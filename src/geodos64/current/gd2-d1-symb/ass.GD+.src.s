; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Systemlabels.
if .p
			t "src.GEOS_MP3.64"
			t "SymbTab_1"
			t "SymbTab_2"
			t "SymbTab64"
			t "TopMac"
			t "ass.Drives"
			t "ass.Macro"
endif

			n "ass.GD"
			c "ass.SysFile V1.0"
			a "Markus Kanet"
			f $04

			o $4000

;*** AutoAssembler Dateien erstellen.
:MAIN__1		OPEN_SYMBOL

			b $f0,"ass.GeoDOS+.src",$00
			b $f0,"ass.GD_MAIN+.src",$00
			b $f0,"ass.GD_COPY+.src",$00
			b $f0,"ass.GD_DOS+.src",$00
			b $f0,"ass.GD_CBM+.src",$00
			b $f0,"ass.GD_CONV+.src",$00
			b $f0,"ass.GD_TOOL+.src",$00
			b $f0,"ass.GD_HELP+.src",$00
			b $f0,"ass.GD_CLR+.src",$00
			b $ff
