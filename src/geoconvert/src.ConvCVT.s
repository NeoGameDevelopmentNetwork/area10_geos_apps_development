; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;geoConvert98
;Convert GEOS files into CVT
;G98 format supports VLIR records
;up to 65.280 blocks (about 16 Mb)

if .p
			t "TopSym"
			t "TopMac"
			t "src.geoConve.ext"
endif

			n "mod.#4"
			o VLIR_BASE
			p START_SEQ

;UPDATE: 07.03.21/M.Kanet
;
;Earlier versions of this description used the SECTOR based
;format of a CVT file. However, to analyze a CVT file the
;STREAM format is more suitable, because the byte addresses
;in this description then match the addresses within a file.

;
;Format CVT data stream:
;
;LABEL          OFFSET / SIZE           DESCRIPTION
;=============================================================
;1) The following 254 data bytes are part of the first sector
;of a CVT file on a diskette or disk image.
;The link-bytes 0/1 of the data block will be ignored here.
;
;DIRENTRY       $0000     30 Bytes      Directory entry of the source file.
; > DATAMODE    $0015     1 Byte        File mode: $00 = Sequential file, $01 = GEOS/VLIR.
; > INFOBLK     $0019     2 Byte        Track and sector of the GEOS infoblock.
;CBMTYPE        $001E     3 Bytes       File type: $82 = "PRG", for any other value "SEQ"
;CVTCODE        $0021     25 Bytes      CVT format string:
;                                       For the old CONVERT 2.x file format:
;                                       " formatted GEOS file V1.0"
;                                       For the new G98 file format:
;                                       " GeoConvert98-format V2.0"
;CVTEND         $003A     1 Byte        NULL
;               $003B     195 Bytes     Unsused, $00-bytes.
;
;2) The following 254 data bytes are part of the second sector
;of a CVT file on a diskette or disk image.
;The link-bytes 0/1 of the data block will be ignored here.
;The second sector is by default the GEOS infoblock.
;
;INFOBLOCK      $00FE     254 Bytes     GEOS infoblock of the source file.
;                                       At the moment a CVT file requires a GEOS infoblock.
;                                       The infoblock is used as first data block of the
;                                       newly created CVT file.
;                                       The link-bytes on a diskette or disk image will be
;                                       replaced with either the first block of the program
;                                       file, or in case of a VLIR data file, with the
;                                       address of VLIR header block.

;
;3) The following 254 data bytes are part of the third sector
;of a CVT file on a diskette or disk image.
;The link-bytes 0/1 of the data block will be ignored here.
;The third sector is optional and includes the VLIR header.
;
;VLIRHEAD       $01FC     254 Bytes     Optional VLIR header for the GEOS specific file format.
;                                       Only available if offset $0015 is set to $01=VLIR.
;                                       ":VLIRHEAD" contains 127 byte pairs #0/#1, which
;                                       contain information about the length of the single
;                                       VLIR record (byte#0, values from 0-255 sectors) and
;                                       the number of bytes in the last sector (values from
;                                       1-255 bytes).
;                                       During the conversion the content of the original VLIR
;                                       header is replaced by the number of blocks for each
;                                       VLIR record and the number of bytes in the last sector
;                                       of the VLIR record.
;                                       NOTE:
;                                       Due to the limitation to 255 sectors, a VLIR record has
;                                       a maximum size of 255*254 data bytes = 64.770 bytes.
;                                       For larger VLIR records the G98 format is required (for
;                                       more information see description below).
;
;4) The following 254 data bytes are part of the fourth sector
;of a CVT file on a diskette or disk image.
;The link-bytes 0/1 of the data block will be ignored here.
;The fourth sector is optional and includes additional VLIR
;record information for VLIR records >255 data blocks.
;
;VLIR2HEAD      $02FA     254 Bytes     Optional VLIR header for the GEOS specific file format.
;                                       Only available if offset $0015 is set to $01=VLIR and
;                                       the size of at least one VLIR record is larger then
;                                       255 blocks.
;                                       ":VLIR2HEAD" contains 127 byte pairs #0/#1, which
;                                       contain information about the high byte the single VLIR
;                                       record size (byte#0, values from 0-255 sectors).
;                                       The second byte #1 is currently unused (always $00).
;                                       The G98 format supports up to 127 VLIR records with
;                                       256*(256-1) blocks * 254 data bytes = 16.581.120 bytes.
;
;x) The following data bytes are part of the program file or
;the data records of a GEOS/VLIR file.
;
;FILEDATA       $01FC or  ...           Data bytes of the original source file if
;                                       the file type is sequential/non-VLIR.
;               $02FA or  ...           Data bytes of the first VLIR record if
;                                       the file type is GEOS/VLIR.
;               $03f8     ...           Data bytes of the first VLIR record if
;                                       the file type is GEOS/VLIR and format is G98.

