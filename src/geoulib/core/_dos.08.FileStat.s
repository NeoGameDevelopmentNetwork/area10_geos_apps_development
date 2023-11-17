; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: $08 DOS_CMD_FILE_STAT
;
;Datei-Informationen abfragen.
;
;--- Hinweis:
;In der Firmware V3.6a ist die Angabe
;eines Verzeichnisses erforderlich!
;
;Auf Grund eines Fehlers im UCI der
;Firmware V3.6a bis mind. V3.10f kann
;nach verschiedenen Befehlen (z.B.
;RENAME mit anderem Ziel-Verzeichnis,
;WRITE_DATA oder COPY_FILE mit anderem
;Ziel-Verzeichnis) FILE_STAT nicht
;mehr verwendet werden.
;Ergebnis -> "82,FILE NOT FOUND".
;
;Alternative:
;OPEN_FILE, FILE_INFO und CLOSE_FILE
;verwenden (nur bei Dateien möglich!)
;
;Übergabe : r6 = Zeiger auf Dateiname
;Rückgabe : X  = Fehlerstatus, $00=OK
;                UCI_STATUS_MSG = Status-Meldung
;                UCI_DATA_MSG   = Datei-Informationen:
;Format   :      00:DWORD  Dateigröße in Bytes
;                04:WORD   Datum
;                06:WORD   Uhrzeit
;                08:CHAR   Extension (3 Bytes)
;                          Keine .ext: $00,$00,$00
;                11:BYTE   Attribut
;                12:CHAR   Dateiname (63 Bytes)
;                   BYTE   NULL
;Verändert: A,X,Y,r4,r5

:_UCID_FILE_STAT

			lda	UCI_TARGET		;Befehl an UCI senden.
			sta	UCI_COMDATA
			lda	#DOS_CMD_FILE_STAT
			sta	UCI_COMDATA

			jsr	ULIB_PUSH_NAME6		;Dateiname an UCI senden.

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
