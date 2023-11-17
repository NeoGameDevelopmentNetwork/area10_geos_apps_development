; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "mod.MDD_#170"
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
			t "-R3_DetectSRAM"
			t "-R3_GetSizeSRAM"
if Flag64_128 = TRUE_C64
			t "-D3_DoDISK_SRAM"
endif
if Flag64_128 = TRUE_C128
			t "+D3_DoDISK_SRAM"
endif
			t "-R3_DoDSKOpSRAM"
			t "-R3_SRAM16Bit"
			t "-DD_RDrvNMSize"
			t "-DD_RDrvNMExist"
			t "-DD_RDrvNMPart"
			t "-DD_AskClrBAM"
;******************************************************************************

;*** Prüfen ob Laufwerk installiert werden kann.
;    Rückgabe:		xReg = $00, Laufwerk kann installiert werden.
:xTestDriveMode		= DetectSCPU

;*** Laufwerk installieren.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk installiert.
;			     = $0D, Laufwerkstyp nicht verfügbar.
:xInstallDrive		sta	DriveMode		;Laufwerksdaten speichern.
			stx	DriveAdr

			lda	#"S"			;Kennung für RAM-Laufwerk/GEOS-DACC.
			ldx	#"R"
			ldy	#"C"
			jsr	SetRDrvName

;--- RAMCard suchen.
			jsr	xTestDriveMode		;RAMCard suchen.
			txa				;Installiert?
			beq	:2			; => Nein, Ende...
::1			rts

;--- RAMCard bereits installiert?
::2			lda	DriveMode
			jsr	CheckRDrvExist		;Laufwerk bereits installiert?
			txa
			bne	:1			; => Nein, Ende...

			jsr	PrepareDskDrv		;Treiber temporär installieren.

;--- Verfügbares RAM ermitteln.
			jsr	SRAM_GET_SIZE
			txa
			bne	:11

			lda	SRAM_BANK_COUNT
			b $2c
::11			lda	#$00

;--- Ergänzung: 16.08.18/M.Kanet
;Im Vergleich zu anderen Speichererweiterungen besitzt die RAMCard ein
;internes Speichermanagement. Der von GEOS reservierte Speicher ist hier
;bereits als "belegt" markiert. Die jetzt ermittelte Anzahl der freien
;Speicherbänke steht somit komplett für das SCPU-Laufwerk zur Verfügung.
;			cmp	#$00			;Speicher verfügbar?
;			beq	:11d			;Nein, Abbruch...
;			ldy	ramExpSize		;Zeiger auf erste Bank ermitteln.
;			ldx	GEOS_RAM_TYP		;GEOS-DACC-Typ einlesen.
;			cpx	#RAM_SCPU		;RAMCard = GEOS-DACC?
;			beq	:11c			;Ja, Speicher beginnt hinter DACC.
;			ldy	SRAM_FREE_START		;Erste freie Speicherbank.
;			lda	SRAM_FREE_END		;Letzte freie Speicherbank.
;::11c			sty	MinFreeRRAM		;Freien Speicher berechnen.
;			cmp	MinFreeRRAM
;			bcc	:11
;			sta	MaxFreeRRAM
;			sec
;			sbc	MinFreeRRAM
::11d			sta	MaxSizeRRAM
			cmp	#$02			;Mind 2x64K verfügbar?
			bcs	:21			; => Ja, weiter...
			ldx	#NO_FREE_RAM
			rts

;--- Treiber installieren.
::21			ldx	DriveAdr		;Laufwerksdaten setzen.
			lda	SRAM_FREE_START		;Erste Speicherbank definieren.
			sta	ramBase     -8,x

;--- Laufwerkstreiber speichern.
			jsr	InitForDskDvJob		;Laufwerkstreiber in GEOS-Speicher
			jsr	StashRAM		;kopieren => Aktueller Treiber
			jsr	DoneWithDskDvJob	;immer im erweiterten Speicher!

;--- Größe des Laufwerks bestimmen.
			jsr	GetCurPartSize		;Falls Laufwerk schon einmal
							;installiert, Größe übernehmen.
			jsr	GetPartSize		;Größe festlegen.
			txa				;Abbruch der Installation?
			bne	:31			; => Ja, Ende...

;--- Laufwerk initialisieren.
			lda	SRAM_FREE_START
			jsr	LOCK_SRAM		;RAMCard Speicher reservieren.

			jsr	InitRDrvNM
			txa
			beq	:32

			ldx	MinFreeRRAM		;Fehler beim erstellen der BAM,
			jsr	DeInstallDrvData	;Laufwerk nicht installiert.

