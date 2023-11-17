; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "TopSym"
			t "TopMac"
:zpage			= $0000
endif

			o $0406
			n "64 CONFIG RL"
			f APPLICATION
			a "M. Kanet"

:SysFileName		= $2364
:RAM_Test_Copy		= $2375				;Testergbniss für aktuelle Bank.
:RAM_Test_CTRL		= $237d				;Kontrollwert für Bank #0 in REU.
:RAM_Test_Buf		= $2385				;Zwischenspeicher für Orginalwert in der REU.
:InitDriveVec		= $238e
:SysDrive		= $238f
:SysDrvType		= $2390
:DriveTypeA		= $2391
:DriveTypeB		= $2392
:DriveTypeC		= $2393
:PosROM_Data		= $2394
:DrvROM_Data		= $2395
:Vec_MenuRecData	= $23b5
:CurrentDrive		= $23b6
:InstallType		= $23b7
:Vec_DrvInfoTab		= $23b8
:CurrentType		= $23ba
:BankInUseTab		= $23bb
:SaveBootProg		= $24bb
:ScreenArea		= $28bb
:ScreenBuffer		= $28bc
:AddrBootProg		= $5000

:ConfigGEOS		b $03,$23,$03,$00
:CurRAM_Flag		b $40

:MainInit		jsr	PatchOldGEOS

			lda	firstBoot
			cmp	#$ff
			bne	AutoInstall
			jmp	LoadMainMenu

;*** Laufwerkstreiber während des bootens automatisch installieren.
:AutoInstall		bit	c128Flag		;GEOS 128 ?
			bmi	l048a			;Ja, Ende...

			lda	curDrive		;Start-Laufwerk speichern.
			sta	SysDrive
			tay
			lda	driveType -8,y
			sta	SysDrvType

			jsr	CheckSizeRAM		;Größe der Speichererweiterung
							;feststellen.

			jsr	i_MoveData		;Boot-Routine zwischenspeichern.
			w	AddrBootProg
			w	SaveBootProg
			w	$0400

			lda	#$01			;Anzahl Laufwerk zurücksetzen.
			sta	numDrives

			jsr	TestAllDrives		;Laufwerke erkennen.

;*** RAMLink-Kennung durch RAM1581-Kennung ersetzen.
:ExitToDeskTop		ldy	#$03
:l0440			lda	driveType +0,y		;Laufwerkstyp einlesen.
			cmp	#$23			;Typ #RAMLink-Partition ?
			bne	l044c			;Nein, weiter...
			lda	#$83			;Laufwerkstyp #RAM1581 für
			sta	driveType +0,y		;RAMLink übergeben.
:l044c			dey
			bpl	l0440

			lda	SysDrive
			jsr	SetNewDrive		;Boot-Laufwerk wieder aktivieren.
			jsr	InitRAM_ReBoot		;ReBoot installieren.

			jsr	CountDrives		;Laufwerke zählen.

			lda	ramExpSize		;Speichererweiterung vorhanden ?
			bne	l0481			;Ja, weiter...

			lda	numDrives
			cmp	#$02			;Mehr als ein Laufwerk ?
			bcc	l0481			;Nein, weiter...
			lda	driveType +0		;Typ für Laufwerk #8 und #9
			cmp	driveType +1		;identisch ?
			bne	l0473			;Nein, weiter...
			cmp	#$03			;Laufwerk #8/9 = 1581 ?
			bne	l0481			;Nein, weiter...

;*** Wenn keine Speichererweiterung vorhanden ist, wird das zweite Laufwerk
;    deaktiviert, nur das Startlaufwerk bleibt aktiv.
;    Das gleiche gilt bei 2x 1581.

:l0473			jsr	SwapDrive		;Zweites Laufwerk aktivieren.
			jsr	PurgeTurbo		;Laufwerk abschalten.
			jsr	SwapDrive		;Zum ersten Laufwerk zurück.

			lda	#$01			;Nur noch ein Laufwerk verfügbar.
			sta	numDrives

:l0481			jsr	i_MoveData		;Boot-Routine an Ursprungsadresse
			w	SaveBootProg		;zurückschreiben.
			w	AddrBootProg
			w	$0400

:l048a			jmp	EnterDeskTop		;Zurück zum DeskTop/Boot-Routine.

;*** GEOS 64-Version V1.3 und früher patchen.
:PatchOldGEOS		bit	c128Flag		;GEOS 128 ?
			bmi	l049f			;Ja, weiter...
			lda	version
			cmp	#$14			;GEOS 64 Version 1.3 oder früher ?
			bcs	l049f			;Nein, weiter...
			jsr	Patch_1			;Patch-Teil #1.
			jsr	Patch_2			;Patch-Teil #2.
:l049f			rts

:Patch_2		lda	#$c3
			sta	r0H
			lda	#$10
			sta	r0L
			ldy	#$00
			sty	r1L
			jsr	l04b3
			lda	#$05
			sta	r1L
:l04b3			ldx	r1L
:l04b5			lda	(r0L),y
			cmp	l04d3,x
			beq	l04c4
			cpx	r1L
			bne	l04b3
			iny
			bne	l04b3
			rts

:l04c4			iny
			bne	l04c8
			rts

:l04c8			inx
			lda	l04d3,x
			bne	l04b5
			lda	#$34
			sta	(r0L),y
			rts

:l04d3			lda	fileHeader +$5c
			cmp	#$00
:l04d8			b " V1.",NULL

;*** GEOS-Version V1.3 patchen.
:Patch_1		lda	version
			cmp	#$13			;GEOS-Version V1.3 ?
			bne	l04fc			;Nein, weiter...

			lda	SetDevice +2		;Zeiger auf Routine ":SetDevice"
			sta	r0H			;einlesen.
			lda	SetDevice +1
			sta	r0L

			ldy	#$00
			lda	(r0L),y			;Ersten Befehl von ":SetDevice"
			cmp	#$ea			;einlesen. "NOP"-Befehl ?
			beq	l04fc			;Ja, weiter...

			ldy	#$03
			lda	#$3d			;SetDevice-Routine patchen.
			sta	(r0L),y
:l04fc			rts

;*** Hauptmenü nachladen.
:LoadMainMenu		jsr	OpenSysFile		;Konfigurieren-Datei öffnen.
			txa				;Diskettenfehler ?
			bne	l051f			;Ja, Abbruch...

			lda	#$01			;Zeiger auf Datensatz für
			jsr	PointRecord		;Hauptmenü.

			lda	#>VLIR_BASE
			sta	r7H
			lda	#<VLIR_BASE
			sta	r7L
			lda	#$ff
			sta	r2L
			sta	r2H
			jsr	ReadRecord		;Hauptmenü einlesen.
			txa				;Diskettenfehler ?
			bne	l051f			;Ja, Abbruch...
			jmp	InitMainMenu		;Hauptmenü starten.
:l051f			jmp	EnterDeskTop		;Fehler, zum DeskTop.

:SystemClass		b "Configure   V2.1",NULL

;*** Systemdatei suchen und öffnen.
:OpenSysFile		ldx	#$00
			lda	SysFileOpen		;Datei bereits geöffnet ?
			bne	l0568			;Ja, Ende...

			lda	#>SysFileName
			sta	r6H
			lda	#<SysFileName
			sta	r6L
			lda	#AUTO_EXEC
			sta	r7L
			lda	#$01
			sta	r7H
			lda	#>SystemClass
			sta	r10H
			lda	#<SystemClass
			sta	r10L
			jsr	FindFTypes		;Konfigurieren-Datei suchen.
			txa				;Diskettenfehler ?
			bne	l0568			;Ja, Abbruch...

			lda	#>SysFileName
			sta	r0H
			lda	#<SysFileName
			sta	r0L
			jsr	OpenRecordFile		;Konfigurieren-Datei öffnen.
			lda	#$ff
			sta	SysFileOpen		;Flag "Datei geöffnet" setzen.
:l0568			rts

;*** Laufwerke erkennen und initialisieren.
:TestAllDrives		jsr	ExitTurbo		;Turbo-Modus abschalten.

			lda	ramExpSize		;Speichererweiterung vorhanden ?
			beq	l0574			;Nein, weiter...
			lda	CurRAM_Flag
:l0574			and	#%10100000
			sta	sysRAMFlg
			sta	sysFlgCopy

			lda	SysDrvType
			cmp	#$02
			bcs	l058c
			jsr	TestDriveType		;Aktuelles Laufwerk testen.
			cmp	#$ff			;Laufwerk erkannt ?
			bne	l058c			;Ja, weiter...
			lda	#$01			;Vorgabe-Laufwerk #1541.
:l058c			sta	DriveTypeA		;Aktuellen Laufwerks-Typ speichern.

			lda	curDrive
			eor	#$01
			jsr	SetDevice		;Nächstes Laufwerk aktivieren.

			jsr	TestDriveType		;Aktuelles Laufwerk testen.
			cmp	#$ff			;Laufwerk erkannt ?
			bne	l05a0			;Ja, weiter...
			lda	#$00			;Laufwerk nicht verfügbar.
:l05a0			sta	DriveTypeB

			lda	ramExpSize		;Speichererweiterung verfügbar ?
			beq	l05b4			;Nein, weiter...
			lda	#$0a
			jsr	SetDevice		;Laufwerk #10 aktivieren.
			jsr	TestDriveType		;Aktuelles Laufwerk testen.
			cmp	#$ff			;Laufwerk erkannt ?
			bne	l05b6			;Ja, weiter...
:l05b4			lda	#$00			;Laufwerk nicht verfügbar.
:l05b6			sta	DriveTypeC

			lda	SysDrive
			jsr	SetDevice		;Startlaufwerk aktivieren.

			jsr	TestSpaceRAM		;Genügend Speicher für alle RAM-
							;Laufwerke verfügbar ?
			jsr	LoadDrivers		;Laufwerkstreiber einlesen.
			txa				;Diskettenfehler ?
			bne	l0608			;Ja, Abbruch...

			jsr	PurgeTurbo		;Turbo abschalten.

			ldy	#$03
			lda	#$00
			sta	numDrives
:l05d2			sta	driveType  +0,y		;Laufwerksvariablen löschen.
			sta	turboFlags +0,y
			sta	driveData  +0,y
			sta	ramBase    +0,y
			dey
			bpl	l05d2

			jsr	InstallDriver		;Laufwerkstreiber installieren.

			lda	DriveTypeA
			jsr	InitCurDrive		;Laufwerk A: initialisieren.

			lda	DriveTypeB		;Laufwerk B: verfügbar ?
			beq	l05f8			;Nein, weiter...
			jsr	SwapDrive		;Auf Laufwerk B: wechseln.

			lda	DriveTypeB
			jsr	InitCurDrive		;Laufwerk B: initialisieren.

:l05f8			lda	DriveTypeC		;Laufwerk C: verfügbar ?
			beq	l0608			;Nein, weiter...

			lda	#$0a
			jsr	SetNewDrive		;Auf Laufwerk C: wechseln.
			lda	DriveTypeC
			jsr	InitCurDrive		;Laufwerk C: initialisieren.
:l0608			rts

;*** Laufwerkstreiber installieren.
:InstallDriver		lda	ramExpSize		;Speichererweiterung verfügbar ?
			beq	l0626			;Nein, Abbruch...

			lda	#$08			;Zeiger auf Laufwerk #8.
			sta	CurrentDrive
			lda	DriveTypeA
			sta	CurrentType

:l0619			jsr	LoadDiskDriver		;Laufwerktreiber installieren.
			inc	CurrentDrive		;Zeiger auf nächstes Laufwerk.
			lda	CurrentDrive
			cmp	#$0c			;Laufwerk #12 erreicht ?
			bne	l0619			;Nein, weiter...
:l0626			rts

;*** Laufwerkstreiber nach "DISK_BASE" kopieren.
:Driver2DISK_BASE	ldy	curDrive
			lda	driveType -8,y		;Laufwerk verfügbar ?
			beq	l065a			;Nein, weiter...
			tay
			jsr	GetVec2Driver		;Zeiger auf Treiber im Speicher.

			lda	Flag_DrvInREU,y		;Treiber bereits geladen ?
			bne	l065a			;Ja, weiter...

			lda	#$ff
			sta	Flag_DrvInREU,y		;Treiber als "Geladen" markieren.

			lda	LdAdrDskDrvL,y		;Treiber nach ":DISK_BASE"
			sta	r1L			;verschieben.
			lda	LdAdrDskDrvH,y
			sta	r1H

			lda	#>DISK_BASE
			sta	r0H
			lda	#<DISK_BASE
			sta	r0L
			lda	#>$0d80
			sta	r2H
			lda	#<$0d80
			sta	r2L
			jsr	MoveData
:l065a			rts

;*** Benötigte Laufwerkstreiber von Diskette einlesen.
:LoadDrivers		lda	DriveTypeA
			jsr	ReadDriverFile		;Treiber für Laufwerk A: laden.
			bne	l0682			;Fehler, Abbruch...

			lda	DriveTypeB
			jsr	ReadDriverFile		;Treiber für Laufwerk B: laden.
			bne	l0682			;Fehler, Abbruch...

			lda	DriveTypeC
			jsr	ReadDriverFile		;Treiber für Laufwerk C: laden.
			bne	l0682			;Fehler, Abbruch...

			ldx	#$00
			lda	SysFileOpen
			beq	l0682

			jsr	CloseRecordFile		;Systemdatei schließen.

			lda	#$00
			sta	SysFileOpen
:l0682			rts

;*** Laufwerkstreiber von Diskette einlesen.
:ReadDriverFile		ldx	#$00
			tay				;Laufwerkstyp = #00 ?
			beq	l06bb			;Ja, Ende...

			jsr	GetVec2Driver		;Zeiger auf Laufwerkstreiber.

			lda	Flag_DrvInREU,y		;Treiber bereits geladen ?
			bne	l06bb			;Ja, weiter...

			tya
			pha
			jsr	OpenSysFile		;Systemdatei öffnen.
			pla
			tay
			txa				;Diskettenfehler ?
			bne	l06bb			;Ja, Abbruch...

			lda	#$ff			;Treiber als "Geladen" markieren.
			sta	Flag_DrvInREU,y

			lda	LdAdrDskDrvL ,y		;Ladeadresse ermitteln.
			sta	r7L
			lda	LdAdrDskDrvH ,y
			sta	r7H

			tya
			clc
			adc	#$02			;Zeiger auf Datensatz in
			jsr	PointRecord		;VLIR-Datei mit Laufwerkstreiber.

			LoadW	r2,$0d80		;Max. $0d80 Bytes lesen.
			jsr	ReadRecord
:l06bb			txa				;Diskettenfehler ?
			rts

:SysFileOpen		b $00
:Flag_DrvInREU		b $00,$00,$00,$00,$00

;*** Speichererweiterung für RAM-Laufwerke ausreichend ?
:TestSpaceRAM		lda	#$01			;Zeiger auf Bank #1.
			sta	r0L

			lda	SysDrive		;Auf zweites Laufwerk wechseln.
			eor	#$01			;(Von RAM41,71,81 kann nicht
			tay				; ja gebootet werden!)

			lda	ConfigGEOS -8,y
			ldx	DriveTypeB
			jsr	TestDriveRAM		;Speicher für Laufwerk belegen.
			sta	DriveTypeB		;Neuen Laufwerkstyp speichern.

			ldy	SysDrive
			lda	ConfigGEOS -8,y
			and	#$7f
			ldx	DriveTypeA
			jsr	TestDriveRAM		;Speicher für Laufwerk belegen.
			sta	DriveTypeA		;Neuen Laufwerkstyp speichern.

			lda	ramExpSize		;Speichererweiterung vorhanden ?
			beq	l06f8			;Nein, weiter...
			lda	ConfigGEOS +2
			ldx	DriveTypeC
			jsr	TestDriveRAM		;Speicher für Laufwerk belegen.
:l06f8			sta	DriveTypeC		;Neuen Laufwerkstyp speichern.
			rts

;*** Ist genügend RAM für Laufwerk verfügbar ?
:TestDriveRAM		stx	r2L			;Aktuellen Laufwerksyp merken.
			sta	r2H			;GEOS-Konfiguration merken.
			jsr	GetSizeRDrive		;Größe RAM-Laufwerk berechnen.
			clc
			adc	r0L			;Anzahl Bänke addieren.
			cmp	ramExpSize		;Speicher-Überlauf ?
			bcc	l0715
			beq	l0715			;Nein, weiter...

			lda	r2H			;Laufwerkstyp "RAM" & "Shadowed"
			and	#$3f			;löschen.
			sta	r2H
			lda	r0L
