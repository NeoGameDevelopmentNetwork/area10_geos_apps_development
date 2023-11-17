; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if COMP_SYS = TRUE_C64
;--- Setup-Programme.
			b $f0,"s.MkSetup64",$00
			b $f0,"s.SetupMP_64",$00
endif

if COMP_SYS = TRUE_C128
			b $f0,"s.MkSetup128",$00
			b $f0,"s.SetupMP_128",$00
endif
