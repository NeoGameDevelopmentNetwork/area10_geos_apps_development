; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Alle erforderlichen Setup-Dateien vor dem erstellen der gepackten
;    Setup-Dateien suchen. Programm bei fehlenden Dateien beenden.
:MainInit		lda	#ST_WR_FORE		;Nur in Vordergrund schreiben.
			sta	dispBufferOn

			jsr	UseSystemFont		;Standard-Zeichensatz aktivieren.
			ClrB	currentMode		;PLAINTEXT.

			jsr	STAGE1_FINDFILE		;"1. Dateien suchen..."
			txa				;Alle Dateien vorhanden?
			beq	:1			;Ja, weiter...
			jmp	EnterDeskTop		;Zurück zum DeskTop.

;*** Aufruf der Packroutine.
;    Es wird ein Gesamt-Archiv mit allen Dateien erstell
::1			jsr	STAGE2_CONVERT		;"2. Dateien konvertieren..."
			txa				;Fehler aufgetreten ?
			bne	:exit			; => Ja, Abruch...

			jsr	STAGE3_GETINFO		;"3. Dateien zusammenfassen..."
			txa				;Fehler aufgetreten ?
			bne	:exit			; => Ja, Abruch...

			jsr	STAGE4_CLEANUP		;"4. Verzeichnis bereinigen..."
			txa				;Fehler aufgetreten ?
			bne	:exit			; => Ja, Abruch...

			jsr	STAGE5_ANALYZE		;"5. Datei analysieren..."
			txa				;Fehler aufgetreten ?
			bne	:exit			; => Ja, Abruch...

			jsr	STAGE6_PACKFILE		;"6. Datei packen..."
			txa				;Fehler aufgetreten ?
			bne	:exit			; => Ja, Abruch...

			jsr	STAGE7_MAKECRC		;"7. Prüfsumme erstellen..."

			LoadW	r0,MkSetupName		;Setup erstellt, MakeSetup löschen.
			jsr	DeleteFile

::exit			jmp	EnterDeskTop		;Programm beenden.

;*** Alle Dateien suchen.
:STAGE1_FINDFILE	lda	#$00			;Bildschirm löschen.
			jsr	SetPattern
			jsr	i_Rectangle
			b	$00,$c7
			w	$0000
			w	$013f

			LoadW	PrntFNameX,PRNT_X_START
			LoadB	PrntFNameY,PRNT_Y_START

			LoadW	r0,InfoTx_00		;Statusmeldung ausgeben.
			jsr	PutString

			lda	#$00
			sta	a0L			;Zähler für Dateinamen löschen.
			sta	ErrMissingFiles		;"Datei fehlt!"-Zähler löschen.
::51			jsr	SetVecFName		;Zeiger auf Dateiname nach ":r6"
							;kopieren (für ":FindFile").
;			lda	r6L
;			ora	r6H			;Ende erreicht?
			beq	:53			; => Ja, Ende...

			lda	rightMargin +0
			pha
			lda	rightMargin +1
			pha

			lda	PrntFNameX +0		;X-Koordinate und rechten
			sta	r11L			;Rand setzen.
			clc
			adc	#< PRNT_X_TAB
			sta	rightMargin +0
			lda	PrntFNameX +1
			sta	r11H
			adc	#> PRNT_X_TAB
			sta	rightMargin +1

			lda	PrntFNameY		;Y-Koordinate setzen.
			sta	r1H

			lda	r6L
			sta	r0L
			lda	r6H
			sta	r0H

			jsr	PutString		;Dateiname ausgeben.

			pla
			sta	rightMargin +0
			pla
			sta	rightMargin +1

			jsr	SetVecFName		;Zeiger auf Dateiname nach ":r6"
							;kopieren (für ":FindFile").
			jsr	FindFile		;GEOS-Datei suchen.
			txa				;Diskettenfehler ?
			beq	:52			; => Nein, weiter...

			jsr	SetVecFName		;Zeiger auf Dateiname nach ":r6".
			LoadW	r0,Dlg_FileError	;Fehler ausgeben.
			jsr	DoDlgBox

			inc	ErrMissingFiles		;Datei nicht gefunden, Abbruch.

			lda	#"x"			;Fehler ausgeben.
			b $2c
::52			lda	#"<"			;"OK"-Status ausgeben.
			pha
			jsr	SetXYPosStatus
			pla
			jsr	PutChar

::55			clc				;Zeiger auf nächste Position für
			lda	PrntFNameY		;Ausgabe der Dateinamen setzen.
			adc	#PRNT_Y_HEIGHT
			cmp	#PRNT_Y_MAX		;Ende der Spalte erreicht?
			bcc	:54			; => Nein, weiter...

			AddVW	PRNT_X_WIDTH,PrntFNameX
			lda	#PRNT_Y_START

