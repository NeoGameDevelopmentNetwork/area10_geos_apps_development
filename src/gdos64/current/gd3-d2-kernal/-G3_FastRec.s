; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Neue FastRectangle-Routine.
:TestFastRec		lda	r2L			;X/Y-Koordinaten auf 8x8
			and	#%00000111		;Raster testen. Falls keine
			bne	:1			;Übereinstimmung muß Standard-
							;Rectangle ausgeführt werden.
			lda	r2H
			and	#%00000111
			cmp	#$07
			bne	:1

			lda	r3L
			and	#%00000111
			bne	:1

			lda	r4L
			and	#%00000111
			cmp	#$07
			beq	StartFastRec
::1			rts

;*** FastRectangle ausführen.
:StartFastRec		pla				;Rücksprung-Adresse löschen.
			pla
:xFastRectangle		lda	r2L			;Höhe des Rechtecks in CARDs
			sta 	r8L			;berechnen.
			sec
			lda	r2H
			sbc	r2L
			lsr
			lsr
			lsr
			sta	r8H
			inc	r8H

			lda	r3L			;Breite des Rechtecks in
			sta	r7L			;CARDs berechnen.
			lda	r3H
			lsr
			ror	r7L
			lsr
			ror	r7L
			lsr
			ror	r7L
			sec
			lda	r4L
			sbc	r3L
			sta	r7H
			lda	r4H
			sbc	r3H
			lsr
			ror	r7H
			lsr
			ror	r7H
			lsr
			ror	r7H

			ldx	r8L
			jsr	GetScanLine
::1			dec	r7L			;Erstes CARD für Rechteck
			bmi	:2			;berechnen.
			jsr	Add8_r5r6
			jmp	:1

::2			lda	r5L			;Startadresse Grafikzeile
			pha				;zwischenspeichern.
			lda	r5H			;r5L=r6L !!!
			pha
			lda	r6H
			pha

			ldx	r7H
			inx
::3			ldy	#7
::4			lda	(curPattern),y		;Aktuelles Muster einlesen.
			bit	dispBufferOn		;Vordergrundgrafik ?
			bpl	:5			;Nein, weiter...
			sta	(r5),y

::5			bit	dispBufferOn		;Hintergrundgrafik ?
			bvc	:6			;Nein, weiter...
			sta	(r6),y

::6			dey
			bpl	:4

			jsr	Add8_r5r6		;Zeiger auf nächstes CARD.

			dex				;Zeile ausgegeben ?
			bne	:3			;Nein, weiter...

			pla				;Startadresse Grafikzeile
			sta	r6H			;wieder zurücksetzen und
			pla				;Zeiger auf nächste Zeile
			sta	r5H			;berechnen.
			pla
			dec	r8H			;Rectangle gezeichnet ?
			beq	EndFastRec		;Ja, Ende...

			clc
			adc	#<320
			sta	r5L
			sta	r6L
			php
			lda	r5H
			adc	#>320
			sta	r5H
			plp
			lda	r6H
			adc	#>320
			sta	r6H
			jmp	:2

;*** 8 Byte zu Register ":r5" und ":r6" addieren.
:Add8_r5r6		clc
			lda	r5L
			adc	#$08
			sta	r5L
			sta	r6L
			bcc	EndFastRec
			inc	r5H
			inc	r6H
:EndFastRec		rts
