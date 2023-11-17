; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: $06 CTRL_CMD_REBOOT
;
;Startet das Ultimate neu.
;
;Übergabe : -
;Rückgabe : X = Fehlerstatus, $00=OK
;Verändert: A,X,Y

:_UCIC_REBOOT

			lda	#UCI_TARGET_CTRL	;Befehl an UCI senden.
			sta	UCI_COMDATA
			lda	#CTRL_CMD_REBOOT
			sta	UCI_COMDATA

			jsr	ULIB_PUSH_CMD		;Befehl ausführen.
;			txa				;Timeout?
;			bne	:err			; => Ja, Abbruch...

;--- CMD_REBOOT liefert keine Daten/Status zurück.
;Siehe firmware/control_target.cc
;			jsr	ULIB_GET_DATA		;Keine Daten...
;			jsr	ULIB_GET_STATUS		;Kein Status...

;--- Keine Rückkehr zum Programm.
;			jsr	ULIB_ACCEPT_DATA	;Datenempfang bestätigen.
;			txa				;Timeout?
;			bne	:err			; => Ja, Abbruch...
;
;			jsr	ULIB_TEST_ERR		;Fehlerstatus auswerten.

::err			rts
