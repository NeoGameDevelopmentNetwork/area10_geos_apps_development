; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;geoConvert
;Hauptmenü
if .p
			t "TopSym"
			t "TopMac"
			t "src.geoConve.ext"
endif

			n "mod.#7"
			o VLIR_BASE
;*** Menü starten.
:START_MAIN_MENU	jsr	SetMenuData		;Menüdaten aktualisieren.

			ldx	MenuJob			;Menüfunktion aufrufen.
			beq	Local_ResetMenu
			dex
			beq	Local_OpenMain
			dex
			beq	Local_ReadDirEntries

;*** Hauptmenü & Dateiauswahl initialisieren.
:Local_ResetMenu	lda	#$00			;Zeiger auf Tabellenanfang
			sta	CurFNameEntryInMenu	;für Dateiliste.

;*** Hauptmenü aktivieren.
:Local_OpenMain		lda	#$00			;Modus "Dateien zusammenfügen"
			sta	Option_SEQ_Merge	;zurücksetzen.
			LoadW	curMenu,Menu_Main	;Zeiger auf Hauptmenü.
			jmp	StartMenu		;Hauptmenü öffnen.

;*** Dateilistenmenü aktivieren.
:Local_ReadDirEntries	jsr	ReadDirEntryToBuf	;Dateien einlesen.
:Local_StartMenu	jsr	ClrScreen		;Bildschirm löschen.

			MoveW	curMenu,r0		;Hauptmenü aufrufen.
			lda	#$01
			jsr	DoMenu
			jmp	SetStdMsePos

;*** Name der aktuellen Diskette in Menü aufnehmen.
:SetMenuData_DiskName	pha
			ldy	#0
			lda	#" "
::101			sta	(r10L),y
			iny
			cpy	#16
			bne	:101
			pla
			jsr	SetDevice
			txa
			bne	:102
			jsr	OpenDisk
			txa
			bne	:102
			ldy	#0
::104			lda	(r5L),y
			sta	(r10L),y
			iny
			cpy	#16
			bne	:104
::102			rts

;*** Menüdaten initialisieren.
:SetMenuData		ldx	#PLAINTEXT		;Alle Laufwerke aktivieren.
			stx	Laufwerk01+1
			stx	Laufwerk02+1
			stx	Laufwerk03+1
			stx	Laufwerk04+1

			ldx	#ITALICON		;Nicht installierte Laufwerke
			lda	driveType+0		;kursiv darstellen und Menüeinrag
			bne	:101			;deaktivieren.
			stx	Laufwerk01+1
			LoadW	Laufwerk01Job,ReDoMenu
::101			lda	driveType+1
			bne	:102
			stx	Laufwerk02+1
			LoadW	Laufwerk02Job,ReDoMenu
::102			lda	driveType+2
			bne	:103
			stx	Laufwerk03+1
			LoadW	Laufwerk03Job,ReDoMenu
::103			lda	driveType+3
			bne	:104
			stx	Laufwerk04+1
			LoadW	Laufwerk04Job,ReDoMenu

::104			lda	SourceDrive		;Anzeige Quell-Laufwerk.
			add	$39
			sta	Parameter03a
			LoadW	r10,Menu_DskNmSource1
			lda	SourceDrive		;Anzeige Quell-Laufwerk.
			jsr	SetMenuData_DiskName

			lda	TargetDrive		;Anzeige Ziel-Laufwerk.
			add	$39
			sta	Parameter09a
			LoadW	r10,Menu_DskNmTarget1
			lda	TargetDrive		;Anzeige Quell-Laufwerk.
			jsr	SetMenuData_DiskName

			lda	Option_CBMFileType	;Ziel-Dateityp festlegen.
			cmp	#$82			;"PRG" ?
			beq	:105			;Ja, weiter...
			lda	#"S"			;CBM-Dateityp "SEQ".
			ldx	#"E"
			ldy	#"Q"
			bne	:106
::105			lda	#"P"			;CBM-Dateityp "PRG".
			ldx	#"R"
			ldy	#"G"
::106			sta	Parameter02a +2
			stx	Parameter02a +3
			sty	Parameter02a +4

			lda	#" "			;LineFeed-Modus in Menü löschen.
			sta	LF_Text02
			sta	LF_Text03
			sta	LF_Text04

			lda	#<LF_Text02
			ldx	#>LF_Text02
			ldy	Option_LineFeedMode
			dey				;LF: CR?
			beq	:107			;Ja, weiter...
			lda	#<LF_Text03
			ldx	#>LF_Text03
			dey				;LF: CR+LF?
			beq	:107			;Ja, weiter...
			lda	#<LF_Text04		;LF: LF
			ldx	#>LF_Text04
::107			sta	r0L
			stx	r0H
			ldy	#$00			;LineFeed-Modus markieren.
			lda	#"*"
			sta	(r0L),y

			jsr	ShowTextMode		;Textmodus anzeigen.
			jsr	GetMaxSizeASCII		;Max. Größe SEQ-Datei in ASCII umwandeln.
			sty	Parameter08a +1
			stx	Parameter08a +2
			sta	Parameter08a +3

			lda	#" "			;Nur GEOS-Dateien konvertieren wenn
			ldx	GEOSValidTypeList+1	;"Alle Dateien konvertieren" gewählt wird?
			beq	:108			;CBM-Dateien anzeigen?
			lda	#"X"			;Nein...
