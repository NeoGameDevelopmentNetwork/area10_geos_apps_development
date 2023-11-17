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
; 59000.___scsi-commands.bas - various scsi commands
;

; CMD-HD SCSI command / Binary format
; Parameter: sd    = cmd-hd scsi device id
;            sl/sh = cmd-hd scsi data-out buffer
;            sc$   = scsi command bytes
;
