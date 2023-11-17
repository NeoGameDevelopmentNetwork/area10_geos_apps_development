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

			n	"mod.#410.obj"
			o	ModStart
			q	EndProgrammCode
			r	EndAreaCBM

			jmp	CBM_PrnFile

			t	"-GetConvTab1"
			t	"-GetConvTab2"
			t	"-CBM_SlctPrnFil"

;*** Commodore-Datei drucken.
:CBM_PrnFile
:SetPrnOpt		ClrB	curSubMenu

:SetPrnOpt1		jsr	Bildschirm_a
:SetPrnOpt2		jsr	InitMenuPage		;Menüseite initialisieren.

			jsr	SetHelp

			LoadW	otherPressVec,ChkOptSlct
			LoadW	r0,Icon_Tab1
			jsr	DoIcons			;Menü aktivieren.
:SetPrnOpt3		StartMouse
			NoMseKey
			rts

;*** Zeiger auf Hilfedatei bereitstellen.
:SetHelp		LoadW	r0,HelpFileName
			lda	#<SetPrnOpt1
			ldx	#>SetPrnOpt1
			jmp	InstallHelp

;*** Zurück zu GeoDOS.
:L410ExitGD		jsr	ClrScreen
			jmp	InitScreen

;*** Dateien auswählen.
:L410m0			NoMseKey

			jsr	ClrScreen		;Fenster löschen.

			lda	V410g0
			ldx	#<ConvTabBase
			ldy	#>ConvTabBase
			jsr	LoadConvTab

			lda	Target_Drv
			jsr	NewDrive
			ldx	#%01000000
			bit	V410d7
			bpl	:101
			ldx	#%10000000
::101			LoadW	r14,V410c3
			jsr	SlctPrnFile		;Dateien auswählen.
			cmp	#$00
			beq	:102
			jmp	L410ExitGD		;Zurück zu GeoDOS.

::102			lda	curDrive
			sta	Target_Drv

			jsr	Port_Test		;Drucker testen.
			txa
			beq	:103
			DB_OK	V410j0			;Fehler: "Drucker nicht bereit!".
			jmp	CBM_PrnFile

::103			LoadW	a5,FileNTab		;Zeiger auf Anfang Datei-Tabelle.
			jsr	DoInfoBox
			PrintStrgV410k0

;*** Ausgewählte Dateien drucken.
:L410n0			lda	Target_Drv
			jsr	NewDrive

			MoveW	a5,r14			;Zeiger auf nächste CBM-Datei.
			jsr	LookCBMfile		;CBM-Datei-Eintrag suchen.
			tay
			bne	L410o0

			bit	V410d7
			bmi	:101
			jmp	L410p0			;Gefunden ? Ja, drucken.
::101			jmp	L410p1

;*** Zeiger auf nächste Datei.
:L410o0			AddVBW	16,a5			;Zeiger auf nächste Datei.
			ldy	#$00			;Ende der Tabelle erreicht ?
			lda	(a5L),y
			bne	L410n0			;Nein, weiter...
:L410o1			jsr	ClrBox
			jmp	L410ExitGD		;Zurück zu GeoDOS.

;*** Ausdruck der aktuellen Datei beenden.
:L410o2			lda	V410d5			;FF-Code ausgeben ?
			beq	:101			;Nein, weiter...
			jsr	Do_PageBreak
::101			jmp	L410o0			;Weiter mit nächster Datei.

;*** Ausdruck abbrechen.
:L410o3			jsr	Do_PageBreak
			jmp	L410o1			;Weiter mit nächster Datei.

;*** Nächste Datei drucken.
:L410p0			stx	:101 +1
			jsr	ClrBoxText		;Infobox.
			PrintStrgV410k0
			jsr	PrnFileName

::101			ldx	#$ff
			lda	diskBlkBuf+3,x		;Ersten Sektor der Datei ermitteln.
			ldy	diskBlkBuf+4,x
			jsr	L410q0
			txa
			bne	:102
			jmp	L410o2
::102			jmp	L410o3

;*** Nächste Datei drucken.
:L410p1			stx	:101 +1
			jsr	ClrBoxText		;Infobox.
			PrintStrgV410k0
			jsr	PrnFileName

::101			ldx	#$ff
			lda	diskBlkBuf+3,x		;Ersten Sektor der Datei ermitteln.
			ldy	diskBlkBuf+4,x
			sta	r1L
			sty	r1H
			LoadW	r4,fileHeader
			jsr	GetBlock

			ClrB	V410d9

			lda	#$01
			sta	:102 +1
::102			lda	#$00
			cmp	#62
			beq	:103
			asl
			tax
			lda	fileHeader+0,x
			beq	:103
			ldy	fileHeader+1,x

			jsr	L410q0
			txa
			bne	:104
			inc	:102 +1
			jmp	:102

::103			jmp	L410o2
::104			jmp	L410o3

