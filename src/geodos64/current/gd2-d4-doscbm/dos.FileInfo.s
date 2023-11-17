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

			n	"mod.#304.obj"
			o	ModStart
			q	EndProgrammCode
			r	EndAreaDOS

			jmp	DOS_FileInfo

			t	"-DOS_SlctFiles"

;*** Datei-Attribute ändern.
:DOS_FileInfo		lda	Target_Drv
			jsr	NewDrive

			LoadW	r14,V304c0		;Titeltext.
			jsr	SlctFiles		;Dateien einlesen.
			tax
			beq	:101
			jmp	L304ExitGD		;Zurück zu GeoDOS.

::101			jsr	SetHelp

			LoadW	a5,FileNTab		;Zeiger auf Tabelle.

:StartEdit		lda	#$00
			sta	WinOpen
			sta	MenuOpen
			sta	curSubMenu

;*** Infos der aktuellen Datei anzeigen.
:StartEdit_a		MoveW	a5,r10			;Aktuelle Datei suchen.
			jsr	LookDOSfile
			tay				;Datei gefunden ?
			bne	NextEdit		;Ja, weiter...
			jsr	Bildschirm_a
			jmp	InitFileData		;Datei-Attribute ändern.

:NextEdit		ldy	#$10
			lda	(a5L),y			;Dateiende erreicht ?
			beq	StartEdit_a		;Nein, weiter...
			AddVBW	16,a5			;Zeiger auf nächste Datei.
			jmp	StartEdit_a		;Optionen ändern.

:LastEdit		CmpWI	a5,FileNTab
			beq	StartEdit_a
			SubVW	16,a5			;Zeiger auf letzte Datei.
			jmp	StartEdit_a		;Optionen ändern.

:Edit_OK		LoadW	a8,Disk_Sek		;Zeiger auf DOS-Verzeichnis-Sektor.
			jsr	D_Write			;Sektor auf Disk zurückschreiben.
			txa				;Fehler ?
			bne	ExitDskErr		;Nein, weiter...
:Edit_Cancel		jmp	NextEdit		;Nächste Datei.
:ExitDskErr		jmp	DiskError		;Diskettenfehler.

;*** Zurück zu GeoDOS.
:EndEdit		jsr	ClrWin			;Fenster löschen.
:L304ExitGD		jmp	InitScreen		;GeoDOS-Menü.

;*** Neues Laufwerk.
:ChangeDrive		jsr	ClrWin
			jmp	vD_FileInfo

;*** NeueDiskette.
:ChangeDisk		jsr	ClrWin
			ldx	#$ff
			lda	curDrive
			jsr	InsertDisk
			cmp	#$01
			beq	ChangeFiles1
			jmp	L304ExitGD

;*** Neue Dateien.
:ChangeFiles		jsr	ClrWin
:ChangeFiles1		jmp	DOS_FileInfo

;*** Zeiger auf Hilfedatei bereitstellen.
:SetHelp		LoadW	r0,HelpFileName
			lda	#<StartEdit
			ldx	#>StartEdit
			jmp	InstallHelp

;*** Fenster aufbauen.
:Bildschirm_a		bit	WinOpen			;Menü bereits aufgebaut ?
			bpl	:101			;Nein, weiter...
			rts				;Ja, Ende.

::101			jsr	ClrScreen		;Bildschirm löschen.

			jsr	i_C_MenuTitel
			b	$00,$00,$28,$01
			jsr	i_C_MenuBack
			b	$00,$01,$28,$18

			FillPRec$00,$00,$07,$0008,$013f

			jsr	UseGDFont
			Print	$0008,$06
if Sprache = Deutsch
			b	PLAINTEXT,"PCDOS  -  Datei-Eigenschaften",NULL
endif
if Sprache = Englisch
			b	PLAINTEXT,"PCDOS  -  File-attributes",NULL
