; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** CBM-Datei zurück nach GEOS wandeln.
:Convert1File		jsr	OpenTargetDrive		;Ziel-Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:55			; => Ja, Abbruch...

			LoadW	r6,FNameBuffer
			jsr	FindFile		;.CVT-Datei suchen.
			txa				;Diskettenfehler ?
			bne	:55			; => Ja, Abbruch...

			jsr	Sv_EntryPosCNV		;Verzeichnis-Position speichern.

			ldy	#$1d			;Eintrag der Datei in Zwischen-
::51			lda	dirEntryBuf  ,y		;speicher kopieren.
			sta	FileEntryBuf1,y
			dey
			bpl	:51

::52			lda	FileEntryBuf1 +1	;Zeiger auf ersten Sektor der
			sta	r1L			;.CNV-Datei setzen.
			lda	FileEntryBuf1 +2
			sta	r1H
			jsr	GetSek_dskBlkBuf	;Ersten Sektor der Datei einlesen.
			bne	:55			; => Diskettenfehler, Abbruch...

			ldx	#$0a			;Fehler: "Falsches Dateiformat".
			ldy	#$19
::53			lda	diskBlkBuf +35,y
			cmp	FormatCode2   ,y	;Formatkennung prüfen.
			bne	:55			;Fehler -> Keine CVT-Datei.
			dey
			bpl	:53

			ldx	#$1d			;Original-Dateieintrag
::54			lda	diskBlkBuf  +2,x	;aus Datensektor kopieren.
			sta	FileEntryBuf2 ,x
			dex
			bpl	:54

			lda	diskBlkBuf   +0		;Zeiger auf Infoblock in
			sta	FileEntryBuf2+19	;Verzeichniseintrag kopieren.
			sta	r1L
			lda	diskBlkBuf   +1
			sta	FileEntryBuf2+20
			sta	r1H
			jsr	GetSek_dskBlkBuf	;Sektor für Infoblock einlesen.
			beq	:56			; => Diskettenfehler, Abbruch.
::55			rts

::56			lda	diskBlkBuf   +0		;Zeiger auf Datensektor/VLIR-Header
			sta	FileEntryBuf2+1		;einlesen und speichern.
			lda	diskBlkBuf   +1
			sta	FileEntryBuf2+2

			lda	#$00			;Sektorverkettung im
			sta	diskBlkBuf   +0		;Infoblock löschen.
			lda	#$ff
			sta	diskBlkBuf   +1
			jsr	PutBlock		;InfoBlock aktualisieren.
			txa				;Diskettenfehler ?
			bne	:55			; => Ja, Abbruch.

;--- Verzeichniseintrag aktualisieren.
			jsr	GetFileDirSek
			txa
			bne	:55

			ldy	#$1d
::57			lda	FileEntryBuf2,y		;Eintrag in Verzeichnissektor
			sta	(r5L)        ,y		;übertragen.
			dey
			bpl	:57

			jsr	PutBlock		;Verzeichnis aktualisieren.
			txa
			bne	:55

			jsr	GetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:55			; => Ja, Abbruch.

			lda	FileEntryBuf1 +1	;Zeiger auf Datensektor mit
			sta	r6L			;.CVT-Kennung.
			lda	FileEntryBuf1 +2
			sta	r6H
			jsr	FreeBlock		;Sektor freigeben.

::58			jsr	PutDirHead		;BAM aktualsieren.
			txa				;Diskettenfehler ?
			bne	:55			;Ja, Abbruch.

			lda	FileEntryBuf2 +21	;VLIR-Datei ?
			bne	Convert1VLIR		; => Ja, weiter...

			LoadW	r0,100
			jsr	PrintCurPercent

			ldx	#NO_ERROR
			rts

;*** VLIR-Datei zurück nach GEOS wandeln.
:Convert1VLIR		jsr	EnterTurbo		;TurboDOS aktivieren.
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	SetVecHdrVLIR		;Zeiger auf VLIR-Sektor.
			jsr	ReadBlock		;Sektor lesen.
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch.

			lda	FileHdrBlock +0		;Zeiger auf ersten Sektor der
			sta	r1L			;Programmdaten.
			lda	FileHdrBlock +1
			sta	r1H

			lda	#$02
			sta	CNV_VlirSize +0
			lda	#$00
			sta	CNV_VlirSize +1
			ldy	#$02			;Zeiger auf VLIR-Eintrag.
