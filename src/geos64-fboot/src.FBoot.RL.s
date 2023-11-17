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

;--- Einsprünge im RAMLink-Kernal.
:EN_SET_REC		= $e0a9
:RL_HW_EN		= $e0b1
:SET_REC_IMG		= $fe03
:EXEC_REC_REU		= $fe06
:EXEC_REC_SEC		= $fe09
:RL_HW_DIS		= $fe0c
:RL_HW_DIS2		= $fe0f
:EXEC_REU_DIS		= $fe1e
:EXEC_SEC_DIS		= $fe21
endif

;*** GEOS-Header.
			n "FBOOT64-RL"
			t "inc.FBoot.Class"
			a "Markus Kanet"
			f 4				;Typ Systemdatei.
			z $80				;nur GEOS64

			o $0801 -2

			i
<MISSING_IMAGE_DATA>

			h "GEOS FastBoot for RAMLink,"
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

			ldx	#$ff			;RAMLink verügbar ?
			lda	EN_SET_REC
			cmp	#$78
			beq	:1
			inx

::1			sty	CPU_DATA
			plp

			txa
			beq	:no_rlnk

			jsr	DetectRLNK		;Speichererweiterung testen.
			txa				;RAMLink installiert ?
			bne	:no_rlnk		; => Nein, Abbruch...

			ldx	#NO_ERROR		;ReBoot initialisieren.
			rts

::no_rlnk		ldx	#DEV_NOT_FOUND
			rts

;*** FetchRAM-Routine für ReBoot.
:execFetchRAM		php
			sei

			lda	CPU_DATA
			pha
			lda	#KRNL_IO_IN
			sta	CPU_DATA

			jsr	EN_SET_REC		;RL-Hardware aktivieren.

			lda	r0L
			sta	$de02
			lda	r0H
			sta	$de03

			lda	r1L
			sta	$de04
			lda	r1H
			clc
			adc	RamBankFirst +0
			sta	$de05
			lda	r3L
			adc	RamBankFirst +1
			sta	$de06

			lda	r2L
			sta	$de07
			lda	r2H
			sta	$de08

			lda	#$00
			sta	    $de09
			sta	    $de0a

			lda	#$91
			sta	    $de01

			jsr	EXEC_REC_REU		;Job ausführen und
			jsr	RL_HW_DIS2		;RL-Hardware abschalten.

			pla
			sta	CPU_DATA

			ldy	#%01000000
			plp
			rts

;******************************************************************************
;*** Zusatzroutinen.
;******************************************************************************
			t "-R3_DetectRLNK"
;******************************************************************************
