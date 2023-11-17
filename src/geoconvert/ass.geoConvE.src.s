; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;AutoAssembler Konfigurationsdatei.

if .p
			t "TopSym"
endif

			o $4000
			c "ass.SysFile V1.0"
			n "ass.geoConv.EN"
			f $04

:MainInit		b $f0,"src.geoConvert",$00
			b $f0,"src.DImgToFile",$00
			b $f0,"src.DImgToDisk",$00
			b $f0,"src.DImgCreate",$00
			b $f0,"src.ConvCVT",$00
			b $f0,"src.ConvUUE",$00
			b $f0,"src.ConvSEQ",$00
			b $f0,"src.MainMenu",$00

			b $f1
			lda	a1H			;Ziel-Laufwerk
			jsr	SetDevice		;aktivieren.
			jsr	OpenDisk		;Diskette öffnen.

			lda	#<:101			;Ziel-Datei löschen.
			sta	r0L
			lda	#>:101
			sta	r0H
			jsr	DeleteFile
			lda	#<:102			;Zeiger auf nächsten
			sta	a0L			;AutoAssembler-Befehl
			lda	#>:102			;setzen.
			sta	a0H
			rts				;Zurück zum AutoAssembler.

::101			b "geoConvert64.EN",$00

::102			b $f5
			b $f0,"lnk.geoConvert.E",$00
			b $ff

;Erlaubte Dateigröße: max.4096 Bytes
;Datenspeicher von $4000-$4fff
			g $4fff
