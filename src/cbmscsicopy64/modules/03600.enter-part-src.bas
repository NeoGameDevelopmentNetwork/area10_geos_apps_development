; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; cbmSCSIcopy64
;
; 03600.enter-part-src.bas - enter source partition
;
; parameter: hs    = current source scsi device
;            os    = system area offset
;                    -1 = system area not tested
;            cs    = copy source partition
; return   : es    = error status
;            os    = system area offset source device
;            cs    = source partition number
;            fs    = source partition format mode
;            s0    = source partition start address
;            s1    = source partition size in 512-byte blocks
;            ct    = -1 / reset copy target partition
; temporary: a$
;      3300: sk,fm,so,pn,ax,bx
;      3200: px,pb,pf,ba,ip,p,ad,hi,lo,bh,bm,bl
;

; Enter source partition
3600 printleft$(po$,14):print"{right}";sl$
3610 input"{up}{right}{right}enter source partition (1-254)";a$
3620 if(val(a$)<1)or(val(a$)>254)thengoto3690

; Clear screen
3630 gosub1930:rem clear status info
; Set partition -1 and check next partition
; This will check the value to be valid
3640 cs=val(a$)-1:gosub3300:rem test next partition

; All done
3690 return
