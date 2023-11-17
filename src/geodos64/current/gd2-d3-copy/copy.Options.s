; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t	"TopSym"
			t	"Sym128.erg"
			t	"TopMac"
			t	"GD_Mac"
			t	"src.GeoDOS.ext"
endif

			n	"mod.#201.obj",NULL
			f	SYSTEM
			c	"GD_Copy     V2.1",NULL
			a	"M. Kanet",NULL
			i
<MISSING_IMAGE_DATA>

			o	ModStart
			r	EndAreaCBM

			jmp	SetOptions

;*** Unterprogramme.
			t	"-GetDriver"
			t	"-GetConvTab1"
			t	"-CBM_SetName"

;*** Farben für Options-Box setzen.
:SetOptions		stx	OptionMode		;Rückkehr-Option merken.

;*** Laufwerke ermitteln.
:GetCurPrinter		ldy	#4
			lda	#$00			;Tabelle mit den verfügbaren
::101			sta	PrntDiskTab-1,y		;Laufwerken für Applikationen löschen.
			dey
			bne	:101

			ldx	#8
::102			lda	DriveTypes-8,x		;Laufwerk vorhanden ?
			beq	:103			;Nein, weiter...
			lda	DriveModes-8,x		;Laufwerksmodus einlesen...
			and	#%00001000		;Aktuelles Laufwerk = RAM-Laufwerk ?
			beq	:103			;Nein, weiter...
			txa				;Laufwerk in Tabelle eintragen.
			sta	PrntDiskTab ,y
			iny				;Zähler für "Laufwerke in Tabelle"
			cpy	#4			;korrigieren. Tabelle voll ?
			beq	InitSearch		;Ja, Ende...
::103			inx				;Zeiger auf nächstes Laufwerk.
			cpx	#12			;Laufwerke 8-11 getestet ?
			bne	:102			;Nein, weiter...

			ldx	#8
::104			lda	DriveTypes-8,x		;Laufwerk vorhanden ?
			beq	:105			;Nein, weiter...
			lda	DriveModes-8,x		;Laufwerksmodus einlesen.
			and	#%00001000		;Aktuelles Laufwerk = RAM-Laufwerk ?
			bne	:105			;Ja, weiter...
			txa				;Laufwerk in Tabelle eintragen.
			sta	PrntDiskTab ,y
			iny				;Zähler für "Laufwerke in Tabelle"
			cpy	#4			;korrigieren. Tabelle voll ?
			beq	InitSearch		;Ja, Ende...
::105			inx				;Zeiger auf nächstes Laufwerk.
			cpx	#12			;Laufwerke 8-11 getestet ?
			bne	:104			;Nein, weiter...

;*** Suche initialisieren.
:InitSearch		ldx	#$00
::101			stx	LookOnDrive		;Zeiger auf Laufwerkstabelle.
			lda	PrntDiskTab ,x		;Laufwerk verfügbar ?
			beq	:103			;Nein, => Kein Druckertreiber.
			jsr	NewDrive		;Laufwerk aktivieren.

			jsr	NewOpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:102			; => Ja, Abbruch...

			LoadW	r6 ,PrntFileName
			jsr	FindFile		;Druckertreiber suchen.
			txa				;Diskettenfehler ?
			beq	ContInitOpt_a		; => Nein, initialisieren.

;*** Suche auf nächstem Laufwerk.
::102			ldx	LookOnDrive
			inx
			cpx	#$04			;Alle Laufwerke getestet ?
			bcc	:101			;Nein, weiter...

::103			ldy	#62			;Vorgabe für Druckertreiber.
			jsr	DoStdPageSize
			jmp	ContInitOpt_b

;*** Options-Menü initialisieren.
:ContInitOpt_a		jsr	GetPrnDim
:ContInitOpt_b		jsr	ChkPageSize		;Seitenlänge bestimmen.

			ClrB	V201a0
			jsr	L201a0			;Linken Rand bestimmen.

;*** Rücksprung in Font/Druckerwahl.
			ldx	OptionMode		;Rückkehr aus Drucker/Font-Wahl ?
			beq	SetOpt_a		;Nein, Normal starten.
			rts				;Zurück zur Drucker-/Font-Auswahl.

;*** Parameter-Fenster zeichnen.
:SetOpt_a		jsr	ClrScreen

			jsr	i_C_MenuTitel
			b	$00,$00,$28,$01
			jsr	i_C_MenuBack
			b	$00,$01,$28,$18

			Display	ST_WR_FORE

			FrameRec$2f,$c7,$00c7,$013f,%11111111
			FillPRec$00,$2f,$2f,$00d0,$010f
			jsr	i_C_Register
			b	$1a,$05,$08,$01

			jsr	UseGDFont
			PrintStrgMenuText
			jsr	UseSystemFont

			lda	#$30
::101			sta	:102 +1
			jsr	i_BitmapUp
			w	Icon_226
::102			b	$00,$ff,$01,$08
			lda	:102 +1
			add	8
			cmp	#$c8
			bne	:101

			FrameRec$2f,$c7,$0007,$00c0,%11111111
			FillPRec$0a,$30,$c7,$00b8,$00bf

;*** Parameter-Texte ausgeben.
			lda	V201a0			;Notitzblock beschriften.
			jsr	PutWinText

;*** Parameter eingeben.
:SetOpt_b		Display	ST_WR_FORE
			ClrB	InputMode
			LoadW	otherPressVec,ChkOptSlct

			jsr	SetHelp

			jsr	i_C_MenuMIcon
			b	$00,$01,$28,$03

			LoadW	r0,Icon_2Tab1
			jmp	DoIcons			;Icons aktivieren.

;*** Zeiger auf Hilfedatei bereitstellen.
:SetHelp		LoadW	r0,HelpFileName
			lda	#<SetOpt_a
			ldx	#>SetOpt_a
			jmp	InstallHelp

;***  Standardparameter einlesen.
:StandardOpt		jsr	CopyStdOpt
			jsr	L201a0			;Seitenformat bestimmen.
			lda	V201a0			;Seite neu aufbauen.
			jmp	PutWinText

;*** Standardparameter einlesen.
:CopyStdOpt		ldy	#$00
::101			lda	V201c2,y		;Standard-Werte in
			sta	CTabCBMtoDOS,y		;Zwischenspeicher übertragen.
			iny
			cpy	#V201c4-V201c2
			bne	:101
			rts

;*** Zurück zu GeoDOS
:L201ExitGD		jsr	i_C_ColorClr
			b	$00,$00,$28,$19
			lda	#$00			;GEOS-Vektoren zurücksetzen.
			sta	otherPressVec+0
			sta	otherPressVec+1
			jmp	InitScreen		;Ende...

;*** Seitenformat bestimmen.
:L201a0			lda	#$60			;Linker Rand für V2.0-Texte.
			ldx	GW_Version
			beq	:101
			lda	#$10			;Linker Rand für V2.1-Texte.
::101			sta	V201a4+0		;Werte für linken Rand speichern.
			ClrB	V201a4+1
			rts

;*** Startadresse Daten-Liste nach ":a9".
:L201b0			lda	V201a0			;Aktuelle Menüseite ermitteln.
			asl
			tax
			lda	V201m2+0,x		;Startadresse für Daten-Liste nach
			sta	a9L			;":a9" kopieren.
			lda	V201m2+1,x
			sta	a9H
			rts

;*** Werte aus Daten-Liste nach ":r2" für GEOS-Grafik-Routinen.
:L201c0			ldy	#$05
::101			lda	(a9L),y
			sta	r2,y
			dey
			bpl	:101
			rts

;*** Routine in ":a9" + yReg aufrufen.
:L201e0			lda	(a9L),y			;Low -Byte der aufzurufenden Routine
			pha				;einlesen.
			iny
			lda	(a9L),y			;High-Byte der aufzurufenden Routine
			tax				;einlesen.
			pla
			jmp	CallRoutine		;Routine aufrufen.

;*** Options-Icon-Fläche füllen.
:L201f0			pha
			lda	#$00
			jsr	SetPattern		;Muster setzen.
			jsr	Rectangle		;Inhalt löschen.

			lda	r3L			;X-Koordinate für Farbe berechnen.
			lsr
			lsr
			lsr
			sta	:102 +0
			lda	r2L			;Y-Koordinate.
			lsr
			lsr
			lsr
			sta	:102 +1
			sec				;Breite.
			lda	r4L
			sbc	r3L
			lsr
			lsr
			lsr
			add	1
			sta	:102 +2

			pla				;Option gewählt ? (AKKU = $02)
			beq	:101			;Nein, weiter...

			AddVBW	1,r3			;Schalter zeichnen.
			SubVW	1,r4
			inc	r2L
			dec	r2H
			Pattern	1
			jsr	Rectangle

::101			jsr	i_ColorBox		;Farbe setzen.
::102			b	$00,$00,$00,$01,$01
			rts

;*** Zahlenwert ausgeben.
:L201g0			sta	r0L			;Zahlenwert nach ":r0".
			stx	r0H
			tya				;Startadresse Daten-Liste berechnen.
			asl
			tax
			lda	V201m4+0,x
			sta	a8L
			lda	V201m4+1,x
			sta	a8H
			ldy	#$00
			lda	(a8L),y			;X-Koordinate für Zahlenausgabe.
			pha
			iny
			lda	(a8L),y
			pha
			iny
			lda	(a8L),y			;Y-Koordinate für Zahlenausgabe.
			pha
			iny
			lda	(a8L),y			;Einsprungs-Adresse für Zahlenausgabe.
			sta	a7L
			iny
			lda	(a8L),y
			sta	a7H
			pla				;Register belegen.
			tay
			pla
			tax
			pla
			jmp	(a7)			;Zahl ausgeben.

;*** Seite wechseln.
:ChangePage		sec				;Y-Koordinate der Maus einlesen.
			lda	mouseYPos		;Testen ob Maus innerhalb des
			sbc	#184			;"Eselsohrs" angeklickt wurde.
			bcs	:102
::101			rts				;Nein, Rücksprung.

::102			tay
			sec
			lda	mouseXPos+0
			sbc	#<168
			tax
			lda	mouseXPos+1
			sbc	#>168
			bne	:101
			cpx	#16			;Ist Maus innerhalb des "Eselsohrs" ?
			bcs	:101			;Nein, Rücksprung.
			cpy	#16
			bcs	:101
			sty	r0L
			txa				;Feststellen: Seite vor/zurück ?
			eor	#%00001111
			cmp	r0L
			bcs	GotoNextPage		;Seite vor.
			bcc	GotoLastPage		;Seite zurück.

;*** Weiter auf nächste Seite.
:GotoNextPage		ldx	V201a0
			inx
			cpx	#$0e
			bne	:101
			ldx	#$00
::101			jmp	GotoNewPage

;*** Zurück zur letzten Seite.
:GotoLastPage		ldx	V201a0
			dex
			cpx	#$ff
			bne	GotoNewPage
			ldx	#$0d
:GotoNewPage		stx	V201a0
			txa
			jmp	PutWinText

;*** Option-Icon gewählt
:OptIconSlct		lda	r0L
			sub	10

;*** Inhalt des Windows ausgeben.
:PutWinText		sta	V201a0			;Neue Parameter-Seite merken.

			jsr	i_C_MenuBack
			b	$01,$06,$17,$12
			jsr	i_ColorBox
			b	$15,$17,$02,$02,$01

			FillPRec$00,$30,$af,$0008,$00b7
			FillPRec$00,$28,$2f,$0010,$00af
			jsr	i_C_Register
			b	$02,$05,$14,$01

			jsr	UseGDFont		;GeoDOS-Font aktivieren.
			lda	V201a0			;Titel-Überschrift ausgeben.
			asl
			pha
			tax
			lda	V201d0+0,x
			sta	r0L
			lda	V201d0+1,x
			sta	r0H
			ClrB	currentMode
			LoadW	r11,$0014
			LoadB	r1H,$2e
			jsr	PutString
			jsr	UseSystemFont		;GEOS-Font aktivieren.
			pla
			tax
			lda	V201m0+0,x		;Fenster-Texte ausgeben.
			sta	r0L
			lda	V201m0+1,x
			sta	r0H
			jsr	PutString

;*** Klick-Positionen anzeigen.
:SetClkPos		jsr	L201b0			;Startadresse Daten-Liste ermitteln.

::101			ldy	#$00
			lda	(a9L),y			;Ende der Daten-Liste erreicht ?
			bne	:102			;Nein, weiter.
			ClrB	pressFlag
			rts				;Ende.

