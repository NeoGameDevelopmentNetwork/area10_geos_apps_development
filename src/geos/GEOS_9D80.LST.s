; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

$9D80			18	clc 			;SetVecToSek
$9D81			A902	lda #$02
$9D83			650E	adc r6L
$9D85			850E	sta r6L
$9D87			9002	bcc $9D8B
$9D89			E60F	inc r6H
$9D8B			60	rts

$9D8C			2014C2	jsr EnterTurbo			;xReadFile
$9D8F			8A	txa
$9D90			D0F9	bne $9D8B

$9D92			205CC2	jsr InitForIO

$9D95			A503	lda r0H
$9D97			48	pha
$9D98			A502	lda r0L
$9D9A			48	pha

$9D9B			A980	lda #>diskBlkBuf
$9D9D			850B	sta r4H
$9D9F			A900	lda #<diskBlkBuf
$9DA1			850A	sta r4L

$9DA3			A902	lda #$02
$9DA5			850C	sta r5L

$9DA7			A505	lda r1H
$9DA9			8D0383	sta fileTrScTab+3
$9DAC			A504	lda r1L
$9DAE			8D0283	sta fileTrScTab+2

$9DB1			201AC2	jsr ReadBlock
$9DB4			8A	txa
$9DB5			D05D	bne $9E14

$9DB7			A0FE	ldy #$FE
$9DB9			AD0080	lda diskBlkBuf+0
$9DBC			D006	bne $9DC4
$9DBE			AC0180	ldy diskBlkBuf+1
$9DC1			88	dey
$9DC2			F036	beq $9DFA

$9DC4			A507	lda r2H
$9DC6			D00A	bne $9DD2
$9DC8			C406	cpy r2L
$9DCA			9006	bcc $9DD2
$9DCC			F004	beq $9DD2
$9DCE			A20B	ldx #$0B
$9DD0			D042	bne $9E14

$9DD2			8404	sty r1L

$9DD4			A930	lda #%00110000
$9DD6			8501	sta CPU_DATA

$9DD8			B90180	lda diskBlkBuf+1,y
$9DDB			88	dey
$9DDC			9110	sta (r7L),y
$9DDE			D0F8	bne $9DD8

$9DE0			A936	lda #%00110110
$9DE2			8501	sta CPU_DATA

$9DE4			A504	lda r1L
$9DE6			18	clc
$9DE7			6510	adc r7L
$9DE9			8510	sta r7L
$9DEB			9002	bcc $9DEF
$9DED			E611	inc r7H

$9DEF			A506	lda r2L
$9DF1			38	sec
$9DF2			E504	sbc r1L
$9DF4			8506	sta r2L
$9DF6			B002	bcs $9DFA
$9DF8			C607	dec r2H

$9DFA			E60C	inc r5L
$9DFC			E60C	inc r5L

$9DFE			A40C	ldy r5L
$9E00			AD0180	lda diskBlkBuf +1
$9E03			8505	sta r1H
$9E05			990183	sta fileTrScTab+1,y
$9E08			AD0080	lda diskBlkBuf +0
$9E0B			8504	sta r1L
$9E0D			990083	sta fileTrScTab+0,y
$9E10			D09F	bne $9DB1

$9E12			A200	ldx #$00

$9E14			68	pla
$9E15			8502	sta r0L
$9E17			68	pla
$9E18			8503	sta r0H
$9E1A			4C5FC2	jmp DoneWithIO

$9E1D			AD6788	lda VerWriteFlag			;VerWriteSek
$9E20			F003	beq $9E25
$9E22			4C23C2	jmp VerWriteBloc
$9E25			4C20C2	jmp WriteBlock

$9E28			2014C2	jsr EnterTurbo
$9E2B			8A	txa
$9E2C			D035	bne $9E63
$9E2E			8D6788	sta VerWriteFlag

$9E31			205CC2	jsr InitForIO

$9E34			A980	lda #>diskBlkBuf
$9E36			850B	sta r4H
$9E38			A900	lda #<diskBlkBuf
$9E3A			850A	sta r4L

$9E3C			A50F	lda r6H
$9E3E			48	pha
$9E3F			A50E	lda r6L
$9E41			48	pha
$9E42			A511	lda r7H
$9E44			48	pha
$9E45			A510	lda r7L
$9E47			48	pha
$9E48			20649E	jsr VerWriteFile
$9E4B			68	pla
$9E4C			8510	sta r7L
$9E4E			68	pla
$9E4F			8511	sta r7H
$9E51			68	pla
$9E52			850E	sta r6L
$9E54			68	pla
$9E55			850F	sta r6H
$9E57			8A	txa
$9E58			D006	bne $9E60
$9E5A			CE6788	dec VerWriteFlag
$9E5D			20649E	jsr VerWriteFile
$9E60			205FC2	jsr DoneWithIO
$9E63			60	rts

