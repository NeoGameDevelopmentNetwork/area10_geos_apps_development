; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Dateien im Speicher sortieren.
;Sortieralgorythmus:
;       a3 = Ende
;:loop1 a1 = Aktuell
;       a3 -> a2
;:loop3 a1 = a2? -> loop2
;       a0/compare
;           a2 < a1? ->swap
;       a2  -32
;       -> loop3
;:loop2 a1 +32
;       a1 = a3? -> loop1
;
;    a0   = Vektor auf Sortier-Routine.
;    a1   = Zeiger auf aktuellen Verzeichnis-Eintrag im Speicher.
;    a2   = Temporärer Zeiger auf letzten Verzeichnis-Eintrag im Speicher.
;    a3   = Zeiger auf letzten Verzeichnis-Eintrag im Speicher.
;
;    r9   = Anzahl Dateien -1.
;
;    r10  = Zeiger auf aktuellen Icon-Eintrag im Cache.
;    r12  = Temporärer Zeiger auf letzten Icon-Eintrag im Cache.
;    r14  = Zeiger auf letzten Icon-Eintrag im Cache.
;
:SORTFILES_INFO		= 80				;Ab 80 Dateien Hinweis anzeigen.

:xSORT_ALL_FILES	ldx	WM_WCODE
			ldy	WMODE_SORT,x
			beq	:no_sort

			lda	WM_DATA_MAXENTRY+0
if MAXENTRY16BIT = TRUE
			ldx	WM_DATA_MAXENTRY+1
			bne	:do_sort
endif
			cmp	#$02
			bcs	:do_sort

::no_sort		ldx	#$ff			;Weniger als 2 Dateien, Ende...
			rts

::do_sort		sec				;Zeiger auf letzten Eintrag
			sbc	#$01			;berechnen.
			sta	r9L
			bcs	:1
			dex
::1			stx	r9H

			tya				;Vektor auf Sortier-Routine.
			asl				;In ":a0" ablegen da die restlichen
			tax				;":rX" Adressen evtl. durch ":BMult"
			lda	vecSortMode+0,x		;in ":SET_POS_CACHE" verändert
			sta	a0L			;werden können.
			lda	vecSortMode+1,x
			sta	a0H

;--- Adressen Verzeichnis im Speicher.
			MoveW	r9L,a3L
if MAXENTRY16BIT = TRUE
			MoveW	r9H,a3H
endif
			ldx	#a3L			;Zeiger auf letzten Verzeichnis-
			jsr	SET_POS_RAM		;Eintrag im Speicher berechnen.

			lda	#$00
			sta	a1L
if MAXENTRY16BIT = TRUE
			sta	a1H
endif
			ldx	#a1L			;Zeiger auf ersten Verzeichnis-
			jsr	SET_POS_RAM		;Eintrag im Speicher berechnen.

;--- Adressen Erster Eintrag im Cache.
			lda	#$00
			sta	r14L
if MAXENTRY16BIT = TRUE
			sta	r14H
endif
			jsr	SET_POS_CACHE		;Eintrag im Cache berechnen.
			MoveW	r13,r10			;Icon-Daten.

;--- Adressen Letzter Eintrag im Cache.
			MoveB	r9L,r14L		;Zeiger auf letzten Verzeichnis-
							;Eintrag im Cache berechnen.
if MAXENTRY16BIT = TRUE
			MoveB	r9H,r14H
endif
			jsr	SET_POS_CACHE
			MoveW	r13,r14			;Icon-Daten.

;--- Hinweis ausgeben.
			jsr	setSortInfo		;"Sortiere Verzeichnis..."

;--- Dateien sortieren.
::do_compare		MoveW	a3,a2			;Temporärer Zähler auf letzten
			MoveW	r14,r12			;Verzeichnis-Eintrag für Vergleich.

::next_entry		CmpW	a2,a1			;Aktueller Zähler = temp. Zähler?
			beq	:do_next		; => Ja, weiter...

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

;--- Sekundärschleife: Nächster Eintrag.
::3			SubVW	32,a2			;Temporären Zähler Speicher.
			SubVW	64,r12			;Temporären Zähler Cache/Icon.

			jmp	:next_entry		;Weiter mit nächstem Vergleich.

