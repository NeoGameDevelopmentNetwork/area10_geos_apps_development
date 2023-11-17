; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Dateien im Speicher sortieren.
;Sortieralgorythmus:
;        a5 = Anfang IconCache/Startwert.
;
;:loop1  a7 = 0
;        a8 = 0
;        a9 = MaxFiles -1
;
;        a1 = Anfang
;        a2 = Anfang +1
;        a3 = Anfang IconCache
;        a4 = Anfang IconCache +1
;
;        a1 > a2 ?
;        FALSE -> loop2
;
;        a2 <=> a1
;        a4 <=> a3
;        a7 = 1
;
;:loop2  a8 < a9 ?
;        TRUE -> loop1
;        a7 = 1 ?
;        TRUE -> loop1
;
:SORTFILES_INFO		= 80				;Ab 80 Dateien Hinweis anzeigen.

:xSORT_ALL_FILES	ldx	WM_WCODE
			ldy	WMODE_SORT,x		;Fenster sortieren?
			beq	:no_sort		; => Nein, Ende...

			lda	WM_DATA_MAXENTRY+0
if MAXENTRY16BIT = TRUE
			ldx	WM_DATA_MAXENTRY+1
			bne	:do_sort
endif
			cmp	#$02			;Meh als eine Datei?
			bcs	:do_sort		; => Ja, weiter...

::no_sort		ldx	#$ff			;Weniger als 2 Dateien, Ende...
			rts

;--- Zeiger auf Sortierroutine.
::do_sort		tya				;Vektor auf Sortier-Routine.
			asl				;In ":a0" ablegen da die restlichen
			tax				;":rX" Adressen evtl. durch ":BMult"
			lda	vecSortMode+0,x		;in ":SET_POS_CACHE" verändert
			sta	a0L			;werden können.
			lda	vecSortMode+1,x
			sta	a0H

;--- Adressen Eintrag im Icon-Cache.
			lda	#$00			;Zeiger auf aktuellen Verzeichnis-
			sta	r14L			;Eintrag im Cache berechnen.
if MAXENTRY16BIT = TRUE
			sta	r14H
endif
			jsr	SET_POS_CACHE
			MoveW	r13,a5

;--- Schleifenzähler initialisieren.
			lda	WM_DATA_MAXENTRY +0
			sec
			sbc	#$01			;Max. Anzahl Durchläufe -1.
			sta	a9L
if MAXENTRY16BIT = TRUE
			lda	WM_DATA_MAXENTRY +1
			sbc	#$00
			sta	a9H
endif

;--- Hinweis ausgeben.
			jsr	setSortInfo		;"Sortiere Verzeichnis..."

;--- BubbleSort.
:BSort			lda	#$00
			sta	a7L			;Werte zurücksetzen.
if MAXENTRY16BIT = TRUE
			sta	a7H
endif
			sta	a8L
if MAXENTRY16BIT = TRUE
			sta	a8H
endif
			LoadW	a1,BASE_DIR_DATA +0
			LoadW	a2,BASE_DIR_DATA +32
			MoveW	a5,a3			;Zeiger auf Icon-Cache.

;--- Sekundärschleife.
::1			lda	a3L			;Zeiger auf Nachbar-Eintrag.
			clc
			adc	#<64
			sta	a4L
			lda	a3H
			adc	#>64
			sta	a4H

			ldy	#$02
			lda	(a2L),y
			cmp	#$ff			;"Weitere Dateien"?
			beq	:3			; => Ja, nicht sortieren.

			bit	GD_ICON_CACHE		;Icon-Cache aktiv?
			bpl	:2			; => Nein, weiter...

			lda	GD_ICON_PRELOAD		;Icons vorab laden?
			bmi	:2			; => Ja, weiter...

			ldy	#$01			;Nur wenn Icons nicht vorab in den
			lda	#GD_MODE_NOICON		;Cache geladen werden dann Cache
			sta	(a1L),y			;Flag löschen -> Schneller.
			sta	(a2L),y			;Flag löschen -> Schneller.

::2			lda	a0L			;Einträge vergleichen.
			ldx	a0H
			jsr	CallRoutine
;			beq	:3			;Nur C-Flag auswerten.
			bcc	:3			; => Nicht sortieren.

			jsr	SwapEntry		;Eintrag tauschen.

;--- Optimierung:
;Für den nächsten Durchgang nur bis
;zum zuletzt getauschten Element
;sortieren, da danach nur größere
;Elemente folgen.
;;;			LoadB	a7L,1
			lda	a8L			;Aktuelle Datei als neues Ende
			clc				;für Primärschleife setzen.
			adc	#$01
			sta	a7L
if MAXENTRY16BIT = TRUE
			lda	a8H
			adc	#$00
			sta	a7H
endif

::3			MoveW	a2,a1			;Zeiger auf nächsten
			AddVBW	32,a2L			;Verzeichnis-Eintrag.

			MoveW	a4,a3			;Zeiger auf nächsten
							;IconCache-Eintrag.
			inc	a8L
