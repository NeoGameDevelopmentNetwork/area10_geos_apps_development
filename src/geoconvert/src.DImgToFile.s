; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;geoConvert
;D64->File
if .p
			t "TopSym"
			t "TopMac"
			t "src.geoConve.ext"
endif

			n "mod.#1"
			o VLIR_BASE
			p START_D64_FILE

;*** Sub-Routinen anspringen.
:START_D64_FILE		lda	#DRV_1541		;1541-Modus als Standard-Modus wählen.
			sta	DiskImageMode

			ldx	FileConvMode
			cpx	#ConvMode_D64_FILE	;Dateiliste im D64-Archiv anzeigen?
			beq	InitD64DirList		;Ja, weiter...
			cpx	#ConvMode_D64_FILE_SAVE	;Datei zum speichern ausgewählt?
			bne	:1			;Nein, weiter...
			jmp	ExtractD64File		;Datei aus Archiv entpacken.

::1			lda	#DRV_1571
			sta	DiskImageMode

			cpx	#ConvMode_D71_FILE	;Dateiliste im D71-Archiv anzeigen?
			beq	InitD64DirList		;Ja, weiter...
			cpx	#ConvMode_D71_FILE_SAVE	;Datei zum speichern ausgewählt?
			bne	:2			;Nein, weiter...
			jmp	ExtractD64File		;Datei aus Archiv entpacken.

::2			lda	#DRV_1581
			sta	DiskImageMode

			cpx	#ConvMode_D81_FILE	;Dateiliste im D81-Archiv anzeigen?
			beq	InitD64DirList		;Ja, weiter...
			cpx	#ConvMode_D81_FILE_SAVE	;Datei zum speichern ausgewählt?
			bne	:3			;Nein, weiter...
			jmp	ExtractD64File		;Datei aus Archiv entpacken.

::3			ldx	#$14			;Unbekannter Befehl.
			jmp	ExitDiskErr

;*** Verzeichnis aus D64-Archiv einlesen.
:InitD64DirList		jsr	ClrScreen		;Bildschirm löschen.
			jsr	DiskImage_ReadSekAdr	;Sektoradressen innerhalb der D64-Datei einlesen.

;*** Dateien aus Verzeichnis einlesen.
:GetD64DirFiles		lda	#$00
			sta	FilesOnDisk		;Anzahl Dateien auf Disk löschen.
			sta	MaxFilesOnDsk		;Max. Anzahl Dateien auf Disk löschen.
			sta	CurFNameEntryInMenu	;Zeiger auf ersten Eintrag setzen.

			jsr	i_FillRam		;Speicher für Verzeichniseinträge löschen.
			w	DskImgMaxDirFiles*32
			w	DskImgDirData
			b	$00

			LoadW	a4,DskImgDirData	;Zeiger auf Anfang Verzeichnis-Speicher.

			jsr	EnterTurbo
			jsr	InitForIO

			ldx	#$12			;1541/71: Verzeichnis beginnt ab Spur 18/Sektor 1.
			lda	#$01
			ldy	DiskImageMode
			cpy	#DRV_1541
			beq	:101
			cpy	#DRV_1571
			beq	:101
			ldx	#$28			;1581: Verzeichnis beginnt ab Spur 40/Sektor 3.
			lda	#$03
::101			jsr	PosToSektor		;Zeiger auf Sektor innerhalb Disk-Abbild berechnen.
			LoadW	r15,diskBlkBuf		;Sektor aus Archiv auslesen.
			jsr	GetSektor

			ldx	#$00
::102			lda	diskBlkBuf +$02,x	;Verzeichnis-Typ testen.
			cmp	#$80 ! SEQ		;Nur SEQQ, PRG und USR erlauben.
			beq	:103			;REL-Dateien werden nicht unterstützt.
			cmp	#$80 ! PRG
			beq	:103
			cmp	#$80 ! USR
			bne	:106
::103			txa				;Gültige Datei, Verzeichnis-Eintrag kopieren.
			pha
			ldy	#$00
::104			lda	diskBlkBuf +$00,x
			sta	(a4L),y
			inx
			iny
			cpy	#$20
			bne	:104

			AddVW	32,a4			;Zeiger auf nächsten Speicherplatz für Verzechniseinträge.
			inc	MaxFilesOnDsk
			lda	MaxFilesOnDsk		;Verzeichnis-Speicher voll?
			cmp	#DskImgMaxDirFiles
			bcc	:105			;Nein, weiter.
			pla
			jmp	:107

::105			pla
			tax