;--- Primärschleife: Nächster Eintrag.
::do_next		AddVBW	32,a1			;Nächster Eintrag Speicher.
			AddVBW	64,r10			;Nächster Eintrag Cache/Icon.

			CmpW	a1,a3			;Ende erreicht?
			beq	:exit			; => Ja, Ende...

			jmp	:do_compare		; => Nein, weiter...

;--- Verzeichnisdaten in Cache kopieren.
::exit			lda	#$00			;Zeiger auf aktuellen Verzeichnis-
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
;    a1  = Zeiger auf aktuellen Verzeichnis-Eintrag im Speicher.
;    a2  = Temporärer Zeiger auf letzten Verzeichnis-Eintrag im Speicher.
;    r10 = Zeiger auf aktuellen Icon-Eintrag im Cache.
;    r12 = Temporärer Zeiger auf letzten Icon-Eintrag im Cache.
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
			MoveW	r10,r1			;Zeiger auf Icon-Eintrag.
			LoadW	r2,64			;Größe Icon-Eintrag.
			jsr	FetchRAM		;Icon-Eintrag einlesen.

			MoveW	r12,r1			;Zeiger auf Vergleichs-Eintrag und
			jsr	SwapRAM			;mit Icon-Eintrag tauschen.

			MoveW	r10,r1			;Vergleichs-Eintrag zurück
			jsr	StashRAM		;in Cache speichern.

::no_cache		rts

;*** Einträge vergleichen.
;    a1 = Zeiger auf aktuellen Verzeichnis-Eintrag im Speicher.
;    a2 = Temporärer Zeiger auf letzten Verzeichnis-Eintrag im Speicher.

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
			bcc	:103
			jmp	SwapEntry		;Eintrag tauschen/sortieren.
::103			rts

::104			ldy	#$05			;Zeichen vergleichen.
::105			lda	(a2L),y
			cmp	(a1L),y
			bcs	:107
::106			jmp	SwapEntry		;Eintrag tauschen/sortieren.

::107			bne	:109
::108			iny				;Weitervergleichen bis
			cpy	#$15			;alle 11 Zeichen geprüft.
			bne	:105
::109			rts

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
::101			jmp	SwapEntry		;Eintrag tauschen/sortieren.
::102			bne	:103
			dey
			lda	(a2L),y
			cmp	(a1L),y
			bcc	:101
			bne	:103
			jmp	SortName		;Größe gleich, nach Name sortieren.
::103			rts

;*** Modus: Datum/Aufwärts.
:SortDateUp		jsr	ConvertDate		;yy/mm/dd nach yyyy/mm/dd wandeln.

			ldx	#$00
::101			lda	dateFile_a2,x
			cmp	dateFile_a1,x
			bcs	:103
::102			jmp	SwapEntry		;Eintrag tauschen/sortieren.
::103			bne	:104
			inx
			cpx	#$06
			bcc	:101
			jmp	SortName		;Datum gleich, nach Name sortieren.
::104			rts

;*** Modus: Datum/Abwärts.
:SortDateDown		jsr	ConvertDate		;yy/mm/dd nach yyyy/mm/dd wandeln.

			ldx	#$00
::101			lda	dateFile_a2,x
			cmp	dateFile_a1,x
			bcs	:103
::102			rts
::103			bne	:104
			inx
			cpx	#$06
			bcc	:101
			jmp	SortName		;Datum gleich, nach Name sortieren.
::104			jmp	SwapEntry		;Eintrag tauschen/sortieren.

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
			jmp	SwapEntry		;Eintrag tauschen/sortieren.
::103			jmp	SortName		;Typ gleich, nach Name sortieren.
::102			rts

;*** Modus: GEOS-Dateityp.
if FALSE
;--- V1: Nur nach GEOS-Dateityp sortieren.
:SortGEOS		ldy	#$18
			lda	(a2L),y
			cmp	(a1L),y
			bcs	:101
			jmp	SwapEntry		;Eintrag tauschen/sortieren.
::101			rts
endif

;--- V2: Nach GEOS/Priorität sortieren.
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
			bcs	:exit
			jmp	SwapEntry		;Eintrag tauschen/sortieren.
::31			jmp	SortName		;GEOS gleich, nach Name sortieren.

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
