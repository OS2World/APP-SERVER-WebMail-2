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

/*:VRX         CB_2_Click
*/
CB_2_Click: procedure
if VRGet("CB_2","Set")=1 then do
 call VRSet "DT_15","Enabled",1
 call VRSet "EF_9","Enabled",1
 call VRSet "DT_18","Enabled",1
 call VRSet "EF_10","Enabled",1
end; else do
 call VRSet "DT_15","Enabled",0
 call VRSet "EF_9","Enabled",0
 call VRSet "DT_18","Enabled",0
 call VRSet "EF_10","Enabled",0
end
return

/*:VRX         CB_3_Click
*/
CB_3_Click: procedure
if VRGet("CB_3","Set")=1 then do
 call VRSet "DT_30","Enabled",1
 call VRSet "EF_16","Enabled",1
 call VRSet "CB_4","Enabled",1
 call VRSet "PB_11","Enabled",1
 call VRSet "PB_16","Enabled",1
end; else do
 call VRSet "DT_30","Enabled",0
 call VRSet "EF_16","Enabled",0
 call VRSet "CB_4","Enabled",0
 call VRSet "PB_11","Enabled",0
 call VRSet "PB_16","Enabled",0
end
return

/*:VRX         CB_7_Click
*/
CB_7_Click: procedure
if VRGet("CB_7","Set")=1 then do
 call VRSet "DT_20","Enabled",1
 call VRSet "EF_21","Enabled",1
end; else do
 call VRSet "DT_20","Enabled",0
 call VRSet "EF_21","Enabled",0
end
return

/*:VRX         CN_1_Click
*/
CN_1_Click: procedure
call VRMethod "CN_1","GetRecordList","SourceOrSelected","records."
caption=VRMethod("CN_1","GetRecordAttr",records.1,"Caption")
if caption="Users" then z=2
else if caption="Settings" then z=3
else if caption="Settings 2" then z=5
else if caption="Access" then z=7
else if caption="Access 2" then z=14
else z=3
call VRSet "GB_2","Visible",0
call VRSet "GB_3","Visible",0
call VRSet "GB_5","Visible",0
call VRSet "GB_7","Visible",0
call VRSet "GB_14","Visible",0
call VRSet "GB_"||z,"Visible",1
return

/*:VRX         DDCB_1_Change
*/
DDCB_1_Change: procedure
/* pop3 ip/port YES */
call VRSet "EF_5","Enabled",1
call VRSet "EF_8","Enabled",1
/* InetMail Pro Settings Button NO */
call VRSet "PB_5","Enabled",0
call VRSet "PB_5","Visible",0
/* users database NO */
call VRSet "PB_6", "Enabled",0
call VRSet "PB_7", "Enabled",0
call VRSet "PB_8", "Enabled",0
/* login type NO */
call VRSet "CB_6", "Enabled",0
if VRGet("DDCB_1","Selected")=1 then do
/* Internal users */
 /* users database YES */
 call VRSet "PB_6","Enabled",1
 call VRSet "PB_7","Enabled",1
 call VRSet "PB_8","Enabled",1
 /* database path NO */
 call VRSet "DT_14","Enabled",0
 call VRSet "DT_14","Visible",1
 call VRSet "EF_1","Enabled",0
 call VRSet "EF_1","Visible",1
 /* user refresh YES */
 call VRSet "DT_7","Enabled",1
 call VRSet "EF_3","Enabled",1
 call VRSet "DT_8","Enabled",1
 /* New User Registration YES */
 call VRSet "CB_3","Enabled",1
 call CB_3_Click
 /* Ignore domains NO */
 call VRSet "CB_5","Set",0
end; else if VRGet("DDCB_1","Selected")=2 then do
/* InetPowerServer */
 /* database path YES */
 call VRSet "DT_14","Caption", "IPS Users path"
 call VRSet "DT_14","Enabled",1
 call VRSet "DT_14","Visible",1
 call VRSet "EF_1","Enabled",1
 call VRSet "EF_1","Visible",1
 /* user refresh YES */
 call VRSet "DT_7","Enabled",1
 call VRSet "EF_3","Enabled",1
 call VRSet "DT_8","Enabled",1
 /* New User Registration YES */
 call VRSet "CB_3","Enabled",1
 call CB_3_Click
 /* Ignore domains NO */
 call VRSet "CB_5","Set",0
end; else if VRGet("DDCB_1","Selected")=3 then do
/* Inet.Mail */
 /* database path */
 call VRSet "DT_14", "Caption", "Inet.mail path"
 call VRSet "DT_14", "Enabled",1
 call VRSet "EF_1", "Enabled",1
 call VRSet "DT_14", "Visible",1
 call VRSet "EF_1", "Visible",1
 /* user refresh NO */
 call VRSet "DT_7", "Enabled", 0
 call VRSet "EF_3", "Enabled", 0
 call VRSet "DT_8", "Enabled", 0
 /* New User Registration YES */
 call VRSet "CB_3","Enabled",1
 call CB_3_Click
 /* Ignore domains YES */
 call VRSet "CB_5","Set",1
