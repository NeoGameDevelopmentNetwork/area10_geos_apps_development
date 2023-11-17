; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t	"TopSym"
			t	"Sym128.erg"
			t	"TopMac"
			t	"GD_Mac"
			t	"src.GeoDOS.ext"
			t	"src.DOSDRIVE.ext"

:MaxFiles		= 96				;Max. Anzahl Dateien im Speicher.

endif

			n	"mod.#302.obj"
			o	ModStart
			q	EndProgrammCode
			r	EndAreaDOS - (MaxFiles * 32)

			jmp	DOS_Dir
			jmp	DOS_InitDir

			t	"-FontType2"

;*** L302: Verzeichnis ausgeben.
:DOS_Dir		ldx	#$00
			lda	curDrive		;Warten bis Diskette eingelegt.
			jsr	InsertDisk
			cmp	#$01
			beq	FirstInitDir
			jmp	L302ExitGD

;*** Einsprung aus "Verzeichnis drucken".
:DOS_ExitPrn		jsr	CheckDiskDOS
			txa				;Fehler ?
			bne	DOS_Dir			;Nein, weiter...

;*** Verzeichnis drucken.
:PrintDir		lda	DirType
			sta	ModBuf+0
			jsr	i_MoveData
			w	Dir_Entry,Disk_Sek,32
			jmp	vD_PrnCurDir

;*** Rückkehr aus "Verzeichnis drucken".
:DOS_InitDir		lda	ModBuf+0
			sta	DirType
			jsr	i_MoveData
			w	Disk_Sek,Dir_Entry,32
			jmp	Start_Dir

:FirstInitDir		jsr	DOS_GetSys		;DOS-System einlesen.
			jsr	DOS_GetDskNam		;Diskettenname einlesen und
			jsr	ClrBox			;Dialogbox abbauen.

;*** Ausgabe der ersten Dircetory-Seite.
			lda	#$00
			sta	DirType			;Hauptverzeichnis.
			sta	DisplayMode		;Dateien anzeigen.
			sta	V302b2			;Name,Größe,Datum & Uhrzeit anzeigen.

:Start_Dir		jsr	Do1stInit		;Zeiger auf Anfang akt. Verzeichnis.
			jsr	Read112Dir		;Dateien einlesen.
			jmp	Bildschirm_a		;Bildschirm initialisieren.

;*** Directory-Icons aktivieren.
:StartDirMenu		LoadW	r0,HelpFileName
			lda	#<Start_Dir
			ldx	#>Start_Dir
			jsr	InstallHelp

			StartMouse			;Warten bis keine Maustaste gedrückt.
			jsr	WaitMouse

:SetMIconCol		jsr	i_C_MenuMIcon
			b	$00,$01,$00,$03

			LoadW	otherPressVec,SlctFile
			LoadW	r0,Icon_Tab1
			jmp	DoIcons

;*** Zurück zu GeoDOS.
:L302ExitGD		jsr	ClrPressVec
			jmp	InitScreen

;*** Anderes Laufwerk wählen.
:SelectDrvA		ldx	#$00
			b $2c
:SelectDrvB		ldx	#$01
			b $2c
:SelectDrvC		ldx	#$02
			b $2c
:SelectDrvD		ldx	#$03
			lda	DrvOnScrn,x
			bne	:101
			rts

::101			sta	Target_Drv
			jsr	NewDrive
			jsr	ClrScreen
			jmp	DOS_Dir

;*** Bildschirm initialisieren.
:Bildschirm_a		jsr	ClrScreen		;Fenster aufbauen.

			jsr	i_C_MenuTitel
			b	$00,$00,$28,$01
			jsr	i_C_MenuBack
			b	$00,$01,$28,$18

			jsr	UseGDFont
			Print	$0008,$06
if Sprache = Deutsch
			b	PLAINTEXT,"PCDOS  -  Inhaltsverzeichnis"
endif
if Sprache = Englisch
			b	PLAINTEXT,"PCDOS  -  Directory"
endif
			b	ESC_GRAPHICS
			b	MOVEPENTO
			w	$0000
			b	$2f
			b	LINETO
			w	$013f
			b	$2f
			b	MOVEPENTO
			w	$0000
			b	$c0
			b	LINETO
			w	$013f
			b	$c0
			b	NULL

:Bildschirm_b		FillPRec$00,$27,$2e,$00a8,$012f

			jsr	UseGDFont		;Disketten-Namen ausgeben.

			lda	DirType			;Verzeichnis-Typ testen.
			bne	:101			;Unterverzeichnis ? Nein, weiter...
			Print	$90,$2c
			b	PLAINTEXT,"Disk: ",NULL
			PrintStrgdosDiskName
			jmp	:105

::101			Print	$90,$2c
			b	PLAINTEXT,"SubD: ",NULL

			ldy	#$00
::102			sty	:103 +1
			lda	Dir_Entry,y		;Byte aus Verzeichnis-Eintrag lesen.
			jsr	ConvertChar 		;Zeichen prüfen und
			jsr	SmallPutChar		;ausgeben.
::103			ldy	#$ff
			cpy	#$07
			bne	:104

			jsr	PrintPunkt

::104			ldy	:103 +1
			iny
			cpy	#$0b
			bne	:102

::105			jsr	GetCluInfo

			jsr	UseMiniFont
			FillPRec$00,$c1,$c7,$0001,$013e

			LoadW	r11,8
			LoadB	r1H,198
			ClrB	currentMode
			MoveW	CountFreeClu,r2
			jsr	CalcBytes
			jsr	ZahlToASCII
			PrintStrgASCII_Zahl
			PrintStrgV302c1

			AddVBW	16,r11
			MoveB	V302a0,r0L
			ClrB	r0H
			lda	#%11000000
			jsr	PutDecimal
			PrintStrgV302c2

			lda	V302a0			;Rollbalken initialisieren.
			sta	V302f0+3
			LoadW	r0,V302f0
			jsr	InitBalken
			jsr	Show16Files		;16 Dateien anzeigen.
			jsr	PrintDrives
			jsr	InitDirMenu		;Menuleiste initialisieren.

			jmp	StartDirMenu		;Hauptmenü aktivieren.

;*** Icon-Leiste initialisieren.
:InitDirMenu		lda	C_MenuBack		;Iconfenster löschen.
			pha
			and	#%00001111
			sta	r0L
			pla
			asl
			asl
			asl
			asl
			ora	r0L
			sta	:101 +4

			jsr	i_ColorBox
::101			b	$00,$01,$28,$05,$ff

			FillPRec$00,$08,$1f,$0000,$013f

			jsr	i_C_MenuBack
			b	$00,$01,$28,$05

			jsr	i_BitmapUp		;Anzeige-Icon.
			w	Icon_08
			b	$26,$28,$02,$08
			jsr	i_C_Balken
			b	$26,$05,$02,$01

;*** Icon-Tabelle definieren.
			LoadB	Icon_Tab1,3
			LoadB	r14H,$0f
			LoadW	r15 ,Icon_Tab1c

			lda	V302a0			;Anzeigemodus definieren.
			beq	:102
			ldx	#$00
			jsr	Copy1Icon

