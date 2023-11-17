; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Einsprungtabelle RAM-Funktionen.
;    Übergabe:		r0	= Startadresse C128-RAM.
;			r1	= Startadresse REU.
;			r2	= Anzahl Bytes.
;			r3L	= Speicherbank.
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:DoRAMOp_SRAM		cpy	#jobStash		;StashRAM ?
			bne	:1			; => Nein, weiter...
			jsr	SCPU_STASH_RAM		;StashRAM für SCPU ausführen.
			jmp	:ok

::1			cpy	#jobFetch		;FetchRAM ?
			bne	:2			; => Nein, weiter...
			jsr	SCPU_FETCH_RAM		;FetchRAM für SCPU ausführen.
			jmp	:ok

::2			cpy	#jobSwap		;SwapRAM ?
			bne	:3			; => Nein, weiter...
			jsr	SCPU_SWAP_RAM		;SwapRAM für SCPU ausführen.
			jmp	:ok

::3			cpy	#jobVerify		;VerifyRAM ?
			bne	:err			; => Nein, weiter...
			jsr	SCPU_VERIFY_RAM		;VerifyRAM für SCPU ausführen.
			txa				;Verify-Error ?
			beq	:ok			; => Nein, weiter...

::err			ldx	#%00100000		;Fehler...
			b $2c
::ok			ldx	#%01000000		;Kein Fehler...
			txa
			ldx	#NO_ERROR
			rts
