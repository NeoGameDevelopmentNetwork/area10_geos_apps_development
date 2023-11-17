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
endif

			n	"mod.#408.obj"
			o	ModStart
			q	EndProgrammCode
			r	EndAreaCBM

			jmp	CBM_PrnDir
			jmp	CBM_PrnCurDir

			t	"-CBM_GetDskNam"
			t	"-GetDriver"

;*** L408: Verzeichnis ausgeben.
;Max. Anzahl GEOS-Filetypen. Der letzte Datei-Typ ist "GEOS ???".
:LastGEOSType		= 23

:CBM_PrnDir		lda	Target_Drv
			jsr	NewDrive

			lda	curDrive
			ldx	#$00			;Diskette einlegen.
			jsr	InsertDisk
			cmp	#$01
			bne	:102

			jsr	CBM_PrnCurDir		;Aktuelles Verzeichnis drucken.

			bit	DirPrinted		;Wurde ein Verzeichnis gedruckt ?
			bpl	:102			;Nein, Ende...
			DB_UsrBoxV408g5			;Abfrage: "Noch ein Verzeichnis ?"
			CmpBI	sysDBData,3
			beq	CBM_PrnDir		;Nein, Ende...

::102			jmp	L408ExitGD		;Zurück zu GeoDOS.

;*** Directory drucken (aus Directory-Menü).
:CBM_PrnCurDir		PopW	ReturnAdress		;Rücksprungadresse vom Stapel holen.

			jsr	ClrScreen
			jsr	LookForPrnt

			lda	Target_Drv
			jsr	LoadNewDisk

:InitMenu		jmp	SetPrnOpt

;*** Directory-Ausdruck beenden.
:L408ExitGD		jsr	ClrWin
			jmp	InitScreen

:ExitPrnMenu		ClrB	DirPrinted
:AbortPrint		jsr	ClrWin
			PushW	ReturnAdress
			rts

;*** Bildschirm löschen,
;    Vektor ":otherPressVec" löschen.
:ClrWin			ClrW	otherPressVec
			jmp	ClrScreen

;*** Dateinamen ausgeben.
:PrintText		ldy	#$00			;Dateiname ausgeben.
::101			sty	:102 +1

			lda	(r15L),y
			beq	:103
			jsr	SmallPutChar

::102			ldy	#$ff
			iny
			cpy	#16
			bne	:101
::103			rts

;*** Neue Diskette einlegen.
:InsertNewDsk		jsr	ClrWin			;Bildschirm löschen.

			lda	Target_Drv		;Diskette einlegen.
			ldx	#$ff
			jsr	InsertDisk
			cmp	#$01
			beq	:101

			ldx	#$00
			b $2c
::101			ldx	#$ff
			stx	DiskInDrv

			lda	Target_Drv

;*** Neue Diskette öffnen.
:LoadNewDisk		sta	Target_Drv
			jsr	NewDrive

			jsr	IsDskInDrv
			bit	DiskInDrv
			bmi	:101
			rts

::101			bit	curDrvMode
			bpl	:102

			ldx	Target_Drv		;Partition aktivieren.
			lda	DrivePart -8,x
			jsr	SetNewPart

::102			lda	curDrvMode
;--- Ergänzung: 02.12.18/M.Kanet
;NativeMode ist auch auf Nicht-CMD-Laufwerken möglich.
;			bpl	:103
			and	#%00100000
			beq	:103
			jsr	New_CMD_Root
			jmp	:104

::103			jsr	NewOpenDisk
::104			txa
			beq	:105
			lda	#$ff
::105			eor	#%11111111
			sta	DiskInDrv

			bit	DiskInDrv
			bpl	:106
			jsr	CBM_GetDskNam
::106			rts

;*** Neue Partition aktivieren.
:LoadNewPart		bit	curDrvMode		;CMD-Laufwerk ?
			bpl	:101			;Nein, weiter...

			ldx	Target_Drv		;Partition aktivieren.
			lda	DrivePart -8,x
			jsr	SetNewPart

			lda	#$ff
			rts
::101			lda	#$00
			rts

;*** Diskette im Laufwerk ?
:IsDskInDrv		jsr	NewOpenDisk		;Diskette öffnen.
			txa				;Fehler ?
			beq	:101			;Nein, weiter...
			lda	#$ff			;Keine Diskette!
::101			eor	#%11111111
			sta	DiskInDrv
			rts

;*** BAM der aktuellen Diskette einlesen.
:GetCurDskBAM		jsr	GetDirHead		;BAM einlesen.
:GetCurBAMInfo		LoadW	r5,curDirHead		;Diskettenspeicher berechnen.
			jmp	CalcBlksFree

;******************************************************************************
;*** Directory drucken.
;******************************************************************************
:DoPrint		bit	DiskInDrv
			bmi	:100
			rts

::100			ClrW	otherPressVec

			lda	#$01
			bit	PrnDirMode
			bpl	:101
			lda	#$03
::101			sta	LinesPerEntry

			jsr	ClrScreen

			bit	PrinterInMem
			bmi	:102

			jsr	LookForPrnt

			bit	PrinterInMem
			bmi	:102

			DB_OK	V408g3			;Fehler: "Druckertreiber nicht ..."
			jmp	SetPrnOpt

::102			jsr	CheckPrinter
			txa
			beq	InitDirHead
			jmp	InitMenu

;*** Directory-Ausdruck initialisieren.
:InitDirHead		ClrB	Page			;Seite auf #NULL.

			jsr	InitHead1
			jsr	InitHead3

			StartMouse
			NoMseKey

			jsr	GetDirHead
			MoveB	curDirHead+0,r1L
			MoveB	curDirHead+1,r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa
			beq	:101
			jmp	DiskError

::101			stx	V408a1			;Zeiger auf ersten Eintrag.
			jsr	WaitNewPage
			beq	NewPage
			jmp	AbortPrint

;*** Einzelne Seite drucken.
:NewPage		jsr	PrintHeader

::101			lda	pressFlag		;Drucken abbrechen ?
			bne	:106			;Ja, zurück zum Directory-Modus.

			lda	CurPrnLine		;Noch Platz für einen Eintrag auf
			cmp	LinesPerEntry		;aktueller Seite ?
			bcs	:102

			jsr	StopPrint		;Seiten-Vorschub.
			jsr	ClrBox
			jsr	WaitNewPage		;Bei Einzel-Blatt, warten auf Papier.
			beq	NewPage			;Nein, nächste Seite.
			jmp	AbortPrint		;Zurück zum Directory-Modus.

::102			jsr	DirLine1		;Einzelne Druck-Zeile erzeugen.
			bmi	:104
			bne	:105			;Directory-Ende, Infos drucken.
			jsr	DirLine2		;Langes Directory erzeugen.
			beq	:103
			dec	CurPrnLine		;Seite voll ?
			dec	CurPrnLine		;Seite voll ?
::103			dec	CurPrnLine		;Seite voll ?
::104			AddVBW	32,a8
			jmp	:101

::105			jsr	PrnDirInfo		;Directory-Informationen drucken.
			LoadB	DirPrinted,$ff
::106			jmp	ExitPrintDir

;*** Eintrag erzeugen.
:DirLine1		ldx	V408a1			;Alle Einträge eines Sektors
			cpx	#$08			;gedruckt ?
			bne	:104			;Nein, weiter...
			lda	diskBlkBuf+0		;Nächsten Directory-Sektor einlesen.
			bne	:101
			lda	#$7f			;Directory-Ende.
			rts

::101			ldx	diskBlkBuf+1
			sta	r1L
			stx	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa
			beq	:103
			stx	:102 +1
			jsr	StopPrint
::102			ldx	#$ff
			jmp	DiskError		;...und Disketten-Fehler ausgeben.

