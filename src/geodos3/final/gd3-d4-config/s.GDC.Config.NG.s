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
;Modus: GD.DISK.xx
;Verwendet StandAlone Laufwerkstreiber.
.GD_NG_MODE		= TRUE
endif

;*** GEOS-Header.
			n "GD.CONFIG"
			t "src.Config.Class"
			t "G3_Sys.Author"
			f AUTO_EXEC
			z $80				;nur GEOS64

			o BASE_EDITOR_MAIN_NG
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

;******************************************************************************
;*** Treiberinformationen initialisieren.
;******************************************************************************
; - Speicher für DISK.CORE löschen.
;   (Kennung für DISK.CORE bleibt bei DESKTOP 2.x im Speicher!)
; - Tabelle mit gültigen Laufwerkstypen initialisieren.
; - Tabelle mit verfügbaren Laufwerkstreibern löschen.
:InitDiskCoreData	jsr	i_FillRam
			w	SIZE_DDRV_INIT_NG + SIZE_DDRV_DATA_NG
			w	BASE_DDRV_INIT
			b	$00

			jsr	i_FillRam		;DiskDataRAM_A/S/B
			w	DDRV_MAX*2 +DDRV_MAX*2 +DDRV_MAX
			w	DRVINF_NG_START
			b	$00

			jsr	i_FillRam		;DiskDrvData
			w	DDRV_MAX
			w	DRVINF_NG_FOUND
			b	$00

			jsr	i_MoveData		;DiskDrvTypes
			w	DskDrvTypes
			w	DRVINF_NG_TYPES
			w	DDRV_MAX

			jsr	i_MoveData		;DiskDrvNames
			w	DskDrvNames
			w	DRVINF_NG_NAMES
			w	DDRV_MAX*17

			rts

;--- Hinweis:
;Die Laufwerkstypen werden beim Start
;von GD.CONFIG an die richtige Adresse
;im Speicher kopiert.
			t "-D3_DrvTypes"
;******************************************************************************
