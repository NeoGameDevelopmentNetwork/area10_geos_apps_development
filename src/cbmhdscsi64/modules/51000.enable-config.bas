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
; 51000.enable-config.bas - enable configuration mode
;
; parameter: dv    = cmd-hd device address
; return   : -
; temporary: he$
;

; Enable configuration mode

; Job-code for "Enable config-mode"
51000 cj$="06":gosub51900
51090 return
