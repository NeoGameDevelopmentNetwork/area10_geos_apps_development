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
::tmp0a = FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM
::tmp0b = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp0 = :tmp0a!:tmp0b
if :tmp0!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Laufwerk auf Senden schalten.
;    Rückgabe:    Z-Flag = 1: OK
;                 Z-Flag = 0: Fehler
;                 xReg   = Fehler-Status
:initDevTALK		jsr	UNTALK			;Laufwerk abschalten.

			jsr	:startTALK		;Laufwerk aktivieren.
			beq	:exitTALK		;OK? => Ja, Ende.
							;Nein, zweiter Versuch...

::startTALK		lda	#$00			;Status-Byte löschen.
			sta	STATUS

			lda	curDevice		;Laufwerksadresse verwenden.
			jsr	TALK			;Laufwerk aktivieren.
			bit	STATUS			;Laufwerksfehler?
			bmi	:error			; => Ja, Abbruch...

			lda	#15 ! %01100000
;			ora	#$60			;"REOPEN".
			jsr	TKSA			;Laufwerk auf Senden schalten.
			ldx	STATUS			;Fehler aufgetreten ?
			beq	:exitTALK		; => Nein, Ende...

::error			jsr	UNTALK			;Laufwerk abschalten.

			ldx	#DEV_NOT_FOUND
::exitTALK		rts

;*** Laufwerk auf Empfang schalten.
;Rückgabe: Z-Flag = 1: OK
;          Z-Flag = 0: Fehler
:initDevLISTEN		jsr	UNLSN			;Laufwerk abschalten.

			jsr	:startLISTEN		;Laufwerk aktivieren.
			beq	:exitLISTEN		;OK? => Ja, Ende.
							;Nein, zweiter Versuch...

::startLISTEN		lda	#$00			;Status-Byte löschen.
			sta	STATUS

			lda	curDevice		;Laufwerksadresse verwenden.
			jsr	LISTEN			;Laufwerk aktivieren.
			bit	STATUS			;Laufwerksfehler?
			bmi	:error			; => Ja, Abbruch...

			lda	#15 ! %01100000
;			ora	#$60			;"REOPEN".
			jsr	SECOND			;Laufwerk auf Empfang schalten.
			ldx	STATUS			;Fehler aufgetreten ?
			beq	:exitLISTEN		; => Nein, Ende...

::error			jsr	UNLSN			;Laufwerk abschalten.

			ldx	#DEV_NOT_FOUND
::exitLISTEN		rts

;*** Befehlskanal schließen.
;Dazu muss das Laufwerk auf LISTEN
;geschaltet, die Sekundäradresse mit
;%11100000=CLOSE kombiniert und dann
;das Laufwerk abgeschaltet werden.
:closeLISTEN		lda	curDevice		;Laufwerksadresse.
			jsr	LISTEN			;Laufwerk aktivieren.
			lda	#15 ! %11100000
;			ora	#$e0			;"CLOSE".
			jsr	SECOND			;Kanal mit SA=15 schließen.
			jmp	UNLSN			;Laufwerk abschalten.
endif

;******************************************************************************
::tmp1 = RL_41!RL_71!RL_81!RL_NM
if :tmp1!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Laufwerk auf Senden schalten.
;    Rückgabe:    Z-Flag = 1: OK
;                 Z-Flag = 0: Fehler
;                 xReg   = Fehler-Status
:initDevTALK		jsr	UNTALK			;Laufwerk abschalten.

			jsr	:startTALK		;Laufwerk aktivieren.
			beq	:exitTALK		;OK? => Ja, Ende.
							;Nein, zweiter Versuch...

::startTALK		lda	#$00			;Status-Byte löschen.
			sta	STATUS

			lda	sysRAMLink		;RAMLink-Adresse verwenden.
			jsr	TALK			;Laufwerk aktivieren.
			bit	STATUS			;Laufwerksfehler?
			bmi	:error			; => Ja, Abbruch...

			lda	#15 ! %01100000