;*** Aktuelles Byte auf Gültigkeit testen.
:L410p2			ldx	V410d9
			beq	:101
			dec	V410d9
			ldx	#$ff
			rts

::101			cmp	#ESC_RULER
			bne	:102
			lda	#26
			bne	:106

::102			cmp	#NEWCARDSET
			bne	:103
			lda	#3
			bne	:106

::103			cmp	#ESC_GRAPHICS
			bne	:107

			ldx	#$00
::104			lda	V410h2,x
			beq	:105
			jsr	Port_Out
			inx
			bne	:104

::105			lda	#4
::106			sta	V410d9
			ldx	#$ff
			rts

::107			ldx	#$00
			rts

;*** Seq.Datei bzw. Datensatz drucken.
:L410q0			sta	r1L
			sty	r1H

			ClrB	pressFlag

:L410q1			LoadW	r4,diskBlkBuf		;Nächsten Sektor der Datei einlesen.
			lda	Target_Drv		;CBM-Laufwerk aktivieren.
			jsr	NewDrive
			jsr	GetBlock
			txa
			beq	:101
			jmp	DiskError		;Disketten-Fehler.

::101			jsr	Port_Init		;Drucker aktivieren.

			lda	#$ff
			ldx	diskBlkBuf+0		;Anzahl Bytes in Puffer berechnen.
			bne	:102
			lda	diskBlkBuf+1
::102			sta	:106 +1

			ldy	#$01
::103			iny
			lda	diskBlkBuf,y		;Zeichen aus Puffer lesen.

			bit	V410d7
			bpl	:103a
			jsr	L410p2
			cpx	#$00
			bne	:106

::103a			cmp	#LF
			bne	:103b
			ldx	V410d6
			beq	:105
			bne	:106

::103b			cmp	#CR			;CR-Code ?
			bne	:104			;Nein, weiter...
			ldx	V410d6			;LF-Code anhängen ?
			beq	:105			;Nein, weiter...
			jsr	Port_Out		;CR-Code ausgeben.
			bit	V410d6			;LF-Code anhängen ?
			bpl	:106
			lda	#LF			;LF-Code ausgeben.
			bne	:105
::104			tax				;Zeichen umwandeln.
			lda	ConvTabBase,x
::105			jsr	Port_Out		;Zeichen ausgeben.
::106			cpy	#$ff			;Alle Zeichen aus Puffer gedruckt ?
			bne	:103			;Nein, weiter...

			jsr	Port_End		;Drucker deaktivieren.
			ldx	pressFlag
			beq	L410q2
			rts

;*** Zeiger auf nächsten Sektor.
:L410q2			lda	diskBlkBuf+0		;Zeiger auf nächsten Sektor.
			beq	:101 			;Datei-Ende ? Ja, Ende...
			sta	r1L
			lda	diskBlkBuf+1
			sta	r1H
			jmp	L410q1			;Nächsten Sektor lesen.

::101			ldx	#$00
			rts

;*** Dateinamen ausgeben.
:PrnFileName		lda	#$22			;Anführungszeichen ausgeben.
			jsr	SmallPutChar

			ldy	#$00			;Dateiname ausgeben.
::101			sty	:102 +1

			lda	(a5L),y
			beq	:103
			jsr	SmallPutChar

::102			ldy	#$ff
			iny
			cpy	#16
			bne	:101

::103			lda	#$22			;Anführungszeichen ausgeben.
			jmp	SmallPutChar

;*** Menüseite initialisieren.
:InitMenuPage		jsr	i_C_MenuBack		;Menüfenster löschen.
			b	$01,$06,$26,$11
			FillPRec$00,$31,$ae,$0009,$0136

			lda	curSubMenu		;Menütext ausgeben.
			asl
			tax
			lda	MenuText+0,x
			sta	r0L
			lda	MenuText+1,x
			sta	r0H
			jsr	PutString

			jmp	SetClkPos		;Optionen auf Bildschirm.

;*** Fenster aufbauen.
:Bildschirm_a		jsr	ClrScreen		;Bildschirm löschen.

			jsr	i_C_MenuTitel
			b	$00,$00,$28,$01
			jsr	i_C_MenuBack
			b	$00,$01,$28,$18

			FillPRec$00,$00,$07,$0008,$013f

			jsr	UseGDFont
			Print	$0008,$06
if Sprache = Deutsch
			b	PLAINTEXT,"CBM  -  Druckerausgabe",NULL
endif
if Sprache = Englisch
			b	PLAINTEXT,"CBM  -  Print files",NULL
endif

			LoadW	r0,V410l1
			jsr	GraphicsString
			jsr	i_C_Register
			b	$01,$05,$08,$01
			jsr	i_C_Register
			b	$0a,$05,$09,$01
			jsr	i_C_Register
			b	$14,$05,$0a,$01

			jsr	i_C_MenuMIcon
			b	$00,$01,$0a,$03
			rts

