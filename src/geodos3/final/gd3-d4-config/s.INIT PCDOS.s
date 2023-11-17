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
			n "mod.MDD_#160"
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
;			b "PCDOS"
;			b NULL
;******************************************************************************

;******************************************************************************
;*** Shared code.
;******************************************************************************
			t "-DD_DDrvPrepare"
			t "-DD_DDrvUnload"
			t "-DD_DDrvClrDat"
;******************************************************************************
			t "-DD_Dev.PCDOS"
;******************************************************************************

;******************************************************************************
;*** Erweiterte PCDOS-Funktionen.
;******************************************************************************
:DataExtDOS		d "obj.PCDOS",NULL
;******************************************************************************

;*** Prüfen ob Laufwerk installiert werden kann.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk kann installiert werden.
:INIT_DEV_TEST		ldy	#1			;1x64K für PCDOS.
			jmp	FindFreeRAM

;*** Laufwerk installieren.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk installiert.
;			     = $0D, Laufwerkstyp nicht verfügbar.
:INIT_DEV_INSTALL	sta	DrvMode			;Laufwerksdaten speichern.
			stx	DrvAdrGEOS

			jsr	DskDev_Prepare		;Treiber temporär installieren.

			ldy	#1			;1x64K für PCDOS.
			jsr	FindFreeRAM
			cpx	#NO_ERROR		;Ist genügend Speicher frei ?
			bne	:53			; => Nein, Installationsfehler.

			sta	drvRAMBase		;Startadresse RAM-Speicher merken.

;--- Angeschlossenes Laufwerk testen.
::51			lda	DrvAdrGEOS		;Aktuelles Laufwerk feststellen.
			jsr	a_TestDriveType
			cpx	#NO_ERROR		;Installationsfehler ?
			bne	:53			; => Ja, Abbruch...

			lda	DrvMode
			cmp	#Drv81DOS
			bne	:54

;--- 1581/DOS installieren.
			cpy	#Drv1581		;1581 erkannt ?
			beq	:57			; => Ja, weiter...

;--- Kompatibles Laufwerk suchen.
::Find81DOS		lda	#Drv1581
			ldy	DrvAdrGEOS
			jsr	a_FindDrive		;1581-Laufwerk suchen.
			txa				;Laufwerk gefunden ?
			beq	:57			; => Ja, weiter...

			lda	DrvAdrGEOS
			jsr	a_TurnOnNewDrive	;Dialogbox ausgeben.
			txa				;Lauafwerk eingeschaltet ?
			beq	:Find81DOS		; => Ja, Laufwerk suchen...

;--- Kein passendes Laufwerk gefunden.
::52			ldx	#DEV_NOT_FOUND
::53			rts

;--- CMDFD/DOS installieren.
::54			cpy	#DrvFD			;CMDFD erkannt ?
			beq	:57			; => Ja, weiter...

;--- Kompatibles Laufwerk suchen.
::FindFDDOS		lda	#DrvFD
			ldy	DrvAdrGEOS
			jsr	a_FindDrive		;CMDFD-Laufwerk suchen.
			txa				;Laufwerk gefunden ?
			beq	:57			; => Ja, weiter...

			lda	DrvAdrGEOS
			jsr	a_TurnOnNewDrive	;Dialogbox ausgeben.
			txa				;Lauafwerk eingeschaltet ?
			beq	:FindFDDOS		; => Ja, Laufwerk suchen...
			bne	:52

;--- Laufwerk installieren.
::57			jmp	InstallDriver		;Treiber installieren.

;*** Laufwerk deinstallieren.
;    Übergabe:		xReg = Laufwerksadresse.
:INIT_DEV_REMOVE	stx	DrvAdrGEOS

;			ldx	DrvAdrGEOS
			jsr	DskDev_Unload		;RAM-Speicher freigeben.

			ldx	DrvAdrGEOS
			jmp	DskDev_ClrData		;Laufwerksdaten zurücksetzen.

;*** Variablen.
:drvRAMBase		b $00

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
:END_INIT		g BASE_DDRV_INIT + SIZE_DDRV_INIT
:DSK_INIT_SIZE		= END_INIT - BASE_DDRV_INIT
;******************************************************************************
