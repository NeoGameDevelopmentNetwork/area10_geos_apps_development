; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; ULIB: Auf C=REU/CMD-REU testen
;
;Übergabe : -
;Rückgabe : X = Fehlerstatus, $00 = C=REU vorhanden
;             = $0D, Keine C=REU
;Verändert: A,X,Y

:ULIB_TEST_CREU

			ldx	#2			;Sektor-Adressen in Steuerregister
::1			txa				;speichern.
			sta	$df00,x
			inx
			cpx	#6
			bcc	:1

			ldx	#2			;Steuerregister auslesen und Werte
::2			txa				;überprüfen.
			cmp	$df00,x			;Werte gültig ?
			bne	:no_creu		; => Nein, keine CREU...
			inx
			cpx	#6
			bcc	:2

			ldx	#NO_ERROR
			b $2c
::no_creu		ldx	#DEV_NOT_FOUND

			rts
