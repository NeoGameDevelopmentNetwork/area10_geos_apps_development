; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** X-Koordinaten (Pixel) auf CARDs
;    umrechnen. Die Bits im ersten und
;    letzten CARD werden in ":r8L" bzw.
;    ":r8H" gespeichert.
:GetCARDs		jsr	xGetScanLine_r11	;Zeilenadresse berechnen.
			lda	r4L
			and	#%00000111		;Anzahl zu setzender Bits im
			tax				;letzten CARD berechnen.
			lda	BitData4,x
			sta	r8H
			lda	r3L
			and	#%00000111		;Anzahl zu setzender Bits im
			tax				;ersten CARD berechnen.
			lda	BitData3,x
			sta	r8L
			lda	r3L
			and	#%11111000
			sta	r3L
:SetXHighCards		lda	r4L
			and	#%11111000
			sta	r4L
			rts

;*** X-Koordinate in Grafikspeicher berechnen.
:DefLineXPos		ldy	r3L			;X-Koordinate in Grafikspeicher
			lda	r3H			;berechnen.
			beq	Compare_r3_r4
			inc	r5H
			inc	r6H

;*** Register r3 und r4 vergleichen.
:Compare_r3_r4		lda	r3H			;Erstes CARD gleich letztes
			cmp	r4H			;CARD ?
			bne	:51
			lda	r3L
			cmp	r4L
::51			rts				;Ja, weiter...

;*** Länge der Grafikzeile in Pixel berechnen.
:GetLenPixelLine	lda	r4L
			sec
			sbc	r3L
			sta	r4L
			lda	r4H
			sbc	r3H
			sta	r4H

			lsr	r4H			;Anzahl Pixel in CARDs
			ror	r4L			;umrechnen.
			lsr	r4L
			lsr	r4L
			rts

;*** 2 Words und 1 Byte aus Programmtext einlesen.
.Get2Word1Byte		ldy	#$00
::51			iny
			lda	(returnAddress)   ,y
			sta	r0              -1,y
			cpy	#$05
			bne	:51
			rts

;*** 3 Bytes über ":r0" einlesen.
:Get3Bytes		jsr	Get1Byte
			tax
			jsr	Get1Byte
			sta	r2L
			jsr	Get1Byte
			ldy	r2L
			rts

;*** 1 Byte über ":r0" einlesen.
:Get1Byte		ldy	#$00
			lda	(r0L),y
			jsr	SetNxByte_r0
			cmp	#$00
			rts

;*** Horizontale Linie zeichen.
;    r2L  = yLow
;    r3   = xLow
;    r4   = xHigh
;    Akku = Linienmuster
:xHorizontalLine	sta	r7L			;Linienmuster merken.

			ldx	#$03			;X-Koordinaten auf Stapel
::50			lda	r3L,x			;retten.
			pha
			dex
			bpl	:50

			jsr	GetCARDs		;Startwerte für aktuelle Zeile.

			jsr	DefLineXPos		;X-Koord. in Grafikspeicher und
							;Erstes CARD = letztes CARD ?
			beq	:55			;Ja, weiter...

			jsr	GetLenPixelLine		;Länge der Grafikzeile in
							;Pixel berechnen.

			lda	r8L			;Linienmuster für erstes
			jsr	GetLinePattern		;CARD berechnen.

::53			jsr	WriteCurCard		;Linienmuster kopieren.
			beq	:56			;Fertig ? Ja, weiter...
			lda	r7L			;Lnienmuster einlesen und
			jmp	:53			;beschreiben.

;*** Nur 1 CARD beschreiben.
::55			lda	r8L			;Bits im ersten und letzten
			ora	r8H			;CARD addieren.
			jmp	:57

::56			lda	r8H			;Linienmuster für letztes CARD.
::57			jsr	GetLinePattern		;Muster berechnen.

;*** Letes Byte in Zeile beschreiben.
:SetLastGrByt		sta	(r6L),y 			;Letztes Byte in Grafik-
			sta	(r5L),y			;speicher übertragen.

;*** Grafikroutinen beenden.
;    X-Koordinaten zurückschreiben.
:ExitGrafxRout		ldx	#$00
::51			pla
			sta	r3L,x
			inx
			cpx	#$04
			bcc	:51
			rts

