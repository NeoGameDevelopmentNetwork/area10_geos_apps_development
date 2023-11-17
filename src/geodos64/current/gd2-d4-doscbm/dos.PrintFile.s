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
			t	"src.DOSDRIVE.ext"
endif

			n	"mod.#310.obj"
			o	ModStart
			q	EndProgrammCode
			r	EndAreaDOS

			jmp	DOS_PrnFile

			t	"-GetConvTab1"
			t	"-GetConvTab2"
			t	"-DOS_SlctFiles"

;*** DOS-Datei drucken.
:DOS_PrnFile
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
:L310ExitGD		jsr	ClrScreen
			jmp	InitScreen

;*** Dateien wählen.
:L310a0			NoMseKey

			jsr	ClrScreen		;Fenster löschen.

			lda	V310g0
			ldx	#<ConvTabBase
			ldy	#>ConvTabBase
			jsr	LoadConvTab

			lda	Target_Drv
			jsr	NewDrive

			LoadW	r14,V310b0
			jsr	SlctFiles		;DOS-Dateien auswählen.
			cmp	#$00
			beq	:101
			jmp	L310ExitGD		;Zurück zu GeoDOS.

::101			lda	curDrive
			sta	Target_Drv

;******************************************************************************

			jsr	Port_Test		;Drucker testen.
			txa
			beq	:102
			DB_OK	V310j0			;Fehler: "Drucker nicht bereit!".
			jmp	DOS_PrnFile

::102			LoadW	a5,FileNTab		;Zeiger auf Anfang Datei-Tabelle.
			jsr	DoInfoBox
			PrintStrgV310k0

;*** Ausgewählte Dateien drucken.
:L310b0			lda	Target_Drv
			jsr	NewDrive
			MoveW	a5,r10			;Zeiger auf nächste DOS-Datei.
			jsr	LookDOSfile		;DOS-Datei-Eintrag suchen.
			tay
			bne	L310b1
			jmp	L310c0			;Gefunden ? Ja, drucken.

;*** Zeiger auf nächste Datei.
:L310b1			AddVBW	16,a5			;Zeiger auf nächste Datei.
			ldy	#$00			;Ende der Tabelle erreicht ?
			lda	(a5L),y
			bne	L310b0			;Nein, weiter...
:L310b2			jsr	ClrBox
			jmp	L310ExitGD		;Zurück zu GeoDOS.

;*** Ausdruck der aktuellen Datei beenden.
:L310b3			lda	V310d5			;FF-Code ausgeben ?
			beq	:101			;Nein, weiter...
			jsr	Do_PageBreak
::101			jmp	L310b1			;Weiter mit nächster Datei.

;*** Ausdruck abbrechen.
:L310b4			jsr	Do_PageBreak
			jmp	L310b2			;Weiter mit nächster Datei.

;*** Nächste Datei drucken.
:L310c0			jsr	ClrBoxText		;Infobox.
			PrintStrgV310k0

			ClrB	pressFlag

			jsr	PrnFileName

			jsr	L310d0
			txa
			beq	:101
			jmp	L310b3			;Weiter mit nächster Datei.
::101			jmp	L310b4

;*** Einzelne DOS-datei drucken.
:L310d0			MoveB	SpClu,V310e0		;Zähler "Sek./Cluster" initialisieren.

			ldx	#$05
			ldy	#$1f
::101			lda	(a8L),y			;Startcluster und Dateilänge
			sta	V310e1,x		;in Zwischenspeicher kopieren.
			dey
			dex
			bpl	:101

			lda	V310e1+0
			ldx	V310e1+1
			jsr	L310f1			;Ersten Cluster einlesen.

			jsr	L310e1			;Datei-Länge -1.
			bcc	L310d3			;Länge = 0 ? Ja, nächste Datei.

