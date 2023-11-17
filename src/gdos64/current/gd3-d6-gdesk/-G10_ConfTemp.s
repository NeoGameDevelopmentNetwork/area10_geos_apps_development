; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
;*** GeoDesk-Informationen.
;
; Hinweis:
; Der BootLoader speichert die GeoDesk-
; Informationen (Dateiname, Laufwerk...)
; direkt im Hauptmodul.

;--- Systeminformationen.
.GD_SYS_NAME		s 17
.GD_SYS_CLASS		t "opt.GDesk.Build"
			e GD_SYS_CLASS +21

;--- Systemlaufwerk.
.BootDrive		b $00
.BootPart		b $00
.BootType		b $00
.BootMode		b $00
.BootSDir		b $00,$00
.BootRBase		b $00

;*** Gemeinsam genutzte Variablen.
;--- AppLink-Konfigurationsdatei.
.GD_APPL_CLASS		b "GD_AppLinks V1.1",NULL

;--- Fenster anzeigen/verstecken.
.GD_HIDEWIN_MODE	b $00

;--- Aktives VLIR-Modul.
.GD_VLIR_CORE		b $00
.GD_VLIR_MODX		b $00

;--- Zwischenspeicher für Laufwerkswechsel.
.TempDrive		b $00
.TempMode		b $00
.TempPart		b $00
.TempSDir		b $00,$00

;--- Quelle/Ziel.
;Für DiskCopy:
;Laufwerk 8-11, CMD-Part,Tr/Se-SubDir.
;
.sysSource		b $00,$00,$00,$00
.sysTarget		b $00,$00,$00,$00

;Bei Datei-Operationen:
;Quelle und Ziel zwischen zwei Fenster,
;z.B. Kopieren/Verschieben.
;Enthält die Fenster-Nr. aus WM_STACK.
;
.winSource		b $00
.winTarget		b $00

;Disk-/Dateien kopieren:
;Quell-/Ziel-Fenster aktualisieren.
;Der Wert wird für GD_RELOAD_DIR beim
;aktualisieren des Fensters gesetzt.
;Siehe TopSym.GD -> SET_LOAD-Flag.
;
.updateSource		b $00
.updateTarget		b $00

;--- Laufwerkstypen (C=1541, CMD HD41...)
.GD_DRVTYPE_A		s 17				;Typ für Laufwerk A:.
.GD_DRVTYPE_B		s 17				;Typ für Laufwerk B:.
.GD_DRVTYPE_C		s 17				;Typ für Laufwerk C:.
.GD_DRVTYPE_D		s 17				;Typ für Laufwerk D:.

;--- Position Bildschirm-Grafikspeicher in REU.
.GD_BACKSCR_BUF		= $0000
.GD_BACKCOL_BUF		= GD_BACKSCR_BUF + 8000

;--- Position Fenster-Daten.
.vecDirDataRAM		w $ffff				;Fenster #0 = Desktop.
			w $2400				;Dateifenster #1.
			w $3800				;Dateifenster #2.
			w $4c00				;Dateifenster #3.
			w $6000				;Dateifenster #4.
			w $7400				;Dateifenster #5.
			w $8800				;Dateifenster #6.
.vecBAMDataRAM		w $ffff				;Fenster #0 = Desktop.
			w $9c00				;BAM-CRC Fenster #1.
			w $a000				;BAM-CRC Fenster #2.
			w $a400				;BAM-CRC Fenster #3.
			w $a800				;BAM-CRC Fenster #4.
			w $ac00				;BAM-CRC Fenster #5.
			w $b000				;BAM-CRC Fenster #6.

;--- Position Icon-Daten.
.vecIconDataRAM		w $ffff				;Fenster #0 = Desktop.
			w $0000				;Dateifenster #1.
			w $2800				;Dateifenster #2.
			w $5000				;Dateifenster #3.
			w $7800				;Dateifenster #4.
			w $a000				;Dateifenster #5.
			w $c800				;Dateifenster #6.

;--- Verzeichnis laden.
.GD_RELOAD_DIR		b $00				;$80 = Dateien von Disk laden.
							;$40 = BAM testen/Cache oder Disk.
							;$3F = Nur Dateien sortieren.
							;$00 = Dateien aus Cache.

;--- Gewählter Eintrag im Arbeitsplatz.
.MyCompEntry		b $00

;--- Zeiger auf 32 Byte Verzeichnis-Eintrag.
.fileEntryVec		w $0000

