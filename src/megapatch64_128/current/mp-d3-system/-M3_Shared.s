; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** SETUP
;******************************************************************************
;*** Alle erforderlichen Setup-Dateien vor dem erstellen der gepackten
;    Setup-Dateien suchen. Programm bei fehlenden Dateien beenden.
:MainInit		jsr	FindAllFiles
			txa				;Alle Dateien vorhanden?
			beq	:1			;Ja, weiter...
			jmp	EnterDeskTop		;Zurück zum DeskTop.

;*** Aufruf der Pack-Routine.
;    Es wird je ein Archiv für alle Dateigruppen erstellt.
::1			lda	#$01			;Kernel...
			jsr	CreateStartFile
			lda	#$02			;RBoot...
			jsr	CreateStartFile
			lda	#$03			;Laufwerkstreiber...
			jsr	CreateStartFile
			lda	#$04			;Hintergrundbilder...
			jsr	CreateStartFile
			lda	#$05			;Bildschirmschoner...
			jsr	CreateStartFile

			LoadW	r0,MkSetupName
			jsr	DeleteFile

			jmp	EnterDeskTop

;*** Konvertierung initialisieren.
:CreateStartFile	sta	FTypeMode		;Dateigruppe merken und
			clc				;Dateinamen/-klasse anpassen.
			adc	#"0"
			sta	SysFileNum1
			sta	SysFileNum2

			jsr	i_FillRam		;Variablen löschen.
			w	(End_DataBuf - Top_DataBuf)
			w	Top_DataBuf
			b	$00

			lda	#$00			;Bildschirm löschen.
			jsr	SetPattern
			jsr	i_Rectangle
			b	$00,$c7
			w	$0000
			w	$013f

;--- Dateiname des SetupMPxy-Files ausgeben.
			LoadW	r0,HdrFNameScrText
			LoadW	r11,$10
			LoadB	r1H,180
			jsr	PutString
			lda	#"."
			jsr	SmallPutChar
			lda	#"."
			jsr	SmallPutChar
			lda	#"."
			jsr	SmallPutChar
			lda	#" "
			jsr	SmallPutChar

;*** Alle benötigten Dateien innerhalb einer Gruppe suchen.
;    Diese Routine sollte keinen Fehler mehr erzeugen,
;    da bereits zu Beginn alle Dateien überprüft werden.
:FindGroupFiles		LoadW	r0,Info_00
			jsr	PutString

			lda	#$00			;Zähler für Dateinamen löschen.
			sta	a0L

::51			jsr	SetVecMP3FName		;Zeiger auf Dateiname einlesen.
			bne	:53			;Alle Dateien bearbeitet ?
			jmp	DoConvGEOS2CBM		; => Ja, weiter...

::53			jsr	FindFile		;GEOS-Datei suchen.
			txa				;Diskettenfehler ?
			beq	:52			; => Nein, weiter...

			jsr	SetVecMP3FName		;Zeiger auf Dateiname einlesen.
			LoadW	r0,Dlg_FileError
			jsr	DoDlgBox		;Fehler ausgeben und zurück
			jmp	EnterDeskTop		;zum DeskTop.

::52			inc	a0L			;Zeiger auf nächste Datei und
			jmp	:51			;weiter mit konvertieren...

;******************************************************************************
;*** Alle Dateien suchen.
;******************************************************************************
:FindAllFiles		lda	#$00			;Bildschirm löschen.
			jsr	SetPattern
			jsr	i_Rectangle
			b	$00,$c7
			w	$0000
			w	$013f

			LoadW	r0,TxFindAllFiles	;Statusmeldung ausgeben.
			LoadW	r11,$0010
			LoadB	r1H,180
			jsr	PutString

			lda	#$00
			sta	a0L			;Zähler für Dateinamen löschen.
			sta	ErrMissingFiles		;"Datei fehlt!"-Zähler löschen.
::51			jsr	SetVecFName		;Zeiger auf Dateiname nach ":r6"
			lda	r6L			;kopieren (für ":FindFile").
			ora	r6H
			beq	:53

			MoveW	r6,r0			;Dateiname ausgeben.
			MoveW	PrntFNameX,r11
			MoveB	PrntFNameY,r1H
			jsr	PutString

			jsr	SetVecFName		;Zeiger auf Dateiname nach ":r6"
			jsr	FindFile		;GEOS-Datei suchen.
			txa				;Diskettenfehler ?
			beq	:52			; => Nein, weiter...

			jsr	SetXYPosStatus
			lda	#"E"			;"OK"-Meldung ausgeben.
			jsr	PutChar
			lda	#"R"
			jsr	PutChar
			lda	#"R"
			jsr	PutChar
			jsr	SetVecFName		;Zeiger auf Dateiname nach ":r6".
			LoadW	r0,Dlg_FileError	;Fehler ausgeben.
			jsr	DoDlgBox
			inc	ErrMissingFiles		;Datei nicht gefunden, Abbruch.
			jmp	:55

::52			jsr	SetXYPosStatus
			lda	#"O"			;"OK"-Meldung ausgeben.
			jsr	PutChar
			lda	#"K"
			jsr	PutChar

::55			clc				;Zeiger auf nächste Position für
			lda	PrntFNameY		;Ausgabe der Dateinamen setzen.
			adc	#11
			cmp	#168
			bcc	:54
			LoadW	PrntFNameX,160
			lda	#20
::54			sta	PrntFNameY
			inc	a0L			;Alle Dateien geprüft?
			bne	:51			;Nein, weiter...
::53			ldx	ErrMissingFiles
			rts

