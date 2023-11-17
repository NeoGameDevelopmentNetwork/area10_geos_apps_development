; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

; Code von geoConvert.
; Angepasst für GeoDesk64:
;  - Fehlerbehandlung.
;  - Rücksprung Hauptprogramm.
; Stand: 27.07.2019
;
;Aufbau CVT Datennsatz:
;Sektor   1 Byte   0/1    Zeiger auf nächsten Sektor.
;                         Hier wird zu Beginn die Adresse des GEOS-Infoblocks
;                         aus Byte 19/20  des Verzeichniseintrages eingeset.
;           Byte   2-31   Verzeichniseintrag der Quelldatei.
;                 32-34   Dateityp-Kennunng      : $82 = "PRG", sonst "SEQ"
;                 35-60   CVT-Format-Kennunng CVT: " formatted GEOS file V1.0",NULL
;                 61-255  $00-Bytes.
;Sektor   2 Byte   0/1    Zeiger auf nächsten Sektor = Anfang GEOS-Datei oder VLIR-Header.
;           Byte   2-255  Inhalt des Infoblocks der GEOS-Datei.
;Sektor   3 Byte   0/1    Zeiger auf nächsten Sektor = Nächster Datenblock oder VLIR-Datensatz.
;                  2-255  SEQ -Datei: GEOS-Dateidaten.
;                         VLIR-Datei: VLIR-Header. Die Daten werden hier allerdings überschrieben mit der
;                                     Anzahl der Sektoren pro VLIR-Datensatz (1-255) und der Anzahl der Bytes
;                                     im letzten Datenblock des VLIR-Streams.
;Sektor 4ff.Byte   0/1    Zeiger auf nächsten Sektor oder
;                         $00/$xy, $xy gibt die Anzahl der Bytes im letzten Datenblock an (2-255).
;                  2-255  Datenbytes.
;
;Aufbau G98 Datennsatz:
;Sektor   1 Byte   0/1    Zeiger auf nächsten Sektor.
;                         Hier wird zu Beginn die Adresse des GEOS-Infoblocks
;                         aus Byte 19/20  des Verzeichniseintrages eingeset.
;           Byte   2-31   Verzeichniseintrag der Quelldatei.
;                 32-34   Dateityp-Kennunng      : $82 = "PRG", sonst "SEQ"
;                 35-60   Format-Kennunng CVT: "SEQ GeoConvert98-format V2.0",NULL
;                 61-255  $00-Bytes.
;Sektor   2 Byte   0/1    Zeiger auf nächsten Sektor = VLIR-Infoblock#1.
;                  2-255  Inhalt des Infoblocks der GEOS-Datei.
;Sektor   3 Byte   0/1    Zeiger auf nächsten Sektor = VLIR-Infoblock#2.
;                  2-255  VLIR-Datei: VLIR-Header. Die Daten werden hier allerdings überschrieben mit der
;                                     Anzahl der Sektoren pro VLIR-Datensatz (1-255) und der Anzahl der Bytes
;                                     im letzten Datenblock des VLIR-Streams.
;Sektor   4 Byte   0/1    Zeiger auf nächsten Sektor = Anfang VLIR-Header.
;                  2-255  VLIR-Datei: Wenn die Datensatzlänger bei VLIR-Dateien die Anzahl von 255 Sektoren
;                                     überschreibt wird das G98-Format erstellt. In diesem Fall wird ein
;                                     zweiter VLIR-Infoblock erstellt. Parallel zu den max. 127 VLIR-Datensätzen
;                                     erhält jeweils das erste von zwei Bytes das HIGH-Byte der Sektoranzahl.
;                                     Damit können Dateien mit 127 VLIR-Datensätzen zu je 1-65535 Sektren a 254Bytes
;                                     erstellt werden. Das maximum liegt aber bei 255 Spuren an 256 Sektoren a 254Bytes.
;                                     Damit unterstützt geoConvert >v98f die max. Partitionsgröße von ca.16Mb.
;Sektor 5ff.Byte   0/1    Zeiger auf nächsten Sektor oder
;                         $00/$xy, $xy zeigt auf das letzte Byte im letzte Datenblock an (2-255).
;                  2-255  Datenbytes.