::108			sta	ModusText02b+3
			rts

;*** Konvertierungsmodus wählen.
;*** Disk nach D64/D71/D81 wandeln.
:ConvDImg_Mode_01	lda	#ConvMode_DISK_D64	;Disk => D64
			b $2c
:ConvDImg_Mode_02	lda	#ConvMode_DISK_D71	;Disk => D71
			b $2c
:ConvDImg_Mode_03	lda	#ConvMode_DISK_D81	;Disk => D81
			sta	FileConvMode		;Konvertierungsmodus merken.

			jsr	GotoFirstMenu		;Zurück zum Hauptmenü.
			jsr	ClrScreen		;Bildschirm löschen.
			jmp	Mod_DskImg_Create	;Konvertierungsmodul nachladen.

;*** Alle Dateien von/nach CVT wandeln.
:ConvCVT_Mode_01	lda	#ConvMode_CVT_ALL_FILES	;DAlle Dateien von/nach CVT.
			sta	FileConvMode		;Konvertierungsmodus merken.

			jsr	GotoFirstMenu		;Zurück zum Hauptmenü.
			jsr	ClrScreen		;Bildschirm löschen.
			jmp	Mod_Convert_CVT		;Konvertierungsmodul nachladen.

;*** Dateien umwandeln.
;    Bei dieseen Funktionen wird zuerst das Dateilisten-Menü angezeigt.
;    Nach Auswahl einer Datei wird das entsprechende Konvertierungsmodul nachgeladen.
:ConvCVT_Mode_02	lda	#ConvMode_GEOS_CBM	;GEOS => CBM
			b $2c
:ConvCVT_Mode_03	lda	#ConvMode_CBM_GEOS	;CBM => GEOS
			b $2c
:ConvUUE_Mode_01	lda	#ConvMode_SEQ_UUE	;SEQ => UUE
			b $2c
:ConvUUE_Mode_02	lda	#ConvMode_SEQ_UUEadd	;SEQ an UUE anhängen
			b $2c
:ConvUUE_Mode_03	lda	#ConvMode_UUE_SEQ	;UUE nach SEQ
			b $2c
:ConvSEQ_Mode_01	lda	#ConvMode_SPLIT_FILE	;Dateien aufteilen
			b $2c
:ConvSEQ_Mode_02	lda	#ConvMode_MERGE_FILE	;Dateien zusammenfügen
			b $2c
;*** D64 entpacken.
:ConvDImg_Mode_04	lda	#ConvMode_D64_DISK	;D64 => Disk
			b $2c
:ConvDImg_Mode_05	lda	#ConvMode_D64_FILE	;D64 => Datei
			b $2c
;*** D71 entpacken.
:ConvDImg_Mode_06	lda	#ConvMode_D71_DISK	;D71 => Disk
			b $2c
:ConvDImg_Mode_07	lda	#ConvMode_D71_FILE	;D71 => Datei
			b $2c
;*** D81 entpacken.
:ConvDImg_Mode_08	lda	#ConvMode_D81_DISK	;D81 => Disk
			b $2c
:ConvDImg_Mode_09	lda	#ConvMode_D81_FILE	;D81 => Datei
			sta	FileConvMode		;Konvertierungsmodus merken.

			jsr	GotoFirstMenu		;Zurück zum Hauptmenü.
			jsr	ClrScreen		;Bildschirm löschen.

			lda	#$00			;Zeiger auf ersten Eintrag in
			sta	CurFNameEntryInMenu	;Datei-Menü richten.
			jmp	OpenFiles		;Datei-Menü aktivieren.

;*** GEOS-Dateityp wählen.
:SlctValidGEOSTypes	lda	mouseData		;Warten bis keine Maustaste
			bpl	SlctValidGEOSTypes	;gedrückt ist.
			LoadB	pressFlag,NULL

			lda	#$09			;Dateityp-Fenster aufbauen.
			jsr	SetPattern
			jsr	i_Rectangle
			b	$18,$25
			w	$0009,$012e

			LoadW	r0,HeaderSlctGTypes	;Menü-Überschrift anzeigen.
			jsr	PutString

			lda	#$00			;GEOS-Klassen-Zähler auf Anfang.
			sta	a0L

::101			jsr	GetXYOptionPos		;Koordinaten für Ausgabe
							;der GEOS-Klassen berechnen.

			lda	r3L 			;X-Koordinate für Beschreibung ermitteln.
			clc
			adc	#$10
			sta	r11L
			lda	r3H
			adc	#$00
			sta	r11H

			clc				;Y-Koordinate für Beschreibung ermitteln.
			lda	r2L
			adc	#$06
			sta	r1H

			LoadB	currentMode,SET_BOLD

			ldx	a0L			;Alle/Keine GEOS-Klassen ausgewählt?
			bne	:102			;Nein, weiter...
			lda	#<GTypeAll		;Name für Schalter "Alle Dateien"
			ldy	#>GTypeAll
			jmp	:103

::102			dex				;Zeiger auf Name für GEOS-Klasse ermitteln.
			lda	GTypeCode,x
			asl
			tax
			lda	GTypeVector +0,x
			ldy	GTypeVector +1,x

::103			sta	r0L 			;Name für Menüschalter ausgeben.
			sty	r0H
			jsr	PutString

			inc	a0L			;Zeiger auf nächsten Eintrag.
			lda	a0L
			cmp	#MaxGEOSFileTypes	;Alle Einträge ausgegeben?
			bne	:101			;Nein, weiter...

