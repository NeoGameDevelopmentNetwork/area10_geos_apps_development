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
;Paketgröße 512 Bytes, siehe hierzu
;"Ultimate DOS Command summary 1.2":
; "The suggested transfer size is
;  512 bytes ata time. This will give
;  the optimal performance, while
;  keeping into consideration the
;  maximum command transfer size."
;"Ultimate-II Command Interface 1.0":
; "The size of the queues are
;  important to note, since they
;  define the maximum transfer size
;  per command. The command queue
;  size is 896 bytes, the response
;  data queue is also 896 bytes and
;  the status queue is 256 bytes"
;
;--- Hinweis:
;Das senden von mehr als 508 Bytes
;erzeugt mind. ab Firmware v3.6a bis
;v3.10f fehlerhafte Dateien.
;Abhilfe: max. 508 Bytes senden.
;
;Übergabe : r0 = Anzahl Bytes (max. 65.535 Bytes)
;           r4 = Zeiger auf Datenpuffer
;Rückgabe : r4 = Zeiger hinter das zuletzt gesendete Byte
;           X  = Fehlerstatus, $00=OK
;                UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r0,r1L,r2,r4,r5

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

			lda	#< 512
			sta	r2L
			lda	#> 512
			sta	r2H

;--- Daten für Datenpaket übergeben.
			ldy	#0
::loop			lda	(r4),y
			sta	UCI_COMDATA		;Byte an UCI übergeben.

			inc	r4L			;Zeiger auf Daten korrigieren.
			bne	:1
			inc	r4H

::1			ldx	#r0L			;Byte-Zähler korrigieren.
			jsr	:dec_word		;Alle Byte geschrieben?
			beq	:push			; => Ja, Übertragung starten.

			ldx	#r2L			;Zähler für Datenpaket korrigieren.
			jsr	:dec_word		;Datenpaket geschrieben?
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

::3			ldx	#r0L
			jsr	:is_zero		;Alle Bytes gesendet?
			bne	:next			; => Nein, weiter...

;			ldx	#NO_ERROR
::err			rts

;--- 16-Bit-Word -1 / Auf $0000 testen.
::dec_word		lda	ZPAGE +0,x
			bne	:lb
			dec	ZPAGE +1,x
::lb			dec	ZPAGE +0,x

::is_zero		lda	ZPAGE +0,x
			ora	ZPAGE +1,x
			rts