endif

			LoadW	r0,V304e0		;Menü zeichnen.
			jsr	GraphicsString

			jsr	i_C_Register
			b	$01,$05,$0a,$01
			jsr	i_C_Register
			b	$0c,$05,$0a,$01
			jsr	i_C_Register
			b	$17,$05,$0a,$01

			LoadB	Icon_Tab1,6		;Icon-Tabelle definieren.
			LoadB	r14H,$1e
			LoadW	r15,Icon_Tab1a

			CmpBI	DOS_Count,1
			beq	:102
			ldx	#$00
			jsr	Copy1Icon

::102			ldx	#$08
			jsr	Copy1Icon

			lda	r14H
			sta	:103 +2
			jsr	i_C_MenuMIcon
::103			b	$00,$01,$ff,$03

			dec	WinOpen
			rts

;*** Icon in Icon-Zeile übernehmen.
:Copy1Icon		ldy	#$00
::101			lda	Icon_Tab1b  ,x
			sta	(r15L),y
			inx
			iny
			cpy	#$08
			bne	:101

			ldy	#$02
			lda	r14H
			sta	(r15L),y

			AddVB	5,r14H
			AddVBW	8,r15
			inc	Icon_Tab1
			rts

;*** Fenster wieder löschen.
:ClrWin			lda	#$00
			sta	WinOpen
			sta	MenuOpen
			sta	otherPressVec+0
			sta	otherPressVec+1
			jmp	ClrScreen

;*** Dateiinfos anzeigen.
:InitFileData		bit	MenuOpen
			bpl	NewFileData
			jsr	SetClkPos
			jmp	EditFileData

;*** Dateiinfo-Menü neu initialisieren.
:NewFileData		jsr	InitMenuPage		;Menüseite initialisieren.

:EditFileData		LoadW	otherPressVec,ChkOptSlct
			LoadW	r0,Icon_Tab1
			jsr	DoIcons			;Menü aktivieren.
			StartMouse
			NoMseKey
			rts

;*** Menüseite initialisieren.
:InitMenuPage		LoadB	MenuOpen,$ff

			jsr	i_C_MenuBack		;Menüfenster löschen.
			b	$00,$06,$28,$13
			FillPRec$00,$31,$b6,$0001,$013e

			jsr	UseGDFont		;Dateiname ausgeben.
			Print	$0018,$46
if Sprache = Deutsch
			b	PLAINTEXT,"Dateiname :"
endif
if Sprache = Englisch
			b	PLAINTEXT,"Filename  :"
endif
			b	NULL

			lda	curSubMenu		;Menütext ausgeben.
			asl
			tax
			lda	MenuText+0,x
			sta	r0L
			lda	MenuText+1,x
			sta	r0H
			jsr	PutString

			jmp	SetClkPos		;Optionen auf Bildschirm.

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
			lda	V304f0+0,x
			sta	a7L
			lda	V304f0+1,x
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

;*** Option-Feld initialisieren.
:InitOptField		jsr	CopyRecData		;Daten für Rechteck einlesen.

			Pattern	0
			jsr	Rectangle

			ClrB	currentMode
			jmp	UseGDFont

;*** Farbe für Klick-Option definieren.
:DefClkOpt		jsr	CopyRecData		;Daten für Rechteck einlesen.
			jsr	DefColOpt
			jsr	SetColOpt
			ldy	#$ff
			rts

;*** Prüfen ob Option angeklickt.
:ChkOptSlct		lda	#$00			;Option "Datum & Uhrzeit" angeklickt ?
			jsr	:110
			bne	:101

			lda	#$06			;Option "Attribute" angeklickt ?
			jsr	:110
			bne	:102

			lda	#$0c			;Option "Statistik" angeklickt ?
			jsr	:110
			bne	:103

			jmp	:120			;Menüoption angeklickt.

::101			lda	#$00
			b $2c
::102			lda	#$01
			b $2c
::103			lda	#$02
			cmp	curSubMenu
			beq	:104
			sta	curSubMenu
			jmp	NewFileData		;Nein, weitertesten.
::104			rts

;*** Mausbereich abfragen.
::110			clc
			adc	#<V304a0
			sta	a7L
			lda	#$00
			adc	#>V304a0
			sta	a7H

			jsr	CopyRecData		;Werte aus Menütabelle nach ":r2".
			jmp	IsMseInRegion		;Ist Maus innerhalb eines Options-

