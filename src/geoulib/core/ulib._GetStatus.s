; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; ULIB: Status einlesen
;
;Holt den Status des letzten Befehls
;vom UCI in den Speicher des C64.
;
;Max. 80 Zeichen!
;
;--- firmware/control_target.cc/dos.cc:
;status_message.message = new uint8_t(80);
;
;Übergabe : -
;Rückgabe : X  = Fehlerstatus:
;                $00=OK
;                $43=Kein Status
;           r5 = Zeiger auf das NULL-Abschluss-Byte
;                Daten liegen ab UCI_STATUS_MSG im Speicher
;Verändert: A,X,Y,r5

:ULIB_GET_STATUS

			ldx	#< UCI_STATUS_MSG
			ldy	#> UCI_STATUS_MSG

;
;Übergabe : X/Y = Zeiger auf Status-Speicher.
;Rückgabe : X   = Fehlerstatus:
;                 $00=OK
;                 $43=Kein Status
;           r5  = Zeiger auf das NULL-Abschluss-Byte
;Verändert: A,X,Y,r5

:ULIB_GET_STATUS_r5

			stx	r5L			;Zeiger auf
			sty	r5H			;Status-Speicher setzen.

			lda	#NULL			;Status-Speicher initialisieren.
			tay
			sta	(r5),y

			ldx	#UCI_NO_STATUS
			bit	UCI_STATUS		;Status vorhanden?
			bvc	:exit			; => Nein, Ende...

			ldx	#80
;			ldy	#0
::loop			bit	UCI_STATUS		;Ende erreicht?
			bvc	:done			; => ja, Ende...

			lda	UCI_DATASTATUS		;Statusbyte einlesen.

			cpx	#0			;Speicher voll?
			beq	:loop			; => Ja, Byte ignorieren...

			sta	(r5),y			;Statusbyte speichern.

			dex

			inc	r5L
			bne	:loop
			inc	r5H
			jmp	:loop			;Nächstes Zeichen...

::done			lda	#NULL			;Ende-Kennung schreiben.
			sta	(r5),y

			ldx	#UCI_NO_ERROR		;Kein Fehler.
::exit			rts

;
; ULIB: UCI-Status auswerten
;
;Übergabe : -
;Rückgabe : X = Fehlerstatus:
;
;Siehe:
; -> firmware/software/filemanager/dos.cc
; -> firmware/software/io/command_interface/command_intf.cc
;
;               $00=OK
;               $01,DIRECTORY EMPTY
;               $02,REQUEST TRUNCATED
;               $21,UNKNOWN COMMAND
;               $81,NOT IN DATA MODE
;               $82,FILE NOT FOUND
;               $83,NO SUCH DIRECTORY
;               $84,NO FILE TO CLOSE
;               $85,NO FILE OPEN
;               $86,CAN'T READ DIRECTORY
;               $87,INTERNAL ERROR
;               $88,NO INFORMATION AVAILABLE
;               $89,NOT A DISK IMAGE
;               $90,DRIVE NOT PRESENT
;               $91,INCOMPATIBLE IMAGE
;               $98,FUNCTION PROHIBITED
;               $99,FUNCTION NOT IMPLEMENTED
;
;               $40=Keine Ultimate erkannt
;               $41=Timeout-Fehler
;               $42=Unbekannter Statusfehler
;               $43=Kein Status
;               $44=Keine Daten

;Verändert: A,X

:ULIB_TEST_ERR		ldx	UCI_STATUS_MSG +0	;Status verfügbar?
			beq	:ok			; => Nein, OK...

			lda	UCI_STATUS_MSG +2
			cmp	#","			;Trennzeichen "," vorhanden?
			bne	:err			; => Nein, Fehler...

;			lda	UCI_STATUS_MSG +0	;Status "xx" überprüfen.
			txa
			cmp	#"0"			;Zahl 0-9 ?
			bcc	:err
			cmp	#"9" +1
			bcs	:err			; => Nein, Fehler...
			sec
			sbc	#"0"
			asl
			asl
			asl
			asl
			sta	:temp_err_buf

			lda	UCI_STATUS_MSG +1
			cmp	#"0"			;Zahl 0-9 ?
			bcc	:err
			cmp	#"9" +1
			bcs	:err			; => Nein, Fehler...
			sec
			sbc	#"0"
			ora	:temp_err_buf		;Fehlercode erzeugen.
			tax				;Übergabe im X-Register.

::ok			rts

::err			ldx	#UCI_ERR_STATUS
			rts

::temp_err_buf		b $00
