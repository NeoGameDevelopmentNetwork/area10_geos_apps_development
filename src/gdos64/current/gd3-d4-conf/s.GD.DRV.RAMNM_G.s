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
			t "SymbTab_GRAM"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Externe Labels.
			t "o.DiskCore.ext"

;--- Ergänzung: 04.04.21/M.Kanet
;Laufwerksdaten automatisch speichern ?
:AUTO_SAVE_CONFIG	= FALSE

;Auf "Extended RAM-Laufwerk" testen ?
:EN_TEST_EXTRAM		= TRUE

;Partition/DiskImage auswählen ?
:EN_SELECT_PART		= FALSE
:EN_SELECT_DIMG		= FALSE

;--- Ergänzung: 28.03.21/M.Kanet
;Keine GEOS-RAMDisk erstellen.
:EN_GEOS_DISK		= FALSE
endif

;*** GEOS-Header.
			n "GD.DISK.RAMNM_G"
			t "opt.DDrv.Class"
			t "opt.Author"
			f DISK_DEVICE
			z $80 ;nur GEOS64

			o DKDRV_LOAD_ADDR
			p _JMP_APPINSTALL

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "GeoRAM-Laufwerk installieren."
			h "Nur für GDOS64!"
endif
if LANG = LANG_EN
			h "Install a GeoRAM drive."
			h "For GDOS64 only!"
endif

;******************************************************************************
;*** Sprungtabelle.
;******************************************************************************
:_JMP_APPINSTALL	jmp	_DRV_APPINSTALL		;Laufwerk installieren.
:_JMP_CFGINSTALL	jmp	_DRV_CFGINSTALL		;Installation über GD.CONFIG.
:_JMP_TESTDEVICE	jmp	initTestDevice		;Nur Hardware testen.
;******************************************************************************
;*** Laufwerksdaten.
;*** (Direkt nach der Sprungtabelle!)
;******************************************************************************
			g DDRV_VAR_START
:DrvAdrGEOS		b $08				;Laufwerksadresse.
:DriveAdr		= DrvAdrGEOS
:DrvMode		b DrvRAMNM_GRAM			;Laufwerkstyp.
:DrvType		b DrvRAMNM			;Laufwerksformat (Partitionstyp).
;--- Konfigurationsregister:
;%1xxxxxxx = CMDHD-PP-Modus aktiv.
;%x1xxxxxx = CMDHD-PP-Modus wählen.
;%xx1xxxxx = Keine Partition wählen.
:_DDRV_VAR_CONF		b %00100000
;--- Treiberspezifische Register.
:AutoClearBAM		b $00
:DrvDataSize		s $04				;Größe der letzten RAMNative-Laufwerke.
:SetSizeRRAM		b $00				;Zuletzt eingestellte Größe für RAMNative-Laufwerk.
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
:DrvName		b "GeoRAM/Native"
			b NULL
;******************************************************************************

;******************************************************************************
;*** Laufwerkstreiber.
;******************************************************************************
			e DDRV_SYS_DEVDATA
			d "obj.Drv_RAMNMG"
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
;******************************************************************************
			t "-DD_RDrvNMSize"
			t "-DD_RDrvNMPart"
			t "-DD_AskClrBAM"
;******************************************************************************
			t "-R3_DetectGRAM"
			t "-R3_GetSizeGRAM"
			t "-R3_GetSBnkGRAM"
:EXTRAM_DEV_TEST	= DetectGRAM
;******************************************************************************
			t "-DD_Init.ExtRAMD"
;******************************************************************************

;*** Laufwerk am ser.Bus initialisieren.
;Übergabe: DrvAdrGEOS = GEOS-Laufwerk A-D/8-11.
;          DrvMode    = Laufwerksmodus $01=1541, $33=RL81...
;Rückgabe: xReg = $00, Laufwerk am ser.Bus vorhanden.
:initTestDevice		= DetectGRAM

;*** Prüfen ob Laufwerk installiert werden kann.
;Übergabe: AKKU = Laufwerkmodus.
;          xReg = Laufwerksadresse.
;Rückgabe: xReg = $00, Laufwerk kann installiert werden.
:initTestInstall	ldx	#NO_ERROR
			rts

;*** Laufwerkstreiber kopieren.
;RealDrvMode definieren:
;SET_MODE_...
; -> PARTITION/SUBDIR/FASTDISK/SD2IEC
; -> SRAM/CREU/GRAM
:initCopyDriver		lda	DrvMode			;Laufwerksmodus einlesen.
			ldx	DrvAdrGEOS		;GEOS-Laufwerksadresse einlesen.
			ldy	#SET_MODE_FASTDISK!SET_MODE_SUBDIR!SET_MODE_GRAM
			jmp	_DDC_DEVPREPARE		;Treiber installieren.

