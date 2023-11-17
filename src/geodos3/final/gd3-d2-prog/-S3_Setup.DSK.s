; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Alle Laufwerkstreiber kopieren.
:CopyDskDev		jsr	CopyDskDevFile		;Dateien kopieren und
			jmp	CopyMenu		;zurück zum Hauptmenü.

:CopyDskDevFile		lda	#$ff
			sta	CopyFlgDskDrive
			lda	#< Inf_CopyDskDrv
			ldx	#> Inf_CopyDskDrv
			jsr	ViewInfoBox		;Infomeldung ausgeben.
			lda	#$03			;Systemdateien aus Archiv
			jmp	ExtractFiles		;entpacken.

;*** Zu kopierende Laufwerkstreiber wählen.
:CopySlctDkDv		jsr	GetDskDrvInfo		;Informationen aus Datei mit
							;Laufwerkstreibern einlesen.

			ldy	#$00			;VLIR-Informationen der Treiber-
::51			lda	DskInfTab+2*254,y	;Datei zwischenspeichern.
			sta	DskDvVLIR    +2,y
			sta	DskDvVLIR_org+2,y
			iny
			cpy	#254
			bcc	:51

			jsr	ClearScrnArea		;Menü-/Status-Fenster löschen.
			LoadW	r0,mnuSlctDisk		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,txSlctDisk1
			jsr	PutString

			LoadB	a0L,1
			LoadW	a1 ,DskInf_Names +17

;--- Aktuellen Treiber anzeigen und Abfrage starten.
:PrntCurDkDev		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$71,$7b
			w	$0020,$00ff

			MoveW	a1 ,r0
			LoadW	r11,$0020
			LoadB	r1H,$7a
			jsr	PutString

			LoadW	r0,txSlctDisk2
			jmp	PutString

;--- Treiber nicht kopieren.
:ReSlctDkDrv		ldy	a0L
			lda	#$00
			sta	DskInf_Modes,y

;--- Zeiger auf nächste Datei.
:NextDkDrv		AddVBW	17,a1			;Zeiger auf nächsten Treiber.

			inc	a0L
			CmpBI	a0L,64			;Alle Treiber überprüft ?
			beq	:51			; => Ja, Ende...

			ldy	#$00
			lda	(a1L),y			;Noch ein Treiber in Tabelle ?
			bne	PrntCurDkDev		; => Ausgeben und Abfrage starten.
::51			jmp	InitCopyDkDv		;Treiber kopieren.

;*** Informationsdatei packen & korrigieren.
:InitCopyDkDv		lda	#$ff
			sta	CopyFlgDskDrive
			lda	#< Inf_CopyDskDrv
			ldx	#> Inf_CopyDskDrv
			jsr	ViewInfoBox		;Infomeldung ausgeben.

			lda	#< DskInf_Modes		;Vektor auf Laufwerkstyp.
			sta	r0L
			sta	r1L
			lda	#> DskInf_Modes
			sta	r0H
			sta	r1H
			lda	#< DskInf_VlirSet	;Vektor auf VLIR-Zeiger.
			sta	r2L
			sta	r3L
			lda	#> DskInf_VlirSet
			sta	r2H
			sta	r3H
			lda	#< DskInf_Names		;Vektor auf Treibernamen.
			sta	r4L
			sta	r5L
			lda	#> DskInf_Names
			sta	r4H
			sta	r5H

			ldy	#$00
			sty	r6L			;Zeiger auf ersten Eintrag in neuer
			sty	r6H			;und alter Tabelle setzen.
			beq	:52

::51			ldy	#$00
			lda	(r0L),y			;Treiber übernehmen ?
			beq	:54			; => Nein, weiter...

::52			lda	(r0L),y			;Informationen für aktuellen
			sta	(r1L),y			;Treiber in neue Liste kopieren.
			lda	(r2L),y
			sta	(r3L),y
			iny
			lda	(r2L),y
			sta	(r3L),y

			ldy	#$00
::53			lda	(r4L),y
			sta	(r5L),y
			iny
			cpy	#17
			bcc	:53

			ldx	#r1L
			jsr	Pos2NxEntry
			inc	r6H

::54			ldx	#r0L
			jsr	Pos2NxEntry
			inc	r6L
			lda	r6L
			cmp	#64			;Alle Treiber-Einträge kopiert ?
			bcc	:51			; => Nein, weiter...
::55			lda	r6H			;Den Rest der neuen Treiber-
			cmp	#64			;Tabelle löschen.
			beq	:57

			ldy	#$00
			tya
			sta	(r1L),y
			sta	(r3L),y
			iny
			sta	(r3L),y
			dey
::56			sta	(r5L),y
			iny
			cpy	#17
			bcc	:56

			ldx	#r1L
			jsr	Pos2NxEntry
			inc	r6H
			jmp	:55
