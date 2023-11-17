; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;GeoDOS initialisieren.
;******************************************************************************

;*** Programm initialisieren.
:GDStartUp		bit	c128Flag		;GEOS 128 ?
			bpl	:101			;Nein, weiter...

			lda	graphMode		;C128: Auf 40-Zeichen umschalten.
			and	#%01111111
			sta	graphMode
			jsr	SetNewMode

::101			jsr	InitForIO		;I/O-Bereich aktivieren.

			lda	$d020			;GEOS-Farben speichern.
			sta	C_GEOS_FRAME
			lda	$d027
			sta	C_GEOS_MOUSE
			lda	screencolors
			sta	C_GEOS_BACK

			lda	C_ScreenBack		;GeoDOS-Farben setzen.
			and	#%00001111
			sta	$d020
			lda	C_Mouse
			sta	$d027

			jsr	DoneWithIO		;I/O-Bereich abschalten.

			jsr	MouseOff

;--- Ergänzung: M.Kanet/18.12.18
;MP128 setzt beim Wechsel von 80Z auf 40Z die Mausgrenzen nicht korrekt.
;Der folgende Code setzt die Mausgrenzen und positioniert den Mauszeiger
;in der Mitte des Bildschirms.
			jsr	SetWindow_a

			php
			sei
			LoadW	r11,160
			ldy	#100
			sec
			jsr	StartMouseMode
			plp
			jsr	UpdateMouse

			jsr	ClrScreen		;Bildschirm löschen.

;*** GeoDOS-Datei suchen.
:GetVLIRTab		lda	curDrive		;Start-Laufwerk merken.
			sta	AppDrv
			sta	BootDrive
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	NewOpenDisk		;Diskette öffnen.
			txa
			bne	:101

;*** Start-Verzeichnis einlesen.
;--- Ergänzung: 21.11.18/M.Kanet
;Bisher wurde nur bei CMD-Laufwerken das aktuelle Verzeichnis eingelesen.
;Mit RAMNative/SD2IEC muss dies auch bei Nicht-CMD-Laufwerken erfolgen!
			lda	curType
			and	#%00000111
			cmp	#$04			;Native-Laufwerk ?
			bne	:100			;Nein, weiter...
			lda	curDirHead+32		;Ja, Track/Sektor Startverzeichnis
			sta	AppNDir   + 0		;merken.
			sta	BootNDir  + 0
			sta	WorkNDir  + 0
			lda	curDirHead+33
			sta	AppNDir   + 1
			sta	BootNDir  + 1
			sta	WorkNDir  + 1

::100			lda	#APPLICATION		;GeoDOS als "Anwendung" suchen.
			ldx	#<AppClass
			ldy	#>AppClass
			jsr	LookForFile
			txa
			beq	:102			;OK, gefunden...

			lda	#AUTO_EXEC		;GeoDOS als "Anwendung" suchen.
			ldx	#<AppClass
			ldy	#>AppClass
			jsr	LookForFile
			txa
			beq	:102			;OK, gefunden...
::101			jmp	GDDiskError		;GeoDOS-Hauptprogramm nicht gefunden.

::102			jsr	i_MoveData
			w	FileNameBuf
			w	AppNameBuf
			w	17

			LoadW	r0,AppNameBuf		;GeoDOS-Hauptprogramm öffnen.
			jsr	OpenRecordFile
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch.

			jsr	CloseRecordFile
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch.

			lda	fileHeader+4		;Hardware-Test-Routine nachladen.
			sta	r1L
			lda	fileHeader+5
			sta	r1H
			LoadW	r2,$2000
			LoadW	r7,$4000
			jsr	ReadFile
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch.

;*** Auf RAM-Erweiterung testen.
:TestForRAM		jsr	CheckRAM
			txa
			bne	:101
			jmp	StartTest
::101			jmp	OpenDeskTop

;*** Hardware testen.
:StartTest		jsr	TestHardware		;Hardware testen.

;*** Konfiguration testen.
:CheckConfig		ldy	#$00			;Konfiguration OK.
			sty	CBM_Count		;Anz. CBM-Drives löschen
			sty	DOS_Count		;Anz. DOS-Drives löschen.
