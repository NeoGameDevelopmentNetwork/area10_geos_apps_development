; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; hdPartInit
;
; 38300.hdpart-nm-size.bas - set partition size for native/foreign mode
;
; parameter: br    = remaining 512-byte blocks
; return   : pr    = size of partition in 512-byte blocks
;                    0 = return to menu
; temporary: kb$,px
;

; Set partition size for native/foreign mode
38300 printtt$
38301 print"  create new ";pt$;"-mode partition{down}"
38302 print"  free blocks remaining: ";
38303 iftb>0thenprintbr*2
38304 iftb<=0thenprint"unknwon"

38310 printleft$(po$,13);
38311 print"  press +/-/* to change partiton size,"
38312 print"  press <x> to go back to menu or"
; "Press <return> to continue."
38313 gosub9010

; Set default partition size.
38320 pr=1024
; Set max. partition size.
38321 px=32640:ifpt=6orpt=7thenpx=32768

; Pront current partition size
38330 printleft$(po$,9);
38331 print"  new partition size:";pr*2;"{left} blocks   "
38332 print"  ( about";pr*512/1024;"{left} kb )    "

; Wait for a key
38340 getkb$:ifkb$=""thengoto38340

; Change partition size
38350 ifkb$="+"thenpr=pr+128:ifpr>pxthenpr=128
38351 ifkb$="-"thenpr=pr-128:ifpr<128thenpr=px
38352 ifkb$="*"thenpr=pr+1024:ifpr>pxthenpr=128

; Test if partition size > remaining blocks
38360 if(tb>0)and(pr>br)thenpr=br

; Cancel/continue?
38370 ifkb$="x"thenpr=0:goto38390
38380 ifkb$<>chr$(13)thengoto38330

; All done
38390 return
