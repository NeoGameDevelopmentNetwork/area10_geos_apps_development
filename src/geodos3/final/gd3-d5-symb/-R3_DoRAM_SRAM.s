; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Einsprungtabelle RAM-Tools/SRAM.
:VerifyRAM_SRAM		ldy	#jobVerify		;RAM-Bereich vergleichen.
			b $2c
:StashRAM_SRAM		ldy	#jobStash		;RAM-Bereich speichern.
			b $2c
:SwapRAM_SRAM		ldy	#jobSwap		;RAM-Bereich tauschen.
			b $2c
:FetchRAM_SRAM		ldy	#jobFetch		;RAM-Bereich laden.

:JobRAM_SRAM		php				;IRQ sperren.
			sei

			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#IO_IN
			sta	CPU_DATA

			jsr	DoRAMOp_SRAM		;Job ausführen.
			tay				;Ergebnis zwischenspeichern.

			pla
			sta	CPU_DATA		;CPU-Register zurücksetzen.

			plp				;IRQ-Status zurücksetzen.

			tya				;Job-Ergebnis in AKKU übergeben.
			ldx	#NO_ERROR		;Flag für "Kein Fehler".
			rts
