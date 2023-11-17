; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

$9EAA			A093	ldy #%10010011			;xVerifyRAM
$9EAC			D00A	bne $9EB8
$9EAE			A090	ldy #%10010000			;xStashRAM
$9EB0			D006	bne $9EB8
$9EB2			A092	ldy #%10010010			;xSwapRAM
$9EB4			D002	bne $9EB8
$9EB6			A091	ldy #%10010001			;xFetchRAM

$9EB8			A20D	ldx #$0D			;xDoRAMOp

$9EBA			ADC388	lda ramExpSize
$9EBD			F039	beq $9EF8

$9EBF			08	php
$9EC0			78	sei

$9EC1			A501	lda CPU_DATA
$9EC3			48	pha

$9EC4			A936	lda #%00110110
$9EC6			8501	sta CPU_DATA

$9EC8			20A9E0	jsr EN_SET_REC

$9ECB			A204	ldx #$04
$9ECD			B501	lda zpage       + 1,x
$9ECF			9D01DE	sta ramExpBase1 + 1,x
$9ED2			CA	dex
$9ED3			D0F8	bne $9ECD

$9ED5			A507	lda r2H
$9ED7			8D08DE	sta ramExpBase1 + 8
$9EDA			A506	lda r2L
$9EDC			8D07DE	sta ramExpBase1 + 7
$9EDF			A508	lda r3L
$9EE1			8D06DE	sta ramExpBase1 + 6
$9EE4			8E0ADE	stx ramExpBase1 +10
$9EE7			8C01DE	sty ramExpBase1 + 1

$9EEA			2006FE	jsr EXEC_REC_REU
$9EED			200FFE	jsr RL_HW_DIS2

$9EF0			68	pla
$9EF1			8501	sta CPU_DATA

$9EF3			28	plp
$9EF4			A940	lda #%01000000
$9EF6			A200	ldx #$00
$9EF8			60	rts

$9EF9			EA	nop 			;NoFunc
$9EFA			EA	nop
$9EFB			EA	nop
$9EFC			EA	nop
$9EFD			EA	nop
$9EFE			EA	nop
$9EFF			EA	nop
$9F00			60	rts