:L310d1			jsr	Port_Init		;Drucker aktivieren.

			jsr	L310e0			;Daten drucken.
			bne	L310d3
			inc	a8H
			jsr	L310e0
			bne	L310d3

			ldx	pressFlag
			beq	L310d2
			rts

:L310d2			jsr	Port_End		;Drucker deaktivieren.

			lda	Target_Drv		;Laufwerk aktivieren.
			jsr	NewDrive
			jsr	L310f0			;Nächsten Cluster lesen.
			tax				;Datei-Ende erreicht ?
			beq	L310d1			;Nein, weiter...
			ldx	#$00
			rts

:L310d3			jsr	Port_End		;Drucker deaktivieren.
			ldx	#$00
			rts

;*** 256 Datenbytes drucken.
:L310e0			ldy	#$00
::101			lda	(a8L),y			;Byte aus Puffer lesen.

			cmp	#LF
			bne	:903b
			ldx	V310d6
			beq	:102b
			bne	:103

::903b			cmp	#CR			;CR-Code ?
			bne	:102			;Nein, weiter...
			ldx	V310d6			;LF-Code anhängen ?
			beq	:102b			;Nein, weiter...
			jsr	Port_Out		;CR-Code ausgeben.
			bit	V310d6			;LF-Code anhängen ?
			bpl	:103
			lda	#LF			;LF-Code ausgeben.
			bne	:102b

::102			tax				;Code umwandeln.
			lda	ConvTabBase,x
::102b			jsr	Port_Out		;Zeichen ausgeben.
::103			jsr	L310e1			;DOS-Dateilänge -1.
			bcc	:104			;Ende erreicht, Rücksprung.
			iny				;Alle Zeichen aus Puffer gedruckt ?
			bne	:101			;Nein, nächstes Zeichen.
::104			rts				;Rücksprung.

;*** DOS-Dateilänge -1.
:L310e1			sec				;DOS-Dateilänge -1.
			lda	V310e2+0		;(Länge = Double Word!)
			sbc	#$01
			sta	V310e2+0
			lda	V310e2+1
			sbc	#$00
			sta	V310e2+1
			lda	V310e2+2
			sbc	#$00
			sta	V310e2+2
			lda	V310e2+3
			sbc	#$00
			sta	V310e2+3
			rts

;*** Nächsten Sektor eines Clusters lesen.
:L310f0			dec	V310e0			;Alle Sektoren eines
			beq	:101			;Clusters gelesen ?
			jsr	Inc_Sek			;Nächsten Sektor im
			jmp	L310f2			;Cluster lesen.

::101			lda	V310e1+0		;Nächsten Cluster
			ldx	V310e1+1		;lesen.
			jsr	Get_Clu
			lda	r1L			;Neue Cluster-Nr.
			ldx	r1H			;merken.
			sta	V310e1+0
			stx	V310e1+1

;*** Nächsten Cluster einlesen.
:L310f1			cmp	#$f8			;FAT12. Dir-Ende ?
			bcc	:101			;Nein, weiter...
			cpx	#$0f
			bcc	:101
			jmp	L310f3			;Dateiende erreicht.

::101			jsr	Clu_Sek			;Cluster berechnen.
			MoveB	SpClu,V310e0		;Zähler setzen.

;*** DOS-Sektor lesen.
:L310f2			LoadW	a8,Disk_Sek
			jsr	D_Read			;Ersten Sektor lesen.
			txa
			beq	:101
			jmp	DiskError		;Disketten-Fehler.
::101			rts

;*** Datei-Ende erreicht.
:L310f3			lda	#$ff
			rts				;Rücksprung, Z-Flag = 0.

;*** Dateinamen ausgeben.
:PrnFileName		lda	#$22			;Anführungszeichen ausgeben.
			jsr	SmallPutChar

			lda	#$00			;Dateiname ausgeben.
::101			pha
			tay
			lda	(a5L),y
			beq	:104
			jsr	ConvertChar
			jsr	SmallPutChar
::102			pla
			add	1
::103			cmp	#12
			bne	:101
			pha
