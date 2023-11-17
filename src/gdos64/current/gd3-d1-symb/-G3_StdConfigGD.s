; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** GeoDesk-Systemkonfiguration.
:GEODESK_DEFAULT_CONFIG

;--- Anzeige: 3Bytes
;000
;GD_COL_MODE
			b $ff				;$FF = S/W-Modus.
;GD_COL_DEBUG
			b $00				;$FF = Debug-Modus, Cache=Farbig.
;GD_COL_CACHE
			b $20				;$20 = Farbe für Icons aus Cache.

;--- Hinweis:
;Entfällt. Icon-Farbe im S/W-Modus
;entspricht der Textfarbe des Fensters.
; -> ":DoFileEntry" / C_WinBack.
;GD_COL_DISK
;			b $00				;$00 = S/W-Datei-Icons.

;--- DeskTop/AppLinks: 2Bytes
;003
;GD_LNK_LOCK
			b $00				;$00 = Drag'n'Drop für AppLinks.
							;$FF = AppLinks gesperrt.
;GD_LNK_TITLE
			b $00				;$00 = Keine Titel anzeigen.
							;$FF = Titel anzeigen

;--- Hintergrundbild: 1Byte
;005
;GD_BACKSCRN
			b $ff				;$00 = Kein Hintergrundbild.
							;$FF = Hintergrundbild verwenden.

;--- Optionen/Anzeige: 5Bytes
;006
;GD_SLOWSCR
			b $00				;$00 = SlowScroll deaktiviert.
							;$FF = SlowScroll aktiv.
;GD_VIEW_DELETED
			b $00				;$00 = Gelöschte Dateien aus.
							;$FF = Gelöschte Dateien ein.
;GD_HIDE_SYSTEM
			b $00				;$80 = Systemdateien ausblenden.
							;$40 = Drucker-/Eingabetreiber ausblenden.
							;$20 = Schreibgeschützte Dateien ausblenden.
;GD_ICON_CACHE
			b $ff				;$00 = Kein Icon-Cache aktiv.
							;$FF = 64K-Icon-Cache aktiv.
;GD_ICON_PRELOAD
			b $00				;$00 = Icon nicht in Speicher laden.
							;$FF = Icon in Speicher laden.

;--- Datei-Eigenschaften: 1Byte
;011
;GD_INFO_SAVE
			b $00				;$00 = AutoSave bei Eigenschaften inaktiv.
							;$FF = Eigenschaften automatisch speichern.

;--- Dateien löschen: 2Bytes
;012
;GD_DEL_MENU
			b $00				;$00 = Vor dem Löschen/Dateien nachfragen.
							;$FF = Dateien automatisch löschen.
;GD_DEL_EMPTY
			b $ff				;$00 = Nicht-leere Verzeichnisse löschen.
							;$FF = Nur leere Verzeichnisse löschen.

;--- Dateien kopieren: 6Bytes
;014
;GD_REUSE_DIR
			b $ff				;$00 = Nicht in Verzeichnis schreiben.
							;$FF = In existierendes Verzeichnis schreiben.
;GD_OVERWRITE
			b $00				;$00 = Dateien nicht überschreiben.
							;$FF = Dateien ohne Nachfragen überschreiben.
;GD_SKIP_EXIST
			b $00				;$00 = Dateien nicht überspringen.
							;$FF = Dateien überspringen.
;GD_SKIP_NEWER
			b $00				;$00 = Neuere Dateien nicht überspringen.
							;$FF = Neuere Dateien überspringen.
;GD_COPY_NM_DIR
			b $40				;Beim kopieren von Verzeichnissen von
							;NativeMode nach 1541/71/81:
							;Bit%7 = 1: Dateien in das Haupt-
							;           verzeichnis kopieren.
							;Bit%6 = 1: Warnung anzeigen.
;GD_OPEN_TARGET
			b $ff				;$00 = Nach dem kopieren Quelle öffnen.
							;$FF = Nach dem kopieren Ziel öffnen.

;--- DiskImage erstellen: 1Byte
;020
;GD_COMPAT_WARN
			b $c0				;Kompatibilitätswarnung anzeigen.
							;Wenn DiskImage nicht zum Laufwerksmodus
							;passt, dann muss GD.CONFIG gestartet werden.
							;Bit%7 = 1: Warnung für SD2IEC anzeigen.
							;Bit%6 = 1: Warnung für CMD-FD anzeigen.

;--- Systeminfo/TaskInfo anzeigen: 1Byte
;021
;GD_SYSINFO_MODE
			b $00				;$00 = Systeminfo anzeigen.
							;$FF = Taskinfo anzeigen.

