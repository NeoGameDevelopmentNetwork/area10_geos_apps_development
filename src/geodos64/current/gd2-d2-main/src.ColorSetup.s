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

			n	"mod.#107.obj"
			o	ModStart
			r	EndAreaMenu

			jmp	ColorSetup

			t	"-CBM_SetName"

;*** Datei-Attribute ändern.
:ColorSetup		jsr	SetGDcol

			jsr	i_C_MenuTitel
			b	$00,$00,$28,$01

			FillPRec$00,$00,$07,$0008,$013f

			jsr	UseGDFont

if Sprache = Deutsch
			Print	$0008,$06
			b	PLAINTEXT,"Farben ändern",NULL
endif

if Sprache = Englisch
			Print	$0008,$06
			b	PLAINTEXT,"Change colors",NULL
endif

			LoadW	r0,ViewCurFName
			jsr	PutString

			jsr	DefSysCol
			jsr	DefColor
			jsr	DefGrafik
			jsr	DefColTab
			jsr	SetClkPos		;Optionen auf Bildschirm.

			FrameRec$20,$2f,$0000,$013f,%11111111
			jsr	i_BitmapUp
			w	Icon_20
			b	$00,$20,$02,$10

			jsr	DefOpt2a

			LoadW	r0,HelpFileName
			lda	#<ColorSetup
			ldx	#>ColorSetup
			jsr	InstallHelp

			jsr	i_C_MenuMIcon
			b	$00,$01,$28,$03
			jsr	i_ColorBox
			b	$00,$04,$02,$02,$01
			jsr	i_ColorBox
			b	$02,$04,$26,$02,$0f

			LoadW	otherPressVec,ChkOptSlct
			LoadW	r0,Icon_Tab1
			jsr	DoIcons			;Menü aktivieren.
			StartMouse
			NoMseKey
			rts

;*** Zurück zu GeoDOS.
:L107ExitGD		ClrW	otherPressVec		;Mausabfrage löschen.
			jsr	SetGDcol		;Bildschirm löschen.
			jmp	InitScreen

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

;*** Bildschirm aufbauen.
:SetClkPos		LoadW	a7,V107e0

::101			ldy	#$00
			lda	(a7L),y
			bne	:102
			ClrB	pressFlag
			rts

::102			jsr	CopyRecData		;Daten für Rechteck einlesen.

			ldy	#$07
			lda	(a7L),y
			tax
			dey
			lda	(a7L),y
			ldy	#$00
			jsr	CallRoutine		;Ausgabefeld definieren.

			jsr	CopyRecData		;Daten für Rahmen einlesen.
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

;*** Farbe für Klick-Option definieren.
:DefClkOpt		jsr	CopyRecData		;Daten für Rechteck einlesen.
			jsr	DefColOpt
			jmp	SetColOpt

;*** Prüfen ob Option angeklickt.
:ChkOptSlct		LoadB	r2L,$20
			LoadB	r2H,$2f
			LoadW	r3,$0000
			LoadW	r4,$000f
			php
			sei
			jsr	IsMseInRegion
			plp
			tax
			beq	ChkDefColArea

::101			sec				;Y-Koordinate der Maus einlesen.
			lda	mouseYPos		;Testen ob Maus innerhalb des
			sbc	#$20			;"Eselsohrs" angeklickt wurde.
			sta	r0L

			sec
			lda	mouseXPos+0
			eor	#%00001111
			cmp	r0L
			bcs	:102			;Seite vor.
			jmp	SetOpt2b
::102			jmp	SetOpt2c

:ChkDefColArea		sei

			LoadW	a7,V107e0

::121			ldy	#$00
			lda	(a7L),y			;Ende Menütabelle erreicht ?
			bne	:122			;Nein, weiter.
			jmp	SlctColItem 		;Ende.

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

;*** Wurde Demobildshirm gewählt ?
:SlctColItem		LoadW	a7,Area_Change
			jsr	CopyRecData
			jsr	IsMseInRegion
			tax
			beq	:101
			jmp	ColorSetup

::101			LoadW	a7,Area_DeskTop
			jsr	CopyRecData
			jsr	IsMseInRegion
			tax
			beq	:103

			lda	#<V107f0
			ldx	#>V107f0
			ldy	#$00
			bit	MenuMode
			bpl	:101a
			lda	#<V107f1
			ldx	#>V107f1
			ldy	#$1a
::101a			sta	a7L
			stx	a7H
			sty	curColMenu

::102			ldy	#$00
			lda	(a7L),y			;Ende Menütabelle erreicht ?
			beq	:103			;Nein, weiter.

			jsr	CopyRecData		;Werte aus Menütabelle nach ":r2".
			jsr	IsMseInRegion		;Ist Maus innerhalb eines Options-
			tax				;Icons ?
			beq	:104			;Nein, weitertesten.

			ldx	curColMenu
			lda	VecToColTab,x
			sta	curColor
			jsr	DefOpt2a

			jsr	SetClkPos		;Neuen Wert für Option anzeigen.

::103			cli
			NoMseKey
			rts

::104			inc	curColMenu
			AddVBW	6,a7
			jmp	:102

;*** Datenbildschirm löschen.
:ClrDefScreen		jsr	i_C_ColorClr
			b	$00,$06,$28,$13

			lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$40,$bf
			w	$0038,$0137
			rts

;*** Grafik zeichnen.
:DefGrafik		jsr	UseGDFont
			ClrB	currentMode

			bit	MenuMode
			bmi	:101
			jmp	DefGrafik1
::101			jmp	DefGrafik2

;*** Farbe zeichnen.
:DefColor		jsr	i_C_ColorClr
			b	$00,$06,$28,$13

			jsr	DefColTab

			bit	MenuMode
			bmi	:101
			jmp	DefColor1
::101			jmp	DefColor2

;*** Grafik zeichnen.
:DefGrafik1		LoadW	r0,V107i0
			jsr	GraphicsString

			jsr	i_BitmapUp
			w	Icon_Bubble
			b	$07,$98,$02,$18
			jsr	i_BitmapUp
			w	Icon_Mouse
			b	$07,$b0,$01,$10
			rts

