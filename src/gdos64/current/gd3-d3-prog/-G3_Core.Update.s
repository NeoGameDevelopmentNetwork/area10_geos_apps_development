; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;Dieses Programm installiert GDOS im laufenden GEOS-System.
;Wird das Programm über das Setup gestartet, so wird im Anschluß die
;Konfiguration gespeichert und die Diskette bootfähig gemacht.
;Wichtig: Das Programm ermittelt die Größe des verfügbaren Speichers
;         automatisch. Ist eine 2Mb-REU angeschlossen, aber das aktuelle
;         GEOS verwendet nur 1Mb, dann darf während des Updates nicht mehr
;         als 1Mb Speicher für GDOS bereitgestellt werden.
;         Der andere Speicher oberhalb des für GEOS verfügbaren Speichers
;         könnte durch eine andere Anwendung (evtl. BASIC) belegt sein!!!
;         Der volle Speicher wird erst beim GEOS-Neustart über BASIC
;         für GDOS freigegeben!!!
;******************************************************************************

;*** Bildschirm-Ausgabe initialisieren.
:MainInit		lda	SerialNumber +0		;Seriennummer des laufenden
			sta	SerialBuffer +0		;GEOS-System einlesen.
			lda	SerialNumber +1
			sta	SerialBuffer +1

			jsr	TestGDINI		;GD.INI-Datei suchen/erstellen.

			jsr	ClrScreen		;Bildschirm löschen.

			jsr	i_FillRam
			w	40 * 2
			w	COLOR_MATRIX +40 * 0
			b	COLOR_UPD_INFO

			jsr	i_FillRam
			w	40 * 19
			w	COLOR_MATRIX +40 * 2
			b	$00

			jsr	i_FillRam
			w	40 * 4
			w	COLOR_MATRIX +40 * 21
			b	COLOR_UPD_INFO

			LoadW	r0,Strg_Welcome		;Titelbildschirm anzeigen.
			jsr	PutString

			lda	#$01
			jsr	SetPattern
			jsr	i_Rectangle
			b	$10,$a7
			w	$0000,$013f

			jsr	DlgBoxColor		;Farben für Dialogbox setzen.

			LoadW	r0,Strg_Welcome2	;"Initialisierung...".
			jsr	PutString

;--- Dialogbox-Routine korrigieren.
			lda	RecoverVector +0
			sta	RecoverVecBuf +0
			lda	RecoverVector +1
			sta	RecoverVecBuf +1

			lda	#< ClrDlgBoxArea
			sta	RecoverVector +0
			lda	#> ClrDlgBoxArea
			sta	RecoverVector +1

;--- Update initialisieren.
			lda	curDrive		;Startlaufwerk einlesen und
			sta	Device_Boot		;zwischenspeichern.

			jsr	GetUpdateConfig		;Benutzerkonfiguration einlesen.

;------------------------------------------------------------------------------
; DRIVECORE
;
;Vor dem Aufruf der Geräte-Erkennuns-
;routine darf auf dem aktiven Laufwerk
;das TurboDOS nicht mehr aktiv sein!
;
			jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	_SER_GETALLDRV		;Alle Laufwerke erkennen.
;------------------------------------------------------------------------------

			jsr	GetPAL_NTSC		;PAL/NTSC-Flag aktualisieren.

			jsr	OpenBootDrive		;Boot-Laufwerk aktivieren.

			jsr	GetRandom		;Zufallszahl ermitteln. Wird später
							;zur Erkennung des DACC benötigt.

			ldx	#$02			;Aktuelles Datum zwischenspeichern.
::11			lda	year      ,x
			sta	DateBuffer,x
			dex
			bpl	:11

;--- RAMLink/SuperCPU erkennen.
			sei				;IRQ sperren.
			cld				;Dezimal-Flag löschen.
			ldx	#$ff			;Stack-Pointer löschen.
			txs

			jsr	CheckSCPU		;SuperCPU erkennen.
			jsr	CheckRLNK		;RAMLink erkennen.

;--- Erkennen der Speichererweiterung initialisieren.
			ldx	CPU_DATA		;RAM-Konfiguration retten.

			lda	#KRNL_IO_IN		;I/O und Kernal einblenden.
			sta	CPU_DATA

			ldy	#$0f			;Prüfsumme für Suche nach der
