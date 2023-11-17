; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Dateien aus Verzeichnis einlesen.

if .p
			t "TopSym"
			t "TopSym.MP3"
			t "TopSym.GD"
			t "TopMac.GD"
			t "s.mod.#101.ext"
endif

			n "mod.#106.obj"
			t "-SYS_CLASS.h"
			f DATA
			o VLIR_BASE
			a "Markus Kanet"

:VlirJumpTable		jmp	xGET_ALL_FILES

;*** Programmroutinen.
			t "-106_GetFileData"
;			t "-106_SortDir"
			t "-106_BSortDir"
			t "-106_ChkDateTime"
			t "-106_SortInfo"

;******************************************************************************
			g BASE_DIR_DATA
;******************************************************************************
