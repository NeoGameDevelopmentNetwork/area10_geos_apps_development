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

			n	"mod.#215.obj"
			o	ModStart

			jmp	DoCBMtoDOSF

;*** Quell- und Ziel-Laufwerk setzen.
			t   "-SetSourceCBM"
			t   "-SetTargetDOS"

;*** L215: Datei von CBM nach MS-DOS kopieren (FAST)
:ConvTabBase		= SCREEN_BASE
:File_Name		= SCREEN_BASE +256
:File_Datum		= File_Name   +256*16

:EndBuffer		= Boot_Sektor -512

;A0  = Boot-Sektor
;A1  = FAT
;A2  = Zeiger auf Datei-Namen.
;A3  = Zeiger auf Datei-Datum.
;A8  = Disk_Sek

:DoCBMtoDOSF		tsx
			stx	StackPointer

;*** Ausgabe-Fenster.
:DoCopyBox		jsr	UseGDFont 		;Bildschirm Initialisieren.
			Display	ST_WR_FORE

			FillPRec$00,$b8,$c7,$0000,$013f
			jsr	i_ColorBox
			b	$00,$00,$28,$17,$00
			jsr	i_ColorBox
			b	$00,$17,$28,$02,$36

			PrintXY	  6,190,V215e0
			PrintXY	  6,198,V215e1
			PrintXY	219,190,V215e2

::102			StartMouse			;Maus-Modus aktivieren.
			NoMseKey

			LoadW	a0,Boot_Sektor		;Vektoren setzen.
			LoadW	a1,FAT
			LoadW	a2,File_Name
			LoadW	a3,File_Datum
			lda	#<Disk_Sek
			sta	a8L
			sta	V215a4+0
			lda	#>Disk_Sek
			sta	a8H
			sta	V215a4+1

			jsr	Max_Free
			jsr	ResetDir

:CopyFiles		lda	pressFlag		;Abbruch durch Maus-Klick ?
			bne	L215ExitGD		;Ja, ende...

			lda	AnzahlFiles		;Alle Dateien kopiert ?
			beq	L215ExitGD		;Ja, ende...

			jsr	PrintName		;Datei-Name ausgeben.
			jsr	StartCopy		;Einzel-Datei kopieren.

::103			AddVBW	16,a2			;Zeiger auf nächste Datei.
			AddVBW	 8,a3

			dec	AnzahlFiles		;Alle Dateien kopiert ?
			bne	CopyFiles		;Nein, weiter...

;*** Ende. Zurück zu GeoDOS.
:L215ExitGD		jsr	SetGDScrnCol
			jsr	ClrScreen		;Bildschirm löschen.

			jsr	DoInfoBox		;FAT auf Disk schreiben.
			PrintStrgV215d0

			jsr	SetTarget		;Ziel-Laufwerk aktivieren.
			jsr	Save_FAT
			jsr	ClrBox
			jmp	InitScreen		;Zurück zu GeoDOS.

;*** Disketten-Fehler!
:ExitDskErr		stx	:101 +1			;Fehler-Nummer merken.

			jsr	SetGDScrnCol
			jsr	ClrScreen		;Bildschirm löschen.
			ldx	StackPointer
			txs

			lda	Target_Drv		;Ziel-Laufwerk aktivieren.
			jsr	NewDrive
			jsr	Save_FAT		;FAT auf Disk schreiben.
			jsr	MakeDirEntry		;Directory Eintrag erzeugen.

::101			ldx	#$ff			;Fehler-Nummer einlesen.
			jmp	DiskError		;Disk-Fehler ausgeben.

;*** Dateiname ausgeben.
:PrintName		Pattern	0			;Text-Fenster löschen.
			FillRec	180,199, 80,218
			FillRec	180,199,293,319

			ldy	#$0f			;Datei-Name erzeugen.
::101			lda	(a2L),y
			sta	FileName,y
			dey
			bpl	:101
			PrintXY	80,190,FileName		;Datei-Name ausgeben.

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

			lda	File1Len +0
			ldx	File1Len +1
			cmp	#$00
			bne	:101
			cpx	#$00
			beq	:103

