; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: $09 DOS_CMD_DELETE_FILE
;
;Datei-Informationen abfragen.
;
;Übergabe : r6 = Zeiger auf Dateiname
;Rückgabe : X  = Fehlerstatus, $00=OK
;                UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r5

:_UCID_DELETE_FILE

			lda	UCI_TARGET		;Befehl an UCI senden.
			sta	UCI_COMDATA
			lda	#DOS_CMD_DELETE_FILE
			sta	UCI_COMDATA

			jsr	ULIB_PUSH_NAME6		;Dateiname an UCI senden.

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
