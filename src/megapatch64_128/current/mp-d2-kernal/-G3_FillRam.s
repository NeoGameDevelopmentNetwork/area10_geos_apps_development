; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Speicherbereich löschen.
:xClearRam		lda	#$00			;Füllbyte $00.
			sta	r2L

;*** Speicherbereich mit Byte füllen.
:xFillRam		lda	r0H			;Mehr als 256 Byte füllen ?
			beq	:2			;Nein, weiter...

			lda	r2L
			ldy	#$00
::1			sta	(r1L),y			;256 Byte füllen.
			dey
			bne	:1
			inc	r1H
			dec	r0H
			bne	:1

::2			lda	r2L
			ldy	r0L
			beq	:4
			dey
::3			sta	(r1L),y			;Restbereich füllen.
			dey
			cpy	#$ff
			bne	:3
::4			rts
