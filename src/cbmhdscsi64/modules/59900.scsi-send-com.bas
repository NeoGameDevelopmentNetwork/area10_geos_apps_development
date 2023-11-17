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
; 59900.scsi-send-com.bas - send "s-c" command to cmd-hd
;
; parameter: sd    = cmd-hd scsi device id
;            sl/sh = cmd-hd scsi data-out buffer
;            sc$   = scsi command bytes
; return   : -
; temporary: -
;

; Send "s-c" command to CMD-HD
59900 print#15,"s-c"chr$(sd)chr$(sl)chr$(sh)sc$:return
