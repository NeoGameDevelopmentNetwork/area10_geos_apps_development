; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;geoConvert
;Hauptprogramm

if .p
			t "TopSym"
			t "TopMac"
			t "sys.Release"
endif

			o $0400
			p MainInit
			a "Markus Kanet"
			n "mod.#0"
			f APPLICATION
			z $00
			t "icon.Header"

;*** Systemvariablen.
if .p

;Zusätzliche Systemadressen aus MegaSym für cvt.FileConvert
.sysFreeBlock		= $9844

;Laufwerkstypen
.DRV_1541		= $01
.DRV_1571		= $02
.DRV_1581		= $03

;Beginn Datenpuffer für Kopiervorgänge.
.DataSekBufStart	= BACK_SCR_BASE
;Max. Anzahl an Datenpuffer = 32*256 = $6000-$7FFF
.DataSekBufMax		= 32

;Max. Anzahl an Dateieinträgen in Dateiauswahlmenü.
.MaxFileEntry		= 14

;Konvertierungsmodi.
.ConvMode_GEOS_CBM	= $01
.ConvMode_CBM_GEOS	= $02
.ConvMode_SEQ_UUE	= $03
.ConvMode_SEQ_UUEadd	= $04
.ConvMode_UUE_SEQ	= $05
.ConvMode_DISK_D64	= $06
.ConvMode_D64_DISK	= $07
.ConvMode_D64_FILE	= $08
.ConvMode_D64_FILE_SAVE	= $09
.ConvMode_SPLIT_FILE	= $0a
.ConvMode_MERGE_FILE	= $0b
.ConvMode_DISK_D81	= $0c
.ConvMode_D81_DISK	= $0d
.ConvMode_D81_FILE	= $0e
.ConvMode_D81_FILE_SAVE	= $0f
.ConvMode_CVT_ALL_FILES	= $10
.ConvMode_D71_DISK	= $11
.ConvMode_D71_FILE	= $12
.ConvMode_D71_FILE_SAVE	= $13
.ConvMode_DISK_D71	= $14
endif

;*** MegaAssembler-Informationen.
.NameGConv		s 17
if Sprache = Deutsch
.ClassGConv		b "geoConv DE  "
endif
if Sprache = Englisch
.ClassGConv		b "geoConv EN  "
endif
			b "V"
			b VMajor
			b "."
			b VMinor
			b NULL
.BootDrive		b $00
.VLIRModule		b $00

;*** Programm initialisieren.
:MainInit		tsx				;Stack-Pointer retten.
			stx	StackPointer

			jsr	ClrScreen		;Bildschirm löschen.

			jsr	MouseUp			;Mauszeiger aktivieren.

			lda	curDrive		;Aktuelles Laufwerk als
			sta	SourceDrive		;Vorgabe für Quell/Ziel.
			sta	TargetDrive
			sta	BootDrive		;Startlaufwerk mit geoConvert merken.

			jsr	i_FillRam		;Erlaubte Dateitypen für
			w	32			;'GEOS->CBM' Menü zurücksetzen.
			w	GEOSValidTypeList
			b	$00
			lda	#$ff			;GEOS->CBM: CBM Dateien ausblenden.
			sta	GEOSValidTypeList+1

			jsr	LoadParameter		;Gespeicherte Parameter aus Infoblock
							;laden, sofern vorhanden.

.ResetMenu		lda	#$00			;Zeiger auf ersten Eintrag in Dateilisten-Menü.
			b $2c
.OpenMain		lda	#$01			;Standardmenü  aufrufen.
			b $2c
.StartMenu		lda	#$02			;Dateilisten-Menü  aufrufen.
			sta	MenuJob			;Menü-Funktion speichern.
			jmp	Mod_MainMenu		;Hauptmenü-Modul nachladen.

