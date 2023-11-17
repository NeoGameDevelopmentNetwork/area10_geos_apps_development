; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "obj.ReBoot.REU"
			t "G3_SymMacExt"

			o BASE_REBOOT
			p GEOS_ReBootSys

:RBOOT_TYPE		= RAM_REU

if Flag64_128 = TRUE_C64
			t "G3_V.Cl.64.Data"
			t "-G3_ReBootCode"
endif
if Flag64_128 = TRUE_C128
			t "G3_V.Cl.128.Data"
			t "+G3_ReBootCode"
endif

;*** DoRAMOp-Routine für C=REU.
			t "-R3_DoRAMOpCREU"

;*** FetchRAM-Routine für ReBoot.
:SysFetchRAM		sei
			php

if Flag64_128 = TRUE_C64
			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#$35
			sta	CPU_DATA
endif
if Flag64_128 = TRUE_C128
			lda	MMU			;I/O-Bereich aktivieren.
			pha
			lda	#$7e
			sta	MMU
			lda	CLKRATE
			pha
			lda	#$00
			sta	CLKRATE
endif

			ldy	#%10010001		;JobCode "FetchRAM".
			jsr	DoRAMOp_CREU
			tay

if Flag64_128 = TRUE_C64
			pla
			sta	CPU_DATA
endif
if Flag64_128 = TRUE_C128
			pla
			sta	CLKRATE
			pla
			sta	MMU
endif

			tya
			plp				;I/O deaktivieren.
			rts

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g BASE_REBOOT+R1_SIZE_REBOOT
;******************************************************************************
