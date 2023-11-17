; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

; geoDOS 64
; (w) by Markus Kanet

			a "M. Kanet",NULL
			f APPLICATION
			o $0400
			p MainInit
			n "geoDOS.obj",NULL
			i
<MISSING_IMAGE_DATA>
			z $80

if .p
			t "TopSym"
			t "TopMac"
			t "mac.geoDOS"
endif

.VersionCode		b PLAINTEXT,"030496-"
.Ser_No			b "$0000-"

			c "geoDOS      V1.1",NULL
.Version		b PLAINTEXT,"V1.10",NULL
:AppClass		b "geoDOS      V1.1",NULL

;*** Unterstützte Laufwerkstypen.
.Drv_None		= 0				;Kein Laufwerk.
.Drv_1541		= 1				;Commodore 1541 (I,C,II).
.Drv_1571		= 2				;Commodore 1571.
.Drv_1581		= 3				;Commodore 1581.
.Drv_R1541		= 4				;RAM-Drive 170 Kbyte = 1541.
.Drv_R1571		= 5				;RAM-Drive 340 Kbyte = 1571.
.Drv_R1581		= 6				;RAM-Drive 790 Kbyte = 1581.
.Drv_CMDRL		= 7				;CMD RAMLink.
.Drv_RAMDrv		= 8				;RAMDrive.
.Drv_CMDFD2		= 9				;CMD FD2000.
.Drv_CMDFD4		= 10				;CMD FD4000.
.Drv_CMDHD		= 11				;Native-Mode CMD HD.
.Drv_CMDRLnat		= 12				;Native-Mode CMD RAMLink.
.Drv_RAMDrvnat		= 13				;Native-Mode RAMDrive.
.Drv_CMDFD2nat		= 14				;Native-Mode CMD FD2000.
.Drv_CMDFD4nat		= 15				;Native-Mode CMD FD4000.
.Drv_CMDHDnat		= 16				;Native-Mode CMD HD.
.Drv_Unknown		= 17				;Unbekannte Laufwerkstyp.

.IBoxLeft		= 115
.IBoxBase1		= 80
.IBoxBase2		= 90
.DBoxLeft		= 51
.DBoxBase1		= 24
.DBoxBase2		= 34

;*** Modul-Nummern.
:geoDOS			= 0
:mod_1			= 1
:mod_10			= 2
:mod_20			= 3
:mod_21			= 4
:mod_22			= 5
:mod_30			= 6
:mod_31			= 7
:mod_40			= 8
:mod_41			= 9
:mod_42			= 10
:mod_50			= 11
:mod_100		= 12
:mod_101		= 13

;*** Haupt-Programmteil.
.Font			t "src.FontData"
			t "inc.System #1"
			t "inc.System #2"
			t "inc.System #3"
			t "inc.System #4"

;*** geoDOS Disketten-Fehler.
.GDDiskError		Display	ST_WR_FORE ! ST_WR_BACK
			jsr	ClrScreen
			jsr	UseSystemFont
			LoadW	r0,V001a0
			RecDlgBoxCSet_Grau

;*** geoDOS beenden, Partition einstellen und zum DeskTop.
.ExitDT			lda	AppDrv			;Start-Laufwerk aktivieren.
			jsr	SetDevice

			lda	AppMode			;Geräte-Typ.
			bpl	ExitDT_a		;Kein CMD-Drive, weiter...
			and	#%01000000		;RAM-Partition ?
			beq	:1			;Nein, weiter...

			ldx	curDrive		;RAMLink Partition
			lda	AppRLPart		;wieder herstellen.
			sta	ramBase-8,x
			lda	AppRLPart+1
			sta	driveData+3
			jmp	ExitDT_a

::1			C_Send	DoPrgPart		;CMD-Partition wieder einstellen.

;*** geoDOS beenden, Partition einstellen und zum DeskTop.
.ExitDT_a		lda	AppDrv			;Start-Laufwerk aktivieren.
			jsr	SetDevice
			jsr	OpenDisk		;Diskette öffnen.
			jsr	PrepareExit		;Farben zurücksetzen.
			jmp	EnterDeskTop		;Zum DeskTop.

.PrepareExit		SetColRam1000,0,$00		;Bildschirm löschen.
			jsr	ClrBitMap
			MoveB	screencolors,:1
			jsr	i_FillRam
			w	1000,COLOR_MATRIX
::1			b	$bf

.SetGEOSCol		jsr	InitForIO		;Mauszeiger & Rahmenfarbe zurücksetzen.
			MoveB	colCursor,$d027
			MoveB	colFrame,$d020
			jmp	DoneWithIO

;*** Zurück zum Basic.
.ExitBasic		LoadW	r0,BasicCommand
			LoadW	r7,$0803
			lda	#$00
			sta	r5L
			sta	r5H
			sta	$0800
			sta	$0801
			sta	$0802
			sta	$0803
			jmp	ToBasic

;*** VLIR-Modul laden.
:GetModule		cmp	AktMod			;Gewünschtes Modul im Speicher ?
			bne	:1			;Nein, Modul laden.
			rts				;Ja, Rücksprung.

::1			sta	AktMod			;Modul-Nummer merken.
			stx	:4+1			;Register zwischenspeichern.
			sty	:5+1
			jsr	GetStartDrv		;Start-Laufwerk aktivieren.
			txa
			beq	:3
