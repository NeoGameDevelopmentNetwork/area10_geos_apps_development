; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Freie Geräteadresse im Bereich #20 bis #29 suchen.
:GetFreeDrvAdr		lda	#20
::1			sta	r14H

			jsr	FindSBusDevice		;Laufwerksadresse testen.

			ldy	r14H
			tax				;Ist Adresse frei ?
			bne	:2			; => Ja, weiter...

			iny
			tya
			cmp	#29 +1			;Max. #29! Sonst kommt es zu
			bcc	:1			;Problemen am ser. Bus!!!

			ldy	r15L
::2			rts