::21			tya				;Speichererweiterung definieren.
			eor	random +0		;Achtung! Unbedingt bei jedem
			eor	$d012			;Start neu und zufällig definieren!
			sta	RAM_TEST_CODE,y
			lda	random +1
			eor	$d012
			eor	RAM_TEST_CODE,y
			sta	RAM_TEST_CODE,y
			dey
			bpl	:21

			stx	CPU_DATA		;RAM-Konfiguration zurücksetzen.

;--- Hiwneis:
;Für die RAM-Erkennung wird hier der
;Testbereich in der REU mit einer
;Kennung versehen. Sind mehrere REU
;vorhanden, dann kann so die aktive
;REU erkannt werden.
			jsr	FetchRAM_TestBuf	;Original-Inhalt sichern.

			LoadW	r0 ,RAM_TEST_CODE
			jsr	StashRAM		;Testcode speichern.

			jsr	FindActiveDACC		;Speichererweiterung feststellen.
			txa				;Ergebnis der DACC-Suche
			pha				;zwischenspeichern.

			jsr	StashRAM_TestBuf	;Original-Inhalt zurückschreiben.

			pla				;DACC-Fehler ?
			beq	:22			; => Nein, weiter...
			jmp	ExitUpdate		; => Nein, zurück zum DeskTop.

::22			ldy	#0
::23			lda	ExtRAM_Type,y
			sta	UserRAMData,y
			iny
			cpy	#5
			bne	:23

			jsr	PrintActiveDACC		;Daten zu GEOS-DACC anzeigen.

			jsr	CheckSizeRAM		;Genügend erweiterter Speicher für
							;RAM-Laufwerke verfügbar ?

			ldx	ExtRAM_Size		;Speicherbank für GDOS-Kernal
			dex				;definieren.
			stx	InstallBank64K

			jsr	resetSCPU_RAM		;SuperCPU-RAMLaufwerk freigeben.

			jsr	RetainInpDev		;Eingabetreiber beibehalten ?
			jsr	ClrConfigInput		;Eingabetreiber in GD.INI löschen.

;--- Update initialisieren.
			jsr	ClrScreen		;Bildschirm löschen.

			LoadW	r0,Strg_Welcome		;Titelbildschirm anzeigen.
			jsr	PutString
			LoadW	r0,Strg_Init		;Bildschirm löschen.
			jsr	PutString

;--- Laufwerkstreiber laden.
			jsr	OpenBootDrive		;Startlaufwerk aktivieren.

			jsr	LoadSysDiskDev		;Laufwerkstreiber aktualisieren.

			jsr	LoadSysBootData		;Datei "GD.BOOT" nachladen.
							;Diese Datei enthält die Daten für
							;ReBoot und die Installationsdaten
							;für den ext. GDOS-Kernal.

			jsr	PurgeTurbo		;TurboDOS entfernen.

;--- GEOS-Kernal installieren.
			LoadW	r0,Strg_Kernal		;"GEOS-Kernal wird geladen...".
			jsr	PutString

			ldy	#$03			;Laufwerksinformationen in
::31			lda	driveType     ,y	;Zwischenspeicher retten, da
			sta	driveType_buf ,y	;während des Updatevorgangs der
			lda	ramBase       ,y	;Speicher von $8000-$8FFF komplett
			sta	ramBase_buf   ,y	;gelöscht wird.
			lda	driveData     ,y
			sta	driveData_buf ,y
			lda	doubleSideFlg ,y
			sta	doubleSide_buf,y
;			lda	turboFlags    ,y
;			sta	turboFlags_buf,y
			dey
			bpl	:31

;--- Installation GEOS-Kernal:
;GEOS-Kernal mit dem aktiven Laufwerks-
;treiber nachladen und installieren.
;Dadurch wird auch der Laufwerkstreiber
;vom GDOS-System im System eingebunden.
;Ab hier ist kein passender RAM-Treiber
;aktiv, daher kein GEOS-":DoRAMOp" bis
;DACC initialisiert ist!
			jsr	LoadSys_GEOS		;GEOS-Kernal laden.
			jsr	InitSys_GEOS		;(64K RAM)

			lda	SerialBuffer +0		;Seriennummer des vorherigen
			sta	SerialNumber +0		;GEOS-Systems übernehmen.
			lda	SerialBuffer +1
			sta	SerialNumber +1

			ldy	#$03			;Laufwerksinformationen wieder
