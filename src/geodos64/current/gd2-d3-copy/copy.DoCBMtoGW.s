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

			n	"mod.#217.obj"
			o	ModStart

			jmp	DoCBMtoGW

;*** Quell- und Ziel-Laufwerk setzen.
			t   "-SetDriveCBM"

;*** L217: Datei von Text nach GW kopieren
:ConvTabBase		= SCREEN_BASE
:File_Name		= SCREEN_BASE +256
:File_Datum		= File_Name   +256*16

:EndBuffer		= $7000
:GWBufSize		= $1a00
:MaxGWpages		= 61

:DoCBMtoGW		tsx
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

			PrintXY	  6,190,V217a0		;Text "Kopiere".
			PrintXY	  6,198,V217a1		;Text "Anzahl".
			PrintXY	219,190,V217a2		;Text "Blocks".
			PrintXY	219,198,V217a3		;Text "Seite".

			StartMouse			;Maus aktivieren.
			NoMseKey

			LoadW	a2,File_Name
			LoadW	a3,File_Datum

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

:CopyFiles		lda	pressFlag		;Abbruch ?
			bne	L217ExitGD		;Ja, Ende...

			lda	AnzahlFiles		;Dateien = 0 ?
			beq	L217ExitGD		;Ja, Ende...

			jsr	PrintName		;Dateiname ausgeben.
			jsr	StartCopy		;Einzel-Datei kopieren.

			AddVBW	16,a2			;Zeiger auf nächste Datei.
			AddVBW	10,a3

			dec	AnzahlFiles		;Weitere Files kopieren ?
			bne	CopyFiles		;Ja, weiter.

;*** Ende. Zurück zu GeoDOS.
:L217ExitGD		jsr	SetTarget
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
			FillRec	180,199, 80,218
			FillRec	180,199,293,319

			ldx	FirstFile		;Dateiname definieren ?
			bne	:102			;Nein, überspringen.

			ldy	#$0f
::101			lda	(a2L),y			;Dateiname in Zwischenspeicher.
			sta	GWFileName,y
			dey
			bpl	:101

::102			PrintXY	80,190,GWFileName

			LoadW	r11,293			;Anzahl Dateien ausgeben.
			ldx	AnzahlFiles
			dex
			stx	r0L
			ClrB	r0H
			lda	#%11000000
			jmp	PutDecimal

;*** Dateilänge ausgeben.
:CopyInfo		LoadW	r11,80
			LoadB	r1H,198
			MoveW	CBMFileLen,r0
			ClrB	r1L
			ldy	#$09
			jsr	DoZahl24Bit

			LoadW	r11,293			;GeoWrite-Seite ausgeben.
			MoveB	VLIR_Set,r0L
			ClrB	r0H
			lda	#%11000000
			jsr	PutDecimal
			lda	#" "
			jmp	SmallPutChar

;*** Byte in Speicher übertragen.
:WriteGWByte		ldy	#$00			;Byte in Speicher schreiben.
			sta	(a6L),y
			IncWord	a6			;Zeiger auf Speicher korrigieren.
			IncWord	BytInGWBuf		;Bytes in Puffer erhöhen.
			rts

;*** Dateilänge -1
:Sub1FileLen		CmpW0	CBMFileLen
			beq	:101
			SubVW	1,CBMFileLen
::101			rts

;*** Trenn-Code einfügen.
:InsLinkCode		ldx	LinkFiles		;Dateien verbinden ?
			beq	:103			;Nein, weiter...

			ldy	AnzahlFiles
			dey				;Letzte Datei ?
			beq	:103			;Ja, Ende...

			lda	VLIR_Set		;Seite #62 erreicht ?
			cmp	#MaxGWpages		;(max. 61 Seiten je GeoWrite-Datei!)
			beq	:103			;Nein, weiter.

			cpx	#%10000000		;Seitenvorschub einfügen ?
			bne	:101			;Nein, weiter...
			jsr	EndPage			;Neue Seite einfügen.
			jmp	InitNewPage

::101			cpx	#%01000000		;Zeilenvorschub einfügen ?
			bne	:102			;Nein, weiter...
			lda	#CR			;Leerzeile einfügen.
			jsr	WriteGWByte

			bit	Txt_FfMode		;Modus testen.
			bmi	:102			;Zeiölen nicht zählen...
			dec	CR_Count		;Zähler korrigieren.
			bne	:102			;Anzahl Zeilen nicht erreicht.
			jsr	EndPage			;Seite abschließen und speichern.
			jsr	InitNewPage		;Neue Seite einrichten.
::102			rts				;Kein Zwischencode einfügen.

::103			jmp	WritePage		;Seite abschließen.

