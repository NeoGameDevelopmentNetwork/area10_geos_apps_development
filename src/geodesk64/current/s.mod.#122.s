; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Systemzeit setzen.

if .p
			t "TopSym"
			t "TopSym.IO"
			t "TopSym.MP3"
			t "TopSym.GD"
			t "TopMac.GD"
			t "s.mod.#101.ext"
endif

			n "mod.#122.obj"
			t "-SYS_CLASS.h"
			f DATA
			o VLIR_BASE
			a "Markus Kanet"

:VlirJumpTable		jmp	xSYSTIME

;*** Programmroutinen.
			t "-122_SysTimeMnu"
			t "-122_SysTime"

;*** Systemroutinen.
			t "-SYS_DISKFILE"

;******************************************************************************
			g BASE_DIR_DATA
;******************************************************************************