:l0715			sta	r0H			;Belegte Speicherbänke merken.

			lda	r2H			;RAM-Laufwerk ?
			bpl	l0722			;Nein, weiter...

			lda	r0H			;Neuen Wert für belegte Bänke in
			sta	r0L			;der Speichererweiterung setzen.

:l071f			lda	r2H			;Laufwerkstyp wieder einlesen.
			rts

:l0722			cmp	#$23			;RAMLink ?
			beq	l071f			;Ja, Ende...

			and	#%00001111		;Laufwerkstyp isolieren.
			cmp	#$01			;Typ #1541 ?
			bne	l0736			;Nein, weiter...

			lda	r2L			;Aktuellen Laufwerkstyp einlesen.
			cmp	#$02			;Typ #1571 ?
			bne	l0736			;Nein, weiter...

			lda	#$01			;1571 als 1541 installieren.
			sta	r2L

:l0736			lda	r2H
			and	#$40			;GEOS-Laufwerk "Shadowed" ?
			beq	l074b			;Nein, weiter...

			lda	r2H			;GEOS-Konfiguration mit
			and	#%00001111		;aktueller Konfiguration
			cmp	r2L			;vergleichen.
			bne	l074b			;Keine Übereinstimmung, Abbruch...

			lda	r0H			;Neue Anzahl belegter RAM-Bänke
			sta	r0L			;festlegen und GEOS-Konfiguration
			lda	r2H			;übernehmen.
			rts

:l074b			lda	r2L			;GEOS-Konfiguration ungültig.
			rts				;Aktuelles laufwerk zurückgeben.

;*** Erweiterte Routine zu "SetDevice".
:SwapDrive		lda	curDrive		;Zum zweiten Laufwerk wechseln.
			eor	#$01
:SetNewDrive		jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Fehler aufgetreten ?
			bne	l077d			;Ja, Abbruch...

			lda	ramExpSize		;Speichererweiterung verfügbar ?
			bne	l0774			;Ja, weiter...

			lda	CurrentType		;Aktuellen Typ speichern.
			pha

			ldy	curDrive
			lda	driveType -8,y		;Laufwerk verfügbar ?
			beq	l0770			;Nein, weiter...
			sta	CurrentType		;Neuen Typ zwischenspeichern.
			jsr	LoadDiskDriver		;Laufwerkstreiber nach DISK_BASE.

:l0770			pla
			sta	CurrentType		;Laufwerkstyp zurücksetzen.

:l0774			ldy	curDrive
			lda	driveType -8,y
			sta	curType
:l077d			rts

;*** Aktuelles Laufwerk initialisieren.
:InitCurDrive		pha				;Laufwerktyp zwischenspeichern.
			lda	#$00			;Aktuelles Laufwerk noch
			sta	InstallType		;nicht installiert.
			lda	curDrive		;Aktuellen Laufwerkstyp merken.
			sta	CurrentDrive
			pla				;Laufwerkstyp wieder einlesen.
			beq	l07d2			;Typ = #0 ? Ja, Ende...

			cmp	#$01			;Kennbyte für #1541 ?
			bne	l0794			;Nein, weiter...
			jmp	Install_1541		;1541-Laufwerk installieren.

:l0794			cmp	#$02			;Kennbyte für #1571 ?
			bne	l079b			;Nein, weiter...
			jmp	Install_1571		;1571-Laufwerk installieren.

:l079b			cmp	#$03			;Kennbyte für #1581 ?
			bne	l07a2			;Nein, weiter...
			jmp	Install_1581		;1581-Laufwerk installieren.

:l07a2			cmp	#$41			;Kennbyte für 1541 "Shadowed" ?
			bne	l07ac			;Nein, weiter...
			jsr	Install_1541		;1541 installieren.
			jmp	Install_DskCache	;Shadow-RAM installieren.

:l07ac			cmp	#$43			;Kennbyte für 1581 "DIR-Shadowed" ?
			bne	l07b6			;Nein, weiter...
			jsr	Install_1581		;1581 installieren.
			jmp	Install_DirCache	;Shadow-RAM installieren.

:l07b6			cmp	#$81			;Kennbyte für #RAM1541 ?
			bne	l07bd			;Nein, weiter...
			jmp	Install_RAM1541		;RAM1541-Laufwerk installieren.

:l07bd			cmp	#$82			;Kennbyte für #RAM1571 ?
			bne	l07c4			;Nein, weiter...
			jmp	Install_RAM1571		;RAM1571-Laufwerk installieren.

:l07c4			cmp	#$83			;Kennbyte für #RAM1581 ?
			bne	l07cb			;Nein, weiter...
			jmp	Install_RAM1581		;RAM1581-Laufwerk installieren.

:l07cb			cmp	#$23
			bne	l07d2
			jmp	Install_RAMLink		;RAMLink-Partition installieren.

:l07d2			rts

;*** 1541/Shadowed 1541 installieren.
:Install_1541		lda	InstallType
			cmp	#$01			; #1541 installiert ?
			beq	Install_1541b		;Ja, weiter...

			cmp	#$41			; #"Shadowed 1541" installieren ?
			bne	Install_1541a		;Nein, weiter...

			ldy	CurrentDrive		;Zeiger auf aktuelles Laufwerk.
			lda	#$01			;1541 in Laufwerkstabelle und
			sta	driveType -8,y		;in GEOS-Konfiguration speichern.
			sta	ConfigGEOS-8,y

			lda	#$00
			sta	ramBase   -8,y		;Zeiger auf Erste Speicherbank
							;für "Shadowed 1541" löschen.
			dec	Cnt_GEOS_Drives		;RAM-Laufwerk installiert.
			rts

;*** Aktueller Typ ungültig, 1541-Laufwerk installieren.
:Install_1541a		lda	#$01
			sta	CurrentType		;Typ #1541 definieren.
			jmp	SetDriveData		;Laufwerksdaten speichern.

;*** Echtes 1541-Laufwerk bereits installieren.
:Install_1541b		rts

;*** 1571 installieren.
:Install_1571		lda	InstallType
			cmp	#$02			; #1571 installiert ?
			beq	Install_1571b		;Ja, weiter...
			lda	#$02
			sta	CurrentType		;Typ #1571 definieren.
			jmp	SetDriveData		;Laufwerksdaten speichern.

;*** Echtes 1571-Laufwerk bereits installieren.
:Install_1571b		rts

;*** 1581 installieren.
:Install_1581		lda	InstallType
			cmp	#$03			; #1581 installiert ?
			beq	Install_1581b		;Ja, weiter...
			lda	#$03
			sta	CurrentType		;Typ #1581 definieren.
			jmp	SetDriveData		;Laufwerksdaten speichern.
:Install_1581b		rts

;*** Shadowed-Laufwerk installieren.
:Install_DskCache	lda	InstallType
			cmp	#$41			; #Shadowed 1541 installiert ?
			beq	l083b			;Ja, weiter...

			lda	#$41
			jsr	ADDR_DrvInREU		;Adresse für Shadow-RAM berechnen.

			ldy	CurrentDrive
			sta	ramBase   -8,y		;Startadresse merken.

			lda	#$41			;Shadowed41 in Laufwerkstabelle und
			sta	driveType -8,y		;in GEOS-Konfiguration speichern.
			sta	ConfigGEOS-8,y
			jsr	NewDisk			;Diskette öffnen.
			dec	Cnt_GEOS_Drives		;RAM-Laufwerk installiert.
:l083b			rts

;*** DirShadowed-Laufwerk installieren.
:Install_DirCache	lda	InstallType
			cmp	#$43			; #DirShadowed 1581 installiert ?
			beq	l085c			;Ja, weiter...

			lda	#$43
			jsr	ADDR_DrvInREU		;Adresse für Shadow-RAM berechnen.

			ldy	CurrentDrive
			sta	ramBase   -8,y		;Startadresse merken.

			lda	#$43			;DirShadowed in Laufwerkstabelle und
			sta	driveType -8,y		;in GEOS-Konfiguration speichern.
			sta	ConfigGEOS-8,y
			jsr	NewDisk			;Diskette öffnen.
			dec	Cnt_GEOS_Drives		;RAM-Laufwerk installiert.
:l085c			rts

;*** RAM1541-Laufwerk installieren.
:Install_RAM1541	lda	InstallType
			cmp	#$81			;Laufwerk bereits installiert ?
			beq	l088e			;Ja, weiter...

			lda	#$81
			sta	CurrentType		;Laufwerkstreiber für
			jsr	LoadDiskDriver		;#RAM1541-Laufwerk einlesen.

			inc	numDrives		;Anzahl Laufwerke +1.

			lda	#$81
			jsr	ADDR_DrvInREU		;Adresse für RAM-Laufwerk berechnen.

			ldy	CurrentDrive
			sta	ramBase   -8,y		;Startadresse merken.
			lda	#$81			;Typ RAM41 in Laufwerkstabelle und
			sta	driveType -8,y		;in GEOS-Konfiguration speichern.
			sta	ConfigGEOS-8,y
			lda	CurrentDrive
			jsr	SetNewDrive		;Laufwerk aktivieren.
			jsr	CreateBAM_RAMx		;BAM für RAM-Laufwerk erzeugen.
			dec	Cnt_GEOS_Drives
:l088e			rts

;*** RAM1571-Laufwerk installieren.
:Install_RAM1571	lda	InstallType
			cmp	#$82			;Laufwerk bereits installiert ?
			beq	l08c0			;Ja, weiter...

			lda	#$82
			sta	CurrentType		;Laufwerkstreiber für
			jsr	LoadDiskDriver		;#RAM1571-Laufwerk einlesen.

			inc	numDrives		;Anzahl Laufwerke +1.

			lda	#$82
			jsr	ADDR_DrvInREU		;Adresse für RAM-Laufwerk berechnen.

			ldy	CurrentDrive
			sta	ramBase   -8,y		;Startadresse merken.
			lda	#$82			;Typ RAM71 in Laufwerkstabelle und
			sta	driveType -8,y		;in GEOS-Konfiguration speichern.
			sta	ConfigGEOS-8,y
			lda	CurrentDrive
			jsr	SetNewDrive		;Laufwerk aktivieren.
			jsr	CreateBAM_RAMx		;BAM für RAM-Laufwerk erzeugen.
			dec	Cnt_GEOS_Drives
:l08c0			rts

;*** RAM1581-Laufwerk installieren.
:Install_RAM1581	lda	InstallType
			cmp	#$83			;Laufwerk bereits installiert ?
			beq	l08f2			;Ja, weiter...

			lda	#$83
			sta	CurrentType		;Laufwerkstreiber für
			jsr	LoadDiskDriver		;#RAM1581-Laufwerk einlesen.

			inc	numDrives		;Anzahl Laufwerke +1.

			lda	#$83
			jsr	ADDR_DrvInREU		;Adresse für RAM-Laufwerk berechnen.

			ldy	CurrentDrive
			sta	ramBase   -8,y		;Startadresse merken.
			lda	#$83			;Typ RAM81 in Laufwerkstabelle und
			sta	driveType -8,y		;in GEOS-Konfiguration speichern.
			sta	ConfigGEOS-8,y
			lda	CurrentDrive
			jsr	SetNewDrive		;Laufwerk aktivieren.
			jsr	CreateBAM_RAMx		;BAM für RAM-Laufwerk erzeugen.
			dec	Cnt_GEOS_Drives
:l08f2			rts

;*** RAM1541-Laufwerk installieren.
:Install_RAMLink	lda	InstallType
			cmp	#$23			;Laufwerk bereits installiert ?
			beq	l0925			;Ja, weiter...

			lda	#$23
			sta	CurrentType		;Laufwerkstreiber für
			jsr	LoadDiskDriver		;#RAMLink-Laufwerk einlesen.

			inc	numDrives		;Anzahl Laufwerke +1.

			jsr	Get1stRL_Part		;Erste Partition suchen.
			bcc	l0925			;Partition gefunden ? Nein, Ende...

			ldy	CurrentDrive		;Startadresse Partition speichern.
			sta	ramBase   -8,y
			txa
			sta	driveData +3

			lda	#$23			;Typ RL in Laufwerkstabelle und
			sta	driveType -8,y		;in GEOS-Konfiguration speichern.
			sta	ConfigGEOS-8,y
			lda	CurrentDrive
			jsr	SetNewDrive		;Laufwerk aktivieren.
			dec	Cnt_GEOS_Drives
:l0925			rts

			b $00

;*** Erste RL-Partition suchen.
:Get1stRL_Part		lda	RL_Aktiv		;RAMLink verfügbar ?
			bne	l092e			;Ja, weiter...
			clc
			rts

:l092e			lda	#$00			;Partitions-Nr. löschen.
			sta	r5L
			lda	#$00			;Flag für "Partition gefunden"
			sta	r9L			;löschen.

			lda	#$01			;Zeiger auf ersten Sektor des
			sta	RL_Track		;Partitions-Verzeichnisses.
			lda	#$00
			sta	RL_Sektor

			lda	#$ff			;System-Partition aktivieren.
			sta	RL_Part

			lda	#>diskBlkBuf
			sta	C64_RAM_H
			lda	#<diskBlkBuf
			sta	C64_RAM_L

:l094f			jsr	GetRL_Sektor		;Sektor einlesen.

			lda	#$00			;Zeiger auf ersten Eintrag.
			sta	r0L
:l0956			lda	r0L
			asl
			asl
			asl
			asl
			asl
			tay
			lda	diskBlkBuf+$02,y
			cmp	#$04			;1581-Partition gefunden ?
			beq	l0983			;Ja, weiter...

:l0965			inc	r0L			;Zeiger auf nächsten Eintrag im
			lda	r0L			;Partitions-Verzeichnis.
			cmp	#$08			;Verzeichnis-Sektor durchsucht ?
			bne	l0956			;Nein, weiter...

			inc	RL_Sektor
			lda	RL_Sektor
			cmp	#$05			;Letzter Verzeichnis-Sektor ?
			bne	l094f			;Nein, weiter...

			lda	r9L
			beq	l0981

			lda	r8L
			ldx	r8H
			sec
			rts

;*** Keine Partition gefunden.
:l0981			clc
			rts

;*** Partition testen.
:l0983			lda	diskBlkBuf+$04,y
			cmp	r5L			;Partitions-Nr. = #$00 ?
			beq	l099f			;Ja, weiter...

			lda	r9L			;Partition bereits gefunden ?
			bne	l0965			;Ja, ignorieren...

			lda	diskBlkBuf+$16,y	;Startadresse Partition merken.
			sta	r8L
			lda	diskBlkBuf+$17,y
			sta	r8H
			lda	#$01			;Flag für "Partition gefunden"
			sta	r9L			;setzen und weitersuchen.
			clv				;(Hier könnte die Routine auch
			bvc	l0965			;beendet werden!)

;*** Partition OK.
:l099f			lda	diskBlkBuf+$16,y
			ldx	diskBlkBuf+$17,y
			sec
			rts

;*** Laufwerksdaten an GEOS übergeben.
:SetDriveData		jsr	LoadDiskDriver		;Aktuellen Laufwerkstreiber laden.

			lda	CurrentDrive
			jsr	SetNewDrive		;Aktuelles Laufwerk aktivieren.

			lda	firstBoot
			cmp	#$ff			;GEOS-SystemBoot ?
			beq	l09c6			;Nein, weiter...

			ldy	CurrentDrive
			lda	CurrentType		;Aktuellen Laufwerkstyp in
			sta	driveType -8,y		;Tabelle eintragen.
			inc	numDrives		;Mind. 1 Laufwerk in Tabelle.
			clv
			bvc	l09cf			;Weiter...

:l09c6			jsr	AddNewDrive

			lda	CurrentDrive
			jsr	SetNewDrive		;Aktuelles Laufwerk aktivieren.

:l09cf			dec	Cnt_GEOS_Drives		;Zähler für RAM-Laufwerke +1.

			ldy	CurrentDrive
			lda	driveType -8,y		;Laufwerkstyp in Zwischenspeicher
			sta	ConfigGEOS-8,y		;übertragen.
			lda	#$00
			sta	ramBase   -8,y		;":ramBase"-Speicher löschen.
			rts