::102			jsr	L201c0			;Werte aus Daten-Liste nach ":r2".

			ldy	#$07			;Inhalt des Options-Icons
			lda	(a9L),y			;definieren.
			tax
			dey
			lda	(a9L),y
			ldy	#$00
			jsr	CallRoutine
			tya
			bmi	:103

			jsr	L201f0			;Falls "Klick-Option",
							;Rechteck mit Muster füllen.

::103			jsr	L201c0			;Werte aus Daten-Liste nach ":r2".
			lda	r2H			;Falls Wert für "Y-unten" = NULL, kein
			beq	:104			;Rechteck zeichnen.

			SubVW	1,r3			;Grenzen des Rechtecks -1.
			AddVBW	1,r4
			dec	r2L
			inc	r2H

			lda	#%11111111		;Rahmen um Options-Icon zeichnen.
			jsr	FrameRectangle

::104			AddVBW	10,a9			;Zeiger auf nächsten Wert in Liste.
			jmp	:101

;*** Prüfen ob Option angeklickt.
:ChkOptSlct		bit	InputMode
			beq	:101

			LoadB	keyData,CR
			lda	keyVector +0
			ldx	keyVector +1
			jsr	CallRoutine

::101			LoadB	r2L,$30
			LoadB	r2H,$bf
			LoadW	r3 ,$00c8
			LoadW	r4 ,$013f
			jsr	IsMseInRegion
			tax
			bne	:102
			jmp	TestClkOpt

::102			lda	mouseYPos
			sub	$30
			lsr
			lsr
			lsr
			tax
			lda	V201m1,x
			bpl	:104
::103			rts

::104			pha
			cli
			NoMseKey			;Warten bis keine Maustaste gedrückt.
			pla
			cmp	V201a0
			beq	:103

			jmp	PutWinText

;*** Mausklick auf Optionsfeld ?
:TestClkOpt		jsr	L201b0			;Startadresse Daten-Liste ermitteln.

::101			ldy	#$00
			lda	(a9L),y			;Ende der Daten-Liste erreicht ?
			bne	:102			;Nein, weiter.
			rts				;Ende.

::102			jsr	L201c0			;Werte aus Daten-Liste nach ":r2".
			jsr	IsMseInRegion		;Ist Maus innerhalb eines Options-
			tax				;Icons ?
			beq	:103			;Nein, weitertesten.

			ldy	#$08
			jsr	L201e0			;Routine aus Daten-Liste aufrufen.
			jsr	SetClkPos		;Neuen Wert für Option anzeigen.
			cli
			NoMseKey			;Warten bis keine Maustaste gedrückt.
			rts				;Ende.

::103			AddVBW	10,a9
			jmp	:101

;*** Parameter anzeigen.
:Def1a			jsr	i_BitmapUp
			w	Icon_221
			b	$02,$38,$02,$10
			jsr	i_ColorBox
			b	$02,$07,$02,$02,$01

			jsr	i_BitmapUp
			w	Icon_222
			b	$02,$50,$02,$10
			jsr	i_ColorBox
			b	$02,$0a,$02,$02,$01

			jsr	i_BitmapUp
			w	Icon_223
			b	$02,$68,$02,$10
			jsr	i_ColorBox
			b	$02,$0d,$02,$02,$01

			jsr	i_BitmapUp
			w	Icon_224
			b	$02,$80,$02,$10
			jsr	i_ColorBox
			b	$02,$10,$02,$02,$01

			jsr	i_BitmapUp
			w	Icon_225
			b	$02,$98,$02,$10
			jsr	i_ColorBox
			b	$02,$13,$02,$02,$01

			jsr	UseGDFont
			ClrB	currentMode

			LoadB	r1H,66			;Übersetzungstabelle DOS - CBM.
			lda	#<CTabDOStoCBM +1
			ldx	#>CTabDOStoCBM +1
			ldy	CTabDOStoCBM
			jsr	Def1_a

			LoadB	r1H,90			;Übersetzungstabelle CBM - DOS.
			lda	#<CTabCBMtoDOS +1
			ldx	#>CTabCBMtoDOS +1
			ldy	CTabCBMtoDOS
			jsr	Def1_a

			LoadB	r1H,114			;Übersetzungstabelle CBM - CBM.
			lda	#<CTabCBMtoCBM +1
			ldx	#>CTabCBMtoCBM +1
			ldy	CTabCBMtoCBM
			jsr	Def1_a

			PrintXY	40,138,PrntFileName
			PrintXY	40,158,UsedGWFont

			LoadW	r11,40			;Punktgröße ausgeben.
			LoadB	r1H,166
			lda	UsedPointSize
			sta	r0L
			ClrB	r0H
			lda	#%11000000
			jsr	PutDecimal

			PrintStrgV201g0

			ldy	#$ff			;Keinen Rahmen zeichnen.
			rts

;*** Übersetzungstabelle ausgeben.
:Def1_a			cpy	#$00
			bne	:101
			lda	#<V201g1
			ldx	#>V201g1
::101			sta	r0L
			stx	r0H
			LoadW	r11,40

			lda	#$00
::102			pha
			tay
			lda	(r0L),y
			jsr	SmallPutChar
			pla
			add	1
			cmp	#16
			bcc	:102
			rts

;*** Parameter anzeigen (Fortsetzung).
:Def2a			ldx	SetDateTime		;Datum von Original-Datei.
			bne	:101
			ldy	#$02
::101			rts

:Def2b			ldx	SetDateTime		;Datum von GEOS.
			beq	:101
			ldy	#$02
::101			rts

:Def2c			ldx	OverWrite		;Dateien löschen.
			bne	:101
			ldy	#$02
::101			rts

:Def2d			ldx	OverWrite		;Dateien übergehen.
			cpx	#$7f
			bne	:101
			ldy	#$02
::101			rts

:Def2e			ldx	OverWrite		;Abfrage.
			bpl	:101
			ldy	#$02
::101			rts

:Def2f			ldx	FileNameFormat		;Dateiname '8+3'.
			bne	:101
			ldy	#$02
::101			rts

:Def2g			ldx	FileNameFormat		;Dateiname packen.
			beq	:101
			ldy	#$02
::101			rts

:Def3a			ldx	DOS_LfMode		;Linefeed.
			beq	:101
			ldy	#$02
::101			rts

:Def3e			bit	CBM_FileTMode
			bpl	Def3b
			rts
:Def3b			ldx	CBMFileType		;Dateityp = SEQ.
			cpx	#$81
			bne	:101
			ldy	#$02
::101			rts

:Def3f			bit	CBM_FileTMode
			bpl	Def3c
			rts
:Def3c			ldx	CBMFileType		;Dateityp = PRG.
			cpx	#$82
			bne	:101
			ldy	#$02
::101			rts

:Def3g			bit	CBM_FileTMode
			bpl	Def3d
			rts
:Def3d			ldx	CBMFileType		;Dateityp = USR.
			cpx	#$83
			bne	:101
			ldy	#$02
::101			rts

:Def3h			bit	CBM_FileTMode
			bpl	:101
			ldy	#$02
::101			rts

:Def4a			ldx	CBM_LfMode		;LF ignorieren.
			beq	:101
			ldy	#$02
::101			rts

:Def4b			ldx	FileNameMode		;MSDOS-Namen vorschlagen.
			bne	:101
			ldy	#$02
::101			rts

:Def4c			ldx	FileNameMode		;Alle MSDOS-Namen neu eingeben.
			beq	:101
			ldy	#$02
::101			rts

;*** Parameter anzeigen (Fortsetzung).
:Def5a			ldx	GW_Version		;GeoWrite V2.0.
			bne	:101
			ldy	#$02
::101			rts

:Def5b			ldx	GW_Version		;GeoWrite V2.1.
			beq	:101
			ldy	#$02
::101			rts

:Def5c			lda	GW_FirstPage+0		;Erste Seiten-Nummer.
			ldx	GW_FirstPage+1
			ldy	#$00
			jmp	L201g0

:Def5d			lda	GW_Format		;Text neu formatieren.
			and	#%00010000
			bne	:101
			ldy	#$02
::101			rts

:Def5e			ldx	DOS_FfMode		;Seitenvorschub übernehmen.
			beq	:101
			ldy	#$02
::101			rts

:Def5f			ldx	DOS_FfMode		;Seitenvorschub ignorieren.
			bne	:101
			ldy	#$02
::101			rts

:Def5g			lda	LinesPerPage		;Anzahl Zeilen pro Seite #2.
			ldx	#$00
			ldy	#$01
			jmp	L201g0

:Def6a			ldx	CBM_FfMode		;Seitenvorschub ignorieren.
			beq	:101
			ldy	#$02
::101			rts

:Def7a			ldx	Txt_LfMode
			cpx	#%10000000
			bne	:101
			ldy	#$02
::101			rts

:Def7b			ldx	Txt_LfMode
			cpx	#%01000000
			bne	:101
			ldy	#$02
::101			rts

:Def8a			ldx	Txt_FfMode		;Seitenvorschub ignorieren.
			beq	:101
			ldy	#$02
::101			rts

:Def8b			ldx	Txt_FfMode		;Seitenvorschub ignorieren.
			bne	:101
			ldy	#$02
::101			rts

:Def9a			lda	GW_LRand+0		;Linker Rand.
			ldx	GW_LRand+1
			ldy	#$02
			jmp	L201g0

:Def9b			jsr	TestTabPos		;Tabulatoren testen.
			lda	GW_RRand+0		;Rechter Rand.
			ldx	GW_RRand+1
			ldy	#$03
			jmp	L201g0

:Def9c			lda	GW_AbsatzTab+0		;Absatz-Tabulator.
			ldx	GW_AbsatzTab+1
			ldy	#$04
			jmp	L201g0

:Def9d			ldx	#$01			;Dezimal-Tabulator #1.
			b $2c
:Def9f			ldx	#$03			;Dezimal-Tabulator #2.
			b $2c
:Def9h			ldx	#$05			;Dezimal-Tabulator #3.
			b $2c
:Def9j			ldx	#$07			;Dezimal-Tabulator #4.
			b $2c
:Def9l			ldx	#$09			;Dezimal-Tabulator #5.
			b $2c
:Def9n			ldx	#$0b			;Dezimal-Tabulator #6.
			b $2c
:Def9p			ldx	#$0d			;Dezimal-Tabulator #7.
			b $2c
:Def9r			ldx	#$0f			;Dezimal-Tabulator #8.

			lda	GW_Tab1,x
			bpl	:101
			ldy	#$02
::101			rts

;*** Parameter anzeigen (Fortsetzung).
:Def9e			ldy	#$00			;Tabulator-Position #1.
			b $2c
:Def9g			ldy	#$02			;Tabulator-Position #2.
			b $2c
:Def9i			ldy	#$04			;Tabulator-Position #3.
			b $2c
:Def9k			ldy	#$06			;Tabulator-Position #4.
			b $2c
:Def9m			ldy	#$08			;Tabulator-Position #5.
			b $2c
:Def9o			ldy	#$0a			;Tabulator-Position #6.
			b $2c
:Def9q			ldy	#$0c			;Tabulator-Position #7.
			b $2c
:Def9s			ldy	#$0e			;Tabulator-Position #8.

			lda	GW_Tab1+0,y
			pha
			lda	GW_Tab1+1,y
			tax
			tya
			lsr
			add	5
			tay
			pla
			jmp	L201g0

:Def10a			ldx	LinkFiles
			beq	:101
			ldy	#$02
::101			rts

:Def10b			lda	LinkFiles
			and	#%00100000
			beq	:101
			ldy	#$02
::101			rts

:Def10c			lda	LinkFiles
			and	#%01000000
			beq	:101
			ldy	#$02
::101			rts

:Def10d			lda	LinkFiles
			and	#%10000000
			beq	:101
			ldy	#$02
::101			rts

:Def11a			ldx	GW_Modify
			bne	:101
			ldy	#$02
::101			rts

:Def11b			lda	GW_Modify
			cmp	#%01000000
			bne	:101
			ldy	#$02
::101			rts

:Def11c			lda	GW_Modify
			cmp	#%10000000
			bne	:101
			ldy	#$02
::101			rts

:Def11d			lda	GW_Modify
			cmp	#%11000000
			bne	:101
			ldy	#$02
::101			rts

;*** Parameter definieren.
:Set2a			lda	#$00			;Datum aus Ziel-Datei.
			b $2c
:Set2b			lda	#$ff			;Datum von GEOS.
			sta	SetDateTime
			rts

:Set2c			lda	#$00			;Dateien löschen.
			b $2c
:Set2d			lda	#$7f			;Dateien übergehen.
			b $2c
:Set2e			lda	#$ff			;Abfrage.
			sta	OverWrite
			rts

:Set2f			lda	#$00			;Dateien übergehen.
			b $2c
