; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;geoConvert
;Disk->D64
if .p
			t "TopSym"
			t "TopMac"
			t "src.geoConve.ext"
endif

			n "mod.#3"
			o VLIR_BASE

;*** Sub-Routinen anspringen.
:START_DISK_D64		jsr	GotoFirstMenu		;Zurück zum Hauptmenü.

			lda	SourceDrive
			jsr	SetDevice		;Laufwerk aktivierem.

			ldx	FileConvMode		;Konvertierungsmodus einlesen.
			cpx	#ConvMode_DISK_D81	;Disk -> D81?
			bne	:102			;Nein, weiter...

;Auf 1581/D81 testen.
			ldy	SourceDrive		;Ist Quell-Laufwerk vom Typ 1581?
			lda	driveType-8,y
			and	#%00000111
			cmp	#DRV_1581
			beq	:101			;Ja, weiter...
			jmp	CreateD81_NoDrv		;Fehler: "Kein 1581-Laufwerk".

::101			lda	#DRV_1581		;Disk-Abbild-Modus festlegen.
			sta	DiskImageMode
			lda	#"8"			;Dateierweiterung  "D81" festlegen.
			sta	DiskFileExt+1
			sta	DlgGetFileName1+1
			lda	#"1"
			sta	DiskFileExt+2
			sta	DlgGetFileName1+2
			jmp	CreateDiskImage		;Disk-Abbild erzeugen.

;Auf 1541/1571/D64/D71 testen.
::102			lda	#DRV_1541		;Standard Disk-Abbild-Modus "D64" festlegen.
			sta	DiskImageMode
			lda	#"6"			;Dateierweiterung "D64" festlegen.
			sta	DiskFileExt+1
			sta	DlgGetFileName1+1
			lda	#"4"
			sta	DiskFileExt+2
			sta	DlgGetFileName1+2

			cpx	#ConvMode_DISK_D64	;Disk -> D64?
			bne	:103			;Nein, weiter...
			ldy	SourceDrive		;Ist Quell-Laufwerk vom Typ 1541?
			lda	driveType-8,y
			and	#%00000111
			cmp	#DRV_1541
			beq	:104			;Ja, weiter...
			jmp	CreateD41_NoDrv		;Fehler: "Kein 1541-Laufwerk".

::103			cpx	#ConvMode_DISK_D71	;Disk -> D71?
			bne	CreateImage_NoDrv	;Nein, unbekannter Abbild-Modus...

			ldy	SourceDrive		;Ist Quell-Laufwerk vom Typ 1541?
			lda	driveType-8,y
			and	#%00000111
			cmp	#DRV_1571
			bne	CreateD71_NoDrv		;Nein, Fehler...
			tya
			jsr	SetDevice		;Laufwerk aktivierem.
			jsr	NewOpenDisk		;Disskette öffnen.
			txa				;Diskettenfehler?
			beq	:105			;Nein, weiter...
			jmp	ExitDiskErr

::105			ldy	curDrive
			lda	curDirHead+3		;1541-Disk in 1571-Laufwerk?
			beq	:104			;Ja, weiter.
			lda	#DRV_1571		;Disk-Abbild-Modus "D71" festlegen.
			sta	DiskImageMode
			lda	#"7"			;Dateierweiterung "D71" festlegen.
			sta	DiskFileExt+1
			sta	DlgGetFileName1+1
			lda	#"1"
			sta	DiskFileExt+2
			sta	DlgGetFileName1+2
::104			jmp	CreateDiskImage		;Disk-Abbild erzeugen.

;*** Laufwerksfehler.
:CreateD81_NoDrv	LoadW	r5,No81DrvTxt		;Kein 1581-Laufwerk gefunden.
			jmp	ErrDiskError

:CreateD71_NoDrv	LoadW	r5,No71DrvTxt		;Kein 1571-Laufwerk gefunden.
			jmp	ErrDiskError

:CreateD41_NoDrv	LoadW	r5,No41DrvTxt		;Kein 1541-Laufwerk gefunden.
			jmp	ErrDiskError

