; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "obj.ScreenSaver"
			t "G3_SymMacExt"

			c "MegaPatch   V3.0"
			a "M. Kanet"
			f APPLICATION
			o LD_ADDR_SCRSAVER

;*** ScreenSaver einbinden.
			d "Starfield"

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_SCRSAVER + R2_SIZE_SCRSAVER -1
;******************************************************************************
