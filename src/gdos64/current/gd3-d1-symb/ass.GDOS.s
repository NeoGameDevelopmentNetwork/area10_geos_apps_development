; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** AutoAssembler.

			n "ass.GDOS"
			c "ass.SysFile V1.0"
			t "opt.Author"
			f 4 ;SYSTEM
			z $40 ;GEOS64 oder GEOS128 40/80 Zeichen

			o $4000

			h "* AutoAssembler Systemdatei."
			h "Erstellt Systemdateien für MegaAssembler."

;*** AutoAssembler Dateien erstellen.
:MAIN__1		b $f0,"ass.GDOS_1_de.s",$00	;GDOS Teil#1de: Kernal.
			b $f0,"ass.GDOS_1_en.s",$00	;GDOS Teil#1en: Kernal.
			b $f0,"ass.GDOS_2_de.s",$00	;GDOS Teil#2de: System+GeoDesk.
			b $f0,"ass.GDOS_2_en.s",$00	;GDOS Teil#2en: System+GeoDesk.

			b $f0,"ass.GDOS_SYS.s",$00	;Nur Ext.Kernal-Routinen.
			b $f0,"ass.GDOS_DSK.s",$00	;Nur Laufwerkstreiber.
			b $f0,"ass.GDOS_CFG.s",$00	;Nur GD.CONFIG/GD.UPDATE.
			b $f0,"ass.GDOS_PRG.s",$00	;Nur Programme.
			b $f0,"ass.GDOS_GDK.s",$00	;Nur GeoDesk64.

			b $f0,"ass.GDOS_CLR.s",$00	;Objekt-/Symboldateien löschen.
			b $ff

;--- Erlaubte Dateigröße: 8192 Bytes.
;    Datenspeicher von $4000-$5fff.
			g $5fff
