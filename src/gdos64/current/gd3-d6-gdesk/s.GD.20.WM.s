; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* GeoDesk WindowManager.

;*** Symboltabellen.
if .p
;--- C64-Labels.
			t "SymbTab_CXIO"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_DCMD"
;			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
endif

;*** GEOS-Header.
			n "obj.GD20"
			f DATA

			o BASE_WMCORE

;*** Systemkennung.
:CODE			b "WM3",NULL

;*** Konfiguration.
			t "-G20_WM.config"

;*** Fenstermanager.
			t "-G20_WM.extern"
			t "-G20_WM.intern"
			t "-G20_WM.screen"
			t "-G20_WM.scrbar"
			t "-G20_WM.drive"
			t "-G20_WM.mouse"
			t "-G20_WM.icons"

;*** Systemroutinen.
			t "-G20_DirDataOp"

;*** Endadresse testen:
			g BASE_WMCORE +SIZE_WMCORE -1
;***
