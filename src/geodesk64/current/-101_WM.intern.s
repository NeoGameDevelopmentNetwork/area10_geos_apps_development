; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;Routine:   WM_CALL_EXEC
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Mausklick in Fenster auswerten.
;******************************************************************************
:WM_CALL_EXEC		jsr	WM_LOAD_WIN_DATA
			lda	WM_DATA_WINSLCT +0
			ldx	WM_DATA_WINSLCT +1
			ldy	WM_WCODE
			jmp	CallRoutine

;******************************************************************************
;Routine:   WM_CALL_EXIT
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Fenster zum schließen vorbereiten.
;******************************************************************************
:WM_CALL_EXIT		jsr	WM_LOAD_WIN_DATA
			lda	WM_DATA_WINEXIT +0
			ldx	WM_DATA_WINEXIT +1
			ldy	WM_WCODE
			jmp	CallRoutine

;******************************************************************************
;Routine:   WM_CALL_RIGHTCLK
;Parameter: WM_WCODE = Fenster-Nr.
;           WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Klick mit rechter Maustaste in Fenster auswerten.
;******************************************************************************
:WM_CALL_RIGHTCLK	jsr	WM_WAIT_NOMSEKEY	;Warten bis keine M-Taste gedrückt.

			lda	#$3f			;Pause für Maustreiber mit
::1			pha				;Doppelklick auf rechter Taste.
			jsr	UpdateMouse
			pla
			sec
			sbc	#$01
			bpl	:1

			jsr	WM_WAIT_NOMSEKEY	;Warten bis keine M-Taste gedrückt.

			lda	WM_DATA_RIGHTCLK +0
			ldx	WM_DATA_RIGHTCLK +1
			jmp	CallRoutine

;******************************************************************************
;Routine:   setWinDataVec
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe:  r0 0 Zeiger auf Fensterdaten.
;Verändert: A,X,Y,r0-r15
;Funktion:  Zeiger auf Fensterdaten-Tabelle setzen.
;******************************************************************************
:setWinDataVec		ldx	WM_WCODE
			lda	:tab_low,x
			sta	r0L
			lda	:tab_high,x
			sta	r0H
			rts

;*** Tabelle mit Adressen der Fenster-Speicher.
; -> ":WM_LOAD_WIN_DATA"
; -> ":WM_SAVE_WIN_DATA"
::tab_low		b <WM_DATA_ALLWIN +WINDOW_DATA_SIZE *0
			b <WM_DATA_ALLWIN +WINDOW_DATA_SIZE *1
			b <WM_DATA_ALLWIN +WINDOW_DATA_SIZE *2
			b <WM_DATA_ALLWIN +WINDOW_DATA_SIZE *3
			b <WM_DATA_ALLWIN +WINDOW_DATA_SIZE *4
			b <WM_DATA_ALLWIN +WINDOW_DATA_SIZE *5
			b <WM_DATA_ALLWIN +WINDOW_DATA_SIZE *6

::tab_high		b >WM_DATA_ALLWIN +WINDOW_DATA_SIZE *0
			b >WM_DATA_ALLWIN +WINDOW_DATA_SIZE *1
			b >WM_DATA_ALLWIN +WINDOW_DATA_SIZE *2
			b >WM_DATA_ALLWIN +WINDOW_DATA_SIZE *3
			b >WM_DATA_ALLWIN +WINDOW_DATA_SIZE *4
			b >WM_DATA_ALLWIN +WINDOW_DATA_SIZE *5
			b >WM_DATA_ALLWIN +WINDOW_DATA_SIZE *6

;******************************************************************************
;Routine:   WM_SET_MAX_WIN
;Parameter: -
;Rückgabe:  -
;Verändert: A,X,Y,r2-r4
;Funktion:  Definiert max. Fenstergröße.
;******************************************************************************
:WM_SET_MAX_WIN		ldy	#$00 +5
			b $2c

;******************************************************************************
;Routine:   WM_SET_STD_WIN
;Parameter: -
;Rückgabe:  -
;Verändert: A,X,Y,r2-r4
;Funktion:  Definiert Standard-Fenstergröße.
;******************************************************************************
;Hinweis:
;Einsprungsadresse wird aktuell
;nicht verwendet.
::WM_SET_STD_WIN	ldy	#$06 +5
			b $2c

;******************************************************************************
;Routine:   WM_SET_SCR_SIZE
;Parameter: -
;Rückgabe:  -
;Verändert: A,X,Y,r2-r4
;Funktion:  Definiert Bildschirm/Desktop-Größe.
;******************************************************************************
:WM_SET_SCR_SIZE	ldy	#$0c +5

			ldx	#$00 +5
::1			lda	:tab,y
			sta	r2L,x
			dey
			dex
			bpl	:1
			rts

;*** Fenstergrößen definieren.
::tab			b $00				;Max. Fenstergröße.
			b MAX_AREA_WIN_Y -1
			w $0000
			w MAX_AREA_WIN_X -1

			b WIN_STD_POS_Y			;Standard-Fenstergröße.
			b WIN_STD_POS_Y + WIN_STD_SIZE_Y -1
			w WIN_STD_POS_X
			w WIN_STD_POS_X + WIN_STD_SIZE_X -1

			b $00				;Bildschirm/Desktop.
			b SCRN_HEIGHT -1
			w $0000
			w SCRN_WIDTH -1

;******************************************************************************
;Routine:   WM_GET_SLCT_SIZE
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe:  -
;Verändert: A,X,Y,r2-r4
;Funktion:  Größe für aktuelles Fenster einlesen.
;******************************************************************************
:WM_GET_SLCT_SIZE	lda	WM_WCODE

;******************************************************************************
;Routine:   WM_GET_WIN_SIZE
;Parameter: AKKU = Fenster-Nr.
;Rückgabe:  -
;Verändert: A,X,Y,r2-r4
;Funktion:  Größe für bestimmtes Fenster einlesen.
;******************************************************************************
:WM_GET_WIN_SIZE	tax				;Fenster = DeskTop?
			bne	:0			; => Nein, weiter...
			jmp	WM_SET_MAX_WIN		;Größe für DeskTop setzen.

::0			lda	WM_WCODE
			pha
			stx	WM_WCODE
			jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.
			ldx	WM_WCODE
			pla
			sta	WM_WCODE

			ldy	WMODE_MAXIMIZED,x
			bne	:2			; => Fenster maximiert.

			ldx	#$05			;Fenster-Größe nach r2-r4.
::1			lda	WM_DATA_Y0,x
			sta	r2L       ,x
			dex
			bpl	:1
			bmi	:3

::2			jsr	WM_SET_MAX_WIN		;Fenster maximiert oder DeskTop.

::3			jmp	WM_LOAD_WIN_DATA	;Fensterdaten zurücksetzen.

;******************************************************************************
;Routine:   WM_WIN_MARGIN
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe:  -
;Verändert: A,X,Y,r2-r4
;Funktion:  Setzt Grenzen für Textausgabe auf Bereich den
;           Bereich innerhalb des aktuellen Fensterrahmens.
;******************************************************************************
:WM_WIN_MARGIN		lda	WM_WCODE

;******************************************************************************
;Routine:   WM_SET_MARGIN
;Parameter: AKKU = Fenster-Nr.
;Rückgabe:  -
;Verändert: X,Y,r2-r4
;Funktion:  Setzt Grenzen für Textausgabe auf Bereich den
;           Bereich innerhalb des angegebenen Fensterrahmens.
;******************************************************************************
:WM_SET_MARGIN		pha

			jsr	WM_GET_WIN_SIZE		;Fenstergröße ermitteln.

			lda	r3L			;Linken Rand nach innen setzen.
			clc
			adc	#$08
			sta	leftMargin +0
			lda	r3H
			adc	#$00
			sta	leftMargin +1

			lda	r4L			;Rechten Rand nach innen setzen.
			sec
			sbc	#$08
			sta	rightMargin +0
			lda	r4H
			sbc	#$00
			sta	rightMargin +1

			lda	r2L			;Oberen Rand nach innen setzen.
			clc
			adc	#$08
			sta	windowTop

			lda	r2H			;Unteren Rand nach innen setzen.
			sec
			sbc	#$08
			sta	windowBottom
			pla
			rts