:Set2g			lda	#$ff			;Abfrage.
			sta	FileNameFormat
			rts

:Set3a			lda	DOS_LfMode		;Linefeed.
			eor	#$ff
			sta	DOS_LfMode
			rts

:Set3b			lda	#$81			;Dateityp = SEQ.
			b $2c
:Set3c			lda	#$82			;Dateityp = PRG.
			b $2c
:Set3d			lda	#$83			;Dateityp = USR.
			sta	CBMFileType
			ClrB	CBM_FileTMode
			rts

:Set3e			lda	CBM_FileTMode
			eor	#%10000000
			sta	CBM_FileTMode
			rts

:Set4a			lda	CBM_LfMode		;Linefeed.
			eor	#$ff
			sta	CBM_LfMode
			rts

:Set4b			lda	#$00			;Namen vorschlagen.
			b $2c
:Set4c			lda	#$ff			;Namen neu eingeben.
			sta	FileNameMode
			rts

:Set5a			lda	#<V201c0		;GeoWrite V2.0
			ldx	#>V201c0
			ldy	#$00
			beq	Set5
:Set5b			lda	#<V201c1		;GeoWrite V2.1
			ldx	#>V201c1
			ldy	#$01
:Set5			sta	r0L			;GeoWrite-Version festlegen.
			stx	r0H
			sty	GW_Version
			jsr	L201a0			;Linken Rand bestimmen.
			ldy	#21
::101			lda	(r0L),y
			sta	GW_LRand,y
			dey
			bpl	:101
			rts

:Set5c			lda	#$00			;Erste Seiten-Nummer.
			jmp	SetInpOpt

:Set5d			lda	GW_Format		;Text neu formatieren.
			eor	#%00010000
			sta	GW_Format
			rts

:Set5e			lda	#$ff			;Seitenvorschub übernehmen.
			b $2c
:Set5f			lda	#$00			;Seitenvorschub ignorieren.
			sta	DOS_FfMode
			rts

:Set5g			lda	#$01			;Anzahl Zeilen pro Seite.
			jmp	SetInpOpt

:Set6a			lda	CBM_FfMode		;Linefeed.
			eor	#$ff
			sta	CBM_FfMode
			rts

:Set7a			bit	Txt_LfMode		;Linefeed.
			bpl	:101
			lda	#%00000000
			b $2c
::101			lda	#%10000000
::102			sta	Txt_LfMode
			rts

:Set7b			bit	Txt_LfMode		;Linefeed.
			bvs	:101
			lda	#%01000000
			b $2c
::101			lda	#%00000000
::102			sta	Txt_LfMode
			rts

;*** Parameter definieren (Fortsetzung).
:Set8a			lda	Txt_FfMode
			eor	#$ff			;Seitenvorschub übernehmen.
			sta	Txt_FfMode
			rts

:Set9a			ldx	#$01			;Dezimal-Tabulator #1.
			b $2c
:Set9b			ldx	#$03			;Dezimal-Tabulator #2.
			b $2c
:Set9c			ldx	#$05			;Dezimal-Tabulator #3.
			b $2c
:Set9d			ldx	#$07			;Dezimal-Tabulator #4.
			b $2c
:Set9e			ldx	#$09			;Dezimal-Tabulator #5.
			b $2c
:Set9f			ldx	#$0b			;Dezimal-Tabulator #6.
			b $2c
:Set9g			ldx	#$0d			;Dezimal-Tabulator #7.
			b $2c
:Set9h			ldx	#$0f			;Dezimal-Tabulator #8.

			lda	GW_Tab1,x
			eor	#%10000000
			sta	GW_Tab1,x
			rts

:Set9i			lda	#$02			;Tabulator-Position #1.
			b $2c
:Set9j			lda	#$03			;Tabulator-Position #2.
			b $2c
:Set9k			lda	#$04			;Tabulator-Position #3.
			b $2c
:Set9l			lda	#$05			;Tabulator-Position #4.
			b $2c
:Set9m			lda	#$06			;Tabulator-Position #5.
			b $2c
:Set9n			lda	#$07			;Tabulator-Position #6.
			b $2c
:Set9o			lda	#$08			;Tabulator-Position #7.
			b $2c
:Set9p			lda	#$09			;Tabulator-Position #8.
			b $2c
:Set9q			lda	#$0a
			b $2c
:Set9r			lda	#$0b
			b $2c
:Set9s			lda	#$0c

:SetInpOpt		asl
			tax
			lda	V201m3+0,x
			sta	a9L
			lda	V201m3+1,x
			sta	a9H
			jmp	InpOptNum

:Set10a			lda	LinkFiles
			bne	:101
			ora	#%00100000
			bne	:102
::101			lda	#$00
::102			sta	LinkFiles
			rts

:Set10b			lda	#%00100000
			b $2c
:Set10c			lda	#%01000000
			b $2c
:Set10d			lda	#%10000000
			sta	LinkFiles
			rts

:Set11a			lda	#%00000000		;GeoWrite-Konvertierung.
			b $2c
:Set11b			lda	#%01000000
			b $2c
:Set11c			lda	#%10000000
			b $2c
:Set11d			lda	#%11000000
			sta	GW_Modify
			rts

;*** Tabulatoren auf Gültigkeit testen.
:TestTabPos		ldy	#$00

::101			lda	GW_Tab1+1,y		;Testen ob Tabulator links vom
			and	#%01111111		;rechten Rand liegt.
			cmp	GW_RRand  +1
			bcc	:103
			lda	GW_Tab1+0,y
			cmp	GW_RRand  +0
			bcc	:103

::102			lda	GW_RRand  +0		;Wert ungültig. Tabulator auf
			sta	GW_Tab1   +0,y		;rechten Rand setzen.
			lda	GW_RRand  +1
			sta	GW_Tab1   +1,y
			jmp	:104

::103			lda	GW_Tab1+1,y		;Testen ob Tabulator rechts vom
			and	#%10000000		;linken Rand liegt.
			ora	GW_LRand  +1
			cmp	GW_Tab1+1,y
			bcc	:104
			lda	GW_LRand  +0
			cmp	GW_Tab1+0,y
			bcc	:104
			bcs	:102

::104			iny
			iny
			cpy	#$10
			bne	:101
			rts

;*** Tabulator-Position ausgeben.
:PrnTab1Opt		pha
			lda	r0H			;Dezimal-Tabulator-Flag löschen.
			and	#%01111111
			sta	r0H
			pla

;*** Zahlenwert/8 ausgeben.
:PrnOpt8Num		jsr	ClrOptRec
			AddW	V201a4,r0		;Linken Rand addieren.

			lda	r0L			;Falls Wert für "Rechter Rand"
			and	#%00000111		;Word um eins erhöhen.
			beq	:101
			IncWord	r0

::101			ldx	#r0L			;Word / 8.
			ldy	#$03
			jsr	DShiftRight
			jmp	PrnOptNum

;*** Zahlenwert/1 ausgeben.
:PrnOpt1Num		jsr	ClrOptRec		;Ausgabebereich löschen.

;*** Zahlenwert ausgeben.
:PrnOptNum		lda	#%11000000		;Zahl "linksbündig" ausgeben.
			jsr	PutDecimal
			ldy	#$ff
			rts

;*** Ausgabe-Fenster für Zahlenwert löschen.
:ClrOptRec		pha				;Register zwischenspeichern.
			txa
			pha
			tya
			pha
			PushW	r0

			lda	#$00			;Ausgabe-Fenster löschen.
			jsr	L201f0

			jsr	UseGDFont		;GD-Font aktivieren.
			ClrB	currentMode

			PopW	r0
			pla				;Register wieder herstellen.
			sta	r1H
			pla
			sta	r11H
			pla
			sta	r11L
			rts

;*** Zahl Eingeben.
:InpOptNum		PopW	V201a3			;Rücksprung-Adresse merken.

			lda	mouseOn			;Menüs & Icons aus.
			and	#%10011111
			sta	mouseOn
			MoveW	a9,V201a2		;Zeiger auf Daten-Liste merken.

;*** Neue Zahl eingeben.
:InpNOptNum		jsr	SetInputAdr		;Pos. auf Zahlenspeicher berechnen.

			ldy	#$00			;Zahl aus Speicher nach ":r0".
			lda	(r1L),y
			sta	r0L
			iny
			lda	(r1L),y
			and	#%00000011
			sta	r0H

			ldy	#$0c
			lda	(a9L),y			;Wert für linken Rand addieren ?
			beq	:101			;Nein, weiter.
			AddW	V201a4,r0		;Ja, Wert für linken Rand addieren.

::101			ldy	#$06
			jsr	L201e0			;Routine aus Daten-Liste aufrufen.

			ldy	#$00
			lda	(a9L),y			;X-Koordinate für Eingabe.
			sta	r11L
			iny
			lda	(a9L),y
			sta	r11H
			iny
			lda	(a9L),y			;Y-Koordinate für Eingabe.
			sta	r1H
			iny
			lda	(a9L),y			;Anzahl Zeichen für Eingabe.
			sta	r2L

			LoadW	r0,V201b1		;Zeiger auf Eingabespeicher.
			LoadB	r1L,$00			;Standard-Fehler-Routine.
			LoadW	keyVector,:102		;Zeiger auf Abschluß-Routine.
			LoadB	InputMode,$ff
			jsr	GetString
			jsr	InitForIO
			LoadB	$d028,$00
			jmp	DoneWithIO

;*** Eingabe abschließen.
::102			MoveW	V201a2,a9		;Zeiger auf Daten-Liste zurücksetzen.

			ldy	#$08
			jsr	L201e0			;Routine aus Daten-Liste aufrufen.

			ldy	#$0c
			lda	(a9L),y			;Wert für linken Rand abziehen ?
			beq	:103			;Nein, weiter.
			SubW	V201a4,r0		;Ja, Wert für linken Rand abziehen.

::103			ldy	#$0a
			jsr	L201e0			;Routine aus Daten-Liste aufrufen.
			bcc	:104			;Wert in Ordnung ? Ja, weiter.
			jsr	SetClkPos		;Alte Werte ausgeben.
			MoveW	V201a2,a9		;Zahl erneut eingeben.
			jmp	InpNOptNum

::104			jsr	SetInputAdr		;Zeiger auf Zahlenpeicher.
			ldy	#$00
			lda	r0L			;Neuen Wert in Speicher schreiben.
			sta	(r1L),y
			iny
			lda	(r1L),y
			and	#%11111100
			ora	r0H
			sta	(r1L),y

			lda	mouseOn			;Icons aktivieren.
			ora	#%00100000
			sta	mouseOn
			ClrB	InputMode

			jsr	SetHelp

			PushW	V201a3			;Rücksprung-Adresse wieder herstellen.
			rts

;*** Zeiger auf Zahlenspeicher einlesen.
:SetInputAdr		ldy	#$04			;Zeiger auf Vorgabe-Wert für
			lda	(a9L),y			;Input-Routine berechnen.
			sta	r1L
			iny
			lda	(a9L),y
			sta	r1H
			rts

;*** Eingegebene Zahlen-Werte überprüfen.
:ChkInput_a		clc				;Nr. der ersten Seite 0-999.
			rts

:ChkInput_b		lda	r0H			;Max. Anzahl Zeilen/Seite 0-255.
			bne	:101
			clc
			rts

::101			sec
			rts

:ChkInput_c		lda	GW_Version		;Absatz-Tabulator / Linker Rand.
			bne	:101

			CmpWI	r0,393
			bcc	:102
			rts

::101			CmpWI	r0,553
			bcc	:102
			rts

::102			CmpW	r0,GW_RRand
			rts

:ChkInput_d		CmpWI	r0,80			;Rechter Rand.
			bcs	:101
			sec
			rts

::101			lda	GW_Version
			bne	:102

			CmpWI	r0,480
			beq	:103
			bcc	:104
			rts

::102			CmpWI	r0,640
			beq	:103
			bcc	:104
			rts

::103			SubVW	1,r0
			clc
			rts

::104			CmpW	GW_LRand,r0
			rts

:ChkInput_e		CmpW	r0,GW_LRand		;Tabulator #1 - #8.
			bcs	:101

			sec
			rts

::101			CmpW	r0,GW_RRand
			bcc	:102

			MoveW	GW_RRand,r0
			clc

::102			rts

;*** $HEX nach ASCII wandeln.
:HEXtoASCII_2		lda	r0L			;Tabulator am Rechten Rand ?
			and	#%00000111		;Ja, Word um eins erhöhen.
			beq	HEXtoASCII_1
			IncWord	r0

