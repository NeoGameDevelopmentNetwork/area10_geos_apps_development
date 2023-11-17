; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** L221: Datei von CBM nach MS-DOS kopieren
:ConvTabBase		= SCREEN_BASE
:File_Name		= SCREEN_BASE +256
:File_Datum		= File_Name   +256*16

:EndBuffer		= $7f00

:CBM_Datum		= CopyOptions +0
:CBM_OverWrite		= CopyOptions +1
:CBM_DOSName		= OptCBMtoDOS +0
:CBM_LfCode		= OptCBMtoDOS +1
:CBM_ZielDir		= OptCBMtoDOS +2
:CBM_ZielDirCl		= OptCBMtoDOS +3
:CBM_FFCode		= OptGWtoDOS  +0

;A0  = Boot-Sektor
;A1  = FAT
;A2  = Zeiger auf Datei-Namen.
;A3  = Zeiger auf Datei-Datum.
;A8  = Disk_Sek

:DoCBMtoDOS		stx	CBMCopyMode

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

			PrintXY	  6,190,V221g0
			PrintXY	  6,198,V221g1
			PrintXY	219,190,V221g2

			lda	CBMCopyMode
			beq	:2
			PrintXY	219,198,V221g3		;Text "Seite:" ausgeben.

::2			StartMouse			;Maus-Modus aktivieren.
			NoMseKey

			LoadW	a0,Boot_Sektor		;Vektoren setzen.
			LoadW	a1,FAT
			LoadW	a2,File_Name
			LoadW	a3,File_Datum

			jsr	InitForBA		;Max. Anzahl Cluster berechnen.
			jsr	Max_Free
			jsr	DoneWithBA

			jsr	InitDir

:CopyFiles		lda	pressFlag		;Abbruch durch Maus-Klick ?
			bne	L221ExitGD		;Ja, ende...

			lda	AnzahlFiles		;Alle Dateien kopiert ?
			beq	L221ExitGD		;Ja, ende...

			jsr	PrintName		;Datei-Name ausgeben.

			jsr	StartCopy		;Einzel-Datei kopieren.

::3			AddVBW	16,a2			;Zeiger auf nächste Datei.
			AddVBW	8,a3

			dec	AnzahlFiles		;Alle Dateien kopiert ?
			bne	CopyFiles		;Nein, weiter...

;*** Ende. Zurück zu geoDOS.
:L221ExitGD		jsr	ClrBitMap		;Bildschirm löschen.
			jsr	ClrBackCol

			jsr	DoInfoBox		;FAT auf Disk schreiben.
			PrintStrgV221f0
			jsr	Save_FAT
			jsr	ClrBox

			jmp	InitScreen		;Zurück zu geoDOS.

;*** Disketten-Fehler!
:ExitDskErr		txa				;Fehler-Nummer merken.
			pha
			lda	Target_Drv		;Ziel-Laufwerk aktivieren.
			jsr	NewDrive
			jsr	Save_FAT		;FAT auf Disk schreiben.
			jsr	SetEntry		;Directory Eintrag erzeugen.
			jsr	ClrBitMap		;Bildschirm löschen.
			jsr	ClrBackCol
			pla				;Fehler-Nummer einlesen.
			tax
			jmp	DiskError		;Disk-Fehler ausgeben.

;*** Dateiname ausgeben.
:PrintName		Pattern	0			;Text-Fenster löschen.
			FillRec	180,199, 80,218
			FillRec	180,199,293,319

			ldy	#$0f			;Datei-Name erzeugen.
::1			lda	(a2L),y
			sta	V221a0,y
			dey
			bpl	:1

			PrintXY	80,190,V221a0		;Datei-Name ausgeben.

			LoadW	r11,293			;Anzahl Dateien ausgeben.
			LoadB	r1H,190
			ldx	AnzahlFiles
			dex
			stx	r0L
			ClrB	r0H
			lda	#%11000000
			jmp	PutDecimal

;*** CopyInfo ausgeben.
:CopyInfo		LoadW	r11,80
			LoadB	r1H,198
			CmpW0	V221c3			;Alle Blocks kopiert ?
			bne	:1			;Nein, weiter.
			jsr	InitForBA		;Text für Datei-Länge = 0 erzeugen.
			lda	#$00
			tax
			jmp	:2