;*** Sub-Routinen aufrufen.
:START_SEQ		lda	FileConvMode		;Alle Dateien konvertieren?
			cmp	#ConvMode_CVT_ALL_FILES
			beq	ConvertAllFiles		; => Ja, weiter...

;*** Eine Datei konvertieren.
:ConvertOneFile		jsr	TextInfo_ConvertData
			jsr	DoConvert1File		;Einzelne Datei konvertieren.
			cpx	#$ff			;Keine CONVERT-Datei?
			beq	:53			; => Ja, Abbruch...
			txa				;Diskettenfehler?
			bne	:52			; => Ja, Abruch...
::51			jmp	StartMenu		;Zurück zum Hauptmenü.

::52			jmp	ExitDiskErr		; => Diskettenfehler.

::53			LoadW	r5,Text_NoCVTFile	; => Keine konvertierte Datei.
			jmp	ErrDiskError

;*** Alle Dateien konvertieren.
:ConvertAllFiles	jsr	GotoFirstMenu		;DoMenu zurücksetzen.
			jsr	ClrScreen		;Bildschirm löschen.
			jsr	TextInfo_ConvertData	;Info-Text ausgeben.

			lda	#ConvMode_GEOS_CBM	;Modus GEOS->CBM setzen.
			sta	FileConvMode

			jsr	InitFileSlctMenu	;Dateien auswählen (max. 255 Dateien!)

			lda	MaxFilesOnDsk		;Dateien gefunden?
			beq	:53			; => Nein, Ende...

			lda	#$00			;Zeiger auf erste Datei.
			sta	a9H
::51			lda	a9H
			jsr	SetVecDirEntry		;Zeiger auf Dateieintrag setzen.

			ldy	#$02
			lda	(a0L),y			;Dateityp "Gelöscht" ?
			beq	:53			; => Ja, nächste Datei...

			LoadW	r1,CurFileName		;Dateiname kopieren.
			AddVW	5,a0
			ldx	#a0L
			lda	#$00
			jsr	CopyConvTextEntry

			jsr	DoConvert1File		;Einzelne Datei konvertieren.
			cpx	#$ff			;Keine CONVERT-Datei ?
			beq	:52			; => Ja, nächste Datei...
			txa				;Diskettenfehler ?
			bne	:54			; => Ja, Abbruch..

::52			inc	a9H			;Alle Dateien konvertiert?
			bne	:51			; => Nein, weiter...

::53			jmp	StartMenu		;Hauptmenü öffnen.
::54			jmp	ExitDiskErr		;Fehlermeldung anzeigen.

;*** Ausgewählte Datei konvertieren.
:DoConvert1File		jsr	FindSlctFile		;Datei suchen.
			txa
			bne	:exit

			lda	dirEntryBuf   +19	;Infoblock-Track verfügbar ?
			ora	dirEntryBuf   +20
			beq	:201			; => Nein, evtl. CVT-Datei...

;--- GEOS-Datei.
::101			jmp	GEOS_CBM		; => GEOS nach CVT wandeln.

;--- CBM-Datei.
::201			lda	dirEntryBuf+21		;Dateiformat einlesen.
			bne	:err			; => VLIR-Format, Fehler...

			jmp	CBM_GEOS		; => CVT nach GEOS wandeln.

::err			ldx	#14			;INCOMPATIBLE
			lda	FileConvMode		;Alle Dateien konvertieren?
			cmp	#ConvMode_CVT_ALL_FILES
			beq	:exit			; => Ja, keinen Fehler anzeigen...
			ldx	#$ff
::exit			rts

;*** Spur/Sektor auf VLIR-Header setzen,
;    r4 auf Datenspeicher für GetBlock/PutBlock setzen.
:SetVecHdrVLIR		lda	FileEntryBuf2 +1
			sta	r1L
			lda	FileEntryBuf2 +2
			sta	r1H
			LoadW	r4,CVT_VlirDataBuf
			rts

;*** Datei von GEOS nach CVT wandeln.
:GEOS_CBM		jsr	CVT_InitFile		;Konvertierung initialisieren.
			txa				;Diskettenfehler ?
			bne	:102			; => Ja, Ende...

			jsr	CVT_MakeHeader
			txa				;Diskettenfehler ?
			bne	:102			; => Ja, Ende...

			jsr	CVT_FileConvert		;Daten konvertieren.
			txa				;Diskettenfehler ?
			bne	:102			; => Ja, Ende...
			tya				;SEQ-Datei ?
			beq	:101			; => Ja, weiter...

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
:CVT_InitFile		jsr	GetFileDirPos		;Datei im Verzeichnis suchen.
			txa				;Diskettenfehler ?
			bne	:102			; => Ja, Ende...

			sta	FormatType		;CVT-Dateiformat "CONVERT V2.x".

			ldy	#30 -1			;Verzeichnis-Eintrag kopieren.
