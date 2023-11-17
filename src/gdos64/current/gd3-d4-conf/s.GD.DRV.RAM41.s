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
:AUTO_SAVE_CONFIG	= FALSE

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
			n "GD.DISK.RAM41"
			t "opt.DDrv.Class"
			t "opt.Author"
			f DISK_DEVICE
			z $80 ;nur GEOS64

			o DKDRV_LOAD_ADDR
			p _JMP_APPINSTALL

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "RAM1541-Laufwerk installieren."
			h "Nur für GDOS64!"
endif
if LANG = LANG_EN
			h "Install a RAM1541 drive."
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
:DrvMode		b DrvRAM1541			;Laufwerkstyp.
:DrvType		b DrvRAM1541			;Laufwerksformat (Partitionstyp).
;--- Konfigurationsregister:
;%1xxxxxxx = CMDHD-PP-Modus aktiv.
;%x1xxxxxx = CMDHD-PP-Modus wählen.
;%xx1xxxxx = Keine Partition wählen.
:_DDRV_VAR_CONF		b %00100000
;--- Treiberspezifische Register.
:AutoClearBAM		b $00
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
:DrvName		b "RAM1541"
			b NULL
;******************************************************************************

;******************************************************************************
;*** Laufwerkstreiber.
;******************************************************************************
			e DDRV_SYS_DEVDATA
			d "obj.Drv_RAM41"
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
			t "-DD_AskClrBAM"
;******************************************************************************

;*** Prüfen ob Laufwerk installiert werden kann.
;Übergabe: AKKU = Laufwerkmodus.
;          xReg = Laufwerksadresse.
;Rückgabe: xReg = $00, Laufwerk kann installiert werden.
:initTestInstall	ldy	#3			;3x64K für RAM1541.
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
			ldy	#SET_MODE_FASTDISK
			jmp	_DDC_DEVPREPARE		;Treiber installieren.

;*** Laufwerkstreiber installieren.
;Übergabe: DrvAdrGEOS = GEOS-Laufwerk A-D/8-11.
;          DrvMode    = Laufwerksmodus $01=1541, $33=RL81...
;Rückgabe: xReg = $00, Laufwerk installiert.
:_DRV_INSTALL		jsr	initCopyDriver		;Treiber installieren.

;--- RAMBase nicht löschen.
;Wird ggf. durch den Editor gesetzt und
;dazu genutzt, um auf ein gültiges
;Verzeichnis zu prüfen.
;			lda	#$00
;			sta	ramBase -8,x

			txa
			clc
			adc	#"A" -8
			sta	DRIVE_NAME +3

			ldy	#3
			jsr	_DDC_RAMFIND		;Freien RAM-Speicher suchen.

			ldx	DrvAdrGEOS
			ldy	ramBase -8,x		;ramBase vordefiniert?
			beq	:2			; => Nein, weiter...

;--- Ergänzung: 21.08.21/M.Kanet
;Wenn Startadressen der RAM-Laufwerke
;nicht lückenlos sind, dann wurde das
;neue RAM-Laufwerk bisher an einer
;anderen Stelle im GEOS-DACC erstellt.
;Da von GD.CONFIG ":ramBase" an die
;INIT-Routine übergeben wird, kann hier
;nun geprüft weden ob an der Vorgabe
;ein RAM-Laufwerk mit passender Größe
;erstellt werden kann.
;Falls nicht, dann wird das Laufwerk
;ab der erste freien Bank erstellt.
			pha				;Erste freie Speicherbank merken.
			tya				;Vorgabe für erste Speicherbank.
			ldy	#3			;Anzahl Speicherbänke.
			jsr	ramBase_Check		;Speicher prüfen.
			pla
			cpx	#NO_ERROR		;Ist gewünschter Speicher frei?
			bne	:2			; => Nein, weiter...

			ldx	DrvAdrGEOS
			lda	ramBase -8,x		;Vorgabe für erste Speicherbank.

::2			pha				;RAM-Speicher in REU belegen.
			ldy	#3
			ldx	#%10000000
			jsr	_DDC_RAMALLOC
			pla
			cpx	#NO_ERROR		;Speicher reserviert ?
			bne	:exit			; => Nein, Installationsfehler.

			ldx	DrvAdrGEOS		;Startadresse RAM-Speicher in
			sta	ramBase   -8,x		;REU zwischenspeichern.

;--- Laufwerkstreiber in REU speichern.
			lda	DrvAdrGEOS		;Aktuelles Laufwerk festlegen.
			sta	curDevice		;Adresse wird für die Routine
			sta	curDrive		;":InitForDskDvJob" benötigt.

			jsr	InitForDskDvJob		;Laufwerkstreiber in GEOS-Speicher
			jsr	StashRAM		;kopieren.
			jsr	DoneWithDskDvJob

;--- BAM erstellen.
			jsr	CreateBAM		;BAM erstellen.

;			ldx	#NO_ERROR
::exit			rts				;Ende.

;*** RAM-Laufwerk bereits installiert ?
:TestCurBAM		jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Laufwerk initialisieren.

