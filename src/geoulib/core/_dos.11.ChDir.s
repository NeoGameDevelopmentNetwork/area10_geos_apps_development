; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: $11 DOS_CMD_CHANGE_DIR
;
;In ROOT-Verzeichnis wechseln.
;
;Übergabe : -
;Rückgabe : X  = Fehlerstatus, $00=OK
;                UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r5

:_UCID_CD_ROOT

			lda	UCI_TARGET		;Befehl an UCI senden.
			sta	UCI_COMDATA
			lda	#DOS_CMD_CHANGE_DIR
			sta	UCI_COMDATA

			lda	#"/"
			sta	UCI_COMDATA
			bne	_UCID_EXEC_CD

;
;In Eltern-Verzeichnis wechseln.
;
;Übergabe : r6 = Zeiger auf Verzeichnisname
;Rückgabe : X  = Fehlerstatus, $00=OK
;                UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r5

:_UCID_CD_PARENT

			lda	UCI_TARGET
			sta	UCI_COMDATA
			lda	#DOS_CMD_CHANGE_DIR
			sta	UCI_COMDATA

			lda	#"."
			sta	UCI_COMDATA
			nop
			sta	UCI_COMDATA
			bne	_UCID_EXEC_CD

;
;In Verzeichnis /Usb0 wechseln.
;
;Übergabe : -
;Rückgabe : X  = Fehlerstatus, $00=OK
;                UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r5,r6

:_UCID_CD_USB0

			lda	#< :path_usb0
			ldx	#> :path_usb0
			bne	_UCID_CD_PATH

::path_usb0		b "/Usb0",NULL

;
;In Verzeichnis /Usb1 wechseln.
;
;Übergabe : -
;Rückgabe : X  = Fehlerstatus, $00=OK
;                UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r5,r6

:_UCID_CD_USB1

			lda	#< :path_usb1
			ldx	#> :path_usb1
			bne	_UCID_CD_PATH

::path_usb1		b "/Usb1",NULL

;
;Verzeichnis wechseln.
;
;Übergabe : A/X = Zeiger auf Verzeichnisname
;Rückgabe : X   = Fehlerstatus, $00=OK
;                 UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r5,r6

:_UCID_CD_PATH

			sta	r6L
			stx	r6H

;
;Verzeichnis öffnen.
;
;Übergabe: r6 = Zeiger auf Verzeichnisname.
;Rückgabe: X  = Fehlerstatus, $00=OK
;               UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r5

:_UCID_CHANGE_DIR

			lda	UCI_TARGET
			sta	UCI_COMDATA
			lda	#DOS_CMD_CHANGE_DIR
			sta	UCI_COMDATA

			jsr	ULIB_PUSH_NAME6		;Dateiname an UCI senden.

:_UCID_EXEC_CD		jsr	ULIB_PUSH_CMD		;Befehl ausführen.
			txa				;Timeout?
			bne	:err			; => Ja, Abbruch...

;			jsr	ULIB_GET_DATA		;Keine Daten...
			jsr	ULIB_GET_STATUS		;Status einlesen.
			jsr	ULIB_ACCEPT_DATA	;Datenempfang bestätigen.
			txa				;Timeout?
			bne	:err			; => Ja, Abbruch...

			jsr	ULIB_TEST_ERR		;Fehlerstatus auswerten.

::err			rts
