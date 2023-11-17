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

:LastGEOSType		= 23				;Max. Anzahl GEOS-Filetypen.
							;Der letzte Datei-Typ ist "GEOS ???".
:MaxFiles		= 240
:DB_DblBit		= $8871

endif

			n	"mod.#402.obj"
			o	ModStart
			q	EndProgrammCode
			r	EndAreaCBM - (MaxFiles * 32)

			jmp	CBM_Dir
			jmp	CBM_Dir

			t	"-FontType2"
			t	"-CBM_GetDskNam"

;*** L402: Verzeichnis ausgeben.
:CBM_Dir		ldx	#$00			;Diskette einlegen.
			lda	curDrive
			jsr	InsertDisk
			cmp	#$01
			beq	CBM_InitDir
			jmp	L402ExitGD

:CBM_InitDir		jsr	NewOpenDisk
			jsr	CBM_GetDskNam
			ldx	#$ff
			lda	curDirHead+32
			cmp	#$01
			bne	:101
			lda	curDirHead+33
			cmp	#$01
			bne	:101
			ldx	#$00
::101			stx	DirType

;*** Ausgabe der ersten Directory-Seite.
			lda	#$00
			sta	DisplayMode
			sta	Display240
			sta	V402b2

:Start_Dir		jsr	Do1stInit
			jsr	Read240Dir		;Verzeichnis einlesen.
			jmp	Bildschirm_a

;*** Directory-Icons aktivieren.
:StartDirMenu		LoadW	r0,HelpFileName
			lda	#<Start_Dir
			ldx	#>Start_Dir
			jsr	InstallHelp

			StartMouse			;Maus aktivieren.
			NoMseKey

:SetMIconCol		jsr	i_C_MenuMIcon
			b	$00,$01,$00,$03

			lda	#$00			;Mausabfrage installieren.
			tax
			bit	DisplayMode		;Speicheranzeige ?
			bmi	:101			;Ja, keine Mausabfrage.
			lda	#<SlctFile		;Mausabfrage zum starten/öffnen
			ldx	#>SlctFile		;von Dateien.
::101			sta	otherPressVec+0
			stx	otherPressVec+1

			LoadW	r0,Icon_Tab1
			jmp	DoIcons

;*** Partition wechseln.
:L402OtherPart		jsr	ClrWin			;Bildschirm löschen.
			jsr	CMD_OtherPart
			jmp	CBM_Dir

;*** Zurück zu GeoDOS.
:CloseNDir		ldy	curDrive		;Aktuelles Laufwerk einlesen.
			lda	DriveModes-8,y		;Laufwerkstyp einloesen.
			and	#%00100000		;NativeMode?
			beq	L402ExitGD
			lda	DirType
			beq	L402ExitGD
			jmp	GoBack1Dir_a

:L402ExitGD		jsr	ClrWin			;Bildschirm löschen.
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
			jmp	CBM_Dir

;*** BAM der aktuellen Diskette einlesen.
:GetCurDskBAM		jsr	GetDirHead		;BAM einlesen.
:GetCurBAMInfo		LoadW	r5,curDirHead		;Diskettenspeicher berechnen.
			jmp	CalcBlksFree

;*** Bildschirm initialisieren.
:Bildschirm_a		jsr	ClrScreen		;Fenster aufbauen.

			jsr	i_C_MenuTitel
			b	$00,$00,$28,$01
			jsr	i_C_MenuBack
			b	$00,$01,$28,$18

			jsr	UseGDFont
			Print	$08,$06
if Sprache = Deutsch
			b	PLAINTEXT,"CBM  -  Inhaltsverzeichnis"
endif
if Sprache = Englisch
			b	PLAINTEXT,"CBM  -  Directory"
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
			Print	$90,$2c
			b	PLAINTEXT,"Disk: ",NULL
			PrintStrgcbmDiskName

			jsr	UseMiniFont
			FillPRec$00,$c1,$c7,$0001,$013e

			jsr	GetCurBAMInfo		;BAM der aktuellen Diskette einlesen.

			LoadW	r11,8			;Belegte Blocks ausgeben.
			LoadB	r1H,198
			ClrB	currentMode
			MoveW	r4,r0
			lda	#%11000000
			jsr	PutDecimal
			PrintStrgV402c1

			AddVBW	16,r11			;Anzahl Dateien im Speicher.
			MoveB	V402a0,r0L
			ClrB	r0H
			lda	#%11000000
			jsr	PutDecimal
			PrintStrgV402c2

			lda	V402a0			;Rollbalken initialisieren.
			sta	V402f0+3
			LoadW	r0,V402f0
			jsr	InitBalken		;Anzeigebalken auf Bildschirm.
			jsr	Show16Files		;16 Dateien anzeigen.
			jsr	PrintDrives		;Laufwerksbezeichnungen ausgeben.
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

			jsr	i_BitmapUp		;Anzeige-Icons.
			w	Icon_09
			b	$26,$28,$02,$08
			jsr	i_C_Balken
			b	$26,$05,$02,$01

;*** Icon-Tabelle definieren.
			LoadB	Icon_Tab1,3
			LoadB	r14H,$0f
			LoadW	r15,Icon_Tab1c

			lda	V402a0			;Anzeigemodus definieren.
			beq	:102
			ldx	#$00
			jsr	Copy1Icon

::102			bit	curDrvMode		;Partitions-Icon definieren.
			bpl	:103
			ldx	#$08
			jsr	Copy1Icon

::103			ldy	curDrive		;Aktuelles Laufwerk einlesen.
			lda	DriveModes-8,y		;Laufwerkstyp einloesen.
			and	#%00100000		;NativeMode?
			beq	:104
			bit	DirType
			bpl	:104
			ldx	#$10			;"ROOT-Dir"
			jsr	Copy1Icon
			ldx	#$18			;"SubDir"
			jsr	Copy1Icon

;*** "MaxFiles-Datei"-Icons.
::104			bit	Display240		;Icons für Seitenwechsel definieren.
			bmi	:105

			lda	V402b1
			beq	:107

::105			lda	#<Icon_01
			ldx	#>Icon_01
			bit	V402b0
			bpl	:106

			lda	#<Icon_01a
			ldx	#>Icon_01a
::106			sta	Icon_Tab1e+0
			stx	Icon_Tab1e+1

			ldx	#$20
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

;*** Laufwerksbezeichnungen ausgeben.
:PrintDrives		jsr	UseMiniFont

			LoadW	r14,9
			LoadB	:104 +2,$02

			lda	#$00
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
			lda	DriveTypes,y
			beq	:105

			pla
			pha
			add	8
			ldx	r15L
			sta	DrvOnScrn,x
			inc	r15L

			pla
			pha
			add	"A"
			jsr	SmallPutChar

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

::101a			pla
			pha
			tay
			lda	DriveTypes,y		;Diskwechsel erlauben.
			cmp	#Drv_CMDHD
			beq	:102
			cmp	#Drv_64Net
			beq	:102
			lda	DriveModes,y
			and	#%00001000
			bne	:102
			ldx	#<Icon_11		;Diskettenlaufwerk.
			ldy	#>Icon_11
			bne	:103

::102			ldx	#<Icon_12		;CMD_HD/RAM/64Net.
			ldy	#>Icon_12

::103			stx	:104 +0
			sty	:104 +1
			jsr	i_BitmapUp
::104			w	Icon_11
			b	$00,$27,$02,$08

			AddVB	4,:104 +2
			AddVBW	32,r14

::105			pla
			add	1
			cmp	#$04
			beq	:106
			jmp	:101

::106			rts

;*** Directory-Fenster löschen und
;    ":otherPressVec" löschen.
:ClrWin			ClrW	otherPressVec
			jmp	ClrScreen

;*** Neue Seite vorbereiten.
:ClrWinBox		jsr	i_C_MenuTBox
			b	$00,$06,$27,$12
			FillPRec$00,$30,$bf,$0000,$0137
			jmp	UseGDFont

;*** Cursor positionieren und Zahlenwert ausgeben..
:PutInfoEntry		LoadW	r11,184			;Cursor-Position für Doppelpunkt.
			lda	#":"			;Doppelpunkt setzen.
			jsr	SmallPutChar
			LoadB	currentMode,0		;Schriftstile löschen.
			LoadW	r11,192			;Cursor-Position für Directory-Daten.
			jmp	UseGDFont		;GeoDOS-Font aktivieren.

