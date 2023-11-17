; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** L211: Datei von MS-DOS nach CBM/GW kopieren
:ConvTabBase		= SCREEN_BASE
:File_Name		= SCREEN_BASE +256
:File_Datum		= File_Name   +256*16

:OptBase		= UsedGWFont

:Opt_Datum		= CopyOptions + 0
:Opt_OverWrite		= CopyOptions + 1

:DOS_CBMType		= OptDOStoCBM + 0
:DOS_LfCode		= OptDOStoCBM + 1
:DOS_FfCode		= OptDOStoGW  + 0
:DOS_GW_Ver		= OptDOStoGW  + 1
:DOS_GW_1Page		= OptDOStoGW  + 2
:DOS_GW_PLen		= OptDOStoGW  + 4
:DOS_GW_Frmt		= OptGW_Format+ 0

:CBM_DOSName		= OptCBMtoDOS + 0
:CBM_LfCode		= OptCBMtoDOS + 1
:CBM_ZielDir		= OptCBMtoDOS + 2
:CBM_ZielDirCl		= OptCBMtoDOS + 3
:CBM_FfCode		= OptGWtoDOS  + 0

:GW_LRand		= OptGW_Rand  + 0
:GW_RRand		= OptGW_Rand  + 2
:GW_TabBase		= OptGW_Tab   + 0
:GW_Absatz		= OptGW_Tab   +16
:GW_Format		= OptGW_Format+ 0
:GW_Font		= OptGW_Font  + 0

:EndBuffer		= $7ff0
:GWBufSize		= $1a00

;A0  = Boot-Sektor
;A1  = FAT
;A2  = Zeiger auf Datei-Namen.
;A3  = Zeiger auf Datei-Datum.
;A4L = Anzahl Sektoren / Cluster - Zähler.
;A5  = Bytes pro Sektor - Zähler.
;A6  = Zeiger auf Zwischenspeicher.
;A7  = Cluster-Nummer.
;A8  = Disk_Sek

;*** Datei von MS-DOS nach CBM/GW kopieren

:DoDOStoCBM		stx	DOSCopyMode		;Kopier-Modus.

;*** geoWrite-Copy initialisieren.
:InitGWCopy		txa
			beq	DoCopyBox

			lda	DOS_GW_1Page+0
			sta	HdrB137+0
			lda	DOS_GW_1Page+1
			sta	HdrB137+1
			lda	DOS_GW_PLen+0
			sta	HdrB144+0
			lda	DOS_GW_PLen+1
			sta	HdrB144+1

			lda	DOS_GW_Ver
			add	$30
			sta	HdrB090+2

;*** Ausgabe-Fenster.
:DoCopyBox		jsr	UseGDFont 		;Bildschirm Initialisieren.
			Display	ST_WR_FORE

			Pattern	0
			FillRec	180,199,0,319

			ldy	#$27
			lda	#$36
::1			sta	COLOR_MATRIX+23*40,y
			sta	COLOR_MATRIX+24*40,y
			dey
			bpl	:1

			PrintXY	  6,190,V211i0
			PrintXY	  6,198,V211i1
			PrintXY	219,190,V211i2

			lda	DOSCopyMode
			beq	:2
			PrintXY	219,198,V211i3		;Text "Seite:" ausgeben.

::2			StartMouse
			NoMseKey

			LoadW	a0,Boot_Sektor		;Vektoren setzen.
			LoadW	a1,FAT
			LoadW	a2,File_Name
			LoadW	a3,File_Datum
			MoveB	SpClu,a4L		;Anzahl Sektoren/Cluster.
			LoadW	a8,Disk_Sek

:CopyFiles		lda	pressFlag
			beq	:2
::1			jmp	L211ExitGD

::2			lda	AnzahlFiles
			beq	L211ExitGD

			jsr	PrintName		;Datei-Name ausgeben.
			jsr	StartCopy		;Einzel-Datei kopieren.

::3			AddVBW	16,a2			;Zeiger auf nächste Datei.
			AddVBW	9,a3
			dec	AnzahlFiles		;Weitere Files kopieren ?
			bne	CopyFiles		;Ja, weiter.

