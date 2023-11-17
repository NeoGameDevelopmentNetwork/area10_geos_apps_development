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
endif

			n	"mod.#308.obj"
			o	ModStart
			q	EndProgrammCode
			r	EndAreaDOS

			jmp	DOS_PrnDir
			jmp	DOS_PrnCurDir

			t	"-GetDriver"
			t	"-DOS_SlctPrnDir"

;*** L306: Verzeichnis ausgeben.
:DOS_PrnDir		jsr	LookForPrnt

			lda	#$00
			sta	DOSInMem
			sta	DirType

			lda	Target_Drv
			jsr	LoadNewDisk		;Laufwerk aktivieren.
::101			jsr	PrintDir

			bit	DirPrinted		;Wurde ein Verzeichnis gedruckt ?
			bpl	:102			;Nein, Ende...
			DB_UsrBoxV306g5			;Abfrage: "Noch ein Verzeichnis ?"
			CmpBI	sysDBData,3
			beq	:101			;Nein, Ende...

::102			jmp	L306ExitGD		;Zurück zu GeoDOS.

;*** Aktuelles Verzeichnis drucken.
:DOS_PrnCurDir		lda	ModBuf+0
			sta	DirType

			jsr	i_MoveData
			w	Disk_Sek,Dir_Entry,32
			PopW	ReturnAdress2

			jsr	ClrScreen		;Drucker-Box löschen.
			jsr	LookForPrnt

			lda	#$ff
			sta	DOSInMem
			jsr	PrintDir

			PushW	ReturnAdress2
			jsr	i_MoveData
			w	Dir_Entry,Disk_Sek,32

			lda	DirType
			sta	ModBuf+0
			rts

;*** Directory drucken (aus Directory-Menü).
:PrintDir		PopW	ReturnAdress		;Rücksprungadresse vom Stapel holen.
:InitMenu		jmp	SetPrnOpt		;Menü aufbauen.

;*** Neue Diskette öffnen.
:LoadNewDisk		jsr	IsDskInDrv
			bit	DiskInDrv
			bpl	NoDOSinMem

:GetDOS			jsr	DOS_GetSys		;DOS-Verzeichnis einlesen.
			jsr	DOS_GetDskNam

			lda	#$ff
			b $2c
:NoDOSinMem		lda	#$00
			sta	DOSInMem
			ClrB	DirType
			rts

;*** Directory-Ausdruck beenden.
:L306ExitGD		jsr	ClrWin			;Bildschirm löschen.
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
;    AKKU = Anzahl Zeichen.
;    xReg = Flag für Datei/Verzeichnis.
;           $00 = NAME
;           $FF = NAME.EXT
:PrnFileName		sta	:104 +1			;Anzahl Zeichen merken.
			stx	:102 +1			;Datei/Verzeichnis-Flag merken.

			ldy	#$00			;Zeiger auf erstes Zeichen.
::101			sty	:103 +1			;Zähler zwischenspeichern.

			lda	(r15L),y		;Textende erreicht ?
			beq	:105			;Ja, Ende...
			jsr	ConvertChar		;Zeichen nach GEOS-ASCII wandeln.
			jsr	SmallPutChar		;Textzeichen ausgeben.

::102			ldx	#$ff			;Punkt ausgeben ?
			beq	:103			;Nein, weiter...
			ldy	:103 +1
			cpy	#$07			;Name komplett ?
			bne	:103			;Nein, weiter...

			lda	#"."
			jsr	SmallPutChar		;Punkt ausgeben.
::103			ldy	#$ff			;Zeiger auf Textstring zurücksetzen.
			iny				;Zeiger auf nächstes Zeichen.
::104			cpy	#$ff			;Alle Zeichen ausgegeben ?
			bne	:101			;Nein, weiter...
::105			rts

;******************************************************************************
;*** Directory drucken.
;******************************************************************************
;*** Zeiger auf Directory-Anfang.
:Do1stInit		lda	#$00
			sta	V306a0			;Anzahl Dateien löschen.
			sta	V306a1			;Zeiger auf Position #1.
			sta	V306a6			;Zeiger auf ersten Sektor im Cluster.
			sta	V306a7			;Zeiger auf ersten Eintrag.

			lda	#<Disk_Sek		;Zeiger auf DOS-Sektorspeicher.
			sta	V306a8 +0
			lda	#>Disk_Sek
			sta	V306a8 +1

			bit	DirType			;Unterverzeichnis ?
			bmi	:101			;Ja, Sonderbehandlung.

			jsr	GetMdrSek		;Anzahl Sektoren im Hauptverzeichnis.
			lda	MdrSektor+0
			sta	V306a5   +0
			lda	MdrSektor+1
			sta	V306a5   +1

			jsr	DefMdr			;Zeiger auf Anfang Hauptverzeichnis.
			jmp	:102

;*** Zeiger auf Unterverzeichnis.
::101			lda	Dir_Entry+26		;Cluster-Nummer lesen.
			ldx	Dir_Entry+27
			sta	V306a3+0		;Als ersten Cluster speichern.
			stx	V306a3+1
			sta	V306a4+0		;Als aktuellen Cluster speichern.
			stx	V306a4+1
			jsr	Clu_Sek			;Cluster umrechnen.

