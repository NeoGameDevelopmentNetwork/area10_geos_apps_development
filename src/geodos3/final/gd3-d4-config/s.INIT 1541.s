; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExtDisk"

;*** GEOS-Header.
			n "mod.MDD_#110"
			t "G3_Disk.V.Class"

;*** Zusätzliche Symboltabellen.
if .p
:DDRV_SYS_DEVDATA	= BASE_DDRV_DATA
endif

;******************************************************************************
;*** Shared code.
;******************************************************************************
:MAIN			t "-DD_JumpTab"
;******************************************************************************

;******************************************************************************
;*** Laufwerksdaten.
;******************************************************************************
:BEGIN_VAR_DATA
:DrvMode		b $00
:DrvAdrGEOS		b $00
:END_VAR_DATA
;******************************************************************************

;******************************************************************************
;*** Titel für Dialogboxen.
;******************************************************************************
;:DlgBoxTitle		b PLAINTEXT,BOLDON
;if Sprache = Deutsch
;			b "Installation "
;endif
;if Sprache = Englisch
;			b "Install "
;endif
;			b "C=1541"
;			b NULL
;******************************************************************************

;******************************************************************************
;*** Shared code.
;******************************************************************************
			t "-DD_DDrvPrepare"
			t "-DD_DDrvUnload"
			t "-DD_DDrvClrDat"
;******************************************************************************
			t "-DD_Dev.C1541"
			t "-DD_InitSD2IEC"
			t "-DD_FindSBusDev"
			t "-D3_1571Mode"
;******************************************************************************

;*** Prüfen ob Laufwerk installiert werden kann.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk kann installiert werden.
:INIT_DEV_TEST		bit	DrvMode
			bvc	:51
			ldy	#3
			jmp	FindFreeRAM

::51			ldx	#NO_ERROR
			rts

;*** Laufwerk installieren.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk installiert.
;			     = $0D, Laufwerkstyp nicht verfügbar.
:INIT_DEV_INSTALL	sta	DrvMode			;Laufwerksdaten speichern.
			stx	DrvAdrGEOS

			jsr	DskDev_Prepare		;Treiber temporär installieren.

;--- Shadow-Laufwerk einrichten?
			bit	DrvMode			;1541-Cache-Laufwerk ?
			bvc	:51			; => Nein, weiter...

			jsr	INIT_DEV_TEST		;Freien RAM-Speicher testen.
			cpx	#NO_ERROR		;Ist genügend Speicher frei ?
			bne	:53			; => Nein, Installationsfehler.

			pha				;Cache-Speicher in REU belegen.
			ldy	#3
			jsr	AllocRAM
			pla
			cpx	#NO_ERROR		;Speicher reserviert ?
			bne	:53			; => Nein, Installationsfehler.

			ldx	DrvAdrGEOS		;Startadresse Cache-Speicher in
			sta	ramBase   -8,x		;REU zwischenspeichern.

;--- Angeschlossenes Laufwerk testen.
::51			lda	#$00
			sta	drvMode_4171

			lda	DrvAdrGEOS		;Aktuelles Laufwerk feststellen.
			jsr	a_TestDriveType
			cpx	#NO_ERROR		;Laufwerk erkannt ?
			bne	:51a			; => Nein, weiter...

			cpy	#Drv1541		;1541-Laufwerk erkannt ?
			beq	:54			; => Ja, weiter...
			cpy	#Drv1571		;1571-Laufwerk erkannt ?
			beq	:1571			; => Ja, weiter...

;--- Ergänzung: 15.12.18/M.Kanet
;Auf SD2IEC-Laufwerk testen. Falls Ja, dann Laufwerks-DOS wechseln.
::51a			jsr	TestSD2IEC		;Aktuelles Laufwerk SD2IEC?
			cpx	#$ff			;SD2IEC ?
			beq	:55			; => Nein, weiter...

;--- Kompatibles Laufwerk suchen.
::52			lda	#Drv1541		;Laufwerksmodus: 1541.
			ldy	DrvAdrGEOS		;Geräteadresse.
			jsr	a_FindDrive		;1541-Laufwerk suchen.
			cpx	#NO_ERROR		;Laufwerk gefunden ?
			beq	:54			; => Ja, weiter...
			lda	#Drv1571		;Laufwerksmodus: 1571.
			ldy	DrvAdrGEOS		;Geräteadresse.
			jsr	a_FindDrive		;1571-Laufwerk/41-Modus suchen.
			cpx	#NO_ERROR		;Laufwerk gefunden ?
			beq	:1571			; => Ja, weiter...

			lda	DrvAdrGEOS
			jsr	a_TurnOnNewDrive	;Dialogbox ausgeben.
			txa				;Lauafwerk eingeschaltet ?
			beq	:52			; =: Ja, Laufwerk suchen...

;--- Kein passendes Laufwerk gefunden.
::53			ldx	#DEV_NOT_FOUND
			rts

;--- Laufwerk installieren.
::1571			dec	drvMode_4171		;1541/1571-Laufwerkstyp merken.

::54			jsr	TestSD2IEC
::55			stx	drvMode_SD2IEC

			jmp	InstallDriver		;Laufwerk installieren.

;*** Laufwerk deinstallieren.
;    Übergabe:		xReg = Laufwerksadresse.
:INIT_DEV_REMOVE	stx	DrvAdrGEOS

;			ldx	DrvAdrGEOS
			jsr	DskDev_Unload		;RAM-Speicher freigeben.

			ldx	DrvAdrGEOS
			jmp	DskDev_ClrData		;Laufwerksdaten zurücksetzen.

;*** Variablen.
:drvMode_SD2IEC		b $00
:drvMode_4171		b $00

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
:END_INIT		g BASE_DDRV_INIT + SIZE_DDRV_INIT
:DSK_INIT_SIZE		= END_INIT - BASE_DDRV_INIT
;******************************************************************************