::104			pla

			lda	#$22			;Anführungszeichen ausgeben.
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
			b	PLAINTEXT,"PCDOS  -  Druckerausgabe",NULL
endif
if Sprache = Englisch
			b	PLAINTEXT,"PCDOS  -  Print files",NULL
endif

			LoadW	r0,V310l0
			jsr	GraphicsString

			jsr	i_C_Register
			b	$01,$05,$08,$01
			jsr	i_C_Register
			b	$0a,$05,$09,$01

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
			lda	V310n0+0,x
			sta	a7L
			lda	V310n0+1,x
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

			jmp	:120

::102			lda	#$00
			b $2c
::103			lda	#$01
			b $2c
::104			lda	#$02
			cmp	curSubMenu
			beq	:105
			sta	curSubMenu
			jmp	SetPrnOpt2		;Nein, weitertesten.
::105			jmp	SetPrnOpt3		;Nein, weitertesten.

::110			clc
			adc	#<V310a0
			sta	a7L
			lda	#$00
			adc	#>V310a0
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

;*** Farbe auf Bildschirm.
:SetColOpt		jsr	i_ColorBox		;Farbe setzen.
			b	$00,$00,$00,$01,$01
			rts

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

;*** Druckerport anzeigen.
:DefOpt1a		lda	#$00
			b $2c
:DefOpt1b		lda	#$ff
			cmp	V310d2
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
			sta	V310d2
			rts

;*** Druckeradresse ändern.
:SetOpt1c		lda	#$00			;Tag eingeben.
			b $2c
:SetOpt1d		lda	#$01			;Monat eingeben.
			asl
			tax
			lda	V310o1+0,x
			sta	a7L
			lda	V310o1+1,x
			sta	a7H
			jmp	InpOptNum

;*** Übersetzungs-Modus anzeigen.
:DefOpt2a		lda	#$00
			b $2c
:DefOpt2b		lda	#$ff
			cmp	V310d1
			bne	:101
			ldy	#$02
::101			rts

;*** Übersetzungstabelle anzeigen.
:DefOpt2c		lda	#<V310g0+1
			ldx	#>V310g0+1
			ldy	V310g0
			bne	:101
			lda	#<V310g1
			ldx	#>V310g1
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
:DefOpt2d		bit	V310d5
			bpl	:101
			ldy	#$02
::101			rts

;*** LineFeed einfügen.
;DOS: $00 = Linefeed unverändert.
;     $80 = LineFeed einfügen.
:DefOpt2e		bit	V310d6
			bpl	:101
			ldy	#$02
::101			rts

;*** LineFeed einfügen.
;DOS: $00 = Linefeed unverändert.
;     $40 = LineFeed ignorieren.
:DefOpt2f		bit	V310d6
			bvc	:101
			ldy	#$02
::101			rts

;*** Übersetzungs-Modus anzeigen.
:SetOpt2a		lda	#$00
			b $2c
:SetOpt2b		lda	#$ff
			sta	V310d1
			rts

;*** Übersetzungstabelle anzeigen.
:SetOpt2c		jsr	SetOpt2b
			jmp	SlctCTabDOS

;*** Seitenvorschub am Ende jeder Datei.
:SetOpt2d		lda	V310d5
			eor	#%11111111
			sta	V310d5
			rts

;*** LineFeed-Modus ändern.
:SetOpt2e		ldx	#$80
			lda	V310d6
			beq	:101
			cmp	#$40
			beq	:101
			ldx	#$00
::101			stx	V310d6
			rts

;*** LineFeed-Modus ändern.
:SetOpt2f		ldx	#$40
			lda	V310d6
			beq	:101
			cmp	#$80
			beq	:101
			ldx	#$00
::101			stx	V310d6
			rts

;*** Geräteadresse einlesen.
:GetDevAdr		lda	V310d3
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
			sta	V310d3
			rts

