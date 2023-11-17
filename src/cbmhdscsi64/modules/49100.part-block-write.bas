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
; 49100.part-block-write.bas - Write a block of the partition table from SCSI data buffer to disk
;
; parameter: dv    = cmd-hd device address
;            sd    = cmd-hd scsi device id
;            so    = system area offset
;            pn    = partition number
; return   : es    = error status
; temporary: ba,bh,bm,bl,wh,wm,wl
;

; Write a block of the partition table from SCSI data buffer to disk

; Find system area
49100 es=0:ifso<0thengosub51400:ifes>0thengoto49190

; Set base address for partition table
49110 ba=so+128+int(pn/16)

; Convert LBA to h/m/l
49120 gosub58900:wh=bh:wm=bm:wl=bl

; Write block to disk
49130 open15,dv,15:gosub58300:close15

; All done
49190 return
