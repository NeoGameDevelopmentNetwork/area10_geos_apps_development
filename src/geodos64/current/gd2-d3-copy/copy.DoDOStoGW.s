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

			n	"mod.#211.obj"
			o	ModStart

			jmp	DoDOStoGW

;*** Quell- und Ziel-Laufwerk setzen.
			t   "-SetSourceDOS"
			t   "-SetTargetCBM"

;*** L211: Datei von MS-DOS nach GeoWrite kopieren
:ConvTabBase		= SCREEN_BASE
:File_Name		= SCREEN_BASE +256
:File_Datum		= File_Name   +256*16

:EndBuffer		= Boot_Sektor -512

:GWBufSize		= $1a00
:MaxGWpages		= 61

;A0  = Boot-Sektor
;A1  = FAT
;A2  = Zeiger auf Datei-Namen.
;A3  = Zeiger auf Datei-Datum.
;A4L = Anzahl Sektoren / Cluster - Zähler.
;A5  = Bytes pro Sektor - Zähler.
;A6  = Zeiger auf Zwischenspeicher.
;A7  = Cluster-Nummer.
;A8  = Disk_Sek

:DoDOStoGW		tsx
			stx	StackPointer

;*** GeoWrite-Copy initialisieren.
:InitGWCopy		lda	GW_FirstPage+0
			sta	HdrB137+0
			lda	GW_FirstPage+1
			sta	HdrB137+1
			lda	GW_PageLength+0
			sta	HdrB144+0
			lda	GW_PageLength+1
			sta	HdrB144+1

			lda	GW_Version
			add	$30
			sta	HdrB090+2

;*** Ausgabe-Fenster.
:DoCopyBox		jsr	UseGDFont 		;Bildschirm Initialisieren.
			Display	ST_WR_FORE

			FillPRec$00,$b8,$c7,$0000,$013f
			jsr	i_ColorBox
			b	$00,$00,$28,$17,$00
			jsr	i_ColorBox
			b	$00,$17,$28,$02,$36

			PrintXY	  6,190,V211a0
			PrintXY	  6,198,V211a1
			PrintXY	219,190,V211a2
			PrintXY	219,198,V211a3		;Text "Seite:" ausgeben.

			StartMouse
			NoMseKey

			LoadW	a0,Boot_Sektor		;Vektoren setzen.
			LoadW	a1,FAT
			LoadW	a2,File_Name
			LoadW	a3,File_Datum
			MoveB	SpClu,a4L		;Anzahl Sektoren/Cluster.
			LoadW	a8,Disk_Sek

			lda	Target_Drv
			jsr	NewDrive

			ldx	#$01
			ldy	#$00
			lda	curDrvMode
			and	#%00100000
			beq	:101
;--- Ergänzung: 02.12.18/M.Kanet
;Sektorsuche ab TR01/SE64 = CMD-Standard.
;			inx				;Suche ab $02/$00 starten.
			ldy	#64			;Suche ab $01/$40 starten.
::101			stx	NxFreeSek+0
			sty	NxFreeSek+1

:CopyFiles		lda	pressFlag
			beq	:102
::101			jmp	L211ExitGD

::102			lda	AnzahlFiles
			beq	L211ExitGD

			jsr	PrintName		;Datei-Name ausgeben.
			jsr	StartCopy		;Einzel-Datei kopieren.

::103			AddVBW	16,a2			;Zeiger auf nächste Datei.
			AddVBW	 9,a3
			dec	AnzahlFiles		;Weitere Files kopieren ?
			bne	CopyFiles		;Ja, weiter.

;*** Ende. Zurück zu GeoDOS.
:L211ExitGD		jsr	SetTarget
			jsr	SetGDScrnCol
			jsr	ClrScreen		;Bildschirm löschen.
			jmp	InitScreen

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
			FillRec	180,199, 80,218
			FillRec	180,199,293,319

			ldx	FirstFile
			bne	:102

			ldy	#$0f
::101			lda	(a2L),y			;Datei-Name in Zwischenspeicher.
			sta	GWFileName,y
			dey
			bpl	:101