;******************************************************************************
;Routine:   WM_DRAW_SLCT_WIN
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Zeichnet leeres Fenster mit System-Icons.
;******************************************************************************
:WM_DRAW_SLCT_WIN	jsr	WM_GET_SLCT_SIZE	;Fenstergröße einlesen.

			jsr	WM_DRAW_USER_WIN	;Leeres Fenster zeichnen.

			jsr	WM_NO_MARGIN		;Rand für Textausgabe zurücksetzen.

;--- System-Icons zeichnen.
			LoadW	r14,:tab1
			LoadB	r15H,5
			MoveB	C_WinTitel,r13H
			jsr	WM_DRAW_ICON_TAB

;--- Resize-Icons zeichnen.
			lda	WM_DATA_SIZE		;Größenänderung zulassen?
			bne	:1			; => Nein, weiter...

			LoadW	r14,:tab2
			LoadB	r15H,4
			MoveB	C_WinTitel,r13H
			jsr	WM_DRAW_ICON_TAB

;--- Move-UP/DOWN-Icons zeichnen.
::1			lda	WM_DATA_MOVEBAR		;Scrollbalken anzeigen?
			beq	:2			; => Nein, weiter...

			LoadW	r14,:tab3
			LoadB	r15H,2
			lda	C_WinMovIcons		;Farbe für Scroll-Up/Down-Icons.
			sta	r13H
			jsr	WM_DRAW_ICON_TAB	;Scroll-Up/Down-Icons anzeigen.

::2			rts

;*** Angaben zur Ausgabe der Fenster-Icons.
;    w Zeiger auf Icon-Daten.
;    w Routine zum setzen der Icon-Position.
::tab1			w Icon_CL
			w WM_DEF_AREA_CL

			w Icon_DN
			w WM_DEF_AREA_DN

			w Icon_ST
			w WM_DEF_AREA_STD

			w Icon_MN
			w WM_DEF_AREA_MN

			w Icon_MX
			w WM_DEF_AREA_MX

::tab2			w Icon_UL
			w WM_DEF_AREA_UL

			w Icon_UR
			w WM_DEF_AREA_UR

			w Icon_DL
			w WM_DEF_AREA_DL

			w Icon_DR
			w WM_DEF_AREA_DR

::tab3			w Icon_PU
			w WM_DEF_AREA_WUP

			w Icon_PD
			w WM_DEF_AREA_WDN

;******************************************************************************
;Routine:   WM_DRAW_USER_WIN
;Parameter: r2-r4 = Fenstergröße.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;           Ausnahme: r2L, r2H, r3, r4
;Funktion:  Leeres Fenster ohne System-Icons zeichnen.
;******************************************************************************
:WM_DRAW_USER_WIN	PushB	r2L			;Y-Oben speichern.
			PushW	r3			;X-Links speichern.

			jsr	WM_CLEAR_WINAREA	;Fensterbereich löschen.

			lda	r2L			;Y-Oben/Unten zwischenspeichern.
			pha
			lda	r2H
			pha

;--- Kopfzeile zeichnen.
			lda	r2L			;Bereich für Kopfzeile definieren.
			clc
			adc	#$07
			sta	r2H

			lda	C_WinTitel		;Farbe für Titelzeile.
			jsr	DirectColor

;--- Fußzeile zeichnen.
			pla				;Bereich für Statuszeile definieren.
			sta	r2H
			sec
			sbc	#$07
			sta	r2L

			lda	C_WinTitel		;Farbe für Statuszeile.
			jsr	DirectColor

			pla				;Y-Oben zurücksetzen.
			sta	r2L

			MoveB	r2H,r11L		;Ende des Fensters mit einer Linie
			lda	#%10101010		;markieren, damit Statuszeile und
			jsr	HorizontalLine		;Kopfzeile verschiedener Fenster
							;unterscheidbar sind.

;--- Linken/rechten Rand zeichnen.
			lda	r4H			;X-Rechts speichern.
			pha
			lda	r4L
			pha

			MoveW	r3,r4			;Linker Rand.
			MoveB	r2L,r3L
			MoveB	r2H,r3H
			lda	#%11111111
			jsr	VerticalLine

			pla				;Rechter Rand.
			sta	r4L
			pla
			sta	r4H
			lda	#%11111111
			jsr	VerticalLine

			PopW	r3			;X-Links zurücksetzen.
			PopB	r2L			;Y-Oben zurücksetzen.
			rts

;******************************************************************************
;Routine:   WM_CLEAR_WINAREA
;Parameter: r2-r4 = Fenstergröße.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Löscht den Fensterbereich.
;******************************************************************************
:WM_CLEAR_WINAREA	lda	C_WinBack		;Farbe für Fenster setzen.
			jsr	DirectColor
			lda	#$00			;Fensterbereich löschen.
			jsr	SetPattern
			jmp	Rectangle

;******************************************************************************
;Routine:   WM_DRAW_ICON_TAB
;Parameter: r14  = Zeiger auf Icon-Tabelle.
;           r15H = Anzahl Icons.
;           r13H = Farbe
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Fenster-Icons darstellen.
;******************************************************************************
:WM_DRAW_ICON_TAB	ldy	#$03			;Routine zum definieren des
			lda	(r14L),y		;Icon-Bereichs aufrufen.
			tax
			dey
			lda	(r14L),y
			jsr	CallRoutine

			lda	r13H			;Farbe für Icon-Bereich setzen.
			jsr	DirectColor

			jsr	WM_CONVERT_PIXEL	;CARDs nach Pixel wandeln.

			ldy	#$00			;Zeiger auf Icon-Grafik einlesen.
			lda	(r14L),y
			sta	r0L
			iny
			lda	(r14L),y
			sta	r0H
			LoadB	r2L,Icon_MoveW		;Icon-Breite.
			LoadB	r2H,Icon_MoveH		;Icon-Höhe.
			jsr	BitmapUp		;Bitmap anzeigen.

			AddVBW	4,r14			;Zeiger nächstes Icon in Tabelle.

			dec	r15H			;Alle Icons angezeigt?
			bne	WM_DRAW_ICON_TAB	; => Nein, weiter...
			rts

;******************************************************************************
;Routine:   WM_DRAW_TITLE
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Ausgabe der Titelzeile für aktuelles Fenster.
;******************************************************************************
:WM_DRAW_TITLE		jsr	WM_NO_MARGIN
			jsr	WM_GET_SLCT_SIZE

			lda	r2L			;X/Y-Koordinaten berechnen.
			clc
			adc	#$06
			sta	r1H

			lda	r3L
			clc
			adc	#$14
			sta	r11L
			lda	r3H
			adc	#$00
			sta	r11H

			lda	r4L			;Ausgabe für rechten Rand
			sec				;begrenzen.
			sbc	#$2c
			sta	rightMargin +0
			lda	r4H
			sbc	#$00
			sta	rightMargin +1

			lda	WM_DATA_TITLE +0	;Titelzeile ausgeben.
			ldx	WM_DATA_TITLE +1
			jmp	CallRoutine

;******************************************************************************
;Routine:   WM_DRAW_INFO
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Ausgabe der Infozeile für aktuelles Fenster.
;******************************************************************************
:WM_DRAW_INFO		jsr	WM_NO_MARGIN
			jsr	WM_GET_SLCT_SIZE

			lda	r2H			;X/Y-Koordinaten berechnen.
			sec
			sbc	#$02
			sta	r1H

			lda	r3L
			clc
			adc	#$0c
			sta	r11L
			lda	r3H
			adc	#$00
			sta	r11H

			lda	r4L			;Ausgabe für rechten Rand
			sec				;begrenzen.
			sbc	#$0c
			sta	rightMargin +0
			lda	r4H
			sbc	#$00
			sta	rightMargin +1

			lda	WM_DATA_INFO +0		;Titelzeile ausgeben.
			ldx	WM_DATA_INFO +1
			jmp	CallRoutine

;******************************************************************************
;Routine:   WM_DRAW_MOVER
;Parameter: WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Zeichnet Scrollbalken.
;******************************************************************************
:WM_DRAW_MOVER		lda	WM_DATA_MOVEBAR		;Scrollbalken anzeigen?
			bne	:1			; => Ja, weiter...
			rts

::1			jsr	WM_DEF_MOVER_DAT	;Größe Scrollbalken definieren.
			jsr	WM_SCRBAR_INIT		;Scrollbalken initialisieren.
			jmp	WM_SCRBAR_DRAW		;Scrollbalken anzeigen.