if MAXENTRY16BIT = TRUE
			bne	:3a
			inc	a8H
endif
::3a
if MAXENTRY16BIT = TRUE
			lda	a8H
			cmp	a9H
			bne	:3b
endif
			lda	a8L
			cmp	a9L			;Alle Einträge geprüft?
::3b			bcc	:1			; => Nein, weiter...

;--- Optimierung:
;Für den nächsten Durchgang nur bis
;zum zuletzt getauschten Element
;sortieren, da danach nur größere
;Elemente folgen.
			lda	a7L			;Wurden Einträge getauscht?
			sta	a9L
if MAXENTRY16BIT = TRUE
			lda	a7H
			sta	a9H
			ora	a9L
endif
			beq	:done			; => Nein, Ende...
			jmp	BSort			; => Weitersortieren.

;--- Verzeichnisdaten in Cache kopieren.
::done			lda	#$00			;Zeiger auf aktuellen Verzeichnis-
			sta	r14L			;Eintrag im Cache berechnen.
if MAXENTRY16BIT = TRUE
			sta	r14H
endif
			jsr	SET_POS_CACHE

			LoadW	r0,BASE_DIR_DATA	;Daten für Verzeichnis-Cache
			MoveW	r14,r1			;setzen und aktualisieren.
			LoadW	r2,MAX_DIR_ENTRIES*32
			lda	GD_SYSDATA_BUF
			sta	r3L
			jsr	StashRAM

;--- Hinweis löschen.
			jsr	resetSortInfo		;Hinweistext löschen.

;--- Ende.
			ldx	WM_WCODE		;Flag setzen: Verzeichnis sortiert.
			lda	WMODE_SORT,x
			ora	#%10000000
			sta	WMODE_SORT,x

			ldx	#$00			;Dateien sortiert, Ende.
			rts

;*** Einträge vertauschen.
;    a1 = Zeiger auf aktuellen Verzeichnis-Eintrag im Speicher.
;    a2 = Zeiger auf nächsten Verzeichnis-Eintrag im Speicher.
;    a3 = Zeiger auf aktuellen Icon-Eintrag im Cache.
;    a4 = Zeiger auf nächsten Icon-Eintrag im Cache.
:SwapEntry		ldy	#$1f			;Einträge im Speicher tauschen.
::101			lda	(a1L),y
			tax
			lda	(a2L),y
			sta	(a1L),y
			txa
			sta	(a2L),y
			dey
			bpl	:101

;--- Swap IconEntry.
			bit	GD_ICON_CACHE		;Icon-Cache aktiv?
			bpl	:no_cache		; => Nein, weiter...

			lda	GD_ICON_PRELOAD		;Icons vorab laden?
			bpl	:no_cache		; => Nein, weiter...

			lda	GD_ICONDATA_BUF		;Zeiger auf 64K-Speicherbank.
			beq	:no_cache		; => Kein Icon-Cache.
			sta	r3L

			LoadW	r0,dataBufIcon		;Zeiger auf Zwischenspeicher.
			MoveW	a3,r1			;Zeiger auf Icon-Eintrag.
			LoadW	r2,64			;Größe Icon-Eintrag.
			jsr	FetchRAM		;Icon-Eintrag einlesen.

			MoveW	a4,r1			;Zeiger auf Vergleichs-Eintrag und
			jsr	SwapRAM			;mit Icon-Eintrag tauschen.

			MoveW	a3,r1			;Vergleichs-Eintrag zurück
			jsr	StashRAM		;in Cache speichern.

::no_cache		rts

;*** Einträge vergleichen.
;    a1 = Zeiger auf aktuellen Verzeichnis-Eintrag im Speicher.
;    a2 = Zeiger auf nächsten Verzeichnis-Eintrag im Speicher.

;*** Modus: Name.
:SortName		ldy	#$05
			lda	(a1L),y			;Zuerst nach Buchstabe a=A
			jsr	:convert_upper		;vergleichen.
			sta	:101 +1
			lda	(a2L),y
			jsr	:convert_upper
::101			cmp	#$ff
			bcc	:106
			beq	:102
			bcs	:109

::102			lda	(a2L),y			;Hier unterscheiden zwischen
			cmp	(a1L),y			;Groß- und Kleinbuchstaben.
			beq	:108
			bcc	:109
::106			sec				;Eintrag tauschen/sortieren.
			rts

::104			ldy	#$05			;Zeichen vergleichen.
::105			lda	(a2L),y
			cmp	(a1L),y
			bcc	:106

::107			bne	:109
::108			iny				;Weitervergleichen bis
			cpy	#$15			;alle 11 Zeichen geprüft.
			bne	:105
::109			clc
			rts

::convert_upper		cmp	#$61			;Kleinbuchstaben in
			bcc	:13			;Großbuchstaben wandeln.
			cmp	#$7e			;Sortieren nach Buchstabe a=A,...
			bcs	:13			;Kein Unterschied Groß/Klein.
::12			sec
			sbc	#$20
