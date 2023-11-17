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
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_MMAP"
			t "SymbTab_GRAM"
			t "MacTab"

;--- RBOOT-Speicher.
:RBOOT_TYPE		= RAM_BBG
endif

;*** GEOS-Header.
			n "obj.ReBoot.BBG"
			f DATA

			o BASE_REBOOT

			r BASE_REBOOT +R1S_REBOOT

;*** Sprungtabelle.
:MainInit		jmp	GEOS_ReBootSys

;*** Startadresse in REU (nicht verwendet).
:BASE_DACC_ADR		w $0000				;Kopie von RamBankFirst.

;*** Systemroutinen.
			t "-G3_ReBootCode"

;*** Größe der Speicherbänke in der GeoRAM 16/32/64Kb.
;--- Ergänzung: 11.09.18/M.Kanet:
;Dieser Variablenspeicher muss im Hauptprogramm an einer Stelle
;definiert werden der nicht durch das nachladen weiterer Programmteile
;überschrieben wird!
:GRAM_BANK_SIZE		b $00

;*** DoRAMOp-Routine für GeoRAM.
			t "-R3_DoRAMOpGRAM"
			t "-R3_GetSBnkGRAM"

;*** FetchRAM-Routine für ReBoot.
:SysFetchRAM		sei
			php

			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#IO_IN
			sta	CPU_DATA

			lda	GRAM_BANK_SIZE
			bne	:1
			jsr	GRamGetBankSize
			lda	GRAM_BANK_SIZE
::1			ldy	#jobFetch		;JobCode "FetchRAM".
			jsr	DoRAMOp_GRAM
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
