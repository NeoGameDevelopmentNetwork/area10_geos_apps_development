; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

$C01B			78	sei 			;ReBootGEOS

$C01C			A936	lda #%00110110
$C01E			8501	sta CPU_DATA

$C020			20A9E0	jsr EN_SET_REC

$C023			A009	ldy #$09
$C025			B937C0	lda RamBootData   ,y
$C028			9901DE	sta ramExpBase1 +1,y
$C02B			88	dey
$C02C			10F7	bpl $C025

$C02E			2006FE	jsr EXEC_REU_REC
$C031			200FFE	jsr RL_HW_DIS

$C034			4C0060	jmp $6000

$C037			91	b $91			;RamBootData
$C038			0060	w $6000
$C03A			007E	w $7E00
$C03C			00	b $00
$C03D			0005	w $0500
$C03F			00	b $00
$C040			00	b $00
