/*:VRX         Main
*/
/*  Main
*/
/***************************************************/
/* Initialize REXXUtil environment (if not present)*/
/***************************************************/
rxload = RxFuncQuery('SysLoadFuncs')
if rxload then do
 call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
 call sysloadfuncs
end
rxload = RxFuncQuery('SockLoadFuncs')
if rxload then do
 call RxFuncAdd 'SockLoadFuncs','RxSock','SockLoadFuncs'
 call SockLoadFuncs(1)
end

/***************************************************/
/* Redirect Standerd IO                            */
/***************************************************/

ok = VRRedirectStdIO( Off, "" )

/***************************************************/
/* Main Process                                    */
/***************************************************/
Main:
/*  Process the arguments.
    Get the parent window.
*/
    parse source . calledAs .
    parent = ""
    argCount = arg()
    argOff = 0
    if( calledAs \= "COMMAND" )then do
        if argCount >= 1 then do
            parent = arg(1)
            argCount = argCount - 1
            argOff = 1
        end
    end; else do
        call VROptions 'ImplicitNames'
        call VROptions 'NoEchoQuit'
    end
    InitArgs.0 = argCount
    if( argCount > 0 )then do i = 1 to argCount
        InitArgs.i = arg( i + argOff )
    end
    drop calledAs argCount argOff

/*  Load the windows
*/
    call VRInit
    parse source . . spec
    _VREPrimaryWindowPath = ,
        VRParseFileName( spec, "dpn" ) || ".VRW"
    _VREPrimaryWindow = ,
        VRLoad( parent, _VREPrimaryWindowPath )
    drop parent spec
    if( _VREPrimaryWindow == "" )then do
        call VRMessage "", "Cannot load window:" VRError(), ,
            "Error!"
        _VREReturnValue = 32000
        signal _VRELeaveMain
    end

/*  Process events
*/
    call Init
    signal on halt
    do while( \ VRGet( _VREPrimaryWindow, "Shutdown" ) )
        _VREEvent = VREvent()
        interpret _VREEvent
    end
_VREHalt:
    _VREReturnValue = Fini()
    call VRDestroy _VREPrimaryWindow
_VRELeaveMain:
    call VRFini
exit _VREReturnValue

VRLoadSecondary:
       __vrlsWait = abbrev( 'WAIT', translate(arg(2)), 1 )
       if __vrlsWait then call VRFlush
       if arg(3,"Exists") then __vrlsParent = arg(3)
       else __vrlsParent = VRWindow()
       __vrlsHWnd = VRLoad( __vrlsParent, VRWindowPath(), arg(1) )
       if __vrlsHWnd = '' then signal __vrlsDone
       if \ __vrlsWait    then signal __vrlsDone
       call VRSet __vrlsHWnd, 'WindowMode', 'Modal'
       if( symbol('__vrlsWindows.0') \== 'VAR' ) then __vrlsTmp = 1
       else __vrlsTmp = __vrlsWindows.0 + 1
       __vrlsWindows.__vrlsTmp = VRWindow( __vrlsHWnd )
       __vrlsWindows.0 = __vrlsTmp
       do while( VRIsValidObject( VRWindow() ))
        __vrlsEvent = VREvent()
        interpret __vrlsEvent
       end
       __vrlsTmp = __vrlsWindows.0
       __vrlsWindows.0 = __vrlsTmp - 1
       call VRWindow __vrlsWindows.__vrlsTmp
       __vrlsHWnd = ''
__vrlsDone:
return __vrlsHWnd

/*:VRX         Fini
*/
Fini:
window=VRWindow()
call VRSet window,"Visible",0
drop window
return 0

/*:VRX         Halt
*/
Halt:
signal _VREHalt
return