;******************************************************************************
;Routine:   WM_DEF_MOVER_DAT
;Parameter: WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe:  r0 = Zeiger auf Datentabelle für Scrollbalken.
;Verändert: A,X,Y,r0-r15
;Funktion:  Definiert Größe/Lage Scrollbalken.
;******************************************************************************
:WM_DEF_MOVER_DAT	jsr	WM_GET_ICON_XY		;Anzahl Einträge ermitteln.
			jsr	WM_GET_SLCT_SIZE	;Größe für aktuelles Fenster laden.

			ldx	#r4L			;X-Position des Scrollbalken
			ldy	#$03			;berechnen: Rechter Fensterrand / 8.
			jsr	DShiftRight
			lda	r4L			;Position in Cards speichern.
			sta	:tmp_XPos

			lda	r2L			;Y-Oben für Scrollbalken.
			clc
			adc	#$08
			sta	:tmp_YPos

			lda	r2H			;Länge für Scrollbalken.
			sec
			sbc	r2L
			sec
			sbc	#4*8			;Titel, Status und 2x Scroll-Icons.
			sta	:tmp_Height
			inc	:tmp_Height		;Anzahl Cards/Höhe +1 -> != $00.

;--- Max. Anzahl an Einträgen.
			lda	WM_DATA_MAXENTRY +0
			sta	:tmp_EntryMax +0
if MAXENTRY16BIT = TRUE
			lda	WM_DATA_MAXENTRY +1
			sta	:tmp_EntryMax +1
endif

;--- Aktuelle Position.
			lda	WM_DATA_CURENTRY +0
			sta	:tmp_EntryPos +0
if MAXENTRY16BIT = TRUE
			lda	WM_DATA_CURENTRY +1
			sta	:tmp_EntryPos +1
endif

;--- Anzahl Einträge je Seite.
			lda	WM_COUNT_ICON_XY
			sta	:tmp_EntryPage +0
if MAXENTRY16BIT = TRUE
			lda	#$00
			sta	:tmp_EntryPage +1
endif

			LoadW	r0,:tmp_MovData		;Zeiger auf Datentabelle.
			rts

;--- Datentabelle für Scrollbalken.
::tmp_MovData
::tmp_XPos		b $00
::tmp_YPos		b $00
::tmp_Height		b $00
if MAXENTRY16BIT = FALSE
::tmp_EntryMax		b $00
::tmp_EntryPos		b $00
::tmp_EntryPage		b $00
endif
if MAXENTRY16BIT = TRUE
::tmp_EntryMax		w $0000
::tmp_EntryPos		w $0000
::tmp_EntryPage		w $0000
endif

;******************************************************************************
;Routine:   WM_DRAW_FRAME
;Parameter: r2-r4 = Fenstergröße.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;           Ausnahme: r2L, r2H, r3, r4
;Funktion:  Zeichnet Gummi-Band.
;           Wird zum verschieben des Fensters und
;           zur Mehrfach-Auswahl verwendet.
;******************************************************************************
;
;DOUBLE_FRAME = TRUE erzeugt einen
;2-Pixel breiten Rand oben/unten. Dies
;entspricht dem Source-Code von 1990.
;
;DOUBLE_FRAME = FALSE erzeugt einen
;1-Pixel breiten Rand oben/unten. Dies
;ist auf einem C64 etwas schneller.
;
:DOUBLE_FRAME = FALSE

if DOUBLE_FRAME = TRUE
:WM_DRAW_FRAME		PushB	r2L			;Y-Oben speichern.
			PushB	r2H			;Y-Unten speichern.

			ldx	r2L
			inx
			stx	r2H			;Oberen Rand invertieren.
			jsr	InvertRectangle

			PopB	r2H			;Y-Unten zurücksetzen.
			tax
			dex
			stx	r2L			;Unteren Rand invertieren.
			jsr	InvertRectangle

			PopB	r2L			;Y-Oben zurücksetzen.

			PushW	r3			;X-Links speichern.
			PushW	r4			;X-Rechts speichern.

			MoveW	r3,r4			;Linken Rand invertieren.
			jsr	InvertRectangle

			PopW	r4			;X-Rechts zurücksetzen.

			MoveW	r4,r3			;Rechten Rand invertieren.
			jsr	InvertRectangle

			PopW	r3			;X-Links zurücksetzen.
			rts
endif

if DOUBLE_FRAME = FALSE
:WM_DRAW_FRAME		;lda	r2L			;Y-Oben speichern.
			;pha
			;lda	r2H			;Y-Unten speichern.
			;pha

			lda	r2L			;Oberen Rand invertieren.
			;sta	r2H
			sta	r11L
			;jsr	InvertRectangle
			jsr	InvertLine

			;pla				;Y-Unten zurücksetzen.

			;sta	r2L			;Unteren Rand invertieren.
			;sta	r2H
			lda	r2H
			sta	r11L
			;jsr	InvertRectangle
			jsr	InvertLine

			;pla				;Y-Oben zurücksetzen.
			;sta	r2L

			lda	r3L			;X-Links speichern.
			pha
			tax
			lda	r3H
			pha
			tay

			lda	r4L			;X-Rechts speichern.
			pha
			lda	r4H
			pha

			stx	r4L			;Linken Rand invertieren.
			sty	r4H
			jsr	InvertRectangle

			pla				;X-Rechts zurücksetzen.
			sta	r4H
			sta	r3H
			pla
			sta	r4L
			sta	r3L
			jsr	InvertRectangle		;Rechten Rand invertieren.

			pla				;X-Links zurücksetzen.
			sta	r3H
			pla
			sta	r3L
			rts
endif

;******************************************************************************
;Routine:   WM_SET_CARD_XY
;Parameter: r2L = Y-Koordinate/oben (Pixel)
;           r2H = Y-Koordinate/unten (Pixel)
;           r3  = X-Koordinate/links (Pixel)
;           r4  = X-Koordinate/rechts (Pixel)
;Rückgabe:  r2L = Y-Koordinate/oben (Pixel), abgerundet
;           r2H = Y-Koordinate/unten (Pixel), aufgerundet
;           r3  = X-Koordinate/links (Pixel), abgerundet
;           r4  = X-Koordinate/rechts (Pixel), aufgerundet
;Verändert: A,r2-r4
;Funktion:  Koordinaten auf CARD-Grenzen setzen.
;******************************************************************************
:WM_SET_CARD_XY		lda	r2L			;Y-Koordinate/oben auf Anfang
			and	#%11111000		;des CARDs setzen.
			sta	r2L

			lda	r2H			;Y-Koordinate/unten auf Ende
			ora	#%00000111		;des CARDs setzen.
			sta	r2H

			lda	r3L			;X-Koordinate/links auf Anfang
			and	#%11111000		;des CARDs setzen.
			sta	r3L

			lda	r4L			;X-Koordinate/rechts auf Ende
			ora	#%00000111		;des CARDs setzen.
			sta	r4L
			rts

;******************************************************************************
;Routine:   WM_GET_ICON_X
;Parameter: WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe:  WM_COUNT_ICON_X = Anzahl Einträge in X-Richtung.
;Verändert: A,X,Y,r0,r2-r4
;Funktion:  Berechnet Anzahl Einträge pro Zeile.
;******************************************************************************
:WM_GET_ICON_X		ldx	WM_DATA_COLUMN		;Anzahl Spalten definiert?
			bne	:3			; => Ja, weiter...

;--- Anzahl Spalten nicht definiert,
;    Anzahl Spalten aus Fensterbreite und Icon-Breite berechnen.
::1			jsr	WM_GET_GRID_X		;Anzahl Einträge/Zeile ermitteln.
			sta	:CUR_GRID_X

;--- Fensterbreite berechnen.
			jsr	WM_GET_SLCT_SIZE	;Fenstergröße ermitteln.

			lda	r4L			;Breite Fenster in Pixel -1
			sec				;berechnen.
			sbc	r3L
			sta	r0L
			lda	r4H
			sbc	r3H
			sta	r0H

			ldx	#r0L			;Breite von Pixel nach CARDs
			ldy	#$03			;umrechnen.
			jsr	DShiftRight

			ldx	r0L			;Max. Anzeigebereich ermitteln.
			inx				;Auf volle CARDs aufrunden.
			txa				;Abzug: 1CARD linker Rand.
			sec				;       1CARD Abstand linker Rand.
							;       1CARD rechter Rand.
