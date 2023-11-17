; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
;Routine  : WM_CLEAR_SCREEN
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Löscht alle Fenster vom Bildschirm und
;           stellt den Hintergrundbildschirm dar.
;
.WM_CLEAR_SCREEN	= GetBackScreen

if FALSE
			lda	#ST_WR_FORE
			sta	dispBufferOn

			lda	sysRAMFlg
			and	#%00001000		;Hintergrundbild aktiv ?
			beq	:1			; => Nein, weiter...

;--- MegaPatch Hintergrundbild laden.
			jmp	GetBackScreen		;Hintergrundbild laden.

;--- DeskTop-Muster anzeigen.
::1			lda	C_GDESK_PATTERN		;GeoDesk-Füllmuster setzen.
			jsr	SetPattern

			jsr	WM_SET_SCR_SIZE		;Max. Bildschirm-Koordinaten setzen.

			lda	C_GDesk_DeskTop
			jsr	DirectColor		;Farben löschen.

			jmp	Rectangle		;Grafik löschen.
endif

;
;Routine  : WM_SAVE_SCREEN
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe : -
;Verändert: A,X,Y,r0-r4
;Funktion : Speichert Bildschirm-Inhalt für
;           Fenster in ScreenBuffer.
;
.WM_SAVE_SCREEN		lda	#$90			;Job-Code für ":StashRAM"
			b $2c

;
;Routine  : WM_LOAD_SCREEN
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe : -
;Verändert: A,X,Y,r0-r4
;Funktion : Lädt Bildschirm-Inhalt für
;           Fenster aus ScreenBuffer.
;
.WM_LOAD_SCREEN		lda	#$91			;Job-Code für ":FetchRAM"
			sta	DataJobCode		;Aktuellen Job-Code speichern.

			php				;Interrupt sperren.
			sei

			lda	dispBufferOn		;Bildschirmflag retten und
			pha				;Grafik nur in Vordergrund.
			lda	#ST_WR_FORE
			sta	dispBufferOn

			lda	r10H			;r10/r11 sichern.
			pha
			lda	r10L
			pha
			lda	r11H
			pha
			lda	r11L
			pha

			lda	WM_WCODE		;Zeiger auf Speicherbereich im
			asl				;ScreenBuffer für aktuelles
			tay				;Fenster.
			lda	ScrBufAdrGrfx +0,y
			sta	r10L
			lda	ScrBufAdrGrfx +1,y
			sta	r10H
			lda	ScrBufAdrCols +0,y
			sta	r11L
			lda	ScrBufAdrCols +1,y
			sta	r11H

			jsr	WM_GET_SLCT_SIZE	;Aktuelle Fenstergröße ermitteln.

			lda	GD_SCRN_STACK		;Speicherbank für ScreenBuffer.
			jsr	DoScrnBufJob		;Bildschirm speichern.

			pla				;r10/r11 zurücksetzen.
			sta	r11L
			pla
			sta	r11H
			pla
			sta	r10L
			pla
			sta	r10H

			pla
			sta	dispBufferOn		;Bildschirmflag zurücksetzen.

			plp				;IRQ-Status zurücksetzen.

			lda	#$ff			;Werte für Delta X/Y des
			sta	DB_DELTA_Y		;aktuellen Fensters löschen.
			sta	DB_DELTA_X
			rts

;*** Tabelle der Anfangsadressen für
;    Grafikspeicher des aktuellen
;    Fensters.
:ScrBufAdrGrfx		w $0000
			w 8192 *1
			w 8192 *2
			w 8192 *3
			w 8192 *4
			w 8192 *5
			w 8192 *6

;*** Tabelle der Anfangsadressen für
;    Farbspeicher des aktuellen
;    Fensters.
:ScrBufAdrCols		w 8192 *7 +1024*0
			w 8192 *7 +1024*1
			w 8192 *7 +1024*2
			w 8192 *7 +1024*3
			w 8192 *7 +1024*4
			w 8192 *7 +1024*5
			w 8192 *7 +1024*6