::57			jmp	PrepareCopyDkDv		;Laufwerkstreiber kopieren.

;*** Zeiger auf nächsten Eintrag.
:Pos2NxEntry		inc	zpage +0,x
			bne	:51
			inc	zpage +1,x

::51			lda	#2
			jsr	:52
			lda	#17
::52			sta	:53 +1
			inx
			inx
			inx
			inx
			lda	zpage +0,x
			clc
::53			adc	#$02
			sta	zpage +0,x
			bcc	:54
			inc	zpage +1,x
::54			rts

;*** Informationen für Kopiervorgang aufbereiten.
:PrepareCopyDkDv	jsr	FindDskDvEntry		;Eintrag für Treiberdatei suchen.
			cpx	#NO_ERROR		;Eintrag gefunden ?
			bne	:55			; => Nein, Abbruch...

			ldy	#$04
::51			lda	DskDvVLIR_org,y		;Nicht verfügbare VLIR-Datensätze
			beq	:52			;in Original-Treiberdatei in der
			lda	#$00			;Kopie ebenfalls als "Nicht vor-
			sta	DskDvVLIR    ,y		;handen" markieren.
			iny
			lda	#$ff
			sta	DskDvVLIR    ,y
			dey
::52			iny
			iny
			bne	:51

			ldy	#$02
			sty	r0L
::53			lda	DskInf_VlirSet ,y	;Verfügbare VLIR-Datensätze in
			beq	:54			;Original-Treiberdatei in der
			asl				;Kopie ebenfalls als "Verfügbar"
			tax				;markieren.
			lda	DskDvVLIR_org+2,x
			sta	DskDvVLIR    +2,x
			lda	DskDvVLIR_org+3,x
			sta	DskDvVLIR    +3,x
			iny
			cpy	#63 *2			;Max. 63xTreiber + 63xInit möglich.
			bcc	:53

::54			jsr	ExtractDskDrv		;Laufwerkstreiber entpacken.

			jsr	FindDskDvEntry		;Eintrag für Treiberdatei suchen.
			txa				;Eintrag gefunden ?
			bne	:55			; => Nein, Abbruch...

;			lda	#$00			;Gruppenkenung löschen.
			sta	FileDataTab +2,y

::55			jmp	CopyMenu		;zurück zum Hauptmenü.

;*** Informationen aus Datei mit Laufwerkstreibern einlesen.
;    Dazu werden aus der gepackten Datei die Sektoren in den Speicher
;    entpackt, welche a).CVT-Kennung, b)InfoBlock, c)VLIR-Header und
;    d)die Treiberliste enthalten.
:GetDskDrvInfo		jsr	SwapSourceDrive		;Quell-Laufwerk öffnen.
			jsr	FindDskDvEntry		;Eintrag für Treiberdatei suchen.
			cpx	#NO_ERROR		;Eintrag gefunden ?
			beq	:51			; => Ja, weiter...
			rts

::51			jsr	SetVec1stByte		;Zeiger auf erstes Byte setzen.

			LoadW	a8,DskInfTab

;*** Daten einlesen.
:DecodeDskDrvInf	jsr	GetNxDataByte		;Nächstes Byte einlesen.
			cpx	#$ff			;Dateiende erreicht ?
			beq	:51			; => Ja, Ende...
			cpx	#NO_ERROR		;Diskettenfehler ?
			bne	EndDkInfoFile		; => Ja, Abbruch...

			jsr	WrDskInfByte		;Byte in Speicher kopieren.

			lda	WriteSekCount +0
			cmp	#$04			;Alle Infos eingelesen ?
			bcc	DecodeDskDrvInf		; => Nein, weiter...

			lda	#$02
			clc
			adc	DskInfTab +2*254
			cmp	WriteSekCount +0
			bcs	DecodeDskDrvInf

::51			ldx	#NO_ERROR
:EndDkInfoFile		rts

;*** Byte in Ziel-Speicher übertragen.
:WrDskInfByte		ldy	#$00
			sta	(a8L),y
			inc	a8L
			bne	:51
			inc	a8H

::51			inc	BytesInCurWSek
			bne	:52

			ldy	#$02
			sty	BytesInCurWSek
			inc	WriteSekCount +0
			bne	:51
			inc	WriteSekCount +1

::52			rts

