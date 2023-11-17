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
; 38800.hdpart-clear.bas - clear partition data
;
; parameter: -
; return   : pt()  = partition data: type
;            pn$() = partition data: name
;            ps()  = partition data: size
;            pa()  = partition data: start address
; temporary: ii
;


; Clear current partition data
38800 forii=1tohm
38810   pn$(ii)="":pt(ii)=0:ps(ii)=0:pa(ii)=0
38820 next
38890 return
