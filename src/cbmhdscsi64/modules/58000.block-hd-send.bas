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
; 58000.block-hd-send.bas - send 512 bytes from block buffer to cmd-hd ram
;
; parameter: bu(x) = 512 data bytes
; return   : -
; temporary: ip
;

; Send 512 bytes as 32-byte blocks from block buffer to CMD-HD ram
58000 print"  ";
58010 forip=0to511step32:print".";:gosub58500:next
; Clear process info
58020 print:print"{up}";sp$;sp$;"{up}"
58090 return
