; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Prüfen ob Laufwerk installiert werden kann.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk kann installiert werden.
:xTestDriveMode		ldx	#NO_ERROR
			txa
			tay
			rts

;*** Laufwerk installieren.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk installiert.
;			     = $0D, Laufwerkstyp nicht verfügbar.
:xInstallDrive		pha				;Laufwerksdaten speichern.
			and	#%00111111
			sta	DriveMode
			pla
			and	#%10000000
			sta	FastPPmode
			stx	DriveAdr

			jsr	PrepareDskDrv		;Treiber temporär installieren.

;--- Angeschlossenes Laufwerk testen.
::51			lda	DriveAdr		;Aktuelles Laufwerk feststellen.
			jsr	TestDriveType
			cpx	#NO_ERROR		;Installationsfehler ?
			bne	:53			; => Ja, Abbruch...
			eor	DriveMode		;Laufwerkstyp erkannt ?
			beq	:56			; => Ja, weiter...
			and	#%11110000		;CMD-Laufwerk angeschlossen ?
			beq	:56			; => Ja, Laufwerk installieren.
							;    Hier stimmt nur das Partitions-
							;    format nicht. Dieses wird von
							;    ":OpenDisk" aktiviert.
;--- Kompatibles Laufwerk suchen.
::53			lda	DriveMode
			and	#%11110000		;CMD-HD-Laufwerkskennung isolieren.
			ldy	DriveAdr
			jsr	FindDrive		;15x1-Laufwerk suchen.
			cpx	#NO_ERROR		;Laufwerk gefunden ?
			beq	:56			; => Ja, weiter...

			lda	DriveAdr
			jsr	TurnOnNewDrive		;Dialogbox ausgeben.
			txa				;Lauafwerk eingeschaltet ?
			beq	:53			; => Ja, Laufwerk suchen...

;--- Kein passendes Laufwerk gefunden.
::55			ldx	#DEV_NOT_FOUND
			rts

;--- Laufwerk installieren.
::56			jsr	PrepareDskDrv		;Treiber installieren.

			ldx	DriveAdr		;Laufwerksdaten setzen.
			lda	DriveMode
			and	#%00001111
			sta	driveType   -8,x
			sta	curType
			txa				;Aktuelles Laufwerk feststellen.
			jsr	TestDriveType
			cpx	#NO_ERROR		;Installationsfehler ?
			bne	:55			; => Ja, Abbruch...
			tya
			ldx	DriveAdr		;Laufwerksdaten setzen.
			and	#%11110000
			ora	curType
			sta	RealDrvType -8,x
			sta	BASE_DDRV_DATA + (DiskDrvType - DISK_BASE)

			ldy	#SET_MODE_PARTITION
			lda	RealDrvType-8,x
			and	#%00001111
			cmp	#DrvNative
			bne	:58
			tya
			ora	#SET_MODE_SUBDIR
			tay
::58			tya
			sta	RealDrvMode-8,x

;--- Laufwerkstreiber speichern.
			jsr	InitForDskDvJob		;Laufwerkstreiber in REU
			jsr	StashRAM		;kopieren.
			jsr	DoneWithDskDvJob

;--- Parallelkabel testen.
			bit	FastPPmode
			bpl	:61
			jsr	TestHDcable		;Auf PP-Kabel testen.
			bne	:61			; => Kein PP-Kabel, Ende...

			jsr	i_MoveData		;Laufwerkstreiber für FF-Kabel
			w	HD_PP			;aktivieren.
			w	DISK_BASE
			w	SIZE_DDRV_DATA

;--- Laufwerkstreiber/PP speichern.
			jsr	InitForDskDvJob		;Laufwerkstreiber in REU
			jsr	StashRAM		;kopieren.
			jsr	DoneWithDskDvJob

			ldx	DriveAdr
			lda	RealDrvMode -8,x
			ora	#SET_MODE_FASTDISK
			sta	RealDrvMode -8,x

