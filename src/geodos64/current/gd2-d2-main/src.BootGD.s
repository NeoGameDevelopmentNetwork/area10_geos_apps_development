; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

; GeoDOS Startprogramm
; (w) by Markus Kanet

if .p
			t	"TopSym"
			t	"Sym128.erg"
			t	"TopMac"
			t	"GD_Mac"

;*** Register für C128.
:MMU			= $ff00
:RAM_Conf_Reg		= $d506
endif

			n "BootGD",NULL
			a "M. Kanet",NULL
			f DESK_ACC
			o $3c00
			p MainInit
			r $5fff
			i
<MISSING_IMAGE_DATA>
			z $00 ; = Nur 40Z.

			h "Startet GeoDOS von einer"
			h "definierten CMD-Partition"
			h ""
			h "C64 (& C128 40-Zeichen)"

;******************************************************************************
:BootClass		b "Boot GeoDOS V298",NULL
			c "Boot GeoDOS V298",NULL
:BootFileName		b "BootGD",NULL
;******************************************************************************

;******************************************************************************
;*** Speicheraufteilung.
;******************************************************************************
if .p
;OS_VARS		= $8000				;Beginn GEOS-Variablen.
.Copy2Sek		= $7f00				;CBM-Sektorspeicher #2.
.Copy1Sek		= $7e00				;CBM-Sektorspeicher #1.
;PrintBase		= $7900				;Startadresse Drucker.
.DOS_Driver		= $7200				;Startadresse MSDOS-Treiber.
.DrvSlctBase		= $6400				;Startadresse Laufwerksauswahl (VLIR-Mod)
.FileNTab		= $6100				;Speicher für Dateinamen.
.FilePTab		= $6000				;Speicher für Partitions-Nummern.
.Disk_Sek		= $5f00				;MSDOS-Sektor.
.Disk2_Sek		= Disk_Sek + $0100
.Disk1_Sek		= Disk_Sek + $0000
.FAT			= $4d00				;MSDOS-FAT.
.Boot_Sektor		= $4b00				;MSDOS-Bootsektor.
.FileDTab3		= $4900				;MSDOS-Datenspeicher Größe #4.
.FileDTab2		= $4300				;MSDOS-Datenspeicher Größe #3.
.FileDTab1		= $4200				;MSDOS-Datenspeicher Größe #2.
.FileDTab		= $4100				;MSDOS-Datenspeicher Größe #1.
.TestHardware		= $4000				;Startadresse Hardwaretest-VLIR-Modul.

.EndAreaCBM		= DOS_Driver  -1		;Max. Endadresse CBM-Funktionen.
.EndAreaDOS		= Boot_Sektor -1		;Max. Endadresse DOS-Funktionen.

.JobCodeInit		= DOS_Driver			;MSDOS-Floppy-Jobcodes initialisieren.

;*** Einsprungadressen für Bootsektor-Informationen.
.Boot			= Boot_Sektor + $00		;Einsprung in Boot-Routine
.Disk_Typ		= Boot_Sektor + $03		;Name des Herstellers & Version
.BpSek			= Boot_Sektor + $0b		;Anzahl Bytes pro Sektor        (Word).
.SpClu			= Boot_Sektor + $0d		;Anzahl Sektoren pro Cluster    (Byte).
.AreSek			= Boot_Sektor + $0e		;Anzahl reservierter Sektoren   (Word).
.Anz_Fat		= Boot_Sektor + $10		;Anzahl File-Allocation-Tables  (Byte).
.Anz_Files		= Boot_Sektor + $11		;Anzahl Eintraege MainDirectory (Word).
.Anz_Sektor		= Boot_Sektor + $13		;Anzahl Sektoren im Volume      (Word).
.Media			= Boot_Sektor + $15		;Media-Descriptor               (Byte).
.SekFat			= Boot_Sektor + $16		;Anzahl Sektoren pro FAT        (Word).
.SekSpr			= Boot_Sektor + $18		;Anzahl Sektoren pro Spur       (Word).
.AnzSLK			= Boot_Sektor + $1a		;Anzahl der Schreib-/Lese-Köpfe (Word).
.FstSek			= Boot_Sektor + $1c		;Entfernung des ersten Sektors im
							;Volume vom ersten Sektor auf dem
							;Speichermedium                 (Word).

;*** C64-Kernal Einsprünge.
.SECOND			= $ff93				;Sekundär-Adresse nach LISTEN senden.
.TKSA			= $ff96				;Sekundär-Adresse nach TALK senden.
.ACPTR			= $ffa5				;Byte-Eingabe vom IEC-Bus.
.CIOUT			= $ffa8				;Byte-Ausgabe auf IEC-Bus.
.UNTALK			= $ffab				;UNTALK-Signal auf IEC-Bus senden.
.UNLSN			= $ffae				;UNLISTEN-Signal auf IEC-Bus senden.
.LISTEN			= $ffb1				;LISTEN-Signal auf IEC-Bus senden.
.TALK			= $ffb4				;TALK-Signal auf IEC-Bus senden.
.SETLFS			= $ffba				;Dateiparameter setzen.
.SETNAM			= $ffbd				;Dateiname setzen.
.OPENCHN		= $ffc0				;Datei öffnen.
.CLOSE			= $ffc3				;Datei schließen.
.CHKIN			= $ffc6				;Eingabefile setzen.
.CKOUT			= $ffc9				;Ausgabefile setzen.
.CLRCHN			= $ffcc				;Standard-I/O setzen.
.CHROUT			= $ffd2				;Zeichen ausgeben.
.GETIN			= $ffe4				;Zeichen einlesen.
.CLALL			= $ffe7				;Alle Kanäle schließen.

;*** C128-Kernal Einsprünge.
;--- Ergänzung: 26.11.18/M.Kanet
;SETBNK ist im GEOS-Kernal nicht vohanden, da beim C128 die
;Einsprungadressen im KERNAL durch eine BANK-Switch-Routine ersetzt
;wurden. Die Routine muss daher manuell nachgebildet werden!
;SETBNK			= $ff68				;Speicherbank für Dateiname/LOAD setzen.

