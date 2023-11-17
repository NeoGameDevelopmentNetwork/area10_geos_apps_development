; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Freie 64K-Speicherbank suchen.
:FindFreeBank		ldy	ramExpSize
			beq	:2
::1			dey
			jsr	GetBankByte
			beq	:3
			tya
			bne	:1
::2			ldx	#NO_FREE_RAM
			b $2c
::3			ldx	#NO_ERROR
			rts

;*** Speicherbank freigeben.
:FreeBank		tya
			lsr
			lsr
			tax
			lda	RamBankInUse,x
			pha
			tya
			and	#%00000011
			tax
			pla
			and	:DOUBLE_BIT,x
			pha
			tya
			lsr
			lsr
			tax
			pla
			sta	RamBankInUse,x
			rts

::DOUBLE_BIT		b %00111111
			b %11001111
			b %11110011
			b %11111100
