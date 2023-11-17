; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "TopSym"
			t "TopMac"
			t "TopSym.FBoot"

;--- SuperCPU-Register.
:SCPU_HW_EN		= $d07e
:SCPU_HW_DIS		= $d07f
:SCPU_HW_CHECK		= $d0bc
:SCPU_HW_OPT		= $d0b4
:SCPU_HW_NORMAL		= $d07a
:SCPU_HW_TURBO		= $d07b
:SCPU_HW_SPEED		= $d0b8
:SCPU_HW_VIC_OPT	= $d074
:SCPU_HW_VIC_B2		= $d074
:SCPU_HW_VIC_B1		= $d075
:SRAM_FIRST_PAGE	= $d27c
:SRAM_FIRST_BANK	= $d27d
:SRAM_LAST_PAGE		= $d27e
:SRAM_LAST_BANK		= $d27f
:SRAM_USER_PAGE		= $d300				;Free RAM $D300-$D3FF.

;--- Ergänzung: 08.07.18/M.Kanet
;Adressen für Prüfung der SuperCPU-Version.
:SCPU_ROM_VER		= $e487
endif

;*** GEOS-Header.
			n "FBOOT64-SCPU"
			t "inc.FBoot.Class"
			a "Markus Kanet"
			f 4				;Typ Systemdatei.
			z $80				;nur GEOS64

			o $0801 -2

			i
<MISSING_IMAGE_DATA>

			h "GEOS FastBoot for SCPU/RAM,"
			h "GEOS64 and GEOS64/MP3..."

;******************************************************************************
;*** BASIC-Header.
;******************************************************************************
			t "inc.FBoot.BASIC"
;******************************************************************************

;*** Systemvariablen.
:BOOT_DEVICE		b $00				;Laufwerksadresse.
:BOOT_GEOS_VER		b $00
:IRQ_VEC_buf		w $0000				;Zwischenspeicher IRQ-Routine.

;******************************************************************************
;*** FBoot-Hauptprogramm.
;******************************************************************************
			t "inc.FBoot.Core"
;******************************************************************************

;*** Speichererweiterung testen.
:TEST_DACC_DEV		php
			sei

			ldy	CPU_DATA
			lda	#KRNL_BAS_IO_IN		;Kernal-ROM + I/O einblenden.
			sta	CPU_DATA

			ldx	#$ff			;SuperCPU verügbar ?
			bit	SCPU_HW_CHECK
			bpl	:1
			inx

::1			sty	CPU_DATA
			plp

			txa
			beq	:no_scpu

			jsr	DetectSCPU		;Speichererweiterung testen.
			txa				;RAMCard installiert ?
			bne	:no_scpu		; => Nein, Abbruch...

			ldx	#NO_ERROR		;ReBoot initialisieren.
			rts

::no_scpu		ldx	#DEV_NOT_FOUND
			rts

;*** FetchRAM-Routine für ReBoot.
:execFetchRAM		sei
			php

			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#IO_IN
			sta	CPU_DATA

			ldy	#%10010001		;JobCode "FetchRAM".
			jsr	DoRAMOp_SRAM
			tay

			pla
			sta	CPU_DATA

			tya
			plp				;I/O deaktivieren.
			rts

;******************************************************************************
;*** Zusatzroutinen.
;******************************************************************************
			t "-R3_DetectSRAM"
			t "-R3_DoRAMOpSRAM"
			t "-R3_SRAM16Bit"
;******************************************************************************
