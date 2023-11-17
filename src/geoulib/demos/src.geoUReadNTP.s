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

			n "geoUReadNTP"
			c "geoUReadNTP V0.1"
			a "Markus Kanet"

			h "pool.ntp.org:123"
			h "NTP-Daten über UDP einlesen..."

			o APP_RAM
			p MAININIT

			f APPLICATION
			z $40 ;GEOS 40/80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execReadNTP

;--- geoULib einbinden.
;Systemroutinen:
			t "ulib.C.SymbTab"		;Erweiterte Symboltabelle.
			t "ulib.C.Core"			;UCI-Systemroutinen.

;Optionale Routinen:
			t "ulib._ErrUDev"		;Fehler "Kein Ultimate" ausgeben.
			t "ulib._GetStatus"		;UCI-Statusregister abfragen.
			t "ulib._GetData"		;Daten über UCI einlesen.
			t "ulib._AccData"		;Datenempfang bestätigen.
			t "ulib._WaitLong"		;3sec. Pause (z.B. MOUNT).
			t "ulib._Push_NAME6"		;Dateiname/Pfad in r6 an UCI senden.

;NETWORK-Routinen:
			t "_net.08.OpenUDP"		;Verbindung über UDP öffnen.
			t "_net.09.Close"		;Verbindung beenden.
			t "_net.10.NRead"		;Daten über Netzwerk einlesen.
			t "_net.11.NWrite"		;Daten über Netzwerk senden.

;Erweiterte Programmroutinen:
			t "inc.Conf.Host"		;Host-/Port-Adresse einlesen.

;*** NTP-Daten über UDP einlesen.
:execReadNTP		jsr	ULIB_TEST_UDEV		;Ultimate testen.
;			txa				;Gerät vorhanden?
			beq	:ok			; => Ja, weiter...

;--- Kein Ultimate, Fehler, Ende...
			jsr	ULIB_ERR_NO_UDEV
			jmp	exitDeskTop		; => Ende...

;--- Ultimate vorhanden.
::ok			jsr	getConfHost		;Konfiguration einlesen.

			lda	uHost			;URL definiert?
			beq	exitDeskTop		; => Nein, Ende...

			lda	uPort +0
			ora	uPort +1		;Port definiert?
			beq	exitDeskTop		; => Nein, Ende...

			jsr	uReadNTP		;Verbindung öffnen.

			lda	#< dBoxStatus
			sta	r0L
			lda	#> dBoxStatus
			sta	r0H
			jsr	DoDlgBox		;Status anzeigen.

;*** Zurück zu GEOS.
:exitDeskTop		jmp	EnterDeskTop		;Ende.

;*** NTP-Daten über UDP einlesen.
;Übergabe : uHost = Host-URL
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;           UCI_DATA_MSG   = Socket-Adresse
;Verändert: A,X,Y,r5,r6,r7L,r7H

:uReadNTP		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			lda	#$00			;Rückmeldung initialisieren.
			sta	socketUDP		; => Keine Informationen.

			lda	#< uHost		;Host-Adresse.
			sta	r6L
			lda	#> uHost
			sta	r6H
			lda	uPort +0		;UDP-Port.
			sta	r7L
			lda	uPort +1
			sta	r7H
			jsr	_UCIN_OPENUDP
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			lda	UCI_DATA_MSG		;Socket/UDP zwischenspeichern.
			sta	socketUDP

;--- WRITE_SOCKET:
			lda	#< requestNTPlen	;Länge NTP-Request.
			sta	r0L
			lda	#> requestNTPlen
			sta	r0H
			lda	#< requestNTP		;NTP-Request-Befehl.
			sta	r4L
			lda	#> requestNTP
			sta	r4H
			lda	socketUDP		;Socket/UDP setzen.
			sta	r7L
			jsr	_UCIN_WRITE_SOCKET
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			lda	UCI_DATA_MSG +0		;Anzahl Datenbytes speichern.
			sta	writeData +0
			lda	UCI_DATA_MSG +1
			sta	writeData +1

;--- Fehlerkontrolle:
			ldy	#48 +2 -1		;Datenbereich mit $FF-Bytes
			lda	#$ff			;überschreiben.
::clr			sta	UCI_DATA_MSG,y
			dey
			bpl	:clr

;--- READ_SOCKET:
			lda	#< 48 +2		;NTP-Informationen einlesen.
			sta	r0L			;48 Datenbyte + 1 Word (Anzahl).
			lda	#> 48 +2
			sta	r0H
;			lda	socketUDP		;Socket/UDP setzen.
;			sta	r7L			; => Durch WRITE_SOCKET gesetzt.
			jsr	_UCIN_READ_SOCKET
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

;--- Debug:
			lda	#NET_RETRY		;Anzahl der benötigten
			sec				;Leseversuche ermitteln.
			sbc	r7H
			sta	countRetry

;--- UDP-Verbindung beenden.
::err			lda	socketUDP		;Socket/UDP setzen.
			sta	r7L
			jsr	_UCIN_CLOSE_SOCKET
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

