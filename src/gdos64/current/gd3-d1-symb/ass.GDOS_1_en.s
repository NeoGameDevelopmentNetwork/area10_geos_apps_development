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
endif

			n "ass.GDOS_1_en"
			c "ass.SysFile V1.0"
			t "opt.Author"
			f 4 ;SYSTEM
			z $40 ;GEOS64 oder GEOS128 40/80 Zeichen

			o $4000

			h "* AutoAssembler Systemdatei."
			h "Erstellt komprimierten MegaPatch-Kernal."

;--- Systemsprache.
:GDOS_1			OPEN_SYMBOL
			b $f0,"opt.GDOSl10n.en",$00

;--- GDOS-Kernal.
			t "-A3_Kernal"
			b $ff

;--- Erlaubte Dateigröße: 8192 Bytes.
;    Datenspeicher von $4000-$5fff.
			g $5fff
