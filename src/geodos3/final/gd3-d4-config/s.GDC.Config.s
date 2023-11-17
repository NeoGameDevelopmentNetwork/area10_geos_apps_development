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
			t "SymbTab_64ROM"
			t "SymbTab_COLOR"
			t "SymbTab_DBOX"
			t "src.Config.DMode"

;--- Laufwerkstreiber-Modus:
;Modus: GD.DISK
;Verwendet die Datei GD.DISK.
.GD_NG_MODE		= FALSE
endif

;*** GEOS-Header.
			n "GD.CONFIG"
			t "src.Config.Class"
			t "G3_Sys.Author"
			f AUTO_EXEC
			z $80				;nur GEOS64

			o BASE_EDITOR_MAIN
			p InitSetup

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "GEOS/GeoDOS konfigurieren:"
			h "Laufwerke, Drucker usw..."
endif
if Sprache = Englisch
			h "Configure GEOS/GeoDOS:"
			h "Drives, printer and more..."
endif

;******************************************************************************
;*** GD.CONFIG - Systemroutinen.
;******************************************************************************
			t "-GC_Config.Core"
			t "-G3_Kernal2REU"		;Kernal in REU kopieren.
			t "-G3_UseFontG3"		;Neuen Zeichensatz aktivieren.
.DrawDBoxTitel		t "-G3_DBoxTitel"		;Titelzeile in Dialogbox löschen.
.SysHEX2ASCII		t "-G3_HEX2ASCII"		;HEX-Zahl nach ASCII wandeln.
			t "-DD_GetFreeBank"
			t "-DD_AllocBank"
			t "-DD_FreeBank"
;******************************************************************************

;******************************************************************************
;*** Alle Laufwerke am ser. Bus ermitteln und Typ feststellen.
;******************************************************************************
			t "-D3_PurgeAllTD"		;TurboDOS abschalten.
			t "-D3_DriveDetect"		;Laufwerkserkennung.
			t "-D3_DvDetectSys"		;Routinen zur Laufwerkserkennung.
.SendComVLen		t "-D3_SendComVLen"		;Befehl an Lauferk senden.
			t "-D3_SendComCTRL"		;CONTROL-Codes an Laufwerk senden.
			t "-D3_TestSBusDrv"		;Laufwerk am ser.Bus testen.

if CFG_DRV_DETECT = 1
			t "-D3_DvDetect_V1"		;ROM-basierte Erkennung.
endif
if CFG_DRV_DETECT = 2
			t "-D3_DvDetect_V2"		;Eigenschaften-basierte Erkennung.
			t "-D3_DvDetectCMD"		;Routinen zur Partitionsserkennung.
endif

.GetAllSerDrives	t "-DD_GetAllDrive"		;Laufwerkserkennung.

.devInfo		= sysDevInfo
.devGEOS		= sysDevGEOS
;******************************************************************************

;******************************************************************************
;*** Startadresse für Konfigurationsmodule festlegen.
;******************************************************************************
:TEMP
.BASE_CONFIG_TOOL =	((>TEMP) +1) * 256
.BASE_CONFIG_SAVE	=	BASE_CONFIG_TOOL +3
.BASE_CONFIG_TEST	=	BASE_CONFIG_TOOL +6
;******************************************************************************

;******************************************************************************
;*** Auf GD3/MP3 testen.
;******************************************************************************
			t "-G3_FindGD"
;******************************************************************************
