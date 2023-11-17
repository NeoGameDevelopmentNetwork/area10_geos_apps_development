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

			n	"mod.#220.obj"
			o	ModStart

			jmp	DoCBMtoCBMF

;*** Quell- und Ziel-Laufwerk setzen.
			t   "-SetDriveCBM"

;*** L220: Datei von CBM nach CBM kopieren
:ConvTabBase		= SCREEN_BASE
:File_Name		= SCREEN_BASE +256
:File_Datum		= File_Name   +256*16

:EndBuffer		= $7000

;A2  = Zeiger auf Datei-Namen.
;A3  = Zeiger auf Datei-Datum.

:DoCBMtoCBMF		tsx
			stx	StackPointer

;*** Ausgabe-Fenster.
:DoCopyBox		jsr	UseGDFont 		;Bildschirm Initialisieren.
			Display	ST_WR_FORE

			FillPRec$00,$b8,$c7,$0000,$013f
			jsr	i_ColorBox
			b	$00,$00,$28,$17,$00
			jsr	i_ColorBox
			b	$00,$17,$28,$02,$36

			PrintXY	  6,190,V220a0
			PrintXY	  6,198,V220a1
			PrintXY	219,190,V220a2

			StartMouse			;Maus-Modus aktivieren.
			NoMseKey

			LoadW	a2,File_Name		;Zeiger auf Dateinamen.
			LoadW	a3,File_Datum		;Zeiger auf Dateidaten.

			lda	Target_Drv		;Ziel-Laufwerk aktivieren.
			jsr	NewDrive

			ldx	#$01			;Zeiger auf ersten Sektor für
			ldy	#$00			;Suche nach nächstem freien Sektor.
			lda	curDrvMode
			and	#%00100000		;Native-Mode-Laufwerk ?
			beq	:101			;Nein, weiter...
;--- Ergänzung: 02.12.18/M.Kanet
;Sektorsuche ab TR01/SE64 = CMD-Standard.
;			inx				;Suche ab $02/$00 starten.
			ldy	#64			;Suche ab $01/$40 starten.
::101			stx	NxFreeSek+0
			sty	NxFreeSek+1

;*** Dateien kopieren.
:CopyFiles		lda	pressFlag		;Abbruch durch Maus-Klick ?
			bne	L220ExitGD		;Ja, ende...

			lda	AnzahlFiles		;Alle Dateien kopiert ?
			beq	L220ExitGD		;Ja, ende...

			jsr	i_FillRam		;Variablenspeicher löschen.
			w	(EndVarMem-StartVarMem)
			w	StartVarMem
			b	$00

			jsr	PrintName		;Datei-Name ausgeben.
			jsr	StartCopy		;Einzel-Datei kopieren.
			txa				;Diskettenfehler ?
			bne	ExitDskErr		;Abbruch!

::101			AddVBW	16,a2			;Zeiger auf nächste Datei.
			AddVBW	10,a3

			dec	AnzahlFiles		;Alle Dateien kopiert ?
			bne	CopyFiles		;Nein, weiter...

;*** Ende. Zurück zu GeoDOS.
:L220ExitGD		jsr	SetTarget
			jsr	SetGDScrnCol
			jsr	ClrScreen		;Bildschirm löschen.
			jmp	InitScreen		;Zurück zu GeoDOS.

;*** Diskettenfehler, Abbruch.
:ExitDskErr		stx	:101 +1
			jsr	SetGDScrnCol
			jsr	ClrScreen		;Bildschirm löschen.
			ldx	StackPointer
			txs
::101			ldx	#$ff
			jmp	vCopyError

;*** Dateiname ausgeben.
:PrintName		Pattern	0			;Text-Fenster löschen.
			FillRec	184,199, 80,218
			FillRec	184,191,293,319
			FillRec	192,199,219,319

			ldy	#$00
::101			lda	(a2L),y			;Dateiname in Zwischenspeicher für
			sta	FileName,y		;Verzeichniseintrag übertragen.
			bne	:102
			lda	#$a0
::102			sta	DirEntry  +3,y
			iny
			cpy	#$10
			bne	:101

			PrintXY	80,190,FileName		;Datei-Name ausgeben.

			LoadW	r11,293			;Anzahl der noch zu kopierenden
			ldx	AnzahlFiles		;Dateien ausgeben.
			dex
			stx	r0L
			ClrB	r0H
			lda	#%11000000
			jmp	PutDecimal

