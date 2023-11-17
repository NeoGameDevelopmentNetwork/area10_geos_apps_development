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
; 58950.convert-hml-2-lba.bas - convert h/m/l to lba
;
; parameter: bh    = lba high-byte
;            bm    = lba medium-byte
;            bl    = lba low-byte
; return   : ba    = scsi lba address
; temporary: -
;

; Convert h/m/l to lba
58950 ba=bh*65536+bm*256+bl
58990 return
