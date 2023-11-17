; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Ist Maus in Bildschirmbereich ?
:xIsMseInRegion		lda	mouseYPos
			cmp	r2L
			bcc	:5
			cmp	r2H
			beq	:1
			bcs	:5

::1			lda	mouseXPos+1
			cmp	r3H
			bne	:2
			lda	mouseXPos+0
			cmp	r3L
::2			bcc	:5

			lda	mouseXPos+1
			cmp	r4H
			bne	:3
			lda	mouseXPos+0
			cmp	r4L
::3			beq	:4
			bcs	:5
::4			lda	#$ff
			rts
::5			lda	#$00
			rts