;--- Hinweis:
;Nur drei CARDs abziehen.
if FALSE
			sbc	#$04			;Falsch: 4CARDs abziehen.
endif
			sbc	#$03			;Richtig: 3CARDs abziehen.

;--- Max. Anzahl Icons pro Zeile berechnen.
if FALSE
			ldx	#$00
::2			cmp	#$02			;Restbreite > 2?
			bcc	:3			; => Nein, Ende...
			tay				;Bereits < ?
			bmi	:3			; => Ja, Ende...
			sec				;Restbreite berechnen.
			sbc	:CUR_GRID_X
			inx				;Anzahl Spalten +1.
			bne	:2
::3			stx	WM_COUNT_ICON_X		;Anzahl Spalten speichern.
			rts
endif

;--- HINWEIS:
;Nur ganze Einträge anzeigen. Bis zur
;Version von 02.07.19 wurden Icons auch
;Partiell angezeigt.
;Im reinen Textmodus wurden nur ganze
;Einträge angezeigt. Das führte dazu
;das nicht alle Texteinträge angezeigt
;wurden, da GRID_X einen größeren Wert
;enthalten hat und am Bildschirm dann
;weniger Einträge angezeigt wurden.
			ldx	#$00
::2			cmp	:CUR_GRID_X		;Restbreite > GRID_X?
			bcc	:3			; => Nein, Ende...
			tay				;Bereits < ?
			bmi	:3			; => Ja, Ende...
			inx				;Anzahl Spalten +1.
			sec				;Restbreite korrigieren.
			sbc	:CUR_GRID_X		;Rest > 0?
			bne	:2			; => Ja, weiter...
::3			stx	WM_COUNT_ICON_X		;Anzahl Spalten speichern.
			rts

::CUR_GRID_X		b $00

;******************************************************************************
;Routine:   WM_GET_ICON_Y
;Parameter: WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe:  WM_COUNT_ICON_Y = Anzahl Icons in Y-Richtung.
;Verändert: A,X,Y,r0,r2-r4
;Funktion:  Berechnet Anzahl Einträge pro Spalte.
;******************************************************************************
:WM_GET_ICON_Y		ldx	WM_DATA_ROW		;Anzahl Zeilen definiert?
			bne	:3			; => Ja, weiter...

;--- Anzahl Zeilen nicht definiert,
;    Anzahl Zeilen aus Fensterhöhe und Icon-Breite berechnen.
::1			jsr	WM_GET_GRID_Y		;Anzahl Einträge/Spalte ermitteln.
			sta	:CUR_GRID_Y

;--- Fensterhöhe berechnen.
			jsr	WM_GET_SLCT_SIZE	;Fenstergröße ermitteln.

			lda	r2H			;Max. Anzeigebereich ermitteln.
			sec				;Abzug: 8Pixel Titelzeile.
			sbc	r2L			;       8Pixel Abstand Titelzeile.
			sec				;       8Pixel Infozeile.
			sbc	#$17

;--- Max. Anzahl Zeilen im Fenster berechnen.
			ldx	#$00			;Zeilenzähler löschen.
::2			cmp	:CUR_GRID_Y
			bcc	:3
;			sec
			sbc	:CUR_GRID_Y
			inx
			bne	:2

::3			stx	WM_COUNT_ICON_Y
			rts

::CUR_GRID_Y		b $00

;******************************************************************************
;Routine:   WM_GET_ICON_XY
;Parameter: WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe:  WM_COUNT_ICON_XY = Anzahl Einträge in Fenster.
;Verändert: A,X,Y,r0,r2-r4
;Funktion:  Berechnet Anzahl Einträge pro Fenster.
;******************************************************************************
:WM_GET_ICON_XY		jsr	WM_GET_ICON_X		;Anzahl Einträge/Zeile ermitteln.
			jsr	WM_GET_ICON_Y		;Anzahl Einträge/Spalte ermitteln.

			lda	#$00			;Anzahl Einträge für Seite
			ldy	WM_COUNT_ICON_Y		;berechnen (X*Y).
			beq	:2
::1			clc
			adc	WM_COUNT_ICON_X
			dey
			bne	:1

::2			sta	WM_COUNT_ICON_XY
			rts

;******************************************************************************
;Routine:   WM_TEST_WIN_POS
;Parameter: WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe:  WM_DATA_BUF
;Verändert: A,X,Y,r0
;Funktion:  Prüft ob erster Eintrag in linker oberer Ecke innerhalb des
;           gültigen Bereichs liegt.
;******************************************************************************
:WM_TEST_WIN_POS	lda	WM_DATA_CURENTRY +0
			sta	r0L
if MAXENTRY16BIT = TRUE
			lda	WM_DATA_CURENTRY +1
			sta	r0H
endif
			jsr	WM_TEST_CUR_POS

			lda	r0L
			sta	WM_DATA_CURENTRY +0
if MAXENTRY16BIT = TRUE
			lda	r0H
			sta	WM_DATA_CURENTRY +1
endif
			jmp	WM_SAVE_WIN_DATA

;******************************************************************************
;Routine:   WM_TEST_CUR_POS
;Parameter: r0 = Zeiger auf aktuellen Eintrag.
;Rückgabe:  r0 = $0000 => Eintrag ungültig.
;Verändert: A,X,r0
;Funktion:  Prüft ob aktueller Eintrag in linker oberer Ecke innerhalb
;           des gültigen Bereichs liegt (Sub. von "WM_TEST_WIN_POS")
;******************************************************************************
:WM_TEST_CUR_POS	lda	r0L			;Icon-Position für nächste
			clc				;Seite berechen.
			adc	WM_COUNT_ICON_XY
if MAXENTRY16BIT = FALSE
			bcs	:2
			cmp	WM_DATA_MAXENTRY +0
endif
if MAXENTRY16BIT = TRUE
			tax
			lda	r0H
			adc	#$00
			bcs	:2

			cmp	WM_DATA_MAXENTRY +1
			bne	:1
			cpx	WM_DATA_MAXENTRY +0
endif

::1			;beq	:4			;Erster Eintrag nächste Seite gülig?
			bcc	:4			; => Ja, Ende...

::2			lda	WM_DATA_MAXENTRY +0
			sec
			sbc	WM_COUNT_ICON_XY
			sta	r0L
if MAXENTRY16BIT = TRUE
			lda	WM_DATA_MAXENTRY +1
			sbc	#$00			;Zeiger auf ersten Eintrag der
			sta	r0H			;letzten Seite berechen.
endif
			bcc	:3			; => Ungültig, weiter...
			rts

::3			lda	#$00			;Zeiger auf ersten Eintrag
			sta	r0L			;zurücksetzen.
if MAXENTRY16BIT = TRUE
			sta	r0H
endif
::4			rts

;******************************************************************************
;Routine:   WM_DEF_STD_WSIZE
;Parameter: WM_WCODE = Fenster-Nr.
;           WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe:  -
;Verändert: A,X,Y
;Funktion:  Standardgröße für aktuelles Fenster setzen.
;Hinweis:   Bei Fenster 1-6 wird die Position um jeweils 8Pixel
;           nach rechts/unten versetzt.
;           Bei mehr als 6 Fenster bleibt die Position auf Standard.
;******************************************************************************
:WM_DEF_STD_WSIZE	ldx	#$05			;Standard-Fenstergröße setzen.
::0			lda	:stdWinSize,x
			sta	WM_DATA_Y0,x
			dex
			bpl	:0

			ldx	WM_WCODE		;Fenster-Nr. einlesen.
			lda	#$00			;Flag für "Fenster maximiert"
			sta	WMODE_MAXIMIZED,x	;löschen.

			cpx	#$06 +1			;Fenster-Position in Abhängigkeit
							;der Fenster-Nr. verschieben.
			bcs	:3			; => Mehr als 6 Fenster, Abbruch.

			ldy	#$00
::1			cpx	#$01			;Fenster-Nr. erreicht?
			beq	:3			; => Ja, Ende...

if FALSE
;--- Hinweis:
;Aktuell sind nicht mehr als 6 Fenster
;möglich. Verschiebung nicht nötig.
			cpy	#$05			;Mehr als 6 Fenster?
			bne	:2			; => Nein, weiter...

			ldy	#$00			;Fenster-Position wieder auf
			SubVB	8*3,WM_DATA_Y0		;Y-Position zurücksetzen.
			SubVB	8*3,WM_DATA_Y1
			;AddVW	8  ,WM_DATA_X0		;X-Position nicht verändern.
			;AddVW	8  ,WM_DATA_X1