;*** Ausgewählte Datei konvertieren.
:DoConvert1File		LoadW	r6,curFileName
			jsr	FindFile
			txa
			bne	:102

;--- Zeiger auf Verzeichnis-Eintrag kopieren.
			lda	r1L
			sta	FileDirSek +0
			lda	r1H
			sta	FileDirSek +1
			lda	r5L
			sta	FileDirPos +0
			lda	r5H
			sta	FileDirPos +1

			lda	dirEntryBuf+19
			beq	:101
			jmp	GEOS_CBM		; => GEOS nach CBM wandeln.
::101			jmp	CBM_GEOS		; => CBM nach GEOS wandeln.
::102			rts				; => Diskettenfehler.

;*** Spur/Sektor auf VLIR-Header setzen,
;    r4 auf Datenspeicher für GetBlock/PutBlock setzen.
:SetVecHdrVLIR		lda	FileEntryBuf2 +1
			sta	r1L
			lda	FileEntryBuf2 +2
			sta	r1H
			LoadW	r4,CVT_VlirDataBuf
			rts

;*** Datei von GEOS nach SEQ wandeln.
:GEOS_CBM		jsr	CVT_InitFile		;Konvertierung initialisieren.
			txa				;Diskettenfehler ?
			bne	:102			; => Ja, Ende...

			ldx	#$ff
			lda	dirEntryBuf   +19
			ora	dirEntryBuf   +20	;GEOS-Datei ?
			beq	:102			; => Nein, weiter...

			jsr	CVT_MakeHeader
			txa				;Diskettenfehler ?
			bne	:102			; => Ja, Ende...

			jsr	CVT_FileConvert		;Daten konvertieren.
			txa				;Diskettenfehler ?
			bne	:102			; => Ja, Ende...
			tya				;SEQ-Datei ?
			beq	:101			;Ja, weiter...

;--- Der erste Datensatz der in Byte 1/2 des Verzeichniseintrages gespeichert war ist bei VLIR-Dateien der VLIR-Header.
;    Dieser wurde bereits in den CVT-Datensatz geschrieben. Als nächstes die einzelnen VLIR-Datensätze in den
;    CVT-Datensatz schreiben.
			jsr	CVT_VlirConvert		;VLIR-Datei konvertieren.
			txa				;Diskettenfehler ?
			bne	:102			; => Ja, Ende...

			jsr	CVT_CheckFormat		;Auf GeoConvert-Format testen.
			txa				;Diskettenfehler ?
			bne	:102			; => Ja, Ende...

::101			jsr	CVT_CreateEntry		;Dateiname erstellen.
			jmp	CVT_SetNewEntry		;Dateieintrag schreiben.
::102			rts

;*** Konvertierung initialisieren.
:CVT_InitFile		ClrB	FormatType		;CVT-Dateiformat "CONVERT Vx".

			ldy	#$1d			;Verzeichnis-Eintrag kopieren.
::101			lda	dirEntryBuf      ,y
			sta	FileEntryBuf1    ,y
			sta	FileEntryBuf2    ,y
			dey
			bpl	:101

::102			rts

;*** Fortsetzung: GEOS nach SEQ.
:CVT_MakeHeader		lda	FileEntryBuf2 +19	;Zeiger auf Infoblock einlesen.
			sta	diskBlkBuf    +0
			lda	FileEntryBuf2 +20
			sta	diskBlkBuf    +1

			ldy	#2			;Original-Verzeichniseintrag
			ldx	#0			;in Datensektor kopieren.
::51			lda	FileEntryBuf2,x
			sta	diskBlkBuf,y
			iny
			inx
			cpx	#30
			bne	:51

			ldx	#0