;
;Routine  : WM_SAVE_AREA
;Parameter: AKKU = 64K-Speicherbank ScreenBuffer.
;           r2L  = Y-Koordinate/oben in Pixel.
;           r2H  = Y-Koordinate/unten in Pixel.
;           r3   = X-Koordinate/links in Pixel.
;           r4   = X-Koordinate/rechts in Pixel.
;           r10  = Zeiger auf Grafikdaten in ScreenBuffer.
;           r11  = Zeiger auf Farbdaten in ScreenBuffer.
;Rückgabe : -
;Verändert: A,X,Y,r0-r4
;Funktion : Speichert Bildschirm-Inhalt für DialogBox in ScreenBuffer.
;
;Hinweis:
;Einsprungsadresse wird aktuell
;nicht verwendet.
;
::WM_SAVE_AREA		ldy	#$90			;Job-Code für ":StashRAM"
			b $2c

;
;Routine  : WM_LOAD_AREA
;Parameter: AKKU = 64K-Speicherbank ScreenBuffer.
;           r2L  = Y-Koordinate/oben in Pixel.
;           r2H  = Y-Koordinate/unten in Pixel.
;           r3   = X-Koordinate/links in Pixel.
;           r4   = X-Koordinate/rechts in Pixel.
;           r10  = Zeiger auf Grafikdaten in ScreenBuffer.
;           r11  = Zeiger auf Farbdaten in ScreenBuffer.
;Rückgabe : -
;Verändert: A,X,Y,r0-r4
;Funktion : Restauriert Bildschirm-Inhalt für DialogBox aus ScreenBuffer.
;
.WM_LOAD_AREA		ldy	#$91			;Job-Code für ":FetchRAM"
			sty	DataJobCode		;Aktuellen Job-Code speichern.
			tax
			php
			sei

			lda	dispBufferOn		;Bildschirmflag retten und
			pha				;Grafik nur in Vordergrund.
			lda	#ST_WR_FORE
			sta	dispBufferOn

			txa
			jsr	DoScrnBufJob		;Bildschirm-Inhalt laden/speichern.

			pla
			sta	dispBufferOn		;Bildschirmflag zurücksetzen.
			plp

			lda	#$ff			;Werte für Delta X/Y des
			sta	DB_DELTA_Y		;aktuellen Fensters löschen.
			sta	DB_DELTA_X
			rts

;
;Routine  : DoScrnBufJob
;Parameter: AKKU = 64K-Speicherbank ScreenBuffer.
;           r2L  = Y-Koordinate/oben in Pixel.
;           r2H  = Y-Koordinate/unten in Pixel.
;           r3   = X-Koordinate/links in Pixel.
;           r4   = X-Koordinate/rechts in Pixel.
;           r10  = Zeiger auf Grafikdaten in ScreenBuffer.
;           r11  = Zeiger auf Farbdaten in ScreenBuffer.
;Rückgabe : -
;Verändert: A,X,Y,r0-r4
;Funktion : Speichert Bildschirm-Inhalt für DialogBox in ScreenBuffer.
;
:DoScrnBufJob		sta	DataBank

			lda	r3H			;Linken Rand der Dialogbox in Cards
			lsr				;berechnen.
			lda	r3L
			and	#%11111000
			sta	r3L
			ror
			lsr
			lsr
			sta	RX_Margin_Left
			ldx	DB_DELTA_X
			cpx	#$ff
			beq	:1
			txa
::1			sta	DB_Margin_Left		;Linker Rand in Cards.

			lda	r2L			;Oberen Rand der Dialogbox in Cards
			lsr				;berechnen.
			lsr
			lsr
			sta	RX_Margin_Top
			ldx	DB_DELTA_Y
			cpx	#$ff			;Delta-Y verwenden?
			beq	:2			; => Nein, weiter...
			txa
::2			sta	DB_Margin_Top		;Oberer Rand in Cards.

			lda	r2H			;Höhe der Dialogbox in Cards
			lsr				;berechnen.
			lsr
			lsr
			sec
			sbc	RX_Margin_Top
			clc
			adc	#$01
			sta	CountLines		;Anzahl Card-Zeilen.

			lda	r4L			;Breite der Dialogbox in Pixel
			ora	#%00000111		;berechnen.
			sta	r4L
			sec
			sbc	r3L
			sta	r0L
			lda	r4H
			sbc	r3H
			sta	r0H			;Anzahl Pixel-Spalten.

			inc	r0L			;Anzahl Pixel-Spalten +1.
			bne	:3
			inc	r0H