;*** Optionsfeld angeklickt.
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

;*** Datum & Uhrzeit ausgeben.
:DefOpt1a		jsr	GetDay			;Tag ausgeben,
			ldy	#$00
			jmp	PutNumOnScrn

:DefOpt1b		jsr	GetMonth		;Monat ausgeben.
			ldy	#$01
			jmp	PutNumOnScrn

:DefOpt1c		jsr	GetYear			;Jahr ausgeben.
			ldy	#$02
			jmp	PutNumOnScrn

:DefOpt2a		jsr	GetHour			;Stunde ausgeben.
			ldy	#$03
			jmp	PutNumOnScrn

:DefOpt2b		jsr	GetMinute		;Minute ausgeben.
			ldy	#$04
			jmp	PutNumOnScrn

:DefOpt2c		jsr	GetSecond		;Sekunde ausgeben.
			ldy	#$05
			jmp	PutNumOnScrn

;*** Datum & Uhrzeit ändern.
:SetOpt1a		lda	#$00			;Tag eingeben.
			b $2c
:SetOpt1b		lda	#$01			;Monat eingeben.
			b $2c
:SetOpt1c		lda	#$02			;Jahr eingeben.
			b $2c
:SetOpt2a		lda	#$03			;Stunde eingeben.
			b $2c
:SetOpt2b		lda	#$04			;Minute eingeben.
			b $2c
:SetOpt2c		lda	#$05			;Sekunde eingeben,
			asl
			tax
			lda	V304g1+0,x
			sta	a7L
			lda	V304g1+1,x
			sta	a7H
			jmp	InpOptNum

;*** Attribute ausgeben.
:DefOpt3a		lda	#%00100000		;Archiv-Bit ausgeben.
			b $2c
:DefOpt3b		lda	#%00000100		;System-Bit ausgeben.
			b $2c
:DefOpt3c		lda	#%00000010		;Hidden-Bit ausgeben.
			b $2c
:DefOpt3d		lda	#%00000001		;READ ONLY-Bit ausgeben.
			sta	:101 +1
			ldy	#$0b
			lda	(a8L),y
			ldy	#$00
::101			and	#%11111111
			beq	:102
			ldy	#$02
::102			rts

;*** Attribute ändern.
:SetOpt3a		lda	#%00100000		;Archiv-Bit ändern.
			b $2c
:SetOpt3b		lda	#%00000100		;System-Bit ändern.
			b $2c
:SetOpt3c		lda	#%00000010		;Hidden-Bit ändern.
			b $2c
:SetOpt3d		lda	#%00000001		;READ ONLY-Bit ändern.
			sta	:101 +1
			ldy	#$0b
			lda	(a8L),y
::101			eor	#%11111111
			sta	(a8L),y
			rts

;*** Dateigröße ausgeben.
:DefOpt4a		jsr	InitOptField

			LoadW	r11,$0084
			LoadB	r1H,$5e

			ldy	#$1e
			ldx	#$02
::101			lda	(a8L),y
			sta	r0L,x
			dey
			dex
			bpl	:101
			jsr	ZahlToASCII
			PrintStrgASCII_Zahl
			jmp	DefClkOpt

;*** Ersten Cluster ausgeben.
:DefOpt4b		jsr	InitOptField

			LoadW	r11,$0084
			LoadB	r1H,$6e

			ldy	#$1a
			lda	(a8L),y
			sta	r0L
			sta	r15L
			iny
			lda	(a8L),y
			sta	r0H
			sta	r15H
			SubVW	2,r0
			lda	#%11000000
			jsr	PutDecimal
			jmp	DefClkOpt

;*** Anzahl Cluster augeben.
:DefOpt4c		jsr	InitOptField

			ClrW	V304b3
			MoveW	r15,r1
::101			lda	r1H
			and	#%00001111
			tax
			lda	r1L
			cpx	#$0f
			bne	:102
			cmp	#$f8
			bcc	:102
			jmp	:103

::102			IncWord	V304b3
			jsr	Get_Clu
			jmp	:101

