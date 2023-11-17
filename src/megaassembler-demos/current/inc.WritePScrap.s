; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; Photoscrap-Datei erstellen.
;
; Dazu wird ein 40Z-Bildausschnitt mit
; Grafik+Farbe in eine PhotoScrap-Datei
; gespeichert.
;
; Übergabe:
:scrapXPos		b $01				;x-Position in Cards.
:scrapYPos		b $08				;y-Position, nur ganze 8er-Blöcke!
:scrapWidth		b $03				;Breite: In Cards!
:scrapHeight		b $18				;Höhe  : Nur ganze 8er-Blöcke!
;
; Interne Variablen:
:dirEntryBlk		b $00,$00
:dirEntryAdr		w $0000
:curBlock		b $00,$00
:curByte		b $00
:nextFreeBlk		b $00,$00
;
; Benötigter Datenspeicher:
; :dataUnpacked = max. 40x8 Byte ungepackte Daten.
; :dataPacked   = max. 40x8 Byte + ca.30 Kompressionsbyte, wenn alle
;                 Datenbyte verschieden sind und ein packen unmöglich ist.

;
; PhotoScrap erstellen.
;
; Hauptroutine:
; - Leere Photoscrap-Datei erstellen
; - Grafikdaten packen und anhängen
; - Farbdaten packen und anhängen
; - Photoscrap-Dateigröße korrigieren
;
:CREATE_PSCRAP		php				;Interrupt sperren.
			sei

			jsr	scrapCreateFile		;Photoscrap-Datei erstellen.
			txa				;Diskettenfehler?
			bne	:1			; => Ja, Abbruch...

			jsr	scrapDefScrData		;Startadresse Grafikdaten berechnen.

			jsr	scrapWriteFile		;Grafikdaten packen.

			LoadW	a0,COLOR_MATRIX		;Startadresse der Farbdaten ab
			jsr	scrapDefColData		;COLOR_MATRIX berechnen.

			jsr	scrapWriteFile		;Farbdaten packen.

			jsr	scrapCloseFile		;Letzten Block Photoscrap speicher.

::1			plp				;Interrupt-Status zurücksetzen.
			rts

;
; Zeiger auf Grafikdaten berechnen.
;
:scrapDefScrData	lda	scrapYPos		;Grafilzeile 0-24 berechnen.
			lsr
			lsr
			lsr

			asl				;Anfangsadresse Grafikdaten im
			tax
			lda	dataStartGfx +0,x	;Speicher ab SCREEN_BASE für die
			clc				;aktuelle Grafikzeile berechnen.
			adc	#< SCREEN_BASE
			sta	a0L
			lda	dataStartGfx +1,x
			adc	#> SCREEN_BASE
			sta	a0H

			lda	scrapXPos		;x-Koordinate in Cards nach
			asl				;Pixel umwandeln und zur Adresse
			asl				;der Grafikdaten addieren.
			asl
			php				;Überlauf im Carry-Flag speichern.
			clc
			adc	a0L
			sta	a0L
			plp				;"Add with Carry": Überlauf über
			lda	#$00			;das Carry-Flag berücksichtigen.
			adc	a0H
			sta	a0H

			lda	scrapWidth		;Anzahl Datenbyte in Grafikzeile:
			asl				;8 Byte je Card x Anzahl Cards
			asl
			asl
			sta	a4L
			ldx	#$00
			bcc	:1			;Überlauf?
			inx				; => Ja, Highbyte anpassen.
::1			stx	a4H			;Nur Werte von $0000-$013f möglich.

			lda	#< 40*8			;Offset bis zum Beginn der
			sta	a5L			;der nächsten Zeile festlegen.
			lda	#> 40*8
			sta	a5H

			lda	#8			;Anzahl Daten innerhalb einer Zeile.
			sta	a3L

			rts

