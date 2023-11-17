; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** Speicher ab $e000.
;******************************************************************************

;Bereich Bank 0 $e000 bis $feff

:oHorizontalLine	jmp	_HorizontalLine		;  org. -> $E000
:oInvertLine		jmp	_InvertLine		;  org. -> $E003
:oRecoverLine		jmp	_RecoverLine		;  org. -> $E006
:oVerticalLine		jmp	_VerticalLine		;  org. -> $E009
:oRectangle		jmp	xRectangle		;  org. -> $E00C
:oFrameRectangle	jmp	_FrameRectangle		;  org. -> $E00F
:oInvertRectangle	jmp	_InvertRectangle	;  org. -> $E012
:oRecoverRectangle	jmp	_RecoverRectangle	;  org. -> $E015
:oDrawLine		jmp	_DrawLine		;  org. -> $E018
:oDrawPoint		jmp	_DrawPoint		;  org. -> $E01B
:oGetScanLine		jmp	xGetScanLine		;  org. -> $E01E
:oTestPoint		jmp	_TestPoint		;  org. -> $E021
:oBitmapUp		jmp	_BitmapUp		;  org. -> $E024
:oUseSystemFont		jmp	_UseSystemFont		;  org. -> $E027
:oGetRealSize		jmp	_GetRealSize		;  org. -> $E02A
:oGetCharWidth		jmp	_GetCharWidth		;  org. -> $E02D
:oLoadCharSet		jmp	_LoadCharSet		;  org. -> $E030
:oImprintRectangle	jmp	_ImprintRectangle	;  org. -> $E033
:oBitmapClip		jmp	_BitmapClip		;  org. -> $E036
:oBitOtherClip		jmp	_BitOtherClip		;  org. -> $E039
:oInitTextPrompt	jmp	_InitTextPrompt		;  org. -> $E03C
:oPromptOn		jmp	_PromptOn		;  org. -> $E03F
:oPromptOff		jmp	_PromptOff		;  org. -> $E042
:oDoSoftSprites		jmp	_DoSoftSprites		;  org. -> $E045
:oPrntCharCode		jmp	_PrntCharCode		;  org. -> $E048
:oTempHideMouse		jmp	_TempHideMouse		;  org. -> $E04B
:oSetMsePic		jmp	_SetMsePic		;  org. -> $E04E
:oBldGDirEntry		jmp	xBldGDirEntry		;  org. -> $E051
:oVDC_ModeInit		jmp	_VDC_ModeInit		;  org. -> $E054
:oColorPoint		jmp	_ColorPoint		;  org. -> $E057
:oDirectColor		jmp	_DirectColor		;  org. -> $E05A
:oRecColorBox		jmp	_RecColorBox		;  org. -> $E05D
:oMoveData		jmp	_MoveBData		;  org. -> $E060
:oJumpB0_Basic		jmp	_JumpB0_Basic		;  org. -> $E063
:oJumpB0_Basic2		jmp	_JumpB0_Basic2		;  org. -> $E066
:oSwapBData		jmp	_SwapBData		;  org. -> $E069
:oVerifyBData		jmp	_VerifyBData		;  org. -> $E06C
:oDoBOp			jmp	_DoBOp			;  org. -> $E06F
:oDoBAMBuf		jmp	_DoBAMBuf		;  org. -> $E072
:oHideOnlyMouse		jmp	_HideOnlyMouse		;  org. -> $E075

:oGetBackScreenVDC	jmp	_GetBackScreenVDC	;$E078
:oLoad80Screen		jmp	_Load80Screen
:oSave80Screen		jmp	_Save80Screen
:oSet_C_FarbTab		jmp	_Set_C_FarbTab
:oSpritesSpool80	jmp	_SpritesSpool80

;******************************************************************************
;*** Speicher bis $E088 mit $00-Bytes auffüllen.
;******************************************************************************
:_30T			e	$e088
:_30
;******************************************************************************
:_JumpB0_Basic2		pha				;geladenes Programm von
			ldy	#$00			;Bank1 nach Bank0 verschieben
			sty	r0L			;Bereich $1c00 bis $8000
			sty	r1L
			sty	r2L			;r0 = $1c00
			sty	r3H			;r1 = $1c00
			iny
			sty	r3L			;r2 = $6400
			lda	#$1c			;r3L = 1
			sta	r0H			;r3H = 0
			sta	r1H
			lda	#$64
			sta	r2H
			jsr	_MoveBData
			sei
			jsr	SetComAreaOBuUnt
			lda	r5L
			sta	StartBasicReset-1
			ldy	#$02
::1			lda	$1c00,y			;Basic Start verschieben
			sta	StartBasicReset-5,y
			dey
			bpl	:1
			ldx	#LenRestBasic
::2			lda	BasicReset-1,x		;Reset-Routine nach $0e2d
			sta	StartBasicReset-1,x
			dex
			bne	:2
			pla
			jmp	StartBasicReset

:BasicReset		d	"obj.ResetBasic"
:EndResetBasic
:LenRestBasic		=	EndResetBasic - BasicReset

:_GetRealSize		sec
			sbc	#$20
:GetRealSize2		jsr	GetCodeWidth
			tay
			txa
			and	#$40
			beq	le1b3
			iny
:le1b3			txa
			and	#$08
			bne	le1bd
			ldx	curSetHight
			lda	baselineOffset
			rts
:le1bd			ldx	curSetHight
			inx
			inx
			iny
			iny
			lda	baselineOffset
			clc
			adc	#$02
			rts

:DefCharData		ldy	r1H
			iny
			sty	BaseUnderLine
			sta	r5L
			jsr	GetCodeWidth
			pha
			lda	r5L
			asl
			tay
			lda	(curIndexTable),y
			sta	r2L
			and	#$07
			sta	BitStr1stBit
			lda	r2L
			and	#$f8
			sta	r3L
			iny
			lda	(curIndexTable),y
			sta	r2H
			pla
			clc
			adc	r2L
			sta	r6H
			clc
			sbc	r3L
			lsr
			lsr
			lsr
			sta	r3H
			tax
			cpx	#$03
			bcc	le202
			ldx	#$03
:le202			lda	CalcBitDataL,x
			sta	r13L
			lda	CalcBitDataH,x
			sta	r13H
			lda	r2L
			lsr	r2H
			ror
			lsr	r2H
			ror
			lsr	r2H
			ror
			clc
			adc	cardDataPntr
			sta	r2L
			lda	r2H
			adc	cardDataPntr+1
			sta	r2H
			ldy	BitStr1stBit
			lda	BitData3,y
			eor	#$ff
			sta	BitStrDataMask
			ldy	r6H
			dey
			tya
			and	#$07
			tay
			lda	BitData4,y
			eor	#$ff
			sta	r7H
			ldy	#$00
			lda	currentMode
			and	#$08
			beq	le245
			ldy	#$80
:le245			sty	r8H
			lda	r5L
			ldx	currentMode
			jsr	GetRealSize2
			sta	r5H
			lda	r1H
			sec
			sbc	r5H
			sta	r1H
			stx	r10H
			tya
			pha
			lda	r11H
			bmi	le26b
			lda	rightMargin +1
			cmp	r11H
			bne	le269
			lda	rightMargin +0
			cmp	r11L
:le269			bcc	RightOver

:le26b			lda	currentMode
			and	#$10
			bne	le272
			tax
:le272			txa
			lsr
			sta	r3L
			clc
			adc	r11L
			sta	StrBitXposL
			lda	r11H
			adc	#$00
			sta	StrBitXposH
			pla
			sta	CurCharWidth
			clc
			adc	StrBitXposL
			sta	r11L
			lda	#$00
			adc	StrBitXposH
			sta	r11H
			bmi	LeftOver
			lda	leftMargin+1
			cmp	r11H
			bne	le2a0
			lda	leftMargin
			cmp	r11L
:le2a0			bcs	LeftOver
			jsr	StreamInfo
			ldx	#$00
			lda	currentMode
			and	#$20
			beq	le2ae
			dex
:le2ae			stx	r10L
			clc
			rts

:RightOver		pla
			sta	CurCharWidth
			clc
			adc	r11L
			sta	r11L
			bcc	le2cc
			inc	r11H
			sec
			rts

:LeftOver		lda	r11L
			sec
			sbc	r3L
			sta	r11L
			bcs	le2cc
			dec	r11H
:le2cc			sec
			rts

:CalcBitDataL		b	<Char24Bit,<Char32Bit,<Char40Bit,<Char48Bit
:CalcBitDataH		b	>Char24Bit,>Char32Bit,>Char40Bit,>Char48Bit

:StreamInfo		ldx	r1H
			jsr	xGetScanLine
			lda	StrBitXposL
			ldx	StrBitXposH
			bmi	le2eb
			cpx	leftMargin+1
			bne	le2e9
			cmp	leftMargin
:le2e9			bcs	le2ef
:le2eb			ldx	leftMargin+1
			lda	leftMargin
:le2ef			pha
			and	#$f8
			sta	r4L
			bit	graphMode
			bmi	le319
			cpx	#$00
			bne	le300
			cmp	#$c0
			bcc	le314
:le300			sec
			sbc	#$80
			pha
			lda	r5L
			clc
			adc	#$80
			sta	r5L
			sta	r6L
			bcc	le313
			inc	r5H
			inc	r6H
:le313			pla
:le314			sta	r1L
			clv
			bvc	le333

:le319			ldy	#$00
			sty	r1L
			stx	r4H
			lsr	r4H
			ror
			lsr	r4H
			ror
			lsr
			clc
			adc	r5L
			sta	r5L
			sta	r6L
			bcc	le333
			inc	r5H
			inc	r6H
:le333			lda	StrBitXposH
			lsr
			sta	r7L
			lda	StrBitXposL
			ror
			lsr	r7L
			ror
			lsr	r7L
			ror
			sta	r7L
			lda	leftMargin +1
			lsr
			sta	r3L
			lda	leftMargin +0
			ror
			lsr	r3L
			ror
			lsr
			sec
			sbc	r7L
			bpl	le358
			lda	#$00
:le358			sta	CurStreamCard
			lda	StrBitXposL
			and	#$07
			sta	r7L
			pla
			and	#$07
			tay
			lda	BitData3,y
			sta	r3L
			eor	#$ff
			sta	r9L

			ldy	r11L
			dey
			ldx	rightMargin+1
			lda	rightMargin
			cpx	r11H
			bne	le37c
			cmp	r11L
:le37c			bcs	le37f
			tay
:le37f			tya
			and	#$07
			tax
			lda	BitData4,x
			sta	r4H
			eor	#$ff
			sta	r9H
			tya
			sec
			sbc	r4L
			bpl	le394
			lda	#$00
:le394			lsr
			lsr
			lsr
			clc
			adc	CurStreamCard
			sta	r8L
			cmp	r3H
			bcs	le3a3
			lda	r3H