::103			ldx	#$00			;Zeiger innerhalb des Directory-
::104			txa				;Sektors berechnen.
			inx
			stx	V408a1
			asl
			asl
			asl
			asl
			asl
			clc
			adc	#<diskBlkBuf
			sta	r4L
			lda	#>diskBlkBuf
			sta	r4H

			ldy	#$02
			lda	(r4L),y			;Datei-Typ-Byte einlesen.
			and	#%01111111
			bne	InitLine1		;Typ < $80, ungültiger Eintrag.
			lda	#$ff
			rts

:InitLine1		ldx	#$00
::101			jsr	InsertSpace
			cpx	#$07
			bne	:101

			MoveW	r4,a8
			jsr	InsertName

			jsr	Ins2Space		;Zwei Leerzeichen einfügen.

			ldy	#$02
			lda	(r4L),y			;Datei-Typ-Byte einlesen.
			pha				;Byte merken.
			and	#%00000111		;Datei-Typ isolieren.
			asl
			asl
			tay
			LoadB	r0L,4
::102			lda	V408f0,y		;Datei-Typ in Zwischenspeicher.
			jsr	InsertASCII
			iny
			dec	r0L
			bne	:102

			pla
			and	#%01000000		;Schreibschutz-Flag isolieren.
			beq	:103
			lda	#"*"			;Datei ist schreibgeschützt.
			bne	:104
::103			lda	#" "			;Datei ist nicht schreibgeschützt.
::104			jsr	InsertASCII

			jsr	Ins2Space		;Ein Leerzeichen einfügen.

;*** Dateigröße und Datum/Uhrzeit einfügen.
			stx	:105 +1 			;Zeiger innerhalb Zwischenspeicher

			ldy	#$1e			;Datei-Größe in ASCII-String
			lda	(r4L),y			;wandeln.
			sta	r0L
			iny
			lda	(r4L),y
			sta	r0H
			ClrB	r1L
			jsr	ZahlToASCII

::105			ldx	#$ff
			LoadW	r0,ASCII_Zahl
			jsr	FileSize

			jsr	Ins2Space		;Ein Leerzeichen einfügen.

			MoveW	r4,a8
			jsr	GetBinDate
			jsr	InsertDate

;*** Eintrag erzeugen (Fortsetzung).
:InitLine2		jsr	Ins2Space		;Zwei Leerzeichen einfügen.

			ldy	#$02			;Zeiger auf Dateityp setzen.
			lda	(r4L),y			;Dateityp einlesen.
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
			lda	(r4L),y
			beq	:103
			cmp	#LastGEOSType
			bcc	:103
			lda	#LastGEOSType
::103			asl
			tay
			lda	V408c0 +0,y
			sta	r0L
			lda	V408c0 +1,y
			sta	r0H

::104			ldy	#$00
::105			lda	(r0L),y			;GEOS-Datei-Typ in Zwischenspeicher.
			beq	:106
			jsr	InsertASCII
			iny
			bne	:105

::106			lda	#CR			;Ende des Zwischenspeichers markieren.
			sta	Memory1+0,x
			lda	#NULL
			sta	Memory1+1,x
			jsr	PrnASCIILine		;Eintrag ausgeben.
			lda	#$00
			rts

;*** Langes Directory.
:DirLine2		bit	PrnDirMode
			bmi	:101
			rts

::101			ldy	#$15			;Datei-Name in Zwischenspeicher.
::102			lda	(r4L),y
			bne	:103
			ldx	#$00
			jmp	SetEndPLine

::103			sta	r1L
			iny
			lda	(r4L),y
			sta	r1H
			PushW	r4
			LoadW	r4,fileHeader
			jsr	GetBlock
			PopW	r4
			txa
			beq	GetLine2
			jmp	DiskError

:GetLine2		ldy	#19
::101			lda	fileHeader +$61,y
			beq	:102
			cmp	#$20
			bcc	:103
			cmp	#$7f
			bcs	:103
::102			dey
			bpl	:101
			bmi	:105

::103			ldy	#19
			lda	#" "
::104			sta	fileHeader +$61,y
			dey
			bpl	:104

::105			ldx	#$07
			ldy	#$00
::106			lda	fileHeader +$61,y
			bne	:107
			lda	#" "
::107			jsr	InsertASCII
			iny
			cpy	#20
			bne	:106

			ldy	#$05
::108			jsr	InsertSpace
			dey
			bne	:108

;*** Langes Directory.
			lda	fileHeader +$60
			lsr
			lsr
			lsr
			lsr
			lsr
			lsr
			asl				;Zeiger auf Text für GEOS-Modus
			tay				;berechnen.
			lda	V408c1 +0,y
			sta	r0L
			lda	V408c1 +1,y
			sta	r0H

			ldy	#$00
::109			lda	(r0L),y
			beq	:110
			jsr	InsertASCII
			iny
			bne	:109
::110			jsr	InsertSpace		;Leerzeichen einfügen.
			iny
			cpy	#$18
			bne	:110

			ldy	#$00
::111			lda	fileHeader +$4d,y
			beq	SetEndPLine
			jsr	InsertASCII
			sta	Memory1,x
			iny
			cpy	#$12
			bne	:111

:SetEndPLine		lda	#$0d
			sta	Memory1+0,x
			lda	#$00
			sta	Memory1+1,x
			jsr	PrnASCIILine
			jsr	EmptyLine
			lda	#$ff
			rts

;*** Directory-Informationen drucken.
:PrnDirInfo		jsr	ChkInfoSpace
			beq	:102
::101			jsr	PrintHeader		;Bei neuer Seite, Seiten-Kopf drucken.
::102			jsr	EmptyLine

			jsr	GetDirInfo

			MoveW	DirFiles,r0
			LoadW	r3,V408b5		;Anzahl Dateien im Directory.
			LoadB	r4L,39
			LoadB	r4H,5
			jsr	NumASCII_a
			MoveW	r3,r0
			jsr	PrnTempLine

			MoveW	UsedBlocks,r0
			LoadW	r3,V408b6		;Anzahl Blocks im Directory.
			LoadB	r4L,39
			LoadB	r4H,5
			jsr	NumASCII_a
			MoveW	r3,r0
			jsr	PrnTempLine

			jsr	GetCurDskBAM		;Disketten-Informationen einlesen.
			sec
			lda	r3L
			sbc	r4L
			sta	r0L
			lda	r3H
			sbc	r4H
			sta	r0H
			LoadW	r3,V408b7		;Anzahl belegter Blocks.
			LoadB	r4L,39
			LoadB	r4H,5
			jsr	NumASCII_a
			MoveW	r3,r0
			jsr	PrnTempLine

			jsr	GetCurBAMInfo
			MoveW	r4,r0
			LoadW	r3,V408b8		;Anzahl freier Sektoren.
			LoadB	r4L,39
			LoadB	r4H,5
			jsr	NumASCII_a
			MoveW	r3,r0
			jsr	PrnTempLine

			jsr	GetCurBAMInfo
			MoveW	r3,r0
			LoadW	r3,V408b9		;Gesamt-Anzahl Sektoren.
			LoadB	r4L,39
			LoadB	r4H,5
			jsr	NumASCII_a
			MoveW	r3,r0
			jsr	PrnTempLine

			jsr	EmptyLine
			LoadW	r0,V408b10		;Anschluß-Info.
			jmp	PrnTempLine

;*** Verzeichnisdaten einlesen.
:GetDirInfo		lda	#$00
			sta	UsedBlocks+0		;Anzahl Blocks in Directory löschen.
			sta	UsedBlocks+1
			sta	DirFiles+0		;Anzahl Files in Directory löschen.
			sta	DirFiles+1

			MoveB	curDirHead+0,r1L
			MoveB	curDirHead+1,r1H

			LoadW	r4,diskBlkBuf
::101			jsr	GetBlock		;Verzeichnis-Sektor lesen.
			txa
			beq	:102
			jmp	DiskError

