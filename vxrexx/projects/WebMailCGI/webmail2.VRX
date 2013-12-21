/*:VRX         Main
*/
Main:
/* WebMail/2 beta 102 Dimitrios 'sehh' Michelinakis <dimitris@michelinakis.gr> */

Globals.!serv=127.0.0.1 /* IP address of the machine running WebManager */
Globals.!port=3511      /* Port that WebManager listens to */
Globals.!WMPath=""      /* Path to .WM files, default is %etc%\webmailhtml\ */
                        /* the ending backslash is required */
Globals.!PrefixPath=""  /* Optional variable for custom image/CSS location */
Globals.!MaxEmails=10   /* Maximum emails listed per page */
Globals.!CharSet="iso-8859-1" /* Default charater set */
Globals.!TagLine="NO"   /* Experimental tag lines */
Globals.!MaxAttachSize="2097152" /* Max attachment size (2MB default) */

/* WebMail/2 */
parse SOURCE Globals.!myinfo .
if Globals.!myinfo="OS/2" then do
 call RxFuncAdd 'SysLoadFuncs','RexxUtil','SysLoadFuncs'
 call SysLoadFuncs
 call RxFuncAdd 'SockLoadFuncs','RxSock','SockLoadFuncs'
 call SockLoadFuncs(1)
 call RxFuncAdd 'DCLoadFuncs','rxDCplus','DCLoadFuncs'
 call DCLoadFuncs
end; else if Globals.!myinfo="UNIX" then do
 call RxFuncAdd 'SockLoadFuncs','rxsock','SockLoadFuncs'
 call SockLoadFuncs