;*** Erste Bank für RAM-Laufwerk in Speichererweiterung ermitteln.
:ADDR_DrvInREU		pha				;Laufwerkstyp speichern.
			jsr	DefUsedBankTab		;Anzahl belegter Baänke ermitteln.
			pla
			sta	r0L

			lda	InstallType		;Laufwerkstyp einlesen.
			and	#$c0			;Laufwerk RAM/Shadowed ?
			bne	l09fa			;Ja, weiter...

			lda	r0L			;Laufwerkstyp einlesen.
			jsr	GetSizeRDrive		;Platz in der REU berechnen.
			cmp	#$01
			beq	FindFreeBank
			bne	l0a15

:l09fa			ldy	CurrentDrive
			lda	ramBase   -8,y		;Startadresse in REU löschen.
			ldx	#$00			;Flag "Laufwerk ist gültig".
			rts

;*** Freie Speicherbank suchen.
:FindFreeBank		ldy	ramExpSize
:l0a06			dey
			bmi	l0a12			; => Speichererweiterung voll.
			lda	BankInUseTab,y		;Bank belegt ?
			bne	l0a06			;Ja, weitersuchen.
			tya
			ldx	#$00			;Flag "Laufwerk ist gültig".
			rts
:l0a12			ldx	#$ff			;Flag "Laufwerk ist ungültig".
			rts

;*** Aufeinanderfolgende, freie Speicherbänke suchen.
:l0a15			sta	r0L			;Bankanzahl merken.

			ldy	#$00			;Zeiger auf erste 64K-Bank.
:l0a19			lda	r0L			;Zähler für Suche auf Anfang.
			sta	r0H

:l0a1d			sty	r1L
			cpy	ramExpSize		;Ende Speichererweiterung erreicht ?
			bcs	l0a44			;Ja, Abbruch.

			lda	BankInUseTab,y
			iny
			cmp	#$00			;Bank frei ?
			bne	l0a1d			;Nein, weitersuchen.

:l0a2c			dec	r0H			;64K-Bank-Zähler -1.
			beq	l0a3f			; => Genügend 64K-Bänke gefunden...

			cpy	ramExpSize		;Ende Speichererweiterung erreicht ?
			bcs	l0a44			;Ja, Abbruch.

			lda	BankInUseTab,y
			iny
			cmp	#$00			;Bank frei ?
			bne	l0a19			;Nein, weitersuchen.
			beq	l0a2c			;Ja, nächste freie Bank suchen.

:l0a3f			lda	r1L			;Erste freie Bank einlesen.
			ldx	#$00			;Flag "Laufwerk ist gültig".
			rts
:l0a44			ldx	#$ff			;Flag "Laufwerk ist ungültig".
			rts

;*** Belegte Speicherbänke ermitteln.
:DefUsedBankTab		ldy	#$1f
			lda	#$00			;Bank-Belegungstabelle löschen.
:l0a4b			sta	BankInUseTab,y
			dey
			bpl	l0a4b

			lda	#$ff			;Bank #0 vorbelegen (GEOS-Kernal).
			sta	BankInUseTab

			lda	#$08			;Zeiger auf erstes Laufwerk.
			sta	r0L

:l0a5a			ldy	r0L
			lda	driveType -8,y		;Laufwerkstyp einlesen.
			jsr	GetSizeRDrive		;Max. Anzahl Bänke ermitteln.
			tax				;Werden RAM-Bänke benötigt ?
			beq	l0a74			;Nein, weiter...

			ldy	r0L
			lda	ramBase -8,y		;Zeiger auf erste Bank einlesen.
			tay
:l0a6b			lda	#$ff			;Benötigte Bänke in Tabelle
			sta	BankInUseTab,y		;als belegt sperren.
			iny
			dex
			bne	l0a6b

:l0a74			inc	r0L
			lda	r0L			;Zeiger auf nächstes Laufwerk.
			cmp	#$0c			;Alle Laufwerke getestet ?
			bcc	l0a5a			;Nein, weiter...
			rts

;*** Anzahl Bänke für RAM-Laufwerk ermitteln.
:GetSizeRDrive		sta	r0H			;Laufwerkstyp speichern.
			and	#$c0			;RAM/Shadowed ?
			beq	l0a93			;Nein, weiter...

			lda	r0H
			cmp	#$83			;RAM1581-Laufwerk ?
			bne	l0a8c			;Nein, weiter...
			clc				;Zeiger auf Tabelle korrigieren.
			adc	#$01

:l0a8c			and	#$0f
			tay
			lda	MaxBank,y
			rts

:l0a93			lda	#$00			;Keine Bank benötigt.
			rts

:MaxBank		b $03,$03,$06,$01,$0d

;*** Laufwerkstreiber installieren.
:LoadDiskDriver		lda	ramExpSize		;Speichererweiterung vorhanden ?
			bne	CopyDDrv2REU		;Ja, weiter...

			lda	sysRAMFlg		;Flag löschen "Treiber in REU".
			and	#$bf
			sta	sysRAMFlg
			sta	sysFlgCopy
			sta	CurRAM_Flag

			ldy	CurrentType
			lda	CurrentDrive		;Zeiger auf benötigten Laufwerks-
			jsr	GetDriverPos		;treiber setzen.

			LoadW	r1,DISK_BASE
			jsr	MoveData		;Laufwerkstreiber installieren.
			rts

;*** Laufwerkstreiber in REU kopieren.
:CopyDDrv2REU		lda	sysRAMFlg		;Flag setzen "Treiber in REU".
			ora	#$40
			sta	sysRAMFlg
			sta	sysFlgCopy
			sta	CurRAM_Flag

			ldy	driveType +0		;Laufwerk #8 verfügbar ?
			beq	l0ade			;Nein, weiter...
			lda	#$08			;Zeiger auf Laufwerkstreiber für
			jsr	GetDriverPos		;Laufwerk #8 berechnen.
			jsr	StashRAM		;Laufwerkstreiber in REU kopieren.

:l0ade			ldy	driveType +1		;Laufwerk #9 verfügbar ?
			beq	l0aeb			;Nein, weiter...
			lda	#$09			;Zeiger auf Laufwerkstreiber für
			jsr	GetDriverPos		;Laufwerk #9 berechnen.
			jsr	StashRAM		;Laufwerkstreiber in REU kopieren.

:l0aeb			ldy	driveType +2		;Laufwerk #10 verfügbar ?
			beq	l0af8			;Nein, weiter...
			lda	#$0a			;Zeiger auf Laufwerkstreiber für
			jsr	GetDriverPos		;Laufwerk #10 berechnen.
			jsr	StashRAM		;Laufwerkstreiber in REU kopieren.

:l0af8			ldy	CurrentType
			lda	CurrentDrive		;Zeiger auf aktuellen Laufwerks-
			jsr	GetDriverPos		;treiber setzen.
			jsr	StashRAM		;Laufwerkstreiber in REU kopieren.

			LoadW	r1,DISK_BASE
			jsr	MoveData		;Laufwerkstreiber installieren.
			rts

;*** Zeiger für StashRAM setzen um Laufwerkstreiber aus
;    C64-RAM in REU zu übertragen.
:GetDriverPos		pha
			jsr	GetVec2Driver		;Zeiger auf Laufwerkstreiber setzen.

			lda	LdAdrDskDrvL ,y		;Zeiger auf Startadresse des
			sta	r0L			;Laufwerkstreiber im C64-RAM.
			lda	LdAdrDskDrvH ,y
			sta	r0H
			pla
			tay
			lda	DskDrvBaseL-8,y		;Zeiger auf Startadresse des
			sta	r1L			;Laufwerkstreiber in der REU.
			lda	DskDrvBaseH-8,y
			sta	r1H
			LoadW	r2 ,$0d80		;Größe Laufwerkstreiber.
			LoadB	r3L,$00			;GEOS-Systembank.
			rts

:LdAdrDskDrvL		b $80,$00,$80,$00,$80
:LdAdrDskDrvH		b $3c,$4a,$57,$65,$72

:DskDrvBaseL		b $00,$80,$00,$80
:DskDrvBaseH		b $83,$90,$9e,$ab

;*** Zeiger auf Gerätetreiber berechnen.
;    $00 = 1541
;    $01 = 1571
;    $02 = 1581
;    $03 = RAM41,71
;    $04 = RAM81,RAMLink

:GetVec2Driver		tya
			bpl	l0b58

			cmp	#$83
			beq	l0b54
			ldy	#$03
			bne	l0b60

:l0b54			ldy	#$04
			bne	l0b60

:l0b58			cmp	#$23
			beq	l0b54
			and	#$0f
			tay
			dey
:l0b60			rts

;*** BAM für RAM-Laufwerk erzeugen.
:CreateBAM_RAMx		ldy	CurrentDrive
			lda	driveType -8,y
			and	#$0f
			cmp	#$03
			bcc	CreateBAM_41_71
			jmp	CreateBAM_81

;*** BAM für RAM1541,71 erzeugen.
:CreateBAM_41_71	ldy	#$00			;Speicher für BAM #1 löschen.
			tya
:l0b73			sta	curDirHead,y
			iny
			bne	l0b73

			lda	#$34			;BAM für 1541 definieren.
			sta	BAM_41_71 +$96
			lda	#$00
			sta	BAM_41_71 +3

			ldy	curDrive
			lda	driveType -8,y
			and	#$0f

			ldy	#$bd
			cmp	#$01			;1541 erzeugen ?
			beq	l0b9d			;Ja, weiter...

			ldy	#$00			;BAM für 1571 definieren.
			lda	#$37
			sta	BAM_41_71 +$96
			lda	#$80
			sta	BAM_41_71 +3

:l0b9d			dey				;BAM #1 erzeugen.
			lda	BAM_41_71   ,y
			sta	curDirHead  ,y
			tya
			bne	l0b9d

			ldy	curDrive
			lda	driveType -8,y
			and	#$0f
			cmp	#$01			;1541 erzeugen ?
			beq	l0bc8			;Ja, weiter...

			ldy	#$00			;Speicher für BAM #2 löschen.
			tya
:l0bb6			sta	dir2Head,y
			iny
			bne	l0bb6

			ldy	#$69
:l0bbe			dey				;BAM #2 erzeugen.
			lda	BAM_71  ,y
			sta	dir2Head,y
			tya
			bne	l0bbe

:l0bc8			jsr	PutDirHead		;BAM auf Diskette speichern.

			jsr	ClrDiskSekBuf		;Sektorspeicher löschen.

			lda	#$ff			;Hauptverzeichnis löschen.
			sta	diskBlkBuf +$01
			LoadW	r4 ,diskBlkBuf
			LoadB	r1L,$12
			LoadB	r1H,$01
			jsr	PutBlock

			inc	r1L			;Sektor $13/$08 löschen.
			lda	#$08			;Ist Borderblock für DeskTop 2.0!
			sta	r1H
			jsr	PutBlock
			lda	#$00
			rts

;*** Sektorspeicher löschen.
:ClrDiskSekBuf		ldy	#$00
			tya
:l0bf5			sta	diskBlkBuf,y
			dey
			bne	l0bf5
			rts

;*** BAM für RAM41,71-Laufwerke.
:BAM_41_71		b $12,$01,$41,$00,$15,$ff,$ff,$1f
			b $15,$ff,$ff,$1f,$15,$ff,$ff,$1f
			b $15,$ff,$ff,$1f,$15,$ff,$ff,$1f
			b $15,$ff,$ff,$1f,$15,$ff,$ff,$1f
			b $15,$ff,$ff,$1f,$15,$ff,$ff,$1f
			b $15,$ff,$ff,$1f,$15,$ff,$ff,$1f
			b $15,$ff,$ff,$1f,$15,$ff,$ff,$1f
			b $15,$ff,$ff,$1f,$15,$ff,$ff,$1f
			b $15,$ff,$ff,$1f,$15,$ff,$ff,$1f
			b $11,$fc,$ff,$07,$12,$ff,$fe,$07
			b $13,$ff,$ff,$07,$13,$ff,$ff,$07
			b $13,$ff,$ff,$07,$13,$ff,$ff,$07
			b $13,$ff,$ff,$07,$12,$ff,$ff,$03
			b $12,$ff,$ff,$03,$12,$ff,$ff,$03
			b $12,$ff,$ff,$03,$12,$ff,$ff,$03
			b $12,$ff,$ff,$03,$11,$ff,$ff,$01
			b $11,$ff,$ff,$01,$11,$ff,$ff,$01
			b $11,$ff,$ff,$01,$11,$ff,$ff,$01
			b $52,$41,$4d,$20,$31,$35,$37,$31
			b $a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
			b $a0,$a0,$52,$44,$a0,$32,$41,$a0
			b $a0,$a0,$a0,$13,$08,$47,$45,$4f;$13/$08 Borderblock!
			b $53,$20,$66,$6f,$72,$6d,$61,$74
			b $20,$56,$31,$2e,$30,$00,$00,$00
			b $00,$00,$00,$00,$00,$00,$00,$00
			b $00,$00,$00,$00,$00,$00,$00,$00
			b $00,$00,$00,$00,$00,$00,$00,$00
			b $00,$00,$00,$00,$00,$15,$15,$15
			b $15,$15,$15,$15,$15,$15,$15,$15
			b $15,$15,$15,$15,$15,$15,$00,$13
			b $13,$13,$13,$13,$13,$12,$12,$12
			b $12,$12,$12,$11,$11,$11,$11,$11

:BAM_71			b $ff,$ff,$1f,$ff,$ff,$1f,$ff,$ff
			b $1f,$ff,$ff,$1f,$ff,$ff,$1f,$ff
			b $ff,$1f,$ff,$ff,$1f,$ff,$ff,$1f
			b $ff,$ff,$1f,$ff,$ff,$1f,$ff,$ff
			b $1f,$ff,$ff,$1f,$ff,$ff,$1f,$ff
			b $ff,$1f,$ff,$ff,$1f,$ff,$ff,$1f
			b $ff,$ff,$1f,$00,$00,$00,$ff,$ff
			b $07,$ff,$ff,$07,$ff,$ff,$07,$ff
			b $ff,$07,$ff,$ff,$07,$ff,$ff,$07
			b $ff,$ff,$03,$ff,$ff,$03,$ff,$ff
			b $03,$ff,$ff,$03,$ff,$ff,$03,$ff
			b $ff,$03,$ff,$ff,$01,$ff,$ff,$01
			b $ff,$ff,$01,$ff,$ff,$01,$ff,$ff
			b $01

;*** BAM für RAM1581 erzeugen.
:CreateBAM_81		ldy	#$00			;BAM Teil #1 definieren.
			tya
:l0d68			sta	curDirHead,y
			iny
			bne	l0d68

			lda	#$28			;Zeiger auf ersten Verzeichnis-
			sta	curDirHead +$00		;Sektor richten.
			lda	#$03
			sta	curDirHead +$01
			lda	#$44
			sta	curDirHead +$02

			ldy	#$2d
:l0d7f			lda	BAM_81,y
			sta	curDirHead +$90,y
			dey
			bpl	l0d7f

			lda	#$28			;BAM Teil #1 speichern.
			sta	r1L
			lda	#$00
			sta	r1H
			LoadW	r4,curDirHead
			jsr	PutBlock

			ldy	#$00			;BAM Teil #2 definieren.
:l0d9d			lda	BAM_81a,y
			sta	dir2Head +$00,y
			iny
			bne	l0d9d

			lda	#$28			;BAM Teil #2 speichern.
			sta	r1L
			lda	#$01
			sta	r1H
			LoadW	r4,dir2Head
			jsr	PutBlock

			lda	#$ff			;BAM Teil #3 definieren.
			sta	dir2Head +$01
			lda	#$00
			sta	dir2Head +$00
			lda	#$28
			sta	dir2Head +$fa
			lda	#$ff
			sta	dir2Head +$fb
			lda	#$ff
			sta	dir2Head +$fd

			lda	#$28			;BAM Teil #3 speichern.
			sta	r1L
			lda	#$02
			sta	r1H
			LoadW	r4,dir2Head
			jsr	PutBlock

			jsr	GetDirHead		;BAM einlesen.

			jsr	ClrDiskSekBuf		;Sektorspeicher löschen.

			lda	#$ff			;Ersten Verzeichnissektor löschen.
			sta	diskBlkBuf +$01
			lda	#>diskBlkBuf
			sta	r4H
			lda	#<diskBlkBuf
			sta	r4L
			lda	#$28
			sta	r1L
			lda	#$03
			sta	r1H
			jsr	PutBlock

			lda	#$13			;Sektor $28/$13 löschen.
			sta	r1H			;Ist Borderblock für DeskTop 2.0!
			jsr	PutBlock
			lda	#$00
			rts

