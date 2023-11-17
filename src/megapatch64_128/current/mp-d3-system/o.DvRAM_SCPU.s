; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "obj.DvRAM_SCPU"
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
			h "RAMCard-RAM-Funktionen..."

;******************************************************************************
;RAM_Type = RAM_SCPU
;******************************************************************************
;*** SuperCPU-Kernal-Einsprünge.
			t "o.Patch_SRAM.ext"

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

			cpy	#%10010000		;StashRAM ?
			bne	:51			; => Nein, weiter...
			jsr	StashRAM_SCPU		;StashRAM für SCPU ausführen.
			jmp	:54

::51			cpy	#%10010001		;FetchRAM ?
			bne	:52			; => Nein, weiter...
			jsr	FetchRAM_SCPU		;FetchRAM für SCPU ausführen.
			jmp	:54

::52			cpy	#%10010010		;SwapRAM ?
			bne	:53			; => Nein, weiter...
			jsr	SwapRAM_SCPU		;SwapRAM für SCPU ausführen.
			jmp	:54

::53			cpy	#%10010011		;SwapRAM ?
			bne	:54			; => Nein, weiter...
			jsr	VerifyRAM_SCPU		;SwapRAM für SCPU ausführen.
			txa				;Verify-Error ?
			beq	:54			; => Nein, weiter...

			ldx	#%00100000
			b $2c
::54			ldx	#%01000000		;Kein Fehler...

if Flag64_128 = TRUE_C64
			pla				;I/O-Bereiche deaktivieren.
			sta	CPU_DATA
endif
if Flag64_128 = TRUE_C128
			pla
			sta	MMU
endif

			plp

			txa				;Zurück zum Programm.
			ldx	#NO_ERROR
:ramOpErr		rts

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g BASE_RAM_DRV_END
;******************************************************************************
