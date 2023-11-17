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
			n "KONFIGURIEREN"
			f APPLICATION
			a "M. Kanet"

:SysFileName		= $1e25
:RAM_Test_Copy		= $1e36
:RAM_Test_Buf		= $1e3e
:SizeOfREU		= $1e46
:InitDriveVec		= $1e47
:SysDrive		= $1e48
:SysDrvType		= $1e49
:DriveTypeA		= $1e4a
:DriveTypeB		= $1e4b
:DriveTypeC		= $1e4c
:PosROM_Data		= $1e4d
:DrvROM_Data		= $1e4e
:Vec_MenuRecData	= $1e6e
:CurrentDrive		= $1e6f
:InstallType		= $1e70
:Vec_DrvInfoTab		= $1e71
:CurrentType		= $1e73
:BankInUseTab		= $1e74
:SaveBootProg		= $1e7c
:ScreenArea		= $227c
:ScreenBuffer		= $227d
:AddrBootProg		= $5000

:ConfigGEOS		b $02,$02,$00,$00
:CurRAM_Flag		b $a0

;*** Programm starten.
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

;*** KONFIGURIEREN beenden und zurück zum DeskTop.
:ExitToDeskTop		lda	SysDrive
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

:SystemClass		b "Configure   V2.0",NULL

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
:Flag_DrvInREU		b $00,$00,$00,$00

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

			lda	r2H
			rts

:l0722			and	#%00001111		;Laufwerkstyp isolieren.
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
			beq	l07c4			;Typ = #0 ? Ja, Ende...

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

:l07c4			rts

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
			jsr	CreateBAM_41_71		;BAM für RAM-Laufwerk erzeugen.
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
			jsr	CreateBAM_41_71		;BAM für RAM-Laufwerk erzeugen.
			dec	Cnt_GEOS_Drives
:l08c0			rts

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
:DefUsedBankTab		ldy	#$07
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
			and	#$0f
			tay
			lda	MaxBank,y		;Benötigte RAM-Bänke einlesen.
:l0a93			rts

:MaxBank		b $03,$03,$06,$01

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

:LdAdrDskDrvL		b $80,$00,$80,$00
:LdAdrDskDrvH		b $3c,$4a,$57,$65

:DskDrvBaseL		b $00,$80,$00,$80
:DskDrvBaseH		b $83,$90,$9e,$ab

;*** Zeiger auf Gerätetreiber berechnen.
;    $00 = 1541
;    $01 = 1571
;    $02 = 1581
;    $03 = RAM1541,71

:GetVec2Driver		tya
			bpl	l0a39

			ldy	#$03
			bne	l0a3d

:l0a39			and	#$0f
			tay
			dey
:l0a3d			rts

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
			cpx	#$81			;1581/FDx/HD-Laufwerk erkannt ?
			beq	l0f76			;Immer weiter...

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

			lda	#$00			;Größe der Speichererweiterung
			sta	ramExpSize		;auf #0 zurücksetzen.

			lda	#$02			;Max. Anzahl Bänke in 128K-REU
			sta	SizeOfREU		;als Zähler setzen.

			lda	$df00			;Größen-Register bei $DF00 einlesen.
			and	#$10			;512K-REU ?
			beq	l0d9b			;Nein, weiter...

			lda	#$08			;Max. Anzahl Bänke in 512K-REU
			sta	SizeOfREU		;als Zähler setzen.

:l0d9b			lda	$df00			;Status-Register der REU testen.
			and	#$e0			;Fehler ?
			bne	l0ddc			;Ja, REU nicht akzeptieren.

			lda	#$55
			sta	$df02			;Prüfbyte in REU speichern und
			cmp	$df02			;vergleichen. Korrekt gespeichert ?
			bne	l0ddc			;Nein, keine REU...

			lda	#$aa
			sta	$df02			;Prüfbyte #2 in REU speichern

			ldy	#$00
:l0db3			dey				;Warteschleife.
			bne	l0db3
			cmp	$df02			;Ist Byte noch gespeichert ?
			bne	l0ddc			;Nein, keine REU...

			lda	#$01			;Mind. 1 Bank in der REU verfügbar.
			sta	ramExpSize

			lda	#$00			;Zeiger auf Bank #0.
			sta	r3L
:l0dc4			jsr	Check64KBank		;Bank verfügbar ?
			bcc	l0dd9			;Nein, weiter...

			lda	ramExpSize		;Max. Anzahl Bänke in REU
			cmp	SizeOfREU		;erreicht ?
			beq	l0ddc			;Ja, REU-Größe ermittelt, Ende...

			inc	ramExpSize		;Bank-Zähler +1.
			inc	r3L
			clv
			bvc	l0dc4