;*** Farbe zeichnen.
:DefColor1		jsr	i_C_MainIcon
			b	$07,$08,$02,$02
			jsr	i_C_MainIcon
			b	$07,$0b,$02,$02
			jsr	i_C_MainIcon
			b	$07,$0e,$02,$02
			jsr	i_C_MainIcon
			b	$07,$11,$02,$02

			jsr	i_C_MenuClose
			b	$0a,$08,$01,$01
			jsr	i_C_MenuTitel
			b	$0b,$08,$1c,$01
			jsr	i_C_MenuBack
			b	$0a,$09,$1d,$0f
			jsr	i_C_MenuDIcon
			b	$1e,$0a,$02,$01
			jsr	i_C_MenuMIcon
			b	$21,$0a,$01,$01
			jsr	i_C_MenuMIcon
			b	$23,$0a,$01,$01

			jsr	i_C_DBoxClose
			b	$0b,$10,$01,$01
			jsr	i_C_DBoxTitel
			b	$0c,$10,$10,$01
			jsr	i_C_DBoxBack
			b	$0b,$11,$11,$06
			jsr	i_C_DBoxDIcon
			b	$0c,$15,$02,$01

			jsr	i_C_IBoxBack
			b	$0d,$0b,$0a,$04

			jsr	i_C_Register
			b	$1f,$0c,$04,$01
			jsr	i_C_MenuBack
			b	$13,$0d,$11,$09

			jsr	i_C_FBoxClose
			b	$14,$0e,$01,$01
			jsr	i_C_FBoxTitel
			b	$15,$0e,$0e,$01
			jsr	i_C_FBoxBack
			b	$14,$0f,$0f,$06
			jsr	i_C_FBoxDIcon
			b	$20,$13,$02,$01
			jsr	i_C_MenuTBox
			b	$15,$10,$09,$04
			jsr	i_C_Balken
			b	$1e,$10,$01,$04

			lda	C_ScreenClear
			and	#%11110000
			sta	r0L
			lda	C_Bubble
			sta	:102 +4
			and	#%00001111
			ora	r0L
			sta	:101 +4

			jsr	i_ColorBox
::101			b	$07,$13,$02,$03,$ff
			jsr	i_ColorBox
::102			b	$07,$14,$02,$01,$ff

			lda	C_Mouse
			asl
			asl
			asl
			asl
			sta	r0L
			lda	C_ScreenClear
			and	#%00001111
			ora	r0L
			sta	:103 +4

			jsr	i_ColorBox
::103			b	$07,$16,$01,$02,$ff
			rts

;*** Grafik zeichnen.
:DefGrafik2		jsr	UseSystemFont

			LoadW	r0,V107i6
			jsr	GraphicsString

			jsr	i_BitmapUp
			w	Icon_Mouse
			b	$0f,$80,$01,$10
			jsr	i_BitmapUp
			w	Icon_OK
			b	$17,$88,$06,$10
			jmp	UseGDFont

;*** Farbe zeichnen.
:DefColor2		lda	C_GEOS_FRAME
			sta	:101 +4
			jsr	i_ColorBox
::101			b	$07,$08,$20,$10,$ff
			jsr	i_C_GEOS
			b	$08,$09,$1e,$0e

			lda	C_GEOS_MOUSE
			asl
			asl
			asl
			asl
			sta	r0L
			lda	C_GEOS_BACK
			and	#%00001111
			ora	r0L
			sta	:102 +4

			jsr	i_ColorBox
::102			b	$0f,$10,$01,$02,$ff
			rts

;*** GD-Farben setzen.
:SetGDcol		jsr	InitForIO
			lda	C_ScreenBack
			and	#%00001111
			sta	$d020
			lda	C_Mouse
			sta	$d027
			jsr	DoneWithIO
			jmp	ClrScreen

;*** Farbskala zeichnen.
:DefColTab		jsr	i_C_MenuBack
			b	$01,$08,$01,$10
			jsr	i_C_MenuBack
			b	$04,$08,$01,$10
			FrameRec$40,$bf,$0008,$0027,%11111111

			LoadB	r5L,$02
			LoadB	r5H,$08
			LoadB	r6L,$02
			LoadB	r6H,$01
			lda	#$00
::101			pha
			tax
			lda	V107d0,x
			sta	r7L
			jsr	RecColorBox
			inc	r5H
			pla
			add	1
			cmp	#16
			bne	:101
			rts

;*** Farbe berechnen.
:GetColNum		ldx	#$00
::101			cmp	V107d0,x
			beq	:102
			inx
			cpx	#$10
			bne	:101

::102			rts

;*** Farbe ermitteln.
:GetColor		ldx	curColor
			lda	VecToDefTab,x
			asl
			asl
			tax
			lda	V107g0+0,x
			sta	a6L
			lda	V107g0+1,x
			sta	a6H

			ldy	#$00
			lda	(a6L),y
			pha
			lsr
			lsr
			lsr
			lsr
			sta	a5L
			pla
			and	#%00001111
			sta	a5H
			rts

;*** Systemfarben berechnen.
:DefSysCol		lda	C_GEOS_FRAME
			and	#%00001111
			sta	C_GEOS_FRAME

			lda	C_GEOS_MOUSE
			and	#%00001111
			sta	C_GEOS_MOUSE

			lda	C_ScreenClear
			and	#%00001111
			sta	C_ScreenBack
			asl
			asl
			asl
			asl
			ora	C_ScreenBack
			sta	C_ScreenClear

			lda	C_Mouse
			and	#%00001111
			sta	C_Mouse

			jsr	InitForIO
			lda	C_ScreenBack
			and	#%00001111
			sta	$d020
			jmp	DoneWithIO

;*** Farbwahl ausgeben.
:DefOpt2a		FillPRec$00,$21,$2e,$0010,$013e

			jsr	UseGDFont
			ClrB	currentMode

			ldx	curColor
			lda	VecToDefTab,x
			asl
			asl
			tax
			lda	V107g0+2,x
			sta	r0L
			lda	V107g0+3,x
			sta	r0H
			LoadW	r11,$0018
			LoadB	r1H,$2a
			jmp	PutString

