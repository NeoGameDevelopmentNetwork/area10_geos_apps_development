; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "DiskDev_1571"
			t "G3_SymMacExtDisk"

			a "M. Kanet"
			o DISK_BASE

			w l950e
			w l95a5
			w l97b3
			w l97d5
			w l95fb
			w l9827
			w l9854
			w l987b
			w l9899
			w l98b8
			w l9119
			w l907a
			w l90ce
			w l904e
			w l9089
			w l9290
			w l9476
			w l9423
			w l933d
			w l942b
			w l914b
			w l9144
			w l9262
			w l94b8
			jmp	l91e9
			jmp	l91f7
:l9036			jmp	l9241
:l9039			jmp	l92f1
:l903c			jmp	l9072
:l903f			jmp	l90c6
			jmp	l97ed
			jmp	l991d
			jmp	l93f0
			jmp	l987b

:l904e			jsr	l90e3
			jsr	l907a
			txa
			bne	l906c
			ldy	curDrive
			lda	curDirHead +3
			sta	doubleSideFlg -8,y
			bpl	l906c
			jsr	l90e9
			jsr	l907a
			lda	#$06
			bne	l906e
:l906c			lda	#$08
:l906e			sta	interleave
			rts

:l9072			lda	#$80
			sta	r4H
			lda	#$00
			sta	r4L
:l907a			jsr	EnterTurbo
			bne	l9088
			jsr	InitForIO
			jsr	ReadBlock
			jsr	DoneWithIO
:l9088			rts

:l9089			jsr	EnterTurbo
			jsr	InitForIO
			jsr	l90e3
			jsr	WriteBlock
			txa
			bne	l90c3
			ldy	curDrive
			lda	curDirHead +3
			sta	doubleSideFlg -8,y
			bpl	l90ac
			jsr	l90e9
			jsr	WriteBlock
			txa
			bne	l90c3
:l90ac			jsr	l90e3
			jsr	VerWriteBlock
			txa
			bne	l90c3
			bit	curDirHead +3
			bpl	l90c3
			jsr	l90e9
			jsr	VerWriteBlock
			txa
			bne	l90c3
:l90c3			jmp	DoneWithIO

:l90c6			lda	#$80
			sta	r4H
			lda	#$00
			sta	r4L
:l90ce			jsr	EnterTurbo
			bne	l90e2
			jsr	InitForIO
			jsr	WriteBlock
			txa
			bne	l90df
			jsr	VerWriteBlock
:l90df			jsr	DoneWithIO
:l90e2			rts

:l90e3			ldy	#$12
			lda	#> curDirHead
			bne	l90ed
:l90e9			ldy	#$35
			lda	#> dir2Head
:l90ed			sty	r1L
			sta	r4H
			lda	#$00
			sta	r1H
			sta	r4L
			rts

:l90f8			lda	#$00
			sta	l9d57
			ldx	#$02
			lda	r1L
			beq	l9117
			cmp	#$24
			bcc	l9115
			ldy	curDrive
			lda	doubleSideFlg -8,y
			bpl	l9117
			lda	r1L
			cmp	#$47
			bcs	l9117
:l9115			sec
			rts
:l9117			clc
			rts

:l9119			jsr	NewDisk
			txa
			bne	l9143
			jsr	GetDirHead
			txa
			bne	l9143
			jsr	l91e0
			jsr	ChkDkGEOS
			lda	#> curDirHead +144
			sta	r4H
			lda	#< curDirHead +144
			sta	r4L
			ldx	#$0c
			jsr	GetPtrCurDkNm
			ldx	#$0a
			ldy	#$0c
			lda	#$12
			jsr	CopyFString
			ldx	#$00
:l9143			rts

:l9144			ldy	#$01
			sty	r3L
			dey
			sty	r3H
:l914b			lda	r9H
			pha
			lda	r9L
			pha
			lda	r3H
			pha
			lda	r3L
			pha
			lda	#$00
			sta	r3H
			lda	#$fe
			sta	r3L
			ldx	#$06
			ldy	#$08
			jsr	Ddiv
			lda	r8L
			beq	l9170
			inc	r2L
			bne	l9170
			inc	r2H
:l9170			jsr	l91e0
			jsr	CalcBlksFree
			pla
			sta	r3L
			pla
			sta	r3H
			ldx	#$03
			lda	r2H
			cmp	r4H
			bne	l9188
			lda	r2L
			cmp	r4L
:l9188			beq	l918c
			bcs	l91d9