::1			SubVW	1,V221c3		;Anzahl Blocks -1.
			jsr	InitForBA		;Restblocks berechnen.
			lda	V221c3+0
			ldx	V221c3+1
::2			jsr	Word_FAC
			jsr	x_FLPSTR
			jsr	DoneWithBA

			ldy	#$07			;Blocks ausgeben.
			jsr	Do_ZFAC
			lda	#" "
			jsr	SmallPutChar

			lda	CBMCopyMode
			beq	:3
			LoadW	r11,293			;geoWrite-Seite ausgeben.
			MoveB	V221d1,r0L
			ClrB	r0H
			lda	#%11000000
			jsr	PutDecimal
::3			rts

;*** Standard-Copy initialisieren.
:InitCopy		ldy	#$07			;Adr. des ersten Sektors
			lda	(a3L),y			;der CBM-Datei ermitteln.
			sta	V221d4+1
			dey
			lda	(a3L),y
			sta	V221d4+0
			dey
::1			lda	(a3L),y			;Datum, Uhrzeit & Datei-Größe
			sta	V221c1,y		;in Zwischenspeicher.
			dey
			bpl	:1

;*** geoWrite-Copy initialisieren.
:InitGWCopy		lda	CBMCopyMode
			bne	:1
			rts

::1			ClrB	V221d1			;Zeiger auf Seite #1.
			MoveW	V221d4,r1		;VLIR-Header einlesen.
			LoadW	r4,V221d3
			jsr	GetBlock
			txa
			beq	:3
::2			jmp	ExitDskErr		;Disketten-Fehler.

::3			SubVW	2,V221c3		;Datei-Länge -2 (Header + Info-Block).

;*** Zeiger auf geoWrite-Seite.
:PosGWPage		inc	V221d1			;Zeiger auf nächste geoWrite-Seite.
			lda	V221d1
			cmp	#61			;Datei-Ende erreicht ?
			beq	:1			;Ja, weiter.
			asl				;Zeiger auf neue Seite berechnen.
			tax
			lda	V221d3+1,x
			sta	V221d4+1
			lda	V221d3+0,x
			sta	V221d4+0
			tax
			bne	:2
::1			LoadB	V221d2,$ff		;Datei-Ende erreicht.
::2			rts

;*** Zeichen in DOS-Puffer schreiben.
:WriteDOSByt		ldy	#$00
			sta	(a8L),y			;CBM-Byte in DOS-Puffer schreiben.
			IncWord	a8			;Zeiger auf DOS-Puffer erhöhen.

			inc	V221c0+0		;DOS-Datei-Länge +1.
			bne	:1
			inc	V221c0+1
			bne	:1
			inc	V221c0+2

::1			IncWord	V221d0			;Zähler für Byte in DOS-Puffer.
			CmpWI	V221d0,512		;DOS-Puffer voll ?
			bne	:2			;Nein, weiter..
			jsr	WriteSektor		;DOS-Puffer schreiben.
::2			rts

;*** Einzel-Datei kopieren.
:StartCopy		jsr	FreeDirEntry

			lda	Source_Drv		;Quell-Laufwerk aktivieren.
			jsr	NewDrive
			jsr	OpenDisk

			lda	#$00
			sta	V221c0+0		;Datei-Länge Ziel-Datei löschen.
			sta	V221c0+1
			sta	V221c0+2
			sta	V221d0+0		;Zeiger innerhalb DOS-Sektor.
			sta	V221d0+1
			sta	V221e0+0		;Nummer des ersten Clusters löschen.
			sta	V221e0+1
			sta	V221d2			;"Datei-Ende"-Flag löschen.
			LoadB	V221e2,1		;Anzahl Sektoren pro Cluster.
			LoadW	a8,Disk_Sek		;Zeiger auf Puffer DOS-Sektor.

;*** Daten der CBM-Datei einlesen.
:ReadData		jsr	InitCopy		;Initialisieren.

:ReadSeqFile		lda	Source_Drv
			jsr	NewDrive		;Quell-Laufwerk aktivieren.
			txa
			beq	:1
			jmp	ExitDskErr		;Disketten-Fehler.

