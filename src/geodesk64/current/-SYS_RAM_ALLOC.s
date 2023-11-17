; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Speicherbank reservieren.
:AllocateBank		tya
			lsr
			lsr
			tax
			lda	RamBankInUse,x
			pha
			tya
			and	#%00000011
			tax
			pla
			ora	:DOUBLE_BIT,x
			pha
			tya
			lsr
			lsr
			tax
			pla
			sta	RamBankInUse,x
			rts

::DOUBLE_BIT		b %11000000
			b %00110000
			b %00001100
			b %00000011
