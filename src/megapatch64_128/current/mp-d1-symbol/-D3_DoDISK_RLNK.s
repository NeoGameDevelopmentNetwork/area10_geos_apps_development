; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Einsprungtabelle RAM-Funktionen.
;Übergabe: r0   = Startadresse C64-RAM.
;          r1   = Startadresse REU.
;          r2   = Anzahl Bytes.
;          r3L  = Speicherbank.
;          yReg = Job-Code.
;Rückgabe: -
;Geändert: AKKU,xReg,yReg
;
:DoRAMOp_DISK		php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			lda	CPU_DATA		;CPU Register einlesen und
			pha				;zwischenspeichern.
			lda	#$36			;I/O-Bereich und Kernal für
			sta	CPU_DATA		;RAMLink-Transfer aktivieren.

			tya
			pha
			jsr	EN_SET_REC		;RL-Hardware aktivieren.
			pla
			sta	EXP_BASE2 + 1		;Command Register.

			lda	r0L			;Computer Address.
			sta	EXP_BASE2 + 2
			lda	r0H
			sta	EXP_BASE2 + 3

			lda	r1L			;RAMLink Address (low/middle byte).
			sta	EXP_BASE2 + 4
			lda	r1H
			sta	EXP_BASE2 + 5
			lda	r3L
			sta	EXP_BASE2 + 6

			lda	r2L			;Transfer length.
			sta	EXP_BASE2 + 7
			lda	r2H
			sta	EXP_BASE2 + 8

;			ldy	#%11000000		;Both Addresses fixed.
			ldy	#$00			;Address Control.
			sty	EXP_BASE2 +10
;			iny				;Bank in 128 for transfer.
;			sta	EXP_BASE2 +16		;(Always GEOS-FrontRAM bank 1).

			jsr	EXEC_REC_REU		;Job ausführen und
			jsr	RL_HW_DIS2		;RL-Hardware abschalten.

			pla
			sta	CPU_DATA		;CPU-Register zurücksetzen.

			plp				;IRQ-Status zurücksetzen.

			lda	#%01000000
			ldx	#NO_ERROR
			rts
