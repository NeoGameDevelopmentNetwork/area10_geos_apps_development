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
; Übergabe		: AKKU	Byte Farbwert
;			  b xl,yl,xb,ybDaten Koordinaten des Rechtecks
; Rückgabe		: Bildschirmausgabe
; Verändert		: AKKU,xReg,yReg
;			  r5,r6,r7L,r8
; Variablen		: -
; Routinen		: -
;******************************************************************************

;******************************************************************************
; Funktion		: Farben für Grafikbildschirm setzen.
; Datum			: 02.07.97
; Aufruf		: JSR  i_ColorBox
; Übergabe		: b xl,yl,xb,yb,f									Daten Koordinaten + Farbwert
; Rückgabe		: Bildschirmausgabe
; Verändert		: AKKU,xReg,yReg
;			  r5,r6,r7L,r8
; Variablen		: -
; Routinen		: -
;******************************************************************************

;******************************************************************************
; Funktion		: Farben für Grafikbildschirm setzen.
; Datum			: 02.07.97
; Aufruf		: JSR  DirectColor
; Übergabe		: AKKU	Byte Farbwert
;			  r2L,r2H,r3,r4Daten Koordinaten + Farbwert
; Rückgabe		: Bildschirmausgabe
; Verändert		: AKKU,xReg,yReg
;			  r5,r6,r7L,r8
; Variablen		: -
; Routinen		: -
;******************************************************************************

;******************************************************************************
; Funktion		: Farben für Grafikbildschirm setzen.
; Datum			: 02.07.97
; Aufruf		: JSR  RecColorBox
; Übergabe		: r5L,r5H,r6L,r6H									Daten Koordinaten des Rechtecks
;			  r7L	Byte Farbwert
; Rückgabe		: Bildschirmausgabe
; Verändert		: AKKU,xReg,yReg
;			  r8
; Variablen		: -
; Routinen		: -
;******************************************************************************

;*** Farbe definieren.
.i_UserColor		sta	r7L
			ldy	#$05			;Zeiger auf Inline-Daten ohne Farbe.
			b $2c
.i_ColorBox		ldy	#$06			;Zeiger auf Inline-Daten mit  Farbe.
			pla
			sta	returnAddress+0
			pla
			sta	returnAddress+1

			sty	:102 +1			;Anzahl zu überlesender Bytes merken.
			dey				;Zeiger auf Datenbyte.
::101			lda	(returnAddress),y
			sta	r5 -1,y
			dey
			bne	:101

			jsr	RecColorBox		;Farbrechteck darstellen.

			php				;Zurück zur aufrufenden Routine.
::102			lda	#$ff
			jmp	DoInlineReturn

.DirectColor		pha

			ldx	#$01
::101			lda	r2L,x
			lsr
			lsr
			lsr
			sta	r5L,x
			dex
			bpl	:101

			ldx	#$02
::102			lda	r3H,x
			sta	r6H,x
			lda	r3L,x
			ldy	#$02
::103			lsr	r6H,x
			ror
			dey
			bpl	:103
			sta	r6L,x
			dex
			dex
			bpl	:102

			ldx	r5H
			inx
			txa
			sec
			sbc	r5L
			sta	r6H
			lda	r5L
			sta	r5H

			ldx	r7L
			inx
			txa
			sec
			sbc	r6L
			ldx	r6L
			stx	r5L
			sta	r6L

			pla
			sta	r7L

.RecColorBox		LoadW	r8,COLOR_MATRIX

			ldx	r5H
::101			jsr	:110			;Zeiger auf Datenzeile berechnen.
			bne	:101

			lda	r5L
			clc
			adc	r8L
			sta	r8L
			bcc	:102
			inc	r8H

::102			ldx	r6H			;Höhe des Rechtecks.
::103			ldy	r6L			;Breite des Rechtecks.
			dey
			lda	r7L			;Farbe einlesen und
::104			sta	(r8L),y			;in Farbspeicher kopieren.
			dey
			bpl	:104
			jsr	:111
			bne	:103
			rts

;*** Zeiger auf Datenzeile berechnen.
::110			beq	:113
::111			clc
			lda	r8L
			adc	#40
			sta	r8L
			bcc	:112
			inc	r8H
::112			dex
::113			rts