;*** Zahlenwert ausgeben.
:PutEntry2		ClrB	r1L			;16-Bit Zahl ausgeben.
			ldy	#$07
			jmp	DoZahl24Bit

;*** HEX-Zahl nach ASCII wandeln.
:HexASCII_a		jsr	PrepNum100		;100er-Zahlen konvertieren.
			pha
			lda	#"0"			;Zehner-Stelle auf "0" setzen.
			sta	Memory1+0,x
			pla
::101			cmp	#10			;Zahl < 10 ?
			bcc	:102			;Ja, Ende...
			inc	Memory1,x		;Nein, Zehner-Stelle erhöhen.
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
:Do1stInit		lda	#$00
			sta	V402a0			;Anzahl Dateien löschen.
			sta	V402a1			;Zeiger auf Position #1.
			sta	V402a7			;Zeiger auf ersten Eintrag.
			sta	V402b0			;Weiteren Dateien im Verzeichnis.
			sta	V402b1			;Weniger als 128 Dateien.

			lda	#<diskBlkBuf		;Zeiger auf Sektorspeicher.
			sta	V402a8 +0
			lda	#>diskBlkBuf
			sta	V402a8 +1

			jsr	GetDirHead		;BAM einlesen.

			lda	curDirHead+0		;Zeiger auf ersten Verzeichnissektor
			sta	V402a3    +0		;einlesen.
			sta	V402a4    +0
			lda	curDirHead+1
			sta	V402a3    +1
			sta	V402a4    +1
			rts

;*** Verzeichnisposition speichern.
:SaveDir		jsr	i_MoveData
			w	V402a0
			w	DskDatMem
			w	11
			rts

;*** Verzeichnisposition zurücksetzen.
:ResetDir		jsr	i_MoveData
			w	DskDatMem
			w	V402a0
			w	11
			rts

;*** Die ersten Dateien einlesen.
:File1st240		bit	V402b1			;Mehr als 240 Dateien ?
			bpl	FileNext_b		;Ja, Icon auswerten.
			jsr	InvertRectangle
			jsr	Do1stInit		;Zeiger auf ersten Verzeichnis-Sektor.
			jmp	FileNext_a		;Dateien einlesen & ausgeben.

;*** Die nächsten Dateien einlesen.
:FileNxt240		bit	V402b1			;Mehr als 240 Dateien ?
			bpl	FileNext_b		;Ja, Icon auswerten.
			bit	V402b0			;Verzeichnis-Ende erreicht ?
			bmi	File1st240		;Ja, Ende...
			jsr	InvertRectangle
:FileNext_a		jsr	Read240Dir		;128 Dateien einlesen.
			jmp	Bildschirm_b		;Bildschirm aufbauen.
:FileNext_b		rts

;*** ":MaxFiles" Dateien einlesen.
:Read240Dir		jsr	DoInfoBox		;Info ausgeben.
			PrintStrgDB_RdFile

			jsr	i_FillRam		;Speicher löschen.
			w	32*MaxFiles
			w	Memory2
			b	$00

			lda	#$00			;Zähler für Anzahl Einträge und
			sta	V402a0			;Zähler für aktuellen Eintrag löschen.
			sta	V402a1

			LoadW	a7,Memory2		;Zeiger auf Anfang des Speichers.

::101			jsr	RdCurDirSek		;Aktuelen Verzeichnis-Sektor lesen.

::102			jsr	GetNxtEntry		;Folgt weiterer Eintrag ?
			beq	:103			;Ja, einlesen.
			LoadB	V402b0,$ff		;Directory-Ende kennzeichnen.
			rts

::103			ldy	#$1f
::104			lda	(r0L),y			;Eintrag kopieren.
			sta	(a7L),y
			dey
			bpl	:104

			AddVBW	32,a7			;Zeiger auf Speicher für nächsten
			inc	V402a0			;Eintrag richten.

			lda	V402a0
			cmp	#MaxFiles		;Speicher voll ?
			bcc	:102			;Nein, weiter...

			jsr	SaveDir			;Verzeichnisposition merken.
			jsr	GetNxtEntry		;Folgt weiterer Eintrag ?
			pha
			jsr	ResetDir		;Verzeichnisposition zurücksetzen.
			pla
			eor	#%11111111		;Ergebnis als Flag für weitere Dateien.
			sta	V402b1			;($FF = weitere Dateien!)
			rts

;*** Nächsten Eintrag suchen.
:GetNxtEntry		lda	V402a7			;Alle Einträge des aktuellen
			cmp	#8			;Sektors gelesen ?
			bcc	:101			;Nein, weiter...

			jsr	RdNxDirSek		;Nächsten Directory-Sektor lesen.
			bcc	:101			;Weiteren Sektor gefunden ? Ja, weiter.
			lda	#$ff			;Verzeichnisende.
			rts

::101			ldy	#$02			;Byte aus Eintrag lesen.
			lda	(a8L),y			;Byte = $00 ?
			jsr	TestDirEntry
			tax				;Ergebnis merken.
			clc				;Zeiger auf nächsten Eintrag.
			lda	a8L
			sta	r0L
			adc	#32
			sta	a8L
			lda	a8H
			sta	r0H
			adc	#0
			sta	a8H
			inc	V402a7
			txa				;Datei gültig ?
			bne	GetNxtEntry		;Nein, weiter...
			rts

;*** Eintrag überprüfen.
:TestDirEntry		and	#%00001111
			beq	:101			;Ja, übergehen.
			lda	#$00
			rts

::101			lda	#$ff			;Datei ungültig!
			rts

;*** Aktuellen Verzeichnissektor lesen.
:RdCurDirSek		MoveB	V402a4+0,r1L		;Aktuellen Verzeichnis-Sektor lesen.
			MoveB	V402a4+1,r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa
			beq	:101
			jmp	DiskError		;Diskettenfehler.

::101			MoveW	V402a8,a8
			rts

;*** Nächsten Verzeichnissektor lesen.
:RdNxDirSek		lda	diskBlkBuf+0
			beq	:102
			sta	V402a4    +0
			sta	r1L
			lda	diskBlkBuf+1
			sta	V402a4    +1
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa
			beq	:101
			jmp	DiskError		;Diskettenfehler.

::101			lda	#<diskBlkBuf		;Zeiger auf Sektorspeicher.
			sta	V402a8 +0
			sta	a8L
			lda	#>diskBlkBuf
			sta	V402a8 +1
			sta	a8H

			lda	#$00
			sta	V402a7
			clc
			rts

::102			sec
			rts

;*** Dateien anzeigen, Icon-Tabelle definieren.
:View16Files		jsr	Show16Files
			jmp	StartDirMenu

;*** 16 Dateien anzeigen.
:Show16Files		LoadB	DisplayMode,$00
			LoadW	Icon_Tab1a,Icon_03
			LoadW	Icon_Tab1b,DiskInfo

			jsr	ClrWinBox		;Fenster löschen.

			lda	V402a0			;Keine Dateien im Speicher ?
			beq	:103			;Text ausgeben.

			MoveB	V402a1,a8L		;Zeiger auf Eintrag berechnen.
			ClrB	a8H
			ldx	#a8L
			ldy	#$05
			jsr	DShiftLeft
			AddVW	Memory2,a8

			lda	#$00
			sta	currentMode		;Darstellungsmodus.
			sta	V402a9			;Zähler für Einträge/Anzeige löschen.
			LoadB	V402a10,54		;Y-Pos. für Ausgabe Directory-Eintrag.

::101			CmpB	V402a0,V402a9		;Ende erreicht ?
			beq	:102			;Ja, Ende...
			jsr	DoFile			;Eintrag ausgeben.

			AddVBW	8,V402a10		;Y-Pos für Ausgabezeile korrigieren.

			inc	V402a9			;Zähler für Anzahl Einträge
			lda	V402a9			;erhöhen.
			cmp	#18			;Seite voll ?
			beq	:104			;Ja, Abbruch.

			AddVBW	32,a8			;Zeiger auf nächsten Eintrag.
			jmp	:101			;Nächsten Eintrag ausgeben.

::102			lda	V402a9			;Anzahl ausgegebener Dateien = 0 ?
			bne	:104			;Nein, weiter...

::103			PrintStrgV402c0			;Info: "Keine Dateien..."
::104			lda	V402a1			;Scrollbalken neu berechnen.
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
			MoveB	V402a10,r1H		;Y-Koordinate.
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
::102			cpy	#$07
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

			lda	V402b2			;Anzeigemodus ?
			beq	DirFile_1		;Name, Größe, Datum & Uhrzeit.
			jmp	DirFile_2		;Name, Attribute.