::3			lda	r0L			;Anzahl Pixel in Zwischenspeicher.
			sta	GrfxDataBytes +0
			lda	r0H
			sta	GrfxDataBytes +1

			ldx	#r0L			;Bytes in Cards umrechnen.
			ldy	#$03
			jsr	DShiftRight

			lda	r0L			;Anzahl Cards in Zwischenspeicher.
			sta	ColsDataBytes

::4			jsr	DefCurLineCols		;Zeiger auf Farbdaten berechnen.

			ldy	DataJobCode		;Job-Code einlesen und
			jsr	DoRAMOp			;Daten speichern/einlesen.

			jsr	DefCurLineGrfx		;Zeiger auf Grafikdaten berechnen.

			ldy	DataJobCode		;Job-Code einlesen und
			jsr	DoRAMOp			;Daten speichern/einlesen.

			inc	DB_Margin_Top		;Zeiger auf nächste Zeile.
			inc	RX_Margin_Top		;Zeiger auf nächste Zeile.
			dec	CountLines		;Zähler korrigieren.
			bne	:4			;Box weiter bearbeiten.

::5			rts

;*** Variablen.
:DataJobCode		b $00
:DB_Margin_Left		b $00
:DB_Margin_Top		b $00
:RX_Margin_Left		b $00
:RX_Margin_Top		b $00
:CountLines		b $00
:ColsDataBytes		b $00
:GrfxDataBytes		w $0000
:DB_DELTA_Y		b $ff
:DB_DELTA_X		b $ff
:DataBank		b $00

;
;Routine  : DefCurLineGrfx
;Parameter: DataBank = 64K-Speicherbank ScreenBuffer.
;           DB_Margin_Top = Zeile in Cards.
;           r2H  = Y-Koordinate/unten in Pixel.
;           r3   = X-Koordinate/links in Pixel.
;           r4   = X-Koordinate/rechts in Pixel.
;           r10  = Zeiger auf Grafikdaten in ScreenBuffer.
;Rückgabe : -
;Verändert: A,X,Y,r0-r4
;Funktion : Daten für aktuelle Grafikzeile definieren.
;
:DefCurLineGrfx		ldx	DB_Margin_Left		;Adresse Grafikspeicher im RAM.
			ldy	DB_Margin_Top
			jsr	setAdrScrBase

			ldx	RX_Margin_Left		;Adresse Grafikspeicher in REU.
			ldy	RX_Margin_Top
			lda	scrBufLine_L  ,y
			clc
			adc	scrBufColumn_L,x
			sta	r1L
			lda	scrBufLine_H  ,y
			adc	scrBufColumn_H,x
			sta	r1H

			lda	r1L
			clc
			adc	r10L
			sta	r1L
			lda	r1H
			adc	r10H
			sta	r1H

			lda	GrfxDataBytes +0	;Anzahl Grafikbytes festlegen.
			sta	r2L
			lda	GrfxDataBytes +1
			sta	r2H

			lda	DataBank		;ScreenBuffer-Bank in REU festlegen.
			sta	r3L
			rts

;*** Startadressen der Grafikzeilen.
:scrBufLine_L		b <  0*8*40,<  1*8*40,<  2*8*40,<  3*8*40
			b <  4*8*40,<  5*8*40,<  6*8*40,<  7*8*40
			b <  8*8*40,<  9*8*40,< 10*8*40,< 11*8*40
			b < 12*8*40,< 13*8*40,< 14*8*40,< 15*8*40
			b < 16*8*40,< 17*8*40,< 18*8*40,< 19*8*40
			b < 20*8*40,< 21*8*40,< 22*8*40,< 23*8*40
			b < 24*8*40

:scrBufLine_H		b >  0*8*40,>  1*8*40,>  2*8*40,>  3*8*40
			b >  4*8*40,>  5*8*40,>  6*8*40,>  7*8*40
			b >  8*8*40,>  9*8*40,> 10*8*40,> 11*8*40
			b > 12*8*40,> 13*8*40,> 14*8*40,> 15*8*40
			b > 16*8*40,> 17*8*40,> 18*8*40,> 19*8*40
			b > 20*8*40,> 21*8*40,> 22*8*40,> 23*8*40
			b > 24*8*40

