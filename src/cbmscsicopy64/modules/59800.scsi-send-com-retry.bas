; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; cbmSCSIcopy64
;
; 59800.scsi-send-com-retry.bas - send "s-c" command to cmd-hd
;
; parameter: sd    = cmd-hd scsi device id
;            sl/sh = cmd-hd scsi data-out buffer
;            sc$   = scsi command bytes
; return   : es    = error status
; temporary: ec,a$
;

; Send SCSI command, retry on error
59800 ec=2
59810 gosub59900:get#15,a$:es=asc(a$+nu$)
59820 ifes>0thenec=ec-1:ifec>0thengoto59810
59890 return
