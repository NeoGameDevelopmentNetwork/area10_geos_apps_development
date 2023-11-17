; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: $10 NET_CMD_READ_SOCKET
;
;Daten über Netzwerk einlesen.
;
;--- Hinweis:
;Wird READ_SOCKET zu schnell nach einem
;WRITE_SOCKET-Befehl gesendet, dann
;stehen die Daten evtl. nocht nicht zur
;Verfügung -> "02,NO DATA :11".
;
;Übergabe : r0  = Anzahl Bytes (max. 65.535 Bytes)
;           r4  = Zeiger auf Anfang Datenpuffer
;           r7L = Socket TCP/UDP
;Rückgabe : r4  = Zeiger hinter das zuletzt gelesene Byte
;           r7H = Retry-Zähler, $00=Timeout aufgetreten
;           X   = Fehlerstatus, $00=OK
;                 UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r4,r5,r7H

:_UCIN_READ_SOCKET

			lda	#NET_RETRY		;Retry-Zähler initialisieren.
			sta	r7H

::wait			lda	#UCI_TARGET_NET		;Befehl an UCI senden.
			sta	UCI_COMDATA
			lda	#NET_CMD_READ_SOCKET
			sta	UCI_COMDATA

			lda	r7L			;Socket TCP/UDP einlesen.
			sta	UCI_COMDATA

			lda	r0L			;Anzahl Datenbytes.
			sta	UCI_COMDATA
			lda	r0H
			sta	UCI_COMDATA

			jsr	ULIB_PUSH_CMD		;Befehl ausführen.
			txa				;Timeout?
			bne	:err			; => Ja, Abbruch...

			jsr	ULIB_GET_DATA		;Daten einlesen.
			jsr	ULIB_GET_STATUS		;Status einlesen.
			jsr	ULIB_ACCEPT_DATA	;Datenempfang bestätigen.
			txa				;Timeout?
			bne	:err			; => Ja, Abbruch...

			jsr	ULIB_TEST_ERR		;Fehlerstatus auswerten.
			cpx	#$02			;Fehler "02:NO DATA: 11"?
			bne	:err			; => Nein, Ende...

			lda	cia1tod_t		;1/10 Sekunde Pause für
::delay			cmp	cia1tod_t		;C128/2MHz und Ultimate64/48MHz.
			beq	:delay

			dec	r7H			;Retry-Zähler abgelaufen?
			bne	:wait			; => Nein, nochmal versuchen...

::err			rts
