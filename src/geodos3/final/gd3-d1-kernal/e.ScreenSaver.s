; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExt"

;*** GEOS-Header.
			n "obj.ScreenSaver"
			c "ScrSaver64  V1.0"
			t "G3_Sys.Author"
			f DATA
			z $80				;nur GEOS64

			o LD_ADDR_SCRSAVER

;*** ScreenSaver einbinden.
			d "Starfield"

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_SCRSAVER + R2_SIZE_SCRSAVER -1
;******************************************************************************
