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

			n	"mod.#404.obj"
			o	ModStart
			q	EndProgrammCode
			r	EndAreaCBM

			jmp	CBM_FileInfo

			t	"-CBM_TextEdit"
			t	"-CBM_SlctFiles"

;*** Datei-Attribute ändern.
:LastGEOSType		= 23

:CBM_FileInfo		lda	Target_Drv
			jsr	NewDrive

			LoadW	r14,V404c0		;Titeltext.
			jsr	SlctFiles		;Dateien einlesen.
			tax
			beq	:101
			jmp	L404ExitGD		;Zurück zu GeoDOS.

::101			jsr	SetHelp

			LoadW	a5,FileNTab		;Zeiger auf Tabelle.

:StartEdit		lda	#$00
			sta	WinOpen
			sta	MenuOpen
			jmp	StartEdit_a

;*** Zeiger auf Hilfedatei bereitstellen.
:SetHelp		LoadW	r0,HelpFileName
			lda	#<StartEdit
			ldx	#>StartEdit
			jmp	InstallHelp

;*** Zurück zu GeoDOS.
:EndEdit		jsr	PrepEndInfo
:L404ExitGD		jmp	InitScreen

;*** Neues Laufwerk.
:ChangeDrive		jsr	PrepEndInfo
			jmp	vC_FileInfo

;*** Neue Diskette
:ChangeDisk		jsr	PrepEndInfo
			ldx	#$ff
			lda	curDrive
			jsr	InsertDisk
			cmp	#$01
			beq	ChangeFiles1
			jmp	L404ExitGD

;*** Neue Dateien.
:ChangeFiles		jsr	PrepEndInfo
:ChangeFiles1		jmp	CBM_FileInfo

;*** Infos der aktuellen Datei anzeigen.
:StartEdit_a		MoveW	a5,r14			;Aktuelle Datei suchen.
			jsr	LookCBMfile
			tay				;Datei gefunden ?
			bne	NextEdit		;Ja, weiter...
			MoveW	r1,CurSek
			stx	SekPoi

			jsr	Bildschirm_a		;Menü darstellen.
			jmp	InitFileData		;Optionen ändern.

:NextEdit		jsr	StopTextEdit
			ldy	#$10
			lda	(a5L),y			;Dateiende erreicht ?
			beq	StartEdit_a		;Nein, weiter...
			AddVBW	16,a5			;Zeiger auf nächste Datei.
			jmp	StartEdit_a		;Optionen anzeigen.

:LastEdit		jsr	StopTextEdit
			CmpWI	a5,FileNTab
			beq	StartEdit_a
			SubVW	16,a5			;Zeiger auf nächste Datei.
			jmp	StartEdit_a		;Optionen anzeigen.

;*** Änderungen Rückgängig machen.
:Edit_Undo		jsr	StopTextEdit		;Eingabe "Infotext" beenden.
			MoveW	CurSek,r1		;Zeiger auf Verzeichnis-Sektor.
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Sektor auf Disk zurückschreiben.
			jmp	StartEdit_a		;Nächste Datei.

;*** Optionen speichern.
:Edit_OK		jsr	StopTextEdit		;Eingabe "Infotext" beenden.

			bit	IsGEOSfile
			bpl	:105

			bit	V404i2+0		;Neue GEOS-Klasse speichern.
			bpl	:103
			jsr	i_MoveData
			w	V404i0,fileHeader+$4d
			w	16

::103			bit	V404i2+1		;Neuen Autor speichern.
			bpl	:104
			jsr	i_MoveData
			w	V404i1,fileHeader+$61
			w	20

::104			ldy	SekPoi			;Infoblock speichern.
			lda	diskBlkBuf+21,y
			ldx	diskBlkBuf+22,y
			sta	r1L
			stx	r1H
			LoadW	r4,fileHeader
			jsr	PutBlock

::105			MoveW	CurSek,r1		;Zeiger auf Verzeichnis-Sektor.
			LoadW	r4,diskBlkBuf
			jsr	PutBlock		;Sektor auf Disk zurückschreiben.
			txa				;Fehler ?
			bne	ExitDskErr		;Nein, weiter...
:Edit_Cancel		jmp	NextEdit		;Nächste Datei.
:ExitDskErr		jmp	DiskError		;Diskettenfehler.

;*** Fenster aufbauen.
:Bildschirm_a		bit	WinOpen			;Bildschirm bereits aufgebaut ?
			bpl	:101			;Nein, weiter...
			rts

::101			jsr	ClrScreen		;Bildschirm löschen.
			jsr	i_C_MenuTitel
			b	$00,$00,$28,$01
			jsr	i_C_MenuBack
			b	$00,$01,$28,$18

			FillPRec$00,$00,$07,$0008,$013f

			jsr	UseGDFont
			Print	$08,$06
if Sprache = Deutsch
			b	PLAINTEXT,"CBM  -  Datei-Eigenschaften",NULL
endif
if Sprache = Englisch
			b	PLAINTEXT,"CBM  -  Filke-attributes",NULL
endif

			LoadW	r0,V404l0		;Menü zeichnen.
			jsr	GraphicsString

			jsr	i_C_Register
			b	$01,$05,$0a,$01
			jsr	i_C_Register
			b	$0c,$05,$09,$01
			jsr	i_C_Register
			b	$16,$05,$09,$01
			jsr	i_C_Register
			b	$20,$05,$05,$01

			LoadB	icon_Tab1,6		;Icon-Tabelle definieren.
			LoadB	r14H,$1e
			LoadW	r15,icon_Tab1a

			CmpBI	CBM_Count,2		;Mehr als 1 Laufwerk ?
			bcc	:102
			ldx	#$00			;Ja, Laufwerkswahl-Icon darstellen.
			jsr	Copy1Icon

::102			ldx	Target_Drv		;Diskettenlaufwerk ?
			lda	DriveModes-8,x
			and	#%00001000
			bne	:103
			lda	DriveTypes-8,x
			cmp	#Drv_CMDHD
			beq	:103
			cmp	#Drv_64Net
			beq	:103
			ldx	#$08			;Ja, Diskettenwechsel-Icon darstellen.
			jsr	Copy1Icon

::103			lda	r14H
			sta	:104 +2
			jsr	i_C_MenuMIcon
::104			b	$00,$01,$ff,$03

			dec	WinOpen
			rts

;*** Icon in Icon-Zeile übernehmen.
:Copy1Icon		lda	r14H
			sta	icon_Tab1b+2,x

			ldy	#$00
::101			lda	icon_Tab1b  ,x
			sta	(r15L),y
			inx
			iny
			cpy	#$08
			bne	:101

			AddVB	5,r14H
			AddVBW	8,r15
			inc	icon_Tab1
			rts

;*** Eingabe beenden, Bildschirm löschen.
:PrepEndInfo		jsr	StopTextEdit		;Eingabe Infotext beenden.
			Display	ST_WR_FORE

;*** Fenster wieder löschen.
:ClrWin			lda	#$00
			sta	WinOpen
			sta	MenuOpen
			sta	otherPressVec+0		;Mausabfrage löschen.
			sta	otherPressVec+1
			jmp	ClrScreen		;Bildschirm löschen.