::101			sub	1
			bcs	:102
			dex
::102			sta	File1Len +0
			stx	File1Len +1

::103			sta	r0L
			stx	r0H
			ClrB	r1L
			ldy	#$09
			jmp	DoZahl24Bit

;*** Zeichen in DOS-Puffer schreiben.
:WriteDOSByt		ldy	#$00
			sta	(a8L),y			;CBM-Byte in DOS-Puffer schreiben.
			IncWord	a8			;Zeiger auf DOS-Puffer erhöhen.

			inc	File2Len+0		;DOS-Datei-Länge +1.
			bne	:101
			inc	File2Len+1
			bne	:101
			inc	File2Len+2

::101			IncWord	BytInDOSsek		;Zähler für Byte in DOS-Puffer.
			CmpWI	BytInDOSsek,512		;DOS-Puffer voll ?
			bne	:102			;Nein, weiter..

			jsr	WriteSektor		;DOS-Puffer schreiben.

::102			rts

;*** Einzel-Datei kopieren.
:StartCopy		jsr	FreeDirEntry

			jsr	SetSource		;Quell-Laufwerk aktivieren.

			lda	#$00
			sta	File2Len+0
			sta	File2Len+1
			sta	File2Len+2
			sta	BytInDOSsek+0
			sta	BytInDOSsek+1
			sta	NextCBMsek+0
			sta	NextCBMsek+1
			sta	EndOfFile		;Dateiende-Flag löschen.
			sta	V215b0+0
			sta	V215b0+1

			LoadB	V215b2,1		;Anzahl Sektoren pro Cluster.
			LoadW	a8,Disk_Sek		;Zeiger auf Puffer DOS-Sektor.

			ldy	#$07			;Adr. des ersten Sektors
			lda	(a3L),y			;der CBM-Datei ermitteln.
			sta	NextCBMsek+1
			dey
			lda	(a3L),y
			sta	NextCBMsek+0
			dey
::101			lda	(a3L),y			;Datum, Uhrzeit & Datei-Größe
			sta	TimeDOS,y		;in Zwischenspeicher.
			dey
			bpl	:101

			LoadW	a6,Memory2		;Zeiger auf Anfang Zwischenspeicher.

;*** Ziel-Datei einlesen.
:ReadSeqFile		jsr	SetSource		;Quell-Laufwerk aktivieren.
:ReadNxSek		MoveW	NextCBMsek,r1		;Zeiger auf nächsten Sektor CBM-Datei.
			LoadW	r4,diskBlkBuf		;Zeiger auf Zwischenspeicher.
			jsr	InitForIO
			jsr	ReadBlock		;Sektor lesen.
			jsr	DoneWithIO
			txa
			beq	:101
			jmp	ExitDskErr		;Disketten-Fehler.

::101			jsr	CopyInfo		;Info ausgeben.

			ldy	#$00
			ldx	#$02			;Adresse des nächsten Sektors merken.
::102			lda	diskBlkBuf,x
			sta	(a6L),y
			iny

			lda	diskBlkBuf +0
			bne	:104
			cpx	diskBlkBuf +1
			beq	:103
			inx
			jmp	:102

::103			jsr	AddYToMem
			jsr	WriteAllData
			jmp	MakeDirEntry

::104			cpx	#$ff
			beq	:105
			inx
			jmp	:102

::105			jsr	AddYToMem

			MoveW	diskBlkBuf,NextCBMsek

			lda	a6H
			cmp	#>EndBuffer
			bne	ReadNxSek

			jsr	WriteBuffer
			jmp	ReadSeqFile

;*** Zeiger auf Datenspeicher korrigieren.
:AddYToMem		tya
			clc
			adc	a6L
			sta	a6L
			bcc	:101
			inc	a6H
::101			rts

;*** Alle Daten auf Diskette schreiben.
:WriteAllData		lda	#$ff
			sta	EndOfFile

;*** Buffer speichern.
:WriteBuffer		SubVW	Memory2,a6
			CmpW0	a6
			bne	:101
			rts

