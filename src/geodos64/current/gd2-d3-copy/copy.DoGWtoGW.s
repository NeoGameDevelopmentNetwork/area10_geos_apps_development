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

			n	"mod.#219.obj"
			o	ModStart

			jmp	DoGWtoGW

;*** Quell- und Ziel-Laufwerk setzen.
			t   "-SetDriveCBM"

;*** L219: Datei von GeoWrite nach GeoWrite kopieren
:ConvTabBase		= SCREEN_BASE
:File_Name		= SCREEN_BASE +256
:File_Datum		= File_Name   +256*16

:EndBuffer		= $7000
:GWBufSize		= $1a00
:MaxGWpages		= 61

;A2  = Zeiger auf Datei-Namen.
;A3  = Zeiger auf Datei-Datum.

:DoGWtoGW		tsx
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

			PrintXY	  6,190,V219a0		;Text "Kopiere".
			PrintXY	  6,198,V219a1		;Text "Anzahl".
			PrintXY	219,190,V219a2		;Text "BLocks".

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

:CopyFiles		lda	pressFlag		;Abbruch durch Maus-Klick ?
			bne	L219ExitGD		;Ja, Ende...

			lda	AnzahlFiles		;Alle Dateien kopiert ?
			beq	L219ExitGD		;Ja, Ende...

			jsr	PrintName		;Datei-Name ausgeben.
			jsr	StartCopy		;Einzel-Datei kopieren.

			AddVBW	16,a2			;Zeiger auf nächste Datei.
			AddVBW	10,a3

			dec	AnzahlFiles		;Alle Dateien kopiert ?
			bne	CopyFiles		;Nein, weiter...

;*** Ende. Zurück zu GeoDOS.
:L219ExitGD		jsr	SetTarget
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

			ldy	#$0f
::101			lda	(a2L),y			;Dateiname in Zwischenspeicher
			sta	GWFileName,y		;kopieren.
			dey
			bpl	:101

			PrintXY	80,190,GWFileName

			LoadW	r11,293			;Anzahl Dateien ausgeben.
			ldx	AnzahlFiles
			dex
			stx	r0L
			ClrB	r0H
			lda	#%11000000
			jmp	PutDecimal

;*** CopyInfo ausgeben.
:CopyInfo		LoadW	r11,80
			LoadB	r1H,198
			MoveW	GW1FileLen,r0
			ClrB	r1L
			ldy	#$09
			jmp	DoZahl24Bit

;*** Datensatz-Nummer asgeben.
:PrintVLIR		LoadW	r11,219			;Cursor positionieren.
			LoadB	r1H,198

			lda	#<V219a3		;Zeiger auf Text "Seite :"
			ldx	#>V219a3
			ldy	VLIR1_Set
			cpy	#MaxGWpages+3
			bcc	:101
			lda	#<V219a4		;Zeiger auf Text "Scrap :"
			ldx	#>V219a4
::101			sta	r0L
			stx	r0H
			jsr	PutString		;Text ausgeben.

			LoadW	r11,293
			lda	VLIR1_Set		;Datensatz-Nr. = Seite ausgeben.
			cmp	#MaxGWpages+3		;Datensatz < 65 ?
			bcc	:102			;Ja, weiter...
			sub	64			;Nr. des Photo-Scraps berechnen.
::102			sta	r0L
			ClrB	r0H
			lda	#%11000000		;Datensatz ausgeben.
			jmp	PutDecimal

;*** ESC_RULER.
:Modify_a		ldy	#27 -1
			bit	GW_Modify
			bmi	Modify_a1
			sty	IgnoreBytes
			jmp	L219b1

:Modify_a1		sty	CopyBytes
			sta	GW_Command
			jmp	L219b0

;*** NEWCARDSET.
:Modify_b		ldy	#4 -1
			bit	GW_Modify
			bvs	Modify_a1
			bmi	:101
			sty	IgnoreBytes
			jmp	L219b1

::101			sty	CopyBytes
			pha
			ora	#%10000000
			sta	GW_Command
			pla
			jmp	L219b0

