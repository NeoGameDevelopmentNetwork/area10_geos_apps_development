; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Tabellenwert für Speicherbank finden.
;Übergabe: Y = 64K-Speicherbank-Nr.
;Rückgabe: A = %00xxxxxx = Frei.
;              %01xxxxxx = Anwendung.
;              %10xxxxxx = Laufwerk.
;              %11xxxxxx = System.
:DACC_BANK_BYTE		tya
			lsr
			lsr
			tax
			lda	RamBankInUse,x
			pha
			tya
			and	#%00000011
			tax
			pla
::1			cpx	#$00
			beq	:2
			asl
			asl
			dex
			bne	:1
::2			and	#%11000000
			rts
