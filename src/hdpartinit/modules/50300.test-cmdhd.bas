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
; 50300.test-cmdhd.bas - test device for CMD-HD
;
; parameter: dv    = device address
; return   : es    = error status
; temporary: a,a$,b$
;

; Test current device for CMD-HD

50300 b$="":open15,dv,15
; 160/254 = $fea0 = "cmd hd"
50310 print#15,"m-r"chr$(160)chr$(254)chr$(6)
50320 fora=1to6:get#15,a$:b$=b$+a$:next
50330 close15

50350 es=0:ifb$<>"cmd hd"thenes=-1
50360 return
