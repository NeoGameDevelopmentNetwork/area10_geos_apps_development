; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;Da für den GEOS.Editor nicht genügend freier Speicher zur Verfügung steht,
;werden bei der Installation eines neuen Laufwerks die Treiber und
;Installationsroutinen kurzzeitig in die REU (Bank MP3_64K_DATA) ausgelagert.
;******************************************************************************

			n "mod.GE_#101"
			t "G3_SymMacExtEdit"
			t "e.Register.ext"

			t "src.Edit.Class"

			a "Markus Kanet"
			o VLIR_BASE

;******************************************************************************
;*** Hauptmenu initialisieren.
;******************************************************************************
:Main

if Flag64_128 = TRUE_C128
			bit	graphMode
			bpl	:1

			lda	#$04			;Farbe für Speicherbelegung.
			sta	Draw_Info_Block+1
			lda	#$07
			sta	Draw_Info_Spool+1
			lda	#$02
			sta	Draw_Info_Task+1
			lda	#$05
			sta	Draw_Info_Disk+1
			lda	#$08
			sta	Draw_Info_GEOS+1
;			lda	#$00
;			sta	Draw_Info_NoRAM+1
			lda	#$0f
			sta	Draw_Info_Free+1
			lda	#"2"
			b	$2c
::1			lda	#"1"
			sta	MhzModus
endif

			lda	#$ff			;Falls Boot-Konfiguration ungültig
			sta	firstBoot		;war, ":firstBoot" löschen. Wird
							;später wieder zurückgesetzt!!!

;--- Ergänzung: 15.12.18/M.Kanet
;SD-Laufwerke für DiskImage-Wechsel erkennen.
			jsr	TestSD2IEC		;SD2IEC-Laufwerke erkennen.

			jsr	CountDrives		;Laufwerke zählen.

			jsr	GetNm_DrvA		;Laufwerk A: Bezeichnung einlesen.
			jsr	GetNm_DrvB		;Laufwerk B: Bezeichnung einlesen.
			jsr	GetNm_DrvC		;Laufwerk C: Bezeichnung einlesen.
			jsr	GetNm_DrvD		;Laufwerk D: Bezeichnung einlesen.

			jsr	GetNm_PartA		;Laufwerk A: Partitionsname lesen.
			jsr	GetNm_PartB		;Laufwerk B: Partitionsname lesen.
			jsr	GetNm_PartC		;Laufwerk C: Partitionsname lesen.
			jsr	GetNm_PartD		;Laufwerk D: Partitionsname lesen.

			jsr	GetCurDevice		;Name der aktuellen Eingabe-/
							;Druckertreiber kopieren.

;--- Ergänzung: 31.12.18/M.Kanet
;GCalcFix für Druckertreiber die $7F3F überschreiben.
if Flag64_128 = TRUE_C64
			jsr	GetGCalcFixMode
endif

;--- Ergänzung: 03.01.19/M.Kanet
;Zusätzliche Label um im GEOS.Editor die Umschaltung
;zwischen QWERTZ/QWERTY zu ermöglchen.
if Sprache = Deutsch
			jsr	GetQWERTZMode
endif

			jsr	GetScrSvName		;Name Bildschirmschoner einlesen.
			jsr	GetSerCodeGEOS		;GEOS-ID nach ASCII wandeln.

			jsr	SetBank_TaskSpl		;TaskMan/Spooler-RAM belegen.

			jsr	GetMoveDataMode		;MoveData-Optionen festlegen.

			jsr	GetSCPUModes		;SCPU-Optionen festlegen.

			bit	SCPU_Aktiv		;SCPU verfügbar ?
			bpl	:2			; => Nein, weiter...

			lda	#<GetSpeedSCPU		;SCPU-Geschwindigkeitsanzeige
			sta	appMain  +0		;installieren.
			lda	#>GetSpeedSCPU
			sta	appMain  +1

::2			jsr	SetADDR_Register	;Register-Routine einlesen.
			jsr	FetchRAM
			jsr	DrawMenuWindow		;Menüfenster zeichnen.

			LoadW	r0,RegisterTab1		;Register-Menü installieren.
			jmp	DoRegister

;--- Ergänzung: 15.12.18/M.Kanet
;Neue Routinen für SD2IEC-Unterstützung ergänzt.

if Flag64_128 = TRUE_C64
;*** SD2IEC-DiskImage-Wechsel für C64:
;Teil des Hauptmenüs.
			t "-G3_TestSD2IEC"
			t "-G3_SlctDskImg"
endif

if Flag64_128 = TRUE_C128
;*** SD2IEC-DiskImage-Wechsel für C128:
;Aus Platzgründen in Bank#0 ausgelagert.
;Der Code wird in den Bereich geladen der für die
;Installation der Laufwerkstreiber reserviert ist:
;APP_RAM / BASE_DDRV_INSTALL und BASE_DDRV_DATA
;Da in diesem Bereich auch die Liste der DiskImages
;abgelegt wird (ab APP_RAM) befindet sich der Code
;am Ende des reservierten Bereichs.

;*** Einsprungadressen für SD2IEC-Routinen.
:xTestSD2IEC		= Base1SDTools +0
:xSlctDiskImg		= Base1SDTools +3

;*** SD2IEC-Routinen aufrufen.
;--- Ergänzung: 05.03.2019/M.Kanet
;Umstellung von Vlir-Routine nach MoveBData:
;Der Code befindet sich nach dem Programmstart in Bank#0 und
;wird über MoveBData in Bank#1 kopiert.
;Das nachladen von Disk führt zu einem Fehler wenn das Laufwerk
;mit dem Editor gewechselt wurde und keine Kopie des Editors mehr
;verfügbar ist.
:TestSD2IEC		lda	#$00			;Aufruf: SD2IEC finden.
			b $2c
:SlctDiskImg		lda	#$ff			;Aufruf: SD2IEC-DiskImage wechseln.

:LoadSysPart		pha

			LoadW	r0,Base0SDTools
			LoadW	r1,Base1SDTools
			LoadW	r2,SizeSDTools
			LoadB	r3L,$00			;SD-Tools aus Bank#0 nach Bank#1
			LoadB	r3H,$01			;einlesen.
			jsr	MoveBData

			pla
			bne	:1
			jmp	xTestSD2IEC		;Auf SD2IEC testen.
::1			jmp	xSlctDiskImg		;Partition wählen.
endif

;*** Flag für Laufwerk A: bis D: => $FF=SD2IEC.
.DrvTypeSD		s $04

;*** Zusätzliche Verzeichnis-Einträge.
;Texte können nicht in "-SlctDskImg" aufgeführt werden da
;verschachtelte if/endif-Abfragen nicht erlaubt sind.
if Sprache = Deutsch
.DirNavEntry		b "<=        (ROOT)"
			b "..      (ZURÜCK)"
endif
if Sprache = Englisch
.DirNavEntry		b "<=        (ROOT)"
			b "..          (UP)"
endif

;******************************************************************************
;*** Menü aufbauen und Menü-Icons aktivieren.
;******************************************************************************
;*** Menüfenster zeichnen.
:DrawMenuWindow		lda	#$00			;Menübereich löschen.
			jsr	SetPattern
			jsr	i_Rectangle
			b	$00,$c7
			w	$0000 ! DOUBLE_W,$013f ! DOUBLE_W ! ADD1_W
			lda	#%11111111		;Menürahmen zeichnen.
			jsr	FrameRectangle
			lda	C_WinBack
			jsr	DirectColor

			LoadB	r2H,$07			;Titelzeile zeichnen.
			jsr	Rectangle
			lda	C_WinTitel
			jsr	DirectColor

			jsr	RegisterSetFont
			LoadW	r0,TxGEOSEdit
			jsr	PutString

			lda	C_WinIcon		;Icon-Menü aktivieren.
			jsr	i_UserColor
			b	$00 ! DOUBLE_B,$01,$0a ! DOUBLE_B,$03
			LoadW	r0,IconMenu
			jmp	DoIcons

;*** Taktfrequenz SCPU abfragen und anzeigen.
;    Diese Routine wird über ":appMain" aufgerufen und ist nur
;    bei eingeschalteter SCPU aktiv!
:GetSpeedSCPU		jsr	CheckForSpeed		;Aktuellen SCPU-Takt einlesen.
			cmp	LastSpeedMode		;Hat sich SCPU-Takt geändert ?
			beq	:1			; => Nein, weiter...
			sta	LastSpeedMode		;Neuen Takt zwischenspeichern und
			sta	BootSpeed		;anzeigen.

			CmpBI	RegisterAktiv,2		;Ist Registerkarte für SCPU aktiv ?
			bne	:1			; => Nein, weiter...

			LoadW	r15,RegTMenu_2a		;Registerkarte aktualisieren.
			jsr	RegisterUpdate
::1			rts

;*** MoveData-Option definieren.
;--- Ergänzung; 21.07.18/M.Kanet
;MOVEDATA funktioniert zwar theoretisch mit allen REUs, da
;aber GEORAM/BBGRAM keinen eigenen Chip dafür verwenden sind diese
;Speichererweiterungen hier evtl. langsamer als die Standard-Routinen.
;Daher wird die MOVEDATA-Option nur noch mit einer C=REU freigeschaltet.
:GetMoveDataMode	ldx	#BOX_OPTION_VIEW
			bit	SCPU_Aktiv		;SCPU aktiv?
			bmi	:1			;Ja, MOVEDATA deaktivieren.
			lda	GEOS_RAM_TYP		;Speichererweiterung testen.
			and	#%01000000		;C=REU?
			beq	:1			;Nein, MOVEDATA deaktivieren.
			ldx	#BOX_OPTION		;C=REU => MOVEDATA freischalten.
::1			stx	RegTMenu_2b
			cpx	#BOX_OPTION		;MOVEDATA verfügbar?
			beq	:2			;Ja, weiter...
			lda	sysRAMFlg		;Nicht verfügbar, dann zur
			and	#%01111111		;Sicherheit die Option ausschalten.
			sta	sysRAMFlg		;sysRAMFlag und BootRAM_Flag
			sta	sysFlgCopy		;getrennt behandeln.
			lda	BootRAM_Flag
			and	#%01111111
			sta	BootRAM_Flag
::2			rts

;*** SCPU-Optionen nur bei vorhandener SCPU aktivieren.
:GetSCPUModes		lda	#BOX_OPTION
			bit	SCPU_Aktiv
			bmi	:1
			lda	#BOX_OPTION_VIEW
::1			sta	RegTMenu_2a
			sta	RegTMenu_2c
			rts

;--- Ergänzung: 31.12.18/M.Kanet
if Flag64_128 = TRUE_C64
;*** GeoCalc-Fix aktiv?
;geoCalc64 nutzt beim Drucken ab $$5569 eine Routine ab $7F3F. Diese Adresse
;ist aber noch für Druckertreiber reserviert.
:GetGCalcFixMode	lda	#$80
			ldx	GCalcFix1 +4
			cpx	#$3f
			beq	:1
			asl
::1			sta	BootGCalcFix
			rts
endif

;--- Ergänzung: 03.01.19/M.Kanet
if Sprache = Deutsch
;*** QWERTZ-Tastatur aktiv?
:GetQWERTZMode		ldx	#$ff
			lda	key0z
			cmp	#"y"
			beq	:1
			inx
::1			stx	BootQWERTZ
			rts
endif

;******************************************************************************
;*** Hauptmenu beenden.
;******************************************************************************
;*** GEOS.Editor verlassen.
:Menu_ExitConfig	jsr	CheckDrvConfig		;Konfiguration überprüfen.
			txa				;Konfigurationsfehler ?
			beq	:3			; => Nein, weiter...

			ldx	#>Dlg_IllegalCfg	;Fehler! Konfiguration ist
			lda	#<Dlg_IllegalCfg	;ungültig.
			jmp	SystemDlgBox

::3			jsr	ExitRegisterMenu	;Systemzeichensatz aktivieren.
							;Wichtig, da die Register-Routine
							;einen eigenen Font aktiviert!

			bit	firstBootCopy		;GEOS-BootUP ?
			bmi	:4			; => Nein, weiter...

			jsr	LdBootScrn		;Hintergrundbild laden.
::4			jmp	ExitToDeskTop		;Rückkehr zum DeskTop.

;******************************************************************************
;*** Konfiguration speichern.
;******************************************************************************
;*** Konfiguration speichern.
:Menu_SaveConfig	ldx	#$00			;Reservierte Speicherbänke
::1			lda	BankUsed,x		;in Konfiguration übertragen.
			cmp	#BankCode_Block
			beq	:2
			lda	#$00
::2			sta	BootBankBlocked,x
			inx
			cpx	ramExpSize
			bcc	:1

::3			cpx	#RAM_MAX_SIZE		;Nicht verfügbarer Speicher in
			beq	:4			;Konfiguration freigeben.

			lda	#$00
			sta	BootBankBlocked,x
			inx
			bne	:3

;--- Konfiguration in Zwischenspeicher übertragen.
::4			ldy	#8
::5			tya
			pha

			lda	#$00			;Aktuelles Laufwerk in
			sta	BootConfig  -8,y	;Konfiguration löschen.
			sta	BootPartRL  -8,y
			sta	BootPartType-8,y

			lda	driveType   -8,y	;Ist Laufwerk definiert ?
			beq	:8			; => Nein, weiter...
			bpl	:5a
;--- Ergänzung: 06.08.18/M.Kanet
;Die Extended RAM-Laufwerke für GeoRAM, C=REU und SCPU nutzen die
;Bits #6(SCPU), #5+#4(GeoRAM), #5(C=REU).
			lda	RealDrvMode -8,y	;Laufwerk partitioniert ?
			and	#%01110000		;RAM41/71/81/NM ?
			bne	:5a			; => Nein, weiter...
			lda	ramBase     -8,y	;Bei RAM-Laufwerk Startadresse in
			sta	BootRamBase -8,y	;GEOS-DACC speichern.
::5a			lda	RealDrvType -8,y	;Laufwerkstyp in
			sta	BootConfig  -8,y	;Konfiguration übertragen.

			lda	RealDrvMode -8,y	;Laufwerk partitioniert ?
			bpl	:8			; => Nein, weiter...

			tya
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	NewDisk			;Diskette/Partition öffnen.
			txa				;Diskettenfehler ?
			bne	:6			; => Ja, weiter...

			lda	#$ff			;Aktive Partition einlesen.
			sta	r3H
			LoadW	r4,dirEntryBuf
			jsr	GetPDirEntry

::6			lda	#$00			;Vorgabe: keine Partition setzen.
			cpx	#NO_ERROR		;Diskettenfehler ?
			bne	:7			; => Ja, weiter...
			lda	dirEntryBuf +2		;Partitions-Nr. einlesen.

::7			ldy	curDrive
			sta	BootPartRL  -8,y	;Partition auf RAMLink speichern.
			lda	RealDrvType -8,y	;Partitionsformat speichern.
			and	#%00001111
			sta	BootPartType-8,y

::8			pla
			tay
			iny
			cpy	#12
			bcc	:5

;--- Konfiguration speichern.
			jsr	SetSystemDevice		;Startlaufwerk aktivieren.
			txa				;Laufwerksfehler ? ?
			bne	SvErr_NoSysFile		; => Ja, Abbruch..

			LoadW	r0,SysFileName
			jsr	OpenRecordFile		;Systemdatei öffnen.
			txa				;Diskettenfehler ?
			bne	SvErr_NoSysFile		; => Ja, Abbruch..

			lda	#$00
			jsr	PointRecord		;Zeiger auf ersten Datensatz.
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Ersten Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	SvErr_DiskError		; => Ja, Abbruch..

			ldy	#0
::9			lda	BootVarStart,y		;Konfiguration am Anfang
			sta	diskBlkBuf +2,y		;des Programms speichern.
			iny
			cpy	#(BootVarEnd - BootVarStart)
			bcc	:9

			jsr	PutBlock		;Sektor zurück auf Disk schreiben.
			txa				;Diskettenfehler ?
			bne	:0			; => Ja, Abbruch..
			jmp	CloseRecordFile		;Systemdatei schließen.
::0			jmp	SvErr_DiskError

;******************************************************************************
;*** Unterprogramme.
;******************************************************************************
;*** Fehler: "Systemdatei ist nicht zu finden!"
:SvErr_NoSysFile	lda	SysDrive
			clc
			adc	#$39
			sta	SaveErrorDrive

			ldx	#>Dlg_ErrLdCfgFile
			lda	#<Dlg_ErrLdCfgFile
			jmp	SystemDlgBox

;*** Fehler: "Konfiguration kann nicht gespeichert werden!"
:SvErr_DiskError	ldx	#>Dlg_SaveError
			lda	#<Dlg_SaveError
			jmp	SystemDlgBox

;*** Dialogbox: "Nicht genügend freier Speicher!".
:DrvInstErrNoRAM	jsr	ClearDriveData		;Laufwerksdaten löschen.
			jsr	CountDrives		;Installierte Laufwerke zählen.

			lda	#< Dlg_InstErrNoRAM
			ldx	#> Dlg_InstErrNoRAM
			jsr	SystemDlgBox
			jmp	SetBank_TaskSpl		;TaskMan/Spooler-RAM belegen.