;*** Ausgabe Größe, Datum & Uhrzeit.
:DirFile_1		jsr	InsertSpace		;Leerzeichen einfügen.

			stx	:103 +1
			ldy	#$02
			lda	(a8L),y
			and	#%00001111		;Datei = Unterverzeichnis ?
			cmp	#$06			;Kein SubDir, weiter...
			bne	:102

::101			LoadW	r0,V402d1		;Text "<SubDir>" übertragen.
			jmp	:103

::102			ldy	#$1e			;Dateigröße nach r0L bis r1L.
			lda	(a8L),y
			sta	r0L
			iny
			lda	(a8L),y
			sta	r0H
			ClrB	r1L
			jsr	ZahlToASCII		;Zahl nach ASCII wandeln.
			LoadW	r0,ASCII_Zahl		;ASCII-Zahl übertragen.

::103			ldx	#$ff
			jsr	CopyFileSize

			jsr	Ins2Space		;Zwei Leerzeichen einfügen.

			jsr	InsertDate		;Datum übertragen.
			jmp	FillUpMem		;Eintrag ausgeben.

;*** Dateiname erzeugen.
:InsertName		ldy	#$05
::101			lda	(a8L),y			;Zeichen aus Dateiname einlesen.
			jsr	ConvertChar 		;Zeichen prüfen und
			jsr	InsertASCII		;in Speicher übertragen.
			iny
			cpy	#$15
			bne	:101
			rts

;*** Datum & Zeit ausgeben.
:InsertDate		jsr	GetBinDate		;Datum DOS->C64.

			lda	V402l1+2		;Ausgabe: Tag.
			jsr	HexASCII_a
			lda	#"."
			jsr	InsertASCII

			lda	V402l1+1		;Ausgabe: Monat.
			jsr	HexASCII_a
			lda	#"."
			jsr	InsertASCII

			lda	V402l1+0		;Ausgabe: Jahr.
			jsr	HexASCII_a

			jsr	Ins2Space

			lda	V402l1+3		;Ausgabe: Stunde.
			jsr	HexASCII_a
			lda	#":"
			jsr	InsertASCII

			lda	V402l1+4		;Ausgabe: Minute.
			jmp	HexASCII_a

;*** Datum einlesen.
:GetBinDate		ldy	#$19
::101			lda	(a8L),y
			sta	V402l1-$19,y
			iny
			cpy	#$1e
			bne	:101
			rts

;*** Ausgabe GEOS-Dateityp.
:DirFile_2		cmp	#$01			;Anzeige "GEOS-Dateityp" ?
			bne	DirFile_3		;Nein, weiter...

			ldy	#$02			;Zeiger auf Dateityp setzen.
			lda	(a8L),y			;Dateityp einlesen.
			and	#%00001111
			cmp	#$05			;Typ #5 = 1581-Unterpartition ?
			beq	:101
			cmp	#$06			;Typ #6 = Native-Unterverzeichnis ?
			bne	:102

			LoadW	r0,V402r106		;Anzeige: "Unterverzeichnis"
			jmp	:104			;Zeile ausgeben.

::101			LoadW	r0,V402r105		;Anzeige: "1581 - Partition"
			jmp	:104			;Zeile ausgeben.

;*** Ausgabe des Dateityps für DEL,SEQ,PRG,USR,REL.
::102			ldy	#$18			;GEOS-Datei-Typ einlesen.
			lda	(a8L),y
			beq	:103
			cmp	#LastGEOSType		;Letzter Dateityp überschritten ?
			bcc	:103			;Nein, weiter...
			lda	#LastGEOSType		;Dateityp "GEOS ???"
::103			asl				;Zeiger auf Text für Dateityp.
			tay
			lda	V402q0 +0,y
			sta	r0L
			lda	V402q0 +1,y
			sta	r0H

::104			jsr	CopyTextStrg		;Text für Dateityp kopieren.
			jmp	FillUpMem		;Speicher auffüllen und ausgeben.

;*** Ausgabe CBM-Dateityp, Schreibschutz, Dateistruktur.
:DirFile_3		ldy	#$02
			lda	(a8L),y			;Datei-Typ-Byte einlesen.
			pha				;Byte merken.
			and	#%00001111		;Datei-Typ isolieren.
			asl
			asl
			tay
			LoadB	r0L,4
::12			lda	V402t0,y		;Datei-Typ in Zwischenspeicher.
			jsr	InsertASCII
			iny
			dec	r0L
			bne	:12

			pla
			and	#%01000000		;Schreibschutz-Flag isolieren.
			beq	:13
			lda	#"*"			;Datei ist schreibgeschützt.
			bne	:14
::13			lda	#" "			;Datei ist nicht schreibgeschützt.
::14			jsr	InsertASCII		;Schreibschutz in Zeile kopieren.

			jsr	InsertSpace		;Leerzeichen einfügen.

			ldy	#$17
			lda	(a8L),y			;Dateistruktur-Byte einlesen.
			bne	:15

			lda	#<V402t1		;"Sequentiell"
			ldy	#>V402t1
			bne	:16

::15			lda	#<V402t2		;"GEOS-VLIR"
			ldy	#>V402t2
::16			sta	r0L
			sty	r0H

			jsr	CopyTextStrg		;Text für Dateityp kopieren.
			jmp	FillUpMem		;Speicher auffüllen und ausgeben.

;*** Diskettenkapazitäten ausgeben.
:DiskInfo		LoadB	DisplayMode,$ff
			LoadW	Icon_Tab1a,Icon_04
			LoadW	Icon_Tab1b,View16Files

			jsr	DoInfoBox		;Info "Verzeichnis wird eingelesen..."
			PrintStrgV402j0
			jsr	GetDirHead
			jsr	GetDirInfo		;Disketteninfos einlesen.

			jsr	ClrWinBox

			jsr	UseSystemFont		;Anzahl Dateien ausgeben.
			PrintXY	16,64,V402e0
			jsr	PutInfoEntry
			MoveW	DirFiles,r0
			jsr	PutEntry2

			jsr	UseSystemFont		;Anzahl belegter Blöcke/Verzeichnis.
			PrintXY	16,76,V402e1
			jsr	PutInfoEntry
			MoveW	UsedBlocks,r0
			jsr	PutEntry2

			jsr	UseSystemFont		;Anzahl belegter Blöcke/Diskette.
			PrintXY	16,88,V402e2
			jsr	PutInfoEntry
			PushB	r1H
			jsr	GetCurBAMInfo		;BAM der aktuellen Diskette einlesen.
			sec				;Diskette in ASCII-String wandeln.
			lda	r3L
			sbc	r4L
			sta	r0L
			lda	r3H
			sbc	r4H
			sta	r0H
			PopB	r1H
			jsr	PutEntry2

			jsr	UseSystemFont		;Anzahl freier Sektoren ausgebn.
			PrintXY	16,100,V402e3
			jsr	PutInfoEntry
			PushB	r1H
			jsr	GetCurBAMInfo		;BAM der aktuellen Diskette einlesen.
			MoveW	r4,r0
			PopB	r1H
			jsr	PutEntry2

			jsr	UseSystemFont		;Gesamt-Anzahl Sektoren ausgeben.
			PrintXY	16,112,V402e4
			jsr	PutInfoEntry
			PushB	r1H
			jsr	GetCurBAMInfo		;BAM der aktuellen Diskette einlesen.
			MoveW	r3,r0
			PopB	r1H
			jsr	PutEntry2

;--- Laufwerksgröße ausgeben.
			ldx	curDrive
			lda	driveType-8,x
			and	#%00000111
			cmp	#%00000100
			beq	:0

			cmp	#%00000001		;1541-Laufwerk ?
			bne	:71			; => Nein, weiter...
::41			lda	#<683
			ldx	#>683
			bne	:cbmdisk

::71			cmp	#%00000010		;1571-Laufwerk ?
			bne	:81			; => Nein, weiter...
			lda	#<1366
			ldx	#>1366
			bne	:cbmdisk

::81			lda	#<3200			;1581-Laufwerk.
			ldx	#>3200
::cbmdisk		sta	r0L
			stx	r0H
			jmp	:2

