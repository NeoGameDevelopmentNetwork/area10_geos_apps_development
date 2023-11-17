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
; 48700.part-setfree.bas - find first free partition
;
; parameter: pn    = last partition number
; return   : pf    = free partition
;                    = 0 no more free partition
;

; Find free partition in partition table data
; Start search at current partition number
48700 pf=0:fori=pnto254
48701     ifpt(i)=0thenpf=i:i=254
48702 next

; Free partition found?
; Exit if all partitions tested
48710 if(pf>0)or(pn=1)thengoto48790

; Start search with partition #1 up to current partition number
48720 fori=1topn
48721     ifpt(i)=0thenpf=i:i=pn
48722 next

; All done
48790 return