;			ldx	#NO_ERROR		;Kein Fehler.
			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;*** Anzahl Datenbytes ausgeben.
:prntCount		lda	writeData +0
			sta	r0L
			lda	writeData +1
			sta	r0H

			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal

			lda	#" "
			jsr	SmallPutChar
			lda	#"/"
			jsr	SmallPutChar
			lda	#" "
			jsr	SmallPutChar

			lda	UCI_DATA_MSG +0
			sta	r0L
			lda	UCI_DATA_MSG +1
			sta	r0H

			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal

			lda	#" "
			jsr	SmallPutChar
			lda	#"("
			jsr	SmallPutChar

			lda	countRetry
			sta	r0L
			lda	#$00
			sta	r0H

			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal

			lda	#")"
			jmp	SmallPutChar

;*** NTP-Daten ausgeben.
:prntNTPData1		ldy	#2 +12*0
			b $2c
:prntNTPData2		ldy	#2 +12*1
			b $2c
:prntNTPData3		ldy	#2 +12*2
			b $2c
:prntNTPData4		ldy	#2 +12*3
			ldx	#0

			lda	#< $0020 +16 +32
			sta	r11L
			lda	#> $0020 +16 +32
			sta	r11H

::1			sty	r15L
			stx	r15H

			lda	r11H
			pha
			lda	r11L
			pha

			lda	UCI_DATA_MSG,y		;NTP-Daten einlesen und
			jsr	prntHexByte		;Als HEX-Zahl ausgeben.

			pla
			clc
			adc	#< 16
			sta	r11L
			pla
			adc	#> 16
			sta	r11H

			ldy	r15L			;Zeiger auf nächstes Datenbyte.
			iny

			ldx	r15H			;Zähler einlesen.
			inx
			cpx	#12			;Max. 12 Bytes ausgegeben?
			bcc	:1			; => Nein, weiter...

			rts

;*** Socket/UDP ausgeben.
:prntSocket		lda	#":"
			jsr	SmallPutChar

			lda	uPort +0
			sta	r0L
			lda	uPort +1
			sta	r0H

			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal

			lda	#","
			jsr	SmallPutChar
			lda	#"#"
			jsr	SmallPutChar

			lda	socketUDP
			sta	r0L
			lda	#$00
			sta	r0H

			lda	#SET_LEFTJUST!SET_SUPRESS
			jmp	PutDecimal

;*** HEX-Zahl als ASCII-Text ausgeben.
;Übergabe: AKKU   = Hex-Zahl.
;          C-Flag = 0: Kein Trennzeichen ausgeben.
;                   1: Trennzeichen ausgeben.
:prntHexByte		jsr	HEX2ASCII		;Byte nach ASCII wandeln.

			pha				;Byte als ASCII-Text ausgeben.
			txa
			jsr	SmallPutChar
			pla
			jsr	SmallPutChar

			lda	#" "			;Trennzeichen...
			jsr	SmallPutChar

			rts

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
			cmp	#"9" +1			;Zahl größer 10?
			bcc	:2			;Ja, weiter...
			clc				;Hex-Zeichen nach $A-$F wandeln.
			adc	#$07
::2			rts

;*** Socket/UDP.
:socketUDP		b $00

;*** Anzahl gesendeter Byte.
:writeData		w $0000

;*** Retry-Fehler.
:countRetry		b $00

;*** NTP-Request.
:requestNTP		b $1b
			s 47
:requestNTPend
:requestNTPlen		= (requestNTPend - requestNTP)

;*** Dialogbox: Status anzeigen.
:dBoxStatus		b %00000001
			b $20,$8f
			w $0020,$011f

			b DBTXTSTR   ,$10,$10
			w :1

			b DBTXTSTR   ,$10,$20
			w :txCount
			b DB_USR_ROUT
			w prntCount

			b DBTXTSTR   ,$10,$2a
			w :tx0
			b DB_USR_ROUT
			w prntNTPData1

			b DBTXTSTR   ,$10,$34
			w :tx1
			b DB_USR_ROUT
			w prntNTPData2

			b DBTXTSTR   ,$10,$3e
			w :tx2
			b DB_USR_ROUT
			w prntNTPData3

			b DBTXTSTR   ,$10,$48
			w :tx3
			b DB_USR_ROUT
			w prntNTPData4

			b DBTXTSTR   ,$10,$56
			w uHost
			b DB_USR_ROUT
			w prntSocket

			b DBTXTSTR   ,$10,$60
			w UCI_STATUS_MSG

			b OK         ,$18,$58
			b NULL

::1			b PLAINTEXT,BOLDON
			b "INFORMATION:"
			b PLAINTEXT,NULL

::txCount		b PLAINTEXT,BOLDON
			b "NTP-Daten: "
			b PLAINTEXT,NULL

::tx0			b "$00: ",NULL
::tx1			b "$0C: ",NULL
::tx2			b "$18: ",NULL
::tx3			b "$24: ",NULL
