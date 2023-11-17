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

			n	"mod.#216.obj"
			o	ModStart

			jmp	DoCBMtoCBM

;*** Quell- und Ziel-Laufwerk setzen.
			t   "-SetDriveCBM"

;*** L216: Datei von Text nach Text kopieren
:ConvTabBase		= SCREEN_BASE
:File_Name		= SCREEN_BASE +256
:File_Datum		= File_Name   +256*16
:EndBuffer		= $7000

;A2  = Zeiger auf Datei-Namen.
;A3  = Zeiger auf Datei-Datum.

:DoCBMtoCBM		tsx
			stx	StackPointer

;*** Ausgabe-Fenster.
:DoCopyBox		jsr	UseGDFont 		;Bildschirm Initialisieren.
			Display	ST_WR_FORE

			FillPRec$00,$b8,$c7,$0000,$013f
			jsr	i_ColorBox
			b	$00,$00,$28,$17,$00
			jsr	i_ColorBox
			b	$00,$17,$28,$02,$36

			PrintXY	  6,190,V216a0
			PrintXY	  6,198,V216a1
			PrintXY	219,190,V216a2

			StartMouse			;Maus-Modus aktivieren.
			NoMseKey

			LoadW	a2,File_Name
			LoadW	a3,File_Datum

:CopyFiles		lda	pressFlag		;Abbruch durch Maus-Klick ?
			bne	L216ExitGD		;Ja, Ende...

			lda	AnzahlFiles		;Alle Dateien kopiert ?
			beq	L216ExitGD		;Ja, Ende...

			jsr	PrintName		;Datei-Name ausgeben.
			jsr	StartCopy		;Einzel-Datei kopieren.

			AddVBW	16,a2			;Zeiger auf nächste Datei.
			AddVBW	10,a3

			dec	AnzahlFiles		;Alle Dateien kopiert ?
			bne	CopyFiles		;Nein, weiter...

;*** Ende. Zurück zu GeoDOS.
:L216ExitGD		jsr	SetTarget
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

			ldy	#$00
::101			lda	(a2L),y			;Dateiname in Zwischenspeicher
			sta	FileName,y		;kopieren.
			bne	:102
			lda	#$a0
::102			sta	DirEntry  +3,y
			iny
			cpy	#$10
			bne	:101

			PrintXY	80,190,FileName		;Datei-Name ausgeben.

			LoadW	r11,293			;Anzahl Dateien ausgeben.
			ldx	AnzahlFiles
			dex
			stx	r0L
			ClrB	r0H
			lda	#%11000000
			jmp	PutDecimal

;*** Dateilänge -1
:Sub1FileLen		CmpW0	File1Len
			beq	:101
			SubVW	1,File1Len
::101			rts

;*** Dateilänge ausgeben.
:CopyInfo		LoadW	r11,80
			LoadB	r1H,198
			MoveW	File1Len,r0
			ClrB	r1L
			ldy	#$09
			jmp	DoZahl24Bit

;*** Zeichen in Copy-Puffer schreiben.
:WriteCBMbyte		ldy	#$00
			sta	(a6L),y			;CBM-Byte in DOS-Puffer schreiben.
			IncWord	a6			;Zeiger auf DOS-Puffer erhöhen.
			rts

;*** Einzel-Datei kopieren.
:StartCopy		jsr	SetSource		;Quell-Laufwerk aktivieren.

::101			lda	#$00
			sta	EndOfFile		;Dateiende-Flag löschen.
			sta	File2Len  +0
			sta	File2Len  +1
			sta	File1stSek+0
			sta	File1stSek+1

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
			jmp	ExitDskErr		;Disketten-Fehler.

::102			ldx	#$ff
			lda	diskBlkBuf+0,x		;Datei-Typ für Ziel-Datei festlegen.
			bit	CBM_FileTMode
			bmi	:103
			lda	CBMFileType
::103			sta	DirEntry  +0

			lda	diskBlkBuf+1,x		;Adr. des ersten Daten-Sektors merken.
			sta	CurDiskSek+0
			lda	diskBlkBuf+2,x
			sta	CurDiskSek+1

			ldy	#$00
::104			lda	(a3L),y			;Datum-/Uhrzeit für Ziel-Datei
			sta	DirEntry +23,y		;festlegen.
			iny
			cpy	#$05
			bne	:104

			ldy	#$00
			tya
::105			sta	DirEntry +19,y		;GEOS-Variablen löschen.
			iny
			cpy	#$04
			bne	:105

			lda	diskBlkBuf+28,x		;Dateilänge Quell-Datei merken.
			sta	File1Len  + 0
			lda	diskBlkBuf+29,x
			sta	File1Len  + 1

;*** Ziel-Datei einlesen.
:ReadSeqFile		jsr	SetSource		;Quell-Laufwerk aktivieren.

			LoadW	a6,Memory2		;Zeiger auf Anfang Zwischenspeicher.

:ReadNxSek		MoveW	CurDiskSek,r1		;Zeiger auf nächsten Sektor CBM-Datei.
			LoadW	r4,Copy1Sek		;Zeiger auf Zwischenspeicher.
			jsr	InitForIO
			jsr	ReadBlock		;Sektor lesen.
			jsr	DoneWithIO
			txa
			beq	:101
			jmp	ExitDskErr		;Disketten-Fehler.

::101			jsr	Sub1FileLen
			jsr	CopyInfo		;Info ausgeben.

			ldx	#$02			;Adresse des nächsten Sektors merken.
::102			lda	Copy1Sek,x
			tay				;Zeichen übersetzen.
			lda	ConvTabBase,y

			cmp	#LF
			bne	:103
			bit	Txt_LfMode
			bvs	:105
			bvc	:104