::0			PushB	r1H			;NativeMode-Laufwerk.
			ldx	#$01			;BAM-Sektor mit Track-Anzahl
			stx	r1L			;direkt von Diskette lesen. Nicht alle
			inx				;Treiber stellen den 2ten BAM-Sektor
			stx	r1H			;über dir2Head bereit.
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			lda	diskBlkBuf +8
			sta	r0L
			lda	#$00
			sta	r0H
			ldx	#$06			;Anzahl Tracks x 64Kb.
::1			asl	r0L
			rol	r0H
			dex
			bne	:1
			PopB	r1H

::2			PushW	r0
			jsr	UseSystemFont		;Anzahl Dateien ausgeben.
			PrintXY	16,128,V402e5
			jsr	PutInfoEntry
			PopW	r0
			PushW	r0
			jsr	PutEntry2

			jsr	UseSystemFont		;Anzahl Dateien ausgeben.
			PrintXY	16,140,V402e6
			jsr	PutInfoEntry
			PopW	r0
			lsr	r0H
			ror	r0L
			lsr	r0H
			ror	r0L
			jsr	PutEntry2

			jsr	UseSystemFont
			PrintXY	16,160,V402e9
			jmp	StartDirMenu

;*** Verzeichnisdaten einlesen.
:GetDirInfo		lda	#$00
			sta	UsedBlocks+0		;Anzahl Blocks in Directory löschen.
			sta	UsedBlocks+1
			sta	DirFiles+0		;Anzahl Files in Directory löschen.
			sta	DirFiles+1

			MoveB	curDirHead+0,r1L
			MoveB	curDirHead+1,r1H

			LoadW	r4,diskBlkBuf
::102			jsr	GetBlock		;Verzeichnis-Sektor lesen.
			txa
			beq	:103
			jmp	DiskError

::103			ldy	#$00
::104			lda	diskBlkBuf+2,y		;Datei vorhanden ?
			beq	:105			;Nein, weiter...

			IncWord	DirFiles		;Anzahl Dateien +1.

			clc				;Belegter Speicher addieren.
			lda	diskBlkBuf+30,y
			adc	UsedBlocks+0
			sta	UsedBlocks+0
			lda	diskBlkBuf+31,y
			adc	UsedBlocks+1
			sta	UsedBlocks+1

::105			tya				;Zeiger auf nächste Datei.
			add	32
			tay
			bne	:104
			lda	diskBlkBuf+0
			beq	:106
			sta	r1L
			lda	diskBlkBuf+1
			sta	r1H
			jmp	:102

::106			rts				;Ende.

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
::101			lda	V402f1,y
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
			ldx	V402b2
			beq	EndMove
			dex
			jmp	InitMove

;*** Anzeige ändern.
:MoveRight		bit	DisplayMode
			bmi	EndMove
			ldx	V402b2
			cpx	#$02
			beq	EndMove
			inx
:InitMove		stx	V402b2

;*** Seite anzeigen und auf Maustaste warten.
:NPageAndMse		jsr	Show16Files
			NoMseKey
:EndMove		rts

;*** NATIVE-Verzeichnis öffnen.
:SlctSubDir		php
			sei
			lda	mouseYPos		;Zeiger auf aktuellen Eintrag
			lsr				;berechnen.
			lsr
			lsr
			pha
			sub	$06
			adda	V402a1
			sta	a8L
			ClrB	a8H
			ldx	#a8L
			ldy	#$05
			jsr	DShiftLeft
			AddVW	Memory2,a8

			pla
			tax
			plp

			ldy	#$02
			lda	(a8L),y
			and	#%00001111
			cmp	#$06
			beq	:102
			NoMseKey
			jmp	StartFile

::102			txa
			asl
			asl
			asl
			sta	r2L
			add	$07
			sta	r2H
			jsr	InvertRectangle

			NoMseKey

;*** Neues CMD-Verzeichnis öffnen.
:GetNewDir		ldy	#$ff
			sty	DirType

			ldy	#$03			;Verzeichniseintrag in Zwischen-
			lda	(a8L),y			;speicher kopieren.
			sta	r1L
			iny
			lda	(a8L),y			;speicher kopieren.
			sta	r1H
			jsr	New_CMD_SubD
			txa
			beq	OpenNewDir
			jmp	DiskError

;*** Zum Hauptverzeichnis.
:GoRootDir		ldy	curDrive		;Aktuelles Laufwerk einlesen.
			lda	DriveModes-8,y		;Laufwerkstyp einloesen.
			and	#%00100000		;NativeMode?
			bne	:101
			rts

::101			jsr	InvertRectangle
:SetRoot		jsr	New_CMD_Root
			txa
			beq	:101
			jmp	DiskError

::101			sta	DirType
:OpenNewDir		jsr	CBM_GetDskNam
			jsr	Do1stInit		;Zeiger auf ersten Verzeichnis-Sektor.
			jsr	Read240Dir		;128 Dateien einlesen.
			jmp	Bildschirm_b		;Bildschirm aufbauen.

;*** Ein Verzeichnis zurück.
:GoBack1Dir		ldy	curDrive		;Aktuelles Laufwerk einlesen.
			lda	DriveModes-8,y		;Laufwerkstyp einloesen.
			and	#%00100000		;NativeMode?
			beq	:101
			bit	DirType			;Hauptverzeichnis ?
			bmi	:102			;Nein, weiter...
::101			rts

::102			jsr	InvertRectangle

:GoBack1Dir_a		jsr	GetDirHead
			txa
			bne	:104

			lda	curDirHead+34
			ldx	curDirHead+35
			cmp	#$01
			bne	:103
			cpx	#$01
			beq	SetRoot
::103			sta	r1L
			stx	r1H
			jsr	New_CMD_SubD
			txa
			beq	OpenNewDir
::104			jmp	DiskError

;*** Datei öffnen.
:StartFile		ldy	#$18
			lda	(a8L),y
			cmp	#APPLICATION
			beq	:101
			cmp	#APPL_DATA
			beq	:101
			cmp	#AUTO_EXEC
			beq	:101
			cmp	#DESK_ACC
			beq	:101

			cmp	#$00			;BASIC-Datei?
			bne	:100			; => Nein, Ende...
			ldy	#$02
			lda	(a8L),y
			and	#%00001111
			cmp	#$02			;CBM-Typ PROGRAMM?
			bne	:100			; => Nein, Ende...

			bit	c128Flag		;C128?
			bpl	:110			; => Nein, weiter...

			ldx	curDrive		;Bei RAM-Laufwerk kein laden
			lda	driveType -8,x		;mit GEOS128/GeoDOS möglich.
			bpl	:110			; => Kein RAM-Laufwerk, weiter.
			lda	curDrvMode		;CMD-Laufwerk/RAMLink?
			bpl	:100			; => Ja, BASIC-laden möglich.

::110			jmp	ExitBAppl		;BASIC-Datei öffnen.

::100			NoMseKey
			rts

::101			jsr	ChkFlag_40_80
			txa
			bne	:100

			ldy	#$02
			ldx	#$00
::102			lda	(a8L),y
			sta	APP_VAR   ,x
			iny
			inx
			cpx	#$1e
			bne	:102

			lda	curDrive
			sta	APP_VAR +31

			ldy	#$03
			ldx	#$00
::103			lda	APP_VAR   ,y
			cmp	#$a0
			beq	:104
			sta	V402g0 +17,x
			iny
			inx
			cpx	#$10
			bne	:103
::104			lda	#$22
			sta	V402g0 +17,x
			lda	#$00
			sta	V402g0 +18,x

			jsr	ClrScreen		;Fenster aufbauen.

			DB_UsrBoxV402g0			;"Datei öffnen ?"
			CmpBI	sysDBData,YES		;"Ja" gewählt ?
			beq	:105
			jmp	Bildschirm_a

::105			ldx	#$ff
			jmp	vAppl_Doks

;*** C128: 40/80Z-Modus testen.
:ChkFlag_40_80		lda	a8L
			clc
			adc	#$02
			sta	r9L
			lda	a8H
			adc	#$00
			sta	r9H
			jsr	GetFHdrInfo
			txa				;Info-Block gefunden ?
			bne	:2			; => Nein, BASIC-File, Abbruch...

			lda	fileHeader+$60		;40/80Z-Flag einlesen.
			ldx	c128Flag		;C64/C128?
			bne	:1			; => C128, Weiter...