;--- Hilfsmittel/Hintergrund: 1Byte
;022
;GD_DA_BACKSCRN
			b $ff				;$FF = Hintergrundbild anzeigen.
							;$00 = Bildschirm zurücksetzen.

;--- Standardansicht DeskTop: 4Bytes
;023
;GD_STD_VIEWMODE
			b $00				;$00 = Icon-Modus.
							;$FF = Text-Modus.
;GD_STD_TEXTMODE
			b $00				;$00 = Text-Modus.
							;$FF = Detail-Modus.
;GD_STD_SORTMODE
			b $00				;$00 = Keine Sortierung.
							;$01 = Dateiname.
							;$02 = Dateigröße.
							;$03 = Datum Alt->Neu.
							;$04 = Datum Neu->Alt.
							;$05 = Dateityp.
							;$06 = GEOS-Dateityp.
;GD_STD_SIZEMODE
			b $00				;$00 = Blocks anzeigen.
							;$FF = KByte anzeigen.

;--- Dual-Fenster-Modus: 3Bytes
;027
;GD_DUALWIN_MODE
			b $00				;$00 = Deaktiviert.
							;$FF = Aktiviert.
;GD_DUALWIN_DRV1
			b $00				;$00-$03 = Laufwerk A: bis D:.
;GD_DUALWIN_DRV2
			b $00				;$00-$03 = Laufwerk A: bis D:.

;--- Fenster neu laden: 1Byte
;030
;GD_DA_UPD_DIR
			b $00				;$00 = Deaktiviert.
							;$7F = Nur oberstes Fenster aktualisieren.
							;$FF = Alle Fenster aktualisieren.

;--- HotCorners: 8Bytes
;031
;GD_HC_CFG1
			b %10000000
							;Bit%7 = 1: HotCorner oben/links aktiv.
							;Bit%2-0  : Funktion oben/links.
;GD_HC_CFG2
			b %10000001
							;Bit%7 = 1: HotCorner oben/rechts aktiv.
							;Bit%2-0  : Funktion oben/rechts.
;GD_HC_CFG3
			b %00000010
							;Bit%7 = 1: HotCorner unten/links aktiv.
							;Bit%2-0  : Funktion unten/links.
;GD_HC_CFG4
			b %00000011
							;Bit%7 = 1: HotCorner unten/rechts aktiv.
							;Bit%2-0  : Funktion unten/rechts.
;GD_HC_TIMER1
			b %00000010
							;Bit%1+0  : Timer oben/links.
;GD_HC_TIMER2
			b %00000010
							;Bit%1+0  : Timer oben/rechts.
;GD_HC_TIMER3
			b %00000010
							;Bit%1+0  : Timer unten/links.
;GD_HC_TIMER4
			b %00000010
							;Bit%1+0  : Timer unten/rechts.

;--- Senden: 6Bytes
;039
;GD_SENDTO_PRN
			b $04				;Drucker  : Geräteadresse.
;GD_SENDTO_XPRN
			b %11110000
							;Bit%7 = 1: GEOS/DE->UTF8.
							;Bit%6 = 1: Send LineFeed.
							;Bit%5 = 1: Remove CR.
							;Bit%4 = 1: Send FormFeed.

;GD_SENDTO_DRV1
			b $00				;Laufwerk1: Geräteadresse.
;GD_SENDTO_XDRV1
			b %00000000
							;Bit%7 = 1: Nur GeoWrite-Dokumente.
							;Bit%6 = 1: Dateien konvertieren.

;GD_SENDTO_DRV2
			b $00				;Laufwerk2: Geräteadresse.
;GD_SENDTO_XDRV2
			b %00000000
							;Bit%7 = 1: Nur GeoWrite-Dokumente.
							;Bit%6 = 1: Dateien konvertieren.

;--- MicroMys: 1Byte
;045
:GD_MWHEEL		b %00101010
							;Bit%7 = 1: MicroMys aktiv.
							;Bit%0/1  : Modus "Up".
							;     %00 = Keine Funktion.
							;     %01 = $10, Eine Zeile hoch.
							;     %10 = $08, Eine Seite hoch.
							;     %11 = $90, Zum Anfang.
							;Bit%2/3  : Modus "Down".
							;     %00 = Keine Funktion.
							;     %01 = $11, Eine Zeile runter.
							;     %10 = $1e, Eine Seite runter.
							;     %11 = $91, Zum Ende.
							;Bit%4/5  : Verzögerung 0-3.
							;Bit%6    : Nicht verwendet.
;--- EOF
;046
;254 ;Max. 254 Bytes!

;******************************************************************************
;*** Endadresse für CONFIG testen.
;******************************************************************************
			g GEODESK_DEFAULT_CONFIG +254
;******************************************************************************
