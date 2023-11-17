; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Hinweis:
;Routinen für den Menu-Screenbuffer:
;Das erste Byte ist immer $00 und
;kennzeichnet den Anfang des Screen-
;buffer. Werte von $01-$7f stehen für
;gepackte $00-Bytes, Werte von $81-$ff
;stehen für ungepackte Grafikdaten.
;Die Bildschirmgrafik wird zeilenweise
;in den Screenbuffer kopiert, gepackt
;werden die Daten aber durchgehend.

;*** Zeiger auf Recover-Daten für RecoverVec.
:curRecoverArea		b $00				;$ff = Hintergrund ungültig.

:u_RecoverVec		ldx	curRecoverArea
			cpx	#$ff
			beq	:exit

			cpx	#$20			;Datei/Info?
			bne	:1			; => Nein, weiter...

			jsr	prntCurPadPage

			ldx	#$20

::1			txa
			pha
			jsr	drawDeskPadCol
			jsr	drawDeskPadICol
			pla
			tax
			jsr	getScreenFromBuf

			ldx	curRecoverArea
			cpx	#$20			;Datei/Info?
			bne	:2			; => Nein, weiter...

			jsr	updInfoScreen

::2			lda	#$ff
			sta	curRecoverArea

::exit			rts

;*** Bildschirm in Puffer speichern.
.putScreenToBuf		stx	curRecoverArea
			jsr	setRecVecData
			jsr	mv_r1_r7_inc_r1
			ldy	#$00
			tya				;Kennbyte für Anfang
			sta	(r7L),y			;Screenbuffer.
			beq	doScreenBufJob

;*** Bildschirm aus Puffer laden.
:getScreenFromBuf	jsr	setRecVecData
			jsr	mv_r1_r7_inc_r1
			lda	#$ff

:doScreenBufJob		sta	r4H

::loop			ldx	r2H
			jsr	GetScanLine

			lda	r2L
			asl
			asl
			asl
			bcc	:1
			inc	r5H

::1			tay				;Zeiger auf Byte.

			lda	r3L
			sta	r4L

::next			bit	r4H			;putScreen2Buf?
			bpl	:2			; => Ja, weiter...

			jsr	jobScrnBufRead
			clv
			bvc	:3

::2			jsr	jobScrnBufWrite

::3			clc				;Zeiger auf nächstes
			adc	#$08			;Char berechnen.
			bcc	:4
			inc	r5H

::4			tay
			dec	r4L			;Alle Chars kopiert?
			bne	:next			; => Nein, weiter...

			inc	r2H
			dec	r3H			;Letzte Zeile?
			bne	:loop			; => Nein, weiter...

			rts

:mv_r1_r7_inc_r1	jsr	move_r1_r7

;*** Word in r1 +1.
:incW_r1		inc	r1L
			bne	:1
			inc	r1H
::1			rts

;*** Word in r1 nach r7 kopieren.
:move_r1_r7		lda	r1H
			sta	r7H
			lda	r1L
			sta	r7L
			rts

;*** Grafikdaten in Puffer schreiben.
;Übergabe: r1 = Zeiger auf Screenbuffer.
;          r5 = Zeiger auf Vordergrundbildschirm.
;          r7 = Zeiger auf aktuellen Block.
;               $00    : Anfang Puffer-Speicher.
;               $01-$7f: 1-127 $00-Grafikbytes.
;               $81-$ff: 1-127 Grafikbytes.
:jobScrnBufWrite	tya
			pha

			lda	r1H
			cmp	#> dirDiskBuf
			bcs	:buf_full

			lda	(r5L),y
			ldy	#$00
			tax				;$00-Grafikyte?
			bne	:next			; => Nein, weiter...

			lda	(r7L),y			;$00-Packer aktiv?
			bmi	:new_NULL		; => Nein, weiter...
			cmp	#%01111111		;Max. 127 $00-Bytes?
			bne	:updCount		; => Nein, weiter...

::new_NULL		jsr	mv_r1_r7_inc_r1
			lda	#$00			;Gepackte $00-Bytes.
			sta	(r7L),y			;Bytezähler setzen.
			beq	:updCount

::next			lda	(r7L),y			;$00-Packer aktiv?
			bpl	:new_GRFX		; => Ja, weiter...
			cmp	#%11111111		;127 Grafikbytes?
			beq	:new_GRFX		; => Neuer Block.

