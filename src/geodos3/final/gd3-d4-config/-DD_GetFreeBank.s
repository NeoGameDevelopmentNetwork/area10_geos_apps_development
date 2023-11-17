; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Freie Bank von 0 nach X suchen.
;    Übergabe:		yReg	= Anzahl Bänke.
;    Rückgabe:		xReg	= Fehlermeldung.
:FindFree64K		ldy	#$01			;Nur eine freie Bank suchen.
:FindFreeRAM		sty	r1L			;Anzahl freier Bänke suchen.
			sty	r1H

			lda	#$00			;Bankzähler löschen.
			sta	r0H
			sta	r0L

::1			ldx	r0L
			jsr	GetBankByte
			and	BANK_BIT_MODE,y
			beq	:3			; => Bank verfügbar, weiter...

			lda	#$00			;Flag "Freie Bank gefunden" löschen.
			sta	r0H
			lda	r1L			;Bankzähler wieder zurücksetzen.
			sta	r1H

::2			inc	r0L			;Zeiger auf nächste Bank.
			lda	r0L
			cmp	ramExpSize		;Alle Bänke durchsucht ?
			bne	:1			; => Nein, weiter...
			ldx	#NO_FREE_RAM		;Nicht genügend Speicherbänke frei.
			rts

::3			lda	r0H			;Freie Bank bereits gefunden ?
			bne	:4			;Ja, weiter...
			lda	r0L			;Erste freie RAM-Bank speichern.
			sta	r0H

::4			dec	r1H			;Genügend Bänke gefunden ?
			bne	:2			;Nein, weitersuchen.
			lda	r0H			;Erste freie Bank.
			ldy	r1L			;Anzahl benötigter Speicherbänke.
			ldx	#NO_ERROR		;Kein Fehler.
			rts

;*** Freie Bank von X nach 0 suchen.
;    Übergabe:		yReg	= Anzahl Bänke.
;    Rückgabe:		xReg	= Fehlermeldung.
:LastFree64K		ldy	#$01			;Nur eine freie Bank suchen.
:LastFreeRAM		sty	r1L			;Anzahl freier Bänke suchen.
			sty	r1H

			lda	#$00			;Bankzähler löschen.
			sta	r0H

			ldx	ramExpSize
			dex
			stx	r0L

::1			ldx	r0L
			jsr	GetBankByte
			and	BANK_BIT_MODE,y
			beq	:3			; => Bank verfügbar, weiter...

			lda	#$00			;Flag "Freie Bank gefunden" löschen.
			sta	r0H
			lda	r1L			;Bankzähler wieder zurücksetzen.
			sta	r1H

::2			dec	r0L			;Zeiger auf nächste Bank.
			bne	:1			;Nein, weiter...
			ldx	#NO_FREE_RAM		;Nicht genügend Speicherbänke frei.
			rts

::3			lda	r0H			;Freie Bank bereits gefunden ?
			bne	:4			;Ja, weiter...
			lda	r0L			;Erste freie RAM-Bank speichern.
			sta	r0H

::4			dec	r1H			;Genügend Bänke gefunden ?
			bne	:2			;Nein, weitersuchen.
			lda	r0L			;Erste freie Bank.
			ldy	r1L			;Anzahl benötigter Speicherbänke.
			ldx	#NO_ERROR		;Kein Fehler.
			rts

;*** Zeiger auf Bank-Bitpaar berechnen.
;    Ein Byte der RAM-Tabelle enthält 4 Bitpaare. Jedes Bitpaar
;    entspricht dabei einer Speicherbank.
:GetBankByte		txa
			and	#$03
			tay
			txa
			lsr
			lsr
			tax
			lda	RamBankInUse,x
			rts

;*** Bank-Modus ermitteln.
;    Das Bitpaar aus der MP3-RAM-Tabelle wird in einen Bytewert umgewandelt:
;    Byte $00 = Frei, $01 = Anwendung, $02 = Disk, $03 = GEOS/Task/Spooler
:GetBankType		and	BANK_BIT_MODE,y
			stx	:2 +1
			ldx	:BankPos,y
			beq	:2
::1			asl
			asl
			dex
			bne	:1
::2			ldx	#$ff
			rts

::BankPos		b $00,$01,$02,$03

;*** Bank-Bits isolieren.
:BANK_BIT_MODE		b %11000000,%00110000,%00001100,%00000011
