; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if COMP_SYS = TRUE_C64
;--- Joysticktreiber.
			b $f0,"s.SStick64.1",$00
			b $f0,"s.SStick64.2",$00
endif

if COMP_SYS = TRUE_C128
;--- Joysticktreiber.
			b $f0,"s.SStick128.1",$00
			b $f0,"s.SStick128.2",$00
endif
