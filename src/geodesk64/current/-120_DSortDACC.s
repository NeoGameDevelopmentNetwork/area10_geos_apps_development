; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Tabelle ausgeben.
;Wird über ":fileListData" definiert.
; :a0  = Zeiger auf Dateien Quelle.
; :a1  = Zeiger auf Dateien Ziel.
; :a2  = Zeiger auf x-Koordinate.
;
;Allgemeine Variablen.
; :a3L = reserviert für y-Koordinate.
; :a3H = $00 = Source, $01 = Target.
;
;Abhängig von Quelle/Ziel.
; :a4  = Max. Dateien Quelle/Ziel.
; :a5L = Zähler für Dateien in Tabelle.
; :a5H = Berechnung für Zeiger/Eintrag.
; :a6  = Aktueller Eintrag.
; :a7  = Ausgabe von Eintrag xyz.
; :a8  = Kopie Ausgabe von Eintrag xyz.
; :a9  = Vektor auf Datei-Nr. in Quelle/Ziel.
:SB_MaxFiles		= 12  -SORTINFO_MODE		;Anzahl Dateien im Fenster.
:SB_YPosMin		= $30 +SORTINFO_MODE*$08	;Y-Koordinate oben für Dateifenster.
:FListYMin		= SB_YPosMin +6			;Y-Koordinate erste Textzeile.
:SB_Height		= SB_MaxFiles*8			;Höhe Scrollbar.
:ShowFileList		LoadB	a3L,FListYMin		;Zeiger auf erste Zeile.

			ClrB	a5L			;Zähler für Anzahl Einträge auf 0.

			ldx	a3H			;Quelle/Ziel.

			lda	SortS_Max,x		;Max. Anzahl Dateien in Tabelle
			sta	a4L			;in Zwischenspeicher kopieren.
			lda	SortS_MaxH,x
			sta	a4H

			lda	SortS_Top,x		;Nr. der ersten Datei auf Seite
			sta	a6L			;in Zwischenspeicher.
			lda	SortS_TopH,x
			sta	a6H

;--- Dateieinträge ausgeben.
::loop			lda	a6H
			cmp	a4H			;Tabellenende erreicht ?
			bne	:exitcmp
			lda	a6L
			cmp	a4L
::exitcmp		bcs	:clrTab			; => Ja, Rest des Fensters löschen.

::1			jsr	GetPosDACC 		;Zeiger auf Dateiposition setzen.
			jsr	View1Entry16		;Dateieintrag ausgeben.

			AddVB	8,a3L			;Zeiger auf nächste Zeile.

			inc	a5L			;Zähler Anzahl Dateien/Tabelle +1.

			IncW	a6			;Zeiger auf nächste Datei.

			CmpBI	a5L,SB_MaxFiles		;Tabelle voll ?
			bne	:loop			; => Nein, weiter...

			rts

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
;Übergabe: a7  = Nummer des Eintrags in DACC.
;                Bit%7=1 : Datei ausgewählt.
;          a2  = X-Position.
;          a3L = Y-Position.
:View1Entry16		lda	a7L			;Nummer des Eintrags kopieren.
			sta	a8L
			lda	a7H
			sta	a8H
			and	#%01111111		;Bit %7 löschen (Dateiauswahl).
			sta	a7H

			jsr	GetFilePos16		;Verzeichniseintrag suchen.
			jmp	PrintEntry		;Dateieintrag ausgeben.

;*** Zeiger auf Verzeichniseintrag berechnen.
;Übergabe: a7 = Nr. des Eintrages im DACC.
;Rückgabe: a7 = Zeiger auf Puffer mit Eintrag.
:GetFilePos16		ldx	#a7L			;Dateinummer x 32.
			ldy	#$05
			jsr	DShiftLeft

			LoadW	r0,dirEntryBuf		;Zeiger auf Dateieintrag im DACC.
			lda	a7L
			clc
			adc	#<$0002
			sta	r1L
			lda	a7H
			adc	#>$0002
			sta	r1H
			LoadW	r2,30
			MoveB	sort64Kbank,r3L
			jsr	FetchRAM		;Dateieintrag einlesen.

			LoadW	a7,dirEntryBuf -2	;Zeiger auf Dateieintrag.

			rts

