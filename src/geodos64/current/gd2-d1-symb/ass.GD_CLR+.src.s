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
			t "ass.Options"
endif

			o $4000
			c "ass.SysFile V1.0"
			n "ass.GD_CLR"
			f $04

:MainInit		t "-A3_CleanUp"

			b $ff
