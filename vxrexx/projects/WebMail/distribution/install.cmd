/* WebMail/2 Installation Script - Dimitrios 'sehh' Michelinakis */
Globals.!Color=1
call on halt name quit
call RxFuncAdd 'SysLoadFuncs','RexxUtil','SysLoadFuncs'
call SysLoadFuncs
call SysCurState 'OFF'
call SysCls
call ShowLogo
say "      Created by Dimitrios 'sehh' Michelinakis <dimitrios@michelinakis.gr>"
say ""
say "      WebMail/2 is a web to email gateway. WebMail/2 allows you to use your"
say "    web browser as a full-featured e-mail client. It does this by interfacing"
say "    your web server with your e-mail server and allowing a web browser to"
say "    send and receive e-mail information. You can use your existing email"
say "    solution on the web, you are not required to change anything from"
say "    your current configuration."
say ""
rc=linein("file_id.diz")
parse value rc with . "WebMail/2 " rc " =" .
if rc="" then rc="Unknown"
say "      =[ Installing version: "||rc||" ]="
say ""
say "                            Press any key to continue"
call SysGetKey
call SysCurState 'ON'
Globals.!WM=""
Globals.!CGI=""
Globals.!POPT=""
Globals.!WMFILES=""
Globals.!IMGFILES=""
Globals.!CGIDLL=""
Globals.!Icons=""
Globals.!SingleServer=""
Globals.!Docs=""
Globals.!Compress=""
Globals.!CustomFiles=""
pop3.1="Generic POP3 server              "
pop3.2="Weasel                           "
pop3.3="Inet.Mail                        "
pop3.4="Inet.Mail Pro                    "
pop3.5="InetPowerServer                  "
pop3.6="OS2PopS                          "
pop3.7="WebMail/2 internal users database"
pop3.8="ZxMail                           "
pop3.0=8
call SysCls
call Checks
call BeforeInstall
call ConfirmInstall
call SysCls
call InstallWM
call InstallWMFILES
call InstallIMGFILES
call InstallCGI
call InstallDLL
call CreateLog
call CreateIcons
call SysCurState 'OFF'
call SysCls
call ShowLogo
say "      Created by Dimitrios 'sehh' Michelinakis <dimitrios@michelinakis.gr>"
say ""
say "      Installation is complete! Thank you for using WebMail/2. Please read"
say "    the documentation, it explains this product in detail. You may also"
say "    contact the author for help or join our beta testers mailing list."
say ""
say ""
say "                            Press any key to continue"
call SysGetKey
call SysCurState 'ON'
exit(0)

BeforeInstall: procedure expose Globals. pop3.
call AskQ "Are you updating an existing installation of WebMail/2? (Y/N)"
Globals.!Update=AskYN()
if Globals.!Update=1 then do
 call AskQ "Enter the path to your existing WebManager installation."
 Globals.!WM=AskPath()
 if stream(Globals.!WM||"\install.log",'c','query exists')="" then call Quit "ERROR: Can't find install.log from previous installation."||'0d0a'x||"ERROR: The upgrade will work only if you've used the"||'0d0a'x||"ERROR: WebMail/2 installer in the past."
 data=charin(Globals.!WM||"\install.log",1,stream(Globals.!WM||"\install.log",'c','query size'))
 call stream Globals.!WM||"\install.log",'c','close'
 interpret data
 if Globals.!SingleServer=1&Globals.!Compress<>1 then do
  if stream(Globals.!CGI||"\webmail2.cmd",'c','query exists')="" then call Quit "ERROR: Couldn't find your existing webmail2.cmd."
  data=charin(Globals.!CGI||"\webmail2.cmd",1,2000)
  call stream Globals.!CGI||"\webmail2.cmd",'c','close'
  tmp1=pos("Globals.!serv=",data)+14
  tmp2=pos(" ",data,tmp1)
  Globals.!serv=substr(data,tmp1,tmp2-tmp1)
  tmp1=pos("Globals.!port=",data)+14
  tmp2=pos(" ",data,tmp1)
  Globals.!port=substr(data,tmp1,tmp2-tmp1)
  tmp1=pos('Globals.!WMPath="',data)+17
  tmp2=pos(" ",data,tmp1)-1
  Globals.!WMPath=substr(data,tmp1,tmp2-tmp1)
  if pos('Globals.!PrefixPath="',data)>0 then do
   tmp1=pos('Globals.!PrefixPath="',data)+21
   tmp2=pos(" ",data,tmp1)-1
   Globals.!PrefixPath=substr(data,tmp1,tmp2-tmp1)
  end; else Globals.!PrefixPath=""
  tmp1=pos("Globals.!MaxEmails=",data)+19
  tmp2=pos(" ",data,tmp1)
  Globals.!MaxEmails=substr(data,tmp1,tmp2-tmp1)
  tmp1=pos('Globals.!CharSet="',data)+18
  tmp2=pos(" ",data,tmp1)-1
  Globals.!CharSet=substr(data,tmp1,tmp2-tmp1)
  tmp1=pos('Globals.!TagLine="',data)+18
  tmp2=pos(" ",data,tmp1)-1
  Globals.!TagLine=substr(data,tmp1,tmp2-tmp1)
  tmp1=pos('Globals.!MaxAttachSize="',data)+24
  tmp2=pos(" ",data,tmp1)-1
  Globals.!MaxAttachSize=substr(data,tmp1,tmp2-tmp1)
 end
 if Globals.!CustomFiles="" then do
  call AskQ "Does your existing setup use custom .WM or image files? To avoid overwriting custom files, new files will be stored under a new path with '.new' extension. (Y/N)"
  Globals.!CustomFiles=AskYN()
 end
