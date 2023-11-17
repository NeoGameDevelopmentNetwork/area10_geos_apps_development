; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;Befindet sich beim 128er in Bank1 ab $d000 unter IO-Bereich!

;*** ZeroPage-Adresse * 2^y
:xDShiftLeft		dey
			bmi	DShiftExit
			asl	zpage +0,x
			rol	zpage +1,x
			jmp	xDShiftLeft

;*** ZeroPage-Adresse : 2^y
:xDShiftRight		dey
			bmi	DShiftExit
			lsr	zpage +1,x
			ror	zpage +0,x
			jmp	xDShiftRight

;*** Zwei Bytes multiplizieren.
:xBBMult		lda	zpage,y
			sta	r8H
			sty	r8L
			ldy	#$08
			lda	#$00
::1			lsr	r8H
			bcc	:2
			clc
			adc	zpage +0,x
::2			ror
			ror	r7L
			dey
			bne	:1
			sta	zpage +1,x
			lda	r7L
			sta	zpage +0,x
			ldy	r8L
:DShiftExit		rts

;*** Bytes mit Word multiplizieren.
:xBMult			lda	#$00
			sta	zpage +1,y

;*** Word mit Word multiplizieren.
:xDMult			lda	#$10
			sta	r8L
			lda	#$00
			sta	r7L
			sta	r7H
::1			lsr	zpage +1,x
			ror	zpage +0,x
			bcc	:2
			lda	r7L
			clc
			adc	zpage +0,y
			sta	r7L
			lda	r7H
			adc	zpage +1,y
::2			lsr
			sta	r7H
			ror	r7L
			ror	r6H
			ror	r6L
			dec	r8L
			bne	:1
			lda	r6L
			sta	zpage +0,x
			lda	r6H
			sta	zpage +1,x
			rts

;*** Ohne Vorzeichen dividieren.
:xDdiv			lda	#$00
			sta	r8L
			sta	r8H
			lda	#$10
			sta	r9L
::1			asl	zpage +0,x
			rol	zpage +1,x
			rol	r8L
			rol	r8H
			lda	r8L
			sec
			sbc	zpage +0,y
			sta	r9H
			lda	r8H
			sbc	zpage +1,y
			bcc	:2
			inc	zpage +0,x
			sta	r8H
			lda	r9H
			sta	r8L
::2			dec	r9L
			bne	:1
:DdivExit		rts

;*** Vorzeichen ermitteln.
:xDabs			lda	zpage +1,x
			bmi	xDnegate
			rts

;*** Mit Vorzeichen dividieren.
:xDSdiv			lda	zpage +1,x
			eor	zpage +1,y
			php
			jsr	xDabs
			stx	r8L
			tya
			tax
			jsr	xDabs
			ldx	r8L
			jsr	xDdiv
			plp
			bpl	DdivExit
;			jmp	xDnegate

;*** Word negieren.
:xDnegate		lda	zpage +1,x
			eor	#$ff
			sta	zpage +1,x
			lda	zpage +0,x
			eor	#$ff
			sta	zpage +0,x
			inc	zpage +0,x
			bne	:1
			inc	zpage +1,x
::1			rts

;*** Word-Adresse -1.
:xDdec			lda	zpage +0,x
			bne	:1
			dec	zpage +1,x
::1			dec	zpage +0,x
			lda	zpage +0,x
			ora	zpage +1,x
			rts