::32			lda	driveType_buf ,y	;zurückschreiben.
			sta	driveType     ,y
			lda	ramBase_buf   ,y
			sta	ramBase       ,y
			lda	driveData_buf ,y
			sta	driveData     ,y
			lda	doubleSide_buf,y
			sta	doubleSideFlg ,y
			lda	#$00
;			lda	turboFlags_buf,y
			sta	turboFlags    ,y
			dey
			bpl	:32

;--- RAM-Treiber initialisieren.
			LoadW	r0,Strg_Device		;"Treiber werden installiert...".
			jsr	PutString

			jsr	InitSys_SetDACC		;DACC-Informationen setzen.

			jsr	InitDeviceRAM		;RAM-Patches installieren.
			txa				;Speichertest OK?
			beq	:41			; => Ja, weiter...
			jmp	Err_RamVerErr		;Fehler ausgeben, Ende.

::41			jsr	InitDeviceSCPU		;SuperCPU patchen.

;--- Laufwerkstreiber in REU sichern.
;Ab hier kann wieder GEOS-":DoRAMOp"
;verwendet werden, da der RAM-Treiber
;installiert ist.
			lda	#%01110000		;Kein MoveData, DiskDriver in REU,
			sta	sysRAMFlg		;ReBoot-Kernal in REU.

			ldy	Device_Boot		;Aktuelles Laufwerk zurücksetzen.
			sty	curDrive
			sty	curDevice
			lda	driveType -8,y
			sta	curType

			jsr	InitCurDskDvJob		;StashRAM erst nachdem der neue
			jsr	StashRAM		;RAM-Treiber installiert wurde!
			jsr	DoneWithDskDvJob

			lda	#$00			;RAMLink-Adresse zurücksetzen.
			sta	sysRAMLink

;--- GDOS-Kernal installieren.
;":LoadSys_GDOS" lädt den GDOS-Kernal
;über die GEOS-Routinen nach. Dazu muss
;aber der neue Laufwerkstreiber bereits
;in der REU gespeichert worden sein, da
;hier auch ":SetDevice" verwendet wird.
			LoadW	r0,Strg_GDOS		;"GDOS-Kernal installieren...".
			jsr	PutString

			jsr	LoadSys_GDOS		;GDOS-Kernal laden.
			jsr	InitSys_GDOS		;(GDOS-Speicherbank + RBOOT)

;--- GEOS-Initialisierung.
			lda	#$ff			;TaskSwitcher deaktivieren (da noch
			sta	Flag_TaskAktiv		;nicht installiert... Erst über
							;GD.CONFIG!!!)
			jsr	FirstInit		;GDOS-Kernal initialisieren.
			jsr	SCPU_OptOn		;SCPU aktivieren (auch wenn keine
							;SCPU verfügbar ist!)

			jsr	UseSystemFont		;GEOS-Font aktivieren.

			lda	#$08			;Sektor-Interleave #8.
			sta	interleave

			ldx	#$02			;Aktuelles Datum zwischenspeichern.
::42			lda	DateBuffer,x
			sta	year      ,x
			dex
			bpl	:42

			jsr	OpenBootDrive		;Startlaufwerk öffnen.

;--- Ergänzung: 24.03.21/M.Kanet
;Bei 1571 auf Doppelseitig umschalten.
			ldx	curDrive
			lda	driveType -8,x		;RAM-Laufwerk ?
			bmi	:43
			lda	_PRG_DEVTYPE -8,x
			cmp	#Drv1571		;1571-Laufwerk ?
			bne	:43			; => Nein, weiter...
			lda	doubleSideFlg -8,x
			jsr	Set1571DkMode		;1571-Laufwerksmodus festlegen.

::43			ldx	curDrive
			ldy	UserPConfig -8,x	;Partition für CMD-Laufwerk.
			beq	:43a			; => Nicht deiniert, weiter...

			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_PARTITION
			bne	:43b

::43a			ldy	#< OpenDisk		;CBM-Laufwerke: Diskette öffnen.
			ldx	#> OpenDisk
			bne	:44

::43b			sty	r3H			;CMD-Partition festlegen.

			ldy	#< OpenPartition	;CMD-Laufwerke: Partition öffnen.
			ldx	#> OpenPartition