::2			jmp	GDDiskError		;Disk-Fehler.

::3			ldx	#r0L			;Start-Diskette noch im Laufwerk ?
			jsr	GetPtrCurDkNm
			LoadW	r1,AppDiskName
			ldx	#r0L
			ldy	#r1L
			lda	#$10
			jsr	CmpFString
			bne	:2			;Nein, Disk-Fehler.

			lda	AktMod			;Zeiger auf Anfang VLIR-Modul
			sub	$01			;auf Diskette berechnen.
			asl
			tax
			lda	AppIndex,x
			sta	r1L
			lda	AppIndex+1,x
			sta	r1H
			ClrB	ModCodeAdr
			LoadW	r7,ModCodeAdr
			LoadW	r2,$5fff-ModCodeAdr
			jsr	ReadFile		;Modul in Speicher einlesen.
			txa
			bne	:2			;Disk-Fehler.

			LoadW	r0,ModCodeAdr		;Datei korrekt geladen ?
			LoadW	r1,AppCode
			ldx	#r0L
			ldy	#r1L
			jsr	CmpString
			bne	:2			;Nein, Disk-Fehler.

			jsr	GetWorkDrv		;Arbeitslaufwerk aktivieren.

::4			ldx	#$00			;Register wiederherstellen.
::5			ldy	#$00
			rts				;Rücksprung.

;*** Neues Laufwerk anmelden.
.NewDrive		jsr	SetDevice		;Neues Laufwerk definieren.
			txa
			bne	:1			;Laufwerks-Fehler.
			ldx	curDrive		;Aktuelles Laufwerk als "ACTION_DRV"
			stx	Action_Drv		;zwischenspeichern.
			lda	DriveTypes-8,x		;Laufwerks-Typ definieren.
			sta	curDrvType
			lda	DriveModes-8,x		;Emulations-Modus definieren.
			sta	curDrvMode
			and	#%00001000		;RAM-Modus definieren.
			sta	curDriveRAM
			jsr	JobCodeInit		;Job-Codes initialisieren.
			ldx	#$00			;Kein Fehler.
::1			rts				;Rücksprung.

;*** Startlaufwerk aktivieren.
.GetStartDrv		lda	curDrive		;Aktuelles Laufwerk
			sta	SetWorkDrv +1		;zwischenspeichern.
			lda	#$00
			sta	CMDPartMode
			sta	CMDPartMode+1
			lda	AppDrv			;Start-Laufwerk aktivieren.
			jsr	SetDevice
			jsr	OpenDisk		;Diskette öffnen.
			txa
			beq	:1			;Kein Fehler, weiter...
			rts				;Disk-Fehler.

::1			lda	AppMode			;Start-Partition einstellen.
			bmi	:2
			rts

::2			and	#%01000000
			beq	:3
			ldx	AppDrv			;RAM-Laufwerk (RL,RD)
			lda	ramBase-8,x
			sta	UsrRAMBase
			lda	driveData+3
			sta	UsrRAMBase+1
			lda	AppRLPart
			sta	ramBase-8,x
			lda	AppRLPart+1
			sta	driveData+3
			inc	CMDPartMode+0

::3			InitSPort			;GEOS-Turbo aus und I/O einschalten.
			CxSend	GetCurPart
			CxReceive CurPartDat
			MoveB	CurPartDat+4,DoUsrPart+4
			CxSend	DoPrgPart
			jsr	DoneWithIO
			inc	CMDPartMode +1

			jmp	OpenDisk		;Diskette öffnen.

;*** Workdisk wieder herstellen.
.GetWorkDrv		lda	AppDrv			;Arbeitslaufwerk wieder aktivieren.
			jsr	SetDevice

			lda	CMDPartMode+0		;RAM-Partition wieder einstellen ?
			beq	:1			;Nein, weiter...
			ldx	AppDrv
			lda	UsrRAMBase
			sta	ramBase-8,x
			lda	UsrRAMBase+1
			sta	driveData+3

::1			lda	CMDPartMode+1		;CMD-Partition wieder einstellen ?
			beq	SetWorkDrv		;Nein, weiter...
			C_Send	DoUsrPart

:SetWorkDrv		lda	#$00
			jmp	SetDevice

;*** Menüs deaktivieren.
:ClearMenus		jsr	RecoverAllMenus
			cbBn	mouseOn,6
			Display	ST_WR_FORE
			Pattern	2
			FillRec	160,191,0,319
			rts

;*** Bildschirm löschen.
.ClrScreen		jsr	ClrBackCol
			jmp	ClrBitMap

;*** Bitmap-Muster setzen
.SetBitMap		b $2c				;Muster für SetPattern ignorieren.
							;(Muster im Akku!)
;*** Bitmap löschen.
.ClrBitMap		Display	ST_WR_FORE
			Pattern	2
			FillRec	0,199,0,319
			rts

;*** Hintergrundfarben setzen.
.ClrBackCol		SetColRam1000,0,$b1
			rts

;*** Modul einlesen.
;    Zeiger im Akku.
:CReadMod		pha
			jsr	ClearMenus
			pla

:ReadMod		asl
			asl
			pha
			tay
			lda	ModTabData+0,y
			pha
			ldx	ModTabData+1,y
			lda	ModTabData+2,y
			tay
			pla
			jsr	GetDrvConfig
			pla
			tay
			lda	ModTabData+3,y
			jmp	GetModule

