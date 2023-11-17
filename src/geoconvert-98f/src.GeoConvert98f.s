; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;


if .p
			t "TopSym"
			t "TopMac"
			t "Sym128.erg"

:DRIVE			= $10
:DRV_1541		= $01
:DRV_1571		= $02
:CBM_PRG		= $82
:CBM_SEQ		= $81
:sysFreeBlock		= $9844
:sysGet1stDirEntry	= $c9f7
:MaxFileEntry		= 14
:MaxFileTypes		= 20

:Deutsch		= 0
:Englisch		= 1
:Sprache		= Englisch

endif

if Sprache = Deutsch
			o $0400
			p MainInit
			a "Markus Kanet"
			n "GeoConvert D98f"
			c "GeoConvert D98.f"
			f APPLICATION
			z $40
			h "Konvertiert GEOS nach SEQ, unterstützt Dateien mit max. 16Mb Größe!"
endif

if Sprache = Englisch
			o $0400
			p MainInit
			a "Markus Kanet"
			n "GeoConvert E98f"
			c "GeoConvert E98.f"
			f APPLICATION
			z $40
			h "Convert files from GEOS to CBM, maximum filesize supported is about 16Mb!"
endif

			i


;*** Programm initialisieren.
:MainInit		tsx				;Stack-Pointer retten.
			stx	StackPointer

			jsr	TestC128		;80Zeichen-Modus C128 testen

			jsr	ClrScreen		;Bildschirm löschen.

			jsr	MouseUp			;Mauszeiger aktivieren.

			lda	curDrive		;Aktuelles Laufwerk als
			sta	SourceDrive		;Vorgabe für Quell/Ziel.
			sta	TargetDrive

			jsr	i_FillRam		;Erlaubte Dateitypen für
			w	32 +1			;Datei-Menü zurücksetzen.
			w	GeosAllTypes
			b	$ff

			jsr	SetMenuData		;Menüanzeige aktualisieren.

			ldy	#$00
			ldx	#$00			;Laufwerksauswahl
::102			lda	#DBUSRICON		;initialisieren. Nicht
			sta	DlgDrv1b   ,x		;installierte Laufwerk nicht
			lda	driveType  ,y		;zur Auswahl anbieten.
			bne	:103
			lda	#NULL
			sta	DlgDrv1b   ,x
::103			inx
			inx
			inx
			inx
			inx
			iny
			cpy	#$04
			bne	:102

;*** Hauptmenü & Dateiauswahl initialisieren.
:ResetMenü		lda	#$00			;Zeiger auf Tabellenanfang
			sta	Poi_1stEntryInTab	;für Dateiliste.

;*** Hauptmenü aktivieren.
:OpenMain		lda	#$00			;Modus "Dateien zusammenfügen"
			sta	SEQ_ModeOpen		;zurücksetzen.
			LoadW	curMenu,Menu_Main	;Zeiger auf Hauptmenü.
			jmp	StartStdMenü		;Hauptmenü öffnen.

;*** Dateimenü aktivieren.
:OpenFiles		LoadW	curMenu,Menu_Files	;Zeiger auf Datei-Menü.

;*** Menü aktivieren.
:StartMenü		jsr	GetMenuEntrysTxt	;Dateien einlesen.
:StartStdMenü		jsr	ClrScreen		;Bildschirm löschen.

			MoveW	curMenu,r0		;Menü aufrufen.
			lda	#$01
			jsr	DoMenu

;*** Standard-Mausposition festlegen.
:SetStdMsePos		LoadB	mouseYPos,$05
			LoadW	mouseXPos,$0009
			ldx	StackPointer
			txa
			rts

;*** Zurück zum DeskTop.
:ExitToDeskTop		jsr	GotoFirstMenu		;Zurück zum Hauptmenü.

			lda	#$08			;Laufwerk 8 aktivieren.
			jsr	SetDevice		;(Falls DeskTop nur auf A/B)
			jmp	EnterDeskTop		;Zurück zum DeskTop.

;*** Info ausgeben.
:PrintInfoBox		jsr	GotoFirstMenu		;Zurück zum Hauptmenü.

			LoadW	r0,DlgInfoBox
			jmp	DoDlgBox		;Infobox ausgeben.

;*** Konvertierungsmodus wählen.
:SetMode1		lda	#$01			;GEOS => CBM
			b $2c
:SetMode2		lda	#$02			;CBM => GEOS
			b $2c
:SetMode3		lda	#$03			;SEQ => UUE
			b $2c
:SetMode4		lda	#$04			;SEQ an UUE anhängen
			b $2c
:SetMode5		lda	#$05			;UUE nach SEQ
			b $2c
:SetMode6		lda	#$06			;Disk => D64
			b $2c
:SetMode7		lda	#$07			;D64 => Disk
			b $2c
:SetMode8		lda	#$08			;D64 => Datei
			b $2c
:SetMode9		lda	#$0a			;Dateien aufteilen
			b $2c
:SetMode10		lda	#$0b			;Dateien zusammenfügen
			sta	FileConvMode		;Konvertierungsmodus merken.

			jsr	GotoFirstMenu		;Zurück zum Hauptmenü.
			jsr	ClrScreen		;Bildschirm löschen.

			lda	#$00			;Zeiger auf ersten Eintrag in
			sta	Poi_1stEntryInTab	;Datei-Menü richten.
			jmp	OpenFiles		;Datei-Menü aktivieren.

;*** GEOS-Dateityp wählen.
:SlctGeosFileType	jsr	GotoFirstMenu		;Zurück zum Hauptmenü.
			jsr	ClrScreen		;Bildschirm löschen.
			LoadW	r0,DlgGeosType
			jsr	DoDlgBox		;GEOS-Dateitypen auswählen.
			jmp	ResetMenü		;Hauptmenü aktivieren.

;*** CBM-Dateityp wählen.
:SlctCBM_FileType	jsr	RecoverMenu		;Menü löschen.
			LoadW	r0,DlgCBM_Type
			jsr	DoDlgBox		;CBM-Dateityp auswählen.
			LoadB	mouseYPos,$24
			LoadW	mouseXPos,$0080		;Mauszeiger setzen.
			jmp	ReDoMenu		;Parameter-Menü aktivieren.

;*** Datei-Format wählen..
:SlctFileTypCBM		lda	#CBM_SEQ		;Zieldatei-Format SEQ.
			b $2c
:SlctFileTypPRG		lda	#CBM_PRG		;Zieldatei-Format PRG.
			sta	CBM_FileType
			jsr	SetMenuData		;Menüanzeige aktualisieren.
			jmp	RstrFrmDialogue

;*** Laufwerk wählen.
:SourceDriveA		lda	#$08			;Quell-Laufwerk A:
			b $2c
:SourceDriveB		lda	#$09			;Quell-Laufwerk B:
			b $2c
:SourceDriveC		lda	#$0a			;Quell-Laufwerk C:
			b $2c
:SourceDriveD		lda	#$0b			;Quell-Laufwerk D:
			sta	SourceDrive		;Quell-Laufwerk merken.
			jsr	DefMenuEntrysTxt	;Dateien einlesen.
			jsr	SetMenuData		;Menüanzeige aktualisieren.
			LoadB	mouseYPos,$32
			LoadW	mouseXPos,$0080		;Mauszeiger setzen.
			jmp	DoPreviousMenu

;*** Ziel-Laufwerk auswählen..
:TargetDriveA		lda	#$88			;Ziel-Laufwerk A:
			b $2c
:TargetDriveB		lda	#$89			;Ziel-Laufwerk B:
			b $2c
:TargetDriveC		lda	#$8a			;Ziel-Laufwerk C:
			b $2c
:TargetDriveD		lda	#$8b			;Ziel-Laufwerk D:
			sta	sysDBData
			jmp	RstrFrmDialogue

;*** Neue Diskette einlegen.
:InsertNewDisk		jsr	GotoFirstMenu		;Zurück zum Hauptmenü.
			lda	SourceDrive
			jsr	SetDevice		;Quell-Laufwerk aktivieren.
			LoadW	r5,InsDiskText
			jsr	ErrDiskError		;Neue Diskette einlegen.
			jmp	DefMenuEntrysTxt	;Dateien einlesen.

