; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "mod.MDD_#120"
			t "G3_SymMacExt"

if Flag64_128 = TRUE_C64
			t "G3_V.Cl.64.Disk"
endif
if Flag64_128 = TRUE_C128
			t "G3_V.Cl.128.Disk"
endif

;--- Ergänzung: 28.03.21/M.Kanet
;Keine GEOS-RAMDisk erstellen.
:EN_GEOS_DISK		= FALSE

			t "-DD_JumpTab"

;*** Prüfen ob Laufwerk installiert werden kann.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk kann installiert werden.
:xTestDriveMode		ldy	#3			;3x64K für RAM1541.
			jmp	GetFreeBankTab

;*** Laufwerk installieren.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk installiert.
;			     = $0D, Laufwerkstyp nicht verfügbar.
:xInstallDrive		sta	DriveMode		;Laufwerksdaten speichern.
			stx	DriveAdr

			jsr	PrepareDskDrv		;Treiber temporär installieren.

			lda	DriveAdr
			clc
			adc	#$39
			sta	DRIVE_NAME +3

			jsr	TestDriveMode		;Freien RAM-Speicher testen.
			cpx	#NO_ERROR		;Ist genügend Speicher frei ?
			beq	:52			; => Ja, weiter.

;--- Laufwerk kann nicht installliert werden.
;			ldx	#NO_FREE_RAM
::51			rts

;--- RAM reservieren.
::52			ldx	DriveAdr
			ldy	ramBase -8,x		;ramBase vordefiniert?
			beq	:53			; => Nein, weiter...

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
			ldy	#3			;Anzahl Speicherbänke.
			jsr	ramBase_Check		;Speicher prüfen.
			pla
			cpx	#NO_ERROR		;Ist gewünschter Speicher frei?
			bne	:53			; => Nein, weiter...

			ldx	DriveAdr
			lda	ramBase -8,x		;Vorgabe für erste Speicherbank.

::53			pha				;RAM-Speicher in REU belegen.
			ldy	#3
			jsr	AllocateBankTab
			pla
			cpx	#NO_ERROR		;Speicher reserviert ?
			bne	:51			; => Nein, Installationsfehler.

			ldx	DriveAdr		;Startadresse RAM-Speicher in
			sta	ramBase   -8,x		;REU zwischenspeichern.

;--- Laufwerkstreiber speichern.
			jsr	InitForDskDvJob		;Laufwerkstreiber in REU
			jsr	StashRAM		;kopieren.
			jsr	DoneWithDskDvJob

;--- BAM erstellen.
			jmp	CreateBAM

;*** Laufwerkstreiber vorbereiten.
:PrepareDskDrv		lda	#$00			;Aktuelles Laufwerk zurücksetzen.
			sta	curDevice

			lda	DriveAdr		;GEOS-Laufwerk aktivieren.
			jsr	SetDevice

			ldx	DriveAdr		;Laufwerksdaten setzen.
;			stx	curDrive		;Durch ":SetDevice" gesetzt.
			lda	DriveMode
			sta	RealDrvType -8,x
			sta	BASE_DDRV_DATA + (DiskDrvType - DISK_BASE)
			bmi	:ram_drive		;RAM-Laufwerk ? => Ja, weiter...
::disk_drive		and	#%01000111		;Shadow-Bit und Format isolieren.
			bne	:set_drive_type
::ram_drive		and	#%10000111		;RAM-Bit und Format isolieren.
::set_drive_type	sta	driveType   -8,x	;GEOS-Laufwerkstyp speichern.
			sta	curType
			lda	#SET_MODE_FASTDISK
			sta	RealDrvMode -8,x
;--- RAMBase nicht löschen.
;Wird ggf. durch den Editor gesetzt und
;dazu genutzt, um auf ein gültiges
;Verzeichnis zu prüfen.
;			lda	#$00
;			sta	ramBase     -8,x

;--- Treiber installieren.
			jsr	i_MoveData		;Laufwerkstreiber aktivieren.
			w	BASE_DDRV_DATA
			w	DISK_BASE
			w	SIZE_DDRV_DATA
			rts

;*** Laufwerk deinstallieren.
;    Übergabe:		xReg = Laufwerksadresse.
:xDeInstallDrive	lda	driveType   -8,x	;RAM-Laufwerk installiert ?
			bpl	:51			; => Nein, weiter...

			txa				;RAM-Speicher in der REU wieder
			pha				;freigeben.
			lda	ramBase     -8,x
			ldy	#3
			jsr	FreeBankTab
			pla
			tax

::51			lda	#$00			;Laufwerksdaten löschen.
			sta	ramBase     -8,x
			sta	driveType   -8,x
			sta	driveData   -8,x
			sta	turboFlags  -8,x
			sta	RealDrvType -8,x
			sta	RealDrvMode -8,x
			tax
			rts

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
;Standardmäßig wird keine GEOS-Diskette mehr erzeugt,
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
:DRIVE_NAME		b $52,$41,$4d,$20,$31,$35,$34,$31
			b $a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
			b $a0,$a0,$52,$44,$a0,$32,$41,$a0
			b $a0,$a0,$a0

;--- Ergänzung: 18.09.19/M.Kanet
;Standardmäßig keine GEOS-Diskette erzeugen.
if EN_GEOS_DISK = FALSE
:RDrvBorderTS		b $00,$00
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

;*** Systemvariablen.
:DriveMode		b $00
:DriveAdr		b $00

;*** Dialogbox-Texte.
if Sprache = Deutsch
:DlgBoxTitle		b PLAINTEXT,BOLDON
			b "Installation RAM1541",NULL
endif

if Sprache = Englisch
:DlgBoxTitle		b PLAINTEXT,BOLDON
			b "Installation RAM1541",NULL
endif

;******************************************************************************
			t "-DD_AskClrBAM"
;******************************************************************************

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
:END_INIT		g BASE_DDRV_INIT + SIZE_DDRV_INIT
:DSK_INIT_SIZE		= END_INIT - BASE_DDRV_INIT
;******************************************************************************
