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

			n "geoUGetHWInf"
			c "geoUGetHWInfV0.1"
			a "Markus Kanet"

			h "Ultimate-Gerätetyp anzeigen..."

			o APP_RAM
			p MAININIT

			f APPLICATION
			z $40 ;GEOS 40/80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execGetHWInfo

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
			t "_ctl.28.GetHWInfo"		;Hardware-Information abfragen.

;Allgemeine Programmroutinen:
			t "inc.DBStatusData"		;Status-Dialogbox.

;*** Ultimate-Gerätetyp anzeigen.
:execGetHWInfo		jsr	ULIB_TEST_UDEV		;Ultimate testen.
;			txa				;Gerät vorhanden?
			beq	:ok			; => Ja, weiter...

;--- Kein Ultimate, Fehler, Ende...
			jsr	ULIB_ERR_NO_UDEV
			jmp	exitDeskTop		; => Ende...

;--- Ultimate vorhanden.
::ok			jsr	uGetHWInfo		;Geräteinfo einlesen.

			lda	#< dBoxStatus
			sta	r0L
			lda	#> dBoxStatus
			sta	r0H
			jsr	DoDlgBox		;Status anzeigen.

;*** Zurück zu GEOS.
:exitDeskTop		jmp	EnterDeskTop		;Ende.

;*** Geräteinfo einlesen.
;Übergabe : -
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;           UCI_DATA_MSG   = Geräte-Informationen
;Verändert: A,X,Y,r4,r5

:uGetHWInfo		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

;--- SID-Informationen.
;Inhalt der Rückmeldung noch unklar.
;Kann bei Bedarf aus dem SourceCode
;zur Firmware entnommen werden.
;			jsr	_UCIC_GET_HWINFO_SID

;--- Ultimate-Gerätetyp.
			lda	#NULL			;Rückmeldung initialisieren.
			sta	UCI_DATA_MSG		; => Keine Geräte-Information.
			jsr	_UCIC_GET_HWINFO_DEV
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

;			ldx	#NO_ERROR		;Kein Fehler.
::err			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.
