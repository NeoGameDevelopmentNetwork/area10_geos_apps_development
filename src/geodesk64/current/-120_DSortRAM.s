; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Tabelle ausgeben.
;Wird über ":fileListData" definiert.
; :a0  = Zeiger auf Dateien Quelle/Ziel.
; :a1  = Zeiger auf Auswahl Quelle/Ziel.
; :a2  = Zeiger auf x-Koordinate.
;
;Allgemeine Variablen.
; :a3L = reserviert für y-Koordinate.
; :a3H = $00 = Source, $01 = Target.
;
;Abhängig von Quelle/Ziel.
; :a4L = Max. Dateien Quelle/Ziel.
; :a5L = Zähler für Dateien in Tabelle.
; :a5H = Berechnung für Zeiger/Eintrag.
; :a6L = Aktueller Eintrag.
; :a7L = Ausgabe von Eintrag xyz.
; :a8L = Kopie Ausgabe von Eintrag xyz.
:SB_MaxFiles		= 12  -SORTINFO_MODE		;Anzahl Dateien im Fenster.
:SB_YPosMin		= $30 +SORTINFO_MODE*$08	;Y-Koordinate oben für Dateifenster.
:FListYMin		= SB_YPosMin +6			;Y-Koordinate erste Textzeile.
:SB_Height		= SB_MaxFiles*8			;Höhe Scrollbar.
:ShowFileList		LoadB	a3L,FListYMin		;Zeiger auf erste Zeile.

			ClrB	a5L			;Zähler für Anzahl Einträge auf 0.

			ldx	a3H
			lda	SortS_Top,x		;Nr. der ersten Datei
			sta	a6L			;in Zwischenspeicher.
			lda	SortS_Max,x		;Max. Anzahl Dateien in Tabelle
			sta	a4L			;in Zwischenspeicher kopieren.

;--- Dateieinträge ausgeben.
::loop			ldy	a6L			;Tabellenende erreicht ?
			cpy	a4L
			bcs	:clrTab			; => Ja, Rest des Fensters löschen.
			lda	(a0L),y			;Nr. Dateieintrag einlesen.
			sta	a7L
			jsr	View1Entry8		;Dateieintrag ausgeben.

			AddVB	8,a3L			;Zeiger auf nächste Zeile.

			inc	a5L			;Zähler Anzahl Dateien/Tabelle +1.

			inc	a6L			;Tabellenende erreicht ?
			beq	:end			; => Ja, Ende...

			CmpBI	a5L,SB_MaxFiles		;Tabelle voll ?
			bne	:loop			; => Nein, weiter...

::end			rts

;--- Unteren Bereich des Ausgabefensters löschen.
::clrTab		lda	#$00			;Füllmuster setzen.
			jsr	SetPattern

			lda	a3L			;Y-oben und Y-unten setzen.
			sec
			sbc	#6
			sta	r2L
			LoadB	r2H,SB_YPosMin+SB_Height -1
			jsr	DefXPos			;X-links und X-rechts setzen.

			jmp	Rectangle		;Bereich löschen.

;*** Eintrag ausgeben.
;Übergabe: a7L = Nummer des Eintrags in RAM.
;          a1  = Tabelle Dateiauswahl.
;          a2  = X-Position.
;          a3L = Y-Position.
:View1Entry8		ldy	a7L			;Nr. des Eintrags speichern.
			ldx	#$00
			lda	(a1L),y			;Datei ausgewählt?
			beq	:1			; => Nein, weiter...
			dex
::1			stx	a8H			;Standard/Reverse Darstellung.

			jsr	GetFilePos8		;Verzeichniseintrag suchen.
			jmp	PrintEntry		;Dateieintrag ausgeben.