;*** Dateilänge -1
:Sub1FileLen		CmpW0	File1Len		;Alle Blocks kopiert ?
			beq	:101			;Ja, übergehen.
			SubVW	1,File1Len		;Anzahl Blocks -1.
::101			rts

;*** CopyInfo ausgeben.
:CopyInfo		jsr	DoneWithIO		;GEOS-Kernal aktivieren.

			LoadW	r11,80			;Anzahl noch zu kopiernder Blocks
			LoadB	r1H,198			;ausgeben.
			MoveW	File1Len,r0
			ClrB	r1L
			ldy	#$09
			jsr	DoZahl24Bit

			jmp	Reset_IO		;GEOS-Turbo & Laufwerk aktivieren.

;*** VLIR-Datensatz ausgeben.
:PrintVLIR		jsr	DoneWithIO		;GEOS-Kernal aktivieren.

			lda	DirEntry +21		;Dateiformat bestimmen.
			bne	:101			;VLIR-Datei, -> Datensatz ausgeben.

			PrintXY	219,198,V220a4		;"Sequentiell" ausgeben.

			jmp	Reset_IO		;GEOS-Turbo & Laufwerk aktivieren.

::101			PrintXY	219,198,V220a3		;"VLIR: (Datensatz) " ausgeben.

			LoadW	r11,293
			lda	LastReadRec
			sub	1
			lsr
			sta	r0L
			ClrB	r0H
			lda	#%11000000
			jsr	PutDecimal

;*** Laufwerk wieder aktivieren.
:Reset_IO		jsr	EnterTurbo		;GEOS-Turbo aktivieren.
			stx	:101 +1			;Fehler-Nr. merken.
			jsr	InitForIO		;I/O aktivieren.
::101			ldx	#$ff
			rts

;*** BAM der Ziel-Diskette "updaten".
:IO_Update		jsr	DoneWithIO		;GEOS-Kernal aktivieren.

			jsr	PutDirHead		;BAM aktualisieren.
			txa				;Diskettenfehler ?
			bne	ExitNewDrive		;Ja, Abbruch...

			jsr	SetSource		;Quell-Laufwerk aktivieren.
			jmp	DiskOpened		;GEOS-Turbo & Laufwerk aktivieren.

;*** Quell/Ziel-Laufwerk aktivieren.
:IO_SetSource		jsr	DoneWithIO
			jsr	SetSource
			jmp	DiskOpened

:IO_SetTarget		jsr	DoneWithIO
			jsr	SetTarget

;*** Diskette geöffnet.
:DiskOpened		txa
			bne	ExitNewDrive
			jsr	EnterTurbo
			txa
:ExitNewDrive		pha
			jsr	InitForIO
			pla
			tax
			rts

;*** Einzeldatei kopieren.
:StartCopy		jsr	SetSource		;Quell-Laufwerk aktivieren.

			ldy	#$07
			lda	(a3L),y
			sta	r1L
			iny
			lda	(a3L),y
			sta	r1H
			iny
			lda	(a3L),y
			sta	:102 +1
			LoadW	r4,diskBlkBuf		;Verzeichnis-Sektor mit aktuellem
			jsr	GetBlock		;Directory-Eintrag einlesen.
			txa				;Diskettenfehler ?
			beq	:102			;Nein, weiter...
::101			jmp	ExitDskErr

::102			ldx	#$ff			;Zeiger auf Eintrag wieder
							;herstellen.

			ldy	#$00
::103			lda	diskBlkBuf,x		;Datei-Eintrag in Zwischenspeicher
			sta	DirEntry  ,y		;kopieren.
::104			inx
			iny
			cpy	#3
			bcc	:103
			cpy	#19
			bcc	:104
			cpy	#30
			bne	:103

			ldy	#$04
