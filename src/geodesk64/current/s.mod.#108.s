; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Datei-Eigenschaften anzeigen.

if .p
			t "TopSym"
			t "TopSym.MP3"
			t "TopSym.GD"
			t "TopMac.GD"
			t "s.mod.#101.ext"
endif

			n "mod.#108.obj"
			t "-SYS_CLASS.h"
			f DATA
			o VLIR_BASE
			a "Markus Kanet"

:VlirJumpTable		jmp	xFILE_INFO

;*** Programmroutinen.
			t "-108_FileInfo"
			t "-108_TextEdit"

;*** Systemroutinen.
			t "-SYS_GTYPE"
			t "-SYS_GTYPE_TXT"
			t "-SYS_CTYPE"
			t "-SYS_SMODE"
			t "-SYS_HEX2ASCII"
			t "-SYS_HEXW2ASCII"
			t "-SYS_STATMSG"

;*** Reservierter Speicher.
:sysMem
:sysMemA		= (sysMem / 256 +1)*256

:curFHdrInfo_S		= 256
:curFHdrInfo		= sysMemA

:bufInfoText_S		= 96
:bufInfoText1		= curFHdrInfo + curFHdrInfo_S
:bufInfoText2		= bufInfoText1 + bufInfoText_S
:bufInfoText3		= bufInfoText2 + bufInfoText_S

:dirEntryData		= bufInfoText3 + bufInfoText_S
:dirEntryData_S		= MAX_DIR_ENTRIES * 32

:sysMemE		= dirEntryData + dirEntryData_S
:sysMemS		= (sysMemE - sysMem)

;******************************************************************************
			g LD_ADDR_REGISTER - sysMemS
;******************************************************************************
