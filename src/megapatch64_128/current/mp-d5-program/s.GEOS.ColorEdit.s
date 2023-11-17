; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboldateien.
			t "G3_SymMacExt"
			t "e.Register.ext"

;--- Hinweis:
;Unter MP64 ist DOUBLE_W/_B/ADD1_W
;mit NULL definiert, im Quelltext dann
;ohne Funktion.
;
;Unter MP128 ist DOUBLE_W/_B/ADD1_W
;für die Verdopplungstechnik gesetzt.
;Nicht mehr unter GEOS64 lauffähig!

;*** GEOS-Header.
if Flag64_128 = TRUE_C64
			n "GEOS64.EditCol"
			c "GCOLEDIT64  V1.1"
			z $00 ;GEOS 64/128, Nur 40Z.
endif
if Flag64_128 = TRUE_C128
			n "GEOS128.EditCol"
			c "GCOLEDIT128 V1.1"
			z $40 ;GEOS 64/128, 40Z/80Z.
endif

			a "Markus Kanet"
			f APPLICATION
			o APP_RAM

			i
<MISSING_IMAGE_DATA>

if Flag64_128!Sprache = TRUE_C64!Deutsch
			h "MegaPatch-Farben ändern"
			h "Nur GEOS/MP3-64!"
endif
if Flag64_128!Sprache = TRUE_C64!Englisch
			h "Edit MegaPatch colors"
			h "GEOS/MP3-64 only!"
endif
if Flag64_128!Sprache = TRUE_C128!Deutsch
			h "MegaPatch-Farben ändern"
			h "Nur GEOS/MP3-128!"
endif
if Flag64_128!Sprache = TRUE_C128!Englisch
			h "Edit MegaPatch colors"
			h "GEOS/MP3-128 only!"
endif

;*** Symbole für ColorEditor.
if .p
:DATA_BUF  = $4f00
:DATA_MODE = DATA_BUF +128 +0
:DATA_COLS = DATA_BUF +128 +4
endif

;--- Hinweis:
;Die erzeugte Autostart-Datei ist zu
;GEOS64 und GEOS128 kompatibel, aber
;nutzt ":graphMode" um unter GEOS128
;den Bildschirm-Modus zu testen.
;
;Für MegaPatch64 muss ":graphMode"
;hier manuell eingebunden werden.
;
;Wenn die Anwendung für MegaPatch128
;assembliert wird, ist ":graphMode"
;über SymbTab128 definiert.
;
if Flag64_128 = TRUE_C64
:graphMode = $003f ;C128: 40Z/80Z-Modus.
endif

;*** Menü initialisieren.
:DoAppStart		lda	MP3_CODE +0		;GEOS/MegaPatch aktiv?
			cmp	#"M"
			bne	:exit			; => Nein, Abbruch...
			lda	MP3_CODE +1
			cmp	#"P"
			beq	:mp3			; => Ja, weiter...
::exit			rts

::mp3			LoadB	r0L,%00000001
			LoadW	r7,DATA_BUF
			LoadW	r6,configColStd
			jsr	GetFile			;Standard-Farbdatei laden.
			txa				;Fehler?
			beq	:init			; => Nein, weiter...

			jsr	i_MoveData		;Vorgabe für Startdatei.
			w	BOOTMP3COL
			w	DATA_BUF
			w	(BOOTMP3COL_END - BOOTMP3COL)

			lda	#AUTO_EXEC
			sta	dirEntryBuf +22
			lda	#$83
			sta	dirEntryBuf +0

;--- Anwendung ausführen.
::init			lda	DATA_COLS +0
			ora	DATA_COLS +1		;Sind Farben definiert?
			beq	:update			; => Nein, importieren...

if Flag64_128 = TRUE_C128
			bit	graphMode		;C128/80Z-Modus?
			bpl	:40z			; => Nein, 40Z-Modus testen.

::80z			lda	#$80			;Farben für 80Z-Modus.
			b $2c
endif
::40z			lda	#$40			;Farben für 40Z-Modus.
			cmp	DATA_MODE		;Gespeicherte Farben kompatibel?
			beq	:ok			; => Ja, weiter...

::update		jsr	SaveColors		;Erststart: Systemfarben übernehmen.

::ok			lda	dirEntryBuf +22		;AutoLoad-Option einlesen.
			cmp	#AUTO_EXEC
			beq	:auto
::appl			lda	#%00000000
			b $2c
::auto			lda	#%10000000		;Bit%7 für Registermenü setzen.
			sta	doAutoLoad

			lda	dirEntryBuf +0		;AutoSave-Option einlesen.
			and	#%01000000
			eor	#%01000000
			sta	doAutoSave

			jsr	GetBackScreen		;Hintergrundbild laden.

if Flag64_128 = TRUE_C128
			bit	graphMode		;40Z/80Z-Modus ?
			bpl	:41z			; => 40Z, weiter...

			lda	#NULL			;Register-Menü an 80Z anpassen.
			sta	fix80a

			lda	fix80b +0
			clc
			adc	#< $0012
			sta	fix80b +0
			lda	fix80b +1
			adc	#> $0012
			sta	fix80b +1
endif

::41z			jsr	SetADDR_Register	;Register-Routine einlesen.
			jsr	FetchRAM

			jsr	RegisterSetFont		;Zeichensatz aktivieren.

			LoadW	r0,RegisterTab		;Register-Menü installieren.
			jsr	DoRegister

			lda	C_WinIcon		;Farben für EXIT-Button setzen.
			jsr	i_UserColor
			b	(R1SizeX0+8)/8 ! DOUBLE_B
			b	(R1SizeY0-8)/8
			b	Icon_MExit_x ! DOUBLE_B
			b	Icon_MExit_y/8

			LoadW	r0,IconMenuTab		;Icon-Menü installieren.
			jsr	DoIcons

			rts				;Zurück zur GEOS-Mainloop.

;*** Anwendung beenden.
:ExitAppl		jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler?
			bne	:exit			; => Ja, Ende...

			jsr	UpdateConfig		;Daten speichern.

