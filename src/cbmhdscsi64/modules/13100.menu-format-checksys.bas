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
; 13100.menu-format-checksys.bas - menu: check system area
;

; Currently not used in this project
;
; ; Check system area
; ; Note: Use device address 'dd' to set the current device 'dv'!
; ;       'dd' is always the last selected CMD-HD.
; 13100 printtt$:print"  checking system area:{down}"
;
; ; Find system area
; 13120 dv=dd:gosub51400:ifes>0thengoto13190
;
; ; Wait for return
; 13140 gosub60400
; 13190 return