;*** Zeiger auf Verzeichniseintrag berechnen.
;Übergabe: a7L = Nummer des Eintrags im RAM.
;Rückgabe: a7  = Zeiger auf Eintrag.
:GetFilePos8		ClrB	a7H			;High-Byte löschen.

			ldx	#a7L			;Dateinummer x 32.
			ldy	#$05
			jsr	DShiftLeft

			AddVW	DIRSEK_SOURCE,a7	;Adresse Dateieintrag berechnen.

			ldy	#$02
::1			lda	(a7L),y
			sta	dirEntryBuf -2,y
			iny
			cpy	#$20
			bcc	:1

			rts

;*** Datei aus Quell-/Ziel-Tabelle auswählen.
;Übergabe: A/X = Zeiger auf Tabelle mit Mausgrenzen.
;          a0  = Zeiger auf Dateien.
;          a1  = Zeiger auf Auswahl.
;          a3H = Quell/Ziel.
:Slct1File		sta	r0L			;Mausgrenzen festlegen.
			stx	r0H
			jsr	InitRam

;--- Datei ausgewählt?
::testFSlct		ldx	a3H			;Mit Maus angelickten Eintrag
			lda	mouseYPos		;berechnen.
			sec
			sbc	#SB_YPosMin
			lsr
			lsr
			lsr
			sta	a8H
			clc
			adc	SortS_Top,x		;Datei innerhalb Liste ?
			cmp	SortS_Max,x
			bcc	:testSlctMode		; => Ja, weiter...

::exit			LoadW	r0,noMseBorder		;Mausgrenzen löschen, da
			jmp	InitRam			;Mausklick ungültig.

;--- Datei aus-/abwählen?
::testSlctMode		tay				;Position innerhalb Verzeichnis
			lda	(a0L),y			;berechnen.
			sta	a7L
			tay
			lda	(a1L),y			;Datei bereits ausgewählt ?
			beq	:select			; => Nein, weiter...

;--- Datei abwählen.
::unselect		sta	a5H			;Eintrag merken...

			ldx	a3H			;Anzahl markierter Einträge
			dec	SortS_Slct,x		;korrigieren.

			lda	#$00			;Aktuelle Auswahl zurücksetzen.
			sta	(a1L),y
			tay

;--- Reihenfolge markierter Dateien korrigieren.
::1			lda	(a1L),y			;Auswahlnummer einlesen.
			cmp	a5H			;Auswahlnummer kleiner Auswahl?
			bcc	:2			; => Ja, weiter...

			lda	(a1L),y			;Auswahlnummer korrigieren.
			sbc	#$01
			sta	(a1L),y

::2			iny				;Alle Auswahlnummern korrigiert?
			bne	:1			; => Nein, weiter...
			jmp	:prntSlctFile		; => Ja, Eintrag ausgeben.

;--- Datei auswählen.
::select		ldx	a3H
			lda	SortS_Slct,x
			cmp	#$ff			;Bereits 255 Dateien angewählt ?
			beq	:exit			; => Ja, Ende...
			inc	SortS_Slct,x		;Datei als "ausgewählt" markieren.
			lda	SortS_Slct,x
			sta	(a1L),y

;--- Dateieintrag ausgeben.
::prntSlctFile		lda	a8H			;Ausgabezeile für Eintrag
			asl				;berechnen.
			asl
			asl
			clc
			adc	#FListYMin
			sta	a3L
			jsr	View1Entry8		;Dateieintrag ausgeben.

;--- Auf Dauerfunktion testen.
			lda	mouseYPos		;Aktuelle Y-Position des
			lsr				;Mauszeigers in CARDs umwandeln.
			lsr
			lsr
			sta	r0L

;--- CBM-Taste auswerten.
::testCBMkey		jsr	testCBMkey		;Dauerfunktion?
			beq	:testMouse		; => Ja, weiter...
			jmp	:exit			;Ende.

;--- Dauerfunktion?
::testMouse		lda	mouseYPos		;Mausposition auswerten.
			lsr
			lsr
			lsr
			cmp	r0L			;Maus noch auf gleichem Eintrag?
			beq	:testCBMkey		; => Ja, weiter...
			jmp	:testFSlct		;Weiteren Eintrag markieren.