::102			MoveB	Seite ,V306a2+0
			MoveB	Spur  ,V306a2+1
			MoveB	Sektor,V306a2+2

			rts

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

;*** Aktuellen Directory-Sektor lesen.
:RdCurDirSek		MoveB	V306a2+0,Seite		;Zeiger auf Sektor richten.
			MoveB	V306a2+1,Spur
			MoveB	V306a2+2,Sektor
			LoadW	a8,Disk_Sek		;Zeiger auf Anfang Zwischenspeicher.
			jsr	D_Read			;Sektor lesen.
			txa
			beq	:101
			jmp	DiskError		;Disketten-Fehler.

::101			MoveW	V306a8,a8		;Zeiger auf aktuellen Eintrag.
			rts

;*** Nächsten Verzeichnis-Sektor lesen.
:RdNxDirSek		bit	DirType			;Hauptverzeichnis ?
			bmi	:102			;Nein, weiter...

			SubVW	1,V306a5		;Zähler Verzeichnis-Sektoren -1.
			CmpW0	V306a5			;Ende erreicht ?
			bne	:101			;Nein, weiter...
			sec				;Directory-Ende erreicht.
			rts

::101			jsr	Inc_Sek			;Zeiger auf nächsten Sektor.
			jmp	:104			;Nächsten Sektor lesen.

;*** Nächsten Sektor eines SubDirs einlesen.
::102			inc	V306a6			;Zeiger auf nächsten Sektor innerhalb
			CmpB	V306a6,SpClu		;des aktuellen Clusters.
			bne	:101			;Nächsten Sektor des Clusters lesen.

			ClrB	V306a6

			lda	V306a4+0		;Aktuelle Cluster-Nr. lesen.
			ldx	V306a4+1
			jsr	Get_Clu			;Zeiger auf nächsten Cluster.
			lda	r1L			;Nr. des neuen Clusters einlesen.
			ldx	r1H
			cmp	#$f7			;12-Bit-FAT.
			bcc	:103
			cpx	#$0f
			bcc	:103
			sec
			rts

::103			sta	V306a4+0
			stx	V306a4+1
			jsr	Clu_Sek			;Cluster umrechnen.

::104			MoveB	Seite ,V306a2+0
			MoveB	Spur  ,V306a2+1
			MoveB	Sektor,V306a2+2

			lda	#<Disk_Sek		;Zeiger auf Zwischenspeicher richten.
			sta	a8L
			sta	V306a8+0
			lda	#>Disk_Sek
			sta	a8H
			sta	V306a8+1

			jsr	D_Read			;Sektor lesen.
			txa
			beq	:105
			jmp	DiskError		;Diskettenfehler.

::105			stx	V306a7			;Zeiger auf ersten Eintrag.
			clc
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

;*** Directory drucken.
:DoPrint		bit	DOSInMem
			bmi	:101
			rts

::101			lda	#$01
			sta	LinesPerEntry

			jsr	ClrScreen		;Drucker-Box löschen.

			bit	PrinterInMem
			bmi	:102

			jsr	LookForPrnt

			bit	PrinterInMem
			bmi	:102

			DB_OK	V306g3			;Fehler: "Druckertreiber nicht ..."
			jmp	SetPrnOpt

::102			jsr	CheckPrinter
			txa
			beq	InitDirHead
			jmp	InitMenu

;*** Directory-Ausdruck initialisieren.
:InitDirHead		lda	Target_Drv
			jsr	NewDrive

			jsr	Do1stInit		;Zurück zum Verzeichnis-Anfang.
			ClrB	Page			;Zähler für Seiten-Nr. auf 0.

			jsr	InitHead1
			jsr	InitHead2

			StartMouse
			NoMseKey

			jsr	RdCurDirSek
			jsr	WaitNewPage
			beq	NewPage
			jmp	AbortPrint

;*** Einzelne Seite drucken.
:NewPage		jsr	PrintHeader

::101			lda	pressFlag		;Drucken abbrechen ?
			bne	:105			;Ja, zurück zum Directory-Modus.

			lda	CurPrnLine		;Noch Platz für einen Eintrag auf
			cmp	LinesPerEntry		;aktueller Seite ?
			bcs	:102

			jsr	StopPrint		;Seiten-Vorschub.
			jsr	ClrBox
			jsr	WaitNewPage		;Bei Einzel-Blatt, warten auf Papier.
			beq	NewPage			;Nein, nächste Seite.
			jmp	AbortPrint		;Zurück zum Directory-Modus.

::102			jsr	DirLine1		;Einzelne Druck-Zeile erzeugen.
			bmi	:103
			bne	:104			;Directory-Ende, Infos drucken.
			jsr	PrnASCIILine		;Eintrag ausgeben.
			dec	CurPrnLine		;Seite voll ?
::103			AddVBW	32,a8
			jmp	:101

