; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;


;*** Alle Dateien konvertieren.
:ConvertAllFiles	jsr	GotoFirstMenu
			jsr	ClrScreen
			jsr	ScreenInfo1

			lda	#$01
			sta	FileConvMode

			jsr	DefMenuEntrysTxt

			lda	MaxFilesOnDsk
			beq	:53

			lda	#$00
			sta	a9H
::51			lda	a9H
			jsr	SetVecFileEntry

			ldy	#$02
			lda	(a0L),y
			beq	:53

			LoadW	r1,CurFileName
			AddVW	5,a0
			ldx	#a0L
			jsr	Copy1Name

			jsr	DoConvert1File
			cpx	#$ff
			beq	:52
			txa
			bne	:54

::52			inc	a9H
			bne	:51

::53			jmp	StartMenü
::54			jmp	ExitDiskErr

;*** Eine Datei konvertieren.
:ConvertOneFile		jsr	ScreenInfo1
			jsr	DoConvert1File
			cpx	#$ff
			beq	:51
			txa
			bne	:52
::51			jmp	StartMenü

::52			jmp	ExitDiskErr		; => Diskettenfehler.

::53			LoadW	r5,NoCnvFileTxt		; => Keine konvertierte Datei.
			jmp	ErrDiskError

;*** Ausgewählte Datei konvertieren.
:DoConvert1File		jsr	FindSlctFile
			lda	dirEntryBuf+19
			beq	:101
			jmp	GEOS_CBM		; => GEOS nach CBM wandeln.
::101			jmp	CBM_GEOS		; => CBM nach GEOS wandeln.

;*** Zeiger auf VLIR-Header.
:SetVecHdrVLIR		lda	FileEntryBuf2 +1
			sta	r1L
			lda	FileEntryBuf2 +2
			sta	r1H
			LoadW	r4,VlirDataBuf1
			rts

;*** Datei von GEOS nach SEQ wandeln.
:GEOS_CBM		jsr	CVT_InitFile		;Konvertierung initialisieren.
			txa				;Diskettenfehler ?
			bne	:102			; => Ja, Ende...

			ldx	#$ff
			lda	dirEntryBuf   +19
			ora	dirEntryBuf   +20	;GEOS-Datei ?
			beq	:102			; => Nein, weiter...

			jsr	CVT_MakeHeader
			txa				;Diskettenfehler ?
			bne	:102			; => Ja, Ende...

			jsr	CVT_FileConvert		;Daten konvertieren.
			txa				;Diskettenfehler ?
			bne	:102			; => Ja, Ende...
			tya				;VLIR-Datei ?
			beq	:101			; => Nein, weiter...

			jsr	CVT_VlirConvert		;VLIR-Datei konvertieren.
			txa				;Diskettenfehler ?
			bne	:102			; => Ja, Ende...

			jsr	CVT_CheckFormat		;Auf GeoConvert-Format testen.
			txa				;Diskettenfehler ?
			bne	:102			; => Ja, Ende...

::101			jsr	CVT_CreateEntry		;Dateiname erstellen.

			jmp	CVT_SetNewEntry		;Dateieintrag schreiben.
::102			rts

;*** Konvertierung initialisieren.
:CVT_InitFile		jsr	GetFileDirPos		;Datei im Verzeichnis suchen.
			txa				;Diskettenfehler ?
			bne	:102			; => Ja, Ende...

			sta	FormatType		;CVT-Dateiformat "CONVERT Vx".

			ldy	#$1d			;Verzeichnis-Eintrag kopieren.
::101			lda	dirEntryBuf      ,y
			sta	FileEntryBuf1    ,y
			sta	FileEntryBuf2    ,y
			dey
			bpl	:101

::102			rts

;*** Fortsetzung: GEOS nach SEQ.
:CVT_MakeHeader		lda	FileEntryBuf2  +19	;Zeiger auf Infoblock einlesen.
			sta	diskBlkBuf     + 0
			lda	FileEntryBuf2  +20
			sta	diskBlkBuf     + 1

			ldy	#$1d 			;Original-Verzeichniseintrag