;*** Linefeed-Modus wählen.
:ConvToUUE_CR		lda	#$01			;LineFeed "CR"
			b $2c
:ConvToUUE_CRLF		lda	#$02			;LineFeed "CR+LF"
			b $2c
:ConvToUUE_LF		lda	#$03			;LineFeed "LF"
			sta	LineFeedMode
			jsr	SetMenuData		;Menüanzeige aktualisieren.
			LoadB	mouseYPos,$5c
			LoadW	mouseXPos,$0080		;Mauszeiger setzen.
			jmp	DoPreviousMenu		;Zurück zum Parameter-Menü.

;*** Textmodus für UUE wechseln (Texte/Programme).
;    je nach Modus werden angehängte Dateien UUE kodiert (Programme)
;    oder nicht kodiert (Texte).
:SwapTextMode		lda	Flag_Text_File
			eor	#$ff
			sta	Flag_Text_File
			jsr	ShowTextMode
			jmp	ReDoMenu

;*** Aktuellen Textmodus anzeigen.
:ShowTextMode		ldx	#<Parameter07a		;Texte.
			ldy	#>Parameter07a
			lda	Flag_Text_File
			bne	:101
			ldx	#<Parameter07b		;Programme.
			ldy	#>Parameter07b
::101			stx	r0L
			sty	r0H
			LoadW	r1,Parameter07 +5
			ldx	#r0L
			ldy	#r1L
			jmp	CopyString

;*** Max. Dateigröße für SEQ-Dateien (trennen) eingeben.
:GetMaxSize		jsr	RecoverMenu		;Menü löschen.

			jsr	GetMaxSizeASCII		;Max. Größe nach ASCII wandeln.

			cpy	#"0"			;ASCII-Wert für Max. Größe
			beq	:104			;in Eingabespeicher kopieren.
			sty	InputBuf1
			ldy	#"1"
			bne	:104a
::104			cpx	#"0"
			beq	:105
::104a			pha
			txa
			sta	InputBuf1 -$30,y
			pla
			iny
::105			sta	InputBuf1 -$30,y
			iny
			lda	#$00
			sta	InputBuf1 -$30,y

			LoadW	r0,DlgGetMaxSize
			LoadW	r5,InputBuf1
			jsr	DoDlgBox		;Dateigröße eingeben.

			lda	InputBuf1 +0		;Wurde Text eingegeben ?
			beq	:111			;Nein, abbruch...

::106			ldx	#$00			;ASCII-Texteingabe nach
			ldy	InputBuf1 +1		;Dezimalwert umwandeln.
			beq	:107
			tax
			tya
			ldy	InputBuf1 +2
			beq	:107
			pha
			txa
			tay
			pla
			tax
			lda	InputBuf1 +2
::107			sec
			sbc	#$30
::108			cpx	#$31
			bcc	:109
			clc
			adc	#10
			dex
			bne	:108
::109			cpy	#$31
			bcc	:110
			clc
			adc	#100
			dey
			bne	:109
::110			sta	SEQ_MaxSize		;Max. Größe merken.
			jsr	SetMenuData		;Menüanzeige aktualisieren.
			LoadB	mouseYPos,$78
			LoadW	mouseXPos,$0080		;Mauszeiger setzen.
::111			jmp	ReDoMenu		;Zurück zum Parameter-Menü.

;*** Größe in ASCII einlesen.
:GetMaxSizeASCII	ldy	#"0"
			ldx	#"0"
			lda	SEQ_MaxSize
::101			cmp	#100
			bcc	:102
			sbc	#100
			iny
			bne	:101
::102			cmp	#10
			bcc	:103
			sbc	#10
			inx
			bne	:102
::103			adc	#"0"
			rts

;*** Menüdaten initialisieren.
:SetMenuData		ldy	#$00
			ldx	#$00			;Quell-Laufwerke initialsieren.
::101			lda	driveType,y
			beq	:102
			lda	#PLAINTEXT
			b $2c
::102			lda	#ITALICON
			sta	Laufwerk01,x
			txa
			clc
			adc	#14
			tax
			iny
			cpy	#$04
			bne	:101

			lda	SourceDrive		;Anzeige Quell-Laufwerk.
			add	$39
			sta	Parameter03a

			lda	CBM_FileType		;Ziel-Dateityp festlegen.
			cmp	#$82
			beq	:103

			lda	#"S"
			ldx	#"E"
			ldy	#"Q"
			bne	:104

::103			lda	#"P"
			ldx	#"R"
			ldy	#"G"
::104			sta	Parameter02a +2
			stx	Parameter02a +3
			sty	Parameter02a +4

			lda	#" "			;LineFeed-Modus merken.
			sta	LF_Text02
			sta	LF_Text03
			sta	LF_Text04

			lda	#<LF_Text02
			ldx	#>LF_Text02
			ldy	LineFeedMode
			dey
			beq	:105
			lda	#<LF_Text03
			ldx	#>LF_Text03
			dey
			beq	:105
			lda	#<LF_Text04
			ldx	#>LF_Text04
::105			sta	r0L
			stx	r0H
			ldy	#$00
			lda	#"*"
			sta	(r0L),y

			jsr	ShowTextMode		;Textmodus anzeigen.
			jsr	GetMaxSizeASCII		;Max. Größe SEQ-Datei.
			sty	Parameter08a +1
			stx	Parameter08a +2
			sta	Parameter08a +3
			rts

;*** Bildschirm-Informationen.
:ScreenInfo1		jsr	ScreenInfo2a
			LoadW	r0,InfoText01
			jmp	PutString

:ScreenInfo2		lda	#$02
			b $2c
:ScreenInfo2a		lda	#$09
			jsr	SetPattern
			jsr	i_Rectangle
			b	$b8,$c7
			w	$0000
:ScreenInfo128		w	$013f
			rts

:ScreenInfo3		jsr	ScreenInfo2a
			jsr	i_PutString
			w	$0010
			b	$c2
			b	PLAINTEXT,BOLDON
if Sprache = Deutsch
			b	" Daten werden eingelesen... ",NULL
endif
if Sprache = Englisch
			b	" Reading data... ",NULL
endif
			rts

;*** Bildschirm löschen.
:ClrScreen		LoadB	dispBufferOn,ST_WR_FORE ! ST_WR_BACK
			lda	#$02
			jsr	SetPattern
			jsr	i_Rectangle
			b	0,199
			w	0
:ClrScreen128		w	319
			rts

;*** GEOS-Dateityp wählen.
:SetGeosType		lda	mouseData		;Warten bis keine Maustaste
			bpl	SetGeosType		;gedrückt ist.
			LoadB	pressFlag,NULL

			lda	#$09			;Dateityp-Fenster aufbauen.
			jsr	SetPattern
			jsr	i_Rectangle
			b	$18,$25
:GeosType_Titel128	w	$0009,$012e

			LoadW	r0,InfoText02
			jsr	PutString

			lda	#$00
			sta	a0L

::101			jsr	GetXparameter		;Koordinaten für Ausgabe
							;der GEOS-Typen berechnen.

			lda	r3L 			;X-Koordinate berechnen.
			clc
			ldx	c128Flag
			beq	:C64
			ldx	graphMode
			beq	:C64
			adc	#$18
			jmp	:1
::C64			adc	#$10
::1			sta	r11L
			lda	r3H
			adc	#$00
			sta	r11H

			clc				;Y-Koordinate berechnen.
			lda	r2L
			adc	#$06
			sta	r1H

			LoadB	currentMode,SET_BOLD

			ldx	a0L			;GEOS-Dateityp ausgeben.
			lda	GTypeCode     ,x
			asl
			tax
::102			lda	GTypeVector +0,x
			sta	r0L
			lda	GTypeVector +1,x
			sta	r0H
			jsr	PutString

			inc	a0L
			lda	a0L
			cmp	#MaxFileTypes
			bne	:101

;*** Einstellungen anzeigen.
:ViewGEOStype		lda	#$00
			sta	a0L

::101			jsr	GetXparameter		;Koordinaten für Ausgabe
							;der GEOS-Typen berechnen.
			ldy	#$00			;Rechteck für Optionswahl
			ldx	a0L			;berechnen und anzeigen.
			lda	GTypeCode   ,x
			tax
			lda	GeosAllTypes,x
			beq	:102
			iny
