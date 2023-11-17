; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** RAM in GEOS-DACC freigeben.
;    Übergabe:		AKKU	= Zeiger auf erste Bank.
;			yReg	= Anzahl Bänke.
;    Rückgabe:		xReg	= Fehlermeldung.
:FreeRAM		sta	:BankAdr
			sty	:BankTabSize
			tya
			beq	:2

::1			lda	:BankAdr
			jsr	Free64K			;Bank in Tabelle belegen.
			txa				;War Bank bereits belegt ?
			bne	:3			;Ja, Abbruch...

			inc	:BankAdr		;Zeiger auf nächste Bank.
			dec	:BankTabSize		;Alle Bänke belegt ?
			bne	:1			;Nein, weiter...

::2			ldx	#NO_ERROR		;Kein Fehler...
::3			rts

;--- Variablen.
::BankAdr		b $00
::BankTabSize		b $00

;*** Bank in GEOS-DACC freigeben.
;    Übergabe:		AKKU	= Bank-Adresse.
;    Rückgabe:		xReg	= Fehlermeldung.
:Free64K		cmp	ramExpSize
			bcs	:1

			tax
			and	#%00000011
			tay

			txa
			lsr
			lsr
			tax

			lda	RamBankInUse,x
			and	:BankModeFree,y
			sta	RamBankInUse,x

			ldx	#NO_ERROR
			rts

::1			ldx	#NO_FREE_RAM
			rts

;--- Variablen.
::BankModeFree		b %00111111,%11001111,%11110011,%11111100