::104			jsr	PrnDirInfo		;Directory-Informationen drucken.
			LoadB	DirPrinted,$ff
::105			jmp	ExitPrintDir

;*** Eintrag erzeugen.
:DirLine1		CmpBI	V306a7,16		;Alle Einträge eines Sektors
			bne	:102			;Nein, weiter...
			jsr	RdNxDirSek		;Nächsten Directory-Sektor einlesen.
			bcc	:101
			lda	#$7f			;Directory-Ende.
			rts

::101			txa				;Disketten-Fehler ?
			beq	:102			;Nein, weiter...
			pha
			jsr	StopPrint
			pla
			tax
			jmp	DiskError		;...und Disketten-Fehler ausgeben.

::102			inc	V306a7			;Zähler Einträge erhöhen.

			ldy	#$00			;Directory-Ende erreicht ?
			lda	(a8L),y
			bne	:104			;Nein, weiter...
			lda	#$7f			;Ja, Ende...
::103			rts

::104			jsr	TestDirEntry
			bne	:103

			jsr	i_FillRam
			w	$0007,Memory1
			b	$20

			ldx	#$07
			jsr	InsertName
			jsr	Ins2Space		;Zwei Leerzeichen einfügen.

			stx	:106 +1
			ldy	#$0b			;Auf Sub-Directory testen.
			lda	(a8L),y
			and	#%00010000
			beq	:105			;Kein SubDir, weiter...

			LoadW	r0,V306c5
			jmp	:106

::105			ldy	#$1c
			lda	(a8L),y
			sta	r0L
			iny
			lda	(a8L),y
			sta	r0H
			iny
			lda	(a8L),y
			sta	r1L
			jsr	ZahlToASCII
			LoadW	r0,ASCII_Zahl

::106			ldx	#$ff
			jsr	FileSize
			jsr	Ins2Space		;X-Koordinate korrigieren.

			jsr	GetBinDate
			jsr	InsertDate
			jsr	Ins2Space

			ldy	#$0b			;"Read-Only"-Status prüfen.
			lda	(a8L),y
			pha
			and	#%00000001
			beq	:107

			lda	#<V306c0
			ldy	#>V306c0
			jsr	CopyAttr

::107			pla				;"Hidden-Datei"-Status prüfen.
			pha
			and	#%00000010
			beq	:108

			lda	#<V306c1
			ldy	#>V306c1
			jsr	CopyAttr

::108			pla				;"System-Datei"-Status prüfen.
			and	#%00000100
			beq	:109

			lda	#<V306c2
			ldy	#>V306c2
			jsr	CopyAttr

::109			dex
			lda	#CR
			jsr	InsertASCII
			lda	#NULL
			jsr	InsertASCII
			lda	#$00
			rts

;*** Directory-Informationen drucken.
:PrnDirInfo		jsr	ChkInfoSpace
			beq	:101
			jsr	PrintHeader		;Bei neuer Seite, Seiten-Kopf drucken.
::101			jsr	GetDirInfo

			LoadB	Memory1 +0,$0d		;Eine Leerzeile ausgeben.
			LoadB	Memory1 +1,$00
			jsr	PrnASCIILine

			MoveB	DirFiles+0,r0L
			MoveB	DirFiles+1,r0H
			LoadW	r3,V306b4		;Anzahl Dateien im Directory.
			LoadB	r4L,39
			LoadB	r4H,8
			jsr	NumASCII_a
			MoveW	r3,r0
			jsr	PrnTempLine

			MoveB	UsedByte+0,r0L
			MoveB	UsedByte+1,r0H
			MoveB	UsedByte+2,r1L
			LoadW	r3,V306b5		;Anzahl Blocks im Directory.
			LoadB	r4L,39
			LoadB	r4H,8
			jsr	NumASCII_b
			MoveW	r3,r0
			jsr	PrnTempLine

			sec
			lda	FreeClu+0
			sbc	CountFreeClu
			sta	r2L
			lda	FreeClu+1
			sbc	CountFreeClu+1
			sta	r2H
			jsr	CalcBytes
			LoadW	r3,V306b6		;Anzahl belegter Blocks.
			LoadB	r4L,39
			LoadB	r4H,8
			jsr	NumASCII_b
			MoveW	r3,r0
			jsr	PrnTempLine

			MoveB	CountFreeClu+0,r0L
			MoveB	CountFreeClu+1,r0H
			LoadW	r3,V306b7		;Anzahl freier Sektoren.
			LoadB	r4L,39
			LoadB	r4H,8
			jsr	NumASCII_a
			MoveW	r3,r0
			jsr	PrnTempLine

			MoveB	CountFreeClu+0,r2L
			MoveB	CountFreeClu+1,r2H
			jsr	CalcBytes
			LoadW	r3,V306b8		;Gesamt-Anzahl Sektoren.
			LoadB	r4L,39
			LoadB	r4H,8
			jsr	NumASCII_b
			MoveW	r3,r0
			jsr	PrnTempLine

			MoveB	FreeByte+0,r0L
			MoveB	FreeByte+1,r0H
			MoveB	FreeByte+2,r1L
			LoadW	r3,V306b9		;Anschluß-Info.
			LoadB	r4L,39
			LoadB	r4H,8
			jsr	NumASCII_b
			MoveW	r3,r0
			jmp	PrnTempLine

