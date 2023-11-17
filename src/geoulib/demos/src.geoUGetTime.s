; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "TopSym"
;			t "TopMac"
;			t "Sym128.erg"

;--- GEOS/MegaPatch3.
:millenium		= $9fad
:MP3_CODE		= $c014
endif

			n "geoUGetTime"
			c "geoUGetTime V0.1"
			a "Markus Kanet"

			h "Systemzeit von Ultimate übernehmen..."

			o APP_RAM
			p MAININIT

			f AUTO_EXEC

			z $40 ;GEOS 40/80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execGetTime

;--- geoULib einbinden.
;Systemroutinen:
			t "ulib.C.SymbTab"		;Erweiterte Symboltabelle.
			t "ulib.C.Core"			;UCI-Systemroutinen.

;Optionale Routinen:
			t "ulib._ErrUDev"		;Fehler "Kein Ultimate" ausgeben.
			t "ulib._GetStatus"		;UCI-Statusregister abfragen.
			t "ulib._GetData"		;Daten über UCI einlesen.
			t "ulib._AccData"		;Datenempfang bestätigen.

;DOS-Routinen:
			t "_dos.00.Target"		;DOS-Target 1/2 setzen.
			t "_dos.26.GetTime"		;Datum/Uhrzeit abfragen.

;Allgemeine Programmroutinen:
			t "inc.DBStatusData"		;Status-Dialogbox.

;*** Sysemzeit setzen.
:execGetTime		jsr	ULIB_TEST_UDEV		;Ultimate testen.
;			txa				;Gerät vorhanden?
			beq	:ok			; => Ja, weiter...

;--- Kein Ultimate, Fehler, Ende...
			bit	firstBoot		;GEOS-Boot?
			bpl	:1			; => Ja, Fehler ignorieren.
			jsr	ULIB_ERR_NO_UDEV
::1			jmp	exitDeskTop		; => Ende...

;--- Ultimate vorhanden.
::ok			jsr	uGetTime		;Datum/Uhrzeit abfragen.
			txa				;Fehler?
			bne	:status			; => Ja, nur Status anzeigen.

			jsr	setSystemTime		;Systemzeit setzen.

::status		bit	firstBoot		;GEOS-Boot?
			bpl	exitDeskTop		; => Ja, Ende...

			lda	#< dBoxStatus
			sta	r0L
			lda	#> dBoxStatus
			sta	r0H
			jsr	DoDlgBox		;Status anzeigen.

;*** Zurück zu GEOS.
:exitDeskTop		jmp	EnterDeskTop		;Ende.

;*** Datum/Uhrzeit abfragen.
;Übergabe: -
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;           UCI_DATA_MSG   = Datum/Uhrzeit
;Verändert: A,X,Y,r4,r5

:uGetTime		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			lda	#NULL			;Rückmeldung initialisieren.
			sta	UCI_DATA_MSG		; => Kein Datum/Uhrzeit.
			jsr	_UCID_SET_TARGET1	;Target DOS1 verwenden.
			jsr	_UCID_GET_TIME		;Datum/Uhrzeit abfragen.
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

;			ldx	#NO_ERROR		;Kein Fehler.
::err			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;*** RTC-Daten der U2P nach DEZ wandeln.
:setSystemTime		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.

			lda	MP3_CODE +0		;GEOS/MegaPatch?
			cmp	#"M"
			bne	:v2
			lda	MP3_CODE +1
			cmp	#"P"
			bne	:v2			; => Nein, weiter...

			lda	UCI_DATA_MSG +0		;Jahrtausend.
			ldx	UCI_DATA_MSG +1
			jsr	ASCIItoDEZ
			sta	millenium

::v2			lda	UCI_DATA_MSG +2		;Jahreszahl.
			ldx	UCI_DATA_MSG +3
			jsr	ASCIItoDEZ
			sta	year

			lda	UCI_DATA_MSG +5		;Monat.
			ldx	UCI_DATA_MSG +6
			jsr	ASCIItoDEZ
			sta	month

			lda	UCI_DATA_MSG +8		;Tag.
			ldx	UCI_DATA_MSG +9
			jsr	ASCIItoDEZ
			sta	day

			lda	UCI_DATA_MSG +11	;Stunde.
			ldx	UCI_DATA_MSG +12
			jsr	ASCIItoDEZ
			sta	hour

;Uhrzeit von 24H nach AM/PM wandeln.
;00:00 ist 12AM, 12:00 ist 12PM!
			jsr	DEZtoBCD
			sed				;AM/PM-Flag berechnen.
			cmp	#$13
			bcc	:1
			sbc	#$12
			ora	#%10000000
::1			sta	cia1tod_h		;Stunde setzen.
			cld

			lda	UCI_DATA_MSG +14	;Minute.
			ldx	UCI_DATA_MSG +15
			jsr	ASCIItoDEZ
			sta	minutes

			jsr	DEZtoBCD		;Minute nach BCD wandeln.
			sta	cia1tod_m		;Minute setzen.

			lda	UCI_DATA_MSG +17	;Sekunde.
			ldx	UCI_DATA_MSG +18
			jsr	ASCIItoDEZ
			sta	seconds

			jsr	DEZtoBCD		;Sekunde nach BCD wandeln.
			sta	cia1tod_s		;Sekunde setzen.

			lda	#$00
			sta	cia1tod_t

			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;*** ASCII nach DEZ wandeln.
:ASCIItoDEZ		sec
			sbc	#"0"
			cmp	#10
			bcc	:1
			lda	#9
::1			tay

			txa
			sec
			sbc	#"0"
			cmp	#10
			bcc	:2
			lda	#9

::2			cpy	#0
			beq	:3
			clc
			adc	#10
			dey
			bne	:2

::3			rts

;*** Dezimal nach BCD.
:DEZtoBCD		ldx	#0
::1			cmp	#10
			bcc	:2
			inx
			sbc	#10
			bcs	:1
::2			sta	r0L
			txa
			asl
			asl
			asl
			asl
			ora	r0L
			rts