:HEXtoASCII_1		ldx	#r0L			;Zahlenwert / 8.
			ldy	#$03
			jsr	DShiftRight
			jmp	HEXtoASCII		;Word nach ASCII wandeln.

:HEXtoASCII_3		ClrB	r0H			;Byte nach ASCII wandeln.

:HEXtoASCII		ClrB	r1L
			jsr	ZahlToASCII

			ldy	#$00
::101			lda	ASCII_Zahl,y		;Word ab $0101 in Eingabespeicher
			beq	:102			;übertragen.
			sta	V201b1,y
			iny
			cpy	#$03
			bne	:101
			lda	#$00			;Ende des Eingabespeichers
::102			sta	V201b1,y		;markieren.
			rts

;*** ASCII nach $HEX-Word wandeln.
:ASCIItoHEX_1		jsr	ASCIItoHEX		;ASCII nach HEX wandeln.
			ldx	#r0L			;Word + 8.
			ldy	#$03
			jmp	DShiftLeft

:ASCIItoHEX		ClrW	r0			;Word auf $0000 setzen.
			lda	V201b1			;Eingabe-Speicher leer ?
			bne	:101			;Nein, weiter.
			rts

::101			ldy	#$01			;Länge der Zahl ermitteln.
::102			lda	V201b1,y
			beq	:103
			iny
			bne	:102
			iny

::103			dey
			sty	r1L			;Länge der Zahl merken.
			ClrB	r1H			;Zeiger auf Dezimal-Stelle für 1er.

::104			ldy	r1L
			lda	V201b1,y		;Zeichen aus Zahlenstring holen.
			sub	$30			;Reinen Zahlenwert (0-9) isolieren.
			bcc	:106			;Unterlauf, keine Ziffer.
			cmp	#$0a			;Wert >= 10 ?
			bcs	:106			;Ja, keine Ziffer.
			tax
			beq	:106			;Null ? Ja, weiter...
::105			ldy	r1H			;Je nach Dezimal-Stelle, 1er, 10er
			lda	V201b0,y		;oder 100er addieren.
			clc
			adc	r0L
			sta	r0L
			lda	#$00
			adc	r0H
			sta	r0H
			dex				;Schleife bis Zahl = 0.
			bne	:105

::106			inc	r1H			;Weiter bis Zahlenende erreicht.
			dec	r1L
			bpl	:104
			rts

;*** Drucker wählen.
:SlctPrinter		jsr	SelectPrinter		;Druckertreiber wählen.
			jsr	GetPrnDim		;Druckertreiber/Seitenlänge einlesen.

;*** Seitenlänge ermitteln.
:GetPageLen		jsr	ChkPageSize		;Seitenlänge mit Schriftart
							;verknüpfen -> Anzahl Zeilen berechnen.

;*** Drucker-Treiber einlesen und Seitenlänge ermitteln.
:ExitPFSlct		jsr	Ld2DrvData		;Laufwerk & Partition zurücksetzen.
			ClrB	V201a0			;Info-Seite neu aufbauen.
			jmp	SetOpt_a

;*** Drucker-Treiber einlesen und Seitenlänge ermitteln.
:GetPrnDim		jsr	LoadPrinter
			txa
			bne	:101
			jsr	GetDimensions
			jmp	DoStdPageSize

::101			ldy	#62
:DoStdPageSize		sty	r0L			;Seitenlänge einlesen.
			ClrB	r0H
			ldx	#r0L
			ldy	#$03
			jsr	DShiftLeft
			MoveW	r0,GW_PageLength
			ldx	#$00
			rts

;*** Anzahl Zeilen berechnen.
:ChkPageSize		MoveW	GW_PageLength,r0

			lda	GW_FontID		;Punktgröße nach ":r1".
			and	#%00111111
			add	2
			sta	r1L
			ClrB	r1H

			ldx	#r0L			;"Seitenlänge : Punktgröße"
			ldy	#r1L
			jsr	Ddiv

			lda	r0L			;Ergebnis nach ":LinesPerPage".
			sub	2
			sta	LinesPerPage

			rts

;*** Schriftart wählen.
:SlctFont		LoadW	V201h1,V201f1
			LoadB	FileType,FONT
			LoadW	VecFileName,FontFileName
			LoadW	VecFileInfo,V201j1
			LoadW	Vec1File,FileNTab +16
			LoadB	MaxReadFiles,254

;*** Neue Diskette anmelden.
:GetFontDisk		jsr	InitGetFile

;*** Zeichensätze einlesen.
:GetFontFiles		ldy	#$0f			;Eintrag "BSW-Font" erzeugen.
::101			lda	V201c3,y
			sta	FileNTab,y
			dey
			bpl	:101

			jsr	InitFileTab

;*** Zeichensatz auswählen.
:GetFontSlct		lda	#<V201h0
			ldx	#>V201h0
			ldy	#$04
			sty	V201h0
			jsr	SelectBox

			lda	r13L
			cmp	#$00			;Dateiauswahl ?
			beq	:103			;Nein, weiter...
			cmp	#$80
			bcc	:101
			cmp	#$90
			beq	:102

			pha
			jsr	Ld2DrvData
			pla
			and	#%01111111
			add	8			;Neue Laufwerksadr. berechnen.
			jsr	NewDrive		;Laufwerk aktivieren.
			jmp	GetFontDisk

::101			jmp	ExitPFSlct

::102			jsr	CMD_NewTarget

			jsr	DoInfoBox
			MoveW	VecFileInfo,r0
			jsr	PutString
			jmp	GetFontFiles

;*** Gewählten Zeichensatz auswerten.
::103			ldy	#15
::104			lda	(r15L),y		;Dateiname in
			sta	FontFileName,y		;Zwischenspeicher kopieren.
			dey
			bpl	:104

			ldx	#$00
			ldx	#$00			;Eintrag "BSW-Font" erzeugen.
::105			lda	V201c3,x
			cmp	FontFileName,x
			bne	LoadNewFont
			inx
			cpx	#$10
			bne	:105

;*** Font: "BSW 9 Punkte" aktivieren.
:SetBSWFont		ldy	#$0f			;Ja, Name des BSW-Fonts in Speicher.
::101			lda	V201c3,y
			sta	UsedGWFont,y
			dey
			bpl	:101

			lda	#$09			;Punktgröße.
			sta	UsedPointSize
			sta	GW_FontID+0		;Punktgröße und ID.
			lda	#$00
			sta	GW_FontID+1
			jmp	ExitPFSlct

;*** Neuen Zeichensatz aktivieren.
:LoadNewFont		LoadW	r6,FontFileName
			jsr	FindFile
			txa
			beq	:102
::101			jmp	DiskError		;Disketten-Fehler.

::102			lda	dirEntryBuf+1		;VLIR-Header lesen.
			sta	r1L
			lda	dirEntryBuf+2
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa
			bne	:101			;Disketten-Fehler.

			LoadW	r9,dirEntryBuf		;File-Header lesen.
			jsr	GetFHdrInfo
			txa
			bne	:101			;Disketten-Fehler.

;*** Tabelle mit Punktgrößen erzeugen.
:CreatePoints		LoadW	a9,FileNTab		;Zeiger auf Anfang für Punktgrößen-
			ClrB	V201a5 			;Tabelle setzen.

			lda	#$02
::101			pha
			tax
			lda	diskBlkBuf,x		;Prüfen ob VLIR-Datensatz belegt ist.
			beq	:104			;Nicht belegt, Größe nicht vorhanden.

			inc	V201a5			;Anzahl Punktgrößen +1.
			txa				;Größe nach ASCII wandeln und in
			sub	2			;Tabelle eintragen.
			lsr
			sta	r0L
			jsr	HEXtoASCII_3

			ldy	#$00
			ldx	#$00
::102			lda	V201b1,y
			beq	:103
			sta	(a9L),y
			iny
			cpy	#$03
			bne	:102

::103			lda	V201g0,x		;Text " Punkte" in Tabelle.
			sta	(a9L),y
			inx
			iny
			cpy	#$10
			bne	:103
			AddVBW	16,a9

::104			pla				;Nächste Punktgröße testen.
			add	2
			bne	:101
			tay				;Tabellenende markieren.
			sta	(a9L),y

;*** Punktgröße wählen.
:SlctPntSize		lda	V201a5			;Punktgrößen in Font-Datei ?
			beq	:102			;Ja, auswählen.
			cmp	#$02
			bcs	:101
			LoadW	r15,FileNTab
			jmp	LoadPointSize

::101			LoadW	V201h1,V201f2

			lda	#<V201h0
			ldx	#>V201h0
			ldy	#$04
			sty	V201h0
			jsr	SelectBox

			lda	r13L
			cmp	#$00			;Dateiauswahl ?
			beq	LoadPointSize		;Nein, weiter...
			cmp	#$01			;Dateiauswahl ?
			beq	:104			;Nein, weiter...
			cmp	#$80
			bcc	:102
			cmp	#$90
			beq	:103

			pha
			jsr	Ld2DrvData
			pla
			and	#%01111111
			add	8			;Neue Laufwerksadr. berechnen.
			jsr	NewDrive		;Laufwerk aktivieren.
			jmp	GetFontDisk

::102			jmp	ExitPFSlct

::103			jsr	CMD_NewTarget

			jsr	DoInfoBox
			MoveW	VecFileInfo,r0
			jsr	PutString
::104			jmp	GetFontFiles

;*** Neue Punktgröße aktivieren.
:LoadPointSize		ldy	#$00			;Punktgröße nach $HEX wandeln.
::101			lda	(r15L),y
			cmp	#" "
			beq	:102
			sta	V201b1,y
			iny
			cpy	#$03
			bne	:101

::102			lda	#$00
			sta	V201b1,y
			jsr	ASCIItoHEX

;*** NEWCARDSET definieren.
:SetNewFont		lda	fileHeader+128		;Font-ID mit Punktgröße
			sta	r1L			;verknüpfen.
			lda	fileHeader+129
			sta	r1H
			ldx	#r1L
			ldy	#$06
			jsr	DShiftLeft
			lda	r0L
			sta	UsedPointSize
			and	#%00111111
			ora	r1L
			sta	GW_FontID+0
			lda	r1H
			sta	GW_FontID+1

			ldy	#$0f
::101			lda	FontFileName,y
			sta	UsedGWFont,y
			dey
			bpl	:101

			jmp	GetPageLen		;Seitenlänge berechnen.

;*** Parameter einlesen.
:LoadOpt		ClrB	DoOptName +1
			LoadW	V201h1,V201f7
			jsr	OptTargetDir
			txa
			bne	:102

;*** Parameterdatei auswählen.
			ldy	#$0f
::101			lda	(r15L),y
			sta	V201l1,y
			dey
			bpl	:101

			jsr	PrepGetFile

			LoadB	r0L,%00000001
			LoadW	r6 ,V201l1
			LoadW	r7 ,CTabCBMtoDOS
			jsr	GetFile
			txa
			beq	:102

			DB_OK	V201i0
			jsr	CopyStdOpt
::102			jmp	ExitSaveOpt

;*** Parameter speichern.
:SaveOpt		LoadB	DoOptName +1,$ff
			LoadW	V201h1,V201f6
			jsr	OptTargetDir
			txa
			beq	:105
			cmp	#$7f
			beq	:102
::101			jmp	ExitSaveOpt

::102			LoadW	r15,V201l3
			ClrB	DoOptName +1

::103			ldy	#$0f			;Eintrag "BSW-Font" erzeugen.
::104			lda	(r15L),y
			sta	OptFileName,y
			dey
			bpl	:104
			jsr	ClrScreen
			jmp	GetOptFName

;*** Bestehende Datei ersetzen.
::105			ldy	#$0f			;Eintrag "BSW-Font" erzeugen.
::106			lda	(r15L),y
			sta	V201l1,y
			dey
			bpl	:106

::107			LoadW	r0,V201l1
			jsr	DeleteFile
			txa
			beq	:107
			jsr	ClrScreen
			jmp	SaveOptFile

;*** Dateiname eingeben.
:GetOptFName		LoadW	r0,OptFileName
			LoadW	r1,V201l1
			LoadB	r2L,$ff
:DoOptName		LoadB	r2H,$ff
			LoadW	r3,V201f6
			jsr	cbmSetName
			cmp	#$01
			bne	ExitSaveOpt

:IsFileOnDsk		LoadW	r6,V201l1
			jsr	FindFile
			txa
			bne	:101

			DB_UsrBoxV201i2
			CmpBI	sysDBData,3
			bne	GetOptFName

			LoadW	r0,V201l1
			jsr	DeleteFile
			txa
			bne	ExitDskErr
			jmp	IsFileOnDsk

::101			cmp	#$05
			beq	SaveOptFile

