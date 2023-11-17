; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;geoConvert
;D64->Disk
if .p
			t "TopSym"
			t "TopMac"
			t "src.geoConve.ext"
endif

			n "mod.#2"
			o VLIR_BASE
			p START_IMAGE_TO_DISK

;*** Sub-Routinen anspringen.
:START_IMAGE_TO_DISK	lda	#DRV_1541
			ldx	FileConvMode
			cpx	#ConvMode_D64_DISK	;D64 => Disk
			beq	:101
			lda	#DRV_1571
			cpx	#ConvMode_D71_DISK	;D71 => Disk
			beq	:101
			lda	#DRV_1581
			cpx	#ConvMode_D81_DISK	;D81 => Disk
			beq	:101
			ldx	#$0d			;Kein passendes Laufwerk gefunden.
			jmp	GetTxtDiskErr

::101			sta	DiskImageMode		;ImageDisk-Modus speichern.

			jsr	GotoFirstMenu		;Hauptmenü aktivieren.
			jsr	ClrScreen		;Bildschirm löschen.

::102			ldy	TargetDrive		;Überprüfenn ob das gewählte
			lda	driveType-8,y		;Ziel-Laufwerk zum  Abbild-Modus passt.
			and	#%00000111
			cmp	DiskImageMode		;Laufwerk = Modus?
			beq	:106			;Ja, weiter...
			lda	DiskImageMode
			cmp	#DRV_1541		;Abbild-Modus = D64?
			bne	:104			;Nein, Fehler...
			lda	driveType-8,y
			and	#%10000111
			cmp	#DRV_1571		;Reales 1571-Laufwerk?
			bne	:104			;Nein, weiter.

			tya				;Prüfen auf 1541-Diskette in 1571-Laufwerk für
			jsr	SetDevice		;D64-Modus.
			jsr	NewOpenDisk		;Diskkette  öffnen.
			txa
			bne	:105
			ldy	curDrive
			lda	curDirHead+3		;1541-Disk in 1571-Laufwerk?
			beq	:106			;Ja, weiter.

::104			LoadW	r5,No41DrvTxt		;Kein 1541-Laufwerk für D64 -> Disk.
			ldy	DiskImageMode
			cpy	#DRV_1541
			beq	:105
			LoadW	r5,No71DrvTxt		;Kein 1571-Laufwerk für D71 -> Disk.
			cpy	#DRV_1571
			beq	:105
			LoadW	r5,No81DrvTxt		;Kein 1581-Laufwerk für D81 -> Disk.
::105			jmp	ErrDiskError

::106			jsr	DiskImage_ReadSekAdr	;Startadressen der Sektoren innerhalb Abbild-Datei einlesen.

;*** Diskettennamen einlesen und Hinweistext ausgeben.
:DeCodeImageDisk	lda	SourceDrive		;Quell-Laufwerk öffnen.
			jsr	SetDevice
			jsr	EnterTurbo
			jsr	InitForIO

			ldx	#$12			;Zeiger auf Sektor 18/0.
			lda	#$00
			ldy	DiskImageMode		;D64/D71-Image?
			cpy	#DRV_1541
			beq	:101			;D64 -> weiter...
			cpy	#DRV_1571
			beq	:101			;D71 -> weiter...
			ldx	#$28			;Zeiger auf Sektor 40/0.
			lda	#$00
::101			jsr	PosToSektor		;Zeiger auf BAM-Sektor setzen.
			LoadW	r15,diskBlkBuf
			jsr	GetSektor		;BAM-Sektor einlesen.
			jsr	DoneWithIO		;Quell-Laufwerk schließen.

;*** Bildschirm-Informationen ausgeben.
			jsr	i_GraphicsString	;Anzeigebereich für
			b	NEWPATTERN,$00		;Diskettennamen löschen.
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

			jsr	i_PutString		;Hinweistext ausgeben.
			w	$0048
			b	$66
			b	PLAINTEXT,BOLDON
if Sprache = Deutsch
			b	"Diskette"
endif
if Sprache = Englisch
			b	"Disk"
endif
			b	GOTOX
			w	$0078
			b	": "
			b	NULL

			LoadW	r15,diskBlkBuf +$90	;1541/1571: Zeiger auf Diskettenname.
			lda	DiskImageMode		;Laufwerkstyp prüfen.
			cmp	#DRV_1541		;1541 ?
			beq	:105			;Ja, weiter...
			cmp	#DRV_1571		;1571 ?
			beq	:105			;Ja, weiter...
			lda	diskBlkBuf +$04		;1581: Hinweis: Einige Programme nutzen auch
			beq	:105			;      die Bytes ab $90 wie bei der 1541/1571.
							;      Beispiel: DualTop.
::104			LoadW	r15,diskBlkBuf +$04	;1581: Zeiger auf Diskettenname.
::105			ldy	#$00			;Diskettennamen einlesen.
::106			tya				;Zeiger auf aktuelles Zeichen im
			pha				;Diskettennamen zwischenspeichern.
			lda	(r15L),y		;Zeichen einelesen.
			cmp	#$a0			;Ende erreicht?
			beq	:109			;ja, Diskettenname komplett.
			cmp	#$20			;Zeichen kleiner $32 (Sonderzeichen)?
			bcc	:107			;Ja, durch "-" ersetzen.
			cmp	#$7f			;Gültiges Zeichen?
			bcc	:108			;Ja, weiter...
