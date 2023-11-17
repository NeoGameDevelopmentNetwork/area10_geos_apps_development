; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

$E07D			A52E	lda currentMode			;ChkBaseItalic
$E07F			1013	bpl $E094

$E081			A405	ldy r1H
$E083			CCFE87	cpy BaseUnderLine
$E086			F006	beq $E08E
$E088			88	dey
$E089			CCFE87	cpy BaseUnderLine
$E08C			D006	bne $E094

$E08E			A516	lda r10L
$E090			49FF	eor #%11111111
$E092			8516	sta r10L

$E094			A52E	lda currentMode
$E096			2910	and #%00010000
$E098			F0C1	beq $E05B

$E09A			A517	lda r10H
$E09C			4A	lsr
$E09D			B018	bcs $E0B7

$E09F			AE9BE3	ldx StrBitXposL
$E0A2			D003	bne $E0A7
$E0A4			CE9CE3	dec StrBitXposH
$E0A7			CA	dex
$E0A8			8E9BE3	stx StrBitXposL

$E0AB			A618	ldx r11L
$E0AD			D002	bne $E0B1
$E0AF			C619	dec r11H
$E0B1			CA	dex
$E0B2			8618	stx r11L

$E0B4			2080DF	jsr StreamInfo

$E0B7			A538	lda rightMargin+1
$E0B9			CD9CE3	cmp StrBitXposH
$E0BC			D005	bne $E0C3
$E0BE			A537	lda rightMargin
$E0C0			CD9BE3	cmp StrBitXposL
$E0C3			900B	bcc $E0D0

$E0C5			A536	lda leftMargin+1
$E0C7			C519	cmp r11H
$E0C9			D004	bne $E0CF
$E0CB			A535	lda leftMargin
$E0CD			C518	cmp r11L
$E0CF			60	rts
$E0D0			38	sec
$E0D1			60	rts

$E0D2			A404	ldy r1L			;WriteNewStream

$E0D4			AE9AE3	ldx CurStreamCard
$E0D7			B545	lda SetStream,x
$E0D9			E412	cpx r8L
$E0DB			F03C	beq $E119
$E0DD			B055	bcs $E134

$E0DF			4516	eor r10L
$E0E1			2514	and r9L
$E0E3			8DEBE0	sta $E0EB
$E0E6			A508	lda r3L
$E0E8			310E	and (r6L),y
$E0EA			0900	ora #%00000000
$E0EC			910E	sta (r6L),y
$E0EE			910C	sta (r5L),y

$E0F0			98	tya
$E0F1			18	clc
$E0F2			6908	adc #$08
$E0F4			A8	tay
$E0F5			E8	inx
$E0F6			E412	cpx r8L
$E0F8			F00B	beq $E105

$E0FA			B545	lda SetStream,x
$E0FC			4516	eor r10L
$E0FE			910E	sta (r6L),y
$E100			910C	sta (r5L),y
$E102			B8	clv
$E103			50EB	bvc $E0F0

$E105			B545	lda SetStream,x
$E107			4516	eor r10L
$E109			2515	and r9H
$E10B			8D13E1	sta $E113
$E10E			A50B	lda r4H
$E110			310E	and (r6L),y
$E112			0900	ora #%00000000
$E114			910E	sta (r6L),y
$E116			910C	sta (r5L),y
$E118			60	rts

$E119			4516	eor r10L
$E11B			2515	and r9H
$E11D			49FF	eor #%11111111
$E11F			0508	ora r3L
$E121			050B	ora r4H
$E123			49FF	eor #%11111111
$E125			8D2FE1	sta $E12F
$E128			A508	lda r3L
$E12A			050B	ora r4H
$E12C			310E	and (r6L),y
$E12E			0900	ora #%00000000
$E130			910E	sta (r6L),y
$E132			910C	sta (r5L),y
$E134			60	rts

$E135			A612	ldx r8L			;InitNewStream
$E137			A900	lda #$00
$E139			9DFF87	sta NewStream,x
$E13C			CA	dex
$E13D			10FA	bpl $E139

$E13F			A513	lda r8H
$E141			297F	and #%01111111
$E143			D010	bne $E155

$E145			20B9E1	jsr DefBitOutBold

$E148			A612	ldx r8L
$E14A			BDFF87	lda NewStream,x
$E14D			9545	sta NewStream,x
$E14F			CA	dex
$E150			10F8	bpl $E14A
$E152			E613	inc r8H
$E154			60	rts

$E155			C901	cmp #$01
$E157			F010	beq $E169
$E159			A417	ldy r10H
$E15B			88	dey
$E15C			F0E7	beq $E145

$E15E			88	dey
$E15F			08	php
$E160			20B9E1	jsr DefBitOutBold
$E163			208BE1	jsr AddFontWidth
$E166			28	plp
$E167			F016	beq $E17F

$E169			208BE1	jsr AddFontWidth
$E16C			2031E3	jsr CopyCharData
$E16F			20B9E1	jsr DefBitOutBold
$E172			A506	lda r2L
$E174			38	sec
$E175			E527	sbc curSetWidth
$E177			8506	sta r2L
$E179			A507	lda r2H
$E17B			E528	sbc curSetWidth+1
$E17D			8507	sta r2H
$E17F			2031E3	jsr CopyCharData
$E182			20B9E1	jsr DefBitOutBold
$E185			2099E1	jsr DefOutLine
$E188			B8	clv
$E189			50BD	bvc $E148

$E18B			A527	lda curSetWidth			;AddFontWidth
$E18D			18	clc
$E18E			6506	adc r2L
$E190			8506	sta r2L
$E192			A528	lda curSetWidth+1
$E194			6507	adc r2H
$E196			8507	sta r2H
$E198			60	rts

$E199			A0FF	ldy #$FF			;DefOutLine
$E19B			C8	iny
$E19C			A207	ldx #$07
$E19E			B94500	lda SetStream,y
$E1A1			3DEDC2	and BitData2 ,x
$E1A4			F00B	beq $E1B1
$E1A6			BDEDC2	lda BitData2 ,x
$E1A9			49FF	eor #%11111111
$E1AB			39FF87	and NewStream,y
$E1AE			99FF87	sta NewStream,y
$E1B1			CA	dex
$E1B2			10EA	bpl $E19E
$E1B4			C412	cpy r8L
$E1B6			D0E3	bne $E19B
$E1B8			60	rts

$E1B9			200AE2	jsr MovBitStrData			;DefBitOutBold

$E1BC			A0FF	ldy #$FF
$E1BE			C8	iny

$E1BF			A207	ldx #$07
$E1C1			B94500	lda SetStream,y
$E1C4			3DEDC2	and BitData2,x
$E1C7			F039	beq $E202

$E1C9			B9FF87	lda NewStream,y
$E1CC			1DEDC2	ora BitData2,x
$E1CF			99FF87	sta NewStream,y

$E1D2			E8	inx
$E1D3			E008	cpx #$08
$E1D5			D00A	bne $E1E1

$E1D7			B9FE87	lda BaseUnderLine,y
$E1DA			0901	ora #%00000001
$E1DC			99FE87	sta BaseUnderLine,y
$E1DF			D009	bne $E1EA

$E1E1			B9FF87	lda NewStream    ,y
$E1E4			1DEDC2	ora BitData2     ,x
$E1E7			99FF87	sta NewStream    ,y

$E1EA			CA	dex
$E1EB			CA	dex
$E1EC			100A	bpl $E1F8

$E1EE			B90088	lda NewStream +1 ,y
$E1F1			0980	ora #%10000000
$E1F3			990088	sta NewStream +1 ,y
$E1F6			D009	bne $E201

$E1F8			B9FF87	lda NewStream    ,y
$E1FB			1DEDC2	ora BitData2     ,x
$E1FE			99FF87	sta NewStream    ,y

$E201			E8	inx
$E202			CA	dex
$E203			10BC	bpl $E1C1
$E205			C412	cpy r8L
$E207			D0B5	bne $E1BE
$E209			60	rts

$E20A			4645	lsr SetStream +0			;MovBitStrData
$E20C			6646	ror SetStream +1
$E20E			6647	ror SetStream +2
$E210			6648	ror SetStream +3
$E212			6649	ror SetStream +4
$E214			664A	ror SetStream +5
$E216			664B	ror SetStream +6
$E218			664C	ror SetStream +7
$E21A			60	rts

$E21B			EA	nop 			;PrntCharCode
$E21C			A8	tay

$E21D			A505	lda r1H
$E21F			48	pha

$E220			98	tya
$E221			206DDE	jsr DefCharData
$E224			B052	bcs $E278

$E226			18	clc
$E227			A52E	lda currentMode
$E229			2990	and #%10010000
$E22B			F003	beq $E230
$E22D			207DE0	jsr ChkBaseItalic

$E230			08	php
$E231			B003	bcs $E236
$E233			2031E3	jsr CopyCharData

$E236			2413	bit r8H
$E238			1006	bpl $E240
$E23A			2035E1	jsr InitNewStream
$E23D			B8	clv
$E23E			5003	bvc $E243

$E240			208BE1	jsr AddFontWidth

$E243			28	plp
$E244			B00F	bcs $E255

$E246			A505	lda r1H
$E248			C533	cmp windowTop
$E24A			9009	bcc $E255
$E24C			C534	cmp windowBottom
$E24E			9002	bcc $E252
$E250			D003	bne $E255
$E252			20D2E0	jsr WriteNewStream

$E255			E60C	inc r5L
$E257			E60E	inc r6L
$E259			A50C	lda r5L
$E25B			2907	and #%00000111
$E25D			D013	bne $E272
$E25F			E60D	inc r5H
$E261			E60F	inc r6H
$E263			A50C	lda r5L
$E265			18	clc
$E266			6938	adc #$38
$E268			850C	sta r5L
$E26A			850E	sta r6L
$E26C			9004	bcc $E272
$E26E			E60D	inc r5H
$E270			E60F	inc r6H

$E272			E605	inc r1H
$E274			C617	dec r10H
$E276			D0AE	bne $E226
$E278			68	pla
$E279			8505	sta r1H
$E27B			60	rts

$E27C			4A	lsr
$E27D			4A	lsr
$E27E			4A	lsr
$E27F			4A	lsr
$E280			4A	lsr
$E281			4A	lsr
$E282			4A	lsr
$E283			4C10E3	jmp DefBitStream2

$E286			4A	lsr
$E287			6646	ror SetStream+1
$E289			6647	ror SetStream+2
$E28B			4A	lsr
$E28C			6646	ror SetStream+1
$E28E			6647	ror SetStream+2
$E290			4A	lsr
$E291			6646	ror SetStream+1
$E293			6647	ror SetStream+2
$E295			4A	lsr
$E296			6646	ror SetStream+1
$E298			6647	ror SetStream+2
$E29A			4A	lsr
$E29B			6646	ror SetStream+1
$E29D			6647	ror SetStream+2
$E29F			4A	lsr
$E2A0			6646	ror SetStream+1
$E2A2			6647	ror SetStream+2
$E2A4			4A	lsr
$E2A5			6646	ror SetStream+1
$E2A7			6647	ror SetStream+2
$E2A9			4C10E3	jmp DefBitStream2

$E2AC			0A	asl
$E2AD			0A	asl
$E2AE			0A	asl
$E2AF			0A	asl
$E2B0			0A	asl
$E2B1			0A	asl
$E2B2			0A	asl
$E2B3			4C10E3	jmp DefBitStream2

$E2B6			0647	asl SetStream+2
$E2B8			2646	rol SetStream+1
$E2BA			2A	rol
$E2BB			0647	asl SetStream+2
$E2BD			2646	rol SetStream+1
$E2BF			2A	rol
$E2C0			0647	asl SetStream+2
$E2C2			2646	rol SetStream+1
$E2C4			2A	rol
$E2C5			0647	asl SetStream+2
$E2C7			2646	rol SetStream+1
$E2C9			2A	rol
$E2CA			0647	asl SetStream+2
$E2CC			2646	rol SetStream+1
$E2CE			2A	rol
$E2CF			0647	asl SetStream+2
$E2D1			2646	rol SetStream+1
$E2D3			2A	rol
$E2D4			0647	asl SetStream+2
$E2D6			2646	rol SetStream+1
$E2D8			2A	rol
$E2D9			4C10E3	jmp DefBitStream2

$E2DC			8545	sta SetStream			;PrepBitSTream

$E2DE			A510	lda r7L
$E2E0			38	sec
$E2E1			EDFD87	sbc BitStr1stBit
$E2E4			F009	beq $E2EF
$E2E6			900C	bcc DefBitStream

$E2E8			A8	tay
$E2E9			200AE2	jsr MovBitStrData

$E2EC			88	dey
$E2ED			D0FA	bne $E2E9

$E2EF			A545	lda SetStream
$E2F1			4C10E3	jmp DefBitStream2

$E2F4			ADFD87	lda BitStr1stBit			;DefBitStream
$E2F7			38	sec
$E2F8			E510	sbc r7L
$E2FA			A8	tay

$E2FB			064C	asl SetStream+7
$E2FD			264B	rol SetStream+6
$E2FF			264A	rol SetStream+5
$E301			2649	rol SetStream+4
$E303			2648	rol SetStream+3
$E305			2647	rol SetStream+2
$E307			2646	rol SetStream+1
$E309			2645	rol SetStream+0
$E30B			88	dey
$E30C			D0ED	bne $E2FB

$E30E			A545	lda SetStream

$E310			8545	sta SetStream			;DefBitStream2

$E312			242E	bit currentMode
$E314			501A	bvc $E330

$E316			A900	lda #$00
$E318			48	pha

$E319			A0FF	ldy #$FF
$E31B			C8	iny
$E31C			B645	ldx SetStream,y
$E31E			68	pla
$E31F			1D10D1	ora BoldData,x
$E322			994500	sta SetStream,y
$E325			8A	txa
$E326			4A	lsr
$E327			A900	lda #$00
$E329			6A	ror
$E32A			48	pha
$E32B			C412	cpy r8L
$E32D			D0EC	bne $E31B

$E32F			68	pla
$E330			60	rts

$E331			A000	ldy #$00			;CopyCharData
$E333			6C1C00	jmp (r13)

$E336			8446	sty SetStream+1			;Char24Bit
$E338			8447	sty SetStream+2
$E33A			B106	lda (r2L),y
$E33C			2DFC87	and BitStrDataMask
$E33F			2511	and r7H
$E341			6C1A00	jmp (r12)

$E344			8447	sty SetStream+2			;Char32Bit
$E346			8448	sty SetStream+3
$E348			B106	lda (r2L),y
$E34A			2DFC87	and BitStrDataMask
$E34D			8545	sta SetStream
$E34F			C8	iny
$E350			B106	lda (r2L),y
$E352			2511	and r7H
$E354			8546	sta SetStream+1
$E356			A545	lda SetStream+0
$E358			6C1A00	jmp (r12)

$E35B			8448	sty SetStream+3			;Char40Bit
$E35D			8449	sty SetStream+4
$E35F			B106	lda (r2L),y
$E361			2DFC87	and BitStrDataMask
$E364			8545	sta SetStream+0
$E366			C8	iny
$E367			B106	lda (r2L),y
$E369			8546	sta SetStream+1
$E36B			C8	iny
$E36C			B106	lda (r2L),y
$E36E			2511	and r7H
$E370			8547	sta SetStream+2
$E372			B8	clv
$E373			50E1	bvc $E356

$E375			B106	lda (r2L),y			;Char48Bit
$E377			2DFC87	and BitStrDataMask
$E37A			8545	sta SetStream+0
$E37C			C8	iny
$E37D			C409	cpy r3H
$E37F			F008	beq $E389
$E381			B106	lda (r2L),y
$E383			994500	sta SetStream,y
$E386			B8	clv
$E387			50F3	bvc $E37C

$E389			B106	lda (r2L),y
$E38B			2511	and r7H
$E38D			994500	sta SetStream,y
$E390			A900	lda #$00
$E392			994600	sta SetStream+1,y
$E395			994700	sta SetStream+2,y
$E398			F0BC	beq $E356

$E39A			00	b $00			;CurStreamCard
$E39B			34	b $34			;StrBitXposL	
$E39C			01	b $01			;StrBitXposH

$E39D			A9BF	lda #$BF			;DefSprPoi
$E39F			8DF08F	sta $8FF0
$E3A2			A207	ldx #$07
$E3A4			A9BB	lda #$BB
$E3A6			9DE88F	sta $8FE8,x
$E3A9			CA	dex
$E3AA			10FA	bpl $E3A6
$E3AC			60	rts

$E3AD			A2FF	ldx #$FF			;xBitOtherClip
$E3AF			4CB4E3	jmp BitAllClips

$E3B2			A200	ldx #$00			;xBitmapClip
$E3B4			8615	stx r9H			;BitAllClips
$E3B6			A900	lda #$00
$E3B8			8508	sta r3L
$E3BA			850A	sta r4L
$E3BC			A51A	lda r12L
$E3BE			051B	ora r12H
$E3C0			F01A	beq $E3DC
$E3C2			A518	lda r11L
$E3C4			20F0E3	jsr GetNumBytes
$E3C7			A506	lda r2L
$E3C9			20F0E3	jsr GetNumBytes
$E3CC			A519	lda r11H
$E3CE			20F0E3	jsr GetNumBytes
$E3D1			A51A	lda r12L
$E3D3			D002	bne $E3D7
$E3D5			C61B	dec r12H
$E3D7			C61A	dec r12L
$E3D9			B8	clv
$E3DA			50E0	bvc $E3BC

$E3DC			A518	lda r11L
$E3DE			20F0E3	jsr GetNumBytes
$E3E1			2047E4	jsr PrnPixelLine
$E3E4			A519	lda r11H
$E3E6			20F0E3	jsr GetNumBytes
$E3E9			E605	inc r1H
$E3EB			C607	dec r2H
$E3ED			D0ED	bne $E3DC
$E3EF			60	rts

$E3F0			C900	cmp #$00			;GetNumBytes
$E3F2			F00A	beq $E3FE
$E3F4			48	pha
$E3F5			2079E4	jsr GetGrafxByte
$E3F8			68	pla
$E3F9			38	sec
$E3FA			E901	sbc #$01
$E3FC			D0F2	bne GetNumBytes
$E3FE			60	rts

$E3FF			68	pla 			;xi_BitmapUp
$E400			853D	sta returnAddress+0
$E402			68	pla
$E403			853E	sta returnAddress+1

$E405			A001	ldy #$01
$E407			B13D	lda (returnAddress),y
$E409			8502	sta r0L
$E40B			C8	iny
$E40C			B13D	lda (returnAddress),y
$E40E			8503	sta r0H
$E410			C8	iny
$E411			B13D	lda (returnAddress),y
$E413			8504	sta r1L
$E415			C8	iny
$E416			B13D	lda (returnAddress),y
$E418			8505	sta r1H
$E41A			C8	iny
$E41B			B13D	lda (returnAddress),y
$E41D			8506	sta r2L
$E41F			C8	iny
$E420			B13D	lda (returnAddress),y
$E422			8507	sta r2H
$E424			202DE4	jsr xBitmapUp
$E427			08	php
$E428			A907	lda #$07
$E42A			4CA4C2	jmp DoInlineReturn

$E42D			A515	lda r9H			;xBitmapUp
$E42F			48	pha
$E430			A900	lda #$00
$E432			8515	sta r9H
$E434			A900	lda #$00
$E436			8508	sta r3L
$E438			850A	sta r4L
$E43A			2047E4	jsr PrnPixelLine
$E43D			E605	inc r1H
$E43F			C607	dec r2H
$E441			D0F7	bne $E43A
$E443			68	pla
$E444			8515	sta r9H
$E446			60	rts

$E447			A605	ldx r1H			;PrnPixelLine
$E449			207DCA	jsr xGetScanLine

$E44C			A506	lda r2L
$E44E			8509	sta r3H

$E450			A504	lda r1L
$E452			C920	cmp #$20
$E454			9004	bcc $E45A
$E456			E60D	inc r5H
$E458			E60F	inc r6H

$E45A			0A	asl
$E45B			0A	asl
$E45C			0A	asl
$E45D			A8	tay

$E45E			8414	sty r9L
$E460			2079E4	jsr GetGrafxByte
$E463			A414	ldy r9L
$E465			910C	sta (r5L),y
$E467			910E	sta (r6L),y

