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
; 30100.hdini-clear.bas - clear partition data
;
; parameter: hm    = max. possible partitions
;            so    = system area offset
;            tb    = total blocks on device
; return   : pt()  = partition data: type
;            pn$() = partition data: name
;            ps()  = partition data: size
;            pa()  = partition data: start address
;            pf    = first free partition
;            br    = blocks remaining
; temporary: ii
;

; Clear current partition data
30100 printtt$:gosub9500

; Clear partition data
30110 gosub38800

; Initialize remaining disk space
30120 gosub30300

; All done
30190 return
