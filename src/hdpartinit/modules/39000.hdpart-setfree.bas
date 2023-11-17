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
; 39000.hdpart-setfree.bas - find first free partition
;
; parameter: pn    = last partition number
; return   : pf    = free partition
;                    = 0 no more free partition
;

; Find free partition in partition table data
; Start search at current partition number
39000 pf=-1:fori=pnto254
39001     ifpt(i)=0thenpf=i:i=254
39002 next

; Free partition found?
; Exit if all partitions tested
39010 if(pf>0)or(pn=1)thengoto39090

; Start search with partition #1 up to current partition number
39020 fori=1topn
39021     ifpt(i)=0thenpf=i:i=pn
39022 next

; All done
39090 return
