; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Ergänzung: 08.07.18/M.Kanet
;Adressen für Prüfung der SuperCPU-Version.
if Flag64_128 = TRUE_C64
:SCPU_VCODE1 = $e487
:SCPU_VCODE2 = $e488
:SCPU_VCODE3 = $e489
endif
if Flag64_128 = TRUE_C128
:SCPU_VCODE1 = $f6dd
:SCPU_VCODE2 = $f6de
:SCPU_VCODE3 = $f6df
endif

;*** Auf SuperCPU/RAMCard testen.
;    Rückgabe:		xReg = $00, Laufwerk kann installiert werden.
:DetectSCPU		php				;IRQ sperren.
			sei

if Flag64_128 = TRUE_C64
			lda	CPU_DATA		;I/O-Bereich und ROM aktivieren.
			pha
			lda	#$37
			sta	CPU_DATA
endif
if Flag64_128 = TRUE_C128
			lda	MMU			;I/O-Bereich und ROM aktivieren.
			pha
			lda	#$4e
			sta	MMU
endif

			jsr	sysDetectSCPU		;Erkennungsroutine starten.

if Flag64_128 = TRUE_C64
			pla
			sta	CPU_DATA		;I/O-Bereich und ROM ausblenden.
endif
if Flag64_128 = TRUE_C128
			pla
			sta	MMU			;I/O-Bereich und ROM ausblenden.
endif

			plp
			rts

;*** Auf RAMCard testen, keine Änderung von MMU, CLKRATE und RAM_Reg_Buf.
:sysDetectSCPU		lda	$d0bc
			cmp	#$ff			;SuperCPU verügbar ?
			beq	:53			; => Nein, Ende...

			lda	SCPU_VCODE2		;CPU-ROM testen.
			cmp	#"."			;RAMCard erst ab ROM V1.40
			bne	:53			;verfügbar. Ältere Versionen der
			lda	SCPU_VCODE1		;SCPU unterstützen keine RAMCard!
			cmp	#"1"
			bcc	:53
			beq	:51
			bcs	:52
::51			lda	SCPU_VCODE3
			cmp	#"4"
			bcc	:53

::52			ldx	#NO_ERROR
			b $2c
::53			ldx	#DEV_NOT_FOUND
			rts
