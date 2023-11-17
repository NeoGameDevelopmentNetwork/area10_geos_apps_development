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
:EN_SELECT_DIMG		= TRUE

;Auf Mehrfach-Installation testen ?
:EN_CHECK_MINST		= FALSE

;--- Ergänzung: 09.04.21/M.Kanet
;Speicher DiskImage-Verzeichnisliste.
:FileNTab		= BACK_SCR_BASE
:SizeNTab		= 127*17			;BASE_EDITOR_DATA-FileNTab = $1d80
:MaxFileN		= 127				;SizeNTab/17
:FileNTabBuf		= FileNTab + SizeNTab
endif

;*** GEOS-Header.
			n "GD.DISK.C1581"
			t "G3_DDrv.V.Class"

			p JMP_INSTALL

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "C=1581-Laufwerk installieren."
			h "Nur für MegaPatch/GeoDOS V3!"
endif
if Sprache = Englisch
			h "Install a C=1581 drive."
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
:DrvMode		b Drv1581			;Laufwerkstyp.
:DrvType		b Drv1581			;Laufwerksformat (Partitionstyp).
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
:DrvName		b "C=1581"
			b NULL
;******************************************************************************

;******************************************************************************
;*** Laufwerkstreiber.
;******************************************************************************
			e DDRV_SYS_DEVDATA
			d "DiskDev_1581"
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

			t "-DD_InitSD2IEC"
;******************************************************************************
			t "-DD_Dev.C1581"
			t "-DD_Init.DvDisk"
;******************************************************************************

;*** Prüfen ob Laufwerk installiert werden kann.
;Übergabe: AKKU = Laufwerkmodus.
;          xReg = Laufwerksadresse.
;Rückgabe: xReg = $00, Laufwerk kann installiert werden.
:INIT_DEV_TEST		ldx	#NO_ERROR
			txa
			tay
			rts

;*** Variablen.
:drvMode_SD2IEC		b $00

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
:END_INIT		g BASE_EDITOR_DATA_NG
:DSK_INIT_SIZE		= END_INIT - DKDRV_LOAD_ADDR
;******************************************************************************