::44			tya
			jsr	CallRoutine		;OpenDisk / OpenPartition.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...

;--- Standard-Gerätetreiber laden.
;Wird durch GD.CONFIG ausgeführt.
;Der Kernal beinhaltet standardmäßig
;den Mouse1351-Treiber.
;			jsr	LoadDev_Printer		;Druckertreiber laden.
;			jsr	LoadDev_Mouse		;Eingabetreiber laden.

;--- Maustreiber initialisieren.
			jsr	InitMouse		;Treiber im Speicher initialisieren.

;--- Routine nachladen, welche GD.CONFIG initialisiert und die
;    Laufwerke installiert.
			jsr	i_MoveData
			w	obj_Updater
			w	BASE_AUTO_BOOT
			w	(end_Updater - obj_Updater)

			jmp	BASE_AUTO_BOOT		;AutoBoot ausführen.

::err			jmp	Err_DiskError		;Fehlermeldung ausgeben.

;*** SuperCPU-RAMLaufwerk freigeben.
:resetSCPU_RAM		lda	Device_SCPU		;SCPU verfügbar ?
			beq	:exit			; => Nein, weiter...

			ldx	#0
::1			lda	UserConfig,x		;Laufwerksmodus einlesen.
			cmp	#DrvRAMNM_SCPU		;Typ SuperRAM-Laufwerk ?
			beq	:found			; => Ja, weiter...
			inx				;Nächstes Laufwerk testen.
			cpx	#4			;Alle Laufwerke getestet ?
			bcc	:1			; => Nein, weiter...
::exit			rts				;Kein SuperRAM-Laufwerk.

::found			lda	CPU_DATA
			pha
			lda	#KRNL_BAS_IO_IN		;Standard-RAM-Bereiche einblenden.
			sta	CPU_DATA

			sta	SCPU_HW_EN		;SuperCPU-Register aktivieren.

			lda	#$00			;Erste freie Speicherbank auf
			sta	SRAM_FIRST_PAGE		;erste Speicherbank des SuperRAM-
			lda	UserRamBase,x		;Laufwerks zurücksetzen.
			sta	SRAM_FIRST_BANK

			sta	SCPU_HW_DIS		;SuperCPU-Register deaktivieren.

			pla				;GEOS-RAM-Bereich wieder einblenden.
			sta	CPU_DATA

			rts

;*** REU-Inhalt sichern/zurücksetzen.
:FetchRAM_TestBuf	ldy	#jobFetch
			b $2c
:StashRAM_TestBuf	ldy	#jobStash

			lda	#< RAM_TEST_BUF		;Zwischenspeicher.
			sta	r0L
			lda	#> RAM_TEST_BUF
			sta	r0H

			ldx	#$00			;REU-Speicher.
			stx	r1L
			stx	r1H

			lda	#$10			;Größe Testcode.
			sta	r2L
			stx	r2H

;			ldx	#$00			;Durch ":setDataTestBuf" gesetzt.
			stx	r3L			;Erste 64K-Speicherbank.

			jmp	DoRAMOp			;FetchRAM/StashRAM.

;*** Zurück zum DeskTop.
;--- Ergänzung: 07.02.21/M.Kanet
;Startlaufwerk wieder aktivieren. Bei GEOSv2 kann sonst der DeskTop
;nicht gefunden werden, wenn zuletzt auf Laufwerk #10/#11 zugegriffen wurde.
:ExitUpdate		lda	RecoverVecBuf +0
			sta	RecoverVector +0
			lda	RecoverVecBuf +1
			sta	RecoverVector +1

			jsr	OpenBootDrive		;Startlaufwerk öffnen.
			jsr	OpenDisk		;Diskette öffnen.

;--- Ergänzung: 07.02.21/M.Kanet
;GEOSv2 löscht bei der Rückkehr zum DeskTop die Farben des
;GDOS-Setup nicht automatisch. Zusätzlich Bildschirminhalt löschen.
			jsr	StdScreen		;Grafik-Bildschirm zurücksetzen.

::exit			jmp	EnterDeskTop		;Zurück zum DeskTop.

;*** Startlaufwerk öffnen.
:OpenBootDrive		lda	Device_Boot		;Start-Laufwerk aktivieren.
			jsr	SetDevice
			jmp	PurgeTurbo		;TurboDOS entfernen.

