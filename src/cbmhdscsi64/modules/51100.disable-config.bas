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
; 51100.disable-config.bas - disable configuration mode
;
; parameter: dv    = cmd-hd device address
; return   : -
; temporary: he$
;

; Disable configuration mode

; Job-code for "Disable config-mode/controller reset"
51100 cj$="14":gosub51900

; Wait for controller reset and exit
51120 gosub51800:return
