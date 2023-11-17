; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Laufwerksdaten speichern.
; Datum			: 04.07.97
; Aufruf		: JSR  Sv1DrvData									 Daten in Speicher #1
;				 (Reserviert für System)
;			  JSR  Sv2DrvData									 Daten in Speicher #2
;				 (Reserviert für Anwender)
; Übergabe		: -
; Rückgabe		: -
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r15
; Variablen		: -curDrvMode Laufwerksmodi
; Routinen		: -NewDrive Laufwerk aktivieren
;			  -GetDirHead BAM einlesen
;			  -GetCurPInfo Partitionsdaten einlesen
;******************************************************************************

;******************************************************************************
; Funktion		: Laufwerksdaten zurücksetzen.
; Datum			: 04.07.97
; Aufruf		: JSR  Ld1DrvData									 Daten aus Speicher #1
;				 (Reserviert für System)
;			  JSR  Ld2DrvData									 Daten aus Speicher #2
;				 (Reserviert für Anwender)
; Übergabe		: -
; Rückgabe		: -
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r15
; Variablen		: -curDrvMode Laufwerksmodi
; Routinen		: -NewDrive Laufwerk aktivieren
;			  -New_CMD_SubD Unterverzeichnis öffnen
;			  -SaveNewPart Neue Partition aktivieren
;******************************************************************************

;*** Zeiger auf Datenspeicher.
:SvVektor		b $00

;*** Zwischenspeicher für Laufwerksdaten.
:Sv1Modes		b $00,$00,$00,$00
:Sv1Drive		b $00
:Sv1Part		b $00
:Sv1PartRAM		b $00,$00
:Sv1NDir		b $00,$00

:Sv2Modes		b $00,$00,$00,$00
:Sv2Drive		b $00
:Sv2Part		b $00
:Sv2PartRAM		b $00,$00
:Sv2NDir		b $00,$00

;*** Laufwerksdaten speichern.
.Sv1DrvData		ldx	#$00
			b $2c
.Sv2DrvData		ldx	#(Sv2Modes - Sv1Modes)
			stx	SvVektor

			lda	curDrive		;Aktuelles Laufwerk
			sta	Sv1Drive     ,x		;zwischenspeichern.
			jsr	NewDrive

			ldx	SvVektor
			lda	#$00
			sta	Sv1Modes  + 0,x
			sta	Sv1Modes  + 1,x
			sta	Sv1Modes  + 2,x

;--- Ergänzung: 29.11.18/M.Kanet
;NativeMode auch auf SD2IEC und RAMNative möglich.
			bit	curDrvMode
			bpl	:103

::102			ldx	curDrive
			lda	DrivePart - 8,x
			jsr	SetNewPart
			txa
			bne	:101

			tya
			ldx	SvVektor
			sta	Sv1Part      ,x
			dec	Sv1Modes  + 0,x

			bit	curDrvMode
			bvc	:103
			ldy	curDrive		;RAM-Laufwerk (RL,RD)
			lda	ramBase   - 8,y
			sta	Sv1PartRAM+ 0,x
			lda	driveData + 3
			sta	Sv1PartRAM+ 1,x
			dec	Sv1Modes  + 1,x

::103			lda	curDrvMode
			and	#%00100000
			beq	:101

			jsr	GetDirHead
			txa
			bne	:101

			ldx	SvVektor
			lda	curDirHead+32
			sta	Sv1NDir   + 0,x
			lda	curDirHead+33
			sta	Sv1NDir   + 1,x
			dec	Sv1Modes  + 2,x
::101			rts

;*** Laufwerksdaten speichern.
.Ld1DrvData		ldx	#$00
			b $2c
.Ld2DrvData		ldx	#(Sv2Modes - Sv1Modes)
			stx	SvVektor

			lda	Sv1Drive  + 0,x
			jsr	NewDrive

			ldx	SvVektor
			lda	Sv1Modes  + 0,x
			bmi	:102
::101			rts

::102			lda	Sv1Part      ,x
			jsr	SaveNewPart

			ldx	SvVektor
			lda	Sv1Modes  + 1,x
			bpl	:103
			ldy	curDrive
			lda	Sv1PartRAM+ 0,x
			sta	ramBase   - 8,y
			lda	Sv1PartRAM+ 1,x
			sta	driveData + 3

::103			lda	Sv1Modes  + 2,x
			bpl	:101
			lda	Sv1NDir   + 0,x
			sta	r1L
			lda	Sv1NDir   + 1,x
			sta	r1H
			jmp	New_CMD_SubD