;*** Bildschirm aufbauen.
:SetClkPos		jsr	SetDataVec		;Zeiger auf Menütabelle.

			FillPRec$00,$b9,$c6,$0001,$013e

			jsr	UseGDFont
			lda	curSubMenu
			asl
			tax
			lda	InfoText+0,x
			sta	r0L
			lda	InfoText+1,x
			sta	r0H
			ClrB	currentMode
			LoadW	r11,$0008
			LoadB	r1H,$c4
			jsr	PutString

::101			ldy	#$00
			lda	(a7L),y			;Alle Daten ausgegeben ?
			bne	:102			;Nein, weiter...
			ClrB	pressFlag		;Ende.
			rts

::102			jsr	CopyRecData		;Daten für Rechteck einlesen.

			ldy	#$07
			lda	(a7L),y
			tax
			dey
			lda	(a7L),y
			ldy	#$00
			jsr	CallRoutine		;Ausgabefeld definieren.
			tya				;Muster setzen ?
			bmi	:103			;Nein, weiter...

			jsr	ShowClkOpt		;Klickoption ausgeben.

::103			jsr	CopyRecData		;Daten für Rahmen einlesen.
			lda	r2H			;Rahmen zeichen ?
			beq	:104			;Nein, weiter...

			SubVW	1,r3			;Grenzen des Rechtecks -1.
			AddVBW	1,r4
			dec	r2L
			inc	r2H

			lda	#%11111111		;Rahmen zeichen.
			jsr	FrameRectangle

::104			AddVBW	10,a7			;Zeiger auf nächste Option.
			jmp	:101

;*** Zeiger auf Datenliste.
:SetDataVec		lda	curSubMenu
			asl
			tax
			lda	V410n0+0,x
			sta	a7L
			lda	V410n0+1,x
			sta	a7H
			rts

;*** Klickoption anzeigen.
:ShowClkOpt		pha
			Pattern	0			;Muster setzen.
			jsr	Rectangle		;Inhalt löschen.

			jsr	DefColOpt

			pla				;Option gewählt ? (AKKU = $02)
			beq	:101			;Nein, weiter...

			AddVBW	1,r3			;Schalter zeichnen.
			SubVW	1,r4
			inc	r2L
			dec	r2H

			Pattern	1
			jsr	Rectangle
::101			jmp	SetColOpt

;*** Farbe für Klick-Option definieren.
:DefClkOpt		jsr	CopyRecData		;Daten für Rechteck einlesen.
			jsr	DefColOpt
			jsr	SetColOpt
			ldy	#$ff
			rts

;*** Prüfen ob Option angeklickt.
:ChkOptSlct		lda	#$00
			jsr	:110
			bne	:102

			lda	#$06
			jsr	:110
			bne	:103

			lda	#$0c
			jsr	:110
			bne	:104

::101			jmp	:120

::102			lda	#$00
			b $2c
::103			lda	#$01
			b $2c
::104			lda	#$02
			cmp	curSubMenu
			beq	:105
			sta	curSubMenu
			jmp	SetPrnOpt2		;Nein, weitertesten.
::105			jmp	SetPrnOpt3

::110			clc
			adc	#<V410a0
			sta	a7L
			lda	#$00
			adc	#>V410a0
			sta	a7H

			jsr	CopyRecData		;Werte aus Menütabelle nach ":r2".
			jmp	IsMseInRegion		;Ist Maus innerhalb eines Options-

::120			jsr	SetDataVec		;Zeiger auf Menütabelle.

::121			ldy	#$00
			lda	(a7L),y			;Ende Menütabelle erreicht ?
			bne	:122			;Nein, weiter.
			ClrB	pressFlag
			rts				;Ende.

::122			jsr	CopyRecData		;Werte aus Menütabelle nach ":r2".
			jsr	IsMseInRegion		;Ist Maus innerhalb eines Options-
			tax				;Icons ?
			beq	:123			;Nein, weitertesten.

			ldy	#$09
			jsr	CallNumRout
			jsr	SetClkPos		;Neuen Wert für Option anzeigen.
			cli
			NoMseKey			;Warten bis keine Maustaste gedrückt.
			rts				;Ende.

::123			AddVBW	10,a7
			jmp	:121

;*** Daten für Rahmen nach ":r2".
:CopyRecData		ldy	#$05
::101			lda	(a7L),y
			sta	r2,y
			dey
			bpl	:101
			rts

;*** Routine aufrufen.
:CallNumRout		lda	(a7L),y
			tax
			dey
			lda	(a7L),y
			jmp	CallRoutine

