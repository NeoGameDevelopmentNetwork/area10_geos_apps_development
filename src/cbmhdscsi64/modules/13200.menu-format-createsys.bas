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
; 13200.menu-format-createsys.bas - menu: create system area
;

; Check system files...
13200 gosub54800:ifec>0thengoto13290

; Create system area
; Note: Use device address 'dd' to set the current device 'dv'!
;       'dd' is always the last selected CMD-HD.
13205 printtt$:print"  create new system area:{down}"

; Print device info
13210 dv=dd:gosub13900

; Print warning
13220 gosub13920

; Print options
13221 gosub13950

13230 getk$:ifk$=""thengoto13230
13231 if(k$="s")or(k$="S")thengosub11000:goto13200
13232 if(k$="y")or(k$="Y")thengoto13240
13233 if(k$="n")or(k$="N")thenes=2:goto13290
13234 goto13230

; Ceate system area
13240 gosub54000
13290 return