;*** Einstellungen anzeigen.
:ViewGEOStype		lda	#$00			;GEOS-Klassen-Zähler auf Anfang.
			sta	a0L

::101			jsr	GetXYOptionPos		;Koordinaten für Schalter
							;der GEOS-Klassen berechnen.

			ldy	#$00			;Muster für Optionswahl
			ldx	a0L			;berechnen und anzeigen.
			beq	:102
			dex
			lda	GTypeCode,x		;anwählen/abwählen.
			tax
			inx
::102			lda	GEOSValidTypeList,x
			bne	:104
::103			iny				;Füllmuster $01 = Ein.
::104			tya				;Füllmuster $00 = Aus.
			jsr	SetPattern
			jsr	Rectangle		;Schalter ein/aus darstellen.
			dec	r2L			;Rahmen zeichnen.
			inc	r2H
			dec	r3L
			inc	r4L
			lda	#%11111111
			jsr	FrameRectangle

			inc	a0L			;Zeiger auf nächste GEOS-Klasse.
			lda	a0L
			cmp	#MaxGEOSFileTypes	;Alle GEOS-Klasse angezeigt?
			bne	:101			;Nein, weiter...
			rts

;*** Maus abfragen für GEOS-Dateityp-Auswahl.
:SwitchGType_OnOff	lda	#$00			;Zeiger auf ersten Eintrag:
			sta	a0L			;=> "Alle Dateien".

::101			jsr	GetXYOptionPos		;Koordinaten für Auswahl
			SubVW	8,r3			;der GEOS-Typen berechnen.
			AddVW	8,r4			;Auswahlbereich etwas vergrößeren
			SubVB	3,r2L			;=> erleichtert das auswählen.
			AddVB	3,r2H

			jsr	IsMseInRegion		;Maus abfragen.
			tax				;Maus im Bereich ?
			beq	:104			;Nein, weitertesten...

			ldx	a0L			;Erster Eintrag = "Alle Dateien"?
			bne	:102			;Nein, weiter...
			lda	GEOSValidTypeList	;Alle Dateitypen wählen bzw. abwählen.
			eor	#%11111111		;"Alle Dateien"-Flag invertieren und
			sta	:101a			;als neuen Füllwert für Switch setzen.

			jsr	i_FillRam		;Switch für "Alle Dateien" ein-
			w	32			;oder ausschalten.
			w	GEOSValidTypeList
::101a			b	$ff
			jmp	:102a

::102			ldx	a0L			;Gewählten GEOS-Dateityp
			dex
			lda	GTypeCode,x		;anwählen/abwählen.
			tax
			inx
			lda	GEOSValidTypeList,x
			eor	#%11111111
			sta	GEOSValidTypeList,x
::102a			jsr	ViewGEOStype		;Neuen Status für Dateityp anzeigen.

::103			lda	mouseData		;Warten bis keine Maustaste
			bpl	:103			;gedrückt ist.
			LoadB	pressFlag,NULL
			rts

::104			inc	a0L
			lda	a0L
			cmp	#MaxGEOSFileTypes
			bne	:101

			jmp	RstrFrmDialogue

;*** X/Y-Koordinaten für Optionsbereiche und Dateityp-Auswahl berechnen.
;    A: Eintragsnummer 0-19
:GetXYOptionPos		ldy	#$00			;Zeiger auf Spalte 1.
			cmp	#10			;Eintrag 0-9 ?
			bcc	:101			;Ja, weiter...
			sec				;Eintrag 10-19
			sbc	#10
			iny				;Zeiger auf Spalte 1.

::101			tax				;Y-Koordinaten "oben" berechnen.
			lda	#$2c			;Startwert für erste Zeile.
::102			cpx	#$00			;Zeile erreicht?
			beq	:103			;Ja, weiter...
			clc				;Y-Koordinaten "oben" auf
			adc	#14			;nächste Zeile setzen.
			dex				;Zeile erreicht?
			bne	:102			;Nein, weiter...

::103			sta	r2L			;Y-Koordinaten "oben" speichern.
			clc				;Y-Koordinaten "unten" berechnen.
			adc	#06
			sta	r2H

			tya				;Spalte 0 oder 1?
			bne	:104			;Spalte 1, weiter...
			LoadW	r3,$0021		;X-Werte für Spalte 0 setzen.
			LoadW	r4,$0026
			rts

::104			LoadW	r3,$00a1		;X-Werte für Spalte 1 setzen.
			LoadW	r4,$00a6
			rts

;*** Option "Nur GEOS Dateien" bei "Alle Dateien konvertieren" wechseln.
:SwitchModeCvtAllFiles	lda	GEOSValidTypeList+1
			eor	#%11111111
			sta	GEOSValidTypeList+1
			jsr	SetMenuData
			jmp	ReDoMenu

;*** GEOS-Dateityp wählen.
:SlctGeosFileType	jsr	GotoFirstMenu		;Zurück zum Hauptmenü.
			jsr	ClrScreen		;Bildschirm löschen.
			LoadW	r0,DlgSlctGeosTypes
			jsr	DoDlgBox		;GEOS-Dateitypen auswählen.
			jsr	SetMenuData		;Menü für Option "Nur GEOS-Dateien konvertieren" aktualisieren.
			jmp	ResetMenu		;Hauptmenü aktivieren.