::102			PrintXY	80,190,GWFileName	;Gesamt-Datei-Name ausgeben.

			LoadW	r11,293			;Anzahl Dateien ausgeben.
			ldx	AnzahlFiles
			dex
			stx	r0L
			ClrB	r0H
			lda	#%11000000
			jmp	PutDecimal

;*** Anzahl Bytes ausgeben.
:CopyInfo		LoadW	r11,80
			LoadB	r1H,197
			lda	DOSFileLen+0
			sta	r0L
			lda	DOSFileLen+1
			sta	r0H
			lda	DOSFileLen+2
			sta	r1L
			ldy	#$09
			jsr	DoZahl24Bit

			LoadW	r11,293			;GeoWrite-Seite ausgeben.
			MoveB	VLIR2_Set,r0L
			ClrB	r0H
			lda	#%11000000
			jmp	PutDecimal

;*** Byte in Speicher übertragen.
:WriteGWByte		ldy	#$00			;Byte in Speicher schreiben.
			sta	(a6L),y
			IncWord	a6			;Zeiger auf Speicher korrigieren.
			IncWord	BytInGWBuf
			rts

;*** Datei-Länge (DOS) um 1 verringern.
:Sub1FileLen		sec
			lda	DOSFileLen +0
			sbc	#$01
			tax
			lda	DOSFileLen +1
			sbc	#$00
			tay
			lda	DOSFileLen +2
			sbc	#$00
			bcc	:101

			sta	DOSFileLen +2
			sty	DOSFileLen +1
			stx	DOSFileLen +0

::101			rts

;*** Trenn-Code einfügen.
:InsLinkCode		ldx	LinkFiles		;Dateien verbinden ?
			beq	:103			;Nein, weiter...

			ldy	AnzahlFiles
			dey				;Letzte Datei ?
			beq	:103			;Ja, Ende...

			cpx	#%10000000		;Seitenvorschub einfügen ?
			bne	:101			;Nein, weiter...
			jsr	EndPage			;Neue Seite einfügen.
			jmp	InitNewPage

::101			cpx	#%01000000		;Zeilenvorschub einfügen ?
			bne	:102			;Nein, weiter...
			lda	#CR			;Leerzeile einfügen.
			jmp	WriteGWByte

::102			rts				;Kein Zwischencode einfügen.

::103			jmp	WriteBuffer		;Seite abschließen.

;*** Nächsten Sektor eines Clusters lesen.
:NxCluSek		dec	a4L			;Alle Sektoren eines
			beq	:101			;Clusters gelesen ?

			jsr	Inc_Sek			;Nächsten Sektor im
			jmp	ReadSektor		;Cluster lesen.

::101			lda	a7L			;Nächsten Cluster
			ldx	a7H			;lesen.
			jsr	Get_Clu
			lda	r1L			;Neue Cluster-Nr.
			ldx	r1H			;merken.
			sta	a7L
			stx	a7H

;*** Cluster Einlesen.
:RdCluSek		cmp	#$f8			;FAT12. Dir-Ende ?
			bcc	:101			;Nein, weiter...
			cpx	#$0f
			bcc	:101
			jmp	CluErr

::101			jsr	Clu_Sek			;Cluster berechnen.
			MoveB	SpClu,a4L		;Zähler setzen.

:ReadSektor		jsr	RdCurDkSek
			jsr	CopyInfo		;Kopieranzeige.
			LoadW	a9,Disk_Sek		;Zeiger auf Sektor.
			LoadW	a5,511 			;Anzahl Bytes / Cluster auf 512 -1.
			rts

:RdCurDkSek		jsr	D_Read			;Ersten Sektor lesen.
			txa
			bne	ReadError
			rts

:CluErr			ldx	#$45
:ReadError		jmp	ExitDskErr		;Disketten-Fehler.

;*** Einzel-Datei kopieren.
:StartCopy		tsx
			stx	StackReg

			jsr	SetSource

			lda	LinkFiles
			beq	:101
			lda	FirstFile
			bne	InitNextFile
			dec	FirstFile

::101			ClrB	AddFiles		;Keine Zusatzfiles.
			jsr	MakeNewGWFile		;GeoWrite-Datei erzeugen.