;*** Options-Menü initialisieren.
:InitFileData		ldy	SekPoi
			lda	diskBlkBuf+21,y
			beq	:101
			ldx	diskBlkBuf+22,y
			sta	r1L
			stx	r1H
			LoadW	r4,fileHeader
			jsr	GetBlock
			jsr	i_MoveData
			w	fileHeader+$05
			w	spr2pic
			w	63
			lda	#$ff
::101			sta	IsGEOSfile

			bit	IsGEOSfile
			bmi	:103

			ldy	SekPoi
			lda	diskBlkBuf+3,y
			sta	r1L
			lda	diskBlkBuf+4,y
			sta	r1H
			LoadW	r4,fileHeader
			jsr	GetBlock

			ldx	#$03
			ldy	#$00
			CmpBI	curSubMenu,3
			bcc	:102
			stx	curSubMenu
::102			sty	curMenuGEOS

::103			jsr	GetKlasse
			jsr	GetAutor

			bit	MenuOpen
			bpl	NewFileData
			jsr	SetClkPos
			jmp	EditFileData

;*** Dateiinfo-Menü neu initialisieren.
:NewFileData		jsr	StopTextEdit		;Eingabe Infotext beenden.
			jsr	InitMenuPage		;Menüseite initialisieren.

:EditFileData		LoadW	otherPressVec,ChkOptSlct
			LoadW	r0,icon_Tab1
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
:SetClkPos		jsr	DefSwapPage
			jsr	SetDataVec		;Zeiger auf Menütabelle.

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
			lda	V404n0+0,x
			sta	a7L
			lda	V404n0+1,x
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
:ChkOptSlct		lda	#$00
			jsr	:110
			bne	:101

			lda	#$06
			jsr	:110
			bne	:102

			lda	#$0c
			jsr	:110
			bne	:103

			lda	#$12
			jsr	:110
			bne	:104

			lda	#$18
			jsr	:110
			bne	:106
			jmp	:120

::101			lda	#$00
			b $2c
::102			lda	#$01
			b $2c
::103			lda	#$02
			jmp	:105

::104			lda	#$03
			bit	IsGEOSfile
			bpl	:105
			adda	curMenuGEOS

::105			cmp	curSubMenu
			beq	:107
			sta	curSubMenu

			jmp	NewFileData		;Nein, weitertesten.

::106			jmp	ChangePage

::107			rts

::110			clc
			adc	#<V404a0
			sta	a7L
			lda	#$00
			adc	#>V404a0
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

;*** Icon für Seitenwechsel zeichnen.
:DefSwapPage		CmpBI	curSubMenu,3
			bcc	:102

			bit	IsGEOSfile
			bpl	:101
			jsr	i_BitmapUp
			w	icon_Page
			b	$26,$a8,$02,$10
			jsr	i_ColorBox
			b	$26,$15,$02,$02,$01
			rts

::101			FillPRec$00,$a8,$b6,$0130,$013e
			jsr	i_C_MenuBack
			b	$26,$15,$02,$02
::102			rts

;*** Seite wechseln.
:ChangePage		bit	IsGEOSfile
			bpl	:101
			sec				;Y-Koordinate der Maus einlesen.
			lda	mouseYPos		;Testen ob Maus innerhalb des
			sbc	#168			;"Eselsohrs" angeklickt wurde.
			bcs	:102
::101			rts				;Nein, Rücksprung.

::102			tay
			sec
			lda	mouseXPos+0
			sbc	#<304
			tax
			lda	mouseXPos+1
			sbc	#>304
			bne	:101
			cpx	#16			;Ist Maus innerhalb des "Eselsohrs" ?
			bcs	:101			;Nein, Rücksprung.
			cpy	#16
			bcs	:101
			sty	r0L
			txa				;Feststellen: Seite vor/zurück ?
			eor	#%00001111
			cmp	r0L
			bcs	:111			;Seite vor.
			bcc	:121			;Seite zurück.

;*** Weiter auf nächste Seite.
::111			ldx	curMenuGEOS
			inx
			cpx	#$04
			bne	:131
			ldx	#$00
			beq	:131

;*** Zurück zur letzten Seite.
::121			ldx	curMenuGEOS
			dex
			cpx	#$ff
			bne	:131
			ldx	#$03

::131			stx	curMenuGEOS
			txa
			add	3
			sta	curSubMenu
			jmp	NewFileData

;*** Daten für Rahmen nach ":r2".
:CopyRecData		ldy	#$05
::1			lda	(a7L),y
			sta	r2,y
			dey
			bpl	:1
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

;*** Icon-Optionen beenden.
:EndSetIcon		pla
			pla
			cli
			NoMseKey			;Warten bis keine Maustaste gedrückt.
			rts				;Ende.

;*** Datei-Struktur anzeigen.
:DefFileStruct		jsr	InitOptField

			LoadW	r11,$0094
			LoadB	r1H,$5e

			LoadW	r0,V404e0		;Text für "Commodore-Format".
			ldy	SekPoi
			lda	diskBlkBuf +$18,y
			beq	:101
			LoadW	r0,V404e1		;Text für "GEOS-Sequentiell".
			lda	fileHeader +$46
			beq	:101
			LoadW	r0,V404e2		;Text für "GEOS-VLIR".
::101			jsr	PutString		;Datei-Format ausgeben.
			jmp	DefClkOpt

;*** GEOS-Dateityp anzeigen.
:DefGEOStyp		jsr	PrintGEOStyp
			jmp	DefClkOpt

;*** GEOS-Dateityp wechseln.
:SetGEOStyp		bit	IsGEOSfile
			bmi	:102
::101			rts

::102			ldx	fileHeader+$45
			cpx	#LastGEOSType
			bcs	:101
			lda	V404f1,x
			beq	:101

::103			lda	V404f2,x
			tax
			jmp	:104

			ldx	fileHeader+$45
			inx
			cpx	#LastGEOSType
			bcc	:104
			ldx	#$00
::104			stx	fileHeader+$45

			lda	V404f1,x
			beq	:103
			txa
			ldy	SekPoi
			sta	diskBlkBuf+$18,y

			jsr	InitOptField
			jsr	PrintGEOStyp

			jsr	CPU_Pause
			jsr	CPU_Pause
			jsr	CPU_Pause
			bit	mouseData
			bpl	:102
			rts

;*** GEOS-Dateityp ausgeben.
:PrintGEOStyp		jsr	InitOptField

			bit	IsGEOSfile
			bpl	:102

			LoadB	r1H,$6e
			LoadW	r11,$0094

			bit	IsGEOSfile		;Falls keine GEOS-Datei, überspringen.
			bpl	:101
			lda	fileHeader +$45
			cmp	#LastGEOSType		;Wert kleiner 22 ?
			bcc	:101			;Ja, weiter...
			lda	#LastGEOSType		;Nein, Datei ist "Nicht GEOS".
