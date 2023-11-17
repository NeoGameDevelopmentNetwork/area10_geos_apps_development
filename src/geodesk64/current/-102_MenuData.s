; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
;Hinweis:
;
;Für neue Untermenüs muss:
; * Menutext bei PT... angelegt werden.
; * Die Menüdaten als WORD#1 bei ":PDVec" ergänzt werden.
; * Die Funktionsroutinen als WORD#2 bei ":PDVec" ergänzt werden.
; * Die Breite des Menüs in ":PDWidth" ergänzt werden.
;

;*** Texte für PopUp-Menüs.
if LANG = LANG_DE
:PT050			b "Überlappend",NULL
:PT051			b "Nebeneinander",NULL
:PT052			b "Neu laden",NULL
:PT053			b "Neue Ansicht",NULL
:PT054			b "( ) Hintergrundbild",NULL
:PT055			b "( ) AppLink sperren",NULL
:PT056			b "Hintergrund wechseln",NULL
:PT057			b "Fenster schließen",NULL

:PT100			b "Datei öffnen",NULL
:PT101			b "Partition wechseln",NULL
:PT102			b "Neuen Drucker wählen",NULL
:PT103			b BOLDON
			b "Drucker"
			b PLAINTEXT,NULL
:PT104			b "Löschen",NULL
:PT105			b "Drucker wechseln",NULL
:PT106			b "Hauptverzeichnis",NULL
:PT107			b "Verzeichnis zurück",NULL
:PT108			b "( ) Titel anzeigen",NULL
:PT109_H		b BOLDON
			b "Arbeitsplatz"
			b PLAINTEXT,NULL
:PT110			b " >> Laufwerk A:",NULL
:PT111			b " >> Laufwerk B:",NULL
:PT112			b " >> Laufwerk C:",NULL
:PT113			b " >> Laufwerk D:",NULL
:PT114			b "( ) Größe in KByte",NULL
:PT115			b "( ) Textmodus",NULL
:PT116			b "( ) Details zeigen",NULL
:PT117			b "( ) Anzeige bremsen",NULL
:PT118			b "Nur gelöschte Dateien",NULL
:PT119_H		b BOLDON
			b "Eingabegerät"
			b PLAINTEXT,NULL
:PT120			b "( ) Dateifilter",NULL
:PT121			b "Laufwerk öffnen",NULL
:PT122			b "Verzeichnis erstellen",NULL
:PT123			b "Konvertieren/CVT",NULL
:PT124			b "Verzeichnis öffnen",NULL
:PT125			b "DiskImage erstellen",NULL
:PT126			b "Wiederherstellen",NULL
:PT127			b "Bereinigen",NULL

:PT130			b ">> Sortieren",NULL
:PT131			b "Dateiname",NULL
:PT132			b "Dateigröße",NULL
:PT133			b "Datum Alt->Neu",NULL
:PT134			b "Datum Neu->Alt",NULL
:PT135			b "Dateityp",NULL
:PT136			b "GEOS-Dateityp",NULL
:PT137			b "Unsortiert",NULL

:PT140			b ">> Auswahl",NULL
:PT141			b "Alle auswählen",NULL
:PT142			b "Auswahl aufheben",NULL

:PT200			b "AppLink löschen",NULL
:PT201			b "AppLink erstellen",NULL
:PT202			b "AppLink umbenennen",NULL

:PT300			b ">> Anzeige",NULL
:PT301			b ">> Laufwerk",NULL

:PT403			b "Eigenschaften",NULL
:PT402			b "Überprüfen",NULL
:PT404			b "Dateien ordnen",NULL
:PT400			b "Löschen",NULL
:PT405			b "Bereinigen",NULL
:PT401			b "Formatieren",NULL

:PT500			b "Alle Dateien",NULL
:PT501			b "Anwendungen",NULL
:PT502			b "Autostart",NULL
:PT503			b "Dokumente",NULL
:PT504			b "Hilfsmittel",NULL
:PT505			b "Zeichensatz",NULL
:PT506			b "Druckertreiber",NULL
:PT507			b "Eingabetreiber",NULL
:PT508			b "BASIC-Programme",NULL
:PT509			b "Systemdateien",NULL

;*** Texte für GEOS-Menü.
;    Hinweis: Ein "_H" am Ende markiert
;    den ersten Eintrag in einem Menü.
;    Hier muss BOLDON gesetzt werden.
:PT900			b "Programme >>",NULL
:PT901			b "Dokumente >>",NULL
:PT902			b "Einstellungen >>",NULL
:PT903			b "Hilfe",NULL
:PT909			b "Beenden >>",NULL

;PT930 -> 501		b "Anwendungen",NULL
;PT931 -> 502		b "AutoStart",NULL
;PT932 -> 504		b "Hilfsmittel",NULL

;PT940 -> 503		b "Dokumente",NULL
:PT941			b "GeoWrite",NULL
:PT942			b "GeoPaint",NULL

