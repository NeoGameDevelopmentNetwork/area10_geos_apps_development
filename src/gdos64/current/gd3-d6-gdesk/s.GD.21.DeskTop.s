; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* GeoDesk initialisieren.
;* GeoDesk über EnterDeskTop starten.
;* GeoDesk aktualisieren.
;* GeoDesk Fenstermanager starten.
;* GeoDesk Fenstermanager neu starten.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_CXIO"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_APPS"
			t "SymbTab_GSPR"
			t "SymbTab_DCMD"
			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
			t "s.GD.20.WM.ext"

;--- AppLink-Definition.
			t "e.GD.10.AppLink"
endif

;*** GEOS-Header.
			n "obj.GD21"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	MainBoot
			jmp	MainReBoot
			jmp	MainUpdate
			jmp	MainUpdateWin
			jmp	MainReStart
			jmp	MainInitWM

;*** Programmroutinen.
			t "-G21_MainDesktop"
			t "-G21_UpdateCore"
			t "-G21_LdDTopMod"
			t "-G21_UpdateWin"
			t "-G21_TaskBar"
			t "-G21_DrawClock"
			t "-G21_MicroMys"
			t "-G21_StartFile"
			t "-G21_AppLink"
			t "-G21_PopUpMenu"
			t "-G21_PopUpFunc"
			t "-G21_DrawIcon"
			t "-G21_DragNDrop"
			t "-G21_WinOpenComp"
			t "-G21_WinOpenDrv"
			t "-G21_WinMseCheck"
			t "-G21_WinDataTab"
			t "-G21_CloseDrvWin"

;*** Systemroutinen.
			t "-SYS_STATMSG"

;*** Endadresse testen:
			g BASE_GDMENU
;***