::102			bit	DirType
			bpl	:104
			ldx	#$08			;"ROOT-Dir"
			jsr	Copy1Icon
			ldx	#$10			;"SubDir"
			jsr	Copy1Icon

;*** "MaxFiles-Datei"-Icons.
::104			lda	V302b1
			beq	:107

::105			lda	#<Icon_01
			ldx	#>Icon_01
			bit	V302b0
			bpl	:106

			lda	#<Icon_01a
			ldx	#>Icon_01a
::106			sta	Icon_Tab1e+0
			stx	Icon_Tab1e+1

			ldx	#$18
			jsr	Copy1Icon

;*** Farbe für Standard-Icons.
::107			lda	r14H
			sta	SetMIconCol +5
			rts

;*** Icon in Icon-Zeile übernehmen.
:Copy1Icon		ldy	#$00
::101			lda	Icon_Tab1d,x
			sta	(r15L),y
			inx
			iny
			cpy	#$08
			bne	:101

			ldy	#$02
			lda	r14H
			sta	(r15L),y

			AddVB	5,r14H
			AddVBW	8,r15
			inc	Icon_Tab1
			rts

;*** 32 Byte addieren.
:Add32Byte		clc
			lda	$00,x
			adc	#32
			sta	$00,x
			bcc	:101
			inc	$01,x
::101			rts

;*** Laufwerksbezeichnungen ausgeben.
:PrintDrives		jsr	UseMiniFont

			LoadB	:102,$02

			lda	#$09
			sta	r14L
			lda	#$00
			sta	r14H
			sta	r15L
			sta	DrvOnScrn+0
			sta	DrvOnScrn+1
			sta	DrvOnScrn+2
			sta	DrvOnScrn+3

::101			pha
			MoveW	r14,r11
			LoadB	r1H,$2d
			pla
			pha
			tay
			lda	DriveModes,y
			and	#%00010000
			beq	:103

			pla
			pha
			add	"A"
			jsr	SmallPutChar

			pla
			pha
			add	8
			ldx	r15L
			sta	DrvOnScrn,x
			inc	r15L

			pla
			pha
			add	8
			cmp	curDrive
			bne	:101a

			AddVBW	20,r11
			LoadB	currentMode,SET_BOLD
			lda	#"!"
			jsr	SmallPutChar
			ClrB	currentMode

::101a			jsr	i_BitmapUp
			w	Icon_10
::102			b	$00,$27,$02,$08

			AddVB	4,:102

			ldx	#r14L
			jsr	Add32Byte

::103			pla
			add	1
			cmp	#$04
			beq	:104
			jmp	:101

::104			rts

;*** Directory-Fenster löschen und
;    ":otherPressVec" löschen.
:ClrPressVec		ClrW	otherPressVec
			jmp	ClrScreen

;*** Neue Seite vorbereiten.
:ClrWinBox		jsr	i_C_MenuTBox
			b	$00,$06,$27,$12
			FillPRec$00,$30,$bf,$0000,$0137
			jmp	UseGDFont

;*** Cursor positionieren und Zahlenwert ausgeben..
:PutInfoEntry		LoadW	r11,176			;Cursor-Position für Doppelpunkt.
			lda	#":"			;Doppelpunkt setzen.
			jsr	SmallPutChar
			ClrB	currentMode		;Schriftstile löschen.
			LoadW	r11,192			;Cursor-Position für Directory-Daten.
			jmp	UseGDFont		;GeoDOS-Font aktivieren.

;*** Zahlenwert ausgeben.
:PutEntry2		ldy	#$07			;24Bit-Zahl ausgeben.
			jmp	DoZahl24Bit

;*** HEX-Zahl nach ASCII wandeln.
:HexASCII_a		jsr	PrepNum100		;100er-Zahlen konvertieren.
			pha
			lda	#"0"			;Zehner-Stelle auf "0" setzen.
			sta	Memory1+0,x
			pla
::101			cmp	#10			;Zahl < 10 ?
			bcc	:102			;Ja, Ende...
			inc	Memory1+0,x		;Nein, Zehner-Stelle erhöhen.
			sub	10			;Zahl = Zahl -10.
			bne	:101			;Zahl = 0 ? Nein, weiter...
::102			add	$30			;ASCII-Zahl erzeugen und
			sta	Memory1+1,x		;Einer-Stelle setzen.
			inx
			inx
			rts

;*** Zeichen einfügen.
:Ins2Space		jsr	InsertSpace		;Leerzeichen einfügen.
:InsertSpace		lda	#" "			;Leerzeichen einfügen.
:InsertASCII		sta	Memory1,x		;ASCII-Zeichen einfügen.
			inx
			rts

;*** "." ausgeben.
:PrintPunkt		lda	#"."
			jmp	SmallPutChar

;*** Zeiger auf Directory-Anfang.
:GoTopDir		jsr	SaveDir			;Verzeichnisposition merken.

;*** Zeiger auf Directory-Anfang.
:Do1stInit		lda	#$00
			sta	V302a0			;Anzahl Dateien löschen.
			sta	V302a1			;Zeiger auf Position #1.
			sta	V302a6			;Zeiger auf ersten Sektor im Cluster.
			sta	V302a7			;Zeiger auf ersten Eintrag.
			sta	V302b0			;Weiteren Dateien im Verzeichnis.
			sta	V302b1			;Kein Speicherüberlauf.

			lda	#<Disk_Sek		;Zeiger auf DOS-Sektorspeicher.
			sta	V302a8 +0
			lda	#>Disk_Sek
			sta	V302a8 +1

			bit	DirType			;Unterverzeichnis ?
			bmi	:101			;Ja, Sonderbehandlung.

			jsr	GetMdrSek		;Anzahl Sektoren im Hauptverzeichnis.
			lda	MdrSektor+0
			sta	V302a5   +0
			lda	MdrSektor+1
			sta	V302a5   +1

			jsr	DefMdr			;Zeiger auf Anfang Hauptverzeichnis.
			jmp	:102

;*** Zeiger auf Unterverzeichnis.
::101			lda	Dir_Entry+26		;Cluster-Nummer lesen.
			ldx	Dir_Entry+27
			sta	V302a3+0		;Als ersten Cluster speichern.
			stx	V302a3+1
			sta	V302a4+0		;Als aktuellen Cluster speichern.
			stx	V302a4+1
			jsr	Clu_Sek			;Cluster umrechnen.

::102			jmp	SaveSekInfo

;*** Aktuellen Sektor merken.
:SaveSekInfo		MoveB	Seite ,V302a2+0
			MoveB	Spur  ,V302a2+1
			MoveB	Sektor,V302a2+2
			rts

;*** Verzeichnisposition speichern.
:SaveDir		jsr	i_MoveData
			w	V302a0
			w	DskDatMem
			w	20
			rts

;*** Verzeichnisposition zurücksetzen.
:ResetDir		jsr	i_MoveData
			w	DskDatMem
			w	V302a0
			w	20
			rts