;*** CBM-Dateityp wählen.
:SlctCBM_FileType	jsr	RecoverMenu		;Menü löschen.
			LoadW	r0,DlgSlctCBMType
			jsr	DoDlgBox		;CBM-Dateityp auswählen.
			LoadB	mouseYPos,$24
			LoadW	mouseXPos,$0080		;Mauszeiger setzen.
			jmp	ReDoMenu		;Parameter-Menü aktivieren.

;*** Datei-Format wählen..
:SetCBMFileTypeSEQ	lda	#$81			;Zieldatei-Format SEQ.
			b $2c
:SetCBMFileTypePRG	lda	#$82			;Zieldatei-Format PRG.
			sta	Option_CBMFileType
			jsr	SetMenuData		;Menüanzeige aktualisieren.
			jmp	RstrFrmDialogue

;*** Laufwerk wählen.
:SourceDriveA		lda	#8			;Quell-Laufwerk A:
			b $2c
:SourceDriveB		lda	#9			;Quell-Laufwerk B:
			b $2c
:SourceDriveC		lda	#10			;Quell-Laufwerk C:
			b $2c
:SourceDriveD		lda	#11			;Quell-Laufwerk D:
			sta	SourceDrive		;Quell-Laufwerk festlegen.
			jsr	InitFileSlctMenu	;Dateien einlesen.
			jsr	SetMenuData		;Menüanzeige aktualisieren.
			LoadB	mouseYPos,$16
			LoadW	mouseXPos,$0080		;Mauszeiger setzen.
			jmp	DoPreviousMenu

;*** Ziel-Laufwerk wählen.
;Mit Ausnahme von GEOS-CVT werden Dateien als Kopie abgelegt.
;Die Kopie wird auf dem Ziel-Laufwerk abgelegt.
:TargetDriveA		lda	#8			;Ziel-Laufwerk A:
			b $2c
:TargetDriveB		lda	#9			;Ziel-Laufwerk B:
			b $2c
:TargetDriveC		lda	#10			;Ziel-Laufwerk C:
			b $2c
:TargetDriveD		lda	#11			;Ziel-Laufwerk D:
			sta	TargetDrive		;Ziel-Laufwerk festlegen.
			jsr	SetMenuData		;Menüanzeige aktualisieren.
			LoadB	mouseYPos,$32
			LoadW	mouseXPos,$0080		;Mauszeiger setzen.
			jmp	DoPreviousMenu

;*** Neue Diskette einlegen.
:InsertNewDiskSource	lda	SourceDrive
			bne	InsertNewDisk
:InsertNewDiskTarget	lda	TargetDrive
:InsertNewDisk		pha
			jsr	SetDevice
			jsr	GotoFirstMenu
			jsr	DialogBoxNewDisk	;Neue Diskette einlegen.
			pla
			cmp	SourceDrive
			bne	:101

			jsr	InitFileSlctMenu	;Dateien einlesen.
::101			jmp	SetMenuData		;Menüanzeige aktualisieren.

;*** Linefeed-Modus wählen.
:ConvToUUE_CR		lda	#$01			;LineFeed "CR"
			b $2c
:ConvToUUE_CRLF		lda	#$02			;LineFeed "CR+LF"
			b $2c
:ConvToUUE_LF		lda	#$03			;LineFeed "LF"
			sta	Option_LineFeedMode
			jsr	SetMenuData		;Menüanzeige aktualisieren.
			LoadB	mouseYPos,$5c
			LoadW	mouseXPos,$0080		;Mauszeiger setzen.
			jmp	DoPreviousMenu		;Zurück zum Parameter-Menü.

;*** Textmodus für UUE wechseln (Texte/Programme).
;    je nach Modus werden angehängte Dateien UUE kodiert (Programme)
;    oder nicht kodiert (Texte).
:SwapTextMode		lda	Option_ConvFileToUUE
			eor	#$ff
			sta	Option_ConvFileToUUE
			jsr	ShowTextMode
			jmp	ReDoMenu

;*** Aktuellen Textmodus anzeigen.
:ShowTextMode		ldx	#<Parameter07a		;Texte.
			ldy	#>Parameter07a
			lda	Option_ConvFileToUUE
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
			sty	Option_SEQ_InputBuf
			ldy	#"1"
			bne	:104a
::104			cpx	#"0"
			beq	:105
::104a			pha
			txa
			sta	Option_SEQ_InputBuf -$30,y
			pla
			iny
::105			sta	Option_SEQ_InputBuf -$30,y
			iny
			lda	#$00
			sta	Option_SEQ_InputBuf -$30,y

			LoadW	r0,DlgGetMaxSize
			LoadW	r5,Option_SEQ_InputBuf
			jsr	DoDlgBox		;Dateigröße eingeben.

			lda	Option_SEQ_InputBuf +0	;Wurde Text eingegeben ?
			beq	:111			;Nein, abbruch...

::106			ldx	#$00			;ASCII-Texteingabe nach
			ldy	Option_SEQ_InputBuf +1	;Dezimalwert umwandeln.
			beq	:107
			tax
			tya
			ldy	Option_SEQ_InputBuf +2
			beq	:107
			pha
			txa
			tay
			pla
			tax
			lda	Option_SEQ_InputBuf +2
::107			sec
			sbc	#"0"