:PT950			b "Zurück zu GEOS",NULL
:PT951			b "BASIC starten",NULL
:PT952			b "BASIC-Programm",NULL

:PT910			b "Einstellungen -> GEOS",NULL
;PT911 -> 105		b "Drucker wechseln",NULL
:PT912			b "Eingabegerät wechseln",NULL
:PT913			b "AppLinks speichern",NULL
:PT914			b "Optionen speichern",NULL
:PT915			b "Optionen -> GeoDesk",NULL
:PT916			b "Hintergrundbild wechseln",NULL
:PT917			b "Systemfarben ändern",NULL
:PT918			b "Datum/Uhrzeit ändern",NULL
endif

;*** Breite der GEOS-Menüs in Pixel.
;Wegen der Menüfarben muss der Wert auf
;$x7 oder $xF = volles CARD enden.
if LANG = LANG_DE
:PDWidth		b $67				;000 = PopUp auf DeskTop.
			b $67				;001 = PopUp auf AppLink.
			b $57				;002 = PopUp auf Arbeitsplatz.
			b $6f				;003 = PopUp auf AppLink/Drucker.
			b $67				;004 = PopUp auf AppLink/Lfwk. CMD/SD.
			b $5f				;005 = PopUp auf Arbeitsplatz/Drucker.
			b $57				;006 = PopUp auf Datei in Fenster.
			b $4f				;007 = PopUp auf Fenster/Lfwk.
			b $5f				;008 = PopUp auf Arbeitsplatz/Lfwk. CMD/SD.
			b $67				;009 = PopUp auf Titelzeile/Native Std.
			b $67				;010 = PopUp auf AppLink/Verzeichnis.
			b $67				;011 = Untermenü "Anzeige".
			b $47				;012 = Untermenü "Diskette".
			b $5f				;013 = PopUp auf Arbeitsplatz/Eingabe.
			b $57				;014 = Untermenü "Dateifilter".
			b $4f				;015 = Untermenü "Sortieren".
			b $57				;016 = Untermenü "Auswahl".
			b $67				;017 = PopUp Titelzeile/Native CMD/SD.
			b $67				;018 = PopUp auf AppLink/Lfwk. Std.
			b $4f				;019 = PopUp auf Arbeitsplatz/Lfwk. Std.
			b $5f				;020 = PopUp Titelzeile/SD2IEC Browser.
			b $5f				;021 = PopUp auf gelöschte Datei in Fenster.
endif

;*** Texte für PopUp-Menüs.
if LANG = LANG_EN
:PT050			b "Overlapping",NULL
:PT051			b "Side by side",NULL
:PT052			b "Reload files",NULL
:PT053			b "New view",NULL
:PT054			b "( ) Wallpaper",NULL
:PT055			b "( ) Lock AppLinks",NULL
:PT056			b "Select wallpaper",NULL
:PT057			b "Close windows",NULL

:PT100			b "Open file",NULL
:PT101			b "Switch partition",NULL
:PT102			b "Install new printer",NULL
:PT103			b BOLDON
			b "Printer"
			b PLAINTEXT,NULL
:PT104			b "Delete",NULL
:PT105			b "Switch printer",NULL
:PT106			b "Root directory",NULL
:PT107			b "Parent directory",NULL
:PT108			b "( ) Show titles",NULL
:PT109_H		b BOLDON
			b "My Computer"
			b PLAINTEXT,NULL
:PT110			b " >> Drive A:",NULL
:PT111			b " >> Drive B:",NULL
:PT112			b " >> Drive C:",NULL
:PT113			b " >> Drive D:",NULL
:PT114			b "( ) Size in KBytes",NULL
:PT115			b "( ) Textmode",NULL
:PT116			b "( ) Show details",NULL
:PT117			b "( ) Slow down output",NULL
:PT118			b "Deleted files only",NULL
:PT119_H		b BOLDON
			b "Input device"
			b PLAINTEXT,NULL
:PT120			b "( ) Filter",NULL
:PT121			b "Open drive",NULL
:PT122			b "Create directory",NULL
:PT123			b "Convert/CVT",NULL
:PT124			b "Open directory",NULL
:PT125			b "Create DiskImage",NULL
:PT126			b "Recover file",NULL
:PT127			b "Purge files",NULL

:PT130			b ">> Sort mode",NULL
:PT131			b "Filename",NULL
:PT132			b "Silesize",NULL
:PT133			b "Date Old->New",NULL
:PT134			b "Date New->Old",NULL
:PT135			b "Filetype",NULL
:PT136			b "GEOS-Filetype",NULL
:PT137			b "Unsorted",NULL

:PT140			b ">> Select files",NULL
:PT141			b "Select all",NULL
:PT142			b "Unselect all",NULL

:PT200			b "Delete AppLink",NULL
:PT201			b "Create AppLink",NULL
:PT202			b "Rename AppLink",NULL

:PT300			b ">> View mode",NULL
:PT301			b ">> Disk/Drive",NULL