::101			lda	DriveTypes,y
			beq	:102			;Laufwerk vorhanden ?
			inc	CBM_Count		;Ja, Zähler für CBM-Laufwerke +1.
			lda	DriveModes,y
			and	#%00010000
			beq	:102 			;DOS-Laufwerk ?
			inc	DOS_Count		;Ja, Zähler für DOS-Laufwerke +1.
::102			iny
			cpy	#$04
			bcc	:101

			ldy	#$00
			jsr	GetGEOSdrv		;Laufwerke "Source" und "Target" auf
			sta	Source_Drv		;Startwerte setzen.
			sta	Action_Drv
			iny
			jsr	GetGEOSdrv
			sta	Target_Drv

;*** Bei CMD-Laufwerk Partition ermitteln.
:GetCMDPart		ldx	#$08
::101			stx	V150a0
			lda	DriveTypes-8,x
			beq	:102
			lda	DriveModes-8,x
			bpl	:102
			jsr	GetDrvPart
::102			ldx	V150a0
			inx
			cpx	#$0c
			bcc	:101

;*** Startpartition ermitteln.
:AppDrvData		lda	AppDrv			;Start-Laufwerk aktivieren.
			jsr	NewDrive
			jsr	NewOpenDisk

			lda	curDrvType		;Laufwerkstyp speichern.
			sta	AppType
			sta	BootType

			lda	curDrvMode		;Laufwerksdaten speichern.
			sta	AppMode
			sta	BootMode

;*** Start-Partition ermitteln.
			lda	curDrvMode		;Laufwerksdaten speichern.
			bpl	:103

			ldx	curDrive
			lda	DrivePart - 8,x
			jsr	SetNewPart

			bit	curDrvMode		;RAM-Laufwerk ?
			bvc	:102			;Nein, weiter...

			lda	Part_Info  +22		;RAMLink-Adresse der Partition merken.
			sta	AppRLPart  + 0
			sta	BootRLpart + 0
			lda	Part_Info  +23
			sta	AppRLPart  + 1
			sta	BootRLpart + 1

::102			lda	Part_Info  + 4		;Partitions-Nr. merken.
			sta	AppPart
			sta	BootPart

::103			lda	BootMode
			and	#%00100000		;Native-Laufwerk ?
			beq	:104			;Nein, weiter...
			MoveW	BootNDir,r1
			jsr	New_CMD_SubD
			txa
			bne	:105
::104			jsr	NewOpenDisk
			txa
			bne	:105
			jmp	PrintTitel		;Titel ausgeben.
::105			jmp	GDDiskError		;GeoDOS-Hauptprogramm nicht gefunden.

;*** Nächstes GEOS-Laufwerk holen.
:GetGEOSdrv		cpy	#$04
			bne	:101
			ldy	#$00
::101			lda	DriveTypes,y
			bne	:102
			iny
			bne	GetGEOSdrv
::102			tya
			add	8
			rts

;*** Aktuelle Partition ermitteln.
:GetDrvPart		txa				;Laufwerk 8-11 aktivieren.
			jsr	SetDevice

			ldx	#$01
			stx	r1L
			stx	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa
			beq	:101

			ldx	V150a0
			lda	#$01
			sta	DrivePart-8,x		;Partitions-Nr. merken.
			rts

::101			jsr	PurgeTurbo		;TurboDOS deaktivieren.
			jsr	InitForIO		;I/O aktivieren.

			ldy	V150a0			;Befehlskanal öffnen.
			ldx	DriveAdress-8,y
			lda	#$0f
			tay
			jsr	SETLFS
			lda	#$00
			jsr	SETNAM
			jsr	OPENCHN

			ldx	V150a0
			lda	DriveModes-8,x
			and	#%01000000		;RAM-Laufwerk ?
			beq	:121			;Ja, Partition suchen.

::111			jsr	FindPart_RAM
			txa
			beq	:131
			lda	#$00
			beq	:132

::121			jsr	FindPart_Disk
			txa
			beq	:131
			lda	#$00
			beq	:132