;*** Fehler, zurück zu GeoDOS.
:ExitDskErr		pha
			jsr	Ld2DrvData
			pla
			tax
			jmp	DiskError

;*** Datei speichern.
:SaveOptFile		LoadW	HdrB000,V201l1
			LoadW	r9,HdrB000
			LoadB	r10L,$00
			jsr	SaveFile
			txa
			bne	ExitDskErr

;*** Zurück zum Options-Menü.
:ExitSaveOpt		jsr	Ld2DrvData
			jsr	L201a0
			jmp	SetOpt_a

;*** Zielverzeichnis auswählen.
:OptTargetDir		jsr	ClrScreen

			LoadW	VecFileInfo,V201j2
			LoadW	Vec1File,FileNTab
			LoadB	MaxReadFiles,255

			lda	AppDrv
			jsr	NewDrive

			jsr	InitGetFile
			jsr	OpenSysDrive
			jmp	GetOptFiles

;*** Neue Diskette anmelden.
:GetOptDisk		jsr	InitGetFile

;*** Parameterdateien einlesen.
:GetOptFiles		MoveW	Vec1File,r6
			LoadB	r7L,DATA
			MoveB	MaxReadFiles,r7H
			LoadW	r10,V201l2
			jsr	FindFTypes

			jsr	PrepFileTab

;*** Parameterdatei auswählen.
:SlctOptFile		lda	#<V201h0
			ldx	#>V201h0
			ldy	#$04
			sty	V201h0
			jsr	SelectBox

			lda	r13L
			cmp	#$00			;Dateiauswahl ?
			beq	:103			;Nein, weiter...
			cmp	#$01			;Dateiauswahl ?
			beq	:104			;Nein, weiter...
			cmp	#$80
			bcc	:101
			cmp	#$90
			beq	:102

			pha
			jsr	Ld2DrvData
			pla
			and	#%01111111
			add	8			;Neue Laufwerksadr. berechnen.
			jsr	NewDrive		;Laufwerk aktivieren.
			jmp	GetOptDisk

::101			jmp	ExitOptFile

::102			jsr	CMD_NewTarget

			jsr	DoInfoBox
			MoveW	VecFileInfo,r0
			jsr	PutString
			jmp	GetOptFiles

::103			ldx	#$00
			rts

::104			ldx	#$7f
			rts

;*** Auswahl Parameterdatei beenden.
:ExitOptFile		ldx	#$ff
			rts

;*** "OPTION.INI"-Datei sichern.
:SaveOptPref		jsr	ClrScreen

			jsr	DoInfoBox
			PrintStrgV201j0

			jsr	OpenSysDrive

			LoadW	r0,V201l3
			jsr	DeleteFile

			LoadW	HdrB000,V201l3
			LoadW	r9,HdrB000
			LoadB	r10L,$00
			jsr	SaveFile

			jsr	OpenUsrDrive
			jmp	SetOpt_a

;*** Tabellen löschen.
:NoCTab			lda	#$00			;Namen der Übersetzungstabelle
			sta	CTabDOStoCBM		;löschen.
			sta	CTabCBMtoDOS
			sta	CTabCBMtoCBM
			jmp	PutWinText

;*** Konvertierungstabelle DOS laden.
:SlctCTabDOS		jsr	ClrScreen
			jsr	LoadConvIndex
			txa
			bne	NoCTabOnDisk

			jsr	GetCTabDOS
			txa
			bne	GotoMenu

			lda	r10L
			sta	CTabDOStoCBM
			lda	#<CTabDOStoCBM+1
			ldx	#>CTabDOStoCBM+1
			jmp	ExitConvTab

;*** Konvertierungstabelle CBM laden.
:SlctCTabCBM		jsr	ClrScreen
			jsr	LoadConvIndex
			txa
			bne	NoCTabOnDisk

			jsr	GetCTabCBM
			txa
			bne	GotoMenu

			lda	r10L
			sta	CTabCBMtoDOS
			lda	#<CTabCBMtoDOS+1
			ldx	#>CTabCBMtoDOS+1
			jmp	ExitConvTab

;*** Konvertierungstabelle Text laden.
:SlctCTabTXT		jsr	ClrScreen
			jsr	LoadConvIndex
			txa
			bne	NoCTabOnDisk

			jsr	GetCTabTXT
			txa
			bne	GotoMenu

			lda	r10L
			sta	CTabCBMtoCBM
			lda	#<CTabCBMtoCBM+1
			ldx	#>CTabCBMtoCBM+1

;*** Auswahl Parameterdatei beenden.
:ExitConvTab		sta	r1L
			stx	r1H
			ldx	#r15L
			ldy	#r1L
			lda	#$10
			jsr	CopyFString

:GotoMenu		ClrB	V201a0			;Info-Seite neu aufbauen.
			jmp	SetOpt_a

:NoCTabOnDisk		cpx	#$05
			beq	:101
			jmp	DiskError

::101			DB_OK	V201i1
			jmp	GotoMenu

;*** Setup-Menu.
:DoSetupMenu		ClrW	otherPressVec

			NoMseKey

			FillPRec$00,$40,$5f,$0040,$0107

			jsr	i_C_MenuTitel
			b	$08,$08,$19,$01
			jsr	i_C_MenuMIcon
			b	$08,$09,$19,$03

if Sprache = Deutsch
			jsr	UseGDFont
			Print	$0048,$46
			b	PLAINTEXT,"Konfigurieren",NULL
endif

if Sprache = Englisch
			jsr	UseGDFont
			Print	$0048,$46
			b	PLAINTEXT,"Configure",NULL
endif

			LoadW	r0,Icon_Tab2
			jsr	DoIcons

			ldy	#$05
::101			lda	V201m5,y
			sta	mouseTop,y
			dey
			bpl	:101
			rts

;*** Icon-Auswertung.
:SelectMenu		PushB	r0L

			ldy	#$05
::100			lda	V201m6,y
			sta	mouseTop,y
			dey
			bpl	:100

			pla
			tax
			beq	:101
			dex
			beq	:102
			dex
			beq	:103
			dex
			beq	:104
			dex
			beq	:105

;*** Zurück zum Options-Menü.
::101			jmp	SetOpt_a

;*** "OPTION.INI" speichern.
::102			jmp	SaveOptPref

;*** Standardwerte laden.
::103			jsr	CopyStdOpt
			jsr	L201a0			;Seitenformat bestimmen.
			jmp	SetOpt_a

;*** Optionen speichern.
::104			jmp	SaveOpt

;*** Optionen laden.
::105			jmp	LoadOpt

;*** Info-Block für Parameter-Datei.
:HdrB000		w V201l1
			b $03,$15
			j
<MISSING_IMAGE_DATA>
			b $83
			b DATA
			b SEQUENTIAL
			w CTabCBMtoDOS
			w CTabCBMtoDOS + (V201c4-V201c2) -1
			w CTabCBMtoDOS
			b "GD_CopyData V"		;Klasse.
			b "1.0"				;Version.
			s $04				;Reserviert.
			b "GeoDOS 64"			;Autor.
:HdrEnd			s (HdrB000+161)-HdrEnd

:V201l1			s 17				;Zwischenspeicher Dateiname.
:V201l2			b "GD_CopyData V1.0",NULL
:V201l3			b "OPTION.INI",NULL

;*** Variablen.
:OptionMode		b $00
:InputMode		b $00
:HelpFileName		b "02,GDH_Copy/Opt",NULL
:FontFileName		s 17
:OptFileName		s 17
:ConvTabClass		w $0000
:ConvTabName		w $0000
:PrntDiskTab		s $04
:LookOnDrive		b $00

:V201a0			b $00				;Aktuelles Parameter-Menü.
:V201a2			w $0000				;Zwischenspeicher: Zeiger auf Daten-Liste.
:V201a3			w $0000				;Zwischenspeicher: Rücksprung-Adresse.
:V201a4			w $0000				;Zwischenspeicher: Anfangs-Wert "linker Rand".
:V201a5			b $00				;Anzahl Punktgrößen.

:V201b0			b 1,10,100			;Umrechnungswerte ASCII -> HEX.
:V201b1			s $04				;Zwischenspeicher für Zahleneingabe.

;*** Vorgabe-Werte.
:V201c0			w $0000,$01df
			w $01df,$01df,$01df,$01df
			w $01df,$01df,$01df,$01df,$0000
:V201c1			w $0000,$027f
			w $027f,$027f,$027f,$027f
			w $027f,$027f,$027f,$027f,$0000

;*** Copy-Optionen.
:V201c2			s 17				;CTabCBMtoDOS
			s 17				;CTabDOStoCBM
			s 17				;CTabDOStoCBM
:V201c3			b "BSW- GEOS System",NULL	;UsedGWFont
			b $09				;UsedPointSize
			w $0040				;LinesPerPage
			b $00				;LinkFiles
			b $00				;SetDateTime
			b $ff				;OverWrite
			b $00				;'8+3'-Dateiname
			b $81				;CBMFileType
			b $00				;DOS_LfMode
			b $00				;FileNameMode
			b $00				;CBM_LfMode
			b $00				;DOS_TargetDir
			w $0000				;DOS_TargetClu
			b $00				;DOS_FfMode
			b $00				;GW_Version
			w $0001				;GW_FirstPage
			w $02f0				;GW_PageLength
			b ESC_RULER			;GW_PageData
			w $0000				;GW_LRand
			w $01df				;GW_RRand
			w $01df				;GW_Tab1
			w $01df				;GW_Tab2
			w $01df				;GW_Tab3
			w $01df				;GW_Tab4
			w $01df				;GW_Tab5
			w $01df				;GW_Tab6
			w $01df				;GW_Tab7
			w $01df				;GW_Tab8
			w $0000				;GW_AbsatzTab
			b %00010000			;GW_Format
			s $03				;GW_Reserve
			b NEWCARDSET			;GW_Font
			w $0009				;GW_FontID
			b $00				;GW_Style
			b $00				;CBM_FfMode
			b $00				;CBM_FileTMode
			b $00				;Txt_LfMode
			b $00				;Txt_FfMode
			b $00				;GW_Modify
:V201c4			b NULL				;Ende Kopier-Optionen.

:V201d0			w V201e0,V201e1 ,V201e2 ,V201e3 ,V201e4
			w V201e5,V201e6 ,V201e7 ,V201e8
			w V201e9,V201e10,V201e11,V201e12,V201e13

if Sprache = Deutsch
:V201e0			b "Informationen",NULL
:V201e1			b "Ziel-Datei",NULL
:V201e2			b "Ziel-Dateiname",NULL
:V201e3			b "DOS - CBM",NULL
:V201e4			b "CBM - DOS",NULL
:V201e5			b "DOS - GeoWrite",NULL
:V201e6			b "GeoWrite - DOS",NULL
:V201e7			b "Text - Text",NULL
:V201e8			b "Text - GeoWrite",NULL
:V201e9			b "GeoWrite - Text",NULL
:V201e10		b "GeoWrite - GeoWrite",NULL
:V201e11		b "GeoWrite konvertieren",NULL
:V201e12		b "Seitenformat",NULL
:V201e13		b "Dateien verbinden",NULL

:V201f1			b PLAINTEXT,"Schriftart wählen",NULL
:V201f2			b PLAINTEXT,"Punktgröße wählen",NULL
:V201f3			b PLAINTEXT,"Übersetzen DOS nach CBM",NULL
:V201f4			b PLAINTEXT,"Übersetzen CBM nach DOS",NULL
:V201f5			b PLAINTEXT,"Übersetzungstabelle",NULL
:V201f6			b PLAINTEXT,"Parameterdatei speichern",NULL
:V201f7			b PLAINTEXT,"Parameterdatei laden",NULL

:V201g0			b " Punkte",0,0,0,0,0,0,0,0,0,0
:V201g1			b "1:1 Übertragung ",NULL
endif

if Sprache = Englisch
:V201e0			b "Informations",NULL
:V201e1			b "Target-file",NULL
:V201e2			b "Target-filename",NULL
:V201e3			b "DOS - CBM",NULL
:V201e4			b "CBM - DOS",NULL
:V201e5			b "DOS - GeoWrite",NULL
:V201e6			b "GeoWrite - DOS",NULL
:V201e7			b "Text - Text",NULL
:V201e8			b "Text - GeoWrite",NULL
:V201e9			b "GeoWrite - Text",NULL
:V201e10		b "GeoWrite - GeoWrite",NULL
:V201e11		b "Convert GeoWrite",NULL
:V201e12		b "Page-layout",NULL
:V201e13		b "Connect files",NULL

