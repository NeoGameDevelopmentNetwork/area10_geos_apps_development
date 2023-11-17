; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** VLIR-Datei öffnen.
:xOpenRecordFile	lda	r0H			;Darf nicht geändert werden!
			sta	r6H			;GeoPublish übergeht diese
			lda	r0L			;Befehlsbytes.
			sta	r6L
			jsr	FindFile		;Dateieintrag suchen.
			txa				;Diskettenfehler ?
			bne	NoRecordFlag		;Ja, Abbruch...

;*** Hier Einsprung der von GeoPublish errechnet wird!!!
			ldx	#$0a
			ldy	#$00
			lda	(r5L),y			;Dateityp-Byte einlesen.
			and	#$3f
			cmp	#$03			;"USR"-Datei ?
			bne	NoRecordFlag		;Nein, Fehler...

			ldy	#$15
			lda	(r5L),y			;VLIR-Datei ?
			cmp	#$01			;Nein, Fehler...
			bne	NoRecordFlag

			tay
			lda	(r5L),y			;Track/Sektor des VLIR-Headers
			sta	VLIR_HeaderTr		;in Zwischenspeicher.
			iny
			lda	(r5L),y
			sta	VLIR_HeaderSe
			lda	r1H			;Verzeichniseintrag der VLIR-
			sta	VLIR_HdrDirSek+1	;Datei in Zwischenspeicher.
			lda	r1L
			sta	VLIR_HdrDirSek+0
			lda	r5H
			sta	VLIR_HdrDEntry+1
			lda	r5L
			sta	VLIR_HdrDEntry+0
			lda	dirEntryBuf+29		;Dateigröße zwischenspeichern.
			sta	fileSize+1
			lda	dirEntryBuf+28
			sta	fileSize+0
			jsr	VLIR_GetHeader		;VLIR-Header einlesen.
			txa				;Diskettenfehler ?
			bne	NoRecordFlag		;Ja, Abbruch...
			sta	usedRecords		;Anzahl Records löschen.

			ldy	#$02			;Anzahl belegter Records
::51			lda	fileHeader +0,y		;in VLIR-Datei zählen.
			ora	fileHeader +1,y
			beq	:52
			inc	usedRecords
			iny
			iny
			bne	:51

::52			ldy	#$00
			lda	usedRecords		;Datei leer ?
			bne	:53			;Nein, weiter...
			dey				;Flag: "Leere VLIR-Datei".
::53			sty	curRecord
			ldx	#$00
			stx	fileWritten
			rts

;*** VLIR-Datei schließen.
:xCloseRecordFile	jsr	xUpdateRecFile
:NoRecordFlag		lda	#$00
			sta	VLIR_HeaderTr
			rts

;*** VLIR-Datei aktualisieren.
:xUpdateRecFile		ldx	fileWritten		;Daten geändert ?
			beq	NoFunc6			; => Nein, weiter... ACHTUNG!
							;Sprung nach ":51" notwendig,
							;damit AKKU auf $00 gesetzt
							;wird wie im Orginal GEOSV2!

			jsr	VLIR_PutHeader		;VLIR-Header speichern.
			txa				;Diskettenfehler ?
			bne	NoFunc6			;Ja, Abbruch...

			lda	VLIR_HdrDirSek+1
			sta	r1H
			lda	VLIR_HdrDirSek+0
			sta	r1L
			jsr	GetBlock_dskBuf		;Verzeichnissektor lesen.
			txa				;Diskettenfehler ?
			bne	NoFunc6			;Ja, Abbruch...

			lda	VLIR_HdrDEntry+1	;Zeiger auf Verzeichniseintrag.
			sta	r5H
			lda	VLIR_HdrDEntry+0
			sta	r5L
			jsr	SetFileDate

			ldy	#$1c
			lda	fileSize+0		;Dateigröße zurückschreiben.
			sta	(r5L),y
			iny
			lda	fileSize+1
			sta	(r5L),y
			jsr	PutBlock_dskBuf
			txa				;Diskettenfehler ?
			bne	NoFunc6			;Ja, Abbruch...
			sta	fileWritten		;Daten aktualisiert,
			jmp	PutDirHead		;BAM auf Diskette speichern.