;*** Diskettenkapazitäten ausgeben.
:GetDirInfo		lda	#$00
			sta	UsedByte+0		;Diskettenspeicher löschen.
			sta	UsedByte+1
			sta	UsedByte+2
			sta	UsedByte+3
			sta	DirFiles+0		;Anzahl Dateien löschen.
			sta	DirFiles+1

			jsr	Do1stInit		;Zum Verzeichnisanfang zurück.

::101			jsr	RdCurDirSek		;Aktuelen Verzeichnis-Sektor lesen.

::102			ldx	V306a7
			bne	:105
::103			stx	V306a7

			ldy	#$00			;Byte aus Eintrag lesen.
			lda	(a8L),y			;Byte = $00 = Verzeichnisende ?
			beq	:106			;Nein, weiter.
			cmp	#$e5			;Datei gelöscht ?
			beq	:104			;Ja, übergehen.

			jsr	AddBytes		;Dateigrößen addieren.

::104			AddVBW	32,a8
			ldx	V306a7
::105			inx
			cpx	#$10
			bne	:103

			jsr	RdNxDirSek		;Nächsten Directory-Sektor lesen.
			bcc	:102			;Weiteren Sektor gefunden ? Ja, weiter.

::106			jsr	Max_Free		;Gesamtspeicher berechnen.

			LoadW	a1,FAT			;Zeiger auf FAT bereitstellen.
			lda	#$00
			sta	CountClu+0		;Zähler Cluster Initialisieren.
			sta	CountClu+1
			sta	CountFreeClu+0		;Zähler freie Cluster Initialisieren.
			sta	CountFreeClu+1

::107			clc				;Zeiger auf Cluster in FAT setzen und
			lda	CountClu		;Zeiger einlesen.
			adc	#$02
			tay
			lda	CountClu+1
			adc	#$00
			tax
			tya
			jsr	Get_Clu

			CmpW0	r1			;Cluster frei ?
			bne	:108			;Nein, weiter...

			IncWord	CountFreeClu		;Anzahl freie Cluster um 1 erhöhen.
::108			IncWord	CountClu		;Zähler +1 bis alle Cluster geprüft.
			CmpW	CountClu,FreeClu
			bne	:107

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

;*** DOS: Erste Kopfzeile erzeugen.
:InitHead1		ldy	#$00			;Titel-Zeile in Zwischenspeicher.
::101			lda	V306b0,y
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
			sta	V306b0,y
			beq	:104
			iny
			bne	:103
::104			rts

;*** DOS: Zweite Kopfzeile erzeugen.
:InitHead2		jsr	DOS_GetDskNam		;Diskettenname einlesen.

			ldy	#0			;Disketten-Name in Titel-Zeile
::101			lda	dosDiskName,y		;eintragen.
			sta	V306b1 + 17,y
			iny
			cpy	#11
			bne	:101

			LoadW	r0,V306c3
			lda	DirType			;Directory-Typ testen.
			beq	:104			;Hauptverzeichnis ? Ja, weiter...
			lda	#"."			;Name des Unterverzeichnisses in
			sta	V306b1+44		;Titel-Zeile eintragen.
			sta	V306b1+45
			lda	#"/"
			sta	V306b1+46

			ldy	#0
			ldx	#0
::102			lda	Dir_Entry,y
			sta	V306b1+47,x
			inx
			cpy	#7
			bne	:103
			inx
::103			iny
			cpy	#11
			bne	:102

			LoadW	r0,V306c4
::104			ldy	#$00
::105			lda	(r0L),y
			beq	:106
			sta	V306b1+32,y
			iny
			bne	:105

::106			rts

;*** Seiten-Kopf drucken.
:PrintHeader		jsr	InitPrint1

			lda	MaxPrnLines		;Anzahl Zeilen pro Seite berechnen.
			sub	$05
::101			sta	CurPrnLine

			jsr	InitPrint2

			LoadW	r0,V306b1
			jsr	PrnTempLine
			LoadW	r0,V306b2
			jsr	PrnTempLine
			LoadW	r0,V306b3
			jmp	PrnTempLine

;*** ASCII-Zeile drucken.
:PrnASCIILine		LoadW	r0,Memory1
:PrnTempLine		LoadW	r1,FileNTab
			jmp	PrintASCII

;*** Seite auswerfen und Ausdruck beenden.
:ExitPrintDir		jsr	StopPrint		;Seiten-Vorschub...
			jsr	ClrBox
			jmp	AbortPrint

