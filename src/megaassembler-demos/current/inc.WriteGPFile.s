; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; Screenshot erstellen.
;
; Dazu wird ein 40Z-Bildschirm mit
; Grafik+Farbe in einer GeoPaint-Datei
; gespeichert.
;
; Benötigter Datenspeicher:
; :dataUnpacked = 1280 +8 +160 +1 Byte ungepackte Daten.
; :dataPacked   = 1280 +8 +160 +1 +48 Byte gepackte Daten.
;
; Im ungünstigsten Fall müssen alle
; Grafikdaten ungepackt gespeichert
; werden. In dem Fall werden zusätzlich
; ca.48Bytes (1448 Daten / max.31Bytes)
; für :dataPacked benötigt.
;
:CREATE_GIMAGE		php				;Interrupt sperren.
			sei

			jsr	paintCreateFile		;GeoPaint-Datei erstellen.
			txa				;Diskettenfehler?
			bne	:err			; => Ja, Abbruch...

			LoadW	r0,paintFileName
			jsr	OpenRecordFile		;GeoPaint-Datei öffnen.
			txa				;Diskettenfehler?
			bne	:err			; => Ja, Abbruch...

			jsr	paintWriteFile		;ScreenShot erstellen.
			txa				;Diskettenfehler?
			bne	:err			; => Ja, Abbruch...

			jsr	UpdateRecordFile	;VLIR-Datei aktualisieren und
			jsr	CloseRecordFile		;GeoPaint-Dokument schließen.
			txa				;Diskettenfehler?
			beq	:1			; => Nein, Ende...

;
; Disk-I/O-Fehler.
; Unvollständige Datei löschen.
;
::err			pha				;Fehlerstatus zwischenspeichern.

			jsr	CloseRecordFile		;VLIR-Datei schließen.

			LoadW	r0,paintFileName
			jsr	DeleteFile		;Beschädigte Datei löschen.

			pla
			tax				;Fehlerstatus zurücksetzen.

::1			plp				;Interrupt-Status zurücksetzen.
			rts

;
; Neues GeoPaint-Dokument erstellen.
;
:paintCreateFile	jsr	:delete			;Vorhandene Datei löschen.

			LoadW	r9  ,HdrGP_Dok
			LoadB	r10L,$00
			jsr	SaveFile		;Leeres Dokument speichern.
			txa				;Diskettenfehler?
			bne	:delete			; => Ja, Abbruch...

			LoadW	r0,paintFileName
			jsr	OpenRecordFile		;Neues Dokument öffnen.
			txa				;Diskettenfehler?
			bne	:delete			; => Ja, Abbruch...

			lda	#0
::loop			pha
			jsr	AppendRecord		;Datensatz einfügen.
			pla
			cpx	#$00 			;Diskettenfehler?
			bne	:delete			; => Ja, Abbruch...
			clc
			adc	#$01
			cmp	#45			;45 Datensätze = 90 Cards Bildgröße.
			bcc	:loop

			jsr	UpdateRecordFile	;VLIR-Datei aktualisieren.
			txa				;Diskettenfehler?
			bne	:delete			; => Ja, Abbruch...

			jsr	CloseRecordFile		;GeoPaint-Dokument schließen.
			txa				;Diskettenfehler?
			beq	:done			; => Nein, Ende...

::delete		LoadW	r0,paintFileName
			jsr	DeleteFile		;Vorhandenes Photoscrap löschen.
;			txa				;Diskettenfehler?
;			beq	:done			; => Nein, Ende...

::done			rts

;
; Grafikdaten in Datei schreiben.
;
; Dabei werden die Grafikdaten von zwei
; Card-Zeilen (2x8=16 Pixel Höhe) und
; die dazugehörigen Farbdaten in einem
; VLIR-Datensatz gespeichert.
;
:paintWriteFile		LoadW	a0,SCREEN_BASE		;Startadresse Grafikdaten.
			LoadW	a2,COLOR_MATRIX		;Startadresse Farbdaten.

			lda	#$00			;Zeiger auf ersten Datensatz.
			jsr	PointRecord

			lda	#00			;Zeiger auf erste Grafik-Zeile.
