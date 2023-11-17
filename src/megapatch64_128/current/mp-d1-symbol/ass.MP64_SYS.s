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
			t "SymbTab_3"
			t "SymbTab64"
			t "MacTab"
			t "ass.Drives"
			t "ass.Macro"
			t "ass.Options"

;--- Auswertung Bildschirm-Modus C128.
:graphMode		= $003f
endif

			n "ass.MP64_SYS"
			c "ass.SysFile V1.0"
			h "* AutoAssembler Systemdatei."
			h "Erstellt Systemprogramme."
			a "Markus Kanet"
			f $04

			o $4000

:COMP_SYS		= TRUE_C64

			t "-A3_Sys"
			b $ff