::108			cpx	#"1"
			bcc	:109
			clc
			adc	#10
			dex
			bne	:108
::109			cpy	#"1"
			bcc	:110
			clc
			adc	#100
			dey
			bne	:109
::110			sta	Option_SEQ_MaxSize	;Max. Größe merken.
			jsr	SetMenuData		;Menüanzeige aktualisieren.

			LoadB	mouseYPos,$78
			LoadW	mouseXPos,$0080		;Mauszeiger setzen.
::111			jmp	ReDoMenu		;Zurück zum Parameter-Menü.

;*** Max. Dateigröße in ASCII umwandeln.
:GetMaxSizeASCII	ldy	#"0"
			ldx	#"0"
			lda	Option_SEQ_MaxSize
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

;*** Gespeicherte Parameter aus Infoblock laden.
:ReLoadParameter	jsr	LoadParameter		;Parameter aus Infoblock einelssen.
			txa				;Fehler? $07=Keine gespeicherten Parameter.
			bne	:101			;Ja, Abbruch...
			jsr	SetMenuData		;Menudaten aktualisieren.
			jmp	GotoFirstMenu		;Zurück zum Hauptmenü.
::101			jmp	ExitDiskErr		;Fehler ausgeben.

;*** Parameter in InfoBlock speichern.
:SaveParameter		jsr	FindGConv		;geoConvert suchen.
			txa				;Gefunden?
			beq	:102			;Ja, weiter...
::101			jmp	ExitDiskErr

::102			lda	dirEntryBuf +19		;Zeiger  auf Inffoblockk einlesen.
			sta	r1L
			lda	dirEntryBuf +20
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Infoblock laden.
			txa				;Diskettenfehler?
			bne	:101			;Ja, Abbruch...

			lda	#VMajor			;Systemkennung setzen.
			sta	diskBlkBuf +$89
			lda	#VMinor
			sta	diskBlkBuf +$8a

			lda	SourceDrive		;Quell-/Ziel-Laufwerk speichern.
			sta	diskBlkBuf +$8b
			lda	TargetDrive
			sta	diskBlkBuf +$8c

			lda	Option_ConvFileToUUE	;Konvertierungsoptionen speichern.
			sta	diskBlkBuf +$8d
			lda	Option_LineFeedMode
			sta	diskBlkBuf +$8e
			lda	Option_CBMFileType
			sta	diskBlkBuf +$8f
			lda	Option_SEQ_MaxSize
			sta	diskBlkBuf +$90

			lda	#<diskBlkBuf +$91	;GEOS-Klassen für Dateiliste bei
			sta	r2L			;Konvertierung von GEOS-CBM speichern.
			lda	#>diskBlkBuf +$91
			sta	r2H
			LoadW	r3,GEOSValidTypeList
			LoadB	r4L,4

::103			ldx	#$08			;Aus  Platzgründen 8 Bytes in 8 Bit speichern.
			ldy	#$00
::104			lda	(r3L),y
			beq	:105
			clc
			bcc	:106
::105			sec
::106			lda	(r2L),y
			ror
			sta	(r2L),y
			inc	r3L
			bne	:107
			inc	r3H

::107			dex
			bne	:104

			inc	r2L
			bne	:108
			inc	r2H
::108			dec	r4L
			bne	:103

			LoadW	r4,diskBlkBuf		;Infoblock mit Parametern speichern.
			jsr	PutBlock
			txa
			beq	:109
			jmp	ExitDiskErr

::109			jmp	GotoFirstMenu		;Zurück zum Hauptmenü.

;*** Info ausgeben.
:PrintInfoBox		jsr	GotoFirstMenu		;Zurück zum Hauptmenü.

			LoadW	r0,DlgInfoBox
			jmp	DoDlgBox		;Infobox ausgeben.

;*** Infobox.
:DlgInfoBox		b $01
			b $30,$a2
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
			b DBTXTSTR    ,$10,$64
			w :108
			b DBSYSOPV
			b NULL

::101			b PLAINTEXT,BOLDON
			b "geoConvert V"
			b VMajor,".",VMinor,VMicro
			b "-"
			k
			b NULL
::102			b PLAINTEXT,"(c) 1997-1999,2018-2021:",NULL
::103			b BOLDON   ,"Markus Kanet",NULL

if Sprache = Deutsch
::104			b PLAINTEXT,"Die Veröffentlichung dieses Programms erfolgt",NULL
::105			b           "in der Hoffnung, daß es Ihnen von Nutzen sein",NULL
::106			b           "wird, aber OHNE IRGENDEINE GARANTIE, sogar ohne",NULL
::107			b           "die implizite Garantie der MARKTREIFE oder der",NULL
::108			b           "VERWENDBARKEIT FÜR EINEN BESTIMMTEN ZWECK.",NULL
endif
if Sprache = Englisch
::104			b PLAINTEXT,"This program is distributed in the hope that",NULL
::105			b           "it will be useful, but WITHOUT ANY WARRANTY;",NULL
::106			b           "without even the implied warranty of",NULL
::107			b           "MERCHANTABILITY or FITNESS FOR A PARTICULAR",NULL
::108			b           "PURPOSE.",NULL
endif

;*** Hauptmenu.
:Menu_Main		b $00
			b $00 + 1*14 +1
			w $0000
if Sprache = Deutsch
			w $0083
endif
if Sprache = Englisch
			w $0071