;*** Farbe berechnen.
:DefColOpt		PushW	r3			;Register r3 und r4 speichern.
			PushW	r4

			ldx	#r3L			;minX und maxX berechnen.
			ldy	#$03
			jsr	DShiftRight
			ldx	#r4L
			ldy	#$03
			jsr	DShiftRight

			lda	r2L			;minY-Koordinate.
			lsr
			lsr
			lsr
			sta	SetColOpt +4

			lda	r2H			;maxY-Koordinate.
			suba	r2L
			lsr
			lsr
			lsr
			add	1
			sta	SetColOpt +6

			lda	r3L			;minX-Koordinate.
			sta	SetColOpt +3

			sec				;maxX-Koordinate.
			lda	r4L
			sbc	r3L
			add	1
			sta	SetColOpt +5

			PopW	r4			;Register r3 und r4 wiederherstellen.
			PopW	r3
			rts

;*** Farbe auf Bildschirm.
:SetColOpt		jsr	i_ColorBox		;Farbe setzen.
			b	$00,$00,$00,$01,$01
			rts

;*** Druckerport anzeigen.
:DefOpt1a		lda	#$00
			b $2c
:DefOpt1b		lda	#$ff
			cmp	V410d2
			bne	:101
			ldy	#$02
::101			rts

;*** Geräteadresse anzeigen.
:DefOpt1c		jsr	GetDevAdr		;Tag ausgeben,
			ldy	#$00
			jmp	PutNumOnScrn

;*** Sekundäradresse anzeigen.
:DefOpt1d		jsr	GetSekAdr		;Tag ausgeben,
			ldy	#$01
			jmp	PutNumOnScrn

;*** Druckerport wechseln.
:SetOpt1a		lda	#$00
			b $2c
:SetOpt1b		lda	#$ff
			sta	V410d2
			rts

;*** Druckeradresse ändern.
:SetOpt1c		lda	#$00			;Tag eingeben.
			b $2c
:SetOpt1d		lda	#$01			;Monat eingeben.
			asl
			tax
			lda	V410o1+0,x
			sta	a7L
			lda	V410o1+1,x
			sta	a7H
			jmp	InpOptNum

;*** Übersetzungs-Modus anzeigen.
:DefOpt2a		lda	#$00
			b $2c
:DefOpt2b		lda	#$ff
			cmp	V410d1
			bne	:101
			ldy	#$02
::101			rts

;*** Übersetzungstabelle anzeigen.
:DefOpt2c		lda	#<V410g0+1
			ldx	#>V410g0+1
			ldy	V410g0
			bne	:101
			lda	#<V410g1
			ldx	#>V410g1
::101			sta	r0L
			stx	r0H
			LoadW	r11,$006a
			LoadB	r1H,$66

			lda	#$00
::102			pha
			tay
			lda	(r0L),y
			jsr	SmallPutChar
			pla
			add	1
			cmp	#16
			bcc	:102
			jmp	DefClkOpt

;*** Seitenvorschub am Ende jeder Datei.
:DefOpt2d		bit	V410d5
			bpl	:101
			ldy	#$02
::101			rts

;*** LineFeed einfügen.
;CBM: $00 = Linefeed unverändert.
;     $40 = LineFeed ignorieren.
;     $80 = LineFeed einfügen.
:DefOpt2e		bit	V410d6
			bpl	:101
			ldy	#$02
::101			rts

;*** LineFeed einfügen.
:DefOpt2f		bit	V410d6
			bvc	:101
			ldy	#$02
::101			rts

;*** Übersetzungs-Modus anzeigen.
:SetOpt2a		lda	#$00
			b $2c
:SetOpt2b		lda	#$ff
			sta	V410d1
			rts

;*** Übersetzungstabelle anzeigen.
:SetOpt2c		jsr	SetOpt2b
			jmp	SlctCTabTXT

;*** Seitenvorschub am Ende jeder Datei.
:SetOpt2d		lda	V410d5
			eor	#%11111111
			sta	V410d5
			rts

;*** LineFeed-Modus ändern.
:SetOpt2e		ldx	#$80
			lda	V410d6
			beq	:101
			cmp	#$40
			beq	:101
			ldx	#$00
::101			stx	V410d6
			rts

;*** LineFeed-Modus ändern.
:SetOpt2f		ldx	#$40
			lda	V410d6
			beq	:101
			cmp	#$80
			beq	:101
			ldx	#$00
::101			stx	V410d6
			rts

;*** Standard/GW-Text drucken.
:DefOpt3a		lda	#$00
			b $2c
:DefOpt3b		lda	#$ff
			cmp	V410d7
			bne	:101
			ldy	#$02
::101			rts

;*** Standard/GW-Text ändern.
:SetOpt3a		lda	#$00
			b $2c
:SetOpt3b		lda	#$ff
			sta	V410d7
			rts

;*** Geräteadresse einlesen.
:GetDevAdr		lda	V410d3
			rts

;*** Geräteadresse prüfen.
:ChkDevAdr		lda	r0H
			bne	:101
			lda	r0L
			cmp	#$04
			bcc	:101
			cmp	#$08
			bcs	:101
			clc
			rts
