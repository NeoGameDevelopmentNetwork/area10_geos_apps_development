; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Icon-Manager.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_CXIO"
			t "SymbTab_GDOS"
			t "SymbTab_GEXT"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_APPS"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
			t "e.Register.ext"

;--- Farben für Rastermodus.
:GRID_COL_1		= 12
:GRID_COL_2		= 15
endif

;*** GEOS-Header.
			n "obj.GD97"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	xICONMANAGER

;*** Systemroutinen.
			t "-SYS_DISKFILE"
			t "-SYS_STATMSG"

;*** IconManager starten.
:xICONMANAGER		lda	C_WinBack		;Vorgabewert für Vorder- und
			pha				;Hintergrundfarbe ermitteln.
			and	#%00001111
			sta	curColorBack
			pla
			lsr
			lsr
			lsr
			lsr
			sta	curColorIcon

			LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

;*** Zurück zum DeskTop.
:ExitRegMenuUser	jsr	sys_LdBackScrn		;Bildschirm zurücksetzen.

			bit	Flag_Modified		;Verzeichnisse aktualisieren?
			bpl	exitIconMan		; => Nein, Ende...

			jsr	SET_LOAD_DISK		;Verzeichnis von Disk neu einlesen.
			jmp	MOD_REBOOT		;DeskTop aktualisieren.

:exitIconMan		jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;--- HINWEIS:
;Hier wird nur das aktuelle Fenster
;aktualisiert. Alternativ kann man auch
;alle Fenster des gleichen Laufwerks
;aktualisieren (wegen Statuszeile).
if FALSE
			lda	curDrive		;Laufwerksadresse einlesen und
			sta	sysSource		;alle Fenster aktualisieren.
			jmp	MOD_UPDATE_WIN		;Zurück zum Hauptmenü.
endif

;*** Hauptfunktion ausführen.
;    Rückgabewerte "ExecRegMenuUser":
;    $00 = DeskTop           exitCode = $00
;    $FF = RegisterMenü      exitCode = $FF
;    $xx = Ausführen/Fehler  exitCode = $7F
:ExecRegMenuUser	ldx	#NO_ERROR		;Zurück zum DeskTop.
			rts

;*** Register-Menü.
:R1SizeY0 = $28
:R1SizeY1 = $9f
:R1SizeX0 = $0028
:R1SizeX1 = $010f

:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

			b 1				;Anzahl Einträge.

			w RegTName1			;Register: "VERZEICHNIS".
			w RegTMenu1

;*** Register-Icons.
:RegTName1		w RTabIcon1
			b RCardIconX_1,R1SizeY0 -$08
			b RTabIcon1_x,RTabIcon1_y

:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y

;*** X-Koordinate der Register-Icons.
:RCardIconX_1		= (R1SizeX0/8) +3
;RCardIconX_2		= RCardIconX_1 + RTabIcon1_x

;*** System-Icons.
:RIcon_Undo		w Icon_Undo
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Undo_x,Icon_Undo_y
			b USE_COLOR_INPUT

:Icon_Undo
<MISSING_IMAGE_DATA>

:Icon_Undo_x		= .x
:Icon_Undo_y		= .y

:RIcon_Apply		w Icon_Apply
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Apply_x,Icon_Apply_y
			b USE_COLOR_INPUT

:Icon_Apply
<MISSING_IMAGE_DATA>

:Icon_Apply_x		= .x
:Icon_Apply_y		= .y

:RIcon_Prev		w Icon_Prev
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Prev_x,Icon_Prev_y
			b USE_COLOR_INPUT

:Icon_Prev
<MISSING_IMAGE_DATA>

:Icon_Prev_x		= .x
:Icon_Prev_y		= .y

:RIcon_Next		w Icon_Next
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Next_x,Icon_Next_y
			b USE_COLOR_INPUT

:Icon_Next
<MISSING_IMAGE_DATA>

:Icon_Next_x		= .x
:Icon_Next_y		= .y

:RIcon_Info		w Icon_Info
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Info_x,Icon_Info_y
			b USE_COLOR_INPUT

:Icon_Info
<MISSING_IMAGE_DATA>

:Icon_Info_x		= .x
:Icon_Info_y		= .y

:RIcon_Fetch		w Icon_Fetch
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Fetch_x,Icon_Fetch_y
			b USE_COLOR_INPUT

:Icon_Fetch
<MISSING_IMAGE_DATA>

:Icon_Fetch_x		= .x
:Icon_Fetch_y		= .y

:RIcon_Load		w Icon_Load
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Load_x,Icon_Load_y
			b USE_COLOR_INPUT

:Icon_Load
<MISSING_IMAGE_DATA>

:Icon_Load_x		= .x
:Icon_Load_y		= .y

:RIcon_Save		w Icon_Save
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Save_x,Icon_Save_y
			b USE_COLOR_INPUT

:Icon_Save
<MISSING_IMAGE_DATA>

:Icon_Save_x		= .x
:Icon_Save_y		= .y

;*** Daten für Register "IconManager".
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$10
:RTab1_1  = $00
:RTab1_2  = (R1SizeX1 - R1SizeX0) -$50 +1
:RTab1_3  = (R1SizeX1 - R1SizeX0) -$30 +1
:RTab1_4  = $38
:RTab1_5  = $68
:RTab1_6  = $78
:RLine1_1 = $00
:RLine1_2 = $10
:RLine1_3 = $38
:RLine1_4 = $38
:RLine1_5 = $48
:RLine1_6 = $18
:RLine1_7 = (R1SizeY1 - R1SizeY0) -$28 +1

:RegTMenu1		b 19

			b BOX_FRAME
				w R1T01
				w getGDIconData
				b RPos1_y +RLine1_1 -5
				b RPos1_y +RLine1_1 +$28 +6
				w R1SizeX0 +8
				w R1SizeX1 -$48 -8

			b BOX_FRAME
				w R1T02
				w $0000
				b RPos1_y +RLine1_1 -5
				b R1SizeY1 -$08 +1 ;RPos1_y +RLine1_1 +$30 +6
				w R1SizeX1 -$48 +1
				w R1SizeX1 -8

;--- Auswahl.
:RegTMenu1a		b BOX_STRING
				w $0000
				w $0000
				b RPos1_y +RLine1_1
				w RPos1_x
				w GDIconName
				b 16
			b BOX_FRAME
				w $0000
				w $0000
				b RPos1_y +RLine1_2 -1
				b RPos1_y +RLine1_2 +3*8
				w RPos1_x +RTab1_1 -1
				w RPos1_x +RTab1_1 +4*8
:RegTMenu1b		b BOX_USER_VIEW
				w $0000
				w printCurIcon
				b RPos1_y +RLine1_2
				b RPos1_y +RLine1_2 +3*8 -1
				w RPos1_x +RTab1_1
				w RPos1_x +RTab1_1 +3*8 -1
			b BOX_ICON
				w $0000
				w slctPrevIcon
				b RPos1_y +RLine1_2
				w RPos1_x +RTab1_1 +3*8
				w RIcon_Prev
				b NO_OPT_UPDATE
			b BOX_ICON
				w R1TGfx
				w slctNextIcon
				b RPos1_y +RLine1_2 +2*8
				w RPos1_x +RTab1_1 +3*8
				w RIcon_Next
				b NO_OPT_UPDATE
			b BOX_ICON
				w R1T06
				w getHdrIcon
				b RPos1_y +RLine1_6
				w RPos1_x +RTab1_4
				w RIcon_Fetch
				b NO_OPT_UPDATE

