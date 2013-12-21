/*:VRX         Main
*/
Main:
signal on halt
s=SockSocket("AF_INET","SOCK_STREAM",0)
if s=-1 then call VRMessage VRWindow(),"Socket error!","Error","E"
call SockSetSockOpt s,"SOL_SOCKET","SO_RCVTIMEO",10
call SockSetSockOpt s,"SOL_SOCKET","SO_SNDTIMEO",10
call SockSetSockOpt s,"SOL_SOCKET","SO_REUSEADDR",1
server.!family="AF_INET"
server.!port=arg(1)
if arg(2)<>"" | arg(2)<>"0.0.0.0" then server.!addr=arg(2)
else server.!addr="INADDR_ANY"
rc=SockBind(s,"server.!")
if rc=-1 then call VRMessage VRWindow(),"Can't bind to socket!","Error","E"
rc=SockListen(s,500)
if rc=-1 then call VRMessage VRWindow(),"Can't listen to socket!","Error","E"
do forever
 ns=SockAccept(s,"client.!")
 call VRMethod "Application","StartThread","Daemon",server.!port||":"||ns||":"||client.!addr
end
exit

/*:VRX         Halt
*/
Halt:
call SockSoClose ns
exit