;******************************************************************************
;*** Zeiger auf nächsten Datensatz der VLIR-Datei.
;:xNextRecord		lda	curRecord
;			clc
;			adc	#$01
;			jmp	xPointRecord

;*** Zeiger auf vorherigen Datensatz der VLIR-Datei.
;:xPreviousRecord	lda	curRecord
;			sec
;			sbc	#$01
;******************************************************************************

;*** Zeiger auf nächsten Datensatz der VLIR-Datei.
:xNextRecord		lda	#$01
			b $2c

;*** Zeiger auf vorherigen Datensatz der VLIR-Datei.
:xPreviousRecord	lda	#$ff
			clc
			adc	curRecord

;*** Zeiger auf Datensatz der VLIR-Datei positionieren.
:xPointRecord		tax
			bmi	:51
			cmp	usedRecords		;Record verfügbar ?
			bcs	:51			;Nein, Fehler...
			sta	curRecord		;Neuen Record merken.

			jsr	VLIR_Get1stSek		;Zeiger auf ersten Sektor.

			ldy	r1L			;$00 = Nicht angelegt.
			ldx	#$00
			b $2c
::51			ldx	#$08
::52			lda	curRecord
:NoFunc6		rts

;*** Datensatz aus VLIR-Datei löschen.
:xDeleteRecord		ldx	#$08
			lda	curRecord		;Record verfügbar ?
			bmi	:53			;Nein, -> Fehler ausgeben...

			jsr	VLIR_GetCurBAM		;BAM im Speicher aktualisieren.
			txa				;Diskettenfehler ?
			bne	:53			;Ja, Abbruch...

			jsr	VLIR_Get1stSek		;Zeiger auf ersten Sektor.

			lda	curRecord		;Zeiger auf Record in
			sta	r0L 			;VLIR-Header.
			jsr	VLIR_DelRecEntry	;Record-Eintrag löschen.
			txa				;Diskettenfehler ?
			bne	:53			;Ja, Abbruch...

			lda	curRecord		;Zeiger auf aktuellen Record
			cmp	usedRecords		;korrigieren.
			bcc	:51
			dec	curRecord

::51			ldx	r1L			;War Record angelegt ?
			beq	:53			;Nein, Ende...
			jsr	FreeSeqChain		;Sektorkette freigeben.
			txa				;Diskettenfehler ?
			bne	:53			;Ja, Abbruch...

			jsr	SubFileSize		;Dateigröße korrigieren.
::52			ldx	#$00			;Kein Fehler, OK.
::53			rts

;*** Dateilänge korrigieren.
:SubFileSize		lda	fileSize+0		;Dateigröße korrigieren.
			sec
			sbc	r2L
			sta	fileSize+0
			bcs	:51
			dec	fileSize+1
::51			rts

;*** Datensatz in VLIR-Datei einfügen.
:xInsertRecord		ldx	#$08
			lda	curRecord		;Record verfügbar ?
			bmi	NewRecordExit		;Nein, Fehler ausgeben...

			jsr	VLIR_GetCurBAM		;BAM im Speicher aktualisieren.
			txa				;Diskettenfehler ?
			bne	NewRecordExit		;Ja, Abbruch...

			lda	curRecord		;Zeiger auf Record in
			sta	r0L 			;VLIR-Header.
			jmp	VLIR_InsRecEntry	;Record-Eintrag einfügen.

;*** Datensatz an VLIR-Datei anhängen.
:xAppendRecord		jsr	VLIR_GetCurBAM		;BAM im Speicher aktualisieren.
			txa				;Diskettenfehler ?
			bne	NewRecordExit		;Ja, Abbruch...

			ldx	curRecord		;Zeiger hinter aktuellen
			inx				;Record positionieren.
			stx	r0L
			jsr	VLIR_InsRecEntry	;Record-Eintrag einfügen.
			txa				;Diskettenfehler ?
			bne	NewRecordExit		;Ja, Abbruch...

			lda	r0L			;Zeiger auf aktuellen Record
			sta	curRecord		;korrigieren.
