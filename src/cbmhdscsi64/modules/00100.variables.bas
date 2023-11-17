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

; af$  : Menu key for auto-format menu
; ap   : Auto create partition mode enabled(1)
; ap$  : Text buffer for "<auto>"
; am$  : Default partition size for native/foreign(16mb)
110 af$="f":ap=1
;111 ap$="<auto>":am$="16mb"

; pt() : Partition type table
120 dimpt(255)



; so   : system-area offset, -1 = not defined
200 so=-1

; pl   : Last created partition
; pa   : Start address last created partition
; ps   : Size of last created partition (512 byte blocks)
; pr   : Required 512 byte blocks for partition
; pt   : Partition type
; pt$  : Partition type text
; pf   : Next free partition
; pn   : Partition number
210 pl=-1
;211 pa=0:ps=0:pr=0:pt=0:pt$=0:pf=0:pn=0

; Define CMD system files
220 s0$="hdos v?.??"
221 s1$="geos/hd v?.??"
222 s2$="geoshd v?.??"
223 s3$="system header"




; Define UI elements
400 sl$=left$(sp$+sp$+sp$+sp$,39)
410 li$="":fori=0to38:li$=li$+"-":next
420 po$="{home}":fori=0to23:po$=po$+"{down}":next
430 ta$="":fori=0to38:ta$=ta$+"{right}":next