end
if Globals.!WM="" then do
 call AskQ "Please enter the path to install WebManager. Press Enter for default: "||SysBootDrive()||"\TCPIP\WebMail2"
 Globals.!WM=AskPath(1,SysBootDrive()||"\TCPIP\WebMail2")
end
if Globals.!SingleServer="" then do
 call AskQ "Is your web server on the same machine as WebManager? (Y/N)"
 Globals.!SingleServer=AskYN()
end
if Globals.!SingleServer=1 then do
 if Globals.!CGI="" then do
  call AskQ "Enter the path where you want the CGI script to be installed (/cgi-bin/)."
  Globals.!CGI=AskPath(1)
 end
 if Globals.!Compress="" then do
  call AskQ "Would you like the installation to compress the rexx CGI script into a binary exe? On heavy loaded systems this may improve speed. (Y/N)"
  Globals.!Compress=AskYN()
 end
 if Globals.!CGIDLL="" then do
  call AskQ "The CGI requires a few DLL files to be installed in the LIBPATH. Enter a path which exists in the LIBPATH. You may also use the current path of the CGI. Press Enter for default: "||SysBootDrive()||"\os2\dll"
  Globals.!CGIDLL=AskPath(1,SysBootDrive()||"\os2\dll")
 end
 if Globals.!WMFILES="" then do
  call AskQ "Enter the path to the WebMail/2 .WM files. Press Enter for default: "||Globals.!WM||"\WebmailHtml"
  Globals.!WMFILES=AskPath(1,Globals.!WM||"\webmailhtml")
 end
 if Globals.!IMGFILES="" then do
  call AskQ "Enter the path to the WebMail/2 images. Press Enter for default: "||Globals.!WM||"\WebmailImages"
  Globals.!IMGFILES=AskPath(1,Globals.!WM||"\webmailimages")
 end
end
if Globals.!Docs="" then do
 call AskQ "Enter the path to the documentation. Press Enter for default: "||Globals.!WM||"\documentation"
 Globals.!Docs=AskPath(1,Globals.!WM||"\documentation")
end
if Globals.!POPT="" then do
 call AskQ "Use the arrow/enter keys to select your POP3 server."
 i=1
 parse value SysCurPos() with row col
 call SysCurState 'OFF'
 do forever
  call charout ,pop3.i
  rc=c2x(SysGetKey('NOECHO'))
  call SysCurPos row,20
  if pos("4D",rc)>0 then do
   if i<7 then i=i+1
   else i=1
  end
  if pos("4B",rc)>0 then do
   if i>1 then i=i-1
   else i=7
  end
  if rc="0D" then do
   say ""
   Globals.!POPT=i
   call SysCurState 'ON'
   leave
  end
 end
end
if Globals.!Icons="" then do
 call AskQ "Create the WebMail/2 icons on the desktop? (Y/N)"
 Globals.!Icons=AskYN()
end
return

ConfirmInstall: procedure expose Globals. pop3.
call AskQ "Ready to install WebMail/2. Proceed with installation? (Y/N)"
if AskYN()=0 then call Quit ""
return

