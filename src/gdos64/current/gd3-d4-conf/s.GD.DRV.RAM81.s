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
			n "GD.DISK.RAM81"
			t "opt.DDrv.Class"
			t "opt.Author"
			f DISK_DEVICE
			z $80 ;nur GEOS64

			o DKDRV_LOAD_ADDR
			p _JMP_APPINSTALL

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "RAM1581-Laufwerk installieren."
			h "Nur für GDOS64!"
endif
if LANG = LANG_EN
			h "Install a RAM1581 drive."
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
:DrvMode		b DrvRAM1581			;Laufwerkstyp.
:DrvType		b DrvRAM1581			;Laufwerksformat (Partitionstyp).
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
:DrvName		b "RAM1581"
			b NULL
;******************************************************************************

;******************************************************************************
;*** Laufwerkstreiber.
;******************************************************************************
			e DDRV_SYS_DEVDATA
			d "obj.Drv_RAM81"
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
:initTestInstall	ldy	#13			;13x64K für RAM1581.
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

			ldy	#13
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
			ldy	#13			;Anzahl Speicherbänke.
			jsr	ramBase_Check		;Speicher prüfen.
			pla
			cpx	#NO_ERROR		;Ist gewünschter Speicher frei?
			bne	:2			; => Nein, weiter...

			ldx	DrvAdrGEOS
			lda	ramBase -8,x		;Vorgabe für erste Speicherbank.

::2			pha				;RAM-Speicher in REU belegen.
			ldy	#13
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

;--- Diskname prüfen.
;In Ausnahmefällen kann an der Diskname
;fehlerhaft sein. Z.B. erzeugt durch
;ältere geoConvert-Versionen.
			txa				;Fehlercode speichern.
			pha

			lda	DrvAdrGEOS		;Laufwerk aktivieren.
			jsr	SetDevice
			jsr	OpenDisk
			ldx	#r0L
			jsr	GetPtrCurDkNm

			ldy	#$00
			lda	(r0L),y			;Diskettenname gültig ?
			bne	:3			; => Ja, weiter...

			jsr	DefDskNmData		;Diskettenname festlegen.

			jsr	PutDirHead

::3			pla
			tax

;			ldx	#NO_ERROR
::exit			rts				;Ende.

;*** RAM-Laufwerk bereits installiert ?
:TestCurBAM		jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Laufwerk initialisieren.

;--- Ergänzung: 18.09.19/M.Kanet
;Da standardmäßig keine GEOS-Disketten mehr erzeugt werden kann der
;GEOS-Format-String nicht als Referenz genutzt werden.
;Byte#2=$44 / Byte#3=$00 verwenden.
if EN_GEOS_DISK = FALSE
			lda	curDirHead +2		;"D" = 1581.
			cmp	#"D"
			bne	:52
			ldy	curDirHead +3		;$00 = Standard.
			bne	:52
endif

if EN_GEOS_DISK = TRUE
			LoadW	r0,curDirHead +$ad
			LoadW	r1,BAM_81     +$1d
			ldx	#r0L
			ldy	#r1L			;Auf GEOS-Kennung
			lda	#12			;"GEOS-format" testen.
			jsr	CmpFString		;Kennung vorhanden ?
			bne	:52			; => Ja, Directory nicht löschen.
endif

::51			ldx	#NO_ERROR
			rts
::52			ldx	#BAD_BAM
			rts

;*** Neue BAM erstellen.
:ClearCurBAM		ldy	#$00			;BAM Teil #1 definieren.
			tya
::51			sta	curDirHead,y
			iny
			bne	:51

			lda	#$28			;Zeiger auf ersten Verzeichnis-
			sta	curDirHead +$00		;Sektor richten.
			ldx	#$03
			stx	curDirHead +$01
			ldx	#$44
			stx	curDirHead +$02

			sta	r1L
			sty	r1H

			jsr	DefDskNmData

			LoadW	r4,curDirHead
			jsr	PutBlock
			txa
			bne	:55

::54			lda	BAM_81a  ,x
			sta	dir2Head ,x
			inx
			bne	:54

			inc	r1H
			LoadW	r4,dir2Head
			jsr	PutBlock
			txa
			bne	:55

			lda	#$ff			;BAM Teil #3 definieren.
			sta	dir2Head +$01
			stx	dir2Head +$00
			ldy	#$28
			sty	dir2Head +$fa
			sta	dir2Head +$fb
			sta	dir2Head +$fd
			inc	r1H
			jsr	PutBlock
			txa
			bne	:55

			jsr	GetDirHead		;BAM einlesen.
			txa
			bne	:55

			jsr	ClrDiskSekBuf		;Sektorspeicher löschen.

			lda	#$ff			;Ersten Verzeichnissektor löschen.
			sta	diskBlkBuf +$01
			LoadB	r1L,$28
			LoadB	r1H,$03
			LoadW	r4,diskBlkBuf
			jsr	PutBlock
			txa
			bne	:55

