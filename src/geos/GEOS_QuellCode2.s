; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Baseline und Kursivmöglichkeit
;    überprüfen.
:ChkBaseItalic		lda	currentMode		;Unterstreichen aktiv ?
			bpl	:102			;Nein, weiter...

			ldy	r1H
			cpy	BaseUnderLine		;Unterstreichen möglich ?
			beq	:101			;Ja, weiter...
			dey				;Auf Baseline testen.
			cpy	BaseUnderLine		;Unterstreichen möglich ?
			bne	:102			;Nein, weiter...

::101			lda	r10L			;Baseline möglich,
			eor	#%11111111		;Invertieren der letzten
			sta	r10L			;Zeichensatz-Zeile.

::102			lda	currentMode
			and	#%00010000		;Kursiv-Modus aktiv ?
			beq	CurModusOK		;Nein, weiter...

			lda	r10H			;Zähler für Pixelverschiebung
			lsr				;bei Kursivschrift einlesen.
			bcs	:105			;Verschieben ? Nein, weiter...

			ldx	StrBitXposL		;X-Koordinate korrigieren.
			bne	:103
			dec	StrBitXposH
::103			dex
			stx	StrBitXposL

			ldx	r11L
			bne	:104
			dec	r11H
::104			dex
			stx	r11L

			jsr	StreamInfo

::105			lda	rightMargin+1
			cmp	StrBitXposH
			bne	:106
			lda	rightMargin+0
			cmp	StrBitXposL
::106			bcc	:108

			lda	leftMargin+1
			cmp	r11H
			bne	:107
			lda	leftMargin+0
			cmp	r11L
::107			rts
::108			sec
			rts

;*** Neue Grafikdaten in Grafikdaten-
;    speicher kopieren.
:WriteNewStream		ldy	r1L			;Zeiger auf Grafikspeicher.
			ldx	CurStreamCard
			lda	SetStream,x
			cpx	r8L			;Nur 1 CARD berechnen ?
			beq	:105			;Ja, weiter...
			bcs	:107			;Überlauf, Ende...

;*** Startbyte definieren.
			eor	r10L			;Zeichen invertieren.
			and	r9L			;Die zu übernehmenden Bits
			sta	:101 +1			;isolieren und merken.
			lda	r3L			;Bits aus Grafikspeicher
			and	(r6L),y			;einlesen und isolieren.
::101			ora	#$00			;Daten verknüpfen.
			sta	(r6L),y
			sta	(r5L),y

;*** Datenbytes definieren.
::102			tya				;Zeiger auf nächstes CARD
			clc				;setzen.
			adc	#$08
			tay
			inx
			cpx	r8L			;Letztes CARD erreicht ?
			beq	:103			;Ja, weiter...

			lda	SetStream,x		;Datenbyte einlesen.
			eor	r10L			;Invertieren.
			sta	(r6L),y			;In Grafikspeicher kopieren.
			sta	(r5L),y
			clv
			bvc	:102			;Nächstes Card setzen.

;*** Bits im letzten CARD bestimmen.
::103			lda	SetStream,x		;Letztes CARD bestimmen.
			eor	r10L			;Zeichen invertieren.
			and	r9H			;Die zu übernehmenden Bits
			sta	:104 +1			;isolieren und merken.
			lda	r4H			;Bits aus Grafikspeicher
			and	(r6L),y			;einlesen und merken.
::104			ora	#$00
			sta	(r6L),y
			sta	(r5L),y
			rts

;*** Nur 1 CARD bestimmen.
::105			eor	r10L			;Invertieren.
			and	r9H			;Die zu übernehmenden Bits
			eor	#$ff			;isolieren und merken.
			ora	r3L
			ora	r4H
			eor	#$ff
			sta	:106 +1
			lda	r3L			;Die ersten und letzten Bits
			ora	r4H			;im CARD isolieren und merken.
			and	(r6L),y
::106			ora	#$00
			sta	(r6L),y			;Daten verknüpfen.
			sta	(r5L),y
::107			rts

;*** Neuen Bit-Stream initialisieren.
:InitNewStream		ldx	r8L			;Anzahl Bit-Stream-Bytes.

			lda	#$00
::101			sta	NewStream,x		;Datenspeicher für die neuen
			dex				;Bit-Stream-Daten löschen.
			bpl	:101

			lda	r8H
			and	#%01111111		;Schriftstil definiert ?
			bne	:105			;Ja, weiter...
::102			jsr	DefBitOutBold

::103			ldx	r8L
::104			lda	NewStream,x		;Neue Bit-Stream-Daten in
			sta	SetStream,x		;Zwischenspeicher kopieren.
			dex
			bpl	:104
			inc	r8H
			rts

::105			cmp	#$01
			beq	:106
			ldy	r10H
			dey				;Kursivschrift aktiv ?
			beq	:102			;Nein, weiter...

			dey				;Daten für Kursiv vorbereiten.
			php				;Dabei werden die oberen
			jsr	DefBitOutBold		;Pixelzeilen jeweils um 1 Bit
			jsr	AddFontWidth		;nach links zurückgesetzt.
			plp
			beq	:107

::106			jsr	AddFontWidth		;Zeiger auf Daten richten.
			jsr	CopyCharData		;Zeichendaten einlesen.
			jsr	DefBitOutBold		;Rahmen für Outline berechnen.
			lda	r2L			;Zeiger auf Daten wieder
			sec				;zurücksetzen.
			sbc	curSetWidth+0
			sta	r2L
			lda	r2H
			sbc	curSetWidth+1
			sta	r2H
::107			jsr	CopyCharData
			jsr	DefBitOutBold		;Rahmen für Outline berechnen.
			jsr	DefOutLine		;Fläche löschen -> Outline.
			clv
			bvc	:103			;Neuen Stream übertragen.

;*** Zeichensatzbreite! addieren.
:AddFontWidth		lda	curSetWidth+0
			clc
			adc	r2L
			sta	r2L
			lda	curSetWidth+1
			adc	r2H
			sta	r2H
			rts

;*** daten für Outline berechnen.
:DefOutLine		ldy	#$ff
::101			iny
			ldx	#$07
::102			lda	SetStream,y
			and	BitData2 ,x		;Bit gesetzt ?
			beq	:103			;Nein, weiter...
			lda	BitData2 ,x		;Bitmaske isolieren.
			eor	#%11111111
			and	NewStream,y		;Bit löschen und
			sta	NewStream,y		;zurückschreiben.
::103			dex				;8 Bit überprüft ?
			bpl	:102			;Nein, weiter...
			cpy	r8L			;Alle Cards geprüft ?
			bne	:101			;Nein, weiter...
			rts

;*** Bit-Verschiebung für Funktionen
;    Outline/Bold berechnen.
:DefBitOutBold		jsr	MovBitStrData

			ldy	#$ff
::101			iny

			ldx	#$07
::102			lda	SetStream  ,y
			and	BitData2   ,x
			beq	:107

			lda	NewStream  ,y
			ora	BitData2   ,x
			sta	NewStream  ,y

			inx
			cpx	#$08
			bne	:103

			lda	NewStream-1,y
			ora	#%00000001
			sta	NewStream-1,y
			bne	:104

::103			lda	NewStream  ,y
			ora	BitData2   ,x
			sta	NewStream  ,y

::104			dex
			dex
			bpl	:105

			lda	NewStream+1,y
			ora	#%10000000
			sta	NewStream+1,y
			bne	:106

::105			lda	NewStream  ,y
			ora	BitData2   ,x
			sta	NewStream  ,y

::106			inx
::107			dex
			bpl	:102
			cpy	r8L
			bne	:101
			rts

;*** BIT-Stream für aktuelle Zeile um
;    1 Pixel verschieben.
:MovBitStrData		lsr	SetStream+0
			ror	SetStream+1
			ror	SetStream+2
			ror	SetStream+3
			ror	SetStream+4
			ror	SetStream+5
			ror	SetStream+6
			ror	SetStream+7
			rts

;*** Zeichen ausgeben. Achtung!
;    ASCII-Code ist um #$20 reduziert!
:PrntCharCode		nop				;Füllbefehl.
			tay				;ASCII-Code merken.

			lda	r1H			;Y-Koordinate speichern.
			pha

			tya				;ASCII-Code zurücksetzen.
			jsr	DefCharData		;Zeichendaten definieren.
			bcs	:109			;Gültig ? Nein, übergehen.

::101			clc
			lda	currentMode
			and	#%10010000		;Kursiv/Unterstreichen ?
			beq	:102			;Nein, weiter...
			jsr	ChkBaseItalic		;Daten für Kursiv und
							;unterstreichen berechnen.
::102			php				;Schriftstile möglich ?
			bcs	:103			;Nein, übergehen.
			jsr	CopyCharData

::103			bit	r8H			;Outline-Modus aktiv ?
			bpl	:104			;Nein, weiter...
			jsr	InitNewStream
			clv
			bvc	:105

::104			jsr	AddFontWidth		;Zeiger auf näcste Bit-Stream-
							;datenzeile setzen.
::105			plp
			bcs	:107

			lda	r1H			;Ist Pixelzeile innerhalb des
			cmp	windowTop		;aktuellen Textfensters ?
			bcc	:107			;Nein, übergehen...
			cmp	windowBottom
			bcc	:106			;Ja, Daten ausgeben...
			bne	:107			;Nein, übergehen...
::106			jsr	WriteNewStream		;Grafikdaten ausgeben.

::107			inc	r5L			;Zeiger auf Grafikspeicher
			inc	r6L			;korrigieren.
			lda	r5L
			and	#$07
			bne	:108
			inc	r5H
			inc	r6H
			lda	r5L
			clc
			adc	#$38
			sta	r5L
			sta	r6L
			bcc	:108
			inc	r5H
			inc	r6H

::108			inc	r1H			;Zeiger auf nächste Pixelzeile.
			dec	r10H			;Alle Zeilen ausgegeben ?
			bne	:101			;Nein, weiter...
::109			pla				;Y-Koordinate zurücksetzen.
			sta	r1H
			rts

;*** Bit-Stream vorbereiten.
;    Nur bei max. 16 Pixel breiten
;    Zeichen (gleich 2 Byte).
:D1a			lsr
:D1b			lsr
:D1c			lsr
:D1d			lsr
:D1e			lsr
:D1f			lsr
:D1g			lsr
:D1h			jmp	DefBitStream2

:D2a			lsr
			ror	SetStream+1
			ror	SetStream+2
:D2b			lsr
			ror	SetStream+1
			ror	SetStream+2
:D2c			lsr
			ror	SetStream+1
			ror	SetStream+2
:D2d			lsr
			ror	SetStream+1
			ror	SetStream+2
:D2e			lsr
			ror	SetStream+1
			ror	SetStream+2
:D2f			lsr
			ror	SetStream+1
			ror	SetStream+2
:D2g			lsr
			ror	SetStream+1
			ror	SetStream+2
:D2h			jmp	DefBitStream2

:D3a			asl
:D3b			asl
:D3c			asl
:D3d			asl
:D3e			asl
:D3f			asl
:D3g			asl
			jmp	DefBitStream2

:D4a			asl	SetStream+2
			rol	SetStream+1
			rol
:D4b			asl	SetStream+2
			rol	SetStream+1
			rol
:D4c			asl	SetStream+2
			rol	SetStream+1
			rol
:D4d			asl	SetStream+2
			rol	SetStream+1
			rol
:D4e			asl	SetStream+2
			rol	SetStream+1
			rol
:D4f			asl	SetStream+2
			rol	SetStream+1
			rol
:D4g			asl	SetStream+2
			rol	SetStream+1
			rol
			jmp	DefBitStream2

;*** Bit-Stream vorbereiten.
;    Einügen/Löschen von Bits.
:PrepBitStream		sta	SetStream		;Erstes Byte speichern.

			lda	r7L			;Anzahl der zu löschenden
			sec				;Bits berechnen.
			sbc	BitStr1stBit
			beq	:102			;Bits löschen ? Nein, weiter...
			bcc	DefBitStream		;Ja, Bits löschen.

			tay				;Anzahl Bits als Zähler.
::101			jsr	MovBitStrData		;Bit-Stream um 1 Bit nach
							;rechts verschieben.
			dey				;Bits gelöscht ?
			bne	:101			;Nein, weiter...

::102			lda	SetStream
			jmp	DefBitStream2

;*** Überflüssige Bits in Bit-Stream
;    für aktuelles Zeichen löschen.
:DefBitStream		lda	BitStr1stBit		;Zeiger auf erstes Bit.
			sec				;Anzahl zu setzender Bits
			sbc	r7L			;abziehen und als Bit-Zähler
			tay				;in yReg kopieren.

::101			asl	SetStream+7		;Bit-Stream um 1 Bit nach
			rol	SetStream+6		;links verschieben.
			rol	SetStream+5
			rol	SetStream+4
			rol	SetStream+3
			rol	SetStream+2
			rol	SetStream+1
			rol	SetStream+0
			dey
			bne	:101

			lda	SetStream

;*** Bit-Stream-Daten bearbeiten.
:DefBitStream2		sta	SetStream

			bit	currentMode		;Schriftstil "Fett" ?
			bvc	D0a			;Nein, weiter...

			lda	#$00			;Bit #7 in aktuellem Bit-Stream
			pha				;nicht setzen.

			ldy	#$ff
::101			iny
			ldx	SetStream,y		;Bit-Stream-Byte einlesen.
			pla				;Bit #7-Wert einlesen.
			ora	BoldData ,x		;"Fettschrift"-Wert addieren.
			sta	SetStream,y		;Neues Bit-Stream-Byte setzen.
			txa
			lsr
			lda	#$00			;Bit #7 im nächstes Bytes des
			ror				;Bit-Streams definieren.
			pha
			cpy	r8L			;Alle Bytes des Bit-Streams
			bne	:101			;verdoppelt ? Nein, weiter...

			pla
:D0a			rts

;*** Erstes Datenbyte auswerten.
;    Einsprung in ":CharXYBit"
:CopyCharData		ldy	#$00
			jmp	(r13)

;*** Max. 24 Bit-Breites Zeichen.
:Char24Bit		sty	SetStream+1
			sty	SetStream+2
			lda	(r2L),y			;Datenbyte einlesen.
			and	BitStrDataMask		;Ungültige Bits am Anfang und
			and	r7H			;Ende entfernen.
			jmp	(r12)

;*** Max. 32 Bit-Breites Zeichen.
:Char32Bit		sty	SetStream+2
			sty	SetStream+3
			lda	(r2L),y
			and	BitStrDataMask
			sta	SetStream+0
			iny
			lda	(r2L),y
			and	r7H
			sta	SetStream+1
:le356			lda	SetStream+0
			jmp	(r12)

;*** Max. 40 Bit-Breites Zeichen.
:Char40Bit		sty	SetStream+3
			sty	SetStream+4
			lda	(r2L),y
			and	BitStrDataMask
			sta	SetStream+0
			iny
			lda	(r2L),y
			sta	SetStream+1
			iny
			lda	(r2L),y
			and	r7H
			sta	SetStream+2
			clv
			bvc	le356

;*** Max. 48 Bit-Breites Zeichen.
:Char48Bit		lda	(r2L),y
			and	BitStrDataMask
			sta	SetStream+0
::101			iny
			cpy	r3H
			beq	:102
			lda	(r2L),y
			sta	SetStream,y
			clv
			bvc	:101

::102			lda	(r2L),y
			and	r7H
			sta	SetStream+0,y
			lda	#$00
			sta	SetStream+1,y
			sta	SetStream+2,y
			beq	le356

;*** variablen für Zeichenausgabe.
:CurStreamCard		b $00
:StrBitXposL		b $34
:StrBitXposH		b $01

;*** Sprite-Zeiger-Kopie setzen.
:DefSprPoi		lda	#$bf
			sta	$8ff0
			ldx	#$07
			lda	#$bb
::101			sta	$8fe8,x
			dex
			bpl	:101
			rts

;*** Bitmap-Ausschnitt ausgeben.
:xBitOtherClip		ldx	#$ff
			jmp	BitAllClip

;*** Bitmap-Ausschnitt ausgeben.
:xBitmapClip		ldx	#$00
:BitAllClip		stx	r9H
			lda	#$00
			sta	r3L
			sta	r4L
::101			lda	r12L
			ora	r12H
			beq	:103
			lda	r11L
			jsr	:104
			lda	r2L
			jsr	:104
			lda	r11H
			jsr	:104
			lda	r12L
			bne	:102
			dec	r12H
::102			dec	r12L
			clv
			bvc	:101
::103			lda	r11L
			jsr	:104
			jsr	PrnPixelLine
			lda	r11H
			jsr	:104
			inc	r1H
			dec	r2H
			bne	:103
			rts

::104			cmp	#$00
			beq	:105
			pha
			jsr	GetGrafxByte
			pla
			sec
			sbc	#$01
			bne	:104
::105			rts

;*** Bitmap darstellen.
:xi_BitmapUp		pla				;Zeiger auf Inline-Daten
			sta	returnAddress+0		;einlesen.
			pla
			sta	returnAddress+1

			ldy	#$01
			lda	(returnAddress),y	;Zeiger auf Grafikdaten
			sta	r0L			;einlesen.
			iny
			lda	(returnAddress),y
			sta	r0H
			iny
			lda	(returnAddress),y	;X-Position in CARDs
			sta	r1L			;einlesen.
			iny
			lda	(returnAddress),y	;Y-Position in Pixel
			sta	r1H			;einlesen.
			iny
			lda	(returnAddress),y	;Breite in CARDs einlesen.
			sta	r2L
			iny
			lda	(returnAddress),y	;Breite in Pixel einlesen.
			sta	r2H
			jsr	xBitmapUp		;Grafik darstellen.
			php
			lda	#$07			;Routine beenden.
			jmp	DoInlineReturn

;*** Bitmap darstellen.
:xBitmapUp		lda	r9H			;Register ":r9" speichern.
			pha
			lda	#$00			;Zähler für Pixelzeilen
			sta	r9H			;löschen.
			lda	#$00			;LOW-Byte der X-Koordinaten
			sta	r3L			;löschen.
			sta	r4L
::101			jsr	PrnPixelLine
			inc	r1H
			dec	r2H
			bne	:101
			pla
			sta	r9H			;Register ":r9" zurücksetzen.
			rts

