; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Farbrechteck zeichnen.
;Übergabe: r0 = Zeiger auf Grafik-Koordinaten:
;               :tab b y0,y1 ;yoben/yunten (in Pixel)
;                    w x0,x1 ;xlinks/xrechts (in Pixel)
;Hinweis:
;x0/x1 darf max. Byte-Wert haben, da
;nur das Low-Byte verwendet wird.
;Wird von openDynMenu für das zeichnen
;der Menüs verwendet. Max. X-Koordinate
;für Menüs daher $00ff = 255!
.grfxScrColRec		ldy	#0			;Koordinaten
::1			lda	(r0L),y			;zwischenspeichern.
			sta	r2,y
			iny
			cpy	#6
			bne	:1

;--- Hinweis:
;Hier hätte man auch ":screencolors"
;verwenden können.
			lda	COLOR_MATRIX +39
			sta	r6L			;Bildschirmfarbe.

			ldx	#r2L
			jsr	div_zpageX_8
			ldx	#r2H
			jsr	div_zpageX_8
			ldx	#r3L
			jsr	div_zpageX_8
			ldx	#r4L
			jsr	div_zpageX_8

;*** Farbrechteck zeichnen.
;Übergabe: r2L = Erste Zeile (in Cards)
;          r2H = Letzte Zeile +1 (in Cards)
;          r3L = Erste Spalte (in Cards)
;          r4H = Letzte Spalte (in Cards)
;          r6L = Farbwert
:cardUsrColRec		lda	r4L			;Breite des
			sec				;Farbrechtecks.
			sbc	r3L
			sta	r4L			;Anzahl Cards.

			lda	r2H			;Höhe des
			sec				;Farbrechtecks.
			sbc	r2L
			sta	r2H			;Anzahl Zeilen.

			lda	r2L			;Offset berechnen.
			sta	r5L
			lda	#$00
			sta	r5H
			jsr	mult_r5_40

			clc				;Zeiger COLOR_MATRIX.
			lda	#< COLOR_MATRIX
			adc	r5L
			sta	r5L
			lda	#> COLOR_MATRIX
			adc	r5H
			sta	r5H

			lda	r3L			;Zeiger auf linke
			clc				;Grenze setzen.
			adc	r5L
			sta	r5L
			bcc	:1
			inc	r5H

::1			ldy	r4L
::2			lda	r6L			;Farbwert.
			sta	(r5L),y			;Zeile einfärben.
			dey
			bpl	:2

			clc				;Zeiger auf nächste
			lda	#40			;Zeile setzen.
			adc	r5L
			sta	r5L
			bcc	:3
			inc	r5H

::3			dec	r2H			;Ende erreicht?
			bpl	:1			; => Nein, weiter...

			rts

;*** Zeropage-Register durch 8 teilen.
;Übergabe: X = Zeiger auf Zeropage-Register.
:div_zpageX_8		lda	zpage,x
			lsr
			lsr
			lsr
			sta	zpage,x
			rts

;*** Register r5 mit 40 multiplizieren.
;Übergabe: r5L = Zeile in COLOR_MATRIX.
;Rückgabe: r5  = Offset ab COLOR_MATRIX.
:mult_r5_40		lda	r5L
			asl
			rol	r5H
			asl
			rol	r5H
			clc
			adc	r5L
			bcc	:1
			inc	r5H
::1			asl
			rol	r5H
			asl
			rol	r5H
			asl
			rol	r5H
			sta	r5L
			rts

;*** DeskPad-Farbe zeichnen.
:drawDeskPadCol		lda	DESKPADCOL
			clv
			bvc	drawUserPadCol

;*** DeskPad mit Bildschirmfarbe zeichnen.
.drawScrnPadCol		lda	screencolors

;*** Farbe für DeskPad setzen (nur GEOS V2).
;Übergabe: A = Farbwert.
:drawUserPadCol		jsr	isGEOS_V2		;GEOS V2?
			bcc	:exit			; => Keine Farbe.

			tay

			lda	r0L
			pha

			lda	#AREA_FULLPAD_Y0 / 8
			sta	r2L
			lda	#AREA_FULLPAD_Y1 / 8
			sta	r2H
			lda	#> AREA_FULLPAD_X0 / 8
			sta	r3H
			lda	#< AREA_FULLPAD_X0 / 8
			sta	r3L
			lda	#> AREA_FULLPAD_X1 / 8
			sta	r4H
			lda	#< AREA_FULLPAD_X1 / 8
			sta	r4L

			sty	r6L
			jsr	cardUsrColRec

			pla
			sta	r0L

::exit			rts