::51			lda	FileEntryBuf2  + 0,y	;in Datensektor kopieren.
			sta	diskBlkBuf     + 2,y
			dey
			bpl	:51

			ldy	#$1c
::52			lda	FormatCode1       ,y	;Formatkennung übertragen.
			sta	diskBlkBuf     +32,y
			dey
			bpl	:52

			lda	CBM_FileType 		;Dateityp überprüfen ?
			cmp	#$82 			;SEQ-Datei ?
			bne	:53 			;Ja, weiter...

			lda	#"P" 			;Formatkennung "PRG".
			sta	diskBlkBuf     +32
			lda	#"R"
			sta	diskBlkBuf     +33
			lda	#"G"
			sta	diskBlkBuf     +34

;*** Rest des Sektors löschen.
::53			ldy	#$42
			lda	#$00
::54			sta	diskBlkBuf        ,y
			iny
			bne	:54

;******************************************************************************
;*** Standard-CONVERT V2.x-Header.
;*** Daten werden nicht abgefragt, daher nicht integriert.
;******************************************************************************
if 0=1
			ldy	#$04 			;GEOS-Informationen kopieren.
::55			lda	version           ,y	;"version", "nationality",
			sta	diskBlkBuf     +66,y	;"unknown", "sysFlgCopy" und
			dey	 			;"c128Flag".
			bpl	:55

			ldy	#$03 			;Laufwerksinformationen in
::56			lda	driveType      + 0,y	;Datensektor kopieren.
			sta	diskBlkBuf     +71,y
			dey
			bpl	:56

			ldy	#$10 			;Name des Druckertreibers in
::57			lda	PrntFileName      ,y	;Datensektor kopieren.
			sta	diskBlkBuf     +75,y
			dey
			bpl	:57

			ldy	#$10 			;Daten aus Kernal in
::58			lda	$c9ef             ,y	;Datensektor kopieren.
			sta	diskBlkBuf     +92,y
			dey
			bpl	:58

			ldy	#$17 			;(c)-Hinweis.
::59			lda	FormatCode3       ,y
			sta	diskBlkBuf    +160,y
			dey
			bpl	:59
endif
;******************************************************************************
;*** Ab hier wieder Standard-Routine.
;******************************************************************************

			jsr	CVT_AllocSektor		;Freien Sektor reservieren.
			txa				;Diskettenfehler ?
			bne	:60			; => Ja, Ende...

			lda	CurSektor      + 0
			sta	FileEntryBuf1  + 1
			sta	r1L
			lda	CurSektor      + 1
			sta	FileEntryBuf1  + 2
			sta	r1H
			LoadW	r4,diskBlkBuf 		;CVT-Datensektor auf
			jmp	PutBlock 		;Diskette schreiben.
::60			rts

;*** Daten konvertieren.
:CVT_FileConvert	lda	FileEntryBuf2  +19
			sta	r1L
			lda	FileEntryBuf2  +20
			sta	r1H
			LoadW	r4,diskBlkBuf 		;Datensektor auf
			jsr	GetBlock 		;Infoblock einlesen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Ende...

			lda	FileEntryBuf2  + 1
			sta	diskBlkBuf     + 0
			lda	FileEntryBuf2  + 2
			sta	diskBlkBuf     + 1
			jsr	PutBlock 		;Ersten Sektor lesen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Ende...

			ldy	FileEntryBuf2  +21	;Dateistruktur.
::51			rts

;*** VLIR-Datei nach SEQ wandeln.
:CVT_VlirConvert	jsr	EnterTurbo		;TurboDOS aktivieren und
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	SetVecHdrVLIR		;Zeiger auf VLIR-Sektor.
			jsr	ReadBlock		;VLIR-Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch.

			lda	#$00			;Datensektor für Highbytes
			tay				;der Sektorzähler löschen.
