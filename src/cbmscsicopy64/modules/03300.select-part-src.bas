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
; 03300.select-part-src.bas - select source partition
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
; temporary: sk,fm,so,pn,ax,bx
;

; Select new source partition +1
3300 sk=1:goto3350
; Select new source partition +10
3310 sk=10

; Select new source partition
3350 fm=-1:sd=hs:so=os:pn=cs:pn$=sn$
3360 gosub3200:ifes>0thengoto3365
; If no other partition is found, reset partition format
3361 iffm=-1thenfm=fs
; Partition found?
3362 ifpn>0thengoto3380

; Error: No partition selected
3365 printleft$(po$,14):print"{right}";sl$
3366 print"{up}{right}{right}no partition found!  press <return>"
3367 pn=-1:fm=-1:sn$=""

; Wait for return
3370 gosub60400

; Set new partition values
; os   : System area offset
; cs   : Source partition
; fs   : Source partition format
; s0   : Start address source partition
; s1   : Size of source partition
; sn$  : Source partition name
3380 os=so:cs=pn:fs=fm:s0=ax:s1=bx:sn$=pn$
3381 iffs<>ftthenct=-1

; All done
3390 return