;*** Ende. Zurück zu geoDOS.
:L211ExitGD		jsr	ClrBitMap		;Bildschirm löschen.
			jsr	ClrBackCol
			jmp	InitScreen

;*** Wechsel auf Quell-Laufwerk.
:SetSource		lda	Source_Drv		;Quell-Laufwerk aktivieren.
			jsr	NewDrive
			txa
			bne	ExitDskErr
			rts

;*** Wechsel auf Ziel-Laufwerk.
:SetTarget		lda	Target_Drv		;Ziel-Laufwerk aktivieren.
			jsr	NewDrive
			jsr	OpenDisk		;Diskette öffnen.
			txa
			bne	ExitDskErr
			rts

;*** Disketten-Fehler!
:ExitDskErr		stx	:1 +1 			;Fehler-Nummer merken.
			jsr	ClrBitMap		;Bildschirm löschen.
			jsr	ClrBackCol
::1			ldx	#$ff 			;Fehler-Nummer einlesen.
			jmp	DiskError		;Disk-Fehler ausgeben.

;*** Name in Zwischenspeicher kopieren.
:CopyNamInBuf		ldy	#$0f
::1			lda	(a2L),y
			sta	V211e0,y		;Name der kopierten Datei.
			ldx	FirstFile
			bne	:2
			sta	V211e1,y		;Name Gesamt-Datei / kopierte Datei.
::2			dey
			bpl	:1
			rts

;*** Dateiname ausgeben.
:PrintName		Pattern	0			;Text-Fenster löschen.
			FillRec	180,199, 80,218
			FillRec	180,199,293,319

			jsr	CopyNamInBuf		;Name in Zwischenspeicher kopieren.
;			PrintXY	80,190,V211e0		;Einzel-Datei-Name ausgeben.
			PrintXY	80,190,V211e1		;Gesamt-Datei-Name ausgeben.

			LoadW	r11,293			;Anzahl Dateien ausgeben.
			LoadB	r1H,190
			ldx	AnzahlFiles
			dex
			stx	r0L
			ClrB	r0H
			lda	#%11000000
			jmp	PutDecimal

;*** Anzahl Bytes ausgeben.
:PrnCopyBytes		LoadW	r11,80
			LoadB	r1H,197
			lda	V211a0+2
			bpl	:1
			jsr	InitForBA
			lda	#$00
			tax
			jsr	Word_FAC
			jmp	:2

::1			jsr	InitForBA
			lda	#<V211d0
			ldy	#>V211d0
			jsr	MOVMA
			lda	V211a0+2
			ldx	#$00
			jsr	Word_FAC
			jsr	x_MULT
			jsr	MOVFA
			lda	V211a0+0
			ldx	V211a0+1
			jsr	Word_FAC
			jsr	ADDFAC
::2			jsr	x_FLPSTR
			jsr	DoneWithBA

			ldy	#$07			;Bytes ausgeben.
			jsr	Do_ZFAC
			lda	#" "
			jsr	SmallPutChar

			lda	DOSCopyMode
			beq	:3

			LoadW	r11,293			;geoWrite-Seite ausgeben.
			MoveB	V211b4,r0L
			ClrB	r0H
			lda	#%11000000
			jsr	PutDecimal

::3			rts

;*** Byte in Speicher übertragen.
:WriteGWByte		IncWord	V211a2
:WriteCBMByte		ldy	#$00			;Byte in Speicher schreiben.
			sta	(a6L),y
			IncWord	a6			;Zeiger auf Speicher korrigieren.
			rts

;*** Datei-Länge (DOS) um 1 verringern.
:Sub1DOSLen		sec
			lda	V211a0 +0
			sbc	#$01
			sta	V211a0 +0
			lda	V211a0 +1
			sbc	#$00
			sta	V211a0 +1
			lda	V211a0 +2
			sbc	#$00
			sta	V211a0 +2
			rts

;*** Einzel-Datei kopieren.
:StartCopy		jsr	SetSource

			lda	LinkFiles
			beq	:1
			lda	FirstFile
			bne	:3
			dec	FirstFile

::1			ldy	#$04			;Datei-Parameter löschen.
			lda	#$00