;*** Noch Platz auf aktueller Seite für Verzeichnis-Infos ?
:ChkInfoSpace		lda	CurPrnLine		;Noch Platz für 8 Zeilen ?
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
			DB_UsrBoxV306g4 			;Drucker nicht verfügbar.
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
			stx	V306b1+75
			sta	V306b1+76

			LoadW	r0,V306b0		;Header ausdrucken.
			jmp	PrnTempLine

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
			sta	DateDMem+2

			RORZWordr15L,5

			lda	r15L			;Monat berechnen.
			and	#%00001111
			sta	DateDMem+1

			RORZWordr15L,4

			lda	r15L			;Jahr berechnen.
			and	#%01111111
			clc
			adc	#80
			sta	DateDMem+0

			ldy	#$16			;Uhrzeit berechnen.
			lda	(a8L),y
			sta	r15L
			iny
			lda	(a8L),y
			sta	r15H

			RORZWordr15L,5

			lda	r15L			;Minute berechnen.
			and	#%00111111
			sta	DateDMem+4

			RORZWordr15L,6

			lda	r15L			;Stunde berechnen.
			and	#%00011111
			sta	DateDMem+3

			pla
			tay
			pla
			tax
			pla
			rts

;*** Info: "Seite wird gedruckt..."
:InfoPrnPage		jsr	DoInfoBox
			PrintStrgV306g0
			rts

;*** Warten auf neues Blatt Papier...
:WaitNewPage		lda	PaperType		;Einzelblatt-Modus ?
			beq	:1			;Ja, Info-Box.
			jsr	ClrBox
			DB_UsrBoxV306g2
			CmpBI	sysDBData,1
			beq	:1

			lda	#$ff
			rts
::1			lda	#$00
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
:FileSize		lda	#$09
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
:UsedByte		s $04				;Anzahl verbrauchter Bytes.
:CountClu		w $0000				;Zähler für ":CalcFreeClu".
:CountFreeClu		w $0000				;Zähler für ":CalcFreeClu".
:DirFiles		w $0000				;Anzahl Files

:CurPrnLine		b $00				;Anzahl Zeilen während Druckvorgang.
:LinesPerEntry		b $00				;Benötigte Druckzeilen für einen Dateieintrag.
:Page			b $00				;Seiten-Nr.

:DateDMem		s $05				;Speicher für Datum.

:V306a0			b $00				;Anzahl Einträge im RAM.
:V306a1			b $00				;Zeiger auf Eintrag im RAM.
:V306a2			s $03				;Seite,Spur,Sektor.
:V306a3			w $0000				;Start-Cluster Unterverzeichnis.
:V306a4			w $0000				;Cluster-Nummer im Unterverzeichnis.
:V306a5			w $0000				;Anzahl Sektoren im Hauptverzeichnis.
:V306a6			b $00				;Aktueller Sektor in Cluster.
:V306a7			b $00				;Zeiger auf Eintrag im Sektor.
:V306a8			w $0000				;Adresse Eintrag in Verzeichnis-Sektor.

;*** Texte für "DOS:Verzeichnis drucken"
if Sprache = Deutsch
:V306b0			b "       GeoDOS - Directory                   Erstellt am "
			b "xx.xx.xx um xx:xx Uhr",$0d,NULL
:V306b1			b "       Diskette: xxxxxxxxxxx                            "
			b "            Seite: xx",$0d,$0d,NULL
:V306b2			b "       Datei-Name    Länge      Datum     Zeit   "
			b "Attribute",$0d,NULL
:V306b3			b "       ------------------------------------------"
			b "----------------------------",$0d,NULL
:V306b4			b "       Anzahl Dateien im Verzeichnis : xxxxxxxx",$0d,NULL
:V306b5			b "       Bytes im Verzeichnis          : xxxxxxxx"
			b " Bytes",$0d,NULL
:V306b6			b "       Belegter Speicher             : xxxxxxxx"
			b " Bytes",$0d,NULL
:V306b7			b "       Freie Cluster                 : xxxxxxxx",$0d,NULL
:V306b8			b "       Verfügbarer Speicher          : xxxxxxxx"
			b " Bytes",$0d,NULL
:V306b9			b "       Speicher gesamt               : xxxxxxxx"
			b " Bytes"
:V306b10		b $0d,NULL

:V306c0			b "Read-Only",NULL
:V306c1			b "Versteckt",NULL
:V306c2			b "System",NULL
:V306c3			b "Hauptverzeichnis           "								,NULL
:V306c4			b "Verzeichnis:"									,NULL
:V306c5			b "<Sub Dir>",NULL
endif

if Sprache = Englisch
:V306b0			b "       GeoDOS - Directory                   Erstellt am "
			b "xx.xx.xx um xx:xx ",$0d,NULL
:V306b1			b "       Disk    : xxxxxxxxxxx                            "
			b "            Page : xx",$0d,$0d,NULL
:V306b2			b "       Filename      Length     Date      Time   "
			b "Attributes",$0d,NULL
:V306b3			b "       ------------------------------------------"
			b "----------------------------",$0d,NULL
:V306b4			b "       Files in directory            : xxxxxxxx",$0d,NULL
:V306b5			b "       Bytes in directory            : xxxxxxxx"
			b " Bytes",$0d,NULL
:V306b6			b "       Allocated diskspace           : xxxxxxxx"
			b " Bytes",$0d,NULL
