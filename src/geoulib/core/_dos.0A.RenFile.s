; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: $0A DOS_CMD_RENAME_FILE
;
;Datei umbenennen und/oder verschieben.
;
;Wird kein Verzeichnispfad angegeben,
;dann gilt das aktuelle Verzeichnis.
;
;Ist der Verzeichnispfad zwischen den
;beiden Dateinamen unterschiedlich,
;dann wird die Datei zwischen beiden
;Verzeichnissen verschoben.
;In dem Fall können beide Dateinamen
;auch identisch sein.
;
;Übergabe : r6 = Zeiger auf alten Dateinamen
;           r8 = Zeiger auf neuen Dateinamen
;Rückgabe : X = Fehlerstatus, $00=OK
;               UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r5

:_UCID_RENAME_FILE

			lda	UCI_TARGET		;Befehl an UCI senden.
			sta	UCI_COMDATA
			lda	#DOS_CMD_RENAME_FILE
			sta	UCI_COMDATA

			jsr	ULIB_PUSH_NAME6		;Alten Dateinamen an UCI senden.

			lda	#NULL			;Trennbyte senden...
			sta	UCI_COMDATA

			jsr	ULIB_PUSH_NAME8		;Neuen Dateinamen an UCI senden.

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
