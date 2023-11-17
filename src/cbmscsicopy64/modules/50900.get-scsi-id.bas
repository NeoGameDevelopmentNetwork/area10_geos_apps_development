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
; 50900.get-scsi-id.bas - get active scsi id
;
; parameter: dv    = cmd-hd device address
; return   : sd    = cmd-hd scsi device id
; temporary: a$,a
;

; Get active SCSI-ID
50900 open15,dv,15

; Read address $9000 = SCSI-ID/LUN as high/low nibble
50910 print#15,"m-r"chr$(0)chr$(144)chr$(1)
50920 get#15,a$:a=asc(a$+nu$)/2/2/2/2
50930 sd=0:if(a>0)and(a<7)thensd=a

; Close command channel
50940 close15
50990 return