:le3a3			cmp	#$03
			bcs	le3c6
			asl
			asl
			asl
			asl
			sta	r12L
			lda	r7L
			sec
			sbc	BitStr1stBit
			clc
			adc	#$08
			clc
			adc	r12L
			tax
			lda	BitMoveRoutData,x
			adc	#<BitMoveRout
			tay
			lda	#$00
			adc	#>BitMoveRout
			bne	le3ca
:le3c6			lda	#>PrepBitStream
			ldy	#<PrepBitStream
:le3ca			sta	r12H
			sty	r12L
			rts

:BitMoveRoutData	b $c7,$48,$49,$4a,$4b,$4c,$4d,$4e
			b $07,$06,$05,$04,$03,$02,$01,$00
			b $c7,$52,$55,$58,$5b,$5e,$61,$64
			b $1f,$1c,$19,$16,$13,$10,$0d,$0a
			b $c7,$6a,$6f,$74,$79,$7e,$83,$88
			b $45,$40,$3b,$36,$31,$2c,$27,$22

:ChkBaselItalic		lda	currentMode
			bpl	le416
			ldy	r1H
			cpy	BaseUnderLine
			beq	le410
			dey
			cpy	BaseUnderLine
			bne	le416
:le410			lda	r10L
			eor	#$ff
			sta	r10L
:le416			lda	currentMode
			and	#$10
			beq	le455
			lda	r10H
			lsr
			bcs	le439
			ldx	StrBitXposL
			bne	le429
			dec	StrBitXposH
:le429			dex
			stx	StrBitXposL
			ldx	r11L
			bne	le433
			dec	r11H
:le433			dex
			stx	r11L
			jsr	StreamInfo
:le439			lda	rightMargin+1
			cmp	StrBitXposH
			bne	le445
			lda	rightMargin
			cmp	StrBitXposL
:le445			bcc	le453
			lda	leftMargin+1
			cmp	r11H
			bne	le451
			lda	leftMargin
			cmp	r11L
:le451			bcc	le455
:le453			sec
			rts
:le455			clc
			rts

:WriteNewStream		ldy	r1L
			ldx	CurStreamCard
			cpx	r8L
			beq	le49e
			bcs	le4bb
			lda	SetStream,x
			eor	r10L
			and	r9L
			sta	le46f+1
			lda	r3L
			and	(r6L),y
:le46f			ora	#$00
			sta	(r6L),y
			sta	(r5L),y
:le475			tya
			clc
			adc	#$08
			tay
			inx
			cpx	r8L
			beq	le48a
			lda	SetStream,x
			eor	r10L
			sta	(r6L),y
			sta	(r5L),y
			clv
			bvc	le475
:le48a			lda	SetStream,x
			eor	r10L
			and	r9H
			sta	le497+1
			lda	r4H
			and	(r6L),y
:le497			ora	#$00
			sta	(r6L),y
			sta	(r5L),y
			rts

:le49e			lda	SetStream,x
			eor	r10L
			and	r9H
			eor	#$ff
			ora	r3L
			ora	r4H
			eor	#$ff
			sta	le4b5+1
			lda	r3L
			ora	r4H
			and	(r6L),y
:le4b5			ora	#$00
			sta	(r6L),y
			sta	(r5L),y
:le4bb			rts

:le4bc			ldx	CurStreamCard
			cpx	r8L
			beq	le533
			bcs	le4bb
			inx
			cpx	r8L
			bne	le4cd
			jmp	le557
:le4cd			dex
			jsr	GetBScrByte
			ldy	#$00
			sta	le508+1
			lda	r8L
			sec
			sbc	CurStreamCard
			bit	dispBufferOn
			bvc	le4e6
			tay
			lda	(r6L),y
			clv
			bvc	le4fa
:le4e6			clc
			adc	r5L
			sta	r5L
			bcc	le4ef
			inc	r5H
:le4ef			jsr	GetVScrByte
			ldy	r6H
			sty	r5H
			ldy	r6L
			sty	r5L
:le4fa			sta	le52c+1
			lda	SetStream,x
			eor	r10L
			and	r9L
			sta	le50a+1
			lda	r3L
:le508			and	#$00
:le50a			ora	#$00
			ldy	#$00
			jsr	SETtoVarScr
:le511			iny
			inx
			cpx	r8L
			beq	le521
			lda	SetStream,x
			eor	r10L
			jsr	SetNxtBScrByte
			clv
			bvc	le511
:le521			lda	SetStream,x
			eor	r10L
			and	r9H
			sta	le52e+1
			lda	r4H
:le52c			and	#$00
:le52e			ora	#$00
			jmp	SetNxtBScrByte
:le533			lda	SetStream,x
			eor	r10L
			and	r9H
			eor	#$ff
			ora	r3L
			ora	r4H
			eor	#$ff
			sta	le552+1
			jsr	GetBScrByte
			ldy	#$00
			sta	le550+1
			lda	r3L
			ora	r4H
:le550			and	#$00
:le552			ora	#$00
			jmp	SETtoVarScr

:le557			dex
			jsr	GetBScrByte
			ldy	#$00
			sta	le572+1
			iny
			jsr	GetNxtBScrByte
			sta	le587+1
			lda	SetStream,x
			eor	r10L
			and	r9L
			sta	le574+1
			lda	r3L
:le572			and	#$00
:le574			ora	#$00
			ldy	#$00
			jsr	SETtoVarScr
			iny
			lda	SetStream+1,x
			eor	r10L
			and	r9H
			sta	le589+1
			lda	r4H
:le587			and	#$00
:le589			ora	#$00
			jmp	SetNxtBScrByte

:InitNewStream		ldx	r8L
			lda	#$00
:le592			sta	$8805,x
			dex
			bpl	le592
			lda	r8H
			and	#$7f
			bne	le5ae
:le59e			jsr	le612
:le5a1			ldx	r8L
:le5a3			lda	$8805,x
			sta	SetStream,x
			dex
			bpl	le5a3
			inc	r8H
			rts
:le5ae			cmp	#$01
			beq	le5c2
			ldy	r10H
			dey
			beq	le59e
			dey
			php
			jsr	le612
			jsr	AddFontWidth
			plp
			beq	le5d8
:le5c2			jsr	AddFontWidth
			jsr	CopyCharData
			jsr	le612
			lda	r2L
			sec
			sbc	curSetWidth +0
			sta	r2L
			lda	r2H
			sbc	curSetWidth +1
			sta	r2H
:le5d8			jsr	CopyCharData
			jsr	le612
			jsr	le5f2
			clv
			bvc	le5a1
:AddFontWidth		lda	curSetWidth +0
			clc
			adc	r2L
			sta	r2L
			lda	curSetWidth +1
			adc	r2H
			sta	r2H
			rts
:le5f2			ldy	#$ff
:le5f4			iny
			ldx	#$07
:le5f7			lda	$0046,y
			and	BitData5,x
			beq	le60a
			lda	BitData5,x
			eor	#$ff
			and	$8805,y
			sta	$8805,y
:le60a			dex
			bpl	le5f7
			cpy	r8L
			bne	le5f4
			rts
:le612			jsr	MovBitStrData
			ldy	#$ff
:le617			iny
			ldx	#$07
:le61a			lda	$0046,y
			and	BitData5,x
			beq	le65d
			lda	$8805,y
			ora	BitData5,x
			sta	$8805,y
			inx
			cpx	#$08
			bne	le63b
			lda	BaseUnderLine,y
			ora	#$01
			sta	BaseUnderLine,y
			clv
			bvc	le644

:le63b			lda	$8805,y
			ora	BitData5,x
			sta	$8805,y
:le644			dex
			dex
			bpl	le653
			lda	$8806,y
			ora	#$80
			sta	$8806,y
			clv
			bvc	le65c
:le653			lda	$8805,y
			ora	BitData5,x
			sta	$8805,y
:le65c			inx
:le65d			dex
			bpl	le61a
			cpy	r8L
			bne	le617
			rts

:MovBitStrData		lsr	SetStream
			ror	$47
			ror	$48
			ror	$49
			ror	$4a
			ror	$4b
			ror	$4c
			ror	$4d
			rts

:_PrntCharCode		tay
			lda	r1H
			pha
			tya
			jsr	DefCharData
			bcs	le6dc
			jsr	_TempHideMouse
			bit	graphMode
			bpl	le68a
			jmp	Prnt80Char
:le68a			clc
			lda	currentMode
			and	#$90
			beq	le694
			jsr	ChkBaselItalic
:le694			php
			bcs	le69a
			jsr	CopyCharData
:le69a			bit	r8H
			bpl	le6a4
			jsr	InitNewStream
			clv
			bvc	le6a7
:le6a4			jsr	AddFontWidth
:le6a7			plp
			bcs	le6b9
			lda	r1H
			cmp	windowTop
			bcc	le6b9
			cmp	windowBottom
			bcc	le6b6
			bne	le6b9
:le6b6			jsr	WriteNewStream
:le6b9			inc	r5L
			inc	r6L
			lda	r5L
			and	#$07
			bne	le6d6
			inc	r5H
			inc	r6H
			lda	r5L
			clc
			adc	#$38
			sta	r5L
			sta	r6L
			bcc	le6d6
			inc	r5H
			inc	r6H
:le6d6			inc	r1H
			dec	r10H
			bne	le68a
:le6dc			pla
			sta	r1H
			rts

:le6e0			lda	r5L
			clc
			adc	#$50
			sta	r5L
			sta	r6L
			bcc	le6ef
			inc	r5H
			inc	r6H
:le6ef			inc	r1H
			lda	r1H
			cmp	#$64
			bne	Prnt80Char
			bit	dispBufferOn
			bvc	Prnt80Char
			lda	r6H
			clc
			adc	#$21
			sta	r6H
			bit	dispBufferOn
			bmi	Prnt80Char
			sta	r5H
:Prnt80Char		clc
			lda	currentMode
			and	#$90
			beq	le712
			jsr	ChkBaselItalic
:le712			php
			bcs	le718
			jsr	CopyCharData
:le718			bit	r8H
			bmi	le743
			lda	curSetWidth
			clc
			adc	r2L
			sta	r2L
			lda	curSetWidth+1
			adc	r2H
			sta	r2H
:le729			plp
			bcs	le73b
			lda	r1H
			cmp	windowTop
			bcc	le73b
			cmp	windowBottom
			bcc	le738
			bne	le73b
:le738			jsr	le4bc
:le73b			dec	r10H
			bne	le6e0
			pla
			sta	r1H
			rts
:le743			jsr	InitNewStream
			clv
			bvc	le729

:CopyCharData		ldy	#$00
			jmp	(r13)

:DefBitStream2		sta	SetStream
			bit	currentMode
			bvs	le755
			rts
:le755			lda	#$00
			pha
			ldy	#$ff
:le75a			iny
			ldx	SetStream,y
			pla
			ora	BoldData,x
			sta	SetStream,y
			txa
			lsr
			lda	#$00
			ror
			pha
			cpy	r8L
			bne	le75a
			pla
			rts

:Char24Bit		sty	SetStream+1
			sty	SetStream+2
			lda	(r2L),y
			and	BitStrDataMask
			and	r7H
			jmp	(r12)

