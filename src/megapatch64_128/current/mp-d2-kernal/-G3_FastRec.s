; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Neue FastRectangle-Routine.
:TestFastRec
if Flag64_128 = TRUE_C128
			bit	graphMode		;Garfikmodus?
			bpl	Rectangle40		;>40 Zeichen

			PushW	r3			;r3 sichern
			PushW	r4			;r4 sichern
			MoveB	r2L,r11L		;Y-Anfang nach r11L
			PushB	dispBufferOn		;Modus sichern und auf Vorder- und
			LoadB	dispBufferOn,$80 ! $40	;Hintergrund setzen wegen r5, sonst
			jsr	SetScrAdr		;wird bei 'nur' Hintergrund r5 = r6
							;und die Berechnung von r5 und r6
							;funktioniert nach DrawVDCLineFast
							;nicht mehr!
			PopB	dispBufferOn		;r5 und r6 als Front- und Back-
			lda	r8L			;Screen-Adresse setzen
			ora	r8H			;nur Cards?
			beq	StartFastRec80		;>ja dann neue Rectangle-Routine
			PopW	r4			;>nein dann alte Rectangle-Routine
			PopW	r3
			rts

:StartFastRec80		jsr	SetLineLen		;Länge der Linie nach r4L
			inc	r4L			;+1
::1			lda	r11L
			and	#$07
			tay				;Linienmuster für aktuelle
			lda	aktPattern,y		;Zeile einlesen.
			bit	dispBufferOn		;in welchen Bildschirm?
			bvc	:2			;>kein Hintergrund
			ldy	r4L			;Weite ins Y-Register
::3			dey
			sta	(r6L),y			;Muster setzen
			bne	:3			;>Schleife
::2			jsr	DrawVDCLineFast		;Linie in VDC zeichnen
			lda	r5L			;r5 auf nächste Zeile setzen
			clc
			adc	#80			;r5 = r5 + 80
			sta	r5L
			bcc	:4
			inc	r5H
::4			jsr	SetBackScrPtr		;r6 für Hintergrund setzen
::5			lda	r11L			;Y-Position laden
			inc	r11L			;und erhöhen
			cmp	r2H			;Ende?
			bne	:1			;>nein
			PopW	r4
			PopW	r3
			pla				;Stack bereinigen
			pla
			rts
:Rectangle40
endif
			lda	r2L			;X/Y-Koordinaten auf 8x8
			and	#%00000111		;Raster testen. Falls keine
			bne	:51			;Übereinstimmung muß Standard-
							;Rectangle ausgeführt werden.
			lda	r2H
			and	#%00000111
			cmp	#$07
			bne	:51

			lda	r3L
			and	#%00000111
			bne	:51

			lda	r4L
			and	#%00000111
			cmp	#$07
			beq	StartFastRec
::51			rts

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
if Flag64_128 = TRUE_C128
			jsr	xGetScanLine		;Routine liegt in Bank 0!
else
			jsr	GetScanLine
endif
::51			dec	r7L			;Erstes CARD für Rechteck
			bmi	:52			;berechnen.
			jsr	Add8_r5r6
			jmp	:51

::52			lda	r5L			;Startadresse Grafikzeile
			pha				;zwischenspeichern.
			lda	r5H			;r5L=r6L !!!
			pha
			lda	r6H
			pha

			ldx	r7H
			inx
::53			ldy	#7

if Flag64_128 = TRUE_C128
::54			lda	aktPattern,y		;Aktuelles Muster einlesen.
else
::54			lda	(curPattern),y		;Aktuelles Muster einlesen.
endif
			bit	dispBufferOn		;Vordergrundgrafik ?
			bpl	:55			;Nein, weiter...
			sta	(r5),y

::55			bit	dispBufferOn		;Hintergrundgrafik ?
			bvc	:56			;Nein, weiter...
			sta	(r6),y

::56			dey
			bpl	:54

			jsr	Add8_r5r6		;Zeiger auf nächstes CARD.

			dex				;Zeile ausgegeben ?
			bne	:53			;Nein, weiter...

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
			jmp	:52

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