;*** Quell-Dateien übernehmen.
:TakeSource		ldx	SortT_Max		;Zielverzeichnis voll ?
			cpx	#$ff
			beq	:exit			; => Ja, Abbruch...
			lda	SortS_Slct		;Source-Dateien gewählt ?
			bne	:add2Target		; => Nein, Abbruch.
::exit			rts				;Nichts zum übernehmen...

;--- Dateien übernehmen.
::add2Target		LoadB	a5H,$01			;Erster ausgewählter Eintrag.

::loop			ldy	#$00
::findEntry		lda	FSLCT_SOURCE,y		;Eintrag aus Tabelle einlesen.
			cmp	a5H			;Ausgewählter Eintrag gefunden?
			bne	:skipEntry		; => Nein, weiter...

			ldx	SortT_Max		;Nr. Eintrages in Tabelle kopieren.
			tya
			sta	FLIST_TARGET,x
			cpx	#$ff			;Tabelle voll ?
			beq	:done			; => Ja, Ende...

			inx
			inc	SortT_Max		;Dateien im Zielverzeichnis  +1.
			dec	SortS_Max		;Dateien im Quellverzeichnis -1.
			beq	:done			;Weitere Dateien ? Nein, Ende...
			jmp	:nextEntry

::skipEntry		iny				;Zeiger auf nächsten Eintrag.
			bne	:findEntry		;Ende erreicht ? Nein, weiter...

::nextEntry		CmpB	a5H,SortS_Slct		;Alle Dateien übernommen ?
			beq	:done			; => Ja, Ende...
			inc	a5H			;Zeiger auf nächste Datei.
			jmp	:loop			; => Weiter...

;--- Quelldateien aus Tabelle entfernen.
::done			ldy	#$00			;Markierte Dateien aus
			ldx	#$00			;Tabelle entfernen.
::remove		stx	:rmNext +1
			ldx	FLIST_SOURCE,y
			lda	FSLCT_SOURCE,x
			bne	:rmNext
			ldx	:rmNext +1
			lda	FLIST_SOURCE,y
			sta	FLIST_SOURCE,x
			inc	:rmNext +1
::rmNext		ldx	#$ff
			iny
			bne	:remove

;--- Dateiliste neu ausgeben.
;Dabei wird dann dann auch die Auswahl von Quelle und Ziel gelöscht.
::allDone		jsr	S_ResetBit
			jsr	T_ResetBit
			jsr	S_SetPos		;Quell-Tabelle aktualisieren.
			jsr	T_End			;In Ziel-Tabelle zum Ende gehen.
			jmp	PrintFiles		;Dateianzahl aktualisieren.

;*** Ziel-Dateien übernehmen.
:TakeTarget		lda	SortT_Slct		;Dateien im Zielverzeichnis ?
			bne	:add2Source		; => Ja, weiter...
::exit			rts				;Nichts zum sortieren.

::add2Source		lda	#>FSLCT_SOURCE		;Auswahl Quelldateien aufheben.
			jsr	ClearMem

			lda	SortS_Max		;Dateien in Quelle ?
			beq	:21			; => Nein, weiter...

;--- Vorhandene Dateien in Quelle sichern.
			ldy	#$00
::11			lda	FLIST_SOURCE,y		;Eintrag vorhanden?
			bne	:12			; => Ja, weiter...
			cpy	#$00			;Ende erreicht?
			bne	:21			; => Ja, weiter...
::12			tax
			lda	#$ff			;Eintrag in Zwischenspeicher
			sta	FSLCT_SOURCE,x		;als "vorhanden" markieren.
			iny				;Alle Dateien überprüft?
			bne	:11			; => Nein, weiter...