:Char32Bit		sty	SetStream+2
			sty	SetStream+3
			lda	(r2L),y
			and	BitStrDataMask
			sta	SetStream
			iny
			lda	(r2L),y
			and	r7H
			sta	SetStream+1
			lda	SetStream
			jmp	(r12)

:Char40Bit		sty	SetStream+3
			sty	SetStream+4
			lda	(r2L),y
			and	BitStrDataMask
			sta	SetStream
			iny
			lda	(r2L),y
			sta	SetStream+1
			iny
			lda	(r2L),y
			and	r7H
			sta	SetStream+2
			lda	SetStream
			jmp	(r12)

:Char48Bit		lda	(r2L),y
			and	BitStrDataMask
			sta	SetStream
:le7b8			iny
			cpy	r3H
			beq	le7c5
			lda	(r2L),y
			sta	SetStream,y
			clv
			bvc	le7b8
:le7c5			lda	(r2L),y
			and	r7H
			sta	SetStream,y
			lda	#$00
			sta	SetStream+1,y
			sta	SetStream+2,y
			lda	SetStream
			jmp	(r12)

:BitMoveRout		lsr
			lsr
			lsr
			lsr
			lsr
			lsr
			lsr
			jmp	DefBitStream2

			lsr
			ror	SetStream+1
			lsr
			ror	SetStream+1
			lsr
			ror	SetStream+1
			lsr
			ror	SetStream+1
			lsr
			ror	SetStream+1
			lsr
			ror	SetStream+1
			lsr
			ror	SetStream+1
			jmp	DefBitStream2

			lsr
			ror	SetStream+1
			ror	SetStream+2
			lsr
			ror	SetStream+1
			ror	SetStream+2
			lsr
			ror	SetStream+1
			ror	SetStream+2
			lsr
			ror	SetStream+1
			ror	SetStream+2
			lsr
			ror	SetStream+1
			ror	SetStream+2
			lsr
			ror	SetStream+1
			ror	SetStream+2
			lsr
			ror	SetStream+1
			ror	SetStream+2
			jmp	DefBitStream2

			asl
			asl
			asl
			asl
			asl
			asl
			asl
			jmp	DefBitStream2

			asl	SetStream+1
			rol
			asl	SetStream+1
			rol
			asl	SetStream+1
			rol
			asl	SetStream+1
			rol
			asl	SetStream+1
			rol
			asl	SetStream+1
			rol
			asl	SetStream+1
			rol
			jmp	DefBitStream2

			asl	SetStream+2
			rol	SetStream+1
			rol
			asl	SetStream+2
			rol	SetStream+1
			rol
			asl	SetStream+2
			rol	SetStream+1
			rol
			asl	SetStream+2
			rol	SetStream+1
			rol
			asl	SetStream+2
			rol	SetStream+1
			rol
			asl	SetStream+2
			rol	SetStream+1
			rol
			asl	SetStream+2
			rol	SetStream+1
			rol
			jmp	DefBitStream2

:PrepBitStream		sta	SetStream
			lda	r7L
			sec
			sbc	BitStr1stBit
			beq	le87c
			bcc	DefBitStream
			tay
:le876			jsr	MovBitStrData
			dey
			bne	le876
:le87c			lda	SetStream
			jmp	DefBitStream2

:DefBitStream		lda	BitStr1stBit
			sec
			sbc	r7L
			tay
:le888			asl	SetStream+7
			rol	SetStream+6
			rol	SetStream+5
			rol	SetStream+4
			rol	SetStream+3
			rol	SetStream+2
			rol	SetStream+1
			rol	SetStream
			dey
			bne	le888
			lda	SetStream
			jmp	DefBitStream2
			rts

:_BitOtherClip		ldx	#$ff
			jmp	BitAllClips

:_BitmapClip		ldx	#$00

:BitAllClips		stx	r9H
			jsr	_TempHideMouse
			PushB	RAM_Conf_Reg
			and	#%11110000
			ora	#%00001010		;8k obere Common-Area
			sta	RAM_Conf_Reg
			lda	#$00
			sta	r3L
			sta	r4L
:le8be			lda	r12L
			ora	r12H
			beq	le8e9
			lda	r11L
			jsr	GetNumBytes
			lda	r2L
			bpl	le8ce
			asl
:le8ce			bit	graphMode
			bmi	le8d6
			lda	r2L
			and	#$7f
:le8d6			jsr	GetNumBytes
			lda	r11H
			jsr	GetNumBytes
			lda	r12L
			bne	le8e4
			dec	r12H
:le8e4			dec	r12L
			clv
			bvc	le8be
:le8e9			lda	r11L
			jsr	GetNumBytes
			jsr	PrnPixelLine
			lda	r11H
			jsr	GetNumBytes
			inc	r1H
			dec	r2H
			bne	le8e9
			PopB	RAM_Conf_Reg
			rts

:GetNumBytes		cmp	#$00
			beq	le90f
			pha
			jsr	GetGrafxByte
			pla
			sec
			sbc	#$01
			bne	GetNumBytes
:le90f			rts

:_BitmapUp		jsr	_TempHideMouse
			PushB	RAM_Conf_Reg
			and	#%11110000
			ora	#%00001010		;8k oben Commen-Area
			sta	RAM_Conf_Reg
			PushB	r9H
			LoadB	r9H,0
			lda	#$00
			sta	$888d
			sta	r3L
			sta	r4L
:le92e			jsr	PrnPixelLine
			inc	r1H
			dec	r2H
			bne	le92e
			PopB	r9H
			PopB	RAM_Conf_Reg
			rts

:PrnPixelLine		ldx	r1H
			jsr	xGetScanLine
			lda	r2L
			sta	r3H
			bpl	le956
			bit	graphMode
			bmi	:80Z
			and	#$7f
			sta	r3H
			bne	le956
::80Z			asl	r3H
:le956			bit	graphMode
			bmi	PrnPixLi80
			lda	r1L
			and	#$7f
			cmp	#$20
			bcc	le966
			inc	r5H
			inc	r6H
:le966			asl
			asl
			asl
			tay
:le96a			sty	r9L
			jsr	GetGrafxByte
			ldy	r9L
			sta	(r5L),y
			sta	(r6L),y
			tya
			clc
			adc	#$08
			bcc	le97f
			inc	r5H
			inc	r6H
:le97f			tay
			dec	r3H
			bne	le96a
			rts

:PrnPixLi80		lda	r1L
			bpl	le98a
			asl
:le98a			clc
			adc	r5L
			sta	r5L
			sta	r6L
			bcc	le997
			inc	r5H
			inc	r6H
:le997			jsr	GetGrafxByte
			jsr	SaveToVDCScr
			jsr	SaveToBackScr
			inc	r6L
			inc	r5L
			bne	le9aa
			inc	r6H
			inc	r5H
:le9aa			dec	r3H
			bne	le997
			rts

:GetGrafxByte		bit	graphMode
			bpl	GetGrafxByte40
			bit	r2L
			bpl	GetGrafxByte40
			lda	$888d
			and	#$01
			beq	le9c5
			lda	$888e
			inc	$888d
			rts

:le9c5			jsr	GetGrafxByte40
			sta	$888e
			ldy	#$03
:le9cd			asl	$888e
			php
			rol
			plp
			rol
			dey
			bpl	le9cd
			pha
			ldy	#$03
:le9da			asl	$888e
			php
			rol
			plp
			rol
			dey
			bpl	le9da
			sta	$888e
			pla
			inc	$888d
			rts

:GetGrafxByte40		lda	r3L
			and	#$7f
			beq	lea01
			bit	r3L
			bpl	le9fc
			jsr	GetPackedByte
			dec	r3L
			rts
:le9fc			lda	r7H
			dec	r3L
			rts
:lea01			lda	r4L
			bne	lea0e
			bit	r9H
			bpl	lea0e
			lda	#r14
			jsr	Jsr_00Akku
:lea0e			jsr	GetPackedByte
			sta	r3L
			cmp	#$dc
			bcc	lea30
			sbc	#$dc
			sta	r7L
			sta	r4H
			jsr	GetPackedByte
			sec
			sbc	#$01
			sta	r4L
			lda	r0H
			sta	r8H
			lda	r0L
			sta	r8L
			clv
			bvc	lea01
:lea30			cmp	#$80
			bcs	GetGrafxByte40
			jsr	GetPackedByte
			sta	r7H
			clv
			bvc	GetGrafxByte40

:GetPackedByte		bit	r9H
			bpl	lea45
			lda	#r13
			jsr	Jsr_00Akku
:lea45			lda	MMU
			ora	#$01			;RAM ab $d000 einschalten
			sta	MMU
			ldy	#$00
			lda	(r0L),y
			pha
			lda	MMU
			and	#$fe			;IO-Bereich einschalten
			sta	MMU
			pla
			inc	r0L
			bne	lea61
			inc	r0H
:lea61			ldx	r4L
			beq	lea77
			dec	r4H
			bne	lea77
			ldx	r8H
			stx	r0H
			ldx	r8L
			stx	r0L
			ldx	r7L
			stx	r4H
			dec	r4L
:lea77			rts

:_UseSystemFont		LoadW	r0,BSW128_Font
			bit	graphMode
			bmi	_LoadCharSet
			LoadW	r0,BSW_Font

:_LoadCharSet		ldy	#0
:lea91			lda	(r0L),y
			sta	baselineOffset,y
			iny
			cpy	#8
			bne	lea91
			lda	r0L
			clc
			adc	curIndexTable
			sta	curIndexTable
			lda	r0H
			adc	curIndexTable+1
			sta	curIndexTable+1
			lda	r0L
			clc
			adc	cardDataPntr+0
			sta	cardDataPntr+0
			lda	r0H
			adc	cardDataPntr+1
			sta	cardDataPntr+1
			rts

:_GetCharWidth		sec
			sbc	#$20
			bcs	GetCodeWidth
			lda	#$00
			rts

:GetCodeWidth		cmp	#$5f
			beq	leace
			asl
			tay
			iny
			iny
			lda	(curIndexTable),y
			dey
			dey
			sec
			sbc	(curIndexTable),y
			rts
:leace			lda	CurCharWidth
			rts

:_PromptOn		ldx	#$80
			lda	alphaFlag
			ora	#$40
			bne	leae2

:_PromptOff		ldx	#$40
			lda	alphaFlag
			and	#$bf
:leae2			stx	c128_alphaFlag
			and	#$c0
			ora	#$3c
			sta	alphaFlag
			rts

:_InitTextPrompt	tay
			lda	mob0clr
			sta	mob1clr
			lda	moby2
			and	#$fd
			sta	moby2
			tya
			pha
			lda	#$83
			sta	alphaFlag
			ldx	#$40
			lda	#$00
:leb07			sta	spr1pic-1,x
			dex
			bne	leb07
			pla
			tay
			cpy	#$2a
			bcc	leb15
			ldy	#$2a
:leb15			cpy	#$15
			bcc	leb26
			beq	leb26
			tya
			lsr
			tay
			lda	moby2
			ora	#$02
			sta	moby2
