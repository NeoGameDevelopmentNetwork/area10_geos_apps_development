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
			lda	#KRNL_IO_IN		;I/O-Bereich und Kernal für
			sta	CPU_DATA		;RAMLink-Transfer aktivieren.

			jsr	EN_SET_REC		;RL-Hardware einschalten.

			sty	EXP_BASE2    + 1	;Command Register.

			ldx	#$01
::1			lda	r0L,x			;Computer Address Pointer.
			sta	EXP_BASE2    + 2,x
			lda	r1L,x			;RAMLink Address (low/middle byte)
			sta	EXP_BASE2    + 4,x
			lda	r2L,x			;Transfer Length.
			sta	EXP_BASE2    + 7,x
			dex
			bpl	:1

			lda	r3L			;RAMLink Address (high byte)
			sta	EXP_BASE2    + 6

;			ldx	#%11000000		;Both addresses fixed.
			inx
			stx	EXP_BASE2    +10	;Address Control.

			jsr	EXEC_REC_REU		;Job ausführen und
			jsr	RL_HW_DIS2		;RL-Hardware abschalten.

			pla
			sta	CPU_DATA		;CPU-Register zurücksetzen.

			plp				;IRQ-Status zurücksetzen.

			lda	#%01000000
			ldx	#NO_ERROR
			rts