:l0dd9			dec	ramExpSize
:l0ddc			jmp	DoneWithIO

;*** Prüfen ob REU-Bank vorhanden ist.
:Check64KBank		LoadW	r0,RAM_Test_Buf
			lda	#$00
			sta	r1L
			sta	r1H
			LoadW	r2,$0008		;Original-Daten aus REU einlesen
			jsr	FetchRAM		;und zwischenspeichern.

			LoadW	r0,RAM_TestData		;Test-Daten in REU kopieren.
			jsr	StashRAM

			LoadW	r0,RAM_Test_Copy	;Testdaten wieder aus REU
			jsr	FetchRAM		;einlesen.

			LoadW	r0,RAM_Test_Buf		;Original-Daten wieder zurück in
			jsr	StashRAM		;REU-Bank kopieren.

			ldy	#$07
:l0e1b			lda	RAM_TestData ,y		;Wurden Daten erfolgreich
			cmp	RAM_Test_Copy,y		;gespeichert ?
			bne	l0e28			;Nein, Bank nicht vorhanden...
			dey
			bpl	l0e1b
			sec				;Bank verfügbar.
			rts
:l0e28			clc				;Bank nicht verfügbar.
			rts

:RAM_TestData		b "RAMCheck"

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
			jsr	$6216

			LoadW	r0,$9d80
			LoadW	r1,$b900
			LoadW	r2,$0280
			jsr	$6216

			LoadW	r0,$bf40
			LoadW	r1,$bb80
			LoadW	r2,$00c0
			jsr	$6216

			LoadW	r0,$c080
			LoadW	r1,$bcc0
			LoadW	r2,$0f80
			jsr	$6216

			LoadB	r4L,$30
			LoadW	r5 ,$d000

			LoadW	r0,$8000
			LoadW	r1,$cc40
			LoadW	r2,$0100

::51			jsr	$6216

			ldy	#$00
::52			lda	diskBlkBuf +$00,y
			sta	(r5L),y
			iny
			bne	:52
			inc	r5H
			inc	r1H
			dec	r4L
			bne	:51

;*** Variablenspeicher löschen.
			jsr	i_FillRam
			w	$0500
			w	$8400
			b	$00

;*** Bildschirm löschen.
			lda	#<SCREEN_BASE
			sta	r0L
			lda	#>SCREEN_BASE
			sta	r0H

			ldx	#$7d
::61			ldy	#$3f
::62			lda	#$55
			sta	(r0L),y
			dey
			lda	#$aa
			sta	(r0L),y
			dey
			bpl	:62
			lda	r0L
			clc
			adc	#$40
			sta	r0L
			bcc	:63
			inc	r0H
::63			dex
			bne	:61

;*** GEOS initialisieren.
			jsr	FirstInit		;GEOS initialisieren.

			lda	#$ff			;GEOS-Boot-Vorgang.
			sta	firstBoot

			jsr	InitMouse		;Mausabfrage initialsieren.

			LoadW	r0,ramExpSize		;GEOS-Variablen aus REU in
			LoadW	r1,$7dc3		;C64-RAM kopieren.
			LoadW	r2,$0002
			jsr	$6216

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
:l1122			ldy	#$91
			ldx	CPU_DATA
			lda	#$35
			sta	CPU_DATA

			lda	r0H
			sta	$df03
			lda	r0L
			sta	$df02
			lda	r1H
			sta	$df05
			lda	r1L
			sta	$df04

			lda	#$00
			sta	$df06

			lda	r2H
			sta	$df08
			lda	r2L
			sta	$df07

			lda	#$00
			sta	$df09
			sta	$df0a
			sty	$df01

:l1158			lda	$df00
			and	#$60
			beq	l1158
			stx	CPU_DATA
			rts