;*** Dateinummer zu Eintrag in Tabelkle ermitteln.
;Übergabe: a0 = Zeiger auf Tabelle Quelle/Ziel.
;          a6 = Nr. des Eintrages in Tabelle.
;Rückgabe: a7 = Dateinummer.
;          a9 = Zeiger auf Dateinummer.
:GetPosDACC		lda	a6L			;Zähler x 2.
			asl
			sta	a9L
			lda	a6H
			rol
			sta	a9H

			lda	a9L			;Zeiger auf Eintrag in Tabelle.
			clc
			adc	a0L
			sta	a9L
			lda	a9H
			adc	a0H
			sta	a9H

			ldy	#$00
			lda	(a9L),y			;Datei-Nr. in DACC einlesen.
			sta	a7L
			iny
			lda	(a9L),y
			sta	a7H
			rts

;*** Datei aus Quell-/Ziel-Tabelle auswählen.
;Übergabe: A/X = Zeiger auf Tabelle mit Mausgrenzen.
;          a0  = Zeiger auf Dateinummern.
;          a1  = Zeiger auf Auswahl.
;          a3H = Quell/Ziel.
:Slct1File		sta	r0L			;Mausgrenzen festlegen.
			stx	r0H
			jsr	InitRam

			LoadB	a5H,$7f			;Auswahl-Flag zurücksetzen.

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
			sta	a6L
			lda	#$00
			adc	SortS_TopH,x		;Datei innerhalb Liste ?
			sta	a6H

;			lda	a6H
			cmp	SortS_MaxH,x
			bne	:exitcmp
			lda	a6L
			cmp	SortS_Max,x
::exitcmp		bcc	:testSlctMode		; => Ja, weiter...

::exit			LoadW	r0,noMseBorder		;Mausgrenzen löschen, da
			jmp	InitRam			;Mausklick ungültig.

;--- Datei aus-/abwählen?
::testSlctMode		jsr	GetPosDACC 		;Datei-Nr. einlesen.

			ldy	a5H			;Auswahlmodus definiert?
			beq	:unselect		; => Ja, Datei abwählen...
			bmi	:select			; => Ja, Datei auswählen...

::setslctmode		lda	a7H			; => Nein, Modus testen.
			and	#%10000000
			eor	#%10000000
			sta	a5H			;Datei nicht ausgewählt ?
			bmi	:select			; => Ja, Datei auswählen...

;--- Datei abwählen.
::unselect		bit	a7H			;Datei bereits abgewählt?
			bpl	:invertFile		; => Ja, weiter...
			ldx	a3H			;Anzahl markierter Einträge
			lda	SortS_Slct,x		;korrigieren / -1.
			bne	:1
			dec	SortS_SlctH,x
::1			dec	SortS_Slct,x
			jmp	:invertFile		; => Weiter...

;--- Datei auswählen.
::select		bit	a7H			;Datei bereits ausgewählt?
			bmi	:invertFile		; => Ja, weiter...
			ldx	a3H			;Anzahl markierter Einträge
			inc	SortS_Slct,x		;korrigieren / +1.
			bne	:invertFile
			inc	SortS_SlctH,x

;--- Eintrag invertieren.
::invertFile		ldy	#$01			;Bit%7 der Dateinummer setzen:
			lda	(a9L),y
			and	#%01111111		;%0xxxxxxx = Datei nicht gewählt.
			ora	a5H			;%1xxxxxxx = Datei ausgewählt.
			sta	(a9L),y
			sta	a7H

;--- Dateieintrag ausgeben.
::prntSlctFile		lda	a8H			;Ausgabezeile für Eintrag
			asl				;berechnen.
			asl
			asl
			clc
			adc	#FListYMin
			sta	a3L
			jsr	View1Entry16		;Dateieintrag ausgeben.

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
:TakeSource		lda	SortS_Slct		;Source-Dateien gewählt ?
			ora	SortS_SlctH
			beq	:1			; => Nein, Abbruch.

			ldx	SortT_MaxH		;Zielverzeichnis voll ?
			cpx	#>MaxSortFiles
			bne	:exitcmp
			ldx	SortT_Max
			cpx	#<MaxSortFiles
::exitcmp		bcc	:2			; => Nein, weiter...
::1			rts				; => Ja, Abbruch.

::2			LoadW	a0,FLIST_SOURCE

			lda	SortT_Max
			asl
			sta	a1L
			lda	SortT_MaxH
			rol
			sta	a1H

			lda	a1L
			clc
			adc	#<FLIST_TARGET
			sta	a1L
			lda	a1H
			adc	#>FLIST_TARGET
			sta	a1H