$E469			98	tya
$E46A			18	clc
$E46B			6908	adc #$08
$E46D			9004	bcc $E473
$E46F			E60D	inc r5H
$E471			E60F	inc r6H
$E473			A8	tay
$E474			C609	dec r3H
$E476			D0E6	bne $E45E
$E478			60	rts

$E479			A508	lda r3L			;GetGrafxByte
$E47B			297F	and #%01111111
$E47D			F00F	beq $E48E
$E47F			2408	bit r3L
$E481			1006	bpl $E489
$E483			20C7E4	jsr GetPackedByte
$E486			C608	dec r3L
$E488			60	rts

$E489			A511	lda r7H
$E48B			C608	dec r3L
$E48D			60	rts

$E48E			A50A	lda r4L
$E490			D007	bne $E499
$E492			2415	bit r9H
$E494			1003	bpl $E499
$E496			20F2E4	jsr GetNextByte

$E499			20C7E4	jsr GetPackedByte
$E49C			8508	sta r3L

$E49E			C9DC	cmp #$DC
$E4A0			9019	bcc $E4BB

$E4A2			E9DC	sbc #$DC
$E4A4			8510	sta r7L
$E4A6			850B	sta r4H
$E4A8			20C7E4	jsr GetPackedByte
$E4AB			38	sec
$E4AC			E901	sbc #$01
$E4AE			850A	sta r4L
$E4B0			A503	lda r0H
$E4B2			8513	sta r8H
$E4B4			A502	lda r0L
$E4B6			8512	sta r8L
$E4B8			B8	clv
$E4B9			50D3	bvc $E48E

$E4BB			C980	cmp #$80
$E4BD			B0BA	bcs GetGrafxByte
$E4BF			20C7E4	jsr GetPackedByte
$E4C2			8511	sta r7H
$E4C4			B8	clv
$E4C5			50B2	bvc GetGrafxByte

$E4C7			2415	bit r9H			;GetPackedByte
$E4C9			1003	bpl $E4CE
$E4CB			20EFE4	jsr GetUsrNxByt

$E4CE			A000	ldy #$00			;GetNxPByte
$E4D0			B102	lda (r0L),y
$E4D2			E602	inc r0L
$E4D4			D002	bne $E4D8
$E4D6			E603	inc r0H

$E4D8			A60A	ldx r4L
$E4DA			F012	beq $E4EE
$E4DC			C60B	dec r4H
$E4DE			D00E	bne $E4EE
$E4E0			A613	ldx r8H
$E4E2			8603	stx r0H
$E4E4			A612	ldx r8L
$E4E6			8602	stx r0L
$E4E8			A610	ldx r7L
$E4EA			860B	stx r4H
$E4EC			C60A	dec r4L
$E4EE			60	rts
$E4EF			6C1C00	jmp (r13)			;GetUsrNxByt
$E4F2			6C1E00	jmp (r14)			;GetNextByte

$E4F5			C920	cmp #$20			;xPutChar
$E4F7			B00A	bcs $E503
$E4F9			A8	tay
$E4FA			B94CE5	lda $E54C,y
$E4FD			BE60E5	ldx $E560,y
$E500			4CD8C1	jmp CallRoutine

$E503			48	pha
$E504			A419	ldy r11H
$E506			841D	sty r13H
$E508			A418	ldy r11L
$E50A			841C	sty r13L
$E50C			A62E	ldx currentMode
$E50E			204BDE	jsr xGetRealSize
$E511			88	dey
$E512			98	tya
$E513			18	clc
$E514			651C	adc r13L
$E516			851C	sta r13L
$E518			9002	bcc $E51C
$E51A			E61D	inc r13H

$E51C			A538	lda rightMargin+1
$E51E			C51D	cmp r13H
$E520			D004	bne $E526
$E522			A537	lda rightMargin
$E524			C51C	cmp r13L
$E526			9022	bcc $E54A

$E528			A536	lda leftMargin+1
$E52A			C519	cmp r11H
$E52C			D004	bne $E532
$E52E			A535	lda leftMargin
$E530			C518	cmp r11L
$E532			F002	beq $E536
$E534			B007	bcs $E53D
$E536			68	pla
$E537			38	sec
$E538			E920	sbc #$20
$E53A			4C1BE2	jmp PrntCharCode

$E53D			A51C	lda r13L
$E53F			18	clc
$E540			6901	adc #$01
$E542			8518	sta r11L
$E544			A51D	lda r13H
$E546			6900	adc #$00
$E548			8519	sta r11H
$E54A			68	pla
$E54B			AEAC84	ldx StringFaultVec+1
$E54E			ADAB84	lda StringFaultVec+0
$E551			4CD8C1	jmp CallRoutine

$E554			2682	b < xBACKSPACE,			< xFORWARDSPACE	;PrintCodeL
$E556			8E96	b < xSetLF,			< xHOME
$E558			9FA7	b < xUPLINE,			< xSetCR
$E55A			B2B9	b < xULINEON,			< xULINEOFF
$E55C			44B2	b < xESC_GRAPHICS,			< xESC_RULER
$E55E			C0C7	b < xREVON,			< xREVOFF
$E560			CEE5	b < xGOTOX,			< xGOTOY
$E562			F2F8	b < xGOTOXY,			< xNEWCARDSET
$E564			040B	b < xBOLDON,			< xITALICON
$E566			1219	b < xOUTLINEON,			< xPLAINTEXT
$E568			E6E5	b > xBACKSPACE,			> xFORWARDSPACE	;PrintCodeH
$E56A			E5E5	b > xSetLF,			> xHOME
$E56C			E5E5	b > xUPLINE,			> xSetCR
$E56E			E5E5	b > xULINEON,			> xULINEOFF
$E570			E6FA	b > xESC_GRAPHICS,			> xESC_RULER
$E572			E5E5	b > xREVON,			> xREVOFF
$E574			E5E5	b > xGOTOX,			> xGOTOY
$E576			E5E5	b > xGOTOXY,			> xNEWCARDSET
$E578			E6E6	b > xBOLDON,			> xITALICON
$E57A			E6E6	b > xOUTLINEON,			> xPLAINTEXT

$E57C			38	sec 			;xSmallPutChar
$E57D			E920	sbc #$20
$E57F			4C1BE2	jmp PrntCharCode

$E582			A900	lda #$00			;xFORMATSPACE
$E584			18	clc
$E585			6518	adc r11L
$E587			8518	sta r11L
$E589			9002	bcc $E58D
$E58B			E619	inc r11H
$E58D			60	rts

$E58E			A505	lda r1H			;xSetLF
$E590			38	sec
$E591			6529	adc curSetHight
$E593			8505	sta r1H
$E595			60	rts

$E596			A900	lda #$00			;xHOME
$E598			8518	sta r11L
$E59A			8519	sta r11H
$E59C			8505	sta r1H
$E59E			60	rts

$E59F			A505	lda r1H			;xUPLINE
$E5A1			38	sec
$E5A2			E529	sbc curSetHight
$E5A4			8505	sta r1H
$E5A6			60	rts

$E5A7			A536	lda leftMargin+1			;xSetCR
$E5A9			8519	sta r11H
$E5AB			A535	lda leftMargin
$E5AD			8518	sta r11L
$E5AF			4C8EE5	jmp xSetLF

$E5B2			A980	lda #%10000000			;xULINEON
$E5B4			052E	ora currentMode
$E5B6			852E	sta currentMode
$E5B8			60	rts

$E5B9			A97F	lda #%01111111			;xULINEOFF
$E5BB			252E	and currentMode
$E5BD			852E	sta currentMode
$E5BF			60	rts

$E5C0			A920	lda #%00100000			;xREVON
$E5C2			052E	ora currentMode
$E5C4			852E	sta currentMode
$E5C6			60	rts

$E5C7			A9DF	lda #%11011111			;xREVOFF
$E5C9			252E	and currentMode
$E5CB			852E	sta currentMode
$E5CD			60	rts

$E5CE			E602	inc r0L			;xGOTOX
$E5D0			D002	bne $E5D4
$E5D2			E603	inc r0H
$E5D4			A000	ldy #$00
$E5D6			B102	lda (r0L),y
$E5D8			8518	sta r11L
$E5DA			E602	inc r0L
$E5DC			D002	bne $E5E0
$E5DE			E603	inc r0H
$E5E0			B102	lda (r0L),y
$E5E2			8519	sta r11H
$E5E4			60	rts

$E5E5			E602	inc r0L			;xGOTOY
$E5E7			D002	bne $E5EB
$E5E9			E603	inc r0H
$E5EB			A000	ldy #$00
$E5ED			B102	lda (r0L),y
$E5EF			8505	sta r1H
$E5F1			60	rts

$E5F2			20CEE5	jsr xGOTOX			;xGOTOXY
$E5F5			4CE5E5	jmp xGOTOY

$E5F8			18	clc 			;xNEWCARDSET
$E5F9			A903	lda #$03
$E5FB			6502	adc r0L
$E5FD			8502	sta r0L
$E5FF			9002	bcc $E603
$E601			E603	inc r0H
$E603			60	rts

$E604			A940	lda #%01000000			;xBOLDON
$E606			052E	ora currentMode
$E608			852E	sta currentMode
$E60A			60	rts

$E60B			A910	lda #%00010000			;xITALICON
$E60D			052E	ora currentMode
$E60F			852E	sta currentMode
$E611			60	rts

$E612			A908	lda #%00001000			;xOUTLINEON
$E614			052E	ora currentMode
$E616			852E	sta currentMode
$E618			60	rts

$E619			A900	lda #%00000000			;xPLAINTEXT
$E61B			852E	sta currentMode
$E61D			60	rts

$E61E			A62E	ldx currentMode			;RemoveChar
$E620			204BDE	jsr xGetRealSize
$E623			8C0788	sty CurCharWidth

$E626			A518	lda r11L			;xBACKSPACE
$E628			38	sec
$E629			ED0788	sbc CurCharWidth
$E62C			8518	sta r11L
$E62E			B002	bcs $E632
$E630			C619	dec r11H
$E632			A519	lda r11H
$E634			48	pha
$E635			A518	lda r11L
$E637			48	pha
$E638			A95F	lda #$5F
$E63A			201BE2	jsr PrntCharCode

$E63D			68	pla
$E63E			8518	sta r11L
$E640			68	pla
$E641			8519	sta r11H
$E643			60	rts

$E644			E602	inc r0L			;xESC_GRAPHICS
$E646			D002	bne $E64A
$E648			E603	inc r0H
$E64A			204DC9	jsr xGraphicsString
$E64D			A202	ldx #r0L
$E64F			2075C1	jsr Ddec
$E652			A202	ldx #r0L
$E654			2075C1	jsr Ddec
$E657			60	rts

$E658			68	pla 			;xi_PutString
$E659			8502	sta r0L
$E65B			68	pla
$E65C			E602	inc r0L
$E65E			D003	bne $E663
$E660			18	clc
$E661			6901	adc #$01
$E663			8503	sta r0H

$E665			A000	ldy #$00
$E667			B102	lda (r0L),y
$E669			E602	inc r0L
$E66B			D002	bne $E66F
$E66D			E603	inc r0H
$E66F			8518	sta r11L
$E671			B102	lda (r0L),y
$E673			E602	inc r0L
$E675			D002	bne $E679
$E677			E603	inc r0H
$E679			8519	sta r11H

$E67B			B102	lda (r0L),y
$E67D			E602	inc r0L
$E67F			D002	bne $E683
$E681			E603	inc r0H
$E683			8505	sta r1H
$E685			2091E6	jsr xPutString

$E688			E602	inc r0L
$E68A			D002	bne $E68E
$E68C			E603	inc r0H
$E68E			6C0200	jmp (r0)

$E691			A000	ldy #$00			;xPutString
$E693			B102	lda (r0L),y
$E695			F00C	beq $E6A3
$E697			20F5E4	jsr xPutChar
$E69A			E602	inc r0L
$E69C			D002	bne $E6A0
$E69E			E603	inc r0H
$E6A0			B8	clv
$E6A1			50EE	bvc xPutString
$E6A3			60	rts

$E6A4			A9D2	lda #>BSW_Font			;xUseSystemFont
$E6A6			8503	sta r0H
$E6A8			A910	lda #<BSW_Font
$E6AA			8502	sta r0L

$E6AC			A000	ldy #$00			;xLoadCharSet
$E6AE			B102	lda (r0L),y
$E6B0			992600	sta baselineOffset,y
$E6B3			C8	iny
$E6B4			C008	cpy #$08
$E6B6			D0F6	bne $E6AE

$E6B8			A502	lda r0L
$E6BA			18	clc
$E6BB			652A	adc curIndexTable
$E6BD			852A	sta curIndexTable
$E6BF			A503	lda r0H
$E6C1			652B	adc curIndexTabl+1
$E6C3			852B	sta curIndexTabl+1

$E6C5			A502	lda r0L
$E6C7			18	clc
$E6C8			652C	adc cardDataPtr
$E6CA			852C	sta cardDataPtr
$E6CC			A503	lda r0H
$E6CE			652D	adc cardDataPtr+1
$E6D0			852D	sta cardDataPtr+1

$E6D2			AD38D8	lda SerNoHByte
$E6D5			D006	bne $E6DD
$E6D7			20F8CF	jsr GetSerHByte
$E6DA			8D38D8	sta SerNoHByte
$E6DD			60	rts

$E6DE			38	sec 			;xGetCharWidth
$E6DF			E920	sbc #$20
$E6E1			B003	bcs GetCodeWidth
$E6E3			A900	lda #$00
$E6E5			60	rts

$E6E6			C95F	cmp #$5F			;GetCodeWidth
$E6E8			D004	bne $E6EE
$E6EA			AD0788	lda CurCharWidth
$E6ED			60	rts

$E6EE			0A	asl
$E6EF			A8	tay
$E6F0			C8	iny
$E6F1			C8	iny
$E6F2			B12A	lda (curIndexTable),y
$E6F4			88	dey
$E6F5			88	dey
$E6F6			38	sec
$E6F7			F12A	sbc (curIndexTable),y
$E6F9			60	rts

$E6FA			A503	lda r0H			;xGetString
$E6FC			8525	sta string+1
$E6FE			A502	lda r0L
$E700			8524	sta string+0

$E702			A504	lda r1L
$E704			8DD387	sta InpStrgFault
$E707			A505	lda r1H
$E709			8DC084	sta stringY
$E70C			A506	lda r2L
$E70E			8DD087	sta InpStrgLen

$E711			A505	lda r1H
$E713			48	pha
$E714			18	clc
$E715			A526	lda baselineOffset
$E717			6505	adc r1H
$E719			8505	sta r1H
$E71B			2048C1	jsr PutString
$E71E			68	pla
$E71F			8505	sta r1H

$E721			38	sec
$E722			A502	lda r0L
$E724			E524	sbc string
$E726			8DCF87	sta InpStrMaxKey

$E729			A519	lda r11H
$E72B			8DBF84	sta stringX +1
$E72E			A518	lda r11L
$E730			8DBE84	sta stringX +0

$E733			ADA484	lda keyVector+1
$E736			8DD287	sta InpStrgKVecBuf +1
$E739			ADA384	lda keyVector
$E73C			8DD187	sta InpStrgKVecBuf +0

$E73F			A9E7	lda #>InputNextKey
$E741			8DA484	sta keyVector+1
$E744			A98F	lda #<InputNextKey
$E746			8DA384	sta keyVector+0

$E749			A9E7	lda #$E7
$E74B			8DAC84	sta StringFaultVec+1
$E74E			A96A	lda #$6A
$E750			8DAB84	sta StringFaultVec+0

$E753			2CD387	bit InpStrgFault
$E756			100A	bpl $E762
$E758			A50B	lda r4H
$E75A			8DAC84	sta StringFaultVec+1
$E75D			A50A	lda r4L
$E75F			8DAB84	sta StringFaultVec+0

$E762			A529	lda curSetHight
$E764			20ACE8	jsr xInitTextPrompt
$E767			4C6EE8	jmp xPromptOn
$E76A			ADCF87	lda InpStrMaxKey			;SetMaxInput
$E76D			8DD087	sta InpStrgLen
$E770			CECF87	dec InpStrMaxKey
$E773			60	rts

$E774			ADB484	lda alphaFlag			;SetCursorMode
$E777			1015	bpl $E78E
$E779			CEB484	dec alphaFlag
$E77C			ADB484	lda alphaFlag
$E77F			293F	and #%00111111
$E781			D00B	bne $E78E
$E783			2CB484	bit alphaFlag
$E786			5003	bvc $E78B
$E788			4C92E8	jmp xPromptOff
$E78B			4C6EE8	jmp xPromptOn
$E78E			60	rts

$E78F			2092E8	jsr xPromptOff			;InputNextKey
$E792			ADBF84	lda stringX +1
$E795			8519	sta r11H
$E797			ADBE84	lda stringX+0
$E79A			8518	sta r11L
$E79C			ADC084	lda stringY
$E79F			8505	sta r1H
$E7A1			ACCF87	ldy InpStrMaxKey
$E7A4			AD0485	lda keyData
$E7A7			1001	bpl $E7AA
$E7A9			60	rts

$E7AA			C90D	cmp #$0D
$E7AC			F056	beq GetStringEnd
$E7AE			C908	cmp #$08
$E7B0			F049	beq $E7FB
$E7B2			C91D	cmp #$1D
$E7B4			F045	beq $E7FB
$E7B6			C91C	cmp #$1C
$E7B8			F041	beq $E7FB
$E7BA			C91E	cmp #$1E
$E7BC			F03D	beq $E7FB
$E7BE			C920	cmp #$20
$E7C0			90E7	bcc $E7A9

$E7C2			CCD087	cpy InpStrgLen
$E7C5			F03A	beq $E801
$E7C7			9124	sta (string),y

$E7C9			A52F	lda dispBufferOn
$E7CB			48	pha
$E7CC			A52F	lda dispBufferOn
$E7CE			2920	and #%00100000
$E7D0			F004	beq $E7D6
$E7D2			A9A0	lda #$A0
$E7D4			852F	sta dispBufferOn

$E7D6			A505	lda r1H
$E7D8			48	pha
$E7D9			18	clc
$E7DA			A526	lda baselineOffset
$E7DC			6505	adc r1H
$E7DE			8505	sta r1H
$E7E0			B124	lda (string),y
$E7E2			2045C1	jsr PutChar
$E7E5			68	pla
$E7E6			8505	sta r1H

$E7E8			68	pla
$E7E9			852F	sta dispBufferOn

$E7EB			EECF87	inc InpStrMaxKey

$E7EE			A619	ldx r11H
$E7F0			8EBF84	stx stringX +1
$E7F3			A618	ldx r11L
$E7F5			8EBE84	stx stringX
$E7F8			B8	clv
$E7F9			5006	bvc $E801

$E7FB			2033E8	jsr DelLastKey
$E7FE			B8	clv
$E7FF			5000	bvc $E801

$E801			4C6EE8	jmp xPromptOn

$E804			78	sei 			;GetStringEnd
$E805			2092E8	jsr xPromptOff

$E808			A97F	lda #%01111111
$E80A			2DB484	and alphaFlag
$E80D			8DB484	sta alphaFlag
$E810			58	cli

$E811			A900	lda #$00
$E813			9124	sta (string),y

$E815			ADD287	lda InpStrgKVecBuf +1
$E818			8503	sta r0H
$E81A			ADD187	lda InpStrgKVecBuf +0
$E81D			8502	sta r0L

$E81F			A900	lda #$00
$E821			8DA384	sta keyVector+0
$E824			8DA484	sta keyVector+1
$E827			8DAB84	sta StringFaultVec+0
$E82A			8DAC84	sta StringFaultVec+1
$E82D			AECF87	ldx InpStrMaxKey
$E830			6C0200	jmp (r0)

$E833			C000	cpy #$00			;DelLastKey
$E835			F035	beq $E86C
$E837			88	dey
$E838			8CCF87	sty InpStrMaxKey

$E83B			A52F	lda dispBufferOn
$E83D			48	pha
$E83E			A52F	lda dispBufferOn
$E840			2920	and #%00100000
$E842			F004	beq $E848
$E844			A9A0	lda #$A0
$E846			852F	sta dispBufferOn