::101			asl				;Zeiger auf Text für GEOS-Typ
			tax				;berechnen.
			lda	V404f0 +0,x		;Startadresse Text einlesen.
			sta	r0L
			lda	V404f0 +1,x
			sta	r0H
			jsr	PutString		;GEOS-Datei-Typ ausgeben.
::102			rts

;*** Klasse ausgeben.
:DefKlasse		jsr	InitOptField

			bit	IsGEOSfile
			bmi	:101
			jmp	DefClkOpt

::101			PrintXY	$0094,$7e,V404i0
			jmp	DefClkOpt

;*** Klasse eingeben.
:SetKlasse		bit	IsGEOSfile
			bmi	:101
			rts

::101			jsr	InitOptField
			LoadW	r0,V404i0
			LoadB	r1H,$78
			LoadW	r11,$0094
			ldx	#16
			LoadB	V404i2+0,$ff
			jmp	SetInputText

;*** Klasse kopieren.
:GetKlasse		ldx	#$00
::101			lda	fileHeader +$4d,x
			sta	V404i0,x
			beq	:102
			inx
			cpx	#$10
			bne	:101
::102			rts

;*** Autor ausgeben.
:DefAutor		jsr	InitOptField

			bit	IsGEOSfile
			bmi	:101
			jmp	DefClkOpt

::101			PrintXY	$0094,$8e,V404i1
			jmp	DefClkOpt

;*** Autor eingeben
:SetAutor		bit	IsGEOSfile
			bmi	:101
			rts

::101			jsr	InitOptField
			LoadW	r0,V404i1
			LoadB	r1H,$88
			LoadW	r11,$0094
			ldx	#20
			LoadB	V404i2+1,$ff
			jmp	SetInputText

;*** Autor kopieren.
:GetAutor		ldy	#19
::101			lda	fileHeader +$61,y
			beq	:102
			cmp	#$20			;Auf gültigen Autoren-Namen testen.
			bcc	:105
			cmp	#$7f
			bcs	:105
::102			dey
			bpl	:101

			ldx	#$00
::103			lda	fileHeader +$61,x
			sta	V404i1,x
			beq	:105
::104			inx
			cpx	#$14
			bne	:103
::105			rts

;*** Klasse/Autor eingeben.
:SetInputText		stx	r2L

			PopW	V404j1

			lda	mouseOn
			and	#%10011111
			sta	mouseOn
			ClrW	otherPressVec
			MoveW	a7,V404j2
			LoadB	r1L,$00
			LoadW	keyVector,:101
			jsr	GetString
			jsr	InitForIO
			LoadB	$d028,$00
			jmp	DoneWithIO

;*** Eingabe beenden.
::101			MoveW	V404j2,a7

			lda	mouseOn
			ora	#%00100000
			sta	mouseOn
			LoadW	otherPressVec,ChkOptSlct

			jsr	SetHelp

			PushW	V404j1
			rts

;*** GEOS-Modus anzeigen.
:DefModus1		lda	#$00
			b $2c
:DefModus2		lda	#$40
			b $2c
:DefModus3		lda	#$80
			b $2c
:DefModus4		lda	#$c0

			bit	IsGEOSfile		;Falls keine GEOS-Datei, überspringen.
			bpl	:1

			ldy	#$00
			cmp	fileHeader +$60
			bne	:1
			ldy	#$02
::1			rts

;*** GEOS-Modus wechseln.
:SetModus1		lda	#$00
			b $2c
:SetModus2		lda	#$40
			b $2c
:SetModus3		lda	#$80
			b $2c
:SetModus4		lda	#$c0

			bit	IsGEOSfile
			bpl	:101
			sta	fileHeader+$60
::101			rts

;*** Infotext eingeben
:DefInfoText		LoadW	r0,fileHeader+$a0
			LoadB	r2L,$70
			LoadB	r2H,$9d
			LoadW	r3,$0018
			LoadW	r4,$00bf
			jsr	InputText
			jmp	DefClkOpt

;*** Texteingabe abschließen.
:StopTextEdit		bit	IsGEOSfile
			bpl	:101

			jsr	InitForIO
			lda	C_Mouse
			sta	$d027
			jsr	DoneWithIO

			jsr	PromptOff

			lda	alphaFlag
			and	#%01111111
			sta	alphaFlag

			jsr	SetHelp

::101			rts

;*** Icons definieren.
:DefIcon1		bit	IsGEOSfile		;Falls keine GEOS-Datei, überspringen.
			bpl	:101

			jsr	DrawIcon
::101			jmp	DefClkOpt

;*** Icon ändern.
:SetIcon1		lda	mouseXPos
			sub	$18
			lsr
			lsr
			cmp	#$18
			bcc	:101
			jmp	:106

::101			sta	r15L
			sta	r14L

			lda	mouseYPos
			sub	$50
			lsr
			lsr
			cmp	#$15
			bcc	:102
			jmp	:106

::102			sta	r15H
			sta	r14H

			ldx	#$00
::103			lda	r14H
			beq	:104
			inx
			inx
			inx
			dec	r14H
			bne	:103

::104			lda	r14L
			cmp	#$08
			bcc	:105
			sub	8
			sta	r14L
			inx
			bne	:104

::105			lda	spr2pic,x
			ldy	r14L
			eor	BitPos,y
			sta	spr2pic,x
			and	BitPos,y
			jsr	Draw1Point
::106			jmp	EndSetIcon

;*** Icons definieren.
:DefIcon2		bit	IsGEOSfile		;Falls keine GEOS-Datei, überspringen.
			bpl	:101

			jsr	DefIcon2a
::101			jmp	DefClkOpt

:DefIcon2a		LoadW	r0,fileHeader +4
			LoadB	r1L,$1a			;Position für Datei-Icon.
			LoadB	r1H,$6d
			lda	fileHeader +2		;Größe des Datei-Icons.
			sta	r2L
			lda	fileHeader +3
			sta	r2H
			jmp	BitmapUp		;Datei-Icon ausgaben.

;*** "Löschen"-Icon zeichnen.
:DefIcon3		LoadW	r0,icon_Clear
			ldx	#$10
			ldy	#$98
			jmp	DefEditIcon

;*** Icon löschen
:SetIcon3		bit	IsGEOSfile		;Falls keine GEOS-Datei, überspringen.
			bpl	:102

			ldy	#$00
			tya
::101			sta	spr2pic,y
			iny
			cpy	#63
			bne	:101
			jsr	DrawIcon
::102			jmp	EndSetIcon

;*** "Invertieren"-Icon zeichnen.
:DefIcon4		LoadW	r0,icon_Invert
			ldx	#$13
			ldy	#$98
			jmp	DefEditIcon

;*** Icon invertieren
:SetIcon4		bit	IsGEOSfile		;Falls keine GEOS-Datei, überspringen.
			bpl	:102

			ldy	#$00
::101			lda	spr2pic,y
			eor	#%11111111
			sta	spr2pic,y
			iny
			cpy	#63
			bne	:101
			jsr	DrawIcon
::102			jmp	EndSetIcon

;*** "In Datei"-Icon zeichnen.
:DefIcon5		LoadW	r0,icon_ToFile
			ldx	#$10
			ldy	#$80
			jmp	DefEditIcon

