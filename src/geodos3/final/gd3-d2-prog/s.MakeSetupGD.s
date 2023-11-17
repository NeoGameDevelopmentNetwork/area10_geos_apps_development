; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExt"

;*** Zusätzliche Symboltabellen.
if .p
			t "SymbTab_DBOX"

;--- Bildschirmausgabe.
:PRNT_Y_HEIGHT		= 11
:PRNT_Y_MAX		= 190
:PRNT_X_WIDTH		= 98
:PRNT_Y_START		= 30
:PRNT_X_START		= 16

;--- Laufwerkstreiber-Modus:
;Modus: GD.DISK
;Verwendet die Datei GD.DISK.
:GD_NG_MODE		= FALSE
endif

;*** GEOS-Header.
			n "MakeSetupGD"
			c "MakeSetupGD V1.0"
			t "G3_Sys.Author"
			f APPLICATION
			z $80				;nur GEOS64

			o APP_RAM
			p MainInit

;******************************************************************************
;*** MakeSetupGD - Systemroutinen.
;******************************************************************************
			t "-M3_Make.Core"
			t "-M3_Make.CVT"
			t "-M3_FilesGD3"		;Liste der Dateinamen.
;--- Prüfsummen-Routine.
;Hier wird eine eigene Routine
;eingebunden, da nicht auszuschließen
;ist das andere GEOS-Versionen andere
;CRC-Ergebnisse liefern.
			t "-M3_PatchCRC"		;Prüfsummen-Routine.
:Class_SET		t "src.Setup.Build"		;GEOS-Klasse für SETUP.
:FontG3			v 7,"fnt.GeoDesk"
;******************************************************************************

;******************************************************************************
;*** Speicher für Informationsdatei.
;******************************************************************************
;--- Ergänzung: 03.03.21/M.Kanet
;Muss am Ende von MakeSetupGD stehen,
;da der Datenbereich als VLIR-Datensatz
;gespeichert wird.
:LengthInfoFile		w $0000
:CRC_CODE		w $0000

;*** Speicher für Dateinamen.
:FNameTab1
;******************************************************************************
