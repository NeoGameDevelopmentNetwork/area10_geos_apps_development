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

			n "geoUMakeDir"
			c "geoUMakeDir V0.1"
			a "Markus Kanet"

if BUILD_DEBUG = TRUE
			h "/Usb0/ULIB/testdir"
else
			h "/root/dir"
endif

			h "Verzeichnis erstellen..."

			o APP_RAM
			p MAININIT

			f APPLICATION
			z $40 ;GEOS 40/80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execCreateDir

;--- geoULib einbinden.
;Systemroutinen:
			t "ulib.C.SymbTab"		;Erweiterte Symboltabelle.
			t "ulib.C.Core"			;UCI-Systemroutinen.

;Optionale Routinen:
			t "ulib._ErrUDev"		;Fehler "Kein Ultimate" ausgeben.
			t "ulib._GetStatus"		;UCI-Statusregister abfragen.
			t "ulib._AccData"		;Datenempfang bestätigen.
			t "ulib._Push_NAME6"		;Dateiname/Pfad in r6 an UCI senden.

;DOS-Routinen:
			t "_dos.00.Target"		;DOS-Target 1/2 setzen.
			t "_dos.16.MakeDir"		;Verzeichnis erstellen.

;Allgemeine Programmroutinen:
			t "inc.Conf.PathDir"		;Verzeichnisname.

;*** Verzeichnis erstellen.
:execCreateDir		jsr	ULIB_TEST_UDEV		;Ultimate testen.
;			txa				;Gerät vorhanden?
			beq	:ok			; => Ja, weiter...

;--- Kein Ultimate, Fehler, Ende...
			jsr	ULIB_ERR_NO_UDEV
			jmp	exitDeskTop		; => Ende...

;--- Ultimate vorhanden.
::ok			jsr	getConfigDir		;Konfiguration einlesen.

			lda	uPathDir		;Pfad vorhanden?
			beq	exitDeskTop		; => Nein, Ende...

			jsr	uCreateDir		;Verzeichnis erstellen.

			lda	#< dBoxCreateDir
			sta	r0L
			lda	#> dBoxCreateDir
			sta	r0H
			jsr	DoDlgBox		;Status anzeigen.

;*** Zurück zu GEOS.
:exitDeskTop		jmp	EnterDeskTop		;Ende.

;*** Verzeichnis erstellen.
;Übergabe : uPathDir = Verzeichnisname
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r5,r6

:uCreateDir		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			jsr	_UCID_SET_TARGET1	;Target DOS1 verwenden.

			lda	#< uPathDir		;Verzeichnis erstellen.
			sta	r6L
			lda	#> uPathDir
			sta	r6H
			jsr	_UCID_CREATE_DIR

			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;*** Dialogbox: Status anzeigen.
:dBoxCreateDir		b %10000001

			b DBTXTSTR   ,$10,$10
			w :1

			b DBTXTSTR   ,$10,$20
			w :2

			b DBTXTSTR   ,$10,$30
			w uPathDir
			b DBTXTSTR   ,$10,$3a
			w UCI_STATUS_MSG

			b OK         ,$10,$48
			b NULL

::1			b PLAINTEXT,BOLDON
			b "INFORMATION:"
			b PLAINTEXT,NULL

::2			b "Create dir: ",NULL