;*** Icon speichern.
:SetIcon5		bit	IsGEOSfile		;Falls keine GEOS-Datei, überspringen.
			bpl	:101

			jsr	i_MoveData
			w	spr2pic
			w	fileHeader+$05
			w	63
			jsr	DefIcon2a
::101			jmp	EndSetIcon

;*** "Aus Datei"-Icon zeichnen.
:DefIcon6		LoadW	r0,icon_FromFile
			ldx	#$13
			ldy	#$80
			jmp	DefEditIcon

;*** Icon laden.
:SetIcon6		bit	IsGEOSfile		;Falls keine GEOS-Datei, überspringen.
			bpl	:101

			jsr	i_MoveData
			w	fileHeader+$05
			w	spr2pic
			w	63
			jsr	DrawIcon
::101			jmp	EndSetIcon

;*** Edit-Icons auf Bildschirm ausgeben.
:DefEditIcon		bit	IsGEOSfile		;Falls keine GEOS-Datei, überspringen.
			bpl	:101

			stx	r1L
			sty	r1H
			LoadB	r2L,$02
			LoadB	r2H,$10
			jsr	BitmapUp

::101			jmp	DefClkOpt

;*** Werte definieren.
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

;*** Optionswerte definieren.
:SetOpt1a		lda	#$00			;Tag eingeben.
			b $2c
:SetOpt1b		lda	#$01			;Monat eingeben.
			b $2c
:SetOpt1c		lda	#$02			;Jahr eingeben.
			b $2c
:SetOpt2a		lda	#$03			;Stunde eingeben.
			b $2c
:SetOpt2b		lda	#$04			;Minute eingeben.
			asl
			tax
			lda	V404o1+0,x
			sta	a7L
			lda	V404o1+1,x
			sta	a7H
			jmp	InpOptNum

;*** CBM-dateityp ausgeben
:DefOpt3a		lda	#%00000000		;DEL-Bit ausgeben.
			b $2c
:DefOpt3b		lda	#%00000001		;SEQ-Bit ausgeben.
			b $2c
:DefOpt3c		lda	#%00000010		;PRG-Bit ausgeben.
			b $2c
:DefOpt3d		lda	#%00000011		;USR-Bit ausgeben.
			b $2c
:DefOpt3e		lda	#%00000100		;REL-Bit ausgeben.
			b $2c
:DefOpt3f		lda	#%00000101		;1581DIR-Bit ausgeben.
			b $2c
:DefOpt3g		lda	#%00000110		;DIR-Bit ausgeben.
			sta	:101 +1
			ldy	SekPoi
			lda	diskBlkBuf+2,y
			ldy	#$00
			and	#%00000111
::101			cmp	#%11111111
			bne	:102
			ldy	#$02
::102			rts

;*** CBM-Dateityp wechseln.
:SetOpt3a		lda	#%00000000		;DEL-Bit ausgeben.
			b $2c
:SetOpt3b		lda	#%00000001		;SEQ-Bit ausgeben.
			b $2c
:SetOpt3c		lda	#%00000010		;PRG-Bit ausgeben.
			b $2c
:SetOpt3d		lda	#%00000011		;USR-Bit ausgeben.
			b $2c
:SetOpt3e		lda	#%00000100		;REL-Bit ausgeben.
			b $2c
:SetOpt3f		lda	#%00000101		;1581DIR-Bit ausgeben.
			b $2c
:SetOpt3g		lda	#%00000110		;DIR-Bit ausgeben.
			sta	:101 +1
			ldy	SekPoi
			lda	diskBlkBuf+2,y
			and	#%11111000
::101			ora	#%11111111
			sta	diskBlkBuf+2,y
			rts

;*** Schreibschutz / 'CLOSED'-Flag anzeigen.
:DefOpt3j		lda	#%00010000		;Unused-Bit ausgeben.
			b $2c
:DefOpt3k		lda	#%00100000		;Hidden-Bit ausgeben.
			b $2c
:DefOpt3h		lda	#%01000000		;Schreibschutz-Bit ausgeben.
			b $2c
:DefOpt3i		lda	#%10000000		;OPEN-Bit ausgeben.
			sta	:101 +1
			ldy	SekPoi
			lda	diskBlkBuf+2,y
			ldy	#$00
::101			and	#%11111111
			beq	:102
			ldy	#$02
::102			rts

;*** Schreibschutz / 'CLOSED'-Flag ändern.
:SetOpt3j		lda	#%00010000		;Unused-Bit ändern.
			b $2c
:SetOpt3k		lda	#%00100000		;Hidden-Bit ändern.
			b $2c
:SetOpt3h		lda	#%01000000		;Schreibschutz-Bit ändern.
			b $2c
:SetOpt3i		lda	#%10000000		;OPEN-Bit ändern.
			sta	:101 +1
			ldy	SekPoi
			lda	diskBlkBuf+2,y
::101			eor	#%11111111
			sta	diskBlkBuf+2,y
			rts

;*** Dateigröße ausgeben.
:DefOpt4a		jsr	InitOptField

			LoadW	r11,$0094
			LoadB	r1H,$5e
			ldy	SekPoi
			lda	diskBlkBuf+30,y
			sta	r0L
			lda	diskBlkBuf+31,y
			sta	r0H
			lda	#%11000000
			jsr	PutDecimal
			jmp	DefClkOpt

;*** Startspur ausgeben.
:DefOpt4b		jsr	InitOptField

			LoadW	r11,$00b4
			LoadB	r1H,$6e
			ldy	SekPoi
			lda	diskBlkBuf+3,y
			jsr	PrnTrSe
			jmp	DefClkOpt

;*** Startsektor ausgeben.
:DefOpt4c		jsr	InitOptField

			LoadW	r11,$010c
			LoadB	r1H,$6e
			ldy	SekPoi
			lda	diskBlkBuf+4,y
			jsr	PrnTrSe
			jmp	DefClkOpt

;*** Track von Infoblock ausgeben.
:DefOpt4d		jsr	InitOptField

			bit	IsGEOSfile
			bpl	:101

			LoadW	r11,$00b4
			LoadB	r1H,$7e
			ldy	SekPoi
			lda	diskBlkBuf+21,y
			jsr	PrnTrSe
::101			jmp	DefClkOpt

;*** Sektor von Infoblock ausgeben.
:DefOpt4e		jsr	InitOptField

			bit	IsGEOSfile
			bpl	:101

			LoadW	r11,$010c
			LoadB	r1H,$7e
			ldy	SekPoi
			lda	diskBlkBuf+22,y
			jsr	PrnTrSe
::101			jmp	DefClkOpt

;*** Startadresse ausgeben.
:DefOpt4f		lda	fileHeader+$47		;Startadresse GEOS-Datei.
			ldx	fileHeader+$48
			bit	IsGEOSfile		;Datei = Typ GEOS ?
			bmi	:101			;Ja, weiter...

			ldy	SekPoi			;Datei = Typ CBM-PRG ?
			lda	diskBlkBuf+2,y
			cmp	#$82
			bne	:102			;Nein, übergehen.
			lda	fileHeader+$02
			ldx	fileHeader+$03

