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
;          uPathDisk    = Verzeichnispfad zum DiskImage
;                         NULL: Nicht definiert
:getConfigDir		lda	dirEntryBuf +22
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

;--- Hinweis:
;Angabe Verzeichnis ist Optional...
;			lda	fileHeader +160		;Verzeichnispfad?
;			cmp	#"/"
;			bne	:exit			; => Nein, Ungültig...

			ldy	#0			;Pfad kopieren.
::loop			lda	fileHeader +160,y
			beq	:done
			cmp	#CR
			beq	:done
			sta	uPathDir,y
			iny
			cpy	#96			;Max. Länge erreicht?
			bcc	:loop			; => Nein, weiter...

::done			rts

;*** Pfad in Ultimate zum Verzeichnis.
:uPathDir		s 96
