﻿; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** GEOS an Speichererweiterung anpassen.
:InitDeviceRAM		php
			sei				;Interrupt sperren.

			lda	CPU_DATA
			pha
			lda	#IO_IN			;I/O-Bereich einblenden.
			sta	CPU_DATA

			jsr	InstallRamDrv		;RAM-Treiber installieren.

			pla
			sta	CPU_DATA		;I/O-Bereich zurücksetzen.

			plp				;Interrupt-Status zurücksetzen.
			rts

;*** RAM-Treiber installieren.
:InstallRamDrv		lda	ExtRAM_Type

;--- SuperCPU
			cmp	#RAM_SCPU		;SuperCPU/RAMCard ?
			bne	:51			; => Nein, weiter...

			sta	SCPU_HW_EN		;SuperCPU-Register aktivieren.

			ldy	#Code9L -1		;RAMCard-16Bit-Routinen für
::50			lda	Code9a,y		;DoRAMOp in SuperCPU-Userspeicher
			sta	SRAM_USER_PAGE,y	;kopieren.
			dey
			cpy	#$ff
			bne	:50

			sta	SCPU_HW_DIS		;SuperCPU-Register abschalten.

;--- Hinweis:
;Erste Bank in RAMCard in RAM-Treiber
;übernehmen, da RamBankFirst bei einem
;ExitGEOS und BootGEOS/SYS49152 evtl.
;überschrieben werden kann.
			lda	RamBankFirst +1
			sta	Code10a + (DvRAM_SCPU_HByt - BASE_RAM_DRV) +1

			ldy	#Code10L -1		;DoRAMOp-Funktionen für SuperCPU.
::50a			lda	Code10a,y
			sta	BASE_RAM_DRV,y
			dey
			cpy	#$ff
			bne	:50a
			ldx	#NO_ERROR
			rts

;--- RAMLink.
::51			cmp	#RAM_RL			;RAMLink ?
			bne	:52			; => Nein, weiter...

;--- Hinweis:
;Erste Bank in RAMCard in RAM-Treiber
;übernehmen, da RamBankFirst bei einem
;ExitGEOS und BootGEOS/SYS49152 evtl.
;überschrieben werden kann.
			lda	RamBankFirst +0
			sta	Code1a + (DvRAM_RLNK_LByt - BASE_RAM_DRV) +1
			lda	RamBankFirst +1
			sta	Code1a + (DvRAM_RLNK_HByt - BASE_RAM_DRV) +1

			ldy	#Code1L -1		;DoRAMOp-Funktionen für RAMLink.
::51a			lda	Code1a,y
			sta	BASE_RAM_DRV,y
			dey
			cpy	#$ff
			bne	:51a
			ldx	#NO_ERROR
			rts

;--- Commodore REU.
::52			cmp	#RAM_REU		;C=REU ?
			bne	:53			; => Nein, weiter...

			ldy	#Code2L -1		;DoRAMOp-Funktionen für C=REU.
::52a			lda	Code2a,y
			sta	BASE_RAM_DRV,y
			dey
			cpy	#$ff
			bne	:52a
			ldx	#NO_ERROR
			rts

;--- GEORAM/BBGRAM.
::53			cmp	#RAM_BBG		;BBGRAM ?
			bne	:54			; => Nein, weiter...

			lda	GRAM_BANK_SIZE
			sta	Code3a + (DvRAM_GRAM_BSIZE - DvRAM_GRAM_START) +1
			ldx	#%11111110		;Bankgröße 64Kb: Page #254, Bank #0.
			ldy	#%00000000
			cmp	#$40
			beq	:49
			ldx	#%01111110		;Bankgröße 32Kb: Page #126, Bank #1.
			ldy	#%00000001
			cmp	#$20
			beq	:49
			ldx	#%00111110		;Bankgröße 16Kb: Page  #62, Bank #3.
			ldy	#%00000011
::49			stx	Code3a + (DvRAM_GRAM_SYSP - DvRAM_GRAM_START) +1
			sty	Code3a + (DvRAM_GRAM_SYSB - DvRAM_GRAM_START) +1

			ldy	#Code3L -1		;DoRAMOp-Funktionen für GeoRAM.
::53a			lda	Code3a,y
			sta	BASE_RAM_DRV,y
			dey
			cpy	#$ff
			bne	:53a

			LoadW	r0,Code4a		;Routine für DoRAMOp-Funktionen
			LoadW	r1,$de00		;installieren.
			lda	Code3a + (DvRAM_GRAM_SYSB - DvRAM_GRAM_START) +1
			ldx	Code3a + (DvRAM_GRAM_SYSP - DvRAM_GRAM_START) +1
			ldy	#Code4L -1
			jsr	CopyData2BBG		;Daten in BBG kopieren.
			ldx	#NO_ERROR
			b $2c
::54			ldx	#DEV_NOT_FOUND		;Speichererweiterung unbekannt.
			rts

;*** Daten in REU kopieren.
:CopyData2BBG		sta	$dfff
			stx	$dffe
::51			lda	(r0L),y
			sta	(r1L),y
			dey
			cpy	#$ff
			bne	:51
			rts

;*** Größe der Speicherbänke in der GeoRAM 16/32/64Kb.
;--- Ergänzung: 11.09.18/M.Kanet:
;Dieser Variablenspeicher muss im Hauptprogramm an einer Stelle
;definiert werden der nicht durch das nachladen weiterer Programmteile
;überschrieben wird!
:GRAM_BANK_SIZE		b $00
