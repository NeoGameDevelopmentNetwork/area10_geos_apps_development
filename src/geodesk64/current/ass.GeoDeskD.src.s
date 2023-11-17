; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			o $4000
			c "ass.SysFile V1.0"
			n "ass.GeoDeskD"
			a "Markus Kanet"
			h "Steuerdatei für AutoAssembler-Modus des MegaAssembler V3."
			f $04

;b $f0,name,0		Datei für MegaAssembler/Linker angeben
;b $f1				Benutzerdefinierte Routine ausführen.
;				Am Ende in :a0 einen Zeiger auf das
;				nächste Befehlsbyte übergeben und die
;				Routine mit 'RTS' beenden.
;b $f2,DEVICE		Quelltext-Laufwerk wechseln (8-11).
;b $f5				Zum Linker wechseln.
;b $f4				Zum MegaAssembler wechseln.
;b $ff				AutoAssembler beenden.

:MainInit		b $f0,"GEODESK-LANG.de",$00
			b $f0,"s.mod.#100.boot",$00
			b $f0,"s.mod.#101",$00
			b $f0,"s.mod.#102",$00
			b $f0,"s.mod.#103",$00
			b $f0,"s.mod.#104",$00
			b $f0,"s.mod.#105",$00
			b $f0,"s.mod.#106",$00
			b $f0,"s.mod.#107",$00
			b $f0,"s.mod.#108",$00
			b $f0,"s.mod.#109",$00
			b $f0,"s.mod.#110",$00
			b $f0,"s.mod.#111",$00
			b $f0,"s.mod.#112",$00
			b $f0,"s.mod.#113",$00
			b $f0,"s.mod.#114",$00
			b $f0,"s.mod.#115",$00
			b $f0,"s.mod.#116",$00
			b $f0,"s.mod.#117",$00
			b $f0,"s.mod.#118",$00
			b $f0,"s.mod.#119",$00
			b $f0,"s.mod.#120",$00
			b $f0,"s.mod.#121",$00
			b $f0,"s.mod.#122",$00
			b $f0,"s.mod.#123",$00
			b $f5
			b $f0,"lnk.GeoDesk.de",$00
			b $ff

;Erlaubte Dateigroesse: 16384 Bytes
;Datenspeicher von $4000-$4fff
			g $4fff