:leb26			tya
			ora	#$80
			sta	spr1pic+$3f
			lda	#$80
:leb2e			sta	spr1pic,x
			inx
			inx
			inx
			dey
			bne	leb2e
			rts

:SetScrAdr		jsr	_TempHideMouse
			ldx	#r3
			jsr	oNormalizeX
			ldx	#r4
			jsr	oNormalizeX
			lda	r4L
			ldx	r4H
			cpx	r3H
			bne	leb4f
			cmp	r3L
:leb4f			bcs	leb5d
			ldy	r3H
			sty	r4H
			ldy	r3L
			sty	r4L
			sta	r3L
			stx	r3H
:leb5d			ldx	r11L
			jsr	xGetScanLine
			lda	r4L
			and	#$07
			tax
			lda	BitData4,x
			sta	r8H
			lda	r3L
			and	#$07
			tax
			lda	BitData3,x
			sta	r8L
			bit	graphMode
			bpl	leb7d
			jsr	SetStartScrAdr
:leb7d			lda	r3L
			and	#$f8
			sta	r3L
			lda	r4L
			and	#$f8
			sta	r4L
			cmp	r3L
			bne	leb91
			lda	r4H
			cmp	r3H
:leb91			rts

:_HorizontalLine	sta	r7L			;Akku = Muster
			PushW	r3
			PushW	r4
			jsr	SetScrAdr
			php
			bit	graphMode
			bmi	HorizLine80
			ldy	r3L
			lda	r3H
			beq	lebb2
			inc	r5H
			inc	r6H
:lebb2			plp
			beq	lebd3
			jsr	SetLineLen
			jsr	GetLinePattern
:lebbb			sta	(r6L),y			;Byteweise setzen
			sta	(r5L),y
			tya
			clc
			adc	#$08
			tay
			bcc	lebca
			inc	r5H
			inc	r6H
:lebca			dec	r4L
			beq	lebda
			lda	r7L
			clv
			bvc	lebbb
:lebd3			lda	r8L			;Pixel am Anfang und Ende der
			ora	r8H			;Linie stezen
			clv
			bvc	lebdc
:lebda			lda	r8H
:lebdc			jsr	GetLinePattern
:lebdf			sta	(r6L),y
			sta	(r5L),y
:lebe3			PopW	r4
			PopW	r3
			rts

:HorizLine80		plp
			beq	lec24
			jsr	SetLineLen
			jsr	GetLinePattern80
			jsr	SaveLineByte
			beq	lec2b
			bit	dispBufferOn
			bvc	Foreground
			ldy	r4L
			lda	r7L
:lec06			dey
			sta	(r6L),y
;			cpy	#$00
			bne	lec06
:Foreground		lda	r7L
			jsr	DrawVDCLineFast
			lda	r5L
			clc
			adc	r4L
			sta	r5L
			sta	r6L
			bcc	lec21
			inc	r5H
			inc	r6H
:lec21			clv
			bvc	lec2b
:lec24			lda	r8L
			ora	r8H
			clv
			bvc	lec2d
:lec2b			lda	r8H
:lec2d			jsr	GetLinePattern80
			jsr	SaveToBackScr
			jsr	SaveToVDCScr
			jmp	lebe3

:SaveLineByte		jsr	SaveToBackScr
			jsr	SaveToVDCScr
			inc	r6L
			inc	r5L
			bne	lec49
			inc	r5H
			inc	r6H
:lec49			dec	r4L
			rts

:SetLineLen		lda	r4L			;Länge der Linie nach r4L
			sec
			sbc	r3L
			sta	r4L
			lda	r4H
			sbc	r3H
			sta	r4H
			lsr	r4H
			ror	r4L
			lsr	r4H
			ror	r4L
			lsr	r4L
			lda	r8L			;Akku = erstes Teilbyte
			rts

:GetLinePattern80	sta	r11H
			jsr	andVScrByte
			jmp	lec6a

:GetLinePattern		sta	r11H
			and	(r5L),y
:lec6a			sta	r7H
			lda	r11H
			eor	#$ff
			and	r7L
			ora	r7H
			rts

:_InvertLine		lda	r3H
			pha
			lda	r3L
			pha
			lda	r4H
			pha
			lda	r4L
			pha
			jsr	SetScrAdr
			php
			bit	graphMode
			bmi	leccd
			ldy	r3L
			lda	r3H
			beq	lec9b
			inc	r5H
			inc	r6H
:lec9b			plp
			beq	lecbd
			jsr	SetLineLen
			eor	(r5L),y
:leca3			eor	#$ff
			sta	(r6L),y
			sta	(r5L),y
			tya
			clc
			adc	#$08
			tay
			bcc	lecb4
			inc	r5H
			inc	r6H
:lecb4			dec	r4L
			beq	lecc4
			lda	(r5L),y
			clv
			bvc	leca3
:lecbd			lda	r8L
			ora	r8H
			clv
			bvc	lecc6
:lecc4			lda	r8H
:lecc6			eor	#$ff
			eor	(r5L),y
			jmp	lebdf
:leccd			plp
			jsr	SetLineLen
			inc	r4L
			jsr	SetComAreaOBuUnt
			lda	r5H
			pha
			lda	r5L
			pha
			ldx	r4L
			dex
			bmi	lecfb
			jsr	GetVScrByte
			clv
			bvc	leced
:lece7			dex
			bmi	lecfb
			jsr	GetNxtVScrByte
:leced			eor	#$ff
			sta	InvLineBuffer,x
			inc	r5L
			bne	lecf8
			inc	r5H
:lecf8			clv
			bvc	lece7
:lecfb			pla
			sta	r5L
			pla
			sta	r5H
			lda	InvLineBuffer
			eor	r8H
			sta	InvLineBuffer
			ldx	r4L
			dex
			bmi	led32
			lda	InvLineBuffer,x
			eor	r8L
			jsr	SaveToVDCScr
			clv
			bvc	led22
:led19			dex
			bmi	led32
			lda	InvLineBuffer,x
			jsr	staNxtVDCData
:led22			jsr	SaveToBackScr
			inc	r6L
			inc	r5L
			bne	led2f
			inc	r6H
			inc	r5H
:led2f			clv
			bvc	led19
:led32			jsr	SetComAreaOBEN
			jmp	lebe3

:led38			lda	r3H
			pha
			lda	r3L
			pha
			lda	r4H
			pha
			lda	r4L
			pha
			lda	dispBufferOn
			pha
			ora	#$c0
			sta	dispBufferOn
			jsr	SetScrAdr
			bit	graphMode
			bpl	led55
			jmp	ledc2
:led55			lda	r5L
			ldy	r6L
			sta	r6L
			sty	r5L
			lda	r5H
			ldy	r6H
			sta	r6H
			sty	r5H
			clv
			bvc	led85

:_RecoverLine		lda	r3H
			pha
			lda	r3L
			pha
			lda	r4H
			pha
			lda	r4L
			pha
			lda	dispBufferOn
			pha
			ora	#$c0
			sta	dispBufferOn
			jsr	SetScrAdr
			bit	graphMode
			bpl	led85
			jmp	ledff

:led85			pla
			sta	dispBufferOn
			ldy	r3L
			lda	r3H
			beq	led92
			inc	r5H
			inc	r6H
:led92			jsr	CMPr3_r4
			beq	ledb3
			jsr	SetLineLen
			jsr	lee3c
:led9d			tya
			clc
			adc	#$08
			tay
			bcc	leda8
			inc	r5H
			inc	r6H
:leda8			dec	r4L
			beq	ledba
			lda	(r6L),y
			sta	(r5L),y
			clv
			bvc	led9d
:ledb3			lda	r8L
			ora	r8H
			clv
			bvc	ledbc
:ledba			lda	r8H
:ledbc			jsr	lee3c
			jmp	lebe3
:ledc2			jsr	CMPr3_r4
			beq	leddf
			jsr	SetLineLen
			jsr	lee61
			iny
:ledce			dec	r4L
			beq	lede6
:ledd2			bit	VDCBaseD600
			bpl	ledd2
			lda	VDCDataD601
			sta	(r6L),y
			iny
			bne	ledce
:leddf			lda	r8L
			ora	r8H
			clv
			bvc	ledf6
:lede6			tya
			clc
			adc	r5L
			sta	r5L
			sta	r6L
			bcc	ledf4
			inc	r5H
			inc	r6H
:ledf4			lda	r8H
:ledf6			jsr	lee61
			pla
			sta	dispBufferOn
			jmp	lebe3

:ledff			jsr	CMPr3_r4
			beq	lee1c
			jsr	SetLineLen
			jsr	lee4d
			iny
:lee0b			dec	r4L
			beq	lee23
			lda	(r6L),y
:lee11			bit	VDCBaseD600
			bpl	lee11
			sta	VDCDataD601
			iny
			bne	lee0b
:lee1c			lda	r8L
			ora	r8H
			clv
			bvc	lee33
:lee23			tya
			clc
			adc	r5L
			sta	r5L
			sta	r6L
			bcc	lee31
			inc	r5H
			inc	r6H
:lee31			lda	r8H
:lee33			jsr	lee4d
			pla
			sta	dispBufferOn
			jmp	lebe3

:lee3c			sta	r7L
			and	(r5L),y
			sta	r7H
			lda	r7L
			eor	#$ff
			and	(r6L),y
			ora	r7H
			sta	(r5L),y
			rts
:lee4d			sta	r7L
			jsr	andVScrByte
			sta	r7H
			lda	r7L
			eor	#$ff
			ldy	#$00
			and	(r6L),y
			ora	r7H
			jmp	SaveToVDCScr
:lee61			sta	r7L
			ldy	#$00
			and	(r6L),y
			sta	r7H
			lda	r7L
			eor	#$ff
			jsr	andVScrByte
			ora	r7H
			sta	(r6L),y
			rts

:_VerticalLine		sta	r8L
			jsr	_TempHideMouse
			ldx	#$0a
			jsr	oNormalizeX
			bit	graphMode
			bmi	leee1
			lda	r4L
			pha
			and	#$07
			tax
			lda	BitData6,x
			sta	r7H
			lda	r4L
			and	#$f8
			sta	r4L
			ldy	#$00
			ldx	r3L
:lee98			stx	r7L
			jsr	xGetScanLine
			lda	r4L
			clc
			adc	r5L
			sta	r5L
			lda	r4H
			adc	r5H
			sta	r5H
			lda	r4L
			clc
			adc	r6L
			sta	r6L
			lda	r4H
			adc	r6H
			sta	r6H
			lda	r7L
			and	#$07
			tax
			lda	BitData6,x
			and	r8L
			bne	leecc
			lda	r7H
			eor	#$ff
			and	(r6L),y
			clv
			bvc	leed0
:leecc			lda	r7H
			ora	(r6L),y
:leed0			sta	(r6L),y
			sta	(r5L),y
			ldx	r7L
			inx
			cpx	r3H
			beq	lee98
			bcc	lee98
			pla
			sta	r4L
			rts