;*** Die ersten Dateien einlesen.
:File1st112		bit	V302b1			;Speicherüberlauf ?
			bpl	FileNext_b		;Ja, Icon auswerten.
			jsr	Do1stInit		;Zeiger auf ersten Verzeichnis-Sektor.
			jmp	FileNext_a		;Dateien einlesen & ausgeben.

;*** Die nächsten Dateien einlesen.
:FileNxt112		bit	V302b1			;Speicherüberlauf ?
			bpl	FileNext_b		;Ja, Icon auswerten.
			bit	V302b0			;Verzeichnis-Ende erreicht ?
			bmi	File1st112		;Ja, Ende...
:FileNext_a		jsr	InvertRectangle
			jsr	Read112Dir		;Dateien einlesen.
			jmp	Bildschirm_b		;Bildschirm aufbauen.
:FileNext_b		rts

;*** Dateien einlesen.
:Read112Dir		jsr	DoInfoBox		;Info ausgeben.
			PrintStrgDB_RdFile

			jsr	i_FillRam		;Speicher löschen.
			w	32*MaxFiles
			w	Memory2
			b	$00

			lda	#$00			;Zähler für Anzahl Einträge und
			sta	V302a0			;Zähler für aktuellen Eintrag löschen.
			sta	V302a1

			LoadW	a7,Memory2		;Zeiger auf Anfang des Speichers.

::101			jsr	RdCurDirSek		;Aktuelen Verzeichnis-Sektor lesen.
::102			jsr	GetNxtEntry		;Folgt weiterer Eintrag ?
			beq	:103			;Ja, einlesen.
			LoadB	V302b0,$ff		;Directory-Ende kennzeichnen.
			rts

::103			ldy	#$1f
::104			lda	(r10L),y		;Eintrag kopieren.
			sta	(a7L),y
			dey
			bpl	:104

			ldx	#a7L
			jsr	Add32Byte
			inc	V302a0			;Eintrag richten.

			lda	V302a0
			cmp	#MaxFiles		;Speicher voll ?
			bcc	:102			;Nein, weiter...

			MoveW	a8,V302a8

			jsr	SaveDir			;Verzeichnisposition merken.
			jsr	GetNxtEntry		;Folgt weiterer Eintrag ?
			pha
			jsr	ResetDir		;Verzeichnisposition zurücksetzen.
			pla
			eor	#%11111111		;Ergebnis als Flag für weitere Dateien.
			sta	V302b1			;($FF = weitere Dateien!)
			rts				;Info löschen.

;*** Nächsten Eintrag suchen.
:GetNxtEntry		MoveW	a8,r10
			MoveB	V302a7,r11L

			lda	V302a7			;Alle Einträge des aktuellen
			cmp	#16			;Sektors gelesen ?
			bcc	:101			;Nein, weiter...

			jsr	RdNxDirSek		;Nächsten Directory-Sektor lesen.
			bcc	GetNxtEntry		;Weiteren Sektor gefunden ? Ja, weiter.
			bcs	:102			;Verzeichnisende.

::101			ldy	#$00			;Byte aus Eintrag lesen.
			lda	(a8L),y			;Byte = $00 ?
			beq	:102			;Nein, weiter.

			jsr	TestDirEntry		;Gültiger Verzeichniseintrag ?

			pha				;Ergebnis merken.
			ldx	#a8L
			jsr	Add32Byte
			inc	V302a7
			pla				;Datei gültig ?
			bne	GetNxtEntry		;Nein, weiter...

			ldx	#$00			;Ja, Ende...
			b $2c
::102			ldx	#$ff
			txa
			rts

;*** Eintrag überprüfen.
:TestDirEntry		cmp	#$e5			;Datei gelöscht ?
			beq	:102			;Ja, übergehen.

			ldy	#$0b
			lda	(a8L),y
			tax
			and	#%00001000		;Volume-Name ?
			bne	:102			;Ja, ignorieren.

			txa
			and	#%00010000		;Unterverzeichnis ?
			bne	:101			;Ja, weiter...

			ldy	#$1a			;Cluster = 0 ?
			lda	(a8L),y
			bne	:101			;Nein, weiter...
			iny
			lda	(a8L),y
			beq	:102			;Ja, ignorieren.

::101			lda	#$00			;Datei OK!
			rts
::102			lda	#$ff			;Datei ungültig!
			rts

;*** Aktuellen Directory-Sektor lesen.
:RdCurDirSek		MoveB	V302a2+0,Seite		;Zeiger auf Sektor richten.
			MoveB	V302a2+1,Spur
			MoveB	V302a2+2,Sektor
			LoadW	a8,Disk_Sek		;Zeiger auf Anfang Zwischenspeicher.
			jsr	D_Read			;Sektor lesen.
			txa
			beq	:101
			jmp	DiskError		;Disketten-Fehler.

::101			MoveW	V302a8,a8		;Zeiger auf aktuellen Eintrag.
			rts

;*** Nächsten Verzeichnis-Sektor lesen.
:RdNxDirSek		bit	DirType			;Hauptverzeichnis ?
			bmi	:102			;Nein, weiter...

			SubVW	1,V302a5		;Zähler Verzeichnis-Sektoren -1.
			CmpW0	V302a5			;Ende erreicht ?
			bne	:101			;Nein, weiter...
			sec				;Directory-Ende erreicht.
			rts

::101			jsr	Inc_Sek			;Zeiger auf nächsten Sektor.
			jmp	:104			;Nächsten Sektor lesen.

;*** Nächsten Sektor eines SubDirs einlesen.
::102			inc	V302a6			;Zeiger auf nächsten Sektor innerhalb
			CmpB	V302a6,SpClu		;des aktuellen Clusters.
			bne	:101			;Nächsten Sektor des Clusters lesen.

			ClrB	V302a6

			lda	V302a4+0		;Aktuelle Cluster-Nr. lesen.
			ldx	V302a4+1
			jsr	Get_Clu			;Zeiger auf nächsten Cluster.
			lda	r1L			;Nr. des neuen Clusters einlesen.
			ldx	r1H
			cmp	#$f7			;12-Bit-FAT.
			bcc	:103
			cpx	#$0f
			bcc	:103
			sec
			rts

::103			sta	V302a4+0
			stx	V302a4+1
			jsr	Clu_Sek			;Cluster umrechnen.

::104			jsr	SaveSekInfo

			lda	#<Disk_Sek		;Zeiger auf Zwischenspeicher richten.
			sta	a8L
			sta	V302a8+0
			lda	#>Disk_Sek
			sta	a8H
			sta	V302a8+1

			jsr	D_Read			;Sektor lesen.
			txa
			beq	:105
			jmp	DiskError		;Diskettenfehler.

::105			stx	V302a7			;Zeiger auf ersten Eintrag.
			clc
			rts

;*** Dateien anzeigen, Icon-Tabelle definieren.
:View16Files		jsr	Show16Files
			jmp	StartDirMenu

