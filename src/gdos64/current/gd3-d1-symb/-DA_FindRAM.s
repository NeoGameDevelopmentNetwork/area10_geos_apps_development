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
;:DACC_FIND_BANK	ldy	#$01			;Nur eine freie Bank suchen.
:DACC_FIND_RAM		sty	r1L			;Anzahl freier Bänke suchen.
			sty	r1H

			lda	#$00			;Bankzähler löschen.
			sta	r0H
			sta	r0L

::1			ldy	r0L
			jsr	DACC_BANK_BYTE
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