::exit			jmp	EnterDeskTop		;Zurück zum DeskTop.

;*** DoIcons-Menü.
:IconMenuTab		b $01				;Nur ein Icon.
			w $0000				;Mausposition nicht verändern.
			b $00

			w Icon_MExit			;Daten für CLOSE-Icon.
			b (R1SizeX0+8)/8 ! DOUBLE_B
			b (R1SizeY0-8)
			b Icon_MExit_x ! DOUBLE_B
			b Icon_MExit_y
			w ExitAppl

:Icon_MExit		b %10000000 +1 +16		;Ungepackt +Kennbyte +16 Datenbytes.

			b %11111111,%11111111		;"CLOSE"
			b %10000000,%00000001
			b %10001100,%00110001
			b %10000110,%01100001
			b %10000011,%11000001
			b %10000110,%01100001
			b %10001100,%00110001
			b %10000000,%00000001

:Icon_MExit_x		= 2				;Beite = 1 Card
:Icon_MExit_y		= 8				;Höhe  = 8 Pixel

;*** Register-Menü.
:R1Height		= $90
:R1Width		= $0100
:R1SizeY0		= ($c8 -8 -R1Height)/2 +8
:R1SizeX0		= ($0140 -R1Width)/2
:R1SizeY1		= R1SizeY0 +R1Height -1
:R1SizeX1		= R1SizeX0 +R1Width -1

:RegisterTab		b R1SizeY0
			b R1SizeY1
			w R1SizeX0 ! DOUBLE_W
			w R1SizeX1 ! DOUBLE_W ! ADD1_W

			b 1				;Anzahl Einträge.

			w RegTName1			;Register: "Farben".
			w RegTMenu1

;*** X-Koordinate der Register-Icons.
;Position: 1 Card einrücken + X-Icon.
:RCardIconX_1		= (R1SizeX0+8+16)/8

;*** Register-Icons.
:RegTName1		w RTabIcon1
			b RCardIconX_1 ! DOUBLE_B
			b R1SizeY0 -8
			b RTabIcon1_x ! DOUBLE_B
			b RTabIcon1_y

if Sprache = Deutsch
:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y
endif

if Sprache = Englisch
:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y
endif

;*** System-Icons.
:Icon_Reset
<MISSING_IMAGE_DATA>

:Icon_Reset_x		= .x
:Icon_Reset_y		= .y

:RIcon_Reset		w Icon_Reset
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Reset_x ! DOUBLE_B
			b Icon_Reset_y
			b USE_COLOR_INPUT

:Icon_MSlctUp		b %10000000 +1 +8		;Ungepackt +Kennbyte +8 Datenbytes.

			b %00000000			;"Pfeil nach oben"
			b %00010000
			b %00111000
			b %01111100
			b %11111110
			b %00111000
			b %00111000
			b %00000000

:Icon_MSlctUp_x		= 1				;Beite = 1 Card
:Icon_MSlctUp_y		= 8				;Höhe  = 8 Pixel

:RIcon_SlctUp		w Icon_MSlctUp
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_MSlctUp_x ! DOUBLE_B
			b Icon_MSlctUp_y
			b USE_COLOR_INPUT

:Icon_MSlctDn		b %10000000 +1 +8		;Ungepackt +Kennbyte +8 Datenbytes.

			b %00000000			;"Pfeil nach unten"
			b %00111000
			b %00111000
			b %11111110
			b %01111100
			b %00111000
			b %00010000
			b %00000000

:Icon_MSlctDn_x		= 1				;Beite = 1 Card
:Icon_MSlctDn_y		= 8				;Höhe  = 8 Pixel

:RIcon_SlctDn		w Icon_MSlctDn
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_MSlctDn_x ! DOUBLE_B
			b Icon_MSlctDn_y
			b USE_COLOR_INPUT

:Icon_Reload
<MISSING_IMAGE_DATA>

:Icon_Reload_x		= .x
:Icon_Reload_y		= .y

:RIcon_Reload		w Icon_Reload
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Reload_x ! DOUBLE_B
			b Icon_Reload_y
			b USE_COLOR_INPUT

;*** Daten für Register "Farben".
;
;--- Hinweis:
;Bei einigen Elementen (BOX_FRAME,
;BOX_USEROPT...) muss ADD1_W für die
;Linke Koordinate gesetzt werden und
;nicht für die Rechte, da sonst bei 80Z
;eine 1-Pixel-Breite Lücke entsteht.
;
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$10
:RTab1_1  = $0090
:RTab1_2  = $0028
:RTab1_3  = $00d0
:RTab1_4  = $0048
:RTab1_5  = $0000
:RLine1_1 = $00
:RLine1_2 = $48
:RLine1_3 = $68
:RLine1_4 = $20

:RegTMenu1		b 18

			b BOX_FRAME
				w R1T01
				w $0000
				b RPos1_y -$06
				b RPos1_y +RLine1_1 +$30 +$04
				w R1SizeX0 +$08 ! DOUBLE_W
				w R1SizeX1 -$08 ! DOUBLE_W ! ADD1_W

;--- Farbtext-Anzeige.
			b BOX_FRAME
				w $0000
				w $0000
				b RPos1_y +RLine1_1 -$01
				b RPos1_y +RLine1_1 +$18
				w RPos1_x +RTab1_2 -$01 ! DOUBLE_W ! ADD1_W
				w R1SizeX1 -$10 +$01 ! DOUBLE_W
::u01			b BOX_USER_VIEW
				w R1T02
				w PrintCurColName
				b RPos1_y +RLine1_1
				b RPos1_y +RLine1_1 +$10 -$01
				w RPos1_x +RTab1_2 ! DOUBLE_W
				w R1SizeX1 -$18 ! DOUBLE_W ! ADD1_W
			b BOX_FRAME
				w $0000
				w $0000
				b RPos1_y +RLine1_1 -$01
				b RPos1_y +RLine1_1 +$10
				w R1SizeX1 -$18 +$01 ! DOUBLE_W
				w R1SizeX1 -$10 +$01 ! DOUBLE_W