;--- Icon-Editor.
			b BOX_USER
				w $0000
				w jobIconEditor
				b RPos1_y +RLine1_1
				b RPos1_y +RLine1_1 +6*8 -1
				w RPos1_x +RTab1_2
				w RPos1_x +RTab1_2 +6*8 -1
:RegTMenu1c		b BOX_USEROPT_VIEW
				w $0000
				w drawAllCards
				b RPos1_y +RLine1_1
				b RPos1_y +RLine1_1 +6*8 -1
				w RPos1_x +RTab1_2
				w RPos1_x +RTab1_2 +6*8 -1
			b BOX_OPTION
				w R1T03
				w drawAllCardCol
				b RPos1_y +RLine1_3
				w RPos1_x +RTab1_2
				w GDIconColMode
				b %11111111
			b BOX_ICON
				w $0000
				w applyIcon
				b RPos1_y +RLine1_5
				w RPos1_x +RTab1_2
				w RIcon_Apply
				b (RegTMenu1b - RegTMenu1 -1)/11 +1
			b BOX_ICON
				w $0000
				w getGDIconData
				b RPos1_y +RLine1_5
				w RPos1_x +RTab1_3
				w RIcon_Undo
				b (RegTMenu1c - RegTMenu1 -1)/11 +1

;--- Farbauswahl.
			b BOX_USER
				w $0000
				w jobSlctColor
				b RPos1_y +RLine1_4
				b RPos1_y +RLine1_4 +2*8 -1
				w R1SizeX0 +8
				w R1SizeX0 +8 +16*8 -1
			b BOX_USEROPT_VIEW
				w $0000
				w $0000
				b RPos1_y +RLine1_4
				b RPos1_y +RLine1_4 +2*8 -1
				w R1SizeX0 +8 +16*8 +1*8
				w R1SizeX0 +8 +16*8 +1*8 +8 -1
			b BOX_USEROPT_VIEW
				w $0000
				w drawColorTab
				b RPos1_y +RLine1_4
				b RPos1_y +RLine1_4 +2*8 -1
				w R1SizeX0 +8
				w R1SizeX0 +8 +16*8 -1

;--- Manager.
			b BOX_ICON
				w R1T04
				w viewHelp
				b RPos1_y +RLine1_7
				w R1SizeX0 +$08
				w RIcon_Info
				b NO_OPT_UPDATE
			b BOX_ICON
				w R1T05
				w loadIconConfig
				b RPos1_y +RLine1_7
				w RPos1_x +RTab1_5
				w RIcon_Load
				b NO_OPT_UPDATE
			b BOX_ICON
				w $0000
				w saveIconConfig
				b RPos1_y +RLine1_7
				w RPos1_x +RTab1_6
				w RIcon_Save
				b NO_OPT_UPDATE

;*** Texte für Register "ICONMANAGER".
if LANG = LANG_DE
:R1T01			b "AUSWAHL",NULL
:R1T02			b "EDITOR",NULL
:R1T03			w RPos1_x +RTab1_2 +$08 +6
			b RPos1_y +RLine1_3 +6
			b "Raster",NULL
:R1T04			w R1SizeX0 +$08 +$10 +4
			b RPos1_y +RLine1_7 +14
			b "Info",NULL
:R1T05			w RPos1_x +RTab1_5 -$38
			b RPos1_y +RLine1_7 +6
			b "Laden und"
			b GOTOXY
			w RPos1_x +RTab1_5 -$38
			b RPos1_y +RLine1_7 +14
			b "speichern",NULL
:R1T06			w RPos1_x +RTab1_4 +$10 +4
			b RPos1_y +RLine1_6 +6
			b "Von Datei"
			b GOTOXY
			w RPos1_x +RTab1_4 +$10 +4
			b RPos1_y +RLine1_6 +14
			b "einlesen",NULL
endif
if LANG = LANG_EN
:R1T01			b "SELECT",NULL
:R1T02			b "EDITOR",NULL
:R1T03			w RPos1_x +RTab1_2 +$08 +6
			b RPos1_y +RLine1_3 +6
			b "Grid",NULL
:R1T04			w R1SizeX0 +$08 +$10 +4
			b RPos1_y +RLine1_7 +14
			b "Info",NULL
:R1T05			w RPos1_x +RTab1_5 -$3a
			b RPos1_y +RLine1_7 +6
			b "Load/Save"
			b GOTOXY
			w RPos1_x +RTab1_5 -$3a
			b RPos1_y +RLine1_7 +14
			b "profile",NULL
:R1T06			w RPos1_x +RTab1_4 +$10 +4
			b RPos1_y +RLine1_6 +6
			b "Read icon"
			b GOTOXY
			w RPos1_x +RTab1_4 +$10 +4
			b RPos1_y +RLine1_6 +14
			b "from file",NULL
endif

;--- Dummy-Scrollbalken.
:R1TGfx			w $0000				;Text-Position ignorieren.
			b $00
			b ESC_GRAPHICS			;Auf Grafik-Befehle umschalten.
			b NEWPATTERN
			b $02
			b MOVEPENTO
			w RPos1_x +RTab1_1 +3*8
			b RPos1_y +RLine1_2 +8
			b RECTANGLETO
			w RPos1_x +RTab1_1 +3*8 +7
			b RPos1_y +RLine1_2 +8 +7
			b NULL

;*** Infobox anzeigen.
:viewHelp		LoadW	r0,Dlg_InfoBox
			jmp	DoDlgBox

;*** Ausgewähltes GeoDesk-Icon einlesen.
:getGDIconData		lda	GDIconNum		;GeoDesk-Icon-Nr einlesen.
			asl
			tax
			lda	GDIconAdrTab +0,x
			sta	r0L
			lda	GDIconAdrTab +1,x
			sta	r0H			;Zeiger auf GeoDesk-Icons einlesen.

			ldy	#64 -1			;GeoDesk-Icon kopieren.
::1			lda	(r0L),y
			sta	IconEditBuf,y
			dey
			bpl	:1

			lda	GDIconNamTab +0,x
			sta	r0L
			lda	GDIconNamTab +1,x
			sta	r0H			;Zeiger auf Icon-Name einlesen.

			ldy	#16 -1			;GeoDesk-Icon-Name kopieren.
::2			lda	(r0L),y
			sta	GDIconName,y
			dey
			bpl	:2

			lda	GDIconColTab +0,x	;Zeiger auf GeoDesk-Farben
			sta	r0L			;einlesen.
			lda	GDIconColTab +1,x
			sta	r0H
			ora	r0L
			sta	r1L			;Bei Fenster-Icons keine Farbe.

			ldy	#9 -1