:V306b7			b "       Free cluster                  : xxxxxxxx",$0d,NULL
:V306b8			b "       Available cluster             : xxxxxxxx"
			b " Bytes",$0d,NULL
:V306b9			b "       Disksize                      : xxxxxxxx"
			b " Bytes"
:V306b10		b $0d,NULL

:V306c0			b "Read-Only",NULL
:V306c1			b "Hidden",NULL
:V306c2			b "System",NULL
:V306c3			b "Root-directory             "								,NULL
:V306c4			b "Directory  :"									,NULL
:V306c5			b "<Sub Dir>",NULL
endif

if Sprache = Deutsch
;*** Info: "Seite wird gedruckt..."
:V306g0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Bitte warten!"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "Seite wird gedruckt..."
			b NULL

;*** Hinweis: "Bitte neues Blatt Papier einlegen!"
:V306g2			w :101, :102, ISet_Info
			b CANCEL,OK
::101			b BOLDON,"Bitte ein neues Blatt",NULL
::102			b        "Papier einlegen!",NULL

;*** Hinweis: "Kann Druckertreiber nicht finden!"
:V306g3			w :101, :102, ISet_Achtung
::101			b BOLDON,"Kann Druckertreiber",NULL
::102			b        "nicht finden!",NULL

;*** Hinweis: "Drucker nicht ansprechbar!"
:V306g4			w :101, :102, ISet_Achtung
			b CANCEL,OK
::101			b BOLDON,"Der Drucker ist nicht",NULL
::102			b        "ansprechbar !",NULL

;*** Hinweis: "Noch ein Verzeichnis drucken ?"
:V306g5			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Möchten Sie noch ein",NULL
::102			b        "Verzeichnis drucken ?",NULL
endif

if Sprache = Englisch
;*** Info: "Seite wird gedruckt..."
:V306g0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Please wait!"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "Printing directory..."
			b NULL

;*** Hinweis: "Bitte neues Blatt Papier einlegen!"
:V306g2			w :101, :102, ISet_Info
			b CANCEL,OK
::101			b BOLDON,"Please insert a new",NULL
::102			b        "paper into printer!",NULL

;*** Hinweis: "Kann Druckertreiber nicht finden!"
:V306g3			w :101, :102, ISet_Achtung
::101			b BOLDON,"Cannot find current",NULL
::102			b        "printerdriver!",NULL

;*** Hinweis: "Drucker nicht ansprechbar!"
:V306g4			w :101, :102, ISet_Achtung
			b CANCEL,OK
::101			b BOLDON,"Printer is not",NULL
::102			b        "available !",NULL

;*** Hinweis: "Noch ein Verzeichnis drucken ?"
:V306g5			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Would you like to print",NULL
::102			b        "another directory ?",NULL
endif

;*** Drucker wählen.
:SlctPrinter		PushB	curDrive
			jsr	OpenSysDrive
			jsr	SelectPrinter		;Durckertreiber wählen.
			jsr	LoadPrntDrv		;Druckertreiber einlesen.
			jsr	Ld2DrvData		;Laufwerks-I/O wieder herstellen.
			pla
			jsr	NewDrive
			jmp	SetPrnOpt		;Druckoptionen.

;*** Laufwerke ermitteln.
:LookForPrnt		jsr	DoInfoBox		;Info: "Treiber werden eingelesen..."
			PrintStrgV306r1

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
:SetPrnOpt		lda	Target_Drv		;Laufwerk aktivieren.
			jsr	IsDskInDrv

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

;*** Neue Diskette einlegen.
:InsertNewDsk		jsr	ClrWin			;Bildschirm löschen.

			lda	Target_Drv		;Diskette einlegen.
			ldx	#$ff
			jsr	InsertDisk
			cmp	#$01
			beq	:101

			ldx	#$00
			rts

::101			ldx	#$ff
			rts

;*** Diskette im Laufwerk ?
:IsDskInDrv		sta	Target_Drv		;Neues Ziel-Laufwerk festlegen.
			jsr	NewDrive		;Laufwerk aktivieren.

			jsr	CheckDiskDOS
			txa				;Fehler ?
			beq	:101			;Nein, weiter...
			lda	#$ff			;Keine Diskette!
::101			eor	#%11111111
			sta	DiskInDrv
			bne	:102
			sta	DOSInMem
::102			rts

;*** Fenster aufbauen.
:Bildschirm_a		jsr	ClrScreen		;Bildschirm löschen.

			jsr	i_C_MenuTitel
			b	$00,$00,$28,$01
			jsr	i_C_MenuBack
			b	$00,$01,$28,$18

			FillPRec$00,$00,$07,$0008,$013f

			jsr	UseGDFont		;Titel ausgeben.
			Print	$0008,$06
if Sprache = Deutsch
			b	PLAINTEXT,"PCDOS  -  Verzeichnis drucken",NULL
endif
if Sprache = Englisch
			b	PLAINTEXT,"PCDOS  -  Print directory",NULL