:PT403			b "Properties",NULL
:PT402			b "Validate",NULL
:PT404			b "Organize files",NULL
:PT400			b "Clear drive",NULL
:PT405			b "Purge data",NULL
:PT401			b "Format disk",NULL

:PT500			b "All files",NULL
:PT501			b "Applications",NULL
:PT502			b "Autoexec files",NULL
:PT503			b "Documents",NULL
:PT504			b "DeskAccessories",NULL
:PT505			b "Fonts",NULL
:PT506			b "Printer driver",NULL
:PT507			b "Input driver",NULL
:PT508			b "BASIC programs",NULL
:PT509			b "System files",NULL

;*** Texte für GEOS-Menü.
;    Hinweis: Ein "_H" am Ende markiert
;    den ersten Eintrag in einem Menü.
;    Hier muss BOLDON gesetzt werden.
:PT900			b "Applications >>",NULL
:PT901			b "Documents >>",NULL
:PT902			b "Settings >>",NULL
:PT903			b "Help",NULL
:PT909			b "Exit GeoDesk >>",NULL

;PT930 -> 501		b "Applications",NULL
;PT931 -> 502		b "Autoexecute",NULL
;PT932 -> 504		b "DeskAccessories",NULL

;PT940 -> 503		b "Documents",NULL
:PT941			b "GeoWrite",NULL
:PT942			b "GeoPaint",NULL

:PT950			b "Exit to GEOS",NULL
:PT951			b "Exit to BASIC",NULL
:PT952			b "BASIC application",NULL

:PT910			b "Settings -> GEOS",NULL
:PT911			b "Select printer driver",NULL
:PT912			b "Select input driver",NULL
:PT913			b "Save AppLinks",NULL
:PT914			b "Save GeoDesk options",NULL
:PT915			b "Options -> GeoDesk",NULL
:PT916			b "Select wallpaper",NULL
:PT917			b "Edit system colors",NULL
:PT918			b "Set date and time",NULL
endif

;*** Breite der GEOS-Menüs in Pixel.
;Wegen der Menüfarben muss der Wert auf
;$x7 oder $xF = volles CARD enden.
if LANG = LANG_EN
:PDWidth		b $5f				;000 = PopUp auf DeskTop.
			b $4f				;001 = PopUp auf AppLink.
			b $4f				;002 = PopUp auf Arbeitsplatz.
			b $57				;003 = PopUp auf AppLink/Drucker.
			b $67				;004 = PopUp auf AppLink/Lfwk. CMD/SD.
			b $5f				;005 = PopUp auf Arbeitsplatz/Drucker.
			b $47				;006 = PopUp auf Datei in Fenster.
			b $4f				;007 = PopUp auf Fenster/Lfwk.
			b $57				;008 = PopUp auf Arbeitsplatz/Lfwk. CMD/SD.
			b $57				;009 = PopUp auf Titelzeile/Native Std.
			b $4f				;010 = PopUp auf AppLink/Verzeichnis.
			b $6f				;011 = Untermenü "Anzeige".
			b $47				;012 = Untermenü "Diskette".
			b $5f				;013 = PopUp auf Arbeitsplatz/Eingabe.
			b $57				;014 = Untermenü "Dateifilter".
			b $4f				;015 = Untermenü "Sortieren".
			b $3f				;016 = Untermenü "Auswahl".
			b $5f				;017 = PopUp Titelzeile/Native CMD/SD.
			b $4f				;018 = PopUp auf AppLink/Lfwk. Std.
			b $3f				;019 = PopUp auf Arbeitsplatz/Lfwk. Std.
			b $5f				;020 = PopUp Titelzeile/SD2IEC Browser.
			b $4f				;021 = PopUp auf gelöschte Datei in Fenster.
endif

;*** GEOS-Hauptmenü.
:MAX_ENTRY_GEOS		= 5
:m01y0			= ((MIN_AREA_BAR_Y-1) - MAX_ENTRY_GEOS*14 -2) & $f8
:m01y1			=  (MIN_AREA_BAR_Y-1)
:m01x0			= MIN_AREA_BAR_X
:m01x1			= $004f
:m01w			= (m01x1 - m01x0 +1)

:MENU_DATA_GEOS		b m01y0
			b m01y1
			w m01x0
			w m01x1

			b MAX_ENTRY_GEOS!VERTICAL

			w PT900				;Anwendungen starten.
			b DYN_SUB_MENU
			w OPEN_MENU_APPL

			w PT901				;Dokumente öffnen.
			b DYN_SUB_MENU
			w OPEN_MENU_DOCS

			w PT902				;Einstellungen.
			b DYN_SUB_MENU
			w OPEN_MENU_SETUP

			w PT903				;Einstellungen.
			b MENU_ACTION
			w OPEN_INFO

			w PT909				;GeoDesk beenden.
			b DYN_SUB_MENU
			w OPEN_MENU_EXIT