::51			sta	VlirDataBuf2,y
			iny
			bne	:51

;			lda	#$00			;Flag löschen:
			sta	Flag_Set1stSek		;Erster Sektor der Datei.

			lda	#$02			;Zeiger auf VLIR-Eintrag.
			sta	VecToVlirEntry

			jsr	CVT_AddSekVLIR

::52			jmp	DoneWithIO

;*** VLIR-Daten an SEQ-Datei anfügen.
:CVT_AddSekVLIR		LoadW	r4,diskBlkBuf

			lda	VecToVlirEntry		;Zeiger auf VLIR-
							;Eintrag einlesen.
::51			tay
			lda	VlirDataBuf1   + 0,y	;VLIR-Datensatz belegt ?
			beq	:56			; => Nein, übergehen.
			sta	diskBlkBuf     + 0	;Erster Durchlauf:
			lda	VlirDataBuf1   + 1,y	;Infoblock steht ab :diskBlkBuf
			sta	diskBlkBuf     + 1	;im Speicher. Hier wird dann
							;Track/Sektor des ersten Daten-
							;satzes als Linkzeiger gesetzt.

			lda	Flag_Set1stSek 		;Erster VLIR-Datensatz ?
			bne	:52			; => Nein, weiter...
			lda	diskBlkBuf     + 0	;Verbindung Infoblock mit
			sta	VlirDataBuf1   + 0	;erstem VLIR-Datensatz (s.o.)
			lda	diskBlkBuf     + 1
			sta	VlirDataBuf1   + 1
			jmp	:53

;--- Ersten Sektor aus Datensatz schreiben.
::52			jsr	WriteBlock		;VLIR-Datensektor speichern.
			txa				;Diskettenfehler ?
			bne	:58			; => Ja, Abbruch.

;--- Neuen Datensatz lesen.
::53			lda	#$00			;Länge des Datensatzes
			sta	LenOfSekStrg   + 0	;löschen.
			sta	LenOfSekStrg   + 1

;--- Datensatz bis zum Ende einlesen.
::54			lda	diskBlkBuf     + 0
			sta	r1L
			lda	diskBlkBuf     + 1
			sta	r1H
			jsr	ReadBlock		;Nächsten VLIR-Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:58			; => Ja, Abbruch.

			inc	LenOfSekStrg   + 0 	;Anzahl Sektoren im
			bne	:55			;aktuellen Datensatz +1.
			inc	LenOfSekStrg   + 1

::55			lda	diskBlkBuf     + 0	;Letzter Sektor ?
			bne	:54 			;Nein, nächsten Sektor lesen.

;--- Daten für Datensatz speichern.
			ldy	VecToVlirEntry
			lda	LenOfSekStrg   + 0	;Anzahl Sektoren in aktuellem
			sta	VlirDataBuf1   + 0,y	;Datensatz merken.
			lda	LenOfSekStrg   + 1	;Highbyte in Zwischenspeicher.
			sta	VlirDataBuf2   + 0,y

			lda	diskBlkBuf     + 1	;Anzahl Bytes in letztem
			sta	VlirDataBuf1   + 1,y	;Sektor merken.

			lda	#$ff
			sta	Flag_Set1stSek

::56			inc	VecToVlirEntry 		;Zeiger auf nächsten VLIR-
			inc	VecToVlirEntry 		;Eintrag in Tabelle.
			lda	VecToVlirEntry 		;Ende erreicht ?
			bne	:51 			;Nein, weiter...

::57			jsr	SetVecHdrVLIR 		;Zeiger auf VLIR-Sektor.
			jmp	WriteBlock 		;Sektor schreiben.
::58			rts

;*** GEOS nach GeoConvert98-Format wandeln.
:CVT_CheckFormat	ldx	#$02
::51			lda	VlirDataBuf2,x
			bne	:53
			inx
			bne	:51
::52			rts

