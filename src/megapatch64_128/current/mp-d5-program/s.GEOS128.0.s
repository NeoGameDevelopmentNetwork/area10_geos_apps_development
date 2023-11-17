; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "GEOS128.0"
			t "G3_SymMacExt"
			t "G3_V.Cl.128.Boot"

			o BASE_GEOS_SYS -2
			p BASE_GEOS_SYS

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "MegaPatch-Kernal Bank 0"
			h "Grundfunktionen..."
endif

if Sprache = Englisch
			h "MegaPatch-kernal bank 0"
			h "mainprogramm..."
endif

;--- Ladeadresse.
:MainInit		w BASE_GEOS_SYS			;DUMMY-Bytes, da Kernal über
							;BASIC-Load eingelesen wird.
;--- GEOS128-Kernal.
.GEOS_Kernal0		d "obj.G3_K128_B0"