;*** Bildschirm zurücksetzen.
:ClrScreen		lda	#$00
			b $2c
:StdScreen		lda	#$02
			jsr	SetPattern

			lda	#ST_WR_FORE
			sta	dispBufferOn

			LoadW	r0,40*25
			LoadW	r1,COLOR_MATRIX
			lda	screencolors
			sta	r2L
			jsr	FillRam

			jsr	i_Rectangle
			b	$00,$c7
			w	$0000,$013f

			rts

;*** Datei "GD.BOOT" nachladen.
;    Diese Datei enthält wichtige Teile für die Installation!
;    Die Startadresse von "GD.BOOT" überschreibt die max. Endadresse
;    dieses Installationsprogramms. Deshalb wird die Datei zuerst an eine
;    freie Stelle im RAM geladen und anschließend nur die benötigten
;    Programmteile an die korrekte Speicheradresse zurückgeschrieben.
;    Benötigter Bereich: 'S_KernalData' bis 'E_KernalData'.
:LoadSysBootData	lda	#< FNamGBOOT		;Systemdatei suchen.
			ldx	#> FNamGBOOT
			jsr	LoadSysFile_Init

;--- Bytes bis Systemdaten überlesen.
			LoadW	r4,diskBlkBuf
			LoadW	r5,$0000
			LoadW	r15,(S_KernalData - L_KernalData)
::51			jsr	ReadByte
			txa
			bne	:54

			ldx	#r15L
			jsr	Ddec
			bne	:51

;--- Systemdaten einlesen.
			LoadW	r14,S_KernalData
			LoadW	r15,(E_KernalData - S_KernalData)
::52			jsr	ReadByte
			cpx	#NO_ERROR
			bne	:54

			ldy	#$00
			sta	(r14L),y

			inc	r14L
			bne	:53
			inc	r14H
::53			ldx	#r15L
			jsr	Ddec
			bne	:52
			rts

::54			jmp	Err_DiskError

;*** GD.GEOS.1 nachladen.
:LoadSys_GEOS		lda	#< FNamGEOS1		;Datei "GEOS64.1" nachladen.
			ldx	#> FNamGEOS1
			jsr	LoadSysFile_Init

			LoadW	r7,BASE_GEOS_SYS -2 +DISK_DRIVER_SIZE
			LoadW	r2,(OS_BASE - BASE_GEOS_SYS)
			jsr	ReadFile		;Datei von Diskette laden.
			txa				;Diskettenfehler ?
			bne	Err_DiskError		; => Nein, weiter...

			jsr	PurgeTurbo		;TurboDOS entfernen.

;--- Neuen Treiber installieren.
;Der Laufwerksreiber wird durch die
;Routine ":LoadSysDiskDev" in der REU
;ab $0000 temporär zwischengespeichert.
			LoadW	r0,BASE_GEOS_SYS
			LoadW	r1,$0000
			LoadW	r2,DISK_DRIVER_SIZE
			LoadB	r3L,$00
			jsr	FetchRAM		;Laufwerkstreiber übernehmen.

			rts				;GD.GEOS.1 geladen, Ende...

;*** GD.GEOS.2 nachladen.
:LoadSys_GDOS		lda	#< FNamGEOS2		;Datei "GEOS64.2" nachladen.
			ldx	#> FNamGEOS2
			jsr	LoadSysFile_Init

			LoadW	r7,BASE_GEOS_SYS -2

			LoadW	r2,(OS_BASE - BASE_GEOS_SYS)
			jsr	ReadFile		;Datei von Diskette laden.
			txa				;Diskettenfehler ?
			bne	Err_DiskError		; => Nein, weiter...

			jsr	PurgeTurbo		;TurboDOS entfernen.

			rts				;GD.GEOS.2 geladen, Ende...

;*** Systemdatei suchen.
:LoadSysFile_Init	sta	r6L
			stx	r6H
			sta	VecFileName +0
			stx	VecFileName +1
			lda	Device_Boot		;Start-Laufwerk aktivieren.
			jsr	SetDevice
			txa				;Laufwerksfehler ?
			bne	Err_DiskError		; => Ja, Abbruch...
			jsr	OpenDisk		;Diskette öffnen und
			txa				;Diskettenfehler ?
			bne	Err_DiskError		; => Ja, Abbruch...

			jsr	FindFile		;Datei auf Diskette suchen.
			txa				;Diskettenfehler ?
			beq	:51			; => Nein, weiter...
			cpx	#FILE_NOT_FOUND		;Datei nicht gefunden ?
			beq	Err_FNotFound		;"Datei nicht gefunden".
			bne	Err_DiskError		;"Diskettenfehler".
