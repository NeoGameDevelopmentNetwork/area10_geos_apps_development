; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExtDisk"

;*** Zusätzliche Symboltabellen.
if .p
			t "s.GD.DRV.Cor.ext"
			t "ext.DiskCore"

;--- Ergänzung: 04.04.21/M.Kanet
;Laufwerksdaten automatisch speichern ?
:AUTO_SAVE_CONFIG	= FALSE

;Partition/DiskImage auswählen ?
:EN_SELECT_PART		= FALSE
:EN_SELECT_DIMG		= FALSE

;Auf Mehrfach-Installation testen ?
:EN_CHECK_MINST		= TRUE

;--- Ergänzung: 28.03.21/M.Kanet
;Keine GEOS-RAMDisk erstellen.
:EN_GEOS_DISK		= FALSE
endif

;*** GEOS-Header.
			n "GD.DISK.RAMNM_C"
			t "G3_DDrv.V.Class"

			p JMP_INSTALL

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "C=REU-Laufwerk installieren."
			h "Nur für MegaPatch/GeoDOS V3!"
endif
if Sprache = Englisch
			h "Install a C=REU drive."
			h "For MegaPatch/GeoDOS V3 only!"
endif

;******************************************************************************
;*** Sprungtabelle.
;******************************************************************************
			t "-DD_Inc.JmpTab"
;******************************************************************************
;*** Laufwerksdaten.
;*** (Direkt nach der Sprungtabelle!)
;******************************************************************************
			g DDRV_VAR_START
:DrvAdrGEOS		b $08				;Laufwerksadresse.
:DriveAdr		= DrvAdrGEOS
:DrvMode		b DrvRAMNM_CREU			;Laufwerkstyp.
:DrvType		b DrvRAMNM			;Laufwerksformat (Partitionstyp).
:AutoClearBAM		b $00
:DrvDataSize		s $04				;Größe der letzten RAMNative-Laufwerke.
:SetSizeRRAM		b $00				;Zuletzt eingestellte Größe für RAMNative-Laufwerk.
;******************************************************************************

;******************************************************************************
;*** Titel für Dialogboxen.
;******************************************************************************
			e DDRV_SYS_TITLE
:DlgBoxTitle		b PLAINTEXT,BOLDON
if Sprache = Deutsch
			b "Installation "
endif
if Sprache = Englisch
			b "Install "
endif
:DrvName		b "C=REU/Native"
			b NULL
;******************************************************************************

;******************************************************************************
;*** Laufwerkstreiber.
;******************************************************************************
			e DDRV_SYS_DEVDATA
			d "DiskDev_RAMNMC"
;******************************************************************************

;******************************************************************************
;*** Shared code.
;******************************************************************************
			t "-DD_Sys.Install"
			t "-DD_Sys.SaveCfg"

			t "-DD_Err.InstDev"		;Installationsfehler ausgeben.
;			t "-DD_Err.InstRAM"		;Fehler: Nicht genügend Speicher.
			t "-G3_HEX2ASCII"		;HEX-Zahl nach ASCII wandeln.
:DrawDBoxTitel		t "-G3_DBoxTitel"		;Titel für Dialogboxen.
			t "-DD_FindDCore"

;			t "-DD_InitSD2IEC"
;******************************************************************************
			t "-DD_Dev.RAMNM_C"
			t "-DD_RDrvNMSize"
			t "-DD_RDrvNMPart"
			t "-DD_AskClrBAM"
			t "-DD_ChkDrvMInst"
;******************************************************************************
			t "-R3_DetectCREU"
			t "-R3_GetSizeCREU"
;******************************************************************************

;*** Prüfen ob Laufwerk installiert werden kann.
;Übergabe: AKKU = Laufwerkmodus.
;          xReg = Laufwerksadresse.
;Rückgabe: xReg = $00, Laufwerk kann installiert werden.
:INIT_DEV_TEST		= DetectCREU

;*** Laufwerk am ser.Bus initialisieren.
;Übergabe: DrvAdrGEOS = GEOS-Laufwerk A-D/8-11.
;          DrvMode    = Laufwerksmodus $01=1541, $33=RL81...
;Rückgabe: xReg = $00, Laufwerk am ser.Bus vorhanden.
:InitDiskDrive		ldx	#NO_ERROR
			rts

;*** Variablen.
:MinFreeRRAM		b $00				;Adresse erste freie Speicherbank.
:MaxFreeRRAM		b $00				;Größe ext.Speicher.
:MaxSizeRRAM		b $00				;Max. verfügbarer Speicher für RAMNative-Laufwerk.

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
:END_INIT		g BASE_EDITOR_DATA_NG
:DSK_INIT_SIZE		= END_INIT - DKDRV_LOAD_ADDR
;******************************************************************************
