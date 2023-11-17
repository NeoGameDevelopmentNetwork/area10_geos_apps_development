; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: $05 CTRL_CMD_FREEZE
;
;Startet das Ultimate-Menü.
;
;Übergabe : -
;Rückgabe : X = Fehlerstatus, $00=OK
;Verändert: A,X,Y

:_UCIC_FREEZE

			jsr	ULIB_128_SLOW		;C128: 1MHz.

			lda	#UCI_TARGET_CTRL	;Befehl an UCI senden.
			sta	UCI_COMDATA
			lda	#CTRL_CMD_FREEZE
			sta	UCI_COMDATA

;--- Sonderbehandlung für Freeze.
			lda	#CMD_NEW_CMD
			sta	UCI_CONTROL

;--- Hinweis:
;Warteschleife für FREEZE-Routine des
;Ultimate. Ohne Verzögerung führt die
;Rückkehr aus dem Menü in seltenen
;Fällen zum Absturz.
			ldy	#0			;Zähler initialisieren.
::wait			jsr	ULIB_WAIT		;Verzögerung
			dey
			bne	:wait

			lda	cia1tod_t		;Systemuhr wieder starten.
			sta	cia1tod_t

;--- CMD_FREEZE liefert keine Daten/Status zurück.
;Siehe firmware/control_target.cc
;			jsr	ULIB_GET_DATA		;Keine Daten...
;			jsr	ULIB_GET_STATUS		;Kein Status...
;			jsr	ULIB_ACCEPT_DATA	;Datenempfang bestätigen.
;			txa				;Timeout?
;			bne	:err			; => Ja, Abbruch...
;
;			jsr	ULIB_TEST_ERR		;Fehlerstatus auswerten.

::err			jsr	ULIB_128_RESTORE	;C128: CLKRATE zurücksetzen.

			rts