::11			ldy	#$01
			lda	(a0L),y
			cmp	#$7f			;Ende Dateien erreicht?
			beq	:31			; => Ja, Ende...
			bcc	:21			;Datei markiert?
							; => Nein, weiter...

			and	#%01111111
			sta	(a1L),y			;Nr. Eintrages in Tabelle kopieren.
			dey
			lda	(a0L),y			;Eintrag übernehmen?
			sta	(a1L),y			;Nr. Eintrages in Tabelle kopieren.

			lda	SortS_Slct		;Anzahl ausgewählte Dateien
			bne	:12			;in Quelle korrigieren.
			dec	SortS_SlctH
::12			dec	SortS_Slct

			lda	SortS_Max		;Max. Anzahl Dateien in
			bne	:13			;Quelle korrigieren.
			dec	SortS_MaxH
::13			dec	SortS_Max

			AddVBW	2,a1

;			ldy	#$00			;Kennung setzen:
			lda	#$ff			;"Datei in Ziel übertragen"
			sta	(a0L),y
			iny
			sta	(a0L),y

			inc	SortT_Max		;Anzahl Ziel-Dateien +1.
			bne	:14
			inc	SortT_MaxH

::14			lda	SortS_Slct		;Alle Einträge übernommen?
			ora	SortS_SlctH
			beq	:31			; => Ja, Ende...

::21			AddVBW	2,a0			;Zeiger auf nächste Quell-Datei.
			jmp	:11			;Weitere Dateien übernehmen.

::31			lda	#<FLIST_SOURCE		;In Ziel übernommene Dateien
			ldx	#>FLIST_SOURCE		;aus Quell-Tabelle bereinigen.
			jmp	clearDirEntries

;*** Ziel-Dateien übernehmen.
:TakeTarget		lda	SortT_Slct		;Source-Dateien gewählt ?
			ora	SortT_SlctH
			beq	:1			; => Nein, Abbruch.

			ldx	SortS_MaxH		;Zielverzeichnis voll ?
			cpx	#>MaxSortFiles
			bne	:exitcmp
			ldx	SortS_Max
			cpx	#<MaxSortFiles
::exitcmp		bcc	:2			;Nein, weiter...
::1			rts				; => Ja, Abbruch.

::2			LoadW	a1,FLIST_TARGET
			LoadW	r2,MaxSortFiles

::11			ldy	#$01
			lda	(a1L),y
			cmp	#$7f			;Ende Dateien erreicht?
			beq	:31			; => Ja, Ende...
			bcc	:21			;Datei markiert?
							; => Nein, weiter...

			jsr	insert2Byte		;2-Byte in Quelle reservieren.

			ldy	#$00			;Dateinummer von Ziel nach
			lda	(a1L),y			;Quelle übernehmen.
			sta	(a0L),y
			iny
			lda	(a1L),y
			and	#%01111111		;Dateiauswahl-Flag zurücksetzen.
			sta	(a0L),y

			ldy	#$00
			lda	#$ff
			sta	(a1L),y
			iny
			sta	(a1L),y

			lda	SortT_Slct		;Anzahl ausgewählte Dateien
			bne	:12			;in Ziel korrigieren.
			dec	SortT_SlctH
::12			dec	SortT_Slct

			lda	SortT_Max		;Max. Anzahl Dateien in
			bne	:13			;Ziel korrigieren.
			dec	SortT_MaxH
::13			dec	SortT_Max

			inc	SortS_Max		;Anzahl Dateien Quelle +1.
			bne	:21
			inc	SortS_MaxH

::21			AddVBW	2,a1			;Zeiger auf nächste Datei.

			lda	SortT_Slct		;Alle Einträge übernommen?
			ora	SortT_SlctH
			bne	:11			; => Nein, weiter...

::31			lda	#<FLIST_TARGET		;In Quelle übernommene Dateien
			ldx	#>FLIST_TARGET		;aus Ziel-Tabelle bereinigen.
			jmp	clearDirEntries

;*** Eintrag in Quelle für Ziel-Eintrag reservieren.
;Übergabe: a1  = Dateinummer Ziel.
:insert2Byte		LoadW	a0,FLIST_SOURCE
			LoadW	r2,(MaxSortFiles * 2) -2

			ldy	#$00			;Dateinummer Ziel einlesen.
			lda	(a1L),y
			sta	r10L
			iny
			lda	(a1L),y
			and	#%01111111
			sta	r10H