;*** Startadressen der Grafikspalten.
:scrBufColumn_L		b < 8 * 0 ,< 8 * 1 ,< 8 * 2 ,< 8 * 3
			b < 8 * 4 ,< 8 * 5 ,< 8 * 6 ,< 8 * 7
			b < 8 * 8 ,< 8 * 9 ,< 8 * 10,< 8 * 11
			b < 8 * 12,< 8 * 13,< 8 * 14,< 8 * 15
			b < 8 * 16,< 8 * 17,< 8 * 18,< 8 * 19
			b < 8 * 20,< 8 * 21,< 8 * 22,< 8 * 23
			b < 8 * 24,< 8 * 25,< 8 * 26,< 8 * 27
			b < 8 * 28,< 8 * 29,< 8 * 30,< 8 * 31
			b < 8 * 32,< 8 * 33,< 8 * 34,< 8 * 35
			b < 8 * 36,< 8 * 37,< 8 * 38,< 8 * 39

:scrBufColumn_H		b > 8 * 0 ,> 8 * 1 ,> 8 * 2 ,> 8 * 3
			b > 8 * 4 ,> 8 * 5 ,> 8 * 6 ,> 8 * 7
			b > 8 * 8 ,> 8 * 9 ,> 8 * 10,> 8 * 11
			b > 8 * 12,> 8 * 13,> 8 * 14,> 8 * 15
			b > 8 * 16,> 8 * 17,> 8 * 18,> 8 * 19
			b > 8 * 20,> 8 * 21,> 8 * 22,> 8 * 23
			b > 8 * 24,> 8 * 25,> 8 * 26,> 8 * 27
			b > 8 * 28,> 8 * 29,> 8 * 30,> 8 * 31
			b > 8 * 32,> 8 * 33,> 8 * 34,> 8 * 35
			b > 8 * 36,> 8 * 37,> 8 * 38,> 8 * 39

;
;Routine  : setAdrScrBasePx
;Parameter: XREG/AKKU = XPos in Pixel.
;           YREG = YPos in Pixel.
;Rückgabe : r0 = Zeiger auf Grafikspeicher.
;Verändert: A,X,Y,r0
;Funktion : Berechnet Adresse im Grafikspeicher.
;
:setAdrScrBasePx	lsr
			txa
			ror
			lsr
			lsr
			tax
			tya
			lsr
			lsr
			lsr
			tay

;
;Routine  : setAdrScrBase
;Parameter: XREG = XPos in CARDs.
;           YREG = YPos in CARDs.
;Rückgabe : r0 = Zeiger auf Grafikspeicher.
;Verändert: A,r0
;Funktion : Berechnet Adresse im Grafikspeicher.
;
:setAdrScrBase		lda	scrBufLine_L  ,y
			clc
			adc	scrBufColumn_L,x
			sta	r0L
			lda	scrBufLine_H  ,y
			adc	scrBufColumn_H,x
			sta	r0H

			lda	r0L
			clc
			adc	#< SCREEN_BASE
			sta	r0L
			lda	r0H
			adc	#> SCREEN_BASE
			sta	r0H

			rts

;
;Routine  : setWidthGfxLine
;Parameter: leftmargin  = Linker Rand.
;           rightmargin = Rechter Rand.
;Rückgabe : r2 = Breite in Bytes.
;Verändert: A,r2
;Funktion : Breite Grafikzeile berechnen.
;
:setWidthGfxLine	lda	rightMargin +0
			sec
			sbc	 leftMargin +0
			sta	r2L
			lda	rightMargin +1
			sbc	 leftMargin +1
			sta	r2H

			inc	r2L
			bne	:1
			inc	r2H
::1			rts

;
;Routine  : DefCurLineCols
;Parameter: DataBank = 64K-Speicherbank ScreenBuffer.
;           r2L  = Y-Koordinate/oben in Pixel.
;           r2H  = Y-Koordinate/unten in Pixel.
;           r3   = X-Koordinate/links in Pixel.
;           r4   = X-Koordinate/rechts in Pixel.
;           r10  = Zeiger auf Grafikdaten in ScreenBuffer.
;Rückgabe : -
;Verändert: A,X,Y,r0-r4
;Funktion : Daten für aktuelle Farbzeile definieren.
;
:DefCurLineCols		ldx	DB_Margin_Left		;Zeiger auf Farbspalte
			ldy	DB_Margin_Top		;Zeiger auf Farbzeile
			jsr	setAdrColBase