:l918c			lda	r6H
			sta	r4H
			lda	r6L
			sta	r4L
			lda	r2H
			sta	r5H
			lda	r2L
			sta	r5L
:l919c			jsr	SetNextFree
			txa
			bne	l91d9
			ldy	#$00
			lda	r3L
			sta	(r4L),y
			iny
			lda	r3H
			sta	(r4L),y
			clc
			lda	#$02
			adc	r4L
			sta	r4L
			bcc	l91b8
			inc	r4H
:l91b8			lda	r5L
			bne	l91be
			dec	r5H
:l91be			dec	r5L
			lda	r5L
			ora	r5H
			bne	l919c
			ldy	#$00
			tya
			sta	(r4L),y
			iny
			lda	r8L
			bne	l91d2
			lda	#$fe
:l91d2			clc
			adc	#$01
			sta	(r4L),y
			ldx	#$00
:l91d9			pla
			sta	r9L
			pla
			sta	r9H
			rts

:l91e0			lda	#$82
			sta	r5H
			lda	#$00
			sta	r5L
			rts

:l91e9			lda	#$12
			sta	r1L
			ldy	#$01
			sty	r1H
			dey
			sty	l9d5a
			beq	l9233
:l91f7			ldx	#$00
			ldy	#$00
			clc
			lda	#$20
			adc	r5L
			sta	r5L
			bcc	l9206
			inc	r5H
:l9206			lda	r5H
			cmp	#$80
			bne	l9210
			lda	r5L
			cmp	#$ff
:l9210			bcc	l9240
			ldy	#$ff
			lda	diskBlkBuf +$01
			sta	r1H
			lda	diskBlkBuf +$00
			sta	r1L
			bne	l9233
			lda	l9d5a
			bne	l9240
			lda	#$ff
			sta	l9d5a
			jsr	l9036
			txa
			bne	l9240
			tya
			bne	l9240
:l9233			jsr	l903c
			ldy	#$00
			lda	#$80
			sta	r5H
			lda	#$02
			sta	r5L
:l9240			rts

:l9241			jsr	GetDirHead
			txa
			bne	l9261
			jsr	l91e0
			jsr	ChkDkGEOS
			bne	l9253
			ldy	#$ff
			bne	l925f
:l9253			lda	$82ac
			sta	r1H
			lda	$82ab
			sta	r1L
			ldy	#$00
:l925f			ldx	#$00
:l9261			rts

:l9262			ldy	#$ad
			ldx	#$00
			stx	isGEOS
:l9269			lda	(r5L),y
			cmp	l927f,x
			bne	l927b
			iny
			inx
			cpx	#$0b
			bne	l9269
			lda	#$ff
			sta	isGEOS
:l927b			lda	isGEOS
			rts

:l927f			b $47,$45,$4f,$53
			b $20,$66,$6f,$72
			b $6d,$61,$74,$20
			b $56,$31,$2e,$30
			b $00

:l9290			php
			sei
			lda	r6L
			pha
			lda	r2H
			pha
			lda	r2L
			pha
			ldx	r10L
			inx
			stx	r6L
			lda	#$12
			sta	r1L
			lda	#$01
			sta	r1H
:l92a8			jsr	l903c
:l92ab			txa
			bne	l92e6
			dec	r6L
			beq	l92c7
:l92b2			lda	diskBlkBuf +$00
			bne	l92bd
			jsr	l9039
			clv
			bvc	l92ab
:l92bd			sta	r1L
			lda	diskBlkBuf +$01
			sta	r1H
			clv
			bvc	l92a8
:l92c7			ldy	#$02
			ldx	#$00
:l92cb			lda	diskBlkBuf +$00,y
			beq	l92e6
			tya
			clc
			adc	#$20
			tay
			bcc	l92cb
			lda	#$01
			sta	r6L
			ldx	#$04
			ldy	r10L
			iny
			sty	r10L
			cpy	#$12
			bcc	l92b2
:l92e6			pla
			sta	r2L
			pla
			sta	r2H
			pla
			sta	r6L
			plp
			rts

:l92f1			lda	r6H
			pha
			lda	r6L
			pha
			ldy	#$48
			ldx	#$04
			lda	curDirHead,y
			beq	l9326
			lda	r1H
			sta	r3H
			lda	r1L
			sta	r3L
			jsr	SetNextFree
			lda	r3H
			sta	diskBlkBuf +$01
			lda	r3L
			sta	diskBlkBuf +$00
			jsr	l903f
			txa
			bne	l9326
			lda	r3H
			sta	r1H
			lda	r3L
			sta	r1L
			jsr	l932d
