; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Desktop/Applinks zeichnen.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_GEXT"
			t "SymbTab_1"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
;			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
			t "s.GD.20.WM.ext"
			t "s.GD.21.Desk.ext"

;--- AppLink-Definition.
			t "e.GD.10.AppLink"
endif

;*** GEOS-Header.
			n "obj.GD25"
			f DATA

			o BASE_GDMENU

;*** Sprungtabelle.
;:MAININIT		jmp	DrawDeskTop

;*** Desktop zeichnen.
:DrawDeskTop		bit	r10L			;Desktop neu zeichnen?
			bmi	:1			; => Nein, Update...
			bvs	:updappl		; => Fenster-Modus ignorieren.

			bit	GD_HIDEWIN_MODE		;Fenster ausgeblendet?
			bpl	:redraw			; => Nein, neu zeichnen.

::1			jsr	WM_DRAW_BACKSCR		;Desktop zeichen,
			jsr	GD_INITCLOCK		;Uhrzeit aktualisieren und
			jmp	:update			;Fenster aus ScreenBuffer laden.

::redraw		lda	#$00			;Alle Fenster anzeigen.
			sta	GD_HIDEWIN_MODE

::updappl		jsr	WM_CLEAR_SCREEN		;Bildschirm löschen.

			jsr	InitTaskBar		;TaskBar darstellen.

			jsr	doGetDevTypes		;Laufwerkstypen einlesen.
			jsr	SUB_SYSINFO		;Systeminfo anzeigen.

::update		jsr	DrawAppLinks		;AppLinks zeichnen.

			jsr	InitWinMseKbd		;Fenster-/Maus-/Tastatur starten.

			lda	#$00			;DeskTop als aktives Fenster setzen.
			sta	WM_WCODE

			jmp	WM_SAVE_SCREEN		;Bildschirminhalt speichern.

;*** AppLinks auf DeskTop ausgeben.
:DrawAppLinks		jsr	ResetFontGD		;GeoDesk-Font aktivieren.

			jsr	initALDataVec		;AppLink-Register initialisieren.

::1			jsr	MAIN_RESETAREA		;Fenstergrenzen löschen.

			jsr	getALIconSize		;Position/Größe für Icon.

			lda	#$00			;Bildschirm-Bereich für
			jsr	SetPattern		;Icon löschen.
			jsr	Rectangle

			bit	GD_LNK_TITLE		;AppLink-Titel anzeigen?
			bpl	:2			; => Nein, weiter...

			ldx	#0			;Position/Größe für Icon speichern.
::svzp			lda	r2,x
			pha
			inx
			cpx	#6
			bcc	:svzp

			ldx	r2H			;Position/Größe für Titel
			inx				;berechnen.
			stx	r2L
			txa
			clc
			adc	#$07
			sta	r2H

			lda	r3L
			sec
			sbc	#< 16
			sta	r3L
			sta	leftMargin +0
			lda	r3H
			sbc	#> 16
			sta	r3H
			sta	leftMargin +1

			lda	r4L
			clc
			adc	#< 16
			sta	r4L
			sta	rightMargin +0
			lda	r4H
			adc	#> 16
			sta	r4H
			sta	rightMargin +1

			lda	#$00			;Bildschirm-Bereich für
			jsr	SetPattern		;AppLink-Titel löschen.
			jsr	Rectangle
			lda	C_GDesk_ALTitle		;Farben für AppLink-Titel auf
			jsr	DirectColor		;Bildschirm löschen.

			ldx	#6 -1			;Position/Größe für Icon wieder
::ldzp			pla				;herstellen.
			sta	r2,x
			dex
			bpl	:ldzp

::2			lda	r15L			;Zeiger auf Speicher für
			sta	r0L			;AppLink-Icon.
			lda	r15H
			sta	r0H

			jsr	WM_CONVERT_PIXEL	;Koordinate von Pixel nach CARDs.

			lda	#3			;Breite Icon in CARDs.
			sta	r2L
			lda	#21			;Höhe Icon in Pixel.
			sta	r2H