::103			cmp	#CR
			bne	:104
			bit	Txt_LfMode		;LineFeed einfügen ?
			bpl	:104			;Nein, überspringen.
			jsr	WriteCBMbyte		;Byte in Copy-Puffer schreiben.
			lda	#LF

::104			jsr	WriteCBMbyte		;Byte in Copy-Puffer schreiben.

::105			lda	Copy1Sek +0		;Letzter Datei-Sektor ?
			bne	:107			;Nein, weiter...
			cpx	Copy1Sek +1		;Datei-Ende erreicht ?
			beq	:106			;Ja, Eintrag schreiben.
			inx
			jmp	:102			;Nächstes Zeichen kopieren.

::106			jsr	WriteAllData		;Rest-Speicher schreiben.
			jmp	MakeDirEntry		;Eintrag erzeugen.

::107			cpx	#$ff			;Alle Daten aus Sektors kopiert ?
			beq	:108			;Ja, Nächster Sektor.
			inx
			jmp	:102			;Nächstes Zeichen kopieren.

::108			MoveW	Copy1Sek,CurDiskSek
			lda	a6H
			cmp	#>EndBuffer		;Puffer voll ?
			bne	ReadNxSek		;Nein, nächsten Sektor lesen.

			jsr	WriteBuffer		;Speicher auf Disk schreiben.
			jmp	ReadSeqFile		;Nächsten Sektor lesen.

;*** Datei-Eintrag schreiben.
:MakeDirEntry		jsr	SetTarget		;Ziel-Laufwerk aktivieren.

			ClrB	r10L			;Freien Directory-Eintrag suchen.
			jsr	GetFreeDirBlk
			txa
			beq	:102
::101			jmp	ExitDskErr		;Disketten-Fehler.

::102			lda	File1stSek+0		;Adr. des ersten Sektors in
			sta	DirEntry  +1		;Datei-Eintrag schreiben.
			lda	File1stSek+1
			sta	DirEntry  +2

			lda	File2Len+0		;Dateilänge in
			sta	DirEntry+28		;Datei-Eintrag schreiben.
			lda	File2Len+1
			sta	DirEntry+29

			ldx	#$00			;Datei-Eintrag in
::103			lda	DirEntry,x		;Verzeichnis-Sektor übertragen.
			sta	diskBlkBuf,y
			iny
			inx
			cpx	#$1e
			bne	:103

			LoadW	r4,diskBlkBuf		;Verzeichnis-Sektor auf Diskette
			jsr	PutBlock		;zurückschreiben.
			txa
			beq	:105
::104			jmp	ExitDskErr		;Disketten-Fehler.

::105			jsr	PutDirHead		;BAM aktualisieren.
			txa				;Diskettenfehler ?
			bne	:104			; => Ja, Abbruch...
			rts

;*** Alle Daten auf Diskette schreiben.
:WriteAllData		lda	#$ff
			sta	EndOfFile

;*** Buffer auf Disk (Target) schreiben.
:WriteBuffer		jsr	CopyInfo		;Infos ausgeben.

			SubVW	Memory2,a6
			CmpW0	a6
			bne	:101
			rts				;Speicher ist leer. Ende.

::101			jsr	SetTarget		;Ziel-Laufwerk aktivieren.

			MoveW	a6,r2

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

			ldy	#$00
::105			lda	fileTrScTab,y		;Dateilänge Ziel-Datei korrigieren.
			beq	:106
			IncWord	File2Len
			iny
			iny
			bne	:105
::106			lda	fileTrScTab-2,y
			sta	FileSekBuf +0
			lda	fileTrScTab-1,y
			sta	FileSekBuf +1

			lda	File1stSek +0
			bne	:107
			lda	fileTrScTab +0		;Ersten Sektor der Datei merken.
			sta	File1stSek +0
			lda	fileTrScTab +1
			sta	File1stSek +1
			jmp	:108

::107			MoveB	FileLastSek +0,r1L	;Letzten Sektor der Datei lesen.
			MoveB	FileLastSek +1,r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa
			bne	:103
			lda	fileTrScTab +0		;Sektorverkettung zwischen dem
			sta	diskBlkBuf  +0		;letzten und den aktuellen Daten des
			lda	fileTrScTab +1		;Zwischenspeichers herstellen.
			sta	diskBlkBuf  +1
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
			sta	a6L
			lda	#>Memory2
			adc	r15H
			sta	a6H

::109			lda	FileSekBuf +0
			sta	FileLastSek +0
			lda	FileSekBuf +1
			sta	FileLastSek +1

			jmp	SetSource		;Quell-Laufwerk aktivieren.

;*** Variablen:
:StackPointer		b $00				;Stack-Zeiger.

:DirEntry		s $1e				;Directory-Eintrag.
:FileName		s $11				;Speicher für Dateiname.
:File2Len		w $0000				;Länge Ziel-Datei.
:File1Len		w $0000				;Länge Quell-Datei.
:EndOfFile		b $00				;$FF = Dateiende erreicht.
:CurDiskSek		b $00,$00			;Sektor Quell-Datei.
:File1stSek		b $00,$00			;Erster Sektor CBM-Datei.
:FileLastSek		b $00,$00			;Letzter gespeicherter Sektor.
:FileSekBuf		b $00,$00			;Zwischenspeicher letzter gespeicherter Sektor.

if Sprache = Deutsch
:V216a0			b PLAINTEXT
			b "Kopiere :",NULL
:V216a1			b "Blocks  :",NULL
:V216a2			b "Dateien :",NULL
endif

if Sprache = Englisch
:V216a0			b PLAINTEXT
			b "Copy    :",NULL
:V216a1			b "Blocks  :",NULL
:V216a2			b "Files :",NULL
endif

;*** Startadresse Kopierspeicher.
:Memory1
:Memory2		= (Memory1 / 256 +1)*256
