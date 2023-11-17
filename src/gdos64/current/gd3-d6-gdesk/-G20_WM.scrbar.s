; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; Funktion        :  Scrollbalken, aus GeoDOS importiert.
; Datum           :  24.06.2019
; Aufruf          :  JSR  WM_SCRBAR_INIT
; Übergabe        :  r0 = Zeiger auf Datentabelle.
;                    b    Zeiger auf xPos (in CARDS!)
;                    b    Zeiger auf yPos (in PIXEL!)
;                    b    max. Länge des Balken (in PIXEL!)
;                    b/w  max. Anzahl Einträge in Tabelle.
;                    b/w  max. Einträge auf einer Seite.
;                    b/w  Tabellenzeiger = Nr. der ersten Datei auf der Seite!
;
;'WM_SCRBAR_INIT'    Muß als erstes aufgerufen werden um die Daten für
;                    den Anzeigebalken zu definieren und den Balken auf dem
;                    Bildschirm auszugeben.
;'WM_SCRBAR_SETPOS'  Setzt Scrollbalken auf neue Position.
;                    Dazu muß im AKKU die neue Position des Tabellenzeigers
;                    übergeben werden.
;'WM_SCRBAR_DRAW'    Zeichnet den Scrollbalken. Dazu muß aber vorher
;                    mindestens 1x 'WM_SCRBAR_INIT' aufgerufen werden!
;'WM_SCRBAR_REDRAW'  Zeichnet den Scrollbalken erneut.
;'WM_SCRBAR_MSEPOS'  Mausklick auf Anzeigebalken auswerten. Ergebnis im AKKU:
;                    $01 = Mausklick Oberhalb Scrollbalken.
;                    $02 = Mausklick auf Scrollbalken.
;                    $03 = Mausklick Unterhalb Scrollbalken.
;'WM_SCRBAR_MSTOP'   Schränkt Mausbewegung ein.
;'WM_SCRBAR_SETMSE'  Setzt neue Mausposition. Wird beim Verschieben des Scroll-
;                    balkens benötigt. Vorher muß ein 'JSR WM_SCRBAR_SETPOS'
;                    erfolgen!
;

;*** Scrollbalken initialiseren.
:WM_SCRBAR_INIT		ldy	#$05			;Parameter speichern.
::1			lda	(r0L),y
			sta	SB_XPos,y
			dey
			bpl	:1

;--- Scrollbalken zeichnen.
			jsr	WM_DEF_AREA_BAR		;Bereich für Scrollbalken setzen.
			lda	C_WinScrBar
			jsr	DirectColor		;Farbe für Scrollbalken setzen.

			jsr	Anzeige_Ypos		;Position Anzeigebalken berechnen.
			jsr	Balken_Ymax		;Länge des Füllbalkens anzeigen.
			jmp	Balken_Ypos		;Y-Position Scrollbalken berechnen.

;*** Neue Balkenposition defnieren und anzeigen.
:WM_SCRBAR_SETPOS	sta	SB_PosEntry		;Neue Position Scrollbalken setzen.

;*** Scrollbalken ausgeben.
:WM_SCRBAR_DRAW		jsr	Balken_Ypos		;Y-Position Scrollbalken berechnen.
			lda	SB_MaxYlen
			sec
			sbc	SB_Top
			bcc	:1
			cmp	SB_Length
			bcs	WM_SCRBAR_REDRAW

::1			lda	SB_MaxYlen
			sec
			sbc	SB_Length
			sta	SB_Top

;*** Scrollbalken zeichnen.
:WM_SCRBAR_REDRAW	lda	SB_PosTop +0		;Grafikposition berechnen.
			sta	r0L
			lda	SB_PosTop +1
			sta	r0H

			lda	#$00			;Zähler für Balkenlänge löschen.
			sta	r1L
			lda	SB_YPos			;Zeiger innerhalb Grafik-CARD be-
			and	#%00000111		;rechnen (Wert von $00-$07).
			tay

::1			lda	#%01010101
			sta	r1H
			lda	r1L
			lsr
			bcc	:1a
			asl	r1H

::1a			lda	SB_Length		;Balkenlänge = $00 ?
			beq	:4			;Ja, kein Scrollbalken anzeigen.

			ldx	r1L
			cpx	SB_Top			;Anfang Scrollbalken erreicht ?
			beq	:3			;Ja, Quer-Linie ausgeben.
			bcc	:4			;Kleiner, dann Hintergrund ausgeben.
			cpx	SB_End			;Ende Scrollbalken erreicht ?
			beq	:3			;Ja, Quer-Linie ausgeben.
			bcs	:4			;Größer, dann Hintergrund ausgeben.
			inx
			cpx	SB_MaxYlen		;Ende Anzeigebalken erreicht ?
			beq	:3			;Ja, Quer-Linie ausgeben.

