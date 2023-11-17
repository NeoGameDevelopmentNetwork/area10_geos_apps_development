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
; 39100.hdpart-nextfree.bas - set next free partition
;
; parameter: pn    = partition number
; return   : pf    = first free partition
;                    = 0 no more free partition
;

; Set partition number to next free partition
39100 pn=pf+1:ifpn>254thenpn=1
; Find free partition
39101 goto39000

; Set free partition +10
39150 pn=pf+10:ifpn>254thenpn=1
; Find free partition
39151 goto39000