::31			ldx	#DEV_NOT_FOUND
			b $2c
::32			ldx	#NO_ERROR
			rts

;*** Routine zum schreiben von Sektoren.
;    StashRAM kann nicht verwendet werden, da evtl. GEOS-DACC nicht im
;    RAM gespeichert ist => Falsche RAM-Treiber!
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

			ldy	#%10010000		;StashRAM.
			jsr	DoRAMOp_DISK		;DoRAMOp/Disktreiber ausführen.

			PopW	r1

			lda	#%01000000		;Kein Fehler...
			ldx	#NO_ERROR
			rts

;*** Speicher in RAMCard reservieren.
;    Übergabe: XReg = Neue erste freie Speicherbank.
:FREE_SRAM		php				;IRQ sperren.
			sei

if Flag64_128 = TRUE_C64
			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#$35
			sta	CPU_DATA
endif
if Flag64_128 = TRUE_C128
			lda	MMU
			pha
			lda	#$7e
			sta	MMU
			lda	RAM_Conf_Reg
			pha
			lda	#$40			;keine CommonArea VIC =
			sta	RAM_Conf_Reg		;Bank1 für REU Transfer
endif

			sta	$d07e			;SuperCPU-Register aktivieren.
			stx	$d27d			;Freien Speicher zurücksetzen.
			sta	$d07f			;SuperCPU-Register abschalten.

if Flag64_128 = TRUE_C64
			pla
			sta	CPU_DATA		;I/O-Bereich ausblenden.
endif
if Flag64_128 = TRUE_C128
			pla
			sta	RAM_Conf_Reg
			pla
			sta	MMU
endif

			plp				;IRQ-Status zurücksetzen.
			rts

;*** Speicher in RAMCard freigeben.
;    Übergabe: -
:LOCK_SRAM		php				;IRQ sperren.
			sei

if Flag64_128 = TRUE_C64
			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#$35
			sta	CPU_DATA
endif
if Flag64_128 = TRUE_C128
			lda	MMU
			pha
			lda	#$7e
			sta	MMU
			lda	RAM_Conf_Reg
			pha
			lda	#$40			;keine CommonArea VIC =
			sta	RAM_Conf_Reg		;Bank1 für REU Transfer
endif

			sta	$d07e			;SuperCPU-Register aktivieren.

			ldy	DriveAdr		;Größe des freien Speichers in
			lda	ramBase   -8,y		;der SuperCPU korrigieren.
			clc
			adc	SetSizeRRAM
			sta	$d27d			;First available Bank.
			lda	#$00
			sta	$d27c			;First available Page.

			sta	$d07f			;SuperCPU-Register abschalten.

if Flag64_128 = TRUE_C64
			pla
			sta	CPU_DATA		;I/O-Bereich ausblenden.
endif
if Flag64_128 = TRUE_C128
			pla
			sta	RAM_Conf_Reg
			pla
			sta	MMU
endif

			plp				;IRQ-Status zurücksetzen.
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
			lda	#SET_MODE_SUBDIR!SET_MODE_FASTDISK!SET_MODE_SRAM
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
			bne	:1			; => Ja, Laufwerk initialisieren.

			inx
			stx	r1L
			inx
			stx	r1H
			jsr	GetBlock_dskBuf

::1			ldy	curDrive
			ldx	ramBase     -8,y	;RAM-Speicher in der REU wieder

:DeInstallDrvData	jsr	FREE_SRAM		;RAMCard Speicher freigeben.

			ldx	curDrive
			lda	#$00			;Laufwerksdaten löschen.
			sta	ramBase     -8,x
			sta	driveType   -8,x
			sta	driveData   -8,x
			sta	turboFlags  -8,x
			sta	RealDrvType -8,x
			sta	RealDrvMode -8,x
			tax
			rts

;*** Systemvariablen.
:DriveMode		b $00
:DriveAdr		b $00
:MinFreeRRAM		b $00
:MaxFreeRRAM		b $00

;*** Titelzeile für Dialogbox.
if Sprache = Deutsch
:DlgBoxTitle		b PLAINTEXT,BOLDON
			b "Installation SuperRAM Native",NULL
endif

if Sprache = Englisch
:DlgBoxTitle		b PLAINTEXT,BOLDON
			b "Installation SuperRAM Native",NULL
endif

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
:END_INIT		g BASE_DDRV_INIT + SIZE_DDRV_INIT
:DSK_INIT_SIZE		= END_INIT - BASE_DDRV_INIT
;******************************************************************************
