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
:BOOT1_START		= DISK_BASE
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
:GET_RTC_DRIVES		= $0000
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
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_REGISTER
;******************************************************************************