:leee1			lda	r3H
			pha
			lda	r3L
			pha
			ldx	r3L
			stx	r7L
			jsr	xGetScanLine
			lda	r4H
			sta	r3H
			lda	r4L
			sta	r3L
			jsr	SetStartScrAdr
			lda	BitData6,x
			sta	r7H
			pla
			sta	r3L
			pla
			sta	r3H
			ldx	r3L
:lef06			stx	r7L
			txa
			and	#$07
			tax
			lda	BitData6,x
			and	r8L
			bne	lef1d
			lda	r7H
			eor	#$ff
			jsr	andBScrByte
			clv
			bvc	lef22
:lef1d			lda	r7H
			jsr	oraBScrByte
:lef22			jsr	SaveToBackScr
			jsr	SaveToVDCScr
			ldx	r7L
			jsr	lef34
			cpx	r3H
			beq	lef06
			bcc	lef06
			rts

:lef34			lda	r5L
			clc
			adc	#$50
			sta	r5L
			sta	r6L
			bcc	lef43
			inc	r5H
			inc	r6H
:lef43			inx
			cpx	#$64
			beq	lef49
			rts
:lef49			bit	dispBufferOn
			bvc	lef5a
			lda	r6H
			clc
			adc	#$21
			sta	r6H
			bit	dispBufferOn
			bmi	lef5a
			sta	r5H
:lef5a			rts

;Neue (Fast)-Rectangle Routinen
;muß oberhalb von $e000 liegen wegen einlesen der Pattern
;aus Bank1 Bereich $c000 - $cfff

			t "-G3_NewRec"

			t "-G3_FastRec"

:_InvertRectangle	lda	r2L
			sta	r11L
:lef87			jsr	_InvertLine
			lda	r11L
			inc	r11L
			cmp	r2H
			bne	lef87
			rts

:_RecoverRectangle	lda	r2L
			sta	r11L
:lef97			jsr	_RecoverLine
			lda	r11L
			inc	r11L
			cmp	r2H
			bne	lef97
			rts

:_ImprintRectangle	lda	r2L
			sta	r11L
:lefa7			jsr	led38
			lda	r11L
			inc	r11L
			cmp	r2H
			bne	lefa7
			rts

:_FrameRectangle	sta	r9H
			ldy	r2L
			sty	r11L
			jsr	_HorizontalLine
			lda	r2H
			sta	r11L
			lda	r9H
			jsr	_HorizontalLine
			lda	r3H
			pha
			lda	r3L
			pha
			lda	r4H
			pha
			lda	r4L
			pha
			lda	r3H
			sta	r4H
			lda	r3L
			sta	r4L
			lda	r2H
			sta	r3H
			lda	r2L
			sta	r3L
			lda	r9H
			jsr	_VerticalLine
			pla
			sta	r4L
			pla
			sta	r4H
			lda	r9H
			jsr	_VerticalLine
			pla
			sta	r3L
			pla
			sta	r3H
			rts
			pla
			sta	r5L
			pla
			sta	r5H
			pla
			sta	returnAddress +0
			pla
			sta	returnAddress +1
			ldy	#$01
			lda	(returnAddress),y
			sta	r2L
			iny
			lda	(returnAddress),y
			sta	r2H
			iny
			lda	(returnAddress),y
			sta	r3L
			iny
			lda	(returnAddress),y
			sta	r3H
			iny
			lda	(returnAddress),y
			sta	r4L
			iny
			lda	(returnAddress),y
			sta	r4H
			lda	r5H
			pha
			lda	r5L
			pha
			rts

:BitData6		b $80,$40,$20,$10,$08,$04,$02
:BitData5		b $01,$02,$04,$08,$10,$20,$40,$80
:BitData3		b $00,$80,$c0,$e0,$f0,$f8,$fc,$fe
:BitData4		b $7f,$3f,$1f,$0f,$07,$03,$01,$00

:_DrawLine		php
			bmi	lf05c
			lda	r11L
			cmp	r11H
			bne	lf05c
			lda	#$ff
			plp
			bcs	lf059
			lda	#$00
:lf059			jmp	_HorizontalLine

:lf05c			ldx	#$08
			jsr	oNormalizeX
			ldx	#$0a
			jsr	oNormalizeX
			lda	#$00
			sta	r7H
			lda	r11H
			sec
			sbc	r11L
			sta	r7L
			bcs	lf07a
			lda	#$00
			sec
			sbc	r7L
			sta	r7L
:lf07a			lda	r4L
			sec
			sbc	r3L
			sta	r12L
			lda	r4H
			sbc	r3H
			sta	r12H
			ldx	#$1a
			jsr	InvertZpWord
			lda	r12H
			cmp	r7H
			bne	lf096
			lda	r12L
			cmp	r7L
:lf096			bcs	lf09b
			jmp	lf140
:lf09b			lda	r7H
			sta	r9H
			lda	r7L
			sta	r9L
			ldy	#$01
			ldx	#$14
			jsr	RotateLeftZpWord
			lda	r9L
			sec
			sbc	r12L
			sta	r8L
			lda	r9H
			sbc	r12H
			sta	r8H
			lda	r7L
			sec
			sbc	r12L
			sta	r10L
			lda	r7H
			sbc	r12H
			sta	r10H
			ldy	#$01
			ldx	#$16
			jsr	RotateLeftZpWord
			lda	#$ff
			sta	r13L
			jsr	CMPr3_r4
			bcc	lf0f9
			lda	r11L
			cmp	r11H
			bcc	lf0de
			lda	#$01
			sta	r13L
:lf0de			lda	r3H
			pha
			lda	r3L
			pha
			lda	r4H
			sta	r3H
			lda	r4L
			sta	r3L
			lda	r11H
			sta	r11L
			pla
			sta	r4L
			pla
			sta	r4H
			clv
			bvc	lf103

:lf0f9			ldy	r11H
			cpy	r11L
			bcc	lf103
			lda	#$01
			sta	r13L
:lf103			plp
			php
			jsr	_DrawPoint
			jsr	CMPr3_r4
			bcs	lf13e
			inc	r3L
			bne	lf113
			inc	r3H
:lf113			bit	r8H
			bpl	lf127
			lda	r9L
			clc
			adc	r8L
			sta	r8L
			lda	r9H
			adc	r8H
			sta	r8H
			clv
			bvc	lf103

:lf127			clc
			lda	r13L
			adc	r11L
			sta	r11L
			lda	r10L
			clc
			adc	r8L
			sta	r8L
			lda	r10H
			adc	r8H
			sta	r8H
			clv
			bvc	lf103
:lf13e			plp
			rts
:lf140			lda	r12H
			sta	r9H
			lda	r12L
			sta	r9L
			ldy	#$01
			ldx	#$14
			jsr	RotateLeftZpWord
			lda	r9L
			sec
			sbc	r7L
			sta	r8L
			lda	r9H
			sbc	r7H
			sta	r8H
			lda	r12L
			sec
			sbc	r7L
			sta	r10L
			lda	r12H
			sbc	r7H
			sta	r10H
			ldy	#$01
			ldx	#$16
			jsr	RotateLeftZpWord
			lda	#$ff
			sta	r13H
			lda	#$ff
			sta	r13L
			lda	r11L
			cmp	r11H
			bcc	lf1a0
			jsr	CMPr3_r4
			bcc	lf18b
			lda	#$00
			sta	r13H
			lda	#$01
			sta	r13L
:lf18b			lda	r4H
			sta	r3H
			lda	r4L
			sta	r3L
			lda	r11L
			pha
			lda	r11H
			sta	r11L
			pla
			sta	r11H
			clv
			bvc	lf1ad

:lf1a0			jsr	CMPr3_r4
			bcs	lf1ad
			lda	#$00
			sta	r13H
			lda	#$01
			sta	r13L
:lf1ad			plp
			php
			jsr	_DrawPoint
			lda	r11L
			cmp	r11H
			bcs	lf1eb
			inc	r11L
			bit	r8H
			bpl	lf1ce
			lda	r9L
			clc
			adc	r8L
			sta	r8L
			lda	r9H
			adc	r8H
			sta	r8H
			clv
			bvc	lf1ad

:lf1ce			lda	r13L
			clc
			adc	r3L
			sta	r3L
			lda	r13H
			adc	r3H
			sta	r3H
			lda	r10L
			clc
			adc	r8L
			sta	r8L
			lda	r10H
			adc	r8H
			sta	r8H
			clv
			bvc	lf1ad
:lf1eb			plp
			rts

:_DrawPoint		php
			jsr	_TempHideMouse
			ldx	#r3
			jsr	oNormalizeX
			ldx	r11L
			jsr	xGetScanLine		;Zeilenadresse nach r6/r5
			bit	graphMode
			bmi	DrawPoint80
			lda	r3L
			and	#%11111000
			tay				;>Cards-Zähler im Y-Register
			lda	r3H			;>an Highbyte anpassen
			beq	lf20c
			inc	r5H
			inc	r6H
:lf20c			lda	r3L
			and	#%00000111		;zu setzendes Bit ausmaskieren
			tax
			lda	BitData6,x		;Bitdaten holen
			plp
			bmi	:fromBACKtoFront
			bcc	:ClrPoint
::SetPoint		ora	(r6L),y			;>mit aktuellem Screenbyte
			clv				; verknüpfen
			bvc	:1			; und speichern
::ClrPoint		eor	#%11111111
			and	(r6L),y
::1			sta	(r6L),y
			sta	(r5L),y
			rts
::fromBACKtoFront	pha
			eor	#%11111111
			and	(r5L),y
			sta	(r5L),y
			pla
			and	(r6L),y
			ora	(r5L),y
			sta	(r5L),y
			rts

:DrawPoint80		jsr	SetStartScrAdr		;r5=r5+r3(in Cards) X=r3L
			lda	BitData6,x
			plp
			bmi	:BACKtoFRONT
			bcc	:ClrPoint
			jsr	oraBScrByte
			clv
			bvc	:1
::ClrPoint		eor	#$ff
			jsr	andBScrByte
::1			jsr	SaveToBackScr
			jmp	SaveToVDCScr
::BACKtoFRONT		pha
			eor	#$ff
			jsr	andVScrByte
			sta	:Buffer
			pla
			jsr	andBScrByte
			ora	:Buffer
			jmp	SaveToVDCScr

::Buffer		s	1

:_TestPoint		jsr	_TempHideMouse
			ldx	#r3
			jsr	oNormalizeX
			ldx	r11L
			jsr	xGetScanLine
			bit	graphMode
			bmi	TestPoint80
			lda	r3L
			and	#%11111000
			tay
			lda	r3H
			beq	lf282
			inc	r6H
:lf282			lda	r3L
			and	#%00000111
			tax
			lda	BitData6,x
			and	(r6L),y
			beq	lf290
			sec
			rts
:lf290			clc
			rts

:TestPoint80		jsr	SetStartScrAdr
			lda	BitData6,x
			jsr	andBScrByte
			beq	lf29f
			sec
			rts