::loop			ldy	#$00			;Dateinummer Quelle einlesen.
			lda	(a0L),y
			sta	r11L
			iny
			lda	(a0L),y
			and	#%01111111
			sta	r11H

			CmpW	r10,r11			;Ziel < Quelle?
			bcs	:next			; => Nein, weiter...

			lda	a0L			;Ab hier nur noch Einträge mit
			sta	r0L			;größerer Dateinummer.
			clc				;2 Bytes für Eintrag reservieren.
			adc	#<$0002
			sta	r1L
			lda	a0H
			sta	r0H
			adc	#>$0002
			sta	r1H

			jmp	MoveData		;Speicherbereich verschieben.

::next			AddVBW	2,a0			;Zeiger auf nächsten Eintrag.
			SubVW	2,r2			;Tabellengröße -2.

			lda	r2L			;Alle Dateien geprüft?
			ora	r2H
			bne	:loop			; => Nein, weiter...
			rts

;*** Gelöschte Einträge aus Tabelle entfernen.
;Übergabe: A/X = Zeiger auf Dateiliste.
;          a3H =  Quelle/Ziel = 0/1.
:clearDirEntries	sta	r0L			;Anfang komprimierte Liste mit
			stx	r0H			;Dateinummern.

			sta	r1L			;Zeiger auf unkomprimierte
			stx	r1H			;Liste mit Dateinummern.

			LoadW	r2,MaxSortFiles		;Max. Anzahl an Dateien zum testen.

::loop			ldy	#$01			;Eintrag gelöscht?
			lda	(r1L),y
			dey
			cmp	#$7f			;Kennung = $7FFF = Ende Dateien?
			beq	:clearEntry		; => Ja, restliche Einträge löschen.
			cmp	#$ff			;Kennung = $FFFF = Ausgewählt?
			bne	:compress		; => Nein, Eintrag übernehmen.
			lda	(r1L),y
			cmp	#$ff			;Kennung = $FFFF = Ausgewählt?
			beq	:next			; => Ja, Eintrag übergehen...

::compress		lda	(r1L),y			;Gelöschten Eintrag aus Tabelle
			sta	(r0L),y			;entfernen.
			iny
			lda	(r1L),y
			sta	(r0L),y

			AddVBW	2,r0			;Zeiger auf nächsten Eintrag.

::next			AddVBW	2,r1			;Zeiger auf nächsten Eintrag.

			lda	r2L			;Anzahl geprüfter Einträge -1.
			bne	:1
			dec	r2H
::1			dec	r2L

			lda	r2L			;Alle Dateien geprüft?
			ora	r2H
			bne	:loop			; => Nein, weiter...

;--- Dateien aus Tabelle entfernen.
::clearEntry		CmpW	r0,r1			;Alle Einträge gelöscht?
			beq	:allDone		; => Ja, Ende...

			ldy	#$00			;Gelöschten Eintra als
			lda	#$ff			;"Nicht vorhanden" markieren.
			sta	(r0L),y
			iny
			lda	#$7f
			sta	(r0L),y

			AddVBW	2,r0			;Zeiger auf nächsten Eintrag...
			jmp	:clearEntry		; => Weitersuchen...

;--- Dateiliste neu ausgeben.
;Dabei wird dann dann auch die Auswahl von Quelle und Ziel gelöscht und
;beide Listen werden auf Anfang gesetzt.
::allDone		lda	a3H			;Quelle oder Ziel?
			bne	:target			; => Ziel, weiter...

::source		jsr	S_SetPos		;Quell-Tabelle aktualisieren.
			jsr	T_End			;In Ziel-Tabelle zum Ende gehen.
			jmp	PrintFiles		;Dateianzahl aktualisieren.

::target		jsr	S_SetPos		;Quell-Tabelle aktualisieren.
			jsr	T_SetPos		;Ziel-Tabelle aktualisieren.
			jmp	PrintFiles		;Dateianzahl aktualisieren.

;*** Zum Anfang der Quell-Tabelle.
:S_Top			lda	#$00
			sta	SortS_Top
			sta	SortS_TopH
			beq	S_SetPos

;*** In der Quell-Tabelle zum Ende springen.
:S_End			jsr	S_TestEndPos
			jmp	S_SetPos

