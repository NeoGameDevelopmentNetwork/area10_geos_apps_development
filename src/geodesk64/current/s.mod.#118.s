; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Datei von/nach CVT wandeln.

if .p
			t "TopSym"
			t "TopSym.MP3"
			t "TopSym.GD"
			t "TopMac.GD"
			t "s.mod.#101.ext"
endif

			n "mod.#118.obj"
			t "-SYS_CLASS.h"
			f DATA
			o VLIR_BASE
			a "Markus Kanet"

:VlirJumpTable		jmp	xCONVERT

;*** Programmroutinen.
			t "-118_Convert"
			t "-118_ConvertCVT"
			t "-118_DefNameDOS"
			t "-118_StatusBox"

;*** Systemroutinen.
			t "-SYS_HEX2ASCII"
			t "-SYS_COPYFNAME"
			t "-SYS_INFOBOX"
			t "-SYS_INFOB_FILE"
			t "-SYS_INFOB_DISK"
			t "-SYS_STATMSG"

;*** Startadresse Dateinamen.
:SYS_FNAME_BUF		;s MAX_DIR_ENTRIES * 17

;*** Speicher für CVT-Daten.
:SYS_DATA_BUF		= SYS_FNAME_BUF + MAX_DIR_ENTRIES * 17

:FileEntryBuf1		= SYS_DATA_BUF +0
:FileEntryBuf2		= SYS_DATA_BUF +30

:CVT_VlirDataBuf	= SYS_DATA_BUF +30 +30
:G98_VlirDataBuf	= SYS_DATA_BUF +30 +30 +256

;******************************************************************************
;Sicherstellen das genügend Speicher
;für Dateinamen und Kopierspeicher
;verfügbar ist.
			g LD_ADDR_REGISTER -(MAX_DIR_ENTRIES * 17)
;******************************************************************************
