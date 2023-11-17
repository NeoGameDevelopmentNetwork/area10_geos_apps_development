; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Datei kopieren.
:InitCopy		ldx	#$01			;Zeiger auf ersten Sektor für
			ldy	#$00			;Suche nach nächstem freien Sektor.
			lda	TargetMode
			and	#SET_MODE_SUBDIR	;Native-Mode-Laufwerk?
			beq	:101			; => Nein, weiter...
			ldy	#64			;Suche ab $01/$40 = CMD-Standard.
::101			stx	NxFreeSek+0
			sty	NxFreeSek+1

			jsr	i_FillRam		;Variablenspeicher löschen.
			w	(EndVarMem-StartVarMem)
			w	StartVarMem
			b	$00
			rts

;*** Dateilänge -1
:Sub1FileLen		lda	File1Len +0		;Alle Blocks kopiert?
			ora	File1Len +1
			beq	:101			; => Ja, übergehen.
			SubVW	1,File1Len		;Anzahl Blocks -1.
::101			rts

;*** prntBlocks ausgeben.
:prntBlocks		jsr	DoneWithIO		;GEOS-Kernal aktivieren.
			jsr	prntBlocksJob
			jmp	Reset_IO

;*** VLIR-Datensatz ausgeben.
:prntFStruct		jsr	DoneWithIO		;GEOS-Kernal aktivieren.
			jsr	prntFStructJob

;*** Laufwerk wieder aktivieren.
:Reset_IO		jsr	EnterTurbo		;GEOS-Turbo aktivieren.
			stx	:101 +1			;Fehler-Nr. merken.
			jsr	InitForIO		;I/O aktivieren.
::101			ldx	#$ff
			rts

;*** Verbleibende Blocks ausgeben.
:prntBlocksJob		LoadW	r11,INFO_X0		;Anzahl noch zu kopierender Blocks
			LoadB	r1H,INFO_Y4		;ausgeben.

			MoveW	File1Len,r0

			lda	#SET_LEFTJUST ! SET_SUPRESS
			jsr	PutDecimal
			lda	#" "			;Anzeige-Reste löschen.
			jmp	SmallPutChar

;*** Dateistruktur ausgeben.
:prntFStructJob		LoadW	r11,INFO_X1
			LoadB	r1H,INFO_Y4

			lda	jobDirEntry +21		;Dateiformat bestimmen.
			bne	:101			;VLIR-Datei, -> Datensatz ausgeben.

			LoadW	r0,V220a4		;"Sequentiell" ausgeben.
			jmp	PutString

::101			LoadW	r0,V220a3		;"VLIR: (Datensatz) " ausgeben.
			jsr	PutString

			lda	LastReadRec		;Nr. des VLIR-Datensatz ausgeben.
			sec
			sbc	#1
			lsr
			sta	r0L
			ClrB	r0H

			lda	#SET_LEFTJUST ! SET_SUPRESS
			jsr	PutDecimal
			lda	#" "			;Anzeige-Reste löschen.
			jmp	SmallPutChar

;*** BAM der Ziel-Diskette "updaten".
:IO_Update		jsr	DoneWithIO		;GEOS-Kernal aktivieren.

			jsr	PutDirHead		;BAM aktualisieren.
			txa				;Diskettenfehler?
			bne	ExitNewDrive		; => Ja, Abbruch...

			jsr	OpenSourceDrive		;Quell-Laufwerk aktivieren.
			jmp	EnableTurboIO		;GEOS-Turbo & Laufwerk aktivieren.

;*** Quell-Laufwerk aktivieren.
;Hinweis:
;Wird aktuell nicht verwendet.
;:IO_SetSource		jsr	DoneWithIO		;I/O abschalten.
;			jsr	OpenSourceDrive		;Source-Laufwerk öffnen.
;			jmp	EnableTurboIO		;GEOS-Turbo & Laufwerk aktivieren.

;*** Ziel-Laufwerk aktivieren.
:IO_SetTarget		jsr	DoneWithIO		;I/O abschalten.
			jsr	OpenTargetDrive		;Target-Laufwerk öffnen.