::52			lda	CVT_FileType,x		;Formatkennung übertragen.
			sta	diskBlkBuf,y
			iny
			inx
			cpx	#29
			bne	:52

			lda	Option_CBMFileType	;Dateityp überprüfen ?
			cmp	#$80 ! PRG 		;SEQ-Datei ?
			bne	:53 			;Ja, weiter...

			lda	#"P" 			;Formatkennung "PRG".
			sta	diskBlkBuf+32
			lda	#"R"
			sta	diskBlkBuf+33
			lda	#"G"
			sta	diskBlkBuf+34

;*** Rest des Sektors löschen.
::53			lda	#$00
::54			sta	diskBlkBuf,y
			iny
			bne	:54

			jsr	CVT_AllocSektor		;Freien Sektor reservieren.
			txa				;Diskettenfehler ?
			bne	:60			; => Ja, Ende...

			lda	CurSektor      + 0	;Zeiger auf reservierten Sektor in
			sta	FileEntryBuf1  + 1	;Verzeichniseintrag für CVT/G98-Datei eintragen.
			sta	r1L
			lda	CurSektor      + 1
			sta	FileEntryBuf1  + 2
			sta	r1H
			LoadW	r4,diskBlkBuf 		;CVT-Datensektor auf
			jmp	PutBlock 		;Diskette schreiben.
::60			rts

;*** Daten konvertieren.
;    Zuerst Info-Block übernehmen, dann entweder GEOS-Datei oder VLIR-Header
;    in CVT-Datensatz übernehmen.
:CVT_FileConvert	lda	FileEntryBuf2  +19	;Spur/Sektor Infoblock der GEOS-Datei einlesen.
			sta	r1L
			lda	FileEntryBuf2  +20
			sta	r1H
			LoadW	r4,diskBlkBuf 		;Infoblock einlesen.
			jsr	GetBlock
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Ende...

			lda	FileEntryBuf2  + 1	;Zeiger auf Daten der GEOS-Datei bzw.
			sta	diskBlkBuf     + 0	;VLIR-Sektor als Verkettung auf nächsten Sektor
			lda	FileEntryBuf2  + 2	;in aktuellen Datenblock = Infoblock schreiben.
			sta	diskBlkBuf     + 1
			jsr	PutBlock 		;Nächsten Sektor der CVT-Datei=Infoblock schreiben.
			txa				;OK ?
			bne	:51			;Nein, Ende...

			ldy	FileEntryBuf2  +21	;Dateistruktur: 0=SEQ, 1=VLIR.
::51			rts

;*** VLIR-Datei nach SEQ wandeln.
:CVT_VlirConvert	jsr	EnterTurbo		;TurboDOS aktivieren und
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	SetVecHdrVLIR		;Zeiger auf VLIR-Sektor.
			jsr	ReadBlock		;VLIR-Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch.

;			lda	#$00			;Datensektor für Highbytes
			tay				;der Sektorzähler löschen.
::51			sta	G98_VlirDataBuf,y
			iny
			bne	:51

;			lda	#$00			;Flag löschen:
			sta	Flag_Set1stSek		;Erster Sektor der Datei.

			lda	#$02			;Zeiger auf ersten VLIR-Eintrag.
			sta	VlirHdrEntry

			jsr	CVT_AddSekVLIR		;Sektoren der VLIR-Datensätze an SEQ-Datei anhängen.

;*** Ergebis-Status speichern und Disk-I/O beenden.
::52			txa
			pha
			jsr	DoneWithIO
			pla
			tax
			rts

;*** VLIR-Daten an SEQ-Datei anfügen.
:CVT_AddSekVLIR		LoadW	r4,diskBlkBuf

			lda	VlirHdrEntry		;Zeiger auf VLIR-
							;Eintrag einlesen.
