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

			n "geoUTemplate"
			c "geoUTemplateV0.0"
			a "Markus Kanet"

			h "geoULib-Template..."

			o APP_RAM
			p MAININIT

			f DESK_ACC
			f APPLICATION
			f DATA

			z $c0 ;Nur GEOS128.
			z $80 ;Nur GEOS64.
			z $40 ;GEOS 40/80-Zeichen.
			z $00 ;GEOS 40-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execMain

;--- geoULib einbinden.
;Systemroutinen:
			t "ulib.C.SymbTab"		;Erweiterte Symboltabelle.
			t "ulib.C.Core"			;UCI-Systemroutinen.

;Optionale Routinen:
			t "ulib._ClkRate128"		;Nur C128: Auf 1/2 MHz umschalten.
			t "ulib._IRQ_NMI"		;IRQ/NMI aus-/einschalten.
			t "ulib._ErrUDev"		;Fehler "Kein Ultimate" ausgeben.
			t "ulib._ErrUDevDA"		;Fehlerausgabe bei DeskAccessories.
			t "ulib._GetStatus"		;UCI-Statusregister abfragen.
			t "ulib._GetData"		;Daten über UCI einlesen.
			t "ulib._AccData"		;Datenempfang bestätigen.
			t "ulib._WaitLong"		;3sec. Pause (z.B. MOUNT).
			t "ulib._Push_DWORD"		;DWORD an UCI senden.
			t "ulib._Push_NAME6"		;Dateiname/Pfad in r6 an UCI senden.
			t "ulib._Push_NAME8"		;Dateiname/Pfad in r8 an UCI senden.
			t "ulib._FileInfo"		;Datei-Informationen konvertieren.
			t "ulib._GetSNative"		;Größe Native-Partition ermitteln.
			t "ulib._ChkImgType"		;DiskImage-Format testen.
			t "ulib._DImgSize"		;DiskImage-Größe testen.
			t "ulib._DetectCREU"		;C=REU erkennen.
			t "ulib._SizeCREU"		;Größe C=REU ermitteln.
			t "ulib._DetectGRAM"		;GeoRAM erkennen.
			t "ulib._SizeGRAM"		;Größe GeoRAM ermitteln.
			t "ulib._SplitPath"		;/Pfad/Dateiname aufteilen.

;DOS-Routinen:
			t "_dos.00.Target"		;DOS-Target 1/2 setzen.
			t "_dos.01.Identify"		;Version DOS-Target abfragen.
			t "_dos.02.FOpen"		;Datei öffnen.
			t "_dos.03.FClose"		;Datei schießen.
			t "_dos.04.DRead"		;Daten lesen.
			t "_dos.05.DWrite2"		;Paketgröße 256B, OK
;			t "_dos.05.DWrite5"		;Paketgröße 512B, Fehler Firmw. v3.6
;			t "_dos.05.DWrite8"		;Paketgröße 508B, OK
			t "_dos.06.FileSeek"		;Position innerhalb Datei setzen.
			t "_dos.07.FileInfo"		;Datei-Informationen einlesen.
			t "_dos.08.FileStat"		;Datei-Informationen einlesen.
			t "_dos.09.DelFile"		;Datei löschen.
			t "_dos.0A.RenFile"		;Datei umbenennen/verschieben.
			t "_dos.0B.CopyFile"		;Datei kopieren.
			t "_dos.11.ChDir"		;Verzeichnis wechseln.
			t "_dos.12.GetPath"		;Aktuelles Verzeichnis einlesen.
			t "_dos.13.OpenDir"		;Verzeichnis öffnen.
			t "_dos.14.ReadDir"		;Verzeichnis einlesen.
			t "_dos.16.MakeDir"		;Verzeichnis erstellen.
			t "_dos.17.HomePath"		;In HOME-Verzeichnis wechseln.
			t "_dos.21.LoadREU"		;Daten in REU laden.
			t "_dos.22.SaveREU"		;Daten aus REU speichern.
			t "_dos.23.Mount"		;Mount DiskImage.
			t "_dos.24.Umount"		;Unmount DiskImage.
			t "_dos.25.SwapDisk"		;DiskImage im Laufwerk wechseln.
			t "_dos.26.GetTime"		;Datum/Uhrzeit abfragen.
			t "_dos.27.SetTime"		;SetTime Ultimate.