::105			lda	(a3L),y			;Datum-/Uhrzeit für Ziel-Datei
			sta	DirEntry+23,y		;festlegen.
			dey
			bpl	:105

			lda	DirEntry +28		;Dateilänge Quell-Datei als
			sta	File1Len + 0		;Zähler initialisieren.
			lda	DirEntry +29
			sta	File1Len + 1

			jsr	EnterTurbo		;GEOS-Turbo aktivieren.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch...

			jsr	InitForIO		;I/O aktivieren.

			lda	#$00
			sta	FreeSekBuf +0
			sta	File2Len   +0		;Länge der Zieldatei löschen.
			sta	File2Len   +1

			lda	DirEntry +22		;Dateityp = $00 ?
			beq	:106			; -> Ja, keine GEOS-Datei.

			jsr	GetInfoSek		;Track/Sektor Infoblock einlesen.
			jsr	SetInfoMem		;Zeiger auf Speicher für Infoblock.
			jsr	ReadBlock		;Infoblock einlesen.
			txa				;Diskettenfehler ?
			bne	:107			;Ja, Abbruch...

			jsr	Sub1FileLen		;Blockzähler -1.

			lda	DirEntry +21		;Dateiformat bestimmen.
			beq	:106
			jmp	FileIsVLIR		; -> VLIR-Datei kopieren.
::106			jmp	FileIsSEQ		; -> SEQ -Datei kopieren.
::107			jmp	DoneWithIO		;Fehler!

;*** Seq. Datei kopieren.
:FileIsSEQ		jsr	GetHeaderSek		;Zeiger auf ersten Sektor einlesen.
			beq	:104			;Sektor verfügbar ? Nein, Ende...

::101			jsr	SetDataTop		;Zeiger auf Startadresse Datenspeicher.
			jsr	LoadFileData		;Sektor-Kette in Speicher einlesen.
			txa				;Diskettenfehler ?
			bne	:106			;Ja, Abbruch...

			MoveW	r1,NextSekBuf		;Nächsten Sektor merken.

			jsr	IO_SetTarget		;Ziel-Laufwerk öffnen.
			txa				;Diskettenfehler ?
			bne	:106			;Ja, Abbruch...

			lda	FreeSekBuf +0		;Startsektor für Sektorsuche schon
			bne	:102			;festgelegt ? -> Ja, weiter...
			jsr	Get1stBlock		;Ersten freien Sektor auf Disk suchen.
			txa				;Diskettenfehler ?
			bne	:106			;Ja, Abbruch...

			lda	FreeSekBuf +0		;Freien Sektor merken.
			sta	DirEntry   +1		;(Reserviert für Infoblock!)
			lda	FreeSekBuf +1
			sta	DirEntry   +2

::102			jsr	SetDataTop		;Zeiger auf Startadresse Datenspeicher.

			PushW	FreeSekBuf		;Ersten freien Sektor merken.
			jsr	SaveFileData		;Sektorkette auf Disk schreiben.
			PopW	r1			;Startadresse Sektorkette einlesen.
			txa				;Diskettenfehler ?
			bne	:106			;Ja, Abbruch...

			jsr	SetDataTop		;Zeiger auf Startadresse Datenspeicher.

			jsr	ChkFileData		;Sektorkette vergleichen.
			txa				;Diskettenfehler ?
			bne	:106			;Ja, Abbruch...

::103			bit	EndOfData		;Alle Daten kopiert ?
			bpl	:105			;Nein, weiter...
::104			jmp	WriteInfo		;Infoblock schreiben.

::105			jsr	IO_Update		;Quell-Laufwerk öffnen.
			txa				;Diskettenfehler ?
			bne	:106			;Ja, Abbruch...

			MoveW	NextSekBuf,r1		;Zeiger auf nächsten Quell-Sektor.
			jmp	:101			;Sektorkette weiterlesen...

;*** Abbruch mit Fehlermeldung im xReg.
::106			jmp	DoneWithIO		;Fehler!

;*** VLIR-Datei kopieren.
:FileIsVLIR		jsr	GetHeaderSek		;VLIR-Header einlesen.

			LoadW	r4,fileTrScTab
			jsr	ReadBlock		;VLIR-Header einlesen.
			txa				;Diskettenfehler ?
			beq	:102			;Nein, weiter...
::101			jmp	DoneWithIO 		;Abbruch.

::102			jsr	Sub1FileLen		;Blockzähler -1.

			lda	#$00
			sta	DataCopied

			jsr	SetDataTop		;Zeiger auf Startadresse Datenspeicher.

			ldy	#2			;Zeiger auf ersten zu lesenden
			sty	WriteCurRec		;Record richten.