;
; Offset-Tabelle für Grafikdaten.
;
:dataStartGfx		w 40 *8 *0  , 40 *8 *1  , 40 *8 *2  , 40 *8 *3
			w 40 *8 *4  , 40 *8 *5  , 40 *8 *6  , 40 *8 *7
			w 40 *8 *8  , 40 *8 *9  , 40 *8 *10 , 40 *8 *11
			w 40 *8 *12 , 40 *8 *13 , 40 *8 *14 , 40 *8 *15
			w 40 *8 *16 , 40 *8 *17 , 40 *8 *18 , 40 *8 *19
			w 40 *8 *20 , 40 *8 *21 , 40 *8 *22 , 40 *8 *23
			w 40 *8 *24

;
; Zeiger auf Farbdaten berechnen.
;
:scrapDefColData	lda	scrapYPos		;Grafilzeile 0-24 berechnen.
			lsr
			lsr
			lsr

			asl				;Anfangsadresse Farbdaten im
			tax
			lda	dataStartCol +0,x	;Speicher ab COLOR_MATRIX für die
			clc				;aktuelle Farbzeile berechnen.
			adc	#< COLOR_MATRIX
			sta	a0L
			lda	dataStartCol +1,x
			adc	#> COLOR_MATRIX
			sta	a0H

			lda	a0L			;x-Koordinate zur Anfrangsadresse
			clc				;der Farbdaten addieren.
			adc	scrapXPos
			sta	a0L
			bcc	:1
			inc	a0H

::1			lda	scrapWidth		;Anzahl Datenbyte in Farbzeile:
			sta	a4L			;max. 40 Cards möglich.
			lda	#$00
			sta	a4H

			lda	#< 40			;Offset bis zum Beginn der
			sta	a5L			;der nächsten Zeile festlegen.
			lda	#> 40
			sta	a5H

			lda	#1			;Anzahl Daten innerhalb einer Zeile.
			sta	a3L

			rts

;
; Offset-Tabelle für Farbdaten.
;
:dataStartCol		w 40 *0  , 40 *1  , 40 *2  , 40 *3
			w 40 *4  , 40 *5  , 40 *6  , 40 *7
			w 40 *8  , 40 *9  , 40 *10 , 40 *11
			w 40 *12 , 40 *13 , 40 *14 , 40 *15
			w 40 *16 , 40 *17 , 40 *18 , 40 *19
			w 40 *20 , 40 *21 , 40 *22 , 40 *23
			w 40 *24

;
; Leere Photoscrap-Datei erzeugen.
;
; Dabei wird ein vorhandenes Photoscrap
; gelöscht und eine neue Datei mit den
; drei Headerbyte für die Größe des
; Photoscrap gespeichert.
;
:scrapCreateFile	jsr	:delete			;Vorhandene Datei löschen.

			lda	scrapWidth		;Größe des Photoscrap in die
			sta	pScrapHdr +0		;Headerbyte übernehmen.
			lda	scrapHeight
			sta	pScrapHdr +1
			lda	#$00			;Höhe max. 200 Pixel, das
			sta	pScrapHdr +2		;Highbyte ist daher immer NULL.

			LoadW	r9  ,HdrPS_Dok		;Zeiger auf Infoblock.
			LoadB	r10L,$00		;Zeiger auf Anfang Verzeichnis.
			jsr	SaveFile		;Leeres Photoscrap speichern.
			txa				;Diskettenfehler?
			bne	:delete			; => Ja, Abbruch...

			LoadW	r6,photoScrapName
			jsr	FindFile		;Dateieintrag Photoscrap suchen.
			txa				;Diskettenfehler?
			bne	:delete			; => Ja, Abbruch...

			lda	r1L			;Adresse des Verzeichnisblock
			sta	dirEntryBlk +0		;zwischenspeichern.
			lda	r1H
			sta	dirEntryBlk +1

			lda	r5L			;Zeiger auf Eintrag innerhalb
			sta	dirEntryAdr +0		;des Verzeichnisblock speichern.
			lda	r5H
			sta	dirEntryAdr +1

			ldx	#1			;Suche für nächsten freien
			stx	nextFreeBlk +0		;Block initialisieren.
			dex
			stx	nextFreeBlk +1

			lda	dirEntryBuf +1		;Zeiger auf Track/Sektor des ersten
			ldx	dirEntryBuf +2		;Block im Photoscrap einlesen.

			sta	curBlock +0		;Adresse des aktuellen Datenblock
			stx	curBlock +1		;zwischenspeichern.

			ldy	#5 -1			;Zeiger auf das letzte Byte im
			sty	curByte			;aktuellen Datenblock definieren.

			sta	r1L			;Zeiger auf Track/Sektor des
			stx	r1H			;ersten Datenblock im Photoscrap.

			jsr	GetBlockBuf		;Ersten Block Photoscrap einlesen.
			txa				;Diskettenfehler?
			beq	:done			; => Nein, Ende...