::54			sta	PrntFNameY
			inc	a0L			;Alle Dateien geprüft?
			bne	:51			;Nein, weiter...
::53			ldx	ErrMissingFiles
			rts

;*** Zeiger auf Dateinamentabelle setzen.
:SetVecFName		lda	a0L
			asl
			tay
			lda	FileNameTab +0,y	;Zeiger auf Dateiname nach ":r6"
			sta	r6L			;kopieren (für ":FindFile").
			lda	FileNameTab +1,y
			sta	r6H
			ora	r6L			;Ende erreicht?
			rts

;*** Koordinaten für Statusmeldung berechnen.
:SetXYPosStatus		clc				;Zeiger auf Ende der Zeile
			lda	PrntFNameX +0		;für "OK"/"ERR"-Meldung setzen.
			adc	#< PRNT_X_TAB
			sta	r11L
			lda	PrntFNameX +1
			adc	#> PRNT_X_TAB
			sta	r11H
			lda	PrntFNameY
			sta	r1H
			rts

;*** Alle GEOS-Dateien in das .CVT-Format (GeoConvert) wandeln.
;    Notwendig um alle Dateien zu einer Installationsdatei zu packen.
:STAGE2_CONVERT		lda	#$00			;Bildschirm löschen.
			jsr	SetPattern
			jsr	i_Rectangle
			b	$00,$c7
			w	$0000,$013f

			LoadW	r0,InfoTx_01
			jsr	PutString

			LoadW	r0,InfoTx_02
			jsr	PutString

			lda	curDrive
			jsr	SetDevice		;Laufwerk aktivieren und
			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...

			lda	#$00			;Zähler für Dateinamen löschen.
			sta	a0L

::51			jsr	SetVecFName		;Zeiger auf Dateiname einlesen.
;			tax				;Alle Dateien bearbeitet ?
			beq	:52			; => Ja, weiter...

			jsr	ConvertFile		;GEOS-Datei nach .CVT wandeln.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...

			inc	a0L			;Zeiger auf nächste Datei und
			jmp	:51			;weiter mit konvertieren...

::52			ldx	#NO_ERROR
			rts

::err			jsr	PrntDiskError
			ldx	#CANCEL_ERR
			rts

;*** Diskettenfehler ausgeben.
:PrntDiskError		stx	DskErrCode

			jsr	SetVecFName		;Zeiger auf Dateiname einlesen.
			MoveW	r6,a9

			LoadW	r0,Dlg_DiskError
			jsr	DoDlgBox

			rts

;*** Datei-Informationen einlesen.
:STAGE3_GETINFO		LoadW	r0,InfoTx_03
			jsr	PutString

			LoadW	a1,FNameTab1		;Zeiger auf Tabelle mit
							;Verzeichnis-Einträgen.

			lda	#$00			;Zähler für Dateinamen löschen.
			sta	a0L

::51			jsr	SetVecFName		;Zeiger auf Dateiname einlesen.
;			tax				;Alle Dateien bearbeitet ?
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

::53			jsr	SetVecFName		;Zeiger auf Dateiname einlesen.
			LoadW	r0,Dlg_FileError	;Fehler ausgeben.
			jsr	DoDlgBox

			ldx	#FILE_NOT_FOUND
			rts

::54			ldy	#$00			;Tabellen-Ende markieren.
			tya
::55			sta	(a1L),y
			iny
			bne	:55

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

::53			jsr	PrntDiskError
			ldx	#CANCEL_ERR
			rts

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

			ldx	#NO_ERROR
			rts

;*** Nicht benötigte Verzeichnis-Einträge löschen.
:STAGE4_CLEANUP		LoadW	r0,InfoTx_04
			jsr	PutString

			LoadW	a1,FNameTab1		;Zeiger auf Tabelle mit
							;Verzeichnis-Einträgen.

			lda	#$00			;Zähler für Dateinamen löschen.
			sta	a0L

::51			jsr	SetVecFName		;Zeiger auf Dateiname einlesen.
;			tax				;Alle Dateien eingelesen ?
			beq	:60			; => Ja, weiter...
			jsr	FindFile		;Dateieintrag suchen.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...

			lda	a0L			;Erste Datei ?
			bne	:56			; => Nein, weiter...

;--- Erste Datei umbenennen...
::52			ldy	#$03			;Name der Gesamtdatei
::53			lda	FName_TMP -3,y		;definieren.
			beq	:54
			sta	(r5L)         ,y
			iny
			bne	:53