::write			txa				;Byte aus Bildschirm
			sta	(r1L),y			;in Puffer schreiben.
			jsr	incW_r1			;Zeiger auf nächstes
			clv				;Byte in Puffer.
			bvc	:updCount

::new_GRFX		jsr	mv_r1_r7_inc_r1

			lda	#%10000000		;Ungepackte Daten.
			sta	(r7L),y
			lda	r1H
			cmp	#> dirDiskBuf
			bcs	:buf_full		; => Puffer voll.
			clv
			bvc	:write

::updCount		lda	(r7L),y			;Byte-Zähler für
			clc				;aktuellen Block +1.
			adc	#$01
			sta	(r7L),y

::buf_full		pla
			rts

;*** Grafikdaten aus Puffer einlesen.
:jobScrnBufRead		tya
			pha

::1			ldy	#$00
			lda	(r7L),y			;Block-Code einlesen.
			and	#%01111111		;$00/$80?
			bne	:new_stream		; => Nein, weiter...
			jsr	mv_r1_r7_inc_r1
			clv				;Weiter mit nächstem
			bvc	:1			;Grafikblock.

::new_stream		ldx	#$00			;Bei "Buffer full"
			lda	r1H			;Bildschirm löschen.
			cmp	#> dirDiskBuf
			beq	:write

			lda	(r7L),y			;Ungepackte Daten?
			bmi	:unpacked		; => Ja, weiter...
::packed		lda	#$00			;$00-Grafikbyte.
			beq	:updCount

::unpacked		lda	(r1L),y			;Grafikbyte einlesen
			pha				;und Zeiger auf das
			jsr	incW_r1			;nächste Byte setzen.
			pla

::updCount		tax				;Grafikbyte.

			lda	(r7L),y			;Byte-Zähler für
			sec				;aktuellen Block -1.
			sbc	#$01
			sta	(r7L),y

::write			pla
			tay
			txa				;Byte in Bildschirm
			sta	(r5L),y			;schreiben.
			tya
			rts

;*** Datenbereich für Recover-Routine setzen.
:setRecVecData		txa
			pha

			lda	#> tempDataBuf
			sta	r1H
			lda	#< tempDataBuf
			sta	r1L

			ldy	#0
::1			lda	tabRecoverData,x
			sta	r2,y
			inx
			iny
			cpy	#4
			bne	:1

			pla
			tax
			rts

;*** Daten für Recover-Routine.
;Tabellenaufbau:  b xCardLeft  ,yPixelTop
;                 b xCardWidth ,yPixelHeight
:tabRecoverData

;Der Bereich der Standard-Dialogbox.
::menuDataDBOX		b $08,$20,$19,$68		;Dialogbox.

;GEOS-Menüdaten werden modifiziert!
:menuDataGEOS
if LANG = LANG_DE
			b   0,$0c,12 +1,$3a		;GEOS-Menü.
			b   4,$0c,11 +1,$64		;Menü Datei.
			b   7,$0c, 8 +1,$4c		;Menü Anzeige.
			b  12,$0c,11 +1,$64		;Menü Diskette.
			b  17,$0c,14 +1,$2c		;Menü Auswahl.
			b  21,$0c, 9 +1,$1e		;Menü Seite.
			b  24,$0c, 8 +1,$3e		;Menü Optionen.
endif
if LANG = LANG_EN
			b   0,$0c,10 +1,$3a		;GEOS-Menü.
			b   4,$0c,11 +1,$64		;Menü Datei.
			b   6,$0c, 6 +1,$4c		;Menü Anzeige.
			b  10,$0c, 8 +1,$64		;Menü Diskette.
			b  13,$0c,10 +1,$2c		;Menü Auswahl.
			b  17,$0c, 8 +1,$1e		;Menü Seite.
			b  20,$0c, 9 +1,$3e		;Menü Optionen.
endif

;Der Bereich der Datei/Info-Dialogbox
;unterhalb der Dateien im DeskPad.
			b  AREA_INFOBOX_X0/8
			b  AREA_FILEPAD_Y1+1
			b (AREA_INFOBOX_X1-AREA_INFOBOX_X0+1)/8+1
			b  AREA_INFOBOX_Y1-AREA_FILEPAD_Y1+5
