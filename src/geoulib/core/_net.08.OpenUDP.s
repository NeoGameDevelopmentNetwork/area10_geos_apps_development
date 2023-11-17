; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: $08 NET_CMD_OPEN_UDP
;
;Verbindung über UDP öffnen.
;
;Übergabe : r6 = Hostname
;           r7 = UDP/Port-Nr. (0 bis 65535)
;Rückgabe : X = Fehlerstatus, $00=OK
;               UCI_STATUS_MSG = Status-Meldung
;               UCI_DATA_MSG   = UDP/Socket-Adresse
;Verändert: A,X,Y,r4,r5

:_UCIN_OPENUDP

			lda	#UCI_TARGET_NET		;Befehl an UCI senden.
			sta	UCI_COMDATA
			lda	#NET_CMD_OPEN_UDP
			sta	UCI_COMDATA

			lda	r7L			;Port-Nummer an UCI senden.
			sta	UCI_COMDATA
			lda	r7H
			sta	UCI_COMDATA

			jsr	ULIB_PUSH_NAME6		;Hostname an UCI senden.

			lda	#NULL			;Ende-Kennung senden.
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

::err			rts