:V201f1			b PLAINTEXT,"Select font",NULL
:V201f2			b PLAINTEXT,"Select pointsize",NULL
:V201f3			b PLAINTEXT,"Translate DOS to CBM",NULL
:V201f4			b PLAINTEXT,"Translate CBM to DOS",NULL
:V201f5			b PLAINTEXT,"Translation-mode",NULL
:V201f6			b PLAINTEXT,"Save parameters",NULL
:V201f7			b PLAINTEXT,"Load parameters",NULL

:V201g0			b " points",0,0,0,0,0,0,0,0,0,0
:V201g1			b "Translate 1:1   ",NULL
endif

if Sprache = Deutsch
;*** Dialogboxen.
:V201h0			b $00				;Zeichensatz/Punktgröße wählen.
			b $ff
			b $00
			b $10
			b $00
:V201h1			w V201f2
			w FileNTab

:V201h2			b $ff				;Konvertierungstabelle laden.
			b $00
			b $00
			b $10
			b $00
:V201h3			w $ffff
			w FileNTab

;*** Fehlermeldungen.
:V201i0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Die Parameterdatei konnte",NULL
::102			b        "nicht geladen werden!",NULL

:V201i1			w :101, :102, ISet_Achtung
::101			b BOLDON,"Keine Übersetzungstabellen",NULL
::102			b        "auf der Systemdiskette!",NULL

:V201i2			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Diese Datei existiert bereits.",NULL
::102			b        "Vorhandene Datei ersetzen?",NULL

;*** Info: "Systemdatei 'OPTION.INI' wird gespeichert"
:V201j0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Systemdatei 'OPTION.INI'"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "wird gespeichert..."
			b NULL

;*** Info: "Zeichensätze werden eingelesen."
:V201j1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Zeichensätze"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "werden eingelesen..."
			b NULL

;*** Info: "Parameterdateien werden eingelesen."
:V201j2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Parameterdateien"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "werden eingelesen..."
			b NULL

;*** Info: "Übersetzungstabellen werden eingelesen."
:V201j3			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Übersetzungstabellen"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "werden eingelesen..."
			b NULL
endif

if Sprache = Englisch
;*** Dialogboxen.
:V201h0			b $00				;Zeichensatz/Punktgröße wählen.
			b $ff
			b $00
			b $10
			b $00
:V201h1			w V201f2
			w FileNTab

:V201h2			b $ff				;Konvertierungstabelle laden.
			b $00
			b $00
			b $10
			b $00
:V201h3			w $ffff
			w FileNTab

;*** Fehlermeldungen.
:V201i0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Not able to load",NULL
::102			b        "parameter-file!",NULL

:V201i1			w :101, :102, ISet_Achtung
::101			b BOLDON,"No translation-modes",NULL
::102			b        "found on systemdisk!",NULL

:V201i2			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"File exist on disk.",NULL
::102			b        "Replace current file?",NULL

;*** Info: "Systemdatei 'OPTION.INI' wird gespeichert"
:V201j0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Systemfile 'OPTION.INI'"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "will be saved..."
			b NULL

;*** Info: "Zeichensätze werden eingelesen."
:V201j1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Searching for"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "GeoWrite-fonts..."
			b NULL

;*** Info: "Parameterdateien werden eingelesen."
:V201j2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Searching for"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "parameter-files..."
			b NULL

;*** Info: "Übersetzungstabellen werden eingelesen."
:V201j3			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Translation-modes"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "will be loaded..."
			b NULL
endif

if Sprache = Deutsch
;*** Auswahlmenü.
:MenuText		b PLAINTEXT

			b GOTOXY
			w $0008
			b $06     ,"Optionen"

			b GOTOXY
			w $00d4
			b $2e     ,"Optionen"

			b GOTOXY
			w $00cc
			b $07*8 -2,"Informationen"

			b GOTOXY
			w $00cc
			b $08*8 -2,"Ziel-Datei"

			b GOTOXY
			w $00cc
			b $09*8 -2,"Ziel-Dateiname"

			b GOTOXY
			w $00cc
			b $0b*8 -2,"DOS > CBM"

			b GOTOXY
			w $00cc
			b $0c*8 -2,"CBM > DOS"

			b GOTOXY
			w $00cc
			b $0e*8 -2,"DOS > GeoWrite"

			b GOTOXY
			w $00cc
			b $0f*8 -2,"GeoWrite > DOS"

			b GOTOXY
			w $00cc
			b $11*8 -2,"Text > Text"

			b GOTOXY
			w $00cc
			b $12*8 -2,"Text > GeoWrite"

			b GOTOXY
			w $00cc
			b $13*8 -2,"GeoWrite > Text"

			b GOTOXY
			w $00cc
			b $14*8 -2,"GWrite > GWrite"

			b GOTOXY
			w $00cc
			b $15*8 -2,"GWrite-Convert"

			b GOTOXY
			w $00cc
			b $17*8 -2,"Seitenformat"

			b GOTOXY
			w $00cc
			b $18*8 -2,"Texte verbinden"

			b NULL
endif

if Sprache = Englisch
;*** Auswahlmenü.
:MenuText		b PLAINTEXT

			b GOTOXY
			w $0008
			b $06     ,"Options"

			b GOTOXY
			w $00d4
			b $2e     ,"Options"

			b GOTOXY
			w $00cc
			b $07*8 -2,"Informations"

			b GOTOXY
			w $00cc
			b $08*8 -2,"Target-file"

			b GOTOXY
			w $00cc
			b $09*8 -2,"Target-filename"

			b GOTOXY
			w $00cc
			b $0b*8 -2,"DOS > CBM"

			b GOTOXY
			w $00cc
			b $0c*8 -2,"CBM > DOS"

			b GOTOXY
			w $00cc
			b $0e*8 -2,"DOS > GeoWrite"

			b GOTOXY
			w $00cc
			b $0f*8 -2,"GeoWrite > DOS"

			b GOTOXY
			w $00cc
			b $11*8 -2,"Text > Text"

			b GOTOXY
			w $00cc
			b $12*8 -2,"Text > GeoWrite"

			b GOTOXY
			w $00cc
			b $13*8 -2,"GeoWrite > Text"

			b GOTOXY
			w $00cc
			b $14*8 -2,"GWrite > GWrite"

			b GOTOXY
			w $00cc
			b $15*8 -2,"GWrite-Convert"

			b GOTOXY
			w $00cc
			b $17*8 -2,"Page-layout"

			b GOTOXY
			w $00cc
			b $18*8 -2,"Connect files"

			b NULL
endif

;*** Parameter-Texte.
:V201m0			w V201n10 ,V201n20 ,V201n25 ,V201n30 ,V201n40
			w V201n50 ,V201n60 ,V201n70 ,V201n50
			w V201n80 ,V201n50 ,V201nb0 ,V201n90 ,V201na0

:V201m1			b $00,$01,$02,$ff,$03,$04,$ff,$05,$06,$ff
			b $07,$08,$09,$0a,$0b,$ff,$0c,$0d

;*** Daten-Listen für "Klick-Positionen".
:V201m2			w V201n11 ,V201n21 ,V201n26 ,V201n31 ,V201n41
			w V201n51 ,V201n61 ,V201n71 ,V201n52
			w V201n81 ,V201n52 ,V201nb1 ,V201n91 ,V201na1

;*** Parameter für Zahleneingabe.
:V201m3			w V201n55a ,V201n55c
			w V201n95a ,V201n95c ,V201n95e
			w V201n95g ,V201n95i ,V201n95k ,V201n95m
			w V201n95o ,V201n95q,V201n95s,V201n95u

;*** Daten-Listen für Zahlenausgabe.
:V201m4			w V201n55b ,V201n55d
			w V201n95b ,V201n95d ,V201n95f
			w V201n95h ,V201n95j ,V201n95l ,V201n95n
			w V201n95p ,V201n95r,V201n95t,V201n95v

;*** Mauszeigergrenzen.
:V201m5			b $48,$5f
			w $0040,$0107

:V201m6			b $00,$c7
			w $0000,$013f

;*** Information.
:V201n10		b NULL

:V201n11		b   1,  0
			w   0,  0,Def1a,$0000
			b NULL

;*** Ziel-Datei.
:V201n20		b ESC_GRAPHICS
			b MOVEPENTO
			w $0010
			b $3b
			b FRAME_RECTO
			w $00af
			b $5b

			b MOVEPENTO
			w $0010
			b $6b
			b FRAME_RECTO
			w $00af
			b $9b

			b ESC_PUTSTRING
			w $0018
			b $3a

if Sprache = Deutsch
			b PLAINTEXT,BOLDON
			b "Datum für Ziel-Datei "
			b GOTOXY
			w $0024
			b $46
			b "Original-Datei"
			b GOTOXY
			w $0024
			b $56
			b "Übernahme von GEOS"
			b GOTOXY
			w $0018
			b $6a
			b "Ziel-Datei überschreiben "
			b GOTOXY
			w $0024
			b $76
			b "Ja, Ziel-Datei löschen"
			b GOTOXY
			w $0024
			b $86
			b "Nein, Datei ignorieren"
			b GOTOXY
			w $0024
			b $96
			b "Abfrage"
			b NULL
endif

if Sprache = Englisch
			b PLAINTEXT,BOLDON
			b "Set Date for target-file "
			b GOTOXY
			w $0024
			b $46
			b "Source-file"
			b GOTOXY
			w $0024
			b $56
			b "Take GEOS-time"
			b GOTOXY
			w $0018
			b $6a
			b "Existing target-files "
			b GOTOXY
			w $0024
			b $76
			b "Overwrite target-file"
			b GOTOXY
			w $0024
			b $86
			b "Ignore source-file"
			b GOTOXY
			w $0024
			b $96
			b "Query"
			b NULL
endif

:V201n21		b $40,$47
			w $0018,$001f,Def2a,Set2a
			b $50,$57
			w $0018,$001f,Def2b,Set2b
			b $70,$77
			w $0018,$001f,Def2c,Set2c
			b $80,$87
			w $0018,$001f,Def2d,Set2d
			b $90,$97
			w $0018,$001f,Def2e,Set2e
			b NULL

;*** Ziel-Dateiname.
:V201n25		b ESC_GRAPHICS
			b MOVEPENTO
			w $0010
			b $3b
			b FRAME_RECTO
			w $00af
			b $ab

			b ESC_PUTSTRING
			w $0018
			b $3a

if Sprache = Deutsch
			b PLAINTEXT,BOLDON
			b "Ziel-Dateiname"
			b GOTOXY
			w $0018
			b $46
			b "MSDOS-Dateiname während"
			b GOTOXY
			w $0018
			b $50
			b "Kopiervorgang in das CBM-"
			b GOTOXY
			w $0018
			b $5a
			b "Format konvertieren:"
			b GOTOXY
			w $0024
			b $6e
			b "'8+3'-Format erzeugen"
			b GOTOXY
			w $0024
			b $78
			b "Bsp.: 'TEST      .TXT'"
			b GOTOXY
			w $0024
			b $8e
			b "Dateinamen packen"
			b GOTOXY
			w $0024
			b $98
			b "Bsp.: 'TEST.TXT'"
			b NULL
endif

if Sprache = Englisch
			b PLAINTEXT,BOLDON
			b "Target-filename"
			b GOTOXY
			w $0018
			b $46
			b "Convert source-filename"
			b GOTOXY
			w $0018
			b $50
			b "to PCDOS-format during"
			b GOTOXY
			w $0018
			b $5a
			b "copying the files:"
			b GOTOXY
			w $0024
			b $6e
			b "Create '8+3'-format"
			b GOTOXY
			w $0024
			b $78
			b "For e.g.: 'TEST    .TXT'"
			b GOTOXY
			w $0024
			b $8e
			b "Pack filenames"
			b GOTOXY
			w $0024
			b $98
			b "For e.g.: 'TEST.TXT'"
			b NULL
endif

:V201n26		b $68,$6f
			w $0018,$001f,Def2f,Set2f
			b $88,$8f
			w $0018,$001f,Def2g,Set2g
			b NULL

;*** DOS -> CBM.
:V201n30		b ESC_GRAPHICS
			b MOVEPENTO
			w $0010
			b $3b
			b FRAME_RECTO
			w $00af
			b $5b

			b MOVEPENTO
			w $0010
			b $6b
			b FRAME_RECTO
			w $00af
			b $9b

			b ESC_PUTSTRING
			w $0018
			b $3a

if Sprache = Deutsch
			b PLAINTEXT,BOLDON
			b "Zeilenvorschub "
			b GOTOXY
			w $0024
			b $46
			b "Ignorieren"
			b GOTOXY
			w $0018
			b $6a
			b "Dateityp "
			b GOTOXY
			w $0024
			b $76
			b "Commodore SEQ"
			b GOTOXY
			w $0024
			b $86
			b "Commodore PRG"
			b GOTOXY
			w $0024
			b $96
			b "Commodore USR"
			b NULL