;--- Markierte Dateien aus Ziel übernehmen.
::21			ldy	#$00
::22			lda	FSLCT_TARGET,y		;Eintrag markiert?
			beq	:23			; => Nein, weiter...
			lda	#$ff			;Eintrag in Zwischenspeicher
			sta	FSLCT_SOURCE,y		;als "vorhanden" markieren.
			dec	SortT_Max		;Zähler für Ziel korrigieren / -1.
			inc	SortS_Max		;Zähler für Quelle korrigieren / +1.
::23			iny				;Alle Dateien überprüft?
			bne	:22			; => Nein, weiter...

;--- Neue Tabelle für Quelle erzeugen.
;Die Liste wird dabei wieder in der
;ursprünglichen Reihenfolge sortiert.
			lda	#>FLIST_SOURCE		;Tabelle Quelldateien löschen.
			jsr	ClearMem

			ldy	#$00
			ldx	#$00
::31			lda	FSLCT_SOURCE,y		;Datei in Quelle vorhanden?
			beq	:32			; => Nein, weiter...
			tya
			sta	FLIST_SOURCE,x		;Eintrag in Tabelle übernehmen.
			inx
::32			iny				;Alle Dateien überprüft?
			bne	:31			; => Nein, weiter...

;--- Quelldateien aus Zieltabelle entfernen.
;Die Zieltabelle wird dabei komprimiert.
			ldy	#$00
			ldx	#$00			;Markierte Dateien aus
::remove		stx	:rmNext +1		;Tabelle entfernen.
			ldx	FLIST_TARGET,y
			lda	FSLCT_TARGET,x
			bne	:rmNext
			ldx	:rmNext +1
			lda	FLIST_TARGET,y
			sta	FLIST_TARGET,x
			inc	:rmNext +1
::rmNext		ldx	#$ff
			iny
			bne	:remove

;--- Dateiliste neu ausgeben.
;Dabei wird dann dann auch die Auswahl von Quelle und Ziel gelöscht.
::allDone		jsr	S_ResetBit
			jsr	T_ResetBit
			jsr	S_SetPos		;Quell-Tabelle aktualisieren.
			jsr	T_SetPos		;Ziel-Tabelle aktualisieren.
			jmp	PrintFiles		;Dateianzahl aktualisieren.

;*** Speicherbereich löschen.
;Übergabe: AKKU = High-Byte Zielbereich.
;Hinweis:
;Wird genutzt um FLIST/FSLCT_SOURCE/TARGET zu löschen.
;Die Tabellen beginnen immer bei $xx00!
:ClearMem		sta	r0H
			ClrB	r0L
			tay
::1			sta	(r0L),y
			iny
			bne	:1
			rts

;*** Zum Anfang der Quell-Tabelle.
:S_Top			lda	#$00
			sta	SortS_Top
			beq	S_SetPos

;*** In der Quell-Tabelle eine Seite zurück.
:S_End			jsr	S_TestEndPos
			jmp	S_SetPos

;*** Zum Anfang der Ziel-Tabelle.
:T_Top			lda	#$00
			sta	SortT_Top
			beq	T_SetPos

;*** In der Ziel-Tabelle eine Seite zurück.
:T_End			jsr	T_TestEndPos
			jmp	T_SetPos

;*** Neue Position Quell-Tabelle setzen.
:S_SetPos		ldy	#$00
			b $2c

;*** Neue Position Ziel-Tabelle setzen.
:T_SetPos		ldy	#$06
			jsr	SetWinData
			jsr	TestNewPos
			jsr	InitBalkenData
			jmp	ShowFileList

;*** Aktuelle Position testen.
;Übergabe: a3H = Quelle/Ziel = 0/1.
:TestNewPos		ldx	a3H

			lda	SortS_Top,x		;Ganze Seite anzeigen möglich?
			clc
			adc	#SB_MaxFiles
			bcs	TestEndPos		; => Nein, zum Ende...

			cmp	SortS_Max,x		;Ende ausserhalb max. Dateien?
			bcs	TestEndPos		; => Ja, zum Ende...
			rts

