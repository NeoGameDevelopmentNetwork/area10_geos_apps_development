; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** GEOS->SEQ: Dateien konvertieren (CONVERT).
;    Übergabe:		r6 = Zeiger auf Dateiname.
:ConvertFile		MoveW	r6,a1			;Zeiger auf Datei-Eintrag speichern.
			jsr	FindFile		;Datei auf Diskette suchen.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...

			MoveB	r1L,a3L			;Zeiger auf Verzeichnis-Sektor
			MoveB	r1H,a3H			;zwischenspeichern.
			MoveW	r5 ,a4			;Zeiger auf Verzeichnis-Eintrag
							;zwischenspeichern.

			ldy	#30 -1			;Verzeichnis-Eintrag in
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
			beq	GEOS_CBM		; => Nein, weiter...

;*** Diskettenfehler ausgeben.
::err			rts

;*** GEOS->SEQ: Konvertierung beginnen.
:GEOS_CBM		MoveB	r3L,a2L			;Belegten Sektor merken.
			MoveB	r3H,a2H
			jsr	PutDirHead		;BAM aktualisieren.

;--- Eintrag für CBM-Datei erzeugen.
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

			ldy	#30 -1			;Neuen Eintrag in Verzeichnis-
::53			lda	FileEntryBuf1,y		;Sektor kopieren.
			sta	(r5L)        ,y
			dey
			bpl	:53

			jsr	PutBlock		;Verzeichnis aktualisieren.
			txa				;Diskettenfehler ?
			bne	:58			; => Ja, Abbruch.

;--- Fortsetzung: GEOS nach SEQ.
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

;*** GEOS->SEQ: VLIR-Datei nach SEQ wandeln.
:GEOS_VLIR		jsr	EnterTurbo
			jsr	InitForIO

			jsr	SetVecHdrVLIR		;Zeiger auf VLIR-Sektor.
			jsr	ReadBlock		;VLIR-Sektor lesen.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch.

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
			bne	:err			; => Ja, Abbruch...

::53			LoadB	a6L,$00			;Länge des Datensatzes löschen.
			LoadW	r4 ,diskBlkBuf		;Zeiger auf Zwischenspeicher.

::54			lda	diskBlkBuf +0
			sta	r1L
			lda	diskBlkBuf +1
			sta	r1H
			jsr	ReadBlock		;Nächsten Datensatz-Sektor lesen.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...

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

;--- Fehler beim konvertieren.
::err			jmp	DoneWithIO		;Ende...

;*** Zeiger auf VLIR-Header.
:SetVecHdrVLIR		lda	FileEntryBuf2 +1
			sta	r1L
			lda	FileEntryBuf2 +2
			sta	r1H
			LoadW	r4,FileHdrBlock
			rts

;*** Packer: Quell-Datei öffnen.
:InitGetByte		jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...

			LoadW	r6,FName_TMP
			jsr	FindFile		;Quell-Datei auf Diskette suchen.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...

			lda	dirEntryBuf +1		;Zeiger auf ersten Sektor der
			sta	a3L			;Datei zwischenspeichern.
			lda	dirEntryBuf +2
			sta	a3H
			lda	#$00			;Zeiger für ":ReadLink" löschen.
			sta	a4L
			sta	a4H

;			ldx	#NO_ERROR
			rts

::err			jsr	PrntDiskError
			ldx	#CANCEL_ERR
			rts

;*** Packer: Byte aus Quell-Datei einlesen.
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

;*** Packer: Gepackte Daten speichern.
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

;*** Packer: Byte in Ziel-Datei speichern.
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
			jsr	WrData_NextSek		;Aktuellen Sektor auf Diskette
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

;*** Packer: Letzten Datensektor schreiben.
:WrData_LastSek		lda	#$00			;Anzahl Bytes in letztem Sektor
			sta	CopySektor +0		;speichern.
			lda	DataVec
			sta	CopySektor +1

;*** Packer: Aktuellen Sektor auf Diskette schreiben.
:WrData_NextSek		MoveB	DataSektor +0,r1L
			MoveB	DataSektor +1,r1H
			LoadW	r4,CopySektor
			jsr	PutBlock
			jmp	PutDirHead

;*** Packer: Freien Sektor auf Diskette suchen.
:GetFreeSek		inc	DataSekCnt +0		;Dateigröße korrigieren.
			bne	:51
			inc	DataSekCnt +1

::51			lda	#$01
			sta	r3L
			sta	r3H
			jmp	SetNextFree

;*** Variablen für Packer.
:FName_TMP		b "TempFile",NULL

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

:FormatCode1		b "MP3"
:FormatCode2		b " formatted GEOS file V1.0",NULL
