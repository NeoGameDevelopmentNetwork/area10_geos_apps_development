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
; 49500.part-block-wrsend.bas - write partition data from block buffer to disk
;
; parameter: dv    = cmd-hd device address
;            sd    = cmd-hd scsi device id
;            so    = system area offset
;            pn    = partition number
; return   : es    = error status
; temporary: ba,bh,bm,bl,wh,wm,wl
;

; Currently not used in this project
;
; ; Write partition data from block buffer to disk
;
; ; Sent bytes to CMD-HD ram
; 49500 open15,dv,15:gosub58000:close15
;
; ; Write a block of the partition table from SCSI data buffer to disk
; 49530 gosub49100
; 49531 ifes>0thengoto49590
;
; ; All done
; 49590 return
