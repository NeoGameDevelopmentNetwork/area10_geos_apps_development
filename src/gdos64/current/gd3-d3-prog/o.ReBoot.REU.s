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
			t "MacTab"

;--- RBOOT-Speicher.
:RBOOT_TYPE		= RAM_REU
endif

;*** GEOS-Header.
			n "obj.ReBoot.REU"
			f DATA

			o BASE_REBOOT

			r BASE_REBOOT +R1S_REBOOT

;*** Sprungtabelle + Variablen.
:MainInit		jmp	GEOS_ReBootSys

;*** Startadresse in REU (nicht verwendet).
:BASE_DACC_ADR		w $0000				;Kopie von RamBankFirst.

;*** Systemroutinen.
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
			g BASE_REBOOT + R1S_REBOOT
;******************************************************************************
