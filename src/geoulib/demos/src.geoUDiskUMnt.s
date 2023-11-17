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

			n "geoUDiskUMnt"
			c "geoUDiskUMntV0.1"
			a "Markus Kanet"

if BUILD_DEBUG = TRUE
			h "09:"
else
			h "00:"
endif

			h "Unmount Disk in Ultimate-Laufwerk..."

			o APP_RAM
			p MAININIT

			f APPLICATION
			z $40 ;GEOS 40/80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execDiskUMnt

;--- geoULib einbinden.
;Systemroutinen:
			t "ulib.C.SymbTab"		;Erweiterte Symboltabelle.
			t "ulib.C.Core"			;UCI-Systemroutinen.

;Optionale Routinen:
			t "ulib._ErrUDev"		;Fehler "Kein Ultimate" ausgeben.
			t "ulib._GetStatus"		;UCI-Statusregister abfragen.
			t "ulib._AccData"		;Datenempfang bestätigen.

;DOS-Routinen:
			t "_dos.00.Target"		;DOS-Target 1/2 setzen.
			t "_dos.24.Umount"		;Unmount DiskImage.

;Erweiterte Programmroutinen:
			t "inc.Conf.PathID"		;Ultimate IEC-ID.

;*** Unmount Disk in Ultimate-Laufwerk.
:execDiskUMnt		jsr	ULIB_TEST_UDEV		;Ultimate testen.
;			txa				;Gerät vorhanden?
			beq	:ok			; => Ja, weiter...

;--- Kein Ultimate, Fehler, Ende...
			jsr	ULIB_ERR_NO_UDEV
			jmp	exitDeskTop		; => Ende...

;--- Ultimate vorhanden.
::ok			jsr	getConfigID		;Konfiguration einlesen.

			lda	uIECID			;IEC-ID definiert?
			beq	exitDeskTop		; => Nein, Ende...

			jsr	uDiskUnmount		;Unmount Disk.

			lda	#< dBoxStatus
			sta	r0L
			lda	#> dBoxStatus
			sta	r0H
			jsr	DoDlgBox		;Status anzeigen.

;*** Zurück zu GEOS.
:exitDeskTop		jmp	EnterDeskTop		;Ende.

;*** Unmount Disk.
;Übergabe : uIECID = Ultimate IEC-ID
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r5,r7H

:uDiskUnmount		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			jsr	_UCID_SET_TARGET1	;Target DOS1 verwenden.

			lda	uIECID			;IEC-ID Ultimate-Laufwerk.
			sta	r7H
			jsr	_UCID_UMOUNT_DISK

			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;*** Dialogbox: IEC-ID ausgeben.
:prntIECID		lda	tIECID +0
			jsr	SmallPutChar

			lda	tIECID +1
			jmp	SmallPutChar

;*** Dialogbox: Status anzeigen.
:dBoxStatus		b %10000001

			b DBTXTSTR,$10,$10
			w :1

			b DBTXTSTR   ,$10,$20
			w :2
			b DB_USR_ROUT
			w prntIECID

			b DBTXTSTR   ,$10,$30
			w UCI_STATUS_MSG

			b OK         ,$10,$48
			b NULL

::1			b PLAINTEXT,BOLDON
			b "INFORMATION:"
			b PLAINTEXT,NULL

::2			b "Unmount disk: ",NULL