end; else if VRGet("DDCB_1","Selected")=4 then do
/* Weasel */
 /* database path YES */
 call VRSet "DT_14", "Caption", "Weasel path"
 call VRSet "DT_14", "Enabled",1
 call VRSet "EF_1", "Enabled",1
 call VRSet "DT_14", "Visible",1
 call VRSet "EF_1", "Visible",1
 /* user refresh YES */
 call VRSet "DT_7", "Enabled", 1
 call VRSet "EF_3", "Enabled", 1
 call VRSet "DT_8", "Enabled", 1
 /* New User Registration YES */
 call VRSet "CB_3","Enabled",1
 call CB_3_Click
 /* Ignore domains YES */
 call VRSet "CB_5","Set",1
end; else if VRGet("DDCB_1","Selected")=5 then do
/* Inet.Mail Pro */
 /* pop3 ip/port */
 call VRSet "EF_5", "Enabled", 0
 call VRSet "EF_8", "Enabled", 0
 /* database path YES */
 call VRSet "DT_14","Enabled",0
 call VRSet "EF_1","Enabled",0
 call VRSet "DT_14", "Visible",0
 call VRSet "EF_1", "Visible",0
 call VRSet "PB_5", "Enabled",1
 call VRSet "PB_5", "Visible",1
 /* user refresh NO */
 call VRSet "DT_7","Enabled",0
 call VRSet "EF_3","Enabled",0
 call VRSet "DT_8","Enabled",0
 /* New User Registration NO */
 call VRSet "CB_3","Set",0
 call VRSet "CB_3","Enabled",0
 call CB_3_Click
 /* Ignore domains NO */
 call VRSet "CB_5","Set",0
end; else if VRGet("DDCB_1","Selected")=6 then do
/* Generic POP3 */
 /* database path NO */
 call VRSet "DT_14", "Enabled",0
 call VRSet "EF_1", "Enabled",0
 call VRSet "DT_14", "Visible",1
 call VRSet "EF_1", "Visible",1
 /* user refresh NO */
 call VRSet "DT_7", "Enabled", 0
 call VRSet "EF_3", "Enabled", 0
 call VRSet "DT_8", "Enabled", 0
 /* New User Registration NO */
 call VRSet "CB_3","Set",0
 call VRSet "CB_3","Enabled",0
 call CB_3_Click
 /* Ignore domains NO */
 call VRSet "CB_5","Set",0
 /* login type YES */
 call VRSet "CB_6", "Enabled",1
end; else if VRGet("DDCB_1","Selected")=7 then do
/* OS2PopS */
 /* users database NO */
 call VRSet "PB_6", "Enabled",0
 call VRSet "PB_7", "Enabled",0
 call VRSet "PB_8", "Enabled",0
 /* database path YES */
 call VRSet "DT_14", "Caption", "OS2PopS path"
 call VRSet "DT_14", "Enabled",1
 call VRSet "EF_1", "Enabled",1
 call VRSet "DT_14", "Visible",1
 call VRSet "EF_1", "Visible",1
 /* user refresh YES */
 call VRSet "DT_7", "Enabled", 1
 call VRSet "EF_3", "Enabled", 1
 call VRSet "DT_8", "Enabled", 1
 /* New User Registration YES */
 call VRSet "CB_3","Enabled",1
 call CB_3_Click
 /* Ignore domains YES */
 call VRSet "CB_5","Set",1
end; else if VRGet("DDCB_1","Selected")=8 then do
/* ZxMail */
 /* database path NO */
 call VRSet "DT_14", "Caption", ""
 call VRSet "DT_14", "Enabled",0
 call VRSet "EF_1", "Enabled",0
 call VRSet "DT_14", "Visible",1
 call VRSet "EF_1", "Visible",1
 /* user refresh NO */
 call VRSet "DT_7", "Enabled", 0
 call VRSet "EF_3", "Enabled", 0
 call VRSet "DT_8", "Enabled", 0
 /* New User Registration NO */
 call VRSet "CB_3","Enabled",0
 call CB_3_Click
 /* Ignore domains YES */
 call VRSet "CB_5","Set",1
end; else if VRGet("DDCB_1","Selected")=9 then do
/* Weasel Pro */
 /* database path YES */
 call VRSet "DT_14", "Caption", "Weasel path"
 call VRSet "DT_14", "Enabled",1
 call VRSet "EF_1", "Enabled",1
 call VRSet "DT_14", "Visible",1
 call VRSet "EF_1", "Visible",1
 /* user refresh YES */
 call VRSet "DT_7", "Enabled", 1
 call VRSet "EF_3", "Enabled", 1
 call VRSet "DT_8", "Enabled", 1
 /* New User Registration NO */
 call VRSet "CB_3","Enabled",0
 call CB_3_Click
 /* Ignore domains NO */
 call VRSet "CB_5","Set",0
 /* login type YES */
 call VRSet "CB_6", "Enabled",1
end
return

/*:VRX         EF_12_Change
*/
EF_12_Change: procedure
tmp=VRGet("EF_12","Value")
nodot=space(translate(tmp,"","."),0)
if datatype(nodot,"N")<>1 then do
 call VRMethod "EF_12","SetFocus"
 call VRMessage VRWindow(),"Please enter a valid IP address.","Error","E"
end
return

/*:VRX         EF_2_Change
*/
EF_2_Change: procedure
if datatype(VRGet("EF_2","Value"),"W")<>1 | VRGet("EF_2","Value")<1 | VRGet("EF_2","Value")>120 then do
 call VRMethod "EF_2","SetFocus"
 call VRMessage VRWindow(), "Please enter a valid number of minutes (>=1 and <=120.","Error","E"