::54			cpy	#$10			;Name auf 16-Zeichen mit
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
			bcc	:57

;--- Verzeichnisblock aktualisieren.
::58			jsr	PutBlock		;Aktuellen Verzeichnis-Eintrag
							;auf Diskette aktualisieren.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...

;--- Löschen fortsetzen.
			inc	a0L			;Zeiger auf nächste Datei und
			jmp	:51			;weiter mit konvertieren...

;--- Alle Dateien gelöscht.
::60			ldx	#NO_ERROR
			rts

;--- Fehler ausgeben.
::err			jsr	PrntDiskError
			ldx	#CANCEL_ERR
			rts

;*** PACKER: "SETUP.TMP"-Datei analysieren.
;    Für den Packer wird ein Kennbyte benötigt, welches dem Entpacker später
;    anzeigt, das nun gepackte Daten folgen. Da im Prinzip jedes Byte auch im
;    Programm vorkommen kann, muß ein einzlnes Byte, welches dem Kennbyte
;    entspricht, ebenfalls gepackt werden. Um den dadurch entstehenden
;    Overhead möglichst klein zu halten, wird ein Byte gesucht, das möglichst
;    selten im Programm vorkommt. Dieses Byte ist dann das Kennbyte für
;    gepackte Daten und wird in der gepackten Datei gespeichert.
:ByteCntL		= $5000
:ByteCntM		= $5100
:ByteCntH		= $5200
:STAGE5_ANALYZE		LoadW	r0,InfoTx_05
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

			ldx	#NO_ERROR
			rts

;*** "SETUP.TMP"-Datei packen.
:STAGE6_PACKFILE	LoadW	r0,InfoTx_06
			jsr	PutString

			jsr	InitGetByte		;Zeiger auf erstes Byte richten.

			lda	#$00
			sta	a0L			;Flag löschen: "Erstes Byte".
			sta	a2L			;Packbyte löschen.
			sta	a2H			;Packbyte-Zähler löschen.

			lda	PackCode
			jsr	PutByteToBuf
			cpx	#$00			;Diskettenfehler ?
			bne	:err			; => ja, Abbruch...

::51			jsr	GetByteToBuf		;Datenbyte einlesen.
			cpx	#$00			;Ende der Datei erreicht ?
			bne	:done			; => Ja, Ende...

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
			bne	:err			; => ja, Abbruch...
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
			bne	:err			; => ja, Abbruch...

			LoadB	a2H,$01			;Zähler für Bytes zurücksetzen..
			jmp	:51			;Weiter mit nächstem Byte.

;--- Dateiende erreicht.
::done			jsr	SendBytes		;Daten auf Diskette schreiben.
			cpx	#$00			;Diskettenfehler ?
			bne	:err			; => ja, Abbruch...
			jsr	WrData_LastSek		;Letzen Sektor speichern.
			ldx	#NO_ERROR
			rts

;--- Fehler ausgeben.
::err			jsr	PrntDiskError
			ldx	#CANCEL_ERR
			rts

;*** Verzeichnis-Eintrag erstellen.
:STAGE7_MAKECRC		jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			beq	:52			; => Nein, weiter...
::51			jmp	:err			;Fehlermeldung ausgeben.

;--- Prüfsumme erstellen unf .INF-Datei speichern.
::52			LoadW	r0,FName_TMP		;Temporäre Datei löschen.
			jsr	DeleteFile

			LoadW	r0,InfoTx_07
			jsr	PutString

			lda	Data1stSek +0
			ldx	Data1stSek +1
			jsr	PatchCRC		;Prüfsumme für Patchdaten
			txa				;erstellen. Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			lda	a0L			;Prüfsumme speichern.
			sta	CRC_CODE +0
			lda	a0H
			sta	CRC_CODE +1

			LoadW	r6 ,FNameSetup		;Setup-Datei suchen. Patch-Daten und
			LoadB	r7L,APPLICATION		;die Informationsdaten werden in der
			LoadB	r7H,1			;Setup-Datei als VLIR-Datensätze
			LoadW	r10,ClassSETUP		;gespeichert.
			jsr	FindFTypes
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch
			ldx	#FILE_NOT_FOUND
			lda	r7H			;Datei gefunden ?
			bne	:53			; => Nein, Abbruch...

			LoadW	r6 ,FNameSetup
			jsr	FindFile		;Setup-Datei suchen.
			txa				;Diskettenfehler ?
			bne	:53			; => Nein, weiter...

			ldx	#5 -1