::2			sta	V211a0,y
			dey
			bpl	:2

			ldx	#$01
			sta	V211b0 +0		;Start-Sektor Datei.
			sta	V211b0 +1
			stx	V211b1 +0		;Start-Adr. für Suche nach freien
			sta	V211b1 +1		;Sektoren auf Disk. (Track/Sektor 1,0)
			sta	V211c0			;"Datei-Ende"-Flag löschen.
			sta	V211e2			;Keine Zusatzfiles.

			jsr	MakeNewGWFile		;geoWrite-Datei erzeugen.
			jsr	InitNewPage		;Neue Seite erzeugen.

::3			ldx	#$00
			ldy	#$04
			lda	(a3L),y			;Start-Cluster der
			sta	a7L			;DOS-Datei einlesen.
			iny
			lda	(a3L),y
			sta	a7H
			iny
			lda	(a3L),y			;Datei-Größe der
			sta	V211a0 +0		;DOS-Datei einlesen.
			iny
			lda	(a3L),y
			sta	V211a0 +1
			iny
			lda	(a3L),y
			sta	V211a0 +2
			jsr	Sub1DOSLen

			lda	a7L			;Ersten Sektor der DOS-Datei lesen.
			ldx	a7H
			jsr	RdCluSek

			lda	DOSCopyMode
			bne	:4
			jmp	NextCBMCopy
::4			jmp	NextGWCopy

;*** Ende geoWrite-Datei.
:EndOfGWFile		lda	PageFull		;Text formatieren ?
			beq	EndOfCBMFile		;Nein, weiter...

			jsr	SetTarget
			jsr	GetVLIRHead		;VLIR-Header lesen.
			lda	diskBlkBuf+2		;Ersten Sektor lesen.
			sta	r1L
			lda	diskBlkBuf+3
			sta	r1H
			jsr	GetBlock
			txa
			beq	:2
::1			jmp	ExitDskErr		;Disketten-Fehler.

::2			lda	OptGW_Format		;Flag für "Text formatieren" setzen.
			and	#%11101111
			sta	diskBlkBuf+25

			jsr	PutBlock		;Sektor zurück auf Diskette.
			txa
			bne	:1

;*** Datei-Ende.
:EndOfCBMFile		jsr	DoFileEntry		;Datei-Eintrag erzeugen.
			C_Send	V211f0			;"Initialisieren..."
			jmp	OpenDisk		;Neue Diskette anmelden.

;*** Trenn-Code einfügen.
:InsLinkCode		lda	LinkFiles
			cmp	#%00100000
			beq	:2
			cmp	#%01000000
			bne	:1			;Neue Seite einfügen.
			lda	#CR			;Leerzeile einfügen.
			jmp	WriteGWByte
::1			ClrB	V211h0
::2			rts

;*** Seite abschließen.
:EndPage		lda	#PAGE_BREAK		;Seitenvorschub in Text
			jsr	WriteGWByte		;einfügen.
			jsr	PrepEndFile		;Rest-Speicher schreiben.
			ClrB	V211c0			;"Datei-Ende"-Flag löschen..
			rts

;** Rest von Ziel-Datei schreiben.
:PrepEndFile		LoadB	V211c0,$ff		;"Datei-Ende"-Flag löschen.
			jmp	WriteBuffer		;Letztes Byte gelesen,Puffer schreiben.

;*** CBM-Datei kopieren.
:NextCBMCopy		ldy	#$00
			lda	(a9L),y			;Byte lesen.
			IncWord	a9			;Zeiger auf nächstes Byte.

			bit	DOS_LfCode		;LineFeed kopieren ?
			bpl	:1			;Ja, überspringen.
			cmp	#LF			;Nein, Zeichen = LineFeed ?
			beq	:2			;Ja, weiter mit nächstem Byte.
::1			tay				;Byte konvertieren.
			lda	ConvTabBase,y
			jsr	WriteCBMByte		;Byte in Speicher schreiben.

::2			jsr	Sub1DOSLen		;Datei-Länge -1.
			bcs	:3			;Ende erreicht ? Nein, weiter.
			jsr	PrepEndFile
			jmp	EndOfCBMFile		;Datei schließen.