;*** Linienmuster berechnen.
:GetLinePattern		sta	r11H
			and	(r5L),y
			sta	r7H
			lda	r11H
			eor	#%11111111
			and	r7L
			ora	r7H
			rts

;*** Daten in aktuelles CARD kopieren.
:WriteCurCard		sta	(r6L),y			;Linienmuster in Grafikspeicher
			sta	(r5L),y			;übertragen.
:PosToNextCard		tya				;Zeiger auf nähstes CARD
			clc				;berechnen.
			adc	#$08
			tay
			bcc	:51
			inc	r5H
			inc	r6H
::51			dec	r4L			;Zähler für CARDs korrigieren.
			rts

;*** Horizontale Linie invertieren.
;    r2L      = yLow
;    r3 /r4   = xLow/xHigh
:xInvertLine		ldx	#$03			;X-Koordinaten auf Stapel
::50			lda	r3L,x			;retten.
			pha
			dex
			bpl	:50

			jsr	GetCARDs		;Startwerte für aktuelle Zeile.

			jsr	DefLineXPos		;X-Koord. in Grafikspeicher und
							;Erstes CARD = letztes CARD ?
			beq	:55			;Ja, weiter...

			jsr	GetLenPixelLine		;Länge der Grafikzeile in
							;Pixel berechnen.

			lda	r8L			;Linienmuster für erstes
			eor	(r5L),y			;CARD berechnen.

::53			eor	#%11111111
			jsr	WriteCurCard		;Linienmuster invertieren.
			beq	:56			;Fertig ? Ja, weiter...
			lda	(r5L),y			;Lnienmuster einlesen und
			jmp	:53			;beschreiben.

;*** Nur 1 CARD beschreiben.
::55			lda	r8L			;Bits im ersten und letzten
			ora	r8H			;CARD addieren.
			jmp	:57

::56			lda	r8H
::57			eor	#%11111111		;Muster für letztes Grafik-
			eor	(r5L),y			;CARD berechnen.
			jmp	SetLastGrByt

;*** Zeile aus Vordergrund in Hinter-
;    grund kopieren. Wird von Routine
;    ":ImprintRectangle" benötigt.
:ImprintRecLine		ldx	#$03			;X-Koordinaten auf Stapel
::50			lda	r3L,x			;retten.
			pha
			dex
			bpl	:50

			jsr	GetStartLine		;Startwerte für aktuelle Zeile.

			lda	r5L			;Startadressen der Linien im
			ldy	r6L			;Vorder- und Hintergrund-
			sta	r6L			;Grafikspeicher vertauschen.
			sty	r5L
			lda	r5H
			ldy	r6H
			sta	r6H
			sty	r5H
			jmp	MovGrafxData

;*** Startwerte für aktuelle Zeile berechnen.
:GetStartLine		lda	dispBufferOn		;Bildschirm-Flag speichern.
			pha
			ora	#%11000000		;Grafikdaten in Vorder- und
			sta	dispBufferOn		;Hintergrundspeicher schreiben.
			jsr	GetCARDs		;Startwerte für aktuelle Zeile.
			pla
			sta	dispBufferOn		;Bildschirm-Flag zurücksetzen.
			rts

;*** Horizontale Linie aus dem Hinter-
;    grund in den Vordergrund kopieren.
;    r2L      = yLow
;    r3 /r4   = xLow/xHigh
:xRecoverLine		ldx	#$03			;X-Koordinaten auf Stapel
::50			lda	r3L,x			;retten.
			pha
			dex
			bpl	:50

			jsr	GetStartLine		;Startwerte für aktuelle Zeile.

;*** Rechteck zwischen Vorder- und
;    Hintergrundgrafik kopieren.
:MovGrafxData		jsr	DefLineXPos		;X-Koord. in Grafikspeicher und
							;Erstes CARD = letztes CARD ?
			beq	:55			;Ja, weiter...

			jsr	GetLenPixelLine		;Länge der Grafikzeile in
							;Pixel berechnen.

			lda	r8L			;Erstes Card erzeugen.
			jsr	LinkGrafxMem

::53			jsr	PosToNextCard		;Zeiger auf nähstes CARD.
			beq	:56			;Fertig ? Ja, weiter...

			lda	(r6L),y			;Byte aus Speicher #1 in
			sta	(r5L),y			;Speicher #2 kopieren.
			jmp	:53			;Nächstes Byte kopieren.