::101			jsr	SetTarget

			MoveW	a6,r10
			LoadW	r11,Memory2

::102			CmpWI	r10,512 +1
			bcc	:106

			SubVW	512,r10

			ldy	#$00
::103			lda	(r11L),y
			sta	Disk1_Sek,y
			iny
			bne	:103
			inc	r11H
::104			lda	(r11L),y
			sta	Disk2_Sek,y
			iny
			bne	:104
			inc	r11H

			jsr	WriteSektor
			clc
			lda	File2Len +1
			adc	#>512
			sta	File2Len +1
			bcc	:105
			inc	File2Len +2
::105			jmp	:102

::106			lda	EndOfFile
			bne	:107
			MoveW	r11,r0
			LoadW	r1,Memory2
			clc
			lda	r10L
			sta	r2L
			adc	#<Memory2
			sta	a6L
			lda	r10H
			sta	r2H
			adc	#>Memory2
			sta	a6H
			jmp	MoveData

::107			MoveW	r11,r0
			LoadW	r1,Disk_Sek
			clc
			lda	r10L
			sta	r2L
			adc	File2Len +0
			sta	File2Len +0
			lda	r10H
			sta	r2H
			adc	File2Len +1
			sta	File2Len +1
			bcc	:108
			inc	File2Len +2
::108			jsr	MoveData

;*** Disk-Sektor auf Disk schreiben.
:WriteSektor		dec	V215b2			;Zeiger auf nächsten Sektor des
			beq	:101			;aktuellen Clusters setzen.
			jsr	Inc_Sek
			jmp	NewInit

::101			MoveB	SpClu,V215b2		;Neuen DOS-Cluster suchen.
			jsr	GetFreeClu
			beq	:102
			ldx	#$49			;Disk Full!
			jmp	ExitDskErr

::102			lda	V215b0+0
			bne	:103
			lda	V215b0+1
			bne	:103

			LoadW	r4,$fff8		;Ersten Cluster merken.
			lda	r2L			;(Für Directory-Eintrag).
			sta	V215b0+0
			sta	V215b1+0
			ldx	r2H
			stx	V215b0+1
			stx	V215b1+1
			jsr	Set_Clu
			lda	r2L
			ldx	r2H
			jsr	Clu_Sek
			jmp	NewInit

::103			lda	V215b1+0		;Nächsten Cluster setzen.
			ldx	V215b1+1
			ldy	r2L
			sty	r4L
			sty	V215b1+0
			ldy	r2H
			sty	r4H
			sty	V215b1+1
			jsr	Set_Clu
			LoadW	r4,$fff8
			lda	V215b1+0
			ldx	V215b1+1
			jsr	Set_Clu
			lda	r2L
			ldx	r2H
			jsr	Clu_Sek

;*** Zeiger reinitialisieren.
:NewInit		LoadW	a8,Disk_Sek		;Zeiger auf DOS-Puffer.
			jsr	D_Write
			txa
			beq	:101
			ldx	#$44
			jmp	ExitDskErr

::101			ClrW	BytInDOSsek
			LoadB	BAM_Modify,$ff		;DOS-BAM modifiziert.
			rts

;*** Suche nach freiem Eintrag im Verzeichnis.
:FreeDirEntry		jsr	SetTarget		;Ziel-Laufwerk aktivieren.

			lda	V215a3+0		;Suche nach freiem Directory-Eintrag
			ldx	V215a3+1		;ab DOS-Sektor...
			ldy	V215a3+2
			sta	Seite
			stx	Spur
			sty	Sektor
			LoadW	a8,Disk_Sek		;DOS-Directory-Sektor lesen.
			jsr	D_Read
			txa
			beq	:101
			jmp	ExitDskErr

::101			MoveW	V215a4,a8		;Zeiger innerhalb DOS-Sektor setzen.
::102			jsr	TestEntryFree		;Eintrag frei ?
			bne	:103			;Nein, weitersuchen...
			lda	Seite			;Position merken.
			ldx	Spur
			ldy	Sektor
			sta	V215a3+0
			stx	V215a3+1
			sty	V215a3+2
			MoveW	a8,V215a4
			LoadW	a8,Disk_Sek
			rts

