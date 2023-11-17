; UTF-8 Byte Order Mark (BOM), do not remove!
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

;--- Freien Speicher für erweiterte DOS-Funktionen.
			ldy	#1			;1x64K für PCDOS.
			jsr	FindFreeRAM
			cpx	#NO_ERROR		;Ist genügend Speicher frei ?
			bne	:error			; => Nein, Installationsfehler.

			sta	drvRAMBase		;Startadresse RAM-Speicher merken.

;--- RealDrvMode definieren:
;SET_MODE_...
; -> PARTITION/SUBDIR/FASTDISK/SD2IEC
; -> SRAM/CREU/GRAM
			ldx	DrvAdrGEOS		;Laufwerksmodi festlegen.
			lda	#SET_MODE_SUBDIR
			ora	RealDrvMode -8,x
			sta	RealDrvMode -8,x

;--- Speicher reservieren.
			lda	drvRAMBase		;Cache-Speicher in REU belegen.
			ldy	#1
			ldx	#%10000000
			jsr	AllocRAM
			cpx	#NO_ERROR		;Speicher reserviert ?
			bne	:error			; => Nein, Installationsfehler.

			ldx	DrvAdrGEOS		;Startadresse Cache-Speicher in
			lda	drvRAMBase
			sta	ramBase     -8,x	;REU zwischenspeichern.

;--- Erweiterte PCDOS-Funktionen installieren.
			LoadW	r0,DataExtDOS		;Erweiterte PCDOS-Funktionen
			LoadW	r1,$f000		;in Speicher verschieben.
			LoadW	r2,$1000
			lda	drvRAMBase
			sta	r3L
			jsr	StashRAM

;--- Laufwerkstreiber in REU speichern.
::2			lda	DrvAdrGEOS		;Aktuelles Laufwerk festlegen.
			sta	curDevice		;Adresse wird für die Routine
			sta	curDrive		;":InitForDskDvJob" benötigt.

			jsr	InitForDskDvJob		;Laufwerkstreiber in GEOS-Speicher
			jsr	StashRAM		;kopieren.
			jsr	DoneWithDskDvJob

			ldx	#NO_ERROR
::error			rts				;Ende.