;*** GEOS-Turbo & Laufwerk aktivieren.
:EnableTurboIO		txa				;Fehler?
			bne	ExitNewDrive		; => Ja, Abbruch...
			jsr	EnterTurbo		;GEOS-Turbo aktivieren.
			txa
:ExitNewDrive		pha
			jsr	InitForIO		;I/O aktivieren.
			pla
			tax
			rts

;*** Einzeldatei kopieren.
;    Übergabe: dirEntryBuf = 30Byte Verzeichnis-Eintrag.
;              curFileName = Name Ziel-Datei.
:StartCopy		tsx
			stx	StackPointer

			jsr	OpenSourceDrive		;Quell-Laufwerk aktivieren.

;--- Dateiname kopieren.
;Ziel-Dateiname kann hier bereits ein
;Suffix "_1" enthalten, daher nicht
;aus dirEntryBuf übernehmen.
			ldy	#$00
::1			lda	curFileName,y		;Dateiname in Zwischenspeicher
			beq	:2			;für neuen Dateieintrag kopieren.
			sta	jobDirEntry +3,y
			iny
			cpy	#16
			bcc	:1
			bcs	:4

::2			lda	#$a0			;Mit "$A0" auf 16 Zeichen auffüllen.
::3			sta	jobDirEntry +3,y
			iny
			cpy	#16
			bcc	:3

::4			ldy	#$00
::103			lda	dirEntryBuf,y		;Datei-Eintrag in Zwischenspeicher
			sta	jobDirEntry,y		;kopieren.
::104			iny
			cpy	#3
			bcc	:103
			cpy	#19			;Dateiname überspringen.
			bcc	:104
			cpy	#30
			bne	:103

			lda	jobDirEntry +28		;Dateilänge Quell-Datei als
			sta	File1Len + 0		;Zähler initialisieren.
			lda	jobDirEntry +29
			sta	File1Len + 1

			jsr	EnterTurbo		;GEOS-Turbo aktivieren.
			txa				;Diskettenfehler?
			bne	:101			; => Ja, Abbruch...

			jsr	InitForIO		;I/O aktivieren.

			lda	#$00
			sta	FreeSekBuf +0
			sta	File2Len   +0		;Länge der Zieldatei löschen.
			sta	File2Len   +1

			lda	jobDirEntry +22		;Dateityp = $00?
			beq	:106			; -> Ja, keine GEOS-Datei.

			jsr	GetInfoSek		;Track/Sektor Infoblock einlesen.
			jsr	SetInfoMem		;Zeiger auf Speicher für Infoblock.
			jsr	ReadBlock		;Infoblock einlesen.
			txa				;Diskettenfehler?
			bne	:107			; => Ja, Abbruch...

			jsr	Sub1FileLen		;Blockzähler -1.

			lda	jobDirEntry +21		;Dateiformat bestimmen.
			beq	:106
			jmp	FileIsVLIR		; -> VLIR-Datei kopieren.
::106			jmp	FileIsSEQ		; -> SEQ -Datei kopieren.
::107			jmp	DoneWithIO		;Fehler!
::101			rts

;*** Seq. Datei kopieren.
:FileIsSEQ		jsr	prntFStruct		;Dateistruktur anzeigen.

			jsr	GetHeaderSek		;Zeiger auf ersten Sektor einlesen.
			bne	:101			;Sektor verfügbar? Ja, kopieren...

;--- HINWEIS:
;Sonderbehandlung für TopDesk-Ordner.
;Hier sind keine Daten vorhanden. Der
;erste Sektor ist Tr/Se = $00/$FF.
;Daher Ziel-Laufwerk aktivieren und
;einen freien Sektor für den Infoblock
;suchen/reservieren.
			jsr	IO_SetTarget		;Ziel-Laufwerk öffnen.
			txa				;Diskettenfehler?
			bne	:106			; => Ja, Abbruch...

			lda	FreeSekBuf +0		;Startsektor für Sektorsuche schon
			bne	:100			;festgelegt? -> Ja, weiter...
			jsr	Get1stBlock		;Ersten freien Sektor suchen.
			txa				;Diskettenfehler?
			bne	:106			; => Ja, Abbruch...
::100			jmp	WriteDirEntry		;Infoblock schreiben.

