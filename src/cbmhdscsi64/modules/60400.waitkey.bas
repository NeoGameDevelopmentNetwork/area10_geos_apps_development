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
; 60400.waitkey.bas - wait for a key
;
; parameter: a$    = ascii char
; return   : a$    = lower case ascii char
; temporary: kb$
;

; "Press <return> to continue."
60400 gosub9010
60410 getkb$:ifkb$<>chr$(13)thengoto60410
60420 print"{up}";sl$;"{up}"
60440 return
