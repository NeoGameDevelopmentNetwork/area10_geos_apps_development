; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;--- Ergänzung: 17.10.18/M.Kanet
;Der SD2IEC-Treiber ist die Weiterentwicklung des IECBus-NM-Treibers.
;IECBus-NM ist auf Grund des Codes im SD2IEC aber nicht in der Lage
;Sektoren oberhalb von Spur 128(8Mb) einzulesen. Der Treiber ist dafür
;kompatibel mit CMD-FD oder CMD-HD.
;Im SD2IEC-Treiber werden jetzt spezifische Aufrufe für den TurboDOS-
;FastLoader der 1571 verwendet um das Problem der 8Mb-Grenze zu umgehen.
;Das führt dazu das der Treiber nur noch mit dem SD2IEC funktioniert.
;Da beide Treiber die gleiche ID verwendet kann entweder IECBUS oder
;SD2IEC in MegaPatch eingebunden werden. Beide Treiber nutzen INIT_IECBUS.
;Getestet mit SD2IEC/LarsP-mini, Firmware 1.0.0/24.
;
;--- Ergänzung: 07.12.19/M.Kanet
;Ersetzt durch s.INIT_SD2IEC.
;******************************************************************************

			n "mod.MDD_#180"
			t "G3_SymMacExt"

if Flag64_128 = TRUE_C64
			t "G3_V.Cl.64.Disk"
endif
if Flag64_128 = TRUE_C128
			t "G3_V.Cl.128.Disk"
endif

			t "-DD_JumpTab"
			t "-DD_InitSD2IEC"

;*** Prüfen ob Laufwerk installiert werden kann.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk kann installiert werden.
:xTestDriveMode		ldx	#NO_ERROR
			txa
			tay
			rts

;*** Laufwerk installieren.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk installiert.
;			     = $0D, Laufwerkstyp nicht verfügbar.
:xInstallDrive		sta	DriveMode		;Laufwerksdaten speichern.
			stx	DriveAdr

			jsr	PrepareDskDrv		;Treiber temporär installieren.

;--- Angeschlossenes Laufwerk testen.
::51			jsr	InitForIO
			lda	DriveAdr
			jsr	DetectDrive
			pha
			jsr	DoneWithIO
			pla
			beq	:52

			ldx	DriveAdr
			lda	ConTabDrvAdrLO -8,x
			sta	Text_NewDrive3 +0
			lda	ConTabDrvAdrHI -8,x
			sta	Text_NewDrive3 +1

			txa
			clc
			adc	#$39
			sta	Text_NewDrive1

			LoadW	r0,Dlg_TurnOnDev
			jsr	DoDlgBox		;Dialogbox: Laufwerk einschalten.
			lda	sysDBData
			cmp	#OK
			beq	:51

;--- Kein passendes Laufwerk gefunden.
			ldx	#DEV_NOT_FOUND
			rts

;--- Laufwerk installieren.
::52			jsr	PrepareDskDrv		;Treiber temporär installieren.

;--- SD2IEC-Kennung speichern.
			jsr	TestSD2IEC		;Aktuelles Laufwerk SD2IEC?
			cpx	#$ff			;SD2IEC ?
			bne	:55			; => Nein, weiter...

			ldx	DriveAdr		;Laufwerksdaten setzen.
			lda	#SET_MODE_SD2IEC
			sta	Flag_SD2IEC
			ora	RealDrvMode -8,x
			sta	RealDrvMode -8,x	;SD2IEC-Flag in RealDrvMode setzen.

::55			jsr	InitForDskDvJob		;Laufwerkstreiber in REU
			jsr	StashRAM		;kopieren.
			jsr	DoneWithDskDvJob

;--- Ende, kein Fehler...
			ldx	#NO_ERROR
			rts

;*** Laufwerkstreiber vorbereiten.
:PrepareDskDrv		lda	#$00			;Aktuelles Laufwerk zurücksetzen.
			sta	curDevice

			lda	DriveAdr		;GEOS-Laufwerk aktivieren.
			jsr	SetDevice

			ldx	DriveAdr		;Laufwerksdaten setzen.