;			lda	#$00			;Farbe für Icon.
;			sta	r3L
			lda	#5			;Delta-Y für Titel.
			sta	r3H

;--- Farbe für Icon definieren.
			ldy	#LINK_DATA_TYPE		;AppLink-Typ einlesen.
			lda	(r14L),y
;			cmp	#AL_TYPE_FILE		;Datei-Icon/Anwendung?
			beq	:9			; => Ja, weiter...

			cmp	#AL_TYPE_MYCOMP		;Arbeitsplatz-Icon?
			beq	:7			; => Ja, weiter...

;--- Laufwerk/Drucker/Verzeichnis.
			lda	r14L			;Zeiger auf Farbtabelle in
			clc				;AppLink-Daten berechnen.
			adc	#< LINK_DATA_COLOR
			sta	r8L
			lda	r14H
			adc	#> LINK_DATA_COLOR
			sta	r8H

			lda	#$00			;Farbe über AppLink setzen.
			beq	:8

;--- Arbeitsplatz-Icon.
::7			lda	C_GDesk_MyComp		;Farbe aus Systemvorgaben setzen.
			jmp	:8

;--- Datei-Icon.
::9			lda	C_GDesk_ALIcon		;Farbe aus Systemvorgaben setzen.

;--- Allgemein: Farbmodus festlegen.
::8			sta	r3L			;Typ der AppLink-Farbe definieren.

			lda	r14L			;Zeiger auf Titel in
			clc				;AppLink-Daten berechnen.
			adc	#17
			sta	r4L
			lda	r14H
			adc	#$00
			sta	r4H

			lda	r1L			;Position für Icon speichern.
			pha
			lda	r1H
			pha

			bit	GD_LNK_TITLE		;AppLink-Titel anzeigen?
			bpl	:3			; => Nein, weiter...

			jsr	GD_FICON_NAME		;Icon und Titel ausgeben.
			jmp	:4

::3			jsr	GD_DRAW_FICON		;Nur Icon ausgeben.

::4			pla				;Position für Icon zurücksetzen.
			sta	r1H
			pla
			sta	r11L

			ldy	#LINK_DATA_TYPE
			lda	(r14L),y		;AppLink-Typ einlesen.
			cmp	#AL_TYPE_DRIVE		;Laufwerk?
			bne	:5			; => Nein, weiter...

			ldy	#LINK_DATA_DRIVE	;Laufwerksbuchstabe auf
			lda	(r14L),y		;AppLink-Icon schreiben.
			sec
			sbc	#$08
			jsr	PrntGeosDrvName		;Laufwerk A: bis D: ausgeben.

::5			jsr	setVecNxALEntry		;Zeiger auf nächste AppLink-Daten.

			dec	AL_CNT_ENTRY		;Alle AppLinks ausgegeben?
			beq	:6			; => Ja, Ende...
			jmp	:1			; => Nein, weiter...
::6			rts

;*** Laufwerkstypen einlesen.
;    Übergabe: YREG =  Laufwerksadresse.
;    Rückhabe: r0 = Zeiger auf Laufwerkstext.
:doGetDevTypes		ldx	#8
::1			stx	r1L

			lda	:gd_bufadr_lo -8,x
			sta	r2L
			lda	:gd_bufadr_hi -8,x
			sta	r2H

			lda	#< :names
			sta	r0L
			lda	#> :names
			sta	r0H

			ldy	#0			;Laufwerkstyp in Tabelle suchen.
::2			lda	RealDrvType -8,x	;Laufwerkstyp einlesen.
			cmp	:types,y
			beq	:3

			lda	r0L
			clc
			adc	#< 17
			sta	r0L
			lda	r0H
			adc	#> 17
			sta	r0H

			iny
			cpy	#:types_count		;Alle Laufwerkstypen durchsucht?
			bcc	:2			; => Nein, weiter...

			lda	#<:unknown
			ldy	#>:unknown
			bne	:4			; => Unbekanntes Laufwerk.

