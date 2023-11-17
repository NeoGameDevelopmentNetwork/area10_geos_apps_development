; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* SD2IEC DiskImage erstellen.

if .p
			t "TopSym"
			t "TopSym.ROM"
			t "TopSym.MP3"
			t "TopSym.GD"
			t "TopMac.GD"
			t "s.mod.#101.ext"
endif

			n "mod.#119.obj"
			t "-SYS_CLASS.h"
			f DATA
			o VLIR_BASE
			a "Markus Kanet"

:VlirJumpTable		jmp	xCREATE_DIMG

;*** Programmroutinen.
			t "-119_CreateMnu"
			t "-119_CreateJob"
			t "-119_StatusBox"

;*** Systemroutinen.
			t "-SYS_DISKFILE"
			t "-SYS_HEX2ASCII"
			t "-SYS_INFOBOX"
			t "-SYS_STATMSG"

;******************************************************************************
			g LD_ADDR_REGISTER
;******************************************************************************