:InitNextFile		ldx	#$00
			ldy	#$04
			lda	(a3L),y			;Start-Cluster der
			sta	a7L			;DOS-Datei einlesen.
			iny
			lda	(a3L),y
			sta	a7H
			iny
			lda	(a3L),y			;Datei-Größe der
			sta	DOSFileLen +0		;DOS-Datei einlesen.
			iny
			lda	(a3L),y
			sta	DOSFileLen +1
			iny
			lda	(a3L),y
			sta	DOSFileLen +2
			jsr	Sub1FileLen

			lda	a7L			;Ersten Sektor der DOS-Datei lesen.
			ldx	a7H
			jsr	RdCluSek

;*** DOS-Datei kopieren.
:ReadNxByte		ldy	#$00
			lda	(a9L),y			;Byte lesen.
			IncWord	a9			;Zeiger auf nächstes Byte.

			cmp	#NULL			;Zeichen = NULL-Byte ?
			beq	:101			;Ja, überlesen.
			cmp	#LF
			bne	:102
::101			jmp	NextByte

::102			cmp	#PAGE_BREAK		;FF  -Byte ?
			bne	:104			;Nein, weiter...
			bit	DOS_FfMode		;Modus testen.
			bpl	:103			;$00 = Übergehen.
			jsr	EndPage			;Seite abschließen und speichern.
			jsr	InitNewPage		;Neue Seite einrichten.
::103			jmp	NextByte		;Weiter mit nächstem Byte.

::104			cmp	#CR			;CR  -Byte ?
			bne	:106			;Nein, weiter...
			jsr	WriteGWByte		;Byte speichern.
			bit	DOS_FfMode		;Modus testen.
			bmi	:105			;Zeiölen nicht zählen...
			dec	CR_Count		;Zähler korrigieren.
			bne	:105			;Anzahl Zeilen nicht erreicht.
			jsr	EndPage			;Seite abschließen und speichern.
			jsr	InitNewPage		;Neue Seite einrichten.
::105			jmp	NextByte		;Weiter mit nächstem Byte.

::106			tay				;Byte konvertieren.
			lda	ConvTabBase,y
			jsr	WriteGWByte		;Byte in Speicher schreiben.

;*** Zeiger auf nächstes Byte Quell-Datei.
:NextByte		jsr	Sub1FileLen		;Datei-Länge -1.
			bcs	:102			;Ende erreicht ? Nein, weiter.

			jsr	InsLinkCode		;Zusammenfügen von Dateien.

			lda	LinkFiles
			beq	:101
			ldx	AnzahlFiles
			dex
			beq	:101
			rts

::101			jmp	MakeDirEntry

::102			SubVW	1,a5			;Anzahl Bytes pro Sektor -1.
			bcs	:103			;Kompletter Sektor kopiert ?
			jsr	NxCluSek		;Ja, nächsten Sektor lesen.

::103			lda	BytInGWBuf+1
			cmp	#>GWBufSize		;GeoWrite-Puffer für Text-Seite voll ?
			bcc	:104			;Nein, weiter.

			LoadB	FormatText,$ff

			jsr	EndPage			;Seite speichern.
			jsr	InitNewPage
::104			jmp	ReadNxByte		;Weiter mit nächstem Byte.

;*** Neue GeoWrite-Datei erzeugen.
:MakeNewGWFile		ldy	#$00			;Leeren VLIR-Header erzeugen.
::101			lda	#$00
			sta	VLIR2Head,y
			iny
			lda	#$ff
			sta	VLIR2Head,y
			iny
			bne	:101

			lda	#$00
			sta	VLIR2_Set		;Zeiger auf Seite löschen.
			sta	GWFileLen+0		;Flag für "Text formatieren" löschen.
			sta	GWFileLen+1		;Zeiger auf Seite löschen.
			sta	FormatText		;Flag für "Text formatieren" löschen.

