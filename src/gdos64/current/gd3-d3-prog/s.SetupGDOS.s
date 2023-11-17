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
			t "SymbTab_GRFX"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Modus für PatchCRC.
:MODE_CRC_SETUP		= TRUE
endif

;*** GEOS-Header.
			n "mod.SETUP"
			t "opt.Setup.Class"
			t "opt.Author"
			f APPLICATION
			z $80 ;nur GEOS64

			o APP_RAM
			p MainMenu

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "Installiert GDOS64..."
endif
if LANG = LANG_EN
			h "Install GDOS64..."
endif

;*** Systemdateien.
:ClassSETUP		t "opt.Setup.Build"
:FNameUpdate		b "GD.UPDATE",NULL

;*** UI-Routinen.
			t "-G3_LogoScreen"		;Programm-Logo anzeigen.
			t "-G3_UseFontG3"		;Zeichensatz einbinden.

;*** Dateiliste für Setup-Datei.
			t "v.FilesGDOS"			;Liste der Dateinamen.

;*** Prüfsummen-Routine.
;Hier wird eine eigene Routine
;eingebunden, da nicht auszuschließen
;ist das andere GEOS-Versionen andere
;CRC-Ergebnisse liefern.
			t "-M3_PatchCRC"

;*** Farben für Setup-Menü.
			t "v.MenuColDef"		;Farbdefinitionen.

;*** Setup - Systemroutinen.
			t "-S3_Setup.Core"		;Hauptprogramm.
			t "-S3_Setup.CVT"		;Dateien konvertieren.
			t "-S3_Setup.PRG"		;Programmdateien kopieren.
			t "-S3_Setup.DSK"		;Laufwerkstreiber kopieren.
			t "-S3_Setup.Size"		;Installationsgröße ermitteln.
			t "-S3_Setup.Copy"		;Dateien kopieren.
			t "-S3_Setup.Archiv"		;ArchivDatei-Routinen.
			t "-S3_TxIcnPData"		;Positionsdaten für Icons und Texte.
			t "-S3_Icons"			;System-Icons.

;*** Archiv-Informationen.
:PatchDataTS		b $00,$00
:PatchInfoTS		b $00,$00

:PatchSizeMax		w $0000
:PatchSizeKB		w $0000				;Speicher: "Alle Dateien"
			w $0000				;Speicher: "Systemdateien"
			w $0000				;Speicher: "ReBoot-System"
			w $0000				;Speicher: "Laufwerkstreiber"
			w $0000				;Speicher: "Hintergrund-Bilder"
			w $0000				;Speicher: "Bildschirmschoner"

;*** CRC-Prüfsumme für Archiv.
:CRC_CODE		w $0000				;Prüfsumme.

;*** Zwischenspeicher für Installation.
:FNameTab1
:PackFileSek		= FNameTab1     + (GD3_FILES_NUM * 32) + 1 +3
:PackFileByt		= PackFileSek   + (GD3_FILES_NUM *  2) + 1
:CopyBuffer		= PackFileByt   + (GD3_FILES_NUM *  1) + 1
:DskDvVLIR		= CopyBuffer    + 256
:DskDvVLIR_org		= DskDvVLIR     + 256
:DskInfTab		= DskDvVLIR_org + 256
:DskInf_VLIR		= DskInfTab + 2*254
:DskInf_Modes		= DskInfTab + 3*254
:DskInf_VlirSet		= DskInfTab + 3*254 +64
:DskInf_Names		= DskInfTab + 3*254 +64 +64*2
:FreeSekTab		= DskInfTab + 3*254 +64 +64*2 +64*17
