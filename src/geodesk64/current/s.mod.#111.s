; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Validate.

if .p
			t "TopSym"
			t "TopSym.IO"
			t "TopSym.MP3"
			t "TopSym.GD"
			t "TopMac.GD"
			t "s.mod.#101.ext"
endif

			n "mod.#111.obj"
			t "-SYS_CLASS.h"
			f DATA
			o VLIR_BASE
			a "Markus Kanet"

:VlirJumpTable		jmp	xVALIDATE
			jmp	xRECOVERY
			jmp	xPURGEFILES

;*** Programmroutinen.
			t "-111_ValidateMnu"
			t "-111_Validate"
			t "-111_Recovery"
			t "-111_PurgeFiles"
			t "-111_StatusBox"

;*** Systemroutinen.
			t "-SYS_DISKFILE"
			t "-SYS_HEX2ASCII"
			t "-SYS_CLEARBAM"
			t "-SYS_STATMSG"

;******************************************************************************
			g LD_ADDR_REGISTER
;******************************************************************************
