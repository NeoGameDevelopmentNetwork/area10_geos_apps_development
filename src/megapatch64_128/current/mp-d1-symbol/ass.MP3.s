; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** AutoAssembler.

			n "ass.MP3"
			c "ass.SysFile V1.0"
			a "Markus Kanet"
			h "* AutoAssembler Systemdatei."
			h "Erstellt Systemdateien für MegaAssembler."
			f $04

			o $4000

;*** AutoAssembler Dateien erstellen.
:MAIN__1		b $f0,"ass.MP64_1.s",$00
			b $f0,"ass.MP64_2.s",$00
			b $f0,"ass.MP64_DSK.s",$00
			b $f0,"ass.MP64_SYS.s",$00
			b $f0,"ass.MP64_PRG.s",$00
			b $f0,"ass.MP128_1.s",$00
			b $f0,"ass.MP128_2.s",$00
			b $f0,"ass.MP128_DSK.s",$00
			b $f0,"ass.MP128_SYS.s",$00
			b $f0,"ass.MP128_PRG.s",$00
			b $ff