;*** Fenster-Menü.
:MAX_ENTRY_SCRN		= 8
:m02y0			= ((MIN_AREA_BAR_Y-1) - MAX_ENTRY_SCRN*14 -2) & $f8
:m02y1			=  (MIN_AREA_BAR_Y-1)
if LANG = LANG_DE
:m02x0			= MAX_AREA_BAR_X-$0057
endif
if LANG = LANG_EN
:m02x0			= MAX_AREA_BAR_X-$004f
endif
:m02x1			= MAX_AREA_BAR_X

:MENU_DATA_SCRN		b m02y0
			b m02y1
			w m02x0
			w m02x1

			b MAX_ENTRY_SCRN!VERTICAL

			w PT109_H			;Arbeitsplatz öffnen.
			b MENU_ACTION
			w EXIT_MENU_SCRN

			w PT110				;Laufwerk A: öffnen.
			b MENU_ACTION
			w PExit_002

			w PT111				;Laufwerk B: öffnen.
			b MENU_ACTION
			w PExit_002

			w PT112				;Laufwerk C: öffnen.
			b MENU_ACTION
			w PExit_002

			w PT113				;Laufwerk D: öffnen.
			b MENU_ACTION
			w PExit_002

			w PT050				;Fenster überlappend.
			b MENU_ACTION
			w EXIT_MENU_SCRN

			w PT051				;Fenster nebeneinander.
			b MENU_ACTION
			w EXIT_MENU_SCRN

			w PT057				;Alle Fenster schließen.
			b MENU_ACTION
			w EXIT_MENU_SCRN

;*** GEOS/Programme
:MAX_ENTRY_APPL		= 3
:m03y0			= ((m01y0 + 32 - MAX_ENTRY_APPL*14 -2) & $f8)  -0 -0
:m03y1			=  (m03y0 + MAX_ENTRY_APPL*16 )                -0 -1
:m03x0			= m01x1  + 1 - (m01w/2)
if LANG = LANG_DE
:m03x1			= m03x0 + $0047
endif
if LANG = LANG_EN
:m03x1			= m03x0 + $004f
endif

:MENU_DATA_APPL		b m03y0
			b m03y1
			w m03x0
			w m03x1

			b MAX_ENTRY_APPL!VERTICAL

			w PT501				;Anwendungen.
			b MENU_ACTION
			w EXIT_MENU_APPL

			w PT502				;AutoExec-Programme.
			b MENU_ACTION
			w EXIT_MENU_APPL

			w PT504				;AutoExec-Programme.
			b MENU_ACTION
			w EXIT_MENU_APPL

;*** GEOS/Dokumente
:MAX_ENTRY_DOCS		= 3
:m04y0			= ((m01y0 + 40 - MAX_ENTRY_DOCS*14 -2) & $f8)  -0 -0
:m04y1			=  (m04y0 + MAX_ENTRY_DOCS*16 )                -0 -1
:m04x0			= m01x1  + 1 - (m01w/2)
:m04x1			= m04x0 + $0037

:MENU_DATA_DOCS		b m04y0
			b m04y1
			w m04x0
			w m04x1

			b MAX_ENTRY_DOCS!VERTICAL

			w PT503				;Dokumente.
			b MENU_ACTION
			w EXIT_MENU_DOCS

			w PT941				;GeoWrite.
			b MENU_ACTION
			w EXIT_MENU_DOCS

			w PT942				;GeoPaint.
			b MENU_ACTION
			w EXIT_MENU_DOCS

;*** GEOS/Beenden
:MAX_ENTRY_EXIT		= 3
:m05y0			= (((MIN_AREA_BAR_Y-1) - MAX_ENTRY_EXIT*14 -2) & $f8) -8 -0
:m05y1			=  (MIN_AREA_BAR_Y-1)                                 -8 -0
:m05x0			= m01x1  + 1 - (m01w/2)
:m05x1			= m05x0 + $0057

:MENU_DATA_EXIT		b m05y0
			b m05y1
			w m05x0
			w m05x1

			b MAX_ENTRY_EXIT!VERTICAL

			w PT950				;Zurück zu GEOS.
			b MENU_ACTION
			w EXIT_MENU_EXIT

			w PT951				;Basic starten.
			b MENU_ACTION
			w EXIT_MENU_EXIT

			w PT952				;Programm starten.
			b MENU_ACTION
			w EXIT_MENU_EXIT

;*** GEOS/Einstellungen
:MAX_ENTRY_SETUP	= 9
:m06y0			= (((MIN_AREA_BAR_Y-1) - MAX_ENTRY_SETUP*14 -2) & $f8) -8 -0
:m06y1			=  (MIN_AREA_BAR_Y-1)                                  -8 -0
:m06x0			= m01x1  + 1 - (m01w/2)
if LANG = LANG_DE
:m06x1			= m06x0 + $0077
endif
if LANG = LANG_EN
:m06x1			= m06x0 + $0067
endif

