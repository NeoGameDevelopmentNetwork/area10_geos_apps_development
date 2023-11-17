; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Byte aus Datensatz einlesen.
:xReadByte		ldy	r5H
			cpy	r5L
			beq	:52
			lda	(r4L),y
			inc	r5H
			ldx	#$00
::51			rts

::52			ldx	#$0b
			lda	r1L
			beq	:51

			jsr	GetBlock
			txa
			bne	:51

			ldy	#$02
			sty	r5H
			dey
			lda	(r4L),y
			sta	r1H
			tax
			dey
			lda	(r4L),y
			sta	r1L
			beq	:53
			ldx	#$ff
::53			inx
			stx	r5L
			jmp	xReadByte
