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
; 41000.part-name.bas - set partition name
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
41000 gosub48900

; Auto-create or custom partition?
41001 ifap=0thengoto41050

; Auto-create: partition name = "TYPE#FF"
; #FF is the hex value of the partition number
41010 by=pf:gosub60200
41020 pn$=pt$+"#"+he$
41030 goto41090

; Enter custom partition name
41050 printtt$
41051 print"  create new ";pt$;"-mode partition{down}{down}"
41052 print"  please enter partition name:"
41053 print"  (leave blank to go back to menu){down}"
41054 printleft$(po$,20)
41055 print"  note: only 16 characters or less are"
41056 print"        allowed. it is recommended to"
41057 print"        use letters and numbers only."

41060 printleft$(po$,10);"  ";
41070 pn$="":inputpn$
41080 iflen(pn$)>16thengoto41060

; All done
41090 return
