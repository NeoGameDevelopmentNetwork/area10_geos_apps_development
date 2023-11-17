; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "obj.ReBoot.BBG"
			t "G3_SymMacExt"

			o BASE_REBOOT
			p GEOS_ReBootSys

:RBOOT_TYPE		= RAM_BBG

if Flag64_128 = TRUE_C64
			t "G3_V.Cl.64.Data"
			t "-G3_ReBootCode"
endif
if Flag64_128 = TRUE_C128
			t "G3_V.Cl.128.Data"
			t "+G3_ReBootCode"
endif

;*** Definierenn der GeoRAM-Register.
:GRAM_PAGE_DATA		= $de00
:GRAM_PAGE_SLCT		= $dffe
:GRAM_BANK_SLCT		= $dfff

:GRAM_BSIZE_0K		= 0
:GRAM_BSIZE_16K		= 16
:GRAM_BSIZE_32K		= 32
:GRAM_BSIZE_64K		= 64

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

			lda	GRAM_BANK_SIZE
			bne	:1
			jsr	GRamGetBankSize
			lda	GRAM_BANK_SIZE
::1			ldy	#%10010001		;JobCode "FetchRAM".
			jsr	DoRAMOp_GRAM
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
