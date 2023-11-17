; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Datei kopieren/verschieben.

if .p
			t "TopSym"
			t "TopSym.IO"
			t "TopSym.MP3"
			t "TopSym.GD"
			t "TopMac.GD"
			t "s.mod.#101.ext"
endif

			n "mod.#114.obj"
			t "-SYS_CLASS.h"
			f DATA
			o VLIR_BASE
			a "Markus Kanet"

:VlirJumpTable		jmp	xFILE_COPYMOVE

;*** Programmroutinen.
			t "-114_CopyMove"
			t "-114_CopyMoveDrv"
			t "-114_CopyMoveDir"
			t "-114_CopyMoveMsc"
			t "-114_CopyMoveJob"
			t "-114_NewName"
			t "-114_StatusBox"
			t "-110_MakeDir"

;*** Systemroutinen.
			t "-SYS_HEX2ASCII"
			t "-SYS_COPYFNAME"
			t "-SYS_INFOBOX"
			t "-SYS_INFOB_FILE"
			t "-SYS_INFOB_DISK"
			t "-SYS_STATMSG"

;*** Startadresse Dateinamen.
:SYS_FNAME_BUF		;s MAX_DIR_ENTRIES * 17

;*** Startadresse Kopierspeicher.
:Memory1		= SYS_FNAME_BUF + (MAX_DIR_ENTRIES * 17)
:Memory2		= (Memory1 / 256 +1)*256
:Copy1Sek		= Memory2
:StartBuffer		= Memory2 +256
:EndBuffer		= OS_VARS ;$8000

;******************************************************************************
;Sicherstellen das genügend Speicher
;für Dateinamen und Kopierspeicher
;verfügbar ist.
			g OS_VARS -(MAX_DIR_ENTRIES * 17) -$2000
;******************************************************************************
