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

;--- Definieren der GeoRAM-Register.
:GRAM_PAGE_DATA		= $de00
:GRAM_PAGE_SLCT		= $dffe
:GRAM_BANK_SLCT		= $dfff

:GRAM_BSIZE_0K		= 0
:GRAM_BSIZE_16K		= 16
:GRAM_BSIZE_32K		= 32
:GRAM_BSIZE_64K		= 64
endif

;*** GEOS-Header.
			n "FBOOT64-GRAM"
			t "inc.FBoot.Class"
			a "Markus Kanet"
			f 4				;Typ Systemdatei.
			z $80				;nur GEOS64

			o $0801 -2

			i
<MISSING_IMAGE_DATA>

			h "GEOS FastBoot for GeoRAM,"
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

;*** Größe der Speicherbänke in der GeoRAM 16/32/64Kb.
;--- Ergänzung: 11.09.18/M.Kanet
;Dieser Variablenspeicher muss im Hauptprogramm an einer Stelle
;definiert werden, der nicht durch das nachladen weiterer Programmteile
;überschrieben wird!
:GRAM_BANK_SIZE		b $00

;******************************************************************************
;*** FBoot-Hauptprogramm.
;******************************************************************************
			t "inc.FBoot.Core"
;******************************************************************************

;*** Speichererweiterung testen.
:TEST_DACC_DEV		jsr	DetectGRAM		;Speichererweiterung testen.
			txa				;BBGRAM installiert ?
			bne	:no_gram		; => Nein, Abbruch...

			php
			sei				;Interrupt sperren.

			jsr	GRamGetBankSize		;Bank-Größe für GeoRAM ermitteln.

			plp				;IRQ-Status zurücksetzen.

			txa				;Speicherfehler?
			bne	:no_gram

			ldx	#NO_ERROR		;ReBoot initialisieren.
			rts

::no_gram		ldx	#DEV_NOT_FOUND
			rts

;*** FetchRAM-BBG-Routine für ReBoot.
:execFetchRAM		sei
			php

			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#IO_IN
			sta	CPU_DATA

			lda	GRAM_BANK_SIZE
			ldy	#%10010001		;JobCode "FetchRAM".
			jsr	DoRAMOp_GRAM
			tay

			pla
			sta	CPU_DATA		;I/O deaktivieren.

			tya
			plp
			rts

;******************************************************************************
;*** Zusatzroutinen.
;******************************************************************************
			t "-R3_DetectGRAM"
			t "-R3_DoRAMOpGRAM"
			t "-R3_GetSBnkGRAM"
;******************************************************************************
