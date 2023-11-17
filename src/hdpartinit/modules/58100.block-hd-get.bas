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
; 58100.block-hd-get.bas - get 512 bytes from cmd-hd ram into block buffer
;
; parameter: bu(x) = 512 data bytes
; return   : -
; temporary: ip
;

; Get 512 bytes as 32-byte blocks from CMD-HD ram into block buffer
58100 print"  ";
58110 forip=0to511step32:print".";:gosub58400:next
; Clear process info
58120 print:print"{up}";sp$;sp$;"{up}"
58190 return