;*** Laufwerkstreiber installieren.
;Übergabe: DrvAdrGEOS = GEOS-Laufwerk A-D/8-11.
;          DrvMode    = Laufwerksmodus $01=1541, $33=RL81...
;Rückgabe: xReg = $00, Laufwerk installiert.
:_DRV_INSTALL		lda	#"G"			;Kennung für RAM-Laufwerk/GEOS-DACC.
			ldx	#"E"
			ldy	#"O"
			jsr	SetRDrvName

			jsr	initCopyDriver		;Treiber installieren.

;--- RAMBase nicht löschen.
;Wird ggf. durch den Editor gesetzt und
;dazu genutzt, um auf ein gültiges
;Verzeichnis zu prüfen.
;			lda	#$00
;			sta	ramBase -8,x

;--- Verfügbares RAM ermitteln.
			ldx	DrvAdrGEOS		;Vorgabewert für Größe des
			lda	DrvDataSize -8,x	;RAMNative-Laufwerk setzen.
			beq	:skip_ram
			sta	SetSizeRRAM

::skip_ram		jsr	GRAM_GET_SIZE		;Größe der C=REU ermitteln.
			txa				;Fehler aufgetreten?
			bne	:2			;Ja, Kein Speicher verfügbar...

			lda	GRAM_BANK_VIRT64	;Anzahl 64K-Bänke einlesen.
			b $2c
::2			lda	#$00
			cmp	#$00			;Speicher verfügbar?
			beq	:4			;Nein, Abbruch...
			ldy	ramExpSize		;Zeiger auf erste Bank ermitteln.
			ldx	GEOS_RAM_TYP		;GEOS-DACC-Typ einlesen.
			cpx	#RAM_BBG		;GeoRAM = GEOS-DACC?
			beq	:3			;Ja, Speicher beginnt hinter DACC.
			ldy	#$00			;Nein, Speicher beginnt bei Bank #0.
::3			sty	MinFreeRRAM		;Freien Speicher berechnen.
			cmp	MinFreeRRAM
			bcc	:2
			sta	MaxFreeRRAM
			sec
			sbc	MinFreeRRAM
::4			sta	MaxSizeRRAM
			cmp	#2			;Mind 2x64K verfügbar?
			bcs	:ram_ok			; => Ja, weiter...

			ldx	#NO_FREE_RAM
			rts

;--- Treiber installieren.
::ram_ok		ldx	DrvAdrGEOS		;Laufwerksdaten setzen.
			lda	MinFreeRRAM		;Erste Speicherbank definieren.
			sta	ramBase     -8,x

			lda	GRAM_BANK_SIZE
			sta	GeoRAMBSize		;Bank-Größe in Treiber speichern.

;--- Laufwerkstreiber speichern.
			lda	DrvAdrGEOS		;Aktuelles Laufwerk festlegen.
			sta	curDevice		;Adresse wird für die Routine
			sta	curDrive		;":InitForDskDvJob" benötigt.

			jsr	InitForDskDvJob		;Laufwerkstreiber in GEOS-Speicher
			jsr	StashRAM		;kopieren.
			jsr	DoneWithDskDvJob

;--- Größe des Laufwerks bestimmen.
			jsr	GetCurPartSize		;Laufwerksgröße übernehmen.
			jsr	SetPartSizeData		;Größe festlegen.
			txa				;Abbruch ?
			bne	:cancel			; => Ja, Ende..

			ldx	DrvAdrGEOS
			lda	SetSizeRRAM		;Größe RAMNative-Laufwerk
			cmp	DrvDataSize -8,x	;geändert ?
			beq	:skip_upd		; => Nein, weiter...
			sta	DrvDataSize -8,x	;Neue Vorgabe speichern.

			lda	#TRUE			;Treiber-Einstellungen
			sta	flgUpdDDrvFile		;aktualisieren.

;--- Laufwerk initialisieren.
::skip_upd		jsr	InitRDrvNM		;RAMNative-Laufwerk initialisieren.
;			txa				;Vorgang erfolgreich?
;			beq	:exit			; => Ja, Ende...
;			bne	:exit			; => Nein, Abbruch...
			rts

::cancel		ldx	#CANCEL_ERR		;Abbruch.
;			b $2c
;			ldx	#NO_ERROR
::exit			rts				;Ende.

;*** Variablen.
:MinFreeRRAM		b $00				;Adresse erste freie Speicherbank.
:MaxFreeRRAM		b $00				;Größe ext.Speicher.
:MaxSizeRRAM		b $00				;Max. verfügbarer Speicher für RAMNative-Laufwerk.

;*** Größe der Speicherbänke in der GeoRAM 16/32/64Kb.
;--- Ergänzung: 11.09.18/M.Kanet:
;Dieser Variablenspeicher muss im Hauptprogramm an einer Stelle
;definiert werden der nicht durch das nachladen weiterer Programmteile
;überschrieben wird!
:GRAM_BANK_SIZE		b $00

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
:END_INIT		g BASE_DDRV_INFO
:DSK_INIT_SIZE		= END_INIT - DKDRV_LOAD_ADDR
;******************************************************************************
