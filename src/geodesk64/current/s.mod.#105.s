; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Datei öffnen.
;* Editor öffnen.
;* Drucker wechseln.
;* Eingabegerät wechseln.
;* Dialog: Fehler Drucker-Installation.
;* Dialog: Drucker-Installation OK.
;* Anwendung wählen.
;* AutoExec wählen.
;* Dokumente wählen.
;* geoWrite-Dokument wählen.
;* geoPaint-Dokument wählen.
;* Hintergrundbild wählen.
;* Nach GEOS beenden.
;* Nach BASIC beenden.
;* BASIC-Programm starten.
;* GEOS-Hilfsmittel starten.
;* AppLink-Datei auf anderen Laufwerken suchen.
;* Druckertreiber laden.
;* Eingabetreiber laden.

if .p
			t "TopSym"
			t "TopSym.IO"
			t "TopSym.MP3"
			t "TopSym.GD"
			t "TopMac.GD"
			t "s.mod.#101.ext"
endif

			n "mod.#105.obj"
			t "-SYS_CLASS.h"
			f DATA
			o VLIR_BASE
			a "Markus Kanet"

:VlirJumpTable		jmp	StartFile_a0
			jmp	OpenEditor
			jmp	ChangePrinter
			jmp	ChangeInput
			jmp	OpenPrntError
			jmp	OpenPrntOK
			jmp	SelectAppl
			jmp	SelectAuto
			jmp	SelectDocument
			jmp	SelectDocWrite
			jmp	SelectDocPaint
			jmp	SelectBackScrn
			jmp	ExitGEOS
			jmp	ExitBASIC
			jmp	ExitBAppl
			jmp	SelectDA
			jmp	StartApplink_a0
			jmp	OpenPrinter
			jmp	OpenInput

;*** Speicherverwaltung.
			t "-SYS_RAM_FREE"
			t "-SYS_RAM_SHARED"

;*** Programmroutinen.
			t "-105_OpenFile"
			t "-105_OpenEditor"
			t "-105_OpenDevice"
			t "-105_ExitBASIC"
			t "-105_BackScreen"

;*** Systemroutinen.
			t "-SYS_COLCONFIG"

;******************************************************************************
			g BASE_DIR_DATA
;******************************************************************************