;*** Auf gültige End-Position testen.
:S_TestEndPos		ldx	#$00
			b $2c
:T_TestEndPos		ldx	#$01

;*** Auf gültige End-Position testen.
;Übergabe: X = Quelle/Ziel = 0/1.
:TestEndPos		lda	SortS_Max,x		;Zum Ende springen.
			sec
			sbc	#SB_MaxFiles		;Genügend Dateien vorhanden?
			bcs	:1			; => Ja, Ende...

			lda	#$00			;Zum Anfang springen.
::1			sta	SortS_Top,x		;Neue Position setzen.
			rts

;*** In der Quell-Tabelle eine Seite vorwärts.
:S_NextPage		lda	SortS_Top		;Nächste Seite möglich?
			clc
			adc	#SB_MaxFiles*2
			bcs	:move2End		; => Nein, zum Ende springen.
			cmp	SortS_Max
			bcc	:move2Page		; => Ja, weiter...
::move2End		jmp	S_End			;Zum Ende springen.

::move2Page		jsr	S_SetNextPage		;Neue Position speichern und
			jmp	S_SetPos		;Dateiliste aktualisieren.

;*** In der Quell-Tabelle eine Seite zurück.
:S_LastPage		lda	SortS_Top		;Bereits ganz am Anfang?
			beq	:exit			; => Ja, Ende...

			jsr	S_SetLastPage		;Vorherige Seite möglich?
			bcs	:move2Page		; => Ja, weiter...
::move2Top		jmp	S_Top			;Zum Anfang springen.
::move2Page		jmp	S_SetPos		;Dateiliste aktualisieren.

::exit			rts

;*** In der Ziel-Tabelle eine Seite vorwärts.
:T_NextPage		lda	SortT_Top		;Nächste Seite möglich?
			clc
			adc	#SB_MaxFiles*2
			bcs	:move2End		; => Nein, zum Ende springen.
			cmp	SortT_Max
			bcc	:move2Page		; => Ja, weiter...
::move2End		jmp	T_End			;Zum Ende springen.

::move2Page		jsr	T_SetNextPage		;Neue Position speichern und
			jmp	T_SetPos		;Dateiliste aktualisieren.

;*** In der Ziel-Tabelle eine Seite zurück.
:T_LastPage		lda	SortT_Top		;Bereits ganz am Anfang?
			beq	:exit			; => Ja, Ende...

			jsr	T_SetLastPage		;Vorherige Seite möglich?
			bcs	:move2Page		; => Ja, weiter...
::move2Top		jmp	T_Top			;Zum Anfang springen.
::move2Page		jmp	T_SetPos		;Dateiliste aktualisieren.

::exit			rts

;*** Zurück zur letzte Seite.
:S_SetLastPage		ldx	#$00
			b $2c
:T_SetLastPage		ldx	#$01

			lda	SortS_Top,x
			sec
			sbc	#SB_MaxFiles
			sta	SortS_Top,x

			rts

;*** Weiter zur nächsten Seite.
:S_SetNextPage		ldx	#$00
			b $2c
:T_SetNextPage		ldx	#$01

			lda	SortS_Top,x
			clc
			adc	#SB_MaxFiles
			sta	SortS_Top,x

			rts

;*** Mausklick auf Quell-Anzeigebalken.
:S_MoveBar		lda	SortS_Max
			cmp	#SB_MaxFiles		;Anzeigebalken vorhanden?
			bcc	:exit			; => Nein, Ende...

::move			ldy	#$00			;Fenstergrenzen setzen.
			jsr	SetWinData

			jsr	InitBalkenData		;Anzeigebalken initialisieren.

			jsr	IsMseOnPos		;Position der Maus ermitteln.
			cmp	#1			;Oberhalb des Anzeigebalkens ?
			beq	:lastPage		; => Ja, eine Seite zurück.
			cmp	#2			;Auf dem Anzeigebalkens ?
			beq	:move2Page		; => Ja, Balken verschieben.
			cmp	#3			;Unterhalb des Anzeigebalkens ?
			beq	:nextPage		; => Ja, eine Seite vorwärts.
