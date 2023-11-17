; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Erweiterte Systemvariablen.
.GD_VAR_START

;--- Anzeige.
.GD_COL_MODE		b $ff				;$FF = S/W-Modus.
.GD_COL_DEBUG		b $00				;$FF = Debug-Modus, Cache=Farbig.
.GD_COL_CACHE		b $20				;$20 = Farbe für Icons aus Cache.

;--- Hinweis:
;Entfällt. Icon-Farbe im S/W-Modus
;entspricht der Textfarbe des Fensters.
; -> ":DoFileEntry" / C_WinBack.
;GD_COL_DISK		b $00				;$00 = S/W-Datei-Icons.

;--- DeskTop/AppLinks.
.GD_LNK_LOCK		b $00				;$00 = Drag'n'Drop für AppLinks.
							;$FF = AppLinks gesperrt.
.GD_LNK_TITLE		b $00				;$00 = Keine Titel anzeigen.
							;$FF = Titel anzeigen

;--- Hintergrundbild.
.GD_BACKSCRN		b $ff				;$00 = Kein Hintergrundbild.
							;$FF = Hintergrundbild verwenden.

;--- Optionen/Anzeige.
.GD_SLOWSCR		b $00				;$00 = SlowScroll deaktiviert.
							;$FF = SlowScroll aktiv.
.GD_VIEW_DEL		b $00				;$00 = Gelöschte Dateien aus.
							;$FF = Gelöschte Dateien ein.
.GD_ICON_CACHE		b $ff				;$00 = Kein Icon-Cache aktiv.
							;$FF = 64K-Icon-Cache aktiv.
.GD_ICON_PRELOAD	b $00				;$00 = Icon nicht in Speicher laden.
							;$FF = Icon in Speicher laden.

;--- Datei-Eigenschaften.
.GD_INFO_SAVE		b $00				;$00 = AutoSave bei Eigenschaften inaktiv.
							;$FF = Eigenschaften automatisch speichern.

;--- Dateien löschen.
.GD_DEL_MENU		b $00				;$00 = Vor dem Löschen/Dateien nachfragen.
							;$FF = Dateien automatisch löschen.
.GD_DEL_EMPTY		b $ff				;$00 = Nicht-leere Verzeichnisse löschen.
							;$FF = Nur leere Verzeichnisse löschen.

;--- Dateien kopieren.
.GD_REUSE_DIR		b $ff				;$00 = Nicht in Verzeichnis schreiben.
							;$FF = In existierendes Verzeichnis schreiben.
.GD_OVERWRITE_FILES	b $00				;$00 = Dateien nicht überschreiben.
							;$FF = Dateien ohne Nachfragen überschreiben.
.GD_SKIP_EXISTING	b $00				;$00 = Dateien nicht überspringen.
							;$FF = Dateien überspringen.
.GD_SKIP_NEWER		b $00				;$00 = Neuere Dateien nicht überspringen.
							;$FF = Neuere Dateien überspringen.
.GD_COPY_NM_DIR		b $40				;Beim kopieren von Verzeichnissen von
							;NativeMode nach 1541/71/81:
							;Bit%7 = 1: Dateien in das Haupt-
							;           verzeichnis kopieren.
							;Bit%6 = 1: Warnung anzeigen.
.GD_OPEN_TARGET		b $00				;$00 = Nach dem kopieren Quelle öffnen.
							;$FF = Nach dem kopieren Ziel öffnen.

;--- DiskImage erstellen.
.GD_SD_COMPAT_WARN	b $ff				;$FF = Kompatibilitätswarnung anzeigen.
							;Wenn DiskImage nicht zum Laufwerksmodus
							;passt muss der GEOS.Editor gestartet werden.

;--- Systeminfo/TaskInfo anzeigen.
.GD_SYSINFO_MODE	b $00				;$00 = Systeminfo anzeigen.
							;$FF = Taskinfo anzeigen.

;--- Hilfsmittel/Hintergrundbild.
.GD_DA_BACKSCRN		b $00				;$FF = Hintergrund sichtbar.
							;$00 = Bildschirm zurücksetzen.

;--- Standardansicht DeskTop.
.GD_STD_VIEWMODE	b $00				;$00 = Icon-Modus.
							;$FF = Text-Modus.
.GD_STD_TEXTMODE	b $00				;$00 = Text-Modus.
							;$FF = Detail-Modus.
.GD_STD_SORTMODE	b $00				;$00 = Keine Sortierung.
							;$01 = Dateiname.
							;$02 = Dateigröße.
							;$03 = Datum Alt->Neu.
							;$04 = Datum Neu->Alt.
							;$05 = Dateityp.
							;$06 = GEOS-Dateityp.
.GD_STD_SIZEMODE	b $00				;$00 = Blocks anzeigen.
							;$FF = KByte anzeigen.

;--- Dual-Fenster-Modus.
.GD_DUALWIN_MODE	b $00				;$00 = Deaktiviert.
							;$FF = Aktiviert.
.GD_DUALWIN_DRV1	b $00				;$00-$03 = Laufwerk A: bis D:.
.GD_DUALWIN_DRV2	b $00				;$00-$03 = Laufwerk A: bis D:.

;--- Fenster neu laden.
.GD_DA_RELOAD_DIR	b $00				;$00 = Deaktiviert.
							;$7F = Nur oberstes Fenster aktualisieren.
							;$FF = Alle Fenster aktualisieren.

;******************************************************************************
;
;Hinweis:
;Der Bereich von ":GD_SYSCOL_A" bis
;":GD_SYSCOL_E" wird in den Farbprofil-
;Dateien gespeichert.
;
.GD_SYSCOL_A

;******************************************************************************
.GEOS_SYS_COLS_A					;Beginn der Farbtabelle.
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
.GEOS_SYS_COLS_E					;Ende der Farbtabelle.

;******************************************************************************
.GDESK_COLS_A						;Beginn der Farbtabelle.
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
.GDESK_COLS_E						;Endde der Farbtabelle.

;******************************************************************************
.C_GEOS_PATTERN		b $02				;GEOS-Hintergrund-Füllmuster.
.C_GDESK_PATTERN	b $02				;GeoDesk-Hintergrund-Füllmuster.
.C_GTASK_PATTERN	b $00				;GeoDesk/TaskBar-Füllmuster.

;*** Farben für GEOS-Datei-Icons.
;    Hintergrund-Farb-Nibble immer $x0.
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
.GDESK_ICOLTAB
if FALSE
;
;    Hinweis: Standard-Farbtabelle.
;             Farbe nach Dateityp.
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
;    Hinweis: Überarbeitete Farbtabelle.
;             Farbe nach Sytemtyp.
;
; Nicht-GEOS      $0x
; Anwendungen     $6x
; Dokumente       $5x
; System          $2x
; Zeichensatz     $Dx
; Treiber         $4x
; Sonstiges       $Cx
; Verzeichnisse   $Bx
;
::fileColorTab		b $00				;$00-Nicht GEOS.
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
.GDESK_ICOLTAB_E

;******************************************************************************
.GD_SYSCOL_E

:GD_VAR_END
.GD_VAR_SIZE = GD_VAR_END - GD_VAR_START
