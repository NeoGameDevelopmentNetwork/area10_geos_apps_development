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

if .p
			t "TopSym"
			t "TopSym.IO"
			t "TopSym.MP3"
			t "TopSym.GD"
			t "TopMac.GD"
			t "s.mod.#101.ext"
endif

			n "mod.#102.obj"
			t "-SYS_CLASS.h"
			f DATA
			o VLIR_BASE
			a "Markus Kanet"

:VlirJumpTable		jmp	MainBoot
			jmp	MainReBoot
			jmp	MainUpdate
			jmp	MainUpdateWin
			jmp	MainReStart
			jmp	MainInitWM

;*** AppLink-Definition.
			t "-SYS_APPLINK"

;*** Programmrroutinen.
			t "-102_MainDesktop"
			t "-102_UpdateWin"
			t "-102_TaskBar"
			t "-102_StartFile"
			t "-102_AppLink"
			t "-102_PopUpMenu"
			t "-102_PopUpFunc"
			t "-102_MenuData"
			t "-102_SetSlctMode"
			t "-102_DoFileEntry"
			t "-102_DrawIcon"
			t "-102_DragNDrop"
			t "-102_WinOpenComp"
			t "-102_WinOpenDrv"
			t "-102_WinMseCheck"
			t "-102_WinDataTab"
			t "-102_ShortCuts"

;*** Systemroutinen.
			t "-SYS_GTYPE"
			t "-SYS_GTYPE_TXT"
			t "-SYS_CTYPE"
			t "-SYS_CLOSEDRVWIN"
			t "-SYS_STATMSG"

;******************************************************************************
			g BASE_DIR_DATA
;******************************************************************************
