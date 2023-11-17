; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if COMP_SYS = TRUE_C64
;--- Maustreiber.
			b $f0,"s.SMouse64",$00
endif

if COMP_SYS = TRUE_C128
;--- Maustreiber.
			b $f0,"s.SMouse128",$00
endif
