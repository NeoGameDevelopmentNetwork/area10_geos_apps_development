; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Farben ändern.

if .p
			t "TopSym"
			t "TopSym.MP3"
			t "TopSym.IO"
			t "TopSym.GD"
			t "TopMac.GD"
			t "s.mod.#101.ext"
endif

			n "mod.#115.obj"
			t "-SYS_CLASS.h"
			f DATA
			o VLIR_BASE
			a "Markus Kanet"

:VlirJumpTable		jmp	xCOLOR_SETUP

;*** Programmroutinen.
			t "-115_ColorsMnu"
			t "-115_Colors"

;*** Systemroutinen.
			t "-SYS_GTYPE_TXT"
			t "-SYS_DISKFILE"
			t "-SYS_HEX2ASCII"
			t "-SYS_COLCONFIG"
			t "-SYS_STATMSG"

;******************************************************************************
			g BASE_DIR_DATA
;******************************************************************************