;*** Menüpunkt wählen.
:SetOpt2b		jsr	StopMouseMove
::101			ldx	curColor
			bne	:102
			ldx	#24
::102			dex
			stx	curColor
			jsr	DefOpt2a
			jsr	CPU_Pause
			jsr	CPU_Pause
			jsr	CPU_Pause
			lda	mouseData
			bpl	:101
			ClrB	pressFlag
			jmp	DefOpt2d

:SetOpt2c		jsr	StopMouseMove
::101			ldx	curColor
			inx
			cpx	#24
			bne	:102
			ldx	#0
::102			stx	curColor
			jsr	DefOpt2a
			jsr	CPU_Pause
			jsr	CPU_Pause
			jsr	CPU_Pause
			lda	mouseData
			bpl	:101
			ClrB	pressFlag

:DefOpt2d		lda	MenuMode
			pha
			lda	#$00
			ldx	curColor
			cpx	#21
			bcc	:101
			lda	#$ff
::101			sta	MenuMode
			pla
			cmp	MenuMode
			beq	:102
			jsr	ClrDefScreen
			jsr	DefColor
			jsr	DefGrafik

::102			ldx	#$05
::103			lda	Area_Mouse,x
			sta	mouseTop  ,x
			dex
			bpl	:103

			jsr	DefOpt3a
			jsr	DefOpt3b
			jmp	CPU_Pause

;*** Farbtabelle ausgeben.
:DefOpt3a		Pattern	0
			FillRec	$41,$be,$0009,$000e
			ldx	#$0b
			ldy	#a5L
			jmp	DefOpt3c

:DefOpt3b		Pattern	0
			FillRec	$41,$be,$0021,$0026
			ldx	#$23
			ldy	#a5H

:DefOpt3c		sty	:101 +1
			stx	r3L
			inx
			stx	r4L
			lda	#$00
			sta	r3H
			sta	r4H

			Pattern	1
			jsr	GetColor

::101			lda	a5H
			jsr	GetColNum
			txa
			asl
			asl
			asl
			add	$42
			sta	r2L
			add	3
			sta	r2H
			jmp	Rectangle

;*** neue Farbe setzen.
:SetOpt3a		lda	#$00
			b $2c

:SetOpt3b		lda	#$01
			pha
			lda	mouseYPos
			lsr
			lsr
			lsr
			sub	8

			pha
			jsr	GetColor
			pla

			tay
			pla
			tax
			lda	V107d0,y
			cpx	#$00
			bne	:101
			asl
			asl
			asl
			asl
::101			sta	a4L

			ldy	#$00
			lda	(a6L),y
			cpx	#$00
			bne	:102
			and	#%00001111
			jmp	:103

::102			and	#%11110000
::103			ora	a4L
			sta	(a6L),y
			jsr	DefSysCol
			jmp	DefColor

;*** Anzeigen der GeoDOS-Farbdateien.
:ViewColFiles		jsr	LookColFiles
			txa
			bne	:101
			lda	FileNTab
			bne	:102
::101			jsr	OpenUsrDrive		;Laufwerk zurücksetzen.
			jmp	ColorSetup		;Zurück zum Setup.

::102			lda	#$00
			sta	r15H
			lda	ColFileVec
			asl
			asl	r15L
			asl
			asl	r15H
			asl
			asl	r15H
			asl
			asl	r15H
			clc
			adc	#<FileNTab
			sta	r15L
			lda	r15H
			adc	#>FileNTab
			sta	r15H

			ldy	#$00
			lda	(r15L),y
			bne	:103
			sta	ColFileVec
			beq	:102

::103			inc	ColFileVec

			LoadW	r14,CurColFileNm
			ldx	#r15L
			ldy	#r14L
			lda	#16
			jsr	CmpFString
			bne	:104

			ldy	#16
			lda	(r15L),y
			bne	:102
			ldx	ColFileVec
			sta	ColFileVec
			cpx	#$01
			beq	:101
			bne	:102

::104			ldx	#r15L
			ldy	#r14L
			lda	#16
			jsr	CopyFString

			jsr	PrepGetFile

			LoadB	r0L,%00000001
			LoadW	r6,CurColFileNm
			LoadW	r7,colSystem
			jsr	GetFile			;Datei einlesen.
			txa				;Diskettenfehler ?
			beq	:101
			jmp	Exit_IO_Error		;Diskettenfehler.

;*** GeoDOS-Farben ändern.
:DefGD_Col		lda	#0
			b $2c

;*** GEOS-Farben ändern.
:DefGEOS_Col		lda	#21
			sta	curColor
			jsr	DefOpt2a
			jmp	DefOpt2d

;*** "COLOR.INI"-Datei sichern.
:SaveColPref		jsr	SetGDcol		;GeoDOS-Farben zurücksetzen.

			jsr	DoInfoBox		;Info: "Speichere COLOR.INI..."
			PrintStrgV107c2

			jsr	OpenSysDrive		;Start-Laufwerk aktivieren.
			txa				;Diskettenfehler ?
			beq	:102			;Nein, weiter...
::101			jmp	GDDiskError		;Systemfehler.

::102			LoadW	r0,V107b5		;Datei "COLOR.INI" löschen.
			jsr	DeleteFile
			txa
			beq	:103
			cpx	#$05
			beq	:103
			jmp	Exit_IO_Error		;Diskettenfehler, Abbruch.

::103			LoadW	HdrB000,V107b5		;Datei "COLOR.INI" speichern.
			jmp	SaveCurFile

;*** Standard-GEOS-Farben erzeugen.
:ResetColPref		jsr	i_MoveData
			w	OrgColData
			w	colSystem
			w	(EndOrgCol-OrgColData)
			jmp	ColorSetup