::3			ldx	r1L			;Fenster-Icon?
			bne	:4			; => Nein, weiter...
			lda	C_GDesk_ALIcon		;Fenster-Farbe einlesen.
			b $2c
::4			lda	(r0L),y			;Farbe für Icon einlesen.
			sta	IconColorBuf,y		;Icon-Farbe speichern.
			dey
			bpl	:3

			rts

;*** Icon in Vorschau anzeigen.
:printCurIcon		jsr	i_BitmapUp		;Aktuelles Icon ausgeben.
			w IconEditBuf
			b (RPos1_x +RTab1_1)/8
			b RPos1_y +RLine1_2
			b 3,21

;*** Farbe für Vorschau setzen.
:prevColBase = COLOR_MATRIX +(RPos1_y +RLine1_2)/8*40   +(RPos1_x +RTab1_1)/8
:setNewIconCol		lda	#< prevColBase		;Zeiger auf Farb-RAM setzen.
			sta	r0L
			lda	#> prevColBase
			sta	r0H

			ldx	#0
::1			ldy	#0
::2			lda	IconColorBuf,x		;Farbe in aktueller Zeile speichern.
			sta	(r0L),y
			iny
			inx
			cpx	#3
			beq	:3
			cpx	#6
			beq	:3
			cpx	#9			;Alle Zeilen bearbeitet?
			beq	:exit			; => Ja, Ende...
			bne	:2

::3			lda	r0L			;Zeiger auf nächste Zeile in
			clc				;Farnb-RAM setzen.
			adc	#< 40
			sta	r0L
			lda	r0H
			adc	#> 40
			sta	r0H
			jmp	:1

::exit			rts

;*** Neues Icon auswählen.
:slctPrevIcon		ldx	GDIconNum		;Bereits am Anfang?
			beq	exitSlctIcon		; => Ja, Ende...

			dec	GDIconNum		;Icon -1.
			jmp	updIconData

:slctNextIcon		ldx	GDIconNum
			cpx	#10 -1			;Bereits am Ende?
			bcs	exitSlctIcon		; => Ja, Ende...

			inc	GDIconNum		;Icon +1.

:updIconData		jsr	getGDIconData		;Neue Icon-Daten einlesen.

			LoadW	r15,RegTMenu1a		;Icon-Bezeichnung ausgeben.
			jsr	RegisterUpdate
			LoadW	r15,RegTMenu1b		;Icon-Vorschau ausgeben.
			jsr	RegisterUpdate

			jsr	drawAllCards		;Icon-Editor aktualisieren.

:exitSlctIcon		rts

;*** Alle CARDs (Grafik+Farbe) ausgeben.
:drawAllCards		lda	#0			;Zeiger auf erstes CARD.
::1			pha				;CARD-Zähler zwischenspeichern.
			jsr	drawCard		;Grafik für aktuelles CARD ausgeben.
			pla
			pha
			jsr	drawCardCol		;Farbe für aktuelles CARD ausgeben.
			pla
			clc
			adc	#1			;Zeiger auf nächstes CARD.
			cmp	#9			;Alle CARDs bearbeitet?
			bcc	:1			; => Nein, weiter...

			lda	#2			;Füllmuster setzen um ungültige
			jsr	SetPattern		;Bereiche zu schraffieren.

			jsr	i_Rectangle		;Bereich in Vorschau schraffieren.
			b	RPos1_y +RLine1_1 +21*2
			b	RPos1_y +RLine1_1 +24*2 -1
			w	RPos1_x +RTab1_2
			w	RPos1_x +RTab1_2 +24*2 -1

			jsr	i_Rectangle		;Bereich in Editor schraffieren.
			b	RPos1_y +RLine1_2 +21
			b	RPos1_y +RLine1_2 +24 -1
			w	RPos1_x +RTab1_1
			w	RPos1_x +RTab1_1 +24 -1

			rts

;*** Grafik für ein CARD ausgeben.
:editScrBase = SCREEN_BASE  +(RPos1_y +RLine1_1)/8*40*8 +(RPos1_x +RTab1_2)
:drawCard		sta	r0L			;CARD-Zähler speichern.

			cmp	#3			;Zeile #1?
			bcc	:row1			; => Ja, weiter...
			cmp	#6			;Zeile #2?
			bcc	:row2			; => Ja, weiter...

::row3			sec				;Zeile #3:
			sbc	#6			;X-Position berechnen.
			sta	r0H
			clc				;Zeiger auf Grafikdaten berechnen.
			adc	#$30
			ldx	#< (editScrBase +(4*40*8))
			ldy	#> (editScrBase +(4*40*8))
			bne	:1

::row2			sec				;Zeile #2:
			sbc	#3			;X-Position berechnen.
			sta	r0H
			clc				;Zeiger auf Grafikdaten berechnen.
			adc	#$18
			ldx	#< (editScrBase +(2*40*8))
			ldy	#> (editScrBase +(2*40*8))
			bne	:1

::row1			sta	r0H
			ldx	#< (editScrBase +(0*40*8))
			ldy	#> (editScrBase +(0*40*8))

::1			sta	r1L			;Zeiger auf Grafikdaten.

			lda	r0H			;Zeiger auf X-Position einlesen.
			asl				;X-Position x 16 (Double-Size).
			asl
			asl
			asl
			sta	r1H			;X2-Position in Editor speichern.

			txa				;Zeiger auf Grafikspeicher
			clc				;berechnen:
			adc	r1H			;Die Pixel werden direkt in den
			sta	r2L			;Grafikspeicher geschrieben!
			tya
			adc	#0
			sta	r2H

			lda	#0
			sta	r3L			;Zähler für Pixel-Zeile.
			sta	r3H			;$00=High-Nibble, $FF=Low-Nibble.

::next			lda	#$00			;Zeiger auf erstes Byte in
			sta	r4L			;Grafikspeicher.

::loop			ldx	r1L			;Icon hat max. 21 Zeilen:
			cpx	#63			;Alle Daten ausgegeben?
			bcs	:end			; => Ja, Ende...

			lda	IconDataBuf,x		;Byte aus Icon-Daten einlesen.

			bit	r3H			;Low-Nibble ausgeben?
			bmi	:low			; => Ja, weiter...

::high			lsr
			lsr
			lsr
			lsr
			jmp	:write

::low			and	#%00001111

::write			tax				;Nibble als Zeiger auf Double-Data.
			lda	doubleData,x		;Breite der Pixel verdoppeln.

			ldy	r4L			;Byte 2x in Grafikspeicher
			sta	(r2L),y			;schreiben (Höhe verdoppeln).
			iny
			sta	(r2L),y
			iny
			sty	r4L			;Neuen Byte-Zeiger speichern.

			bit	r3H			;LOW-Nibble aktiv?
			bmi	:21			; => Ja, nächste Zeile.

			tya				;Zeiger auf Grafikspeicher für
			clc				;LOW-Nibble berechnen.
			adc	#8 -2
			sta	r4L

			dec	r3H			;LOW-Nibble als Aktiv setzen.
			bne	:loop			;Daten ausgeben.