::106			txa				;Zeiger auf nächsten Eintrag in Verzeichnis-Sektor
			clc				;berechnen.
			adc	#32
			tax				;Alle Einträge im Sektor ausgelesen?
			bne	:102			;Nein, weiter...
			lda	diskBlkBuf +$01		;Zeiger auf nächsten Verzeichnis-Sektor.
			ldx	diskBlkBuf +$00		;Letzter  Sektor erreicht?
			bne	:101			;Nein, weiter...

::107			jsr	DoneWithIO

			lda	#ConvMode_D64_FILE_SAVE	;Konvertierungsmodus festlegen.
			ldx	DiskImageMode
			cpx	#DRV_1541
			beq	:108
			lda	#ConvMode_D71_FILE_SAVE
			ldx	DiskImageMode
			cpx	#DRV_1571
			beq	:108
			lda	#ConvMode_D81_FILE_SAVE
::108			sta	FileConvMode
;			jsr	SetMenuData		;Wird der Befehl hier benötigt???
			jsr	AddFilesToMenu		;Verzeichniseinträge in Menü übernehmen.

;*** Image-Verzeichnis anzeigen.
:ViewD64Dir		LoadW	r0,MenuFiles		;Dateiauswahl-Menü anzeigen.
			lda	#$01
			jmp	DoMenu

;*** Datei aus D64-Datei extrahieren.
:ExtractD64File		ldy	#$02 			;Verzeichnis-Eintrag der ausgewählten Datei
::102			lda	(a0L),y			;zwischenspeichern.
			sta	dirEntryBuf -$02,y
			sta	OrgFileEntry -$02,y
			iny
			cpy	#$20
			bne	:102

			LoadB	dispBufferOn,ST_WR_FORE	;Vordergrund-Bildschirm löschen.
							;Hintergrund-Bildschirm wird als Zwischenspeicher genutzt.
			jsr	i_GraphicsString	;Dateiname ausgeben.
			b	NEWPATTERN,$00
			b	MOVEPENTO
			w	$0040
			b	$48
			b	RECTANGLETO
			w	$00ff
			b	$7f
			b	FRAME_RECTO
			w	$0040
			b	$48
			b	MOVEPENTO
			w	$0042
			b	$4a
			b	FRAME_RECTO
			w	$00fd
			b	$7d
			b	NULL

			LoadW	r0,Text_FileName
			jsr	PutString

			ldy	#$00			;Dateiname ausgeben.
::103			lda	dirEntryBuf +$03,y	;Nicht druckbare Zeichen imm Dateinamen
			sta	ExtractFileName ,y	;durch * ersetzen.
			cmp	#$a0
			beq	:107
			sty	:106 +1
			cmp	#$20
			bcc	:104
			cmp	#$7f
			bcc	:105
::104			lda	#"*"
::105			jsr	SmallPutChar
::106			ldy	#$ff
			iny
			cpy	#$10
			bne	:103

::107			lda	#$00
			sta	ExtractFileName,y

			LoadW	r0,Text_FStructInfo	;Dateityp ausgebenn (Sequentiell, GEOS oder VLIR)
			jsr	PutString

			lda	#<Text_FStructSEQ
			ldx	#>Text_FStructSEQ
			ldy	dirEntryBuf +$13
			beq	:108
			lda	#<Text_FStructGEOS
			ldx	#>Text_FStructGEOS
			ldy	dirEntryBuf +$15
			beq	:108
			lda	#<Text_FStructVLIR
			ldx	#>Text_FStructVLIR
::108			sta	r0L
			stx	r0H
			jsr	PutString

			LoadW	r0,Text_FSize		;DDateigröße ausgeben.
			jsr	PutString

			lda	dirEntryBuf +$1c
			sta	r0L
			lda	dirEntryBuf +$1d
			sta	r0H
			lda	#%11000000
			jsr	PutDecimal

			LoadW	r0,Text_FSizeBlk
			jsr	PutString

			jsr	TextInfo_DelOldFile	;Evtl. Existierende Datei löschen.

			lda	TargetDrive
			jsr	SetDevice
			LoadW	r0,ExtractFileName
			jsr	DeleteFile

			jsr	TextInfo_ExtractDImgF	;Texthinweis ausgeben.

;*** Datei einlesen.
:ReadD64File		lda	#$01 			;Suche nach erstem freien
			sta	a4L 			;Sektor initialsieren.
			sta	a4H

			lda	OrgFileEntry +$13	;infoblock vorhanden?
			beq	:101			;Nein, weiter...
			ldx	OrgFileEntry +$14
			jsr	CopyD64SeqChain		;Infoblock kopieren. Der Block wird dabei wie eine Datei
			lda	dirEntryBuf +$01	;behandelt und als "Datei" kopiert.
			ldx	dirEntryBuf +$02	;Zeiger auf den entpackten Infoblock an
			sta	dirEntryBuf +$13	;die richtige  Stelle imm Verzeichnis-Eintrag verschieben.
			stx	dirEntryBuf +$14