$9E64			A000	ldy #$00			;VerWriteFile
$9E66			B10E	lda (r6L),y
$9E68			F03B	beq $9EA5
$9E6A			8504	sta r1L
$9E6C			C8	iny
$9E6D			B10E	lda (r6L),y
$9E6F			8505	sta r1H
$9E71			88	dey
$9E72			20809D	jsr SetVecToSek

$9E75			B10E	lda (r6L),y
$9E77			910A	sta (r4L),y
$9E79			C8	iny
$9E7A			B10E	lda (r6L),y
$9E7C			910A	sta (r4L),y

$9E7E			A0FE	ldy #$FE

$9E80			A930	lda #%00110000
$9E82			8501	sta CPU_DATA

$9E84			88	dey
$9E85			B110	lda (r7L),y
$9E87			990280	sta diskBlkBuf+2,y
$9E8A			98	tya
$9E8B			D0F7	bne $9E84

$9E8D			A936	lda #%00110110
$9E8F			8501	sta CPU_DATA

$9E91			201D9E	jsr VerWriteSek
$9E94			8A	txa
$9E95			D00F	bne $9EA6

$9E97			18	clc
$9E98			A9FE	lda #$FE
$9E9A			6510	adc r7L
$9E9C			8510	sta r7L
$9E9E			9002	bcc $9EA2
$9EA0			E611	inc r7H
$9EA2			B8	clv
$9EA3			50BF	bvc VerWriteFile
$9EA5			AA	tax
$9EA6			60	rts

$9EA7			2B96	w $962B

$9EA9			FF	b $FF

$9EAA			A093	ldy #%10010011			;xVerifyRAM
$9EAC			D00A	bne $9EB8
$9EAE			A090	ldy #%10010000			;xStashRAM
$9EB0			D006	bne $9EB8
$9EB2			A092	ldy #%10010010			;xSwapRAM
$9EB4			D002	bne $9EB8
$9EB6			A091	ldy #%10010001			;xFetchRAM

$9EB8			A20D	ldx #$0D			;xDoRAMOp

$9EBA			A508	lda r3L
$9EBC			CDC388	cmp ramExpSize
$9EBF			B03F	bcs $9F00

$9EC1			A601	ldx CPU_DATA
$9EC3			A935	lda #%00110101
$9EC5			8501	sta CPU_DATA

$9EC7			A503	lda r0H
$9EC9			8D03DF	sta ramExpBase2 + 3
$9ECC			A502	lda r0L
$9ECE			8D02DF	sta ramExpBase2 + 2
$9ED1			A505	lda r1H
$9ED3			8D05DF	sta ramExpBase2 + 5
$9ED6			A504	lda r1L
$9ED8			8D04DF	sta ramExpBase2 + 4
$9EDB			A508	lda r3L
$9EDD			8D06DF	sta ramExpBase2 + 6
$9EE0			A507	lda r2H
$9EE2			8D08DF	sta ramExpBase2 + 8
$9EE5			A506	lda r2L
$9EE7			8D07DF	sta ramExpBase2 + 7
$9EEA			A900	lda #$00
$9EEC			8D09DF	sta ramExpBase2 + 9
$9EEF			8D0ADF	sta ramExpBase2 +10
$9EF2			8C01DF	sty ramExpBase2 + 1

$9EF5			AD00DF	lda ramExpBase2 + 0
$9EF8			2960	and #$60
$9EFA			F0F9	beq $9EF5

$9EFC			8601	stx CPU_DATA

$9EFE			A200	ldx #$00
$9F00			60	rts

$9F01			00000000b $00,$00,$00,$00			;BasicCommand
$9F05			00000000b $00,$00,$00,$00
$9F09			00000000b $00,$00,$00,$00
$9F0D			00000000b $00,$00,$00,$00
$9F11			00000000b $00,$00,$00,$00
$9F15			00000000b $00,$00,$00,$00
$9F19			00000000b $00,$00,$00,$00
$9F1D			00000000b $00,$00,$00,$00
$9F21			00000000b $00,$00,$00,$00
$9F25			00000000b $00,$00,$00,$00

