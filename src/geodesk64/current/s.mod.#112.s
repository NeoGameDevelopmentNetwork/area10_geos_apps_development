; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Disk-Info.

if .p
			t "TopSym"
			t "TopSym.MP3"
			t "TopSym.GD"
			t "TopMac.GD"
			t "s.mod.#101.ext"
endif

			n "mod.#112.obj"
			t "-SYS_CLASS.h"
			f DATA
			o VLIR_BASE
			a "Markus Kanet"

:VlirJumpTable		jmp	xDISKINFO

;*** Programmroutinen.
			t "-112_DiskInfoMnu"
			t "-112_DiskInfo"

;*** Systemroutinen.
			t "-SYS_DISKFILE"
			t "-SYS_DISKNEWNAME"
			t "-SYS_DISKMAXTR"
			t "-SYS_HEX2ASCII"
			t "-SYS_DEVTYPE"
			t "-SYS_STATMSG"

;*** Reservierter Speicher.
:sysMem
:sysMemA		= (sysMem / 256 +1)*256

:borderBlock_S		= 256
:borderBlock		= sysMemA

:sysMemE		= borderBlock + borderBlock_S
:sysMemS		= (sysMemE - sysMem)

;******************************************************************************
			g LD_ADDR_REGISTER - sysMemS
;******************************************************************************