::exit			rts

::lastPage		jmp	S_LastPage
::move2Page		jmp	MoveToPos
::nextPage		jmp	S_NextPage

;*** Mausklick auf Quell-Anzeigebalken.
:T_MoveBar		lda	SortT_Max
			cmp	#SB_MaxFiles		;Anzeigebalken vorhanden?
			bcc	:exit			; => Nein, Ende...

::move			ldy	#$06			;Fenstergrenzen setzen.
			jsr	SetWinData

			jsr	InitBalkenData		;Anzeigebalken initialisieren.

			jsr	IsMseOnPos		;Position der Maus ermitteln.
			cmp	#1			;Oberhalb des Anzeigebalkens ?
			beq	:lastPage		; => Ja, eine Seite zurück.
			cmp	#2			;Auf dem Anzeigebalkens ?
			beq	:move2Page		; => Ja, Balken verschieben.
			cmp	#3			;Unterhalb des Anzeigebalkens ?
			beq	:nextPage		; => Ja, eine Seite vorwärts.
::exit			rts

::lastPage		jmp	T_LastPage
::move2Page		jmp	MoveToPos
::nextPage		jmp	T_NextPage

;*** Balken verschieben.
;Hinweis:
;Das RegisterMenü erlaubt nicht die
;Auswertung einer Dauerfunktion über
;die Maustaste, da nach dem anklicken
;einer Option gewartet wird, bis die
;Maustaste losgelassen wird.
;Daher wird hier der Scrollbalken an
;die Mausposition gekoppelt bis die
;Maustaste erneut gedrückt wird.
:MoveToPos		jsr	StopMouseMove		;Mausbewegung einschränken.

::waitMouse		jsr	UpdateMouse		;Mausdaten aktualisieren.
			ldx	mouseData		;Maustaste noch gedrückt ?
			bpl	:exitMouse		;Nein, neue Position anzeigen.
			lda	inputData		;Mausbewegung einlesen.
			bne	:moveMouse		;Mausbewegung auswerten.
			beq	:waitMouse		;Keine Bewegung, Schleife...

::exitMouse		jsr	WM_WAIT_NOMSEKEY	;Warten bis keine M-Taste gedrückt.

			LoadW	r0,noMseBorder		;Mausgrenzen löschen.
			jsr	InitRam

			lda	a3H			;Quelle oder Ziel?
			bne	:move2Target		; => Ziel...
::move2Source		jmp	S_SetPos		;Position Quelle setzen.
::move2Target		jmp	T_SetPos		;Position Ziel setzen.

::moveMouse		cmp	#$02			;Maus nach oben ?
			beq	:moveUp			;Ja, auswerten.
			cmp	#$06			;Maus nach unten ?
			beq	:moveDown		;Ja, auswerten.
			jmp	:waitMouse		;Keine Bewegung, Schleife...

::moveUp		jsr	LastFile_a		;Eine Datei zurück.
			bcs	:waitMouse		; => Geht nicht, ignorieren.

;			ldx	a3H			;Zeiger auf vorherige Datei.
			dec	SortS_Top,x
			jmp	:move2Pos		;Neue Position anzeigen.

::moveDown		jsr	NextFile_a		;Eine Datei vorwärts.
			bcs	:waitMouse		; => Geht nicht, ignorieren.

;			ldx	a3H			;Zeiger auf nächste Datei.
			inc	SortS_Top,x

::move2Pos		lda	SortS_Top,x		;Tabellenposition einlesen.
			ldy	#$00			;High-Byte Position löschen.
			jsr	SetNewPos16		;Anzeigebalken setzen und
			jsr	SetRelMouse		;Maus entsprechend verschieben.
			jmp	:waitMouse		;Maus weiter auswerten.