;--- Ergänzung: 15.03.19/M.Kanet
;Unter GEOS gibt es kein Flag für "Nur GEOS128". Eine Anwendung die für den
;40+80Z-Modus entwickelt wurde kann auch für GEOS64 existieren. Es kannn aber
;auch eine reine GEOS128-Anwendung sein.
;Unter GEOS64 werden daher GEOS64, 40ZOnly und 40/80Z akzeptiert.
			cmp	#$c0			;Nur 80Z?
			beq	:4			; => GEOS128-App auf GEOS64... Abbruch.
			bne	:3			;Evtl. GEOS64 App... weiter...

;--- Ergänzung: 15.03.19/M.Kanet
;Unter GEOS128 werden 40ZOnly, 80ZOnly und 40/80Z akzeptiert.
::1			cmp	#%00000000		;40/80Z-Flag einlesen.
			beq	:3			;Nur 40Z -> weiter...
			cmp	#%01000000		;40/80Z ?
			beq	:3			;Ja -> weiter...
			cmp	#%10000000		;Nur GEOS64Z ?
			beq	:4			;Ja -> Abbruch...
			cmp	#%11000000		;Nur 80Z ?
			beq	:3			;Ja -> weiter...
::4			ldx	#INCOMPATIBLE		; -> Nur GEOS64, Abbruch.
			b $2c
::3			ldx	#$00
::2			rts

;*** BASIC-Programm starten.
:ExitBAppl		ldy	#$05			;Dateiname in Zwischenspeicher
			ldx	#$00			;und in Dialogbox schreiben.
::loop1			lda	(a8L),y
			cmp	#$a0
			beq	:exit_dskerr_loop1
			sta	AppFName,x
			sta	V402v0 +17,x
			iny
			inx
			cpx	#$10
			bne	:loop1
::exit_dskerr_loop1	lda	#$22
			sta	V402v0 +17,x
			lda	#$00
			sta	AppFName,x
			inx
			sta	V402v0 +17,x

			jsr	ClrScreen		;Fenster aufbauen.

			DB_UsrBoxV402v0			;"BASIC-Datei öffnen ?"
			CmpBI	sysDBData,YES		;"Ja" gewählt ?
			beq	:do_load
			jmp	Bildschirm_a		;Nein, Verzeichnis wieder anzeigen.

::exit_dskerr		jmp	DiskError		;Diskfehler anzeigen.

::do_load		LoadW	r6,AppFName
			jsr	FindFile		;Datei suchen.
			txa				;Fehler?
			bne	:exit_dskerr		; => Ja, Abbruch...

			bit	c128Flag		;C128?
			bmi	:load_c128		; => Ja, weiter...

;--- Ladeadresse prüfen.
			lda	dirEntryBuf+1		;Zeiger auf ersten Datenblock.
			sta	r1L
			lda	dirEntryBuf+2
			sta	r1H
			LoadW	r4,diskBlkBuf		;Zeiger auf Zwischenspeicher.
			jsr	GetBlock		;Ersten Datenblock einlesen.
			txa				;Fehler?
			bne	:exit_dskerr		; => Ja, Abbruch...

			lda	diskBlkBuf+2		;Laeadresse = $0801?
			cmp	#$01
			bne	:ask_load_abs		; => Nein, Absolut laden?
			lda	diskBlkBuf+3
			cmp	#$08
			beq	:load_std		; => Ja, weiter...

::ask_load_abs		ldx	curDrive		;Bei RAM-Laufwerk kein absolutes
			lda	driveType -8,x		;laden mit ",dev,1" möglich.
			bpl	:0			; => Kein RAM-Laufwerk, weiter.
			lda	curDrvMode		;CMD-Laufwerk/RAMLink?
			bmi	:0			; => Ja, BASIC-laden möglich.

			DB_UsrBoxV402v2			;Fragen ob von RAM normal geladen
			lda	sysDBData		;werden soll...
			cmp	#YES			;"Ja" ?
			beq	:load_std		; => Normal laden.
			bne	:cancel			;Abbruch.

::0			DB_UsrBoxV402v1			;Fragen ob Absolut geladen
			lda	sysDBData		;werden soll...
			cmp	#NO
			beq	:load_std		; => Nein, normal laden/starten.
			cmp	#YES
			beq	:load_abs		; => Ja, absolut laden.
::cancel		jmp	Bildschirm_a		;Nein, Verzeichnis wieder anzeigen.

;--- C128: Programm laden/starten.
::load_c128		jmp	C128BootFile

;--- Programm normal laden/starten.
::load_std		LoadW	r0,RunBASICcom		;"RUN"-Befehl.
			LoadW	r5,dirEntryBuf		;Zeiger auf Verzeichnis-Eintrag.
			LoadW	r7,$0801		;Ladeadresse.

			jmp	ToBasic			;Nach BASIC beenden.

;--- Programm absolut laden/manuell starten.
::load_abs		LoadW	r1,LoadBASIC64

			ldx	#$00
			ldy	#$05			;Dateiname kopieren.
::2			lda	AppFName,x		;Ende erreicht?
			beq	:3
			sta	(r1L),y			;Ende Dateiname suchen.
			iny
			inx
			cpx	#$10
			bne	:2

::3			lda	#$22			;",dev,1" an den Dateinamen
			sta	(r1L),y			;anhängen.
			iny
			lda	#$2c			;","
			sta	(r1L),y
			iny

			ldx	curDrive		;Laufwerk 8,9,10,11 in
			lda	driveAdr1 -8,x		;Befehl eintragen.
			beq	:4
			sta	(r1L),y
			iny
::4			lda	driveAdr2 -8,x
			sta	(r1L),y
			iny

			lda	#$2c			;","
			sta	(r1L),y
			iny
			lda	#"1"			;"1"
			sta	(r1L),y
			iny
			lda	#NULL			;Befehlsende.
			sta	(r1L),y

;*** Nach BASIC verlassen und Befehl ausführen.
;    Übergabe: r0 = Zeiger auf Befehl.
			LoadW	r0,LoadBASIC64		;"LOAD"-Befehl.

			lda	#$00			;Kein Programm laden.
			sta	r5L
			sta	r5H

			sta	$0800			;Kein Programm starten.
			sta	$0801
			sta	$0802
			sta	$0803
			LoadW	r7,$0803
			jmp	ToBasic			;Nach BASIC beenden.

:AppFName		s 17

:RunBASICcom		b "RUN",NULL

:LoadBASIC64		b "LOAD",$22
			s 17
			b $22,",8,1",NULL

:RunBASIC128		b "RUN",$22
			s 17
			b $22,",8,1",NULL

:driveAdr1		b NULL,NULL,"1","1"
:driveAdr2		b "8" ,"9" ,"0","1"

;*** Frage: "BASIC-Datei starten?
if Sprache = Deutsch
:V402v0			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Datei: ",$22,"1234567890123456",$22,NULL
::102			b        "Die BASIC-Datei starten ?",NULL
endif
if Sprache = Englisch
:V402v0			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"File : ",$22,"1234567890123456",$22,NULL
::102			b        "Run BASIC file ?",NULL
endif

;*** Frage: "BASIC-Datei absolut laden?
if Sprache = Deutsch
:V402v1			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Keine Standard-Ladeadresse.",NULL
::102			b        "Absolut mit ,dev,1 laden ?",NULL
endif
if Sprache = Englisch
:V402v1			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"No standard load adress.",NULL
::102			b        "Load absolute with ,dev,1 ?",NULL
endif

;*** Frage: "BASIC-Datei absolut laden?
if Sprache = Deutsch
:V402v2			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"RAM-Laufwerk: Absolutes laden",NULL
::102			b        "nicht möglich. Normal laden ?",NULL
endif
if Sprache = Englisch
:V402v2			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Absolute loading from RAM-drive",NULL
::102			b        "not supported. Load normal ?",NULL
endif

;*** Routine zum starten eines BASIC-Files.
;    Übergabe: r15 = Dateiname.
:C128BootFile		LoadW	r1,RunBASIC128

			ldx	#$00
			ldy	#$04			;Dateiname kopieren.
::2			lda	AppFName,x		;Ende erreicht?
			beq	:3
			sta	(r1L),y			;Ende Dateiname suchen.
			iny
			inx
			cpx	#$10
			bne	:2

::3			lda	#$22			;",dev,1" an den Dateinamen
			sta	(r1L),y			;anhängen.
			iny
			lda	#$2c			;","
			sta	(r1L),y
			iny
			lda	#"U"			;","
			sta	(r1L),y
			iny

			ldx	curDrive		;Laufwerk 8,9,10,11 in
			lda	driveAdr1 -8,x		;Befehl eintragen.
			beq	:4
			sta	(r1L),y
			iny