;*** PAGE_BREAK.
:Modify_c		bit	GW_Modify
			bmi	:101
			bit	Txt_FfMode
			bpl	:102
::101			jmp	L219a1
::102			jmp	L219b1

;*** ESC_GRAPHICS.
:Modify_d		ldy	#5 -1
			sty	CopyBytes
			sta	GW_Command
			jmp	L219b0

;*** Einzel-Datei kopieren.
:StartCopy		jsr	SetSource		;Quell-Laufwerk aktivieren.
			jsr	MakeNewGWFile

			ldy	#$07			;Adr. des Verzeichnis-Sektors mit
			lda	(a3L),y			;Datei-Eintrag einlesen.
			sta	r1L
			iny
			lda	(a3L),y
			sta	r1H
			iny
			lda	(a3L),y			;Zeiger auf Datei-Eintrag in
			sta	:102 +1 			;Verzeichnis-Sektor einlesen.
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Sektor mit Datei-Eintrag einlesen.
			txa
			beq	:102
::101			jmp	vCopyError		;Disketten-Fehler.

::102			ldx	#$ff
			lda	diskBlkBuf+1,x		;Adresse VLIR-Header merken.
			sta	r1L
			lda	diskBlkBuf+2,x
			sta	r1H

			lda	diskBlkBuf  +19,x
			sta	GW_InfoBlock+ 0
			lda	diskBlkBuf  +20,x
			sta	GW_InfoBlock+ 1

			ldy	#$00
::103			lda	(a3L),y			;Datum-/Uhrzeit für Ziel-Datei
			sta	DirEntry +23,y		;festlegen.
			iny
			cpy	#$05
			bne	:103

			lda	diskBlkBuf+28,x		;Dateilänge Quell-Datei merken.
			sta	GW1FileLen+ 0
			lda	diskBlkBuf+29,x
			sta	GW1FileLen+ 1
			LoadW	r4,Copy2Sek		;VLIR-Header Quell-Datei einlesen.
			jsr	GetBlock
			txa
			bne	:101

			bit	GW_Modify
			bpl	:104

			lda	GW_InfoBlock+0		;Infoblock einlesen.
			sta	r1L
			lda	GW_InfoBlock+1
			sta	r1H
			LoadW	r4,HdrB000		;VLIR-Header Quell-Datei einlesen.
			jsr	GetBlock
			txa
			bne	:101

::104			jsr	InitScrapHead

;*** Text-Seiten kopieren.
:CopyMode1		lda	#$00			;Zeiger auf VLIR-Einträge
			sta	VLIR1_Set		;initialisieren.
			sta	VLIR2_Set
			jsr	SetNewPage		;Neue Seite einrichten.

::101			inc	VLIR1_Set
			lda	VLIR1_Set
			cmp	#MaxGWpages +1		;Kopf-/Fußzeile ?
			bcc	:102			;Nein, weiter...
			sta	VLIR2_Set		;Zeiger auf VLIR-Datensatz Ziel-Datei.
::102			cmp	#MaxGWpages +4		;Photoscraps ?
			bcc	:103			;Nein, Textseite kopieren.
			jmp	CopyMode2		;Photoscraps kopieren.

::103			asl
			tax
			lda	Copy2Sek+0,x		;VLIR-Datensatz belegt ?
			beq	:101			;Nein, nicht kopieren.
			sta	CurGWsek +0
			lda	Copy2Sek+1,x
			sta	CurGWsek +1
			jsr	PrintVLIR		;Datensatz-Nr. ausgeben.

			lda	#$00
			sta	IgnoreBytes
			sta	CopyBytes
			sta	GW_Command
			sta	GW_ComPoi
			jsr	CopyTextPage		;Textseite kopieren.
			jmp	:101			;Nächsten Datensatz kopieren.

;*** Photoscraps kopieren.
:CopyMode2		dec	VLIR1_Set
::101			inc	VLIR1_Set		;Zeiger auf nächsten Datensatz.
			lda	VLIR1_Set
			sta	VLIR2_Set
			asl
			tax
			bne	:102
			jmp	MakeDirEntry		;Dateieintrag erzeugen.

