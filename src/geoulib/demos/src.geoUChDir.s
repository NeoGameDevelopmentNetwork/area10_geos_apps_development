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

			n "geoUChDir"
			c "geoUChDir   V0.1"
			a "Markus Kanet"

if BUILD_DEBUG = TRUE
			h "/Usb0/ULIB"
else
			h "/root/dir"
endif

			h "Ultimate-Verzeichnis wechseln..."

			o APP_RAM
			p MAININIT

			f APPLICATION
			z $40 ;GEOS 40/80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execChangeDir

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

;DOS-Routinen:
			t "_dos.00.Target"		;DOS-Target 1/2 setzen.
			t "_dos.11.ChDir"		;Verzeichnis wechseln.
			t "_dos.12.GetPath"		;Aktuelles Verzeichnis einlesen.

;Allgemeine Programmroutinen:
			t "inc.Conf.PathDir"		;Verzeichnisname.
			t "inc.DBChDirData"		;Status-Dialogbox für CD-Befehle.

;*** Verzeichnis wechseln.
:execChangeDir		jsr	ULIB_TEST_UDEV		;Ultimate testen.
;			txa				;Gerät vorhanden?
			beq	:ok			; => Ja, weiter...

;--- Kein Ultimate, Fehler, Ende...
			jsr	ULIB_ERR_NO_UDEV
			jmp	exitDeskTop		; => Ende...

;--- Ultimate vorhanden.
::ok			jsr	getConfigDir		;Konfiguration einlesen.

			lda	uPathDir		;Pfad vorhanden?
			beq	exitDeskTop		; => Nein, Ende...

			lda	#< dBoxChangeDir
			sta	r0L
			lda	#> dBoxChangeDir
			sta	r0H
			jsr	DoDlgBox		;Status anzeigen.

;*** Zurück zu GEOS.
:exitDeskTop		jmp	EnterDeskTop		;Ende.

;*** Verzeichnis wechseln.
;Übergabe : -
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r5,r6

:uChangeDir		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			jsr	_UCID_SET_TARGET1	;Target DOS1 verwenden.

			lda	#< uPathDir		;Verzeichnis wechseln.
			sta	r6L
			lda	#> uPathDir
			sta	r6H
			jsr	_UCID_CHANGE_DIR

			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;*** Aktuellen Verzeichnispfad einlesen.
;Übergabe: -
;Rückgabe: X = Fehlerstatus, $00=OK
;          UCI_STATUS_MSG = Status-Meldung
;          UCI_DATA_MSG   = Verzeichnispfad
;Verändert: A,X,Y,r4,r5,r6

:uGetPath		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			jsr	_UCID_SET_TARGET1	;Target DOS1 verwenden.
			jsr	_UCID_GET_PATH		;Verzeichnispfad einlesen.

			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.