;*** Zeiger auf Dateinamentabelle setzen.
:SetVecFName		lda	a0L
			asl
			asl
			tax				;Zeiger auf Dateiname nach ":r6"
			lda	FileDataTab +0,x	;kopieren (für ":FindFile").
			sta	r6L
			lda	FileDataTab +1,x
			sta	r6H
			rts

;*** Koordinaten für Statusmeldung berechnen.
:SetXYPosStatus		clc				;Zeiger auf Ende der Zeile
			lda	PrntFNameX +0		;für "OK"/"ERR"-Meldung setzen.
			adc	#<120
			sta	r11L
			lda	PrntFNameX +1
			adc	#>120
			sta	r11H
			lda	PrntFNameY
			sta	r1H
			rts

;*** Variablen.
:ErrMissingFiles	b $00
:PrntFNameX		w $0010
:PrntFNameY		b 20

;*** Statusmeldung.
:TxFindAllFiles		b GOTOXY
			w $0010
			b $b8
			b PLAINTEXT,BOLDON
if Sprache = Deutsch
			b "Prüfe auf fehlende Dateien...",NULL
endif
if Sprache = Englisch
			b "Checking for missing files...",NULL
endif

;******************************************************************************
;*** Konvertieren.
;******************************************************************************
;*** Alle GEOS-Dateien in das .CVT-Format (GeoConvert) wandeln.
;    Notwendig um alle Dateien zu einer Installationsdatei zu packen.
:DoConvGEOS2CBM		LoadW	r0,Info_01
			jsr	PutString

			lda	curDrive
			jsr	SetDevice		;Laufwerk aktivieren und
			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	DiskError		; => Ja, Abbruch...

			lda	#$00			;Zähler für Dateinamen löschen.
			sta	a0L

::51			jsr	SetVecMP3FName		;Zeiger auf Dateiname einlesen.
							;Alle Dateien bearbeitet ?
			beq	:52			; => Ja, weiter...
			jsr	GEOS_CBM		;GEOS-Datei nach .CVT wandeln.
			txa				;Diskettenfehler ?
			bne	DiskError		; => Ja, Abbruch...

			inc	a0L			;Zeiger auf nächste Datei und
			jmp	:51			;weiter mit konvertieren...

::52			jmp	GetFileInfo		;Alle Dateien verbinden.

;*** Diskettenfehler ausgeben.
:DiskError		stx	DskErrCode
			LoadW	r0,Dlg_DiskError
			jsr	DoDlgBox
			jmp	EnterDeskTop

;*** Zeiger auf MP3-Dateiname setzen.
;    Dateien die nicht der gesuchten Gruppe entsprechen werden
;    dabei nicht berücksichtigt.
:SetVecMP3FName		lda	a0L
			asl
			asl
			tax				;Zeiger auf Dateiname nach ":r6"
			lda	FileDataTab +0,x	;kopieren (für ":FindFile").
			sta	r6L
			lda	FileDataTab +1,x
			sta	r6H
			ora	r6L
			beq	:1

			lda	FileDataTab +2,x
			cmp	FTypeMode
			beq	:0

			inc	a0L
			bne	SetVecMP3FName

::0			lda	#$ff
::1			rts

;******************************************************************************
;*** Konvertieren.
;******************************************************************************
;*** Datei-Informationen einlesen.
:GetFileInfo		LoadW	r0,Info_02
			jsr	PutString

			LoadW	a1,FNameTab1		;Zeiger auf Tabelle mit
							;Verzeichnis-Einträgen.

			lda	#$00			;Zähler für Dateinamen löschen.
			sta	a0L

::51			jsr	SetVecMP3FName		;Zeiger auf Dateiname einlesen.
							;Alle Dateien bearbeitet ?
			beq	:54			; => Ja, weiter...
			jsr	FindFile		;Dateieintrag suchen.
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch...

			ldy	#$1f			;Verzeichnis-Eintrag kopieren.
::52			lda	dirEntryBuf-2,y
			sta	(a1L)        ,y
			dey
			bpl	:52

			AddVBW	32,a1			;Zeiger auf Tabelle korrigieren.

			inc	a0L			;Zeiger auf nächste Datei und
			jmp	:51			;weiter mit Verzeichnis-Einlesen...
::53			rts

::54			ldy	#$00			;Tabellen-Ende markieren.
			tya
::55			sta	(a1L),y
			iny
			bne	:55

;******************************************************************************
;*** Dateien verbinden.
;******************************************************************************
;*** Alle Dateien zu einer Gesamtdatei verbinden.
:CombineFiles		LoadW	a1,FNameTab1		;Zeiger auf Tabelle mit
							;Verzeichnis-Einträgen.

			lda	#$00			;Zähler für belegte Blocks der
			sta	a3L			;Gesamtdatei löschen.
			sta	a3H

			LoadW	r4,diskBlkBuf		;Zeiger auf Speicher für
							;aktuellen Sektor.

::51			lda	#$00			;Zähler für belegte Blocks der
			sta	a2L			;Einzeldatei löschen.
			sta	a2H

			ldy	#$03			;Zeiger auf ersten Sektor der
			lda	(a1L),y			;Einzeldatei richten.
			sta	r1L
			iny
			lda	(a1L),y
			sta	r1H
::52			jsr	GetBlock		;Aktuellen Sektor einlesen.
			txa				;Diskettenfehler ?
			beq	:54			; => Nein, weiter...
::53			jmp	DiskError		;Ende...

::54			inc	a2L			;Anzahl belegte Blöcke der
			bne	:55			;Einzeldatei +1.
			inc	a2H

::55			inc	a3L			;Anzahl belegte Blöcke der
			bne	:56			;Gesamtdatei +1.
			inc	a3H