::102			tya
			jsr	SetPattern
			jsr	Rectangle
			dec	r2L
			inc	r2H
			dec	r3L
			inc	r4L
			lda	#%11111111
			jsr	FrameRectangle

			inc	a0L
			lda	a0L
			cmp	#MaxFileTypes
			bne	:101
			rts

;*** Maus abfragen (Dateiauswahl).
:TestMouse1		lda	#$00
			sta	a0L

::101			jsr	GetXparameter		;Koordinaten für Auswahl

							;der GEOS-Typen berechnen.
			SubVW	8,r3
			AddVW	8,r4
			SubVB	3,r2L
			AddVB	3,r2H

			jsr	IsMseInRegion		;Maus abfragen.
			tax				;Maus im Bereich ?
			beq	:104			;Nein, weitertesten...

			ldx	a0L
			bne	:102
			lda	GeosAllTypes		;Alle Dateitypen wählen bzw.
			pha				;abwählen.
			eor	#$ff
			sta	:101a

			jsr	i_FillRam
			w	32
			w	GeosAllTypes
::101a			b	$ff

			pla
			sta	GeosAllTypes

::102			ldx	a0L			;Gewählten GEOS-Dateityp
			lda	GTypeCode   ,x		;anwählen/abwählen.
			tax
			lda	GeosAllTypes,x
			eor	#$ff
			sta	GeosAllTypes,x
			jsr	ViewGEOStype

::103			lda	mouseData		;Warten bis keine Maustaste
			bpl	:103			;gedrückt ist.
			LoadB	pressFlag,NULL
			rts

::104			inc	a0L
			lda	a0L
			cmp	#MaxFileTypes
			bne	:101

			jmp	RstrFrmDialogue

;*** X-Koordinaten für Optionsbereiche und Dateityp-Ausgabe berechnen.
:GetXparameter		ldy	#$00
			cmp	#10
			bcc	:101
			sec
			sbc	#10
			iny
::101			tax
			lda	#$2c
::102			cpx	#$00
			beq	:103
			clc
			adc	#14
			dex
			bne	:102
::103			sta	r2L
			clc
			adc	#06
			sta	r2H

			tya
			bne	:104
			lda	c128Flag
			beq	:C64
			lda	graphMode
			beq	:C64
			LoadW	r3,$0061
			LoadW	r4,$006b
			rts
::C64			LoadW	r3,$0021
			LoadW	r4,$0026
			rts

::104			lda	c128Flag
			beq	:C64_2
			lda	graphMode
			beq	:C64_2
			LoadW	r3,$0151
			LoadW	r4,$015b
			rts
::C64_2			LoadW	r3,$00a1
			LoadW	r4,$00a6
			rts

;*** Quelltext wählen.
:SlctTextFile		pha
			lda	FilesOnDisk		;Dateieinträge verfügbar ?
			beq	:101			;Ja, weiter...
::100			pla
			jmp	ReDoMenu

::101			lda	FileConvMode		;Konvertierungsmodus einlesen.
			beq	:100			;Modus definiert ? Nein, Ende.

;*** Zeiger auf Listen-Eintrag berechnen.
			pla
			pha
			jsr	SetVecToFileNm		;Zeiger auf Dateieintrag.

;*** Weiter oder zum Anfang ?
			ldy	#$01
			lda	(a0L),y
			cmp	#BOLDON			;Datei gewählt ?
			bne	:102			;Ja, weiter...

;*** Dateiliste aktualisieren.
			pla
			jsr	RecoverMenu		;Menü abbauen.

			lda	Menu_Files +6
			and	#%00111111
			sec
			sbc	#$02
			clc
			adc	Poi_1stEntryInTab
			sta	Poi_1stEntryInTab

			jsr	CopyNewFiles		;Nächste Dateien einlesen.
			jmp	ReDoMenu		;Dateimenü aktivieren.

;*** Datei zum konvertieren auswählen.
::102			jsr	ClrScreen		;Bildschirm löschen.

			pla
			clc
			adc	Poi_1stEntryInTab
			sec
			sbc	#$01
			ldx	MT03b +1
			cpx	#BOLDON
			bne	:103
			sec
			sbc	#$01
::103			jsr	SetVecFileEntry		;Zeiger auf Datei berechnen.

			ldy	#$05
			ldx	#$00
::104			lda	(a0L),y			;Dateiname kopieren.
			beq	:105
			cmp	#$a0
			beq	:105
			sta	CurFileName,x
			iny
			inx
			cpx	#16
			bcc	:104
::105			lda	#$00
			sta	CurFileName,x
			inx
			cpx	#17
			bcc	:105

;*** Verzweigen zur Konvertierungs-Routine.
			lda	FileConvMode		;Konvertierungsroutine
			asl				;aufrufen.
			tax
			ldy	FileConvRout+0,x
			lda	FileConvRout+1,x
			tax
			tya
			jmp	CallRoutine

;*** Zeiger auf Dateieintrag in PD-Menü kopieren.
:SetVecToFileNm		sta	a0L
			LoadB	a0H,$00
			LoadW	a1, $0011
			ldx	#a0L
			ldy	#a1L
			jsr	DMult
			AddVW	MT03a,a0		;Zeiger auf Eintrag berechnen.
			rts

;*** Ausgewählte Datei suchen.
:FindSlctFile		lda	SourceDrive
			jsr	SetDevice
			jsr	NewOpenDisk
			LoadW	r6,CurFileName
			jmp	FindFile

;*** Datei suchen, Position im Verzeichnis merken.
:GetFileDirPos		jsr	FindSlctFile
			txa
			beq	CopyPosFileEntry
			rts

;*** Zeiger auf Verzeichnis-Eintrag kopieren.
:CopyPosFileEntry	lda	r1L
			sta	FileDirSek +0
			lda	r1H
			sta	FileDirSek +1
			lda	r5L
			sta	FileDirPos +0
			lda	r5H
			sta	FileDirPos +1
			rts

;*** Textdateien einlesen.
:DefMenuEntrysTxt	lda	#$00			;Zeiger auf erste Datei.
			sta	Poi_1stEntryInTab

:GetMenuEntrysTxt	lda	#$00
			sta	FilesOnDisk		;Datei-Flag löschen.
			sta	MaxFilesOnDsk		;Dateizähler löschen.

			jsr	i_FillRam		;Speicher für Dateieinträge.
			w	$2000			;löschen.
			w	$4000
			b	$00

			LoadB	Menu_Files +6,$01 ! VERTICAL ! CONSTRAINED

			ldy	FileConvMode		;Modus definiert ?
			beq	TestFileMemory		;Nein, Abbruch.

			lda	SourceDrive
			jsr	SetDevice
			jsr	NewOpenDisk		;Quell-Diskette öffnen.

			lda	curDirHead +$00
			sta	r1L
			lda	curDirHead +$01
			sta	r1H
			LoadW	r4,diskBlkBuf
			LoadW	a0,$4000

::101			jsr	GetBlock		;Verzeichnis-Sektor lesen.

			ldx	#$00
::102			jsr	TestCurDirEntry		;Eintrag gültig ?
			bcs	:105			;Nein, weiter...
			txa
			pha
			ldy	#$00
::103			lda	diskBlkBuf,x		;Dateieintrag kopieren.
			sta	(a0L),y
			inx
			iny
			cpy	#$20
			bne	:103
			AddVW	32,a0
			inc	MaxFilesOnDsk
			bne	:104
			pla
			jmp	TestFileMemory		;Dateispeicher voll!

::104			pla
			tax
::105			txa
			clc
			adc	#$20
			tax
			bne	:102			;Zeiger auf nächsten Eintrag.

			ldx	diskBlkBuf +1		;Nächsten Verzeichnis-Sektor
			lda	diskBlkBuf +0		;von Diskette einlesen.
			beq	TestFileMemory
			stx	r1H
			sta	r1L
			jmp	:101

