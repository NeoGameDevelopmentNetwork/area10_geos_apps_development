; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "mod.MDD_#174"
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
			t "-R3_DetectGRAM"
			t "-R3_GetSizeGRAM"
			t "-R3_GetSBnkGRAM"
if Flag64_128 = TRUE_C64
			t "-D3_DoDISK_GRAM"
endif
if Flag64_128 = TRUE_C128
			t "+D3_DoDISK_GRAM"
endif
			t "-R3_DoRAMOpGRAM"
			t "-DD_RDrvNMSize"
			t "-DD_RDrvNMExist"
			t "-DD_RDrvNMPart"
			t "-DD_AskClrBAM"
;******************************************************************************

;*** Prüfen ob Laufwerk installiert werden kann.
;    Rückgabe:		xReg = $00, Laufwerk kann installiert werden.
:xTestDriveMode		= DetectGRAM

;*** Laufwerk installieren.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk installiert.
;			     = $0D, Laufwerkstyp nicht verfügbar.
:xInstallDrive		sta	DriveMode		;Laufwerksdaten speichern.
			stx	DriveAdr

			lda	#"G"			;Kennung für RAM-Laufwerk/GEOS-DACC.
			ldx	#"E"
			ldy	#"O"
			jsr	SetRDrvName

;--- GeoRAM suchen.
			jsr	xTestDriveMode		;GeoRAM suchen.
			txa				;Installiert?
			beq	:2			; => Ja, Weiter...
::1			rts

;--- GeoRAM bereits installiert?
::2			lda	DriveMode
			jsr	CheckRDrvExist		;Laufwerk bereits installiert?
			txa
			bne	:1			; => Nein, Ende...

			jsr	PrepareDskDrv		;Treiber temporär installieren.

;--- Verfügbares RAM ermitteln.
			jsr	GRAM_GET_SIZE		;Größe der C=REU ermitteln.
			txa				;Fehler aufgetreten?
			bne	:11			;Ja, Kein Speicher verfügbar...

			lda	GRAM_BANK_VIRT64	;Anzahl 64K-Bänke einlesen.
			b $2c
::11			lda	#$00
			cmp	#$00			;Speicher verfügbar?
			beq	:11d			;Nein, Abbruch...
			ldy	ramExpSize		;Zeiger auf erste Bank ermitteln.
			ldx	GEOS_RAM_TYP		;GEOS-DACC-Typ einlesen.
			cpx	#RAM_BBG		;GeoRAM = GEOS-DACC?
			beq	:11c			;Ja, Speicher beginnt hinter DACC.
			ldy	#$00			;Nein, Speicher beginnt bei Bank #0.
::11c			sty	MinFreeRRAM		;Freien Speicher berechnen.
			cmp	MinFreeRRAM
			bcc	:11
			sta	MaxFreeRRAM
			sec
			sbc	MinFreeRRAM
::11d			sta	MaxSizeRRAM
			cmp	#$02			;Mind 2x64K verfügbar?
			bcs	:21			; => Ja, weiter...
			ldx	#NO_FREE_RAM
			rts

;--- Treiber installieren.
::21			ldx	DriveAdr		;Laufwerksdaten setzen.
			lda	MinFreeRRAM		;Erste Speicherbank definieren.
			sta	ramBase     -8,x

			lda	GRAM_BANK_SIZE
			sta	GeoRAMBSize		;Bank-Größe in Treiber speichern.

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
			jsr	InitRDrvNM
			txa
			beq	:32

			lda	MinFreeRRAM		;Fehler beim erstellen der BAM,
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
			lda	#SET_MODE_SUBDIR!SET_MODE_FASTDISK!SET_MODE_GRAM
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

;*** Systemvariablen.
:DriveMode		b $00
:DriveAdr		b $00
:MinFreeRRAM		b $00
:MaxFreeRRAM		b $00

;*** Größe der Speicherbänke in der GeoRAM 16/32/64Kb.
;--- Ergänzung: 11.09.18/M.Kanet:
;Dieser Variablenspeicher muss im Hauptprogramm an einer Stelle
;definiert werden der nicht durch das nachladen weiterer Programmteile
;überschrieben wird!
:GRAM_BANK_SIZE		b $00

;*** Titelzeile für Dialogbox.
if Sprache = Deutsch
:DlgBoxTitle		b PLAINTEXT,BOLDON
			b "Installation GeoRAM Native",NULL
endif

if Sprache = Englisch
:DlgBoxTitle		b PLAINTEXT,BOLDON
			b "Installation GeoRAM Native",NULL
endif

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
:END_INIT		g BASE_DDRV_INIT + SIZE_DDRV_INIT
:DSK_INIT_SIZE		= END_INIT - BASE_DDRV_INIT
;******************************************************************************