;*** Laufwerk wählen,
;    bei Abbruch zum Menü zurück.
:GetDrvConfig		jsr	SlctDrive
			cpx	#$00
			beq	:1
			jmp	SetMenu
::1			rts

;*** Bildschirm initialisieren.
.InitScreen		lda	#mod_1
			jsr	GetModule
			jmp	ModStart

;*** Bildschirm initialisieren.
.SetMenu		lda	#mod_1
			jsr	GetModule
			jmp	ModStart+3

;*** DOS-Laufwerk wählen.
.SlctDrive		pha
			lda	#mod_1
			jsr	GetModule
			pla
			jmp	ModStart+6

;*** INFO ausgeben.
.m_Info			jsr	GotoFirstMenu

.m_Info_a		lda	#mod_10
			jsr	GetModule
			jmp	ModStart

;*** Kopier-Parameter einstellen.
.m_SetOptions		jsr	ClearMenus
			ldx	#$00

.m_SetOpt1		lda	#mod_20
			jsr	GetModule
			jmp	ModStart

;*** Kopieren DOS -> CBM.
.m_DOStoCBM		lda	#$00
			b $2c

;*** Kopieren DOS -> GW.
.m_DOStoGW		lda	#$ff
			sta	:1 +1

			lda	#$00
			jsr	CReadMod
::1			ldx	#$00
			jmp	ModStart

;*** Kopieren CBM -> DOS.
.m_CBMtoDOS		lda	#$00
			b $2c

;*** Kopieren GW -> DOS.
.m_GWtoDOS		lda	#$ff
			sta	:1 +1

			lda	#$01
			jsr	CReadMod
::1			ldx	#$00
			jmp	ModStart

;*** Ausgewählte Dateien kopieren.
.m_copyDOStoCBM		ldx	#$00
			b $2c

;*** Ausgewählte Dateien kopieren.
.m_copyDOStoGW		ldx	#$ff
			lda	#mod_100
			jsr	GetModule
			jmp	ModStart

;*** Ausgewählte Dateien kopieren.
.m_copyCBMtoDOS		ldx	#$00
			b $2c

;*** Ausgewählte Dateien kopieren.
.m_copyGWtoDOS		ldx	#$ff
			lda	#mod_101
			jsr	GetModule
			jmp	ModStart

;*** MS-DOS Menü formatieren.
.m_DOS_Format		lda	#$02
			jsr	CReadMod
			jmp	ModStart

;*** MS-DOS Diskette umbenennen.
.m_DOS_Rename		lda	#$02
			jsr	CReadMod
			jmp	ModStart+3

;*** MD-DOS Directory ausgeben.
.m_DOS_Dir		lda	#$03
			jsr	CReadMod
			jmp	ModStart

;*** MS-DOS-Datei umbenennen.
.m_DOS_DelFile		lda	#$00
			b $2c

;*** MS-DOS-Datei löschen.
.m_DOS_RenFile		lda	#$ff

			pha
			lda	#$06
			jsr	CReadMod
			pla
			bne	:1
			jmp	ModStart
::1			jmp	ModStart+3

;*** CBM Diskette formatieren.
.m_CBM_Format		lda	#$04
			jsr	CReadMod
			jmp	ModStart

;*** CBM Diskette umbenennen.
.m_CBM_Rename		lda	#$04
			jsr	CReadMod
			jmp	ModStart+3

;*** CBM-Directory ausgeben.
.m_CBM_Dir		lda	#$05
			jsr	CReadMod
			jmp	ModStart

.m_CBM_Dir1		lda	#mod_41
			jsr	GetModule
			jmp	ModStart

;*** CBM-Datei umbenennen.
.m_CBM_DelFile		lda	#$00
			b $2c

;*** CBM-Datei löschen.
.m_CBM_RenFile		lda	#$ff

			pha
			lda	#$07
			jsr	CReadMod
			pla
			bne	:1
			jmp	ModStart+6
::1			jmp	ModStart+9

;*** CBM Partition wechseln.
.m_SlctPart		jsr	ClearMenus
			ldx	#$00
.m_SlctPart1		lda	#mod_42
			jsr	GetModule
			jmp	ModStart

;*** Angaben über Start-Laufwerk.
.AppDrv			b $00				;Startlaufwerk.
.AppType		b $00				;Typ des Startlaufwerks.
.AppMode		b $00
.AppRLPart		b $00,$00			;Startadresse RAMLink-Boot-Partition.
:AppName		s $18
:AppDiskName		s $11

;*** Variablen für geoDOS-Module.
:ModAnz			= 14
:AppIndex		s ModAnz*2
:AktMod			b $00
:AppCode		b "geoDOS",NULL
.ModBuf			s $08				;Zwischenspeicher bei Modulwechsel.

:ModTabData		b %10000001,$ff,$00,mod_21	;m_DOStoCBM
			b %10000001,$00,$ff,mod_22	;m_CBMtoDOS
			b %10000000,$00,$ff,mod_30	;m_DOS_Format/Rename
			b %00000000,$00,$ff,mod_31	;m_DOS_Dir
			b %10000000,$00,$00,mod_40	;m_CBM_Format/Rename
			b %00000000,$00,$00,mod_41	;m_CBM_Dir
			b %10000000,$00,$ff,mod_50	;m_DOS_FileWorks
			b %10000000,$00,$00,mod_50	;m_CBM_FileWorks