;*** Zurück zum DeskTop.
.ExitToDeskTop		jsr	GotoFirstMenu		;Zurück zum Hauptmenü.

			lda	#8			;Laufwerk 8 aktivieren.
			jsr	SetDevice		;(Falls DeskTop nur auf A/B)
			jmp	EnterDeskTop		;Zurück zum DeskTop.

;*** Standard-Mausposition festlegen.
.SetStdMsePos		LoadB	mouseYPos,$05
			LoadW	mouseXPos,$0009
			ldx	StackPointer
			txa
			rts

;*** geoConvert auf Diskette suchen.
.FindGConv		lda	BootDrive		;Start-Laufwerk aktivieren.
			jsr	NewSetDevice
			jsr	NewOpenDisk		;Diskette öffnen.
			txa				;Fehler?
			bne	:102			;Ja, Abbruch...

			LoadW	r6 ,NameGConv		;geoConvert über die
			LoadB	r7L,APPLICATION		;GEOS-Klasse suchen.
			LoadB	r7H,1
			LoadW	r10,ClassGConv
			jsr	FindFTypes
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch.
			lda	r7H			;Datei gefunden ?
			bne	:101			;Nein, Fehler.
			LoadW	r6,NameGConv		;Verzeichnis-Eintrag einlesen.
			jmp	FindFile
::101			ldx	#$05			;"geoConvert nicht gefunden".
::102			rts

;*** Ausgewählte Datei suchen.
.FindSlctFile		lda	SourceDrive		;Quell-Laufwerk aktivieren.
			jsr	SetDevice
			jsr	NewOpenDisk
			LoadW	r6,CurFileName		;Zeiger auf ausgewählte Datei.
			jmp	FindFile		;Verzeichnis-Eintrag einlesen.

;*** Neue OpenDisk-Routine.
.NewOpenDisk		jsr	NewDisk
			txa
			bne	:101

			jsr	GetDirHead
			txa
			bne	:101

			jsr	ChkDkGEOS

			ldx	#r1L
			jsr	GetPtrCurDkNm
			LoadW	r0,curDirHead +$90
			ldx	#r0L
			ldy	#r1L
			lda	#16
			jsr	CopyFString

			ldx	#$00
::101			rts

;*** Neue SetDevice-Routine.
.NewSetDevice		cmp	curDrive
			beq	:1
			jmp	SetDevice
::1			ldx	#$00
			rts

;*** Gespeicherte Parameter aus Infoblock laden.
.LoadParameter		jsr	FindGConv		;geoConvert suchen.
			txa				;Gefunden?
			beq	:102
::101			rts

::102			lda	dirEntryBuf +19		;Zeiger auf Infoblock einlesen.
			sta	r1L
			lda	dirEntryBuf +20
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Infoblock einlesen.
			txa				;Diskettenfehler?
			bne	:101			;Ja, Abbruch...

			ldx	#$07			;Systemkennung prüfen.
			lda	diskBlkBuf +$89		;X-Reg=$07 Fehler für "Keine gespeicherten Parameter".
			cmp	#VMajor
			bne	:101
			lda	diskBlkBuf +$8a
			cmp	#VMinor
			bne	:101

			lda	diskBlkBuf +$8b		;Quell-Laufwwerk einlesen.
			sta	SourceDrive
			lda	diskBlkBuf +$8c		;Ziel-Laufwerk einlesen.
			sta	TargetDrive

			lda	diskBlkBuf +$8d		;UUE-Modus einlesen.
			sta	Option_ConvFileToUUE
			lda	diskBlkBuf +$8e		;LF-Modus einlesen.
			sta	Option_LineFeedMode
			lda	diskBlkBuf +$8f		;CBM-Dateityp PRG/SEQ einlesen.
			sta	Option_CBMFileType
			lda	diskBlkBuf +$90		;Max. Dateigröße SEQ-aufteilen.
			sta	Option_SEQ_MaxSize

			lda	#<diskBlkBuf +$91	;GEOS-Klassen für GEOS->CBM einlesen.
			sta	r2L			;Aus Platzgründen werden 8 Bytes in 8 Bit gespeichert.
			lda	#>diskBlkBuf +$91
			sta	r2H
			LoadW	r3,GEOSValidTypeList

			ldx	#$00
