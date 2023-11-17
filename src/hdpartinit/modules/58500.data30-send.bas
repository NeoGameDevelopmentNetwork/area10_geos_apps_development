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
; 58500.data30-send.bas - send 30 data-bytes to cmd-hd ram
;
; parameter: bu(x) = 512 data bytes
;            sb    = cmd-hd scsi data-out buffer
;            ip    = pointer 32byte block in buffer
; return   : -
; temporary: i,ad,lo,hi,sc$,j
;

; Send 30 data bytes to CMD-HD ram
; Used to send partition data bytes #2-#31 to CMD-HD
58500 j=2

; Send 30/32 data bytes to CMD-HD ram
58550 ad=sb+ip+j:hi=int(ad/256):lo=ad-hi*256
58570 sc$="":fori=jto31:sc$=sc$+chr$(bu(ip+i)):next
58580 print#15,"m-w"chr$(lo)chr$(hi)chr$(32-j)sc$
58590 return