::101			pha				;Startadresse merken.
			txa
			pha

			jsr	InitOptField

			LoadW	r11,$0094
			LoadB	r1H,$8e
			lda	#"$"
			jsr	SmallPutChar
			PopB	r15L			;HIGH-Byte.
			jsr	PrnHexZahl
			PopB	r15L			;LOW-Byte.
			jsr	PrnHexZahl
::102			jmp	DefClkOpt

;*** Endadresse ausgeben.
:DefOpt4g		jsr	InitOptField

			bit	IsGEOSfile		;Datei = Typ GEOS ?
			bpl	:101			;Ja, weiter...

			LoadW	r11,$0094
			LoadB	r1H,$9e
			lda	#"$"
			jsr	SmallPutChar
			lda	fileHeader+$4a		;Endadresse GEOS-Datei.
			sta	r15L			;HIGH-Byte.
			jsr	PrnHexZahl
			lda	fileHeader+$49
			sta	r15L			;LOW-Byte.
			jsr	PrnHexZahl
::101			jmp	DefClkOpt

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
			cpy	#$10
			bne	:101

::103			jmp	DefClkOpt

;*** Datum & Uhrzeit aus DOS einlesen..
:GetDay			ldy	SekPoi
			lda	diskBlkBuf+27,y
			rts

:GetMonth		ldy	SekPoi
			lda	diskBlkBuf+26,y
			rts

:GetYear		ldy	SekPoi
			lda	diskBlkBuf+25,y
			rts

:GetHour		ldy	SekPoi
			lda	diskBlkBuf+28,y
			rts

:GetMinute		ldy	SekPoi
			lda	diskBlkBuf+29,y
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

:Check			ldx	r0H
			bne	ChkError
			cmp	r0L
			bcc	ChkError
			clc				;Wert OK!
			rts
:ChkError		sec				;Wert zu klein/zu groß.
			rts

;*** Datum eingeben.
:SetDay			ldy	SekPoi
			lda	r0L
			sta	diskBlkBuf+27,y
			rts

:SetMonth		ldy	SekPoi
			lda	r0L
			sta	diskBlkBuf+26,y
			rts

:SetYear		ldy	SekPoi
			lda	r0L
			sta	diskBlkBuf+25,y
			rts

;*** Uhrzeit eingeben.
:SetHour		ldy	SekPoi
			lda	r0L
			sta	diskBlkBuf+28,y
			rts

:SetMinute		ldy	SekPoi
			lda	r0L
			sta	diskBlkBuf+29,y
			rts

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

;*** $HEX nach HEXASCII wandeln.
:HEXtoHEXASCII		lda	r15L
			ldx	#$30
::101			cmp	#16
			bcc	:103
			inx
			cpx	#$3a
			bne	:102
			inx
			inx
			inx
			inx
			inx
			inx
			inx
::102			sec
			sbc	#16
			bcs	:101
::103			cmp	#10
			bcc	:104
			add	7
::104			add	$30
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
			lda	V404j3,y		;oder 100er addieren.
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

;*** Track/Sektor ausgeben.
:PrnTrSe		sta	r15L
			lda	#"$"
			jsr	SmallPutChar
:PrnHexZahl		jsr	HEXtoHEXASCII
			lda	InputBuf+0
			jsr	SmallPutChar
			lda	InputBuf+1
			jmp	SmallPutChar

;*** Zahlenwert ausgeben.
:PutNumOnScrn		sta	r15L			;Zahlenwert nach ":r0".
			jsr	HEXtoASCII
			tya				;Startadresse Menütabelle berechnen.
			asl
			tax
			lda	V404o0+0,x
			sta	a6L
			lda	V404o0+1,x
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
:InpOptNum		PopW	V404j1			;Rücksprung-Adresse merken.

			lda	mouseOn			;Menüs & Icons aus.
			and	#%10011111
			sta	mouseOn
			ClrW	otherPressVec
			MoveW	a7,V404j2		;Zeiger auf Menütabelle merken.

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
::101			MoveW	V404j2,a7		;Zeiger auf Menütabelle zurücksetzen.

			ldy	#$08			;Eingabe nach HEX wandeln.
			jsr	CallNumRout

			ldy	#$0a			;Zahlenwert prüfen.
			jsr	CallNumRout
			bcc	:102			;Wert in Ordnung ? Ja, weiter.
			jsr	SetClkPos		;Alte Werte ausgeben.
			MoveW	V404j2,a7		;Zahl erneut eingeben.
			jmp	InpNOptNum

::102			ldy	#$0c			;Eingabe übernehmen.
			jsr	CallNumRout

			lda	mouseOn			;Icons aktivieren.
			ora	#%00100000
			sta	mouseOn
			LoadW	otherPressVec,ChkOptSlct

			jsr	SetHelp

			PushW	V404j1			;Rücksprung-Adresse wieder herstellen.
			rts

;*** Icon vergrößern.
:DrawIcon		lda	#$00
			sta	r14L			;Zeiger auf Byte und
			sta	r15H			;Zeiger auf Y-Koordinate löschen.

::101			lda	#$00			;Zeiger auf X-Koordinate löschen.
			sta	r15L

::102			lda	#$00			;Zeiger auf Bit löschen.
			sta	r14H

::103			ldx	r14L			;Byte aus Grafik einlesen.
			lda	spr2pic,x
			ldy	r14H			;Bit aus Grafik isolieren.
			and	BitPos,y
			jsr	Draw1Point		;Punkt zeichnen.

			inc	r15L			;X-Koordinate +1.
			inc	r14H			;Zeiger auf nächstes Bit.
			lda	r14H			;Alle 8 Bit eines Byte ausgegeben ?
			cmp	#$08
			bne	:103			;Nein, weiter...

			inc	r14L			;Zeiger auf nächstes Byte.
			lda	r15L			;24 Punkte = 1 Zeile ausgegeben ?
			cmp	#$18
			bne	:102			;Nein, weiter...

			inc	r15H			;Zeiger auf nächste Zeile.
			lda	r14L			;Alle 64 Byte ausgegeben ?
			cmp	#$3f
			bne	:101			;Nein, weiter...
			rts

;*** Einzelnen Punkt zeichnen.
:Draw1Point		pha				;$00 = löschen, <>$00 = setzen.
			lda	r15L			;minX-Koordinate berechnen.
			asl
			asl
			add	$18
			sta	r3L
			add	$03			;maxX-Koordinate berechnen.
			sta	r4L
			lda	#$00
			sta	r3H
			sta	r4H

			lda	r15H			;minY-Koordinate berechnen.
			asl
			asl
			add	$50
			sta	r2L
			add	$03			;maxY-Koordinate berechnen.
			sta	r2H

			ldx	#$00			;Vorgabe: Punkt löschen.
			pla				;Bit löschen oder setzen ?
			beq	:101			; = $00, dann löschen.
			inx				;Punkt setzen.
::101			txa
			jsr	SetPattern
			jmp	Rectangle

;*** Name der Hilfedatei.
:HelpFileName		b "11,GDH_CBM/Datei",NULL