;*** Dialogbox: "Laufwerk konnte nicht installiert werden!".
:DrvInstallError	jsr	ClearDriveData		;Laufwerksdaten löschen.
			jsr	CountDrives		;Installierte Laufwerke zählen.
:DrvNotInstalled	lda	#< Dlg_InstallError
			ldx	#> Dlg_InstallError
			jsr	SystemDlgBox
			jmp	SetBank_TaskSpl		;TaskMan/Spooler-RAM belegen.

;------------------------------------------------------------------------------
;<*> Laufwerk muß nicht abgeschaltet werden.
;------------------------------------------------------------------------------
;<*>;*** Laufwerk abschalten.
;<*>:TurnOffDrive	pha
;<*>			txa
;<*>			jsr	IsDrvOnline		;Laufwerk am ser. Bus suchen.
;<*>			tax
;<*>			pla
;<*>
;<*>			cpx	#NO_ERROR		;Ist Laufwerk eingeschaltet ?
;<*>			bne	:1			; => Nein, weiter...
;<*>
;<*>			tax				;RAM-Laufwerk abschalten ?
;<*>			bmi	:1			; => Ja, weiter...
;<*>
;<*>			and	#%11110000
;<*>			cmp	#DrvRAMLink		;RAMLink-Laufwerk ?
;<*>			beq	:1			; => Ja, weiter...
;<*>
;<*>			lda	NewDrive
;<*>			clc
;<*>			adc	#$39
;<*>			sta	TurnOffDrvAdr		;Laufwerksbuchstabe definieren.
;<*>
;<*>			ldx	#>Dlg_TurnOffDrv
;<*>			lda	#<Dlg_TurnOffDrv
;<*>			jsr	SystemDlgBox		;Dialogbox: "Laufwerk abschalten".
;<*>
;<*>::1			jsr	ClearDriveData		;Laufwerk löschen.
;<*>			jmp	CountDrives
;------------------------------------------------------------------------------

;*** Datei auswählen.
;    Übergabe:		r7L  = Datei-Typ.
;			r10  = Datei-Klasse.
;    Rückgabe:		In ":dataFileName" steht der Dateiname.
;			xReg = $00, Datei wurde ausgewählt.
:OpenFile		MoveB	r7L,OpenFile_Type
			MoveW	r10,OpenFile_Class

::1			ldx	SysDrive
			lda	driveType -8,x
			bne	:3

			ldx	#8
::2			lda	driveType -8,x
			bne	:3
			inx
			cpx	#12
			bcc	:2
			jmp	Err_IllegalConf

::3			txa
			jsr	SetDevice

::4			MoveB	OpenFile_Type ,r7L
			MoveW	OpenFile_Class,r10
			LoadW	r5 ,dataFileName
			LoadB	r7H,255
			lda	#<Dlg_SlctFile
			ldx	#>Dlg_SlctFile
			jsr	SystemDlgBox		;ScreenSaver auswählen.

			lda	sysDBData
			bpl	:5

			and	#%00001111
			jsr	SetDevice
			txa
			beq	:4
			bne	:1

::5			cmp	#DISK
			beq	:4
			ldx	#$ff
			cmp	#CANCEL			;Abbruch gewählt ?
			beq	:6			; => Ja, Abbruch...
			inx
::6			rts

;******************************************************************************
;*** Neues Laufwerk installieren.
;******************************************************************************
;*** Neuen Laufwerksmodus wählen.
:InstNewDrvA		ldx	#8
			b $2c
:InstNewDrvB		ldx	#9
			b $2c
:InstNewDrvC		ldx	#10
			b $2c
:InstNewDrvD		ldx	#11
			stx	NewDrive		;Laufwerksadresse speichern.

			jsr	FindCopyDkDvFile	;Treiberdatei suchen.
			txa				;Datei gefunden ?
			bne	:error			; => Nein, Abbruch...

			LoadW	r0,Dlg_SlctDMode
			LoadW	r5,dataFileName
			jsr	DoDlgBox		;Laufwerkstyp auswählen.
			CmpBI	sysDBData,CANCEL	;Abbruch gewählt ?
			bne	:prepare
::error			rts				; => Ja, Ende...

;--- Neuen Laufwerkmodus aktivieren.
::prepare		jsr	ClrBank_TaskMan		;Speicherbänke für TaskMan und
			jsr	ClrBank_Spooler		;Spooler löschen, da Laufwerke die
							;höchste Priorität haben!
;--- Laufwerk deinstallieren.
:uninstall		ldx	DB_GetFileEntry
			lda	VLIR_Types ,x		;Neuen Laufwerksmodus einlesen und
			pha				;zwischenspeichern.

			ldx	NewDrive
			cmp	RealDrvType -8,x	;Laufwerkstyp wechseln ?
			beq	:1
			lda	#$00
			sta	BootRamBase -8,x	; -> Vorgabe für ramBase löschen.

::1			lda	RealDrvType -8,x	;Laufwerk installiert ?
			beq	:install		; => Nein, weiter...
			jsr	GetDrvModVec		;Zeiger auf Typen-Tabelle berechnen.
			cmp	#$ff			;Unbekanntes Laufwerk ?
			beq	:install		; => Ja, weiter...

			ldx	NewDrive
			lda	RealDrvType -8,x	;Vorhandenes Laufwerk abschalten ?
			jsr	LoadDskDrvData		;Aktiven Treiber einlesen.
			txa				;Diskettenfehler ?
			bne	:install		; => Ja, Abbruch...

			jsr	purgeAllDrvTurbo	;TurboDOS abschalten.

			ldx	NewDrive
			jsr	DDrv_DeInstall		;Aktuelles Laufwerk De-Installieren.

			jsr	ClearDriveData		;Laufwerk löschen.
			jsr	CountDrives		;Anzahl Laufwerke aktualisieren.

;--- Neues Laufwerk installieren.
::install		pla
			sta	NewDriveMode		;Modus "Kein Laufwerk" gewählt ?
			beq	EndInstallDrive		; => Ja, Ende...

			ldx	NewDrive
			jsr	LoadDskDrvData		;Benötigten Treiber einlesen.
			txa				;Diskettenfehler ?
			bne	:drvInstErr		; => Nein, weiter...

			jsr	purgeAllDrvTurbo	;TurboDOS abschalten.

;--- Ergänzung: 15.06.18/M.Kanet
;Der RAMNative-Treiber erkennt bei der Laufwerksinstallation ob
;bereits einmal ein RAMNative-Laufwerk installiert war. Dazu wird die
;BAM geprüft. Ist diese gültig wird daraus die Größe des Laufwerks ermittelt
;und im GEOS.Editor dann als Größe vorgeschlagen. Damit dies funktioniert
;sollte in :ramBase die frühere Startadresse übergeben werden.
;Wird die Konfiguration im Editor gespeichert wird jetzt auch die :ramBase
;Adresse der RAMLaufwerke gesichert und an dieser Stelle vor der Laufwerks-
;Installation als Vorschlag an die Installationsroutine übergeben.
			ldx	NewDrive		;Ziel-Laufwerk.
			lda	NewDriveMode		;Neuer Laufwerksmodus.

;--- Ergänzung: 06.08.18/M.Kanet
;Die Extended RAM-Laufwerke für GeoRAM, C=REU und SCPU nutzen die
;Bits #6(SCPU), #5+#4(GeoRAM), #5(C=REU).
;			and	#%11110000		;RAM-Laufwerk ?
			bpl	:2
			and	#%01110000		;RAM41/71/81/NM-Laufwerk?
			bne	:2			; => Nein, weiter...
			lda	ramBase -8,x		;ramBase bereits definiert?
			bne	:2			; => Ja, weiter...
;--- Ergänzung: 08.08.18/M.Kanet
;Bei einem Ext.RAM-Laufwerk (SuperRAM, GeoRAAM, C=REU) kann ramBase
;bei einem bereits früher installiertem Laufwerk auch 0 sein.
			lda	BootRamBase -8,x	;Neues RAMLaufwerk. Für RAMNative
			sta	ramBase -8,x		;Startadresse vorschlagen.
::2			lda	NewDriveMode
			jsr	DoInstallDskDev		;Installationsroutine starten.
			txa				;Installationsfehler ?
			beq	:finalize 		; => Nein, weiter...
			cpx	#NO_FREE_RAM
			bne	:drvInstErr
			jmp	DrvInstErrNoRAM		;Fehlermeldung ausgeben.
::drvInstErr		jmp	DrvInstallError		;Fehlermeldung ausgeben.

::finalize		ldx	NewDrive		;Echten Laufwerkstyp einlesen.
			lda	driveType -8,x		;Laufwerk verfügbar ?
			beq	EndInstallDrive		; => Nein, weiter...
			txa
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	ClearDiskName		;Diskettenname löschen.

			ldx	curDrive
			lda	driveType -8,x		;RAM-Laufwerk ?
			bmi	EndInstallDrive		; => Ja, weiter...
			lda	#$ff			;$FF = ser.Bus-Laufwerk ist aktiv.
			sta	DriveInUseTab-8,x

;*** Installation abschließen, neuen Laufwerksmodus anzeigen.
:EndInstallDrive	jsr	SetBank_TaskSpl		;TaskMan/Spooler-RAM belegen.

;--- Ergänzung: 15.12.18/M.Kanet
;SD-Laufwerke für DiskImage-Wechsel erkennen.
			jsr	TestSD2IEC		;SD2IEC-Laufwerke erkennen.

			ldx	NewDrive		;Aktuelles Laufwerk einlesen und
			jsr	GetNm_Drv		;Laufwerksbezeichnungen einlesen.
			ldx	NewDrive		;Aktuelles Laufwerk einlesen und
			jmp	InstNewPart		;Partition installieren.

;******************************************************************************
;*** Neues Partition installieren.
;******************************************************************************
;*** Neue Partition aktivieren.
:InstNewPartA		ldx	#8
			b $2c
:InstNewPartB		ldx	#9
			b $2c
:InstNewPartC		ldx	#10
			b $2c
:InstNewPartD		ldx	#11
:InstNewPart		stx	NewDrive		;Laufwerksadresse speichern.
			lda	driveType  -8,x		;Laufwerk verfügbar ?
			beq	:1
			txa
			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Laufwerksfehler ?
			bne	:1			; => Nein, weiter...
			jsr	GetNm_Part		;Partitionsname einlesen wegen
							;HD-Native, sonst kommt keine
							;Partitionauswahlbox!!!
			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:1			; => Ja, Abbruch...

			ldx	curDrive
			lda	RealDrvMode-8,x		;Partitioniertes Laufwerk ?
			bpl	:1			; => Nein, weiter...

			LoadW	r0,Dlg_SlctPart
			LoadW	r5,dataFileName
			jsr	DoDlgBox		;Partition auswählen.

			jsr	OpenDisk		;Diskette öffnen, dabei aktive
							;Partition auf Gültigkeit testen.
			jmp	GetNm_Part		;Partitionsname einlesen.

;--- Ergänzung: 15.12.18/M.Kanet
;Auf SD2IEC testen und ggf. DiskImage-Wechsel ausführen.
::1			ldx	NewDrive
			lda	RealDrvMode-8,x		;Partitioniertes Laufwerk ?
			bmi	:2			; => Ja, weiter...
			lda	DrvTypeSD  -8,x		;SD2IEC-Laufwerk?
			beq	:2			; => Nein, Ende.
			jsr	SlctDiskImg		;DiskImage wechseln.
::2			jmp	GetNm_Part		;Partitionsname einlesen.

;*** Laufwerke abschalten.
:purgeAllDrvTurbo	ldx	#8			;TurboDOS auf allen Laufwerken
::1			lda	driveType -8,x		;abschalten, da ggf. über die
			beq	:2			;Kernal-Routinen auf die Laufwerke
			txa				;zugegriffen wird.
			pha
			jsr	SetDevice
			jsr	PurgeTurbo
			pla
			tax
::2			inx
			cpx	#12
			bcc	:1

			lda	NewDrive
			jmp	SetDevice

;******************************************************************************
;*** Laufwerksbezeichnung einlesen.
;******************************************************************************
;*** Aktuellen Laufwerksmodus einlesen.
:GetNm_DrvA		ldx	#$08
			b $2c
:GetNm_DrvB		ldx	#$09
			b $2c
:GetNm_DrvC		ldx	#$0a
			b $2c
:GetNm_DrvD		ldx	#$0b
:GetNm_Drv		stx	NewDrive		;Laufwerksadresse speichern.

			ldy	#8			;Zeiger auf Laufwerk #8.
::1			tya				;Aktuelles Laufwerk speichern.
			pha
			ldx	driveType   -8,y	;Laufwerk verfügbar ?
			beq	:2			; => Nein, weiter...

			jsr	SetDevice		;Laufwerkstreiber einlesen.

			ldy	curDrive
			lda	RealDrvType -8,y	;Laufwerkstyp einlesen und mit
			cmp	DiskDrvType		;Laufwerkstreiber vergleichen.
			bne	:3			; => Fehler, unbekanntes Laufwerk.

::2			jsr	GetDrvModVec		;Zeiger auf Typen-Tabelle berechnen.
			cmp	#$ff			;Unbekanntes Laufwerk ?
			bne	:4			; => Nein, weiter...

::3			LoadW	r0,TxDrvUnknown
			jmp	:5

::4			txa
			sta	r0L			;Zeiger auf Tabelle mit Laufwerks-
			lda	#17			;typen-Bezeichnung berechnen.
			sta	r1L
			ldx	#r0L
			ldy	#r1L
			jsr	BBMult
			AddVW	VLIR_Names,r0

::5			pla
			tay				;Zeiger auf Speicher für Laufwerks-
			sec				;name für Laufwerk ermitteln.
			sbc	#$08
			asl
			tax
			lda	DrvNmVec +0,x
			sta	r1L
			lda	DrvNmVec +1,x
			sta	r1H

			tya
			pha
			ldx	#r0L			;Laufwerksbezeichnung kopieren.
			ldy	#r1L
			jsr	CopyString

			pla
			tay
			iny				;Zeiger auf nächstes Laufwerk.
			cpy	#12			;Alle Laufwerke getestet ?
			bcc	:1			;Nein, weiter...
			rts

;******************************************************************************
;*** Partitionsname einlesen.
;******************************************************************************
;*** Partitionsname ausgeben.
:GetNm_Part		ldx	curDrive
			b $2c
:GetNm_PartA		ldx	#8
			b $2c
:GetNm_PartB		ldx	#9
			b $2c
:GetNm_PartC		ldx	#10
			b $2c
:GetNm_PartD		ldx	#11
			stx	NewDrive		;Laufwerksadresse speichern.
			lda	RealDrvType -8,x	;Laufwerk verfügbar ?
			beq	:50			; => Nein, Ende...
			jsr	GetDrvModVec		;Zeiger auf Typen-Tabelle berechnen.
			cmp	#$ff			;Unbekanntes Laufwerk ?
			beq	:50			; => Ja, Abbruch...

			ldx	NewDrive		;Laufwerksadresse einlesen und
			lda	RealDrvMode -8,x	;CMD-Laufwerk gefunden ?
			bpl	:50			; => Nein, weiter...

			txa
			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Laufwerksfehler ?
			bne	:50			; => Nein, weiter...

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			beq	:1			; => Nein, weiter...

::50			jsr	SetVecPartNm		;Zeiger auf Namenspeicher setzen.

;--- Ergänzung: 16.12.18/M.Kanet
;Bei SD2IEC Textkennung setzen.
			ldx	NewDrive		;Laufwerksadresse einlesen.
			lda	DrvTypeSD -8,x		;SD2IEC ?
			beq	:51			; => Nein, weiter...
			LoadW	r0,TxSD2IEC		;SD2IEC-Kennung setzen.
			ldx	#r0L
			ldy	#r1L
			jmp	CopyString

::51			ldy	#$00
			tya				;Kein CMD/SD2IEC: Name löschen.
			sta	(r1L),y
			rts

::1			lda	#$ff
			sta	r3H
			LoadW	r4,dirEntryBuf
			jsr	GetPDirEntry		;Aktive Partition suchen.
			txa
			bne	:50			; => Nicht gefunden, Ende...

			jsr	SetVecPartNm		;Zeiger auf Speicherbereich für
							;Partitionsname

			ldy	#$00			;Partitionsname in Zwischenspeicher
::2			lda	dirEntryBuf +3,y	;übertragen.
			beq	:3
			cmp	#$a0
			beq	:3
			sta	(r1L),y
			iny
			cpy	#$10
			bcc	:2

::3			cpy	#$10			;Partitions-Name mit $00-Bytes
			beq	:4			;auf 17-Zeichen auffüllen.
			lda	#$00
			sta	(r1L),y
			iny
			bne	:3
::4			rts

;*** Zeiger auf Speicher für Partitionsname setzen.
:SetVecPartNm		lda	NewDrive
			sec
			sbc	#$08
			asl
			tay
			lda	PartNmVec +0,y
			sta	r1L
			lda	PartNmVec +1,y
			sta	r1H
			rts