;******************************************************************************
;*** Hauptmenü-Routine.
;******************************************************************************
:VLIR_BASE
:MenuRecData		b $69,$c4			;Rahmen für RAM-Optionen.
			w $00b4,$0136

			b $8b,$95			;Rahmen für ReBoot.
			w $011e,$0130

			b $a7,$b1			;Rahmen für MoveData.
			w $011e,$0130

			b $07,$62			;Rahmen für Laufwerk A:
			w $001e,$00a0

			b $07,$62			;Rahmen für Laufwerk B:
			w $00b4,$0136

			b $69,$c4			;Rahmen für Laufwerk C:
			w $001e,$00a0

			b $18,$22			;Max. 5 Anzeige-Optionen.
			w $0088,$009a

			b $26,$30
			w $0088,$009a

			b $34,$3e
			w $0088,$009a

			b $42,$4c
			w $0088,$009a

			b $50,$5a
			w $0088,$009a

			b $18,$22			;Max. 5 Anzeige-Optionen.
			w $011e,$0130

			b $26,$30
			w $011e,$0130

			b $34,$3e
			w $011e,$0130

			b $42,$4c
			w $011e,$0130

			b $50,$5a
			w $011e,$0130

			b $7a,$84			;Max. 5 Anzeige-Optionen.
			w $0088,$009a

			b $88,$92
			w $0088,$009a

			b $96,$a0
			w $0088,$009a

			b $a4,$ae
			w $0088,$009a

			b $b2,$bc
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
:l16d4			lda	driveType  ,y		;Aktuelle Konfiguration einlesen
			sta	ConfigGEOS ,y		;und zwischenspeichern.
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

:l1786			jsr	CloseRecordFile		;Systemdatei schließen.
:l1789			rts

;*** Fehler: "Falsche GEOS-Version".
:Dlg_WrongGEOS		b $81
			b DBTXTSTR ,$0c,$20
			w l12eb
			b DBTXTSTR ,$0c,$30
			w l1306
			b OK       ,$01,$48
			b NULL

:l12eb			b BOLDON,$22,"CONFIGURE",$22," ist auf diese",NULL
:l1306			b BOLDON,"Version des GEOS KERNAL nicht anwendbar.",NULL

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

:Titel_DriveA		b BOLDON,"Laufwerk A",NULL
:Titel_DriveB		b BOLDON,"Laufwerk B",NULL
:Titel_DriveC		b BOLDON,"Laufwerk C",NULL

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
			LoadW	r11,$003f
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
			LoadW	r11,$00d5
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
			LoadW	r11,$003f
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
			LoadB	r1H,$aa
			LoadW	r11,$00be
			jsr	PutString

			LoadW	r0 ,l19ef
			LoadB	r1H,$b6
			LoadW	r11,$00be
			jsr	PutString

;*** Neue MoveData-Option anzeigen.
:NewOptMoveData		lda	sysRAMFlg
			and	#%10000000
			beq	l19e0
			lda	#$02
:l19e0			ldy	#$01
			jsr	ViewSlctDrive
			rts

:l19e6			b BOLDON,"DMA für",NULL
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
:l1a1a			ldy	#$02
			jsr	ViewSlctDrive
			rts

:l1a20			b BOLDON
			b "Neustarten "
			b GOTOXY
			w $00be
			b $99
			b "des RAM",NULL

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
			beq	l1627			;Nein, weiter...

			ldy	#$01
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
:TestOptReBoot		ldy	#$02
			jsr	SetMenuRecData		;Abfrage-Bereich festlegen.
			jsr	IsMseInRegion		;Mausklick in Bereich ?
			beq	l1627			;Nein, Ende...

			lda	sysRAMFlg		;ReBoot-Status wechseln.
			eor	#$20
			sta	sysRAMFlg
			sta	sysFlgCopy
			sta	CurRAM_Flag
			jmp	NewOptReBoot
:l1627			rts

;*** Größe der Speichererweiterung ausgeben.
:PrntSizeREU		lda	ramExpSize		;Zeiger auf Text für Größe
			asl				;berechnen.
			asl
			clc
			adc	ramExpSize
			tay

			ldx	#$00
:l1634			lda	l166f,y			;Größenangabe in Ausgabetext
			sta	l1659,x			;kopieren.
			iny
			inx
			cpx	#$05
			bne	l1634

			LoadW	r0 ,l1658
			LoadB	r1H,$75
			LoadW	r11,$00b9
			jsr	PutString		;Größe ausgeben.
			rts

:l1658			b BOLDON
:l1659			b "00000 RAM-Erweiterung",NULL
:l166f			b "Keine"
			b "64K" ,BOLDON,BOLDON,"128K",BOLDON
			b "172K",BOLDON       ,"256K",BOLDON
			b "320K",BOLDON       ,"384K",BOLDON
			b "448K",BOLDON       ,"512K",BOLDON

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

:l1c29			b BOLDON,"Die Konfiguration kann nicht",NULL
			b BOLDON,"gespeichert werden:  Die Datei",NULL
:l1c48			b BOLDON,"KONFIGURIEREN ist nicht zu finden.",NULL