;*** BAM für RAM81-Laufwerk.
:BAM_81			b $52,$41,$4d,$20,$31,$35,$38,$31
			b $a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
			b $a0,$a0,$52,$44,$a0,$33,$44,$a0
			b $a0,$00,$00,$28,$13,$47,$45,$4f;$28/$13 Borderblock.
			b $53,$20,$66,$6f,$72,$6d,$61,$74
			b $20,$56,$31,$2e
			b $30,$00

:BAM_81a		b $28,$02,$44,$bb,$45,$41,$c0,$00
			b $00,$00,$00,$00,$00,$00,$00,$00
			b $28,$ff,$ff,$ff,$ff,$ff,$28,$ff
			b $ff,$ff,$ff,$ff,$28,$ff,$ff,$ff
			b $ff,$ff,$28,$ff,$ff,$ff,$ff,$ff
			b $28,$ff,$ff,$ff,$ff,$ff,$28,$ff
			b $ff,$ff,$ff,$ff,$28,$ff,$ff,$ff
			b $ff,$ff,$28,$ff,$ff,$ff,$ff,$ff
			b $28,$ff,$ff,$ff,$ff,$ff,$28,$ff
			b $ff,$ff,$ff,$ff,$28,$ff,$ff,$ff
			b $ff,$ff,$28,$ff,$ff,$ff,$ff,$ff
			b $28,$ff,$ff,$ff,$ff,$ff,$28,$ff
			b $ff,$ff,$ff,$ff,$28,$ff,$ff,$ff
			b $ff,$ff,$28,$ff,$ff,$ff,$ff,$ff
			b $28,$ff,$ff,$ff,$ff,$ff,$28,$ff
			b $ff,$ff,$ff,$ff,$28,$ff,$ff,$ff
			b $ff,$ff,$28,$ff,$ff,$ff,$ff,$ff
			b $28,$ff,$ff,$ff,$ff,$ff,$28,$ff
			b $ff,$ff,$ff,$ff,$28,$ff,$ff,$ff
			b $ff,$ff,$28,$ff,$ff,$ff,$ff,$ff
			b $28,$ff,$ff,$ff,$ff,$ff,$28,$ff
			b $ff,$ff,$ff,$ff,$28,$ff,$ff,$ff
			b $ff,$ff,$28,$ff,$ff,$ff,$ff,$ff
			b $28,$ff,$ff,$ff,$ff,$ff,$28,$ff
			b $ff,$ff,$ff,$ff,$28,$ff,$ff,$ff
			b $ff,$ff,$28,$ff,$ff,$ff,$ff,$ff
			b $28,$ff,$ff,$ff,$ff,$ff,$28,$ff
			b $ff,$ff,$ff,$ff,$28,$ff,$ff,$ff
			b $ff,$ff,$28,$ff,$ff,$ff,$ff,$ff
			b $28,$ff,$ff,$ff,$ff,$ff,$28,$ff
			b $ff,$ff,$ff,$ff,$28,$ff,$ff,$ff
			b $ff,$ff,$23,$f0,$ff,$f7,$ff,$ff

;*** Laufwerkstyp ermitteln.
:TestDriveType		LoadW	r0,$e580		;Auf 1541/71 testen.
			jsr	GetDriveType
			cpx	#$00			;Fehler aufgetreten ?
			bne	l0f59			;Ja, Ende...
			cmp	#$00			;Laufwerk erkannt ?
			bne	l0f59			;Ja, weiter...

			LoadW	r0,$a6c0		;Auf 1581 testen.
			jsr	GetDriveType

:l0f59			cpx	#$00			;Fehler aufgetreten ?
			bne	l0f74			;Ja, Abbruch...
			tax

			lda	#$01			;Kennbyte für #1541.
			cpx	#$41			;1541-Laufwerk erkannt ?
			beq	l0f76			;Ja, weiter...

			lda	#$02			;Kennbyte für #1571.
			cpx	#$71			;1571-Laufwerk erkannt ?
			beq	l0f76			;Ja, weiter...

			lda	#$03			;Kennbyte für #1581.
			ldx	#$81			;1581/FDx/HD-Laufwerk erkannt ?
			bne	l0f76			;Immer weiter...

;******************************************************************************
; Der "LDX #$81"-Befehl war ursprünglich ein "CPX #$81".
; War das Laufwerk dann keine #1581, wurde die Erkennung abgebrochen.
; Mit der Einführung der FDx/HD-Serie von CMD mußte der Befehl geändert
; werden, sonst würden diese Laufwerke nicht erkannt. Das Programm definiert
; dann ein nicht als 1581 erkanntes Laufwerk immer als #1581.
;******************************************************************************

			lda	#$ff			;Laufwerk nicht erkannt, Ende...
			bne	l0f76			;(Wird nie erreicht!)

:l0f74			lda	#$00			;Laufwerk erkannt, Ende...
:l0f76			rts

;*** Laufwerkstyp ermitteln.
;    Dazu Speicherbereich aus Floppy-ROM einlesen.
;    Anschließend innerhalb des gelesenen Bereichs die Kennung "15" suchen.
;    Das folgende Byte gibt dann den Laufwerkstyp an.
:GetDriveType		jsr	InitFloppyCom

			LoadW	r2,$0100		;Max. 256 Bytes testen.

:l0f82			jsr	ReadROM_Info		;ROM-Daten einlesen.
			cpx	#$00			;Diskettenfehler ?
			bne	l0fcb			;Ja, Abbruch.
			cmp	#$31			;Byte #1 von "15xx" gefunden ?
			bne	ContFindType		;Nein, weitersuchen.

			jsr	ReadROM_Info		;Nächstes Byte aus ROM einlesen.
			cmp	#$35			;Byte #2 von "15xx" gefunden ?
			bne	ContFindType		;Nein, weiter...

			jsr	ReadROM_Info		;Nächstes Byte aus ROM einlesen.
			sta	r1L			;Kennbyte speichern.
			and	#%01110000
			cmp	#$30			;Ist Zeichen eine Zahl ?
			bne	ContFindType		;Nein, weiter...

			lda	r1L			;Kennbyte wieder einlesen.
			asl				;High-Nibble isolieren.
			asl
			asl
			asl
			sta	r1L
			jsr	ReadROM_Info		;Nächstes Byte aus ROM einlesen.
			sta	r1H			;Kennbyte speichern.
			and	#%01110000
			cmp	#$30			;Ist Zeichen eine Zahl ?
			bne	ContFindType		;Nein, weiter...

			lda	r1H			;Laufwerkskennung berechnen.
			and	#$0f			;Rückgabe ist dann "41","71","81".
			ora	r1L
			ldx	#$00
			rts

;*** Kennung noch nicht gefunden, weitersuchen.
:ContFindType		lda	r2L
			bne	l0fc1
			dec	r2H
:l0fc1			dec	r2L
			lda	r2L
			ora	r2H
			bne	l0f82
			ldx	#$00
:l0fcb			rts

;*** Zeiger auf ROM-Adresse in Floppy-Befehl kopieren.
:InitFloppyCom		lda	r0H
			sta	ROM_AddrH
			lda	r0L
			sta	ROM_AddrL
			lda	#$20
			sta	PosROM_Data
			rts

;*** Speicherbereich aus Floppy-ROM einlesen.
:ReadROM_Info		ldy	PosROM_Data		;Zeiger auf Datenspeicher.
			cpy	#$20			;32 Bytes gelesen ?
			bcs	RdNxROMBytes		;Ja, die nächsten 32 Byte einlesen.
			lda	DrvROM_Data,y		;Nächstes Byte aus Datenspeicher.
			inc	PosROM_Data		;Zeiger auf nächstes Byte.
			ldx	#$00			;Flag: "Kein Fehler"...
			rts

;*** Weitere 32 Byte aus Floppy-ROM einlesen.
:RdNxROMBytes		jsr	InitForIO		;I/O aktivieren.

			LoadW	r0,FloppyCom
			jsr	SendFloppyCom		;"M-R"-befehl an Floppy senden.
			beq	l1000			;Kein Fehler, weiter...

			jsr	DoneWithIO		;Fehler, Abbruch...
			rts

:l1000			jsr	$ffae			;Laufwerk abschalten.

			lda	curDrive		;Laufwerk auf "Senden" umschalten.
			jsr	$ffb4
			lda	#$ff
			jsr	$ff96

			ldy	#$00
:l1010			jsr	$ffa5			;ROM-Kennung einlesen.
			sta	DrvROM_Data,y
			iny
			cpy	#$20
			bcc	l1010

			jsr	$ffab			;Laufwerk abschalten.

			lda	curDrive
			jsr	$ffb1

			lda	#$ef
			jsr	$ff93
			jsr	$ffae

			jsr	DoneWithIO

			lda	#$00			;Zeiger auf erstes Byte in
			sta	PosROM_Data		;Datenspeicher.

			clc				;"M-R"-Befehl auf die nächsten
			lda	#$20			;32 Byte im Floppy-ROM richten.
			adc	ROM_AddrL
			sta	ROM_AddrL
			bcc	l1042
			inc	ROM_AddrH
:l1042			clv				;Nächstes Byte aus Datenspeicher.
			bvc	ReadROM_Info

:FloppyCom		b "M-R"
:ROM_AddrL		b $00
:ROM_AddrH		b $00
:ROM_Bytes		b $20

;*** Befehl an Floppy senden.
:SendFloppyCom		lda	#$00			;Status-Byte löschen.
			sta	STATUS

			lda	curDrive
			jsr	$ffb1			;Laufwerk aktivieren.
			bit	STATUS			;Fehler aufgetreten ?
			bmi	l1071			;Ja, Abbruch...

			lda	#$ff
			jsr	$ff93			;Laufwerk auf Empfang schalten.
			bit	STATUS			;Fehler aufgetreten ?
			bmi	l1071			;Ja, Abbruch...

			ldy	#$00
:l1064			lda	(r0L),y			;Kommando-Befehl an Floppy senden.
			jsr	$ffa8
			iny
			cpy	#$06
			bcc	l1064

			ldx	#$00			;OK, Kein Fehler...
			rts

;*** Laufwerk nicht verfügbar!
:l1071			jsr	$ffae			;Laufwerk abschalten.
			ldx	#$0d			;Fehler: "Device not present".
			rts

;*** Laufwerke zählen. Achtung!
;    Max. zwei Laufwerke werden erkannt!
;    Schuld daran ist der Befehl "LDY #$01".
:CountDrives		lda	#$00			;Anzahl Laufwerke löschen.
			sta	numDrives

			ldy	#$01
:l107e			lda	driveType +0,y		;Laufwerk verfügbar ?
			beq	l1086			;Nein, weiter...
			inc	numDrives		;Anzahl Laufwerke +1.
:l1086			dey
			bpl	l107e
			rts

;*** Größe der Speichererweiterung testen.
:CheckSizeRAM		jsr	InitForIO		;I/O aktivieren.

			lda	#$00			;Größe dr RAM-Erweiterung mit
			sta	ramExpSize		;#0 vorbelegen.

			jsr	CheckForRL		;RAMLink vorhanden ?
			bcc	l109f			;Nein, weiter... ACHTUNG!
							;Ist eine RAMLink vorhanden muß
							;jetzt bereits das RL-Patch
							;installiert sein!

			lda	#$ff			;RL als vorhanden markieren.
			sta	RL_Aktiv
			jsr	FindRL_DACC		;RL-DACC-Partition suchen.
:l109f			jmp	l10c3			;Ende...

;******************************************************************************
;*** Überreste aus CONFIGURE 2.0.
;*** Erkennung der Größe einer C=REU. Wurde wohl von CMD einfach überschrieben
;*** und danach vernachlässigt...
;******************************************************************************

			lda	#$01
			sta	ramExpSize
			lda	#$00
			sta	r3L

:l10ab			jsr	Check64KBank
			bcc	l10c0

			lda	ramExpSize
			cmp	$238d
			beq	l10c3
			inc	ramExpSize
			inc	r3L
			clv
			bvc	l10ab
:l10c0			dec	ramExpSize
;******************************************************************************

:l10c3			jmp	DoneWithIO

;*** Prüfen ob REU-Bank vorhanden ist.
:Check64KBank		LoadW	r0,RAM_Test_Buf
			lda	#$00
			sta	r1L
			sta	r1H
			LoadW	r2,$0008		;Original-Daten aus REU einlesen
			jsr	FetchRAM		;und zwischenspeichern.

			LoadW	r0,RAM_TestData		;Testdaten in REU kopieren.
			jsr	StashRAM

			LoadW	r0,RAM_Test_Copy	;Testdaten wieder aus REU
			jsr	FetchRAM		;einlesen.

			lda	r3L
			pha
			lda	#$00
			sta	r3L

			LoadW	r0,RAM_Test_CTRL	;Daten aus Bank #0 einlesen (falls
			jsr	FetchRAM		; Bank nicht verfügbar, werden die
							; Daten in Bank #0 transferiert!)

			pla
			sta	r3L

			LoadW	r0,RAM_Test_Buf		;Original-Daten wieder zurück in
			jsr	StashRAM		;REU-Bank kopieren.

			ldy	#$07			;Testen ob Bank verfügbar ist.
:l1117			lda	RAM_TestData,y
			cmp	RAM_Test_Copy,y
			bne	l112d
			ldx	r3L
			beq	l1128
			cmp	RAM_Test_CTRL,y
			beq	l112d
:l1128			dey
			bpl	l1117
			sec				;Bank verfügbar.
			rts
:l112d			clc				;Bank nicht verfügbar.
			rts

:RAM_TestData		b "RAMCheck"

;*** Auf RAMLink prüfen.
:CheckForRL		ldx	$e0a9			;Byte aus C64-Kernal einlesen.
			cpx	#$78			;"SEI"-Befehl ?
			beq	InstallRL_Patch		;Ja, Patch installieren.
			clc				;Keine RL aktiv.
			rts

;*** RAMLink-Patches installieren.
:InstallRL_Patch	LoadW	r0,RL_DoRAMOp		;Zeiger auf neue ":DoRAMOp"-Routine.

			lda	DoRAMOp +2		;Zeiger auf alte ":DoRAMOp"-Routine.
			sta	r1H
			lda	DoRAMOp +1
			sta	r1L

			ldy	#$41			;Neue ":DoRAMOp"-Routine ins
			dey				;GEOS-Kernal kopieren.
:l1155			lda	(r0L),y
			sta	(r1L),y
			dey
			bpl	l1155

			LoadW	r0,RL_ReBoot		;Zeiger auf neue ":ReBoot"-Routine.
			LoadW	r1,$c01b		;Zeiger auf alte ":ReBoot"-Routine.

			ldy	#$26			;Neue ":ReBoot"-Routine ins
			dey				;GEOS-Kernal kopieren.
:l116f			lda	(r0L),y
			sta	(r1L),y
			dey
			bpl	l116f
			sec
			rts

:RL_Aktiv		b $00

;******************************************************************************
;Neue ":ReBootGEOS"-Routine. Wird im Bereich ab $c01b installiert.
;******************************************************************************
:RL_ReBoot		sei
			lda	#$36
			sta	CPU_DATA
			jsr	$e0a9

			ldy	#$09
:l1183			lda	$c037,y
			sta	$de01,y
			dey
			bpl	l1183

			jsr	$fe06
			jsr	$fe0f

			jmp	$6000

			b $91,$00,$60,$00
			b $7e,$00,$00,$05
			b $00,$00

;******************************************************************************
;Neue ":DoRAMOp"-Routine. Wird im Bereich ab $9eb8 installiert.
;******************************************************************************
:RL_DoRAMOp		ldx	#$0d
			lda	ramExpSize
			beq	l11df
			php
			sei
			lda	CPU_DATA
			pha
			lda	#$36
			sta	CPU_DATA
			jsr	$e0a9
			ldx	#$04
