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

			n "geoUDWrite8"
			c "geoUDWrite8 V0.1"
			a "Markus Kanet"

if BUILD_DEBUG = TRUE
			h "/Usb0/ULIB/testfile"
else
			h "/root/dir/filename"
endif

			h "Daten in Datei schreiben..."
			h "Transfergröße 508 Bytes."

			o APP_RAM
			p MAININIT

			f APPLICATION
			z $00 ;GEOS 40-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execFileWrite

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

;DOS-Routinen:
			t "_dos.00.Target"		;DOS-Target 1/2 setzen.
			t "_dos.02.FOpen"		;Datei öffnen.
			t "_dos.03.FClose"		;Datei schießen.
;			t "_dos.05.DWrite2"		;Paketgröße 256B, OK
;			t "_dos.05.DWrite5"		;Paketgröße 512B, Fehler Firmw. v3.6
			t "_dos.05.DWrite8"		;Paketgröße 508B, OK
			t "_dos.11.ChDir"		;Verzeichnis wechseln.

;Erweiterte Programmroutinen:
			t "inc.Conf.FName"		;Dateiname mit/ohne Pfad.

;*** Daten in Datei schreiben.
:execFileWrite		jsr	ULIB_TEST_UDEV		;Ultimate testen.
;			txa				;Gerät vorhanden?
			beq	:ok			; => Ja, weiter...

;--- Kein Ultimate, Fehler, Ende...
			jsr	ULIB_ERR_NO_UDEV
			jmp	exitDeskTop		; => Ende...

;--- Ultimate vorhanden.
::ok			jsr	getFileName		;Konfiguration einlesen.

			lda	uFileName		;Pfad vorhanden?
			beq	exitDeskTop		; => Nein, Ende...

			lda	#22			;Testmuster zeichen.
			jsr	SetPattern
			jsr	i_Rectangle
			b	0,199
			w	0,319

			jsr	uFileWrite		;Daten in Datei schreiben.

			lda	#< dBoxStatus
			sta	r0L
			lda	#> dBoxStatus
			sta	r0H
			jsr	DoDlgBox		;Status anzeigen.

;*** Zurück zu GEOS.
:exitDeskTop		jmp	EnterDeskTop		;Ende.

;*** Daten in Datei schreiben.
;Übergabe : uFileName = (Verzeichnispfad)Dateiname
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;           UCI_DATA_MSG   = Verzeichnispfad (falls vorhanden, sonst NULL)
;           r6 = Zeiger auf Dateiname innerhalb uFileName
;Verändert: A,X,Y,r0,r1L,r4,r5,r6,r9

:uFileWrite		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
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

;			lda	#< uFileName		;Datei zum schreiben öffnen.
;			sta	r6L
;			lda	#> uFileName
;			sta	r6H
			jsr	_UCID_OPEN_FILE_OVERWRITE
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			lda	#< 8000			;8000 Byte ab SCREEN_BASE
			sta	r0L			;in Datei schreiben.
			lda	#> 8000
			sta	r0H
			lda	#< SCREEN_BASE
			sta	r4L
			lda	#> SCREEN_BASE
			sta	r4H

			jsr	_UCID_WRITE_DATA	;Daten in Datei schreiben.
;			txa				;Fehler?
;			bne	:done			; => Ja, Abbruch...

::done			jsr	_UCID_CLOSE_FILE	;Datei schliesen.

::err			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;*** Dialogbox: Status anzeigen.
:dBoxStatus		b %10000001

			b DBTXTSTR   ,$10,$10
			w :info

			b DBTXTSTR   ,$10,$20
			w uFileName

			b DBTXTSTR   ,$10,$2a
			w UCI_STATUS_MSG

			b OK         ,$10,$48
			b NULL

::info			b PLAINTEXT,BOLDON
			b "INFORMATION:"
			b PLAINTEXT,NULL