endif

::2			AddVB	8  ,WM_DATA_Y0		;Fenster um 1 CARD nach rechts/unten
			AddVB	8  ,WM_DATA_Y1		;verschieben.
			AddVW	16 ,WM_DATA_X0
			AddVW	16 ,WM_DATA_X1

			iny
			dex				;Fenster-Nr. erreicht?
			bne	:1			; => Nein, weiter...

::3			rts

::stdWinSize		b WIN_STD_POS_Y
			b WIN_STD_POS_Y +WIN_STD_SIZE_Y -1
			w WIN_STD_POS_X
			w WIN_STD_POS_X +WIN_STD_SIZE_X -1

;******************************************************************************
;Routine:   WM_SET_WIN_SIZE
;Parameter: WM_WCODE = Fenster-Nr.
;           WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe:  -
;Verändert: A,X,Y
;Funktion:  Größe für aktuelles Fenster speichern.
;******************************************************************************
:WM_SET_WIN_SIZE	jsr	WM_SET_CARD_XY		;Fenstergröße auf CARDs runden.

			jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

			ldx	#$05			;Fenstergröße in Tabelle speichern.
::1			lda	r2L,x
			sta	WM_DATA_Y0,x
			dex
			bpl	:1

			jmp	WM_SAVE_WIN_DATA	;Fensterdaten speichern.

;******************************************************************************
;Routine:   WM_DEF_AREA...
;Parameter: -
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Bereiche für Fenster-Icons berechnen.
;******************************************************************************
:WM_DEF_AREA_CL		lda	#$00
			b $2c
:WM_DEF_AREA_DN		lda	#$03
			b $2c
:WM_DEF_AREA_STD	lda	#$06
			b $2c
:WM_DEF_AREA_MN		lda	#$09
			b $2c
:WM_DEF_AREA_MX		lda	#$0c
			b $2c
:WM_DEF_AREA_UL		lda	#$0f
			b $2c
:WM_DEF_AREA_UR		lda	#$12
			b $2c
:WM_DEF_AREA_DL		lda	#$15
			b $2c
:WM_DEF_AREA_DR		lda	#$18
			b $2c
:WM_DEF_AREA_WUP	lda	#$1b
			b $2c
:WM_DEF_AREA_WDN	lda	#$1e
:WM_DEF_AREA		pha
			jsr	WM_GET_SLCT_SIZE
			pla
			tay

			lda	:WM_DEFICON_TAB +0,y
			bmi	:2

			lda	r3L
			clc
			adc	:WM_DEFICON_TAB +1,y
			sta	r3L
			bcc	:1
			inc	r3H
::1			jmp	:3

::2			lda	r4L
			sec
			sbc	:WM_DEFICON_TAB +1,y
			sta	r3L
			lda	r4H
			sbc	#$00
			sta	r3H

::3			lda	r3L
			clc
			adc	#$07
			sta	r4L
			lda	r3H
			adc	#$00
			sta	r4H

::4			lda	:WM_DEFICON_TAB +0,y
			and	#%01000000
			bne	:5

			lda	r2L
			clc
			adc	:WM_DEFICON_TAB +2,y
			sta	r2L
			clc
			adc	#$07
			sta	r2H
			rts

::5			lda	r2H
			sec
			sbc	:WM_DEFICON_TAB +2,y
			sta	r2L
			clc
			adc	#$07
			sta	r2H
			rts

;*** Tabelle für Icon-Bereiche.
;    b $00!$00 = linke  obere  Ecke
;      $80!$00 = rechte obere  Ecke
;      $00!$40 = linke  untere Ecke
;      $80!$40 = rechte untere Ecke
;    b DeltaX
;    b DeltaY
::WM_DEFICON_TAB	b $00!$00,$08,$00		;Close
			b $80!$00,$27,$00		;Sortieren.
			b $80!$00,$1f,$00		;Standard
			b $80!$00,$17,$00		;Minimize
			b $80!$00,$0f,$00		;Maximize
			b $00!$00,$00,$00		;Resize UL
			b $80!$00,$07,$00		;Resize UR
			b $00!$40,$00,$07		;Resize DL
			b $80!$40,$07,$07		;Resize DR
			b $80!$40,$07,$17		;Resize DL
			b $80!$40,$07,$0f		;Resize DL

;******************************************************************************
;Routine:   WM_DEF_AREA_MV
;Parameter: -
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Bereich für Klick auf Titelzeile berechnen.
;******************************************************************************
:WM_DEF_AREA_MV		jsr	WM_GET_SLCT_SIZE

			lda	r2L
			clc
			adc	#$07
			sta	r2H

			lda	r3L
			clc
			adc	#$10
			sta	r3L
			lda	r3H
			adc	#$00
			sta	r3H

			lda	r4L
			sec
			sbc	#$28
			sta	r4L
			lda	r4H
			sbc	#$00
			sta	r4H
			rts

;******************************************************************************
;Routine:   WM_DEF_AREA_BAR
;Parameter: -
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Bereich für Klick auf Scrollbalken berechnen.
;******************************************************************************
:WM_DEF_AREA_BAR	jsr	WM_GET_SLCT_SIZE

			lda	r2L
			clc
			adc	#$08
			sta	r2L

			lda	r2H
			sec
			sbc	#$18
			sta	r2H

			lda	r4L
			sec
			sbc	#$07
			sta	r3L
			lda	r4H
			sbc	#$00
			sta	r3H
			rts

;******************************************************************************
;Routine:   WM_CALL_MOVE
;Parameter: WM_WCODE = Fenster-Nr.
;           WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Fensterinhalt verschieben.
;******************************************************************************
:WM_CALL_MOVE		lda	WM_DATA_WINMOVE +0
			ldx	WM_DATA_WINMOVE +1
			cmp	#$ff
			bne	:51
			cpx	#$ff			;Standard-Icon-Modus?
			bne	:51			; => Nein, weiter...
			jmp	WM_MOVE_ENTRY_I

::51			cmp	#$ee
			bne	:52
			cpx	#$ee			;Standard-Text-Modus?
			bne	:52			; => Nein, weiter...
			jmp	WM_MOVE_ENTRY_T

::52			ldy	WM_WCODE		;Anwender-Routine zum verschieben
			jmp	CallRoutine		;der Daten aufrufen.

;******************************************************************************
;Routine:   WM_MOVE_ENTRY_I
;Parameter: WM_WCODE = Fenster-Nr.
;           WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Standard-Routine zum verschieben von Icon-Daten.
;           Wird aufgerufen mit Tabellen-Eintrag ":WM_DATA_MOVE" = $FFFF.
;******************************************************************************
:WM_MOVE_ENTRY_I	jsr	WM_GET_ICON_X
			jsr	WM_GET_ICON_Y

			lda	WM_DATA_CURENTRY +0
			sta	r0L
if MAXENTRY16BIT = TRUE
			lda	WM_DATA_CURENTRY +1
			sta	r0H
endif

			lda	WM_MOVE_MODE
			beq	:moveLineUp
			bmi	:moveLineDown
			jmp	WM_MOVE_POS

::exit			ldx	#$00			; => Keine Daten ausgegeben.
			rts

;--- Nach oben verschieben.
::moveLineUp		lda	r0L
if MAXENTRY16BIT = TRUE
			ora	r0H
endif
			beq	:exit

if MAXENTRY16BIT = TRUE
			lda	r0L
endif
			sec
			sbc	WM_COUNT_ICON_X
			sta	r0L
if MAXENTRY16BIT = TRUE
			lda	r0H
			sbc	#$00
			sta	r0H
endif
			bcs	moveIconPos		; => Kein Unterlauf, weiter...
			bcc	moveTopOfPage		; => Zum Anfang der Liste.

;--- Nach unten verschieben.
::moveLineDown		lda	r0L
			clc
			adc	WM_COUNT_ICON_X
			sta	r0L
if MAXENTRY16BIT = TRUE
			lda	r0H
			adc	#$00
			sta	r0H
endif

			bcc	moveIconPos		; => Kein überlauf, weiter...

;--- Eintrag ungültiug, neu positionieren.
:moveEndOfPage		lda	#$ff			;Zeiger auf letzten Eintrag.
			b $2c
:moveTopOfPage		lda	#$00			;Zeiger auf ersten Eintrag.
			sta	r0L
