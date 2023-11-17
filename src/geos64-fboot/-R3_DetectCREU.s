; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Auf C=REU/CMD-REU testen.
;    Rückgabe:		xReg = $00, Laufwerk kann installiert werden.
:DetectCREU		php				;IRQ sperren.
			sei

			lda	CPU_DATA		;I/O-Bereich und ROM aktivieren.
			pha
			lda	#IO_IN
			sta	CPU_DATA

			jsr	:sysDetectCREU		;Erkennungsroutine starten.

			pla
			sta	CPU_DATA		;I/O-Bereich und ROM ausblenden.

			plp
			rts

;*** Auf C=REU testen, keine Änderung von CPU_DATA.
;--- Hinweis: 04.02.21/M.Kanet
;Eigenständige ":sysDetect"-Routine war
;nur unter MegaPatch128 notwendig.
::sysDetectCREU		ldx	#$02			;Sektor-Adressen in Steuerregister
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