;*** Einsprünge im RAMLink-Kernal.
.EN_SET_REC		= $e0a9
.RL_HW_EN		= $e0b1
.SET_REC_IMG		= $fe03
.EXEC_REC_REU		= $fe06
.EXEC_REC_SEC		= $fe09
.RL_HW_DIS		= $fe0c
.RL_HW_DIS2		= $fe0f
.EXEC_REU_DIS		= $fe1e
.EXEC_SEC_DIS		= $fe21

;*** Variablen für Dialogboxen.
.IBoxLeft		= 107
.IBoxBase1		= 80
.IBoxBase2		= 90
.DBoxLeft		= 51
.DBoxBase1		= 24
.DBoxBase2		= 34
endif

;******************************************************************************
;*** Liste der Laufwerkstypen für :DriveTypes.
;******************************************************************************
if .p
;*** Unterstützte Laufwerkstypen.
;Bei Änderungen an der Nummerierung sind die Datentabellen anzupassen.
; -> DriveType-Datentabelle:
;    -src.GetDrive
;    -dos.FormatRename
;    -cbm.FormatRename
.Drv_None		= 0				;Kein Laufwerk.
.Drv_1541		= 1				;Commodore 1541 (I,C,II).
.Drv_1571		= 2				;Commodore 1571.
.Drv_1581		= 3				;Commodore 1581.
.Drv_R1541		= 4				;RAMDisk 170 Kbyte = 1541.
.Drv_R1571		= 5				;RAMDisk 340 Kbyte = 1571.
.Drv_R1581		= 6				;RAMDisk 790 Kbyte = 1581.
.Drv_RNAT		= 7				;RAMDisk Native.
.Drv_GWRD		= 8				;GateWay RAMDisk Native.
.Drv_CMDRL		= 9				;CMD RAMLink.
.Drv_CMDRD		= 10				;CMD RAMDrive.
.Drv_CMDFD2		= 11				;CMD FD2000.
.Drv_CMDFD4		= 12				;CMD FD4000.
.Drv_CMDHD		= 13				;CMD HD.
.Drv_64Net		= 14				;64Net.
.Drv_DOS_1581		= 15				;DOS 1581
.Drv_DOS_FD2		= 16				;DOS FD2000
.Drv_DOS_FD4		= 17				;DOS FD4000
.Drv_Native		= 18				;IECBus Native.

;*** Laufwerke bei der Hardware-Erkennung.
;    Später nicht mehr verfügbar!
.Drv_CMDRL_GW		= 19				;gateWay CMD RAMLink.
.Drv_RAMDrv_GW		= 20				;gateWay RAMDrive.
.Drv_CMDRLNat		= 21				;Native-Mode CMD RAMLink.
.Drv_RAMDrvNat		= 22				;Native-Mode RAMDrive.
.Drv_CMDRLNat_GW	= 23				;gateWay CMD RAMLink.
.Drv_RAMDrvNat_GW	= 24				;gateWay RAMDrive.
.Drv_CMDFD2nat		= 25				;Native-Mode CMD FD2000.
.Drv_CMDFD4nat		= 26				;Native-Mode CMD FD4000.
.Drv_CMDHDnat		= 27				;Native-Mode CMD HD.
.Drv_Unknown		= 28				;Unbekannte Laufwerkstypen.
endif

;******************************************************************************
;*** Systemdaten.
;******************************************************************************
.GD_OS_VARS

;*** GeoDOS-Systemvariablen.
			t "-GD_System"

;*** Tabelle mit Farbwerten.
			t "-ColorData"

;*** Ende Systemvariablen.
.GD_OS_VARS2

;******************************************************************************
;*** Systemvariablen.
;******************************************************************************

;*** Systemvariablen im Infoblock.
:IBlockSektor		s 256
			t "-IBlockData"

;*** Klasse der Systemdateien.
:ToolClass		w AppClass
			w CopyClass
			w DOS_Class
			w CBM_Class

:CopyClass		b "GD_Copy     V2.1",NULL
:DOS_Class		b "GD_DOS      V2.1",NULL
:CBM_Class		b "GD_CBM      V2.2",NULL
:DDrvClass		b "GD_DOSDRIVE V2.2",NULL

;*** Variablen.
:V000a0			b $00
:V000a1			b $00
:V000a2			s $04
:V000a3			b $00
:V000a4			b $00
:V000a5			b $00
:V000a6			b $00

:V000b0			b "G-P",$ff,$0d
:V000b1			s 31

:V000c0			b $00				;Anzahl Partitionen.
:V000c1			b "$=P:*=8"
:V000c2			b $00,"478N",$00,$00,$00

if Sprache = Deutsch
;*** Text für neuen Infoblock.
:V000d0			b 100,10,1
:V000d1			b "GeoDOS wird geladen von",CR
:V000d2			b "Laufwerk  xxxxxxx /000",NULL

;*** Suchtexte...
:V000e0			b PLAINTEXT
			b GOTOXY
			w $0040
			b $40
			b "Suche GeoDOS..."
			b GOTOXY
			w $0040
			b $49
			b "bitte etwas Geduld...",NULL

:V000e1			b "Laufwerk A:",NULL
:V000e2			b GOTOX
			w $0094
			b "Part#",NULL
:V000e3			b GOTOX
			w $0094
			b "erfolglos...",NULL
:V000e4			b GOTOX
			w $0094
			b "OK!         ",NULL

:V000e5			b 96,107,118,129		;Ausgabezeilen.

:V000e6			b GOTOX
			w $0094
			b "(kein)      ",NULL

;*** Text für DeskTop-Start.
:V000f0			b PLAINTEXT
			b GOTOXY
			w $0008
			b $c2
			b "GeoDOS wird gestartet...",NULL

;*** Lade-Fehler.
:V000g1			w :101, :102, ISet_Achtung
::101			b BOLDON,"Systemlaufwerk defekt",NULL
::102			b        "oder Systemdatei fehlt!",NULL

;*** Hinweis: "Keine RAM-Erweiterung!"
:V000g2			w :101, :102, ISet_Achtung
::101			b BOLDON,"GeoDOS-Hauptprogramm ist",NULL
::102			b        "nicht auf Laufwerk A: bis D: !",NULL
endif

