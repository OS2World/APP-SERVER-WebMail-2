/* make.cmd */
if ARG(1)="" then exit
ver=substr(arg(1),2)
fileid="-==== WebMail/2 beta "||ver||" ====-"||'0d0a'x
fileid=fileid||"Allows users to read their"||'0d0a'x
fileid=fileid||"email via a web browser."||'0d0a'x
fileid=fileid||"Supports 3rd party programs"||'0d0a'x
fileid=fileid||"like Weasel, IPS, Inet.Mail"||'0d0a'x
fileid=fileid||"Inet.MailPro, OS2PopS, ZxMail,"||'0d0a'x
fileid=fileid||"and generic POP3 servers."||'0d0a'x
fileid=fileid||"-============================-"||'0d0a'x
path = "c:\utils\vxrexx\projects\WebMail\distribution\"||ARG(1)
'@mkdir '||path
'@zip.exe -9j '||path||'\webmanager.zip c:\utils\vxrexx\projects\webmail\webmanager.exe'
'@zip.exe -9j '||path||'\webmanager.zip c:\utils\vxrexx\projects\webmail\setup\setup.exe'
'@zip.exe -9j '||path||'\webmailhtml.zip c:\mptn\etc\webmailhtml\*.wm'
'@zip.exe -9j '||path||'\cgi.zip c:\tcpip\web2\cgi-bin\webmail2.cmd'
'@zip.exe -9j '||path||'\cgi.zip c:\Utils\vxrexx\projects\WebMail\distribution\rexx2exe.exe'
'@zip.exe -9j '||path||'\webmailimages.zip c:\tcpip\web2\html\webmailimages\*.gif'
'@zip.exe -9j '||path||'\documentation.zip C:\Utils\vxrexx\projects\WebMail\documentation\*'
'@zip.exe -9j '||path||'\webmailhtml-metal.zip c:\mptn\etc\webmailhtml\metal\*.wm'
'@zip.exe -9j '||path||'\webmailimages-metal.zip c:\tcpip\web2\html\webmailimages\metal\*.png'
'@copy dll.zip '||path
'@copy install.cmd '||path
call charout path||'\file_id.diz',fileid
call stream path||'\file_id.diz','c','close'
'@copy read.me '||path
'@zip -9j '||path||'\webmail'||ARG(1)||'.zip '||ARG(1)||'\*'