::56			lda	diskBlkBuf +0		;Folgt weiterer Sektor ?
			beq	:57			; => Nein, weiter...
			sta	r1L
			lda	diskBlkBuf +1
			sta	r1H			;Zeiger auf nächsten Sektor und
			jmp	:52			;nächsten Sektor einlesen.

;--- Aktuelle Einzeldatei beenden.
::57			ldy	#$00			;Anzahl Bytes im letzten Sektor
			sta	(a1L),y			;in Verzeichnis-Tabelle kopieren.
			iny
			lda	diskBlkBuf +1
			sta	(a1L),y

			ldy	#$1e			;Anzahl belegter Blocks der
			lda	a2L			;Einzeldatei in Verzeichnis-
			sta	(a1L),y			;Tabelle kopieren.
			iny
			lda	a2H
			sta	(a1L),y

			ldx	diskBlkBuf +1		;Nicht benötigte Bytes im
::58			inx				;letzten Sektor mit $00-Bytes
			beq	:59			;auffüllen. Wichtig für Packer!
			lda	#$00
			sta	diskBlkBuf,x
			beq	:58

::59			ldy	#$22
			lda	(a1L),y			;Folgt weitere Datei ?
			beq	:60			; => Nein, Ende...

			iny				;Ersten Sektor der nächsten Datei
			lda	(a1L),y			;als Link-Adresse in aktuellem
			sta	diskBlkBuf +0		;Sektor speichern.
			iny
			lda	(a1L),y
			sta	diskBlkBuf +1
			jsr	PutBlock		;Sektor auf Diskette schreiben.
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch...

			AddVW	32,a1			;Zeiger auf nächste Datei und
			jmp	:51			;weiter mit Datei-kombinieren.

::60			lda	a1L			;Größe der Datei "PATCH_64.INF"
			clc				;festlegen.
			adc	#$20
			sta	LengthInfoFile +0
			lda	a1H
			adc	#$00
			sta	LengthInfoFile +1

;******************************************************************************
;*** Delete files.
;******************************************************************************
;*** Nicht benötigte Verzeichnis-Einträge löschen.
:DelOldFiles		LoadW	r0,Info_03
			jsr	PutString

			LoadW	a1,FNameTab1		;Zeiger auf Tabelle mit
							;Verzeichnis-Einträgen.

			lda	#$00			;Zähler für Dateinamen löschen.
			sta	a0L
			sta	a0H

::51			jsr	SetVecMP3FName		;Zeiger auf Dateiname einlesen.
							;Alle Dateien eingelesen ?
			beq	:60			; => Ja, weiter...
			jsr	FindFile		;Dateieintrag suchen.
			txa				;Diskettenfehler ?
			bne	:59			; => Ja, Abbruch...

			lda	a0H			;Erste Datei ?
			bne	:56			; => Nein, weiter...
			inc	a0H

;--- Erste Datei...
::52			ldy	#$03			;Name der Gesamtdatei
::53			lda	FName_TMP -3,y		;definieren.
			beq	:54
			sta	(r5L)         ,y
			iny
			bne	:53
::54			cpy	#$13			;Name auf 16-Zeichen mit
			beq	:55			;$A0-Bytes auffüllen.
			lda	#$a0
			sta	(r5L)         ,y
			iny
			bne	:54

::55			ldy	#$1c			;Größe der Gesamtdatei in
			lda	a3L			;Verzeichnis-Eintrag kopieren.
			sta	(r5L),y
			iny
			lda	a3H
			sta	(r5L),y
			jmp	:58			;Eintrag aktualisieren.

;--- Restliche Einträge löschen...
::56			lda	#$00			;Verzeichnis-Eintrag löschen.
			tay
::57			sta	(r5L),y
			iny
			cpy	#30
			bne	:57

::58			jsr	PutBlock		;Aktuellen verzeichnis-Eintrag
							;auf Diskette aktualisieren.
			txa				;Diskettenfehler ?
			bne	:59			; => Ja, Abbruch...

			inc	a0L			;Zeiger auf nächste Datei und
			jmp	:51			;weiter mit konvertieren...

::59			jmp	DiskError		;Diskettenfehler ausgeben.

;--- Informationsdatei speichern.
::60			jmp	AnalyzeFile

;******************************************************************************
;*** GEOS => SEQ
;******************************************************************************
;*** Datei von GEOS nach SEQ wandeln.
;    Übergabe:		r6 = Zeiger auf Dateiname.
:GEOS_CBM		MoveW	r6,a1			;Zeiger auf Datei-Eintrag speichern.
			jsr	FindFile		;Datei auf Diskette suchen.
			txa				;Diskettenfehler ?
			bne	ExitDiskErr		; => Ja, Abbruch...

			MoveB	r1L,a3L			;Zeiger auf Verzeichnis-Sektor
			MoveB	r1H,a3H			;zwischenspeichern.
			MoveW	r5 ,a4			;Zeiger auf Verzeichnis-Eintrag
							;zwischenspeichern.

			ldy	#$1d			;Verzeichnis-Eintrag in
::51			lda	dirEntryBuf   ,y	;Zwischenspeicher kopieren.
			sta	FileEntryBuf1 ,y
			sta	FileEntryBuf2 ,y
			dey
			bpl	:51

			jsr	GetDirHead		;Aktuelle BAM einlesen.

			ldy	#$01			;Sektor für Konvertierungs-
			sty	r3L			;kennung festlegen.
			dey
			sty	r3H
			jsr	SetNextFree		;Ersten freien Sektor suchen.
			txa				;Diskettenfehler ?
			beq	StartConvGEOS		; => Nein, weiter...