;--- Farbauswahl.
			b BOX_ICON
				w $0000
				w LastColEntry
				b RPos1_y +RLine1_1
				w R1SizeX1 -$18 +$01 ! DOUBLE_W
				w RIcon_SlctUp
				b (:u01 - RegTMenu1  -1)/11 +1
			b BOX_ICON
				w $0000
				w NextColEntry
				b RPos1_y +RLine1_1 +$08
				w R1SizeX1 -$18 +$01 ! DOUBLE_W
				w RIcon_SlctDn
				b (:u01 - RegTMenu1  -1)/11 +1

;--- Optionen.
			b BOX_ICON
				w R1T02a
				w ResetColors
				b RPos1_y +RLine1_4
				w RPos1_x +RTab1_1 ! DOUBLE_W
				w RIcon_Reset
				b NO_OPT_UPDATE
			b BOX_OPTION
				w R1T02c
				w $0000
				b RPos1_y +RLine1_4
				w RPos1_x +RTab1_5 ! DOUBLE_W
				w doAutoLoad
				b %10000000
			b BOX_OPTION
				w R1T02d
				w $0000
				b RPos1_y +RLine1_4
				w RPos1_x +RTab1_4 ! DOUBLE_W
				w doAutoSave
				b %01000000
			b BOX_ICON
				w R1T02b
				w ImportColors
				b RPos1_y +RLine1_4
				w RPos1_x +RTab1_3 ! DOUBLE_W
				w RIcon_Reload
				b NO_OPT_UPDATE

;--- Farbe: Vordergrund.
			b BOX_FRAME
				w R1T03
				w $0000
				b RPos1_y +RLine1_2 -$08
				b RPos1_y +RLine1_2 +$08 +$04
				w R1SizeX0 +$08 ! DOUBLE_W ! ADD1_W
				w R1SizeX1 -$08 ! DOUBLE_W
:RegTMenu1a		b BOX_USEROPT_VIEW
				w R1T04
				w PrintCurColorT
				b RPos1_y +RLine1_2
				b RPos1_y +RLine1_2 +$08 -$01
				w R1SizeX1 -$28 +$01 ! DOUBLE_W ! ADD1_W
				w R1SizeX1 -$10 ! DOUBLE_W
			b BOX_FRAME
				w $0000
				w $0000
				b RPos1_y +RLine1_2 -$01
				b RPos1_y +RLine1_2 +$08
				w RPos1_x +RTab1_2 -$01 ! DOUBLE_W ! ADD1_W
				w RPos1_x +RTab1_2 +$80 ! DOUBLE_W
			b BOX_USER
				w R1T04a
				w ColorInfoT
				b RPos1_y +RLine1_2
				b RPos1_y +RLine1_2 +$08 -$01
				w RPos1_x +RTab1_2 ! DOUBLE_W
				w RPos1_x +RTab1_2 +$80 -$01 ! DOUBLE_W ! ADD1_W

;--- Farbe: Hintergrund.
			b BOX_FRAME
				w R1T05
				w $0000
				b RPos1_y +RLine1_3 -$08
				b RPos1_y +RLine1_3 +$08 +$04
				w R1SizeX0 +$08 ! DOUBLE_W ! ADD1_W
				w R1SizeX1 -$08 ! DOUBLE_W
:RegTMenu1b		b BOX_USEROPT_VIEW
				w R1T06
				w PrintCurColorB
				b RPos1_y +RLine1_3
				b RPos1_y +RLine1_3 +$08 -$01
				w R1SizeX1 -$28 +$01 ! DOUBLE_W ! ADD1_W
				w R1SizeX1 -$10 ! DOUBLE_W
			b BOX_FRAME
				w $0000
				w $0000
				b RPos1_y +RLine1_3 -$01
				b RPos1_y +RLine1_3 +$08
				w RPos1_x +RTab1_2 -$01 ! DOUBLE_W ! ADD1_W
				w RPos1_x +RTab1_2 +$80 ! DOUBLE_W
			b BOX_USER
				w R1T06a
				w ColorInfoB
				b RPos1_y +RLine1_3
				b RPos1_y +RLine1_3 +$08 -$01
				w RPos1_x +RTab1_2 ! DOUBLE_W
				w RPos1_x +RTab1_2 +$80 -$01 ! DOUBLE_W ! ADD1_W

;*** Texte für Register "Farben".
if Sprache = Deutsch
:R1T01			b "BEREICH",NULL

:R1T02			w RPos1_x ! DOUBLE_W
			b RPos1_y +RLine1_1 +$06
			b "Name:"
			b GOTOXY
			w RPos1_x ! DOUBLE_W
			b RPos1_y +RLine1_1 +$10 +$06
			b "Info:",NULL
:R1T02a			w RPos1_x +RTab1_1 +$10 +$04 ! DOUBLE_W
			b RPos1_y +RLine1_4 +$06
			b "Reset"
:fix80a			b " /",NULL
:R1T02b
:fix80b			w RPos1_x +RTab1_3 -$26 ! DOUBLE_W
			b RPos1_y +RLine1_4 +$08 +$06
			b "Reload",NULL
:R1T02c			w RPos1_x +RTab1_5 +$08 +$04 ! DOUBLE_W
			b RPos1_y +RLine1_4 +$06
			b "GEOSBoot:"
			b GOTOXY
			w RPos1_x +RTab1_5 +$08 +$04 ! DOUBLE_W
			b RPos1_y +RLine1_4 +$09 +$06
			b "AutoLoad",NULL
:R1T02d			w RPos1_x +RTab1_4 +$08 +$04 ! DOUBLE_W
			b RPos1_y +RLine1_4 +$06
			b "Beenden:"
			b GOTOXY
			w RPos1_x +RTab1_4 +$08 +$04 ! DOUBLE_W
			b RPos1_y +RLine1_4 +$09 +$06
			b "AutoSave",NULL

:R1T03			b "VORDERGRUND",NULL

:R1T04			w RPos1_x ! DOUBLE_W
			b RPos1_y +RLine1_2 +$06
			b "Farbe:",NULL