if Sprache = Englisch
;*** Text für neuen Infoblock.
:V000d0			b 100,10,1
:V000d1			b "Boot GeoDOS from",CR
:V000d2			b "diskdrive xxxxxxx /000",NULL

;*** Suchtexte...
:V000e0			b PLAINTEXT
			b GOTOXY
			w $0040
			b $40
			b "Searching for GeoDOS."
			b GOTOXY
			w $0040
			b $49
			b "Please wait...",NULL

:V000e1			b "Drive    A:",NULL
:V000e2			b GOTOX
			w $0094
			b "Part#",NULL
:V000e3			b GOTOX
			w $0094
			b "not found...",NULL
:V000e4			b GOTOX
			w $0094
			b "OK!         ",NULL

:V000e5			b 96,107,118,129		;Ausgabezeilen.

:V000e6			b GOTOX
			w $0094
			b "(none)      ",NULL

;*** Text für DeskTop-Start.
:V000f0			b PLAINTEXT
			b GOTOXY
			w $0008
			b $c2
			b "Start GeoDOS...",NULL

;*** Lade-Fehler.
:V000g1			w :101, :102, ISet_Achtung
::101			b BOLDON,"Systemdrive or GeoDOS",NULL
::102			b        "is corrupt!",NULL

;*** Hinweis: "Keine RAM-Erweiterung!"
:V000g2			w :101, :102, ISet_Achtung
::101			b BOLDON,"GeoDOS-application not",NULL
::102			b        "found on drive A: to D: !",NULL
endif

;******************************************************************************
;*** Haupt-Programmteil.
;******************************************************************************
			t   "-FontType1"
			t   "-ColorBox64"
			t   "-SetColorGD"
			t   "-ConvertChar"
			t   "-PrintText"
			t   "-DialogBox"
			t   "-InfoBox"
			t   "-DoZahl24Bit"
			t   "-ZahlToASCII"
			t   "-FloppyCom"
			t   "-SetNewPart"
			t   "-GetPartInfo"
			t   "-ClrPartInfo"
			t   "-SaveDrive"
			t   "-SystemDrive"
			t   "-BootDrive"
			t   "-CheckDiskCBM"
			t   "-NewOpenDisk"
			t   "-CMD_Native"
			t   "-PrepGetFile"
			t   "-LookForFile"
			t   "-Addition"
;******************************************************************************

;*** Hardware testen.
:GD_Hardware		bit	ScreenMode
			bpl	:101
			jmp	InitTest

::101			jsr	UseGDFont
			jsr	i_C_ColorClr
			b	$00,$00,$28,$19

			Display	ST_WR_FORE
			Pattern	0
			FillRec	0,199,0,319		;Bildschirm löschen.
			jsr	ClrBackCol		;GeoDOS-Standard-Farben.

			Pattern	0
			FillRec	8,23,8,311
			lda	#%11111111
			jsr	FrameRectangle
			FrameRec 10, 21, 11,308,%11111111
			FrameRec 11, 20, 12,307,%11111111
			jsr	i_C_MenuBack
			b	$01,$01,$26,$02
			Print	 48,18
			b	PLAINTEXT,"GeoDOS 64 - ",NULL
			PrintStrgVersion
			Print	181,18
			b	PLAINTEXT,"(c) 1995-2023",NULL

			Pattern	0
			FillRec	176,191,8,311
			lda	#%11111111
			jsr	FrameRectangle
			FrameRec178,189, 11,308,%11111111
			FrameRec179,188, 12,307,%11111111
			jsr	i_C_MenuBack
			b	$01,$16,$26,$02

			Print	 48,186			;Versions-Nr. ausgeben.
			b	"Revision :    ",NULL
			PrintStrgVersionCode

			Window	40,151,48,271
			jsr	i_BitmapUp
			w	Icon_Close
			b	$06,$28,$01,$08

if Sprache = Deutsch
			Print	64,46
			b	"Initialisierung...",NULL
			Print	64,64
			b	"Hardware wird getestet,"
			b	GOTOXY
			w	64
			b	73
			b	"bitte etwas Geduld...",NULL

endif

if Sprache = Englisch
			Print	64,46
			b	"Initialising...",NULL
			Print	64,64
			b	"Testing hardware,"
			b	GOTOXY
			w	64
			b	73
			b	"please wait...",NULL

endif

;******************************************************************************
			t   "-HardwareTest"
;******************************************************************************
			t   "-CheckRAM"
;******************************************************************************

;*** Neues Laufwerk anmelden.
:NewDrive		jsr	SetDevice		;Neues Laufwerk definieren.
			txa
			bne	:101			;Laufwerks-Fehler.

			ldx	curDrive		;Aktuelles Laufwerk als "ACTION_DRV"
			stx	Action_Drv		;zwischenspeichern.
			lda	DriveTypes-8,x		;Laufwerks-Typ definieren.
			sta	curDrvType
			lda	DriveModes-8,x		;Emulations-Modus definieren.
			sta	curDrvMode
			and	#%00001000		;RAM-Modus definieren.
			sta	curDriveRAM
			ldx	#$00			;Kein Fehler.
::101			rts				;Rücksprung.

;*** Hauptverzeichnis wählen.
:SetCMD_Root		lda	curDrvMode
;--- Ergänzung: 28.11.2018/M.Kanet
;NativeMode ist auch auf Nicht-CMD-Laufwerken möglich.
;			bpl	:101
			and	#%00100000
			beq	:101
			jmp	New_CMD_Root
::101			jmp	NewOpenDisk

;*** GeoDOS Disketten-Fehler.
:GDDiskError		jsr	ClrScreen
			DB_CANCELV000g1

;*** GeoDOS beenden, Partition einstellen und zum DeskTop.
:ExitDT			jsr	OpenBootDrive

			lda	#8			;Laufwerk #8 aktivieren.
			jsr	SetDevice
			jsr	NewOpenDisk		;Diskette öffnen.

			jsr	ClrScreen
			jsr	i_C_GEOS
			b	$00,$00,$28,$19

			jsr	InitForIO		;Mauszeiger & Rahmenfarbe zurücksetzen.
			lda	C_GEOS_MOUSE
			sta	$d027
			lda	C_GEOS_FRAME
			sta	$d020
			jsr	DoneWithIO

			jmp	EnterDeskTop		;Zum DeskTop.

