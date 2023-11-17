; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Disk löschen.

if .p
			t "TopSym"
			t "TopSym.ROM"
			t "TopSym.MP3"
			t "TopSym.GD"
			t "TopMac.GD"
			t "s.mod.#101.ext"
endif

			n "mod.#113.obj"
			t "-SYS_CLASS.h"
			f DATA
			o VLIR_BASE
			a "Markus Kanet"

:VlirJumpTable		jmp	xCLEARDISK
			jmp	xPURGEDISK
			jmp	xFORMATDISK

;*** Programmroutinen.
			t "-113_ClrDiskMnu"
			t "-113_ClearDisk"
			t "-113_FormatDisk"
			t "-113_StatusBox"

;*** Systemroutinen.
			t "-SYS_DISKFILE"
			t "-SYS_DISKMAXTR"
			t "-SYS_DISKNEXTSEK"
			t "-SYS_HEX2ASCII"
			t "-SYS_CLEARBAM"
			t "-SYS_INFOBOX"
			t "-SYS_CLOSEDRVWIN"
			t "-SYS_STATMSG"

;******************************************************************************
			g LD_ADDR_REGISTER
;******************************************************************************
