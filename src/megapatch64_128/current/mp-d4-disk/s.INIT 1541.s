; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "mod.MDD_#110"
			t "G3_SymMacExt"

if Flag64_128 = TRUE_C64
			t "G3_V.Cl.64.Disk"
endif
if Flag64_128 = TRUE_C128
			t "G3_V.Cl.128.Disk"
endif

			t "-DD_JumpTab"
			t "-DD_InitSD2IEC"

;*** Prüfen ob Laufwerk installiert werden kann.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk kann installiert werden.
:xTestDriveMode		and	#%01000000
			beq	:51
			ldy	#$03
			jmp	GetFreeBankTab

::51			tax
			tay
			rts

;*** Laufwerk installieren.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk installiert.
;			     = $0D, Laufwerkstyp nicht verfügbar.
:xInstallDrive		sta	DriveMode		;Laufwerksdaten speichern.
			stx	DriveAdr

			jsr	PrepareDskDrv		;Treiber temporär installieren.

;--- Shadow-Laufwerk einrichten?
			lda	DriveMode
			and	#%01000000		;1541-Cache-Laufwerk ?
			beq	:51			; => Nein, weiter...

			jsr	TestDriveMode		;Freien RAM-Speicher testen.
			cpx	#NO_ERROR		;Ist genügend Speicher frei ?
			bne	:53			; => Nein, Installationsfehler.

			pha				;Cache-Speicher in REU belegen.
			ldy	#$03
			jsr	AllocateBankTab
			pla
			cpx	#NO_ERROR		;Speicher reserviert ?
			bne	:53			; => Nein, Installationsfehler.

			ldx	DriveAdr		;Startadresse Cache-Speicher in
			sta	ramBase   -8,x		;REU zwischenspeichern.

;--- Angeschlossenes Laufwerk testen.
::51			lda	DriveAdr		;Aktuelles Laufwerk feststellen.
			jsr	TestDriveType
			cpx	#NO_ERROR		;Laufwerk erkannt ?
			bne	:51a			; => Nein, weiter...
			cpy	#Drv1541		;1541-Laufwerk erkannt ?
			beq	:54			; => Ja, weiter...

;--- Ergänzung: 15.12.18/M.Kanet
;Auf SD2IEC-Laufwerk testen. Falls Ja, dann Laufwerks-DOS wechseln.
::51a			tya
			pha
			jsr	TestSD2IEC		;Aktuelles Laufwerk SD2IEC?
			pla
			tay
			cpx	#$ff			;SD2IEC ?
			bne	:51b			; => Nein, weiter...

			lda	#"4"
			ldx	#"1"
			jsr	LoadDriveROM		;DOS1541.BIN laden.
			jmp	:54			;Weiter...

;--- 1541-Treiber darf nur 1541 einrichten, sonst kommt es beim booten zu
;    Installationsproblemen wenn eine 1541 und eine 1571 installiert wird!
::51b			cpy	#Drv1571		;1571-Laufwerk erkannt ?
			beq	:54			; => Ja, weiter...

;--- Kompatibles Laufwerk suchen.
::52			lda	#Drv1541		;Laufwerksmodus: 1541.
			ldy	DriveAdr		;Geräteadresse.
			jsr	FindDrive		;1541-Laufwerk suchen.
			cpx	#NO_ERROR		;Laufwerk gefunden ?
			beq	:54			; => Ja, weiter...
			lda	#Drv1571		;Laufwerksmodus: 1571.
			ldy	DriveAdr		;Geräteadresse.
			jsr	FindDrive		;1571-Laufwerk/41-Modus suchen.
			cpx	#NO_ERROR		;Laufwerk gefunden ?
			beq	:54			; => Ja, weiter...

			lda	DriveAdr
			jsr	TurnOnNewDrive		;Dialogbox ausgeben.
			txa				;Lauafwerk eingeschaltet ?
			beq	:51			; =: Ja, Laufwerk suchen...

;--- Kein passendes Laufwerk gefunden.
::53			ldx	#DEV_NOT_FOUND
			rts

;--- Laufwerk installieren.
::54			jsr	PrepareDskDrv		;Treiber temporär installieren.

;--- SD2IEC-Kennung speichern.
			jsr	TestSD2IEC		;Aktuelles Laufwerk SD2IEC?
			cpx	#$ff			;SD2IEC ?
			bne	:55			; => Nein, weiter...

			ldx	DriveAdr		;Laufwerksdaten setzen.
			lda	#SET_MODE_SD2IEC
			sta	Flag_SD2IEC
			ora	RealDrvMode -8,x
			sta	RealDrvMode -8,x	;SD2IEC-Flag in RealDrvMode setzen.

;--- Laufwerkstreiber speichern.
::55			jsr	InitForDskDvJob		;Laufwerkstreiber in REU
			jsr	StashRAM		;kopieren.
			jsr	DoneWithDskDvJob

;--- Cache-Speicher löschen.
			jsr	InitShadowRAM

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
			lda	#$00
			sta	RealDrvMode -8,x

;--- Treiber installieren.
			jsr	i_MoveData		;Laufwerkstreiber aktivieren.
			w	BASE_DDRV_DATA
			w	DISK_BASE
			w	SIZE_DDRV_DATA
			rts

;*** Laufwerk deinstallieren.
;    Übergabe:		xReg = Laufwerksadresse.
:xDeInstallDrive	lda	driveType   -8,x
			and	#%01000000		;Cache-Laufwerk installiert ?
			beq	:51			; => Nein, weiter...

			txa				;Cache-Speicher in der REU wieder
			pha				;freigeben.

;--- Ergänzung: 01.07.2018/M.Kanet
;In der Version von 1999-2003 wurde die Anzahl der
;freizugebenden Speicherbänke fälschlicherweise im X-Register übergeben.
;Die Routine ":FreeBankTab" erwartet die Anzahl aber im Y-Register.
			lda	ramBase     -8,x
			ldy	#$03
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

;*** ShadowRAM initialisieren.
:InitShadowRAM		bit	DriveMode		;Shaow1541 ?
			bvc	:53			;Ja, weiter...

::51			lda	#>InitWordData		;Zeiger auf Initialisierungswert
			sta	r0H			;für Sektortabelle (2x NULL-Byte!)
			lda	#<InitWordData
			sta	r0L

			ldy	#$00			;Offset in 64K-Bank.
			sty	r1L
			sty	r1H
			sty	r2H			;Anzahl Bytes.
			iny
			iny
			sty	r2L

			iny				;Bank-Zähler initialisieren.
			sty	r3H

			ldy	DriveAdr		;Zeiger auf erste Bank für
			lda	ramBase -8,y		;Shadow1541-Laufwerk richten.
			sta	r3L

::52			jsr	StashRAM		;Sektor "Nicht gespeichert" setzen.
			inc	r1H			;Zeiger auf nächsten Sektor in Bank.
			bne	:52			;Schleife.

			inc	r3L			;Zeiger auf nächste Bank.
			dec	r3H			;Alle Bänke initialisiert ?
			bne	:52			;Nein, weiter...
::53			rts

;*** Systemvariablen.
:DriveMode		b $00
:DriveAdr		b $00
:InitWordData		w $0000

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
:END_INIT		g BASE_DDRV_INIT + SIZE_DDRV_INIT
:DSK_INIT_SIZE		= END_INIT - BASE_DDRV_INIT
;******************************************************************************
