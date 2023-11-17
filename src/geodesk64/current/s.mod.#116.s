; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Diskette kopieren.

if .p
			t "TopSym"
			t "TopSym.MP3"
			t "TopSym.GD"
			t "TopMac.GD"
			t "s.mod.#101.ext"
endif

			n "mod.#116.obj"
			t "-SYS_CLASS.h"
			f DATA
			o VLIR_BASE
			a "Markus Kanet"

:VlirJumpTable		jmp	xDISK_COPY

;*** Programmroutinen.
			t "-116_DCopyMnu"
			t "-116_DCopyJob"
			t "-116_StatusBox"

;*** Systemroutinen.
			t "-SYS_DISKFILE"
			t "-SYS_DISKMAXTR"
			t "-SYS_DISKNEXTSEK"
			t "-SYS_DISKNEWNAME"
			t "-SYS_HEX2ASCII"
			t "-SYS_INFOBOX"
			t "-SYS_STATMSG"

;*** Startadresse Kopierspeicher.
:Memory1
:Memory2		= (Memory1 / 256 +1)*256
:diskCopyBuf		= Memory2
:endCopyBuf		= OS_VARS

;******************************************************************************
;Sicherstellen das genügend Speicher
;für DiskCopy verfügbar ist.
			g OS_VARS -$2000
;******************************************************************************