::51			tay
			lda	CVT_VlirDataBuf+ 0,y	;VLIR-Datensatz belegt ?
			beq	:56			; => Nein, übergehen.
			sta	diskBlkBuf     + 0	;Erster Durchlauf:
			lda	CVT_VlirDataBuf+ 1,y	;Infoblock steht ab :diskBlkBuf
			sta	diskBlkBuf     + 1	;im Speicher. Hier wird dann
							;Track/Sektor des ersten Daten-
							;satzes als Linkzeiger gesetzt.

			lda	Flag_Set1stSek 		;Erster VLIR-Datensatz ?
			bne	:52			; => Nein, weiter...
			lda	diskBlkBuf     + 0	;Verbindung Infoblock mit
			sta	CVT_VlirDataBuf+ 0	;erstem VLIR-Datensatz (s.o.)
			lda	diskBlkBuf     + 1
			sta	CVT_VlirDataBuf+ 1
			jmp	:53

;--- Ersten Sektor aus Datensatz schreiben.
::52			jsr	WriteBlock		;VLIR-Datensektor speichern.
			txa				;Diskettenfehler ?
			bne	:58			; => Ja, Abbruch.

;--- Neuen Datensatz lesen.
::53			lda	#$00
			sta	VlirChainLength   + 0	;Länge des Datensatzes löschen.
			sta	VlirChainLength   + 1

;--- Datensatz bis zum Ende einlesen.
::54			lda	diskBlkBuf     + 0
			sta	r1L
			lda	diskBlkBuf     + 1
			sta	r1H
			jsr	ReadBlock		;Nächsten VLIR-Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:58			; => Ja, Abbruch.

			inc	VlirChainLength   + 0 	;Anzahl Sektoren im
			bne	:55			;aktuellen Datensatz +1.
			inc	VlirChainLength   + 1

::55			lda	diskBlkBuf     + 0	;Letzter Sektor ?
			bne	:54 			;Nein, nächsten Sektor lesen.

;--- Daten für aktuellen VLIR-Datensatz speichern.
			ldy	VlirHdrEntry
			lda	VlirChainLength   + 0	;Anzahl Sektoren in aktuellem VLIR-Header als LOW-Byte speichern.
			sta	CVT_VlirDataBuf+ 0,y
			lda	VlirChainLength   + 1	;HIGH-Byte Anzahl Sektoren in G98-Zusatz-Datenblock speichern.
			sta	G98_VlirDataBuf+ 0,y

			lda	diskBlkBuf     + 1	;Anzahl Bytes in letztem Sektor VLIR-Datensatz merken.
			sta	CVT_VlirDataBuf+ 1,y

			lda	#$ff			;Flag "Erster Sektor" löschen.
			sta	Flag_Set1stSek

::56			inc	VlirHdrEntry 		;Zeiger auf nächsten VLIR-
			inc	VlirHdrEntry 		;Eintrag in Tabelle.
			lda	VlirHdrEntry 		;Ende erreicht ?
			bne	:51 			;Nein, weiter...

::57			jsr	SetVecHdrVLIR 		;Zeiger auf VLIR-Sektor. In diesem veränderten VLIR-Sektor
							;stehen jetzt in Byte 0 die Anzahl der Sektoren des
							;VLIR-Datensatzes (1-255), in Byte 1 die Anzahl der Bytes
							;im letzten Datenblock des VLIR-Datensatzes.
			jmp	WriteBlock 		;Sektor schreiben.
::58			rts

;*** GEOS nach GeoConvert98-Format wandeln.
:CVT_CheckFormat	ldx	#$02			;HIGH-bytes der Sektorzähler für VLIR-Datensatzlänge
::51			lda	G98_VlirDataBuf,x	;prüfen. Falls <>0, dann VLIR-Datei mit einer Datensatzlänge
			bne	:53			;von mehr als 255 Sektoren.
			inx
			bne	:51			;VLIR-Datensatz > 255 Sektoren gefunden?
::52			rts				;Nein, Ende...