;*** Bildschirm löschen.
:ClrScreen		jsr	ClrBackCol
			jmp	ClrBitMap

;*** Bildschirm löschen.
:Clr2BitMap		jsr	ClrBackScr

:ClrBitMap		jsr	i_FillRam
			w	8000,SCREEN_BASE
			b	$00
			rts

:ClrBackScr		jsr	i_FillRam
			w	8000,SCREEN_BASE
			b	$00
			rts

;*** Hintergrundfarben setzen.
:ClrBackCol		jsr	i_C_ColorClr
			b	$00,$00,$28,$19
			rts

;******************************************************************************
;GeoDOS initialisieren.
;******************************************************************************

;*** Programm initialisieren.
:MainInit		bit	c128Flag
			bpl	:101

			lda	graphMode
			and	#%01111111
			sta	graphMode
			jsr	SetNewMode

::101			lda	curDrive		;Start-Laufwerk merken.
			sta	BootDrive

			jsr	InitForIO		;Bildschirm-Farben speichern.
			lda	$d020
			sta	C_GEOS_FRAME
			lda	$d027
			sta	C_GEOS_MOUSE
			lda	screencolors
			sta	C_GEOS_BACK
			jsr	DoneWithIO

;*** Infoblock einlesen.
:InitSystem		jsr	GetIBlock		;Infoblock einlesen.

			lda	IBlockSektor+$45
			cmp	#DESK_ACC		;Hilfsmittel ?
			bne	:101			;Nein, weiter...
			jsr	DelSwapFile		;SWAP-Datei löschen.

;*** Neustart ausführen ?
::101			clc				;Auf "*RESET*"-Kennung testen.
			lda	IBlockSektor+$a0
			adc	IBlockSektor+$a1
			adc	IBlockSektor+$a2
			adc	IBlockSektor+$a3
			adc	IBlockSektor+$a4
			adc	IBlockSektor+$a5
			adc	IBlockSektor+$a6
			cmp	#$d8
			bne	IsGD_DeskTop

			ClrB	SYS_Installed		;BootGD erneut installieren.
			jmp	BootStandard

;*** GeoDOS als DeskTop ?
:IsGD_DeskTop		lda	SYS_Installed		;BootGD bereits installiert ?
			bne	:102			;Ja, weiter...
::101			jmp	BootStandard		;Noch nicht installiert, dann
							;Hardwaretest ausführen.

::102			ldy	#$06			;GeoDOS als DeskTop
::103			lda	BootFileName,y		;installiert ?
			cmp	$c3cf,y
			bne	:101			;Nein, Hardware-Test durchführen.
			dey
			bpl	:103
			jmp	BootDeskTop

;*** BootGD-Bildschirmfarben setzen.
:ScreenBootGD		jsr	InitForIO		;Startfarben setzen.
			lda	C_ScreenBack
			and	#%00001111
			sta	$d020
			lda	C_Mouse
			sta	$d027
			jsr	DoneWithIO

			jmp	ClrScreen		;Bildschirm löschen.

;******************************************************************************
;*** BootGD als DeskTop starten.
;******************************************************************************
:BootDeskTop		jsr	ScreenBootGD		;BootGD-Bildschirmfarben setzen.

			jsr	CheckRAM		;Konfiguration testen.
			txa				;Abbruch ?
			bne	:101			;Ja, Ende.

			jsr	InitForIO		;Bildschirmfarben setzen.
			lda	#$00
			sta	$d020
			sta	$d021
			lda	#$06
			sta	$d027
			jsr	DoneWithIO

			jsr	i_ColorBox
			b	$00,$00,$28,$19,$00
			jsr	ClrBitMap

			Display	ST_WR_FORE
			Pattern	0
			FrameRec$b8,$c7,$0000,$013f,%11111111

			jsr	UseGDFont		;"GeoDOS wird geladen..."
			PrintStrgV000f0

			jsr	i_ColorBox
			b	$00,$17,$28,$02,$36

;*** Hardware testen.
			LoadB	ScreenMode,$ff		;Bildschirm-Modus "BootGD" definieren.
			jsr	GD_Hardware		;Hardware testen.
			jmp	CheckConfig		;Test fortsetzen.
::101			jmp	ExitDT			;Zum DeskTop zurück.

;******************************************************************************
;*** BootGD als DA/Applikation starten.
;******************************************************************************
:BootStandard		jsr	ScreenBootGD		;BootGD-Bildschirmfarben setzen.

;*** Auf Süpeichererweiterung testen.
:TestForRAM		jsr	CheckRAM		;Konfiguration testen.
			txa				;Abbruch ?
			beq	StartTest		;Nein, weiter...
			jmp	ExitDT			;Zum DeskTop zurück.

;*** Hardware testen.
:StartTest		LoadB	ScreenMode,$00		;Bildschirm-Modus "BootGD" definieren.
			jsr	GD_Hardware		;Hardware testen.

;*** Konfiguration testen.
:CheckConfig		ldy	#$00			;Konfiguration OK.
			sty	CBM_Count		;Anz. CBM-Drives zählen und
			sty	DOS_Count		;Anz. DOS-Drives zählen.
::101			lda	DriveTypes,y
			beq	:102
			inc	CBM_Count
			lda	DriveModes,y
			and	#%00010000
			beq	:102
			inc	DOS_Count
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

;*** Laufwerksinfos einlesen, Boot-Informationen speichern.
			jsr	GetDrvInfo		;Laufwerksinformationen einlesen.
			jsr	SaveBootData		;Startwerte merken.
			jmp	InitBootGD		;BootGD installieren.

;*** Nächstes GEOS-Laufwerk suchen.
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

;******************************************************************************
;*** Installationsmodus testen.
;******************************************************************************
:InitBootGD		lda	SYS_Installed
			beq	StartSearchGD		;BootGD installiert, weiter...

			ldy	#$08
			sty	V000a6
:TestCurType		ldx	SYS_GD64Drive
			lda	SYS_DriveType  -8,x
			cmp	DriveTypes     -8,y
			beq	TestInstall

;*** Nächsten Laufwerkstyp finden, auf dem GeoDOS
;    installiert sein könnte.
:FindNextDrive		inc	V000a6
			ldy	V000a6
			cpy	#$0c
			bcc	TestCurType