;*** Dateien gefunden ?
:TestFileMemory		lda	MaxFilesOnDsk		;Dateien gefunden ?
			bne	CopyNewFiles		;Ja, weiter...

			LoadW	r4,NoFiles		;Hinweis "Keine Dateien!"
			LoadW	r5,MT03b
			ldx	#r4L
			ldy	#r5L
			jsr	CopyString

			LoadB	Menu_Files +1,$1d
			LoadB	Menu_Files +6,$02 ! VERTICAL ! CONSTRAINED
			LoadB	CurFileName,NULL
			inc	FilesOnDisk
			rts

;*** Weitere Dateien in "Datei-Menü" einblenden.
:CopyNewFiles		lda	Poi_1stEntryInTab
			cmp	MaxFilesOnDsk
			bcc	:100
			lda	#$00
			sta	Poi_1stEntryInTab

::100			lda	Poi_1stEntryInTab
			jsr	SetVecFileEntry

			MoveW	a0,r0
			LoadW	r1,MT03b
			LoadB	r2L,$01
			LoadB	r2H,$0f

			lda	Poi_1stEntryInTab
			sta	r3L

			lda	MaxFilesOnDsk
			cmp	#MaxFileEntry +1
			bcc	:103

			lda	MaxFilesOnDsk
			sec
			sbc	r3L
			cmp	#MaxFileEntry
			bcs	:102

			LoadW	r4,Go1stTextFile
			ldx	#r4L
			lda	#$ff
			jsr	AddTextToList
			jmp	:103

::102			LoadW	r4,MoreTextFiles
			ldx	#r4L
			lda	#$ff
			jsr	AddTextToList

::103			ldy	#$02
			lda	(r0L),y
			beq	:104

			AddVW	5,r0
			ldx	#r0L
			lda	#$00
			jsr	AddTextToList
			AddVW	27,r0
			inc	r3L

			lda	r2L
			cmp	#MaxFileEntry
			beq	:104
			lda	r3L
			cmp	MaxFilesOnDsk
			bcc	:103
::104			lda	r2L
			ora	#VERTICAL ! UN_CONSTRAINED
			sta	Menu_Files +6
			lda	r2H
			sta	Menu_Files +1
			rts

;*** Prüfen ob Datei-Eintrag gültig.
:TestCurDirEntry	ldy	FileConvMode
			beq	:101

			ldy	diskBlkBuf +$02,x
			bne	:103
::101			sec
			rts
::102			clc
			rts

::103			ldy	FileConvMode
			dey
			bne	:104
			ldy	diskBlkBuf +$18,x
			lda	GeosTypes      ,y
			beq	:101
			bne	:102

::104			dey
			bne	:105
			ldy	diskBlkBuf +$15,x
			bne	:101
			beq	:102

::105			ldy	FileConvMode
			cpy	#$06
			beq	:102
			ldy	diskBlkBuf +$15,x
			bne	:101
			beq	:102

;** Dateiname in Tabelle kopieren, Zeiger auf nächsten Eintrag.
:AddTextToList		jsr	Copy1Name
::103			AddVW	17,r1
			AddVB	14,r2H
			inc	r2L
			rts

;*** Dateiname kopieren.
:Copy1Name		stx	:101 +1
			tax

			ldy	#$00
::101			lda	($ff),y
			cmp	#$a0
			beq	:102
			cpx	#$ff
			beq	:101b

			cmp	#$20
			bcc	:101a
			cmp	#$7f
			bcc	:101b
::101a			lda	#"*"

::101b			sta	(r1L),y
			iny
			cpy	#16
			bcc	:101
::102			lda	#$00
			sta	(r1L),y
			iny
			cpy	#17
			bne	:102
			rts

;*** Zeiger auf Verzeichniseintrag.
:SetVecFileEntry	sta	a0L
			LoadB	a0H,$00
			LoadW	a1 ,$0020
			ldx	#a0L
			ldy	#a1L
			jsr	DMult
			AddVW	$4000,a0
			rts

;******************************************************************************
;*** Unterprogramme zum anzeigen von Diskettenfehlern.
;******************************************************************************

;*** Diskettenfehler anzeigen.
:ErrDiskError		lda	curDrive
			add	$39
			sta	DlgDskErrDrvTa

			LoadW	r0,DlgDiskError
			LoadB	mouseYPos,$45
			LoadW	mouseXPos,$00f3		;Mauszeiger setzen.
			jsr	DoDlgBox
			jmp	StartMenü

;*** Text für Diskettenfehler definieren.
:GetTxtDiskErr		cpx	#$20
			bcs	:101
			dex
			txa
			asl
			tay
			lda	ErrTxtVecTab1 +0,y
			sta	r5L
			lda	ErrTxtVecTab1 +1,y
			sta	r5H
			bne	:104

::101			cpx	#$73
			bne	:102
			LoadW	r5,ErrText19
			bne	:104

::102			cpx	#$2a
			bcc	:103
			LoadW	r5,ErrText20
			bne	:104

::103			txa
			sbc	#$1f
			asl
			tay
			lda	ErrTxtVecTab2 +0,y
			sta	r5L
			lda	ErrTxtVecTab2 +1,y
			sta	r5H
::104			jmp	ErrDiskError

;*** Diskettenfehler ausgeben.
:ExitDiskErr		jsr	GetTxtDiskErr
			jmp	SetStdMsePos

;******************************************************************************
;*** Konvertierungsroutinen.
;******************************************************************************

			t "d64.ExtractDisk"
			t "d64.ExtractFile"
			t "d64.CreateImage"
			t "d64.Tools"
			t "cvt.FileConvert"
			t "uue.FileConvert"
			t "seq.FileConvert"
			t "src.DefNameDOS"
			t "src.NewOpenDisk"

;*** Testen ob C128 im 80Zeichen-Modus. Wenn ja, dann X-Positionen anpassen!
:TestC128		lda	c128Flag
			beq	:c64			;>C64
			lda	graphMode
			bmi	:c128			;>C128 80Zeichen
::c64			rts				;>C64 / C128-40Zeichen

::c128			LoadW	ClrScreen128 ,639
			LoadB	Menu_Main128 ,MainMenü_right
			LoadB	Menu_GEOS128_2 ,GeosMenü_right
			lda	#SubMenü_left
			sta	Menu_GEOS128_1
			sta	Menu_Param128_1
			sta	Menu_Modus128_1
			LoadW	Menu_Param128_2 ,ParamMenü_right
			LoadW	Menu_Modus128_2 ,ModusMenü_right
			LoadB	Menu_Files128 ,FilesMenü_right

			LoadB	Menu_Drive128 ,DriveMenü_right
			LoadW	Menu_LF128 ,LFMenü_right

			lda	#$c0
			sta	LF1
			sta	LF2
			sta	LF3

			LoadW	GeosType_Titel128    ,$0051
			LoadW	GeosType_Titel128+2  ,$023d
			LoadW	GeosType_TitelText128,$00b0

			LoadW	ScreenInfo128 ,639

			lda	#$6a
			sta	Parameter01+5
			sta	Parameter02+4

;*** IncludeFiles.
			LoadW	D64_a1,$0080
			LoadW	D64_a2,$01fe
			LoadW	D64_a3,$0080
			LoadW	D64_a4,$0084
			LoadW	D64_a5,$01fa
			LoadW	V300a1,$0090
			LoadW	V300a2,$00e0

			LoadW	D64_b1,$0080
			LoadW	D64_b2,$01fe
			LoadW	D64_b3,$0080
			LoadW	D64_b4,$0084
			LoadW	D64_b5,$01fa
			LoadW	V301a3,$0090
			LoadW	V301a3_,$00e0
			LoadW	V301a4,$0090
			LoadW	V301a4_,$00e0
			LoadW	V301a5,$0090
			LoadW	V301a5_,$00e0

			LoadW	D64_c1,$0080
			LoadW	D64_c2,$01fe
			LoadW	D64_c3,$0080
			LoadW	D64_c4,$0084
			LoadW	D64_c5,$01fa
			LoadW	V302a1,$0090
			LoadW	V302a2,$00e0

;*** Dialogboxen
			ldx	#0
::1			lda	DlgBoxData,x
			sta	r1L
			inx
			lda	DlgBoxData,x
			cmp	#$ff
			bne	:2
			rts				;>fertig