::4			lda	driveAdr2 -8,x
			sta	(r1L),y
			iny

			lda	#NULL			;Befehlsende.
			sta	(r1L),y

;*** Nach BASIC verlassen und Befehl ausführen.
;    Übergabe: r0 = Zeiger auf Befehl.
			LoadW	r0,SCREEN_BASE
			LoadW	r1,RunBASIC128		;"RUN"-Befehl.

			ldy	#$00
::1			lda	(r1L),y
			sta	(r0L),y
			beq	:5
			iny
			bne	:1

::5			lda	#$00			;Kein Programm laden.
			sta	r5L
			sta	r5H

			sta	$1c00			;Kein Programm starten.
			sta	$1c01
			sta	$1c02
			sta	$1c03
			LoadW	r7,$1c03
			jmp	ToBasic			;Nach BASIC beenden.

;*** Balken verschieben.
:MoveBar		bit	DisplayMode
			bmi	:101
			lda	V402a0
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
			LoadW	r0,V402f2
			jsr	InitRam
			jmp	Show16Files		;Position anzeigen.

::103			cmp	#$02			;Maus nach oben ?
			beq	:104			;Ja, auswerten.
			cmp	#$06			;Maus nach unten ?
			beq	:105			;Ja, auswerten.
			jmp	:101			;Keine Bewegung, Schleife...

::104			jsr	LastFile_a
			bcs	:101			;Geht nicht, Abbruch.
			dec	V402a1			;Zeiger auf letzte Datei.
			jmp	:106			;Neue Position anzeigen.

::105			jsr	NextFile_a		;Eine Datei vorwärts.
			bcs	:101			;Geht nicht, Abbruch.
			inc	V402a1			;Zeiger auf nächste Datei.
::106			lda	V402a1			;Tabellenposition einlesen und
			jsr	SetPosBalken		;Anzeigebalken setzen und
			jsr	SetRelMouse		;Maus entsprechend verschieben.
			jmp	:101			;Maus weiter auswerten.

;*** Zum Anfang der Tabelle.
:TopFile		lda	V402a1
			beq	:101
			ClrB	V402a1
			jmp	NPageAndMse
::101			rts

;*** Zum Ende der Tabelle.
:EndFile		lda	V402a0
			sub	18
			bcc	:101
			sta	V402a1+0
			jmp	NPageAndMse
::101			rts

;*** Eine Seite vor.
:NextPage		lda	V402a1
			add	36
			bcs	:101
			cmp	V402a0
			bcc	:102
::101			jmp	EndFile

::102			sub	18
			sta	V402a1
			jmp	NPageAndMse

;*** Eine Seite zurück.
:LastPage		lda	V402a1
			sub	18
			bcs	:101
			jmp	TopFile

::101			sta	V402a1
			jmp	NPageAndMse

;*** Tabelle bewegen.
:NextFile		jsr	InvertRectangle

::101			jsr	NextFile_a		;Scrolling möglich ?
			bcs	:102			;Nein, Ende...
			jsr	ScrollDown		;Eine Zeile scrollen.

			lda	V402a1			;Balken neu positionieren.
			jsr	SetPosBalken

			jsr	TestMouse		;Maustaste noch gedrückt ?
			bcs	:101			;Weiterscrollen.

::102			lda	#$04
			jmp	EndSlctIcon

:NextFile_a		lda	DisplayMode
			bne	:101
			lda	V402a0
			cmp	#18
			bcc	:101
			lda	V402a1
			add	18
			cmp	V402a0
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
::103			lda	#2
::104			pha
			ldy	#$00			;18 Grafikzeilen a 296 Byte.
::105			lda	(r0L),y			;verschieben.
			sta	(r1L),y
			iny
			cpy	#152
			bne	:105

			AddVBW	152,r0
			AddVBW	152,r1

			pla
			sub	1
			bne	:104

			AddVBW	16,r0
			AddVBW	16,r1

			dex
			bne	:103
			plp

			inc	V402a1
			MoveB	V402a1,a8L
			ClrB	a8H
			ldx	#a8L
			ldy	#$05
			jsr	DShiftLeft
			AddVW	Memory2+17*32,a8
			LoadB	V402a10,190		;Y-Pos. für Ausgabe Directory-Eintrag.
			jmp	DoFile			;Eintrag ausgeben.

;*** Tabelle Target bewegen.
:LastFile		jsr	InvertRectangle

::101			jsr	LastFile_a
			bcs	:102
			jsr	ScrollUp		;Eine Zeile scrollen.

			lda	V402a1			;Balken neu positionieren.
			jsr	SetPosBalken

			jsr	TestMouse		;Maustaste noch gedrückt ?
			bcs	:101			;Weiterscrollen.

::102			lda	#$03
			jmp	EndSlctIcon

:LastFile_a		lda	DisplayMode
			bne	:101
			lda	V402a0
			cmp	#18
			bcc	:101
			lda	V402a1
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
::102			lda	#$02
::103			pha
			ldy	#151			;18 Grafikzeilen a 296 Byte.
::104			lda	(r0L),y			;verschieben.
			sta	(r1L),y
			dey
			cpy	#255
			bne	:104

			SubVW	152,r0
			SubVW	152,r1

			pla
			sub	1
			bne	:103

			SubVW	16,r0
			SubVW	16,r1

			dex
			bne	:102
			plp

			dec	V402a1
			MoveB	V402a1,a8
			ClrB	a8H
			ldx	#a8L
			ldy	#$05
			jsr	DShiftLeft
			AddVW	Memory2,a8
			LoadB	V402a10,54		;Y-Pos. für Ausgabe Directory-Eintrag.
			jmp	DoFile			;Eintrag ausgeben.

;*** Modus für sortieren wählen.
:SetSortMode		jsr	ClrScreen

			lda	#<V402u0
			ldx	#>V402u0
			jsr	SelectBox

			lda	r13L
			beq	:101
			jmp	Bildschirm_a

::101			lda	r13H
			asl
			tax
			lda	V402u3+0,x
			sta	V402u4+1
			lda	V402u3+1,x
			sta	V402u4+2

;*** Dateien im Speicher sortieren.
:SortDir		ldx	V402a0			;Mehr als 1 Datei ?
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

::103			jsr	V402u4
			CmpW	r13,r15
			beq	:108
			SubVW	32,r13
			jmp	:103

::108			AddVBW	32,r15
			CmpW	r14,r15			;Alle Dateien sortiert ?
			bne	:102			;Nein, weiter...

			ClrB	V402a1			;Dateien neu anzeigen.
			jmp	Bildschirm_a

;*** Einträge vertauschen.
:SwapEntry		ldy	#$1f			;Einträge tauschen.
::101			lda	(r13L),y
			tax
			lda	(r15L),y
			sta	(r13L),y
			txa
			sta	(r15L),y
			dey
			bpl	:101
			rts

;*** Modus: Name.
:SortName		ldy	#$05
			lda	(r15L),y
			jsr	:11
			sta	:101 +1
			lda	(r13L),y
			jsr	:11
::101			cmp	#$ff
			bcc	:106
			beq	:102
			bcs	:109

::102			lda	(r13L),y
			cmp	(r15L),y
			beq	:108
			bcc	:103
			jmp	SwapEntry
::103			rts

::104			ldy	#$05			;Zeichen vergleichen.
::105			lda	(r13L),y
			cmp	(r15L),y
			bcs	:107
::106			jmp	SwapEntry

::107			bne	:109
::108			iny				;Weitervergleichen bis
			cpy	#$15			;alle 11 Zeichen geprüft.
			bne	:105
::109			rts

::11			cmp	#$61
			bcc	:13
			cmp	#$7e
			bcs	:13
::12			sub	$20
::13			rts

;*** Modus: Größe.
:SortSize		ldy	#$1f
			lda	(r13L),y
			cmp	(r15L),y
			bcs	:102
::101			jmp	SwapEntry
::102			bne	:103
			dey
			lda	(r13L),y
			cmp	(r15L),y
			bcc	:101
			bne	:103
			jmp	SortName
::103			rts

;*** Modus: Datum/Aufwärts.
:SortDateUp		jsr	ConvertDate		;yy/mm/dd nach yyyy/mm/dd wandeln.

			ldx	#$00
::101			lda	dateFile_r13,x
			cmp	dateFile_r15,x
			bcs	:103