::53			jsr	CVT_AllocSektor		;Freien Sektor belegen.
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch.

			jsr	SetVecHdrVLIR		;Zeiger auf VLIR-Header.
			jsr	GetBlock
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch.

			lda	VlirDataBuf1   + 0	;Zeiger auf VLIR-Daten in
			sta	VlirDataBuf2   + 0	;zweiten Info-Sektor kopieren.
			lda	VlirDataBuf1   + 1
			sta	VlirDataBuf2   + 1

			lda	CurSektor      + 0	;Zeiger auf zweiten Info-Sektor
			sta	VlirDataBuf1   + 0	;in VLIR-Header übertragen.
			lda	CurSektor      + 1
			sta	VlirDataBuf1   + 1

			jsr	PutBlock		;VLIR-Header zurück auf Disk.
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch.

			lda	CurSektor      + 0
			sta	r1L
			lda	CurSektor      + 1
			sta	r1H
			LoadW	r4,VlirDataBuf2
			jsr	PutBlock		;Zweiten Info-Sektor schreiben.
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch.

;--- GeoConvert-Header schreiben.
			lda	FileEntryBuf1  + 1
			sta	r1L
			lda	FileEntryBuf1  + 2
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa				;Diskettenfehler ?
			bne	:55			; => Ja, Abbruch.

			ldy	#$18
::54			lda	FormatCode4       ,y	;Formatkennung übertragen.
			sta	diskBlkBuf     +35,y	;CVT-Datei kann nicht mehr mit
			dey				;CONVERT Vx bearbeitet werden!
			bpl	:54

			jsr	PutBlock		;Formatkennung V2 schreiben.
			txa				;Diskettenfehler ?
			bne	:55			; => Ja, Abbruch.

			lda	#$ff
			sta	FormatType

			inc	FileEntryBuf1  +28	;Anzahl belegter Blöcke +1.
			bne	:55
			inc	FileEntryBuf1  +29
::55			rts

;*** Eintrag für CBM-Datei erzeugen.
:CVT_CreateEntry	lda	CBM_FileType		;CBM-Dateityp kopieren.
			sta	FileEntryBuf1 + 0

			LoadW	r0,CurFileName		;MSDODS-Dateiname erzeugen.
			jsr	SetNameDOS

			ldx	#< FormatExt1		;Endung für CONVERT-Format.
			ldy	#> FormatExt1
			bit	FormatType
			bpl	:51
			ldx	#< FormatExt2		;Endung für GeoConvert-Format.
			ldy	#> FormatExt2

::51			stx	r0L			;Datei-Endung erstellen.
			sty	r0H

			LoadW	r1,FileNameDOS+ 8

			ldx	#r0L
			ldy	#r1L
			lda	#$04
			jsr	CopyFString

			lda	#$00			;Dateiname auf "8+3"-Zeichen
			sta	FileNameDOS   +12	;begrenzen.
			sta	FileNameDOS   +13
			sta	FileNameDOS   +14
			sta	FileNameDOS   +15
			sta	FileNameDOS   +16
			sta	FileNameDOS   +17

			jsr	CheckCurFileNm		;Dateiname überprüfen.

			ldy	#$00			;Dateiname in Speicher für
::52			lda	FileNameDOS      ,y	;Dateieintrag kopieren.
			beq	:53
			sta	FileEntryBuf1 + 3,y
			iny
			cpy	#16
			bcc	:52
			bcs	:54

::53			lda	#$a0			;Dateiname auf 16 Zeichen mit
			sta	FileEntryBuf1 + 3,y	;$A0-Bytes auffüllen.
			iny
			cpy	#16
			bcc	:53

::54			lda	#$00 			;GEOS-Informationen aus
			sta	FileEntryBuf1 +19 	;Dateieintrag löschen.
			sta	FileEntryBuf1 +20
			sta	FileEntryBuf1 +21
			sta	FileEntryBuf1 +22

			inc	FileEntryBuf1 +28	;Anzahl belegter Blöcke +1.
			bne	:56
			inc	FileEntryBuf1 +29
