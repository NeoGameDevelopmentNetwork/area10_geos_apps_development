﻿; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: $12 DOS_CMD_GET_PATH
;
;Aktuelles Verzeichnis abfragen.
;
;Übergabe : -
;Rückgabe : X = Fehlerstatus, $00=OK
;               UCI_STATUS_MSG = Status-Meldung
;               UCI_DATA_MSG   = Verzeichnispfad
;Verändert: A,X,Y,r4,r5

:_UCID_GET_PATH

			lda	UCI_TARGET		;Befehl an UCI senden.
			sta	UCI_COMDATA
			lda	#DOS_CMD_GET_PATH
			sta	UCI_COMDATA

			jsr	ULIB_PUSH_CMD		;Befehl ausführen.
			txa				;Timeout?
			bne	:err			; => Ja, Abbruch...

			jsr	ULIB_GET_STRING		;Daten einlesen, Ende = NULL-Byte.
			jsr	ULIB_GET_STATUS		;Status einlesen.
			jsr	ULIB_ACCEPT_DATA	;Datenempfang bestätigen.
			txa				;Timeout?
			bne	:err			; => Ja, Abbruch...

			jsr	ULIB_TEST_ERR		;Fehlerstatus auswerten.

::err			rts