::21			inc	r3H			;Nibble-Zähler zurücksetzen.

			lda	r1L			;Zeiger auf nächste
			clc				;Grafikdaten für Icon setzen.
			adc	#3
			sta	r1L

			lda	r4L			;Zeiger auf Grafikspeicher
			sec				;für nächste Zeile setzen.
			sbc	#8
			sta	r4L

			inc	r3L
			lda	r3L
			cmp	#8			;Alle Zeilen ausgegeben?
			bcs	:end			; => Ja, Ende...
			cmp	#4			;Obere Hälfte ausgegeben?
			bne	:loop			; => Nein, weiter...

			lda	r2L			;Zeiger auf Grafikspeicher für
			clc				;untere Hälfte des CARD berechnen.
			adc	#< (40*8)
			sta	r2L
			lda	r2H
			adc	#> (40*8)
			sta	r2H

			bne	:next			;Weiter mit unterer Hälfte...

::end			rts				;Ende.

;*** Alle Farb-CARDs ausgeben.
:drawAllCardCol		lda	#0			;Zeiger auf erstes CARD.
::1			pha				;CARD-Zähler zwischenspeichern.
			jsr	drawCardCol		;Farbe für aktuelles CARD ausgeben.
			pla
			clc
			adc	#1			;Zeiger auf nächstes CARD.
			cmp	#9			;Alle CARDs bearbeitet?
			bcc	:1			; => Nein, weiter...

			rts

;*** Farbe für ein CARD ausgeben.
:editColBase = COLOR_MATRIX +(RPos1_y +RLine1_1)/8*40   +(RPos1_x +RTab1_2)/8
:drawCardCol		sta	r0L			;CARD-Zähler speichern.

			cmp	#3			;Zeile #1?
			bcc	:row1			; => Ja, weiter...
			cmp	#6			;Zeile #2?
			bcc	:row2			; => Ja, weiter...

::row3			sec				;Zeile #3:
			sbc	#6			;X-Position berechnen.
			ldx	#< (editColBase +(4*40))
			ldy	#> (editColBase +(4*40))
			bne	:1

::row2			sec				;Zeile #2:
			sbc	#3			;X-Position berechnen.
			ldx	#< (editColBase +(2*40))
			ldy	#> (editColBase +(2*40))
			bne	:1

::row1			ldx	#< (editColBase +(0*40))
			ldy	#> (editColBase +(0*40))

::1			asl				;X-Position verdoppeln.
			sta	r0H			;X2-Positon speichern.

			txa				;Zeiger auf Farb-RAM
			clc				;berechnen:
			adc	r0H			;Die Farben werden direkt in das
			sta	r2L			;Farb-RAM geschrieben!
			tya
			adc	#0
			sta	r2H

			bit	GDIconColMode		;Raster aktiv?
			bmi	:grid			; => Ja, weiter...

;--- Icon-Farben ausgeben.
::default		ldx	r0L			;Farben für Icon einlesen.
			lda	IconColorBuf,x

			ldy	#0			;Obere Hälfte des CARDs:
			sta	(r2L),y			;Doppelte Höhe = Farbe 2x speichern.
			iny
			sta	(r2L),y
			dey

			pha

			lda	r2L			;Zeiger auf nächste Zeile in
			clc				;Farb-RAM berechnen.
			adc	#< 40
			sta	r2L
			lda	r2H
			adc	#> 40
			sta	r2H

			pla

;			ldy	#0			;Untere Hälfte des CARDs:
			sta	(r2L),y			;Doppelte Höhe = Farbe 2x speichern.
			iny
			sta	(r2L),y

			rts

;--- Farb-Raster ausgeben.
::grid			ldy	#0			;Obere Hälfte des CARDs:
			lda	#GRID_COL_1		;Rasterfarbe #1.
			sta	(r2L),y			;Doppelte Höhe = Farbe 2x speichern.
			iny
			lda	#GRID_COL_2		;Rasterfarbe #2.
			sta	(r2L),y
			dey

			pha

			lda	r2L			;Zeiger auf nächste Zeile in
			clc				;Farb-RAM berechnen.
			adc	#< 40
			sta	r2L
			lda	r2H
			adc	#> 40
			sta	r2H

			pla

;			ldy	#0			;Untere Hälfte des CARDs:
			lda	#GRID_COL_2		;Rasterfarbe #2.
			sta	(r2L),y			;Doppelte Höhe = Farbe 2x speichern.
			iny
			lda	#GRID_COL_1		;Rasterfarbe #1.
			sta	(r2L),y

			rts

;*** Icon-Editor initialisieren.
:jobIconEditor		lda	r1L			;Aufbau Register-Menü?
			bne	:edit			; => Nein, weiter...
			rts				;Ende.

;--- Pixel setzen/löschen.
::edit			php				;SHIFT-Taste abfragen.
			sei				;Mausklick+SHIFT = Farbe setzen.
			ldx	CPU_DATA
			lda	#$35
			sta	CPU_DATA
			lda	#%11111101
			sta	cia1base +0
			lda	cia1base +1
			stx	CPU_DATA
			plp

			and	#%10000000		;Farbe setzen?
			bne	:setgrfx		; => Nein, weiter...

;--- Farbe in Editor setzen.
::setcols		lda	GDIconNum		;Zeiger auf Farbdaten einlesen.
			asl
			tax
			lda	GDIconColTab +0,x
			sta	r1L
			lda	GDIconColTab +1,x
			sta	r1H
			ora	r1L			;Hat Icon eigene Farben?
			beq	:exit_cols		; => Nein, Ende...

			lda	mouseXPos +0		;X-Position in Editor berechnen.
			sec
			sbc	#< (RPos1_x +RTab1_2)
			sta	r0L
			lda	mouseXPos +1
			sbc	#> (RPos1_x +RTab1_2)
			sta	r0H

			ldx	#r0L			;X-Position / 16 = CARD #0-2.
			ldy	#4
			jsr	DShiftRight

			lda	mouseYPos		;Y-Position in Editor berechnen.
			sec
			sbc	#< (RPos1_y +RLine1_1)
			lsr				;Y-Position / 16 = Zeile #0-2.
			lsr
			lsr
			lsr
			tax				;Erste Zeile?
			beq	:22			; => Nein, weiter...

::21			lda	r0L			;CARD-Zähler berechnen.
			clc
			adc	#3
			sta	r0L
			dex
			bne	:21

::22			lda	curColorIcon		;Vordergrundfarbe mit
			asl				;Hintergrundfarbe kombinieren.
			asl
			asl
			asl
			ora	curColorBack

			ldx	r0L			;Zeiger auf CARD einlesen und
			sta	IconColorBuf,x		;neuen Farbwert speichern.

			txa
			jsr	drawCardCol		;Farbe für aktuelles CARD ausgeben.

::exit_cols		rts

