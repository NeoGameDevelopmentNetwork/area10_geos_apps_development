; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** AutoAssembler.

			n "ass.G3_64"
			c "ass.SysFile V1.0"
			t "G3_Sys.Author"
			h "* AutoAssembler Systemdatei."
			h "Erstellt Systemdateien für MegaAssembler."
			f $04

			o $4000

;*** AutoAssembler Dateien erstellen.
:MAIN__1		b $f0,"ass.G3_64_1.s",$00	;Kernal.
			b $f0,"ass.G3_64_2.s",$00	;Prog., ext.Kernal und Treiber.
			b $f0,"ass.G3_64_DSK.s",$00	;Nur System-Laufwerkstreiber.
			b $f0,"ass.G3_64_DRV.s",$00	; -> Laufwerkstreiber.
			b $f0,"ass.G3_64_INI.s",$00	; -> Init für GD.DISK.
			b $f0,"ass.G3_64_DAP.s",$00	; -> Anwendungstreiber.
			b $f0,"ass.G3_64_SYS.s",$00	;Nur Ext.Kernal-Routinen.
			b $f0,"ass.G3_64_PRG.s",$00	;Nur Programme.
			b $f0,"ass.G3_64_CFG.s",$00	;Nur GD.CONFIG/GD.UPDATE.
			b $f0,"ass.G3_64_CLR.s",$00	;Objekt-/Symboldateien löschen.
			b $ff
