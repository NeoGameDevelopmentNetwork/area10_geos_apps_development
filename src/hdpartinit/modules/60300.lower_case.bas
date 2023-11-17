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
; 60300.lower_case.bas - convert text to lower case
;
; parameter: a$    = ascii char
; return   : a$    = lower case ascii char
; temporary: -
;

; Convert ascii char to lower case
60300 ifasc(a$)>=96thena$=chr$(asc(a$)-32)
60390 return
