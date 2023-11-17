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
; 49000.part-block-read.bas - read a block of the partition table from disk into SCSI data buffer
;
; parameter: dv    = cmd-hd device address
;            sd    = cmd-hd scsi device id
;            so    = system area offset
;            pn    = partition number
; return   : es    = error status
; temporary: ba,bh,bm,bl,rh,rm,rl
;

; Read a block of the partition table from disk into SCSI data buffer

; Find system area
49000 es=0:ifso<0thengosub51400:ifes>0thengoto49090

; Set base address to partition table
49005 ba=so+128+int(pn/16)

; Convert LBA to h/m/l
49010 gosub58900:rh=bh:rm=bm:rl=bl

; Read block from disk
49020 open15,dv,15:gosub58200:close15

; All done
49090 return