::107			lda	#"-"			;Nein, durch "-" ersetzen.
::108			jsr	SmallPutChar		;Zeichen auf Bildschirm ausgeben.
			pla				;Zeiger auf aktuelles Zeichen im
			tay				;Diskettennamen wieder herstellen.
			iny				;Zeiger auf nächstes Zeichen.
			cpy	#$10			;Ende erreicht?
			bne	:106			;Nein, weiter...
			beq	:110
::109			pla				;Zeiger auf Diskettenname verwerfen.
::110			jsr	TextInfo_ExtractDImg
			jsr	ClearJobInfo

;*** Dekodierung initialisieren.
			lda	#$01			;Zeiger auf Spur #1.
			sta	a3L
			lda	#$00			;Zeiger auf Sektor #0.
			sta	a3H

;*** Daten von Image-Datei einlesen.
:ReadImageSekData	ldx	a3L
			jsr	PrintJobInfo
			lda	SourceDrive		;Quell-Laufwerk öffnen.
			jsr	SetDevice
			jsr	EnterTurbo
			jsr	InitForIO

::101			LoadW	r15,DataSekBufStart	;Zeiger auf Anfang Zwischenspeicher.
			MoveB	a3L,a4L			;Start-Spur/-Sektor zwischenspeichern
			MoveB	a3H,a4H			;für WriteImageSekData.
			lda	#DataSekBufMax		;Sektor-Zähler auf Anfang setzen.
			sta	a5L			;Zähler für Daten lesen.
			sta	a5H			;Zähler für Daten schreiben.

;*** 32 Sektoren aus Image-Datei einlesen.
::102			ldx	a3L			;Zeiger auf aktuellen Sektor setzen.
			lda	a3H
			jsr	PosToSektor
			jsr	GetSektor		;Datenblock einlesen.
			dec	a5L			;Datenblock-Zähler herunterzählen.

			jsr	SetNextSek		;Zeiger auf nächsten Datenblock.
			bne	:103			;Letzter Datenblock? Ja, Ende.

			inc	r15H			;Zeiger auf Zwischenspeicher hochsetzen.
			lda	a5L			;Datenspeicher voll?
			bne	:102			;Nein, nächsten Sektor einlesen.

::103			jsr	DoneWithIO		;Laufwerk schließen.

			CmpBI	a5L,DataSekBufMax	;Wurden weitere Sektoren eingelesen?
			beq	EndOfImage		;Nein, Ende erreicht.

;*** Daten auf Disk schreiben.
:WriteImageSekData	lda	TargetDrive		;Ziel-Laufwerk öffnen.
			jsr	SetDevice
			jsr	EnterTurbo
			jsr	InitForIO

			LoadW	r4,DataSekBufStart	;Zeiger auf Anfang Zwischenspeicher.
			MoveB	a4L,a3L			;Start-Spur/-Sektor zurücksetzen.
			MoveB	a4H,a3H

;*** max. 32 Sektoren auf Diskette schreiben.
::101			MoveB	a3L,r1L			;Aktuellen Sektor auf Disk schreiben.
			MoveB	a3H,r1H
			jsr	WriteDataBlock
			txa
			bne	:102
			dec	a5H			;Datenblock-Zähler herunterzählen.

			jsr	SetNextSek		;Zeiger auf nächsten Datenblock.
			bne	EndOfImage		;Letzter Datenblock? Ja, Ende.

			inc	r4H			;Zeiger Zwischenspeicher hochsetzen.
			lda	a5H			;Datenspeicher voll?
			bne	:101			;Nein, nächsten Sektor einlesen.

			jsr	DoneWithIO		;Laufwerk schließen.
			jmp	ReadImageSekData	;Nächsten Speicherbereich einlesen.
::102			jmp	ExitDiskErr

;*** Image entpackt.
:EndOfImage		jsr	DoneWithIO		;Laufwerk schließen.
			jsr	ClrScreen		;Bildschirm löschen.
			jmp	OpenMain		;Zurück zum Hauptmenü.

;*** Datenblock schreiben.
;Bei 1581 auf ersten BAM-Sektor testen und
;Disk-Namen von BASIC/$04 nach GEOS/$90 tauschen.
:WriteDataBlock		lda	curType
			and	#%0000 0111
			cmp	#$03
			bne	ExitWriteBlock

			lda	r1L
			cmp	#40
			bne	ExitWriteBlock
			lda	r1H
			bne	ExitWriteBlock

			ldy	#$04			;Zeiger auf Angang Diskname.
			lda	(r4L),y			;Zeichen aus Original-Name lesen
			beq	ExitWriteBlock		;Kein Name vorhanden, Ende.

:SwapDskNamData		ldy	#$04			;Zeiger auf Angang Diskname.
::51			lda	(r4L),y			;Zeichen aus Original-Name lesen
			sta	SwapByteBuf		;und zwischenspeichern.

			tya				;Zeiger auf 1541/1571 kompatible
			clc				;Position des Disknamen setzen.
			adc	#$8c
			tay

			lda	(r4L),y			;Zeichen aus 1541/1571 kompatiblen
			pha				;Disknamen einlesen und merken.

			lda	SwapByteBuf		;Zeichen aus Original-Name wieder
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

:ExitWriteBlock		jmp	WriteBlock

:SwapByteBuf		b $00

;*** Prüfen ob Datenspeicher bereits von Programmcode belegt.
			g DataSekBufStart