:lf29f			clc
			rts

			t "+G3_VDCModeInit"

:CMPr3_r4		lda	r3H
			cmp	r4H
			bne	lf2ab
			lda	r3L
			cmp	r4L
:lf2ab			rts

:DrawVDCLineFast	bit	dispBufferOn
			bpl	:1			;>nicht in Vordergrund
			jsr	SetVDCScrByte		;Set Byte an VDC Adresse r5
			lda	r4L			;Breite der Linie
			sec				;1 abziehen da 1 Byte durch
			sbc	#1			;SetVDCScrByte schon gesetzt ist
			beq	:1			;>alle schon gesetzt dann Ende
			ldx	#30			;WordCount-Register setzen
			stx	VDCBaseD600
::2			bit	VDCBaseD600
			bpl	:2
			sta	VDCDataD601		;Anzahl setzen
::1			rts

:GetNxtBScrByte		bit	dispBufferOn
			bvc	:1			;>kein Hintergrund
			lda	(r6L),y
			rts
::1			bit	VDCBaseD600
			bpl	:1
			lda	VDCDataD601
			rts

:GetBScrByte		bit	dispBufferOn
			bvc	lf4a0			;>kein Hintergrund
			ldy	#$00
			lda	(r6L),y
			rts
:lf4a0			stx	XRegBuf_r6+1
			ldx	#$ad			;lda-Befehl
			bne	DoVarScrByte_r6

:oraBScrByte		bit	dispBufferOn
			bvc	lf4b0			;>kein Hintergrund
			ldy	#$00
			ora	(r6L),y
			rts
:lf4b0			stx	XRegBuf_r6+1
			ldx	#$0d			;ora-Befehl
			bne	DoVarScrByte_r6

:andBScrByte		bit	dispBufferOn
			bvc	lf4c0			;>kein Hintergrund
			ldy	#$00
			and	(r6L),y
			rts
:lf4c0			stx	XRegBuf_r6+1
			ldx	#$2d			;and-Befehl

:DoVarScrByte_r6	stx	Befehl_r6
			ldx	#18
			stx	VDCBaseD600
			ldx	r6H
::1			bit	VDCBaseD600
			bpl	:1
			stx	VDCDataD601
			ldx	#19
			stx	VDCBaseD600
			ldx	r6L
::2			bit	VDCBaseD600
			bpl	:2
			stx	VDCDataD601
			ldx	#31
			stx	VDCBaseD600
:XRegBuf_r6		ldx	#$00
::1			bit	VDCBaseD600
			bpl	:1
:Befehl_r6		lda	VDCDataD601
			rts

:oSetVDC		stx	VDCBaseD600
::1			bit	VDCBaseD600
			bpl	:1
			sta	VDCDataD601
			rts

:oGetVDC		stx	VDCBaseD600
::1			bit	VDCBaseD600
			bpl	:1
			lda	VDCDataD601
			rts

:GetNxtVScrByte		bit	dispBufferOn
			bmi	lf519			;>nur Vordergrund
			bvc	lf519			;>kein Hintergrund
			ldy	#$00
			lda	(r5L),y
			rts
:lf519			bit	VDCBaseD600
			bpl	lf519
			lda	VDCDataD601
			rts

:GetVScrByte		bit	dispBufferOn
			bmi	GetVDCScrByte
			bvc	GetVDCScrByte
			ldy	#$00
			lda	(r5L),y
			rts
:GetVDCScrByte		stx	BufXReg+1
			ldx	#$ad			;LDA - Befehl
			bne	DoVarVDC		;unbedingter Sprung

:oraVScrByte		bit	dispBufferOn		;40 oder 80Zeichen?
			bmi	:80Z
			bvc	:80Z
			ldy	#$00
			ora	(r5L),y
			rts
::80Z			stx	BufXReg+1
			ldx	#$0d			;ORA - Befehl
			bne	DoVarVDC		;unbedingter Sprung

:eorVScrByte		bit	dispBufferOn
			bmi	:80Z
			bvc	:80Z
			ldy	#$00
			eor	(r5L),y
			rts
::80Z			stx	BufXReg+1
			ldx	#$4d			;EOR - Befehl
			bne	DoVarVDC		;unbedingter Sprung

:andVScrByte		bit	dispBufferOn
			bmi	:80Z
			bvc	:80Z
			ldy	#$00
			and	(r5L),y
			rts
::80Z			stx	BufXReg+1
			ldx	#$2d			;AND - Befehl
			bne	DoVarVDC		;unbedingter Sprung

:SETtoVarScr		bit	dispBufferOn
			bvc	lf570
			sta	(r6L),y
:lf570			bmi	SetVDCScrByte
			rts

:SaveToVDCScr		bit	dispBufferOn
			bmi	SetVDCScrByte
			rts

:SetVDCScrByte		stx	BufXReg+1
			ldx	#$8d			;STA - Befehl

:DoVarVDC		stx	DoVarBefehl		;Befehl speichern
			ldx	#18
			stx	VDCBaseD600
			ldx	r5H
:lf587			bit	VDCBaseD600
			bpl	lf587
			stx	VDCDataD601
			ldx	#19
			stx	VDCBaseD600
			ldx	r5L
:lf596			bit	VDCBaseD600
			bpl	lf596
			stx	VDCDataD601
			ldx	#31
			stx	VDCBaseD600
:BufXReg		ldx	#$00
:lf5a5			bit	VDCBaseD600
			bpl	lf5a5
:DoVarBefehl		sta	VDCDataD601
			rts

:SetNxtBScrByte		bit	dispBufferOn
			bvc	lf5b4
			sta	(r6L),y
:lf5b4			bpl	lf5be
:lf5b6			bit	VDCBaseD600
			bpl	lf5b6
			sta	VDCDataD601
:lf5be			rts

:staNxtVDCData		bit	dispBufferOn
			bpl	lf5cb
:lf5c3			bit	VDCBaseD600
			bpl	lf5c3
			sta	VDCDataD601
:lf5cb			rts

:SaveToBackScr		bit	dispBufferOn
			bvc	lf5d4
			ldy	#$00
			sta	(r6L),y
:lf5d4			rts

			t "-G3_NewGetScanL"

:SetBackScrPtr		lda	r5H
			clc
			adc	#$60
			sta	r6H
			lda	r5L
			sta	r6L
			lda	r6H
			cmp	#$7f
			bne	lfa92
			lda	r6L
			cmp	#$40
:lfa92			bcc	lfa9b
			lda	r6H
			clc
:lfa97			adc	#$21
			sta	r6H
:lfa9b			rts

:lfa9c			bvc	lfaac
			jsr	SetBackScrPtr
:lfaa1			lda	r6H
			sta	r5H
			lda	r6L
			sta	r5L
			pla
			tax
			rts

:lfaac			lda	r5H
			sta	r6H
			lda	r5L
			sta	r6L
			pla
			tax
			rts
			lda	r3H
			pha
			lda	r3L
			and	#$07
			pha
			lda	r3L
			lsr	r3H
			ror
			lsr	r3H
			ror
			lsr	r3H
			ror
			clc
			adc	r5L
			sta	r5L
			sta	r6L
			php
			lda	r5H
			adc	r3H
			sta	r5H
			plp
			lda	r6H
			adc	r3H
			sta	r6H
			pla
			tax
			pla
			sta	r3H
			rts

;VDC-Bildschirm zwischenspeichern
;für DialogBox		      - Komplett innerhalb des VDC von $6000 bis $bfff
;für Bildschirmschoner  - Grafik innerhalb des VDC von $c000 bis $ffff
;			      - Farbram im Bereich $a000 bis $bfff in Bank 1
;			      = Vordegrundspeicher 40 Zeichen
;                         muß vom Bildschirmschoner
;			        immer mit gesichert werden, auch im 80 Zeichen-Modus
;für Spooler		      - Grafik im Bereich MP3_64K_DATA $1000 bis $6fff
;Übergabe:		Y-Reg = 0 und...
;			sec   - Komplette Speicherung im VDC (DialogBox)
;			clc   - Speicherung VDC/Bank 1 (Bildschirmschoner)
;			Y-Reg <> 0 - Speicherung im Bereich MP3_64K_DATA (Spooler)
;			Akku  =  0 - Bildschirm nicht löschen
;			Akku  <> 0 - Bildschirm löschen mit Farbe im Akku setzen

:_Save80Screen		beq	Save80			;> keine Farbe setzen/kein löschen
			pha				;Farbe sichern
			jsr	Save80			;Bildschirm sichern
			ldx	#18
			lda	#$00			;Startadresse = $0000 VDC
			jsr	oSetVDC
			inx
			jsr	oSetVDC
			ldy	#200
::4			lda	#0
			jsr	SetLine			;Linie setzen
			dey
			bne	:4
			pla
:ClearColScr80		pha
			ldx	#18
			lda	#$40			;Startadresse = $4000
			jsr	oSetVDC
			lda	#$00
			inx
			jsr	oSetVDC
			ldy	#100			;100 Linien löschen falls hohe Auflösung
::3			pla				;Farbe wiederherstellen
			pha				;und sichern
			jsr	SetLine			;Bildschirmfarbe setzen
			dey
			bne	:3
			pla
			rts

;Bildschirm retten/wiederherstellen
:Save80			lda	#0			;Save-Kennzeichen
			b	$2c
:_Load80Screen		lda	#1			;Load-Kennzeichen
			pha
			tya				;Wiederherstellung/Retten für Spooler?
			beq	:5			;> nein
			pla				;> ja Save-/Loadkennzeichen holen
			jmp	LdSvSpoolScrn		;SpoolerBildschirm retten/wiederherstellen

::5			php				;Modus sichern
			jsr	_TempHideMouse
			jsr	SetCopyBit
			plp				;Modus wiederherstellen
			bcc	:1			;> Farbdaten in Bank 1 sichern
			pla
			jmp	_LdSvVDCScreen		;> kompletter Bildschirm im VDC

::1			pla
			beq	:3			;> Screen retten

			jsr	_LoadScrCol		;> Farben wiederherstellen
			lda	#$c0			;Copy von $c000
			ldy	#$00
			ldx	#32
			jsr	SetVDCReg
			lda	#$00			;nach $0000
			tay
			ldx	#18
			jsr	SetVDCReg
			jmp	:4

::3			jsr	_SaveScrCol
			lda	#$00			;Copy von $0000
			tay
			ldx	#32
			jsr	SetVDCReg
			lda	#$c0			;nach $c000
			ldy	#$00
			ldx	#18
			jsr	SetVDCReg

::4			ldy	#63			;Anzahl Durchläufe
			lda	#0			;256 Bytes kopieren
			ldx	#30			;WordCount-Register
::2			jsr	oSetVDC
			dey
			bne	:2
			jmp	ClearCopyBit

:SetVDCReg		jsr	oSetVDC			;Copyregister setzen
			inx				;in X wird Register
			tya				;in A wird Highbyte
			jmp	oSetVDC			;in Y wird Lowbyte übergeben

