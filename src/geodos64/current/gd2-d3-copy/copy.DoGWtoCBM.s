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

			n	"mod.#218.obj"
			o	ModStart

			jmp	DoGWtoCBM

;*** Quell- und Ziel-Laufwerk setzen.
			t   "-SetDriveCBM"

;*** L218: Datei von GeoWrite nach Text kopieren
:ConvTabBase		= SCREEN_BASE
:File_Name		= SCREEN_BASE +256
:File_Datum		= File_Name   +256*16

:EndBuffer		= $7000
:GWBufSize		= $1a00
:MaxGWpages		= 61

;A2  = Zeiger auf Datei-Namen.
;A3  = Zeiger auf Datei-Datum.

:DoGWtoCBM		tsx
			stx	StackPointer

;*** Ausgabe-Fenster.
:DoCopyBox		jsr	UseGDFont 		;Bildschirm Initialisieren.
			Display	ST_WR_FORE

			FillPRec$00,$b8,$c7,$0000,$013f
			jsr	i_ColorBox
			b	$00,$00,$28,$17,$00
			jsr	i_ColorBox
			b	$00,$17,$28,$02,$36

			PrintXY	  6,190,V218a0		;Text "Kopiere".
			PrintXY	  6,198,V218a1		;Text "Anzahl".
			PrintXY	219,190,V218a2		;Text "BLocks".

::102			StartMouse			;Maus aktivieren.
			NoMseKey

			LoadW	a2,File_Name
			LoadW	a3,File_Datum

:CopyFiles		lda	pressFlag		;Abbruch durch Maus-Klick ?
			bne	L218ExitGD		;Ja, Ende...

			lda	AnzahlFiles		;Alle Dateien kopiert ?
			beq	L218ExitGD		;Ja, Ende...

			jsr	PrintName		;Datei-Name ausgeben.
			jsr	StartCopy		;Einzel-Datei kopieren.

::103			AddVBW	16,a2			;Zeiger auf nächste Datei.
			AddVBW	10,a3

			dec	AnzahlFiles		;Alle Dateien kopiert ?
			bne	CopyFiles		;Nein, weiter...

;*** Ende. Zurück zu GeoDOS.
:L218ExitGD		jsr	SetTarget
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
			sta	FileName,y		;kopieren.
			dey
			bpl	:101

			PrintXY	80,190,FileName

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
			MoveW	File1Len,r0
			ClrB	r1L
			ldy	#$09
			jmp	DoZahl24Bit

;*** Datensatz-Nummer asgeben.
:PrintVLIR		PrintXY	219,198,V218a3

			LoadW	r11,293
			MoveB	VLIR1_Set,r0L		;Datensatz-Nr. = Seite ausgeben.
			ClrB	r0H
			lda	#%11000000		;Datensatz ausgeben.
			jmp	PutDecimal

;*** Dateilänge -1
:Sub1FileLen		CmpW0	File1Len		;Alle Blocks kopiert ?
			beq	:101			;Nein, weiter.
			SubVW	1,File1Len		;Anzahl Blocks -1.
::101			rts

;*** Einzel-Datei kopieren.
:StartCopy		jsr	SetSource		;Quell-Laufwerk aktivieren.

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
::101			jmp	ExitDskErr		;Disketten-Fehler.

::102			ldx	#$ff
			lda	diskBlkBuf+0,x
			bit	CBM_FileTMode
			bmi	:103
			lda	CBMFileType
::103			sta	DirEntry+0

			lda	diskBlkBuf+1,x		;Adresse VLIR-Header merken.
			sta	r1L
			lda	diskBlkBuf+2,x
			sta	r1H

			ldy	#$00
::104			lda	(a3L),y			;Datum-/Uhrzeit für Ziel-Datei
			sta	DirEntry +23,y		;festlegen.
			iny
			cpy	#$05
			bne	:104

			lda	diskBlkBuf+28,x		;Dateilänge Quell-Datei merken.
			sta	File1Len  + 0
			lda	diskBlkBuf+29,x
			sta	File1Len  + 1

			LoadW	r4,Copy2Sek		;VLIR-Header Quell-Datei einlesen.
			jsr	GetBlock
			txa
			bne	:101

;*** Text-Seiten kopieren.
:CopyMode1		lda	#$00			;Zeiger auf VLIR-Einträge
			sta	VLIR1_Set		;initialisieren.
			sta	File1stSek+0
			sta	File1stSek+1
			sta	File2Len  +0
			sta	File2Len  +1
			LoadW	a6,Memory2		;Neue Seite einrichten.

::101			inc	VLIR1_Set
			lda	VLIR1_Set
			cmp	#MaxGWpages +1		;Photoscraps ?
			bcc	:102			;Nein, Textseite kopieren.
			jmp	MakeDirEntry		;Photoscraps kopieren.

