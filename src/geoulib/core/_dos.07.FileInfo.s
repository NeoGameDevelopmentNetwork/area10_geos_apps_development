; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: $07 DOS_CMD_FILE_INFO
;
;Datei-Informationen abfragen.
;
;Übergabe : -
;Rückgabe : X = Fehlerstatus, $00=OK
;               UCI_STATUS_MSG = Status-Meldung
;               UCI_DATA_MSG   = Datei-Informationen:
;Format   :     00:DWORD  Dateigröße in Bytes
;               04:WORD   Datum
;               06:WORD   Uhrzeit
;               08:CHAR   Extension (3 Bytes)
;                         Keine .ext: $00,$00,$00
;               11:BYTE   Attribut
;               12:CHAR   Dateiname (63 Bytes)
;                  BYTE   NULL
;Verändert: A,X,Y,r4,r5

:_UCID_FILE_INFO

			lda	UCI_TARGET		;Befehl an UCI senden.
			sta	UCI_COMDATA
			lda	#DOS_CMD_FILE_INFO
			sta	UCI_COMDATA

			jsr	ULIB_PUSH_CMD		;Befehl ausführen.
			txa				;Timeout?
			bne	:err			; => Ja, Abbruch...

;--- Hinweis:
;Zum einlesen der Datei-Informationen
;wird ein NULL-Byte am Ende benötigt.
;			jsr	ULIB_GET_DATA		;Daten einlesen.
			jsr	ULIB_GET_STRING		;Daten einlesen, Ende = NULL-Byte.
			jsr	ULIB_GET_STATUS		;Status einlesen.
			jsr	ULIB_ACCEPT_DATA	;Datenempfang bestätigen.
			txa				;Timeout?
			bne	:err			; => Ja, Abbruch...

			jsr	ULIB_TEST_ERR		;Fehlerstatus auswerten.

::err			rts