:l9326			pla
			sta	r6L
			pla
			sta	r6H
			rts

:l932d			lda	#$00
			tay
:l9330			sta	diskBlkBuf +$00,y
			iny
			bne	l9330
			dey
			sty	diskBlkBuf +$01
			jmp	l903f

:l933d			lda	r3H
			clc
			adc	interleave
			sta	r6H
			lda	r3L
			sta	r6L
			cmp	#$12
			beq	l935b
			cmp	#$35
			beq	l935b
:l9351			lda	r6L
			cmp	#$12
			beq	l9387
			cmp	#$35
			beq	l9387
:l935b			cmp	#$24
			bcc	l936a
			clc
			adc	#$b9
			tax
			lda	curDirHead,x
			bne	l9372
			beq	l9387
:l936a			asl
			asl
			tax
			lda	curDirHead,x
			beq	l9387
:l9372			lda	r6L
			jsr	l93c6
			lda	l93de,x
			sta	r7L
			tay
:l937d			jsr	l93e2
			beq	l93b8
			inc	r6H
			dey
			bne	l937d
:l9387			bit	curDirHead +3
			bpl	l93a0
			lda	r6L
			cmp	#$24
			bcs	l9399
			clc
			adc	#$23
			sta	r6L
			bne	l93a8
:l9399			sec
			sbc	#$22
			sta	r6L
			bne	l93a4
:l93a0			inc	r6L
			lda	r6L
:l93a4			cmp	#$24
			bcs	l93c3
:l93a8			sec
			sbc	r3L
			sta	r6H
			asl
			adc	#$04
			adc	interleave
			sta	r6H
			clv
			bvc	l9351
:l93b8			lda	r6L
			sta	r3L
			lda	r6H
			sta	r3H
			ldx	#$00
			rts
:l93c3			ldx	#$03
			rts

:l93c6			pha
			cmp	#$24
			bcc	l93ce
			sec
			sbc	#$23
:l93ce			ldx	#$00
:l93d0			cmp	l93da,x
			bcc	l93d8
			inx
			bne	l93d0
:l93d8			pla
			rts

:l93da			b $12,$19,$1f,$24
:l93de			b $15,$13,$12,$11

:l93e2			lda	r6H
:l93e4			cmp	r7L
			bcc	l93ee
			sec
			sbc	r7L
			clv
			bvc	l93e4
:l93ee			sta	r6H
:l93f0			jsr	FindBAMBit
			bne	l93f8
			ldx	#$06
			rts

:l93f8			php
			lda	r6L
			cmp	#$24
			bcc	l940a
			lda	r8H
			eor	dir2Head,x
			sta	dir2Head,x
			clv
			bvc	l9412
:l940a			lda	r8H
			eor	curDirHead,x
			sta	curDirHead,x
:l9412			ldx	r7H
			plp
			beq	l941d
			dec	curDirHead,x
			clv
			bvc	l9420
:l941d			inc	curDirHead,x
:l9420			ldx	#$00
			rts

:l9423			jsr	FindBAMBit
			beq	l93f8
			ldx	#$06
			rts

:l942b			lda	r6H
			and	#$07
			tax
			lda	l946e,x
			sta	r8H
			lda	r6L
			cmp	#$24
			bcc	l945b
			sec
			sbc	#$24
			sta	r7H
			lda	r6H
			lsr
			lsr
			lsr
			clc
			adc	r7H
			asl	r7H
			clc
			adc	r7H
			tax
			lda	r6L
			clc
			adc	#$b9
			sta	r7H
			lda	dir2Head,x
			and	r8H
			rts

:l945b			asl
			asl
			sta	r7H
			lda	r6H
			lsr
			lsr
			lsr
			sec
			adc	r7H
			tax
			lda	curDirHead,x
			and	r8H
			rts

:l946e			b $01,$02,$04,$08
			b $10,$20,$40,$80

:l9476			lda	#$00
			sta	r4L
			sta	r4H
			ldy	#$04
:l947e			lda	(r5L),y
			clc
			adc	r4L
			sta	r4L
			bcc	l9489
			inc	r4H
:l9489			tya
			clc
			adc	#$04
			tay
			cpy	#$48
			beq	l9489
			cpy	#$90
			bne	l947e
			lda	#$02
			sta	r3H
			lda	#$98
			sta	r3L
			bit	curDirHead +3
			bpl	l94b7
			ldy	#$dd