::delete		LoadW	r0,photoScrapName
			jsr	DeleteFile		;Vorhandenes Photoscrap löschen.
;			txa				;Diskettenfehler?
;			beq	:done			; => Nein, Ende...

::done			rts

;
; Daten in Photoscrap-Datei speichern.
;
; Dabei werden die Grafik-/Farbdaten
; zeilenweise in den Zwischenspeicher
; übertragen, gepackt und dann an die
; Photoscrap-Datei angehängt.
;
:scrapWriteFile		lda	scrapHeight		;Anzahl Zeilen in Cards
			lsr				;berechnen.
			lsr
			lsr

;
; Test auf Anzahl Zeilen=0 kann
; entfallen, da Photoscrap mindestens
; 1 Card hoch ist.
;
::loop			pha				;Zähler auf Stack speichern.

			jsr	scrapCopyData		;Daten einlesen.

			jsr	scrapPackData		;Daten packen.

			jsr	scrapUpdateFile		;Gepackte Daten speichern.

			pla				;Zeilen-Zähler wieder einlesen.

			cpx	#$00			;Diskettenfehler?
			bne	:err			; => Ja, Abbruch...

			sec				;Zeilen-Zähler korrigieren.
			sbc	#1			;Alle Zeilen gespeichert?
			bne	:loop			; => Nein, weiter...

::err			rts

;
; Daten an Photoscrap anhängen.
;
; Ablauf:
; - Test auf "Daten vorhanden"
; - Ist Datenblock voll?
;   - Ja, Datenblock speichern und
;     neuen Datenblock anlegen.
;   - Nein, Byte in Datenblock
;     übernehmen.
; - Weiter bis alle Byte gespeichert.
;
:scrapUpdateFile	lda	#< dataPacked		;Zeiger auf gepackte Daten.
			sta	r0L
			lda	#> dataPacked
			sta	r0H

::next			lda	r2L			;Sind noch Daten vorhanden?
			ora	r2H
			bne	:1			; => Ja, weiter...

			ldx	#$00			;Ende, kein Fehler.
::err			rts

::1			ldx	curByte			;Zeiger auf letztes Byte einlesen.
			inx				;Ist aktueller Datenblock voll?
			bne	:2			; =>> Nein, weiter...

			jsr	GetNxFreeBlk		;Freien Block suchen.
			txa				;Diskettenfehler?
			bne	:err			; => Ja, Abbruch...

			ldx	#2			;Zeiger auf nächste Byte-Position.

			inc	dirEntryBuf +28		;Anzahl Blocks für Photoscrap
			bne	:2			;korrigieren.
			inc	dirEntryBuf +29

::2			stx	curByte			;Zeiger auf Datenbyte speichern.

			ldy	#$00			;Wert aus Zwischenspeicher
			lda	(r0L),y			;einlesen und in Datenblock
			sta	diskBlkBuf,x		;übernehmen.

			lda	r2L			;Anzahl Datenbytes -1.
			bne	:3
			dec	r2H
::3			dec	r2L

			inc	r0L			;Zeiger auf Zwischenspeicher
			bne	:4			;korrigieren.
			inc	r0H

::4			jmp	:next			;Weiter mit nächstem Byte.