:StartSearchGD		jmp	FindGeoDOS

;*** Installations-Laufwerk öffnen und GeoDOS suchen.
:TestInstall		tya
			jsr	NewDrive		;Laufwerk aktivieren.

			bit	curDrvMode		;CMD-Laufwerk ?
			bpl	:101			;Nein, weiter...

			lda	SYS_GD64_Part		;Letzte GeoDOS-Partition aktivieren.
			jsr	SetNewPart

::101			lda	curDrvMode
			and	#%00100000
			beq	:102

			jsr	SetCMD_Root		;Hauptverzeichnis starten.
			txa				;Diskettenfehler ?
			bne	FindNextDrive		;Ja, Abbruch.
			lda	SYS_GD64_NM_T
			beq	:102
			sta	r1L
			lda	SYS_GD64_NM_S
			sta	r1H
			jsr	New_CMD_SubD
			txa				;Diskettenfehler ?
			bne	FindNextDrive		;Ja, Abbruch.

::102			jsr	IsGDonDisk		;GeoDOS auf Diskette suchen.
			txa				;Programm gefunden ?
			bne	FindNextDrive		;Nein, weitersuchen.
			jmp	StartUpGD		;GeODOS starten.

;*** Ist GeoDOS auf aktueller Diskette ?
:IsGDonDisk		lda	#APPLICATION
			ldx	#<AppClass
			ldy	#>AppClass
			jsr	LookForFile		;GeoDOS als Applikation suchen.
			txa
			beq	:101

			lda	#AUTO_EXEC
			ldx	#<AppClass
			ldy	#>AppClass
			jsr	LookForFile		;GeoDOS als AutoExec suchen.
			txa
			beq	:101

			ldx	#$ff			;GeoDOS nicht gefunden.
::101			rts

;*** Ist GeoDOS auf Laufwerk/Partition ?
:IsGDonPart		bit	curDrvMode		;CMD-Laufwerk ?
			bpl	:101			;Nein, Abbruch.
			jsr	ReadAllParts		;Alle partitionen einlesen.
			cpx	#$00			;Diskettenfehler ?
			beq	:102			;Nein, weiter...
::101			ldx	#$ff			;GeoDOS nicht gefunden.
			rts

::102			cmp	#$02			;Mehr als eine Partitionen verfügbar ?
			bcc	:101			;Nein, Abbruch.
			sta	V000a4

			ldx	#$00
::103			stx	V000a5
			lda	FilePTab,x		;Partition einlesen.
			pha
			jsr	PrnCurPartNr		;Aktive Partition anzeigen.
			pla
			jsr	SetNewPart		;Partition aktivieren.
			txa				;Diskettenfehler ?
			bne	:104			;Ja, Abbruch.

			jsr	IsGDonDisk		;GeoDOS auf Diskette suchen.
			txa				;Programm gefunden ?
			bne	:104			;Nein, weitersuchen.
			rts				;GeoDOS gefunden, Ende...

::104			ldx	V000a5
			inx				;Zeiger auf nächste Partition.
			cpx	V000a4			;Alle Partitionen getestet ?
			bne	:103			;Nein, weiter...

			ldx	curDrive
			lda	DrivePart -8,x
			jsr	SetNewPart		;Partition zurücksetzen.
			ldx	#$ff			;GeoDOS nicht gefunden.
			rts

;*** GeoDOS auf Disketten in Laufwerk A: bis D: suchen.
;    Wenn nicht gefunden, auf allen Partitionen
;    weitersuchen.
:FindGeoDOS		FillPRec$00,$31,$96,$0031,$0106
			jsr	UseGDFont

			PrintStrgV000e0

			jsr	GetDriveTab

			ldx	#$00
::101			stx	V000a1
			ldy	V000a2,x
			beq	:105
			lda	DriveTypes -8,y
			beq	:105
			sty	V000a3

			jsr	PrnCurDrive		;Aktuelles Laufwerk anzeigen.

			lda	V000a3
			jsr	NewDrive		;Laufwerk aktivieren.
			txa				;Diskettenfehler ?
			bne	:104			;Ja, Abbruch...

			bit	curDrvMode		;CMD-Laufwerk ?
			bpl	:102			;Nein, weiter...

			ldx	V000a3
			lda	DrivePart  -8,x
			jsr	SetNewPart		;Partition aktivieren.
			txa				;Diskettenfehler ?
			bne	:104			;Ja, Abbruch.
			beq	:103			;GeoDOS suchen.

::102			jsr	CheckDiskCBM		;Auf Disk im Laufwerk testen.
			txa				;Diskettenfehler ?
			bne	:104			;Ja, Abbruch...

			jsr	NewOpenDisk		;Aktuelle Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:104			;Ja, Abbruch...

::103			jsr	IsGDonDisk		;GeoDOS auf Diskette suchen.
			txa				;Programm gefunden ?
			bne	:104			;Nein, weitersuchen...
			jmp	GD_Found		;GeoDOS starten.

::104			lda	#<V000e3
			ldx	#>V000e3
			jsr	PrintText

::105			ldx	V000a1
			inx				;Zeiger auf nächstes Laufwerk.
			cpx	#$04			;Alle Laufwerke getestet ?
			bne	:101			;Nein, weiter...

;*** GeoDOS nicht auf Diskette in Laufwerk A: bis D:.
;    Programm auf allen Laufwerken und allen Partitionen
;    suchen. Wenn nicht gefunden, Fehler ausgeben.
:FindGeoDOS_P		FillPRec$00,$31,$96,$0031,$0106
			jsr	UseGDFont

			PrintStrgV000e0

			jsr	GetDriveTab

			ldx	#$00
::101			stx	V000a1
			ldy	V000a2,x
			beq	:103
			lda	DriveTypes -8,y
			beq	:103
			lda	DriveModes -8,y
			bpl	:103
			sty	V000a3

			jsr	PrnCurDrive		;Aktuelles Laufwerk anzeigen.

			lda	V000a3
			jsr	NewDrive		;Laufwerk aktivieren.
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch...

			jsr	CheckDiskCBM		;Auf Disk im Laufwerk testen.
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch...

			jsr	NewOpenDisk		;Aktuelle Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch...

			ldx	V000a1
			lda	V000e5,x
			sta	r1H
			PrintStrgV000e2			;Aktive Partition anzeigen.
			jsr	IsGDonPart		;GeoDOS auf allen Partitionen suchen.
			txa				;Programm gefunden ?
			bne	:102			;Nein, weitersuchen...
			jmp	GD_Found		;GeoDOS starten.