;*** 16 Dateien anzeigen.
:Show16Files		LoadB	DisplayMode,$00
			LoadW	Icon_Tab1a,Icon_03
			LoadW	Icon_Tab1b,DiskInfo

			jsr	ClrWinBox		;Fenster löschen.

			lda	V302a0			;Keine Dateien im Speicher ?
			beq	:103			;Text ausgeben.

			MoveB	V302a1,a8L		;Zeiger auf Eintrag berechnen.
			ClrB	a8H
			ldx	#a8L
			ldy	#$05
			jsr	DShiftLeft
			AddVW	Memory2,a8

			lda	#$00
			sta	currentMode		;Darstellungsmodus.
			sta	V302a9			;Zähler für Einträge/Anzeige löschen.
			LoadB	V302a10,54		;Y-Pos. für Ausgabe Directory-Eintrag.

::101			CmpB	V302a0,V302a9		;Ende erreicht ?
			beq	:102			;Ja, Ende...
			jsr	DoFile			;Eintrag ausgeben.

			AddVBW	8,V302a10		;Y-Pos für Ausgabezeile korrigieren.

			inc	V302a9			;Zähler für Anzahl Einträge
			lda	V302a9			;erhöhen.
			cmp	#18			;Seite voll ?
			beq	:104			;Ja, Abbruch.

			ldx	#a8L
			jsr	Add32Byte
			jmp	:101			;Nächsten Eintrag ausgeben.

::102			lda	V302a9			;Anzahl ausgegebener Dateien = 0 ?
			bne	:104			;Nein, weiter...

::103			PrintStrgV302c0			;Info: "Keine Dateien..."
::104			lda	V302a1			;Scrollbalken neu berechnen.
			jmp	SetPosBalken

;*** Zahl auf Wert < 100 testen.
:PrepNum100		cmp	#100
			bcc	:101
			sbc	#100
			jmp	PrepNum100
::101			rts

;*** Speicher mit Leerzeichen auffüllen.
:FillUpMem		cpx	#40			;Rest der Zeile mit Leerzeichen
			bcs	:101			;auffüllen.
			jsr	InsertSpace
			bne	FillUpMem

::101			lda	#$00			;Zeilenende kennzeichnen.
			sta	Memory1,x

			LoadW	r11,8			;X-Koordinate.
			MoveB	V302a10,r1H		;Y-Koordinate.
			PrintStrgMemory1			;Verzeichniszeile ausgeben.
			rts

;*** Text für Attribut in Druckzeile kopieren.
:CopyAttr		sta	r0L
			sty	r0H
			jsr	CopyTextStrg
			lda	#","
			jmp	InsertASCII

;*** Textstring in Speicher kopieren.
:CopyTextStrg		ldy	#$00
::101			lda	(r0L),y
			beq	:102
			jsr	InsertASCII
			iny
			bne	:101
::102			rts

;*** Dateigröße in Speicher übertragen.
:CopyFileSize		ldy	#$00			;Dateigröße auf 9 Zeichen mit
::101			lda	(r0L),y			;Leerzeichen auffüllen.
			beq	:102
			iny
			bne	:101
::102			cpy	#$09
			beq	:103
			jsr	InsertSpace
			iny
			bne	:102

::103			ldy	#$00			;Dateigröße in Zwischenspeicher
::104			lda	(r0L),y			;übertragen.
			beq	:105
			jsr	InsertASCII
			iny
			bne	:104
::105			rts

;*** Datei-Eintrag ausgeben.
:DoFile			jsr	UseGDFont
			ldx	#$00
			stx	currentMode		;Darstellungsmodus.

			jsr	InsertName		;Name in Zwischenspeicher übertragen.
			jsr	InsertSpace		;Leerzeichen einfügen.

			lda	V302b2			;Anzeigemodus ?
			beq	DirFile_1		;Name, Größe, Datum & Uhrzeit.
			jmp	DirFile_2		;Name, Attribute.

;*** Ausgabe Größe, Datum & Uhrzeit.
:DirFile_1		jsr	InsertSpace		;Leerzeichen einfügen.
			jsr	Ins2Space		;Zwei Leerzeichen einfügen.

			stx	:104 +1
			ldy	#$0b
			lda	(a8L),y
			and	#%00010000		;Datei = Unterverzeichnis ?
			beq	:102			;Kein SubDir, weiter...

::101			LoadW	r0,V302d1		;Text "<SubDir>" übertragen.
			jmp	:104

::102			ldy	#$1c			;Dateigröße nach r0L bis r1L.
			ldx	#$00
::103			lda	(a8L),y
			sta	r0L,x
			iny
			inx
			cpx	#$03
			bne	:103
			jsr	ZahlToASCII		;Zahl nach ASCII wandeln.
			LoadW	r0,ASCII_Zahl		;ASCII-Zahl übertragen.

::104			ldx	#$ff
			jsr	CopyFileSize

			jsr	Ins2Space		;Zwei Leerzeichen einfügen.

			jsr	InsertDate		;Datum übertragen.
			jmp	FillUpMem		;Eintrag ausgeben.

;*** Dateiname erzeugen.
:InsertName		ldy	#$00
::101			lda	(a8L),y			;Zeichen aus Dateiname einlesen.
			jsr	ConvertChar 		;Zeichen prüfen und
			jsr	InsertASCII		;in Speicher übertragen.
			cpy	#$07
			bne	:102
			jsr	InsertSpace		;Leerzeichen "EXT" einfügen.
::102			iny
			cpy	#$0b
			bne	:101
			rts

;*** Datum & Zeit ausgeben.
:InsertDate		jsr	GetBinDate		;Datum DOS->C64.

			lda	V302k1+0		;Ausgabe: Tag.
			jsr	HexASCII_a
			lda	#"."
			jsr	InsertASCII

			lda	V302k1+1		;Ausgabe: Monat.
			jsr	HexASCII_a
			lda	#"."
			jsr	InsertASCII

			lda	V302k1+2		;Ausgabe: Jahr.
			jsr	HexASCII_a

			jsr	Ins2Space

			lda	V302k1+3		;Ausgabe: Stunde.
			jsr	HexASCII_a
			lda	#":"
			jsr	InsertASCII

			lda	V302k1+4		;Ausgabe: Minute.
			jmp	HexASCII_a

;*** Attribute ausgeben.
:DirFile_2		ldy	#$0b			;"Read-Only"-Status prüfen.
			lda	(a8L),y
			pha
			and	#%00000001
			beq	:101

			lda	#<V302d3
			ldy	#>V302d3
			jsr	CopyAttr

::101			pla				;"Hidden-Datei"-Status prüfen.
			pha
			and	#%00000010
			beq	:102

			lda	#<V302d4
			ldy	#>V302d4
			jsr	CopyAttr

::102			pla				;"System-Datei"-Status prüfen.
			pha
			and	#%00000100
			beq	:103

			lda	#<V302d5
			ldy	#>V302d5
			jsr	CopyAttr

::103			pla				;"Archiv"-Status prüfen.
			and	#%00100000
			beq	:104

			lda	#<V302d6
			ldy	#>V302d6
			jsr	CopyAttr

