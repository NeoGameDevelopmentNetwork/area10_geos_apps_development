; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: $28 CTRL_CMD_GET_HDWINF
;
;Hardware-Informationen Ultimate oder SID abfragen.
;
;Übergabe : -
;Rückgabe : X = Fehlerstatus, $00=OK
;               UCI_STATUS_MSG = Status-Meldung
;               UCI_DATA_MSG   = Hardware-Info
;Verändert: A,X,Y,r4,r5

;--- Hinweis:
;U64: "ULTIMATE 64"
;U2 : "1541 ULTIMATE II"
:_UCIC_GET_HWINFO_DEV

			ldx	#0			;Ultimate-Gerätetyp abfragen.
			beq	getHWInfo

;--- Hinweis:
;Inhalt der Rückmeldung noch unklar.
;Kann bei Bedarf aus dem SourceCode
;zur Firmware entnommen werden.
:_UCIC_GET_HWINFO_SID

			ldx	#1			;SID-Informationen abfragen.

:getHWInfo		lda	#UCI_TARGET_CTRL	;Befehl an UCI senden.
			sta	UCI_COMDATA
			lda	#CTRL_CMD_GET_HWINFO
			sta	UCI_COMDATA

;			ldx	#DEV_INFO
			stx	UCI_COMDATA		;3.Byte = Abfrage-Typ 0/1 senden.

			lda	#NULL			;4.Byte = Format-Kennung.
			sta	UCI_COMDATA		;Funktion unklar...

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