::56			rts

;*** Neuen verzeichnis-Eintrag schreiben.
:CVT_SetNewEntry	lda	FileDirSek    + 0	;Verzeichnissektor für
			sta	r1L 			;Dateieintrag lesen.
			lda	FileDirSek    + 1
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Ende...

			lda	FileDirPos    + 0	;Zeiger auf Dateieintrag.
			sta	r5L
			lda	FileDirPos    + 1
			sta	r5H

			ldy	#$1d 			;Neuen Eintrag in Verzeichnis-
::51			lda	FileEntryBuf1 + 0,y	;Sektor kopieren.
			sta	(r5L)            ,y
			dey
			bpl	:51

			jmp	PutBlock 		;Verzeichnis aktualisieren.
::52			rts

;*** Freien Sektor reservieren.
:CVT_AllocSektor	jsr	GetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:101			; => Ja, Ende...

			LoadB	r3L,1
			LoadB	r3H,1
			jsr	SetNextFree		;Ersten freien Sektor suchen.
			txa				;Diskettenfehler ?
			bne	:101			; => Ja, Ende...

			lda	r3L			;Belegten Sektor merken.
			sta	CurSektor     +0
			lda	r3H
			sta	CurSektor     +1
			jmp	PutDirHead		;BAM aktualisieren.
::101			rts

;*** CVT/G98-Sektor freigeben.
:CVT_FreeSektor		pha
			txa
			pha
			jsr	GetDirHead		;BAM einlesen.
			pla
			sta	r6H
			pla
			sta	r6L
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch.

			lda	version			;GEOS-Version testen.
			cmp	#$12			;Version 1.x ?
			beq	:51			; => Ja, Sonderbehandlung.
			jsr	FreeBlock		;Sektor freigeben.
			jmp	PutDirHead		;BAM aktualsieren.

::51			jsr	sysFreeBlock		;Sektor freigeben.
			jmp	PutDirHead		;BAM aktualsieren.

::52			rts

;*** CBM-Datei nach GEOS konvertieren.
:CBM_GEOS		jsr	CVT_InitFile
			txa				;Diskettenfehler ?
			bne	:102			; => Ja, Ende...

			ldx	#$ff
			lda	dirEntryBuf   +19
			ora	dirEntryBuf   +20	;GEOS-Datei ?
			bne	:102			; => Ja, weiter...

			jsr	CVT_GetFormat
			cpx	#$ff			;Keine CVT/G98-Datei ?
			beq	:102			; => Ja, Ende...
			txa				;Diskettenfehler ?
			bne	:102			; => Ja, Ende...

			jsr	CVT_SeqConvert		;Daten konvertieren.
			txa				;Diskettenfehler ?
			bne	:102			; => Ja, Ende...
			tya
			beq	:101

			jsr	CVT_SeqVlirConv

::101			jsr	CVT_SetNewEntry		;dateieintrag schreiben.
::102			rts

;*** CVT/G98-Format bestimmen.
:CVT_GetFormat		lda	FileEntryBuf1  + 1	;Zeiger auf CVT/G98-Header
			ldx	FileEntryBuf1  + 2	;einlesen und speichern.
			sta	CurSektor      + 0
			stx	CurSektor      + 1
			sta	r1L
			stx	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;CVT/G98-Header einlesen.
			txa				;Diskettenfehler ?
			bne	:58			; => Ja, Abbruch.

			ldy	#$19
::51			lda	diskBlkBuf     +35,y
			cmp	FormatCode2       ,y	;Formatkennung prüfen.
			bne	:52			;Fehler -> Keine CVT-Datei.
			dey
			bpl	:51
			bmi	:56

::52			ldy	#$19
::53			lda	diskBlkBuf     +35,y
			cmp	FormatCode4       ,y	;Formatkennung prüfen.
			bne	:54 			;Fehler -> Keine G98-Datei.
			dey
			bpl	:53

			lda	VlirDataBuf2   + 0
			sta	VlirDataBuf1   + 0
			lda	VlirDataBuf2   + 1
			sta	VlirDataBuf1   + 1

			dec	FormatType		;Flag setzen: "G98-Datei".
			jmp	:56