if EN_GEOS_DISK = TRUE
			lda	#$27			;Sektor $28/$27 löschen.
			sta	r1H			;Ist Borderblock für DeskTop 2.0!
			jsr	PutBlock
endif

::55			rts

;*** Sektorspeicher löschen.
:ClrDiskSekBuf		ldy	#$00
			tya
::51			sta	diskBlkBuf,y
			dey
			bne	:51
			rts

;*** Diskettenname definieren.
;--- Ergänzung: 06.01.19/M.Kanet
;Standardmäßig Diskname nur ab Byte $90 erstellen.
;Die Routine "-D3_SwapDkNmDat" tauscht 25Bytes aus.
:DefDskNmData		ldy	#0
::51			lda	#$00
			sta	curDirHead +$04,y
			lda	DRIVE_NAME,y
			sta	curDirHead +$90,y
			iny
			cpy	#25
			bcc	:51
			rts

;*** BAM für RAM81-Laufwerk.
;"RAM 1581"/ID=RD
:DRIVE_NAME		b "R","A","M","x","1","5","8","1"
			b $a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
			b $a0,$a0,"R","D",$a0,"3","D",$a0 ;Disk-ID!
			b $a0,$00,$00

;--- Ergänzung: 18.09.19/M.Kanet
;Standardmäßig keine GEOS-Diskette erzeugen.
if EN_GEOS_DISK = FALSE
:RDrvBorderTS		b $00,$00			;Kein BorderBlock.
			b $00,$00,$00,$00,$00
			b $00,$00,$00,$00,$00,$00,$00
			b $00,$00,$00,$00
endif
if EN_GEOS_DISK = TRUE
:RDrvBorderTS		b $28,$27			;BorderBlock.
			b "G","E","O","S"," "
			b "f","o","r","m","a","t"," "
			b "V","1",".","0"
endif

			b $00

;"RAM 1581"/ID=RD
:BAM_81a		b $28,$02,$44,$bb,"R","D",$c0,$00 ;Disk-ID!
			b $00,$00,$00,$00,$00,$00,$00,$00
			b $28,$ff,$ff,$ff,$ff,$ff,$28,$ff
			b $ff,$ff,$ff,$ff,$28,$ff,$ff,$ff
			b $ff,$ff,$28,$ff,$ff,$ff,$ff,$ff
			b $28,$ff,$ff,$ff,$ff,$ff,$28,$ff
			b $ff,$ff,$ff,$ff,$28,$ff,$ff,$ff
			b $ff,$ff,$28,$ff,$ff,$ff,$ff,$ff
			b $28,$ff,$ff,$ff,$ff,$ff,$28,$ff
			b $ff,$ff,$ff,$ff,$28,$ff,$ff,$ff
			b $ff,$ff,$28,$ff,$ff,$ff,$ff,$ff
			b $28,$ff,$ff,$ff,$ff,$ff,$28,$ff
			b $ff,$ff,$ff,$ff,$28,$ff,$ff,$ff
			b $ff,$ff,$28,$ff,$ff,$ff,$ff,$ff
			b $28,$ff,$ff,$ff,$ff,$ff,$28,$ff
			b $ff,$ff,$ff,$ff,$28,$ff,$ff,$ff
			b $ff,$ff,$28,$ff,$ff,$ff,$ff,$ff
			b $28,$ff,$ff,$ff,$ff,$ff,$28,$ff
			b $ff,$ff,$ff,$ff,$28,$ff,$ff,$ff
			b $ff,$ff,$28,$ff,$ff,$ff,$ff,$ff
			b $28,$ff,$ff,$ff,$ff,$ff,$28,$ff
			b $ff,$ff,$ff,$ff,$28,$ff,$ff,$ff
			b $ff,$ff,$28,$ff,$ff,$ff,$ff,$ff
			b $28,$ff,$ff,$ff,$ff,$ff,$28,$ff
			b $ff,$ff,$ff,$ff,$28,$ff,$ff,$ff
			b $ff,$ff,$28,$ff,$ff,$ff,$ff,$ff
			b $28,$ff,$ff,$ff,$ff,$ff,$28,$ff
			b $ff,$ff,$ff,$ff,$28,$ff,$ff,$ff
			b $ff,$ff,$28,$ff,$ff,$ff,$ff,$ff
			b $28,$ff,$ff,$ff,$ff,$ff,$28,$ff
			b $ff,$ff,$ff,$ff,$28,$ff,$ff,$ff
			b $ff,$ff

;--- Ergänzung: 24.03.21/M.Kanet
;Standardmäßig wird keine GEOS-Diskette mehr erzeugtz,
;daher wird auch kein BorderBlock benötigt.
if EN_GEOS_DISK = FALSE
			b $24,$f0,$ff,$ff,$ff,$ff
endif
if EN_GEOS_DISK = TRUE
			b $23,$f0,$ff,$ff,$ff,$7f
endif

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
:END_INIT		g BASE_DDRV_INFO
:DSK_INIT_SIZE		= END_INIT - DKDRV_LOAD_ADDR
;******************************************************************************