;*** Parameter speichern.
:SaveColor		jsr	SetGDcol		;GeoDOS-Farben zurücksetzen.

			LoadW	V107a1,V107b3		;Auswahltabelle mit Farbdateien um
			jsr	GetColFile		;Dateiname zu wählen.
			txa
			beq	OverWriteCol		; -> Datei-Update.
			bpl	GetColFileNam		; -> Neuen Namen eingeben.

			CmpBI	r13L,$01		;"OK" gewählt ?
			beq	GetColFileNam		;Ja, neuen Namen eingeben.

:BackToColSet		jsr	OpenUsrDrive		;Laufwerk zurücksetzen.
			jmp	ColorSetup		;Zurück zum Setup.

:OverWriteCol		LoadW	r0,V107b1
			jsr	DeleteFile		;Gewählte Datei auf Diskette löschen.
			txa				;Diskettenfehler ?
			beq	OverWriteCol		;Nein, nochmal löschen.
			cpx	#$05			;"File not found" ?
			bne	Exit_IO_Error		;Nein, Diskettenfehler.
			jmp	SaveColFile		;Update der Farbdatei speichern.

:Exit_IO_Error		pha				;Fehler-Nr. merken.
			jsr	OpenUsrDrive		;Laufwerk zurücksetzen.
			pla
			tax				;Diskettenfehler einlesen und
			jmp	DiskError		;anzeigen.

;*** Dateiname eingeben.
:GetColFileNam		LoadW	r0,V107b0		;Dateiname eingeben.
			LoadW	r1,V107b1
			LoadB	r2L,$00
			LoadB	r2H,$ff
			LoadW	r3,V107b3
			jsr	cbmSetName
			cmp	#$01			;"OK" ?
			bne	BackToColSet		;Nein, zurück zum Setup.

			lda	V107b1			;Gültiger Dateiname ?
			beq	BackToColSet		;Nein, zurück zum Setup.

;*** Farbdatei suchen.
:LookColFile		LoadW	r6,V107b1
			jsr	FindFile		;Farbdatei suchen.
			cpx	#$05
			beq	SaveColFile		;Nicht gefunden, weiter...
			cpx	#$00			;Diskettenfehler ?
			bne	Exit_IO_Error		;Ja, Abbruch.

			DB_UsrBoxV107c0			;"Datei überschreiben ?"
			CmpBI	sysDBData,3		;"Ja" gewählt ?
			bne	GetColFileNam		;Nein, neuen Namen eingeben.

			LoadW	r0,V107b1
			jsr	DeleteFile		;Alte Datei auf Diskette löschen.
			txa				;Diskettenfehler ?
			bne	Exit_IO_Error		;Ja, Abbruch.
			jmp	LookColFile

;*** Farbdaten speichern.
:SaveColFile		LoadW	HdrB000,V107b1
:SaveCurFile		LoadW	r9,HdrB000
			LoadB	r10L,$00
			jsr	SaveFile		;Farbdatei auf Diskette sichern.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch.

			jsr	OpenUsrDrive		;Laufwerk zurücksetzen.
			jmp	ColorSetup		;Zurück zum Setup.

::101			jmp	Exit_IO_Error		;Diskettenfehler.

;*** Parameter einlesen.
:LoadColor		jsr	SetGDcol		;GeoDOS-Farben zurücksetzen.

			LoadW	V107a1,V107b4		;Auswahltabelle mit Farbdateien um
			jsr	GetColFile		;Dateiname zu wählen.
			txa
			beq	:103			; -> Datei laden.
			bmi	:102			; -> Abbruch.

::101			DB_OK	V107c1			;Fehler: "Keine Dateien auf Diskette!"

::102			jsr	OpenUsrDrive		;Laufwerk zurücksetzen.
			jmp	ColorSetup		;Zurück zum Setup.

::103			LoadW	r14,CurColFileNm
			ldx	#r15L
			ldy	#r14L
			lda	#16
			jsr	CopyFString

			LoadB	r0L,%00000001
			LoadW	r6,CurColFileNm
			LoadW	r7,colSystem
			jsr	GetFile			;Datei einlesen.
			txa				;Diskettenfehler ?
			beq	:102			;Nein, Ende.

			jmp	Exit_IO_Error		;Diskettenfehler.

;*** Parameterdatei auswählen.
:GetColFile		jsr	LookColFiles

			lda	#<V107a0
			ldx	#>V107a0
			jsr	SelectBox

			ldx	r13L
			beq	:104
			ldx	#$ff			;Abbruch.
			rts

::104			ldy	#$0f			;Gewählte Datei in
::105			lda	(r15L),y		;Zwischenspeicher.
			sta	V107b1,y
			dey
			bpl	:105

			ldx	#$00			;"OK".
			rts

;*** Liste mit Farbdateien einlesen.
:LookColFiles		jsr	OpenSysDrive		;Start-Laufwerk aktivieren.
			txa				;Diskettenfehler ?
			beq	:102			;Nein, weiter...
::101			jmp	GDDiskError		;Systemfehler.

::102			jsr	i_FillRam		;Speicher löschen.
			w	17*256
			w	FileNTab
			b	$00

			LoadW	a9,FileNTab

			lda	#DATA
			ldx	#<V107b2
			ldy	#>V107b2
			jsr	GetFileList		;Farbdateien einlesen.

			lda	FileNTab
			bne	:103
			ldx	#$7f
			rts
::103			ldx	#$00
			rts

;*** Farbdefinitionsdateien einlesen.
:GetFileList		LoadW	r6,FileNTab
			LoadB	r7L,DATA
			LoadB	r7H,255
			LoadW	r10,V107b2
			jsr	FindFTypes
			txa
			beq	:102
::101			rts				;Disketten-Fehler, keine Dateien.

::102			CmpBI	r7H,255			;Dateien gefunden ?
			bne	:104			;Ja, Tabelle generieren.
::103			rts

::104			lda	a9L			;Dateinamen der gefundenen Einträge
			sta	r0L			;in 16-Byte-Format wandeln.
			sta	r1L
			lda	a9H
			sta	r0H
			sta	r1H

::105			CmpBI	r7H,255
			beq	:107

			ldy	#0