::102			ldy	#$00
::103			lda	diskBlkBuf+2,y		;Datei vorhanden ?
			beq	:104			;Nein, weiter...

			IncWord	DirFiles		;Anzahl Dateien +1.

			clc				;Belegter Speicher addieren.
			lda	diskBlkBuf+30,y
			adc	UsedBlocks+0
			sta	UsedBlocks+0
			lda	diskBlkBuf+31,y
			adc	UsedBlocks+1
			sta	UsedBlocks+1

::104			tya				;Zeiger auf nächste Datei.
			add	32
			tay
			bne	:103
			lda	diskBlkBuf+0
			beq	:105
			sta	r1L
			lda	diskBlkBuf+1
			sta	r1H
			jmp	:101

::105			rts				;Ende.

;*** DOS/CBM: Erste Kopfzeile erzeugen.
:InitHead1		ldy	#$00			;Titel-Zeile in Zwischenspeicher.
::101			lda	V408b0,y
			sta	Memory1,y
			beq	:102
			iny
			bne	:101

::102			ldx	#$38			;Datum des Directory-Ausdrucks in
			lda	day			;Titel-Zeile eintragen.
			jsr	HexASCII_a
			inx
			lda	month
			jsr	HexASCII_a
			inx
			lda	year
			jsr	HexASCII_a
			ldx	#$44			;Uhrzeit des Directory-Ausdrucks in
			lda	hour			;Titel-Zeile eintragen.
			jsr	HexASCII_a
			inx
			lda	minutes
			jsr	HexASCII_a

			ldy	#0			;Titel-Zeile zurückschreiben.
::103			lda	Memory1,y
			sta	V408b0,y
			beq	:104
			iny
			bne	:103
::104			rts

;*** CBM: Zweite Kopfzeile erzeugen.
:InitHead3		jsr	CBM_GetDskNam

			ldy	#$00			;Disketten-Name in Titel-Zeile
::101			lda	cbmDiskName,y		;eintragen.
			jsr	ConvertChar
			sta	V408b1+17,y
			iny
			cpy	#$10
			bne	:101
			rts

;*** Seiten-Kopf drucken.
:PrintHeader		jsr	InitPrint1

			lda	MaxPrnLines
			sub	$05
			bit	PrnDirMode
			bpl	:101
			sub	$01
::101			sta	CurPrnLine

			jsr	InitPrint2

			LoadW	r0,V408b1
			jsr	PrnTempLine
			LoadW	r0,V408b2
			jsr	PrnTempLine

			bit	PrnDirMode
			bpl	:102
			LoadW	r0,V408b3
			jsr	PrnTempLine

::102			LoadW	r0,V408b4
			jmp	PrnTempLine

;*** Leerzeile drucken.
:EmptyLine		LoadB	Memory1+0,CR		;Eine Leerzeile ausgeben.
			LoadB	Memory1+1,NULL

;*** ASCII-Zeile drucken.
:PrnASCIILine		LoadW	r0,Memory1
:PrnTempLine		LoadW	r1,FileNTab
			jmp	PrintASCII

;*** Seite auswerfen und Ausdruck beenden.
:ExitPrintDir		jsr	StopPrint		;Seiten-Vorschub...
			jsr	ClrBox
			jmp	AbortPrint

;*** Noch Platz auf aktueller Seite für Verzeichnis-Infos ?
:ChkInfoSpace		lda	CurPrnLine		;Noch Platz für 6 Zeilen ?
			cmp	#$08
			bcs	:101
			jsr	StopPrint		;Nein, Seiten-Vorschub...
			jsr	WaitNewPage		;Warten auf neue Seite.
			beq	:102			;Nein, Directory-Daten drucken.
			jmp	AbortPrint

::101			lda	#$00
			rts
::102			lda	#$ff
			rts

;*** Ist Drucker aktiv ?
:CheckPrinter		jsr	InitForPrint		;Druckertreiber initialisieren.
			jsr	StartASCII		;Drucker auf ASCII vorbereiten.
			txa
			beq	:101			;Kein Fehler, Seite initialisieren.
			DB_UsrBoxV408g4 			;Drucker nicht verfügbar.
			CmpBI	sysDBData,1
			beq	CheckPrinter
			ldx	#$ff
::101			rts

;*** Ausdruck initialisieren.
:InitPrint1		inc	Page
			jsr	InfoPrnPage
			jmp	SetNLQ

:InitPrint2		lda	Page			;Seiten-Nummer in Titel-Zeile.
			jsr	HexASCII_b
			stx	V408b1+75
			sta	V408b1+76

			LoadW	r0,V408b0		;Header ausdrucken.
			jmp	PrnTempLine

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
:InsertDate		lda	DateDMem+2		;Ausgabe: Tag.
			jsr	HexASCII_a
			lda	#"."
			jsr	InsertASCII

			lda	DateDMem+1		;Ausgabe: Monat.
			jsr	HexASCII_a
			lda	#"."
			jsr	InsertASCII

			lda	DateDMem+0		;Ausgabe: Jahr.
			jsr	HexASCII_a

			jsr	Ins2Space

			lda	DateDMem+3		;Ausgabe: Stunde.
			jsr	HexASCII_a
			lda	#":"
			jsr	InsertASCII

			lda	DateDMem+4		;Ausgabe: Minute.
			jmp	HexASCII_a

;*** Datum einlesen.
:GetBinDate		ldy	#$19
::101			lda	(a8L),y
			sta	DateDMem-$19,y
			iny
			cpy	#$1e
			bne	:101
			rts

;*** Info: "Seite wird gedruckt..."
:InfoPrnPage		jsr	DoInfoBox
			PrintStrgV408g0
			rts

;*** Warten auf neues Blatt Papier...
:WaitNewPage		lda	PaperType		;Einzelblatt-Modus ?
			beq	:101			;Ja, Info-Box.
			jsr	ClrBox
			DB_UsrBoxV408g2
			lda	sysDBData
			cmp	#$01
			beq	:101

			lda	#$ff
			rts
::101			lda	#$00
			rts

;*** Zahl auf Wert < 100 testen.
:PrepNum100		cmp	#100
			bcc	:101
			sbc	#100
			jmp	PrepNum100
::101			rts

;*** Zeichen einfügen.
:Ins2Space		jsr	InsertSpace		;Leerzeichen einfügen.
:InsertSpace		lda	#" "			;Leerzeichen einfügen.
:InsertASCII		sta	Memory1,x		;ASCII-Zeichen einfügen.
			inx
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
:FileSize		lda	#$05
			sta	:102 +1

			ldy	#$00			;Dateigröße auf 9 Zeichen mit
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

;*** HEX-Zahl nach ASCII wandeln.
:HexASCII_b		jsr	PrepNum100
			ldx	#"0"			;Zehner-Stelle auf "0" setzen.
::101			cmp	#10			;Zahl < 10 ?
			bcc	:102			;Ja, Ende...
			inx				;Nein, Zehner-Stelle erhöhen.
			sub	10			;Zahl = Zahl -10.
			bne	:101			;Zahl = 0 ? Nein, weiter...
::102			add	$30			;ASCII-Zahl erzeugen.
			rts

;*** Zahl in ASCII wandeln.
:NumASCII_a		ClrB	r1L
:NumASCII_b		jsr	ZahlToASCII
:NumASCII_c		ldy	r4L			;Zeiger auf Adresse für Zahlenstring.
			ldx	#$00
::101			lda	ASCII_Zahl,x		;ASCII-Zeichen aus Zahlenstring
			beq	:102			;einlesen. Zeichen = 0 ? Ja, Ende...
			sta	(r3L),y			;In Ziel-String eintragen.
			iny				;Weiter mit nächstem Zeichen.
			inx
			bne	:101

::102			cpx	r4H			;String auf gewünschte Länge mit
			bcs	:103			;Leerzeichen auffüllen.
			lda	#" "
			sta	(r3L),y
			iny
			inx
			bne	:102

::103			rts