::131			lda	V150a2   +2
::132			ldx	V150a0
			sta	DrivePart-8,x		;Partitions-Nr. merken.
			lda	#$0f
			jsr	CLOSE
			jmp	DoneWithIO

;*** CMD-Erkennung senden.
:SendGP_com		sta	V150a1+3

			ldx	#$0f
			jsr	CKOUT

			lda	#$00
			sta	:101 +1
::101			ldy	#$ff
			cpy	#$05
			beq	:102
			lda	V150a1,y
			jsr	$ffd2
			inc	:101 +1
			jmp	:101

::102			jmp	CLRCHN

;*** CMD-Erkennung empfangen.
:GetGP_com		ldx	#$0f
			jsr	CHKIN

			lda	#$00
			sta	:101 +4
::101			jsr	$ffe4
			ldy	#$ff
			cpy	#$1f
			beq	:102
			sta	V150a2,y
			inc	:101 +4
			jmp	:101

::102			jmp	CLRCHN

;*** Aktuelle Partition auf RAM suchen.
:FindPart_RAM		ldx	#1
::101			txa
			jsr	SendGP_com
			jsr	GetGP_com

			ldx	V150a2   + 0
			beq	:102
			cpx	#$05
			bcs	:102

			lda	curType
			and	#%00001111
			cmp	V150a3   - 1,x
			bne	:102

			ldx	curDrive
			lda	ramBase  - 8,x
			cmp	V150a2   +20
;			bne	:102
;			lda	driveData+ 3
;			cmp	V150a2   +21
			beq	:103

::102			ldx	V150a1 +3		;Falsche Partition, weitersuchen.
			inx
			cpx	#32
			bne	:101

			ldx	#$05
			b $2c
::103			ldx	#$00
			rts

;*** Aktuelle Partition auf Disk suchen.
:FindPart_Disk		lda	#$ff			;Aktive Partition einlesen.
			jsr	SendGP_com
			jsr	GetGP_com

			lda	V150a2   + 1		;Bei FD-Disketten auf
			beq	:100			;DOS/CBM-Format testen.
			and	#%00100000		;Wert $00 = HD/RL.
			beq	:104

::100			ldx	V150a2   + 0
			beq	:101
			cpx	#$05
			bcs	:101

			lda	curType
			and	#%00001111
			cmp	V150a3   - 1,x
			bne	:101
			ldx	#$00
			rts

;*** Erste gültige Partition suchen.
::101			ldx	#1
::102			txa
			jsr	SendGP_com
			jsr	GetGP_com

			ldx	V150a2   + 0
			beq	:103
			cpx	#$05
			bcs	:103

			lda	curType
			and	#%00001111
			cmp	V150a3   - 1,x
			beq	:105

::103			ldx	V150a1 +3		;Falsche Partition, weitersuchen.
			inx
			cpx	#32
			bne	:102

::104			ldx	#$05
			b $2c
::105			ldx	#$00
			rts

;*** Titel ausgeben.
.PrintTitel		StartMouse			;Maus aktivieren.
			jsr	UpdateMouse		;Mausdaten aktualisieren.
::101			lda	mouseData		;Maustaste gedrückt ?
			beq	:101			;Ja, weiter...

;*** Setup-Dateien laden.
:InitConfig		jsr	LoadSysVar
			txa
			beq	GetInfo
			jmp	InitScreen
:GetInfo		jmp	vTitel			;Titelbild.

			t "-LoadSysVar"

;******************************************************************************
;*** Fortsetzung Hauptprogramm.
;******************************************************************************
:V150a0			b $00
:V150a1			b "G-P",$ff,$0d
:V150a2			s 31
:V150a3			b $04,$01,$02,$03

if Sprache = Deutsch
;*** Hinweis: "Keine RAM-Erweiterung!"
:V150b0			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Keine RAM-Erweiterung!",NULL
::102			b        "Konfiguration anpassen?",NULL
endif

if Sprache = Englisch
;*** Hinweis: "Keine RAM-Erweiterung!"
:V150b0			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"No RAM-expansion found!",NULL
::102			b        "Autoconfigure system?",NULL
endif