;*** Diskettenfehler ausgeben.
:ExitDiskErr		rts

;******************************************************************************
;*** GEOS => SEQ
;******************************************************************************
;*** Konvertierung beginnen.
:StartConvGEOS		MoveB	r3L,a2L			;Belegten Sektor merken.
			MoveB	r3H,a2H
			jsr	PutDirHead		;BAM aktualisieren.

;*** Eintrag für CBM-Datei erzeugen.
			lda	#$81			;Dateityp "SEQ".
			sta	FileEntryBuf1 +0
			lda	a2L			;Zeiger auf ersten Sektor der
			sta	FileEntryBuf1 +1	;CBM-Datei.
			lda	a2H
			sta	FileEntryBuf1 +2

			ldx	#$13
			lda	#$00			;GEOS-Informationen aus
::51			sta	FileEntryBuf1,x		;Dateieintrag löschen.
			inx
			cpx	#$1c
			bne	:51

			inc	FileEntryBuf1 +28	;Anzahl belegter Blöcke +1.
			bne	:52
			inc	FileEntryBuf1 +29

::52			MoveB	a3L,r1L			;Verzeichnissektor für
			MoveB	a3H,r1H			;Dateieintrag lesen.
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa				;Diskettenfehler ?
			bne	:58			; => Ja, Abbruch...

			MoveW	a4,r5			;Zeiger auf Dateieintrag.

			ldy	#$1d			;Neuen Eintrag in Verzeichnis-
::53			lda	FileEntryBuf1,y		;Sektor kopieren.
			sta	(r5L)        ,y
			dey
			bpl	:53

			jsr	PutBlock		;Verzeichnis aktualisieren.
			txa				;Diskettenfehler ?
			bne	:58			; => Ja, Abbruch.

;*** Fortsetzung: GEOS nach SEQ.
			lda	FileEntryBuf2 +19	;Zeiger auf Infoblock als
			sta	diskBlkBuf    +0	;Link-Adresse speichern.
			lda	FileEntryBuf2 +20
			sta	diskBlkBuf    +1

			ldy	#$1d			;Original-Verzeichniseintrag
::54			lda	FileEntryBuf2   ,y	;in Datensektor kopieren.
			sta	diskBlkBuf    +2,y
			dey
			bpl	:54

			ldy	#$1c
::55			lda	FormatCode1 ,y		;Formatkennung übertragen.
			sta	diskBlkBuf +$20,y
			dey
			bpl	:55

::56			ldy	#$42			;Rest des Datensektors löschen.
			lda	#$00			;Wichtig für Packer!
::57			sta	diskBlkBuf,y
			iny
			bne	:57

			MoveB	a2L,r1L
			MoveB	a2H,r1H
			LoadW	r4,diskBlkBuf		;Datensektor zurück auf
			jsr	PutBlock		;Diskette schreiben.
			txa				;Diskettenfehler ?
			bne	:58			; => Ja, Abbruch.

			lda	FileEntryBuf2 +19
			sta	r1L
			lda	FileEntryBuf2 +20
			sta	r1H
			jsr	GetBlock		;Infoblock einlesen.
			txa				;Diskettenfehler ?
			beq	:59			; => Nein, weiter...
::58			rts				;Diskettenfehler ausgeben.

::59			lda	FileEntryBuf2 +1	;Zeiger auf ersten Sektor als
			sta	diskBlkBuf    +0	;Link-Adresse speichern.
			lda	FileEntryBuf2 +2
			sta	diskBlkBuf    +1
			jsr	PutBlock		;Infoblock zurück auf Diskette
			txa				;Diskettenfehler ?
			bne	:58			; => Ja, Abbruch.

			lda	FileEntryBuf2 +21	;Dateistruktur auswerten:
			bne	GEOS_VLIR		; -> VLIR.
			rts				; -> SEQ, Konvertieren beendet.

;******************************************************************************
;*** GEOS => SEQ
;******************************************************************************
;*** VLIR-Datei nach SEQ wandeln.
:GEOS_VLIR		jsr	EnterTurbo
			jsr	InitForIO

			jsr	SetVecHdrVLIR		;Zeiger auf VLIR-Sektor.
			jsr	ReadBlock		;VLIR-Sektor lesen.
			txa				;Diskettenfehler ?
			bne	ErrExitConvert		; => Ja, Abbruch.

			lda	#$00			;Flag: "Erster Sektor" setzen.
			sta	a5H

			lda	#$02			;Zeiger auf VLIR-Eintrag.
			sta	a5L
::51			tay
			lda	FileHdrBlock +0,y	;VLIR-Datensatz belegt ?
			beq	:55			; => Nein, übergehen.
			sta	diskBlkBuf   +0		;VLIR-Daten verbinden.
			lda	FileHdrBlock +1,y
			sta	diskBlkBuf   +1

			lda	a5H			;Datensätze bereits verkettet ?
			bne	:52			; => Ja, weiter...
			lda	diskBlkBuf +$00		;Verbindung VLIR-Header mit
			sta	FileHdrBlock +0		;erstem Datensatz.
			lda	diskBlkBuf +$01
			sta	FileHdrBlock +1
			jmp	:53

::52			jsr	WriteBlock		;Sektor zurückschreiben.
			txa				;Diskettenfehler ?
			bne	ErrExitConvert		; => Ja, Abbruch...

::53			LoadB	a6L,$00			;Länge des Datensatzes löschen.
			LoadW	r4 ,diskBlkBuf		;Zeiger auf Zwischenspeicher.