:CreateImage_NoDrv	ldx	#$0d			;Kein passendes laufwerk gefunden.
			jmp	GetTxtDiskErr

;*** Diskette nach D64/D81 wandeln.
:CreateDiskImage	lda	#$00			;Ziel-Dateiname löschen.
			sta	DImgTargetFile
			LoadW	r5,DImgTargetFile
			LoadW	r0,DlgGetFileName
			jsr	DoDlgBox		;Ziel-Dateiname eingebem.

			lda	DImgTargetFile		;Name eingeben?
			beq	:103			;Nein, zurück zum Hauptmenü.
			lda	sysDBData
			cmp	#CANCEL			;Abruch gewählt?
			bne	:104			;Nein, weiter...
::103			jmp	OpenMain		;Zurück zum Hauptmenü.

::104			LoadW	r0,DImgTargetFile	;Dteiname nach DOS  wandeln.
			jsr	SetNameDOS
			lda	#"."			;Dateierweiterung überschreiben.
			sta	FileNameDOS   +8
			lda	DiskFileExt   +0
			sta	FileNameDOS   +9
			lda	DiskFileExt   +1
			sta	FileNameDOS   +10
			lda	DiskFileExt   +2
			sta	FileNameDOS   +11
			lda	#$00			;Zeichen 12-16+NULL-Byte löschen.
			sta	FileNameDOS   +12
			sta	FileNameDOS   +13
			sta	FileNameDOS   +14
			sta	FileNameDOS   +15
			sta	FileNameDOS   +16
			sta	FileNameDOS   +17

			jsr	CheckCurFileNm		;Existiert Datei bereits? Falls Ja, Name ändern.

			ldy	#0			;Ziel-Dateiname in Zwischenspeicher.
::101			lda	FileNameDOS,y
			sta	DImgTargetFile ,y
			iny
			cpy	#16
			bne	:101

			lda	TargetDrive		;Ziel-Laufwerk öffnen.
			jsr	SetDevice
			jsr	NewOpenDisk		;Diskette öffnen.

			jsr	TextInfo_DelOldFile	;Evtl. vorhandene Ziel-Datei löschen.

			LoadW	r0,DImgTargetFile
			jsr	DeleteFile

;*** Bildschirm-Informationen ausgeben.
:PrnScrnInfo		jsr	i_GraphicsString	;Anzeigebereich für Disk-Abbild-Dateiname löschen.
			b	NEWPATTERN,$00
			b	MOVEPENTO
			w	$0040
			b	$58
			b	RECTANGLETO
			w	$00ff
			b	$6f
			b	FRAME_RECTO
			w	$0040
			b	$58
			b	MOVEPENTO
			w	$0042
			b	$5a
			b	FRAME_RECTO
			w	$00fd
			b	$6d
			b	NULL

			LoadW	r0,Text_PrintFileName	;Disk-Abbild-Dateiname ausgeben.
			jsr	PutString

			ldy	#$00
::103			lda	DImgTargetFile,y
			beq	:107
			sty	:106 +1
			cmp	#$20
			bcc	:104
			cmp	#$7f
			bcc	:105
::104			lda	#"-"
::105			jsr	SmallPutChar
::106			ldy	#$ff
			iny
			cpy	#$10
			bne	:103

::107			jsr	TextInfo_CreateDImg	;Texthinweis "Daten werden konvertiert..."
			jsr	ClearJobInfo		;Fortschrittsanzeige löschen.

;*** Datei einlesen.
:InitD64Info		lda	#$01			;Zeiger auf Spur 1/Sektor 0.
			ldx	#$00
			sta	a3L
			stx	a3H

			stx	DImgSekData +$00
			sta	DImgSekData +$01

			stx	D64ImageEntry +$01
			stx	D64ImageEntry +$02
			sta	D64ImageEntry +$1c
			stx	D64ImageEntry +$1d

			sta	a4L
			sta	a4H

