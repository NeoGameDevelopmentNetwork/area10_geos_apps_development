﻿; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Systemlabels.
if .p
			t "src.GEOS_MP3.ext"
			t "SymbTab_1"
			t "SymbTab_2"
			t "SymbTab_3"
			t "SymbTab_MMap"
			t "MacTab"
			t "s.MP3.Edit.1.ext"
endif

:PASS1 = < .p
if PASS1 ! Flag64_128 = TRUE ! TRUE_C64
			t "SymbTab64"
endif
if PASS1 ! Flag64_128 = TRUE ! TRUE_C128
			t "SymbTab128"
endif
