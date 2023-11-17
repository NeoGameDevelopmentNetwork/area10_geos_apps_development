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
:DEBUG_SYSINFO		= TRUE

;*** Bildschirmgröße.
:SCRN_WIDTH		= $0140
:SCRN_HEIGHT		= $c8
:SCRN_XCARDS		= 40
:SCRN_XBYTES		= SCRN_XCARDS*8

;*** Größe Dateizähler definieren,
;    Max. Anzahl Dateien im RAM.
:MAX_DIR_ENTRIES	= 160  ;Max.160 wegen Icon-Cache!
;MAX_DIR_ENTRIES	= 7    ;Für PagingMode-Test.

;*** Modul-Nummern.
;Hinweis:
;Die Nummern entsprechen nicht mehr den
;VLIR-Datensätzen, sondern sind laufend
;durchnummeriert!
;GMOD_BOOT		= 0  ;00

:GMOD_GDCORE		= 0  ;10

:GMOD_WMCORE		= 1  ;20
:GMOD_DESKTOP		= 2  ;21

:GEXT_DRAWDTOP		= 3  ;25
:GEXT_START_HC		= 4  ;26
:GEXT_SETINPUT		= 5  ;27
:GEXT_WINFILES		= 6  ;28
:GEXT_SHORTCUT		= 7  ;29

:GMNU_GEOS		= 8  ;30
:GMNU_WIN		= 9  ;31
:GMNU_MYCOMP		= 10 ;32
:GMNU_DTOP		= 11 ;33
:GMNU_ALINK		= 12 ;34
:GMNU_DISK		= 13 ;35
:GMNU_FILE		= 14 ;36
:GMNU_TITLE		= 15 ;37
:GMNU_SD2IEC		= 16 ;38
:GMNU_CBMCOM		= 17 ;39

:GMOD_PARTITION		= 18 ;40
:GMOD_APPLINK		= 19 ;41
:GMOD_FILE_OPEN		= 20 ;42
:GMOD_SWAPBORDER	= 21 ;43
:GMOD_LOAD_FILES	= 22 ;45
:GMOD_BACKSCRN		= 23 ;48

:GMOD_SYSINFO		= 24 ;50
:GMOD_SYSTIME		= 25 ;52
:GMOD_COLORSETUP	= 26 ;53
:GMOD_SAVE_CONFIG	= 27 ;54
:GMOD_SETDRVMODE	= 28 ;55
:GMOD_STATMSG		= 29 ;56

:GMOD_DISKINFO		= 30 ;60
:GMOD_CREATEIMG		= 31 ;61
:GMOD_CLRDISK		= 32 ;62
:GMOD_DISKCOPY		= 33 ;63
:GMOD_VALIDATE		= 34 ;64

:GMOD_FILE_INFO		= 35 ;80
:GMOD_NM_DIR		= 36 ;81
:GMOD_FILE_DELETE	= 37 ;82
:GMOD_COPYMOVE		= 38 ;83

;--- Zusätzliche GEODESK-Module.
:GMOD_INFO		= 39 ;90
:GMOD_DIRSORT		= 40 ;91
:GMOD_FILECVT		= 41 ;92
:GMOD_GPSHOW		= 42 ;93
:GMOD_SENDTO		= 43 ;94
:GMOD_CBMDISK		= 44 ;95
:GMOD_CMDPART		= 45 ;96
:GMOD_ICONMAN		= 46 ;97
:GMOD_SD2IEC		= 47 ;98

;*** Anzahl VLIR-Module ohne BOOT.
;Letzte Modul-Nummer +1 (für BOOT) !!!
;Die Anzahl der Module wird dann in
;den DACC-Speicher geladen.
:GD_VLIR_COUNT		= 48

;*** Startadresse WindowManager.
:BASE_WMCORE		= $6000
:SIZE_WMCORE		= $2000

;*** Startadresse Speicher für Module.
;Hinweis:
;Überlagert den Bereich von WMCORE!
:BASE_EXTDATA		= BASE_WMCORE
:SIZE_EXTDATA		= OS_BASE -BASE_EXTDATA

;*** Menü-Bereich.
:BASE_GDMENU		= $4400
:SIZE_GDMENU		= $0800

;*** Startadresse Verzeichnis-Daten.
:BASE_DIRDATA		= BASE_GDMENU +SIZE_GDMENU

;*** Startadresse VLIR im DACC.
;Bereich $0000-$01FF ist reserviert für
;Original-EnterDeskTop-Routine.
:DACC_GEODESK		= $0200

;*** Optionen/Systemwerte für GeoDesk.
:GDA_OPTIONS		= APP_RAM      ;Speicheradresse Konfiguration Hauptmodul.
:GDS_OPTIONS		= 254          ;254Bytes Optionen.
:GDA_SYSTEM		= GDA_OPTIONS +GDS_OPTIONS  +2
:GDS_SYSTEM		= 256          ;256Bytes Systemwerte.

;*** Startadresse GeoDesk-Hauptmodul.
:BASE_GEODESK		= GDA_SYSTEM +GDS_SYSTEM

;*** Startadresse Boot-Loader.
:BASE_BOOTLOAD		= $7000        ;Ladeadresse Boot-Loader.
:SIZE_BOOTLOAD		= $1000        ;Max. Größe Boot-Loader.

;*** Ladeadresse VLIR-Module.
:BASE_VLIRDATA		= GDA_SYSTEM +GDS_SYSTEM
:SIZE_VLIRDATA		= BASE_BOOTLOAD -BASE_VLIRDATA

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
;
;Siehe auch "s.GD.56.StatMsg".
;
;PRNT_UPDATED		= $80 ! %01000000
;PRNT_NOT_UPDATED	= $80
;INPT_UPDATED		= $81 ! %01000000
;INPT_NOT_UPDATED	= $81
;UNKNOWN_FTYPE		= $82
;FILENAME_ERROR		= $83
;APPL_NOT_FOUND		= $84
;ALNK_NOT_FOUND		= $85
;SKIP_DIRECTORY		= $86
;GMOD_NOT_FOUND		= $87
;SENDTO_DRV_ERR		= $88