::102			asl
			tax
			lda	Copy2Sek+0,x		;VLIR-Datensatz belegt ?
			beq	:101			;Nein, nicht kopieren.
			sta	CurGWsek +0
			lda	Copy2Sek+1,x
			sta	CurGWsek +1
			jsr	PrintVLIR		;Datensatz-Nr. ausgeben.

			lda	#$00
			sta	IgnoreBytes
			jsr	CopyTextPage		;Textseite kopieren.
			jmp	:101			;Nächsten Datensatz kopieren.

;*** Textseite einlesen.
:CopyTextPage		MoveW	CurGWsek,r1		;Track/Sektor für Quell-Datei.
			LoadW	r4,Copy1Sek		;Zeiger auf Zwischenspeicher.
			jsr	InitForIO
			jsr	ReadBlock		;Sektor lesen.
			jsr	DoneWithIO
			txa
			beq	:102
			jmp	ExitDskErr		;Disketten-Fehler.

::102			jsr	Sub1FileLen		;Anzahl Blocks -1.
			jsr	CopyInfo		;Info ausgeben.

			ldy	#$ff			;Anzahl Bytes berechnen.
			lda	Copy1Sek +0
			bne	:103
			ldy	Copy1Sek +1
::103			sty	:16 +1

			ldx	#$02			;Zeiger auf erstes Byte.
			stx	:104+1

::104			ldx	#$ff

			ldy	IgnoreBytes		;Aktuelles Byte ignorieren ?
			beq	:105			;Nein, kopieren.
			dec	IgnoreBytes		;Byte übergehen.
			jmp	:15			;Weiter mit nächstem Byte.

::105			lda	Copy1Sek,x		;Byte einlesen.

			cmp	#ESC_RULER		;"ESC_RULER" ausfiltern.
			bne	:106
			ldy	#27 -1
			bne	:108

::106			cmp	#NEWCARDSET		;"NEWCARDSET" ausfiltern.
			bne	:107
			ldy	#4 -1
			bne	:108

::107			cmp	#ESC_GRAPHICS		;"ESC_GRAPHICS" ausfiltern.
			bne	:110

			ldy	#$00			;Damit im konvertierten Text
::801			lda	:901,y			;erkennbar ist das hier eine Grafik
			beq	:802			;fehlt wird hier ein Platzhalter
			tax				;eingefügt.
			tya
			pha
			txa
			jsr	WriteCBMByte		;Seite abschließen und speichern.
			pla
			tay
			iny
			bne	:801
::802			jsr	AddCRLF
			ldy	#5 -1
			jmp	:108

::901			b "                "		;Einrückung um 16Zeichen.
			b "<MISSING_IMAGE_DATA>",$00

::108			sty	IgnoreBytes
			jmp	:15

::110			cmp	#PAGE_BREAK		;"FormFeed" ?
			bne	:13			;Nein, weiter...
			bit	Txt_FfMode		;Modus testen.
			bmi	:14			;$FF = übernehmen.
			jsr	AddCRLF
			jsr	AddCRLF
			jmp	:15

::13			cmp	#CR			;"Carriage Return" ?
			bne	:14			;Nein, weiter...
			jsr	AddCRLF
			jmp	:15

;*** Byte in Speicher übertragen.
::14			jsr	WriteCBMByte

;*** Zeiger auf nächstes Byte.
::15			ldx	:104 +1
::16			cpx	#$ff
			beq	:17
			inc	:104 +1
			jmp	:104

::17			lda	Copy1Sek+1		;Adresse des nächsten Sektors in
			sta	CurGWsek +1		;Speicher übertragen.
			lda	Copy1Sek+0
			sta	CurGWsek +0		;Letzter Sektor ?
			bne	:20			;Nein, weiter...

			lda	VLIR1_Set
			cmp	#MaxGWpages		;Kopf-/Fußzeile ?
			bcs	:18			;Ja, alle Daten schreiben.
			asl
			tax
			lda	Copy2Sek +2,x		;Weitere Seite vorhanden ?
			bne	:19			;Ja, übergehen.
::18			jsr	WriteAllData		;Alle Daten aus Puffer schreiben.
			LoadW	a6,Memory2		;Neue Seite einrichten.
::19			rts				;Ende.

::20			jmp	CopyTextPage		;Nächstenn Sektor/Seite kopieren.

;*** CR/LF einfügen.
:AddCRLF		lda	#CR			;$00 = Nur Leerzeile einfügen.
			bit	Txt_LfMode		;Modus testen.
			bpl	WriteCBMByte		;Kein LF einfügen...
			jsr	WriteCBMByte		;Byte speichern.
			lda	#LF			;LF einfügen.