::101			jsr	SetDataTop		;Zeiger auf Start Datenspeicher.
			jsr	LoadFileData		;Sektor-Kette in Speicher einlesen.
			txa				;Diskettenfehler?
			bne	:106			; => Ja, Abbruch...

			MoveW	r1,NextSekBuf		;Nächsten Sektor merken.

			jsr	IO_SetTarget		;Ziel-Laufwerk öffnen.
			txa				;Diskettenfehler?
			bne	:106			; => Ja, Abbruch...

			lda	FreeSekBuf +0		;Startsektor für Sektorsuche schon
			bne	:102			;festgelegt? -> Ja, weiter...
			jsr	Get1stBlock		;Ersten freien Sektor suchen.
			txa				;Diskettenfehler?
			bne	:106			; => Ja, Abbruch...

			lda	FreeSekBuf +0		;Freien Sektor merken.
			sta	jobDirEntry   +1	;(Reserviert für Infoblock!)
			lda	FreeSekBuf +1
			sta	jobDirEntry   +2

::102			jsr	SetDataTop		;Zeiger auf Start Datenspeicher.

			PushW	FreeSekBuf		;Ersten freien Sektor merken.
			jsr	SaveFileData		;Sektorkette auf Disk schreiben.
			PopW	r1			;Startadresse Sektorkette einlesen.
			txa				;Diskettenfehler?
			bne	:106			; => Ja, Abbruch...

			jsr	SetDataTop		;Zeiger auf Start Datenspeicher.

			jsr	ChkFileData		;Sektorkette vergleichen.
			txa				;Diskettenfehler?
			bne	:106			; => Ja, Abbruch...

::103			bit	EndOfData		;Alle Daten kopiert?
			bpl	:105			; => Nein, weiter...
::104			jmp	WriteDirEntry		;Infoblock schreiben.

::105			jsr	IO_Update		;Quell-Laufwerk öffnen.
			txa				;Diskettenfehler?
			bne	:106			; => Ja, Abbruch...

			MoveW	NextSekBuf,r1		;Zeiger auf nächsten Quell-Sektor.
			jmp	:101			;Sektorkette weiterlesen...

;*** Abbruch mit Fehlermeldung im xReg.
::106			jmp	DoneWithIO		;Fehler!

;*** VLIR-Datei kopieren.
:FileIsVLIR		jsr	GetHeaderSek		;VLIR-Header einlesen.

			LoadW	r4,fileTrScTab
			jsr	ReadBlock		;VLIR-Header einlesen.
			txa				;Diskettenfehler?
			beq	:102			; => Nein, weiter...
::101			jmp	DoneWithIO 		;Abbruch.

::102			jsr	Sub1FileLen		;Blockzähler -1.

			lda	#$00
			sta	DataCopied

			jsr	SetDataTop		;Zeiger auf Start Datenspeicher.

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

			tay				;Track -Adresse = $00?
			beq	:106			; => Ja, Record übergehen...

			PushW	r1
			jsr	prntFStruct
			PopW	r1

::105			jsr	LoadFileData		;Sektorkette einlesen.
			txa				;Diskettenfehler?
			bne	:101			; => Ja, Abbruch...

			MoveW	r1,NextSekBuf		;Nächsten Sektor merken.

			bit	EndOfData		;Dateiende erreicht?
			bpl	:201			; => Ja, weiter...

			jsr	AddSekToMem		;Kopierspeicher voll?
			bcs	:201			; => Ja, weiter...

::106			ldy	LastReadRec		;Zeiger auf nächsten Record.
			iny				;Ende erreicht?
			bne	:104			; => Nein, nächsten Record kopieren

;*** Record-Daten im Speicher kopieren.
::201			jsr	IO_SetTarget		;Ziel-Laufwerk öffnen.
			txa				;Diskettenfehler?
			beq	:203			; => Nein, weiter...
::202			jmp	DoneWithIO

::203			lda	FreeSekBuf +0		;Startsektor für Sektorsuche schon
			bne	:204			;festgelegt? -> Ja, weiter...
			jsr	Get1stBlock		;Ersten freien Sektor suchen.
			txa				;Diskettenfehler?
			bne	:202			; => Ja, Abbruch...

