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
; 10100.menu-slctsysdev.bas - select system files device
;

; Select system files device
10100 printtt$
10110 printleft$(po$,5)
10111 print"  must be a device between 8 and 29."
10112 print"  enter '0' to return to menu."
10113 printleft$(po$,4)

10120 print"{up}";sl$
10121 input"{up}  enter device address";ga
10123 ifga=0thengoto10190

10130 if(ga<8)or(ga>29)or(ga=dd)thenga=0:goto10120
10131 open15,ga,15:close15
10132 ifst<>0thengoto10121

10190 return
