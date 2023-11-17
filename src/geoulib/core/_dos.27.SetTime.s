; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: $27 DOS_CMD_SET_TIME
;
;Ultimate-Uhrzeit setzen.
;
;Übergabe: r4 = Zeiger auf Datum/Uhrzeit
;               Format (6 Bytes):
;               YY,MM,DD,hh,mm,ss
;               YY = JAHR - 1900 (0-255)
;Rückgabe: X = Fehlerstatus, $00=OK
;              UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r5

:_UCID_SET_TIME

			lda	UCI_TARGET		;Befehl an UCI senden.
			sta	UCI_COMDATA
			lda	#DOS_CMD_SET_TIME
			sta	UCI_COMDATA

			ldy	#0
::1			lda	(r4L),y			;Datum/Uhrzeit einlesen.
			sta	UCI_COMDATA		;Byte an UCI übergeben.
			iny
			cpy	#6			;Daten gesendet?
			bcc	:1			; => Nein, weiter...

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
