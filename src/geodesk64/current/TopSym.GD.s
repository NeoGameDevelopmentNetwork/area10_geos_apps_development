; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Debug-Modes.
;
;SYSINFO:
;Wenn auf TRUE gesetzt, dann erscheint
;im System-Einstellungen-Menü eine
;zusätzliche Registerkarte "DEBUG".
;Hier werden Speicherinformationen zu
;GeoDesk angezeigt.
;
;Standard: FALSE
;
:DEBUG_SYSINFO		= FALSE

;*** Spracheinstellungen.
;Wird durch assemblieren der Datei:
;  GEODESK-LANG.de (Deutsch) oder
;  GEODESK-LANG.en (Englisch)
;erstellt. Externe Symboltabelle:
;  GEODESK-LANG.ext
;
			t "GEODESK-LANG.ext"

;*** Größe Dateizähler definieren,
;    Max. Anzahl Dateien im RAM.
;Hinweis: Max.160 wegen Icon-Cache!
:MAXENTRY16BIT		= FALSE				;Max. 256 Einträge.
:MAX_DIR_ENTRIES	= 160
;MAXENTRY16BIT 		= TRUE				;Max. 65536 Einträge wenn Speicher verfügbar ;-)
;MAX_DIR_ENTRIES	= 148

;MAX_DIR_ENTRIES	= 7				;Für PagingMode-Test.

;*** VLIR-Modulnummern.
;VLIR_BOOT		= 0
;VLIR_WM		= 1  -1
:VLIR_DESKTOP		= 2  -1
:VLIR_PARTITION		= 3  -1
:VLIR_APPLINK		= 4  -1
:VLIR_FILE_OPEN		= 5  -1
:VLIR_LOAD_FILES	= 6  -1
:VLIR_SAVE_CONFIG	= 7  -1
:VLIR_FILE_INFO		= 8  -1
:VLIR_FILE_DELETE	= 9  -1
:VLIR_NM_DIR		= 10 -1
:VLIR_VALIDATE		= 11 -1
:VLIR_DISKINFO		= 12 -1
:VLIR_CLRDISK		= 13 -1
:VLIR_COPYMOVE		= 14 -1
:VLIR_COLORSETUP	= 15 -1
:VLIR_DISKCOPY		= 16 -1
:VLIR_INFO		= 17 -1
:VLIR_CONVERT		= 18 -1
:VLIR_CREATEIMG		= 19 -1
:VLIR_DIRSORT		= 20 -1
:VLIR_SYSINFO		= 21 -1
:VLIR_SYSTIME		= 22 -1
:VLIR_STATMSG		= 23 -1

;*** Anzahl VLIR-Module ohne BOOT.
;Die Anzahl der Module wird dann in
;den DACC-Speicher geladen.
:GD_VLIR_COUNT		= 23

;*** Startadresse Boot-Loader.
:VLIR_BOOT_START	= $7000
:VLIR_BOOT_SIZE		= $1000

;*** Startadresse Verzeichnis-Daten.
;Zusätzlich 32Bytes für "Weitere Dateien" abziehen.
;Entfällt, ">>Weitere Dateien" ist der 160ste Eintrag.
:BASE_DIR_DATA		= ( OS_VARS - MAX_DIR_ENTRIES * 32 )

;*** AppLink-Typen.
:AL_TYPE_FILE		= $00
:AL_TYPE_DRIVE		= $ff
:AL_TYPE_PRNT		= $fe
:AL_TYPE_SUBDIR		= $fd
:AL_TYPE_MYCOMP		= $80

;*** AppLink: Zeiger auf Datentabelle.
:AL_ID_FILE		= $00
:AL_ID_DRIVE		= $01
:AL_ID_PRNT		= $02
:AL_ID_SUBDIR		= $03

;*** AppLink: $FF = Fensteroptionen speichern.
:AL_WMODE_FILE		= $00
:AL_WMODE_DRIVE		= $ff
:AL_WMODE_PRNT		= $00
:AL_WMODE_SUBDIR	= $ff

;*** Farbe für GeoDesk-Uhr.
:GD_COLOR_CLOCK		= $07

;*** Anzahl Befehle in Spungtabelle ":MAIN".
:GD_JMPTBL_COUNT	= $02

;*** Einsprungadresse für EnterDeskTop.
:GD_ENTER_DT		= APP_RAM +3

;*** Dateityp für "Weitere Dateien".
:GD_MORE_FILES		= $ff

;*** Datei-Auswahl.
:GD_MODE_SELECT		= $ff
:GD_MODE_UNSLCT		= $00
:GD_MODE_MASK		= %11111111

;*** Icon-Cache.
:GD_MODE_ICACHE		= $00
:GD_MODE_NOICON		= $ff

;*** SET_LOAD-Flag.
:GD_LOAD_DISK		= %1000 0000			;Dateien immer von Disk laden.
:GD_TEST_CACHE		= %0100 0000			;Dateien aus Cache oder von Disk.
:GD_SORT_ONLY		= %0011 1111			;Nur Dateien sortieren.
:GD_LOAD_CACHE		= %0000 0000			;Dateien aus Cache laden (Standard).

;*** Ersatz-Zeichen für Sonderzeichen.
:GD_REPLACE_CHAR	= "_"

;*** Statusmeldungen.
;Wegen fehlendem Symbolspeicher als
;HEX-Werte direkt im Code enthalten.
;PRNT_UPDATED		= $c0
;PRNT_NOT_UPDATED	= $80
;INPT_UPDATED		= $c1
;INPT_NOT_UPDATED	= $81
;UNKNOWN_FTYPE		= $82
;FILENAME_ERROR		= $83
;APPL_NOT_FOUND		= $84
;ALNK_NOT_FOUND		= $85
;SKIP_DIRECTORY		= $86