::102			jmp	SwapEntry		;Eintrag tauschen/sortieren.
::103			bne	:104
			inx
			cpx	#$06
			bcc	:101
			jmp	SortName		;Datum gleich, nach Name sortieren.
::104			rts

;*** Modus: Datum/Abwärts.
:SortDateDown		jsr	ConvertDate		;yy/mm/dd nach yyyy/mm/dd wandeln.

			ldx	#$00
::101			lda	dateFile_r13,x
			cmp	dateFile_r15,x
			bcs	:103
::102			rts
::103			bne	:104
			inx
			cpx	#$06
			bcc	:101
			jmp	SortName		;Datum gleich, nach Name sortieren.
::104			jmp	SwapEntry		;Eintrag tauschen/sortieren.

;*** Datum von yy/mm/dd nach yyyy/mm/dd konvertieren.
:ConvertDate		ldy	#$19
			ldx	#$01
::1			lda	(r15L),y
			sta	dateFile_r15,x
			lda	(r13L),y
			sta	dateFile_r13,x
			iny
			inx
			cpx	#$06
			bcc	:1

			lda	dateFile_r15 +1
			jsr	:century
			stx	dateFile_r15 +0
			lda	dateFile_r13 +1
			jsr	:century
			stx	dateFile_r13 +0
			rts

;--- Jahrhundert ermitteln.
::century		ldx	#19
			cmp	#80			;Jahr >= 80 => 1980.
			bcs	:99
			ldx	#20			;Jahr <  80 => 2000 - 2079.
::99			rts

:dateFile_r15		s 07
:dateFile_r13		s 07

;*** Modus: Typ.
:SortTyp		ldy	#$02
			lda	(r15L),y
			and	#%00001111
			sta	:101 +1
			lda	(r13L),y
			and	#%00001111
::101			cmp	#$ff
			beq	:103
			bcs	:102
			jmp	SwapEntry
::103			jmp	SortName
::102			rts

;*** Modus: GEOS-Dateityp.
if FALSE
;--- V1: Nur nach GEOS-Dateityp sortieren.
:SortGEOS		ldy	#$18
			lda	(r13L),y
			cmp	(r15L),y
			bcs	:101
			jmp	SwapEntry		;Eintrag tauschen/sortieren.
::101			rts
endif

;--- V2: Nach GEOS/Priorität sortieren.
;Anwendungen zuerst, danach Dokumente.
;Systemdateien am Ende.
:SortGEOS		ldy	#$02
			lda	(r15L),y		;CBM-Dateityp einlesen.
			and	#%00001111
			cmp	#$06			;Typ = Verzeichnis?
			bne	:11			; => Nein, weiter...
			lda	#$ff			;Verzeichnisse an Ende sortieren.
			bne	:12
::11			ldy	#$18
			lda	(r15L),y		;GEOS-Dateityp einlesen und
			jsr	:get_priority		;in GEOS-Priorität konvertieren.
::12			sta	:30 +1

			ldy	#$02
			lda	(r13L),y		;CBM-Dateityp einlesen.
			and	#%00001111
			cmp	#$06			;Typ = Verzeichnis?
			bne	:21			; => Nein, weiter...
			lda	#$ff			;Verzeichnisse an Ende sortieren.
			bne	:30
::21			ldy	#$18
			lda	(r13L),y		;GEOS-Dateityp einlesen und
			jsr	:get_priority		;in GEOS-Priorität konvertieren.

::30			cmp	#$ff
			beq	:31
			bcs	:exit
			jmp	SwapEntry		;Eintrag tauschen/sortieren.
::31			jmp	SortName		;GEOS gleich, nach Name sortieren.

;--- GEOS-Datei nach Priorität sortieren.
::get_priority		cmp	#$10
			bcs	:exit
			tax
			lda	GEOS_Priority,x
::exit			rts

;*** Konvertierungstabelle GEOS-Dateityp.
:GEOS_Priority		b $03 ;$00 = nicht GEOS.
			b $04 ;$01 = BASIC-Programm.
			b $05 ;$02 = Assembler-Programm.
			b $07 ;$03 = Datenfile.
			b $0e ;$04 = Systemdatei.
			b $02 ;$05 = Hilfsprogramm.
			b $00 ;$06 = Anwendung.
			b $06 ;$07 = Dokument.
			b $08 ;$08 = Zeichensatz.
			b $09 ;$09 = Druckertreiber.
			b $0a ;$0a = Eingabetreiber.
			b $0c ;$0b = Laufwerkstreiber.
			b $0d ;$0c = Startprogramm.
			b $0f ;$0d = Temporär.
			b $01 ;$0e = Selbstausführend.
			b $0b ;$0f = Eingabetreiber 128.
			b $10 ;$10 = Unbekannt.

;*** Name der Hilfedatei.
:HelpFileName		b "09,GDH_CBM/Disk",NULL

;*** Variablen.
:UsedBlocks		w $0000				;Anzahl belegter Blocks
:DirFiles		w $0000				;Anzahl Files

:DirType		b $00				;$00 = Root.
							;$FF = SubDir.
:DisplayMode		b $00				;$00 = Anzeige Dateien.
							;$FF = Anzeige Verzeichnis.
:Display240		b $00				;$00 = Kein Datei-Icon.
							;$FF = Datei-Icon anzeigen.
:DrvOnScrn		s $04				;Laufwerke auf Bildschirm.
:DskDatMem		s 11				;Speicher für Diskettendaten.
:V402l1			s $05				;Speicher für Datum.

:V402a0			b $00				;Zähler für Dateien im RAM.
:V402a1			b $00				;Zeiger auf aktuellen Eintrag im RAM.
:V402a3			b $00,$00			;Start-Sektor Unterverzeichnis.
:V402a4			b $00,$00			;Aktueller Sektor Verzeichnis.
:V402a7			b $00				;Zeiger auf Eintrag im Sektor.
:V402a8			w $0000				;Adresse Eintrag in Verzeichnis-Sektor.
:V402a9			b $00				;Anzahl Einträge auf Seite.
:V402a10		b $00				;Y-Koordinate.

:V402b0			b $00				;$00 = Es folgen weitere Dateien.
							;$FF = Verzeichnisende erreicht.
:V402b1			b $00				;$00 = Weniger als ":MaxFiles" Dateien.
							;$FF = Mehr als ":MaxFiles" Dateien.
:V402b2			b $00				;$00 = Größe, Datum, Zeit anzeigen.
							;$01 = Typ anzeigen.

if Sprache = Deutsch
:V402c0			b PLAINTEXT
			b GOTOXY
			w 32
			b 100
			b "Verzeichnis ist leer!"
			b NULL
:V402c1			b " Block(s) verfügbar",NULL
:V402c2			b " Datei(en) im Speicher",NULL
:V402c3			b "   *** Ende ***",NULL

:V402d1			b "<DIR>",NULL
:V402d2			b PLAINTEXT
			b GOTOXY
			w 32
			b 100
			b "Verzeichnis ist leer!"
			b NULL

:V402e0			b PLAINTEXT,BOLDON,"Dateien im Verzeichnis",NULL
:V402e1			b PLAINTEXT,BOLDON,"Blocks im Verzeichnis belegt",NULL
:V402e2			b PLAINTEXT,BOLDON,"Blocks auf Diskette belegt",NULL
:V402e3			b PLAINTEXT,BOLDON,"Blocks auf Diskette verfügbar",NULL
:V402e4			b PLAINTEXT,BOLDON,"Blocks auf Diskette gesamt",NULL
:V402e5			b PLAINTEXT,BOLDON,"Größe der Diskette in Blocks",NULL
:V402e6			b PLAINTEXT,BOLDON,"Größe der Diskette in KByte",NULL
:V402e9			b PLAINTEXT,BOLDON
			b "1 Block auf Disk entspricht 254 Datenbytes",NULL
endif

if Sprache = Englisch
:V402c0			b PLAINTEXT
			b GOTOXY
			w 32
			b 100
			b "Directory is empty!"
			b NULL
:V402c1			b " Block(s) available",NULL
:V402c2			b " File(s) in memory",NULL
:V402c3			b "   *** End ***",NULL

:V402d1			b "<DIR>",NULL
:V402d2			b PLAINTEXT
			b GOTOXY
			w 32
			b 100
			b "Directory is empty!"
			b NULL