::101			sec
			rts

;*** Geräteadresse setzen.
:SetDevAdr		lda	r0L
			sta	V410d3
			rts

;*** Sekundäradresse einlesen.
:GetSekAdr		lda	V410d4
			rts

;*** Sekundäradresse prüfen.
:ChkSekAdr		lda	r0H
			bne	:101
			clc
			rts
::101			sec
			rts

;*** Sekundäradresse setzen.
:SetSekAdr		lda	r0L
			sta	V410d4
			rts

;*** $HEX nach ASCII wandeln.
:HEXtoASCII		lda	r15L
			sta	r0L
			lda	#$00
			sta	r0H
			sta	r1L
			jsr	ZahlToASCII

			ldy	#$00
::101			lda	ASCII_Zahl,y		;Word ab $0101 in Eingabespeicher
			beq	:102			;übertragen.
			sta	InputBuf,y
			iny
			cpy	#$03
			bne	:101
			lda	#$00			;Ende des Eingabespeichers
::102			sta	InputBuf,y		;markieren.
			rts

;*** ASCII nach $HEX-Word wandeln.
:ASCIItoHEX		ClrW	r0			;Word auf $0000 setzen.
			lda	InputBuf		;Eingabe-Speicher leer ?
			bne	:101			;Nein, weiter.
			rts

::101			ldy	#$01			;Länge der Zahl ermitteln.
::102			lda	InputBuf,y
			beq	:103
			iny
			bne	:102
			iny

::103			dey
			sty	r1L			;Länge der Zahl merken.
			ClrB	r1H			;Zeiger auf Dezimal-Stelle für 1er.

::104			ldy	r1L
			lda	InputBuf,y		;Zeichen aus Zahlenstring holen.
			sub	$30			;Reinen Zahlenwert (0-9) isolieren.
			bcc	:106			;Unterlauf, keine Ziffer.
			cmp	#$0a			;Wert >= 10 ?
			bcs	:106			;Ja, keine Ziffer.
			tax
			beq	:106			;Null ? Ja, weiter...

::105			ldy	r1H			;Je nach Dezimal-Stelle, 1er, 10er
			lda	InputData,y		;oder 100er addieren.
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

;*** Zahlenwert ausgeben.
:PutNumOnScrn		pha
			tya
			asl
			tax
			lda	V410o0+0,x
			sta	a6L
			lda	V410o0+1,x
			sta	a6H

			lda	#$00			;Ausgabe-Fenster löschen.
			jsr	ShowClkOpt

			ldy	#$00
			lda	(a6L),y			;X-Koordinate für Zahlenausgabe.
			sta	r11L
			iny
			lda	(a6L),y
			sta	r11H
			iny
			lda	(a6L),y			;Y-Koordinate für Zahlenausgabe.
			sta	r1H

			jsr	UseGDFont
			ClrB	currentMode

			pla
			sta	r0L
			ClrB	r0H
			lda	#%11000000
			jsr	PutDecimal
			ldy	#$ff
			rts

;*** Zahl Eingeben.
:InpOptNum		PopW	V410f1			;Rücksprung-Adresse merken.

			lda	mouseOn			;Menüs & Icons aus.
			and	#%10011111
			sta	mouseOn
			ClrW	otherPressVec
			MoveW	a7,V410f2		;Zeiger auf Menütabelle merken.

;*** Neue Zahl eingeben.
:InpNOptNum		ldy	#$04			;Zahlenwert einlesen.
			jsr	CallNumRout
			sta	r15L
			ldy	#$06			;Zahlenwert nach ASCII wandeln.
			jsr	CallNumRout

			ldy	#$00
			lda	(a7L),y			;X-Koordinate für Eingabe.
			sta	r11L
			iny
			lda	(a7L),y
			sta	r11H
			iny
			lda	(a7L),y			;Y-Koordinate für Eingabe.
			sta	r1H

			jsr	UseGDFont
			ClrB	currentMode
			LoadW	r0,InputBuf		;Zeiger auf Eingabespeicher.
			LoadB	r1L,$00			;Standard-Fehler-Routine.
			LoadB	r2L,2
			LoadW	keyVector,:101		;Zeiger auf Abschluß-Routine.
			jsr	GetString
			jsr	InitForIO
			LoadB	$d028,$00
			jmp	DoneWithIO

;*** Eingabe abschließen.
::101			MoveW	V410f2,a7		;Zeiger auf Menütabelle zurücksetzen.

			ldy	#$08			;Eingabe nach HEX wandeln.
			jsr	CallNumRout

			ldy	#$0a			;Zahlenwert prüfen.
			jsr	CallNumRout
			bcc	:102			;Wert in Ordnung ? Ja, weiter.
			jsr	SetClkPos		;Alte Werte ausgeben.
			MoveW	V410f2,a7		;Zahl erneut eingeben.
			jmp	InpNOptNum