;*** Nur 1 CARD beschreiben.
::55			lda	r8L			;Bits im ersten und letzten
			ora	r8H			;CARD addieren.
			jmp	:57

::56			lda	r8H			;Linienmuster für letztes CARD.
::57			jsr	LinkGrafxMem		;Muster berechnen.
			jmp	ExitGrafxRout		;Routine abschließen.

;*** Byte aus Vordergrund mit Byte
;    aus Hintergrund verknüpfen.
:LinkGrafxMem		sta	r7L
			and	(r5L),y
			sta	r7H
			lda	r7L
			eor	#%11111111
			and	(r6L),y
			ora	r7H
			sta	(r5L),y
			rts

;*** Vertikale Linie zeichen.
;    r3L/r3H  = yLow/yHigh
;    r4       =      xHigh
;    Akku = Linienmuster
:xVerticalLine		sta	r8L			;Linienmuster merken.

			lda	r4L			;LOW-Byte der X-Koordinate
			pha				;zwischenspeichern.
			and	#%00000111
			tax
			lda	BitData1,x		;Zeiger auf Bit in Byte
			sta	r7H			;berechnen und merken.

			jsr	SetXHighCards		;X-Koordinate in 8-Byte-Wert
							;umrechnen.

			ldy	#$00
			ldx	r3L			;Zeiger auf Bytereihe in CARD.

::51			stx	r7L			;Aktuelle Zeile merken.
			jsr	xGetScanLine		;Zeilenadresse berechnen.

			lda	r4L			;Zeiger auf CARD-Spalte in
			clc				;Vordergrund-Grafikspeicher
			adc	r5L			;berechnen.
			sta	r5L
			lda	r4H
			adc	r5H
			sta	r5H

			lda	r4L			;Zeiger auf CARD-Spalte in
			clc				;Hintergrund-Grafikspeicher
			adc	r6L			;berechnen.
			sta	r6L
			lda	r4H
			adc	r6H
			sta	r6H

			lda	r7L			;Aktuelle Zeile einlesen.
			and	#%00000111		;8-Bit-Wert ermitteln.
			tax
			lda	BitData1,x		;Zu setzendes Bit berechnen.
			and	r8L			;Mit Linienmuster verknüpfen.
			bne	:52			;Bit setzen ? Ja, weiter...

			lda	r7H			;Bit an X-Koordinate löschen.
			eor	#%11111111
			and	(r5L),y
			jmp	:53

::52			lda	r7H			;Bit an X-Koordinate setzen.
			ora	(r5L),y
::53			sta	(r6L),y
			sta	(r5L),y
			ldx	r7L
			inx
			cpx	r3H
			beq	:51
			bcc	:51
			pla
			sta	r4L
			rts

;*** Inline: Rechteck zeichen.
;    b yLow,yHigh
;    w xLow,xHigh
:xi_Rectangle		jsr	GetInlineData		;Inline-Daten einlesen.
			jsr	xRectangle		;Rechteck zeichnen.
.Exit7ByteInline	php
			lda	#$07			;Routine beenden.
			jmp	DoInlineReturn

;******************************************************************************
;*** Neue xRectangle-Routine.
;******************************************************************************
;*** GraphicsString: RECTANGLETO
:GS_RECTANGLETO		jsr	GS_GetXYpar

			t "-G3_NewRec"
;******************************************************************************

;******************************************************************************
;*** Schnelle Rechteck-Routine.
;******************************************************************************
			t "-G3_FastRec"
;******************************************************************************

;*** Rechteck invertieren.
;    r2L/r2H = yLow/yHigh
;    r3 /r4  = xLow/xHigh
:xInvertRectangle	lda	#<xInvertLine
			ldx	#>xInvertLine
			bne	DoRecJob

;*** Rechteck herstellen.
;    r2L/r2H = yLow/yHigh
;    r3 /r4  = xLow/xHigh
:xRecoverRec		lda	#<xRecoverLine
			ldx	#>xRecoverLine
			bne	DoRecJob

;*** Rechteck speichern.
;    r2L/r2H = yLow/yHigh
;    r3 /r4  = xLow/xHigh
:xImprintRec		lda	#<ImprintRecLine
			ldx	#>ImprintRecLine

