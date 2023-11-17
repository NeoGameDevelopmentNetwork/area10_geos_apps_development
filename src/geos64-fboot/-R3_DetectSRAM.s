; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Auf SuperCPU/RAMCard testen.
;    Rückgabe:		xReg = $00, Laufwerk kann installiert werden.
:DetectSCPU		php				;IRQ sperren.
			sei

			lda	CPU_DATA		;I/O-Bereich und ROM aktivieren.
			pha
			lda	#KRNL_IO_IN
			sta	CPU_DATA

			jsr	:sysDetectSCPU		;Erkennungsroutine starten.

			pla
			sta	CPU_DATA		;I/O-Bereich und ROM ausblenden.

			plp
			rts

;*** Auf RAMCard testen, keine Änderung von CPU_DATA.
;--- Hinweis: 04.02.21/M.Kanet
;Eigenständige ":sysDetect"-Routine war
;nur unter MegaPatch128 notwendig.
::sysDetectSCPU		lda	SCPU_HW_CHECK
			cmp	#$ff			;SuperCPU verügbar ?
			beq	:53			; => Nein, Ende...

			lda	SCPU_ROM_VER +1		;CPU-ROM testen.
			cmp	#"."			;RAMCard erst ab ROM V1.40
			bne	:53			;verfügbar. Ältere Versionen der
			lda	SCPU_ROM_VER +0		;SCPU unterstützen keine RAMCard!
			cmp	#"1"
			bcc	:53
			beq	:51
			bcs	:52
::51			lda	SCPU_ROM_VER +2
			cmp	#"4"
			bcc	:53

::52			ldx	#NO_ERROR
			b $2c
::53			ldx	#DEV_NOT_FOUND
			rts