::102			lda	Copy2Sek+0,x		;VLIR-Datensatz belegt ?
			beq	:101			;Nein, nicht kopieren.
			sta	CurGWsek +0
			lda	Copy2Sek+1,x
			sta	CurGWsek +1
			jsr	PrintVLIR		;Datensatz-Nr. ausgeben.

			lda	#$00			;Kopiervorgang initialisieren.
			sta	GW1stSek  +0
			sta	GW1stSek  +1
			sta	BytInGWBuf+0
			sta	BytInGWBuf+1
			LoadW	a6,Memory2

::103			jsr	ReadVLIRfile		;Photoscrap kopieren.
			tax				;Ende erreicht ?
			beq	:104			;Ja alle Daten schreiben.
			jsr	WriteBuffer		;Puffer speichern.
			jmp	:103			;Kopieren fortsetzen.
::104			jsr	WriteAllData		;Alle Daten speichern.
			jmp	:101			;Nächsten Datensatz kopieren.

;*** Textseite einlesen.
:CopyTextPage		MoveW	CurGWsek,r1		;Track/Sektor für Quell-Datei.
			LoadW	r4,Copy1Sek		;Zeiger auf Zwischenspeicher.
			jsr	InitForIO
			jsr	ReadBlock		;Sektor lesen.
			jsr	DoneWithIO
			txa
			beq	:101
			jmp	vCopyError		;Disketten-Fehler.

::101			jsr	Sub1FileLen		;Anzahl Blocks -1.
			jsr	CopyInfo		;Info ausgeben.
			ldy	#$ff			;Anzahl Bytes berechnen.
			lda	Copy1Sek +0
			bne	:102
			ldy	Copy1Sek +1
::102			sty	L219b2 +1
			ldx	#$02			;Zeiger auf erstes Byte.
			stx	L219a0+1

;*** Textseite einlesen (Fortsetzung).
:L219a0			ldx	#$ff
			ldy	IgnoreBytes		;Aktuelles Byte ignorieren ?
			beq	:101			;Nein, kopieren.
			dec	IgnoreBytes		;Byte übergehen.
			jmp	L219b1			;Weiter mit nächstem Byte.

::101			lda	Copy1Sek,x		;Byte einlesen.
			ldy	CopyBytes		;Datei 1:1 kopieren ?
			beq	:104			;Nein, weiter...

			ldy	GW_Command
			cpy	#NEWCARDSET ! $80
			bne	:102
			ldy	GW_ComPoi
			lda	GW_Font+1,y
			inc	GW_ComPoi

::102			jsr	WriteGWByte		;Byte in Puffer schreiben.
			dec	CopyBytes
			bne	:103

			ldy	GW_Command
			cpy	#ESC_GRAPHICS
			bne	:103
			jsr	App_Scrap

::103			jmp	L219b1			;Weiter mit nächstem Byte.

::104			sty	GW_Command
			sty	GW_ComPoi

			cmp	#ESC_RULER		;"ESC_RULER" ausfiltern.
			beq	L219a2
			cmp	#NEWCARDSET		;"NEWCARDSET" ausfiltern.
			beq	L219a3
			cmp	#PAGE_BREAK		;"FormFeed" ?
			beq	L219a4
			cmp	#ESC_GRAPHICS		;"ESC_GRAPHICS" übernehmen.
			beq	L219a5

			cmp	#CR			;"Carriage Return" ?
			bne	L219b0			;Nein, weiter...
			bit	GW_Modify
			bmi	L219b0
			bit	Txt_FfMode		;Modus testen.
			bmi	L219b0			;Zeilen nicht zählen...
			dec	CR_Count		;Zähler korrigieren.
			bne	L219b0			;Anzahl Zeilen nicht erreicht.
			jsr	WriteGWByte		;Byte speichern.

;*** Seite abschließen, nächste Seite kopieren.
:L219a1			jsr	EndPage			;Seite abschließen und speichern.
			jsr	SetNewPage
			jmp	L219b1			;Weiter mit nächstem Byte.