::104			dex
			jmp	FillUpMem

;*** Datum berechnen.
:GetBinDate		pha
			txa
			pha
			tya
			pha

			ldy	#$18			;Tag berechnen.
			lda	(a8L),y
			sta	r15L
			iny
			lda	(a8L),y
			sta	r15H
			lda	r15L
			and	#%00011111
			sta	V302k1+0

			RORZWordr15L,5

			lda	r15L			;Monat berechnen.
			and	#%00001111
			sta	V302k1+1

			RORZWordr15L,4

			lda	r15L			;Jahr berechnen.
			and	#%01111111
			clc
			adc	#80
			sta	V302k1+2

			ldy	#$16			;Uhrzeit berechnen.
			lda	(a8L),y
			sta	r15L
			iny
			lda	(a8L),y
			sta	r15H

			RORZWordr15L,5

			lda	r15L			;Minute berechnen.
			and	#%00111111
			sta	V302k1+4

			RORZWordr15L,6

			lda	r15L			;Stunde berechnen.
			and	#%00011111
			sta	V302k1+3

			pla
			tay
			pla
			tax
			pla
			rts

;*** Diskettenkapazitäten ausgeben.
:DiskInfo		LoadB	DisplayMode,$ff
			LoadW	Icon_Tab1a,Icon_04
			LoadW	Icon_Tab1b,View16Files

			jsr	DOS_GetSys		;Diskettenverzeichnis einlesen.
			jsr	GetDirInfo

			jsr	ClrWinBox		;Fensterhintergrund löschen.

			jsr	UseSystemFont		;Anzahl Dateien ausgeben.
			PrintXY	20,64,V302e0
			jsr	PutInfoEntry
			MoveB	DirFiles+0,r0L
			MoveB	DirFiles+1,r0H
			ClrB	r1L
			ldy	#$07
			jsr	DoZahl24Bit

			jsr	UseSystemFont		;Anzahl Bytes im Directory ausgeben.
			PrintXY	20,76,V302e1
			jsr	PutInfoEntry
			MoveB	UsedByte+0,r0L
			MoveB	UsedByte+1,r0H
			MoveB	UsedByte+2,r1L
			jsr	PrnTxtByte

			jsr	UseSystemFont		;Anzahl belegter Cluster ausgeben.
			PrintXY	20,88,V302e2
			jsr	PutInfoEntry

			sec				;Anzahl freie Cluster berechnen.
			lda	FreeClu    +0
			sbc	CountFreeClu+0
			sta	r2L
			lda	FreeClu    +1
			sbc	CountFreeClu+1
			sta	r2H

			jsr	CalcBytes
			jsr	PrnTxtByte

			jsr	UseSystemFont		;Anzahl freier Cluster ausgeben.
			PrintXY	20,100,V302e3
			jsr	PutInfoEntry
			MoveB	CountFreeClu+0,r0L
			MoveB	CountFreeClu+1,r0H
			ClrB	r1L
			ldy	#$07
			jsr	DoZahl24Bit

			jsr	UseSystemFont		;Anzahl freier Bytes ausgeben.
			PrintXY	20,112,V302e4
			jsr	PutInfoEntry
			MoveW	CountFreeClu,r2
			jsr	CalcBytes
			jsr	PrnTxtByte

			jsr	UseSystemFont		;Anzahl Gesamt-Bytes ausgeben.
			PrintXY	20,124,V302e5
			jsr	PutInfoEntry
			MoveB	FreeByte+0,r0L
			MoveB	FreeByte+1,r0H
			MoveB	FreeByte+2,r1L
			jsr	PrnTxtByte

			jmp	StartDirMenu

:PrnTxtByte		ldy	#$07
			jsr	DoZahl24Bit

			jsr	UseSystemFont
			LoadW	r0,V302e6
			jmp	PutString

;*** Bytes berechnen.
:CalcBytes		lda	#$00			;Speicherzähler löschen.
			sta	r0L
			sta	r0H
			sta	r1L

::101			CmpW0	r2			;Cluster = 0 ?
			beq	:102			;Ja, Ende...

			clc				;Bytes pro Cluster zu
			lda	r0L			;freiem Speicher addieren.
			adc	CluByte+0
			sta	r0L
			lda	r0H
			adc	CluByte+1
			sta	r0H
			lda	r1L
			adc	#$00
			sta	r1L

			SubVW	1,r2			;Anzahl Cluster -1.
			jmp	:101			;Weiterzählen...

::102			rts

;*** Diskettenkapazitäten ausgeben.
:GetDirInfo		lda	#$00
			sta	UsedByte+0		;Diskettenspeicher löschen.
			sta	UsedByte+1
			sta	UsedByte+2
			sta	UsedByte+3
			sta	DirFiles+0		;Anzahl Dateien löschen.
			sta	DirFiles+1

			jsr	GoTopDir		;Zum Verzeichnisanfang zurück.

::101			jsr	RdCurDirSek		;Aktuelen Verzeichnis-Sektor lesen.

::102			ldx	V302a7
			bne	:105
::103			stx	V302a7

			ldy	#$00			;Byte aus Eintrag lesen.
			lda	(a8L),y			;Byte = $00 = Verzeichnisende ?
			beq	:106			;Nein, weiter.
			cmp	#$e5			;Datei gelöscht ?
			beq	:104			;Ja, übergehen.

			jsr	AddBytes		;Dateigrößen addieren.

::104			ldx	#a8L
			jsr	Add32Byte

			ldx	V302a7
::105			inx
			cpx	#$10
			bne	:103

			jsr	RdNxDirSek		;Nächsten Directory-Sektor lesen.
			bcc	:102			;Weiteren Sektor gefunden ? Ja, weiter.

::106			jsr	ResetDir		;Verzeichnis zurücksetzen.

;*** Anzahl belegter Cluster berechnen.
:GetCluInfo		jsr	Max_Free		;Gesamtspeicher berechnen.

			LoadW	a1,FAT			;Zeiger auf FAT bereitstellen.
			lda	#$00
			sta	CountClu+0		;Zähler Cluster Initialisieren.
			sta	CountClu+1
			sta	CountFreeClu+0		;Zähler freie Cluster Initialisieren.
			sta	CountFreeClu+1

::101			clc				;Zeiger auf Cluster in FAT setzen und
			lda	CountClu		;Zeiger einlesen.
			adc	#$02
			tay
			lda	CountClu+1
			adc	#$00
			tax
			tya
			jsr	Get_Clu

			CmpW0	r1			;Cluster frei ?
			bne	:102			;Nein, weiter...

			IncWord	CountFreeClu		;Anzahl freie Cluster um 1 erhöhen.
::102			IncWord	CountClu		;Zähler +1 bis alle Cluster geprüft.
			CmpW	CountClu,FreeClu
			bne	:101
			rts

;*** Dateigrößen addieren.
:AddBytes		ldy	#$0b			;Prüfen ob Eintrag = Datei.
			lda	(a8L),y
			and	#%00001000
			beq	:102
