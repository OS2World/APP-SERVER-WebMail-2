/*:VRX         Main
*/
Main:
signal on halt
parse arg param
parse value param with server.!port ":" ns ":" client.!addr
call VRMethod "Application", "GetVar", "Globals.!Access.","Globals.!Access."

/* Security - check who is talking to us by IP address (Web server access) */
tmp=0
do i=1 to Globals.!Access.0
 if CompareIP(client.!addr,Globals.!Access.i)=1 then do
  tmp=1
  leave
 end
end
if tmp=0 then do
 call SockSoClose ns
 call VRMethod "Application","PostQueue",0,0,"call Refresh_AuthFail","clientaddr",client.!addr,"type","web server"
 exit
end

/* Get webmail2.cmd request */
call ReceiveData
parse value newData with . ":" user ":" one ":" two ":" .
if pos("@",user)>0 then parse value user with user "@" domain
else domain=""
if substr(newData,1,1)=0 then clientip=two
else clientip=one

/* Request is to report a CGI error */
if substr(newData,1,1)=3 then do
 call SockSoClose ns
 call VRMethod "Application","PostQueue",0,0,"call Refresh_CGIError","clientaddr",client.!addr,"errormsg",substr(newData,3)
 exit
end

/* Check if user's IP address is allowed */
call VRMethod "Application","GetVar","Globals.!AccessCli.","Globals.!AccessCli."
tmp=0
do i=1 to Globals.!AccessCli.0
 if CompareIP(clientip,Globals.!AccessCli.i)=1 then do
  tmp=1
  leave
 end
end
if tmp=0 then do
 call SockSoClose ns
 call VRMethod "Application","PostQueue",0,0,"call Refresh_AuthFail","clientaddr",clientip,"type","client"
 exit
end

if substr(newData,1,1)=0 then do
 /* Check if user is banned */
 call VRMethod "Application","GetVar","Globals.!AccessBan.","Globals.!AccessBan."
 do i=1 to Globals.!AccessBan.0
  if pos(translate(Globals.!AccessBan.i),translate(user))>0 then do
   call SockSoClose ns
   call VRMethod "Application","PostQueue",0,0,"call Refresh_AuthFail","clientaddr",clientip,"type","banned user ("||user||")"
   exit
  end
 end
 /* Check if users domain is allowed */
 tmp=0
 call VRMethod "Application","GetVar","Globals.!AccessDom.","Globals.!AccessDom."
 if Globals.!AccessDom.0=1 & domain="" then do
  domain=Globals.!AccessDom.1
  newData=substr(newData,1,pos(":",newData,3)-1)||"@"||domain||substr(newData,pos(":",newData,3))
 end
 do i=1 to Globals.!AccessDom.0
  if translate(Globals.!AccessDom.i)=translate(domain) then do
   tmp=1
   leave
  end
 end
 if tmp=0 then do
  call SockSoClose ns
  call VRMethod "Application","PostQueue",0,0,"call Refresh_AuthFail","clientaddr",clientip,"type","domain ("||domain||")"
  exit
 end
end

/* Request is to register a new user */
if substr(newData,1,1)=4 then do
 call VRMethod "Application","GetVar","Globals.!NewUsers","Globals.!AccessDom."
 if Globals.!NewUsers=0 then do
  call SockSoClose ns
  exit
 end
 parse value newData with . ":" username ":" emailid ":" domain ":" password ":" .
 rc=User_Check()
 if rc=1 then call VRMethod "Application","PostQueue",0,0,"call User_AddNew","username",username,"emailid",emailid,"domain",domain,"password",password
 call SendData "[WebManager2] "||rc
 call SockSoClose ns
 exit
end

