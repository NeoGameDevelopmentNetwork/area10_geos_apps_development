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
; 59450.scsi-capacity-print.bas - READ CAPACITY and print info
;
; parameter: sl/sh = cmd-hd scsi data-out buffer
; return   : ed    = status byte
;            tb    = block count
; temporary: ec,a$,he$,sc$,by$,by,bh,bm,bl
;

; Display capacity
59450 gosub59400:ifes>0thengoto59490

59460 print"  total count of 512-byte blocks:"
59461 print"  dez:";tb;" / hex:";
59462 by=bh:gosub60200:print" $";he$;":";
59463 by=bm:gosub60200:printhe$;
59464 by=bl:gosub60200:printhe$

59470 print
59471 print"  total count of bytes:"
59472 print" ";int(tb*512/1000/1000);"{left}mb";
59473 print"  (1mb = 1.000.000 bytes){down}"

59490 return
