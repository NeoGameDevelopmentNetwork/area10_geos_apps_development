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
			n "mod.MDD_#114"
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
;			b "C=1581"
;			b NULL
;******************************************************************************

;******************************************************************************
;*** Shared code.
;******************************************************************************
			t "-DD_DDrvPrepare"
			t "-DD_DDrvClrDat"
;******************************************************************************
			t "-DD_Dev.C1581"
			t "-DD_InitSD2IEC"
			t "-DD_FindSBusDev"
;******************************************************************************

;*** Prüfen ob Laufwerk installiert werden kann.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk kann installiert werden.
:INIT_DEV_TEST		ldx	#NO_ERROR
			txa
			tay
			rts

;*** Laufwerk installieren.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk installiert.
;			     = $0D, Laufwerkstyp nicht verfügbar.
:INIT_DEV_INSTALL	sta	DrvMode			;Laufwerksdaten speichern.
			stx	DrvAdrGEOS

			jsr	DskDev_Prepare		;Treiber temporär installieren.

;--- Angeschlossenes Laufwerk testen.
::51			lda	DrvAdrGEOS		;Aktuelles Laufwerk feststellen.
			jsr	a_TestDriveType
			cpx	#NO_ERROR		;Installationsfehler ?
			bne	:51a			; => Ja, Abbruch...
			cpy	#Drv1581		;1581-Laufwerk installieren ?
			beq	:54			; => Ja, weiter...

;--- Ergänzung: 15.12.18/M.Kanet
;Auf SD2IEC-Laufwerk testen. Falls Ja, dann Laufwerks-DOS wechseln.
::51a			jsr	TestSD2IEC		;Aktuelles Laufwerk SD2IEC?
			cpx	#$ff			;SD2IEC ?
			beq	:55			; => Ja, weiter...

;--- Kompatibles Laufwerk suchen.
::52			lda	#Drv1581
			ldy	DrvAdrGEOS
			jsr	a_FindDrive		;1581-Laufwerk suchen.
			cpx	#$00			;Laufwerk gefunden ?
			beq	:54			; => Ja, weiter...

			lda	DrvAdrGEOS
			jsr	a_TurnOnNewDrive	;Dialogbox ausgeben.
			txa				;Lauafwerk eingeschaltet ?
			beq	:52			; => Ja, Laufwerk suchen...

;--- Kein passendes Laufwerk gefunden.
::53			ldx	#DEV_NOT_FOUND
			rts

;--- Laufwerk installieren.
::54			jsr	TestSD2IEC
::55			stx	drvMode_SD2IEC

			jmp	InstallDriver

;*** Laufwerk deinstallieren.
;    Übergabe:		xReg = Laufwerksadresse.
:INIT_DEV_REMOVE	stx	DrvAdrGEOS

;			ldx	DrvAdrGEOS
;			jsr	DskDev_Unload		;RAM-Speicher freigeben.

;			ldx	DrvAdrGEOS
			jmp	DskDev_ClrData		;Laufwerksdaten zurücksetzen.

;*** Variablen.
:drvMode_SD2IEC		b $00

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
:END_INIT		g BASE_DDRV_INIT + SIZE_DDRV_INIT
:DSK_INIT_SIZE		= END_INIT - BASE_DDRV_INIT
;******************************************************************************