::13			rts

;*** Modus: Größe.
:SortSize		ldy	#$1f
			lda	(a2L),y
			cmp	(a1L),y
			bcs	:102
::101			sec				;Eintrag tauschen/sortieren.
			rts

::102			bne	:103
			dey
			lda	(a2L),y
			cmp	(a1L),y
			bcc	:101
			bne	:103
			jmp	SortName		;Größe gleich, nach Name sortieren.

::103			clc
			rts

;*** Modus: Datum/Aufwärts.
:SortDateUp		jsr	ConvertDate		;yy/mm/dd nach yyyy/mm/dd wandeln.

			ldx	#$00
::101			lda	dateFile_a2,x
			cmp	dateFile_a1,x
			bcs	:103
::102			sec				;Eintrag tauschen/sortieren.
			rts

::103			bne	:104
			inx
			cpx	#$06
			bcc	:101
			jmp	SortName		;Datum gleich, nach Name sortieren.

::104			clc
			rts

;*** Modus: Datum/Abwärts.
:SortDateDown		jsr	ConvertDate		;yy/mm/dd nach yyyy/mm/dd wandeln.

			ldx	#$00
::101			lda	dateFile_a2,x
			cmp	dateFile_a1,x
			bcs	:103
::102			clc
			rts

::103			bne	:104
			inx
			cpx	#$06
			bcc	:101
			jmp	SortName		;Datum gleich, nach Name sortieren.

::104			sec				;Eintrag tauschen/sortieren.
			rts

;*** Modus: BASIC-Dateityp.
:SortTyp		ldy	#$02
			lda	(a1L),y			;BASIC-Dateityp #1 einlesen.
			and	#FTYPE_MODES
			sta	:101 +1
			lda	(a2L),y			;BASIC-Dateityp #2 einlesen.
			and	#FTYPE_MODES
::101			cmp	#$ff			;BASIC-Dateityp vergleichen.
			beq	:103			; => Identisch, nach Name sortieren.
			bcs	:102			; => Größer, Ende...
			sec				;Eintrag tauschen/sortieren.
			rts

::103			jmp	SortName		;Typ gleich, nach Name sortieren.

::102			clc
			rts

;*** Modus: GEOS-Dateityp/Priorität.
;Anwendungen zuerst, danach Dokumente.
;Systemdateien am Ende.
:SortGEOS		ldy	#$02
			lda	(a1L),y			;CBM-Dateityp einlesen.
			and	#FTYPE_MODES
			cmp	#FTYPE_DIR		;Typ = Verzeichnis?
			bne	:11			; => Nein, weiter...

			lda	#$ff			;Verzeichnisse an Ende sortieren.
			bne	:12

::11			ldy	#$18
			lda	(a1L),y			;GEOS-Dateityp einlesen und
			jsr	:get_priority		;in GEOS-Priorität konvertieren.
::12			sta	:30 +1

			ldy	#$02
			lda	(a2L),y			;CBM-Dateityp einlesen.
			and	#FTYPE_MODES
			cmp	#FTYPE_DIR		;Typ = Verzeichnis?
			bne	:21			; => Nein, weiter...
			lda	#$ff			;Verzeichnisse an Ende sortieren.
			bne	:30
::21			ldy	#$18
			lda	(a2L),y			;GEOS-Dateityp einlesen und
			jsr	:get_priority		;in GEOS-Priorität konvertieren.

::30			cmp	#$ff
			beq	:31
			bcs	:32
			sec				;Eintrag tauschen/sortieren.
			rts

::31			jmp	SortName		;GEOS gleich, nach Name sortieren.

::32			clc
			rts

;--- GEOS-Datei nach Priorität sortieren.
::get_priority		cmp	#$10
			bcs	:exit
			tax
			lda	GEOS_Priority,x
::exit			rts

;*** Tabelle mit Zeigern auf die Sortier-Routinen.
:vecSortMode		w $0000				;Kein sortieren.
			w SortName
			w SortSize
			w SortDateUp
			w SortDateDown
			w SortTyp
			w SortGEOS

;*** Konvertierungstabelle GEOS-Dateityp.
:GEOS_Priority		b $03 ;$00 = nicht GEOS.
			b $04 ;$01 = BASIC-Programm.
			b $05 ;$02 = Assembler-Programm.
			b $07 ;$03 = Datenfile.
			b $0e ;$04 = Systemdatei.
			b $02 ;$05 = Hilfsprogramm.
			b $00 ;$06 = Anwendung.
			b $06 ;$07 = Dokument.
			b $08 ;$08 = Zeichensatz.
			b $09 ;$09 = Druckertreiber.
			b $0a ;$0a = Eingabetreiber.
			b $0c ;$0b = Laufwerkstreiber.
			b $0d ;$0c = Startprogramm.
			b $0f ;$0d = Temporär.
			b $01 ;$0e = Selbstausführend.
			b $0b ;$0f = Eingabetreiber 128.
			b $10 ;$10 = Unbekannt.
