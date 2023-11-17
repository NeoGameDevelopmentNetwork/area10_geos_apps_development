; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			o $4000
			c "ass.SysFile V1.0"
			n "ass.MegaAss"
			a "Markus Kanet"
			h "Steuerdatei für AutoAssembler-Modus des MegaAssembler V3+"
			f $04

;b $f0,name,0		Datei für MegaAssembler/Linker angeben
;b $f1				Benutzerdefinierte Routine ausführen.
;				Am Ende in :a0 einen Zeiger auf das
;				nächste Befehlsbyte übergeben und die
;				Routinee mit 'RTS' beenden.
;b $f2,DEVICE		Quelltext-Laufwerk wechseln (8-11).
;b $f4				Zum Linker wechseln.
;b $f5				Zum MegaAssembler wechseln.
;b $ff				AutoAssembler beenden.

:MainInit		b $f0,"src.MegaAss0",$00
			b $f0,"src.MegaAss1",$00
			b $f0,"src.MegaAss2",$00
			b $f0,"src.MegaAss3",$00
			b $f0,"src.MegaAss4",$00
			b $f0,"src.MegaAss5",$00
			b $f0,"src.MegaAss6",$00
			b $f5
			b $f0,"lnk.MegaAss",$00
			b $ff

;Erlaubte Dateigröße: 8192 Bytes
;Datenspeicher von $4000-$5fff
			g $6000
