; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Einsprungtabelle RAM-Tools/CREU.
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
:xDoRAMOp_NoChk		php
			sei

			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#IO_IN
			sta	CPU_DATA

			jsr	DoRAMOp_CREU		;Job ausführen.
			tay				;Ergebnis zwischenspeichern.

			pla
			sta	CPU_DATA		;CPU-Register zurücksetzen.

			plp

			tya				;Job-Ergebnis in AKKU übergeben.
			ldx	#NO_ERROR
:ramOpErr		rts