$E848			A505	lda r1H
$E84A			48	pha
$E84B			18	clc
$E84C			A526	lda baselineOffset
$E84E			6505	adc r1H
$E850			8505	sta r1H
$E852			B124	lda (string),y
$E854			201EE6	jsr RemoveChar
$E857			68	pla
$E858			8505	sta r1H
$E85A			ACCF87	ldy InpStrMaxKey
$E85D			68	pla
$E85E			852F	sta dispBufferOn

$E860			A619	ldx r11H
$E862			8EBF84	stx stringX +1
$E865			A618	ldx r11L
$E867			8EBE84	stx stringX
$E86A			18	clc
$E86B			60	rts

$E86C			38	sec
$E86D			60	rts

$E86E			A940	lda #%01000000			;xPromptOn
$E870			0DB484	ora alphaFlag
$E873			8DB484	sta alphaFlag
$E876			A901	lda #$01
$E878			8508	sta r3L
$E87A			ADBF84	lda stringX +1
$E87D			850B	sta r4H
$E87F			ADBE84	lda stringX +0
$E882			850A	sta r4L
$E884			ADC084	lda stringY
$E887			850C	sta r5L
$E889			20C0CC	jsr xPosSprite
$E88C			2002CD	jsr xEnablSprite
$E88F			B8	clv
$E890			500F	bvc SetPromptMode

$E892			A9BF	lda #%10111111			;xPromptOff
$E894			2DB484	and alphaFlag
$E897			8DB484	sta alphaFlag
$E89A			A901	lda #$01
$E89C			8508	sta r3L
$E89E			201ACD	jsr xDisablSprite

$E8A1			ADB484	lda alphaFlag			;SetPromptMode
$E8A4			29C0	and #%11000000
$E8A6			093C	ora #%00111100
$E8A8			8DB484	sta alphaFlag
$E8AB			60	rts

$E8AC			A8	tay 			;xInitTextPrompt

$E8AD			A501	lda CPU_DATA
$E8AF			48	pha
$E8B0			A935	lda #$35
$E8B2			8501	sta CPU_DATA

$E8B4			AD27D0	lda mob0clr
$E8B7			8D28D0	sta mob1clr
$E8BA			AD17D0	lda moby2
$E8BD			29FD	and #%11111101
$E8BF			8D17D0	sta moby2

$E8C2			98	tya
$E8C3			48	pha
$E8C4			A983	lda #%10000011
$E8C6			8DB484	sta alphaFlag

$E8C9			A240	ldx #$40
$E8CB			A900	lda #$00
$E8CD			9D3F8A	sta spr1pic -1,x
$E8D0			CA	dex
$E8D1			D0FA	bne $E8CD

$E8D3			68	pla
$E8D4			A8	tay
$E8D5			C015	cpy #$15
$E8D7			900D	bcc $E8E6
$E8D9			F00B	beq $E8E6

$E8DB			98	tya
$E8DC			4A	lsr
$E8DD			A8	tay
$E8DE			AD17D0	lda moby2
$E8E1			0902	ora #%00000010
$E8E3			8D17D0	sta moby2

$E8E6			A980	lda #$80
$E8E8			9D408A	sta spr1pic,x
$E8EB			E8	inx
$E8EC			E8	inx
$E8ED			E8	inx
$E8EE			88	dey
$E8EF			10F7	bpl $E8E8
$E8F1			68	pla
$E8F2			8501	sta CPU_DATA
$E8F4			60	rts

$E8F5			8506	sta r2L			;ConvDEZtoASCII
$E8F7			A904	lda #$04
$E8F9			8507	sta r2H
$E8FB			A900	lda #$00
$E8FD			8508	sta r3L
$E8FF			8509	sta r3H

$E901			A000	ldy #$00
$E903			A607	ldx r2H
$E905			A502	lda r0L
$E907			38	sec
$E908			FD4AE9	sbc DezDataL,x
$E90B			8502	sta r0L
$E90D			A503	lda r0H
$E90F			FD4FE9	sbc DezDataH,x
$E912			9006	bcc $E91A
$E914			8503	sta r0H
$E916			C8	iny
$E917			B8	clv
$E918			50EB	bvc $E905

$E91A			A502	lda r0L
$E91C			7D4AE9	adc DezDataL,x
$E91F			8502	sta r0L
$E921			98	tya
$E922			D008	bne $E92C
$E924			E000	cpx #$00
$E926			F004	beq $E92C
$E928			2406	bit r2L
$E92A			7019	bvs $E945

$E92C			0930	ora #%00110000
$E92E			A608	ldx r3L
$E930			9545	sta SetStream,x
$E932			A62E	ldx currentMode
$E934			204BDE	jsr xGetRealSize
$E937			98	tya
$E938			18	clc
$E939			6509	adc r3H
$E93B			8509	sta r3H
$E93D			E608	inc r3L

$E93F			A9BF	lda #%10111111
$E941			2506	and r2L
$E943			8506	sta r2L
$E945			C607	dec r2H
$E947			10B8	bpl $E901
$E949			60	rts

$E94A			01	b < 1			;DezDataL
$E94B			0A	b < 10
$E94C			64	b < 100
$E94D			E8	b < 1000
$E94E			10	b < 10000

$E94F			00	b > 1			;DezDataH
$E950			00	b > 10
$E951			00	b > 100
$E952			03	b > 1000
$E953			27	b > 10000

$E954			20F5E8	jsr ConvDEZtoASCII			;xPutDecimal

$E957			2406	bit r2L
$E959			3010	bmi $E96B

$E95B			A506	lda r2L
$E95D			293F	and #%00111111
$E95F			38	sec
$E960			E509	sbc r3H
$E962			18	clc
$E963			6518	adc r11L
$E965			8518	sta r11L
$E967			9002	bcc $E96B
$E969			E619	inc r11H

$E96B			A608	ldx r3L
$E96D			8602	stx r0L
$E96F			B544	lda SetStream-1,x
$E971			48	pha
$E972			CA	dex
$E973			D0FA	bne $E96F

$E975			68	pla
$E976			20F5E4	jsr xPutChar
$E979			C602	dec r0L
$E97B			D0F8	bne $E975
$E97D			60	rts

$E97E			A0FF	ldy #$FF			;xCRC
$E980			8406	sty r2L
$E982			8407	sty r2H
$E984			C8	iny
$E985			A980	lda #$80
$E987			8508	sta r3L

$E989			0606	asl r2L
$E98B			2607	rol r2H

$E98D			B102	lda (r0L),y
$E98F			2508	and r3L
$E991			9002	bcc $E995

$E993			4508	eor r3L
$E995			F00C	beq $E9A3

$E997			A506	lda r2L
$E999			4921	eor #%00100001
$E99B			8506	sta r2L
$E99D			A507	lda r2H
$E99F			4910	eor #%00010000
$E9A1			8507	sta r2H

$E9A3			4608	lsr r3L
$E9A5			90E2	bcc $E989

$E9A7			C8	iny
$E9A8			D002	bne $E9AC
$E9AA			E603	inc r0H

$E9AC			A204	ldx #r1L
$E9AE			2075C1	jsr Ddec
$E9B1			A504	lda r1L
$E9B3			0505	ora r1H
$E9B5			D0CE	bne $E985
$E9B7			60	rts

$E9B8			08	php 			;xDrawLine
$E9B9			A900	lda #$00
$E9BB			8511	sta r7H

$E9BD			A519	lda r11H
$E9BF			38	sec
$E9C0			E518	sbc r11L
$E9C2			8510	sta r7L
$E9C4			B007	bcs $E9CD
$E9C6			A900	lda #$00
$E9C8			38	sec
$E9C9			E510	sbc r7L
$E9CB			8510	sta r7L

$E9CD			A50A	lda r4L
$E9CF			38	sec
$E9D0			E508	sbc r3L
$E9D2			851A	sta r12L
$E9D4			A50B	lda r4H
$E9D6			E509	sbc r3H
$E9D8			851B	sta r12H
$E9DA			A21A	ldx #r12L
$E9DC			206FC1	jsr Dabs

$E9DF			A51B	lda r12H
$E9E1			C511	cmp r7H
$E9E3			D004	bne $E9E9
$E9E5			A51A	lda r12L
$E9E7			C510	cmp r7L
$E9E9			B003	bcs SetVarHLine
$E9EB			4C95EA	jmp SetVarVLine

$E9EE			A510	lda r7L			;SetVarHLine
$E9F0			0A	asl
$E9F1			8514	sta r9L
$E9F3			A511	lda r7H
$E9F5			2A	rol
$E9F6			8515	sta r9H

$E9F8			A514	lda r9L
$E9FA			38	sec
$E9FB			E51A	sbc r12L
$E9FD			8512	sta r8L
$E9FF			A515	lda r9H
$EA01			E51B	sbc r12H
$EA03			8513	sta r8H

$EA05			A510	lda r7L
$EA07			38	sec
$EA08			E51A	sbc r12L
$EA0A			8516	sta r10L
$EA0C			A511	lda r7H
$EA0E			E51B	sbc r12H
$EA10			8517	sta r10H

$EA12			0616	asl r10L
$EA14			2617	rol r10H

$EA16			A9FF	lda #$FF
$EA18			851C	sta r13L

$EA1A			A509	lda r3H
$EA1C			C50B	cmp r4H
$EA1E			D004	bne $EA24
$EA20			A508	lda r3L
$EA22			C50A	cmp r4L
$EA24			9021	bcc $EA47

$EA26			A518	lda r11L
$EA28			C519	cmp r11H
$EA2A			9004	bcc $EA30

$EA2C			A901	lda #$01
$EA2E			851C	sta r13L

$EA30			A409	ldy r3H
$EA32			A608	ldx r3L
$EA34			A50B	lda r4H
$EA36			8509	sta r3H
$EA38			A50A	lda r4L
$EA3A			8508	sta r3L
$EA3C			840B	sty r4H
$EA3E			860A	stx r4L

$EA40			A519	lda r11H
$EA42			8518	sta r11L
$EA44			B8	clv
$EA45			500A	bvc $EA51

$EA47			A419	ldy r11H
$EA49			C418	cpy r11L
$EA4B			9004	bcc $EA51
$EA4D			A901	lda #$01
$EA4F			851C	sta r13L
$EA51			28	plp
$EA52			08	php
$EA53			2044EB	jsr xDrawPoint

$EA56			A509	lda r3H
$EA58			C50B	cmp r4H
$EA5A			D004	bne $EA60
$EA5C			A508	lda r3L
$EA5E			C50A	cmp r4L
$EA60			B031	bcs $EA93

$EA62			E608	inc r3L
$EA64			D002	bne $EA68
$EA66			E609	inc r3H

$EA68			2413	bit r8H
$EA6A			1010	bpl $EA7C

$EA6C			A514	lda r9L
$EA6E			18	clc
$EA6F			6512	adc r8L
$EA71			8512	sta r8L
$EA73			A515	lda r9H
$EA75			6513	adc r8H
$EA77			8513	sta r8H
$EA79			B8	clv
$EA7A			50D5	bvc $EA51

$EA7C			18	clc
$EA7D			A51C	lda r13L
$EA7F			6518	adc r11L
$EA81			8518	sta r11L
$EA83			A516	lda r10L
$EA85			18	clc
$EA86			6512	adc r8L
$EA88			8512	sta r8L

$EA8A			A517	lda r10H
$EA8C			6513	adc r8H
$EA8E			8513	sta r8H
$EA90			B8	clv
$EA91			50BE	bvc $EA51

$EA93			28	plp
$EA94			60	rts

$EA95			A51A	lda r12L			;SetVarVLine
$EA97			0A	asl
$EA98			8514	sta r9L
$EA9A			A51B	lda r12H
$EA9C			2A	rol
$EA9D			8515	sta r9H

$EA9F			A514	lda r9L
$EAA1			38	sec
$EAA2			E510	sbc r7L
$EAA4			8512	sta r8L
$EAA6			A515	lda r9H
$EAA8			E511	sbc r7H
$EAAA			8513	sta r8H

$EAAC			A51A	lda r12L
$EAAE			38	sec
$EAAF			E510	sbc r7L
$EAB1			8516	sta r10L
$EAB3			A51B	lda r12H
$EAB5			E511	sbc r7H
$EAB7			8517	sta r10H
$EAB9			0616	asl r10L
$EABB			2617	rol r10H

$EABD			A9FF	lda #$FF
$EABF			851D	sta r13H
$EAC1			851C	sta r13L

$EAC3			A518	lda r11L
$EAC5			C519	cmp r11H
$EAC7			9027	bcc $EAF0
$EAC9			A509	lda r3H
$EACB			C50B	cmp r4H
$EACD			D004	bne $EAD3

$EACF			A508	lda r3L
$EAD1			C50A	cmp r4L
$EAD3			9008	bcc $EADD

$EAD5			A900	lda #$00
$EAD7			851D	sta r13H
$EAD9			A901	lda #$01
$EADB			851C	sta r13L

$EADD			A50B	lda r4H
$EADF			8509	sta r3H
$EAE1			A50A	lda r4L
$EAE3			8508	sta r3L
$EAE5			A618	ldx r11L
$EAE7			A519	lda r11H
$EAE9			8518	sta r11L
$EAEB			8619	stx r11H
$EAED			B8	clv
$EAEE			5014	bvc $EB04

$EAF0			A509	lda r3H
$EAF2			C50B	cmp r4H
$EAF4			D004	bne $EAFA
$EAF6			A508	lda r3L
$EAF8			C50A	cmp r4L
$EAFA			B008	bcs $EB04

$EAFC			A900	lda #$00
$EAFE			851D	sta r13H
$EB00			A901	lda #$01
$EB02			851C	sta r13L
$EB04			28	plp
$EB05			08	php
$EB06			2044EB	jsr xDrawPoint

$EB09			A518	lda r11L
$EB0B			C519	cmp r11H
$EB0D			B033	bcs $EB42
$EB0F			E618	inc r11L

$EB11			2413	bit r8H
$EB13			1010	bpl $EB25

$EB15			A514	lda r9L
$EB17			18	clc
$EB18			6512	adc r8L
$EB1A			8512	sta r8L
$EB1C			A515	lda r9H
$EB1E			6513	adc r8H
$EB20			8513	sta r8H
$EB22			B8	clv
$EB23			50DF	bvc $EB04

$EB25			A51C	lda r13L
$EB27			18	clc
$EB28			6508	adc r3L
$EB2A			8508	sta r3L
$EB2C			A51D	lda r13H
$EB2E			6509	adc r3H
$EB30			8509	sta r3H

$EB32			A516	lda r10L
$EB34			18	clc
$EB35			6512	adc r8L
$EB37			8512	sta r8L
$EB39			A517	lda r10H
$EB3B			6513	adc r8H
$EB3D			8513	sta r8H
$EB3F			B8	clv
$EB40			50C2	bvc $EB04

$EB42			28	plp
$EB43			60	rts

$EB44			08	php 			;xDrawPoint
$EB45			A618	ldx r11L
$EB47			207DCA	jsr xGetScanLine

$EB4A			A508	lda r3L
$EB4C			29F8	and #%11111000
$EB4E			A8	tay
$EB4F			A509	lda r3H
$EB51			F004	beq $EB57
$EB53			E60D	inc r5H
$EB55			E60F	inc r6H
$EB57			A508	lda r3L
$EB59			2907	and #%00000111
$EB5B			AA	tax
$EB5C			BDE6C2	lda BitData1,x
$EB5F			28	plp
$EB60			3010	bmi $EB72
$EB62			9005	bcc $EB69
$EB64			110E	ora (r6L),y
$EB66			B8	clv
$EB67			5004	bvc $EB6D

$EB69			49FF	eor #%11111111
$EB6B			310E	and (r6L),y
$EB6D			910E	sta (r6L),y
$EB6F			910C	sta (r5L),y
$EB71			60	rts

$EB72			48	pha
$EB73			49FF	eor #%11111111
$EB75			310C	and (r5L),y
$EB77			910C	sta (r5L),y
$EB79			68	pla
$EB7A			310E	and (r6L),y
$EB7C			110C	ora (r5L),y
$EB7E			910C	sta (r5L),y
$EB80			60	rts

$EB81			A618	ldx r11L			;xTestPoint
$EB83			207DCA	jsr xGetScanLine

$EB86			A508	lda r3L
$EB88			29F8	and #%11111000
$EB8A			A8	tay
$EB8B			A509	lda r3H
$EB8D			F002	beq $EB91
$EB8F			E60F	inc r6H

$EB91			A508	lda r3L
$EB93			2907	and #%00000111
$EB95			AA	tax
$EB96			BDE6C2	lda BitData1,x
$EB99			310E	and (r6L),y
$EB9B			F002	beq $EB9F
$EB9D			38	sec
$EB9E			60	rts
$EB9F			18	clc
$EBA0			60	rts

$EBA1			9013	bcc $EBB6			;xStartMouseMode

$EBA3			A518	lda r11L
$EBA5			0519	ora r11H
$EBA7			F00D	beq $EBB6

$EBA9			A519	lda r11H
$EBAB			853B	sta mouseXPos+1
$EBAD			A518	lda r11L
$EBAF			853A	sta mouseXPos
$EBB1			843C	sty mouseYPos
$EBB3			2083FE	jsr SlowMouse

$EBB6			A9EC	lda #>ChkMseButton
$EBB8			8DA284	sta mouseVector+1
$EBBB			A9B6	lda #<ChkMseButton
$EBBD			8DA184	sta mouseVector+0

$EBC0			A9ED	lda #>IsMseOnMenu
$EBC2			8DA884	sta mouseFaultVec+1
$EBC5			A909	lda #<IsMseOnMenu
$EBC7			8DA784	sta mouseFaultVec+0

$EBCA			A900	lda #$00
$EBCC			8DB684	sta faultData
$EBCF			4C8AC1	jmp MouseUp

$EBD2			A900	lda #$00			;xClearMouseMode
$EBD4			8530	sta mouseOn
$EBD6			A900	lda #$00			;MouseSpriteOff
$EBD8			8508	sta r3L
$EBDA			4C1ACD	jmp xDisablSprite

$EBDD			A97F	lda #%01111111			;xMouseOff
$EBDF			2530	and mouseOn
$EBE1			8530	sta mouseOn
$EBE3			4CD6EB	jmp MouseSpriteOff

$EBE6			A980	lda #%10000000			;xMouseUp
$EBE8			0530	ora mouseOn
$EBEA			8530	sta mouseOn
$EBEC			60	rts

$EBED			2086FE	jsr UpdateMouse			;InitMouseData

$EBF0			2430	bit mouseOn
$EBF2			1024	bpl $EC18
$EBF4			2019EC	jsr SetMseToArea

$EBF7			A900	lda #$00
$EBF9			8508	sta r3L
$EBFB			A532	lda msePicPtr+1
$EBFD			850B	sta r4H
$EBFF			A531	lda msePicPtr+0
$EC01			850A	sta r4L
$EC03			20C6C1	jsr DrawSprite

$EC06			A53B	lda mouseXPos+1
$EC08			850B	sta r4H
$EC0A			A53A	lda mouseXPos
$EC0C			850A	sta r4L
$EC0E			A53C	lda mouseYPos
$EC10			850C	sta r5L
$EC12			20CFC1	jsr PosSprite
$EC15			20D2C1	jsr EnablSprite
$EC18			60	rts

$EC19			ACBA84	ldy mouseLeft+0			;SetMseToArea
$EC1C			AEBB84	ldx mouseLeft+1
$EC1F			A53B	lda mouseXPos+1
$EC21			300A	bmi $EC2D
$EC23			E43B	cpx mouseXPos+1
$EC25			D002	bne $EC29
$EC27			C43A	cpy mouseXPos+0
$EC29			900E	bcc $EC39
$EC2B			F00C	beq $EC39

$EC2D			A920	lda #%00100000
$EC2F			0DB684	ora faultData
$EC32			8DB684	sta faultData
$EC35			843A	sty mouseXPos+0
$EC37			863B	stx mouseXPos+1

$EC39			ACBC84	ldy mouseRight+0
$EC3C			AEBD84	ldx mouseRight+1
$EC3F			E43B	cpx mouseXPos+1
$EC41			D002	bne $EC45
$EC43			C43A	cpy mouseXPos+0
$EC45			B00C	bcs $EC53