:l11b4			lda	zpage +1,x
			sta	$de01,x
			dex
			bne	l11b4
			lda	r2H
			sta	$de08
			lda	r2L
			sta	$de07
			lda	r3L
			sta	$de06
			stx	$de0a
			sty	$de01
			jsr	$fe06
			jsr	$fe0f
			pla
			sta	CPU_DATA
			plp
			lda	#$40
			ldx	#$00
:l11df			rts

;*** DACC-Partition auf RL suchen.
:FindRL_DACC		lda	#$01			;RL-Track.
			sta	RL_Track
			lda	#$00			;RL-Sektor.
			sta	RL_Sektor
			lda	#$ff			;RL-Partition.
			sta	RL_Part
			lda	#$80			;Ziel-Adresse C64-RAM.
			sta	C64_RAM_H
			lda	#$00
			sta	C64_RAM_L

:l11f9			jsr	GetRL_Sektor		;Partitions-Verzeichnis einlesen.

			lda	#$00
			sta	a0L
:l1200			lda	a0L
			asl
			asl
			asl
			asl
			asl
			tay
			lda	diskBlkBuf+$02,y	;Partitionstyp einlesen.
			cmp	#$07			;DACC-Partition ?
			bne	l122e			;Nein, weiter...

			lda	diskBlkBuf+$15,y	;Startadresse = $000000 ?
			ora	diskBlkBuf+$16,y
			ora	diskBlkBuf+$17,y
			bne	l122e			;Nein, weiter...

			lda	diskBlkBuf+$1d,y	;Größer als 16Mb ?
			beq	l1227			;Nein, weiter...

			lda	#$ff			;DACC hat volle RL-Größe.
			sta	ramExpSize
			clv
			bvc	l122d
:l1227			lda	diskBlkBuf+$1e,y	;Größe des DACC-Speichers festlegen.
			sta	ramExpSize
:l122d			rts

:l122e			inc	a0L
			lda	a0L			;Zeiger auf nächsten Eintrag.
			cmp	#$08			;Alle Einträge eines Sektors ?
			bne	l1200			;Nein, weiter...

			inc	RL_Sektor		;Zeiger auf nächsten Verzeichnis-
			lda	RL_Sektor		;Sektor richten.
			cmp	#$05			;Alle Sektoren durchsucht ?
			bne	l11f9			;Nein, weiter...
			rts

;*** Sektor aus RAMLink einlesen.
:GetRL_Sektor		php
			sei
			lda	CPU_DATA
			pha
			lda	#$36			;ROM aktivierern.
			sta	CPU_DATA

			jsr	$e0a9			;RL-Kernal aktivieren.

			lda	RL_Track		;Track/Sektor.
			sta	$de21
			lda	RL_Sektor
			sta	$de22

			lda	C64_RAM_H
			sta	$de24
			lda	C64_RAM_L		;Ziel-Addresse.
			sta	$de23

			lda	RL_Part			;RL-Partition.
			sta	$de25

			lda	#$01			;Bank für C128.
			sta	$de26

			lda	#$80			;RL-Job.
			sta	$de20
			lda	#$00			;Keine Ahnung wozu...
			sta	$de1a

			jsr	$fe09			;Job ausführen und
			jsr	$fe0f			;RL-Kernal abschalten.

			pla
			sta	CPU_DATA		;GEOS-Kernal wieder einschalten.
			plp
			rts

:RL_Track		b $00
:RL_Sektor		b $00
:RL_Part		b $00
:C64_RAM_L		b $00
:C64_RAM_H		b $00

;*** Daten für ReBoot in REU übertragen.
:InitRAM_ReBoot		lda	sysRAMFlg
			and	#$20			;Kernal in REU speichern ?
			beq	l129d			;Nein, weiter...
			lda	SysDrive
			jsr	SetNewDrive		;Boot-Laufwerk aktivieren.
			jsr	CopyKernal2REU		;GEOS-Kernal und
			jsr	CopyReBoot2REU		;ReBoot-Routine in REU kopieren.
:l129d			rts

;*** Aktuelles GEOS-Kernal in REU kopieren.
:CopyKernal2REU		jsr	SetLowBAdr		;Systemvariablen in REU kopieren.
			LoadB	r0H,$84			;C64: $8400-$88FF
			LoadB	r1H,$79			;REU: $7900-$7DFF
			LoadB	r2H,$05
			jsr	StashRAM

			bit	sysRAMFlg
			bvs	l12cb

			jsr	SetLowBAdr		;Laufwerkstreiber in REU kopieren.
			LoadB	r0H,$90			;C64: $9000-$9D7F
			LoadB	r1H,$83			;REU: $8300-$907F
			LoadW	r2 ,$0d80
			jsr	StashRAM

:l12cb			jsr	SetLowBAdr		;Kernal Teil #1 in REU kopieren.
			lda	#$80			;C64: $9D80-$9FFF
			sta	r0L			;REU: $B900-$BB7F
			sta	r2L
			LoadB	r0H,$9d
			LoadB	r1H,$b9
			LoadB	r3L,$00
			LoadB	r2H,$02
			jsr	StashRAM

			jsr	SetLowBAdr		;Kernal Teil #2 in REU kopieren.
			LoadW	r0,$bf40		;C64: $BF40-$CFFF
			LoadW	r1,$bb80		;REU: $BB80-$CC3F
			LoadW	r2,$10c0
			jsr	StashRAM

			LoadB	r4L,$30
			LoadW	r5 ,$d000
			LoadW	r0 ,$8000		;Kernal Teil #3 in REU kopieren.
			LoadW	r1 ,$cc40		;C64: $D000-$FFFF
			LoadW	r2 ,$0100		;REU: $CC40-$FC3F
			LoadB	r3L,$00

:l132d			ldy	#$00
:l132f			lda	(r5L),y
			sta	diskBlkBuf +$00,y
			iny
			bne	l132f
			jsr	StashRAM
			inc	r5H
			inc	r1H
			dec	r4L
			bne	l132d
			rts

;*** LOW -Bytes für StashRAM/FetchRAM-Routinen setzen.
:SetLowBAdr		lda	#$00
			sta	r0L
			sta	r1L
			sta	r2L
			sta	r3L
			rts

;*** ReBoot-Routine in REU kopieren.
;C64: $D000-$FFFF
;REU: $7E00-$82FF
:CopyReBoot2REU		jsr	SetLowBAdr

			lda	#>$7e00
			sta	r1H
			lda	#>$0500
			sta	r2H
			lda	#>GEOS_ReBootSys
			sta	r0H
			lda	#<GEOS_ReBootSys
			sta	r0L
			jmp	StashRAM

;*** GEOS-ReBoot-Routine.
;Start ab $6000 im RAM!
:GEOS_ReBootSys		sei
			cld
			ldx	#$ff
			txs
			lda	#$30
			sta	CPU_DATA

			LoadW	r0,DISK_BASE
			LoadW	r1,$8300
			LoadW	r2,$0d80
			jsr	$6231

			LoadW	r0,$9d80
			LoadW	r1,$b900
			LoadW	r2,$0280
			jsr	$6231

			LoadW	r0,$bf40
			LoadW	r1,$bb80
			LoadW	r2,$00c0
			jsr	$6231

			LoadW	r0,$c080
			LoadW	r1,$bcc0
			LoadW	r2,$0f80
			jsr	$6231

			LoadB	r4L,$30
			LoadW	r5 ,$d000

			LoadW	r0 ,$8000
			LoadW	r1 ,$cc40
			LoadW	r2 ,$0100

:l13fd			jsr	$6231

			ldy	#$00
:l1402			lda	diskBlkBuf +$00,y
			sta	(r5L),y
			iny
			bne	l1402
			inc	r5H
			inc	r1H
			dec	r4L
			bne	l13fd

;*** Variablenspeicher löschen.
			jsr	i_FillRam
			w	$0500
			w	$8400
			b	$00

;*** Bildschirm löschen.
:l141a			lda	#$00
			sta	r0L
			lda	#$a0
			sta	r0H
			ldx	#$7d
:l1424			ldy	#$3f
:l1426			lda	#$55
			sta	(r0L),y
			dey
			lda	#$aa
			sta	(r0L),y
			dey
			bpl	l1426
			lda	r0L
			clc
			adc	#$40
			sta	r0L
			bcc	l143d
			inc	r0H
:l143d			dex
			bne	l1424

;*** GEOS initiailisieren.
			jsr	FirstInit		;GEOS initialisieren.

			lda	#$ff			;GEOS-Boot-Vorgang.
			sta	firstBoot

			jsr	InitMouse		;Mausabfrage initialisieren.

;*** GEOS-Variablen aus REU einlesen.
			LoadW	r0,ramExpSize		;GEOS-Variablen aus REU in
			LoadW	r1,$7dc3		;C64-RAM kopieren.
			LoadW	r2,$0002
			jsr	$6231

			lda	sysFlgCopy		;System-Flag speichern.
			sta	sysRAMFlg

			LoadW	r0,year			;Datum aus REU einlesen.
			LoadW	r1,$7a16
			LoadW	r2,$0003
			lda	#$00
			sta	r3L
			jsr	FetchRAM

			lda	$dc08			;Uhrzeit starten.
			sta	$dc08

			LoadW	r0,driveType		;Laufwerkstypen aus REU einlesen.
			LoadW	r1,$798e
			LoadW	r2,$0004
			jsr	FetchRAM

			LoadW	r0,ramBase		;RAM-Adressen aus REU einlesen.
			LoadW	r1,$7dc7
			LoadW	r2,$0004
			jsr	FetchRAM

			LoadW	r0,driveData		;Laufwersdaten aus REU einlesen.
			LoadW	r1,$7dbf
			LoadW	r2,$0004
			jsr	FetchRAM

			LoadW	r0,PrntFileName		;Name des Druckertreibes aus
			LoadW	r1,$7965		;REU einlesen.
			LoadW	r2,$0011
			jsr	FetchRAM

			LoadW	r0,inputDevName		;Name des Eingabetreibes aus
			LoadW	r1,$7dcb		;REU einlesen.
			LoadW	r2,$0011
			jsr	FetchRAM

			LoadW	r0,curDrive		;Aktuelles Laufwerk aus
			LoadW	r1,$7989		;REU einlesen.
			LoadW	r2,$0001
			jsr	FetchRAM

;*** GEOS initiailisieren.
			jsr	InitForIO		;Warteschleife.

			lda	#$04
			sta	r0L
:l153a			ldy	#$00
			ldx	#$00
:l153e			dey
			bne	l153e
			dex
			bne	l153e
			dec	r0L
			bne	l153a

			jsr	DoneWithIO

			lda	curDrive		;Aktuelles Laufwerk merken.
			pha

			lda	#$0b			;Zeiger auf Laufwerk #11.
			sta	curDrive
			sta	curDevice

			lda	#$00			;Anzahl Laufwerke löschen.
			sta	numDrives
			sta	curDevice

			lda	#$08			;Sektor-Interleave setzen.
			sta	interleave
			jsr	SetDevice		;Laufwerk #8 aktivieren.

			lda	#$08			;Zeiger auf Laufwerk #8.
			sta	InitDriveVec

:l156a			ldy	InitDriveVec
			lda	driveType -8,y		;Laufwerk verfügbar ?
			beq	l1582			;Nein, weiter...
			cpy	#$0a			;Aktuelles Laufwerk < 10 ?
			bcs	l1579			;Nein, weiter...
			inc	numDrives		;Anzahl Laufwerke +1.

:l1579			lda	InitDriveVec
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	NewDisk			;Diskette öffnen.

:l1582			inc	InitDriveVec
			lda	InitDriveVec		;Zeiger auf nächstes Laufwerk.
			cmp	#$0c			;Alle Laufwerke getestet ?
			bcc	l156a			;Nein, weiter...

;******************************************************************************
;Fehler! Dieser Befehl würde auch ein Laufwerk #12 ansprechen!
;******************************************************************************
			beq	l156a
;******************************************************************************

			pla
			jsr	SetDevice		;Laufwerk zurücksetzen.
			jmp	EnterDeskTop		;Zurück zum DeskTop.

;*** FetchRAM-Routine für ReBoot.
:l1595			ldy	#$91
			php
			sei
			lda	CPU_DATA
			pha
			lda	#$36
			sta	CPU_DATA

			jsr	$e0a9

			ldx	#$04
:l15a5			lda	zpage +1,x
			sta	$de01   ,x
			dex
			bne	l15a5

			lda	r2H
			sta	$de08
			lda	r2L
			sta	$de07

			lda	#$00
			sta	$de06
			stx	$de0a
			sty	$de01

			jsr	$fe06
			jsr	$fe0f

			pla
			sta	CPU_DATA
			plp
			rts

;******************************************************************************
;*** Hauptmenü-Routine.
;******************************************************************************
:VLIR_BASE
:MenuRecData		b $69,$c4			;Rahmen für RAM-Optionen.
			w $00b4,$0136

			b $85,$8f			;Rahmen für ReBoot.
			w $011e,$0130

			b $a1,$ab			;Rahmen für MoveData.
			w $011e,$0130

			b $07,$62			;Rahmen für Laufwerk A:
			w $001e,$00a0

			b $07,$62			;Rahmen für Laufwerk B:
			w $00b4,$0136

			b $69,$c4			;Rahmen für Laufwerk C:
			w $001e,$00a0

			b $17,$21			;Max. 7 Anzeige-Optionen.
			w $0088,$009a

			b $21,$2b
			w $0088,$009a

			b $2b,$35
			w $0088,$009a

			b $35,$3f
			w $0088,$009a

			b $3f,$49
			w $0088,$009a

			b $49,$53
			w $0088,$009a

			b $53,$5d
			w $0088,$009a

			b $17,$21			;Max. 7 Anzeige-Optionen.
			w $011e,$0130

			b $21,$2b
			w $011e,$0130

			b $2b,$35
			w $011e,$0130

			b $35,$3f
			w $011e,$0130

			b $3f,$49
			w $011e,$0130

			b $49,$53
			w $011e,$0130

			b $53,$5d
			w $011e,$0130

			b $79,$83			;Max. 7 Anzeige-Optionen.
			w $0088,$009a

			b $83,$8d
			w $0088,$009a

			b $8d,$97
			w $0088,$009a

			b $97,$a1
			w $0088,$009a

			b $a1,$ab
			w $0088,$009a

			b $ab,$b5
			w $0088,$009a

			b $b5,$bf
			w $0088,$009a

;*** Bereich für Mausabfrage/Laufwerksanzeige ermitteln.
:SetMenuRecData		LoadW	r0,MenuRecData		;Zeiger auf Rechteck-Daten.

			cpy	#$00			;Rahmen für RAM-Optionen ?
			beq	l1689			;Ja, weiter...

:l167b			clc				;Zeiger auf nächsten Eintrag
			lda	#$06			;in Tabelle richten.
			adc	r0L
			sta	r0L
			bcc	l1686
			inc	r0H

:l1686			dey				;Rechteck-Daten erreicht ?
			bne	l167b			;Nein, weiter...

:l1689			ldy	#$05			;Rechteck-Daten kopieren.
:l168b			lda	(r0L),y
			sta	r2   ,y
			dey
			bpl	l168b
			rts

;*** Hauptmenü initialisieren.
:InitMainMenu		lda	version
			cmp	#$13			;GEOS-Version V1.2 ?
			bcc	l16a0			;Ja weiter...
			bit	c128Flag		;GEOS 128 ?
			bpl	l16ad			;Nein, weiter...
:l16a0			jsr	CloseRecordFile		;Systemdatei schließen.
			ldx	#>Dlg_WrongGEOS
			lda	#<Dlg_WrongGEOS
			jsr	SystemDlgBox		;Fehler, falsche GEOS-Version.
:l16aa			jmp	EnterDeskTop		;Zurück zum DeskTop.

:l16ad			lda	#ST_WR_FORE		;Nur Vordergrund-Bildschirm.
			sta	dispBufferOn

			lda	curDrive
			sta	SysDrive		;Start-Laufwerk speichern.
			tay
			lda	driveType -8,y
			sta	SysDrvType		;Start-Laufwerkstyp speichern.

			jsr	CheckSizeRAM		;Größe der REU testen.

			lda	#$01			;Anzahl der Laufwerke auf #1
			sta	numDrives		;zurücksetzen.

			jsr	LoadAllDrivers		;Diskettentreiber einlesen.
			txa				;Diskettenfehler ?
			bne	l16aa			;Ja, Abbruch...

			lda	sysRAMFlg		;RAM-Flag zwischenspeichern.
			sta	CurRAM_Flag

			ldy	#$03