::53			jsr	CVT_AllocSektor		;Freien Sektor belegen.
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch.

			jsr	SetVecHdrVLIR		;Zeiger auf VLIR-Header.
			jsr	GetBlock
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch.

			lda	CVT_VlirDataBuf+ 0	;Zeiger auf Startsektor VLIR-Daten in
			sta	G98_VlirDataBuf+ 0	;zweiten Info-Sektor kopieren.
			lda	CVT_VlirDataBuf+ 1
			sta	G98_VlirDataBuf+ 1

			lda	CurSektor      + 0	;Zeiger auf zweiten Info-Sektor
			sta	CVT_VlirDataBuf+ 0	;in VLIR-Header übertragen.
			lda	CurSektor      + 1
			sta	CVT_VlirDataBuf+ 1

			jsr	PutBlock		;VLIR-Header zurück auf Disk.
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch.

			lda	CurSektor      + 0
			sta	r1L
			lda	CurSektor      + 1
			sta	r1H
			LoadW	r4,G98_VlirDataBuf
			jsr	PutBlock		;Zweiten Info-Sektor schreiben.
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch.

;*** GeoConvert-Header schreiben.
			lda	FileEntryBuf1  + 1
			sta	r1L
			lda	FileEntryBuf1  + 2
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa				;Diskettenfehler ?
			bne	:55			; => Ja, Abbruch.

			ldy	#$18
::54			lda	G98_FormatCode,y	;Formatkennung übertragen.
			sta	diskBlkBuf+35,y		;CVT-Datei kann nicht mehr mit
			dey				;CONVERT Vx bearbeitet werden!
			bpl	:54

			jsr	PutBlock		;Formatkennung V2 schreiben.
			txa				;Diskettenfehler ?
			bne	:55			; => Ja, Abbruch.

			lda	#$ff
			sta	FormatType

			inc	FileEntryBuf1  +28	;Anzahl belegter Blöcke +1.
			bne	:55
			inc	FileEntryBuf1  +29
::55			rts

;*** Eintrag für CBM-Datei erzeugen.
:CVT_CreateEntry	lda	Option_CBMFileType	;CBM-Dateityp kopieren.
			sta	FileEntryBuf1 + 0

			LoadW	r0,curFileName		;MSDODS-Dateiname erzeugen.
			jsr	SetNameDOS

			ldx	#< CVT_FileExt		;Endung für CONVERT-Format.
			ldy	#> CVT_FileExt
			bit	FormatType
			bpl	:51
			ldx	#< G98_FileExt		;Endung für GeoConvert-Format.
			ldy	#> G98_FileExt

::51			stx	r0L			;Datei-Endung erstellen.
			sty	r0H

			LoadW	r1,FileNameDOS+ 8

			ldx	#r0L
			ldy	#r1L
			lda	#$04
			jsr	CopyFString

			lda	#$00			;Dateiname auf "8+3"-Zeichen
			sta	FileNameDOS   +12	;begrenzen.
			sta	FileNameDOS   +13
			sta	FileNameDOS   +14
			sta	FileNameDOS   +15
			sta	FileNameDOS   +16
			sta	FileNameDOS   +17

			jsr	CheckCurFileNm		;Dateiname überprüfen.

			ldy	#$00			;Dateiname in Speicher für
::52			lda	FileNameDOS      ,y	;Dateieintrag kopieren.
			beq	:53
			sta	FileEntryBuf1 + 3,y
			iny
			cpy	#16
			bcc	:52
			bcs	:54

::53			lda	#$a0			;Dateiname auf 16 Zeichen mit
			sta	FileEntryBuf1 + 3,y	;$A0-Bytes auffüllen.
			iny
			cpy	#16
			bcc	:53

::54			lda	#$00 			;GEOS-Informationen aus
			sta	FileEntryBuf1 +19 	;Dateieintrag löschen.
			sta	FileEntryBuf1 +20
			sta	FileEntryBuf1 +21
			sta	FileEntryBuf1 +22

			inc	FileEntryBuf1 +28	;Anzahl belegter Blöcke +1.
			bne	:56
			inc	FileEntryBuf1 +29
::56			rts