;--- Pixel in Editor setzen.
::setgrfx		lda	mouseXPos +0		;X-Position in Editor berechnen.
			sec
			sbc	#< (RPos1_x +RTab1_2)
			sta	r0L
			lda	mouseXPos +1
			sbc	#> (RPos1_x +RTab1_2)
			sta	r0H

			lsr	r0H			;X-Position / 2 = Pixel #0-23.
			ror	r0L

			lda	r0L			;Zeiger auf aktuelles Bit %0-7
			and	#%00000111		;berechnen.
			sta	r1L

			lda	r0L			;Zeiger auf aktuelles Byte #0-2
			lsr				;berechnen.
			lsr
			lsr
			sta	r2L

			lda	mouseYPos		;Y-Position in Editor berechnen.
			sec
			sbc	#< (RPos1_y +RLine1_1)
			lsr				;Y-Position / 2 = Zeile #0-2.
			tax				;Erste Zeile?
			beq	:32			; => Nein, weiter...

::31			lda	r2L			;CARD-Zähler berechnen.
			clc
			adc	#3
			sta	r2L
			dex
			bne	:31

::32			ldx	r2L			;Zeiger auf Byte holen und
			lda	IconDataBuf,x		;Byte aus Icon-Daten einlesen.
			ldy	r1L
			eor	bitData,y		;Pixel invertieren und
			sta	IconDataBuf,x		;Icon-Daten aktualisieren.

			jsr	drawAllCards		;Grafik für aktuelles CARD ausgeben.

			rts

;*** Farbtabelle zeichnen.
:colTabBase = COLOR_MATRIX +(RPos1_y +RLine1_4)/8*40   +(R1SizeX0 +8)/8
:drawColorTab		lda	#0			;Grafik im Bereich Farbtabelle
			jsr	SetPattern		;löschen.

			jsr	i_Rectangle
			b	RPos1_y +RLine1_4
			b	RPos1_y +RLine1_4 +2*8 -1
			w	R1SizeX0 +8
			w	R1SizeX0 +8 +16*8 -1

			lda	# (RPos1_y +RLine1_4 +7)
			sta	r11L
			lda	#%10101010
			jsr	HorizontalLine
			inc	r11L
			lda	#%01010101		;Trennung zwischen Farbe für
			jsr	HorizontalLine		;Vorder- und Hintergrund setzen.

			lda	#< colTabBase		;Zeiger auf Farb-RAM berechnen.
			sta	r0L
			clc
			adc	#< 40
			sta	r1L
			lda	#> colTabBase
			sta	r0H
			adc	#> 40
			sta	r1H

			ldy	#0			;Farbtabelle ausgeben.
::1			tya
			bne	:2
			lda	#$10
::2			sta	(r0L),y
			sta	(r1L),y
			iny
			cpy	#16
			bcc	:1

			iny				;Aktuelle Farbe für
			lda	curColorIcon		;Vorder- und Hintergrund ausgeben.
			sta	(r0L),y
			lda	curColorBack
			sta	(r1L),y

			lda	#(RPos1_y +RLine1_4)
			sta	r2L
			clc
			adc	#6
			sta	r2H

			lda	curColorIcon		;Auswahl Vordergrund-Farbe anzeigen.
			jsr	:setcol

			lda	r2L			;Zeiger auf Grafik für
			clc				;Hintergrundfarbe setzen.
			adc	#9
			sta	r2L
			clc
			adc	#6
			sta	r2H

			lda	curColorBack		;Auswahl Hintergrund-Farbe anzeigen.

;--- Rechteck um Auswahl zeichnen.
::setcol		asl				;X-Position links berechnen.
			asl
			asl
			clc
			adc	#< (R1SizeX0 +8)
			sta	r3L
			lda	#0
			adc	#> (R1SizeX0 +8)
			sta	r3H

			lda	r3L			;X-Position rechts berechnen.
			clc
			adc	#< 7
			sta	r4L
			lda	r3H
			adc	#> 7
			sta	r4H

			lda	#%11111111		;Rahmen zeichnen.
			jsr	FrameRectangle

			rts

;*** Vorder-/Hintergrundfarbe wählen.
:jobSlctColor		lda	r1L			;Aufbau Register-Menü?
			bne	:slct			; => Nein, weiter...
			rts				;Ende.

::slct			lda	mouseXPos +0		;X-Position berechnen.
			sec
			sbc	#< (R1SizeX0 +8)
			sta	r0L
			lda	mouseXPos +1
			sbc	#> (R1SizeX0 +8)
			sta	r0H

			ldx	#r0L			;X-Position / 8 = Farbe #0-15.
			ldy	#3
			jsr	DShiftRight

			lda	mouseYPos		;Y-Position berechnen.
			sec
			sbc	#< (RPos1_y +RLine1_4)
			lsr
			lsr
			lsr				;Hintergrundfarbe setzen?
			bne	:back			; => Ja, weiter...

::fore			lda	r0L			;Neuen Wert für Vordergrund setzen.
			sta	curColorIcon
			jmp	drawColorTab		;Farbtabelle aktualisieren.

::back			lda	r0L			;Neuen Wert für Hintergrund setzen.
			sta	curColorBack
			jmp	drawColorTab		;Farbtabelle aktualisieren.

;*** Icon-Daten in System übernehmen.
:applyIcon		lda	#$ff			;System-Icons wurden geändert.
			sta	Flag_Modified

			lda	GDIconNum		;Zeiger auf System-Icon einlesen.
			asl
			tax
			lda	GDIconAdrTab +0,x
			sta	r0L
			lda	GDIconAdrTab +1,x
			sta	r0H

			ldy	#64 -1			;Icon-Daten aus Editor in
::1			lda	IconEditBuf,y		;System-Icon übertragen.
			sta	(r0L),y
			dey
			bpl	:1

			lda	GDIconColTab +0,x	;Zeiger auf Farbdaten einlesen.
			sta	r0L
			lda	GDIconColTab +1,x
			sta	r0H
			ora	r0L			;Hat Icon eigene Farben?
			beq	:done			; => Nein, Ende...

			ldy	#9 -1			;Farb-Daten aus Editor in
::2			lda	IconColorBuf,y		;System-Farben übernehmen.
			sta	(r0L),y
			dey
			bpl	:2

::done			rts				;Ende.

;*** Icon aus Datei-Header einlesen.
:getHdrIcon		lda	#$00
			sta	dataFileName		;Speicher für Dateiname löschen.
			sta	r10L
			sta	r10H			;Keine GEOS-Klasse verwenden.
			lda	#255			;255 = Alle Dateitypen erlauben.
			sta	r7L
			LoadW	r5,dataFileName		;Zwischenspeicher Dateiname.
			LoadW	r0,Dlg_GetFiles
			jsr	DoDlgBox		;Dateiauswahlbox.

			lda	sysDBData
			cmp	#OPEN			;Datei öffnen?
			bne	:exit			; => Nein, Ende...

			lda	dataFileName		;Wurde Datei ausgewählt?
			beq	:exit			; => Nein, Ende...

			LoadW	r6,dataFileName
			jsr	FindFile		;Datei in Verzeichnis suchen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			lda	dirEntryBuf +22		;GEOS-Datei?
			beq	:exit			; => Nein, Ende...

			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo		;GEOS-Dateiheader einlesen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			ldy	#64 -1			;Icon-Daten aus Dateiheader in
::1			lda	fileHeader +4,y		;Editor übertragen.
			sta	IconEditBuf,y
			dey
			bpl	:1

			jsr	drawAllCards		;Editor aktualisieren.