end
return

/*:VRX         EF_3_Change
*/
EF_3_Change: procedure
if datatype(VRGet("EF_3","Value"),"W")<>1 | VRGet("EF_3","Value")<1 | VRGet("EF_3","Value")>65535 then do
 call VRMethod "EF_3","SetFocus"
 call VRMessage VRWindow(),"Please enter a valid number of minutes (>=1 and <=60000).","Error","E"
end
return

/*:VRX         EF_4_Change
*/
EF_4_Change: procedure
if datatype(VRGet("EF_4","Value"),"W")<>1 | VRGet("EF_4","Value")<1 | VRGet("EF_4","Value")>65535 then do
 call VRMethod "EF_4","SetFocus"
 call VRMessage VRWindow(),"Please enter a valid port number (<=65535).","Error","E"
end
return

/*:VRX         EF_7_Change
*/
EF_7_Change: procedure
if datatype(VRGet("EF_7","Value"),"W")<>1 | VRGet("EF_7","Value")<1 | VRGet("EF_7","Value")>65535 then do
 call VRMethod "EF_7","SetFocus"
 call VRMessage VRWindow(),"Please enter a valid port number (<=65535).","Error","E"
end
return

/*:VRX         EF_8_Change
*/
EF_8_Change: procedure
if datatype(VRGet("EF_8","Value"),"W")<>1 | VRGet("EF_8","Value")<1 | VRGet("EF_8","Value")>65535 then do
 call VRMethod "EF_8","SetFocus"
 call VRMessage VRWindow(),"Please enter a valid port number (<=65535).","Error","E"
end
return

/*:VRX         EF_9_Change
*/
EF_9_Change: procedure
if datatype(VRGet("EF_9","Value"),"W")<>1 | VRGet("EF_9","Value")<1 | VRGet("EF_9","Value")>65535 then do
 call VRMethod "EF_9","SetFocus"
 call VRMessage VRWindow(),"Please enter a valid number (>1 and <=65535).","Error","E"
end
return

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

/*:VRX         InetMailProSettings_Close
*/
InetMailProSettings_Close: 
    call InetMailProSettings_Fini
return

/*:VRX         InetMailProSettings_Create
*/
InetMailProSettings_Create: 
call VRMethod "LB_8","AddStringList","Globals.!IMPDomains.",,"Globals.!IMPPaths."
call InetMailProSettings_Init
return

/*:VRX         InetMailProSettings_Fini
*/
InetMailProSettings_Fini: 
    window = VRInfo( "Window" )
    call VRDestroy window
    drop window
return
/*:VRX         InetMailProSettings_Init
*/
InetMailProSettings_Init: 
    window = VRInfo( "Object" )
    if( \VRIsChildOf( window, "Notebook" ) ) then do
        call VRMethod window, "CenterWindow"
        call VRSet window, "Visible", 1
        call VRMethod window, "Activate"
    end
    drop window
return