/*:VRX         Init
*/
Init: procedure expose Globals.
Globals.!Version="beta 102"
Globals.!WorkingDir=VRGet("Application","Program")
Globals.!WorkingDir=substr(Globals.!WorkingDir,1,lastpos('\',Globals.!WorkingDir)-1)
Globals.!IniFile=Globals.!WorkingDir||"\WebManager.ini"
Globals.!Program="WebManager.EXE"
Globals.!WindowLeft=VRGetIni(Globals.!Program,"Left",Globals.!IniFile,"NoClose")
Globals.!WindowTop=VRGetIni(Globals.!Program,"Top",Globals.!IniFile,"NoClose")
Globals.!Users.0=0
Globals.!Access.0=0
Globals.!AccessCli.0=0
Globals.!OnlineUsr.0=0
call VRMethod "Application","PutVar","Globals.!OnlineUsr.","Globals.!OnlineUsr."
Globals.!IP=VRGetIni(Globals.!Program,"IP",Globals.!IniFile,"NoClose")
if Globals.!IP="" then Globals.!IP="127.0.0.1"
Globals.!Port=VRGetIni(Globals.!Program,"Port",Globals.!IniFile,"NoClose")
if Globals.!Port="" then Globals.!Port=3511
Globals.!PasswordTimeout=VRGetIni(Globals.!Program,"PasswordTimeout",Globals.!IniFile,"NoClose")
if Globals.!PasswordTimeout="" then Globals.!PasswordTimeout=10
Globals.!Timer=VRGetIni(Globals.!Program,"Timer",Globals.!IniFile,"NoClose")
if Globals.!Timer="" then Globals.!Timer=120
Globals.!POP3=VRGetIni(Globals.!Program,"POP3",Globals.!IniFile,"NoClose")
if Globals.!POP3="" then Globals.!POP3="127.0.0.1"
call VRMethod "Application","PutVar","Globals.!POP3","Globals.!POP3"
Globals.!POP3P=VRGetIni(Globals.!Program,"POP3P",Globals.!IniFile,"NoClose")
if Globals.!POP3P="" then Globals.!POP3P="110"
call VRMethod "Application","PutVar","Globals.!POP3P","Globals.!POP3P"
Globals.!SMTP=VRGetIni(Globals.!Program,"SMTP",Globals.!IniFile,"NoClose")
if Globals.!SMTP="" then Globals.!SMTP="127.0.0.1"
call VRMethod "Application","PutVar","Globals.!SMTP","Globals.!SMTP"
Globals.!SMTPP=VRGetIni(Globals.!Program,"SMTPP",Globals.!IniFile,"NoClose")
if Globals.!SMTPP="" then Globals.!SMTPP="25"
call VRMethod "Application","PutVar","Globals.!SMTPP","Globals.!SMTPP"
Globals.!Ignored=VRGetIni(Globals.!Program,"Ignored",Globals.!IniFile,"NoClose")
if Globals.!Ignored="" then Globals.!Ignored=0
call VRMethod "Application","PutVar","Globals.!Ignored","Globals.!Ignored"
Globals.!FullEmail=VRGetIni(Globals.!Program,"FullEmail",Globals.!IniFile,"NoClose")
if Globals.!FullEmail="" then Globals.!FullEmail=0
call VRMethod "Application","PutVar","Globals.!FullEmail","Globals.!FullEmail"
Globals.!AlertP=VRGetIni(Globals.!Program,"AlertP",Globals.!IniFile,"NoClose")
if Globals.!AlertP="" then Globals.!AlertP=0
Globals.!AlertF=VRGetIni(Globals.!Program,"AlertF",Globals.!IniFile,"NoClose")
if Globals.!AlertF="" then Globals.!AlertF=100
Globals.!AlertR=VRGetIni(Globals.!Program,"AlertR",Globals.!IniFile,"NoClose")
Globals.!UseLogFile=VRGetIni(Globals.!Program,"UseLogFile",Globals.!IniFile,"NoClose")
if Globals.!UseLogFile="" then Globals.!UseLogFile=0
Globals.!LogFile=VRGetIni(Globals.!Program,"LogFile",Globals.!IniFile,"NoClose")
if Globals.!LogFile="" then Globals.!LogFile=Globals.!WorkingDir||"\WebManager.log"
Globals.!UserDataBase=VRGetIni(Globals.!Program,"UserDataBase",Globals.!IniFile,"NoClose")
if Globals.!UserDataBase<1|Globals.!UserDataBase>9 then Globals.!UserDataBase=1
call VRMethod "Application","PutVar","Globals.!UserDataBase","Globals.!UserDataBase"
Globals.!UserPath=VRGetIni(Globals.!Program,"UserPath",Globals.!IniFile,"NoClose")
call VRMethod "Application","PutVar","Globals.!UserPath","Globals.!UserPath"
tmp=VRGetIni(Globals.!Program,"IMPDomains",Globals.!IniFile,"NoClose")
Globals.!IMPDomains.0=0
if tmp<>"" then do
 i=Globals.!IMPDomains.0
 do while tmp<>""
  i=i+1
  parse value tmp with tmp1 '01'x tmp
  Globals.!IMPDomains.i=tmp1
 end
 Globals.!IMPDomains.0=i
end
call VRMethod "Application","PutVar","Globals.!IMPDomains.","Globals.!IMPDomains."
tmp=VRGetIni(Globals.!Program,"IMPPaths",Globals.!IniFile,"NoClose")
Globals.!IMPPaths.0=0
if tmp<>"" then do
 i=Globals.!IMPPaths.0
 do while tmp<>""
  i=i+1
  parse value tmp with tmp1 '01'x tmp
  Globals.!IMPPaths.i=tmp1
 end
 Globals.!IMPPaths.0=i
end
call VRMethod "Application","PutVar","Globals.!IMPPaths.","Globals.!IMPPaths."
drop tmp
drop tmp1
Globals.!NewUsers=VRGetIni(Globals.!Program,"NewUsers",Globals.!IniFile,"NoClose")
if Globals.!NewUsers="" then Globals.!NewUsers=0
call VRMethod "Application","PutVar","Globals.!NewUsers","Globals.!NewUsers"
Globals.!NewUsersNot=VRGetIni(Globals.!Program,"NewUsersNot",Globals.!IniFile,"NoClose")
call VRMethod "Application","PutVar","Globals.!NewUsersNot","Globals.!NewUsersNot"
Globals.!NewUsersAuto=VRGetIni(Globals.!Program,"NewUsersAuto",Globals.!IniFile,"NoClose")
if Globals.!NewUsersAuto="" then Globals.!NewUsersAuto=0
call VRMethod "Application","PutVar","Globals.!NewUsersAuto","Globals.!NewUsersAuto"
window=VRWindow()
if (Globals.!WindowLeft \= '' & Globals.!WindowTop \= '') then call VRSet window,'Left',Globals.!WindowLeft,'Top',Globals.!WindowTop
else call VRMethod window, "CenterWindow"
Globals.!StartMin=VRGetIni(Globals.!Program,"StartMin",Globals.!IniFile,"NoClose")
if Globals.!StartMin<>0 & Globals.!StartMin<>1 then Globals.!StartMin = 0
if Globals.!StartMin=0 then call VRSet window,"Visible", 1
call VRMethod window,"Activate"
drop window
return

/*:VRX         LoadUsers_InetMail
*/
LoadUsers_InetMail: procedure expose Globals.
if Globals.!UserPath="" then do
 call VRMessage VRWindow(),"Inet.Mail directory is invalid!","Error","E"
 return
end
if VRIsDir(Globals.!UserPath)<>1 then do
 call VRMessage VRWindow(),"Inet.Mail directory is invalid!","Error","E"
 return
end
call RxFuncAdd 'HPassLoadFuncs','HRxPass','HPassLoadFuncs'
call HPassLoadFuncs
return

/*:VRX         LoadUsers_InetMailPro
*/
LoadUsers_InetMailPro: procedure expose Globals.
call RxFuncAdd 'HPassLoadFuncs','HRxPass','HPassLoadFuncs'
call HPassLoadFuncs
return

/*:VRX         LoadUsers_Internal
*/
LoadUsers_Internal: procedure expose Globals.
ConfigFile=Globals.!WorkingDir||"\WebManager.usr"
i=stream(ConfigFile,'c','open')
if pos("NOTREADY",i)>0 then do
 call VRMessage VRWindow(),"Can't load user file","Error","E"
 return
end
i=0
do while lines(ConfigFile)>0
 tmp=linein(ConfigFile)
 if substr(tmp,1,1)<>"#" & tmp<>"" & tmp<>'0d0a'x then do
  i=i+1
  Globals.!Users.i=tmp
 end
end
Globals.!Users.0=i
call VRMethod "Application","PutVar","Globals.!Users.","Globals.!Users."
return

/*:VRX         LoadUsers_IPS
*/
LoadUsers_IPS: procedure expose Globals.
if Globals.!UserPath="" then do
 call VRMessage VRWindow(),"IPS User directory is invalid!","Error","E"
 return
end
if VRIsDir(Globals.!UserPath)<>1 then do
 call VRMessage VRWindow(),"IPS User directory is invalid!","Error","E"
 return
end
rxload=RxFuncQuery('ipsLoadFuncs')
if rxload then do
 call RxFuncAdd 'ipsLoadFuncs','IPSREXX','ipsLoadFuncs'
 call ipsLoadFuncs
end
s=VRDir(Globals.!UserPath||"\*","N", ,)
i=0
do while s<>""
 if pos('.stat',s)<=0 then do
  i=i+1
  call SysFileSearch "Password",Globals.!UserPath||"\"||s,'found.'
  found.1=substr(found.1,pos("Password",found.1)+9)
  found.1=space(found.1)
  call SysFileSearch "Fullname",Globals.!UserPath||"\"||s,'found2.'
  found2.1=substr(found2.1,pos("Fullname",found2.1)+9)
  found2.1=space(found2.1)
  Globals.!Users.i=space(s)||":"||found.1||":"||found2.1||":"
 end
 s=VRDir( , "N", ,)
end
Globals.!Users.0=i
call VRMethod "Application","PutVar","Globals.!Users.","Globals.!Users."
return

/*:VRX         LoadUsers_OS2PopS
*/
LoadUsers_OS2PopS: procedure expose Globals.
if Globals.!UserPath="" then do
 call VRMessage VRWindow(),"The OS2PopS directory is invalid!","Error","E"
 return
end
if VRIsDir(Globals.!UserPath||"\UserInfo")<>1 then do
 call VRMessage VRWindow(),"The OS2PopS directory is invalid!","Error","E"
 return
end
call SysFileSearch '01'x,Globals.!UserPath||"\UserInfo\OS2POPS.Users",'found.'
ii=0
do i=1 to found.0
 if pos('01'x,found.i)=1 then do
  parse value found.i with '01'x userid '01'x userpass '01'x username '01'x
  ii=ii+1
  Globals.!Users.ii=userid||":"||userpass||":"||username||":"
 end
end
Globals.!Users.0=ii
call VRMethod "Application","PutVar","Globals.!Users.","Globals.!Users."
return

/*:VRX         LoadUsers_Weasel
*/
LoadUsers_Weasel: procedure expose Globals.
if Globals.!UserPath="" then do
 call VRMessage VRWindow(),"Weasel directory is invalid!","Error","E"
 return
end
if VRIsDir(Globals.!UserPath)<>1 then do
 call VRMessage VRWindow(),"Weasel directory is invalid!","Error","E"
 return
end
call SysIni Globals.!UserPath||"\weasel.INI",'ALL:','appz'
z=0
do i=1 to appz.0
 if pos("$",appz.i)<1 then do
  z=z+1
  pwd=SysIni(Globals.!UserPath||"\weasel.INI",appz.i,'Password')
  fullname=SysIni(Globals.!UserPath||"\weasel.INI",appz.i,'RealName')
  if pos("ERROR",fullname)>0 then fullname=""
  Globals.!Users.z=appz.i||":"||strip(pwd,,'00'x)||":"||fullname
 end
end
Globals.!Users.0=z
call VRMethod "Application","PutVar","Globals.!Users.","Globals.!Users."
return

/*:VRX         LoadUsers_WeaselPro
*/
LoadUsers_WeaselPro: procedure expose Globals.
if Globals.!UserPath="" then do
 call VRMessage VRWindow(),"Weasel directory is invalid!","Error","E"
 return
end
if VRIsDir(Globals.!UserPath)<>1 then do
 call VRMessage VRWindow(),"Weasel directory is invalid!","Error","E"
 return
end
call SysIni Globals.!UserPath||"\weasel.INI",'ALL:','appz'
if appz.0<1 then do
 call VRMessage VRWindow(),"Error reading Weasel INI file!","Error","E"
 return
end
do i=1 to appz.0
 if appz.i="$SYS" then do
  mailRoot=SysIni(Globals.!UserPath||"\weasel.INI",appz.i,'MailRoot')
  rc=c2x(SysIni(Globals.!UserPath||"\weasel.INI",appz.i,'MultiDomainEnabled'))
  if rc="01" then do
   pwd=SysIni(Globals.!UserPath||"\weasel.INI",appz.i,'Domains')
   z=0
   do while length(pwd)>0
    if pwd='00'x then leave
    z=z+1
    parse value pwd with domains.z '00'x pwd
   end
   domains.0=z
  end; else do
   call VRMessage VRWindow(),"Weasel multiple domains not enabled!","Error","E"
   return
  end
 end
end
z=0
if domains.0>0 then do
 do x=1 to domains.0
  tmpuserpath=mailRoot||domains.x
  call SysIni tmpuserpath||"\DOMAIN.INI",'ALL:','appz'
  do i=1 to appz.0
   if pos("$",appz.i)<1 then do
    z=z+1
    pwd=SysIni(tmpuserpath||"\DOMAIN.INI",appz.i,'Password')
    if pos("ERROR",pwd)>0 then pwd=""
    fullname=SysIni(tmpuserpath||"\DOMAIN.INI",appz.i,'RealName')
    if pos("ERROR",fullname)>0 then fullname=""
    Globals.!Users.z=appz.i||"@"||domains.x||":"||strip(pwd,,'00'x)||":"||fullname
   end
  end
 end
end
Globals.!Users.0=z
call VRMethod "Application","PutVar","Globals.!Users.","Globals.!Users."
return

/*:VRX         LoadUsers_ZxMail
*/
LoadUsers_ZxMail: procedure expose Globals.
call rxfuncadd "ZxUser","ZXMAILRX","ZxUser"
rc=RXFUNCQUERY( "ZxUser")
if rc<>0 then call VRMessage VRWindow(),"Error loading ZxMail Rexx Extensions, please ensure ZxMailRx.dll is in your LIBPATH."
return

/*:VRX         Quit
*/
Quit:
window = VRWindow()
left = VRGet(window, 'Left')
top = VRGet(window, 'Top')
height = VRGet(window, 'Height')
width = VRGet(window, 'Width')
if( left \= '' & top \= '' )then do
 call VRSetIni Globals.!Program, "Left", left, Globals.!IniFile, "NoClose"
 call VRSetIni Globals.!Program, "Top", top, Globals.!IniFile, "NoClose"
end
/*
if( height \= '' & width \= '' )then do
 call VRSetIni Globals.!Program, "Height", height, Globals.!IniFile, "NoClose"
 call VRSetIni Globals.!Program, "Width", width, Globals.!IniFile
end
*/
call VRSet window, "Shutdown", 1
drop left
drop top
drop height
drop width
drop window
drop Globals.
return

/*:VRX         Refresh
*/
Refresh: procedure
call VRMethod "Application","ListThreads","threads."
if threads.0>=2 then call VRSet "DT_3","Caption",threads.0-2
else do
 call VRSet "DT_3","ForeColor","Red"
 call VRSet "DT_3","Caption","ERROR"
end
call VRMethod "Application","GetVar","Globals.!OnlineUsr.","Globals.!OnlineUsr."
call VRSet "DT_2","Caption",Globals.!OnlineUsr.0
call VRSet "DT_34","Caption",VRGet("DT_34","Caption")+1
return

/*:VRX         Refresh_AuthFail
*/
Refresh_AuthFail: procedure expose Globals.!LogFile Globals.!UseLogFile Globals.!AlertR Globals.!AlertF Globals.!AlertP
rcc=VRGet("DT_5","Caption")
call VRSet "DT_5","Caption",rcc+1
call VRInfo "temp."
if Globals.!UseLogFile=1 & symbol('temp.!type')="VAR" & temp.!type<>"" then call lineout Globals.!LogFile,"AUTHENTICATION ERROR: Unauthorised "||temp.!type||" access from: "||temp.!clientaddr||" ("||date()||" "||time()||")"
if Globals.!AlertP=1 then do
 tmp=Globals.!AlertF
 if rcc+1 >= tmp then do
  prog="start /C "||Globals.!AlertR
  address CMD prog
 end
end
return

/*:VRX         Refresh_CGIError
*/
Refresh_CGIError: procedure expose Globals.!LogFile Globals.!UseLogFile
call VRSet "DT_20","Caption",VRGet("DT_20","Caption")+1
call VRInfo "temp."
if Globals.!UseLogFile=1 then call lineout Globals.!LogFile,"CGI ERROR: "||temp.!clientaddr||": "||temp.!errormsg||" ("||date()||" "||time()||")"
return

/*:VRX         TM_1_Trigger
*/
TM_1_Trigger: procedure expose Globals.
rc=stream(Globals.!WorkingDir||"\refresh","c","query exists")
if rc<>"" then do
 if Globals.!UserDataBase=1 then call LoadUsers_Internal
 else if Globals.!UserDataBase=2 then call LoadUsers_IPS
 else if Globals.!UserDataBase=4 then call LoadUsers_Weasel
 else if Globals.!UserDataBase=7 then call LoadUsers_OS2PopS
 else if Globals.!UserDataBase=9 then call LoadUsers_WeaselPro
 call SysFileDelete Globals.!WorkingDir||"\refresh"
end
return

/*:VRX         TM_2_Trigger
*/
TM_2_Trigger: procedure expose Globals.!PasswordTimeout
call VRMethod "Application","GetVar","Globals.!OnlineUsr.","Globals.!OnlineUsr."
do i=1 to Globals.!OnlineUsr.0
 parse value Globals.!OnlineUsr.i with tmp1 ":" tmp2 ":" . ":" tmp4 ":" tmp5 "-" tmp6 ":" .
 tmp6=tmp6+Globals.!PasswordTimeout
 if date("S")=tmp5 then do
  if time("M")>tmp6 then call VRMethod "Application", "PostQueue", 0, 0, "call User_Offline", "rc", tmp4||":"||tmp1||":"||tmp2
 end; else call VRMethod "Application", "PostQueue", 0, 0, "call User_Offline", "rc", tmp4||":"||tmp1||":"||tmp2
end
return

/*:VRX         User_AddNew
*/
User_AddNew: procedure expose Globals.
call VRInfo "temp."
if Globals.!NewUsersAuto=1 then call User_Register temp.!username||":"||temp.!emailid||":"||temp.!domain||":"||temp.!password
else do 
 call lineout "WebManager.new", temp.!username||":"||temp.!emailid||":"||temp.!domain||":"||temp.!password
 call stream "WebManager.new", 'c', 'close'
end
if Globals.!NewUsersNot<>"" then do
 prog="start /C "||Globals.!NewUsersNot||" "||temp.!username||":"||temp.!emailid||"@"||temp.!domain
 address CMD prog
end
return

/*:VRX         User_Offline
*/
User_Offline: procedure
call VRMethod "Application","GetVar","Globals.!OnlineUsr.","Globals.!OnlineUsr."
call VRInfo "temp."
parse value temp.!rc with tmp1 ":" .
do i=1 to Globals.!OnlineUsr.0
 parse value Globals.!OnlineUsr.i with . ":" . ":" . ":" tmp4 ":" .
 if tmp1==tmp4 then do
  Globals.!OnlineUsr.i=""
  zz=0
  do ii=1 to Globals.!OnLineUsr.0
   if Globals.!OnLineUsr.ii<>"" then do
    zz=zz+1
    Globals.!OnLineUsr.zz=Globals.!OnLineUsr.ii
   end
  end
  Globals.!OnLineUsr.0=zz
  leave
 end
end
call VRMethod "Application","PutVar","Globals.!OnlineUsr.","Globals.!OnlineUsr."
call Refresh
return

/*:VRX         User_Online
*/
User_Online: procedure
call VRMethod "Application","GetVar","Globals.!OnlineUsr.","Globals.!OnlineUsr."
i=Globals.!OnlineUsr.0+1
call VRInfo "temp."
/* userid:passowrd:clientIP:md5-id:datetime:fullname:NewPOP3:NewPOP3P: */
Globals.!OnlineUsr.i=temp.!authuser||":"||temp.!authpazz||":"||temp.!clientip||":"||temp.!clientid||":"||date("S")||"-"||time("M")||":"||temp.!fullname||":"||temp.!NewPOP3||":"||temp.!NewPOP3P||":"
Globals.!OnlineUsr.0=i
call VRMethod "Application","PutVar","Globals.!OnlineUsr.","Globals.!OnlineUsr."
call VRSet "DT_33","Caption",VRGet("DT_33","Caption")+1
call Refresh
return

/*:VRX         User_Register
*/
User_Register: procedure expose Globals.
parse value ARG(1) with username ":" emailid ":" domain ":" password
if Globals.!UserDataBase=1 then do
 /* INTERNAL */
 ConfigFile=Globals.!WorkingDir||"\WebManager.usr"
 call lineout ConfigFile,emailid||domain||":"||password||":"||username||":"
 call VRMethod "LB_1","AddString",emailid||domain||":"||password||":"||username||":"
 call LoadUsers_Internal
end; else if Globals.!UserDataBase=4 then do
 /* WEASEL */
 call SysIni Globals.!UserPath||"\weasel.INI",emailid,"Password",password
 call SysIni Globals.!UserPath||"\weasel.INI",emailid,"RealName",username
 rc=strip(SysIni(Globals.!UserPath||"\weasel.INI",'$SYS','MailRoot'),,'00'x)
 if pos(":",rc)>0 then call SysMkDir rc||emailid
 call LoadUsers_Weasel
end; else if Globals.!UserDataBase=2 then do
 /* IPS */
 tmp.1="[USER]"
 tmp.2="Username="||emailid
 tmp.3="Fullname="||username
 tmp.4="Aliases="
 tmp.5="Password=-"||password
 tmp.6="ChangePassword=1"
 tmp.7="APOPSecret="
 tmp.8="Anonymous=0"
 tmp.9="Administrator=0"
 tmp.10="RootDirectory="
 tmp.11="LoginDirectory="
 tmp.12="ClientAddress=*"
 tmp.13="MaxBandwidth=0"
 tmp.14="MemberOfGroups=users"
 tmp.0=14
 call stream Globals.!UserPath||"\"||emailid, 'c', 'open write'
 do i=1 to tmp.0
  call lineout Globals.!UserPath||"\"||emailid,tmp.i
 end
 call stream Globals.!UserPath||"\"||emailid, 'c', 'close'
 call LoadUsers_IPS
end; else if Globals.!UserDataBase=3 then do
 /* INETMAIL */
 rc=SysIni(Globals.!UserPath||"\INETMAIL.INI",'InetMail','defmaildir')||"\"||emailid
 tmp.realname=username
 tmp.username=emailid
 tmp.password=password
 tmp.emaildir=rc
 tmp.passtype="PASS"
 tmp.forward="FALSE"
 tmp.localproc="FALSE"
 tmp.ccmail="FALSE"
 call SysMkDir rc
 call HCreateUser Globals.!UserPath||"\InetMail.pas", tmp.
 call LoadUsers_InetMail
end; else if Globals.!UserDataBase=5 then do
 /* INETMAIL PRO */
end; else if Globals.!UserDataBase=7 then do
 /* OS2PopS */
 ConfigFile=Globals.!UserPath||"\UserInfo\OS2POPS.Users"
 call lineout ConfigFile,'01'x||emailid||domain||'01'x||password||'01'x||username||'01'x
end
return

/*:VRX         User_Update
*/
User_Update: procedure
call VRMethod "Application","GetVar","Globals.!OnlineUsr.","Globals.!OnlineUsr."
call VRInfo "temp."
i=temp.!i
Globals.!OnlineUsr.i=temp.!userdata
call VRMethod "Application","PutVar","Globals.!OnlineUsr.","Globals.!OnlineUsr."
return

/*:VRX         Window1_Close
*/
Window1_Close:
call Quit
return

/*:VRX         Window1_Create
*/
Window1_Create: procedure expose Globals.
call VRSet "Window1","Caption","WebMail/2 - Initializing..."

/* load users from the selected usersdatabase */
if Globals.!UserDataBase=1 then call LoadUsers_Internal
else if Globals.!UserDataBase=2 then call LoadUsers_IPS
else if Globals.!UserDataBase=3 then call LoadUsers_InetMail
else if Globals.!UserDataBase=4 then call LoadUsers_Weasel
else if Globals.!UserDataBase=5 then call LoadUsers_InetMailPro
else if Globals.!UserDataBase=6 then nop
else if Globals.!UserDataBase=7 then call LoadUsers_OS2PopS
else if Globals.!UserDataBase=8 then call LoadUsers_ZxMail
else if Globals.!UserDataBase=9 then call LoadUsers_WeaselPro
else do
 call VRMessage VRWindow(), "Error loading users database, please reset the ini file.","Error","E"
 signal Quit
end

/* Load WebServer Access page settings */
ConfigFile=Globals.!WorkingDir||"\WebManager.acc"
i=stream(ConfigFile,'c','open')
if pos("NOTREADY",i)>0 then do
 call VRMessage VRWindow(),"Can't load access file","Error","E"
 signal Quit
end
i=0
do while lines(ConfigFile)>0
 tmp=linein(ConfigFile)
 if substr(tmp,1,1)<>"#" & tmp<>"" & tmp<>'0d0a'x then do
  i=i+1
  Globals.!Access.i=space(tmp)
 end
end
Globals.!Access.0=i
call VRMethod "Application","PutVar","Globals.!Access.","Globals.!Access."

/* Load Client Access page settings */
ConfigFile=Globals.!WorkingDir||"\WebManager.cli"
i=stream(ConfigFile,'c','open')
if pos("NOTREADY",i)>0 then do
 call VRMessage VRWindow(),"Can't load access client file","Error","E"
 signal Quit
end
i=0
do while lines(ConfigFile)>0
 tmp=linein(ConfigFile)
 if substr(tmp,1,1)<>"#" & tmp<>"" & tmp<>'0d0a'x then do
  i=i+1
  Globals.!AccessCli.i=space(tmp)
 end
end
Globals.!AccessCli.0=i
call VRMethod "Application","PutVar","Globals.!AccessCli.","Globals.!AccessCli."

/* Load User Blacklist */
ConfigFile=Globals.!WorkingDir||"\WebManager.blk"
i=stream(ConfigFile,'c','open')
if pos("NOTREADY",i)>0 then do
 call VRMessage VRWindow(),"Can't load Blacklist file","Error","E"
 signal Quit
end
i=0
do while lines(ConfigFile)>0
 tmp=linein(ConfigFile)
 if substr(tmp,1,1)<>"#" & tmp<>"" & tmp<>'0d0a'x then do
  i=i+1
  Globals.!AccessBan.i=space(tmp)
 end
end
Globals.!AccessBan.0=i
call VRMethod "Application","PutVar","Globals.!AccessBan.","Globals.!AccessBan."

/* Load Accessible Domains */
ConfigFile=Globals.!WorkingDir||"\WebManager.dom"
i=stream(ConfigFile,'c','open')
if pos("NOTREADY",i)>0 then do
 call VRMessage VRWindow(),"Can't load domains file","Error","E"
 signal Quit
end
i=0
do while lines(ConfigFile)>0
 tmp=linein(ConfigFile)
 if substr(tmp,1,1)<>"#" & tmp<>"" & tmp<>'0d0a'x then do
  i=i+1
  Globals.!AccessDom.i=space(tmp)
 end
end
Globals.!AccessDom.0=i
call VRMethod "Application","PutVar","Globals.!AccessDom.","Globals.!AccessDom."

/* Misc */
call VRSet "TM_2","Delay",Globals.!PasswordTimeout*60000
call VRSet "TM_2","Enabled", 1
if Globals.!UserDataBase=2|Globals.!UserDataBase=4|Globals.!UserDataBase=7|Globals.!UserDataBase=9 then do
 call VRSet "TM_1","Delay",Globals.!Timer*60000
 call VRSet "TM_1","Enabled",1
end
/* Make sure the database directory exists */
if VRIsDir(Globals.!WorkingDir||"\database")=0 then call VRMkDir Globals.!WorkingDir||"\database"

/* Load the Spawner */
tid=VRMethod("Application","StartThread","Spawner",Globals.!Port,Globals.!IP)
if tid=-1 then do
 call VRMessage VRWindow(),"Error creating Spawner thread","Error","E"
 return
end
threads.0=0
loop UNTIL threads.0 > 1
do
 call VRMethod "Application","ListThreads","threads."
end
call Refresh

/* end init */
call VRSet "Window1","Caption","WebMail/2 v"||Globals.!Version||" - WebManager"
return

