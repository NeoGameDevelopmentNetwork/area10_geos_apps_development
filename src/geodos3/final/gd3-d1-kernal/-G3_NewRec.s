; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Rechteck zeichen.
;    r2L/r2H = yLow/yHigh
;    r3 /r4  = xLow/xHigh
:xRectangle		jsr	TestFastRec		;Auf FastRectangle testen.
							;Rückkehr nur wenn FastRec
							;nicht möglich ist.

			lda	r2L			;Startzeile als Anfangswert
			sta	r11L			;für Rectangle setzen.
::1			lda	r11L
			and	#$07
			tay				;Linienmuster für aktuelle
			lda	(curPattern),y		;Zeile einlesen.
			jsr	xHorizontalLine		;Horizontale Linie zeichnen.
			lda	r11L
			inc	r11L
			cmp	r2H			;Letzte Zeile erreicht ?
			bne	:1			;Nein, weiter...
			rts