::54			lda	diskBlkBuf +0
			sta	r1L
			lda	diskBlkBuf +1
			sta	r1H
			jsr	ReadBlock		;Nächsten Datensatz-Sektor lesen.
			txa				;Diskettenfehler ?
			bne	ErrExitConvert		; => Ja, Abbruch...

			inc	a6L			;Anzahl Sektoren +1.
			lda	diskBlkBuf +0		;Letzter Sektor ?
			bne	:54			; => Nein, nächsten Sektor lesen.

			ldy	a5L
			lda	a6L			;Anzahl Sektoren merken.
			sta	FileHdrBlock +0,y
			lda	diskBlkBuf +1		;Anzahl Bytes in letztem
			sta	FileHdrBlock +1,y	;Sektor merken.
			LoadB	a5H,$ff			;Flag: "Erster Sektor" löschen.

::55			inc	a5L			;Zeiger auf nächsten VLIR-
			inc	a5L			;Eintrag in Tabelle.

			lda	a5L			;Ende erreicht ?
			bne	:51			; => Nein, weiter...

			jsr	SetVecHdrVLIR		;Zeiger auf VLIR-Sektor.
			jsr	WriteBlock		;Sektor schreiben.

;*** Fehler beim konvertieren.
:ErrExitConvert		jmp	DoneWithIO		;Ende...

;*** Zeiger auf VLIR-Header.
:SetVecHdrVLIR		lda	FileEntryBuf2 +1
			sta	r1L
			lda	FileEntryBuf2 +2
			sta	r1H
			LoadW	r4,FileHdrBlock
			rts

;******************************************************************************
;*** Packer
;******************************************************************************
;*** "SETUP.TMP"-Datei analysieren.
;    Für den Packer wird ein Kennbyte benötigt, welches der Entpacker später
;    anzeigt, das nun gepackte Daten folgen. Da im Prinzip jedes Byte auch im
;    Programm vorkommen kann, muß ein einzlnes Byte, welches dem Kennbyte
;    entspricht, ebenfalls gepackt werden. Um den dadurch entstehenden
;    Overhead möglichst klein zu halten, wird ein Byte gesucht, der möglichst
;    selten im Programm vorkommt. Dieses Byte ist dann das Kennbyte für
;    gepackte Daten und wird in der gepackten Datei gespeichert.
:ByteCntL		= $5000
:ByteCntM		= $5100
:ByteCntH		= $5200
:AnalyzeFile		LoadW	r0,Info_04
			jsr	PutString

			lda	#$00			;Analyse-Speicher löschen.
			tax				;Die 3x256 Bytes dienen als Zähler
::51			sta	ByteCntL,x		;für die Häufigkeit eines bestimmten
			sta	ByteCntM,x		;Bytewertes...
			sta	ByteCntH,x
			inx
			bne	:51

			jsr	InitGetByte		;Zeiger auf erstes Byte richten.
::52			jsr	GetByteToBuf		;Datenbyte einlesen.
			cpx	#$00			;Ende der Datei erreicht ?
			bne	:53			; => Ja, weiter...

			tax				;Byte-Zähler korrigieren.
			inc	ByteCntL,x
			bne	:52
			inc	ByteCntM,x
			bne	:52
			inc	ByteCntH,x
			jmp	:52			;Weiter mit nächstem Byte.

;--- Byte-Analyze auswerten.
::53			lda	#$ff			;Vergleichswert initialisieren.
			sta	a0L
			sta	a0H
			sta	a1L

			ldx	#$00			;Byte-Zähler mit dem bisher
::54			lda	ByteCntH,x		;kleinsten Wert vergleichen.
			cmp	a1L			;Kommt das aktuelle Byte seltener
			bne	:55			;vor als das bisherige, dann dieses
			lda	ByteCntM,x		;Byte als neues Kennbyte markieren.
			cmp	a0H
			bne	:55
			lda	ByteCntL,x
			cmp	a0L
::55			bcs	:56

			lda	ByteCntL,x		;Neuen Vergleichswert gefunden.
			sta	a0L			;Kennbyte zwischenspeichern.
			lda	ByteCntM,x
			sta	a0H
			lda	ByteCntH,x
			sta	a1L
			stx	a1H

::56			inx				;Alle Bytes überprüft ?
			bne	:54			; => Nein, weiter...

			lda	a1H			;Kennbyte für Packer definieren und
			sta	PackCode		;Datei packen.
			jmp	PackFile

;******************************************************************************
;*** Packer
;******************************************************************************
;*** "SETUP.TMP"-Datei packen.
:PackFile		LoadW	r0,Info_05
			jsr	PutString

			jsr	InitGetByte		;Zeiger auf erstes Byte richten.

			lda	#$00
			sta	a0L			;Flag löschen: "Erstes Byte".
			sta	a2L			;Packbyte löschen.
			sta	a2H			;Packbyte-Zähler löschen.

			lda	PackCode
			jsr	PutByteToBuf
			cpx	#$00			;Diskettenfehler ?
			bne	:56			; => ja, Abbruch...

::51			jsr	GetByteToBuf		;Datenbyte einlesen.
			cpx	#$00			;Ende der Datei erreicht ?
			beq	:52			; => Nein, weiter...

			jsr	SendBytes		;Daten im Speicher auf Diskette
			cpx	#$00			;Diskettenfehler ?
			bne	:56			; => ja, Abbruch...
			jsr	UpdateFileData		;übertragen und Verzeichnis-Eintrag
			jmp	MakeEntry		;erstellen.

