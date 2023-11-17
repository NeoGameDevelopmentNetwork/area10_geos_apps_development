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
; 35500.hdini-make-entry.bas - create partition entry
;
; parameter: pn    = partition number
;            pt()  = partition data: type
;            pn$() = partition data: name
;            ps()  = partition data: size
; return   : bu(x) = partition entry
; temporary: ip,i,pn$,ba,bh,bm,bl
;

; Create partition entry

; Set position in block buffer to partition entry
35500 ip=(pn and 15)*32

; Clear partition entry
; Byte#0/1 are link pointer for partition directory
35510 fori=2to31:bu(ip+i)=0:next

; Partition type
35520 ifpt(pn)=0thengoto35590
35521 bu(ip+ 2)=pt(pn)

; Partition name
35530 pn$=left$(pn$(pn),16)
35531 iflen(pn$)<16thenpn$=pn$+chr$(160):goto35531
35532 fori=0to15:bu(ip+ 5+i)=asc(mid$(pn$,i+1,1)):next

; Partition start address
35540 ba=pa(pn):gosub58900
35541 bu(ip+21)=bh:bu(ip+22)=bm:bu(ip+23)=bl

; Partition size
35550 ba=ps(pn):gosub58900
35551 bu(ip+29)=bh:bu(ip+30)=bm:bu(ip+31)=bl

35590 return