:R1T04a			w R1SizeX1 -$36 ! DOUBLE_W
			b RPos1_y +RLine1_2 +$06
			b "->",NULL

:R1T05			b "HINTERGRUND",NULL

:R1T06			w RPos1_x ! DOUBLE_W
			b RPos1_y +RLine1_3 +$06
			b "Farbe:",NULL

:R1T06a			w R1SizeX1 -$36 ! DOUBLE_W
			b RPos1_y +RLine1_3 +$06
			b "->",NULL
endif
if Sprache = Englisch
:R1T01			b "AREA",NULL

:R1T02			w RPos1_x ! DOUBLE_W
			b RPos1_y +RLine1_1 +$06
			b "Name:"
			b GOTOXY
			w RPos1_x ! DOUBLE_W
			b RPos1_y +RLine1_1 +$10 +$06
			b "Info:",NULL
:R1T02a			w RPos1_x +RTab1_1 +$10 +$04 ! DOUBLE_W
			b RPos1_y +RLine1_4 +$06
			b "Reset"
:fix80a			b " /",NULL
:R1T02b
:fix80b			w RPos1_x +RTab1_3 -$26 ! DOUBLE_W
			b RPos1_y +RLine1_4 +$08 +$06
			b "Reload",NULL
:R1T02c			w RPos1_x +RTab1_5 +$08 +$04 ! DOUBLE_W
			b RPos1_y +RLine1_4 +$06
			b "GEOSBoot:"
			b GOTOXY
			w RPos1_x +RTab1_5 +$08 +$04 ! DOUBLE_W
			b RPos1_y +RLine1_4 +$09 +$06
			b "AutoLoad",NULL
:R1T02d			w RPos1_x +RTab1_4 +$08 +$04 ! DOUBLE_W
			b RPos1_y +RLine1_4 +$06
			b "On exit:"
			b GOTOXY
			w RPos1_x +RTab1_4 +$08 +$04 ! DOUBLE_W
			b RPos1_y +RLine1_4 +$09 +$06
			b "AutoSave",NULL

:R1T03			b "FOREGROUND",NULL

:R1T04			w RPos1_x ! DOUBLE_W
			b RPos1_y +RLine1_2 +$06
			b "Color:",NULL

:R1T04a			w R1SizeX1 -$36 ! DOUBLE_W
			b RPos1_y +RLine1_2 +$06
			b "->",NULL

:R1T05			b "BACKGROUND",NULL

:R1T06			w RPos1_x ! DOUBLE_W
			b RPos1_y +RLine1_3 +$06
			b "Color:",NULL

:R1T06a			w R1SizeX1 -$36 ! DOUBLE_W
			b RPos1_y +RLine1_3 +$06
			b "->",NULL
endif

;*** Systemfarben wechseln.
:PrintCurColName	lda	#$00			;Füllmuster für Farbbereich.
			jsr	SetPattern

			jsr	i_Rectangle		;Anzeigebereich löschen.
			b	RPos1_y +RLine1_1
			b	RPos1_y +RLine1_1 +$10 -$01
			w	RPos1_x +RTab1_2 ! DOUBLE_W
			w	R1SizeX1 -$18 ! DOUBLE_W ! ADD1_W

			lda	C_InputField		;Farbe für Anzeigebereich setzen.
			jsr	DirectColor

			lda	#$01			;Füllmuster für Registerbereich.
			jsr	SetPattern

			jsr	i_Rectangle		;Anzeigebereich Register löschen.
			b	RPos1_y +RLine1_1 +$10
			b	RPos1_y +RLine1_1 +$18 -$01
			w	RPos1_x +RTab1_2 ! DOUBLE_W
			w	R1SizeX1 -$10 ! DOUBLE_W ! ADD1_W

			lda	C_InputField		;Farbe für Registerbereich setzen.
			jsr	DirectColor

			lda	#PLAINTEXT		;Zeichenformat zurücksetzen.
			jsr	PutChar

;--- MP3-Farbgruppe ausgeben.
			LoadW	r15,Vec2ColNames1	;Zeiger Tabelle mit Farbtexten.

			lda	Vec2Color		;Zeiger auf Farbwert einlesen.
			asl
			asl
			pha
			tay
			lda	(r15L),y		;Zeiger auf Text/Zeile#1.
			sta	r0L
			iny
			lda	(r15L),y
			sta	r0H
			ldy	#(RPos1_y +RLine1_1 +$06)
			jsr	:prntCurLine		;Textzeile ausgeben.

;--- MP3-Farbwert ausgeben.
			pla				;Zeiger auf Farbwert einlesen.
			tay
			iny
			iny
			lda	(r15L),y		;Zeiger auf Text/Zeile#2.
			sta	r0L
			iny
			lda	(r15L),y
			sta	r0H
			ldy	#(RPos1_y +RLine1_1 +$08 +$06)
			jsr	:prntCurLine		;Textzeile ausgeben.

;--- MP3-Register ausgeben.
			lda	#REV_ON
			jsr	PutChar

			LoadW	r15,Vec2ColNames2	;Zeiger Tabelle mit Farbadressen.

			lda	Vec2Color		;Zeiger auf Farbwert einlesen.
			asl
			tay
			lda	(r15L),y		;Zeiger auf Text/Zeile#3.
			sta	r0L
			iny
			lda	(r15L),y
			sta	r0H
			ldy	#(RPos1_y +RLine1_1 +$10 +$06)

::prntCurLine		sty	r1H			;Cursorposition festlegen.
			LoadW	r11,(RPos1_x +RTab1_2 +$02) ! DOUBLE_W

			jmp	PutString		;Textzeile ausgeben.

;*** Zus.Mausfarbe ignorieren?
:skipMseCol		= 4				;Ja
;:skipMseCol		= 255				;Nein

;*** Zeiger auf nächsten Bereich.
:NextColEntry		ldx	Vec2Color		;Nächster Bereich.
::2			inx
			cpx	#skipMseCol		;Zus.Mausfarbe ignorieren?
			beq	:2			; => Ja, nächster Bereich...
			cpx	#MaxColSettings
			bcc	:1
			ldx	#$00