::2			sta	r1H
			inx
			lda	DlgBoxData,x
			ldy	#3
			sta	(r1),y
			jsr	:sub
			jsr	:sub
			jsr	:sub
			inx
			bne	:1

::sub			iny
			inx
			lda	DlgBoxData,x
			sta	(r1),y
			rts

:DlgBoxData		w	DlgInfoBox ,$0040!DOUBLE_W,$00ff!DOUBLE_W
			w	DlgGeosType ,$0028!DOUBLE_W,$011f!DOUBLE_W
			w	DlgDiskError ,$0040!DOUBLE_W,$00ff!DOUBLE_W
			w	DlgGetFileName ,		$0040!DOUBLE_W,$00ff!DOUBLE_W
			w	DlgGetMaxSize ,$0040!DOUBLE_W,$00ff!DOUBLE_W
			w	$ffff

:MainMenü_right		=	70
:SubMenü_left		=	71
:GeosMenü_right		=	150
:ParamMenü_right	=	265
:ModusMenü_right	=	250
:DriveMenü_right	=	220
:LFMenü_right		=	300
:FilesMenü_right	=	159

;*** Variablen.
:StackPointer		b $00

:curMenu		w $0000

:FileConvMode		b $00
:FileConvRout		w GotoFirstMenu
			w ConvertOneFile
			w ConvertOneFile
			w ConvToUUE
			w AppendToUUE
			w ConvUUE_SEQ_PRG
			w CreateD64Image
			w D64toDISK
			w D64toFile		;D64-Verzeichnis einlesen.
			w ExtractD64File	;Datei aus D64 konvertieren.
			w SEQ_Trennen
			w SEQ_Verbinden

:GeosAllTypes		b $00
:GeosTypes		s 32

:Poi_1stEntryInTab	b $00
:FilesOnDisk		b $00
:MaxFilesOnDsk		b $00
:Flag_AllFiles		b $00

:CharForDOS		b "0123456789"
			b "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
			b NULL

:SourceDrive		b $08
:TargetDrive		b $08

:CurDiskName		s 17
:CurFileName		s 17
:FileDirSek		b $00,$00
:FileDirPos		w $0000
:CurSektor		b $00,$00

:CBM_FileType		b CBM_PRG
:GEOS_FileType		b APPLICATION

:SEQ_MaxSize		b $0f
:InputBuf1		s $04

:SourceFile		s 17
:TargetFile		s 17

:BlockCount		w $0000
:DirSektor		b $00,$00
:DirPointer		b $00

:SrcSektor		b $00,$00
:BytePointer		b $00
:SrcSekData		s 256

:TgtSektor		b $00,$00
:TgtSekData		s 256

:FindSektor		b $01,$01
:StartSektor		b $00,$00

;*** Systemtexte.
if Sprache = Deutsch
:NoFiles		b PLAINTEXT,BOLDON,"Keine Dateien!",NULL
:MoreTextFiles		b PLAINTEXT,BOLDON,">> Weiter",PLAINTEXT,NULL
:Go1stTextFile		b PLAINTEXT,BOLDON,"<< Anfang",PLAINTEXT,NULL
:InfoText01		b GOTOXY
			w $0010
			b $c2
			b PLAINTEXT,BOLDON
			b " Daten werden konvertiert... ",NULL

:InfoText02		b GOTOXY
:GeosType_TitelText128	w $0030
			b $20
			b BOLDON," Dateitypen für Menü 'Dateien' wählen: ",NULL
endif

if Sprache = Englisch
:NoFiles		b PLAINTEXT,BOLDON,"No files!     ",NULL
:MoreTextFiles		b PLAINTEXT,BOLDON,">> More  ",PLAINTEXT,NULL
:Go1stTextFile		b PLAINTEXT,BOLDON,"<< Top   ",PLAINTEXT,NULL
:InfoText01		b GOTOXY
			w $0010
			b $c2
			b PLAINTEXT,BOLDON
			b " Converting data... ",NULL

:InfoText02		b GOTOXY
:GeosType_TitelText128	w $0030
			b $20
			b BOLDON," Select filetypes for menu 'Files' ",NULL
endif

if Sprache = Deutsch
;*** Fehlermeldungen im Klartext.
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
:InsDiskText		b BOLDON,"Bitte neue Diskette einlegen!"						,PLAINTEXT,NULL
:NoCnvFileTxt		b BOLDON,"Keine konvertierte Datei!"							,PLAINTEXT,NULL
:No41DrvTxt		b BOLDON,"Kein 1541-Laufwerk!"								,PLAINTEXT,NULL

:ErrTxtVecTab1		w ErrText01,ErrText02
			w ErrText03,ErrText04
			w ErrText05,ErrText06
			w ErrText20,ErrText20
			w ErrText20,ErrText07
			w ErrText08,ErrText20
			w ErrText09,ErrText10

:ErrTxtVecTab2		w ErrText11,ErrText12
			w ErrText13,ErrText14
			w ErrText20,ErrText15
			w ErrText16,ErrText17
			w ErrText20,ErrText18

;*** Dateitypen.
:GTypeAll		b "Alle Dateien",NULL
:GType00		b "Commodore",NULL
:GType01		b "BASIC",NULL
:GType02		b "Assembler",NULL
:GType03		b "Daten",NULL
:GType04		b "Systemdateien",NULL
:GType05		b "DeskAccessory",NULL
:GType06		b "Applikationen",NULL
:GType07		b "Dokumente",NULL
:GType08		b "Zeichensätze",NULL
:GType09		b "Druckertreiber",NULL
:GType10		b "Eingabetreiber",NULL
:GType11		b "Laufwerkstreiber",NULL
:GType12		b "Startprogramme",NULL
:GType13		b "Temporäre Dateien",NULL
:GType14		b "Selbstausführend",NULL
:GType15		b "Eingabetreiber C128",NULL
:GType17		b "GateWay-Dokument",NULL
:GType21		b "GeoShell-Befehl",NULL
:GType22		b "GeoFAX-Drucker",NULL

:GTypeVector		w GTypeAll
			w GType00,GType01,GType02,GType03
			w GType04,GType05,GType06,GType07
			w GType08,GType09,GType10,GType11
			w GType12,GType13,GType14,GType15
			w $0000  ,GType17,$0000  ,$0000
			w $0000  ,GType21,GType22

:GTypeCode		b $00,$01,$02,$03
			b $04,$05,$06,$07
			b $08,$09,$0a,$0b
			b $0c,$0d,$0e,$0f
			b $10,$12,$16,$17
endif

if Sprache = Englisch
;*** Fehlermeldungen im Klartext.
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
:InsDiskText		b BOLDON,"Insert new disk!"								,PLAINTEXT,NULL
:NoCnvFileTxt		b BOLDON,"Not a converted file!"							,PLAINTEXT,NULL
:No41DrvTxt		b BOLDON,"No 1541-drive!"								,PLAINTEXT,NULL

:ErrTxtVecTab1		w ErrText01,ErrText02
			w ErrText03,ErrText04
			w ErrText05,ErrText06
			w ErrText20,ErrText20
			w ErrText20,ErrText07
			w ErrText08,ErrText20
			w ErrText09,ErrText10

:ErrTxtVecTab2		w ErrText11,ErrText12
			w ErrText13,ErrText14
			w ErrText20,ErrText15
			w ErrText16,ErrText17
			w ErrText20,ErrText18

;*** Dateitypen.
:GTypeAll		b "All filetypes",NULL
:GType00		b "Commodore",NULL
:GType01		b "BASIC",NULL
:GType02		b "Assembler",NULL
:GType03		b "Data",NULL
:GType04		b "Systemfiles",NULL
:GType05		b "DeskAccessory",NULL
:GType06		b "Applicatios",NULL
:GType07		b "Documents",NULL
:GType08		b "Fonts",NULL
:GType09		b "Printdrivers",NULL
:GType10		b "Inputdrivers",NULL
:GType11		b "Diskdrivers",NULL
:GType12		b "Startfiles",NULL
:GType13		b "Temporary files",NULL
:GType14		b "Auto-execute",NULL
:GType15		b "Inputdriver C128",NULL
:GType17		b "GateWay-document",NULL
:GType21		b "GeoShell-command",NULL
:GType22		b "GeoFAX-printdriver",NULL