;*** Neue Seite erzeugen.
:InitNewPage		inc	VLIR2_Set		;Nr. des aktuellen Datensatzes +1.
			lda	VLIR2_Set		;Seite #62 erreicht ?
			cmp	#MaxGWpages +1		;(max. 61 Seiten je GeoWrite-Datei!)
			bcc	:105			;Nein, weiter.

			jsr	MakeDirEntry		;Datei-Eintrag erzeugen.
			jsr	SetSource
			jsr	RdCurDkSek

			ldx	AddFiles		;Namen für neue Datei erzeugen ?
			bne	:103
::101			lda	GWFileName,x
			beq	:102
			inx
			cpx	#14
			bne	:101

::102			lda	#"_"			;Namens-Zusatz "_x" an Datei-Name
			sta	GWFileName,x		;anhängen.
			inx
			lda	#$40
			sta	GWFileName,x		;Nein, weiter.
			stx	AddFiles		;Kennung Datei-Name erhöhen.

::103			inc	GWFileName,x
			lda	GWFileName,x
			cmp	#$5b			;Max. Anzahl erreicht ?
			bne	:104			;Nein, weiter.
			ldx	StackReg
			txs
			rts				;Nächste Datei kopieren.

::104			jsr	PrintName
			jmp	MakeNewGWFile

::105			ldy	#30			;"ESC_RULER" am Seiten-Anfang
::106			lda	GW_PageData,y		;eintragen.
			sta	Memory2,y
			dey
			bpl	:106

			clc
			lda	#<31
			sta	BytInGWBuf+0
			adc	#<Memory2
			sta	a6L
			lda	#>31
			sta	BytInGWBuf+1
			adc	#>Memory2
			sta	a6H

			lda	LinesPerPage		;Anzahl Zeilen/Seite auf Standardwert.
			sta	CR_Count
			rts

;*** Ende GeoWrite-Datei.
:ChkToFrmtTxt		lda	FormatText		;Text formatieren ?
			beq	:103			;Nein, weiter...

			lda	VLIR2Head+2		;Ersten Sektor lesen.
			sta	r1L
			lda	VLIR2Head+3
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa
			beq	:102
::101			jmp	ExitDskErr		;Disketten-Fehler.

::102			lda	GW_Format + 0		;Flag für "Text formatieren" setzen.
			and	#%11101111
			sta	diskBlkBuf+25

			jsr	PutBlock		;Sektor zurück auf Diskette.
			txa
			bne	:101

::103			rts				;Ende...

;*** Seite abschließen.
:EndPage		lda	VLIR2_Set
			cmp	#MaxGWpages
			bcs	WriteBuffer

			lda	#PAGE_BREAK		;Seitenvorschub in Text
			jsr	WriteGWByte		;einfügen.

;*** Buffer auf Disk (Target) schreiben.
:WriteBuffer		jsr	CopyInfo		;Infos ausgeben.
			lda	BytInGWBuf+0		;Puffergröße ermitteln.
			bne	:101
			lda	BytInGWBuf+1
			bne	:101
			rts				;Ja, Ende.

::101			jsr	SetTarget		;Ziel-Laufwerk aktivieren.

			lda	BytInGWBuf+0		;Puffergröße ermitteln.
			sta	r2L
			lda	BytInGWBuf+1
			sta	r2H
			LoadW	r6,fileTrScTab		;Speicher für Sektor-Nummern.
			jsr	BlkAlloc		;Sektoren belegen.
			txa
			beq	:103
::102			jmp	ExitDskErr

::103			jsr	PutDirHead		;BAM aktualisieren.
			txa
			bne	:102

			LoadW	r6,fileTrScTab		;Zeiger auf Sektor-Tabelle.
			LoadW	r7,Memory2		;Startadresse Zwischenspeicher.
			jsr	WriteFile		;Zwischenspeicher schreiben.
			txa
			bne	:102

			ldy	#$00			;Sektor-Anzahl für CBM-Datei erhöhen.
::104			lda	fileTrScTab,y
			beq	:105
			IncWord	GWFileLen
			iny
			iny
			bne	:104

::105			lda	VLIR2_Set
			asl
			tax
			lda	fileTrScTab +0		;Ersten Sektor der Datei merken.
			sta	VLIR2Head   +0,x
			lda	fileTrScTab +1
			sta	VLIR2Head   +1,x

			jmp	SetSource

