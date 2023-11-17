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
			bne	:0			;Nein, Treiber auf Disk suchen.
			lda	r6L
			cmp	#<PrntFileName
			bne	:0

			jsr	TestPrntFile		;Druckertreiber suchen ?
			beq	:7			;Ja, weiter...

::0			jsr	Sub3_r6
			jsr	Get1stDirEntry		;Erster DIR-Sektor lesen.
			txa				;Diskettenfehler ?
			bne	:8			;Ja, Abbruch.

::1			tay				;yReg=$00.
			lda	(r5L),y			;Gelöschter Eintrag ?
			beq	:4			;Ja, weiter...

			ldy	#$03
::2			lda	(r6L),y			;Dateinamen vergleichen.
			beq	:3
			cmp	(r5L),y
			bne	:4			; -> Falsche Datei,...
			iny
			bne	:2
::3			cpy	#$13
			beq	:5			; -> Richtige Datei...
			lda	(r5L),y
			iny
			cmp	#$a0
			beq	:3

::4			jsr	GetNxtDirEntry		;Zeiger auf nächsten Eintrag.
			txa				;Diskettenfehler ?
			bne	:8			;Ja, Abbruch...
			tya				;Verzeichnis-Ende erreicht ?
			beq	:1			;Nein, weiter...
			ldx	#$05			;Fehler: "File not found"
			bne	:8

::5			ldy	#29
::6			lda	(r5L)      ,y		;Datei-Eintrag kopieren.
			sta	dirEntryBuf,y
			dey
			bpl	:6

::7			ldx	#$00			;Kein Fehler...
::8			plp
			rts
