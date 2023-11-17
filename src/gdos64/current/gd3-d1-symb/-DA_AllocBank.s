; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Bank in GEOS-DACC belegen.
;    Übergabe:		AKKU	= Bank-Adresse.
;			xReg	= Bit-Muster
;    Rückgabe:		xReg	= Fehlermeldung.
:DACC_ALLOC_BANK	cmp	ramExpSize
			bcs	:3

			stx	:BankType

			tax
			and	#%00000011
			tay

			txa
			lsr
			lsr
			tax

			lda	RamBankInUse,x
			and	:BankModeUsed,y
			bne	:3

			lda	RamBankInUse,x
			and	:BankModeFree,y
			sta	:2 +1

			lda	:BankType
			cpy	#$00
			beq	:2
::1			lsr
			lsr
			dey
			bne	:1

::2			ora	#$ff
			sta	RamBankInUse,x

			ldx	#NO_ERROR
			rts

::3			ldx	#NO_FREE_RAM
			rts

;--- Variablen.
::BankType		b $00
::BankModeFree		b %00111111
			b %11001111
			b %11110011
			b %11111100
::BankModeUsed		b %11000000
			b %00110000
			b %00001100
			b %00000011
