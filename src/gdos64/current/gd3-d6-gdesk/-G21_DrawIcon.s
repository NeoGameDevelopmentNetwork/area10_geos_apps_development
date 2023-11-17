; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Datei-Icon mit Dateiname ausgeben.
;    Übergabe: r0  = Zeiger auf Icon.
;              r1L = X-Koordinate (CARDs)
;              r1H = Y-Koordinate (Pixel)
;              r2L = Breite (CARDs)
;              r2H = Höhe (Pixel)
;              r3L = Farbe
;              r3H = DeltaY
;              r4  = Zeiger auf Dateiname.
;                    (Ende mit $00- oder $A0-Byte, max. 16 Zeichen)
;              r8  = Zeiger auf Farbtabelle (3x3 CARDs)
;    Hinweis: Die Register r1L bis r3L werden nicht verändert.
.GD_FICON_NAME		ldx	#r1L			;PUSH-Befehle durch Schleife
::0			lda	zpage,x			;ersetzt -> Code-Reduktion.
			pha				;Icon-Daten sichern und
			inx	 			;Zeiger auf Dateiname retten.
			cpx	#r4H +1
			bcc	:0

			jsr	GD_DRAW_FICON		;Datei-Icon darstellen.

			PopB	r0H			;Zeiger auf Dateiname zurücksetzen.
			PopB	r0L
			PopB	r3H 			;DeltaY zurüsetzen.

			txa				;Wurde Icon teilweise ausgegeben ?
			bne	:4			; => Nein, Ende...

;--- Textbreite für zentrierte Ausgabe berechnen.
			ldy	#$00
			sty	r4L			;Textbreite löschen.
			sty	r4H
::1			sty	:2 +1			;Zeiger sichern.
			lda	(r0L),y			;Zeichen einlesen. Ende erreicht ?
			beq	:3			; => Ja, weiter...
			cmp	#$a0			;Ende erreicht ?
			beq	:3			; => Ja, weiter...
			and	#%01111111		;Unter GEOS nur Zeichen $20-$7E.
			cmp	#$20			;ASCII < $20?
			bcc	:2			; => Ja, ignorieren...
			cmp	#$7f			;ASCII >= $7f?
			bcs	:2			; => Ja, ignorieren...
			ldx	currentMode
			jsr	GetRealSize		;Zeichenbreite ermitteln und
			tya				;zur Gesamtbreite addieren.
			clc
			adc	r4L
			sta	r4L
			bcc	:2
			inc	r4H
::2			ldy	#$ff
			iny				;Zeiger auf nächstes Zeichen.
			cpy	#16			;Dateiname ausgegeben ?
			bne	:1			; => Nein, weiter...

::3			lsr	r4H			;Textbreite halbieren.
			ror	r4L

			lda	#$00			;Startposition für Textausgabe
			sta	r11H			;berechnen.
			lda	r1L
			asl
			asl
			asl
			sta	r11L
			rol	r11H
			AddVW	12,r11			;Zeiger auf Mitte des Datei-Icons.

			lda	r11L			;Textposition nach links
			sec				;versetzen => Zentrierte Ausgabe.
			sbc	r4L
			sta	r11L
			lda	r11H
			sbc	r4H
			sta	r11H

			lda	r1H			;Y-Koordinate für
			clc				;Textausgabe berechnen.
			adc	#25			;3 CARDs + 1 Pixelzeile.
			clc
			adc	r3H
			sta	r1H

			jsr	smallPutString		;Dateiname ausgeben.
			ldx	#NO_ERROR

::4			ldx	#r3L			;Icon-Daten wieder
::5			pla				;zurücksetzen.
			sta	zpage,x
			dex
			cpx	#r1L
			bcs	:5

			rts