::1			LoadW	V221d6,Memory		;Zeiger auf Anfang Zwischenspeicher.

:ReadNxSek		jsr	CopyInfo		;Info ausgeben.
			MoveW	V221d4,r1		;Zeiger auf nächsten Sektor CBM-Datei.
			MoveW	V221d6,r4		;Zeiger auf Zwischenspeicher.
			jsr	GetBlock		;Sektor lesen.
			txa
			beq	:1
			jmp	ExitDskErr		;Disketten-Fehler.

::1			ldy	#$00			;Adresse des nächsten Sektors merken.
			lda	(r4L),y
			sta	V221d4+0
			tax
			iny
			lda	(r4L),y
			sta	V221d4+1
			cpx	#$00			;Letzter Sektor der Datei ?
			beq	:2			;Ja, weiter.
			lda	#$ff			;Nein, 254 Bytes kopieren.
::2			sta	:4 +1			;Anzahl Bytes in Sektor.
::3			iny				;xx Datenbytes um 2 Byte verschieben.
			lda	(r4L),y			;(Link-Adresse überschreiben!).
			dey
			dey
			sta	(r4L),y
			iny
			iny
			IncWord	V221d5			;Anzahl Bytes in Zwischenspeicher +1.
::4			cpy	#$00
			bne	:3

			dey				;Zeiger auf Zwischenspeicher
			tya				;korrigieren.
			clc
			adc	r4L
			sta	V221d6+0
			lda	#$00
			adc	r4H
			sta	V221d6+1

			CmpWI	r4,EndBuffer		;Zwischenspeicher voll ?
			bcs	:5			;Ja, schreiben.
			txa				;Ende erreicht ?
			beq	:5			;Ja, schreiben.
			jmp	ReadNxSek		;Nächsten CBM-Sektor einlesen.

::5			jsr	Convert			;Puffer konvertieren & schreiben.

			lda	V221d4+0		;Datei-Ende erreicht ?
			beq	:6			;Ja, Ende.
			jmp	ReadSeqFile		;Nein, weiterlesen.

::6			lda	CBMCopyMode
			beq	:7
			jsr	PosGWPage		;Zeiger auf nächste geoWrite-Seite.
			lda	V221d2			;Datei-Ende erreicht ?
			bne	:7			;Ja, Ende.
			jmp	ReadSeqFile		;Nein, weiterlesen.

::7			CmpW0	V221d0			;Noch Daten im Puffer ?
			beq	:8			;Nein, weiter.
			jsr	WriteSektor		;Ja, auf Diskette schreiben.

::8			jmp	SetEntry		;Directory-Eintrag erzeugen.

;*** Buffer konvertieren.
:Convert		LoadW	a4,Memory		;Zeiger auf Anfang Zwischenspeicher.

::1			CmpW	V221d6,a4		;Alle Daten kopiert ?
			bne	:2			;Nein, weiter.
			rts				;Ja, Ende.

::2			ldy	#$00			;Zeichen aus Zwischenspeicher lesen.
			lda	(a4L),y

			ldx	CBMCopyMode		;geoWrite-Modus ?
			beq	:7			;Nein, weiter.

			cmp	#ESC_RULER		;Steuercode ? Wenn ja, überlesen.
			bne	:3
			lda	#27
			bne	:6

::3			cmp	#NEWCARDSET
			bne	:4
			lda	#4
			bne	:6

::4			cmp	#ESC_GRAPHICS
			bne	:5
			lda	#5
			bne	:6

::5			cmp	#PAGE_BREAK
			bne	:7
			ldx	CBM_FFCode
			beq	:7
			lda	#CR			;Seitenende durch Zeilenende ersetzen.
			bne	:7
::6			clc
			adc	a4L
			sta	a4L
			lda	#$00
			adc	a4H
			sta	a4H
			jmp	:1

::7			tay				;Zeichen übersetzen.
			lda	ConvTabBase,y

			ldx	CBM_LfCode		;LineFeed einfügen ?
			beq	:8			;Nein, überspringen.
			cmp	#CR
			bne	:8
			jsr	WriteDOSByt		;Byte in DOS-Puffer schreiben.
			lda	#LF