::103			LoadB	r4L,8
			ldy	#$00
			lda	(r2L),y
::104			tay
			lda	#$00
			sta	GEOSValidTypeList,x
			tya
			lsr
			bcs	:105
			dec	GEOSValidTypeList,x
::105			inx
			dec	r4L
			bne	:104
			inc	r2L
			bne	:106
			inc	r2H
::106			cpx	#32
			bne	:103
			ldx	#$00
			rts

;*** Konvertierungsroutinen aus VLIR-Modulen nachladen..
.Mod_DskImg_File	lda	#$01			;Modul #1: d64.ExtractFile
			b $2c
.Mod_DskImg_Disk	lda	#$02			;Modul #2: d64.ExtractDisk
			b $2c
.Mod_DskImg_Create	lda	#$03			;Modul #3: d64.CreateImage
			b $2c
.Mod_Convert_CVT	lda	#$04			;Modul #4: cvt.ConvertFile
			b $2c
.Mod_Convert_UUE	lda	#$05			;Modul #5: uue.ConvertFile
			b $2c
.Mod_Convert_SEQ	lda	#$06			;Modul #6: seq.ConvertFile
			b $2c
.Mod_MainMenu		lda	#$07			;Modul #8: Hauptmenü
			cmp	VLIRModule
			beq	:4
			sta	VLIRModule
			jsr	FindGConv		;geoConvert suchen.
			txa				;OK?
			beq	:3			;Ja, weiter...
::2			jmp	ExitDiskErr		;Nicht gefunden, Fehler.

::3			lda	dirEntryBuf +1		;Zeiger auf VLIR-Header einelsen.
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r4,fileHeader
			jsr	GetBlock
			txa
			bne	:2

			lda	VLIRModule		;Zeiger auf VLIR-Modul einlesen.
			asl
			tax
			lda	fileHeader +2,x
			sta	r1L
			lda	fileHeader +3,x
			sta	r1H
			LoadW	r2,BACK_SCR_BASE - VLIR_BASE
			LoadW	r7,VLIR_BASE
			jsr	ReadFile		;Programmteil einlesen.
			txa				;Diiskettenfehler?
			bne	:2			;JA, Abbbruch.

::4			lda	#$00
			sta	r0L			;Flag-Byte für StartAppl löschen.
			lda	#<VLIR_BASE		;Programm-Startadresse festlegen.
			sta	r7L
			lda	#>VLIR_BASE
			sta	r7H
			jmp	StartAppl		;Modul starten.

;*** Texthinweise ausgeben:
.TextInfo_ConvertData	jsr	ClearTextBackground	;Bildschirmbereich löschen.
			jsr	i_PutString
			w	$0010
			b	$c2
			b	PLAINTEXT
if Sprache = Deutsch
			b	" Daten werden konvertiert... "
endif
if Sprache = Englisch
			b	" Converting data... "
endif
			b	NULL
			rts

.TextInfo_CreateDImg	jsr	ClearTextBackground	;Bildschirmbereich löschen.
			jsr	i_PutString
			w	$0010
			b	$c2
			b	PLAINTEXT
if Sprache = Deutsch
			b	" Abbild-Datei wird erzeugt... "
endif
if Sprache = Englisch
			b	" Creating disk image... "
endif
			b	NULL
			rts

.TextInfo_ExtractDImg	jsr	ClearTextBackground	;Bildschirmbereich löschen.
			jsr	i_PutString
			w	$0010
			b	$c2
			b	PLAINTEXT
if Sprache = Deutsch
			b	" Abbild-Datei auf Disk schreiben... "
endif
if Sprache = Englisch
			b	" Writing image to disk... "
