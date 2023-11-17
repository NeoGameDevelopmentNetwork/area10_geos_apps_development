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
			t "SymbTab_RLNK"
			t "MacTab"

;--- RBOOT-Speicher.
:RBOOT_TYPE		= RAM_RL
endif

;*** GEOS-Header.
			n "obj.ReBoot.RL"
			f DATA

			o BASE_REBOOT

			r BASE_REBOOT +R1S_REBOOT

;*** Sprungtabelle + Variablen.
:MainInit		jmp	GEOS_ReBootSys

;*** Startadresse in RAMCard.
:BASE_DACC_ADR		w $0000				;Kopie von RamBankFirst.

;*** Systemroutinen.
			t "-G3_ReBootCode"

;*** FetchRAM-Routine für ReBoot.
:SysFetchRAM		sei
			php

			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#KRNL_IO_IN
			sta	CPU_DATA

			jsr	EN_SET_REC

			ldx	#$01
::51			lda	r0,x			;Computer Address Pointer.
			sta	EXP_BASE2 + 2,x
			lda	r2,x			;Transfer Length.
			sta	EXP_BASE2 + 7,x
			dex
			bpl	:51

			inx
;			stx	EXP_BASE2 + 9		;Not used.
			stx	EXP_BASE2 +10		;Address Control.

			lda	r1L			;RAMLink System Address Pointer.
			sta	EXP_BASE2 + 4
			lda	r1H
			clc
			adc	BASE_DACC_ADR +0
			sta	EXP_BASE2 + 5
			lda	#$00
			clc
			adc	BASE_DACC_ADR +1
			sta	EXP_BASE2 + 6

			ldy	#$91			;JobCode setzen.
			sty	EXP_BASE2 + 1		;Job ausführen.

			jsr	EXEC_REC_REU		;Job ausführen und
			jsr	RL_HW_DIS2		;RL-Hardware abschalten.

			pla
			sta	CPU_DATA		;I/O-Bereich deaktivieren.

			ldy	#%01000000
			plp				;Interrupt zurücksetzen.
			rts

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g BASE_REBOOT + R1S_REBOOT
;******************************************************************************
