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
; 58800.data512-clear.bas - clear 512-byte data buffer
;
; parameter: bu(x) = 512 data bytes
; return   : -
; temporary: i
;

; Clear 512-byte data buffer
58800 fori=0to511:bu(i)=0:next:return
