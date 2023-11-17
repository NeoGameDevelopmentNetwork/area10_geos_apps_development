; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Zahl auf Bildschirm ausgeben.
:xPutDecimal		jsr	ConvDEZtoASCII		;Zahl nach ASCII wandeln.

			bit	r2L			;Zahl linksbündig ausgeben ?
			bmi	:52			;Ja, weiter...

			lda	r2L			;Breite des Ausgabefeldes in
			and	#%00111111		;Pixel ermitteln.
			sec
			sbc	r3H
			clc
			adc	r11L			;X-Position für Zahlenausgabe
			sta	r11L			;festlegen.
			bcc	:52
			inc	r11H

::52			ldx	r3L
			stx	r0L
::53			lda	SetStream-1,x		;ASCII-Zeichen der Zahl
			pha				;zwischenspeichern.
			dex
			bne	:53

::54			pla				;Zeichen einlesen und
			jsr	xPutChar		;ausgeben.
			dec	r0L			;Alle Zeichen aus ASCII-String
			bne	:54			;ausgegeben ? Nein, weiter...
			rts
