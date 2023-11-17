; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t	"TopSym"
			t	"TopMac"
			t	"src.geoDOS.ext"
			t	"mac.geoDOS"
endif

			n	"mod.#21.obj"

			o	ModCodeAdr
			b	"geoDOS",NULL

			jmp	DOStoCBM

			t	"src.FileExist"
			t	"copy.DOStoCBM"
