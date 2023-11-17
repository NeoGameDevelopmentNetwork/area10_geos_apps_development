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
; 48900.part-type.bas - define partition type text
;
; parameter: pt    = cmd partition type
; return   : pt$   = partition type
;

; Define partition type text
; pd$(0)="empty"
; pd$(1)="native":pd$(2)="1541":pd$(3)="1571":pd$(4)="1581"
; pd$(5)="1581 cp/m":pd$(6)="prntbuf":pd$(7)="foreign"
; pd$(8)="system":pd$(9)="unknown"
48900 ifpt=255thenpt$=pd$(8):return
48910 ifpt>7thenpt$=pd$(9):return
48920 pt$=pd$(pt):return