:l94a5			lda	(r5L),y
			clc
			adc	r4L
			sta	r4L
			bcc	l94b0
			inc	r4H
:l94b0			iny
			bne	l94a5
			asl	r3L
			rol	r3H
:l94b7			rts

:l94b8			jsr	GetDirHead
			txa
			bne	l950d
			jsr	l91e0
			jsr	CalcBlksFree
			ldx	#$03
			lda	r4L
			ora	r4H
			beq	l950d
			lda	#$00
			sta	r3H
			lda	#$13
			sta	r3L
			jsr	SetNextFree
			txa
			beq	l94e4
			lda	#$01
			sta	r3L
			jsr	SetNextFree
			txa
			bne	l950d
:l94e4			lda	r3H
			sta	r1H
			lda	r3L
			sta	r1L
			jsr	l932d
			txa
			bne	l950d
			lda	r1H
			sta	curDirHead +$ac
			lda	r1L
			sta	curDirHead +$ab
			ldy	#$bc
			ldx	#$0f
:l9500			lda	l927f,x
			sta	curDirHead,y
			dey
			dex
			bpl	l9500
			jsr	PutDirHead
:l950d			rts

:l950e			php
			pla
			sta	l9d4d
			sei
			lda	CPU_DATA
			sta	l9d4f
			lda	#$36
			sta	CPU_DATA
			lda	$d01a
			sta	l9d4e
			lda	$d030
			sta	l9d4c
			ldy	#$00
			sty	$d030
			sty	$d01a
			lda	#$7f
			sta	$d019
			sta	$dc0d
			sta	$dd0d
			lda	#> l959f
			sta	$0315
			lda	#< l959f
			sta	$0314
			lda	#> l95a4
			sta	$0319
			lda	#< l95a4
			sta	$0318
			lda	#$3f
			sta	$dd02
			lda	$d015
			sta	l9d50
			sty	$d015
			sty	$dd05
			iny
			sty	$dd04
			lda	#$81
			sta	$dd0d
			lda	#$09
			sta	$dd0e
			ldy	#$2c
:l9571			lda	$d012
			cmp	$8f
			beq	l9571
			sta	$8f
			dey
			bne	l9571
			lda	$dd00
			and	#$07
			sta	$8e
			ora	#$30
			sta	$8f
			lda	$8e
			ora	#$10
			sta	l9d56
			ldy	#$1f
:l9591			lda	l96e8,y
			and	#$f0
			ora	$8e
			sta	l96e8,y
			dey
			bpl	l9591
			rts

:l959f			pla
			tay
			pla
			tax
			pla
:l95a4			rti

:l95a5			sei
			lda	l9d4c
			sta	$d030
			lda	l9d50
			sta	$d015
			lda	#$7f
			sta	$dd0d
			lda	$dd0d
			lda	l9d4e
			sta	$d01a
			lda	l9d4f
			sta	CPU_DATA
			lda	l9d4d
			pha
			plp
			rts

:l95cb			stx	$8c
			sta	$8b
			lda	#$00
			sta	STATUS
			lda	curDrive
			jsr	$ffb1
			bit	STATUS
			bmi	l95f5
			lda	#$ff
			jsr	$ff93
			bit	STATUS
			bmi	l95f5
			ldy	#$00
:l95e8			lda	($8b),y
			jsr	$ffa8
			iny
			cpy	#$05
			bcc	l95e8
			ldx	#$00
			rts

:l95f5			jsr	$ffae
			ldx	#$0d
			rts

:l95fb			lda	curDrive
			jsr	SetDevice
			ldx	curDrive
			lda	turboFlags -8,x
			bmi	l9617
			jsr	l9673
			txa
			bne	l964e
			ldx	curDrive
			lda	#$80
			sta	turboFlags -8,x
:l9617			and	#$40
			bne	l9647
			jsr	InitForIO

			ldx	#> l9650
			lda	#< l9650
			jsr	l95cb
			txa
			bne	l964b
			jsr	$ffae
			sei
			ldy	#$21
:l962e			dey
			bne	l962e
			jsr	l9758
:l9634			bit	$dd00
			bmi	l9634
			jsr	DoneWithIO
			ldx	curDrive
			lda	turboFlags -8,x
			ora	#$40
			sta	turboFlags -8,x
:l9647			ldx	#$00
			beq	l964e
