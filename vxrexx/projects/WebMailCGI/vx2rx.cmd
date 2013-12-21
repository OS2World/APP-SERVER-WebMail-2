/* vx2rx.cmd - VX-REXX to Classic Rexx - by sehh */

Globals.!input="webmail2.vrx"
Globals.!output="c:\tcpip\web2\cgi-bin\webmail2.cmd"

call RxFuncAdd 'SysLoadFuncs','RexxUtil','SysLoadFuncs'
call SysLoadFuncs

Globals.!inputsize=stream(Globals.!input,'c','query size')
call stream Globals.!input,'c','open read'
i=0
inputdata.0=0
do while lines(Globals.!input)>0
 i=i+1
 inputdata.i=linein(Globals.!input)
end
inputdata.0=i
'@erase '||Globals.!output||' >nul 2>nul'
do i=1 to inputdata.0
 if pos("Main:",inputdata.i)=1 then iterate
 if pos("/*:VRX",inputdata.i)=1 then i=i+1
 else call lineout Globals.!output,inputdata.i
end