;
; Photoscrap-Datei schließen.
;
; Dabei wird der letzte Datenblock der
; noch im Speicher ist auf Diskette
; gespeichert und die Blockanzahl für
; das Photoscrap korrigiert.
;
:scrapCloseFile		lda	#$00			;Linkbyte im aktuellen Datenblock
			sta	diskBlkBuf +0		;auf $00=Dateiende setzen.
			lda	curByte			;Zeiger auf das letzte Byte im
			sta	diskBlkBuf +1		;aktuellen Datenblock übernehmen.

			lda	curBlock +0		;Adresse des aktuellen
			sta	r1L			;Datenblock einlesen.
			lda	curBlock +1
			sta	r1H

			jsr	PutBlockBuf		;Aktuellen Block speichern.
			txa				;Diskettenfehler?
			bne	:err			; => Ja, Abbruch...

			lda	dirEntryBlk +0		;Track/Sektor für Verzeichnisblock
			sta	r1L			;des Photoscrap einlesen.
			lda	dirEntryBlk +1
			sta	r1H

			jsr	GetBlock		;Verzeichnisblock einlesen.
			txa				;Diskettenfehler?
			bne	:err			; => Ja, Abbruch...

			ldy	dirEntryAdr		;Anzahl Blocks für Photoscrap
			lda	dirEntryBuf +28		;im Verzeichniseintrag anpassen.
			sta	diskBlkBuf  +28,y
			lda	dirEntryBuf +29
			sta	diskBlkBuf  +29,y

			jsr	PutBlock		;Verzeichnisblock speichern.
			txa				;Diskettenfehler?
			bne	:err			; => Ja, Abbruch...

;
; SetNextFree reserviert den nächsten
; Block nur in der BAM im Speicher.
; Zum Schluss die BAM speichern!
;
			jsr	PutDirHead		;BAM aktualisieren.
;			txa				;Diskettenfehler?
;			bne	:err			; => Ja, Abbruch...

::err			rts

;
; Sektor in diskBlkBuf schreiben
;
:PutBlockBuf		lda	#< diskBlkBuf		;Zeiger auf Zwischenspeicher für
			sta	r4L			;den aktuellen Datenblock setzen.
			lda	#> diskBlkBuf
			sta	r4H

			jmp	PutBlock		;Aktuellen Block speichern.

;
; Sektor nach diskBlkBuf einlesen
;
:GetBlockBuf		lda	#< diskBlkBuf		;Zeiger auf Zwischenspeicher für
			sta	r4L			;den aktuellen Datenblock setzen.
			lda	#> diskBlkBuf
			sta	r4H

			jmp	GetBlock		;Aktuellen Block speichern.

;
; Nächsten freien Block suchen
;
:GetNxFreeBlk		lda	nextFreeBlk +0
			sta	r3L
			lda	nextFreeBlk +1
			sta	r3H
			jsr	SetNextFree		;Neuen freien Datenblock suchen.
			txa				;Diskettenfehler?
			bne	:err			; => Ja, Abbruch...

			lda	curBlock +0		;Adresse des aktuellen
			sta	r1L			;Datenblock einlesen.
			lda	curBlock +1
			sta	r1H

			lda	r3L			;Adresse des freien Datenblock.
			ldx	r3H
			sta	nextFreeBlk +0		;Adresse Track/Sektor als neue
			stx	nextFreeBlk +1		;Startwert für Sektorsuche setzen.

			sta	curBlock +0		;Neuer Datenblock als "Aktuell"
			stx	curBlock +1		;setzen.

			sta	diskBlkBuf +0		;Adresse des neuen Datenblock als
			stx	diskBlkBuf +1		;Linkbyte im aktuellen Block setzen.

			jsr	PutBlockBuf		;Aktuellen Block speichern.
;			txa				;Diskettenfehler?
;			bne	:err			; => Ja, Abbruch...

::err			rts

