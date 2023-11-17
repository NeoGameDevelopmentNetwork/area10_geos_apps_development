; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: $04 NET_CMD_GET_MAC
;
;Hardware-Adresse (MAC) abfragen.
;
;Übergabe : -
;Rückgabe : X = Fehlerstatus, $00=OK
;               UCI_STATUS_MSG = Status-Meldung
;               UCI_DATA_MSG   = Informationen:
;Format   :     Byte#0-5: Hardware-Adresse (MAC)
;Verändert: A,X,Y,r4,r5

:_UCIN_GETMAC

			lda	#UCI_TARGET_NET		;Befehl an UCI senden.
			sta	UCI_COMDATA
			lda	#NET_CMD_GET_MAC
			sta	UCI_COMDATA
			lda	#NET_INTERFACE		;Netzwerk-Schnittstelle $00.
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
