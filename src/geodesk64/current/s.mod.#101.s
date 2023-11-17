; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* GeoDesk von Disk starten.
;* GeoDesk aus DACC starten.
;
;* FensterManager.
;* Systemvariablen.
;* Systemroutinen.
;* Systemicons.
;* Systemzeichensatz.

if .p
			t "TopSym"
			t "TopSym.IO"
			t "TopSym.MP3"
			t "TopSym.GD"
			t "TopMac.GD"
endif

			n "mod.#101.obj"
			t "-SYS_CLASS.h"
			f APPLICATION
			o APP_RAM
			a "Markus Kanet"

;*** Einsprungtabelle für Modul-Funktionen.
;Sofern hir weitere Routinen hinzugefügt
;werden muss ":GD_JMPTBL_COUNT" in
;":TopSym.GD" angepasst werden!
:VlirJumpTable		jmp	MOD_BOOT
			jmp	MOD_REBOOT

;------------------------------------------------------------------------------
;Reservierter Bereich für System-
;Variablen. Bereich nicht verschieben,
;da Boot/SaveConfig darauf zugreift.
;------------------------------------------------------------------------------
;*** Systemvariablen.
			t "-SYS_VAR"

;*** Programmvariablen.
			t "-101_VarDataGD"
			t "-101_VarDataWM"
;------------------------------------------------------------------------------

;*** Weitere Variablen, werden nicht gespeichert.
			t "-101_VarDataMisc"

;*** AppLink-Definition.
			t "-SYS_APPLINK"

;*** Fenstermanager.
			t "-101_WM.extern"
			t "-101_WM.intern"
			t "-101_WM.screen"
			t "-101_WM.scrbar"
			t "-101_WM.drive"
			t "-101_WM.mouse"
			t "-101_WM.icons"

;*** Systemroutinen.
			t "-101_SwitchDrive"
			t "-101_DlgTitle"
			t "-101_DrawClock"
			t "-101_LoadModule"
			t "-101_UpdateMod"
			t "-101_AppLinkDev"
			t "-101_AppLinkData"
			t "-101_ResetFontGD"
			t "-101_CopyFName"
			t "-101_DirDataOp"
			t "-101_DEZ2ASCII"
			t "-101_SmallPutStr"

;*** System-Icons.
			t "-101_SystemIcons"

;*** Spezieller Zeichensatz (7x8)
.FontG3			v 7,"fnt.GeoDesk"

;*** Beginn Speicher für VLIR-Module.
.VLIR_BASE
