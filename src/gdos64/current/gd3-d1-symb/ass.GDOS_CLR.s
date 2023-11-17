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
;			t "ass.Options"

;--- Objektdateien löschen.
:DEL_OBJ_FILES		= TRUE

;--- Externe Symboldateien löschen.
:DEL_EXT_FILES		= TRUE

;--- Warnung ausgeben bei Dateifehler.
:DEL_ENABLE_WARN	= FALSE
endif

			n "ass.GDOS_CLR"
			c "ass.SysFile V1.0"
			t "opt.Author"
			f 4 ;SYSTEM
			z $40 ;GEOS64 oder GEOS128 40/80 Zeichen

			o $4000

			h "* AutoAssembler Systemdatei."
			h "Löscht Objekt- und Symboldateien."

;--- Dateien bereinigen.
			t "-A3_CleanUp"
			b $ff

;--- Erlaubte Dateigröße: 8192 Bytes.
;    Datenspeicher von $4000-$5fff.
			g $5fff
