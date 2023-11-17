; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Verzeichnis in Speicher einlesen.
;Max. 224 Dateien = 28 Sektoren.
:Read224Dir		jsr	i_FillRam		;Speicher löschen.
			w	MaxReadSek * 256
			w	DIRSEK_SOURCE
			b	$00

			jsr	GetDirHead		;BAM einlesen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			jsr	EnterTurbo		;TurboDOS aktivieren und
			jsr	InitForIO		;I/O aktivieren.

			lda	#$00
			sta	a5L			;Anzahl Sektoren löschen.

			MoveW	curDirHead,r1		;Zeiger auf ersten Verz.-Sektor.
			LoadW	r4,DIRSEK_SOURCE	;Zeiger auf Zwischenspeicher.

::read			inc	a5L			;Anzahl Verzeichnis-Sektoren +1.

			jsr	ReadBlock		;Verzeichnis-Sektor einlesen.
			txa				;Fehler?
			bne	:err_exit		; => Ja, Abbruch...

			ldy	#$00
			lda	(r4L),y			;Weiterer Verzeichnis-Sektor?
			beq	:end			; => Nein, Ende...
			sta	r1L
			iny
			lda	(r4L),y			;Zeiger auf nächsten
			sta	r1H			;Verzeichnis-Sektor setzen.

			inc	r4H			;Zeiger auf nächsten Sektorspeicher.

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
:ImportFiles		ldy	#$00
			tya
::1			sta	FLIST_SOURCE,y		;Tabelle Quelldateien löschen.
			sta	FSLCT_SOURCE,y
			sta	FLIST_TARGET,y		;Tabelle Zieldateien löschen.
			sta	FSLCT_TARGET,y
			iny				;Alle Daten gelöscht?
			bne	:1			; => Nein, weiter...

;--- Dateinummern übernehmen.
::init			lda	#<DIRSEK_SOURCE		;Adr. Verzeichnisblock in RAM.
			sta	r4L
			lda	#>DIRSEK_SOURCE
			sta	r4H

			ldx	#$00			;Anzahl Verzeichnisblöcke.
			stx	r1H

			stx	r5L			;Dateizähler.
			stx	r6L			;Dateiposition im RAM.

;--- Dateinummern in Tabelle übernehmen.
::loop			LoadB	r7L,2			;Zeiger auf ersten Eintrag.

::read			ldy	r7L
			lda	(r4L),y			;Dateieintrag gültig?
			beq	:next			; => Nein, weiter...

			ldx	r5L			;Index einlesen.
			lda	r6L			;Nr. Eintrag für Sortieren
			sta	FLIST_SOURCE,x		;in Tabelle übernehmen.
			inc	r5L
			inx
			cpx	#MaxSortFiles		;Liste voll?
			beq	:end			; => Ja, Ende...

::next			inc	r6L			;Dateinummer +1.

			AddVB	32,r7L			;Zeiger auf nächsten Eintrag.
			bcc	:read			; => Weiter mit nächstem Eintrag.

			inc	r1H			;Sektor-Zähler +1.
			lda	r1H
			cmp	SekInMem		;Alle Sektoren durchsucht?
			beq	:end			; => Ja, Ende...

			ldy	#$00
			lda	(r4L),y			;Verzeichnis-Ende erreicht?
			beq	:end			; => Ja, Ende...

			inc	r4H			;Zeiger auf nächsten Sektor.
			bne	:loop			;Nächste Dateien auswerten.

;--- Alle Dateien übernommen.
::end			lda	r5L			;Anzahl Dateien in Liste speichern.
			sta	SortS_Max

			ldx	#$00			;Anzahl Dateien Ziel löschen.
			stx	SortT_Max

			stx	SortS_Top		;Tabellen auf Anfang setzen.
			stx	SortT_Top

			stx	SortS_Slct		;Ausgewählte Dateien zurücksetzen.
			stx	SortT_Slct

;			ldx	#NO_ERROR		;Kein Fehler.
			b $2c
::error			ldx	#FULL_DIRECTORY		;Verzeichnis zu groß.
			rts

;*** Neues Verzeichnis schreiben.
:Write224Dir		jsr	GetDirHead		;BAM einlesen.
			txa				;Fehler?
			beq	:1			; => Nein, weiter...
			rts

::1			jsr	EnterTurbo		;TurboDOS aktivieren und
			jsr	InitForIO		;I/O aktivieren.

			lda	#$00
			sta	a5L			;Anzahl Sektoren zurücksetzen.
			sta	a6L			;Dateizähler löschen.

			MoveW	curDirHead,r1		;Zeiger auf Verzeichnis-Sektor.
			LoadW	r4,diskBlkBuf		;Puffer für Verzeichnis-Sektor.

;--- Verzeichnis schreiben.
::loop			jsr	ReadBlock		;Verzeichnis-Sektor einlesen.
			txa				;Fehler?
			beq	:10			; => Nein, weiter...
			jmp	:end			; => Ja, Abbruch...

::10			ldy	#$02			;Bestehende Verzeichniseinträge
;			lda	#$00			;löschen.
::11			sta	(r4L),y
			iny
			bne	:11

;--- 8 Verzeichniseinträge je Block.
::next			CmpB	a6L,SortT_Max		;Bereits alle Dateien geschrieben?
			bcc	:20			; => Nein, weiter...

;--- Ältere Verzeichniseinträge löschen.
			ldx	#$00
			stx	diskBlkBuf +0
			dex
			stx	diskBlkBuf +1
			bne	:40

;--- Verzeichniseintrag übernehmen.
::20			ldx	a6L			;Dateiposition einlesen.
			lda	FLIST_TARGET,x		;Dateinummer einlesen.
			sta	a7L			;8-Bit-Wert Dateinummer setzen.

			jsr	GetFilePos8		;Zeiger auf Verzeichniseintrag.

			ldy	#$02			;Verzeichniseintrag kopieren.
::21			lda	(a7L),y
			sta	(r4L),y
			iny
			cpy	#$20
			bne	:21

;--- Nächster Verzeichniseintrag.
::30			inc	a6L			;Zeiger auf nächste Datei.

			AddVB	32,r4L			;Zeiger auf nächsten Eintrag.
			bcc	:next			; => Sektor noch nicht voll...

;--- Verzeichnis-Sektor schreiben.
::40			LoadW	r4,diskBlkBuf		;Zeiger auf Zwischenspeicher.
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