::8			jsr	WriteDOSByt		;Byte in DOS-Puffer schreiben.

			IncWord	a4			;Zeiger auf nächstes Byte in Puffer.
			jmp	:1

;*** Disk-Sektor auf Disk schreiben.
:WriteSektor		lda	Target_Drv		;Ziel-Laufwerk aktivieren.
			jsr	NewDrive

			dec	V221e2			;Zeiger auf nächsten Sektor des
			beq	:0			;aktuellen Clusters setzen.
			jsr	Inc_Sek
			jmp	NewInit

::0			MoveB	SpClu,V221e2		;Neuen DOS-Cluster suchen.
			jsr	GetFreeClu
			beq	:1
			ldx	#$49			;Disk Full!
			jmp	ExitDskErr

::1			lda	V221e0+0
			bne	:2
			lda	V221e0+1
			bne	:2

			LoadW	r4,$fff8		;Ersten Cluster merken.
			lda	r2L			;(Für Directory-Eintrag).
			sta	V221e0+0
			sta	V221e1+0
			ldx	r2H
			stx	V221e0+1
			stx	V221e1+1
			jsr	Set_Clu
			lda	r2L
			ldx	r2H
			jsr	Clu_Sek
			jmp	NewInit

::2			lda	V221e1+0		;Nächsten Cluster setzen.
			ldx	V221e1+1
			ldy	r2L
			sty	r4L
			sty	V221e1+0
			ldy	r2H
			sty	r4H
			sty	V221e1+1
			jsr	Set_Clu
			LoadW	r4,$fff8
			lda	V221e1+0
			ldx	V221e1+1
			jsr	Set_Clu
			lda	r2L
			ldx	r2H
			jsr	Clu_Sek

;*** Zeiger reinitialisieren.
:NewInit		LoadW	a8,Disk_Sek		;Zeiger auf DOS-Puffer.
			jsr	D_Write
			txa
			beq	:1
			lda	#$44
			jmp	ExitDskErr

::1			ClrW	V221d0

			lda	Source_Drv		;Quell-Laufwerk aktivieren.
			jsr	NewDrive

			LoadB	BAM_Modify,$ff		;DOS-BAM modifiziert.
			rts

;*** Suche nach freiem Eintrag im Verzeichnis.
:FreeDirEntry		lda	Target_Drv		;Ziel-Laufwerk aktivieren.
			jsr	NewDrive

			lda	V221b3+0		;Suche nach freiem Directory-Eintrag
			ldx	V221b3+1		;ab DOS-Sektor...
			ldy	V221b3+2
			sta	Seite
			stx	Spur
			sty	Sektor
			LoadW	a8,Disk_Sek		;DOS-Directory-Sektor lesen.
			jsr	D_Read
			txa
			beq	:1
			jmp	ExitDskErr

::1			MoveW	V221b4,a8		;Zeiger innerhalb DOS-Sektor setzen.
::2			jsr	TestEntryFree		;Eintrag frei ?
			bne	:3			;Nein, weitersuchen...
			lda	Seite			;Position merken.
			ldx	Spur
			ldy	Sektor
			sta	V221b3+0
			stx	V221b3+1
			sty	V221b3+2
			MoveW	a8,V221b4
			rts

::3			AddVBW	32,a8			;Zeiger auf nächsten Eintrag.
			dec	V221b5
			bne	:2

			jsr	GetNxDirSek		;Nächster Directory-Sektor lesen.
			bne	:4			;Fehler: Kein Sektor mehr vorhanden.
			LoadB	V221b5,16
			jmp	:2

::4			ldx	#$47
			jmp	ExitDskErr

;*** Prüfen ob Eintrag frei.
:TestEntryFree		ldy	#$00
			lda	(a8L),y
			bne	:1
			rts
::1			cmp	#$e5
			bne	:2
			lda	#$00			;Eintrag frei.
			rts
::2			lda	#$ff			;Eintrag belegt.
			rts

;*** Directory-Eintrag erzeugen.
:SetEntry		lda	Target_Drv		;Ziel-Laufwerk aktivieren.
			jsr	NewDrive

			lda	V221b3+0		;Directory-Sektor für Directory-
			ldx	V221b3+1		;Eintrag lesen.
			ldy	V221b3+2
			sta	Seite
			stx	Spur
			sty	Sektor
			LoadW	a8,Disk_Sek
			jsr	D_Read
			MoveW	V221b4,a8

			ldy	#$00
			ldx	#$00
