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
; 30300.hdini-check.bas - check partition data
;
; parameter: hm    = max. possible partitions
;            so    = system area offset
;            tb    = total blocks on device
; return   : pf    = first free partition
;            br    = blocks remaining
; temporary: ii
;

; Check partition data
30300 pf=-1:br=-1
30301 ifso>0theniftb>0thenbr=tb

30310 forii=0tohm
30320   if(ii>0)and(pt(ii)=0)and(pf=<0)thenpf=ii
30330   ifpt(ii)=0thengoto30380
30340   iftb>0thenbr=br-ps(ii)
30380 next

; All done
30390 return