if MAXENTRY16BIT = TRUE
			sta	r0H
endif

:moveIconPos		jsr	WM_TEST_CUR_POS		;Neue Position testen/korrigieren.
			jmp	WM_SET_NEW_POS		;Neue Position setzen.

;******************************************************************************
;Routine:   WM_MOVE_ENTRY_T
;Parameter: WM_WCODE = Fenster-Nr.
;           WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Standard-Routine zum verschieben von Text-Daten.
;           Wird aufgerufen mit Tabellen-Eintrag ":WM_DATA_MOVE" = $EEEE.
;******************************************************************************
:WM_MOVE_ENTRY_T	jsr	WM_GET_ICON_X
			jsr	WM_GET_ICON_Y

			lda	WM_MOVE_MODE		;Scroll-Modus einlesen.
			beq	:moveLineUp		; => Nach oben...
			bmi	:moveLineDown		; => Nach unten...
			jmp	WM_MOVE_POS		;Neue Seite anzeigen.

;--- Nicht verschieben.
::exit			ldx	#$00			; => Keine Daten ausgegeben.
			rts

;--- Nach oben verschieben.
::moveLineUp		lda	WM_DATA_CURENTRY +0
if MAXENTRY16BIT = TRUE
			ora	WM_DATA_CURENTRY +1
endif
			beq	:exit

if MAXENTRY16BIT = TRUE
			lda	WM_DATA_CURENTRY +0
endif
			sec
			sbc	WM_COUNT_ICON_X
			sta	WM_DATA_CURENTRY +0
if MAXENTRY16BIT = TRUE
			lda	WM_DATA_CURENTRY +1
			sbc	#$00
			sta	WM_DATA_CURENTRY +1
endif
			bcc	moveTopOfPage		; => Unterlauf, zum Angang...

			jsr	WM_SAVE_WIN_DATA	;Fensterdaten aktualisieren.
			jsr	moveTextLastLine	;Eine Zeile nach oben scrollen.

			ldx	#$ff			; => Daten ausgegeben.
			rts

;--- Nach unten verschieben.
::moveLineDown		lda	WM_DATA_CURENTRY +0
			clc
			adc	WM_COUNT_ICON_XY
if MAXENTRY16BIT = FALSE
			bcs	:exit			; => Überlauf, Abbruch...
			tax
			cpx	WM_DATA_MAXENTRY +0
endif
if MAXENTRY16BIT = TRUE
			tax
			lda	WM_DATA_CURENTRY +1
			adc	#$00
			bcs	:exit			; => Überlauf, Abbruch...
			cmp	WM_DATA_MAXENTRY +1
			bne	:2
			cpx	WM_DATA_MAXENTRY +0
endif
::2			bcs	:exit			; => Eintrag ungültig, Abbruch...

			stx	r5L			;Nr.Eintrag letzte Zeile speichern.
if MAXENTRY16BIT = TRUE
			sta	r5H
endif

			lda	WM_DATA_CURENTRY +0	;Erster Eintrag der Seite
			clc				;berechnen.
			adc	WM_COUNT_ICON_X
			sta	WM_DATA_CURENTRY +0
if MAXENTRY16BIT = TRUE
			lda	WM_DATA_CURENTRY +1
			adc	#$00
			sta	WM_DATA_CURENTRY +1
endif

			jsr	WM_SAVE_WIN_DATA	;Fensterdaten aktualisieren.
			jsr	moveTextNextLine	;Eine Zeile nach unten scrollen.

			ldx	#$ff			; => Daten ausgegeben.
			rts

;******************************************************************************
;Routine:   moveTextNextLine
;Parameter: WM_WCODE = Fenster-Nr.
;           WM_DATA_BUF = Daten für aktuelles Fenster.
;           r5 = Zeiger auf ersten Eintrag für erste Zeile.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Verschiebt Fensterinhalt um eine Zeile nach oben.
;           Dabei wird direkt ein Teil des Grafik-Bildschirms über
;           ":MoveData" verschoben.
;******************************************************************************
:moveTextNextLine	jsr	setMoveLines		;Anzahl Grafikzeilen berechen.

			lda	windowTop		;Adresse Grafikspeicher berechnen.
			clc
			adc	#$08
			tay
			ldx	leftMargin +0
			lda	leftMargin +1
			jsr	setAdrScrBasePx

			lda	r0L			;Zeiger auf Grafikdaten der
			sta	r1L			;nächsten Zeile berechnen.
			clc
			adc	#< SCRN_XBYTES
			sta	r0L
			lda	r0H
			sta	r1H
			adc	#> SCRN_XBYTES
			sta	r0H

			jsr	setWidthGfxLine		;Breite Grafikzeile berechnen.

;--- Grafikdaten verschieben.
::31			dec	r4H
			beq	:32			; => Ja, weiter...

			jsr	MoveData		;Daten verschieben.

			lda	r0L			;Zeiger auf Grafikdaten der
			sta	r1L			;nächsten Zeile berechnen.
			clc
			adc	#< SCRN_XBYTES
			sta	r0L
			lda	r0H
			sta	r1H
			adc	#> SCRN_XBYTES
			sta	r0H
			jmp	:31

::32			MoveW	r2,r0			;Grafik der letzte Zeile löschen.
			jsr	ClearRam

;--- Neuen Eintrag in letzter Zeile ausgeben.
			lda	windowBottom
			sec
			sbc	#$08 -1
			sta	r1H

			jsr	setXPosLeft

			MoveB	r5L,r0L			;Erster Eintrag in letzter Zeile.
if MAXENTRY16BIT = TRUE
			MoveB	r5H,r0H
endif

			jmp	WM_LINE_OUTPUT		;Zeile ausgeben.

;******************************************************************************
;Routine:   moveTextLastLine
;Parameter: WM_WCODE = Fenster-Nr.
;           WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Verschiebt Fensterinhalt um eine Zeile nach unten.
;           Dabei wird direkt ein Teil des Grafik-Bildschirms über
;           ":MoveData" verschoben.
;******************************************************************************
:moveTextLastLine	jsr	setMoveLines		;Anzahl Grafikzeilen berechen.

			lda	windowBottom		;Adresse Grafikspeicher berechnen.
			and	#%11111000
			sec
			sbc	#$08
			tay
			ldx	leftMargin +0
			lda	leftMargin +1
			jsr	setAdrScrBasePx

			lda	r0L			;Zeiger auf Grafikdaten der
			clc				;nächsten Zeile berechnen.
			adc	#< SCRN_XBYTES
			sta	r1L
			lda	r0H
			adc	#> SCRN_XBYTES
			sta	r1H

			jsr	setWidthGfxLine		;Breite Grafikzeile berechnen.

;--- Grafikdaten verschieben.
::41			dec	r4H			;Erste Zeile verschoben?
			beq	:42			; => Ja, weiter...

			jsr	MoveData		;Daten verschieben.

			lda	r0L
			sta	r1L
			sec
			sbc	#< SCRN_XBYTES
			sta	r0L
			lda	r0H
			sta	r1H
			sbc	#> SCRN_XBYTES
			sta	r0H
			jmp	:41

::42			MoveW	r2,r0			;Grafik der ersten Zeile löschen.
			jsr	ClearRam

;--- Neuen Eintrag in erster Zeile ausgeben.
			lda	windowTop		;Y-Position für Ausgabe der
			clc				;ersten Zeile berechnen.
			adc	#$08
			sta	r1H

			jsr	setXPosLeft

			lda	WM_DATA_CURENTRY +0
			sta	r0L
if MAXENTRY16BIT = TRUE
			lda	WM_DATA_CURENTRY +1
			sta	r0H
endif

			jmp	WM_LINE_OUTPUT		;Zeile ausgeben.

;******************************************************************************
;Routine:   setMoveLines
;Parameter: WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe:  r4H = Anzahl Zeilen in CARDs.
;Verändert: A,X,Y,r0-r15
;Funktion:  Berechnet Anzahl an Grafikzeilen in CARDs.
;******************************************************************************
:setMoveLines		lda	WM_WCODE		;Textbegrenzung setzen.
			jsr	WM_SET_MARGIN

			lda	windowBottom
			sec
			sbc	windowTop
			lsr
			lsr
			lsr
			sta	r4H
			rts