::103			lda	#$ff			;Neuen Record lesen.
			sta	ContinueCopy

::104			lda	#$00
			sta	EndOfData

			lda	fileTrScTab+0,y		;Track-Adresse aus VLIR-Header für
			sta	r1L			;aktuellen Record einlesen.
			ldx	fileTrScTab+1,y		;Sektor-Adresse aus VLIR-Header für
			stx	r1H			;aktuellen Record einlesen.

			iny
			sty	LastReadRec		;Zeiger auf gelesenen Record setzen.

			tay				;Track -Adresse = $00 ?
			beq	:106			;Ja, Record übergehen...

			PushW	r1
			jsr	PrintVLIR
			PopW	r1

::105			jsr	LoadFileData		;Sektorkette einlesen.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch...

			MoveW	r1,NextSekBuf		;Nächsten Sektor merken.

			bit	EndOfData
			bpl	:201

			jsr	AddSekToMem		;Kopierspeicher voll ?
			bcs	:201			;Ja, weiter...

::106			ldy	LastReadRec		;Zeiger auf nächsen Record.
			iny				;Ende erreicht ?
			bne	:104			;Nein, nächsten Record kopieren

;*** Record-Daten im Speicher kopieren.
::201			jsr	IO_SetTarget		;Ziel-Laufwerk öffnen.
			txa				;Diskettenfehler ?
			beq	:203			;Nein, weiter...
::202			jmp	DoneWithIO

::203			lda	FreeSekBuf +0		;Startsektor für Sektorsuche schon
			bne	:204			;festgelegt ? -> Ja, weiter...
			jsr	Get1stBlock		;Ersten freien Sektor auf Disk suchen.
			txa				;Diskettenfehler ?
			bne	:202			;Ja, Abbruch...

::204			lda	DataCopied		;Wurden Daten kopiert ?
			bne	:205			;Ja, weiter...
			jmp	WriteInfo		; -> Infoblock schreiben.

::205			lda	ContinueCopy		;Sektorkette weiterschreiben ?
			beq	:208			; -> Ja, Sonderbehandlung.

::206			ldy	WriteCurRec		;Zeiger auf Sektor des zu schreibenden
			lda	fileTrScTab+0,y		;Records. War Adresse = $00 ?
			bne	:207			;Nein, Daten aus Record schreiben.

			inc	WriteCurRec		;Zeiger auf nächsten Record.
			inc	WriteCurRec		;Alle Records kopiert ?
			beq	:212			;Ja, Daten verifizieren.
			bne	:206			;Weiterkopieren...

;*** Neuen Record auf Diskette schreiben.
::207			lda	FreeSekBuf +0		;Ersten Sektor in VLIR-Header
			sta	fileTrScTab+0,y		;übertragen.
			lda	FreeSekBuf +1
			sta	fileTrScTab+1,y

::208			PushW	FreeSekBuf		;Ersten Sektor merken.
			PushB	WriteCurRec		;Zeiger auf aktuellen Record merken.

			jsr	SetDataTop		;Zeiger auf Startadresse Datenspeicher.

::209			jsr	SaveFileData		;Sektorkette auf Disk schreiben.
			txa				;Diskettenfehler ?
			bne	:212			;Ja, Abbruch...

			ldy	#0
			lda	(a6L),y			;Wurde kompletter Record kopiert ?
			bne	:212			;Nein, weiter...

::210			ldy	WriteCurRec
			iny
			iny
			sty	WriteCurRec		;Alle Records kopiert ?
			beq	:212			;Ja, Daten verifizieren...

			lda	fileTrScTab+0,y		;Nächster Record verfügbar ?
			beq	:210			;Ja, Record schreiben.

::211			jsr	AddSekToMem		;Kopierspeicher voll ?
			bcs	:212			;Ja, Daten verifizieren...

			lda	FreeSekBuf +0		;Startadresse Sektorkette in
			sta	fileTrScTab+0,y		;VLIR-Header eintragen.
			lda	FreeSekBuf +1
			sta	fileTrScTab+1,y
			jmp	:209			;Nächsten Record schreiben.