;
; Photoscrap-Daten kopieren.
;
; Die Daten werden aus dem Bildschirm-
; oder Farbspeicher zuerst ungepackt in
; den Zwischenspeicher kopiert.
; Dabei werden Grafikdaten in ganzen
; Pixelzeilen kopiert. Das ganze wird
; für 8 Pixelzeilen wiederholt.
; Bei Farbdaten wird nur eine Zeile
; in den Zwischenspeicher kopiert.
;
; Übergabe:
; a0  = Zeiger auf ungepackte Daten.
; a4  = Anzahl zu packender Daten.
; a5  = Offset zur nächsten Zeile.
; a3L = Anzahl Pixelzeilen.
;
:scrapCopyData		lda	a0L			;Zeiger auf ungepackte Daten.
			ldx	a0H
			sta	r0L
			stx	r0H

			lda	#< dataUnpacked		;Zeiger auf Zwischenspeicher.
			ldx	#> dataUnpacked
			sta	r1L
			stx	r1H

			lda	#0			;Zähler für Pixelzeilen
			sta	a3H			;initialisieren.

::1			ldx	scrapWidth		;Anzahl Cards in Zeile einlesen.

			lda	r0H			;Zeiger auf Anfang der aktuellen
			pha				;Zeile zwischenspeichern.
			lda	r0L
			pha

::2			ldy	#0			;Grafik- oder Farbbyte kopieren.
			lda	(r0L),y
			sta	(r1L),y

			lda	r0L			;Zeiger auf nächstes Byte in
			clc				;aktueller Zeile berechnen.
			adc	a3L
			sta	r0L
			bcc	:3
			inc	r0H

::3			inc	r1L			;Zeiger auf nächstes Byte im
			bne	:4			;Zwischenspeicher setzen.
			inc	r1H

::4			dex				;Alle Cards bearbeitet?
			bne	:2			; => Nein, weiter...

			pla				;Startadresse der nächsten
			clc				;Pixelzeile berechnen.
			adc	#< 1
			sta	r0L
			pla
			adc	#> 1
			sta	r0H

			inc	a3H			;Zeilenzähler +1.

			lda	a3H			;Wurde alle Pixelzeilen bzw. die
			cmp	a3L			;komplette Farbzeile kopiert?
			bne	:1			; => Nein, weiter...

			AddW	a5,a0			;Zeiger auf nächste Zeile.

			rts

;
; Daten packen.
;
; dataUnpacked = Ungepackte Daten.
; dataPacked = Zwischenspeicher.
;
; Verwendete Register:
; a4  = Anzahl ungepackte Datenbyte.
; a6  = Anzahl der noch zu bearbeitenden Bytes.
; a9L = Anzahl identische Bytes.
; a9H = Anzahl ungepackter Bytes.
;
; Rückgabe:
; r2  = Anzahl gepackte Datenbyte.
;
:scrapPackData		LoadW	r0,dataUnpacked		;Zeiger auf ungepackte Daten.
			LoadW	r1,dataPacked		;Zeiger auf Zwischenspeicher.

			MoveW	a4,a6			;Anzahl Bytes in Zeile.

			lda	#$00			;Anzahl identische Byte
			sta	a9L			;zurücksetzen.

;*** Bytes aus Zwischenspeicher einlesen, packen und in Speicher für
;    GeoPaint-Datensatz kopieren.
::next			jsr	scrapEqualBytes		;Nach gleichen Bytes suchen.

			ldy	#< scrapPackNone	;Vorgabe:
			ldx	#> scrapPackNone	;Daten nicht packen.

			lda	a9L			;Anzahl zu packender Bytes.
			cmp	#$04			;Mehr als vier Bytes?
			bcc	:1			; => Ja, Daten nicht packen.

			ldy	#< scrapPackBytes	;$8x=Einzelbyte (max. 127x) packen.
			ldx	#> scrapPackBytes

::1			tya
			jsr	CallRoutine		;Daten packen/nicht packen.

			lda	a6L
			ora	a6H			;Alle Bytes gepackt?
			bne	:next			; => Nein, weiter...

			lda	r1L			;Anzahl der gepackten Datenbyte
			sec				;berechnen.
			sbc	#< dataPacked
			sta	r2L
			lda	r1H
			sbc	#> dataPacked
			sta	r2H

			rts

