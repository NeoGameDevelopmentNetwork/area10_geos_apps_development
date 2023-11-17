; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: $03 DOS_CMD_CLOSE_FILE
;
;Datei zum lesen/schreiben öffnen.
;
;Übergabe: -
;Rückgabe: X = Fehlerstatus, $00=OK
;              UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r5

:_UCID_CLOSE_FILE

			lda	UCI_TARGET		;Befehl an UCI senden.
			sta	UCI_COMDATA
			lda	#DOS_CMD_CLOSE_FILE
			sta	UCI_COMDATA

			jsr	ULIB_PUSH_CMD		;Befehl ausführen.
			txa				;Timeout?
			bne	:err			; => Ja, Abbruch...

;			jsr	ULIB_GET_DATA		;Keine Daten...

;--- Hinweis:
;READ_DATA liefert keinen Status wenn
;kein Fehler auftritt.
			lda	UCI_STATUS_MSG		;Status vorhanden?
			beq	:get_status

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