::102			ldy	#$0c			;Eingabe übernehmen.
			jsr	CallNumRout

			lda	mouseOn			;Icons aktivieren.
			ora	#%00100000
			sta	mouseOn
			LoadW	otherPressVec,ChkOptSlct

			jsr	SetHelp

			PushW	V410f1			;Rücksprung-Adresse wieder herstellen.
			rts

;*** Konvertierungstabelle DOS laden.
:SlctCTabTXT		jsr	ClrScreen
			jsr	LoadConvIndex
			txa
			bne	NoCTab

			jsr	GetCTabTXT
			txa
			bne	GotoMenu

			lda	r10L
			sta	V410g0
			lda	#<V410g0 +1
			ldx	#>V410g0 +1

;*** Auswahl Parameterdatei beenden.
:ExitConvTab		sta	r1L
			stx	r1H
			ldx	#r15L
			ldy	#r1L
			lda	#$10
			jsr	CopyFString

;*** Zum Menü zurück.
:GotoMenu		jmp	SetPrnOpt1		;Zurück zum Druck-Modus.

;*** Keine Tabellen auf Diskette.
:NoCTab			cpx	#$05
			beq	:101
			jmp	DiskError

::101			DB_OK	V410j1
			jmp	SetPrnOpt1		;Zurück zum Druck-Modus.

;*** Einsprungadressen und Verzweigung zu den
;    entsprechenden Port-Routinen.
:Port_Init		lda	V410d3
			jsr	SetDevice
			jsr	InitForIO

			bit	V410d2
			bpl	:101
			jmp	IEC_Init
::101			jmp	UP_Init

:Port_End		bit	V410d2
			bpl	:101
			jmp	IEC_End
::101			jmp	UP_End

:Port_Test		lda	V410d3
			jsr	SetDevice
			jsr	InitForIO

			bit	V410d2
			bpl	:101
			jmp	IEC_Test
::101			jmp	UP_Test

:Port_Out		bit	V410d2
			bpl	:101
			jmp	CIOUT
::101			jmp	UP_CIOUT

;*** Seitenvorschub ausgeben.
:Do_PageBreak		jsr	Port_Init		;Drucker aktivieren.
			lda	#PAGE_BREAK
			jsr	Port_Out		;FF-Code ausgeben.
			jmp	Port_End		;Drucker deaktivieren.

;*** Sekundäradresse für "Schreiben auf Drucker"
;    auf IEC-Bus senden.
:IEC_Init		ldx	#$00			;Fehlerflag löschen.
			stx	$90
			lda	V410d3
			jsr	LISTEN			;Drucker auf "LISTEN".
			lda	V410d4
			and	#$0f
			ora	#$60
			jsr	SECOND			;Sekundäradresse senden.
			ldx	$90
			rts

;*** Druckersignal "UNLISTEN" auf IEC-Bus senden.
:IEC_End		ldx	#$00			;Fehlerflag löschen.
			stx	$90
			lda	V410d3
			jsr	LISTEN			;Drucker auf "LISTEN".
			lda	V410d4
			and	#$0f
			ora	#$e0
			jsr	SECOND			;Sekundäradresse senden.
			jsr	UNLSN			;Drucker auf "UNLISTEN".
			ldx	$90
			jmp	DoneWithIO

;*** Sekundäradresse auf IEC-Bus senden
;    um zu testen ob Drucker angeschlossen ist.
:IEC_Test		ldx	#$00			;Fehlerflag löschen.
			stx	$90
			lda	V410d3
			jsr	LISTEN			;Drucker auf "LISTEN".
			lda	V410d4
			and	#$0f
			ora	#$f0
			jsr	SECOND			;Sekundäradresse senden.
			jsr	UNLSN			;Drucker auf "UNLISTEN".
			ldx	$90
			jmp	DoneWithIO

;*** User-Port testen.
:UP_Test		lda	$dd00
			and	#$03
			ora	#$c4
			sta	$dd00
			lda	#$3f
			sta	$dd02
			ldy	#$ff
			sty	$dd03
			lda	$dd0d
			iny
			sty	$dd01
			lda	$dd00
			and	#$03
			sta	$dd00
			ora	#$04
			sta	$dd00
::101			dex
			bne	:101
			lda	$dd0d
			and	#$10
			bne	:102
			iny
			bne	:101
			ldx	#$80
::102			jmp	DoneWithIO

;*** User-Port aktivieren.
:UP_Init		ldx	#$00
			rts

;*** User-Port deaktivieren.
:UP_End			ldx	#$00
			jmp	DoneWithIO

;*** Byte-Ausgabe auf User-Port.
:UP_CIOUT		sta	$dd01
			lda	$dd00
			and	#$03
			sta	$dd00
			ora	#$04
			sta	$dd00
::101			lda	$dd0d
			and	#$10
			beq	:101
			rts

