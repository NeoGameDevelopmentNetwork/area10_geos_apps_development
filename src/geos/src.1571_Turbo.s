; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			o $0300
			n "obj.Turbo71"

:l0300			b $0f,$07,$0d,$05
			b $0b,$03,$09,$01
			b $0e,$06,$0c,$04
			b $0a,$02,$08
:l030f			b $00,$80,$20,$a0
			b $40,$c0,$60,$e0
			b $10,$90,$30,$b0
			b $50,$d0,$70,$f0

:l031f			ldy	#$00
			sty	$73
			sty	$74
			iny
			sty	$71
			ldy	#$00
			jsr	l03e8
			lda	$71
			jsr	l033a
			ldy	$71
:l0334			jsr	l03e8
:l0337			dey
			lda	($73),y
:l033a			tax
			lsr
			lsr
			lsr
			lsr
			sta	$70
			txa
			and	#$0f
			tax
			lda	#$04
			sta	$1800
:l034a			bit	$1800
			beq	l034a
			nop
			nop
			nop
			nop
			stx	$1800
			jsr	l03e0
			txa
			rol
			and	#$0f
			sta	$1800
			php
			plp
			nop
			nop
			nop
			ldx	$70
			lda	l0300,x
			sta	$1800
			jsr	l03df
			rol
			and	#$0f
			cpy	#$00
			sta	$1800
			jsr	l03de
			bne	l0337
			jsr	l03da
			beq	l03d0
:l0382			ldy	#$01
			jsr	l0390
			sta	$71
			tay
			jsr	l0390
			ldy	$71
			rts
:l0390			jsr	l03e8
			jsr	l03db
			lda	#$00
			sta	$70
:l039a			eor	$70
			sta	$70
			jsr	l03db
			lda	#$04
:l03a3			bit	$1800
			beq	l03a3
			jsr	l03dc
			lda	$1800
			jsr	l03db
			asl
			ora	$1800
			php
			plp
			nop
			nop
			and	#$0f
			tax
			lda	$1800
			jsr	l03de
			asl
			ora	$1800
			and	#$0f
			ora	l030f,x
			dey
			sta	($73),y
			bne	l039a
:l03d0			ldx	#$02
			stx	$1800
			jsr	l03d9
			nop
:l03d9			nop
:l03da			nop
:l03db			nop
:l03dc			nop
			nop
:l03de			nop
:l03df			nop
:l03e0			rts
:l03e1			dec	$48
			bne	l03e8
			jsr	l04c5
:l03e8			lda	#$c0
			sta	$1805
:l03ed			bit	$1805
			bpl	l03e1
			lda	#$04
			bit	$1800
			bne	l03ed
			lda	#$00
			sta	$1800
			rts
			php
			sei
			lda	$49
			pha
			ldy	#$00
:l0406			dey
			bne	l0406
			ldy	#$00
:l040b			dey
			bne	l040b
			jsr	l048e
			lda	$180f
			ora	#$20
			sta	$180f
			jsr	$a483
			lda	#$00
			sta	$1800
			lda	#$1a
			sta	$1802
			jsr	l03d0
			lda	#$04
:l042b			bit	$1800
			beq	l042b
			jsr	l04ba
			lda	#$06
			sta	$74
			lda	#$f7
			sta	$73
			jsr	l0382
			lda	l06f9
			sta	l06f6
			cmp	#$24
			bcs	l0453
			lda	$180f
			and	#$fb
			sta	$180f
			jmp	l0461
:l0453			sec
			sbc	#$23
			sta	l06f6
			lda	$180f
			ora	#$04
			sta	$180f
:l0461			jsr	l04be
			lda	#$07
			sta	$74
			lda	#$00
			sta	$73
			lda	#$04
			pha
			lda	#$2f
			pha
			jmp	(l06f7)
			jsr	l03e8
			lda	#$00
			sta	$33
			jsr	$f98f
			lda	#$ec
			sta	$1c0c
			jsr	l048e
			pla
			pla
			pla
			sta	$49
			plp
			rts
:l048e			lda	$180f
			and	#$df
			sta	$180f
			jsr	$a483
			jsr	$ff82
			lda	$02af
			ora	#$80
			sta	$02af
			rts
			lda	l06f9

			sta	$77
			eor	#$60
			sta	$78
			rts
			jsr	l062a
			ldy	#$00
			jsr	l0334
			jmp	l031f
:l04ba			lda	#$f7
			bne	l04cf
:l04be			lda	#$08
			ora	$1c00
			bne	l04dd
:l04c5			lda	#$00
			sta	$20
			lda	#$ff
			sta	$3e
			lda	#$fb
:l04cf			and	$1c00
			jmp	l04dd
:l04d5			lda	$1c00
			and	#$9f
			ora	l04e1,x
:l04dd			sta	$1c00
			rts
:l04e1			brk
			jsr	$6040
:l04e5			jsr	l06d4
			lda	$22
			beq	l04f1
			ldx	$00
			dex
			beq	l0511
:l04f1			lda	$12
			pha
			lda	$13
			pha
			jsr	l0581
			pla
			sta	$13
			tax
			pla
			sta	$12
			ldy	$00
			cpy	#$01
			bne	l0530
			cpx	$17
			bne	l0531
			cmp	$16
			bne	l0531
			lda	#$00