;******************************************************************************
;*** Laufwerks-/Partitionsname ausgeben.
;******************************************************************************
:PutDrvInfoA		ldx	#8
			b $2c
:PutDrvInfoB		ldx	#9
			b $2c
:PutDrvInfoC		ldx	#10
			b $2c
:PutDrvInfoD		ldx	#11
			stx	NewDrive		;Laufwerksadresse speichern.
			lda	driveType   -8,x
			bne	:1
			LoadW	r0,TxNoDrv
			jmp	PutString		;Text "Kein Laufwerk!" ausgeben.

::1			lda	RealDrvType -8,x	;Ist Laufwerk installiert ?
			jsr	GetDrvModVec		;Zeiger auf Typen-Tabelle berechnen.
			cmp	#$ff			;Unbekanntes Laufwerk ?
			bne	:2			; => Nein, weiter...
			LoadW	r0,TxDrvUnknown
			jmp	PutString		;Text "Laufwerk unbekannt!"

::2			PushW	r11			;X-Koordinate zwischenspeichern.

			lda	NewDrive		;Zeiger auf Speicher für Laufwerks-
			sec				;name setzen und ausgeben.
			sbc	#$08
			asl
			tax
			stx	:drvVec +1
			lda	DrvNmVec +0,x
			sta	r0L
			lda	DrvNmVec +1,x
			sta	r0H
			jsr	PutString

			ldx	NewDrive
			lda	driveType -8,x
			and	#%00001111		;Laufwerkstyp isolieren.
			cmp	#DrvNative		;CMD/NativeMode?
			bne	:noSize			; => Nein, keine Größe ausgeben.

			lda	#","
			jsr	SmallPutChar
			lda	#" "
			jsr	SmallPutChar

			PushW	r11
			PushB	r1H

			lda	NewDrive
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:noDisk			; => Ja, Keine Diskette...

;--- Ergänzung: 01.03.19/M.Kanet
;Der HD-NM-PP-Treiber verwendet nicht dir3Head, daher den BAM-Sektor
;$01/$02 mit Track-Anzahl nach diskBlkBuf einlesen.
			stx	r4L
			inx
			stx	r1L
			inx
			stx	r1H
			lda	#>diskBlkBuf
			sta	r4H
			jsr	GetBlock
			txa
			bne	:noDisk

;--- Ergänzung: 15.12.18/M.Kanet
;Laufwerksgröße in KByte ausgeben und nicht mehr die Anzahl
;der max. verfügbaren Blocks.
			lda	diskBlkBuf +8
			b $2c
::noDisk		lda	#$00			;Keine Diskette im Laufwerk.
			sta	r0L
			lda	#$40
			sta	r1L
			ldx	#r0L
			ldy	#r1L
			jsr	BBMult

			PopB	r1H
			PopW	r11

			lda	#%11000000
			jsr	PutDecimal
			lda	#"K"
			jsr	SmallPutChar
			lda	#"b"
			jsr	SmallPutChar

::noSize		PopW	r11			;Koordinaten für Partitionsname
			AddVB	8,r1H			;definieren.

::drvVec		ldx	#$ff
			lda	PartNmVec +0,x		;Partitionsname ausgeben.
			sta	r0L			;Bei Nicht-CMD-Laufwerken ist der
			lda	PartNmVec +1,x		;Partitionsname bereits gelöscht!
			sta	r0H
			jmp	PutString

;******************************************************************************
;*** Suche nach Datei mit Laufwerkstreibern.
;******************************************************************************
;*** Kopie der Laufwerkstreiber-Datei suchen.
:FindCopyDkDvFile	ldx	#NO_ERROR
			ldy	MP3_64K_DISK		;Treiber im RAM gespeichert ?
			bne	:2			; => Ja, Ende...

			jsr	FindDiskDrvFile		;Treiberdatei suchen.
			txa				;Datei gefunden ?
			bne	Err_NoDkFile		; => Nein, Abbruch...

			ldy	NewDrive		;Soll Laufwerk mit Treiberdatei
			cpy	DiskFileDrive		;gewechselt werden ?
			bne	:2			; => Nein, Ende...

;--- Weitere Kopie der Treiberdatei suchen, da Laufwerk mit aktueller
;    Kopie gewechselt werden soll.
::1			ldy	DiskFileDrive		;Laufwerk mit aktueller Kopie der
			lda	driveType -8,y		;Treiberdatei deaktivieren.
			pha
			tya				;Laufwerksadresse speichern da
			pha				;":DiskFileDrive" geändert wird.
			lda	#$00
			sta	driveType -8,y
			jsr	FindDkDvAllDrv		;Treiberdatei suchen.
			pla
			tay
			pla				;Laufwerksregister wieder
			sta	driveType -8,y		;zurücksetzen.
			txa				;Weitere Kopie gefunden ?
			bne	Err_NoSysDkFile		; => Nein, Fehler...
::2			rts

;*** Keine Datei mit Laufwerkstreibern gefunden.
:Err_NoSysDkFile	lda	#< Dlg_ErrLdSysFile
			ldx	#> Dlg_ErrLdSysFile
			bne	Err_DkFile

;*** Keine Datei mit Laufwerkstreibern gefunden.
:Err_NoDkFile		lda	#< Dlg_NoDskFile
			ldx	#> Dlg_NoDskFile
:Err_DkFile		jsr	SystemDlgBox
			ldx	#DEV_NOT_FOUND
			rts

;******************************************************************************
;*** Register-Routinen.
;******************************************************************************

;******************************************************************************
;*** Einstellen der Register-Optionen.
;*** Änderung erfolgt direkt über Register-Funktionen. Hier wird nur
;*** der Wert in die Boot-Konfiguration übertragen.
;******************************************************************************

;*** Laufwerkstreiber in RAM kopieren.
:Swap_DskInRAM		lda	BootLoadDkDv
			bne	:1
			ldx	MP3_64K_DISK
			sta	MP3_64K_DISK
			sta	BankUsed+0 ,x		;Bank-Modus einlesen.
			sta	BankUsed+1 ,x		;Bank-Modus einlesen.
			jsr	SetBank_TaskSpl		;TaskMan/Spooler-RAM belegen.
			jsr	InitDkDrv_Disk
			jmp	BankUsed_2GEOS		;GEOS-Bank-Tabelle aktualisieren.

::1			ldx	MP3_64K_DATA
			dex
			lda	BankUsed ,x		;Bank-Modus einlesen.
			cmp	#BankCode_GEOS		;Ist Speicherbank bereits durch
			beq	:3			;Anwendung oder Laufwerkstreiber
			cmp	#BankCode_Disk		;belegt ?
			beq	:3
			cmp	#BankCode_Block
			beq	:3			; => Ja, Fehler ausgeben.
			dex
			lda	BankUsed ,x		;Bank-Modus einlesen.
			cmp	#BankCode_GEOS		;Ist Speicherbank bereits durch
			beq	:3			;Anwendung oder Laufwerkstreiber
			cmp	#BankCode_Disk		;belegt ?
			beq	:3
			cmp	#BankCode_Block
			beq	:3			; => Ja, Fehler ausgeben.

			stx	MP3_64K_DISK		;Speicherbank setzen.

			jsr	InitDkDrv_RAM		;Laufwerkstreiber einlesen.
			txa				;Installationsfehler ?
			bne	:2			; => Ja, Abbruch...

			ldx	MP3_64K_DISK		;Speicherbank als "belegt"
			lda	#BankCode_GEOS		;markieren.
			sta	BankUsed+0 ,x
			lda	#BankCode_GEOS		;markieren.
			sta	BankUsed+1,x
			jsr	SetBank_TaskSpl		;TaskManager/Spooler initialisieren.
			jmp	BankUsed_2GEOS		;GEOS-Bank-Tabelle aktualisieren.

;--- Fehler beim Wechseln der RAM-Option anzeigen.
::2			lda	#< Dlg_NoDskFile
			ldx	#> Dlg_NoDskFile
			bne	:4

::3			lda	#< Dlg_DkRamInUse
			ldx	#> Dlg_DkRamInUse
::4			jsr	SystemDlgBox

			lda	#$00			;Option "Treiber in RAM" löschen.
			sta	BootLoadDkDv
			sta	MP3_64K_DISK
			jmp	InitDkDrv_Disk

;*** Taktfrequenz für SCPU umschalten.
:Swap_Speed		bit	SCPU_Aktiv		;SuperCPU aktiviert ?
			bpl	NOFUNC01		; => Nein, Ende...

			php				;I/O-Register einblenden.
			sei

if Flag64_128 = TRUE_C64
			ldx	CPU_DATA
			lda	#$35
			sta	CPU_DATA
endif

			lda	$d0b8			;Taktfrequenz umschalten.
			and	#%01000000
			bne	:1
			sta	$d07a			;Auf 1Mhz schalten.
			beq	:2
::1			sta	$d07b			;Auf 20Mhz schalten.
::2

if Flag64_128 = TRUE_C64
			stx	CPU_DATA
endif

			plp
			jsr	GetSpeedSCPU		;Taktfrequenz aktualisieren.
:NOFUNC01		rts

;*** Optimierung für SCPU umschalten.
:Swap_Optimize		bit	SCPU_Aktiv		;SuperCPU aktiviert ?
			bpl	NOFUNC01		; => Nein, Ende...
			lda	Flag_Optimize
			sta	BootOptimize
			jmp	SCPU_SetOpt		;Neue Optimierung aktivieren.

;******************************************************************************
;*** Register-Routinen.
;******************************************************************************
;--- Ergänzung: 20.07.18/M.Kanet
;Das Registermenü wechselt nur den Status von sysRAMFlg.
;Damit die Einstellung beim nächsten Start wieder hergestellt wird,
;muss der Status in BootRAM_Flag übertragen werden.
;*** Option für MOVE_DATA sichern.
:Swap_MOVEDATA		lda	sysRAMFlg
			and	#%10000000
			bne	:1
			lda	BootRAM_Flag
			and	#%01111111
			sta	BootRAM_Flag
			rts
::1			lda	BootRAM_Flag
			ora	#%10000000
			sta	BootRAM_Flag
			rts

;*** Laufwerkstyp erkennen für RTC-Echtzeituhr.
:FindTypeRTCdrv		ldx	#$00
::1			lda	RTC_Type,x		;Modus aus Tabelle mit
			cmp	BootRTCdrive		;Konfiguration vergleichen.
			beq	:2			; => Gefunden, Ende...
			inx
			cmp	#$ff			;Letzten Modus geprüft ?
			bne	:1			; => Nein, weitersuchen.
			ldx	#$00			;RTC-Gerät unbekannt, keine Uhr.
::2			rts

;*** *** Laufwerk mit CMD-Uhr anzeigen.
:PutSetClkInfo		jsr	FindTypeRTCdrv		;Zeiger auf RTC-Uhr-Text
			txa				;berechnen und RTC-Gerät anzeigen.
			asl
			tax
			lda	VecText_CMD_Clk +0,x
			sta	r0L
			lda	VecText_CMD_Clk +1,x
			sta	r0H
			LoadW	r11,$00b4 ! DOUBLE_W
			LoadB	r1H,$7e
			jmp	PutString

;*** Neues CMD-Laufwerk mit GEOS-Uhrzeit wählen.
:SetNewClkDev		jsr	FindTypeRTCdrv		;Zeiger auf nächstes RTC-Gerät.
			lda	RTC_Type,x
			cmp	#$ff
			bne	:1
			ldx	#$ff
::1			inx
			lda	RTC_Type,x
			sta	BootRTCdrive		;Keine Uhr setzen ?
			beq	:2			; => Ja, Ende...
			cmp	#$ff			;AutoDetect ?
			beq	:2			; => Ja, Ende...
			jsr	FindRTCdrive		;RTC-Gerät suchen.
			txa				;RTC-Fehler ?
			bne	SetNewClkDev		; => Ja, nächstes RTC-Gerät.
::2			LoadW	r15,RegTMenu_2d		;Registerkarte aktualisieren.
			jmp	RegisterUpdate

;******************************************************************************
;*** Register-Routinen.
;******************************************************************************
;*** GEOS-Code ändern.
:SetNewGEOS_ID		jsr	GetNewCodeGEOS		;ASCII nach GEOS-ID wandeln.
			sty	SerialNumber +0		;Neue GEOS-ID installieren.
			sta	SerialNumber +1

;*** GEOS-ID nach ASCII-Text umwandeln.
:GetSerCodeGEOS		jsr	GetSerialNumber

			lda	r0L
			pha
			lda	r0H
			jsr	HEX2ASCII
			stx	GEOS_ID_ASCII +0
			sta	GEOS_ID_ASCII +1
			pla
			jsr	HEX2ASCII
			stx	GEOS_ID_ASCII +2
			sta	GEOS_ID_ASCII +3
			rts

;*** ASCII-Text in GEOS-ID umwandeln.
:GetNewCodeGEOS		lda	GEOS_ID_ASCII +2
			ldx	GEOS_ID_ASCII +3
			jsr	:1
			tay
			lda	GEOS_ID_ASCII +0
			ldx	GEOS_ID_ASCII +1
::1			jsr	:2
			asl
			asl
			asl
			asl
			sta	r0L
			txa
			jsr	:2
			ora	r0L
			rts

::2			and	#%01111111
			cmp	#$60
			bcc	:3
			sbc	#$20
::3			sec
			sbc	#$30
			cmp	#10
			bcc	:4
			sbc	#$07
::4			rts

;*** HEX-Zahl nach ASCII wandeln.
:HEX2ASCII		pha
			lsr
			lsr
			lsr
			lsr
			jsr	:1
			tax
			pla
::1			and	#%00001111
			clc
			adc	#$30
			cmp	#$3a
			bcc	:2
			clc
			adc	#$07
::2			rts

;******************************************************************************
;*** GEOS-ID kopieren.
;******************************************************************************
;*** Serien-ID anpassen.
:SaveGEOS_IDtoDsk	lda	SysDrive
			jsr	SetDevice
			txa
			bne	:err
			jsr	OpenDisk
			txa
			bne	:err
			LoadW	r6,FNameG1
			jsr	FindFile		;Systemdatei mit GEOS-ID suchen.
			txa				;Datei gefunden? ?
			beq	:50			; => Ja, weiter...

::err			ldx	#>Dlg_SvIDErrSys
			lda	#<Dlg_SvIDErrSys
			jmp	SystemDlgBox

::50			lda	#< SerialNumber
			sec
			sbc	#< DISK_BASE -2		;2 Bytes für Dummy-WORD am Beginn
			sta	r10L			;der Startdatei abziehen.
			lda	#> SerialNumber		;(BASIC-Loader!)
			sbc	#> DISK_BASE -2
			sta	r10H

			LoadW	r4,diskBlkBuf
			lda	dirEntryBuf +1		;Sektor mit GEOS-ID innerhalb
			ldx	dirEntryBuf +2		;der Startdatei suchen.
::51			sta	r1L
			stx	r1H
			jsr	GetBlock
			txa
			bne	:52

			CmpWI	r10,254			;Sektor gefunden ?
			bcc	:53			; => Ja, weiter...

			SubVW	254,r10

			ldx	diskBlkBuf +1
			lda	diskBlkBuf +0
			bne	:51
::52			ldx	#>Dlg_SvIDErrDsk
			lda	#<Dlg_SvIDErrDsk
			jmp	SystemDlgBox

::53			jsr	GetSerialNumber		;Aktuelle GEOS-ID einlesen.

			ldx	r10L			;LowByte der GEOS-ID speichern.
			inx
			inx
			lda	r0L
			sta	diskBlkBuf,x
			inx				;HighByte noch innerhalb Sektor ?
			bne	:54			; => Ja, weiter...

			jsr	PutBlock		;Aktuellen Sektor speichern.
			txa
			bne	:52

			lda	diskBlkBuf +0		;Nächsten Sektor einlesen.
			ldx	diskBlkBuf +1
			sta	r1L
			stx	r1H
			jsr	GetBlock
			txa
			bne	:52

			ldx	#$02			;Zeiger auf erstes Byte.
::54			lda	r0H			;HighByte der GEOS-ID speichern.
			sta	diskBlkBuf,x
			jsr	PutBlock
			txa
			bne	:52

			ldx	#>Dlg_SvID_OK
			lda	#<Dlg_SvID_OK
			jmp	SystemDlgBox

;******************************************************************************
;*** Register-Routinen.
;******************************************************************************
;*** Speicherübersicht ausgeben.
;    Max. 64 Bänke a 64KByte = 4 MByte REU-Speicher!
:Draw_MemInfo		LoadW	r0,R3T02
			jsr	PutString

			ldx	#<TxRAM_RL		;"RAMLink DACC"
			ldy	#>TxRAM_RL
			lda	GEOS_RAM_TYP
			asl
			bcs	:1
			ldx	#<TxRAM_CBM		;"C=REU"
			ldy	#>TxRAM_CBM
			asl
			bcs	:1
			ldx	#<TxRAM_BBG		;"GeoRAM/BBGRAM"
			ldy	#>TxRAM_BBG
			asl
			bcs	:1
			ldx	#<TxRAM_SCPU		;"SuperCPU/RAMCard"
			ldy	#>TxRAM_SCPU
