; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "SymbTab_CSYS"
			t "SymbTab_CXIO"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GTYP"
			t "SymbTab_MMAP"
			t "SymbTab_SCPU"
			t "MacTab"

;--- RBOOT-Speicher.
:RBOOT_TYPE		= RAM_SCPU
endif

;*** GEOS-Header.
			n "obj.ReBoot.SCPU"
			f DATA

			o BASE_REBOOT

			r BASE_REBOOT +R1S_REBOOT

;*** Sprungtabelle.
:MainInit		jmp	GEOS_ReBootSys

;*** Startadresse in RAMCard.
:BASE_DACC_ADR		w $0000				;Kopie von RamBankFirst.

;*** Systemroutinen.
			t "-G3_ReBootCode"

;*** DoRAMOp-Routine für RAMCard.
			t "-R3_DoRAMOpSRAM"
			t "-R3_SRAM16Bit"

;*** FetchRAM-Routine für ReBoot.
:SysFetchRAM		sei
			php

			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#IO_IN
			sta	CPU_DATA

			ldy	#jobFetch		;JobCode "FetchRAM".
			lda	BASE_DACC_ADR +1	; -> RamBankFirst +1
			jsr	DoRAMOp_SRAM		;Job ausführen.

			pla
			sta	CPU_DATA

			tya
			plp				;I/O deaktivieren.
			rts

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g BASE_REBOOT + R1S_REBOOT
;******************************************************************************