InstallWM: procedure expose Globals.
say "INSTALL: WebManager"
'@unzip.exe -o -qq webmanager.zip -d '||Globals.!WM||' >nul 2>nul'
if rc=50 then call Quit "ERROR: The existing WebManager/Setup EXE file is locked!"
say "INSTALL: Documentation"
'@unzip.exe -o -qq documentation.zip -d '||Globals.!Docs||' >nul 2>nul'
return

InstallWMFILES: procedure expose Globals.
if Globals.!SingleServer=0 then return
say "INSTALL: WM files"
if Globals.!CustomFiles=1 then
 WMFILES=Globals.!WMFILES||".new"
else
 WMFILES=Globals.!WMFILES
'@unzip.exe -o -qq webmailhtml.zip -d '||WMFILES||' >nul 2>nul'
'@mkdir '||WMFILES||'\metal >nul 2>nul'
'@unzip.exe -o -qq webmailhtml-metal.zip -d '||WMFILES||'\metal >nul 2>nul'
return

InstallIMGFILES: procedure expose Globals.
if Globals.!SingleServer=0 then return
say "INSTALL: Images"
if Globals.!CustomFiles=1 then
 IMGFILES=Globals.!IMGFILES||".new"
else
 IMGFILES=Globals.!IMGFILES
'@unzip.exe -o -qq webmailimages.zip -d '||IMGFILES||' >nul 2>nul'
'@mkdir '||IMGFILES||'\metal >nul 2>nul'
'@unzip.exe -o -qq webmailimages-metal.zip -d '||IMGFILES||'\metal >nul 2>nul'
return

InstallCGI: procedure expose Globals.
if Globals.!SingleServer=0 then return
say "INSTALL: CGI"
'@unzip.exe -o -qq cgi.zip webmail2.cmd -d '||Globals.!CGI||' >nul 2>nul'
if stream(Globals.!CGI||"\webmail2.cmd",'c','query exists')<>"" then do
 data=charin(Globals.!CGI||"\webmail2.cmd",1,stream(Globals.!CGI||"\webmail2.cmd",'c','query size'))
 call stream Globals.!CGI||"\webmail2.cmd",'c','close'
 if Globals.!Update=1&Globals.!Compress<>1 then do
  parse value data with tmp1 'Globals.!serv=' ' ' tmp2
  data=tmp1||'Globals.!serv='||Globals.!serv||' '||tmp2
  parse value data with tmp1 'Globals.!port=' ' ' tmp2
  data=tmp1||'Globals.!port='||Globals.!port||' '||tmp2
  parse value data with tmp1 'Globals.!WMPath="' '"' tmp2
  data=tmp1||'Globals.!WMPath="'||Globals.!WMPath||'"'||tmp2
  parse value data with tmp1 'Globals.!PrefixPath="' '"' tmp2
  data=tmp1||'Globals.!PrefixPath="'||Globals.!PrefixPath||'"'||tmp2
  parse value data with tmp1 'Globals.!MaxEmails=' ' ' tmp2
  data=tmp1||'Globals.!MaxEmails='||Globals.!MaxEmails||' '||tmp2
  parse value data with tmp1 'Globals.!CharSet="' '"' tmp2
  data=tmp1||'Globals.!CharSet="'||Globals.!CharSet||'"'||tmp2
  parse value data with tmp1 'Globals.!TagLine="' '"' tmp2
  data=tmp1||'Globals.!TagLine="'||Globals.!TagLine||'"'||tmp2
  parse value data with tmp1 'Globals.!MaxAttachSize="' '"' tmp2
  data=tmp1||'Globals.!MaxAttachSize="'||Globals.!MaxAttachSize||'"'||tmp2
 end; else do
  parse value data with tmp1 'Globals.!WMPath="' '"' tmp2
  data=tmp1||'Globals.!WMPath="'||Globals.!WMFILES||'\"'||tmp2
 end
 call SysFileDelete Globals.!CGI||"\webmail2.cmd"
 call charout Globals.!CGI||"\webmail2.cmd",data
 call stream Globals.!CGI||"\webmail2.cmd",'c','close'
end
if Globals.!Compress=1 then do
 '@unzip.exe -o -qq cgi.zip rexx2exe.exe -d . >nul 2>nul'
 '@rexx2exe.exe '||Globals.!CGI||'\webmail2.cmd '||Globals.!CGI||'\webmail2.exe /C >nul 2>nul'
 call SysFileDelete ".\rexx2exe.exe"
 call SysFileDelete Globals.!CGI||'\webmail2.cmd'
end
return

