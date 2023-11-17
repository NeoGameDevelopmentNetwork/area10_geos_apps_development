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
; 38200.hdpart-name.bas - set partition name
;
; parameter: ap    = auto-create partition mode
;            pt    = cmd partition type
;            pf    = next free partition
; return   : pn$   = new partition name
;                    return to menu if empty
;            pt$   = partition type text
; temporary: by,pn$
;

; Set partition name

; Set partition type text for auto-create
38200 gosub48900

; Auto-create or custom partition?
38201 ifap=0thengoto38250

; Auto-create: partition name = "TYPE#FF"
; #FF is the hex value of the partition number
38210 by=pf:gosub60200
38220 pn$=pt$+"#"+he$
38230 goto38290

; Enter custom partition name
38250 printtt$
38251 print"  create new ";pt$;"-mode partition{down}{down}"
38252 print"  please enter partition name:"
38253 print"  (leave blank to go back to menu){down}"
38254 printleft$(po$,20)
38255 print"  note: only 16 characters or less are"
38256 print"        allowed. it is recommended to"
38257 print"        use letters and numbers only."

38260 printleft$(po$,10);"  ";
38270 pn$="":inputpn$
38280 iflen(pn$)>16thengoto38260

; All done
38290 return