;--- Ergänzung: 18.09.19/M.Kanet
;Da standardmäßig keine GEOS-Disketten mehr erzeugt werden kann der
;GEOS-Format-String nicht als Referenz genutzt werden.
;Byte#2=$41 / Byte#3=$00 verwenden.
if EN_GEOS_DISK = FALSE
			lda	curDirHead +2		;"A" = 1541.
			cmp	#$41
			bne	:52
			ldy	curDirHead +3		;$00 = Einseitig.
			bne	:52
endif

if EN_GEOS_DISK = TRUE
			LoadW	r0,curDirHead +$ad
			LoadW	r1,BAM_41     +$ad
			ldx	#r0L
			ldy	#r1L			;Auf GEOS-Kennung
			lda	#12			;"GEOS-format" testen.
			jsr	CmpFString		;Kennung vorhanden ?
			bne	:52			; => Ja, Directory nicht löschen.
endif

::51			ldx	#NO_ERROR
			b $2c
::52			ldx	#BAD_BAM
			rts

;*** Neue BAM erstellen.
:ClearCurBAM		ldy	#$00			;Speicher für BAM #1 löschen.
			tya
::51			sta	curDirHead,y
			iny
			bne	:51

			ldy	#$bd
::52			dey				;BAM #1 erzeugen.
			lda	BAM_41      ,y
			sta	curDirHead  ,y
			tya
			bne	:52

			jsr	PutDirHead		;BAM auf Diskette speichern.
			txa
			bne	:53

			jsr	ClrDiskSekBuf		;Sektorspeicher löschen.

			lda	#$ff			;Hauptverzeichnis löschen.
			sta	diskBlkBuf +$01
			LoadW	r4 ,diskBlkBuf
			LoadB	r1L,$12
			LoadB	r1H,$01
			jsr	PutBlock
			txa
			bne	:53

if EN_GEOS_DISK = TRUE
			lda	#$13			;Sektor $13/$08 löschen.
			sta	r1L			;Ist Borderblock für DeskTop 2.0!
			lda	#$08
			sta	r1H
			jsr	PutBlock
endif

::53			rts

;*** Sektorspeicher löschen.
:ClrDiskSekBuf		ldy	#$00
			tya
::51			sta	diskBlkBuf,y
			dey
			bne	:51
			rts

;*** BAM für RAM41-Laufwerke.
:BAM_41			b $12,$01,$41,$00,$15,$ff,$ff,$1f
			b $15,$ff,$ff,$1f,$15,$ff,$ff,$1f
			b $15,$ff,$ff,$1f,$15,$ff,$ff,$1f
			b $15,$ff,$ff,$1f,$15,$ff,$ff,$1f
			b $15,$ff,$ff,$1f,$15,$ff,$ff,$1f
			b $15,$ff,$ff,$1f,$15,$ff,$ff,$1f
			b $15,$ff,$ff,$1f,$15,$ff,$ff,$1f
			b $15,$ff,$ff,$1f,$15,$ff,$ff,$1f
			b $15,$ff,$ff,$1f,$15,$ff,$ff,$1f
			b $11,$fc,$ff,$07

;--- Ergänzung: 24.03.21/M.Kanet
;Standardmäßig wird keine GEOS-Diskette mehr erzeugtz,
;daher wird auch kein BorderBlock benötigt.
if EN_GEOS_DISK = FALSE
			b $13,$ff,$ff,$07
endif
if EN_GEOS_DISK = TRUE
			b $12,$ff,$fe,$07
endif

			b $13,$ff,$ff,$07,$13,$ff,$ff,$07
			b $13,$ff,$ff,$07,$13,$ff,$ff,$07
			b $13,$ff,$ff,$07,$12,$ff,$ff,$03
			b $12,$ff,$ff,$03,$12,$ff,$ff,$03
			b $12,$ff,$ff,$03,$12,$ff,$ff,$03
			b $12,$ff,$ff,$03,$11,$ff,$ff,$01
			b $11,$ff,$ff,$01,$11,$ff,$ff,$01
			b $11,$ff,$ff,$01,$11,$ff,$ff,$01
:DRIVE_NAME		b "R","A","M","x","1","5","4","1"
			b $a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
			b $a0,$a0,"R","D",$a0,"2","A",$a0
			b $a0,$a0,$a0

;--- Ergänzung: 18.09.19/M.Kanet
;Standardmäßig keine GEOS-Diskette erzeugen.
if EN_GEOS_DISK = FALSE
:RDrvBorderTS		b $00,$00			;Kein BorderBlock.
			b $00,$00,$00,$00,$00
			b $00,$00,$00,$00,$00,$00,$00
			b $00,$00,$00,$00
endif
if EN_GEOS_DISK = TRUE
:RDrvBorderTS		b $13,$08			;BorderBlock.
			b "G","E","O","S"," "
			b "f","o","r","m","a","t"," "
			b "V","1",".","0"
endif

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
:END_INIT		g BASE_DDRV_INFO
:DSK_INIT_SIZE		= END_INIT - DKDRV_LOAD_ADDR
;******************************************************************************