endif

			b 4 ! HORIZONTAL ! UN_CONSTRAINED

			w Main01
			b SUB_MENU
			w Menu_GEOS

			w Main02
			b SUB_MENU
			w Menu_Parameter

			w Main03
			b SUB_MENU
			w Menu_Modus1

			w Main04
			b SUB_MENU
			w Menu_Modus2

if Sprache = Deutsch
:Main01			b "geos",NULL
:Main02			b "Parameter",NULL
:Main03			b "Datei",NULL
:Main04			b "Disk",NULL
endif
if Sprache = Englisch
:Main01			b "geos",NULL
:Main02			b "Options",NULL
:Main03			b "File",NULL
:Main04			b "Disk",NULL
endif

;*** Menü "GEOS".
:Menu_GEOS		b $0f
			b $0f + 2*14 +1
			w $0000
			w $0000 + 71

			b $02 ! VERTICAL ! UN_CONSTRAINED

			w File01
			b MENU_ACTION
			w PrintInfoBox

			w File02
			b MENU_ACTION
			w ExitToDeskTop

if Sprache = Deutsch
:File01			b "Information",NULL
:File02			b "Verlassen",NULL
endif
if Sprache = Englisch
:File01			b "Information",NULL
:File02			b "Exit",NULL
endif

;*** Daten für Menü Parameter.
:Menu_Parameter		b $0f
			b $0f + 11*14 +1
			w $001c
			w $001c +154

			b 11 ! VERTICAL ! UN_CONSTRAINED

			w Parameter03
			b SUB_MENU
			w SlctSourceDrv

			w Menu_DskNmSource
			b MENU_ACTION
			w InsertNewDiskSource

			w Parameter09
			b SUB_MENU
			w SlctTargetDrv

			w Menu_DskNmTarget
			b MENU_ACTION
			w InsertNewDiskTarget

			w Parameter01
			b MENU_ACTION
			w SlctGeosFileType

			w Parameter02
			b MENU_ACTION
			w SlctCBM_FileType

			w Parameter06
			b SUB_MENU
			w Menu_LF

			w Parameter07
			b MENU_ACTION
			w SwapTextMode

			w Parameter08
			b MENU_ACTION
			w GetMaxSize

			w Parameter10
			b MENU_ACTION
			w SaveParameter

			w Parameter11
			b MENU_ACTION
			w ReLoadParameter

if Sprache = Deutsch
:Parameter01		b "Dateityp festlegen: GEOS",NULL
:Parameter02		b "Dateityp festlegen: CBM"
:Parameter02a		b " (PRG)",NULL
:Parameter03		b PLAINTEXT,BOLDON
			b "Daten auf Laufwerk "
:Parameter03a		b "A:",PLAINTEXT,NULL
:Parameter05		b "CVT: Alle Dateien konvertieren "
:Parameter05a		b "( )",NULL
:Parameter06		b "UUE: LineFeed-Modus wählen",NULL
:Parameter07		b "UUE: 1234567890123456",NULL
:Parameter07a		b "Texte",NULL
:Parameter07b		b "Programme",NULL
:Parameter08		b "SEQ: Max. Dateigröße "
:Parameter08a		b "(000 Kb)",NULL
:Parameter09		b PLAINTEXT,BOLDON
			b "Ziel-Laufwerk "
:Parameter09a		b "A:",PLAINTEXT,NULL
:Parameter10		b "Parameter speichern",NULL
:Parameter11		b "Parameter laden",NULL
endif
if Sprache = Englisch
:Parameter01		b "Select file type: GEOS",NULL
:Parameter02		b "Select file type: CBM  "
:Parameter02a		b " (PRG)",NULL
:Parameter03		b PLAINTEXT,BOLDON
			b "Data on drive "
:Parameter03a		b "A:",PLAINTEXT,NULL
:Parameter05		b "CVT: Convert all files "
:Parameter05a		b "( )",NULL
:Parameter06		b "UUE: Select LineFeed-Mode",NULL
:Parameter07		b "UUE: 1234567890123456",NULL
:Parameter07a		b "Documents",NULL
:Parameter07b		b "Programms",NULL
:Parameter08		b "SEQ: Max. Filesize "
:Parameter08a		b "(000 Kb)",NULL
:Parameter09		b PLAINTEXT,BOLDON
			b "Target drive "
:Parameter09a		b "A:",PLAINTEXT,NULL
:Parameter10		b "Save options",NULL
:Parameter11		b "Load options",NULL
endif

:Menu_DskNmSource	b " -> "
:Menu_DskNmSource1	s 17

:Menu_DskNmTarget	b " -> "
:Menu_DskNmTarget1	s 17

;*** Daten für Laufwerksauswahl.
:SlctSourceDrv		b $17
			b $17 + 4*14 +1
			w $0080
			w $00c8

			b 4 ! VERTICAL ! UN_CONSTRAINED

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

;*** Daten für Laufwerksauswahl.
:SlctTargetDrv		b $33
			b $33 + 4*14 +1
			w $0080
			w $00c8

			b 4 ! VERTICAL ! UN_CONSTRAINED

			w Laufwerk01
			b MENU_ACTION
:Laufwerk01Job		w TargetDriveA

			w Laufwerk02
			b MENU_ACTION
:Laufwerk02Job		w TargetDriveB

			w Laufwerk03
			b MENU_ACTION
:Laufwerk03Job		w TargetDriveC

			w Laufwerk04
			b MENU_ACTION
