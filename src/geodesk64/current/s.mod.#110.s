; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* NativeMode-Verzeichnis erstellen.

if .p
			t "TopSym"
			t "TopSym.MP3"
			t "TopSym.GD"
			t "TopMac.GD"
			t "s.mod.#101.ext"
endif

			n "mod.#110.obj"
			t "-SYS_CLASS.h"
			f DATA
			o VLIR_BASE
			a "Markus Kanet"

:VlirJumpTable		jmp	xCREATE_NM_DIR

;*** Programmroutinen.
			t "-110_MakeDirMnu"
			t "-110_MakeDir"

;*** Systemroutinen.
			t "-SYS_DISKFILE"
			t "-SYS_HEX2ASCII"
			t "-SYS_STATMSG"

;******************************************************************************
			g LD_ADDR_REGISTER
;******************************************************************************
