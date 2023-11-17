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
; 13300.menu-format-mainos.bas - menu: write new main o.s.
;

; Check system files...
13300 gosub54800:ifec>0thengoto13390

; Write new main o.s.
; Note: Use device address 'dd' to set the current device 'dv'!
;       'dd' is always the last selected CMD-HD.
13305 printtt$:print"  write new main o.s.:{down}"

; Print device info
13310 dv=dd:gosub13900

; Find system area, do not check for system o.s.
13311 es=0:ifso<0thengosub51410:ifes>0thengoto13490

; Print warning
13320 gosub13930

; Print options
13321 gosub13950

13330 getk$:ifk$=""thengoto13330
13331 if(k$="s")or(k$="S")thengosub11000:goto13300
13332 if(k$="y")or(k$="Y")thengoto13340
13333 if(k$="n")or(k$="N")thenes=2:goto13390
13334 goto13330

; Write new main o.s.
13340 gosub55400
13390 return