::101			lda	dirEntryBuf      ,y
			sta	FileEntryBuf1    ,y
			sta	FileEntryBuf2    ,y
			dey
			bpl	:101

::102			rts

;*** Fortsetzung: GEOS nach SEQ.
:CVT_MakeHeader		ldx	#14			;INCOMPATIBLE
			lda	FileEntryBuf2 +19	;Zeiger auf Infoblock einlesen.
			beq	:60			; => Keine GEOS-Datei, Abbruch..
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
			bne	:53 			; => Ja, weiter...

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
			jsr	PutBlock 		;Diskette schreiben.
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
			bne	:51			; => Ja, Ende...

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

			LoadW	r0,CurFileName		;MSDODS-Dateiname erzeugen.
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

			LoadB	r3L,1
			LoadB	r3H,0
			jsr	SetNextFree		;Ersten freien Sektor suchen.
			txa				;Diskettenfehler ?
			bne	:101			; => Ja, Ende...

			lda	r3L			;Belegten Sektor merken.
			sta	CurSektor     +0
			lda	r3H
			sta	CurSektor     +1
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

			lda	version			;GEOS-Version testen.
			cmp	#$12			;Version 1.x ?
			beq	:51			; => Ja, Sonderbehandlung.
			jsr	FreeBlock		;Sektor freigeben.
			jmp	PutDirHead		;BAM aktualsieren.

::51			jsr	sysFreeBlock		;Sektor freigeben.
			jmp	PutDirHead		;BAM aktualsieren.

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

			jsr	CVT_ConvertCBM		;Daten konvertieren.
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

;*** CVt-Datei nach GEOS konvertieren.
:CVT_ConvertCBM		lda	FileEntryBuf1  +19	;Infoblock definiert?
			bne	:50			; => Ja, weiter...

			ldx	#14			;INCOMPATIBLE.
			lda	FileConvMode		;Alle Dateien konvertieren?
			cmp	#ConvMode_CVT_ALL_FILES
			bne	:err			; => Ja, weiter...
			ldx	#$ff			;Fehler, keine konvertierte Datei.
::err			rts

::50			sta	r1L
			lda	FileEntryBuf1  +20
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Infoblock-Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch.

			lda	diskBlkBuf     + 0	;Zeiger auf VLIR-Header oder
			sta	FileEntryBuf1  + 1	;Programmdaten einlesen und in
			lda	diskBlkBuf     + 1	;Dateieintrag kopieren.
			sta	FileEntryBuf1  + 2

			lda	#$00 			;Sektorverkettung im
			sta	diskBlkBuf     + 0	;Infoblock löschen.
			lda	#$ff
			sta	diskBlkBuf     + 1
			jsr	PutBlock
			txa	 			;Diskettenfehler ?
			bne	:53 			; => Ja, Abbruch.

			ldy	FileEntryBuf1  +21	;VLIR-Datei ?
			beq	:53			; => Nein, weiter...

			lda	FileEntryBuf1  + 1	;Zeiger auf VLIR-Header
			sta	r1L			;setzen. Dieser Sektor enthält
			lda	FileEntryBuf1  + 2	;die VLIR-Informationen.
			sta	r1H
			LoadW	r4,CVT_VlirDataBuf
			jsr	GetBlock		;VLIR-Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch.

			tay				;Speicher für High-Bytes
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
			jsr	GetBlock		;Zweiten VLIR-Sektor einlesen.
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

;*** Variablen.
:FormatType		b $00				;$00 = CONVERT
							;$FF = GeoConvert98

:FileEntryBuf1		= StartSekTab +0
:FileEntryBuf2		= StartSekTab +30

:CVT_VlirDataBuf	= StartSekTab +30 +30
:G98_VlirDataBuf	= StartSekTab +30 +30 +256

:VlirHdrEntry		b $00
:VlirChainLength	w $0000

:Flag_Set1stSek		b $00
:ByteInLastSek		b $00

:FileDirSek		b $00,$00
:FileDirPos		w $0000

:CVT_FileType		b "SEQ"
:CVT_FormatCode		b " formatted GEOS file V1.0",NULL
:CVT_FileExt		b ".CVT"
:G98_FormatCode		b " GeoConvert98-format V2.0",NULL
:G98_FileExt		b ".G98"

if Sprache = Deutsch
:Text_NoCVTFile		b BOLDON,"Dateiformat nicht erkannt!"							,PLAINTEXT,NULL
endif
if Sprache = Englisch
:Text_NoCVTFile		b BOLDON,"Unknwon file type!",PLAINTEXT,NULL
endif

;*** Prüfen ob Datenspeicher bereits von Programmcode belegt.
			g DataSekBufStart
