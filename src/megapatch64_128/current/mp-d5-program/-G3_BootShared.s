; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** RAM-Treiber testen.
:TestDeviceRAM		ldy	#$00			;Testdaten erzeugen.
			lda	#%11101010
::52			sta	diskBlkBuf,y
			iny
			bne	:52

			jsr	:60			;DoRAMOp-Werte setzen.
			jsr	StashRAM		;Testdaten in REU speichern.

			ldy	#$00			;Prüfdaten erzeugen.
			lda	#%00010101
::53			sta	diskBlkBuf,y
			iny
			bne	:53

			jsr	:60			;DoRAMOp-Werte setzen.
			jsr	FetchRAM		;Testdaten aus REU einlesen.

			ldy	#$00			;Testdaten mit Prüfdaten
::54			lda	diskBlkBuf,y		;vergleichen.
			eor	#%11111111
			cmp	#%00010101
			bne	:55
			iny
			bne	:54

			ldx	#NO_ERROR
			b $2c
::55			ldx	#DEV_NOT_FOUND
			rts

;--- Werte für DoRAMOp setzen.
::60			lda	#$00
			ldx	#> diskBlkBuf
			sta	r0L
			stx	r0H

;			lda	#$00
			sta	r1L
			sta	r1H

;			lda	#$00
			ldx	#$01
			sta	r2L
			stx	r2H

;			lda	#$00
			sta	r3L
			rts

;*** DACC-Konfiguration speichern.
:SaveRamConfig		LoadW	r6,FNamGEOS_B		;"GEOS.BOOT" modifizieren.
			jsr	FindFile		;Datei suchen.
			txa				;"GEOS.BOOT" gefunden?
			bne	:51			; => Nein, Ende...

			jsr	SaveRamType		;Gewählte Speichererweiterung
			txa				;in Systemprogramm speichern.
			bne	:52			;Fehler? => Ja, Ende...

::51			LoadW	r6,FNamRBOOT_B		;"RBOOT.BOOT" modifizieren.
			jsr	FindFile		;Datei suchen.
			txa				;"RBOOT.BOOT" gefunden?
			bne	:52			; => Nein, Ende...

			jsr	SaveRamType		;Gewählte Speichererweiterung
							;in Systemprogramm speichern.
::52			rts

;*** Konfiguration speichern.
:SaveRamType		lda	dirEntryBuf +1		;Ersten Programmsektor einlesen.
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch...

if Flag64_128 = TRUE_C128
			php
			sei
			lda	RAM_Conf_Reg		;CommonArea aktivieren, da hier
			pha				;die Konfigurationsdaten liegen.
			lda	#%01000111
			sta	RAM_Conf_Reg
endif

::51			lda	ExtRAM_Type   ,x
			sta	diskBlkBuf +14,x
			inx
			cpx	#$05
			bcc	:51

if Flag64_128 = TRUE_C128
			pla
			sta	RAM_Conf_Reg
			plp
endif

			jsr	PutBlock		;Sektor wieder auf Disk speichern.
::52			rts

;*** Ersten Druckertreiber auf Diskette suchen/laden.
:LoadDev_Printer	lda	#$ff			;Druckername in RAM löschen.
			sta	PrntFileNameRAM

			LoadW	r6 ,PrntFileName
			LoadB	r7L,PRINTER
			jsr	LoadDev_InitFn		;Druckertreiber suchen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...
			lda	r7H			;Treiber gefunden ?
			bne	:51			; => Nein, Abbruch...

			lda	Flag_LoadPrnt		;Druckertreiber in REU laden ?
			bne	:51			;Nein, weiter...

			LoadB	r0L,%00000001
			LoadW	r6 ,PrntFileName
			LoadW	r7 ,PRINTBASE
			jsr	GetFile			;Druckertreiber laden.
::51			rts

;*** Ersten Maustreiber auf Diskette suchen/laden.
:LoadDev_Mouse		LoadW	r6 ,inputDevName
if Flag64_128 = TRUE_C64
			LoadB	r7L,INPUT_DEVICE
endif
if Flag64_128 = TRUE_C128
			LoadB	r7L,INPUT_128
endif
			jsr	LoadDev_InitFn		;Eingabetreiber suchen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...
			lda	r7H			;Treiber gefunden ?
			bne	:51			; => Nein, Abbruch...

			LoadB	r0L,%00000001
			LoadW	r6 ,inputDevName
			LoadW	r7 ,MOUSE_BASE
			jsr	GetFile			;Eingabetreiber laden.
::51			rts

;*** Dateisuche initialisieren.
:LoadDev_InitFn		ldx	#$01
			stx	r7H
			dex
			stx	r10L
			stx	r10H
			jmp	FindFTypes		;Eingabetreiber suchen.

;*** GEOS-Variablenspeicher $8000-$8FFF löschen.
:InitSys_ClrVar		lda	#$00
			ldx	#$80
			sta	r0L
			stx	r0H

			ldx	#$10
			tay
::51			sta	(r0L),y
			iny
			bne	:51
			inc	r0H
			dex
			bne	:51

			rts

;*** Variablen für DoRAMOp-Routinen setzen.
:InitSys_SetRAM		ldx	ExtRAM_Size		;Größe des ermittelten Speichers
			cpx	#3			;Weniger als 3x64Kb?
			bcc	:2			; => Ja, Abbruch...
			cpx	#RAM_MAX_SIZE		;an GEOS übergeben.
			bcc	:1
			ldx	#RAM_MAX_SIZE
::1			stx	ramExpSize

			dex				;Speicherbereich für Megapatch-
			stx	MP3_64K_SYSTEM		;Kernal in REU festlegen.
			dex
			stx	MP3_64K_DATA
			ldx	#$00			;Laufwerkstreiber von
			stx	MP3_64K_DISK		;Diskette installieren.

			lda	ExtRAM_Bank  +0
			sta	RamBankFirst +0
			lda	ExtRAM_Bank  +1
			sta	RamBankFirst +1

			lda	ExtRAM_Type		;RAM-Typ an GEOS übergeben.
			sta	GEOS_RAM_TYP

;			ldx	#NO_ERROR		;XReg ist bereits #0 = Kein Fehler.
			b $2c
::2			ldx	#DEV_NOT_FOUND
			rts