$EC47			A910	lda #%00010000
$EC49			0DB684	ora faultData
$EC4C			8DB684	sta faultData
$EC4F			843A	sty mouseXPos+0
$EC51			863B	stx mouseXPos+1

$EC53			ACB884	ldy mouseTop
$EC56			A53C	lda mouseYPos
$EC58			C9E4	cmp #$E4
$EC5A			B006	bcs $EC62
$EC5C			C43C	cpy mouseYPos
$EC5E			900C	bcc $EC6C
$EC60			F00A	beq $EC6C

$EC62			A980	lda #%10000000
$EC64			0DB684	ora faultData
$EC67			8DB684	sta faultData
$EC6A			843C	sty mouseYPos

$EC6C			ACB984	ldy mouseBottom
$EC6F			C43C	cpy mouseYPos
$EC71			B00A	bcs $EC7D

$EC73			A940	lda #%01000000
$EC75			0DB684	ora faultData
$EC78			8DB684	sta faultData
$EC7B			843C	sty mouseYPos

$EC7D			2430	bit mouseOn
$EC7F			5034	bvc $ECB5
$EC81			A53C	lda mouseYPos
$EC83			CDC186	cmp DM_MenuRange+0
$EC86			9025	bcc $ECAD
$EC88			CDC286	cmp DM_MenuRange+1
$EC8B			F002	beq $EC8F
$EC8D			B01E	bcs $ECAD

$EC8F			A53B	lda mouseXPos+1
$EC91			CDC486	cmp DM_MenuRange+3
$EC94			D005	bne $EC9B
$EC96			A53A	lda mouseXPos
$EC98			CDC386	cmp DM_MenuRange+2
$EC9B			9010	bcc $ECAD
$EC9D			A53B	lda mouseXPos+1
$EC9F			CDC686	cmp DM_MenuRange+5
$ECA2			D005	bne $ECA9
$ECA4			A53A	lda mouseXPos
$ECA6			CDC586	cmp DM_MenuRange+4
$ECA9			900A	bcc $ECB5
$ECAB			F008	beq $ECB5
$ECAD			A908	lda #%00001000
$ECAF			0DB684	ora faultData
$ECB2			8DB684	sta faultData
$ECB5			60	rts

$ECB6			AD0585	lda mouseData			;ChkMseButton
$ECB9			3044	bmi $ECFF

$ECBB			A530	lda mouseOn
$ECBD			2980	and #%10000000
$ECBF			F03E	beq $ECFF

$ECC1			A530	lda mouseOn
$ECC3			2940	and #%01000000
$ECC5			F02F	beq $ECF6
$ECC7			A53C	lda mouseYPos
$ECC9			CDC186	cmp DM_MenuRange+0
$ECCC			9028	bcc $ECF6
$ECCE			CDC286	cmp DM_MenuRange+1
$ECD1			F002	beq $ECD5
$ECD3			B021	bcs $ECF6
$ECD5			A53B	lda mouseXPos+1
$ECD7			CDC486	cmp DM_MenuRange+3
$ECDA			D005	bne $ECE1
$ECDC			A53A	lda mouseXPos
$ECDE			CDC386	cmp DM_MenuRange+2
$ECE1			9013	bcc $ECF6
$ECE3			A53B	lda mouseXPos+1
$ECE5			CDC686	cmp DM_MenuRange+5
$ECE8			D005	bne $ECEF
$ECEA			A53A	lda mouseXPos
$ECEC			CDC586	cmp DM_MenuRange+4
$ECEF			F002	beq $ECF3
$ECF1			B003	bcs $ECF6
$ECF3			4C24F0	jmp DM_ExecMenuJob

$ECF6			A530	lda mouseOn
$ECF8			2920	and #%00100000
$ECFA			F003	beq $ECFF
$ECFC			4CCEF1	jmp DI_ChkMseClk

$ECFF			ADA984	lda otherPressVec+0
$ED02			AEAA84	ldx otherPressVec+1
$ED05			4CD8C1	jmp CallRoutine
$ED08			60	rts

$ED09			A9C0	lda #$C0			;IsMseOnMenu
$ED0B			2430	bit mouseOn
$ED0D			1029	bpl $ED38
$ED0F			5027	bvc $ED38
$ED11			ADB784	lda menuNumber
$ED14			F022	beq $ED38

$ED16			ADB684	lda faultData
$ED19			2908	and #%00001000
$ED1B			D018	bne $ED35
$ED1D			A280	ldx #$80
$ED1F			A9C0	lda #$C0
$ED21			A8	tay
$ED22			2CC086	bit DM_MenuType
$ED25			3002	bmi $ED29
$ED27			A220	ldx #$20
$ED29			8A	txa
$ED2A			2DB684	and faultData
$ED2D			D006	bne $ED35
$ED2F			98	tya
$ED30			2CC086	bit DM_MenuType
$ED33			7003	bvs $ED38
$ED35			2019EE	jsr xDoPreviousMenu
$ED38			60	rts

$ED39			8DCF86	sta DM_MseOnEntry			;xDoMenu
$ED3C			A200	ldx #$00
$ED3E			8EB784	stx menuNumber
$ED41			F008	beq DM_SaveMenu

$ED43			AEB784	ldx menuNumber			;DM_OpenMenu
$ED46			A900	lda #$00
$ED48			9DCF86	sta DM_MseOnEntry,x

$ED4B			A502	lda r0L			;DM_SaveMenu
$ED4D			9DC786	sta DM_MenuTabL,x
$ED50			A503	lda r0H
$ED52			9DCB86	sta DM_MenuTabH,x
$ED55			2042EE	jsr DM_SetMenuData
$ED58			38	sec

$ED59			08	php 			;DM_InitMenu
$ED5A			A52F	lda dispBufferOn
$ED5C			48	pha
$ED5D			A980	lda #$80
$ED5F			852F	sta dispBufferOn
$ED61			A519	lda r11H
$ED63			48	pha
$ED64			A518	lda r11L
$ED66			48	pha
$ED67			2019F0	jsr DM_SetMenuRec

$ED6A			A523	lda curPattern+1
$ED6C			48	pha
$ED6D			A522	lda curPattern
$ED6F			48	pha
$ED70			A900	lda #$00
$ED72			2053CA	jsr xSetPattern
$ED75			2055C8	jsr xRectangle
$ED78			68	pla
$ED79			8522	sta curPattern
$ED7B			68	pla
$ED7C			8523	sta curPattern+1
$ED7E			A9FF	lda #$FF
$ED80			20C3C8	jsr xFrameRectangle
$ED83			68	pla
$ED84			8518	sta r11L
$ED86			68	pla
$ED87			8519	sta r11H
$ED89			2083EE	jsr DM_PrintMenu
$ED8C			20B2EF	jsr DM_SetMenuLine
$ED8F			68	pla
$ED90			852F	sta dispBufferOn
$ED92			28	plp
$ED93			2CC086	bit DM_MenuType
$ED96			7002	bvs $ED9A
$ED98			9055	bcc $EDEF

$ED9A			AEB784	ldx menuNumber
$ED9D			BCCF86	ldy DM_MseOnEntry,x
$EDA0			2CC086	bit DM_MenuType
$EDA3			302A	bmi $EDCF
$EDA5			B9D386	lda DM_MenuPosL,y
$EDA8			8518	sta r11L
$EDAA			B9E286	lda DM_MenuPosH,y
$EDAD			8519	sta r11H
$EDAF			C8	iny
$EDB0			B9D386	lda DM_MenuPosL,y
$EDB3			18	clc
$EDB4			6518	adc r11L
$EDB6			8518	sta r11L
$EDB8			B9E286	lda DM_MenuPosH,y
$EDBB			6519	adc r11H
$EDBD			8519	sta r11H
$EDBF			6619	ror r11H
$EDC1			6618	ror r11L
$EDC3			ADC186	lda DM_MenuRange+0
$EDC6			18	clc
$EDC7			6DC286	adc DM_MenuRange+1
$EDCA			6A	ror
$EDCB			A8	tay
$EDCC			B8	clv
$EDCD			501F	bvc $EDEE

$EDCF			B9D386	lda DM_MenuPosL,y
$EDD2			C8	iny
$EDD3			18	clc
$EDD4			79D386	adc DM_MenuPosL,y
$EDD7			4A	lsr
$EDD8			A8	tay
$EDD9			ADC386	lda DM_MenuRange+2
$EDDC			18	clc
$EDDD			6DC586	adc DM_MenuRange+4
$EDE0			8518	sta r11L
$EDE2			ADC486	lda DM_MenuRange+3
$EDE5			6DC686	adc DM_MenuRange+5
$EDE8			8519	sta r11H
$EDEA			4619	lsr r11H
$EDEC			6618	ror r11L
$EDEE			38	sec
$EDEF			2430	bit mouseOn
$EDF1			1006	bpl $EDF9
$EDF3			A920	lda #%00100000
$EDF5			0530	ora mouseOn
$EDF7			8530	sta mouseOn
$EDF9			A940	lda #%01000000
$EDFB			0530	ora mouseOn
$EDFD			8530	sta mouseOn
$EDFF			4CA1EB	jmp xStartMouseMode

$EE02			20DDEB	jsr xMouseOff			;xReDoMenu
$EE05			4C22EE	jmp DM_OpenCurMenu

$EE08			08	php 			;xGotoFirstMenu
$EE09			78	sei
$EE0A			ADB784	lda menuNumber
$EE0D			C900	cmp #$00
$EE0F			F006	beq $EE17
$EE11			2019EE	jsr xDoPreviousMenu
$EE14			B8	clv
$EE15			50F3	bvc $EE0A
$EE17			28	plp
$EE18			60	rts

$EE19			20DDEB	jsr xMouseOff			;xDoPreviousMenu
$EE1C			209CEF	jsr xRecoverMenu
$EE1F			CEB784	dec menuNumber

$EE22			2042EE	jsr DM_SetMenuData			;DM_OpenCurMenu
$EE25			18	clc
$EE26			4C59ED	jmp DM_InitMenu

$EE29			48	pha 			;DM_VecToEntry
$EE2A			ACB784	ldy menuNumber
$EE2D			B9C786	lda DM_MenuTabL,y
$EE30			8502	sta r0L
$EE32			B9CB86	lda DM_MenuTabH,y
$EE35			8503	sta r0H
$EE37			68	pla
$EE38			8512	sta r8L
$EE3A			0A	asl
$EE3B			0A	asl
$EE3C			6512	adc r8L
$EE3E			6907	adc #$07
$EE40			A8	tay
$EE41			60	rts

$EE42			AEB784	ldx menuNumber			;DM_SetMenuData
$EE45			BDC786	lda DM_MenuTabL,x
$EE48			8502	sta r0L
$EE4A			BDCB86	lda DM_MenuTabH,x
$EE4D			8503	sta r0H
$EE4F			A006	ldy #$06
$EE51			B102	lda (r0L),y
$EE53			8DC086	sta DM_MenuType
$EE56			88	dey
$EE57			B102	lda (r0L),y
$EE59			99B884	sta mouseTop,y
$EE5C			99C186	sta DM_MenuRange+0,y
$EE5F			88	dey
$EE60			10F5	bpl $EE57

$EE62			B998C0	lda $C098,y			;**********************************
$EE65			18	clc
$EE66			695A	adc #$5A
$EE68			9938C0	sta $C038,y

$EE6B			ADC486	lda DM_MenuRange+3
$EE6E			8519	sta r11H
$EE70			ADC386	lda DM_MenuRange+2
$EE73			8518	sta r11L
$EE75			ADC186	lda DM_MenuRange+0
$EE78			8505	sta r1H
$EE7A			2CC086	bit DM_MenuType
$EE7D			7003	bvs $EE82
$EE7F			2082F1	jsr SetMseFullWin
$EE82			60	rts

$EE85			2039F1	jsr DM_SvFntData			;DM_PrintMenu
$EE86			20A4E6	jsr xUseSystemFont
$EE89			A900	lda #$00
$EE8B			8517	sta r10H
$EE8D			852E	sta currentMode
$EE8F			38	sec
$EE90			2068EF	jsr DM_SetNextPos

$EE93			2053EF	jsr DM_SvEntryPos
$EE96			18	clc
$EE97			2068EF	jsr DM_SetNextPos
$EE9A			20D1EE	jsr DM_PrintEntry
$EE9D			18	clc
$EE9E			2068EF	jsr DM_SetNextPos

$EEA1			2CC086	bit DM_MenuType
$EEA4			1015	bpl $EEBB

$EEA6			A505	lda r1H
$EEA8			38	sec
$EEA9			6529	adc curSetHight
$EEAB			8505	sta r1H
$EEAD			ADC486	lda DM_MenuRange+3
$EEB0			8519	sta r11H
$EEB2			ADC386	lda DM_MenuRange+2
$EEB5			8518	sta r11L
$EEB7			38	sec
$EEB8			2068EF	jsr DM_SetNextPos

$EEBB			A517	lda r10H
$EEBD			18	clc
$EEBE			6901	adc #$01
$EEC0			8517	sta r10H

$EEC2			ADC086	lda DM_MenuType
$EEC5			291F	and #%00011111
$EEC7			C517	cmp r10H
$EEC9			D0C8	bne $EE93

$EECB			2044F1	jsr DM_LdFntData
$EECE			4C53EF	jmp DM_SvEntryPos

$EED1			A517	lda r10H			;DM_PrintEntry
$EED3			48	pha
$EED4			A516	lda r10L
$EED6			48	pha
$EED7			A517	lda r10H
$EED9			2029EE	jsr DM_VecToEntry
$EEDC			B102	lda (r0L),y
$EEDE			AA	tax
$EEDF			C8	iny
$EEE0			B102	lda (r0L),y
$EEE2			8503	sta r0H
$EEE4			8602	stx r0L
$EEE6			A536	lda leftMargin+1
$EEE8			48	pha
$EEE9			A535	lda leftMargin+0
$EEEB			48	pha
$EEEC			A538	lda rightMargin+1
$EEEE			48	pha
$EEEF			A537	lda rightMargin+0
$EEF1			48	pha
$EEF2			ADAC84	lda StringFaultVec+1
$EEF5			48	pha
$EEF6			ADAB84	lda StringFaultVec+0
$EEF9			48	pha
$EEFA			A900	lda #$00
$EEFC			8536	sta leftMargin+1
$EEFE			A900	lda #$00
$EF00			8535	sta leftMargin
$EF02			38	sec
$EF03			ADC586	lda DM_MenuRange+4
$EF06			E901	sbc #$01
$EF08			8537	sta rightMargin
$EF0A			ADC686	lda DM_MenuRange+5
$EF0D			E900	sbc #$00
$EF0F			8538	sta rightMargin+1
$EF11			A9EF	lda #>DM_StopPrint
$EF13			8DAC84	sta StringFaultVec+1
$EF16			A948	lda #<DM_StopPrint
$EF18			8DAB84	sta StringFaultVec+0
$EF1B			A505	lda r1H
$EF1D			48	pha
$EF1E			18	clc
$EF1F			A526	lda baselineOffset
$EF21			6505	adc r1H
$EF23			8505	sta r1H
$EF25			E605	inc r1H
$EF27			2091E6	jsr xPutString
$EF2A			68	pla
$EF2B			8505	sta r1H
$EF2D			68	pla
$EF2E			8DAB84	sta StringFaultVec+0
$EF31			68	pla
$EF32			8DAC84	sta StringFaultVec+1
$EF35			68	pla
$EF36			8537	sta rightMargin+0
$EF38			68	pla
$EF39			8538	sta rightMargin+1
$EF3B			68	pla
$EF3C			8535	sta leftMargin+0
$EF3E			68	pla
$EF3F			8536	sta leftMargin+1
$EF41			68	pla
$EF42			8516	sta r10L
$EF44			68	pla
$EF45			8517	sta r10H
$EF47			60	rts

$EF48			ADBD84	lda mouseRight+1			;DM_StopPrint
$EF4B			8519	sta r11H
$EF4D			ADBC84	lda mouseRight
$EF50			8518	sta r11L
$EF52			60	rts

$EF53			A417	ldy r10H			;DM_SvEntryPos
$EF55			A605	ldx r1H
$EF57			2CC086	bit DM_MenuType
$EF5A			3007	bmi $EF63
$EF5C			A519	lda r11H
$EF5E			99E286	sta DM_MenuPosH,y
$EF61			A618	ldx r11L
$EF63			8A	txa
$EF64			99D386	sta DM_MenuPosL,y
$EF67			60	rts

$EF68			9008	bcc DM_NextPos			;DM_SetNextPos
$EF6A			2CC086	bit DM_MenuType
$EF6D			1008	bpl DM_NextVPos
$EF6F			B8	clv
$EF70			500D	bvc DM_NextHPos

$EF72			2CC086	bit DM_MenuType			;DM_NextPos
$EF75			1008	bpl DM_NextHPos

$EF77			A505	lda r1H			;DM_NextVPos
$EF79			18	clc
$EF7A			6902	adc #$02
$EF7C			8505	sta r1H
$EF7E			60	rts

$EF7F			A518	lda r11L			;DM_NextHPos
$EF81			18	clc
$EF82			6904	adc #$04
$EF84			8518	sta r11L
$EF86			9002	bcc $EF8A
$EF88			E619	inc r11H
$EF8A			60	rts

$EF8B			2042EE	jsr DM_SetMenuData			;xRecoverAllMenus
$EF8E			209CEF	jsr xRecoverMenu
$EF91			CEB784	dec menuNumber
$EF94			10F5	bpl xRecoverAllMenus
$EF96			A900	lda #$00
$EF98			8DB784	sta menuNumber
$EF9B			60	rts

$EF9C			2019F0	jsr DM_SetMenuRec			;xRecoverMenu

$EF9F			ADB184	lda RecoverVector+0			;RecoverDB_Box
$EFA2			0DB284	ora RecoverVector+1
$EFA5			D008	bne $EFAF
$EFA7			A900	lda #$00
$EFA9			2039C1	jsr SetPattern
$EFAC			4C24C1	jmp Rectangle
$EFAF			6CB184	jmp (RecoverVector)

$EFB2			ADC086	lda DM_MenuType			;DM_SetMenuLine
$EFB5			291F	and #%00011111
$EFB7			38	sec
$EFB8			E901	sbc #$01
$EFBA			F05C	beq $F018
$EFBC			8506	sta r2L

$EFBE			2CC086	bit DM_MenuType
$EFC1			3026	bmi $EFE9

$EFC3			ADC186	lda DM_MenuRange+0
$EFC6			18	clc
$EFC7			6901	adc #$01
$EFC9			8508	sta r3L
$EFCB			ADC286	lda DM_MenuRange+1
$EFCE			38	sec
$EFCF			E901	sbc #$01
$EFD1			8509	sta r3H

$EFD3			A606	ldx r2L
$EFD5			BDD386	lda DM_MenuPosL,x
$EFD8			850A	sta r4L
$EFDA			BDE286	lda DM_MenuPosH,x
$EFDD			850B	sta r4H
$EFDF			A9AA	lda #$AA
$EFE1			20E9C7	jsr xVerticalLine
$EFE4			C606	dec r2L
$EFE6			D0EB	bne $EFD3
$EFE8			60	rts

$EFE9			ADC486	lda DM_MenuRange+3
$EFEC			8509	sta r3H
$EFEE			ADC386	lda DM_MenuRange+2
$EFF1			8508	sta r3L
$EFF3			E608	inc r3L
$EFF5			D002	bne $EFF9
$EFF7			E609	inc r3H
$EFF9			ADC686	lda DM_MenuRange+5
$EFFC			850B	sta r4H
$EFFE			ADC586	lda DM_MenuRange+4
$F001			850A	sta r4L
$F003			A20A	ldx #r4L
$F005			2075C1	jsr Ddec

$F008			A606	ldx r2L
$F00A			BDD386	lda DM_MenuPosL,x
$F00D			8518	sta r11L
$F00F			A955	lda #$55
$F011			2051C6	jsr xHorizontalLine
$F014			C606	dec r2L
$F016			D0F0	bne $F008
$F018			60	rts

