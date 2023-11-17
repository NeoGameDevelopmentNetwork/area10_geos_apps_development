; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Einsprungtabelle RAM-Tools/GeoRAM.
;--- Hinweis:
;"-R3_DoRAM_GRAM"
;Diese Routine ist die Kernal-Routine
;für die ":DoRAMOp"-Funktionen.
;"-R3_DoRAM_GUPD"
;Diese Routine enthält eine temporäre
;":DoRAMOp"-Routine für "GD.UPDATE",
;da die Original-GEOS-Routine die Daten
;in einem anderen Format speichert.
;Siehe Kommentare in "-G3_UpdRAMOp".
:VerifyRAM_GRAM		ldy	#jobVerify		;RAM-Bereich vergleichen.
			b $2c
:StashRAM_GRAM		ldy	#jobStash		;RAM-Bereich speichern.
			b $2c
:SwapRAM_GRAM		ldy	#jobSwap		;RAM-Bereich tauschen.
			b $2c
:FetchRAM_GRAM		ldy	#jobFetch		;RAM-Bereich laden.

:JobRAM_GRAM		php				;IRQ sperren.
			sei

			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#IO_IN
			sta	CPU_DATA

			lda	GRAM_BANK_SIZE		;Bank-Größe einlesen und
			jsr	DoRAMOp_GRAM		;Job ausführen.
			tay				;AKKU-Register speichern.

			pla
			sta	CPU_DATA

			plp				;IRQ-Status zurücksetzen.

			tya				;Job-Ergebnis in AKKU übergeben.
			ldx	#NO_ERROR		;Flag für "Kein Fehler".
			rts
