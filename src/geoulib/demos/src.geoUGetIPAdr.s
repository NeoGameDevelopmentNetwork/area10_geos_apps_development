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
endif

			n "geoUGetIPAdr"
			c "geoUGetIPAdrV0.1"
			a "Markus Kanet"

			h "IP-Adresse anzeigen..."

			o APP_RAM
			p MAININIT

			f APPLICATION

			z $40 ;GEOS 40/80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execGetIPAddr

;--- geoULib einbinden.
;Systemroutinen:
			t "ulib.C.SymbTab"		;Erweiterte Symboltabelle.
			t "ulib.C.Core"			;UCI-Systemroutinen.

;Optionale Routinen:
			t "ulib._ErrUDev"		;Fehler "Kein Ultimate" ausgeben.
			t "ulib._GetStatus"		;UCI-Statusregister abfragen.
			t "ulib._GetData"		;Daten über UCI einlesen.
			t "ulib._AccData"		;Datenempfang bestätigen.

;NETWORK-Routinen:
			t "_net.05.GetIPAdr"		;IP-Adresse abfragen.

;*** IP-Adresse anzeigen.
:execGetIPAddr		jsr	ULIB_TEST_UDEV		;Ultimate testen.
;			txa				;Gerät vorhanden?
			beq	:ok			; => Ja, weiter...

;--- Kein Ultimate, Fehler, Ende...
			jsr	ULIB_ERR_NO_UDEV
			jmp	exitDeskTop		; => Ende...

;--- Ultimate vorhanden.
::ok			jsr	uGetIPAddr		;IP-Adresse abfragen.

			lda	#< dBoxStatus
			sta	r0L
			lda	#> dBoxStatus
			sta	r0H
			jsr	DoDlgBox		;Status ausgeben.

;*** Zurück zu GEOS.
:exitDeskTop		jmp	EnterDeskTop		;Ende.

;*** IP-Adresse anzeigen.
;Übergabe: -
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;           UCI_DATA_MSG   = Netzwerk-Informationen
;Verändert: A,X,Y,r4,r5

:uGetIPAddr		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			ldx	#0
			lda	#$ff			;Rückmeldung initialisieren.
::1			sta	UCI_DATA_MSG,x		; => Keine Informationen.
			inx
			cpx	#12
			bcc	:1

			jsr	_UCIN_GETIPADDR
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

;			ldx	#NO_ERROR		;Kein Fehler.
:err			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;*** Rückmeldung ausgeben.
:prntIPAddr		ldy	#0
			b $2c
:prntNetMask		ldy	#4
			b $2c
:prntGateway		ldy	#8
			ldx	#0
::1			lda	UCI_DATA_MSG,y
			sta	r14,x
			iny
			inx
			cpx	#4
			bcc	:1

			lda	r14L			;Byte #1.
			sec
			jsr	prntByte

			lda	r14H			;Byte #2.
			sec
			jsr	prntByte

			lda	r15L			;Byte #3.
			sec
			jsr	prntByte

			lda	r15H			;Byte #4.
			clc
			jsr	prntByte

			rts

;*** Bytewert ausgeben.
;Übergabe: AKKU   = Bytewert.
;          C-Flag = 0: Kein Trennzeichen ausgeben.
;                   1: Trennzeichen ausgeben.
:prntByte		php

			sta	r0L
			lda	#$00
			sta	r0H

			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal

			plp				;Trennzeichen ausgeben?
			bcc	:1			; => Nein, Ende...

			lda	#"."			;Trennzeichen...
			jsr	SmallPutChar

::1			rts

;*** Dialogbox: Status anzeigen.
:dBoxStatus		b %10000001

			b DBTXTSTR   ,$10,$10
			w :1

			b DBTXTSTR   ,$10,$20
			w UCI_STATUS_MSG

			b DBTXTSTR   ,$10,$30
			w :txIP
			b DB_USR_ROUT
			w prntIPAddr

			b DBTXTSTR   ,$10,$3a
			w :txNET
			b DB_USR_ROUT
			w prntNetMask

			b DBTXTSTR   ,$10,$44
			w :txGW
			b DB_USR_ROUT
			w prntGateway

			b OK         ,$10,$48
			b NULL

::1			b PLAINTEXT,BOLDON
			b "INFORMATION:"
			b PLAINTEXT,NULL

::txIP			b PLAINTEXT,BOLDON
			b "IP:  "
			b PLAINTEXT,NULL

::txNET			b PLAINTEXT,BOLDON
			b "NET: "
			b PLAINTEXT,NULL

::txGW			b PLAINTEXT,BOLDON
			b "GW: "
			b PLAINTEXT,NULL
