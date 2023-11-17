﻿; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Laufwerkstreiber installieren.
;Übergabe: DrvAdrGEOS = GEOS-Laufwerk A-D/8-11.
;          DrvMode    = Laufwerksmodus $01=1541, $33=RL81...
;Rückgabe: xReg = $00, Laufwerk installiert.
:InstallDriver		lda	DrvMode			;Laufwerksmodus einlesen.
			ldx	DrvAdrGEOS		;GEOS-Laufwerksadresse einlesen.
			jsr	DskDev_Prepare		;Treiber installieren.

;--- RealDrvMode definieren:
;SET_MODE_...
; -> PARTITION/SUBDIR/FASTDISK/SD2IEC
; -> SRAM/CREU/GRAM
			lda	drvMode_SD2IEC		;SD2IEC-Laufwerk ?
			beq	:1			; => Nein, weiter...

			ldx	DrvAdrGEOS		;Laufwerksmodi festlegen.
			lda	#SET_MODE_SD2IEC
			sta	Flag_SD2IEC
			ora	RealDrvMode -8,x
			sta	RealDrvMode -8,x

;--- Laufwerkstreiber in REU speichern.
::1			lda	DrvAdrGEOS		;Aktuelles Laufwerk festlegen.
			sta	curDevice		;Adresse wird für die Routine
			sta	curDrive		;":InitForDskDvJob" benötigt.

			jsr	InitForDskDvJob		;Laufwerkstreiber in GEOS-Speicher
			jsr	StashRAM		;kopieren.
			jsr	DoneWithDskDvJob

;--- Auf SD2IEC-Laufwerk testen.
;Falls Ja, dann Laufwerks-DOS wechseln.
			lda	drvMode_SD2IEC		;SD2IEC-Laufwerk ?
			beq	:2			; => Nein, weiter...

			lda	#"4"
			ldx	#"1"
			jsr	LoadDriveROM		;DOS1581.BIN laden.

;--- Shadow-Laufwerk einrichten?
::2			bit	DrvMode			;1541-Cache-Laufwerk ?
			bvc	:3			; => Nein, weiter...

			ldy	#3
			jsr	FindFreeRAM		;Freien RAM-Speicher suchen.

			pha				;Cache-Speicher in REU belegen.
			ldy	#3
			ldx	#%10000000
			jsr	AllocRAM
			pla
			cpx	#NO_ERROR		;Speicher reserviert ?
			bne	:exit			; => Nein, Installationsfehler.

			ldx	DrvAdrGEOS		;Startadresse Cache-Speicher in
			sta	ramBase   -8,x		;REU zwischenspeichern.

			jsr	InitShadowRAM		;Cache-Speicher löschen.

;--- Ergänzung: 28.08.21/M.Kanet
;Shadow-Bit erst nach AllocRAM setzen.
			ldx	DrvAdrGEOS		;Shadow-Bit setzen nachdem der
			lda	driveType -8,x		;Speicher reserviert und auch
			ora	#%01000000		;initialisiert wurde!
			sta	driveType -8,x
			sta	curType

;--- 1571 in den 1541-Modus umschalten.
::3			lda	drvMode_SD2IEC		;SD2IEC-Laufwerk ?
			bne	:done			; => Ja, weiter...
			lda	drvMode_4171		;1571-Laufwerk ?
			beq	:done			; => Nein, weiter...

			ldx	DrvAdrGEOS		;Laufwerksadresse.
			lda	#$00			;1541-Modus.
			jsr	Set1571DkMode		;Laufwerksmodus festlegen.

::done			ldx	#NO_ERROR
::exit			rts				;Ende.

;*** ShadowRAM initialisieren.
:InitShadowRAM		t "-D3_InitShadow"