::51			lda	dirEntryBuf +1		;Zeiger auf ersten Sektor der
			sta	r1L			;Datei setzen.
			lda	dirEntryBuf +2
			sta	r1H
			rts

;*** Fehler: Diskettenfehler.
:Err_DiskError		stx	DskErrCode
			LoadW	r0,Dlg_DiskError
			jmp	DoDlgBox

;*** Fehlercode ausgeben.
:PrntDskErrCode		LoadB	r1H,$56
			LoadW	r11,$0060
			lda	#"-"
			jsr	SmallPutChar

			lda	DskErrCode
			sta	r0L
			lda	#$00
			sta	r0H
			lda	#%11000000
			jsr	PutDecimal

			lda	#"-"
			jmp	SmallPutChar

;*** Fehler: Datei nicht gefunden.
:Err_FNotFound		MoveW	VecFileName,r9
			LoadW	r0,Dlg_FNotFound
			jmp	DoDlgBox

;*** Fehler, zurück zum BASIC.
:Err_RamVerErr		LoadW	r0,Dlg_RamVerError
			jmp	DoDlgBox

;*** Dialogbox-Hintergrund löschen.
:ClrDlgBoxArea		lda	#$01
			jsr	SetPattern
			jmp	Rectangle

;*** Kernal-Teil #1 installieren.
;    Programmcode liegt ab ":BASE_GEOS_SYS" im Speicher und wird
;    nach $9000-$9C7F und $BF40-$FFFF kopiert.
:InitSys_GEOS		jsr	OpenBootDrive		;Startlaufwerk öffnen.

			sei
			lda	#RAM_64K		;64K-RAM-Bereich einblenden.
			sta	CPU_DATA

			LoadW	$0314,NewIRQ		;IRQ-Routine abschalten.
			LoadW	$0316,NewNMI		;NMI-Routine abschalten.

;--- Ergänzung!!!
			LoadW	$fffa,NewNMI		;NMI/Reset-Vektor auf RAM verbiegen,
			LoadW	$fffc,NewNMI		;falls NMI während kopieren des
							;neuen Kernals auftritt (alte NMI-
							;Routine wird ja überschrieben!)

;--- GEOS-Variablenspeicher löschen.
			lda	screencolors		;Bildschirmfarbe speichern.
			pha

			jsr	InitSys_ClrVar		;GEOS-Variablen löschen.

			pla
			jsr	InitSys_ClrCol		;Farb-RAM löschen.

			LoadW	r0,BASE_GEOS_SYS
			jsr	CopySys_DISK		;Laufwerkstreiber installieren.

			LoadW	r0,BASE_GEOS_SYS + DISK_DRIVER_SIZE
			jsr	CopySys_GEOS		;GEOS-Kernal installieren.

;--- Ergänzung: 10.07.21/M.Kanet
;Bei der Installation des GEOS-Kernals
;kann der Zeichensatz an einer anderen
;Stelle im Speicher liegen. Daher muss
;":UseSystemFont" aufgerufen werden!
			jsr	UseSystemFont		;Neuen Zeichensatz aktivieren.
			rts

;*** Neue IRQ/NMI-Routine.
:NewIRQ			pla
			tay
			pla
			tax
			pla
:NewNMI			rti

;*** Kernal-Teil #2 installieren,ReBoot-Routine in REU kopieren.
;    Programmcode liegt ab ":BASE_GEOS_SYS" im Speicher und wird
;    in die Speicherbank #1 kopiert.
;--- Ausgelagerte Kernal-Funktionen in RAM kopieren.
:InitSys_GDOS		jsr	CopySys_GDOS		;GDOS-Kernal installieren.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			jsr	CopySys_RBOOT		;RBOOT-Routine installieren.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			rts				;Ende...

::err			jmp	Err_RamVerErr

;*** Variablen.
:Device_Boot		b $00
:DevAdr_RL		b $00
:SerialBuffer		w $0000
:DateBuffer		s $03
:RecoverVecBuf		w $0000
:DskErrCode		b $00
:VecFileName		w $0000

