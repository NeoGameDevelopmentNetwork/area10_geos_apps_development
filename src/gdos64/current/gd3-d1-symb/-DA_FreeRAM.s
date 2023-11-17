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
:DACC_FREE_RAM		sta	:BankAdr
			sty	:BankTabSize
			tya
			beq	:2

::1			lda	:BankAdr
			jsr	DACC_FREE_BANK		;Bank in Tabelle belegen.
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