;*** Einzel-Datei kopieren.
:StartCopy		jsr	SetSource		;Quell-Laufwerk aktivieren.

			lda	LinkFiles		;Dateien verbinden ?
			beq	:101			;Nein, initialisieren.
			lda	FirstFile		;Erste Datei ?
			bne	InitNextFile		;Nein übergehen.
			dec	FirstFile

::101			ClrB	AddFiles
			jsr	MakeNewGWFile		;GeoWrite-Datei initialisieren.

:InitNextFile		ldy	#$07			;Adr. des Verzeichnis-Sektors mit
			lda	(a3L),y			;Datei-Eintrag einlesen.
			sta	r1L
			iny
			lda	(a3L),y
			sta	r1H
			iny
			lda	(a3L),y			;Zeiger auf Datei-Eintrag in
			sta	:101 +1 			;Verzeichnis-Sektor einlesen.
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Sektor mit Datei-Eintrag einlesen.
			txa
			beq	:101
			jmp	ExitDskErr		;Disketten-Fehler.

::101			ldx	#$ff
			lda	diskBlkBuf+1,x		;Adr. des ersten Daten-Sektors merken.
			sta	CurCBMsek +0
			lda	diskBlkBuf+2,x
			sta	CurCBMsek +1

			ldy	#$00
::102			lda	(a3L),y			;Datum-/Uhrzeit für Ziel-Datei
			sta	DirEntry +23,y		;festlegen.
			iny
			cpy	#$05
			bne	:102

			lda	diskBlkBuf+28,x		;Dateilänge Quell-Datei merken.
			sta	CBMFileLen+ 0
			lda	diskBlkBuf+29,x
			sta	CBMFileLen+ 1

			clc				;Anzahl Bytes in Puffer
			lda	BytInGWBuf+0		;korrigieren. Kann bei "LinkFiles"
			adc	#<Memory2		;zu Beginn einer neuen Quell-Datei
			sta	a6L			;auch <> 0 sein!
			lda	BytInGWBuf+1
			adc	#>Memory2
			sta	a6H
			jmp	ReadNxSek

;*** Seite abschließen.
:EndPage		lda	VLIR_Set
			cmp	#MaxGWpages		;Letzte Seite ?
			bcs	WritePage		;Ja, kein PAGE_BREAK einfügen.

			lda	#PAGE_BREAK		;Seitenvorschub in Text
			jsr	WriteGWByte		;einfügen.

;*** Seite auf Disk schreiben.
:WritePage		jsr	CopyInfo		;Infos ausgeben.
			CmpW0	BytInGWBuf		;Puffergröße ermitteln.
			bne	:101
			rts				;Ja, Ende.

::101			jsr	SetTarget		;Ziel-Laufwerk aktivieren.

			MoveW	BytInGWBuf,r2
			LoadW	r6,fileTrScTab		;Speicher für Sektor-Nummern.
			jsr	BlkAlloc		;Sektoren belegen.
			txa
			beq	:103
::102			jmp	ExitDskErr		;Disketten-Fehler.

::103			jsr	PutDirHead		;BAM aktualisieren.
			txa
			bne	:102

			LoadW	r6,fileTrScTab		;Zeiger auf Sektor-Tabelle.
			LoadW	r7,Memory2		;Startadresse Zwischenspeicher.
			jsr	WriteFile		;Zwischenspeicher schreiben.
			txa
			bne	:102

			ldy	#$00
::104			lda	fileTrScTab,y		;Dateilänge Ziel-Datei korrigieren.
			beq	:105
			IncWord	GWFileLen
			iny
			iny
			bne	:104

::105			lda	VLIR_Set
			asl
			tax
			lda	fileTrScTab+0		;Ersten Sektor der Datei merken.
			sta	Copy2Sek  +0,x
			lda	fileTrScTab+1
			sta	Copy2Sek  +1,x

			jmp	SetSource		;Quell-Laufwerk aktivieren.

;*** Ziel-Datei einlesen.
:ReadNxSek		jsr	RdCurDkSek
			jsr	Sub1FileLen		;Anzahl Blocks -1.
			jsr	CopyInfo		;Info ausgeben.

			ldy	#$ff
			lda	Copy1Sek+0
			bne	:101
			ldy	Copy1Sek+1
::101			sty	NextByte +4

			ldx	#$02			;Zeiger auf erstes Byte in Quell-Datei.
			stx	ReadNxByte+1

;*** Nächstes Byte aus Datei lesen.
:ReadNxByte		ldx	#$ff
			lda	Copy1Sek,x		;Byte einlesen.
			tay
			lda	ConvTabBase,y		;Zeichen übersetzen.
			beq	:101			;NULL-Byte Übergehen...
			cmp	#LF			;LF  -Byte Übergehen...
			bne	:102
