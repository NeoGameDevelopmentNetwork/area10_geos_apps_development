; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Einsprungtabelle RAM-Tools/RAMLink.
:xVerifyRAM		ldy	#jobVerify		;RAM-Bereich vergleichen.
			b $2c
:xStashRAM		ldy	#jobStash		;RAM-Bereich speichern.
			b $2c
:xSwapRAM		ldy	#jobSwap		;RAM-Bereich tauschen.
			b $2c
:xFetchRAM		ldy	#jobFetch		;RAM-Bereich laden.

:xDoRAMOp		php				;IRQ sperren.
			sei

			lda	CPU_DATA		;Kernal+I/O einblenden.
			pha
			lda	#KRNL_IO_IN
			sta	CPU_DATA

			jsr	EN_SET_REC		;RL-Hardware einschalten.

			sty	EXP_BASE2    + 1

			ldx	#$01
::51			lda	r0L,x			;Computer Address Pointer.
			sta	EXP_BASE2    + 2,x
			lda	r2L,x			;Transfer Length.
			sta	EXP_BASE2    + 7,x
			dex
			bpl	:51

			inx
			stx	EXP_BASE2    +10	;Address Control.

::52			lda	r1L			;RAMLink System Address Pointer.
			sta	EXP_BASE2    + 4
			lda	r1H
			clc
			adc	RamBankFirst + 0
			sta	EXP_BASE2    + 5
			lda	r3L
			adc	RamBankFirst + 1
			sta	EXP_BASE2    + 6

			jsr	EXEC_REC_REU		;Job ausführen.

			lda	EXP_BASE2    + 0	;Job-Ergebnis in AKKU übergeben.
			pha

			jsr	RL_HW_DIS2		;RL-Hardware abschalten.

			pla
			tay				;AKKU-Register speichern.

			pla
			sta	CPU_DATA		;Kernal+I/O ausblenden.

			plp				;IRQ-Status zurücksetzen.

			tya				;Ergebnis in AKKU übergeben.
			ldx	#$00			;Flag für "Kein Fehler".
			rts
