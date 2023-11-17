; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: $13 DOS_CMD_OPEN_DIR
;
;Verzeichnis zum lesen öffnen.
;
;Übergabe : -
;Rückgabe : X = Fehlerstatus, $00=OK
;               UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r5

:_UCID_OPEN_DIR

			lda	UCI_TARGET		;Befehl an UCI senden.
			sta	UCI_COMDATA
			lda	#DOS_CMD_OPEN_DIR
			sta	UCI_COMDATA

			jsr	ULIB_PUSH_CMD		;Befehl ausführen.
			txa				;Timeout?
			bne	:err			; => Ja, Abbruch...

;			jsr	ULIB_GET_DATA		;Keine Daten...
			jsr	ULIB_GET_STATUS		;Status einlesen.
			jsr	ULIB_ACCEPT_DATA	;Datenempfang bestätigen.
			txa				;Timeout?
			bne	:err			; => Ja, Abbruch...

			jsr	ULIB_TEST_ERR		;Fehlerstatus auswerten.

::err			rts