;*** Zum Anfang der Ziel-Tabelle.
:T_Top			lda	#$00
			sta	SortT_Top
			sta	SortT_TopH
			beq	T_SetPos

;*** In der Ziel-Tabelle zum Ende springen.
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
			adc	#<SB_MaxFiles
			sta	r0L
			lda	SortS_TopH,x
			adc	#>SB_MaxFiles
			sta	r0H
			bcs	TestEndPos		; => Nein, zum Ende...

			lda	r0H			;Ende ausserhalb max. Dateien?
			cmp	SortS_MaxH,x
			bne	:exitcmp
			lda	r0L
			cmp	SortS_Max,x
::exitcmp		bcs	TestEndPos		; => Ja, zum Ende...
			rts

;*** Auf gültige End-Position testen.
:S_TestEndPos		ldx	#$00
			b $2c
:T_TestEndPos		ldx	#$01

;*** Auf gültige End-Position testen.
;Übergabe: X = Quelle/Ziel = 0/1.
:TestEndPos		lda	SortS_Max,x		;Zum Ende springen.
			sec
			sbc	#<SB_MaxFiles
			sta	SortS_Top,x
			lda	SortS_MaxH,x
			sbc	#>SB_MaxFiles
			sta	SortS_TopH,x		;Genügend Dateien vorhanden?
			bcs	:exit			; => Ja, Ende...

			lda	#$00			;Zum Anfang springen.
			sta	SortS_Top,x
			sta	SortS_TopH,x

::exit			rts

;*** In der Quell-Tabelle eine Seite vorwärts.
:S_NextPage		lda	SortS_Top		;Nächste Seite möglich?
			clc
			adc	#<SB_MaxFiles*2
			tax
			lda	SortS_TopH
			adc	#>SB_MaxFiles*2
			bcs	:move2End		; => Nein, zum Ende springen.

			cmp	SortS_MaxH		;Ende ausserhalb max. Dateien?
			bne	:exitcmp
			cpx	SortS_Max
::exitcmp		bcc	:move2Page		; => Ja, weiter...
::move2End		jmp	S_End			;Zum Ende springen.

::move2Page		jsr	S_SetNextPage		;Neue Position speichern und
			jmp	S_SetPos		;Dateiliste aktualisieren.

;*** Zum Ende der Quell-Tabelle.
:S_LastPage		lda	SortS_Top		;Bereits ganz am Anfang?
			ora	SortS_TopH
			beq	:exit

			jsr	S_SetLastPage		;Vorherige Seite möglich?
			bcs	:move2Page		; => Ja, weiter...
::move2Top		jmp	S_Top			;Zum Anfang springen.
::move2Page		jmp	S_SetPos		;Dateiliste aktualisieren.

::exit			rts

;*** In der Ziel-Tabelle eine Seite vorwärts.
:T_NextPage		lda	SortT_Top		;Nächste Seite möglich?
			clc
			adc	#<SB_MaxFiles*2
			tax
			lda	SortT_TopH
			adc	#>SB_MaxFiles*2
			bcs	:move2End		; => Nein, zum Ende springen.

			cmp	SortT_MaxH		;Ende ausserhalb max. Dateien?
			bne	:exitcmp
			cpx	SortT_Max
::exitcmp		bcc	:move2Page		; => Ja, weiter...
::move2End		jmp	T_End			;Zum Ende springen.

::move2Page		jsr	T_SetNextPage		;Neue Position speichern und
			jmp	T_SetPos		;Dateiliste aktualisieren.

;*** Zum Ende der Ziel-Tabelle.
:T_LastPage		lda	SortT_Top		;Bereits ganz am Anfang?
			ora	SortT_TopH
			beq	:exit

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
			sbc	#<SB_MaxFiles
			sta	SortS_Top,x
			lda	SortS_TopH,x
			sbc	#>SB_MaxFiles
			sta	SortS_TopH,x

			rts

;*** Weiter zur nächsten Seite.
:S_SetNextPage		ldx	#$00
			b $2c
:T_SetNextPage		ldx	#$01

			lda	SortS_Top,x
			clc
			adc	#<SB_MaxFiles
			sta	SortS_Top,x
			lda	SortS_TopH,x
			adc	#>SB_MaxFiles
			sta	SortS_TopH,x

			rts