::212			PopB	WriteCurRec		;Zeiger auf aktuellen Record einlesen.
			PopW	r1			;Zeiger auf ersten Sektor einlesen.

			txa				;Diskettenfehler ?
			beq	:301			;Nein, weiter...
::213			jmp	DoneWithIO		;Abbruch, Diskettenfehler...

;*** Neue Daten verifizieren.
::301			jsr	SetDataTop		;Zeiger auf Startadresse Datenspeicher.

::302			jsr	ChkFileData		;Sektorkette vergleichen.
			txa				;Diskettenfehler ?
			bne	:213			;Ja, Abbruch...

			ldy	#0
			lda	(a6L),y			;Wurde kompletter Record kopiert ?
			bne	:307			;Nein, weiter...

::303			ldy	WriteCurRec
			iny
			iny
			sty	WriteCurRec		;Alle Records kopiert ?
			beq	:304			;Ja, Infoblock schreiben.

			lda	fileTrScTab+0,y		;Zeiger auf nächsten Record.
			sta	r1L
			ldx	fileTrScTab+1,y
			stx	r1H

			cmp	#$00			;Daten im nächsten Record ?
			bne	:305			;Ja   -> nächsten Record vergleichen.
			beq	:303			;Nein -> Zeiger auf nächsten Record.

::304			;jsr	IO_Update
			;txa				;Diskettenfehler ?
			;bne	:308			;Ja, Abbruch.

			jmp	WriteInfo

;*** Alle Daten vergleichen.
::305			jsr	AddSekToMem		;Kopierspeicher voll ?
			bcc	:302			;Nein, weiter...

;*** Neue Sektorkette lesen.
::306			jsr	IO_Update		;Quell-Laufwerk öffnen.
			txa				;Diskettenfehler ?
			bne	:308			;Ja, Abbruch.

			stx	DataCopied		;Flags für "Daten im Speicher" und
			dex				;"Sektorkette weiterlesen" löschen.
			stx	ContinueCopy
			jsr	SetDataTop		;Zeiger auf Startadresse Datenspeicher.

			jmp	:106			;Nächsten Record einlesen.

;*** Letzte Sektorkette weiterlesen.
::307			jsr	IO_Update		;Quell-Laufwerk öffnen.
			txa				;Diskettenfehler ?
			bne	:308			;Ja, Abbruch.

			stx	DataCopied		;Flag "Daten im Speicher" löschen und
			stx	ContinueCopy		;Flag "Sektorkette weiterlesen" setzen.
			jsr	SetDataTop		;Zeiger auf Startadresse Datenspeicher.

			MoveW	NextSekBuf,r1		;Zeiger auf nächsten Quell-Sektor.
			jmp	:105			;Sektorkette weiterlesen.

;*** Diskettenfehler.
::308			jmp	DoneWithIO		;Abbruch, Diskettenfehler...

;*** Sektorkette einlesen.
:LoadFileData		MoveW	a6,r4
			jsr	ReadBlock		;Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:103			;Ja, Abbruch...

			jsr	Sub1FileLen		;Blockzähler -1.
			jsr	CopyInfo		;Info ausgeben.

			jsr	MoveSekAdr		;Verkettungszeiger kopieren.
			beq	:102			;Noch ein Sektor ? Nein, Ende.

			jsr	IsMemoryFull		;Speicher voll ?
			bcs	:101			;Nein, weiterlesen...

			inc	a6H			;Zeiger auf nächsten Sektor.
			jmp	LoadFileData

::101			lda	#$00
			b $2c
::102			lda	#$ff
			sta	EndOfData

			lda	#$ff
			sta	DataCopied

::103			rts

;*** Sektorkette schreiben.
:SaveFileData		lda	FreeSekBuf +0		;Nächster Sektor in Speicher für
			sta	r3L			;aktuellen Sektor und in Adresse für
			sta	r1L			;"Nächster freien Sektor suchen"
			lda	FreeSekBuf +1		;kopieren.
			sta	r3H
			sta	r1H