:GTypeVector		w GTypeAll
			w GType00,GType01,GType02,GType03
			w GType04,GType05,GType06,GType07
			w GType08,GType09,GType10,GType11
			w GType12,GType13,GType14,GType15
			w $0000  ,GType17,$0000  ,$0000
			w $0000  ,GType21,GType22

:GTypeCode		b $00,$01,$02,$03
			b $04,$05,$06,$07
			b $08,$09,$0a,$0b
			b $0c,$0d,$0e,$0f
			b $10,$12,$16,$17
endif

;*** Hauptmenu.
:Menu_Main		b $00
			b $2b
			w $0000
:Menu_Main128		w $0037

			b $03 ! VERTICAL ! UN_CONSTRAINED

			w Main01
			b SUB_MENU
			w Menu_GEOS

			w Main02
			b SUB_MENU
			w Menu_Parameter

			w Main03
			b SUB_MENU
			w Menu_Modus

;*** Menü "GEOS".
:Menu_GEOS		b $00
			b $1d
:Menu_GEOS128_1		w $0038
:Menu_GEOS128_2		w $007f

			b $02 ! VERTICAL ! UN_CONSTRAINED

			w File01
			b MENU_ACTION
			w PrintInfoBox

			w File02
			b MENU_ACTION
			w ExitToDeskTop

;*** Daten für Menü Parameter.
:Menu_Parameter		b $0e
			b $7f
:Menu_Param128_1	w $0038
:Menu_Param128_2	w $00cf

			b $08 ! VERTICAL ! UN_CONSTRAINED

			w Parameter01
			b MENU_ACTION
			w SlctGeosFileType

			w Parameter02
			b MENU_ACTION
			w SlctCBM_FileType

			w Parameter03
			b SUB_MENU
			w Menu_Drive

			w Parameter04
			b MENU_ACTION
			w InsertNewDisk

			w Parameter05
			b MENU_ACTION
			w ConvertAllFiles

			w Parameter06
			b SUB_MENU
			w Menu_LF

			w Parameter07
			b MENU_ACTION
			w SwapTextMode

			w Parameter08
			b MENU_ACTION
			w GetMaxSize

;*** Daten für Laufwerksauswahl.
:Menu_Drive		b $33
			b $6c
			w $0080
:Menu_Drive128		w $00c8

			b $04 ! VERTICAL ! UN_CONSTRAINED

			w Laufwerk01
			b MENU_ACTION
			w SourceDriveA

			w Laufwerk02
			b MENU_ACTION
			w SourceDriveB

			w Laufwerk03
			b MENU_ACTION
			w SourceDriveC

			w Laufwerk04
			b MENU_ACTION
			w SourceDriveD

;*** LineFeed für UUE wählen.
:Menu_LF		b $5c
			b $95
			w $0050
:Menu_LF128		w $00ff

			b $04 ! VERTICAL ! UN_CONSTRAINED

			w LF_Text01
			b MENU_ACTION
			w ReDoMenu

			w LF_Text02
			b MENU_ACTION
			w ConvToUUE_CR

			w LF_Text03
			b MENU_ACTION
			w ConvToUUE_CRLF

			w LF_Text04
			b MENU_ACTION
			w ConvToUUE_LF

;*** Konvertierungsmodus wählen.
:Menu_Modus		b $1c
			b $a9
:Menu_Modus128_1	w $0038
:Menu_Modus128_2	w $00bf

			b $0a ! VERTICAL ! UN_CONSTRAINED

			w ModusText01
			b MENU_ACTION
			w SetMode1

			w ModusText02
			b MENU_ACTION
			w SetMode2

			w ModusText03
			b MENU_ACTION
			w SetMode3

			w ModusText04
			b MENU_ACTION
			w SetMode4

			w ModusText05
			b MENU_ACTION
			w SetMode5

			w ModusText06
			b MENU_ACTION
			w CreateD64Image

			w ModusText07
			b MENU_ACTION
			w SetMode7

			w ModusText08
			b MENU_ACTION
			w SetMode8

			w ModusText09
			b MENU_ACTION
			w SetMode9

			w ModusText10
			b MENU_ACTION
			w SetMode10

;*** Daten für Menü.
:Menu_Files		b $00
			b $1e
			w $0000
:Menu_Files128		w $005f

			b $02 ! VERTICAL ! UN_CONSTRAINED

			w MT03a
			b MENU_ACTION
			w OpenMain

			w MT03b
			b MENU_ACTION
			w SlctTextFile

			w MT03c
			b MENU_ACTION
			w SlctTextFile

			w MT03d
			b MENU_ACTION
			w SlctTextFile

			w MT03e
			b MENU_ACTION
			w SlctTextFile

			w MT03f
			b MENU_ACTION
			w SlctTextFile

			w MT03g
			b MENU_ACTION
			w SlctTextFile

			w MT03h
			b MENU_ACTION
			w SlctTextFile

			w MT03i
			b MENU_ACTION
			w SlctTextFile

			w MT03j
			b MENU_ACTION
			w SlctTextFile

			w MT03k
			b MENU_ACTION
			w SlctTextFile

			w MT03l
			b MENU_ACTION
			w SlctTextFile

			w MT03m
			b MENU_ACTION
			w SlctTextFile

			w MT03n
			b MENU_ACTION
			w SlctTextFile


if Sprache = Deutsch
;*** Menü-Texte.
:Main01			b "geos",NULL
:Main02			b "Parameter",NULL
:Main03			b "Modus",NULL
:File01			b "Information",NULL
:File02			b "Verlassen",NULL

:Parameter01		b "GEOS",GOTOX,$60,$00,"-Format wählen",NULL
:Parameter02		b "CBM" ,GOTOX,$60,$00,"-Format wählen"
:Parameter02a		b " (PRG)",NULL
:Parameter03		b "Daten auf Laufwerk "
:Parameter03a		b "A:",NULL
:Parameter04		b "Neue Diskette",NULL
:Parameter05		b "CVT: Alle Dateien konvertieren",NULL
:Parameter06		b "UUE: LineFeed-Modus wählen",NULL
:Parameter07		b "UUE: 1234567890123456",NULL
:Parameter07a		b "Texte",NULL
:Parameter07b		b "Programme",NULL
:Parameter08		b "SEQ: Max. Dateigröße "
:Parameter08a		b "(000 Kb)",NULL

:Laufwerk01		b PLAINTEXT,"Laufwerk A:",PLAINTEXT,NULL
:Laufwerk02		b PLAINTEXT,"Laufwerk B:",PLAINTEXT,NULL
:Laufwerk03		b PLAINTEXT,"Laufwerk C:",PLAINTEXT,NULL
:Laufwerk04		b PLAINTEXT,"Laufwerk D:",PLAINTEXT,NULL

:LF_Text01		b PLAINTEXT,BOLDON
			b "Linefeed-Modus für UUE-Datei:",PLAINTEXT,NULL
:LF_Text02		b "  Linefeed: CR"   ,GOTOX
:LF1			b $a8,$00,BOLDON
			b ">>",PLAINTEXT," C64 Standard",NULL
:LF_Text03		b "  Linefeed: CR+LF",GOTOX
:LF2			b $a8,$00,BOLDON
			b ">>",PLAINTEXT," IBM/DOS PCs",NULL
:LF_Text04		b "  Linefeed: LF"   ,GOTOX
:LF3			b $a8,$00,BOLDON
			b ">>",PLAINTEXT," UNIX-Systeme",NULL

:ModusText01		b PLAINTEXT,"GEOS ",GOTOX,$6c,$00,"=> CBM",NULL
:ModusText02		b           "CBM " ,GOTOX,$6c,$00,"=> GEOS",NULL
:ModusText03		b           "SEQ " ,GOTOX,$6c,$00,"=> UUE",NULL
:ModusText04		b           "Datei an UUE anhängen",NULL
:ModusText05		b           "UUE " ,GOTOX,$6c,$00,"=> SEQ",NULL
:ModusText06		b           "Disk ",GOTOX,$6c,$00,"=> D64",NULL
:ModusText07		b           "D64 " ,GOTOX,$6c,$00,"=> Disk",NULL
:ModusText08		b           "D64 " ,GOTOX,$6c,$00,"=> Datei",NULL
:ModusText09		b           "SEQ Datei aufteilen",NULL
:ModusText10		b           "SEQ Dateien zusammenfügen",NULL

