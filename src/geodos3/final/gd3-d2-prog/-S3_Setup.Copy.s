; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Einzelne Datei aus Setup-Archiv entpacken.
;
;Verwendete Speicheradressen:
;EXTERN:
; :EntryPosInArchiv  = Datei-Nr.
; :PackedBytes       = Gepackte Daten: $FF = Packer aktiv.
; :PackedByteCode    = Gepackte Daten: Bytewert.
; :PackedBytCount    = Gepackte Daten: Anzahl Bytes.
;
;INTERN:
; :ExtractFileType   = Dateityp.
; :BytesInCurWSek    = Anzahl Bytes in aktuellem Sektor für Ziel-Datei.
; :BytesInLastSek    = Anzahl Bytes in letztem Sektor der Ziel-Datei.
; :SizeSourceFile    = Anzahl Sektoren für Ziel-Datei.
; :WriteSekCount     = Zähler geschriebene Sektoren.
; :a7                = Zeiger auf Tabelle mit Dateieinträgen.
; :a8                = Zeiger auf Speicher für Treiberdatei-Info.
; :a9                = Zeiger auf Sektoren-Tabelle.
;
:ExtractFiles		jsr	ExtractCurFile		;Aktuelle Datei entpacken.
			txa				;Diskettenfehler?
			bne	EXTRACT_ERROR		; => Nein, weiter...
			rts

:EXTRACT_ERROR		pla				;Rücksprungadresse GEOS-MainLoop
			pla				;vom Stack löschen.

			stx	DskErrCode

			LoadW	r0,DLG_EXTRACT_ERR
			jsr	DoDlgBox		;Fehler anzeigen.
			jmp	ExitToDeskTop		;Zurück zum DeskTop.

;*** Alle Dateien der Gruppe entpacken.
;Übergabe: AKKU = Gruppen-Nr.
:ExtractCurFile		sta	ExtractFileType

			jsr	SetVecTopArchiv		;Zeiger auf Tabelle mit Dateinamen.

::51			lda	EntryPosInArchiv	;Entspricht Datei der geforderten
			asl				;Dateigruppe ?
			asl
			tax
			lda	FileDataTab +2,x
			cmp	ExtractFileType
			bne	:52			; => Nein, weiter...
			txa
			jsr	Decode1File		;Datei entpacken.
			txa				;Diskettenfehler ?
			bne	:53			; => Nein, weiter...

			lda	EntryPosInArchiv	;Gruppenkennung löschen.
			asl
			asl
			tax
			lda	#$00
			sta	FileDataTab +2,x

::52			jsr	SetVecNxEntry		;Alle Dateien analysiert ?
			bne	:51			; => Nein, weiter...
			ldx	#$00
::53			rts

;*** Datei entpacken.
;    Übergabe:		a7               = Zeiger auf Dateiinformationen.
;			EntryPosInArchiv = Datei-Nr.
:Decode1File		jsr	DeleteTarget		;Ziel-Datei löschen.

			jsr	AllocFileSek		;Erforderlichen Speicher belegen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			jsr	SetVec1stByte		;Zeiger auf erstes Byte.

			LoadW	a9,FreeSekTab		;Zeiger auf Tabelle mit freien
			jsr	DecodeNxByte		;Sektoren und Datei entpacken.
			jmp	CreateDirEntry
::51			rts

;*** Verzeichnis-Eintrag erstellen.
:CreateDirEntry		jsr	OpenTargetDrive		;Ziel-Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch...

			LoadB	r10L,$00
			jsr	GetFreeDirBlk		;Freien Eintrag suchen.
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch...

			tya
			tax
			lda	#$81			;Dateityp SEQ.
			sta	diskBlkBuf,x
			inx
			lda	Data1stSek +0		;Ersten Datensektor setzen.
			sta	diskBlkBuf,x
			inx
			lda	Data1stSek +1
			sta	diskBlkBuf,x
			inx
			ldy	#$05			;Dateiname kopieren.
::51			lda	(a7L),y
			sta	diskBlkBuf,x
			inx
			iny
			cpy	#$1e
			bcc	:51

			lda	WriteSekCount +0	;Größe der gepackten Datei
			sta	diskBlkBuf,x		;festlegen.
			inx
			lda	WriteSekCount +1
			sta	diskBlkBuf,x
			LoadW	r4,diskBlkBuf
			jsr	PutBlock		;Verzeichnis-Eintrag schreiben.
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch...

			jsr	PutDirHead		;BAM aktualisieren.
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch...
			jmp	Convert1File		;Datei nach GEOS wandeln.
::52			rts

;*** Nächstes Byte entpacken.
:DecodeNxByte		jsr	GetNxDataByte		;Nächstes Byte einlesen.
			cpx	#$ff			;Dateiende erreicht ?
			beq	:51			; => Ja, Ende...
			cpx	#NO_ERROR		;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch...

			jsr	PutBytTarget		;Byte in Zieldatei schreiben.
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch...

			lda	SizeSourceFile+1
			cmp	WriteSekCount +1
			bne	DecodeNxByte
			lda	SizeSourceFile+0
			cmp	WriteSekCount +0	;Alle Sektoren entpackt ?
			bne	DecodeNxByte		; => Nein, weiter...