::103			LoadW	r11,$0084
			LoadB	r1H,$7e
			MoveW	V304b3,r0
			lda	#%11000000
			jsr	PutDecimal
			jmp	DefClkOpt

;*** Dateiname ausgeben.
:DefName		jsr	InitOptField

			LoadW	r11,$0082
			LoadB	r1H,$46

			ldy	#$00
::101			sty	:102 +1
			lda	(a5L),y
			beq	:103
			jsr	ConvertChar
			jsr	SmallPutChar
::102			ldy	#$ff
			iny
			cpy	#$0c
			bne	:101

::103			jmp	DefClkOpt

;*** Datum & Uhrzeit aus DOS einlesen..
:GetDay			jsr	ReadDT
			lda	r1L
			and	#%00011111
			ldx	#$00
			rts

:GetMonth		jsr	ReadDT
			ldx	#r1L
			ldy	#5
			jsr	DShiftRight
			lda	r1L
			and	#%00001111
			ldx	#$00
			rts

:GetYear		jsr	ReadDT
			ldx	#r1L
			ldy	#9
			jsr	DShiftRight
			lda	r1L
			add	80
::101			cmp	#100
			bcc	:102
			sub	100
			bne	:101
::102			ldx	#$00
			rts

:GetHour		jsr	ReadDT
			ldx	#r0L
			ldy	#11
			jsr	DShiftRight
			lda	r0L
			ldx	#$00
			rts

:GetMinute		jsr	ReadDT
			ldx	#r0L
			ldy	#5
			jsr	DShiftRight
			lda	r0L
			and	#%00111111
			ldx	#$00
			rts

:GetSecond		jsr	ReadDT
			lda	r0L
			and	#%00011111
			asl
			ldx	#$00
			rts

;*** Eingabewerte überprüfen.
:ChkDay			lda	#31			;Tag, 1-31.
			b $2c
:ChkMonth		lda	#12			;Monat, 1-12.
			ldy	r0L
			beq	ChkError
			bne	Check

:ChkYear		lda	#99			;Jahr, 0-99.
			b $2c
:ChkHour		lda	#23			;Stunde, 0-23.
			b $2c
:ChkMinute		lda	#59			;Minute, 0-59.
			b $2c
:ChkSecond		lda	#59			;Sekunde, 0-59.

:Check			ldx	r0H
			bne	ChkError
			cmp	r0L
			bcc	ChkError
			clc				;Wert OK!
			rts
:ChkError		sec				;Wert zu klein/zu groß.
			rts

;*** Datum & Uhrzeit nach ":r0" kopieren.
:ReadDT			ldy	#$19
			ldx	#$03
::101			lda	(a8L),y
			sta	r0L,x
			dey
			dex
			bpl	:101
			rts

;*** Datum & Uhrzeit nach ":a8" kopieren.
:WriteDT		ldy	#$19
			ldx	#$03
::101			lda	r0L,x
			sta	(a8L),y
			dey
			dex
			bpl	:101
			rts

;*** Datum eingeben.
:SetDay			lda	#%00011111
			ldx	#%00000000
			ldy	#$00
			jmp	SetDate

:SetMonth		lda	#%11100000
			ldx	#%00000001
			ldy	#$05
			jmp	SetDate

:SetYear		lda	r0L
			bne	:101
			lda	#100
::101			sub	80
			bcs	:102
			adc	#100
::102			sta	r0L
			lda	#%00000000
			ldx	#%11111110
			ldy	#$09

:SetDate		sta	r3L
			eor	#$ff
			sta	r4L
			txa
			sta	r3H
			eor	#$ff
			sta	r4H

			ldx	#r0L
			jsr	DShiftLeft

			lda	r0L
			and	r3L
			sta	r2L
			lda	r0H
			and	r3H
			sta	r2H

			jsr	ReadDT

			lda	r1L
			and	r4L
			ora	r2L
			sta	r1L
			lda	r1H
			and	r4H
			ora	r2H
			sta	r1H

			jmp	WriteDT

;*** Uhrzeit eingeben.
:SetSecond		lsr	r0L
			lda	#%00011111
			ldx	#%00000000
			ldy	#$00
			jmp	SetTime