:MT03a			b PLAINTEXT,BOLDON,"<< Hauptmenü ",PLAINTEXT,NULL
:MT03b			s 17
:MT03c			s 17
:MT03d			s 17
:MT03e			s 17
:MT03f			s 17
:MT03g			s 17
:MT03h			s 17
:MT03i			s 17
:MT03j			s 17
:MT03k			s 17
:MT03l			s 17
:MT03m			s 17
:MT03n			s 17
endif

if Sprache = Englisch
;*** Menü-Texte.
:Main01			b "geos",NULL
:Main02			b "Parameter",NULL
:Main03			b "Mode",NULL
:File01			b "Information",NULL
:File02			b "Exit",NULL

:Parameter01		b "Select format: GEOS",NULL
:Parameter02		b "Select format: CBM  "
:Parameter02a		b " (PRG)",NULL
:Parameter03		b "Data on drive "
:Parameter03a		b "A:",NULL
:Parameter04		b "New disk",NULL
:Parameter05		b "CVT: Convert all files",NULL
:Parameter06		b "UUE: Select LineFeed-Mode",NULL
:Parameter07		b "UUE: 1234567890123456",NULL
:Parameter07a		b "Documents",NULL
:Parameter07b		b "Programms",NULL
:Parameter08		b "SEQ: Max. Filesize "
:Parameter08a		b "(000 Kb)",NULL

:Laufwerk01		b PLAINTEXT,"Drive    A:",PLAINTEXT,NULL
:Laufwerk02		b PLAINTEXT,"Drive    B:",PLAINTEXT,NULL
:Laufwerk03		b PLAINTEXT,"Drive    C:",PLAINTEXT,NULL
:Laufwerk04		b PLAINTEXT,"Drive    D:",PLAINTEXT,NULL

:LF_Text01		b PLAINTEXT,BOLDON
			b "Linefeed-Mode for UUE-file:",PLAINTEXT,NULL
:LF_Text02		b "  Linefeed: CR"   ,GOTOX
:LF1			b $a8,$00,BOLDON
			b ">>",PLAINTEXT," C64 Standard",NULL
:LF_Text03		b "  Linefeed: CR+LF",GOTOX
:LF2			b $a8,$00,BOLDON
			b ">>",PLAINTEXT," IBM/DOS PCs",NULL
:LF_Text04		b "  Linefeed: LF"   ,GOTOX
:LF3			b $a8,$00,BOLDON
			b ">>",PLAINTEXT," UNIX-Systems",NULL

:ModusText01		b PLAINTEXT,"GEOS ",GOTOX,$6c,$00,"=> CBM",NULL
:ModusText02		b           "CBM " ,GOTOX,$6c,$00,"=> GEOS",NULL
:ModusText03		b           "SEQ " ,GOTOX,$6c,$00,"=> UUE",NULL
:ModusText04		b           "Add file to UUE-file",NULL
:ModusText05		b           "UUE " ,GOTOX,$6c,$00,"=> SEQ",NULL
:ModusText06		b           "Disk ",GOTOX,$6c,$00,"=> D64",NULL
:ModusText07		b           "D64 " ,GOTOX,$6c,$00,"=> Disk",NULL
:ModusText08		b           "D64 " ,GOTOX,$6c,$00,"=> File",NULL
:ModusText09		b           "SEQ Split file",NULL
:ModusText10		b           "SEQ Connect files",NULL

:MT03a			b PLAINTEXT,BOLDON,"<< Mainmenu  ",PLAINTEXT,NULL
:MT03b			s 17
:MT03c			s 17
:MT03d			s 17
:MT03e			s 17
:MT03f			s 17
:MT03g			s 17
:MT03h			s 17
:MT03i			s 17
:MT03j			s 17
:MT03k			s 17
:MT03l			s 17
:MT03m			s 17
:MT03n			s 17
endif

if Sprache = Deutsch
;*** Infobox.
:DlgInfoBox		b $01
			b $30,$97
			w $0020,$011f
			b DBTXTSTR    ,$10,$0e
			w :101
			b DBTXTSTR    ,$10,$1e
			w :102
			b DBTXTSTR    ,$10,$29
			w :103
			b DBTXTSTR    ,$10,$38
			w :104
			b DBTXTSTR    ,$10,$43
			w :105
			b DBTXTSTR    ,$10,$4e
			w :106
			b DBTXTSTR    ,$10,$59
			w :107
			b DBSYSOPV
			b NULL

::101			b PLAINTEXT,BOLDON
			b "GeoConvert 98f-"
			k
			b NULL
::102			b "(c) '97/98/99: Markus Kanet",NULL
::103			b "EMail:",NULL
::104			b "Anpassung an GEOS128-80 Zeichen:",NULL
::105			b "Wolfgang Grimm, MegaCom Software",NULL
::106			b "EMail: ",NULL
::107			b "",NULL

;*** Dialobox Auswahl GEOS-Dateityp.
:DlgGeosType		b $01
			b $18,$b7
			w $0008,$012f
			b DB_USR_ROUT
			w SetGeosType
			b DBOPVEC
			w TestMouse1
			b NULL

;*** Dialogbox Auswahl CBM-Dateityp.
:DlgCBM_Type		b $81
			b DBUSRICON    ,$02,$18
			w iconDataSEQ
			b DBUSRICON    ,$02,$30
			w iconDataPRG
			b CANCEL       ,$10,$48
			b DBTXTSTR     ,$10,$0e
			w :101
			b DBTXTSTR     ,$38,$1e
			w :102
			b DBTXTSTR     ,$38,$28
			w :103
			b DBTXTSTR     ,$38,$36
			w :102
			b DBTXTSTR     ,$38,$40
			w :104
			b NULL

::101			b BOLDON,"Dateiformat wählen:",PLAINTEXT,NULL
::102			b BOLDON,"Konvertierte Datei vom",NULL
::103			b        "Typ 'SEQ' erstellen.",NULL
::104			b        "Typ 'PRG' erstellen.",PLAINTEXT,NULL

;*** Daten für "PRG"-Icon.
:iconDataPRG		w icon_PRG
			b $00,$00,$04,$10
			w SlctFileTypPRG

;*** Daten für "SEQ"-Icon.
:iconDataSEQ		w icon_SEQ
			b $00,$00,$04,$10
			w SlctFileTypCBM

;*** Dialobox für Diskettenfehler.
:DlgDiskError		b $01
			b $20,$5f
			w $0040,$00ff
			b DBVARSTR    ,$10,$0f
			b r5L
			b DBTXTSTR    ,$10,$1d
			w DlgDskErrDrvT
			b OK          ,$11,$28
			b NULL

:DlgDskErrDrvT		b BOLDON,"(Laufwerk "
:DlgDskErrDrvTa		b "x:)",NULL

;*** Name D64-Datei eingeben.
:DlgGetFileName		b $01
			b $20,$5f
			w $0040,$00ff
			b DBTXTSTR    ,$10,$0f
			w :101
			b DBGETSTRING ,$10,$14
			b r5L, 16
			b CANCEL      ,$11,$28
			b NULL

::101			b PLAINTEXT,BOLDON
			b "Name der D64-Datei:",NULL
endif

if Sprache = Deutsch
;*** Dialogobx: "Dateiname nicht gefunden!"
:DlgNoFileName		b $81
			b DBTXTSTR    ,$10,$0e
			w :101
			b DBTXTSTR    ,$10,$1e
			w :102
			b DBTXTSTR    ,$10,$29
			w :103
			b OK          ,$02,$48
			b NULL

::101			b PLAINTEXT
			b BOLDON   ,"Schwerer Fehler!",PLAINTEXT,NULL
::102			b           "Es ist kein Dateiname im",BOLDON,NULL
::103			b           "UUE-Code angegeben!",NULL

;*** Dialogbox: "'END' nicht gefunden!"
:DlgEndNotFound		b $81
			b DBTXTSTR    ,$10,$0e
			w :101
			b DBTXTSTR    ,$10,$1e
			w :102
			b DBTXTSTR    ,$10,$29
			w :103
			b OK          ,$02,$48
			b NULL