endif

if Sprache = Englisch
			b PLAINTEXT,BOLDON
			b "Linefeed "
			b GOTOXY
			w $0024
			b $46
			b "ignore"
			b GOTOXY
			w $0018
			b $6a
			b "Filetype "
			b GOTOXY
			w $0024
			b $76
			b "Commodore SEQ"
			b GOTOXY
			w $0024
			b $86
			b "Commodore PRG"
			b GOTOXY
			w $0024
			b $96
			b "Commodore USR"
			b NULL
endif

:V201n31		b $40,$47
			w $0018,$001f,Def3a,Set3a
			b $70,$77
			w $0018,$001f,Def3b,Set3b
			b $80,$87
			w $0018,$001f,Def3c,Set3c
			b $90,$97
			w $0018,$001f,Def3d,Set3d
			b NULL

;*** CBM -> DOS.
:V201n40		b ESC_GRAPHICS
			b MOVEPENTO
			w $0010
			b $3b
			b FRAME_RECTO
			w $00af
			b $5b

			b MOVEPENTO
			w $0010
			b $6b
			b FRAME_RECTO
			w $00af
			b $9b

			b ESC_PUTSTRING
			w $0018
			b $3a

if Sprache = Deutsch
			b PLAINTEXT,BOLDON
			b "Zeilenvorschub "
			b GOTOXY
			w $0024
			b $46
			b "Einfügen"
			b GOTOXY
			w $0018
			b $6a
			b "PCDOS-Dateiname "
			b GOTOXY
			w $0024
			b $76
			b "Name vorschlagen"
			b GOTOXY
			w $0024
			b $86
			b "Neu eingeben"
			b NULL
endif

if Sprache = Englisch
			b PLAINTEXT,BOLDON
			b "Linefeed "
			b GOTOXY
			w $0024
			b $46
			b "Insert LF"
			b GOTOXY
			w $0018
			b $6a
			b "PCDOS-filename "
			b GOTOXY
			w $0024
			b $76
			b "Create default"
			b GOTOXY
			w $0024
			b $86
			b "Enter new name"
			b NULL
endif

:V201n41		b $40,$47
			w $0018,$001f,Def4a,Set4a
			b $70,$77
			w $0018,$001f,Def4b,Set4b
			b $80,$87
			w $0018,$001f,Def4c,Set4c
			b NULL

;*** DOS -> GW / CBM -> GW
:V201n50		b ESC_GRAPHICS
			b MOVEPENTO
			w $0010
			b $3b
			b FRAME_RECTO
			w $00af
			b $5b

			b MOVEPENTO
			w $0010
			b $6b
			b FRAME_RECTO
			w $00af
			b $ab

			b ESC_PUTSTRING
			w $0018
			b $3a

if Sprache = Deutsch
			b PLAINTEXT,BOLDON
			b "Text-Format "
			b GOTOXY
			w $0024
			b $46
			b "Write Image V2.0"
			b GOTOXY
			w $0024
			b $56
			b "Write Image V2.1"
			b GOTOXY
			w $0018
			b $6a
			b "Layout "
			b GOTOXY
			w $0018
			b $76
			b "Erste Seiten-Nr:"
			b GOTOXY
			w $0024
			b $86
			b "Text neu formatieren"
			b GOTOXY
			w $0024
			b $96
			b "Seitenende übernehmen"
			b GOTOXY
			w $0024
			b $a6
			b "Zeilen pro Seite:"
			b NULL
endif

if Sprache = Englisch
			b PLAINTEXT,BOLDON
			b "Text-format "
			b GOTOXY
			w $0024
			b $46
			b "Write Image V2.0"
			b GOTOXY
			w $0024
			b $56
			b "Write Image V2.1"
			b GOTOXY
			w $0018
			b $6a
			b "Layout "
			b GOTOXY
			w $0018
			b $76
			b "No. of first page:"
			b GOTOXY
			w $0024
			b $86
			b "Reformat text"
			b GOTOXY
			w $0024
			b $96
			b "Leave end of page"
			b GOTOXY
			w $0024
			b $a6
			b "Lines per page:"
			b NULL
endif

;*** DOS -> GW / CBM -> GW
:V201n51		b $40,$47
			w $0018,$001f,Def5a,Set5a
			b $50,$57
			w $0018,$001f,Def5b,Set5b
			b $70,$77
			w $0088,$009f,Def5c,Set5c
			b $80,$87
			w $0018,$001f,Def5d,Set5d
			b $90,$97
			w $0018,$001f,Def5e,Set5e
			b $a0,$a7
			w $0018,$001f,Def5f,Set5f
			b $a0,$a7
			w $0088,$009f,Def5g,Set5g
			b NULL

:V201n52		b $40,$47
			w $0018,$001f,Def5a,Set5a
			b $50,$57
			w $0018,$001f,Def5b,Set5b
			b $70,$77
			w $0088,$009f,Def5c,Set5c
			b $80,$87
			w $0018,$001f,Def5d,Set5d
			b $90,$97
			w $0018,$001f,Def8a,Set8a
			b $a0,$a7
			w $0018,$001f,Def8b,Set8a
			b $a0,$a7
			w $0088,$009f,Def5g,Set5g
			b NULL

:V201n55a		w $008a				;Nr. der ersten Seite.
			b $70,3
			w GW_FirstPage
			w HEXtoASCII,ASCIItoHEX
			w ChkInput_a
			b $00
:V201n55b		w $008a
			b $76
			w PrnOpt1Num

:V201n55c		w $008a				;Max. Seitenlänge.
			b $a0,3
			w LinesPerPage
			w HEXtoASCII_3,ASCIItoHEX
			w ChkInput_b
			b $00
:V201n55d		w $008a
			b $a6
			w PrnOpt1Num

;*** GW -> DOS.
:V201n60		b ESC_GRAPHICS
			b MOVEPENTO
			w $0010
			b $3b
			b FRAME_RECTO
			w $00af
			b $4b

			b MOVEPENTO
			w $0010
			b $5b
			b FRAME_RECTO
			w $00af
			b $6b

			b MOVEPENTO
			w $0010
			b $7b
			b FRAME_RECTO
			w $00af
			b $ab

			b ESC_PUTSTRING
			w $0018
			b $3a

if Sprache = Deutsch
			b PLAINTEXT,BOLDON
			b "Zeilenvorschub "
			b GOTOXY
			w $0024
			b $46
			b "Einfügen"
			b GOTOXY
			w $0018
			b $5a
			b "GeoWrite - Seitenende "
			b GOTOXY
			w $0024
			b $66
			b "Übernehmen"
			b GOTOXY
			w $0018
			b $7a
			b "DOS-Dateiname "
			b GOTOXY
			w $0024
			b $86
			b "Name vorschlagen"
			b GOTOXY
			w $0024
			b $96
			b "Neu eingeben"
			b NULL
endif

if Sprache = Englisch
			b PLAINTEXT,BOLDON
			b "Linefeed "
			b GOTOXY
			w $0024
			b $46
			b "Insert LF"
			b GOTOXY
			w $0018
			b $5a
			b "GeoWrite - End of page"
			b GOTOXY
			w $0024
			b $66
			b "Take over"
			b GOTOXY
			w $0018
			b $7a
			b "PCDOS-filename "
			b GOTOXY
			w $0024
			b $86
			b "Create default"
			b GOTOXY
			w $0024
			b $96
			b "Enter new name"
			b NULL
endif

:V201n61		b $40,$47
			w $0018,$001f,Def4a,Set4a
			b $60,$67
			w $0018,$001f,Def6a,Set6a
			b $80,$87
			w $0018,$001f,Def4b,Set4b
			b $90,$97
			w $0018,$001f,Def4c,Set4c
			b NULL

;*** CBM -> CBM.
:V201n70		b ESC_GRAPHICS
			b MOVEPENTO
			w $0010
			b $3b
			b FRAME_RECTO
			w $00af
			b $5b

			b MOVEPENTO
			w $0010
			b $6b
			b FRAME_RECTO
			w $00af
			b $ab

			b ESC_PUTSTRING
			w $0018
			b $3a

if Sprache = Deutsch
			b PLAINTEXT,BOLDON
			b "Zeilenvorschub "
			b GOTOXY
			w $0024
			b $46
			b "Einfügen"
			b GOTOXY
			w $0024
			b $56
			b "Ignorieren"
			b GOTOXY
			w $0018
			b $6a
			b "Dateityp "
			b GOTOXY
			w $0024
			b $76
			b "Commodore SEQ"
			b GOTOXY
			w $0024
			b $86
			b "Commodore PRG"
			b GOTOXY
			w $0024
			b $96
			b "Commodore USR"
			b GOTOXY
			w $0024
			b $a6
			b "Dateityp unverändert"
			b NULL
endif

if Sprache = Englisch
			b PLAINTEXT,BOLDON
			b "Linefeed "
			b GOTOXY
			w $0024
			b $46
			b "Insert LF"
			b GOTOXY
			w $0024
			b $56
			b "Ignore LF"
			b GOTOXY
			w $0018
			b $6a
			b "Filetype "
			b GOTOXY
			w $0024
			b $76
			b "Commodore SEQ"
			b GOTOXY
			w $0024
			b $86
			b "Commodore PRG"
			b GOTOXY
			w $0024
			b $96
			b "Commodore USR"
			b GOTOXY
			w $0024
			b $a6
			b "Do not change"
			b NULL
endif

:V201n71		b $40,$47
			w $0018,$001f,Def7a,Set7a
			b $50,$57
			w $0018,$001f,Def7b,Set7b
			b $70,$77
			w $0018,$001f,Def3e,Set3b
			b $80,$87
			w $0018,$001f,Def3f,Set3c
			b $90,$97
			w $0018,$001f,Def3g,Set3d
			b $a0,$a7
			w $0018,$001f,Def3h,Set3e
			b NULL

;*** GW -> CBM.
:V201n80		b ESC_GRAPHICS
			b MOVEPENTO
			w $0010
			b $3b
			b FRAME_RECTO
			w $00af
			b $4b

			b MOVEPENTO
			w $0010
			b $5b
			b FRAME_RECTO
			w $00af
			b $6b

			b MOVEPENTO
			w $0010
			b $7b
			b FRAME_RECTO
			w $00af
			b $ab

			b ESC_PUTSTRING
			w $0018
			b $3a

if Sprache = Deutsch
			b PLAINTEXT,BOLDON
			b "Zeilenvorschub "
			b GOTOXY
			w $0024
			b $46
			b "Einfügen"
			b GOTOXY
			w $0018
			b $5a
			b "GeoWrite - Seitenende "
			b GOTOXY
			w $0024
			b $66
			b "Übernehmen"
			b GOTOXY
			w $0018
			b $7a
			b "Dateityp "
			b GOTOXY
			w $0024
			b $86
			b "Commodore SEQ"
			b GOTOXY
			w $0024
			b $96
			b "Commodore PRG"
			b GOTOXY
			w $0024
			b $a6
			b "Commodore USR"
			b NULL
endif

if Sprache = Englisch
			b PLAINTEXT,BOLDON
			b "Linefeed "
			b GOTOXY
			w $0024
			b $46
			b "Insert LF"
			b GOTOXY
			w $0018
			b $5a
			b "GeoWrite - End of page"
			b GOTOXY
			w $0024
			b $66
			b "Take over"
			b GOTOXY
			w $0018
			b $7a
			b "Filetype "
			b GOTOXY
			w $0024
			b $86
			b "Commodore SEQ"
			b GOTOXY
			w $0024
			b $96
			b "Commodore PRG"
			b GOTOXY
			w $0024
			b $a6
			b "Commodore USR"
			b NULL
endif

;*** GW -> CBM.
:V201n81		b $40,$47
			w $0018,$001f,Def7a,Set7a
			b $60,$67
			w $0018,$001f,Def8a,Set8a
			b $80,$87
			w $0018,$001f,Def3b,Set3b
			b $90,$97
			w $0018,$001f,Def3c,Set3c
			b $a0,$a7
			w $0018,$001f,Def3d,Set3d
			b NULL

;*** Seitenformat.
:V201n90		b ESC_GRAPHICS
			b MOVEPENTO
			w $0010
			b $3b
			b FRAME_RECTO
			w $00af
			b $5b

			b MOVEPENTO
			w $0010
			b $6b
			b FRAME_RECTO
			w $00af
			b $ab

			b ESC_PUTSTRING
			w $0018
			b $3a

