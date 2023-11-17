; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion     : Auswahltabelle
; Datum        : 15.08.20 / Änderung auf 16Bit-Werte.
; Aufruf       : JSR  InitScrBar16
; Übergabe     : r0 = Zeiger auf Datentabelle.
;                b    Zeiger auf xPos (in CARDS!)
;                b    Zeiger auf yPos (in PIXEL!)
;                b    max. Länge des Balken (in PIXEL!)
;                b    max. Einträge auf einer Seite.
;                w    max. Anzahl Einträge in Tabelle.
;                w    Tabellenzeiger = Nr. der ersten Datei auf der Seite!
;
;'InitScrBar16'  Muß als erstes aufgerufen werden um die Daten (r0-r2) für
;                den Anzeigebalken zu definieren und den Balken auf dem
;                Bildschirm auszugeben.
;'SetNewPos16'   Setzt den Füllbalken auf neue Position. Dazu muß im AKKU die
;                neue Position des Tabellenzeigers übergeben werden.
;'PrntScrBar16'   Zeichnet den Anzeige- und Füllbalken erneut. Dazu muß aber
;                vorher mindestens 1x 'InitBalken' aufgerufen worden sein!
;'ReadSB_Data'   Übergibt folgende Werte an die aufrufende Routine:
;                r0L = SB_XPos        Byte  X-Position Balken in CARDS.
;                r0H = SB_YPos        Byte  Y-Position in Pixel.
;                r1L = SB_MaxYlen     Byte  Länge des Balkens.
;                r1H = SB_MaxEScr     Byte  Anzahl Einträge auf Seite.
;                r2  = SB_MaxEntry16  Word  Anzahl Einträge in Tabelle.
;                r3  = SB_PosEntry16  Word  Aktuelle Position in Tabelle.
;                r4  = SB_PosTop      Word  Startadresse im Grafikspeicher.
;                r5L = SB_Top         Byte  Oberkante Füllbalken.
;                r5H = SB_End         Byte  Unterkante Füllbalken.
;                r6L = SB_Length      Byte  Länge Füllbalken.
;'IsMseOnPos'    Mausklick auf Anzeigebalken auswerten. Ergebnis im AKKU:
;                $01 = Mausklick Oberhalb Füllbalken.
;                $02 = Mausklick auf Füllbalken.
;                $03 = Mausklick Unterhalb Füllbalken.
;'StopMouseMove' Schränkt Mausbewegung ein.
;'SetRelMouse'   Setzt neue Mausposition. Wird beim Verschieben des
;                Füllbalkens benötigt. Vorher muß ein 'JSR SetNewPos16'
;                erfolgen!
;******************************************************************************

;*** Balken initialiseren.
:InitScrBar16		ldy	#8 -1			;Parameter speichern.
::1			lda	(r0L),y
			sta	SB_XPos,y
			dey
			bpl	:1

			jsr	Anzeige_Ypos		;Position Anzeigebalkens berechnen.
			jsr	Balken_Ymax		;Länge des Füllbalkens anzeigen.

			lda	SB_XPos
			sta	:colData +0

			lda	SB_YPos			;Position für "UP"-Icon berechnen.
			lsr
			lsr
			lsr
			sta	:colData +1

			lda	SB_MaxYlen
			lsr
			lsr
			lsr
			sta	:colData +3

			lda	#$01
			jsr	i_UserColor
::colData		b	$00,$00,$01,$00

			jmp	PrntScrBar16		;Balken ausgeben.

;*** Neue Balkenposition defnieren und anzeigen.
:SetNewPos16		sta	SB_PosEntry16 +0	;Neue Position Füllbalken setzen.
			sty	SB_PosEntry16 +1

;*** Balken ausgeben.
:PrntScrBar16		jsr	Balken_Ypos		;Y-Position Füllbalken berechnen.

			MoveW	SB_PosTop,r0		;Grafikposition berechnen.
			ClrB	r1L			;Zähler für Balkenlänge löschen.

			lda	SB_YPos			;Zeiger innerhalb Grafik-CARD be-
			and	#%00000111		;rechnen (Wert von $00-$07).
			tay

::1			lda	SB_Length		;Balkenlänge = $00 ?
			beq	:4			;Ja, kein Füllbalken anzeigen.

			ldx	r1L
			cpx	SB_Top			;Anfang Füllbalken erreicht ?
			beq	:3			;Ja, Quer-Linie ausgeben.
			bcc	:4			;Kleiner, dann Hintergrund ausgeben.
			cpx	SB_End			;Ende Füllbalken erreicht ?
			beq	:3			;Ja, Quer-Linie ausgeben.
			bcs	:4			;Größer, dann Hintergrund ausgeben.
			inx
			cpx	SB_MaxYlen		;Ende Anzeigebalken erreicht ?
			beq	:4			;Ja, Quer-Linie ausgeben.

