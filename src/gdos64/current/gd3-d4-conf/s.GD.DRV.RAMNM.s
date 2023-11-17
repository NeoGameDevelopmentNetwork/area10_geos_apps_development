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
			t "SymbTab_MMAP"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Externe Labels.
			t "o.DiskCore.ext"

;--- Ergänzung: 04.04.21/M.Kanet
;Laufwerksdaten automatisch speichern ?
:AUTO_SAVE_CONFIG	= TRUE

;Auf "Extended RAM-Laufwerk" testen ?
:EN_TEST_EXTRAM		= FALSE

;Partition/DiskImage auswählen ?
:EN_SELECT_PART		= FALSE
:EN_SELECT_DIMG		= FALSE

;--- Ergänzung: 28.03.21/M.Kanet
;Keine GEOS-RAMDisk erstellen.
:EN_GEOS_DISK		= FALSE
endif

;*** GEOS-Header.
			n "GD.DISK.RAMNM"
			t "opt.DDrv.Class"
			t "opt.Author"
			f DISK_DEVICE
			z $80 ;nur GEOS64

			o DKDRV_LOAD_ADDR
			p _JMP_APPINSTALL

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "RAMNative-Laufwerk installieren."
			h "Nur für GDOS64!"
endif
if LANG = LANG_EN
			h "Install a RAMNative drive."
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
:DrvMode		b DrvRAMNM			;Laufwerkstyp.
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
:DrvName		b "RAM/Native"			;Laufwerksname.
			b NULL
;******************************************************************************

;******************************************************************************
;*** Laufwerkstreiber.
;******************************************************************************
			e DDRV_SYS_DEVDATA
			d "obj.Drv_RAMNM"
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
			t "-DD_RDrvNMSize"
;			t "-DD_RDrvNMExist"
			t "-DD_RDrvNMPart"
			t "-DD_AskClrBAM"
;******************************************************************************

;*** Prüfen ob Laufwerk installiert werden kann.
;Übergabe: AKKU = Laufwerkmodus.
;          xReg = Laufwerksadresse.
;Rückgabe: xReg = $00, Laufwerk kann installiert werden.
:initTestInstall	ldy	#2			;Mind 2x64K erforderlich.
			jsr	_DDC_RAMFIND

;			ldx	#NO_ERROR
			rts

;*** Laufwerk am ser.Bus initialisieren.
;Übergabe: DrvAdrGEOS = GEOS-Laufwerk A-D/8-11.
;          DrvMode    = Laufwerksmodus $01=1541, $33=RL81...
;Rückgabe: xReg = $00, Laufwerk am ser.Bus vorhanden.
:initTestDevice		ldx	#NO_ERROR
			rts

;*** Laufwerkstreiber kopieren.
;RealDrvMode definieren:
;SET_MODE_...
; -> PARTITION/SUBDIR/FASTDISK/SD2IEC
; -> SRAM/CREU/GRAM
:initCopyDriver		lda	DrvMode			;Laufwerksmodus einlesen.
			ldx	DrvAdrGEOS		;GEOS-Laufwerksadresse einlesen.
			ldy	#SET_MODE_FASTDISK!SET_MODE_SUBDIR
			jmp	_DDC_DEVPREPARE		;Treiber installieren.

;*** Laufwerkstreiber installieren.
;Übergabe: DrvAdrGEOS = GEOS-Laufwerk A-D/8-11.
;          DrvMode    = Laufwerksmodus $01=1541, $33=RL81...
;Rückgabe: xReg = $00, Laufwerk installiert.
:_DRV_INSTALL		lda	#"R"			;Kennung für RAM-Laufwerk/GEOS-DACC.
			ldx	#"A"
			ldy	#"M"
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

::skip_ram		jsr	GetMaxSize		;Max. mögliche Größe ermitteln.
			txa				;Laufwerk möglich?
			bne	:exit			;Nein, Abbruch.

			lda	MaxSizeRRAM
			cmp	#2			;Mind 2x64K verfügbar?
			bcs	:ram_ok			; => Ja, weiter...

			ldx	#NO_FREE_RAM
			rts

;--- Laufwerkstreiber speichern.
::ram_ok		lda	DrvAdrGEOS		;Aktuelles Laufwerk festlegen.
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

;--- Installation fortsetzen.
			lda	MinFreeRRAM		;Adresse erste Speicherbank.

			ldx	DrvAdrGEOS
			ldy	ramBase -8,x		;ramBase vordefiniert?
			beq	:2			; => Nein, weiter...

;--- Ergänzung: 21.08.21/M.Kanet
;Wenn Startadressen der RAM-Laufwerke
;nicht lückenlos sind, dann wurde das
;neue RAM-Laufwerk bisher an einer
;anderen Stelle im GEOS-DACC erstellt.
;Da vom GEOS.Editor ":ramBase" an die
;INIT-Routine übergeben wird, kann hier
;nun geprüft weden ob an der Vorgabe
;ein RAM-Laufwerk mit passender Größe
;erstellt werden kann.
;Falls nicht, dann wird das Laufwerk
;ab der erste freien Bank erstellt.
			pha				;Erste freie Speicherbank merken.
			tya				;Vorgabe für erste Speicherbank.
			ldy	SetSizeRRAM		;Anzahl Speicherbänke.
			jsr	ramBase_Check		;Speicher prüfen.
			pla
			cpx	#NO_ERROR		;Ist gewünschter Speicher frei?
			bne	:2			; => Nein, weiter...

			ldx	DrvAdrGEOS
			lda	ramBase -8,x		;Vorgabe für erste Speicherbank.

::2			pha				;Speicher für Laufwerk in
			ldy	SetSizeRRAM		;GEOS-DACC reservieren.
			ldx	#%10000000
			jsr	_DDC_RAMALLOC
			pla
			cpx	#NO_ERROR		;Speicher reserviert ?
			bne	:exit			; => Nein, Installationsfehler.

			ldx	DrvAdrGEOS		;Startadresse Laufwerk in
			sta	ramBase -8,x		;GEOS-DACC zwischenspeichern.

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

;*** Max. freien Speicher ermitteln.
;    Rückgabe:    MinFreeRRAM = Startbank für Laufwerk im RAM.
;                 MaxSizeRRAM = Max. Größe für Laufwerk.
;Dazu wird die max. RAM-größe als Startwert gesetzt und dann der Wert
;so lange rediziert bis der größte Speicherblock für ein RAMNative-Laufwerk
;gefunden wurde.
:GetMaxSize		ldy	ramExpSize		;Max. Größe für Laufwerk
			sty	r2L			;ermitteln.

::51			ldy	r2L
			beq	:53
			jsr	_DDC_RAMFIND
			cpx	#NO_ERROR
			beq	:52
			dec	r2L
			jmp	:51

;--- Freien Speicher gefunden.
::52			sta	MinFreeRRAM
			sty	MaxSizeRRAM
			rts

;--- Kein Speicher frei.
::53			ldy	#$00
			sty	MaxSizeRRAM
			ldx	#NO_FREE_RAM
			rts

;*** Variablen.
:MinFreeRRAM		b $00				;Adresse erste freie Speicherbank.
:MaxSizeRRAM		b $00				;Max. verfügbarer Speicher für RAMNative-Laufwerk.

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
:END_INIT		g BASE_DDRV_INFO
:DSK_INIT_SIZE		= END_INIT - DKDRV_LOAD_ADDR
;******************************************************************************
