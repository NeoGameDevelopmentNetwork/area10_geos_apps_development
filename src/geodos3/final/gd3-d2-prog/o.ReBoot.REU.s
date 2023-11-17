; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExt"

;*** GEOS-Header.
			n "obj.ReBoot.REU"
			t "G3_Data.V.Class"

			o BASE_REBOOT
			p GEOS_ReBootSys

:RBOOT_TYPE		= RAM_REU

			t "-G3_ReBootCode"

;*** DoRAMOp-Routine für C=REU.
			t "-R3_DoRAMOpCREU"

;*** FetchRAM-Routine für ReBoot.
:SysFetchRAM		sei
			php

			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#IO_IN
			sta	CPU_DATA

			ldy	#jobFetch		;JobCode "FetchRAM".
			jsr	DoRAMOp_CREU
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