::51			sty	CNV_VlirEntry
			lda	FileHdrBlock +0,y	;VLIR-Datensatz belegt ?
			beq	:57			; => Nein, übergehen.
			sta	CNV_VlirSekCnt		;Anzahl Sektoren/Datensatz merken.
			lda	FileHdrBlock +1,y	;Anzahl Bytes in letztem
			sta	CNV_VlirSekByt		;Datensatz-Sektor merken.

			lda	r1L			;Start-Sektor des aktuellen
			sta	FileHdrBlock +0,y	;Datensatzes in VLIR-Header.
			lda	r1H
			sta	FileHdrBlock +1,y
			LoadW	r4,diskBlkBuf
::52			jsr	ReadBlock		;Sektor einlesen.
			txa				;Diskettenfehler ?
			beq	:54			; => Ja, Abbruch.
::53			jmp	DoneWithIO		;I/O-Bereich ausblenden.

::54			inc	CNV_VlirSize +0
			bne	:55
			inc	CNV_VlirSize +1

::55			dec	CNV_VlirSekCnt		;Alle Sektoren gelesen ?
			beq	:56			; => Ja, Ende...

			lda	diskBlkBuf   +0		;Zeiger auf nächsten Sektor.
			sta	r1L
			lda	diskBlkBuf   +1
			sta	r1H
			jmp	:52			;Nächsten Sektor lesen.

::56			lda	diskBlkBuf   +0		;Zeiger auf nächsten Sektor
			pha				;zwischenspeichern.
			lda	diskBlkBuf   +1
			pha

			lda	#$00			;Letzten Sektor
			sta	diskBlkBuf   +0		;kennzeichnen.
			lda	CNV_VlirSekByt		;Anzahl Bytes in letztem
			sta	diskBlkBuf   +1		;Sektor festlegen.
			jsr	WriteBlock		;Sektor schreiben.
			pla				;Zeiger auf nächsten Sektor.
			sta	r1H
			pla
			sta	r1L
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch.

::57			ldy	CNV_VlirEntry		;Zeiger auf nächsten Datensatz.
			iny
			iny				;Alle Datensätze erzeugt ?
			bne	:51			; => Nein, weiter...

			lda	#$00			;Sektorverkettung für
			sta	FileHdrBlock  +0	;Linkzeiger löschen.
			lda	#$ff
			sta	FileHdrBlock  +1
			jsr	SetVecHdrVLIR		;Zeiger auf VLIR-Sektor.
			jsr	WriteBlock		;Sektor speichern.
::58			jsr	DoneWithIO		;I/O-Bereich ausblenden.

;*** Dateigröße korrigieren.
:NewFileSize		jsr	GetFileDirSek		;Verzeichnissektor lesen.
			txa
			bne	:51

			ldy	#$1c
			lda	CNV_VlirSize +0
			sta	(r5L),y
			iny
			lda	CNV_VlirSize +1
			sta	(r5L),y
			jsr	PutBlock
			txa
			bne	:51

			LoadW	r0,100
			jsr	PrintCurPercent

			ldx	#NO_ERROR
::51			rts

;*** Zeiger auf Verzeichnis-Eintrag zwischenspeichern.
:Sv_EntryPosCNV		lda	r1L			;Zeiger auf Verzeichnis-Sektor
			sta	CNV_DirSek_S		;zwischenspeichern.
			lda	r1H
			sta	CNV_DirSek_T
			lda	r5L			;Zeiger auf Verzeichnis-Eintrag
			sta	CNV_DirSek_Vec +0	;zwischenspeichern.
			lda	r5H
			sta	CNV_DirSek_Vec +1
			rts

;*** Verzeichnis-Sektor einlesen.
:GetFileDirSek		lda	CNV_DirSek_S
			sta	r1L
			lda	CNV_DirSek_T
			sta	r1H
			lda	CNV_DirSek_Vec +0
			sta	r5L
			lda	CNV_DirSek_Vec +1
			sta	r5H

;*** Sektor nach ":diskBlkBuf" einlesen.
:GetSek_dskBlkBuf	LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Ersten Sektor der Datei einlesen.
			txa				;Diskettenfehler ?
			rts

;*** Zeiger auf VLIR-Header.
:SetVecHdrVLIR		lda	FileEntryBuf2 +1
			sta	r1L
			lda	FileEntryBuf2 +2
			sta	r1H
			LoadW	r4,FileHdrBlock
			rts

;*** Variablen für .CVT-Konvertierung.
:CNV_DirSek_S		b $00
:CNV_DirSek_T		b $00
:CNV_DirSek_Vec		w $0000
:CNV_VlirSize		w $0000
:CNV_VlirEntry		b $00
:CNV_VlirSekCnt		b $00
:CNV_VlirSekByt		b $00

:FileEntryBuf1		s 30
:FileEntryBuf2		s 30
:FileHdrBlock		s 256

:FormatCode1		b "GD3"
:FormatCode2		b " formatted GEOS file V1.0",NULL