;*** Datei-Icon ausgeben (63-Byte-Format).
;    Übergabe: r0  = Zeiger auf Icon.
;              r1L = X-Koordinate (CARDs)
;              r1H = Y-Koordinate (Pixel)
;              r2L = Breite (CARDs)
;              r2H = Höhe (Pixel)
;              r3L = Farbe
;              r8  = Zeiger auf Farbtabelle (3x3 CARDs)
.GD_DRAW_FICON		lda	r1L			;Ist Icon innerhalb des
			asl				;sichtbaren Bereichs ?
			asl
			asl
			sta	r4L
			lda	#$00
			rol
			sta	r4H
			cmp	rightMargin +1
			bne	:1
			lda	r4L
			cmp	rightMargin +0
::1			beq	:2			; => Ja, weiter...
			bcs	:3			; => Nein, Ende...

::2			lda	r1H			;Ist Icon innerhalb des
			cmp	windowBottom		;sichtbaren Bereichs ?
			bcc	:4			; => Ja, weiter...
			ldx	#$7f
			rts
::3			ldx	#$ff			;Icon nicht dargestellt, Ende...
			rts

;--- Byte aus Icon-Daten einlesen.
::read_icon_data	lda	$ffff,x
			inx
			rts

;--- Tabelle mit Daten zur CARD-Ausgabe.
;Hinweis: Ursprünglich konnten am
;Zeilenende auch halbe Icons angezeigt
;werden. Aktuell werden Icons am Ende
;aber nur noch angezeigt wenn genügend
;platz vorhanden ist. Es mus also nicht
;mehr auf 2/3 oder 3/3 getestet werden.
;Bit #6=1 -> Card 2 ausgeben.
;Bit #7=1 -> Card 3 ausgeben.
;::card_info		b $00,$00,$40,$c0

;--- Position im Grafikspeicher berechnen.
::4			ldx	r1H			;Zeiger auf erstes Byte in Zeile
			jsr	GetScanLine		;des Grafikspeichers berechnen.

			lda	r4L			;Zeiger auf erstes Byte für
			clc				;Icon berechnen.
			adc	r5L
			sta	r5L
			lda	r4H
			adc	r5H
			sta	r5H

::5			lda	rightMargin +1		;Breite des Icons reduzieren,
			lsr				;falls rechter Rand überschritten
			lda	rightMargin +0		;wird.
			ror
			lsr
			lsr
			tax
			inx
			stx	:6 +1
			stx	:7 +1

			lda	r1L
			clc
			adc	r2L
::6			cmp	#40
			beq	:8
			bcc	:8
::7			lda	#40			;Max. mögliche Breite berechnen.
			sec
			sbc	r1L
			sta	r2L
::8			lda	r2L			;Breite = $00 ?
			beq	:3			; => Ja, Ende...

			ldx	windowBottom		;Höhe des Icons reduzieren,
			inx				;falls unterer Rand überschritten
			stx	:9 +1			;wird.
			stx	:a +1

			lda	r1H
			clc
			adc	r2H
::9			cmp	#200
			beq	:b
			bcc	:b
::a			lda	#200			;Max. mögliche Höhe berechnen.
			sec
			sbc	r1H
			sta	r2H
::b			lda	r2H			;Neue Icon-Höhe einlesen und
			sta	r4H			;zwischenspeichern. Höhe = $00 ?
			beq	:3			; => Ja, Ende...

;--- Zeiger auf Icon-Daten.
			lda	r0L			;Zeiger auf Icon-Daten setzen.
			clc				;$BF-Code übergehen und
			adc	#$01			;Zeiger kopieren.
			sta	:read_icon_data +1
			lda	r0H
			adc	#$00
			sta	:read_icon_data +2

;--- Ergänzung: 20.08.05 M.Kanet
;Hinweis: Nur ganze Icons ausgeben.
;			ldx	r2L			;Flag für die zu beschreibenden
;			lda	:card_info,x		;CARDs einlesen.
;			sta	r4L

;--- Icon zeichnen.
			ldx	#$00
::c			lda	r5L			;Zeiger auf Card #2 berechnen.
			clc
			adc	#$08
			sta	r6L
			lda	r5H
			adc	#$00
			sta	r6H

			lda	r6L			;Zeiger auf Card #3 berechnen.
			clc
			adc	#$08
			sta	r7L
			lda	r6H
			adc	#$00
			sta	r7H

			ldy	#$00