;*** Bank für GDOS.
:InstallBank64K		b $00

;*** Angaben zur Speichererweiterung.
:ExtRAM_Type		b $00				;$00 = keine RAM-Erweiterung.
							;$80 = RAMLink / RAMDrive.
							;$40 = Commodore REU.
							;$20 = BBG/GEORAM.
							;$10 = SuperCPU/RAMCard.
:ExtRAM_Size		b $00				;Anzahl 64K-Bänke.
:ExtRAM_Bank		w $0000
:ExtRAM_Part		b $00

;*** Dateinamen für Systemdateien.
:FNamGBOOT		b "GD.BOOT",NULL
:FNamGEOS1		b "GD.BOOT.1",NULL
:FNamGEOS2		b "GD.BOOT.2",NULL
:FNamGDINI		b "GD.INI",NULL
:FNamGDUPD		b "GD.UPDATE",NULL

;*** Zwischenspeicher Laufwerksdaten.
:driveType_buf		s $04
:driveData_buf		s $04
:ramBase_buf		s $04
:doubleSide_buf		s $04
;:turboFlags_buf	s $04

;*** Zeiger auf Laufwerkstreiber in RAM.
:VecToDskDvPos		w R1A_DSKDEV_A
			w R1A_DSKDEV_B
			w R1A_DSKDEV_C
			w R1A_DSKDEV_D

;*** "Willkommen"-Bildschirm.
:Strg_Welcome		b GOTOXY
			w $0010
			b $0b
			b PLAINTEXT,BOLDON

if LANG = LANG_DE
			b "Willkommen zum GEOS-Update `GDOS64`",NULL
endif
if LANG = LANG_EN
			b "Welcome to the GEOS update `GDOS64`",NULL
endif

:Strg_Welcome2		b GOTOXY
			w $0010
			b $b4

if LANG = LANG_DE
			b "Initialisierung...",NULL
endif
if LANG = LANG_EN
			b "Initializing...",NULL
endif

;*** "Initialisierung"-Bildschirm.
:Strg_Init		b GOTOXY
			w $0010
			b $1a
			b PLAINTEXT

if LANG = LANG_DE
			b "System wird konfiguriert....",NULL
endif
if LANG = LANG_EN
			b "Preparing system...",NULL
endif

;*** "GEOS-Kernal"-Bildschirm.
:Strg_Kernal		b GOTOXY
			w $0010
			b $28
			b PLAINTEXT

if LANG = LANG_DE
			b "GEOS-Kernal wird installiert...",NULL
endif
if LANG = LANG_EN
			b "Installing GEOS kernal...",NULL
endif

;*** "Gerätetreiber"-Bildschirm.
:Strg_Device		b GOTOXY
			w $0010
			b $36
			b PLAINTEXT

if LANG = LANG_DE
			b "Gerätetreiber für GEOS werden installiert...",NULL
endif
if LANG = LANG_EN
			b "Installing GEOS drivers...",NULL
endif

;*** "GDOS64"-Bildschirm.
:Strg_GDOS		b GOTOXY
			w $0010
			b $44
			b PLAINTEXT

if LANG = LANG_DE
			b "GDOS64-Kernal wird installiert...",NULL
endif
if LANG = LANG_EN
			b "Installing GDOS64 kernal...",NULL
endif

;*** Dialogbox: Fehler beim installieren des GEOS/GDOS-Kernals.
:Dlg_RamVerError	b %00000000
			b $20,$97
			w $0010,$012f

			b DB_USR_ROUT
			w SysErrColor
			b DBTXTSTR ,$0c,$10
			w Dlg_SysError
			b DBTXTSTR ,$0c,$1c
			w :t1
			b DBTXTSTR ,$0c,$26
			w :t2
			b DBTXTSTR ,$0c,$30
			w :t3
			b DBTXTSTR ,$0c,$3a
			w :t4
			b DBTXTSTR ,$0c,$4a
			w Dlg_RBootGEOS1
			b DBTXTSTR ,$0c,$54
			w Dlg_RBootGEOS2
			b NULL

if LANG = LANG_DE
::t1			b "Die Installation ist fehlgeschlagen. Der GDOS64-",NULL
::t2			b "Kernal konnte nicht in der Speichererweiterung",NULL
::t3			b "installiert werden!",NULL
::t4			b "Bitte die Speichererweiterung auf Fehler prüfen!",NULL
endif

