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
			t "SymbTab_GRFX"
			t "SymbTab_64ROM"
			t "SymbTab_SCPU"
			t "SymbTab_RLNK"
			t "s.GD.BOOT.2.ext"
			t "o.Patch_SCPU.ext"
			t "o.DvRAM_GRAM.ext"

;--- Laufwerkstreiber-Modus:
;Modus: GD.DISK
;Verwendet die Datei GD.DISK.
:GD_NG_MODE		= FALSE

;--- GEOS-BOOT: StashRAM/VerifyRAM
:BOOT_STASHRAM		= StashRAM
:BOOT_VERIFYRAM		= VerifyRAM
endif

;*** GEOS-Header.
			n "GD.BOOT"
			t "G3_Boot.V.Class"
			z $80				;nur GEOS64

			o BASE_GEOSBOOT -2		;BASIC-Start beachten!
			p MainInit

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "Installiert GeoDOS64"
			h "in Ihrem GEOS-System..."
endif
if Sprache = Englisch
			h "Installs GeoDOS64"
			h "in your GEOS-system..."
endif

;*** Füllbytes.
.L_KernelData		w BASE_GEOSBOOT			;DummyBytes, da Programm über
							;BASIC-LOAD geladen wird!!!
;*** Einsprung aus GEOS-Startprogramm.
:InitBootProc		jmp	MainInit

;*** Boot-Informationen einbinden.
;Direkt nach der Sprungtabelle!
;Daten werden durch andere Programme
;direkt an dieser Stelle verändert!
			t "-G3_SysBootData"		;Angaben Boot-Laufwerk.

;******************************************************************************
;*** GD.BOOT - Systemroutinen.
;******************************************************************************
			t "-G3_Core.Boot"		;GD.BOOT-Systemroutinen.
			t "-G3_PrntString"		;Boot-Meldungen ausgeben.
			t "-G3_DataBootInfo"		;Boot-Meldungen.
;******************************************************************************

;******************************************************************************
;*** Systemroutinen GD.BOOT/GD.UPDATE.
;******************************************************************************
			t "-G3_Core.Install"		;Shared Code GD.BOOT/GD.UPDATE.
			t "-G3_SvDACCdev"		;DACC-Typ in Boot-Config speichern.
			t "-G3_InitDevRAM"		;RAM-Treiber installieren.
			t "-G3_InitDevSCPU"		;SuperCPU installieren.
if FALSE
			t "-G3_InitDevHD"		;CMD-HD initialisieren.
endif
;******************************************************************************

;******************************************************************************
;*** Hardware-Erkennung.
;******************************************************************************
;Code darf nicht überschrieben werden!
			t "-G3_CheckSCPU"		;SuperCPU erkennen.
			t "-G3_CheckRLNK"		;RAMLink erkennen.
;******************************************************************************

;******************************************************************************
;*** Der folgende Datenbereich wird auch von "GD.UPDATE" mitverwendet.
;*** Der Datenbereich wird dazu von "GD.UPDATE" nachgeladen.
;******************************************************************************
.S_KernelData		t "-G3_KernalData"
;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
.E_KernelData		g BASE_GEOS_SYS
;******************************************************************************

;******************************************************************************
;*** ACHTUNG!
;*** Alle folgenden Routinen werden beim Start teilweise überschrieben!
;******************************************************************************
			t "-R3_DetectRLNK"
			t "-R3_DetectSCPU"
			t "-R3_DetectCREU"
			t "-R3_DetectGRAM"
			t "-R3_GetSizeSRAM"
			t "-R3_GetSizeCREU"
			t "-R3_GetSizeGRAM"
			t "-R3_GetSBnkGRAM"
			t "-G3_PrntBootInf"
			t "-G3_GetRLPEntry"
			t "-G3_FindRAMExp"
			t "-G3_GetRAMType"
;******************************************************************************