:l0511			pha
			lda	$22
			ldx	#$ff
			sec
			sbc	l06f6
			beq	l052f
			bcs	l0524
			eor	#$ff
			adc	#$01
			ldx	#$01
:l0524			jsr	l0536
			lda	l06f6
			sta	$22
			jsr	l05c2
:l052f			pla
:l0530			rts
:l0531			lda	#$0b
			sta	$00
			rts
:l0536			stx	$4a
			asl
			tay
			lda	$1c00
			and	#$fe
			sta	$70
			lda	#$2f
			sta	$71
:l0545			lda	$70
			clc
			adc	$4a
			eor	$70
			and	#$03
			eor	$70
			sta	$70
			sta	$1c00
			lda	$71
			jsr	l0573
			cpy	#$06
			bcc	l0566
			cmp	#$1b
			bcc	l056c
			sbc	#$03
			bne	l056c
:l0566			cmp	#$2f
			bcs	l056c
			adc	#$04
:l056c			sta	$71
			dey
			bne	l0545
			lda	#$96
:l0573			pha
			sta	$1805
:l0577			lda	$1805
			bne	l0577
			pla
			rts
			jsr	l06d4
:l0581			ldx	$00
			dex
			beq	l059b
			ldx	#$ff
			lda	#$01
			jsr	l0536
			ldx	#$01
			txa
			jsr	l0536
			lda	#$ff
			jsr	l0573
			jsr	l0573
:l059b			lda	#$04
			sta	$70
:l059f			jsr	l0635
			lda	$18
			cmp	#$24
			bcc	l05aa
			sbc	#$23
:l05aa			sta	$22
			ldy	$00
			dey
			beq	l05c2
			dec	$70
			bmi	l05bd
			ldx	$70
			jsr	l04d5
			sec
			bcs	l059f
:l05bd			lda	#$00
			sta	$22
			rts
:l05c2			jsr	$f24b
			sta	$43
			jmp	l04d5
:l05ca			tax
			bit	l06f5
			bpl	l05d8
			jsr	l06e2
			ldx	#$00
			stx	l06f5
:l05d8			cpx	$22
			beq	l05fd
			jsr	l059b
			cmp	#$01
			bne	l05fd
			ldy	$19
			iny
			cpy	$43
			bcc	l05ec
			ldy	#$00
:l05ec			sty	$19
			lda	#$00
			sta	$45
			lda	#$00
			sta	$33
			lda	#$18
			sta	$32
			jsr	l0641
:l05fd			rts
			jsr	l04e5
			ldx	$00
			dex
			bne	l0609
			jsr	l05ca
:l0609			ldy	#$00
			jsr	l0390
			eor	$70
			sta	$3a
			ldy	$00
			dey
			bne	l0622
			lda	$1c00
			and	#$10
			bne	l0622
			lda	#$08
			sta	$00
:l0622			jsr	l031f
			lda	#$10
			jmp	l062f
:l062a			jsr	l04e5
			lda	#$00
:l062f			ldx	$00
			dex
			beq	l0637
			rts
:l0635			lda	#$30
:l0637			sta	$45
			lda	#$06
			sta	$33
			lda	#$f9
			sta	$32

:l0641			lda	#$07
			sta	$31
			tsx
			stx	$49
			ldx	#$01
			stx	$00
			dex
			stx	$02ab
			stx	$02fe
			stx	$3f
			lda	#$ee
			sta	$1c0c
			lda	$45
			cmp	#$10
			beq	l066a
			cmp	#$30
			beq	l0667
			jmp	$9606
:l0667			jmp	$944f
:l066a			jsr	$f78f
			jsr	$970f
			ldy	#$09
:l0672			bit	$180f
			bmi	l0672
			bit	$1c00
			dey
			bne	l0672
			lda	#$ff
			sta	$1c03
			lda	$1c0c
			and	#$1f
			ora	#$c0
			sta	$1c0c
			lda	#$ff
			ldy	#$05
			sta	$1c01
:l0693			bit	$180f
			bmi	l0693
			bit	$1c00
			dey
			bne	l0693
			ldy	#$bb
:l06a0			lda	$0100,y
:l06a3			bit	$180f
			bmi	l06a3
			sta	$1c01
			iny
			bne	l06a0
:l06ae			lda	($30),y
:l06b0			bit	$180f
			bmi	l06b0
			sta	$1c01
			iny
			bne	l06ae
:l06bb			bit	$180f
			bmi	l06bb
			lda	$1c0c
			ora	#$e0
			sta	$1c0c
			lda	#$00
			sta	$1c03
			sta	$50
			lda	#$01
			sta	$00
			rts
:l06d4			lda	$20
			and	#$20
			bne	l06f0
			jsr	$f97e
			lda	#$ff
			sta	l06f5
:l06e2			ldy	#$c8
:l06e4			dex
			bne	l06e4
			dey
			bne	l06e4
			sty	$3e
			lda	#$20
			sta	$20
:l06f0			lda	#$ff
			sta	$48
			rts
:l06f5			b $00
:l06f6			b $00
:l06f7			b $00,$00
:l06f9			b $00,$00