;*** Original-DeskTop-Farben
.colCursor		b $00
.colFrame		b $00

;*** Titel-Zeile.
.InfoLine		b PLAINTEXT,REV_ON
			b " A:         B:         C:         D:         "
			b PLAINTEXT,NULL

;*** geoWrite.
.gW_Boot		b $00

;*** Laufwerks-Parameter.
.Source_Drv		b $00
.Target_Drv		b $00
.Action_Drv		b $00
.curDrvType		b $00
.curDrvMode		b $00
.curDriveRAM		b $00
.CBM_Count		b $00
.DOS_Count		b $00
.DriveTypes		s $04
.DriveModes		s $04
.DriveAdress		s $04

;*** Speicher für Directory-Eintrag.
.Dir_Entry		s $20

;*** Speicher für FAT-Typ.
.FAT_Typ		b	$00

;*** Angaben zur Position des DOS-Disketten-Name auf Diskette.
.DskNamSekNr		w	$0000
.DskNamEntry		w	$0000
.VolNExist		b	$00

;*** Speicher für Disketten-Namen.
.dosDiskName		s	11 +1
.cbmDiskName		s	16 +1

;*** Zeiger für "FAT verändert".
.BAM_Modify		b $00

;*** Partitions-Befehle.
.GetPartDat		w $0005
			b "G-P",$00,$0d
.GetCurPart		w $0005
			b "G-P",$ff,$0d
.CurPartDat		w $001f
			s 32
.DoPrgPart		w $0004
			b 67,208,$00,$0d
.DoUsrPart		w $0004
			b 67,208,$00,$0d
.UsrRAMBase		b $00,$00
.CMDPartMode		b $00,$00

;*** Basic-Start-Befehl.
:BasicCommand		b NULL				;Kein Befehl ausführen.

;*** Lade-Fehler.
:V001a0			b $01
			b 56,127
			w 64,255
			b CANCEL    , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V001a1
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V001a2
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V001a1			b PLAINTEXT,BOLDON
			b "Fehler beim Nachladen",NULL
:V001a2			b "der geoDOS-Programme!",NULL

;*** Namen der Übersetzungstabellen.
.CTabCBMtoDOS		s $11
.CTabDOStoCBM		s $11

;*** Name der eingestellten Schriftart.
.UsedGWFont		b "BSW- GEOS System",NULL
.UsedPointSize		b $09

;*** Copy-Optionen.
.LinesPerPage		w $0040				;Anzahl Zeilen/Seite (WORD!).
.LinkFiles		b $00				;DOS-Dateien kombinieren.
.CopyOptions		b $00				;Datum der Quell-Datei übernehmen.
			b $ff				;Vor dem löschen von Dateien fragen.
.OptDOStoCBM		b $81				;CBM-Datei-Typ "SEQ".
			b $00				;"LF" nich ignorieren.
.OptCBMtoDOS		b $00				;DOS-Namen vorschlagen.
			b $00				;"LF" nicht einfügen.
			b $00				;Typ Ziel-Verzeichnis ($FF = SubDir)
			w $0000				;Cluster für Ziel-Verzeichnis.
.OptDOStoGW		b $00				;DOS-Seitenvorschub ignorieren.
			b $00				;geoWrite-Text V2.0
			w $0001				;Nr. der ersten Seite.
			w $02f0				;Länge einer Seite -> Druckertreiber.
.GW_PageData		b ESC_RULER
.OptGW_Rand		w $0000				;Linker Rand.
			w $01df				;Rechter Rand.
.OptGW_Tab		w $01df				;Tabulator #1.
			w $01df				;Tabulator #2.
			w $01df				;Tabulator #3.
			w $01df				;Tabulator #4.
			w $01df				;Tabulator #5.
			w $01df				;Tabulator #6.
			w $01df				;Tabulator #7.
			w $01df				;Tabulator #8.
			w $0000				;Absatz-Tabulator.
.OptGW_Format		b %00010000			;Formatierung.
			s $03				;Reserviert.
.OptGW_Font		b NEWCARDSET
			w $0009				;Font-ID & Punktgröße.
			b $00				;Schriftstil.

.OptGWtoDOS		b $00				;GW-Seitenvorschub ignorieren.

.AnzahlFiles		b $00				;Anzahl Dateien zum kopieren.

;*** Programm initialisieren.
:MainInit		jsr	InitForIO
			MoveB	$d027,colCursor
			MoveB	$d020,colFrame
			lda	#$00			;Maus- und Rahmen-Farbe
			sta	$d027			;definieren.
			sta	$d020
			jsr	DoneWithIO

;*** VLIR-Tabelle erzeugen.
:GetVLIRTab		lda	curDrive		;Start-Laufwerk merken.
			sta	AppDrv
			jsr	SetDevice
			jsr	OpenDisk
			txa
			bne	:1

			ldx	#r0L			;Disketten-Name merken.
			jsr	GetPtrCurDkNm
			LoadW	r1,AppDiskName
			ldx	#r0L
			ldy	#r1L
			lda	#$10
			jsr	CopyFString

			LoadW	r6,AppName		;geoDOS-Datei suchen.
			LoadW	r7L,APPLICATION
			LoadB	r7H,1
			LoadW	r10,AppClass
			jsr	FindFTypes
			txa
			beq	:2
::1			jmp	GDDiskError		;Disk-Fehler.

