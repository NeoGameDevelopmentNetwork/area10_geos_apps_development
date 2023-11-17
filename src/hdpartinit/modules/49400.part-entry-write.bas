; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; hdPartInit
;
; 49400.part-entry-write.bas - write single partition entry from block buffer to disk
;
; parameter: dv    = cmd-hd device address
;            sd    = cmd-hd scsi device id
;            so    = system area offset
;            pn    = partition number
; return   : es    = error status
; temporary: ba,bh,bm,bl,wh,wm,wl,rh,rm,rl,ip
;

; Write single partition entry from block buffer to disk

; Read a block of the partition table from disk into SCSI data buffer
49400 gosub49000:ifes>0thengoto49490

; Set position to partition entry
49410 ip=(pn and 15)*32

; Send 30 data bytes to CMD-HD ram
49420 open15,dv,15:gosub58500:close15

; Write partition data block to disk
49430 gosub49100
;49431 ifes>0thengoto49490

; All done
49490 return