::1			stx	r0L
			sty	r0H
			jsr	PutString		;Speichererweiterung anzeigen.

;*** Speicherbelegungs-Tabelle ausgeben.
:Draw_64KBankTab	ldx	#$00			;Zeiger auf Bank #0.
::1			txa
			pha
			jsr	Draw_64KBank		;Bank-Status ausgeben.
			pla
			tax
			inx				;Zeiger auf nächste Speicherbank.
			cpx	#$40			;Alle Bänke ausgegeben ?
			bcc	:1			; => Nein, weiter...
			rts

;*** Koordinaten für 64K-Bank berechnen.
:GetBankArea		pha				;Y-Koordinate für Status-Feld
			and	#%11111000		;berechnen.
			clc
			adc	#$58
			sta	r2L
			clc
			adc	#$07
			sta	r2H

			pla				;X-Koordinate für Status-Feld
			and	#%00000111		;berechnen.
			asl
			asl
			asl
			clc
			adc	#< $0058
			sta	r3L
			lda	#$00
			adc	#> $0058

if Flag64_128 = TRUE_C128
			ora	#%10000000		;Double-Bit einblenden.
endif

			sta	r3H

			lda	r3L
			clc
			adc	#< $0007
			sta	r4L
			lda	r3H
			adc	#> $0007

if Flag64_128 = TRUE_C128
			ora	#%10100000		;Double-/Add1_W-Bit einblenden.
endif
			sta	r4H
			rts

;******************************************************************************
;*** Register-Routinen.
;******************************************************************************
;*** Status für aktuelle Speicherbank anzeigen.
:Draw_64KBank		pha
			jsr	GetBankArea		;Koordinaten für Bank berechnen.
			pla
			tax
			cpx	ramExpSize		;RAM-Bank installiert ?
			bcs	Draw_Info_NoRAM		; => Nein, weiter...

			lda	BankUsed ,x		;Ist Bank frei ?
			beq	Draw_Info_Free		; => Ja, weiter...
			cmp	#BankCode_GEOS		;Ist Bank durch GEOS belegt ?
			beq	Draw_Info_GEOS		; => Ja, weiter...
			cmp	#BankCode_Disk		;Ist Bank durch TaskMan belegt ?
			beq	Draw_Info_Disk		; => Ja, weiter...
			cmp	#BankCode_Task		;Ist Bank durch TaskMan belegt ?
			beq	Draw_Info_Task		; => Ja, weiter...
			cmp	#BankCode_Spool		;Ist Bank durch TaskMan belegt ?
			beq	Draw_Info_Spool		; => Ja, weiter...
							;Bank ist reserviert!

;*** Legende für Speichertabelle anzeigen.
:Draw_Info_Block	lda	#$05
			b $2c
:Draw_Info_Spool	lda	#$03
			b $2c
:Draw_Info_Task		lda	#$06
			b $2c
:Draw_Info_Disk		lda	#$0d
			b $2c
:Draw_Info_GEOS		lda	#$02
			b $2c
:Draw_Info_NoRAM	lda	#$00
			b $2c
:Draw_Info_Free		lda	#$01
			jsr	DirectColor
			lda	#$00
			jsr	SetPattern		;Füllmuster definieren.
			jsr	Rectangle
			lda	#%11111111
			jmp	FrameRectangle		;Bank-Status anzeigen.

;*** Anzeige für TaskTaskMan/Spooler aktualisieren.
:Update_MemInfo		jsr	SetBank_TaskSpl		;TaskMan/Spooler-RAM belegen.

			LoadW	r15,RegTMenu_3a		;Register-Karten aktualisieren.
			jsr	RegisterUpdate
			LoadW	r15,RegTMenu_3b
			jsr	RegisterUpdate

			jsr	Draw_64KBankTab		;Bank-Tabelle ausgeben.
			jmp	BankUsed_2GEOS		;GEOS-Bank-Tabelle aktualisieren.

;*** Bänke für TaskMan/Spooler in Tabelle belegen.
:SetBank_TaskSpl	jsr	ClrBank_TaskMan		;TaskMan-RAM freigeben.
			jsr	ClrBank_Spooler		;Spooler -RAM freigeben.

			lda	TASK_COUNT
			beq	:1

			jsr	AutoInitTaskMan		;TaskMan-RAM belegen.

::1			lda	#$00			;Größe Spooler-RAM löschen.
			sta	SpoolRamSize +0
			sta	SpoolRamSize +1

			bit	BootSpooler		;Spooler aktiviert ?
			bpl	:2			; => Nein, weiter...

			jsr	AutoInitSpooler		;Spooler -RAM belegen.

			lda	BootSpoolSize		;Größe des Speichers für Spooler
			sta	r1L			;speichern und in Dezimal-Zahl
			lda	#$00			;umrechnen.
			sta	r1H
			ldx	#r1L
			ldy	#$06
			jsr	DShiftLeft

			lda	r1L
			sta	SpoolRamSize +0
			lda	r1H
			sta	SpoolRamSize +1
			ora	r1L			;RAM für Spooler installiert ?
			bne	:2			; => Ja, weiter...
			sta	BootSpooler		;Spooler deaktivieren.

::2			rts

;******************************************************************************
;*** Register-Routinen.
;******************************************************************************
;*** GEOS-Bank reservieren/freigeben.
:Swap_BankMode		ldx	Reserved		;Bank-Nr. einlesen und Eingabe-
			lda	#$00			;speicher wieder löschen.
			sta	Reserved
			cpx	ramExpSize		;Bank installiert ?
			bcc	:2			; => Ja, weiter...
::1			rts

::2			lda	BankUsed ,x		;Bank-Modus einlesen.
			beq	:5			; => Bank für TaskMan/Spooler.
			cmp	#BankCode_GEOS
			beq	:1
			cmp	#BankCode_Disk
			beq	:1
			cmp	#BankCode_Task		;Bank durch TaskMan belegt ?
			bne	:3			; => Nein, Ende...
			dec	TASK_COUNT		;Anzahl Task korrigieren und
			jmp	:5

::3			cmp	#BankCode_Spool		;Bank durch Spooler belegt ?
			bne	:4			; => Nein, weiter...
			dec	BootSpoolSize		;Spooler-RAM korrigieren und
			jmp	:5			;Speicherbank für GEOS reservieren.

::4			cmp	#BankCode_Block
			bne	:1
			lda	#$00
			b $2c
::5			lda	#BankCode_Block		;Speicherbank für GEOS
			sta	BankUsed ,x		;reservieren.
			jmp	Update_MemInfo		;Register "Speicher" aktualisieren.

;******************************************************************************
;*** Register-Routinen.
;******************************************************************************
;*** Neue Task-Anzahl berechnen.
:Swap_MaxTask		lda	mouseYPos
			sec
			sbc	#$70
			cmp	#$04
			bcs	:2			; => Weiter...

			ldx	TASK_COUNT
			cpx	#MAX_TASK_ACTIV
			beq	:1
			inx
			stx	TASK_COUNT		;Neue Anzahl Tasks speichern.
::1			jmp	:3			;Register "Speicher" aktualisieren.

::2			ldx	TASK_COUNT
			beq	:3
			dex
			stx	TASK_COUNT		;Neue Anzahl Tasks speichern.
::3			ldy	#$ff
			txa
			beq	:4
			iny
::4			sty	BootTaskMan
			jmp	Update_MemInfo		;Register "Speicher" aktualisieren.

;*** Neue Größe SpoolerRAM berechnen.
:Swap_SpoolRAM		lda	mouseYPos
			sec
			sbc	#$90			;Spooler +64k/-64k.
			cmp	#$04			;Spoolergröße verringern ?
			bcs	:3			; => Ja, Weiter...

			bit	BootSpooler		;Spooler aktiv ?
			bmi	:1			; => Ja, weiter...

			lda	#$00			;Größe des SpoolerRAM zurücksetzen.
			sta	BootSpoolSize

			lda	#%10000000		;Spooler aktivieren.
			sta	BootSpooler

;--- Spooler +64k.
::1			ldx	BootSpoolSize
			cpx	#MAX_SPOOL_SIZE
			bcs	:2
			inx
			cpx	ramExpSize
			beq	:2
			stx	BootSpoolSize		;Neue Größe für Spooler speichern.
::2			jmp	Update_MemInfo		;Register "Speicher" aktualisieren.

;--- Spooler -64k.
::3			ldx	BootSpoolSize
			beq	:4
			dex
			stx	BootSpoolSize		;Neue Größe für Spooler speichern.
::4			txa				;RAM für Spooler installiert ?
			bne	:5			; => Ja, weiter...
			sta	BootSpooler		;Spooler deaktivieren.
::5			jmp	Update_MemInfo		;Register "Speicher" aktualisieren.

;*** Durch GEOS/MP3/Laufwerkstreiber belegen.
:SetGEOS_RAM		ldy	#$00			;Speichertabelle und Informationen
			tya				;über reservierte Speicherbänke
::1			ldx	BankUsed,y		;löschen.
			cpx	#BankCode_Block
			bne	:2
			sta	BankUsed,y
::2			iny
			cpy	ramExpSize
			bne	:1
			rts

;*** Maus-Position für Schieberegler definieren.
:DefMouseXPos
if Flag64_128 = TRUE_C128
			ldx	mouseXPos
			ldy	mouseXPos+1
			bit	graphMode		;welcher Grafik-Modus?
			bpl	:40			;>40 Zeichen
			lsr	mouseXPos+1
			ror	mouseXPos
::40			lda	mouseXPos
			sec
			sbc	#< $0020
			lsr
			lsr
			stx	mouseXPos
			sty	mouseXPos+1
			rts
endif

if Flag64_128 = TRUE_C64
			lda	mouseXPos
			sec
			sbc	#< $0020
			lsr
			lsr
			rts
endif

;******************************************************************************
;*** Register-Routinen.
;******************************************************************************
;*** Bezeichnung des ScreenSavers einlesen.
:GetScrSvName		jsr	SwapScrSaver		;Bildschirmschoner einlesen.

			LoadW	r0,LD_ADDR_SCRSAVER +6
			LoadW	r1,BootSaverName
			ldx	#r0L
			ldy	#r1L			;Name des ScreenSavers in
			jsr	CopyString		;Konfigurationstabelle übernehmen.
			jmp	SwapScrSaver

;*** Modus für Bildschirmschoner wechseln.
;--- Ergänzung: 01.07.18/M.Kanet
;In der Version von 1999-2003 wurde hier der Status des Bildschirmschoners
;in der Boot-Konfiguration gespeichert.
;An dieser Stelle sollte nur das "On/Off"-Bit gespeichert werden.
:Swap_ScrSaver		lda	Flag_ScrSaver
			and	#%10000000
			sta	BootScrSaver
			rts

;*** Neuen Bildschirmschoner laden.
:GetNewScrSaver		LoadB	r7L,SYSTEM
			LoadW	r10,Class_ScrSaver
			jsr	OpenFile		;Datei auswählen.
			txa				;Diskettenfehler ?
			bne	NoScrSaver		; => Ja, Ende...

			LoadW	r0,dataFileName		;Name des ScreenSavers in
			LoadW	r1,BootSaverName	;Konfigurationstabelle übernehmen.
			ldx	#r0L
			ldy	#r1L
			jsr	CopyString

;*** Bildschirmschoner laden.
:GetScrSvFile		LoadW	r6,BootSaverName
			jsr	InitScrSaver		;Neuen ScreenSaver installieren.
;--- Ergänzung: 20.07.18/M.Kanet
;Fehler korrigiert, wenn Xreg <> #NO_ERROR, dann konnte
;der Bildschirmschoner nicht initialisiert werden.
			txa				;Diskettenfehler ?
			bne	NoScrSaver		; => Nein, weiter...
			jmp	GetScrSvName		;Name Bildschirmschoner einlesen.

:NoScrSaver		lda	#%10000000		;Bildschirmschoner abschalten und
			sta	Flag_ScrSaver		;Konfiguration speichern.
			sta	BootScrSaver
			lda	#NULL
			sta	BootSaverName
			LoadW	r15,RegTMenu_4a		;Registerkarte aktualisieren.
			jmp	RegisterUpdate

;*** Bildschirmschoner testen.
;    Dazu wird der Zähler in Flag_ScrSaver gelöscht was beim nächsten
;    Interrupt den Bildschirmschoner startet.
;--- Ergänzung: 01.07.18/M.Kanet
;Hinweis: Das testen funktioniert nicht wenn der
;Bildschirmschoner deaktiviert ist.
:StartScrnSaver		lda	r1L			;Register-Grafikaufbau ?
			beq	:3			; => Ja, Ende...

::1			bit	mouseData		;Maustaste gedrückt ?
			bpl	:1			; => Ja, warten bis keine Maustaste.

			bit	Flag_ScrSaver		;Bildschirmschoner deaktiviert?
			bmi	:3			;Ja, Abbruch...

			php				;IRQ sperren umd den ScreenSaver
			sei				;einzulesen und zu initialisieren.
			jsr	SwapScrSaver
			jsr	LD_ADDR_SCRSVINIT
			txa
			pha
			jsr	SwapScrSaver
			pla
			tax				;Fehler-Register zurücksetzen.
			plp

			cpx	#NO_ERROR		;Initialisierung erfolgreich?
			beq	:2			;Ja, weiter...
			LoadW	r0,Dlg_ScrSvErr		;Fehlermeldung ausgeben.
			jsr	DoDlgBox
			jmp	NoScrSaver		;Bildschirmschoner abschalten.

::2			lda	#%00000000
			sta	Flag_ScrSaver
::3			rts

;******************************************************************************
;*** Register-Routinen.
;******************************************************************************
;*** Neuen Wert für ScreenSaver eingeben.
:Swap_ScrSvDelay	lda	r1L			;Register-Grafikaufbau ?
			beq	Draw_ScrSvDelay		; => Ja, weiter...

			jsr	DefMouseXPos		;Neuen Wert für Aktivierungszeit
			cmp	#1
			bcs	:ok
			lda	#1
::ok			sta	Flag_ScrSvCnt		;berechnen.
			sta	BootScrSvCnt

;--- Ergänzung: 01.07.18/M.Kanet
;In der Version von 1999-2003 wurde hier der Bildschirmschoner grundsätzlich
;neu gestartet auch wenn dieser deaktiviert war.
;An dieser Stelle sollte nur das "Neustart"-Bit gesetzt werden.
			lda	Flag_ScrSaver		;ScreenSaver initialisieren.
			ora	#%01000000		;Dabei nur das "Initialize"-Bit
			sta	Flag_ScrSaver		;setzen, das "On/Off"-Bit 7 nicht
							;löschen da sonst der ScreenSaver
							;automatisch eingeschaltet wird.

;*** Verzögerungszeit für ScreenSaver festlegen.
:Draw_ScrSvDelay	lda	C_InputField		;Farbe für Schieberegler setzen.
			jsr	DirectColor

			jsr	i_BitmapUp		;Schieberegler ausgeben.
			w	Icon_06
			b	$04 ! DOUBLE_B,$68,Icon_06x ! DOUBLE_B,Icon_06y

			ldx	#$04			;Position für Schieberegler
			lda	Flag_ScrSvCnt		;berechnen.
			lsr
			bcs	:1
			dex
::1			sta	:2 +1
			txa
			clc
::2			adc	#$ff

if Flag64_128 = TRUE_C128
			ora	#%10000000		;Double-Bit einblenden
endif

			sta	:6 +0

			ldx	#$01			;Breite des Regler-Icons
			lda	Flag_ScrSvCnt		;berechnen.
			lsr				;Bei 0.5, 1.5, 2.5 usw... 1 CARD.
			bcs	:3			;Bei 1.0, 2.0, 3.0 usw... 2 CARDs.
			inx

if Flag64_128 = TRUE_C128
::3			txa
			ora	#%10000000		;Double-Bit einblenden
			sta	:6 +2
endif

if Flag64_128 = TRUE_C64
::3			stx	:6 +2
endif

			ldx	#<Icon_08		;Typ für Regler-Icon ermitteln.
			ldy	#>Icon_08
			lda	Flag_ScrSvCnt
			lsr
			bcs	:4			; => Typ #1, 0.5, 1.5, 2.5 usw...
			ldx	#<Icon_07		; => Typ #1, 1.0, 2.0, 3.0 usw...
			ldy	#>Icon_07
::4			stx	:5 +0
			sty	:5 +1

			jsr	i_BitmapUp		;Schieberegler anzeigen.
::5			w	Icon_05
::6			b	$0c,$6b,$ff,$05

;******************************************************************************
;*** Register-Routinen.
;******************************************************************************
;*** Aktivierungszeit anzeigen.
:Draw_ScrSvTime		LoadW	r0, R4T04 + 6

			lda	Flag_ScrSvCnt		;Aktivierungszeit in Minuten und
			asl				;Sekunden umrechnen.
			asl
			clc
			adc	Flag_ScrSvCnt
			ldx	#$00
::1			cmp	#60
			bcc	:2
			sec
			sbc	#60
			inx
			bne	:1
