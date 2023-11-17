; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* AppLink-Daten laden.
;* AppLink-Daten speichern.
;* AppLink umbenennen.

if .p
			t "TopSym"
			t "TopSym.MP3"
			t "TopSym.GD"
			t "TopMac.GD"
			t "s.mod.#101.ext"
endif

			n "mod.#104.obj"
			t "-SYS_CLASS.h"
			f DATA
			o VLIR_BASE
			a "Markus Kanet"

:VlirJumpTable		jmp	xLNK_LOAD_DATA
			jmp	xLNK_SAVE_DATA
			jmp	xLNK_RENAME

;*** AppLink-Definition.
			t "-SYS_APPLINK"

;*** Programmroutinen.
			t "-104_AppLink"

;*** Startadresse Kopierspeicher.
:Memory1
:Memory2		= (Memory1 / 256 +1)*256
:ND_VLIR		= Memory2			;256 Bytes VLIR-Daten.
:ND_Data		= ND_VLIR +256			;256 Bytes AppLink-Daten.

;******************************************************************************
;Sicherstellen das genügend Speicher
;für AppLink-Daten verfügbar ist.
			g BASE_DIR_DATA -(3*256)
;******************************************************************************