InstallDLL: procedure expose Globals.
say "INSTALL: DLL"
if Globals.!POPT=3 then '@unzip.exe -o -qq dll.zip HRxPass.dll -d '||Globals.!WM||' >nul 2>nul'
if Globals.!POPT=4 then do
 '@unzip.exe -o -qq dll.zip HRxPassPro.dll -d '||Globals.!WM||' >nul 2>nul'
 '@rename '||Globals.!WM||'\HRxPassPro.dll HRxPass.dll >nul 2>nul'
end
if Globals.!POPT=5 then '@unzip.exe -o -qq dll.zip ipsrexx.dll -d '||Globals.!WM||' >nul 2>nul'
if Globals.!SingleServer=1 then '@unzip.exe -o -qq dll.zip dcdll.dll dcplus.dll rxdcplus.dll rxface.dll -d '||Globals.!CGIDLL||' >nul 2>nul'
return

CreateLog: procedure expose Globals.
say "INSTALL: Log file"
data='Globals.!WM="'||Globals.!WM||'";'
data=data||'Globals.!CGI="'||Globals.!CGI||'";'
data=data||'Globals.!POPT="'||Globals.!POPT||'";'
data=data||'Globals.!WMFILES="'||Globals.!WMFILES||'";'
data=data||'Globals.!IMGFILES="'||Globals.!IMGFILES||'";'
data=data||'Globals.!CGIDLL="'||Globals.!CGIDLL||'";'
data=data||'Globals.!SingleServer='||Globals.!SingleServer||";"
data=data||'Globals.!Icons='||Globals.!Icons||";"
data=data||'Globals.!Docs="'||Globals.!Docs||'";'
data=data||'Globals.!Compress='||Globals.!Compress||";"
call SysFileDelete Globals.!WM||"\install.log"
call charout Globals.!WM||"\install.log",data
call stream Globals.!WM||"\install.log",'c','close'
return