;*** GEOS-Datei: VLIR-Header/Info-Block kopieren.
:MakeDirEntry		jsr	SetTarget

			LoadW	r0,GWFileName		;Falls Datei bereits vorhanden,
			jsr	DeleteFile		;Datei löschen.
			txa
			beq	:101
			cpx	#$05
			beq	:101
			jmp	ExitDskErr

::101			jsr	ChkToFrmtTxt		;GeoWrite-Text formatieren ?

			ldy	#$00
::102			lda	VLIR2Head,y		;Info-Block erzeugen.
			sta	Disk2_Sek,y
			iny
			bne	:102

			ldx	#$01			;VLIR-Header schreiben.
			jsr	WrSekOnTrgt
			IncWord	GWFileLen

			ldy	#$00
::103			lda	HdrB000,y		;Info-Block erzeugen.
			sta	Disk2_Sek,y
			iny
			bne	:103

			ldx	#19			;Info-Block schreiben.
			jsr	WrSekOnTrgt
			IncWord	GWFileLen

			jsr	PutDirHead		;BAM auf Diskette speichern.
			txa
			beq	SetEntry
			jmp	ExitDskErr

;*** Datei-Eintrag schreiben.
:SetEntry		jsr	SetDate			;Datum erzeugen.

			ClrB	r10L			;Freien Directory-Eintrag suchen.
			jsr	GetFreeDirBlk
			txa
			beq	:102
::101			jmp	ExitDskErr		;Disketten-Fehler.

::102			ldx	#0
::103			lda	GWFileName,x
			beq	:104
			sta	DirEntry+3,x
			inx
			cpx	#16
			bne	:103
::104			cpx	#16
			beq	:105
			lda	#$a0
			sta	DirEntry+3,x
			inx
			bne	:104

::105			lda	#$80 ! USR		;GeoWrite-Daten festlegen.
			sta	DirEntry +0
			lda	#VLIR
			sta	DirEntry+21
			lda	#APPL_DATA
			sta	DirEntry+22

			ldx	#$00
::106			lda	DirEntry,x		;Datei-Eintrag in Verzeichnis-Sektor
			sta	diskBlkBuf,y		;übertragen.
			iny
			inx
			cpx	#$1c
			bne	:106

			lda	GWFileLen +0		;Dateilänge in Datei-Eintrag schreiben.
			sta	diskBlkBuf+0,y
			lda	GWFileLen +1
			sta	diskBlkBuf+1,y

			LoadW	r4,diskBlkBuf		;Verzeichnis-Sektor zurückschreiben.
			jsr	PutBlock
			txa
			beq	:108
::107			jmp	ExitDskErr		;Disketten-Fehler.

::108			jsr	PutDirHead		;BAM aktualisieren.
			txa				;Diskettenfehler ?
			bne	:107			; => Ja, Abbruch...
			rts

;*** Sektor auf Target-Disk schreiben.
:WrSekOnTrgt		stx	:101 +1
			jsr	GetSekOnTrgt		;Freien Sektor suchen.
::101			ldx	#$ff
			lda	r3L			;Nr. des Sektors in Verzeichnis-
			sta	DirEntry +0,x		;Eintrag schreiben.
			sta	r1L
			lda	r3H
			sta	DirEntry +1,x
			sta	r1H
			LoadW	r4,Disk2_Sek		;Daten auf Disk schreiben.
			jsr	PutBlock
			txa
			beq	:102
			jmp	ExitDskErr		;Disketten-Fehler.
::102			rts

;*** Freien Sektor auf Target suchen.
:GetSekOnTrgt		MoveB	NxFreeSek+0,r3L
			MoveB	NxFreeSek+1,r3H
			jsr	SetNextFree
			txa
			beq	:102
::101			jmp	ExitDskErr		;Disketten-Fehler.

::102			MoveB	r3L,NxFreeSek+0
			MoveB	r3H,NxFreeSek+1
			rts

;*** Datum erzeugen.
:SetDate		lda	SetDateTime
			beq	:102

			ldx	#$04