::1			lda	V221a0,x		;Datei-Name kopieren.
			sta	(a8L),y
			inx
			iny
			cpy	#$08
			bne	:1
			inx
::2			lda	V221a0,x
			sta	(a8L),y
			inx
			iny
			cpy	#$0b
			bne	:2

			lda	#%00100000		;Datei-Attribute definieren.
			sta	(a8L),y

			ldy	#$16
			ldx	#$00
::3			lda	V221c1,x		;Datei-Datum & -Uhrzeit
			sta	(a8L),y			;definieren.
			iny
			inx
			cpx	#$04
			bne	:3

			lda	V221e0+0		;Start-Cluster definieren.
			sta	(a8L),y
			iny
			lda	V221e0+1
			sta	(a8L),y
			iny

			ldx	#$00
::4			lda	V221c0,x		;Datei-Größe definieren.
			sta	(a8L),y
			iny
			inx
			cpx	#$03
			bne	:4
			lda	#$00
			sta	(a8L),y

			LoadW	a8,Disk_Sek		;Directory-Sektor schreiben.
			jmp	D_Write

;*** Verzeichnis initialisieren.
:InitDir		lda	CBM_ZielDir		;Typ Zielverzeichnis.
			bne	:1			; -> Unterverzeichnis.

;*** Zeiger auf Hauptverzeichnis.
			jsr	DefMdr
			MoveW	Anz_Files,V221b0
			jmp	:2

;*** Zeiger auf Unterverzeichnis.
::1			lda	CBM_ZielDirCl+0
			ldx	CBM_ZielDirCl+1
			sta	V221b1+0
			stx	V221b1+1
			jsr	Clu_Sek
			MoveB	SpClu ,V221b2

;*** Zeiger definieren.
::2			MoveB	Seite ,V221b3+0
			MoveB	Spur  ,V221b3+1
			MoveB	Sektor,V221b3+2
			LoadW	V221b4,Disk_Sek
			LoadB	V221b5,16
			rts

;*** Zeiger auf nächsten Directory-Sektor.
:GetNxDirSek		lda	CBM_ZielDir		;Typ Ziel-Verzeichnis.
			bne	:1			; -> Unterverzeichnis.

			SubVW	16,V221b0		;Zeiger auf nächsten Sektor des
			CmpW0	V221b0			;Hauptverzeichnisses.
			beq	:3			;Fehler, -> Directory voll.
			jmp	:2

::1			dec	V221b2			;Zeiger auf nächsten Sektor innerhalb
			beq	:6			;des Unterverzeichnis-Clusters.

::2			jsr	Inc_Sek			;Nächsten Directory-Sektor lesen.
			LoadW	a8,Disk_Sek
			jsr	D_Read
			txa
			bne	:5
			rts

::3			ldx	#$47			;Kein Platz im Hauptverzeichnis.
			b $2c
::4			ldx	#$48			;Kein Platz im Unterverzeichnis.
::5			jmp	ExitDskErr

::6			MoveB	SpClu,V221b2		;Anzahl Sektoren pro Cluster.

			lda	V221b1+0		;Zeiger auf nächsten Cluster lesen.
			ldx	V221b1+1
			jsr	Get_Clu
			lda	r1L
			ldx	r1H

			ldy	FAT_Typ
			bne	:7

			cmp	#$f8			;FAT12. Dir-Ende ?
			bcc	:8			;Nein, weiter...
			cpx	#$0f
			bcc	:8
			jmp	:4

::7			cmp	#$f8			;FAT16. Dir-Ende ?
			bcc	:8			;Nein, weiter...
			cpx	#$ff
			bne	:8
			jmp	:4			;Ja, Ende...

::8			sta	V221b1+0		;Cluster merken.
			stx	V221b1+1
::9			jsr	Clu_Sek			;Cluster umrechnen.
			LoadW	a8,Disk_Sek
			jsr	D_Read			;Ersten Sektor lesen.
			txa
			beq	:10
			jmp	ExitDskErr