;*** Mausklick auf Quell-Anzeigebalken.
:S_MoveBar		lda	SortS_MaxH		;Anzeigebalken möglich?
			cmp	#>SB_MaxFiles
			bne	:exitcmp
			lda	SortS_Max
			cmp	#<SB_MaxFiles
::exitcmp		bcc	:exit			; => Nein, Ende...

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
:T_MoveBar		lda	SortT_MaxH		;Anzeigebalken möglich?
			cmp	#>SB_MaxFiles
			bne	:exitcmp
			lda	SortT_Max
			cmp	#<SB_MaxFiles
::exitcmp		bcc	:exit			; => Nein, Ende...

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
			beq	:moveUp			; => Ja, auswerten.
			cmp	#$06			;Maus nach unten ?
			beq	:moveDown		; => Ja, auswerten.
			jmp	:waitMouse		; => Keine Bewegung, Schleife...

::moveUp		jsr	LastFile_a		;Eine Datei zurück.
			bcs	:waitMouse		; => Geht nicht, ignorieren.

;			ldx	a3H			;Zeiger auf vorherige Datei.
			lda	SortS_Top,x
			bne	:1
			dec	SortS_TopH,x
::1			dec	SortS_Top,x
			jmp	:move2Pos		;Neue Position anzeigen.

::moveDown		jsr	NextFile_a		;Eine Datei vorwärts.
			bcs	:waitMouse		; => Geht nicht, ignorieren.

;			ldx	a3H			;Zeiger auf nächste Datei.
			inc	SortS_Top,x
			bne	:move2Pos
			inc	SortS_TopH,x

::move2Pos		lda	SortS_Top,x		;Tabellenposition einlesen.
			ldy	SortS_TopH,x
			jsr	SetNewPos16		;Anzeigebalken setzen und
			jsr	SetRelMouse		;Maus entsprechend verschieben.
			jmp	:waitMouse		;Maus weiter auswerten.

;*** Eine Datei vorwärts.
:NextFile		jsr	NextFile_a
			bcc	NextFile_b
			rts				;Abbruch...

:NextFile_a		ldx	a3H
			lda	SortS_Top,x		;Nächsten Dateinamen ausgeben.
			clc
			adc	#SB_MaxFiles
			sta	a6L
			lda	SortS_TopH,x
			adc	#$00
			sta	a6H

;			lda	a6H
			cmp	SortS_MaxH,x		;Tabellen-Ende erreicht ?
			bne	:exitcmp
			lda	a6L
			cmp	SortS_Max,x		;Tabellen-Ende erreicht ?
::exitcmp
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
			bne	:3
			inc	SortS_TopH,x		;Tabellenzeiger korrigieren.

::3			jsr	GetPosDACC 		;Datei-Nr. einlesen.

			lda	#FListYMin +SB_Height -$08
			sta	a3L

			jsr	View1Entry16

			ldx	a3H
			lda	SortS_Top,x		;Nächsten Dateinamen ausgeben.
			ldy	SortS_TopH,x
			jsr	SetNewPos16		;Scrollbalken aktualisieren.

			jsr	TestMouse		;Dauerfunktion?

			jmp	NextFile		; => Weiterscrollen.

;*** Eine Datei zurück.
:LastFile		jsr	LastFile_a
			bcc	LastFile_b
			rts				;Abbruch.

:LastFile_a		ldx	a3H
			lda	SortS_Top,x		;Nächsten Dateinamen ausgeben.
			sta	a6L
			lda	SortS_TopH,x
			sta	a6H
			ora	a6L			;Tabellenanfang erreicht?
			bne	:1			; => Nein, weiter...
			sec				;Ende erreicht.
			rts
::1			clc				;Datei zurück.
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
			lda	SortS_Top,x
			bne	:3
			dec	SortS_TopH,x		;Tabellenzeiger korrigieren.
::3			dec	SortS_Top,x

			lda	SortS_Top,x		;Nächsten Dateinamen ausgeben.
			sta	a6L
			lda	SortS_TopH,x
			sta	a6H
			jsr	GetPosDACC 		;Datei-Nr. einlesen.

			lda	#FListYMin
			sta	a3L

			jsr	View1Entry16

			ldx	a3H
			lda	SortS_Top,x		;Nächsten Dateinamen ausgeben.
			ldy	SortS_TopH,x
			jsr	SetNewPos16		;Scrollbalken aktualisieren.

			jsr	TestMouse		;Dauerfunktion?

			jmp	LastFile		; => Ja, Weiterscrollen.

