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

; pt() : hd.ini: partition type
; pn$(): hd.ini: partition name
; ps() : hd.ini: partition size
; pa() : hd.ini: partition start address
120 dimpt(254),pn$(254),ps(254),pa(254)

; pp() : Partition directory / partition types
121 dimpp(254)

; hm   : Max. count of partitions
130 hm=254

; mp   : Max. count of entries for partition directory
131 mp=16




; so   : system-area offset, -1 = not defined
200 so=-1

; pl   : partition list displayed, -1 = not listed
210 pl=-1

; pa   : Partition start address
; ps   : Partition size (512 byte blocks)
; pr   : Required 512 byte blocks for partition
; pt   : Partition type
; pt$  : Partition type text
; pf   : Next free partition
; pn   : Partition number
;211 pa=0:ps=0:pr=0:pt=0:pt$=0:pf=0:pn=0

; cd$  : Default name of configuration file
220 cd$="hd.ini"

; cf$  : Name of configuration file
221 cf$=cd$


; Define UI elements
400 sl$=left$(sp$+sp$+sp$+sp$,39)
410 li$="":fori=0to38:li$=li$+"-":next
420 po$="{home}":fori=0to23:po$=po$+"{down}":next
430 ta$="":fori=0to38:ta$=ta$+"{right}":next
