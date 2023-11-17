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
; 60400.waitkey.bas - wait for a key
;
; parameter: a$    = ascii char
; return   : a$    = lower case ascii char
; temporary: kb$
;

; "Press <return> to continue."
60400 getkb$:ifkb$<>chr$(13)thengoto60400
60490 return
