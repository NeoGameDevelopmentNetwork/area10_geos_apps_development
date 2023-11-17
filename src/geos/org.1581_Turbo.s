; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			o $0300
			n "obj.Turbo81"
			a "M. Kanet"

:l0300			b $0f,$07,$0d,$05,$0b,$03,$09,$01
			b $0e,$06,$0c,$04,$0a,$02,$08
:l030f			b $00,$80,$20,$a0,$40,$c0,$60,$e0
			b $10,$90,$30,$b0,$50,$d0,$70,$f0

.l031f			ldy	#$00
			lda	l04eb
			bpl	l0328
			ldy	#$02

:l0328			jsr	l0362

.l032b			lda	#$05
			sta	$7e
			ldy	#$00
			sty	$7f
			iny
			jsr	l0354
			jsr	l046a
			cli

:l033b			lda	l04e8
			beq	l034b
			dex
			bne	l034b
			dec	l04e8
			bne	l034b

			jsr	l04be

:l034b			lda	#$04
			bit	$4001
			bne	l033b
			sei
			rts

:l0354			sty	$42

			ldy	#$00
			jsr	l0402

			lda	$42
			jsr	l0368
			ldy	$42
:l0362			jsr	l0402
:l0365			dey
			lda	($7e),y
:l0368			sta	$41
			and	#$0f
:l036c			tax
			lda	#$04
			sta	$4001

:l0372			bit	$4001
			beq	l0372
			lda	l0300,x
			sta	$4001
			nop
			nop
			ldx	$41
			rol
			and	#$0f
			sta	$4001
			txa
			lsr
			lsr
			lsr
			lsr
			tax
			lda	l0300,x
			sta	$4001
			nop
			nop
			nop
			nop
			rol
			and	#$0f
			cpy	#$00
			sta	$4001
			bne	l0365
			jsr	l03fe
			beq	l03ed
			nop
			nop
			nop
			nop
			nop
			nop
			nop

:l03ad			jsr	l0402

			jsr	l03fb

			lda	#$00
			sta	$41
:l03b7			eor	$41
			sta	$41

			jsr	l03fc

			lda	#$04
:l03c0			bit	$4001
			beq	l03c0
			jsr	l03fd
			lda	$4001
			jsr	l03fc
			asl
			ora	$4001
			php
			plp
			nop
			nop
			and	#$0f
			tax
			lda	$4001
			jsr	l03ff
			asl
			ora	$4001
			and	#$0f
			ora	l030f,x
			dey
			sta	($7e),y
			bne	l03b7
:l03ed			ldx	#$02
			stx	$4001
			php
			plp
			php
			plp
			php
			plp
			php
			plp
			nop
:l03fb			nop
:l03fc			nop
:l03fd			nop
:l03fe			nop
:l03ff			nop
			nop
			rts

:l0402			lda	#$04
			bit	$4001
			bne	l0402
			lda	#$00
			sta	$4001
			rts

.l040f			sei

			lda	$41
			pha
			lda	$42
			pha
			lda	$7f
			pha
			lda	$7e
			pha

			ldx	#$02
			ldy	#$00
:l0420			dey
			bne	l0420
			dex
			bne	l0420

			jsr	l03ed

			lda	#$04
:l042b			bit	$4001
			beq	l042b

			lda	#$04
			sta	$7f
			lda	#$e9
			sta	$7e

			ldy	#$01
			jsr	l03ad
			sta	$42
			tay
			jsr	l03ad
			jsr	l046e

			lda	#$06
			sta	$7f
			lda	#$00
			sta	$7e

			lda	#$04
			pha
			lda	#$2f
			pha
			jmp	(l04e9)

.l0457			jsr	l0402
			pla
			pla
			pla
			sta	$7e
			pla
			sta	$7f
			pla
			sta	$42
			pla
			sta	$41
			cli
			rts

:l046a			lda	#$bf
			bne	l0475

:l046e			lda	#$40
			ora	$4000
			bne	l0478

:l0475			and	$4000
:l0478			sta	$4000
			rts

.l047c			jsr	l04b0

			ldy	#$00
			jsr	l03ad

			lda	#$b6
			jsr	l04d1

			lda	$05
			sta	$01fa
			bne	l0498
			lda	#$90
			sta	l04e8
			jsr	l04d1
:l0498			jmp	l032b

.l049b			jsr	l04b9
			lda	#$92
			jsr	l04d1
			lda	$05
			cmp	#$02
			bcc	l04ac
			nop
			nop
			rts

:l04ac			lda	#$b0
			bne	l04d1
:l04b0			lda	l04eb
			and	#$7f
			cmp	$11
			beq	l04e6

.l04b9			lda	l04e8
			beq	l04e6

:l04be			ldx	#$03
			jsr	$ff6c
			lda	#$00
			sta	l04e8
			lda	#$86
			bne	l04d1

.l04cc			jsr	l04b0
			lda	#$80
:l04d1			sta	$05
			lda	l04eb
			and	#$7f
			sta	$11
			lda	l04ec
			sta	$12
			ldx	#$03
			lda	$02,x
			jsr	$ff54
:l04e6			rts

			b $00
:l04e8			b $00
:l04e9			b $00
			b $00
:l04eb			b $00
:l04ec			b $00