;*** Pixelzeile ausgeben.
:PrnPixelLine		ldx	r1H			;Grafikzeile berechnen.
			jsr	xGetScanLine

			lda	r2L			;Breite in CARDs merken.
			sta	r3H

			lda	r1L
			cmp	#$20			;Bitmap breiter 32 CARDs ?
			bcc	:101			;Nein, weiter...
			inc	r5H
			inc	r6H

::101			asl				;Zeiger auf CARD berechnen.
			asl
			asl
			tay

::102			sty	r9L			;Zeiger auf CARD merken.
			jsr	GetGrafxByte		;Byte einlesen und in
			ldy	r9L			;Grafikspeicher schreiben.
			sta	(r5L),y
			sta	(r6L),y

			tya				;Zeiger auf nächstes CARD.
			clc
			adc	#$08
			bcc	:103
			inc	r5H
			inc	r6H
::103			tay
			dec	r3H			;Pixelzeile berechnet ?
			bne	:102			;Nein, weiter...
			rts

;*** Byte aus gepackten Daten einlesen.
:GetGrafxByte		lda	r3L
			and	#%01111111
			beq	:102
			bit	r3L
			bpl	:101
			jsr	GetPackedByte
			dec	r3L
			rts

::101			lda	r7H
			dec	r3L
			rts

::102			lda	r4L
			bne	:103
			bit	r9H
			bpl	:103
			jsr	GetNextByte

::103			jsr	GetPackedByte
			sta	r3L

			cmp	#$dc			;Doppelt gepackte Daten ?
			bcc	:104			;Nein, weiter...

			sbc	#$dc			;Anzahl doppelt gepackter
			sta	r7L			;Daten berechnen.
			sta	r4H
			jsr	GetPackedByte
			sec
			sbc	#$01
			sta	r4L
			lda	r0H
			sta	r8H
			lda	r0L
			sta	r8L
			clv
			bvc	:102

::104			cmp	#$80			;ungepackte Daten ?
			bcs	GetGrafxByte		;Ja, Byte einlesen.
			jsr	GetPackedByte
			sta	r7H
			clv
			bvc	GetGrafxByte

;*** Byte aus gepackten Daten einlesen.
:GetPackedByte		bit	r9H
			bpl	:101
			jsr	GetUsrNxByt

;*** Byte aus gepackten Daten einlesen (Fortsetzung).
::101			ldy	#$00
			lda	(r0L),y
			inc	r0L
			bne	:102
			inc	r0H

::102			ldx	r4L
			beq	:103
			dec	r4H
			bne	:103
			ldx	r8H
			stx	r0H
			ldx	r8L
			stx	r0L
			ldx	r7L
			stx	r4H
			dec	r4L
::103			rts

:GetUsrNxByt		jmp	(r13)
:GetNextByte		jmp	(r14)

;*** Zeichen ausgeben.
:xPutChar		cmp	#$20
			bcs	:101
			tay
			lda	PrintCodeL -$08,y
			ldx	PrintCodeH -$08,y
			jmp	CallRoutine

::101			pha				;ASCII-Zeichen merken.
			ldy	r11H			;X-Koordinate speichern.
			sty	r13H
			ldy	r11L
			sty	r13L
			ldx	currentMode		;Zeichenbreite berechnen.
			jsr	xGetRealSize
			dey				;Breite -1 und zur
			tya				;aktuellen X-Koordinate
			clc				;addieren.
			adc	r13L
			sta	r13L
			bcc	:102
			inc	r13H

::102			lda	rightMargin+1		;Zeichen noch innerhalb
			cmp	r13H			;des Textfensters ?
			bne	:103
			lda	rightMargin+0
			cmp	r13L
::103			bcc	:107			;Nein, Fehlerbehandlung.

			lda	leftMargin+1		;Zeichen noch innerhalb
			cmp	r11H			;des Textfensters ?
			bne	:104
			lda	leftMargin+0
			cmp	r11L
::104			beq	:105			;Ja, weiter...
			bcs	:106			;Nein, Fehlerbehandlung.

::105			pla
			sec
			sbc	#$20			;Zeichencode umrechnen und
			jmp	PrntCharCode		;Zeichen ausgeben.

::106			lda	r13L
			clc
			adc	#$01
			sta	r11L
			lda	r13H
			adc	#$00
			sta	r11H

::107			pla
			ldx	StringFaultVec+1
			lda	StringFaultVec+0
			jmp	CallRoutine

;*** Einsprung für Steuercodes.
:PrintCodeL		b < xBACKSPACE,< xFORWARDSPACE
			b < xSetLF,< xHOME
			b < xUPLINE,< xSetCR
			b < xULINEON,< xULINEOFF
			b < xESC_GRAPHICS,									< xESC_RULER
			b < xREVON,< xREVOFF
			b < xGOTOX,< xGOTOY
			b < xGOTOXY,< xNEWCARDSET
			b < xBOLDON,< xITALICON
			b < xOUTLINEON,< xPLAINTEXT

:PrintCodeH		b > xBACKSPACE,> xFORWARDSPACE
			b > xSetLF,> xHOME
			b > xUPLINE,> xSetCR
			b > xULINEON,> xULINEOFF
			b > xESC_GRAPHICS,									> xESC_RULER
			b > xREVON,> xREVOFF
			b > xGOTOX,> xGOTOY
			b > xGOTOXY,> xNEWCARDSET
			b > xBOLDON,> xITALICON
			b > xOUTLINEON,> xPLAINTEXT

;*** Textzeichen ausgeben.
:xSmallPutChar		sec
			sbc	#$20
			jmp	PrntCharCode

:xFORWARDSPACE		lda	#$00
			clc
			adc	r11L
			sta	r11L
			bcc	:101
			inc	r11H
::101			rts

;*** Eine Zeile tiefer.
:xSetLF			lda	r1H
			sec
			adc	curSetHight
			sta	r1H
			rts

;*** Cursor nach links/oben.
:xHOME			lda	#$00
			sta	r11L
			sta	r11H
			sta	r1H
			rts

;*** Eine Zeile höher.
:xUPLINE		lda	r1H
			sec
			sbc	curSetHight
			sta	r1H
			rts

;*** Zum Anfang der nächsten Zeile.
:xSetCR			lda	leftMargin+1
			sta	r11H
			lda	leftMargin+0
			sta	r11L
			jmp	xSetLF

;*** Unterstreichen ein.
:xULINEON		lda	#%10000000
			ora	currentMode
			sta	currentMode
			rts

;*** Unterstreichen aus.
:xULINEOFF		lda	#%01111111
			and	currentMode
			sta	currentMode
			rts

;*** Inversdarstellung ein.
:xREVON			lda	#%00100000
			ora	currentMode
			sta	currentMode
			rts

;*** Inversdarstellung aus.
:xREVOFF		lda	#%11011111
			and	currentMode
			sta	currentMode
			rts

;*** Neue X-Koordinate setzen.
:xGOTOX			inc	r0L
			bne	:101
			inc	r0H
::101			ldy	#$00
			lda	(r0L),y
			sta	r11L
			inc	r0L
			bne	:102
			inc	r0H
::102			lda	(r0L),y
			sta	r11H
			rts

;*** Neue Y-Koordinate setzen.
:xGOTOY			inc	r0L
			bne	:101
			inc	r0H
::101			ldy	#$00
			lda	(r0L),y
			sta	r1H
			rts

;*** Neue X und Y-Koordinate setzen.
:xGOTOXY		jsr	xGOTOX
			jmp	xGOTOY

;*** Drei Byte überlesen.
:xNEWCARDSET		clc
			lda	#$03
			adc	r0L
			sta	r0L
			bcc	:101
			inc	r0H
::101			rts

;*** Fettschrift ein.
:xBOLDON		lda	#%01000000
			ora	currentMode
			sta	currentMode
			rts

;*** Kursivschrift ein.
:xITALICON		lda	#%00010000
			ora	currentMode
			sta	currentMode
			rts

;*** "Outline"-Sschrift ein.
:xOUTLINEON		lda	#%00001000
			ora	currentMode
			sta	currentMode
			rts

;*** Standard-Schrift ein.
:xPLAINTEXT		lda	#$00
			sta	currentMode
			rts

;*** Letztes Zeichen löschen.
:RemoveChar		ldx	currentMode
			jsr	xGetRealSize
			sty	CurCharWidth

;*** Ein Zeichen zurück.
:xBACKSPACE		lda	r11L
			sec
			sbc	CurCharWidth
			sta	r11L
			bcs	:101
			dec	r11H
::101			lda	r11H			;X-Koordinate merken.
			pha
			lda	r11L
			pha
			lda	#$5f			;Delete-Code ausgeben. Ist
			jsr	PrntCharCode		;normalerweise $7F, Wert wurde
			pla				;aber um $20 reduziert!
			sta	r11L			;X-Koordinate zurücksetzen.
			pla
			sta	r11H
			rts

;*** Grafikbefehle ausführen.
:xESC_GRAPHICS		inc	r0L
			bne	:101
			inc	r0H
::101			jsr	xGraphicsString
			ldx	#r0L
			jsr	Ddec
			ldx	#r0L
			jsr	Ddec
			rts

;*** Inline: Zeichenkette ausgeben.
:xi_PutString		pla				;Zeiger auf Inlne-Daten
			sta	r0L			;einlesen.
			pla
			inc	r0L
			bne	:101
			clc
			adc	#$01
::101			sta	r0H

			ldy	#$00
			lda	(r0L),y			;X-Koordinate einlesen.
			inc	r0L
			bne	:102
			inc	r0H
::102			sta	r11L
			lda	(r0L),y
			inc	r0L
			bne	:103
			inc	r0H
::103			sta	r11H
			lda	(r0L),y			;Y-Koordinate einlesen.
			inc	r0L
			bne	:104
			inc	r0H
::104			sta	r1H
			jsr	xPutString		;Text ausgeben.
			inc	r0L
			bne	:105
			inc	r0H
::105			jmp	(r0)			;Zurück zum Programm.

;*** Zeichenkette ausgeben.
:xPutString		ldy	#$00
			lda	(r0L),y			;Zeichen einlesen.
			beq	:102			;$00 gefunden ? Ja, Ende...
			jsr	xPutChar		;Zeichen ausgeben.
			inc	r0L			;Zeiger auf nächstes Zeichen.
			bne	:101
			inc	r0H
::101			clv
			bvc	xPutString		;Nächstes Zeichen ausgeben.
::102			rts

;*** Standardzeichensatz aktivieren.
:xUseSystemFont		lda	#>BSW_Font
			sta	r0H
			lda	#<BSW_Font
			sta	r0L

;*** Benutzerzeichensatz aktivieren.
:xLoadCharSet		ldy	#$00
::101			lda	(r0L),y
			sta	baselineOffset,y
			iny
			cpy	#$08
			bne	:101

			lda	r0L
			clc
			adc	curIndexTable+0
			sta	curIndexTable+0
			lda	r0H
			adc	curIndexTable+1
			sta	curIndexTable+1

			lda	r0L
			clc
			adc	cardDataPntr+0
			sta	cardDataPntr+0
			lda	r0H
			adc	cardDataPntr+1
			sta	cardDataPntr+1

;*** Keine Ahnung was diese Routine macht...
			lda	SerNoHByte		;For what the hell is this ???
			bne	:102
			jsr	GetSerHByte
			sta	SerNoHByte
::102			rts

;*** Breite des aktuellen Zeichens
;    (im Akku) ermitteln.
:xGetCharWidth		sec
			sbc	#$20			;Zeichencode berechnen.
			bcs	GetCodeWidth		;Steuercode ? Nein -> weiter..
			lda	#$00			;Steuercode, Breite = $00.
			rts

;*** Auf "Delete"-Code testen.
;    ASCII-Code um $20 reduziert!
:GetCodeWidth		cmp	#$5f			;Delete-Code ?
			bne	:101			;Nein, weiter...
			lda	CurCharWidth		;Breite des letzten Zeichens.
			rts

::101			asl
			tay
			iny
			iny
			lda	(curIndexTable),y
			dey
			dey
			sec
			sbc	(curIndexTable),y
			rts

;*** Zeichen über Tastatur einlesen.
:xGetString		lda	r0H
			sta	string +1
			lda	r0L
			sta	string +0

			lda	r1L			;Fehlerroutine merken.
			sta	InpStrgFault
			lda	r1H
			sta	stringY
			lda	r2L
			sta	InpStrgLen

			lda	r1H
			pha
			clc
			lda	baselineOffset
			adc	r1H
			sta	r1H
			jsr	PutString
			pla
			sta	r1H

			sec
			lda	r0L
			sbc	string +0
			sta	InpStrMaxKey

			lda	r11H			;X-Koordinate für Eingabe
			sta	stringX+1		;festlegen.
			lda	r11L
			sta	stringX+0

			lda	keyVector+1		;Alten Tastaturabfrage-Vektor
			sta	InpStrgKVecBuf+1	;zwischenspeichern.
			lda	keyVector+0
			sta	InpStrgKVecBuf+0

			lda	#>InputNextKey		;Neue Tastaturabfrage
			sta	keyVector+1		;installieren.
			lda	#<InputNextKey
			sta	keyVector+0

			lda	#>SetMaxInput		;Fehlerbehandlungsroutine
			sta	StringFaultVec+1	;installieren.
			lda	#<SetMaxInput
			sta	StringFaultVec+0

			bit	InpStrgFault
			bpl	:101
			lda	r4H			;Anwender-Fehlerroutine
			sta	StringFaultVec+1	;installieren.
			lda	r4L
			sta	StringFaultVec+0

::101			lda	curSetHight		;Cursor installieren.
			jsr	xInitTextPrompt
			jmp	xPromptOn		;Cursor einschalten.

;*** Länge der Eingabe reduzieren.
:SetMaxInput		lda	InpStrMaxKey
			sta	InpStrgLen
			dec	InpStrMaxKey
			rts

;*** Cursormodus festlegen.
:SetCursorMode		lda	alphaFlag		;Eingabemodus aktiv ?
			bpl	:102			;Nein, Ende...
			dec	alphaFlag
			lda	alphaFlag
			and	#%00111111		;Cursor aktiv ?
			bne	:102			;Nein, Ende...
			bit	alphaFlag		;Cursor invertieren...
			bvc	:101
			jmp	xPromptOff		;Cursor abschalten.
::101			jmp	xPromptOn		;Cursor einschalten.
::102			rts

;*** Nächste Taste einlesen.
:InputNextKey		jsr	xPromptOff		;Cursor abschalten.
			lda	stringX+1		;Zeichenposition auf Bild-
			sta	r11H			;schirm in Zwischenspeicher.
			lda	stringX+0
			sta	r11L
			lda	stringY
			sta	r1H
			ldy	InpStrMaxKey
			lda	keyData			;Gültiges Zeichen ?
			bpl	:102			;Ja, weiter...
::101			rts

;*** Tastendruck auswerten.
::102			cmp	#$0d			;<RETURN> gedrückt ?
			beq	GetStringEnd		;ja, Ende der Eingabe...
			cmp	#$08			;<CRSR LEFT> gedrückt ?
			beq	:104			;Ja, letztes Zeichen löschen.
			cmp	#$1d			;<INSERT> gedrückt ?
			beq	:104			;Ja, letztes Zeichen löschen.
			cmp	#$1c			;<DELETE> gedrückt ?
			beq	:104			;Ja, letztes Zeichen löschen.
			cmp	#$1e			;<CRSR RIGHT> gedrückt ?
			beq	:104			;Ja, letztes Zeichen löschen.
			cmp	#$20			;Gültiges Zeichen ?
			bcc	:101			;Nein, weiter...

			cpy	InpStrgLen		;Eingabespeicher voll ?
			beq	:105			;Ja, Ende...
			sta	(string),y

			lda	dispBufferOn		;Bildschirm-Flag speichern.
			pha
			lda	dispBufferOn
			and	#%00100000		;Dialogbox aktiv ?
			beq	:103			;Nein, weiter...
			lda	#%10100000		;Zeichen nur in Vordergrund-
			sta	dispBufferOn		;Grafikspeicher schreiben

::103			lda	r1H			;Y-Koordinate merken.
			pha
			clc
			lda	baselineOffset
			adc	r1H			;Y-Koordinate für ":PutChar"
			sta	r1H			;berechnen.
			lda	(string),y		;Eingegebenes Zeichen auf
			jsr	PutChar			;Bildschirm ausgeben.
			pla
			sta	r1H

			pla				;Bildschirm-Flag zurücksetzen.
			sta	dispBufferOn

			inc	InpStrMaxKey		;Anzahl Zeichen +1.

			ldx	r11H			;Neue X-Koordinate speichern.
			stx	stringX+1
			ldx	r11L
			stx	stringX+0
			clv
			bvc	:105			;Cursor einschalten.

::104			jsr	DelLastKey		;Letztes Zeichen löschen.
			clv
			bvc	:105

::105			jmp	xPromptOn		;Cursor einschalten.

;*** GetString: Eingabe beenden.
:GetStringEnd		sei				;IRQ sperren.
			jsr	xPromptOff		;Cursor abschalten.

			lda	#$7f			;Eingabeflag löschen.
			and	alphaFlag
			sta	alphaFlag

			cli				;IRQ wieder aktivieren.

			lda	#$00			;Eingabe mit $00-Byte
			sta	(string),y		;abschließen.

			lda	InpStrgKVecBuf+1	;Einsprungadresse für Programm
			sta	r0H			;nach ":r0" kopieren.
			lda	InpStrgKVecBuf+0
			sta	r0L

			lda	#$00
			sta	keyVector+0		;Tastaturabfrage löschen.
			sta	keyVector+1
			sta	StringFaultVec+0	;Fehlerbehandlungsroutine
			sta	StringFaultVec+1	;wieder löschen.
			ldx	InpStrMaxKey		;Max. Anzahl Zeichen merken.
			jmp	(r0)			;Zurück zum Programm.

;*** Letzte Taste löschen.
:DelLastKey		cpy	#$00			;Zeichen im Speicher ?
			beq	:102			;Nein, weiter...
			dey
			sty	InpStrMaxKey		;Anzahl Zeichen im Speicher -1.

			lda	dispBufferOn		;Bildschirm-Flag speichern.
			pha
			lda	dispBufferOn
			and	#%00100000		;Dialogbox aktiv ?
			beq	:101			;Nein, weiter...
			lda	#%10100000		;Zeichen nur in Vordergrund-
			sta	dispBufferOn		;Grafikspeicher schreiben

