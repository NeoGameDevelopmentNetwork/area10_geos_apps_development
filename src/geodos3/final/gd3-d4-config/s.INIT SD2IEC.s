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
			n "mod.MDD_#180"
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
;			b "SD2IEC/NM"
;			b NULL
;******************************************************************************

;******************************************************************************
;*** Shared code.
;******************************************************************************
			t "-DD_DDrvPrepare"
			t "-DD_DDrvClrDat"
;******************************************************************************
			t "-DD_Dev.SDNM"
			t "-DD_InitSD2IEC"
			t "-DD_FindSBusDev"
;******************************************************************************

;*** Prüfen ob Laufwerk installiert werden kann.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk kann installiert werden.
:INIT_DEV_TEST		lda	#$00
			tax
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
			cpx	#$00			;Installationsfehler ?
			bne	:52			; => Ja, Abbruch...
			cpy	#DrvNative		;SD2IEC-Laufwerk installieren ?
			beq	:54			; => Ja, weiter...

;--- Auf SD2IEC mit "M-R"-Emulation testen.
			jsr	TestSD2IEC		;Laufwerk überprüfen.
			cpx	#$ff			;Aktuelles Laufwerk SD2IEC?
			beq	:54			; => Weiter...

;--- Kompatibles Laufwerk suchen.
::52			lda	#DrvNative
			ldy	DrvAdrGEOS
			jsr	a_FindDrive		;SD2IEC-Laufwerk suchen.
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
::54			jmp	InstallDriver

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
