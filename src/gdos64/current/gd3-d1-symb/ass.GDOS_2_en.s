; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Systemlabels.
if .p
			t "ass.Includes"
			t "ass.Drives"
			t "ass.Macro"
			t "ass.Options"

;--- Sprache festlegen.
:LANG_DE		= $0110
:LANG_EN		= $0220
:LANG			= LANG_EN
endif

			n "ass.GDOS_2_en"
			c "ass.SysFile V1.0"
			t "opt.Author"
			f 4 ;SYSTEM
			z $40 ;GEOS64 oder GEOS128 40/80 Zeichen

			o $4000

			h "* AutoAssembler Systemdatei."
			h "Erstellt Laufwerkstreiber und Systemprogramme."

;--- Systemfunktionen.
:DO_SYS			t "-A3_Sys"

;--- Laufwrkstreiber.
:DO_DSK			t "-A3_Disk"

;--- Konfiguration.
:DO_CFG			t "-A3_Config"

;--- Programme.
:DO_PRG			t "-A3_Prog"

;--- GeoDesk64.
:DO_GDESK		t "-A3_GeoDesk"
			b $f4

;--- Build-Dateien löschen.
:DEL_BUILD		t "-A3_CleanUp"

;--- Ende.
:ALL_DONE		b $ff

;--- Erlaubte Dateigröße: 16384 Bytes.
;    Datenspeicher von $4000-$7fff.
			g $7fff