;*** Name der Hiledatei.
:HelpFileName		b "07,GDH_CBM/Datei",NULL

;*** Variablen.
:InputBuf		s $04
:curSubMenu		b $00

:InputData		b 1,10,100

:MenuText		w V410m0, V410m1, V410m2
:InfoText		w V410c0, V410c1, V410c2

:V410a0			b $28,$2f
			w $0008,$0047
			b $28,$2f
			w $0050,$0097
			b $28,$2f
			w $00a0,$00ef

if Sprache = Deutsch
:V410c0			b PLAINTEXT,"Druckeranschluß einrichten",NULL
:V410c1			b PLAINTEXT,"Druckoptionen",NULL
:V410c2			b PLAINTEXT,"Textformat wählen",NULL
:V410c3			b PLAINTEXT,"Dateien drucken", NULL
endif

if Sprache = Englisch
:V410c0			b PLAINTEXT,"Configure printer",NULL
:V410c1			b PLAINTEXT,"Options",NULL
:V410c2			b PLAINTEXT,"Select textformat",NULL
:V410c3			b PLAINTEXT,"Print files", NULL
endif

:V410d1			b $00				;$00 = 1:1 Übertragung.
							;$FF = Übersetzungstabelle.
:V410d2			b $00				;$00 = USER-Port.
							;$FF = ser. Bus.
:V410d3			b $04				;Geräte-Adresse.
:V410d4			b $01				;Sekundär-Adresse.
:V410d5			b $ff				;FF-Code am Ende einer Datei.
:V410d6			b $00				;LF-Code ignorieren.
:V410d7			b $00				;$00 = Standard-Texte.
							;$FF = GW-Texte.
:V410d9			b $00				;Anzahl Byte überlesen.

:V410f1			w $0000
:V410f2			w $0000

if Sprache = Deutsch
:V410g0			s 17
:V410g1			b "1:1 Übertragung ",NULL,NULL

:V410h2			b $0d,"        *** GRAFIK ***",$0d,NULL
endif

if Sprache = Englisch
:V410g0			s 17
:V410g1			b "Translate 1:1   ",NULL,NULL

:V410h2			b $0d,"        *** GRAPHICS ***",$0d,NULL
endif

if Sprache = Deutsch
;*** Fehler: "Drucker nicht aktiv!"
:V410j0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Der Drucker ist nicht",NULL
::102			b        "ansprechbar !",NULL

:V410j1			w :101, :102, ISet_Achtung
::101			b BOLDON,"Keine Übersetzungstabellen",NULL
::102			b        "auf der Systemdiskette!",NULL

;*** Infotexte.
:V410k0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Datei wird gedruckt..."
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b NULL
endif

if Sprache = Englisch
;*** Fehler: "Drucker nicht aktiv!"
:V410j0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Printer is not",NULL
::102			b        "available !",NULL

:V410j1			w :101, :102, ISet_Achtung
::101			b BOLDON,"No translation-modes",NULL
::102			b        "found on disk!",NULL

;*** Infotexte.
:V410k0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Printing file..."
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b NULL
endif

;*** Menügrafik.
if Sprache = Deutsch
:V410l1			b MOVEPENTO
			w $0000
			b $30
			b FRAME_RECTO
			w $013f
			b $b8
			b FRAME_RECTO
			w $0000
			b $c7

			b ESC_PUTSTRING
			w $000c
			b $2e
			b PLAINTEXT
			b "Drucker"

			b GOTOX
			w $0054
			b "Optionen"

			b GOTOX
			w $00a4
			b "Textformat"
			b NULL
endif

if Sprache = Englisch
:V410l1			b MOVEPENTO
			w $0000
			b $30
			b FRAME_RECTO
			w $013f
			b $b8
			b FRAME_RECTO
			w $0000
			b $c7

			b ESC_PUTSTRING
			w $000c
			b $2e
			b PLAINTEXT
			b "Printer"

			b GOTOX
			w $0054
			b "Options"

			b GOTOX
			w $00a4
			b "Textformat"
			b NULL
endif

;*** Menütexte.
if Sprache = Deutsch
:V410m0			b PLAINTEXT
			b GOTOXY
			w $0028
			b $4e
			b "Druckeranschluß am USER-Port"

			b GOTOXY
			w $0028
			b $6e
			b "Druckeranschluß am seriellen Bus"

			b GOTOXY
			w $0048
			b $7e
			b "Geräteadresse"

			b GOTOXY
			w $0048
			b $8e
			b "Sekundäradresse"

			b NULL

:V410m1			b PLAINTEXT
			b GOTOXY
			w $0028
			b $46
			b "Ausdruck 1:1"

			b GOTOXY
			w $0028
			b $56
			b "Übersetzungstabelle verwenden"

			b GOTOXY
			w $0028
			b $66
			b "Tabelle:"

			b GOTOXY
			w $0028
			b $7e
			b "Papiervorschub am Ende jeder Datei"

			b GOTOXY
			w $0028
			b $8e
			b "Zeilenvorschub einfügen"

			b GOTOXY
			w $0028
			b $9e
			b "Zeilenvorschub ignorieren"

			b NULL

