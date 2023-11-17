; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "mod.MDD_#160"
			t "G3_SymMacExt"

if Flag64_128 = TRUE_C64
			t "G3_V.Cl.64.Disk"
endif
if Flag64_128 = TRUE_C128
			t "G3_V.Cl.128.Disk"
endif

			t "-DD_JumpTab"

;*** Prüfen ob Laufwerk installiert werden kann.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk kann installiert werden.
:xTestDriveMode		jmp	GetFreeBank

;*** Laufwerk installieren.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk installiert.
;			     = $0D, Laufwerkstyp nicht verfügbar.
:xInstallDrive		sta	DriveMode		;Laufwerksdaten speichern.
			stx	DriveAdr

			jsr	PrepareDskDrv		;Treiber temporär installieren.

			jsr	TestDriveMode		;Freien RAM-Speicher testen.
			cpx	#NO_ERROR		;Ist genügend Speicher frei ?
			bne	:53			; => Nein, Installationsfehler.

			sta	DrvRamBase		;Startadresse RAM-Speicher merken.

;--- Angeschlossenes Laufwerk testen.
::51			lda	DriveAdr		;Aktuelles Laufwerk feststellen.
			jsr	TestDriveType
			cpx	#NO_ERROR		;Installationsfehler ?
			bne	:53			; => Ja, Abbruch...

			lda	DriveMode
			cmp	#Drv81DOS
			bne	:54

;--- 1581/DOS installieren.
			cpy	#Drv1581		;1581 erkannt ?
			beq	:57			; => Ja, weiter...

;--- Kompatibles Laufwerk suchen.
::Find81DOS		lda	#Drv1581
			ldy	DriveAdr
			jsr	FindDrive		;1581-Laufwerk suchen.
			txa				;Laufwerk gefunden ?
			beq	:57			; => Ja, weiter...

			lda	DriveAdr
			jsr	TurnOnNewDrive		;Dialogbox ausgeben.
			txa				;Lauafwerk eingeschaltet ?
			beq	:Find81DOS		; => Ja, Laufwerk suchen...

;--- Kein passendes Laufwerk gefunden.
::52			ldx	#DEV_NOT_FOUND
::53			rts

;--- CMDFD/DOS installieren.
::54			cpy	#DrvFD			;CMDFD erkannt ?
			beq	:57			; => Ja, weiter...

;--- Kompatibles Laufwerk suchen.
::FindFDDOS		lda	#DrvFD
			ldy	DriveAdr
			jsr	FindDrive		;CMDFD-Laufwerk suchen.
			txa				;Laufwerk gefunden ?
			beq	:57			; => Ja, weiter...

			lda	DriveAdr
			jsr	TurnOnNewDrive		;Dialogbox ausgeben.
			txa				;Lauafwerk eingeschaltet ?
			beq	:FindFDDOS		; => Ja, Laufwerk suchen...
			bne	:52

;--- Laufwerk installieren.
::57			jsr	PrepareDskDrv		;Treiber installieren.

			ldx	DriveAdr		;Laufwerksdaten setzen.
			lda	DriveMode
			and	#%00001111
			sta	driveType   -8,x
			sta	curType

			lda	DrvRamBase		;Cache-Speicher in REU belegen.
			ldy	#$01
			jsr	AllocateBankTab
			cpx	#NO_ERROR		;Speicher reserviert ?
			bne	:53			; => Nein, Installationsfehler.

			ldx	DriveAdr		;Startadresse Cache-Speicher in
			lda	DrvRamBase
			sta	ramBase     -8,x	;REU zwischenspeichern.

			lda	DriveMode
;			and	#%00001111
			sta	RealDrvType -8,x
			sta	BASE_DDRV_DATA + (DiskDrvType - DISK_BASE)
			lda	#SET_MODE_SUBDIR
			sta	RealDrvMode -8,x

;--- PCDOS Zusatz-Treiber installieren.
			LoadW	r0,DataExtDOS		;Erweiterte DOS-Routinen
			LoadW	r1,$f000		;in Speicher verschieben.
			LoadW	r2,$1000
			lda	DrvRamBase
			sta	r3L
			jsr	StashRAM

;--- Laufwerkstreiber speichern.
			jsr	InitForDskDvJob		;Laufwerkstreiber in REU
			jsr	StashRAM		;kopieren.
			jsr	DoneWithDskDvJob

;--- Ende, kein Fehler...
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
			lda	#SET_MODE_SUBDIR
			sta	RealDrvMode -8,x

;--- Treiber installieren.
			jsr	i_MoveData		;Laufwerkstreiber aktivieren.
			w	BASE_DDRV_DATA
			w	DISK_BASE
			w	SIZE_DDRV_DATA
			rts

;*** Laufwerk deinstallieren.
;    Übergabe:		xReg = Laufwerksadresse.
:xDeInstallDrive	txa				;RAM-Speicher in der REU wieder
			pha				;freigeben.
			lda	ramBase     -8,x
			jsr	FreeBank
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

;*** Systemvariablen.
:DriveMode		b $00
:DriveAdr		b $00
:DrvOnline		b $00
:DrvRamBase		b $00
:DataExtDOS		d "obj.PCDOS",NULL

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
:END_INIT		g BASE_DDRV_INIT + SIZE_DDRV_INIT
:DSK_INIT_SIZE		= END_INIT - BASE_DDRV_INIT
;******************************************************************************
