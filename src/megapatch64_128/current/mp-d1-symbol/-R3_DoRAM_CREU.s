; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Einsprungtabelle RAM-Tools/CREU.
:VerifyRAM_CREU		ldy	#%10010011		;RAM-Bereich vergleichen.
			b $2c
:StashRAM_CREU		ldy	#%10010000		;RAM-Bereich speichern.
			b $2c
:SwapRAM_CREU		ldy	#%10010010		;RAM-Bereich tauschen.
			b $2c
:FetchRAM_CREU		ldy	#%10010001		;RAM-Bereich laden.

:JobRAM_CREU		ldx	#$0d			;DEV_NOT_FOUND
			lda	r3L
			cmp	ramExpSize		;Speicherbank verfügbar?
			bcs	:err			; => Nein, Fehler...

			php
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
			lda	RAM_Conf_Reg
			pha
			lda	#$40			;keine CommonArea VIC =
			sta	RAM_Conf_Reg		;Bank1 für REU Transfer
			lda	CLKRATE			;aktuellen Takt
			pha				;zwischenspeichern.
			lda	#$00			;auf 1 Mhz schalten!
			sta	CLKRATE			;Sonst geht nichts!
endif

			jsr	DoRAMOp_CREU		;Job ausführen.
			tay				;Ergebniss zwischenspeichern.

if Flag64_128 = TRUE_C64
			pla
			sta	CPU_DATA
endif
if Flag64_128 = TRUE_C128
			pla				;aktuellen Takt zurücksetzen
			sta	CLKRATE
			pla
			sta	RAM_Conf_Reg
			pla
			sta	MMU
endif

			plp

			tya				;Job-Ergebnis in AKKU übergeben.
			ldx	#NO_ERROR
::err			rts