::101			jsr	GetNextFree		;Nächsten freien Sektor suchen.
			txa				;Diskettenfehler ?
			bne	:103			;Ja, Abbruch.

			ldy	#0
			lda	(a6L),y			;Noch ein Sektor in aktueller Kette ?
			beq	:102			;Nein, Ende...

			lda	r3L			;Nächsten Sektor als Verkettungszeiger
			sta	(a6L),y			;für aktuellen Sektor merken.
			iny
			lda	r3H
			sta	(a6L),y

::102			MoveW	a6,r4
			jsr	WriteBlock		;Sektor auf Diskette schreiben.
			txa				;Diskettenfehler ?
			bne	:103			;Ja, Abbruch...

			IncWord	File2Len		;Blockzähler Zieldatei +1.

			lda	r3L			;Adresse des nächsten Sektors in
			sta	r1L			;Zwischenspeicher kopieren und als
			sta	FreeSekBuf +0		;neue Startadresse für "Sektor suchen"
			lda	r3H			;setzen.
			sta	r1H
			sta	FreeSekBuf +1

			ldy	#0
			lda	(a6L),y			;Folgt noch ein Sektor ?
			beq	:103			;Nein, Ende...

			jsr	IsMemoryFull		;Speicher voll ?
			bcs	:103			;Nein, weiterschreiben...

			inc	a6H
			jmp	:101

::103			rts				;Ende...

;*** Sektorkette vergleichen.
:ChkFileData		MoveW	a6,r4
			jsr	VerWriteBlock		;Sektor vergleichen.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch...

			jsr	MoveSekAdr		;Verkettungszeiger kopieren.
			beq	:101			;Noch ein Sektor ? Nein, Ende.

			jsr	IsMemoryFull		;Speicher voll ?
			bcs	:101			;Nein, weiterlesen...

			inc	a6H			;Zeiger auf nächsten Sektor.
			jmp	ChkFileData

::101			rts

;*** Infoblock auf Diskette schreiben.
;    Sektor liegt ab ":Copy1Sek" im
;    Speicher des Computers!
:WriteInfo		jsr	DoneWithIO		;I/O abschalten.

			lda	DirEntry +22		;GEOS-Datei ?
			bne	:102			;Ja, weiter...

			MoveW	FreeSekBuf,r6		;Kein Infoblock erzeugen.
			jsr	FreeBlock		;Sektor für Infoblock freigeben.
			txa				;Diskettenfehler ?
			beq	:103			;Nein, Verzeichniseintrag erzeugen.
::101			rts				;Abbruch...

::102			lda	FreeSekBuf +0		;Sektor für Infoblock in
			sta	r1L			;Zwischenspeicher und Verzeichnis-
			sta	DirEntry   +19		;eintrag füpr Zieldatei kopieren.
			lda	FreeSekBuf +1
			sta	r1H
			sta	DirEntry   +20

			jsr	SetInfoMem		;Zeiger auf Speicher für Infoblock.
			jsr	PutBlock		;Sektor auf Diskette speichern.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch...

			IncWord	File2Len		;Blockzähler Zieldatei +1.

			lda	DirEntry +21		;VLIR-Datei ?
			beq	:103			;Nein, weiter...

			MoveW	FreeSekBuf,r3		;Freien Sektor für
			jsr	SetNextFree		;Nächsten freien Sektor suchen.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch...

			lda	r3L			;Sektor für VLIR-Header in
			sta	r1L			;Zwischenspeicher und Verzeichnis-
			sta	DirEntry +1		;eintrag füpr Zieldatei kopieren.
			lda	r3H
			sta	r1H
			sta	DirEntry +2

			LoadW	r4,fileTrScTab		;VLIR-Header speichern.
			jsr	PutBlock
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch...

			IncWord	File2Len		;Blockzähler Zieldatei +1.

;*** Verzeichniseintrag erzeugen.
::103			LoadB	r10L,0
			jsr	GetFreeDirBlk		;Freien Verzeichniseintrag suchen.
			txa				;Diskettenfehler ?
			bne	:108			;Ja, Abbruch...

			ldx	#0			;Verzeichniseintrag in