::101			lda	OrgFileEntry +$01	;Bei SEQ Datei kopieren, bei VLIR-Datei den
			ldx	OrgFileEntry +$02	;VLIR-Headerblock kopieren.
			jsr	CopyD64SeqChain

			lda	OrgFileEntry +$15	;VLIR-Datei?
			bne	:102			;Ja, weiter...
			jmp	WriteFileEntry		;Verzeichnis-Eintrag schreiben.

::102			lda	TargetDrive
			jsr	SetDevice

			lda	dirEntryBuf +$01	;VLIR-Header einlesen.
			ldx	dirEntryBuf +$02
			sta	NewVlirHdrSek +$00
			stx	NewVlirHdrSek +$01
			sta	r1L
			stx	r1H
			LoadW	r4,NewVlirHeader
			jsr	GetBlock
			txa				;Diskettenfehler?
			bne	:105			;Ja, Abbruch...

			LoadB	VecNewVlirHdr,$02	;Zeiger auf ersten VLIR-Datensatz.

::103			ldy	VecNewVlirHdr
			lda	NewVlirHeader +$00,y	;VLIR-Datensatz belegt?
			beq	:104			;Nein, weiter...
			ldx	NewVlirHeader +$01,y	;VLIR-Datensatz als Datei kopieren.
			jsr	CopyD64SeqChain

			ldy	VecNewVlirHdr		;Zeiger auf erstenn Sektor des kopierrtenn VLIR-
			lda	dirEntryBuf +$01	;Datensatzes in neuennn VLIR-Header speichern.
			sta	NewVlirHeader +$00,y
			lda	dirEntryBuf +$02
			sta	NewVlirHeader +$01,y

::104			inc	VecNewVlirHdr		;Alle Datensätze kopiert?
			inc	VecNewVlirHdr
			bne	:103			;Nein, weiter..

			lda	TargetDrive		;Ziel-Laufwerk aktivieren.
			jsr	SetDevice

			lda	NewVlirHdrSek +$00	;Neuen VLIR-Header schreiben.
			ldx	NewVlirHdrSek +$01
			sta	dirEntryBuf +$01
			stx	dirEntryBuf +$02
			sta	r1L
			stx	r1H
			LoadW	r4,NewVlirHeader
			jsr	PutBlock
			txa				;Diskettenfehler?
			beq	WriteFileEntry		;Nein, weiter...
::105			jmp	ExitDiskErr

;*** Verzeichniseintrag schreiben.
:WriteFileEntry		lda	TargetDrive		;Ziel-Laufwerk öffnen und BAM einleseen.
			jsr	SetDevice
			jsr	GetDirHead

			LoadB	r10L,$00		;Leeren Verzeichnis-Eintrag suchen.
			jsr	GetFreeDirBlk
			txa
			beq	:102
::101			jmp	ExitDiskErr

::102			ldx	#$00			;Verzeichniseintrag kopieren.
::103			lda	dirEntryBuf,x
			sta	diskBlkBuf,y
			iny
			inx
			cpx	#$1e
			bne	:103

			jsr	PutBlock		;Verzeichnis-Sektor zurück auf Disk schreiben.
			txa				;Diskettenfehler?
			bne	:101			;Ja, Abbruch...

			jsr	ClrScreen		;Bildschirm löschen und
			LoadW	mouseXPos,$005c		;zurück zum Dateiauswahl-menü um
			LoadB	mouseYPos,$16		;weitere Dateien zu entpacken.
			jmp	ReDoMenu

;*** Sektorkette kopieren.
:CopyD64SeqChain	sta	a3L			;Ersten Sektor merken.
			stx	a3H

			ldx	#$00
			stx	dirEntryBuf +$01	;Ersten Sektor Zieldaten
			stx	dirEntryBuf +$02	;löschen.

:RdD64SeqChain		lda	SourceDrive		;Quell-Laufwerk aktivieren.
			jsr	SetDevice
			jsr	EnterTurbo		;GEOS-Turbo aktivieren.
			jsr	InitForIO

			LoadW	r15,DataSekBufStart	;Zeiger auf Zwischenspeicher.

			lda	#DataSekBufMax		;Zähler für gelesene Sektoren
			sta	a5L			;löschen (max. 32 Sektoren!)
			sta	a5H
::102			ldx	a3L			;Zeiger auf Sektor in D64-
			lda	a3H			;Datei berechnen und Sektor
			jsr	PosToSektor		;in Zwischenspeicher lesen.
			jsr	GetSektor
			dec	a5L			;Sektoren in Speicher +1.

			ldy	#$01			;Zeiger auf nächsten Sektor
			lda	(r15L),y		;einlesen und merken.
			sta	a3H
			dey
			lda	(r15L),y
			sta	a3L
			beq	:103
			inc	r15H			;Zeiger auf Zwischenspeicher.
			lda	a5L
			bne	:102