:Laufwerk04Job		w TargetDriveD

if Sprache = Deutsch
:Laufwerk01		b PLAINTEXT,PLAINTEXT,"Laufwerk A:",PLAINTEXT,NULL
:Laufwerk02		b PLAINTEXT,PLAINTEXT,"Laufwerk B:",PLAINTEXT,NULL
:Laufwerk03		b PLAINTEXT,PLAINTEXT,"Laufwerk C:",PLAINTEXT,NULL
:Laufwerk04		b PLAINTEXT,PLAINTEXT,"Laufwerk D:",PLAINTEXT,NULL
endif
if Sprache = Englisch
:Laufwerk01		b PLAINTEXT,PLAINTEXT,"Drive A:",PLAINTEXT,NULL
:Laufwerk02		b PLAINTEXT,PLAINTEXT,"Drive B:",PLAINTEXT,NULL
:Laufwerk03		b PLAINTEXT,PLAINTEXT,"Drive C:",PLAINTEXT,NULL
:Laufwerk04		b PLAINTEXT,PLAINTEXT,"Drive D:",PLAINTEXT,NULL
endif

;*** LineFeed für UUE wählen.
:Menu_LF		b $5c
			b $5c + 4*14 +1
			w $0050
			w $00ff

			b 4 ! VERTICAL ! UN_CONSTRAINED

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

if Sprache = Deutsch
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
endif
if Sprache = Englisch
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
endif

;*** Konvertierungsmodus wählen.
:Menu_Modus1		b $0f
			b $0f + 12*14 +1
if Sprache = Deutsch
w $004e
			w $004e +146
endif
if Sprache = Englisch
w $0043
			w $0043 +146
endif

			b 12 ! VERTICAL ! UN_CONSTRAINED

			w ModusText00a
			b MENU_ACTION
			w ReDoMenu

			w ModusText01
			b MENU_ACTION
			w ConvCVT_Mode_02

			w ModusText02
			b MENU_ACTION
			w ConvCVT_Mode_03

			w ModusText02a
			b MENU_ACTION
			w ConvCVT_Mode_01

			w ModusText02b
			b MENU_ACTION
			w SwitchModeCvtAllFiles

			w ModusText00c
			b MENU_ACTION
			w ReDoMenu

			w ModusText09
			b MENU_ACTION
			w ConvSEQ_Mode_01

			w ModusText10
			b MENU_ACTION
			w ConvSEQ_Mode_02

			w ModusText00b
			b MENU_ACTION
			w ReDoMenu

			w ModusText03
			b MENU_ACTION
			w ConvUUE_Mode_01

			w ModusText04
			b MENU_ACTION
			w ConvUUE_Mode_02

			w ModusText05
			b MENU_ACTION
			w ConvUUE_Mode_03
if Sprache = Deutsch
:ModusText00a		b PLAINTEXT
			b BOLDON   ,"Umwandeln: CVT-Dateien",NULL
:ModusText01		b PLAINTEXT,"  GEOS => CBM.cvt",NULL
:ModusText02		b           "  CBM.cvt => GEOS",NULL
:ModusText02a		b           "  Alle Dateien konvertieren",NULL
:ModusText02b		b           "  (X) Nur GEOS-Dateien",NULL
:ModusText00b		b BOLDON   ,"Umwandeln: UUE-Dateien",NULL
:ModusText03		b PLAINTEXT,"  SEQ => UUE",NULL
:ModusText04		b           "  SEQ => an UUE anhängen",NULL
:ModusText05		b           "  UUE => SEQ",NULL
:ModusText00c		b BOLDON   ,"Bearbeiten: SEQ-Dateien",NULL
:ModusText09		b PLAINTEXT,"  Datei aufteilen",NULL
:ModusText10		b           "  Dateien zusammenfügen",NULL
endif
if Sprache = Englisch
:ModusText00a		b PLAINTEXT
			b BOLDON   ,"Convert: CVT-files",NULL
:ModusText01		b PLAINTEXT,"  GEOS => CBM.cvt",NULL
:ModusText02		b           "  CBM.cvt => GEOS",NULL
:ModusText02a		b           "  Convert all files",NULL
:ModusText02b		b           "  (X) GEOS files only",NULL
:ModusText00b		b BOLDON   ,"Convert: UUE-files",NULL
:ModusText03		b PLAINTEXT,"  SEQ => UUE",NULL
:ModusText04		b           "  SEQ => add to UUE",NULL
:ModusText05		b           "  UUE => SEQ",NULL
:ModusText00c		b BOLDON   ,"Edit: SEQ-files",NULL
:ModusText09		b PLAINTEXT,"  Split file",NULL
:ModusText10		b           "  Merge files",NULL
endif

;*** Disk-Modus wählen.
:Menu_Modus2		b $10
			b $10 + 12*14 +1
if Sprache = Deutsch
			w $006a
			w $006a +140
endif
if Sprache = Englisch
			w $0058
			w $0058 +140
