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
:EN_CHECK_MINST		= FALSE

;--- Ergänzung: 28.03.21/M.Kanet
;Keine GEOS-RAMDisk erstellen.
:EN_GEOS_DISK		= FALSE
endif

;*** GEOS-Header.
			n "GD.DISK.RAM81"
			t "G3_DDrv.V.Class"

			p JMP_INSTALL

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "RAM1581-Laufwerk installieren."
			h "Nur für MegaPatch/GeoDOS V3!"
endif
if Sprache = Englisch
			h "Install a RAM1581 drive."
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
:DrvMode		b DrvRAM1581			;Laufwerkstyp.
:DrvType		b DrvRAM1581			;Laufwerksformat (Partitionstyp).
:AutoClearBAM		b $00
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
:DrvName		b "RAM1581"
			b NULL
;******************************************************************************

;******************************************************************************
;*** Laufwerkstreiber.
;******************************************************************************
			e DDRV_SYS_DEVDATA
			d "DiskDev_RAM81"
;******************************************************************************

;******************************************************************************
;*** Shared code.
;******************************************************************************
			t "-DD_Sys.Install"
			t "-DD_Sys.SaveCfg"

			t "-DD_Err.InstDev"		;Installationsfehler ausgeben.
			t "-DD_Err.InstRAM"		;Fehler: Nicht genügend Speicher.
			t "-G3_HEX2ASCII"		;HEX-Zahl nach ASCII wandeln.
:DrawDBoxTitel		t "-G3_DBoxTitel"		;Titel für Dialogboxen.
			t "-DD_FindDCore"

;			t "-DD_InitSD2IEC"
;******************************************************************************
			t "-DD_Dev.RAM81"
			t "-DD_AskClrBAM"
;******************************************************************************

;*** Prüfen ob Laufwerk installiert werden kann.
;Übergabe: AKKU = Laufwerkmodus.
;          xReg = Laufwerksadresse.
;Rückgabe: xReg = $00, Laufwerk kann installiert werden.
:INIT_DEV_TEST		ldx	#NO_ERROR
			txa
			tay
			rts

;*** Laufwerk am ser.Bus initialisieren.
;Übergabe: DrvAdrGEOS = GEOS-Laufwerk A-D/8-11.
;          DrvMode    = Laufwerksmodus $01=1541, $33=RL81...
;Rückgabe: xReg = $00, Laufwerk am ser.Bus vorhanden.
:InitDiskDrive		ldy	#13			;13x64K für RAM1581.
			jsr	FindFreeRAM

;			ldx	#NO_ERROR
			rts

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
:END_INIT		g BASE_EDITOR_DATA_NG
:DSK_INIT_SIZE		= END_INIT - DKDRV_LOAD_ADDR
;******************************************************************************
