; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** AutoAssembler.

			n "ass.geoULibStd"
			c "ass.SysFile V1.0"

			a "Markus Kanet"

			f 4 ;SYSTEM

			z $40 ;GEOS 40/80-Zeichen.

			o $4000

			h "* AutoAssembler Systemdatei."
			h "Erstellt Demo-Anwendungen für geoULib."

;*** AutoAssembler Dateien erstellen.
:MAIN__1		b $f0,"ext.BuildMod.Std",$00
			t "ass.geoULib.inc"

;--- Erlaubte Dateigröße: 8192 Bytes.
;    Datenspeicher von $4000-$5fff.
			g $5fff
