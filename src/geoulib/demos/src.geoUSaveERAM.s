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

			n "geoUSaveERAM"
			c "geoUSaveERAMV0.1"
			a "Markus Kanet"

if BUILD_DEBUG = TRUE
			h "/Usb0/ULIB/geos.reu"
else
			h "/root/dir/file"
endif

			h "Speichert Inhalt von C=REU oder GeoRAM als Datei..."

			o APP_RAM
			p MAININIT

			f APPLICATION
			z $40 ;GEOS 40/80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execSaveERAM

;--- geoULib einbinden.
;Systemroutinen:
			t "ulib.C.SymbTab"		;Erweiterte Symboltabelle.
			t "ulib.C.Core"			;UCI-Systemroutinen.

;Optionale Routinen:
			t "ulib._ClkRate128"		;Nur C128: Auf 1/2 MHz umschalten.
			t "ulib._ErrUDev"		;Fehler "Kein Ultimate" ausgeben.
			t "ulib._GetStatus"		;UCI-Statusregister abfragen.
			t "ulib._GetData"		;Daten über UCI einlesen.
			t "ulib._AccData"		;Datenempfang bestätigen.
			t "ulib._Push_DWORD"		;DWORD an UCI senden.
			t "ulib._Push_NAME6"		;Dateiname/Pfad in r6 an UCI senden.
			t "ulib._DetectCREU"		;C=REU erkennen.
			t "ulib._SizeCREU"		;Größe C=REU ermitteln.
			t "ulib._DetectGRAM"		;GeoRAM erkennen.
			t "ulib._SizeGRAM"		;Größe GeoRAM ermitteln.
			t "ulib._SplitPath"		;/Pfad/Dateiname aufteilen.

;DOS-Routinen:
			t "_dos.00.Target"		;DOS-Target 1/2 setzen.
			t "_dos.02.FOpen"		;Datei öffnen.
			t "_dos.03.FClose"		;Datei schießen.
			t "_dos.11.ChDir"		;Verzeichnis wechseln.
			t "_dos.22.SaveREU"		;Daten aus REU speichern.

;Erweiterte Programmroutinen:
			t "inc.Conf.FName"		;Dateiname mit/ohne Pfad.

;*** Inhalt C=REU/GeoRAM als Dateie speichern.
:execSaveERAM		jsr	ULIB_TEST_UDEV		;Ultimate testen.
;			txa				;Gerät vorhanden?
			beq	:ok			; => Ja, weiter...

;--- Kein Ultimate, Fehler, Ende...
			jsr	ULIB_ERR_NO_UDEV
			jmp	exitDeskTop		; => Ende...

;--- Ultimate vorhanden.
::ok			jsr	getFileName		;Konfiguration einlesen.

			lda	uFileName		;Pfad vorhanden?
			beq	exitDeskTop		; => Nein, Ende...

			jsr	uSaveERAM		;C=REU/GEORAM als Datei speichern.
			txa				;Fehler?
			beq	:status			; => Nein, weiter...

			lda	#NULL			;Transferstatus löschen und
			sta	UCI_DATA_MSG		;Statusbox anzeigen.

::status		lda	#< dBoxStatus
			sta	r0L
			lda	#> dBoxStatus
			sta	r0H
			jsr	DoDlgBox		;Status anzeigen.

;*** Zurück zu GEOS.
:exitDeskTop		jmp	EnterDeskTop		;Ende.

;*** Inhalt C=REU/GeoRAM als Dateie speichern.
;Übergabe : uFileName = (Verzeichnispfad/)Dateiname
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;           UCI_DATA_MSG   = Transferstatus
;Verändert: A,X,Y,r0 bis r3L,r4,r5,r6,r7L,r9

:uSaveERAM		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			jsr	ULIB_TEST_CREU		;C=REU vorhanden?
			txa
			bne	:1			; => Nein, weiter...

			jsr	ULIB_SIZE_CREU		;Größe C=REU ermitteln.
			tya				;Fehler?
			beq	:err			; => Ja, Abbruch...
			bne	:save			; => Speichern...