;			ora	#$60			;"REOPEN".
			jsr	TKSA			;Laufwerk auf Senden schalten.
			ldx	STATUS			;Fehler aufgetreten ?
			beq	:exitTALK		; => Nein, Ende...

::error			jsr	UNTALK			;Laufwerk abschalten.

			ldx	#DEV_NOT_FOUND
::exitTALK		rts

;*** Laufwerk auf Empfang schalten.
;Rückgabe: Z-Flag = 1: OK
;          Z-Flag = 0: Fehler
:initDevLISTEN		jsr	UNLSN			;Laufwerk abschalten.

			jsr	:startLISTEN		;Laufwerk aktivieren.
			beq	:exitLISTEN		;OK? => Ja, Ende.
							;Nein, zweiter Versuch...

::startLISTEN		lda	#$00			;Status-Byte löschen.
			sta	STATUS

			lda	sysRAMLink		;RAMLink-Adresse verwenden.
			jsr	LISTEN			;Laufwerk aktivieren.
			bit	STATUS			;Laufwerksfehler?
			bmi	:error			; => Ja, Abbruch...

			lda	#15 ! %01100000
;			ora	#$60			;"REOPEN".
			jsr	SECOND			;Laufwerk auf Empfang schalten.
			ldx	STATUS			;Fehler aufgetreten ?
			beq	:exitLISTEN		; => Nein, Ende...

::error			jsr	UNLSN			;Laufwerk abschalten.

			ldx	#DEV_NOT_FOUND
::exitLISTEN		rts

;*** Befehlskanal schließen.
;Dazu muss das Laufwerk auf LISTEN
;geschaltet, die Sekundäradresse mit
;%11100000=CLOSE kombiniert und dann
;das Laufwerk abgeschaltet werden.
:closeLISTEN		lda	sysRAMLink		;Laufwerksadresse.
			jsr	LISTEN			;Laufwerk aktivieren.
			lda	#15 ! %11100000
;			ora	#$e0			;"CLOSE".
			jsr	SECOND			;Kanal mit SA=15 schließen.
			jmp	UNLSN			;Laufwerk abschalten.
endif

;******************************************************************************
::tmp2 = C_41!C_71!C_81!PC_DOS!IEC_NM!S2I_NM
if :tmp2!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Laufwerk auf Empfang schalten.
;    Rückgabe:    Z-Flag = 1: OK
;                 Z-Flag = 0: Fehler
;                 xReg   = Fehler-Status
:initDevLISTEN		jsr	UNLSN			;Laufwerk abschalten.

			jsr	:startLISTEN		;Laufwerk aktivieren.
			beq	:exitLISTEN		;OK? => Ja, Ende.
							;Nein, zweiter Versuch...

::startLISTEN		lda	#$00			;Status-Byte löschen.
			sta	STATUS

			lda	curDevice		;Laufwerksadresse verwenden.
			jsr	LISTEN			;Laufwerk aktivieren.
			bit	STATUS			;Laufwerksfehler?
			bmi	:error			; => Ja, Abbruch...

			lda	#15 ! %01100000
;			ora	#$60			;"REOPEN".
			jsr	SECOND			;Laufwerk auf Empfang schalten.
			ldx	STATUS			;Fehler aufgetreten ?
			beq	:exitLISTEN		; => Nein, Ende...

::error			jsr	UNLSN			;Laufwerk abschalten.

			ldx	#DEV_NOT_FOUND
::exitLISTEN		rts

;*** Befehlskanal schließen.
;Dazu muss das Laufwerk auf LISTEN
;geschaltet, die Sekundäradresse mit
;%11100000=CLOSE kombiniert und dann
;das Laufwerk abgeschaltet werden.
:closeLISTEN		lda	curDevice		;Laufwerksadresse.
			jsr	LISTEN			;Laufwerk aktivieren.
			lda	#15 ! %11100000
;			ora	#$e0			;"CLOSE".
			jsr	SECOND			;Kanal mit SA=15 schließen.
			jmp	UNLSN			;Laufwerk abschalten.
endif