$F019			A206	ldx #$06			;DM_SetMenuRec
$F01B			BDC086	lda DM_MenuType,x
$F01E			9505	sta r1H,x
$F020			CA	dex
$F021			D0F8	bne $F01B
$F023			60	rts

$F024			20DDEB	jsr xMouseOff			;DM_ExecMenuJob
$F027			2091F0	jsr DM_EntryRange
$F02A			202BF1	jsr InvertMenuArea
$F02D			A514	lda r9L
$F02F			AEB784	ldx menuNumber
$F032			9DCF86	sta DM_MseOnEntry,x
$F035			2016F1	jsr DM_GetEntryInfo

$F038			2404	bit r1L
$F03A			3041	bmi DM_OpenNxMenu
$F03C			7035	bvs DM_OpenDynMenu

$F03E			ADB384	lda selectionFlash			;DM_ExecUsrJob
$F041			8502	sta r0L
$F043			A900	lda #$00
$F045			8503	sta r0H
$F047			207ACC	jsr xSleep
$F04A			2091F0	jsr DM_EntryRange
$F04D			202BF1	jsr InvertMenuArea
$F050			ADB384	lda selectionFlash
$F053			8502	sta r0L
$F055			A900	lda #$00
$F057			8503	sta r0H
$F059			207ACC	jsr xSleep
$F05C			2091F0	jsr DM_EntryRange
$F05F			202BF1	jsr InvertMenuArea
$F062			2091F0	jsr DM_EntryRange

$F065			AEB784	ldx menuNumber
$F068			BDCF86	lda DM_MseOnEntry,x
$F06B			48	pha
$F06C			2016F1	jsr DM_GetEntryInfo
$F06F			68	pla
$F070			6C0200	jmp (r0)

$F073			2083F0	jsr DM_GotoUsrAdr			;DM_OpenDynMenu
$F076			A502	lda r0L
$F078			0503	ora r0H
$F07A			D001	bne $F07D
$F07C			60	rts

$F07D			EEB784	inc menuNumber			;DM_OpenNxMenu
$F080			4C43ED	jmp DM_OpenMenu

$F083			AEB784	ldx menuNumber			;DM_GotoUsrAdr
$F086			BDCF86	lda DM_MseOnEntry,x
$F089			48	pha
$F08A			2016F1	jsr DM_GetEntryInfo
$F08D			68	pla
$F08E			6C0200	jmp (r0)

$F091			ADC086	lda DM_MenuType			;DM_EntryRange
$F094			291F	and #%00011111
$F096			A8	tay
$F097			ADC086	lda DM_MenuType
$F09A			303E	bmi $F0DA

$F09C			88	dey
$F09D			A53B	lda mouseXPos+1
$F09F			D9E286	cmp DM_MenuPosH,y
$F0A2			D005	bne $F0A9
$F0A4			A53A	lda mouseXPos
$F0A6			D9D386	cmp DM_MenuPosL,y
$F0A9			90F1	bcc $F09C

$F0AB			C8	iny
$F0AC			B9D386	lda DM_MenuPosL,y
$F0AF			850A	sta r4L
$F0B1			B9E286	lda DM_MenuPosH,y
$F0B4			850B	sta r4H
$F0B6			88	dey
$F0B7			B9D386	lda DM_MenuPosL,y
$F0BA			8508	sta r3L
$F0BC			B9E286	lda DM_MenuPosH,y
$F0BF			8509	sta r3H
$F0C1			8414	sty r9L
$F0C3			C000	cpy #$00
$F0C5			D006	bne $F0CD
$F0C7			E608	inc r3L
$F0C9			D002	bne $F0CD
$F0CB			E609	inc r3H
$F0CD			AEC186	ldx DM_MenuRange+0
$F0D0			E8	inx
$F0D1			8606	stx r2L
$F0D3			AEC286	ldx DM_MenuRange+1
$F0D6			CA	dex
$F0D7			8607	stx r2H
$F0D9			60	rts

$F0DA			A53C	lda mouseYPos
$F0DC			88	dey
$F0DD			D9D386	cmp DM_MenuPosL,y
$F0E0			90FA	bcc $F0DC

$F0E2			C8	iny
$F0E3			B9D386	lda DM_MenuPosL,y
$F0E6			8507	sta r2H
$F0E8			88	dey
$F0E9			B9D386	lda DM_MenuPosL,y
$F0EC			8506	sta r2L
$F0EE			8414	sty r9L
$F0F0			C000	cpy #$00
$F0F2			D002	bne $F0F6
$F0F4			E606	inc r2L
$F0F6			ADC486	lda DM_MenuRange+3
$F0F9			8509	sta r3H
$F0FB			ADC386	lda DM_MenuRange+2
$F0FE			8508	sta r3L
$F100			E608	inc r3L
$F102			D002	bne $F106
$F104			E609	inc r3H
$F106			ADC686	lda DM_MenuRange+5
$F109			850B	sta r4H
$F10B			ADC586	lda DM_MenuRange+4
$F10E			850A	sta r4L
$F110			A20A	ldx #r4L
$F112			2075C1	jsr Ddec
$F115			60	rts

$F116			2029EE	jsr DM_VecToEntry			;DM_GetEntryInfo
$F119			C8	iny
$F11A			C8	iny
$F11B			B102	lda (r0L),y
$F11D			8504	sta r1L
$F11F			C8	iny
$F120			B102	lda (r0L),y
$F122			AA	tax
$F123			C8	iny
$F124			B102	lda (r0L),y
$F126			8503	sta r0H
$F128			8602	stx r0L
$F12A			60	rts

$F12B			A52F	lda dispBufferOn			;InvertMenuArea
$F12D			48	pha
$F12E			A980	lda #$80
$F130			852F	sta dispBufferOn
$F132			206CC8	jsr xInvertRectangle
$F135			68	pla
$F136			852F	sta dispBufferOn
$F138			60	rts

$F139			A209	ldx #$09			;DM_SvFntData
$F13B			B525	lda baselineOffset-1,x
$F13D			9D0B85	sta saveFontTab   -1,x
$F140			CA	dex
$F141			D0F8	bne $F13B
$F143			60	rts

$F144			A209	ldx #$09			;DM_LdFntData
$F146			BD0B85	lda saveFontTab   -1,x
$F149			9525	sta baselineOffset-1,x
$F14B			CA	dex
$F14C			D0F8	bne $F146
$F14E			60	rts

$F14F			A503	lda r0H			;xDoIcons
$F151			8540	sta DI_VecDefTab+1
$F153			A502	lda r0L
$F155			853F	sta DI_VecDefTab+0
$F157			20A5F1	jsr DI_DrawIcons
$F15A			2082F1	jsr SetMseFullWin
$F15D			A530	lda mouseOn
$F15F			2980	and #%10000000
$F161			D006	bne $F169
$F163			A530	lda mouseOn
$F165			29BF	and #%10111111
$F167			8530	sta mouseOn
$F169			A530	lda mouseOn
$F16B			0920	ora #%00100000
$F16D			8530	sta mouseOn
$F16F			A001	ldy #$01
$F171			B13F	lda (DI_VecDefTab),y
$F173			8518	sta r11L
$F175			C8	iny
$F176			B13F	lda (DI_VecDefTab),y
$F178			8519	sta r11H
$F17A			C8	iny
$F17B			B13F	lda (DI_VecDefTab),y
$F17D			A8	tay
$F17E			38	sec
$F17F			4CA1EB	jmp xStartMouseMode

$F182			A900	lda #$00			;SetMseFullWin
$F184			8DBA84	sta mouseLeft
$F187			8DBB84	sta mouseLeft+1
$F18A			8DB884	sta mouseTop
$F18D			A901	lda #$01
$F18F			8DBD84	sta mouseRight+1
$F192			A93F	lda #$3F
$F194			8DBC84	sta mouseRight
$F197			A9C7	lda #$C7
$F199			8DB984	sta mouseBottom
$F19C			60	rts

$F19D			0A	asl 			;DI_SetToEntry
$F19E			0A	asl
$F19F			0A	asl
$F1A0			18	clc
$F1A1			6904	adc #$04
$F1A3			A8	tay
$F1A4			60	rts

$F1A5			A900	lda #$00			;DI_DrawIcons
$F1A7			8516	sta r10L
$F1A9			A516	lda r10L
$F1AB			209DF1	jsr DI_SetToEntry
$F1AE			A200	ldx #$00
$F1B0			B13F	lda (DI_VecDefTab),y
$F1B2			9502	sta r0L,x
$F1B4			C8	iny
$F1B5			E8	inx
$F1B6			E006	cpx #$06
$F1B8			D0F6	bne $F1B0
$F1BA			A502	lda r0L
$F1BC			0503	ora r0H
$F1BE			F003	beq $F1C3
$F1C0			202DE4	jsr xBitmapUp
$F1C3			E616	inc r10L
$F1C5			A516	lda r10L
$F1C7			A000	ldy #$00
$F1C9			D13F	cmp (DI_VecDefTab),y
$F1CB			D0DC	bne $F1A9
$F1CD			60	rts

$F1CE			A540	lda DI_VecDefTab+1			;DI_ChkMseClk
$F1D0			F005	beq $F1D7
$F1D2			2043F2	jsr DI_GetSlctIcon
$F1D5			B009	bcs $F1E0
$F1D7			ADA984	lda otherPressVec+0
$F1DA			AEAA84	ldx otherPressVec+1
$F1DD			4CD8C1	jmp CallRoutine

$F1E0			AD0888	lda DI_VecToEntry
$F1E3			D05D	bne $F242
$F1E5			A502	lda r0L
$F1E7			8D0988	sta DI_SelectedIcon
$F1EA			8C0888	sty DI_VecToEntry
$F1ED			A9C0	lda #$C0
$F1EF			2CB584	bit iconSelFlag
$F1F2			F024	beq $F218
$F1F4			3002	bmi $F1F8
$F1F6			701A	bvs $F212

$F1F8			2083F2	jsr DI_GetIconSize
$F1FB			202BF1	jsr InvertMenuArea
$F1FE			ADB384	lda selectionFlash
$F201			8502	sta r0L
$F203			A900	lda #$00
$F205			8503	sta r0H
$F207			207ACC	jsr xSleep
$F20A			AD0988	lda DI_SelectedIcon
$F20D			8502	sta r0L
$F20F			AC0888	ldy DI_VecToEntry
$F212			2083F2	jsr DI_GetIconSize
$F215			202BF1	jsr InvertMenuArea
$F218			A01E	ldy #$1E
$F21A			A200	ldx #$00
$F21C			AD1585	lda dblClickCount
$F21F			F004	beq $F225
$F221			A2FF	ldx #$FF
$F223			A000	ldy #$00
$F225			8C1585	sty dblClickCount
$F228			8603	stx r0H
$F22A			AD0988	lda DI_SelectedIcon
$F22D			8502	sta r0L
$F22F			AC0888	ldy DI_VecToEntry
$F232			A200	ldx #$00
$F234			8E0888	stx DI_VecToEntry
$F237			C8	iny
$F238			C8	iny
$F239			B13F	lda (DI_VecDefTab),y
$F23B			AA	tax
$F23C			88	dey
$F23D			B13F	lda (DI_VecDefTab),y
$F23F			20D8C1	jsr CallRoutine
$F242			60	rts

$F243			A900	lda #$00			;DI_GetSlctIcon
$F245			8502	sta r0L
$F247			A502	lda r0L
$F249			209DF1	jsr DI_SetToEntry
$F24C			B13F	lda (DI_VecDefTab),y
$F24E			C8	iny
$F24F			113F	ora (DI_VecDefTab),y
$F251			F022	beq $F275
$F253			C8	iny
$F254			A53B	lda mouseXPos+1
$F256			4A	lsr
$F257			A53A	lda mouseXPos
$F259			6A	ror
$F25A			4A	lsr
$F25B			4A	lsr
$F25C			38	sec
$F25D			F13F	sbc (DI_VecDefTab),y
$F25F			9014	bcc $F275
$F261			C8	iny
$F262			C8	iny
$F263			D13F	cmp (DI_VecDefTab),y
$F265			B00E	bcs $F275
$F267			88	dey
$F268			A53C	lda mouseYPos
$F26A			38	sec
$F26B			F13F	sbc (DI_VecDefTab),y
$F26D			9006	bcc $F275
$F26F			C8	iny
$F270			C8	iny
$F271			D13F	cmp (DI_VecDefTab),y
$F273			900C	bcc $F281
$F275			E602	inc r0L
$F277			A502	lda r0L
$F279			A000	ldy #$00
$F27B			D13F	cmp (DI_VecDefTab),y
$F27D			D0C8	bne $F247
$F27F			18	clc
$F280			60	rts
$F281			38	sec
$F282			60	rts

$F283			B13F	lda (DI_VecDefTab),y			;DI_GetIconSize
$F285			88	dey
$F286			88	dey
$F287			18	clc
$F288			713F	adc (DI_VecDefTab),y
$F28A			38	sec
$F28B			E901	sbc #$01
$F28D			8507	sta r2H
$F28F			B13F	lda (DI_VecDefTab),y
$F291			8506	sta r2L
$F293			88	dey
$F294			B13F	lda (DI_VecDefTab),y
$F296			8508	sta r3L
$F298			C8	iny
$F299			C8	iny
$F29A			18	clc
$F29B			713F	adc (DI_VecDefTab),y
$F29D			850A	sta r4L
$F29F			A900	lda #$00
$F2A1			8509	sta r3H
$F2A3			850B	sta r4H

$F2A5			A003	ldy #$03
$F2A7			A208	ldx #$08
$F2A9			205DC1	jsr DShiftLeft
$F2AC			A003	ldy #$03
$F2AE			A20A	ldx #r4L
$F2B0			205DC1	jsr DShiftLeft
$F2B3			A20A	ldx #r4L
$F2B5			2075C1	jsr Ddec
$F2B8			60	rts

$F2B9			A503	lda r0H			;xDoDlgBox
$F2BB			8544	sta DB_VecDefTab+1
$F2BD			A502	lda r0L
$F2BF			8543	sta DB_VecDefTab+0

$F2C1			A200	ldx #$00
$F2C3			B50C	lda r5L,x
$F2C5			48	pha
$F2C6			E8	inx
$F2C7			E00C	cpx #$0C
$F2C9			D0F8	bne $F2C3

$F2CB			2063F3	jsr InitDB_Box1
$F2CE			2086F3	jsr DB_DrawBox

$F2D1			A900	lda #$00
$F2D3			8519	sta r11H
$F2D5			A900	lda #$00
$F2D7			8518	sta r11L

$F2D9			20A1EB	jsr xStartMouseMode
$F2DC			20A4E6	jsr xUseSystemFont

$F2DF			A20B	ldx #$0B
$F2E1			68	pla
$F2E2			950C	sta r5L,x
$F2E4			CA	dex
$F2E5			10FA	bpl $F2E1

$F2E7			A000	ldy #$00
$F2E9			A207	ldx #$07
$F2EB			B143	lda (DB_VecDefTab),y
$F2ED			1002	bpl $F2F1
$F2EF			A201	ldx #$01

$F2F1			8A	txa
$F2F2			A8	tay
$F2F3			B143	lda (DB_VecDefTab),y
$F2F5			8502	sta r0L
$F2F7			F025	beq StartDB_Box

$F2F9			A200	ldx #$00
$F2FB			B50C	lda r5L,x
$F2FD			48	pha
$F2FE			E8	inx
$F2FF			E00C	cpx #$0C
$F301			D0F8	bne $F2FB

$F303			C8	iny
$F304			8404	sty r1L

$F306			A402	ldy r0L
$F308			B93CF3	lda DB_BoxCTabL -1,y
$F30B			BE4FF3	ldx DB_BoxCTabH -1,y
$F30E			20D8C1	jsr CallRoutine

$F311			A20B	ldx #$0B
$F313			68	pla
$F314			950C	sta r5L,x
$F316			CA	dex
$F317			10FA	bpl $F313

$F319			A404	ldy r1L
$F31B			B8	clv
$F31C			50D5	bvc $F2F3

$F31E			AD0C88	lda DB_Icon_Tab			;StartDB_Box
$F321			F00B	beq $F32E
$F323			A988	lda #>DB_Icon_Tab
$F325			8503	sta r0H
$F327			A90C	lda #<DB_Icon_Tab
$F329			8502	sta r0L
$F32B			205AC1	jsr DoIcons

$F32E			68	pla
$F32F			8D5388	sta DB_ReturnAdr+0
$F332			68	pla
$F333			8D5488	sta DB_ReturnAdr+1
$F336			BA	tsx
$F337			8E5588	stx DB_RetStackP
$F33A			4CC3C1	jmp MainLoop

$F33D			CDCDCDCDb <DB_SysIcon  , <DB_SysIcon, <DB_SysIcon  , <DB_SysIcon
$F341			CDCDCDCDb <DB_SysIcon  , <DB_SysIcon, $cd          , $cd
$F345			CDCD021Cb $cd          , $cd        , <DB_TextStrg , <DB_VarTxtStrg
$F349			38AED788b <DB_GetString, <DB_SysOpV , <DB_GraphStrg, <DB_GetFiles
$F34D			C6F7EC	b <DB_OpVec    , <DB_UsrIcon, <DB_UserRout

$F350			F4F4F4F4b >DB_SysIcon  , >DB_SysIcon, >DB_SysIcon  , >DB_SysIcon
$F354			F4F4CDCDb >DB_SysIcon  , >DB_SysIcon, $cd          , $cd
$F358			CDCDF6F6b $cd          , $cd        , >DB_TextStrg , >DB_VarTxtStrg
$F35C			F6F5F5F6b >DB_GetString, >DB_SysOpV , >DB_GraphStrg, >DB_GetFiles
$F360			F5F4F5	b >DB_OpVec    , >DB_UsrIcon, >DB_UserRout

$F363			A501	lda CPU_DATA
$F365			48	pha
$F366			A935	lda #$35
$F368			8501	sta CPU_DATA

$F36A			A985	lda #>dlgBoxRamBuf
$F36C			850B	sta r4H
$F36E			A91F	lda #<dlgBoxRamBuf
$F370			850A	sta r4L
$F372			2057F4	jsr DB_SvGeosVar

$F375			A901	lda #$01
$F377			8D15D0	sta mobenble

$F37A			68	pla
$F37B			8501	sta CPU_DATA
$F37D			200DC4	jsr GEOS_Init2
$F380			A900	lda #$00
$F382			8D1D85	sta sysDBData
$F385			60	rts

$F386			A9A0	lda #$A0			;DB_DrawBox
$F388			852F	sta dispBufferOn

$F38A			A000	ldy #$00
$F38C			B143	lda (DB_VecDefTab),y
$F38E			291F	and #%00011111
$F390			F00A	beq $F39C
$F392			2039C1	jsr SetPattern
$F395			38	sec
$F396			20D8F3	jsr DB_DefBoxPos
$F399			2024C1	jsr Rectangle

$F39C			A900	lda #$00
$F39E			2039C1	jsr SetPattern
$F3A1			18	clc
$F3A2			20D8F3	jsr DB_DefBoxPos
$F3A5			A50B	lda r4H
$F3A7			8538	sta rightMargin+1
$F3A9			A50A	lda r4L
$F3AB			8537	sta rightMargin
$F3AD			2024C1	jsr Rectangle
$F3B0			18	clc
$F3B1			20D8F3	jsr DB_DefBoxPos
$F3B4			A9FF	lda #$FF
$F3B6			2027C1	jsr FrameRectangle
$F3B9			A900	lda #$00
$F3BB			8D0C88	sta DB_Icon_Tab+0
$F3BE			8D0D88	sta DB_Icon_Tab+1
$F3C1			8D0E88	sta DB_Icon_Tab+2
$F3C4			60	rts

$F3C5			A000	ldy #$00			;ClearDB_Box
$F3C7			B143	lda (DB_VecDefTab),y
$F3C9			291F	and #%00011111
$F3CB			F004	beq $F3D1
$F3CD			38	sec
$F3CE			20D2F3	jsr ClrBoxArea
$F3D1			18	clc
$F3D2			20D8F3	jsr DB_DefBoxPos			;ClrBoxArea
$F3D5			4C9FEF	jmp RecoverDB_Box

$F3D8			A900	lda #$00			;DB_DefBoxPos
$F3DA			9002	bcc $F3DE
$F3DC			A908	lda #$08
$F3DE			8505	sta r1H