::52			bit	a0L			;Erstes Byte ?
			bmi	:53			; => Nein, weiter...
			sta	a2L			;Packbyte setzen und Byte-Zähler
			LoadB	a2H,$01			;initialisieren.
			LoadB	a0L,$ff
			jmp	:51			;Nächstes Byte auswerten.

::53			cmp	a2L			;Aktuelles Byte=letztes Byte ?
			beq	:55			; => Ja, weiter...
::54			pha				;Aktuelles Byte merken und
			jsr	SendBytes		;Letztes Byte senden.
			pla
			cpx	#$00			;Diskettenfehler ?
			bne	:56			; => ja, Abbruch...
			sta	a2L			;Packbyte setzen und Byte-Zähler
			LoadB	a2H,$01			;initialisieren.
			jmp	:51			;Nächstes Byte auswerten.

::55			inc	a2H			;Byte-Zähler korrigieren und
			bne	:51			;weitersuchen.
			dec	a2H			;Zähler -1: Max. 255 Bytes.
							;Wenn genau 256 gleiche Bytes
							;folgen kann nicht erkannt werden
							;ob der Puffer bereits geschrieben
							;wurde: Nicht ändern!!!!!!!!!!!!!!
			jsr	SendBytes		; => 255 Bytes, Daten speichern.
			cpx	#$00			;Diskettenfehler ?
			bne	:56			; => ja, Abbruch...
			LoadB	a2H,$01			;Zähler für Bytes zurücksetzen..
			jmp	:51			;Weiter mit nächstem Byte.
::56			jmp	DiskError

;*** Prüfsummen-Routine.
;    Hier wird eine eigene Routine eingebunden, da nicht auszuschließen
;    ist das andere GEOS-Versionen andere CRC-Ergebnisse liefern.
			t "-G3_PatchCRC"

;******************************************************************************
;*** Packer
;******************************************************************************
;*** Verzeichnis-Eintrag erstellen.
:MakeEntry		LoadW	r0,Info_06
			jsr	PutString

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			beq	:52			; => Nein, weiter...
::51			jmp	DiskError

;--- Prüfsumme erstellen unf .INF-Datei speichern.
::52			LoadW	r0,FName_TMP		;Temporäre Datei löschen.
			jsr	DeleteFile
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

;--- Prüfsumme erstellen.
			lda	Data1stSek +0
			ldx	Data1stSek +1
			jsr	PatchCRC		;Prüfsumme für Patchdaten
			txa				;erstellen. Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			lda	a0L			;Prüfsumme speichern.
			sta	CRC_CODE +0
			lda	a0H
			sta	CRC_CODE +1

;--- Leeres Archiv erstellen.
			LoadW	r9  ,HdrB000		;Leere Archiv-Datei erstellen.
			LoadB	r10L,0
			jsr	SaveFile
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

;--- Infodaten speichern.
			LoadW	r0,HdrFName		;VLIR-Datei öffnen.
			jsr	OpenRecordFile
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch...

			jsr	AppendRecord		;Datensatz erstellen.
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch...

			lda	LengthInfoFile +0	;Größe des Infodatenspeichers
			sec				;berechnen.
			sbc	#< CRC_CODE
			sta	r2L
			lda	LengthInfoFile +1
			sbc	#> CRC_CODE
			sta	r2H
			LoadW	r7 ,CRC_CODE		;Infodatensatz speichern.
			jsr	WriteRecord
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch...

			jsr	UpdateRecordFile	;VLIR-Daten aktualisieren.
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch...

			jsr	CloseRecordFile		;VLIR-Datei schließen.

;--- Dateigröße anpassen.
			LoadW	r6 ,HdrFName
			jsr	FindFile		;SetupMP-Datei suchen.
			txa				;Diskettenfehler ?
			beq	:54			; => Nein, weiter...
::53			jmp	DiskError

::54			ldy	#28			;Dateigröße korrigieren.
			lda	dirEntryBuf,y
			clc
			adc	DataSekCnt  +0
			sta	(r5L),y
			iny
			lda	dirEntryBuf,y
			adc	DataSekCnt  +1
			sta	(r5L),y
			LoadW	r4,diskBlkBuf
			jsr	PutBlock
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch...

			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r4,fileHeader
			jsr	GetBlock		;VLIR-Header einlesen.
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch...

			lda	Data1stSek +0
			sta	fileHeader +4
			lda	Data1stSek +1
			sta	fileHeader +5
			jsr	PutBlock		;Zeiger auf Patchdaten.
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch...

;******************************************************************************
;*** Packer
;******************************************************************************
;--- Infoblock mit Infotext versehen.
			lda	dirEntryBuf +19
			sta	r1L
			lda	dirEntryBuf +20
			sta	r1H
			LoadW	r4,fileHeader
			jsr	GetBlock		;VLIR-Header einlesen.
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch...

			ldx	#$00
::55			lda	HdrB160,x
			sta	fileHeader +160,x
			beq	:56
			inx
			bne	:55

::56			jsr	PutBlock
			txa
			bne	:53
			rts

;******************************************************************************
;*** Packer
;******************************************************************************
;*** Quell-Datei öffnen.
:InitGetByte		jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			LoadW	r6,FName_TMP
			jsr	FindFile		;Quell-Datei auf Diskette suchen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			lda	dirEntryBuf +1		;Zeiger auf ersten Sektor der
			sta	a3L			;Datei zwischenspeichern.
			lda	dirEntryBuf +2
			sta	a3H
			lda	#$00			;Zeiger für ":ReadLink" löschen.
			sta	a4L
			sta	a4H
			rts

::51			jmp	DiskError