;*** Systemvariablen.
:UsedBlocks		w $0000				;Anzahl belegter Blocks
:DirFiles		w $0000				;Anzahl Files

:CurPrnLine		b $00				;Anzahl Zeilen während Druckvorgang.
:LinesPerEntry		b $00				;Benötigte Druckzeilen für einen Dateieintrag.
:Page			b $00				;Seiten-Nr.
:DateDMem		s $05				;Speicher für Datum.

:V408a0			b $00,$00			;Zeiger auf Verzeichnis-Sektor.
:V408a1			b $00				;Zeiger auf Eintrag in Verzeichnis-Sektor.

if Sprache = Deutsch
;*** Texte für "CBM:Verzeichnis drucken"
:V408b0			b "       GeoDOS - Directory                   Erstellt am "
			b "xx.xx.xx um xx:xx Uhr",$0d,NULL

;*** Texte für "CBM:Verzeichnis drucken"
:V408b1			b "       Diskette:                                        "
			b "            Seite: xx",$0d,$0d,NULL
:V408b2			b "       Datei-Name        Typ S  Länge  Datum     Zeit   "
			b "GEOS-Datei-Typ",$0d,NULL
:V408b3			b "       Name des Autors          GEOS-Modus              "
			b "GEOS-Klasse",$0d,NULL
:V408b4			b "       -------------------------------------------------"
			b "---------------------",$0d,NULL
:V408b5			b "       Anzahl Dateien im Verzeichnis : xxxxx",$0d,NULL
:V408b6			b "       Blocks im Verzeichnis         : xxxxx",$0d,NULL
:V408b7			b "       Blocks auf Diskette belegt    : xxxxx",$0d,NULL
:V408b8			b "       Blocks auf Diskette frei      : xxxxx",$0d,NULL
:V408b9			b "       Anzahl Blocks auf Diskette    : xxxxx",$0d,NULL
:V408b10		b "       1 Block auf Diskette entspricht 254 Bytes.",$0d,NULL
endif

if Sprache = Englisch
;*** Texte für "CBM:Verzeichnis drucken"
:V408b0			b "       GeoDOS - Directory                   Erstellt am "
			b "xx.xx.xx at xx:xx",$0d,NULL

;*** Texte für "CBM:Verzeichnis drucken"
:V408b1			b "       Disk    :                                        "
			b "            Page : xx",$0d,$0d,NULL
:V408b2			b "       Filename          Typ S  Length Date      Time   "
			b "GEOS-Filetype",$0d,NULL
:V408b3			b "       Name of author           GEOS-Mode               "
			b "GEOS-class",$0d,NULL
:V408b4			b "       -------------------------------------------------"
			b "---------------------",$0d,NULL
:V408b5			b "       Files in directory            : xxxxx",$0d,NULL
:V408b6			b "       Blocks used in directory      : xxxxx",$0d,NULL
:V408b7			b "       Blocks used on disk           : xxxxx",$0d,NULL
:V408b8			b "       Blocks available on disk      : xxxxx",$0d,NULL
:V408b9			b "       Total blocks on disk          : xxxxx",$0d,NULL
:V408b10		b "       Each block contains 256 bytes.",$0d,NULL
endif

;*** Texte für Verzeichnis.
:V408c0			w V408d0 ,V408d1 ,V408d2 ,V408d3 ,V408d4
			w V408d5 ,V408d6 ,V408d7 ,V408d8 ,V408d9
			w V408d10,V408d11,V408d12,V408d13,V408d14
			w V408d15,V408d99,V408d17,V408d99,V408d99
			w V408d99,V408d21,V408d22,V408d99

:V408c1			w V408e0 ,V408e1 ,V408e2 ,V408e3

if Sprache = Deutsch
:V408d0			b "Nicht GEOS",NULL
:V408d1			b "BASIC",NULL
:V408d2			b "Assembler",NULL
:V408d3			b "Datenfile",NULL
:V408d4			b "System-Datei",NULL
:V408d5			b "DeskAccessory",NULL
:V408d6			b "Anwendung",NULL
:V408d7			b "Dokument",NULL
:V408d8			b "Zeichensatz",NULL
:V408d9			b "Druckertreiber",NULL
:V408d10		b "Eingabetreiber",NULL
:V408d11		b "Laufwerkstreiber",NULL
:V408d12		b "Startprogramm",NULL
:V408d13		b "Temporär",NULL
:V408d14		b "Selbstausführend",NULL
:V408d15		b "Eingabetreiber 128",NULL
:V408d17		b "gateWay-Dokument",NULL
:V408d21		b "geoShell-Kommando",NULL
:V408d22		b "geoFAX Druckertreiber",NULL
:V408d99		b "GEOS ???",NULL

:V402r105		b "< 1581 - Partition >",NULL
:V402r106		b "< Unterverzeichnis >",NULL

:V408e0			b "GEOS 40 Zeichen",NULL
:V408e1			b "GEOS 40 & 80 Zeichen",NULL
:V408e2			b "GEOS 64",NULL
:V408e3			b "GEOS 128, 80 Zeichen",NULL

:V408f0			b "DEL SEQ PRG USR REL CBM DIR ??? "
:V408f1			b "Sequentiell",NULL
:V408f2			b "GEOS-VLIR",NULL
endif

if Sprache = Englisch
:V408d0			b "Not GEOS",NULL
:V408d1			b "BASIC",NULL
:V408d2			b "Assembler",NULL
:V408d3			b "Datafile",NULL
:V408d4			b "Systemfile",NULL
:V408d5			b "DeskAccessory",NULL
:V408d6			b "Application",NULL
:V408d7			b "Document",NULL
:V408d8			b "Font",NULL
:V408d9			b "Printerdriver",NULL
:V408d10		b "Inputdriver",NULL
:V408d11		b "Diskdriver",NULL
:V408d12		b "Bootfile",NULL
:V408d13		b "Temporary",NULL
:V408d14		b "Autoexecute",NULL
:V408d15		b "Input 128",NULL
:V408d17		b "gateWay-document",NULL
:V408d21		b "geoShell-command",NULL
:V408d22		b "geoFAX printerdriver",NULL
:V408d99		b "GEOS ???",NULL

:V402r105		b "< 1581 - Partition >",NULL
:V402r106		b "<   subdirectory   >",NULL

:V408e0			b "GEOS 40 columns",NULL
:V408e1			b "GEOS 40 & 80 columns",NULL
:V408e2			b "GEOS 64",NULL
:V408e3			b "GEOS 128, 80 columns",NULL

:V408f0			b "DEL SEQ PRG USR REL CBM DIR ??? "
:V408f1			b "Sequential",NULL
:V408f2			b "GEOS-VLIR",NULL
endif

if Sprache = Deutsch
;*** Info: "Seite wird gedruckt..."
:V408g0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Bitte warten!"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "Seite wird gedruckt..."
			b PLAINTEXT,NULL

;*** Info: "Druckertreiber wird geladen..."
:V408g1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Druckertreiber wird"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "geladen..."
			b NULL

;*** Hinweis: "Bitte neues Blatt Papier einlegen!"
:V408g2			w :101, :102, ISet_Info
			b CANCEL,OK
::101			b BOLDON,"Bitte ein neues Blatt",NULL
::102			b        "Papier einlegen!",NULL

;*** Hinweis: "Kann Druckertreiber nicht finden!"
:V408g3			w :101, :102, ISet_Achtung
::101			b BOLDON,"Kann Druckertreiber",NULL
::102			b        "nicht finden!",NULL

;*** Hinweis: "Drucker nicht ansprechbar!"
:V408g4			w :101, :102, ISet_Achtung
			b CANCEL,OK
::101			b BOLDON,"Der Drucker ist nicht",NULL
::102			b        "ansprechbar !",NULL

;*** Hinweis: "Noch ein Verzeichnis drucken ?"
:V408g5			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Möchten Sie noch ein",NULL
::102			b        "Verzeichnis drucken ?",NULL
endif