$F3E0			A544	lda DB_VecDefTab+1
$F3E2			48	pha
$F3E3			A543	lda DB_VecDefTab+0
$F3E5			48	pha

$F3E6			A000	ldy #$00
$F3E8			B143	lda (DB_VecDefTab),y
$F3EA			1008	bpl $F3F4

$F3EC			A9F4	lda #>StdDB_BoxPos -1
$F3EE			8544	sta DB_VecDefTab+1
$F3F0			A922	lda #<StdDB_BoxPos -1
$F3F2			8543	sta DB_VecDefTab+0

$F3F4			A200	ldx #$00
$F3F6			A001	ldy #$01
$F3F8			B143	lda (DB_VecDefTab),y
$F3FA			18	clc
$F3FB			6505	adc r1H
$F3FD			9506	sta r2L,x
$F3FF			C8	iny
$F400			E8	inx
$F401			E002	cpx #$02
$F403			D0F3	bne $F3F8

$F405			B143	lda (DB_VecDefTab),y
$F407			18	clc
$F408			6505	adc r1H
$F40A			9506	sta r2L,x
$F40C			C8	iny
$F40D			E8	inx
$F40E			B143	lda (DB_VecDefTab),y
$F410			9002	bcc $F414
$F412			6900	adc #$00
$F414			9506	sta r2L,x
$F416			C8	iny
$F417			E8	inx
$F418			E006	cpx #$06
$F41A			D0E9	bne $F405

$F41C			68	pla
$F41D			8543	sta DB_VecDefTab+0
$F41F			68	pla
$F420			8544	sta DB_VecDefTab+1
$F422			60	rts

$F423			207F	b $20,$7F			;StdDB_BoxPos
$F426			4000FF00w $0040,$00FF

$F42A			2041F4	jsr InitDB_Box2			;xRstrFrmDialogue
$F42C			20C5F3	jsr ClearDB_Box
$F42F			AD1D85	lda sysDBData
$F432			8502	sta r0L
$F434			AE5588	ldx DB_RetStackP
$F437			9A	txs
$F438			AD5488	lda DB_ReturnAdr+1
$F43B			48	pha
$F43C			AD5388	lda DB_ReturnAdr+0
$F43F			48	pha
$F440			60	rts

$F441			A501	lda CPU_DATA			;InitDB_Box2
$F443			48	pha
$F444			A935	lda #$35
$F446			8501	sta CPU_DATA

$F448			A985	lda #>dlgBoxRamBuf
$F44A			850B	sta r4H
$F44C			A91F	lda #<dlgBoxRamBuf
$F44E			850A	sta r4L
$F450			206CF4	jsr DB_LdGeosVar

$F453			68	pla
$F454			8501	sta CPU_DATA
$F456			60	rts

$F457			A200	ldx #$00			;DB_SvGeosVar
$F459			A000	ldy #$00
$F45B			2084F4	jsr DB_SetMemVec
$F45E			F00B	beq $F46B
$F460			B106	lda (r2L),y
$F462			910A	sta (r4L),y
$F464			C8	iny
$F465			C608	dec r3L
$F467			D0F7	bne $F460
$F469			F0F0	beq $F45B
$F46B			60	rts

$F46C			08	php 			;DB_LdGeosVar
$F46D			78	sei
$F46E			A200	ldx #$00
$F470			A000	ldy #$00
$F472			2084F4	jsr DB_SetMemVec
$F475			F00B	beq $F482
$F477			B10A	lda (r4L),y
$F479			9106	sta (r2L),y
$F47B			C8	iny
$F47C			C608	dec r3L
$F47E			D0F7	bne $F477
$F480			F0F0	beq $F472
$F482			28	plp
$F483			60	rts

$F484			98	tya 			;DB_SetMemVec
$F485			18	clc
$F486			650A	adc r4L
$F488			850A	sta r4L
$F48A			9002	bcc $F48E
$F48C			E60B	inc r4H

$F48E			A000	ldy #$00
$F490			BDA7F4	lda DB_SaveMemTab,x
$F493			8506	sta r2L
$F495			E8	inx
$F496			BDA7F4	lda DB_SaveMemTab,x
$F499			8507	sta r2H
$F49B			E8	inx
$F49C			0506	ora r2L
$F49E			F006	beq $F4A6
$F4A0			BDA7F4	lda DB_SaveMemTab,x
$F4A3			8508	sta r3L
$F4A5			E8	inx
$F4A6			60	rts

$F4A7			2200	w curPattern
$F4A9			17	b $17
$F4AA			9B84	w appMain
$F4AC			26	b $26
$F4AD			3F00	w DI_VecDefTab
$F4AF			02	b $02
$F4B0			C086	w DM_MenuType
$F4B2			31	b $31
$F4B3			F186	w ProcCurDelay
$F4B5			E3	b $E3
$F4B6			F88F	w obj0Pointer
$F4B8			08	b $08
$F4B9			00D0	w mob0xpos
$F4BB			11	b $11
$F4BC			15D0	w mobenble
$F4BE			01	b $01
$F4BF			D01B	w mobprior
$F4C1			03	b $03
$F4C2			25D0	w mcmclr0
$F4C4			02	b $02
$F4C5			28D0	w mob1clr
$F4C7			07	b $07
$F4C8			17D0	w moby2
$F4CA			01	b $01
$F4CB			0000	w zPage+0

$F4CD			88	dey 			;DB_SysIcon
$F4CE			D012	bne $F4E2
$F4D0			ADA384	lda keyVector+0
$F4D3			0DA484	ora keyVector+1
$F4D6			D00A	bne $F4E2
$F4D8			A9F5	lda #>DB_ChkEnter
$F4DA			8DA484	sta keyVector+1
$F4DD			A988	lda #<DB_ChkEnter
$F4DF			8DA384	sta keyVector+0
$F4E2			98	tya
$F4E3			0A	asl
$F4E4			0A	asl
$F4E5			0A	asl
$F4E6			18	clc
$F4E7			6958	adc #<SysIconTab
$F4E9			850C	sta r5L
$F4EB			A900	lda #$00
$F4ED			69F5	adc #>SysIconTab
$F4EF			850D	sta r5H
$F4F1			200DF5	jsr DB_DefIconPos
$F4F4			4C2EF5	jmp DB_CopyIconInTab

$F4F7			200DF5	jsr DB_DefIconPos			;DB_UsrIcon
$F4FA			B143	lda (DB_VecDefTab),y
$F4FC			850C	sta r5L
$F4FE			C8	iny
$F4FF			B143	lda (DB_VecDefTab),y
$F501			850D	sta r5H
$F503			C8	iny
$F504			98	tya
$F505			48	pha
$F506			202EF5	jsr DB_CopyIconInTab
$F509			68	pla
$F50A			8504	sta r1L
$F50C			60	rts

$F50D			18	clc 			;DB_DefIconPos
$F50E			20D8F3	jsr DB_DefBoxPos
$F511			4609	lsr r3H
$F513			6608	ror r3L
$F515			4608	lsr r3L
$F517			4608	lsr r3L
$F519			A404	ldy r1L
$F51B			B143	lda (DB_VecDefTab),y
$F51D			18	clc
$F51E			6508	adc r3L
$F520			8508	sta r3L
$F522			C8	iny
$F523			B143	lda (DB_VecDefTab),y
$F525			18	clc
$F526			6506	adc r2L
$F528			8506	sta r2L
$F52A			C8	iny
$F52B			8404	sty r1L
$F52D			60	rts

$F52E			AE0C88	ldx DB_Icon_Tab			;DB_CopyIconInTab
$F531			E008	cpx #$08
$F533			B022	bcs $F557
$F535			8A	txa
$F536			E8	inx
$F537			8E0C88	stx DB_Icon_Tab
$F53A			209DF1	jsr DI_SetToEntry
$F53D			AA	tax
$F53E			A000	ldy #$00
$F540			B10C	lda (r5L),y
$F542			C002	cpy #$02
$F544			D002	bne $F548
$F546			A508	lda r3L
$F548			C003	cpy #$03
$F54A			D002	bne $F54E
$F54C			A506	lda r2L
$F54E			9D0C88	sta DB_Icon_Tab,x
$F551			E8	inx
$F552			C8	iny
$F553			C008	cpy #$08
$F555			D0E9	bne $F540
$F557			60	rts

$F558			A9BF	w $BFA9
$F558			00000610b $00,$00,$06,$10
$F558			90F5	w DB_Icon_OK

$F558			58BF	w $BF58
$F558			00000610b $00,$00,$06,$10
$F558			94F5	w DB_Icon_CANCEL

$F558			6FF9	w Icon_YES
$F558			00000610b $00,$00,$06,$10
$F558			98F5	w DB_Icon_YES

$F558			1DF9	w Icon_NO
$F558			00000610b $00,$00,$06,$10
$F558			9CF5	w DB_Icon_NO

$F558			C1F9	w Icon_OPEN
$F558			00000610b $00,$00,$06,$10
$F558			A0F5	w DB_Icon_OPEN

$F558			14FA	w Icon_DISK
$F558			00000610b $00,$00,$06,$10
$F558			A4F5	w DB_Icon_DISK

$F588			AD0485	lda keyData			;DB_ChkEnter
$F58B			C90D	cmp #$0D
$F58D			F001	beq $F590
$F58F			60	rts

$F590			A901	lda #$01			;DB_Icon_OK
$F592			D014	bne $F5A8
$F594			A902	lda #$02			;DB_Icon_CANCEL
$F596			D010	bne $F5A8
$F598			A903	lda #$03			;DB_Icon_YES
$F59A			D00C	bne $F5A8
$F59C			A904	lda #$04			;DB_Icon_NO
$F59E			D008	bne $F5A8
$F5A0			A905	lda #$05			;DB_Icon_OPEN
$F5A2			D004	bne $F5A8
$F5A4			A906	lda #$06			;DB_Icon_DISK
$F5A6			D000	bne $F5A8
$F5A8			8D1D85	sta sysDBData
$F5AB			4CBFC2	jmp RstrFromDialogue

$F5AE			A9F5	lda #>DB_ChkSysOpV			;DB_SysOpV
$F5B0			8DAA84	sta otherPressVec+1
$F5B3			A9B9	lda #<DB_ChkSysOpV
$F5B5			8DA984	sta otherPressVec+0
$F5B8			60	rts

$F5B9			2C0585	bit mouseData			;DB_ChkSysOpV
$F5BC			3018	bmi DB_NoFunc
$F5BE			A90E	lda #$0E
$F5C0			8D1D85	sta sysDBData
$F5C3			4CBFC2	jmp RstrFromDialogue

$F5C6			A404	ldy r1L			;DB_OpVec
$F5C8			B143	lda (DB_VecDefTab),y
$F5CA			8DA984	sta otherPressVec+0
$F5CD			C8	iny
$F5CE			B143	lda (DB_VecDefTab),y
$F5D0			8DAA84	sta otherPressVec+1
$F5D3			C8	iny
$F5D4			8404	sty r1L
$F5D6			60	rts

$F5D7			A404	ldy r1L			;DB_GraphStrg
$F5D9			B143	lda (DB_VecDefTab),y
$F5DB			8502	sta r0L
$F5DD			C8	iny
$F5DE			B143	lda (DB_VecDefTab),y
$F5E0			8503	sta r0H
$F5E2			C8	iny
$F5E3			98	tya
$F5E4			48	pha
$F5E5			2036C1	jsr GraphicsString
$F5E8			68	pla
$F5E9			8504	sta r1L
$F5EB			60	rts

$F5EC			A404	ldy r1L			;DB_UserRout
$F5EE			B143	lda (DB_VecDefTab),y
$F5F0			8502	sta r0L
$F5F2			C8	iny
$F5F3			B143	lda (DB_VecDefTab),y
$F5F5			AA	tax
$F5F6			C8	iny
$F5F7			98	tya
$F5F8			48	pha
$F5F9			A502	lda r0L
$F5FB			20D8C1	jsr CallRoutine
$F5FE			68	pla
$F5FF			8504	sta r1L
$F601			60	rts

$F602			18	clc 			;DB_TextStrg
$F603			20D8F3	jsr DB_DefBoxPos
$F606			206FF6	jsr DB_GetTextPos
$F609			B143	lda (DB_VecDefTab),y
$F60B			8502	sta r0L
$F60D			C8	iny
$F60E			B143	lda (DB_VecDefTab),y
$F610			8503	sta r0H
$F612			C8	iny
$F613			98	tya
$F614			48	pha
$F615			2048C1	jsr PutString
$F618			68	pla
$F619			8504	sta r1L
$F61B			60	rts

$F61C			18	clc 			;DB_VarTxtStrg
$F61D			20D8F3	jsr DB_DefBoxPos
$F620			206FF6	jsr DB_GetTextPos
$F623			B143	lda (DB_VecDefTab),y
$F625			C8	iny
$F626			AA	tax
$F627			B500	lda zPage+0,x
$F629			8502	sta r0L
$F62B			B501	lda zPage+1,x
$F62D			8503	sta r0H
$F62F			98	tya
$F630			48	pha
$F631			2048C1	jsr PutString
$F634			68	pla
$F635			8504	sta r1L
$F637			60	rts

$F638			18	clc 			;DB_GetString
$F639			20D8F3	jsr DB_DefBoxPos
$F63C			206FF6	jsr DB_GetTextPos

$F63F			B143	lda (DB_VecDefTab),y
$F641			C8	iny
$F642			AA	tax
$F643			B500	lda zPage+0,x
$F645			8502	sta r0L
$F647			B501	lda zPage+1,x
$F649			8503	sta r0H
$F64B			B143	lda (DB_VecDefTab),y
$F64D			8506	sta r2L
$F64F			C8	iny
$F650			A9F6	lda #>DB_EndGetStrg
$F652			8DA484	sta keyVector+1
$F655			A967	lda #<DB_EndGetStrg
$F657			8DA384	sta keyVector

$F65A			A900	lda #$00
$F65C			8504	sta r1L
$F65E			98	tya
$F65F			48	pha
$F660			20BAC1	jsr GetString
$F663			68	pla
$F664			8504	sta r1L
$F666			60	rts

$F667			A90D	lda #$0D			;DB_EndGetStrg
$F669			8D1D85	sta sysDBData
$F66C			4CBFC2	jmp RstrFromDialogue

$F66F			A404	ldy r1L			;DB_GetTextPos
$F671			B143	lda (DB_VecDefTab),y
$F673			18	clc
$F674			6508	adc r3L
$F676			8518	sta r11L
$F678			A509	lda r3H
$F67A			6900	adc #$00
$F67C			8519	sta r11H
$F67E			C8	iny
$F67F			B143	lda (DB_VecDefTab),y
$F681			C8	iny
$F682			18	clc
$F683			6506	adc r2L
$F685			8505	sta r1H
$F687			60	rts

$F688			A404	ldy r1L			;DB_GetFiles
$F68A			B143	lda (DB_VecDefTab),y
$F68C			8D5788	sta DB_GetFileX
$F68F			C8	iny
$F690			B143	lda (DB_VecDefTab),y
$F692			8D5888	sta DB_GetFileY

$F695			C8	iny
$F696			98	tya
$F697			48	pha
$F698			A50D	lda r5H
$F69A			8D5A88	sta DB_FileTabVec+1
$F69D			A50C	lda r5L
$F69F			8D5988	sta DB_FileTabVec+0

$F6A2			20C9F8	jsr DB_FileWinPos

$F6A5			A509	lda r3H
$F6A7			6A	ror
$F6A8			A508	lda r3L
$F6AA			6A	ror
$F6AB			4A	lsr
$F6AC			4A	lsr
$F6AD			18	clc
$F6AE			6907	adc #$07
$F6B0			48	pha

$F6B1			A507	lda r2H
$F6B3			38	sec
$F6B4			E90E	sbc #$0E
$F6B6			48	pha

$F6B7			A510	lda r7L
$F6B9			48	pha

$F6BA			A517	lda r10H
$F6BC			48	pha
$F6BD			A516	lda r10L
$F6BF			48	pha

$F6C0			A9FF	lda #$FF
$F6C2			2027C1	jsr FrameRectangle

$F6C5			38	sec
$F6C6			A507	lda r2H
$F6C8			E910	sbc #$10
$F6CA			8518	sta r11L
$F6CC			A9FF	lda #$FF
$F6CE			2018C1	jsr HorizontalLine

$F6D1			68	pla
$F6D2			8516	sta r10L
$F6D4			68	pla
$F6D5			8517	sta r10H
$F6D7			68	pla
$F6D8			8510	sta r7L

$F6DA			A90F	lda #$0F
$F6DC			8511	sta r7H

$F6DE			A983	lda #>fileTrScTab
$F6E0			850F	sta r6H
$F6E2			A900	lda #<fileTrScTab
$F6E4			850E	sta r6L
$F6E6			203BC2	jsr FindFTypes
$F6E9			68	pla
$F6EA			8506	sta r2L
$F6EC			68	pla
$F6ED			8508	sta r3L
$F6EF			8D4FF7	sta DB_GetFileIcon+2
$F6F2			A90F	lda #$0F
$F6F4			38	sec
$F6F5			E511	sbc r7H
$F6F7			F025	beq $F71E
$F6F9			8D5688	sta DB_FilesInTab
$F6FC			C906	cmp #$06
$F6FE			900B	bcc $F70B
$F700			A9F7	lda #>DB_GetFileIcon
$F702			850D	sta r5H
$F704			A94D	lda #<DB_GetFileIcon
$F706			850C	sta r5L
$F708			202EF5	jsr DB_CopyIconInTab

$F70B			A9F7	lda #>DB_SlctNewFile
$F70D			8DAA84	sta otherPressVec+1
$F710			A978	lda #<DB_SlctNewFile
$F712			8DA984	sta otherPressVec+0

$F715			2022F7	jsr DB_FindFileInTab
$F718			2053F8	jsr DB_PutFileNames
$F71B			2019F8	jsr DB_FileInBuf
$F71E			68	pla
$F71F			8504	sta r1L
$F721			60	rts

$F722			AD5688	lda DB_FilesInTab			;DB_FindFileInTab
$F725			48	pha
$F726			68	pla
$F727			38	sec
$F728			E901	sbc #$01
$F72A			48	pha
$F72B			F011	beq $F73E
$F72D			2024F8	jsr DB_SetCmpVec

$F730			A000	ldy #$00
$F732			B102	lda (r0L),y
$F734			D104	cmp (r1L),y
$F736			D0EE	bne $F726
$F738			AA	tax
$F739			F003	beq $F73E
$F73B			C8	iny
$F73C			D0F4	bne $F732

$F73E			68	pla
$F73F			8D5C88	sta DB_SelectedFile
$F742			38	sec
$F743			E904	sbc #$04
$F745			1002	bpl $F749
$F747			A900	lda #$00
$F749			8D5B88	sta DB_1stFileInTab
$F74C			60	rts

$F74D			55F7	w DB_ArrowGrafx			;DB_GetFileIcon
$F74F			0000030Cb $00,$00,$03,$0C
$F753			C4F7	w DB_MoveFileList

$F755			03FF	b $03,%11111111;%11111111,%11111111
$F757			9E800001b $9e,%10000000,%00000000,%00000001
$F75B			800001	b     %10000000,%00000000,%00000001
$F75E			8200E1	b     %10000010,%00000000,%11100001
$F761			8707FD	b     %10000111,%00000111,%11111101
$F764			8F83F9	b     %10001111,%10000011,%11111001
$F767			9FC1F1	b     %10011111,%11000001,%11110001
$F76A			BFE0E1	b     %10111111,%11100000,%11100001
$F76D			870041	b     %10000111,%00000000,%01000001
$F770			800001	b     %10000000,%00000000,%00000001
$F773			800001	b     %10000000,%00000000,%00000001
$F776			03FF	b $03,%11111111;%11111111,%11111111

$F778			AD0585	lda mouseData			;DB_SlctNewFile
$F77B			3046	bmi $F7C3
$F77D			20C9F8	jsr DB_FileWinPos
$F780			18	clc
$F781			A506	lda r2L
$F783			6945	adc #$45
$F785			8507	sta r2H
$F787			20B3C2	jsr IsMseInRegio
$F78A			F037	beq $F7C3
$F78C			20BCF8	jsr DB_IncSlctFile