;*** Alle Dateien im Quell-Tabelle markieren.
:S_SetAll		lda	SortS_Max
			ora	SortS_MaxH
			bne	:1
			rts

::1			LoadW	a0,FLIST_SOURCE
			LoadW	r2,MaxSortFiles

:S_SetAll_a		ldy	#$01
			lda	(a0L),y			;Eintrag bereits markiert?
			bmi	:2			; => Ja, weiter...
			cmp	#$7f			;Ende Dateieinträge erreicht?
			beq	:end			; => Ja, Ende...

::1			lda	(a0L),y
			ora	#%10000000
			sta	(a0L),y

			inc	SortS_Slct
			bne	:2
			inc	SortS_SlctH

::2			AddVBW	2,a0

			lda	r2L
			bne	:3
			dec	r2H
::3			dec	r2L

			lda	r2L
			ora	r2H
			bne	S_SetAll_a

::end			jmp	S_SetPos

;*** Alle Dateien im Ziel-Tabelle markieren.
:T_SetAll		lda	SortT_Max
			ora	SortT_MaxH
			bne	:1
			rts

::1			LoadW	a1,FLIST_TARGET
			LoadW	r2,MaxSortFiles

:T_SetAll_a		ldy	#$01
			lda	(a1L),y			;Eintrag bereits markiert?
			bmi	:2			; => Ja, weiter...
			cmp	#$7f			;Ende Dateieinträge erreicht?
			beq	:end			; => Ja, Ende...

::1			lda	(a1L),y
			ora	#%10000000
			sta	(a1L),y

			inc	SortT_Slct
			bne	:2
			inc	SortT_SlctH

::2			AddVBW	2,a1

			lda	r2L
			bne	:3
			dec	r2H
::3			dec	r2L

			lda	r2L
			ora	r2H
			bne	T_SetAll_a

::end			jmp	T_SetPos

;*** Seite im Quell-Tabelle markieren.
:S_SetPage_a		lda	SortS_Top		;Zeiger auf ersten Eintrag.
			asl
			sta	a0L
			lda	SortS_TopH
			rol
			sta	a0H
			AddVW	FLIST_SOURCE,a0

			LoadW	r2,SB_MaxFiles		;Anzahl Dateien im Fenster.

			jmp	S_SetAll_a

;*** Seite im Ziel-Tabelle markieren.
:T_SetPage_a		lda	SortT_Top		;Zeiger auf ersten Eintrag.
			asl
			sta	a1L
			lda	SortT_TopH
			rol
			sta	a1H
			AddVW	FLIST_TARGET,a1

			LoadW	r2,SB_MaxFiles		;Anzahl Dateien im Fenster.

			jmp	T_SetAll_a

;*** Quell-Bit löschen.
:S_ResetBit		lda	#<FLIST_SOURCE
			ldy	#>FLIST_SOURCE
			ldx	#$00
			beq	Reset1Bit

;*** Ziel-Bit löschen.
:T_ResetBit		lda	#<FLIST_TARGET
			ldy	#>FLIST_TARGET
			ldx	#$01

:Reset1Bit		sta	r4L
			sty	r4H

			lda	#$00
			sta	SortS_Slct,x
			sta	SortS_SlctH,x

			lda	SortS_Max,x
			sta	r5L
			lda	SortS_MaxH,x
			sta	r5H

::1			lda	r5L
			ora	r5H
			beq	:3

			ldy	#$01
			lda	(r4L),y
			and	#%01111111
			sta	(r4L),y

			AddVBW	2,r4

			lda	r5L
			bne	:2
			dec	r5H
::2			dec	r5L
			jmp	:1

::3			rts

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
:InitBalkenData		ldx	r3H			;Quelle/Ziel?

			lda	scrBarXPosCards,x
			sta	scrBarData+0

			lda	SortS_Max,x		;Max. 2048 Dateien / 64K-Bank.
			sta	scrBarData+4
			lda	SortS_MaxH,x		;High-Byte von Anzahl/Position
			sta	scrBarData+5		;setzen (16-Bit-Wert).

			lda	SortS_Top,x		;Max. 2048 Dateien / 64K-Bank.
			sta	scrBarData+6
			lda	SortS_TopH,x		;High-Byte von Anzahl/Position
			sta	scrBarData+7		;setzen (16-Bit-Wert).

			LoadW	r0,scrBarData
			jmp	InitScrBar16