$9F29			00	b $00				;ResetTimer
$9F2A			000000	b $00,$00,$00			;BasicBackData	
$9F2D			00	b $00			;EndBasicL
$9F2E			00	b $00			;EndBasicH

$9F2F			78	sei 			;JumpToBasic
$9F30			A936	lda #%00110110
$9F32			8501	sta CPU_DATA

$9F34			A002	ldy #$02
$9F36			B90008	lda $0800,y
$9F39			992A9F	sta BasicBackData,y
$9F3C			88	dey
$9F3D			10F7	bpl $9F36

$9F3F			A511	lda r7H
$9F41			8D2E9F	sta EndBasicH
$9F44			A510	lda r7L
$9F46			8D2D9F	sta EndBasicL

$9F49			E601	inc CPU_DATA

$9F4B			A2FF	ldx #$FF
$9F4D			9A	txs

$9F4E			A900	lda #$00
$9F50			8D16D0	sta grcntrl2

$9F53			20A3FD	jsr IOINIT

$9F56			A6BA	ldx curDevice

$9F58			A900	lda #$00
$9F5A			A8	tay
$9F5B			990200	sta $0002,y
$9F5E			990002	sta $0200,y
$9F61			990003	sta $0300,y
$9F64			C8	iny
$9F65			D0F4	bne $9F5B

$9F67			86BA	stx curDevice

$9F69			A9A0	lda #> $A000
$9F6B			8D8402	sta MEMSIZ +1

$9F6E			A9C3	lda #< TBUFFER
$9F70			85B2	sta TAPE1 +0
$9F72			A903	lda #> TBUFFER
$9F74			85B3	sta TAPE1 +1

$9F76			A908	lda #> $0800
$9F78			8D8202	sta MEMSTR +1
$9F7B			4A	lsr
$9F7C			8D8802	sta HIBASE

$9F7F			20DAC4	jsr SetKernalVec
$9F82			2081FF	jsr CINT

$9F85			A99F	lda #> NewNMI
$9F87			8D1903	sta NMIINV +1
$9F8A			A9AC	lda #< NewNMI
$9F8C			8D1803	sta NMIINV +0

$9F8F			A906	lda #$06
$9F91			8D299F	sta ResetTimer

$9F94			AD0DDD	lda $DD0D
$9F97			A9FF	lda #$FF
$9F99			8D04DD	sta $DD04
$9F9C			8D05DD	sta $DD05
$9F9F			A981	lda #$81
$9FA1			8D0DDD	sta $DD0D
$9FA4			A901	lda #$01
$9FA6			8D0EDD	sta $DD0E

$9FA9			6C00A0	jmp ($A000)

$9FAC			48	pha 			;NewNMI
$9FAD			98	tya
$9FAE			48	pha

$9FAF			AD0DDD	lda cia2ICR

$9FB2			CE299F	dec ResetTimer
$9FB5			D044	bne $9FFB

$9FB7			A97F	lda #$7F
$9FB9			8D0DDD	sta $DD0D

$9FBC			A9C0	lda #> SystemReBoot
$9FBE			8D1903	sta NMIINV +1
$9FC1			A900	lda #< SystemReBoot
$9FC3			8D1803	sta NMIINV +0

$9FC6			A002	ldy #$02
$9FC8			B92A9F	lda BasicBackData,y
$9FCB			990008	sta $0800,y
$9FCE			88	dey
$9FCF			10F7	bpl $9FC8

$9FD1			AD2E9F	lda EndBasicH
$9FD4			852E	sta VARTAB   +1
$9FD6			AD2D9F	lda EndBasicL
$9FD9			852D	sta VARTAB   +0

$9FDB			C8	iny
$9FDC			B9019F	lda BasicCommand,y
$9FDF			F00A	beq $9FEB
$9FE1			91D1	sta ($D1),y
$9FE3			A90E	lda #14
$9FE5			99F0D8	sta $D8F0,y
$9FE8			C8	iny
$9FE9			D0F1	bne $9FDC

$9FEB			98	tya
$9FEC			F00D	beq $9FFB

$9FEE			A928	lda #$28
$9FF0			85D3	sta PNTR

$9FF2			A901	lda #$01
$9FF4			85C6	sta NDX

$9FF6			A90D	lda #$0D
$9FF8			8D7702	sta KEYD

$9FFB			68	pla
$9FFC			A8	tay
$9FFD			68	pla
$9FFE			40	rti

$9FFF			40	rti
