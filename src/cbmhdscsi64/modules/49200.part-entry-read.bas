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
; 49200.part-entry-read.bas - read single partition entry from disk into block buffer
;
; parameter: dv    = cmd-hd device address
;            sd    = cmd-hd scsi device id
;            so    = system area offset
;            pn    = partition number
; return   : es    = error status
; temporary: ba,bh,bm,bl,rh,rm,rl,ip
;

; Read single partition entry from disk into block buffer

; Read a block of the partition table from disk into SCSI data buffer
49200 gosub49000:ifes>0thengoto49290

; Set position to partition entry
49210 ip=(pn and 15)*32

; Read partition data
49220 open15,dv,15:gosub58400:close15

; All done
49290 return