::101			rts				;Keine Datei.

::102			lda	(a8L),y
			and	#%00010000
			bne	:101

			ldy	#$1a			;Prüfen ob Start-Cluster = 0.
			lda	(a8L),y
			bne	:103			;Nein, Gültige Datei.
			iny
			lda	(a8L),y
			beq	:101			;Ja, Keine Datei.

::103			ldy	#$1c			;Datei-Größe aus aktuellem
							;Directory-Eintrag im RAM holen.
			clc
			lda	(a8L),y			;Datei-Größe Low-Byte.
			adc	UsedByte+0
			sta	UsedByte+0
			iny
			lda	(a8L),y			;Datei-Größe Middle-Byte.
			adc	UsedByte+1
			sta	UsedByte+1
			iny
			lda	(a8L),y			;Datei-Größe High-Byte.
			adc	UsedByte+2
			sta	UsedByte+2

			IncWord	DirFiles		;Anzahl Einträge im Directory +1.
			rts

;*** Mausklick überprüfen.
:SlctFile		ClrB	a0L
::101			jsr	CopyMouseData		;Mausbereich einlesen.

			php				;Maus innerhalb Bereich ?
			sei
			jsr	IsMseInRegion
			plp
			tax
			beq	:102			;Nein, weiter...
			jmp	(r5)			;Ja, Routine aufrufen.

::102			inc	a0L			;Alle Bereiche überprüft ?
			lda	a0L
			cmp	#10
			bne	:101			;Nein, weiter...
			rts				;Ja, Abbruch...

;*** Bereichsdaten einlesen.
:CopyMouseData		asl
			asl
			asl
			tay
			ldx	#$00
::101			lda	V302f1,y
			sta	r2L,x
			iny
			inx
			cpx	#$08
			bne	:101
			rts

;*** Dauerfunktion ?
:TestMouse		;jsr	CPU_Pause		;Wartepause.
			lda	mouseData		;Maustaste noch gedrückt ?
			bne	:101			;Nein, weiter...
			sec
			rts

::101			ClrB	pressFlag
			clc
			rts

;*** Mausklick beenden.
:EndSlctIcon		jsr	CopyMouseData
			jmp	InvertRectangle

;*** Anzeige ändern.
:MoveLeft		bit	DisplayMode
			bmi	EndMove
			ldx	V302b2
			beq	EndMove
			dex
			jmp	InitMove

;*** Anzeige ändern.
:MoveRight		bit	DisplayMode
			bmi	EndMove
			ldx	V302b2
			bne	EndMove
			inx
:InitMove		stx	V302b2

;*** Seite anzeigen und auf Maustaste warten.
:NPageAndMse		jsr	Show16Files
:WaitMouse		NoMseKey
:EndMove		rts

;*** Unterverzeichnis öffnen.
:SlctSubDir		bit	DisplayMode		;Dateimodus ?
			bmi	:101			;Nein, Mausklick übergehen.

			php				;Interrupt sperren.
			sei

			lda	mouseYPos		;Mausposition berechnen.
			lsr
			lsr
			lsr
			pha
			sub	6

			adda	V302a1			;Zeiger auf Datei berechnen.
			sta	a8L
			ClrB	a8H
			ldx	#a8L
			ldy	#$05
			jsr	DShiftLeft
			AddVW	Memory2,a8

			pla
			tax
			plp

			ldy	#$0b
			lda	(a8L),y
			and	#%00010000		;Datei gleich Verzeichnis ?
			bne	:102			;Ja, weiter...
			jsr	WaitMouse
::101			rts

::102			txa				;Eintrag invertieren.
			asl
			asl
			asl
			sta	r2L
			add	$07
			sta	r2H
			jsr	InvertRectangle

			jsr	WaitMouse

;*** Neues Verzeichnis öffnen.
:GetNewDir		ldy	#$1f			;Verzeichniseintrag in Zwischen-
::101			lda	(a8L),y			;speicher übertragen.
			sta	Dir_Entry,y
			dey
			bpl	:101

			lda	Dir_Entry+26		;Cluster = 0 ?
			ldx	Dir_Entry+27
			bne	:102
			tay
			beq	:103			;Ja, Hauptverzeichnis aktivieren.

::102			sta	V302a3+0		;Als ersten Cluster speichern.
			stx	V302a3+1
			sta	V302a4+0		;Als aktuellen Cluster speichern.
			stx	V302a4+1
			lda	#$ff
::103			sta	DirType			;Verzeichnismodus ändern.
			jmp	OpenNewDir		;Verzeichnis öffnen.

;*** Hauptverzeichnis öffnen.
:GoRootDir		jsr	InvertRectangle
			lda	#$00
			sta	DirType			;Hauptverzeichnis.
			sta	DisplayMode		;Dateimodus.
:OpenNewDir		jsr	Do1stInit		;Zeiger auf ersten Verzeichnis-Sektor.
			jsr	Read112Dir		;Dateien einlesen.
			jmp	Bildschirm_b		;Bildschirm aufbauen.

;*** Ein Verzeichnis zurück.
:GoBack1Dir		bit	DirType			;Hauptverzeichnis ?
			bmi	:101			;Nein, weiter...
			rts

::101			jsr	InvertRectangle

			ClrB	DisplayMode

			jsr	Do1stInit		;Zeiger auf ersten Verzeichnis-Sektor.
			jsr	RdCurDirSek		;Sektor lesen.

			ldx	#a8L
			jsr	Add32Byte
			jmp	GetNewDir		;"Parent"-Verzeichnis öffnen.

;*** Balken verschieben.
:MoveBar		bit	DisplayMode
			bmi	:101
			lda	V302a0
			cmp	#18 +1
			bcc	:101
			jsr	IsMseOnPos		;Position der Maus ermitteln.
			cmp	#$01			;Oberhalb des Anzeigebalkens ?
			beq	:102			;Ja, eine Seite zurück.
			cmp	#$02			;Auf dem Anzeigebalkens ?
			beq	:103			;Ja, Balken verschieben.
			cmp	#$03			;Unterhalb des Anzeigebalkens ?
			beq	:104			;Ja, eine Seite vorwärts.
::101			rts

::102			jmp	LastPage
::103			jmp	MoveToPos
::104			jmp	NextPage

;*** Balken verschieben.
:MoveToPos		jsr	StopMouseMove		;Mausbewegung einschränken.

::101			jsr	UpdateMouse		;Mausdaten aktualisieren.
			ldx	mouseData		;Maustaste noch gedrückt ?
			bmi	:102			;Nein, neue Position anzeigen.
			lda	inputData		;Mausbewegung einlesen.
			bne	:103			;Mausbewegung auswerten.
			beq	:101			;Keine Bewegung, Schleife...

::102			ClrB	pressFlag		;Maustastenklick löschen.
			LoadW	r0,V302f2
			jsr	InitRam
			jmp	Show16Files		;Position anzeigen.

::103			cmp	#$02			;Maus nach oben ?
			beq	:104			;Ja, auswerten.
			cmp	#$06			;Maus nach unten ?
			beq	:105			;Ja, auswerten.
			jmp	:101			;Keine Bewegung, Schleife...

