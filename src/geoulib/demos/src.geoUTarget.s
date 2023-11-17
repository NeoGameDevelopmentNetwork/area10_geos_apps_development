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

			n "geoUTarget"
			c "geoUTarget  V0.1"
			a "Markus Kanet"

			h "Ultimate-Target-Version anzeigen..."

			o APP_RAM
			p MAININIT

			f APPLICATION

			z $40 ;GEOS 40/80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execTarget

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
			t "_dos.01.Identify"		;Version DOS-Target abfragen.

;CONTROL-Routinen:
			t "_ctl.01.Identify"		;Version CONTROL-Target abfragen.

;NETWORK-Routinen:
			t "_net.01.Identify"		;Version NETWORK-Target abfragen.

;*** Ultimate-Target-Version anzeigen.
:execTarget		jsr	ULIB_TEST_UDEV		;Ultimate testen.
;			txa				;Gerät vorhanden?
			beq	:ok			; => Ja, weiter...

;--- Kein Ultimate, Fehler, Ende...
			jsr	ULIB_ERR_NO_UDEV
			jmp	exitDeskTop		; => Ende...

;--- Ultimate vorhanden.
::ok			lda	#< dBoxTarget
			sta	r0L
			lda	#> dBoxTarget
			sta	r0H
			jsr	DoDlgBox		;Status anzeigen.

;*** Zurück zu GEOS.
:exitDeskTop		jmp	EnterDeskTop		;Ende.

;*** DOS-Version abfragen.
;Übergabe : -
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;           UCI_DATA_MSG   = Target-Version
;Verändert: A,X,Y,r4,r5

:uTargetDOS		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			lda	#NULL			;Rückmeldung initialisieren.
			sta	UCI_DATA_MSG		; => Keine Target-Version.
			jsr	_UCID_SET_TARGET1	;Target DOS1 verwenden.
			jsr	_UCID_IDENTIFY		;Target-Version DOS abfragen.
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

;			ldx	#NO_ERROR		;Kein Fehler.
::err			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;*** CONTROL-Version abfragen.
;Übergabe : -
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;           UCI_DATA_MSG     = Target-Version
;Verändert: A,X,Y,r4,r5

:uTargetCTRL		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			lda	#NULL			;Rückmeldung initialisieren.
			sta	UCI_DATA_MSG		; => Keine Target-Version.
			jsr	_UCIC_IDENTIFY		;Target-Version CONTROL abfragen.
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

;			ldx	#NO_ERROR		;Kein Fehler.
::err			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;*** NETWORK-Version abfragen.
;Übergabe : -
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;           UCI_DATA_MSG     = Target-Version
;Verändert: A,X,Y,r4,r5

:uTargetNET		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			lda	#NULL			;Rückmeldung initialisieren.
			sta	UCI_DATA_MSG		; => Keine Target-Version.
			jsr	_UCIN_IDENTIFY		;Target-Version NETWORK abfragen.
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

;			ldx	#NO_ERROR		;Kein Fehler.
::err			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;*** Dialogbox: Target-Version anzeigen.
:dBoxTarget		b %00000001
			b $20,$8f
			w $0040,$00ff

			b DBTXTSTR   ,$10,$10
			w :1

			b DB_USR_ROUT
			w uTargetDOS

			b DBTXTSTR   ,$10,$20
			w UCI_DATA_MSG
			b DBTXTSTR   ,$10,$2a
			w UCI_STATUS_MSG

			b DB_USR_ROUT
			w uTargetCTRL

			b DBTXTSTR   ,$10,$36
			w UCI_DATA_MSG
			b DBTXTSTR   ,$10,$40
			w UCI_STATUS_MSG

			b DB_USR_ROUT
			w uTargetNET

			b DBTXTSTR   ,$10,$4c
			w UCI_DATA_MSG
			b DBTXTSTR   ,$10,$56
			w UCI_STATUS_MSG

			b OK         ,$10,$58
			b NULL

::1			b PLAINTEXT,BOLDON
			b "INFORMATION:"
			b PLAINTEXT,NULL