;			stx	curDrive		;Durch ":SetDevice" gesetzt.
			lda	DriveMode
			sta	RealDrvType -8,x
			sta	BASE_DDRV_DATA + (DiskDrvType - DISK_BASE)
			bmi	:ram_drive		;RAM-Laufwerk ? => Ja, weiter...
::disk_drive		and	#%01000111		;Shadow-Bit und Format isolieren.
			bne	:set_drive_type
::ram_drive		and	#%10000111		;RAM-Bit und Format isolieren.
::set_drive_type	sta	driveType   -8,x	;GEOS-Laufwerkstyp speichern.
			sta	curType
			lda	#SET_MODE_SUBDIR
			sta	RealDrvMode -8,x

;--- Treiber installieren.
			jsr	i_MoveData		;Laufwerkstreiber aktivieren.
			w	BASE_DDRV_DATA
			w	DISK_BASE
			w	SIZE_DDRV_DATA
			rts

;*** Laufwerk deinstallieren.
;    Übergabe:		xReg = Laufwerksadresse.
:xDeInstallDrive	lda	#$00			;Laufwerksdaten löschen.
			sta	ramBase     -8,x
			sta	driveType   -8,x
			sta	driveData   -8,x
			sta	turboFlags  -8,x
			sta	RealDrvType -8,x
			sta	RealDrvMode -8,x
			tax
			rts

;*** Ist Laufwerk eingeschaltet ?
;Übergabe: AKKU = Laufwerks-Adresse.
:DetectDrive		tax				;Laufwerksadresse einlesen und
			lda	#15			;testen ob Laufwerk aktiv.
			tay
			jsr	SETLFS
			lda	#0			;Kein Dateiname erforderlich.
			tax
			tay
			jsr	SETNAM
			jsr	OPENCHN			;Befehlskanal öffnen.
			lda	#15
			jsr	CLOSE			;Befehlskanal schließen.
			lda	STATUS			;STATUS = OK ?
			rts

;*** Titelzeile in Dialogbox löschen.
:Dlg_DrawTitel		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$30,$3f
			w	$0040 ! DOUBLE_W,$00ff ! DOUBLE_W ! ADD1_W
			lda	C_DBoxTitel
			jsr	DirectColor
			jmp	UseSystemFont

;*** Systemvariablen.
:DriveMode		b $00
:DriveAdr		b $00

;*** Dialogbox: Laufwerk einschalten. Geräteadresse = #8 bis #19
:Dlg_TurnOnDev		b %01100001
			b $30,$97
			w $0040 ! DOUBLE_W,$00ff ! DOUBLE_W ! ADD1_W

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR ,$0c,$0b
			w Dlg_Titel
			b DBTXTSTR ,$0c,$20
			w :52

if Sprache = Deutsch
			b DBTXTSTR ,$0c,$2a
			w :53
			b DBTXTSTR ,$0c,$40
			w Text_NewDrive2
			b OK       ,$01,$50
			b CANCEL   ,$11,$50
			b NULL

::52			b "Bitte schalten Sie jetzt",NULL
::53			b "das neue Laufwerk "
:Text_NewDrive1		b "x: ein!",NULL
:Text_NewDrive2		b PLAINTEXT
			b "(Geräteadresse #"
:Text_NewDrive3		b "xx)",NULL
:Dlg_Titel		b PLAINTEXT,BOLDON
			b "Information",NULL
endif

if Sprache = Englisch
			b DBTXTSTR,$0c,$40
			w Text_NewDrive2
			b OK      ,$01,$50
			b CANCEL  ,$11,$50
			b NULL

::52			b "Please switch on drive "
:Text_NewDrive1		b "x: !",NULL
:Text_NewDrive2		b PLAINTEXT
			b "(Device adress #"
:Text_NewDrive3		b "xx)",NULL
:Dlg_Titel		b PLAINTEXT,BOLDON
			b "Information",NULL
endif

:ConTabDrvAdrLO		b "0","0","1","1"
:ConTabDrvAdrHI		b "8","9","0","1"

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
:END_INIT		g BASE_DDRV_INIT + SIZE_DDRV_INIT
:DSK_INIT_SIZE		= END_INIT - BASE_DDRV_INIT
;******************************************************************************
