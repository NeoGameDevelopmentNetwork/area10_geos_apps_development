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

;******************************************************************************
::tmp0a = C_41!C_71!C_81!IEC_NM!S2I_NM
::tmp0b = FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM
::tmp0 = :tmp0a!:tmp0b
if :tmp0!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** Laufwerk auf Senden schalten.
;    Rückgabe:    Z-Flag = 1: OK
;                 Z-Flag = 0: Fehler
;                 xReg   = Fehler-Status
:initDataTALK		lda	#5			;Datenkanal.
			b $2c
:initDevTALK		lda	#15			;Befehlskanal.
			sta	:channel

			jsr	UNTALK			;Laufwerk abschalten.

			jsr	:startTALK		;Laufwerk aktivieren.
			beq	:exitTALK		;OK? => Ja, Ende.
							;Nein, zweiter Versuch...

::startTALK		lda	#$00			;Status-Byte löschen.
			sta	STATUS

			lda	curDevice		;Laufwerksadresse verwenden.
			jsr	TALK			;Laufwerk aktivieren.
			bit	STATUS			;Laufwerksfehler?
			bmi	:error			; => Ja, Abbruch...

			lda	:channel		;"REOPEN" -> DO NOT CHANGE!!!
			ora	#$60 				;Der Befehlskanal ist hier bereits
							;durch ":openFComChan" geöffnet!
			jsr	TKSA			;Laufwerk auf Senden schalten.
			ldx	STATUS			;Fehler aufgetreten ?
			beq	:exitTALK		; => Nein, Ende...

::error			jsr	UNTALK			;Laufwerk abschalten.

			ldx	#DEV_NOT_FOUND
::exitTALK		rts

::channel		b $00

;*** Laufwerk auf Empfang schalten.
;Rückgabe: Z-Flag = 1: OK
;          Z-Flag = 0: Fehler
:initDataLISTEN		lda	#5			;Datenkanal.
			b $2c
:initDevLISTEN		lda	#15			;Befehlskanal.
			sta	:channel

			jsr	UNLSN			;Laufwerk abschalten.

			jsr	:startLISTEN		;Laufwerk aktivieren.
			beq	:exitLISTEN		;OK? => Ja, Ende.
							;Nein, zweiter Versuch...

::startLISTEN		lda	#$00			;Status-Byte löschen.
			sta	STATUS

			lda	curDevice		;Laufwerksadresse verwenden.
			jsr	LISTEN			;Laufwerk aktivieren.
			bit	STATUS			;Laufwerksfehler?
			bmi	:error			; => Ja, Abbruch...

			lda	:channel		;"REOPEN" -> DO NOT CHANGE!!!
			ora	#$60 				;Der Befehlskanal ist hier bereits
							;durch ":openFComChan" geöffnet!
			jsr	SECOND			;Laufwerk auf Empfang schalten.
			ldx	STATUS			;Fehler aufgetreten ?
			beq	:exitLISTEN		; => Nein, Ende...

::error			jsr	UNLSN			;Laufwerk abschalten.

			ldx	#DEV_NOT_FOUND
::exitLISTEN		rts

::channel		b $00

;*** Daten-/Befehlskanal schließen.
;Dazu muss das Laufwerk auf LISTEN
;geschaltet, die Sekundäradresse mit
;%11100000=CLOSE kombiniert und dann
;das Laufwerk abgeschaltet werden.
:closeLISTEN		lda	curDevice		;Laufwerksadresse.
			jsr	LISTEN			;Laufwerk aktivieren.
			lda	#5 ! %11100000
;			ora	#$e0			;"CLOSE".
			jsr	SECOND			;Kanal mit SA=15 schließen.
			jsr	UNLSN			;Laufwerk abschalten.

			lda	curDevice		;Laufwerksadresse.
			jsr	LISTEN			;Laufwerk aktivieren.
			lda	#15 ! %11100000
;			ora	#$e0			;"CLOSE".
			jsr	SECOND			;Kanal mit SA=15 schließen.
			jmp	UNLSN			;Laufwerk abschalten.
endif