/*:VRX         Init
*/
Init: procedure expose Globals.
Globals.!WorkingDir=VRGet("Application","Program")
Globals.!WorkingDir=substr(Globals.!WorkingDir,1,lastpos('\',Globals.!WorkingDir)-1)
Globals.!IniFile=Globals.!WorkingDir||"\WebManager.ini"
Globals.!Program="WebManager.EXE"
Globals.!WindowLeft=VRGetIni(Globals.!Program,"LeftSetup",Globals.!IniFile,"NoClose")
Globals.!WindowTop=VRGetIni(Globals.!Program,"TopSetup",Globals.!IniFile,"NoClose")
Globals.!Users.0=0
Globals.!Access.0=0
Globals.!AccessCli.0=0
Globals.!OnlineUsr.0=0
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
Globals.!POP3P=VRGetIni(Globals.!Program,"POP3P",Globals.!IniFile,"NoClose")
if Globals.!POP3P="" then Globals.!POP3P="110"
Globals.!SMTP=VRGetIni(Globals.!Program,"SMTP",Globals.!IniFile,"NoClose")
if Globals.!SMTP="" then Globals.!SMTP="127.0.0.1"
Globals.!SMTPP=VRGetIni(Globals.!Program,"SMTPP",Globals.!IniFile,"NoClose")
if Globals.!SMTPP="" then Globals.!SMTPP="25"
Globals.!Ignored=VRGetIni(Globals.!Program,"Ignored",Globals.!IniFile,"NoClose")
if Globals.!Ignored="" then Globals.!Ignored=0
Globals.!FullEmail=VRGetIni(Globals.!Program,"FullEmail",Globals.!IniFile,"NoClose")
if Globals.!FullEmail="" then Globals.!FullEmail=0
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
Globals.!UserPath=VRGetIni(Globals.!Program,"UserPath",Globals.!IniFile,"NoClose")
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
drop tmp
drop tmp1
Globals.!NewUsers=VRGetIni(Globals.!Program,"NewUsers",Globals.!IniFile,"NoClose")
if Globals.!NewUsers="" then Globals.!NewUsers=0
Globals.!NewUsersNot=VRGetIni(Globals.!Program,"NewUsersNot",Globals.!IniFile,"NoClose")
Globals.!NewUsersAuto=VRGetIni(Globals.!Program,"NewUsersAuto",Globals.!IniFile,"NoClose")
if Globals.!NewUsersAuto="" then Globals.!NewUsersAuto=0
window=VRWindow()
if (Globals.!WindowLeft \= '' & Globals.!WindowTop \= '') then call VRSet window,'Left',Globals.!WindowLeft,'Top',Globals.!WindowTop
else call VRMethod window, "CenterWindow"
Globals.!StartMin=VRGetIni(Globals.!Program,"StartMin",Globals.!IniFile,"NoClose")
if Globals.!StartMin<>0 & Globals.!StartMin<>1 then Globals.!StartMin = 0
call VRSet window,"Visible", 1
call VRMethod window,"Activate"
drop window
return

/*:VRX         LB_8_Click
*/
LB_8_Click: procedure
call VRMethod "LB_8","GetSelectedList","indices."
if indices.0<1 then return
call VRSet "EF_18","Value",VRMethod("LB_8","GetString",indices.1)
data=VRMethod("LB_8","GetItemData",indices.1)
parse value data with data1 '02'x data2 '03'x data3
call VRSet "EF_17","Value",data1
call VRSet "EF_19","Value",data2
call VRSet "EF_20","Value",data3
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
call VRMethod "LB_1","Reset"
if Globals.!UserDataBase=1 & Globals.!Users.0>0 then call VRMethod "LB_1","AddStringList","Globals.!Users."
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
  Globals.!Users.z=appz.i||":"||strip(pwd,,'00'x)||":"||fullname
 end
end
Globals.!Users.0=z
return

/*:VRX         PB_10_Click
*/
PB_10_Click:
call PB_4_Click
return

/*:VRX         PB_11_Click
*/
PB_11_Click: procedure expose Globals.
status=VRMethod("LB_5","GetSelectedStringList","selects.")
if selects.0<1 then return
call PB_16_Click
do i=1 to selects.0
 call User_Register selects.i
 call VRMethod "LB_5","DeleteString",selects.i
end
call VRMethod "LB_5","GetStringList","strings."
ConfigFile=Globals.!WorkingDir||"\WebManager.new"
call stream ConfigFile,'c','close'
call VRDeleteFile(ConfigFile)
call stream ConfigFile,'c','open write'
do i=1 to strings.0
 call lineout ConfigFile, strings.i
end
call stream ConfigFile,'c','close'
return

/*:VRX         PB_12_Click
*/
PB_12_Click: procedure expose Globals.
status = VRMethod( "LB_2", "GetSelectedStringList", "selects." )
if selects.0<1 then return
do i=1 to selects.0
 call VRMethod "LB_2", "DeleteString", selects.i
end
call VRMethod "LB_2", "GetStringList", "strings."
ConfigFile=Globals.!WorkingDir||"\WebManager.acc"
call stream ConfigFile, 'c', 'close'
call VRDeleteFile(ConfigFile)
call stream ConfigFile, 'c', 'open'
Globals.!Access.0=strings.0
do i=1 to strings.0
 Globals.!Access.i=strings.i
 call lineout ConfigFile, strings.i
end
call stream ConfigFile, 'c', 'close'
return

/*:VRX         PB_13_Click
*/
PB_13_Click: procedure expose Globals.
tmp = ""
button.0 = 2
button.1 = "Add"
button.2 = "Cancel"
call VRPrompt VRWindow(), "Please enter IP address:", ,
              "tmp", "Add allowed IP", "button.", 1, 2
if result = 2 | tmp = "" then return
pos = VRMethod( "LB_2", "FindString", tmp,, "Exact" )
if pos<>0 then do
 call VRMessage VRWindow(),"IP already exists!","Error","E"
 return
end
rc = SockGetHostByName(tmp,"host.!")
if (rc <> 0) then tmp = host.!addr
ConfigFile=Globals.!WorkingDir||"\WebManager.acc"
call lineout ConfigFile, tmp
i=Globals.!Access.0+1
Globals.!Access.i=tmp
Globals.!Access.0=i
call VRMethod "LB_2", "AddString", tmp
call stream ConfigFile, 'c', 'close'
return

/*:VRX         PB_14_Click
*/
PB_14_Click: procedure expose Globals.
status = VRMethod( "LB_3", "GetSelectedStringList", "selects." )
if selects.0<1 then return
do i=1 to selects.0
 call VRMethod "LB_3", "DeleteString", selects.i
end
call VRMethod "LB_3", "GetStringList", "strings."
ConfigFile=Globals.!WorkingDir||"\WebManager.cli"
call stream ConfigFile, 'c', 'close'
call VRDeleteFile(ConfigFile)
call stream ConfigFile, 'c', 'open'
Globals.!AccessCli.0=strings.0
do i=1 to strings.0
 Globals.!AccessCli.i=strings.i
 call lineout ConfigFile, strings.i
end
call stream ConfigFile, 'c', 'close'
return

/*:VRX         PB_15_Click
*/
PB_15_Click: procedure expose Globals.
tmp = ""
button.0 = 2
button.1 = "Add"
button.2 = "Cancel"
call VRPrompt VRWindow(), "Please enter IP address:", ,
              "tmp", "Add allowed IP", "button.", 1, 2
if result = 2 | tmp = "" then return
pos = VRMethod( "LB_3", "FindString", tmp,, "Exact" )
if pos<>0 then do
 call VRMessage VRWindow(),"IP already exists!","Error","E"
 return
end
rc = SockGetHostByName(tmp,"host.!")
if (rc <> 0) then tmp = host.!addr
ConfigFile=Globals.!WorkingDir||"\WebManager.cli"
call lineout ConfigFile, tmp
i=Globals.!AccessCli.0+1
Globals.!AccessCli.i=tmp
Globals.!AccessCli.0=i
call VRMethod "LB_3", "AddString", tmp
call stream ConfigFile, 'c', 'close'
return

/*:VRX         PB_16_Click
*/
PB_16_Click: procedure expose Globals.
status = VRMethod( "LB_5", "GetSelectedStringList", "selects." )
if selects.0<1 then return
do i=1 to selects.0
 call VRMethod "LB_5", "DeleteString", selects.i
end
call VRMethod "LB_5", "GetStringList", "strings."
ConfigFile=Globals.!WorkingDir||"\WebManager.new"
call stream ConfigFile, 'c', 'close'
call VRDeleteFile(ConfigFile)
call stream ConfigFile, 'c', 'open write'
do i=1 to strings.0
 call lineout ConfigFile, strings.i
end
return

/*:VRX         PB_17_Click
*/
PB_17_Click: procedure expose Globals.
tmp=""
button.0=2
button.1="Add"
button.2="Cancel"
call VRPrompt VRWindow(),"Please enter user ID:","tmp","Add banned user","button.",1,2
if result=2|tmp="" then return
pos=VRMethod("LB_6","FindString",tmp,,"Exact")
if pos<>0 then do
 call VRMessage VRWindow(),"User already exists!","Error","E"
 return
end
ConfigFile=Globals.!WorkingDir||"\WebManager.blk"
call lineout ConfigFile,tmp
i=Globals.!AccessBan.0+1
Globals.!AccessBan.i=tmp
Globals.!AccessBan.0=i
call VRMethod "LB_6","AddString",tmp
call stream ConfigFile,'c','close'
return

/*:VRX         PB_18_Click
*/
PB_18_Click: procedure expose Globals.
status = VRMethod( "LB_6", "GetSelectedStringList", "selects." )
if selects.0<1 then return
do i=1 to selects.0
 call VRMethod "LB_6", "DeleteString", selects.i
end
call VRMethod "LB_6", "GetStringList", "strings."
ConfigFile=Globals.!WorkingDir||"\WebManager.blk"
call stream ConfigFile, 'c', 'close'
call VRDeleteFile(ConfigFile)
call stream ConfigFile, 'c', 'open'
Globals.!AccessBan.0=strings.0
do i=1 to strings.0
 Globals.!AccessBan.i=strings.i
 call lineout ConfigFile, strings.i
end
call stream ConfigFile, 'c', 'close'
return

/*:VRX         PB_19_Click
*/
PB_19_Click: procedure expose Globals.
tmp=""
button.0=2
button.1="Add"
button.2="Cancel"
call VRPrompt VRWindow(),"Please enter a domain:","tmp","Add domain","button.",1,2
if result=2|tmp="" then return
pos=VRMethod("LB_7","FindString",tmp,,"Exact")
if pos<>0 then do
 call VRMessage VRWindow(),"Domain already exists!","Error","E"
 return
end
ConfigFile=Globals.!WorkingDir||"\WebManager.dom"
call lineout ConfigFile,tmp
i=Globals.!AccessDom.0+1
Globals.!AccessDom.i=tmp
Globals.!AccessDom.0=i
call VRMethod "LB_7","AddString",tmp
call stream ConfigFile,'c','close'
return

/*:VRX         PB_1_Click
*/
PB_1_Click: procedure expose selects. i
user=VRGet("EF_13","Value")
fullname=VRGet("EF_14","Value")
pazz=VRGet("EF_15","Value")
if pazz="" then do
 call VRMessage VRWindow(),"Password field is empty!","Error","E"
 return
end
call VRMethod "LB_1","DeleteString",selects.i
call VRMethod "LB_1","AddString",user||":"||pazz||":"||fullname||":"
call UserChange_Fini
return

/*:VRX         PB_20_Click
*/
PB_20_Click: procedure expose Globals.
status = VRMethod( "LB_7", "GetSelectedStringList", "selects." )
if selects.0<1 then return
do i=1 to selects.0
 call VRMethod "LB_7", "DeleteString", selects.i
end
call VRMethod "LB_7", "GetStringList", "strings."
ConfigFile=Globals.!WorkingDir||"\WebManager.dom"
call stream ConfigFile, 'c', 'close'
call VRDeleteFile(ConfigFile)
call stream ConfigFile, 'c', 'open'
Globals.!AccessDom.0=strings.0
do i=1 to strings.0
 Globals.!AccessDom.i=strings.i
 call lineout ConfigFile, strings.i
end
call stream ConfigFile, 'c', 'close'
return

/*:VRX         PB_21_Click
*/
PB_21_Click: procedure
call VRMethod "LB_8","GetSelectedList","indices."
if indices.0>0 then call VRMethod "LB_8","DeleteList","indices."
return

/*:VRX         PB_22_Click
*/
PB_22_Click: procedure
call InetMailProSettings_Fini
return

/*:VRX         PB_24_Click
*/
PB_24_Click: 
call VRMethod "LB_8","GetStringList","Globals.!IMPDomains."
call VRMethod "LB_8","GetItemDataList","Globals.!IMPPaths."
tmp=""
do i=1 to Globals.!IMPDomains.0
 tmp=tmp||Globals.!IMPDomains.i||'01'x
end
call VRSetIni Globals.!Program,"IMPDomains",tmp,Globals.!IniFile,"NoClose"
tmp=""
do i=1 to Globals.!IMPPaths.0
 tmp=tmp||Globals.!IMPPaths.i||'01'x
end
call VRSetIni Globals.!Program,"IMPPaths",tmp,Globals.!IniFile,"NoClose"
call InetMailProSettings_Fini
return

/*:VRX         PB_2_Click
*/
PB_2_Click: procedure
call UserChange_Fini
return

/*:VRX         PB_4_Click
*/
PB_4_Click: procedure expose Globals.
if VRGet("DDCB_1","Selected")=9&VRGet("CB_6","Set")=0 then do
 call VRMessage VRWindow(),"Weasel Pro requires the Full Email feature to be enabled.","Error","E"
 return
end
if VRGet("DDCB_1","Selected")<>9&VRGet("DDCB_1","Selected")<>6&VRGet("CB_6","Set")=1 then call VRSet "CB_6","Set",0
call VRSet "DT_19","Visible",1
Globals.!IP=VRGet("EF_12","Value")
Globals.!Port=VRGet("EF_4","Value")
Globals.!PasswordTimeout=VRGet("EF_2","Value")
Globals.!Timer=VRGet("EF_3","Value")
Globals.!StartMin=VRGet("CB_1","Set")
Globals.!POP3=VRGet("EF_5","Value")
Globals.!POP3P=VRGet("EF_8","Value")
Globals.!SMTP=VRGet("EF_6","Value")
Globals.!SMTPP=VRGet("EF_7","Value")
Globals.!UserPath=VRGet("EF_1","Value")
Globals.!Ignored=VRGet("CB_5","Set")
Globals.!FullEmail=VRGet("CB_6","Set")
call VRSetIni Globals.!Program,"IP",Globals.!IP,Globals.!IniFile,"NoClose"
call VRSetIni Globals.!Program,"Port",Globals.!Port,Globals.!IniFile,"NoClose"
call VRSetIni Globals.!Program,"PasswordTimeout",Globals.!PasswordTimeout,Globals.!IniFile,"NoClose"
call VRSetIni Globals.!Program,"Timer",Globals.!Timer,Globals.!IniFile,"NoClose"
call VRSetIni Globals.!Program,"StartMin",Globals.!StartMin,Globals.!IniFile,"NoClose"
call VRSetIni Globals.!Program,"POP3",Globals.!POP3,Globals.!IniFile,"NoClose"
call VRSetIni Globals.!Program,"POP3P",Globals.!POP3P,Globals.!IniFile,"NoClose"
call VRSetIni Globals.!Program,"SMTP",Globals.!SMTP,Globals.!IniFile,"NoClose"
call VRSetIni Globals.!Program,"SMTPP",Globals.!SMTPP,Globals.!IniFile,"NoClose"
call VRSetIni Globals.!Program,"UserPath",Globals.!UserPath,Globals.!IniFile,"NoClose"
call VRSetIni Globals.!Program,"Ignored",Globals.!Ignored,Globals.!IniFile,"NoClose"
call VRSetIni Globals.!Program,"FullEmail",Globals.!FullEmail,Globals.!IniFile,"NoClose"
Globals.!Users.0=0
if VRGet("DDCB_1","Selected")=1 then do
 Globals.!UserDataBase=1
 call LoadUsers_Internal
end; else Globals.!UserDataBase=VRGet("DDCB_1","Selected")
call VRSetIni Globals.!Program, "UserDataBase", Globals.!UserDataBase, Globals.!IniFile, "NoClose"
if Globals.!UserDataBase=1|Globals.!UserDataBase=2|Globals.!UserDataBase=3|Globals.!UserDataBase=4|Globals.!UserDataBase=7|Globals.!UserDataBase=9 then do
 call VRSet "DT_7", "Enabled", 1
 call VRSet "EF_3", "Enabled", 1
 call VRSet "DT_8", "Enabled", 1
end; else do
 call VRSet "DT_7", "Enabled", 0
 call VRSet "EF_3", "Enabled", 0
 call VRSet "DT_8", "Enabled", 0
end
if VRGet("CB_2","Set")=1 then do
 if VRGet("EF_9","Value")="" | VRGet("EF_10","Value")="" then do
  call VRMessage VRWindow(), "Alert Program has incorrect values!","Error","E" 
  return
 end
end
Globals.!AlertP=VRGet("CB_2","Set")
Globals.!AlertF=VRGet("EF_9","Value")
Globals.!AlertR=VRGet("EF_10","Value")
Globals.!UseLogFile=VRGet("CB_7","Set")
Globals.!LogFile=VRGet("EF_21","Value")
if Globals.!UserDataBase=5 then call VRSet "CB_3","Set",0
Globals.!NewUsers = VRGet("CB_3","Set")
Globals.!NewUsersNot = VRGet("EF_16","Value")
Globals.!NewUsersAuto = VRGet("CB_4","Set")
call VRSetIni Globals.!Program, "AlertP", Globals.!AlertP, Globals.!IniFile, "NoClose"
call VRSetIni Globals.!Program, "AlertF", Globals.!AlertF, Globals.!IniFile, "NoClose"
call VRSetIni Globals.!Program, "AlertR", Globals.!AlertR, Globals.!IniFile, "NoClose"
call VRSetIni Globals.!Program, "UseLogFile", Globals.!UseLogFile, Globals.!IniFile, "NoClose"
call VRSetIni Globals.!Program, "LogFile", Globals.!LogFile, Globals.!IniFile, "NoClose"
call VRSetIni Globals.!Program, "NewUsers", Globals.!NewUsers, Globals.!IniFile, "NoClose"
call VRSetIni Globals.!Program, "NewUsersNot", Globals.!NewUsersNot, Globals.!IniFile, "NoClose"
call VRSetIni Globals.!Program, "NewUsersAuto", Globals.!NewUsersAuto, Globals.!IniFile, "NoClose"
return

/*:VRX         PB_5_Click
*/
PB_5_Click: procedure expose Globals.
call VRLoadSecondary "InetMailProSettings", "Wait"
return

/*:VRX         PB_6_Click
*/
PB_6_Click: procedure expose Globals.
tmp=""
button.0=2
button.1="OK"
button.2="Cancel"
call VRPrompt VRWindow(),"Please enter user full name (can be empty):","fullname","Add user","button.",1,2
if result=2 then return
call VRPrompt VRWindow(),"Please enter user email ID:","user","Add user","button.",1,2
if result=2|user="" then return
do i=1 to Globals.!Users.0
 parse value Globals.!Users.i with tmp1 ":" tmp2 ":"
 if translate(tmp1)=translate(user) then do
  call VRMessage VRWindow(),"User already exists!","Error","E"
  return
 end
end
call VRPrompt VRWindow(),"Please enter password:","pazz","Add user","button.",1,2
if result=2|pazz="" then return
ConfigFile=Globals.!WorkingDir||"\WebManager.usr"
call lineout ConfigFile,user||":"||pazz||":"||fullname||":"
i=Globals.!Users.0+1
Globals.!Users.i=user||":"||pazz||":"||fullname||":"
Globals.!Users.0=i
call VRMethod "LB_1", "AddString", user||":"||pazz||":"||fullname||":"
call LoadUsers_Internal
return

/*:VRX         PB_7_Click
*/
PB_7_Click: procedure expose Globals.
status = VRMethod( "LB_1", "GetSelectedStringList", "selects." )
if selects.0<1 then return
do i=1 to selects.0
 call VRMethod "LB_1", "DeleteString", selects.i
end
call VRMethod "LB_1", "GetStringList", "strings."
ConfigFile=Globals.!WorkingDir||"\WebManager.usr"
call stream ConfigFile, 'c', 'close'
call VRDeleteFile(ConfigFile)
call stream ConfigFile, 'c', 'open write'
Globals.!Users.0=strings.0
do i=1 to strings.0
 Globals.!Users.i=strings.i
 call lineout ConfigFile, strings.i
end
call LoadUsers_Internal
return

/*:VRX         PB_8_Click
*/
PB_8_Click: procedure expose Globals.
status=VRMethod("LB_1","GetSelectedStringList","selects.")
if selects.0<1 then return
do i=1 to selects.0
 call VRLoadSecondary "UserChange", "Wait"
end
call VRMethod "LB_1","GetStringList","strings."
ConfigFile=Globals.!WorkingDir||"\WebManager.usr"
call stream ConfigFile,'c','close'
call VRDeleteFile(ConfigFile)
call stream ConfigFile,'c','open'
Globals.!Users.0=strings.0
do z=1 to strings.0
 Globals.!Users.z=strings.z
 call lineout ConfigFile,strings.z
end
call LoadUsers_Internal
return

/*:VRX         PB_9_Click
*/
PB_9_Click: procedure expose Globals.
if VRGet("EF_18","Value")=""|VRGet("EF_17","Value")=""|VRGet("EF_19","Value")="" then return
if stream(VRGet("EF_17","Value"),'c','query exists')="" then do
 call VRMessage "InetMailProSettings","Password file not found.","ERROR","E"
 return
end
if VRMethod("LB_8","FindString",VRGet("EF_18","Value"))<>0 then do
 call VRMessage "InetMailProSettings","Domain already exists.","ERROR","E"
 return
end
if pos('01'x,VRGet("EF_18","Value"))>0|pos('01'x,VRGet("EF_17","Value"))>0|pos('01'x,VRGet("EF_19","Value"))>0|pos('01'x,VRGet("EF_20","Value"))>0 then do
 call VRMessage "InetMailProSettings","Invalid characters detected.","ERROR","E"
 return
end
if pos('02'x,VRGet("EF_18","Value"))>0|pos('02'x,VRGet("EF_17","Value"))>0|pos('02'x,VRGet("EF_19","Value"))>0|pos('02'x,VRGet("EF_20","Value"))>0 then do
 call VRMessage "InetMailProSettings","Invalid characters detected.","ERROR","E"
 return
end
if pos('03'x,VRGet("EF_18","Value"))>0|pos('03'x,VRGet("EF_17","Value"))>0|pos('03'x,VRGet("EF_19","Value"))>0|pos('03'x,VRGet("EF_20","Value"))>0 then do
 call VRMessage "InetMailProSettings","Invalid characters detected.","ERROR","E"
 return
end
call VRMethod "LB_8","AddString",VRGet("EF_18","Value"),,VRGet("EF_17","Value")||'02'x||VRGet("EF_19","Value")||'03'x||VRGet("EF_20","Value")
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
 call VRSetIni Globals.!Program, "LeftSetup", left, Globals.!IniFile, "NoClose"
 call VRSetIni Globals.!Program, "TopSetup", top, Globals.!IniFile, "NoClose"
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

/*:VRX         UserChange_Close
*/
UserChange_Close: procedure
call UserChange_Fini
return

/*:VRX         UserChange_Create
*/
UserChange_Create: procedure expose selects. i
parse value selects.i with user ":" pazz ":" fullname ":"
call VRSet "EF_13","Value",user
call VRSet "EF_14","Value",fullname
call VRSet "EF_15","Value",pazz
call UserChange_Init
return

/*:VRX         UserChange_Fini
*/
UserChange_Fini: 
window=VRInfo("Window")
call VRDestroy window
drop window
return
/*:VRX         UserChange_Init
*/
UserChange_Init: 
    window = VRInfo( "Object" )
    if( \VRIsChildOf( window, "Notebook" ) ) then do
        call VRMethod window, "CenterWindow"
        call VRSet window, "Visible", 1
        call VRMethod window, "Activate"
    end
    drop window
return

/*:VRX         Window1_Close
*/
Window1_Close:
call Quit
return

/*:VRX         Window1_Create
*/
Window1_Create: procedure expose Globals.
call VRSet "Window1","Caption","WebMail/2 - Setup - Initializing..."
/* create window structure */
field=VRMethod("CN_1","AddField","String","Name")
record=VRMethod("CN_1","AddRecord","","First","Users",,,)
record=VRMethod("CN_1","AddRecord","","","Settings",,,)
call VRMethod "CN_1","SetRecordAttr",record,"Selected",1
call VRMethod "CN_1","AddRecord",record,"","Settings 2"
record=VRMethod("CN_1","AddRecord","","","Access",,,)
call VRMethod "CN_1","AddRecord",record,"","Access 2"

/* Display values in GUI controls */
call VRSet "EF_12","Value",Globals.!IP
call VRSet "EF_4","Value",Globals.!Port
call VRSet "EF_2","Value",Globals.!PasswordTimeout
call VRSet "EF_3","Value",Globals.!Timer
call VRSet "CB_1","Set",Globals.!StartMin
call VRSet "EF_5","Value",Globals.!POP3
call VRSet "EF_8","Value",Globals.!POP3P
call VRSet "EF_6","Value",Globals.!SMTP
call VRSet "EF_7","Value",Globals.!SMTPP
call VRSet "EF_1","Value",Globals.!UserPath
call VRSet "CB_5","Set",Globals.!Ignored
call VRSet "CB_6","Set",Globals.!FullEmail
call VRSet "CB_2","Set",Globals.!AlertP
call VRSet "EF_9","Value",Globals.!AlertF
call VRSet "EF_10","Value",Globals.!AlertR
call CB_2_Click
call VRSet "CB_7","Set",Globals.!UseLogFile
call VRSet "EF_21","Value",Globals.!LogFile
call CB_7_Click
call VRSet "CB_3","Set",Globals.!NewUsers
call VRSet "EF_16","Value",Globals.!NewUsersNot
call VRSet "CB_4","Set",Globals.!NewUsersAuto
call CB_3_Click

/* load users from the selected usersdatabase */
if Globals.!UserDataBase=1 then do
 call VRSet "DDCB_1","Selected",1
 call LoadUsers_Internal
end; else call VRSet "DDCB_1","Selected",Globals.!UserDataBase

/* Load old new users */
ConfigFile=Globals.!WorkingDir||"\WebManager.new"
i=stream(ConfigFile,'c','open')
if pos("NOTREADY",i)<1 then do
 do while lines(ConfigFile)>0
  tmp=linein(ConfigFile)
  if substr(tmp,1,1)<>"#" & tmp<>"" & tmp<>'0d0a'x then call VRMethod "LB_5","AddString",space(tmp)
 end
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
if Globals.!Access.0>0 then call VRMethod "LB_2","AddStringList","Globals.!Access."

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
if Globals.!AccessCli.0>0 then call VRMethod "LB_3","AddStringList","Globals.!AccessCli."

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
if Globals.!AccessBan.0>0 then call VRMethod "LB_6","AddStringList","Globals.!AccessBan."

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
if Globals.!AccessDom.0>0 then call VRMethod "LB_7","AddStringList","Globals.!AccessDom."

/* Misc */
if Globals.!UserDataBase=1|Globals.!UserDataBase=2|Globals.!UserDataBase=3|Globals.!UserDataBase=4|Globals.!UserDataBase=7|Globals.!UserDataBase=9 then do
 call VRSet "DT_7","Enabled",1
 call VRSet "EF_3","Enabled",1
 call VRSet "DT_8","Enabled",1
end
/* Make sure the database directory exists */
if VRIsDir(Globals.!WorkingDir||"\database")=0 then call VRMkDir Globals.!WorkingDir||"\database"

/* end init */
call VRSet "Window1","Caption","WebMail/2 - Setup"
return