if Sprache = Englisch
;*** Info: "Seite wird gedruckt..."
:V408g0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Please wait!"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "Printing directory..."
			b PLAINTEXT,NULL

;*** Info: "Druckertreiber wird geladen..."
:V408g1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Please wait while"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "loading printdriver..."
			b NULL

;*** Hinweis: "Bitte neues Blatt Papier einlegen!"
:V408g2			w :101, :102, ISet_Info
			b CANCEL,OK
::101			b BOLDON,"Please add new paper",NULL
::102			b        "into your printer!",NULL

;*** Hinweis: "Kann Druckertreiber nicht finden!"
:V408g3			w :101, :102, ISet_Achtung
::101			b BOLDON,"Cannot find current",NULL
::102			b        "printerdriver!",NULL

;*** Hinweis: "Drucker nicht ansprechbar!"
:V408g4			w :101, :102, ISet_Achtung
			b CANCEL,OK
::101			b BOLDON,"Printer is not",NULL
::102			b        "available!",NULL

;*** Hinweis: "Noch ein Verzeichnis drucken ?"
:V408g5			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Would you like to print",NULL
::102			b        "another directory ?",NULL
endif

;*** Drucker wählen.
:SlctPrinter		jsr	OpenSysDrive
			jsr	SelectPrinter		;Durckertreiber wählen.
			jsr	LoadPrntDrv		;Druckertreiber einlesen.
			jsr	Ld2DrvData		;Laufwerks-I/O wieder herstellen.
			lda	Target_Drv
			jsr	LoadNewDisk
			jmp	SetPrnOpt		;Druckoptionen.

;*** Laufwerke ermitteln.
:LookForPrnt		jsr	DoInfoBox		;Info: "Treiber werden eingelesen..."
			PrintStrgV408g1

			jsr	OpenSysDrive

			LoadW	r6,PrntFileName		;Druckertreiber laden.
			jsr	FindFile
			txa
			bne	:103

			jsr	LoadPrntDrv

::103			jsr	OpenUsrDrive
			jmp	ClrBox

;*** Druckertreiber laden.
:LoadPrntDrv		jsr	LoadPrinter
			txa
			beq	:101
			lda	#$ff
::101			eor	#%11111111
			sta	PrinterInMem
			cmp	#$ff
			bne	:102
			jsr	GetDimensions
			sty	r0L
			LoadB	r1L,$08
			ldx	#r0L
			ldy	#r1L
			jsr	BBMult
			LoadW	r1,$000c
			ldx	#r0L
			ldy	#r1L
			jsr	Ddiv
			ldy	r0L
			iny
			sty	MaxPrnLines
::102			rts

;*** Commodore-Datei drucken.
:SetPrnOpt		jsr	IsDskInDrv

			ClrB	curSubMenu		;Zeiger auf Hauptmenü.

;*** Bildschirm aufbauen.
:SetPrnOpt1		jsr	Bildschirm_a

;*** Auswahlmenü darstellen.
:SetPrnOpt2		jsr	InitMenuPage		;Menüseite initialisieren.

;*** Menü aktivieren.
			jsr	SetHelp

			LoadW	otherPressVec,ChkOptSlct
			LoadW	r0,Icon_Tab1
			jsr	DoIcons			;Icon-Menü aktivieren.

:SetPrnOpt3		StartMouse
			NoMseKey
			rts

;*** Zeiger auf Hilfedatei bereitstellen.
:SetHelp		LoadW	r0,HelpFileName
			lda	#<SetPrnOpt1
			ldx	#>SetPrnOpt1
			jmp	InstallHelp

;*** Fenster aufbauen.
:Bildschirm_a		jsr	ClrScreen		;Bildschirm löschen.

			jsr	i_C_MenuTitel
			b	$00,$00,$28,$01
			jsr	i_C_MenuBack
			b	$00,$01,$28,$18

			FillPRec$00,$00,$07,$0008,$013f

			jsr	UseGDFont		;Titel ausgeben.
			PrintStrgV408r0

			LoadW	r0,V408v0		;Menügrafik zeichnen.
			jsr	GraphicsString
			jsr	i_C_Register
			b	$01,$05,$0b,$01
			jsr	i_C_Register
			b	$0d,$05,$09,$01
			jsr	i_C_Register
			b	$17,$05,$08,$01

			jsr	i_C_MenuMIcon
			b	$00,$01,$0a,$03
			rts

;*** Menüseite initialisieren.
:InitMenuPage		jsr	i_C_MenuBack		;Menüfenster löschen.
			b	$01,$06,$26,$13
			FillPRec$00,$31,$b7,$0001,$013e

			lda	curSubMenu		;Menütext ausgeben.
			asl
			tax
			lda	MenuText+0,x
			sta	r0L
			lda	MenuText+1,x
			sta	r0H
			jsr	PutString

;*** Bildschirm aufbauen.
:SetClkPos		jsr	SetDataVec		;Zeiger auf Menütabelle.

			FillPRec$00,$b9,$c6,$0001,$013e

			jsr	UseGDFont		;GeoDOS-Font aktivieren.
			ClrB	currentMode

			lda	curSubMenu		;Text für Fußzeile ausgeben.
			asl
			tax
			lda	InfoText+0,x
			sta	r0L
			lda	InfoText+1,x
			sta	r0H
			ClrB	currentMode
			LoadW	r11,$0008
			LoadB	r1H,$c4
			jsr	PutString

::101			ldy	#$00			;Menüoptionen ausgeben.
			lda	(a7L),y			;Alle Daten ausgegeben ?
			bne	:102			;Nein, weiter...
			ClrB	pressFlag		;Ende.
			rts

::102			jsr	CopyRecData		;Daten für Rechteck einlesen.

			ldy	#$07
			lda	(a7L),y
			tax
			dey
			lda	(a7L),y
			ldy	#$00
			jsr	CallRoutine		;Ausgabefeld definieren.
			tya				;Muster setzen ?
			bmi	:103			;Nein, weiter...

			jsr	ShowClkOpt		;Klickoption ausgeben.

::103			jsr	CopyRecData		;Daten für Rahmen einlesen.
			lda	r2H			;Rahmen zeichen ?
			beq	:104			;Nein, weiter...

			SubVW	1,r3			;Grenzen des Rechtecks -1.
			AddVBW	1,r4
			dec	r2L
			inc	r2H

			lda	#%11111111		;Rahmen zeichen.
			jsr	FrameRectangle

::104			AddVBW	10,a7			;Zeiger auf nächste Option.
			jmp	:101

;*** Zeiger auf Datenliste.
:SetDataVec		lda	curSubMenu
			asl
			tax
			lda	V408x0+0,x
			sta	a7L
			lda	V408x0+1,x
			sta	a7H
			rts

;*** Klickoption anzeigen.
:ShowClkOpt		pha
			Pattern	0			;Muster setzen.
			jsr	Rectangle		;Inhalt löschen.

			jsr	DefColOpt

			pla				;Option gewählt ? (AKKU = $02)
			beq	:101			;Nein, weiter...

			AddVBW	1,r3			;Schalter zeichnen.
			SubVW	1,r4
			inc	r2L
			dec	r2H

			Pattern	1
			jsr	Rectangle
::101			jmp	SetColOpt

;*** Farbe für Klick-Option definieren.
:DefClkOpt		jsr	CopyRecData		;Daten für Rechteck einlesen.
			jsr	DefColOpt		;Farbe für Optionsfeld definieren.
			jsr	SetColOpt		;Farbe für Optionsfeld darstellen.
			ldy	#$ff
			rts

;*** Prüfen ob Option angeklickt.
:ChkOptSlct		lda	#$00
			jsr	:110			;Klick auf "Verzeichnis" ?
			bne	:102			;Ja, weiter...

			lda	#$06
			jsr	:110			;Klick auf "Optionen" ?
			bne	:103			;Ja, weiter...

			lda	#$0c
			jsr	:110			;Klick auf "Drucker" ?
			bne	:104			;Ja, weiter...

