; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Einsprungtabelle RAM-Tools/GeoRAM.
:VerifyRAM_GRAM		ldy	#%10010011		;RAM-Bereich vergleichen.
			b $2c
:StashRAM_GRAM		ldy	#%10010000		;RAM-Bereich speichern.
			b $2c
:SwapRAM_GRAM		ldy	#%10010010		;RAM-Bereich tauschen.
			b $2c
:FetchRAM_GRAM		ldy	#%10010001		;RAM-Bereich laden.

:JobRAM_GRAM		ldx	#$0d			;DEV_NOT_FOUND
			lda	r3L
			cmp	ramExpSize		;Speicherbank verfügbar?
			bcs	:err			; => Nein, Fehler...

			php				;IRQ sperren.
			sei

if Flag64_128 = TRUE_C64
			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#$35
			sta	CPU_DATA
endif
if Flag64_128 = TRUE_C128
			lda	MMU
			pha
			lda	#$7e
			sta	MMU
endif

			lda	GRAM_BANK_SIZE		;Bank-Größe einlesen und
			jsr	DoRAMOp_GRAM		;Job ausführen.
			tay				;AKKU-Register speichern.

if Flag64_128 = TRUE_C64
			pla
			sta	CPU_DATA
endif
if Flag64_128 = TRUE_C128
			pla
			sta	MMU
endif

			plp				;IRQ-Status zurücksetzen.

			tya				;Job-Ergebnis in AKKU übergeben.
			ldx	#NO_ERROR		;Flag für "Kein Fehler".
::err			rts
