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
endif

			n "ass.GDOS_CFG"
			c "ass.SysFile V1.0"
			t "opt.Author"
			f 4 ;SYSTEM
			z $40 ;GEOS64 oder GEOS128 40/80 Zeichen

			o $4000

			h "* AutoAssembler Systemdatei."
			h "Erstellt Systemprogramme."

;--- Konfiguration.
:MAIN			t "-A3_Config"
			b $ff

;--- Erlaubte Dateigröße: 8192 Bytes.
;    Datenspeicher von $4000-$5fff.
			g $5fff
