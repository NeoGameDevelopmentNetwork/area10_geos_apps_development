; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExt"

;*** Zusätzliche Symboltabellen.
if .p
			t "SymbTab_SCPU"
endif

;*** GEOS-Header.
			n "obj.ReBoot.SCPU"
			t "G3_Data.V.Class"

			o BASE_REBOOT
			p GEOS_ReBootSys

:RBOOT_TYPE		= RAM_SCPU

			t "-G3_ReBootCode"

;*** DoRAMOp-Routine für RAMCard.
			t "-R3_DoRAMOpSRAM"
			t "-R3_SRAM16Bit"

;--- DoRAMOpSRAM für GEOS-DACC/Disk.
:DefBankAdrSRAM		= DefBankAdrDACC
;DefBankAdrSRAM		= DefBankAdrDISK

;*** FetchRAM-Routine für ReBoot.
:SysFetchRAM		sei
			php

			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#IO_IN
			sta	CPU_DATA

			ldy	#jobFetch		;JobCode "FetchRAM".
			jsr	DoRAMOp_SRAM
			tay

			pla
			sta	CPU_DATA

			tya
			plp				;I/O deaktivieren.
			rts

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g BASE_REBOOT+R1_SIZE_REBOOT
;******************************************************************************