;*** Sekundäradresse einlesen.
:GetSekAdr		lda	V310d4
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
			sta	V310d4
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
			lda	V310o0+0,x
			sta	a6L
			lda	V310o0+1,x
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
:InpOptNum		PopW	V310f1			;Rücksprung-Adresse merken.

			lda	mouseOn			;Menüs & Icons aus.
			and	#%10011111
			sta	mouseOn
			ClrW	otherPressVec
			MoveW	a7,V310f2		;Zeiger auf Menütabelle merken.

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
::101			MoveW	V310f2,a7		;Zeiger auf Menütabelle zurücksetzen.

			ldy	#$08			;Eingabe nach HEX wandeln.
			jsr	CallNumRout

			ldy	#$0a			;Zahlenwert prüfen.
			jsr	CallNumRout
			bcc	:102			;Wert in Ordnung ? Ja, weiter.
			jsr	SetClkPos		;Alte Werte ausgeben.
			MoveW	V310f2,a7		;Zahl erneut eingeben.
			jmp	InpNOptNum

::102			ldy	#$0c			;Eingabe übernehmen.
			jsr	CallNumRout

			lda	mouseOn			;Icons aktivieren.
			ora	#%00100000
			sta	mouseOn
			LoadW	otherPressVec,ChkOptSlct

			jsr	SetHelp

			PushW	V310f1			;Rücksprung-Adresse wieder herstellen.
			rts

;*** Konvertierungstabelle DOS laden.
:SlctCTabDOS		jsr	ClrScreen
			jsr	LoadConvIndex
			txa
			bne	NoCTab

			jsr	GetCTabDOS
			txa
			bne	GotoMenu

			lda	r10L
			sta	V310g0
			lda	#<V310g0 +1
			ldx	#>V310g0 +1

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

::101			DB_OK	V310j1
			jmp	SetPrnOpt1		;Zurück zum Druck-Modus.

;*** Einsprungadressen und Verzweigung zu den
;    entsprechenden Port-Routinen.
:Port_Init		lda	V310d3
			jsr	SetDevice
			jsr	InitForIO

			bit	V310d2
			bpl	:101
			jmp	IEC_Init
::101			jmp	UP_Init

:Port_End		bit	V310d2
			bpl	:101
			jmp	IEC_End
::101			jmp	UP_End

:Port_Test		lda	V310d3
			jsr	SetDevice
			jsr	InitForIO

			bit	V310d2
			bpl	:101
			jmp	IEC_Test
::101			jmp	UP_Test

:Port_Out		bit	V310d2
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
			lda	V310d3
			jsr	LISTEN			;Drucker auf "LISTEN".
			lda	V310d4
			and	#$0f
			ora	#$60
			jsr	SECOND			;Sekundäradresse senden.
			ldx	$90
			rts

;*** Druckersignal "UNLISTEN" auf IEC-Bus senden.
:IEC_End		ldx	#$00			;Fehlerflag löschen.
			stx	$90
			lda	V310d3
			jsr	LISTEN			;Drucker auf "LISTEN".
			lda	V310d4
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
			lda	V310d3
			jsr	LISTEN			;Drucker auf "LISTEN".
			lda	V310d4
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

;*** Variablen.
:HelpFileName		b "06,GDH_DOS/Datei",NULL

:InputBuf		s $04
:curSubMenu		b $00

:InputData		b 1,10,100

:MenuText		w V310m0, V310m1
:InfoText		w V310c0, V310c1

:V310a0			b $28,$2f
			w $0008,$0047
			b $28,$2f
			w $0050,$0097

if Sprache = Deutsch
:V310b0			b PLAINTEXT,"Dateien drucken",NULL

:V310c0			b "Druckeranschluß einrichten",NULL
:V310c1			b "Druckoptionen",NULL
endif

if Sprache = Englisch
:V310b0			b PLAINTEXT,"Print files",NULL

:V310c0			b "Configure printer",NULL
:V310c1			b "Options",NULL
endif

