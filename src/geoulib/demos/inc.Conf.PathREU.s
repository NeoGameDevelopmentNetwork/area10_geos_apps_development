; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Konfiguration aus Infoblock einlesen.
;Übergabe: dirEntryBuf  = Verzeichnis-Eintrag
;Rückgabe: geosRAMDisk  = GEOS-Laufwerk A bis D
;                         NULL: Nicht definiert
;          geosDriveAdr = GEOS-Laufwerk 8 bis 11
;                         NULL: Nicht definiert
;          uPathRDisk   = Verzeichnispfad zum RAMDiskImage
;                         NULL: Nicht definiert
:getConfigREU		lda	dirEntryBuf +22
			cmp	#APPLICATION		;Anwendung?
			beq	:1			; => Ja, weiter...
			cmp	#AUTO_EXEC		;AutoExec?
			beq	:1			; => Ja, weiter...
::exit			rts

::1			lda	dirEntryBuf +19		;Infoblock vorhanden?
			beq	:exit			; => Nein, Abbruch...

;Hinweis:
;Infoblock wird vom GEOS-Kernal über
;GetFile eingelesen!
if FALSE
			sta	r1L
			lda	dirEntryBuf +20
			sta	r1H

			lda	#< fileHeader
			sta	r4L
			lda	#> fileHeader
			sta	r4H

			jsr	GetBlock		;Infoblock einlesen.
			txa				;Fehler?
			bne	:exit			; => Nein, weiter...
endif

			lda	fileHeader +160		;GEOS-Laufwerk A bis D auswerten.
			cmp	#"A"
			bcc	:exit			; => Ungültig...
			cmp	#"D" +1
			bcs	:exit			; => Ungültig...

			ldx	fileHeader +161		;Trennzeichen?
			cpx	#":"
			bne	:exit			; => Ungültig...

;--- Hinweis:
;Angabe Verzeichnis ist Optional...
;			ldx	fileHeader +162		;Verzeichnispfad?
;			cpx	#"/"
;			bne	:exit			; => Nein, Ungültig...

			tay
			sec
			sbc	#"A" -8
			tax
			lda	driveType -8,x		;Ziel-Laufwerk = RAMDisk?
			bpl	:exit			; => Nein, Abbruch...

			sty	geosRAMDisk		;GEOS-Laufwerk A bis D.
			stx	geosDriveAdr		;GEOS-Laufwerk 8 bis 11.

			ldy	#0			;Pfad kopieren.
::loop			lda	fileHeader +160 +2,y
			beq	:done
			cmp	#CR
			beq	:done
			sta	uPathRDisk,y
			iny
			cpy	#96 -2			;Max. Länge -2 (A:) erreicht?
			bcc	:loop			; => Nein, weiter...

::done			rts

;*** Pfad in Ultimate zum RAMDiskImage.
:uPathRDisk		s 96
