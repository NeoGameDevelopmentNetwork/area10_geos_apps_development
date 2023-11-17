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
; Datum			: 02.07.97 geändert 20.10.98 W. Grimm
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
; Datum			: 02.07.97 geändert 20.10.98 W. Grimm
; Aufruf		: JSR  RecColorBox
; Übergabe		: r5L,r5H,r6L,r6H   Daten Koordinaten des Rechtecks
;			= (xl, yl, xb, yb) wie bei i_ColorBox oder i_UserColor
;			  r7L               Byte  Farbwert
; Rückgabe		: Bildschirmausgabe
; Verändert		: AKKU,xReg,yReg
; Variablen		: -
; Routinen		: -
;******************************************************************************

if Flag64_128 = TRUE_C64
;*** Farbe definieren.
:xi_UserColor		sta	r7L
			ldy	#$05			;Zeiger auf Inline-Daten ohne Farbe.
			b $2c
:xi_ColorBox		ldy	#$06			;Zeiger auf Inline-Daten mit  Farbe.
			pla
			sta	returnAddress +0
			pla
			sta	returnAddress +1

			sty	:102 +1			;Überlesende Bytes merken.
			dey				;Zeiger auf Datenbyte.
::101			lda	(returnAddress),y
			sta	r5 -1,y
			dey
			bne	:101

			jsr	RecColorBox		;Farbrechteck darstellen.
			php				;Zurück zur aufrufenden Routine.
::102			lda	#$ff
			jmp	DoInlineReturn

;*** Farbe über register r2 bis r4 zeichnen.
:xDirectColor		pha

			ldx	#$01
::101			lda	r2L,x
			lsr
			lsr
			lsr
			sta	r5L,x			;r5L = r2L/8
			dex				;r5H = r2H/8
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
			sta	r6L,x			;r6L = r3/8
			dex				;r7L = r4/8
			dex
			bpl	:102

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
::101			jsr	:110			;Zeiger auf erste Zeile (+ X-Anfang) für
			bne	:101			;Farbdaten berechnen.

::102			ldx	r6H			;Höhe des Rechtecks.
::103			ldy	r6L			;Breite des Rechtecks.
			dey
			lda	r7L			;Farbe einlesen und
::104			sta	(r5L),y			;in Farbspeicher kopieren.
			dey
			bpl	:104
			jsr	:111
			bne	:103
			rts

;*** Zeiger auf Datenzeile berechnen.
::110			beq	:113
::111			clc
			lda	r5L
			adc	#40
			sta	r5L
			bcc	:112
			inc	r5H
::112			dex
::113			rts
endif

if Flag64_128 = TRUE_C128
;******************************************************************************
;128er Routinen in Bank 0!
;******************************************************************************
; Funktion		: Farbe für ein Pixel setzen oder holen (sec / clc)
; Datum			: 02.07.97
; Aufruf		: JSR	ColorPoint
; Übergabe		: r2L,r2H,r3,r4     Daten Koordinaten des Punktes
; Rückgabe		: Bildschirmausgabe
; Verändert		: AKKU,xReg,yReg
;			  r8
; Variablen		: -
; Routinen		: -
;******************************************************************************

:_ColorPoint		bcc	GetColorPoint
			ldx	graphMode
			bpl	:40
			sta	:Farbe+1
			jsr	SetScr80Adr
::Farbe			lda	#$00
			jsr	SetVDCScrByte
			jmp	LOADr2r6
::40			sta	:Farbe40+1
			jsr	SetScr40Adr
::Farbe40		lda	#$00
			ldy	#0
			sta	(r5),y
			jmp	LOADr2r6

:GetColorPoint		ldx	graphMode
			bpl	:40
			jsr	SetScr80Adr
			jsr	GetVDCScrByte
::1			tax
			jsr	LOADr2r6
			txa
			rts
::40			jsr	SetScr40Adr
			ldy	#0
			lda	(r5),y
			jmp	:1

;Farbwert in r7L
;r5L = X-Koordinate, r6L = Breite in Cards
;r5H = Y-Koordinate, r6H = Höhe in Cards
:_RecColorBox		jsr	SAVEr2r6
			lda	graphMode
			bpl	:40a
			bit	r5L
			bpl	:noDbl2
			asl	r5L
::noDbl2		bit	r6L
			bpl	:noDbl
			asl	r6L
::noDbl			ldy	vdcClrMode
			dey
			dey
			dey
			bmi	:80
::1			asl	r5H
			asl	r6H
			dey
			bpl	:1

::40a			lda	r5L
			and	#%01111111
			sta	r5L
			lda	r6L
			and	#%01111111
			sta	r6L

::80			MoveB	r5H,r2L
			inc	r2L
			jsr	SetScrAdresse
			ldy	r6L
			dey
			sty	r4L			;Breite
			MoveB	r6H,r2H			;Höhe
			lda	r7L
			ldx	graphMode
			bpl	:40
			sta	DoColBox80+1
			jmp	DoColBox80_2