::106			lda	(r0L),y			;GEOS 17 Zeichen nach
			sta	(r1L),y			;GeoDOS 16 Zeichen.
			iny
			cpy	#16
			bne	:106

			AddVBW	17,r0
			AddVBW	16,r1

			inc	r7H
			jmp	:105

::107			ldy	#0			;Ende der Tabelle merkieren
			tya
			sta	(r1L),y
			rts

;*** Variablen.
:HelpFileName		b "09,GDH_System",NULL
:ViewCurFName		b GOTOXY
			w $00a8
			b $06
			b ">>                <<"
			b GOTOX
			w $00b8
:CurColFileNm		b "COLOR.INI",0,0,0,0,0,0,0,0

:curColor		b $00
:curColMenu		b $00
:MenuMode		b $00
:ColFileVec		b $00

;*** Farbdateien einlesen.
:V107a0			b $ff
			b $00
			b $00
			b $10
			b $00
:V107a1			w V107b4
			w FileNTab

;*** Info-Block für Parameter-Textdatei.
:HdrB000		w V107b1
			b $03,$15
			j
<MISSING_IMAGE_DATA>
			b $83
			b DATA
			b SEQUENTIAL
			w colSystem
			w colSystem + 25
			w colSystem
			b "GD_Color    V"		;Klasse.
			b "2.0"				;Version.
			s $04				;Reserviert.
			b "GeoDOS 64"			;Autor.
:HdrEnd			s (HdrB000+161)-HdrEnd

:V107b0			s 17				;Zwischenspeicher Dateiname.
:V107b1			s 17				;Zwischenspeicher Dateiname.
:V107b2			b "GD_Color    V2.0",NULL

if Sprache = Deutsch
:V107b3			b PLAINTEXT,"Farbdaten speichern",NULL
:V107b4			b PLAINTEXT,"Farbdaten laden",NULL
:V107b5			b "COLOR.INI",NULL

;*** Fehler: "Keine Tabellen auf Start-Diskette!"
:V107c0			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Diese Datei existiert bereits!",NULL
::102			b        "Vorhandene Datei ersetzen ?",NULL

:V107c1			w :101, :102, ISet_Achtung
::101			b BOLDON,"Keine Farbtabellen auf",NULL
::102			b        "Systemdiskette!",NULL

;*** Info: "Verzeichnis wird eingelesen."
:V107c2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Systemdatei 'COLOR.INI'"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "wird gespeichert..."
			b NULL
endif

if Sprache = Englisch
:V107b3			b PLAINTEXT,"Save color-sheme",NULL
:V107b4			b PLAINTEXT,"Load color-sheme",NULL
:V107b5			b "COLOR.INI",NULL

;*** Fehler: "Keine Tabellen auf Start-Diskette!"
:V107c0			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"This file always exist!",NULL
::102			b        "Replace existing file?",NULL

:V107c1			w :101, :102, ISet_Achtung
::101			b BOLDON,"No color-shemes found",NULL
::102			b        "on disk!",NULL

;*** Info: "Verzeichnis wird eingelesen."
:V107c2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Systemfile 'COLOR.INI'"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "will be updated..."
			b NULL
endif

;*** Mausabfragebereiche.
:Area_DeskTop		b $30,$c7
			w $0000,$013f
:Area_Screen		b $40,$bf
			w $0008,$0027
:Area_Change		b $00,$07
			w $0000,$013f
:Area_Mouse		b $00,$c7
			w $0000,$013f

;*** Farbwerte für Farbskala.
:V107d0			b $01,$0f,$0c,$0b,$00,$09,$08,$07
			b $0a,$02,$04,$06,$0e,$03,$05,$0d

;*** Datenliste für "Klick-Positionen".
:V107e0			b $40,$bf
			w $0010,$0017,DefOpt3a,SetOpt3a
			b $40,$bf
			w $0018,$001f,DefOpt3b,SetOpt3b
			b NULL

;*** Systemfarben.
:OrgColData		b $05				;Hintergrund.
			b $55				;Hintergrund ohne Vordergrund!
			b $0f				;Dialogbox.
			b $0d				;Textfenster.
			b $0d				;Icons.
			b $0d				;System-Icons.
			b $01				;Close-Icon.
			b $12				;Titel-Zeile.
			b $03				;Scrollbalken.
			b $16				;Karteikarten.
			b $07				;Bubble-Farbe.
			b $06				;Mausfarbe.
			b $01				;Dialogbox: Close-Icon.
			b $12				;Dialogbox: Titel.
			b $0f				;Dialogbox: Hintergrund + Text.
			b $01				;Dialogbox: System-Icons.
			b $03				;Infobox  : Hintergrund + Text.
			b $01				;Dateiauswahlbox: Close-Icon.
			b $12				;Dateiauswahlbox: Titel.
			b $0f				;Dateiauswahlbox: Hintergrund + Text.
			b $01				;Dateiauswahlbox: System-Icons.
			b $01				;Icons Hauptmenü.
			b $bf				;Hintergrund: Farbe GEOS-Standard-Applikationen.
			b $00				;Rahmen     : Farbe GEOS-Standard-Applikationen.
			b $06				;Mauszeiger : Farbe GEOS-Standard-Applikationen.
:EndOrgCol		b $00

;*** Dateiauswahlboxbereiche.
:V107f0			b $98,$9f			;System-Icon.
			w $0100,$010f
			b $80,$9f			;Scroll-Balken.
			w $00f0,$00f7
			b $80,$9f			;Dateifenster.
			w $00a8,$00f7
			b $70,$77			;CLOSE-Icon.
			w $00a0,$00a7
			b $70,$77			;Titelzeile.
			w $00a8,$0117
			b $78,$a7			;Dateiauswahlbox.
			w $00a0,$0117

;*** Karteikartenbereiche.
			b $68,$af			;Karte.
			w $0098,$011f
			b $60,$67			;Register.
			w $00f8,$0117

;*** Systemboxbereiche.
			b $a7,$af			;System-Icon.
			w $0060,$006f
			b $80,$87			;CLOSE-Icon.
			w $0058,$005f
			b $80,$87			;Titelzeile.
			w $0060,$00df
			b $88,$b7			;Systembox.
			w $0058,$00df