::3			SubVW	1,a5			;Anzahl Bytes pro Sektor -1.
			bcs	:4			;Kompletter Sektor kopiert ?
			jsr	NxCluSek		;Ja, nächsten Sektor lesen.

::4			CmpWI	a6,EndBuffer		;Speicher voll ?
			bcc	:5			;Nein, weiter.
			jsr	WriteBuffer		;Ja, Speicher schreiben.
::5			jmp	NextCBMCopy		;Nächstes Zeichen kopieren.

;*** GW-Datei kopieren.
:NextGWCopy		ldy	#$00
			lda	(a9L),y			;Byte lesen.
			IncWord	a9			;Zeiger auf nächstes Byte.

			cmp	#NULL			;Zeichen = NULL-Byte ?
			beq	:2			;Ja, überlesen.
			cmp	#PAGE_BREAK		;Zeichen = Seitenvorschub ?
			bne	:1			;Nein, weiter.
			bit	DOS_FfCode		;Seitenvorschub ignorieren ?
			bpl	:2			;Ja, weiter mit nächstem Byte.
			ClrB	V211h0			;Seiten-Ende definieren.
			jmp	:2

::1			cmp	#LF			;Zeichen = LineFeed ?
			beq	:2			;Ja, weiter mit nächstem Byte.
			tay				;Byte konvertieren.
			lda	ConvTabBase,y
			jsr	WriteGWByte		;Byte in Speicher schreiben.

			bit	DOS_FfCode		;Seitenvorschub ignorieren ?
			bmi	:2			;Nein, weiter.
			cmp	#CR			;Zeichen = Zeilen-Ende ?
			bne	:2			;Nein, weiter.
			dec	V211h0			;Zähler für Anzahl Zeilen -1.

::2			jsr	Sub1DOSLen		;Datei-Länge -1.
			bcs	:5			;Ende erreicht ? Nein, weiter.

			lda	LinkFiles		;Dateien verbinden ?
			beq	:4			;Nein, Datei abschließen.
			ldx	AnzahlFiles
			dex	 			;Letzte Datei ?
			beq	:4			;Ja, Datei abschließen.

			jsr	InsLinkCode		;Zusammenfügen von Dateien.

			lda	V211h0			;Seiten-Ende erreicht ?
			beq	:3			;Ja, Seite speichern.
			rts				;Nein, nächste Datei.

::3			jmp	EndPage			;Seite speichern.

::4			jsr	PrepEndFile		;Speicher auf Diskette schreiben.
			jmp	EndOfGWFile		;Kopiervorgang abschließen.

::5			SubVW	1,a5			;Anzahl Bytes pro Sektor -1.
			bcs	:6			;Kompletter Sektor kopiert ?
			jsr	NxCluSek		;Ja, nächsten Sektor lesen.

::6			lda	V211h0			;Seite voll ?
			beq	:7			;Ja, Seite speichern.

			lda	V211a2+1
			cmp	#>GWBufSize		;geoWrite-Puffer für Text-Seite voll ?
			bne	:8			;Nein, weiter.
			LoadB	PageFull,$ff
::7			jsr	EndPage			;Seite speichern.
			jmp	NextGWCopy		;Weiter mit nächstem Byte.

::8			CmpWI	a6,EndBuffer		;Zwischenspeicher voll ?
			bcc	:9			;Nein, weiter.
			jsr	WriteBuffer		;Speicher auf Disk schreiben.
::9			jmp	NextGWCopy		;Weiter mit nächstem Byte.

;*** Buffer auf Disk (Target) schreiben.
:WriteBuffer		jsr	PrnCopyBytes		;Infos ausgeben.
			jsr	SetTarget

			sec				;Anzahl Bytes im Puffer
			lda	a6L			;berechnen.
			sbc	#<Memory
			sta	r2L
			lda	a6H
			sbc	#>Memory
			sta	r2H

			lda	V211c0			;Datei-Ende erreicht ?
			bne	:2			;Ja, alle Bytes schreiben.

			LoadW	r3,254			;Anzahl zu schreibender 254-Byte-
			ldx	#r2L			;Blocks berechnen.
			ldy	#r3L
			jsr	Ddiv
			MoveW	r8,r15			;Rest von "Anzahl/254" nach r15.
			LoadW	r3,254			;Anzahl Blöcke * 254.
			ldx	#r2L
			ldy	#r3L
			jsr	BMult

