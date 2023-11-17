; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Auf SuperCPU/RAMCard testen.
;Rückgabe: xReg = $00, Laufwerk kann installiert werden.
;               = $0D, Keine SuperCPU.
;               = $60, Keine RAMCard.
:DetectSCPU		php				;IRQ sperren.
			sei

			lda	CPU_DATA		;I/O-Bereich und ROM aktivieren.
			pha
			lda	#KRNL_IO_IN
			sta	CPU_DATA

			lda	SCPU_HW_CHECK
			cmp	#$ff			;SuperCPU verügbar ?
			beq	:no_scpu		; => Nein, Ende...

			lda	SCPU_ROM_VER +1		;CPU-ROM testen.
			cmp	#"."			;RAMCard erst ab ROM V1.40
			bne	:no_ram			;verfügbar. Ältere Versionen der
			lda	SCPU_ROM_VER +0		;SCPU unterstützen keine RAMCard!
			cmp	#"1"
			bcc	:no_ram
			beq	:51
			bcs	:ok
::51			lda	SCPU_ROM_VER +2
			cmp	#"4"
			bcc	:no_ram

::ok			ldx	#NO_ERROR
			b $2c
::no_ram		ldx	#NO_FREE_RAM
			b $2c
::no_scpu		ldx	#DEV_NOT_FOUND

			pla
			sta	CPU_DATA		;I/O-Bereich und ROM ausblenden.

			plp
			rts