::2			LoadW	r0,AppName		;geoDOS-Datei öffnen.
			jsr	OpenRecordFile
			txa
			bne	:1

			jsr	i_MoveData		;VLIR-Daten einlesen.
			w	fileHeader+4
			w	AppIndex
			w	ModAnz*2

			jsr	CloseRecordFile

;*** geoDOS initialisieren.
:InitDrive		jsr	UseGDFont
			Display	ST_WR_FORE ! ST_WR_BACK

			SetColRam1000,0,$cc

			Pattern	2
			FillRec	0,199,0,319		;Bildschirm löschen.
			jsr	ClrBackCol		;geoDOS-Standard-Farben.

			Pattern	0			;Kopfzeile.
			FillRec	7,24,8,311
			lda	#%11111111
			jsr	FrameRectangle
			FrameRec  9, 22, 11,308,%11111111
			FrameRec 10, 21, 12,307,%11111111

			PrintXY	128,18,V002c0		;"geoDOS 64".

			Pattern	0			;Fußzeile.
			FillRec	175,192,8,311
			lda	#%11111111
			jsr	FrameRectangle
			FrameRec177,190, 11,308,%11111111
			FrameRec178,189, 12,307,%11111111

			PrintXY	16,186,V002c3		;Versions-Nr. ausgeben.
			PrintStrgVersionCode

			Window	40,151,48,263
			PrintXY	64,46,V002b0

			jsr	i_BitmapUp
			w	icon_Close
			b	6,40
			b	icon_Close_x,icon_Close_y

			PrintXY	64,64,V002c1
			PrintXY	64,73,V002c2

;*** Laufwerke überprüfen.
			lda	#$00
			sta	Source_Drv		;Kopieren: Source
			sta	Target_Drv		;Kopieren: Target
			sta	Action_Drv		;Auswahllaufwerk
			sta	CBM_Count		;Anz. CBM-Drives
			sta	DOS_Count		;Anz. DOS-Drives
			sta	curDrvType		;Laufwerkstyp.
			sta	curDrvMode		;Laufwerksmodus.
			sta	V002a1			;Anz. Laufwerke

			lda	#$00
:L002a0			sta	V002a0			;Laufwerksnummer.
			add	$41			;Test-Hinweis ausgeben.
			sta	V002b1+9
			ldx	V002a0
			lda	V002b2,x
			sta	r1H
			LoadW	r11,64
			PrintStrgV002b1

;*** Nächstes Laufwerk überprüfen.
			ldy	V002a0
			lda	driveType,y		;Laufwerks-Typ ermitteln.
			sta	curDevice
			beq	:0			;Kein Laufwerk...
			tya
			add	$08
			sta	DriveAdress,y
			jsr	SetDevice		;Laufwerk aktivieren.
			txa
			bne	:0			;Fehler...

			ldy	V002a0			;Laufwerkstyp
			lda	driveType,y		;ermitteln.
			bmi	L002a1			;RAM ? Ja, weiter.
			and	#%00011111		;"gateWay"-RAM-Laufwerk testen.
			cmp	#%00010000
			bcs	L002a1
			and	#%00000111
			cmp	#$01
			beq	:1
			cmp	#$02
			beq	:2
			cmp	#$03
			beq	:3
			cmp	#$04
			beq	:4
::0			jmp	No_Drv
::1			jmp	Drv1541
::2			jmp	Drv1571
::3			jmp	Drv1581
::4			jmp	DrvNative

:L002a1			and	#%00000111
			cmp	#$01
			beq	:1
			cmp	#$02
			beq	:2
			cmp	#$03
			beq	:3
			cmp	#$04
			beq	:4
			jmp	No_Drv
::1			jmp	DrvRAM1541
::2			jmp	DrvRAM1571
::3			jmp	DrvRAM1581
::4			jmp	DrvNative

;*** Laufwerke A: bis D: testen..
:L002a2			ldx	V002a0
			lda	DriveTypes ,x
			beq	:1
			lda	curDevice
			sta	DriveAdress,x
::1			inx
			txa
			cmp	#$04
			beq	:2
			jmp	L002a0

::2			lda	AppDrv
			jsr	SetDevice
			jsr	UseSystemFont

;*** Konfiguration testen.
:CheckConfig		lda	DOS_Count
			bne	:1
			LoadW	V002h1,V002i0		;Fehler:
			LoadW	V002h2,V002i1		;"Kein DOS-Drive"
			jmp	ConfigErr
::1			CmpBI	CBM_Count,2
			bcs	ConfigOK
			LoadW	V002h1,V002i2		;Fehler:
			LoadW	V002h2,V002i3		;"Nur 1 Laufwerk"

:ConfigErr		jsr	i_FillRam
			w	27,COLOR_MATRIX + 5*40 + 7
			b	$b1
			Pattern	2
			FillRec	40,159,48,271
			LoadW	r0,V002h0
			RecDlgBoxCSet_Grau

:ConfigOK		ldy	#$ff			;Konfiguration OK.
::1			iny				;Laufwerke "Source" und "Target" auf
			lda	driveType,y		;Startwerte setzen.
			beq	:1
			tya
			add	$08
			sta	Source_Drv
			sta	Action_Drv
::2			iny
			lda	driveType,y
			beq	:2
			tya
			add	$08
			sta	Target_Drv