;*** Infoboxbereiche.
			b $58,$77			;Infobox.
			w $0068,$00b7

;*** Menüboxbereiche.
			b $50,$57			;Icon.
			w $0108,$010f
			b $50,$57			;Icon.
			w $0118,$011f
			b $50,$57			;System-Icons..
			w $00f0,$00ff
			b $40,$47			;CLOSE-Icon.
			w $0050,$0057
			b $40,$47			;Titelzeile.
			w $0058,$0137
			b $48,$bf			;Menübox..
			w $0050,$0137

;*** Systemboxbereiche.
			b $40,$4f			;Icon #1.
			w $0038,$0047
			b $58,$67			;Icon #2.
			w $0038,$0047
			b $70,$7f			;Icon #3.
			w $0038,$0047
			b $88,$97			;Icon #4.
			w $0038,$0047
			b $9d,$ac			;Bubbles.
			w $0038,$0047
			b $b0,$bf			;Mauszeiger.
			w $0038,$003f
			b $30,$c7			;Hintergrund.
			w $0000,$013f

			b NULL

;*** GEOS-Standardbereiche.
:V107f1			b $80,$8f			;Mauszeiger.
			w $0078,$007f
			b $48,$b7			;Hintergrund.
			w $0040,$012f
			b $40,$bf			;Rahmen.
			w $0038,$0137

			b NULL

;*** Farbbereiche.
:V107g0			w C_FBoxDIcon,V107h33		;$00
			w C_Balken,V107h35		;$01
			w C_MenuTBox,V107h34		;$02
			w C_FBoxClose,V107h31		;$03
			w C_FBoxTitel,V107h32		;$04
			w C_FBoxBack,V107h30		;$05

			w C_MenuBack,V107h10		;$06
			w C_Register,V107h15		;$07

			w C_DBoxDIcon,V107h23		;$08
			w C_DBoxClose,V107h21		;$09
			w C_DBoxTitel,V107h22		;$0a
			w C_DBoxBack,V107h20		;$0b

			w C_IBoxBack,V107h40		;$0c

			w C_MenuMIcon,V107h13		;$0d
			w C_MenuMIcon,V107h13		;$0e
			w C_MenuDIcon,V107h14		;$0f
			w C_MenuClose,V107h11		;$10
			w C_MenuTitel,V107h12		;$11
			w C_MenuBack,V107h10		;$12

			w C_MainIcon,V107h1			;$13
			w C_MainIcon,V107h1			;$14
			w C_MainIcon,V107h1			;$15
			w C_MainIcon,V107h1			;$16
			w C_Bubble,V107h50		;$17
			w C_Mouse,V107h51		;$18
			w C_ScreenClear,V107h0			;$19

			w C_GEOS_MOUSE,V107h60		;$1a
			w C_GEOS_BACK,V107h61		;$1b
			w C_GEOS_FRAME,V107h62		;$1c

;*** Zeiger auf Definitionstabelle.
:VecToDefTab		b $19,$16
			b $12,$10,$11,$0d,$0f,$07
			b $0b,$09,$0a,$08
			b $05,$03,$04,$00,$02,$01
			b $0c
			b $17,$18
			b $1a,$1b,$1c

;*** Zeiger auf Farbtabelle.
:VecToColTab		b $0f,$11,$10,$0d,$0e,$0c
			b $02,$07
			b $0b,$09,$0a,$08
			b $12
			b $05,$05,$06,$03,$04,$02
			b $01,$01,$01,$01,$13,$14,$00
			b $15,$16,$17

if Sprache = Deutsch
;*** Menütexte.
:V107h0			b "00 DeskTop",GOTOXY,$a0,$00,$2a ,"=> Hintergrund"	,NULL
:V107h1			b "01 DeskTop",GOTOXY,$a0,$00,$2a ,"=> Menü-Icons"	,NULL

:V107h10		b "02 Menüfenster"									,GOTOXY,$a0,$00,$2a ,"=> Hintergrund"	,NULL
:V107h11		b "03 Menüfenster"									,GOTOXY,$a0,$00,$2a ,"=> CLOSE-Icon"	,NULL
:V107h12		b "04 Menüfenster"									,GOTOXY,$a0,$00,$2a ,"=> Titelzeile"	,NULL
:V107h13		b "05 Menüfenster"									,GOTOXY,$a0,$00,$2a ,"=> Icons"	,NULL
:V107h14		b "06 Menüfenster"									,GOTOXY,$a0,$00,$2a ,"=> System-Icon"	,NULL
:V107h15		b "07 Menüfenster"									,GOTOXY,$a0,$00,$2a ,"=> Register"	,NULL

:V107h20		b "08 Dialogbox"									,GOTOXY,$a0,$00,$2a ,"=> Fenster"	,NULL
:V107h21		b "09 Dialogbox"									,GOTOXY,$a0,$00,$2a ,"=> CLOSE-Icon"	,NULL
:V107h22		b "10 Dialogbox"									,GOTOXY,$a0,$00,$2a ,"=> Titelzeile"	,NULL
:V107h23		b "11 Dialogbox"									,GOTOXY,$a0,$00,$2a ,"=> System-Icon"	,NULL

:V107h30		b "12 Dateiauswahlbox"									,GOTOXY,$a0,$00,$2a ,"=> Fenster"	,NULL
:V107h31		b "13 Dateiauswahlbox"									,GOTOXY,$a0,$00,$2a ,"=> CLOSE-Icon"	,NULL
:V107h32		b "14 Dateiauswahlbox"									,GOTOXY,$a0,$00,$2a ,"=> Titelzeile"	,NULL
:V107h33		b "15 Dateiauswahlbox"									,GOTOXY,$a0,$00,$2a ,"=> System-Icon"	,NULL
:V107h34		b "16 Dateiauswahlbox"									,GOTOXY,$a0,$00,$2a ,"=> Textfenster"	,NULL
:V107h35		b "17 Dateiauswahlbox"									,GOTOXY,$a0,$00,$2a ,"=> Scrollbalken"	,NULL

:V107h40		b "18 Infobox" 			,NULL