::2			jsr	SetDelayTime

			LoadB	currentMode,$00
			LoadW	r0,R4T04
			jsr	PutString		;Aktivierungszeit anzeigen.
			jmp	RegisterSetFont		;Zeichensatz zurücksetzen.

;*** Zahl nach ASCII wandeln.
:SetDelayTime		pha
			txa
			ldy	#$01
			jsr	:50
			pla
::50			ldx	#$30
::1			cmp	#10
			bcc	:2
			inx
			sbc	#10
			bcs	:1
::2			adc	#$30
			sta	(r0L),y
			dey
			txa
			sta	(r0L),y
			iny
			iny
			iny
			iny
			rts

;******************************************************************************
;*** Register-Routinen.
;******************************************************************************
;*** Modus für Hintergrund wechseln.
:Swap_BackScrn		lda	BootGrfxFile		;Hintergrundbild definiert?
			beq	GetNoBackScrn		;Nein, abschalten...
			lda	sysRAMFlg
			and	#%00001000		;Hintergrundbild aktiv ?
			beq	GetNoBackScrn

::1			jsr	SetSystemDevice		;Startlaufwerk aktivieren.
			jmp	GetBackScrFile		; => Ja, Hintergrundbild laden.

;*** Neues Hintergrundbild laden.
:GetNewBackScrn		LoadB	r7L,APPL_DATA
			LoadW	r10,Class_GeoPaint
			jsr	OpenFile		;Datei auswählen.
			txa				;Diskettenfehler ?
			bne	NoBackScrn		; => Ja, weiter...

			LoadW	r0,dataFileName		;Name des ScreenSavers in
			LoadW	r1,BootGrfxFile		;Konfigurationstabelle übernehmen.
			ldx	#r0L
			ldy	#r1L
			jsr	CopyString

;*** Bildschirmgrafik einlesen.
:GetBackScrFile		lda	sysRAMFlg
			ora	#%00001000
			sta	sysRAMFlg
			sta	sysFlgCopy
			lda	BootRAM_Flag
			ora	#%00001000
			sta	BootRAM_Flag

;*** Grafik von Diskette einlesen und speichern.
:GetScrnFromDisk	jsr	LdScrnFrmDisk		;Hintergrundbild einlesen.
			jsr	DrawMenuWindow		;Menü aufbauen.
			jmp	RegisterInitMenu

;--- Ergänzung: 13.01.2019/M.Kanet
;Wenn die Auswahl des Hintergrundbildes abgebrochen
;wurde, dann Hintergrundbild deaktivieren.
;*** Registerkarte aktualisieren.
:NoBackScrn		lda	#$00
			sta	BootGrfxFile

;*** Kein Hintergrundbild verwenden.
:GetNoBackScrn		lda	sysRAMFlg
			and	#%11110111
			sta	sysRAMFlg
			sta	sysFlgCopy
			lda	BootRAM_Flag
			and	#%11110111
			sta	BootRAM_Flag

;--- Ergänzung: 29.07.18/M.Kanet
;Wird kein Hintergrundbild verwendet müssen beim C128 auch die Farben
;des 80Z-Bildschirms gelöscht werden wenn man den GEOS-Editor im
;40Z-Modus startet.
if Flag64_128 = TRUE_C128
			lda	graphMode		;40Z. aktiv ?
			bmi	:1			; => Nein, weiter...
			pha				;Bildschirmmodus speichern.
			lda	#$80			;Auf 80Z. umschalten.
			sta	graphMode
			jsr	SetNewMode
			lda	#$02			;VDC initialisieren.
			jsr	VDC_ModeInit
			jsr	StdClrScrn		;Bildschirm löschen.
			pla
			sta	graphMode		;Bildschirmmodus zurücksezen.
			jsr	SetNewMode
endif
::1			jsr	StdClrScrn		;Hintergrundmuster einlesen.
			jsr	DrawMenuWindow		;Menü aufbauen.
			jmp	RegisterInitMenu

;*** Aktuelles Hintergrundbild anzeigen.
:PrintCurBackScrn	lda	r1L
			beq	:1

			lda	sysRAMFlg
			and	#%00001000		;Hintergrundbild aktiv ?
			beq	:1			; => Nein, weiter...

			LoadW	r0,Dlg_GetBScrn
			jsr	DoDlgBox

::1			rts

;******************************************************************************
;*** Register-Routinen.
;******************************************************************************
;*** Modus für Menü-Anzeige wechseln.
:Swap_MenuMode		lda	Flag_MenuStatus
			sta	BootMenuStatus
			rts

;*** Modus für Menü-Trennlinien wechseln.
:Swap_MLineMode		lda	Flag_SetMLine
			sta	BootMLineMode
			rts

;*** Modus für Farbdarstellung wechseln.
:Swap_ColsMode		lda	Flag_SetColor
			sta	BootColsMode
			rts

;*** Neuen Wert für CURSOR-Speed eingeben.
:Swap_CRSR_Speed	lda	r1L			;Register-Grafikaufbau ?
			beq	Draw_CRSR_Speed		; => Ja, weiter...

			lda	mouseXPos		;Neuen Wert für Verzögerungszeit
							;berechnen.
if Flag64_128 = TRUE_C128
			bit	graphMode		;welcher Grafik-Modus?
			bpl	:40			;>40 Zeichen
			sta	r15L
			lda	mouseXPos+1
			lsr
			ror	r15L
			lda	r15L
::40
endif
			sec
			sbc	#< $00c0
			cmp	#4			;nicht kleiner als 4
			bcs	:ok			;>ja
			lda	#4			;auf 4 setzen
::ok			lsr				;geteilt durch 4
			lsr
			sta	Flag_CrsrRepeat
			sta	BootCRSR_Repeat

;*** Verzögerungszeit für Cursor anzeigen.
:Draw_CRSR_Speed	lda	C_InputField		;Farbe für Schiebeegler setzen.
			jsr	DirectColor

			jsr	i_BitmapUp		;Schieberegler ausgeben.
			w	Icon_05
			b	$18 ! DOUBLE_B,$50,Icon_05x ! DOUBLE_B,Icon_05y

			ldx	#$18			;Position für Schieberegler
			lda	Flag_CrsrRepeat		;berechnen.
			lsr
			bcs	:1
			dex
::1			sta	:2 +1
			txa
			clc
::2			adc	#$ff

if Flag64_128 = TRUE_C128
			ora	#%10000000		;Double-Bit einblenden
endif
			sta	:6 +0

			ldx	#$01			;Breite des Regler-Icons
			lda	Flag_CrsrRepeat		;berechnen.
			lsr				;Bei 0.5, 1.5, 2.5 usw... 1 CARD.
			bcs	:3			;Bei 1.0, 2.0, 3.0 usw... 2 CARDs.
			inx

if Flag64_128 = TRUE_C128
::3			txa
			ora	#%10000000		;Double-Bit einblenden
			sta	:6 +2
endif

if Flag64_128 = TRUE_C64
::3			stx	:6 +2
endif

			ldx	#<Icon_08		;Typ für Regler-Icon ermitteln.
			ldy	#>Icon_08
			lda	Flag_CrsrRepeat
			lsr
			bcs	:4			; => Typ #1, 0.5, 1.5, 2.5 usw...
			ldx	#<Icon_07		; => Typ #1, 1.0, 2.0, 3.0 usw...
			ldy	#>Icon_07
::4			stx	:5 +0
			sty	:5 +1

			jsr	i_BitmapUp		;Schieberegler anzeigen.
::5			w	Icon_05
::6			b	$18,$53,$ff,$05
			rts

;******************************************************************************
;*** Register-Routinen.
;******************************************************************************
;*** Neuen Druckertreiber laden.
:GetNewPrinter		LoadB	r7L,PRINTER
			LoadW	r10,$0000
			jsr	OpenFile		;Datei auswählen.
			txa				;Diskettenfehler ?
			bne	NOFUNC02		; => Ja, Abbruch...

			LoadW	r0,dataFileName		;Name des ScreenSavers in
			jmp	LoadPrntDevice

;*** Modus für Drukertreiber wechseln.
:SwapPrntRAM		lda	Flag_LoadPrnt
			sta	BootPrntMode
;--- Ergänzung: 31.12.18/M.Kanet
;geoCalc64 nutzt beim Drucken ab $$5569 eine Routine ab $7F3F. Diese Adresse
;ist aber noch für Druckertreiber reserviert.
;Wird der Treiber von Disk geladen kann der Fix nicht
;auf den aktuellen Druckertreiber angewendet werden.
if Flag64_128 = TRUE_C64
			beq	NOFUNC02
			lda	#$00			;Treiber von Disk => GCalcFix=Aus.
			sta	BootGCalcFix
			LoadW	r15,RegTMenu_6a
			jsr	RegisterUpdate
endif
:NOFUNC02		rts

;*** Name der aktuellen Eingbae-/Druckertreiber kopieren.
:GetCurDevice		ldy	#$10
::1			lda	PrntFileName,y
			sta	BootPrntName,y
			lda	inputDevName,y
			sta	BootInptName,y
			dey
			bpl	:1
			rts

;*** Neues Eingabegerät laden.
:GetNewInput
if Flag64_128 = TRUE_C128
			LoadB	r7L,INPUT_128
endif

if Flag64_128 = TRUE_C64
			LoadB	r7L,INPUT_DEVICE
endif

			LoadW	r10,$0000
			jsr	OpenFile		;Datei auswählen.
			txa				;Diskettenfehler ?
			bne	NOFUNC02		; => Ja, Abbruch...

			LoadW	r0,dataFileName		;Name des Eingabegeräts in
			jmp	LoadInptDevice

;******************************************************************************
;*** Register-Routinen.
;******************************************************************************
;*** Modus für Druckerspooler wechseln.
:SwapSpooler		lda	BootSpooler		;Spooler aktivieren ?
			beq	:1			; => Nein, weiter...

			lda	BootSpoolSize		;Spooler bereits installiert ?
			bne	:2			; => Ja, weiter...
			lda	#MAX_SPOOL_STD		;Spooler-RAM auf Standard setzen.
::1			sta	BootSpoolSize		;Neue Größe Spoole-RAM festlegen.

::2			jsr	SetBank_TaskSpl		;TaskMan/Spooler-RAM belegen.

;*** Modus für AutoStart des Spoolers wechseln.
:SwapSplAuto		lda	Flag_SpoolCount
			sta	BootSpoolCount
			rts

;*** Neuen Wert für Spooler-Verzögerung eingeben.
:Swap_SpoolDelay	lda	r1L			;Register-Menü im Aufbau ?
			beq	Draw_SpoolDelay		; => Ja, nur Anzeige ausgeben.

			jsr	DefMouseXPos		;Neuen Wert für Aktivierungszeit
			cmp	#1
			bcs	:ok
			lda	#1
::ok			asl				;berechnen.
			asl	Flag_SpoolCount		;Bit 7 übernehmen
			ror
			sta	Flag_SpoolCount
			sta	BootSpoolCount

;*** Verzögerungszeit für ScreenSaver festlegen.
:Draw_SpoolDelay	lda	C_InputField		;Farbe für Schiebeegler setzen.
			jsr	DirectColor

			jsr	i_BitmapUp		;Schieberegler ausgeben.
			w	Icon_06
			b	$04 ! DOUBLE_B,$98,Icon_06x ! DOUBLE_B,Icon_06y

			ldx	#$04			;Position für Schieberegler
			lda	Flag_SpoolCount		;berechnen.
			and	#%00111111
			lsr
			bcs	:1
			dex
::1			sta	:2 +1
			txa
			clc
::2			adc	#$ff

if Flag64_128 = TRUE_C128
			ora	#%10000000		;Double-Bit einblenden
endif

			sta	:6 +0

			ldx	#$01			;Breite des Regler-Icons
			lda	Flag_SpoolCount		;berechnen.
			and	#%00111111
			lsr				;Bei 0.5, 1.5, 2.5 usw... 1 CARD.
			bcs	:3			;Bei 1.0, 2.0, 3.0 usw... 2 CARDs.
			inx

if Flag64_128 = TRUE_C128
::3			txa
			ora	#%10000000		;Double-Bit einblenden
			sta	:6 +2
endif

if Flag64_128 = TRUE_C64
::3			stx	:6 +2
endif

			ldx	#<Icon_08		;Typ für Regler-Icon ermitteln.
			ldy	#>Icon_08
			lda	Flag_SpoolCount
			and	#%00111111
			lsr
			bcs	:4			; => Typ #1, 0.5, 1.5, 2.5 usw...
			ldx	#<Icon_07		; => Typ #1, 1.0, 2.0, 3.0 usw...
			ldy	#>Icon_07
::4			stx	:5 +0
			sty	:5 +1

			jsr	i_BitmapUp		;Schieberegler anzeigen.
::5			w	Icon_05
::6			b	$0c,$9b,$01,$05

;******************************************************************************
;*** Register-Routinen.
;******************************************************************************
;*** Aktivierungszeit anzeigen.
:Draw_SpoolTime		LoadW	r0,R6T07 + 6

			lda	Flag_SpoolCount		;Aktivierungszeit in Minuten und
			and	#%00111111		;Sekunden umrechnen.
			sta	:1 +1
			asl
			asl
			clc
::1			adc	#$ff
			lsr
			ldx	#$00
::2			cmp	#60
			bcc	:3
;			sec
			sbc	#60
			inx
			bne	:2
::3			jsr	SetDelayTime

			LoadB	currentMode,$00
			LoadW	r0,R6T07
			jsr	PutString		;Aktivierungszeit anzeigen.
			jmp	RegisterSetFont		;Zeichensatz zurücksetzen.

;******************************************************************************
;*** Variablen.
;******************************************************************************
;*** Laufwerksbezeichnungen.
.DrvNmVec		w DrvNmA,DrvNmB,DrvNmC,DrvNmD
.DrvNmA			s 17
.DrvNmB			s 17
.DrvNmC			s 17
.DrvNmD			s 17

.PartNmVec		w PartNmA,PartNmB,PartNmC,PartNmD
.PartNmA		s 17
.PartNmB		s 17
.PartNmC		s 17
.PartNmD		s 17

;*** Register-Variablen.
:GEOS_ID_ASCII		s $05				;GEOS-ID.

:SpoolRamSize		w $0000				;Größe des Spooler-RAM in KBytes.

:Reserved		b $00				;Reservierte Speicherbank.
:BankBuffer		s $40				;Zwischenspeicher für Bank-Tabelle.

:OpenFile_Type		b $00				;Dateiauswahl: Dateityp.
:OpenFile_Class		w $0000				;Dateiauswahl: Zeiger auf Klasse.

;*** Texte für Hauptmenü.
if Sprache = Deutsch
:TxNoDrv		b "Kein Laufwerk!",NULL
:TxDrvUnknown		b "Unbekannt!",NULL
endif

if Sprache = Englisch
:TxNoDrv		b "No drive!",NULL
:TxDrvUnknown		b "Unknown drive!",NULL
endif

;*** Titelzeile.
:TxGEOSEdit		b PLAINTEXT
			b GOTOXY
			w $0008
			b $06
			b "GEOS.Editor",NULL

;*** Kennung für SD2IEC-Laufwerke.
:TxSD2IEC		b "(SD2IEC)",NULL

;*** Speichererweiterungen.
:TxRAM_RL		b "RAMLINK DACC",NULL
:TxRAM_CBM		b "C=REU",NULL
:TxRAM_BBG		b "GEORAM/BBGRAM",NULL
:TxRAM_SCPU		b "RAMCard",NULL

;--- Ergänzung: 04.07.18/M.Kanet
;W.Grimm hat in der Version von 2003 den 64Net-Treiber
;als RTC-Uhr ergänzt. Routine wurde ungetestet 1:1 übernommen.
;*** RTC-Geräte.
:TxRTC_None		b "-",NULL
:TxRTC_RL		b "RAMLink",NULL
:TxRTC_FD		b "CMD FD",NULL
:TxRTC_HD		b "CMD HD",NULL
:TxRTC_SM		b "SmartMouse",NULL
:TxRTC_64NET		b "PC - 64net",NULL
:TxRTC_Auto		b "AutoDetect",NULL

;*** Variablen für RTC-Uhr-Anzeige.
:VecText_CMD_Clk	w TxRTC_None
			w TxRTC_RL
			w TxRTC_FD
			w TxRTC_HD
			w TxRTC_SM
			w TxRTC_64NET
			w TxRTC_Auto

:RTC_Type		b $00,DrvRAMLink,DrvFD,DrvHD,$fe,$fd,$ff

;*** Dateiname für das speichern der GEOS-ID.
if Flag64_128 = TRUE_C64
:FNameG1		b "GEOS64.1",NULL
endif

if Flag64_128 = TRUE_C128
:FNameG1		b "GEOS128.1",NULL
endif

;******************************************************************************
;*** Dialogboxen.
;******************************************************************************
;*** Dialogbox: Datei wählen.
:Dlg_SlctFile		b $81
			b DBGETFILES!DBSETDRVICON ,$00,$00
			b CANCEL                  ,$00,$00
			b DISK                    ,$00,$00
			b DBUSRICON               ,$00,$00
			w Dlg_SlctInstall
			b NULL