::101			lda	r1H			;Y-Koordinate merken.
			pha
			clc
			lda	baselineOffset
			adc	r1H			;Y-Koordinate für ":PutChar"
			sta	r1H			;berechnen.
			lda	(string),y		;Letztes Zeichen einlesen und
			jsr	RemoveChar		;auf Bildschirm löschen.
			pla
			sta	r1H
			ldy	InpStrMaxKey
			pla
			sta	dispBufferOn		;Bildschirm-Flag zurücksetzen.

			ldx	r11H			;Neue X-Koordinate speichern.
			stx	stringX+1
			ldx	r11L
			stx	stringX+0
			clc				;Zeichen wurde gelöscht.
			rts

::102			sec				;Kein Zeichen gelöscht.
			rts

;*** Cursor einschalten.
:xPromptOn		lda	#%01000000
			ora	alphaFlag
			sta	alphaFlag
			lda	#$01			;Sprite-Nummer für Cursor.
			sta	r3L
			lda	stringX+1		;X-Koordinate für Cursor.
			sta	r4H
			lda	stringX+0
			sta	r4L
			lda	stringY			;Y-Koordinate für Cursor.
			sta	r5L
			jsr	xPosSprite		;Cursor positionieren.
			jsr	xEnablSprite		;Cursor einschalten.
			clv
			bvc	SetPromptMode

;*** Cursor abschalten.
:xPromptOff		lda	#%10111111		;Flag: "Cursor unsichtbar".
			and	alphaFlag
			sta	alphaFlag
			lda	#$01			;Cursor-Sprite wählen.
			sta	r3L
			jsr	xDisablSprite		;Sprite abschalten.

:SetPromptMode		lda	alphaFlag
			and	#%11000000
			ora	#%00111100
			sta	alphaFlag
			rts

;*** Cursor-Sprite erzeugen.
:xInitTextPrompt	tay				;Höhe des Cursors merken.

			lda	CPU_DATA		;I/O-Register sichern.
			pha
			lda	#%00110101		;I/O-Bereich einschalten.
			sta	CPU_DATA

			lda	mob0clr			;Mauszeigerfarbe als Wert für
			sta	mob1clr			;Cursor-Farbe festsetzen.

			lda	moby2			;Keine Vergrößerung des Sprite
			and	#%11111101		;in Y-Richtung.
			sta	moby2

			tya				;Höhe des Cursors
			pha				;zwischenspeichern.
			lda	#%10000011		;Flag: "Cursor aktiv".
			sta	alphaFlag

			ldx	#$40
			lda	#$00
::101			sta	spr1pic -1,x		;Sprite-Speicher löschen.
			dex
			bne	:101

			pla				;Cursor-Höhe einlesen.
			tay
			cpy	#$15			;Mehr als 21 Pixel ?
			bcc	:102			;Nein, weiter...
			beq	:102			;Nein, weiter...

			tya				;Cursor-Höhe durch 2 teilen.
			lsr
			tay
			lda	moby2			;Sprite-Vergrößerung
			ora	#$02			;in Y-Richtung.
			sta	moby2

::102			lda	#%10000000		;Cursor-Grafik erzeugen.
::103			sta	spr1pic,x
			inx
			inx
			inx
			dey
			bpl	:103
			pla				;I/O-Register zurücksetzen.
			sta	CPU_DATA
			rts

;*** Zahl in ASCII umwandeln.
:ConvDEZtoASCII		sta	r2L
			lda	#$04			;Zeiger auf 10000er.
			sta	r2H
			lda	#$00
			sta	r3L
			sta	r3H

::101			ldy	#$00
			ldx	r2H
::102			lda	r0L			;Wert 10^x von Dezimal-Zahl
			sec				;subtrahieren.
			sbc	DezDataL,x
			sta	r0L
			lda	r0H
			sbc	DezDataH,x
			bcc	:103			;Unterlauf ? Ja, weiter...
			sta	r0H
			iny
			clv				;Weiterrechnen.
			bvc	:102

::103			lda	r0L			;Zahl auf letzten Wert
			adc	DezDataL,x		;zurücksetzen.
			sta	r0L
			tya				;Stelle in ASCII-Zahl > $00 ?
			bne	:104			;Ja, weiter...
			cpx	#$00			;Linker Rand erreicht ?
			beq	:104			;Ja, weiter...
			bit	r2L			;Führende Nullen ausgeben ?
			bvs	:105			;Nein, weiter...

::104			ora	#$30			;Zahl in Zwischenspeicher
			ldx	r3L			;übertragen.
			sta	SetStream,x

			ldx	currentMode		;Zeichenbreite des
			jsr	xGetRealSize		;aktuellen Zeichen berechnen.
			tya				;Zeichenbreite addieren.
			clc
			adc	r3H
			sta	r3H
			inc	r3L

			lda	#%10111111
			and	r2L
			sta	r2L
::105			dec	r2H			;Nächste Ziffer des
			bpl	:101			;ASCII-Strings berechnen.
			rts

;*** Tabelle für Umrechnung DEZ->ASCII.
:DezDataL		b < 1
			b < 10
			b < 100
			b < 1000
			b < 10000

:DezDataH		b > 1
			b > 10
			b > 100
			b > 1000
			b > 10000

;*** Zahl auf Bildschirm ausgeben.
:xPutDecimal		jsr	ConvDEZtoASCII		;Zahl nach ASCII wandeln.

			bit	r2L			;Zahl linksbündig ausgeben ?
			bmi	:101			;Ja, weiter...

			lda	r2L			;Breite des Ausgabefeldes in
			and	#%00111111		;Pixel ermitteln.
			sec
			sbc	r3H
			clc
			adc	r11L			;X-Position für Zahlenausgabe
			sta	r11L			;festlegen.
			bcc	:101
			inc	r11H

::101			ldx	r3L
			stx	r0L
::102			lda	SetStream-1,x		;ASCII-Zeichen der Zahl
			pha				;zwischenspeichern.
			dex
			bne	:102

::103			pla				;Zeichen einlesen und
			jsr	xPutChar		;ausgeben.
			dec	r0L			;Alle Zeichen aus ASCII-String
			bne	:103			;ausgegeben ? Nein, weiter...
			rts

;*** Prüfsumme bilden.
:xCRC			ldy	#$ff			;Startwert für Prüfsumme.
			sty	r2L
			sty	r2H
			iny
::101			lda	#$80			;Bit-Maske auf Startwert.
			sta	r3L

::102			asl	r2L			;Prüfsumme um 1 Bit nach
			rol	r2H			;links verschieben.

			lda	(r0L),y			;Byte aus CRC-Bereich lesen.
			and	r3L			;Mit Bit-Maske verknüpfen.
			bcc	:103			;War Prüfsummen-Bit #15 = 0 ?
							;Ja, weiter...
			eor	r3L			;Bit-Ergebnis invertieren.
::103			beq	:104			;Ergebnis = $00 ? Ja, weiter...

			lda	r2L			;Prüfsumme ergänzen.
			eor	#%00100001
			sta	r2L
			lda	r2H
			eor	#%00010000
			sta	r2H

::104			lsr	r3L			;Alle Bits eines Bytes ?
			bcc	:102			;Nein, weiter...

			iny				;Zeiger auf nächstes Byte
			bne	:105			;berechnen.
			inc	r0H

::105			ldx	#r1L			;Länge des CRC-Bereichs
			jsr	Ddec			;korrigieren.
			lda	r1L
			ora	r1H			;Prüfsumme erstellt ?
			bne	:101			;Nein, weiter...
			rts

;*** Linie zeichnen.
;    r11L/r11H = yLow/yHigh
;    r3  /r4   = xLow/xHigh
:xDrawLine		php				;Statusbyte merken.
			lda	#$00
			sta	r7H

			lda	r11H			;Y_Länge der Linie berechnen.
			sec
			sbc	r11L
			sta	r7L
			bcs	:101
			lda	#$00			;Länge in Absolut-Wert
			sec				;umrechnen.
			sbc	r7L
			sta	r7L

::101			lda	r4L			;X_Länge der Linie berechnen.
			sec
			sbc	r3L
			sta	r12L
			lda	r4H
			sbc	r3H
			sta	r12H
			ldx	#r12L			;Länge in Absolut-Wert
			jsr	Dabs			;umrechnen.

			lda	r12H			;X_Länge größer Y_Länge ?
			cmp	r7H
			bne	:102
			lda	r12L
			cmp	r7L
::102			bcs	SetVarHLine		;Ja, X_Linie zeichnen.
			jmp	SetVarVLine		; -> Y_Linie zeichnen.

;*** Linie zwischen +45 und -45 Grad
;    zeichnen. Y-Abstand zwischen zwei
;    X-Punkten max. 1 Pixel.
:SetVarHLine		lda	r7L			;Y-Delta-Wert zwischen zwei
			asl				;Punkten berechnen.
			sta	r9L
			lda	r7H
			rol
			sta	r9H

			lda	r9L
			sec
			sbc	r12L
			sta	r8L
			lda	r9H
			sbc	r12H
			sta	r8H

			lda	r7L
			sec
			sbc	r12L
			sta	r10L
			lda	r7H
			sbc	r12H
			sta	r10H

			asl	r10L
			rol	r10H

			lda	#$ff
			sta	r13L

;*** Linen-Richtung bestimmen.
			lda	r3H
			cmp	r4H
			bne	:101
			lda	r3L
			cmp	r4L
::101			bcc	:103			; -> Links nach rechts.

			lda	r11L
			cmp	r11H
			bcc	:102			; -> Oben nach unten.
			lda	#$01
			sta	r13L

::102			ldy	r3H			;X-Koordinaten vertauschen.
			ldx	r3L
			lda	r4H
			sta	r3H
			lda	r4L
			sta	r3L
			sty	r4H
			stx	r4L
			lda	r11H			;Y-Startwert setzen.
			sta	r11L
			clv
			bvc	:104

;*** Linie zeichnen (Fortsetzung).
::103			ldy	r11H
			cpy	r11L
			bcc	:104			; -> Unten nach oben.
			lda	#$01
			sta	r13L

::104			plp
			php				;Statusbyte einlesen.
			jsr	xDrawPoint		;Punkt setzen.

			lda	r3H			;Ende der Linie erreicht ?
			cmp	r4H
			bne	:105
			lda	r3L
			cmp	r4L
::105			bcs	:108			;Ja, Ende...

			inc	r3L			;Zeiger auf nächsten Punkt
			bne	:106			;der Linie berechnen.
			inc	r3H

::106			bit	r8H			;Y-Koordinate ändern ?
			bpl	:107			;Ja, weiter...

			lda	r9L			;Zeiger auf nächstes Pixel
			clc				;setzen.
			adc	r8L
			sta	r8L
			lda	r9H
			adc	r8H
			sta	r8H
			clv
			bvc	:104

::107			clc				;Y-Koordinate ändern.
			lda	r13L
			adc	r11L
			sta	r11L
			lda	r10L			;Zeiger auf nächstes Pixel
			clc				;setzen.
			adc	r8L
			sta	r8L
			lda	r10H
			adc	r8H
			sta	r8H
			clv
			bvc	:104
::108			plp
			rts

;*** Linie größer +45 oder -45 Grad
;    zeichnen. Y-Abstand zwischen zwei
;    X-Punkten größer als 1 Pixel.
:SetVarVLine		lda	r12L			;X-Delta-Wert zwischen zwei
			asl				;Punkten berechnen.
			sta	r9L
			lda	r12H
			rol
			sta	r9H

			lda	r9L
			sec
			sbc	r7L
			sta	r8L
			lda	r9H
			sbc	r7H
			sta	r8H

			lda	r12L
			sec
			sbc	r7L
			sta	r10L
			lda	r12H
			sbc	r7H
			sta	r10H
			asl	r10L
			rol	r10H

			lda	#$ff
			sta	r13H
			sta	r13L

;*** Linien-Richtung bestimmen.
			lda	r11L
			cmp	r11H
			bcc	:103			; -> Oben nach unten.

			lda	r3H
			cmp	r4H
			bne	:101
			lda	r3L
			cmp	r4L
::101			bcc	:102			; -> Links nach rechts.
			lda	#$00
			sta	r13H
			lda	#$01
			sta	r13L
::102			lda	r4H			;X-Startwert setzen.
			sta	r3H
			lda	r4L
			sta	r3L
			ldx	r11L			;Y-Koordinaten vertauschen.
			lda	r11H
			sta	r11L
			stx	r11H
			clv
			bvc	:105

::103			lda	r3H
			cmp	r4H
			bne	:104
			lda	r3L
			cmp	r4L
::104			bcs	:105			; -> Rechts nach links.
			lda	#$00
			sta	r13H
			lda	#$01
			sta	r13L
::105			plp
			php				;Statusbyte einlesen.
			jsr	xDrawPoint		;Punkt zeichnen.

			lda	r11L
			cmp	r11H			;Ende der Linie erreicht ?
			bcs	:107			;Ja, Ende...
			inc	r11L			;Zeiger auf nächstes Byte.
			bit	r8H			;X-Koordinate ändern ?
			bpl	:106			;Ja, weiter...

			lda	r9L			;Zeiger auf nächstes Pixel
			clc				;setzen.
			adc	r8L
			sta	r8L
			lda	r9H
			adc	r8H
			sta	r8H
			clv
			bvc	:105

::106			lda	r13L			;X-Koordinate ändern.
			clc
			adc	r3L
			sta	r3L
			lda	r13H
			adc	r3H
			sta	r3H

			lda	r10L			;Zeiger auf nächstes Pixel
			clc				;setzen.
			adc	r8L
			sta	r8L
			lda	r10H
			adc	r8H
			sta	r8H
			clv
			bvc	:105

::107			plp
			rts

;*** Einzelnen Punkt setzen.
:xDrawPoint		php				;Statusflag merken.
			ldx	r11L			;Grafikzeile berechnen.
			jsr	xGetScanLine

			lda	r3L			;Absoluten Bytewert ermitteln.
			and	#%11111000
			tay
			lda	r3H
			beq	:101
			inc	r5H
			inc	r6H

::101			lda	r3L
			and	#%00000111
			tax				;Zu setzendes Bit
			lda	BitData1,x		;berechnen.

			plp				;Statusflag einlesen.
			bmi	:104			;Hintergrund nach Vordergrund.
			bcc	:102			; -> Punkt löschen.
			ora	(r6L),y			; -> Punkt setzen.
			clv
			bvc	:103

::102			eor	#$ff
			and	(r6L),y

::103			sta	(r6L),y			;Ergebnis in Grafikspeicher
			sta	(r5L),y			;übertragen.
			rts

::104			pha				;Pixel aus Hintergrundgrafik
			eor	#$ff			;einlesen und in Vordergrund-
			and	(r5L),y			;grafik kopieren.
			sta	(r5L),y
			pla
			and	(r6L),y
			ora	(r5L),y
			sta	(r5L),y
			rts

;*** Punkt-Zustand ermitteln.
:xTestPoint		ldx	r11L			;Grafikzeile berechnen.
			jsr	xGetScanLine

			lda	r3L			;Absoluten Bytewert ermitteln.
			and	#%11111000
			tay
			lda	r3H
			beq	:101
			inc	r6H

::101			lda	r3L
			and	#%00000111
			tax				;Zu testendes Bit
			lda	BitData1,x		;berechnen.
			and	(r6L),y
			beq	:102
			sec				; -> Punkt ist gesetzt.
			rts
::102			clc				; -> Punkt ist gelöscht.
			rts

;*** Mausabfrage starten.
:xStartMouseMode	bcc	:101			;Mauszeiger positionieren ?
							; -> Nein, weiter...
			lda	r11L
			ora	r11H			;X-Koordinate gesetzt ?
			beq	:101			; -> Nein, weiter...

			lda	r11H			;Neue Mausposition setzen.
			sta	mouseXPos+1
			lda	r11L
			sta	mouseXPos+0
			sty	mouseYPos
			jsr	SlowMouse

::101			lda	#>ChkMseButton		;Zeiger auf Mausabfrage
			sta	mouseVector+1		;installieren.
			lda	#<ChkMseButton
			sta	mouseVector+0
			lda	#>IsMseOnMenu
			sta	mouseFaultVec+1		;Zeiger auf Fehlerroutine bei
			lda	#<IsMseOnMenu		;verlassen des Mausbereichs.
			sta	mouseFaultVec+0
			lda	#$00			;Flag: "Mauszeiger im Bereich".
			sta	faultData
			jmp	MouseUp			;Mauszeiger darstellen.

;*** Maus abschalten.
:xClearMouseMode	lda	#$00			;Mausabfrage unterbinden.
			sta	mouseOn
:MouseSpriteOff		lda	#$00			;Sprite #0 = Mauszeiger
			sta	r3L			;abschalten.
			jmp	xDisablSprite

;*** Mauszeiger abschalten.
:xMouseOff		lda	#%01111111
			and	mouseOn
			sta	mouseOn
			jmp	MouseSpriteOff

;*** Mauzeiger einschalten.
:xMouseUp		lda	#%10000000
			ora	mouseOn
			sta	mouseOn
			rts

;*** Mauszeiger abfragen.
:InitMouseData		jsr	UpdateMouse		;Mausposition einlesen.
			bit	mouseOn			;Mauszeiger aktiv ?
			bpl	:101			;Nein, weiter...
			jsr	SetMseToArea
			lda	#$00			;Zeiger auf Sprite #0 für
			sta	r3L			;Mauszeiger.
			lda	msePicPtr+1		;Zeiger auf Grafik-Daten für
			sta	r4H			;Sprite #0 = Mauszeiger.
			lda	msePicPtr+0
			sta	r4L
			jsr	DrawSprite		;Maus-Sprite erstellen.
			lda	mouseXPos+1
			sta	r4H
			lda	mouseXPos+0
			sta	r4L
			lda	mouseYPos
			sta	r5L
			jsr	PosSprite		;Mauszeiger positionieren.
			jsr	EnablSprite		;Sprite einschalten.
::101			rts