:NewRecordExit		rts

;*** Datensatz einlesen.
:xReadRecord		ldx	#$08
			lda	curRecord		;Record verfügbar ?
			bmi	:51			;Nein, Abbruch...

			jsr	VLIR_Get1stSek		;Zeiger auf ersten Sektor.
			lda	r1L
			tax				;Record angelegt ?
			beq	:51			;Nein, Ende...

			jsr	ReadFile		;Record in Speicher einlesen.
			lda	#$ff			;$FF = Daten gelesen.
::51			rts

;*** Datensatz schreiben.
:xWriteRecord		ldx	#$08
			lda	curRecord		;Record verfügbar ?
			bmi	NoFunc4			;Nein, Abbruch...
			lda	r2H			;Anzahl zu schreibender
			pha				;Bytes zwischenspeichern.
			lda	r2L
			pha
			jsr	VLIR_GetCurBAM		;BAM im Speicher aktualisieren.
			pla				;Anzahl zu schreibender
			sta	r2L			;Bytes zurückschreiben.
			pla
			sta	r2H
			txa				;Diskettenfehler ?
			bne	NoFunc4			;Ja, Abbruch...
			jsr	VLIR_Get1stSek		;Zeiger auf ersten Sektor.
			lda	r1L			;Sektor bereits angelegt ?
			bne	:51			;Ja, weiter...
			ldx	#$00
			lda	r2L
			ora	r2H			;Sind Daten im Record ?
			beq	NoFunc4			;Nein, Ende...
			bne	:53			;Ja, Daten schreiben.

;*** Bestehenden Record löschen.
;    (Record wird später ersetzt)
::51			lda	r2H			;Anzahl zu schreibender
			pha				;Bytes zwischenspeichern.
			lda	r2L
			pha
			lda	r7H			;Startadresse Speicherbereich
			pha				;zwischenspeichern.
			lda	r7L
			pha
			jsr	FreeSeqChain		;Sektorkette freigeben.
			jsr	SubFileSize		;Dateigröße korrigieren.
			pla				;Startadresse Speicherbereich
			sta	r7L			;zurückschreiben.
			pla
			sta	r7H
			pla				;Anzahl zu schreibender
			sta	r2L			;Bytes zurückschreiben.
			pla
			sta	r2H
			txa				;Diskettenfehler ?
			bne	NoFunc4			;Ja, Abbruch...

::52			lda	r2L
			ora	r2H			;Sind Daten im Record ?
			beq	VLIR_ClrHdrEntry	;Nein, Record-Eintrag löschen.
::53			jmp	VLIR_SaveRecData	;Speicherbereich schreiben.
:NoFunc4		rts

;*** Leeren Record-Eintrag in
;    VLIR-Header erzeugen.
:VLIR_ClrHdrEntry	ldy	#$ff
			sty	r1H
			iny
			sty	r1L
			jmp	VLIR_Set1stSek

;*** VLIR-Header einlesen.
:VLIR_GetHeader		jsr	VLIR_SetHdrData		;Zeiger auf VLIR-Header setzen.
			txa				;Fehler ?
			bne	NoFunc4			;Ja, Abbruch...
			jmp	GetBlock		;Sektor lesen.

;*** VLIR-Header speichern.
:VLIR_PutHeader		jsr	VLIR_SetHdrData		;Zeiger auf VLIR-Header setzen.
			txa				;Fehler ?
			bne	NoFunc4			;Ja, Abbruch...
			jmp	PutBlock		;Sektor schreiben.

;*** Zeiger auf VLIR-Header setzen.
:VLIR_SetHdrData	ldx	#$07
			lda	VLIR_HeaderTr		;VLIR-Datei geöffnet ?
			beq	:51			;Nein, Fehler...
			sta	r1L			;Zeiger auf Sektor VLIR-Header.
			lda	VLIR_HeaderSe
			sta	r1H
			jsr	Vec_fileHeader		;Zeiger auf Header-Speicher.
			ldx	#$00
::51			rts