::2			LoadW	r6,fileTrScTab		;Speicher für Sektor-Nummern.
			jsr	BlkAlloc		;Sektoren belegen.
			txa
			beq	:4
::3			jmp	ExitDskErr

::4			jsr	PutDirHead		;BAM aktualisieren.
			txa
			bne	:3
			LoadW	r6,fileTrScTab		;Zeiger auf Sektor-Tabelle.
			LoadW	r7,Memory		;Startadresse Zwischenspeicher.
			jsr	WriteFile		;Zwischenspeicher schreiben.
			txa
			bne	:3
			MoveB	r1L,V211b1+0		;Adr. des letzten Sektors merken.
			MoveB	r1H,V211b1+1

			lda	V211b0
			bne	:5
			lda	fileTrScTab +0		;Ersten Sektor der Datei merken.
			sta	V211b0 +0
			lda	fileTrScTab +1
			sta	V211b0 +1
			jmp	:6
::5			MoveB	V211b2 +0,r1L		;Letzten Sektor der Datei lesen.
			MoveB	V211b2 +1,r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa
			bne	:3
			lda	fileTrScTab +0		;Sektorverkettung zwischen dem
			sta	diskBlkBuf  +0		;letzten und den aktuellen Daten des
			lda	fileTrScTab +1		;Zwischenspeichers herstellen.
			sta	diskBlkBuf  +1
			jsr	PutBlock		;Sektor zurück auf Disk schreiben.

::6			lda	V211c0
			bne	:7
			sec				;Rest der MS-DOS-Daten im Speicher
			lda	#<EndBuffer		;nach vorne verschieben.
			sbc	r15L
			sta	r0L
			lda	#>EndBuffer
			sbc	r15H
			sta	r0H
			LoadW	r1,Memory
			MoveW	r15,r2
			jsr	MoveData

			clc				;Zeiger auf Speicher hinter evtl.
			lda	#<Memory		;Rest von MS-DOS-Daten setzen.
			adc	r15L
			sta	a6L
			lda	#>Memory
			adc	r15H
			sta	a6H

::7			ldy	#$00			;Sektor-Anzahl für CBM-Datei erhöhen.
::8			lda	fileTrScTab,y
			beq	:9
			IncWord	V211a1
			iny
			iny
			bne	:8

::9			lda	V211b1 +0
			sta	V211b2 +0
			lda	V211b1 +1
			sta	V211b2 +1

			lda	V211b6
			beq	:10
			ClrB	V211b6
			jsr	WritePage

::10			jmp	SetSource

;*** Nächsten Sektor eines Clusters lesen.
:NxCluSek		dec	a4L			;Alle Sektoren eines
			beq	:2			;Clusters gelesen ?

			jsr	Inc_Sek			;Nächsten Sektor im
			jmp	ReadSektor		;Cluster lesen.

::1			jmp	ExitDskErr		;Disketten-Fehler.

::2			lda	a7L			;Nächsten Cluster
			ldx	a7H			;lesen.
			jsr	Get_Clu
			lda	r1L			;Neue Cluster-Nr.
			ldx	r1H			;merken.
			sta	a7L
			stx	a7H

;*** Cluster Einlesen.
:RdCluSek		ldy	FAT_Typ
			bne	:1

			cmp	#$f8			;FAT12. Dir-Ende ?
			bcc	:2			;Nein, weiter...
			cpx	#$0f
			bcc	:2
			jmp	CluErr

::1			cmp	#$f8			;FAT16. Dir-Ende ?
			bcc	:2			;Nein, weiter...
			cpx	#$ff
			beq	CluErr

::2			jsr	Clu_Sek			;Cluster berechnen.
			MoveB	SpClu,a4L		;Zähler setzen.
