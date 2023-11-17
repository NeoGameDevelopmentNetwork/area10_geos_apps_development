; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; ULIB: Daten einlesen
;
;Holt die Daten des letzten Befehls
;vom UCI in den Speicher des C64.
;
;Max. 512 Bytes!
;
;--- firmware/control_target.cc/dos.cc:
;data_message.message = new uint8_t(512);
;

;
; ULIB: Daten nach UCI_DATA_MSG einlesen
;
;Übergabe : -
;Rückgabe : X  = Fehlerstatus:
;                $00=OK
;                $02=Keine Daten
;           r4 = Zeiger hinter das zuletzt gelesene Byte
;                Daten liegen ab UCI_DATA_MSG im Speicher
;Verändert: A,X,Y,r4

:ULIB_GET_DATA

			ldx	#< UCI_DATA_MSG
			ldy	#> UCI_DATA_MSG

;
; ULIB: Daten nach X/Y einlesen
;
;Übergabe : X/Y = Zeiger auf Datenspeicher
;Rückgabe : X   = Fehlerstatus:
;                 $00=OK
;                 $02=Keine Daten
;           r4  = Zeiger hinter das zuletzt gelesene Byte
;Verändert: A,X,Y,r4

:ULIB_GET_DATA_XY

			stx	r4L			;Zeiger auf
			sty	r4H			;Datenspeicher setzen.

			jsr	ULIB_GET_NEXT
;			txa				;Timeout?
;			bne	:err			; => Ja, Abbruch...

::err			rts

;
; ULIB: String nach UCI_DATA_MSG einlesen
;
;Übergabe : -
;Rückgabe : X  = Fehlerstatus:
;                $00=OK
;                $02=Keine Daten
;           r4 = Zeiger hinter das zuletzt gelesene Byte
;                Daten liegen ab UCI_DATA_MSG im Speicher
;                Setzt 'End-of-Data'-Markierung mit NULL-Byte
;Verändert: A,X,Y,r4

:ULIB_GET_STRING

			ldx	#< UCI_DATA_MSG
			ldy	#> UCI_DATA_MSG

;
; ULIB: String nach X/Y einlesen
;
;Übergabe : X/Y = Zeiger auf Datenspeicher
;Rückgabe : X   = Fehlerstatus:
;                 $00=OK
;                 $02=Keine Daten
;           r4  = Zeiger hinter das zuletzt gelesene Byte
;                 Setzt 'End-of-Data'-Markierung mit NULL-Byte
;Verändert: A,X,Y,r4

:ULIB_GET_STR_XY

			stx	r4L			;Zeiger auf
			sty	r4H			;Datenspeicher setzen.

			lda	#NULL			;Datenspeicher initialisieren.
			tay
			sta	(r4),y

			jsr	ULIB_GET_NEXT
			txa				;Timeout?
			bne	:err			; => Ja, Abbruch...

;			ldy	#0
;			lda	#NULL			;$00-Byte als Ende-Kennung
			sta	(r4),y			;schreiben.

::err			rts

;
; ULIB: Daten nach r4 einlesen
;
;Übergabe : r4  = Zeiger auf Datenspeicher
;Rückgabe : X   = Fehlerstatus:
;                 $00=OK
;                 $02=Keine Daten
;           r4  = Zeiger hinter das zuletzt gelesene Byte
;           Y   = $00 (wenn kein Fehler aufgetreten ist)
;Verändert: A,X,Y,r4

:ULIB_GET_NEXT		jsr	ULIB_WAIT_IDLE		;Auf Ultimate warten...
			txa				;Timeout?
			bne	:exit			; => Ja, Abbruch...

			ldx	#UCI_NO_DATA
			bit	UCI_STATUS		;Daten verfügbar?
			bpl	:exit			; => Nein, Ende...

			ldx	#2
			ldy	#0
::loop			bit	UCI_STATUS		;Ende erreicht?
			bpl	:done			; => Ja, Ende...

			lda	UCI_DATAINFO		;Datenbyte einlesen.

			cpx	#0			;Speicher voll?
			beq	:loop			; => Ja, Datenbyte ignorieren...

			sta	(r4),y			;Datenbyte speichern.

			inc	r4L
			bne	:loop

			inc	r4H
			dex

			jmp	:loop			;Nächstes Zeichen...

::done			ldx	#UCI_NO_ERROR
::exit			rts