:SetCopyBit		;Copybit 7 in Reg. 24 setzen
			ldx	#24
			jsr	oGetVDC
			ora	#%10000000
			jmp	oSetVDC

:ClearCopyBit		ldx	#24
			jsr	oGetVDC
			and	#%01111111
			jmp	oSetVDC

:SetLine		ldx	#31			;Data-Register
			jsr	oSetVDC
			dex				;WordCount-Register
			lda	#79
			jmp	oSetVDC

:_SaveScrCol		ldx	#1			;Save-Kennzeichen
			b	$2c
:_LoadScrCol		ldx	#0			;Load-Kennzeichen
			stx	:Flag+1

			php
			sei
			LoadW	r0,$a000
			LoadW	r1,8000
			ldx	#18
			lda	#$40
			jsr	oSetVDC
			lda	#$00
			inx
			jsr	oSetVDC
			ldy	#0
			ldx	#31			;Data-Register

::Flag			lda	#0
			bne	:save

::load			lda	(r0),y
			jsr	oSetVDC
			inc	r0L			;Zeiger auf Ablagespeicher erhöhen
			bne	:1
			inc	r0H
::1			lda	r1L
			sec
			sbc	#1
			sta	r1L
			bcs	:load
			lda	r1H
			sec
			sbc	#1
			sta	r1H
			bcs	:load
			bcc	:EndLoadSave

::save			jsr	oGetVDC			;Byte von VDC holen
			sta	(r0),y			;und speichern
			inc	r0L			;Zeiger auf Ablagespeicher erhöhen
			bne	:2
			inc	r0H
::2			lda	r1L
			sec
			sbc	#1
			sta	r1L
			bcs	:save
			lda	r1H
			sec
			sbc	#1
			sta	r1H
			bcs	:save

::EndLoadSave		plp
			rts

;Dialogboxhintergrund sichern/wiederherstellen
:_LdSvVDCScreen		pha

			ldy	#5
::11			lda	r2L,y
			sta	DlgRegBuf,y
			dey
			bpl	:11

			jsr	SetScr80Adr		;FarbScreenPointer setzen
			lda	vdcClrMode
			cmp	#3
			bcc	:m1
			beq	:m2
			inc	r2H			;Höhe für Schatten vergrößern
			inc	r2H
::m2			inc	r2H
::m1			pla
			pha
			jsr	:1

			ldy	#5
::12			lda	DlgRegBuf,y
			sta	r2L,y
			dey
			bpl	:12

			sec
			lda	r2H			;Y-unten von Y-oben
			sbc	r2L			;abziehen - ergibt Höhe
			clc
			adc	#8			;+ 8 für Schatten
			sta	r2H			;in r2H ist Höhe
			inc	r2L			;in r2L ist Y-Anfang
			;anpassen für Zähler
			jsr	SETr5L_r4L		;r5L = X-Byte Anfang
			;r4L = Breite

			LoadB	r5H,$00			;Highbyte von VDC-Adresse
::4			dec	r2L			;Y-Anfang
			beq	:3			;aufaddieren bis Anfangszeile
			jsr	Add80r5			;r5 =r5 + 80
			jmp	:4
::3			pla
			jsr	:1
			jmp	ClearCopyBit

::1			inc	r2H			;anpassen für Zähler
			inc	r4L			;anpassen für Zähler
			inc	r4L			;für Schatten
			inc	r4L			;für Schatten
			tax
			beq	:Save

::2			lda	r5H			;Copy von r5 + $6000
			clc
			adc	#$60
			ldy	r5L
			ldx	#32
			jsr	SetVDCReg
			lda	r5H			;nach r5
			ldy	r5L
			ldx	#18
			jsr	SetVDCReg
			lda	r4L			;Anzahl Bytes kopieren
			ldx	#30			;WordCount-Register
			jsr	oSetVDC
			jsr	Add80r5			;r5 =r5 + 80
			dec	r2H			;nächste Zeile
			bne	:2
			jmp	LOADr2r6

::Save			lda	r5H			;Copy von r5
			ldy	r5L
			ldx	#32
			jsr	SetVDCReg
			lda	r5H			;nach r5 + $6000
			clc
			adc	#$60
			ldy	r5L
			ldx	#18
			jsr	SetVDCReg
			lda	r4L			;Anzahl Bytes kopieren
			ldx	#30			;WordCount-Register
			jsr	oSetVDC
			jsr	Add80r5			;r5 =r5 + 80
			dec	r2H			;nächste Zeile
			bne	:Save
			jmp	LOADr2r6

:Add80r5		lda	r5L			;ereicht ist
			clc
			adc	#80
			sta	r5L
			bcc	:1
			inc	r5H
::1			rts

:_GetBackScreenVDC	lda	#$00			;r11 = $0000
			sta	r11L
			sta	r11H
			sta	r12L			;r12 = $4000
			LoadB	r12H,$40

			LoadW	r14,SCREEN_BASE
			LoadW	r15,COLOR_MATRIX

			LoadB	r1L,25
::1			lda	r14H
			pha
			lda	r14L
			pha
			jsr	MoveGrfx80
			jsr	MoveCols80
			pla				;r14L vom Stack holen
			adc	#<320			;r14L = r14L + <320
			sta	r14L
			pla				;r14H vom Stack holen
			adc	#>320			;r14H = r14H + >320
			sta	r14H			;-> r14 = r14 + 320
			lda	r15L			;r15 = r15 + 40
			clc
			adc	#40
			sta	r15L
			bcc	:2
			inc	r15H
::2			dec	r1L
			bne	:1
			rts

:MoveGrfx80		ldx	#18
			lda	r11H
			jsr	oSetVDC
			lda	r11L
			inx
			jsr	oSetVDC

			LoadB	r13H,8
::2			PushW	r14
			LoadB	r13L,40
			ldy	#0
::1			lda	(r14),y

			pha				;in X-Richtung
			lsr				;jedes Pixel verdoppeln
			lsr
			lsr
			lsr
			tax
			lda	VerdoppelTab,x
			ldx	#31
			jsr	oSetVDC

			pla
			and	#$0f
			tax
			lda	VerdoppelTab,x
			ldx	#31
			jsr	oSetVDC

			AddVW	8,r14
			dec	r13L
			bne	:1
			PopW	r14
			inc	r14L
			bne	:14
			inc	r14H
::14			dec	r13H
			bne	:2
			AddVW	640,r11
			rts

:MoveCols80		ldy	vdcClrMode
			cpy	#4
			beq	:1a
			dey
::1a			sty	r0L

			ldx	#18
			lda	r12H
			jsr	oSetVDC
			lda	r12L
			inx
			jsr	oSetVDC

::2			ldy	#0
::1			lda	(r15),y
			pha
			and	#%00001111
			tax
			lda	VDCFarbtab,x
			sta	:xx+1
			pla
			lsr
			lsr
			lsr
			lsr
			tax
			lda	VDCFarbtab,x
			asl
			asl
			asl
			asl
::xx			ora	#$00
			ldx	#31
			jsr	oSetVDC
			jsr	oSetVDC
			iny
			cpy	#40
			bne	:1
			AddVW	80,r12
			dec	r0L
			bne	:2
			rts

;MP3-Farbtabelle an VIC/VDC anpassen
;In Abhängigkeit von graphMode wird die entsprechende Farbtabelle
;nach C_FarbTab kopiert
:_Set_C_FarbTab		ldy	#FarbAnzahl-1
::1			lda	C_FarbTab,y
			ldx	_C_FarbTab_VDC,y
			sta	_C_FarbTab_VDC,y
			txa
			sta	C_FarbTab,y
			dey
			bpl	:1
			rts

:VDCFarbtab		b	0			;schwarz (0)
			b	15			;weiß (1)
			b	8			;rot (2)
			b	7			;türkis (3)
			b	11			;violett (4)
			b	4			;grün (5)
			b	2			;blau (6)
			b	13			;gelb (7)
			b	10			;orange (8)
			b	12			;braun (9)
			b	9			;hellrot (10)
			b	1			;grau 1 dunkelgrau (11)
			b	6			;grau 2 mittelgrau (12)
			b	5			;hellgrün (13)
			b	3			;hellblau (14)
			b	14			;grau 3 hellgrau (15)

:_SpritesSpool80	php
			jsr	_TempHideMouse
			jsr	SetCopyBit
			LoadB	r2L,24			;24 Zeilen kopieren
			plp
			bcc	:10
			jmp	GetSprSpool		;Hintergrund wiederherstellen

::10			LoadW	r0,(168*80)+73		;Grafikdaten kopieren
			LoadW	r1,16000
			jsr	:1

			jsr	InitColSpool
			jsr	:1

			jmp	ClearCopyBit

::1			lda	r0H			;Copy von Zeile 168 bis Zeile 191
			ldy	r0L			;Spalte 73 bis 78
			ldx	#32
			jsr	SetVDCReg
			lda	r1H			;nach 16000 im VDC
			ldy	r1L
			ldx	#18
			jsr	SetVDCReg
			lda	#6			;6 Bytes kopieren
			ldx	#30			;WordCount-Register
			jsr	oSetVDC
			AddVW	80,r0
			AddVW	6,r1
			dec	r2L
			bne	:1
			rts

:GetSprSpool		LoadW	r0,(168*80)+73
			LoadW	r1,16000
			jsr	:1

			jsr	InitColSpool
			jsr	:1

			jmp	ClearCopyBit

::1			lda	r1H			;Copy von 16000 im VDC
			ldy	r1L
			ldx	#32
			jsr	SetVDCReg
			lda	r0H			;nach Zeile 168 bis Zeile 191
			ldy	r0L			;Spalte 73 bis 78
			ldx	#18
			jsr	SetVDCReg
			lda	#6			;6 Bytes kopieren
			ldx	#30			;WordCount-Register
			jsr	oSetVDC
			AddVW	80,r0
			AddVW	6,r1
			dec	r2L
			bne	:1
			rts

:InitColSpool		LoadB	r2L,3			;24 Zeilen kopieren
			LoadW	r0,$4000+(21*80)+73	;Grafikdaten kopieren
			ldy	vdcClrMode
			dey
			dey
			beq	:2
			AddVW	(21*80),r0
			asl	r2L
			dey
			beq	:2
			AddVW	(21*80)*2,r0
			asl	r2L
::2			rts

;Bildschirm für Druckerspooler sichern/wiederherstellen
;in REU von $0400 bis $8000
:LdSvSpoolScrn		sta	:flag+1
			php
			sei
			jsr	_TempHideMouse
			jsr	:swap
			lda	:flag+1
			beq	:save2
			lda	scr80colors
			jsr	ClearColScr80

::save2			LoadW	r0,$1000
			ldx	#18			;Startadresse VDC setzen
			lda	#$00
			jsr	oSetVDC
			lda	#$00
			inx
			jsr	oSetVDC
			ldy	#0
			ldx	#31			;Data-Register

::flag			lda	#$00
			bne	:load

