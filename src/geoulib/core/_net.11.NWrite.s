; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: $11 NET_CMD_SOCKET_WRITE
;
;Daten über Netzwerk senden.
;
;Übergabe : r0  = Anzahl Bytes (max. 65.535 Bytes)
;           r4  = Zeiger auf Datenpuffer
;           r7L = Socket TCP/UDP
;Rückgabe : r4  = Zeiger hinter das zuletzt gesendete Byte
;           X   = Fehlerstatus, $00=OK
;                 UCI_STATUS_MSG = Status-Meldung
;                 UCI_DATA_MSG   = Word, Anzahl gesendete Bytes
;Verändert: A,X,Y,r0,r4,r5

:_UCIN_WRITE_SOCKET

			ldx	#UCI_NO_DATA		;Fehler: Keine Daten.
			lda	r0L
			ora	r0H			;Daten vorhanden?
			beq	:err			; => Nein, Abbruch...

;--- Neues Datenpaket vorbereiten.
::next			lda	#UCI_TARGET_NET		;Befehl an UCI senden.
			sta	UCI_COMDATA
			lda	#NET_CMD_WRITE_SOCKET
			sta	UCI_COMDATA

			lda	r7L			;Socket TCP/UDP einlesen.
			sta	UCI_COMDATA

;--- Daten für Datenpaket übergeben.
			ldy	#0
::loop			lda	(r4),y
			sta	UCI_COMDATA		;Byte an UCI übergeben.

			inc	r4L			;Zeiger auf Daten korrigieren.
			bne	:1
			inc	r4H

::1			ldx	#r0L			;Byte-Zähler korrigieren.
			jsr	:dec_word		;Alle Byte geschrieben?
			bne	:loop			; => Ja, Übertragung starten.

			jsr	ULIB_PUSH_CMD		;Befehl ausführen.
			txa				;Timeout?
			bne	:err			; => Ja, Abbruch...

			jsr	ULIB_GET_DATA		;Daten einlesen.
			jsr	ULIB_GET_STATUS		;Status einlesen.
			jsr	ULIB_ACCEPT_DATA	;Datensatz akzeptieren.
			txa				;Timeout?
			bne	:err			; => Ja, Abbruch...

			jsr	ULIB_TEST_ERR		;Fehlerstatus auswerten.
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

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