;*** Eine Datei vorwärts.
:NextFile		jsr	NextFile_a
			bcc	NextFile_b
			rts				;Abbruch...

:NextFile_a		ldx	a3H
			lda	SortS_Top,x
			clc
			adc	#SB_MaxFiles
			bcs	:1
			cmp	SortS_Max,x		;Tabellen-Ende erreicht ?
::1			rts

:NextFile_b		php
			sei
			ldx	a3H
			lda	GrafxDatLo,x
			sta	r0L
			lda	GrafxDatHi,x
			sta	r0H

			ldx	#SB_MaxFiles -1
::1			lda	r0L			;Zeiger auf Grafik-Daten berechnen.
			clc
			sta	r1L
			adc	#<SCRN_XBYTES
			sta	r0L
			lda	r0H
			sta	r1H
			adc	#>SCRN_XBYTES
			sta	r0H
			ldy	#$00			;12 Grafikzeilen a 144 Byte (18 * 8)
::2			lda	(r0L),y			;verschieben.
			sta	(r1L),y
			iny
			cpy	#144
			bne	:2
			dex
			bne	:1
			plp

			ldx	a3H
			inc	SortS_Top,x		;Tabellenzeiger korrigieren.

			lda	SortS_Top,x		;Nächsten Dateinamen ausgeben.
			pha
			clc
			adc	#SB_MaxFiles -1
			tay
			lda	(a0L),y
			sta	a7L
			lda	#FListYMin +SB_Height -$08
			sta	a3L
			jsr	View1Entry8

			pla
			ldy	#$00			;High-Byte löschen.
			jsr	SetNewPos16		;Scrollbalken aktualisieren.

			jsr	TestMouse		;Dauerfunktion?

			jmp	NextFile		; => Weiterscrollen.

;*** Eine Datei zurück.
:LastFile		jsr	LastFile_a
			bcc	LastFile_b
			rts				;Abbruch.

:LastFile_a		ldx	a3H
			lda	SortS_Top,x		;Tabellenzeiger korrigieren.
			bne	:1
			sec
			rts
::1			clc
			rts

:LastFile_b		php
			sei
			ldx	a3H
			clc
			lda	GrafxDatLo,x
			adc	#<(SB_MaxFiles -1)*SCRN_XBYTES
			sta	r0L
			lda	GrafxDatHi,x
			adc	#>(SB_MaxFiles -1)*SCRN_XBYTES
			sta	r0H

			ldx	#SB_MaxFiles -1
::1			lda	r0L			;Zeiger auf Grafik-Daten berechnen.
			sec
			sta	r1L
			sbc	#<SCRN_XBYTES
			sta	r0L
			lda	r0H
			sta	r1H
			sbc	#>SCRN_XBYTES
			sta	r0H
			ldy	#$00			;12 Grafikzeilen a 144 Byte (18 * 8)
::2			lda	(r0L),y			;verschieben.
			sta	(r1L),y
			iny
			cpy	#144
			bne	:2
			dex
			bne	:1
			plp

			ldx	a3H
			dec	SortS_Top,x		;Tabellenzeiger korrigieren.

			lda	SortS_Top,x		;Nächsten Dateinamen ausgeben.
			pha
			tay
			lda	(a0L),y
			sta	a7L
			lda	#FListYMin
			sta	a3L
			jsr	View1Entry8

			pla
			ldy	#$00			;High-Byte löschen.
			jsr	SetNewPos16		;Scrollbalken aktualisieren.

			jsr	TestMouse		;Dauerfunktion?

			jmp	LastFile		; => Ja, Weiterscrollen.

;*** Alle Dateien im Quell-Tabelle markieren.
:S_SetAll		lda	SortS_Max
			bne	:1
			rts

::1			ldx	#$00
			stx	r0L
			ldy	SortS_Slct
			iny
			sty	r0H