:V310d1			b $00				;$00 = 1:1 Übertragung.
							;$FF = Übersetzungstabelle.
:V310d2			b $00				;$00 = USER-Port.
							;$FF = ser. Bus.
:V310d3			b $04				;Geräte-Adresse.
:V310d4			b $01				;Sekundär-Adresse.
:V310d5			b $ff				;FF-Code am Ende einer Datei.
:V310d6			b $00				;LF-Code ignorieren.

:V310e0			b $00				;Anzahl Sektoren pro Cluster.
:V310e1			w $0000				;Aktueller Cluster.
:V310e2			s $04				;DOS-Dateilänge.

:V310f1			w $0000
:V310f2			w $0000

:V310g0			s 17
:V310g1			b "Translate 1:1   "

;*** Fehler: "Drucker nicht aktiv!"
:V310j0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Printer is not",NULL
::102			b        "available !",NULL

:V310j1			w :101, :102, ISet_Achtung
::101			b BOLDON,"No translation-file",NULL
::102			b        "on systemdisk!",NULL

;*** Infotexte.
:V310k0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Printing file..."
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b NULL

if Sprache = Deutsch
;*** Menügrafik
:V310l0			b MOVEPENTO
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

			b NULL

;*** Menütexte.
:V310m0			b PLAINTEXT
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

:V310m1			b PLAINTEXT
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
endif

if Sprache = Englisch
;*** Menügrafik
:V310l0			b MOVEPENTO
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

			b NULL

;*** Menütexte.
:V310m0			b PLAINTEXT
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
			b "Device-adress"

			b GOTOXY
			w $0048
			b $8e
			b "secondary-adress"

			b NULL

:V310m1			b PLAINTEXT
			b GOTOXY
			w $0028
			b $46
			b "Print 1:1"

			b GOTOXY
			w $0028
			b $56
			b "Use translation-file"

			b GOTOXY
			w $0028
			b $66
			b "File:"

			b GOTOXY
			w $0028
			b $7e
			b "New page at end of file"

			b GOTOXY
			w $0028
			b $8e
			b "Insert linefeed"

			b GOTOXY
			w $0028
			b $9e
			b "Ignore linefeed"

			b NULL
endif

;*** Datenliste für "Klick-Positionen".
:V310n0			w V310n1, V310n2

:V310n1			b $48,$4f
			w $0018,$001f,DefOpt1a,SetOpt1a
			b $68,$6f
			w $0018,$001f,DefOpt1b,SetOpt1b

			b $78,$7f
			w $0028,$003f,DefOpt1c,SetOpt1c
			b $88,$8f
			w $0028,$003f,DefOpt1d,SetOpt1d

			b NULL

:V310n2			b $40,$47
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

;*** Menütabellen für Zahlenausgabe.
:V310o0			w V310p0, V310p2

;*** Tabellen für Zahleneingabe.
:V310o1			w V310p1, V310p3

;*** Geräteadresse.
:V310p0			w $002a
			b $7e

:V310p1			w $002a
			b $78
			w GetDevAdr
			w HEXtoASCII,ASCIItoHEX
			w ChkDevAdr
			w SetDevAdr

;*** Sekundäradresse.
:V310p2			w $002a
			b $8e

:V310p3			w $002a
			b $88
			w GetSekAdr
			w HEXtoASCII,ASCIItoHEX
			w ChkSekAdr
			w SetSekAdr

;*** Druckmenü-Icons.
:Icon_Tab1		b 2
			w $0000
			b $00

			w Icon_02
			b $00,$08,$05,$18
			w L310ExitGD

			w Icon_01
			b $05,$08,$05,$18
			w L310a0

;*** Icons.
:Icon_01
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
:Icon_02
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_02
<MISSING_IMAGE_DATA>
endif

:EndProgrammCode

;*** Speicher für Übersetzungstabelle.
:ConvTabBase		s 256