;*** Mauszeiger in Bereich festsetzen.
:SetMseToArea		ldy	mouseLeft+0
			ldx	mouseLeft+1
			lda	mouseXPos+1		;Mauszeiger über linken Rand ?
			bmi	:102			;Ja, Fehler anzeigen.
			cpx	mouseXPos+1		;Mauszeiger links von
			bne	:101			;aktueller Bereichsgrenze ?
			cpy	mouseXPos+0
::101			bcc	:103			;Nein, weiter...
			beq	:103			;Nein, weiter...

::102			lda	#%00100000		;Mauszeiger hat linke Grenze
			ora	faultData		;überschritten. Mauszeiger auf
			sta	faultData		;linke Grenze setzen.
			sty	mouseXPos+0
			stx	mouseXPos+1

::103			ldy	mouseRight+0
			ldx	mouseRight+1
			cpx	mouseXPos+1		;Mauszeiger über rechten Rand ?
			bne	:104
			cpy	mouseXPos+0
::104			bcs	:105			;Nein, weiter...

			lda	#%00010000		;Mauszeiger hat rechte Grenze
			ora	faultData		;überschritten. Mauszeiger auf
			sta	faultData		;rechte Grenze setzen.
			sty	mouseXPos+0
			stx	mouseXPos+1

::105			ldy	mouseTop
			lda	mouseYPos		;Hat Mauszeiger die untere
			cmp	#$e4			;Bildgrenze überschritten ?
			bcs	:106			;Ja, Fehler anzeigen.
			cpy	mouseYPos		;Mauszeiger über obere Grenze ?
			bcc	:107			;Nein, weiter...
			beq	:107			;Nein, weiter...

::106			lda	#%10000000		;Mauszeiger hat obere Grenze
			ora	faultData		;überschritten. Mauszeiger auf
			sta	faultData		;obere Grenze setzen.
			sty	mouseYPos

::107			ldy	mouseBottom
			cpy	mouseYPos		;Mauszeiger über untere Grenze?
			bcs	:108			;Nein, weiter...

			lda	#%01000000		;Mauszeiger hat untere Grenze
			ora	faultData		;überschritten. Mauszeiger auf
			sta	faultData		;untere Grenze setzen.
			sty	mouseYPos

::108			bit	mouseOn			;PullDown-Menü aktiv ?
			bvc	:113			;Nein, weiter...
			lda	mouseYPos		;Ist Mauszeiger zwischen oberer
			cmp	DM_MenuRange+0		;und untere Grenze des Menü-
			bcc	:112			;fensters ?
			cmp	DM_MenuRange+1
			beq	:109
			bcs	:112			;Nein, Fehler anzeigen.

::109			lda	mouseXPos+1		;Ist Mauszeiger zwischen linker
			cmp	DM_MenuRange+3		;und rechter Grenze des Menü-
			bne	:110			;fensters ?
			lda	mouseXPos+0
			cmp	DM_MenuRange+2
::110			bcc	:112			;Nein, Fehler anzeigen.
			lda	mouseXPos+1
			cmp	DM_MenuRange+5
			bne	:111
			lda	mouseXPos+0
			cmp	DM_MenuRange+4
::111			bcc	:113			;Ja, weiter...
			beq	:113			;Ja, weiter...
::112			lda	#%00001000		;Mauszeiger hat aktuelles
			ora	faultData		;PullDown-Menü verlassen.
			sta	faultData
::113			rts

;*** Maustaste auswerten.
:ChkMseButton		lda	mouseData		;Maustaste gedrückt ?
			bmi	:106			;Nein, Ende...

			lda	mouseOn
			and	#%10000000		;Mauszeiger aktiv ?
			beq	:106			;Nein, Ende...

			lda	mouseOn
			and	#%01000000		;Menüs aktiv ?
			beq	:105			;Nein, weiter...
			lda	mouseYPos		;Wenn Maustaste innerhalb
			cmp	DM_MenuRange+0		;eines Menüs gedrückt wurde,
			bcc	:105			;dann Menüeintrag auswerten.
			cmp	DM_MenuRange+1
			beq	:101
			bcs	:105
::101			lda	mouseXPos+1
			cmp	DM_MenuRange+3
			bne	:102
			lda	mouseXPos+0
			cmp	DM_MenuRange+2
::102			bcc	:105
			lda	mouseXPos+1
			cmp	DM_MenuRange+5
			bne	:103
			lda	mouseXPos+0
			cmp	DM_MenuRange+4
::103			beq	:104
			bcs	:105
::104			jmp	DM_ExecMenuJob		;Menüeintrag ausgewählt.

::105			lda	mouseOn
			and	#%00100000		;Icons aktiv ?
			beq	:106			;Nein, weiter...
			jmp	DI_ChkMseClk		;Iconeintrag auswerten.

::106			lda	otherPressVec+0
			ldx	otherPressVec+1
			jmp	CallRoutine
			rts

;*** Mauszeiger hat Bereich verlassen.
:IsMseOnMenu		lda	#%11000000
			bit	mouseOn			;Mauszeiger und Menüs aktiv ?
			bpl	:103			;Nein, Ende...
			bvc	:103			;Nein, Ende...
			lda	menuNumber		;Hauptmenü aktiv ?
			beq	:103			;Ja, übergehen.

			lda	faultData		;Hat Mauszeiger aktuelles Menü
			and	#%00001000		;verlassen ?
			bne	:102			;Ja, ein Menü zurück.
			ldx	#%10000000
			lda	#%11000000
			tay
			bit	DM_MenuType
			bmi	:101
			ldx	#%00100000
::101			txa				;Hat Mauszeiger obere/linke
			and	faultData		;Grenze verlassen ?
			bne	:102			;Ja, ein Menü zurück.
			tya
			bit	DM_MenuType		;Mauszeiger einschränken ?
			bvs	:103			;Nein, weiter...
::102			jsr	xDoPreviousMenu		;Ein Menü zurück.
::103			rts

;*** Pull-Down-Menü erzeugen.
:xDoMenu		sta	DM_MseOnEntry		;Mauszeiger auf Menü-Eintrag.
			ldx	#$00			;Aktives Menü löschen.
			stx	menuNumber
			beq	DM_SaveMenu

;*** Neues Menü öffnen.
:DM_OpenMenu		ldx	menuNumber
			lda	#$00
			sta	DM_MseOnEntry,x

;*** Menüzeiger speichern.
:DM_SaveMenu		lda	r0L			;Zeiger auf Menütabelle
			sta	DM_MenuTabL,x		;zwischenspeichern.
			lda	r0H
			sta	DM_MenuTabH,x
			jsr	DM_SetMenuData		;Menüdaten einlesen.
			sec

;*** Menü initialisieren.
:DM_InitMenu		php
			lda	dispBufferOn		;Bildschirm-Flag
			pha				;zwischenspeichern.
			lda	#%10000000		;Menü nur im Vordergrund
			sta	dispBufferOn		;aufbauen.
			lda	r11H			;Register ":r11"
			pha				;zwischenspeichern.
			lda	r11L
			pha
			jsr	DM_SetMenuRec		;Menüfenster berechnen.

;*** Menü initialisieren (Fortsetzung).
			lda	curPattern+1		;Zeiger auf Füllmuster
			pha				;zwischenspeichern.
			lda	curPattern+0
			pha
			lda	#$00			;Füllmuster #0 für Menü-
			jsr	xSetPattern		;rechteck setzen.
			jsr	xRectangle		;Menü-Rechteck zeichnen.
			pla				;Füllmuster zurückschreiben.
			sta	curPattern+0
			pla
			sta	curPattern+1
			lda	#%11111111		;Rahmen um Menü-Rechteck
			jsr	xFrameRectangle		;zeichnen.
			pla				;Register ":r11" zurücksetzen.
			sta	r11L
			pla
			sta	r11H
			jsr	DM_PrintMenu
			jsr	DM_SetMenuLine
			pla				;Bildschirm-Flag
			sta	dispBufferOn		;zurückschreiben.
			plp
			bit	DM_MenuType		;Menüdefinition testen.
			bvs	:101			; -> Mauszeiger einschränken.
			bcc	:104

;*** Position für Mauszeiger setzen.
::101			ldx	menuNumber
			ldy	DM_MseOnEntry,x
			bit	DM_MenuType		;Menü Vertikal / Horizontal ?
			bmi	:102			; -> Vertikal.
			lda	DM_MenuPosL,y		;Mauszeiger auf die mitte des
			sta	r11L			;gewählten Menüpunktes setzen.
			lda	DM_MenuPosH,y
			sta	r11H
			iny
			lda	DM_MenuPosL,y
			clc
			adc	r11L
			sta	r11L
			lda	DM_MenuPosH,y
			adc	r11H
			sta	r11H
			ror	r11H
			ror	r11L
			lda	DM_MenuRange+0
			clc
			adc	DM_MenuRange+1
			ror
			tay
			clv
			bvc	:103

::102			lda	DM_MenuPosL,y		;Mauszeiger auf die mitte des
			iny				;gewählten Menüpunktes setzen.
			clc
			adc	DM_MenuPosL,y
			lsr
			tay
			lda	DM_MenuRange+2
			clc
			adc	DM_MenuRange+4
			sta	r11L
			lda	DM_MenuRange+3
			adc	DM_MenuRange+5
			sta	r11H
			lsr	r11H
			ror	r11L

::103			sec				;Mausposition setzen.
::104			bit	mouseOn			;Mauszeiger aktiv ?
			bpl	:105			;Nein, weiter...
			lda	#%00100000		;Icons aktivieren.
			ora	mouseOn
			sta	mouseOn
::105			lda	#%01000000		;Menüs aktivieren.
			ora	mouseOn
			sta	mouseOn
			jmp	xStartMouseMode		;Mausabfrage starten.

;*** Menü nochmals anzeigen.
:xReDoMenu		jsr	xMouseOff
			jmp	DM_OpenCurMenu

;*** Zurück zum Hauptmenü.
:xGotoFirstMenu		php
			sei
::101			lda	menuNumber
			cmp	#$00
			beq	:102
			jsr	xDoPreviousMenu
			clv
			bvc	:101
::102			plp
			rts

;*** Vorheriges Menü öffnen.
:xDoPreviousMenu	jsr	xMouseOff
			jsr	xRecoverMenu
			dec	menuNumber

;*** Eingestelltes Menü öffnen (auch über ":ReDoMenu")
:DM_OpenCurMenu		jsr	DM_SetMenuData
			clc
			jmp	DM_InitMenu

;*** Zeiger auf Menüeintrag.
:DM_VecToEntry		pha
			ldy	menuNumber
			lda	DM_MenuTabL,y
			sta	r0L
			lda	DM_MenuTabH,y
			sta	r0H
			pla
			sta	r8L
			asl
			asl
			adc	r8L
			adc	#$07
			tay
			rts

;*** Menü-Daten einlesen.
:DM_SetMenuData		ldx	menuNumber
			lda	DM_MenuTabL,x		;Zeiger auf Eintrag in
			sta	r0L			;Menütabelle berechnen.
			lda	DM_MenuTabH,x
			sta	r0H
			ldy	#$06
			lda	(r0L),y			;Menüdefinition einlesen
			sta	DM_MenuType		;merken.
			dey
::101			lda	(r0L),y			;Menügrenzen einlesen und
			sta	mouseTop,y		;zwischenspeichern.
			sta	DM_MenuRange,y
			dey
			bpl	:101

			lda	GetSerialNumber+2-256,y	;erkennbaren Sinn !
			clc
			adc	#< (xGraphicsString-xGetSerialNumber)
			sta	GraphicsString +2-256,y

			lda	DM_MenuRange+3		;Zeiger auf X_Position für
			sta	r11H			;Menütabelle.
			lda	DM_MenuRange+2
			sta	r11L
			lda	DM_MenuRange+0		;Zeiger auf Y_Position für
			sta	r1H			;Menütabelle.
			bit	DM_MenuType
			bvs	:102
			jsr	SetMseFullWin
::102			rts

;*** Alle Menüeinträge ausgeben.
:DM_PrintMenu		jsr	DM_SvFntData		;Zeichensatzdaten speichern.
			jsr	xUseSystemFont		;Systemzeichensatz aktivieren.
			lda	#$00
			sta	r10H			;Zähler für Einträge löschen.
			sta	currentMode		;Schriftstil "PLAINTEXT".
			sec				;Zeiger auf nächste Position
			jsr	DM_SetNextPos		;für Menüeintrag.

::101			jsr	DM_SvEntryPos		;Position Trennzeile merken.
			clc				;Überstand Menüeintrag setzen.
			jsr	DM_SetNextPos
			jsr	DM_PrintEntry		;Aktuellen Eintrag ausgeben.
			clc				;Überstand Menüeintrag setzen.
			jsr	DM_SetNextPos

			bit	DM_MenuType		;Menü: Vertikal/Horizontal ?
			bpl	:102			; -> Horizontal.

			lda	r1H			; -> Vertikal.
			sec				;Zeiger auf nächste Zeile für
			adc	curSetHight		;Menüeintrag berechnen.
			sta	r1H
			lda	DM_MenuRange+3		;Zeiger auf linken Rand des
			sta	r11H			;Menüfensters.
			lda	DM_MenuRange+2
			sta	r11L
			sec
			jsr	DM_SetNextPos

::102			lda	r10H			;Zeiger auf nächsten Eintrag
			clc				;in Definitionstabelle.
			adc	#$01
			sta	r10H

			lda	DM_MenuType
			and	#%00011111
			cmp	r10H			;Alle Einträge ausgegeben ?
			bne	:101			;Nein, weiter...
			jsr	DM_LdFntData		;Zeichensatz zurücksetzen.
			jmp	DM_SvEntryPos		;Position Trennzeile merken.

;*** Menüeintrag ausgeben.
:DM_PrintEntry		lda	r10H			;Zähler für Menüeinträge
			pha				;zwischenspeichern.
			lda	r10L
			pha
			lda	r10H			;Zeiger auf Menüeintrag
			jsr	DM_VecToEntry		;berechnen.
			lda	(r0L),y			;Zeiger auf Menütext aus
			tax				;Definitionstabelle einlesen.
			iny
			lda	(r0L),y
			sta	r0H
			stx	r0L
			lda	leftMargin+1		;Grenze für linken Rand bei
			pha				;Textausgabe merken.
			lda	leftMargin+0
			pha
			lda	rightMargin+1		;Grenze für rechten Rand bei
			pha				;Textausgabe merken.
			lda	rightMargin+0
			pha
			lda	StringFaultVec+1	;Vektor für Fehlerbehandlung
			pha				;bei Bereichsüberschreitung
			lda	StringFaultVec+0	;merken.
			pha
			lda	#$00			;Grenze für linken Rand bei
			sta	leftMargin+1		;Textausgaben löschen.
			lda	#$00
			sta	leftMargin+0
			sec				;Grenze für rechten Rand bei
			lda	DM_MenuRange+4		;Textausgaben auf Begrenzung
			sbc	#$01			;des Menüfensters setzen.
			sta	rightMargin+0
			lda	DM_MenuRange+5
			sbc	#$00
			sta	rightMargin+1
			lda	#>DM_StopPrint		;Fehlerbehandlungsroutine
			sta	StringFaultVec+1	;installieren.
			lda	#<DM_StopPrint
			sta	StringFaultVec+0
			lda	r1H			;Aktuelle Y-Koordiante
			pha				;zwischenspeichern.
			clc				;Y-Koordinate korrigieren.
			lda	baselineOffset
			adc	r1H
			sta	r1H
			inc	r1H
			jsr	xPutString		;Menutext ausgeben.
			pla				;Aktuelle Y-Koordinate
			sta	r1H			;zurücksetzen.
			pla				;Vektor auf Fehlerbehandlung
			sta	StringFaultVec+0	;bei überschreiten des
			pla				;rechten Randes zurücksetzen.
			sta	StringFaultVec+1
			pla				;Grenze für rechten Rand bei
			sta	rightMargin+0		;Textausgabe zurücksetzen.
			pla
			sta	rightMargin+1
			pla
			sta	leftMargin+0		;Grenze für linken rand bei
			pla				;Textausgabe zurücksetzen.
			sta	leftMargin+1
			pla
			sta	r10L
			pla				;Zähler für Icon-Einträge
			sta	r10H			;zurücksetzen.
			rts

;*** Fehlerroutine Menütext-Ausgabe.
:DM_StopPrint		lda	mouseRight+1
			sta	r11H
			lda	mouseRight+0
			sta	r11L
			rts

;*** Position für Trennzeile merken.
:DM_SvEntryPos		ldy	r10H
			ldx	r1H
			bit	DM_MenuType
			bmi	:101
			lda	r11H
			sta	DM_MenuPosH,y
			ldx	r11L
::101			txa
			sta	DM_MenuPosL,y
			rts

;*** Zeiger auf nächste Position für
;    Menüpunkt berechnen.
:DM_SetNextPos		bcc	DM_NextPos
			bit	DM_MenuType		;Menü: Vertikal/Horizontal ?
			bpl	DM_NextVPos		; -> Horizontal.
			clv
			bvc	DM_NextHPos

:DM_NextPos		bit	DM_MenuType
			bpl	DM_NextHPos

;*** Nächste Position (vertikal).
:DM_NextVPos		lda	r1H
			clc
			adc	#$02
			sta	r1H
			rts

;*** Nächste Position (horizontal).
:DM_NextHPos		lda	r11L
			clc
			adc	#$04
			sta	r11L
			bcc	:101
			inc	r11H
::101			rts

;*** Alle Menüs löschen.
:xRecoverAllMenus	jsr	DM_SetMenuData		;Zeiger auf aktuelles Menü.
			jsr	xRecoverMenu		;Menü zurücksetzen.
			dec	menuNumber		;Eine Menüebene zurück.
			bpl	xRecoverAllMenus	;Noch ein Menü ? ja, weiter...
			lda	#$00			;Menüzähler löschen.
			sta	menuNumber
			rts

;*** Menü/Dialogbox löschen.
:xRecoverMenu		jsr	DM_SetMenuRec		;Zeiger auf aktuelles Menü.
:RecoverDB_Box		lda	RecoverVector+0		;Routine zum zurücksetzen des
			ora	RecoverVector+1		;Hintergrunds installiert ?
			bne	:101			;Ja, weiter...
			lda	#$00			;Bereich über Füllmuster #0
			jsr	SetPattern		;löschen.
			jmp	Rectangle
