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
; 51800.wait-config.bas - wait until scsi-controller is ready
;
; parameter: -
; return   : -
; temporary: -
;

; Wait a few seconds to let the scsi-controller finish job after reset
51800 pokets,0
51810 ifpeek(ts)<120thengoto51810
51890 return
