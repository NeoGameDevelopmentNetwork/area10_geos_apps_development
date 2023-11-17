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
; 03700.enter-part-tgt.bas - enter target partition
;
; parameter: ht    = current target scsi device
;            ot    = system area offset
;                    -1 = system area not tested
;            ct    = copy target partition
; return   : es    = error status
;            ot    = system area offset target device
;            ct    = target partition number
;            ft    = target partition format mode
;            t0    = target partition start address
;            t1    = target partition size in 512-byte blocks
; temporary: a$
;      3400: sk,fm,so,pn,ax,bx
;      3200: px,pb,pf,ba,ip,p,ad,hi,lo,bh,bm,bl
;

; Enter target partition
3700 printleft$(po$,14):print"{right}";sl$
3710 input"{up}{right}{right}enter target partition (1-254)";a$
3720 if(val(a$)<1)or(val(a$)>254)thengoto3790

; Clear screen
3730 gosub1930:rem clear status info
; Set partition -1 and check next partition
; This will check the value to be valid
3740 ct=val(a$)-1:gosub3400:rem test next partition

; All done
3790 return