::101			jmp	(RecoverVector)		;Hintergrund kopieren.
;*** Trennzeile zwischen Menüeinträgen.
:DM_SetMenuLine		lda	DM_MenuType
			and	#%00011111
			sec
			sbc	#$01			;Anzahl Einträge = $00 ?
			beq	:105			;Ja, keine Ausgabe.
			sta	r2L			;Anzahl Trennzeilen merken.

			bit	DM_MenuType		;Vertikales Menü ?
			bmi	:102			;Nein, weiter...

			lda	DM_MenuRange+0		;Obere Grenze für Trennlinie
			clc				;berechnen.
			adc	#$01
			sta	r3L
			lda	DM_MenuRange+1		;Untere Grenze für Trennlinie
			sec				;berechnen.
			sbc	#$01
			sta	r3H

::101			ldx	r2L			;X-Koordinate für Trennzeile
			lda	DM_MenuPosL,x		;einlesen.
			sta	r4L
			lda	DM_MenuPosH,x
			sta	r4H
			lda	#%10101010		;Linie zeichnen.
			jsr	xVerticalLine
			dec	r2L			;Alle Linien gezeichnet ?
			bne	:101			;Nein, weiter...
			rts

::102			lda	DM_MenuRange+3		;Linke Grenze für Trennzeile
			sta	r3H			;berechnen.
			lda	DM_MenuRange+2
			sta	r3L
			inc	r3L
			bne	:103
			inc	r3H
::103			lda	DM_MenuRange+5		;Rechte Grenze für Trennzeile
			sta	r4H			;berechnen.
			lda	DM_MenuRange+4
			sta	r4L
			ldx	#r4L
			jsr	Ddec

::104			ldx	r2L			;Y-Koordinate für Trennzeile
			lda	DM_MenuPosL,x		;einlesen.
			sta	r11L
			lda	#%01010101		;Linie zeichnen.
			jsr	xHorizontalLine
			dec	r2L			;Alle Linien gezeichnet ?
			bne	:104			;Nein, weiter...
::105			rts

;*** Menüfenstergrenzen kopieren.
:DM_SetMenuRec		ldx	#$06
::101			lda	DM_MenuRange-1,x
			sta	r2L         -1,x
			dex
			bne	:101
			rts

;*** Menu-Eintrag ausführen.
:DM_ExecMenuJob		jsr	xMouseOff		;Maus abschalten.
			jsr	DM_EntryRange		;Gewählten Eintrag suchen.
			jsr	InvertMenuArea		;Eintrag invertieren.
			lda	r9L
			ldx	menuNumber		;Gewählten Menüeintrag
			sta	DM_MseOnEntry,x		;zwischenspeichern.
			jsr	DM_GetEntryInfo		;Menüeintrag-Infos einlesen.

			bit	r1L			;Funktion bestimmen.
			bmi	DM_OpenNxMenu		; -> Untermenü öffnen.
			bvs	DM_OpenDynMenu		; -> Routine + Untermenü.

:DM_ExecUsrJob		lda	selectionFlash		;Zähler für Menü-blinken
			sta	r0L			;setzen.
			lda	#$00
			sta	r0H
			jsr	xSleep			;Pause ausführen.
			jsr	DM_EntryRange		;Gewählten Eintrag suchen.
			jsr	InvertMenuArea		;Eintrag invertieren.
			lda	selectionFlash		;Zähler für Menü-blinken
			sta	r0L			;setzen.
			lda	#$00
			sta	r0H
			jsr	xSleep			;Pause ausführen.
			jsr	DM_EntryRange		;Gewählten Eintrag suchen.
			jsr	InvertMenuArea		;Eintrag invertieren.
			jsr	DM_EntryRange		;Gewählten Eintrag suchen.

			ldx	menuNumber
			lda	DM_MseOnEntry,x		;Nummer des gewählten Menüs
			pha				;zwischenspeichern.
			jsr	DM_GetEntryInfo		;Grenzen für Menü einlesen.
			pla
			jmp	(r0)			;Routine aufrufen.

;*** Routine ausführen, Menü öffnen.
:DM_OpenDynMenu		jsr	DM_GotoUsrAdr		;Routine ausführen.
			lda	r0L
			ora	r0H			;Menü verfügbar ?
			bne	DM_OpenNxMenu		;Ja, weiter...
			rts

;*** Nächstes Menü öffnen.
:DM_OpenNxMenu		inc	menuNumber		;Zeiger auf nächstes Menü.
			jmp	DM_OpenMenu		;Menü öffnen.

;*** Menüdaten lesen und
;    Anwenderroutine starten.
:DM_GotoUsrAdr		ldx	menuNumber
			lda	DM_MseOnEntry,x		;Nummer des gewählten Menüs
			pha				;zwischenspeichern.
			jsr	DM_GetEntryInfo		;Grenzen für Menü einlesen.
			pla
			jmp	(r0)			;Routine aufrufen.

;*** Ausgewählten Menüeintrag suchen.
:DM_EntryRange		lda	DM_MenuType
			and	#%00011111
			tay
			lda	DM_MenuType		;Vertikal / Horizontal ?
			bmi	:104			; -> Vertikal.

::101			dey
			lda	mouseXPos+1		;Mauszeiger links von
			cmp	DM_MenuPosH,y		;aktuellem Menüeintrag ?
			bne	:102
			lda	mouseXPos+0
			cmp	DM_MenuPosL,y
::102			bcc	:101			;Ja, -> falscher Eintrag.

			iny				;Linke und rechte Grenze des
			lda	DM_MenuPosL,y		;aktuellen Menüeintrages
			sta	r4L			;berechnen.
			lda	DM_MenuPosH,y
			sta	r4H
			dey
			lda	DM_MenuPosL,y
			sta	r3L
			lda	DM_MenuPosH,y
			sta	r3H
			sty	r9L
			cpy	#$00
			bne	:103
			inc	r3L
			bne	:103
			inc	r3H
::103			ldx	DM_MenuRange+0		;Obere und untere Grenze für
			inx				;aktuellen Menüeintrag
			stx	r2L			;berechnen.
			ldx	DM_MenuRange+1
			dex
			stx	r2H
			rts

::104			lda	mouseYPos
::105			dey
			cmp	DM_MenuPosL,y		;Mauszeiger über Trennlinie ?
			bcc	:105			;Nein, weiter...

			iny
			lda	DM_MenuPosL,y		;Untere und obere Grenze für
			sta	r2H			;aktuellen Menüeintrag
			dey				;berechnen.
			lda	DM_MenuPosL,y
			sta	r2L
			sty	r9L
			cpy	#$00
			bne	:106
			inc	r2L
::106			lda	DM_MenuRange+3		;Linke und rechte Grenze für
			sta	r3H			;aktuellen Menüeintrag
			lda	DM_MenuRange+2		;berechnen.
			sta	r3L
			inc	r3L
			bne	:107
			inc	r3H
::107			lda	DM_MenuRange+5
			sta	r4H
			lda	DM_MenuRange+4
			sta	r4L
			ldx	#r4L
			jsr	Ddec
			rts

;*** Menüeintrag-Information einlesen.
:DM_GetEntryInfo	jsr	DM_VecToEntry
			iny
			iny
			lda	(r0L),y
			sta	r1L
			iny
			lda	(r0L),y
			tax
			iny
			lda	(r0L),y
			sta	r0H
			stx	r0L
			rts

;*** Bereich im Vordergrund invertieren.
:InvertMenuArea		lda	dispBufferOn
			pha
			lda	#%10000000
			sta	dispBufferOn
			jsr	xInvertRectangle
			pla
			sta	dispBufferOn
			rts

;*** Zeichensatzdaten zwischenspeichern.
:DM_SvFntData		ldx	#$09
::101			lda	baselineOffset-1,x
			sta	saveFontTab   -1,x
			dex
			bne	:101
			rts

;*** Zeichensatzdaten zurückschreiben.
:DM_LdFntData		ldx	#$09
::101			lda	saveFontTab   -1,x
			sta	baselineOffset-1,x
			dex
			bne	:101
			rts

;*** Icon-Menü erzeugen.
:xDoIcons		lda	r0H
			sta	DI_VecDefTab+1
			lda	r0L
			sta	DI_VecDefTab+0
			jsr	DI_DrawIcons		;Icons auf Bildschirm ausgeben.
			jsr	SetMseFullWin		;Mausbewegungsgrenzen löschen.
			lda	mouseOn
			and	#%10000000		;Maus aktiv ?
			bne	:101			;Ja, weiter...
			lda	mouseOn			;Nein, Menüs abschalten.
			and	#%10111111
			sta	mouseOn
::101			lda	mouseOn			;Icon-Menü aktivieren.
			ora	#%00100000
			sta	mouseOn
			ldy	#$01
			lda	(DI_VecDefTab),y	;Neue X-Koordinate für
			sta	r11L			;Mauszeiger einlesen.
			iny
			lda	(DI_VecDefTab),y
			sta	r11H
			iny
			lda	(DI_VecDefTab),y	;Neue Y-Koordinate für
			tay				;Mauszeiger einlesen.
			sec
			jmp	xStartMouseMode		;Mauszeiger setzen/starten.

;*** Mausbewegungsgrenzen löschen.
:SetMseFullWin		lda	#$00
			sta	mouseLeft+0
			sta	mouseLeft+1
			sta	mouseTop
			lda	#>$013f
			sta	mouseRight+1
			lda	#<$013f
			sta	mouseRight+0
			lda	#$c7
			sta	mouseBottom
			rts

;*** Zeiger auf Iconeintrag berechnen.
:DI_SetToEntry		asl
			asl
			asl
			clc
			adc	#$04
			tay
			rts

;*** Icons auf Bildschirm ausgeben.
:DI_DrawIcons		lda	#$00
			sta	r10L
::101			lda	r10L			;Zeiger auf Eintrag in
			jsr	DI_SetToEntry		;Definitionstabelle berechnen.
			ldx	#$00			;Icon-Daten nach ":r0"
::102			lda	(DI_VecDefTab),y	;kopieren -> Vorgabewerte für
			sta	r0L,x			;":BitmapUp".
			iny
			inx
			cpx	#$06
			bne	:102
			lda	r0L
			ora	r0H			;Icon verfügbar ?
			beq	:103			;Nein, übergehen...
			jsr	xBitmapUp		;Icon ausgeben.
::103			inc	r10L			;Zeiger auf nächsten Eintrag.
			lda	r10L
			ldy	#$00
			cmp	(DI_VecDefTab),y	;Alle Icons bearbeitet ?
			bne	:101			;Nein, weiter...
			rts

;*** Mausklick auswerten.
:DI_ChkMseClk		lda	DI_VecDefTab+1		;Icon-Tabelle definiert ?
			beq	:101			;Nein, Ende...
			jsr	DI_GetSlctIcon		;Mausklick auswerten.
			bcs	:102			;Icon gewählt ? Ja, weiter...
::101			lda	otherPressVec+0		;Mausklick weiter auswerten.
			ldx	otherPressVec+1
			jmp	CallRoutine

::102			lda	DI_VecToEntry
			bne	:107
			lda	r0L
			sta	DI_SelectedIcon
			sty	DI_VecToEntry
			lda	#%11000000
			bit	iconSelFlag		;Icon invertieren ?
			beq	:105			;Nein, weiter...
			bmi	:103			; -> Blinkendes Icon.
			bvs	:104			; -> Icon invertieren.

::103			jsr	DI_GetIconSize		;Icon-Grenzen berechnen.
			jsr	InvertMenuArea		;Icon invertieren.
			lda	selectionFlash		;Zähler für Icon-blinken
			sta	r0L			;setzen.
			lda	#$00
			sta	r0H
			jsr	xSleep			;Pause ausführen.
			lda	DI_SelectedIcon
			sta	r0L
			ldy	DI_VecToEntry
::104			jsr	DI_GetIconSize
			jsr	InvertMenuArea
::105			ldy	#$1e			;Zähler für Doppelklick
			ldx	#$00			;initialisieren.
			lda	dblClickCount		;Doppelklickauswertung bereits
			beq	:106			;aktiviert ? Nein, weiter...
			ldx	#$ff			;Flag: "Icon-Doppelklick".
			ldy	#$00
::106			sty	dblClickCount		;Zähler Doppelklick setzen.
			stx	r0H			;Doppelklick-Modus setzen.
			lda	DI_SelectedIcon
			sta	r0L
			ldy	DI_VecToEntry
			ldx	#$00
			stx	DI_VecToEntry
			iny
			iny
			lda	(DI_VecDefTab),y
			tax
			dey
			lda	(DI_VecDefTab),y
			jsr	CallRoutine
::107			rts

;*** Gewähltes Icon ermitteln.
:DI_GetSlctIcon		lda	#$00			;Zähler auf ersten
			sta	r0L			;Icon-Eintrag richten.
::101			lda	r0L			;Zeiger auf Icon-Eintrag
			jsr	DI_SetToEntry		;berechnen.
			lda	(DI_VecDefTab),y	;Icon definiert ?
			iny				;Ja, wenn Zeiger auf Icon-
			ora	(DI_VecDefTab),y	;Grafik > $0000.
			beq	:102			;Nein, Eintrag übergehen.
			iny
			lda	mouseXPos+1		;Maus X-Position in CARDs
			lsr				;umrechnen.
			lda	mouseXPos+0
			ror
			lsr
			lsr
			sec				;Mauszeiger rechts von
			sbc	(DI_VecDefTab),y	;X-Position des Icons ?
			bcc	:102			;Nein, nächster Eintrag...
			iny
			iny				;Mauszeiger innerhalb
			cmp	(DI_VecDefTab),y	;des Icons ?
			bcs	:102			;Nein, nächster Eintrag...
			dey
			lda	mouseYPos
			sec				;Mauszeiger unterhalb von
			sbc	(DI_VecDefTab),y	;Y-Position des Icons ?
			bcc	:102			;Nein, nächster Eintrag...
			iny
			iny				;Mauszeiger innerhalb
			cmp	(DI_VecDefTab),y	;des Icons ?
			bcc	:103			;Ja, gewähltes Icon gefunden.
::102			inc	r0L
			lda	r0L			;Zeiger auf nächsten Eintrag.
			ldy	#$00
			cmp	(DI_VecDefTab),y	;Ende Icon-Tabelle erreicht ?
			bne	:101			;Nein, weiter...
			clc				;Flag: "Kein Icon angeklickt".
			rts
::103			sec				;Flag: "Icon angeklickt".
			rts

;*** Icon-Grenzen berechnen.
:DI_GetIconSize		lda	(DI_VecDefTab),y
			dey
			dey
			clc
			adc	(DI_VecDefTab),y
			sec
			sbc	#$01
			sta	r2H
			lda	(DI_VecDefTab),y
			sta	r2L
			dey
			lda	(DI_VecDefTab),y
			sta	r3L
			iny
			iny
			clc
			adc	(DI_VecDefTab),y
			sta	r4L
			lda	#$00
			sta	r3H
			sta	r4H

			ldy	#$03
			ldx	#r3L
			jsr	DShiftLeft
			ldy	#$03
			ldx	#r4L
			jsr	DShiftLeft
			ldx	#r4L
			jsr	Ddec
			rts

;*** Dialogbox erzeugen.
:xDoDlgBox		lda	r0H			;Zeiger auf Dialogboxtabelle
			sta	DB_VecDefTab+1		;zwischenspeichern.
			lda	r0L
			sta	DB_VecDefTab+0

			ldx	#$00
::101			lda	r5L,x			;Variablen zwischenspeichern.
			pha
			inx
			cpx	#$0c
			bne	:101

			jsr	InitDB_Box1
			jsr	DB_DrawBox

			lda	#$00
			sta	r11H
			lda	#$00
			sta	r11L

			jsr	xStartMouseMode		;Mauszeiger aktivieren.
			jsr	xUseSystemFont		;Systemzeichensatz starten.

			ldx	#$0b
::102			pla				;Variablen zurückschreiben.
			sta	r5L,x
			dex
			bpl	:102

			ldy	#$00
			ldx	#$07			;Zeiger auf erstes Datenbyte.
			lda	(DB_VecDefTab),y	;Definitionsbyte einlesen.
			bpl	:103			; -> Größenangaben übergehen.
			ldx	#$01

::103			txa				;Zeiger auf Datentabelle.
			tay
::104			lda	(DB_VecDefTab),y	;Dialogbox-Code einlesen
			sta	r0L			;und merken.
			beq	StartDB_Box		;$00 ? Ja, Ende...

			ldx	#$00
::105			lda	r5L,x			;Variablen zwischenspeichern.
			pha
			inx
			cpx	#$0c
			bne	:105

			iny				;Zeiger auf Datentabelle
			sty	r1L			;zwischenspeichern.

			ldy	r0L			;Dialogbox-Code einlesen.
			lda	DB_BoxCTabL -1,y	;Routine zum DB_Box-Code
			ldx	DB_BoxCTabH -1,y	;aufrufen.
			jsr	CallRoutine

			ldx	#$0b
::106			pla				;Variablen zurückschreiben.
			sta	r5L,x
			dex
			bpl	:106

			ldy	r1L			;Zeiger auf Dialogboxtabelle
			clv				;zurücksetzen und Tabelle
			bvc	:104			;weiter auswerten.

;*** Dialogbox definiert -> starten.
:StartDB_Box		lda	DB_Icon_Tab		;Icons in Dialogbox ?
			beq	:101			;Nein, weiter...
			lda	#>DB_Icon_Tab		;Icons in Dalogbox über
			sta	r0H			;":DoIcons" aktivieren.
			lda	#<DB_Icon_Tab
			sta	r0L
			jsr	DoIcons

::101			pla
			sta	DB_ReturnAdr+0		;LOW -Byte Rücksprungadresse.
			pla
			sta	DB_ReturnAdr+1		;HIGH-Byte Rücksprungadresse.
			tsx
			stx	DB_RetStackP		;Stackzeiger merken.
			jmp	MainLoop