::102			lda	#<V000e3
			ldx	#>V000e3
			jsr	PrintText

::103			ldx	V000a1
			inx				;Zeiger auf nächstes Laufwerk.
			cpx	#$04			;Alle Laufwerke getestet ?
			bne	:101			;Nein, weiter...

;*** GeoDOS nicht gefunden.
:GD_NotFound		jsr	ClrScreen
			DB_CANCELV000g2
			jmp	ExitDT

;*** GeoDOS gefunden. Programm starten.
:GD_Found		lda	#<V000e4		;Hinweistext ausgeben.
			ldx	#>V000e4
			jsr	PrintText
			jmp	StartUpGD

;*** Aktuelles Laufwerk ausgeben.
:PrnCurDrive		lda	V000a3
			clc
			adc	#$39
			sta	V000e1+9
			lda	V000e5,x
			sta	r1H
			LoadW	r11,$0040
			PrintStrgV000e1
			rts

;*** Partitions-Nr. anzeigen.
:PrnCurPartNr		sta	r0L
			ClrB	r0H
			ldx	V000a1
			lda	V000e5,x
			sta	r1H
			LoadW	r11L,$00b9
			lda	#%11000000
			jmp	PutDecimal

;*** Text anzeigen.
:PrintText		sta	r0L
			stx	r0H
			ldx	V000a1			;Text "OK" (GeoDOS gefunden)
			lda	V000e5,x		;ausgeben.
			sta	r1H
			LoadW	r11,$0094
			jmp	PutString

;******************************************************************************
;*** Systemvariablen initialisieren.
;******************************************************************************
:StartUpGD		jsr	SaveAppData		;Applikations-Laufwerk merken.

;*** GeoDOS-Hauptprogrammteil laden.
			LoadW	r0,AppNameBuf		;VLIR-Datei öffnen.
			jsr	OpenRecordFile
			jsr	CloseRecordFile

			lda	fileHeader+2
			sta	r1L
			lda	fileHeader+3
			sta	r1H
			LoadW	r2,$3c00
			LoadW	r7,$0400
			jsr	ReadFile		;GeoDOS-Kernal einlesen.

;*** Zurück zum Boot-Laufwerk.
:BackToBoot		ldx	curDrive		;Partition auf aktuellem Laufwerk
			lda	DriveModes-8,x		;wieder zurücksetzen.
			bpl	:101

			lda	DrivePart -8,x
			jsr	SetNewPart

::101			jsr	OpenBootDrive		;Boot-Laufwerk/Partition aktivieren.
			jsr	PutIBlock		;Boot-Daten speichern.

			jsr	i_MoveData		;Systemvariablen in Transferbereich
			w	GD_OS_VARS		;übertragen.
			w	PRINTBASE
			w	(GD_OS_VARS2 - GD_OS_VARS)

			jmp	$0400			;GeoDOS starten.

;*** CMD-Erkennung senden.
:SendGP_com		sta	V000b0+3

			ldx	#$0f
			jsr	CKOUT

			lda	#$00
			sta	:101 +1
::101			ldy	#$ff
			cpy	#$05
			beq	:102
			lda	V000b0,y
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
			sta	V000b1,y
			inc	:101 +4
			jmp	:101

::102			jmp	CLRCHN

;*** Boot-Informationen speichern.
:SaveBootData		lda	BootDrive
			jsr	NewDrive		;Boot-Laufwerk aktivieren.

;--- Hinweis:
;Unter MP3/GDOS64 können mehrere
;RAMLink-Laufwerke eingerichtet werden.
;Damit driveData+3 aktualisiert wird,
;muss hier über die Routine EnterTurbo
;driveData+3 aktualisiert werden.
			jsr	EnterTurbo
;---

			lda	curDrvType
			sta	BootType		;Laufwerkstyp merken.
			lda	curDrvMode
			sta	BootMode		;Laufwerksmodus merken.

;--- Ergänzung: 28.11.18/M.Kanet
;NativeMode ist auch auf Nicht-CMD-Laufwerken möglich.
			bit	curDrvMode		;CMD-Laufwerk ?
;			bpl	:102			;Nein, weiter...
			bpl	:101			;Nein, auf SD2IEC/RAMNative testen...

			ldx	BootDrive
			lda	DrivePart -8,x
			sta	BootPart		;Boot-Partition merken.

			lda	BootMode
			and	#%01000000
			beq	:101

			lda	ramBase   -8,x		;RAMLink-Boot-Partition merken.
			sta	BootRLpart+0
			lda	driveData +3
			sta	BootRLpart+1

::101			lda	BootMode
			and	#%00100000
			beq	:102

			jsr	GetDirHead		;NativeMode-Boot-Verzeichnis merken.
			lda	curDirHead+32
			sta	BootNDir  + 0
			lda	curDirHead+33
			sta	BootNDir  + 1

::102			rts

;*** GeoDOS-Informationen speichern.
:SaveAppData		lda	curDrive
			sta	AppDrv
			jsr	NewDrive		;Applikationslaufwerk aktivieren.

			lda	curDrvType
			sta	AppType			;Laufwerkstyp speichern.
			lda	curDrvMode
			sta	AppMode

			bit	curDrvMode		;CMD-Laufwerk ?
			bpl	:102			;Nein, weiter...

			jsr	GetCurPInfo		;Aktive partition einlesen.
			txa				;Diskettenfehler ?
			beq	:101			;Nein, weiter...
			ldy	#$01			;Vorgabe-Partition #1.
::101			sty	AppPart			;GeoDOS-Partition speichern.

			lda	AppMode
			and	#%01000000
			beq	:102

			lda	Part_Info +22		;RAMLink-Partition speichern.
			sta	AppRLPart + 0
			lda	Part_Info +23
			sta	AppRLPart + 1

