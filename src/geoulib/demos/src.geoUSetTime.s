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
			t "ext.BuildMod.ext"

;--- GEOS/MegaPatch3.
:millenium		= $9fad
:MP3_CODE		= $c014
endif

			n "geoUSetTime"
			c "geoUSetTime V0.1"
			a "Markus Kanet"

			h "GEOS-Datum/Uhrzeit an Ultimate senden..."

			o APP_RAM
			p MAININIT

			f APPLICATION
			z $40 ;GEOS 40/80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execSetTime

;--- geoULib einbinden.
;Systemroutinen:
			t "ulib.C.SymbTab"		;Erweiterte Symboltabelle.
			t "ulib.C.Core"			;UCI-Systemroutinen.

;Optionale Routinen:
			t "ulib._ErrUDev"		;Fehler "Kein Ultimate" ausgeben.
			t "ulib._GetStatus"		;UCI-Statusregister abfragen.
			t "ulib._AccData"		;Datenempfang bestätigen.

;DOS-Routinen:
			t "_dos.00.Target"		;DOS-Target 1/2 setzen.
			t "_dos.27.SetTime"		;SetTime Ultimate.

;Erweiterte Programmroutinen:
;			-

;*** Datum/Uhrzeit für Ultimate setzen.
:execSetTime		jsr	ULIB_TEST_UDEV		;Ultimate testen.
;			txa				;Gerät vorhanden?
			beq	:ok			; => Ja, weiter...

;--- Kein Ultimate, Fehler, Ende...
			jsr	ULIB_ERR_NO_UDEV
			jmp	exitDeskTop		; => Ende...

;--- Ultimate vorhanden.
::ok			jsr	getConfigTime		;Datum/Uhrzeit vorbereiten.

			jsr	uSetTime		;Datum/Uhrzeit für Ultimate setzen.

			lda	#< dbNoText		;Kein Fehler...
			ldy	#> dbNoText
			cpx	#$00			;Fehler-Status testen.
			beq	:1			; => Kein, Fehler, weiter...
			lda	#< dbNotAllowed		;Hinweis auf 'Allow SetTime'.
			ldy	#> dbNotAllowed
::1			sta	r5L			;Zeiger auf Hinweistext an
			sty	r5H			;Dialogbox übergeben.

			lda	#< dBoxStatus
			sta	r0L
			lda	#> dBoxStatus
			sta	r0H
			jsr	DoDlgBox		;Status anzeigen.

;*** Zurück zu GEOS.
:exitDeskTop		jmp	EnterDeskTop		;Ende.

;*** Datum/Uhrzeit für Ultimate setzen.
;Übergabe : uTimeBuf = Datum/Uhrzeit.
;                      Format (6 Bytes):
;                      YY,MM,DD,hh,mm,ss
;                      YY = JAHR - 1900 (0-255)
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r4,r5

:uSetTime		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			jsr	_UCID_SET_TARGET1	;Target DOS1 verwenden.

			lda	#< uTimeBuf		;Zeiger auf Datum/Uhrzeit.
			sta	r4L
			lda	#> uTimeBuf
			sta	r4H
			jsr	_UCID_SET_TIME

			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;--- Zwischenspeicher für Datum/Uhrzeit.
:uTimeBuf		s 6

;*** Datum/Uhrzeit einlesen.
:getConfigTime		ldx	#19			;GEOS V2:
			lda	year			;Jahr von 1980 bis 2079.
			cmp	#80
			bcs	:1
			inx

::1			ldy	MP3_CODE +0		;GEOS/MegaPatch?
			cpy	#"M"
			bne	:2
			ldy	MP3_CODE +1
			cpy	#"P"
			bne	:2			; => Nein, weiter...

			ldx	millenium		;Jahrtausend aus System übernehmen.

::2			sec				;Jahreszahl wird als Wert von
			sbc	#00			;0-255 ab 1900 übergeben.
			pha
			txa
			sbc	#19
			tay
			pla

			cpy	#0			;Zahl < 100?
			beq	:4			; => Ja, weiter...

::3			clc				;Jahr +100.
			adc	#100
			dey				;Differenz Jahrtausend = 0?
			bne	:3			; => Nein, weiter...

::4			sta	uTimeBuf +0		;Jahr (0-255) in Zwischenspeicher.

			ldx	#1			;Monat/Tag/Stunde/Minute/Sekunde
::5			lda	year,x			;in Zwischenspeicher kopieren.
			sta	uTimeBuf,x
			inx
			cpx	#6
			bcc	:5

			rts

;*** Dialogbox: Status anzeigen.
:dBoxStatus		b %10000001

			b DBTXTSTR,$10,$10
			w :1

			b DBTXTSTR   ,$10,$20
			w :2
			b DBTXTSTR   ,$10,$2a
			w UCI_STATUS_MSG

			b DBVARSTR   ,$10,$38
			b r5L

			b OK         ,$10,$48
			b NULL

::1			b PLAINTEXT,BOLDON
			b "INFORMATION:"
			b PLAINTEXT,NULL

::2			b "Set time: ",NULL

:dbNotAllowed		b "UltiDOS: Allow SetDate enabled?"
:dbNoText		b NULL