::10			lda	#$00			;Kein Fehler...
			rts

;*** Freien Cluster suchen.
:GetFreeClu		MoveW	V221a1,r2		;Zeiger auf ersten Cluster.
			jmp	:2

::1			lda	r2L			;Cluster-Link-Adresse einlesen.
			ldx	r2H
			jsr	Get_Clu
			CmpW0	r1			;Ist Cluster frei ?
			beq	:3			;Ja...

::2			IncWord	r2			;Nein, Zeiger auf nächsten Cluster.
			SubVW	1,Free_Clu
			CmpW0	Free_Clu		;Alle Cluster belegt ?
			bne	:1			;Nein, weiter...

			lda	#$ff			;Disk voll...
			rts

::3			MoveW	r2,V221a1		;Cluster-Adresse merken.
			lda	#$00
			rts

;*** Cluster-Verkettung.
;a/x Letzer Cluster der Datei.
;r2  Neue Cluster-Nummer.
:ConnectClu		sta	r15L			;Letzter Cluster der Datei.
			stx	r15H

			lda	r2L			;Cluster-Nummer merken.
			pha
			sta	r4L
			lda	r2H
			pha
			sta	r4H
			lda	r15L			;Zeiger auf neuen Cluster korrigieren.
			ldx	r15H
			jsr	Set_Clu

			LoadW	r4,$fff8		;Letzten Cluster kennzeichnen.
			pla
			tax
			pla
			sta	r15L
			stx	r15H
			jsr	Set_Clu

			lda	r15L			;Cluster-Inhalt löschen.
			ldx	r15H
			jsr	Clu_Sek

			LoadW	r0,512
			LoadW	r1,Disk_Sek
			jsr	ClearRam

			MoveB	SpClu,r14L
::1			jsr	D_Write			;Einzelnen Sektor eines Clusters
			txa				;löschen.
			beq	:2
			jmp	ExitDskErr

::2			jsr	Inc_Sek
			dec	r14L
			bne	:1
			rts

;*** Variablen:
:CBMCopyMode		b $00				;$FF = geoWrite nach DOS.

:V221a0			s $11				;Speicher für DOS-Datei-Name.
:V221a1			w $0000				;Suche nach freiem Cluster ab Nr. x.

:V221b0			w $0000				;Anzahl Einträge im Hauptverzeichnis.
:V221b1			w $0000				;Cluster-Nummer SubDir.
:V221b2			b $00				;Zähler Sektor in Cluster.
:V221b3			s $03				;Sektor-Adresse.
:V221b4			w $0000				;Zeiger innerhalb des Sektors.
:V221b5			b $00				;Zähler innerhalb des Sektors.

:V221c0			s $03				;Länge Ziel-Datei.
:V221c1			w $0000				;Stunde, Minute   (DOS-Format).
:V221c2			w $0000				;Jahr, Monat, Tag (DOS-Format).
:V221c3			w $0000				;Datei-Größe (in Blocks).

:V221d0			w $0000				;Anzahl Bytes im DOS-Sektor.
:V221d1			b $00				;Zeiger auf geoWrite-Seite.
:V221d2			b $00				;$FF = Datei-Ende erreicht.
:V221d3			s $0100				;Link-Sektor.
:V221d4			b $00,$00			;Nächster CBM-Sektor.
:V221d5			w $0000				;Anzahl Bytes im Puffer.
:V221d6			w $0000				;Zeiger auf Byte in Puffer.

:V221e0			w $0000				;Erste Cluster-Nummer.
:V221e1			w $0000				;Cluster-Nummer.
:V221e2			b $00				;Zähler Sektor in Cluster.
:V221e3			s $03				;Sektor-Adresse.
:V221e4			w $0000				;Zeiger innerhalb des Sektors.
:V221e5			b $00				;Zähler innerhalb des Sektors.

:V221f0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Disketten-Verzeichnis"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "wird aktualisiert..."
			b NULL

:V221g0			b PLAINTEXT
			b "Kopiere :",NULL
:V221g1			b "Blocks  :",NULL
:V221g2			b "Dateien :",NULL
:V221g3			b "Seite   :",NULL

:V221z0
:Memory			=(V221z0 / 256 +1) *256
