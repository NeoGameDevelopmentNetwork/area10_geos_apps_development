; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Verzeichnis in DACC-Speicher einlesen.
;Max. 2048 Dateien = 256 Sektoren.
:Read64kDir		jsr	GetDirHead		;BAM einlesen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			jsr	EnterTurbo		;TurboDOS aktivieren und
			jsr	InitForIO		;I/O aktivieren.

			lda	#$00
			sta	a5L			;Anzahl Sektoren löschen.
			sta	a6L			;Zeiger auf DACC-Speicher
			sta	a6H			;zurücksetzen.

			MoveW	curDirHead,r1		;Zeiger auf ersten Verz.-Sektor.
			LoadW	r4,diskBlkBuf		;Zeiger auf Zwischenspeicher.

::read			inc	a5L			;Anzahl Verzeichnis-Sektoren +1.

			jsr	ReadBlock		;Verzeichnis-Sektor einlesen.
			txa				;Fehler?
			bne	:err_exit		; => Ja, Abbruch...

			LoadW	r0,diskBlkBuf		;Disk-Sektor in DACC kopieren.
			MoveW	a6,r1
			LoadW	r2,256
			MoveB	sort64Kbank,r3L
			jsr	StashRAM

			ldy	#$00
			lda	(r4L),y			;Weiterer Verzeichnis-Sektor?
			beq	:end			; => Nein, Ende...
			sta	r1L
			iny
			lda	(r4L),y			;Zeiger auf nächsten
			sta	r1H			;Verzeichnis-Sektor setzen.

			inc	a6H			;Zeiger auf nächsten Sektorspeicher.

			lda	a5L			;Max. Anzahl Sektoren erreicht?
			cmp	#MaxReadSek
			bne	:read			; => Nein, weiter...

			ldx	#FULL_DIRECTORY		;Fehler: Verzeichnis zu groß.
			b $2c
::end			ldx	#NO_ERROR
::err_exit		jsr	DoneWithIO		;I/O abschalten.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			lda	a5L			;Anzahl Verzeichnis-Sektoren.
			sta	SekInMem

			jmp	ImportFiles		;Dateien einlesen.

;--- Laufwerksfehler.
::error			rts

;*** Dateien in Tabelle übernehmen.
:ImportFiles		lda	#<FLIST_SOURCE		;Tabelle Quelldateien löschen.
			ldx	#>FLIST_SOURCE
			jsr	:doInit

			lda	#<FLIST_TARGET		;Tabelle Zieldateien löschen.
			ldx	#>FLIST_TARGET
			jsr	:doInit
			jmp	:init

;--- Tabellenbereich initialisieren.
;$7FFF = Nicht belegt.
;$0xxx = Datei, nicht markiert.
;$8xxx = Datei, markiert.
;$FFFF = Temp. Datei während Übertrag.
::doInit		sta	r0L			;Zeiger auf Datenbereich.
			stx	r0H

			LoadW	r2,MaxSortFiles		;Größe Datenbereich.

::1			ldy	#$00			;Zeiger auf Low-Byte setzen.
			lda	#$ff
			sta	(r0L),y			;Low-Byte Dateinummer löschen.
			iny				;Zeiger auf High-Byte setzen.
			lda	#$7f
			sta	(r0L),y			;Low-Byte Dateinummer löschen.

			AddVBW	2,r0			;Zeiger auf nächsten Eintrag.

			lda	r2L			;Zähler für Größe Datenbereich
			bne	:2			;korrigieren.
			dec	r2H
::2			dec	r2L

			lda	r2L
			ora	r2H			;Datenbereich gelöscht?
			bne	:1			; => Nein, weiter...

			rts

;--- Dateinummern übernehmen.
::init			lda	#<diskBlkBuf		;Adr. Verzeichnisblock im RAM.
			sta	r0L
			lda	#>diskBlkBuf
			sta	r0H

			ldx	#$00			;Adr. Verzeichnisblock im DACC.
			stx	r1L
			stx	r1H

;			ldx	#$00			;Größe Verzeichnisblock = 256Bytes.
			stx	r2L
			lda	#$01
			sta	r2H

			MoveB	sort64Kbank,r3L		;Adresse 64K-Bank im DACC.

;			ldx	#$00
			stx	r5L			;Dateizähler.
			stx	r5H
			stx	r6L			;Dateiposition in DACC.
			stx	r6H

			LoadW	r10,FLIST_SOURCE	;Zeiger auf Anfang Quelldateien.

;--- Dateienummern aus DACC übernehmen.
::loop			jsr	FetchRAM		;Disk-Sektor aus DACC einlesen.

			LoadB	r7L,2			;Zeiger auf ersten Eintrag.

::read			ldy	r7L
			lda	diskBlkBuf,y		;Dateieintrag gültig?
			beq	:next			; => Nein, weiter...

			ldy	#$00			;Index einlesen.
			lda	r6L			;Nr. Eintrag in DACC für Sortieren
			sta	(r10L),y		;in Tabelle übernehmen.
			iny
			lda	r6H
			sta	(r10L),y

			AddVBW	2,r10			;Zeiger auf nächsten Eintrag.

			IncW	r5			;Anzahl Dateieinträge +1.

			lda	r5H			;Absolutes Max. für Dateien ist
			cmp	#>2048			;2048 in einer 64K-Speicherbank.
			beq	:error			; => Verzeichnis zu groß.
			cmp	#>MaxSortFiles		;Liste voll?
			bne	:exitcmp
			lda	r5L
			cmp	#<MaxSortFiles
