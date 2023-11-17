; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Farben für Grafikbildschirm setzen.
; Datum			: 02.07.97
; Aufruf		: JSR  i_UserColor
; Übergabe		: AKKU              Byte  Farbwert
;			  b xl,yl,xb,yb     Daten Koordinaten des Rechtecks
; Rückgabe		: Bildschirmausgabe
; Verändert		: AKKU,xReg,yReg
;			  r5,r6,r7
; Variablen		: -
; Routinen		: -
;******************************************************************************

;******************************************************************************
; Funktion		: Farben für Grafikbildschirm setzen.
; Datum			: 02.07.97
; Aufruf		: JSR  i_ColorBox
; Übergabe		: b xl,yl,xb,yb,f   Daten Koordinaten + Farbwert
; Rückgabe		: Bildschirmausgabe
; Verändert		: AKKU,xReg,yReg
;			  r5,r6,r7
; Variablen		: -
; Routinen		: -
;******************************************************************************

;******************************************************************************
; Funktion		: Farben für Grafikbildschirm setzen.
; Datum			: 02.07.97
; Aufruf		: JSR  DirectColor
; Übergabe		: AKKU              Byte  Farbwert
;			  r2L,r2H,r3,r4     Daten Koordinaten + Farbwert
; Rückgabe		: Bildschirmausgabe
; Verändert		: AKKU,xReg,yReg
;			  r5,r6,r7
; Variablen		: -
; Routinen		: -
;******************************************************************************

;******************************************************************************
; Funktion		: Farben für Grafikbildschirm setzen.
; Datum			: 02.07.97
; Aufruf		: JSR  RecColorBox
; Übergabe		: r5L,r5H,r6L,r6H   Daten								Koordinaten des Rechtecks
;			= (xl, yl, xb, yb)  wie bei i_ColorBox oder i_UserColor
;			  r7L               Byte      Farbwert
; Rückgabe		: Bildschirmausgabe
; Verändert		: AKKU,xReg,yReg
; Variablen		: -
; Routinen		: -
;******************************************************************************

;*** Farbe definieren.
:xi_UserColor		sta	r7L
			ldy	#$05			;Zeiger auf Inline-Daten ohne Farbe.
			b $2c
:xi_ColorBox		ldy	#$06			;Zeiger auf Inline-Daten mit  Farbe.
			pla
			sta	returnAddress +0
			pla
			sta	returnAddress +1

			sty	:2 +1			;Überlesende Bytes merken.
			dey				;Zeiger auf Datenbyte.
::1			lda	(returnAddress),y
			sta	r5 -1,y
			dey
			bne	:1

			jsr	RecColorBox		;Farbrechteck darstellen.
			php				;Zurück zur aufrufenden Routine.
::2			lda	#$ff
			jmp	DoInlineReturn

;*** Farbe über register r2 bis r4 zeichnen.
:xDirectColor		pha

			ldx	#$01
::1			lda	r2L,x
			lsr
			lsr
			lsr
			sta	r5L,x			;r5L = r2L/8
			dex				;r5H = r2H/8
			bpl	:1

			ldx	#$02
::2			lda	r3H,x
			sta	r6H,x
			lda	r3L,x
			ldy	#$02
::3			lsr	r6H,x
			ror
			dey
			bpl	:3
			sta	r6L,x			;r6L = r3/8
			dex				;r7L = r4/8
			dex
			bpl	:2

			ldx	r5H
			inx
			txa
			sec
			sbc	r5L
			sta	r6H			;r6H = Höhe Y
			lda	r5L
			sta	r5H			;r5H = Y-Anfang

			ldx	r7L
			inx
			txa
			sec
			sbc	r6L
			ldx	r6L
			stx	r5L			;r5L = r6L (X-Anfang)
			sta	r6L			;r6L = Breite X
			pla
			sta	r7L			;Farbe nach r7L

;*** Farbe zeichnen.
:xRecColorBox		lda	r5H			;Y-Anfang (in r5L ist X-Anfang)
			ldx	#>COLOR_MATRIX		;r5H auf COLOR_MATRIX-high setzen
			stx	r5H			;COLOR_MATRIX-low ist immer 0!
			tax				;Y-Anfang ins X-Register
::1			jsr	:10			;Zeiger auf erste Zeile (+ X-Anfang)
			bne	:1			;für Farbdaten berechnen.

::2			ldx	r6H			;Höhe des Rechtecks.
::3			ldy	r6L			;Breite des Rechtecks.
			dey
			lda	r7L			;Farbe einlesen und
::4			sta	(r5L),y			;in Farbspeicher kopieren.
			dey
			bpl	:4
			jsr	:11
			bne	:3
			rts

;*** Zeiger auf Datenzeile berechnen.
::10			beq	:13
::11			clc
			lda	r5L
			adc	#40
			sta	r5L
			bcc	:12
			inc	r5H
::12			dex
::13			rts