::101			lda	year,x
			sta	DirEntry+23,x
			dex
			bpl	:101
			rts

::102			ldy	#$03
			jsr	:103
			and	#%00011111
			sta	DirEntry+25		;Tag.
			RORZWordr15L,5
			lda	r15L
			and	#%00001111
			sta	DirEntry+24		;Monat.
			RORZWordr15L,4
			lda	r15L
			and	#%01111111
			clc
			adc	#80
			sta	DirEntry+23		;Jahr.

			ldy	#$01
			jsr	:103
			RORZWordr15L,5
			lda	r15L
			and	#%00111111
			sta	DirEntry+27		;Minute.
			RORZWordr15L,6
			lda	r15L
			and	#%00011111
			sta	DirEntry+26		;Stunde.

			rts

::103			lda	(a3L),y
			sta	r15H
			dey
			lda	(a3L),y
			sta	r15L
			rts

;*** Variablen
:StackPointer		b $00

:DirEntry		s $1e				;GeoWrite-dateieintrag.
:GWFileName		s $11				;DOS-Datei-Name (Ziel-Datei).
:AddFiles		b $00				;=$00 Kein Zusatz-Name, >$00 Pos. für Zusatzname.
:FirstFile		b $00				;$00 = Erste Datei erzeugen.
:VLIR2_Set		b $00				;Zeiger auf Seite.
:DOSFileLen		s $03				;DOS-Datei-Länge.
:GWFileLen		w $0000				;CBM-Datei-Länge.
:BytInGWBuf		w $0000				;Bytes in GW-Seite.
:CR_Count		b $00				;Anzahl Zeilen/Seite.
:FormatText		b $00				;$FF = GW-Seite zu lang, neu formatieren.
:NxFreeSek		b $00,$00			;Suche nach freiem Sektor für CBM-Datei.
:StackReg		b $00

:VLIR2Head		s $0100				;Speicher für VLIR-Header.

if Sprache = Deutsch
:V211a0			b PLAINTEXT
			b "Kopiere :",NULL
:V211a1			b "Bytes   :",NULL
:V211a2			b "Dateien :",NULL
:V211a3			b "Seite   :",NULL
endif

if Sprache = Englisch
:V211a0			b PLAINTEXT
			b "Copy    :",NULL
:V211a1			b "Bytes   :",NULL
:V211a2			b "Files   :",NULL
:V211a3			b "Page    :",NULL
endif

;*** Info-Block für GeoWrite-Textdatei.
:HdrB000		b $00,$ff
:HdrB002		b $03,$15
			j
<MISSING_IMAGE_DATA>
:HdrB068		b $83
:HdrB069		b APPL_DATA
:HdrB070		b VLIR
:HdrB071		w $0000,$ffff,$0000
:HdrB077		b "Write Image V"		;Klasse.
:HdrB090		b "2.0"				;Version.
:HdrB093		b $00,$00,$00,$00		;Reserviert.
:HdrB097		b "GeoDOS 64"			;Autor.
:HdrB106		s 11				;Reserviert.
:HdrB117		b "geoWrite    V"		;Application.
:HdrB130		b "2.0"				;Version.
:HdrB133		b $00,$00,$00,$00		;Reserviert.
:HdrB137		w $0001				;Erste Seite.
:HdrB139		b %00000000			;Titelseite/NLQ-Abstände.
:HdrB140		w $0000				;Höhe Kopfzeile.
:HdrB142		w $0000				;Höhe Fußzeile.
:HdrB144		w $02f0				;Länge einer Seite.
:HdrB146		s 14				;Reserviert.

if Sprache = Deutsch
:HdrB160		b "Konvertierte PCDOS-Datei. "
			b "(w) GeoDOS 64...",NULL
:HdrEnd			s (HdrB000+256)-HdrEnd
endif

if Sprache = Englisch
:HdrB160		b "Converted PCDOS-file. "
			b "(w) GeoDOS 64...",NULL
:HdrEnd			s (HdrB000+256)-HdrEnd
endif

;*** Startadresse Kopierspeicher.
:Memory1
:Memory2		= (Memory1 / 256 +1)*256
