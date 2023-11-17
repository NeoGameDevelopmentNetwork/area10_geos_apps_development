; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Einsprungtabelle RAM-Funktionen.
;Übergabe: r0   = Startadresse C64-RAM.
;          r1   = Startadresse REU.
;          r2   = Anzahl Bytes.
;          r3L  = Speicherbank.
;          yReg = Job-Code.
;Rückgabe: -
;Geändert: AKKU,xReg,yReg
;
:DoRAMOp_DISK		php				;IRQ sperren.
			sei

			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#IO_IN
			sta	CPU_DATA

			lda	r3L			;Speicherbank für Sektoradresse.
			jsr	DoRAMOp_SRAM		;Job ausführen.

			pla
			sta	CPU_DATA

			plp				;IRQ-Status zurücksetzen.

			tya
;			ldx	#NO_ERROR
			rts
