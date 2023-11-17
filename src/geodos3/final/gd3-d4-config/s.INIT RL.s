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
			n "mod.MDD_#150"
			t "G3_Disk.V.Class"

;*** Zusätzliche Symboltabellen.
if .p
			t "SymbTab_RLNK"
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
;			b "CMD-RL"
;			b NULL
;******************************************************************************

;******************************************************************************
;*** Shared code.
;******************************************************************************
			t "-DD_DDrvPrepare"
			t "-DD_DDrvClrDat"
;******************************************************************************
			t "-DD_Dev.CMDRL"
;******************************************************************************
			t "-R3_DetectRLNK"
;******************************************************************************

;*** Prüfen ob Laufwerk installiert werden kann.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk kann installiert werden.
:INIT_DEV_TEST		= DetectRLNK

;*** Laufwerk installieren.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk installiert.
;			     = $0D, Laufwerkstyp nicht verfügbar.
:INIT_DEV_INSTALL	sta	DrvMode			;Laufwerksdaten speichern.
			stx	DrvAdrGEOS

			jsr	INIT_DEV_TEST		;Auf RAMLink testen.
			txa				;RAMLink verfügbar ?
			bne	:err			; => Nein, Abbruch...

			lda	DrvMode			;Laufwerksmodus einlesen.
			ldx	DrvAdrGEOS		;GEOS-Laufwerksadresse einlesen.
			jsr	DskDev_Prepare		;Treiber installieren.

			ldx	DrvAdrGEOS
			ldy	#SET_MODE_PARTITION
			lda	curType
			and	#%00000111
			cmp	#DrvNative
			bne	:1
			ldy	#SET_MODE_PARTITION ! SET_MODE_SUBDIR
::1			tya
			ora	#SET_MODE_FASTDISK
			sta	RealDrvMode -8,x

;--- RAMBase nicht löschen.
;Wird ggf. durch den Editor gesetzt und
;dazu genutzt, um auf ein gültiges
;Verzeichnis zu prüfen.
;			lda	#$00
;			sta	ramBase     -8,x

;--- Laufwerk installieren.
			jmp	InstallDriver

;--- Kein passendes Laufwerk gefunden.
::err			ldx	#DEV_NOT_FOUND
			rts

;*** Laufwerk deinstallieren.
;    Übergabe:		xReg = Laufwerksadresse.
:INIT_DEV_REMOVE	stx	DrvAdrGEOS

;			ldx	DrvAdrGEOS
;			jsr	DskDev_Unload		;RAM-Speicher freigeben.

;			ldx	DrvAdrGEOS
			jmp	DskDev_ClrData		;Laufwerksdaten zurücksetzen.

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
:END_INIT		g BASE_DDRV_INIT + SIZE_DDRV_INIT
:DSK_INIT_SIZE		= END_INIT - BASE_DDRV_INIT
;******************************************************************************
