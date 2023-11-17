; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExtDisk"

;*** GEOS-Header.
			n "mod.MDD_#126"
			t "G3_Disk.V.Class"

;*** Zusätzliche Symboltabellen.
if .p
:DDRV_SYS_DEVDATA	= BASE_DDRV_DATA

;--- Ergänzung: 28.03.21/M.Kanet
;Keine GEOS-RAMDisk erstellen.
:EN_GEOS_DISK		= FALSE
endif

;******************************************************************************
;*** Shared code.
;******************************************************************************
:MAIN			t "-DD_JumpTab"
;******************************************************************************

;******************************************************************************
;*** Laufwerksdaten.
;******************************************************************************
:BEGIN_VAR_DATA
:DrvMode		b $00
:DrvAdrGEOS		b $00
:AutoClearBAM		b $00
:DrvDataSize		s $04				;Größe der letzten RAMNative-Laufwerke.
:SetSizeRRAM		b $00				;Zuletzt eingestellte Größe für RAMNative-Laufwerk.
:END_VAR_DATA
:MinFreeRRAM		b $00				;Adresse erste freie Speicherbank.
:MaxSizeRRAM		b $00				;Max. verfügbarer Speicher für RAMNative-Laufwerk.
;******************************************************************************

;******************************************************************************
;*** Titel für Dialogboxen.
;******************************************************************************
:DlgBoxTitle		b PLAINTEXT,BOLDON
if Sprache = Deutsch
			b "Installation "
endif
if Sprache = Englisch
			b "Install "
endif
			b "RAM NATIVE"
			b NULL
;******************************************************************************

;******************************************************************************
;*** Shared code.
;******************************************************************************
:DrawDBoxTitel		t "-G3_DBoxTitel"
;******************************************************************************
			t "-DD_DDrvPrepare"
			t "-DD_DDrvUnload"
			t "-DD_DDrvClrDat"
;******************************************************************************
			t "-DD_Dev.RAMNM"
			t "-DD_AskClrBAM"
			t "-DD_RDrvNMSize"
;			t "-DD_RDrvNMExist"
			t "-DD_RDrvNMPart"
			t "-DD_RDrvUpdate"
;******************************************************************************

;*** Prüfen ob Laufwerk installiert werden kann.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk kann installiert werden.
:INIT_DEV_TEST		ldy	#$02			;Mind 2x64K erforderlich.
			jmp	FindFreeRAM

;*** Laufwerk installieren.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk installiert.
;			     = $0D, Laufwerkstyp nicht verfügbar.
:INIT_DEV_INSTALL	sta	DrvMode			;Laufwerksdaten speichern.
			stx	DrvAdrGEOS

			jsr	InstallDriver		;Treiber installieren.
			txa
			bne	:exit

			jsr	UpdateDskDrvData	;INIT-Routine im Laufwerkstreiber
							;aktualisieren.
			ldx	#NO_ERROR
::exit			rts

;*** Laufwerk deinstallieren.
;    Übergabe:		xReg = Laufwerksadresse.
:INIT_DEV_REMOVE	stx	DrvAdrGEOS

;			ldx	DrvAdrGEOS
			jsr	DskDev_Unload		;RAM-Speicher freigeben.

			ldx	DrvAdrGEOS
			jmp	DskDev_ClrData		;Laufwerksdaten zurücksetzen.

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
:END_INIT		g BASE_DDRV_INIT + SIZE_DDRV_INIT
:DSK_INIT_SIZE		= END_INIT - BASE_DDRV_INIT
;******************************************************************************
