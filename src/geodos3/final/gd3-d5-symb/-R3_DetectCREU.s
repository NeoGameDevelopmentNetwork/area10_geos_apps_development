; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Auf C=REU/CMD-REU testen.
;Rückgabe: xReg = $00, Laufwerk kann installiert werden.
;               = $0D, Keine C=REU.
:DetectCREU		php				;IRQ sperren.
			sei

			lda	CPU_DATA		;I/O-Bereich und ROM aktivieren.
			pha
			lda	#IO_IN
			sta	CPU_DATA

			ldx	#$02			;Sektor-Adressen in Steuerregister
::51			txa				;speichern.
			sta	$df00,x
			inx
			cpx	#$06
			bcc	:51

			ldx	#$02			;Steuerregister auslesen und Werte
::52			txa				;überprüfen.
			cmp	$df00,x			;Werte gültig ?
			bne	:no_creu		; => Nein, keine CREU...
			inx
			cpx	#$06
			bcc	:52

			ldx	#NO_ERROR
			b $2c
::no_creu		ldx	#DEV_NOT_FOUND

			pla
			sta	CPU_DATA		;I/O-Bereich und ROM ausblenden.

			plp
			rts