;*** Neuen verzeichnis-Eintrag schreiben.
:CVT_SetNewEntry	lda	FileDirSek    + 0	;Verzeichnissektor für
			sta	r1L 			;Dateieintrag lesen.
			lda	FileDirSek    + 1
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Ende...

			lda	FileDirPos    + 0	;Zeiger auf Dateieintrag.
			sta	r5L
			lda	FileDirPos    + 1
			sta	r5H

			ldy	#$1d 			;Neuen Eintrag in Verzeichnis-
::51			lda	FileEntryBuf1 + 0,y	;Sektor kopieren.
			sta	(r5L)            ,y
			dey
			bpl	:51

			jmp	PutBlock 		;Verzeichnis aktualisieren.
::52			rts

;*** Freien Sektor reservieren.
:CVT_AllocSektor	jsr	GetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:101			; => Ja, Ende...

			lda	NxFreeSek +0
			sta	r3L
			lda	NxFreeSek +1
			sta	r3H
			jsr	SetNextFree		;Ersten freien Sektor suchen.
			txa				;Diskettenfehler ?
			bne	:101			; => Ja, Ende...

			lda	r3L			;Belegten Sektor merken.
			sta	CurSektor     +0
			sta	NxFreeSek     +0
			lda	r3H
			sta	CurSektor     +1
			sta	NxFreeSek     +1
			jmp	PutDirHead		;BAM aktualisieren.
::101			rts

;*** CVT/G98-Sektor freigeben.
:CVT_FreeSektor		pha
			txa
			pha
			jsr	GetDirHead		;BAM einlesen.
			pla
			sta	r6H
			pla
			sta	r6L
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch.

;			lda	version			;GEOS-Version testen.
;			cmp	#$12			;Version 1.x ?
;			beq	:51			; => Ja, Sonderbehandlung.
			jsr	FreeBlock		;Sektor freigeben.
			jmp	PutDirHead		;BAM aktualsieren.

;::51			jsr	sysFreeBlock		;Sektor freigeben.
;			jmp	PutDirHead		;BAM aktualsieren.

::52			rts

;*** CBM-Datei nach GEOS konvertieren.
:CBM_GEOS		jsr	CVT_InitFile
			txa				;Diskettenfehler ?
			bne	:102			; => Ja, Ende...

			ldx	#$ff
			lda	dirEntryBuf   +19
			ora	dirEntryBuf   +20	;GEOS-Datei ?
			bne	:102			; => Ja, weiter...

			jsr	CVT_GetFormat
			cpx	#$ff			;Keine CVT/G98-Datei ?
			beq	:102			; => Ja, Ende...
			txa				;Diskettenfehler ?
			bne	:102			; => Ja, Ende...

			jsr	CVT_SeqConvert		;Daten konvertieren.
			txa				;Diskettenfehler ?
			bne	:102			; => Ja, Ende...
			tya
			beq	:101

			jsr	CVT_SeqVlirConv

::101			jsr	CVT_SetNewEntry		;dateieintrag schreiben.
::102			rts

;*** CVT/G98-Format bestimmen.
:CVT_GetFormat		lda	FileEntryBuf1  + 1	;Zeiger auf CVT/G98-Header
			ldx	FileEntryBuf1  + 2	;einlesen und speichern.
			sta	CurSektor      + 0
			stx	CurSektor      + 1
			sta	r1L
			stx	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;CVT/G98-Header einlesen.
			txa				;Diskettenfehler ?
			bne	:58			; => Ja, Abbruch.

			ldy	#$19
::51			lda	diskBlkBuf     +35,y
			cmp	CVT_FormatCode       ,y	;Formatkennung prüfen.
			bne	:52			;Fehler -> Keine CVT-Datei.
			dey
			bpl	:51
			bmi	:56