;CONTROL-Routinen:
			t "_ctl.01.Identify"		;Version CONTROL-Target abfragen.
			t "_ctl.05.Freeze"		;Ultimate-Menü aufrufen.
			t "_ctl.06.Reboot"		;Ultimate neu starten.
			t "_ctl.28.GetHWInf"		;Hardware-Informationen abfragen.
			t "_ctl.29.DrvInfo"		;IEC-Geräteinfo abfragen.
			t "_ctl.30.EnDiskA"		;Laufwerk A einschalten.
			t "_ctl.31.DisDiskA"		;Laufwerk A abschalten.
			t "_ctl.32.EnDiskB"		;Laufwerk B einschalten.
			t "_ctl.33.DisDiskB"		;Laufwerk B abschalten.
			t "_ctl.34.DiskPwrA"		;Status Laufwerk A abfragen.
			t "_ctl.35.DiskPwrB"		;Status Laufwerk B abfragen.

;NETWORK-Routinen:
			t "_net.01.Identify"		;Version NETWORK-Target abfragen.
			t "_net.02.GetIFCnt"		;Anzahl Schnittstellen abfragen.
			t "_net.04.GetMAC"		;Hardware-Adresse abfragen.
			t "_net.05.GetIPAdr"		;IP-Adresse abfragen.
			t "_net.07.OpenTCP"		;Verbindung über TCP öffnen.
			t "_net.08.OpenUDP"		;Verbindung über UDP öffnen.
			t "_net.09.Close"		;Verbindung beenden.
			t "_net.10.NRead"		;Daten über Netzwerk einlesen.
			t "_net.11.NWrite"		;Daten über Netzwerk senden.

;Erweiterte Programmroutinen:
			t "inc.Conf.FName"		;Dateiname mit/ohne Pfad.
			t "inc.Conf.PathDir"		;Verzeichnisname.
			t "inc.Conf.PathREU"		;RAMDisk-Konfiguration.
			t "inc.Conf.PathID"		;Ultimate IEC-ID.
			t "inc.Conf.Host"		;Host-/Port-Adresse einlesen.
			t "inc.DBStatusData"		;Status-Dialogbox.
			t "inc.DBChDirData"		;Status-Dialogbox für CD-Befehle.
			t "inc.PrntFileInfo"		;Datei-Informationen anzeigen.

;*** Ultimate-Routine aufrufen.
:execMain		jsr	ULIB_TEST_UDEV		;Ultimate testen.
;			txa				;Gerät vorhanden?
			beq	:ok			; => Ja, weiter...

;--- Kein Ultimate.
			jsr	ULIB_ERR_NO_UDEV	;Fehler ausgeben.

;--- GEOS-Programm beenden.
;Entweder exitDeskTop oder exitDA.

::application		jmp	exitDeskTop		; => Ende...
::desk_accessory	jmp	exitDA

;--- Ultimate vorhanden.
::ok

			jsr	PurgeTurbo		;Optional: TurboDOS deaktivieren.

;			jsr	uXXX			;Ultimate-Routine aufrufen.

;--- GEOS-Programm beenden.
;Entweder exitDeskTop oder exitDA.

;--- Anwendungen: Zurück zu GEOS.
:exitDeskTop		jmp	EnterDeskTop		;Ende.

;--- DAs: Zurück zur Anwendung.
:exitDA			lda	#< RstrAppl		;Zurück zur Anwendung.
			sta	appMain +0
			lda	#> RstrAppl
			sta	appMain +1

			rts				;Ende.

;*** GEOS-Laufwerk A bis D.
:geosDriveAdr		b $00
:geosRAMDisk		b NULL

;*** Subroutinen.
:uChangeDir
:uGetPath
			rts