:L219a2			jmp	Modify_a
:L219a3			jmp	Modify_b
:L219a4			jmp	Modify_c
:L219a5			jmp	Modify_d

;*** Byte in Speicher übertragen.
:L219b0			jsr	WriteGWByte

;*** Zeiger auf nächstes Byte.
:L219b1			ldx	L219a0 +1
:L219b2			cpx	#$ff
			beq	:101
			inc	L219a0 +1
			jmp	L219a0

::101			lda	Copy1Sek+1		;Adresse des nächsten Sektors in
			sta	CurGWsek +1		;Speicher übertragen.
			lda	Copy1Sek+0
			sta	CurGWsek +0		;Letzter Sektor ?
			bne	:104			;Nein, weiter...

			lda	VLIR1_Set
			cmp	#MaxGWpages		;Kopf-/Fußzeile ?
			bcs	:102			;Ja, alle Daten schreiben.
			asl
			tax
			lda	Copy2Sek +2,x		;Weitere Seite vorhanden ?
			bne	:103			;Ja, übergehen.

::102			jsr	WriteAllData		;Alle Daten aus Puffer schreiben.
			jsr	SetNewPage		;Neue Seite einrichten.
::103			rts				;Ende.

::104			lda	BytInGWBuf +1
			cmp	#>GWBufSize		;Speicher voll ?
			bcc	:105			;Nein, weiter...

			LoadB	FormatText,$ff
			jsr	EndPage			;Seite speichern.
			jsr	SetNewPage		;Neue Seite einrichten.
::105			jmp	CopyTextPage

;*** Daten in Puffer einlesen.
:ReadVLIRfile		MoveW	CurGWsek,r1		;Track/Sektor für Quell-Datei.
			LoadW	r4,Copy1Sek		;Zeiger auf Zwischenspeicher.
			jsr	InitForIO
			jsr	ReadBlock		;Sektor lesen.
			jsr	DoneWithIO
			txa
			beq	:102
			jmp	vCopyError		;Disketten-Fehler.

::102			jsr	Sub1FileLen		;Anzahl Blocks -1.
			jsr	CopyInfo		;Info ausgeben.

			ldy	#$ff			;Anzahl Bytes berechnen.
			lda	Copy1Sek +0
			bne	:103
			ldy	Copy1Sek +1
::103			sty	:105 +1

			ldx	#$02
			ldy	#$00
::104			lda	Copy1Sek,x		;Byte aus Sektor in Zwischenspeicher
			sta	(a6L),y			;übertragen.
			IncWord	BytInGWBuf
			iny
::105			cpx	#$ff
			beq	:106
			inx
			bne	:104

::106			tya				;Zeiger auf Zwischenspeicher
			clc				;korrigieren.
			adc	a6L
			sta	a6L
			lda	#$00
			adc	a6H
			sta	a6H

			lda	Copy1Sek+1		;Adresse des nächsten Sektors in
			sta	CurGWsek +1		;Speicher übertragen.
			lda	Copy1Sek+0
			sta	CurGWsek +0		;Letzter Sektor ?
			bne	:107			;Nein, weiter...
			rts

::107			lda	a6H
			cmp	#>EndBuffer		;Speicher voll ?
			bcc	ReadVLIRfile		;Nein, weiter...
			lda	#$ff
			rts

;*** Byte in Speicher übertragen.
:WriteGWByte		ldy	#$00			;Byte in Speicher schreiben.
			sta	(a6L),y
			IncWord	a6			;Zeiger auf Speicher korrigieren.
			IncWord	BytInGWBuf		;Bytes in Puffer erhöhen.
			rts

;*** Dateilänge -1
:Sub1FileLen		CmpW0	GW1FileLen		;Alle Blocks kopiert ?
			beq	:101			;Nein, weiter.
			SubVW	1,GW1FileLen		;Anzahl Blocks -1.
::101			rts