::204			lda	DataCopied		;Wurden Daten kopiert?
			bne	:205			; => Ja, weiter...
			jmp	WriteDirEntry		; -> Infoblock schreiben.

::205			lda	ContinueCopy		;Sektorkette weiterschreiben?
			beq	:208			; -> Ja, Sonderbehandlung.

::206			ldy	WriteCurRec		;Track des zu schreibenden
			lda	fileTrScTab+0,y		;Records. War Adresse = $00?
			bne	:207			; => Nein, Daten schreiben.

			inc	WriteCurRec		;Zeiger auf nächsten Record.
			inc	WriteCurRec		;Alle Records kopiert?
			beq	:212			; => Ja, Daten verifizieren.
			bne	:206			;Weiterkopieren...

;*** Neuen Record auf Diskette schreiben.
::207			lda	FreeSekBuf +0		;Ersten Sektor in VLIR-Header
			sta	fileTrScTab+0,y		;übertragen.
			lda	FreeSekBuf +1
			sta	fileTrScTab+1,y

::208			PushW	FreeSekBuf		;Ersten Sektor merken.
			PushB	WriteCurRec		;Zeiger auf aktuellen Record merken.

			jsr	SetDataTop		;Zeiger auf Start Datenspeicher.

::209			jsr	SaveFileData		;Sektorkette auf Disk schreiben.
			txa				;Diskettenfehler?
			bne	:212			; => Ja, Abbruch...

			ldy	#0
			lda	(a6L),y			;Wurde kompletter Record kopiert?
			bne	:212			; => Nein, weiter...

::210			ldy	WriteCurRec
			iny
			iny
			sty	WriteCurRec		;Alle Records kopiert?
			beq	:212			; => Ja, Daten verifizieren...

			lda	fileTrScTab+0,y		;Nächster Record verfügbar?
			beq	:210			; => Ja, Record schreiben.

::211			jsr	AddSekToMem		;Kopierspeicher voll?
			bcs	:212			; => Ja, Daten verifizieren...

			lda	FreeSekBuf +0		;Startadresse Sektorkette in
			sta	fileTrScTab+0,y		;VLIR-Header eintragen.
			lda	FreeSekBuf +1
			sta	fileTrScTab+1,y
			jmp	:209			;Nächsten Record schreiben.

::212			PopB	WriteCurRec		;Zeiger auf Record einlesen.
			PopW	r1			;Zeiger auf ersten Sektor einlesen.

			txa				;Diskettenfehler?
			beq	:301			; => Nein, weiter...
::213			jmp	DoneWithIO		;Abbruch, Diskettenfehler...

;*** Neue Daten verifizieren.
::301			jsr	SetDataTop		;Zeiger auf Start Datenspeicher.

::302			jsr	ChkFileData		;Sektorkette vergleichen.
			txa				;Diskettenfehler?
			bne	:213			; => Ja, Abbruch...

			ldy	#0
			lda	(a6L),y			;Wurde kompletter Record kopiert?
			bne	:307			; => Nein, weiter...

::303			ldy	WriteCurRec
			iny
			iny
			sty	WriteCurRec		;Alle Records kopiert?
			beq	:304			; => Ja, Infoblock schreiben.

			lda	fileTrScTab+0,y		;Zeiger auf nächsten Record.
			sta	r1L
			ldx	fileTrScTab+1,y
			stx	r1H

			cmp	#$00			;Daten im nächsten Record?
			bne	:305			;Ja   -> Record vergleichen.
			beq	:303			;Nein -> Zeiger auf nächsten Record.

::304			;jsr	IO_Update
			;txa				;Diskettenfehler?
			;bne	:308			; => Ja, Abbruch.

			jmp	WriteDirEntry

;*** Alle Daten vergleichen.
::305			jsr	AddSekToMem		;Kopierspeicher voll?
			bcc	:302			; => Nein, weiter...

;*** Neue Sektorkette lesen.
::306			jsr	IO_Update		;Quell-Laufwerk öffnen.
			txa				;Diskettenfehler?
			bne	:308			; => Ja, Abbruch.

			stx	DataCopied		;Flags für "Daten im Speicher" und
			dex				;"Sektorkette weiterlesen" löschen.
			stx	ContinueCopy
			jsr	SetDataTop		;Zeiger auf Start Datenspeicher.

			jmp	:106			;Nächsten Record einlesen.

