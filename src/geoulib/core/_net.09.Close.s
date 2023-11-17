; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: $09 NET_CMD_CLOSE_SOCKET
;
;Verbindung beenden.
;
;Übergabe : r7L = Socket-Nr. (0 bis 255)
;Rückgabe : X = Fehlerstatus, $00=OK
;               UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r5

:_UCIN_CLOSE_SOCKET

			lda	#UCI_TARGET_NET		;Befehl an UCI senden.
			sta	UCI_COMDATA
			lda	#NET_CMD_CLOSE_SOCKET
			sta	UCI_COMDATA

			lda	r7L			;Socket-Nummer an UCI senden.
			sta	UCI_COMDATA

			jsr	ULIB_PUSH_CMD		;Befehl ausführen.
			txa				;Timeout?
			bne	:err			; => Ja, Abbruch...

;			jsr	ULIB_GET_DATA		;Keine Daten...

;--- Hinweis:
;Wenn keinen Status vorhanden, dann
;Status von CLOSE_SOCKET einlesen.
			lda	UCI_STATUS_MSG		;Status vorhanden?
			beq	:get_status		; => Nein, weiter...

			jsr	ULIB_TEST_ERR		;Fehlerstatus auswerten.
			txa				;Bereits Fehler vorhanden?
			bne	:1			; => Ja, Status übergehen...
;---
::get_status		jsr	ULIB_GET_STATUS		;Status einlesen.

::1			jsr	ULIB_ACCEPT_DATA	;Datenempfang bestätigen.
			txa				;Timeout?
			bne	:err			; => Ja, Abbruch...

			jsr	ULIB_TEST_ERR		;Fehlerstatus auswerten.

::err			rts