;*** Variablen.
:InputBuf		s $04
:CurSek			b $00,$00
:SekPoi			b $00
:WinOpen		b $00
:MenuOpen		b $00
:IsGEOSfile		b $00
:curSubMenu		b $00
:curMenuGEOS		b $00

:BitPos			b $80,$40,$20,$10,$08,$04,$02,$01
:MenuText		w V404m0, V404m1, V404m2, V404m3, V404m4, V404m5, V404m6
:InfoText		w V404b0, V404b1, V404b2, V404b3, V404b4, V404b5, V404b6

:V404a0			b $28,$2f
			w $0008,$0057
			b $28,$2f
			w $0060,$00a7
			b $28,$2f
			w $00b0,$00f7
			b $28,$2f
			w $0100,$0127
			b $a8,$b7
			w $0130,$013f

if Sprache = Deutsch
:V404b0			b "Datum und Uhrzeit ändern",NULL
:V404b1			b "Datei-Attribute ändern",NULL
:V404b2			b "Datei-Statistik",NULL
:V404b3			b "GEOS-Informationen / Dateityp",NULL
:V404b4			b "GEOS-Informationen / Bildschirm-Modus",NULL
:V404b5			b "GEOS-Informationen / Infotext",NULL
:V404b6			b "GEOS-Informationen / Datei-Icon",NULL

:V404c0			b PLAINTEXT,"Datei-Informationen zeigen",NULL
:V404c1			b PLAINTEXT,"Neuer Dateiname",NULL

:V404d0			b PLAINTEXT,BOLDON
			b GOTOXY
			w 44
			b 165
			b "Keine GEOS-Datei!"
			b NULL
endif

if Sprache = Englisch
:V404b0			b "Edit time and date",NULL
:V404b1			b "Edit file-attributes",NULL
:V404b2			b "File-statistics",NULL
:V404b3			b "GEOS-Informations / Filetype",NULL
:V404b4			b "GEOS-Informations / Screenmode",NULL
:V404b5			b "GEOS-Informations / Informations",NULL
:V404b6			b "GEOS-Informations / Fileicon",NULL

:V404c0			b PLAINTEXT,"Edit file-attributes",NULL
:V404c1			b PLAINTEXT,"Edit filename",NULL

:V404d0			b PLAINTEXT,BOLDON
			b GOTOXY
			w 44
			b 165
			b "No GEOS-file!"
			b NULL
endif

;*** CBM- und GEOS-Dateitypen.
if Sprache = Deutsch
:V404e0			b PLAINTEXT,"Commodore",NULL
:V404e1			b PLAINTEXT,"Sequentiell",NULL
:V404e2			b PLAINTEXT,"GEOS - VLIR",NULL
endif

if Sprache = Englisch
:V404e0			b PLAINTEXT,"Commodore",NULL
:V404e1			b PLAINTEXT,"Sequential",NULL
:V404e2			b PLAINTEXT,"GEOS - VLIR",NULL
endif

:V404f0			w V404g0 ,V404g1 ,V404g2 ,V404g3 ,V404g4
			w V404g5 ,V404g6 ,V404g7 ,V404g8 ,V404g9
			w V404g10,V404g11,V404g12,V404g13,V404g14
			w V404g15,V404g99,V404g17,V404g99,V404g99
			w V404g99,V404g21,V404g22,V404g99

:V404f1			b $ff,$ff,$ff,$ff,$ff
			b $ff,$ff,$ff,$ff,$ff
			b $ff,$ff,$ff,$ff,$ff
			b $ff,$00,$ff,$00,$00
			b $00,$ff,$ff,$00

:V404f2			b $01,$02,$0c,$08,$0e
			b $06,$07,$03,$09,$16
			b $0f,$0d,$04,$11,$05
			b $0b,$00,$15,$00,$00
			b $00,$00,$0a,$00

:V404f3			w V404h0 ,V404h1 ,V404h2 ,V404h3

if Sprache = Deutsch
;*** GEOS-Dateitypen (max. 20 Zeichen).
:V404g0			b "Nicht GEOS",NULL
:V404g1			b "BASIC",NULL
:V404g2			b "Assembler",NULL
:V404g12		b "Startprogramm",NULL
:V404g4			b "System-Datei",NULL
:V404g14		b "Selbstausführend",NULL
:V404g5			b "DeskAccessory",NULL
:V404g6			b "Anwendung",NULL
:V404g7			b "Dokument",NULL
:V404g3			b "Datenfile",NULL
:V404g8			b "Zeichensatz",NULL
:V404g9			b "Druckertreiber",NULL
:V404g22		b "Drucker/GeoFAX",NULL
:V404g10		b "Eingabetreiber",NULL
:V404g15		b "Eingabetreiber 128",NULL
:V404g11		b "Laufwerkstreiber",NULL
:V404g13		b "Temporär/SwapFile",NULL
:V404g17		b "gateWay-Dokument",NULL
:V404g21		b "GeoShell-Kommando",NULL
:V404g99		b "GEOS ???",NULL

:V404h0			b "GEOS 40 Zeichen",NULL
:V404h1			b "GEOS 40 & 80 Zeichen",NULL
:V404h2			b "GEOS 64",NULL
:V404h3			b "GEOS 128, 80 Zeichen",NULL
endif

if Sprache = Englisch
;*** GEOS-Dateitypen (max. 20 Zeichen).
:V404g0			b "Not GEOS",NULL
:V404g1			b "BASIC",NULL
:V404g2			b "Assembler",NULL
:V404g12		b "Bootfile",NULL
:V404g4			b "Systemfile",NULL
:V404g14		b "Autoexecute",NULL
:V404g5			b "DeskAccessory",NULL
:V404g6			b "Application",NULL
:V404g7			b "Document",NULL
:V404g3			b "Datafile",NULL
:V404g8			b "Font",NULL
:V404g9			b "Printerdriver",NULL
:V404g22		b "Printer/GeoFAX",NULL
:V404g10		b "Inputdriver",NULL
:V404g15		b "Inputdriver 128",NULL
:V404g11		b "Diskdriver",NULL
:V404g13		b "Temporary",NULL
:V404g17		b "gateWay-document",NULL
:V404g21		b "GeoShell-command",NULL
:V404g99		b "GEOS ???",NULL

:V404h0			b "GEOS 40 columns",NULL
:V404h1			b "GEOS 40 & 80 columns",NULL
:V404h2			b "GEOS 64",NULL
:V404h3			b "GEOS 128, 80 columns",NULL
endif

:V404i0			s 17				;Klasse.
:V404i1			s 21				;Autor.
:V404i2			b $00,$00

:V404j0			b $91,$00,$00,$00,$00
:V404j1			w $0000
:V404j2			w $0000
:V404j3			b 1,10,100

;*** Menügrafik
if Sprache = Deutsch
:V404l0			b MOVEPENTO
			w $0000
			b $30
			b FRAME_RECTO
			w $013f
			b $b7
			b FRAME_RECTO
			w $0000
			b $c7

			b ESC_PUTSTRING
			w $000e
			b $2e
			b PLAINTEXT
			b "Datum/Zeit"
			b GOTOX
			w $0064
			b "Attribute"
			b GOTOX
			w $00b4
			b "Statistik"
			b GOTOX
			w $0104
			b "GEOS"

			b NULL
