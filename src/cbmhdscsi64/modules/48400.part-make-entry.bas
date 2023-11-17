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
; 48400.part-make-entry.bas - create partition entry
;
; parameter: pn    = partition number
;            pt    = cmd partition type
;            pn$   = partition name
;            pa    = partition start address
;            ps    = partition size of last created partition
;            pr    = required blocks for partition
; return   : bu(x) = partition entry
; temporary: ip,i,nm$,ba,bh,bm,bl
;

; Create partition entry

; Set position in block buffer to partition entry
48400 ip=(pn and 15)*32

; Clear partition entry
; Byte#0/1 are link pointer for partition directory
48410 fori=2to31:bu(ip+i)=0:next

; Partition type
48420 bu(ip+ 2)=pt

; Partition name
48431 pn$=left$(pn$,16)
48432 nm$=pn$
48433 iflen(nm$)<16thennm$=nm$+chr$(160):goto48433
48434 fori=0to15:bu(ip+ 5+i)=asc(mid$(nm$,i+1,1)):next

; Partition start address
48440 ba=pa+ps:gosub58900
48441 bu(ip+21)=bh:bu(ip+22)=bm:bu(ip+23)=bl

; Partition size
48450 ba=pr:gosub58900
48451 bu(ip+29)=bh:bu(ip+30)=bm:bu(ip+31)=bl

48490 return