;
; Identische Datenbyte suchen.
;
; Sucht in den ungepackten Datenbyte
; mehrere gleiche, aufeinanderfolgende
; Einzelbyte.
;
:scrapEqualBytes	lda	a9L			;Sind noch gleiche Einzelbytes
			bne	:exit			;im Speicher? Nein, Daten noch
							;nicht komplett gepackt, nächste
							;Einzelbytes packen.

			ldy	#$00			;Zeiger auf aktuelles Byte.
			lda	(r0L),y			;Aktuelles Byte einlesen.
			iny				;Zeiger auf nächstes Byte.
::loop			cmp	(r0L),y			;Byte identisch mit aktuellem Byte?
			bne	:done			; => Nein, weiter...
			iny				;Zähler für gleiche Byte erhöhen.
			cpy	#$7f			;Max. 127 gleiche Bytes erreicht?
			bcc	:loop			; => Nein, weiter...

::done			lda	a6H			;Anzahl gleiche Bytes mit Anzahl
			bne	:1			;der noch zu packenden Bytes
			cpy	a6L			;vergleichen.
			bcc	:1
			beq	:1
			ldy	a6L			;Anzahl Bytes auf Restbytes setzen.

::1			tya				;Anzahl gleicher Einzelbytes
			sta	a9L			;zwischenspeichern.

::exit			rts

;
; Gleiche Einzelbytes packen.
;
; Übergabe:
; a9L = Anzahl gleiche Datenbyte.
; r0  = Zeiger auf ungepackte Daten.
; r1  = Zeiger auf gepackte Daten.
;
:scrapPackBytes		lda	a9L			;Anzahl Einzelbytes einlesen.

			ldy	#$00			;Zeiger auf Zwischenpeicher.
			sta	(r1L),y			;Kompressionsbyte $01-$7f setzen.

			lda	(r0L),y			;Zu packendes Datenbyte einlesen.
			iny				;Zeiger auf nächstes Byte setzen.
			sta	(r1L),y			;Byte in Zwischenpeicher kopieren.

			lda	#2			;Zeiger für Zwischenpeicher auf
			clc				;nächstes Byte setzen.
			adc	r1L
			sta	r1L
			bcc	:1
			inc	r1H

::1			lda	a9L			;Zeiger auf Datenbyte um Anzahl
			clc				;der Einzelbytes erhöhen.
			adc	r0L
			sta	r0L
			bcc	:2
			inc	r0H

::2			lda	a6L			;Anzahl noch zu packender Bytes
			sec				;korrigieren.
			sbc	a9L			; => In :a9L steht die Anzahl der
			sta	a6L			;    gepackten Einzelbytes.
			bcs	:3
			dec	a6H

::3			lda	#$00			;Zähler Anzahl Einzelbyte löschen.
			sta	a9L

			rts

;
; Daten ungepackt übernehmen.
;
; Übergabe:
; r0  = Zeiger auf ungepackte Daten.
; r1  = Zeiger auf gepackte Daten.
;
:scrapPackNone		jsr	scrapCountBytes		;Ungepackte Bytes zählen.

			lda	a9H			;Anzahl ungepackter Bytes.
			cmp	#($dc-$81)		;Mehr als 90 Byte?
			bcc	:1			; => Nein, weiter...
			lda	#($dc-$81)		;Max. 90 ungepackte Byte möglich.
			sta	a9H
::1			ora	#%10000000		;Packmodus "Ungepackt" setzen.
			ldy	#$00			;Zeiger auf Zwischenpeicher.
			sta	(r1L),y			;Kompressionsbyte speichern.

			inc	r1L
			bne	:2
			inc	r1H

::2			ldy	a9H			;Anzahl ungepackter Bytes in
			dey				;Zwischenspeicher kopieren.
			jsr	scrapCopyYRegByt

			lda	a9H			;Zeiger für Zwischenspeicher auf
			clc				;nächstes Byte setzen.
			adc	r1L
			sta	r1L
			bcc	:3
			inc	r1H

