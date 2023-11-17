; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "obj.DvRAM_REU"
			t "G3_SymMacExt"

if Flag64_128 = TRUE_C64
			t "G3_V.Cl.64.Data"
endif
if Flag64_128 = TRUE_C128
			t "G3_V.Cl.128.Data"
endif

			o BASE_RAM_DRV

			r BASE_RAM_DRV +SIZE_RAM_DRV

			h "MegaPatch-Kernal"
			h "C=REU-RAM-Funktionen..."

;******************************************************************************
;RAM_Type = RAM_REU
;******************************************************************************
;*** Einsprungtabelle RAM-Tools.
:xVerifyRAM		ldy	#%10010011		;RAM-Bereich vergleichen.
			b $2c
:xStashRAM		ldy	#%10010000		;RAM-Bereich speichern.
			b $2c
:xSwapRAM		ldy	#%10010010		;RAM-Bereich tauschen.
			b $2c
:xFetchRAM		ldy	#%10010001		;RAM-Bereich laden.

:xDoRAMOp		ldx	#$0d			;DEV_NOT_FOUND
			lda	r3L
			cmp	ramExpSize		;Speicherbank verfügbar?
			bcs	ramOpErr		; => Nein, Fehler...

;--- Einsprung für BootGEOS ($c000).
:xDoRAMOp_NoChk		php
			sei

if Flag64_128 = TRUE_C64
			lda	CPU_DATA
			pha
			lda	#$35
			sta	CPU_DATA
endif
if Flag64_128 = TRUE_C128
			lda	MMU			;Sonst geht nichts!
			pha
			lda	#$7e
			sta	MMU
			lda	RAM_Conf_Reg
			pha
			lda	#$40			;keine CommonArea VIC =
			sta	RAM_Conf_Reg		;Bank1 für REU Transfer
			lda	CLKRATE			;aktuellen Takt
			pha				;zwischenspeichern.
			lda	#$00
			sta	CLKRATE			;auf 1 Mhz schalten!
endif

			ldx	#$03
::51			lda	r0L         ,x
			sta	EXP_BASE1 +2,x
			dex
			bpl	:51

			lda	r3L			;Bank in der REU.
			sta	EXP_BASE1 + 6
			lda	r2L
			sta	EXP_BASE1 + 7
			lda	r2H			;Anzahl Bytes.
			sta	EXP_BASE1 + 8
			lda	#$00
			sta	EXP_BASE1 + 9
			sta	EXP_BASE1 +10
			sty	EXP_BASE1 + 1

::52			lda	EXP_BASE1 + 0		;Job ausführen.
			and	#%01100000
			beq	:52
			tax				;Job-Ergebnis retten.

if Flag64_128 = TRUE_C64
			pla
			sta	CPU_DATA		;CPU-Register zurücksetzen.
endif
if Flag64_128 = TRUE_C128
			pla				;aktuellen Takt zurücksetzen
			sta	CLKRATE
			pla
			sta	RAM_Conf_Reg
			pla
			sta	MMU
endif

			txa				;Job-Ergebnis zurücksetzen.
			plp
			ldx	#NO_ERROR
:ramOpErr		rts

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g BASE_RAM_DRV_END
;******************************************************************************