endif

if Sprache = Englisch
:V404l0			b MOVEPENTO
			w $0000
			b $30
			b FRAME_RECTO
			w $013f
			b $b7
			b FRAME_RECTO
			w $0000
			b $c7

			b ESC_PUTSTRING
			w $000e
			b $2e
			b PLAINTEXT
			b "Date/time"
			b GOTOX
			w $0064
			b "Attribute"
			b GOTOX
			w $00b4
			b "Statistic"
			b GOTOX
			w $0104
			b "GEOS"

			b NULL
endif

;*** Menütexte.
if Sprache = Deutsch
:V404m0			b PLAINTEXT
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
			b NULL

:V404m1			b PLAINTEXT
			b GOTOXY
			w $0018
			b $5e
			b "Datei-Attribute"

			b GOTOXY
			w $0038
			b $6e
			b "Typ 'DEL'"
			b GOTOXY
			w $0038
			b $7e
			b "Typ 'SEQ'"
			b GOTOXY
			w $0038
			b $8e
			b "Typ 'PRG'"
			b GOTOXY
			w $0038
			b $9e
			b "Typ 'USR'"
			b GOTOXY
			w $0038
			b $ae
			b "Bit%4 'UNUSED'"
			b GOTOXY
			w $00b0
			b $6e
			b "Typ 'REL'"
			b GOTOXY
			w $00b0
			b $7e
			b "Typ '1581DIR'"
			b GOTOXY
			w $00b0
			b $8e
			b "Typ 'CMD_Dir'"
			b GOTOXY
			w $00b0
			b $9e
			b "Schreibschutz"
			b GOTOXY
			w $00b0
			b $ae
			b "Bit%5 'Hidden'"
			b GOTOXY
			w $00b0
			b $5e
			b "Datei geschlossen"
			b NULL
endif

;*** Menütexte.
if Sprache = Englisch
:V404m0			b PLAINTEXT
			b GOTOXY
			w $0018
			b $5e
			b "Date and time of"
			b GOTOXY
			w $0018
			b $66
			b "last edit"

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
			b NULL

:V404m1			b PLAINTEXT
			b GOTOXY
			w $0018
			b $5e
			b "File attributes"

			b GOTOXY
			w $0038
			b $6e
			b "Type 'DEL'"
			b GOTOXY
			w $0038
			b $7e
			b "Type 'SEQ'"
			b GOTOXY
			w $0038
			b $8e
			b "Type 'PRG'"
			b GOTOXY
			w $0038
			b $9e
			b "Type 'USR'"
			b GOTOXY
			w $0038
			b $ae
			b "Bit%4 'UNUSED'"
			b GOTOXY
			w $00b0
			b $6e
			b "Type 'REL'"
			b GOTOXY
			w $00b0
			b $7e
			b "Type '1581DIR'"
			b GOTOXY
			w $00b0
			b $8e
			b "Type 'CMD_Dir'"
			b GOTOXY
			w $00b0
			b $9e
			b "Write protected"
			b GOTOXY
			w $00b0
			b $ae
			b "Bit%5 'Hidden'"
			b GOTOXY
			w $00b0
			b $5e
			b "File closed"
			b NULL
endif

;*** Menütexte.
if Sprache = Deutsch
:V404m2			b PLAINTEXT
			b GOTOXY
			w $0018
			b $5e
			b "Dateigröße    :"
			b GOTOX
			w $00da
			b "Block(s)"

			b GOTOXY
			w $0018
			b $6e
			b "Erster Sektor :"
			b GOTOX
			w $0090
			b "Spur"
			b GOTOX
			w $00da
			b "Sektor"

			b GOTOXY
			w $0018
			b $7e
			b "Infoblock     :"
			b GOTOX
			w $0090
			b "Spur"
			b GOTOX
			w $00da
			b "Sektor"

			b GOTOXY
			w $0018
			b $8e
			b "Startadresse  :"

			b GOTOXY
			w $0018
			b $9e
			b "Endadresse    :"
			b NULL
endif

if Sprache = Englisch
:V404m2			b PLAINTEXT
			b GOTOXY
			w $0018
			b $5e
			b "Filesize      :"
			b GOTOX
			w $00da
			b "Block(s)"

			b GOTOXY
			w $0018
			b $6e
			b "First sector  :"
			b GOTOX
			w $0090
			b "Tr."
			b GOTOX
			w $00da
			b "Sector"

			b GOTOXY
			w $0018
			b $7e
			b "Infoblock     :"
			b GOTOX
			w $0090
			b "Tr."
			b GOTOX
			w $00da
			b "Sector"

			b GOTOXY
			w $0018
			b $8e
			b "Startaddress  :"

			b GOTOXY
			w $0018
			b $9e
			b "Endaddress    :"
			b NULL
endif

;*** Menütexte.
if Sprache = Deutsch
:V404m3			b PLAINTEXT
			b GOTOXY
			w $0018
			b $5e
			b "Dateistruktur :"
			b GOTOXY
			w $0018
			b $6e
			b "GEOS-Dateityp :"
			b GOTOXY
			w $0018
			b $7e
			b "GEOS-Klasse   :"
			b GOTOXY
			w $0018
			b $8e
			b "Autor         :"
			b NULL

:V404m4			b PLAINTEXT
			b GOTOXY
			w $0018
			b $5e
			b "Bildschirm-Modus:"

			b GOTOXY
			w $0038
			b $6e
			b "GEOS 64/128, nur 40 Zeichen"

			b GOTOXY
			w $0038
			b $7e
			b "GEOS 64/128, 40/80 Zeichen"

			b GOTOXY
			w $0038
			b $8e
			b "Nur GEOS 64"

			b GOTOXY
			w $0038
			b $9e
			b "Nur GEOS 128"

			b NULL

:V404m5			b PLAINTEXT
			b GOTOXY
			w $0018
			b $66
			b "Infotext"
			b NULL

:V404m6			b PLAINTEXT
			b GOTOXY
			w $00c8
			b $5e
			b "Original"
			b NULL
endif

;*** Menütexte.
if Sprache = Englisch
:V404m3			b PLAINTEXT
			b GOTOXY
			w $0018
			b $5e
			b "Filestructure :"
			b GOTOXY
			w $0018
			b $6e
			b "GEOS-filetype :"
			b GOTOXY
			w $0018
			b $7e
			b "GEOS-class    :"
			b GOTOXY
			w $0018
			b $8e
			b "Author        :"
			b NULL

:V404m4			b PLAINTEXT
			b GOTOXY
			w $0018
			b $5e
			b "Screen-mode   :"

			b GOTOXY
			w $0038
			b $6e
			b "GEOS 64/128, 40 columns only"

			b GOTOXY
			w $0038
			b $7e
			b "GEOS 64/128, 40/80 columns"

			b GOTOXY
			w $0038
			b $8e
			b "GEOS 64 only"

			b GOTOXY
			w $0038
			b $9e
			b "GEOS 128 only"

			b NULL