::101			jmp	NextByte

::102			cmp	#PAGE_BREAK		;FF  -Byte ?
			bne	:104			;Nein, weiter...
			bit	Txt_FfMode		;Modus testen.
			bpl	:103			;$00 = Übergehen.
			jsr	EndPage			;Seite abschließen und speichern.
			jsr	InitNewPage		;Neue Seite einrichten.
::103			jmp	NextByte		;Weiter mit nächstem Byte.

::104			cmp	#CR			;CR  -Byte ?
			bne	:106			;Nein, weiter...
			bit	Txt_FfMode		;Modus testen.
			bmi	:106			;Zeiölen nicht zählen...
			dec	CR_Count		;Zähler korrigieren.
			bne	:106			;Anzahl Zeilen nicht erreicht.
			jsr	WriteGWByte		;Byte speichern.
			jsr	EndPage			;Seite abschließen und speichern.
			jsr	InitNewPage		;Neue Seite einrichten.
::105			jmp	NextByte		;Weiter mit nächstem Byte.

::106			jsr	WriteGWByte		;Byte in Puffer schreiben...

;*** Zeiger auf nächstes Byte der Quell-Datei.
:NextByte		ldx	ReadNxByte +1
			cpx	#$ff
			beq	:101
			inc	ReadNxByte +1
			jmp	ReadNxByte

::101			lda	Copy1Sek+1
			sta	CurCBMsek+1
			lda	Copy1Sek+0
			sta	CurCBMsek+0
			bne	:103

			jsr	InsLinkCode

			lda	LinkFiles
			beq	:102
			ldx	AnzahlFiles
			dex
			beq	:102
			rts

::102			jmp	MakeDirEntry

::103			lda	BytInGWBuf+1
			cmp	#>GWBufSize		;Puffer voll ?
			bcc	:104			;Nein, nächsten Sektor lesen.

			LoadB	FormatText,$ff		;Text beim Erststart formatieren.

			jsr	EndPage			;Seite abschließen und speichern.
			jsr	InitNewPage		;Speicher auf Disk schreiben.
::104			jmp	ReadNxSek		;Nächsten Sektor lesen.

;*** Aktuellen Sektor lesen.
:RdCurDkSek		MoveW	CurCBMsek,r1		;Track/Sektor für Quell-Datei.
			LoadW	r4,Copy1Sek		;Zeiger auf Zwischenspeicher.
			jsr	InitForIO
			jsr	ReadBlock		;Sektor lesen.
			jsr	DoneWithIO
			txa
			bne	:101
			rts

::101			jmp	ExitDskErr		;Disketten-Fehler.

;*** Neue GeoWrite-Datei erzeugen.
:MakeNewGWFile		ldy	#$00
::101			lda	#$00			;Leeren VLIR-Header erzeugen.
			sta	Copy2Sek,y
			iny
			lda	#$ff
			sta	Copy2Sek,y
			iny
			bne	:101

			lda	#$00
			sta	VLIR_Set		;Zeiger auf GW-Seite.
			sta	GWFileLen +0		;GW-Dateilänge.
			sta	GWFileLen +1
			sta	FormatText		;GW-Datei nach Start neu formatieren.

;*** Neue Seite erzeugen.
:InitNewPage		inc	VLIR_Set		;Zeiger auf nächste Seite...
			lda	VLIR_Set		;Seite #62 erreicht ?
			cmp	#MaxGWpages +1		;(max. 61 Seiten je GeoWrite-Datei!)
			bne	:105			;Nein, weiter.

			jsr	MakeDirEntry2		;Datei-Eintrag erzeugen.
			jsr	SetSource
			jsr	RdCurDkSek

			ldx	AddFiles		;Namen für neue Datei erzeugen ?
			bne	:103			;Nein, weiter...
::101			lda	GWFileName,x		;Länge Quell-Dateiname ermitteln.
			beq	:102
			inx
			cpx	#14
			bne	:101

::102			lda	#"_"			;Namens-Zusatz "_x" an Dateiname
			sta	GWFileName,x		;anhängen.
			inx
			lda	#$40
			sta	GWFileName,x
			stx	AddFiles		;Position Namens-Zusatz merken.

::103			inc	GWFileName,x		;Zähler für Zusatzdateien erhöhen.
			lda	GWFileName,x		;Letzte Datei erreicht ?
			cmp	#$5b
			bne	:104			;Nein, weiter.
			pla				;Max. 26 Zusatzfiles erzeugt, kopieren
			pla				;beenden. Somit werden max.
			pla				;27 Dateien a 61 Seiten erzeugt!
			pla
			ClrB	FirstFile		;Kopiervorgang mit nächster Datei.
			rts				;fortsetzen.

