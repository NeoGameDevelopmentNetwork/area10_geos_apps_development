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
; 58900.convert-lba-2-hml.bas - convert lba to h/m/l
;
; parameter: ba    = scsi block address
; return   : bh    = lba high-byte
;            bm    = lba medium-byte
;            bl    = lba low-byte
; temporary: -
;

; Convert lba to h/m/l
58900 bh=int(ba/65536)
58901 bm=int((ba-bh*65536)/256)
58902 bl=ba-bh*65536-bm*256
58940 return