::101			jmp	:120			;Wurde Option angeklickt ?

::102			lda	#$00
			b $2c
::103			lda	#$01
			b $2c
::104			lda	#$02
			cmp	curSubMenu
			beq	:105
			sta	curSubMenu
			jmp	SetPrnOpt2		;Nein, weitertesten.
::105			jmp	SetPrnOpt3

;*** Mausbereich prüfen.
::110			clc
			adc	#<V408t0
			sta	a7L
			lda	#$00
			adc	#>V408t0
			sta	a7H

			jsr	CopyRecData		;Werte aus Menütabelle nach ":r2".
			jmp	IsMseInRegion		;Ist Maus innerhalb eines Options-

;*** Optionsbereich prüfen.
::120			jsr	SetDataVec		;Zeiger auf Menütabelle.

::121			ldy	#$00
			lda	(a7L),y			;Ende Menütabelle erreicht ?
			bne	:122			;Nein, weiter.
			ClrB	pressFlag
			rts				;Ende.

::122			jsr	CopyRecData		;Werte aus Menütabelle nach ":r2".
			jsr	IsMseInRegion		;Ist Maus innerhalb eines Options-
			tax				;Icons ?
			beq	:123			;Nein, weitertesten.

			ldy	#$09
			jsr	CallNumRout
			jsr	SetClkPos		;Neuen Wert für Option anzeigen.
			cli
			NoMseKey			;Warten bis keine Maustaste gedrückt.
			rts				;Ende.

::123			AddVBW	10,a7
			jmp	:121

;*** Daten für Rahmen nach ":r2".
:CopyRecData		ldy	#$05
::1			lda	(a7L),y
			sta	r2,y
			dey
			bpl	:1
			rts

;*** Routine aufrufen.
:CallNumRout		lda	(a7L),y
			tax
			dey
			lda	(a7L),y
			jmp	CallRoutine

;*** Farbe berechnen.
:DefColOpt		PushW	r3			;Register r3 und r4 speichern.
			PushW	r4

			ldx	#r3L			;minX und maxX berechnen.
			ldy	#$03
			jsr	DShiftRight
			ldx	#r4L
			ldy	#$03
			jsr	DShiftRight

			lda	r2L			;minY-Koordinate.
			lsr
			lsr
			lsr
			sta	SetColOpt +4

			lda	r2H			;maxY-Koordinate.
			suba	r2L
			lsr
			lsr
			lsr
			add	1
			sta	SetColOpt +6

			lda	r3L			;minX-Koordinate.
			sta	SetColOpt +3

			sec				;maxX-Koordinate.
			lda	r4L
			sbc	r3L
			add	1
			sta	SetColOpt +5

			PopW	r4			;Register r3 und r4 wiederherstellen.
			PopW	r3
			rts

;*** Farbe auf Bildschirm.
:SetColOpt		jsr	i_ColorBox		;Farbe setzen.
			b	$00,$00,$00,$01,$01
			rts

;*** Aktuelles Laufwerk anzeigen.
:DefOpt1a		lda	#$00			;Ausgabe-Fenster löschen.
			jsr	ShowClkOpt

			lda	Target_Drv		;Laufwerksbuchstaben berechnen.
			add	$39
			sta	:101 +10

			Print	$0024,$4e
if Sprache = Deutsch
::101			b	PLAINTEXT,"Laufwerk x: ",NULL
endif
if Sprache = Englisch
::101			b	PLAINTEXT,"Drive    x: ",NULL
endif

			lda	Target_Drv		;Laufwerksbezeichnung ausgeben.
			sub	8
			asl
			asl
			asl
			clc
			adc	#<Drive_ASCII
			sta	r15L
			lda	#$00
			adc	#>Drive_ASCII
			sta	r15H
			jsr	PrintText
			ldy	#$ff
			rts

;*** Aktuelle Partition anzeigen.
:DefOpt1b		lda	#$00			;Ausgabe-Fenster löschen.
			jsr	ShowClkOpt
			bit	DiskInDrv		;Diskette im Laufwerk ?
			bpl	:101			;Nein, weiter...
			bit	curDrvMode		;CMD-Laufwerk ?
			bpl	:102			;Nein, weiter...

			LoadW	r11,$0024		;Partitionsname ausgeben.
			LoadB	r1H,$76
			LoadW	r15,Part_Info+5
			jsr	PrintText
			ldy	#$ff
			rts

::101			Print	$0024,$76
if Sprache = Deutsch
			b	PLAINTEXT,"(Keine Diskette)",NULL
endif
if Sprache = Deutsch
			b	PLAINTEXT,"(No disk)",NULL
endif
			ldy	#$ff
			rts

::102			PrintXY	$0024,$76,cbmDiskName
			ldy	#$ff
			rts

;*** Verzeichnisnamen anzeigen.
:DefOpt1c		lda	#$00			;Ausgabe-Fenster löschen.
			jsr	ShowClkOpt
			bit	DiskInDrv		;Diskette im Laufwerk ?
			bpl	:103			;Nein, weiter...

			lda	curDrvMode
;--- Ergänzung: 02.12.18/M.Kanet
;NativeMode ist auch auf Nicht-CMD-Laufwerken möglich.
;			bpl	:103
			and	#%00100000
			beq	:103

			lda	curDirHead+32
			cmp	#$01
			bne	:101
			lda	curDirHead+33
			cmp	#$01
			beq	:102

::101			ldx	#r15L			;Zeiger auf Diskettenname.
			jsr	GetPtrCurDkNm
			LoadW	r11,$0024		;Diskettenname ausgeben.
			LoadB	r1H,$9e
			jsr	PrintText
			jmp	:103

::102			PrintXY	$0024,$9e,cbmDiskName

::103			ldy	#$ff
			rts

;*** Partition wechseln.
:SetOpt1b		bit	DiskInDrv
			bpl	:101
			bit	curDrvMode		;CMD-Laufwerk ?
			bmi	:102			;Ja, weiter...
::101			rts

::102			pla
			pla
			jsr	ClrWin			;Bildschirm löschen.
			jsr	CMD_OtherPart		;Partition wechseln.
			jmp	SetPrnOpt		;Optionen anzeigen.

;*** Laufwerk wechseln.
:SetOpt1d		ldx	Target_Drv		;Zeiger auf nächstes Laufwerk.
::101			inx
			cpx	#12			;Letztes Laufwerk erreicht ?
			bcc	:102			;Nein, weiter...
			ldx	#8			;Laufwerk #8 aktivieren.
::102			lda	DriveTypes-8,x		;Laufwerk verfügbar ?
			beq	:101			;Nein, nächstes Laufwerk.
			txa
			jmp	LoadNewDisk

;*** Diskette wechseln.
:SetOpt1e		lda	curDrvMode
			and	#%00001000
			beq	:101
			lda	Target_Drv
			jmp	LoadNewDisk

::101			pla
			pla
			jsr	InsertNewDsk		;Neue Diskette einlegen.
			jmp	SetPrnOpt1		;Optionen anzeigen.

;*** Native-Verzeichnis wechseln.
:SetOpt1f		bit	DiskInDrv		;Diskette im Laufwerk ?
			bpl	:101			;Nein, weiter...
			lda	curDrvMode		;CMD-Laufwerk ?
;--- Ergänzung: 02.12.18/M.Kanet
;NativeMode ist auch auf Nicht-CMD-Laufwerken möglich.
;			bpl	:101
			and	#%00100000
			bne	:102			;Ja, weiter...
::101			rts

::102			pla
			pla
			jsr	ClrWin			;Bildschirm löschen.
			jsr	CMD_OtherNDir		;Partition wechseln.
			jmp	SetPrnOpt		;Optionen anzeigen.