::1			jmp	SetColEntry

;*** Zeiger auf letzten Bereich.
:LastColEntry		ldx	Vec2Color		;Vorheriger Bereich.
::2			txa
			bne	:1
			ldx	#MaxColSettings
::1			dex
			cpx	#skipMseCol		;Zus.Mausfarbe ignorieren?
			beq	:2			; => Ja, vorheriger Bereich...

:SetColEntry		stx	Vec2Color
;			jsr	PrintCurColName		;Farbbereich ausgeben.

			jsr	waitNoMseKey		;Warten bis keine M-Taste gedrückt.

;*** Aktuelle Farbeinstellungen anzeigen.
:UpdateCurColor		LoadW	r15,RegTMenu1a		;Farbbereiche für Vorder- und
			jsr	RegisterUpdate		;Hintergrund anzeigen.
			LoadW	r15,RegTMenu1b
			jmp	RegisterUpdate

;*** Aktuellen Farbwert für Text ausgeben.
:PrintCurColorT		ldx	Vec2Color		;Aktuelle Farbe aus Tabelle holen.
			lda	C_FarbTab,x		;GEOS/MegaPatch-Farbtabelle holen.
			lsr				;Farbbereich anzeigen.
			lsr
			lsr
			lsr
			jmp	DirectColor

;*** Aktuellen Farbwert für Hintergrund ausgeben.
:PrintCurColorB		ldx	Vec2Color		;Aktuelle Farbe aus Tabelle holen.
			lda	C_FarbTab,x		;GEOS/MegaPatch-Farbtabelle holen.
			and	#%00001111		;Farbbereich anzeigen.
			jmp	DirectColor

;*** Farbtabelle Text/Hintergrund ausgeben.
;    Übergabe: r1L = $00=Farbtabelle anzeigen/$FF=aktualisieren.
;              Wird durch RegisterMenü gesetzt.
:ColorInfoT		lda	r1L			;Farbtabelle anzeigen?
			bne	SetColorT		; => Nein, weiter...
			lda	#(RPos1_y +RLine1_2)/8
			bne	ColorInfo

:ColorInfoB		lda	r1L			;Farbtabelle anzeigen?
			bne	SetColorB		; => Nein, weiter...
			lda	#(RPos1_y +RLine1_3)/8

:ColorInfo		sta	:2 +1

			lda	#(RPos1_x +RTab1_2)/8 ! DOUBLE_B
			sta	:2 +0

			ldx	#$00			;Farbtabelle ausgeben.
::1			txa
			pha
			lda	ColorTab,x		;Farbwert einlesen.

if Flag64_128 = TRUE_C128
			bit	graphMode		;C128/80Z-Modus?
			bpl	:40z			; => Nein, Farbe für 40Z-Modus.
::80z			txa				;VDC-Farbe anzeigen.
endif

::40z			jsr	i_UserColor		;Farbwert anzeigen.
::2			b	$00
			b	$11
			b	$01 ! DOUBLE_B
			b	$01

			inc	:2 +0

			pla
			tax
			inx				;Zeiger auf nächste Farbe setzen.
			cpx	#$10			;Alle Farben angezeigt?
			bne	:1			; => Nein, weiter...
			rts

;*** Neue Textfarbe setzen.
;HINWEIS:
;Abfrage ob Maus innerhalb Bereich, da
;die Routine auch von RegisterAllOpt
;aufgerufen wird und dabei eine neue
;Farbe ausgewählt werden würde.
:SetColorT		LoadB	r2L,RPos1_y +RLine1_2
			LoadB	r2H,RPos1_y +RLine1_2 +$08 -$01
			LoadW	r3 ,RPos1_x +RTab1_2 ! DOUBLE_W
			LoadW	r4 ,RPos1_x +RTab1_2 +$80 -$01 ! DOUBLE_W ! ADD1_W
			jsr	IsMseInRegion
			cmp	#TRUE
			beq	SetNewColT
			rts

;*** Neue Hintergrundfarbe setzen.
:SetColorB		LoadB	r2L,RPos1_y +RLine1_3
			LoadB	r2H,RPos1_y +RLine1_3 +$08 -$01
			LoadW	r3 ,RPos1_x +RTab1_2 ! DOUBLE_W
			LoadW	r4 ,RPos1_x +RTab1_2 +$80 -$01 ! DOUBLE_W ! ADD1_W
			jsr	IsMseInRegion
			cmp	#TRUE
			beq	SetNewColB
			rts

;*** Neue Vorder-/Hintergrundfarbe setzen.
:SetNewColT		lda	#$00
			b $2c
:SetNewColB		lda	#$ff
			sta	r13H

			jsr	InitVecDataTab		;Zeiger auf Systemfarben setzen.

			jsr	getSlctColor		;Zeiger auf Farbdaten berechnen.

			lda	ColorTab,x		;Farbwert einlesen.

if Flag64_128 = TRUE_C128
			bit	graphMode		;C128/80Z-Modus?
			bpl	:40z			; => Nein, Farbe für 40Z-Modus.
::80z			txa				;VDC-Farbe anzeigen.
endif

::40z			sta	r0L			;Auswahl speichern.

			lda	Vec2Color
			asl
			pha
			tay

			bit	r13H			;Vorder- oder Hintergrundfarbe?
			bpl	:0			; => Vordergrund, weiter...
			iny

::0			lda	(r14L),y		;Modus einlesen.
			and	#%11110000		;Vordergrund anzeigen?
			beq	:1			; => Nein, weiter...
			jsr	Add1High		;High-Nibble Farbwert erzeugen.

::1			pla
			tay

			bit	r13H			;Vorder- oder Hintergrundfarbe?
			bpl	:2			; => Vordergrund, weiter...
			iny

::2			lda	(r14L),y		;Modus einlesen.
			and	#%00001111		;Hintergrund anzeigen?
			beq	:3			; => Nein, weiter...
			jsr	Add1Low			;Low-Nibble Farbwert erzeugen.

::3			jmp	UpdateCurColor		;Farbwert anzeigen.