;******************************************************************************
;Routine:   setXPosLeft.
;Parameter: leftMargin = Linker Fensterrand.
;Rückgabe:  r1L = X-Pos in CARDs.
;Verändert: A,r1L
;Funktion:  Berechnet X-Position für ersten Eintrag in nächster Zeile.
;******************************************************************************
:setXPosLeft		lda	leftMargin +1		;X-Position für Ausgabe der
			lsr				;Zeile berechnen.
			lda	leftMargin +0
			ror
			lsr
			lsr
			sta	r1L
			rts

;******************************************************************************
;Routine:   WM_SET_NEW_POS
;Parameter: r0 = Eintrag an erster Stelle.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Zeichnet Einträge an aktueller Position.
;******************************************************************************
:WM_SET_NEW_POS		lda	r0L
			sta	WM_DATA_CURENTRY +0
if MAXENTRY16BIT = TRUE
			ldx	r0H
			stx	WM_DATA_CURENTRY +1
endif

			jsr	WM_SCRBAR_SETPOS	;Scrollbalken aktualisieren.
			jsr	WM_SAVE_WIN_DATA	;Fensterdaten speichern.

			ldx	#$00			;Keine Daten ausgegeben.
			rts

;******************************************************************************
;Routine:   WM_MOVE_POS
;Parameter: WM_WCODE = Fenster-Nr.
;           WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Scrollbalken verschieben.
;******************************************************************************
:WM_MOVE_POS
if MAXENTRY16BIT = TRUE
			lda	SB_MaxEntry +1
			cmp	SB_MaxEPage +1
			bne	:10
endif
			lda	SB_MaxEntry +0
			cmp	SB_MaxEPage +0
::10			bcc	:11

			jsr	WM_SCRBAR_MSEPOS	;Position der Maus ermitteln.

			cmp	#$02			;Auf dem Anzeigebalkens ?
			beq	:moveNewPos		; => Ja, Balken verschieben.

			cmp	#$01			;Oberhalb des Anzeigebalkens ?
			beq	:12			; => Ja, eine Seite zurück.
			cmp	#$03			;Unterhalb des Anzeigebalkens ?
			beq	:14			; => Ja, eine Seite vorwärts.

::11			rts				;Oops... Ende.

::12			jmp	:moveLastPage
::14			jmp	:moveNextPage

;--- Balken verschieben.
::moveNewPos		jsr	WM_SCRBAR_MSTOP		;Mausbewegung einschränken.

::moveNext		jsr	UpdateMouse		;Mausdaten aktualisieren.

			ldx	mouseData		;Maustaste noch gedrückt ?
			bmi	:21			; => Nein, neue Position anzeigen.

			lda	inputData		;Wurde Maus bewegt ?
			beq	:moveNext		; => Nein, keine Bewegung, Schleife.

			jsr	UpdateMouse		;Mausdaten aktualisieren.

			lda	inputData		;Wurde Maus bewegt ?
			beq	:moveNext		; => Nein, keine Bewegung, Schleife.

			cmp	#$06			;Maus nach unten ?
			beq	:moveDown		; => Ja, auswerten.
			cmp	#$02			;Maus nach oben ?
			beq	:moveUp			; => Ja, auswerten.
			bne	:moveNext		; => Nein, Schleife...

;--- Balken neu positionieren.
::21			jsr	:moveToFile		;Position in Dateiliste berechnen.
			ClrB	pressFlag		;Maustastenklick löschen.
			jsr	WM_NO_MOUSE_WIN
			ldx	#$00
			rts

;--- Balken nach oben.
::moveUp		lda	SB_Top			;Am oberen Rand ?
			beq	:moveNext		; =: Ja, Abbruch...
			dec	mouseTop
			dec	mouseBottom
			dec	SB_Top
			dec	SB_End
			jsr	WM_SCRBAR_REDRAW	;Neue Balkenposition ausgeben.
			jmp	:moveNext		;Schleife...

;--- Balken nach unten.
::moveDown		lda	SB_Top
			clc
			adc	SB_Length
			cmp	SB_MaxYlen
			bcs	:moveNext
			inc	mouseTop
			inc	mouseBottom
			inc	SB_Top
			inc	SB_End
			jsr	WM_SCRBAR_REDRAW	;Neue Balkenposition ausgeben.
			jmp	:moveNext		;Schleife...

;--- Mausposition in Listenposition umrechnen.
::moveToFile		lda	SB_Top			;Aktuelle Mausposition in
			sta	r0L			;Position in Tabelle umrechnen.
if MAXENTRY16BIT = TRUE
			lda	#$00
			sta	r0H
endif
			lda	SB_MaxEntry +0
			sec
			sbc	SB_MaxEPage +0
			sta	r11L
if MAXENTRY16BIT = TRUE
			lda	SB_MaxEntry +1
			sbc	SB_MaxEPage +1
			sta	r11H
endif

			ldx	#r0L
			ldy	#r11L
if MAXENTRY16BIT = FALSE
			jsr	BBMult
endif
if MAXENTRY16BIT = TRUE
			jsr	DMult
endif

			lda	SB_End
			sec
			sbc	SB_Top
			sta	r10L
			inc	r10L
			lda	SB_MaxYlen
			sec
			sbc	r10L
			sta	r11L
			lda	#$00
			sta	r11H
			ldx	#r0L
			ldy	#r11L
			jsr	Ddiv
			jmp	WM_SET_NEW_POS

;--- Eine Seite vorwärts.
::moveNextPage		lda	WM_DATA_CURENTRY +0
			clc
			adc	WM_COUNT_ICON_XY
			sta	r0L
if MAXENTRY16BIT = TRUE
			lda	WM_DATA_CURENTRY +1
			adc	#$00
			sta	r0H
endif
			jsr	WM_TEST_CUR_POS
			jmp	:31

;--- Eine Seite zurück.
::moveLastPage		lda	WM_DATA_CURENTRY +0
			sec
			sbc	WM_COUNT_ICON_XY
			sta	r0L
if MAXENTRY16BIT = TRUE
			lda	WM_DATA_CURENTRY +1
			sbc	#$00
			sta	r0H
endif
			bcs	:31
			lda	#$00
			sta	r0L
if MAXENTRY16BIT = TRUE
			sta	r0H
endif
::31			jsr	WM_SET_NEW_POS

			jsr	WM_WAIT_NOMSEKEY	;Warten bis keine M-Taste gedrückt.

			ldx	#$00
			rts

;******************************************************************************
;Routine:   WM_LINE_OUTPUT
;Parameter: WM_WCODE = Fenster-Nr.
;           r0  = Zähler für aktuellen Eintrag.
;           r1L = X-Position für Ausgabe.
;           r1H = Y-Position für Ausgabe.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Standard-Routine zum verschieben von Text-Daten.
;           Wird aufgerufen mit Tabellen-Eintrag ":WM_DATA_MOVE" = $EEEE.
;******************************************************************************
:WM_LINE_OUTPUT		lda	r0L
			sta	CurEntry +0
if MAXENTRY16BIT = TRUE
			lda	r0H
			sta	CurEntry +1
endif

			lda	r1L
			sta	CurXPos
			lda	r1H
			sta	CurYPos

			jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.
			jsr	WM_CALL_GETFILES	;Routine "Dateien laden" aufrufen.
			jsr	WM_SAVE_WIN_DATA	;Fensterdaten speichern.

			jsr	WM_WIN_MARGIN

			jsr	ResetFontGD		;GeoDesk-Zeichensatz aktivieren.

			jsr	WM_GET_GRID_X
			sta	CurGridX
			jsr	WM_GET_GRID_Y
			sta	CurGridY

			lda	rightMargin +1
			lsr
			lda	rightMargin +0
			ror
			lsr
			lsr
			sta	MaxXPos
			inc	MaxXPos

			lda	windowBottom
			sta	MaxYPos

			lda	#$00
			sta	CountX

::1			lda	CurXPos
			cmp	MaxXPos
			bcc	:3
			rts

::3			sta	r1L
			lda	CurYPos
			sta	r1H

			lda	MaxXPos
			sta	r2L
			lda	MaxYPos
			sta	r2H

			lda	CurGridX
			sta	r3L
			lda	CurGridY
			sta	r3H

			lda	CurEntry +0
			sta	r0L
if MAXENTRY16BIT = TRUE
			lda	CurEntry +1
			sta	r0H
