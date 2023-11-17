; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Systemlabels.
if .p
			t "src.GEOS_MP3.128"
			t "SymbTab_1"
			t "SymbTab_2"
			t "SymbTab_3"
			t "SymbTab128"
			t "MacTab"
			t "ass.Drives"
			t "ass.Macro"
			t "ass.Options"
endif

			n "ass.MP128_2"
			c "ass.SysFile V1.0"
			a "Markus Kanet"
			h "* AutoAssembler Systemdatei."
			h "Erstellt Laufwerkstreiber und Systemprogramme."
			f $04

			o $4000

:COMP_SYS		= TRUE_C128

			t "-A3_Sys"
			t "-A3_Prog"
			t "-A3_Disk"
			t "-A3_CleanUp"
			b $ff
