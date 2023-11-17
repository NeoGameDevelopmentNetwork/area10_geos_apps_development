; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "SymbTab_1"
;			t "SymbTab_GDOS"
			t "SymbTab_GTYP"
			t "SymbTab_MMAP"
;			t "MacTab"
endif

;*** GEOS-Header.
			n "obj.ScreenSaver"
			c "ScrSaver64  V1.0"
			t "opt.Author"
			f DATA
			z $80 ;nur GEOS64

			o LOAD_SCRSAVER

;*** ScreenSaver einbinden.
			d "Starfield"

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LOAD_SCRSAVER + R2S_SCRSAVER -1
;******************************************************************************