;*** Laufwerkstreiber entpacken.
:ExtractDskDrv		jsr	DecodeDskDrvFile	;Laufwerkstreiber entpacken.
			txa				;Diskettenfehler ?
			bne	:51			; => Nein, weiter...

			LoadW	r6,File_GD3_Disk
			jsr	FindFile		;Treiberdatei auf Diskette suchen.
			txa				;Diskettenfehler ?
			bne	:51			; => Nein, weiter...

			LoadW	r0,File_GD3_Disk
			jsr	OpenRecordFile		;Treiberdatei öffnen und
			txa				;Diskettenfehler ?
			bne	:51			; => Nein, weiter...

			lda	#$00			;Informationen über verfügbare
			jsr	PointRecord		;Treiber aktualisieren.
			LoadW	r2,64+64*2+64*17
			LoadW	r7,DskInfTab +3*254
			jsr	WriteRecord
			txa				;Diskettenfehler ?
			bne	:51			; => Nein, weiter...

			jsr	UpdateRecordFile
			txa				;Diskettenfehler ?
			bne	:51			; => Nein, weiter...

			jmp	CloseRecordFile

::51			jmp	EXTRACT_ERROR

;*** Laufwerkstreiber-Datei entpacken.
;    Übergabe:		a7  = Zeiger auf Datei-Eintrag.
:DecodeDskDrvFile	jsr	DeleteTarget		;Ziel-Datei löschen.

;--- Speicher für Treiberdatei in BAM reservieren.
			lda	#$03			;Die ersten beiden Bytes im VLIR-
			sta	DskDvVLIR_org +0	;Header sind unbenutzt. Diese werden
			sta	DskDvVLIR     +0	;hier mit den Daten für den .CVT-
			lda	#$ff			;Header gefüllt:
			sta	DskDvVLIR_org +1	;Anzahl Sektoren        : $03
			sta	DskDvVLIR     +1	;Bytes in letztem Sektor: $FF = 256

			ldy	#$00			;Anzahl benötigter Sektoren
			sty	AllocSekCount +0	;für Ziel-Datei berechnen.
			sty	AllocSekCount +1
::51			lda	DskDvVLIR      ,y
			clc
			adc	AllocSekCount +0
			sta	AllocSekCount +0
			bcc	:52
			inc	AllocSekCount +1
::52			iny
			iny
			bne	:51

			jsr	AllocUsrFSek		;Erforderlichen Speicher belegen.
			txa
			bne	:55

;--- Kopiervorgang initialisieren.
			jsr	SetVec1stByte		;Zeiger auf erstes Byte.

			lda	#$02
			sta	BytesInTmpWSek

			lda	#$00
			sta	VecDskFileHdr		;Zeiger auf VLIR-Datensatz.
			sta	PutByteToDisk		;$00 = VLIR-Datensatz schreiben.

			LoadW	a9,FreeSekTab		;Zeiger auf "Freier Sektor"-Tabelle.

;--- Treiberdatei kopieren.
::53			jsr	InitNxDskDvVLIR		;Nächsten Treiber kopieren.
			txa				;Diskettenfehler?
			bne	:55			; => Ja, Abbruch...

			inc	VecDskFileHdr
			CmpBI	VecDskFileHdr,127	;Alle Treiber kopiert ?
			bne	:53			; => Nein, weiter...

			jsr	WriteLastSektor		;Letzten Sektor aktualisieren.
			txa
			bne	:55

;--- Treiberdatei kopiert.
;    VLIR-Header in .CVT-Datei korrigieren.
			LoadW	r4,diskBlkBuf		;Informationen der .CVT-Datei
							;über die VLIR-Datei aktualisieren.
			lda	Data1stSek +0		;Da nicht alle VLIR-Datensätze
			ldx	Data1stSek +1		;kopiert wurden, ist der Inhalt der
			jsr	GetDskDvBlock		;.CVT-Datei nicht korrekt. Der
			bne	:55			;VLIR-Header wird hier durch den
							;beim kopieren erstellten Header
			lda	diskBlkBuf +0		;ersetzt.
			ldx	diskBlkBuf +1
			jsr	GetDskDvBlock
			bne	:55

			lda	diskBlkBuf +0
			ldx	diskBlkBuf +1
			jsr	GetDskDvBlock
			bne	:55

			ldx	#$02
::54			lda	diskBlkBuf,x
			sta	fileHeader,x
			lda	DskDvVLIR ,x
			sta	diskBlkBuf,x
			inx
			bne	:54
			jsr	PutBlock
			txa
			bne	:55

			jmp	CreateDirEntry
::55			rts

;--- Einzelnen Sektor einlesen.
:GetDskDvBlock		sta	r1L
			stx	r1H
			jsr	GetBlock
			txa
			rts