::readDT		lda	dirEntryBuf +23,x	;Datum und Uhrzeit der
			sta	bufDateTime,x		;Setup-Datei zwischenspeichern.
			dex
			bpl	:readDT

			LoadW	r0,FNameSetup		;VLIR-Datei öffnen.
			jsr	OpenRecordFile
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch...

			lda	#$01			;Zeiger auf ersten Datensatz.
			jsr	PointRecord
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

			LoadW	r6 ,FNameSetup
			jsr	FindFile		;Setup-Datei suchen.
			txa				;Diskettenfehler ?
			beq	:54			; => Nein, weiter...
::53			jmp	:err

::54			ldy	#23
			ldx	#0
::writeDT		lda	bufDateTime,x		;Datum und Uhrzeit der
			sta	(r5L),y			;Setup-Datei wieder herstellen.
			inx
			iny
			cpy	#28
			bcc	:writeDT

;			ldy	#28			;Dateigröße korrigieren.
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
			sta	fileHeader +6
			lda	Data1stSek +1
			sta	fileHeader +7
			jsr	PutBlock		;Zeiger auf Patchdaten.
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch...

;--- Eintrag für SetupGD erstellt.
			ldx	#NO_ERROR
			rts

;--- Fehler ausgeben.
::err			jsr	PrntDiskError
			ldx	#CANCEL_ERR
			rts

;*** Variablen für Dateisuche.
:ErrMissingFiles	b $00
:PrntFNameX		w $0010
:PrntFNameY		b 30

;*** Dateiname für Setup-Datei.
:FNameSetup		s 17

;*** Dateiname MakeSetup-Datei.
if LANG = LANG_DE
:MkSetupName		b "MakeSetupGDOSde",NULL
endif
if LANG = LANG_EN
:MkSetupName		b "MakeSetupGDOSen",NULL
endif

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
if LANG = LANG_DE
			b "ACHTUNG!",NULL
::102			b "Quelldatei fehlt:",NULL
endif
if LANG = LANG_EN
			b "ERROR!",NULL
::102			b "Source file is missing:",NULL
endif

;*** Dialogbox: Diskettenfehler.
:Dlg_DiskError		b $81
			b DBTXTSTR ,$10,$10
			w :101
			b DBTXTSTR ,$10,$1c
			w :102
			b DBVARSTR ,$10,$28
			b a9L
			b DB_USR_ROUT
			w :103
			b OK       ,$02,$48
			b NULL

::101			b PLAINTEXT,BOLDON
if LANG = LANG_DE
			b "ACHTUNG!",NULL
::102			b "Diskettenfehler:",NULL
endif
if LANG = LANG_EN
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
:InfoTx_00		b PLAINTEXT
			b GOTOXY
			w PRNT_X_START
			b $0a
if LANG = LANG_DE
			b "Prüfe auf fehlende Dateien..."
endif
if LANG = LANG_EN
			b "Checking for missing files..."
endif
			b PLAINTEXT,NULL

:InfoTx_01		b PLAINTEXT
			b GOTOXY
			w PRNT_X_START
			b $10
if LANG = LANG_DE
			b "1. Alle Dateien sind vorhanden!",NULL
endif
if LANG = LANG_EN
			b "1. All files do exist!",NULL
endif

:InfoTx_02		b PLAINTEXT
			b GOTOXY
			w PRNT_X_START
			b $20
if LANG = LANG_DE
			b "2. Dateien nach SEQ wandeln...",NULL
endif
if LANG = LANG_EN
			b "2. Convert files to SEQ...",NULL
endif

:InfoTx_03		b GOTOXY
			w PRNT_X_START
			b $30
if LANG = LANG_DE
			b "3. Dateien zusammenfassen...",NULL
endif
if LANG = LANG_EN
			b "3. Merging files...",NULL
endif

:InfoTx_04		b GOTOXY
			w PRNT_X_START
			b $40
if LANG = LANG_DE
			b "4. Verzeichnis bereinigen...",NULL
endif
if LANG = LANG_EN
			b "4. Cleaning up directory...",NULL
endif

:InfoTx_05		b GOTOXY
			w PRNT_X_START
			b $50
if LANG = LANG_DE
			b "5. Datei analysieren...",NULL
endif
if LANG = LANG_EN
			b "5. Analyzing file...",NULL
endif

:InfoTx_06		b GOTOXY
			w PRNT_X_START
			b $60
if LANG = LANG_DE
			b "6. Datei packen...",NULL
endif
if LANG = LANG_EN
			b "6. Compress file...",NULL
endif

:InfoTx_07		b GOTOXY
			w PRNT_X_START
			b $70
if LANG = LANG_DE
			b "7. Prüfsumme erstellen...",NULL
endif
if LANG = LANG_EN
			b "7. Creating checksum...",NULL
endif
