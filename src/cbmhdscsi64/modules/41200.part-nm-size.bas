; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; cbmHDscsi64
;
; 41200.part-nm-size.bas - set partition size for native/foreign mode
;
; parameter: br    = remaining 512-byte blocks
; return   : pr    = size of partition in 512-byte blocks
;                    0 = return to menu
; temporary: kb$,px
;

; Set partition size for native/foreign mode
41200 printtt$
41201 print"  create new ";pt$;"-mode partition{down}"
41202 print"  free blocks remaining:";br*2

41210 printleft$(po$,13);
41211 print"  press +/-/* to change partiton size,"
41212 print"  press <x> to go back to menu or"
; "Press <return> to continue."
41213 gosub9010

; Set default partition size.
41220 pr=1024
; Set max. partition size.
41221 px=32640:ifpt=7thenpx=32768

; Pront current partition size
41230 printleft$(po$,9);
41231 print"  new partition size:";pr*2;"{left} blocks   "
41232 print"  ( about";pr*512/1024;"{left} kb )    "

; Wait for a key
41240 getkb$:ifkb$=""thengoto41240

; Change partition size
41250 ifkb$="+"thenpr=pr+128:ifpr>pxthenpr=128
41251 ifkb$="-"thenpr=pr-128:ifpr<128thenpr=px
41252 ifkb$="*"thenpr=pr+1024:ifpr>pxthenpr=128

; Test if partition size > remaining blocks
41260 ifpr>brthenpr=br

; Cancel/continue?
41270 ifkb$="x"thenpr=0:goto41290
41280 ifkb$<>chr$(13)thengoto41230

; All done
41290 return
