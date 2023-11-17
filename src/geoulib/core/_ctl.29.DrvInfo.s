; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: $29 CTRL_CMD_GET_DRVINFO
;
;Laufwerkinformationen abfragen.
;
;Übergabe : -
;Rückgabe : X = Fehlerstatus, $00=OK
;               UCI_STATUS_MSG = Status-Meldung
;               UCI_DATA_MSG   = Laufwerk-Info
;Format   :     Byte #00   : Anzahl Laufwerke (4)
;               Byte #01-03: Konfiguration Laufwerk A
;                            Laufwerkstyp (0=1541, 1=1571, 2=1581, 3=UNSET)
;                            IEC-ID oder Geräteadresse (je nach Firmware)
;                            Laufwerk-Status (1=Ein, 0=Aus)
;               Byte #04-06: Konfiguration Laufwerk B
;               Byte #07-09: Konfiguration IEC-Laufwerk (Typ=15)
;               Byte #10-12: Konfiguration Drucker (Typ=80)
;Verändert: A,X,Y,r4,r5

:_UCIC_GET_DRVINFO

			lda	#UCI_TARGET_CTRL	;Befehl an UCI senden.
			sta	UCI_COMDATA
			lda	#CTRL_CMD_GET_DRVINFO
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
