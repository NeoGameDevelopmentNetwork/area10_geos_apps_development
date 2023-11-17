; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Icon-Menü erzeugen.
:xDoIcons		lda	r0H			;Zeiger auf Icon-Tabelle
			sta	DI_VecDefTab+1		;zwischenspeichern.
			lda	r0L
			sta	DI_VecDefTab+0

			jsr	DI_DrawIcons		;Icons auf Bildschirm ausgeben.
			jsr	SetMseFullWin		;Mausbewegungsgrenzen löschen.

			lda	mouseOn			;Icons aktivieren.
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
::1			sta	r10L			;Zeiger auf Eintrag in
			jsr	DI_SetToEntry		;Definitionstabelle berechnen.

			ldx	#$00			;Icon-Daten nach ":r0"
::2			lda	(DI_VecDefTab),y	;kopieren -> Vorgabewerte für
			sta	r0L,x			;":BitmapUp".
			iny
			inx
			cpx	#$06
			bne	:2

			lda	r0L
			ora	r0H			;Icon verfügbar ?
			beq	:3			;Nein, übergehen...
			jsr	xBitmapUp		;Icon ausgeben.

::3			ldx	r10L			;Zeiger auf nächsten Eintrag.
			inx
			txa
			ldy	#$00
			cmp	(DI_VecDefTab),y	;Alle Icons bearbeitet ?
			bne	:1			;Nein, weiter...
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
			jmp	Ddec

;*** Mausklick auswerten.
:DI_ChkMseClk		lda	DI_VecDefTab+1		;Icon-Tabelle definiert ?
			beq	:1			;Nein, Ende...
			jsr	DI_GetSlctIcon		;Mausklick auswerten.
			bcs	:2			;Icon gewählt ? Ja, weiter...
::1			lda	otherPressVec+0		;Mausklick weiter auswerten.
			ldx	otherPressVec+1
			jmp	CallRoutine

::2			lda	DI_VecToEntry
			bne	:7
			lda	r0L
			sta	DI_SelectedIcon
			sty	DI_VecToEntry
			lda	#%11000000
			bit	iconSelFlag		;Icon invertieren ?
			beq	:5			;Nein, weiter...
			bmi	:3			; -> Blinkendes Icon.
			bvs	:4			; -> Icon invertieren.

::3			jsr	DI_GetIconSize		;Icon-Grenzen berechnen.
			jsr	InvertMenuArea		;Icon invertieren.
			jsr	DoMenuSleep
			lda	DI_SelectedIcon
			sta	r0L
			ldy	DI_VecToEntry
::4			jsr	DI_GetIconSize
			jsr	InvertMenuArea

::5			ldy	#$1e			;Zähler für Doppelklick
			ldx	#$00			;initialisieren.
			lda	dblClickCount		;Doppelklickauswertung bereits
			beq	:6			;aktiviert ? Nein, weiter...
			dex				;Flag: "Icon-Doppelklick".
			ldy	#$00
::6			sty	dblClickCount		;Zähler Doppelklick setzen.
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
			jmp	CallRoutine
::7			rts

;*** Gewähltes Icon ermitteln.
:DI_GetSlctIcon		lda	#$00			;Zähler auf ersten
			sta	r0L			;Icon-Eintrag richten.
::1			jsr	DI_SetToEntry		;Zeiger auf Icon-Eintrag
							;berechnen.
			lda	(DI_VecDefTab),y	;Icon definiert ?
			iny				;Ja, wenn Zeiger auf Icon-
			ora	(DI_VecDefTab),y	;Grafik > $0000.
			beq	:2			;Nein, Eintrag übergehen.
			iny
			lda	mouseXPos+1		;Maus X-Position in CARDs
			lsr				;umrechnen.
			lda	mouseXPos+0
			ror
			lsr
			lsr
			sec				;Mauszeiger rechts von
			sbc	(DI_VecDefTab),y	;X-Position des Icons ?
			bcc	:2			;Nein, nächster Eintrag...
			iny
			iny				;Mauszeiger innerhalb
			cmp	(DI_VecDefTab),y	;des Icons ?
			bcs	:2			;Nein, nächster Eintrag...
			dey
			lda	mouseYPos
			sec				;Mauszeiger unterhalb von
			sbc	(DI_VecDefTab),y	;Y-Position des Icons ?
			bcc	:2			;Nein, nächster Eintrag...
			iny
			iny				;Mauszeiger innerhalb
			cmp	(DI_VecDefTab),y	;des Icons ?
			bcc	:3			;Ja, gewähltes Icon gefunden.
::2			inc	r0L
			lda	r0L			;Zeiger auf nächsten Eintrag.
			ldy	#$00
			cmp	(DI_VecDefTab),y	;Ende Icon-Tabelle erreicht ?
			bne	:1			;Nein, weiter...
			clc				;Flag: "Kein Icon angeklickt".
			rts
::3			sec				;Flag: "Icon angeklickt".
			rts