:V402e0			b PLAINTEXT,BOLDON,"Files in directory",NULL
:V402e1			b PLAINTEXT,BOLDON,"Blocks used in directory",NULL
:V402e2			b PLAINTEXT,BOLDON,"Blocks used on disk",NULL
:V402e3			b PLAINTEXT,BOLDON,"Blocks available on disk",NULL
:V402e4			b PLAINTEXT,BOLDON,"Blocks available",NULL
:V402e5			b PLAINTEXT,BOLDON,"Total disk size in Blocks",NULL
:V402e6			b PLAINTEXT,BOLDON,"Total disk size in KByte",NULL
:V402e9			b PLAINTEXT,BOLDON
			b "Each block on disk contains 254 data bytes",NULL
endif

;*** Daten für Scroll-Balken.
:V402f0			b $27,$38,$80,$ff,$12,$00

;*** Daten für Mausabfrage.
:V402f1			b $28,$2f
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
:V402f2			w mouseTop
			b $06
			b $00,$c7
			w $0000,$013f
			w $0000

if Sprache = Deutsch
;*** Fehler: "Keine Tabellen auf Start-Diskette!"
:V402g0			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Datei: ",$22,"1234567890123456",$22,NULL
::102			b        "Die gewählte Datei öffnen ?",NULL
endif

if Sprache = Englisch
;*** Fehler: "Keine Tabellen auf Start-Diskette!"
:V402g0			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"File : ",$22,"1234567890123456",$22,NULL
::102			b        "Open selected file ?",NULL
endif

if Sprache = Deutsch
;*** Info: "Verzeichnis wird eingelesen."
:V402j0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Diskettenverzeichnis"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "wird eingelesen..."
			b NULL

;*** Texte für Verzeichnis.
:V402q0			w V402r0 ,V402r1 ,V402r2 ,V402r3 ,V402r4
			w V402r5 ,V402r6 ,V402r7 ,V402r8 ,V402r9
			w V402r10,V402r11,V402r12,V402r13,V402r14
			w V402r15,V402r99,V402r17,V402r99,V402r99
			w V402r99,V402r21,V402r22,V402r99

:V402q1			w V402s0 ,V402s1 ,V402s2 ,V402s3

:V402r0			b "Nicht GEOS",NULL
:V402r1			b "BASIC",NULL
:V402r2			b "Assembler",NULL
:V402r3			b "Datenfile",NULL
:V402r4			b "System-Datei",NULL
:V402r5			b "DeskAccessory",NULL
:V402r6			b "Anwendung",NULL
:V402r7			b "Dokument",NULL
:V402r8			b "Zeichensatz",NULL
:V402r9			b "Druckertreiber",NULL
:V402r10		b "Eingabetreiber",NULL
:V402r11		b "Laufwerkstreiber",NULL
:V402r12		b "Startprogramm",NULL
:V402r13		b "Temporär",NULL
:V402r14		b "Selbstausführend",NULL
:V402r15		b "Eingabetreiber 128",NULL
:V402r17		b "gateWay-Dokument",NULL
:V402r21		b "geoShell-Kommando",NULL
:V402r22		b "geoFAX Druckertreiber",NULL
:V402r99		b "GEOS ???",NULL

:V402r105		b "< 1581 - Partition >",NULL
:V402r106		b "< Unterverzeichnis >",NULL

:V402s0			b "GEOS 40 Zeichen",NULL
:V402s1			b "GEOS 40 & 80 Zeichen",NULL
:V402s2			b "GEOS 64",NULL
:V402s3			b "GEOS 128, 80 Zeichen",NULL

:V402t0			b "DEL SEQ PRG USR REL CBM DIR ??? "
:V402t1			b "Sequentiell",NULL
:V402t2			b "GEOS-VLIR",NULL

;*** Auswahlbox für Sortiermodus.
:V402u0			b $00
			b $00
			b $00
			b $10
			b $00
			w V402u1
			w V402u2

:V402u1			b PLAINTEXT,"Dateien sortieren",NULL
:V402u2			b "Dateiname       "
			b "Dateigröße      "
			b "Datum aufwärts  "
			b "Datum abwärts   "
			b "Dateityp        "
			b "GEOS-Dateityp   "
			b NULL

:V402u3			w SortName  , SortSize
			w SortDateUp, SortDateDown
			w SortTyp   , SortGEOS

:V402u4			jmp	$ffff
endif

if Sprache = Englisch
;*** Info: "Verzeichnis wird eingelesen."
:V402j0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Load current"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "disk-directory..."
			b NULL

;*** Texte für Verzeichnis.
:V402q0			w V402r0 ,V402r1 ,V402r2 ,V402r3 ,V402r4
			w V402r5 ,V402r6 ,V402r7 ,V402r8 ,V402r9
			w V402r10,V402r11,V402r12,V402r13,V402r14
			w V402r15,V402r99,V402r17,V402r99,V402r99
			w V402r99,V402r21,V402r22,V402r99

:V402q1			w V402s0 ,V402s1 ,V402s2 ,V402s3

:V402r0			b "Not GEOS",NULL
:V402r1			b "BASIC",NULL
:V402r2			b "Assembler",NULL
:V402r3			b "Datafile",NULL
:V402r4			b "Systemfile",NULL
:V402r5			b "DeskAccessory",NULL
:V402r6			b "Application",NULL
:V402r7			b "Document",NULL
:V402r8			b "Font",NULL
:V402r9			b "Printerdriver",NULL
:V402r10		b "Inputdriver",NULL
:V402r11		b "Diskdriver",NULL
:V402r12		b "Bootfile",NULL
:V402r13		b "Temporary",NULL
:V402r14		b "Autoexecute",NULL
:V402r15		b "Input128 128",NULL
:V402r17		b "gateWay-document",NULL
:V402r21		b "geoShell-command",NULL
:V402r22		b "geoFAX printerdriver",NULL
:V402r99		b "GEOS ???",NULL

:V402r105		b "< 1581 - Partition >",NULL
:V402r106		b "<   Subdirectory   >",NULL

:V402s0			b "GEOS 40 columns",NULL
:V402s1			b "GEOS 40 & 80 columns",NULL
:V402s2			b "GEOS 64",NULL
:V402s3			b "GEOS 128, 80 columns",NULL

:V402t0			b "DEL SEQ PRG USR REL CBM DIR ??? "
:V402t1			b "Sequential",NULL
:V402t2			b "GEOS-VLIR",NULL

;*** Auswahlbox für Sortiermodus.
:V402u0			b $00
			b $00
			b $00
			b $10
			b $00
			w V402u1
			w V402u2

:V402u1			b PLAINTEXT,"Sort files",NULL
:V402u2			b "Filename        "
			b "Filesize        "
			b "Date (old first)"
			b "Date (new first)"
			b "Filetype        "
			b "GEOS-filetype   "
			b NULL

:V402u3			w SortName  , SortSize
			w SortDateUp, SortDateDown
			w SortTyp   , SortGEOS

:V402u4			jmp	$ffff
endif

;*** Icon-Tabelle
:Icon_Tab1		b	3
			w	$0000
			b	$00

			w	Icon_00
			b	$00,$08,$05,$18
			w	L402ExitGD

:Icon_Tab1a		w	Icon_03
			b	$05,$08,$05,$18
:Icon_Tab1b		w	DiskInfo

			w	Icon_05
			b	$0a,$08,$05,$18
			w	vC_PrnCurDir

:Icon_Tab1c		s	5 * 8

:Icon_Tab1d		w	Icon_10
			b	$16,$08,$05,$18
			w	SetSortMode

			w	Icon_07
			b	$25,$08,$05,$18
			w	L402OtherPart

			w	Icon_02
			b	$16,$08,$05,$18
			w	GoRootDir

			w	Icon_02a
			b	$25,$08,$05,$18
			w	GoBack1Dir

:Icon_Tab1e		w	Icon_01
			b	$25,$08,$05,$18
			w	FileNxt240

;*** Directory-Icons.
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

:Icon_07
<MISSING_IMAGE_DATA>

:Icon_09
<MISSING_IMAGE_DATA>

:Icon_10
<MISSING_IMAGE_DATA>

:Icon_11
<MISSING_IMAGE_DATA>

:Icon_12
<MISSING_IMAGE_DATA>

:EndProgrammCode

;*** Startadresse Zwischenspeicher.
;    Directory der aktuellen Diskette.
;    Berechnung Druckdaten.
:Memory1		s 80 +1
:Memory2		s ((Memory1+81) / 256 +1) * 256 - Memory2
