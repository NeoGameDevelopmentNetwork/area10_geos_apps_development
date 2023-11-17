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
; 49300.part-block-rdget.bas - read partition data from disk into block buffer
;
; parameter: dv    = cmd-hd device address
;            sd    = cmd-hd scsi device id
;            so    = system area offset
;            pn    = partition number
; return   : es    = error status
; temporary: ba,bh,bm,bl,rh,rm,rl
;

; Currently not used in this project
;
; ; Read partition block from disk into block buffer
;
; ; Read a block of the partition table from disk into SCSI data buffer
; 49300 gosub49000:ifes>0thengoto49390
;
; ; Receive bytes from buffer
; 49310 open15,dv,15:gosub58100:close15
;
; ; All done
; 49390 return
