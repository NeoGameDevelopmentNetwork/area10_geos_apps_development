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

			n "geoUSaveREU"
			c "geoUSaveREU V0.2"
			a "Markus Kanet"

if BUILD_DEBUG = TRUE
			h "C:/Usb0/ULIB/test.d64"
else
			h "x:/root/dir/disk.ext"
endif

			h "Ultimate-RAM-Laufwerk als DiskImage speichern..."

			o APP_RAM
			p MAININIT

			f APPLICATION
			z $40 ;GEOS 40/80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execSaveREU

;--- geoULib einbinden.
;Systemroutinen:
			t "ulib.C.SymbTab"		;Erweiterte Symboltabelle.
			t "ulib.C.Core"			;UCI-Systemroutinen.

;Optionale Routinen:
			t "ulib._ErrUDev"		;Fehler "Kein Ultimate" ausgeben.
			t "ulib._GetStatus"		;UCI-Statusregister abfragen.
			t "ulib._GetData"		;Daten über UCI einlesen.
			t "ulib._AccData"		;Datenempfang bestätigen.
			t "ulib._Push_DWORD"		;DWORD an UCI senden.
			t "ulib._Push_NAME6"		;Dateiname/Pfad in r6 an UCI senden.
			t "ulib._GetSNative"		;Größe Native-Partition ermitteln.
			t "ulib._DImgSize"		;DiskImage-Größe testen.
			t "ulib._SplitPath"		;/Pfad/Dateiname aufteilen.

;DOS-Routinen:
			t "_dos.00.Target"		;DOS-Target 1/2 setzen.
			t "_dos.02.FOpen"		;Datei öffnen.
			t "_dos.03.FClose"		;Datei schießen.
			t "_dos.11.ChDir"		;Verzeichnis wechseln.
			t "_dos.22.SaveREU"		;Daten aus REU speichern.

;Erweiterte Programmroutinen:
			t "inc.Conf.PathREU"		;RAMDisk-Konfiguration.

;*** GEOS-RAMDisk als DiskImage speichern.
:execSaveREU		jsr	ULIB_TEST_UDEV		;Ultimate testen.
;			txa				;Gerät vorhanden?
			beq	:ok			; => Ja, weiter...

;--- Kein Ultimate, Fehler, Ende...
			jsr	ULIB_ERR_NO_UDEV
			jmp	exitDeskTop		; => Ende...

;--- Ultimate vorhanden.
::ok			jsr	getConfigREU		;Konfiguration einlesen.

			lda	uPathRDisk		;Pfad vorhanden?
			beq	exitDeskTop		; => Nein, Ende...

			lda	geosRAMDisk		;RAMDisk definiert?
			beq	exitDeskTop		; => Nein, Ende...

			jsr	uSaveRAMDisk		;RAMDisk als Disk speichern.
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

;*** GEOS-RAMDisk als DiskImage speichern.
;Übergabe : uPathRDisk   = (Verzeichnispfad/)Dateiname
;           geosDriveAdr = GEOS-Laufwerk 8 bis 11
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;           UCI_DATA_MSG   = Transferstatus
;Verändert: A,X,Y,r0 bis r3L,r4,r5,r6,r7L,r9

:uSaveRAMDisk		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			jsr	_UCID_SET_TARGET1	;Target DOS1 verwenden.

			lda	#< UCI_DATA_MSG		;Zwischenspeicher für Pfad.
			sta	r6L
			lda	#> UCI_DATA_MSG
			sta	r6H
			lda	#< uPathRDisk		;Zeiger auf /Pfad/Dateiname.
			sta	r9L
			lda	#> uPathRDisk
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

			lda	geosDriveAdr		;GEOS-Laufwerksadresse.
			sta	r7L
			jsr	ULIB_GETS_NATIVE	;Größe NativeMode einlesen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

;			lda	#< uPathRDisk		;Neue/Leere Datei erstellen.
;			sta	r6L
;			lda	#> uPathRDisk
;			sta	r6H
			jsr	_UCID_OPEN_FILE_OVERWRITE
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

;			lda	#NULL			;Rückmeldung initialisieren.
			sta	UCI_DATA_MSG		; => Kein Transferstatus.

			ldx	geosDriveAdr
			lda	driveType -8,x
			and	#ST_DMODES
			pha
			asl
			asl
			tay

			ldx	#0
::size			lda	#$00			;Startadresse löschen.
			sta	r0,x
			lda	tabDiskSize,y		;Größe RAMDisk übernehmen.
			sta	r2,x
			iny
			inx
			cpx	#4
			bcc	:size

			ldx	geosDriveAdr		;Erste 64K-Speicherbank ist
			lda	ramBase -8,x		;Startadresse RAMDisk.
			sta	r1L

			pla
			tax
			lda	twoStepCopy,x		;Sonderbehandlung 1571?
			beq	:cont			; => Nein, weiter...

;--- Sonderbehandlung 1571.
::is1571		pha				;Offset speichern.

			lsr	r3L			;Größe/2.
			ror	r2H

			jsr	_UCID_SAVE_REU		;Teil #1 speichern (Track 1-35).

			pla				;Offset wieder einlesen.

			cpx	#NO_ERROR		;Ladefehler?
			bne	:exit			; => Ja, Abbruch...

			clc				;Offset addieren und
			adc	r2H			;Teil #2 speichern (Track 36-70).
			sta	r0H			;Startadresse einer RAMDisk ist
			bcc	:1			;immer $xx:0000 => MLB hat immer
			inc	r1L			;den Wert $00. Nach dem addieren
::1			lda	r1L			;des Offset kann kein Überlauf
			adc	r3L			;eintreten. Daher nur die Größe
			sta	r1L			;von Teil #1 addieren.

;--- Standard für D64/D81/DNP.
::cont			jsr	_UCID_SAVE_REU		;REU speichern.
;			txa				;Fehler?
;			bne	:exit			; => Ja, Abbruch...

;			ldx	#NO_ERROR		;Kein Fehler.
::exit			jsr	_UCID_CLOSE_FILE	;Datei schließen.

::err			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;*** GEOS-Laufwerk 8-11.
:geosDriveAdr		b $00

;*** GEOS-Laufwerk A bis D.
:geosRAMDisk		b "X:",NULL

;*** Dialogbox: Status anzeigen.
:dBoxStatus		b %00000001
			b $20,$7f
			w $0030,$010f

			b DBTXTSTR   ,$10,$10
			w :1

			b DBTXTSTR   ,$10,$20
			w :2

			b DBTXTSTR   ,$10,$30
			w geosRAMDisk
			b DBTXTSTR   ,$1a,$30
			w uPathRDisk

			b DBTXTSTR   ,$10,$3a
			w UCI_STATUS_MSG
			b DBTXTSTR   ,$10,$44
			w UCI_DATA_MSG

			b OK         ,$14,$48
			b NULL

::1			b PLAINTEXT,BOLDON
			b "INFORMATION:"
			b PLAINTEXT,NULL

::2			b "Save RAMDisk:"
			b NULL