::2			lda	FLIST_SOURCE,x
			tax
			lda	FSLCT_SOURCE,x
			bne	:3
			lda	r0H
			sta	FSLCT_SOURCE,x
			inc	r0H
::3			inc	r0L
			ldx	r0L
			cpx	SortS_Max
			bne	:2

			lda	SortS_Max
			sta	SortS_Slct
			jmp	S_SetPos

;*** Alle Dateien im Ziel-Tabelle markieren.
:T_SetAll		lda	SortT_Max
			bne	:1
			rts

::1			ldx	#$00
			stx	r0L
			ldy	SortT_Slct
			iny
			sty	r0H

::2			lda	FLIST_TARGET,x
			tax
			lda	FSLCT_TARGET,x
			bne	:3
			lda	r0H
			sta	FSLCT_TARGET,x
			inc	r0H
::3			inc	r0L
			ldx	r0L
			cpx	SortT_Max
			bne	:2

			lda	SortT_Max
			sta	SortT_Slct
			jmp	T_SetPos

;*** Seite im Quell-Tabelle markieren.
:S_SetPage_a		ldx	SortS_Top
			stx	r0L
			txa
			clc
			adc	#SB_MaxFiles
			sta	r1L
			ldy	SortS_Slct
			iny
			sty	r0H

::2			lda	FLIST_SOURCE,x
			tax
			lda	FSLCT_SOURCE,x
			bne	:3
			lda	r0H
			sta	FSLCT_SOURCE,x
			inc	r0H
::3			inc	r0L
			ldx	r0L
			cpx	SortS_Max
			beq	:4
			cpx	r1L
			bne	:2

::4			ldx	r0H
			dex
			stx	SortS_Slct
			jmp	S_SetPos

;*** Seite im Ziel-Tabelle markieren.
:T_SetPage_a		ldx	SortT_Top
			stx	r0L
			txa
			clc
			adc	#SB_MaxFiles
			sta	r1L
			ldy	SortT_Slct
			iny
			sty	r0H

::2			lda	FLIST_TARGET,x
			tax
			lda	FSLCT_TARGET,x
			bne	:3
			lda	r0H
			sta	FSLCT_TARGET,x
			inc	r0H
::3			inc	r0L
			ldx	r0L
			cpx	SortT_Max
			beq	:4
			cpx	r1L
			bne	:2

::4			ldx	r0H
			dex
			stx	SortT_Slct
			jmp	T_SetPos

;*** Quell-Bit löschen.
:S_ResetBit		lda	#>FSLCT_SOURCE
			ldx	#$00
			beq	Reset1Bit

;*** Ziel-Bit löschen.
:T_ResetBit		lda	#>FSLCT_TARGET
			ldx	#$01

:Reset1Bit		sta	r4H
			ClrB	r4L

			lda	#$00
			sta	SortS_Slct,x
			tay
::1			sta	(r4L),y
			iny
			bne	:1
			rts

;*** Anzeigebalken verschieben.
:S_ChkBalken		lda	r1L
			bne	:1
			LoadB	r3H,0
			jmp	InitBalkenData
::1			jmp	S_MoveBar

:T_ChkBalken		lda	r1L
			bne	:1
			LoadB	r3H,1
			jmp	InitBalkenData
::1			jmp	T_MoveBar

;*** Anzeigebalken initialisieren.
:InitBalkenData		ldx	a3H			;Quelle/Ziel?

			lda	scrBarXPosCards,x
			sta	scrBarData+0

			lda	SortS_Max,x		;Max. 255 Dateien.
			sta	scrBarData+4

			lda	SortS_Top,x		;Max. 255 Dateien.
			sta	scrBarData+6

			lda	#$00			;High-Byte von Anzahl/Position
			sta	scrBarData+5		;löschen (nur 8-Bit-Werte).
			sta	scrBarData+7

			LoadW	r0,scrBarData
			jmp	InitScrBar16
