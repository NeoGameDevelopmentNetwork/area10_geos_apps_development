; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Zahl in ASCII umwandeln.
:ConvDEZtoASCII		sta	r2L
			lda	#$04			;Zeiger auf 10000er.
			sta	r2H
			lda	#$00
			sta	r3L
			sta	r3H

::1			ldy	#$00
			ldx	r2H
::2			lda	r0L			;Wert 10^x von Dezimal-Zahl
			sec				;subtrahieren.
			sbc	DezDataL,x
			sta	r0L
			lda	r0H
			sbc	DezDataH,x
			bcc	:3			;Unterlauf ? Ja, weiter...
			sta	r0H
			iny
			jmp	:2

::3			lda	r0L			;Zahl auf letzten Wert
			adc	DezDataL,x		;zurücksetzen.
			sta	r0L
			tya				;Stelle in ASCII-Zahl > $00 ?
			bne	:4			;Ja, weiter...
			cpx	#$00			;Linker Rand erreicht ?
			beq	:4			;Ja, weiter...
			bit	r2L			;Führende Nullen ausgeben ?
			bvs	:5			;Nein, weiter...

::4			ora	#$30			;Zahl in Zwischenspeicher
			ldx	r3L			;übertragen.
			sta	SetStream,x

			ldx	currentMode		;Zeichenbreite des
			jsr	xGetRealSize		;aktuellen Zeichen berechnen.
			tya				;Zeichenbreite addieren.
			clc
			adc	r3H
			sta	r3H
			inc	r3L

			lda	#%10111111
			and	r2L
			sta	r2L
::5			dec	r2H			;Nächste Ziffer des
			bpl	:1			;ASCII-Strings berechnen.
			rts

;*** Tabelle für Umrechnung DEZ->ASCII.
:DezDataL		b < 1,< 10,< 100,< 1000,< 10000
:DezDataH		b > 1,> 10,> 100,> 1000,> 10000