endif
			b	NULL
			rts

.TextInfo_ExtractDImgF	jsr	ClearTextBackground	;Bildschirmbereich löschen.
			jsr	i_PutString
			w	$0010
			b	$c2
			b	PLAINTEXT
if Sprache = Deutsch
			b	" Datei entpacken... "
endif
if Sprache = Englisch
			b	" Extracting file... "
endif
			b	NULL
			rts
.TextInfo_ReadData	jsr	ClearTextBackground	;Bildschirmbereich löschen.
			jsr	i_PutString
			w	$0010
			b	$c2
			b	PLAINTEXT
if Sprache = Deutsch
			b	" Daten werden eingelesen... "
endif
if Sprache = Englisch
			b	" Reading data... "
endif
			b	NULL
			rts

.TextInfo_DelOldFile	jsr	ClearTextBackground	;Bildschirmbereich löschen.
			jsr	i_PutString
			w	$0010
			b	$c2
			b	PLAINTEXT
if Sprache = Deutsch
			b	" Lösche existierende Ziel-Datei... "
endif
if Sprache = Englisch
			b	" Deleting existing target file.. "
endif
			b	NULL
			rts

;*** Bildschirm löschen.
.ClrScreen		LoadB	dispBufferOn,ST_WR_FORE ! ST_WR_BACK
			lda	#$02
			jsr	SetPattern
			jsr	i_Rectangle
			b	0,199
			w	0
			w	319
			rts

;*** Anzeigebereich für Statusmeldungen löschen.
.ResetScreenBackground	lda	#$02			;Hintergrundmuster wieder herstellen.
			b $2c
.ClearTextBackground	lda	#$09			;Bildschirmbereich löschen.
			jsr	SetPattern		;Füllmuster setzen.
			jsr	i_Rectangle		;Rechteck-Bereich mit Muster füllen.
			b	184,199
			w	0
			w	319
			rts

;*** Text für Diskettenfehler definieren.
;    X: Fehlermeldung.
.GetTxtDiskErr		cpx	#$20			;Fehler >= 32?
			bcs	:101			;Ja, weiter...
			cpx	#$10			;Fehler 16-31 sind nicht definiert.
			bcs	:103			;"Unbekannter Befehl" ausgeben.
			dex
			txa
			asl
			tay
			lda	ErrTxtVecTab1 +0,y
			sta	r5L
			lda	ErrTxtVecTab1 +1,y
			sta	r5H
			bne	ErrDiskError

::101			cpx	#$73			;Fehler $73 "Falsche DOS Version"?
			bne	:102			;Nein, weiter...
			LoadW	r5,ErrText19
			bne	ErrDiskError

::102			cpx	#$2f
			bcc	:104
::103			LoadW	r5,ErrText20		;Fehler "Unbekannter Befehl"
			bne	ErrDiskError

::104			txa
			sbc	#$1f
			asl
			tay
			lda	ErrTxtVecTab2 +0,y
			sta	r5L
			lda	ErrTxtVecTab2 +1,y
			sta	r5H
			bne	ErrDiskError

;*** Neue Diskette einlegen.
.DialogBoxNewDisk	LoadW	r5,InsDiskText

;*** Diskettenfehler anzeigen.
.ErrDiskError		lda	curDrive
			add	$39
			sta	DlgDskErrDrvTa

			LoadW	r0,DlgDiskError
			LoadW	r6,CurFileName
			LoadB	mouseYPos,$45
			LoadW	mouseXPos,$00f3		;Mauszeiger setzen.
			jsr	DoDlgBox
			jmp	StartMenu

;*** Diskettenfehler ausgeben.
;    X: Fehlermeldung.
.ExitDiskErr		jsr	GetTxtDiskErr
			jmp	SetStdMsePos

