; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_APPS"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Bildschirmausgabe.
:PRNT_Y_HEIGHT		= 9
:PRNT_Y_MAX		= 198
:PRNT_X_WIDTH		= 78
:PRNT_X_TAB		= 70
:PRNT_Y_START		= 24
:PRNT_X_START		= 4

;--- Modus für PatchCRC.
:MODE_CRC_SETUP		= FALSE
endif

;*** GEOS-Header.
if LANG = LANG_DE
			n "MakeSetupGDOSde"
			c "MkSetupGDOSdV1.1"
			h "Erstellt die Setup-Datei für GDOS64..."
endif
if LANG = LANG_EN
			n "MakeSetupGDOSen"
			c "MkSetupGDOSeV1.1"
			h "Create the setup file for GDOS64..."
endif
			t "opt.Author"
			f APPLICATION
			z $80 ;nur GEOS64

			o APP_RAM
			p MainInit

;*** MakeSetupGDOS - Systemroutinen.
			t "-M3_Make.Core"
			t "-M3_Make.CVT"

;--- Dateiliste für Setup-Datei.
			t "v.FilesGDOS"			;Liste der Dateinamen.

;--- Prüfsummen-Routine.
;Hier wird eine eigene Routine
;eingebunden, da nicht auszuschließen
;ist das andere GEOS-Versionen andere
;CRC-Ergebnisse liefern.
			t "-M3_PatchCRC"		;Prüfsummen-Routine.

;--- GEOS-Klasse für Setup-Datei.
:ClassSETUP		t "opt.Setup.Build"		;GEOS-Klasse für SETUP.

;--- Dateidatum der Setup-Datei.
:bufDateTime		s 5

;*** Speicher für Informationsdatei.
;HINWEIS:
;Muss am Ende von MakeSetupGD stehen,
;da der Datenbereich als VLIR-Datensatz
;gespeichert wird.
:LengthInfoFile		w $0000
:CRC_CODE		w $0000

;*** Speicher für Dateinamen.
:FNameTab1