:V410m2			b PLAINTEXT
			b GOTOXY
			w $0028
			b $4e
			b "Standard-Dateien drucken"
			b GOTOXY
			w $0028
			b $58
			b "z.B. ASCII-Textdateien oder"
			b GOTOXY
			w $0028
			b $62
			b "Dateien mit reinen Druckdaten."

			b GOTOXY
			w $0028
			b $86
			b "GeoWrite-Dokumente drucken"
			b GOTOXY
			w $0028
			b $90
			b "(ohne Formatierung und Tabulatoren,"
			b GOTOXY
			w $0028
			b $9a
			b "keine Grafik-Ausgabe)"

			b NULL
endif

;*** Menütexte.
if Sprache = Englisch
:V410m0			b PLAINTEXT
			b GOTOXY
			w $0028
			b $4e
			b "Printer connected to USER-port"

			b GOTOXY
			w $0028
			b $6e
			b "Printer connected to ser. bus"

			b GOTOXY
			w $0048
			b $7e
			b "Device-addr."

			b GOTOXY
			w $0048
			b $8e
			b "Secondary addr."

			b NULL

:V410m1			b PLAINTEXT
			b GOTOXY
			w $0028
			b $46
			b "Print 1:1"

			b GOTOXY
			w $0028
			b $56
			b "Use translation-mode"

			b GOTOXY
			w $0028
			b $66
			b "Mode   :"

			b GOTOXY
			w $0028
			b $7e
			b "Formfeed at the end of each file"

			b GOTOXY
			w $0028
			b $8e
			b "Insert linefeed"

			b GOTOXY
			w $0028
			b $9e
			b "Ignore linefeed"

			b NULL

:V410m2			b PLAINTEXT
			b GOTOXY
			w $0028
			b $4e
			b "Print standard-textfiles"
			b GOTOXY
			w $0028
			b $58
			b "like ASCII-textfiles or"
			b GOTOXY
			w $0028
			b $62
			b "files with printing-codes."

			b GOTOXY
			w $0028
			b $86
			b "Print GeoWrite-documents"
			b GOTOXY
			w $0028
			b $90
			b "(without layout and"
			b GOTOXY
			w $0028
			b $9a
			b "graphics)"

			b NULL
endif

;*** Datenliste für "Klick-Positionen".
:V410n0			w V410n1, V410n2, V410n3

:V410n1			b $48,$4f
			w $0018,$001f,DefOpt1a,SetOpt1a
			b $68,$6f
			w $0018,$001f,DefOpt1b,SetOpt1b

			b $78,$7f
			w $0028,$003f,DefOpt1c,SetOpt1c
			b $88,$8f
			w $0028,$003f,DefOpt1d,SetOpt1d

			b NULL

:V410n2			b $40,$47
			w $0018,$001f,DefOpt2a,SetOpt2a
			b $50,$57
			w $0018,$001f,DefOpt2b,SetOpt2b
			b $60,$67
			w $0068,$00e7,DefOpt2c,SetOpt2c

			b $78,$7f
			w $0018,$001f,DefOpt2d,SetOpt2d
			b $88,$8f
			w $0018,$001f,DefOpt2e,SetOpt2e
			b $98,$9f
			w $0018,$001f,DefOpt2f,SetOpt2f

			b NULL

:V410n3			b $48,$4f
			w $0018,$001f,DefOpt3a,SetOpt3a

			b $80,$87
			w $0018,$001f,DefOpt3b,SetOpt3b

			b NULL

;*** Menütabellen für Zahlenausgabe.
:V410o0			w V410p0, V410p2

;*** Tabellen für Zahleneingabe.
:V410o1			w V410p1, V410p3

;*** Tag.
:V410p0			w $002a
			b $7e

:V410p1			w $002a
			b $78
			w GetDevAdr
			w HEXtoASCII,ASCIItoHEX
			w ChkDevAdr
			w SetDevAdr

;*** Monat.
:V410p2			w $002a
			b $8e

:V410p3			w $002a
			b $88
			w GetSekAdr
			w HEXtoASCII,ASCIItoHEX
			w ChkSekAdr
			w SetSekAdr

;*** Druckmenü-Icons.
:Icon_Tab1		b 2
			w $0000
			b $00

			w Icon_10
			b $00,$08,$05,$18
			w L410ExitGD

			w Icon_02
			b $05,$08,$05,$18
			w L410m0

;*** Icons.
:Icon_02
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
:Icon_10
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_10
<MISSING_IMAGE_DATA>
endif

:EndProgrammCode

;*** Speicher für Übersetzungstabelle.
:ConvTabBase		s 256