::exit			rts

;*** Icon-Konfiguration laden.
:loadIconConfig		lda	#$00
			sta	dataFileName		;Speicher für Dateiname löschen.
			LoadB	r7L,SYSTEM		;GEOS-Dateityp SYSTEM.
			LoadW	r10,confIconClass	;GEOS-Klasse setzen.
			LoadW	r5,dataFileName		;Zwischenspeicher Dateiname.
			LoadW	r0,Dlg_GetFiles
			jsr	DoDlgBox		;Dateiauswahlbox anzeigen.

			lda	sysDBData		;Wurde Laufwerk gewechselt?
			bpl	:1			; => Nein, weiter...

			and	#%00001111
			jsr	SetDevice		;Neues Laufwerk aktivieren.
			txa				;Fehler?
			beq	loadIconConfig		; => Nein, zurück zur Auswahlbox.
			bne	:exit			; => Ja, Abbruch...

::1			cmp	#OPEN			;Datei geöffnet?
			bne	:exit			; => Nein, Ende...
			lda	dataFileName		;Datei ausgewählt?
			beq	:exit			; => Nein, Ende...

			LoadB	r0L,%00000001
			LoadW	r6,dataFileName		;Zeiger auf Dateiname.
			LoadW	r7,dataIconBuf		;Startadresse Icondaten.
			jsr	GetFile			;Datei einlesen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			jsr	i_MoveData		;Systemicons.
			w	dataIconBuf
			w	Icon_Drive
			w	9*64

			jsr	i_MoveData		;Arbeitsplatz.
			w	dataIconBuf +9*64
			w	appLinkIBufA
			w	64

			jsr	i_MoveData		;Farbe für Lwfk/Prnt/Inpt/SDir.
			w	dataIconBuf +10*64
			w	sysIconColorTab
			w	4*9

			jsr	RegisterNextOpt		;Register-Menü aktualisieren.

			lda	#$ff			;System-Icons wurden geändert.
			sta	Flag_Modified

::exit			rts

;*** Icon-Profil speichern.
:saveIconConfig		LoadW	a0,confIconName
			LoadW	r0,Dlg_InputName
			jsr	DoDlgBox		;Dateiname eingeben.

			lda	sysDBData		;Rückmeldung auswerten.
			cmp	#CANCEL			; ABBRUCH ?
			beq	:cancel			; => Ja, Ende...
			lda	confIconName		;Name eingegeben ?
			bne	:slctDrive		; => Ja, weiter...

;--- Ziel-Datei wählen.
::slctFile		LoadB	r7L,SYSTEM		;GEOS-Dateityp SYSTEM.
			LoadW	r10,confIconClass	;GEOS-Klasse setzen.
			LoadW	r5,confIconName		;Zeiger auf Dateiname.
			LoadW	r0,Dlg_GetFiles
			jsr	DoDlgBox		;Dateiauswahlbox.

			lda	sysDBData		;Wurde Laufwerk gewechselt?
			bpl	:1			; => Nein, weiter...

			and	#%00001111
			jsr	SetDevice		;Neues Laufwerk aktivieren.
			txa				;Fehler?
			beq	:slctFile		; => Nein, zurück zur Auswahlbox.
			bne	:cancel			; => Ja, Abbruch...

::1			cmp	#DISK			;Partition/Diskwechsel gewählt ?
			beq	:slctFile		; => Ja, Neustart...

			cmp	#OPEN			;Datei geöffnet?
			bne	:cancel			; => Nein, Ende...
			lda	confIconName		;Datei ausgewählt?
			bne	:save			; => Ja, weiter...

::cancel		rts

;--- Ziel-Laufwerk wählen.
::slctDrive		LoadW	r5,dataFileName		;Temporärer Name. Ausgewählter
			LoadB	r7L,SYSTEM		;GEOS-Dateityp SYSTEM.
			LoadW	r10,confIconClass	;GEOS-Klasse setzen.
			LoadW	r0,Dlg_SlctDrive
			jsr	DoDlgBox		;Partition/Laufwerk wählen.

			lda	sysDBData		;Laufwerk wechseln ?
			bpl	:2			; =>: Nein, weiter...
			and	#%00001111
			jsr	SetDevice		;Neues Laufwerk aktivieren.
			txa				;Fehler?
			beq	:slctDrive		; => Nein, zurück zur Auswahlbox.
			bne	:cancel			; => Ja, Abbruch...

::2			cmp	#DISK			;Partition/Diskwechsel gewählt ?
			beq	:slctDrive		; => Ja, Neustart...
			cmp	#CANCEL			;"ABBRUCH" gewählt ?
			beq	:cancel			; => Ja, Ende...

;--- Icon-Daten speichern.
::save			lda	curDrive		;Laufwerksname in
			clc				;DialogBox übernehmen.
			adc	#"A" -$08
			sta	confIconDrive

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler ?
			bne	:err			; => Ja, Abbruch...

			LoadW	r0,confIconName
			jsr	DeleteFile		;Vorhandene Datei löschen.
			txa				;Fehler?
			beq	:3			; => Nein, weiter...
			cmp	#FILE_NOT_FOUND		;Datei nicht vorhanden?
			bne	:err			; => Nein, Abbruch...

::3			lda	#< confIconName		;Zeiger auf Dateiname für
			sta	HdrB000 +0		;Iconprofil.
			lda	#> confIconName
			sta	HdrB000 +1

			jsr	doSaveIconConf		;Iconprofil speichern.

			lda	#< Dlg_DiskSave		;Dialogbox:
			ldy	#> Dlg_DiskSave		;"Iconprofil gespeichert"

			cpx	#NO_ERROR		;Fehler ?
			beq	:dlgbox			; => Nein, Ende...

::err			lda	#< Dlg_DskSvErr		;Dialogbox:
			ldy	#> Dlg_DskSvErr		;"Iconprofil nicht gespeichert"
::dlgbox		sta	r0L
			sty	r0H

			lda	HdrB000 +0		;Zeiger auf Dateiname einlesen.
			sta	a0L
			lda	HdrB000 +1
			sta	a0H

			jsr	DoDlgBox		;Hinweis/Fehler ausgeben.

::exit			rts

;*** Iconprofil speichern.
:doSaveIconConf		jsr	i_MoveData		;Systemicons.
			w	Icon_Drive
			w	dataIconBuf
			w	9*64

			jsr	i_MoveData		;Arbeitsplatz.
			w	appLinkIBufA
			w	dataIconBuf +9*64
			w	64

			jsr	i_MoveData		;Farbe für Lwfk/Prnt/Inpt/SDir.
			w	sysIconColorTab
			w	dataIconBuf +10*64
			w	4*9

			LoadW	r10L,0
			LoadW	r9,HdrB000
			jsr	SaveFile		;Iconprofil speichern.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			lda	HdrB000 +0		;Zeiger auf Dateiname einlesen.
			sta	r6L
			lda	HdrB000 +1
			sta	r6H
			jsr	FindFile		;Iconprofil suchen.
			txa				;Datei gefunden?
			bne	:err			; => Nein, Abbruch...

			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo		;Infoblock einlesen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			lda	HdrB160			;SaveFile löscht Byte #160,
			sta	fileHeader +160		;Byte wieder herstellen.

			lda	dirEntryBuf+19
			sta	r1L
			lda	dirEntryBuf+20
			sta	r1H
			LoadW	r4,fileHeader
			jsr	PutBlock		;Infoblock schreiben.
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

