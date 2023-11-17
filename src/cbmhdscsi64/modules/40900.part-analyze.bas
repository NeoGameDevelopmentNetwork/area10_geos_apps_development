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
40900 ifpl>=0thengoto40950

; Analyze partition table
40930 gosub48000:ifes>0thengoto40990
40931 ifpf=0thengoto40950
40932 print

; Open command channel
40940 open15,dv,15

; SCSI READ CAPACITY
40941 gosub59450

; Wait a second...
40942 gosub51800

; Close command channel
40943 close15

; Calculate remaining blocks
40950 br=tb-pa-ps

; All done
40990 return