:ReadSektor		jsr	D_Read			;Ersten Sektor lesen.
			txa
			bne	ReadError
			jsr	PrnCopyBytes		;Kopieranzeige.
			LoadW	a9,Disk_Sek		;Zeiger auf Sektor.
			LoadW	a5,511 			;Anzahl Bytes / Cluster auf 512 -1.
			rts

:CluErr			ldx	#$45
:ReadError		jmp	ExitDskErr		;Disketten-Fehler.

;*** Neue geoWrite-Datei erzeugen.
:MakeNewGWFile		lda	DOSCopyMode
			bne	:2
			rts

::1			jmp	ExitDskErr

::2			jsr	SetTarget
			MoveB	V211b1+0,r3L		;Sektor für VLIR-Header belegen.
			MoveB	V211b1+1,r3H
			jsr	SetNextFree
			txa
			bne	:1
			jsr	PutDirHead
			txa
			bne	:1

			lda	r3L			;Sektor-Adresse für VLIR-Header
			sta	r1L			;merken.
			sta	V211b3+0
			lda	r3H
			sta	r1H
			sta	V211b3+1

			ldy	#$00			;Leeren VLIR-Header erzeugen.
::3			lda	#$00
			sta	diskBlkBuf+0,y
			lda	#$ff
			sta	diskBlkBuf+1,y
			iny
			iny
			bne	:3

			LoadW	r4,diskBlkBuf		;VLIR-Header schreiben.
			jsr	PutBlock
			txa
			beq	:4
			jmp	ExitDskErr		;Disketten-Fehler.

::4			lda	#$00
			sta	V211b4			;Zeiger auf Seite löschen.
			sta	PageFull		;Flag für "Text formatieren" löschen.
			IncWord	V211a1			;Länge CBM-Datei +1.

			jmp	SetSource		;Quell-Laufwerk aktivieren.

;*** VLIR-Header lesen.
:GetVLIRHead		MoveW	V211b3,r1
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa
			bne	:1
			rts

::1			jmp	ExitDskErr		;Disketten-Fehler.

;*** Seite aktualisieren.
:WritePage		jsr	GetVLIRHead

			lda	V211b4			;Seite in VLIR-Header eintragen.
			asl
			tay
			lda	V211b0+0
			sta	diskBlkBuf+0,y
			lda	V211b0+1
			sta	diskBlkBuf+1,y

			jsr	PutBlock		;VLIR-Header zurück auf Diskette.
			txa
			beq	InitNewPage
			jmp	ExitDskErr		;Disketten-Fehler.

;*** Neue Seite erzeugen.
:InitNewPage		LoadW	a6,Memory		;Zeiger auf Anfang des Speichers
							;zurücksetzen.
			lda	DOSCopyMode
			bne	:1
			rts

::1			lda	#$00
			sta	V211a2+0
			sta	V211a2+1
			sta	V211b0+0		;Start-Track/-Sektor für
			sta	V211b0+1		;geoWrite-Datensatz löschen.
			sta	V211b2+0		;Adresse des setzten Sektors des
			sta	V211b2+1		;aktuellen Datensatzes löschen.
			inc	V211b4			;Nr. des aktuellen Datensatzes +1.

			lda	V211b4			;Seite #62 erreicht ?
			cmp	#62			;(max. 61 Seiten je geoWrite-Datei!)
			bne	:6			;Nein, weiter.

			jsr	EndOfGWFile		;Datei-Eintrag erzeugen.

			ldx	V211e2			;Namen für neue Datei erzeugen ?
			bne	:4
::2			lda	V211e1,x
			beq	:3
			inx
			cpx	#$0e
			bne	:2
::3			lda	#"_"			;Namens-Zusatz "_x" an Datei-Name
			sta	V211e1,x		;anhängen.
			lda	#$40
			sta	V211e1,x		;Nein, weiter.
			inx
			stx	V211e2			;Kennung Datei-Name erhöhen.
::4			inc	V211e1,x
			lda	V211e1,x
			cmp	#$5b			;Max. Anzahl erreicht ?
			bne	:5			;Nein, weiter.
			pla				;Max. 26 Zusatzfiles erzeugt, kopieren
			pla				;beenden. Somit werden max.
			pla				;27 Dateien a 61 Seiten erzeugt!
			pla
			rts				;Nächste Datei kopieren.

