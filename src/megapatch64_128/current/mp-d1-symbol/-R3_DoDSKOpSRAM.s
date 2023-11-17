; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Einsprungtabelle RAM-Funktionen.
;Übergabe: r0  = Startadresse RAM.
;          r1  = Startadresse REU.
;          r2  = Anzahl Bytes.
;          r3L = Speicherbank.
;Rückgabe: -
;Geändert: AKKU,xReg,yReg
:DoRAMOp_SRAM		cpy	#%10010000		;StashRAM ?
			bne	:51			; => Nein, weiter...
			jsr	SCPU_STASH_RAM		;StashRAM für SCPU ausführen.
			jmp	:54

::51			cpy	#%10010001		;FetchRAM ?
			bne	:52			; => Nein, weiter...
			jsr	SCPU_FETCH_RAM		;FetchRAM für SCPU ausführen.
			jmp	:54

::52			cpy	#%10010010		;SwapRAM ?
			bne	:53			; => Nein, weiter...
			jsr	SCPU_SWAP_RAM		;SwapRAM für SCPU ausführen.
			jmp	:54

::53			cpy	#%10010011		;SwapRAM ?
			bne	:54			; => Nein, weiter...
			jsr	SCPU_VERIFY_RAM		;SwapRAM für SCPU ausführen.
			txa				;Verify-Error ?
			beq	:54			; => Nein, weiter...

			ldx	#%00100000
			b $2c
::54			ldx	#%01000000		;Kein Fehler...
			txa
			ldx	#NO_ERROR
			rts

;*** Speicherbank berechnen.
;Laufwerkstreiber beginnt direkt an der angegebenen Speicherbank.
:DefBankAdr		lda	r3L			;Speicherbank berechnen.
			rts