::54			ldx	#$ff
::55			rts

;--- Original-Dateieintrag kopieren.
::56			ldx	#$1d
::57			lda	diskBlkBuf     + 2,x	;Original-Dateieintrag
			sta	FileEntryBuf1  + 0,x	;aus Datensektor kopieren.
			dex
			bpl	:57

			lda	diskBlkBuf     + 0	;Zeiger auf Infoblock in
			sta	FileEntryBuf1  +19	;Verzeichniseintrag kopieren.
			lda	diskBlkBuf     + 1
			sta	FileEntryBuf1  +20

			lda	CurSektor      + 0	;Zeiger auf G98-Header und
			ldx	CurSektor      + 1	;Sektor freigeben.
			jsr	CVT_FreeSektor
::58			rts

;*** VLIR-Konvertierung initialisieren.
:CVT_SeqConvert		lda	FileEntryBuf1  +19	;Zeiger auf Infoblock in
			sta	r1L			;Verzeichniseintrag kopieren.
			lda	FileEntryBuf1  +20
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Infoblock-Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch.

			lda	diskBlkBuf     + 0	;Zeiger auf VLIR-Header
			sta	FileEntryBuf1  + 1	;einlesen und in Dateieintrag
			lda	diskBlkBuf     + 1	;kopieren.
			sta	FileEntryBuf1  + 2

			lda	#$00 			;Sektorverkettung im
			sta	diskBlkBuf     + 0	;Infoblock löschen.
			lda	#$ff
			sta	diskBlkBuf     + 1
			jsr	PutBlock
			txa	 			;Diskettenfehler ?
			bne	:53 			;Ja, Abbruch.

			ldy	FileEntryBuf1  +21	;VLIR-Datei ?
			beq	:53

			lda	FileEntryBuf1  + 1	;Zeiger auf VLIR-Header
			sta	r1L			;setzen. Dieser Sektor enthält
			lda	FileEntryBuf1  + 2	;die VLIR-Informationen.
			sta	r1H
			LoadW	r4,VlirDataBuf1
			jsr	GetBlock		;VLIR-Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch.

			tay				;Datensektor für Highbytes
::51			sta	VlirDataBuf2,y		;der Sektorzähler löschen.
			iny
			bne	:51

			bit	FormatType		;G98-Datei ?
			bpl	:52			; => Nein, weiter...

;--- G98-Header einlesen.
			lda	VlirDataBuf1   + 0
			sta	r1L
			lda	VlirDataBuf1   + 1
			sta	r1H
			LoadW	r4,VlirDataBuf2
			jsr	GetBlock		;Zweiten Info-Sektor schreiben.
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch.

			lda	VlirDataBuf1   + 0	;Zeiger auf G98-Header und
			ldx	VlirDataBuf1   + 1	;Sektor freigeben.
			jsr	CVT_FreeSektor
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch.

			lda	VlirDataBuf2   + 0
			sta	VlirDataBuf1   + 0
			lda	VlirDataBuf2   + 1
			sta	VlirDataBuf1   + 1

;--- CVT/G98-Header in BAM freigeben.
::52			ldy	FileEntryBuf1  +21	;VLIR-Datei ?
::53			rts

;*** Verzeichniseintrag aktualisieren.
:CVT_SeqVlirConv	jsr	EnterTurbo		;TurboDOS aktivieren und
			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	VlirDataBuf1   + 0	;Zeiger auf ersten Sektor der
			sta	r1L			;VLIR-Daten setzen.
			lda	VlirDataBuf1   + 1
			sta	r1H

			lda	#$02			;Zeiger auf VLIR-Eintrag.
			sta	VecToVlirEntry