if LANG = LANG_EN
::t1			b "Installation has failed. The current GDOS64 kernal",NULL
::t2			b "could not be installed in the currently active",NULL
::t3			b "GEOS ram expansion unit!",NULL
::t4			b "Please check your ram expansion for errors!",NULL
endif

;*** Dialogbox: Diskettenfehler.
:Dlg_DiskError		b %00000000
			b $20,$97
			w $0010,$012f

			b DB_USR_ROUT
			w SysErrColor
			b DBTXTSTR ,$0c,$10
			w Dlg_SysError
			b DBTXTSTR ,$0c,$1c
			w :t1
			b DBTXTSTR ,$0c,$26
			w :t2
			b DBTXTSTR ,$0c,$36
			w :t3
			b DBTXTSTR ,$0c,$46
			w Dlg_RBootGEOS1
			b DBTXTSTR ,$0c,$50
			w Dlg_RBootGEOS2
			b DB_USR_ROUT
			w PrntDskErrCode
			b NULL

if LANG = LANG_DE
::t1			b "Installation auf Grund eines Diskettenfehlers",NULL
::t2			b "auf dem Startlaufwerk fehlgeschlagen.",NULL
::t3			b "Fehlercode:",NULL
endif

if LANG = LANG_EN
::t1			b "Installation has been failed because a",NULL
::t2			b "disk error was detected!",NULL
::t3			b "Code:",NULL
endif

;*** Dialogbox: Start-Laufwerk nicht erkannt.
:Dlg_NoDkDvErr		b %00000000
			b $20,$97
			w $0010,$012f

			b DB_USR_ROUT
			w SysErrColor
			b DBTXTSTR ,$0c,$10
			w Dlg_SysError
			b DBTXTSTR ,$0c,$1c
			w :t1
			b DBTXTSTR ,$0c,$26
			w :t2
			b DBTXTSTR ,$0c,$30
			w :t3
			b DBTXTSTR ,$0c,$46
			w Dlg_RBootGEOS1
			b DBTXTSTR ,$0c,$50
			w Dlg_RBootGEOS2
			b NULL

if LANG = LANG_DE
::t1			b "Die Installation kann nicht fortgesetzt werden,",NULL
::t2			b "da kein Laufwerkstreiber für das derzeit aktive",NULL
::t3			b "Boot-Laufwerk gefunden wurde!",NULL
endif

if LANG = LANG_EN
::t1			b "The installation can not be continued because",NULL
::t2			b "no disk driver was found for the currently",NULL
::t3			b "active boot drive!",NULL
endif

;*** Dialogbox: "Datei xy fehlt".
:Dlg_FNotFound		b %00000000
			b $20,$97
			w $0010,$012f

			b DB_USR_ROUT
			w SysErrColor
			b DBTXTSTR ,$0c,$10
			w Dlg_SysError
			b DBTXTSTR ,$0c,$1c
			w :t1
			b DBTXTSTR ,$0c,$26
			w :t2
			b DBVARSTR ,$2c,$36
			b r9L
			b DBTXTSTR ,$0c,$46
			w Dlg_RBootGEOS1
			b DBTXTSTR ,$0c,$50
			w Dlg_RBootGEOS2
			b NULL

if LANG = LANG_DE
::t1			b "Installation fehlgeschlagen. Die Folgende Datei",NULL
::t2			b "wurde nicht gefunden:",NULL
endif

if LANG = LANG_EN
::t1			b "Installation has been failed. The following",NULL
::t2			b "file was not found:",NULL
endif

;*** Texte für alle Dialogboxen.
if LANG = LANG_DE
:Dlg_SysError		b PLAINTEXT,BOLDON
			b "FEHLER!",NULL
:Dlg_RBootGEOS1		b "Aktiver Kernal wurde teilweise überschrieben,",NULL
:Dlg_RBootGEOS2		b "GEOS muss neu gestartet werden...",NULL
endif

if LANG = LANG_EN
:Dlg_SysError		b PLAINTEXT,BOLDON
			b "ERROR!",NULL
:Dlg_RBootGEOS1		b "Active kernal has been partly overwritten.",NULL
:Dlg_RBootGEOS2		b "Please restart your GEOS-system...",NULL
endif