;*** Anzahl Druckzeilen eingeben.
:SetOpt2a		lda	#$00			;Max. Anzahl Druckzeilen eingeben.
			asl
			tax
			lda	V408y1+0,x
			sta	a7L
			lda	V408y1+1,x
			sta	a7H
			jmp	InpOptNum

:DefOpt2a		jsr	GetMaxLine		;Max. Anzahl Druckzeilen ausgeben,
			ldy	#$00
			jmp	PutNumOnScrn

:GetMaxLine		lda	MaxPrnLines		;Max. Anzahl Druckzeilen einlesen,
			rts

:ChkMaxLine		CmpWI	r0,15			;Max. Anzahl Druckzeilen auf
			bcc	:101			;Gültigkeit prüfen.
			CmpWI	r0,256
			bcc	:102
::101			sec
			rts
::102			clc
			rts

:SetMaxLine		lda	r0L			;Max. Anzahl Druckzeilen festlegen.
			sta	MaxPrnLines
			rts

;*** Papiermodus ändern.
:SetOpt2b		lda	PaperType
			eor	#%11111111
			sta	PaperType
			rts

;*** Papiermodus anzeigen.
:DefOpt2b		bit	PaperType
			bpl	:101
			ldy	#$02
::101			rts

;*** Papiermodus ändern.
:SetOpt2c		lda	PrnDirMode
			eor	#%11111111
			sta	PrnDirMode
			rts

;*** Papiermodus anzeigen.
:DefOpt2c		bit	PrnDirMode
			bpl	:101
			ldy	#$02
::101			rts

;*** Druckertreiber anzeigen.
:DefOpt3a		lda	#$00			;Ausgabe-Fenster löschen.
			jsr	ShowClkOpt
			LoadW	r11,$0024		;Name Druckertreiber ausgeben.
			LoadB	r1H,$4e
			LoadW	r15,PrntFileName
			jsr	PrintText
::101			ldy	#$ff
			rts

;*** Druckertreiber wechseln
:SetOpt3b		pla
			pla
			jsr	ClrScreen
			jmp	SlctPrinter

;*** Icons ausgeben.
:ChangeIcon1		lda	#$48
			b $2c
:ChangeIcon2		lda	#$70
			b $2c
:ChangeIcon3		lda	#$98
			sta	:101 +6
::101			jsr	i_BitmapUp
			w	Icon_02
			b	$23,$68,$01,$08
			ldy	#$ff
			rts

;*** Zahlenwert ausgeben.
:PutNumOnScrn		pha
			tya
			asl
			tax
			lda	V408y0+0,x
			sta	a6L
			lda	V408y0+1,x
			sta	a6H

			lda	#$00			;Ausgabe-Fenster löschen.
			jsr	ShowClkOpt

			ldy	#$00
			lda	(a6L),y			;X-Koordinate für Zahlenausgabe.
			sta	r11L
			iny
			lda	(a6L),y
			sta	r11H
			iny
			lda	(a6L),y			;Y-Koordinate für Zahlenausgabe.
			sta	r1H

			jsr	UseGDFont		;GeoDOS-Zeichensatz aktivieren.
			ClrB	currentMode

			pla
			sta	r0L			;Zahl ausgeben.
			ClrB	r0H
			lda	#%11000000
			jsr	PutDecimal
			ldy	#$ff
			rts

;*** Zahl Eingeben.
:InpOptNum		PopW	V408u0			;Rücksprung-Adresse merken.

			lda	mouseOn			;Menüs & Icons aus.
			and	#%10011111
			sta	mouseOn
			ClrW	otherPressVec
			MoveW	a7,V408u1		;Zeiger auf Menütabelle merken.

;*** Neue Zahl eingeben.
:InpNOptNum		ldy	#$04			;Zahlenwert einlesen.
			jsr	CallNumRout
			sta	r15L
			ldy	#$06			;Zahlenwert nach ASCII wandeln.
			jsr	CallNumRout

			ldy	#$00
			lda	(a7L),y			;X-Koordinate für Eingabe.
			sta	r11L
			iny
			lda	(a7L),y
			sta	r11H
			iny
			lda	(a7L),y			;Y-Koordinate für Eingabe.
			sta	r1H

			jsr	UseGDFont
			ClrB	currentMode
			LoadW	r0,InputBuf		;Zeiger auf Eingabespeicher.
			LoadB	r1L,$00			;Standard-Fehler-Routine.
			LoadB	r2L,3
			LoadW	keyVector,:101		;Zeiger auf Abschluß-Routine.
			jsr	GetString
			jsr	InitForIO
			LoadB	$d028,$00
			jmp	DoneWithIO

;*** Eingabe abschließen.
::101			MoveW	V408u1,a7		;Zeiger auf Menütabelle zurücksetzen.

			ldy	#$08			;Eingabe nach HEX wandeln.
			jsr	CallNumRout

			ldy	#$0a			;Zahlenwert prüfen.
			jsr	CallNumRout
			bcc	:102			;Wert in Ordnung ? Ja, weiter.
			jsr	SetClkPos		;Alte Werte ausgeben.
			MoveW	V408u1,a7		;Zahl erneut eingeben.
			jmp	InpNOptNum

::102			ldy	#$0c			;Eingabe übernehmen.
			jsr	CallNumRout

			lda	mouseOn			;Icons aktivieren.
			ora	#%00100000
			sta	mouseOn
			LoadW	otherPressVec,ChkOptSlct

			jsr	SetHelp

			PushW	V408u0			;Rücksprung-Adresse wieder herstellen.
			rts

;*** $HEX nach ASCII wandeln.
:HEXtoASCII		lda	r15L
			sta	r0L
			lda	#$00
			sta	r0H
			sta	r1L
			jsr	ZahlToASCII

			ldy	#$00
::101			lda	ASCII_Zahl,y		;Word ab $0101 in Eingabespeicher
			beq	:102			;übertragen.
			sta	InputBuf,y
			iny
			cpy	#$03
			bne	:101
			lda	#$00			;Ende des Eingabespeichers
::102			sta	InputBuf,y		;markieren.
			rts

;*** ASCII nach $HEX-Word wandeln.
:ASCIItoHEX		ClrW	r0			;Word auf $0000 setzen.
			lda	InputBuf		;Eingabe-Speicher leer ?
			bne	:101			;Nein, weiter.
			rts

::101			ldy	#$01			;Länge der Zahl ermitteln.
::102			lda	InputBuf,y
			beq	:103
			iny
			bne	:102
			iny

::103			dey
			sty	r1L			;Länge der Zahl merken.
			ClrB	r1H			;Zeiger auf Dezimal-Stelle für 1er.

::104			ldy	r1L
			lda	InputBuf,y		;Zeichen aus Zahlenstring holen.
			sub	$30			;Reinen Zahlenwert (0-9) isolieren.
			bcc	:106			;Unterlauf, keine Ziffer.
			cmp	#$0a			;Wert >= 10 ?
			bcs	:106			;Ja, keine Ziffer.
			tax
			beq	:106			;Null ? Ja, weiter...

::105			ldy	r1H			;Je nach Dezimal-Stelle, 1er, 10er
			lda	InputData,y		;oder 100er addieren.
			clc
			adc	r0L
			sta	r0L
			lda	#$00
			adc	r0H
			sta	r0H
			dex				;Schleife bis Zahl = 0.
			bne	:105

::106			inc	r1H			;Weiter bis Zahlenende erreicht.
			dec	r1L
			bpl	:104
			rts

;*** Name der Hilfedatei.
:HelpFileName		b "12,GDH_CBM/Disk",NULL

;*** Variablen.
:curSubMenu		b $00
:PrnDirMode		b $00				;DirTyp-Modus.
:PaperType		b $00				;Papier-Modus.
:MaxPrnLines		b $40				;Anzahl Zeilen / Seite.
:PrinterInMem		b $00				;$FF = Druckertreiber im Speicher.
:DiskInDrv		b $00
:DirPrinted		b $00				;$00 = Kein Verzeichnis gedruckt.
:ReturnAdress		w $0000