::104			jsr	LastFile_a
			bcs	:101			;Geht nicht, Abbruch.
			dec	V302a1			;Zeiger auf letzte Datei.
			jmp	:106			;Neue Position anzeigen.

::105			jsr	NextFile_a		;Eine Datei vorwärts.
			bcs	:101			;Geht nicht, Abbruch.
			inc	V302a1			;Zeiger auf nächste Datei.
::106			lda	V302a1			;Tabellenposition einlesen und
			jsr	SetPosBalken		;Anzeigebalken setzen und
			jsr	SetRelMouse		;Maus entsprechend verschieben.
			jmp	:101			;Maus weiter auswerten.

;*** Zum Anfang der Tabelle.
:TopFile		lda	V302a1
			beq	:101
			ClrB	V302a1
			jmp	NPageAndMse
::101			rts

;*** Zum Ende der Tabelle.
:EndFile		lda	V302a0
			sub	18
			bcc	:101
			sta	V302a1+0
			jmp	NPageAndMse
::101			rts

;*** Eine Seite vor.
:NextPage		lda	V302a1
			add	36
			bcs	:101
			cmp	V302a0
			bcc	:102
::101			jmp	EndFile

::102			sub	18
			sta	V302a1
			jmp	NPageAndMse

;*** Eine Seite zurück.
:LastPage		lda	V302a1
			sub	18
			bcs	:101
			jmp	TopFile

::101			sta	V302a1
			jmp	NPageAndMse

;*** Tabelle bewegen.
:NextFile		jsr	InvertRectangle

::101			jsr	NextFile_a		;Scrolling möglich ?
			bcs	:102			;Nein, Ende...
			jsr	ScrollDown		;Eine Zeile scrollen.

			lda	V302a1			;Balken neu positionieren.
			jsr	SetPosBalken

			jsr	TestMouse		;Maustaste noch gedrückt ?
			bcs	:101			;Weiterscrollen.

::102			lda	#$04
			jmp	EndSlctIcon

:NextFile_a		lda	DisplayMode
			bne	:101
			lda	V302a0
			cmp	#18
			bcc	:101
			lda	V302a1
			add	18
			cmp	V302a0
			bcc	:102
::101			sec
			rts
::102			clc
			rts

;*** Eine Datei vorwärts.
:ScrollDown		php
			sei

			LoadW	r0,SCREEN_BASE + 7*40*8 + 1*8
			LoadW	r1,SCREEN_BASE + 6*40*8 + 1*8

			ldx	#17
::101			lda	#2
::102			pha
			ldy	#$00			;18 Grafikzeilen a 296 Byte.
::103			lda	(r0L),y			;verschieben.
			sta	(r1L),y
			iny
			cpy	#152
			bne	:103

			AddVBW	152,r0
			AddVBW	152,r1

			pla
			sub	1
			bne	:102

			AddVBW	16,r0
			AddVBW	16,r1

			dex
			bne	:101
			plp

			inc	V302a1
			MoveB	V302a1,a8L
			ClrB	a8H
			ldx	#a8L
			ldy	#$05
			jsr	DShiftLeft
			AddVW	Memory2+17*32,a8
			LoadB	V302a10,190		;Y-Pos. für Ausgabe Directory-Eintrag.
			jmp	DoFile			;Eintrag ausgeben.

;*** Tabelle Target bewegen.
:LastFile		jsr	InvertRectangle

::101			jsr	LastFile_a
			bcs	:102
			jsr	ScrollUp		;Eine Zeile scrollen.

			lda	V302a1			;Balken neu positionieren.
			jsr	SetPosBalken

			jsr	TestMouse		;Maustaste noch gedrückt ?
			bcs	:101			;Weiterscrollen.

::102			lda	#$03
			jmp	EndSlctIcon

:LastFile_a		lda	DisplayMode
			bne	:101
			lda	V302a0
			cmp	#18
			bcc	:101
			lda	V302a1
			bne	:102
::101			sec
			rts
::102			clc
			rts

;*** Eine Datei zurück.
:ScrollUp		php
			sei

			LoadW	r0,SCREEN_BASE + 22*40*8 + 1*8 + 152
			LoadW	r1,SCREEN_BASE + 23*40*8 + 1*8 + 152

			ldx	#$11
::101			lda	#$02
::102			pha
			ldy	#151			;18 Grafikzeilen a 296 Byte.
::103			lda	(r0L),y			;verschieben.
			sta	(r1L),y
			dey
			cpy	#255
			bne	:103

			SubVW	152,r0
			SubVW	152,r1

			pla
			sub	1
			bne	:102

			SubVW	16,r0
			SubVW	16,r1

			dex
			bne	:101
			plp

			dec	V302a1
			MoveB	V302a1,a8
			ClrB	a8H
			ldx	#a8L
			ldy	#$05
			jsr	DShiftLeft
			AddVW	Memory2,a8
			LoadB	V302a10,54		;Y-Pos. für Ausgabe Directory-Eintrag.
			jmp	DoFile			;Eintrag ausgeben.

;*** Dateien im Speicher sortieren.
:SortDir		ldx	V302a0			;Mehr als 1 Datei ?
			cpx	#$02
			bcs	:101			;Ja, Weiter...
			rts

::101			dex				;Zeiger auf letzten Eintrag berechnen.
			stx	r14L
			ClrB	r14H
			ldx	#r14L
			ldy	#$05
			jsr	DShiftLeft
			AddVW	Memory2,r14
			LoadW	r15,Memory2

::102			MoveW	r14,r13			;Zeiger auf letzte Datei.

::103			ldy	#$00			;Zeichen vergleichen.
::104			lda	(r13L),y
			cmp	(r15L),y
			bcs	:106

			ldy	#$1f			;Einträge tauschen.
::105			lda	(r13L),y
			tax
			lda	(r15L),y
			sta	(r13L),y
			txa
			sta	(r15L),y
			dey
			bpl	:105

::106			bne	:107
			iny				;Weitervergleichen bis
			cpy	#11			;alle 11 Zeichen geprüft.
			bne	:104

::107			CmpW	r13,r15
			beq	:108
			SubVW	32,r13
			jmp	:103

::108			ldx	#r15L
			jsr	Add32Byte
			CmpW	r14,r15			;Alle Dateien sortiert ?
			bne	:102			;Nein, weiter...

			ClrB	V302a1			;Dateien neu anzeigen.
			jmp	Bildschirm_b

;*** Name der Hilfedatei.
:HelpFileName		b "06,GDH_DOS/Disk",NULL

;*** Variablen zur Steuerung des Directorys.
:UsedByte		s $04				;Anzahl verbrauchter Bytes.
:DirFiles		w $0000				;Anzahl Files im Directory.
:CountClu		w $0000				;Zähler für ":CalcFreeClu".
:CountFreeClu		w $0000				;Zähler für ":CalcFreeClu".

:DirType		b $00				;$00 = Root
							;$FF = SubDir
