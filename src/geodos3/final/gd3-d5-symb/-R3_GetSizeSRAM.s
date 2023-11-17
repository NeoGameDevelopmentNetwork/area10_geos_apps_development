; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Definieren der RAMCard-Register.
;SRAM_FIRST_PAGE	= $d27c				;In ":SymbTab_1" definiert.
;SRAM_FIRST_BANK	= $d27d
;SRAM_LAST_PAGE		= $d27e
;SRAM_LAST_BANK		= $d27f

:SRAM_BSIZE_64K		= 64

;*** Systemvariablen.
:SRAM_SIZE_KB		w $0000
:SRAM_BANK_COUNT	b $00
:SRAM_FREE_START	b $00
:SRAM_FREE_END		b $00

;*** Standardwerte setzen und RAMCard-Erkennung.
:SRAM_GET_SIZE		jsr	SRAM_GET_BCOUNT

;*** RAMCard-Erkennung abgeschlossen.
:ExitSRamTest		lda	SRAM_BANK_COUNT		;Speicher verfügbar?
			beq	:1			; => Nein, Ende...

;*** RAMCard-Größe berechnen.
			sta	r0L			;Anzahl der Speicherbänke zur
			lda	#$00			;Berechnung der GEOS/MP3 64Kb
			sta	r0H			;Speicherbänke in r0 ablegen.

			lda	#SRAM_BSIZE_64K		;Größe der Speicherbänke
			sta	r1L			;in r1L ablegen.

			ldx	#r0L			;BMult für WORD*BYTE aufrufen.
			ldy	#r1L
			jsr	BMult
			MoveW	r0,SRAM_SIZE_KB		;Größe der RAMCard speichern.

			ldx	#NO_ERROR
			b $2c
::1			ldx	#DEV_NOT_FOUND		;RAMCard nicht erkannt.
			rts

;*** Größe des SuperCPU-RAMCard-Speichers ermitteln.
:SRAM_GET_BCOUNT	php				;IRQ sperren.
			sei

			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#IO_IN
			sta	CPU_DATA

			jsr	sysGetBCntSRAM		;Erkennungsroutine starten.

			pla
			sta	CPU_DATA		;I/O-Bereich ausblenden.

			plp				;IRQ-Status zurücksetzen.

			stx	SRAM_FREE_START
			tya
			sta	SRAM_BANK_COUNT
			beq	:12
			ldx	#NO_ERROR
			b $2c
::12			ldx	#DEV_NOT_FOUND
			rts

;*** SRAM Bankanzahl testen, keine Änderung von MMU, CLKRATE und RAM_Reg_Buf.
:sysGetBCntSRAM		ldx	SRAM_FIRST_BANK		;Erste freie Bank einlesen.
			lda	SRAM_FIRST_PAGE		;Beginnt Bank bei Page #0?
			beq	:11			; => Ja, weiter...
			inx				;Nein, Bank überspringen.
::11			stx	SRAM_FREE_START		;Freier Speicher Startadresse.
			lda	SRAM_LAST_BANK		;Letzte freie Bank.
			sta	SRAM_FREE_END
			sec				;Anzahl freie 64K-Speicherbänke
			sbc	SRAM_FREE_START		;berechnen.
			sta	SRAM_BANK_COUNT
			tay
			rts
