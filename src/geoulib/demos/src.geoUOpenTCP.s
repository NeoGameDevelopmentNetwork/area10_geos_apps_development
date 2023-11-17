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
endif

			n "geoUOpenTCP"
			c "geoUOpenTCP V0.1"
			a "Markus Kanet"

if BUILD_DEBUG = TRUE
			h "192.168.2.2:2049"
else
			h "some.url:port"
endif

			h "Netzwerk-Verbindung über TCP..."

			o APP_RAM
			p MAININIT

			f APPLICATION
			z $40 ;GEOS 40/80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execOpenTCP

;--- geoULib einbinden.
;Systemroutinen:
			t "ulib.C.SymbTab"		;Erweiterte Symboltabelle.
			t "ulib.C.Core"			;UCI-Systemroutinen.

;Optionale Routinen:
			t "ulib._ErrUDev"		;Fehler "Kein Ultimate" ausgeben.
			t "ulib._GetStatus"		;UCI-Statusregister abfragen.
			t "ulib._GetData"		;Daten über UCI einlesen.
			t "ulib._AccData"		;Datenempfang bestätigen.
			t "ulib._Push_NAME6"		;Dateiname/Pfad in r6 an UCI senden.

;NETWORK-Routinen:
			t "_net.07.OpenTCP"		;Verbindung über TCP öffnen.
			t "_net.09.Close"		;Verbindung beenden.

;Erweiterte Programmroutinen:
			t "inc.Conf.Host"		;Host-/Port-Adresse einlesen.

;*** Netzwerk-Verbindung über TCP.
:execOpenTCP		jsr	ULIB_TEST_UDEV		;Ultimate testen.
;			txa				;Gerät vorhanden?
			beq	:ok			; => Ja, weiter...

;--- Kein Ultimate, Fehler, Ende...
;			jsr	ULIB_ERR_NO_UDEV
;			jmp	exitDeskTop		; => Ende...

;--- Ultimate vorhanden.
::ok			jsr	getConfHost		;Konfiguration einlesen.

			lda	uHost			;URL definiert?
			beq	exitDeskTop		; => Nein, Ende...

			lda	uPort +0
			ora	uPort +1		;Port definiert?
			beq	exitDeskTop		; => Nein, Ende...

			jsr	uOpenTCP		;Verbdingung öffnen.

			lda	#< dBoxStatus
			sta	r0L
			lda	#> dBoxStatus
			sta	r0H
			jsr	DoDlgBox		;Status anzeigen.

;*** Zurück zu GEOS.
:exitDeskTop		jmp	EnterDeskTop		;Ende.

;*** Verbindung über TCP öffnen.
;Übergabe : uHost = Host-URL
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;           UCI_DATA_MSG   = Socket-Adresse
;Verändert: A,X,Y,r5,r6,r7L

:uOpenTCP		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			lda	#$00			;Rückmeldung initialisieren.
			sta	socketTCP		; => Keine Informationen.

			lda	#< uHost		;Host-Adresse.
			sta	r6L
			lda	#> uHost
			sta	r6H
			lda	uPort +0		;TCP-Port.
			sta	r7L
			lda	uPort +1
			sta	r7H
			jsr	_UCIN_OPENTCP
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			lda	UCI_DATA_MSG		;Socket/TCP zwischenspeichern.
			sta	socketTCP

;--- TCP-Verbindung beenden.
::err			lda	socketTCP		;Socket/TCP setzen.
			sta	r7L
			jsr	_UCIN_CLOSE_SOCKET
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

;			ldx	#NO_ERROR		;Kein Fehler.
			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;*** Socket/TCP ausgeben.
:prntSocket		lda	#"#"
			jsr	SmallPutChar

			lda	socketTCP
			sta	r0L
			lda	#$00
			sta	r0H

			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal

			rts

;*** Socket/TCP.
:socketTCP		b $00

;*** Dialogbox: Status anzeigen.
:dBoxStatus		b %10000001

			b DBTXTSTR   ,$10,$10
			w :1

			b DBTXTSTR   ,$10,$20
			w :2

			b DBTXTSTR   ,$10,$30
			w uHost
			b DB_USR_ROUT
			w prntSocket

			b DBTXTSTR   ,$10,$44
			w UCI_STATUS_MSG

			b OK         ,$10,$48
			b NULL

::1			b PLAINTEXT,BOLDON
			b "INFORMATION:"
			b PLAINTEXT,NULL

::2			b "Open TCP: ",NULL
