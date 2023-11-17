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
			t "-DD_DDrvPrepare"
			t "-DD_DDrvClrDat"
			t "-DD_InitSD2IEC"
			t "-DD_FindSBusDev"
:TestSBusDrive		t "-D3_TestSBusDrv"
:ClrDBoxTitel		t "-G3_DBoxTitel"
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
::51			jsr	InitForIO
			lda	DrvAdrGEOS
			jsr	TestSBusDrive
			pha
			jsr	DoneWithIO
			pla
			beq	:52

			ldx	DrvAdrGEOS
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
::52			jsr	DskDev_Prepare		;Treiber temporär installieren.

;--- SD2IEC-Kennung speichern.
			jsr	TestSD2IEC		;Aktuelles Laufwerk SD2IEC?
			cpx	#$ff			;SD2IEC ?
			bne	:55			; => Nein, weiter...

			ldx	DrvAdrGEOS		;Laufwerksdaten setzen.
			lda	#SET_MODE_SD2IEC
			sta	Flag_SD2IEC
			ora	#SET_MODE_SUBDIR
			ora	RealDrvMode -8,x
			sta	RealDrvMode -8,x	;SD2IEC-Flag in RealDrvMode setzen.

;--- Laufwerkstreiber speichern.
::55			lda	DrvAdrGEOS		;Aktuelles Laufwerk festlegen.
			sta	curDevice		;Adresse wird für die Routine
			sta	curDrive		;":InitForDskDvJob" benötigt.

			jsr	InitForDskDvJob		;Laufwerkstreiber in REU
			jsr	StashRAM		;kopieren.
			jsr	DoneWithDskDvJob

;--- Ende, kein Fehler...
			ldx	#NO_ERROR
			rts

;*** Laufwerk deinstallieren.
;    Übergabe:		xReg = Laufwerksadresse.
:INIT_DEV_REMOVE	stx	DrvAdrGEOS

;			ldx	DrvAdrGEOS
;			jsr	DskDev_Unload		;RAM-Speicher freigeben.

;			ldx	DrvAdrGEOS
			jmp	DskDev_ClrData		;Laufwerksdaten zurücksetzen.

;*** Systemvariablen.
:DrvMode		b $00
:DrvAdrGEOS		b $00

;*** Dialogbox: Laufwerk einschalten. Geräteadresse = #8 bis #19
:Dlg_TurnOnDev		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w ClrDBoxTitel
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