::101			b PLAINTEXT
			b BOLDON   ,"Schwerer Fehler!",PLAINTEXT,NULL
::102			b           "Das Ende der UUE-Kodierung",BOLDON,NULL
::103			b           "wurde nicht gefunden!",NULL

;*** Laufwerksauswahl.
:DlgSlctTgtDrv		b $81

			b DBTXTSTR     ,$10,$0e
			w FileBoxTitle2
			b CANCEL       ,$02,$48
:DlgDrv1b		b DBUSRICON    ,$02,$20
			w DriveIconA
:DlgDrv2b		b DBUSRICON    ,$06,$20
			w DriveIconB
:DlgDrv3b		b DBUSRICON    ,$0a,$20
			w DriveIconC
:DlgDrv4b		b DBUSRICON    ,$0e,$20
			w DriveIconD
			b NULL

:FileBoxTitle2		b PLAINTEXT,BOLDON
			b "Ziel-Laufwerk wählen:",NULL

:DriveIconA		w Icon_01
			b $00,$00,$02,$10
			w TargetDriveA

:DriveIconB		w Icon_02
			b $00,$00,$02,$10
			w TargetDriveB

:DriveIconC		w Icon_03
			b $00,$00,$02,$10
			w TargetDriveC

:DriveIconD		w Icon_04
			b $00,$00,$02,$10
			w TargetDriveD

;*** Max. Größe SEQ-Datei.
:DlgGetMaxSize		b $01
			b $20,$5f
			w $0040,$00ff
			b DBTXTSTR    ,$10,$0f
			w :101
			b DBGETSTRING ,$10,$14
			b r5L, 3
			b CANCEL      ,$11,$28
			b NULL

::101			b PLAINTEXT,BOLDON
			b "Max. Größe in KByte:",NULL
endif

if Sprache = Englisch
;*** Infobox.
:DlgInfoBox		b $01
			b $30,$97
			w $0020,$011f
			b DBTXTSTR    ,$10,$0e
			w :101
			b DBTXTSTR    ,$10,$1e
			w :102
			b DBTXTSTR    ,$10,$29
			w :103
			b DBTXTSTR    ,$10,$38
			w :104
			b DBTXTSTR    ,$10,$43
			w :105
			b DBTXTSTR    ,$10,$4e
			w :106
			b DBTXTSTR    ,$10,$59
			w :107
			b DBSYSOPV
			b NULL

::101			b PLAINTEXT,BOLDON
			b "GeoConvert 98f-"
			k
			b NULL
::102			b "(c) '97/98/99: Markus Kanet",NULL
::103			b "EMail: ",NULL
::104			b "Adapted to GEOS128-80 columns:",NULL
::105			b "Wolfgang Grimm, MegaCom Software",NULL
::106			b "EMail: ",NULL
::107			b "",NULL

;*** Dialobox Auswahl GEOS-Dateityp.
:DlgGeosType		b $01
			b $18,$b7
			w $0008,$012f
			b DB_USR_ROUT
			w SetGeosType
			b DBOPVEC
			w TestMouse1
			b NULL

;*** Dialogbox Auswahl CBM-Dateityp.
:DlgCBM_Type		b $81
			b DBUSRICON    ,$02,$18
			w iconDataSEQ
			b DBUSRICON    ,$02,$30
			w iconDataPRG
			b CANCEL       ,$10,$48
			b DBTXTSTR     ,$10,$0e
			w :101
			b DBTXTSTR     ,$38,$1e
			w :102
			b DBTXTSTR     ,$38,$28
			w :103
			b DBTXTSTR     ,$38,$36
			w :102
			b DBTXTSTR     ,$38,$40
			w :104
			b NULL

::101			b BOLDON,"Select fileformat:",PLAINTEXT,NULL
::102			b BOLDON,"Create convert-file",NULL
::103			b        "type 'SEQ'.",NULL
::104			b        "type 'PRG'.",PLAINTEXT,NULL

;*** Daten für "PRG"-Icon.
:iconDataPRG		w icon_PRG
			b $00,$00,$04,$10
			w SlctFileTypPRG

;*** Daten für "SEQ"-Icon.
:iconDataSEQ		w icon_SEQ
			b $00,$00,$04,$10
			w SlctFileTypCBM

;*** Dialobox für Diskettenfehler.
:DlgDiskError		b $01
			b $20,$5f
			w $0040,$00ff
			b DBVARSTR    ,$10,$0f
			b r5L
			b DBTXTSTR    ,$10,$1d
			w DlgDskErrDrvT
			b OK          ,$11,$28
			b NULL

:DlgDskErrDrvT		b BOLDON,"(Drive "
:DlgDskErrDrvTa		b "x:)",NULL

;*** Name D64-Datei eingeben.
:DlgGetFileName		b $01
			b $20,$5f
			w $0040,$00ff
			b DBTXTSTR    ,$10,$0f
			w :101
			b DBGETSTRING ,$10,$14
			b r5L, 16
			b CANCEL      ,$11,$28
			b NULL

::101			b PLAINTEXT,BOLDON
			b "Name of D64-file:",NULL
endif

if Sprache = Englisch
;*** Dialogobx: "Dateiname nicht gefunden!"
:DlgNoFileName		b $81
			b DBTXTSTR    ,$10,$0e
			w :101
			b DBTXTSTR    ,$10,$1e
			w :102
			b DBTXTSTR    ,$10,$29
			w :103
			b OK          ,$02,$48
			b NULL

::101			b PLAINTEXT
			b BOLDON   ,"Fatal error!",PLAINTEXT,NULL
::102			b           "No filename found in",BOLDON,NULL
::103			b           "UUE-converted file!",NULL

;*** Dialogbox: "'END' nicht gefunden!"
:DlgEndNotFound		b $81
			b DBTXTSTR    ,$10,$0e
			w :101
			b DBTXTSTR    ,$10,$1e
			w :102
			b DBTXTSTR    ,$10,$29
			w :103
			b OK          ,$02,$48
			b NULL

::101			b PLAINTEXT
			b BOLDON   ,"Fatal error!",PLAINTEXT,NULL
::102			b           "End of the UUE-encoded",BOLDON,NULL
::103			b           "file not found!",NULL

;*** Laufwerksauswahl.
:DlgSlctTgtDrv		b $81

			b DBTXTSTR     ,$10,$0e
			w FileBoxTitle2
			b CANCEL       ,$02,$48
:DlgDrv1b		b DBUSRICON    ,$02,$20
			w DriveIconA
:DlgDrv2b		b DBUSRICON    ,$06,$20
			w DriveIconB
:DlgDrv3b		b DBUSRICON    ,$0a,$20
			w DriveIconC
:DlgDrv4b		b DBUSRICON    ,$0e,$20
			w DriveIconD
			b NULL

:FileBoxTitle2		b PLAINTEXT,BOLDON
			b "Select target-drive:",NULL

:DriveIconA		w Icon_01
			b $00,$00,$02,$10
			w TargetDriveA

:DriveIconB		w Icon_02
			b $00,$00,$02,$10
			w TargetDriveB

:DriveIconC		w Icon_03
			b $00,$00,$02,$10
			w TargetDriveC

:DriveIconD		w Icon_04
			b $00,$00,$02,$10
			w TargetDriveD

;*** Max. Größe SEQ-Datei.
:DlgGetMaxSize		b $01
			b $20,$5f
			w $0040,$00ff
			b DBTXTSTR    ,$10,$0f
			w :101
			b DBGETSTRING ,$10,$14
			b r5L, 3
			b CANCEL      ,$11,$28
			b NULL

::101			b PLAINTEXT,BOLDON
			b "Max. size in KByte:",NULL
endif

;*** DRIVE-Icon.
:icon_PRG

:icon_SEQ

:Icon_01
:Icon_01x		= .x
:Icon_01y		= .y

:Icon_02
:Icon_02x		= .x
:Icon_02y		= .y

:Icon_03
:Icon_03x		= .x
:Icon_03y		= .y

:Icon_04
:Icon_04x		= .x
:Icon_04y		= .y

;*** Start Sektordaten für D64.
:StartSekTab