::107			lda	DirEntry  ,x		;Verzeichnissektor kopieren.
			sta	diskBlkBuf,y
			iny
			inx
			cpx	#$1c
			bcc	:107

			lda	File2Len  +0		;Dateilänge der Ziel-Datei in
			sta	diskBlkBuf+0,y		;Verzeichnis-Eintrag schreiben.
			lda	File2Len  +1
			sta	diskBlkBuf+1,y

			LoadW	r4,diskBlkBuf		;Verzeichniseintrag
			jsr	PutBlock		;zurück auf Diskette schreiben.
			txa				;Diskettenfehler ?
			bne	:108			;Ja, Abbruch...

			jmp	PutDirHead		;BAM auf Diskette sichern, Ende...

::108			rts				;Diskettenfehler...

;*** Nächsten freien Sektor auf
;    Ziel-Laufwerk suchen.
:Get1stBlock		lda	NxFreeSek+0
			sta	r3L
			lda	NxFreeSek+1
			sta	r3H
			jsr	GetNextFree		;Nächsten freien Sektor suchen.
			MoveW	r3,FreeSekBuf		;Sektor merken.
			rts

;*** Nächsten freien Sektor suchen.
:GetNextFree		jsr	DoneWithIO
			jsr	SetNextFree
			stx	:101 +1
			jsr	EnterTurbo
			jsr	InitForIO
::101			ldx	#$ff
			rts

;*** Zeiger auf Anfang Datenspeicher.
:SetDataTop		LoadW	a6,Memory2		;Zeiger auf Startadresse
			rts				;für Datenspeicher.

;*** Zeiger auf Anfang Datenspeicher.
:SetInfoMem		LoadW	r4,Copy1Sek		;Zeiger auf Startadresse
			rts				;für Datenspeicher.

;*** Kopierspeicher voll ?
:AddSekToMem		inc	a6H			;Zeiger auf Datenspeicher korrigieren.
			lda	a6H
			cmp	#>EndBuffer		;Speicher voll ?
			rts

:IsMemoryFull		ldy	a6H
			iny
			cpy	#>EndBuffer
			rts

;*** Verkettungszeiger nach ":r1" kopieren.
:MoveSekAdr		ldy	#1			;Verkettungszeiger einlesen.
			lda	(a6L),y
			sta	r1H
			dey
			lda	(a6L),y
			sta	r1L			;Nächster Sektor verfügbar ?
			rts

;*** Sektoradresse aus ":dirEntryBuf" nach ":r1" kopieren.
;    xReg = zeigt auf Byte-Position!
:GetHeaderSek		ldx	#1
			b $2c
:GetInfoSek		ldx	#19

:CopyEntrySek		lda	DirEntry+1,x
			sta	r1H
			lda	DirEntry+0,x
			sta	r1L
			rts

;*** Variablen.
:StackPointer		b $00
:NxFreeSek		b $00,$00

:StartVarMem
:FreeSekBuf		b $00,$00			;Erster Sektor VLIR-Datensatz.
:NextSekBuf		b $00,$00			;Nächster freier Sektor.
:EndOfData		b $00				;$FF = Datensatz vollständig.
:ContinueCopy		b $00				;$00 = Datensatz weiterlesen.
:DataCopied		b $00				;$FF = Daten im Speicher.
:WriteCurRec		b $00				;Zeiger auf aktuellen Datensatz.
:LastReadRec		b $00				;Zeiger auf nächsten Datensatz.
:FileName		s $11				;Speicher für Dateiname.
:DirEntry		s 30				;Speicher für Verzeichniseintrag.
:File1Len		w $0000				;Dateilänge Quelldatei.
:File2Len		w $0000				;Dateilänge Zieldatei.
:EndVarMem		b $00				;Ende Variablenspeicher.

if Sprache = Deutsch
;*** Systemtexte.
:V220a0			b PLAINTEXT
			b "Kopiere :",NULL
:V220a1			b "Blocks  :",NULL
:V220a2			b "Dateien :",NULL
:V220a3			b "VLIR    :     ",NULL
:V220a4			b "Sequentiell   ",NULL
endif

if Sprache = Englisch
;*** Systemtexte.
:V220a0			b PLAINTEXT
			b "Copy    :",NULL
:V220a1			b "Blocks  :",NULL
:V220a2			b "Files   :",NULL
:V220a3			b "VLIR    :     ",NULL
:V220a4			b "Sequential    ",NULL
endif

;*** Startadresse Kopierspeicher.
:Memory1
:Memory2		= (Memory1 / 256 +1)*256
