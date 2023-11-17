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
			n "ass.GeoDOS"
			f $04

:MainInit		OPEN_TARGET
			OPEN_SYMBOL

:MainInit1		t "-A3_Main"
			b $f4

:MainInit2		t "-A3_Copy"
			b $f4

:MainInit3		t "-A3_DOS"
			b $f4

:MainInit4		t "-A3_CBM"
			b $f4

:MainInit5		t "-A3_Convert"
			b $f4

:MainInit6		t "-A3_Tools"
			t "-A3_Help"

:MainInitX		t "-A3_CleanUp"

			b $ff