;*** Scrap-Header initialisieren.
:InitScrapHead		ldy	#$00
::101			lda	Copy2Sek +$82,y
			sta	GW_Scraps+$00,y
			lda	Copy2Sek +$83,y
			sta	GW_Scraps+$01,y
			lda	#$00
			sta	Copy2Sek +$82,y
			lda	#$ff
			sta	Copy2Sek +$83,y
			iny
			iny
			cpy	#$7e
			bne	:101
			rts

;*** Scrap-Nr. in VLIR-header übernehmen.
:App_Scrap		sub	$40
			asl
			tay
			lda	GW_Scraps +$00,y
			sta	Copy2Sek  +$82,y
			lda	GW_Scraps +$01,y
			sta	Copy2Sek  +$83,y
			rts

;*** Neue GeoWrite-Datei erzeugen.
:MakeNewGWFile		ldy	#$00
::101			lda	#$00			;Leeren VLIR-Header erzeugen.
			sta	VLIR2Head,y
			iny
			lda	#$ff
			sta	VLIR2Head,y
			iny
			bne	:101

			lda	#$00
			sta	GW2FileLen +0		;GW-Dateilänge löschen.
			sta	GW2FileLen +1
			sta	FormatText		;GW-Datei nach Start neu formatieren.
			rts

;*** Zeiger auf neue seite richten.
:SetNewPage		inc	VLIR2_Set

;*** Neue Seite erzeugen.
:InitNewPage		LoadW	a6,Memory2

			bit	GW_Modify
			bmi	:103

			ldy	#26			;"ESC_RULER" am Seiten-Anfang
::101			lda	GW_PageData,y		;eintragen.
			sta	(a6L),y
			dey
			bpl	:101
			AddVBW	27,a6

			bit	GW_Modify
			bvs	:103

			ldy	#3			;"ESC_RULER" am Seiten-Anfang
::102			lda	GW_Font,y		;eintragen.
			sta	(a6L),y
			dey
			bpl	:102
			AddVBW	4,a6

::103			sec
			lda	a6L
			sbc	#<Memory2
			sta	BytInGWBuf+0
			lda	a6H
			sbc	#>Memory2
			sta	BytInGWBuf+1

			lda	LinesPerPage		;Anzahl Zeilen/Seite auf Standardwert.
			sta	CR_Count
			ClrW	GW1stSek
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
::101			jmp	vCopyError		;Disketten-Fehler.

::102			lda	GW_Format + 0		;Flag für "Text formatieren" setzen.
			and	#%11101111
			sta	diskBlkBuf+25

			jsr	PutBlock		;Sektor zurück auf Diskette.
			txa
			bne	:101

::103			rts				;Ende...

;*** Seite abschließen.
:EndPage		lda	VLIR2_Set
			cmp	#MaxGWpages		;Letzte Seite ?
			bcs	WriteBuffer		;Ja, kein PAGE_BREAK einfügen.

			lda	#PAGE_BREAK		;Seitenvorschub in Text
			jsr	WriteGWByte		;einfügen.

;*** Kompletten Buffer speichern.
:WriteAllData		LoadB	GW_EOF,$ff

;*** Buffer auf Disk (Target) schreiben.
:WriteBuffer		jsr	CopyInfo		;Infos ausgeben.
			CmpW0	BytInGWBuf		;Puffergröße ermitteln.
			bne	:101			;Speicher leer ?
			rts				;Ja, Ende.

::101			jsr	SetTarget		;Ziel-Laufwerk aktivieren.

			MoveW	BytInGWBuf,r2		;Puffergröße nach r2.

			lda	GW_EOF			;Datei-Ende erreicht ?
			bne	:102			;Ja, alle Bytes schreiben.
			LoadW	r3,254			;Anzahl zu schreibender 254-Byte-
			ldx	#r2L			;Blocks berechnen.
			ldy	#r3L
			jsr	Ddiv
			MoveW	r8,r15			;Rest von "Anzahl/254" nach r15.
			LoadW	r3,254			;Anzahl Blöcke * 254.
			ldx	#r2L
			ldy	#r3L
			jsr	BMult
			MoveW	r2,r14