;--- Ende, kein Fehler...
::61			ldx	#NO_ERROR
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
			lda	#$00
			sta	RealDrvMode -8,x

;--- Treiber installieren.
			jsr	i_MoveData		;Laufwerkstreiber aktivieren.
			w	BASE_DDRV_DATA
			w	DISK_BASE
			w	SIZE_DDRV_DATA
			rts

;*** Laufwerk deinstallieren.
:xDeInstallDrive	lda	#$00
			sta	ramBase     -8,x
			sta	driveType   -8,x
			sta	driveData   -8,x
			sta	turboFlags  -8,x
			sta	RealDrvType -8,x
			sta	RealDrvMode -8,x
			tax
			rts

;*** Auf CMD-HD-Kabel testen.
:TestHDcable		lda	DriveAdr
			jsr	SetDevice
			jsr	PurgeTurbo
			jsr	InitForIO

			LoadW	r0,data1
			LoadB	r2L,32
			jsr	SendCommand
			jsr	UNLSN

			LoadW	r0,data2
			LoadB	r2L,23
			jsr	SendCommand
			jsr	UNLSN

			LoadW	r0,data3
			LoadB	r2L,5
			jsr	SendCommand
			jsr	UNLSN

;--- Ergänzung: 08.07.18/M.Kanet
;Code-Rekonstruktion: MMU und RAM_Conf_Reg sichern und RAM-Bank umschalten.
if Flag64_128 = TRUE_C128
			jsr	L05f7
endif

			jsr	EN_SET_REC

			ldx	#$98
			lda	$df41
			pha
			lda	$df42
			stx	$df43
			sta	$df42
			pla
			sta	$df41

			lda	#$00
			sta	r0L
			sta	r0H

			lda	$df40
			clc
			adc	#$10
			sta	:1 +4
			adc	#$10
			sta	:1 +4

::1			lda	$df40
			cmp	#$ff
			beq	:2

			inc	r0L
			bne	:1
			inc	r0H
			bne	:1
			beq	:9

::2			lda	$df40
			cmp	#$ff
			beq	:3

			inc	r0L
			bne	:2
			inc	r0H
			bne	:2
			beq	:9

::9			lda	#$ff
			b $2c
::3			lda	#NO_ERROR
			pha
			jsr	RL_HW_DIS2

;--- Ergänzung: 08.07.18/M.Kanet
;Code-Rekonstruktion: RAMLink deaktivieren und MMU/RAM_Conf_Reg zurücksetzen.
if Flag64_128 = TRUE_C128
			jsr	L05ec
endif

			jsr	DoneWithIO
			pla
			tax
			rts

;--- Test-Routine Teil #1
:data1			b "M-W",$00,$03,$1b

			sei
			ldx	#$82
			lda	$8802
			stx	$8803
			sta	$8802
			lda	#$10
			sta	$8000
			ldx	#$00
			ldy	#$00
::1			iny
			bne	:1
			inx
			bne	:1

;--- Test-Routine Teil #2
:data2			b "M-W",$1b,$03,$11
			ldx	#$00
			lda	#$01
::1			sta	$8800
::2			inx
			bne	:2
			clc
			adc	#$01
			bne	:1
			cli
			rts

;--- Test-Routine starten
:data3			b "M-E",$00,$03

if Flag64_128 = TRUE_C128
;--- Ergänzung: 04.07.18/M.Kanet
;Code-Rekonstruktion: Folgende Routinen ergänzt,
;vermutlich Bank-RAM-Konfiguration.
:L05ec			lda	#$00
			sta	RAM_Conf_Reg
:L05f1			lda	#$00
			sta	MMU
			rts

:L05f7			lda	MMU
			sta	L05f1+1
			lda	#$4e
			sta	MMU
			lda	RAM_Conf_Reg
			sta	L05ec+1
			and	#%11110000
			ora	#%00000100
			sta	RAM_Conf_Reg
			rts
endif