:V107h50		b "19 Bubbles" 			,NULL
:V107h51		b "20 Mauszeiger"									 			,NULL

:V107h60		b "21 GEOS-Standard"									,GOTOXY,$a0,$00,$2a ,"=> Mauszeiger"	,NULL
:V107h61		b "22 GEOS-Standard"									,GOTOXY,$a0,$00,$2a ,"=> Hintergrund"	,NULL
:V107h62		b "23 GEOS-Standard"									,GOTOXY,$a0,$00,$2a ,"=> Rahmen"	,NULL
endif

if Sprache = Englisch
;*** Menütexte.
:V107h0			b "00 DeskTop",GOTOXY,$a0,$00,$2a ,"=> Background"	,NULL
:V107h1			b "01 DeskTop",GOTOXY,$a0,$00,$2a ,"=> Menuicons"	,NULL

:V107h10		b "02 Menuwindow"									,GOTOXY,$a0,$00,$2a ,"=> Background"	,NULL
:V107h11		b "03 Menuwindow"									,GOTOXY,$a0,$00,$2a ,"=> CLOSE-Icon"	,NULL
:V107h12		b "04 Menuwindow"									,GOTOXY,$a0,$00,$2a ,"=> Topline"	,NULL
:V107h13		b "05 Menuwindow"									,GOTOXY,$a0,$00,$2a ,"=> Icons"	,NULL
:V107h14		b "06 Menuwindow"									,GOTOXY,$a0,$00,$2a ,"=> Systemicon"	,NULL
:V107h15		b "07 Menuwindow"									,GOTOXY,$a0,$00,$2a ,"=> Register"	,NULL

:V107h20		b "08 Dialogbox"									,GOTOXY,$a0,$00,$2a ,"=> Window"	,NULL
:V107h21		b "09 Dialogbox"									,GOTOXY,$a0,$00,$2a ,"=> CLOSE-Icon"	,NULL
:V107h22		b "10 Dialogbox"									,GOTOXY,$a0,$00,$2a ,"=> Topline"	,NULL
:V107h23		b "11 Dialogbox"									,GOTOXY,$a0,$00,$2a ,"=> Systemicon"	,NULL

:V107h30		b "12 File-selector"									,GOTOXY,$a0,$00,$2a ,"=> Window"	,NULL
:V107h31		b "13 File-selector"									,GOTOXY,$a0,$00,$2a ,"=> CLOSE-Icon"	,NULL
:V107h32		b "14 File-selector"									,GOTOXY,$a0,$00,$2a ,"=> Topline"	,NULL
:V107h33		b "15 File-selector"									,GOTOXY,$a0,$00,$2a ,"=> Systemicon"	,NULL
:V107h34		b "16 File-selector"									,GOTOXY,$a0,$00,$2a ,"=> Textwindow"	,NULL
:V107h35		b "17 File-selector"									,GOTOXY,$a0,$00,$2a ,"=> Movebar"	,NULL

:V107h40		b "18 Infobox" 			,NULL

:V107h50		b "19 Bubbles" 			,NULL
:V107h51		b "20 Mousearrow"									 			,NULL

:V107h60		b "21 GEOS-Standard"									,GOTOXY,$a0,$00,$2a ,"=> Mousearrow"	,NULL
:V107h61		b "22 GEOS-Standard"									,GOTOXY,$a0,$00,$2a ,"=> Background"	,NULL
:V107h62		b "23 GEOS-Standard"									,GOTOXY,$a0,$00,$2a ,"=> Frame"	,NULL
endif

;*** Hauptmenü-Icons.
:V107i0			b NEWPATTERN,$01

			b MOVEPENTO			;Menü-Icon #1.
			w $0038
			b $40
			b FRAME_RECTO
			w $0047
			b $4f
			b MOVEPENTO			;Menü-Icon #1.
			w $003c
			b $44
			b RECTANGLETO
			w $0043
			b $4b

			b MOVEPENTO			;Menü-Icon #2.
			w $0038
			b $58
			b FRAME_RECTO
			w $0047
			b $67
			b MOVEPENTO			;Menü-Icon #1.
			w $003c
			b $5c
			b RECTANGLETO
			w $0043
			b $63

			b MOVEPENTO			;Menü-Icon #3.
			w $0038
			b $70
			b FRAME_RECTO
			w $0047
			b $7f
			b MOVEPENTO			;Menü-Icon #1.
			w $003c
			b $74
			b RECTANGLETO
			w $0043
			b $7b

			b MOVEPENTO			;Menü-Icon #4.
			w $0038
			b $88
			b FRAME_RECTO
			w $0047
			b $97
			b MOVEPENTO			;Menü-Icon #1.
			w $003c
			b $8c
			b RECTANGLETO
			w $0043
			b $93

;*** Menübox.
:V107i1			b MOVEPENTO			;CLOSE-Icon.
			w $0050
			b $40
			b FRAME_RECTO
			w $0057
			b $47
			b MOVEPENTO
			w $0052
			b $43
			b FRAME_RECTO
			w $0055
			b $44

			b MOVEPENTO
			w $0050
			b $48
			b FRAME_RECTO
			w $0137
			b $bf

			b MOVEPENTO			;Icon #1.
			w $0108
			b $50
			b FRAME_RECTO
			w $010f
			b $57

			b MOVEPENTO			;Icon #2.
			w $0118
			b $50
			b FRAME_RECTO
			w $011f
			b $57

			b ESC_PUTSTRING
			w $005c
			b $46

if Sprache = Deutsch
			b "TITEL"
endif

if Sprache = Englisch
			b "TITLE"
endif

			b GOTOXY
			w $00f1
			b $56
			b "OK"

			b GOTOXY
			w $00c8
			b $62
			b "Text"

			b ESC_GRAPHICS