:SetMinute		lda	#%11100000
			ldx	#%00000111
			ldy	#$05
			jmp	SetTime

:SetHour		lda	#%00000000
			ldx	#%11111000
			ldy	#$0b

:SetTime		sta	r3L
			eor	#$ff
			sta	r4L
			txa
			sta	r3H
			eor	#$ff
			sta	r4H

			ldx	#r0L
			jsr	DShiftLeft

			lda	r0L
			and	r3L
			sta	r2L
			lda	r0H
			and	r3H
			sta	r2H

			jsr	ReadDT

			lda	r0L
			and	r4L
			ora	r2L
			sta	r0L
			lda	r0H
			and	r4H
			ora	r2H
			sta	r0H

			jmp	WriteDT

;*** $HEX nach ASCII wandeln.
:HEXtoASCII		lda	r15L
			ldx	#$30
::101			cmp	#10
			bcc	:102
			inx
			sbc	#10
			bcs	:101
::102			adc	#$30
			stx	InputBuf+0
			sta	InputBuf+1
			ClrB	InputBuf+2
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
			lda	V304b2,y		;oder 100er addieren.
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
:PutNumOnScrn		sta	r15L			;Zahlenwert nach ":r0".
			jsr	HEXtoASCII
			tya				;Startadresse Menütabelle berechnen.
			asl
			tax
			lda	V304g0+0,x
			sta	a6L
			lda	V304g0+1,x
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

			lda	InputBuf+0
			jsr	SmallPutChar
			lda	InputBuf+1
			jsr	SmallPutChar
			ldy	#$ff
			rts

;*** Zahl Eingeben.
:InpOptNum		PopW	V304b0			;Rücksprung-Adresse merken.

			lda	mouseOn			;Menüs & Icons aus.
			and	#%10011111
			sta	mouseOn
			ClrW	otherPressVec
			MoveW	a7,V304b1		;Zeiger auf Menütabelle merken.

;*** Neue Zahl eingeben.
:InpNOptNum		jsr	UseGDFont

			ldy	#$04			;Zahlenwert einlesen.
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
::101			MoveW	V304b1,a7		;Zeiger auf Menütabelle zurücksetzen.

			ldy	#$08			;Eingabe nach HEX wandeln.
			jsr	CallNumRout

			ldy	#$0a			;Zahlenwert prüfen.
			jsr	CallNumRout
			bcc	:102			;Wert in Ordnung ? Ja, weiter.
			jsr	SetClkPos		;Alte Werte ausgeben.
			MoveW	V304b1,a7		;Zahl erneut eingeben.
			jmp	InpNOptNum

::102			ldy	#$0c			;Eingabe übernehmen.
			jsr	CallNumRout

			lda	mouseOn			;Icons aktivieren.
			ora	#%00100000
			sta	mouseOn
			LoadW	otherPressVec,ChkOptSlct

			jsr	SetHelp

			PushW	V304b0			;Rücksprung-Adresse wieder herstellen.
			rts

;*** Variablen.
:HelpFileName		b "09,GDH_DOS/Datei",NULL

:InputBuf		s $04
:WinOpen		b $00
:MenuOpen		b $00
:curSubMenu		b $00

:MenuText		w V304d0, V304d1, V304d2
:InfoText		w V304c1, V304c2, V304c3

:V304a0			b $28,$2f
			w $0008,$0057
			b $28,$2f
			w $0060,$00af
			b $28,$2f
			w $00b8,$0107

:V304b0			w $0000
:V304b1			w $0000
:V304b2			b 1,10,100
:V304b3			w $0000

if Sprache = Deutsch
:V304c0			b PLAINTEXT,"Datei-Informationen zeigen",NULL
:V304c1			b "Datum und Uhrzeit ändern",NULL
:V304c2			b "Datei-Attribute ändern",NULL
:V304c3			b "Datei-Statistik",NULL
endif

if Sprache = Englisch
:V304c0			b PLAINTEXT,"View file-attributes",NULL
:V304c1			b "Change date and time",NULL
:V304c2			b "Change file-attributes",NULL
:V304c3			b "File statistics",NULL
endif