;*** Dialogbox: Datei wählen.
:Dlg_SlctPart		b $81
			b DBGETFILES!DBSELECTPART ,$00,$00
			b CANCEL                  ,$00,$00
			b OPEN                    ,$00,$00
			b NULL

;*** Dialogbox: Laufwerksmodus wählen.
:Dlg_SlctDMode		b $81
			b DBUSRFILES
			w VLIR_Names
			b CANCEL    ,$00,$00
			b DBUSRICON ,$00,$00
			w Dlg_SlctInstall
			b NULL

:Dlg_SlctInstall	w Icon_01
			b $00,$00,$06 ! DOUBLE_B,$10
			w :101

::101			lda	#OPEN
			sta	sysDBData
			jmp	RstrFrmDialogue

;*** Dialogbox: Hintergrundbild zeigen.
:Dlg_GetBScrn		b $00
			b $00,$c7
			w $0000 ! DOUBLE_W,$013f ! DOUBLE_W ! ADD1_W
			b DB_USR_ROUT
			w LdBootScrn
			b DBSYSOPV
			b NULL

;*** Bildschirmschoner - Initialisierung fehlgeschlagen.
:Dlg_ScrSvErr		b %01100001
			b $30,$97
			w $0040 ! DOUBLE_W,$00ff ! DOUBLE_W ! ADD1_W

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$10,$0b
			w Dlg_Titel2
			b DBTXTSTR   ,$10,$20
			w :51
			b DBTXTSTR   ,$10,$2b
			w :52
			b DBTXTSTR   ,$10,$3b
			w :53
			b OK         ,$02,$50
			b NULL

if Sprache = Deutsch
::51			b PLAINTEXT
			b "Der Bildschirmschoner konnte",NULL
::52			b "nicht initialisiert werden!",NULL
::53			b "Bildschirmschoner deaktiviert.",NULL
endif
if Sprache = Englisch
::51			b PLAINTEXT
			b "Unable to initialize the",NULL
::52			b "screen saver!",NULL
::53			b "Screensaver has been disabled.",NULL
endif

;******************************************************************************
;*** Dialogboxen.
;******************************************************************************
;*** Dialogbox: Laufwerk konnte nicht installiert werden.
:Dlg_InstallError	b %01100001
			b $30,$97
			w $0040 ! DOUBLE_W,$00ff ! DOUBLE_W ! ADD1_W

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel1
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2a
			w :3
			b OK         ,$01,$50
			b NULL

if Sprache = Deutsch
::2			b "Das Laufwerk konnte nicht",NULL
::3			b "installiert werden!",NULL
endif

if Sprache = Englisch
::2			b "Unable to install drive!",NULL
::3			b NULL
endif

;*** Dialogbox: Nicht genügend freier Speicher.
:Dlg_InstErrNoRAM	b %01100001
			b $30,$97
			w $0040 ! DOUBLE_W,$00ff ! DOUBLE_W ! ADD1_W

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel1
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2c
			w :3
			b DBTXTSTR   ,$0c,$36
			w :4
			b OK         ,$01,$50
			b NULL

if Sprache = Deutsch
::2			b "Installation abgebrochen!",NULL
::3			b "Es ist nicht ausreichend",NULL
::4			b "freier Speicher verfügbar.",NULL
endif

if Sprache = Englisch
::2			b "Unable to install drive!",NULL
::3			b "Not enough free extended",NULL
::4			b "memory available!",NULL
endif

;******************************************************************************
;*** Dialogboxen.
;******************************************************************************
;*** Dialogbox: Speicherbank für Laufwerkstreiber belegt.
:Dlg_DkRamInUse		b %01100001
			b $30,$97
			w $0040 ! DOUBLE_W,$00ff ! DOUBLE_W ! ADD1_W

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel1
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2a
			w :3
			b DBTXTSTR   ,$0c,$34
			w :4
			b DBTXTSTR   ,$0c,$3e
			w :5
			b OK         ,$01,$50
			b NULL

if Sprache = Deutsch
::2			b "Installieren der Laufwerks-",NULL
::3			b "treiber nicht möglich!",NULL
::4			b "Die benötigte Speicherbank",NULL
::5			b "ist bereits belegt!",NULL
endif

if Sprache = Englisch
::2			b "Unable to copy Diskdrivers",NULL
::3			b "to Ram-expansion!",NULL
::4			b "The required 64K-memory is",NULL
::5			b "used by another application!",NULL
endif

;*** Dialogbox: Startlaufwerk kann nicht geändert werden.
:Dlg_ErrLdSysFile	b %01100001
			b $30,$97
			w $0040 ! DOUBLE_W,$00ff ! DOUBLE_W ! ADD1_W

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel1
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2a
			w :3
			b OK         ,$01,$50
			b NULL

if Sprache = Deutsch
::2			b "Systemlaufwerk kann nicht",NULL
::3			b "gewechselt werden!",NULL
endif

if Sprache = Englisch
::2			b "Unable to install new",NULL
::3			b "driver on systemdrive!",NULL
endif

;******************************************************************************
;*** Dialogboxen.
;******************************************************************************
;<*> Routine entfällt bis auf weiteres.
;<*>;*** Dialogbox: Laufwerk abschalten.
;<*>:Dlg_TurnOffDrv	b %01100001
;<*>			b $30,$97
;<*>			w $0040 ! DOUBLE_W,$00ff ! DOUBLE_W ! ADD1_W
;<*>
;<*>			b DB_USR_ROUT
;<*>			w Dlg_DrawTitel
;<*>			b DBTXTSTR   ,$0c,$0b
;<*>			w Dlg_Titel2
;<*>			b DBTXTSTR   ,$0c,$20
;<*>			w :2
;<*>
;<*>if Sprache = Deutsch
;<*>			b DBTXTSTR   ,$0c,$2a
;<*>			w :3
;<*>			b OK         ,$11,$50
;<*>			b NULL
;<*>
;<*>::2			b "Bitte schalten Sie jetzt",NULL
;<*>::3			b "das Laufwerk "
;<*>:TurnOffDrvAdr	b "x: aus!",NULL
;<*>endif
;<*>
;<*>if Sprache = Englisch
;<*>			b OK         ,$11,$50
;<*>			b NULL
;<*>
;<*>::2			b "Please switch off drive "
;<*>:TurnOffDrvAdr	b "x: !",NULL
;<*>endif

;******************************************************************************
;*** Dialogboxen.
;******************************************************************************
;*** Dialogbox: Konfiguration kann nicht gespeichert werden.
:Dlg_ErrLdCfgFile	b %01100001
			b $30,$97
			w $0040 ! DOUBLE_W,$00ff ! DOUBLE_W ! ADD1_W

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel1
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2a
			w :3
			b DBTXTSTR   ,$20,$36
			w SysFileName
			b DBTXTSTR   ,$0c,$42
			w :4
			b OK         ,$01,$50
			b NULL

if Sprache = Deutsch
::2			b "Speichern der Konfiguration",NULL
::3			b "ist nicht möglich! Die Datei:",NULL
::4			b "fehlt auf Laufwerk "
:SaveErrorDrive		b "x: !",NULL
endif

if Sprache = Englisch
::2			b "Unable to save configuration",NULL
::3			b "to disk! The file:",NULL
::4			b "is not on drive "
:SaveErrorDrive		b "x: !",NULL
endif

;*** Dialogbox: Konfiguration kann nicht gespeichert werden.
:Dlg_SaveError		b %01100001
			b $30,$97
			w $0040 ! DOUBLE_W,$00ff ! DOUBLE_W ! ADD1_W

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel1
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2a
			w :3
			b DBTXTSTR   ,$0c,$34
			w :4
			b OK         ,$01,$50
			b NULL

if Sprache = Deutsch
::2			b "Speichern der Konfiguration",NULL
::3			b "auf Grund eines Disketten -",NULL
::4			b "fehlers abgebrochen!",NULL
endif

if Sprache = Englisch
::2			b "Unable to save configuration",NULL
::3			b "on disk because a diskerror",NULL
::4			b "was detected!",NULL
endif

;******************************************************************************
;*** Dialogboxen.
;******************************************************************************
;*** Dialogbox: Systemdatei 'GEOS64.1' nicht gefunden.
:Dlg_SvIDErrSys		b %01100001
			b $30,$97
			w $0040 ! DOUBLE_W,$00ff ! DOUBLE_W ! ADD1_W

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel1
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2a
			w :3
			b DBTXTSTR   ,$0c,$38
			w :4
			b DBTXTSTR   ,$0c,$42
			w :5
			b OK         ,$01,$50
			b NULL

if Sprache = Deutsch
::2			b "Systemdatei nicht gefunden:",NULL
endif
if Sprache ! Flag64_128 = Deutsch ! TRUE_C64
::3			b "  >> GEOS64.1",NULL
endif
if Sprache ! Flag64_128 = Deutsch ! TRUE_C128
::3			b "  >> GEOS128.1",NULL
endif
if Sprache = Deutsch
::4			b "GEOS-ID konnte nicht auf Disk",NULL
::5			b "gespeichert werden!",NULL
endif

if Sprache = Englisch
::2			b "Systemfile not found:",NULL
endif
if Sprache ! Flag64_128 = Englisch ! TRUE_C64
::3			b "  >> GEOS64.1",NULL
endif
if Sprache ! Flag64_128 = Englisch ! TRUE_C128
::3			b "  >> GEOS128.1",NULL
endif
if Sprache = Englisch
::4			b "GEOS-ID could not been",NULL
::5			b "saved to disk!",NULL
endif

;*** Dialogbox: GEOS-ID kann wegen DiskError nicht gespeichert werden.
:Dlg_SvIDErrDsk		b %01100001
			b $30,$97
			w $0040 ! DOUBLE_W,$00ff ! DOUBLE_W ! ADD1_W

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel1
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2a
			w :3
			b DBTXTSTR   ,$0c,$34
			w :4
			b OK         ,$01,$50
			b NULL

if Sprache = Deutsch
::2			b "Speichern der GEOS-ID auf",NULL
::3			b "Grund eines Diskettenfehlers",NULL
::4			b "abgebrochen!",NULL
endif
if Sprache = Englisch
::2			b "Unable to save GEOS-ID to",NULL
::3			b "disk because a disk error",NULL
::4			b "was detected!",NULL
endif

;*** Dialogbox: GEOS-ID gespeichert.
:Dlg_SvID_OK		b %01100001
			b $30,$97
			w $0040 ! DOUBLE_W,$00ff ! DOUBLE_W ! ADD1_W

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel2
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2a
			w :3
			b OK         ,$01,$50
			b NULL

if Sprache = Deutsch
::2			b "Speichern der GEOS-ID",NULL
::3			b "erfolgreich beendet!",NULL
endif
if Sprache = Englisch
::2			b "Saving the GEOS-ID to disk",NULL
::3			b "successfully completed!",NULL
endif

;******************************************************************************
;*** Icon-Menü / Register-Menü.
;******************************************************************************
;*** System-Iconmenü.
:IconMenu		b $02
			w $0000
			b $00

			w Icon_02
			b $00 ! DOUBLE_B,$08,$05 ! DOUBLE_B,$18
			w Menu_ExitConfig

			w Icon_03
			b $05 ! DOUBLE_B,$08,$05 ! DOUBLE_B,$18
			w Menu_SaveConfig

;*** Register-Tabelle.
:RegisterTab1		b $30,$bf
			w $0008 ! DOUBLE_W,$0137 ! DOUBLE_W ! ADD1_W

			b 6				;Anzahl Einträge.

			w RegTName1_1			;Register: "Laufwerke".
			w RegTMenu_1

			w RegTName1_2			;Register: "System".
			w RegTMenu_2

			w RegTName1_3			;Register: "Speicher".
			w RegTMenu_3

			w RegTName1_4			;Register: "Anzeige".
			w RegTMenu_4

			w RegTName1_5			;Register: "Menü".
			w RegTMenu_5

			w RegTName1_6			;Register: "Drucker".
			w RegTMenu_6

:RegTName1_1		w Icon_20
			b RegCardIconX_1,$28,Icon_20x ! DOUBLE_B,Icon_20y

:RegTName1_2		w Icon_21
			b RegCardIconX_2,$28,Icon_21x ! DOUBLE_B,Icon_21y

:RegTName1_3		w Icon_23
			b RegCardIconX_3,$28,Icon_23x ! DOUBLE_B,Icon_23y

:RegTName1_4		w Icon_22
			b RegCardIconX_4,$28,Icon_22x ! DOUBLE_B,Icon_22y

:RegTName1_5		w Icon_25
			b RegCardIconX_5,$28,Icon_25x ! DOUBLE_B,Icon_25y

:RegTName1_6		w Icon_24
			b RegCardIconX_6,$28,Icon_24x ! DOUBLE_B,Icon_24y

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "LAUFWERKE".
:RegTMenu_1		b 15

			b BOX_FRAME			;----------------------------------------
				w R1T01
				w $0000
				b $40,$b7
				w $0018!DOUBLE_W,$0127!DOUBLE_W!ADD1_W
			b BOX_USEROPT_VIEW		;----------------------------------------
				w R1T02
				w PutDrvInfoA
				b $48,$57
				w $0068!DOUBLE_W,$010f!DOUBLE_W!ADD1_W
			b BOX_ICON			;----------------------------------------
				w $0000
				w InstNewDrvA
				b $48
				w $0110!DOUBLE_W
				w RegTIcon1_1_01
				b $02
			b BOX_ICON			;----------------------------------------
				w $0000
				w InstNewPartA
				b $50
				w $0110!DOUBLE_W
				w RegTIcon1_1_01
				b $02
			b BOX_USEROPT_VIEW		;----------------------------------------
				w R1T03
				w PutDrvInfoB
				b $60,$6f
				w $0068!DOUBLE_W,$010f!DOUBLE_W!ADD1_W
			b BOX_ICON			;----------------------------------------
				w $0000
				w InstNewDrvB
				b $60
				w $0110!DOUBLE_W
				w RegTIcon1_1_01
				b $05
			b BOX_ICON			;----------------------------------------
				w $0000
				w InstNewPartB
				b $68
				w $0110!DOUBLE_W
				w RegTIcon1_1_01
				b $05
			b BOX_USEROPT_VIEW		;----------------------------------------
				w R1T04
				w PutDrvInfoC
				b $78,$87
				w $0068!DOUBLE_W,$010f!DOUBLE_W!ADD1_W
			b BOX_ICON			;----------------------------------------
				w $0000
				w InstNewDrvC
				b $78
				w $0110!DOUBLE_W
				w RegTIcon1_1_01
				b $08
			b BOX_ICON			;----------------------------------------
				w $0000
				w InstNewPartC
				b $80
				w $0110!DOUBLE_W
				w RegTIcon1_1_01
				b $08
			b BOX_USEROPT_VIEW		;----------------------------------------
				w R1T05
				w PutDrvInfoD
				b $90,$9f
				w $0068!DOUBLE_W,$010f!DOUBLE_W!ADD1_W
			b BOX_ICON			;----------------------------------------
				w $0000
				w InstNewDrvD
				b $90
				w $0110!DOUBLE_W
				w RegTIcon1_1_01
				b $0b
			b BOX_ICON			;----------------------------------------
				w $0000
				w InstNewPartD
				b $98
				w $0110!DOUBLE_W
				w RegTIcon1_1_01
				b $0b
			b BOX_OPTION			;----------------------------------------
				w R1T06
				w Swap_DskInRAM
				b $a8
				w $0020!DOUBLE_W
				w BootLoadDkDv
				b %11111111
			b BOX_OPTION			;----------------------------------------
				w R1T07
				w $0000
				b $a8
				w $00d8!DOUBLE_W
				w BootUseFastPP
				b %10000000

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
if Sprache = Deutsch
:R1T01			b "AKTUELLE KONFIGURATION",NULL

:R1T02			w $0020 ! DOUBLE_W
			b $4e
			b "Laufwerk A:",NULL

:R1T03			w $0020 ! DOUBLE_W
			b $66
			b "Laufwerk B:",NULL

:R1T04			w $0020 ! DOUBLE_W
			b $7e
			b "Laufwerk C:",NULL

:R1T05			w $0020 ! DOUBLE_W
			b $96
			b "Laufwerk D:",NULL

:R1T06			w $0030 ! DOUBLE_W
			b $ae
			b "Treiber in RAM kopieren",NULL

:R1T07			w $00e8 ! DOUBLE_W
			b $ae
			b "HD-Kabel",NULL
endif

if Sprache = Englisch
:R1T01			b "CURRENT CONFIGURATION",NULL

:R1T02			w $0020 ! DOUBLE_W
			b $4e
			b "Drive A:",NULL

:R1T03			w $0020 ! DOUBLE_W
			b $66
			b "Drive B:",NULL

:R1T04			w $0020 ! DOUBLE_W
			b $7e
			b "Drive C:",NULL

:R1T05			w $0020 ! DOUBLE_W
			b $96
			b "Drive D:",NULL