:MENU_DATA_SETUP	b m06y0
			b m06y1
			w m06x0
			w m06x1

			b MAX_ENTRY_SETUP!VERTICAL

			w PT910				;Einstellungen: GEOS.
			b MENU_ACTION
			w EXIT_MENU_SETUP

			w PT915				;Einstellungen: GeoDesk.
			b MENU_ACTION
			w EXIT_MENU_SETUP

			w PT914				;Einstellungen speichern.
			b MENU_ACTION
			w EXIT_MENU_SETUP

			w PT105				;Drucker wechseln.
			b MENU_ACTION
			w EXIT_MENU_SETUP

			w PT912				;Eingabegerät wechseln.
			b MENU_ACTION
			w EXIT_MENU_SETUP

			w PT917				;Systemfarben ändern.
			b MENU_ACTION
			w EXIT_MENU_SETUP

			w PT916				;Hintergrundbild wechseln.
			b MENU_ACTION
			w EXIT_MENU_SETUP

			w PT913				;AppLinks speichern.
			b MENU_ACTION
			w EXIT_MENU_SETUP

			w PT918				;Systemzeit setzen.
			b MENU_ACTION
			w EXIT_MENU_SETUP

;*** Zeiger auf Menüdaten.
;
;Die Menüdaten sind GEOS PullDownMenüs.
;Die Angaben zu Position/Größe können
;entfallen (werden durch Menüroutine
;automatisch gesetzt).
;
;Die Funktionstabellen entalten je ein
;WORD für jede Routine die aufgerufen
;werden soll, oder den Wert $0000 für
;ein Untermenü.
;
:PDVec			w PD000,PJ000			;PopUp auf DeskTop.
			w PD001,PJ001			;PopUp auf AppLink.
			w PD002,PJ002			;PopUp auf Arbeitsplatz.
			w PD003,PJ003			;PopUp auf AppLink/Drucker.
			w PD004,PJ004			;PopUp auf AppLink/Lfwk. CMD/SD.
			w PD005,PJ005			;PopUp auf Arbeitsplatz/Drucker.
			w PD006,PJ006			;PopUp auf Datei in Fenster.
			w PD007,PJ007			;PopUp auf Fenster/Lfwk.
			w PD008,PJ008			;PopUp auf Arbeitsplatz/Lfwk. CMD/SD.
			w PD009,PJ009			;PopUp auf Titelzeile/Native Std.
			w PD010,PJ010			;PopUp auf AppLink/Verzeichnis.
			w PD011,PJ011			;Untermenü "Anzeige".
			w PD012,PJ012			;Untermenü "Diskette".
			w PD013,PJ013			;PopUp auf Arbeitsplatz/Eingabe.
			w PD014,PJ014			;Untermenü "Dateifilter".
			w PD015,PJ015			;Untermenü "Sortieren".
			w PD016,PJ016			;Untermenü "Auswahl".
			w PD017,PJ017			;PopUp Titelzeile/Native CMD/SD.
			w PD018,PJ018			;PopUp auf AppLink/Lfwk. Std.
			w PD019,PJ019			;PopUp auf Arbeitsplatz/Lfwk. Std.
			w PD020,PJ020			;PopUp Titelzeile/SD2IEC Browser.
			w PD021,PJ021			;PopUp auf gelöschte Datei in Fenster.

;*** PopUp auf DeskTop.
:PD000			b $00,$00
			w $0000,$0000

			b 7!VERTICAL

			w PT050				;Fenster überlappend.
			b MENU_ACTION
			w PExit_000

			w PT051				;Fenster Nebeneinander.
			b MENU_ACTION
			w PExit_000

			w PT056				;Hintergrundbild ändern.
			b MENU_ACTION
			w PExit_000

			w PT054				;Hintergrundbild ein/aus.
			b MENU_ACTION
			w PExit_000

			w PT108				;AppLink-Titel anzeigen.
			b MENU_ACTION
			w PExit_000

			w PT055				;AppLinks sperren.
			b MENU_ACTION
			w PExit_000

			w PT057				;Alle Fenster schließen.
			b MENU_ACTION
			w PExit_000

:PJ000			w WM_FUNC_SORT
			w WM_FUNC_POS
			w MOD_OPEN_BACKSCR
			w PF_BACK_SCREEN
			w PF_VIEW_ALTITLE
			w PF_LOCK_APPLINK
			w WM_CLOSE_ALL_WIN

;*** PopUp auf AppLink.
:PD001			b $00,$00
			w $0000,$0000

			b 3!VERTICAL

			w PT202				;AppLink umbenennen.
			b MENU_ACTION
			w PExit_001

			w PT100				;AppLink öffnen.
			b MENU_ACTION
			w PExit_001

			w PT200				;AppLink löschen.
			b MENU_ACTION
			w PExit_001

:PJ001			w AL_RENAME_ENTRY
			w AL_OPEN_ENTRY
			w AL_DEL_ENTRY