;*** RAMLink-Startpartition ermitteln.
:GetRLPart		lda	AppDrv			;Start-Laufwerk aktivieren.
			jsr	NewDrive

			lda	curDrvType		;Laufwerks-daten speichern.
			sta	AppType
			lda	curDrvMode
			sta	AppMode
			bmi	:2
::1			jmp	:8

::2			and	#%01000000
			bne	:3
			jmp	:7

::3			ldx	curDrive		;Startadresse RAMLink-Partition
			lda	ramBase-8,x		;einlesen.
			sta	AppRLPart+0
			lda	driveData+3
			sta	AppRLPart+1

			InitSPort			;GEOS-Turbo aus und I/O einschalten.
			ldx	#1			;Startadresse AppRLPart vergleichen).
::4			stx	GetPartDat +5
			CxSend	GetPartDat
			CxReceiveCurPartDat
			CmpW	CurPartDat +22,AppRLPart
			beq	:5
			ldx	GetPartDat +5
			inx
			cpx	#32
			bne	:4

			lda	#$00			;Partition nicht gefunden.
			beq	:6
::5			lda	CurPartDat+4
::6			sta	DoPrgPart +4
			CxSend	DoPrgPart		;Partition in RAMLink setzen.
			jsr	DoneWithIO
			jmp	:8

::7			InitSPort			;GEOS-Turbo aus und I/O einschalten.
			CxSend	GetCurPart
			CxReceiveCurPartDat
			jsr	DoneWithIO
			MoveB	CurPartDat+4,DoPrgPart+4

::8			jmp	m_Info_a		;Titelbild.

;*** Laufwerksdaten schreiben.
;    Akku = Laufwerkstyp.
:SetCBMDrv		inc	CBM_Count		;Anzahl CBM-Laufwerke +1.
			jmp	SetDrvDat
:SetDOSDrv		inc	CBM_Count		;Anzahl CBM-Laufwerke +1.
			inc	DOS_Count		;Anzahl DOS-Laufwerke +1.
:SetDrvDat		tax
			ldy	V002a0
			lda	V002e0,x		;Laufwerks-Typ aus Tabelle holen und
			sta	DriveTypes,y		;in Laufwerkstabelle schreiben.
			lda	V002e1,x		;Laufwerks-Infos aus Tabelle holen und
			sta	DriveModes,y		;in Laufwerkstabelle schreiben.
			txa				;Text in Info-Zeile eintragen.
			asl
			asl
			asl
			sta	r0L
			ClrB	r0H
			AddVW	V002d0,r0
			ldx	V002b3,y
			ldy	#$00
::2			lda	(r0L),y
			sta	InfoLine,x
			inx
			iny
			cpy	#$07
			bne	:2
			lda	#$20
			sta	InfoLine,x

			ldx	V002a0			;Einzel-Test beendet, Laufwerks-Typ
			lda	V002b2,x		;in Info-Box ausgeben.
			sta	r1H
			LoadW	r11,148
			jsr	PutString

			lda	curDevice
			beq	:3
			pha				;Physikalische Geräteadresse
			jsr	InitForBA		;ausgeben.
			pla
			ldx	#$00
			jsr	Word_FAC
			jsr	x_FLPSTR
			jsr	DoneWithBA
			ldy	#$07
			jsr	Do_ZFAC
			lda	#":"
			jsr	SmallPutChar
::3			jmp	L002a2			;Nächstes Laufwerk.

;*** Laufwerks-Typ nicht vorhanden.
:No_Drv			lda	#Drv_None
			jmp	SetDrvDat

;*** Laufwerks-Typ nicht erkannt.
:DrvUnknown		lda	#Drv_Unknown
			jmp	SetDrvDat

;*** Laufwerke definieren.
:Drv1541		lda	#Drv_1541
			jmp	SetCBMDrv

:Drv1571		lda	#Drv_1571
			jmp	SetCBMDrv

:DrvRAM1541		lda	#Drv_R1541
			jmp	SetCBMDrv

:DrvRAM1571		lda	#Drv_R1571
			jmp	SetCBMDrv

;*** Test auf CMD FD/HD-Drives.
:Drv1581		jsr	GetCMDCode		;CMD-ROM-Infos einlesen.
			cpx	#$00
			beq	:1
			jmp	DrvUnknown

::1			LoadW	r0,V002f1 + 2
			LoadW	r1,V002g2
			ldx	#r0L
			ldy	#r1L
			lda	#$06
			jsr	CmpFString
			bne	:3
			LoadW	r0,V002f3 + 2
			LoadW	r1,V002g4
			ldx	#r0L
			ldy	#r1L
			lda	#$04
			jsr	CmpFString
			beq	:2

			lda	#Drv_CMDFD2		;FD2000 -Drive
			b $2c
::2			lda	#Drv_CMDFD4		;FD4000 -Drive
			jmp	SetDOSDrv

::3			LoadW	r0,V002f1 + 2
			LoadW	r1,V002g3
			ldx	#r0L
			ldy	#r1L
			lda	#$06
			jsr	CmpFString
			bne	:4

			lda	#Drv_CMDHD		;HD -Drive
			jmp	SetCBMDrv

::4			lda	#Drv_1581		;1581-Drive
			jmp	SetDOSDrv

;*** Test auf RAM-Drive Typ 1581/RAMLink.
:DrvRAM1581		jsr	InitForIO		;Kernal ein.
			CmpBI	$e0a9,$78		;Jiffy-DOS testen.
			bne	:1
			CmpBI	$e0ab,$7e
			beq	:2