;*** Byte in Speicher übertragen.
:WriteCBMByte		tay
			lda	ConvTabBase,y
			ldy	#$00			;Byte in Speicher schreiben.
			sta	(a6L),y
			IncWord	a6			;Zeiger auf Speicher korrigieren.
			lda	a6H
			cmp	#>EndBuffer		;Speicher voll ?
			bcc	:1			;Nein, weiter...
			jsr	WriteBuffer		;Seite speichern.
::1			rts

;*** Kompletten Buffer speichern.
:WriteAllData		LoadB	GW_EOF,$ff

;*** Buffer auf Disk (Target) schreiben.
:WriteBuffer		jsr	CopyInfo		;Infos ausgeben.

			sec				;Sind Daten im Puffer?
			lda	a6L
			sbc	#<Memory2
			tax
			lda	a6H
			sbc	#>Memory2
			bne	:101			; => Ja, mehr als 256 Bytes.
			cpx	#$00
			bne	:101			; => Ja, mind. 255 Bytes.
::100			rts				; => Nein, keine Daten schreiben.

;*** Buffer auf Disk (Target) schreiben (Fortsetzung).
::101			stx	a6L
			sta	a6H

			jsr	SetTarget		;Ziel-Laufwerk aktivieren.

			MoveW	a6,r2			;Puffergröße nach r2.

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

			lda	File1stSek +0
			bne	:107

			lda	fileTrScTab+0		;Ersten Sektor der Datei merken.
			sta	File1stSek +0
			lda	fileTrScTab+1
			sta	File1stSek +1
			jmp	:109

::107			MoveB	FileLastSek +0,r1L	;Letzten Sektor der Datei lesen.
			MoveB	FileLastSek +1,r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa
			bne	:103

::108			lda	fileTrScTab +0		;Sektorverkettung zwischen dem
			sta	diskBlkBuf  +0		;letzten und den aktuellen Daten des
			lda	fileTrScTab +1		;Zwischenspeichers herstellen.
			sta	diskBlkBuf  +1
			jsr	PutBlock		;Sektor zurück auf Disk schreiben.
			txa
			bne	:103

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

::110			lda	FileSekBuf +0
			sta	FileLastSek+0
			lda	FileSekBuf +1
			sta	FileLastSek+1
			ClrB	GW_EOF
			jmp	SetSource

;*** GEOS-Datei: VLIR-Header/Info-Block kopieren.
:MakeDirEntry		jsr	SetTarget

			ClrB	r10L			;Freien Directory-Eintrag suchen.
			jsr	GetFreeDirBlk
			txa
			beq	:102
::101			jmp	ExitDskErr		;Disketten-Fehler.

::102			ldx	#0
::103			lda	FileName,x
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

::105			lda	File1stSek+0		;Adr. des ersten Sektors in
			sta	DirEntry  +1		;Datei-Eintrag schreiben.
			lda	File1stSek+1
			sta	DirEntry  +2

			lda	#NULL			;GeoWrite-Daten festlegen.
			sta	DirEntry+19
			sta	DirEntry+20
			sta	DirEntry+21
			sta	DirEntry+22

			ldx	#$00
::106			lda	DirEntry,x		;Datei-Eintrag in Verzeichnis-Sektor
			sta	diskBlkBuf,y		;übertragen.
			iny
			inx
			cpx	#$1c
			bne	:106

			lda	File2Len  +0		;Dateilänge in Datei-Eintrag schreiben.
			sta	diskBlkBuf+0,y
			lda	File2Len  +1
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

;*** Variablen:
:StackPointer		b $00				;Stack-Zeiger.

:DirEntry		s $1e				;Directory-Eintrag.
:FileName		s $11				;Speicher für Datei-Name.
:VLIR1_Set		b $00				;VLIR-Zeiger Quell-Datei.
:GW_EOF			b $00				;$FF = Dateiende erreicht.
:IgnoreBytes		b $00				;Anzahl Bytes ignorieren.
:File1Len		w $0000				;Länge Quell-Datei.
:File2Len		w $0000				;Länge Ziel-Datei.
:CurGWsek		b $00,$00			;Sektor Quell-Datei.
:File1stSek		b $00,$00			;Erster Sektor CBM-Datei.
:FileLastSek		b $00,$00			;Letzter gespeicherter Sektor.
:FileSekBuf		b $00,$00			;Zwischenspeicher letzter gespeicherter Sektor.

if Sprache = Deutsch
:V218a0			b PLAINTEXT
			b "Kopiere :",NULL
:V218a1			b "Blocks  : ",NULL
:V218a2			b "Dateien :",NULL
:V218a3			b "Seite   :     ",NULL
endif

if Sprache = Englisch
:V218a0			b PLAINTEXT
			b "Copy    :",NULL
:V218a1			b "Blocks  : ",NULL
:V218a2			b "Files   :",NULL
:V218a3			b "Page    :     ",NULL
endif

;*** Startadresse Kopierspeicher.
:Memory1
:Memory2		= (Memory1 / 256 +1)*256