:R1T06			w $0030 ! DOUBLE_W
			b $ae
			b "Diskdrivers to RAM",NULL

:R1T07			w $00e8 ! DOUBLE_W
			b $ae
			b "HD-cable",NULL
endif

:RegTIcon1_1_01		w Icon_09
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b $01 ! DOUBLE_B
			b $08
			b USE_COLOR_INPUT		;Farbe für Icon.

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "SYSTEM".
:RegTMenu_2		b 14

			b BOX_FRAME			;----------------------------------------
				w R2T01
				w $0000
				b $40,$87
				w $0018!DOUBLE_W,$0097!DOUBLE_W!ADD1_W
			b BOX_OPTION_VIEW		;----------------------------------------
				w R2T02
				w $0000
				b $48
				w $0088!DOUBLE_W
				w SCPU_Aktiv
				b %11111111
:RegTMenu_2a		b BOX_OPTION			;----------------------------------------
				w R2T03
				w Swap_Speed
				b $58
				w $0088!DOUBLE_W
				w LastSpeedMode
				b %11111111
:RegTMenu_2c		b BOX_OPTION			;----------------------------------------
				w R2T04
				w Swap_Optimize
				b $68
				w $0088!DOUBLE_W
				w Flag_Optimize
				b %00000011
			b BOX_OPTION_VIEW		;----------------------------------------
				w R2T10
				w $0000
				b $78
				w $0088!DOUBLE_W
				w SCPU_Aktiv
				b %00000011

			b BOX_FRAME			;----------------------------------------
				w R2T05
				w $0000
				b $40,$67
				w $00a0!DOUBLE_W,$0127!DOUBLE_W!ADD1_W
:RegTMenu_2b		b BOX_OPTION			;----------------------------------------
				w R2T06
				w Swap_MOVEDATA
				b $58
				w $0118!DOUBLE_W
				w sysRAMFlg
				b %10000000

			b BOX_FRAME			;----------------------------------------
				w R2T07
				w $0000
				b $70,$87
				w $00a0!DOUBLE_W,$0127!DOUBLE_W!ADD1_W
			b BOX_ICON			;----------------------------------------
				w $0000
				w SetClockGEOS
				b $78
				w $00a8!DOUBLE_W
				w RegTIcon1_3_01
				b $00
:RegTMenu_2d		b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w PutSetClkInfo
				b $78,$7f
				w $00b0!DOUBLE_W,$0117!DOUBLE_W!ADD1_W
			b BOX_ICON			;----------------------------------------
				w $0000
				w SetNewClkDev
				b $78
				w $0118!DOUBLE_W
				w RegTIcon1_1_01
				b $09

			b BOX_FRAME			;----------------------------------------
				w R2T08
				w $0000
				b $90,$af
				w $0018!DOUBLE_W,$0127!DOUBLE_W!ADD1_W
			b BOX_ICON			;----------------------------------------
				w $0000
				w SaveGEOS_IDtoDsk
				b $a0
				w $00f8!DOUBLE_W
				w RegTIcon1_3_01
				b $00
			b BOX_STRING			;----------------------------------------
				w R2T09
				w SetNewGEOS_ID
				b $a0
				w $0100!DOUBLE_W
				w GEOS_ID_ASCII
				b $04

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
if Sprache = Deutsch
:R2T01			b "CMD SUPERCPU",NULL

:R2T02			w $0020 ! DOUBLE_W
			b $4e
			b "SCPU aktiviert:",NULL

:R2T03			w $0020 ! DOUBLE_W
			b $5e
:MhzModus		b "1MHz-Modus:",NULL

:R2T04			w $0020 ! DOUBLE_W
			b $6e
			b "Optimierung Aus:",NULL

:R2T10			w $0020 ! DOUBLE_W
			b $7e
			b "16Bit-MoveData:",NULL

:R2T05			b "C=/CMD REU",NULL

:R2T06			w $00a8 ! DOUBLE_W
			b $4e
			b "Speichertransfer"
			b GOTOXY
			w $00a8 ! DOUBLE_W
			b $56
			b "optimieren."
			b GOTOXY
			w $00a8 ! DOUBLE_W
			b $5e
			b "C=REU-MoveData:",NULL

:R2T07			b "UHRZEIT SETZEN",NULL

:R2T08			b "GEOS ID",NULL

:R2T09			w $0020 ! DOUBLE_W
			b $9e
			b "Die aktuelle GEOS-ID. Die neue ID"
			b GOTOXY
			w $0020 ! DOUBLE_W
			b $a6
			b "kann auf Disk gespeichert werden.",NULL
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
if Sprache = Englisch
:R2T01			b "CMD SUPERCPU",NULL

:R2T02			w $0020 ! DOUBLE_W
			b $4e
			b "SCPU is activ:",NULL

:R2T03			w $0020 ! DOUBLE_W
			b $5e
:MhzModus		b "1MHz-Mode:",NULL

:R2T04			w $0020 ! DOUBLE_W
			b $6e
			b "Optimization Off:",NULL

:R2T10			w $0020 ! DOUBLE_W
			b $7e
			b "16Bit-MoveData:",NULL

:R2T05			b "C=/CMD REU",NULL

:R2T06			w $00a8 ! DOUBLE_W
			b $4e
			b "Enable fast"
			b GOTOXY
			w $00a8 ! DOUBLE_W
			b $56
			b "memory transfer."
			b GOTOXY
			w $00a8 ! DOUBLE_W
			b $5e
			b "C=REU-MoveData:",NULL

:R2T07			b "SET CLOCK",NULL

:R2T08			b "GEOS ID",NULL

:R2T09			w $0020 ! DOUBLE_W
			b $9e
			b "The current GEOS-ID."
			b GOTOXY
			w $0020 ! DOUBLE_W
			b $a6
			b "The new ID can be saved to disk.",NULL
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "SPEICHER".
:RegTMenu_3		b 16

			b BOX_FRAME			;----------------------------------------
				w R3T01
				w Draw_MemInfo
				b $40,$9f
				w $0018!DOUBLE_W,$00a7!DOUBLE_W!ADD1_W
			b BOX_FRAME			;----------------------------------------
				w R3T03
				w $0000
				b $40,$5f
				w $00b0!DOUBLE_W,$0127!DOUBLE_W!ADD1_W
			b BOX_NUMERIC			;----------------------------------------
				w R3T04
				w Swap_BankMode
				b $50
				w $0108!DOUBLE_W
				w Reserved
				b 2!NUMERIC_LEFT!NUMERIC_BYTE
			b BOX_FRAME			;----------------------------------------
				w R3T05
				w $0000
				b $68,$7f
				w $00b0!DOUBLE_W,$0127!DOUBLE_W!ADD1_W
:RegTMenu_3a		b BOX_NUMERIC_VIEW		;----------------------------------------
				w R3T06
				w Update_MemInfo
				b $70
				w $0108!DOUBLE_W
				w TASK_COUNT
				b 2!NUMERIC_LEFT!NUMERIC_BYTE
			b BOX_ICON			;----------------------------------------
				w $0000
				w Swap_MaxTask
				b $70
				w $0118!DOUBLE_W
				w RegTIcon1_6_01
				b $05
			b BOX_FRAME			;----------------------------------------
				w R3T07
				w $0000
				b $88,$9f
				w $00b0!DOUBLE_W,$0127!DOUBLE_W!ADD1_W
:RegTMenu_3b		b BOX_NUMERIC_VIEW		;----------------------------------------
				w R3T08
				w Update_MemInfo
				b $90
				w $00b8 !DOUBLE_W
				w SpoolRamSize
				b 4!NUMERIC_RIGHT!NUMERIC_WORD
			b BOX_ICON			;----------------------------------------
				w $0000
				w Swap_SpoolRAM
				b $90
				w $00d8!DOUBLE_W
				w RegTIcon1_6_01
				b $08
			b BOX_USER_VIEW			;----------------------------------------
				w R3T09
				w Draw_Info_Free
				b $a8,$af
				w $0018!DOUBLE_W,$001f!DOUBLE_W!ADD1_W
			b BOX_USER_VIEW			;----------------------------------------
				w R3T10
				w Draw_Info_GEOS
				b $b0,$b7
				w $0018!DOUBLE_W,$001f!DOUBLE_W!ADD1_W
			b BOX_USER_VIEW			;----------------------------------------
				w R3T11
				w Draw_Info_Disk
				b $b0,$b7
				w $0040!DOUBLE_W,$0047!DOUBLE_W!ADD1_W
			b BOX_USER_VIEW			;----------------------------------------
				w R3T12
				w Draw_Info_Task
				b $b0,$b7
				w $0068!DOUBLE_W,$006f!DOUBLE_W!ADD1_W
			b BOX_USER_VIEW			;----------------------------------------
				w R3T13
				w Draw_Info_Spool
				b $b0,$b7
				w $00c0!DOUBLE_W,$00c7!DOUBLE_W!ADD1_W
			b BOX_USER_VIEW			;----------------------------------------
				w R3T14
				w Draw_Info_NoRAM
				b $a8,$af
				w $0040!DOUBLE_W,$0047!DOUBLE_W!ADD1_W
			b BOX_USER_VIEW			;----------------------------------------
				w R3T15
				w Draw_Info_Block
				b $a8,$af
				w $0088!DOUBLE_W,$008f!DOUBLE_W!ADD1_W

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
if Sprache = Deutsch
:R3T01			b "SPEICHERBELEGUNG",NULL
:R3T02			b GOTOXY
			w $0048 ! DOUBLE_W
			b $5e
			b ">>"
			b GOTOXY
			w $0020 ! DOUBLE_W
			b $62
			b "1024 K"
			b GOTOXY
			w $0020 ! DOUBLE_W
			b $72
			b "2048 K"
			b GOTOXY
			w $0020 ! DOUBLE_W
			b $82
			b "3072 K"
			b GOTOXY
			w $0020 ! DOUBLE_W
			b $92
			b "4096 K"
			b GOTOXY
			w $0028 ! DOUBLE_W
			b $4e
			b NULL

:R3T03			b "SPEICHER",NULL

:R3T04			w $00b4 ! DOUBLE_W
			b $4c
			b "64K-RAM-Speicher"
			b GOTOXY
			w $00b4 ! DOUBLE_W
			b $56
			b "reservieren:",NULL

:R3T05			b "TASKMANAGER",NULL

:R3T06			w $00b4 ! DOUBLE_W
			b $76
			b "Anwendungen:",NULL

:R3T07			b "DRUCKERSPOOLER",NULL

:R3T08			w $00e4 ! DOUBLE_W
			b $96
			b "KByte",NULL
:R3T09			w $0024 ! DOUBLE_W
			b $ae
			b "Frei",NULL
:R3T10			w $0024 ! DOUBLE_W
			b $b6
			b "GEOS",NULL
:R3T11			w $004c ! DOUBLE_W
			b $b6
			b "Disk",NULL
:R3T12			w $0074 ! DOUBLE_W
			b $b6
			b "TaskManager",NULL
:R3T13			w $00cc ! DOUBLE_W
			b $b6
			b "Spooler",NULL
:R3T14			w $004c ! DOUBLE_W
			b $ae
			b "Kein RAM",NULL
:R3T15			w $0094 ! DOUBLE_W
			b $ae
			b "Reserviert",NULL
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
if Sprache = Englisch
:R3T01			b "MEMORY-MAP",NULL
:R3T02			b GOTOXY
			w $0048 ! DOUBLE_W
			b $5e
			b ">>"
			b GOTOXY
			w $0020 ! DOUBLE_W
			b $62
			b "1024 K"
			b GOTOXY
			w $0020 ! DOUBLE_W
			b $72
			b "2048 K"
			b GOTOXY
			w $0020 ! DOUBLE_W
			b $82
			b "3072 K"
			b GOTOXY
			w $0020 ! DOUBLE_W
			b $92
			b "4096 K"
			b GOTOXY
			w $0028 ! DOUBLE_W
			b $4e
			b NULL

:R3T03			b "MEMORY",NULL

:R3T04			w $00b4 ! DOUBLE_W
			b $4c
			b "Reserve 64K-RAM-"
			b GOTOXY
			w $00b4 ! DOUBLE_W
			b $56
			b "memory:",NULL

:R3T05			b "TASKMANAGER",NULL

:R3T06			w $00b4 ! DOUBLE_W
			b $76
			b "Applications:",NULL

:R3T07			b "PRINTSPOOLER",NULL

:R3T08			w $00e4 ! DOUBLE_W
			b $96
			b "KByte",NULL
:R3T09			w $0024 ! DOUBLE_W
			b $ae
			b "Free",NULL
:R3T10			w $0024 ! DOUBLE_W
			b $b6
			b "GEOS",NULL
:R3T11			w $004c ! DOUBLE_W
			b $b6
			b "Disk",NULL
:R3T12			w $0074 ! DOUBLE_W
			b $b6
			b "TaskManager",NULL
:R3T13			w $00cc ! DOUBLE_W
			b $b6
			b "Spooler",NULL
:R3T14			w $004c ! DOUBLE_W
			b $ae
			b "No RAM",NULL
:R3T15			w $0094 ! DOUBLE_W
			b $ae
			b "Reserved",NULL
endif

:RegTIcon1_3_01		w Icon_11
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_11x ! DOUBLE_B
			b Icon_11y
			b USE_COLOR_INPUT		;Farbe für Icon.

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "BILDSCHIRMSCHONER".
:RegTMenu_4		b 11

			b BOX_FRAME			;----------------------------------------
				w R4T01
				w $0000
				b $40,$7f
				w $0018!DOUBLE_W,$0127!DOUBLE_W!ADD1_W
			b BOX_USER			;----------------------------------------
				w $0000
				w StartScrnSaver
				b $48,$4f
				w $0048!DOUBLE_W,$00c7!DOUBLE_W!ADD1_W
			b BOX_STRING_VIEW		;----------------------------------------
				w R4T02
				w StartScrnSaver
				b $48
				w $0048!DOUBLE_W
				w BootSaverName
				b 16
			b BOX_ICON			;----------------------------------------
				w $0000
				w GetNewScrSaver
				b $48
				w $00c8!DOUBLE_W
				w RegTIcon1_1_01
				b $03
			b BOX_USER			;----------------------------------------
				w $0000
				w Swap_ScrSvDelay
				b $68,$6f
				w $0023!DOUBLE_W,$00bf!DOUBLE_W!ADD1_W
:RegTMenu_4a		b BOX_OPTION			;----------------------------------------
				w R4T05
				w Swap_ScrSaver
				b $58
				w $0020!DOUBLE_W
				w Flag_ScrSaver
				b %10000000

			b BOX_FRAME			;----------------------------------------
				w R4T06
				w $0000
				b $88,$af
				w $0018!DOUBLE_W,$0127!DOUBLE_W!ADD1_W
			b BOX_OPTION			;----------------------------------------
				w R4T08
				w Swap_BackScrn
				b $90
				w $0020!DOUBLE_W
				w sysRAMFlg
				b %00001000
			b BOX_USER			;----------------------------------------
				w $0000
				w PrintCurBackScrn
				b $a0,$a7
				w $0048!DOUBLE_W,$00bf!DOUBLE_W!ADD1_W
			b BOX_STRING_VIEW		;----------------------------------------
				w R4T07
				w $0000
				b $a0
				w $0048!DOUBLE_W
				w BootGrfxFile
				b 16
			b BOX_ICON			;----------------------------------------
				w $0000
				w GetNewBackScrn
				b $a0
				w $00c8!DOUBLE_W
				w RegTIcon1_1_01
				b $0a

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
if Sprache = Deutsch
:R4T01			b "BILDSCHIRMSCHONER",NULL

:R4T02			w $0020 ! DOUBLE_W
			b $4e
			b "Name:",NULL

:R4T04			b GOTOXY
			w $00c8 ! DOUBLE_W
			b $6e
			b "( 00:00 MIN. ) "
			b GOTOXY
			w $0020 ! DOUBLE_W
			b $76
			b "<->"
			b GOTOX
			w $0049 ! DOUBLE_W
			b "01:00"
			b GOTOX
			w $0078 ! DOUBLE_W
			b "02:00"
			b GOTOX
			w $00b6 ! DOUBLE_W
			b "<+>"
			b NULL

:R4T05			w $0030 ! DOUBLE_W
			b $5e
			b "Bildschirmschoner deaktivieren",NULL

:R4T06			b "HINTERGRUNDBILD",NULL

:R4T07			w $0020 ! DOUBLE_W
			b $a6
			b "Name:",NULL

:R4T08			w $0030 ! DOUBLE_W
			b $96
			b "Hintergrundbild verwenden",NULL
endif

if Sprache = Englisch
:R4T01			b "SCREENSAVER",NULL

:R4T02			w $0020 ! DOUBLE_W
			b $4e
			b "Name:",NULL

:R4T04			b GOTOXY
			w $00c8 ! DOUBLE_W
			b $6e
			b "( 00:00 MIN. ) "
			b GOTOXY
			w $0020 ! DOUBLE_W
			b $76
			b "<->"
			b GOTOX
			w $0049 ! DOUBLE_W
			b "01:00"
			b GOTOX
			w $0078 ! DOUBLE_W
			b "02:00"
			b GOTOX
			w $00b6 ! DOUBLE_W
			b "<+>"
			b NULL