:InputBuf		s $04
:InputData		b 1,10,100

:MenuText		w V408w0, V408w1, V408w2
:InfoText		w V408s0, V408s1, V408s2

if Sprache = Deutsch
:V408r0			b PLAINTEXT
			b GOTOXY
			w $0008
			b $06
			b "CBM  -  Verzeichnis drucken",NULL

:V408s0			b "Aktuelles Verzeichnis",NULL
:V408s1			b "Druckoptionen",NULL
:V408s2			b "Aktiver Druckertreiber",NULL
endif

if Sprache = Englisch
:V408r0			b PLAINTEXT
			b GOTOXY
			w $0008
			b $06
			b "CBM  -  Print directory",NULL

:V408s0			b "Current directory",NULL
:V408s1			b "Options",NULL
:V408s2			b "Current printer",NULL
endif

:V408t0			b $28,$2f
			w $0008,$005f
			b $28,$2f
			w $0068,$00af
			b $28,$2f
			w $00b8,$00f7

:V408u0			w $0000
:V408u1			w $0000

;*** Menügrafik.
if Sprache = Deutsch
:V408v0			b MOVEPENTO
			w $0000
			b $30
			b FRAME_RECTO
			w $013f
			b $b8
			b FRAME_RECTO
			w $0000
			b $c7

			b ESC_PUTSTRING
			w $000c
			b $2e
			b PLAINTEXT
			b "Verzeichnis"
			b GOTOX
			w $006c
			b "Optionen"
			b GOTOX
			w $00bc
			b "Drucker"

			b NULL
endif

if Sprache = Englisch
:V408v0			b MOVEPENTO
			w $0000
			b $30
			b FRAME_RECTO
			w $013f
			b $b8
			b FRAME_RECTO
			w $0000
			b $c7

			b ESC_PUTSTRING
			w $000c
			b $2e
			b PLAINTEXT
			b "Directory"
			b GOTOX
			w $006c
			b "Options"
			b GOTOX
			w $00bc
			b "Printer"

			b NULL
endif

if Sprache = Deutsch
;*** Menütexte.
:V408w0			b ESC_GRAPHICS
			b MOVEPENTO
			w $0018
			b $42
			b FRAME_RECTO
			w $0127
			b $54

			b MOVEPENTO
			w $0018
			b $6a
			b FRAME_RECTO
			w $0127
			b $7c

			b MOVEPENTO
			w $0018
			b $92
			b FRAME_RECTO
			w $0127
			b $a4

			b ESC_PUTSTRING
			w $0020
			b $42
			b PLAINTEXT
			b "Aktuelles Laufwerk"

			b GOTOXY
			w $0020
			b $6a
			b "Diskette/Partition"

			b GOTOXY
			w $0020
			b $92
			b "Verzeichnis"
			b NULL

:V408w1			b ESC_GRAPHICS
			b MOVEPENTO
			w $0018
			b $42
			b FRAME_RECTO
			w $0127
			b $5c

			b MOVEPENTO
			w $0018
			b $72
			b FRAME_RECTO
			w $0127
			b $a4

			b ESC_PUTSTRING
			w $0020
			b $42
			b PLAINTEXT
			b "Seitenlänge"

			b GOTOXY
			w $0020
			b $72
			b "Druckoptionen"

			b GOTOXY
			w $0020
			b $4e
			b "Druckzeilen pro Seite :"

			b GOTOXY
			w $0034
			b $7e
			b "Einzelblatt-Papier verwenden"

			b GOTOXY
			w $0034
			b $8e
			b "Ausführliches Verzeichnis drucken"
			b NULL

:V408w2			b ESC_GRAPHICS
			b MOVEPENTO
			w $0018
			b $42
			b FRAME_RECTO
			w $0127
			b $54

			b ESC_PUTSTRING
			w $0020
			b $42
			b PLAINTEXT
			b "Druckertreiber"
			b NULL
endif

if Sprache = Englisch
;*** Menütexte.
:V408w0			b ESC_GRAPHICS
			b MOVEPENTO
			w $0018
			b $42
			b FRAME_RECTO
			w $0127
			b $54

			b MOVEPENTO
			w $0018
			b $6a
			b FRAME_RECTO
			w $0127
			b $7c

			b MOVEPENTO
			w $0018
			b $92
			b FRAME_RECTO
			w $0127
			b $a4

			b ESC_PUTSTRING
			w $0020
			b $42
			b PLAINTEXT
			b "Current drive"

			b GOTOXY
			w $0020
			b $6a
			b "Disk/Partition"

			b GOTOXY
			w $0020
			b $92
			b "Directory"
			b NULL

:V408w1			b ESC_GRAPHICS
			b MOVEPENTO
			w $0018
			b $42
			b FRAME_RECTO
			w $0127
			b $5c

			b MOVEPENTO
			w $0018
			b $72
			b FRAME_RECTO
			w $0127
			b $a4

			b ESC_PUTSTRING
			w $0020
			b $42
			b PLAINTEXT
			b "Length of page"

			b GOTOXY
			w $0020
			b $72
			b "Options"

			b GOTOXY
			w $0020
			b $4e
			b "Lines per page :"

			b GOTOXY
			w $0034
			b $7e
			b "Use single-paper"

			b GOTOXY
			w $0034
			b $8e
			b "Additional informations"
			b NULL

:V408w2			b ESC_GRAPHICS
			b MOVEPENTO
			w $0018
			b $42
			b FRAME_RECTO
			w $0127
			b $54

			b ESC_PUTSTRING
			w $0020
			b $42
			b PLAINTEXT
			b "Printerdriver"
			b NULL
endif

;*** Datenliste für "Klick-Positionen".
:V408x0			w V408x1, V408x2, V408x3

:V408x1			b $48,$4f
			w $0020,$0117,DefOpt1a,$0000
			b $70,$77
			w $0020,$0117,DefOpt1b,SetOpt1b
			b $98,$9f
			w $0020,$0117,DefOpt1c,$0000
			b $48,$4f
			w $0118,$011f,ChangeIcon1,SetOpt1d
			b $70,$77
			w $0118,$011f,ChangeIcon2,SetOpt1e
			b $98,$9f
			w $0118,$011f,ChangeIcon3,SetOpt1f
			b NULL

:V408x2			b $48,$4f
			w $00d0,$00e7,DefOpt2a,SetOpt2a
			b $78,$7f
			w $0020,$0027,DefOpt2b,SetOpt2b
			b $88,$8f
			w $0020,$0027,DefOpt2c,SetOpt2c
			b NULL

:V408x3			b $48,$4f
			w $0020,$0117,DefOpt3a,$0000
			b $48,$4f
			w $0118,$011f,ChangeIcon1,SetOpt3b
			b NULL

;*** Menütabellen für Zahlenausgabe.
:V408y0			w V408z0

;*** Tabellen für Zahleneingabe.
:V408y1			w V408z1

;*** Max. Anzahl Zeilen.
:V408z0			w $00d2
			b $4e

:V408z1			w $00d2
			b $48
			w GetMaxLine
			w HEXtoASCII,ASCIItoHEX
			w ChkMaxLine
			w SetMaxLine

;*** Auswahlbox für Drucken.
:Icon_Tab1		b	2			;Druck-Optionen
			w	$0000
			b	$00

			w	Icon_00
			b	$00,$08,$05,$18
			w	ExitPrnMenu

			w	Icon_01
			b	$05,$08,$05,$18
			w	DoPrint

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

:Icon_02
<MISSING_IMAGE_DATA>

:EndProgrammCode

;*** Startadresse Zwischenspeicher.
;    Directory der aktuellen Diskette.
;    Berechnung Druckdaten.
:Memory1		s 80 +1
:Memory2		= ((Memory1+81) / 256 +1) * 256
