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
; 00100.variables.bas - define program variables
;
; Note: BASIC lines commented out include variables
;       that will be initialized later.
;       To reduce programm code skip initialization.
;
; Note: Reserved variable names for C128:
;       er, el, ds, ds$
;

; ts   : C64/C128 clock register 1/10 seconds
100 ts=162

; Device information
; hs    : source scsi device
; ht    : target scsi device
110 hs=-1:ht=-1

; cs    : copy source scsi partition
; ct    : copy target scsi partition
120 cs=-1:ct=-1

; fs    : format source partition
; ft    : format target partition
; fm    : partition type
130 fs=-1:ft=-1:fm=-1

; os    : offset system area source
; ot    : offset system area target
140 os=-1:ot=-1

; s0    : start address source partition
; t0    : start address target partition
150 s0=-1:t0=-1

; s1    : sector count source partition
; t1    : sector count target partition
160 s1=-1:t1=-1

; so   : system-area offset, -1 = not defined
200 so=-1

; ty$(): directory file types
300 dimty$(9)
301 ty$(0)="del":ty$(1)="seq":ty$(2)="prg"
302 ty$(3)="usr":ty$(4)="rel":ty$(5)="cbm"
303 ty$(6)="dir":ty$(9)="???"

; Define UI elements
400 sl$=left$(sp$+sp$+sp$+sp$,37)
410 li$="":fori=0to36:li$=li$+chr$(192):next
411 c0$=chr$(176):c1$=chr$(174)
412 c2$=chr$(173):c3$=chr$(189)
413 vi$=chr$(125)
420 po$="{home}":fori=0to23:po$=po$+"{down}":next
430 ta$="":fori=0to38:ta$=ta$+"{right}":next
440 gf$=chr$(34)