:DisplayMode		b $00				;$00 = Anzeige Dateien.
							;$FF = Anzeige Verzeichnis.
:DrvOnScrn		s $04				;Laufwerke auf Bildschirm.
:DskDatMem		s 20				;Zwischenspeicher für Verzeichnisangaben.
:V302k1			s $05				;Speicher für DOS-Datum.

:V302a0			b $00				;Anzahl Einträge im RAM.
:V302a1			b $00				;Zeiger auf Eintrag im RAM.
:V302a2			s $03				;Seite,Spur,Sektor.
:V302a3			w $0000				;Start-Cluster Unterverzeichnis.
:V302a4			w $0000				;Cluster-Nummer im Unterverzeichnis.
:V302a5			w $0000				;Anzahl Sektoren im Hauptverzeichnis.
:V302a6			b $00				;Aktueller Sektor in Cluster.
:V302a7			b $00				;Zeiger auf Eintrag im Sektor.
:V302a8			w $0000				;Adresse Eintrag in Verzeichnis-Sektor.
:V302a9			b $00				;Anzahl Einträge auf Seite.
:V302a10		b $00				;Y-Koordinate.

:V302b0			b $00				;$00 = Es folgen weitere Dateien.
							;$FF = Verzeichnisende erreicht.
:V302b1			b $00				;$00 = weniger als 112 Dateien.
							;$FF = Speicherüberlauf.
:V302b2			b $00				;$00 = Name,Größe,Datum,Zeit.
							;$01 = Name,Attribute.

if Sprache = Deutsch
:V302c0			b PLAINTEXT
			b GOTOXY
			w $0020
			b $64
			b "Verzeichnis ist leer!"
			b NULL
:V302c1			b " Byte(s) verfügbar",NULL
:V302c2			b " Datei(en) im Speicher",NULL

:V302d0			b PLAINTEXT,"PCDOS: "									 ,NULL
:V302d1			b	"<Sub Dir>" 			,NULL
:V302d2			b PLAINTEXT,"Datei:         .   "							,NULL
:V302d3			b	"Lesen" 			,NULL
:V302d4			b	"Versteckt" 		,NULL
:V302d5			b	"System" 		,NULL
:V302d6			b	"Archiv" 		,NULL

:V302e0			b PLAINTEXT,BOLDON,"Dateien im Verzeichnis"						,NULL
:V302e1			b PLAINTEXT,BOLDON,"Bytes im Verzeichnis"						,NULL
:V302e2			b PLAINTEXT,BOLDON,"Belegter Speicher"							,NULL
:V302e3			b PLAINTEXT,BOLDON,"Anzahl freier Cluster"						,NULL
:V302e4			b PLAINTEXT,BOLDON,"Verfügbarer Speicher"						,NULL
:V302e5			b PLAINTEXT,BOLDON,"Speicher gesamt"							,NULL
:V302e6			b           BOLDON," Byte(s)"								,NULL
endif

if Sprache = Englisch
:V302c0			b PLAINTEXT
			b GOTOXY
			w $0020
			b $64
			b "Directory empty!"
			b NULL
:V302c1			b " Byte(s) available",NULL
:V302c2			b " File(s) in memory",NULL

:V302d0			b PLAINTEXT,"PCDOS: "									 ,NULL
:V302d1			b	"<Sub Dir>" 			,NULL
:V302d2			b PLAINTEXT,"File :         .   "							,NULL
:V302d3			b	"Read" 			,NULL
:V302d4			b	"Hidden" 		,NULL
:V302d5			b	"System" 		,NULL
:V302d6			b	"Archiv" 		,NULL

:V302e0			b PLAINTEXT,BOLDON,"Files in directory"							,NULL
:V302e1			b PLAINTEXT,BOLDON,"Bytes in directory"							,NULL
:V302e2			b PLAINTEXT,BOLDON,"Used diskspace"							,NULL
:V302e3			b PLAINTEXT,BOLDON,"Free cluster"							,NULL
:V302e4			b PLAINTEXT,BOLDON,"Available diskspace"						,NULL
:V302e5			b PLAINTEXT,BOLDON,"Disksize"								,NULL
:V302e6			b           BOLDON," Byte(s)"								,NULL
endif

;*** Daten für Scrollbalken.
:V302f0			b $27,$38,$80,$ff,$12,$00

;*** Daten für Mausabfrage.
:V302f1			b $28,$2f
			w $0130,$0137,MoveLeft
			b $28,$2f
			w $0138,$013f,MoveRight
			b $30,$bf
			w $0000,$0137,SlctSubDir
			b $30,$37
			w $0138,$013f,LastFile
			b $b8,$bf
			w $0138,$013f,NextFile
			b $38,$b7
			w $0137,$013f,MoveBar
			b $28,$2f
			w $0010,$001f,SelectDrvA
			b $28,$2f
			w $0030,$003f,SelectDrvB
			b $28,$2f
			w $0050,$005f,SelectDrvC
			b $28,$2f
			w $0070,$007f,SelectDrvD

;*** Maus-Fenstergrenzen.
:V302f2			w mouseTop
			b $06
			b $00,$c7
			w $0000,$013f
			w $0000

;*** Icon-Tabelle
:Icon_Tab1		b	3			;Icons für Hauptverzeichnis.
			w	$0000
			b	$00

			w	Icon_00
			b	$00,$08,$05,$18
			w	L302ExitGD

:Icon_Tab1a		w	Icon_03
			b	$05,$08,$05,$18
:Icon_Tab1b		w	DiskInfo

			w	Icon_05
			b	$0a,$08,$05,$18
			w	DOS_ExitPrn

:Icon_Tab1c		s	4 * 8

:Icon_Tab1d		w	Icon_09
			b	$16,$08,$05,$18
			w	SortDir

			w	Icon_02
			b	$16,$08,$05,$18
			w	GoRootDir

			w	Icon_02a
			b	$25,$08,$05,$18
			w	GoBack1Dir

:Icon_Tab1e		w	Icon_01
			b	$25,$08,$05,$18
			w	FileNxt112

;*** Icons.
if Sprache = Deutsch
:Icon_00
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_00
<MISSING_IMAGE_DATA>
endif

:Icon_01
<MISSING_IMAGE_DATA>

:Icon_01a
<MISSING_IMAGE_DATA>

:Icon_02
<MISSING_IMAGE_DATA>

:Icon_02a
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
:Icon_03
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_03
<MISSING_IMAGE_DATA>
endif

if Sprache = Deutsch
:Icon_04
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_04
<MISSING_IMAGE_DATA>
endif

if Sprache = Deutsch
:Icon_05
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_05
<MISSING_IMAGE_DATA>
endif

:Icon_08
<MISSING_IMAGE_DATA>

:Icon_09
<MISSING_IMAGE_DATA>

:Icon_10
<MISSING_IMAGE_DATA>

:EndProgrammCode

;*** Startadresse Zwischenspeicher.
;    Directory der aktuellen Diskette.
:Memory1		s 80 +1
:Memory2		= ((Memory1+81) / 256 +1) * 256