::102			lda	AppMode
			and	#%00100000
			beq	:105

			jsr	GetDirHead		;NativeMode-Verzeichnis speichern.
			txa				;Diskettenfehler ?
			beq	:103			;Nein, weiter...

			jsr	New_CMD_Root		;Hauptverzeichnis anwählen.
			lda	#$01
			tax
			bne	:104

::103			lda	curDirHead+32		;Aktuelles Verzeichnis einlesen.
			ldx	curDirHead+33

::104			sta	AppNDir   + 0
			stx	AppNDir   + 1

::105			jsr	i_MoveData		;Programm-Name speiuchern.
			w	FileNameBuf
			w	AppNameBuf
			w	16
			rts

;*** Hilfsmittel-SwapFile löschen.
:DelSwapFile		LoadW	r0,SwapFileNm		;SwapFile löschen.
			jsr	DeleteFile
			txa
			beq	DelSwapFile
			rts

:SwapFileNm		b $1b,"Swap File",NULL

;*** Laufwerke ermitteln.
:GetDriveTab		ldy	#$00
			ldx	#8
::101			lda	#$00
			sta	V000a2,y
			lda	DriveTypes-8,x		;Laufwerk vorhanden ?
			beq	:102			;Nein, weiter...
			lda	DriveModes-8,x		;Laufwerksmodus einlesen...
			and	#%00001000		;Aktuelles Laufwerk = RAM-Laufwerk ?
			beq	:102			;Nein, weiter...
			txa				;Laufwerk in Tabelle eintragen.
			sta	V000a2,y
			iny				;Zähler für "Laufwerke in Tabelle"
			cpy	#4			;korrigieren. Tabelle voll ?
			beq	:105			;Ja, Ende...
::102			inx				;Zeiger auf nächstes Laufwerk.
			cpx	#12			;Laufwerke 8-11 getestet ?
			bne	:101			;Nein, weiter...

			ldx	#8
::103			lda	#$00
			sta	V000a2,y
			lda	DriveTypes-8,x		;Laufwerk vorhanden ?
			beq	:104			;Nein, weiter...
			lda	DriveModes-8,x		;Laufwerksmodus einlesen.
			and	#%00001000		;Aktuelles Laufwerk = RAM-Laufwerk ?
			bne	:104			;Ja, weiter...
			txa				;Laufwerk in Tabelle eintragen.
			sta	V000a2,y
			iny				;Zähler für "Laufwerke in Tabelle"
			cpy	#4			;korrigieren. Tabelle voll ?
			beq	:105			;Ja, Ende...
::104			inx				;Zeiger auf nächstes Laufwerk.
			cpx	#12			;Laufwerke 8-11 getestet ?
			bne	:103			;Nein, weiter...
::105			rts				;Ende.

;*** Aktuelle Partition ermitteln: RAMLink (über driveData/ramBase) und FD/HD.
:GetDrvInfo		ldx	#$08
::101			stx	V000a0
			lda	DriveTypes-8,x		;Laufwerk verfügbar ?
			beq	:102			;Nein, weiter...
			txa
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	EnterTurbo

			ldx	V000a0
			lda	DriveModes-8,x		;CMD-Laufwerk ?
			bmi	:103			;Ja, Partition einlesen.
::102			jmp	:141

::103			jsr	PurgeTurbo		;GEOS-Turbo deaktivieren und
			jsr	InitForIO		;I/O einschalten.

			ldy	V000a0
			ldx	DriveAdress-8,y
			lda	#$0f
			tay
			jsr	SETLFS
			lda	#$00
			jsr	SETNAM
			jsr	OPENCHN

			ldx	V000a0
			lda	DriveModes-8,x
			and	#%01000000		;RAMLink/RAMDrive?
			bne	:111			; => Ja, weiter...
			jmp	:121			; => Nein, FD/HD Laufwerk.

::111			ldx	#1			;RAMLink-Partition suchen. Dabei
::112			txa				;werden alle Partitionen mit den Werten
			jsr	SendGP_com		;in ":ramBase" und ":driveData+3" auf
			jsr	GetGP_com		;übereinstimmung getestet. Bei der
							;RAMLink muß die BASIC-Partition nicht
			lda	V000b1   + 0		;mit der GEOS-Partition übereinstimmen!
			beq	:113			;Routine nicht entfernen!

			ldx	curDrive
			lda	ramBase  - 8,x
			cmp	V000b1   +20
;--- Hinweis:
;Es ist ausreichend nur das High-Byte
;der RAMLink-Adresse zu testen.
;			bne	:113
;			lda	driveData+ 3
;			cmp	V000b1   +21
;---
			beq	:131

::113			ldx	V000b0 +3		;Falsche Partition, weitersuchen.
			inx
			cpx	#32			;Max. 32 Partitionen getestet ?
			bne	:112			;Nein, weiter...
			jsr	DoneWithIO		;Passiert nur wenn falsche Werte in
			jmp	ExitDT			;":ramBase" & ":driveData+3" gesetzt
							;sind, Partition nicht gefunden.

::121			lda	#$ff			;Partition auf HD/FD einlesen.
			jsr	SendGP_com
			jsr	GetGP_com

::131			ldx	V000a0
			lda	V000b1   +2
			sta	DrivePart-8,x		;Partition speichern.
			lda	#$0f
			jsr	CLOSE
			jsr	DoneWithIO

::141			ldx	V000a0
			inx
			cpx	#$0c			;Alle Laufwerke getestet ?
			beq	:143			;Nein, weiter...
			jmp	:101
::143			rts

;******************************************************************************
:ReadAllParts		jsr	i_FillRam
			w	256,FilePTab
			b	$00

			ldy	curDrive		;Partitions-Modus zum aktiven
			lda	driveType-8,y		;Laufwerk ermitteln.
			and	#%00000111
			tay
			lda	V000c2,y
			beq	:101
			sta	V000c1 +6

::101			jsr	PurgeTurbo
			jsr	InitForIO

			lda	#$00
			sta	V000c0
			sta	STATUS

			ldx	curDrive		;Partitionsverzeichnis einlesen.
			lda	DriveAdress-8,x
			jsr	LISTEN
			bit	STATUS
			bpl	:103
::102			ldx	#$0d			;Fehler: "Laufwerk nicht bereit".
			jmp	Part_Fehler