::51			jmp	WriteLastSektor
::52			rts

;*** Byte in Ziel-Datei speichern.
:PutBytTarget		bit	firstByte		;Erstes Byte schreiben ?
			bmi	:51			; => Nein, weiter...
			dec	firstByte

			pha				;Byte speichern und freien
			jsr	GetSekTarget		;Sektor einlesen. Byte wieder
			pla				;zurücksetzen.

			ldy	r3L			;Ersten Sektor zwischenspeichern.
			sty	DataSektor +0
			sty	Data1stSek +0
			ldy	r3H
			sty	DataSektor +1
			sty	Data1stSek +1

			ldy	#$02
			bne	:52

::51			ldy	BytesInCurWSek		;Aktueller Sektor voll ?
			bne	:52			; => Nein, weiter...

			pha
			jsr	WrCurSektor		;Sektor auf Diskette schreiben.
			pla
			cpx	#$00
			bne	:54

			ldy	#$02
::52			sta	CopyBuffer,y		;Byte in Sektorspeicher
			iny				;kopieren.
			sty	BytesInCurWSek		;Speicher voll ?
			bne	:53			; => Nein, weiter...

			inc	WriteSekCount +0	;Anzahl Sektoren korrigieren.
			bne	:53
			inc	WriteSekCount +1

::53			ldx	#$00
::54			rts

;*** Aktuellen Sektor auf Diskette schreiben.
:WrCurSektor		jsr	GetSekTarget		;Nächsten freien Sektor einlesen.

			lda	r3L			;LinkBytes in aktuellem Sektor
			sta	CopyBuffer +0		;vermerken und Sektor auf
			lda	r3H			;Diskette schreiben.
			sta	CopyBuffer +1
			jsr	PutSekTarget
			txa
			bne	:51

			jsr	SwapSourceDrive		;Quell-Laufwerk öffnen.

			lda	CopyBuffer +0
			sta	DataSektor +0
			lda	CopyBuffer +1
			sta	DataSektor +1
::51			rts

;*** Zeiger auf erstes Byte einer datei im Archiv setzen.
:SetVec1stByte		jsr	SwapSourceDrive		;Quell-Laufwerk öffnen.

			lda	EntryPosInArchiv	;Zeiger auf ersten Sektor und
			asl				;erstes Byte innerhalb des Sektors
			asl				;speichern.
			tay
			lda	PackFileSAdr,y
			sta	r1L
			iny
			lda	PackFileSAdr,y
			sta	r1H
			iny
			lda	PackFileSAdr,y
			sta	Vec2SourceByte

			jsr	GetSek_dskBlkBuf	;Ersten Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	InitError		; => Ja, Abbruch...

			lda	#$00
			sta	firstByte		;Flag: "Ersten Sektor merken".
			sta	PackedByteCode		;Anzahl gepackter Bytes.
			sta	PackedBytCount		;Gepacktes Byte.
			sta	PackedBytes		;Flag: "Packer nicht aktiv".

;*** Anzahl Sektoren in entpackter Datei auslesen.
:InitTargetFile		ldy	#$1e			;Anzahl benötigter Blocks einlesen.
			lda	(a7L),y
			sta	SizeSourceFile+0
			iny
			lda	(a7L),y
			sta	SizeSourceFile+1

			ldy	#$01			;Anzahl Bytes in letztem Sektor
			lda	(a7L),y			;einlesen.
			sta	BytesInLastSek

			lda	#$02			;Zeiger innerhalb Sektorspeicher
			sta	BytesInCurWSek		;auf Startwert zurücksetzen.

			ldx	#$00			;Sektorzähler löschen.
			stx	WriteSekCount +0
			stx	WriteSekCount +1
:InitError		rts

;*** Freie Sektoren für Datei belegen.
:AllocFileSek		jsr	InitTargetFile
			txa
			bne	AllocSekErr

			lda	SizeSourceFile+0	;Anzahl Sektoren in Desamtdatei
			sta	AllocSekCount +0	;einlesen.
			lda	SizeSourceFile+1
			sta	AllocSekCount +1

;*** Freie Sektoren auf Diskette belegen.
;    Übergabe:		AllocSekCount = Anzahl benötigte Sektoren.
:AllocUsrFSek		LoadW	a9 ,FreeSekTab		;Zeiger auf Sektortabelle.

			jsr	OpenTargetDrive		;Ziel-Diskette öffnen.
			txa
			bne	AllocSekErr

::51			lda	AllocSekCount +0
			ora	AllocSekCount +1	;Speicher für Ziel-Datei belegt ?
			bne	:52			; => Nein, weiter...
			jmp	PutDirHead		;BAM aktualisieren.