;*** PopUp auf Arbeitsplatz.
:PD002			b $00,$00
			w $0000,$0000

			b 5!VERTICAL

			w PT109_H			;Arbeitsplatz öffnen.
			b MENU_ACTION
			w PExit_002

			w PT110				;Laufwerk A: öffnen.
			b MENU_ACTION
			w PExit_002

			w PT111				;Laufwerk B: öffnen.
			b MENU_ACTION
			w PExit_002

			w PT112				;Laufwerk C: öffnen.
			b MENU_ACTION
			w PExit_002

			w PT113				;Laufwerk D: öffnen.
			b MENU_ACTION
			w PExit_002

:PJ002			w AL_OPEN_ENTRY
			w PF_OPEN_DRV_A
			w PF_OPEN_DRV_B
			w PF_OPEN_DRV_C
			w PF_OPEN_DRV_D

;*** PopUp auf AppLink/Drucker.
:PD003			b $00,$00
			w $0000,$0000

			b 4!VERTICAL

			w PT102				;Drucker auswählen.
			b MENU_ACTION
			w PExit_003

			w PT105				;Drucker installieren.
			b MENU_ACTION
			w PExit_003

			w PT200				;AppLink löschen.
			b MENU_ACTION
			w PExit_003

			w PT202				;AppLink umbenennen.
			b MENU_ACTION
			w PExit_003

:PJ003			w AL_SWAP_PRINTER
			w AL_OPEN_PRNT
			w AL_DEL_ENTRY
			w AL_RENAME_ENTRY

;*** PopUp auf AppLink/Laufwerk CMD/SD2IEC.
:PD004			b $00,$00
			w $0000,$0000

			b 4!VERTICAL

			w PT202				;AppLink umbenennen.
			b MENU_ACTION
			w PExit_004

			w PT121				;Laufwerk öffnen.
			b MENU_ACTION
			w PExit_004

			w PT101				;Partition/DiskImage wechseln.
			b MENU_ACTION
			w PExit_004

			w PT200				;AppLink löschen.
			b MENU_ACTION
			w PExit_004

:PJ004			w AL_RENAME_ENTRY
			w AL_OPEN_ENTRY
			w AL_OPEN_DSKIMG
			w AL_DEL_ENTRY

;*** PopUp auf Arbeitsplatz/Drucker.
:PD005			b $00,$00
			w $0000,$0000

			b 2!VERTICAL

			w PT103				;Drucker auswählen.
			b MENU_ACTION
			w PExit_005

			w PrntFileName			;Druckername anzeigen/auswählen.
			b MENU_ACTION
			w PExit_005

:PJ005			w AL_SWAP_PRINTER
			w AL_SWAP_PRINTER

;*** PopUp auf Arbeitsplatz/Eingabe.
:PD013			b $00,$00
			w $0000,$0000

			b 2!VERTICAL

			w PT119_H
			b MENU_ACTION
			w PExit_013

			w inputDevName
			b MENU_ACTION
			w PExit_013

:PJ013			w AL_OPEN_INPUT
			w AL_OPEN_INPUT

;*** PopUp auf Datei in Fenster.
:PD006			b $00,$00
			w $0000,$0000

			b 4!VERTICAL

			w PT403				;Datei-Eigenschaften.
			b MENU_ACTION
			w PExit_006

			w PT100				;Datei öffnen.
			b MENU_ACTION
			w PExit_006

			w PT104				;Datei löschen.
			b MENU_ACTION
			w PExit_006

			w PT123				;Datei konvertieren.
			b MENU_ACTION
			w PExit_006

:PJ006			w PF_FILE_INFO
			w PF_OPEN_FILE
			w PF_DEL_FILE
			w PF_CONVERT_FILE

;*** PopUp auf Fenster/Laufwerk.
:PD007			b $00,$00
			w $0000,$0000

			b 8!VERTICAL

			w PT052				;Neu laden.
			b MENU_ACTION
			w PExit_007

			w PT053				;Neue Ansicht.
			b MENU_ACTION
			w PExit_007

			w PT140				;>> Auswahl.
			b DYN_SUB_MENU
			w OPEN_MENU_SELECT

			w PT120				;>> Dateifilter.
			b DYN_SUB_MENU
			w OPEN_MENU_FILTER

			w PT130				;>> Sortieren.
			b DYN_SUB_MENU
			w OPEN_MENU_SORT

			w PT300				;>> Anzeige.
			b DYN_SUB_MENU
			w OPEN_MENU_VOPT

			w PT301				;>> Diskette.
			b DYN_SUB_MENU
			w OPEN_MENU_DISK

			w PT201				;Applink erstellen.
			b MENU_ACTION
			w PExit_007

:PJ007			w PF_RELOAD_DISK
			w PF_NEW_VIEW
			w $0000
			w $0000
			w $0000
			w $0000
			w $0000
			w PF_CREATE_AL

