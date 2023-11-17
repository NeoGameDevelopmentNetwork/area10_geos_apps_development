; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: $0B DOS_CMD_COPY_FILE
;
;Datei kopieren.
;
;Quelle muss ein Dateiname im aktuellen
;Verzeichnis sein.
;Ziel muss ein anderes Verzeichnis ohne
;Angabe eines Dateinamen sein!
;
;Übergabe : r6 = Zeiger auf Dateiname Quelle
;                Beisiel: test.d64        (Ohne Pfad!)
;           r8 = Zeiger auf Ziel-Verzeichnis
;                Beispiel: /Usb0/testdir  (Ohne Dateiname!)
;Rückgabe : X = Fehlerstatus, $00=OK
;               UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r5

:_UCID_COPY_FILE

			lda	UCI_TARGET		;Befehl an UCI senden.
			sta	UCI_COMDATA
			lda	#DOS_CMD_COPY_FILE
			sta	UCI_COMDATA

			jsr	ULIB_PUSH_NAME6		;Dateiname Quelle an UCI senden.

			lda	#NULL			;Trennbyte senden...
			sta	UCI_COMDATA

			jsr	ULIB_PUSH_NAME8		;Dateiname Ziel an UCI senden.

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