;*** Hauptmenu.
:SystemMenu		b $00
			b $0e
			w $0000
			w $001c

			b $01 ! HORIZONTAL ! UN_CONSTRAINED

			w l1791
			b DYN_SUB_MENU
			w SvMenuBackScr

:l1791			b "Datei",NULL

:SubMenuDef		b $0e
			b $2a
			w $0000
			w $006a

			b $02 ! VERTICAL ! UN_CONSTRAINED

			w l17a8
			b MENU_ACTION
			w Menu_SaveConfig

			w l17c0
			b MENU_ACTION
			w Menu_ExitConfig

:l17a8			b "Konfiguration speichern",NULL
:l17c0			b "Verlassen",NULL

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

:ModeTabDrvA		b $08
			b $06
			b $00,$00,$00,$00
			b $00,$00,$00,$00
			b $00,$00,$00,$00

:ModeTabDrvB		b $09
			b $0b
			b $00,$00,$00,$00
			b $00,$00,$00,$00
			b $00,$00,$00,$00

:ModeTabDrvC		b $0a
			b $10
			b $00,$00,$00,$00
			b $00,$00,$00,$00
			b $00,$00,$00,$00

:TabDrvInfoL		b <l1903
			b <l1916
			b <l1920
			b <l1935
			b <l1943
			b <l194d
			b <l1957
			b <l196c

:TabDrvInfoH		b >l1903
			b >l1916
			b >l1920
			b >l1935
			b >l1943
			b >l194d
			b >l1957
			b >l196c

:l1903			b $00
			w l1908
			w TurnOffDrive
:l1908			b "Kein Laufwerk",NULL

:l1916			b $01
			w l191b
			w Install_1541
:l191b			b "1541",NULL

:l1920			b $41
			w l1925
			w Install_DskCache
:l1925			b "1541 schattiert",NULL

:l1935			b $81
			w l193a
			w Install_RAM1541
:l193a			b "RAM 1541",NULL

:l1943			b $02
			w l1948
			w Install_1571
:l1948			b "1571",NULL

:l194d			b $03
			w l1952
			w Install_1581
:l1952			b "1581",NULL

:l1957			b $43
			w l195c
			w Install_DirCache
:l195c			b "1581 schattiert",NULL

:l196c			b $82
			w l1971
			w Install_RAM1571
:l1971			b "RAM 1571",NULL

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

;*** Laufwerk abschalten.
:TurnOffDrive		lda	InstallType		;Laufwerk vorhanden ?
			beq	l1fb2			;Nein, weiter...

			jsr	PurgeTurbo		;Turbo-Modus abschalten.

			lda	InstallType		;RAM-Laufwerk ?
			bmi	l1fa6			;Ja, weiter...

			lda	CurrentDrive
			clc
			adc	#$39
			sta	l2008			;Laufwerksbuchstaben ermitteln.

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
			b "Schalten Sie Laufwerk "
:l2008			b "x AUS",NULL
:l2025			b "und/oder trennen Sie es ab.",NULL

:Dlg_TurnOffDrv		b $81
			b DBTXTSTR,$0c,$20
			w l1fec
			b DBTXTSTR,$0c,$30
			w l2025
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
;    Die folgenden Texte werden nicht angesprochen. Hier wurde bei
;    der Übersetzung schlampig gearbeitet, da jetzt beide Dialogboxen den
;    gleichen Text anzeigen, obwohl die eine Box für Laufwerk #8/#9 und die
;    zweite Box für Laufwerk #8/#10 gedacht ist.
			b BOLDON,"(Muß Gerätenummer 8 oder 9 haben!)"
			b BOLDON,"(Muß Gerätenummer 8 oder 10 haben!)"

:l1cae			b BOLDON,"Schließen Sie das neue Laufwerk",NULL
:l1ccf			b BOLDON,"an, und schalten Sie es ein.",NULL

;*** Dialogbox: Laufwerk einschalten.
;               Geräteadresse #8 oder #9
:Dlg_SetDev_8_9		b $81
			b DBTXTSTR,$0c,$10
			w l1cae
			b DBTXTSTR,$0c,$20
			w l1ccf
			b OK      ,$01,$48
			b CANCEL  ,$11,$48
			b NULL

;*** Dialogbox: Laufwerk einschalten.
;               Geräteadresse #8 oder #10
:Dlg_SetDev_8_10	b $81
			b DBTXTSTR,$0c,$10
			w l1cae
			b DBTXTSTR,$0c,$20
			w l1ccf
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
			b $00,$0e,$0e,$1e		;Daten für PullDown-Menü.