::2			lda	#%10000000		;Wert für Füllbalken.
			b $2c
::3			lda	#%11111111
			b $2c
::4			lda	#%11111111
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
:Anzeige_Ypos		MoveB	SB_XPos,r0L		;Zeiger auf X_CARD berechnen.
			LoadB	r0H,NULL
			ldx	#r0L
			ldy	#$03
			jsr	DShiftLeft
			AddVW	SCREEN_BASE,r0		;Zeiger auf Grafikspeicher.

			lda	SB_YPos			;Zeiger auf Y-Position
			lsr				;berechnen.
			lsr
			lsr
			tay
			beq	:2
::1			AddVW	40*8,r0
			dey
			bne	:1
::2			MoveW	r0,SB_PosTop		;Grafikspeicher-Adresse merken.
			rts

;*** Länge des Balken berechnen.
:Balken_Ymax		lda	#$00
			ldx	SB_MaxEntry16 +1	;Mehr als 255 Einträge?
			bne	:1			; => Ja, Balken immer möglich.
			ldx	SB_MaxEScr
			cpx	SB_MaxEntry16 +0	;Balken möglich?
			bcs	:2			; => Nein, weiter...

::1			MoveB	SB_MaxYlen,r0L		;Länge Balken berechnen.
			MoveB	SB_MaxEScr,r1L
			ldx	#r0L			;Multiplikation durchführen.
			ldy	#r1L
			jsr	BBMult

			MoveW	SB_MaxEntry16,r1
			ldx	#r0L
			ldy	#r1L
			jsr	Ddiv

			lda	r0L
			cmp	#8			;Balken kleiner 8 Pixel?
			bcs	:2			; => Nein, weiter...
			lda	#$08			;Mindestgröße für Balken.
::2			sta	SB_Length
			rts

;*** Position des Balken berechnen.
:Balken_Ypos		lda	SB_MaxEntry16 +1	;Mehr als 255 Einträge?
			bne	:1			; => Balken immer erforderlich.

			ldx	#NULL
			ldy	SB_Length

			lda	SB_MaxEScr
			cmp	SB_MaxEntry16 +0	;Balken möglich?
			bcs	:2			; => Nein, weiter...

::1			MoveW	SB_PosEntry16,r0

			lda	SB_MaxYlen
			sec
			sbc	SB_Length
			sta	r1L
			lda	#$00
			sta	r1H

			ldx	#r0L			;Multiplikation durchführen.
			ldy	#r1L
			jsr	BMult

			lda	SB_MaxEntry16 +0
			sec
			sbc	SB_MaxEScr
			sta	r1L
			lda	SB_MaxEntry16 +1
			sbc	#$00
			sta	r1H

			ldx	#r0L
			ldy	#r1L
			jsr	Ddiv

			lda	r0L
			tax
			clc
			adc	SB_Length
			tay
::3			cpy	SB_MaxYlen
			beq	:2
			bcc	:2
			dey
			dex
			bne	:3
::2			stx	SB_Top
			dey
			sty	SB_End
			rts

;*** Daten für Scrollbalken übergeben.
;Hinweis:
;Wurde von GeoDOS übernommen und wird
;wird in GeoDesk nicht verwendet.
;:ReadSB_Data		ldx	#13 -1
;::1			lda	SB_XPos,x
;			sta	r0L,x
;			dex
;			bpl	:1
;			rts

;*** Mausklick überprüfen.
:IsMseOnPos		lda	mouseYPos
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
:StopMouseMove		lda	mouseXPos +0
			sta	mouseLeft +0
			sta	mouseRight+0
			lda	mouseXPos +1
			sta	mouseLeft +1
			sta	mouseRight+1
			lda	mouseYPos
			jmp	SetNewRelMse

:SetRelMouse		lda	#$ff
			clc
			adc	SB_Top
:SetNewRelMse		sta	mouseTop
			sta	mouseBottom
			sec
			sbc	SB_Top
			sta	SetRelMouse+1
			rts

;*** Variablen für Scrollbalken.
:SB_XPos		b $00				;r0L
:SB_YPos		b $00				;r0H
:SB_MaxYlen		b $00				;r1L
:SB_MaxEScr		b $00				;r1H
:SB_MaxEntry16		w $0000				;r2
:SB_PosEntry16		w $0000				;r3

:SB_PosTop		w $0000				;r4
:SB_Top			b $00				;r5L
:SB_End			b $00				;r5H
:SB_Length		b $00				;r6L
