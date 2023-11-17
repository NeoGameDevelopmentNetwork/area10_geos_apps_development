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
; 38400.hdpart-create.bas - create new partition entry
;
; parameter: ap    = auto-create partition mode
;            pn    = partition nr
;            pt$   = partition type/text
;            pn$   = partition name
;            pr    = partition size (512 byte blocks)
; return   : pt()  = partition data: type
;            pn$() = partition data: name
;            ps()  = partition data: size
;            pa()  = partition data: start address/0
;            pf    = first free partition
;            br    = blocks remaining
; temporary: ip,i,nm$,ba,bh,bm,bl,a$
;

; Create new partition entry
38400 printtt$

; "Create new partition:"
38410 gosub9560
38411 print"    partition :";pn
38412 print"    name      : ";pn$
38413 print"    type      : ";pt$
38414 print"    size      :";pr*2;"blocks{down}"

; Create partition entry
38420 pt(pn)=pt:pn$(pn)=pn$:ps(pn)=pr:pa(pn)=0

; Get next free partition
38430 gosub39000

; Partition created
38440 print"  partition created!{down}"

; Wait for return
38450 ifap=0thengoto38460
38451 gosub51800:rem wait a second
38452 goto38490

; Wait for return
38460 gosub60400

; All done!
38490 return