;*** Letzte Sektorkette weiterlesen.
::307			jsr	IO_Update		;Quell-Laufwerk öffnen.
			txa				;Diskettenfehler?
			bne	:308			; => Ja, Abbruch.

			stx	DataCopied		;Flag "Daten im Speicher" löschen.
			stx	ContinueCopy		;Flag "Sektorkette lesen" setzen.
			jsr	SetDataTop		;Zeiger auf Start Datenspeicher.

			MoveW	NextSekBuf,r1		;Zeiger auf nächsten Quell-Sektor.
			jmp	:105			;Sektorkette weiterlesen.

;*** Diskettenfehler.
::308			jmp	DoneWithIO		;Abbruch, Diskettenfehler...

;*** Sektorkette einlesen.
:LoadFileData		MoveW	a6,r4
			jsr	ReadBlock		;Sektor einlesen.
			txa				;Diskettenfehler?
			bne	:103			; => Ja, Abbruch...

			jsr	Sub1FileLen		;Blockzähler -1.
			jsr	prntBlocks		;Info ausgeben.

			jsr	MoveSekAdr		;Verkettungszeiger kopieren.
			beq	:102			;Noch ein Sektor? Nein, Ende.

			jsr	IsMemoryFull		;Speicher voll?
			bcs	:101			; => Nein, weiterlesen...

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
			txa				;Diskettenfehler?
			bne	:103			; => Ja, Abbruch.

			ldy	#0
			lda	(a6L),y			;Noch ein Sektor in aktueller Kette?
			beq	:102			; => Nein, Ende...

			lda	r3L			;Nächsten Sektor als
			sta	(a6L),y			;Verkettungszeiger für aktuellen
			iny				;Sektor merken.
			lda	r3H
			sta	(a6L),y

::102			MoveW	a6,r4
			jsr	WriteBlock		;Sektor auf Diskette schreiben.
			txa				;Diskettenfehler?
			bne	:103			; => Ja, Abbruch...

			IncW	File2Len		;Blockzähler Zieldatei +1.

			lda	r3L			;Adresse des nächsten Sektors in
			sta	r1L			;Zwischenspeicher kopieren und als
			sta	FreeSekBuf +0		;neue Adresse für "Sektor suchen"
			lda	r3H			;setzen.
			sta	r1H
			sta	FreeSekBuf +1

			ldy	#0
			lda	(a6L),y			;Folgt noch ein Sektor?
			beq	:103			; => Nein, Ende...

			jsr	IsMemoryFull		;Speicher voll?
			bcs	:103			; => Nein, weiterschreiben...

			inc	a6H
			jmp	:101

::103			rts				;Ende...

;*** Sektorkette vergleichen.
:ChkFileData		MoveW	a6,r4
			jsr	VerWriteBlock		;Sektor vergleichen.
			txa				;Diskettenfehler?
			bne	:101			; => Ja, Abbruch...

			jsr	MoveSekAdr		;Verkettungszeiger kopieren.
			beq	:101			;Noch ein Sektor? Nein, Ende.

			jsr	IsMemoryFull		;Speicher voll?
			bcs	:101			; => Nein, weiterlesen...

			inc	a6H			;Zeiger auf nächsten Sektor.
			jmp	ChkFileData

::101			rts

;*** Infoblock auf Diskette schreiben.
;    Sektor liegt ab ":Copy1Sek" im
;    Speicher des Computers!
:WriteDirEntry		jsr	DoneWithIO		;I/O abschalten.

			lda	jobDirEntry +22		;GEOS-Datei?
			bne	:writeInfoBlk		; => Ja, weiter...

			ldx	FreeSekBuf +0		;Seektor Infoblock reserviert?
			beq	:exit			; => Nein, Ende...
			stx	r6L
			lda	FreeSekBuf +1
			sta	r6H
			jsr	FreeBlock		;Sektor für Infoblock freigeben.
			txa				;Diskettenfehler?
			beq	NewDirEntry		; => Nein, Dateieintrag erzeugen.
::exit			rts				;Abbruch...