;*** Gewählte Farbe berechnen.
:getSlctColor		lda	mouseXPos +1		;Position Mauszeiger einlesen und
			lsr				;in Zeiger auf Farbtabelle wandeln.
			lda	mouseXPos +0
			ror
			lsr
			lsr

if Flag64_128 = TRUE_C128
			bit	graphMode
			bpl	:40

::80			sec
			sbc	#(RPos1_x +RTab1_2)/8*2
			lsr
			tax
			rts
endif

::40			sec
			sbc	#(RPos1_x +RTab1_2)/8
			tax
			rts

;*** Textfarbe wechseln.
:Add1High		ldy	Vec2Color
			lda	(r15L),y		;Farbwert einlesen und
			and	#%00001111		;Low-Nibble isolieren.
			sta	r0H
			lda	r0L			;Aktueller Farbwert in High-Nibble
			asl				;umwandeln.
			asl
			asl
			asl
			ora	r0H			;High-/Low-Nibble erzeugen und
			sta	(r15L),y		;neuen Farbwert speichern.
			rts

;*** Hintergrundfarbe wechseln.
:Add1Low		ldy	Vec2Color
			lda	(r15L),y		;Farbwert einlesen und
			and	#%11110000		;Low-Nibble isolieren.
			ora	r0L			;High-/Low-Nibble erzeugen und
			sta	(r15L),y		;neuen Farbwert speichern.
			rts

;*** Tabellenzeiger initialisieren.
;    Rückgabe: r14 = High-/Low-Nibble-Informationen.
;              r15 = Zeiger auf Farbdaten GEOS/GeoDesk.
:InitVecDataTab		lda	#< C_FarbTab
			ldx	#> C_FarbTab
			sta	r15L			;Zeiger auf Farbdaten festlegen.
			stx	r15H

			lda	#< ColModifyTab1
			ldx	#> ColModifyTab1
			sta	r14L			;Zeiger auf High-/Low-Nibble
			stx	r14H			;Farbinformationen speichern.

			rts

;*** Warten bis keine Maustaste gedrückt.
:waitNoMseKey		lda	mouseData		;Maustaste gedrückt?
			bpl	waitNoMseKey		; => Ja, warten...
			lda	#$00
			sta	pressFlag		;Tastenstatus löschen.
			rts

;*** Farben zurücksetzen.
:ResetColors
if Flag64_128 = TRUE_C128
			bit	graphMode		;C128/80Z-Modus?
			bpl	:40z			; => Nein, Farben für 40Z-Modus.

::80z			jsr	i_MoveData		;Standard-VDC-Farben
			w	CxFarbTabVDC		;wieder herstellen.
			w	C_FarbTab
			w	22

			jmp	UpdateCurColor		;Aktuellen Farbwert aktualisieren.
endif

::40z			jsr	i_MoveData		;Standard-MP3-Farben
			w	CxFarbTab		;wieder herstellen.
			w	C_FarbTab
			w	22

			jmp	UpdateCurColor		;Aktuellen Farbwert aktualisieren.

;*** Farben zurücksetzen.
:ImportColors		jsr	LoadColors		;Farben einlesen.
			jmp	UpdateCurColor		;Aktuellen Farbwert aktualisieren.

;*** Farben einlesen.
:LoadColors		lda	DATA_COLS +0
			ora	DATA_COLS +1		;Sind Farben definiert?
			beq	:exit			; => Nein, Ende...

if Flag64_128 = TRUE_C128
			bit	graphMode		;C128/80Z-Modus?
			bpl	:40z			; => Nein, 40Z-Modus testen.

::80z			lda	#$80			;Farben für 80Z-Modus.
			b $2c
::40z			lda	#$40			;Farben für 40Z-Modus.
			cmp	DATA_MODE		;Gespeicherte Farben kompatibel?
			bne	:exit			; => Nein, Abbruch...
endif

			jsr	i_MoveData		;Gespeicherte Farben einlesen.
			w	DATA_COLS
			w	C_FarbTab
			w	22

::exit			rts

;*** Farben speichern.
:UpdateConfig		bit	doAutoSave		;Automatisch speichern?
			bvc	:skip			; => Nein, weiter...

::update		jsr	SaveColors		;Farben einlesen.

::skip			bit	doAutoLoad		;AutoLoad-Option speichern.
			bmi	:auto
::appl			lda	#APPLICATION
			b $2c
::auto			lda	#AUTO_EXEC
			sta	HdrB000 +69
			tax

			lda	doAutoSave		;AutoSave-Option speichern.
			and	#%01000000
			eor	#%01000000
			ora	#$83
			sta	HdrB000 +68
			tay

			bit	doAutoSave		;Automatisch speichern?
			bvs	:setClass		; => Ja, weiter...

			cpx	dirEntryBuf +22		;Wurden Optionen geändert?
			bne	:setClass
			cpy	dirEntryBuf +0
			beq	:exit			; => Nein, Ende...

if Flag64_128 = TRUE_C64
::setClass		lda	#"6"
			sta	HdrB000 +87
			lda	#"4"
			sta	HdrB000 +88		;Anwendungsklasse für GEOS64.
endif
if Flag64_128 = TRUE_C128
::setClass		bit	graphMode		;40Z/80Z-Modus?
			bmi	:80z			; => 80Z, weiter...
::40z			lda	#"4"
			b $2c
::80z			lda	#"8"
			sta	HdrB000 +87
			lda	#"0"
			sta	HdrB000 +88		;Anwendungsklasse für GEOS128.
endif

			LoadW	r0,configColStd
			jsr	DeleteFile
			txa
			beq	:save
			cpx	#FILE_NOT_FOUND
			bne	:exit

::save			LoadW	r9,HdrB000
			LoadB	r10L,0
			jsr	SaveFile
;			txa				;Fehler?
;			bne	:exit			; => Ja, Abbruch...

::exit			rts

;*** Farben speichern.
:SaveColors		jsr	i_MoveData
			w	C_FarbTab
			w	DATA_COLS
			w	22