$F78F			20C9F8	jsr DB_FileWinPos
$F792			A53C	lda mouseYPos
$F794			38	sec
$F795			E506	sbc r2L
$F797			8502	sta r0L
$F799			A900	lda #$00
$F79B			8503	sta r0H
$F79D			8505	sta r1H
$F79F			A90E	lda #$0E
$F7A1			8504	sta r1L
$F7A3			A202	ldx #r0L
$F7A5			A004	ldy #r1L
$F7A7			2069C1	jsr Ddiv

$F7AA			A502	lda r0L
$F7AC			18	clc
$F7AD			6D5B88	adc DB_1stFileInTab
$F7B0			CD5688	cmp DB_FilesInTab
$F7B3			9005	bcc $F7BA
$F7B5			AE5688	ldx DB_FilesInTab
$F7B8			CA	dex
$F7B9			8A	txa
$F7BA			8D5C88	sta DB_SelectedFile
$F7BD			20BCF8	jsr DB_IncSlctFile
$F7C0			2019F8	jsr DB_FileInBuf
$F7C3			60	rts

$F7C4			20BCF8	jsr DB_IncSlctFile			;DB_MoveFileList
$F7C7			A900	lda #$00
$F7C9			8503	sta r0H
$F7CB			AD4FF7	lda DB_GetFileIcon+2
$F7CE			0A	asl
$F7CF			0A	asl
$F7D0			0A	asl
$F7D1			2603	rol r0H
$F7D3			18	clc
$F7D4			690C	adc #$0C
$F7D6			8502	sta r0L
$F7D8			9002	bcc $F7DC
$F7DA			E603	inc r0H

$F7DC			AE5B88	ldx DB_1stFileInTab
$F7DF			A503	lda r0H
$F7E1			C53B	cmp mouseXPos+1
$F7E3			D004	bne $F7E9
$F7E5			A502	lda r0L
$F7E7			C53A	cmp mouseXPos
$F7E9			9003	bcc $F7EE
$F7EB			CA	dex
$F7EC			100C	bpl $F7FA

$F7EE			E8	inx
$F7EF			AD5688	lda DB_FilesInTab
$F7F2			38	sec
$F7F3			ED5B88	sbc DB_1stFileInTab
$F7F6			C906	cmp #$06
$F7F8			9003	bcc $F7FD

$F7FA			8E5B88	stx DB_1stFileInTab

$F7FD			AD5B88	lda DB_1stFileInTab
$F800			CD5C88	cmp DB_SelectedFile
$F803			9003	bcc $F808
$F805			8D5C88	sta DB_SelectedFile
$F808			18	clc
$F809			6904	adc #$04
$F80B			CD5C88	cmp DB_SelectedFile
$F80E			B003	bcs $F813
$F810			8D5C88	sta DB_SelectedFile
$F813			2019F8	jsr DB_FileInBuf
$F816			4C53F8	jmp DB_PutFileNames

$F819			AD5C88	lda DB_SelectedFile			;DB_FileInBuf
$F81C			2024F8	jsr DB_SetCmpVec
$F81F			A004	ldy #r1L
$F821			4C65C2	jmp CopyString

$F824			A202	ldx #r0L			;DB_SetCmpVec
$F826			2034F8	jsr DB_SetFileName
$F829			AD5A88	lda DB_FileTabVec+1
$F82C			8505	sta r1H
$F82E			AD5988	lda DB_FileTabVec+0
$F831			8504	sta r1L
$F833			60	rts

$F834			8502	sta r0L			;DB_SetFileName
$F836			A911	lda #$11
$F838			8504	sta r1L
$F83A			8A	txa
$F83B			48	pha
$F83C			A002	ldy #r0L
$F83E			A204	ldx #r1L
$F840			2060C1	jsr BBMult
$F843			68	pla
$F844			AA	tax
$F845			A504	lda r1L
$F847			18	clc
$F848			6900	adc #<fileTrScTab
$F84A			9500	sta zPage+0,x
$F84C			A983	lda #>fileTrScTab
$F84E			6900	adc #$00
$F850			9501	sta zPage+1,x
$F852			60	rts

$F853			A538	lda rightMargin+1			;DB_PutFileNames
$F855			48	pha
$F856			A537	lda rightMargin+0
$F858			48	pha

$F859			A900	lda #$00
$F85B			20F1F8	jsr DB_SetWinEntry

$F85E			A50B	lda r4H
$F860			8538	sta rightMargin+1
$F862			A50A	lda r4L
$F864			8537	sta rightMargin
$F866			A900	lda #$00
$F868			8520	sta r15L
$F86A			2039C1	jsr SetPattern

$F86D			AD5B88	lda DB_1stFileInTab
$F870			A21E	ldx #$1E
$F872			2034F8	jsr DB_SetFileName

$F875			A940	lda #$40
$F877			852E	sta currentMode

$F879			A520	lda r15L
$F87B			20F1F8	jsr DB_SetWinEntry
$F87E			2024C1	jsr Rectangle

$F881			A509	lda r3H
$F883			8519	sta r11H
$F885			A508	lda r3L
$F887			8518	sta r11L
$F889			A506	lda r2L
$F88B			18	clc
$F88C			6909	adc #$09
$F88E			8505	sta r1H
$F890			A51F	lda r14H
$F892			8503	sta r0H
$F894			A51E	lda r14L
$F896			8502	sta r0L
$F898			2048C1	jsr PutString

$F89B			18	clc
$F89C			A911	lda #$11
$F89E			651E	adc r14L
$F8A0			851E	sta r14L
$F8A2			9002	bcc $F8A6
$F8A4			E61F	inc r14H

$F8A6			E620	inc r15L
$F8A8			A520	lda r15L
$F8AA			C905	cmp #$05
$F8AC			D0CB	bne $F879

$F8AE			20BCF8	jsr DB_IncSlctFile

$F8B1			A900	lda #$00
$F8B3			852E	sta currentMode
$F8B5			68	pla
$F8B6			8537	sta rightMargin
$F8B8			68	pla
$F8B9			8538	sta rightMargin+1
$F8BB			60	rts

$F8BC			AD5C88	lda DB_SelectedFile			;DB_IncSlctFile
$F8BF			38	sec
$F8C0			ED5B88	sbc DB_1stFileInTab
$F8C3			20F1F8	jsr DB_SetWinEntry
$F8C6			4C2AC1	jmp InvertRectangle

$F8C9			18	clc 			;DB_FileWinPos
$F8CA			20D8F3	jsr DB_DefBoxPos

$F8CD			AD5788	lda DB_GetFileX
$F8D0			18	clc
$F8D1			6508	adc r3L
$F8D3			8508	sta r3L
$F8D5			9002	bcc $F8D9
$F8D7			E609	inc r3H

$F8D9			18	clc
$F8DA			697C	adc #$7C
$F8DC			850A	sta r4L
$F8DE			A900	lda #$00
$F8E0			6509	adc r3H
$F8E2			850B	sta r4H

$F8E4			AD5888	lda DB_GetFileY
$F8E7			18	clc
$F8E8			6506	adc r2L
$F8EA			8506	sta r2L
$F8EC			6958	adc #$58
$F8EE			8507	sta r2H
$F8F0			60	rts

$F8F1			8502	sta r0L			;DB_SetWinEntry
$F8F3			A90E	lda #$0E
$F8F5			8504	sta r1L
$F8F7			A004	ldy #r1L
$F8F9			A202	ldx #r0L
$F8FB			2060C1	jsr BBMult
$F8FE			20C9F8	jsr DB_FileWinPos
$F901			A502	lda r0L
$F903			18	clc
$F904			6506	adc r2L
$F906			8506	sta r2L
$F908			18	clc
$F909			690E	adc #$0E
$F90B			8507	sta r2H
$F90D			E606	inc r2L
$F90F			C607	dec r2H
$F911			E608	inc r3L
$F913			D002	bne $F917
$F915			E609	inc r3H
$F917			A20A	ldx #r4L
$F919			2075C1	jsr Ddec
$F91C			60	rts

$F91D			05FF82FEb $05,$FF,$82,$FE			;Icon_NO
$F921			80040082b $80,$04,$00,$82
$F925			03800400b $03,$80,$04,$00
$F929			B803801Cb $B8,$03,$80,$1C
$F92D			C0180003b $C0,$18,$00,$03
$F931			801CC000b $80,$1C,$C0,$00
$F935			0003801Eb $00,$03,$80,$1E
$F939			CF3BE003b $CF,$3B,$E0,$03
$F93D			801ED99Bb $80,$1E,$D9,$9B
$F941			B003801Bb $B0,$03,$80,$1B
$F945			D99B3003b $D9,$9B,$30,$03
$F949			801BDF9Bb $80,$1B,$DF,$9B
$F94D			30038019b $30,$03,$80,$19
$F951			D81B3003b $D8,$1B,$30,$03
$F955			8019D99Bb $80,$19,$D9,$9B
$F959			30038018b $30,$03,$80,$18
$F95D			CF1B3003b $CF,$1B,$30,$03
$F961			80040082b $80,$04,$00,$82
$F965			03800400b $03,$80,$04,$00
$F969			810306FFb $81,$03,$06,$FF
$F96D			817F	b $81,$7F

$F96F			05FF82FEb $05,$FF,$82,$FE			;Icon_YES
$F973			80040082b $80,$04,$00,$82
$F977			03800400b $03,$80,$04,$00
$F97B			B8038000b $B8,$03,$80,$00
$F97F			0C000003b $0C,$00,$00,$03
$F983			80000C00b $80,$00,$0C,$00
$F987			00038000b $00,$03,$80,$00
$F98B			0CF00003b $0C,$F0,$00,$03
$F98F			80000D98b $80,$00,$0D,$98
$F993			00038000b $00,$03,$80,$00
$F997			0CF80003b $0C,$F8,$00,$03
$F99B			80000D98b $80,$00,$0D,$98
$F99F			00038001b $00,$03,$80,$01
$F9A3			8D980003b $8D,$98,$00,$03
$F9A7			80018D98b $80,$01,$8D,$98
$F9AB			00038000b $00,$03,$80,$00
$F9AF			F8F80003b $F8,$F8,$00,$03
$F9B3			80040082b $80,$04,$00,$82
$F9B7			03800400b $03,$80,$04,$00
$F9BB			810306FFb $81,$03,$06,$FF
$F9BF			817F	b $81,$7F

$F9C1			05FF82FEb $05,$FF,$82,$FE			;Icon_OPEN
$F9C5			800400BEb $80,$04,$00,$BE
$F9C9			03998000b $03,$99,$80,$00
$F9CD			00000399b $00,$00,$03,$99
$F9D1			871C0000b $87,$1C,$00,$00
$F9D5			03800C30b $03,$80,$0C,$30
$F9D9			0000038Fb $00,$00,$03,$8F
$F9DD			9E79F1E7b $9E,$79,$F1,$E7
$F9E1			C398CC31b $C3,$98,$CC,$31
$F9E5			DB376398b $DB,$37,$63,$98
$F9E9			CC319B36b $CC,$31,$9B,$36
$F9ED			6398CC31b $63,$98,$CC,$31
$F9F1			9BF66398b $9B,$F6,$63,$98
$F9F5			CC319B06b $CC,$31,$9B,$06
$F9F9			6398CC31b $63,$98,$CC,$31
$F9FD			9B36638Fb $9B,$36,$63,$8F
$FA01			8C3199E6b $8C,$31,$99,$E6
$FA05			63800400b $63,$80,$04,$00
$FA09			82038004b $82,$03,$80,$04
$FA0D			00810306b $00,$81,$03,$06
$FA11			FF817F	b $FF,$81,$7F

$FA14			05FF81FEb $05,$FF,$81,$FE			;Icon_DISK
$FA18			E3028680b $E3,$02,$86,$80
$FA1C			00000000b $00,$00,$00,$00
$FA20			03B6801Fb $03,$B6,$80,$1F
$FA24			0C030003b $0C,$03,$00,$03
$FA28			80198003b $80,$19,$80,$03
$FA2C			00038018b $00,$03,$80,$18
$FA30			DCF33003b $DC,$F3,$30,$03
$FA34			8018CD9Bb $80,$18,$CD,$9B
$FA38			60038018b $60,$03,$80,$18
$FA3C			CD83C003b $CD,$83,$C0,$03
$FA40			8018CCF3b $80,$18,$CC,$F3
$FA44			80038018b $80,$03,$80,$18
$FA48			CC1BC003b $CC,$1B,$C0,$03
$FA4C			80198D9Bb $80,$19,$8D,$9B
$FA50			6003801Fb $60,$03,$80,$1F
$FA54			0CF33003b $0C,$F3,$30,$03
$FA58			E3028680b $E3,$02,$86,$80
$FA5C			00000000b $00,$00,$00,$00
$FA60			0306FF81b $03,$06,$FF,$81
$FA64			7F05FF	b $7F,$05,$FF

$FA67			2439	bit pressFlag			;ExecMseKeyB
$FA69			500F	bvc $FA7A

$FA6B			A9BF	lda #%10111111
$FA6D			2539	and pressFlag
$FA6F			8539	sta pressFlag
$FA71			ADA584	lda inputVector
$FA74			AEA684	ldx inputVecto+1
$FA77			20D8C1	jsr CallRoutine

$FA7A			A539	lda pressFlag
$FA7C			2920	and #%00100000
$FA7E			F00F	beq $FA8F

$FA80			A9DF	lda #%11011111
$FA82			2539	and pressFlag
$FA84			8539	sta pressFlag
$FA86			ADA184	lda mouseVector
$FA89			AEA284	ldx mouseVector+1
$FA8C			20D8C1	jsr CallRoutine

$FA8F			2439	bit pressFlag
$FA91			100C	bpl $FA9F

$FA93			20C8FC	jsr GetKeyFromBuf
$FA96			ADA384	lda keyVector
$FA99			AEA484	ldx keyVector+1
$FA9C			20D8C1	jsr CallRoutine

$FA9F			ADB684	lda faultData
$FAA2			F00E	beq xESC_RULER

$FAA4			ADA784	lda mouseFaultVec+0
$FAA7			AEA884	ldx mouseFaultVec+1
$FAAA			20D8C1	jsr CallRoutine
$FAAD			A900	lda #$00
$FAAF			8DB684	sta faultData
$FAB2			60	rts

$FAB3			D8	cld 			;GEOS_IRQ
$FAB4			8D0B88	sta IRQ_BufAkku
$FAB7			68	pla
$FAB8			48	pha
$FAB9			2910	and #%00010000
$FABB			F004	beq $FAC1
$FABD			68	pla
$FABE			6CAF84	jmp (BRKVector)

$FAC1			8A	txa
$FAC2			48	pha
$FAC3			98	tya
$FAC4			48	pha
$FAC5			A542	lda CallRoutVec+1
$FAC7			48	pha
$FAC8			A541	lda CallRoutVec+0
$FACA			48	pha
$FACB			A53E	lda returnAddress+1
$FACD			48	pha
$FACE			A53D	lda returnAddress
$FAD0			48	pha

$FAD1			A200	ldx #$00
$FAD3			B502	lda r0L,x
$FAD5			48	pha
$FAD6			E8	inx
$FAD7			E020	cpx #$20
$FAD9			D0F8	bne $FAD3

$FADB			A501	lda CPU_DATA
$FADD			48	pha
$FADE			A935	lda #$35
$FAE0			8501	sta CPU_DATA

$FAE2			AD1585	lda dblClickCount
$FAE5			F003	beq $FAEA
$FAE7			CE1585	dec dblClickCount

$FAEA			ACD987	ldy keyMode
$FAED			F006	beq $FAF5
$FAEF			C8	iny
$FAF0			F003	beq $FAF5
$FAF2			CED987	dec keyMode

$FAF5			2036FB	jsr GetMatrixCode

$FAF8			AD0A88	lda AlarmAktiv
$FAFB			F003	beq $FB00
$FAFD			CE0A88	dec AlarmAktiv

$FB00			AD9D84	lda intTopVector
$FB03			AE9E84	ldx intTopVect+1
$FB06			20D8C1	jsr CallRoutine

$FB09			AD9F84	lda intBotVector
$FB0C			AEA084	ldx intBotVect+1
$FB0F			20D8C1	jsr CallRoutine

$FB12			A901	lda #$01
$FB14			8D19D0	sta grirq

$FB17			68	pla
$FB18			8501	sta CPU_DATA

$FB1A			A21F	ldx #$1F
$FB1C			68	pla
$FB1D			9502	sta r0L,x
$FB1F			CA	dex
$FB20			10FA	bpl $FB1C

$FB22			68	pla
$FB23			853D	sta returnAddress
$FB25			68	pla
$FB26			853E	sta returnAddress+1
$FB28			68	pla
$FB29			8541	sta CallRoutVec+0
$FB2B			68	pla
$FB2C			8542	sta CallRoutVec+1
$FB2E			68	pla
$FB2F			A8	tay
$FB30			68	pla
$FB31			AA	tax
$FB32			AD0B88	lda IRQ_BufAkku
$FB35			40	rti 			;IRQ_END

$FB36			ADD987	lda keyMode			;GetMatrixCode
$FB39			D00B	bne $FB46
$FB3B			ADEA87	lda currentKey
$FB3E			20ABFC	jsr NewKeyInBuf
$FB41			A90F	lda #$0F
$FB43			8DD987	sta keyMode

$FB46			A900	lda #$00
$FB48			8505	sta r1H
$FB4A			2080FB	jsr CheckKeyboard
$FB4D			D030	bne $FB7F
$FB4F			20FAFC	jsr SHIFT_CBM_CTRL

$FB52			A007	ldy #$07
$FB54			2080FB	jsr CheckKeyboard
$FB57			D026	bne $FB7F

$FB59			B91DFC	lda KeyMatrixData,y
$FB5C			8D00DC	sta $DC00
$FB5F			AD01DC	lda $DC01
$FB62			D9EB87	cmp KB_LastKeyTab,y
$FB65			99EB87	sta KB_LastKeyTab,y
$FB68			D012	bne $FB7C

$FB6A			D9F387	cmp KB_MultipleKey,y
$FB6D			F00D	beq $FB7C
$FB6F			48	pha
$FB70			59F387	eor KB_MultipleKey,y
$FB73			F003	beq $FB78
$FB75			208BFB	jsr MultipleKeyMod
$FB78			68	pla
$FB79			99F387	sta KB_MultipleKey,y
$FB7C			88	dey
$FB7D			10D5	bpl $FB54
$FB7F			60	rts

$FB80			A9FF	lda #$FF			;CheckKeyboard
$FB82			8D00DC	sta $DC00
$FB85			AD01DC	lda $DC01
$FB88			C9FF	cmp #$FF
$FB8A			60	rts

$FB8B			8502	sta r0L			;MultipleKeyMod
$FB8D			A907	lda #$07
$FB8F			8504	sta r1L

$FB91			A502	lda r0L			;NextMultipleKey
$FB93			A604	ldx r1L
$FB95			3DEDC2	and BitData2,x
$FB98			F07B	beq $FC15
$FB9A			98	tya
$FB9B			0A	asl
$FB9C			0A	asl
$FB9D			0A	asl
$FB9E			6504	adc r1L
$FBA0			AA	tax

$FBA1			2405	bit r1H
$FBA3			1006	bpl $FBAB
$FBA5			BD6BFC	lda keyTab1,x
$FBA8			B8	clv
$FBA9			5003	bvc $FBAE

$FBAB			BD2BFC	lda keyTab0,x
$FBAE			8503	sta r0H
$FBB0			A505	lda r1H
$FBB2			2920	and #%00100000
$FBB4			F012	beq $FBC8

$FBB6			A503	lda r0H
$FBB8			2045FD	jsr TestForLowChar
$FBBB			C941	cmp #$41
$FBBD			9009	bcc $FBC8
$FBBF			C95B	cmp #$5B
$FBC1			B005	bcs $FBC8
$FBC3			38	sec
$FBC4			E940	sbc #$40
$FBC6			8503	sta r0H

$FBC8			2405	bit r1H
$FBCA			5006	bvc $FBD2
$FBCC			A503	lda r0H
$FBCE			0980	ora #%10000000
$FBD0			8503	sta r0H