::5			ClrW	V211a1			;Größe der geoWrite-Datei löschen.
			jsr	MakeNewGWFile		;Neue geoWrite-Datei anlegen.
			jsr	InitNewPage		;Erste Seite erzeugen.

::6			LoadB	V211b6,$ff		;Datensatz in VLIR-Header eintragen.

			ldy	#30			;"ESC_RULER" am Seiten-Anfang
::7			lda	GW_PageData,y		;eintragen.
			sta	(a6L),y
			dey
			bpl	:7
			AddVBW	31,a6
			LoadB	V211a2,31

			lda	LinesPerPage		;Anzahl Zeilen/Seite auf Standardwert.
			sta	V211h0
			rts

;*** Datei-Eintrag schreiben.
:DoFileEntry		jsr	SetTarget		;Ziel-Laufwerk aktivieren.

			LoadW	r0,V211e1		;Falls Datei bereits vorhanden,
			jsr	DeleteFile		;Datei löschen.
			txa
			beq	SetInfoBlock
			cpx	#$05
			beq	SetInfoBlock
			jmp	ExitDskErr

;*** geoWrite-Info-Block erzeugen.
:SetInfoBlock		ldx	DOSCopyMode
			beq	SetEntry

			MoveB	V211b1+0,r3L		;Freien Sektor für Info-Block suchen.
			MoveB	V211b1+1,r3H
			jsr	SetNextFree
			txa
			beq	:2
::1			jmp	ExitDskErr

::2			jsr	PutDirHead		;BAM zurückschreiben.
			txa
			bne	:1

			lda	r3L			;Sektor in Speicher einlesen.
			sta	r1L
			sta	V211b5+0
			lda	r3H
			sta	r1H
			sta	V211b5+1
			LoadW	r4,fileHeader
			jsr	GetBlock
			txa				;Fehler ?
			bne	:1			;Ja, Abbruch...

			ldy	#$00
::3			lda	V211g0,y
			sta	fileHeader,y
			iny
			bne	:3
			jsr	PutBlock		;Info-Block auf Diuskette schreiben.
			txa				;Fehler ?
			bne	:1			;Ja, Abbruch...

			IncWord	V211a1			;Anzahl Sektoren/Ziel-Datei +1.

;*** Datei-Eintrag schreiben.
:SetEntry		ClrB	r10L			;Freien Directory-Eintrag suchen.
			jsr	GetFreeDirBlk
			txa
			beq	:2
::1			jmp	ExitDskErr		;Disketten-Fehler.

::2			lda	DOS_CBMType		;CBM-Datei-Typ.
			ldx	DOSCopyMode
			beq	:3
			lda	#$80 ! USR
::3			sta	diskBlkBuf,y
			iny

			txa
			beq	:4
			lda	V211b3+0		;Start-Track/-Sektor VLIR-Header.
			ldx	V211b3+1
			jmp	:5

::4			lda	V211b0+0		;Start-Track/-Sektor CBM-Datei.
			ldx	V211b0+1

::5			sta	diskBlkBuf,y
			iny
			txa
			sta	diskBlkBuf,y
			iny

			ldx	#$00			;Datei-Name.
::6			lda	V211e1,x
			beq	:8
			sta	diskBlkBuf,y
			iny
			inx
			bne	:6
::7			lda	#$a0
			sta	diskBlkBuf,y
			iny
			inx
::8			cpx	#$10
			bne	:7

			lda	DOSCopyMode
			bne	:9
			lda	#$00			;CBM-Datei: Kein Info-Block.
			tax
			beq	:10
::9			lda	V211b5+0		;Adresse des Info-Blocks.
			ldx	V211b5+1

::10			sta	diskBlkBuf,y
			txa
			iny
			sta	diskBlkBuf,y
			iny

;*** Datei-Entrag erzeugen.
			lda	#$00			;CBM-Datei: SEQ-Datei.
			ldx	DOSCopyMode
			beq	:11
			lda	#VLIR			;geoWrite-Datei: VLIR-Datei.
