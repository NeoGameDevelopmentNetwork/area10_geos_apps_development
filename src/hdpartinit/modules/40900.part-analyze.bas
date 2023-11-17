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
; 40900.part-analyze.bas - analyze partition table
;
; parameter: dv    = cmd-hd device address
;            sd    = cmd-hd scsi device id
;            so    = system area offset
;            pl    = partition number
; return   : es    = error status
;            br    = free blocks remaining
;            tb    = total blocks on disk
;            pf    = next free partition
;            pl    = last created partition
;            ps    = size of last created partition
; temporary: -
;

; Do we need to analyze the partiton table?
40900 ifpl>=0thengoto40990

; Analyze partition table
40910 gosub48000

; All done
40990 return
