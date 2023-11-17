; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Einsprungtabelle RAM-Tools/SRAM.
;
; Wird nur innerhalb des Kernal oder
; dem RAM-Treiber verwendet.
;
:xVerifyRAM		ldy	#jobVerify		;RAM-Bereich vergleichen.
			b $2c
:xStashRAM		ldy	#jobStash		;RAM-Bereich speichern.
			b $2c
:xSwapRAM		ldy	#jobSwap		;RAM-Bereich tauschen.
			b $2c
:xFetchRAM		ldy	#jobFetch		;RAM-Bereich laden.

:xDoRAMOp		ldx	#$0d			;DEV_NOT_FOUND
			lda	r3L
			cmp	ramExpSize		;Speicherbank verfügbar?
			bcs	ramOpErr		; => Nein, Fehler...

;--- Einsprung für BootGEOS ($c000).
:xDoRAMOp_NoChk		php				;IRQ sperren.
			sei

			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#IO_IN
			sta	CPU_DATA

:DvRAM_HByt		lda	#$ff			; -> RamBankFirst +1
			clc
			adc	r3L

::0			cpy	#jobStash		;StashRAM ?
			bne	:1			; => Nein, weiter...
			jsr	SRAM_D300_STASH		;StashRAM für SCPU ausführen.
			jmp	:ok

::1			cpy	#jobFetch		;FetchRAM ?
			bne	:2			; => Nein, weiter...
			jsr	SRAM_D300_FETCH		;FetchRAM für SCPU ausführen.
			jmp	:ok

::2			cpy	#jobSwap		;SwapRAM ?
			bne	:3			; => Nein, weiter...
			jsr	SRAM_D300_SWAP		;SwapRAM für SCPU ausführen.
			jmp	:ok

::3			cpy	#jobVerify		;VerifyRAM ?
			bne	:err			; => Nein, weiter...
			jsr	SRAM_D300_VERIFY	;VerifyRAM für SCPU ausführen.
			txa				;Verify-Error ?
			beq	:ok			; => Nein, weiter...

::err			ldy	#%00100000		;Fehler...
			b $2c
::ok			ldy	#%01000000		;Kein Fehler...

			pla
			sta	CPU_DATA		;CPU-Register zurücksetzen.

			plp				;IRQ-Status zurücksetzen.

			tya				;Job-Ergebnis in AKKU übergeben.
			ldx	#NO_ERROR		;Flag für "Kein Fehler".
:ramOpErr		rts
