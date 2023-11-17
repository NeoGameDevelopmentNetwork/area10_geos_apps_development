; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "obj.ReBoot.SCPU"
			t "G3_SymMacExt"

			o BASE_REBOOT
			p GEOS_ReBootSys

:RBOOT_TYPE		= RAM_SCPU

if Flag64_128 = TRUE_C64
			t "G3_V.Cl.64.Data"
			t "-G3_ReBootCode"
endif
if Flag64_128 = TRUE_C128
			t "G3_V.Cl.128.Data"
			t "+G3_ReBootCode"
endif

;*** DoRAMOp-Routine für RAMCard.
			t "-R3_DoRAMOpSRAM"
			t "-R3_SRAM16Bit"

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
endif

			ldy	#%10010001		;JobCode "FetchRAM".
			jsr	DoRAMOp_SRAM
			tay

if Flag64_128 = TRUE_C64
			pla
			sta	CPU_DATA
endif
if Flag64_128 = TRUE_C128
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