::1			jsr	ULIB_TEST_GRAM		;GeoRAM vorhanden?
			txa
			bne	:err			; => Nein, weiter...

			jsr	ULIB_SIZE_GRAM		;Größe GeoRAM ermitteln.
			tya				;Fehler?
			beq	:err			; => Ja, Abbruch...

::save			jsr	_UCID_SET_TARGET1	;Target DOS1 verwenden.

			lda	#< UCI_DATA_MSG		;Zwischenspeicher für Pfad.
			sta	r6L
			lda	#> UCI_DATA_MSG
			sta	r6H
			lda	#< uFileName		;Zeiger auf /Pfad/Dateiname.
			sta	r9L
			lda	#> uFileName
			sta	r9H
			jsr	ULIB_SPLIT_PATH		;Pfad+Dateiname aufteilen.
			txa				;Pfad vorhanden?
			beq	:skipcd			; => Nein, weiter...

;			lda	#< UCI_DATA_MSG		;Verzeichnis wechseln.
;			sta	r6L
;			lda	#> UCI_DATA_MSG
;			sta	r6H
			jsr	_UCID_CHANGE_DIR
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

::skipcd		lda	r9L			;Zeiger auf Dateiname ohne Pfad.
			sta	r6L
			lda	r9H
			sta	r6H

;			lda	#< uFileName		;Neue/Leere Datei erstellen.
;			sta	r6L
;			lda	#> uFileName
;			sta	r6H
			jsr	_UCID_OPEN_FILE_OVERWRITE
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

;--- Hinweis:
;Die Größe für den Speicherbereich
;hat man bereits in r2/r3 durch die
;Routinen ULIB_SIZE_CREU/GRAM!
;			lda	#$00			;Startadresse $0000:0000.
			sta	r0L
			sta	r0H
			sta	r1L
			sta	r1H

;--- Hinweis:
;Nur 16Mb: Teil#1 speichern
			lda	r3H			;16Mb speichern?
			beq	:rest			; => Nein, weiter...

			ldx	#1			;Anzahl Bytes $0000:0001.
			stx	r2L
			dex
			stx	r2H
			stx	r3L
			stx	r3H

;--- Hinweis:
;Auf Grund eines Fehlers im UCI der
;Firmware bis V3.10f kann eine 16Mb
;REU oder GeoRAM nicht komplett auf
;USB gespeichert werden, max. können
;$FF:FFFF Bytes gespeichert werden.
;Workaround: Zuerst Byte#0 speichern,
;dann den Rest.

;			lda	#NULL			;Rückmeldung initialisieren.
			sta	UCI_DATA_MSG		; => Kein Transferstatus.

			jsr	_UCID_SAVE_REU		;REU Teil#1 speichern.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			ldx	#$ff			;Anzahl Bytes $00FF:FFFF.
			stx	r2L
			stx	r2H
			stx	r3L
			inx
			stx	r3H

			inc	r0L			;Startadresse $0000:0001.

;--- Hinweis:
;Nur 16Mb: Teil#2 speichern
;1mb- 8Mb: REU komplett speichern
::rest
;			lda	#NULL			;Rückmeldung initialisieren.
			sta	UCI_DATA_MSG		; => Kein Transferstatus.

			jsr	_UCID_SAVE_REU		;REU Teil#2 speichern.
;			txa				;Fehler?
;			bne	:exit			; => Ja, Abbruch...

;			ldx	#NO_ERROR		;Kein Fehler.
::exit			jsr	_UCID_CLOSE_FILE	;Datei schließen.

::err			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;*** Dialogbox: Status anzeigen.
:dBoxStatus		b %00000001
			b $20,$7f
			w $0030,$010f

			b DBTXTSTR   ,$10,$10
			w :1

			b DBTXTSTR   ,$10,$20
			w :2

			b DBTXTSTR   ,$10,$30
			w uFileName

			b DBTXTSTR   ,$10,$3a
			w UCI_STATUS_MSG
			b DBTXTSTR   ,$10,$44
			w UCI_DATA_MSG

			b OK         ,$14,$48
			b NULL

::1			b PLAINTEXT,BOLDON
			b "INFORMATION:"
			b PLAINTEXT,NULL

::2			b "Save extended memory:"
			b NULL