::d			jsr	:read_icon_data		;Card #1 immer kopieren.
			sta	(r5L),y

;--- Ergänzung: 20.08.05 M.Kanet
;Hinweis: Nur ganze Icons ausgeben.
;			bit	r4L			;Card #2 kopieren ?
;			bvc	:e			; => Nein, weiter...
			jsr	:read_icon_data
			sta	(r6L),y

;--- Ergänzung: 20.08.05 M.Kanet
;Hinweis: Nur ganze Icons ausgeben.
;			bit	r4L			;Card #3 kopieren ?
;			bpl	:f			; => Nein, weiter...
			jsr	:read_icon_data
			sta	(r7L),y
			bne	:g			;:read_icon_data erhöht X-Reg,
							;daher immer Sprung nach :g

::e			inx				;Icon-Daten überlesen.
::f			inx

::g			dec	r4H			;Alle Zeilen kopiert ?
			beq	:h			; => Ja, Ende...
			iny				;Card-Zeile kopiert ?
			cpy	#$08
			bcc	:d			; => Nein, weiter...

			AddVW	40*8,r5			;Zeiger auf nächste Zeile
			jmp	:c			;Nächste Zeile ausgeben.

;--- Farbe zeichnen.
::h			lda	r1L			;Größe des Farbrechtecks
			sta	r5L			;berechnen.
			lda	r1H
			lsr
			lsr
			lsr
			sta	r5H

			lda	r2L			;Breite in CARDs.
			sta	r6L

			lda	r2H			;Höhe in CARDs berechnen.
			lsr				;Am unteren Fensterrand kann auch
			lsr				;nur ein Teil eines Icons
			lsr				;angezeigt werden. Die Höhe ist
			sta	r6H			;also nicht immer = 3 CARDs!
			lda	r2H
			and	#%00000111		;Höhe ohne Rest durch 8 teilbar?
			beq	:j			; => Ja, weiter...
			inc	r6H			;Höhe +1.
::j

;			jmp	DrawColors		;Weiter bei ":DrawColors"

;*** Farben für Icon zeichnen.
;    Übergabe: r3L = Farbe, $00  = Farbtabelle in r8.
;              r8  = Zeiger auf Farbtabelle (3x3 CARDs)
;              r1L = Spalte (in CARDs)
;              r5H = Zeile (in CARDs)
;              r6L = Breite (in CARDs)
;              r6H = Höhe (in CARDs)
:DrawColors		MoveW	r8,:getColByte +1	;Zeiger auf Farb-Tabelle in
							;Kopier-Routine übertragen.

			ldx	r5H			;Zeiger auf Farbzeile
			lda	colorBuf_L,x		;berechnen.
			clc
			adc	#< COLOR_MATRIX
			sta	r8L
			lda	colorBuf_H,x
			adc	#> COLOR_MATRIX
			sta	r8H

			ClrB	r7H			;CARD-Zeile auf Anfang.

::1			ldy	r7H			;Zeiger auf Farbtabelle setzen.
			ldx	:offset,y

			ldy	r1L			;Zeiger auf COLOR_MATRIX setzen.

			lda	r6L			;Zähler für Breite in CARDs setzen.
			sta	r7L

::2			lda	r3L			;Farbe vorgegeben?
			bne	:3			; => Ja, weiter...
::getColByte		lda	$ffff,x			;Farbe aus Tabelle einlesen und
::3			sta	(r8L),y			;in COLOR_MATRIX speichern.
			iny
			inx
			dec	r7L			;Alle CARDs eingefärbt?
			bne	:2			; => Nein, weiter...

			AddVBW	40,r8			;Nächste Zeile in COLOR_MATRIX.

			inc	r7H			;Nächste Zeile in Farbtabelle.

			dec	r6H			;Alle Farben gesetzt?
			bne	:1			; => Nein, weiter...

			ldx	#$00			;xReg = $00, Icon gezeichnet.
			rts

::offset		b $00,$03,$06