;*** Disketten-Daten einlesen.
:Read1541Data		ldx	a3L			;Fortschrittsanzeige.
			jsr	PrintJobInfo

			lda	SourceDrive		;Quell-Laufwerk öffnen..
			jsr	SetDevice
			jsr	EnterTurbo
			jsr	InitForIO

			LoadW	r4,DataSekBufStart	;Zeiger auf Anfang Zwischenspeicher für
							;eingelesene Sektoren.
			lda	#DataSekBufMax		;Zähler für Datenpuffer auf Anfang.
			sta	a5L
			sta	a5H

;*** Sektoren einlesen.
::101			MoveB	a3L,r1L			;Aktuellen Quell-Sektor einlesen.
			MoveB	a3H,r1H
			jsr	ReadDataBlock
			txa
			bne	:103
			dec	a5L			;Sektorzähler reduzieren.

			jsr	SetNextSek		;Zeiger auf nächsten Sektor.
			bne	:102			;-> Kein weiterer Sektor.

			inc	r4H			;Zeiger auf nächsten Zwischenspeicher.
			lda	a5L			;Zwischenspeicher voll?
			bne	:101			;Nein weiter...

::102			sta	a9L			;"Disk-Ende ereicht"-Flag speichern.
			jsr	DoneWithIO

			lda	a5L
			cmp	#DataSekBufMax		;Daten in Zwischenspeicher?
			bne	SaveDiskToD64		;Ja, Daten in Disk-Abbild-Datei speichern.
			jmp	EndOfDiskData		;Disk vollständig eingelesen, Ende.
::103			jmp	ExitDiskErr

;*** Datenblock einlesen.
;Bei 1581 auf ersten BAM-Sektor testen und
;Disk-Namen von GEOS/$90 nach BASIC/$04 tauschen.
:ReadDataBlock		jsr	ReadBlock
			txa
			bne	:10

			lda	curType
			and	#%0000 0111
			cmp	#$03
			bne	:10

			lda	r1L
			cmp	#40
			bne	:10
			lda	r1H
			bne	:10

			ldy	#$90			;Zeiger auf Angang Diskname.
			lda	(r4L),y			;Zeichen aus Original-Name lesen
			bne	SwapDskNamData		;Name vorhanden, tauschen...
::10			rts

:SwapDskNamData		ldy	#$04			;Zeiger auf Angang Diskname.
::51			lda	(r4L),y			;Zeichen aus Original-Name lesen
			sta	:SwapByteBuf		;und zwischenspeichern.

			tya				;Zeiger auf 1541/1571 kompatible
			clc				;Position des Disknamen setzen.
			adc	#$8c
			tay

			lda	(r4L),y			;Zeichen aus 1541/1571 kompatiblen
			pha				;Disknamen einlesen und merken.

			lda	:SwapByteBuf		;Zeichen aus Original-Name wieder
			sta	(r4L),y			;einlesen und an kompatible
							;Position speichern.
			tya				;Zeiger zurück auf originale
			sec				;Position des Disknamen setzen.
			sbc	#$8c
			tay

			pla				;Zeichen aus 1541/1571 kompatiblen
			sta	(r4L),y			;Disknamen wieder einlesen und
							;an originaler Stelle einfügen.
			iny				;Zeiger auf nächstes Zeichen.
			cpy	#$1d			;Alle Zeichen getauscht?
			bne	:51			; => Nein, weiter...

;			ldx	#$00			;XReg zurücksetzen/Kein Fehler.
			rts				;Ende.

::SwapByteBuf		b $00

;*** Daten in D64-Datei schreiben.
:SaveDiskToD64		lda	TargetDrive		;Ziel-Laufwerk öffnen.
			jsr	SetDevice
			jsr	GetDirHead		;BAM einlesen.
			txa
			bne	:101

			LoadW	a6 ,DataSekBufStart

			ldy	D64ImageEntry +$01	;Sektor bereits auf Ziel-Laufwerk angelegt?
			bne	:104			;Ja, weiter...

			MoveB	a4L,r3L			;Freien Sektor auf Disk reservieren.
			MoveB	a4H,r3H
			jsr	SetNextFree
			txa				;Sekktor reserviert?
			beq	:102			;Ja, weiter...