if Sprache = Deutsch
;*** Menütexte.
:V304d0			b PLAINTEXT
			b GOTOXY
			w $0018
			b $5e
			b "Datum & Uhrzeit der"
			b GOTOXY
			w $0018
			b $66
			b "letzten Änderung"

			b GOTOXY
			w $0028
			b $76
			b "Datum   :"
			b GOTOX
			w $0099
			b "."
			b GOTOX
			w $00b9
			b "."

			b GOTOXY
			w $0028
			b $86
			b "Uhrzeit :"
			b GOTOX
			w $0099
			b ":"
			b GOTOX
			w $00b9
			b "."
			b NULL

:V304d1			b PLAINTEXT
			b GOTOXY
			w $0018
			b $5e
			b "Datei-Attribute"

			b GOTOXY
			w $0038
			b $6e
			b "Archivieren"
			b GOTOXY
			w $0038
			b $7e
			b "System-Datei"
			b GOTOXY
			w $0038
			b $8e
			b "Versteckt"
			b GOTOXY
			w $0038
			b $9e
			b "Schreibgeschützt"
			b NULL

:V304d2			b PLAINTEXT
			b GOTOXY
			w $0018
			b $5e
			b "Dateigröße   : "
			b GOTOX
			w $00dc
			b "Byte(s)"

			b GOTOXY
			w $0018
			b $6e
			b "Startcluster : "

			b GOTOXY
			w $0018
			b $7e
			b "Benötigt     : "
			b GOTOX
			w $00dc
			b "Cluster"
			b NULL
endif

if Sprache = Englisch
;*** Menütexte.
:V304d0			b PLAINTEXT
			b GOTOXY
			w $0018
			b $5e
			b "Date and time of"
			b GOTOXY
			w $0018
			b $66
			b "last change"

			b GOTOXY
			w $0028
			b $76
			b "Date    :"
			b GOTOX
			w $0099
			b "."
			b GOTOX
			w $00b9
			b "."

			b GOTOXY
			w $0028
			b $86
			b "Time    :"
			b GOTOX
			w $0099
			b ":"
			b GOTOX
			w $00b9
			b "."
			b NULL

:V304d1			b PLAINTEXT
			b GOTOXY
			w $0018
			b $5e
			b "File-attributes"

			b GOTOXY
			w $0038
			b $6e
			b "Archiv"
			b GOTOXY
			w $0038
			b $7e
			b "Systemfile"
			b GOTOXY
			w $0038
			b $8e
			b "Hidden"
			b GOTOXY
			w $0038
			b $9e
			b "Write-protected"
			b NULL

:V304d2			b PLAINTEXT
			b GOTOXY
			w $0018
			b $5e
			b "Filesize     : "
			b GOTOX
			w $00dc
			b "Byte(s)"

			b GOTOXY
			w $0018
			b $6e
			b "First cluster: "

			b GOTOXY
			w $0018
			b $7e
			b "Needed       : "
			b GOTOX
			w $00dc
			b "cluster"
			b NULL
endif

;*** Menügrafik
if Sprache = Deutsch
:V304e0			b MOVEPENTO
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
			b "Datum/Zeit"

			b GOTOX
			w $0064
			b "Attribute"

			b GOTOX
			w $00bc
			b "Statistik"

			b NULL
endif

;*** Menügrafik
if Sprache = Englisch
:V304e0			b MOVEPENTO
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
			b "Date/time"

			b GOTOX
			w $0064
			b "Attributes"

			b GOTOX
			w $00bc
			b "Statistic"

			b NULL
endif

;*** Datenliste für "Klick-Positionen".
:V304f0			w V304f1, V304f2, V304f3

:V304f1			b $40,$47
			w $0080,$00ff,DefName ,$0000
			b $70,$77
			w $0080,$0097,DefOpt1a,SetOpt1a
			b $70,$77
			w $00a0,$00b7,DefOpt1b,SetOpt1b
			b $70,$77
			w $00c0,$00d7,DefOpt1c,SetOpt1c
			b $80,$87
			w $0080,$0097,DefOpt2a,SetOpt2a
			b $80,$87
			w $00a0,$00b7,DefOpt2b,SetOpt2b
			b $80,$87
			w $00c0,$00d7,DefOpt2c,SetOpt2c
			b NULL