/* Authenticate user and do login */
rc=Authenticate(newData)
if rc<>0 & rc<>2 then do
 parse value rc with . ":" . ":" . ":" . ":" five ":" six ":"
 if five="" & six="" then do
  call VRMethod "Application","GetVar","Globals.!POP3","Globals.!POP3"
  call VRMethod "Application","GetVar","Globals.!POP3P","Globals.!POP3P"
  call VRMethod "Application","GetVar","Globals.!SMTP","Globals.!SMTP"
  call VRMethod "Application","GetVar","Globals.!SMTPP","Globals.!SMTPP"
  call SendData "[WebManager2] OK:"||Globals.!POP3||":"||Globals.!POP3P||":"||Globals.!SMTP||":"||Globals.!SMTPP||":"||rc||":"
 end; else do
  call VRMethod "Application","GetVar","Globals.!SMTP","Globals.!SMTP"
  call VRMethod "Application","GetVar","Globals.!SMTPP","Globals.!SMTPP"
  tmp=lastpos(":",rc,length(rc)-1)
  tmp=lastpos(":",rc,tmp-1)
  rc=substr(rc,1,tmp)
  call SendData "[WebManager2] OK:"||five||":"||six||":"||Globals.!SMTP||":"||Globals.!SMTPP||":"||rc||":"
 end
end; else if rc=0 then call VRMethod "Application","PostQueue",0,0,"call Refresh_AuthFail","clientaddr",clientip,"type","user/password"
call SockSoClose ns
exit