::52			lda	:SearchSektor +0
			sta	r3L
			lda	:SearchSektor +1
			sta	r3H
			jsr	SetNextFree		;Freien Sektor suchen.
			txa				;Diskettenfehler ?
			beq	:52a

			lda	#$01
			sta	r3L
			sta	r3H
			jsr	SetNextFree		;Freien Sektor suchen.
			txa				;Diskettenfehler ?
			bne	AllocSekErr		; => Ja, Abbruch...

::52a			ldy	#$00			;Freien Sektor in Sektortabelle
			lda	r3L			;übertragen.
			sta	:SearchSektor +0
			sta	(a9L),y
			iny
			lda	r3H
			sta	:SearchSektor +1
			sta	(a9L),y
			AddVBW	2,a9

			lda	AllocSekCount +0
			bne	:53
			dec	AllocSekCount +1
::53			dec	AllocSekCount +0	;Sektorzähler korrigieren und
			jmp	:51			;weiter mit nächstem Sektor.

::SearchSektor		b $01,$01

:AllocSekErr		rts

;*** Freien Sektor auf Ziel-Laufwerk einlesen.
:GetSekTarget		ldy	#$00			;Zeiger auf Sektortabelle und
			lda	(a9L),y			;nächsten Sektor einlesen.
			sta	r3L
			iny
			lda	(a9L),y
			sta	r3H
			AddVBW	2,a9
			rts

;*** Aktuellen Sektor auf Diskette schreiben.
:PutSekTarget		PushW	r1			;Register zwischenspeichern.
			PushW	r4

			jsr	PrintPercent
			jsr	SwapTargetDrive		;Ziel-Laufwerk aktivieren.

			lda	DataSektor +0		;Zeiger auf Ziel-Sektor setzen.
			sta	r1L
			lda	DataSektor +1
			sta	r1H
			LoadW	r4,CopyBuffer
			jsr	PutBlock		;Sektor auf Diskette schreiben.
			PopW	r4
			PopW	r1
			rts

;*** Datei wurde entpackt, letzte daten auf Diskette schreiben.
:WriteLastSektor	jsr	SwapTargetDrive		;Ziel-Laufwerk aktivieren.
			jsr	PrintPercent

			lda	#$00			;Anzahl Bytes in letztem Sektor
			sta	CopyBuffer +0		;zwischenspeichern.
			lda	BytesInLastSek
			sta	CopyBuffer +1
			lda	DataSektor +0
			sta	r1L
			lda	DataSektor +1
			sta	r1H
			LoadW	r4,CopyBuffer
			jmp	PutBlock		;Sektor auf Diskette schreiben.

;*** Byte in Ziel-Datei speichern.
:PutBytDskDrv		inc	BytesInTmpWSek		;Anzahl Bytes +1. Sektor voll ?
			bne	:52			; => Nein, weiter...

			inc	WrTmpSekCount +0	;Anzahl Sektoren +1.
			bne	:51
			inc	WrTmpSekCount +1
::51			ldy	#$02			;Zeiger auf Byte zurücksetzen.
			sty	BytesInTmpWSek

::52			bit	PutByteToDisk		;Byte auf Diskette schreiben ?
			bmi	:53			; => Nein, weiter...
			jmp	PutBytTarget		; => Byte auf Diskette schreiben.

::53			ldx	#NO_ERROR		; => Byte ignorieren.
			rts

;*** Variablen.
:ExtractFileType	b $00				;Datei-Gruppe.

:AllocSekCount		w $0000				;Anzahl reservierter Sektoren.

:firstByte		b $00				;$00 = Ersten Sektor merken.
:Data1stSek		b $00,$00			;Erster Sektor der Datei.
:DataSektor		b $00,$00			;Aktueller Sektor der Datei.

:BytesInCurWSek		b $00				;Bytes: Aktuellen Sektor der Datei.
:BytesInLastSek		b $00				;Bytes: Letzter Sektor der Datei.

:WriteSekCount		w $0000				;Anzahl Sektoren für Datei.
:SizeSourceFile		w $0000				;Größe der aktuellen Datei.

;*** Dialogbox: Fehler beim entpacken der Datei.
:DLG_EXTRACT_ERR	b $81
			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR ,$10,$0b
			w :10
			b DBTXTSTR ,$10,$20
			w :11
			b DBTXTSTR ,$10,$2a
			w :12
			b DB_USR_ROUT
			w PrntErrCode
			b OK       ,$10,$48
			b NULL

if Sprache = Deutsch
::10			b PLAINTEXT,BOLDON
			b "INSTALLATIONSFEHLER"
			b NULL
::11			b "Die Datei konnte nicht",NULL
::12			b "entpackt werden!",NULL
endif
if Sprache = Englisch
::10			b PLAINTEXT,BOLDON
			b "INSTALLATION FAILED"
			b NULL
::11			b "Not able to extract",NULL
::12			b "this file!",NULL
endif