endif

			b 12 ! VERTICAL ! UN_CONSTRAINED

			w ModusText80
			b MENU_ACTION
			w ReDoMenu

			w ModusText06			;Disk => D64
			b MENU_ACTION
			w ConvDImg_Mode_01

			w ModusText07			;D64 => Disk
			b MENU_ACTION
			w ConvDImg_Mode_04

			w ModusText08			;D64 => File
			b MENU_ACTION
			w ConvDImg_Mode_05

			w ModusText81
			b MENU_ACTION
			w ReDoMenu

			w ModusText14			;Disk => D71
			b MENU_ACTION
			w ConvDImg_Mode_02

			w ModusText15			;D71 => Disk
			b MENU_ACTION
			w ConvDImg_Mode_06

			w ModusText16			;D71 => Datei
			b MENU_ACTION
			w ConvDImg_Mode_07

			w ModusText82
			b MENU_ACTION
			w ReDoMenu

			w ModusText11			;Disk => D81
			b MENU_ACTION
			w ConvDImg_Mode_03

			w ModusText12			;D81 => Disk
			b MENU_ACTION
			w ConvDImg_Mode_08

			w ModusText13			;D81 => Datei
			b MENU_ACTION
			w ConvDImg_Mode_09

if Sprache = Deutsch
:ModusText80		b PLAINTEXT
			b BOLDON   ,"Umwandeln: D64",NULL
:ModusText06		b PLAINTEXT,"  Disk => D64",NULL
:ModusText07		b           "  D64 => Disk",NULL
:ModusText08		b           "  D64 => Datei",NULL
:ModusText81		b PLAINTEXT
			b BOLDON   ,"Umwandeln: D71",NULL
:ModusText14		b PLAINTEXT,"  Disk => D71",NULL
:ModusText15		b           "  D71 => Disk",NULL
:ModusText16		b           "  D71 => Datei",NULL
:ModusText82		b PLAINTEXT
			b BOLDON   ,"Umwandeln: D81",NULL
:ModusText11		b PLAINTEXT,"  Disk => D81",NULL
:ModusText12		b           "  D81 => Disk",NULL
:ModusText13		b           "  D81 => Datei",NULL
endif
if Sprache = Englisch
:ModusText80		b PLAINTEXT
			b BOLDON   ,"Convert: D64",NULL
:ModusText06		b PLAINTEXT,"  Disk => D64",NULL
:ModusText07		b           "  D64 => Disk",NULL
:ModusText08		b           "  D64 => File",NULL
:ModusText81		b PLAINTEXT
			b BOLDON   ,"Convert: D71",NULL
:ModusText14		b PLAINTEXT,"  Disk => D71",NULL
:ModusText15		b           "  D71 => Disk",NULL
:ModusText16		b           "  D71 => File",NULL
:ModusText82		b PLAINTEXT
			b BOLDON   ,"Convert: D81",NULL
:ModusText11		b PLAINTEXT,"  Disk => D81",NULL
:ModusText12		b           "  D81 => Disk",NULL
:ModusText13		b           "  D81 => File",NULL
endif

;*** Dialobox Auswahl GEOS-Dateityp.
:DlgSlctGeosTypes	b $01
			b $18,$b7
			w $0008,$012f
			b DB_USR_ROUT
			w SlctValidGEOSTypes
			b DBOPVEC
			w SwitchGType_OnOff
			b NULL

if Sprache = Deutsch
:HeaderSlctGTypes	b GOTOXY
			w $0018
			b $20
			b BOLDON," GEOS-Dateitypen für Dateiauswahl 'GEOS->CBM': ",NULL
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
endif
if Sprache = Englisch
:HeaderSlctGTypes	b GOTOXY
			w $0018
			b $20
			b BOLDON," GEOS filetypes for file selection 'GEOS->CBM' ",NULL
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
endif

:GTypeVector		w GType00,GType01,GType02,GType03
			w GType04,GType05,GType06,GType07
			w GType08,GType09,GType10,GType11
			w GType12,GType13,GType14,GType15
			w $0000  ,GType17,$0000  ,$0000
			w $0000  ,GType21,GType22,$0000
			w $0000  ,$0000  ,$0000  ,$0000
			w $0000  ,$0000  ,$0000  ,$0000

:GTypeCode		b $00,$01,$02,$03
			b $04,$05,$06,$07
			b $08,$09,$0a,$0b
			b $0c,$0d,$0e,$0f
			b $11,$15,$16

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

if Sprache = Deutsch
::101			b PLAINTEXT,BOLDON
			b "Max. Größe in KByte:",NULL
endif
if Sprache = Englisch
::101			b PLAINTEXT,BOLDON
			b "Max. size in KByte:",NULL
endif

;*** Dialogbox Auswahl CBM-Dateityp.
:DlgSlctCBMType		b $81
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

if Sprache = Deutsch
::101			b BOLDON,"Dateiformat wählen:",PLAINTEXT,NULL
::102			b BOLDON,"Konvertierte Datei vom",NULL
::103			b        "Typ 'SEQ' erstellen.",NULL
::104			b        "Typ 'PRG' erstellen.",PLAINTEXT,NULL
endif
if Sprache = Englisch
::101			b BOLDON,"Select fileformat:",PLAINTEXT,NULL
::102			b BOLDON,"Create convert-file",NULL
::103			b        "type 'SEQ'.",NULL
::104			b        "type 'PRG'.",PLAINTEXT,NULL
endif

;*** Daten für "PRG/SEQ"-Icon.
:iconDataPRG		w icon_PRG
			b $00,$00,$04,$10
			w SetCBMFileTypePRG
:iconDataSEQ		w icon_SEQ
			b $00,$00,$04,$10
			w SetCBMFileTypeSEQ

			t "icon.PRG_SEQ"
