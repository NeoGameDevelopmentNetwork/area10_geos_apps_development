; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: $21 DOS_CMD_LOAD_REU
;
;Daten aus DiskImage in REU laden.
;
;Übergabe : r0/r1 = Startadresse in REU
;           r2/r3 = Anzahl Bytes
;Rückgabe : X = Fehlerstatus, $00=OK
;               UCI_STATUS_MSG = Status-Meldung
;               UCI_DATA_MSG   = Transfer-Status
;Verändert: A,X,Y,r4,r5

:_UCID_LOAD_REU

			lda	UCI_TARGET		;Befehl an UCI senden.
			sta	UCI_COMDATA
			lda	#DOS_CMD_LOAD_REU
			sta	UCI_COMDATA

			ldx	#r0			;Adresse in REU an UCI senden.
			jsr	ULIB_PUSH_DWORD
			ldx	#r2			;Größe für DiskImage an UCI senden.
			jsr	ULIB_PUSH_DWORD

			jsr	ULIB_PUSH_CMD		;Befehl ausführen.
			txa				;Timeout?
			bne	:err			; => Ja, Abbruch...

			jsr	ULIB_GET_STRING		;Daten einlesen, Ende = NULL-Byte.
			jsr	ULIB_GET_STATUS		;Status einlesen.
			jsr	ULIB_ACCEPT_DATA	;Datenempfang bestätigen.
			txa				;Timeout?
			bne	:err			; => Ja, Abbruch...

			jsr	ULIB_TEST_ERR		;Fehlerstatus auswerten.

::err			rts
