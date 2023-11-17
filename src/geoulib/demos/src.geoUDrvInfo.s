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

			n "geoUDrvInfo"
			c "geoUDrvInfo V0.1"
			a "Markus Kanet"

			h "IEC-Geräteinfo anzeigen..."

			o APP_RAM
			p MAININIT

			f APPLICATION

			z $40 ;GEOS 40/80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execGetDrvInfo

;--- geoULib einbinden.
;Systemroutinen:
			t "ulib.C.SymbTab"		;Erweiterte Symboltabelle.
			t "ulib.C.Core"			;UCI-Systemroutinen.

;Optionale Routinen:
			t "ulib._ErrUDev"		;Fehler "Kein Ultimate" ausgeben.
			t "ulib._GetStatus"		;UCI-Statusregister abfragen.
			t "ulib._GetData"		;Daten über UCI einlesen.
			t "ulib._AccData"		;Datenempfang bestätigen.

;CONTROL-Routinen:
			t "_ctl.29.DrvInfo"		;IEC-Geräteinfo abfragen.

;*** IEC-Geräteinfo anzeigen.
:execGetDrvInfo		jsr	ULIB_TEST_UDEV		;Ultimate testen.
;			txa				;Gerät vorhanden?
			beq	:ok			; => Ja, weiter...

;--- Kein Ultimate, Fehler, Ende...
			jsr	ULIB_ERR_NO_UDEV
			jmp	exitDeskTop		; => Ende...

;--- Ultimate vorhanden.
::ok			jsr	uGetDrvInfo		;IEC-Geräteinfo abfragen.

			lda	#< dBoxStatus
			sta	r0L
			lda	#> dBoxStatus
			sta	r0H
			jsr	DoDlgBox		;Status ausgeben.

;*** Zurück zu GEOS.
:exitDeskTop		jmp	EnterDeskTop		;Ende.

;*** IEC-Geräteinfo anzeigen.
;Übergabe: -
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;           UCI_DATA_MSG   = IEC-Geräteinfo
;Verändert: A,X,Y,r4,r5

:uGetDrvInfo		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			ldy	#0
			lda	#NULL			;Rückmeldung initialisieren.
::1			sta	UCI_DATA_MSG,y		; => Keine Informationen.
			iny
			cpy	#1+3+3+3+3
			bcc	:1

			jsr	_UCIC_GET_DRVINFO
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

;			ldx	#NO_ERROR		;Kein Fehler.
:err			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;*** Anzahl IEC-Geräte ausgeben.
:prntNumDrv		lda	UCI_DATA_MSG +0		;Anzahl IEC-Geräte.
			clc
			jsr	prntHexByte
			rts

;*** Geräteinfo ausgeben.
:prntDevInfo1		ldy	#1
			b $2c
:prntDevInfo2		ldy	#4
			b $2c
:prntDevInfo3		ldy	#7
			b $2c
:prntDevInfo4		ldy	#10
			ldx	#0
::1			lda	UCI_DATA_MSG,y
			sta	r14,x
			iny
			inx
			cpx	#3
			bcc	:1

			lda	r14L			;Laufwerkstyp.
			sec
			jsr	prntHexByte

			lda	r14H			;IEC-ID/Geräteadresse.
			sec
			jsr	prntHexByte

			lda	r15L			;Laufwerkstatus (DrvPower)
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
			cmp	#"9" +1			;Zahl größer 10?
			bcc	:2			;Ja, weiter...
			clc				;Hex-Zeichen nach $A-$F wandeln.
			adc	#$07
::2			rts

;*** Dialogbox: Status anzeigen.
:dBoxStatus		b %00000001
			b $20,$8f
			w $0040,$00ff

			b DBTXTSTR   ,$10,$10
			w :1

			b DBTXTSTR   ,$10,$20
			w UCI_STATUS_MSG

			b DBTXTSTR   ,$10,$2c
			w :txDrvCount
			b DB_USR_ROUT
			w prntNumDrv

			b DBTXTSTR   ,$10,$36
			w :txDrv1
			b DB_USR_ROUT
			w prntDevInfo1

			b DBTXTSTR   ,$10,$40
			w :txDrv2
			b DB_USR_ROUT
			w prntDevInfo2

			b DBTXTSTR   ,$10,$4a
			w :txIECDrv
			b DB_USR_ROUT
			w prntDevInfo3

			b DBTXTSTR   ,$10,$54
			w :txPrnt
			b DB_USR_ROUT
			w prntDevInfo4

			b OK         ,$10,$58
			b NULL

::1			b PLAINTEXT,BOLDON
			b "INFORMATION:"
			b PLAINTEXT,NULL

::txDrvCount		b PLAINTEXT,BOLDON
			b "Geräte: "
			b PLAINTEXT,NULL

::txDrv1		b PLAINTEXT,BOLDON
			b "Laufwerk A:  "
			b PLAINTEXT,NULL

::txDrv2		b PLAINTEXT,BOLDON
			b "Laufwerk B:  "
			b PLAINTEXT,NULL

::txIECDrv		b PLAINTEXT,BOLDON
			b "IEC-Laufwerk: "
			b PLAINTEXT,NULL

::txPrnt		b PLAINTEXT,BOLDON
			b "IEC-Drucker:  "
			b PLAINTEXT,NULL