;--- Gewählter Datei-Eintrag in Dateiliste.
.fileEntryPos		b $00
.fileEntryCount		b $00

;--- Fensterdaten aktualisieren ?
.drvUpdFlag		b $00				;%1xxxxxxx = Fensterdaten aktualisieren.
							;%x1xxxxxx = Andere Fenster schließen.
							;%xx1xxxxx = Dateiauswahl aufheben.
.drvUpdSDir		b $00				;WIN_SDIR_T
			b $00				;WIN_SDIR_S
.drvUpdMode		b $00				;WIN_DATAMODE

;--- GetFileData: Datenlaufwerk.
.getFileWin		b $00
.getFileDrv		b $00
.getFilePart		b $00
.getFileSDir		b $00,$00

;--- Dialogbox-Titel.
if LANG = LANG_DE
.Dlg_Titel_Info		b PLAINTEXT,BOLDON
			b "HINWEIS"
			b NULL

.Dlg_Titel_Err		b PLAINTEXT,BOLDON
			b "FEHLER"
			b NULL
endif
if LANG = LANG_EN
.Dlg_Titel_Info		b PLAINTEXT,BOLDON
			b "INFORMATION"
			b NULL

.Dlg_Titel_Err		b PLAINTEXT,BOLDON
			b "ERROR"
			b NULL
endif

;--- Laufwerksfehler.
.errDrvCode		b $00
.errDrvInfoT		b $00
.errDrvInfoS		b $00
.errDrvInfoP		b $00
.errDrvInfoF		w $0000

;*** Bildschirmschoner-Flag:
;Bit%7=1: Bildschirmschoner über
;         appMain/MainLoop starten.
.Flag_RunScrSvr		b $00

;
;*** Systemfarben/Muster.
;
.GD_PROFILE

;
;*** GEOS-Farbtabelle.
;
.GD_COLOR_GEOS
::C_Balken		b $0d				;Scrollbalken.
::C_Register		b $07				;Karteikarten: Aktiv.
::C_RegisterOff		b $08				;Karteikarten: Inaktiv.
::C_RegisterBack	b $07				;Karteikarten: Hintergrund.
::C_Mouse		b $06				;Mausfarbe.
::C_DBoxTitel		b $10				;Dialogbox: Titel.
::C_DBoxBack		b $03				;Dialogbox: Hintergrund + Text.
::C_DBoxDIcon		b $01				;Dialogbox: System-Icons.
::C_FBoxTitel		b $10				;Dateiauswahlbox: Titel.
::C_FBoxBack		b $0e				;Dateiauswahlbox: Hintergrund + Text.
::C_FBoxDIcon		b $0d				;Dateiauswahlbox: System-Icons.
::C_FBoxFiles		b $03				;Dateiauswahlbox: Dateifenster.
::C_WinTitel		b $10				;Fenster: Titel.
::C_WinBack		b $0f				;Fenster: Hintergrund.
::C_WinShadow		b $00				;Fenster: Schatten.
::C_WinIcon		b $0d				;Fenster: System-Icons.
::C_PullDMenu		b $03				;PullDown-Menu.
::C_InputField		b $01				;Text-Eingabefeld.
::C_InputFieldOff	b $0f				;Inaktives Optionsfeld.
::C_GEOS_BACK		b $bf				;GEOS-Standard: Hintergrund.
::C_GEOS_FRAME		b $00				;GEOS-Standard: Rahmen.
::C_GEOS_MOUSE		b $06				;GEOS-Standard: Mauszeiger.

			g GD_COLOR_GEOS + COLVAR_SIZE

;
;*** GeoDesk-Farbtabelle.
;
.GD_COLOR						;Beginn der Farbtabelle.
.C_WinScrBar		b $01				;Fenster/Scrollbalken.
.C_WinMovIcons		b $10				;Scroll Up/Down-Icons.
.C_GDesk_Clock		b GD_COLOR_CLOCK		;GeoDesk-Uhr.
.C_GDesk_GEOS		b $03				;GEOS-Menübutton.
.C_RegisterExit		b $0d				;Karteikarten: Beenden.
.C_GDesk_TaskBar	b $10				;GeoDesk-Taskbar.
.C_GDesk_ALIcon		b $01				;Farbe für AppLink-Icons/Standard.
.C_GDesk_ALTitle	b $07				;Farbe für AppLink-Titel.
.C_GDesk_MyComp		b $01				;Farbe für Arbeitsplatz-Icon.
.C_GDesk_DeskTop	b $bf				;Farbe für GeoDesk ohne BackScreen.