endif

			LoadW	r0,V306v0		;Menügrafik zeichnen.
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
			b	$01,$06,$26,$11
			FillPRec$00,$31,$ae,$0009,$0136

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
			lda	V306x0+0,x
			sta	a7L
			lda	V306x0+1,x
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
			adc	#<V306t0
			sta	a7L
			lda	#$00
			adc	#>V306t0
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
::101			lda	(a7L),y
			sta	r2,y
			dey
			bpl	:101
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

			lda	curDrive		;Laufwerksbezeichnung ausgeben.
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
			lda	#8
			jsr	PrnFileName
			ldy	#$ff
			rts

;*** Diskettenname anzeigen.
:DefOpt1b		lda	#$00			;Ausgabe-Fenster löschen.
			jsr	ShowClkOpt

			bit	DiskInDrv		;Diskette im Laufwerk ?
			bpl	:101			;Nein, weiter...
			bit	DOSInMem		;Diskette im Laufwerk ?
			bmi	:102			;Nein, weiter...
::101			Print	$0024,$76
if Sprache = Deutsch
			b	PLAINTEXT,"(Keine Diskette)",NULL
endif
if Sprache = Englisch
			b	PLAINTEXT,"(No disk)       ",NULL
endif
			jmp	:103

::102			LoadW	r15,dosDiskName
			LoadW	r11,$0024		;Diskettenname ausgeben.
			LoadB	r1H,$76
			lda	#11
			jsr	PrnFileName
::103			ldy	#$ff
			rts

;*** Verzeichnisname anzeigen.
:DefOpt1c		lda	#$00			;Ausgabe-Fenster löschen.
			jsr	ShowClkOpt
			bit	DiskInDrv		;Diskette im Laufwerk ?
			bpl	:102			;Nein, weiter...
			bit	DOSInMem		;Diskette im Laufwerk ?
			bpl	:102			;Nein, weiter...
			bit	DirType
			bmi	:101

			Print	$0024,$9e
if Sprache = Deutsch
			b	PLAINTEXT,"(Hauptverzeichnis)",NULL
endif
if Sprache = Englisch
			b	PLAINTEXT,"(Root-directory  )",NULL
endif
			jmp	:102

::101			LoadW	r15,Dir_Entry
			LoadW	r11,$0024		;Diskettenname ausgeben.
			LoadB	r1H,$9e
			lda	#12
			jsr	PrnFileName
::102			ldy	#$ff
			rts

;*** Laufwerk wechseln.
:SetOpt1d		pla
			pla

			ldx	Target_Drv		;Zeiger auf nächstes Laufwerk.
::101			inx
			cpx	#12			;Letztes Laufwerk erreicht ?
			bcc	:102			;Nein, weiter...
			ldx	#8			;Laufwerk #8 aktivieren.
::102			lda	DriveTypes-8,x		;Laufwerk verfügbar ?
			beq	:101			;Nein, nächstes Laufwerk.
			lda	DriveModes-8,x
			and	#%00010000
			beq	:101
			txa

			cmp	Target_Drv
			beq	:103
			ldx	#$00
			stx	DiskInDrv
			stx	DOSInMem

::103			jsr	LoadNewDisk
			jmp	SetPrnOpt1		;Optionen anzeigen.

;*** Diskette wechseln.
:SetOpt1e		pla
			pla
			jsr	InsertNewDsk
			txa
			sta	DiskInDrv
			bpl	:101
			lda	Target_Drv
			jsr	IsDskInDrv
			bit	DiskInDrv
			bpl	:101
			jsr	GetDOS
::101			jmp	SetPrnOpt1		;Optionen anzeigen.

;*** Verzeichnis wechseln.
:SetOpt1f		bit	DiskInDrv		;Diskette im Laufwerk ?
			bmi	:101			;Nein, weiter...
			rts

::101			pla
			pla
			jsr	ClrWin

			bit	DOSInMem
			bmi	:102
			jsr	DOS_GetSys		;DOS-Verzeichnis einlesen.
			jsr	DOS_GetDskNam
			LoadB	DOSInMem,$ff

::102			LoadW	r14,V306r2		;Titel-Zeile.
			jsr	SlctSubDir		;Verzeichnisse einlesen.
			tax
			beq	:103
			jmp	L306ExitGD		;Zurück zu GeoDOS.

::103			MoveB	r0L,DirType
			jmp	SetPrnOpt1		;Optionen anzeigen.

;*** Anzahl Druckzeilen eingeben.
:SetOpt2a		lda	#$00			;Max. Anzahl Druckzeilen eingeben.
			asl
			tax
			lda	V306y1+0,x
			sta	a7L
			lda	V306y1+1,x
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