;*** Byte aus Quell-Datei einlesen.
:GetByteToBuf		MoveB	a3L,r1L			;Zeiger auf aktuelle
			MoveB	a3H,r1H			;Byte-Position.
			MoveW	a4 ,r5
			LoadW	r4 ,diskBlkBuf
			jsr	ReadByte		;Byte einlesen.
			pha
			MoveB	r1L,a3L			;Neue Position zwischenspeichern.
			MoveB	r1H,a3H
			MoveW	r5 ,a4
			pla
			rts

;*** Gepackte Daten speichern.
:SendBytes		lda	a2L
			cmp	PackCode		;Aktuelles Byte = PackCode ?
			beq	:53			; => Ja, immer packen.

			ldx	a2H
			beq	:53
			cpx	#$04			;Mehr als drei Bytes ?
			bcs	:53			; => Ja, packen...

::51			lda	a2L			;Packen nicht effektiv,
			jsr	PutByteToBuf		;einzelne Bytes speichern.
			txa
			bne	:52
			dec	a2H
			bne	:51
::52			rts

;--- Drei Byte Packdaten speichern.
::53			lda	PackCode		;PackCode senden.
			jsr	PutByteToBuf
			txa
			bne	:52

			lda	a2L			;Byte-Typ senden.
			jsr	PutByteToBuf
			txa
			bne	:52

			lda	a2H			;Anzahl Bytes senden.
			jmp	PutByteToBuf

;******************************************************************************
;*** Packer
;******************************************************************************
;*** Byte in Ziel-Datei speichern.
:PutByteToBuf		bit	firstByte		;Erstes Byte ?
			bmi	:51			; => Nein, weiter...
			dec	firstByte		;Flag löschen: "Erstes Byte".

			pha				;Erstes Byte merken.
			jsr	GetFreeSek		;Freien Sektor suchen.
			pla
			cpx	#$00			;Diskettenfehler ?
			bne	:53			; => ja, Abbruch...

			ldy	r3L			;Zeiger auf Freien Sektor
			sty	DataSektor +0		;zwischenspeichern.
			sty	Data1stSek +0
			ldy	r3H
			sty	DataSektor +1
			sty	Data1stSek +1
			ldy	#$02
			sty	DataVec
			bne	:52

::51			ldy	DataVec			;Aktueller Sektor voll ?
			bne	:52			; => Nein, weiter...

			pha				;Erstes Byte merken.
			jsr	GetFreeSek		;Freien Sektor suchen.
			pla
			cpx	#$00			;Diskettenfehler ?
			bne	:53			; => ja, Abbruch...

			pha
			lda	r3L			;Freien Sektor als Link-Adresse
			sta	CopySektor +0		;in aktuellem Sektor speichern.
			pha
			lda	r3H
			sta	CopySektor +1
			pha
			jsr	SaveFileData		;Aktuellen Sektor auf Diskette
			pla				;übertragen.
			sta	DataSektor +1
			pla
			sta	DataSektor +0
			ldy	#$02			;Byte-Zähler für aktuellen
			sty	DataVec			;Sektor löschen.
			pla
			cpx	#$00			;Diskettenfehler ?
			bne	:53			; => ja, Abbruch...

::52			eor	#%11001010		;Gepackte Datei kodieren!!!
			sta	CopySektor,y		;Byte in aktuellen Datensektor
			iny				;übertragen und Zeiger auf nächste
			sty	DataVec			;Byte-Position.
			ldx	#$00
::53			rts

;*** Letzten Datensektor schreiben.
:UpdateFileData		lda	#$00			;Anzahl Bytes in letztem Sektor
			sta	CopySektor +0		;speichern.
			lda	DataVec
			sta	CopySektor +1

;*** Aktuellen Sektor auf Diskette schreiben.
:SaveFileData		MoveB	DataSektor +0,r1L
			MoveB	DataSektor +1,r1H
			LoadW	r4,CopySektor
			jsr	PutBlock
			jmp	PutDirHead

;*** Freien Sektor auf Diskette suchen.
:GetFreeSek		inc	DataSekCnt +0		;Dateigröße korrigieren.
			bne	:51
			inc	DataSekCnt +1

::51			lda	#$01
			sta	r3L
			sta	r3H
			jmp	SetNextFree

;******************************************************************************
;*** SETUP
;******************************************************************************
;*** Dateiname MakeSetup-Datei.
if Flag64_128 = TRUE_C64
:MkSetupName		b "MakeSetup64",NULL
endif
if Flag64_128 = TRUE_C128
:MkSetupName		b "MakeSetup128",NULL
endif

;*** Liste der Dateinamen.
			t "-G3_FilesMP3"

;*** Dialogbox: Diskettenfehler.
:Dlg_FileError		b $81
			b DBTXTSTR ,$10,$10
			w :101
			b DBTXTSTR ,$10,$1c
			w :102
			b DBVARSTR ,$10,$2c
			b r6L
			b OK       ,$02,$48
			b NULL

::101			b PLAINTEXT,BOLDON
if Sprache = Deutsch
			b "ACHTUNG!",NULL
::102			b "Quelldatei fehlt:",NULL
endif
if Sprache = Englisch
			b "ERROR!",NULL
::102			b "Source file is missing:",NULL
endif

;*** Dialogbox: Diskettenfehler.
:Dlg_DiskError		b $81
			b DBTXTSTR ,$10,$10
			w :101
			b DBTXTSTR ,$10,$1c
			w :102
			b DB_USR_ROUT
			w :103
			b OK       ,$02,$48
			b NULL

::101			b PLAINTEXT,BOLDON
if Sprache = Deutsch
			b "ACHTUNG!",NULL
::102			b "Diskettenfehler:",NULL
endif
if Sprache = Englisch
			b "ERROR!",NULL
