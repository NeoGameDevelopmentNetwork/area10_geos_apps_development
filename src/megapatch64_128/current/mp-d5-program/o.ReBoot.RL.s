; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "obj.ReBoot.RL"
			t "G3_SymMacExt"

			o BASE_REBOOT
			p GEOS_ReBootSys

:RBOOT_TYPE		= RAM_RL

if Flag64_128 = TRUE_C64
			t "G3_V.Cl.64.Data"
			t "-G3_ReBootCode"
endif
if Flag64_128 = TRUE_C128
			t "G3_V.Cl.128.Data"
			t "+G3_ReBootCode"
endif

;*** FetchRAM-Routine für ReBoot.
:SysFetchRAM		sei
			php

if Flag64_128 = TRUE_C64
			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#$36
			sta	CPU_DATA
endif
if Flag64_128 = TRUE_C128
			lda	MMU			;I/O-Bereich aktivieren.
			pha
			lda	#$4e
			sta	MMU
			lda	RAM_Conf_Reg
			pha
			and	#%11110000
			ora	#%00000100
			sta	RAM_Conf_Reg
endif

			jsr	$e0a9

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
if Flag64_128 = TRUE_C128
			inx				;Bank für C128-Transfer.
			stx	EXP_BASE2 +16
endif

			ldy	#$91			;JobCode setzen.
			sty	EXP_BASE2 + 1

			jsr	$fe06			;Job ausführen und
			jsr	$fe0f			;RL-Hardware abschalten.

if Flag64_128 = TRUE_C64
			pla
			sta	CPU_DATA
endif
if Flag64_128 = TRUE_C128
			pla
			sta	RAM_Conf_Reg
			pla
			sta	MMU
endif

			ldy	#%01000000
			plp				;I/O deaktivieren.
			rts

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g BASE_REBOOT+R1_SIZE_REBOOT
;******************************************************************************
