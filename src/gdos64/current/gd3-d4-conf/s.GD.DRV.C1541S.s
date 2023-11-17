; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_CROM"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_DDRV"
			t "SymbTab_MMAP"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Externe Labels.
			t "o.DiskCore.ext"

;--- Ergänzung: 04.04.21/M.Kanet
;Laufwerksdaten automatisch speichern ?
:AUTO_SAVE_CONFIG	= FALSE

;Auf "Extended RAM-Laufwerk" testen ?
:EN_TEST_EXTRAM		= FALSE

;Partition/DiskImage auswählen ?
:EN_SELECT_PART		= FALSE
:EN_SELECT_DIMG		= TRUE

;--- Ergänzung: 09.04.21/M.Kanet
;Speicher DiskImage-Verzeichnisliste.
:FileNTab		= BACK_SCR_BASE
:SizeNTab		= 127*17			;BASE_EDITOR_DATA-FileNTab = $1d80
:MaxFileN		= 127				;SizeNTab/17
:FileNTabBuf		= FileNTab + SizeNTab
endif

;*** GEOS-Header.
			n "GD.DISK.C1541S"
			t "opt.DDrv.Class"
			t "opt.Author"
			f DISK_DEVICE
			z $80 ;nur GEOS64

			o DKDRV_LOAD_ADDR
			p _JMP_APPINSTALL

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "C=1541S-Laufwerk installieren."
			h "Nur für GDOS64!"
endif
if LANG = LANG_EN
			h "Install a C=1541S drive."
			h "For GDOS64 only!"
endif

;******************************************************************************
;*** Sprungtabelle.
;******************************************************************************
:_JMP_APPINSTALL	jmp	_DRV_APPINSTALL		;Laufwerk installieren.
:_JMP_CFGINSTALL	jmp	_DRV_CFGINSTALL		;Installation über GD.CONFIG.
:_JMP_TESTDEVICE	jmp	initTestInstall		;Nur Laufwerk testen.
;******************************************************************************
;*** Laufwerksdaten.
;*** (Direkt nach der Sprungtabelle!)
;******************************************************************************
			g DDRV_VAR_START
:DrvAdrGEOS		b $08				;Laufwerksadresse.
:DriveAdr		= DrvAdrGEOS
:DrvMode		b DrvShadow1541			;Laufwerkstyp.
:DrvType		b Drv1541			;Laufwerksformat (Partitionstyp).
;--- Konfigurationsregister:
;%1xxxxxxx = CMDHD-PP-Modus aktiv.
;%x1xxxxxx = CMDHD-PP-Modus wählen.
;%xx1xxxxx = Keine Partition wählen.
:_DDRV_VAR_CONF		b %00000000
;--- Treiberspezifische Register.
;
;******************************************************************************

;******************************************************************************
;*** Titel für Dialogboxen.
;******************************************************************************
			e DDRV_SYS_TITLE
:DlgBoxTitle		b PLAINTEXT,BOLDON
if LANG = LANG_DE
			b "Installation "
endif
if LANG = LANG_EN
			b "Install "
endif
:DrvName		b "C=1541 (Shadow)"
			b NULL
;******************************************************************************

;******************************************************************************
;*** Laufwerkstreiber.
;******************************************************************************
			e DDRV_SYS_DEVDATA
			d "obj.Drv_1541"
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
;******************************************************************************
			t "-DD_Init.Dv41"
			t "-D3_1571Mode"
:InitShadowRAM		t "-D3_InitShadow"		;ShadowRAM initialisieren.
;******************************************************************************

;*** Prüfen ob Laufwerk installiert werden kann.
;Übergabe: AKKU = Laufwerkmodus.
;          xReg = Laufwerksadresse.
;Rückgabe: xReg = $00, Laufwerk kann installiert werden.
:initTestInstall	ldy	#3			;3x64K für 1541/Shadow.
			jsr	_DDC_RAMFIND

;			ldx	#NO_ERROR
			rts

;*** Laufwerkstreiber kopieren.
;RealDrvMode definieren:
;SET_MODE_...
; -> PARTITION/SUBDIR/FASTDISK/SD2IEC
; -> SRAM/CREU/GRAM
:initCopyDriver		lda	DrvMode			;Laufwerksmodus einlesen.
			ldx	DrvAdrGEOS		;GEOS-Laufwerksadresse einlesen.
			ldy	drvMode_SD2IEC
			beq	:1
			ldy	#SET_MODE_SD2IEC
::1			sty	DDRV_SYS_DEVDATA + (Flag_SD2IEC - DISK_BASE)
			jmp	_DDC_DEVPREPARE		;Treiber installieren.

;*** Laufwerkstreiber installieren.
;Übergabe: DrvAdrGEOS = GEOS-Laufwerk A-D/8-11.
;          DrvMode    = Laufwerksmodus $01=1541, $33=RL81...
;Rückgabe: xReg = $00, Laufwerk installiert.
:_DRV_INSTALL		jsr	initCopyDriver		;Treiber installieren.

;--- Laufwerkstreiber in REU speichern.
			lda	DrvAdrGEOS		;Aktuelles Laufwerk festlegen.
			sta	curDevice		;Adresse wird für die Routine
			sta	curDrive		;":InitForDskDvJob" benötigt.

			jsr	InitForDskDvJob		;Laufwerkstreiber in GEOS-Speicher
			jsr	StashRAM		;kopieren.
			jsr	DoneWithDskDvJob

;--- Shadow-Laufwerk einrichten?
			bit	DrvMode			;1541-Cache-Laufwerk ?
			bvc	:2			; => Nein, weiter...

			ldy	#3
			jsr	_DDC_RAMFIND		;Freien RAM-Speicher suchen.

			pha				;Cache-Speicher in REU belegen.
			ldy	#3
			ldx	#%10000000
			jsr	_DDC_RAMALLOC
			pla
			cpx	#NO_ERROR		;Speicher reserviert ?
			bne	:exit			; => Nein, Installationsfehler.

			ldx	DrvAdrGEOS		;Startadresse Cache-Speicher in
			sta	ramBase   -8,x		;REU zwischenspeichern.

			jsr	InitShadowRAM		;Cache-Speicher löschen.

;--- Ergänzung: 28.08.21/M.Kanet
;Shadow-Bit erst nach AllocRAM setzen.
			ldx	DrvAdrGEOS		;Shadow-Bit setzen nachdem der
			lda	driveType -8,x		;Speicher reserviert und auch
			ora	#%01000000		;initialisiert wurde!
			sta	driveType -8,x
			sta	curType

;--- 1571 in den 1541-Modus umschalten.
::2			lda	drvMode_SD2IEC		;SD2IEC-Laufwerk ?
			bne	:done			; => Ja, weiter...
			lda	drvMode_4171		;1571-Laufwerk ?
			beq	:done			; => Nein, weiter...

			ldx	DrvAdrGEOS		;Laufwerksadresse.
			lda	#$00			;1541-Modus.
			jsr	Set1571DkMode		;Laufwerksmodus festlegen.

::done			ldx	#NO_ERROR
::exit			rts				;Ende.

;*** Variablen.
:drvMode_SD2IEC		b $00
:drvMode_4171		b $00

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
:END_INIT		g BASE_DDRV_INFO
:DSK_INIT_SIZE		= END_INIT - DKDRV_LOAD_ADDR
;******************************************************************************