:V304f2			b $40,$47
			w $0080,$00ff,DefName ,$0000
			b $68,$6f
			w $0028,$002f,DefOpt3a,SetOpt3a
			b $78,$7f
			w $0028,$002f,DefOpt3b,SetOpt3b
			b $88,$8f
			w $0028,$002f,DefOpt3c,SetOpt3c
			b $98,$9f
			w $0028,$002f,DefOpt3d,SetOpt3d
			b NULL

:V304f3			b $40,$47
			w $0080,$00ff,DefName ,$0000
			b $58,$5f
			w $0080,$00d7,DefOpt4a,$0000
			b $68,$6f
			w $0080,$00d7,DefOpt4b,$0000
			b $78,$7f
			w $0080,$00d7,DefOpt4c,$0000
			b NULL

;*** Menütabellen für Zahlenausgabe.
:V304g0			w V304h0 ,V304h2 ,V304h4
			w V304h6 ,V304h8 ,V304h10

;*** Tabellen für Zahleneingabe.
:V304g1			w V304h1,V304h3,V304h5
			w V304h7,V304h9,V304h11

:V304h0			w $0084
			b $76
:V304h1			w $0084
			b $70
			w GetDay
			w HEXtoASCII,ASCIItoHEX
			w ChkDay
			w SetDay

:V304h2			w $00a4
			b $76
:V304h3			w $00a4
			b $70
			w GetMonth
			w HEXtoASCII,ASCIItoHEX
			w ChkMonth
			w SetMonth

:V304h4			w $00c4
			b $76
:V304h5			w $00c4
			b $70
			w GetYear
			w HEXtoASCII,ASCIItoHEX
			w ChkYear
			w SetYear

:V304h6			w $0084
			b $86
:V304h7			w $0084
			b $80
			w GetHour
			w HEXtoASCII,ASCIItoHEX
			w ChkHour
			w SetHour

:V304h8			w $00a4
			b $86
:V304h9			w $00a4
			b $80
			w GetMinute
			w HEXtoASCII,ASCIItoHEX
			w ChkMinute
			w SetMinute

:V304h10		w $00c4
			b $86
:V304h11		w $00c4
			b $80
			w GetSecond
			w HEXtoASCII,ASCIItoHEX
			w ChkSecond
			w SetSecond

;*** Icontabelle.
:Icon_Tab1		b 7
			w $0000
			b $00

			w Icon_Exit
			b $00,$08,$05,$18
			w EndEdit

			w Icon_Load
			b $05,$08,$05,$18
			w StartEdit_a

			w Icon_Save
			b $0a,$08,$05,$18
			w Edit_OK

			w Icon_Last
			b $0f,$08,$05,$18
			w LastEdit

			w Icon_Next
			b $14,$08,$05,$18
			w Edit_Cancel

			w Icon_Files
			b $19,$08,$05,$18
			w ChangeFiles

:Icon_Tab1a		s 2 * 8

:Icon_Tab1b		w Icon_Drive
			b $0d,$08,$05,$18
			w ChangeDrive

			w Icon_Disk
			b $10,$08,$05,$18
			w ChangeDisk

;*** Icons.
if Sprache = Deutsch
:Icon_Exit
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_Exit
<MISSING_IMAGE_DATA>
endif

:Icon_Load
<MISSING_IMAGE_DATA>

:Icon_Save
<MISSING_IMAGE_DATA>

:Icon_Last
<MISSING_IMAGE_DATA>

:Icon_Next
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
:Icon_Drive
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_Drive
<MISSING_IMAGE_DATA>
endif

if Sprache = Deutsch
:Icon_Disk
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_Disk
<MISSING_IMAGE_DATA>
endif

if Sprache = Deutsch
:Icon_Files
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_Files
<MISSING_IMAGE_DATA>
endif

:EndProgrammCode
