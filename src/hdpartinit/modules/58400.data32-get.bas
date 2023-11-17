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
; 58400.data32-get.bas - get 30/32 data-bytes from cmd-hd ram
;
; parameter: bu(x) = 512 data bytes
;            sb    = cmd-hd scsi data-out buffer
;            ip    = pointer 32byte block in buffer
; return   : -
; temporary: i,ad,lo,hi,sc$
;

; Get 32 data bytes from CMD-HD ram
58400 j=0:goto58450

; Get 30 data bytes from CMD-HD ram
58410 j=2

; Get 30/32 data bytes from CMD-HD ram
58450 ad=sb+ip+j:hi=int(ad/256):lo=ad-hi*256
58470 print#15,"m-r"chr$(lo)chr$(hi)chr$(32-j)
58480 fori=jto31:get#15,a$:bu(ip+i)=asc(a$+nu$):next
58490 return
