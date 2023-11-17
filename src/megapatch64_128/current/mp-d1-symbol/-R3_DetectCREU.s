; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Auf C=REU/CMD-REU testen.
;Rückgabe: xReg = $00, Laufwerk kann installiert werden.
:DetectCREU		php				;IRQ sperren.
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

			jsr	sysDetectCREU		;Erkennungsroutine starten.

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

;*** Auf C=REU testen, keine Änderung von MMU, CLKRATE und RAM_Reg_Buf.
:sysDetectCREU		ldx	#$02			;Sektor-Adressen in Steuerregister
::51			txa				;speichern.
			sta	$df00,x
			inx
			cpx	#$06
			bcc	:51

			ldx	#$02			;Steuerregister auslesen und Werte
::52			txa				;überprüfen.
			cmp	$df00,x
			bne	:53			;Steuerregister fehlerhaft, Ende...
			inx
			cpx	#$06
			bcc	:52

			ldx	#NO_ERROR
			b $2c
::53			ldx	#DEV_NOT_FOUND
			rts