::11			sta	diskBlkBuf,y
			iny

			txa				;CBM-Datei: Datei-Typ "BASIC".
			beq	:12
			lda	#APPL_DATA		;geoWrite-Datei: Datei-Typ "DOKUMENT".
::12			sta	diskBlkBuf,y
			iny

;*** Datum erzeugen und eintragen.
:InsertDate		tya
			pha
			jsr	SetDate			;Datum erzeugen.
			pla
			tay
			lda	r11L
			sta	diskBlkBuf,y
			iny
			lda	r10H
			sta	diskBlkBuf,y
			iny
			lda	r10L
			sta	diskBlkBuf,y
			iny
			lda	r11H
			sta	diskBlkBuf,y
			iny
			lda	r12L
			sta	diskBlkBuf,y
			iny
			lda	V211a1+0
			sta	diskBlkBuf,y
			iny
			lda	V211a1+1
			sta	diskBlkBuf,y
			LoadW	r4,diskBlkBuf
			jmp	PutBlock

;*** Datum erzeugen.
:SetDate		lda	Opt_Datum
			beq	:1

			MoveB	day,r10L		;GEOS-Uhrzeit.
			MoveB	month,r10H
			MoveB	year,r11L
			MoveB	hour,r11H
			MoveB	minutes,r12L
			rts

::1			ldy	#$03
			lda	(a3L),y
			sta	r15H
			dey
			lda	(a3L),y
			sta	r15L
			and	#%00011111
			sta	r10L			;Tag.
			RORZWordr15L,5
			lda	r15L
			and	#%00001111
			sta	r10H			;Monat.
			RORZWordr15L,4
			lda	r15L
			and	#%01111111
			clc
			adc	#80
			sta	r11L			;Jahr.

			ldy	#$00
			lda	(a3L),y
			sta	r15L
			iny
			lda	(a3L),y
			sta	r15H
			RORZWordr15L,5
			lda	r15L
			and	#%00111111
			sta	r12L			;Minute.
			RORZWordr15L,6
			lda	r15L
			and	#%00011111
			sta	r11H			;Stunde.
			rts

;*** Variablen
:DOSCopyMode		b $00				;Kopier-Modus.
:PageFull		b $00				;$FF = GW-Seite zu lang, neu formatieren.
:FirstFile		b $00				;$00 = Erste Datei erzeugen.

:V211a0			s $03				;DOS-Datei-Länge.
:V211a1			w $0000				;CBM-Datei-Länge.
:V211a2			w $0000				;Bytes in GW-Seite.

:V211b0			b $00,$00			;Start-Track/-Sektor für CBM-Datei.
:V211b1			b $00,$00			;Suche nach freiem Sektor für CBM-Datei.
:V211b2			b $00,$00			;Letzter gespeicherter Sektor für CBM-Datei.
:V211b3			b $00,$00			;Track/-Sektor für VLIR-Header.
:V211b4			b $00				;Zeiger auf Seite.
:V211b5			b $00,$00			;Track/Sektor für Info-Block.
:V211b6			b $00				;$ff = Seite in VLIR-Header eintragen.

:V211c0			b $00				;$ff = Datei-Ende erreicht.

:V211d0			b $91,$00,$00,$00,$00

:V211e0			s $11				;DOS-Datei-Name (Bildschirm).
:V211e1			s $11				;DOS-Datei-Name (Ziel-Datei).
:V211e2			b $00				;=$00, Kein Zusatz-Name, >$00, Pos. für Zusatzname.

:V211f0			w $0003
			b "I0:"

;*** Info-Block für geoWrite-Textdatei.
:V211g0			b $00,$ff
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
:HdrB097		b "geoDOS 64"			;Autor.
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
:HdrB160		b "Konvertierte MS-DOS-Datei. "
			b "(w) geoDOS 64 by One Vision.",NULL
			s 40

:V211h0			b $00				;Anzahl Zeilen/Seite.

:V211i0			b PLAINTEXT
			b "Kopiere :",NULL
:V211i1			b "Bytes   :",NULL
:V211i2			b "Dateien :",NULL
:V211i3			b "Seite   :",NULL

:V211z0
:Memory			= (V211z0 / 256 +1)*256