::103			AddVBW	32,a8			;Zeiger auf nächsten Eintrag.
			dec	V215a5
			bne	:102

			jsr	GetNxDirSek		;Nächster Directory-Sektor lesen.
			bne	:104			;Fehler: Kein Sektor mehr vorhanden.
			LoadB	V215a5,16
			jmp	:102

::104			ldx	#$47
			jmp	ExitDskErr

;*** Prüfen ob Eintrag frei.
:TestEntryFree		ldy	#$00
			lda	(a8L),y
			bne	:101
			rts
::101			cmp	#$e5
			bne	:102
			lda	#$00			;Eintrag frei.
			rts
::102			lda	#$ff			;Eintrag belegt.
			rts

;*** Verzeichnis initialisieren.
:ResetDir		lda	DOS_TargetDir		;Typ Zielverzeichnis.
			bne	:101			; -> Unterverzeichnis.

;*** Zeiger auf Hauptverzeichnis.
			jsr	DefMdr
			MoveW	Anz_Files,V215a0
			jmp	:102

;*** Zeiger auf Unterverzeichnis.
::101			lda	DOS_TargetClu+0
			ldx	DOS_TargetClu+1
			sta	V215a1+0
			stx	V215a1+1
			jsr	Clu_Sek
			MoveB	SpClu ,V215a2

;*** Zeiger definieren.
::102			MoveB	Seite ,V215a3+0
			MoveB	Spur  ,V215a3+1
			MoveB	Sektor,V215a3+2
			LoadW	V215a4,Disk_Sek
			LoadB	V215a5,16
			rts

;*** Zeiger auf nächsten Directory-Sektor.
:GetNxDirSek		lda	DOS_TargetDir		;Typ Ziel-Verzeichnis.
			bne	:101			; -> Unterverzeichnis.

			SubVW	16,V215a0		;Zeiger auf nächsten Sektor des
			CmpW0	V215a0			;Hauptverzeichnisses.
			beq	:103			;Fehler, -> Directory voll.
			jmp	:102

::101			dec	V215a2			;Zeiger auf nächsten Sektor innerhalb
			beq	:106			;des Unterverzeichnis-Clusters.

::102			jsr	Inc_Sek			;Nächsten Directory-Sektor lesen.
			LoadW	a8,Disk_Sek
			jsr	D_Read
			txa
			bne	:105
			rts

::103			ldx	#$47			;Kein Platz im Hauptverzeichnis.
			b $2c
::104			ldx	#$48			;Kein Platz im Unterverzeichnis.
::105			jmp	ExitDskErr

::106			MoveB	SpClu,V215a2		;Anzahl Sektoren pro Cluster.

			lda	V215a1+0		;Zeiger auf nächsten Cluster lesen.
			ldx	V215a1+1
			jsr	Get_Clu
			lda	r1L
			ldx	r1H

			cmp	#$f8			;FAT12. Dir-Ende ?
			bcc	:108			;Nein, weiter...
			cpx	#$0f
			bcc	:108
			jmp	:104

::108			sta	V215a1+0		;Cluster merken.
			stx	V215a1+1
::109			jsr	Clu_Sek			;Cluster umrechnen.
			LoadW	a8,Disk_Sek
			jsr	D_Read			;Ersten Sektor lesen.
			txa
			beq	:110
			jmp	ExitDskErr

::110			lda	#$00			;Kein Fehler...
			rts

;*** Freien Cluster suchen.
:GetFreeClu		MoveW	FreeCluster,r2		;Zeiger auf ersten Cluster.
			jmp	:102

::101			lda	r2L			;Cluster-Link-Adresse einlesen.
			ldx	r2H
			jsr	Get_Clu
			CmpW0	r1			;Ist Cluster frei ?
			beq	:103			;Ja...

::102			IncWord	r2			;Nein, Zeiger auf nächsten Cluster.
			SubVW	1,FreeClu
			CmpW0	FreeClu			;Alle Cluster belegt ?
			bne	:101			;Nein, weiter...

			lda	#$ff			;Disk voll...
			rts

