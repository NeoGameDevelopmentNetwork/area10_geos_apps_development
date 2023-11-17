; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** RAM in GEOS-DACC belegen.
;    Übergabe:		AKKU	= Zeiger auf erste Bank.
;			xReg	= Bit-Muster.
;			yReg	= Anzahl Bänke.
;    Rückgabe:		xReg	= Fehlermeldung.
:AllocRAM		sta	:BankAdr
			stx	:BankType
			sty	:BankTabSize
			tya
			beq	:2

::1			lda	:BankAdr		;Zeiger auf aktuelle Bank und
			ldx	:BankType
			jsr	Alloc64K		;Bank in Tabelle belegen.
			txa				;War Bank bereits belegt ?
			bne	:3			;Ja, Abbruch...

			inc	:BankAdr		;Zeiger auf nächste Bank.
			dec	:BankTabSize		;Alle Bänke belegt ?
			bne	:1			;Nein, weiter...

::2			ldx	#NO_ERROR		;Kein Fehler...
::3			rts

;--- Variablen.
::BankType		b $00
::BankAdr		b $00
::BankTabSize		b $00

;*** Bank in GEOS-DACC belegen.
;    Übergabe:		AKKU	= Bank-Adresse.
;			xReg	= Bit-Muster
;    Rückgabe:		xReg	= Fehlermeldung.
:Alloc64K		stx	:BankType
			cmp	ramExpSize
			bcs	:3

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
::1			cpy	#$00
			beq	:2
			lsr
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
::BankModeFree		b %00111111,%11001111,%11110011,%11111100
::BankModeUsed		b %11000000,%00110000,%00001100,%00000011