::1			jsr	DoneWithIO		;Kein Jiffy-DOS, keine RL oder RD.
			jmp	:3

::2			lda	#$00			;RAMLink oder RAMDrive vorhanden ?
			sta	$df7e
			sta	$dfc0
			sta	$df81
			lda	$de77
			and	#$1f
			sta	r0L
			sta	$df82
			sta	$df7f
			jsr	DoneWithIO		;Kernal aus.

			lda	r0L
			beq	:3

			jsr	FindRLDrv		;CMD-ROM-Kennung einlesen.
			tax
			bpl	:4			;CMD RL/RAMDrive gefunden.

::3			lda	#Drv_R1581		;RAM 1581-Drive

::4			jmp	SetCBMDrv

;*** CMD-Native-Mode Drive.
:DrvNative		jsr	GetCMDCode		;CMD-ROM-Daten einlesen.
			cpx	#$00
			beq	:1
			jmp	DrvUnknown

::1			LoadW	r0,V002f1 +2		;Test auf CMD RL.
			LoadW	r1,V002g0
			ldx	#r0L
			ldy	#r1L
			lda	#$06
			jsr	CmpFString
			bne	:2
			lda	#Drv_CMDRLnat
			jmp	SetCBMDrv

::2			LoadW	r1,V002g1		;Test auf RAMDrive.
			ldx	#r0L
			ldy	#r1L
			lda	#$06
			jsr	CmpFString
			bne	:3
			lda	#Drv_RAMDrvnat
			jmp	SetCBMDrv

::3			LoadW	r1,V002g2		;Test auf CMD FD.
			ldx	#r0L
			ldy	#r1L
			lda	#$06
			jsr	CmpFString
			bne	:5
			LoadW	r0,V002f3 +2		;Test auf CMD FD2 oder FD4.
			LoadW	r1,V002g4
			ldx	#r0L
			ldy	#r1L
			lda	#$04
			jsr	CmpFString
			beq	:4

			lda	#Drv_CMDFD2nat
			jmp	SetDOSDrv
::4			lda	#Drv_CMDFD4nat
			jmp	SetDOSDrv

::5			LoadW	r1,V002g3		;Test auf CMD HD.
			ldx	#r0L
			ldy	#r1L
			lda	#$06
			jsr	CmpFString
			bne	:6

			lda	#Drv_CMDHDnat
			jmp	SetCBMDrv

::6			jmp	DrvUnknown

;*** CMD-Kennung einlesen.
:GetCMDCode		InitSPort			;GEOS-Turbo aus und I/O einschalten.
			CxSend	V002f0			;"CMD xx" einlesen.
			cpx	#$00
			bne	:1			;Fehler...
			CxReceiveV002f1
			CxSend	V002f2			;"x000" (für FD) einlesen.
			cpx	#$00
			bne	:1
			CxReceiveV002f3
			jsr	DoneWithIO

			ldx	#$00
			b $2c
::1			ldx	#$ff
			rts

;*** Geräteadresse der RAMLink bestimmen.
:FindRLDrv		lda	#$08
::1			sta	curDevice

			ldx	curDrive
			sta	DriveAdress-8,x

			jsr	InitForIO

			ClrB	STATUS

			lda	curDevice
			jsr	$ffb1			;LISTEN schalten.
			lda	#$ef			;Sekundär-Adresse nach
			jsr	$ff93			;LISTEN senden.
			jsr	$ffae			;UNLISTEN auf IEC-Bus.

			jsr	DoneWithIO

			lda	STATUS			;STATUS-Byte testen.
			beq	:3			;$00 = Kein Fehler.

::2			lda	curDevice
			add	1
			cmp	#$20
			bne	:1

			lda	#$ff			;Flag für "FEHLER".
			rts

::3			jsr	GetCMDCode		;CMD-ROM-Kennung einlesen.
			cpx	#$00
			bne	:2

			LoadW	r0,V002f1 + 2		;CMD-ROM-Kennung mit
			LoadW	r1,V002g0		;Text "CMD RL" vergleichen.
			ldx	#r0L
			ldy	#r1L
			lda	#$06
			jsr	CmpFString
			beq	:4			;CMD-RAMLink gefunden.

			LoadW	r0,V002f1 + 2		;CMD-ROM-Kennung mit
			LoadW	r1,V002g1		;Text "CMD RD" vergleichen.
			ldx	#r0L
			ldy	#r1L
			lda	#$06
			jsr	CmpFString
			beq	:5			;RAMDrive gefunden.
			jmp	:2

::4			lda	#Drv_CMDRL		;RAMLink -Laufwerk.
			rts

::5			lda	#Drv_RAMDrv		;RAMDrive-Laufwerk.
			rts

;*** Variablen für :InitDrive.
:V002a0			b $00				;Zähler für Laufwerke
:V002a1			b $00				;Anzahl Laufwerke

:V002b0			b PLAINTEXT,REV_ON
			b "Initialisierung..."
			b PLAINTEXT,NULL
:V002b1			b "Laufwerk A: Test...",NULL
:V002b2			b 96,107,118,129		;Ausgabezeilen.
:V002b3			b $05,$10,$1b,$26		;Zeiger für INFO-Zeile.

:V002c0			b PLAINTEXT
			b "geoDOS 64",NULL