endif

			lda	WM_DATA_PRNFILE +0
			ldx	WM_DATA_PRNFILE +1
			jsr	CallRoutine		;Routine zum Ausgeben von Daten.
			txa				;Daten ausgegeben?
			beq	:4			; => Nein, weiter...

			inc	CurEntry +0		;Zeiger auf nächsten Eintrag.
if MAXENTRY16BIT = TRUE
			bne	:4
			inc	CurEntry +1
endif

::4
if MAXENTRY16BIT = TRUE
			lda	CurEntry +1
			cmp	WM_DATA_MAXENTRY +1
			bne	:4a
endif
			lda	CurEntry +0		;Alle Daten ausgegeben?
			cmp	WM_DATA_MAXENTRY +0
::4a			bcs	:6			; => Ja, Ende...

			cpx	#$7f			;Keine weiteren Daten in Zeile?
			beq	:6			; => Ja, Ende...

			lda	CurXPos			;Zeiger auf nächste Spalte.
			clc
			adc	CurGridX
			sta	CurXPos

			inc	CountX

			lda	WM_DATA_COLUMN		;Alle Spalten ausgegeben?
			beq	:5
			lda	CountX
			cmp	WM_DATA_COLUMN
			bcc	:6
::5			jmp	:1			; => Nein, weiter...

::6			rts

;******************************************************************************
;Routine:   WM_CALL_DRAWROUT
;Parameter: WM_WCODE = Fenster-Nr.
;           WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Daten für Fenster ausgeben.
;           $0000 = Keine Daten ausgeben.
;           $FFFF = Standard-Ausgabe, z.B. Dateien.
;******************************************************************************
:WM_CALL_DRAWROUT	lda	WM_DATA_WINPRNT +0
			ldx	WM_DATA_WINPRNT +1
			ldy	WM_WCODE
			cmp	#$ff
			bne	:1
			cpx	#$ff
			beq	WM_STD_OUTPUT
::1			jmp	CallRoutine

;******************************************************************************
;Routine:   WM_STD_OUTPUT
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Daten für Fenster ausgeben.
;******************************************************************************
:WM_STD_OUTPUT		php
			sei				;Interrupt sperren.
			jsr	MouseOff		;Mauszeiger abschalten.

			jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

			jsr	WM_CALL_GETFILES	;Routine "Dateien laden" aufrufen.

			jsr	WM_SAVE_WIN_DATA	;Fensterdaten speichern.

			jsr	ResetFontGD		;GeoDesk-Zeichensatz aktivieren.

			jsr	WM_TEST_WIN_POS		;Erster Eintrag gültig?
			jsr	InitFPosData		;Daten für Ausgabe initialisieren.

			lda	WM_DATA_MAXENTRY +0
if MAXENTRY16BIT = TRUE
			ora	WM_DATA_MAXENTRY +1
endif
			beq	:end_output		;Daten vorhanden? => Nein, Ende...

::next_column		lda	CurXPos			;Aktuelle X-Position innerhalb
			cmp	MaxXPos			;des gültigen Bereichs?
			bcc	:3			; => Ja, weiter...

::reset_column		jsr	restColumnData		;Spaltendaten zurücksetzen.
			bcc	:next_row		; => Nächste Zeile, weiter...
::end_output		plp				;Interrupt-Status zurücksetzen.
			jmp	MouseUp			;Mauszeiger einschalten, Ende...

::next_row		sta	CurYPos			;Neue Y-Position speichern.
			inc	CountY			;Zähler für Zeilen korrigieren.

			ldx	WM_DATA_ROW		;Anzahl Zeilen begrenzt?
			beq	:2b			; => Nein, weiter...
			cmp	WM_DATA_ROW		;Max. Anzahl Zeilen erreicht?
			bcs	:end_output		; => Ja, Ende...

::2b			lda	CurXPos
::3			jsr	setEntryData		;Daten für aktuellen Eintrag setzen.

			lda	CurEntry +0		;Zeiger auf aktuellen Eintrag.
			sta	r0L
if MAXENTRY16BIT = TRUE
			lda	CurEntry +1
			sta	r0H
endif

			lda	WM_DATA_PRNFILE +0
			ldx	WM_DATA_PRNFILE +1
			jsr	CallRoutine		;Nächsten Eintrag ausgeben.
			txa				;Wurde Eintrag ausgegeben?
			beq	:4			; => Nein, weiter...

			inc	CurEntry +0		;Zähler auf nächsten Eintrag.
if MAXENTRY16BIT = TRUE
			bne	:4
			inc	CurEntry +1
endif

::4
if MAXENTRY16BIT = TRUE
			lda	CurEntry +1
			cmp	WM_DATA_MAXENTRY +1
			bne	:4a
endif
			lda	CurEntry +0
			cmp	WM_DATA_MAXENTRY +0
::4a			bcs	:end_output		; => Weitere Einträge ausgeben.

			cpx	#$7f			;War Eintrag im sichtbaren Bereich?
			beq	:5a			; => Nein, Eintrag in nächster
							;    Zeile darstellen.

			jsr	setNextColumn		;X-Position für nächsten Eintrag.

			lda	WM_DATA_COLUMN		;Max. Anzahl Spalten definiert?
			beq	:5			; => Nein, weiter...
			lda	CountX
			cmp	WM_DATA_COLUMN		;Max. Anzahl Spalten erreicht?
			bcc	:5a			; => Nein, weiter...

::5			jmp	:next_column		;Nächste Spalte.
::5a			jmp	:reset_column		;Nächste Zeile.

;*** Spaltenwerte zurücksetzen.
;    Rückgabe: C-Flag = 1, keine weitere Zeile möglich.
;    Wird auch von der Dateiauswahl verwendet.
:restColumnData		lda	#$00			;Zähler zurücksetzen.
			sta	CountX

			lda	MinXPos			;X-Position auf Anfang.
			sta	CurXPos

			lda	CurYPos			;Zeiger auf nächste Zeile.
			clc
			adc	CurGridY		;Neue Y-Position innerhalb
			cmp	MaxYPos			;des gültigen Bereichs?
			rts

;*** Daten für Eintrag setzen.
;    Übergabe: AKKU = Aktuelle X-Position.
;    Wird auch von der Dateiauswahl verwendet.
:setEntryData		sta	r1L			;Aktuelle X-Position setzen.
			lda	CurYPos
			sta	r1H			;Aktuelle Y-Position setzen.

			lda	MaxXPos			;Max. X-Position setzen.
			sta	r2L
			lda	MaxYPos			;Max. Y-Position setzen.
			sta	r2H

			lda	CurGridX		;X-Abstand setzen.
			sta	r3L
			lda	CurGridY		;Y-Abstand setzen.
			sta	r3H
			rts

;*** Zeiger auf nächste Spalte.
;    Wird auch von von Dateiauswahl verwendet.
:setNextColumn		lda	CurXPos			;X-Position für nächsten Eintrag.
			clc
			adc	CurGridX
			sta	CurXPos

			inc	CountX			;Zähler für Spalte korrigieren.
			rts

;******************************************************************************
;Routine:   InitFPosData
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Daten für Fenster ausgeben.
;******************************************************************************
:InitFPosData		jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

			jsr	WM_WIN_MARGIN		;Grenzen für Textausgabe setzen.

			jsr	WM_GET_GRID_X		;Spaltenabstand berechnen.
			sta	CurGridX
			jsr	WM_GET_GRID_Y		;Zeilenabstand berechnen.
			sta	CurGridY

			lda	leftMargin +1		;Anfang für X-Position berechnen.
			lsr
			lda	leftMargin +0
			ror
			lsr
			lsr
			sta	MinXPos
			sta	CurXPos

			lda	rightMargin +1		;Max. X-Position berechnen.
			lsr
			lda	rightMargin +0
			ror
			lsr
			lsr
			sta	MaxXPos
			inc	MaxXPos

			lda	windowTop		;Anfang für Y-Position berechnen.
			clc
			adc	#$08
			sta	MinYPos
			sta	CurYPos

			lda	windowBottom		;Max. Y-Position berechnen.
			sta	MaxYPos

			lda	WM_DATA_CURENTRY +0
			sta	CurEntry +0
if MAXENTRY16BIT = TRUE
			lda	WM_DATA_CURENTRY +1
			sta	CurEntry +1		;Zeiger auf aktuellen Eintrag.
endif

			lda	#$00			;Spalten-/Zeilenzähler löschen.
			sta	CountX
			sta	CountY
			rts
