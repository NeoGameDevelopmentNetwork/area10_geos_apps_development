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
; 03400.select-part-tgt.bas - select target partition
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
; temporary: sk,fm,so,pn,ax,bx
;


; Select new target partition +1
3400 sk=1:goto3450
; Select new target partition +10
3410 sk=10

; Select new target partition
3450 fm=fs:sd=ht:so=ot:pn=ct:pn$=tn$
3460 gosub3200:ifes>0thengoto3465
3462 ifpn>0thengoto3480

; Error: No partition selected
3465 printleft$(po$,14):print"{right}";sl$
3466 print"{up}{right}{right}no partition found!  press <return>"
3467 pn=-1:fm=-1:tn$=""

; Wait for return
3470 gosub60400

; Set new partition values
; ot   : System area offset
; ct   : Target partition
; ft   : Target partition format
; t0   : Start address target partition
; t1   : Size of target partition
; tn$  : Target partition name
3480 ot=so:ct=pn:ft=fm:t0=ax:t1=bx:tn$=pn$

; All done
3490 return
