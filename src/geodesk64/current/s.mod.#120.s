; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Verzeichnis sortieren.
;* Zwei Dateien im Verzeichnis tauschen.

if .p
			t "TopSym"
			t "TopSym.MP3"
			t "TopSym.IO"
			t "TopSym.GD"
			t "TopMac.GD"
			t "s.mod.#101.ext"

;Sortieren von Dateien mit 64Kb
;GEOS-DACC Speicher verwenden.
:SORTMODE64K = TRUE

;Erweiterte Datei-Informationen
;bei Auwahl einer Datei anzeigen.
:SORTFINFO = TRUE
endif

if SORTFINFO = FALSE
:SORTINFO_MODE = 0
endif
if SORTFINFO = TRUE
:SORTINFO_MODE = 1
endif
;*** Benötigter Speicher für SORTFINFO.
;Zahl muss durch 16 teilbar sein!
:SORTFINFO_SIZE = $0160 * SORTINFO_MODE
;*** Anzahl zusätzlicher Registermenü-Einträge.
:SORTFINFO_ENTRIES = SORTINFO_MODE * 3

			n "mod.#120.obj"
			t "-SYS_CLASS.h"
			f DATA
			o VLIR_BASE
			a "Markus Kanet"

:VlirJumpTable		jmp	xSORTDIR
			jmp	xSWAPENTRIES

;*** Programmroutinen.
			t "-120_DirSortMnu"
			t "-120_ChkNmSd1"
			t "-120_ScrollBar16"
			t "-120_SwapEntries"

;*** Gemeinsamer Code für RAM und DACC-Sortierung.
			t "-120_DSortShared"

;*** RAM-Sortierung.
if SORTMODE64K = FALSE
:SORT64K_ENTRIES = 0
			t "-120_DirLdSvRAM"		;Dateien in RAM einlesen.
			t "-120_DSortRAM"

;--- Startadresse Dateinamen.
;Max. 224 Dateien ohne Datei-Info.
;Max. 208 Dateien mit Datei-Info.
:MaxReadSek		= 28 - ((SORTFINFO_SIZE + 255) / 256)
:MaxSortFiles		= MaxReadSek  *8
:DIRSEK_SOURCE		= LD_ADDR_REGISTER - (MaxReadSek * 256)
:FSLCT_TARGET		= DIRSEK_SOURCE - 256
:FLIST_TARGET		= FSLCT_TARGET  - 256
:FSLCT_SOURCE		= FLIST_TARGET  - 256
:FLIST_SOURCE		= FSLCT_SOURCE  - 256
endif

;*** DACC-Sortierung.
if SORTMODE64K = TRUE
:SORT64K_ENTRIES = 1
			t "-120_DirLdSvDACC"		;Dateien in DACC einlesen.
			t "-120_DSortDACC"

;--- Speicherverwaltung.
			t "-SYS_RAM_FREE"
			t "-SYS_RAM_ALLOC"
			t "-SYS_RAM_SHARED"

;--- Startadresse Dateinummern.
;Bit %0-%10 = Dateinummer 0-2047.
;Bit %15    = 1 / Datei markiert.
;Max. 1808 Dateien ohne Datei-Info.
;Max. 1696 Dateien mit Datei-Info.
:MaxReadSek		= 226 - ((SORTFINFO_SIZE + 255) / 256) *8
:MaxSortFiles		= MaxReadSek  *8
:DIRSEK_SOURCE		= diskBlkBuf
:FLIST_TARGET		= LD_ADDR_REGISTER - MaxSortFiles*2
:FLIST_SOURCE		= FLIST_TARGET     - MaxSortFiles*2
endif

;*** Systemroutinen.
			t "-SYS_DISKFILE"
			t "-SYS_HEX2ASCII"
			t "-SYS_STATMSG"

;Hinweis:
;Zum überprüfen der Code-Größe für SORTFINFO das Label FLIST_SOURCE und
;Label END_PROGRAM_CODE als "EXTERN" markieren.
;Die Größe kann dann über die ext.Symboltabelle ermittelt werden.
:END_PROGRAM_CODE	b NULL

;******************************************************************************
;Sicherstellen das genügend Speicher
;für Dateinamen verfügbar ist.
			g FLIST_SOURCE
;******************************************************************************