:GD_COLOR_END						;Endde der Farbtabelle.
:GD_COLOR_SIZE = (GD_COLOR_END - GD_COLOR)

;
;*** GEOS-/GeoDesk-Füllmuster.
;
.C_GEOS_PATTERN		b $02				;GEOS-Hintergrund-Füllmuster.
.C_GDESK_PATTERN	b $02				;GeoDesk-Hintergrund-Füllmuster.
.C_GTASK_PATTERN	b $00				;GeoDesk/TaskBar-Füllmuster.

;
;*** Farben für GEOS-Datei-Icons.
;
; Hinweis:
; Hintergrund-Farb-Nibble immer $x0.
;
; $0x = Schwarz   $8x = Orange
; $1x = Weiß      $9x = Braun
; $2x = Rot       $Ax = Hellrot
; $3x = Türkis    $Bx = Dunkelgrau
; $4x = Violett   $Cx = Grau
; $5x = Grün      $Dx = Hellgrün
; $6x = Blau      $Ex = Hellblau
; $7x = Gelb      $Fx = Hellgrau
;
.GD_COLICON
if FALSE
;
; Hinweis: Standard-Farbtabelle.
;          Farbe nach Dateityp.
;
::fileColorTab		b $00				;$00-Nicht GEOS.
			b $00				;$01-BASIC-Programm.
			b $30				;$02-Assembler-Programm.
			b $30				;$03-Datenfile.
			b $20				;$04-Systemdatei.
			b $60				;$05-Hilfsprogramm.
			b $60				;$06-Anwendung.
			b $30				;$07-Dokument.
			b $70				;$08-Zeichensatz.
			b $50				;$09-Druckertreiber.
			b $50				;$0A-Eingabetreiber.
			b $20				;$0B-Laufwerkstreiber.
			b $20				;$0C-Startprogramm.
			b $00				;$0D-Temporäre Datei (SWAP FILE).
			b $60				;$0E-Selbstausführend (AUTO_EXEC).
			b $50				;$0F-Eingabetreiber C128.
			b $70				;$10-Unbekannt.
			b $60				;$11-gateWay-Dokument.
			b $70				;$12-Unbekannt.
			b $70				;$13-Unbekannt.
			b $70				;$14-Unbekannt.
			b $60				;$15-geoShell-Befehl.
			b $50				;$16-geoFax-Dokument.
			b $70				;$17-Unbekannt.
			b $b0				;$18-Verzeichnis.
endif

if TRUE
;
; Hinweis: Überarbeitete Farbtabelle.
;          Farbe nach Sytemtyp.
;
; Nicht-GEOS      $Cx
; Anwendungen     $6x
; Dokumente       $5x
; System          $2x
; Zeichensatz     $Dx
; Treiber         $4x
; Sonstiges       $Cx
; Verzeichnisse   $Bx
;
::fileColorTab		b $c0				;$00-Nicht GEOS.
			b $60				;$01-BASIC-Programm.
			b $60				;$02-Assembler-Programm.
			b $c0				;$03-Datenfile.
			b $20				;$04-Systemdatei.
			b $60				;$05-Hilfsprogramm.
			b $60				;$06-Anwendung.
			b $50				;$07-Dokument.
			b $d0				;$08-Zeichensatz.
			b $40				;$09-Druckertreiber.
			b $40				;$0A-Eingabetreiber.
			b $40				;$0B-Laufwerkstreiber.
			b $20				;$0C-Startprogramm.
			b $c0				;$0D-Temporäre Datei (SWAP FILE).
			b $60				;$0E-Selbstausführend (AUTO_EXEC).
			b $40				;$0F-Eingabetreiber C128.
			b $c0				;$10-Unbekannt.
			b $40				;$11-gateWay-Dokument.
			b $c0				;$12-Unbekannt.
			b $c0				;$13-Unbekannt.
			b $c0				;$14-Unbekannt.
			b $40				;$15-geoShell-Befehl.
			b $50				;$16-geoFax-Dokument.
			b $c0				;$17-Unbekannt.
			b $b0				;$18-Verzeichnis.
endif
:GD_COLICON_END
:GD_COLICON_SIZE = (GD_COLICON_END - GD_COLICON)

;
;*** Ende Systemfarben/Muster.
;
:GD_PROFILE_END
:GD_PROFILE_SIZE = (GD_PROFILE_END - GD_PROFILE)