::104			jsr	PrintName
			jmp	MakeNewGWFile		;Neue GeoWrite-Datei anlegen.

::105			ldy	#30			;"ESC_RULER" am Seiten-Anfang
::106			lda	GW_PageData,y		;eintragen.
			sta	Memory2,y
			dey
			bpl	:106

			clc
			lda	#31
			sta	BytInGWBuf+0
			adc	#<Memory2
			sta	a6L
			lda	#0
			sta	BytInGWBuf+1
			adc	#>Memory2
			sta	a6H

			lda	LinesPerPage		;Anzahl Zeilen/Seite auf Standardwert.
			sta	CR_Count
			rts

;*** Ende GeoWrite-Datei.
:ChkToFrmtTxt		lda	FormatText		;Text formatieren ?
			beq	:103			;Nein, weiter...

			lda	Copy2Sek+2		;Ersten Sektor lesen.
			sta	r1L
			lda	Copy2Sek+3
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

;*** GEOS-Datei: VLIR-Header/Info-Block kopieren.
:MakeDirEntry		lda	LinkFiles		;Dateien verbinden ?
			beq	MakeDirEntry2		;Nein, Eintrag erzeugen.
			lda	AnzahlFiles
			cmp	#$01			;Letzte Datei kopiert ?
			beq	MakeDirEntry2		;Ja, Eintrag erzeugen.
			rts

:MakeDirEntry2		jsr	SetTarget		;Ziel-Laufwerk aktivieren.
			jsr	ChkToFrmtTxt		;GeoWrite-Text formatieren ?

			ldx	#$01			;VLIR-Header schreiben.
			jsr	WrSekOnTrgt
			IncWord	GWFileLen

			ldy	#$00
::101			lda	HdrB000,y		;Info-Block erzeugen.
			sta	Copy2Sek,y
			iny
			bne	:101
			ldx	#19			;Info-Block schreiben.
			jsr	WrSekOnTrgt
			IncWord	GWFileLen

			jsr	PutDirHead
			txa
			beq	SetEntry
			jmp	ExitDskErr

;*** Datei-Eintrag schreiben.
:SetEntry		ClrB	r10L			;Freien Directory-Eintrag suchen.
			jsr	GetFreeDirBlk
			txa
			beq	:102
::101			jmp	ExitDskErr		;Disketten-Fehler.

::102			ldx	#0
::103			lda	GWFileName,x		;Dateiname in Verzeichnis-Eintrag
			beq	:104			;übertragen.
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
			sta	DirEntry+0
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
			jmp	SetSource		;Ziel-Laufwerk aktivieren.

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
			LoadW	r4,Copy2Sek		;Daten auf Disk schreiben.
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

;*** Variablen:
:StackPointer		b $00				;Stack-Zeiger.

:DirEntry		s $1e				;Directory-Eintrag.
:FirstFile		b $00				;Erste Datei-Initialisierung.
:VLIR_Set		b $00				;Zeiger auf GW-Seite.
:GWFileLen		w $0000				;GW-Dateilänge.
:CBMFileLen		w $0000				;CBM-Dateilänge.
:BytInGWBuf		w $0000				;Bytes in GW-Puffer.
:FormatText		b $00				;GW-Datei nach Start neu formatieren.
:CurCBMsek		b $00,$00			;Aktueller Sektor CBM-Datei.
:NxFreeSek		b $00,$00			;Suche nach freiem Sektor.
:AddFiles		b $00				;$00, Keine Zusatzfiles, >$00, Pos. für Zusatzname.
:GWFileName		s $11				;Name GW-Datei.
:CR_Count		b $00				;Anzahl Zeilen pro Seite.

if Sprache = Deutsch
:V217a0			b PLAINTEXT
			b "Kopiere :",NULL
:V217a1			b "Blocks  :",NULL
:V217a2			b "Dateien :",NULL
:V217a3			b "Seite   :",NULL
endif

if Sprache = Englisch
:V217a0			b PLAINTEXT
			b "Copy    :",NULL
:V217a1			b "Blocks  :",NULL
:V217a2			b "Files   :",NULL
:V217a3			b "Page    :",NULL
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
:HdrB160		b "Konvertierte Text-Datei.",CR
			b "(w) GeoDOS 64...",NULL
:HdrEnd			s (HdrB000+256)-HdrEnd
endif

if Sprache = Englisch
:HdrB160		b "Converted textfile.",CR
			b "(w) GeoDOS 64...",NULL
:HdrEnd			s (HdrB000+256)-HdrEnd
endif

;*** Startadresse Kopierspeicher.
:Memory1
:Memory2		= (Memory1 / 256 +1)*256
