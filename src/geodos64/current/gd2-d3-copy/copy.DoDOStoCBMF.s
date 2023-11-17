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

			n	"mod.#212.obj"
			o	ModStart

			jmp	DoDOStoCBMF

;*** Quell- und Ziel-Laufwerk setzen.
			t   "-SetSourceDOS"
			t   "-SetTargetCBM"

;*** L212: Datei von MS-DOS nach CBM kopieren
:ConvTabBase		= SCREEN_BASE
:File_Name		= SCREEN_BASE +256
:File_Datum		= File_Name   +256*16

:EndBuffer		= Boot_Sektor -512

;A0  = Boot-Sektor
;A1  = FAT
;A2  = Zeiger auf Datei-Namen.
;A3  = Zeiger auf Datei-Datum.
;A4L = Anzahl Sektoren / Cluster - Zähler.
;A5  = Bytes pro Sektor - Zähler.
;A6  = Zeiger auf Zwischenspeicher.
;A7  = Cluster-Nummer.
;A8  = Speicher.

:DoDOStoCBMF		tsx
			stx	StackPointer

;*** Ausgabe-Fenster.
:DoCopyBox		jsr	UseGDFont 		;Bildschirm Initialisieren.
			Display	ST_WR_FORE

			FillPRec$00,$b8,$c7,$0000,$013f
			jsr	i_ColorBox
			b	$00,$00,$28,$17,$00
			jsr	i_ColorBox
			b	$00,$17,$28,$02,$36

			PrintXY	  6,190,V212a0
			PrintXY	  6,198,V212a1
			PrintXY	219,190,V212a2

			StartMouse
			NoMseKey

			LoadW	a0,Boot_Sektor		;Vektoren setzen.
			LoadW	a1,FAT
			LoadW	a2,File_Name
			LoadW	a3,File_Datum

:CopyFiles		lda	pressFlag
			bne	L212ExitGD

			lda	AnzahlFiles
			beq	L212ExitGD

			jsr	StartCopy		;Einzel-Datei kopieren.

			AddVBW	16,a2			;Zeiger auf nächste Datei.
			AddVBW	 9,a3

			dec	AnzahlFiles		;Weitere Files kopieren ?
			bne	CopyFiles		;Ja, weiter.

;*** Ende. Zurück zu GeoDOS.
:L212ExitGD		jsr	SetTarget
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

;*** Anzahl Bytes ausgeben.
:CopyInfo		LoadW	r11,80
			LoadB	r1H,197
			lda	File1Len+0
			sta	r0L
			lda	File1Len+1
			sta	r0H
			lda	File1Len+2
			sta	r1L
			ldy	#$09
			jmp	DoZahl24Bit

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

:ReadSektor		jsr	D_Read			;Ersten Sektor lesen.
			txa
			bne	ReadError
			jmp	CopyInfo		;Kopieranzeige.

:CluErr			ldx	#$45
:ReadError		jmp	ExitDskErr		;Disketten-Fehler.

;*** Einzel-Datei kopieren.
:StartCopy		jsr	SetSource		;Quell-Laufwerk aktivieren.

			Pattern	0			;Text-Fenster löschen.
			FillRec	180,199, 80,218
			FillRec	180,199,293,319

			ldy	#$0f
::101			lda	(a2L),y			;Name Ziel-Datei in Zwischenspeicher.
			sta	FileName,y
			dey
			bpl	:101
			PrintXY	80,190,FileName		;Datei-Name ausgeben.

			LoadW	r11,293			;Anzahl Dateien ausgeben.
			ldx	AnzahlFiles
			dex
			stx	r0L
			ClrB	r0H
			lda	#%11000000
			jsr	PutDecimal

			lda	#$00
			sta	File2Len+0
			sta	File2Len+1
			sta	File1stSek+0
			sta	File1stSek+1
			sta	EndOfFile

			ldx	#$00
			ldy	#$04
			lda	(a3L),y			;Start-Cluster der
			sta	a7L			;DOS-Datei einlesen.
			iny
			lda	(a3L),y
			sta	a7H
			iny
			lda	(a3L),y			;Datei-Größe der
			sta	File1Len +0		;DOS-Datei einlesen.
			iny
			lda	(a3L),y
			sta	File1Len +1
			iny
			lda	(a3L),y
			sta	File1Len +2

			LoadW	a8,Memory2		;Zeiger auf Anfang des Speichers
							;zurücksetzen.
			MoveB	SpClu,a4L

;*** CBM-Datei kopieren.
:DoCopyFile		lda	a7L			;Ersten Sektor der DOS-Datei lesen.
			ldx	a7H
			jsr	RdCluSek
			jmp	:102

::101			jsr	NxCluSek

::102			lda	File1Len +2
			bne	:103
			CmpWI	File1Len +0,512 +1
			bcs	:103

			AddW	File1Len,a8

			lda	#$00
			sta	File1Len +0
			sta	File1Len +1
			sta	File1Len +2

			jsr	WriteAllData		;Letztes Byte gelesen,Puffer schreiben.
			jmp	MakeDirEntry		;Datei-Eintrag erzeugen.

::103			inc	a8H
			inc	a8H

			sec
			lda	File1Len +0
			sbc	#<512
			sta	File1Len +0
			lda	File1Len +1
			sbc	#>512
			sta	File1Len +1
			lda	File1Len +2
			sbc	#$00
			sta	File1Len +2

			lda	a8H
			cmp	#>EndBuffer
			bcc	:101			;Nein, weiter.

			jsr	WriteBuffer		;Ja, Speicher schreiben.

			jmp	:101			;Nächstes Zeichen kopieren.

;*** Alle Bytes auf Diskette schreiben.
:WriteAllData		lda	#$ff
			sta	EndOfFile