::3			cmp	#NULL			;Kein Laufwerk?
			beq	:5			; => Ja, Ende...
			cmp	#$04			;1541-1581?
			bcs	:5			; => Nein, weiter...

			lda	RealDrvMode -8,x
			and	#SET_MODE_SD2IEC	;SD2IEC-Laufwerk?
			beq	:5			; => nein, weiter...

;--- Sonderbehandlung für SD2IEC mit 1541/71/81-Treiber.
			lda	#<:nameSD41
			ldy	#>:nameSD41
			cpx	#Drv1541
			beq	:4
			lda	#<:nameSD71
			ldy	#>:nameSD71
			cpx	#Drv1571
			beq	:4
			lda	#<:nameSD81
			ldy	#>:nameSD81

::4			sta	r0L			;Zeiger auf Laufwerkstext
			sty	r0H			;für SD41/71/81-Laufwerk.

::5			ldy	#16
::6			lda	(r0L),y
			sta	(r2L),y
			dey
			bpl	:6

			ldx	r1L
			inx
			cpx	#12
			bcc	:1

			rts

::gd_bufadr_lo		b < GD_DRVTYPE_A
			b < GD_DRVTYPE_B
			b < GD_DRVTYPE_C
			b < GD_DRVTYPE_D
::gd_bufadr_hi		b > GD_DRVTYPE_A
			b > GD_DRVTYPE_B
			b > GD_DRVTYPE_C
			b > GD_DRVTYPE_D

;*** Tabelle mit Laufwerkstypen.
::types			b $00,$01,$41,$02,$03,$05
			b $81,$82,$83,$84
			b $c4,$a4,$b4
			b $31,$32,$33,$34
			b $11,$12,$13,$14,$15
			b $21,$22,$23,$24
			b $04
::types_end
::types_count		= (:types_end - :types)

;*** Texte für Laufwerkstypen.
::names
if LANG = LANG_DE
			b "Kein Laufwerk"
endif
if LANG = LANG_EN
			b "No drive"
endif
			e :names + 1*17
			b "C=1541"
			e :names + 2*17
			b "C=1541 (Cache)"
			e :names + 3*17
			b "C=1571"
			e :names + 4*17
			b "C=1581"
			e :names + 5*17
			b "C=1581/DOS"
			e :names + 6*17
			b "RAM 1541"
			e :names + 7*17
			b "RAM 1571"
			e :names + 8*17
			b "RAM 1581"
			e :names + 9*17
			b "RAM Native"
			e :names +10*17
			b "SRAM Native"
			e :names +11*17
			b "CREU Native"
			e :names +12*17
			b "GRAM Native"
			e :names +13*17
			b "CMD RL41"
			e :names +14*17
			b "CMD RL71"
			e :names +15*17
			b "CMD RL81"
			e :names +16*17
			b "CMD RLNative"
			e :names +17*17
			b "CMD FD41"
			e :names +18*17
			b "CMD FD71"
			e :names +19*17
			b "CMD FD81"
			e :names +20*17
			b "CMD FDNative"
			e :names +21*17
			b "CMD FDPCDOS"
			e :names +22*17
			b "CMD HD41"
			e :names +23*17
			b "CMD HD71"
			e :names +24*17
			b "CMD HD81"
			e :names +25*17
			b "CMD HDNative"
			e :names +26*17
			b "SD2IEC Native"
			e :names +27*17
if LANG = LANG_DE
::unknown		b "Unbekannt ?"
endif
if LANG = LANG_EN
::unknown		b "Unknown ?"
endif
			e :names +28*17

;*** Sondertexte für SD2IEC mit 1541/71/81-Treiber.
::nameSD41		b "SD2IEC 1541"
			e :nameSD41 +17
::nameSD71		b "SD2IEC 1571"
			e :nameSD71 +17
::nameSD81		b "SD2IEC 1581"
			e :nameSD81 +17

;*** Endadresse testen:
;Sicherstellen das genügend Speicher
;für Desktop-Daten verfügbar ist.
			g BASE_GDMENU +SIZE_GDMENU -1
;***
