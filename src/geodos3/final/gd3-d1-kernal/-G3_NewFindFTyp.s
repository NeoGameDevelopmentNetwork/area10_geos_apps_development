; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Dateitypen suchen.
;    Neuer Dateityp #255 zeigt alle Dateien an!
:xFindFTypes		php
			sei

			lda	r6H			;Zeiger auf Tabelle für
			sta	r1H			;Dateinamen.
			lda	r6L
			sta	r1L

			lda	#$00			;Größe der Tabelle für
			sta	r0H			;Dateinamen berechnen.

			lda	r7H
			asl
			rol	r0H
			asl
			rol	r0H
			asl
			rol	r0H
			asl
			rol	r0H
			adc	r7H
			sta	r0L
			bcc	:1
			inc	r0H
::1			jsr	ClearRam		;Dateinamen-Tabelle löschen.
			jsr	Sub3_r6

			jsr	Get1stDirEntry		;Ersten DIR-Sektor lesen.
			txa				;Diskettenfehler ?
			bne	:8			;Ja, Abbruch...

::2			ldy	#$00
			lda	(r5L),y			;Datei-Eintrag vorhanden ?
			beq	:7			;Nein, weiter...

			ldy	#$16
			lda	r7L			;Dateityp einlesen.
			cmp	#255			;Alle Dateien einlesen ?
			beq	:3			;Ja, weiter...
			cmp	(r5L),y			;Gesuchter Dateityp ?
			bne	:7			;Nein, übergehen.

			jsr	CheckFileClass		;GEOS-Klasse vergleichen.
			txa				;Diskettenfehler ?
			bne	:8			;Ja, Abbruch...

			tya				;GEOS-Klasse OK ?
			bne	:7			;Nein, weiter...

::3			ldy	#$03
::4			lda	(r5L),y			;Dateinamen in Tabelle
			cmp	#$a0			;kopieren.
			beq	:5
			sta	(r6L),y
			iny
			cpy	#$13
			bne	:4

::5			clc				;Zeiger auf Position für
			lda	#$11			;Dateinamen in Tabelle
			adc	r6L			;korrigieren.
			sta	r6L
			bcc	:6
			inc	r6H

::6			dec	r7H			;Dateizähler -1.
			beq	:8			;Speicher voll ? Ja, Ende...

::7			jsr	GetNxtDirEntry		;Zeiger auf nächsten Eintrag.
			txa				;Diskettenfehler ?
			bne	:8			;Ja, Abbruch...
			tya				;Ende erreicht ?
			beq	:2			;Nein, weiter...
::8			plp
			rts

;*** Zeiger auf Ablagebereich korrigieren.
;FindFTypes und FindFile arbeiten mit einem Index der um
;3 Byte versetzt ist, deshalb muß die Zieladresse angepaßt werden.
:Sub3_r6		sec
			lda	r6L
			sbc	#$03
			sta	r6L
			bcs	:1
			dec	r6H
::1			rts

;*** GEOS-Klasse vergleichen.
:CheckFileClass		lda	r10L
			ora	r10H
			tax				;xReg=$00, Kein Fehler...
			beq	:2			; => Kein Klasse, Ende...

			ldy	#$13
			lda	(r5L),y
			sta	r1L
			iny
			lda	(r5L),y
			sta	r1H
			jsr	Vec_fileHeader
			jsr	GetBlock
			txa
			bne	:4

			tay
::1			lda	(r10L),y
			beq	:2
			cmp	fileHeader+$4d,y
			bne	:3
			iny
			bne	:1

::2			ldy	#$00
			rts

::3			ldy	#$ff
::4			rts
