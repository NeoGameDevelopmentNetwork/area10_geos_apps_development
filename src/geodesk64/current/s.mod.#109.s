; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Datei löschen.

if .p
			t "TopSym"
			t "TopSym.IO"
			t "TopSym.MP3"
			t "TopSym.GD"
			t "TopMac.GD"
			t "s.mod.#101.ext"
endif

			n "mod.#109.obj"
			t "-SYS_CLASS.h"
			f DATA
			o VLIR_BASE
			a "Markus Kanet"

:VlirJumpTable		jmp	xFILE_DELETE

;*** Programmroutinen.
			t "-109_DeleteMnu"
			t "-109_DeleteFile"
			t "-109_StatusBox"

;*** Systemroutinen.
			t "-SYS_DISKFILE"
			t "-SYS_HEX2ASCII"
			t "-SYS_COPYFNAME"
			t "-SYS_INFOBOX"
			t "-SYS_INFOB_FILE"
			t "-SYS_INFOB_DISK"
			t "-SYS_STATMSG"

;*** Startadresse Dateinamen.
:SYS_FNAME_BUF		;s MAX_DIR_ENTRIES * 17

;******************************************************************************
;Sicherstellen das genügend Speicher
;für Dateinamen und Kopierspeicher
;verfügbar ist.
			g LD_ADDR_REGISTER -(MAX_DIR_ENTRIES * 17)
;******************************************************************************