;*** Tabelle mit Einsprungadressen für
;    Dialogbox-Steuercodes.
:DB_BoxCTabL		b <DB_SysIcon  , <DB_SysIcon, <DB_SysIcon  , <DB_SysIcon
			b <DB_SysIcon  , <DB_SysIcon, $cd          , $cd
			b $cd          , $cd        , <DB_TextStrg , <DB_VarTxtStrg
			b <DB_GetString, <DB_SysOpV , <DB_GraphStrg, <DB_GetFiles
			b <DB_OpVec    , <DB_UsrIcon, <DB_UserRout

:DB_BoxCTabH		b >DB_SysIcon  , >DB_SysIcon, >DB_SysIcon  , >DB_SysIcon
			b >DB_SysIcon  , >DB_SysIcon, $cd          , $cd
			b $cd          , $cd        , >DB_TextStrg , >DB_VarTxtStrg
			b >DB_GetString, >DB_SysOpV , >DB_GraphStrg, >DB_GetFiles
			b >DB_OpVec    , >DB_UsrIcon, >DB_UserRout

;*** Dialogbox initialisieren.
;    Aktuelle GEOS-Variabln speichern
;    und auf Standard zurücksetzen.
:InitDB_Box1		lda	CPU_DATA		;CPU-Register speichern.
			pha
			lda	#%00110101		;I/O-Bereich aktivieren.
			sta	CPU_DATA

			lda	#>dlgBoxRamBuf		;GEOS-Variablen im Bereich
			sta	r4H			;":dlgBoxRamBuf" speichern.
			lda	#<dlgBoxRamBuf
			sta	r4L
			jsr	DB_SvGeosVar

			lda	#$01			;Mauszeiger einschalten.
			sta	mobenble

			pla
			sta	CPU_DATA		;CPU-Register zurücksetzen.
			jsr	GEOS_Init2		;GEOS-Variablen auf Standard.
			lda	#$00			;DB_Box-Status löschen.
			sta	sysDBData
			rts

;*** Dialogbox zeichen.
:DB_DrawBox		lda	#%10100000
			sta	dispBufferOn		;Nur im Vordergrund zeichen.

			ldy	#$00			;Definitionsbyte aus
			lda	(DB_VecDefTab),y	;Dialogboxtabelle einlesen.
			and	#%00011111		;Schatten zeichnen ?
			beq	:101			;Nein, weiter...
			jsr	SetPattern		;Füllmuster für Schatten.
			sec				;Position für Schatten
			jsr	DB_DefBoxPos		;berechnen.
			jsr	Rectangle		;Schatten zeichnen.

::101			lda	#$00			;Füllmuster für Dialogbox.
			jsr	SetPattern
			clc				;Position für Dialogbox
			jsr	DB_DefBoxPos		;berechnen.
			lda	r4H			;Grenze für Textausgaben
			sta	rightMargin+1		;definieren.
			lda	r4L
			sta	rightMargin+0
			jsr	Rectangle		;Dialogbox zeichnen.
			clc				;Position für Dialogbox
			jsr	DB_DefBoxPos		;berechnen.
			lda	#$ff			;Rahmen um Dialogbox
			jsr	FrameRectangle		;zeichnen.
			lda	#$00			;Icon-Tabelle löschen.
			sta	DB_Icon_Tab+0
			sta	DB_Icon_Tab+1
			sta	DB_Icon_Tab+2
			rts

;*** Dialogbox löschen.
:ClearDB_Box		ldy	#$00			;Definitionsbyte aus
			lda	(DB_VecDefTab),y	;Dialogboxtabelle einlesen.
			and	#%00011111		;Schatten zeichnen ?
			beq	:101			;Nein, weiter...
			sec				;Schatten löschen.
			jsr	:102
::101			clc				;Dialogbox löschen.
::102			jsr	DB_DefBoxPos
			jmp	RecoverDB_Box

;*** Position für Dialogbox berechnen.
:DB_DefBoxPos		lda	#$00			;Dialogbox berechnen ?
			bcc	:101			;Ja, weiter...
			lda	#$08			;Schatten berechnen.
::101			sta	r1H			;Zeiger auf Differenz.

			lda	DB_VecDefTab+1		;Zeiger auf Dialogboxtabelle
			pha				;zwischenspeichern.
			lda	DB_VecDefTab+0
			pha

			ldy	#$00
			lda	(DB_VecDefTab),y	;Standard-Dialogbox ?
			bpl	:102			;Nein, weiter...

			lda	#>StdDB_BoxPos -1	;Zeiger auf Standard-
			sta	DB_VecDefTab+1		;Dialogboxtabelle setzen.
			lda	#<StdDB_BoxPos -1
			sta	DB_VecDefTab+0

::102			ldx	#$00
			ldy	#$01
::103			lda	(DB_VecDefTab),y	;YOben/YUnten berechnen.
			clc
			adc	r1H
			sta	r2L,x
			iny
			inx
			cpx	#$02
			bne	:103

::104			lda	(DB_VecDefTab),y	;XLinks/XRechts berechnen.
			clc
			adc	r1H
			sta	r2L,x
			iny
			inx
			lda	(DB_VecDefTab),y
			bcc	:105
			adc	#$00
::105			sta	r2L,x
			iny
			inx
			cpx	#$06
			bne	:104

			pla				;Zeiger auf Dialogboxtabelle
			sta	DB_VecDefTab+0		;zurücksetzen.
			pla
			sta	DB_VecDefTab+1
			rts

;*** Daten für Standard-Dialogbox.
:StdDB_BoxPos		b $20,$7f
			w $0040,$00ff

;*** Dialogbox beenden.
:xRstrFrmDialogue	jsr	InitDB_Box2
			jsr	ClearDB_Box
			lda	sysDBData
			sta	r0L
			ldx	DB_RetStackP
			txs
			lda	DB_ReturnAdr+1
			pha
			lda	DB_ReturnAdr+0
			pha
			rts

;*** Dialogbox beenden.
;    GEOS-Variablen zurücksetzen.
:InitDB_Box2		lda	CPU_DATA		;CPU-Register speichern.
			pha
			lda	#%00110101		;I/O-Bereich aktivieren.
			sta	CPU_DATA

			lda	#>dlgBoxRamBuf		;GEOS-Variablen im Bereich
			sta	r4H			;":dlgBoxRamBuf" speichern.
			lda	#<dlgBoxRamBuf
			sta	r4L
			jsr	DB_LdGeosVar

			pla
			sta	CPU_DATA		;CPU-Register zurücksetzen.
			rts

;*** GEOS-Variablen speichern.
:DB_SvGeosVar		ldx	#$00
			ldy	#$00
::101			jsr	DB_SetMemVec
			beq	:103
::102			lda	(r2L),y
			sta	(r4L),y
			iny
			dec	r3L
			bne	:102
			beq	:101
::103			rts

;*** GEOS-Variablen laden.
:DB_LdGeosVar		php
			sei
			ldx	#$00
			ldy	#$00
::101			jsr	DB_SetMemVec
			beq	:103
::102			lda	(r4L),y
			sta	(r2L),y
			iny
			dec	r3L
			bne	:102
			beq	:101
::103			plp
			rts

;*** Zeiger auf den zu sichernden Speicherberich aus Tabelle lesen.
:DB_SetMemVec		tya
			clc
			adc	r4L
			sta	r4L
			bcc	:101
			inc	r4H
::101			ldy	#$00
			lda	DB_SaveMemTab,x		;Low -Byte.
			sta	r2L
			inx
			lda	DB_SaveMemTab,x		;High-Byte.
			sta	r2H
			inx
			ora	r2L
			beq	:102
			lda	DB_SaveMemTab,x		;Anzahl Bytes.
			sta	r3L
			inx
::102			rts

;*** Zeiger auf die zu sichernden Speicherbereiche für ":DoDlgBox".
:DB_SaveMemTab		w curPattern
			b $17
			w appMain
			b $26
			w DI_VecDefTab
			b $02
			w DM_MenuType
			b $31
			w ProcCurDelay
			b $e3
			w obj0Pointer
			b $08
			w mob0xpos
			b $11
			w mobenble
			b $01
			w mobprior
			b $03
			w mcmclr0
			b $02
			w mob1clr
			b $07
			w moby2
			b $01
			w $0000

;*** Dialogbox-Icon darstellen.
:DB_SysIcon		dey				;Icon "OK" ?
			bne	:101			;Nein, weiter...
			lda	keyVector+0
			ora	keyVector+1		;Tastaturabfrage aktiv ?
			bne	:101			;Ja, weiter...
			lda	#>DB_ChkEnter		;Tastaturabfrage installieren,
			sta	keyVector+1		;bei <RETURN> wird das "OK" -
			lda	#<DB_ChkEnter		;Icon aktiviert !
			sta	keyVector+0
::101			tya				;Zeiger auf Icon-Eintrag für
			asl				;Dialogbox-Icon berechnen.
			asl
			asl
			clc
			adc	#<SysIconTab
			sta	r5L
			lda	#$00
			adc	#>SysIconTab
			sta	r5H
			jsr	DB_DefIconPos		;Ausgabeposition berechnen
			jmp	DB_CopyIconInTab	;Icon in Tabelle kopieren.

;*** User-Icon darstellen.
:DB_UsrIcon		jsr	DB_DefIconPos		;Ausgabeposition berechnen
			lda	(DB_VecDefTab),y	;Zeiger auf Icon-Eintrag
			sta	r5L			;des User-Icons einlesen.
			iny
			lda	(DB_VecDefTab),y
			sta	r5H
			iny
			tya
			pha
			jsr	DB_CopyIconInTab	;Icon in Tabelle kopieren.
			pla
			sta	r1L
			rts

;*** Position für System-/User-Icon
;    berechnen.
:DB_DefIconPos		clc
			jsr	DB_DefBoxPos
			lsr	r3H
			ror	r3L
			lsr	r3L
			lsr	r3L
			ldy	r1L
			lda	(DB_VecDefTab),y
			clc
			adc	r3L
			sta	r3L
			iny
			lda	(DB_VecDefTab),y
			clc
			adc	r2L
			sta	r2L
			iny
			sty	r1L
			rts

;*** Icon-Daten in Tabelle für die
;    Routine ":DoIcons" kopieren.
:DB_CopyIconInTab	ldx	DB_Icon_Tab
			cpx	#$08
			bcs	:104
			txa
			inx
			stx	DB_Icon_Tab
			jsr	DI_SetToEntry
			tax
			ldy	#$00
::101			lda	(r5L),y
			cpy	#$02
			bne	:102
			lda	r3L
::102			cpy	#$03
			bne	:103
			lda	r2L
::103			sta	DB_Icon_Tab,x
			inx
			iny
			cpy	#$08
			bne	:101
::104			rts

;*** Icon-Tabellen für System-Icons.
:SysIconTab		w $bfa9				;*** Icon_OK
			b $00,$00,$06,$10
			w DB_Icon_OK

			w $bf58				;*** Icon_Close
			b $00,$00,$06,$10
			w DB_Icon_CANCEL

			w Icon_YES
			b $00,$00,$06,$10
			w DB_Icon_YES

			w Icon_NO
			b $00,$00,$06,$10
			w DB_Icon_NO

			w Icon_OPEN
			b $00,$00,$06,$10
			w DB_Icon_OPEN

			w Icon_DISK
			b $00,$00,$06,$10
			w DB_Icon_DISK

;*** GEOS-Tastaturabfrage für die
;    Dialogbox zum "OK"-Icon.
:DB_ChkEnter		lda	keyData
			cmp	#$0d
			beq	DB_Icon_OK
			rts

;*** Dialogbox beenden / System-Icon.
:DB_Icon_OK		lda	#$01			;OK
			bne	DB_SetIcon
:DB_Icon_CANCEL		lda	#$02			;CANCEL
			bne	DB_SetIcon
:DB_Icon_YES		lda	#$03			;YES
			bne	DB_SetIcon
:DB_Icon_NO		lda	#$04			;NO
			bne	DB_SetIcon
:DB_Icon_OPEN		lda	#$05			;OPEN
			bne	DB_SetIcon
:DB_Icon_DISK		lda	#$06			;DISK
			bne	DB_SetIcon
:DB_SetIcon		sta	sysDBData		;Rückgabewert festlegen und
			jmp	RstrFrmDialogue		;Dialogbox beenden.

;*** Steuercode: DBSYSOPV
:DB_SysOpV		lda	#>DB_ChkSysOpV
			sta	otherPressVec+1
			lda	#<DB_ChkSysOpV
			sta	otherPressVec+0
			rts

;*** DBSYSOPV-Routine.
:DB_ChkSysOpV		bit	mouseData		;Maustaste gedrückt ?
			bmi	DB_NoFunc		;Nein, weiter...
			lda	#$0e
			sta	sysDBData		;Rückgabewert festlegen und
			jmp	RstrFrmDialogue		;Dialogbox beenden.

;*** Steuercode: DBOPVEC
:DB_OpVec		ldy	r1L
			lda	(DB_VecDefTab),y	;Mausklick-Routine
			sta	otherPressVec+0		;installieren.
			iny
			lda	(DB_VecDefTab),y
			sta	otherPressVec+1
			iny
			sty	r1L
:DB_NoFunc		rts

;*** Steuercode: DBGRAPHSTR
:DB_GraphStrg		ldy	r1L
			lda	(DB_VecDefTab),y	;Zeiger auf Grafikbefehle
			sta	r0L			;einlesen.
			iny
			lda	(DB_VecDefTab),y
			sta	r0H
			iny
			tya
			pha
			jsr	GraphicsString		;Grafikbefehle ausführen.
			pla
			sta	r1L
			rts

;*** Steuercode: DB_USR_ROUT
:DB_UserRout		ldy	r1L
			lda	(DB_VecDefTab),y	;Zeiger auf Anwender-Routine
			sta	r0L			;einlesen.
			iny
			lda	(DB_VecDefTab),y
			tax
			iny
			tya
			pha
			lda	r0L
			jsr	CallRoutine		;Anwender-Routine ausführen.
			pla
			sta	r1L
			rts

;*** Steuercode: DBTXTSTR
:DB_TextStrg		clc				;Dialogbox-Koordinaten
			jsr	DB_DefBoxPos		;berechnen.
			jsr	DB_GetTextPos		;Textposition berechnen.
			lda	(DB_VecDefTab),y	;Zeiger auf Textstring
			sta	r0L			;einlesen.
			iny
			lda	(DB_VecDefTab),y
			sta	r0H
			iny
			tya
			pha
			jsr	PutString		;Text ausgeben.
			pla
			sta	r1L
			rts

;*** Steuercode: DBVARSTR
:DB_VarTxtStrg		clc				;Dialogbox-Koordinaten
			jsr	DB_DefBoxPos		;berechnen.
			jsr	DB_GetTextPos		;Textposition berechnen.
			lda	(DB_VecDefTab),y	;Zeiger auf Textstring
			iny				;einlesen.
			tax
			lda	zpage+0,x
			sta	r0L
			lda	zpage+1,x
			sta	r0H
			tya
			pha
			jsr	PutString		;Text ausgeben.
			pla
			sta	r1L
			rts

;*** Steuercode: DBGETSTRING
:DB_GetString		clc				;Dialogbox-Koordinaten
			jsr	DB_DefBoxPos		;berechnen.
			jsr	DB_GetTextPos		;Textposition berechnen.
			lda	(DB_VecDefTab),y	;Zeiger auf Textstring
			iny				;einlesen.
			tax
			lda	zpage+0,x
			sta	r0L
			lda	zpage+1,x
			sta	r0H
			lda	(DB_VecDefTab),y	;Max. Anzahl Zeichen
			sta	r2L			;einlesen.
			iny
			lda	#>DB_EndGetStrg		;Tastaturabfrage für <RETURN>
			sta	keyVector+1		;installieren.
			lda	#<DB_EndGetStrg
			sta	keyVector+0
			lda	#$00
			sta	r1L
			tya
			pha
			jsr	GetString
			pla
			sta	r1L
			rts

;*** Dialogbox-Texteingabe beenden.
:DB_EndGetStrg		lda	#$0d
			sta	sysDBData		;Rückgabewert festlegen und
			jmp	RstrFrmDialogue		;Dialogbox beenden.

;*** X/Y-Koordinate für Textausgabe.
:DB_GetTextPos		ldy	r1L
			lda	(DB_VecDefTab),y
			clc
			adc	r3L
			sta	r11L
			lda	r3H
			adc	#$00
			sta	r11H
			iny
			lda	(DB_VecDefTab),y
			iny
			clc
			adc	r2L
			sta	r1H
			rts

;*** Steuercode: DBGETFILES
:DB_GetFiles		ldy	r1L
			lda	(DB_VecDefTab),y	;Ausgabeposition für
			sta	DB_GetFileX		;Dateifenster.
			iny
			lda	(DB_VecDefTab),y
			sta	DB_GetFileY

			iny
			tya
			pha

			lda	r5H			;Zeiger auf Dateiablage-
			sta	DB_FileTabVec+1		;bereich zwischenspeichern.
			lda	r5L
			sta	DB_FileTabVec+0

			jsr	DB_FileWinPos

			lda	r3H			;Breite des Ausgabefensters
			ror				;in CARDS berechnen.
			lda	r3L
			ror
			lsr
			lsr
			clc
			adc	#$07
			pha

			lda	r2H			;Y-Position für ersten Eintrag
			sec				;in Dateifenster.
			sbc	#$0e
			pha

			lda	r7L			;GEOS-Filetyp merken.
			pha

			lda	r10H			;Zeiger auf GEOS-Klasse
			pha				;zwischenspeichern.
			lda	r10L
			pha

			lda	#$ff			;Rahmen um Dateifenster
			jsr	FrameRectangle		;zeichnen.

			sec				;Trennzeile Dateifenster und
			lda	r2H			;Scroll-Pfeile zeichnen.
			sbc	#$10
			sta	r11L
			lda	#$ff
			jsr	HorizontalLine

			pla				;Zeiger auf GEOS-Klasse
			sta	r10L			;zurücksetzen.
			pla
			sta	r10H
			pla				;GEOS-Filetyp
			sta	r7L			;zurücksetzen.

			lda	#$0f			;Max. 15 Dateien einlesen.
			sta	r7H

			lda	#>fileTrScTab		;Zeiger auf Speicherbereich
			sta	r6H			;für Dateinamen.
			lda	#<fileTrScTab
			sta	r6L
			jsr	FindFTypes		;Dateien suchen.
			pla
			sta	r2L
			pla
			sta	r3L
			sta	DB_GetFileIcon+2
			lda	#$0f			;Anzahl gefundener Dateien
			sec				;berechnen.
			sbc	r7H			;Dateien gefunden ?
			beq	:102			;Nein, weiter...
			sta	DB_FilesInTab		;Anzahl Dateien merken.
			cmp	#$06			;Mehr als 6 Dateien ?
			bcc	:101			;Nein, weiter...
			lda	#>DB_GetFileIcon	;Ja, Scroll-Pfeile in
			sta	r5H			;Tabelle kopieren.
			lda	#<DB_GetFileIcon
			sta	r5L
			jsr	DB_CopyIconInTab