::err			rts

;*** Variablen.
:Flag_Modified		b $00

:GDIconNum		b $00
:GDIconName		s 17
:GDIconColMode		b $00

:GDIconColTab		w Color_Drive
			w Color_SDir
			w Color_Prnt
			w Color_Inpt
			w $0000
			w $0000
			w $0000
			w $0000
			w $0000
			w $0000

:GDIconAdrTab		w Icon_Drive
			w Icon_Map
			w Icon_Printer
			w Icon_Input
			w Icon_DEL
			w Icon_CBM
			w Icon_41_71
			w Icon_81_NM
			w Icon_MoreFiles
			w appLinkIBufA

:GDIconNamTab		w :t0
			w :t1
			w :t2
			w :t3
			w :t4
			w :t5
			w :t6
			w :t7
			w :t8
			w :t9

if LANG = LANG_DE
::t0			b "Laufwerk"
			e :t0 +17
::t1			b "Unterverzeichnis"
			e :t1 +17
::t2			b "Drucker"
			e :t2 +17
::t3			b "Eingabegerät"
			e :t3 +17
::t4			b "Gelöschte Datei"
			e :t4 +17
::t5			b "Nicht-GEOS-Datei"
			e :t5 +17
::t6			b "41/71 Partition"
			e :t6 +17
::t7			b "81/NM Partition"
			e :t7 +17
::t8			b "Weitere Dateien"
			e :t8 +17
::t9			b "Arbeitsplatz"
			e :t9 +17
endif
if LANG = LANG_EN
::t0			b "Drive"
			e :t0 +17
::t1			b "Subdirectory"
			e :t1 +17
::t2			b "Printer device"
			e :t2 +17
::t3			b "Input device"
			e :t3 +17
::t4			b "Deleted file"
			e :t4 +17
::t5			b "None-GEOS file"
			e :t5 +17
::t6			b "41/71 Partition"
			e :t6 +17
::t7			b "81/NM Partition"
			e :t7 +17
::t8			b "More files"
			e :t8 +17
::t9			b "My Computer"
			e :t9 +17
endif

;--- Daten für Editor.
:IconEditBuf		b $bf				;Kennbyte ungepackte Daten.
:IconDataBuf		s 63				;3x21 Bytes für Grafikdaten.
:IconColorBuf		s 9				;3x 3 Bytes für Farbdaten.

:curColorIcon		b $00				;Aktuelle Fordergrundfarbe.
:curColorBack		b $00				;Aktuelle Hintergrundfarbe.

;--- Position für Pixel in Editor.
:bitData		b %10000000
			b %01000000
			b %00100000
			b %00010000
			b %00001000
			b %00000100
			b %00000010
			b %00000001

;-- Doppele Pixelbreite.
:doubleData		b %00000000
			b %00000011
			b %00001100
			b %00001111
			b %00110000
			b %00110011
			b %00111100
			b %00111111
			b %11000000
			b %11000011
			b %11001100
			b %11001111
			b %11110000
			b %11110011
			b %11111100
			b %11111111

;*** Dateiauswahlbox.
:Dlg_GetFiles		b %10000001
			b DBGETFILES!DBSETDRVICON ,$00,$00
			b CANCEL                  ,$00,$00
			b OPEN                    ,$00,$00
			b NULL

;*** Dialogbox: Ziel-Laufwerk wählen.
:Dlg_SlctDrive		b $81
			b DBGETFILES!DBSETDRVICON ,$00,$00
			b DISK                    ,$00,$00
			b CANCEL                  ,$00,$00
			b OPEN                    ,$00,$00
			b NULL

;*** Dateiname für Konfigurationsdatei.
:confIconDrive		b "A:",PLAINTEXT,NULL
:confIconPart		b $00
:confIconName		b "GeoDesk.icn"
			e confIconName +17
:confIconClass		b "geoDeskIcon "		;Klasse
			b "V0.1"			;Version
			b NULL

;*** Info-Block für Konfigurationsdatei.
:HdrB000		w confIconName
::002			b $03,$15
			b $bf
			b %11111111,%11111111,%11111111
			b %10000000,%00000000,%00000001
			b %10000000,%00000000,%00001101
			b %10011100,%00111000,%00000001
			b %10011100,%00111000,%00001101
			b %10011100,%00111000,%00001101
			b %10000000,%00000000,%00001101
			b %10111110,%01111100,%00011101
			b %10000000,%00000000,%00000001
			b %10011100,%00000000,%00000001
			b %10011100,%00000000,%00000001
			b %10011100,%00000000,%00000001
			b %10000000,%00000011,%00111001
			b %10111110,%00000100,%00100101
			b %10000000,%00000101,%10100101
			b %10000000,%00000100,%10100101
			b %10000000,%00000011,%10111001
			b %10000000,%00000000,%00000001
			b %10101010,%10101010,%10101011
			b %11010101,%01010101,%01010101
			b %11111111,%11111111,%11111111

::068			b $81				;SEQ.
			b SYSTEM			;GEOS-Systemdatei.
			b SEQUENTIAL			;GEOS-Dateityp SEQ.
			w dataIconBuf			;Programm-Anfang.
			w dataIconBuf +10*64 +4*9	;Programm-Ende.
			w $0000				;Programm-Start.
::077			b "geoDeskIcon "		;Klasse
			b "V0.1"			;Version
			b NULL
			b $00,$00			;Reserviert
			b $00				;Bildschirmflag
::097			b "GeoDesk64"			;Autor
			s 11				;Reserviert
			s 12  				;Anwendung/Klasse
			s 4  				;Anwendung/Version
			b NULL
			s 26				;Reserviert.

if LANG = LANG_DE
:HdrB160		b "Konfigurationsdatei",CR
			b "für GeoDesk-Icons",NULL
endif
if LANG = LANG_EN
:HdrB160		b "Configuration file",CR
			b "for GeoDesk icons",NULL
endif

::HdrEnd		s (HdrB000+256)-:HdrEnd

;*** Neuen Namen für Iconprofil eingeben.
:Dlg_InputName		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w :1
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$40
			w :3
			b DBTXTSTR   ,$0c,$4a
			w :4
			b DBTXTSTR   ,$18,$31
			w :5
			b DBTXTSTR   ,$0c,$5b
			w :6
			b DBGETSTRING,$38,$2b
			b a0L, 16
;HINWEIS:
;GetString muss mit RETURN beendet
;werden, da "OK" kein NULL-Byte setzt!
;			b OK         ,$01,$50
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT,BOLDON
			b "ICONPROFIL SPEICHERN",NULL
::2			b PLAINTEXT
			b "Name für Iconprofil eingeben:",NULL
