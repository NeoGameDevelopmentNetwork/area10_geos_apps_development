; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Neuen Zeichensatz aktivieren.
:UseFontG3
if Flag64_128 = TRUE_C128
			lda	graphMode
			bpl	:1
			LoadW	r0,FontG3_80
			jmp	LoadCharSet
endif
::1			LoadW	r0,FontG3
			jmp	LoadCharSet

;*** Spezieller Zeichensatz für GEOS_MegaPatch (7x8)
:FontG3			v 8,"fnt.GEOS_G3"

if Flag64_128 = TRUE_C128
:FontG3_80		v 8,"fnt.GEOS_G3_128"
endif