::101			lda	#>DB_SlctNewFile	;Mausabfrage für Dateiauswahl
			sta	otherPressVec+1		;installieren.
			lda	#<DB_SlctNewFile
			sta	otherPressVec+0

			jsr	DB_FindFileInTab
			jsr	DB_PutFileNames
			jsr	DB_FileInBuf
::102			pla
			sta	r1L
			rts

;*** Gewählte Datei suchen..
:DB_FindFileInTab	lda	DB_FilesInTab		;Zeiger auf letzte Datei
			pha				;in Tabelle.
::101			pla
			sec
			sbc	#$01
			pha
			beq	:103
			jsr	DB_SetCmpVec		;Zeiger auf Datei berechnen.

			ldy	#$00
::102			lda	(r0L),y			;Dateinamen vergleichen.
			cmp	(r1L),y			;Übereinstimmung ?
			bne	:101			;Nein, nächste Datei...
			tax				;Ende Dateiname erreicht ?
			beq	:103			;Ja, Name gefunden, weiter...
			iny				;Nächstes Zeichen aus
			bne	:102			;Dateiname vergleichen.

::103			pla
			sta	DB_SelectedFile
			sec
			sbc	#$04
			bpl	:104
			lda	#$00
::104			sta	DB_1stFileInTab
			rts

;*** Icon-Tabelle für Scrollpfeile.
;    ":DB_GetFileIcon"+2 enthält die
;    linke Grenze für Scrollpfeile,
;    Angabe in CARDs !!!
:DB_GetFileIcon		w DB_ArrowGrafx
			b $00,$00,$03,$0c
			w DB_MoveFileList

;*** Daten für Scroll-Icon.
:DB_ArrowGrafx		b $03,%11111111;%11111111,%11111111
			b $9e,%10000000,%00000000,%00000001
			b     %10000000,%00000000,%00000001
			b     %10000010,%00000000,%11100001
			b     %10000111,%00000111,%11111101
			b     %10001111,%10000011,%11111001
			b     %10011111,%11000001,%11110001
			b     %10111111,%11100000,%11100001
			b     %10000111,%00000000,%01000001
			b     %10000000,%00000000,%00000001
			b     %10000000,%00000000,%00000001
			b $03,%11111111;%11111111,%11111111

;*** DBGETFILES: Datei auswählen.
:DB_SlctNewFile		lda	mouseData		;Maustaste gedrückt ?
			bmi	:102			;Nein, weiter...
			jsr	DB_FileWinPos		;Fenstergrenzen berechnen.
			clc
			lda	r2L
			adc	#$45
			sta	r2H
			jsr	IsMseInRegion		;Mausklick innerhalb Fenster ?
			beq	:102			;Nein, Abbruch...
			jsr	DB_InvSlctFile		;Gewählte Datei invertieren.

			jsr	DB_FileWinPos		;Zeiger auf gewählte
			lda	mouseYPos		;Datei berechnen.
			sec
			sbc	r2L
			sta	r0L
			lda	#$00
			sta	r0H
			sta	r1H
			lda	#$0e
			sta	r1L
			ldx	#r0L
			ldy	#r1L
			jsr	Ddiv

			lda	r0L			;Mausklick gültig ?
			clc
			adc	DB_1stFileInTab
			cmp	DB_FilesInTab
			bcc	:101			;Ja, weiter...
			ldx	DB_FilesInTab		;Zeiger auf letzte Datei.
			dex
			txa
::101			sta	DB_SelectedFile		;Gewählte Datei merken.
			jsr	DB_InvSlctFile		;Datei invertieren.
			jsr	DB_FileInBuf
::102			rts

;*** Dateiliste verschieben.
:DB_MoveFileList	jsr	DB_InvSlctFile		;Dateiauswahl aufheben.
			lda	#$00			;Grenze zwischen linken und
			sta	r0H			;rechten Scrollpfeil berechnen.
			lda	DB_GetFileIcon+2
			asl
			asl
			asl
			rol	r0H
			clc
			adc	#$0c
			sta	r0L
			bcc	:101
			inc	r0H

::101			ldx	DB_1stFileInTab		;Zeiger auf erste Datei.
			lda	r0H			;Dateiliste nach oben
			cmp	mouseXPos+1		;verschieben ?
			bne	:102
			lda	r0L
			cmp	mouseXPos+0
::102			bcc	:103			;Nein, weiter...
			dex				;Zeiger auf letzte Datei.
			bpl	:104			;Überprüfen.

::103			inx				;Zeiger auf nächste Datei.
			lda	DB_FilesInTab
			sec
			sbc	DB_1stFileInTab
			cmp	#$06			;Nächste Datei verfügbar ?
			bcc	:105			;Nein, -> weiter...

::104			stx	DB_1stFileInTab		;Erste Datei in Tabelle merken.

::105			lda	DB_1stFileInTab		;Gewählte Datei noch
			cmp	DB_SelectedFile		;innerhalb Dateifenster ?
			bcc	:106			;Ja, weiter...
			sta	DB_SelectedFile		;Nein, neue Datei wählen.
::106			clc
			adc	#$04
			cmp	DB_SelectedFile
			bcs	:107
			sta	DB_SelectedFile
::107			jsr	DB_FileInBuf		;Gewählte Datei in Puffer.
			jmp	DB_PutFileNames		;Dateinamen ausgeben.

;*** Dateiname in Zwischenspeicher.
:DB_FileInBuf		lda	DB_SelectedFile		;Zeiger auf gewählte Datei.
			jsr	DB_SetCmpVec
			ldy	#r1L			;Datei in Zwischenspeicher
			jmp	CopyString		;kopieren.

;*** Vergleichszeiger setzen.
:DB_SetCmpVec		ldx	#r0L
			jsr	DB_SetFileNam
			lda	DB_FileTabVec+1		;Zeiger auf Speicher für
			sta	r1H			;gewählte Datei.
			lda	DB_FileTabVec+0
			sta	r1L
			rts

;*** Zeiger auf Dateinamen berechnen.
;    Zeiger auf Name im Akku,
;    Ablage in ZeroPage über xReg!
:DB_SetFileNam		sta	r0L
			lda	#$11
			sta	r1L
			txa
			pha
			ldy	#r0L
			ldx	#r1L
			jsr	BBMult
			pla
			tax
			lda	r1L
			clc
			adc	#<fileTrScTab
			sta	zpage+0,x
			lda	#>fileTrScTab
			adc	#$00
			sta	zpage+1,x
			rts

;*** Dateiname im Fenster ausgeben.
:DB_PutFileNames	lda	rightMargin+1		;Rechte Textgrenze merken.
			pha
			lda	rightMargin+0
			pha

			lda	#$00			;Dateifenstergrenzen
			jsr	DB_SetWinEntry		;berechnen.

			lda	r4H			;Neue Textausgabegrenze
			sta	rightMargin+1		;festlegen.
			lda	r4L
			sta	rightMargin+0

			lda	#$00
			sta	r15L			;Zeiger auf erste Datei.
			jsr	SetPattern		;Füllmuster "löschen" setzen.

			lda	DB_1stFileInTab		;Zeiger auf ersten Dateinamen
			ldx	#r14L			;in Dateifenster.
			jsr	DB_SetFileNam

			lda	#%01000000		;Fettschrift einschalten.
			sta	currentMode

::101			lda	r15L			;Fensterbereich für
			jsr	DB_SetWinEntry		;Dateieintrag löschen.
			jsr	Rectangle

			lda	r3H			;X-Koordinate für
			sta	r11H			;Dateiname innerhalb des
			lda	r3L			;Dateifensters setzen.
			sta	r11L
			lda	r2L			;Y-Koordinate für
			clc				;Dateiname innerhalb des
			adc	#$09			;Dateifensters berechnen.
			sta	r1H
			lda	r14H			;Zeiger auf Dateiname.
			sta	r0H
			lda	r14L
			sta	r0L
			jsr	PutString		;Dateiname ausgeben.

			clc				;Zeiger auf nächste Datei.
			lda	#$11
			adc	r14L
			sta	r14L
			bcc	:102
			inc	r14H

::102			inc	r15L			;Datei-Zähler +1.
			lda	r15L
			cmp	#$05			;5 Dateien ausgegeben ?
			bne	:101			;Nein, weiter...

			jsr	DB_InvSlctFile		;Gewählte Datei anzeigen.

			lda	#$00			;":currentMode" löschen.
			sta	currentMode

			pla				;Textausgabegrenzen
			sta	rightMargin+0		;zurücksetzen.
			pla
			sta	rightMargin+1
			rts

;*** Gewählte Datei invertieren.
:DB_InvSlctFile		lda	DB_SelectedFile
			sec
			sbc	DB_1stFileInTab
			jsr	DB_SetWinEntry
			jmp	InvertRectangle

;*** Rahmen für Dateifenster berechnen.
:DB_FileWinPos		clc				;Grenze für Dialogbox
			jsr	DB_DefBoxPos		;berechnen.

			lda	DB_GetFileX		;X-Koordinate Dateifenster
			clc				;berechnen.
			adc	r3L
			sta	r3L
			bcc	:101
			inc	r3H

::101			clc				;Breite des Dateifensters
			adc	#$7c			;berechnen.
			sta	r4L
			lda	#$00
			adc	r3H
			sta	r4H

			lda	DB_GetFileY		;Obere und untere Grenze
			clc				;des Dateifensters berechnen.
			adc	r2L
			sta	r2L
			adc	#$58
			sta	r2H
			rts

;*** Bildschirmgrenzen für Datei-
;    eintrag berechnen.
:DB_SetWinEntry		sta	r0L
			lda	#$0e
			sta	r1L
			ldy	#r1L
			ldx	#r0L
			jsr	BBMult
			jsr	DB_FileWinPos
			lda	r0L
			clc
			adc	r2L
			sta	r2L
			clc
			adc	#$0e
			sta	r2H
			inc	r2L
			dec	r2H
			inc	r3L
			bne	:101
			inc	r3H
::101			ldx	#r4L
			jsr	Ddec
			rts

;*** Daten für "NO"-Icon.
:Icon_NO		b $05,$ff,$82,$fe,$80,$04,$00,$82
			b $03,$80,$04,$00,$b8,$03,$80,$1c
			b $c0,$18,$00,$03,$80,$1c,$c0,$00
			b $00,$03,$80,$1e,$cf,$3b,$e0,$03
			b $80,$1e,$d9,$9b,$b0,$03,$80,$1b
			b $d9,$9b,$30,$03,$80,$1b,$df,$9b
			b $30,$03,$80,$19,$d8,$1b,$30,$03
			b $80,$19,$d9,$9b,$30,$03,$80,$18
			b $cf,$1b,$30,$03,$80,$04,$00,$82
			b $03,$80,$04,$00,$81,$03,$06,$ff
			b $81,$7f

;*** Daten für "YES"-Icon.
:Icon_YES		b $05,$ff,$82,$fe,$80,$04,$00,$82
			b $03,$80,$04,$00,$b8,$03,$80,$00
			b $0c,$00,$00,$03,$80,$00,$0c,$00
			b $00,$03,$80,$00,$0c,$f0,$00,$03
			b $80,$00,$0d,$98,$00,$03,$80,$00
			b $0c,$f8,$00,$03,$80,$00,$0d,$98
			b $00,$03,$80,$01,$8d,$98,$00,$03
			b $80,$01,$8d,$98,$00,$03,$80,$00
			b $f8,$f8,$00,$03,$80,$04,$00,$82
			b $03,$80,$04,$00,$81,$03,$06,$ff
			b $81,$7f

;*** Daten für "OPEN"-Icon.
:Icon_OPEN		b $05,$ff,$82,$fe,$80,$04,$00,$be
			b $03,$99,$80,$00,$00,$00,$03,$99
			b $87,$1c,$00,$00,$03,$80,$0c,$30
			b $00,$00,$03,$8f,$9e,$79,$f1,$e7
			b $c3,$98,$cc,$31,$db,$37,$63,$98
			b $cc,$31,$9b,$36,$63,$98,$cc,$31
			b $9b,$f6,$63,$98,$cc,$31,$9b,$06
			b $63,$98,$cc,$31,$9b,$36,$63,$8f
			b $8c,$31,$99,$e6,$63,$80,$04,$00
			b $82,$03,$80,$04,$00,$81,$03,$06
			b $ff,$81,$7f

;*** Daten für "DISK"-Icon.
:Icon_DISK		b $05,$ff,$81,$fe,$e3,$02,$86,$80
			b $00,$00,$00,$00,$03,$b6,$80,$1f
			b $0c,$03,$00,$03,$80,$19,$80,$03
			b $00,$03,$80,$18,$dc,$f3,$30,$03
			b $80,$18,$cd,$9b,$60,$03,$80,$18
			b $cd,$83,$c0,$03,$80,$18,$cc,$f3
			b $80,$03,$80,$18,$cc,$1b,$c0,$03
			b $80,$19,$8d,$9b,$60,$03,$80,$1f
			b $0c,$f3,$30,$03,$e3,$02,$86,$80
			b $00,$00,$00,$00,$03,$06,$ff,$81
			b $7f,$05,$ff

;*** Maus- und Tastatur abfragen.
:ExecMseKeyb		bit	pressFlag		;Eingabetreiber geändert ?
			bvc	:101			;Nein, weiter...

			lda	#%10111111
			and	pressFlag
			sta	pressFlag
			lda	inputVector+0
			ldx	inputVector+1
			jsr	CallRoutine

::101			lda	pressFlag
			and	#%00100000		;Wurde Mausknopf gedrückt ?
			beq	:102			;Nein, weiter...

			lda	#%11011111
			and	pressFlag
			sta	pressFlag
			lda	mouseVector+0		;Mausklick ausführen.
			ldx	mouseVector+1
			jsr	CallRoutine

::102			bit	pressFlag		;Wurde Taste gedrückt ?
			bpl	:103			;Nein, weiter...

			jsr	GetKeyFromBuf		;Taste aus Tastaturpuffer.
			lda	keyVector+0		;Tastaturabfrage des Anwenders
			ldx	keyVector+1		;aufrufen.
			jsr	CallRoutine

::103			lda	faultData		;Hat Maus Bereich verlassen ?
			beq	xESC_RULER		;Nein, weiter...

			lda	mouseFaultVec+0		;Maus hat bereich verlassen,
			ldx	mouseFaultVec+1		;zugehörige Anwender-Routine
			jsr	CallRoutine		;aufrufen.
			lda	#$00
			sta	faultData
:xESC_RULER		rts

;*** GEOS-Systeminterrupt!
:GEOS_IRQ		cld
			sta	IRQ_BufAkku
			pla
			pha
			and	#%00010000		;Standard IRQ ?
			beq	:101			;Ja, weiter...
			pla
			jmp	(BRKVector)		;BRK-Abbruch.

::101			txa				;Register zwischenspeichern.
			pha
			tya
			pha
			lda	CallRoutVec+1		;Variablen zwischenspeichern.
			pha
			lda	CallRoutVec+0
			pha
			lda	returnAddress+1
			pha
			lda	returnAddress+0
			pha

			ldx	#$00
::102			lda	r0L,x
			pha
			inx
			cpx	#$20
			bne	:102

			lda	CPU_DATA		;CPU-Register speichern.
			pha
			lda	#%00110101		;I/O-Bereich aktivieren.
			sta	CPU_DATA

			lda	dblClickCount		;Auf Doppelklick testen ?
			beq	:103			;Nein, weiter...
			dec	dblClickCount		;Zähler korrigieren.

::103			ldy	keyMode			;Erste Taste einlesen ?
			beq	:104			;Ja, weiter...
			iny				;Taste in ":currentKey" ?
			beq	:104			;Nein, weiter...
			dec	keyMode

::104			jsr	GetMatrixCode

			lda	AlarmAktiv
			beq	:105
			dec	AlarmAktiv

::105			lda	intTopVector+0		;IRQ/GEOS.
			ldx	intTopVector+1
			jsr	CallRoutine

			lda	intBotVector+0		;IRQ/Anwender.
			ldx	intBotVector+1
			jsr	CallRoutine

			lda	#$01			;Raster-IRQ-Flag setzen.
			sta	grirq

			pla				;CPU-Register wieder
			sta	CPU_DATA		;zurücksetzen.

			ldx	#$1f			;Variablen zurückschreiben.
::106			pla
			sta	r0L,x
			dex
			bpl	:106

			pla
			sta	returnAddress+0
			pla
			sta	returnAddress+1
			pla
			sta	CallRoutVec+0
			pla
			sta	CallRoutVec+1
			pla				;Register wieder einlesen.
			tay
			pla
			tax
			lda	IRQ_BufAkku

;*** Einsprung bei RESET/NMI.
:IRQ_END		rti

;*** Wurde Taste gedrückt ?
:GetMatrixCode		lda	keyMode			;Taste in ":currentKey" ?
			bne	:101			;Nein, weiter...
			lda	currentKey
			jsr	NewKeyInBuf
			lda	#%00001111		;Flag: "Taste in Puffer"
			sta	keyMode			;setzen.

::101			lda	#$00			;Keine Taste gedrückt.
			sta	r1H
			jsr	CheckKeyboard		;Wurde Taste gedrückt ?
			bne	:105			;Nein, Ende...
			jsr	SHIFT_CBM_CTRL		;SHIFT/CBM/CTRL auswerten.
							;In r1H steht das Ergebnis!

			ldy	#$07