:l964b			jsr	DoneWithIO
:l964e			txa
			rts
:l9650			b $4d,$2d,$45,$ff
			b $03

:l9655			jsr	InitForIO
			ldx	#$04
			lda	#$75
			jsr	l97e1
			jsr	l981b
			lda	curDrive
			jsr	$ffb1
			lda	#$ef
			jsr	$ff93
			jsr	$ffae
			jmp	DoneWithIO

:l9673			jsr	InitForIO
			lda	#> l9951
			sta	$8e
			lda	#< l9951
			sta	$8d
			lda	#> $0300
			sta	l96d7
			lda	#< $0300
			sta	l96d6
			lda	#$1f
			sta	$8f
:l968c			jsr	l96b2
			txa
			bne	l96af
			clc
			lda	#$20
			adc	$8d
			sta	$8d
			bcc	l969d
			inc	$8e
:l969d			clc
			lda	#$20
			adc	l96d6
			sta	l96d6
			bcc	l96ab
			inc	l96d7
:l96ab			dec	$8f
			bpl	l968c
:l96af			jmp	DoneWithIO

:l96b2			ldx	#> l96d3
			lda	#< l96d3
			jsr	l95cb
			txa
			bne	l96d2
			lda	#$20
			jsr	$ffa8
			ldy	#$00
:l96c3			lda	($8d),y
			jsr	$ffa8
			iny
			cpy	#$20
			bcc	l96c3
			jsr	$ffae
			ldx	#$00
:l96d2			rts

:l96d3			b $4d,$2d,$57
:l96d6			b $00
:l96d7			b $00
:l96d8			b $0f,$07,$0d,$05
			b $0b,$03,$09,$01
			b $0e,$06,$0c,$04
			b $0a,$02,$08,$00
:l96e8			b $05,$85,$25,$a5
			b $45,$c5,$65,$e5
			b $15,$95,$35,$b5
			b $55,$d5,$75,$f5
:l96f8			b $05,$25,$05,$25
			b $15,$35,$15,$35
			b $05,$25,$05,$25
			b $15,$35,$15,$35

:l9708			lda	r0L
			pha
			jsr	l981b
			sty	r0L
:l9710			sec
:l9711			lda	$d012
			sbc	#$31
			bcc	l971c
			and	#$06
			beq	l9711
:l971c			lda	$8f
			sta	$dd00
			lda	$8e
			sta	$dd00
			dec	r0L
			lda	$dd00
			lsr
			lsr
			nop
			ora	$dd00
			lsr
			lsr
			lsr
			lsr
			ldy	$dd00
			tax
			tya
			lsr
			lsr
			ora	$dd00
			and	#$f0
			ora	l96d8,x
			ldy	r0L
:l9746			sta	($8b),y
			ora	$8d
:l974a			ora	$8d
			tya
			bne	l9710
			jsr	l9758
			pla
			sta	r0L
			lda	($8b),y
			rts
:l9758			ldx	l9d56
			stx	$dd00
			rts

:l975f			jsr	l981b
			tya
			pha
			ldy	#$00
			jsr	l9776
			pla
			tay
:l976b			jsr	l981b
:l976e			dey
			lda	($8b),y
			ldx	$8e
			stx	$dd00
:l9776			tax
			and	#$0f
			sta	$8d
			sec
:l977c			lda	$d012
			sbc	#$31
			bcc	l9787
			and	#$06
			beq	l977c
:l9787			txa
			ldx	$8f
			stx	$dd00
			and	#$f0
			ora	$8e
			sta	$dd00
			ror
			ror
			and	#$f0
			ora	$8e
			sta	$dd00
			ldx	$8d
			lda	l96e8,x
			sta	$dd00
			lda	l96f8,x
			cpy	#$00
			sta	$dd00
			bne	l976e
			nop
			nop
			beq	l9758

:l97b3			lda	#$08
			sta	interleave
			txa
			pha
			ldx	curDrive
			lda	turboFlags -8,x
			and	#$40
			beq	l97d2
			jsr	l9655
			ldx	curDrive
			lda	turboFlags -8,x
			and	#$bf
			sta	turboFlags -8,x
:l97d2			pla
			tax
			rts

:l97d5			jsr	ExitTurbo
:l97d8			ldy	curDrive
			lda	#$00
			sta	turboFlags -8,y
			rts

:l97e1			stx	$8c
			sta	$8b
			ldy	#$02
			bne	l97f9
:l97e9			stx	$8c
			sta	$8b