;*** Nächsten Laufwerkstreiber entpacken.
:InitNxDskDvVLIR	lda	#$00			;Zähler für geschriebene Sektoren
			sta	WrTmpSekCount +0	;in datensatz löschen.
			sta	WrTmpSekCount +1

			lda	VecDskFileHdr
			asl
			tax
			lda	DskDvVLIR_org+0,x	;Anzahl Sektoren in
			sta	VDataSekCount		;aktuellem Datensatz einlesen.
			beq	:51

			lda	#$ff
			sta	PutByteToDisk
			lda	DskDvVLIR    +0,x	;Datensatz kopieren ?
			beq	DecodeNxDkDvByte	; => Ja, weiter...
			inc	PutByteToDisk		; => Nein, nicht kopieren...
			lda	DskDvVLIR_org+1,x	;Anzahl Bytes in letztem Datensatz
			sta	BytesInLastSek		;bzw. im letzten Sektor der
			jmp	DecodeNxDkDvByte	;Treiberdatei einlesen und merken.

::51			ldx	#NO_ERROR
			rts

;*** Bytes für einzelnen Treiber kopieren.
:DecodeNxDkDvByte	jsr	GetNxDataByte		;Nächstes Byte einlesen.
			cpx	#$ff			;Dateiende erreicht ?
			beq	:51			; => Ja, Ende...
			cpx	#NO_ERROR		;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch...

			jsr	PutBytDskDrv		;Byte in Zieldatei speichern.
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch...

			lda	WrTmpSekCount +0
			cmp	VDataSekCount +0	;Alle Sektoren / Treiber kopiert ?
			bne	DecodeNxDkDvByte	; => Nein, weiter...
::51			ldx	#NO_ERROR
::52			rts

;*** Eintrag für Treiberdatei in Dateiliste suchen.
:FindDskDvEntry		jsr	SetVecTopArchiv

			ldx	#NO_ERROR
::51			lda	EntryPosInArchiv
			asl
			asl
			tay
			lda	FileDataTab +2,y	;Eintrag in Dateitabelle für
			cmp	#$03			;Treiberdatei suchen.
			beq	:52			; => Gefunden, weiter...

			jsr	SetVecNxEntry
			bne	:51
			ldx	#FILE_NOT_FOUND		;Fehler: "File not found!"
::52			rts

;*** Variablen.
:VecDskFileHdr		b $00
:VDataSekCount		b $00

;*** Laufwerkstreiber auswählen.
:mnuSlctDisk		b $04
			w $0000
			b $00

			w Icon_10
			b Icon4x1 ,Icon4y
			b Icon_10x,Icon_10y
			w NextDkDrv

			w Icon_11
			b Icon4x2 ,Icon4y
			b Icon_11x,Icon_11y
			w ReSlctDkDrv

			w Icon_07
			b Icon4x3 ,Icon4y
			b Icon_07x,Icon_07y
			w InitCopyDkDv

			w Icon_12
			b Icon4x4 ,Icon4y
			b Icon_12x,Icon_12y
			w ExitToDeskTop

;*** Laufwerkstreiber auswählen.
:txSlctDisk1		b PLAINTEXT
			b GOTOXY
			w $0018
			b $58
if Sprache = Deutsch
			b "Soll der folgende Laufwerkstreiber auf der"
endif
if Sprache = Englisch
			b "Should the following disk-driver be installed"
endif
			b GOTOXY
			w $0018
			b $60
if Sprache = Deutsch
			b "Startdiskette installiert werden ?"
endif
if Sprache = Englisch
			b "to the bootdisk ?"
endif
			b GOTOXY
			w $0020
			b $70
if Sprache = Deutsch
			b "Laufwerkstreiber für"
endif
if Sprache = Englisch
			b "Disk-driver for"
endif

			b GOTOXY
			w IconT4x1
			b IconT4y1
if Sprache = Deutsch
			b "Kopieren"
endif
if Sprache = Englisch
			b "Copy"
endif

			b GOTOXY
			w IconT4x2
			b IconT4y1
if Sprache = Deutsch
			b "Nicht"
endif
if Sprache = Englisch
			b "Do not"
endif
			b GOTOXY
			w IconT4x2
			b IconT4y2
if Sprache = Deutsch
			b "Kopieren"
endif
if Sprache = Englisch
			b "Copy"
endif

			b GOTOXY
			w IconT4x3
			b IconT4y1
if Sprache = Deutsch
			b "Installation"
endif
if Sprache = Englisch
			b "Continue with"
endif
			b GOTOXY
			w IconT4x3
			b IconT4y2
if Sprache = Deutsch
			b "fortsetzen"
endif
if Sprache = Englisch
			b "installation"
endif

			b GOTOXY
			w IconT4x4
			b IconT4y1
if Sprache = Deutsch
			b "Setup"
endif
if Sprache = Englisch
			b "Cancel"
endif
			b GOTOXY
			w IconT4x4
			b IconT4y2
if Sprache = Deutsch
			b "abbrechen"
endif
if Sprache = Englisch
			b "Setup"
endif
			b NULL

:txSlctDisk2		b PLAINTEXT
if Sprache = Deutsch
			b " - Laufwerk ?"
endif
if Sprache = Englisch
			b " - drive ?"
endif
			b NULL