::102			jsr	CheckKeyboard		;Wurde Taste gedrückt ?
			bne	:105			;Nein, Ende...

			lda	KeyMatrixData,y		;Reihe #0 bis #7 durchsuchen.
			sta	$dc00

			lda	$dc01			;Spaltenregister einlesen und
			cmp	KB_LastKeyTab,y		;mit letztem Wert vergleichen.
			sta	KB_LastKeyTab,y		;Neuen Wert merken.
			bne	:104			;Wurde Taste gedrückt ?
							;Ja, weiter...

			cmp	KB_MultipleKey,y	;Mit letzter Taste vergleichen.
			beq	:104			;Übereinstimmung, weiter...
			pha
			eor	KB_MultipleKey,y	;War vorher Taste gedrückt ?
			beq	:103			;Ja, -> Dauerfunktion.
			jsr	MultipleKeyMod		;Neue Taste einlesen.
::103			pla
			sta	KB_MultipleKey,y	;Neue Taste merken.
::104			dey
			bpl	:102			;Nächste Reihe testen.
::105			rts

;*** Tastatur abfragen.
;    Wurde Taste gedrückt ?
:CheckKeyboard		lda	#$ff
			sta	$dc00
			lda	$dc01
			cmp	#$ff
			rts

;*** Taste auswerten,
;    auf Dauerfunktion testen.
:MultipleKeyMod		sta	r0L
			lda	#$07
			sta	r1L

::101			lda	r0L
			ldx	r1L
			and	BitData2,x
			beq	:110
			tya
			asl
			asl
			asl
			adc	r1L
			tax

			bit	r1H			;Wurde SHIFT/CBM gedrückt ?
			bpl	:102			;Nein, weiter...
			lda	keyTab1,x		;Taste mit SHIFT einlesen.
			clv
			bvc	:103

::102			lda	keyTab0,x		;Taste ohne SHIFT einlesen.
::103			sta	r0H			;Taste speichern.
			lda	r1H
			and	#%00100000		;Wurde CTRL-Taste gedrückt ?
			beq	:104			;Nein, weiter...

			lda	r0H			;Tastencode einlesen.
			jsr	TestForLowChar		;Zeichenwert isolieren.
			cmp	#$41			;Buchstabentaste gedrückt ?
			bcc	:104			;Nein, weiter...
			cmp	#$5b
			bcs	:104			;Nein, weiter...
			sec				;Ja, CTRL-Taste erzeugen.
			sbc	#$40			;(Codes von $01-$1A)
			sta	r0H

::104			bit	r1H			;Wurde CBM-Taste gedrückt ?
			bvc	:105			;Nein, weiter...
			lda	r0H			;Ja, Bit #7 aktivieren.
			ora	#%10000000
			sta	r0H

::105			lda	r0H
			sty	r0H

			ldy	#$02			;Wurde Taste "<",">" oder "^"
::106			cmp	SpecialKeyTab,y		;gedrückt ?
			beq	:107			;Ja, weiter...
			dey
			bpl	:106
			bmi	:108			;Keine Sondertaste.

::107			lda	ReplaceKeyTab,y		;Ersatzcode für Tasten "<",
							;">" und "^" verwenden.

::108			ldy	r0H
			sta	r0H
			and	#$7f			;Tastencode isolieren.
			cmp	#%00011111		;Taste SHIFT/CBM/CTRL ?
			beq	:109			;Ja, übergehen...

			ldx	r1L
			lda	r0L
			and	BitData2,x
			and	KB_MultipleKey,y
			beq	:109

			lda	#%00001111		;Dauerfunktion, Taste max. 16x
			sta	keyMode			;ausführen -> Puffer voll.
			lda	r0H
			sta	currentKey		;Neue Taste merken und
			jsr	NewKeyInBuf		;in Tastaturpuffer schreiben.
			clv
			bvc	:110

::109			lda	#%11111111		;Keine Taste in
			sta	keyMode			;":currentKey" gespeichert.
			lda	#$00
			sta	currentKey

::110			dec	r1L			;Nächste Spalte testen.
			bmi	:111
			jmp	:101

::111			rts

;*** Tabelle mit Tastaturabfrage-
;    adressen für Reihe #0 bis #7.
:KeyMatrixData		b $fe,$fd,$fb,$f7
			b $ef,$df,$bf,$7f

;*** Spezialtasten, werden von GEOS
;    durch GEOS-spezifische Tasten
;    ersetzt.
:SpecialKeyTab		b $bb,$ba,$e0
:ReplaceKeyTab		b $3c,$3e,$5e

;*** Tastaturtabelle #0.
;    Tasten ohne SHIFT/CBM/CTRL.
;    Entsprechend Tastaturmatrix!
:keyTab0		b $1d,$0d,$1e,$0e,$01,$03,$05,$11
			b $33,$77,$61,$34,$79,$73,$65,$1f
			b $35,$72,$64,$36,$63,$66,$74,$78
			b $37,$7a,$67,$38,$62,$68,$75,$76
			b $39,$69,$6a,$30,$6d,$6b,$6f,$6e
			b $7e,$70,$6c,$27,$2e,$7c,$7d,$2c
			b $1f,$2b,$7b,$12,$1f,$23,$1f,$2d
			b $31,$14,$1f,$32,$20,$1f,$71,$16

;*** Tastaturtabelle #1.
;    Tasten mit SHIFT.
;    Entsprechend Tastaturmatrix!
:keyTab1		b $1c,$0d,$08,$0f,$02,$04,$06,$10
			b $40,$57,$41,$24,$59,$53,$45,$1f
			b $25,$52,$44,$26,$43,$46,$54,$58
			b $2f,$5a,$47,$28,$42,$48,$55,$56
			b $29,$49,$4a,$3d,$4d,$4b,$4f,$4e
			b $3f,$50,$4c,$60,$3a,$5c,$5d,$3b
			b $5e,$2a,$5b,$13,$1f,$27,$1f,$5f
			b $21,$14,$1f,$22,$20,$1f,$51,$17

;*** Neue Taste in Tastaturpuffer.
:NewKeyInBuf		php
			sei
			pha
			lda	#$80
			ora	pressFlag
			sta	pressFlag
			ldx	MaxKeyInBuf
			pla
			sta	keyBuffer,x
			jsr	Add1Key
			cpx	keyBufPointer
			beq	:101
			stx	MaxKeyInBuf
::101			plp
			rts

;*** Zeichen aus Tastaturpuffer holen.
:GetKeyFromBuf		php
			sei
			ldx	keyBufPointer
			lda	keyBuffer,x
			sta	keyData
			jsr	Add1Key
			stx	keyBufPointer
			cpx	MaxKeyInBuf
			bne	:101
			pha
			lda	#$7f
			and	pressFlag
			sta	pressFlag
			pla
::101			plp
			rts

;*** Zähler für ":MaxKeyInBuf" und
;    ":keyBufPointer" korrigieren.
:Add1Key		inx
			cpx	#$10
			bne	:101
			ldx	#$00
::101			rts

;*** Zeichen über Tastatur einlesen.
:xGetNextChar		bit	pressFlag
			bpl	:101
			jmp	GetKeyFromBuf
::101			lda	#$00			;Keine Taste gedrückt.
			rts

;*** Gedrückte Taste aus Matrix mit
;    SHIFT/CBM/CTRL verknüpfen.
:SHIFT_CBM_CTRL		lda	#%11111101		;Linke SHIFT-Taste abfragen.
			sta	$dc00			;Tastaturabfrage Reihe #1.
			lda	$dc01			;Spaltenregister einlesen.
			eor	#%11111111
			and	#%10000000		;Bit #7 = Spalte 7 gesetzt ?
			bne	:101			;Ja, SHIFT-Taste gedrückt.

			lda	#%10111111		;Rechte SHIFT-Taste abfragen.
			sta	$dc00			;Tastaturabfrage Reihe #6.
			lda	$dc01			;Spaltenregister einlesen.
			eor	#%11111111
			and	#%00010000		;Bit #4 = Spalte 4 gesetzt ?
			beq	:102			;Nein, weiter...

::101			lda	#%10000000		;Zeichen in Tastenspeicher
			ora	r1H			;mit SHIFT verknüpfen.
			sta	r1H

::102			lda	#%01111111		;CBM-Taste abfragen.
			sta	$dc00			;Tastaturabfrage Reihe #7.
			lda	$dc01			;Spaltenregister einlesen.
			eor	#%11111111
			and	#%00100000		;Bit #5 = Spalte 5 gesetzt ?
			beq	:103			;Nein, weiter...

			lda	#%01000000		;Zeichen in Tastenspeicher
			ora	r1H			;mit CBM verknüpfen.
			sta	r1H

::103			lda	#%01111111		;CTRL-Taste abfragen.
			sta	$dc00			;Tastaturabfrage Reihe #7.
			lda	$dc01			;Spaltenregister einlesen.
			eor	#%11111111
			and	#%00000100		;Bit #2 = Spalte 2 gesetzt ?
			beq	:104

			lda	#%00100000		;Zeichen in Tastenspeicher
			ora	r1H			;mit CTRL verknüpfen.
			sta	r1H
::104			rts

;*** Auf Taste für Kleinbuchstaben
;    testen.
:TestForLowChar		pha				;Zeichen merken.
			and	#%01111111		;GEOS nur von $20 - $7F !!!
			cmp	#$61			;Kleinbuchstabe ?
			bcc	:101			;Nein, weiter...
			cmp	#$7b
			bcs	:101			;Nein, weiter...
			pla
			sec				;Ja, in Großbuchstaben
			sbc	#$20			;umrechnen.
			pha
::101			pla
			rts

;*** GEOS-Uhrzeit aktualisieren.
:SetGeosClock		sei
			ldx	CPU_DATA
			lda	#%00110101
			sta	CPU_DATA

			lda	$dc0f			;Uhrzeit aktivieren.
			and	#$7f
			sta	$dc0f

			lda	hour			;Aktuelle Stunde aus GEOS-
			cmp	#$0c			;Register einlesen.
			bmi	:101			;Bit #7 gesetzt ? Ja, weiter...

			bit	$dc0b			;AM/PM-Flag testen.
			bmi	:101			;PM ? Ja, weiter...
			jsr	GetNextDay		;Ja, neuen Tag beginnen.

::101			lda	$dc0b			;12-Stunden-Uhrzeit in
			and	#$1f			;24-Stunden-Uhrzeit umrechnen.
			cmp	#$12
			bne	:102
			lda	#$00

::102			bit	$dc0b			;AM/PM-Flag testen.
			bpl	:103			;Nein, weiter...
			sed				;Uhrzeit im Bereich 12-23 Uhr.
			clc
			adc	#$12
			cld
::103			jsr	BCDtoDEZ		;Stunde berechnen.
			sta	hour
			lda	$dc0a
			jsr	BCDtoDEZ		;Minute berechnen.
			sta	minutes
			lda	$dc09
			jsr	BCDtoDEZ		;Sekunde berechnen.
			sta	seconds
			lda	$dc08			;Uhrzeit starten.

			ldy	#$02
::104			lda	year,y			;Aktuelles Datum in
			sta	dateCopy,y		;Zwischenspeicher kopieren.
			dey
			bpl	:104

			lda	$dc0d			;Alarm-Zustand einlesen.
			sta	r1L

			stx	CPU_DATA		;I/O abschalten.

			bit	alarmSetFlag		;Weckzeit aktiviert ?
			bpl	:105			;Nein, weiter...
			and	#%00000100		;Weckzeit erreicht ?
			beq	:106			;Nein, weiter...

			lda	#%01001010		;Flag: "Weckzeit erreicht"
			sta	alarmSetFlag		;setzen.
			lda	alarmTmtVector+1	;Weckroutine definiert ?
			beq	:105			;Nein, Weckton ausgeben.
			jmp	(alarmTmtVector)	;Weckroutine anspringen.

::105			bit	alarmSetFlag		;Weckzeit erreicht ?
			bvc	:106			;Nein, weiter...
			jsr	DoAlarmSound		;Weckton aktivieren.
::106			cli
			rts

;*** Neuen Tag definieren.
:GetNextDay		ldy	month			;Zeiger auf Tagestabelle.
			lda	DaysPerMonth -1,y	;Anzahl Tage/Monat einlesen.
			cpy	#$02			;Monat = "Februar" ?
			bne	:102			;Nein, weiter...
			tay
			lda	year			;Auf Schaltjahr testen.
			and	#$03
			bne	:101
			iny				;"Februar" = 29 Tage.
::101			tya

::102			cmp	day			;Letzter Tag erreicht ?
			bne	:105			;Nein, weiter...
			ldy	#$00			;Tag auf Anfangswert setzen.
			sty	day
			lda	month
			cmp	#$0c			;Letzter Monat erreicht ?
			bne	:104			;Nein, weiter...
			sty	month			;Monat auf Anfangswert setzen.
			lda	year
			cmp	#$63			;Letztes Jahr (99) erreicht ?
			bne	:103			;Nein, weiter...
			dey				;Jahr auf Anfangswert setzen.
			sty	year
::103			inc	year			;Datum +1.
::104			inc	month
::105			inc	day
			rts

;*** Tabelle mit der Anzahl von
;    Tagen pro Monat.
:DaysPerMonth		b 31,28,31,30,31,30
			b 31,31,30,31,30,31

;*** BCD nach DEZ wandeln.
:BCDtoDEZ		pha
			and	#%11110000
			lsr
			lsr
			lsr
			lsr
			tay
			pla
			and	#%00001111
			clc
::101			dey
			bmi	:102
			adc	#10
			bne	:101
::102			rts

;*** Warnton "Wecker" ausgeben.
:DoAlarmSound		lda	AlarmAktiv
			bne	:103

			ldy	CPU_DATA
			lda	#%00110101
			sta	CPU_DATA

			ldx	#$18
::101			lda	AlarmSoundData,x
			sta	$d400,x
			dex
			bpl	:101

			ldx	#$21
			lda	alarmSetFlag
			and	#$3f
			bne	:102
			tax
::102			stx	$d404
			sty	CPU_DATA

			lda	#%00011110
			sta	AlarmAktiv
			dec	alarmSetFlag

::103			rts

;*** Daten für SID/Alarmton.
:AlarmSoundData		b $00,$10,$00,$08,$40,$08,$00,$00
			b $00,$00,$00,$00,$00,$00,$00,$00
			b $00,$00,$00,$00,$00,$00,$00,$00
			b $0f,$00,$00,$00,$00,$0f

;*** Maustreiber.
:InitMouse		jmp	$fe8c
:SlowMouse		jmp	$fe98
:UpdateMouse		jmp	$fe99

			b $10
			b $84
			b $7f

			lda	#$00
			sta	mouseXPos+1
			lda	#$08
			sta	mouseXPos+0
			lda	#$08
			sta	mouseYPos
			rts

			bit	mouseOn
			bmi	$fea0
			jmp	$ff50

			lda	CPU_DATA
			pha
			lda	#%00110101
			sta	CPU_DATA

			lda	$dc02
			pha
			lda	$dc03
			pha
			lda	$dc00
			pha

			lda	#$00
			sta	$dc02
			sta	$dc03

			lda	$dc01
			and	#$10
			cmp	$fe89
			beq	$fed4
			sta	$fe89
			asl
			asl
			asl
			sta	mouseData

			lda	pressFlag
			ora	#$20
			sta	pressFlag

			lda	#$ff
			sta	$dc02
			lda	#$40
			sta	$dc00

			ldx	#$66
			nop
			nop
			nop
			dex
			bne	$fee0

			stx	r1L

			lda	$d419
			ldy	$fe8a
			jsr	$ff61
			sty	$fe8a
			cmp	#$00
			beq	$ff04
			pha
			and	#$80
			bne	$feff
			lda	#$40
			ora	r1L
			sta	r1L
			pla
			clc
			adc	mouseXPos+0
			sta	mouseXPos+0
			txa
			adc	mouseXPos+1
			sta	mouseXPos+1

			lda	$d41a
			ldy	$fe8b
			jsr	$ff61
			sty	$fe8b
			cmp	#$00
			beq	$ff2d
			pha
			and	#$80
			lsr
			lsr
			lsr
			bne	$ff28
			lda	#$20
			ora	r1L
			sta	r1L
			pla

			sec
			eor	#$ff
			adc	mouseYPos
			sta	mouseYPos

			lda	r1L
			lsr
			lsr
			lsr
			lsr
			tax
			lda	$ff51,x
			sta	inputData

			pla
			sta	$dc00
			pla
			sta	$dc03
			pla
			sta	$dc02
			pla
			sta	CPU_DATA
			rts

			b $ff,$06,$02,$ff
			b $00,$07,$01,$ff
			b $04,$05,$03,$ff
			b $ff,$ff,$ff,$ff

			sty	r0L
			sta	r0H

			ldx	#$00
			sec
			sbc	r0L
			and	#$7f
			cmp	#$40
			bcs	$ff76
			lsr
			beq	$ff83
			ldy	r0H
			rts

			ora	#$c0
			cmp	#$ff
			beq	$ff83
			sec
			ror

			ldx	#$ff
			ldy	r0H
			rts

			lda	#$00
			rts

			rti

			ora	pressFlag
			sta	pressFlag
			jsr	$ff18
			lda	$fe90
			and	#$10
			cmp	$fe8e
			beq	$ffa9
			sta	$fe8e
			asl
			asl
			asl
			eor	#$80
			sta	mouseData
			lda	#$20
			ora	pressFlag
			sta	pressFlag
			rts

			b $ff,$02,$06,$ff
			b $04,$03,$05,$ff
			b $00,$01,$07,$ff
			b $ff,$ff,$ff,$ff

			lda	$ffe8,x
			sta	r1L
			lda	$ffea,x
			sta	r2L

			lda	$fff2,x
			pha

			ldx	#r1L
			ldy	#$02
			jsr	BBMult
			ldx	#r2L
			jsr	BBMult
			pla

			pha
			bpl	$ffdd
			ldx	#r1L
			jsr	Dnegate
			pla
			and	#$40
			beq	$ffe7
			ldx	#r2L
			jsr	Dnegate
			rts

			b $ff,$b5,$00,$b5
			b $ff,$b5,$00,$b5
			b $ff,$b5,$00,$40
			b $40,$c0,$80,$80
			b $00,$00

;*** C64/C128 - Systemvektoren.
:NMI_VECTOR		w IRQ_END
:RESET_VECTOR		w IRQ_END
:IRQ_VECTOR		w GEOS_IRQ

;*** Ende GEOS-Quellcode!