if Flag64_128 = TRUE_C128
			bit	graphMode		;C128/80Z-Modus?
			bpl	:40z			; => Nein, 40Z-Modus setzen.

::80z			lda	#$80			;Farben für 80Z-Modus.
			b $2c
endif

::40z			lda	#$40			;Farben für 40Z-Modus.
			sta	DATA_MODE

			rts

;*** Optionen.
:doAutoSave		b $00
:doAutoLoad		b $00

;*** Sortierte Farbtabelle 40Z.
:ColorTab		b $01,$0f,$0c,$0b,$00,$09,$08,$07
			b $0a,$02,$04,$06,$0e,$03,$05,$0d

;*** Farbeinstellungen.
:Vec2Color		b $00				;Zeiger aktueller Farbbereich.

;*** Max. Anzahl Farben.
:MaxColSettings		= 22

;******************************************************************************
:CxFarbTab		t "-G3_MP3_COLOR"

if Flag64_128 = TRUE_C128
;******************************************************************************
:CxFarbTabVDC		t "+G3_MP3_COLOR"
endif

;*** Tabelle zum ändern des Farbwertes.
;    Highbyte:		Textfarbe ändern.
;    Lowbyte:		Hintergrundfarbe ändern.
;    Byte #1:		Textfarbe.
;    Byte #2:		Hintergrundfarbe.
:ColModifyTab1		b %11110000,%00001111		;#0
			b %11110000,%00001111		;#1
			b %11110000,%00001111		;#2
			b %11110000,%00001111		;#3
			b %11111111,%11111111		;#4
			b %11110000,%00001111		;#5
			b %11110000,%00001111		;#6
			b %11110000,%00001111		;#7
			b %11110000,%00001111		;#8
			b %11110000,%00001111		;#9
			b %11110000,%00001111		;#10
			b %11110000,%00001111		;#11
			b %11110000,%00001111		;#12
			b %11110000,%00001111		;#13
			b %11110000,%00001111		;#14
			b %11110000,%00001111		;#15
			b %11110000,%00001111		;#16
			b %11110000,%00001111		;#17
			b %11110000,%00001111		;#18
			b %11110000,%00001111		;#19
			b %11111111,%11111111		;#20
			b %11111111,%11111111		;#21

;*** MP3-Farbgruppe/-name.
:Vec2ColNames1		w Text_1_05, Text_2_01		;#0
			w Text_1_02, Text_2_02		;#1
			w Text_1_02, Text_2_03		;#2
			w Text_1_02, Text_2_04		;#3
			w Text_1_03, Text_2_05		;#4
			w Text_1_04, Text_2_06		;#5
			w Text_1_04, Text_2_04		;#6
			w Text_1_04, Text_2_07		;#7
			w Text_1_05, Text_2_06		;#8
			w Text_1_05, Text_2_04		;#9
			w Text_1_05, Text_2_07		;#10
			w Text_1_05, Text_2_08		;#11
			w Text_1_06, Text_2_16		;#12
			w Text_1_06, Text_2_04		;#13
			w Text_1_04, Text_2_09		;#14
			w Text_1_06, Text_2_07		;#15
			w Text_1_07, Text_2_10		;#16
			w Text_1_08, Text_2_11		;#17
			w Text_1_08, Text_2_12		;#18
			w Text_1_09, Text_2_13		;#19
			w Text_1_09, Text_2_14		;#20
			w Text_1_09, Text_2_15		;#21

if Sprache = Deutsch
:Text_1_02		b "GEOS/Registerkarten:",NULL
:Text_1_03		b "GEOS/Zeiger",NULL
:Text_1_04		b "GEOS/Dialogbox:",NULL
:Text_1_05		b "GEOS/Dateiauswahlbox:",NULL
:Text_1_06		b "GEOS/Fenster:",NULL
:Text_1_07		b "GEOS/PullDown-Menu",NULL
:Text_1_08		b "GEOS/Eingabefelder:",NULL
:Text_1_09		b "GEOS/Standard:",NULL

:Text_2_01		b "Balken und Pfeile",NULL
:Text_2_02		b "Aktives Register",NULL
:Text_2_03		b "Inaktives Register",NULL
:Text_2_04		b "Textfarbe/Hintergrund",NULL
:Text_2_05		b "Mauspfeil/Pointer",NULL
:Text_2_06		b "Titel",NULL
:Text_2_07		b "System-Icons",NULL
:Text_2_08		b "Dateifenster",NULL
:Text_2_09		b "Schatten",NULL
:Text_2_10		b "(Für GEOS-Anwendungen)",NULL
:Text_2_11		b "Text-Eingabefeld",NULL
:Text_2_12		b "Inaktives Optionsfeld",NULL
:Text_2_13		b "Hintergrund/Anwendungen",NULL
:Text_2_14		b "Rahmen",NULL
:Text_2_15		b "Mauszeiger",NULL
:Text_2_16		b "Titelzeile/Statuszeile",NULL
endif
if Sprache = Englisch
:Text_1_02		b "GEOS/Register cards:",NULL
:Text_1_03		b "GEOS/Pointer",NULL
:Text_1_04		b "GEOS/Dialogue box:",NULL
:Text_1_05		b "GEOS/File selector box:",NULL
:Text_1_06		b "GEOS/Window:",NULL
:Text_1_07		b "GEOS/PullDown menu",NULL
:Text_1_08		b "GEOS/Input fields:",NULL
:Text_1_09		b "GEOS/Default:",NULL

:Text_2_01		b "Scrollbar and arrows",NULL
:Text_2_02		b "Active register",NULL
:Text_2_03		b "Inactive register",NULL
:Text_2_04		b "Text color/Background",NULL
:Text_2_05		b "Mouse/Pointer",NULL
:Text_2_06		b "Title",NULL
:Text_2_07		b "System icons",NULL
:Text_2_08		b "File window",NULL
:Text_2_09		b "Shadow",NULL
:Text_2_10		b "(For GEOS applications)",NULL
:Text_2_11		b "Input field for text",NULL
:Text_2_12		b "Inactive option field",NULL
:Text_2_13		b "Background/Applications",NULL
:Text_2_14		b "Border",NULL
:Text_2_15		b "Mouse",NULL
:Text_2_16		b "Titlebar/Statusbar",NULL
endif