;*** Buffer auf Disk (Target) schreiben.
:WriteBuffer		jsr	CopyInfo		;Infos ausgeben.
			SubVW	Memory2,a8
			CmpW0	a8
			bne	:101
			rts

::101			jsr	SetTarget

			MoveW	a8,r2

			lda	EndOfFile		;Datei-Ende erreicht ?
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
::103			jmp	ExitDskErr

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
			IncWord	File2Len
			iny
			iny
			bne	:105

::106			lda	fileTrScTab-2,y
			sta	FileSekBuf +0
			lda	fileTrScTab-1,y
			sta	FileSekBuf +1

			lda	File1stSek
			bne	:107
			lda	fileTrScTab+0		;Ersten Sektor der Datei merken.
			sta	File1stSek +0
			lda	fileTrScTab+1
			sta	File1stSek +1
			jmp	:108

::107			MoveB	FileLastSek+0,r1L	;Letzten Sektor der Datei lesen.
			MoveB	FileLastSek+1,r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa
			bne	:103
			lda	fileTrScTab+0		;Sektorverkettung zwischen dem
			sta	diskBlkBuf +0		;letzten und den aktuellen Daten des
			lda	fileTrScTab+1		;Zwischenspeichers herstellen.
			sta	diskBlkBuf +1
			jsr	PutBlock		;Sektor zurück auf Disk schreiben.

::108			lda	EndOfFile
			bne	:109
			clc				;Rest der Daten im Speicher
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
			lda	#<Memory2		;Rest von Daten setzen.
			adc	r15L
			sta	a8L
			lda	#>Memory2
			adc	r15H
			sta	a8H

::109			lda	FileSekBuf +0
			sta	FileLastSek+0
			lda	FileSekBuf +1
			sta	FileLastSek+1

			jmp	SetSource

;*** Datei-Eintrag schreiben.
:MakeDirEntry		jsr	SetTarget		;Ziel-Laufwerk aktivieren.

			ClrB	r10L			;Freien Directory-Eintrag suchen.
			jsr	GetFreeDirBlk
			txa
			beq	:102
::101			jmp	ExitDskErr		;Disketten-Fehler.

::102			lda	CBMFileType		;CBM-Datei-Typ.
			sta	diskBlkBuf,y
			iny
			lda	File1stSek+0		;Start-Track/-Sektor CBM-Datei.
			sta	diskBlkBuf,y
			iny
			lda	File1stSek+1
			sta	diskBlkBuf,y
			iny

			ldx	#$00			;Datei-Name.
::103			lda	FileName,x
			beq	:105
			sta	diskBlkBuf,y
			iny
			inx
			bne	:103
::104			lda	#$a0
			sta	diskBlkBuf,y
			iny
			inx
::105			cpx	#$10
			bne	:104

			lda	#$00			;CBM-Datei: Kein Info-Block.
			ldx	#$04
::106			sta	diskBlkBuf,y
			iny
			dex
			bne	:106

			sty	:107 +1
			jsr	SetDate			;Datum erzeugen.
::107			ldy	#$ff
			ldx	#$00
::108			lda	r10L,x
			sta	diskBlkBuf,y
			iny
			inx
			cpx	#$05
			bne	:108

			lda	File2Len+0
			sta	diskBlkBuf,y
			iny
			lda	File2Len+1
			sta	diskBlkBuf,y

			LoadW	r4,diskBlkBuf
			jsr	PutBlock
			txa
			beq	:110
::109			jmp	ExitDskErr		;Disketten-Fehler.

::110			jsr	PutDirHead		;BAM aktualisieren.
			txa				;Diskettenfehler ?
			bne	:109			; => Ja, Abbruch...
			rts

;*** Datum erzeugen.
:SetDate		lda	SetDateTime
			beq	:102
			ldx	#$04
::101			lda	year,x
			sta	r10L,x
			dex
			bpl	:101
			rts

::102			ldy	#$03
			jsr	:103
			and	#%00011111
			sta	r11L			;Tag.
			RORZWordr15L,5
			lda	r15L
			and	#%00001111
			sta	r10H			;Monat.
			RORZWordr15L,4
			lda	r15L
			and	#%01111111
			add	80
			sta	r10L			;Jahr.

			ldy	#$01
			jsr	:103
			RORZWordr15L,5
			lda	r15L
			and	#%00111111
			sta	r12L			;Minute.
			RORZWordr15L,6
			lda	r15L
			and	#%00011111
			sta	r11H			;Stunde.
			rts

::103			lda	(a3L),y
			sta	r15H
			dey
			lda	(a3L),y
			sta	r15L
			rts

;*** Variablen
:StackPointer		b $00

:FileName		s $11				;DOS-Datei-Name.
:File1Len		s $03				;DOS-Datei-Länge.
:File2Len		w $0000				;CBM-Datei-Länge.
:File1stSek		b $00,$00			;Start-Track/-Sektor für CBM-Datei.
:FileLastSek		b $00,$00			;Letzter gespeicherter Sektor für CBM-Datei.
:FileSekBuf		b $00,$00			;Zwischenspeicher für letzten gespeicherten Sektor.
:EndOfFile		b $00				;$ff = Datei-Ende erreicht.

if Sprache = Deutsch
:V212a0			b PLAINTEXT
			b "Kopiere :",NULL
:V212a1			b "Bytes   :",NULL
:V212a2			b "Dateien :",NULL
endif

if Sprache = Englisch
:V212a0			b PLAINTEXT
			b "Copy    :",NULL
:V212a1			b "Bytes   :",NULL
:V212a2			b "Files   :",NULL
endif

;*** Startadresse Kopierspeicher.
:Memory1
:Memory2		= (Memory1 / 256 +1)*256

:DskErrRout		= ExitDskErr