::101			jmp	ExitDiskErr		;Diskettenfehler ausgeben.

::102			lda	r3L			;Adresse des reservvierten
			ldx	r3H			;Sektors zwischenspeichern.
			sta	a4L
			stx	a4H
			sta	a7L
			stx	a7H
			sta	D64ImageEntry +$01	;Erster reservierter Sektor
			stx	D64ImageEntry +$02	;als Anfangssektor Disk-Abbild-DDatei festlegen.

::104			ldy	#$00			;Datenbytes aus Datenpuffer in reservierten
::105			lda	(a6L),y			;Sektor kopieren.
			jsr	AddByteToD64Sek
			iny
			bne	:105

			dec	a5H			;Sektorzähler in Datenpuffer reduzieren.
			bne	:107			;Ende erreicht? Nein, weiter...

::106			jsr	PutDirHead		;BAM auf Disk schreiben.
			txa
			bne	:101

			lda	a9L			;Ende der Quell-Diskette erreicht?
			bne	EndOfDiskData		;Ja, Ende...
			jmp	Read1541Data		;Nein, weitere Daten aus Quell-Diskette  einlesen.

::107			inc	a6H			;Zeiger auf nächsten Block in Datenpuffer.
			lda	a9L			;Ende der Quell-Diskette erreicht?
			beq	:104			;Nein, weiter...

			lda	a5H			;Anzahl eingelesener Sektoren in Datenpuffer
			cmp	a5L			;auf  Diskette ggeschrieben?
			beq	:108			;Ja, Ende...
			jmp	:104			;Weitere Daten  auf Disk schreiben.

::108			jsr	PutDirHead		;BAM auf Disk schreiben.
			txa
			bne	:101

;*** D64-Datei beenden.
:EndOfDiskData		lda	TargetDrive
			jsr	SetDevice
			jsr	GetDirHead
			txa
			beq	:102
::101			jmp	ExitDiskErr

::102			jsr	UpdateD64Sek		;Letzten Sektor schreiben.
			jsr	PutDirHead
			txa
			bne	:101

;*** Verzeichniseintrag erzeugen.
:MakeD64DirEntry	lda	#$82			;Typ 'PRG'
			sta	D64ImageEntry

			ldy	#$03
			ldx	#$00
::101			lda	DImgTargetFile ,x	;Dateiname in Eintrag schreiben.
			beq	:102
			sta	D64ImageEntry ,y
			iny
			inx
			cpx	#$10
			bne	:101
			beq	:103

::102			lda	#$a0			;Dateiname mit SHIFT-SPACE auffüllen.
			sta	D64ImageEntry ,y
			iny
			inx
			cpx	#$10
			bne	:102

::103			lda	#$00
			sta	D64ImageEntry ,y	;Dummy-Byte Spur Side-Sektor-Block (nur 'REL').
			iny
			sta	D64ImageEntry ,y	;Dummy-Byte Sektor Side-Sektor-Block (nur 'REL').
			iny
			sta	D64ImageEntry ,y	;Dummy-Byte Datensatzlänge (nur 'REL').
			iny
			sta	D64ImageEntry ,y	;Dummy-Byte.
			iny
			lda	year
			sta	D64ImageEntry ,y	;Dateidatum: Jahr.
			iny
			lda	month
			sta	D64ImageEntry ,y	;Dateidatum: Monat.
			iny
			lda	day
			sta	D64ImageEntry ,y	;Dateidatum: Tag.
			iny
			lda	hour
			sta	D64ImageEntry ,y	;Dateidatum: Stunde.
			iny
			lda	minutes
			sta	D64ImageEntry ,y	;Dateidatum: Minute.

			LoadB	r10L,$00		;Freien Verzeichniseintrag suchen.
			jsr	GetFreeDirBlk
			txa				;Fehler aufgetreten?
			bne	:105			;Ja, Abbruch...

			ldx	#$00			;Verzeichnis-Eintrag schreiben.
