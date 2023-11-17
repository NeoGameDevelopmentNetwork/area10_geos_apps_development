; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "obj.DvRAM_RL"
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
			h "RAMLink-RAM-Funktionen..."

;******************************************************************************
;RAM_Type = RAM_RL
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
			lda	#$36
			sta	CPU_DATA
endif
if Flag64_128 = TRUE_C128
			lda	MMU
			pha
			lda	#$4e
			sta	MMU
			lda	RAM_Conf_Reg
			pha
			and	#$f0
			ora	#$04
			sta	RAM_Conf_Reg
endif

			jsr	$e0a9

			sty	EXP_BASE2    + 1

			ldx	#$01
::51			lda	r0L,x			;Computer Address Pointer.
			sta	EXP_BASE2    + 2,x
			lda	r2L,x			;Transfer Length.
			sta	EXP_BASE2    + 7,x
			dex
			bpl	:51
			inx
			stx	EXP_BASE2    +10	;Address Control.
if Flag64_128 = TRUE_C128
			inx				;C128 Bank #1.
			stx	EXP_BASE2    +16
endif

			lda	r1L			;RAMLink System Adress Pointer.
			sta	EXP_BASE2    + 4
			lda	r1H
			clc
			adc	RamBankFirst + 0
			sta	EXP_BASE2    + 5
			lda	r3L
			adc	RamBankFirst + 1
			sta	EXP_BASE2    + 6

			jsr	$fe06			;Job ausführen.

			lda	EXP_BASE2    + 0	;Fehlerflag auslesen und
			pha				;zwischenspeichern.
			jsr	$fe0f			;RL-Hardware abschalten.
			pla
			tax

if Flag64_128 = TRUE_C64
			pla
			sta	CPU_DATA		;I/O ausblenden.
endif
if Flag64_128 = TRUE_C128
			pla
			sta	RAM_Conf_Reg
			pla
			sta	MMU
endif
			plp

			txa
			ldx	#NO_ERROR		;Kein Fehler.
:ramOpErr		rts

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g BASE_RAM_DRV_END
;******************************************************************************