::52			ldy	#$19
::53			lda	diskBlkBuf     +35,y
			cmp	G98_FormatCode       ,y	;Formatkennung prüfen.
			bne	:54 			;Fehler -> Keine G98-Datei.
			dey
			bpl	:53

			lda	G98_VlirDataBuf   + 0
			sta	CVT_VlirDataBuf   + 0
			lda	G98_VlirDataBuf   + 1
			sta	CVT_VlirDataBuf   + 1

			dec	FormatType		;Flag setzen: "G98-Datei".
			jmp	:56

::54			ldx	#$ff
::55			rts

;--- Original-Dateieintrag kopieren.
::56			ldx	#$1d
::57			lda	diskBlkBuf     + 2,x	;Original-Dateieintrag
			sta	FileEntryBuf1  + 0,x	;aus Datensektor kopieren.
			dex
			bpl	:57

			lda	diskBlkBuf     + 0	;Zeiger auf Infoblock in
			sta	FileEntryBuf1  +19	;Verzeichniseintrag kopieren.
			lda	diskBlkBuf     + 1
			sta	FileEntryBuf1  +20

			lda	CurSektor      + 0	;Zeiger auf G98-Header und
			ldx	CurSektor      + 1	;Sektor freigeben.
			jsr	CVT_FreeSektor
::58			rts

;*** VLIR-Konvertierung initialisieren.
:CVT_SeqConvert		lda	FileEntryBuf1  +19	;Zeiger auf Infoblock in
			sta	r1L			;Verzeichniseintrag kopieren.
			lda	FileEntryBuf1  +20
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Infoblock-Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch.

			lda	diskBlkBuf     + 0	;Zeiger auf VLIR-Header
			sta	FileEntryBuf1  + 1	;einlesen und in Dateieintrag
			lda	diskBlkBuf     + 1	;kopieren.
			sta	FileEntryBuf1  + 2

			lda	#$00 			;Sektorverkettung im
			sta	diskBlkBuf     + 0	;Infoblock löschen.
			lda	#$ff
			sta	diskBlkBuf     + 1
			jsr	PutBlock
			txa	 			;Diskettenfehler ?
			bne	:53 			;Ja, Abbruch.

			ldy	FileEntryBuf1  +21	;VLIR-Datei ?
			beq	:53

			lda	FileEntryBuf1  + 1	;Zeiger auf VLIR-Header
			sta	r1L			;setzen. Dieser Sektor enthält
			lda	FileEntryBuf1  + 2	;die VLIR-Informationen.
			sta	r1H
			LoadW	r4,CVT_VlirDataBuf
			jsr	GetBlock		;VLIR-Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch.

			tay				;Datensektor für Highbytes
::51			sta	G98_VlirDataBuf,y	;der Sektorzähler löschen.
			iny
			bne	:51

			bit	FormatType		;G98-Datei ?
			bpl	:52			; => Nein, weiter...

;--- G98-Header einlesen.
			lda	CVT_VlirDataBuf   + 0
			sta	r1L
			lda	CVT_VlirDataBuf   + 1
			sta	r1H
			LoadW	r4,G98_VlirDataBuf
			jsr	GetBlock		;Zweiten Info-Sektor schreiben.
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch.

			lda	CVT_VlirDataBuf   + 0	;Zeiger auf G98-Header und
			ldx	CVT_VlirDataBuf   + 1	;Sektor freigeben.
			jsr	CVT_FreeSektor
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch.

			lda	G98_VlirDataBuf   + 0
			sta	CVT_VlirDataBuf   + 0
			lda	G98_VlirDataBuf   + 1
			sta	CVT_VlirDataBuf   + 1

;--- CVT/G98-Header in BAM freigeben.
::52			ldy	FileEntryBuf1  +21	;VLIR-Datei ?
::53			rts

;*** Verzeichniseintrag aktualisieren.
:CVT_SeqVlirConv	jsr	EnterTurbo		;TurboDOS aktivieren und
			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	CVT_VlirDataBuf+ 0	;Zeiger auf ersten Sektor der
			sta	r1L			;VLIR-Daten setzen.
			lda	CVT_VlirDataBuf+ 1
			sta	r1H

			lda	#$02			;Zeiger auf VLIR-Eintrag.
			sta	VlirHdrEntry