::104			lda	D64ImageEntry ,x
			sta	diskBlkBuf ,y
			iny
			inx
			cpx	#$1e
			bne	:104

			jsr	PutBlock		;Verzeichnis aktualisieren.
			txa				;Fehler aufgetreten?
			bne	:105			;Ja, Abbruch...

			jsr	ClrScreen		;Bildschirm löschen.
			jmp	OpenMain		;Zurück zum Hauptmenü,

::105			jmp	ExitDiskErr

;*** Byte in D64/D81-Datei übertragen.
:AddByteToD64Sek	sty	:102 +1			;Zeiger innerhalb Datenpuffer retten.

			ldx	DImgSekData +$01	;Zeiger auf nächstes Byte in Sektor Abbild-Datei setzen.
			inx				;Aktueller Sektor voll?
			bne	:101			;Nein, weiter...

			pha				;Datenbyte sichern.

			MoveB	a4L,r3L
			MoveB	a4H,r3H
			jsr	SetNextFree		;Neuen Sektor reservieren.
			txa	 			;Sektor reserviert?
			beq	:103			;Ja, weiter...
::104			jmp	ExitDiskErr

::103			lda	r3L			;Zeiger auf reservierten Sektor
			ldx	r3H			;zwischenspeichern.
			sta	a4L
			stx	a4H
			sta	DImgSekData +$00	;Zeiger auf reservierten Sektor als Link in
			stx	DImgSekData +$01	;aktuellen Sektor schreiben.

			MoveB	a7L,r1L
			MoveB	a7H,r1H
			LoadW	r4,DImgSekData
			jsr	PutBlock		;Aktuellen Sektor auf Disk schreiben.
			txa	 			;Diskettenfehler?
			bne	:104			;Ja, Abbruch...

			lda	DImgSekData +$00	;Addresse reservierter Sektor als
			ldx	DImgSekData +$01	;neuen aktuellenn Sektor festlegen.
			sta	a7L
			stx	a7H

			inc	D64ImageEntry +$1c	;Dateilänge anpassen.
			bne	:100
			inc	D64ImageEntry +$1d

::100			lda	#$00			;"Datei-Ende"-Kennung setzen.
			sta	DImgSekData +$00
			ldx	#$02			;Zeiger auf erstes Byte in neuen Sektor.
			pla

::101			stx	DImgSekData +$01	;Zeiger auf letztes Byte in Sektor.
			sta	DImgSekData,x		;Byte in Sektor schreiben.
::102			ldy	#$ff			;Zeiger innerhalb Datenpuffer wieder herstellen.
			rts

;*** Byte in D64-Datei übertragen.
:UpdateD64Sek		MoveB	a7L,r1L
			MoveB	a7H,r1H
			LoadW	r4,DImgSekData
			jsr	PutBlock		;Aktuellen Sektor Disk-Abbild-Datei schreiben.
			txa				;Diskettenfehler?
			beq	:101			;Nein, Ende...
			jmp	ExitDiskErr		;Ja, Abbruch...
::101			rts

;*** Variablen.
:D64ImageEntry		s 30
:DiskFileExt		b "D64"

:Text_PrintFileName	b PLAINTEXT,BOLDON
			b GOTOXY
			w $0048
			b $66
if Sprache = Deutsch
			b "Datei"
endif
if Sprache = Englisch
			b "File"
endif
			b GOTOX
			w $0078
			b ": "
			b NULL

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

if Sprache = Deutsch
::101			b PLAINTEXT,BOLDON
			b "Name der "
:DlgGetFileName1	b "D64-Datei:",NULL
endif
if Sprache = Englisch

::101			b PLAINTEXT,BOLDON
			b "Name of "
:DlgGetFileName1	b "D64-file:",NULL
endif

;*** Prüfen ob Datenspeicher bereits von Programmcode belegt.
			g DataSekBufStart
