; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "mod.MDD_#126"
			t "G3_SymMacExt"

if Flag64_128 = TRUE_C64
			t "G3_V.Cl.64.Disk"
endif
if Flag64_128 = TRUE_C128
			t "G3_V.Cl.128.Disk"
endif

;--- Ergänzung: 28.03.21/M.Kanet
;Keine GEOS-RAMDisk erstellen.
:EN_GEOS_DISK = FALSE

;******************************************************************************
			t "-DD_JumpTab"
;******************************************************************************
			t "-DD_RDrvNMSize"
			t "-DD_RDrvNMExist"
			t "-DD_RDrvNMPart"
			t "-DD_AskClrBAM"
;******************************************************************************

;*** Prüfen ob Laufwerk installiert werden kann.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk kann installiert werden.
:xTestDriveMode		ldy	#2			;Mind 2x64K erforderlich.
			jmp	GetFreeBankTab

;*** Laufwerk installieren.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk installiert.
;			     = $0D, Laufwerkstyp nicht verfügbar.
:xInstallDrive		sta	DriveMode		;Laufwerksdaten speichern.
			stx	DriveAdr

			jsr	PrepareDskDrv		;Treiber temporär installieren.

			lda	#"R"			;Kennung für RAM-Laufwerk/GEOS-DACC.
			ldx	#"A"
			ldy	#"M"
			jsr	SetRDrvName

;--- Verfügbares RAM ermitteln.
			ldx	DriveAdr		;Vorgabewert für Größe des
			lda	DskSizeA -8,x		;RAMNative-Laufwerk setzen.
			sta	SetSizeRRAM

			jsr	GetMaxSize		;Max. mögliche Größe ermitteln.
			txa				;Laufwerk möglich?
			bne	:11			;Nein, Abbruch.

			lda	MaxSizeRRAM
			cmp	#$02			;Mind 1x64K verfügbar?
			bcs	:21			; => Ja, weiter...
			ldx	#NO_FREE_RAM
::11			rts

;--- Laufwerkstreiber speichern.
::21			jsr	InitForDskDvJob		;Laufwerkstreiber in GEOS-Speicher
			jsr	StashRAM		;kopieren => Aktueller Treiber
			jsr	DoneWithDskDvJob	;immer im erweiterten Speicher!

;--- Größe des Laufwerks bestimmen.
			jsr	GetCurPartSize		;Laufwerksgröße übernehmen.
			jsr	GetPartSize		;Größe festlegen.
			txa				;Abbruch der Installation?
			bne	:42			; => Ja, Ende...

;--- Installation fortsetzen.
::31			lda	MinFreeRRAM		;Adresse erste Speicherbank.

			ldx	DriveAdr
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
			ldy	SetSizeRRAM		;Anzahl Speicherbänke.
			jsr	ramBase_Check		;Speicher prüfen.
			pla
			cpx	#NO_ERROR		;Ist gewünschter Speicher frei?
			bne	:53			; => Nein, weiter...

			ldx	DriveAdr
			lda	ramBase -8,x		;Vorgabe für erste Speicherbank.

::53			pha				;Speicher für Laufwerk in
			ldy	SetSizeRRAM		;GEOS-DACC reservieren.
			jsr	AllocateBankTab
			pla
			cpx	#NO_ERROR		;Speicher reserviert ?
			bne	:43			; => Nein, Installationsfehler.

			ldx	DriveAdr		;Startadresse Laufwerk in
			sta	ramBase -8,x		;GEOS-DACC zwischenspeichern.

;--- Laufwerk initialisieren.
::41			jsr	InitRDrvNM		;RAMNative-Laufwerk initialisieren.
			txa				;Vorgang erfolgreich?
			beq	:44			;Ja, Ende...

			lda	MinFreeRRAM		;Fehler beim erstellen der BAM,
			jsr	DeInstallDrvData	;Laufwerk nicht installiert.

::42			ldx	#DEV_NOT_FOUND
::43			rts

::44			ldx	#NO_ERROR
			rts

;*** Routine zum schreiben von Sektoren.
:WriteSektor		PushW	r1

			dec	r1L
			lda	r1H
			clc
			adc	#$00
			sta	r1H
			lda	r1L
			ldx	curDrive
			adc	ramBase -8,x
			sta	r3L
			lda	#$00
			sta	r1L

			LoadW	r0,diskBlkBuf
			LoadW	r2,$0100
			jsr	StashRAM

			PopW	r1
			ldx	#NO_ERROR
			rts

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
			lda	#SET_MODE_SUBDIR!SET_MODE_FASTDISK
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
:xDeInstallDrive	txa
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	DeInstallDrvData	; => Ja, Laufwerk initialisieren.

			inx				;Zeiger auf Spur $01/02 setzen
			stx	r1L			;und BAM-Sektor mit Laufwerks-
			inx				;größe einlesen.
			stx	r1H
			jsr	GetBlock_dskBuf
			txa				;Diskettenfehler?
			bne	DeInstallDrvData	;Ja, Speicher kann nicht ermittelt
							;werden => Speicher kann nicht
							;mehr freigegeben werden.
			ldx	curDrive
			lda	ramBase     -8,x	;RAM-Speicher wieder
			ldy	diskBlkBuf  +8		;freigeben.
			jsr	FreeBankTab

:DeInstallDrvData	ldx	curDrive
			lda	#$00			;Laufwerksdaten löschen.
			sta	ramBase     -8,x
			sta	driveType   -8,x
			sta	driveData   -8,x
			sta	turboFlags  -8,x
			sta	RealDrvType -8,x
			sta	RealDrvMode -8,x
			tax
			rts

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
			jsr	GetFreeBankTab
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

;*** Systemvariablen.
:DriveMode		b $00
:DriveAdr		b $00
:MinFreeRRAM		b $00

;*** Titelzeile für Dialogbox.
if Sprache = Deutsch
:DlgBoxTitle		b PLAINTEXT,BOLDON
			b "Installation RAM Native",NULL
endif

if Sprache = Englisch
:DlgBoxTitle		b PLAINTEXT,BOLDON
			b "Installation RAM Native",NULL
endif

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
:END_INIT		g BASE_DDRV_INIT + SIZE_DDRV_INIT
:DSK_INIT_SIZE		= END_INIT - BASE_DDRV_INIT
;******************************************************************************
