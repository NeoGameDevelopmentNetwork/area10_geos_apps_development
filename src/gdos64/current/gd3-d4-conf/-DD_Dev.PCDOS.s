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
:_DRV_INSTALL		jsr	initCopyDriver		;Treiber installieren.

;--- Freien Speicher für erweiterte DOS-Funktionen.
;Hinweis:
;Vor der Installatiuon des Treibers
;wird bereits geprüft ob 1x64K RAM an
;Speicher verfügbar ist. Daher kann
;hier kein Fehler mehr auftreten.
			ldy	#1			;1x64K für PCDOS.
			jsr	_DDC_RAMFIND
			sta	drvRAMBase		;Startadresse RAM-Speicher merken.

;			lda	drvRAMBase		;Cache-Speicher in REU belegen.
			ldy	#1
			ldx	#%10000000
			jsr	_DDC_RAMALLOC

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