::51			tay
			lda	VlirDataBuf1   + 0,y	;VLIR-Datensatz belegt ?
			beq	:55			; => Nein, weiter...
			sta	LenOfSekStrg   + 0
			lda	VlirDataBuf2   + 0,y	;Anzahl Sektoren in aktuellem
			sta	LenOfSekStrg   + 1	;Datensatz einlesen.

			lda	VlirDataBuf1   + 1,y	;Anzahl Bytes in letztem
			sta	ByteInLastSek		;Datensatz-Sektor merken.

			lda	r1L			;Start-Sektor des aktuellen
			sta	VlirDataBuf1   + 0,y	;Datensatzes in VLIR-Header.
			lda	r1H
			sta	VlirDataBuf1   + 1,y
			LoadW	r4,diskBlkBuf

;--- Aktuellen Datensatz lesen.
::52			jsr	ReadBlock		;Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:56			; => Ja, Abbruch...

			lda	LenOfSekStrg   + 0	;Anzahl Sektoren in aktuellem
			bne	:53			;Datensatz -1.
			dec	LenOfSekStrg   + 1
::53			dec	LenOfSekStrg   + 0	;Alle Sektoren gelesen ?
			lda	LenOfSekStrg   + 0
			ora	LenOfSekStrg   + 1
			beq	:54			; => Ja, Ende...

			lda	diskBlkBuf     + 0	;Zeiger auf nächsten Sektor.
			sta	r1L
			lda	diskBlkBuf     + 1
			sta	r1H
			jmp	:52			;Nächsten Sektor lesen.

;--- Aktuellen Datensatz abschließen.
::54			lda	diskBlkBuf     + 0	;Zeiger auf nächsten Sektor
			pha				;zwischenspeichern.
			lda	diskBlkBuf     + 1
			pha

			lda	#$00			;Letzten Sektor markieren und
			sta	diskBlkBuf     + 0	;Anzahl Bytes in letztem
			lda	ByteInLastSek		;Sektor festlegen.
			sta	diskBlkBuf     + 1
			jsr	WriteBlock		;Letzten VLIR-Sektor schreiben.

			pla				;Zeiger auf nächsten Sektor
			sta	r1H			;einlesen und speichern.
			pla
			sta	r1L
			txa				;Diskettenfehler ?
			bne	:56			; => Ja, Abbruch.

;--- Zeiger auf nächsten Datensatz.
::55			inc	VecToVlirEntry		;Zeiger auf nächsten
			inc	VecToVlirEntry		;Datensatz.

			lda	VecToVlirEntry		;Alle Datensätze erzeugt ?
			bne	:51			;Nein, weiter...

			lda	#$00			;Sektorverkettung für
			sta	VlirDataBuf1   + 0	;VLIR-Header löschen.
			lda	#$ff
			sta	VlirDataBuf1   + 1

			lda	FileEntryBuf1  + 1
			sta	r1L
			lda	FileEntryBuf1  + 2
			sta	r1H
			LoadW	r4,VlirDataBuf1
			jsr	WriteBlock		;Sektor speichern.
::56			jmp	DoneWithIO

;*** Variablen.
:FileEntryBuf1		s 30
:FileEntryBuf2		s 30
:FormatType		b $00			;$00 = CONVERT
						;$FF = GeoConvert98

:VlirDataBuf1		s 256
:VlirDataBuf2		s 256
:VecToVlirEntry		b $00
:Flag_Set1stSek		b $00
:LenOfSekStrg		w $0000
:ByteInLastSek		b $00

:FormatCode1		b "SEQ"
:FormatCode2		b " formatted GEOS file V1.0",NULL
:FormatCode3		b $c2,$4c,$41,$53,$54,$45,$52,$27
			b $53,$20,$c3,$4f,$4e,$56,$45,$52
			b $54,$45,$52,$20,$d6,$32,$2e,$31
:FormatExt1		b ".CVT"

:FormatCode4		b " GeoConvert98-format V2.0",NULL
:FormatExt2		b ".G98"
