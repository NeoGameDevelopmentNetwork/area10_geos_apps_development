; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
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
;******************************************************************************

;*** Scrollbalken initialiseren.
:WM_SCRBAR_INIT
if MAXENTRY16BIT = FALSE
			ldy	#$05			;Parameter speichern.
endif
if MAXENTRY16BIT = TRUE
			ldy	#$08			;Parameter speichern.
endif
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
:WM_SCRBAR_SETPOS	sta	SB_PosEntry +0		;Neue Position Scrollbalken setzen.
if MAXENTRY16BIT = TRUE
			stx	SB_PosEntry +1
endif

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
:WM_SCRBAR_REDRAW	MoveW	SB_PosTop,r0		;Grafikposition berechnen.

			ClrB	r1L			;Zähler für Balkenlänge löschen.
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
			CmpB	r1L,SB_MaxYlen		;Gesamte Balkenlänge ausgegeben ?
			beq	:6			;Ja, Abbruch...

			iny
			cpy	#8			;8 Byte in einem CARD gespeichert ?
			bne	:1			;Nein, weiter...

			AddVW	SCRN_XBYTES,r0		;Zeiger auf nächstes CARD berechnen.
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
			MoveW	r0,SB_PosTop
			rts

;*** Länge des Balken berechnen.
:Balken_Ymax
if MAXENTRY16BIT = TRUE
			lda	SB_MaxEPage +1
			cmp	SB_MaxEntry +1
			bne	:2
endif
			lda	SB_MaxEPage +0
			cmp	SB_MaxEntry +0
::2			bcc	:0			;Balken möglich ?

			lda	#$00			;Nein, weiter...
			beq	:1

::0			MoveB	SB_MaxYlen,r0L		;Länge Balken berechnen.
if MAXENTRY16BIT = TRUE
			LoadB	r0H,NULL
endif
			MoveB	SB_MaxEPage +0,r1L
if MAXENTRY16BIT = TRUE
			MoveB	SB_MaxEPage +1,r1H
endif
			jsr	Mult_r0r1

			MoveB	SB_MaxEntry +0,r1L
if MAXENTRY16BIT = TRUE
			MoveB	SB_MaxEntry +1,r1H
endif
			jsr	Div_r0r1

			CmpBI	r0L,8			;Balken kleiner 8 Pixel ?
			bcs	:1			;Nein, weiter...
			lda	#$08			;Mindestgröße für Balken.
::1			sta	SB_Length
			rts

;*** Position des Balken berechnen.
:Balken_Ypos		ldx	#$00
			ldy	SB_Length
if MAXENTRY16BIT = TRUE
			lda	SB_MaxEPage +1
			cmp	SB_MaxEntry +1
			bne	:0
endif
			lda	SB_MaxEPage +0
			cmp	SB_MaxEntry +0
::0			bcs	:1

			MoveB	SB_PosEntry +0,r0L
if MAXENTRY16BIT = TRUE
			MoveB	SB_PosEntry +1,r0H
endif
			lda	SB_MaxYlen
			sec
			sbc	SB_Length
			sta	r1L
if MAXENTRY16BIT = TRUE
			LoadB	r1H,NULL
endif
			jsr	Mult_r0r1

			MoveB	SB_MaxEntry +0,r1L
if MAXENTRY16BIT = TRUE
			MoveB	SB_MaxEntry +1,r1H
endif
			lda	r1L
			sec
			sbc	SB_MaxEPage +0
			sta	r1L
if MAXENTRY16BIT = TRUE
			lda	r1H
			sbc	SB_MaxEPage +1
			sta	r1H
endif
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
if MAXENTRY16BIT = FALSE
			jmp	BBMult
endif
if MAXENTRY16BIT = TRUE
			jmp	DMult
endif
:Div_r0r1
if MAXENTRY16BIT = FALSE
			lda	#$00
			sta	r1H
endif
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
if MAXENTRY16BIT = FALSE
:SB_MaxEntry		b $00
:SB_PosEntry		b $00
:SB_MaxEPage		b $00
endif
if MAXENTRY16BIT = TRUE
:SB_MaxEntry		w $0000
:SB_PosEntry		w $0000
:SB_MaxEPage		w $0000
endif

;*** Grafikdaten für Scrollbalken.
:SB_PosTop		w $0000
:SB_Top			b $00
:SB_End			b $00
:SB_Length		b $00