:R4T05			w $0030 ! DOUBLE_W
			b $5e
			b "Turn off screensaver",NULL

:R4T06			b "BACKGROUND-PICTURE",NULL

:R4T07			w $0020 ! DOUBLE_W
			b $a6
			b "Name:",NULL

:R4T08			w $0030 ! DOUBLE_W
			b $96
			b "Use background-picture",NULL
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "MENU".
if Sprache = Deutsch
:RegTMenu_5		b 15

			b BOX_FRAME			;----------------------------------------
				w R5T01
				w $0000
				b $40,$87
				w $0018!DOUBLE_W,$00af!DOUBLE_W!ADD1_W
			b BOX_OPTION			;----------------------------------------
				w R5T02
				w Swap_MenuMode
				b $48
				w $00a0!DOUBLE_W
				w Flag_MenuStatus
				b %10000000
			b BOX_OPTION			;----------------------------------------
				w R5T03
				w Swap_MenuMode
				b $58
				w $0090!DOUBLE_W
				w Flag_MenuStatus
				b %00100000
			b BOX_OPTION			;----------------------------------------
				w $0000
				w Swap_MenuMode
				b $58
				w $00a0!DOUBLE_W
				w Flag_MenuStatus
				b %00010000
			b BOX_OPTION			;----------------------------------------
				w R5T04
				w Swap_MLineMode
				b $68
				w $00a0!DOUBLE_W
				w Flag_SetMLine
				b %10000000
			b BOX_OPTION			;----------------------------------------
				w R5T04a
				w Swap_MenuMode
				b $78
				w $00a0!DOUBLE_W
				w Flag_MenuStatus
				b %01000000

			b BOX_FRAME			;----------------------------------------
				w R5T05
				w $0000
				b $40,$5f
				w $00b8!DOUBLE_W,$0127!DOUBLE_W!ADD1_W
			b BOX_USER			;----------------------------------------
				w R5T06
				w Swap_CRSR_Speed
				b $50,$57
				w $00c3!DOUBLE_W,$00ff!DOUBLE_W!ADD1_W

			b BOX_FRAME			;----------------------------------------
				w R5T07
				w $0000
				b $68,$87
				w $00b8!DOUBLE_W,$0127!DOUBLE_W!ADD1_W
			b BOX_OPTION			;----------------------------------------
				w R5T08
				w Swap_ColsMode
				b $78
				w $0118!DOUBLE_W
				w Flag_SetColor
				b %10000000

			b BOX_FRAME			;----------------------------------------
				w R5T09
				w $0000
				b $90,$af
				w $0018!DOUBLE_W,$00af!DOUBLE_W!ADD1_W
			b BOX_STRING			;----------------------------------------
				w R5T10
				w GetInpDrvFile
				b $a0
				w $0020!DOUBLE_W
				w inputDevName
				b 16
			b BOX_ICON			;----------------------------------------
				w $0000
				w GetNewInput
				b $a0
				w $00a0!DOUBLE_W
				w RegTIcon1_1_01
				b $0b

;--- Ergänzung: 03.01.19/M.Kanet
;Umschaltung QWERTZ / QWERTY ergänzt.
			b BOX_FRAME			;----------------------------------------
				w R5T12
				w $0000
				b $90,$af
				w $00b8!DOUBLE_W,$0127!DOUBLE_W!ADD1_W
			b BOX_OPTION			;----------------------------------------
				w R5T13
				w InitQWERTZ
				b $a0
				w $0118!DOUBLE_W
				w BootQWERTZ
				b %11111111
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "MENU".
if Sprache = Englisch
:RegTMenu_5		b 13

			b BOX_FRAME			;----------------------------------------
				w R5T01
				w $0000
				b $40,$87
				w $0018!DOUBLE_W,$00af!DOUBLE_W!ADD1_W
			b BOX_OPTION			;----------------------------------------
				w R5T02
				w Swap_MenuMode
				b $48
				w $00a0!DOUBLE_W
				w Flag_MenuStatus
				b %10000000
			b BOX_OPTION			;----------------------------------------
				w R5T03
				w Swap_MenuMode
				b $58
				w $0090!DOUBLE_W
				w Flag_MenuStatus
				b %00100000
			b BOX_OPTION			;----------------------------------------
				w $0000
				w Swap_MenuMode
				b $58
				w $00a0!DOUBLE_W
				w Flag_MenuStatus
				b %00010000
			b BOX_OPTION			;----------------------------------------
				w R5T04
				w Swap_MLineMode
				b $68
				w $00a0!DOUBLE_W
				w Flag_SetMLine
				b %10000000
			b BOX_OPTION			;----------------------------------------
				w R5T04a
				w Swap_MenuMode
				b $78
				w $00a0!DOUBLE_W
				w Flag_MenuStatus
				b %01000000

			b BOX_FRAME			;----------------------------------------
				w R5T05
				w $0000
				b $40,$5f
				w $00b8!DOUBLE_W,$0127!DOUBLE_W!ADD1_W
			b BOX_USER			;----------------------------------------
				w R5T06
				w Swap_CRSR_Speed
				b $50,$57
				w $00c3!DOUBLE_W,$00ff!DOUBLE_W!ADD1_W

			b BOX_FRAME			;----------------------------------------
				w R5T07
				w $0000
				b $68,$87
				w $00b8!DOUBLE_W,$0127!DOUBLE_W!ADD1_W
			b BOX_OPTION			;----------------------------------------
				w R5T08
				w Swap_ColsMode
				b $78
				w $0110!DOUBLE_W
				w Flag_SetColor
				b %10000000

			b BOX_FRAME			;----------------------------------------
				w R5T09
				w $0000
				b $90,$af
				w $0018!DOUBLE_W,$0127!DOUBLE_W!ADD1_W
			b BOX_STRING			;----------------------------------------
				w R5T10
				w GetInpDrvFile
				b $98
				w $0048!DOUBLE_W
				w inputDevName
				b 16
			b BOX_ICON			;----------------------------------------
				w R5T11
				w GetNewInput
				b $98
				w $00c8!DOUBLE_W
				w RegTIcon1_1_01
				b $0b
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
if Sprache = Deutsch
:R5T01			b "GEOS-MENÜ",NULL

:R5T02			w $0020 ! DOUBLE_W
			b $4e
			b "Eintrag invertieren:",NULL

:R5T03			w $0020 ! DOUBLE_W
			b $5e
			b "Menü/Icon-Status:",NULL

:R5T04			w $0020 ! DOUBLE_W
			b $6e
			b "Trennlinien setzen:",NULL

:R5T04a			w $0020 ! DOUBLE_W
			b $7e
			b "Stop am unteren Rand:",NULL

:R5T05			b "CURSOR",NULL
:R5T06			w $00c0 ! DOUBLE_W
			b $4d
			b "Blinkfrequenz:",NULL

:R5T07			b "DIALOGBOX",NULL

:R5T08			w $00c0 ! DOUBLE_W
			b $76
			b "Dialogboxen"
			b GOTOXY
			w $00c0 ! DOUBLE_W
			b $7e
			b "in Farbe:",NULL

:R5T09			b "MAUS / JOYSTICK",NULL

:R5T10			w $0020 ! DOUBLE_W
			b $9c
			b "Name:",NULL
;:R5T11			w $0020 ! DOUBLE_W
;			b $ab
;			b "(Wird beim Booten automatisch installiert)",NULL
:R5T12			b "TASTATUR",NULL
:R5T13			w $00c0 ! DOUBLE_W
			b $9c
			b "QWERTZ"
			b GOTOXY
			w $00c0 ! DOUBLE_W
			b $a6
			b "Tastatur:",NULL

endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
if Sprache = Englisch
:R5T01			b "GEOS-MENU",NULL

:R5T02			w $0020 ! DOUBLE_W
			b $4e
			b "Invert entry:",NULL

:R5T03			w $0020 ! DOUBLE_W
			b $5e
			b "Menu/Icon mode:",NULL

:R5T04			w $0020 ! DOUBLE_W
			b $6e
			b "Insert lines:",NULL

:R5T04a			w $0020 ! DOUBLE_W
			b $7e
			b "Stop at bottom:",NULL

:R5T05			b "CURSOR",NULL
:R5T06			w $00c0 ! DOUBLE_W
			b $4d
			b "Flashfrequency:",NULL

:R5T07			b "DIALOGBOX",NULL

:R5T08			w $00c0 ! DOUBLE_W
			b $76
			b "Set color in"
			b GOTOXY
			w $00c0 ! DOUBLE_W
			b $7e
			b "dialogbox:",NULL

:R5T09			b "CURRENT INPUTDRIVER",NULL

:R5T10			w $0020 ! DOUBLE_W
			b $9e
			b "Name:",NULL
:R5T11			w $0020 ! DOUBLE_W
			b $ab
			b "(Becomes automatically installed at bootup)",NULL
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "DRUCKER".
:RegTMenu_6
if Flag64_128 = TRUE_C64
			b 9
endif

if Flag64_128 = TRUE_C128
			b 7
endif

			b BOX_FRAME			;----------------------------------------
				w R6T01
				w $0000
				b $40,$67
				w $0018!DOUBLE_W,$0127!DOUBLE_W!ADD1_W
			b BOX_STRING			;----------------------------------------
				w R6T02
				w GetPrntDrvFile
				b $48
				w $0048!DOUBLE_W
				w PrntFileName
				b 16
			b BOX_ICON			;----------------------------------------
				w $0000
				w GetNewPrinter
				b $48
				w $00c8!DOUBLE_W
				w RegTIcon1_1_01
				b $02

if Flag64_128 = TRUE_C64
			b BOX_OPTION			;----------------------------------------
				w R6T03
				w SwapPrntRAM
				b $58
				w $0020!DOUBLE_W
				w Flag_LoadPrnt
				b %10000000

;--- Ergänzung: 31.12.18/M.Kanet
;Die Option reduziert die erlaubte Größe von Druckertreibern im RAM/Spooler
;um 1Byte da GeoCalc ab $7F3F Programmcode nutzt. Dieses Byte ist aber noch
;für Druckertreiber reserviert.
:RegTMenu_6a		b BOX_OPTION			;----------------------------------------
				w R6T03a
				w InitGCalcFix
				b $58
				w $0118!DOUBLE_W
				w BootGCalcFix
				b %10000000
endif

			b BOX_FRAME			;----------------------------------------
				w R6T04
				w $0000
				b $70,$af
				w $0018!DOUBLE_W,$0127!DOUBLE_W!ADD1_W
			b BOX_OPTION			;----------------------------------------
				w R6T05
				w SwapSpooler
				b $78
				w $0020!DOUBLE_W
				w BootSpooler
				b %10000000
			b BOX_USER			;----------------------------------------
				w $0000
				w Swap_SpoolDelay
				b $98,$9f
				w $0023!DOUBLE_W,$00bf!DOUBLE_W!ADD1_W
			b BOX_OPTION			;----------------------------------------
				w R6T08
				w SwapSplAuto
				b $88
				w $0020!DOUBLE_W
				w Flag_SpoolCount
				b %10000000

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
if Sprache = Deutsch
:R6T01			b "AKTIVER DRUCKER",NULL

:R6T02			w $0020 ! DOUBLE_W
			b $4e
			b "Name:",NULL
:R6T03			w $0030 ! DOUBLE_W
			b $5e
			b "Treiber von Disk laden",NULL
:R6T03a			w $00d0 ! DOUBLE_W
			b $5e
			b "GeoCalc-Fix",NULL

:R6T04			b "DRUCKERSPOOLER",NULL

:R6T05			w $0030 ! DOUBLE_W
			b $7e
			b "Spooler zum Drucken verwenden",NULL

:R6T07			b GOTOXY
			w $00c8 ! DOUBLE_W
			b $9e
			b "( 00:00 MIN. ) "
			b GOTOXY
			w $0020 ! DOUBLE_W
			b $a6
			b "<->"
			b GOTOX
			w $0049 ! DOUBLE_W
			b "00:30"
			b GOTOX
			w $0078 ! DOUBLE_W
			b "01:00"
			b GOTOX
			w $00b6 ! DOUBLE_W
			b "<+>"
			b NULL

:R6T08			w $0030 ! DOUBLE_W
			b $8e
			b "Spooler über TaskManager starten",NULL
endif

if Sprache = Englisch
:R6T01			b "CURRENT PRINTER",NULL

:R6T02			w $0020 ! DOUBLE_W
			b $4e
			b "Name:",NULL
:R6T03			w $0030 ! DOUBLE_W
			b $5e
			b "Load driver from disk",NULL
:R6T03a			w $00d0 ! DOUBLE_W
			b $5e
			b "GeoCalc-Fix",NULL

:R6T04			b "PRINTSPOOLER",NULL

:R6T05			w $0030 ! DOUBLE_W
			b $7e
			b "Use spooler for printing",NULL

:R6T07			b GOTOXY
			w $00c8 ! DOUBLE_W
			b $9e
			b "( 00:00 MIN. ) "
			b GOTOXY
			w $0020 ! DOUBLE_W
			b $a6
			b "<->"
			b GOTOX
			w $0049 ! DOUBLE_W
			b "00:30"
			b GOTOX
			w $0078 ! DOUBLE_W
			b "01:00"
			b GOTOX
			w $00b6 ! DOUBLE_W
			b "<+>"
			b NULL

:R6T08			w $0030 ! DOUBLE_W
			b $8e
			b "Start spooler over the TaskManager",NULL
endif

:RegTIcon1_6_01		w Icon_10
			b %01000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_10x ! DOUBLE_B
			b Icon_10y
			b USE_COLOR_INPUT		;Farbe für Icon.

;******************************************************************************
;*** Icons.
;******************************************************************************
;*** System-Icons.
:Icon_01
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
:Icon_02
<MISSING_IMAGE_DATA>

:Icon_03
<MISSING_IMAGE_DATA>

endif

if Sprache = Englisch
:Icon_02
<MISSING_IMAGE_DATA>

:Icon_03
<MISSING_IMAGE_DATA>
endif

;*** Icons für Delay-Anzeige.
:Icon_05
<MISSING_IMAGE_DATA>
:Icon_05x		= .x
:Icon_05y		= .y

:Icon_06
<MISSING_IMAGE_DATA>
:Icon_06x		= .x
:Icon_06y		= .y

:Icon_07
<MISSING_IMAGE_DATA>
:Icon_07x		= .x
:Icon_07y		= .y

:Icon_08
<MISSING_IMAGE_DATA>
:Icon_08x		= .x
:Icon_08y		= .y

;*** Auswahl-Icons.
:Icon_09
<MISSING_IMAGE_DATA>
:Icon_09x		= .x
:Icon_09y		= .y

:Icon_10
<MISSING_IMAGE_DATA>
:Icon_10x		= .x
:Icon_10y		= .y

:Icon_11
<MISSING_IMAGE_DATA>
:Icon_11x		= .x
:Icon_11y		= .y

;******************************************************************************
;*** Icons.
;******************************************************************************
;*** System-Icons.
if Sprache = Deutsch
:Icon_20
<MISSING_IMAGE_DATA>
:Icon_20x		= .x
:Icon_20y		= .y

:Icon_21
<MISSING_IMAGE_DATA>
:Icon_21x		= .x
:Icon_21y		= .y

:Icon_22
<MISSING_IMAGE_DATA>
:Icon_22x		= .x
:Icon_22y		= .y

:Icon_23
<MISSING_IMAGE_DATA>
:Icon_23x		= .x
:Icon_23y		= .y

:Icon_24
<MISSING_IMAGE_DATA>
:Icon_24x		= .x
:Icon_24y		= .y

:Icon_25
<MISSING_IMAGE_DATA>
:Icon_25x		= .x
:Icon_25y		= .y
endif

if Sprache = Englisch
:Icon_20
<MISSING_IMAGE_DATA>
:Icon_20x		= .x
:Icon_20y		= .y

:Icon_21
<MISSING_IMAGE_DATA>
:Icon_21x		= .x
:Icon_21y		= .y

:Icon_22
<MISSING_IMAGE_DATA>
:Icon_22x		= .x
:Icon_22y		= .y

:Icon_23
<MISSING_IMAGE_DATA>
:Icon_23x		= .x
:Icon_23y		= .y

:Icon_24
<MISSING_IMAGE_DATA>
:Icon_24x		= .x
:Icon_24y		= .y

:Icon_25
<MISSING_IMAGE_DATA>
:Icon_25x		= .x
:Icon_25y		= .y
endif

;*** X-Koordinate der Register-Icons.
:RegCardIconX_1		= $02 ! DOUBLE_B
:RegCardIconX_2		= RegCardIconX_1 + Icon_20x
:RegCardIconX_3		= RegCardIconX_2 + Icon_21x
:RegCardIconX_4		= RegCardIconX_3 + Icon_23x
:RegCardIconX_5		= RegCardIconX_4 + Icon_22x
:RegCardIconX_6		= RegCardIconX_5 + Icon_25x

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_REGISTER
;******************************************************************************