;*** Druckertreiber anzeigen.
:DefOpt3a		lda	#$00			;Ausgabe-Fenster löschen.
			jsr	ShowClkOpt
			PrintXY	$0024,$4e,PrntFileName
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
			lda	V306y0+0,x
			sta	a6L
			lda	V306y0+1,x
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
:InpOptNum		PopW	V306u0			;Rücksprung-Adresse merken.

			lda	mouseOn			;Menüs & Icons aus.
			and	#%10011111
			sta	mouseOn
			ClrW	otherPressVec
			MoveW	a7,V306u1		;Zeiger auf Menütabelle merken.

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
::101			MoveW	V306u1,a7		;Zeiger auf Menütabelle zurücksetzen.

			ldy	#$08			;Eingabe nach HEX wandeln.
			jsr	CallNumRout

			ldy	#$0a			;Zahlenwert prüfen.
			jsr	CallNumRout
			bcc	:102			;Wert in Ordnung ? Ja, weiter.
			jsr	SetClkPos		;Alte Werte ausgeben.
			MoveW	V306u1,a7		;Zahl erneut eingeben.
			jmp	InpNOptNum

::102			ldy	#$0c			;Eingabe übernehmen.
			jsr	CallNumRout

			lda	mouseOn			;Icons aktivieren.
			ora	#%00100000
			sta	mouseOn
			LoadW	otherPressVec,ChkOptSlct

			jsr	SetHelp

			PushW	V306u0			;Rücksprung-Adresse wieder herstellen.
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

;*** Variablen.
:HelpFileName		b "09,GDH_DOS/Disk",NULL

:curSubMenu		b $00
:DirType		b $00				;$00 = Root, $FF = SubDir
:PrnDirMode		b $00				;DirTyp-Modus.
:PaperType		b $00				;Papier-Modus.
:MaxPrnLines		b $40				;Anzahl Zeilen / Seite.
:PrinterInMem		b $00				;$FF = Druckertreiber im Speicher.
:DiskInDrv		b $00
:DOSInMem		b $00				;$FF = DOS-Infos eingelesen.
:DirPrinted		b $00				;$00 = Kein Verzeichnis gedruckt.
:ReturnAdress		w $0000
:ReturnAdress2		w $0000

:InputBuf		s $04
:InputData		b 1,10,100

:MenuText		w V306w0, V306w1, V306w2
:InfoText		w V306s0, V306s1, V306s2

if Sprache = Deutsch
;*** Info: "Druckertreiber wird geladen..."
:V306r1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Druckertreiber wird"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "geladen...", NULL

;*** Titel für Verzeichnisauswahl.
:V306r2			b PLAINTEXT,"Verzeichnis wählen",NULL

;*** Fußzeilentexte.
:V306s0			b "Aktuelles Verzeichnis",NULL
:V306s1			b "Druckoptionen",NULL
:V306s2			b "Aktiver Druckertreiber",NULL
endif

if Sprache = Englisch
;*** Info: "Druckertreiber wird geladen..."
:V306r1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Loading"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "printerdriver...", NULL

;*** Titel für Verzeichnisauswahl.
:V306r2			b PLAINTEXT,"Select directory",NULL

;*** Fußzeilentexte.
:V306s0			b "Current directory",NULL
:V306s1			b "Options",NULL
:V306s2			b "Current printerdriver",NULL
endif

:V306t0			b $28,$2f
			w $0010,$0067
			b $28,$2f
			w $0070,$00b7
			b $28,$2f
			w $00c0,$00ff

:V306u0			w $0000
:V306u1			w $0000

if Sprache = Deutsch
;*** Menügrafik.
:V306v0			b MOVEPENTO
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
;*** Menügrafik.
:V306v0			b MOVEPENTO
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
:V306w0			b ESC_GRAPHICS
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
			b "Diskettenname"

			b GOTOXY
			w $0020
			b $92
			b "Verzeichnis"
			b NULL

:V306w1			b ESC_GRAPHICS
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
			b NULL

:V306w2			b ESC_GRAPHICS
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
:V306w0			b ESC_GRAPHICS
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
			b "Diskname"

			b GOTOXY
			w $0020
			b $92
			b "Directory"
			b NULL

:V306w1			b ESC_GRAPHICS
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
			b NULL

:V306w2			b ESC_GRAPHICS
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
:V306x0			w V306x1, V306x2, V306x3

:V306x1			b $48,$4f
			w $0020,$0117,DefOpt1a,$0000
			b $70,$77
			w $0020,$0117,DefOpt1b,$0000
			b $98,$9f
			w $0020,$0117,DefOpt1c,$0000
			b $48,$4f
			w $0118,$011f,ChangeIcon1,SetOpt1d
			b $70,$77
			w $0118,$011f,ChangeIcon2,SetOpt1e
			b $98,$9f
			w $0118,$011f,ChangeIcon3,SetOpt1f
			b NULL

:V306x2			b $48,$4f
			w $00d0,$00e7,DefOpt2a,SetOpt2a
			b $78,$7f
			w $0020,$0027,DefOpt2b,SetOpt2b
			b NULL

:V306x3			b $48,$4f
			w $0020,$0117,DefOpt3a,$0000
			b $48,$4f
			w $0118,$011f,ChangeIcon1,SetOpt3b
			b NULL

;*** Menütabellen für Zahlenausgabe.
:V306y0			w V306z0

;*** Tabellen für Zahleneingabe.
:V306y1			w V306z1

;*** Max. Anzahl Zeilen.
:V306z0			w $00d2
			b $4e

:V306z1			w $00d2
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