::3			lda	a9H			;Zeiger auf Datenbyte um Anzahl
			clc				;ungepackter Bytes erhöhen.
			adc	r0L
			sta	r0L
			bcc	:4
			inc	r0H

::4			lda	a6L			;Anzahl noch zu packender Bytes
			sec				;korrigieren.
			sbc	a9H			; => In :a9H steht die Anzahl der
			sta	a6L			;    ungepackten Einzelbytes.
			bcs	:5
			dec	a6H

::5			rts

;
; Datenbytes kopieren.
;
; Übergabe:
; yReg = Anzahl Bytes -1
;        max. 128 Byte!
;
:scrapCopyYRegByt	lda	(r0L),y			;Byte einlesen und in
			sta	(r1L),y			;Zwischenspeicher kopieren.
			dey				;Alle Bytes kopiert?
			bpl	scrapCopyYRegByt	; => Nein, weiter...
			rts

;
; Anzahl ungepackter Daten berechnen.
;
; Rückgabe:
; a9H = Anzahl Einzelbytes.
;
:scrapCountBytes	lda	#$01			;Max. Anzahl ungepackter Bytes auf
			sta	a9H			;Startwert setzen.

			PushW	r0			;Zeiger auf Grafikdaten retten.
			PushW	a6			;Anzahl zu packender Bytes retten.

			jsr	scrapPosNxByte		;Zeiger auf nächstes Byte setzen.

::loop			lda	a6L			;Weitere Bytes in Grafikspeicher
			ora	a6H			;zum packen vorhanden?
			beq	:exit			; => Nein, Ende...

			lda	#$00			;Einzelbyte-Flag löschen.
			sta	a9L

			jsr	scrapEqualBytes		;Gleiche Einzelbytes suchen.
			cmp	#4			;Mehr als vier gleiche Bytes?
			bcs	:exit			; => Ja, Einzelbytes packen.

			jsr	scrapPosNxByte		;Zeiger auf nächstes Byte.

			inc	a9H			;Anzahl ungepackter Datenbyte +1.

			lda	a9H
			cmp	#90 +1			;Max. 90 Bytes gefunden?
			bcc	:loop			; => Nein weiter...

			lda	#$00			;Einzelbyte-Flag löschen.
			sta	a9L

::exit			PopW	a6			;Anzahl noch zu packender Bytes
			PopW	r0			;und Zeiger auf Grafikdaten wieder
			rts				;zurücksetzen.

;
; Zeiger auf nächstes Datenbyte.
;
; Übergabe:
; r0 = Zeiger Originaldaten.
; a6 = Zähler Restdaten.
;
:scrapPosNxByte		inc	r0L			;Zeiger auf nächstes Byte der
			bne	:51			;Grafikdaten setzen.
			inc	r0H

::51			lda	a6L			;Anzahl noch zu packender Bytes
			bne	:52			;korrigieren.
			dec	a6H
::52			dec	a6L

			rts

;
; Name der Photoscrap-Datei.
;
:photoScrapName		b "Photo Scrap",NULL

;
; Infoblock für Photoscrap-Datei.
;
:HdrPS_Dok		w photoScrapName
			b $03,$15
			j
<MISSING_IMAGE_DATA>

:HdrPS_068		b $80!SEQ
:HdrPS_069		b SYSTEM
:HdrPS_070		b SEQUENTIAL
:HdrPS_071		w pScrapHdr			;Zeiger auf Header-Bytes.
			w pScrapHdr +3			;Nur 3 Byte speichern.
			w $0000
:HdrPS_077		b "Photo Scrap "		;Klasse.
:HdrPS_089		b "V1.1"			;Version.
:HdrPS_093		b $00,$00,$00,$00		;Reserviert.
:HdrPS_160		e HdrPS_Dok +160 +1		;Info.

;
; Headerbytes für Photoscrap:
; 1 Byte = Breite in Cards.
; 1 Word = Höhe in Pixel.
;
:pScrapHdr		b $00				;Breite in Cards.
			w $0000				;Höhe in Pixel.