$FBD2			A503	lda r0H
$FBD4			8403	sty r0H

$FBD6			A002	ldy #$02
$FBD8			D925FC	cmp SpecialKeyTab,y
$FBDB			F005	beq $FBE2
$FBDD			88	dey
$FBDE			10F8	bpl $FBD8
$FBE0			3003	bmi $FBE5

$FBE2			B928FC	lda ReplaceKeyTab,y

$FBE5			A403	ldy r0H
$FBE7			8503	sta r0H
$FBE9			297F	and #%00011111
$FBEB			C91F	cmp #$1F
$FBED			F01C	beq $FC0B

$FBEF			A604	ldx r1L
$FBF1			A502	lda r0L
$FBF3			3DEDC2	and BitData2,x
$FBF6			39F387	and KB_MultipleKey,y
$FBF9			F010	beq $FC0B

$FBFB			A90F	lda #$0F
$FBFD			8DD987	sta keyMode
$FC00			A503	lda r0H
$FC02			8DEA87	sta currentKey
$FC05			20ABFC	jsr NewKeyInBuf
$FC08			B8	clv
$FC09			500A	bvc $FC15

$FC0B			A9FF	lda #$FF
$FC0D			8DD987	sta keyMode
$FC10			A900	lda #$00
$FC12			8DEA87	sta currentKey

$FC15			C604	dec r1L
$FC17			3003	bmi $FC1C
$FC19			4C91FB	jmp NextMultipleKey

$FC1C			60	rts

$FC1D			FEFDFBF7b $FE,$FD,$FB,$F7			;KeyMatrixData
$FC21			EFDFBF7Fb $EF,$DF,$BF,$7F

$FC25			BBBAE0	b $BB,$BA,$E0			;SpecialKeyTab
$FC28			3C3E5E	b $3C,$3E,$5E

$FC2B			1D0D1E0Eb $1D,$0D,$1E,$0E			;keyTab0
$FC2B			01030511b $01,$03,$05,$11
$FC2B			33776134b $33,$77,$61,$34
$FC2B			7973651Fb $79,$73,$65,$1F
$FC2B			35726436b $35,$72,$64,$36
$FC2B			63667478b $63,$66,$74,$78
$FC2B			377A6738b $37,$7A,$67,$38
$FC2B			62687576b $62,$68,$75,$76
$FC2B			39696A30b $39,$69,$6A,$30
$FC2B			6D6B6F6Eb $6D,$6B,$6F,$6E
$FC2B			7E706C27b $7E,$70,$6C,$27
$FC2B			2E7C7D2Cb $2E,$7C,$7D,$2C
$FC2B			1F2B7B12b $1F,$2B,$7B,$12
$FC2B			1F231F2Db $1F,$23,$1F,$2D
$FC2B			31141F32b $31,$14,$1F,$32
$FC2B			201F7116b $20,$1F,$71,$16

$FC2B			1C0D080Fb $1C,$0D,$08,$0F			;keyTab1
$FC2B			02040610b $02,$04,$06,$10
$FC2B			40574124b $40,$57,$41,$24
$FC2B			5953451Fb $59,$53,$45,$1F
$FC2B			25524426b $25,$52,$44,$26
$FC2B			43465458b $43,$46,$54,$58
$FC2B			2F5A4728b $2F,$5A,$47,$28
$FC2B			42485556b $42,$48,$55,$56
$FC2B			29494A3Db $29,$49,$4A,$3D
$FC2B			4D4B4F4Eb $4D,$4B,$4F,$4E
$FC2B			3F504C60b $3F,$50,$4C,$60
$FC2B			3A5C5D3Bb $3A,$5C,$5D,$3B
$FC2B			5E2A5B13b $5E,$2A,$5B,$13
$FC2B			1F271F5Fb $1F,$27,$1F,$5F
$FC2B			21141F22b $21,$14,$1F,$22
$FC2B			201F5117b $20,$1F,$51,$17

$FCAB			08	php 			;NewKeyInBuf
$FCAC			78	sei
$FCAD			48	pha
$FCAE			A980	lda #%10000000
$FCB0			0539	ora pressFlag
$FCB2			8539	sta pressFlag
$FCB4			AED887	ldx MaxKeyInBuf
$FCB7			68	pla
$FCB8			9DDA87	sta keyBuffer,x
$FCBB			20E8FC	jsr Add1Key
$FCBE			ECD787	cpx keyBufPointer
$FCC1			F003	beq $FCC6
$FCC3			8ED887	stx MaxKeyInBuf
$FCC6			28	plp
$FCC7			60	rts

$FCC8			08	php 			;GetKeyFromBuf
$FCC9			78	sei
$FCCA			AED787	ldx keyBufPointer
$FCCD			BDDA87	lda keyBuffer,x
$FCD0			8D0485	sta keyData
$FCD3			20E8FC	jsr Add1Key
$FCD6			8ED787	stx keyBufPointer
$FCD9			ECD887	cpx MaxKeyInBuf
$FCDC			D008	bne $FCE6
$FCDE			48	pha
$FCDF			A97F	lda #%01111111
$FCE1			2539	and pressFlag
$FCE3			8539	sta pressFlag
$FCE5			68	pla
$FCE6			28	plp
$FCE7			60	rts

$FCE8			E8	inx 			;Add1Key
$FCE9			E010	cpx #$10
$FCEB			D002	bne $FCEF
$FCED			A200	ldx #$00
$FCEF			60	rts

$FCF0			2439	bit pressFlag			;xGetNextChar
$FCF2			1003	bpl $FCF7
$FCF4			4CC8FC	jmp GetKeyFromBuf
$FCF7			A900	lda #$00
$FCF9			60	rts

$FCFA			A9FD	lda #%11111101			;SHIFT_CBM_CTRL
$FCFC			8D00DC	sta $DC00
$FCFF			AD01DC	lda $DC01
$FD02			49FF	eor #%11111111
$FD04			2980	and #%10000000
$FD06			D00E	bne $FD16

$FD08			A9BF	lda #%10111111
$FD0A			8D00DC	sta $DC00
$FD0D			AD01DC	lda $DC01
$FD10			49FF	eor #%11111111
$FD12			2910	and #%00010000
$FD14			F006	beq $FD1C

$FD16			A980	lda #%10000000
$FD18			0505	ora r1H
$FD1A			8505	sta r1H

$FD1C			A97F	lda #%01111111
$FD1E			8D00DC	sta $DC00
$FD21			AD01DC	lda $DC01
$FD24			49FF	eor #%11111111
$FD26			2920	and #%00100000
$FD28			F006	beq $FD30

$FD2A			A940	lda #%01000000
$FD2C			0505	ora r1H
$FD2E			8505	sta r1H

$FD30			A97F	lda #%01111111
$FD32			8D00DC	sta $DC00
$FD35			AD01DC	lda $DC01
$FD38			49FF	eor #%11111111
$FD3A			2904	and #%00000100
$FD3C			F006	beq $FD44

$FD3E			A920	lda #%00100000
$FD40			0505	ora r1H
$FD42			8505	sta r1H
$FD44			60	rts

$FD45			48	pha 			;TestForLowChar
$FD46			297F	and #%01111111
$FD48			C961	cmp #$61
$FD4A			9009	bcc $FD55
$FD4C			C97B	cmp #$7B
$FD4E			B005	bcs $FD55
$FD50			68	pla
$FD51			38	sec
$FD52			E920	sbc #$20
$FD54			48	pha
$FD55			68	pla
$FD56			60	rts

$FD57			78	sei 			SetGeosClock
$FD58			A601	ldx CPU_DATA
$FD5A			A935	lda #$35
$FD5C			8501	sta CPU_DATA

$FD5E			AD0FDC	lda $DC0F
$FD61			297F	and #%01111111
$FD63			8D0FDC	sta $DC0F

$FD66			AD1985	lda hour
$FD69			C90C	cmp #$0C
$FD6B			3008	bmi $FD75

$FD6D			2C0BDC	bit $DC0B
$FD70			3003	bmi $FD75
$FD72			20D7FD	jsr GetNextDay

$FD75			AD0BDC	lda $DC0B
$FD78			291F	and #%00011111
$FD7A			C912	cmp #$12
$FD7C			D002	bne $FD80
$FD7E			A900	lda #$00

$FD80			2C0BDC	bit $DC0B
$FD83			1005	bpl $FD8A
$FD85			F8	sed
$FD86			18	clc
$FD87			6912	adc #$12
$FD89			D8	cld
$FD8A			2020FE	jsr BCDtoDEZ
$FD8D			8D1985	sta hour
$FD90			AD0ADC	lda $DC0A
$FD93			2020FE	jsr BCDtoDEZ
$FD96			8D1A85	sta minutes
$FD99			AD09DC	lda $DC09
$FD9C			2020FE	jsr BCDtoDEZ
$FD9F			8D1B85	sta seconds
$FDA2			AD08DC	lda $DC08

$FDA5			A002	ldy #$02
$FDA7			B91685	lda year,y
$FDAA			9918C0	sta dateCopy,y
$FDAD			88	dey
$FDAE			10F7	bpl $FDA7

$FDB0			AD0DDC	lda $DC0D
$FDB3			8504	sta r1L

$FDB5			8601	stx CPU_DATA

$FDB7			2C1C85	bit alarmSetFlag
$FDBA			1011	bpl $FDCD
$FDBC			2904	and #%00000100
$FDBE			F015	beq $FDD5

$FDC0			A94A	lda #$4A
$FDC2			8D1C85	sta alarmSetFlag
$FDC5			ADAE84	lda alarmTmtVe+1
$FDC8			F003	beq $FDCD
$FDCA			6CAD84	jmp (alarmTmtVect)

$FDCD			2C1C85	bit alarmSetFlag
$FDD0			5003	bvc $FDD5
$FDD2			2034FE	jsr DoAlarmSound
$FDD5			58	cli
$FDD6			60	rts

$FDD7			AC1785	ldy month			;GetNextDay
$FDDA			B913FE	lda DaysPerMonth-1,y
$FDDD			C002	cpy #$02
$FDDF			D00A	bne $FDEB
$FDE1			A8	tay
$FDE2			AD1685	lda year
$FDE5			2903	and #%00000011
$FDE7			D001	bne $FDEA
$FDE9			C8	iny
$FDEA			98	tya

$FDEB			CD1885	cmp day
$FDEE			D020	bne $FE10
$FDF0			A000	ldy #$00
$FDF2			8C1885	sty day
$FDF5			AD1785	lda month
$FDF8			C90C	cmp #$0C
$FDFA			D011	bne $FE0D
$FDFC			8C1785	sty month
$FDFF			AD1685	lda year
$FE02			C963	cmp #$63
$FE04			D004	bne $FE0A
$FE06			88	dey
$FE07			8C1685	sty year
$FE0A			EE1685	inc year
$FE0D			EE1785	inc month
$FE10			EE1885	inc day
$FE11			60	rts

$FE14			1F1C1F1Eb 31,28,31,30			;DaysPerMonth
$FE18			1F1E1F1Fb 31,30,31,31
$FE1C			1E1F1E1Fb 30,31,30,31

$FE20			48	pha 			;BCDtoDEZ
$FE21			29F0	and #%11110000
$FE23			4A	lsr
$FE24			4A	lsr
$FE25			4A	lsr
$FE26			4A	lsr
$FE27			A8	tay
$FE28			68	pla
$FE29			290F	and #%00001111
$FE2B			18	clc
$FE2C			88	dey
$FE2D			3004	bmi $FE33
$FE2F			690A	adc #$0A
$FE31			D0F9	bne $FE2C
$FE33			60	rts

$FE34			AD0A88	lda AlarmAktiv			;DoAlarmSound
$FE37			D028	bne $FE61

$FE39			A401	ldy CPU_DATA
$FE3B			A935	lda #$35
$FE3D			8501	sta CPU_DATA

$FE3F			A218	ldx #$18
$FE41			BD62FE	lda $FE62,x
$FE44			9D00D4	sta $D400,x
$FE47			CA	dex
$FE48			10F7	bpl $FE41

$FE4A			A221	ldx #$21
$FE4C			AD1C85	lda alarmSetFlag
$FE4F			293F	and #%00111111
$FE51			D001	bne $FE54
$FE53			AA	tax
$FE54			8E04D4	stx v1Cntrl
$FE57			8401	sty CPU_DATA

$FE59			A91E	lda #$1E
$FE5B			8D0A88	sta AlarmAktiv
$FE5E			CE1C85	dec alarmSetFlag

$FE61			60	rts

$FE62			00100008b $01,$10,$00,$08
$FE66			40080000b $40,$08,$00,$00
$FE6A			00000000b $00,$00,$00,$00
$FE6E			00000000b $00,$00,$00,$00
$FE72			00000000b $00,$00,$00,$00
$FE76			00000000b $00,$00,$00,$00
$FE7A			0F000000b $F0,$00,$00,$00
$FE7E			000F	b $00,$0F

$FE80			4C8CFE	jmp $FE8C			;InitMouse
$FE83			4C98FE	jmp $FE98			;SlowMouse
$FE86			4C99FE	jmp $FE99			;UpdateMouse

$FE89			10	b $10
$FE8A			84	b $84
$FE8B			7F	b $7F

$FE8C			A900	lda #$00
$FE8E			853B	sta mouseXPos+1
$FE90			A908	lda #$08
$FE92			853A	sta mouseXPos
$FE94			A908	lda #$08
$FE96			853C	sta mouseYPos
$FE98			60	rts

$FE99			2430	bit mouseOn
$FE9B			3003	bmi $FEA0
$FE9D			4C50FF	jmp $FF50

$FEA0			A501	lda CPU_DATA
$FEA2			48	pha
$FEA3			A935	lda #$35
$FEA5			8501	sta CPU_DATA

$FEA7			AD02DC	lda $DC02
$FEAA			48	pha
$FEAB			AD03DC	lda $DC03
$FEAE			48	pha
$FEAF			AD00DC	lda $DC00
$FEB2			48	pha

$FEB3			A900	lda #$00
$FEB5			8D02DC	sta $DC02
$FEB8			8D03DC	sta $DC03

$FEBB			AD01DC	lda $DC01
$FEBE			2910	and #$10
$FEC0			CD89FE	cmp $FE89
$FEC3			F00F	beq $FED4
$FEC5			8D89FE	sta $FE89
$FEC8			0A	asl
$FEC9			0A	asl
$FECA			0A	asl
$FECB			8D0585	sta mouseData

$FECE			A539	lda pressFlag
$FED0			0920	ora #$20
$FED2			8539	sta pressFlag

$FED4			A9FF	lda #$FF
$FED6			8D02DC	sta $DC02
$FED9			A940	lda #$40
$FEDB			8D00DC	sta $DC00

$FEDE			A266	ldx #$66
$FEE0			EA	nop
$FEE1			EA	nop
$FEE2			EA	nop
$FEE3			CA	dex
$FEE4			D0FA	bne $FEE0

$FEE6			8604	stx r1L

$FEE8			AD19D4	lda $D419
$FEEB			AC8AFE	ldy $FE8A
$FEEE			2061FF	jsr $FF61
$FEF1			8C8AFE	sty $FE8A
$FEF4			C900	cmp #$00
$FEF6			F00C	beq $FF04
$FEF8			48	pha
$FEF9			2980	and #$80
$FEFB			D002	bne $FEFF
$FEFD			A940	lda #$40
$FEFF			0504	ora r1L
$FF01			8504	sta r1L
$FF03			68	pla
$FF04			18	clc
$FF05			653A	adc mouseXPos
$FF07			853A	sta mouseXPos
$FF09			8A	txa
$FF0A			653B	adc mouseXPos+1
$FF0C			853B	sta mouseXPos+1

$FF0E			AD1AD4	lda $D41A
$FF11			AC8BFE	ldy $FE8B
$FF14			2061FF	jsr $FF61
$FF17			8C8BFE	sty $FE8B
$FF1A			C900	cmp #$00
$FF1C			F00F	beq $FF2D
$FF1E			48	pha
$FF1F			2980	and #$80
$FF21			4A	lsr
$FF22			4A	lsr
$FF23			4A	lsr
$FF24			D002	bne $FF28
$FF26			A920	lda #$20
$FF28			0504	ora r1L
$FF2A			8504	sta r1L
$FF2C			68	pla

$FF2D			38	sec
$FF2E			49FF	eor #$FF
$FF30			653C	adc mouseYPos
$FF32			853C	sta mouseYPos

$FF34			A504	lda r1L
$FF36			4A	lsr
$FF37			4A	lsr
$FF38			4A	lsr
$FF39			4A	lsr
$FF3A			AA	tax
$FF3B			BD51FF	lda $FF51,x
$FF3E			8D0685	sta inputData

$FF41			68	pla
$FF42			8D00DC	sta $DC00
$FF45			68	pla
$FF46			8D03DC	sta $DC03
$FF49			68	pla
$FF4A			8D02DC	sta $DC02
$FF4D			68	pla
$FF4E			8501	sta CPU_DATA
$FF50			60	rts

$FF51			FF0602FFb $FF,$06,$02,$FF
$FF55			000701FFb $00,$07,$01,$FF
$FF59			040503FFb $04,$05,$03,$FF
$FF5D			FFFFFFFFb $FF,$FF,$FF,$FF

$FF61			8402	sty r0L
$FF63			8503	sta r0H

$FF65			A200	ldx #$00
$FF67			38	sec
$FF68			E502	sbc r0L
$FF6A			297F	and #$7F
$FF6C			C940	cmp #$40
$FF6E			B006	bcs $FF76
$FF70			4A	lsr
$FF71			F010	beq $FF83
$FF73			A403	ldy r0H
$FF75			60	rts

$FF76			09C0	ora #$C0
$FF78			C9FF	cmp #$FF
$FF7A			F007	beq $FF83
$FF7C			38	sec
$FF7D			6A	ror

$FF7E			A2FF	ldx #$FF
$FF80			A403	ldy r0H
$FF82			60	rts

$FF83			A900	lda #$00
$FF85			60	rts

$FF86			40	rti

$FF87			0539	ora pressFlag
$FF89			8539	sta pressFlag
$FF8B			2018FF	jsr $FF18
$FF8E			AD90FE	lda $FE90
$FF91			2910	and #$10
$FF93			CD8EFE	cmp $FE8E
$FF96			F011	beq $FFA9
$FF98			8D8EFE	sta $FE8E
$FF9B			0A	asl
$FF9C			0A	asl
$FF9D			0A	asl
$FF9E			4980	eor #$80
$FFA0			8D0585	sta mouseData
$FFA3			A920	lda #$20
$FFA5			0539	ora pressFlag
$FFA7			8539	sta pressFlag
$FFA9			60	rts

$FFAA			FF0206FFb $FF,$02,$06,$FF
$FFAE			040305FFb $04,$03,$05,$FF
$FFB2			000107FFb $00,$01,$07,$FF
$FFB6			FFFFFFFFb $FF,$FF,$FF,$FF

$FFBA			BDE8FF	lda $FFE8,x
$FFBD			8504	sta r1L
$FFBF			BDEAFF	lda updTime,x
$FFC2			8506	sta r2L

$FFC4			BDF2FF	lda $FFF2,x
$FFC7			48	pha

$FFC8			A204	ldx #r1L
$FFCA			A002	ldy #r0L
$FFCC			2060C1	jsr BBMult
$FFCF			A206	ldx #r2L
$FFD1			2060C1	jsr BBMult
$FFD4			68	pla

$FFD5			48	pha
$FFD6			1005	bpl $FFDD
$FFD8			A204	ldx #r1L
$FFDA			2072C1	jsr Dnegate
$FFDD			68	pla
$FFDE			2940	and #$40
$FFE0			F005	beq closeAll
$FFE2			A206	ldx #r2L
$FFE4			2072C1	jsr Dnegate
$FFE7			60	rts

$FFE8			FFB500B5b $FF,$B5,$00,$B5
$FFEC			FFB500B5b $FF,$B5,$00,$B5
$FFF0			FFB50040b $FF,$B5,$00,$40
$FFF4			40C08080b $40,$C0,$80,$80
$FFF8			0000	b $00,$00

$FFFA			35FB	w IRQ_END
$FFFC			35FB	w IRQ_END
$FFFE			B3FA	w GEOS_IRQ