::loop			sta	r12H

			jsr	paintCopyData		;Bildschirmdaten einlesen.
							;(2*640 Grafik, 2*80 Farbe).
			jsr	paintPackData		;Bildschirmdaten packen.

			LoadW	r7,dataPacked		;Zeiger auf Zwischenspeicher.
			jsr	WriteRecord		;Datensatz auf Diskette schreiben.
			txa
			bne	:err

			jsr	NextRecord		;Zeiger auf nächsten Datensatz.
			txa
			bne	:err

			inc	r12H			;Zähler korrigieren.

			lda	r12H			;13x2 Cards = max.26 Cards Höhe.
			cmp	#13			;Alle Daten kopiert?
			bcc	:loop			; => Nein, weiter...

::err			rts

;
; Daten in Zwischenspeicher kopieren.
;
; Die Daten werden aus dem Bildschirm-
; speicher zuerst ungepackt in den
; Zwischenspeicher kopiert:
;    320 Byte (Grafik-Zeile #1) + 320 Leerbytes
;  + 320 Byte (Grafik-Zeile #2) + 320 Leerbytes
;  +   8 Byte (reserviert)
;  +  40 Byte (Farben-Zeile #1) +  40 Leerbytes
;  +  40 Byte (Farben-Zeile #2) +  40 Leerbytes
;
;Übergabe:
; a0  = Zeiger auf Grafikdaten.
; a2  = Zeiger auf Farbdaten.
;
:paintCopyData		jsr	i_FillRam		;Zwischenspeicher für Grafikdaten
			w	1280 +8			;löschen (incl. 8 Füllbytes).
			w	dataUnpacked +   0
			b	$00

			jsr	i_FillRam		;Zwischenspeicher für Farbdaten
			w	160			;mit Vorgabewert füllen.
			w	dataUnpacked +1288
			b	$bf

			lda	#< dataUnpacked
			sta	a1L
			lda	#> dataUnpacked
			sta	a1H			;Zeiger auf ungepackte Grafikdaten.

			lda	#< dataUnpacked +1288
			sta	a3L
			lda	#> dataUnpacked +1288
			sta	a3H			;Zeiger auf ungepackte Farbdaten.

			lda	r12H
			cmp	#12			;Letzte Doppelzeile schreiben?
			beq	:skip			; => Ja, nur eine Zeile kopieren.

			jsr	getDataGrfx		;Grafikdaten in Zwischenspeicher.
			jsr	getDataCols		;Farbdaten   in Zwischenspeicher.

::skip			jsr	getDataGrfx		;Grafikdaten in Zwischenspeicher.
			jmp	getDataCols		;Farbdaten   in Zwischenspeicher.

;
; Grafikdaten einlesen.
;
; Dabei werden die Grafikdaten aus dem
; Bildschirmspeicher in den Puffer für
; die ungepackten Daten kopiert.
;
:getDataGrfx		MoveW	a0 ,r0			;320 Grafikdaten kopieren.
			MoveW	a1 ,r1
			LoadW	r2 ,320
			jsr	MoveData

			AddVW	320,a0			;Zeiger auf nächste Grafikzeile.
			AddVW	640,a1			;Zeiger auf Speicher korrigieren.
			rts

;
; Farbdaten einlesen.
;
; Dabei werden die Farbdaten aus dem
; Farbspeicher in den Puffer für die
; ungepackten Daten kopiert.
;
:getDataCols		MoveW	a2 ,r0			;40 Farbdaten kopieren.
			MoveW	a3 ,r1
			LoadW	r2 ,40
			jsr	MoveData

			AddVW	40 ,a2			;Zeiger auf nächste Farbzeile.
			AddVW	80 ,a3			;Zeiger auf Speicher korrigieren.
			rts

;
; Daten packen.
;
; dataUnpacked = Ungepackte Daten.
; dataPacked   = Zwischenspeicher.
;
; Verwendete Register:
; a0  = Zeiger auf Zwischenspeicher für Grafikdaten.
; a1  = Zeiger auf VLIR-Speicher    für Grafikdaten.
; a2  = Zeiger auf Zwischenspeicher für Farbdaten.
; a3  = Zeiger auf VLIR-Speicher    für Farbdaten.
; a6  = Anzahl der noch zu bearbeitenden Bytes.
; a7  = Zwischenspeicher 8-Byte-Blocks.
; a8L = Anzahl 8-Byte-Blocks.
; a8H = Anzahl identische 8-Byte-Blocks.
; a9L = Anzahl identische Bytes.
; a9H = Anzahl ungepackter Bytes.
;
;Rückgabe:
; r2  = Anzahl gepackte Datenbytes.
;
;
; Max. Anzahl Datenbyte berechnen:
;
; 80 Cards Grafik x 8 Byte x 2 Zeilen
; + 8 Füllbyte
; + 80 Cards Farbe x 2 Zeilen
; = 1448 Bytes

;
; Bytes aus Zwischenspeicher einlesen,
; packen und in Speicher für Geopaint-
; Datensatz kopieren.
:paintPackData		LoadW	r0,dataUnpacked		;Zeiger auf ungepackte Daten.
			LoadW	r1,dataPacked		;Zeiger auf VLIR-Speicher.

			LoadW	a6,1448			;Max. Anzahl Datenbyte.

			lda	#$00
			sta	a9L			;Anzahl identische Einzelbytes.
			sta	a8H			;Anzahl identische 8-Byte-Blocks.

::next			jsr	paintEqualBytes		;Nach gleichen Bytes suchen.
			cmp	#8			;Mehr als 8 gleiche Bytes?
			bcs	:single			; => Ja, weiter...

;
; Mehrere 8-Byte-Blöcke?
;
::multi			jsr	paintGet8Block		;Gleichen 8-Byte-Blöcke suchen.
			cmp	#2			;Mehr als 1 gleicher Block?
			bcc	:single			; => Nein, weiter...

			ldy	#< paintPack8Block
			ldx	#> paintPack8Block
			bne	:exec			;$4x = 8-Byte-Blöcke packen.

;
; Einzelbytes packen oder
; ungepackte Daten?
;
::single		lda	a9L			;Anzahl zu packender Bytes.
			cmp	#4			;Mehr als vier Bytes?
			bcc	:unpacked		; => Ja, Daten nicht packen.

			ldy	#< paintPackSingle
			ldx	#> paintPackSingle
			bne	:exec			;$8x = Einzelbytes packen.

::unpacked		ldy	#< paintPackNoData
			ldx	#> paintPackNoData
;			bne	:exec			;$0x = Einzelbytes packen.

;
; Daten in Zwischenspeicher kopieren,
; gepackt oder ungepackt.
::exec			tya
			jsr	CallRoutine		;Packroutine aufrufen.

			lda	a6L
			ora	a6H			;Alle Bytes gepackt?
			bne	:next			; => Nein, weiter...

			lda	#$00			;Abschluss-Byte.
			tay				; => Farb- und Grafikdaten müssen
			sta	(r1L),y			;    mit einem NULL-Byte enden!
			inc	r1L
			bne	:done
			inc	r1H

::done			lda	r1L			;Anzahl gepackte Bytes berechnen.
			sec
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
; Übrgabe:
; r0  = Zeiger auf ungepackte Daten.
; a6  = Anzahl noch zu packender Daten.
; a9L = Anzahl identische Datenbyte.
;
:paintEqualBytes	lda	a9L			;Sind noch gleiche Einzelbytes
			bne	:skip			;im Speicher? Nein, Daten noch
							;nicht komplett gepackt, nächste
							;Einzelbytes packen.

			ldy	#$00			;Zeiger auf aktuelles Byte.
			lda	(r0L),y			;Aktuelles Byte einlesen.
			iny				;Zeiger auf nächstes Byte.
::loop			cmp	(r0L),y			;Byte identisch mit aktuellem Byte?
			bne	:exit			; => Nein, weiter...
			iny				;Zähler für gleiche Byte erhöhen.
			cpy	#63			;Max. 63 gleiche Bytes erreicht?
			bcc	:loop			; => Nein, weiter...

::exit			lda	a6H			;Anzahl gleiche Bytes mit Anzahl
			bne	:1			;der noch zu packenden Bytes
			cpy	a6L			;vergleichen.
			bcc	:1
			beq	:1
			ldy	a6L			;Anzahl Bytes auf Restbytes setzen.
::1			tya				;Anzahl gleicher Einzelbytes
			sta	a9L			;zwischenspeichern.

::skip			rts

;
; Identische 8-Byte-Blöcke suchen.
;
; Sucht in den ungepackten Datenbyte
; mehrere gleiche, aufeinanderfolgende
; 8-Byte-Blöcke.
;
; Übergabe:
; r0  = Zeiger auf ungepackte Daten.
; a6  = Anzahl noch zu packender Daten.
; a8H = Anzahl 8-Byte-Blöcke.
;
; Rückgabe:
; AKKU = Anzahl 8-Byte-Blöcke.
;
:paintGet8Block		lda	a8H			;Sind noch gleiche 8-Byte-Blöcke
			bne	:skip			;im Speicher? Nein, Daten noch
							;nicht komplett gepackt, nächsten
							;8-Byte-Block packen.

			lda	a6L			;Anzahl noch zu packender Bytes
			sta	a8L			;einlesen und durch 8 teilen.
			lda	a6H			;Dadurch noch verbleibende 8-Byte-
			lsr				;Blöcke berechnen.
			ror	a8L
			lsr
			ror	a8L
			lsr
			ror	a8L

			lda	a8L
			cmp	#2			;Mehr als 2x 8-Byte-Block übrig?
			bcs	:test			; => Ja, weiter...

			lda	#$00			;Packen nicht effektiv, da zu
::skip			rts				;wenig Bytes zum packen übrig.

::test			cmp	#63 +1			;Mehr als 63x 8-Byte-Block übrig?
			bcc	:init			; => Weniger als 63, weiter...
			lda	#63			;Max.-Wert 63 für 8-Byte-Blöcke
			sta	a8L			;in einen Packdurchgang setzen.

::init			lda	r0L			;Zeiger auf den ersten 8-Byte-
			sta	a7L			;Block setzen.
			lda	r0H
			sta	a7H

			ldx	#1			;Zähler initialisieren.
::next			lda	a7L			;Zeiger auf nächsten 8-Byte-Block.
			clc
			adc	#8
			sta	a7L
			bcc	:1
			inc	a7H

::1			ldy	#8 -1
::loop			lda	(r0L),y			;Bytes in nächstem 8-Byte-Block
			cmp	(a7L),y			;gleich wie aktueller 8-Byte-Block?
			bne	:exit			; => Nein, Ende...
			dey
			bpl	:loop			; => Ja, nächstes Byte testen...

			inx				;Max. Wert für gleiche Blöcke
			cpx	a8L			;erreicht (max. 63)?
			bcc	:next			; => Nein, weiter...

::exit			txa				;Anzahl gleicher 8-Byte-Blocks
			sta	a8H			;zwischenspeichern.
			rts

;
; Daten packen ($4x)
;
; Packt mehrere 8-Byte-Blöcke. Die
; 8-Byte sind nicht gepackt.
;
; Übergabe:
; r0  = Zeiger auf ungepackte Daten.
; r1  = Zeiger auf Zwischenspeicher.
; a6  = Anzahl noch zu packender Daten.
; a8H = Anzahl 8-Byte-Blöcke.
;
:paintPack8Block	lda	a8H			;Anzahl 8-Byte-Blocks einlesen.
			ora	#$40			;Kompressions-Flag setzen.

			ldy	#$00			;Zeiger auf Zwischenspeicher.
			sta	(r1L),y			;Kompressionsbyte setzen.

			inc	r1L			;Zeiger auf nächstes Byte im
			bne	:1			;Zwischenspeicher.
			inc	r1H

::1			ldy	#$07			;8-Byte-Block in VLIR-Speicher
			jsr	paintCopyYRegByt	;übertragen.

			lda	a8H			;Anzahl 8-Byte-Blocks einlesen und
			sta	a7L			;in Einzelbytes umrechnen.
			lda	#$00
			asl	a7L
			rol
			asl	a7L
			rol
			asl	a7L
			rol
			sta	a7H

			lda	a7L			;Zeiger auf Grafikdaten um Anzahl
			clc				;gepackter 8-Byte-Blocks erhöhen.
			adc	r0L
			sta	r0L
			lda	a7H
			adc	r0H
			sta	r0H

			lda	r1L			;Zeiger für Zwischenspeicher auf
			clc				;nächstes Byte setzen.
			adc	#8
			sta	r1L
			bcc	:2
			inc	r1H

::2			lda	a6L			;Anzahl noch zu packender Bytes
			sec				;korrigieren.
			sbc	a7L			; => In :a7 steht die Anzahl der
			sta	a6L			;    gepackten 8-Byte-Blöcke, umge-
			lda	a6H			;    rechnet in Einzelbytes.
			sbc	a7H
			sta	a6H

			jmp	paintClearFlags		;8-Byte/Einzelbyte-Flag löschen.

;
; Daten packen ($8x)
;
; Packt mehrere identische Einzelbyte.
;
; Übergabe:
; r0  = Zeiger auf ungepackte Daten.
; r1  = Zeiger auf Zwischenspeicher.
; a6  = Anzahl noch zu packender Daten.
; a9L = Anzahl Einzelbytes.
;
:paintPackSingle	lda	a9L			;Anzahl Einzelbytes einlesen.
			ora	#$80			;Kompressions-Flag setzen.

			ldy	#$00			;Zeiger auf VLIR-Speicher.
			sta	(r1L),y			;Kompressionsbyte setzen.

			lda	(r0L),y			;Zu packendes Byte einlesen und
			iny				;als Packbyte in den Zwischen-
			sta	(r1L),y			;speicher schreiben.

			lda	r1L			;Zeiger für Zwischenspeicher auf
			clc				;nächstes Byte setzen.
			adc	#2
			sta	r1L
			bcc	:1
			inc	r1H

::1			lda	a9L			;Zeiger auf Grafikdaten um Anzahl
			clc				;gepackter Einzelbytes erhöhen.
			adc	r0L
			sta	r0L
			bcc	:2
			inc	r0H

::2			lda	a6L			;Anzahl noch zu packender Bytes
			sec				;korrigieren.
			sbc	a9L			; => In :a9L steht die Anzahl der
			sta	a6L			;    gepackten Einzelbytes.
			bcs	paintClearFlags
			dec	a6H

;*** Flags für 8-Byte-Blöcke/Einzelbytes löschen.
:paintClearFlags	lda	#$00
			sta	a9L			;Anzahl Einzelbyte löschen.
			sta	a8H			;Anzahl 8-Byte-Blocks löschen.
			rts

;
; Daten ungepackt speichern ($01-$3f)
;
; Die Daten werden ungepackt in den
; Zwischenspeicher kopiert.
;
; Übergabe:
; r0  = Zeiger auf ungepackte Daten.
; r1  = Zeiger auf Zwischenspeicher.
; a6  = Anzahl noch zu packender Daten.
; a9H = Anzahl ungepackte Bytes.
;
:paintPackNoData	jsr	paintCountBytes		;Ungepackte Bytes zählen.

			lda	a9H			;Anzahl ungepackter Bytes.
			ldy	#$00			;Zeiger auf VLIR-Speicher.
			sta	(r1L),y			;Kompressionsbyte setzen.

			inc	r1L			;Zeiger auf nächstes Byte im
			bne	:1			;Zwischenspeicher.
			inc	r1H

::1			ldy	a9H			;Anzahl ungepackter Bytes in
			dey				;Zwischenspeicher kopieren.
			jsr	paintCopyYRegByt

			lda	a9H			;Zeiger auf Grafikdaten um Anzahl
			clc				;ungepackter Bytes erhöhen.
			adc	r0L
			sta	r0L
			bcc	:2
			inc	r0H

::2			lda	a9H			;Zeiger für VLIR-Speicher auf
			clc				;nächstes Byte setzen.
			adc	r1L
			sta	r1L
			bcc	:3
			inc	r1H

::3			lda	a6L			;Anzahl noch zu packender Bytes
			sec				;korrigieren.
			sbc	a9H			; => In :a9H steht die Anzahl der
			sta	a6L			;    ungepackten Einzelbytes.
			bcs	:4
			dec	a6H

::4			rts

;
; Anzahl Bytes aus Grafikspeicher in
; Zwischenspeicher kopieren.
;
; Übergabe:
; yReg = Anzahl Bytes -1,
;        max. 128 Bytes!
:paintCopyYRegByt	lda	(r0L),y			;Byte einlesen und in
			sta	(r1L),y			;Zwischenspeicher kopieren.
			dey				;Alle Bytes kopiert?
			bpl	paintCopyYRegByt	; => Nein, weiter...
			rts

;
; Anzahl ungepackte Daten berechnen.
;
; Übergabe:
; r0  = Zeiger auf ungepackte Daten.
; a6  = Anzahl noch zu packender Daten.
;
; Rückgabe:
; a9H = Anzahl ungepackte Daten.
;
:paintCountBytes	lda	#$01			;Max. Anzahl ungepackter Bytes auf
			sta	a9H			;Startwert setzen.

			PushW	r0			;Zeiger auf Grafikdaten retten.
			PushW	a6			;Anzahl zu packender Bytes retten.

			jsr	paintPosNxByte		;Zeiger auf nächstes Byte setzen.

::1			lda	a6L			;Weitere Bytes in Grafikspeicher
			ora	a6H			;zum packen vorhanden?
			beq	:exit			; => Nein, Ende...

			jsr	paintClearFlags		;8-Byte/Einzelbyte-Flags löschen.

			jsr	paintEqualBytes		;Gleiche Einzelbytes suchen.
			cmp	#4			;Mehr als vier gleiche Bytes?
			bcs	:exit			; => Ja, Abbruch. Ab hier ist das
							;packen über Anzahl gleicher Bytes
							;wieder effektiver !!!
			jsr	paintGet8Block		;Nach gleichen 8-Byte-Blocks suchen.
			cmp	#2			;Mehr als zwei 8-Byte-Blocks?
			bcs	:exit			; => Ja, Abbruch. Ab hier ist das
							;packen über Anzahl gleicher 8-Byte-
							;Blocks wieder effektiver !!!
			jsr	paintPosNxByte		;Zeiger auf nächstes Byte.

			inc	a9H			;Anzahl ungepackter Bytes +1.
			lda	a9H
			cmp	#63			;Max. 63 Bytes gefunden?
			bcc	:1			;Nein weiter...

			jsr	paintClearFlags		;8-Byte/Einzelbyte-Flags löschen.

::exit			PopW	a6			;Anzahl noch zu packender Bytes
			PopW	r0			;und Zeiger auf Grafikdaten wieder

			rts				;zurücksetzen.

;
; Zeiger auf ungepackte Daten und
; Anzahl noch zu packender Daten
; korrigieren.
;
:paintPosNxByte		inc	r0L			;Zeiger auf nächstes Byte der
			bne	:1			;Grafikdaten setzen.
			inc	r0H

::1			lda	a6L			;Anzahl noch zu packender Bytes
			bne	:2			;korrigieren.
			dec	a6H
::2			dec	a6L

			rts

;
; Variablen.
;
:paintFileName		b "Screen Capture",NULL

;
; Header für Geopaint-Datei.
;
:HdrGP_Dok		w paintFileName
			b $03,$15
			j
<MISSING_IMAGE_DATA>

:HdrGP_068		b $83
:HdrGP_069		b APPL_DATA
:HdrGP_070		b VLIR
:HdrGP_071		w $0000,$ffff,$0000
:HdrGP_077		b "Paint Image "		;Klasse.
:HdrGP_089		b "V1.1"			;Version.
:HdrGP_093		b $00				;NULL-Byte.
:HdrGP_094		b $00,$00,$00			;Reserviert.
:HdrGP_097		b NULL				;Autor.
:HdrGP_098		e HdrGP_097 +20			;Reserviert.
:HdrGP_117		b "geoPaint    "		;Application.
:HdrGP_129		b "V2.0"			;Version.
:HdrGP_133		b $00				;NULL-Byte.
:HdrGP_134		b $01				;Flag für "Farbe an".
:HdrGP_135		s 25				;Reserviert.
:HdrGP_160		b NULL