:V404m5			b PLAINTEXT
			b GOTOXY
			w $0018
			b $66
			b "Infotext"
			b NULL

:V404m6			b PLAINTEXT
			b GOTOXY
			w $00c8
			b $5e
			b "Original"
			b NULL
endif

;*** Datenliste für "Klick-Positionen".
:V404n0			w V404n1, V404n2, V404n3, V404n4, V404n5, V404n6, V404n7

:V404n1			b $40,$47
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
			b NULL

:V404n2			b $40,$47
			w $0080,$00ff,DefName ,$0000
			b $68,$6f
			w $0028,$002f,DefOpt3a,SetOpt3a
			b $78,$7f
			w $0028,$002f,DefOpt3b,SetOpt3b
			b $88,$8f
			w $0028,$002f,DefOpt3c,SetOpt3c
			b $98,$9f
			w $0028,$002f,DefOpt3d,SetOpt3d
			b $a8,$af
			w $0028,$002f,DefOpt3j,SetOpt3j
			b $68,$6f
			w $00a0,$00a7,DefOpt3e,SetOpt3e
			b $78,$7f
			w $00a0,$00a7,DefOpt3f,SetOpt3f
			b $88,$8f
			w $00a0,$00a7,DefOpt3g,SetOpt3g
			b $98,$9f
			w $00a0,$00a7,DefOpt3h,SetOpt3h
			b $a8,$af
			w $00a0,$00a7,DefOpt3k,SetOpt3k
			b $58,$5f
			w $00a0,$00a7,DefOpt3i,SetOpt3i
			b NULL

:V404n3			b $40,$47
			w $0080,$00ff,DefName ,$0000
			b $58,$5f
			w $0090,$00cf,DefOpt4a,$0000
			b $68,$6f
			w $00b0,$00cf,DefOpt4b,$0000
			b $68,$6f
			w $0108,$0127,DefOpt4c,$0000
			b $78,$7f
			w $00b0,$00cf,DefOpt4d,$0000
			b $78,$7f
			w $0108,$0127,DefOpt4e,$0000
			b $88,$8f
			w $0090,$00cf,DefOpt4f,$0000
			b $98,$9f
			w $0090,$00cf,DefOpt4g,$0000
			b NULL

:V404n4			b $40,$47
			w $0080,$00ff,DefName      ,$0000
			b $58,$5f
			w $0090,$0127,DefFileStruct,$0000
			b $68,$6f
			w $0090,$0127,DefGEOStyp   ,SetGEOStyp
			b $78,$7f
			w $0090,$0127,DefKlasse    ,SetKlasse
			b $88,$8f
			w $0090,$0127,DefAutor     ,SetAutor
			b NULL

:V404n5			b $40,$47
			w $0080,$00ff,DefName      ,$0000
			b $68,$6f
			w $0028,$002f,DefModus1    ,SetModus1
			b $78,$7f
			w $0028,$002f,DefModus2    ,SetModus2
			b $88,$8f
			w $0028,$002f,DefModus3    ,SetModus3
			b $98,$9f
			w $0028,$002f,DefModus4    ,SetModus4
			b NULL

:V404n6			b $40,$47
			w $0080,$00ff,DefName      ,$0000
			b $70,$9f
			w $0018,$00bf,DefInfoText  ,$0000
			b NULL

:V404n7			b $40,$47
			w $0080,$00ff,DefName      ,$0000
			b $50,$a7
			w $0018,$0077,DefIcon1     ,SetIcon1
			b $68,$87
			w $00c8,$00ef,DefIcon2     ,$0000
			b $98,$a7
			w $0080,$008f,DefIcon3     ,SetIcon3
			b $98,$a7
			w $0098,$00a7,DefIcon4     ,SetIcon4
			b $80,$8f
			w $0080,$008f,DefIcon5     ,SetIcon5
			b $80,$8f
			w $0098,$00a7,DefIcon6     ,SetIcon6
			b NULL

;*** Menütabellen für Zahlenausgabe.
:V404o0			w V404p0 ,V404p2 ,V404p4
			w V404p6 ,V404p8

;*** Tabellen für Zahleneingabe.
:V404o1			w V404p1,V404p3,V404p5
			w V404p7,V404p9

;*** Tag.
:V404p0			w $0084
			b $76

:V404p1			w $0084
			b $70
			w GetDay
			w HEXtoASCII,ASCIItoHEX
			w ChkDay
			w SetDay

;*** Monat.
:V404p2			w $00a4
			b $76

:V404p3			w $00a4
			b $70
			w GetMonth
			w HEXtoASCII,ASCIItoHEX
			w ChkMonth
			w SetMonth

;*** Jahr.
:V404p4			w $00c4
			b $76

:V404p5			w $00c4
			b $70
			w GetYear
			w HEXtoASCII,ASCIItoHEX
			w ChkYear
			w SetYear

;*** Stunde.
:V404p6			w $0084
			b $86

:V404p7			w $0084
			b $80
			w GetHour
			w HEXtoASCII,ASCIItoHEX
			w ChkHour
			w SetHour

;*** Minute.
:V404p8			w $00a4
			b $86

:V404p9			w $00a4
			b $80
			w GetMinute
			w HEXtoASCII,ASCIItoHEX
			w ChkMinute
			w SetMinute

;*** Icontabelle.
:icon_Tab1		b 6
			w $0000
			b $00

			w icon_Exit
			b $00,$08,$05,$18
			w EndEdit

			w icon_Load
			b $05,$08,$05,$18
			w Edit_Undo

			w icon_Save
			b $0a,$08,$05,$18
			w Edit_OK

			w icon_Last
			b $0f,$08,$05,$18
			w LastEdit

			w icon_Next
			b $14,$08,$05,$18
			w Edit_Cancel

			w icon_Files
			b $19,$08,$05,$18
			w ChangeFiles

:icon_Tab1a		s 2*8

:icon_Tab1b		w icon_Drive
			b $1e,$08,$05,$18
			w ChangeDrive

:icon_Tab1c		w icon_Disk
			b $23,$08,$05,$18
			w ChangeDisk

;*** Icons.
if Sprache = Deutsch
:icon_Exit
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:icon_Exit
<MISSING_IMAGE_DATA>
endif

:icon_Load
<MISSING_IMAGE_DATA>

:icon_Save
<MISSING_IMAGE_DATA>

:icon_Last
<MISSING_IMAGE_DATA>

:icon_Next
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
:icon_Drive
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:icon_Drive
<MISSING_IMAGE_DATA>
endif

if Sprache = Deutsch
:icon_Disk
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:icon_Disk
<MISSING_IMAGE_DATA>
endif

if Sprache = Deutsch
:icon_Files
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:icon_Files
<MISSING_IMAGE_DATA>
endif

:icon_Page
<MISSING_IMAGE_DATA>

:icon_Clear
<MISSING_IMAGE_DATA>

:icon_Invert
<MISSING_IMAGE_DATA>

:icon_ToFile
<MISSING_IMAGE_DATA>

:icon_FromFile
<MISSING_IMAGE_DATA>

:EndProgrammCode
