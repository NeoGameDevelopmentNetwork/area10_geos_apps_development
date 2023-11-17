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

			n "geoUFileInfo"
			c "geoUFileInfoV0.1"
			a "Markus Kanet"

if BUILD_DEBUG = TRUE
			h "/Usb0/ULIB/test.d64"
else
			h "/root/dir/disk.ext"
endif

			h "Datei-Informationen anzeigen..."

			o APP_RAM
			p MAININIT

			f APPLICATION

			z $40 ;GEOS 40/80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execFileInfo

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
			t "ulib._SplitPath"		;/Pfad/Dateiname aufteilen.
			t "ulib._FileInfo"		;Datei-Informationen konvertieren.

;DOS-Routinen:
			t "_dos.00.Target"		;DOS-Target 1/2 setzen.
			t "_dos.02.FOpen"		;Datei öffnen.
			t "_dos.03.FClose"		;Datei schießen.
			t "_dos.07.FileInfo"		;Datei-Informationen einlesen.
			t "_dos.11.ChDir"		;Verzeichnis wechseln.

;Erweiterte Programmroutinen:
			t "inc.Conf.FName"		;Dateiname mit/ohne Pfad.
			t "inc.PrntFileInfo"		;Datei-Informationen anzeigen.

;*** Datei-Informationen anzeigen.
:execFileInfo		jsr	ULIB_TEST_UDEV		;Ultimate testen.
;			txa				;Gerät vorhanden?
			beq	:ok			; => Ja, weiter...

;--- Kein Ultimate, Fehler, Ende...
			jsr	ULIB_ERR_NO_UDEV
			jmp	exitDeskTop		; => Ende...

;--- Ultimate vorhanden.
::ok			jsr	getFileName		;Konfiguration einlesen.

			lda	uFileName		;Pfad vorhanden?
			beq	exitDeskTop		; => Nein, Ende...

			jsr	uGetFileInfo		;Datei-Informationen einlesen.

			lda	r9L
			sta	vec2FName +0
			lda	r9H
			sta	vec2FName +1

			lda	#< dBoxFileInfo
			sta	r0L
			lda	#> dBoxFileInfo
			sta	r0H
			jsr	DoDlgBox		;Status anzeigen.

;*** Zurück zu GEOS.
:exitDeskTop		jmp	EnterDeskTop		;Ende.

;*** Datei-Informationen einlesen.
;Übergabe : uFileName = (Verzeichnispfad/)Dateiname
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;           UCI_DATA_MSG   = Datei-Informationen
;           r6 = Zeiger auf Dateiname innerhalb uFileName
;Verändert: A,X,Y,r4,r5,r6,r9

:uGetFileInfo		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			jsr	_UCID_SET_TARGET1	;Target DOS1 verwenden.

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

;			lda	#< uFileName		;Datei zum lesen öffnen.
;			sta	r6L
;			lda	#> uFileName
;			sta	r6H
			jsr	_UCID_OPEN_FILE_READ
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			jsr	_UCID_FILE_INFO		;Datei-Informationen einlesen.

			jsr	_UCID_CLOSE_FILE	;Datei schliesen.

::err			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;*** Zeiger auf Dateiname.
:vec2FName		w $0000

;*** Dialogbox: Datei-Informationen anzeigen.
:dBoxFileInfo		b %10000001

			b DBTXTSTR,$10,$10
			w :info
			b DB_USR_ROUT
			w prntStatus

			b DBTXTSTR,$10,$1a
			w uFileName

			b DBTXTSTR,$10,$25
			w :10
			b DB_USR_ROUT
			w prntFName

			b DBTXTSTR,$10,$2e
			w :11
			b DB_USR_ROUT
			w prntSize

			b DBTXTSTR,$10,$37
			w :12
			b DB_USR_ROUT
			w prntDate

			b DBTXTSTR,$10,$40
			w :13
			b DB_USR_ROUT
			w prntTime

			b DBTXTSTR,$10,$49
			w :14
			b DB_USR_ROUT
			w prntExt

			b DBTXTSTR,$10,$52
			w :15
			b DB_USR_ROUT
			w prntAttr

			b OK         ,$10,$48
			b NULL

::info			b PLAINTEXT,BOLDON
			b "INFO: "
			b PLAINTEXT,NULL

::10			b "Name: ",NULL
::11			b "Größe: ",NULL
::12			b "Datum: ",NULL
::13			b "Zeit: ",NULL
::14			b "Ext: ",NULL
::15			b "Typ: ",NULL
