; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Neuen Zeichensatz aktivieren.
:UseFontG3		LoadW	r0,FontG3
			jmp	LoadCharSet

;*** Spezieller Zeichensatz für GEOS_MegaPatch (7x8)
:FontG3			v 8,"fnt.GEOS_G3"