::51			tay
			lda	CVT_VlirDataBuf+ 0,y	;VLIR-Datensatz belegt ?
			beq	:55			; => Nein, weiter...
			sta	VlirChainLength+ 0
			lda	G98_VlirDataBuf+ 0,y	;Anzahl Sektoren in aktuellem
			sta	VlirChainLength+ 1	;VLIR-Datensatz einlesen.

			lda	CVT_VlirDataBuf+ 1,y	;Anzahl Bytes in letztem
			sta	ByteInLastSek		;VLIR-Datensatz-Sektor merken.

			lda	r1L			;Start-Sektor des aktuellen
			sta	CVT_VlirDataBuf+ 0,y	;VLIR--Datensatzes in VLIR-Header.
			lda	r1H
			sta	CVT_VlirDataBuf+ 1,y
			LoadW	r4,diskBlkBuf

;--- Aktuellen Datensatz lesen.
::52			jsr	ReadBlock		;Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:56			; => Ja, Abbruch...

			lda	VlirChainLength+0	;Anzahl Sektoren in aktuellem
			bne	:53			;Datensatz -1.
			dec	VlirChainLength+1
::53			dec	VlirChainLength+0	;Alle Sektoren gelesen ?
			lda	VlirChainLength+0
			ora	VlirChainLength+1
			beq	:54			; => Ja, Ende...

			lda	diskBlkBuf+0		;Zeiger auf nächsten Sektor.
			sta	r1L
			lda	diskBlkBuf+1
			sta	r1H
			jmp	:52			;Nächsten Sektor lesen.

;--- Aktuellen Datensatz abschließen.
::54			lda	diskBlkBuf+0		;Zeiger auf nächsten Sektor
			pha				;zwischenspeichern.
			lda	diskBlkBuf+1
			pha

			lda	#$00			;Letzten Sektor markieren und
			sta	diskBlkBuf+0		;Anzahl Bytes in letztem
			lda	ByteInLastSek		;Sektor festlegen.
			sta	diskBlkBuf+1
			jsr	WriteBlock		;Letzten VLIR-Sektor schreiben.

			pla				;Zeiger auf nächsten Sektor
			sta	r1H			;einlesen und speichern.
			pla
			sta	r1L
			txa				;Diskettenfehler ?
			bne	:56			; => Ja, Abbruch.

;--- Zeiger auf nächsten Datensatz.
::55			inc	VlirHdrEntry		;Zeiger auf nächsten
			inc	VlirHdrEntry		;Datensatz.

			lda	VlirHdrEntry		;Alle Datensätze erzeugt ?
			bne	:51			;Nein, weiter...

			lda	#$00			;Sektorverkettung für
			sta	CVT_VlirDataBuf+0	;VLIR-Header löschen.
			lda	#$ff
			sta	CVT_VlirDataBuf+1

			lda	FileEntryBuf1+1
			sta	r1L
			lda	FileEntryBuf1+2
			sta	r1H
			LoadW	r4,CVT_VlirDataBuf
			jsr	WriteBlock		;Sektor speichern.
::56			jmp	DoneWithIO

;*** Variablen.
:FormatType		b $00				;$00 = CONVERT
							;$FF = GeoConvert98

:Option_CBMFileType	b $82				;Dateityp für CVT $82=PRG, $81=SEQ.

:VlirHdrEntry		b $00
:VlirChainLength	w $0000

:Flag_Set1stSek		b $00
:ByteInLastSek		b $00

:FileDirSek		b $00,$00
:FileDirPos		w $0000

:NxFreeSek		b $00,$00
:CurSektor		b $00,$00

:CVT_FileType		b "SEQ"
:CVT_FormatCode		b " formatted GEOS file V1.0",NULL
:CVT_FileExt		b ".CVT"
:G98_FormatCode		b " GeoConvert98-format V2.0",NULL
:G98_FileExt		b ".G98"
