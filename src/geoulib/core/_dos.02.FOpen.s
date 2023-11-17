; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: $02 DOS_CMD_OPEN_FILE
;
;Datei zum lesen/schreiben öffnen.
;
;Übergabe: X  = Filemode:
;               $01=READ
;               $02=WRITE, in Kombination mit:
;               $04=NEW       oder
;               $08=OVERWRITE
;          r6 = Zeiger auf Dateiname
;Rückgabe: X  = Fehlerstatus, $00=OK
;               UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r5

:_UCID_OPEN_FILE_READ
			ldx	#%00000001
			b $2c

:_UCID_OPEN_FILE_WRITE
			ldx	#%00000010
			b $2c

:_UCID_OPEN_FILE_NEW
			ldx	#%00000110
			b $2c

:_UCID_OPEN_FILE_OVERWRITE
			ldx	#%00001010

:_UCID_OPEN_FILE_XATTR

			lda	UCI_TARGET		;Befehl an UCI senden.
			sta	UCI_COMDATA
			lda	#DOS_CMD_OPEN_FILE
			sta	UCI_COMDATA

;			ldx	#FILE_MODE		;Dateimodus an UCI senden.
			stx	UCI_COMDATA

			jsr	ULIB_PUSH_NAME6		;Dateiname an UCI senden.

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
