; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;Reference: "Serial bus control codes"
;https://codebase64.org/doku.php?id=base:how_the_vic_64_serial_bus_works
;$20-$3E : LISTEN  , device number ($20 + device number #0-30)
;$3F     : UNLISTEN, all devices
;$40-$5E : TALK    , device number ($40 + device number #0-30)
;$5F     : UNTALK  , all devices
;$60-$6F : REOPEN  , channel ($60 + secondary address / channel #0-15)
;$E0-$EF : CLOSE   , channel ($E0 + secondary address / channel #0-15)
;$F0-$FF : OPEN    , channel ($F0 + secondary address / channel #0-15)

;*** Laufwerk auf Senden schalten.
;    Rückgabe:    Z-Flag = 1: OK
;                 Z-Flag = 0: Fehler
;                 xReg   = Fehler-Status
:initDataTALK		lda	#5			;Datenkanal.
			b $2c
:initDevTALK		lda	#15			;Befehlskanal.
			sta	devChan

			jsr	UNTALK			;Laufwerk abschalten.

			jsr	:startTALK		;Laufwerk aktivieren.
			beq	:exit			;OK? => Ja, Ende.
							;Nein, zweiter Versuch...

::startTALK		ClrB	STATUS			;Status-Byte löschen.

			lda	curDevice		;Laufwerksadresse verwenden.
			jsr	TALK			;Laufwerk aktivieren.
			bit	STATUS			;Laufwerksfehler?
			bmi	:error			; => Ja, Abbruch...

			lda	devChan			;REOPEN -> DO NOT CHANGE!!!
			ora	#%01100000 			;Der Befehlskanal ist hier bereits
							;durch ":openFComChan" geöffnet!
			jsr	TKSA			;Laufwerk auf Senden schalten.
			ldx	STATUS			;Fehler aufgetreten ?
			beq	:exit			; => Nein, Ende...

::error			jsr	UNTALK			;Laufwerk abschalten.

			ldx	#DEV_NOT_FOUND
::exit			rts

;*** Laufwerk auf Empfang schalten.
;Rückgabe: Z-Flag = 1: OK
;          Z-Flag = 0: Fehler
:initDataLISTEN		lda	#5			;Datenkanal.
			b $2c
:initDevLISTEN		lda	#15			;Befehlskanal.
			sta	devChan

			jsr	UNLSN			;Laufwerk abschalten.

			jsr	startLISTEN		;Laufwerk aktivieren.
			beq	exitLISTEN		;OK? => Ja, Ende.
							;Nein, zweiter Versuch...

:startLISTEN		lda	#$60			;"REOPEN". -> DO NOT CHANGE!!!
							;Der Befehlskanal ist hier bereits
							;durch ":openFComChan" geöffnet!
			b $2c
:closeLISTEN		lda	#$e0			;"CLOSE".
			sta	:ieccom +1

			ClrB	STATUS			;Status-Byte löschen.

			lda	curDevice		;Laufwerksadresse verwenden.
			jsr	LISTEN			;Laufwerk aktivieren.
			bit	STATUS			;Laufwerksfehler?
			bmi	:error			; => Ja, Abbruch...

			lda	devChan
::ieccom		ora	#$ff
			jsr	SECOND			;Laufwerk auf Empfang schalten.
			ldx	STATUS			;Fehler aufgetreten ?
			beq	exitLISTEN		; => Nein, Ende...

::error			jsr	UNLSN			;Laufwerk abschalten.

			ldx	#DEV_NOT_FOUND
:exitLISTEN		rts

;*** Laufwerkskanal.
:devChan		b $00