;*** MP3-Registeradressen.
:Vec2ColNames2		w Text_3_00
			w Text_3_01
			w Text_3_02
			w Text_3_03
			w Text_3_04
			w Text_3_05
			w Text_3_06
			w Text_3_07
			w Text_3_08
			w Text_3_09
			w Text_3_10
			w Text_3_11
			w Text_3_12
			w Text_3_13
			w Text_3_14
			w Text_3_15
			w Text_3_16
			w Text_3_17
			w Text_3_18
			w Text_3_19
			w Text_3_20
			w Text_3_21

:Text_3_00		b "  -> $9FEA = C_Balken",NULL	;#0
:Text_3_01		b "  -> $9FEB = C_Register",NULL;#1
:Text_3_02		b "  -> $9FEC = C_RegisterOff",NULL;#2
:Text_3_03		b "  -> $9FED = C_RegisterBack",NULL;#3
if Sprache = Deutsch
:Text_3_04		b "  -> $9FEE = C_Mouse (n.v.)",NULL;#4
endif
if Sprache = Englisch
:Text_3_04		b "  -> $9FEE = C_Mouse (unused)",NULL;#4
endif
:Text_3_05		b "  -> $9FEF = C_DBoxTitel",NULL;#5
:Text_3_06		b "  -> $9FF0 = C_DBoxBack",NULL;#6
:Text_3_07		b "  -> $9FF1 = C_DBoxIcon",NULL;#7
:Text_3_08		b "  -> $9FF2 = C_FBoxTitel",NULL;#8
:Text_3_09		b "  -> $9FF3 = C_FBoxBack",NULL;#9
:Text_3_10		b "  -> $9FF4 = C_FBoxDIcon",NULL;#10
:Text_3_11		b "  -> $9FF5 = C_FBoxFiles",NULL;#11
:Text_3_12		b "  -> $9FF6 = C_WinTitel",NULL;#12
:Text_3_13		b "  -> $9FF7 = C_WinBack",NULL	;#13
:Text_3_14		b "  -> $9FF8 = C_WinShadow",NULL;#14
:Text_3_15		b "  -> $9FF9 = C_WinIcon",NULL	;#15
:Text_3_16		b "  -> $9FFA = C_PullDMenu",NULL;#16
:Text_3_17		b "  -> $9FFB = C_InputField",NULL;#17
:Text_3_18		b "  -> $9FFC = C_InputFieldOff",NULL;#18
:Text_3_19		b "  -> $9FFD = C_GEOS_BACK",NULL;#19
:Text_3_20		b "  -> $9FFE = C_GEOS_FRAME",NULL;#20
:Text_3_21		b "  -> $9FFF = C_GEOS_MOUSE",NULL;#21

;*** Info-Block für Konfigurationsdatei.
:configColStd		b "GEOS.MP3.COLOR",NULL

:HdrB000		w configColStd
::002			b $03,$15
			b $bf
			b %11111111,%11111111,%11111111
			b %10000000,%00000000,%00000001
			b %10000000,%00000000,%00001101
			b %10011100,%00111000,%00010001
			b %10011100,%00111000,%00010001
			b %10011100,%00111000,%00010001
			b %10000000,%00000000,%00001101
			b %10111110,%01111100,%00000001
			b %10000000,%00000000,%00000001
			b %10011100,%00000000,%00000001
			b %10011100,%00000000,%00000001
			b %10011100,%00000000,%00000001
			b %10000000,%10001011,%10011001
			b %10111110,%11011010,%01000101
			b %10000000,%10101011,%10001001
			b %10000000,%10001010,%00000101
			b %10000000,%10001010,%00011001
			b %10000000,%00000000,%00000001
			b %10101010,%10101010,%10101011
			b %11010101,%01010101,%01010101
			b %11111111,%11111111,%11111111

::068			b $83				;USR
::069			b AUTO_EXEC			;GEOS-Autostart-Datei
::070			b SEQUENTIAL			;GEOS-Dateiformat SEQ
::071			w DATA_BUF			;Programm-Anfang
::073			w DATA_BUF +254			;Programm-Ende
::075			w DATA_BUF			;Programm-Start
::077			b "MP3COLDATA64"		;Klasse
::089			b "V1.0"			;Version
			e (:089 +6)
::095			b $00				;Reserviert
::096			b $40				;Bildschirmflag: 40Z/80Z
::097			b "GEOS/MP3"			;Autor
			e (:097 +20)
::117			e (:117 +12)			;Anwendung/Klasse
::129			e (:129 +5)			;Anwendung/Version
::134			e (:134 +26)			;Reserviert

:HdrB160		b NULL
::HdrEnd		s (HdrB000+256)-:HdrEnd

;*** Vorlage für Startdatei.
:BOOTMP3COL		lda	DATA_COLS +0
			ora	DATA_COLS +1		;Sind Farben definiert?
			beq	:exit			; => Nein, Ende...

			bit	c128Flag		;C128?
			bpl	:40z			; => Nein, 40Z-Modus verwenden.
			bit	graphMode		;C128/80Z-Modus?
			bpl	:40z			; => Nein, 40Z-Modus testen.

::80z			lda	#$80			;Farben für 80Z-Modus.
			b $2c
::40z			lda	#$40			;Farben für 40Z-Modus.
			cmp	DATA_MODE		;Gespeicherte Farben kompatibel?
			bne	:exit			; => Nein, Abbruch...

			jsr	i_MoveData		;Gespeicherte Farben einlesen.
			w	DATA_COLS
			w	C_FarbTab
			w	22

::exit			jmp	EnterDeskTop		;Programm beenden.

			e (BOOTMP3COL +128)

::DATA_MODE		b $00
::RESERVED		b $00,$00,$00
::DATA_COLS		s 22

			e (BOOTMP3COL +254)

:BOOTMP3COL_END
;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_REGISTER
;******************************************************************************