::102			LoadW	r6,fileTrScTab		;Speicher für Sektor-Nummern.
			jsr	BlkAlloc		;Sektoren belegen.
			txa
			beq	:104
::103			jmp	vCopyError

::104			jsr	PutDirHead		;BAM aktualisieren.
			txa
			bne	:103
			LoadW	r6,fileTrScTab		;Zeiger auf Sektor-Tabelle.
			LoadW	r7,Memory2		;Startadresse Zwischenspeicher.
			jsr	WriteFile		;Zwischenspeicher schreiben.
			txa
			bne	:103

			ldy	#$00			;Sektor-Anzahl für CBM-Datei erhöhen.
::105			lda	fileTrScTab,y
			beq	:106
			IncWord	GW2FileLen
			iny
			iny
			bne	:105
::106			lda	fileTrScTab-2,y
			sta	GWSekBuf +0
			lda	fileTrScTab-1,y
			sta	GWSekBuf +1

			lda	GW1stSek +0
			bne	:107
			lda	VLIR2_Set
			asl
			tax
			lda	fileTrScTab +0		;Ersten Sektor der Datei merken.
			sta	GW1stSek    +0
			sta	VLIR2Head   +0,x
			lda	fileTrScTab +1
			sta	GW1stSek    +1
			sta	VLIR2Head   +1,x
			jmp	:109

::107			MoveB	GWLastSek +0,r1L	;Letzten Sektor der Datei lesen.
			MoveB	GWLastSek +1,r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa
			beq	:108
			jmp	vCopyError

::108			lda	fileTrScTab +0		;Sektorverkettung zwischen dem
			sta	diskBlkBuf  +0		;letzten und den aktuellen Daten des
			lda	fileTrScTab +1		;Zwischenspeichers herstellen.
			sta	diskBlkBuf  +1
			jsr	PutBlock		;Sektor zurück auf Disk schreiben.

::109			lda	GW_EOF
			bne	:110
			clc				;Rest der MS-DOS-Daten im Speicher
			lda	#<Memory2		;nach vorne verschieben.
			sta	r1L
			adc	r14L
			sta	r0L
			lda	#>Memory2
			sta	r1H
			adc	r14H
			sta	r0H
			MoveW	r15,r2
			jsr	MoveData

			clc				;Zeiger auf Speicher hinter evtl.
			lda	#<Memory2		;Rest von MS-DOS-Daten setzen.
			adc	r15L
			sta	a6L
			lda	#>Memory2
			adc	r15H
			sta	a6H

::110			lda	GWSekBuf +0
			sta	GWLastSek +0
			lda	GWSekBuf +1
			sta	GWLastSek +1
			ClrB	GW_EOF
			jmp	SetSource

;*** GEOS-Datei: VLIR-Header/Info-Block kopieren.
:MakeDirEntry		jsr	SetTarget
			jsr	ChkToFrmtTxt		;GeoWrite-Text formatieren ?

			ldy	#$00
::101			lda	VLIR2Head,y		;VLIR-Header erzeugen.
			sta	Copy2Sek,y
			iny
			bne	:101
			ldx	#$01			;VLIR-Header schreiben.
			jsr	WrSekOnTrgt
			IncWord	GW2FileLen
			jsr	Sub1FileLen		;Dateilänge korrigieren.
			jsr	CopyInfo

			ldy	#$00
::102			lda	HdrB000,y		;Info-Block erzeugen.
			sta	Copy2Sek,y
			iny
			bne	:102
			ldx	#19			;Info-Block schreiben.
			jsr	WrSekOnTrgt
			IncWord	GW2FileLen
			jsr	Sub1FileLen		;Dateilänge korrigieren.
			jsr	CopyInfo

			jsr	PutDirHead		;BAM auf Diskette speichern.
			txa
			beq	SetEntry
			jmp	vCopyError

;*** Datei-Eintrag schreiben.
:SetEntry		ClrB	r10L			;Freien Directory-Eintrag suchen.
			jsr	GetFreeDirBlk
			txa
			beq	:102
