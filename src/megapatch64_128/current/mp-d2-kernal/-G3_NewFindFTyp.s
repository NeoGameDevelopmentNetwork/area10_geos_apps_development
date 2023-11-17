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
			bcc	:51
			inc	r0H
::51			jsr	ClearRam		;Dateinamen-Tabelle löschen.
			jsr	Sub3_r6

			jsr	Get1stDirEntry		;Ersten DIR-Sektor lesen.
			txa				;Diskettenfehler ?
			bne	:58			;Ja, Abbruch...

::52			ldy	#$00
			lda	(r5L),y			;Datei-Eintrag vorhanden ?
			beq	:57			;Nein, weiter...

			ldy	#$16
			lda	r7L			;Dateityp einlesen.
			cmp	#255			;Alle Dateien einlesen ?
			beq	:53			;Ja, weiter...
			cmp	(r5L),y			;Gesuchter Dateityp ?
			bne	:57			;Nein, übergehen.

			jsr	CheckFileClass		;GEOS-Klasse vergleichen.
			txa				;Diskettenfehler ?
			bne	:58			;Ja, Abbruch...

			tya				;GEOS-Klasse OK ?
			bne	:57			;Nein, weiter...

::53			ldy	#$03
::54			lda	(r5L),y			;Dateinamen in Tabelle
			cmp	#$a0			;kopieren.
			beq	:55
			sta	(r6L),y
			iny
			cpy	#$13
			bne	:54

::55			clc				;Zeiger auf Position für
			lda	#$11			;Dateinamen in Tabelle
			adc	r6L			;korrigieren.
			sta	r6L
			bcc	:56
			inc	r6H

::56			dec	r7H			;Dateizähler -1.
			beq	:58			;Speicher voll ? Ja, Ende...

::57			jsr	GetNxtDirEntry		;Zeiger auf nächsten Eintrag.
			txa				;Diskettenfehler ?
			bne	:58			;Ja, Abbruch...
			tya				;Ende erreicht ?
			beq	:52			;Nein, weiter...
::58			plp
			rts

;*** Zeiger auf Ablagebereich korrigieren.
;FindFTypes und FindFile arbeiten mit einem Index der um
;3 Byte versetzt ist, deshalb muß die Zieladresse angepaßt werden.
:Sub3_r6		sec
			lda	r6L
			sbc	#$03
			sta	r6L
			bcs	:51
			dec	r6H
::51			rts

;*** GEOS-Klasse vergleichen.

if Flag64_128 = TRUE_C64
:CheckFileClass		lda	r10L
			ora	r10H
			tax				;xReg=$00, Kein Fehler...
			beq	:102			; => Kein Klasse, Ende...

			ldy	#$13
			lda	(r5L),y
			sta	r1L
			iny
			lda	(r5L),y
			sta	r1H
			jsr	Vec_fileHeader
			jsr	GetBlock
			txa
			bne	:104

			tay
::101			lda	(r10L),y
			beq	:102
			cmp	fileHeader+$4d,y
			bne	:103
			iny
			bne	:101

::102			ldy	#$00
			rts

::103			ldy	#$ff
::104			rts
endif

if Flag64_128 = TRUE_C128
:CheckFileClass		ldx	#$00
			lda	r10L
			ora	r10H
			bne	:1			;>Klasse angegeben

			lda	r7L			;GEOS-Filetyp
			cmp	#$05			;= Hilfsmittel?
			bne	:3			;>nein

::1			ldy	#$13			;>ja
			lda	(r5L),y
			sta	r1L
			iny
			lda	(r5L),y
			sta	r1H
			jsr	Vec_fileHeader
			jsr	GetBlock
			txa
			bne	:5			;>Diskfehler

			tay
			lda	r10L
			ora	r10H
			bne	:2

			jsr	TestgraphMode
			beq	:3
			ldx	#$00
			beq	:4

::2			lda	(r10L),y
			beq	:3
			cmp	fileHeader+$4d,y
			bne	:4
			iny
			bne	:2

::3			ldy	#$00
			rts

::4			ldy	#$ff
::5			rts
endif
