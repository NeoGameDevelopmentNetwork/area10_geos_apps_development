; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "GEOS_QuellCo.ext"
			t "GEOS_9D80.SR.ext"

:EN_SET_REC		= $e0a9
:RL_HW_EN		= $e0b1
:SET_REC_IMG		= $fe03
:EXEC_REC_REU		= $fe06
:EXEC_REC_SEC		= $fe09
:RL_HW_DIS		= $fe0c
:RL_HW_DIS2		= $fe0f
:EXEC_REU_DIS		= $fe1e
:EXEC_SEC_DIS		= $fe21

endif

			n "GEOS_RL/1.OBJ"
			f $06
			c "KERNAL_9D80 V1.0"
			a "M. Kanet"
			o xVerifyRAM
			p EnterDeskTop
			i
<MISSING_IMAGE_DATA>

;*** Einsprungtabelle RAM-Tools.
:RL_xVerifyRAM		ldy	#%10010011		;RAM-Bereich vergleichen.
			bne	RL_xDoRAMOp
:RL_xStashRAM		ldy	#%10010000		;RAM-Bereich speichern.
			bne	RL_xDoRAMOp
:RL_xSwapRAM		ldy	#%10010010		;RAM-Bereich tauschen.
			bne	RL_xDoRAMOp
:RL_xFetchRAM		ldy	#%10010001		;RAM-Bereich laden.

:RL_xDoRAMOp		ldx	#$0d

			lda	ramExpSize
			beq	:102

			php
			sei

			lda	CPU_DATA
			pha

			lda	#%00110110
			sta	CPU_DATA

			jsr	EN_SET_REC

			ldx	#$04
::101			lda	zpage       + 1,x
			sta	ramExpBase1 + 1,x
			dex
			bne	:101

			lda	r2H
			sta	ramExpBase1 + 8
			lda	r2L
			sta	ramExpBase1 + 7
			lda	r3L
			sta	ramExpBase1 + 6
			stx	ramExpBase1 +10
			sty	ramExpBase1 + 1

			jsr	EXEC_REC_REU
			jsr	RL_HW_DIS2

			pla
			sta	CPU_DATA

			plp
			lda	#%01000000
			ldx	#$00
::102			rts

			nop				;Füllbytes
			nop
			nop
			nop
			nop
			nop
			nop
			rts
