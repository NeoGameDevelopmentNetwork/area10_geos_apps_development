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

			n "geoUCopyFile"
			c "geoUCopyFileV0.1"
			a "Markus Kanet"

if BUILD_DEBUG = TRUE
			h "test.d64,/Usb0/ULIB/testdir"
else
			h "filename,/root/dir"
endif

			h "Datei kopieren..."

			o APP_RAM
			p MAININIT

			f APPLICATION
			z $40 ;GEOS 40/80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execCopyFile

;--- geoULib einbinden.
;Systemroutinen:
			t "ulib.C.SymbTab"		;Erweiterte Symboltabelle.
			t "ulib.C.Core"			;UCI-Systemroutinen.

;Optionale Routinen:
			t "ulib._ErrUDev"		;Fehler "Kein Ultimate" ausgeben.
			t "ulib._GetStatus"		;UCI-Statusregister abfragen.
			t "ulib._AccData"		;Datenempfang bestätigen.
			t "ulib._Push_NAME6"		;Dateiname/Pfad in r6 an UCI senden.
			t "ulib._Push_NAME8"		;Dateiname/Pfad in r8 an UCI senden.

;DOS-Routinen:
			t "_dos.00.Target"		;DOS-Target 1/2 setzen.
			t "_dos.0B.CopyFile"		;Datei kopieren.
;			t "_dos.11.ChDir"		;Verzeichnis wechseln.

;*** Datei kopieren.
:execCopyFile		jsr	ULIB_TEST_UDEV		;Ultimate testen.
;			txa				;Gerät vorhanden?
			beq	:ok			; => Ja, weiter...

;--- Kein Ultimate, Fehler, Ende...
			jsr	ULIB_ERR_NO_UDEV
			jmp	exitDeskTop		; => Ende...

;--- Ultimate vorhanden.
::ok			jsr	getConfig		;Konfiguration einlesen.

			lda	uFileName		;Quelle/Ziel vorhanden?
			beq	exitDeskTop
			lda	uPathTarget
			beq	exitDeskTop		; => Nein, Ende...

			jsr	uCopyFile		;Datei kopieren.

			lda	#< dBoxCopy
			sta	r0L
			lda	#> dBoxCopy
			sta	r0H
			jsr	DoDlgBox		;Status anzeigen.

;*** Zurück zu GEOS.
:exitDeskTop		jmp	EnterDeskTop		;Ende.

;*** Datei kopieren.
;Übergabe : uFileName   = Dateiname Quelle
;           uPathTarget = Dateiname Ziel
;           uPathDir    = Verzeichnis für Datei (Optional)
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r5,r6,r8
;
;Quelle muss ein Dateiname im aktuellen
;Verzeichnis sein.
;Ziel muss ein anderes Verzeichnis ohne
;Angabe eines Dateinamen sein!

:uCopyFile		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			jsr	_UCID_SET_TARGET1	;Target DOS1 verwenden.

;			lda	#< uPathDir		;Ggf. Verzeichnis wechseln.
;			sta	r6L
;			lda	#> uPathDir
;			sta	r6H
;			jsr	_UCID_CHANGE_DIR
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

			lda	#< uFileName		;Zeiger auf Dateiname im
			sta	r6L			;aktuellen Verzeichnis!
			lda	#> uFileName
			sta	r6H
			lda	#< uPathTarget		;Zeiger auf Ziel-Verzeichnis ohne
			sta	r8L			;Angabe eines Dateinamen!
			lda	#> uPathTarget
			sta	r8H
			jsr	_UCID_COPY_FILE

::err			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;*** Konfiguration aus Infoblock einlesen.
;Übergabe: dirEntryBuf = Verzeichnis-Eintrag
;Rückgabe: uFileName   = Dateiname für Quelldatei
;                        NULL: Nicht definiert
;          uPathTarget = Ziel-Verzeichnis
;                        NULL: Nicht definiert
:getConfig		lda	dirEntryBuf +22
			cmp	#APPLICATION		;Anwendung?
			beq	:1			; => Ja, weiter...
			cmp	#AUTO_EXEC		;AutoExec?
			beq	:1			; => Ja, weiter...
::exit			rts

::1			lda	dirEntryBuf +19		;Infoblock vorhanden?
			beq	:exit			; => Nein, Abbruch...

;Hinweis:
;Infoblock wird vom GEOS-Kernal über
;GetFile eingelesen!
if FALSE
			sta	r1L
			lda	dirEntryBuf +20
			sta	r1H

			lda	#< fileHeader
			sta	r4L
			lda	#> fileHeader
			sta	r4H

			jsr	GetBlock		;Infoblock einlesen.
			txa				;Fehler?
			bne	:exit			; => Nein, weiter...
endif

::filename		ldy	#0
			ldx	#0			;Alten Dateinamen kopieren.
::loop1			lda	fileHeader +160,y
			beq	:done
			cmp	#CR
			beq	:done
			cmp	#","
			beq	:targetdir
			sta	uFileName,x
			inx
			iny
			cpy	#96 -1			;Max. Länge -1 erreicht?
			bcc	:loop1			; => Nein, weiter...
			bcs	:done

::targetdir		iny
			ldx	#0			;Neuen Dateinamen kopieren.
::loop2			lda	fileHeader +160,y
			beq	:done
			cmp	#CR
			beq	:done
			sta	uPathTarget,x
			beq	:done
			inx
			iny
			cpy	#96 -1			;Max. Länge -1 erreicht?
			bcc	:loop2			; => Nein, weiter...

::done			rts

;*** Dateinamen für Kopieren.
:uFileName		s 96
:uPathTarget		s 96

;*** Dialogbox: Status anzeigen.
:dBoxCopy		b %10000001

			b DBTXTSTR,$10,$10
			w :1

			b DBTXTSTR   ,$10,$20
			w :2

			b DBTXTSTR   ,$10,$30
			w :source
			b DBTXTSTR   ,$1a,$30
			w uFileName

			b DBTXTSTR   ,$10,$3a
			w :dest
			b DBTXTSTR   ,$1a,$3a
			w uPathTarget

			b DBTXTSTR   ,$10,$44
			w UCI_STATUS_MSG

			b OK         ,$10,$48
			b NULL

::1			b PLAINTEXT,BOLDON
			b "INFORMATION:"
			b PLAINTEXT,NULL

::2			b "Copy file:",NULL
::source		b "<",NULL
::dest			b ">",NULL
