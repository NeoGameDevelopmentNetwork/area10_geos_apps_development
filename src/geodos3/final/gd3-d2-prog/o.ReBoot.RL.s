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
			t "SymbTab_RLNK"
endif

;*** GEOS-Header.
			n "obj.ReBoot.RL"
			t "G3_Data.V.Class"

			o BASE_REBOOT
			p GEOS_ReBootSys

:RBOOT_TYPE		= RAM_RL

			t "-G3_ReBootCode"

;*** FetchRAM-Routine für ReBoot.
:SysFetchRAM		sei
			php

			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#KRNL_IO_IN
			sta	CPU_DATA

			jsr	EN_SET_REC

			ldx	#$04
::51			lda	zpage     + 1,x
			sta	EXP_BASE2 + 1,x
			dex
			bne	:51

			ldx	#$00			;RAMLink-HighByte für Transfer.
			stx	EXP_BASE2 + 6

			lda	r2L			;Anzahl Bytes.
			sta	EXP_BASE2 + 7
			lda	r2H
			sta	EXP_BASE2 + 8
			stx	EXP_BASE2 +10		;AddressControl -> r0L/r1L erhöhen.

			ldy	#$91			;JobCode setzen.
			sty	EXP_BASE2 + 1

			jsr	EXEC_REC_REU		;Job ausführen und
			jsr	RL_HW_DIS2		;RL-Hardware abschalten.

			pla
			sta	CPU_DATA

			ldy	#%01000000
			plp				;I/O deaktivieren.
			rts

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g BASE_REBOOT+R1_SIZE_REBOOT
;******************************************************************************