::103			MoveW	r2,FreeCluster		;Cluster-Adresse merken.
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
::101			jsr	D_Write			;Einzelnen Sektor eines Clusters
			txa				;löschen.
			beq	:102
			jmp	ExitDskErr

::102			jsr	Inc_Sek
			dec	r14L
			bne	:101
			rts

;*** Directory-Eintrag erzeugen.
:MakeDirEntry		jsr	SetTarget		;Ziel-Laufwerk aktivieren.

			lda	V215a3+0		;Directory-Sektor für Directory-
			ldx	V215a3+1		;Eintrag lesen.
			ldy	V215a3+2
			sta	Seite
			stx	Spur
			sty	Sektor
			LoadW	a8,Disk_Sek
			jsr	D_Read
			MoveW	V215a4,a8

			ldy	#$00
			ldx	#$00
::101			lda	FileName,x		;Datei-Name kopieren.
			sta	(a8L),y
			inx
			iny
			cpy	#$08
			bne	:101
			inx
::102			lda	FileName,x
			sta	(a8L),y
			inx
			iny
			cpy	#$0b
			bne	:102

			lda	#%00100000		;Datei-Attribute definieren.
			sta	(a8L),y

			ldy	#$16
			ldx	#$00
::103			lda	TimeDOS,x		;Datei-Datum & -Uhrzeit
			sta	(a8L),y			;definieren.
			iny
			inx
			cpx	#$04
			bne	:103

			lda	V215b0+0		;Start-Cluster definieren.
			sta	(a8L),y
			iny
			lda	V215b0+1
			sta	(a8L),y
			iny

			ldx	#$00
::104			lda	File2Len,x		;Datei-Größe definieren.
			sta	(a8L),y
			iny
			inx
			cpx	#$03
			bne	:104
			lda	#$00
			sta	(a8L),y

			LoadW	a8,Disk_Sek		;Directory-Sektor schreiben.
			jmp	D_Write

;*** Variablen:
:StackPointer		b $00

:FileName		s $11				;Speicher für DOS-Datei-Name.
:FreeCluster		w $0000				;Suche nach freiem Cluster ab Nr. x.
:BytInDOSsek		w $0000				;Anzahl Bytes im DOS-Sektor.
:NextCBMsek		b $00,$00			;Nächster CBM-Sektor.
:EndOfFile		b $00				;$FF = Dateiende erreicht.
:TimeDOS		w $0000				;Stunde, Minute   (DOS-Format).
:DateDOS		w $0000				;Jahr, Monat, Tag (DOS-Format).
:File1Len		w $0000				;Datei-Größe (in Blocks).
:File2Len		s $03				;Länge Ziel-Datei.

:V215a0			w $0000				;Anzahl Einträge im Hauptverzeichnis.
:V215a1			w $0000				;Cluster-Nummer SubDir.
:V215a2			b $00				;Zähler Sektor in Cluster.
:V215a3			s $03				;Sektor-Adresse.
:V215a4			w $0000				;Zeiger innerhalb des Sektors.
:V215a5			b $00				;Zähler innerhalb des Sektors.

:V215b0			w $0000				;Erste Cluster-Nummer.
:V215b1			w $0000				;Cluster-Nummer.
:V215b2			b $00				;Zähler Sektor in Cluster.

if Sprache = Deutsch
:V215d0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Diskettenverzeichnis"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "wird aktualisiert..."
			b NULL

:V215e0			b PLAINTEXT
			b "Kopiere :",NULL
:V215e1			b "Blocks  :",NULL
:V215e2			b "Dateien :",NULL
endif

if Sprache = Englisch
:V215d0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Update directory"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "on targetdisk..."
			b NULL

:V215e0			b PLAINTEXT
			b "Copy    :",NULL
:V215e1			b "Blocks  :",NULL
:V215e2			b "Files   :",NULL
endif

;*** Startadresse Kopierspeicher.
:Memory1
:Memory2		= (Memory1 / 256 +1)*256

:DskErrRout		= ExitDskErr