;*** Fehlermeldungen im Klartext.
if Sprache = Deutsch
:ErrText01		b BOLDON,"Diskette voll!"								,PLAINTEXT,NULL
:ErrText02		b BOLDON,"Spurnummer ungültig!"								,PLAINTEXT,NULL
:ErrText03		b BOLDON,"Diskette voll!"								,PLAINTEXT,NULL
:ErrText04		b BOLDON,"Verzeichnis voll!"								,PLAINTEXT,NULL
:ErrText05		b BOLDON,"Datei nicht gefunden!"							,PLAINTEXT,NULL
:ErrText06		b BOLDON,"BAM fehlerhaft!"								,PLAINTEXT,NULL
:ErrText07		b BOLDON,"Falsche Dateistruktur!"							,PLAINTEXT,NULL
:ErrText08		b BOLDON,"Datenpuffer voll!"								,PLAINTEXT,NULL
:ErrText09		b BOLDON,"Gerät nicht vorhanden!"							,PLAINTEXT,NULL
:ErrText10		b BOLDON,"Verzeichnis voll!"								,PLAINTEXT,NULL
:ErrText11		b BOLDON,"Header-Block fehlt!"								,PLAINTEXT,NULL
:ErrText12		b BOLDON,"Unformatierte Diskette!"							,PLAINTEXT,NULL
:ErrText13		b BOLDON,"Daten-Block fehlt!"								,PLAINTEXT,NULL
:ErrText14		b BOLDON,"Daten-Prüfsummenfehler!"							,PLAINTEXT,NULL
:ErrText15		b BOLDON,"Fehler beim schreiben!"							,PLAINTEXT,NULL
:ErrText16		b BOLDON,"Schreibschutz aktiv!"								,PLAINTEXT,NULL
:ErrText17		b BOLDON,"Header-Prüfsummenfehler!"							,PLAINTEXT,NULL
:ErrText18		b BOLDON,"Falsche Disketten-ID!"							,PLAINTEXT,NULL
:ErrText19		b BOLDON,"Falsche DOS-Version!"								,PLAINTEXT,NULL
:ErrText20		b BOLDON,"Unbekannter Befehl!"								,PLAINTEXT,NULL
:ErrText21		b BOLDON,"Byte-Dekodierungsfehler!"							,PLAINTEXT,NULL
:ErrText22		b BOLDON,"Keine Parameter gespeichert!"							,PLAINTEXT,NULL
:InsDiskText		b BOLDON,"Bitte neue Diskette einlegen!"						,PLAINTEXT,NULL
endif
if Sprache = Englisch
:ErrText01		b BOLDON,"Disk full!"									,PLAINTEXT,NULL
:ErrText02		b BOLDON,"Illegal block-address!"							,PLAINTEXT,NULL
:ErrText03		b BOLDON,"Disk full!"									,PLAINTEXT,NULL
:ErrText04		b BOLDON,"Directory full!"								,PLAINTEXT,NULL
:ErrText05		b BOLDON,"File not found!"								,PLAINTEXT,NULL
:ErrText06		b BOLDON,"Illegal BAM!"									,PLAINTEXT,NULL
:ErrText07		b BOLDON,"Wrong filestructure!"								,PLAINTEXT,NULL
:ErrText08		b BOLDON,"Databuffer full!"								,PLAINTEXT,NULL
:ErrText09		b BOLDON,"Device not present!"								,PLAINTEXT,NULL
:ErrText10		b BOLDON,"Directory full!"								,PLAINTEXT,NULL
:ErrText11		b BOLDON,"Missing header-block!"							,PLAINTEXT,NULL
:ErrText12		b BOLDON,"Unformatted disk!"								,PLAINTEXT,NULL
:ErrText13		b BOLDON,"Missing data-block!"								,PLAINTEXT,NULL
:ErrText14		b BOLDON,"CRC-error!"									,PLAINTEXT,NULL
:ErrText15		b BOLDON,"Write-error!"									,PLAINTEXT,NULL
:ErrText16		b BOLDON,"Write protected disk!"							,PLAINTEXT,NULL
:ErrText17		b BOLDON,"Header-CRC-error!"								,PLAINTEXT,NULL
:ErrText18		b BOLDON,"Wrong disk-ID!"								,PLAINTEXT,NULL
:ErrText19		b BOLDON,"Wrong DOS-version!"								,PLAINTEXT,NULL
:ErrText20		b BOLDON,"Unknown command!"								,PLAINTEXT,NULL
:ErrText21		b BOLDON,"Byte decode error!"								,PLAINTEXT,NULL
:ErrText22		b BOLDON,"No saved options!"								,PLAINTEXT,NULL
:InsDiskText		b BOLDON,"Insert new disk!"								,PLAINTEXT,NULL
endif