:V002c1			b "Hardware wird getestet,",NULL
:V002c2			b "bitte etwas Geduld...",NULL

:V002c3			b "Voll-Version: ",NULL

:V002d0			b "(kein) ",NULL
:V002d1			b "1541   ",NULL
:V002d2			b "1571   ",NULL
:V002d3			b "1581   ",NULL
:V002d4			b "RAM1541",NULL
:V002d5			b "RAM1571",NULL
:V002d6			b "RAM1581",NULL
:V002d7			b "CMD RL ",NULL
:V002d8			b "RAMDrv ",NULL
:V002d9			b "CMD FD2",NULL
:V002d10		b "CMD FD4",NULL
:V002d11		b "CMD HD ",NULL
:V002d12		b "CMD+RL ",NULL
:V002d13		b "RAMDrv+",NULL
:V002d14		b "CMD+FD2",NULL
:V002d15		b "CMD+FD4",NULL
:V002d16		b "CMD+HD ",NULL
:V002d17		b "Typ ???",NULL

:V002e0			b Drv_None			;Kein Laufwerk.
			b Drv_1541			;Commodore 1541 (I,C,II).
			b Drv_1571			;Commodore 1571.
			b Drv_1581			;Commodore 1581.
			b Drv_R1541			;RAM-Drive 170 Kbyte = 1541.
			b Drv_R1571			;RAM-Drive 340 Kbyte = 1571.
			b Drv_R1581			;RAM-Drive 790 Kbyte = 1581.
			b Drv_CMDRL			;CMD RAMLink.
			b Drv_RAMDrv			;RAMDrive.
			b Drv_CMDFD2			;CMD FD2000.
			b Drv_CMDFD4			;CMD FD4000.
			b Drv_CMDHD			;CMD HD.
			b Drv_CMDRL			;Native-Mode CMD RAMLink.
			b Drv_RAMDrv			;Native-Mode RAMDrive.
			b Drv_CMDFD2			;Native-Mode CMD FD2000.
			b Drv_CMDFD4			;Native-Mode CMD FD4000.
			b Drv_CMDHD			;Native-Mode CMD HD.
			b Drv_None			;Unbekanntes Laufwerk.

:V002e1			b %00000000			;Kein Laufwerk
			b %00000000			;1541
			b %00000000			;1571
			b %00010000			;1581
			b %00001000			;RAM 1541
			b %00001000			;RAM 1571
			b %00001000			;RAM 1581
			b %11001000			;CMD RL
			b %11001000			;RAMDrive
			b %10010000			;CMD FD2
			b %10010000			;CMD FD4
			b %10000000			;CMD HD
			b %10101000			;CMD RL   Native
			b %10101000			;RAMDrive Native
			b %10110000			;CMD FD2  Native
			b %10110000			;CMD FD4  Native
			b %10100000			;CMD HD   Native
			b %00000000			;Unbekanntes Laufwerk

:V002f0			w $0006
			b "M-R",$a0,$fe,$06
:V002f1			w $0006
			s $06
:V002f2			w $0006
			b "M-R",$f0,$fe,$08
:V002f3			w $0008
			s $08

:V002g0			b "CMD RL"
:V002g1			b "CMD RD"
:V002g2			b "CMD FD"
:V002g3			b "CMD HD"
:V002g4			b "4000"

;*** Fehler: "Kein DOS-Laufwerk!"
:V002h0			b $01
			b 56,127
			w 64,255
			b OK       , 16, 48
			b DBTXTSTR ,DBoxLeft,DBoxBase1
:V002h1			w V002i0
			b DBTXTSTR ,DBoxLeft,DBoxBase2
:V002h2			w V002i1
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V002i0			b PLAINTEXT,BOLDON
			b "Kein Laufwerk Typ",NULL
:V002i1			b "CBM 1581 / CMD FD !"
			b PLAINTEXT,NULL

:V002i2			b PLAINTEXT,BOLDON
			b "Fehler! Nur ein",NULL
:V002i3			b "Laufwerk vorhanden !"
			b PLAINTEXT,NULL

;*** Einsprungadressen der Tabellen.
:Memory			= MainInit
.Disk_Sek		=(Memory / $0100 +1) * $0100
.Boot_Sektor		= Disk_Sek    + $0200
.FAT			= Boot_Sektor + $0200
.ModCodeAdr		= FAT         + $1200
.ModStart		= ModCodeAdr  + $0007

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

;*** Routinen im Basic-Interpreter.
.MOVMA			= $ba8c				;ARG: mit Konstante aus Speicher laden.
.x_MULT			= $ba30				;FAC: = FAC * ARG
.MOVFA			= $bc0c				;ARG: = FAC
.ADDFAC			= $b86a				;FAC: = FAC + ARG
.MOVMF			= $bba2				;FAC: mit Konstante aus Speicher laden.
.x_DIVAF		= $bb14				;FAC: = ARG/FAC
.MOVFM			= $bbd4				;FAC: in Speicher verschieben.
.FACWRD			= $b7f7				;FAC: in 2-Byte-Integer wandeln.
.SUBFAC			= $b853				;FAC: = ARG - FAC
.x_FLPSTR		= $bddd				;FAC: Als String ab $0100 ablegen.
.BINFAC			= $bc49				;FAC: = Integer in $63 (low) / $62 (high).
.BYTFAC			= $b3a2				;FAC: = Integer in Y-Reg.
