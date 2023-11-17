; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Bank in GEOS-DACC freigeben.
;    Übergabe:		AKKU	= Bank-Adresse.
;    Rückgabe:		xReg	= Fehlermeldung.
:DACC_FREE_BANK		cmp	ramExpSize
			bcs	:1

			tax
			and	#%00000011
			tay

			txa
			lsr
			lsr
			tax

			lda	RamBankInUse,x
			and	:DOUBLE_BIT,y
			sta	RamBankInUse,x

			ldx	#NO_ERROR
			rts

::1			ldx	#NO_FREE_RAM
			rts

;--- Variablen.
::DOUBLE_BIT		b %00111111
			b %11001111
			b %11110011
			b %11111100
