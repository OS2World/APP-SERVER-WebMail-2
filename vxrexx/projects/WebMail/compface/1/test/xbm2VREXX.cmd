/*
 *  xbm2VREXX.cmd  ---  Display 48*48 XBM in VREXX Window
 *
 *         Copyright (C) 1997,1998  OKUNISHI Fujikazu
 *
 * Author:  OKUNISHI Fujikazu <fuji0924@mbox.kyoto-inet.or.jp>
 * Created: Jul 30, 1997
 * Revised: Feb  1, 1998
 *
 * how2use:
 *  ex.)
 *   1.  xface.cmd +x-face/6 | xbm2VREXX.cmd [RET]
 *   2a. xbm2VREXX.cmd foo.xbm [RET]
 *   2b. xbm2VREXX.cmd < foo.xbm [RET]
 */

  Parse Arg IN .

  Call INIT
  Call PARSE_XBM
  Call DRAW_PIXEL
  Call CLEAN
Exit


INIT:
  If IN='' Then Do; If Lines()==0 Then Exit 255; IN='STDIN'; End
           Else If Stream(IN,'C','Query Exist') ='' Then Exit 255
  str=''

  If RxFuncQuery('VInit') Then
    Call RxFuncAdd 'VInit', 'VREXX', 'VINIT'
  If VInit() =='ERROR' then Do; Call VExit; Exit 999; End

  /* VREXX variables */
  pos.left   = 0
  pos.bottom = 0
  pos.right  = 100
  pos.top    = 100
  msg.0 = 1
  msg.1 = 'Press OK to close the windows'
Return


PARSE_XBM:
  Do i=1 By 1 While Lines(IN)
    str.i= Linein(IN)
    If Left(Word(str.i, 1), 2)<>'0x' Then Iterate
    Do Until Length(str.i)==0
      Parse Var str.i '0x' strA.i ',' str.i
      strA.i =Substr(strA.i, 1, 2)
      If Datatype(strA.i, 'X') <>1 Then Leave
      strA.i = B2X(Reverse(X2b(strA.i)))
      str = str strA.i
    End
  End
  j=1
  Do i=48 By -1 While Length(str)>0
    Parse Var str str1.i str2.i str3.i str4.i str5.i str6.i str
    line.i= X2B(str1.i||str2.i||str3.i||str4.i||str5.i||str6.i)
  /*Say Line.i*/
    Do k=1 To Length(line.i)
      y.j=i
      x.j=Substr(line.i, k, 1)
      If x.j Then x.j=k
        Else Do; Drop y.j;Drop x.j; Iterate; End
      j=j+1
    End
  End
  j=j-1
Return


DRAW_PIXEL:  /* Drawing */
  id = VOpenWindow('X-Face Graphics Window', 'WHITE', pos)
/*Call VForeColor id, 'BLUE'*/
  Call VDraw id, 'PIXEL', x, y, j
  Call VMsgBox 'XBM2VREXX', msg, 1
  Call VCloseWindow id
Return


CLEAN:
SYNTAX:
HALT:
FAILURE:
  rb=VExit()
Return

/* end of procedure */
