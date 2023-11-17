; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Einsprungtabelle RAM-Funktionen.
;
; Wird innerhalb des Kernal, dem RAM-
; Treiber, SuperRAM-Laufwerk, RBOOT,
; RBOOT.SYS und FBOOT verwendet.
;
; Übergabe:		AKKU	= Speicherbank.
;			yReg	= Job-Code.
;			r0	= Startadresse RAMCard.
;			r1	= Startadresse REU.
;			r2	= Anzahl Bytes.
; Rückgabe:		AKKU	= Job-Status.
; Geändert:		AKKU,xReg,yReg
:DoRAMOp_SRAM		cpy	#jobStash		;StashRAM ?
			bne	:1			; => Nein, weiter...
			jsr	SCPU_X16_STASH		;StashRAM für SCPU ausführen.
			jmp	:ok

::1			cpy	#jobFetch		;FetchRAM ?
			bne	:2			; => Nein, weiter...
			jsr	SCPU_X16_FETCH		;FetchRAM für SCPU ausführen.
			jmp	:ok

::2			cpy	#jobSwap		;SwapRAM ?
			bne	:3			; => Nein, weiter...
			jsr	SCPU_X16_SWAP		;SwapRAM für SCPU ausführen.
			jmp	:ok

::3			cpy	#jobVerify		;VerifyRAM ?
			bne	:err			; => Nein, weiter...
			jsr	SCPU_X16_VERIFY		;VerifyRAM für SCPU ausführen.
			txa				;Verify-Error ?
			beq	:ok			; => Nein, weiter...

::err			ldy	#%00100000		;Fehler...
			b $2c
::ok			ldy	#%01000000		;Kein Fehler...
			ldx	#NO_ERROR
			rts