::103			lda	#$f0			;"$=P:*=x"
			jsr	SECOND
			bit	STATUS
			bmi	:102

::104			ldy	#$00
::105			lda	V000c1,y
			jsr	CIOUT
			iny
			cpy	#$07
			bne	:105
			jsr	UNLSN

			ClrB	STATUS
			ldx	curDrive
			lda	DriveAdress-8,x
			jsr	TALK
			lda	#$f0
			jsr	TKSA
			jsr	ACPTR
			bit	STATUS
			bvc	:106
			ldx	#$05			;Fehler: "Verzeichnis nicht gefunden".
			jmp	Part_Fehler

::106			ldy	#$1f			;Verzeichnis-Header
::107			jsr	ACPTR			;überlesen.
			dey
			bne	:107

;*** Partitionen aus Verzeichnis einlesen.
:RdCMDPart		jsr	ACPTR			;Auf Verzeichnis-Ende
			cmp	#$00			;testen.
			beq	EndRead
			jsr	ACPTR

			jsr	ACPTR			;Partitionsnummer
			ldy	V000c0			;in Tabelle.
			sta	FilePTab,y

			jsr	ACPTR

::101			jsr	ACPTR			;Weiterlesen bis zum
			cmp	#$00
			beq	:104
			cmp	#$22			;Part.-Namen.
			bne	:101

::102			jsr	ACPTR
			cmp	#$22
			bne	:102

;*** Verzeichnis-Ende erreicht ?
::103			inc	V000c0
			CmpBI	V000c0,255
			beq	EndRead

::104			jsr	ACPTR
			cmp	#$00
			bne	:104
			jmp	RdCMDPart

:EndRead		jsr	UNTALK

			ClrB	STATUS			;Status-Byte löschen.
			ldx	curDrive		;Laufwerk abschalten.
			lda	DriveAdress-8,x
			jsr	LISTEN
			lda	#$e0
			jsr	SECOND
			jsr	UNLSN

			ldx	#$00			;Kein Fehler.
:Part_Fehler		jsr	DoneWithIO		;I/O deaktivieren.
			lda	V000c0			;Anzahl Partitionen.
			rts				;Ende.

;*** Text für Infoblock erzeugen.
:DoIB_Text		lda	AppDrv
			sub	8
			asl
			asl
			asl
			tax
			ldy	#$00
::101			lda	Drive_ASCII,x
			sta	V000d2+10,y
			inx
			iny
			cpy	#$07
			bne	:101

			ldx	#$00
			lda	AppPart
::102			cmp	V000d0,x
			bcc	:103
			inc	V000d2+19,x
			sec
			sbc	V000d0,x
			bcs	:102
::103			inx
			cpx	#3
			bne	:102

			ldy	#$a0
			ldx	#$00
::104			lda	V000d1,x
			beq	:105
			sta	IBlockSektor,y
			inx
			iny
			bne	:104
			beq	:106
::105			sta	IBlockSektor,y
			iny
			bne	:105
::106			rts

;*** BootGD-Infoblock einlesen.
:GetIBlock		jsr	GetBootGD_IB

			lda	dirEntryBuf +19
			sta	r1L
			lda	dirEntryBuf +20
			sta	r1H

			LoadW	r4,IBlockSektor
			jmp	GetBlock

;*** Infoblock einlesen.
:GetBootGD_IB		lda	#APPLICATION
			ldx	#<BootClass
			ldy	#>BootClass
			jsr	LookForFile
			txa
			beq	:101

			lda	#AUTO_EXEC
			ldx	#<BootClass
			ldy	#>BootClass
			jsr	LookForFile
			txa
			beq	:101

			lda	#DESK_ACC
			ldx	#<BootClass
			ldy	#>BootClass
			jsr	LookForFile
			txa
			beq	:101

			jmp	GDDiskError
::101			rts

;*** Infoblock aktualisieren.
:UpdateIB		ldy	#$03
::101			lda	SYS_DriveType,y
			cmp	DriveTypes   ,y
			bne	PutIBlock
			lda	SYS_DriveMode,y
			cmp	DriveModes   ,y
			bne	PutIBlock
			lda	SYS_Drive_Adr,y
			cmp	DriveAdress  ,y
			bne	PutIBlock
			dey
			bpl	:101

			lda	SYS_GD64Drive
			cmp	AppDrv
			bne	PutIBlock

			lda	SYS_GD64_Part
			cmp	AppPart
			bne	PutIBlock

			lda	SYS_GD64_PR_L
			cmp	AppRLPart    + 0
			bne	PutIBlock
			lda	SYS_GD64_PR_H
			cmp	AppRLPart    + 1
			bne	PutIBlock

			lda	SYS_GD64_NM_T
			cmp	AppNDir     + 0
			bne	PutIBlock
			lda	SYS_GD64_NM_S
			cmp	AppNDir     + 1
			bne	PutIBlock

			rts

;*** Neue daten speichern.
:PutIBlock		lda	#$ff
			sta	SYS_Installed
			jsr	DoIB_Text

			ldy	#$03
::101			lda	DriveTypes   ,y
			sta	SYS_DriveType,y
			lda	DriveModes   ,y
			sta	SYS_DriveMode,y
			lda	DriveAdress  ,y
			sta	SYS_Drive_Adr,y
			dey
			bpl	:101

			lda	AppDrv
			sta	SYS_GD64Drive

			lda	AppPart
			sta	SYS_GD64_Part

			lda	AppRLPart    + 0
			sta	SYS_GD64_PR_L
			lda	AppRLPart    + 1
			sta	SYS_GD64_PR_H

			lda	AppNDir     + 0
			sta	SYS_GD64_NM_T
			lda	AppNDir     + 1
			sta	SYS_GD64_NM_S

			PushB	curDrive

			lda	BootDrive
			jsr	NewDrive
			jsr	NewOpenDisk

			jsr	GetBootGD_IB

			lda	dirEntryBuf +19
			sta	r1L
			lda	dirEntryBuf +20
			sta	r1H

			LoadW	r4,IBlockSektor
			jsr	PutBlock

			pla
			jmp	NewDrive

;******************************************************************************
;			e FilePTab
;******************************************************************************
