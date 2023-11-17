; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: $04 DOS_CMD_READ_DATA
;
;Daten aus geöffneter Datei einlesen.
;
;Übergabe : r0 = Anzahl Bytes (max. 65.535 Bytes)
;           r4 = Zeiger auf Anfang Datenpuffer
;Rückgabe : r4 = Zeiger hinter das zuletzt gelesene Byte
;           r6 = Zeiger auf Anfang Datenpuffer
;                (Darf nicht verändert werden!)
;           X  = Fehlerstatus, $00=OK
;                UCI_STATUS_MSG = Status-Meldung
;           Y  = Status-Bits (IDLE/BUSY/DATALAST/DATAMORE)
;Verändert: A,X,Y,r6

:_UCID_READ_DATA

			lda	r4L
			sta	r6L
			lda	r4H
			sta	r6H

			lda	UCI_TARGET		;Befehl an UCI senden.
			sta	UCI_COMDATA
			lda	#DOS_CMD_READ_DATA
			sta	UCI_COMDATA

			lda	r0L			;Anzahl Datenbytes.
			sta	UCI_COMDATA
			lda	r0H
			sta	UCI_COMDATA

			jsr	ULIB_PUSH_CMD		;Befehl ausführen.
			txa				;Timeout?
			bne	:err			; => Ja, Abbruch...

			tya
			and	#CMD_STATE_BITS		;Daten vorhanden?
			beq	:no_data		; => Nein, Ende...

::err			rts

::no_data		ldx	#UCI_NO_DATA		;Fehler: keine Daten...
			rts

;
;Nächsten Datensatz einlesen.
;
;Übergabe : r0 = Anzahl Bytes (max. 65.535 Bytes)
;           r6 = Zeiger auf Datenpuffer
;                (Durch _UCI_READ_DATA gesetzt)
;Rückgabe : r4 = Zeiger hinter das zuletzt gelesene Byte
;           r6 = Zeiger auf Anfang Datenpuffer
;                (Darf nicht verändert werden!)
;           X  = Fehlerstatus, $00=OK
;                UCI_STATUS_MSG = Status-Meldung
;           Y  = Status-Bits (IDLE/BUSY/DATALAST/DATAMORE)
;Verändert: A,X,Y,r4,r5

:_UCID_READ_NEXT

			lda	r6L			;Zeiger auf Datenpuffer
			sta	r4L			;zurücksetzen.
			lda	r6H
			sta	r4H

;
;Nächsten Datensatz nach r4 einlesen.
;
;Übergabe : r0 = Anzahl Bytes (max. 65.535 Bytes)
;           r4 = Zeiger auf Datenpuffer
;Rückgabe : r4 = Zeiger hinter das zuletzt gelesene Byte
;           r6 = Zeiger auf Anfang Datenpuffer
;                (Darf nicht verändert werden!)
;           X  = Fehlerstatus, $00=OK
;                UCI_STATUS_MSG = Status-Meldung
;           Y  = Status-Bits (IDLE/BUSY/DATALAST/DATAMORE)
;Verändert: A,X,Y,r5

:_UCID_READ_CONT

;--- Daten einlesen.
;Status muss nicht abgefragt werden,
;das Ende einer Datei wird über DATA
;mitgeteilt. DATA_LAST zeigt an das
;noch ein letztes Datenpaket folgt.
			jsr	ULIB_GET_NEXT		;Daten einlesen.
;			jsr	ULIB_GET_STATUS		;Status einlesen.
			jsr	ULIB_ACCEPT_DATA	;Datensatz akzeptieren.
;			txa				;Timeout?
;			bne	:err			; => Ja, Abbruch...

;			jsr	ULIB_TEST_ERR		;Fehlerstatus auswerten.
;			txa				;Timeout?
;			bne	:err			; => Ja, Abbruch...

::err			rts