;*** PopUp auf Arbeitsplatz/Laufwerk CMD- oder SD2IEC-Laufwerk.
:PD008			b $00,$00
			w $0000,$0000

			b 7!VERTICAL

			w PT053				;Neue Ansicht.
			b MENU_ACTION
			w PExit_008

			w PT121				;Öffnen.
			b MENU_ACTION
			w PExit_008

			w PT402				;Validate.
			b MENU_ACTION
			w PExit_008

			w PT403				;Disk-Info.
			b MENU_ACTION
			w PExit_008

			w PT101				;Partition/DiskImage wechseln.
			b MENU_ACTION
			w PExit_008

			w PT400				;Diskette löschen.
			b MENU_ACTION
			w PExit_008

			w PT401				;Diskette formatieren.
			b MENU_ACTION
			w PExit_008

:PJ008			w MYCOMP_NEWVIEW
			w MYCOMP_OPENDRV
			w MYCOMP_VALIDATE
			w MYCOMP_DISKINFO
			w MYCOMP_PART
			w MYCOMP_CLRDRV
			w MYCOMP_FRMTDRV

;*** PopUp auf Titel/Native.
:PD009			b $00,$00
			w $0000,$0000

			b 3!VERTICAL

			w PT106				;Hauptverzeichnis.
			b MENU_ACTION
			w PExit_009

			w PT107				;Ein Verzeichnis zurück.
			b MENU_ACTION
			w PExit_009

			w PT122				;Verzeichnis erstellen.
			b MENU_ACTION
			w PExit_009

:PJ009			w PF_OPEN_ROOT
			w PF_OPEN_PARENT
			w PF_CREATE_DIR

;*** PopUp auf AppLink/Verzeichnis.
:PD010			b $00,$00
			w $0000,$0000

			b 3!VERTICAL

			w PT202				;AppLink umbenennen.
			b MENU_ACTION
			w PExit_010

			w PT124				;Verzeichnis öffnen.
			b MENU_ACTION
			w PExit_010

			w PT200				;AppLink löschen.
			b MENU_ACTION
			w PExit_010

:PJ010			w AL_RENAME_ENTRY
			w PF_OPEN_SDIR
			w AL_DEL_ENTRY

;*** Untermenü "Anzeige" auf Fenster/Laufwerk.
:PD011			b $00,$00
			w $0000,$0000

			b 5!VERTICAL

			w PT114				;Größe in KByte/Blocks.
			b MENU_ACTION
			w PExit_011

			w PT115				;Textmodus.
			b MENU_ACTION
			w PExit_011

			w PT116				;Details zeigen.
			b MENU_ACTION
			w PExit_011

			w PT117				;Anzeige bremsen.
			b MENU_ACTION
			w PExit_011

			w PT118				;Anzeige bremsen.
			b MENU_ACTION
			w PExit_011

:PJ011			w PF_VIEW_SIZE
			w PF_VIEW_ICONS
			w PF_VIEW_DETAILS
			w PF_VIEW_SLOWMOVE
			w PF_VIEW_DELFILES

;*** Untermenü "Diskette" auf Fenster/Laufwerk.
:PD012			b $00,$00
			w $0000,$0000

			b 6!VERTICAL

			w PT403				;Eigenschaften.
			b MENU_ACTION
			w PExit_012

			w PT402				;Validate.
			b MENU_ACTION
			w PExit_012

			w PT404				;Dateien ordnen.
			b MENU_ACTION
			w PExit_012

			w PT400				;Disk löschen.
			b MENU_ACTION
			w PExit_012

			w PT405				;Diskette bereinigen.
			b MENU_ACTION
			w PExit_012

			w PT401				;Disk formatieren.
			b MENU_ACTION
			w PExit_012

:PJ012			w MOD_DISKINFO
			w MOD_VALIDATE
			w MOD_DIRSORT
			w MOD_CLRDISK
			w MOD_PURGEDISK
			w PF_FORMAT_DISK

;*** Untermenü "Anzeige/Dateifilter" auf Fenster/Laufwerk.
:PD014			b $00,$00
			w $0000,$0000

			b 10!VERTICAL

			w PT500				;Filter: Alle Dateien.
			b MENU_ACTION
			w PExit_014

			w PT501				;Filter: Anwendungen.
			b MENU_ACTION
			w PExit_014

			w PT502				;Filter: AutoStart.
			b MENU_ACTION
			w PExit_014

			w PT503				;Filter: Dokumente.
			b MENU_ACTION
			w PExit_014

			w PT504				;Filter: Hilfsmittel.
			b MENU_ACTION
			w PExit_014

			w PT505				;Filter: Zeichensätze.
			b MENU_ACTION
			w PExit_014

			w PT506				;Filter: Druckertreiber.
			b MENU_ACTION
			w PExit_014

			w PT507				;Filter: Eingabetreiber.
			b MENU_ACTION
			w PExit_014

			w PT509				;Filter: BASIC-Programme.
			b MENU_ACTION
			w PExit_014

			w PT508				;Filter: BASIC-Programme.
			b MENU_ACTION
			w PExit_014

:PJ014			w PF_FILTER_ALL
			w PF_FILTER_APPS
			w PF_FILTER_EXEC
			w PF_FILTER_DOCS
			w PF_FILTER_DA
			w PF_FILTER_FONT
			w PF_FILTER_PRNT
			w PF_FILTER_INPT
			w PF_FILTER_SYS
			w PF_FILTER_BASIC