::40			sta	DoColBox40+1
			jmp	DoColBox40

;Farbwert in Akku
;Y-Koordinaten r2L, r2H in Pixel
;X-Koordinaten r3, r4 in Pixel
:_DirectColor		ldx	graphMode		;welcher Modus?
			bmi	ColBox80		;>C128 80Zeichen
:ColBox40		sta	DoColBox40+1		;Farbwert speichern
			jsr	SetScr40Adr
:DoColBox40		lda	#0
			ldy	r4L
::3			sta	(r5),y
			dey
			bpl	:3
			AddVW	40,r5
			dec	r2H
			bne	DoColBox40
			jmp	LOADr2r6

:ColBox80		sta	DoColBox80+1
			jsr	SetScr80Adr
:DoColBox80_2		inc	r4L			;wegen DrawVDCLineFast
:DoColBox80		lda	#$00
			jsr	DrawVDCLineFast
			AddVW	80,r5			;nächste Zeile
			dec	r2H
			bne	DoColBox80

:LOADr2r6		ldy	#9
::1			lda	ZeroBuffer,y
			sta	r2,y
			dey
			bpl	:1
			rts

:SAVEr2r6		ldy	#9
::1			lda	r2,y
			sta	ZeroBuffer,y
			dey
			bpl	:1
			rts
:ZeroBuffer		s	10

:SetScrAdresse		PushB	r2L
			ldx	graphMode		;welcher Modus?
			bmi	_SetScr80Adr		;>C128 80Zeichen
			jmp	_SetScr40Adr		;>C128 40Zeichen

:SetScr40Adr		jsr	SAVEr2r6
			ldx	#r3L
			jsr	oNormalizeX
			ldx	#r4L
			jsr	oNormalizeX
			PushB	r2L
			jsr	SETr2L_r2H
:_SetScr40Adr		LoadB	r5H,$8c			;r5 = $8c00 + r5L
::2			dec	r2L
			beq	:1
			AddVW	40,r5
			jmp	:2
::1			PopB	r2L
			rts

:SetScr80Adr		jsr	SAVEr2r6
			ldx	#r3L
			jsr	oNormalizeX
			ldx	#r4L
			jsr	oNormalizeX
			PushB	r2L
			jsr	SETr2L_r2H

:_SetScr80Adr		;ldx	vdcClrMode		;welcher Farbmodus?
;			beq	:1			;>ohne Farbe
;			cpx	#2
;			bcs	:1
;			lda	#$38
;			b	$2c
::1			lda	#$40
			sta	r5H			;Highbyte von ATR-Adresse
::2			dec	r2L			;Y-Anfang
			beq	:3			;aufaddieren bis Anfangszeile
			AddVW	80,r5			;ereicht ist
			jmp	:2
::3			PopB	r2L
			rts

:SETr2L_r2H		sec
			lda	r2H			;Y-unten von Y-oben
			sbc	r2L			;abziehen - ergibt Höhe
			ldx	graphMode		;welcher Modus?
			bpl	:401			;>C128 40Zeichen
			ldx	vdcClrMode		;welcher VDC Farbmodus?
			cpx	#3
			beq	:3_			;8x4 Pixel
			cpx	#4
			beq	:4_			;8x2Pixel
::401			lsr				;geteilt durch 8 (8x8 Pixel)
::3_			lsr				;geteilt durch 4 (8x4 Pixel)
::4_			lsr				;geteilt durch 2 (8x2 Pixel)
			sta	r2H			;in r2H ist Höhe
			lda	r2L			;Y-oben
			ldx	graphMode		;welcher Modus?
			bpl	:40			;>C128 40Zeichen
			ldx	vdcClrMode		;welcher VDC Farbmodus?
			cpx	#3
			beq	:3			;8x4 Pixel
			cpx	#4
			beq	:4			;8x2Pixel
::40			lsr				;geteilt durch 8 (8x8 Pixel)
::3			lsr				;geteilt durch 4 (8x4 Pixel)
::4			lsr				;geteilt durch 2 (8x2 Pixel)
			sta	r2L			;in r2L ist Y-Anfang
			inc	r2L
			inc	r2H

:SETr5L_r4L		lda	r3L
			sta	r5L
			lda	r3H
			lsr				;r3 geteilt durch 8
			ror	r5L
			lsr
			ror	r5L
			lsr
			ror	r5L			;in r5L ist X-Anfang
			sec
			lda	r4L			;Weite berechnen
			sbc	r3L
			sta	r4L			;Weite in r4L
			lda	r4H
			sbc	r3H			;Weite high im Akku
			lsr				;geteilt druch 8
			ror	r4L
			lsr
			ror	r4L
			lsr
			ror	r4L			;Weite in r4L
			rts
endif