;*** Rechteck-Job ausführen.
:DoRecJob		sta	:51 +1
			stx	:51 +2

			lda	r2L			;Startzeile als Anfangswert
			sta	r11L			;für Rectangle setzen.
::51			jsr	$ffff			;Rechteck-Job ausführen.
			lda	r11L
			inc	r11L
			cmp	r2H			;Letzte Zeile erreicht ?
			bne	:51			;Nein, weiter...
			rts

;*** Inline: Rechteck herstellen.
;    b yLow,yHigh
;    w xLow,xHigh
:xi_RecoverRec		jsr	GetInlineData		;Inline-Daten einlesen.
			jsr	xRecoverRec		;Rechteck kopieren.
			jmp	Exit7ByteInline		;Routine beenden.

;*** Inline: Rechteck speichern.
;    b yLow,yHigh
;    w xLow,xHigh
:xi_ImprintRec		jsr	GetInlineData		;Inline-Daten einlesen.
			jsr	xImprintRec		;Rechteck kopieren.
			jmp	Exit7ByteInline		;Routine beenden.

;*** Inline: Rechteck herstellen.
;    b yLow,yHigh
;    w xLow,xHigh
:xi_FrameRec		jsr	GetInlineData		;Inline-Daten einlesen.
			iny
			lda	(returnAddress),y	;Linienmuster einlesen.
			jsr	xFrameRectangle		;Rahmen zeichnen.
			php
			lda	#$08
			jmp	DoInlineReturn		;Inline-Routine beenden.

;*** GraphicsString: FRAME_RECTO
:GS_FRAMERECTO		jsr	GS_GetXYpar
			lda	#$ff

;*** Inline: Rechteck herstellen.
;    r2L/r2H = yLow/yHigh
;    r3 /r4  = xLow/xHigh
:xFrameRectangle	sta	r9H			;Linienmuster merken.

			ldy	r2L			;Oberen Rand zeichnen.
			sty	r11L
			jsr	xHorizontalLine

			lda	r2H			;Unteren Rand zeichnen.
			sta	r11L
			lda	r9H
			jsr	xHorizontalLine

			lda	r3H			;X-Koordinaten merken.
			pha
			lda	r3L
			pha
			lda	r4H
			pha
			lda	r4L
			pha

			lda	r3H			;X-Koordinate auf Linken Rand
			sta	r4H			;setzen.
			lda	r3L
			sta	r4L
			lda	r2H
			sta	r3H
			lda	r2L
			sta	r3L
			lda	r9H			;Linken Rand zeichnen.
			jsr	xVerticalLine
			pla				;X-Koordinate für rechten
			sta	r4L			;Rand wiederherstellen.
			pla
			sta	r4H
			lda	r9H			;Linken Rand zeichnen.
			jsr	xVerticalLine
			pla				;X-Koordinate für rechten
			sta	r3L			;Rand wiederherstellen.
			pla
			sta	r3H
			rts

;*** Inline-Grafikdaten einlesen.
;    Aufruf über JSR...
:GetInlineData		pla				;Rücksprungadresse vom
			sta	r5L			;Stapel holen.
			pla
			sta	r5H
			pla				;Startadresse der Inline-Daten
			sta	returnAddress+0		;einlesen und speichern.
			pla
			sta	returnAddress+1

			ldy	#$00
::51			iny
			lda	(returnAddress)   ,y	;Grafik-Koordinaten einlesen.
			sta	r2              -1,y
			cpy	#$06
			bne	:51

			lda	r5H			;Rücksprungadresse auf Stapel
			pha				;zurückschreiben.
			lda	r5L
			pha
:GraphStrgExit		rts				;Rücksprung.

;*** Inline: Grafikbefehle ausführen.
:xi_GraphicsStrg	pla				;Zeiger auf Inline-Daten
			sta	r0L			;für ":GraphicsString".
			pla
			inc	r0L
			bne	:51
			clc
			adc	#$01
::51			sta	r0H
			jsr	xGraphicsString		;Grafikbefehle ausführen.
			jmp	(r0)			;Zum Programm zurück.

