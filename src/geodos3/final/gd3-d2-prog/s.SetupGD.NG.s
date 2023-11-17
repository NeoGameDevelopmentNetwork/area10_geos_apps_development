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
			t "SymbTab_COLOR"
			t "SymbTab_DBOX"

;--- Startadresse Kernaldaten.
;Wird für ":SetSerialNumber" benötigt
;um die Adresse der Seriennummer im
;Speicher zu berechnen.
:BOOT1_START		= OS_LOW

;--- Laufwerkstreiber-Modus:
;Modus: GD.DISK.xx
;Verwendet StandAlone Laufwerkstreiber.
:GD_NG_MODE		= TRUE
endif

;*** GEOS-Header.
			n "mod.SMP3_#100"
			t "src.Setup.Class"
			t "G3_Sys.Author"
			f APPLICATION
			z $80				;nur GEOS64

			o APP_RAM
			p MainMenu

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "Installiert GeoDOS64..."
endif
if Sprache = Englisch
			h "Install GeoDOS64..."
endif

;******************************************************************************
;*** Systemdateien.
;******************************************************************************
:ClassSETUP		t "src.Setup.Build"
:FNameUpdate		b "GD.UPDATE",NULL

;*** UI-Routinen.
			t "-G3_LogoScreen"		;Programm-Logo anzeigen.
			t "-G3_UseFontG3"		;Zeichensatz einbinden.

;*** Programmteile einbinden.
			t "-M3_FilesGD3"		;Dateiliste einbinden.
;--- Prüfsummen-Routine.
;Hier wird eine eigene Routine
;eingebunden, da nicht auszuschließen
;ist das andere GEOS-Versionen andere
;CRC-Ergebnisse liefern.
			t "-M3_PatchCRC"
			t "-S3_Setup.Core"		;Hauptprogramm.
			t "-S3_Setup.CVT"		;Dateien konvertieren.
			t "-S3_Setup.PRG"		;Programmdateien kopieren.
			t "-S3_Setup.DSK.NG"		;Laufwerkstreiber kopieren.
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
:PackFileSAdr		= FNameTab1     + (GD3_FILES_NUM * 32) + 1 +3
:CopyBuffer		= PackFileSAdr  + (GD3_FILES_NUM *  4) + 1
:DskDvVLIR		= CopyBuffer    + 256
:DskDvVLIR_org		= DskDvVLIR     + 256
:DskInfTab		= DskDvVLIR_org + 256
:DskInf_VLIR		= DskInfTab + 2*254
:DskInf_Modes		= DskInfTab + 3*254
:DskInf_VlirSet		= DskInfTab + 3*254 +64
:DskInf_Names		= DskInfTab + 3*254 +64 +64*2
:FreeSekTab		= DskInfTab + 3*254 +64 +64*2 +64*17
