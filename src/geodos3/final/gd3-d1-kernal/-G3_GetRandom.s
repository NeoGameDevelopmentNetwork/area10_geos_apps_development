; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Zufallszahl berechnen.
:xGetRandom		inc	random+0
			bne	:1
			inc	random+1
::1			asl	random+0
			rol	random+1
			bcc	:3
			lda	#$0e
			adc	random+0
			sta	random+0
			bcc	:2
			inc	random+1
::2			rts

::3			lda	random+1
			cmp	#$ff
			bcc	:4
			lda	random+0
			sbc	#$f1
			bcc	:4
			sta	random+0
			lda	#$00
			sta	random+1
::4			rts