;*** Untermenü "Sortieren" auf Fenster/Laufwerk.
:PD015			b $00,$00
			w $0000,$0000

			b 7!VERTICAL

			w PT131				;Sortieren: Name.
			b MENU_ACTION
			w PExit_015

			w PT132				;Sortieren: Dateigröße.
			b MENU_ACTION
			w PExit_015

			w PT133				;Sortieren: Datum Alt->Neu.
			b MENU_ACTION
			w PExit_015

			w PT134				;Sortieren: Datum Neu->Alt.
			b MENU_ACTION
			w PExit_015

			w PT135				;Sortieren: CBM-Dateityp.
			b MENU_ACTION
			w PExit_015

			w PT136				;Sortieren: GEOS-Dateityp.
			b MENU_ACTION
			w PExit_015

			w PT137				;Sortieren: Unsortiert.
			b MENU_ACTION
			w PExit_015

:PJ015			w PF_SORT_NAME
			w PF_SORT_SIZE
			w PF_SORT_DATE_OLD
			w PF_SORT_DATE_NEW
			w PF_SORT_TYPE
			w PF_SORT_GEOS
			w PF_SORT_NONE

;*** Untermenü "Auswahl" auf Fenster/Laufwerk.
:PD016			b $00,$00
			w $0000,$0000

			b 2!VERTICAL

			w PT141				;Auswahl: Alle auswählen.
			b MENU_ACTION
			w PExit_016

			w PT142				;Auswahl: Keine auswählen.
			b MENU_ACTION
			w PExit_016

:PJ016			w PF_SELECT_ALL
			w PF_SELECT_NONE

;*** PopUp auf Titel/CMD-Native.
:PD017			b $00,$00
			w $0000,$0000

			b 4!VERTICAL

			w PT106				;Hauptverzeichnis.
			b MENU_ACTION
			w PExit_017

			w PT107				;Ein Verzeichnis zurück.
			b MENU_ACTION
			w PExit_017

			w PT122				;Verzeichnis erstellen.
			b MENU_ACTION
			w PExit_017

			w PT101				;Partition wechseln.
			b MENU_ACTION
			w PExit_017

:PJ017			w PF_OPEN_ROOT
			w PF_OPEN_PARENT
			w PF_CREATE_DIR
			w PF_SWAP_DSKIMG

;*** PopUp auf AppLink/Laufwerk/Standard.
:PD018			b $00,$00
			w $0000,$0000

			b 3!VERTICAL

			w PT202				;AppLink umbenennen.
			b MENU_ACTION
			w PExit_018

			w PT121				;Laufwerk öffnen.
			b MENU_ACTION
			w PExit_018

			w PT200				;AppLink löschen.
			b MENU_ACTION
			w PExit_018

:PJ018			w AL_RENAME_ENTRY
			w AL_OPEN_ENTRY
			w AL_DEL_ENTRY

;*** PopUp auf Arbeitsplatz/Laufwerk.
:PD019			b $00,$00
			w $0000,$0000

			b 6!VERTICAL

			w PT053				;Neue Ansicht.
			b MENU_ACTION
			w PExit_019

			w PT121				;Öffnen.
			b MENU_ACTION
			w PExit_019

			w PT402				;Validate.
			b MENU_ACTION
			w PExit_019

			w PT403				;DiskInfo.
			b MENU_ACTION
			w PExit_019

			w PT400				;Diskette löschen.
			b MENU_ACTION
			w PExit_019

			w PT401				;Diskette formatieren.
			b MENU_ACTION
			w PExit_019

:PJ019			w MYCOMP_NEWVIEW
			w MYCOMP_OPENDRV
			w MYCOMP_VALIDATE
			w MYCOMP_DISKINFO
			w MYCOMP_CLRDRV
			w MYCOMP_FRMTDRV

;*** PopUp auf Titel/SD2IEC-DiskImage-Browser.
:PD020			b $00,$00
			w $0000,$0000

			b 3!VERTICAL

			w PT106				;Hauptverzeichnis.
			b MENU_ACTION
			w PExit_020

			w PT107				;Ein Verzeichnis zurück.
			b MENU_ACTION
			w PExit_020

			w PT125				;SD-Image erstellen.
			b MENU_ACTION
			w PExit_020

:PJ020			w PF_OPEN_ROOT
			w PF_OPEN_PARENT
			w PF_CREATE_IMG

;*** PopUp auf gelöschte Datei in Fenster.
:PD021			b $00,$00
			w $0000,$0000

			b 3!VERTICAL

			w PT403				;Datei-Eigenschaften.
			b MENU_ACTION
			w PExit_021

			w PT126				;Datei löschen.
			b MENU_ACTION
			w PExit_021

			w PT127				;Datei bereinigen.
			b MENU_ACTION
			w PExit_021

:PJ021			w PF_FILE_INFO
			w MOD_UNDELFILE
			w MOD_CLEANUP