CreateIcons: procedure expose Globals.
if Globals.!Icons=0 then return
say "INSTALL: Icons"
call SysCreateObject 'WPFolder','WebMail/2','<WP_DESKTOP>','OBJECTID=<WEBMAIL2FLDR>;'||'ALWAYSSORT=YES','Update'
call SysCreateObject 'WPProgram','WebManager','<WEBMAIL2FLDR>','EXENAME='||Globals.!WM||'\WebManager.exe;'||'STARTUPDIR='||Globals.!WM||';OBJECTID=<WEBMANAGEREXE>','Update'
call SysCreateObject 'WPProgram','Setup','<WEBMAIL2FLDR>','EXENAME='||Globals.!WM||'\setup.exe;'||'STARTUPDIR='||Globals.!WM||';OBJECTID=<WMSETUPEXE>','Update'
call SysCreateObject 'WPURL','Documentation','<WEBMAIL2FLDR>','NOPRINT=YES;URL=file:///'||ReplaceStr(space(Globals.!Docs),"\","/")||'/index.html','Update'
call SysCreateObject 'WPURL','Home page','<WEBMAIL2FLDR>','NOPRINT=YES;URL=http://www.michelinakis.gr/Dimitris/webmail/','Update'
call SysCreateObject 'WPURL','Bug report','<WEBMAIL2FLDR>','NOPRINT=YES;URL=http://www.michelinakis.gr/Dimitris/webmail/bugtracker/','Update'
return

Checks: procedure expose Globals.
if SysSearchPath("PATH","unzip.exe")="" then call Quit "ERROR: Unzip.exe was not found in the system path."
return

AskYN: procedure expose Globals.
do forever
 rc=translate(SysGetKey('NOECHO'))
 if rc="Y" then return 1
 else if rc="N" then return 0
 call Quit "ERROR: Invalid answer."
end
return 0 /* Make script valid for ObjRexx */

AskPath: procedure expose Globals.
path=linein()
if path=""&arg(2)<>"" then path=arg(2)
else if path="" then exit(0)
if lastpos("\",path)=length(path) then path=substr(path,1,length(path)-1)
curdir=directory()
newdir=directory(path)
call directory curdir
if translate(newdir)<>translate(path) then do
 if arg(1)=1 then do
  call AskQ "Directory doesn't exist, create? (Y/N)"
  if AskYN()=1 then do
   '@mkdir '||path||' >nul 2>nul'
   if rc<>0 then call Quit "ERROR: Can't create directory."
  end; else call Quit "ERROR: Directory doesn't exist."
 end; else call Quit "ERROR: Directory doesn't exist."
end
return path
 
AskFile: procedure expose Globals.
call charout ,"-["
file=linein()
if file="" then exit(0)
if stream(file,'c','query exists')="" then call Quit "ERROR: File "||filespec('N',file)||" doesn't exist."
return file

AskQ: procedure expose Globals.
q=arg(1)
call SysCls
if Globals.!Color=1 then do
 /* say "[?7h[255D[40m" */
 say ""
 say ""
 say ""
 say ""
 say "[0;1m[16CÜÜßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßÜÜ"
 say "[14CÛß  [47m²[40mßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß[47m²[2C[40mßÛ"
 say "[14C[47m±[1C[0;32m± [1;37;47m±[42C±[1C[0;32m± [1;37;47m±[40m"
 say "[14C[47m°[1C[0;32m² [1;37;47m°[42C°[1C[0;32m² [1;37;47m°[40m"
 say "[14C[0mÛ [32mÛ [37mÛ[42CÛ [1;32;42m°[1C[0mÛ"
 say "[14C[1;30;47m°[1C[32;42m°[1C[30;47m°[42C°[1C[32;42m±[1C[30;47m°[40m"
 say "[14C[47m±[1C[32;42m±[1C[30;47m±[42C±[1C[32;42m²[1C[30;47m±[40m"
 say "[14C[47m²[1C[32;42m²[1C[30;47m²[42C²[1C[32;42m²[1C[30;47m²[40m"
 say "[14CßßÜÜßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßÜÜßß"
 say "[18Cßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß"
 say ""
 say ""
 say ""
 say ""
 say ""
 say ""
 say ""
 say ""
 say ""
 say "[0m[255D"
end
if length(q)<40 then do
 call SysCurPos 6,21
 call charout ,q
end; else do
 i=5
 do forever
  i=i+1
  call SysCurPos i,20
  if length(q)>40 then do
   if lastpos(" ",q,40)>0 then do
    call charout ,substr(q,1,lastpos(" ",q,40))
    q=substr(q,lastpos(" ",q,40)+1)
   end; else do 
    call charout ,substr(q,1,40)
    q=substr(q,41)
   end
  end; else do
   call charout ,substr(q,1,length(q))
   leave
  end
 end
end
call SysCurPos 11,20
return

Quit: procedure expose Globals.
call SysCls
call ShowLogo
say ""
say arg(1)
exit(9)
 
ShowLogo: procedure expose Globals.
if Globals.!Color=0 then do
 say ""
 say " ÛÛ»    ÛÛ» ÛÛÛÛÛÛÛ» ÛÛÛÛÛÛ»  ÛÛÛ»   ÛÛÛ»  ÛÛÛÛÛ»  ÛÛ» ÛÛ»          Û» ÛÛÛÛÛÛ»"
 say " ÛÛº    ÛÛº ÛÛÉÍÍÍÍ¼ ÛÛÉÍÍÛÛ» ÛÛÛÛ» ÛÛÛÛº ÛÛÉÍÍÛÛ» ÛÛº ÛÛº         ÛÉ¼ ÈÍÍÍÍÛÛ»"
 say " ÛÛº Û» ÛÛº ÛÛÛÛÛ»   ÛÛÛÛÛÛÉ¼ ÛÛÉÛÛÛÛÉÛÛº ÛÛÛÛÛÛÛº ÛÛº ÛÛº        ÛÉ¼   ÛÛÛÛÛÉ¼"
 say " ÛÛºÛÛÛ»ÛÛº ÛÛÉÍÍ¼   ÛÛÉÍÍÛÛ» ÛÛºÈÛÛÉ¼ÛÛº ÛÛÉÍÍÛÛº ÛÛº ÛÛº       ÛÉ¼   ÛÛÉÍÍÍ¼"
 say " ÈÛÛÛÉÛÛÛÉ¼ ÛÛÛÛÛÛÛ» ÛÛÛÛÛÛÉ¼ ÛÛº ÈÍ¼ ÛÛº ÛÛº  ÛÛº ÛÛº ÛÛÛÛÛÛÛ» ÛÉ¼    ÛÛÛÛÛÛÛ»"
 say "  ÈÍÍ¼ÈÍÍ¼  ÈÍÍÍÍÍÍ¼ ÈÍÍÍÍÍ¼  ÈÍ¼     ÈÍ¼ ÈÍ¼  ÈÍ¼ ÈÍ¼ ÈÍÍÍÍÍÍ¼ È¼     ÈÍÍÍÍÍÍ¼"
end; else do
 say "[?7h[255D[0;1;34mÚÄ[37m¿  [34mÚÄ[37m¿ [34mÚ[0;34mÄÄÄÄÄ[1mÄ[37m¿ [34mÚ[0;34mÄÄÄÄ[1mÄ[37m¿  [34mÚ[0;34mÄÄÄÄÄ[1mÄ[37m¿ [34mÚ[0;34m"
 say "[A[37CÄÄÄÄÄ[1mÄ[37m¿ [0;34mÚ[1mÄ[37m¿ [34mÚÄ[37m¿[14C[34mÚ[0;34mÄ[1mÄ[37m¿ [34mÚ[0;34mÄÄÄÄÄ[1mÄ[37m¿"
 say "À[34mÄÙ  [37mÀ[34mÄÙ [37mÀ[34mÄ[0;34mÄÄÄÄÄ[1mÙ [37mÀ[34mÄ[0;34mÄÄÄÄ[1mÙ  [37mÀ[34mÄ[0;34mÄÄÄÄÄ[1mÙ [37mÀ[34mÄ[0;34mÄÄÄÄÄ[1mÙ [A"
 say "[45C[37mÀ[34mÄÙ [37mÀ[34mÄÙ[14C[37mÀ[34mÄ[0;34mÄ[1mÙ [37mÀ[34mÄ[0;34mÄÄÄÄÄ[1mÙ"
 say "[0;34mÚÄ¿  Ú[1mÄ[37m¿ [0;34mÚÄÄÄ[1mÄ[37m¿   [0;34mÚÄÄÄÄÄ[1mÄ[37m¿ [0;34mÚ[1mÄ[37m¿[34mÚ[37m¿[0;34mÚ[1mÄ[37m¿ [0;34mÚÄÄÄÄÄ[1mÄ[A"
 say "[43C[37m¿ [0;34mÚ[1mÄ[37m¿ [0;34mÚ[1mÄ[37m¿[10C[0;34mÚÄ[1mÄ[37m¿[5C[0;34mÚÄÄÄÄÄ[1mÄ[37m¿"
 say "[0;34m³ ³[1mÚ[37m¿[0;34m³ [1m³ [0;34m³ ÚÄÄ[1mÙ   [0;34m³ ÚÄÄ¿ [1m³ [0;34m³ [1m³[37mÀ[34mÙ[0;34m³ [1m³ [0;34m³ ÚÄÄ¿ [1m³ [0;34m³ [A"
 say "[47C[1m³ [0;34m³ [1m³[8C[0;34mÚÄÙÚÄ[1mÙ[5C[0;34m³ ÚÄÄÄÄ[1mÙ"
 say "³ [0;34mÀÙ[1mÀ[0;34mÙ ³ [1m³ [0;34mÀÄÄÄ[1mÄ[37m¿ [34m³ [0;34mÀÄÄÙ ³ [1m³ [0;34m³  [1m³ [0;34m³ [1m³ [0;34m³  [1m³ [0;34m³ [1m³ [A"
 say "[47C[0;34m³ [1m³ [0;34mÀÄÄÄ[1mÄ[37m¿ [34mÚ[0;34mÄÙÚÄÙ[7C[1m³ [0;34mÀÄÄÄ[1mÄ[37m¿"
 say "À[34mÄ[0;34mÄÄÄÄÄÙ [1;37mÀ[34mÄ[0;34mÄÄÄÄÄ[1mÙ [37mÀ[34mÄ[0;34mÄÄÄÄÄÙ [1;37mÀ[34mÄ[0;34mÙ  [1;37mÀ[34mÄ[0;34mÙ [1;37mÀ[34mÄ[0;34m[A"
 say "[38CÙ  [1;37mÀ[34mÄ[0;34mÙ [1;37mÀ[34mÄ[0;34mÙ [1;37mÀ[34mÄ[0;34mÄÄÄÄÄ[1mÙ [37mÀ[34mÄ[0;34mÄÙ[9C[1;37mÀ[34mÄ[0;34mÄÄÄÄÄ[1mÙ"
 say "[0m[255D"
end
return

ReplaceStr: procedure
tmp1=ARG(1)
tmp2=ARG(2)
tmp3=ARG(3)
do forever
 iz=pos(tmp2,tmp1)
 if iz<1 then leave
 tmp=substr(tmp1,1,iz-1)
 tmpp=substr(tmp1,iz+length(tmp2))
 tmp1=tmp||tmp3||tmpp
end
return tmp1
