; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: $05 DOS_CMD_WRITE_DATA
;
;Daten in geöffnete Datei schreiben.
;Paketgröße 256 Bytes.
;
;--- Hinweis:
;Das senden von mehr als 508 Bytes
;erzeugt mind. ab Firmware v3.6a bis
;v3.10f fehlerhafte Dateien.
;Abhilfe: max. 508 Bytes senden. Das
;senden von 256 Bytes vereinfacht die
;Routine allerdings deutlich.
;
;Übergabe : r0 = Anzahl Bytes (max. 65.535 Bytes)
;           r4 = Zeiger auf Datenpuffer
;Rückgabe : r4 = Zeiger hinter das zuletzt gesendete Byte
;           X  = Fehlerstatus, $00=OK
;                UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r0,r1L,r5

:_UCID_WRITE_DATA

			ldx	#UCI_NO_DATA		;Fehler: Keine Daten.
			lda	r0L
			ora	r0H			;Daten vorhanden?
			beq	:err			; => Nein, Abbruch...

			lda	#NULL			;$00 = Status 1x abfragen.
			sta	r1L

;--- Neues Datenpaket vorbereiten.
::next			lda	UCI_TARGET		;Befehl an UCI senden.
			sta	UCI_COMDATA
			lda	#DOS_CMD_WRITE_DATA
			sta	UCI_COMDATA

			lda	#NULL			;Zwei Dummy-Bytes.
			sta	UCI_COMDATA
			sta	UCI_COMDATA

;--- Daten für Datenpaket übergeben.
			ldy	#0
::loop			lda	(r4),y
			sta	UCI_COMDATA		;Byte an UCI übergeben.

			lda	r0L			;Byte-Zähler korrigieren.
			bne	:1
			dec	r0H
::1			dec	r0L

			lda	r0L
			ora	r0H			;Alle Byte geschrieben?
			beq	:push			; => Ja, Übertragung starten.

			iny				;256 Byte geschrieben?
			bne	:loop			; => Nein, weiter...

::push			jsr	ULIB_PUSH_CMD		;Befehl ausführen.
			txa				;Timeout?
			bne	:err			; => Ja, Abbruch...

			bit	r1L			;Status nur 1x abfragen um einen
			bmi	:2			;"ACCESS DENIED"-Fehler abzufangen.

			jsr	ULIB_GET_STATUS		;Status einlesen.

::2			jsr	ULIB_ACCEPT_DATA	;Datensatz akzeptieren.
			txa				;Timeout?
			bne	:err			; => Ja, Abbruch...

			bit	r1L			;Status nur 1x abfragen um einen
			bmi	:3			;"ACCESS DENIED"-Fehler abzufangen.
			dec	r1L

			jsr	ULIB_TEST_ERR		;Fehlerstatus auswerten.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

::3			lda	r0L
			ora	r0H			;Alle Byte gesendet?
			bne	:next			; => Nein, weiter...

;			ldx	#NO_ERROR
::err			rts