::2			lda	r1H
			and	#%10000001
			ora	#%01100110		;Wert für Scrollbalken.
			bne	:5

::3			lda	r1H
			ora	#%01111110
			bne	:5

::4			lda	r1H
::5			sta	(r0L),y			;Byte in Grafikspeicher schreiben.
			inc	r1L

			lda	r1L			;Gesamte Balkenlänge ausgegeben ?
			cmp	SB_MaxYlen
			beq	:6			;Ja, Abbruch...

			iny
			cpy	#8			;8 Byte in einem CARD gespeichert ?
			bne	:1			;Nein, weiter...

			lda	r0L			;Zeiger auf nächstes CARD berechnen.
			clc
			adc	#< SCRN_XBYTES
			sta	r0L
			lda	r0H
			adc	#> SCRN_XBYTES
			sta	r0H

			ldy	#$00
			beq	:1			;Schleife...
::6			rts				;Ende.

;*** Position des Anzeigebalken berechnen.
:Anzeige_Ypos		lda	SB_YPos			;Zeiger auf Y-Position
			lsr				;berechnen.
			lsr
			lsr
			tay
			ldx	SB_XPos
			jsr	setAdrScrBase

			lda	r0L
			sta	SB_PosTop +0
			lda	r0H
			sta	SB_PosTop +1
			rts

;*** Länge des Balken berechnen.
:Balken_Ymax		lda	SB_MaxEPage
			cmp	SB_MaxEntry
::2			bcc	:0			;Balken möglich ?

			lda	#$00			;Nein, weiter...
			beq	:1

::0			lda	SB_MaxYlen		;Länge Balken berechnen.
			sta	r0L
			lda	SB_MaxEPage
			sta	r1L
			jsr	Mult_r0r1

			lda	SB_MaxEntry
			sta	r1L
			jsr	Div_r0r1

			lda	r0L
			cmp	#8			;Balken kleiner 8 Pixel ?
			bcs	:1			;Nein, weiter...
			lda	#$08			;Mindestgröße für Balken.
::1			sta	SB_Length
			rts

;*** Position des Balken berechnen.
:Balken_Ypos		ldx	#$00
			ldy	SB_Length
			lda	SB_MaxEPage
			cmp	SB_MaxEntry
::0			bcs	:1

			lda	SB_PosEntry
			sta	r0L
			lda	SB_MaxYlen
			sec
			sbc	SB_Length
			sta	r1L
			jsr	Mult_r0r1

			lda	SB_MaxEntry
			sta	r1L
			lda	r1L
			sec
			sbc	SB_MaxEPage
			sta	r1L
			jsr	Div_r0r1

			lda	r0L
			tax
			clc
			adc	SB_Length
			tay
::1			stx	SB_Top
			dey
			sty	SB_End
			rts

:Mult_r0r1		ldx	#r0L			;Multiplikation durchführen.
			ldy	#r1L
			jmp	BBMult

:Div_r0r1		lda	#$00
			sta	r1H

			ldx	#r0L			;16Bit.
			ldy	#r1L			; 8Bit.
			jmp	Ddiv

;*** Mausklick überprüfen.
:WM_SCRBAR_MSEPOS	lda	mouseYPos
			sec
			sbc	SB_YPos
			cmp	SB_Top
			bcc	:3
::1			cmp	SB_End
			bcc	:2
			lda	#$03
			b $2c
::2			lda	#$02
			b $2c
::3			lda	#$01
			rts

;*** Mausbewegung kontrollieren.
:WM_SCRBAR_MSTOP	lda	mouseXPos +0
			sta	mouseLeft +0
			sta	mouseRight+0
			lda	mouseXPos +1
			sta	mouseLeft +1
			sta	mouseRight+1
			lda	mouseYPos
			jmp	SetNewRelMse

:WM_SCRBAR_SETMSE	lda	#$ff
			clc
			adc	SB_Top

:SetNewRelMse		sta	mouseTop
			sta	mouseBottom
			sec
			sbc	SB_Top
			sta	WM_SCRBAR_SETMSE+1
			rts

;*** Variablen.
:SB_XPos		b $00
:SB_YPos		b $00
:SB_MaxYlen		b $00
:SB_MaxEntry		b $00
:SB_PosEntry		b $00
:SB_MaxEPage		b $00

;*** Grafikdaten für Scrollbalken.
:SB_PosTop		w $0000
:SB_Top			b $00
:SB_End			b $00
:SB_Length		b $00