::3			b "Auf der nächsten Seite das Laufwerk",NULL
::4			b "wählen und mit 'Öffnen' bestätigen.",NULL
::5			b BOLDON
			b "Name:"
			b PLAINTEXT,NULL
::6			b "Kein Name = Dateiauswahl",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT,BOLDON
			b "SAVE ICON PROFILE",NULL
::2			b PLAINTEXT
			b "Enter name for the icon profile:",NULL
::3			b "On the next page please select the",NULL
::4			b "drive and confirm with 'Open'.",NULL
::5			b BOLDON
			b "Name:"
			b PLAINTEXT,NULL
::6			b "No name = Select file",NULL
endif

;*** Info: Iconprofil gespeichert.
:Dlg_DiskSave		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2a
			w :3
			b DBTXTSTR   ,$18,$3a
			w :4
			b DBTXTSTR   ,$38,$3a
			w confIconDrive
			b DBVARSTR   ,$42,$3a
			b a0L
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Das aktuelle Iconprofil wurde",NULL
::3			b "erfolgreich gespeichert:",NULL
::4			b BOLDON
			b "Datei:"
			b PLAINTEXT,NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The current icon profile has",NULL
::3			b "been saved successfully:",NULL
::4			b BOLDON
			b "File:"
			b PLAINTEXT,NULL
endif

;*** Fehler: Iconprofil nicht gespeichert.
:Dlg_DskSvErr		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Err
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2a
			w :3
			b DBTXTSTR   ,$18,$3a
			w :4
			b DBTXTSTR   ,$38,$3a
			w confIconDrive
			b DBVARSTR   ,$42,$3a
			b a0L
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Das aktuelle Iconprofil konnte",NULL
::3			b "nicht gespeichert werden!",NULL
::4			b BOLDON
			b "Datei:"
			b PLAINTEXT,NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The current icon profile",NULL
::3			b "could not be saved!",NULL
::4			b BOLDON
			b "File:"
			b PLAINTEXT,NULL
endif

;*** Infobox.
:dbInfoLine0  = $10
:dbInfoLine1  = $18
:dbInfoLine2  = $30
:dbInfoLine3  = $48
:dbInfoLine4  = $60
:dbInfoLine5  = $78
:dbInfoLine9  = $88
:dbInfoTop    = $10
:dbInfoHeight = $9f
:dbInfoLeft   = $0010
:dbInfoWidth  = $0117
:dbInfoTab0   = $10
:dbInfoTab1   = $02
:dbInfoTab2   = dbInfoLeft +$10 +$10 +$04
:dbInfoTab3   = $1b
:dbInfoTab4   = dbInfoLeft +$10

:Dlg_InfoBox		b %00000001
			b dbInfoTop ,dbInfoTop  +dbInfoHeight
			w dbInfoLeft,dbInfoLeft +dbInfoWidth

			b DBUSRICON  ,dbInfoTab1 ,dbInfoLine1
			w :iconFetch
			b DBUSRICON  ,dbInfoTab1 ,dbInfoLine2
			w :iconLoad
			b DBUSRICON  ,dbInfoTab1 ,dbInfoLine3
			w :iconSave
			b DBUSRICON  ,dbInfoTab1 ,dbInfoLine4
			w :iconApply
			b DBUSRICON  ,dbInfoTab1 ,dbInfoLine5
			w :iconUndo

			b DBTXTSTR   ,dbInfoTab0 ,dbInfoLine0
			w :text

			b DB_USR_ROUT
			w :setIconColor

			b OK         ,dbInfoTab3 ,dbInfoLine9

			b NULL

if LANG = LANG_DE
::text			b PLAINTEXT,BOLDON
			b "GEODESK-Icons verwalten"
			b PLAINTEXT

			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine1 -4 +10
			b "Datei-Icon aus einer GEOS-Datei einlesen"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine1 -4 +10 +10
			b "(Farben müssen manuell angepasst werden!)"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine2 -4 +10
			b "GeoDesk-Icons aus Profildatei laden"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine2 -4 +10 +10
			b "(Aktuelle Icons werden überschrieben!)"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine3 -4 +10
			b "GeoDesk-Icons in Profildatei speichern"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine3 -4 +10 +10
			b "(`GeoDesk.icn` wird beim Systemstart geladen)"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine4 -4 +10
			b "Änderungen im Editor übernehmen"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine4 -4 +10 +10
			b "Maustaste: Pixel / Maustaste+<SHIFT> Farbe setzen"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine5 +10
			b "Änderungen im Editor rückgängig machen"
			b GOTOXY
			w dbInfoTab4
			b dbInfoTop +dbInfoLine9 +10
			b BOLDON,"Farbe nicht für alle Icons verfügbar!"

			b NULL
endif
if LANG = LANG_EN
::text			b PLAINTEXT,BOLDON
			b "Manage GEODESK icons"
			b PLAINTEXT

			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine1 -4 +10
			b "Read icon from a GEOS file"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine1 -4 +10 +10
			b "(Colors must be set manually!)"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine2 -4 +10
			b "Load GeoDesk icons from file"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine2 -4 +10 +10
			b "(Current icons will be replaced!)"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine3 -4 +10
			b "Save GeoDesk icons to file"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine3 -4 +10 +10
			b "(`GeoDesk.icn` will be loaded during bootup)"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine4 -4 +10
			b "Apply changes from editor"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine4 -4 +10 +10
			b "Button: Set pixel, Button+<SHIFT>: Set Color"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine5 +10
			b "Undo all chganges from editor"
			b GOTOXY
			w dbInfoTab4
			b dbInfoTop +dbInfoLine9 +10
			b BOLDON,"Color not available for all icons!"

			b NULL
endif

::iconFetch		w Icon_Fetch
			b $00,$00
			b Icon_Fetch_x,Icon_Fetch_y
			w $0000

::iconLoad		w Icon_Load
			b $00,$00
			b Icon_Load_x,Icon_Load_y
			w $0000

::iconSave		w Icon_Save
			b $00,$00
			b Icon_Save_x,Icon_Save_y
			w $0000

::iconApply		w Icon_Apply
			b $00,$00
			b Icon_Apply_x,Icon_Apply_y
			w $0000

::iconUndo		w Icon_Undo
			b $00,$00
			b Icon_Undo_x,Icon_Undo_y
			w $0000

::setIconColor		lda	#(dbInfoLine1 /8) +2
			jsr	:setColor

			lda	#(dbInfoLine2 /8) +2
			jsr	:setColor

			lda	#(dbInfoLine3 /8) +2
			jsr	:setColor

			lda	#(dbInfoLine4 /8) +2
			jsr	:setColor

			lda	#(dbInfoLine5 /8) +2
::setColor		sta	r5H

			lda	#dbInfoTab1 +2
			sta	r5L

			lda	#2
			sta	r6L
			sta	r6H

			lda	C_DBoxDIcon
			sta	r7L

			jmp	RecColorBox

;*** Zwischenspeicher für Iconprofil.
:dataIconBuf
:sizeIconBuf		= $0300

;*** Endadresse testen:
			g RegMenuBase -sizeIconBuf
;***
