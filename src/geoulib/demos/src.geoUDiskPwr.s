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

			n "geoUDiskPwr"
			c "geoUDiskPwr V0.1"
			a "Markus Kanet"

			h "Laufwerkstatus anzeigen..."

			o APP_RAM
			p MAININIT

			f APPLICATION

			z $40 ;GEOS 40/80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execDiskPower

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
			t "_ctl.34.DiskPwrA"		;Status Laufwerk A abfragen.
			t "_ctl.35.DiskPwrB"		;Status Laufwerk B abfragen.

;*** Laufwerkstatus anzeigen.
:execDiskPower		jsr	ULIB_TEST_UDEV		;Ultimate testen.
;			txa				;Gerät vorhanden?
			beq	:ok			; => Ja, weiter...

;--- Kein Ultimate, Fehler, Ende...
			jsr	ULIB_ERR_NO_UDEV
			jmp	exitDeskTop		; => Ende...

;--- Ultimate vorhanden.
::ok			lda	#< dBoxStatus
			sta	r0L
			lda	#> dBoxStatus
			sta	r0H
			jsr	DoDlgBox		;Status ausgeben.

;*** Zurück zu GEOS.
:exitDeskTop		jmp	EnterDeskTop		;Ende.

;*** Status Laufwerk A abfragen.
;Übergabe: -
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;           UCI_DATA_MSG   = Laufwerkstatus
;Verändert: A,X,Y,r4,r5

:uDiskPowerA		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			lda	#NULL			;Rückmeldung initialisieren.
			sta	UCI_DATA_MSG		; => Kein Laufwerksstatus.
			jsr	_UCIC_DISK_A_POWER
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

;			ldx	#NO_ERROR		;Kein Fehler.
:err			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;*** Status Laufwerk B abfragen.
;Übergabe: -
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;           UCI_DATA_MSG   = Laufwerkstatus
;Verändert: A,X,Y,r4,r5

:uDiskPowerB		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			lda	#NULL			;Rückmeldung initialisieren.
			sta	UCI_DATA_MSG		; => Kein Laufwerksstatus.
			jsr	_UCIC_DISK_B_POWER
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

;			ldx	#NO_ERROR		;Kein Fehler.
::err			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;*** Dialogbox: Status anzeigen.
:dBoxStatus		b %10000001

			b DBTXTSTR   ,$10,$10
			w :1

			b DB_USR_ROUT
			w uDiskPowerA

			b DBTXTSTR   ,$10,$20
			w :A
			b DBTXTSTR   ,$1a,$20
			w UCI_DATA_MSG
			b DBTXTSTR   ,$10,$2a
			w UCI_STATUS_MSG

			b DB_USR_ROUT
			w uDiskPowerB

			b DBTXTSTR   ,$10,$36
			w :B
			b DBTXTSTR   ,$1a,$36
			w UCI_DATA_MSG
			b DBTXTSTR   ,$10,$40
			w UCI_STATUS_MSG

			b OK         ,$10,$48
			b NULL

::1			b PLAINTEXT,BOLDON
			b "INFORMATION:"
			b PLAINTEXT,NULL

::A			b "A:",NULL
::B			b "B:",NULL
