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
; 13400.menu-format-clrpart.bas - menu: clear partition table
;

; Clear partition table
; Note: Use device address 'dd' to set the current device 'dv'!
;       'dd' is always the last selected CMD-HD.
13400 printtt$
; "Clear partition table:"
13401 gosub9500

; Print device info
13410 dv=dd:gosub13900

; Find system area
13411 es=0:ifso<0thengosub51400:ifes>0thengoto13490

; Print warning
13420 gosub13940

; Print options
13421 gosub13950

13430 getk$:ifk$=""thengoto13430
13431 if(k$="s")or(k$="S")thengosub11000:goto13400
13432 if(k$="y")or(k$="Y")thengoto13440
13433 if(k$="n")or(k$="N")thenes=2:goto13490
13434 goto13430

; Clear partition table
13440 printtt$
; "Clear partition table:"
13441 gosub9500

; Print device info
13450 gosub13900

; Clear partition table
13460 gosub54400

; All done!
13490 return