;*** Record-Eintrag aus VLIR-Header
;    löschen. Anzahl Records -1.
:VLIR_DelRecEntry	ldx	#$08
			lda	r0L			;Record verfügbar ?
			bmi	:53			;Nein, Fehler ausgeben.
			asl				;Zeiger auf Record berechnen.
			tay
			lda	#$7e			;Anzahl Records berechnen.
			sec
			sbc	r0L
			asl
			tax
			beq	:52
::51			lda	fileHeader +4,y		;Ersten Record in Tabelle
			sta	fileHeader +2,y		;löschen, folgende Records
			iny				;verschieben.
			dex
			bne	:51
::52			stx	fileHeader+$fe		;Ende VLIR-Datei markieren.
			stx	fileHeader+$ff		;(über Tr/Se = $00/$00!)
			dec	usedRecords		;Anzahl Records -1.
::53			rts

;*** Record-Eintrag in VLIR-Header
;    einfügen. Anzahl Records +1.
:VLIR_InsRecEntry	ldx	#$09

			lda	usedRecords		;Bereits alle Records
			cmp	#$7f			;in VLIR-Datei belegt ?
			bcs	:53			;Ja, Abbruch...

			ldx	#$08
			lda	r0L			;Record verfügbar ?
			bmi	:53			;Nein, Abbruch...

			ldy	#$fe			;Zeiger auf letzten Record.
			lda	#$7e			;Anzahl Records berechnen.
			sec
			sbc	r0L
			asl
			tax
			beq	:52

::51			lda	fileHeader -1,y		;Record-Zeiger ab gewünschtem
			sta	fileHeader +1,y		;Record um 2 Byte verschieben.
			dey
			dex
			bne	:51

::52			txa				;Leeren Record-Eintrag in
			sta	fileHeader +0,y		;VLIR-Header erzeugen.
			lda	#$ff			;(Durch Tr/Se = $00/$FF!)
			sta	fileHeader +1,y
			inc	usedRecords		;Anzahl Records +1.
::53			rts

;*** Tr/Se des aktuellen Record lesen.
:VLIR_Get1stSek		lda	curRecord
			asl
			tay
			lda	fileHeader +2,y
			sta	r1L
			lda	fileHeader +3,y
			sta	r1H
			rts

;*** Tr/Se in VLIR-Header eintragen.
:VLIR_Set1stSek		lda	curRecord
			asl
			tay
			lda	r1L
			sta	fileHeader +2,y
			lda	r1H
			sta	fileHeader +3,y
			rts

;*** Speicherbereich in BAM belegen
;    und auf Disk speichern.
:VLIR_SaveRecData	jsr	Vec_fileTrScTab
			lda	r7H			;Startadresse Speicherbereich
			pha				;zwischenspeichern.
			lda	r7L
			pha
			jsr	BlkAlloc		;Sektoren belegen.
			pla				;Startadresse Speicherbereich
			sta	r7L			;zurückschreiben.
			pla
			sta	r7H
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...
			lda	r2L			;Anzahl Sektoren merken.
			pha
			jsr	Vec_fileTrScTab
			jsr	WriteFile		;Speicher auf Disk schreiben.
			pla				;Anzahl Sektoren wieder
			sta	r2L			;zurückschreiben.
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...
			lda	fileTrScTab+1		;Zeiger auf ersten Sektor
			sta	r1H			;in VLIR-Header eintragen.
			lda	fileTrScTab+0
			sta	r1L
			jsr	VLIR_Set1stSek
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...
			lda	r2L			;Dateigröße korrigieren.
			clc
			adc	fileSize+0
			sta	fileSize+0
			bcc	:51
			inc	fileSize+1
::51			rts

;*** BAM im Speicher aktualisieren.
:VLIR_GetCurBAM		ldx	#$00
			lda	fileWritten		;Record bereits aktualisiert ?
			bne	:1			;Nein, weiter...
			jsr	GetDirHead		;Disketten-BAM einlesen.
			txa				;Fehler ?
			bne	:1			;Ja, Abbruch...
			lda	#$ff			;Record als "aktualisiert"
			sta	fileWritten		;markieren.
::1			rts