::102			b "Disk error:",NULL
endif

::103			lda	DskErrCode
			sta	r0L
			lda	#$00
			sta	r0H
			LoadB	r1H,$3c
			LoadW	r11,$00a8
			lda	#%11000000
			jmp	PutDecimal

:DskErrCode		b $00

;*** Informationstexte...
:Info_00		b PLAINTEXT,BOLDON
			b GOTOXY
			w $0010
			b $10
if Sprache = Deutsch
			b "1. Dateien suchen...",NULL
endif
if Sprache = Englisch
			b "1. Checking files...",NULL
endif

:Info_01		b PLAINTEXT,BOLDON
			b GOTOXY
			w $0010
			b $20
if Sprache = Deutsch
			b "2. Dateien nach SEQ wandeln...",NULL
endif
if Sprache = Englisch
			b "2. Converting files to SEQ...",NULL
endif

:Info_02		b GOTOXY
			w $0010
			b $30
if Sprache = Deutsch
			b "3. Dateien zusammenfassen...",NULL
endif
if Sprache = Englisch
			b "3. Merging files...",NULL
endif

:Info_03		b GOTOXY
			w $0010
			b $40
if Sprache = Deutsch
			b "4. Verzeichnis aktualisieren...",NULL
endif
if Sprache = Englisch
			b "4. Updating directory...",NULL
endif

:Info_04		b GOTOXY
			w $0010
			b $50
if Sprache = Deutsch
			b "5. Datei analysieren...",NULL
endif
if Sprache = Englisch
			b "5. Analyzing file...",NULL
endif

:Info_05		b GOTOXY
			w $0010
			b $60
if Sprache = Deutsch
			b "6. Datei packen...",NULL
endif
if Sprache = Englisch
			b "6. Compress file...",NULL
endif

:Info_06		b GOTOXY
			w $0010
			b $70
if Sprache = Deutsch
			b "7. Prüfsumme erstellen...",NULL
endif
if Sprache = Englisch
			b "7. Creating checksum...",NULL
endif

;*** Variablen für Packer.
:FName_TMP		b "TempFile",NULL
:FTypeMode		b $00

:FormatCode1		b "MP3"
:FormatCode2		b " formatted GEOS file V1.0",NULL

;*** Info-Block für SETUP-Dateien.
:HdrB000		w HdrFName
:HdrB002		b $03,$15
			j
<MISSING_IMAGE_DATA>

:HdrB068		b $83
:HdrB069		b SYSTEM
:HdrB070		b VLIR
:HdrB071		w $0000,$ffff,$0000
if Flag64_128 = TRUE_C64
:HdrB077		b "SetupMP64"			;Klasse/MP64.
endif
if Flag64_128 = TRUE_C128
:HdrB077		b "SetupMP128"			;Klasse/MP128.
endif
if Sprache = Deutsch
:SysLanguage		b "d"				;Sprache/Deutsch.
endif
if Sprache = Englisch
:SysLanguage		b "e"				;Sprache/Englisch.
endif
:SysFileNum1		b "1"
if Flag64_128 = TRUE_C64
			b " "				;Füllbyte MP64.
endif
:HdrB089		b "V"
:HdrB090		b "2.2"				;Version.
:HdrB093		b $00,$00,$00,$00		;Reserviert.
:HdrB097		b "M.Kanet/W.Grimm"		;Autor.
:HdrB112		s 6				;Reserviert.
:HdrB117		s 16				;Version.
:HdrB133		b $00,$00,$00,$00		;Reserviert.
:HdrB137		w $0000				;Erste Seite.
:HdrB139		b $00				;Titelseite/NLQ-Abstände.
:HdrB140		w $0000				;Höhe Kopfzeile.
:HdrB142		w $0000				;Höhe Fußzeile.
:HdrB144		w $0000				;Länge einer Seite.
:HdrB146		s 14				;Reserviert.

if Flag64_128 = TRUE_C64
:HdrB160		b "* MegaPatch64 *",CR
			b "Markus Kanet",NULL
endif
if Flag64_128 = TRUE_C128
:HdrB160		b "* MegaPatch128 *",CR
			b "M.Kanet/W.Grimm",NULL
endif
:HdrEnd			s (HdrB000+256)-HdrEnd

:HdrFNameScrText	b GOTOXY
			w $0010
			b $b8
			b PLAINTEXT,BOLDON

;--- Hinweis:
;Dateinamen für die SETUP-Dateien.
;Für SETUP sind die Dateinamen nicht
;von Bedeutung, da hier nur über die
;GEOS-Klasse gesucht wird.
if Flag64_128 = TRUE_C64
:HdrFName		b "SetupMP64"			;Klasse.
endif
if Flag64_128 = TRUE_C128
:HdrFName		b "SetupMP128"			;Klasse.
endif
if Sprache = Deutsch
:dBoxSysLang		b "d"
endif
if Sprache = Englisch
:dBoxSysLang		b "e"
endif
			b "."
:SysFileNum2		b "1"
			b NULL

;*** Datenspeicher.
:Top_DataBuf
:firstByte		b $00
:DataSektor		b $00,$00
:Data1stSek		b $00,$00
:DataVec		b $00
:DataSekCnt		w $0000
:CopySektor		s 256
:PackCode		b $00

;*** Variablen für GEOS-SEQ.
:FileEntryBuf1		s 30
:FileEntryBuf2		s 30
:FileHdrBlock		s 256

;*** Speicher für Informationsdatei.
:LengthInfoFile		w $0000
:CRC_CODE		w $0000
:FNameTab1
:End_DataBuf
