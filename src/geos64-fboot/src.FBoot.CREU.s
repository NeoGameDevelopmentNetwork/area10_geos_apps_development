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

;--- Speichererweiterung.
;EXP_BASE		= $df00				;Base address of RAM expansion unit #1 & 2
:EXP_BASE1		= $df00				;Base address of RAM expansion unit #1
:EXP_BASE2		= $de00				;Base address of RAM expansion unit #2
endif

;*** GEOS-Header.
			n "FBOOT64-CREU"
			t "inc.FBoot.Class"
			a "Markus Kanet"
			f 4				;Typ Systemdatei.
			z $80				;nur GEOS64

			o $0801 -2

			i
<MISSING_IMAGE_DATA>

			h "GEOS FastBoot for C=REU,"
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

;*** FetchRAM-Routine für ReBoot.
:execFetchRAM		php
			sei

			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#IO_IN
			sta	CPU_DATA

			ldy	#%10010001		;JobCode "FetchRAM".
			jsr	DoRAMOp_CREU
			tay

			pla
			sta	CPU_DATA		;I/O deaktivieren.

			tya
			plp
			rts

;******************************************************************************
;*** Zusatzroutinen.
;******************************************************************************
			t "-R3_DetectCREU"
:TEST_DACC_DEV		= DetectCREU			;Speichererweiterung testen.

			t "-R3_DoRAMOpCREU"
;******************************************************************************
