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

			n "geoUPathUsb0"
			c "geoUPathUsb0V0.2"
			a "Markus Kanet"

			h "Ultimate-Verzeichnis /Usb0 setzen..."

			o APP_RAM
			p MAININIT

			f APPLICATION
			z $40 ;GEOS 40/80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execPathUsb0

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
			t "inc.DBChDirData"		;Status-Dialogbox für CD-Befehle.

;*** In Verzeichnis /Usb0 wechseln.
:execPathUsb0		jsr	ULIB_TEST_UDEV		;Ultimate testen.
;			txa				;Gerät vorhanden?
			beq	:ok			; => Ja, weiter...

;--- Kein Ultimate, Fehler, Ende...
			jsr	ULIB_ERR_NO_UDEV
			jmp	exitDeskTop		; => Ende...

;--- Ultimate vorhanden.
::ok			lda	#< dBoxChangeDir
			sta	r0L
			lda	#> dBoxChangeDir
			sta	r0H
			jsr	DoDlgBox		;Status anzeigen.

;*** Zurück zu GEOS.
:exitDeskTop		jmp	EnterDeskTop		;Ende.

;*** In Verzeichnis /Usb0 wechseln.
;Übergabe : -
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r5,r6

:uChangeDir		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			jsr	_UCID_SET_TARGET1	;Target DOS1 verwenden.
			jsr	_UCID_CD_USB0		;In Verzeichnis /Usb0 wechseln.
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

;			ldx	#NO_ERROR		;Kein Fehler.
::err			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;--- Text für Dialogbox.
:uPathDir		b "/Usb0",NULL

;*** Aktuellen Verzeichnispfad einlesen.
;Übergabe : -
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;           UCI_DATA_MSG   = Verzeichnispfad
;Verändert: A,X,Y,r4,r5,r6

:uGetPath		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			lda	#NULL			;Rückmeldung initialisieren.
			sta	UCI_DATA_MSG		; => Kein Verzeichnispfad.
			jsr	_UCID_SET_TARGET1	;Target DOS1 verwenden.
			jsr	_UCID_GET_PATH		;Verzeichnispfad einlesen.
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

;			ldx	#NO_ERROR		;Kein Fehler.
::err			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.
