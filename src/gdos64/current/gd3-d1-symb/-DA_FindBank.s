; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Freie 64K-Speicherbank suchen.
:DACC_FIND_BANK		ldy	ramExpSize
			beq	:2
::1			dey
			jsr	DACC_BANK_BYTE
			beq	:3
			tya
			bne	:1
::2			ldx	#NO_FREE_RAM
			b $2c
::3			ldx	#NO_ERROR
			rts