/*:VRX         AddressBook_Add
*/
AddressBook_Add: procedure expose ns alias name email
user=substr(ARG(1),1,pos("@",ARG(1))-1)
dir=VRGet("Application","Program")
dir=substr(dir,1,lastpos('\',dir)-1)||"\database"
call VRMethod "Application","GetVar","Globals.!Ignored",Globals.!Ignored
if Globals.!Ignored=0 then do
 domain=substr(ARG(1),pos("@",ARG(1))+1)
 if VRIsDir(dir||"\"||domain)=0 then call VRMkDir dir||"\"||domain
 userfile=dir||"\"||domain||"\"||user
end; else userfile=dir||"\"||user
if stream(userfile,"c","query exists")="" then call charout userfile,"<addressbook>"||'0d0a'x||alias||":"||name||":"||email||'0d0a'x||"</addressbook>"||'0d0a'x
else do
 if alias<>"" then do
  call SysFileSearch alias,userfile,'res.'
  do i=1 to res.0
   parse value res.i with tmp ":" .
   if translate(alias)=translate(tmp) then do
    call SendData 3
    return
   end
  end
  do i=1 to res.0
   parse value res.i with . ":" tmp ":" .
   if translate(alias)=translate(tmp) then do
    call SendData 3
    return
   end
  end
 end
 if name<>"" then do
  call SysFileSearch name,userfile,'res.'
  do i=1 to res.0
   parse value res.i with tmp ":" .
   if translate(name)=translate(tmp) then do
    call SendData 2
    return
   end
  end
  do i=1 to res.0
   parse value res.i with . ":" tmp ":" .
   if translate(name)=translate(tmp) then do
    call SendData 2
    return
   end
  end
 end
 call SysFileSearch email,userfile,'res.'
 do i=1 to res.0
  parse value res.i with . ":" . ":" tmp
  if translate(email)=translate(tmp) then do
   call SendData 4
   return
  end
 end
 call SysFileSearch "</addressbook>",userfile,'res.','N'
 if res.0>0 then do
  data=charin(userfile,1,stream(userfile,"c","query size"))
  parse value data with tmp1 "</addressbook>" tmp2
  data=tmp1||alias||":"||name||":"||email||'0d0a'x||"</addressbook>"||tmp2
  call stream userfile,'c','close'
  call VRDeleteFile userfile
  call charout userfile,data
 end; else do
  call lineout userfile,"<addressbook>"
  call lineout userfile,alias||":"||name||":"||email
  call lineout userfile,"</addressbook>"
 end 
end
call SendData 1
return

/*:VRX         AddressBook_Remove
*/
AddressBook_Remove: procedure expose ns email
user=substr(ARG(1),1,pos("@",ARG(1))-1)
dir=VRGet("Application","Program")
dir=substr(dir,1,lastpos('\',dir)-1)||"\database"
call VRMethod "Application","GetVar","Globals.!Ignored",Globals.!Ignored
if Globals.!Ignored=0 then do
 domain=substr(ARG(1),pos("@",ARG(1))+1)
 if VRIsDir(dir||"\"||domain)=0 then do
  call SendData 2
  return
 end
 userfile=dir||"\"||domain||"\"||user
end; else userfile=dir||"\"||user
if stream(userfile,"c","query exists")="" then do
 call SendData 2
 return
end
call stream userfile,'c','open'
data=""
do while lines(userfile)>0
 tmp=linein(userfile)||'0d0a'x
 if pos(":"||email||'0d0a'x,tmp)>0 then
  ok=1
 else
  data=data||tmp
end
call stream userfile,'c','close'
call VRDeleteFile userfile
call charout userfile,data
call stream userfile,'c','close'
if ok=1 then call SendData 1
else call SendData 2
return

/*:VRX         AddressBook_Send
*/
AddressBook_Send: procedure expose ns
user=substr(ARG(1),1,pos("@",ARG(1))-1)
dir=VRGet("Application","Program")
dir=substr(dir,1,lastpos('\',dir)-1)||"\database"
call VRMethod "Application","GetVar","Globals.!Ignored",Globals.!Ignored
if Globals.!Ignored=0 then do
 domain=substr(ARG(1),pos("@",ARG(1))+1)
 if VRIsDir(dir||"\"||domain)=0 then do
  call SendData "."
  return
 end
 userfile=dir||"\"||domain||"\"||user
end; else userfile=dir||"\"||user
if stream(userfile,"c","query exists")="" then do
 call SendData "."
 return
end
call SysFileSearch "</addressbook>",userfile,'res.','N'
if res.0>0 then do
 data=charin(userfile,1,stream(userfile,"c","query size"))
 data=substr(data,1,pos("</addressbook>",data)-1)
 data=substr(data,pos("<addressbook>",data)+15)
 call SendData data||"."
end; else call SendData "."
return

/*:VRX         Authenticate
*/
Authenticate: procedure expose Globals. ns
parse value ARG(1) with rtype ":" authid
/* 0=first time login, 1=recheck, 2=logoff,
 5=addressbook, 6=add address, 7=remove address,
 8=signature, 9=save signature
 a=email, b=add email, c=remove email */
if rtype=0 then do
 parse value authid with authuser ":" authpazz ":" clientip ":"
 if pos("@",authuser)<1 then return 0
 rc=User_CheckOnline(0)
 if rc<>0 & rc<>1 then return(rc)
 fullemail=0
 rc2=Authenticate_User()
 if rc=0 & rc2=1 then do
  rc=rexx_md5(date('B')||":"||time('S')||":"||clientip||":")||fullemail
  call VRMethod "Application","PostQueue",0,0,"call User_Online","authuser",authuser,"authpazz",authpazz,"clientip",clientip,"clientid",rc,"fullname",fullname,"newpop3",newpop3,"newpop3p",newpop3p
  return rc||":"||authuser||":"||authpazz||":"||fullname||":"||newpop3||":"||newpop3p||":"
 end
 return 0
end; else if rtype=1 then do
 parse value authid with authid ":" clientip ":"
 rc=User_CheckOnline(1)
 return(rc)
end; else if rtype=2 then do
 parse value authid with authid ":" clientip ":"
 rc=User_CheckOnline(2)
 if rc<>0 then call VRMethod "Application","PostQueue",0,0,"call User_Offline","rc",rc
 return 2
end; else if rtype=5 then do
 parse value authid with authid ":" clientip ":"
 rc=User_CheckOnline(3)
 if rc<>0 then call AddressBook_Send rc
 return 2
end; else if rtype=6 then do
 parse value authid with authid ":" clientip ":" alias ":" name ":" email ":"
 rc=User_CheckOnline(3)
 if rc<>0 then call AddressBook_Add rc
 return 2
end; else if rtype=7 then do
 parse value authid with authid ":" clientip ":" email ":"
 rc=User_CheckOnline(3)
 if rc<>0 then call AddressBook_Remove rc
 return 2
end; else if rtype=8 then do
 parse value authid with authid ":" clientip ":"
 rc=User_CheckOnline(3)
 if rc<>0 then call Signature_Send rc
 return 2
end; else if rtype=9 then do
 parse value authid with authid ":" clientip ":" signature ":" options ":"
 rc=User_CheckOnline(3)
 if rc<>0 then call Signature_Save rc
 return 2
end; else if rtype="a" then do
 parse value authid with authid ":" clientip ":"
 rc=User_CheckOnline(3)
 if rc<>0 then call EmailBook_Send rc
 return 2
end; else if rtype="b" then do
 parse value authid with authid ":" clientip ":" email ":"
 rc=User_CheckOnline(3)
 if rc<>0 then call EmailBook_Add rc
 return 2
end; else if rtype="c" then do
 parse value authid with authid ":" clientip ":" email ":"
 rc=User_CheckOnline(3)
 if rc<>0 then call EmailBook_Remove rc
 return 2
end
return

/*:VRX         Authenticate_User
*/
Authenticate_User: procedure expose Globals. authuser authpazz fullname newpop3 newpop3p fullemail
newpop3=""
newpop3p=""
call VRMethod "Application","GetVar","Globals.!Users.","Globals.!Users."
call VRMethod "Application","GetVar","Globals.!UserDataBase","Globals.!UserDataBase"
call VRMethod "Application","GetVar","Globals.!UserPath","Globals.!UserPath"
call VRMethod "Application","GetVar","Globals.!FullEmail","Globals.!FullEmail"
if Globals.!FullEmail=1 then
 fullemail=1
if Globals.!UserDataBase=1|Globals.!UserDataBase=4|Globals.!UserDataBase=7|Globals.!UserDataBase=9 then do
 do zz=1 to Globals.!Users.0
  parse value Globals.!Users.zz with tmp1 ":" tmp2 ":" fullname ":"
  if pos("@",tmp1)>0 then do
   if translate(authuser)=translate(tmp1)&authpazz=tmp2 then return 1
  end; else do
   if translate(substr(authuser,1,pos("@",authuser)-1))=translate(tmp1)&authpazz=tmp2 then return 1
  end
 end
end; else if Globals.!UserDataBase=3 then do
 parse value authuser with tmp "@" .
 inetmail.username=tmp
 inetmail.password=authpazz
 rc=HCheckUser(Globals.!UserPath||"\InetMail.pas",inetmail.)
 if substr(rc,1,3)="OK." then do
  call HUserInfo Globals.!UserPath||"\InetMail.pas",userdata.
  fullname=userdata.realname
  return 1
 end
end; else if Globals.!UserDataBase=2 then do
 do zz=1 to Globals.!Users.0
  parse value Globals.!Users.zz with tmp1 ":" tmp2 ":" fullname ":"
  if translate(substr(authuser,1,pos("@",authuser)-1)) == translate(tmp1) then do
   if pos("-",tmp2)=1 then do
    if substr(tmp2,2)==authpazz then return 1
   end; else do   
    rc = ipsAuth(tmp2, authpazz)
    if rc = "OK" then return 1
   end
  end
 end
end; else if Globals.!UserDataBase=5 then do
 call VRMethod "Application","GetVar","Globals.!IMPDomains.","Globals.!IMPDomains."
 call VRMethod "Application","GetVar","Globals.!IMPPaths.","Globals.!IMPPaths."
 parse value authuser with tmp "@" tmpdomain
 do i=1 to Globals.!IMPDomains.0
  if translate(tmpdomain)=translate(Globals.!IMPDomains.i) then leave
 end
 if translate(tmpdomain)<>translate(Globals.!IMPDomains.i) then return 0
 inetmail.username=tmp
 inetmail.password=authpazz
 inetmail.domain=tmpdomain
 parse value Globals.!IMPPaths.i with tmp1 '02'x newpop3 '03'x newpop3p
 rc=HCheckUser(tmp1,inetmail.)
 if substr(rc,1,3)="OK." then do
  call HUserInfo tmp1,inetmail.
  fullname=inetmail.realname
  return 1
 end
end; else if Globals.!UserDataBase=6 then do
 fullname=""
 call VRMethod "Application","GetVar","Globals.!POP3","Globals.!POP3"
 call VRMethod "Application","GetVar","Globals.!POP3P","Globals.!POP3P"
 ns=SockSocket("AF_INET","SOCK_STREAM",0)
 if ns=-1 then return 0
 server.!family="AF_INET"
 server.!port=Globals.!POP3P
 server.!addr=Globals.!POP3
 rc=SockConnect(ns,"server.!")
 if rc=-1 then return 0
 call ReceiveData
 if substr(newData,1,3)<>"+OK" then return 0
 if Globals.!FullEmail=1 then
  tmp=authuser
 else
  parse value authuser with tmp "@" .
 apop=0
 tmp1=pos("<",newData)
 if tmp1>0 then do
  tmp2=pos("@",newData,tmp1)
  if tmp2>0 then do
   tmp3=pos(">",newData,tmp2)
   if tmp3>0&pos("Inet.Mail",newData)<1 then do
    apop=1
    md5=substr(newData,tmp1,tmp3-tmp1+1)||authpazz
    md5=translate(rexx_md5(md5),"abcdefghijklmnopqrstuvwxyz„”á","ABCDEFGHIJKLMNOPQRSTUVWXYZŽ™šá")
    call SendData "APOP "||tmp||" "||md5
    call ReceiveData
   end
  end
 end
 if apop=0 then do
  call SendData "USER "||tmp
  call ReceiveData
  if substr(newData,1,3)<>"+OK" then return 0
  call SendData "PASS "||authpazz
  call ReceiveData
 end
 if substr(newData,1,3)<>"+OK" then return 0
 call SendData "QUIT"
 rc=SockSoClose(ns)
 return 1
end; else if Globals.!UserDataBase=8 then do
 parse value authuser with tmp "@" .
 rc=ZxUser('LOGIN',tmp,authpazz,'zxsessionid','zxuserdata','zxmsglist')
 if rc<>0 then return 0
 fullname=zxuserdata.!desc
 rc=ZxUser('LOGOFF',zxsessionid)
 if rc<>0 then return 0
 return 1
end
return 0

/*:VRX         CompareIP
*/
CompareIP: procedure
parse value ARG(1) with x1 "." x2 "." x3 "." x4
parse value ARG(2) with y1 "." y2 "." y3 "." y4
if y1<>0 & x1<>y1 then return 0
else if y2<>0 & x2<>y2 then return 0
else if y3<>0 & x3<>y3 then return 0
else if y4<>0 & x4<>y4 then return 0
return 1

/*:VRX         EmailBook_Add
*/
EmailBook_Add: procedure expose ns email
user=substr(ARG(1),1,pos("@",ARG(1))-1)
dir=VRGet("Application","Program")
dir=substr(dir,1,lastpos('\',dir)-1)||"\database"
call VRMethod "Application","GetVar","Globals.!Ignored",Globals.!Ignored
if Globals.!Ignored=0 then do
 domain=substr(ARG(1),pos("@",ARG(1))+1)
 if VRIsDir(dir||"\"||domain)=0 then call VRMkDir dir||"\"||domain
 userfile=dir||"\"||domain||"\"||user
end; else userfile=dir||"\"||user
if stream(userfile,"c","query exists")="" then call charout userfile,"<emailbook>"||'0d0a'x||email||'0d0a'x||"</emailbook>"||'0d0a'x
else do
 call SysFileSearch email,userfile,'res.'
 if res.0>0 then do
  call SendData 2
  return
 end
 call SysFileSearch "</emailbook>",userfile,'res.','N'
 if res.0>0 then do
  data=charin(userfile,1,stream(userfile,"c","query size"))
  parse value data with tmp1 "</emailbook>" tmp2
  data=tmp1||email||'0d0a'x||"</emailbook>"||tmp2
  call stream userfile,'c','close'
  call VRDeleteFile userfile
  call charout userfile,data
 end; else do
  call lineout userfile,"<emailbook>"||'0d0a'x||email||'0d0a'x||"</emailbook>"
 end 
end
call SendData 1
return

/*:VRX         EmailBook_Remove
*/
EmailBook_Remove: procedure expose ns email
user=substr(ARG(1),1,pos("@",ARG(1))-1)
dir=VRGet("Application","Program")
dir=substr(dir,1,lastpos('\',dir)-1)||"\database"
call VRMethod "Application","GetVar","Globals.!Ignored",Globals.!Ignored
if Globals.!Ignored=0 then do
 domain=substr(ARG(1),pos("@",ARG(1))+1)
 if VRIsDir(dir||"\"||domain)=0 then do
  call SendData 2
  return
 end
 userfile=dir||"\"||domain||"\"||user
end; else userfile=dir||"\"||user
if stream(userfile,"c","query exists")="" then do
 call SendData 2
 return
end
dat=charin(userfile,1,stream(userfile,"c","query size"))
call stream userfile,'c','close'
data=substr(dat,1,pos("</emailbook>",dat)-1)
data=substr(data,pos("<emailbook>",data)+13)
i=0
newdata=""
do while pos('0d0a'x,data)>0
 parse value data with tmp '0d0a'x data
 i=i+1
 if i=email then do
  ok=1
 end; else do
  newdata=newdata||tmp||'0d0a'x
 end
end
if ok=1 then do
 call VRDeleteFile userfile
 call charout userfile,substr(dat,1,pos("<emailbook>",dat)+10)||'0d0a'x||newdata||substr(dat,pos("</emailbook>",dat))
 call stream userfile,'c','close'
end
if ok=1 then call SendData 1
else call SendData 2
return

/*:VRX         EmailBook_Send
*/
EmailBook_Send: procedure expose ns
user=substr(ARG(1),1,pos("@",ARG(1))-1)
dir=VRGet("Application","Program")
dir=substr(dir,1,lastpos('\',dir)-1)||"\database"
call VRMethod "Application","GetVar","Globals.!Ignored",Globals.!Ignored
if Globals.!Ignored=0 then do
 domain=substr(ARG(1),pos("@",ARG(1))+1)
 if VRIsDir(dir||"\"||domain)=0 then do
  call SendData "."
  return
 end
 userfile=dir||"\"||domain||"\"||user
end; else userfile=dir||"\"||user
if stream(userfile,"c","query exists")="" then do
 call SendData "."
 return
end
call SysFileSearch "</emailbook>",userfile,'res.','N'
if res.0>0 then do
 data=charin(userfile,1,stream(userfile,"c","query size"))
 data=substr(data,1,pos("</emailbook>",data)-1)
 data=substr(data,pos("<emailbook>",data)+13)
 call SendData data||"."
end; else call SendData "."
return

/*:VRX         Halt
*/
Halt:
call SockSoClose ns
exit

/*:VRX         ReceiveData
*/
ReceiveData: procedure expose ns newData
/* call SockRecv ns,"newData",1024 */
length=ARG(1)
if length="" then length=1024
r.0=1
r.1=ns
newData=""
do while pos('0d0a'x,newData)<1
 bytes=SockSelect("r.","","",10)
 if bytes>0 then bytes=SockRecv(ns,"Buffer",length)
 else bytes=-2
 if bytes<=0 then do /* Remote socket has vanished */
  if bytes=-2 then answer=-2 /* No input within timeout */
  else if bytes<0 then answer=-1 /* Receive failure */
  else answer=-1 /* Socket has closed */
  return answer
 end; else answer=0 /* OK */
 newData=newData||Buffer
end
return answer

/*:VRX         SendData
*/
SendData: procedure expose ns
call SockSend ns, ARG(1)||'0d0a'x
return

/*:VRX         Signature_Save
*/
Signature_Save: procedure expose ns signature options
user=substr(ARG(1),1,pos("@",ARG(1))-1)
dir=VRGet("Application","Program")
dir=substr(dir,1,lastpos('\',dir)-1)||"\database"
call VRMethod "Application","GetVar","Globals.!Ignored",Globals.!Ignored
if Globals.!Ignored=0 then do
 domain=substr(ARG(1),pos("@",ARG(1))+1)
 if VRIsDir(dir||"\"||domain)=0 then call VRMkDir dir||"\"||domain
 userfile=dir||"\"||domain||"\"||user
end; else userfile=dir||"\"||user
if stream(userfile,"c","query exists")="" then call charout userfile,"<signature>"||signature||"</signature>"||'0d0a'x||"<options>"||options||"</options>"||'0d0a'x
else do

 call SysFileSearch "</signature>",userfile,'res.','N'
 if res.0>0 then do
  data=charin(userfile,1,stream(userfile,"c","query size"))
  parse value data with tmp1 "<signature>" . "</signature>" tmp2
  data=tmp1||"<signature>"||signature||"</signature>"||tmp2
  call stream userfile,'c','close'
  call VRDeleteFile userfile
  call charout userfile,data
 end; else call charout userfile,"<signature>"||signature||"</signature>"||'0d0a'x

 call stream userfile,'c','close'
 call SysFileSearch "</options>",userfile,'res.','N'
 if res.0>0 then do
  data=charin(userfile,1,stream(userfile,"c","query size"))
  parse value data with tmp1 "<options>" . "</options>" tmp2
  data=tmp1||"<options>"||options||"</options>"||tmp2
  call stream userfile,'c','close'
  call VRDeleteFile userfile
  call charout userfile,data
 end; else call charout userfile,"<options>"||options||"</options>"||'0d0a'x

end
call SendData 1
return

/*:VRX         Signature_Send
*/
Signature_Send: procedure expose ns
user=substr(ARG(1),1,pos("@",ARG(1))-1)
dir=VRGet("Application","Program")
dir=substr(dir,1,lastpos('\',dir)-1)||"\database"
call VRMethod "Application","GetVar","Globals.!Ignored",Globals.!Ignored
if Globals.!Ignored=0 then do
 domain=substr(ARG(1),pos("@",ARG(1))+1)
 if VRIsDir(dir||"\"||domain)=0 then do
  call SendData "showheaders=0&showhtml=0&bccto=&userfake=&signature=."
  return
 end
 userfile=dir||"\"||domain||"\"||user
end; else userfile=dir||"\"||user
if stream(userfile,"c","query exists")="" then do
 call SendData "showheaders=0&showhtml=0&bccto=&userfake=&signature=."
 return
end

call SysFileSearch "</signature>",userfile,'res.','N'
if res.0>0 then do
 data=charin(userfile,1,stream(userfile,"c","query size"))
 data=substr(data,1,pos("</signature>",data)-1)
 data=substr(data,pos("<signature>",data)+11)
 tempsign="signature="||data||"."
end; else tempsign="signature=."

call stream userfile,'c','close'
call SysFileSearch "</options>",userfile,'res.','N'
if res.0>0 then do
 data=charin(userfile,1,stream(userfile,"c","query size"))
 data=substr(data,1,pos("</options>",data)-1)
 data=substr(data,pos("<options>",data)+9)
 /* if substr(data,length(data))="&" then */
 if lastpos("&",data)=length(data) then
  call SendData data||tempsign
 else
  call SendData data||"&"||tempsign
end; else call SendData "showheaders=0&showhtml=0&bccto=&userfake=&"||tempsign

return

/*:VRX         User_Check
*/
User_Check: procedure expose Globals. emailid password domain
if length(password)<4 then return 3
call VRMethod "Application","GetVar","Globals.!Users.","Globals.!Users."
call VRMethod "Application","GetVar","Globals.!UserDataBase","Globals.!UserDataBase"
call VRMethod "Application","GetVar","Globals.!UserPath","Globals.!UserPath"
if Globals.!UserDataBase=1|Globals.!UserDataBase=7|Globals.!UserDataBase=9 then do
 do i=1 to Globals.!Users.0
  parse value Globals.!Users.i with tmp1 ":" tmp2
  if pos("@",tmp1)>0 then do
   if translate(emailid||"@"||domain)=translate(tmp1) then return 2
  end; else do
   if translate(emailid)=translate(tmp1) then return 2
  end
 end
 return 1
end; else if Globals.!UserDataBase=4 then do
 do i=1 to Globals.!Users.0
  parse value Globals.!Users.i with tmp1 ":" tmp2
  if translate(emailid)=translate(tmp1) then return 2
 end
 call SysIni Globals.!UserPath||"\weasel.INI",'$ALIAS','ALL:','keyz'
 do i=1 to keyz.0
  if translate(emailid)==translate(keyz.i) then return 2
 end
 return 1
end; else if Globals.!UserDataBase=2 then do
 do i=1 to Globals.!Users.0
  parse value Globals.!Users.i with tmp1 ":" tmp2
  if translate(emailid)==translate(tmp1) then return 2
 end
 call SysFileTree Globals.!UserPath||"\*","usernames.","FO"
 do i=1 to usernames.0
  call SysFileSearch emailid,usernames.i,"found."
  if found.0>0 then do
   do ii=1 to found.0
    if pos("ALIASES=",translate(found.ii))=1 then return 2
   end
  end
 end
 return 1
end; else if Globals.!UserDataBase=3 then do
 rc = HQueryUser(Globals.!UserPath||"\InetMail.pas",emailid)
 if substr(rc,1,3)="OK." then return 2
 return 1
end; else if Globals.!UserDataBase=5 then do
 rc = HQueryUser(Globals.!UserPath||"\InetMail.pas",emailid,substr(domain,2))
 if substr(rc,1,3)="OK." then return 2
 return 1
end
return 0

/*:VRX         User_CheckOnline
*/
User_CheckOnline: procedure expose Globals. authuser authpazz clientip authid
call VRMethod "Application","GetVar","Globals.!OnlineUsr.","Globals.!OnlineUsr."
if ARG(1)=0 then do
 do i=1 to Globals.!OnlineUsr.0
  parse value Globals.!OnlineUsr.i with tmp1 ":" tmp2 ":" tmp3 ":" tmp4 ":" . ":" tmp5 ":" tmp6 ":" tmp7 ":"
  if translate(tmp1)=translate(authuser) & translate(tmp2)=translate(authpazz) then do
   return tmp4||":"||tmp1||":"||tmp2||":"||tmp5||":"||tmp6||":"||tmp7||":"
   /* Client IP security disabled
   if clientip=tmp3 then return tmp4||":"||tmp1||":"||tmp2||":"||tmp5||":"||tmp6||":"||tmp7||":"
   else return 1
   */
  end
 end
end; else if ARG(1)=1|ARG(1)=2|ARG(1)=3 then do
 do i=1 to Globals.!OnlineUsr.0
  parse value Globals.!OnlineUsr.i with tmp1 ":" tmp2 ":" tmp3 ":" tmp4 ":" . ":" tmp5 ":" tmp6 ":" tmp7 ":"
  if authid=tmp4 then do
   /* Client IP security disabled
   & clientip=tmp3
   */
   if ARG(1)=1|ARG(1)=3 then call VRMethod "Application","PostQueue",0,0,"call User_Update","i",i,"userdata",tmp1||":"||tmp2||":"||tmp3||":"||tmp4||":"||date("S")||"-"||time("M")||":"||tmp5||":"||tmp6||":"||tmp7||":"
   if ARG(1)=3 then return tmp1
   return tmp4||":"||tmp1||":"||tmp2||":"||tmp5||":"||tmp6||":"||tmp7||":"
  end
 end
end
return 0