if Sprache = Deutsch
			b PLAINTEXT,BOLDON
			b "Randeinstellungen "
			b GOTOXY
			w $0018
			b $46
			b "Links:"
			b GOTOXY
			w $0068
			b $46
			b "Rechts:"
			b GOTOXY
			w $0018
			b $56
			b "Absatz-Tabulator:"

			b GOTOXY
			w $0018
			b $6a
			b "Tabulatoren "

			b GOTOXY
			w $0024
			b $76	,"T1:"
			b GOTOXY
			w $0024
			b $86	,"T2:"
			b GOTOXY
			w $0024
			b $96	,"T3:"
			b GOTOXY
			w $0024
			b $a6	,"T4:"
			b GOTOXY
			w $0074
			b $76	,"T5:"
			b GOTOXY
			w $0074
			b $86	,"T6:"
			b GOTOXY
			w $0074
			b $96	,"T7:"
			b GOTOXY
			w $0074
			b $a6	,"T8:"
			b NULL
endif

;*** Seitenformat.
if Sprache = Englisch
			b PLAINTEXT,BOLDON
			b "Border-settings"
			b GOTOXY
			w $0018
			b $46
			b "Left:"
			b GOTOXY
			w $0068
			b $46
			b "Right:"
			b GOTOXY
			w $0018
			b $56
			b "Left margin:"

			b GOTOXY
			w $0018
			b $6a
			b "Tabulatoren "

			b GOTOXY
			w $0024
			b $76	,"T1:"
			b GOTOXY
			w $0024
			b $86	,"T2:"
			b GOTOXY
			w $0024
			b $96	,"T3:"
			b GOTOXY
			w $0024
			b $a6	,"T4:"
			b GOTOXY
			w $0074
			b $76	,"T5:"
			b GOTOXY
			w $0074
			b $86	,"T6:"
			b GOTOXY
			w $0074
			b $96	,"T7:"
			b GOTOXY
			w $0074
			b $a6	,"T8:"
			b NULL
endif

:V201n91		b $40,$47			;"Linker Rand".
			w $0040,$0057,Def9a,Set9i
			b $40,$47			;"Rechter Rand".
			w $0090,$00a7,Def9b,Set9j
			b $50,$57			;"Absatztabulator".
			w $0090,$00a7,Def9c,Set9k
			b $70,$77			;"Dez. Tab#1".
			w $0018,$001f,Def9d,Set9a
			b $70,$77			;"Pos. Tab#1".
			w $0040,$0057,Def9e,Set9l
			b $80,$87			;"Dez. Tab#2".
			w $0018,$001f,Def9f,Set9b
			b $80,$87			;"Pos. Tab#2".
			w $0040,$0057,Def9g,Set9m
			b $90,$97			;"Dez. Tab#3".
			w $0018,$001f,Def9h,Set9c
			b $90,$97			;"Pos. Tab#3".
			w $0040,$0057,Def9i,Set9n
			b $a0,$a7			;"Dez. Tab#4".
			w $0018,$001f,Def9j,Set9d
			b $a0,$a7			;"Pos. Tab#4".
			w $0040,$0057,Def9k,Set9o
			b $70,$77
			w $0068,$006f,Def9l,Set9e
			b $70,$77			;"Pos. Tab#1".
			w $0090,$00a7,Def9m,Set9p
			b $80,$87
			w $0068,$006f,Def9n,Set9f
			b $80,$87			;"Pos. Tab#6".
			w $0090,$00a7,Def9o,Set9q
			b $90,$97
			w $0068,$006f,Def9p,Set9g
			b $90,$97			;"Pos. Tab#7".
			w $0090,$00a7,Def9q,Set9r
			b $a0,$a7
			w $0068,$006f,Def9r,Set9h
			b $a0,$a7			;"Pos. Tab#8".
			w $0090,$00a7,Def9s,Set9s
			b NULL

;*** Seitenformat.
:V201n95a		w $0042	 			;Linker Rand.
			b $40,2
			w GW_LRand
			w HEXtoASCII_1,ASCIItoHEX_1, ChkInput_c
			b $ff
:V201n95b		w $0042
			b $46
			w PrnOpt8Num

:V201n95c		w $0092	 			;Rechter Rand.
			b $40,2
			w GW_RRand
			w HEXtoASCII_2,ASCIItoHEX_1, ChkInput_d
			b $ff
:V201n95d		w $0092
			b $46
			w PrnOpt8Num

:V201n95e		w $0092	 			;Absatz.
			b $50,2
			w GW_AbsatzTab
			w HEXtoASCII_1,ASCIItoHEX_1, ChkInput_c
			b $ff
:V201n95f		w $0092
			b $56
			w PrnOpt8Num

:V201n95g		w $0042	 			;Tabulator #1.
			b $70,2
			w GW_Tab1+0
			w HEXtoASCII_2,ASCIItoHEX_1, ChkInput_e
			b $ff
:V201n95h		w $0042
			b $76
			w PrnTab1Opt

:V201n95i		w $0042	 			;Tabulator #2.
			b $80,2
			w GW_Tab1+2
			w HEXtoASCII_2,ASCIItoHEX_1, ChkInput_e
			b $ff
:V201n95j		w $0042
			b $86
			w PrnTab1Opt

:V201n95k		w $0042	 			;Tabulator #3.
			b $90,2
			w GW_Tab1+4
			w HEXtoASCII_2,ASCIItoHEX_1, ChkInput_e
			b $ff
:V201n95l		w $0042
			b $96
			w PrnTab1Opt

:V201n95m		w $0042	 			;Tabulator #4.
			b $a0,2
			w GW_Tab1+6
			w HEXtoASCII_2,ASCIItoHEX_1, ChkInput_e
			b $ff
:V201n95n		w $0042
			b $a6
			w PrnTab1Opt

:V201n95o		w $0092	 			;Tabulator #5.
			b $70,2
			w GW_Tab1+8
			w HEXtoASCII_2,ASCIItoHEX_1, ChkInput_e
			b $ff
:V201n95p		w $0092
			b $76
			w PrnTab1Opt

:V201n95q		w $0092	 			;Tabulator #6.
			b $80,2
			w GW_Tab1+10
			w HEXtoASCII_2,ASCIItoHEX_1, ChkInput_e
			b $ff
:V201n95r		w $0092
			b $86
			w PrnTab1Opt

:V201n95s		w $0092	 			;Tabulator #7.
			b $90,2
			w GW_Tab1+12
			w HEXtoASCII_2,ASCIItoHEX_1, ChkInput_e
			b $ff
:V201n95t		w $0092
			b $96
			w PrnTab1Opt

:V201n95u		w $0092	 			;Tabulator #8.
			b $a0,2
			w GW_Tab1+14
			w HEXtoASCII_2,ASCIItoHEX_1, ChkInput_e
			b $ff
:V201n95v		w $0092
			b $a6
			w PrnTab1Opt

;*** Texte verbinden.
:V201na0		b ESC_GRAPHICS
			b MOVEPENTO
			w $0010
			b $4b
			b FRAME_RECTO
			w $00af
			b $ab

			b ESC_PUTSTRING
			w $0018
			b $3f

if Sprache = Deutsch
			b PLAINTEXT,BOLDON
			b "Mehrere Texte zu einer"
			b GOTOXY
			w $0018
			b $4a
			b "GeoWrite-Datei verbinden "
			b GOTOXY
			w $0024
			b $5e
			b "Dateien zusammenfügen"
			b GOTOXY
			w $0024
			b $76
			b "Direkt verbinden"
			b GOTOXY
			w $0024
			b $86
			b "Leerzeile einfügen"
			b GOTOXY
			w $0024
			b $96
			b "Neue Seite beginnen"
			b NULL
endif

if Sprache = Englisch
			b PLAINTEXT,BOLDON
			b "Combine selected files"
			b GOTOXY
			w $0018
			b $4a
			b "into a single document"
			b GOTOXY
			w $0024
			b $5e
			b "Combine files"
			b GOTOXY
			w $0024
			b $76
			b "Combine directly"
			b GOTOXY
			w $0024
			b $86
			b "Insert empty line"
			b GOTOXY
			w $0024
			b $96
			b "Start new page"
			b NULL
endif

:V201na1		b $58,$5f
			w $0018,$001f,Def10a,Set10a
			b $70,$77
			w $0018,$001f,Def10b,Set10b
			b $80,$87
			w $0018,$001f,Def10c,Set10c
			b $90,$97
			w $0018,$001f,Def10d,Set10d
			b NULL

;*** GW-Konvertieren.
:V201nb0		b ESC_GRAPHICS
			b MOVEPENTO
			w $0010
			b $4b
			b FRAME_RECTO
			w $00af
			b $ab

			b ESC_PUTSTRING
			w $0018
			b $3f

if Sprache = Deutsch
			b PLAINTEXT,BOLDON
			b "Konvertieren von"
			b GOTOXY
			w $0018
			b $4a
			b "GeoWrite-Dokumenten:"
			b GOTOXY
			w $0024
			b $5e
			b "Layout & Fonts ändern"
			b GOTOXY
			w $0024
			b $76
			b "Nur Layout ändern"
			b GOTOXY
			w $0024
			b $86
			b "Nur Fonts wechseln"
			b GOTOXY
			w $0024
			b $96
			b "1:1 konvertieren"
			b NULL
endif

if Sprache = Englisch
			b PLAINTEXT,BOLDON
			b "Convert GeoWrite-"
			b GOTOXY
			w $0018
			b $4a
			b "documents:"
			b GOTOXY
			w $0024
			b $5e
			b "Change layout + fonts"
			b GOTOXY
			w $0024
			b $76
			b "Change layout only"
			b GOTOXY
			w $0024
			b $86
			b "Change fonts only"
			b GOTOXY
			w $0024
			b $96
			b "Change nothing"
			b NULL
endif

:V201nb1		b $58,$5f
			w $0018,$001f,Def11a,Set11a
			b $70,$77
			w $0018,$001f,Def11b,Set11b
			b $80,$87
			w $0018,$001f,Def11c,Set11c
			b $90,$97
			w $0018,$001f,Def11d,Set11d
			b NULL

;*** Icon-Tabelle.
:Icon_2Tab1		b 9
			w $0000
			b $00

			w Icon_203
			b $00,$08,$05,$18
			w L201ExitGD

			w Icon_201
			b $05,$08,$05,$18
			w SlctPrinter

			w Icon_202
			b $0a,$08,$05,$18
			w SlctFont

			w Icon_205
			b $0f,$08,$05,$18
			w NoCTab

			w Icon_206
			b $14,$08,$05,$18
			w SlctCTabDOS

			w Icon_207
			b $19,$08,$05,$18
			w SlctCTabCBM

			w Icon_208
			b $1e,$08,$05,$18
			w SlctCTabTXT

			w Icon_209
			b $23,$08,$05,$18
			w DoSetupMenu

			w Icon_204
			b $15,$b8,$02,$10
			w ChangePage

;*** Icon-Tabelle für Setup-Menü.
:Icon_Tab2		b 5
			w $0000
			b $00

			w Icon_214
			b $08,$48,$05,$18
			w SelectMenu

			w Icon_210
			b $0d,$48,$05,$18
			w SelectMenu

			w Icon_211
			b $12,$48,$05,$18
			w SelectMenu

			w Icon_212
			b $17,$48,$05,$18
			w SelectMenu

			w Icon_213
			b $1c,$48,$05,$18
			w SelectMenu

;*** Icons.
if Sprache = Deutsch
:Icon_201
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_201
<MISSING_IMAGE_DATA>
endif

:Icon_202
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
:Icon_203
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_203
<MISSING_IMAGE_DATA>
endif

:Icon_204
<MISSING_IMAGE_DATA>

:Icon_205
<MISSING_IMAGE_DATA>

:Icon_206
<MISSING_IMAGE_DATA>

:Icon_207
<MISSING_IMAGE_DATA>

:Icon_208
<MISSING_IMAGE_DATA>

:Icon_209
<MISSING_IMAGE_DATA>

;*** Icons für Setup-Menu.
:Icon_210
<MISSING_IMAGE_DATA>

:Icon_211
<MISSING_IMAGE_DATA>

:Icon_212
<MISSING_IMAGE_DATA>

:Icon_213
<MISSING_IMAGE_DATA>

:Icon_214
<MISSING_IMAGE_DATA>

;*** Icons für Informations-Seite.
:Icon_221
<MISSING_IMAGE_DATA>

:Icon_222
<MISSING_IMAGE_DATA>

:Icon_223
<MISSING_IMAGE_DATA>

:Icon_224
<MISSING_IMAGE_DATA>

:Icon_225
<MISSING_IMAGE_DATA>

:Icon_226
<MISSING_IMAGE_DATA>
