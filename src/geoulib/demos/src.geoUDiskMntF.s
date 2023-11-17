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

			n "geoUDiskMntF"
			c "geoUDiskMntFV0.1"
			a "Markus Kanet"

if BUILD_DEBUG = TRUE
			h "09:/Usb0/ULIB/test.d64"
else
			h "00:/root/dir/disk.ext"
endif

			h "Mount Disk in Ultimate-Laufwerk ohne Fehlerprüfung..."

			o APP_RAM
			p MAININIT

			f APPLICATION
			z $40 ;GEOS 40/80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execDiskMntF

;--- geoULib einbinden.
;Systemroutinen:
			t "ulib.C.SymbTab"		;Erweiterte Symboltabelle.
			t "ulib.C.Core"			;UCI-Systemroutinen.

;Optionale Routinen:
			t "ulib._ErrUDev"		;Fehler "Kein Ultimate" ausgeben.
			t "ulib._GetStatus"		;UCI-Statusregister abfragen.
			t "ulib._GetData"		;Daten über UCI einlesen.
			t "ulib._AccData"		;Datenempfang bestätigen.
			t "ulib._WaitLong"		;3sec. Pause (z.B. MOUNT).
			t "ulib._Push_NAME6"		;Dateiname/Pfad in r6 an UCI senden.
			t "ulib._SplitPath"		;/Pfad/Dateiname aufteilen.

;DOS-Routinen:
			t "_dos.00.Target"		;DOS-Target 1/2 setzen.
			t "_dos.11.ChDir"		;Verzeichnis wechseln.
			t "_dos.23.Mount"		;Mount DiskImage.

;*** Mount Disk in Ultimate-Laufwerk.
:execDiskMntF		jsr	ULIB_TEST_UDEV		;Ultimate testen.
;			txa				;Gerät vorhanden?
			beq	:ok			; => Ja, weiter...

;--- Kein Ultimate, Fehler, Ende...
			jsr	ULIB_ERR_NO_UDEV
			jmp	exitDeskTop		; => Ende...

;--- Ultimate vorhanden.
::ok			jsr	getConfig		;Konfiguration einlesen.

			lda	uIECID			;IEC-ID definiert?
			beq	exitDeskTop		; => Nein, Ende...

			lda	uFileName		;Pfad vorhanden?
			beq	exitDeskTop		; => Nein, Ende...

			jsr	uDiskMountF		;Mount Disk.

			lda	#< dBoxStatus
			sta	r0L
			lda	#> dBoxStatus
			sta	r0H
			jsr	DoDlgBox		;Status anzeigen.

;*** Zurück zu GEOS.
:exitDeskTop		jmp	EnterDeskTop		;Ende.

;*** Mount Disk.
;Übergabe : uFileName = (Verzeichnispfad/)Dateiname DiskImage
;           uIECID    = Ultimate IEC-ID
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;           UCI_DATA_MSG   = Verzeichnispfad (falls vorhanden, sonst NULL)
;           r6 = Zeiger auf Dateiname innerhalb uFileName
;Verändert: A,X,Y,r5,r6,r7H,r9

:uDiskMountF		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
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

;			lda	#< uFileName		;Zeiger auf Dateiname.
;			sta	r6L
;			lda	#> uFileName
;			sta	r6H
			lda	uIECID			;IEC-ID Ultimate-Laufwerk.
			sta	r7H
			jsr	_UCID_MOUNT_DISK

::err			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;*** Konfiguration aus Infoblock einlesen.
;Übergabe: dirEntryBuf  = Verzeichnis-Eintrag
;Rückgabe: uIECID    = GEOS-Laufwerk A bis D
;                      NULL: Nicht definiert
;          uFileName = Dateiname DiskImage (mit oder ohne Pfad)
;                      NULL: Nicht definiert
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

			lda	fileHeader +160		;IEC-ID auswerten.
			cmp	#"0"
			bcc	:exit			; => Ungültig...
			cmp	#"9" +1
			bcs	:exit			; => Ungültig...

			ldx	fileHeader +161		;IEC-ID auswerten.
			cpx	#"0"
			bcc	:exit			; => Ungültig...
			cpx	#"9" +1
			bcs	:exit			; => Ungültig...

			ldy	fileHeader +162		;Trennzeichen?
			cpy	#":"
			bne	:exit			; => Ungültig...

;--- Hinweis:
;Angabe Verzeichnis ist Optional...
;			ldy	fileHeader +163		;Verzeichnispfad?
;			cpy	#"/"
;			bne	:exit			; => Nein, Ungültig...

			sta	txtIECID +0
			stx	txtIECID +1

			sec				;Ultimate IEC-ID ermitteln.
			sbc	#"0"
			asl
			sta	r0L
			asl
			asl
			clc
			adc	r0L
			sta	r0L
			txa
			sec
			sbc	#"0"
			clc
			adc	r0L
			cmp	#8			;IEC-ID < 8?
			bcc	:exit			; => Ja, ungültig...
			cmp	#30 +1			;IEC-ID > 30?
			bcs	:exit			; => Ja, ungültig...

			sta	uIECID			;IEC-ID speichern.

::copy_path		ldy	#0			;Pfad kopieren.
::loop			lda	fileHeader +160 +3,y
			cmp	#CR
			beq	:done
			sta	uFileName,y
			beq	:done
			iny
			cpy	#96 -3			;Max. Länge -3 (00:) erreicht?
			bcc	:loop			; => Nein, weiter...

::done			rts

;*** Pfad in Ultimate zum DiskImage.
:uFileName		s 96

;*** Ultimate IEC-ID 8-30.
:uIECID			b $00

;*** Dialogbox: Status anzeigen.
:dBoxStatus		b %10000001

			b DBTXTSTR   ,$10,$10
			w :1

			b DBTXTSTR   ,$10,$20
			w :2

			b DBTXTSTR   ,$10,$2e
			w uFileName
			b DBVARSTR   ,$10,$38
			b r9

			b DBTXTSTR   ,$10,$44
			w UCI_STATUS_MSG

			b OK         ,$10,$48
			b NULL

::1			b PLAINTEXT,BOLDON
			b "INFORMATION:"
			b PLAINTEXT,NULL

::2			b "Mount disk: "
:txtIECID		b "XX",NULL