if FALSE
			ldx	DB_Margin_Top		;Zeiger auf Farbzeile
			lda	colorBuf_L,x		;berechnen.
			clc
			adc	#< COLOR_MATRIX
			sta	r0L
			lda	colorBuf_H,x
			adc	#> COLOR_MATRIX
			sta	r0H

			lda	DB_Margin_Left		;Zeiger auf Farbspalte
			clc				;berechnen.
			adc	r0L
			sta	r0L
			lda	#$00
			adc	r0H
			sta	r0H
endif

			ldx	RX_Margin_Top		;Zeiger auf Farbzeile in
			lda	colorBuf_L,x		;ScreenBuffer berechnen.
			clc
			adc	r11L
			sta	r1L
			lda	colorBuf_H,x
			adc	r11H
			sta	r1H

			lda	RX_Margin_Left		;Zeiger auf Farbspalte in
			clc				;ScreenBuffer berechnen.
			adc	r1L
			sta	r1L
			lda	#$00
			adc	r1H
			sta	r1H

			lda	ColsDataBytes		;Anzahl Farbbytes festlegen.
			sta	r2L
			lda	#$00
			sta	r2H

			lda	DataBank		;ScreenBuffer-Bank in REU festlegen.
			sta	r3L
			rts

;*** Startadressen der Farbzeilen.
.colorBuf_L		b <  0*40,<  1*40,<  2*40,<  3*40
			b <  4*40,<  5*40,<  6*40,<  7*40
			b <  8*40,<  9*40,< 10*40,< 11*40
			b < 12*40,< 13*40,< 14*40,< 15*40
			b < 16*40,< 17*40,< 18*40,< 19*40
			b < 20*40,< 21*40,< 22*40,< 23*40
			b < 24*40

.colorBuf_H		b >  0*40,>  1*40,>  2*40,>  3*40
			b >  4*40,>  5*40,>  6*40,>  7*40
			b >  8*40,>  9*40,> 10*40,> 11*40
			b > 12*40,> 13*40,> 14*40,> 15*40
			b > 16*40,> 17*40,> 18*40,> 19*40
			b > 20*40,> 21*40,> 22*40,> 23*40
			b > 24*40

;
;Routine  : setAdrColrBasePx
;Parameter: XREG/AKKU = XPos in Pixel.
;           YREG = YPos in Pixel.
;Rückgabe : r0 = Zeiger auf Farbspeicher.
;Verändert: A,X,Y,r0
;Funktion : Berechnet Adresse im Farbspeicher.
;
if FALSE
;--- Hinweis:
;Wird aktuell nicht verwendet.
:setAdrColBasePx	lsr
			txa
			ror
			lsr
			lsr
			tax
			tya
			lsr
			lsr
			lsr
			tay
endif

;
;Routine  : setAdrColBase
;Parameter: XREG = XPos in CARDs.
;           YREG = YPos in CARDs.
;Rückgabe : r0 = Zeiger auf Farbspeicher.
;Verändert: A,r0
;Funktion : Berechnet Adresse im Farbspeicher.
;
:setAdrColBase		txa
			clc
			adc	colorBuf_L,y
			sta	r0L
			lda	#$00
			adc	colorBuf_H,y
			sta	r0H

			lda	r0L
			clc
			adc	#< COLOR_MATRIX
			sta	r0L
			lda	r0H
			adc	#> COLOR_MATRIX
			sta	r0H

			rts

;
;Routine  : setWidthColLine
;Parameter: leftmargin  = Linker Rand.
;           rightmargin = Rechter Rand.
;Rückgabe : r2 = Breite in Bytes.
;Verändert: A,r2
;Funktion : Breite Farbzeile berechnen.
;
if FALSE
;--- Hinweis:
;Wird aktuell nicht verwendet.
;
:setWidthColLine	jsr	setWidthGfxLine

			ldx	#r2
			ldy	#$03
			jmp	DShiftRight
endif
