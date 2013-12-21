/* make.cmd */
if arg(1)="" then exit
ver=arg(1)
ver1=substr(ver,1,pos(".",ver)-1)
fileid="-======== WebMail/2 v"||ver1||" =======-"||'0d0a'x
fileid=fileid||"Web to Email interface for your"||'0d0a'x
fileid=fileid||"existing email service. It uses"||'0d0a'x
fileid=fileid||"your existing POP3/SMTP to give"||'0d0a'x
fileid=fileid||"your users access from the web."||'0d0a'x
fileid=fileid||""||'0d0a'x
fileid=fileid||"Supports OS/2 email servers and"||'0d0a'x
fileid=fileid||"any POP3/SMTP service of any"||'0d0a'x
fileid=fileid||"platform. Runs under any OS/2"||'0d0a'x
fileid=fileid||"or Linux web server along with"||'0d0a'x
fileid=fileid||"an OS/2 management daemon."||'0d0a'x
fileid=fileid||""||'0d0a'x
fileid=fileid||"Supported under OS/2:"||'0d0a'x
fileid=fileid||"Weasel, WeaselPro, IPS, InetMail,"||'0d0a'x
fileid=fileid||"InetMailPro, OS2PopS, ZxMail, and"||'0d0a'x
fileid=fileid||"any generic pop3 and smtp server."||'0d0a'x
fileid=fileid||""||'0d0a'x
fileid=fileid||"Supported under UNIX systems:"||'0d0a'x
fileid=fileid||"A web server with CGI and Cookie"||'0d0a'x
fileid=fileid||"support. A Rexx interpreter with"||'0d0a'x
fileid=fileid||"rxsock and Base64/QuotedPrintable"||'0d0a'x
fileid=fileid||"libraries."||'0d0a'x
fileid=fileid||"-===============================-"||'0d0a'x
path = "c:\utils\vxrexx\projects\WebMail\distribution\"||ver
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
'@zip -9j '||path||'\webmail'||ver1||'.zip '||path||'\*'
rc=stream('hobbestemplate.txt','c','query size')
data=charin('hobbestemplate.txt',1,rc)
parse value data with tmp1 "::" . ";;" tmp2
call charout path||"\webmail"||ver1||".txt",tmp1||ver1||tmp2