::exitcmp		bcs	:end			; => Ja, Ende...

::next			IncW	r6			;Dateinummer +1.

			AddVB	32,r7L			;Zeiger auf nächsten Eintrag.
			bcc	:read			; => Weiter mit nächstem Eintrag.

			inc	r1H			;Sektor-Zähler +1.
			lda	r1H
			cmp	SekInMem		;Alle Sektoren durchsucht?
			beq	:end			; => Ja, Ende...

			lda	diskBlkBuf +0		;Verzeichnis-Ende erreicht?
			bne	:loop			; => Nein, weiter...

;--- Alle Dateien übernommen.
::end			lda	r5L			;Anzahl Dateien in Liste speichern.
			sta	SortS_Max
			lda	r5H
			sta	SortS_MaxH

			ldx	#$00			;Anzahl Dateien Ziel löschen.
			stx	SortT_Max
			stx	SortT_MaxH

			stx	SortS_Top		;Tabellen auf Anfang setzen.
			stx	SortS_TopH
			stx	SortT_Top
			stx	SortT_TopH

			stx	SortS_Slct		;Ausgewählte Dateien zurücksetzen.
			stx	SortS_SlctH
			stx	SortT_Slct
			stx	SortT_SlctH

;			ldx	#NO_ERROR		;Kein Fehler.
			b $2c
::error			ldx	#FULL_DIRECTORY		;Verzeichnis zu groß.
			rts

;*** Neues Verzeichnis schreiben.
:Write64kDir		jsr	GetDirHead		;BAM einlesen.
			txa				;Fehler?
			beq	:1			; => Nein, weiter...
			rts

::1			jsr	EnterTurbo		;TurboDOS aktivieren und
			jsr	InitForIO		;I/O aktivieren.

			lda	#$00
			sta	a5L			;Anzahl Sektoren löschen.
			sta	a6L			;Zeiger auf DACC-Speicher
			sta	a6H			;zurücksetzen.

			MoveW	curDirHead,r1		;Zeiger auf ersten Verz.-Sektor.
			LoadW	r4,diskBlkBuf		;Zeiger auf Zwischenspeicher.

			LoadW	a1,FLIST_TARGET		;Dateizähler auf Anfang.

;--- Verzeichnis-Block einlesen.
::loop			jsr	ReadBlock		;Verzeichnis-Sektor einlesen.
			txa				;Fehler?
			beq	:10			; => Nein, weiter...
			jmp	:end			; => Ja, Abbruch...

::10			ldy	#$02			;Bestehende Verzeichniseinträge
;			lda	#$00			;löschen.
::11			sta	(r4L),y
			iny
			bne	:11

			PushB	r1L			;Aktuelle Sektor-Adresse speichern.
			PushB	r1H

;--- 8 Verzeichniseinträge je Block.
;Makro "CmpW" hier nicht verwenden!
::next			lda	a6H			;Bereits alle Dateien geschrieben?
			cmp	SortT_MaxH
			bne	:exitcmp
			lda	a6L
			cmp	SortT_Max
::exitcmp		bcc	:20			; => Nein, weiter...

;--- Ältere Verzeichniseinträge löschen.
::clear			ldx	#$00
			stx	diskBlkBuf +0
			dex
			stx	diskBlkBuf +1
			bne	:40

;--- Verzeichniseintrag übernehmen.
::20			ldy	#$00			;Dateinummer einlesen.
			lda	(a1L),y
			sta	a7L			;Low-Byte Dateinummer setzen.
			iny
			lda	(a1L),y
			sta	a7H			;High-Byte Dateinummer setzen.

			jsr	GetFilePos16		;Zeiger auf Verzeichniseintrag.

			ldy	#$02			;Verzeichniseintrag kopieren.
::21			lda	(a7L),y
			sta	(r4L),y
			iny
			cpy	#$20
			bne	:21

;--- Nächster Verzeichniseintrag.
::30			IncW	a6			;Dateizähler +1.

			AddVBW	2,a1			;Zeiger auf nächste Datei.

			AddVB	32,r4L			;Zeiger auf nächsten Eintrag.
			bcc	:next			; => Sektor noch nicht voll...

;--- Verzeichnis-Sektor schreiben.
::40			PopB	r1H			;Aktuelle Sektor-Adresse setzen.
			PopB	r1L
			LoadW	r4,diskBlkBuf		;Zeiger auf Zwischenspeicher.
			jsr	WriteBlock		;Verzeichnis-Sektor schreiben.
			txa				;Fehler?
			bne	:end			; => Ja, Abbruch...

			inc	a5L			;Sektorzähler korrigieren.
			lda	a5L
			cmp	SekInMem		;Alle Sektoren geschrieben?
			beq	:end			; => Ja, Ende...

			lda	diskBlkBuf +0		;Zeiger auf nächsten Sektor.
			beq	:end			; => Ende erreicht.
			sta	r1L
			lda	diskBlkBuf +1
			sta	r1H
			jmp	:loop			;Weiter mit nächstem Sektor.

;--- Verzeichnis komplett oder Fehler.
::end			jsr	DoneWithIO		;I/O beenden.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

;--- NativeMode-Verzeichnisse korrigieren.
			lda	curType			;Laufwerkstyp einlesen.
			and	#DRIVE_MODES
			cmp	#DrvNative		;NativeMode ?
			bne	:exit			; => Nein, weiter...

			jsr	VerifyNMDir		;Verzeichnis-Header korrigieren.
::exit			rts				;Ende.