:l16d4			lda	driveType +0,y		;Laufwerkstyp einlesen und
			jsr	TestRL_Part		;auf RAMLink testen.
			sta	driveType +0,y		;Neue Konfiguration speichern.
			sta	ConfigGEOS+0,y		;(RL ist dann Typ $23!)
			dey
			bpl	l16d4

			jsr	CountDrives		;Laufwerke zählen (immer #1 oder #2)

			jsr	i_GraphicsString	;Bildschirm löschen.
			b	NEWPATTERN,$02
			b	MOVEPENTO
			w	$0000
			b	$00
			b	RECTANGLETO
			w	$013f
			b	$c7
			b	NULL

			LoadW	r0,IconMenu
			jsr	DoIcons			;Dummy-Iconmenü aktivieren.

			LoadW	r0,SystemMenu
			lda	#$00
			jsr	DoMenu			;Hauptmenü aktivieren.

			jsr	DrawAllMenus

			lda	#>ChkMseButton
			sta	otherPressVec +1
			lda	#<ChkMseButton
			sta	otherPressVec +0
			lda	#>LdMenuBackScr
			sta	RecoverVector +1
			lda	#<LdMenuBackScr
			sta	RecoverVector +0
			rts

;*** Dummy-Iconmenü.
:IconMenu		b $01
			w $0005
			b $05

			w $0000
			b $27,$00,$01,$01
			w $0000

;*** Prüfen ob Laufwerk = Partition auf RAMLink.
:TestRL_Part		cmp	#$83
			bne	l1741
			lda	ramBase +0,y
			cmp	ramExpSize
			bcs	l173f
			lda	#$83			;RAM1581-Laufwerk.
			rts
:l173f			lda	#$23			;RAMLink-Partition.
:l1741			rts

;*** Laufwerkstreiber einlesen.
:LoadAllDrivers		jsr	Driver2DISK_BASE	;Laufwerkstreiber für aktuelles
							;Laufwerk nach DISK_BASE kopieren.
			lda	ramExpSize		;Speichererweiterung vorhanden ?
			beq	l175e			;Nein, weiter...

			lda	curDrive
			eor	#$01
			tay
			lda	driveType -8,y		;Zweites Laufwerk verfügbar ?
			beq	l175e			;Nein, weiter...
			jsr	SwapDrive		;Auf zweites Laufwerk wechseln.
			jsr	Driver2DISK_BASE	;Laufwerkstreiber einlesen.
			jsr	SwapDrive		;Auf erstes laufwerk zurück.

:l175e			lda	#$01			;Laufwerkstreiber #1541 laden.
			jsr	ReadDriverFile
			bne	l1789

			lda	#$02			;Laufwerkstreiber #1571 laden.
			jsr	ReadDriverFile
			bne	l1789

			lda	#$03			;Laufwerkstreiber #1581 laden.
			jsr	ReadDriverFile
			bne	l1789

			lda	ramExpSize		;Speichererweiterung verfügbar ?
			beq	l1786			;Nein, weiter...

			lda	#$81			;Laufwerkstreiber #RAMxyz laden.
			jsr	ReadDriverFile
			bne	l1789

			lda	#$83			;Laufwerkstreiber #RAMLink laden.
			jsr	ReadDriverFile
			bne	l1789

:l1786			jsr	CloseRecordFile		;Systemdatei schließen.
:l1789			rts

;*** Fehler: "Falsche GEOS-Version".
:Dlg_WrongGEOS		b $81
			b DBTXTSTR ,$0c,$20
			w l1799
			b DBTXTSTR ,$0c,$30
			w l17b8
			b OK       ,$01,$48
			b NULL

:l1799			b BOLDON,$22,"CONFIGURE",$22," is not applicable",NULL
:l17b8			b BOLDON,"to this version of GEOS KERNAL",NULL

;*** Menü-Daten anzeigen.
:DrawAllMenus		jsr	ViewMenuDrvA		;Laufwerksmodi für Laufwerk A:
			jsr	ViewMenuDrvB		;Laufwerksmodi für Laufwerk B:

			lda	ramExpSize		;Speichererweiterung vorhanden ?
			beq	l17e6			;Nein, weiter...
			jsr	ViewMenuDrvC		;Laufwerksmodi für Laufwerk C:

:l17e6			ldy	#$00
			jsr	DrawMenuRect
			jsr	ViewMenuRAM
			jsr	ExitTurbo
			rts

;*** Menü-Rechteck zeichnen.
:DrawMenuRect		jsr	SetMenuRecData		;Rechteck-Daten einlesen.

			lda	#$00
			jsr	SetPattern
			jsr	Rectangle		;Menü-Hintergrund löschen.

			lda	#$ff
			jsr	FrameRectangle		;Rahmen um Rechteck zeichnen.

			inc	r2H
			inc	r4L
			bne	l180a
			inc	r4H
:l180a			lda	#$ff
			jsr	FrameRectangle		;Schatten zeichnen.

			dec	r2H
			ldx	#r4L
			jsr	Ddec			;Rechteck-Daten zurücksetzen.
			rts

;*** Laufwerksauswahl anzeigen.
:ViewSlctDrive		pha
			jsr	SetMenuRecData
			pla
			jsr	SetPattern
			jsr	Rectangle
			lda	#$ff
			jmp	FrameRectangle

;*** Prüfen ob Modus angeklickt wurde und entsprechende Routine ausführen.
;    Die folgende Routine findet sich Byte für Byte wieder ab dem Label
;    ":TestSlctDrvMode", kann also auch entfallen!
:TestSlctDrvMod2	lda	Vec_DrvInfoTab+1
			sta	r15H
			lda	Vec_DrvInfoTab+0
			sta	r15L

			ldy	#$00
			lda	(r15L),y
			sta	CurrentDrive
			jsr	SetNewDrive

			ldy	CurrentDrive
			lda	driveType -8,y
			sta	InstallType
			jmp	l1864

;*** Prüfen ob laufwerksmodus angeklickt wurde und
;    entsprechende Routine ausführen.
:TestSlctDrvMode	lda	Vec_DrvInfoTab+1
			sta	r15H
			lda	Vec_DrvInfoTab+0
			sta	r15L

			ldy	#$00
			lda	(r15L),y
			sta	CurrentDrive
			jsr	SetNewDrive

			ldy	CurrentDrive
			lda	driveType -8,y
			sta	InstallType

:l1864			ldy	#$01
			lda	(r15L),y
			sta	Vec_MenuRecData

:l186b			clc
			lda	#$02
			adc	r15L
			sta	r15L
			bcc	l1876
			inc	r15H

:l1876			ldy	#$00
			lda	(r15L),y
			sta	r13L
			iny
			lda	(r15L),y
			sta	r13H
			beq	l18a5

			ldy	Vec_MenuRecData
			jsr	SetMenuRecData
			jsr	IsMseInRegion
			beq	l189f

			ldy	#$03
			lda	(r13L),y
			sta	r0L
			iny
			lda	(r13L),y
			sta	r0H
			jsr	l18a6
			clv
			bvc	l18a5

:l189f			inc	Vec_MenuRecData
			clv
			bvc	l186b
:l18a5			rts
:l18a6			jmp	(r0)

:Titel_DriveA		b BOLDON,"Drive A",NULL
:Titel_DriveB		b BOLDON,"Drive B",NULL
:Titel_DriveC		b BOLDON,"Drive C",NULL

;*** Bildschirm-Inhalte erneuern.
:ReDrawAllMenus		ldy	#$03
			jsr	ClearMenuRec		;Menü-Bereich Laufwerk A: löschen.
			ldy	#$04
			jsr	ClearMenuRec		;Menü-Bereich Laufwerk B: löschen.

			lda	ramExpSize		;Speichererweiterung vorhanden ?
			beq	l18d8			;Nein, weiter...
			ldy	#$05
			jsr	ClearMenuRec		;Menü-Bereich Laufwerk C: löschen.

:l18d8			jsr	ViewModesDrvA
			jsr	ViewModesDrvB

			lda	ramExpSize		;Speichererweiterung vorhanden ?
			beq	l18e6			;Nein, weiter...
			jsr	ViewModesDrvC

:l18e6			jsr	ExitTurbo
			rts

;*** Menü für Laufwerk A: anzeigen.
:ViewMenuDrvA		ldy	#$03
			jsr	DrawMenuRect
			LoadW	r0 ,Titel_DriveA
			LoadB	r1H,$13
			LoadW	r11,$004f
			jsr	PutString

:ViewModesDrvA		lda	#>ModeTabDrvA
			sta	Vec_DrvInfoTab+1
			lda	#<ModeTabDrvA
			sta	Vec_DrvInfoTab+0
			jsr	GetDrvModes
			rts

;*** Menü für Laufwerk B: anzeigen.
:ViewMenuDrvB		ldy	#$04
			jsr	DrawMenuRect
			LoadW	r0 ,Titel_DriveB
			LoadB	r1H,$13
			LoadW	r11,$00e5
			jsr	PutString

:ViewModesDrvB		lda	#>ModeTabDrvB
			sta	Vec_DrvInfoTab+1
			lda	#<ModeTabDrvB
			sta	Vec_DrvInfoTab+0
			jsr	GetDrvModes
			rts

;*** Menü für Laufwerk C: anzeigen.
:ViewMenuDrvC		ldy	#$05
			jsr	DrawMenuRect
			LoadW	r0 ,Titel_DriveC
			LoadB	r1H,$75
			LoadW	r11,$004f
			jsr	PutString

:ViewModesDrvC		lda	#>ModeTabDrvC
			sta	Vec_DrvInfoTab+1
			lda	#<ModeTabDrvC
			sta	Vec_DrvInfoTab+0
			jsr	GetDrvModes
			rts

;*** Anzeige-Option löschen.
:ClearMenuRec		jsr	SetMenuRecData		;Menügrenzen berechnen.

			clc				;Grenzen um 2 Pixel nach innen
			lda	#$02			;verkleinern.
			adc	r3L
			sta	r3L
			bcc	l1976
			inc	r3H

:l1976			sec
			lda	r4L
			sbc	#$02
			sta	r4L
			lda	r4H
			sbc	#$00
			sta	r4H

			lda	r2L
			clc
			adc	#$0f
			sta	r2L

			lda	r2H
			sec
			sbc	#$02
			sta	r2H

			lda	#$00
			jsr	SetPattern
			jsr	Rectangle		;Menü-Bereich löschen.
			rts

;*** RAM-Menu anzeigen.
:ViewMenuRAM		jsr	PrntSizeREU		;Größe der REU ausgeben.
			lda	ramExpSize		;Speichererweiterung vorhanden ?
			beq	l19a8			;Nein, weiter...
			jsr	OptMoveData		;MoveData-Status anzeigen.
			jsr	OptReBoot		;ReBoot-Status anzeigen.
:l19a8			rts

;*** MoveData-Option anzeigen.
:OptMoveData		LoadW	r0 ,l19e6
			LoadB	r1H,$a4
			LoadW	r11,$00be
			jsr	PutString

			LoadW	r0 ,l19ef
			LoadB	r1H,$b2
			LoadW	r11,$00be
			jsr	PutString

;*** Neue MoveData-Option anzeigen.
:NewOptMoveData		lda	sysRAMFlg
			and	#%10000000
			beq	l19e0
			lda	#$02
:l19e0			ldy	#$02
			jsr	ViewSlctDrive
			rts

:l19e6			b BOLDON,"DMA for",NULL
:l19ef			b $22,"MoveData",$22,NULL

;*** ReBoot-Option anzeigen.
:OptReBoot		LoadW	r0 ,l1a20
			LoadB	r1H,$8d
			LoadW	r11,$00be
			jsr	PutString

;*** Neue ReBoot-Option anzeigen.
:NewOptReBoot		lda	sysRAMFlg
			and	#%00100000
			beq	l1a1a
			lda	#$02
:l1a1a			ldy	#$01
			jsr	ViewSlctDrive
			rts

:l1a20			b BOLDON,"RAM Reboot",NULL

;*** Mausklick auswerten.
:ChkMseButton		lda	mouseData		;Maustaste gedrückt ?
			bpl	l1a32			;Ja, weiter...
			rts				;Ende...

:l1a32			lda	#$00			;Flag für RAM-Laufwerke löschen.
			sta	Cnt_GEOS_Drives

			jsr	TestOptMoveData
			jsr	ChkSlctDrvA
			jsr	ChkSlctDrvB

			lda	ramExpSize		;Speichererweiterung vorhanden ?
			beq	l1a48			;Nein, weiter...
			jsr	ChkSlctDrvC

:l1a48			lda	Cnt_GEOS_Drives		;RAM-Laufwerke gefunden ?
			beq	l1a53			;Nein, weiter...
			jsr	CountDrives		;Laufwerke zählen.
			jsr	ReDrawAllMenus
:l1a53			rts

:Cnt_GEOS_Drives	b $00

;*** Mausklick auf Laufwerksmodi auswerten.
:ChkSlctDrvA		LoadW	Vec_DrvInfoTab,ModeTabDrvA
			jsr	TestSlctDrvMode
			rts

:ChkSlctDrvB		LoadW	Vec_DrvInfoTab,ModeTabDrvB
			jsr	TestSlctDrvMode
			rts

:ChkSlctDrvC		LoadW	Vec_DrvInfoTab,ModeTabDrvC
			jsr	TestSlctDrvMod2
			rts

;*** MoveData-Option wechseln.
:TestOptMoveData	lda	ramExpSize		;Speichererweiterung vorhanden ?
			beq	l1aba			;Nein, weiter...

			ldy	#$02
			jsr	SetMenuRecData		;Abfragebereich festlegen.
			jsr	IsMseInRegion		;Mausklick in Bereich ?
			beq	TestOptReBoot		;Nein, Ende...

			lda	sysRAMFlg		;MoveData-Status wechseln.
			eor	#$80
			sta	sysRAMFlg
			sta	sysFlgCopy
			sta	CurRAM_Flag
			jmp	NewOptMoveData

;*** ReBoot-Option wechseln.
:TestOptReBoot		ldy	#$01
			jsr	SetMenuRecData		;Abfragebereich festlegen.
			jsr	IsMseInRegion		;Mausklick in Bereich ?
			beq	l1aba			;Nein, Ende...

			lda	sysRAMFlg		;ReBoot-Status wechseln.
			eor	#$20
			sta	sysRAMFlg
			sta	sysFlgCopy
			sta	CurRAM_Flag
			jmp	NewOptReBoot

:l1aba			rts

;*** Größe der der Speichererweiterung anzeigen.
:PrntSizeREU		LoadW	r0 ,l1aed
			LoadB	r1H,$75
			LoadW	r11,$00be
			jsr	PutString		;Infotext ausgeben.

			lda	ramExpSize
			sta	r0L
			lda	#$40
			sta	r2L
			ldx	#$02
			ldy	#$06
			jsr	BBMult			;Größe der REU in Kbyte berechnen.

			lda	#%11000000
			jsr	PutDecimal		;Größe ausgeben.
			lda	#"K"
			jsr	PutChar
			rts

:l1aed			b BOLDON
			b "RAM expansion: ",NULL

;*** CONFIGURE verlassen.
:Menu_ExitConfig	jsr	DoPreviousMenu		;Zurück zum Hauptmenu.

			lda	driveType +0		;Laufwerk A: vorhanden ?
			beq	l1b08			;Nein, weiter...
			bpl	l1b10			;Ja, zurück zu GEOS.

:l1b08			lda	driveType +1		;Laufwerk A: vorhanden ?
			beq	l1b0f			;Nein, Beenden nicht möglich.
			bpl	l1b10			;Ja, zurück zu GEOS.
:l1b0f			rts

:l1b10			ldy	SysDrive
			lda	driveType -8,y		;Startlaufwerk noch vorhanden ?
			bne	l1b1e			;Ja, weiter...
			tya				;auf anderes Laufwerk umschalten.
			eor	#$01
			sta	SysDrive
:l1b1e			jmp	ExitToDeskTop		;GEOS-Daten definieren und Ende...

;******************************************************************************
;Routine wird nicht angesprungen!
;******************************************************************************
;*** Systemtext ausgeben.
:DoErrTextBox		ldx	#>l1b28
			lda	#<l1b28
			jmp	SystemDlgBox

:l1b28			b $81
			b DBVARSTR,$10,$20
			b r5L
			b OK      ,$01,$48
			b NULL
;******************************************************************************

;*** Programm-Information anzeigen.
:Menu_ViewInfo		jsr	DoPreviousMenu		;Zurück zum Hauptmenu.
			ldx	#>Dlg_InfoBox
			lda	#<Dlg_InfoBox
			jsr	SystemDlgBox		;Infobox anzeigen.
			rts

:Dlg_InfoBox		b $81
			b DBTXTSTR,$08,$10
			w l1b58
			b DBTXTSTR,$08,$20
			w l1b6c
			b DBTXTSTR,$08,$2c
			w l1b86
			b DBTXTSTR,$08,$3e
			w l1b9a
			b DBTXTSTR,$08,$4a
			w l1bb7
			b DBSYSOPV
			b NULL

:l1b58			b BOLDON,OUTLINEON,"RL CONFIGURE 2.1",PLAINTEXT,NULL
:l1b6c			b BOLDON          ,"Copyright (C) 1986-1990,",NULL
:l1b86			b                  "Berkeley Softworks.",NULL
:l1b9a			b                  "Portions Copyright (C) 1991,",NULL
:l1bb7			b                  "Creative Micro Designs, Inc."
			b PLAINTEXT,NULL

;*** Konfiguration speichern.
:Menu_SaveConfig	jsr	DoPreviousMenu		;Zurück zum Hauptmenü.

			lda	SysDrive
			jsr	SetNewDrive		;Startlaufwerk aktivieren.

			LoadW	r0,SysFileName
			jsr	OpenRecordFile		;Systemdatei öffnen.
			txa				;Diskettenfehler ?
			bne	ConfigSaveError		;Ja, Abbruch..

			lda	#$00
			jsr	PointRecord		;Zeiger auf ersten Datensatz.

			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Ersten Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	ConfigSaveError		;Ja, Abbruch..

			ldy	#$04
:l1c01			lda	ConfigGEOS +0,y		;Konfiguration am Anfang
			sta	diskBlkBuf +2,y		;des Programms speichern.
			dey
			bpl	l1c01

			jsr	PutBlock		;Sektor zurück auf Disk schreiben.
			txa				;Diskettenfehler ?
			bne	ConfigSaveError		;Ja, Abbruch..

			jmp	CloseRecordFile		;Systemdatei schließen.

;*** Konfiguration kann nicht gespeichert werden.
:ConfigSaveError	ldx	#>Dlg_SaveError
			lda	#<Dlg_SaveError
			jmp	SystemDlgBox

:Dlg_SaveError		b $81
			b DBTXTSTR,$0c,$20
			w l1c29
			b DBTXTSTR,$0c,$30
			w l1c48
			b OK      ,$01,$48
			b NULL

:l1c29			b BOLDON,"Unable to save configuration:",NULL
:l1c48			b BOLDON,"Can't find ",$22,"CONFIGURE",$22," file.",NULL

;*** Hauptmenu.
:SystemMenu		b $00
			b $0e
			w $0000
			w $0015

			b $01 ! HORIZONTAL ! UN_CONSTRAINED

			w l1c72
			b DYN_SUB_MENU
			w SvMenuBackScr

:l1c72			b "file",NULL
:l1c77			b "disk",NULL

:SubMenuDef		b $0e
			b $38
			w $0000
			w $0062

			b $03 ! VERTICAL ! UN_CONSTRAINED

			w l1c92
			b MENU_ACTION
			w Menu_SaveConfig

			w l1ca5
			b MENU_ACTION
			w Menu_ViewInfo

			w l1cb4
			b MENU_ACTION
			w Menu_ExitConfig

:l1c92			b "save configuration",NULL
:l1ca5			b "CONFIGURE info",NULL
:l1cb4			b "quit",NULL

;*** Laufwerksmodi einlesen und anzeigen.
:GetDrvModes		lda	Vec_DrvInfoTab+1	;Zeiger auf Tabelle mit Laufwerks-
			sta	r15H			;Informationen.
			lda	Vec_DrvInfoTab+0
			sta	r15L

			ldy	#$00
			lda	(r15L),y		;Laufwerk einlesen und als
			sta	CurrentDrive		;aktuelles Laufwerk festlegen.
			tay
			lda	driveType -8,y
			sta	InstallType		;Laufwerkstyp festlegen.

			ldy	#$01			;Offset auf Tabelle ":MenuRecData"
			lda	(r15L),y		;für Position der Anzeigefelder
			sta	Vec_MenuRecData		;einlesen und zwischenspeichern.

			clc				;Zeiger auf Tabelle mit Einsprungs-
			lda	#$02			;Adressen für Laufwerksmodi setzen.
			adc	r15L
			sta	r15L
			bcc	l1ce3
			inc	r15H

:l1ce3			ldy	#$0b			;Tabelle mit Laufwerksmodi löschen.
:l1ce5			lda	#$00
			sta	(r15L),y
			dey
			bpl	l1ce5

			jsr	Mode_NoDrive
			jsr	DrvModeInTab
			jsr	Mode_1541
			jsr	DrvModeInTab
			jsr	Mode_Shadow1541
			jsr	DrvModeInTab
			jsr	Mode_1571
			jsr	DrvModeInTab
			jsr	Mode_1581
			jsr	DrvModeInTab
			jsr	Mode_Shadow1581
			jsr	DrvModeInTab
			jsr	Mode_RAM1541
			jsr	DrvModeInTab
			jsr	Mode_RAM1571
			jsr	DrvModeInTab
			jsr	Mode_RAM1581
			jsr	DrvModeInTab
			jsr	Mode_RAMLink
			jsr	DrvModeInTab

			lda	Vec_DrvInfoTab+1
			sta	r15H
			lda	Vec_DrvInfoTab+0
			sta	r15L
			clc
			lda	#$02
			adc	r15L
			sta	r15L
			bcc	l1d3d
			inc	r15H

;*** Laufwerksmodi innerhalb Menü-Rahmen anzeigen.
:l1d3d			ldy	#$00
			lda	(r15L),y
			sta	r13L
			iny
			lda	(r15L),y
			sta	r13H			;Modi verfügbar ?
			beq	l1da5			;Nein, Ende...

			ldy	Vec_MenuRecData		;Modi-Rahmen zeichnen.
			jsr	SetMenuRecData

			lda	r2L			;X/Y-Koordinate für Textausgabe des
			clc				;aktuellen Laufwerksmodi berechnen.
			adc	#$08
			sta	r1H
			sec
			lda	r3L
			sbc	#$5a
			sta	r11L
			lda	r3H
			sbc	#$00
			sta	r11H

			ldy	#$00
			lda	(r13L),y
			pha
			iny
			lda	(r13L),y		;Zeiger auf Modi-Text setzen.
			sta	r0L
			iny
			lda	(r13L),y
			sta	r0H

			lda	r15H
			pha
			lda	r15L
			pha
			jsr	PutString		;Bezeichnung ausgeben.
			pla
			sta	r15L
			pla
			sta	r15H

			ldy	Vec_MenuRecData
			pla
			cmp	InstallType		;Modus = Aktueller Modus ?
			bne	l1d8f			;Nein, weiter...

			lda	#$02			;Aktiven Laufwerks-Modus anzeigen.
			bne	l1d91
:l1d8f			lda	#$00			;Inaktiven Laufwerks-Modus anzeigen.
:l1d91			jsr	ViewSlctDrive		;Laufwerksmodus anzeigen.

			clc
			lda	#$02
			adc	r15L
			sta	r15L
			bcc	l1d9f
			inc	r15H
:l1d9f			inc	Vec_MenuRecData
			clv
			bvc	l1d3d			;Nächsten Modus ausgeben.

:l1da5			rts

;*** Laufwerksmodus in Tabelle übertragen.
:DrvModeInTab		dey				;Laufwerksmodi übernehmen ?
			bmi	l1dc3			;Nein, weiter...
			lda	TabDrvInfoH,y		;Zeiger auf Laufwerksdaten der
			tax				;Laufwerkstypen einlesen und in
			lda	TabDrvInfoL,y		;Tabelle mit möglichen Laufwerks-
			ldy	#$00			;modi übernehmen.
			sta	(r15L),y
			iny
			txa
			sta	(r15L),y
			clc				;Zeiger auf nächsten Eintrag.
			lda	#$02
			adc	r15L
			sta	r15L
			bcc	l1dc3
			inc	r15H
:l1dc3			rts

:ModeTabDrvA		b $08				;Geräteadresse Laufwerk A:
			b $06				;Zeiger auf MenuRecData.
			b $00,$00,$00,$00		;Laufwerksmodi #1 bis #7.
			b $00,$00,$00,$00
			b $00,$00,$00,$00
			b $00,$00,$00,$00

:ModeTabDrvB		b $09				;Geräteadresse Laufwerk B:
			b $0d				;Zeiger auf MenuRecData.
			b $00,$00,$00,$00		;Laufwerksmodi #1 bis #7.
			b $00,$00,$00,$00
			b $00,$00,$00,$00
			b $00,$00,$00,$00

:ModeTabDrvC		b $0a				;Geräteadresse Laufwerk C:
			b $14				;Zeiger auf MenuRecData.
			b $00,$00,$00,$00		;Laufwerksmodi #1 bis #7.
			b $00,$00,$00,$00
			b $00,$00,$00,$00
			b $00,$00,$00,$00

;*** Zeiger auf Laufwerksdaten.
:TabDrvInfoL		b <l1e0e
			b <l1e1c
			b <l1e26
			b <l1e39
			b <l1e47
			b <l1e51
			b <l1e5b
			b <l1e70
			b <l1e7e
			b <l1e8c

:TabDrvInfoH		b >l1e0e
			b >l1e1c
			b >l1e26
			b >l1e39
			b >l1e47
			b >l1e51
			b >l1e5b
			b >l1e70
			b >l1e7e
			b >l1e8c

;*** Laufwerksdaten.
:l1e0e			b $00
			w l1e13
			w TurnOffDrive
:l1e13			b "No Drive",NULL

:l1e1c			b $01
			w l1e21
			w Install_1541
:l1e21			b "1541",NULL

:l1e26			b $41
			w l1e2b
			w Install_DskCache
:l1e2b			b "Shadowed 1541",NULL

:l1e39			b $81
			w l1e3e
			w Install_RAM1541
:l1e3e			b "RAM 1541",NULL

:l1e47			b $02
			w l1e4c
			w Install_1571
:l1e4c			b "1571",NULL

:l1e51			b $03
			w l1e56
			w Install_1581
:l1e56			b "1581",NULL

:l1e5b			b $43
			w l1e60
			w Install_DirChache
:l1e60			b "Dir Shadow 1581",NULL

:l1e70			b $82
			w l1e75
			w Install_RAM1571
:l1e75			b "RAM 1571",NULL

:l1e7e			b $83
			w l1e83
			w Install_RAM1581
:l1e83			b "RAM 1581",NULL

:l1e8c			b $23
			w l1e91
			w Install_RAMLink
:l1e91			b "RL/RD 1581 part.",NULL

;*** Modus "Kein Laufwerk" möglich ?
:Mode_NoDrive		ldy	InstallType
			beq	l1ea9
			ldy	#$01
:l1ea9			rts

;*** Modus "1541" möglich ?
:Mode_1541		lda	InstallType
			cmp	#$01
			beq	l1eb9
			cmp	#$41
			beq	l1eb9
			cmp	#$00
			bne	l1ebc
:l1eb9			ldy	#$02
			rts
:l1ebc			ldy	#$00
			rts

;*** Modus "Shadow1541" möglich ?
:Mode_Shadow1541	lda	InstallType
			cmp	#$41
			beq	l1ed2
			cmp	#$01
			bne	l1ed5
			lda	#$41
			jsr	ADDR_DrvInREU
			txa
			bne	l1ed5
:l1ed2			ldy	#$03
			rts
:l1ed5			ldy	#$00
			rts

;*** Modus "RAM1541" möglich ?
:Mode_RAM1541		lda	InstallType
			cmp	#$81
			beq	l1eeb
			cmp	#$00
			bne	l1eee
			lda	#$81
			jsr	ADDR_DrvInREU
			txa
			bne	l1eee
:l1eeb			ldy	#$04
			rts
:l1eee			ldy	#$00
			rts

;*** Modus "1571" möglich ?
:Mode_1571		lda	InstallType
			cmp	#$02
			beq	l1efc
			cmp	#$00
			bne	l1eff
:l1efc			ldy	#$05
			rts
:l1eff			ldy	#$00
			rts

;*** Modus "1581" möglich ?
:Mode_1581		lda	InstallType
			cmp	#$03
			beq	l1f0d
			cmp	#$00
			bne	l1f10
:l1f0d			ldy	#$06
			rts
:l1f10			ldy	#$00
			rts

;*** Modus "Shadow1581" möglich ?
:Mode_Shadow1581	lda	InstallType
			cmp	#$43
			beq	l1f26
			cmp	#$03
			bne	l1f29
			lda	#$43
			jsr	ADDR_DrvInREU
			txa
			bne	l1f29
:l1f26			ldy	#$07
			rts
:l1f29			ldy	#$00
			rts

;*** Modus "RAM1571" möglich ?
:Mode_RAM1571		lda	InstallType
			cmp	#$82
			beq	l1f3f
			cmp	#$00
			bne	l1f42
			lda	#$82
			jsr	ADDR_DrvInREU
			txa
			bne	l1f42
:l1f3f			ldy	#$08
			rts
:l1f42			ldy	#$00
			rts

;*** Modus "RAM1581" möglich ?
:Mode_RAM1581		lda	InstallType
			cmp	#$83
			beq	l1f58
			cmp	#$00
			bne	l1f5b
			lda	#$83
			jsr	ADDR_DrvInREU
			txa
			bne	l1f5b
:l1f58			ldy	#$09
			rts
:l1f5b			ldy	#$00
			rts

;*** Modus "RAMLink-Partition" möglich ?
:Mode_RAMLink		lda	InstallType
			cmp	#$23
			beq	l1f7a
			cmp	#$00
			bne	l1f7d
			ldy	#$02
:l1f6b			lda	driveType +0,y
			cmp	#$23
			beq	l1f7d
			dey
			bpl	l1f6b
			jsr	Get1stRL_Part
			bcc	l1f7d
:l1f7a			ldy	#$0a
			rts
:l1f7d			ldy	#$00
			rts

;*** Laufwerk abschalten.
:TurnOffDrive		lda	InstallType		;Laufwerk vorhanden ?
			beq	l1fb2			;Nein, weiter...

			jsr	PurgeTurbo		;Turbo-Modus abschalten.

			lda	InstallType		;RAM-Laufwerk ?
			bmi	l1fa6			;Ja, weiter...

			lda	CurrentDrive
			clc
			adc	#$39
			sta	l2025			;Laufwerksbuchstaben ermitteln.

			ldx	#>Dlg_TurnOffDrv
			lda	#<Dlg_TurnOffDrv
			jsr	SystemDlgBox		;Dialogbox: "Laufwerk abschalten".

			lda	r0L
			cmp	#CANCEL			;Abbruch ?
			beq	l1fb2			;Ja, Ende...

			jsr	WaitLoop		;Systempause einlegen.

:l1fa6			lda	CurrentDrive
			jsr	ClearDrvData		;Laufwerk löschen.

			jsr	UpdateDriveData		;Laufwerksinformation updaten.
			dec	Cnt_GEOS_Drives		;Anzahl Laufwerke -1.

:l1fb2			rts

;*** Warteschleife.
:WaitLoop		php
			sei
			lda	#>l1fde
			sta	intBotVector +1
			lda	#<l1fde
			sta	intBotVector +0
			lda	#$00
			sta	LoopCount +1
			lda	#$78
			sta	LoopCount +0
			plp

:l1fca			lda	LoopCount +0
			ora	LoopCount +1
			bne	l1fca

			php
			sei
			lda	#$00
			sta	intBotVector +0
			sta	intBotVector +1
			plp
			rts

:l1fde			lda	LoopCount +0
			bne	l1fe6
			dec	LoopCount +1
:l1fe6			dec	LoopCount +0
			rts

:LoopCount		w $0000

:l1fec			b BOLDON
			b "If you are able to, please",NULL
:l2008			b "turn OFF and/or unplug drive "
:l2025			b "x.",NULL

:Dlg_TurnOffDrv		b $81
			b DBTXTSTR,$0c,$20
			w l1fec
			b DBTXTSTR,$0c,$30
			w l2008
			b OK      ,$01,$48
			b CANCEL  ,$11,$48
			b NULL

:Cnt_RealDrives		b $00

;*** Laufwerke zählen, nicht vorhandene (echte) Laufwerke löschen.
:UpdateDriveData	lda	#$00
			sta	Cnt_RealDrives
			lda	#$08
			jsr	UpdateCurDrive
			lda	#$09
			jsr	UpdateCurDrive
			lda	#$0a
			jsr	UpdateCurDrive
			lda	Cnt_RealDrives
			sta	numDrives
			rts

;*** Aktuelles Laufwerk testen.
:UpdateCurDrive		tay				;Zeiger auf Laufwerkstyp-Tabelle.
			lda	driveType -8,y		;Aktuellen Laufwerkstyp einlesen.
			beq	l206b			; => $00 = Nicht vorhanden.
			bmi	l2068			; => $8x = RAM-Laufwerk, weiter...
			tya				;Laufwerksadresse übergeben.
			jsr	IsDriveOnline		;Neues laufwerk aktivieren.
			bne	l2068			;Laufwerk verfügbar ? Ja, weiter...
			jsr	ClearDrvData		;Laufwerksvariablen löschen.
			rts				;Ende...
:l2068			inc	Cnt_RealDrives		;Anzahl echte Laufwerke +1.
:l206b			rts

;*** Laufwerk auf Existenz prüfen.
:IsDriveOnline		jsr	SetNewDrive		;Laufwerk aktivieren.

			lda	numDrives		;Mind. ein Laufwerk verfügbar ?
			bne	l2077			;Ja, weiter...
			inc	numDrives		;Zähler korrigieren.

:l2077			jsr	NewDisk			;Diskette öffnen.
			cpx	#$0d			;Laufwerk vorhanden ?
			rts				;Ende...

;*** Laufwerksdaten löschen.
:ClearDrvData		ldy	curDrive
			lda	#$00
			sta	driveType -8,y
			sta	ramBase   -8,y
			sta	ConfigGEOS -8,y
			sta	diskOpenFlg,y
			rts

;*** Speicher für gesichertes Laufwerk beim anmelden
;    eines neuen Laufwerks.
:SvSwapDrvADDR		b $00

;*** Neues Laufwerk einschalten.
:AddNewDrive		lda	#$00
			sta	SvSwapDrvADDR

			lda	CurrentDrive
			cmp	#$0a
			bcc	AddDrv_8_9
			jmp	AddDrv_8_10

;*** Neues Laufwerk einschalten.
;    Geräteadresse muß #8 oder #9 sein.
:AddDrv_8_9		lda	#$00			;Zwischenspeicher für Laufwerks-
			sta	SvSwapDrvADDR		;adresse löschen.

			ldy	CurrentDrive
			lda	CurrentType		;Laufwerkstyp für neues Laufwerk
			sta	driveType -8,y		;speichern.

			inc	numDrives		;Anzahl Laufwerke +1.

			lda	CurrentDrive
			jsr	IsDriveOnline		;Ist Laufwerk bereits vorhanden ?
			bne	l20d3			;Ja, weiter...

;*** Laufwerk #8/#9 nicht aktiv.
			lda	CurrentDrive		;Freie Laufwerksadresse suchen.
			eor	#$01
			tay
			lda	driveType -8,y		;Adresse #8/#9 oder #10/11 frei ?
			beq	l20e4			;Ja, weiter...

;*** Laufwerk #8/#9 freischalten um neues Laufwerk mit Adr. #8/#9 zu erkennen.
;    Dazu vorhandenes Laufwerk auf Adr. #11 umschalten.
			tya
			ldy	#$0b			;Zeiger auf Adresse #11.
			bit	sysRAMFlg		;Laufwerkstreiber in der REU ?
			bvs	l20ce			;Ja, weiter...
			eor	#$02			;Auf Adresse #9 wechseln.
			tay
:l20ce			lda	driveType -8,y		;Adresse frei ?
			beq	l20d5			;Ja, weiter...
:l20d3			bne	l213b

:l20d5			sty	SvSwapDrvADDR		;Freie Geräteadresse merken und
			jsr	SwapDrive		;auf Laufwerk #8/#9 umschalten.

			lda	SvSwapDrvADDR
			jsr	SetNewDskDevice		;Geräteadresse für Laufwerk setzen.
			jsr	PurgeTurbo		;GEOS-Turbo abschalten.

							;***********************************
							;Zu diesem Zeitpunkt sind Laufwerke
							;#8 und #9 nicht angeschlossen.
							;***********************************

:l20e4			ldx	#>Dlg_SetDev_8_9
			lda	#<Dlg_SetDev_8_9
			jsr	SystemDlgBox		;Dialogbox: Laufwerk einschalten.

			lda	r0L
			cmp	#CANCEL			;Abbruch ?
			beq	l2123			;Ja, Ende.

			lda	CurrentDrive
			jsr	IsDriveOnline		;Wurde Laufwerk eingeschaltet ?
			bne	l2123			;Ja, weiter...

			lda	CurrentDrive		;Zeiger auf zweite Geräteadresse.
			eor	#$01
			sta	curDevice
			sta	curDrive		;Als aktuelles Laufwerk setzen.
			tay
			lda	CurrentType
			sta	driveType -8,y		;Laufwerkstyp speichern.
			lda	CurrentDrive
			jsr	SetNewDskDevice		;Laufwerksadresse zurücksetzen.

			lda	CurrentDrive
			sta	curDevice
			sta	curDrive
			eor	#$01
			tay
			lda	#$00
			sta	driveType -8,y
			txa
			bne	l20e4

:l2123			lda	SvSwapDrvADDR		;Wurde Laufwerk #8/#9 gesichert ?
			beq	l213b			;Nein, weiter...

;*** War zu Beginn eine der Geräteadressen #8/#9 bereits belegt, dann
;    wurde dieses Laufwerk auf eine neue Adresse #11 gesetzt. Dieses Laufwerk
;    wird jetzt wieder auf die alte Adresse zurückgesetzt.

			jsr	IsDriveOnline		;Ist altes Laufwerk noch vorhanden ?
			bne	l2133			;Ja, weiter...

			jsr	ClearDrvData		;Laufwerksdaten löschen.
			clv
			bvc	l213b			;weiter...

:l2133			lda	CurrentDrive		;Altes Laufwerk #8/#9 wieder
			eor	#$01			;zurücksetzen.
			jsr	SetNewDskDevice

:l213b			jsr	UpdateDriveData		;Laufwerksinformationen updaten.
			rts

;*** Neues Laufwerk einschalten.
;    Geräteadresse muß #8 oder #10 sein.
:AddDrv_8_10		lda	#$00			;Zwischenspeicher für Laufwerks-
			sta	SvSwapDrvADDR		;adresse löschen.

			ldy	CurrentDrive
			lda	CurrentType		;Laufwerkstyp für neues Laufwerk
			sta	driveType -8,y		;speichern.

			inc	numDrives		;Anzahl Laufwerke +1.

			lda	CurrentDrive
			jsr	IsDriveOnline		;Ist Laufwerk bereits vorhanden ?
			bne	l2166			;Ja, weiter...

			ldy	#$08			;Zeiger auf Laufwerk #8.
			lda	driveType -8,y		;Laufwerk vorhanden ?
			beq	l2179			;Nein, weiter...

			ldy	#$0b			;Zeiger auf Laufwerk #11.
			lda	driveType -8,y		;Laufwerk vorhanden ?
			beq	l2168			;Nein, weiter...
:l2166			bne	l21c9

:l2168			sty	SvSwapDrvADDR		;Freie Geräteadresse merken und
			lda	#$08			;auf Laufwerk #8 umschalten.
			jsr	SetNewDrive

			lda	SvSwapDrvADDR		;Laufwerk #8 auf Adr. #11
			jsr	SetNewDskDevice		;umschalten.

			jsr	PurgeTurbo		;GEOS-Turbo deaktivieren.

:l2179			ldx	#>Dlg_SetDev_8_10
			lda	#<Dlg_SetDev_8_10
			jsr	SystemDlgBox		;Dialogbox: Laufwerk einschalten.

			lda	r0L
			cmp	#CANCEL			;Abbruch ?
			beq	l21b4			;Ja, Ende...

			lda	CurrentDrive
			jsr	IsDriveOnline		;Wurde Laufwerk eingeschaltet ?
			bne	l21b4			;Ja, weiter...

			lda	#$08
			sta	curDevice
			sta	curDrive
			tay
			lda	CurrentType
			sta	driveType -8,y
			lda	CurrentDrive		;Neues Laufwerk auf die richtige
			jsr	SetNewDskDevice		;Geräteadresse setzen.

			lda	CurrentDrive
			sta	curDevice
			sta	curDrive

			ldy	#$08
			lda	#$00			;Laufwerk #8 löschen.
			sta	driveType -8,y
			txa
			bne	l2179

:l21b4			lda	SvSwapDrvADDR		;Wurde Laufwerk #8 auf #11
			beq	l21c9			;gewechselt ? Nein, weiter...

			jsr	IsDriveOnline		;Ist Laufwerk #11 noch aktiv ?
			bne	l21c4			;Ja, weiter...

			jsr	ClearDrvData		;Laufwerksdaten löschen, Ende...
			clv
			bvc	l21c9

:l21c4			lda	#$08			;Laufwerk #11 wieder auf die alte
			jsr	SetNewDskDevice		;Adresse #8 zurücksetzen.

:l21c9			jsr	UpdateDriveData		;Laufwerksinformationen updaten.
			rts

;*** Texte für Dialogbox: Laufwerk einschalten.
:l21cd			b BOLDON
			b "Plug in & turn ON new drive.",NULL
:l21eb			b BOLDON
			b "(Must be set to device 8 or 9)",NULL
:l220b			b BOLDON
			b "(Must be set to device 8 or 10)",NULL

;*** Dialogbox: Laufwerk einschalten.
;               Geräteadresse = #8 oder #9
:Dlg_SetDev_8_9		b $81
			b DBTXTSTR,$0c,$10
			w l21cd
			b DBTXTSTR,$0c,$20
			w l21eb
			b OK      ,$01,$48
			b CANCEL  ,$11,$48
			b NULL

;*** Dialogbox: Laufwerk einschalten.
;               Geräteadresse = #8 oder #10
:Dlg_SetDev_8_10	b $81
			b DBTXTSTR,$0c,$10
			w l21cd
			b DBTXTSTR,$0c,$20
			w l220b
			b OK      ,$01,$48
			b CANCEL  ,$11,$48
			b NULL

;*** Laufwerk auf neue Geräteadresse setzen.
:SetNewDskDevice	bit	sysRAMFlg		;Laufwerkstreiber in REU ?
			bvc	:51			;Nein, weiter...

			pha
			tay
			lda	DskDrvBaseL -8,y	;Zeiger auf Adresse des aktuellen
			sta	r1L			;Laufwerkstreiber in der REU.
			lda	DskDrvBaseH -8,y
			sta	r1H
			LoadW	r0 ,DISK_BASE
			LoadW	r2 ,$0d80
			LoadB	r3L,$00
			jsr	StashRAM		;Laufwerkstreiber in REU speichern.
			pla

::51			sta	r0L			;Neue Laufwerksadresse speichern.

			lda	curDrive		;Aktuelles Laufwerk einlesen und
			pha				;zwischenspeichern.
			tay
			lda	ramBase   -8,y		;Laufwerksvariablen speichern.
			pha
			lda	driveType -8,y
			pha				;RAM-Laufwerk ?
			bpl	:52			;Nein, weiter...

			lda	r0L
			jsr	SetNewDrive		;Neues Laufwerk aktivieren.
			clv				;Sonderbehandlung für echte
			bvc	:53			;Laufwerke übergehen.

::52			lda	r0L			;Laufwerksadresse ändern.
			jsr	ChangeDiskDevice

::53			ldy	curDrive
			pla
			sta	driveType -8,y		;Laufwerksdaten für neues Laufwerk
			pla				;zurückschreiben.
			sta	ramBase   -8,y
			pla
			tay
			lda	#$00			;Variablen für altes Laufwerk
			sta	ramBase   -8,y		;löschen.
			sta	driveType -8,y
			rts

;**+ Dialogbox ausgeben.
;    Zuvor Grafikdaten sichern, damit Dialogbox korrekt wieder
;    abgebaut wird.
:SystemDlgBox		stx	r0H			;Zeiger auf Dialogbox-Daten.
			sta	r0L

			ldx	#$00
			stx	ScreenArea

			lda	r5H
			pha
			lda	r5L
			pha
			jsr	DoSvScrnGrafx		;Bildschirminhalt speichern.
			pla
			sta	r5L
			pla
			sta	r5H
			jmp	DoDlgBox		;Dialogbox öffnen.

;CONFIGURE verwendet PullDown-Menüs. Beim Abbau der Menüs wird die Routine
;in RecoverVector aufgerufen. Da im Hintergrundbereich aber während des
;Startvorgangs das Boot-Programm liegt, muß der Bildschirm-Inhalt an anderer
;Stelle gespeichert werden!

;*** Unterverzeichnis öffnen.
:SvMenuBackScr		ldx	#$04
			jsr	SvScrnGrafx
			LoadW	r0,SubMenuDef
			rts

:SvScrnGrafx		stx	ScreenArea		;Bildschirm-Bereich merken.
			ldx	ScreenArea		;Bildschirm-Bereich wieder einlesen.
			jmp	DoSvScrnGrafx

;*** Menübildschirm wieder herstellen.
:LdMenuBackScr		ldx	ScreenArea
			jsr	l22eb
			rts

;*** Aufruf auch über Dialogboxen!!!
:DoSvScrnGrafx		lda	#$00			;Modus "Hintergrund speichern".
			clv
			bvc	l22ed

:l22eb			lda	#$ff			;Modus "Hintergrund einlesen".
:l22ed			sta	r4H			;Modus speichern.
			jsr	SetVarMenuScr

;*** Bildschirm-Inhalte austauschen.
::51			ldx	r2H			;Zeiger auf aktuelle
			jsr	GetScanLine		;Bildschirmzeile richten.

			lda	r2L
			asl
			asl
			asl
			bcc	:52
			inc	r5H
::52			tay
			lda	r3L
			sta	r4L

::53			bit	r4H			;Modus abfragen.
			bpl	:54			; => Grafikdaten speichern.

			jsr	LdScrData		; => Grafikdaten einlesen.
			clv
			bvc	:55

::54			jsr	SvScrData		; => Grafikdaten speichern.

::55			inc	r1L
			bne	:56
			inc	r1H

::56			clc
			adc	#$08
			bcc	:57
			inc	r5H

::57			tay
			dec	r4L
			bne	:53
			inc	r2H
			dec	r3H			;Alle Grafikdaten gespeichert ?
			bne	:51			;Nein, weiter...
			rts

;*** Grafikdaten zwischenspeichern.
:SvScrData		lda	(r5L),y
			tax
			tya
			pha
			ldy	#$00
			txa
			sta	(r1L),y
			pla
			rts

;*** Grafikdaten wieder einlesen.
:LdScrData		tya
			pha
			ldy	#$00
			lda	(r1L),y
			tax
			pla
			tay
			txa
			sta	(r5L),y
			tya
			rts

;*** Variablen setzen zum speichern/laden des Hintergrundbildschirms.
:SetVarMenuScr		LoadW	r1,ScreenBuffer

			ldy	#$00
::51			lda	SvScrnAreas,x
			sta	r2         ,y
			inx
			iny
			cpy	#$04
			bne	:51
			rts

:SvScrnAreas		b $08,$20,$19,$68		;Daten für Dialogbox.
			b $00,$0e,$0e,$2c		;daten für PullDown-Menü.