:l97ed			ldy	#$04
			lda	r1H
			sta	l9d55
			lda	r1L
			sta	l9d54
:l97f9			lda	$8c
			sta	l9d53
			lda	$8b
			sta	l9d52
			lda	#> l9d52
			sta	$8c
			lda	#< l9d52
			sta	$8b
			jmp	l975f

:l980e			ldy	#$01
			jsr	l9708
			pha
			tay
			jsr	l9708
			pla
			tay
			rts
:l981b			sei
			lda	$8e
			sta	$dd00
:l9821			bit	$dd00
			bpl	l9821
			rts

:l9827			pha
			jsr	EnterTurbo
			bne	l9852
			pla
			pha
			ora	#$20
			sta	r1L
			jsr	InitForIO
			ldx	#$04
			lda	#$a5
			jsr	l97e9
			jsr	DoneWithIO
			jsr	l97d8
			pla
			tax
			lda	#$c0
			sta	turboFlags -8,x
			stx	curDrive
			stx	curDevice
			ldx	#$00
			rts
:l9852			pla
			rts

:l9854			jsr	EnterTurbo
			bne	l987a
			sta	l9d57
			sta	r1L
			jsr	InitForIO
:l9861			ldx	#$05
			lda	#$7e
			jsr	l97e9
			jsr	l991d
			beq	l9877
			inc	l9d57
			cpy	l9d57
			beq	l9877
			bcs	l9861
:l9877			jsr	DoneWithIO
:l987a			rts

:l987b			jsr	l90f8
			bcc	l9896
:l9880			jsr	l990b
			jsr	l9708
			jsr	l9924
			txa
			beq	l9896
			inc	l9d57
			cpy	l9d57
			beq	l9896
			bcs	l9880
:l9896			ldy	#$00
			rts

:l9899			jsr	l90f8
			bcc	l98b7
:l989e			ldx	#$05
			lda	#$fe
			jsr	l990f
			jsr	l976b
			jsr	l9924
			beq	l98b7
			inc	l9d57
			cpy	l9d57
			beq	l98b7
			bcs	l989e
:l98b7			rts

:l98b8			jsr	l90f8
			bcc	l990a
			ldx	#$00
:l98bf			lda	#$03
			sta	l9d59
:l98c4			jsr	l990b
			sty	$8d
			lda	#$51
			sta	l9746
			lda	#$85
			sta	l974a
			jsr	l9708
			lda	#$91
			sta	l9746
			lda	#$05
			sta	l974a
			lda	$8d
			pha
			jsr	l9924
			pla
			cpx	#$00
			bne	l98f0
			tax
			beq	l990a
			ldx	#$25
:l98f0			dec	l9d59
			bne	l98c4
			inc	l9d57
			lda	l9d57
			cmp	#$05
			beq	l990a
			pha
			jsr	WriteBlock
			pla
			sta	l9d57
			txa
			beq	l98bf
:l990a			rts

:l990b			ldx	#$04
			lda	#$af
:l990f			jsr	l97e9
			lda	r4H
			sta	$8c
			lda	r4L
			sta	$8b
			ldy	#$00
			rts

:l991d			ldx	#$03
			lda	#$1f
			jsr	l97e1
:l9924			lda	#> l9d58
			sta	$8c
			lda	#< l9d58
			sta	$8b
			jsr	l980e
			lda	l9d58
			pha
			tay
			lda	l9946 -1,y
			tay
			pla
			cmp	#$01
			beq	l9942
			clc
			adc	#$1e
			bne	l9944
:l9942			lda	#$00
:l9944			tax
:l9945			rts

:l9946			b $01,$05,$02,$08
			b $08,$01,$05,$01
			b $05,$05,$05

:l9951			d "obj.Turbo71"

:l9d4c			b $ff
:l9d4d			b $37
:l9d4e			b $f1
:l9d4f			b $30
:l9d50			b $01,$00

:l9d52			b $af
:l9d53			b $04

:l9d54			b $35
:l9d55			b $00
:l9d56			b $15
:l9d57			b $00
:l9d58			b $01
:l9d59			b $00
:l9d5a			b $ff,$00,$00,$00
			b $00,$00,$00,$00
			b $00,$00,$00,$00
			b $00,$00,$00,$00
			b $00,$00,$00,$00
			b $00,$00,$00,$00
			b $00,$00,$00,$00
			b $00,$00,$00,$00
			b $00,$00,$00,$00
			b $00