:ErrTxtVecTab1		w ErrText01,ErrText02
			w ErrText03,ErrText04
			w ErrText05,ErrText06
			w ErrText22,ErrText20
			w ErrText20,ErrText07
			w ErrText08,ErrText20
			w ErrText09,ErrText10

:ErrTxtVecTab2		w ErrText11,ErrText12
			w ErrText13,ErrText14
			w ErrText20,ErrText15
			w ErrText16,ErrText17
			w ErrText20,ErrText18
			w ErrText20,ErrText20
			w ErrText20,ErrText20
			w ErrText21,ErrText20

;*** Dialobox für Diskettenfehler.
:DlgDiskError		b $01
			b $20,$5f
			w $0040,$00ff
			b DBVARSTR    ,$10,$0f
			b r5L
			b DBVARSTR    ,$10,$1e
			b r6L
			b DBTXTSTR    ,$10,$32
			w DlgDskErrDrvT
			b OK          ,$11,$28
			b NULL

if Sprache = Deutsch
:DlgDskErrDrvT		b BOLDON,"(Laufwerk "
:DlgDskErrDrvTa		b "x:)",NULL
endif
if Sprache = Englisch
:DlgDskErrDrvT		b BOLDON,"(Drive "
:DlgDskErrDrvTa		b "x:)",NULL
endif

;*** Unterprogramme und Menüs.
			t "inc.SelectFile"
			t "inc.DefNameDOS"
			t "inc.ToolsDImg"
			t "inc.ToolsSEQ"

;*** Variablen.
:StackPointer		b $00
.curMenu		w $0000
.MenuJob		b $00
.MaxGEOSFileTypes	= 20
.GEOSValidTypeList	s 32				;Liste der erlaubten GEOS-Typen.

;*** Systemvariablen der Sub-Routinen die über
;    das Menü geändert werden können.
.Option_ConvFileToUUE	b $00
.Option_LineFeedMode	b $02
.Option_CBMFileType	b $82				;Dateityp PRG.
.Option_SEQ_MaxSize	b $0f				;Wert in KBytes.
.Option_SEQ_InputBuf	s $04
.Option_SEQ_Merge	b $00

;*** Systemvariablen die über Sub-Routinen
;    verändert werden.
.SourceDrive		b $08
.TargetDrive		b $08

.CurFileName		s 17
.CurSektor		b $00,$00

.CurFNameEntryInMenu	b $00
.FilesOnDisk		b $00
.MaxFilesOnDsk		b $00

;*** Zwischenspeicher für Verzeichniseinträge.
;1541: max. 144 Dateien   * 32 Bytes.
;1571: max. 144 Dateien   * 32 Bytes.
;1581: max. 296 Dateien   * 32 Bytes.
;      Verzeichnis auf max. 144 Dateien beschränken
;      (Speicherplatz).
.DskImgMaxDirFiles	= 144
.DskImgDirData		s DskImgMaxDirFiles*32

;*** Beginn VLIR-Module.
.VLIR_BASE

;*** Prüfen ob Datenspeicher bereits von Programmcode belegt.
			g DataSekBufStart