end
Globals.!myinfo="WebMail/2 for OS/2"
Globals.!myself=translate(value("SCRIPT_NAME",,'ENVIRONMENT'),"/","\")
if Globals.!WMPath="" then Globals.!WMPath=value("ETC",,'ENVIRONMENT')||"\webmailhtml\"
if value("WEBMAIL2_SERV",,'ENVIRONMENT')<>"" then Globals.!serv=value("WEBMAIL2_SERV",,'ENVIRONMENT')
if value("WEBMAIL2_PORT",,'ENVIRONMENT')<>"" then Globals.!port=value("WEBMAIL2_PORT",,'ENVIRONMENT')
if value("WEBMAIL2_PATH",,'ENVIRONMENT')<>"" then Globals.!WMPath=value("WEBMAIL2_PATH",,'ENVIRONMENT')
if value("WEBMAIL2_PPATH",,'ENVIRONMENT')<>"" then Globals.!PrefixPath=value("WEBMAIL2_PPATH",,'ENVIRONMENT')
if value("WEBMAIL2_MAXE",,'ENVIRONMENT')<>"" then Globals.!MaxEmails=value("WEBMAIL2_MAXE",,'ENVIRONMENT')
if value("WEBMAIL2_CHARSET",,'ENVIRONMENT')<>"" then Globals.!CharSet=value("WEBMAIL2_CHARSET",,'ENVIRONMENT')
if value("WEBMAIL2_MAXSIZE",,'ENVIRONMENT')<>"" then Globals.!MaxAttachSize=value("WEBMAIL2_MAXSIZE",,'ENVIRONMENT')
if value("REQUEST_METHOD",,'ENVIRONMENT')="GET" then do
 if pos(Globals.!myself,value("HTTP_REFERER",,'ENVIRONMENT'))<1 then call UserLoginScreen
 Globals.!querystring=URLDecode(value("QUERY_STRING",,'ENVIRONMENT'))
 parse value Globals.!querystring with Globals.!stat1 "&" Globals.!stat2 "&" Globals.!stat3
 if pos("refresh",Globals.!stat1)=1 then call CheckLogon "checkemail"
 else if pos("read",Globals.!stat1)=1 then call CheckLogon "read"
 else if pos("new",Globals.!stat1)=1 then call CheckLogon "new"
 else if pos("delete",Globals.!stat1)=1 then call CheckLogon "delete"
 else if pos("logoff",Globals.!stat1)=1 then call CheckLogon "logoff"
 else if pos("download",Globals.!stat1)=1 then call CheckLogon "download"
 else if pos("help",Globals.!stat1)=1 then call CheckLogon "help"
 else if pos("addr",Globals.!stat1)=1 then call CheckLogon "addr"
 else if pos("email",Globals.!stat1)=1 then call CheckLogon "email"
 else if pos("sign",Globals.!stat1)=1 then call CheckLogon "sign"
 else if pos("userscr",Globals.!stat1)=1 then call NewUserScreen
end; else do
 Globals.!ContentLength=value("CONTENT_LENGTH",,'ENVIRONMENT')
 if Globals.!ContentLength>=Globals.!MaxAttachSize then do
  say "Status: 406 Not Acceptable"
  call ErrorScreen 1,"Attachment size too large."
 end
 if Globals.!ContentLength>0 then Globals.!querystring=charin(,,Globals.!ContentLength)
 Globals.!ContentType=value("CONTENT_TYPE",,'ENVIRONMENT')
 if pos("multipart/form-data",Globals.!ContentType)>0 then do
  if pos(Globals.!myself,value("HTTP_REFERER",,'ENVIRONMENT'))<1 then call UserLoginScreen
  Globals.!stat1="postnew"
  call CheckLogon "postnew"
 end; else do
  Globals.!queryencoded=Globals.!querystring
  Globals.!querystring=URLDecode(Globals.!querystring)
  parse value Globals.!querystring with Globals.!stat1 "&" Globals.!stat2 "&" Globals.!stat3
  if pos("flogin=",Globals.!stat1)=1 then call CheckLogon "fcheckemail"
  if pos("userreg=",Globals.!stat1)=1 then call NewUser
  if pos("addressbadd=",Globals.!stat1)=1 then call CheckLogon "addr"
  if pos("emailadd=",Globals.!stat1)=1 then call CheckLogon "email"
  if pos("signaturesave=",Globals.!stat1)=1 then call CheckLogon "sign"
 end
end
call UserLoginScreen
return

/*:VRX         AddrScreen
*/
AddrScreen: procedure expose Globals.
Globals.!ServerErr=""
Globals.!AddrAlias=""
Globals.!AddrName=""
Globals.!AddrEmail=""
if Globals.!stat1="addressbadd=1" then do
 parse value Globals.!querystring with . "&returnto=" Globals.!stat2 "&a=" Globals.!AddrAlias "&n=" Globals.!AddrName "&e=" Globals.!AddrEmail
 if pos(":",Globals.!AddrAlias)>0 then Globals.!ServerErr="Invalid characters detected"
 else if pos("@",Globals.!AddrEmail)<1 then Globals.!ServerErr="Invalid email address"
 else if Globals.!AddrAlias=""&Globals.!AddrName="" then Globals.!ServerErr="The alias and name fields are both incomplete"
 else if Globals.!AddrEmail="" then Globals.!ServerErr="Email field is incomplete"
 else do
  call ConnectManager
  Globals.!clientIP=value("REMOTE_ADDR",,'ENVIRONMENT')
  if Globals.!clientIP="" then call ErrorScreen 1,"CheckLogon: Can't detect your client"
  cookie=substr(Globals.!Cookie,pos("WEBMAIL2=",Globals.!Cookie)+9,33)
  call SendData "6:"||cookie||":"||Globals.!clientIP||":"||Globals.!AddrAlias||":"||Globals.!AddrName||":"||Globals.!AddrEmail||":"||'0d0a'x
  call ReceiveData
  if substr(newData,1,1)=1 then Globals.!ServerErr="User added successfully"
  else if substr(newData,1,1)=3 then Globals.!ServerErr="Alias already exists"
  else if substr(newData,1,1)=2 then Globals.!ServerErr="Name already exists"
  else if substr(newData,1,1)=4 then Globals.!ServerErr="Email address already exists"
 end
 if Globals.!stat2>0 then do
  Globals.!stat3=""
  call ReceiveEmail
 end
 Globals.!stat2="a"
 Globals.!stat3=""
end
if Globals.!stat2="a" then do
 i=0
 if Globals.!stat3<>"" then do
  parse value Globals.!stat3 with i "&" Globals.!stat3
  Globals.!stat3=RXB64decode(Globals.!stat3)
  if pos(" ",Globals.!stat3)>0 then do
   Globals.!AddrEmail=substr(Globals.!stat3,lastpos(" ",Globals.!stat3)+1)
   Globals.!AddrName=substr(Globals.!stat3,1,lastpos(" ",Globals.!stat3)-1)
  end; else Globals.!AddrEmail=Globals.!stat3
  if pos("<",Globals.!AddrEmail)>0 then Globals.!AddrEmail=translate(Globals.!AddrEmail,"","<")
  if pos(">",Globals.!AddrEmail)>0 then Globals.!AddrEmail=translate(Globals.!AddrEmail,"",">")
  Globals.!AddrEmail=space(Globals.!AddrEmail)
  if pos('"',Globals.!AddrName)>0 then Globals.!AddrName=space(translate(Globals.!AddrName,"",'"'))
  if pos("=?",Globals.!AddrName)=1 then do
   parse value Globals.!AddrName with . "?" . "?" . "?" Globals.!AddrName "?" .
   Globals.!AddrName=RXdeQuoted(Globals.!AddrName)
  end
 end
 call ParseHTML Globals.!WMPath||"header.wm",1
 call ParseHTML Globals.!WMPath||"addressb-add.wm"
 call ParseHTML Globals.!WMPath||"footer.wm"
 exit
end
if Globals.!stat2="d" then do
 call ConnectManager
 Globals.!clientIP=value("REMOTE_ADDR",,'ENVIRONMENT')
 if Globals.!clientIP="" then call ErrorScreen 1,"CheckLogon: Can't detect your client"
 cookie=substr(Globals.!Cookie,pos("WEBMAIL2=",Globals.!Cookie)+9,33)
 call SendData "7:"||cookie||":"||Globals.!clientIP||":"||Globals.!stat3||":"||'0d0a'x
 call ReceiveData
 if substr(newData,1,1)=1 then Globals.!ServerErr="Removed email "||Globals.!stat3
 else if substr(newData,1,1)=2 then Globals.!ServerErr="Couldn't remove email "||Globals.!stat3
end
call ConnectManager
Globals.!clientIP=value("REMOTE_ADDR",,'ENVIRONMENT')
if Globals.!clientIP="" then call ErrorScreen 1,"CheckLogon: Can't detect your client"
cookie=substr(Globals.!Cookie,pos("WEBMAIL2=",Globals.!Cookie)+9,33)
call SendData "5:"||cookie||":"||Globals.!clientIP||":"||'0d0a'x
call ReceiveDataExtended 32768
book=newData
rc=SockSoClose(socket)
if rc=-1 then call ErrorScreen 1,"CheckLogon: Error on SockSoClose"
if ARG(1)=1 then return book
call ParseHTML Globals.!WMPath||"header.wm",1
Globals.!AddrTable=""
if pos(":",book)>0 then do
 do while pos(":",book)>0
  parse value book with Globals.!AddrAlias ":" Globals.!AddrName ":" Globals.!AddrEmail '0d0a'x book
  Globals.!AddrTable=Globals.!AddrTable||ParseHTML(Globals.!WMPath||"addressb-table.wm",0,1)
 end
end
call ParseHTML Globals.!WMPath||"addressb.wm"
call ParseHTML Globals.!WMPath||"footer.wm"
exit

/*:VRX         EmailScreen
*/
EmailScreen: procedure expose Globals.
if Globals.!ServerErr="GLOBALS.!SERVERERR" then Globals.!ServerErr=""
Globals.!AddrName=""
Globals.!AddrEmail=""
if Globals.!stat1="emailadd=1" then do
 parse value Globals.!querystring with . "&returnto=" Globals.!stat2 "&n=" Globals.!AddrName "&e=" Globals.!AddrEmail
 if pos("@",Globals.!AddrEmail)<1 then Globals.!ServerErr="Invalid email address"
 tmp=Globals.!AddrName||Globals.!AddrEmail
 if pos('"',tmp)>0|pos("'",tmp)>0|pos("<",tmp)>0|pos(">",tmp)>0|pos(":",tmp)>0|pos("&",tmp)>0 then do
  Globals.!ServerErr="Invalid characters detected"
 end; else do
  email='"'||Globals.!AddrName||'" <'||Globals.!AddrEmail||'>'
  call ConnectManager
  Globals.!clientIP=value("REMOTE_ADDR",,'ENVIRONMENT')
  if Globals.!clientIP="" then call ErrorScreen 1,"CheckLogon: Can't detect your client"
  cookie=substr(Globals.!Cookie,pos("WEBMAIL2=",Globals.!Cookie)+9,33)
  call SendData "b:"||cookie||":"||Globals.!clientIP||":"||email||":"||'0d0a'x
  call ReceiveData
  if substr(newData,1,1)=1 then Globals.!ServerErr="Email added successfully"
  else if substr(newData,1,1)=2 then Globals.!ServerErr="Email address already exists"
 end
 if Globals.!stat2>0 then do
  Globals.!stat3=""
  call ReceiveEmail
 end
 Globals.!stat2="a"
 Globals.!stat3=""
end
if Globals.!stat2="a" then do
 i=0
 if Globals.!stat3<>"" then do
  parse value Globals.!stat3 with i "&" Globals.!stat3
  Globals.!stat3=RXB64decode(Globals.!stat3)
  if pos(" ",Globals.!stat3)>0 then do
   Globals.!AddrEmail=substr(Globals.!stat3,lastpos(" ",Globals.!stat3)+1)
   Globals.!AddrName=substr(Globals.!stat3,1,lastpos(" ",Globals.!stat3)-1)
  end; else Globals.!AddrEmail=Globals.!stat3
 end
 call ParseHTML Globals.!WMPath||"header.wm",1
 call ParseHTML Globals.!WMPath||"email-add.wm"
 call ParseHTML Globals.!WMPath||"footer.wm"
 exit
end
if Globals.!stat2="d" then do
 call ConnectManager
 Globals.!clientIP=value("REMOTE_ADDR",,'ENVIRONMENT')
 if Globals.!clientIP="" then call ErrorScreen 1,"CheckLogon: Can't detect your client"
 cookie=substr(Globals.!Cookie,pos("WEBMAIL2=",Globals.!Cookie)+9,33)
 call SendData "c:"||cookie||":"||Globals.!clientIP||":"||Globals.!stat3||":"||'0d0a'x
 call ReceiveData
 if substr(newData,1,1)=1 then Globals.!ServerErr="Email removed successfully"
 else if substr(newData,1,1)=2 then Globals.!ServerErr="Could not remove email"
end
call ConnectManager
Globals.!clientIP=value("REMOTE_ADDR",,'ENVIRONMENT')
if Globals.!clientIP="" then call ErrorScreen 1,"CheckLogon: Can't detect your client"
cookie=substr(Globals.!Cookie,pos("WEBMAIL2=",Globals.!Cookie)+9,33)
call SendData "a:"||cookie||":"||Globals.!clientIP||":"||'0d0a'x
call ReceiveDataExtended 32768
book=substr(newData,1,length(newData)-3)
rc=SockSoClose(socket)
if rc=-1 then call ErrorScreen 1,"CheckLogon: Error on SockSoClose"
if ARG(1)=1 then do
 if Globals.!realname="" then
  return '<'||Globals.!user||'>'||'0d0a'x||book
 else
  return '"'||Globals.!realname||'" <'||Globals.!user||'>'||'0d0a'x||book
end
call ParseHTML Globals.!WMPath||"header.wm",1
Globals.!ListTable=""
i=0
if pos('0d0a'x,book)>0 then do
 do while pos('0d0a'x,book)>0
  parse value book with Globals.!AddrEmail '0d0a'x book
  Globals.!AddrEmail=ReplaceStr(Globals.!AddrEmail,"<","&lt;")
  Globals.!AddrEmail=ReplaceStr(Globals.!AddrEmail,">","&gt;")
  i=i+1
  Globals.!ListTable=Globals.!ListTable||ParseHTML(Globals.!WMPath||"email-table.wm",0,1)
 end
end
call ParseHTML Globals.!WMPath||"email.wm"
call ParseHTML Globals.!WMPath||"footer.wm"
exit

/*:VRX         calcMD5
*/
calcMD5: procedure
parse arg stuff
numeric digits 11
lenstuff=length(stuff)
c0=d2c(0)
c1=d2c(128)
c1a=d2c(255)
c1111=c1a||c1a||c1a||c1a
slen=length(stuff)*8
slen512=slen//512
if slen512=448 then  addme=512
if slen512<448 then addme=448-slen512
if slen512>448 then addme=960-slen512
addwords=addme/8
apad=c1||copies(c0,addwords-1)
xlen=reverse(right(d2c(lenstuff*8),4,c0))||c0||c0||c0||c0  /* 2**32 max bytes in message */
newstuff=stuff||apad||xlen
a='67452301'x;
b='efcdab89'x;
c='98badcfe'x;
d='10325476'x;
lennews=length(newstuff)/4
do i1 = 0 to ((lennews/16)-1)
 i16=i1*64
 do j=1 to 16
  j4=((j-1)*4)+1
  jj=i16+j4
  m.j=reverse(substr(newstuff,jj,4))
 end
 aa=a;bb=b;cc=c;dd=d
 S11=7
 S12=12
 S13=17
 S14=22
 a=round1( a, b, c, d,   0 , S11, 3614090360); /* 1 */
 d=round1( d, a, b, c,   1 , S12, 3905402710); /* 2 */
 c=round1( c, d, a, b,   2 , S13,  606105819); /* 3 */
 b=round1( b, c, d, a,   3 , S14, 3250441966); /* 4 */
 a=round1( a, b, c, d,   4 , S11, 4118548399); /* 5 */
 d=round1( d, a, b, c,   5 , S12, 1200080426); /* 6 */
 c=round1( c, d, a, b,   6 , S13, 2821735955); /* 7 */
 b=round1( b, c, d, a,   7 , S14, 4249261313); /* 8 */
 a=round1( a, b, c, d,   8 , S11, 1770035416); /* 9 */
 d=round1( d, a, b, c,   9 , S12, 2336552879); /* 10 */
 c=round1( c, d, a, b,  10 , S13, 4294925233); /* 11 */
 b=round1( b, c, d, a,  11 , S14, 2304563134); /* 12 */
 a=round1( a, b, c, d,  12 , S11, 1804603682); /* 13 */
 d=round1( d, a, b, c,  13 , S12, 4254626195); /* 14 */
 c=round1( c, d, a, b,  14 , S13, 2792965006); /* 15 */
 b=round1( b, c, d, a,  15 , S14, 1236535329); /* 16 */
 S21=5
 S22=9
 S23=14
 S24=20
 a= round2( a, b, c, d,   1 , S21, 4129170786); /* 17 */
 d= round2( d, a, b, c,   6 , S22, 3225465664); /* 18 */
 c=  round2( c, d, a, b,  11 , S23,  643717713); /* 19 */
 b=  round2( b, c, d, a,   0 , S24, 3921069994); /* 20 */
 a=  round2( a, b, c, d,   5 , S21, 3593408605); /* 21 */
 d=  round2( d, a, b, c,  10 , S22,   38016083); /* 22 */
 c=  round2( c, d, a, b,  15 , S23, 3634488961); /* 23 */
 b= round2( b, c, d, a,   4 , S24, 3889429448); /* 24 */
 a= round2( a, b, c, d,   9 , S21,  568446438); /* 25 */
 d= round2( d, a, b, c,  14 , S22, 3275163606); /* 26 */
 c=  round2( c, d, a, b,   3 , S23, 4107603335); /* 27 */
 b=  round2( b, c, d, a,   8 , S24, 1163531501); /* 28 */
 a=  round2( a, b, c, d,  13 , S21, 2850285829); /* 29 */
 d=  round2( d, a, b, c,   2 , S22, 4243563512); /* 30 */
 c=  round2( c, d, a, b,   7 , S23, 1735328473); /* 31 */
 b= round2( b, c, d, a,  12 , S24, 2368359562); /* 32 */
 S31= 4
 S32= 11
 S33= 16
 S34= 23
 a= round3( a, b, c, d,   5 , S31, 4294588738); /* 33 */
 d=  round3( d, a, b, c,   8 , S32, 2272392833); /* 34 */
 c=  round3( c, d, a, b,  11 , S33, 1839030562); /* 35 */
 b=  round3( b, c, d, a,  14 , S34, 4259657740); /* 36 */
 a=  round3( a, b, c, d,   1 , S31, 2763975236); /* 37 */
 d=  round3( d, a, b, c,   4 , S32, 1272893353); /* 38 */
 c=  round3( c, d, a, b,   7 , S33, 4139469664); /* 39 */
 b=  round3( b, c, d, a,  10 , S34, 3200236656); /* 40 */
 a=  round3( a, b, c, d,  13 , S31,  681279174); /* 41 */
d=  round3( d, a, b, c,   0 , S32, 3936430074); /* 42 */
c=  round3( c, d, a, b,   3 , S33, 3572445317); /* 43 */
b=  round3( b, c, d, a,   6 , S34,   76029189); /* 44 */
a=  round3( a, b, c, d,   9 , S31, 3654602809); /* 45 */
d=  round3( d, a, b, c,  12 , S32, 3873151461); /* 46 */
c=  round3( c, d, a, b,  15 , S33,  530742520); /* 47 */
b=  round3( b, c, d, a,   2 , S34, 3299628645); /* 48 */
S41=6
S42=10
S43=15
s44=21
a=round4( a, b, c, d,   0 , S41, 4096336452); /* 49 */
d=round4( d, a, b, c,   7 , S42, 1126891415); /* 50 */
c=round4( c, d, a, b,  14 , S43, 2878612391); /* 51 */
b=round4( b, c, d, a,   5 , s44, 4237533241); /* 52 */
a=round4( a, b, c, d,  12 , S41, 1700485571); /* 53 */
d=round4( d, a, b, c,   3 , S42, 2399980690); /* 54 */
c=round4( c, d, a, b,  10 , S43, 4293915773); /* 55 */
b=round4( b, c, d, a,   1 , s44,  2240044497); /* 56 */
a=round4( a, b, c, d,   8 , S41, 1873313359); /* 57 */
d=round4( d, a, b, c,  15 , S42, 4264355552); /* 58 */
c=round4( c, d, a, b,   6 , S43, 2734768916); /* 59 */
b=round4( b, c, d, a,  13 , s44, 1309151649); /* 60 */
a=round4( a, b, c, d,   4 , S41, 4149444226); /* 61 */
d=round4( d, a, b, c,  11 , S42, 3174756917); /* 62 */
c=round4( c, d, a, b,   2 , S43,  718787259); /* 63 */
b=round4( b, c, d, a,   9 , s44, 3951481745); /* 64 */
a=m32add(aa,a) ; b=m32add(bb,b) ; c=m32add(cc,c) ; d=m32add(dd,d)
end
aa=c2x(reverse(a))||c2x(reverse(b))||c2x(reverse(C))||c2x(reverse(D))
return aa

round1:procedure expose m. c1111 c0 c1
parse arg a1,b1,c1,d1,kth,shift,sini
kth=kth+1
t1=c2d(a1)+c2d(f(b1,c1,d1))+ c2d(m.kth) + sini
t1a=right(d2c(t1),4,c0)
t2=rotleft(t1a,shift)
t3=m32add(t2,b1)
return t3

round2:procedure expose m. c1111 c0 c1
parse arg a1,b1,c1,d1,kth,shift,sini
kth=kth+1
t1=c2d(a1)+c2d(g(b1,c1,d1))+ c2d(m.kth) + sini
t1a=right(d2c(t1),4,c0)
t2=rotleft(t1a,shift)
t3=m32add(t2,b1)
return t3

round3:procedure expose m. c1111 c0 c1
parse arg a1,b1,c1,d1,kth,shift,sini
kth=kth+1
t1=c2d(a1)+c2d(h(b1,c1,d1))+ c2d(m.kth) + sini
t1a=right(d2c(t1),4,c0)
t2=rotleft(t1a,shift)
t3=m32add(t2,b1)
return t3

round4:procedure expose m. c1111 c0 c1
parse arg a1,b1,c1,d1,kth,shift,sini
kth=kth+1
t1=c2d(a1)+c2d(i(b1,c1,d1))+ c2d(m.kth) + sini
t1a=right(d2c(t1),4,c0)
t2=rotleft(t1a,shift)
t3=m32add(t2,b1)
return t3

m32add:procedure expose c0 c1 c1111
parse arg v1,v2
t1=c2d(v1)+c2d(v2)
t2=d2c(t1)
t3=right(t2,4,c0)
return t3

f:procedure expose c0 c1 c1111 
parse arg x,y,z
t1=bitand(x,y)
notx=bitxor(x,c1111)
t2=bitand(notx,z)
return bitor(t1,t2)

g:procedure expose c0 c1 c1111
parse arg x,y,z
t1=bitand(x,z)
notz=bitxor(z,c1111)
t2=bitand(y,notz)
return bitor(t1,t2)

h:procedure expose c0 c1 c1111
parse arg x,y,z
t1=bitxor(x,y)
return bitxor(t1,z)

i:procedure expose c0 c1 c1111
parse arg x,y,z
notz=bitxor(z,c1111)
t2=bitor(x,notz)
return bitxor(y,t2)

rotleft:procedure 
parse arg achar,s
if s=0 then return achar

bits=x2b(c2x(achar))
lb=length(bits)
t1=left(bits,s)
t2=bits||t1
yib=right(t2,lb)
return x2c(b2x(yib))

/*:VRX         CheckEmail
*/
CheckEmail: procedure expose Globals.
call ConnectPOP
call SendData "STAT"||'0d0a'x
call ReceiveData
if substr(newData,1,3)<>"+OK" then do
 call SendData "QUIT"||'0d0a'x
 call ErrorScreen 2,"CheckEmail: Email server couldn't get status"
end
parse value newData with . Globals.!totalmail Globals.!totalsize
if datatype(Globals.!totalmail,"N")<>1 then do
 call SendData "QUIT"||'0d0a'x
 call ErrorScreen 2,"CheckEmail: Server returned wrong value"
end
jumpnumber=0
Globals.!JumpTable=""
if Globals.!totalmail>Globals.!MaxEmails then do
 jumpnumber=Globals.!totalmail / Globals.!MaxEmails
 if pos(".",jumpnumber)>0 then jumpnumber=substr(jumpnumber,1,pos(".",jumpnumber)-1)+1
 if Globals.!stat2<=jumpnumber then zzz=Globals.!stat2
 else zzz=1
 do zz=1 to jumpnumber
  Globals.!JumpPage=zz
  if zz=zzz then
   Globals.!JumpTable=Globals.!JumpTable||ParseHTML( Globals.!WMPath||"jump-table-current.wm",0,1 )
  else
   Globals.!JumpTable=Globals.!JumpTable||ParseHTML( Globals.!WMPath||"jump-table.wm",0,1 )
 end
end
if Globals.!stat2<=jumpnumber & Globals.!totalmail>=1 then do
 Globals.!SetCookiePage=Globals.!stat2
 zz=Globals.!stat2 * Globals.!MaxEmails
 EmailStart=zz - Globals.!MaxEmails + 1
 if zz>Globals.!totalmail then zz=Globals.!totalmail
 Globals.!totalmail=zz
end; else if Globals.!totalmail>=1 then do
 Globals.!SetCookiePage=1
 if Globals.!totalmail>Globals.!MaxEmails then Globals.!totalmail=Globals.!MaxEmails
 EmailStart=1
end; else EmailStart=0
zz=0
if Globals.!totalmail>0 then do
 do i=EmailStart to Globals.!totalmail
  call SendData "TOP "||i||" 0"||'0d0a'x
  call ReceiveData 3
  if substr(newData,1,3)="+OK" then do
   call ReceiveDataExtended 32768
   zz=zz+1
   ListMail.i.!h=newData
  end
 end
end
ListMail.0=zz
call SendData "QUIT"||'0d0a'x
rc=SockSoClose(socket)
if rc=-1 then call ErrorScreen 3,"CheckEmail: Error on SockSoClose"
call ParseHTML Globals.!WMPath||"header.wm",1
if ListMail.0>0 then do
 Globals.!ListTable=""
 do i=EmailStart to Globals.!totalmail
  call ScanHeaders 1
  if ListMail.i.!XFace<>"" then ListMail.i.!XFace='<img align="middle" border=0 src="'||Globals.!myself||'?read&'||i||'&x" alt="X-Face" title="X-Face">'
  if ListMail.i.!ContentType="YES" then Globals.!ContentType=ParseHTML(Globals.!WMPath||"attachment-yes.wm",0,1)
  else Globals.!ContentType=ParseHTML(Globals.!WMPath||"attachment-no.wm",0,1)
  if ListMail.i.!Priority="High" then Globals.!Priority=ParseHTML(Globals.!WMPath||"priority-high.wm",0,1)
  else do
   if ListMail.i.!Priority="Low" then Globals.!Priority=ParseHTML(Globals.!WMPath||"priority-low.wm",0,1)
   else Globals.!Priority=ParseHTML(Globals.!WMPath||"priority-normal.wm",0,1)
  end 
  Globals.!ListTable=Globals.!ListTable||ParseHTML(Globals.!WMPath||"listemails-table.wm",0,1)
 end
 call ParseHTML Globals.!WMPath||"listemails.wm"
end; else call ParseHTML Globals.!WMPath||"nomail.wm"
call ParseHTML Globals.!WMPath||"footer.wm"
exit

/*:VRX         CheckLogon
*/
CheckLogon: procedure expose Globals.
Globals.!ServerErr=""
Globals.!clientIP=value("REMOTE_ADDR",,'ENVIRONMENT')
if Globals.!clientIP="" then call ErrorScreen 1,"CheckLogon: Can't detect your client"
if ARG(1)="fcheckemail" then tmp1=0
else if ARG(1)="logoff" then tmp1=2
else tmp1=1
Globals.!Cookie=value("HTTP_COOKIE",,'ENVIRONMENT')
if tmp1<>0&pos("WEBMAIL2",Globals.!Cookie)<1 then do
 call SysSleep 6
 call ErrorScreen 1,"Login refused"
end
call ConnectManager
if tmp1=0 then do
 Globals.!user=substr(Globals.!stat2,3,length(Globals.!stat2)-2)
 Globals.!pazz=substr(Globals.!stat3,3,length(Globals.!stat3)-2)
 call SendData tmp1||":"||Globals.!user||":"||Globals.!pazz||":"||Globals.!clientIP||":"||'0d0a'x
end; else do
 cookie=substr(Globals.!Cookie,pos("WEBMAIL2=",Globals.!Cookie)+9,33)
 call SendData tmp1||":"||cookie||":"||Globals.!clientIP||":"||'0d0a'x
end
if tmp1<>2 then do
 call ReceiveData
 rc=SockSoClose(socket)
 if rc=-1 then call ErrorScreen 1,"CheckLogon: Error on SockSoClose"
 if pos("[WebManager2] OK",newData)<1 then do
  call SysSleep 6
  call ErrorScreen 1,"Login refused"
 end
 parse value newData with . ":" Globals.!pop3 ":" Globals.!pop3p ":" Globals.!smtp ":" Globals.!smtpp ":" Globals.!AuthID ":" Globals.!user ":" Globals.!pazz ":" Globals.!realname ":"
 if ARG(1)="fcheckemail" then do
  Globals.!SetCookie="SET"
  Globals.!SetCookiePage=1
  Globals.!stat2=1
  Globals.!stat3=""
  call CheckEmail
 end; else if ARG(1)="checkemail" then call CheckEmail
 else if ARG(1)="read" then call ReceiveEmail
 else if ARG(1)="new" then call NewEmailScreen
 else if ARG(1)="postnew" then call NewEmail
 else if ARG(1)="delete" then call DeleteEmail
 else if ARG(1)="download" then call Download
 else if ARG(1)="help" then call HelpScreen
 else if ARG(1)="addr" then call AddrScreen
 else if ARG(1)="email" then call EmailScreen
 else if ARG(1)="sign" then call SignScreen
end; else call UserLoginScreen
call SysSleep 6
call ErrorScreen 1,"Login refused"
return

/*:VRX         ConnectManager
*/
ConnectManager: procedure expose Globals. socket newData
socket=SockSocket("AF_INET","SOCK_STREAM",0)
if socket=-1 then call ErrorScreen 1,"CheckLogon: Error open socket"
call SockSetSockOpt socket,"SOL_SOCKET","SO_RCVTIMEO",10
call SockSetSockOpt socket,"SOL_SOCKET","SO_SNDTIMEO",10
server.!family="AF_INET"
server.!port=Globals.!port
server.!addr=Globals.!serv
rc=SockConnect(socket,"server.!")
if rc=-1 then call ErrorScreen 1,"CheckLogon: Error on Socket/Port connection"
return

/*:VRX         ConnectPOP
*/
ConnectPOP: procedure expose Globals. socket
socket=SockSocket("AF_INET","SOCK_STREAM",0)
if socket=-1 then call ErrorScreen 3,"ConnectPOP: Error open socket"
call SockSetSockOpt socket,"SOL_SOCKET","SO_RCVTIMEO",10
call SockSetSockOpt socket,"SOL_SOCKET","SO_SNDTIMEO",10
server.!family="AF_INET"
server.!port=Globals.!pop3p
server.!addr=Globals.!pop3
rc=SockConnect(socket,"server.!")
if rc=-1 then call ErrorScreen 3,"ConnectPOP: Error on Socket/Port connection"
call ReceiveData
if substr(newData,1,3)<>"+OK" then call ErrorScreen 2,"ConnectPOP: Server refused connection"
if right(Globals.!AuthID,1)=1 then tmpuser=Globals.!user
else parse value Globals.!user with tmpuser "@" tmpdomain
apop=0
tmp1=pos("<",newData)
if tmp1>0 then do
 tmp2=pos("@",newData,tmp1)
 if tmp2>0 then do
  tmp3=pos(">",newData,tmp2)
  if tmp3>0&pos("Inet.Mail",newData)<1 then do
   apop=1
   md5=substr(newData,tmp1,tmp3-tmp1+1)||Globals.!pazz
   md5=translate(calcMD5(md5),"abcdefghijklmnopqrstuvwxyz„”á","ABCDEFGHIJKLMNOPQRSTUVWXYZŽ™šá")
   call SendData "APOP "||tmpuser||" "||md5||'0d0a'x
   call ReceiveData
  end
 end
end
if apop=0 then do
 call SendData "USER "||tmpuser||'0d0a'x
 call ReceiveData
 if substr(newData,1,3)<>"+OK" then do
  call SendData "QUIT"||'0d0a'x
  call ErrorScreen 2,"ConnectPOP: Server refused user login"
 end
 call SendData "PASS "||Globals.!pazz||'0d0a'x
 call ReceiveData
end
if substr(newData,1,3)<>"+OK" then do
 call SendData "QUIT"||'0d0a'x
 call ErrorScreen 2,"ConnectPOP: Failed login, your account is locked, retry later."
end
return

/*:VRX         DeleteEmail
*/
DeleteEmail: procedure expose Globals.
call ConnectPOP
if pos("all",Globals.!stat2)>0 then do
 call SendData "STAT"||'0d0a'x
 call ReceiveData
 if substr(newData,1,3)<>"+OK" then do
  call SendData "QUIT"||'0d0a'x
  call ErrorScreen 2,"DeleteEmail: Email server couldn't get status"
 end
 parse value newData with . Globals.!totalmail .
 if datatype(Globals.!totalmail,"N")<>1 then do
  call SendData "QUIT"||'0d0a'x
  call ErrorScreen 2,"DeleteEmail: Server returned wrong value"
 end
 do i=1 to Globals.!totalmail
  call SendData "DELE "||i||'0d0a'x
  call ReceiveData
  if substr(newData,1,3)<>"+OK" then do
   call SendData "QUIT"||'0d0a'x
   call ErrorScreen 2,"DeleteEmail: Server couldn't delete email or email already deleted"
  end
 end
end; else do
 call SendData "DELE "||Globals.!stat2||'0d0a'x
 call ReceiveData
 if substr(newData,1,3)<>"+OK" then do
  call SendData "QUIT"||'0d0a'x
  call ErrorScreen 2,"DeleteEmail: Server couldn't delete email or email already deleted"
 end
end
call SendData "QUIT"||'0d0a'x
rc=SockSoClose(socket)
if rc=-1 then call ErrorScreen 3,"DeleteEmail: Error on SockSoClose"
say "Status: 301 Moved Permanently"
if Globals.!stat3<>"" then do
 Globals.!stat2=Globals.!stat3-1
 if Globals.!stat2=0 then say 'Location: '||Globals.!myself||"?refresh&1"
 else if Globals.!stat2=-1 then say 'Location: '||Globals.!myself||"?refresh&1"
 else say 'Location: '||Globals.!myself||"?read&"||Globals.!stat2
end; else do
 poz=pos("WEBMAIL2PAGE=",Globals.!Cookie)
 if poz>0 then do
  poz1=pos(";",Globals.!Cookie,poz)
  if poz1>0 then
   Globals.!stat2=substr(Globals.!Cookie,poz+13,poz1-poz-13)
  else
   Globals.!stat2=substr(Globals.!Cookie,poz+13)
  say 'Location: '||Globals.!myself||"?refresh&"||Globals.!stat2
 end; else say 'Location: '||Globals.!myself||"?refresh"
end
say "Cache-Control: no-cache"
say "Pragma: no-cache"
say "Expires: Thu, 01 Dec 1994 16:00:00 GMT"
say "Content-Length: 0"
say ""
exit

/*:VRX         Download
*/
Download: procedure expose Globals.
parse value Globals.!stat2 with Globals.!stat2 ":" FileName
if FileName="unknown" then call ErrorScreen 2,"Download: Unknown file attachment"
call ReceiveEmail 4
ListMail.i.!h=translate(ListMail.i.!h," ",'09'x)
poz=pos('0d0a'x,ListMail.i.!h)+2
do while poz<length(ListMail.i.!h)
 rc=substr(ListMail.i.!h,poz,1)
 if rc=" " then ListMail.i.!h=substr(ListMail.i.!h,1,poz-3)||" "||space(substr(ListMail.i.!h,poz+1))
 poz=pos('0d0a'x,ListMail.i.!h,poz)+2
end
h1=translate(ListMail.i.!h)
if pos("CONTENT-TYPE:",h1)>0 then do
 tmp1=pos("CONTENT-TYPE:",h1)+13
 tmp2=pos('0d0a'x,h1,tmp1)
 tmp3=space(substr(ListMail.i.!h,tmp1,tmp2-tmp1))
 if pos("MULTIPART/MIXED;",translate(tmp3))>0 then do
  boundary=substr(tmp3,pos("BOUNDARY=",translate(tmp3))+9)
  if pos('"',boundary)=1 then boundary=substr(boundary,2,length(boundary)-2)
  boundary="--"||boundary
  pozlength=1
  zi=0
  do while pos(boundary||'0d0a'x,ListMail.i.!b,pozlength)>0
   poz=pos(boundary||'0d0a'x,ListMail.i.!b,pozlength)
   pozlength=pos('0d0a'x||'0d0a'x,ListMail.i.!b,poz)+4
   headerz=substr(ListMail.i.!b,poz,pozlength-poz)
   if pos(FileName,headerz)>0&pos("BASE64",translate(headerz))>0 then do
    pozlength2=pos(boundary,ListMail.i.!b,pozlength)
    ListMail.i.!b=substr(ListMail.i.!b,pozlength,pozlength2-pozlength)
    say 'Content-Type: application/octet-stream'
    say 'Content-Disposition: attachment; filename="'||FileName||'"'
    say 'Content-Length: '||length(ListMail.i.!b)
    say "Cache-Control: no-cache"
    say "Pragma: no-cache"
    say ""
    call charout ,RXB64decode(ListMail.i.!b)
    exit
   end
  end
 end; else call ErrorScreen 2,"Download: Unknown file attachment"
end; else call ErrorScreen 2,"Download: Unknown file attachment"
exit

/*:VRX         ErrorScreen
*/
ErrorScreen: procedure expose Globals.
Globals.!ServerErr=ARG(2)
if ARG(1)=1 then do
 Globals.!SetCookie="SET"
 Globals.!AuthID=""
 call ParseHTML Globals.!WMPath||"loginerror.wm",1
end; else if ARG(1)=2 then do
 call ParseHTML Globals.!WMPath||"header.wm",1
 call ParseHTML Globals.!WMPath||"servererror.wm"
 call ParseHTML Globals.!WMPath||"footer.wm"
end; else if ARG(1)=3 then do
 socket=SockSocket("AF_INET","SOCK_STREAM",0)
 call SockSetSockOpt socket,"SOL_SOCKET","SO_RCVTIMEO",10
 call SockSetSockOpt socket,"SOL_SOCKET","SO_SNDTIMEO",10
 server.!family="AF_INET"
 server.!port=Globals.!port
 server.!addr=Globals.!serv
 call SockConnect socket,"server.!"
 call SockSend socket,"3:"||ARG(2)
 call SockSoClose socket
 call ErrorScreen 2,"Email Server Error!"
end
exit

/*:VRX         HelpScreen
*/
HelpScreen: procedure expose Globals.
call ParseHTML Globals.!WMPath||"header.wm",1
call ParseHTML Globals.!WMPath||"help.wm"
call ParseHTML Globals.!WMPath||"footer.wm"
exit

/*:VRX         Html2Txt
*/
Html2Txt: procedure
html=ARG(1)
chars.1="<"
chars.2=">"
chars.3="&"
chars.4=";"
chars.0=4
do i=1 to chars.0
 z=i+1
 tmp1=1
 do while tmp1>0
  tmp1=pos(chars.i,html,tmp1)
  if tmp1<1 then leave
  tmp2=pos(chars.z,html,tmp1)
  if tmp2<tmp1 then leave
  html=delstr(html,tmp1,tmp2-tmp1+1)
 end
 i=i+1
end
return html

/*:VRX         NewEmail
*/
NewEmail: procedure expose Globals.
parse value Globals.!ContentType with . "boundary=" boundary
if pos('"',boundary)=1 then boundary=substr(boundary,2,length(boundary)-2)
boundary='0d0a'x||"--"||boundary
userfake=""
sendto=""
charset="iso-8859-1"
inreplyto=""
replysel1=""
replyto=""
replysel2=""
ccto=""
bccto=""
subject=""
epriority="Normal"
body=""
filename=""
eol='0d0a'x||'0d0a'x
do 13
 parse value Globals.!querystring with headbody (eol) Globals.!querystring
 if headbody="" then iterate
 else headbody=headbody||'0d0a'x
 poz=pos("CONTENT-DISPOSITION:",translate(headbody))
 if poz<1 then iterate
 pozend=pos('0d0a'x,headbody,poz)
 headval=substr(headbody,poz,pozend-poz)
 if pos("FORM-DATA",translate(headval))<1 then iterate
 if pos("NAME=",translate(headval))<1 then iterate
 headval=substr(headval,pos("NAME=",translate(headval))+5)
 if pos('"',headval)=1 then headval=substr(headval,2,pos('"',headval,2)-2)
 if headval="" then call ErrorScreen 3,"NewEmail: Error reading form while posting email"
 if headval<>"upload_file" then parse value Globals.!querystring with bodyval (boundary) Globals.!querystring
 if headval="f" then userfake=bodyval
 else if headval="t" then sendto=bodyval
 else if headval="charset" then charset=bodyval
 else if headval="inreplyto" then inreplyto=bodyval
 else if headval="rb" then replysel1=bodyval
 else if headval="rt" then replyto=bodyval
 else if headval="rb2" then replysel2=bodyval
 else if headval="c" then ccto=bodyval
 else if headval="b" then bccto=bodyval
 else if headval="s" then subject=bodyval
 else if headval="p" then epriority=bodyval
 else if headval="body" then body=bodyval
 else if headval="upload_file" then do
  headval=substr(headbody,poz,pozend-poz)
  if pos("FILENAME=",translate(headval))<1 then iterate
  headval=substr(headval,pos("FILENAME=",translate(headval))+9)
  if pos('"',headval)=1 then headval=substr(headval,2,pos('"',headval,2)-2)
  if headval<>"" then do
   filename=filespec("name",headval)
   parse value Globals.!querystring with Globals.!querystring (boundary) .
   leave
  end
 end
end
if replysel1="f"&replysel2="" then nop
else if replysel1=""&replysel2="r" then sendto=replyto
else if replysel1="f"&replysel2="r" then sendto=sendto||" "||replyto
else call ErrorScreen 2,"NewEmail: You must select atleast one email target"
if filename<>""&length(Globals.!querystring)>Globals.!MaxAttachSize then call ErrorScreen 2,"NewEmail: Attachment size exceeds the limit of "||format(Globals.!MaxAttachSize/1048576,,1)||" MB"
sendto=ResolveEmails(sendto)
if ccto<>"" then ccto=ResolveEmails(ccto)
if bccto<>"" then bccto=ResolveEmails(bccto)
socket=SockSocket("AF_INET","SOCK_STREAM",0)
if socket=-1 then call ErrorScreen 3,"NewEmail: Error open socket"
call SockSetSockOpt socket,"SOL_SOCKET","SO_RCVTIMEO",10
call SockSetSockOpt socket,"SOL_SOCKET","SO_SNDTIMEO",10
server.!family="AF_INET"
server.!port=Globals.!smtpp
server.!addr=Globals.!smtp
rc=SockConnect(socket,"server.!")
if rc=-1 then call ErrorScreen 3,"NewEmail: Error on Socket/Port connection"
call ReceiveData
if substr(newData,1,3)<>"220" then call ErrorScreen 2,"NewEmail: Server refused connection"
do while substr(newData,4,1)<>" "
 call ReceiveData
end
call SendData "EHLO "||Globals.!clientIP||'0d0a'x
call ReceiveData
if substr(newData,1,3)<>"250" then do
 call SendData "HELO "||Globals.!clientIP||'0d0a'x
 call ReceiveData
end; else do
 multiline=newData
 if pos("250 ",mutiline)<1 then do
  do until pos("250 ",mutiline)<1
   call ReceiveData
   multiline=multiline||newData
  end
 end
 newData="250"
 if pos("AUTH ",multiline)>0 then do
  parse value multiline with . "250" . "AUTH " tmp '0d0a'x .
  tmp=translate(tmp)
  if right(Globals.!AuthID,1)=1 then tmpuser=Globals.!user
  else parse value Globals.!user with tmpuser "@" tmpdomain
  if pos("CRAM-MD5",tmp)>0 then do
   call SendData "AUTH CRAM-MD5"||'0d0a'x
   call ReceiveData
   if substr(newData,1,3)="334" then text=RXB64decode(substr(newData,5))
   else do
    call SendData "QUIT"||'0d0a'x
    call ErrorScreen 2,"NewEmail: SMTP Authentication failure"
   end
   ipad='36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x||'36'x
   opad='5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x||'5C'x
   pwd=Globals.!pazz
   if length(pwd)>64 then pwd=calcMD5(pwd)
   tmp=calcMD5(bitxor(pwd,opad,'00'x)||x2c(calcMD5(bitxor(pwd,ipad,'00'x)||text)))
   call SendData RXB64encode(tmpuser||" "||tmp)
   call ReceiveData
   if substr(newData,1,3)="235" then newData="250"
  end; else if pos("PLAIN",tmp)>0 then do
   call SendData "AUTH PLAIN "||RXB64encode("login"||'0'x||tmpuser||'0'x||Globals.!pazz||'0'x)
   call ReceiveData
   if substr(newData,1,3)="235" then newData="250"
  end; else if pos("LOGIN",tmp)>0 then do
   call SendData "AUTH LOGIN"||'0d0a'x
   call ReceiveData
   if substr(newData,1,3)<>"334" then do
    call SendData "QUIT"||'0d0a'x
    call ErrorScreen 2,"NewEmail: SMTP Authentication failure"
   end
   call SendData RXB64encode(tmpuser)
   call ReceiveData
   if substr(newData,1,3)<>"334" then do
    call SendData "QUIT"||'0d0a'x
    call ErrorScreen 2,"NewEmail: SMTP Authentication failure"
   end
   call SendData RXB64encode(Globals.!pazz)
   call ReceiveData
   if substr(newData,1,3)="235" then newData="250"
  end
 end
end
if substr(newData,1,3)<>"250" then do
 call SendData "QUIT"||'0d0a'x
 call ErrorScreen 2,"NewEmail: Server dropped connection"
end
if userfake="" then tmp=Globals.!user
else parse value userfake with "<" tmp ">"
call SendData "MAIL FROM: <"||tmp||">"||'0d0a'x
call ReceiveData
if substr(newData,1,3)<>"250"&substr(newData,1,3)<>"251" then do
 call SendData "QUIT"||'0d0a'x
 call ErrorScreen 2,"NewEmail: Server rejected email transfer"
end
if pos(" ",sendto)>0 then do
 tmp=sendto
 do while tmp<>""
  parse value tmp with sendto1 tmp
  call SendData "RCPT TO: <"||sendto1||">"||'0d0a'x
  call ReceiveData
  if substr(newData,1,3)<>"250"&substr(newData,1,3)<>"251" then do
   call SendData "QUIT"||'0d0a'x
   call ErrorScreen 2,"NewEmail: Server rejected target email:"||newData
  end
 end
end; else do
 call SendData "RCPT TO: <"||sendto||">"||'0d0a'x
 call ReceiveData
 if substr(newData,1,3)<>"250"&substr(newData,1,3)<>"251" then do
  call SendData "QUIT"||'0d0a'x
  call ErrorScreen 2,"NewEmail: Server rejected target email:"||newData
 end
end
if pos(" ",ccto)>0 then do
 tmp=ccto
 do while tmp<>""
  parse value tmp with sendto1 tmp
  call SendData "RCPT TO: <"||sendto1||">"||'0d0a'x
  call ReceiveData
  if substr(newData,1,3)<>"250"&substr(newData,1,3)<>"251" then do
   call SendData "QUIT"||'0d0a'x
   call ErrorScreen 2,"NewEmail: Server rejected target email"
  end
 end
end; else if ccto<>"" then do
 call SendData "RCPT TO: <"||ccto||">"||'0d0a'x
 call ReceiveData
 if substr(newData,1,3)<>"250"&substr(newData,1,3)<>"251" then do
  call SendData "QUIT"||'0d0a'x
  call ErrorScreen 2,"NewEmail: Server rejected target email"
 end
end
if pos(" ",bccto)>0 then do
 tmp=bccto
 do while tmp<>""
  parse value tmp with sendto1 tmp
  call SendData "RCPT TO: <"||sendto1||">"||'0d0a'x
  call ReceiveData
  if substr(newData,1,3)<>"250"&substr(newData,1,3)<>"251" then do
   call SendData "QUIT"||'0d0a'x
   call ErrorScreen 2,"NewEmail: Server rejected target email"
  end
 end
end; else if bccto<>"" then do
 call SendData "RCPT TO: <"||bccto||">"||'0d0a'x
 call ReceiveData
 if substr(newData,1,3)<>"250"&substr(newData,1,3)<>"251" then do
  call SendData "QUIT"||'0d0a'x
  call ErrorScreen 2,"NewEmail: Server rejected target email"
 end
end
call SendData "DATA"||'0d0a'x
call ReceiveData
if substr(newData,1,3)<>"354" then do
 call SendData "QUIT"||'0d0a'x
 call ErrorScreen 2,"NewEmail: Server rejected email data"
end
if userfake="" then tmp=Globals.!user
else tmp=userfake
header="From: "||tmp||'0d0a'x
if pos(" ",sendto)>0 then do
 tmp=sendto
 parse value tmp with sendto1 tmp
 header=header||"To: <"||sendto1||">,"||'0d0a'x
 do while tmp<>""
  parse value tmp with sendto1 tmp
  header=header||"    <"||sendto1||">"
  if tmp<>"" then header=header||","||'0d0a'x
  else header=header||'0d0a'x
 end
end; else header=header||"To: <"||sendto||">"||'0d0a'x
if pos(" ",ccto)>0 then do
 tmp=ccto
 parse value tmp with sendto1 tmp
 header=header||"Cc: <"||sendto1||">,"||'0d0a'x
 do while tmp<>""
  parse value tmp with sendto1 tmp
  header=header||"    <"||sendto1||">"
  if tmp<>"" then header=header||","||'0d0a'x
  else header=header||'0d0a'x
 end
end; else if ccto<>"" then header=header||"Cc: <"||ccto||">"||'0d0a'x
header=header||"Date: "||substr(date("W"),1,3)||", "||date('N')||" "||time()||" "||SignScreen(2)||'0d0a'x
header=header||"Priority: "||epriority||'0d0a'x
header=header||"X-Mailer: "||Globals.!myinfo||'0d0a'x
if Globals.!XFace<>""&Globals.!XFace<>"GLOBALS.!XFACE" then header=header||"X-Face: "||Globals.!XFace||'0d0a'x
if inreplyto<>"" then header=header||"In-Reply-To: "||inreplyto||'0d0a'x
header=header||"MIME-Version: 1.0"||'0d0a'x
if filename="" then header=header||"Content-Type: text/plain; charset="||charset||'0d0a'x||"Content-Transfer-Encoding: 8bit"||'0d0a'x
else do
 boundary="_=_=_=WM2.BOUNDARY."||date("B")||random()||"=_=_=_"
 header=header||'Content-Type: multipart/mixed; boundary="'||boundary||'"'||'0d0a'x
end
header=header||"Subject: "||subject||'0d0a'x||'0d0a'x
if filename="" then body=header||body
else do
 body=header||"--"||boundary||'0d0a'x||"Content-Type: text/plain; charset="||charset||'0d0a'x||"Content-Transfer-Encoding: 8bit"||'0d0a'x||'0d0a'x||body||'0d0a'x||"--"||boundary||'0d0a'x||'Content-Type: application/octet-stream; name="'||filename||'"'||'0d0a'x||"Content-Transfer-Encoding: base64"||'0d0a'x||'Content-Disposition: attachment; filename="'||filename||'"'||'0d0a'x||'0d0a'x
end
call SendData body
if filename<>"" then do
 buf=RXB64encode(Globals.!querystring)
 poz=1
 do while poz<length(buf)
  if (poz+32768)<length(buf) then call SendData substr(buf,poz,32768)
  else call SendData substr(buf,poz,length(buf)-poz+1)
  poz=poz+32768
 end
 call SendData '0d0a'x||"--"||boundary||"--"
end
call SendData '0d0a'x||"."||'0d0a'x
call ReceiveData
if substr(newData,1,3)<>"250" then do
 call SendData "QUIT"||'0d0a'x
 call ErrorScreen 2,"NewEmail: Server rejected email data"
end
call SendData "QUIT"||'0d0a'x
rc=SockSoClose(socket)
if rc=-1 then call ErrorScreen 3,"NewEmail: Error on SockSoClose"
poz=pos("WEBMAIL2PAGE=",Globals.!Cookie)
if poz>0 then do
 poz1=pos(";",Globals.!Cookie,poz)
 if poz1>0 then
  Globals.!stat2=substr(Globals.!Cookie,poz+13,poz1-poz-13)
 else
  Globals.!stat2=substr(Globals.!Cookie,poz+13)
 Globals.!stat3=""
end
call CheckEmail
return

/*:VRX         NewEmailScreen
*/
NewEmailScreen: procedure expose Globals.
Globals.!EmailReplyTo=""
if Globals.!stat2<>"" then call ReceiveEmail 3
else do
 ListMail.i.!From=""
 ListMail.i.!MessageID=""
 ListMail.i.!Cc=""
 ListMail.i.!Subject=""
 ListMail.i.!b=""
end
rc=SignScreen(1)
if Globals.!UserFake="" then Globals.!UserFake=Globals.!user
if Globals.!Bccto="" then ListMail.i.!Bcc=""
else ListMail.i.!Bcc=Globals.!Bccto
if rc<>"" then ListMail.i.!b=ListMail.i.!b||'0d0a'x||'0d0a'x||rc
if Globals.!TagLine="YES" then do
tagline.0=192
tagline.1="<> God created men and rested... God created women and no-ones rested since!"
tagline.2="<> God is my co-pilot, but the Devil is my bombardier."
tagline.3="<> God may have made man first, but there is always a rough draft before a final copy."
tagline.4="<> God must love stupid people, he made so many."
tagline.5="<> Good girls get fat, bad girls get eaten."
tagline.6="<> Gravity doesn't exist. Earth sucks. "
tagline.7="<> Ground Beef: A Cow With No Legs!"
tagline.8="<> Growing old is mandatory; growing up is optional!! "
tagline.9="<> Guests who kill talk show hosts--On the last Geraldo."
tagline.10="<> Guns don't kill people, postal workers do."
tagline.11="<> H lp! S m b dy  st ll th  v wl s fr m my k yb  rd!"
tagline.12="<> Half of the people in the world are below average. "
tagline.13="<> Half the people you know are below average."
tagline.14="<> Hang up and drive!"
tagline.15="<> Happiness is a belt-fed weapon."
tagline.16="<> Hard work pays off in the future. Laziness pays off now."
tagline.17="<> Harder than your husband!!"
tagline.18="<> hAS ANYONE SEEN MY cAPSLOCK KEY? "
tagline.19="<> Having a Smoking Section in a restaurant is a little like having a Peeing Section in a pool."
tagline.20="<> He who hesitates is probably right."
tagline.21="<> He who laughs last has the best lawyer"
tagline.22="<> He who laughs last thinks slowest! "
tagline.23="<> Heaven won't have me and Hell's afraid I'll take over. "
tagline.24="<> Hell hath no fury like the lawyer of a woman scorned."
tagline.25="<> Help nature, don't breathe."
tagline.26="<> Help stamp out and eradicate superfluous redundancy."
tagline.27="<> Help Wanted: Telepath. You know where to apply."
tagline.28="<> Help! My Reality Check Bounced!"
tagline.29="<> Here I am! Now what are your other two wishes?"
tagline.30="<> Hi-ho, hi-ho, it's hand grenades I throw..."
tagline.31="<> Hold a hard drive to your ear -- listen to the C: "
tagline.32="<> Hold the Liberals liable"
tagline.33="<> Horn broken, watch for finger."
tagline.34="<> House guarded by SHOTGUN 3 nights a week. You guess which 3."
tagline.35="<> How can I miss you if you won't go away?"
tagline.36="<> How can my checking account be overdrawn? I still have checks!"
tagline.37="<> How come abbreviated is such a long word?"
tagline.38="<> How come Superman could stop bullets with his chest, but always ducked when someone threw a gun at him?"
tagline.39="<> How do I set a laser printer to stun?"
tagline.40="<> How do most men define marriage? A very expensive way to get your laundry done free."
tagline.41="<> How do you tell when you've run out of invisible ink?"
tagline.42="<> How many of you believe in telekinesis? Raise my hands...."
tagline.43="<> How many times do I have to flush before you go away?"
tagline.44="<> I almost had a psychic girlfriend but she left me before we met."
tagline.45="<> I am built for comfort, not for speed!"
tagline.46="<> I am logged in, therefore I am."
tagline.47="<> I am only horny on the days that end in y."
tagline.48="<> I believe no problem is so large or so difficult that it can't be fixed with the right amount of C4!"
tagline.49="<> I brake just for the hell of it!"
tagline.50="<> I can please only one person per day.  Today is not your day.  Tomorrow isn't looking good either."
tagline.51="<> I can see clearly now, the brain is gone..."
tagline.52="<> I can't remember if I'm the good twin or the evil one."
tagline.53="<> I couldn't repair your brakes, so I made your horn louder."
tagline.54="<> I did a drot of lugs in college, I hink I thave dain bramage. "
tagline.55="<> I did alot of drugs in the 50's now I do them at room temperature."
tagline.56="<> I didn't fight my way to the top of the food chain to be a vegetarian."
tagline.57="<> I don't care who you are, FATSO. Get the reindeer off my roof!"
tagline.58="<> I don't care, I don't have to."
tagline.59="<> I don't find it hard to meet expenses. They're everywhere!"
tagline.60="<> I don't have a license to kill.  I have a learner's permit."
tagline.61="<> I don't have a solution but I admire the problem."
tagline.62="<> I don't have an attitude problem.  You have a perception problem."
tagline.63="<> I don't have to be dead to donate my organ."
tagline.64="<> I don't suffer from insanity. I enjoy every minute of it. "
tagline.65="<> I don't suffer from stress.  I'm a carrier."
tagline.66="<> I drive way too fast to worry about cholesterol."
tagline.67="<> I failed my urine-test."
tagline.68="<> I feel like I'm diagonally parked in a parallel universe."
tagline.69="<> I get enough exercise just pushing my luck"
tagline.70="<> I got a gun for my wife, best trade I ever made."
tagline.71="<> I got some diving equipment for my wife... It was the best trade I ever made."
tagline.72="<> I had a life once... now I have a computer and a modem. "
tagline.73="<> I had a monumental idea this morning, but I didn't like it."
tagline.74="<> I have the heart of a child. I keep it in a jar. "
tagline.75="<> I intend to live forever - so far, so good."
tagline.76="<> I just want revenge. Is that so wrong?"
tagline.77="<> I killed a 6-pack just to watch it die."
tagline.78="<> I know what you're thinking, and you should be ashamed of yourself."
tagline.79="<> I let my mind wander and it didn't come back."
tagline.80="<> I like cats, too. Let's exchange recipes."
tagline.81="<> I like you, but I wouldn't want to see you working with subatomic particles"
tagline.82="<> I loathe people who keep dogs.  They are cowards who haven't got the guts to bite people themselves."
tagline.83="<> I love animals... they're delicious."
tagline.84="<> I love cats ... they taste just like chicken"
tagline.85="<> I love cats... dead ones"
tagline.86="<> I love deadlines.  I especially like the whooshing sound they make as they go flying by."
tagline.87="<> I love defenseless animals, especially in a good gravy."
tagline.88="<> I love Jesus.  It's his fan club that makes me nervous."
tagline.89="<> I majored in liberal arts. Will that be for here or to go?"
tagline.90="<> I may be fat, but your ugly - I can lose weight!   "
tagline.91="<> I may be going slow, but I am ahead of you!"
tagline.92="<> I need someone really bad... Are you really bad?"
tagline.93="<> I plead contemporary insanity."
tagline.94="<> I poured Spot remover on my dog. Now he's gone."
tagline.95="<> I pretend to work. They pretend to pay me."
tagline.96="<> I refuse to star in your psychodrama."
tagline.97="<> I said 'no' to drugs, but they just wouldn't listen."
tagline.98="<> I smile because I do not know what is going on."
tagline.99="<> I souport publik edekashun."
tagline.100="<> I started out with nothing &amp; still have most of it left."
tagline.101="<> I still miss my Ex, but my aim is getting better!"
tagline.102="<> I support the three basic food groups.. KEG - BOTTLE - CAN"
tagline.103="<> I think, therefore I am DANGEROUS."
tagline.104="<> I think, therefore I am. I think. "
tagline.105="<> I thought I wanted a career, turns out I just wanted paychecks."
tagline.106="<> I took an IQ test and the results were negative."
tagline.107="<> I tried sniffing Coke once, but the ice cubes got stuck in my nose."
tagline.108="<> I tried switching to gum but I couldn't keep it lit. "
tagline.109="<> I tried to think but nothing happened! - CURLY"
tagline.110="<> I used to be indecisive; now I'm not sure."
tagline.111="<> I used to have a handle on life, but it broke."
tagline.112="<> I used to have an open mind but my brains kept falling out."
tagline.113="<> I used up all my sick days, so I'm calling in dead."
tagline.114="<> I want to die peacefully, in my sleep, like my grandfather, not screaming and terrified, like his passengers. "
tagline.115="<> I wasn't born a bitch.  Men like you made me this way."
tagline.116="<> I went fishing with Salvador Dali; he was using a dotted line."
tagline.117="<> I wonder how much deeper would the ocean be without sponges."
tagline.118="<> I won't rise to the occasion, but I'll slide over to it."
tagline.119="<> I work 40 hours a week to be this poor."
tagline.120="<> I wouldn't be caught dead with a necrophiliac."
tagline.121="<> Winning isn't everything, it's also important to humiliate your opponent"
tagline.122="<> Witches are crafty people"
tagline.123="<> Women who seek to be equal to men lack ambition. "
tagline.124="<> Work is for people who don't know how to fish."
tagline.125="<> Workaholics Anonymous---- THANK GOD IT'S MONDAY"
tagline.126="<> You can listen to thunder and tell how close you came to getting hit. If you don't hear it, you got hit, so never mind.."
tagline.127="<> You can tune a guitar, but you can't tuna fish."
tagline.128="<> You can't be first, but you could be next"
tagline.129="<> You can't have everything...where would you put it? "
tagline.130="<> You have the right to remain silent. Anything you say will be misquoted and used against you."
tagline.131="<> You never really learn to swear until you learn to drive."
tagline.132="<> You say I'm a bitch like it's a bad thing."
tagline.133="<> You show the sensitivity of a Medieval Dentist."
tagline.134="<> You will get what's coming to you....Unless they mailed it."
tagline.135="<> You! Off my planet!"
tagline.136="<> Your kid may be an honor student, but you're still an idiot."
tagline.137="<> Your only young once; you can be immature forever."
tagline.138="<> Your tits look like they're made of cardboard. Are they real?"
tagline.139="<> Your ugly and your mama dresses you funny"
tagline.140="<> You're just jealous because the voices only talk to me."
tagline.141="<> You're only young once; you can be immature forever "
tagline.142="<> You're slower than a herd of turtles stampeding through peanut butter."
tagline.143="<> Make it idiot-proof and someone will make a better idiot."
tagline.144="<> MAKE LOVE NOT WAR - see driver for details"
tagline.145="<> Make the World a better place, kill yourself."
tagline.146="<> Make yourself at home! Clean my kitchen."
tagline.147="<> Many people quit looking for work when they find a job."
tagline.148="<> Marriage is not a word: it is a sentence."
tagline.149="<> Marriage is not a word: its a SENTENCE."
tagline.150="<> Master Baiters catch more fish"
tagline.151="<> Me You Dinner Motel"
tagline.152="<> Mean people rule!"
tagline.153="<> Mean people suck... Nice people swallow..."
tagline.154="<> Meandering to a different drummer."
tagline.155="<> Meat is yummy!"
tagline.156="<> Men who have pierced ears are better prepared for marriage. They've experienced pain and bought jewelry."
tagline.157="<> Mental backup in progress - Do Not Disturb."
tagline.158="<> Mental Floss prevents Moral Decay."
tagline.159="<> Microbiology Lab: Staph Only!"
tagline.160="<> Missing your cat? Try looking under my tires."
tagline.161="<> Monday is an awful way to spend 1/7th of your life."
tagline.162="<> Money can't buy love. But it CAN rent a very close imitation."
tagline.163="<> Montana -- At least the cows are sane!"
tagline.164="<> Mushrooms always grow in damp places, which is why they look like umbrellas."
tagline.165="<> My disgust with the current administration cannot be summarized here."
tagline.166="<> My Karma ran over my Dogma."
tagline.167="<> My kid beat up your honor student."
tagline.168="<> My kid had sex with your honor student."
tagline.169="<> My message above. Your response here ____________. "
tagline.170="<> My other car is a piece of crap too!"
tagline.171="<> My other car is also a Mercedes."
tagline.172="<> My reality check just bounced."
tagline.173="<> My wife keeps complaining I never listen to her ... or something like that."
tagline.174="<> My wife ran away with my best friend. I sure miss him. "
tagline.175="<> Never assume. It makes an 'ass' out of 'u' and 'me'. "
tagline.176="<> Never do card tricks for the group you play poker with."
tagline.177="<> Never hit a man with glasses. Use your fist!"
tagline.178="<> Never play leapfrog with a Unicorn"
tagline.179="<> Never run after buses or women: you'll always get left behind."
tagline.180="<> Never trust anything that bleeds for five days and doesn't die. "
tagline.181="<> Never try to teach a pig to sing, You waste your time and only annoys the pig."
tagline.182="<> Never underestimate the power of stupid people in large groups"
tagline.183="<> Never wrestle with a pig. You get dirty and the pig enjoys it."
tagline.184="<> Next time wave all of your fingers."
tagline.185="<> Nice perfume. Must you marinate in it?"
tagline.186="<> No one is listening until you make a mistake."
tagline.187="<> No radio - Already stolen."
tagline.188="<> No sense being pessimistic. It wouldn't work anyway."
tagline.189="<> Not all men are annoying. Some are dead."
tagline.190="<> Nothing is fool-proof to a sufficiently talented fool."
tagline.191="<> Nurses call all the SHOTS"
tagline.192="<> OK, so what's the speed of dark?"
 pick=random(1, tagline.0)
 ListMail.i.!b=ListMail.i.!b||'0d0a'x||tagline.pick
end
if pos("US-ASCII",translate(Globals.!CharSet))>0 then Globals.!CharSet="iso-8859-1"
call ParseHTML Globals.!WMPath||"header.wm",1
if Globals.!stat2<>""&Globals.!EmailReplyTo<>"" then
 call ParseHTML Globals.!WMPath||"reply.wm"
else
 call ParseHTML Globals.!WMPath||"composeemail.wm"
call ParseHTML Globals.!WMPath||"footer.wm"
exit

/*:VRX         NewUser
*/
NewUser: procedure expose Globals.
Globals.!clientIP=value("REMOTE_ADDR",,'ENVIRONMENT')
if Globals.!clientIP="" then call ErrorScreen 1,"CheckLogon: Can't detect your client"
username=substr(Globals.!stat2,3)
parse value Globals.!stat3 with "e=" emailid "&d=" domain "&p=" password
if username=""|emailid=""|domain=""|password="" then call NewUserScreen "One or more fields are incomplete."
if length(password)<4 then call NewUserScreen "Your password must be atleast 4 characters long."
if length(emailid)<4|length(emailid)>8 then call NewUserScreen "Your email ID must be between 4 and 8 characters long."
if DATATYPE(emailid,'L')=0|pos(":",username)>0|pos(":",domain)>0|pos(":",password)>0|pos(" ",password)>0 then call NewUserScreen "Illegal character detected."
call ConnectManager
call SendData "4"||":"||username||":"||emailid||":"||domain||":"||password||":"||Globals.!clientIP||":"||'0d0a'x
call ReceiveData
rc=SockSoClose(socket)
if rc=-1 then call NewUserScreen "New users are not allowed."
if pos("[WebManager2]",newData)>0 then do
 rc=substr(newData,15,1)
 if rc=2 then call NewUserScreen "Email ID already exists."
 if rc=1 then do
  call ParseHTML Globals.!WMPath||"newuser-thankyou.wm",1
  exit
 end
 call NewUserScreen "User registration rejected."
end
call SysSleep 6
call NewUserScreen "New users are not allowed."
exit

/*:VRX         NewUserScreen
*/
NewUserScreen: procedure expose Globals.
Globals.!ServerErr=ARG(1)
call ParseHTML Globals.!WMPath||"newuser.wm",1
exit

/*:VRX         ParseHTML
*/
ParseHTML: procedure expose Globals. i ListMail.
findstring.1="*!WMVERSION!*:"||Globals.!myinfo
findstring.2="*!WMUSER!*:"||Globals.!user
findstring.3="*!WMPASS!*:"||Globals.!pazz
findstring.4="*!WMFILENAME!*:"||Globals.!myself
findstring.5="*!WMEMAILNUM!*:"||i
findstring.6="*!WMEMAILFROM!*:"||ListMail.i.!From
findstring.7="*!WMEMAILSUBJECT!*:"||ListMail.i.!Subject
findstring.8="*!WMEMAILDATE!*:"||ListMail.i.!Date
findstring.9="*!WMEMAILBODY!*:"||ListMail.i.!b
findstring.10="*!WMEMAILTABLE!*:"||Globals.!ListTable
findstring.11="*!SERVERERROR!*:"||Globals.!ServerErr
findstring.12="*!WMATTACHMENT!*:"||Globals.!ContentType
findstring.13="*!WMEMAILPRIORITY!*:"||Globals.!Priority
findstring.14="*!WMAUTHID!*:"||Globals.!AuthID
findstring.15="*!WMATTACHMENTSTABLE!*:"||Globals.!AttachmentsTable
findstring.16="*!WMATTACHFILE!*:"||Globals.!AttachFile
findstring.17="*!WMJUMPTABLE!*:"||Globals.!JumpTable
findstring.18="*!WMJUMPPAGE!*:"||Globals.!JumpPage
findstring.19="*!WMPREVEMAILNUM!*:"||Globals.!PrevEmailNum
findstring.20="*!WMNEXTEMAILNUM!*:"||Globals.!NextEmailNum
findstring.21="*!WMEMAILCC!*:"||ListMail.i.!Cc
findstring.22="*!WMEMAILREPLYTO!*:"||Globals.!EmailReplyTo
poz=pos("WEBMAIL2PAGE=",Globals.!Cookie)
if poz>0 then do
 poz1=pos(";",Globals.!Cookie,poz)
 if poz1>0 then
  findstring.23="*!WMPAGE!*:"||substr(Globals.!Cookie,poz+13,poz1-poz-13)
 else
  findstring.23="*!WMPAGE!*:"||substr(Globals.!Cookie,poz+13)
end; else findstring.23="*!WMPAGE!*:1"
findstring.24="*!WMTOTALSIZE!*:"||Globals.!totalsize
findstring.25="*!WMADDRBTABLE!*:"||Globals.!AddrTable
findstring.26="*!WMADDRBALIAS!*:"||Globals.!AddrAlias
findstring.27="*!WMADDRBNAME!*:"||Globals.!AddrName
findstring.28="*!WMADDREMAIL!*:"||Globals.!AddrEmail
findstring.29="*!WMFULLFROM!*:"||ListMail.i.!FullFrom
findstring.30="*!WMCHARSET!*:"||Globals.!CharSet
findstring.31="*!WMSIGNATURE!*:"||Globals.!Sign
findstring.32="*!WMSHOWHEADERS!*:"||Globals.!ShowHeaders
findstring.33="*!WMSHOWHTML!*:"||Globals.!ShowHtml
findstring.34="*!WMEMAILBCC!*:"||ListMail.i.!Bcc
findstring.35="*!WMEMAILFAKE!*:"||Globals.!UserFake
findstring.36="*!WMFULLNAME!*:"||Globals.!realname
findstring.37="*!WMTIMEZONESELECT!*:"||Globals.!TimeZones
findstring.38="*!WMINREPLYTO!*:"||ListMail.i.!MessageID
findstring.39="*!WMEMAILSELECT!*:"||Globals.!EmailSelect
findstring.40="*!WMXFACE!*:"||ListMail.i.!XFace
findstring.41="*!WMPPATH!*:"||Globals.!PrefixPath
findstring.0=41
if ARG(2)=1 then do
 say 'Content-type: text/html; charset='||Globals.!CharSet
 say "Cache-Control: no-cache"
 say "Pragma: no-cache"
 say "Expires: Thu, 01 Dec 1994 16:00:00 GMT"
 if Globals.!SetCookie="SET" then say "Set-Cookie: WEBMAIL2="||Globals.!AuthID
 if symbol("Globals.!SetCookiePage")="VAR" then do
  say "Set-Cookie: WEBMAIL2PAGE="||Globals.!SetCookiePage
  findstring.23="*!WMPAGE!*:"||Globals.!SetCookiePage
 end
 say ""
end
if arg(1)="none" then return
istr=stream(arg(1),'c','open read')
if istr<>"READY:" then do
 say "Server Error: Loading .WM files"
 exit
end
istr=stream(arg(1),'c','query size')
tmp=charin(arg(1),1,istr)
do ii=1 to findstring.0
 parse value findstring.ii with tmp1 ":" tmp2
 poz=1
 do forever
  tmp3=pos(tmp1,tmp,poz)
  if tmp3=0 then leave
  tmp=delstr(tmp,tmp3,length(tmp1))
  tmp=insert(tmp2,tmp,tmp3-1)
  poz=tmp3+length(tmp2)
 end
end
if ARG(3)<>1 then say tmp
return tmp

/*:VRX         ReceiveData
*/
ReceiveData: procedure expose socket newData
length=ARG(1)
if length="" then length=1024
r.0=1
r.1=socket
newData=""
do while pos('0d0a'x,newData)<1
 bytes=SockSelect("r.","","",10)
 if bytes>0 then bytes=SockRecv(socket,"Buffer",length)
 else bytes=-2
 if bytes<=0 then return -1 /* Remote socket has vanished */
 newData=newData||Buffer /* Append input to bufferful */
end
return 0

/*:VRX         ReceiveDataExtended
*/
ReceiveDataExtended: procedure expose socket newData
length=ARG(1)
if length="" then length=1024
r.0=1
r.1=socket
newData=""
do while pos('0d0a'x||"."||'0d0a'x,newData)<1
 bytes=SockSelect("r.","","",10)
 if bytes>0 then bytes=SockRecv(socket,"Buffer",length)
 else bytes=-2
 if bytes<=0 then return -1 /* Remote socket has vanished */
 newData=newData||Buffer /* Append input to bufferful */
end
return 0

/*:VRX         ReceiveDataSize
*/
ReceiveDataSize: procedure expose socket newData
size=ARG(1)
length=ARG(2)
if length="" then length=1024
r.0=1
r.1=socket
newData=""
do while length(newData)<size
 bytes=SockSelect("r.","","",10)
 if bytes>0 then bytes=SockRecv(socket,"Buffer",length)
 else bytes=-2
 if bytes<=0 then return -1 /* Remote socket has vanished */
 newData=newData||Buffer /* Append input to bufferful */
end
return 0

/*:VRX         ReceiveEmail
*/
ReceiveEmail: procedure expose Globals. ListMail. i
if Globals.!stat2=0 then do
 say "Status: 301 Moved Permanently"
 poz=pos("WEBMAIL2PAGE=",Globals.!Cookie)
 if poz>0 then do
  poz1=pos(";",Globals.!Cookie,poz)
  if poz1>0 then
   Globals.!stat2=substr(Globals.!Cookie,poz+13,poz1-poz-13)
  else
   Globals.!stat2=substr(Globals.!Cookie,poz+13)
  say 'Location: '||Globals.!myself||"?refresh&"||Globals.!stat2
 end; else say 'Location: '||Globals.!myself||"?refresh"
 say "Cache-Control: no-cache"
 say "Pragma: no-cache"
 say "Expires: Thu, 01 Dec 1994 16:00:00 GMT"
 say ""
 exit
end
i=Globals.!stat2
call ConnectPOP
call SendData "STAT"||'0d0a'x
call ReceiveData
if substr(newData,1,3)<>"+OK" then do
 call SendData "QUIT"||'0d0a'x
 call ErrorScreen 2,"ReceiveEmail: Email server couldn't get status"
end
parse value newData with . Globals.!totalmail .
if datatype(Globals.!totalmail,"N")<>1 then do
 call SendData "QUIT"||'0d0a'x
 call ErrorScreen 2,"ReceiveEmail: Server returned wrong value"
end
call SendData "LIST "||Globals.!stat2||'0d0a'x
call ReceiveData
if substr(newData,1,3)<>"+OK" then do
 call SendData "QUIT"||'0d0a'x
 call ErrorScreen 2,"ReceiveEmail: Server couldn't list email"
end
parse value newData with . . s2 '0d0a'x
if s2<Globals.!MaxAttachSize then call SendData "RETR "||Globals.!stat2||'0d0a'x
else do
 incomplete=1
 call SendData "TOP "||Globals.!stat2||" 200"||'0d0a'x
end
call ReceiveData 5
if substr(newData,1,3)<>"+OK" then do
 call SendData "QUIT"||'0d0a'x
 call ErrorScreen 2,"ReceiveEmail: Server couldn't retrieve email body"
end
call ReceiveDataSize s2,32768
ListMail.i.!b=newData
if length(ListMail.i.!b)=8 then ListMail.i.!b="X-Junkmail: Yes"||'0d0a'x||'0d0a'x||"JunkMail: This email has been detected as junk mail."||'0d0a'x||"If this message has incorrectly been identified as junk, please forward to notjunk@junkspy.com"||ListMail.i.!b
headpoz=pos('0d0a'x||'0d0a'x,ListMail.i.!b)
if headpoz>0 then do
 ListMail.i.!h=substr(ListMail.i.!b,1,headpoz+3)
 if pos('0d0d0a'x,ListMail.i.!h)>0 then ListMail.i.!h=ReplaceStr(ListMail.i.!h,'0d0d0a'x,'0d0a'x)
end; else do
 call SendData "QUIT"||'0d0a'x
 call ErrorScreen 2,"ReceiveEmail: Server couldn't retrieve email headers"
end
call SendData "QUIT"||'0d0a'x
rc=SockSoClose(socket)
if rc=-1 then call ErrorScreen 3,"ReceiveEmail: Error on SockSoClose"
if Globals.!stat3<>"o" then
 ListMail.i.!b=substr(ListMail.i.!b,pos('0d0a'x||'0d0a'x,ListMail.i.!b)+4)
ListMail.i.!b=substr(ListMail.i.!b,1,lastpos('0d0a'x||"."||'0d0a'x,ListMail.i.!b)+1)
if arg(1)=3 then do
 call ScanHeaders 3
 if qpyes=1 then ListMail.i.!b=RXdeQuoted(ListMail.i.!b)
 if htmlyes=1 then do
  do while pos("<SCRIPT>",translate(ListMail.i.!b))>0
   tmp1=pos("<SCRIPT>",translate(ListMail.i.!b))
   tmp2=pos("</SCRIPT>",translate(ListMail.i.!b),tmp1)+9
   if tmp2<tmp1 then leave
   ListMail.i.!b=delstr(ListMail.i.!b,tmp1,tmp2-tmp1)
  end
  ListMail.i.!b=Html2Txt(ListMail.i.!b)
 end
 tmp=1
 ListMail.i.!b=insert( ">",ListMail.i.!b)
 do while pos('0d0a'x,ListMail.i.!b,tmp)>0
  tmp=pos('0d0a'x,ListMail.i.!b,tmp)+1
  ListMail.i.!b=insert( ">",ListMail.i.!b,tmp)
 end
 if Globals.!EmailReplyTo<>"" then
  ListMail.i.!b=insert("On "||ListMail.i.!Date||", "||Globals.!EmailReplyTo||" wrote:"||'0d0a'x||'0d0a'x,ListMail.i.!b)
 else
  ListMail.i.!b=insert("On "||ListMail.i.!Date||", "||ListMail.i.!From||" wrote:"||'0d0a'x||'0d0a'x,ListMail.i.!b)
 return
end; else if arg(1)=4 then return
else if Globals.!stat3="o" then do
 tempbody=ListMail.i.!b
 call ScanHeaders 2
 ListMail.i.!b=tempbody
 call ParseHTML "none",1
 Globals.!AttachmentsTable=""
 if ListMail.i.!ContentType="YES" then do
  Globals.!ContentType=ParseHTML(Globals.!WMPath||"attachment-yes.wm",0,1)||'0d0a'x
  do iz=1 to Globals.!AttachFiles.0
   Globals.!AttachFile=Globals.!AttachFiles.iz
   Globals.!AttachmentsTable=Globals.!AttachmentsTable||ParseHTML(Globals.!WMPath||"attachment-table.wm",0,1)||'0d0a'x
  end
 end
 ListMail.i.!b=ReplaceStr(ListMail.i.!b,"&","&amp;")
 ListMail.i.!b=ReplaceStr(ListMail.i.!b,"<","&lt;")
 ListMail.i.!b=ReplaceStr(ListMail.i.!b,">","&gt;")
 ListMail.i.!b=ReplaceStr(ListMail.i.!b,">","&quot;")
 call ParseHTML Globals.!WMPath||"printemail.wm"
end; else do
 call ScanHeaders 2
 if Globals.!stat3="x" then do
  say 'Content-Type: image/x-xbitmap'
  say ""
  if RxFuncQuery("UncFace")=1 then call RxFuncAdd "UncFace", "rxface", "UncFace"
  call charout ,UncFace(1,ListMail.i.!XFace)
  exit
 end
 call SignScreen 1
 if qpyes=1 then ListMail.i.!b=RXdeQuoted(ListMail.i.!b)
 if htmlyes=1&Globals.!ShowHtml="" then ListMail.i.!b=Html2Txt(ListMail.i.!b)
 if ListMail.i.!XFace<>"" then ListMail.i.!XFace='<img src="'||Globals.!myself||'?read&'||i||'&x" alt="X-Face" title="X-Face">'
 if ListMail.i.!Priority="High" then Globals.!Priority=ParseHTML(Globals.!WMPath||"priority-high.wm",0,1)||'0d0a'x
 else if ListMail.i.!Priority="Low" then Globals.!Priority=ParseHTML(Globals.!WMPath||"priority-low.wm",0,1)||'0d0a'x
 else Globals.!Priority=ParseHTML(Globals.!WMPath||"priority-normal.wm",0,1)||'0d0a'x
 if Globals.!stat3="p" then
  call ParseHTML "none",1
 else
  call ParseHTML Globals.!WMPath||"header.wm",1
 Globals.!AttachmentsTable=""
 if ListMail.i.!ContentType="YES" then do
  Globals.!ContentType=ParseHTML(Globals.!WMPath||"attachment-yes.wm",0,1)||'0d0a'x
  do iz=1 to Globals.!AttachFiles.0
   Globals.!AttachFile=Globals.!AttachFiles.iz
   Globals.!AttachmentsTable=Globals.!AttachmentsTable||ParseHTML(Globals.!WMPath||"attachment-table.wm",0,1)||'0d0a'x
  end
 end; else do
  if Globals.!stat3<>"p" then do
   Globals.!ContentType=ParseHTML(Globals.!WMPath||"attachment-no.wm",0,1)||'0d0a'x
   Globals.!AttachmentsTable=Globals.!ContentType
  end
 end
 if Globals.!stat2>1 then Globals.!PrevEmailNum=Globals.!stat2-1
 else Globals.!PrevEmailNum=0
 if Globals.!stat2>=Globals.!totalmail then Globals.!NextEmailNum=0
 else Globals.!NextEmailNum=Globals.!stat2+1
 if incomplete=1 then ListMail.i.!b=ListMail.i.!b||'0d0a'x||"*************************************"||'0d0a'x||"The rest of the email body has been"||'0d0a'x||"removed because it was too big to fit"||'0d0a'x||"*************************************"||'0d0a'x
 if htmlyes=1 then do
  do while pos("<SCRIPT>",translate(ListMail.i.!b))>0
   tmp1=pos("<SCRIPT>",translate(ListMail.i.!b))
   tmp2=pos("</SCRIPT>",translate(ListMail.i.!b),tmp1)+9
   if tmp2<tmp1 then leave
   ListMail.i.!b=delstr(ListMail.i.!b,tmp1,tmp2-tmp1)
  end
 end; else do
  ListMail.i.!b=ReplaceStr(ListMail.i.!b,"&","&amp;")
  ListMail.i.!b=ReplaceStr(ListMail.i.!b,"<","&lt;")
  ListMail.i.!b=ReplaceStr(ListMail.i.!b,">","&gt;")
  ListMail.i.!b=ReplaceStr(ListMail.i.!b,">","&quot;")
 end
 if Globals.!ShowHeaders<>"" then do
  ListMail.i.!h=ReplaceStr(ListMail.i.!h,"&","&amp;")
  ListMail.i.!h=ReplaceStr(ListMail.i.!h,"<","&lt;")
  ListMail.i.!h=ReplaceStr(ListMail.i.!h,">","&gt;")
  ListMail.i.!h=ReplaceStr(ListMail.i.!h,">","&quot;")
  ListMail.i.!b=ListMail.i.!h||ListMail.i.!b
 end
 if Globals.!stat3="p" then do
  call ParseHTML Globals.!WMPath||"printemail.wm"
 end; else do
  call ParseHTML Globals.!WMPath||"reademail.wm"
  call ParseHTML Globals.!WMPath||"footer.wm"
 end
end
exit

/*:VRX         ReplaceStr
*/
ReplaceStr: procedure
tmp1=ARG(1)
tmp2=ARG(2)
tmp3=ARG(3)
poz=1
do forever
 tmp=pos(tmp2,tmp1,poz)
 if tmp=0 then leave
 tmp1=delstr(tmp1,tmp,length(tmp2))
 tmp1=insert(tmp3,tmp1,tmp-1)
 poz=tmp+length(tmp3)
end
return tmp1

/*:VRX         ResolveEmails
*/
ResolveEmails: procedure expose Globals.
sendto=ARG(1)
book=AddrScreen(1)
if pos(" ",sendto)>0 then do
  tmp1=sendto
  sendto=""
  do while length(tmp1)>0
   tmpemailfound=0
   tmp2=book
   parse value tmp1 with tmpemail tmp1
   do while pos(":",tmp2)>0
    parse value tmp2 with AddrAlias ":" AddrName ":" AddrEmail '0d0a'x tmp2
    if translate(tmpemail)=translate(AddrAlias)|translate(tmpemail)=translate(AddrName) then do
     tmpemailfound=1
     leave
    end
   end
   if tmpemailfound=1 then sendto=sendto||" "||AddrEmail
   else sendto=sendto||" "||tmpemail
  end
  sendto=space(sendto)
end; else do
 do while pos(":",book)>0
  parse value book with AddrAlias ":" AddrName ":" AddrEmail '0d0a'x book
  if translate(sendto)=translate(AddrAlias)|translate(sendto)=translate(AddrName) then sendto=AddrEmail
 end
end
return sendto

/*:VRX         ScanHeaders
*/
ScanHeaders: procedure expose Globals. i ListMail. qpyes htmlyes
ListMail.i.!h=translate(ListMail.i.!h," ",'09'x)
poz=pos('0d0a'x,ListMail.i.!h)+2
do while poz<length(ListMail.i.!h)
 rc=substr(ListMail.i.!h,poz,1)
 if rc=" " then ListMail.i.!h=substr(ListMail.i.!h,1,poz-3)||" "||space(substr(ListMail.i.!h,poz+1))
 poz=pos('0d0a'x,ListMail.i.!h,poz)+2
end
h1=translate(ListMail.i.!h)
if pos('0d0a'x||"CONTENT-TYPE:",h1)>0 then do
 tmp1=pos('0d0a'x||"CONTENT-TYPE:",h1)+15
 tmp2=pos('0d0a'x,h1,tmp1)
 tmp3=space(substr(ListMail.i.!h,tmp1,tmp2-tmp1))
 if pos("MULTIPART/MIXED;",translate(tmp3))>0 then ListMail.i.!ContentType="YES"
 if pos("CHARSET=",translate(tmp3))>0 then do
  tmp1=pos("CHARSET=",translate(tmp3))+8
  ListMail.i.!CharSet=substr(tmp3,tmp1)
  if pos('"',ListMail.i.!CharSet)>0 then parse value ListMail.i.!CharSet with '"' ListMail.i.!CharSet '"'
 end
end
if pos('0d0a'x||"FROM:",h1)>0 then do
 tmp1=pos('0d0a'x||"FROM:",h1)+7
 tmp2=pos('0d0a'x,h1,tmp1)
 tmp3=space(substr(ListMail.i.!h,tmp1,tmp2-tmp1))
 if pos(" ",tmp3)<1 then do
  pmt=RXB64encode(tmp3)
  ListMail.i.!FullFrom=substr(pmt,1,pos('0d0a'x,pmt)-1)
  if pos("<",tmp3)>0&pos(">",tmp3)>0 then parse value tmp3 with . "<" tmp3 ">" .
 end; else if arg(1)=3 then do
  if pos("<",tmp3)>0&pos(">",tmp3)>0 then parse value tmp3 with . "<" tmp3 ">" .
  else if pos('(',tmp3)>0&pos(')',tmp3)>0 then do 
   parse value tmp3 with tmp1 '(' . ')' tmp2
   tmp3=tmp1||tmp2
  end; else tmp3=substr(tmp3,lastpos(" ",tmp3)+1)
 end; else do
  pmt=RXB64encode(tmp3)
  ListMail.i.!FullFrom=substr(pmt,1,pos('0d0a'x,pmt)-1)
  if pos('"',tmp3)>0 then parse value tmp3 with . '"' tmp3 '"' .
  else if pos('(',tmp3)>0&pos(')',tmp3)>0 then parse value tmp3 with . '(' tmp3 ')' .
  else parse value tmp3 with tmp3 " " .
  if pos("=?",tmp3)=1 then do
   parse value tmp3 with . "?" enc1 "?" . "?" tmp3 "?" .
   tmp3=RXdeQuoted(tmp3)
   if arg(1)=1 then do
    if translate(Globals.!CharSet)="KOI8-R"&pos("1251",enc1)>0 then tmp3=RXreCode(3,4,tmp3)
    if pos("1251",Globals.!CharSet)>0&translate(enc1)="KOI8-R" then tmp3=RXreCode(4,3,tmp3)
   end; else do
    if translate(ListMail.i.!CharSet)="KOI8-R"&pos("1251",enc1)>0 then tmp3=RXreCode(3,4,tmp3)
    if pos("1251",ListMail.i.!CharSet)>0&translate(enc1)="KOI8-R" then tmp3=RXreCode(4,3,tmp3)
   end
  end
 end
 ListMail.i.!From=space(tmp3)
end; else ListMail.i.!From=""
if pos('0d0a'x||"SUBJECT:",h1)>0 then do
 tmp1=pos('0d0a'x||"SUBJECT:",h1)+10
 tmp2=pos('0d0a'x,h1,tmp1)
 tmp3=space(substr(ListMail.i.!h,tmp1,tmp2-tmp1))
 if pos("=?",tmp3)>0 & pos("?=",tmp3)>0 then do
  do until pos("=?",tmp3)<1 & pos("?=",tmp3)<1
   parse value tmp3 with tmp1 "=?" enc1 "?" enc2 "?" tmp3 "?=" tmp4
   if translate(enc2)="Q" then do
    tmp3=RXdeQuoted(tmp3)
    tmp3=ReplaceStr(tmp3,"_"," ")
    tmp3=tmp1||tmp3||tmp4
   end; else if translate(enc2)="B" then do
    tmp3=RXB64decode(tmp3)
    tmp3=ReplaceStr(tmp3,"_"," ")
    tmp3=tmp1||tmp3||tmp4
   end; else do
    tmp3=tmp1||tmp3||tmp4
    leave
   end
  end
  if arg(1)=1 then do
   if translate(Globals.!CharSet)="KOI8-R"&pos("1251",enc1)>0 then tmp3=RXreCode(3,4,tmp3)
   if pos("1251",Globals.!CharSet)>0&translate(enc1)="KOI8-R" then tmp3=RXreCode(4,3,tmp3)
  end; else do
   if translate(ListMail.i.!CharSet)="KOI8-R"&pos("1251",enc1)>0 then tmp3=RXreCode(3,4,tmp3)
   if pos("1251",ListMail.i.!CharSet)>0&translate(enc1)="KOI8-R" then tmp3=RXreCode(4,3,tmp3)
  end
 end
 if arg(1)=3&pos("RE:",translate(tmp3))<1 then do
  ListMail.i.!Subject="Re: "||tmp3
  ListMail.i.!Subject=ReplaceStr(ListMail.i.!Subject,'"',"&quot;")
 end; else do
  if pos("&",tmp3)>0 then tmp3=ReplaceStr(tmp3,"&","&amp;")
  if pos("<",tmp3)>0 then tmp3=ReplaceStr(tmp3,"<","&lt;")
  if pos(">",tmp3)>0 then tmp3=ReplaceStr(tmp3,">","&gt;")
  if pos('"',tmp3)>0 then tmp3=ReplaceStr(tmp3,'"',"&quot;")
  ListMail.i.!Subject=tmp3
 end
end; else ListMail.i.!Subject=""
if pos('0d0a'x||"DATE:",h1)>0 then do
 tmp1=pos('0d0a'x||"DATE:",h1)+7
 tmp2=pos('0d0a'x,h1,tmp1)
 tmp3=space(substr(ListMail.i.!h,tmp1,tmp2-tmp1))
 if length(tmp3)>38 then
  ListMail.i.!Date=space(substr(tmp3,1,26))
 else
  ListMail.i.!Date=tmp3
end; else ListMail.i.!Date=""
if pos('0d0a'x||"PRIORITY:",h1)>0 then do
 tmp1=pos('0d0a'x||"PRIORITY:",h1)+11
 tmp2=pos('0d0a'x,h1,tmp1)
 tmp3=space(substr(h1,tmp1,tmp2-tmp1))
 if tmp3="HIGH" then ListMail.i.!Priority="High"
 else if tmp3="LOW" then ListMail.i.!Priority="Low"
 else ListMail.i.!Priority="Normal"
end; else ListMail.i.!Priority="Normal"
if pos('0d0a'x||"X-FACE:",h1)>0 then do
 tmp1=pos('0d0a'x||"X-FACE:",h1)+9
 tmp2=pos('0d0a'x,h1,tmp1)
 ListMail.i.!XFace=space(substr(ListMail.i.!h,tmp1,tmp2-tmp1))
end; else ListMail.i.!XFace=""
if arg(1)=2|arg(1)=3 then do
 if pos('0d0a'x||"CONTENT-TRANSFER-ENCODING:",h1)>0 then do
  tmp1=pos('0d0a'x||"CONTENT-TRANSFER-ENCODING:",h1)+28
  tmp2=pos('0d0a'x,h1,tmp1)
  tmp3=space(substr(ListMail.i.!h,tmp1,tmp2-tmp1))
  if pos("QUOTED-PRINTABLE",translate(tmp3))>0 then qpyes=1
 end
 if pos('0d0a'x||"CONTENT-TYPE:",h1)>0 then do
  tmp1=pos('0d0a'x||"CONTENT-TYPE:",h1)+15
  tmp2=pos('0d0a'x,h1,tmp1)
  tmp3=space(substr(ListMail.i.!h,tmp1,tmp2-tmp1))
  if pos("TEXT/HTML",translate(tmp3))>0 then htmlyes=1
  if pos("CHARSET=",translate(tmp3))>0 then do
   tmp1=pos("CHARSET=",translate(tmp3))+8
   Globals.!CharSet=substr(tmp3,tmp1)
   if pos('"',Globals.!CharSet)>0 then parse value Globals.!CharSet with '"' Globals.!CharSet '"'
  end
  if pos("MULTIPART/MIXED;",translate(tmp3))>0|pos("MULTIPART/ALTERNATIVE;",translate(tmp3))>0 then do
   boundary=substr(tmp3,pos("BOUNDARY=",translate(tmp3))+9)
   boundary="--"||space(translate(boundary,"",'"'))
   if pos("MULTIPART/MIXED;",translate(tmp3))>0&arg(1)<>3 then do
    pozlength=1
    zi=0
    do while pos(boundary||'0d0a'x,ListMail.i.!b,pozlength)>0
     poz=pos(boundary||'0d0a'x,ListMail.i.!b,pozlength)
     pozlength=pos('0d0a'x||'0d0a'x,ListMail.i.!b,poz)+4
     headerz=substr(ListMail.i.!b,poz,pozlength-poz)
     if pos(" text",headerz)<1 then do
      if pos("name=",headerz)>0 then do
       zi=zi+1
       parse value headerz with . "name=""" Globals.!AttachFiles.zi """" .
      end; else Globals.!AttachFiles.zi="unknown"
     end
    end
    Globals.!AttachFiles.0=zi
    if Globals.!AttachFiles.0>0 then ListMail.i.!ContentType="YES"
   end
   poz=pos(boundary||'0d0a'x,ListMail.i.!b,1)
   if poz>0 then do
    pozlength=pos('0d0a'x||'0d0a'x,ListMail.i.!b,poz)+4
    pozend=pos(boundary,ListMail.i.!b,pozlength)-1
    call ScanSubHeaders substr(ListMail.i.!b,poz,pozlength-poz)
    ListMail.i.!b=substr(ListMail.i.!b,pozlength,pozend-pozlength)
   end
  end; else do
   if pos("CONTENT-TRANSFER-ENCODING: QUOTED-PRINTABLE",h1)>0 then qpyes=1
  end
 end
end
if arg(1)=3 then do
 if pos('0d0a'x||"REPLY-TO:",h1)>0 then do
  tmp1=pos('0d0a'x||"REPLY-TO:",h1)+11
  tmp2=pos('0d0a'x,h1,tmp1)
  tmp3=space(substr(ListMail.i.!h,tmp1,tmp2-tmp1))
  if pos("<",tmp3)>0&pos(">",tmp3)>0 then parse value tmp3 with . "<" tmp3 ">" .
  else if pos(" ",tmp3)>0 then tmp3=substr(tmp3,lastpos(" ",tmp3)+1)
  if tmp3<>ListMail.i.!From then do
   Globals.!EmailReplyTo=ListMail.i.!From
   ListMail.i.!From=space(tmp3)
  end
 end
 if pos('0d0a'x||"MESSAGE-ID:",h1)>0 then do
  tmp1=pos('0d0a'x||"MESSAGE-ID:",h1)+13
  tmp2=pos('0d0a'x,h1,tmp1)
  tmp3=space(substr(ListMail.i.!h,tmp1,tmp2-tmp1))
  ListMail.i.!MessageID=space(tmp3)
 end
 if pos('0d0a'x||"CC:",h1)>0 then do
  tmp1=pos('0d0a'x||"CC:",h1)+5
  tmp2=pos('0d0a'x,h1,tmp1)
  tmp3=space(substr(ListMail.i.!h,tmp1,tmp2-tmp1))
  if pos("<",tmp3)>0&pos(">",tmp3)>0 then parse value tmp3 with . "<" tmp3 ">" .
  else if pos(" ",tmp3)>0 then tmp3=substr(tmp3,lastpos(" ",tmp3)+1)
  ListMail.i.!Cc=space(tmp3)
 end; else ListMail.i.!Cc=""
end
return

/*:VRX         ScanSubHeaders
*/
ScanSubHeaders: procedure expose Globals. i ListMail. qpyes htmlyes
subheader=arg(1)
subheader=translate(subheader," ",'09'x)
poz=pos('0d0a'x,subheader)+2
do while poz<length(subheader)
 rc=substr(subheader,poz,1)
 if rc=" " then subheader=substr(subheader,1,poz-3)||" "||space(substr(subheader,poz+1))
 poz=pos('0d0a'x,subheader,poz)+2
end
h1=translate(subheader)
if pos('0d0a'x||"CONTENT-TYPE:",h1)>0 then do
 tmp1=pos('0d0a'x||"CONTENT-TYPE:",h1)+15
 tmp2=pos('0d0a'x,h1,tmp1)
 tmp3=space(substr(subheader,tmp1,tmp2-tmp1))
 if pos("TEXT/HTML",translate(tmp3))>0 then htmlyes=1
 if pos("CHARSET=",translate(tmp3))>0 then do
  tmp1=pos("CHARSET=",translate(tmp3))+8
  Globals.!CharSet=substr(tmp3,tmp1)
  if pos('"',Globals.!CharSet)>0 then parse value Globals.!CharSet with '"' Globals.!CharSet '"'
 end
 if pos('0d0a'x||"CONTENT-TRANSFER-ENCODING:",h1)>0 then do
  tmp1=pos('0d0a'x||"CONTENT-TRANSFER-ENCODING:",h1)+28
  tmp2=pos('0d0a'x,h1,tmp1)
  tmp3=space(substr(subheader,tmp1,tmp2-tmp1))
  if pos("QUOTED-PRINTABLE",translate(tmp3))>0 then qpyes=1
 end
end
return

/*:VRX         SendData
*/
SendData: procedure expose socket
call SockSend socket,ARG(1)
return

/*:VRX         SignScreen
*/
SignScreen: procedure expose Globals.
Globals.!ServerErr=""
Globals.!Sign=""
if Globals.!stat1="signaturesave=1" then do
 parse value Globals.!querystring with Globals.!querystring "s=" Globals.!Sign
 parse value Globals.!querystring with . "&returnto=" Globals.!stat2 "&"
 if pos("&from=",Globals.!querystring)>0 then parse value Globals.!querystring with "from=" Globals.!UserFake "&"
 else Globals.!UserFake=""
 if pos("&bcc=",Globals.!querystring)>0 then parse value Globals.!querystring with . "bcc=" Globals.!Bccto "&"
 else Globals.!Bccto=""
 if pos("&xface=",Globals.!queryencoded)>0 then parse value Globals.!queryencoded with . "xface=" xface "&"
 else xface=""
 if pos("&h=",Globals.!querystring)>0 then showheaders=1
 else showheaders=0
 if pos("&t=",Globals.!querystring)>0 then showhtml=1
 else showhtml=0
 if pos("&timezoneoffset=",Globals.!querystring)>0 then parse value Globals.!querystring with . "timezoneoffset=" Globals.!TimeZoneOffset "&"
 else Globals.!TimeZoneOffset="+0000"
 if length(Globals.!Sign)>250 then Globals.!ServerErr="Too many characters in the signature. Max size is 250."
 else if length(xface)>1024 then Globals.!ServerErr="Too many characters in the X-Face. Max size is 250."
 else do
  call ConnectManager
  Globals.!clientIP=value("REMOTE_ADDR",,'ENVIRONMENT')
  if Globals.!clientIP="" then call ErrorScreen 1,"CheckLogon: Can't detect your client"
  cookie=substr(Globals.!Cookie,pos("WEBMAIL2=",Globals.!Cookie)+9,33)
  call SendData "9:"||cookie||":"||Globals.!clientIP||":"||Globals.!Sign||":showheaders="||showheaders||"&showhtml="||showhtml||"&bccto="||Globals.!Bccto||"&xface="||xface||"&userfake="||Globals.!UserFake||"&timezoneoffset="||Globals.!TimeZoneOffset||"&:"||'0d0a'x
  call ReceiveData
  if substr(newData,1,1)=1 then Globals.!ServerErr="Setup saved successfully"
  else if substr(newData,1,1)=2 then Globals.!ServerErr="Setup can't be saved"
 end
 if Globals.!stat2>0 then do
  Globals.!stat3=""
  call ReceiveEmail
 end
 Globals.!stat2=""
 Globals.!stat3=""
end
i=0
call ConnectManager
Globals.!clientIP=value("REMOTE_ADDR",,'ENVIRONMENT')
if Globals.!clientIP="" then call ErrorScreen 1,"CheckLogon: Can't detect your client"
cookie=substr(Globals.!Cookie,pos("WEBMAIL2=",Globals.!Cookie)+9,33)
call SendData "8:"||cookie||":"||Globals.!clientIP||":"||'0d0a'x
call ReceiveDataExtended 32768
if pos("showheaders=",newData)=1 then parse value newData with "showheaders=" Globals.!ShowHeaders "&" newData
else Globals.!ShowHeaders=0
if pos("showhtml=",newData)=1 then parse value newData with "showhtml=" Globals.!ShowHtml "&" newData
else Globals.!ShowHtml=0
if pos("bccto=",newData)=1 then parse value newData with "bccto=" Globals.!Bccto "&" newData
else Globals.!Bccto=""
if pos("xface=",newData)=1 then do
 parse value newData with "xface=" ListMail.i.!XFace "&" newData
 if ListMail.i.!XFace<>"" then do
  Globals.!XFace=URLDecode(ListMail.i.!XFace)
  ListMail.i.!XFace=ReplaceStr(Globals.!XFace,"&","&amp;")
  ListMail.i.!XFace=ReplaceStr(ListMail.i.!XFace,"<","&lt;")
  ListMail.i.!XFace=ReplaceStr(ListMail.i.!XFace,">","&gt;")
  ListMail.i.!XFace=ReplaceStr(ListMail.i.!XFace,'"',"&quot;")
 end; else Globals.!XFace=""
end; else ListMail.i.!XFace=""
if pos("userfake=",newData)=1 then parse value newData with "userfake=" Globals.!UserFake "&" newData
else Globals.!UserFake=""
if pos("timezoneoffset=",newData)=1 then parse value newData with "timezoneoffset=" Globals.!TimeZoneOffset "&" newData
else Globals.!TimeZoneOffset="+0000"
Globals.!TimeZones='<option  value="-1200">-1200</option><option  value="-1100">-1100</option><option  value="-1000">-1000</option><option  value="-0900">-0900</option>'
Globals.!TimeZones=Globals.!TimeZones||'<option  value="-0800">-0800</option><option  value="-0700">-0700</option><option  value="-0600">-0600</option><option  value="-0500">-0500</option>'
Globals.!TimeZones=Globals.!TimeZones||'<option  value="-0400">-0400</option><option  value="-0330">-0330</option><option  value="-0300">-0300</option><option  value="-0230">-0230</option>'
Globals.!TimeZones=Globals.!TimeZones||'<option  value="-0200">-0200</option><option  value="-0100">-0100</option><option  value="+0000">+0000</option><option  value="+0100">+0100</option>'
Globals.!TimeZones=Globals.!TimeZones||'<option  value="+0200">+0200</option><option  value="+0300">+0300</option><option  value="+0330">+0330</option><option  value="+0400">+0400</option>'
Globals.!TimeZones=Globals.!TimeZones||'<option  value="+0500">+0500</option><option  value="+0530">+0530</option><option  value="+0600">+0600</option><option  value="+0630">+0630</option>'
Globals.!TimeZones=Globals.!TimeZones||'<option  value="+0700">+0700</option><option  value="+0800">+0800</option><option  value="+0900">+0900</option><option  value="+0930">+0930</option>'
Globals.!TimeZones=Globals.!TimeZones||'<option  value="+1000">+1000</option><option  value="+1030">+1030</option><option  value="+1100">+1100</option><option  value="+1200">+1200</option>'
Globals.!TimeZones=Globals.!TimeZones||'<option  value="+1300">+1300</option>'
if pos(Globals.!TimeZoneOffset,Globals.!TimeZones)>0 then
 Globals.!TimeZones=insert("selected ",Globals.!TimeZones,pos(Globals.!TimeZoneOffset,Globals.!TimeZones)-8)
if Globals.!ShowHeaders=1 then Globals.!ShowHeaders="checked"
else Globals.!ShowHeaders=""
if Globals.!ShowHtml=1 then Globals.!ShowHtml="checked"
else Globals.!ShowHtml=""
if Globals.!Bccto="" then ListMail.i.!Bcc=""
else ListMail.i.!Bcc=Globals.!Bccto
if pos("signature=",newData)=1 then do
 Globals.!Sign=substr(newData,11,lastpos(".",newData)-11)
end; else do
 Globals.!Sign=""
end
rc=SockSoClose(socket)
if rc=-1 then call ErrorScreen 1,"CheckLogon: Error on SockSoClose"
book=EmailScreen(1)
Globals.!EmailSelect=""
if pos('0d0a'x,book)>0 then do
 do while pos('0d0a'x,book)>0
  parse value book with email '0d0a'x book
  if email=Globals.!UserFake then
   selected="selected "
  else
   selected=""
  email=ReplaceStr(email,"<","&lt;")
  email=ReplaceStr(email,">","&gt;")
  Globals.!EmailSelect=Globals.!EmailSelect||"<option "||selected||"value='"||email||"'>"||email||'</option>'
 end
end; else do
 email="'"||Globals.!realname||"' <"||Globals.!user||'>'
 Globals.!EmailSelect='<option selected value="'||email||'">'||email||'</option>'
end
if ARG(1)=1 then return Globals.!Sign
if ARG(1)=2 then return Globals.!TimeZoneOffset
call ParseHTML Globals.!WMPath||"header.wm",1
call ParseHTML Globals.!WMPath||"setup.wm"
call ParseHTML Globals.!WMPath||"footer.wm"
exit

/*:VRX         URLDecode
*/
URLDecode: procedure
line=translate(ARG(1)," ","+")
lineLen=length(line)
newLine=''
i=1
do while i<=lineLen
 c=substr(line,i,1)
 if c\='%' then newLine=newLine||c
 else if i+2<=lineLen then do
  newLine= newLine||x2c(substr(line,i+1,2))
  i=i+2
 end
 i=i+1
end
return newLine
/* call charout "c:\tcpip\web2\cgi-bin\debug.txt",tmp */

/*:VRX         UserLoginScreen
*/
UserLoginScreen: procedure expose Globals.
Globals.!SetCookie="SET"
Globals.!AuthID=""
Globals.!SetCookiePage=""
call ParseHTML Globals.!WMPath||"userlogin.wm",1
exit