;*** Systeminfobox.
:V107i2			b MOVEPENTO			;CLOSE-Icon.
			w $0058
			b $80
			b FRAME_RECTO
			w $005f
			b $87
			b MOVEPENTO
			w $005a
			b $83
			b FRAME_RECTO
			w $005d
			b $84

			b MOVEPENTO			;Dateiauswahlbox..
			w $0058
			b $88
			b FRAME_RECTO
			w $00df
			b $b7

			b ESC_PUTSTRING
			w $0064
			b $86
			b "System"

			b GOTOXY
			w $0061
			b $ae
			b "OK"

			b GOTOXY
			w $0064
			b $96
			b "Text"

			b ESC_GRAPHICS

;*** Infobox.
:V107i3			b MOVEPENTO			;Dateiauswahlbox..
			w $0068
			b $58
			b FRAME_RECTO
			w $00b7
			b $77

			b MOVEPENTO			;Dateiauswahlbox..
			w $006a
			b $5a
			b FRAME_RECTO
			w $00b5
			b $75

			b MOVEPENTO			;Dateiauswahlbox..
			w $006b
			b $5b
			b FRAME_RECTO
			w $00b4
			b $74

			b ESC_PUTSTRING
			w $0074
			b $68
			b "Info"

			b ESC_GRAPHICS

;*** Karteikarte.
:V107i4			b MOVEPENTO			;Karteikarte.
			w $0098
			b $68
			b FRAME_RECTO
			w $011f
			b $af

			b NEWPATTERN,$00
			b MOVEPENTO
			w $0099
			b $69
			b RECTANGLETO
			w $011e
			b $ae

			b ESC_PUTSTRING
			w $00f9
			b $66
			b "MENU"

			b ESC_GRAPHICS

;*** Dateiauswahlbox.
:V107i5			b MOVEPENTO			;CLOSE-Icon.
			w $00a0
			b $70
			b FRAME_RECTO
			w $00a7
			b $77
			b MOVEPENTO
			w $00a2
			b $73
			b FRAME_RECTO
			w $00a5
			b $74

			b MOVEPENTO			;Dateiauswahlbox..
			w $00a0
			b $78
			b FRAME_RECTO
			w $0117
			b $a7

			b NEWPATTERN,$00
			b MOVEPENTO			;Dateiauswahlbox..
			w $00a1
			b $79
			b RECTANGLETO
			w $0116
			b $a6

			b MOVEPENTO			;Dateifenster.
			w $00a7
			b $7f
			b FRAME_RECTO
			w $00f8
			b $a0

			b MOVEPENTO			;Scroll-Up-Icon.
			w $00f0
			b $80
			b FRAME_RECTO
			w $00f7
			b $87
			b MOVEPENTO
			w $00f3
			b $82
			b FRAME_RECTO
			w $00f4
			b $85

			b NEWPATTERN,$01		;Scroll-Bar-Icon.
			b MOVEPENTO
			w $00f0
			b $8c
			b RECTANGLETO
			w $00f7
			b $94

			b MOVEPENTO			;Scroll-Down-Icon.
			w $00f0
			b $98
			b FRAME_RECTO
			w $00f7
			b $9f
			b MOVEPENTO
			w $00f3
			b $9a
			b FRAME_RECTO
			w $00f4
			b $9d

if Sprache = Deutsch
			b ESC_PUTSTRING
			w $00ac
			b $76
			b "Dateiauswahl"

			b GOTOXY
			w $00b2
			b $8a
			b "DATEIEN"
endif

if Sprache = Englisch
			b ESC_PUTSTRING
			w $00ac
			b $76
			b "Select files"

			b GOTOXY
			w $00b2
			b $8a
			b "Files"
endif

			b GOTOXY
			w $0101
			b $9e
			b "OK"

			b NULL

;*** Dateiauswahlbox.
:V107i6			b NEWPATTERN,$02
			b MOVEPENTO
			w $0040
			b $48
			b RECTANGLETO
			w $012f
			b $b7
			b FRAME_RECTO
			w $0040
			b $48

			b NEWPATTERN,$00
			b MOVEPENTO
			w $0040
			b $48
			b RECTANGLETO
			w $00bf
			b $55
			b FRAME_RECTO
			w $0040
			b $48

			b MOVEPENTO
			w $0068
			b $60
			b RECTANGLETO
			w $00ef
			b $9f
			b FRAME_RECTO
			w $0068
			b $60

			b ESC_PUTSTRING
			w $0042
			b $51
			b BOLDON

if Sprache = Deutsch
			b "GEOS  Datei  Verlassen"
endif

if Sprache = Englisch
			b "GEOS  File   Exit"
endif

			b PLAINTEXT

			b ESC_GRAPHICS
			b MOVEPENTO
			w $0060
			b $48
			b LINETO
			w $0060
			b $55

			b MOVEPENTO
			w $0085
			b $48
			b LINETO
			w $0085
			b $55

			b NULL

;*** Icontabelle.
:Icon_Tab1		b 8
			w $0000
			b $00

			w Icon_Exit
			b $00,$08,$05,$18
			w L107ExitGD

			w Icon_14
			b $05,$08,$05,$18
			w DefGD_Col

			w Icon_15
			b $0a,$08,$05,$18
			w DefGEOS_Col

			w Icon_12
			b $0f,$08,$05,$18
			w SaveColPref

			w Icon_13
			b $14,$08,$05,$18
			w ResetColPref

			w Icon_10
			b $19,$08,$05,$18
			w SaveColor

			w Icon_11
			b $1e,$08,$05,$18
			w LoadColor

			w Icon_16
			b $23,$08,$05,$18
			w ViewColFiles

;*** Icons.
if Sprache = Deutsch
:Icon_Exit
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_Exit
<MISSING_IMAGE_DATA>
endif

:Icon_Bubble
<MISSING_IMAGE_DATA>

:Icon_Mouse
<MISSING_IMAGE_DATA>

:Icon_10
<MISSING_IMAGE_DATA>

:Icon_11
<MISSING_IMAGE_DATA>

:Icon_12
<MISSING_IMAGE_DATA>

:Icon_13
<MISSING_IMAGE_DATA>

:Icon_14
<MISSING_IMAGE_DATA>

:Icon_15
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
:Icon_16
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_16
<MISSING_IMAGE_DATA>
endif

:Icon_20
<MISSING_IMAGE_DATA>
