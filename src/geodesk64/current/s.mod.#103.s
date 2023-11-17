; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Partition wechseln.
;* SD2IEC Hauptverzeichnis.
;* SD2IEC Elternverzeichnis.
;* SD2IEC Eintrag öffnen.

if .p
			t "TopSym"
			t "TopSym.MP3"
			t "TopSym.ROM"
			t "TopSym.GD"
			t "TopMac.GD"
			t "s.mod.#101.ext"
endif

			n "mod.#103.obj"
			t "-SYS_CLASS.h"
			f DATA
			o VLIR_BASE
			p VLIR_BASE
			a "Markus Kanet"

:VlirJumpTable		jmp	getDiskData
			jmp	dirRootSD
			jmp	dirOpenSD
			jmp	dirOpenEntry
			jmp	getModeSD2IEC

;*** Programmroutinen.
			t "-103_DiskCore"
			t "-103_DiskShared"
			t "-103_DiskSD2IEC"
			t "-103_DiskCMD"
			t "-103_DirSelect"
			t "-103_Data"
			t "-103_GetModeSD"
			t "-103_SortSD2IEC"

;*** Reservierter Speicher.
:sysMem
:sysMemA		= (sysMem / 256 +1)*256

:partTypeBuf_S		= 256
:partTypeBuf		= sysMemA

:sysMemE		= partTypeBuf + partTypeBuf_S
:sysMemS		= (sysMemE - sysMem)

;******************************************************************************
			g BASE_DIR_DATA - sysMemS
;******************************************************************************