::writeInfoBlk		lda	FreeSekBuf +0		;Sektor für Infoblock in
			sta	r1L			;Zwischenspeicher und Verzeichnis-
			sta	jobDirEntry   +19	;eintrag für Zieldatei kopieren.
			lda	FreeSekBuf +1
			sta	r1H
			sta	jobDirEntry   +20

			jsr	SetInfoMem		;Zeiger auf Speicher für Infoblock.
			jsr	PutBlock		;Sektor auf Diskette speichern.
			txa				;Diskettenfehler?
			bne	:exit			; => Ja, Abbruch...

			IncW	File2Len		;Blockzähler Zieldatei +1.

			lda	jobDirEntry +21		;VLIR-Datei?
			beq	NewDirEntry		; => Nein, weiter...

			MoveW	FreeSekBuf,r3		;Freien Sektor für
			jsr	SetNextFree		;Nächsten freien Sektor suchen.
			txa				;Diskettenfehler?
			bne	:exit			; => Ja, Abbruch...

			lda	r3L			;Sektor für VLIR-Header in
			sta	r1L			;Zwischenspeicher und Verzeichnis-
			sta	jobDirEntry +1		;eintrag für Zieldatei kopieren.
			lda	r3H
			sta	r1H
			sta	jobDirEntry +2

			LoadW	r4,fileTrScTab		;VLIR-Header speichern.
			jsr	PutBlock
			txa				;Diskettenfehler?
			bne	:exit			; => Ja, Abbruch...

			IncW	File2Len		;Blockzähler Zieldatei +1.

;*** Verzeichniseintrag erzeugen.
:NewDirEntry		LoadB	r10L,0
			jsr	GetFreeDirBlk		;Freien Verzeichniseintrag suchen.
			txa				;Diskettenfehler?
			bne	:error			; => Ja, Abbruch...

;			ldx	#0			;Verzeichniseintrag in
::1			lda	jobDirEntry ,x		;Verzeichnis-Sektor kopieren.
			sta	diskBlkBuf  ,y
			iny
			inx
			cpx	#28			;30Bytes - 2Bytes Dateigröße.
			bcc	:1

			lda	File2Len  +0		;Dateilänge der Ziel-Datei in
			sta	diskBlkBuf+0,y		;Verzeichnis-Eintrag schreiben.
			lda	File2Len  +1
			sta	diskBlkBuf+1,y

			LoadW	r4,diskBlkBuf		;Verzeichniseintrag
			jsr	PutBlock		;zurück auf Diskette schreiben.
			txa				;Diskettenfehler?
			bne	:error			; => Ja, Abbruch...

			jmp	PutDirHead		;BAM auf Diskette sichern, Ende...

::error			rts				;Diskettenfehler...

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
:SetDataTop		LoadW	a6,StartBuffer		;Zeiger auf Startadresse
			rts				;für Datenspeicher.

;*** Zeiger auf Anfang Datenspeicher.
:SetInfoMem		LoadW	r4,Copy1Sek		;Zeiger auf Startadresse
			rts				;für Datenspeicher.

;*** Kopierspeicher voll?
:AddSekToMem		inc	a6H			;Zeiger auf Speicher korrigieren.
			lda	a6H
			cmp	#>EndBuffer		;Speicher voll?
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
			sta	r1L			;Nächster Sektor verfügbar?
			rts

;*** Sektoradresse aus ":dirEntryBuf" nach ":r1" kopieren.
;    xReg = zeigt auf Byte-Position!
:GetHeaderSek		ldx	#1
			b $2c
:GetInfoSek		ldx	#19

			lda	jobDirEntry+1,x
			sta	r1H
			lda	jobDirEntry+0,x
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
:jobDirEntry		s 30				;Speicher für Verzeichniseintrag.
:File1Len		w $0000				;Dateilänge Quelldatei.
:File2Len		w $0000				;Dateilänge Zieldatei.
:EndVarMem		b $00				;Ende Variablenspeicher.

;*** Systemtexte.
if LANG = LANG_DE
:V220a3			b "VLIR / #",NULL
:V220a4			b "Sequentiell",NULL
endif
if LANG = LANG_EN
:V220a3			b "VLIR / #",NULL
:V220a4			b "Sequential",NULL
endif
