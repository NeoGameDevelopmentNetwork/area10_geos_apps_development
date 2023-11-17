; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExtEdit"

;*** Zusätzliche Symboltabellen.
if .p
			t "SymbTab_64ROM"
			t "SymbTab_SCPU"
			t "SymbTab_DBOX"
			t "src.Config.DMode"

;--- I/O-Register CMD-SmartMouse.
:mport			= $dc01
:mpddr			= $dc03

;--- Startadresse Kernaldaten.
;Wird für ":SetSerialNumber" benötigt
;um die Adresse der Seriennummer im
;Speicher zu berechnen.
:BOOT1_START		= OS_LOW
endif

;*** GEOS-Header.
			n "GD.CONF.GEOS"
			c "GDC.GEOS    V1.0"
			t "G3_Sys.Author"
			f SYSTEM
			z $80				;nur GEOS64

			o BASE_CONFIG_TOOL

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "GEOS-System konfigurieren"
endif
if Sprache = Englisch
			h "Configure GEOS-system"
endif

;******************************************************************************
;*** Sprungtabelle.
;******************************************************************************
:MainInit		jmp	InitMenu
:SaveData		jmp	SaveConfig
:CheckData		ldx	#$00
			rts
;******************************************************************************

;******************************************************************************
;*** GD.GEOS - Systemroutinen.
;******************************************************************************
			t "-GC_GEOS.Core"
;******************************************************************************

;******************************************************************************
;*** GEOS-Uhrzeit setzen.
;******************************************************************************
			t "-GC_RTC"
			t "-GC_RTC_CMD"
			t "-GC_RTC_CMDSM"
			t "-GC_RTC_TC64"
			t "-GC_RTC_U64_IIp"
;******************************************************************************

;******************************************************************************
;*** Alle Laufwerke am ser. Bus ermitteln und Typ feststellen.
;******************************************************************************
			t "-D3_PurgeAllTD"		;TurboDOS abschalten.
			t "-D3_DriveDetect"		;Laufwerkserkennung.
			t "-D3_DvDetectSys"		;Routinen zur Laufwerkserkennung.
			t "-D3_SendComVLen"		;Befehl an Lauferk senden.
			t "-D3_SendComCTRL"		;CONTROL-Codes an Laufwerk senden.
			t "-D3_TestSBusDrv"		;Laufwerk am ser.Bus testen.

if CFG_DRV_DETECT = 1
			t "-D3_DvDetect_V1"		;ROM-basierte Erkennung.
endif
if CFG_DRV_DETECT = 2
			t "-D3_DvDetect_V2"		;Eigenschaften-basierte Erkennung.
			t "-D3_DvDetectCMD"		;Routinen zur Partitionsserkennung.
endif

			t "-DD_GetAllDrive"		;Laufwerkserkennung.

:devInfo		= sysDevInfo
:devGEOS		= sysDevGEOS
:GET_RTC_DRIVES		= xGetAllSerDrives
;******************************************************************************

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_REGISTER
;******************************************************************************
