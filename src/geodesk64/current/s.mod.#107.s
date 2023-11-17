; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* GeoDesk-Konfiguration speichern.
;* GeoDesk-Optionen ändern.

if .p
			t "TopSym"
			t "TopSym.MP3"
			t "TopSym.GD"
			t "TopMac.GD"
			t "s.mod.#101.ext"
endif

			n "mod.#107.obj"
			t "-SYS_CLASS.h"
			f DATA
			o VLIR_BASE
			a "Markus Kanet"

:VlirJumpTable		jmp	xSAVE_CONFIG
			jmp	xOPTIONS

;*** Programmroutinen.
			t "-107_OptionsMnu"
			t "-107_Options"
			t "-107_SaveConfig"

;*** Speicherverwaltung.
			t "-SYS_RAM_FREE"
			t "-SYS_RAM_ALLOC"
			t "-SYS_RAM_SHARED"

;*** Systemroutinen.
			t "-SYS_DISKFILE"
			t "-SYS_HEX2ASCII"

if DEBUG_SYSINFO = TRUE
			t "-SYS_HEXW2ASCII"
endif

;******************************************************************************
			g BASE_DIR_DATA
;******************************************************************************