;*** Inline: Grafikbefehle ausführen.
;    r0 = Zeiger auf Tabelle.
:xGraphicsString	jsr	Get1Byte		;Befehlcode einlesen.
			beq	GraphStrgExit		;NULL ? Ja, Ende...
			tay
			dey
			lda	GS_RoutTabL,y		;Zeiger auf Routine einlesen
			ldx	GS_RoutTabH,y		;und ausführen.
			jsr	CallRoutine
			jmp	xGraphicsString		;Nächsten Befehl ausführen.

;*** Einsprungadressen für
;    GraphicsString-Befehle.
:GS_RoutTabL		b < GS_MOVEPENTO
			b < GS_LINETO
			b < GS_RECTANGLETO
			b < GS_PENFILL
			b < GS_NEWPATTERN
			b < GS_PUTSTRING
			b < GS_FRAMERECTO
			b < GS_PENXDELTA
			b < GS_PENYDELTA
			b < GS_PENXYDELTA

:GS_RoutTabH		b > GS_MOVEPENTO
			b > GS_LINETO
			b > GS_RECTANGLETO
			b > GS_PENFILL
			b > GS_NEWPATTERN
			b > GS_PUTSTRING
			b > GS_FRAMERECTO
			b > GS_PENXDELTA
			b > GS_PENYDELTA
			b > GS_PENXYDELTA

;*** GraphicsString: MOVEPENTO
:GS_MOVEPENTO		jsr	Get3Bytes
			sta	GS_Ypos
			stx	GS_XposL
			sty	GS_XposH

;*** GraphicsString: PENFILL
:GS_PENFILL		rts

;*** GraphicsString: LINETO
:GS_LINETO		lda	GS_XposH
			sta	r3H
			lda	GS_XposL
			sta	r3L
			lda	GS_Ypos
			sta	r11L
			jsr	GS_MOVEPENTO
			sta	r11H
			stx	r4L
			sty	r4H
			sec
			lda	#$00
			jmp	xDrawLine

;*** GraphicsString: ESC_PUTSTRING
:GS_PUTSTRING		jsr	Get1Byte
			sta	r11L
			jsr	Get1Byte
			sta	r11H
			jsr	Get1Byte
			sta	r1H
			jmp	xPutString

;*** GraphicsString: PENXYDELTA
:GS_PENXYDELTA		ldx	#$01
			bne	GS_SetXDelta

;*** GraphicsString: PENXDELTA
:GS_PENXDELTA		ldx	#$00
:GS_SetXDelta		ldy	#$00
			lda	(r0L),y
			iny
			clc
			adc	GS_XposL
			sta	GS_XposL
			lda	(r0L),y
			iny
			adc	GS_XposH
			sta	GS_XposH
			txa
			beq	GS_ExitPenDelta
			bne	GS_SetYDelta

;*** GraphicsString: PENYDELTA
:GS_PENYDELTA		ldy	#$00
:GS_SetYDelta		lda	(r0L),y
			iny
			clc
			adc	GS_Ypos
			sta	GS_Ypos
			iny
:GS_ExitPenDelta	tya
			jmp	Add_A_r0

;*** GraphicsString:
;    Parameter einlesen (Word,Byte)
:GS_GetXYpar		jsr	Get3Bytes
			cmp	GS_Ypos
			bcs	:51
			sta	r2L
			pha
			lda	GS_Ypos
			sta	r2H
			jmp	:52

::51			sta	r2H
			pha
			lda	GS_Ypos
			sta	r2L

::52			pla
			sta	GS_Ypos
			cpy	GS_XposH
			beq	:53
			bcs	:55
::53			bcc	:54
			cpx	GS_XposL
			bcs	:55

::54			stx	r3L
			sty	r3H
			lda	GS_XposH
			sta	r4H
			lda	GS_XposL
			sta	r4L
			jmp	:56

::55			stx	r4L
			sty	r4H
			lda	GS_XposH
			sta	r3H
			lda	GS_XposL
			sta	r3L
::56			stx	GS_XposL
			sty	GS_XposH
			rts

;*** GraphicsString: NEWPATTERN
:GS_NEWPATTERN		jsr	Get1Byte

;*** Neues Füllmuster setzen.
:xSetPattern		asl
			asl
			asl
			adc	#<GEOS_Patterns
			sta	curPattern     +0
			lda	#$00
			adc	#>GEOS_Patterns
			sta	curPattern     +1
			rts
