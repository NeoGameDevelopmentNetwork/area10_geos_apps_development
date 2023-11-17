; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Datei suchen.
;    Wenn der aktive Druckertreiber kopiert werden soll, zeigt ":r6" nicht
;    auf ":PrntFileName" und FindFile sucht die datei auf Diskette.
;    Zeigt ":r6" jedoch auf ":PrntFileName", dann soll der aktive Drucker-
;    treiber gesucht werden (z.B. beim Start von GeoWrite um die Seitenlänge
;    festzulegen...). In diesem Fall mit xReg = $00 beenden.
:xFindFile		php
			sei

			lda	r6H			;Suche nach aktuellem Drucker-
			cmp	#>PrntFileName		;treiber in ":PrntFileName" ?
			bne	:50			;Nein, Treiber auf Disk suchen.
			lda	r6L
			cmp	#<PrntFileName
			bne	:50

			jsr	TestPrntFile		;Druckertreiber suchen ?
			beq	:57			;Ja, weiter...

::50			jsr	Sub3_r6
			jsr	Get1stDirEntry		;Erster DIR-Sektor lesen.
			txa				;Diskettenfehler ?
			bne	:58			;Ja, Abbruch.

::51			tay				;yReg=$00.
			lda	(r5L),y			;Gelöschter Eintrag ?
			beq	:54			;Ja, weiter...

			ldy	#$03
::52			lda	(r6L),y			;Dateinamen vergleichen.
			beq	:53
			cmp	(r5L),y
			bne	:54			; -> Falsche Datei,...
			iny
			bne	:52
::53			cpy	#$13
			beq	:55			; -> Richtige Datei...
			lda	(r5L),y
			iny
			cmp	#$a0
			beq	:53

::54			jsr	GetNxtDirEntry		;Zeiger auf nächsten Eintrag.
			txa				;Diskettenfehler ?
			bne	:58			;Ja, Abbruch...
			tya				;Verzeichnis-Ende erreicht ?
			beq	:51			;Nein, weiter...
			ldx	#$05			;Fehler: "File not found"
			bne	:58

::55			ldy	#29
::56			lda	(r5L)      ,y		;Datei-Eintrag kopieren.
			sta	dirEntryBuf,y
			dey
			bpl	:56

::57			ldx	#$00			;Kein Fehler...
::58			plp
			rts