::save			jsr	oGetVDC			;Byte von VDC holen
			sta	(r0),y			;und speichern
			inc	r0L			;Zeiger auf Ablagespeicher erhöhen
			bne	:save
			inc	r0H
			lda	r0H
			cmp	#$70			;alle Bytes gesichert?
			bne	:save			;>nein dann weiter...
			jsr	:swap
			plp
			rts

::load			lda	(r0),y
			jsr	oSetVDC
			inc	r0L			;Zeiger auf Ablagespeicher erhöhen
			bne	:load
			inc	r0H
			lda	r0H
			cmp	#$70			;alle Bytes geladen?
			bne	:load			;>nein dann weiter...
			jsr	:swap
			plp
			rts

::swap			lda	#$00			;r0 = $1000
			sta	r0L
			sta	r1L			;r1 = $1000
			lda	#$10
			sta	r0H
			sta	r1H
			LoadW	r2,$6000
			ldy	MP3_64K_DATA
			sty	r3L
			jmp	BASE_RAM_DRV+6		;Direkteinsprung xSwapRAM

;******************************************************************************
;*** Speicher bis $FC00 mit $00-Bytes auffüllen.
;******************************************************************************
:_31T			e $fc00
:_31
;******************************************************************************

:DoBOpBuffer		s	$0100

:_MoveBData		ldy	#$00
			beq	_DoBOp
:_SwapBData		ldy	#$02
			bne	_DoBOp
:_VerifyBData		ldy	#$03
			bne	_DoBOp
:_DoBOp			lda	RAM_Conf_Reg		;Konfiguration sichern
			pha
			and	#$f0
			ora	#$08			;1 kb Common Area oben
			sta	RAM_Conf_Reg		; = $fc00 bis $ffff
			PushB	MMU			; MMU sichern

			ldx	#7			;r0 bis r3 sichern
::1			lda	r0L,x
			pha
			dex
			bpl	:1

			lda	r3L			;Start-Bank
			ror
			ror
			ror
			and	#$c0
			ora	#$3f			;nach MMU umrechnen
			sta	r3L			;und sichern
			sta	MMU			;und setzen

			lda	r3H			;Ziel-Bank
			ror
			ror
			ror
			and	#$c0
			ora	#$3f			;nach MMU umrechnen
			sta	r3H			;und sichern

			tya				;welcher Verschiebe-Modus?
			beq	Move			;>verschieben
			cmp	#$02			;welcher Verschiebe-Modus?
			bne	:2
			jmp	Swap			;>tauschen
::2			cmp	#$03
			bne	:3
			jmp	Verify			;>vergleichen

::3			ldx	r0H			;r0 und r1 tauschen
			lda	r1H			;r3L und r3H tauschen
			stx	r1H
			sta	r0H
			ldx	r0L
			lda	r1L
			stx	r1L
			sta	r0L
			ldx	r3L
			lda	r3H
			stx	r3H
			sta	r3L

;Verschieben von zwei Speicherbänken
:Move			ldy	r2L			;Anzahl Low-Byte testen
			beq	:4			;>ist 0

::1			dey				;Anzahl LowByte
			lda	(r0L),y			;von Startbereich
			sta	DoBOpBuffer,y		;in Buffer
			tya
			bne	:1

			MoveB	r3H,MMU			;Ziel-Bank setzen

			ldy	r2L			;Anzahl LowByte
::2			dey
			lda	DoBOpBuffer,y		;von Buffer
			sta	(r1L),y			;nach Zielbereich
			tya
			bne	:2

			lda	r2L			;r0 = r0 + r2L
			clc
			adc	r0L
			sta	r0L
			bcc	:3
			inc	r0H
::3			lda	r2L			;r1 = r1 + r2L
			clc
			adc	r1L
			sta	r1L
			bcc	:4
			inc	r1H

::4			lda	r2H			;Anzahl Highbyte testen
			bne	:5
			jmp	EndDoBOp		;>fertig

::5			ldy	#$00
			MoveB	r3L,MMU			;Startbank setzen

::6			lda	(r0L),y			;256 Byte vom Startbereich
			sta	DoBOpBuffer,y		;in Buffer
			iny
			bne	:6

			MoveB	r3H,MMU			;Zielbank setzen

::7			lda	DoBOpBuffer,y		;256 Byte vom Buffer
			sta	(r1L),y			;nach Zielbereich
			iny
			bne	:7

			inc	r0H			;r0 = r0 + 256
			inc	r1H			;r1 = r1 + 256
			dec	r2H
			jmp	:4

;Austauschen von zwei Speicherbänken
:Swap			ldy	r2L
			beq	lfe23

:lfddd			dey
			lda	(r0L),y
			sta	DoBOpBuffer,y
			tya
			bne	lfddd
			lda	r3H
			sta	MMU
			ldy	r2L
:lfded			dey
			lda	DoBOpBuffer,y
			tax
			lda	(r1L),y
			sta	DoBOpBuffer,y
			txa
			sta	(r1L),y
			tya
			bne	lfded
			lda	r3L
			sta	MMU
			ldy	r2L
:lfe04			dey
			lda	DoBOpBuffer,y
			sta	(r0L),y
			tya
			bne	lfe04
			lda	r2L
			clc
			adc	r0L
			sta	r0L
			bcc	lfe18
			inc	r0H
:lfe18			lda	r2L
			clc
			adc	r1L
			sta	r1L
			bcc	lfe23
			inc	r1H
:lfe23			lda	r2H
			beq	lfe60
			ldy	#$00
			lda	r3L
			sta	MMU
:lfe2e			lda	(r0L),y
			sta	DoBOpBuffer,y
			iny
			bne	lfe2e
			lda	r3H
			sta	MMU
:lfe3b			lda	DoBOpBuffer,y
			tax
			lda	(r1L),y
			sta	DoBOpBuffer,y
			txa
			sta	(r1L),y
			iny
			bne	lfe3b
			lda	r3L
			sta	MMU
:lfe4f			lda	DoBOpBuffer,y
			sta	(r0L),y
			iny
			bne	lfe4f
			inc	r0H
			inc	r1H
			dec	r2H
			jmp	lfe23

:lfe60			jmp	EndDoBOp

;Vergleichen von zwei Speicherbänken
:Verify			ldy	r2L
			beq	lfe98
:lfe67			dey
			lda	(r0L),y
			sta	DoBOpBuffer,y
			tya
			bne	lfe67
			lda	r3H
			sta	MMU
			ldy	r2L
:lfe77			dey
			lda	DoBOpBuffer,y
			cmp	(r1L),y
			bne	lfec3
			tya
			bne	lfe77
			lda	r2L
			clc
			adc	r0L
			sta	r0L
			bcc	lfe8d
			inc	r0H
:lfe8d			lda	r2L
			clc
			adc	r1L
			sta	r1L
			bcc	lfe98
			inc	r1H
:lfe98			lda	r2H
			beq	lfec3
			ldy	#$00
			lda	r3L
			sta	MMU
:lfea3			lda	(r0L),y
			sta	DoBOpBuffer,y
			iny
			bne	lfea3
			lda	r3H
			sta	MMU
:lfeb0			lda	DoBOpBuffer,y
			cmp	(r1L),y
			bne	lfec3
			iny
			bne	lfeb0
			inc	r0H
			inc	r1H
			dec	r2H
			jmp	lfe98

:lfec3			beq	lfec9

			ldx	#$ff			;TRUE setzen
			bne	EndDoBOp

:lfec9			ldx	#$00			;FALSE setzen

:EndDoBOp		ldy	#0
::1			pla
			sta	r0L,y
			iny
			cpy	#8
			bne	:1

			PopB	MMU
			PopB	RAM_Conf_Reg
			txa
			rts

.DlgRegBuf		s	6

;******************************************************************************
;*** Speicher bis $FF00 mit $00-Bytes auffüllen.
;******************************************************************************
:_32T			e $ff00
:_32
;******************************************************************************
			s	5			;MMU-Register!

;Bereich Bank 0 $ff05 bis $ffff

:oGEOS_IRQ		cld
			pha
			lda	MMU
			pha
			lda	#$7e
			sta	MMU
			lda	RAM_Conf_Reg
			pha
			and	#$f0
			sta	RAM_Conf_Reg
			nop
			nop
			nop
			pla
			sta	RAM_Conf_Reg
			pla
			sta	MMU
			pla
:oIRQ_END		rti

:oNormalizeX		lda	zpage +1,x
			bpl	lff3d
			rol
			bmi	lff4f
			ror
			bit	graphMode
			bpl	lff38
			clc
			adc	#$60
			rol	zpage +0,x
			rol
:lff38			and	#$1f
			sta	zpage +1,x
			rts
:lff3d			rol
			bpl	lff4f
			ror
			bit	graphMode
			bpl	lff4b
			sec
			adc	#$a0
			rol	zpage +0,x
			rol
:lff4b			ora	#$e0
			sta	zpage +1,x
:lff4f			rts

:InvertZpWord		lda	zpage +1,x
			bmi	lf5da
			rts
:lf5da			lda	zpage +1,x
			eor	#$ff
			sta	zpage +1,x
			lda	zpage +0,x
			eor	#$ff
			sta	zpage +0,x
			inc	zpage +0,x
			bne	lf5ec
			inc	zpage +1,x
:lf5ec			rts

:RotateLeftZpWord	dey
			bmi	lf5f7
			asl	zpage +0,x
			rol	zpage +1,x
			jmp	RotateLeftZpWord
:lf5f7			rts

;BAM-Buffer Routine für GEOS V2.0 Laufwerkstreiber
;Benutzt Speicherbereich von $ac00 bis $c000 in Bank 0
:_DoBAMBuf		ldx	#8
::1			lda	zpage +1,x		;r0 bis r3 sichern
			sta	ZeroBuf,x
			dex
			bne	:1

			tya
			cmp	#$ff
			beq	lf79a
			pha
			lda	#$ac			;r1 = r1 + $ac00
			clc
			adc	r1H
			sta	r1H
			ldy	#$00
			sty	r1L			;r1L = $00
			sty	r2L			;r2  = $0100
			sty	r3H			;r3L = 1
			iny				;r3H = 0
			sty	r2H
			sty	r3L
			MoveW	r4,r0
			pla
			tay
			jsr	_DoBOp
			tay
			jsr	lf7bf
			tya
			rts

:lf79a			PushB	MMU
			LoadB	MMU,$3f			;nur Bank 0
			LoadW	r1,$ac00
::1			lda	#$00
			tay
			sta	(r1L),y
			iny
			sta	(r1L),y
			inc	r1H
			lda	r1H
			cmp	#$c0
			bcc	:1
			PopB	MMU

:lf7bf			ldx	#8
::1			lda	ZeroBuf,x
			sta	zpage +1,x
			dex
			bne	:1
			rts

:ZeroBuf		s	8

;******************************************************************************
;*** Speicher bis $FFFA mit $00-Bytes auffüllen.
;******************************************************************************
:_33T			e $fffa
:_33
;******************************************************************************

			w	IRQ_END
			w	IRQ_END
			w	oGEOS_IRQ