::103			jsr	DoneWithIO
			CmpBI	a5L,DataSekBufMax	;Daten im Speicher ?
			bne	SaveSeqChain		;Ja, weiter...
			rts				;Ende...

;*** Daten auf Zieldatei schreiben.
:SaveSeqChain		lda	TargetDrive		;Ziel-Laufwerk aktivieren.
			jsr	SetDevice
			jsr	NewOpenDisk
			txa
			bne	:101

			LoadW	a6 ,DataSekBufStart	;Zeiger auf Zwischenspeicher.

			lda	dirEntryBuf +$01	;Erster Sektor definiert ?
			bne	:103			;Ja, weiter...
			MoveB	a4L,r3L			;Ersten Sektor für Sektorkette
			MoveB	a4H,r3H			;ermitteln und merken.
			jsr	SetNextFree
			txa
			beq	:102
::101			jmp	ExitDiskErr

::102			lda	r3L
			ldx	r3H
			sta	a4L
			stx	a4H
			sta	a7L
			stx	a7H
			sta	dirEntryBuf +$01
			stx	dirEntryBuf +$02

::103			ldy	#$00
			lda	(a6L),y			;Folgt weiterer Sektor ?
			beq	:104			;Nein, weiter...

			MoveB	a4L,r3L			;Nächsten Sektor belegen.
			MoveB	a4H,r3H
			jsr	SetNextFree
			txa
			bne	:101

			ldy	#$00
			lda	r3L			;Verkettungszeiger für
			sta	a4L			;Sektorkette aktualisieren.
			sta	(a6L),y
			iny
			lda	r3H
			sta	a4H
			sta	(a6L),y

::104			MoveB	a7L,r1L			;Aktuellen Sektor schreiben.
			MoveB	a7H,r1H
			MoveW	a6 ,r4
			jsr	PutBlock
			txa
			bne	:106
			dec	a5H

			ldy	#$00			;Zeiger auf nächsten Sektor.
			lda	(a6L),y			;Sektor vorhanden ?
			beq	:105			;Nein, Ende...
			sta	a7L
			iny
			lda	(a6L),y
			sta	a7H

			inc	a6H
			lda	a5H			;Zwischenspeicher kopiert ?
			bne	:103			;Nein, weiter...
			jsr	PutDirHead		;BAM aktualsieren.
			txa
			bne	:106
			jmp	RdD64SeqChain		;Daten weiterlesen.

::105			jsr	PutDirHead		;Sektorkette kopiert.
			txa
			beq	:107
::106			jmp	ExitDiskErr
::107			rts

;*** Variablen.
:OrgFileEntry		s 30
:NewVlirHdrSek		b $00,$00
:NewVlirHeader		s 256
:VecNewVlirHdr		b $00
:ExtractFileName	s 17

if Sprache = Deutsch
:Text_FileName		b PLAINTEXT,BOLDON
			b GOTOXY
			w $0048
			b $58
			b "Datei"
			b GOTOX
			w $0078
			b ": "
			b NULL

:Text_FStructInfo	b GOTOXY
			w $0048
			b $66
			b "Format"
			b GOTOX
			w $0078
			b ": "
			b NULL

:Text_FSize		b GOTOXY
			w $0048
			b $74
			b "Größe"
			b GOTOX
			w $0078
			b ": "
			b NULL
:Text_FSizeBlk		b " Blöcke"
			b NULL

:Text_FStructSEQ	b "Sequentiell",NULL
:Text_FStructGEOS	b "GEOS-Sequentiell",NULL
:Text_FStructVLIR	b "GEOS-VLIR",NULL
endif
if Sprache = Englisch
:Text_FileName		b PLAINTEXT,BOLDON
			b GOTOXY
			w $0048
			b $58
			b "File"
			b GOTOX
			w $0078
			b ": "
			b NULL

:Text_FStructInfo	b GOTOXY
			w $0048
			b $66
			b "Format"
			b GOTOX
			w $0078
			b ": "
			b NULL

:Text_FSize		b GOTOXY
			w $0048
			b $74
			b "Size"
			b GOTOX
			w $0078
			b ": "
			b NULL
:Text_FSizeBlk		b " blocks",NULL

:Text_FStructSEQ	b "Sequential",NULL
:Text_FStructGEOS	b "GEOS-Sequential",NULL
:Text_FStructVLIR	b "GEOS-VLIR",NULL
endif

;*** Prüfen ob Datenspeicher bereits von Programmcode belegt.
			g DataSekBufStart