::101			jmp	vCopyError		;Disketten-Fehler.

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

			lda	GW2FileLen +0		;Dateilänge in Datei-Eintrag schreiben.
			sta	diskBlkBuf+0,y
			lda	GW2FileLen +1
			sta	diskBlkBuf+1,y
			LoadW	r4,diskBlkBuf		;Verzeichnis-Sektor zurückschreiben.
			jsr	PutBlock
			txa
			beq	:108
::107			jmp	vCopyError		;Disketten-Fehler.

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
			LoadW	r4,Copy2Sek		;Daten auf Disk schreiben.
			jsr	PutBlock
			txa
			beq	:102
			jmp	vCopyError		;Disketten-Fehler.
::102			rts

;*** Freien Sektor auf Target suchen.
:GetSekOnTrgt		MoveB	NxFreeSek+0,r3L
			MoveB	NxFreeSek+1,r3H
			jsr	SetNextFree
			txa
			beq	:102
::101			jmp	vCopyError		;Disketten-Fehler.
::102			MoveB	r3L,NxFreeSek+0
			MoveB	r3H,NxFreeSek+1
			rts

;*** Variablen:
:StackPointer		b $00				;Stack-Zeiger.

:DirEntry		s $1e				;Directory-Eintrag.
:GWFileName		s $11				;Speicher für Datei-Name.
:VLIR1_Set		b $00				;VLIR-Zeiger Quell-Datei.
:VLIR2_Set		b $00				;VLIR-Zeiger Ziel-Datei.
:GW_EOF			b $00				;$FF = Dateiende erreicht.
:IgnoreBytes		b $00				;Anzahl Bytes ignorieren.
:CopyBytes		b $00				;Anzahl Bytes 1:1 übertragen.
:BytInGWBuf		w $0000				;Bytes in Buffer.
:GW1FileLen		w $0000				;Länge Quell-Datei.
:GW2FileLen		w $0000				;Länge Ziel-Datei.
:CurGWsek		b $00,$00			;Sektor Quell-Datei.
:GW1stSek		b $00,$00			;Erster Sektor CBM-Datei.
:GWLastSek		b $00,$00			;Letzter gespeicherter Sektor.
:GWSekBuf		b $00,$00			;Zwischenspeicher letzter gespeicherter Sektor.
:NxFreeSek		b $00,$00			;Suche nach freiem Sektor.
:FormatText		b $00				;Text beim Erststart formatieren.
:CR_Count		b $00				;Anzahl Zeilen pro Seite.
:GW_Command		b $00				;Aktuelles Steuerzeichen für ":CopyBytes"
:GW_ComPoi		b $00				;Zeiger für NEWCARDSET-Änderung.
:GW_InfoBlock		b $00,$00			;Infoblock Quell-Dokument.

:VLIR2Head		s $0100
:GW_Scraps		s 63 * 2

if Sprache = Deutsch
:V219a0			b PLAINTEXT
			b "Kopiere :",NULL
:V219a1			b "Blocks  : ",NULL
:V219a2			b "Dateien :",NULL
:V219a3			b "Seite   :     ",NULL
:V219a4			b "Scrap   :     ",NULL
endif

if Sprache = Englisch
:V219a0			b PLAINTEXT
			b "Copy    :",NULL
:V219a1			b "Blocks  : ",NULL
:V219a2			b "Files   :",NULL
:V219a3			b "Page    :     ",NULL
:V219a4			b "Scrap   :     ",NULL
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
:HdrB160		b "Konvertierte GeoWrite-Datei.",CR
			b "(w) GeoDOS 64...",NULL
:HdrEnd			s (HdrB000+256)-HdrEnd
endif

if Sprache = Englisch
:HdrB160		b "Converted GeoWrite- document.",CR
			b "(w) GeoDOS 64...",NULL
:HdrEnd			s (HdrB000+256)-HdrEnd
endif

;*** Startadresse Kopierspeicher.
:Memory1
:Memory2		= (Memory1 / 256 +1)*256
