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

			n "geoUGetMAC"
			c "geoUGetMAC  V0.1"
			a "Markus Kanet"

			h "Hardware-Adresse (MAC) anzeigen..."

			o APP_RAM
			p MAININIT

			f APPLICATION

			z $40 ;GEOS 40/80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execGetMAC

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
			t "_net.04.GetMAC"		;Hardware-Adresse abfragen.

;*** Hardware-Adresse anzeigen.
:execGetMAC		jsr	ULIB_TEST_UDEV		;Ultimate testen.
;			txa				;Gerät vorhanden?
			beq	:ok			; => Ja, weiter...

;--- Kein Ultimate, Fehler, Ende...
			jsr	ULIB_ERR_NO_UDEV
			jmp	exitDeskTop		; => Ende...

;--- Ultimate vorhanden.
::ok			jsr	uGetMAC			;Netzwerk-Adresse abfragen.

			lda	#< dBoxStatus
			sta	r0L
			lda	#> dBoxStatus
			sta	r0H
			jsr	DoDlgBox		;Status ausgeben.

;*** Zurück zu GEOS.
:exitDeskTop		jmp	EnterDeskTop		;Ende.

;*** Hardware-Adresse anzeigen.
;Übergabe: -
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;           UCI_DATA_MSG   = Netzwerk-Informationen
;Verändert: A,X,Y,r4,r5

:uGetMAC		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			ldx	#0
			lda	#$ff			;Rückmeldung initialisieren.
::1			sta	UCI_DATA_MSG,x		; => Keine Informationen.
			inx
			cpx	#6
			bcc	:1

			jsr	_UCIN_GETMAC
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

;			ldx	#NO_ERROR		;Kein Fehler.
:err			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;*** Rückmeldung ausgeben.
:prntMAC		lda	UCI_DATA_MSG +0		;MAC #1.
			sec
			jsr	prntHexByte

			lda	UCI_DATA_MSG +1		;MAC #2.
			sec
			jsr	prntHexByte

			lda	UCI_DATA_MSG +2		;MAC #3.
			sec
			jsr	prntHexByte

			lda	UCI_DATA_MSG +3		;MAC #4.
			sec
			jsr	prntHexByte

			lda	UCI_DATA_MSG +4		;MAC #5.
			sec
			jsr	prntHexByte

			lda	UCI_DATA_MSG +5		;MAC #6.
			clc
			jsr	prntHexByte

			rts

;*** HEX-Zahl als ASCII-Text ausgeben.
;Übergabe: AKKU   = Hex-Zahl.
;          C-Flag = 0: Kein Trennzeichen ausgeben.
;                   1: Trennzeichen ausgeben.
:prntHexByte		php

			jsr	HEX2ASCII		;Byte nach ASCII wandeln.

			pha				;Byte als ASCII-Text ausgeben.
			txa
			jsr	SmallPutChar
			pla
			jsr	SmallPutChar

			plp				;Trennzeichen ausgeben?
			bcc	:1			; => Nein, Ende...

			lda	#":"			;Trennzeichen...
			jsr	SmallPutChar

::1			rts

;*** HEX-Zahl nach ASCII wandeln.
;Übergabe: AKKU   = Hex-Zahl.
;Rückgabe: AKKU/XREG = LOW/HIGH-Nibble Hex-Zahl.
:HEX2ASCII		pha				;HEX-Wert speichern.
			lsr				;HIGH-Nibble isolieren.
			lsr
			lsr
			lsr
			jsr	:1			;HIGH-Nibble nach ASCII wandeln.
			tax				;Ergebnis zwischenspeichern.

			pla				;HEX-Wert zurücksetzen und
							;nach ASCII wandeln.
::1			and	#%00001111
			clc
			adc	#"0"
			cmp	#$3a			;Zahl größer 10?
			bcc	:2			;Ja, weiter...
			clc				;Hex-Zeichen nach $A-$F wandeln.
			adc	#$07
::2			rts

;*** Dialogbox: Status anzeigen.
:dBoxStatus		b %10000001

			b DBTXTSTR   ,$10,$10
			w :1

			b DBTXTSTR   ,$10,$20
			w UCI_STATUS_MSG

			b DBTXTSTR   ,$10,$30
			w :text
			b DB_USR_ROUT
			w prntMAC

			b OK         ,$10,$48
			b NULL

::1			b PLAINTEXT,BOLDON
			b "INFORMATION:"
			b PLAINTEXT,NULL

::text			b PLAINTEXT,BOLDON
			b "MAC:  "
			b PLAINTEXT,NULL
