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

			n	"mod.#104.obj"
			o	ModStart
			r	EndAreaCBM

			jmp	NewScreen

			t	"-MenuIcon1"
			t	"-MenuIcon2"
			t	"-MenuIcon3"
			t	"-FontType2"
			t	"-TestMseArea"

;*** L104: Bildschirm aufbauen.
:NewScreen		jsr	SetGDScrnCol		;GeoDOS-Farben setzen.
			jsr	ClrScreen		;Bildschirm löschen.
			jsr	PrintStatus		;Statuszeile ausgeben.

			jsr	SetSlctPart		;Partitionsabfrage installieren.
			jsr	SetBubbles		;Bubble-Modus installieren.
			jsr	SetSlctDrv		;Laufwerksabfrage installieren.
			jsr	SetMKey2Mode		;Mittlere Maustaste installieren.
			jsr	SetDnD			;Drag'n'Drop.

			bit	ToolBoxInMem		;Toolbox im Speicher ?
			bmi	:101			;Ja, weiter...
			jsr	LoadToolBox		;Toolbox laden.
::101			jsr	PrintToolBar		;Toolbox auf Bildschirm ausgeben.

			jsr	InitIcons		;Hauptmenü-Icons installieren.

;*** Menüs aufbauen.
:InitMainMenu		ldx	#$ff			;Zurück zur MainLoop.
			txs
			lda	#>MainLoop -1
			pha
			lda	#<MainLoop -1
			pha

			sei				;IRQ sperren.

			jsr	UseSystemFont		;Systemzeichensatz aktivieren.
			Display	ST_WR_FORE		;Nur Vordergrundgrafik.

			jsr	ResetGEOS		;GEOS-Variablen löschen.
			jsr	ResetGeoDOS		;GeoDOS-Werte initialisieren.
			jsr	ConfigHelp		;Hilfefunktion installieren.

			bit	CBM_Install		;Farbe für CBM-Icon ausgeben.
			bpl	:101
			jsr	i_C_MainIcon
			b	$04,$00,$05,$04

::101			bit	DOS_Install		;Farbe für DOS-Icon ausgeben.
			bpl	:102
			jsr	i_C_MainIcon
			b	$04,$06,$05,$04

::102			bit	CopyInstall		;Farbe für Copy-Icon ausgeben.
			bpl	:103
			jsr	i_C_MainIcon
			b	$04,$0c,$05,$04

::103			jsr	i_C_MainIcon		;Farbe für Setup-Icon ausgeben.
			b	$04,$12,$05,$04

			PushW	mouseXPos		;Mausposition speichern.
			PushB	mouseYPos

			jsr	i_C_MenuMIcon		;Farbe für EXIT!-Icon ausgeben.
			b	$01,$00,$02,$02

			LoadW	r0,Icon_Tab1
			jsr	DoIcons			;Menü starten.

			lda	curMenu			;Hauptmenü ?
			beq	:104			;Ja, weiter...
			jsr	CreateMenu		;Aktuelles Menü zeichnen.
			jsr	PrnIconTab		;Untermenü-Icons auf Bildschirm.

::104			pla				;Mausabfrage initialisieren.
			tay
			PopW	r11
			sec
			jsr	StartMouseMode		;Maus aktivieren.
			cli

;*** Warten bis keine Maustaste gedrückt.
:WaitNoMseKey		NoMseKey
			rts

;*** GEOS-Vektoren löschen.
:ResetGEOS		lda	#$00
			sta	appMain +0
			sta	appMain +1
			sta	intBotVector +0
			sta	intBotVector +1
			sta	keyVector +0
			sta	keyVector +1
			sta	inputVector +0
			sta	inputVector +1
			sta	mouseFaultVec +0
			sta	mouseFaultVec +1
			sta	otherPressVec +0
			sta	otherPressVec +1
			sta	StringFaultVec +0
			sta	StringFaultVec +1
			sta	alarmTmtVector +0
			sta	alarmTmtVector +1
			LoadB	selectionFlash ,$0a
			LoadB	alphaFlag ,%00000000
			LoadB	iconSelFlag ,ST_FLASH
			rts

;*** GeoDOS-Vektoren setzen.
:ResetGeoDOS		LoadB	iconSelFlag ,ST_FLASH
			LoadW	otherPressVec ,SlctIconMenu
			LoadW	keyVector ,TestKey
			LoadW	appMain ,IsMseOnIcon
			LoadW	intBotVector ,MouseIRQ
			rts

;*** Oberfläche verlassen.
:InitForExit1		jsr	InitForExit2		;Systemabfragen löschen.
			jmp	UpdateToolBox 		;Ja, speichern.

:InitForExit2		jsr	NoHelp			;Bubbles abschalten.
			jsr	ClrMenu			;Menüfenster löschen.
			jsr	ResetGEOS		;GEOS-Vektoren zurücksetzen.
			jmp	ClrScreen		;Bildschirm löschen / Routine starten.

;*** Hilfeseite installieren.
:ConfigHelp		lda	curMenu
			asl
			tay
			lda	HelpFileName+0,y
			ldx	HelpFileName+1,y
			sta	r0L			;Zeiger auf Hilfedatei speichern.
			stx	r0H

			lda	#<InitScreen
			ldx	#>InitScreen		;Zeiger auf "Hilfe verlassen"-Routine.
			jmp	InstallHelp		;Hilfe installieren.

;*** Icon-Menü initialisieren.
:InitIcons		LoadW	Icon_Tab1,1
			ldy	#$00
			ldx	#$00
			bit	CBM_Install		;CBM-Modul verfügbar ?
			bpl	:101			;Nein, weiter...
			jsr	Copy1Icon		;CBM-Icon in Icon-Tabelle kopieren.

::101			ldx	#$08
			bit	DOS_Install		;DOS-Modul verfügbar ?
			bpl	:102			;Nein, weiter...
			jsr	Copy1Icon		;DOS-Icon in Icon-Tabelle kopieren.

::102			ldx	#$10
			bit	CopyInstall		;COPY-Modul verfügbar ?
			bpl	:103			;Nein, weiter...
			jsr	Copy1Icon		;COPY-Icon in Icon-Tabelle kopieren.

::103			ldx	#$18			;EXIT!-Icon in Tabelle kopieren.

;*** Icon in Icon-Zeile übernehmen.
:Copy1Icon		lda	Icon_Tab1b,x
			sta	Icon_Tab1a,y
			inx
			iny
			tya
			and	#%00000111
			bne	Copy1Icon
			inc	Icon_Tab1
			rts

;*** Status-Zeile ausgeben.
:PrintStatus		jsr	i_C_MenuBack		;Farbe für Statuszeile.
			b	$00,$17,$28,$02

			FillPRec$00,$b8,$c7,$0000,$013f
			lda	#%11111111
			jsr	FrameRectangle		;Rahmen um Statuszeile zeichnen.

			jsr	UseMiniFont		;Spezial-Zeichensatz einschalten.

			jsr	i_BitmapUp		;Drucker-/Eingabetreiber anzeigen.
			w	Icon_17
			b	$00,$b8,$02,$10
			jsr	PrnSysInfo

			jsr	i_BitmapUp		;Datum/Uhrzeit anzeigen.
			w	Icon_18
			b	$0d,$b8,$02,$10
			jsr	PrnDateTime

			jmp	PrnDrvInfo		;Laufwerke anzeigen.

;*** DEZIMAL nach ASCII wandeln.
:HEXtoASCII		ldx	#$30
::101			cmp	#10
			bcc	:102
			inx
			sbc	#10
			bcs	:101
::102			adc	#$30
			rts

;*** Uhrzeit ausgeben.
:PrnSysInfo		ClrB	currentMode
			PrintXY	$0014,$be,PrntFileName
			PrintXY	$0014,$c5,inputDevName
			rts

;*** Uhrzeit ausgeben.
:PrnDateTime		jsr	UseMiniFont		;Spezial-Zeichensatz einschalten.

			LoadW	r11,$0079
			LoadB	r1H,$be
			lda	day
			jsr	PrnNumInfo
			lda	#"."
			jsr	SmallPutChar
			lda	month
			jsr	PrnNumInfo
			lda	#"."
			jsr	SmallPutChar
			lda	year
			jsr	PrnNumInfo
			lda	#" "
			jsr	SmallPutChar

			LoadW	r11,$0079
			LoadB	r1H,$c5
			lda	hour
			jsr	PrnNumInfo
			lda	#":"
			jsr	SmallPutChar
			lda	minutes
			jsr	PrnNumInfo
			lda	#"."
			jsr	SmallPutChar
			lda	seconds
			jsr	PrnNumInfo
			lda	#" "
			jmp	SmallPutChar

:PrnNumInfo		jsr	HEXtoASCII
			pha
			txa
			jsr	SmallPutChar
			pla
			jmp	SmallPutChar

;*** Laufwerke ausgeben.
:PrnDrvInfo		LoadW	r14,$00a0		;Zeiger auf X-Pos. für erstes Laufwerk.

			lda	#$00
::101			pha

			MoveW	r14,r11			;Laufwerksbuchstaben ausgeben.
			LoadB	r1H,191
			pla
			pha
			add	"A"
			jsr	SmallPutChar
			lda	#":"
			jsr	SmallPutChar

			pla
			pha
			add	8
			cmp	Target_Drv		;Aktuelles Laufwerk ?
			bne	:101a			;Nein, weiter...

			AddVBW	20,r11			;Aktuelles Laufwerk kennzeichnen.
			LoadB	currentMode,SET_BOLD
			lda	#"!"
			jsr	SmallPutChar
			ClrB	currentMode

::101a			pla				;X-Koordinate für
			pha				;Laufwerks-Icon berechnen.
			tay
			lda	PrnDrvXPos,y
			sta	:106 +0

			lda	DriveTypes,y		;Laufwerk verfügbar ?
			bne	:102			;Ja, weiter...

			lda	#10			;Symbol für
			ldx	#<Icon_16		;"Laufwerk nicht vorhanden!"
			ldy	#>Icon_16
			jmp	:104

::102			lda	DriveTypes,y
			ldx	#<Icon_14		;Symbol für
			ldy	#>Icon_14		;"Diskettenlaufwerk"
			cmp	#Drv_1541
			beq	:103
			cmp	#Drv_1571
			beq	:103
			cmp	#Drv_1581
			beq	:103
			cmp	#Drv_CMDFD2
			beq	:103
			cmp	#Drv_CMDFD4
			beq	:103

			ldx	#<Icon_15		;Symbol für
			ldy	#>Icon_15		;"RAM/HD-Laufwerk"
::103			lda	#$08
::104			sta	:106 +3
			stx	:105 +0
			sty	:105 +1
			jsr	i_BitmapUp		;Laufwerks-Icon ausgeben.
::105			w	$ffff
::106			b	$00,$b9,$02,$08

			pla				;Laufwerkstyp ausgeben.
			pha
			tay
			lda	DriveTypes,y		;Laufwerk nicht verfügbar ?
			beq	:109			;Ja, weiter...

			MoveW	r14,r11
			LoadB	r1H,197
			LoadB	r15H,7

			tya
			asl
			asl
			asl
::107			pha				;Laufwerkstyp ausgeben.
			tax
			lda	Drive_ASCII,x
			cmp	#$60
			bcc	:108
			sbc	#$20
::108			jsr	SmallPutChar
			pla
			add	1
			dec	r15H
			bne	:107

::109			AddVBW	40,r14			;Zeiger auf Pos. für nächstes Laufwerk.
			pla
			add	1			;Zeiger auf nächstes Laufwerk.
			cmp	#$04			;Alle Laufwerke ausgegeben ?
			beq	:110			;Nein, weiter...
			jmp	:101

::110			rts

;*** Neues Vorgabelaufwerk setzen.
:SetNewTarget		lda	mouseXPos +0		;Angewähltes Laufwerk berechnen.
			sec
			sbc	#<$00a0
			sta	r0L
			lda	mouseXPos +1
			sbc	#>$00a0
			sta	r0H
			bcc	:101			;Kein Laufwerk, Abbruch...

			LoadW	r1,$0028
			ldx	#r0L
			ldy	#r1L
			jsr	Ddiv

			lda	r0L
			add	8
			tax
			lda	DriveTypes-8,x		;Laufwerk verfügbar ?
			beq	:101			;Nein, Abbruch...
			txa
			sta	Target_Drv		;Aktuelles Laufwerk speichern.
			jsr	NewDrive		;Laufwerk aktivieren.
			jsr	PrintStatus		;Statuszeile ausgeben.
			jmp	WaitNoMseKey		;Warten bis keine Maustaste gedrückt.
::101			rts

;*** Laufwerksauswahl-Modus wechseln.
:SwapSlctDrv		lda	TargetMode
			eor	#$ff
			sta	TargetMode
			jsr	SetSlctDrv
			ldx	#<SYS_DrvTarget
			jmp	SetOptToHdr

;*** Icon für "Laufwerksauswahl-Modus" definieren.
:SetSlctDrv		ldx	#<Icon_89
			ldy	#>Icon_89
			bit	TargetMode
			bpl	:101
			ldx	#<Icon_90
			ldy	#>Icon_90
::101			stx	MI_6b+0
			sty	MI_6b+1
			rts

;*** "Kopieren: Partitionsabfrage".
:SwapSlctPart		lda	CopyMod
			eor	#$ff
			sta	CopyMod
			jsr	SetSlctPart
			ldx	#<SYS_Copy_Mode
			jmp	SetOptToHdr

;*** Icon für "Partitionsauswahl-Modus" definieren.
:SetSlctPart		ldx	#<Icon_41
			ldy	#>Icon_41
			bit	CopyMod
			bpl	:103
			ldx	#<Icon_42
			ldy	#>Icon_42
::103			stx	MI_5a+0
			sty	MI_5a+1
			rts

;*** Bubble-Anzeige ein-/ausschalten.
:SwapBubbles		lda	BubbleMod
			eor	#$ff
			sta	BubbleMod
			jsr	SetBubbles
			ldx	#<SYS_Bubble_OK
			jmp	SetOptToHdr

;*** Icon für "Bubble-Anzeige" definieren.
:SetBubbles		ldx	#<Icon_12
			ldy	#>Icon_12
			bit	BubbleMod
			bpl	:101
			ldx	#<Icon_13
			ldy	#>Icon_13
::101			stx	MI_6a+0
			sty	MI_6a+1
			rts

;*** Mittlere Maustaste ein-/ausschalten.
:SwapMKey2Mode		lda	MseKey2Mode
			eor	#$ff
			sta	MseKey2Mode
			jsr	SetMKey2Mode
			ldx	#<SYS_MKey2Mode
			jmp	SetOptToHdr

;*** Icon für "Mittlere Maustaste" definieren.
:SetMKey2Mode		ldx	#<Icon_98
			ldy	#>Icon_98
			bit	MseKey2Mode
			bpl	:101
			ldx	#<Icon_99
			ldy	#>Icon_99
::101			stx	MI_6c+0
			sty	MI_6c+1
			rts

;--- Ergänzung: 22.12.18/M.Kanet
;Unterstützung für Option D'n'D On/Off ergänzt.
;Kann im Menü TOOLS ein-/ausgeschaltet werden.
;*** Drag'n'Drop ein-/ausschalten.
:SwapDnD		lda	EnableDnD
			eor	#$ff
			sta	EnableDnD
			jsr	SetDnD
			ldx	#<SYS_EnableDnD
			jmp	SetOptToHdr

;*** Icon für "Mittlere Maustaste" definieren.
:SetDnD			ldx	#<Icon_92
			ldy	#>Icon_92
			bit	EnableDnD
			bmi	:101
			ldx	#<Icon_91
			ldy	#>Icon_91
::101			stx	MI_6d+0
			sty	MI_6d+1
			rts

;*** Option im Infoblock von GeoDOS speichern.
:SetOptToHdr		sta	a0L			;Optionswert merken.
			stx	a0H			;Offset im Infoblock merken.

			jsr	NoHelp			;Bubbles abschalten.
			jsr	MouseOff		;Mauszeiger abschalten.

			jsr	OpenSysDrive		;GeoDOS-Laufwerk öffnen.

			LoadW	r6,AppNameBuf
			jsr	FindFile		;GeoDOS-Datei öffnen.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch...

			lda	dirEntryBuf+19
			sta	r1L
			lda	dirEntryBuf+20
			sta	r1H
			LoadW	r4,IBlockSektor
			jsr	GetBlock		;GeoDOS-Infoblock laden.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch...

			lda	a0L
			ldx	a0H
			sta	IBlockSektor,x		;Optionswert in Infoblock speichern.

			lda	dirEntryBuf+19
			sta	r1L
			lda	dirEntryBuf+20
			sta	r1H
			LoadW	r4,IBlockSektor
			jsr	PutBlock		;Neuen Infoblock schreiben.

			jsr	OpenUsrDrive		;Laufwerk  zurücksetzen.

			jsr	PrnIconTab		;Icons erneut anzeigen.
			jsr	MouseUp			;Mauszeiger wieder einschalten.
			jsr	ConfigHelp		;Hilfefunktion installieren.
			jmp	WaitNoMseKey 		;Warten bis Maustaste losgelassen.
::101			jmp	GDDiskError

;*** Toolbox löschen.
:ClrToolBox		ldx	#$05			;ca. 2sec. warten.
::101			jsr	CPU_Pause
			bit	mouseData		;Maustaste noch gedückt ?
			bmi	:104			;Ja, weiter...
			dex
			bpl	:101

			jsr	InitForExit2		;GeoDOS zurücksetzen.

			DB_UsrBoxV104b0			;Abfrage: "Toolbox löschen ?"
			CmpBI	sysDBData,YES		;"Toolbox löschen" gewählt ?
			bne	:103			;Nein, Abbruch...

			ldy	#$04			;Toolbox-Inhalt löschen.
::102			lda	#$00
			sta	MenuIcon_1+0,y
			sta	MenuIcon_1+1,y
			sta	MenuIcon_1+6,y
			sta	MenuIcon_1+7,y
			tya
			add	8
			tay
			cpy	#84
			bcc	:102

			LoadB	ToolBoxModify,$ff
			jsr	SaveToolBox		;Leere Toolbox speichern.

::103			jmp	NewScreen		;Zum Hauptmenü.
::104			rts				;Mausklick ignorieren.

;*** GeoDOS beenden.
:CallExitMenu		jsr	InitForExit1		;GeoDOS zurücksetzen.
			jmp	vExitGD			;"Verlassen"-Menü starten.

;*** Toolbar zeichnen.
:PrintToolBar		jsr	i_C_MenuTitel
			b	$00,$00,$01,$16
			jsr	i_C_MenuBack
			b	$01,$00,$02,$16

			FillPRec$00,$00,$af,$0008,$0017
			FrameRec$00,$af,$0008,$0017,%11111111

			jsr	i_BitmapUp
			w	Icon_05
			b	$00,$78,$01,$30

			ldx	#$01			;Zeiger auf Icon-Daten für
			jsr	PosCIconTab		;Toolbox berechnen.

			ClrB	r14L
::101			lda	r14L
			jsr	SetIconTab		;Zeiger auf aktuelles Icon berechnen.

			ldy	#$00
			jsr	TetVecData0		;Zeiger auf Bitmap = $0000 ?
			beq	:105			;Ja, Icon nicht definiert.

			ldy	#$03			;Y-Koordinate für Farbe berechnen.
			lda	(r15L),y
			lsr
			lsr
			lsr
			sta	:103 +4

			ldx	r14L
			lda	IconFarbe_1,x		;Farbe definiert ?
			bne	:103			;Ja, weiter...
			lda	C_MenuMIcon		;Standard-Farbe verwenden.
::103			jsr	i_UserColor		;Farbe darstellen.
			b	$01,$ff,$02,$02

::105			inc	r14L			;Zeiger auf nächstes Icon.
			CmpB	r14L,a1L		;Farbe für alle Icons ausgegeben ?
			bne	:101			;Nein, weiter...
			jmp	PrnCurIcons		;Toolbox-Icons ausgeben.

;*** Toolbox speichern.
:LoadToolBox		jsr	OpenSysDrive		;GeoDOS-Laufwerk öffnen.

			LoadW	r6,V104a2
			LoadB	r7L,DATA
			LoadB	r7H,$01
			LoadW	r10,V104a1
			jsr	FindFTypes		;TOOLBOX.INI-Datei suchen.
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch.
			lda	r7H			;Datei gefunden ?
			bne	:101			;Nein, weiter...

			jsr	PrepGetFile

			LoadW	r6,V104a2
			LoadW	r7,MenuIcon_1
			lda	#%00000001
			jsr	GetFile			;Toolbox einlesen.
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch.

::101			LoadB	ToolBoxInMem,$ff
			jmp	OpenUsrDrive		;Laufwerk zurücksetzen.
::102			jmp	GDDiskError

;*** Toolbox speichern.
:SaveToolBox		jsr	UpdateToolBox		;Toolbox speichern.
			jmp	NewScreen		;Zurück zum Hauptmenü.

:UpdateToolBox		bit	ToolBoxModify		;Toolbox geändert ?
			bpl	:103			;Nein, nicht speichern.

			jsr	DoInfoBox		;Infobox ausgeben.
			PrintStrgV104b1

			jsr	OpenSysDrive		;GeoDOS-Laufwerk öffnen.

			LoadW	r0,V104a0
			jsr	DeleteFile		;Alte Toolbox löschen.
			txa				;Diskettenfehler ?
			beq	:101			;Nein, weiter...
			cpx	#$05			;"File not found ?"
			bne	:102			;Nein, Abbruch...

::101			LoadW	r9,HdrB000
			LoadB	r10L,NULL
			jsr	SaveFile		;Neue Toolbox speichern.
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch...

			jsr	OpenUsrDrive		;Laufwerk zurücksetzen.

			ClrB	ToolBoxModify
			jmp	ClrBox			;Infobox löschen.
::102			jmp	GDDiskError
::103			rts

;*** Icons darstellen.
:PrnIconTab		jsr	PosIconTab		;Zeiger auf aktuelle Icon-Daten setzen.

:PrnCurIcons		ClrB	r14L			;Zeiger auf erstes Icon.
::101			lda	r14L
			jsr	SetIconTab		;Zeiger auf aktuelles Icon berechnen.

			ldy	#$05			;Daten Icon in Register für
			ldx	#$05			;":BitmapUp" kopieren.
::102			lda	(r15L),y
			sta	r0L,x
			sta	curIconData,x
			dey
			dex
			bpl	:102

			CmpW0	r0			;Icon-Grafik definiert ?
			beq	:103			;Nein, weiter...
			jsr	BitmapUp		;Icon auf Bildschirm ausgeben.

::103			inc	r14L			;Zeiger auf nächstes Icon.
			CmpB	r14L,a1L		;Alle Icons ausgegeben ?
			bne	:101			;Nein, weiter...
			rts

;*** Zeiger auf Icon berechnen.
:SetIconTab		ldx	#$00			;Zeiger mit 8 multiplizieren.
			stx	r15H
			asl
			rol	r15H
			asl
			rol	r15H
			asl
			rol	r15H
			clc
			adc	a0L			;Startadresse Icon-Tabelle
			sta	r15L			;addieren.
			lda	r15H
			adc	a0H
			sta	r15H
			AddVBW	4,r15			;Icon-Tabellen-Header übergehen.
			rts

;*** Icon-Abmessungen berechnen.
:DefIconSize		lda	curIconData+5		;Y-Koordinate für Unterkante.
			adda	curIconData+3
			sub	1
			sta	r2H
			lda	curIconData+3		;Y-Koordinate für Oberkante.
			sta	r2L
			lda	curIconData+2		;X-Koordinate für linke  Grenze/low.
			sta	r3L
			adda	curIconData+4		;X-Koordinate für rechte Grenze/low.
			sta	r4L

			lda	#$00
			sta	r3H			;X-Koordinate für linke  Grenze/high.
			sta	r4H			;X-Koordinate für rechte Grenze/high.

			ldx	#r3L			;X-Koordinate in Pixel umrechnen.
			ldy	#$03
			jsr	DShiftLeft

			ldx	#r4L			;X-Koordinate in Pixel umrechnen.
			ldy	#$03
			jsr	DShiftLeft

			ldx	#r4L
			jmp	Ddec

;*** Daten über Vektor auf $0000 testen.
:TetVecData0		lda	(r15L),y
			iny
			ora	(r15L),y
			rts

;*** Test ob Icon angeklickt wurde.
:SlctIconMenu		jsr	ChkMseKey		;Maustaste prüfen.

			lda	#<MouseClkArea
			ldx	#>MouseClkArea
			jsr	TestMseArea		;Besondere Mausbereiche abfragen.

;*** Prüfen ob Icon angeklickt.
:ChkMseClick		ldx	#$01
			stx	MoveFromMenu		;Zeiger auf Toolbox.
			jsr	PosCIconTab		;Zeiger auf icon-Daten berechnen.
			jsr	TestIconMenu		;Wurde Toolbox-Icon angewählt ?
			bcs	:102			;Ja, auswerten.

			ldx	curMenu			;Aktuelles Menü = Hauptmenü ?
			beq	EndMseKlick		;Ja, keine weitere Funktion.
			stx	MoveFromMenu
			jsr	PosCIconTab		;Zeiger auf icon-Daten berechnen.
			jsr	TestIconMenu		;Mausklick auf Menü-Icon ?
			bcs	:102			;Ja, auswerten.

			jsr	ClkOnDeskTop		;Mausklick auf Desktop ?
			bne	EndMseKlick		;Nein, Mausklick ignorieren.
			jmp	:105			;Ja, aktuelles Menü schließen.

;*** Klick auf Icon auswerten.
::102			ldy	#$00
			jsr	TetVecData0		;Zeiger auf Bitmap = $0000 ?
			beq	EndMseKlick		;Ja, Ende...

			lda	r14L
			sta	SelectedIcon		;Zeiger auf gewähltes icon.
			jsr	DefIconSize		;Pixel-Grenzen für Icon berechnen.
			jsr	InvertRectangle		;Icon invertieren.

			lda	curIconData+7		;Sonderbehandlung für interne
			beq	:104			;Routine ? Ja, weiter...

;--- Ergänzung: 22.12.18/M.Kanet
;Unterstützung für Option D'n'D On/Off ergänzt.
;Kann im Menü TOOLS ein-/ausgeschaltet werden.
			bit	EnableDnD		;Drag'n'Drop aktiviert?
			bmi	:103			;Ja, weiter...
			jsr	WaitNoMseKey		;Waryten bis keine Maustaste gedrückt.
			jmp	:103a

::103			jsr	Move2ToolBox		;Icon verschieben ? Nein, weiter...

::103a			jsr	InitForExit1		;Vorbereiten zum verlassen des Menüs.

			lda	TargetMode
			sta	TempTrgtMode
			jmp	(curIconData+6)		;Externe Routine aufrufen.

::104			lda	curIconData+6		;Routine = $0000 ?
			bne	:106			;Nein, weiter...

::105			jsr	NoHelp			;Bubbles abschalten.
			jsr	ClrMenu			;Menüfenster löschen.
			ClrB	curMenu			;Hauptmenü aktivieren.
			jmp	InitMainMenu		;Zum Hauptmenü.

::106			sec				;Zeiger auf interne Routine
			sbc	#$01			;berechnen und ausführen.
			asl
			tay
			lda	InternalRout +0,y
			ldx	InternalRout +1,y
			jmp	CallRoutine

;*** Mausklick beenden.
:EndMseKlick		jmp	WaitNoMseKey		;Waryten bis keine Maustaste gedrückt.

;*** Menü auf Toolbox ablegen.
:Move2ToolBox		lda	mouseYPos		;Mausbewegungen einschränken.
			sta	mouseTop
			sta	mouseBottom
			lda	mouseXPos +0
			sta	mouseLeft +0
			sta	mouseRight+0
			lda	mouseXPos +1
			sta	mouseLeft +1
			sta	mouseRight+1

			ldx	#$05			;ca. 2sec. warten.
::101			jsr	CPU_Pause
			bit	mouseData		;Maustaste noch gedückt ?
			bpl	:102			;Ja, weiter...
			LoadW	r0,V104c1		;Nein, Mausbewegung freigeben und
			jmp	InitRam			;zur Routine zurück.

::102			dex
			bpl	:101

			pla				;Rücksprungadresse löschen.
			pla

			jsr	NoHelp			;Bubbles abschalten.

			jsr	DefIconSize		;Pixel-Grenzen für Icon berechnen.
			jsr	InvertRectangle		;Icon invertieren.

			Display	ST_WR_BACK		;Nur Hintergrundgrafik.

			MoveW	curIconData,r0
			LoadB	r1L,$26
			LoadB	r1H,$b8
			LoadB	r2L,$02
			LoadB	r2H,$10
			jsr	BitmapUp		;Bitmap ausgeben.

			Display	ST_WR_FORE		;Nur Vordergrundgrafik.

			ldx	#$00			;Icon-Daten in Sprite-Puffer kopieren.
			ldy	#$00
::103			lda	BACK_SCR_BASE+7664+ 0,y
			sta	Spr05+ 0,x
			lda	BACK_SCR_BASE+7664+ 8,y
			sta	Spr05+ 1,x
			lda	BACK_SCR_BASE+7984+ 0,y
			sta	Spr05+24,x
			lda	BACK_SCR_BASE+7984+ 8,y
			sta	Spr05+25,x
			inx
			inx
			inx
			iny
			cpy	#$08
			bne	:103

			LoadB	r3L,6			;Spritemuster für Icon #1
			LoadW	r4,Spr05		;erzeugen.
			jsr	DrawSprite
			jsr	EnablSprite

			LoadB	r3L,7			;Spritemuster für Icon #2
			LoadW	r4,Spr06		;erzeugen.
			jsr	DrawSprite
			jsr	EnablSprite

			jsr	ClkOnDeskTop		;Farbe Menüicon bestimmen.
			sta	MoveIconCol

			jsr	InitForIO		;Spritefarben des GhostIcon bestimmen.
			lda	MoveIconCol
			lsr
			lsr
			lsr
			lsr
			sta	$d02d			;Sprite-Farbe #1.
			lda	MoveIconCol
			and	#%00001111
			sta	$d02e			;Sprite-Farbe #3.
			lda	#$00
			sta	$d017			;Keine Vergrößerung in y-Richtung.
			sta	$d01d			;Keine Vergrößerung in x-Richtung.
			sta	$d01c			;Keine Multicolor-Sprites.
			jsr	DoneWithIO

			jsr	SetIcon2Mse		;GhostIcon an Mauspfeil anbinden.

			jsr	WaitNoMseKey 		;Warten bis Maustaste losgelassen.

			LoadW	r0,V104c1		;Mausbewegung freigeben.
			jsr	InitRam

			CmpBI	MoveFromMenu,1		;Klick auf Toolbox ?
			bne	:105			;Nein, weiter...

			ldy	mouseYPos		;X-Koordinate verschieben.
			LoadW	r11,$0020
			sec
			jsr	StartMouseMode		;Maus aktivieren.

::105			jsr	SetIcon2Mse		;GhostIcon an Mauspfeil anbinden.

;*** Icon bewegen.
			ldx	#$01
			jsr	PosCIconTab		;Zeiger auf Toolbox-Daten berechnen.
:Move2NewPos		jsr	TestIconMenu		;Mausklick auf Toolbox ?
			bcc	:101			;Ja, auswerten.

			LoadW	r4,$0008
			lda	curIconData+3
			sta	r5L
			jsr	SetIcon2Pos		;GhostIcon positionieren.
			jmp	:102

::101			jsr	SetIcon2Mse		;GhostIcon an Mauspfeil anbinden.

::102			lda	mouseData		;Maustaste gedrückt ?
			bmi	Move2NewPos		;Nein, GhostIcon bewegen.

			jsr	TestIconMenu		;Position auswerten.
			bcs	:104			;Klick auf Toolbox ? Ja, weiter...

			CmpBI	MoveFromMenu,1		;Toolbox verschieben ?
			bne	:103			;Nein, weiter...
			jmp	:199			;Ja, Toolbox-Icon löschen.
::103			jmp	EndMoveIcon		;GhostIcon löschen.

::104			PushW	r15			;Ziel-Pos. Icondaten merken.
			PushB	r14L			;Ziel-Iconnr. merken.

			ldx	MoveFromMenu		;Zeiger auf gewähltes Icon
			jsr	PosCIconTab		;berechnen.

			lda	SelectedIcon
			jsr	SetIconTab		;Zeiger auf Icon-Daten in Tabelle.

			PopB	r14H			;Ziel-Iconnr.
			PopW	r13			;Ziel-Pos. Icondaten.

			ldy	#$00			;Pos. Bitmap-Grafik kopieren.
			lda	(r15L),y
			sta	(r13L),y
			iny
			lda	(r15L),y
			sta	(r13L),y

			ldy	#$06			;Einsprungadresse kopieren.
			lda	(r15L),y
			sta	(r13L),y
			iny
			lda	(r15L),y
			sta	(r13L),y

			ldy	MoveFromMenu		;Bubble-Text kopieren.
			ldx	WinDataOffset,y
			lda	MenuWinData+6,x
			sta	r12L
			lda	MenuWinData+7,x
			sta	r12H

			lda	SelectedIcon
			asl
			tay

			lda	r14H
			asl
			tax

			lda	(r12L),y
			sta	IconText_1+0,x
			iny
			lda	(r12L),y
			sta	IconText_1+1,x

			ldx	r14H			;Icon-Farbe kopieren.
			lda	MoveIconCol
			cmp	C_MenuMIcon
			bne	:198
			lda	#$00
::198			sta	IconFarbe_1,x

			CmpBI	MoveFromMenu,1
			bne	:105
::199			jsr	ClrTBoxIcon

::105			LoadB	ToolBoxModify,$ff

			jsr	EndMoveIcon		;GhostIcon abschalten.
			jsr	PrintToolBar		;Toolbox zeichnen.
			jmp	InitMainMenu		;Hauptmenü aktivieren.

;*** Icon auf Mausposition setzen.
:SetIcon2Mse		MoveW	mouseXPos,r4
			MoveB	mouseYPos,r5L
:SetIcon2Pos		LoadB	r3L,6			;Spritemuster für Bubbles
			jsr	PosSprite
			LoadB	r3L,7			;Spritemuster für Bubbles
			jmp	PosSprite

;*** Icon löschen.
:EndMoveIcon		lda	#$00
			sta	r4L
			sta	r4H
			sta	r5L
			jsr	SetIcon2Pos		;GhostIcon positionieren und
			LoadB	r3L,6			;abschalten.
			jsr	DisablSprite
			LoadB	r3L,7
			jsr	DisablSprite
			jmp	WaitNoMseKey

;*** Toolbox-Icon löschen.
:ClrTBoxIcon		ldx	#$01
			jsr	PosCIconTab		;Zeiger auf Toolbox-Daten berechnen.
			lda	SelectedIcon
			jsr	SetIconTab		;Zeiger auf Icon-Daten in Tabelle.

			ldy	#$00			;Vektor für Icon-Grafik und
			tya				;Icon-Routine löschen.
			sta	(r15L),y
			iny
			sta	(r15L),y
			ldy	#$06
			sta	(r15L),y
			iny
			sta	(r15L),y
			rts

;*** Welches Icon wurde angeklickt ?
:TestIconMenu		lda	#$00
			sta	r14L
::101			lda	r14L
			jsr	SetIconTab		;Zeiger auf Icon-Daten in Tabelle.

			ldy	#$02			;Testen ob Maus innerhalb des
			lda	mouseXPos+1		;aktuellen Icons.
			lsr
			lda	mouseXPos+0
			ror
			lsr
			lsr
			sec
			sbc	(r15L),y
			bcc	:102
			iny
			iny
			cmp	(r15L),y
			bcs	:102
			dey
			lda	mouseYPos
			sec
			sbc	(r15L),y
			bcc	:102
			iny
			iny
			cmp	(r15L),y
			bcc	:103			;Icon gefunden, weiter...

::102			inc	r14L			;Zeiger auf nächstes Icon.
			CmpB	r14L,a1L		;Alle Icons getestet ?
			bne	:101			;Nein, weiter...
			clc				;Icon nicht gefunden ?
			rts

::103			ldy	#$07
::104			lda	(r15L),y		;Icon-Daten in Zwischenspeicher
			sta	curIconData,y		;kopieren.
			dey
			bpl	:104
			sec				;Icon gefunden.
			rts

;*** Maustasten abfragen.
:MouseIRQ		jsr	ChkMseKey		;Maus abfragen.
			rts				;Keine Funktion, Ende...

:ChkMseKey		php				;IRQ sperren.
			sei
			ldx	$01
			lda	#$35			;I/O aktivieren.
			sta	$01

			lda	$d419
			cmp	#$ff			;Echte Maus angeschlossen ?
			beq	:100			;Nein, Abbruch.

			lda	#$ff
			sta	$dc00
::101			lda	$dc01
			cmp	$dc01
			bne	:101

			cmp	#$ff			;Taste gedrückt ?
			beq	:100			;Nein, Abbruch.

			ldy	$dc01			;Maustaste abfragen.
			cpy	#%11111110		;"Rechte Maustaste" ?
			beq	:102			;Ja, ausführen.
			cpy	#%11111101		;"Mittlere Maustaste" ?
			beq	:103			;Ja, ausführen.
::100			stx	$01
			plp				;Ende, keine Funktion.
			rts

;*** Rechte Maustaste  : Maus-Menü aufrufen.
::102			jsr	ResetGEOS
			LoadW	appMain,OpenMseMenu

			jmp	:104

;*** Mittlere Maustaste: Verlassen-Menü aufrufen.
::103			bit	MseKey2Mode		;Mittlere Maustaste abgeschaltet ?
			bmi	:100			;Ja, Abbruch.
			jsr	ResetGEOS
			LoadW	appMain,CallExitMenu

;*** Sonderfunktionen beenden.
::104			stx	$01

			plp
			pla
			pla
			rts

;*** Warten bis keine Maustaste gedrückt.
:L104a0			lda	$dc01
			cmp	#%11101111
			beq	L104a0
			cmp	#%11111101
			beq	L104a0
			cmp	#%11111110
			beq	L104a0
			ClrB	pressFlag
			rts

:L104a1			php
			sei
			ldx	$01
			LoadB	$01,$35
			jsr	L104a0
			stx	$01
			plp
			rts

;*** Mausklick auf DeskTop ?
:ClkOnDeskTop		lda	mouseYPos		;Zeiger auf Speicher in COLOR_MATRIX
			lsr				;berechnen.
			lsr
			lsr
			sta	r0L
			LoadB	r1L,40
			ldx	#r0L
			ldy	#r1L
			jsr	BBMult
			MoveW	mouseXPos,r1L
			ldx	#r1L
			ldy	#$03
			jsr	DShiftRight
			AddW	r1,r0
			AddVW	COLOR_MATRIX,r0

			ldy	#$00
			lda	(r0L),y			;Farbe aus FarbRAM einlesen und mit
			cmp	C_ScreenClear		;DeskTop-Farbe vergleichen.
			rts

;*** Tastaturabfrage
:TestKey		CmpBI	keyData,CR		;Wurde RETURN gedrückt ?
			beq	InitMseMenu		;Ja, Maus-Menü öffnen.
			cmp	#$01			;Wurde "F1"-Taste gedrückt ?
			beq	:101			;Ja, Hilfe aufrufen.
			rts				;Keine Funktion.

::101			jmp	BootHelp		;Hilfe aufrufen.

;*** Neues Menü wurde aktiviert.
:OpenMseMenu		jsr	UpdateMouse		;Sonderbehandlung für
			jsr	WaitNoMseKey		;Maustreiber, die bei Klick auf die
			jsr	CPU_Pause		;rechte Maustaste einen Doppelklick
			jsr	UpdateMouse		;ausführen. Diese Befehle stellen
			jsr	WaitNoMseKey		;sicher, das der zweite Klick ausge-
			jsr	CPU_Pause		;führt wurde.
			jsr	UpdateMouse
			jsr	WaitNoMseKey

;*** Maus-Menü aktivieren.
:InitMseMenu		jsr	L104a1			;Warten bis keine Maustaste gedrückt.
			jsr	ResetGEOS		;Abfrageroutinen abschalten.

;*** Funktionsmenüs aktivieren.
:SetMse_Menu		lda	#$02			;"Sonderfunktionen".
			b $2c
:SetCBM_Menu		lda	#$03			;"Mein Computer".
			b $2c
:SetDOS_Menu		lda	#$04			;"MSDOS Computer".
			b $2c
:SetCOPY_Menu		lda	#$05			;"KOPIEREN".
			b $2c
:SetSYS_Menu		lda	#$06			;"SETUP".
			cmp	curMenu			;Menü bereits aktiv ?
			beq	:102			;Ja, weiter...
			pha
			jsr	NoHelp			;Bubbles abschalten.
			jsr	ClrMenu			;Altes Menü löschen.
			pla
			sta	curMenu			;Neues Menü aktivieren.
			jsr	ConfigHelp
::101			jmp	InitMainMenu		;Zum Hauptmenü.
::102			jmp	ResetGeoDOS		;Abfrageroutinen installieren.

;*** Menüfeld zeichnen.
:CreateMenu		lda	curMenu			;Hauptmenü ?
			bne	:101			;Nein, weiter...
			rts				;Abbruch.

::101			lda	C_MenuBack		;Farbe für Menüfenster.
			jsr	SetWinBox		;Menü zeichnen.
			AddVB	8,r2L			;Rahmen um Menü darstellen.
			lda	#%11111111
			jsr	FrameRectangle

			jsr	GetMenuWidth		;Farbe für Titelzeile berechnen.
			sta	:103 +5
::103			jsr	i_C_MenuTitel
			b	$0b,$02,$28,$01
::104			jsr	i_C_MenuClose
			b	$0b,$02,$01,$01

			jsr	UseGDFont		;Sonderzeichensatz aktivieren.
			ClrB	currentMode

			ldy	curMenu			;Zeiger auf Titeltext.
			ldx	WinDataOffset,y
			lda	MenuWinData+2,x
			sta	r0L
			lda	MenuWinData+3,x
			sta	r0H
			LoadW	r11,$0068		;Titelzeile ausgeben.
			LoadB	r1H,$16
			jsr	PutString

			ldx	curMenu			;Menu initialisieren.
			ldy	WinDataOffset ,x
			lda	MenuWinData+12,y
			ldx	MenuWinData+13,y
			jsr	CallRoutine

;*** Zeiger auf Icon-Daten berechnen.
:PosIconTab		ldx	curMenu
:PosCIconTab		lda	WinDataOffset,x
			tax
			lda	MenuWinData+4,x
			sta	a0L
			lda	MenuWinData+5,x
			sta	a0H

			ldy	#$00
			lda	(a0L),y
			sta	a1L
			rts

;*** Menüfeld zeichnen.
:ClrMenu		lda	curMenu			;Hauptmenü ?
			beq	:101			;Ja ignorieren.
			lda	C_ScreenClear		;Menüfenster löschen.
			jmp	SetWinBox
::101			rts

;*** Menü-Fenster löschen/zeichnen.
:SetWinBox		sta	:101 +7

			jsr	GetMenuWidth
			sta	:101 +5
			sty	:101 +6
::101			jsr	i_ColorBox
			b	$0b,$02,$28,$19,$ff

			jsr	DefWinBoxSize
			Pattern	0
			jmp	Rectangle

;*** Menügröße einlesen.
:GetMenuWidth		ldy	curMenu
			ldx	WinDataOffset,y
			lda	MenuWinData+0,x
			ldy	MenuWinData+1,x
			rts

;*** Klick innerhalb Menü ?
:TestWinBox		LoadB	r5L,$0b
			LoadB	r5H,$02
			jsr	GetMenuWidth
			sta	r6L
			sty	r6H

;*** Fenstergröße berechnen.
:DefWinBoxSize		LoadW	r3,$0058
			lda	r5L
			adda	r6L
			sub	1
			sta	r4L
			ClrB	r4H
			ldx	#r4L
			ldy	#$03
			jsr	DShiftLeft
			AddVBW	7,r4
			LoadB	r2L,16
			lda	r5H
			adda	r6H
			sub	1
			asl
			asl
			asl
			add	7
			sta	r2H
			rts

;*** Menü-Text und Icon-Farben für Menü-Fenster zeichnen.
:Mouse_Menu		ldx	#$02			;Spezial-Menü.
			b $2c
:CBM_Menu		ldx	#$03			;Mein Computer.
			b $2c
:DOS_Menu		ldx	#$04			;MSDOS Computer.
			b $2c
:COPY_Menu		ldx	#$05			;Dateien kopieren.
			b $2c
:SETUP_Menu		ldx	#$06			;Setup-Menü.

			ldy	WinDataOffset ,x
			lda	MenuWinData+04,y
			sta	a0L
			lda	MenuWinData+05,y
			sta	a0H
			lda	MenuWinData+08,y
			sta	a1L
			lda	MenuWinData+09,y
			sta	a1H
			lda	MenuWinData+10,y
			sta	r0L
			lda	MenuWinData+11,y
			sta	r0H
			jsr	GraphicsString

;*** Farbe für Icons in Menü ausgeben.
:SetMenuColor		ldy	#$00
			lda	(a0L),y
			sta	a2L

			AddVBW	6,a0

::101			ldy	#$00
			lda	(a0L),y
			sta	r5L
			iny
			lda	(a0L),y
			lsr
			lsr
			lsr
			sta	r5H
			iny
			lda	(a0L),y
			sta	r6L
			iny
			lda	(a0L),y
			lsr
			lsr
			lsr
			sta	r6H

			ldy	#$01
			lda	(a1L),y
			bne	:102
			dey
			lda	(a1L),y
			jmp	:104

::102			sta	:103 +2
			dey
			lda	(a1L),y
			sta	:103 +1

::103			lda	$ffff
::104			sta	r7L
			jsr	RecColorBox
			AddVBW	8,a0
			AddVBW	2,a1
			dec	a2L
			bne	:101
			rts

;*** Sprechblase ermitteln.
:IsMseOnIcon		jsr	PrnDateTime		;Datum/Uhrzeit ausgeben.

			lda	BubbleMod		;Bubbles anzeigen ?
			beq	:101			;Ja, weiter...
			rts

::101			ldx	#$01			;Bubbles für Toolbox anzeigen.
			jsr	:103

			ldx	curMenu			;Hauptmenü ?
			beq	:102			;Ja, ignorieren.
			jsr	:103			;Bubbles für Menü anzeigen.
::102			jmp	NoHelp			;Keine Hilfe anzeigen.

;*** Mausposition testen.
::103			lda	WinDataOffset,x		;Zeiger auf Icon-Tabelle einlesen.
			tax
			stx	curHelpMenu
			lda	MenuWinData+4,x
			sta	r14L
			lda	MenuWinData+5,x
			sta	r14H

			ldy	#$00
			sty	r15L
			lda	(r14L),y		;Anzahl Icons einlesen.
			sta	r15H

			AddVBW	4,r14			;Zeiger auf erstes Icon in Tabelle.

::104			ldy	#$00
			lda	(r14L),y
			iny
			ora	(r14L),y		;Bitmap definiert ?
			beq	:106			;Nein, weiter...
			iny
::105			lda	(r14L),y		;Icon-Daten kopieren.
			sta	r0L -2,y
			iny
			cpy	#$06
			bne	:105

			MoveB	r0L,r3L			;Icon-Grenzen berechnen.
			ClrB	r3H
			ldx	#r3L
			ldy	#$03
			jsr	DShiftLeft

			lda	r0L
			adda	r1L
			sub	1
			sta	r4L
			ClrB	r4H
			ldx	#r4L
			ldy	#$03
			jsr	DShiftLeft
			AddVBW	7,r4

			MoveB	r0H,r2L

			lda	r0H
			adda	r1H
			sub	1
			sta	r2H

			jsr	IsMseInRegion
			tax				;Ist Maus innerhalb Icon ?
			bne	BubbleOut		;Ja, weiter...

::106			AddVBW	8,r14
			inc	r15L			;Zeiger auf nächstes Icon.
			CmpB	r15L,r15H		;Alle Icons getestet ?
			bne	:104			;Nein, weiter...
			rts

;*** Bubble auf Bildschirm ausgeben.
:BubbleOut		pla				;Icon gefunden, Rücksprungadresse
			pla				;löschen.
			lda	inputData		;Keine Mausbewegung ?
			bmi	:108			;Ja, Bubbles ausgeben.

			CmpB	r15L,curHelp		;Maus noch auf aktivem Bubble ?
			beq	:101			;Ja, weiter...
			jmp	NoHelp			;Bubble löschen.
::101			rts

::108			bit	curHelp			;Ist Bubble aktiv ?
			bmi	:109			;Nein, neue Bubble ausgeben.

			lda	r15L			;Ist gewählter Bubble
			cmp	curHelp			;bereits aktiv ?
			beq	:101			;Ja, ignorieren.

::109			ldx	curHelpMenu		;Zeiger auf Bubble-Text-Tabelle.
			lda	MenuWinData+6,x
			sta	r14L
			lda	MenuWinData+7,x
			sta	r14H
			lda	r15L
			sta	curHelp
			asl
			tay
			lda	(r14L),y
			pha
			iny
			lda	(r14L),y
			tax
			pla
			jmp	SetHelp			;Bubble erzeugen.

;*** Sprite-Register definieren.
:DefBubbleData		jsr	InitForIO
			lda	C_Bubble		;Farbe für Bubble berechnen.
			pha
			lsr
			lsr
			lsr
			lsr
			sta	$d029			;Sprite-Farbe #1.
			sta	$d02a			;Sprite-Farbe #2.
			pla
			and	#%00001111
			sta	$d02b			;Sprite-Farbe #3.
			sta	$d02c			;Sprite-Farbe #4.
			lda	#$00
			sta	$d017			;Keine Vergrößerung in y-Richtung.
			sta	$d01d			;Keine Vergrößerung in x-Richtung.
			sta	$d01c			;Keine Multicolor-Sprites.
			jsr	DoneWithIO
			plp
			rts

;*** Keine Sprechblase.
:NoHelp			LoadB	curHelp,$ff		;Bubbles deaktivieren.
:NoHelp2		LoadB	r3L,2			;Sprites #2 bis #5 abschalten.
			jsr	DisablSprite
			LoadB	r3L,3
			jsr	DisablSprite
			LoadB	r3L,4
			jsr	DisablSprite
			LoadB	r3L,5
			jmp	DisablSprite

;*** Position für Bubble berechnen.
:SetHelpPos1		clc
			lda	r14L
			adc	#4
			sta	r4L
			lda	r14H
			adc	#0
			sta	r4H

			lda	r15L
			sub	15
			sta	r5L

			jsr	PosSprite
			jmp	EnablSprite

:SetHelpPos2		clc
			lda	r14L
			adc	#28
			sta	r4L
			lda	r14H
			adc	#0
			sta	r4H

			lda	r15L
			sub	15
			sta	r5L

			jsr	PosSprite
			jmp	EnablSprite

;*** Sprechblase anzeigen.
:SetHelp		php				;IRQ sperren.
			sei

			sta	:101 +1			;Registerinhalte sichern.
			stx	:101 +3
			PushW	r3			;X-Koordinate sichern.
			PushB	r2L			;Y-Koordinate sichern.
			jsr	NoHelp2			;Sprites löschen.

			LoadB	r3L,2			;Spritemuster für Bubbles
			LoadW	r4,Spr01		;erzeugen.
			jsr	DrawSprite
			LoadB	r3L,3
			LoadW	r4,Spr02
			jsr	DrawSprite
			LoadB	r3L,4
			LoadW	r4,Spr03
			jsr	DrawSprite
			LoadB	r3L,5
			LoadW	r4,Spr04
			jsr	DrawSprite

			Display	ST_WR_BACK		;Textausgabebereich löschen.
			jsr	UseMiniFont
			jsr	i_FillRam
			w	8*40,BACK_SCR_BASE+24*40*8
			b	$00

::101			lda	#$ff			;Text für Bubble ausgeben.
			ldx	#$ff
			sta	r0L
			stx	r0H
			LoadW	r11,3
			LoadB	r1H,197
			jsr	PutString

			Display	ST_WR_FORE

			ldx	#$06			;Text in Bubble-Format umwandeln.
			ldy	#$00
::102			lda	BACK_SCR_BASE+7680+ 0,y
			ora	#%10000000
			sta	spr2pic+0,x
			lda	BACK_SCR_BASE+7680+ 8,y
			sta	spr2pic+1,x
			lda	BACK_SCR_BASE+7680+16,y
			sta	spr2pic+2,x
			lda	BACK_SCR_BASE+7680+24,y
			sta	spr3pic+0,x
			lda	BACK_SCR_BASE+7680+32,y
			sta	spr3pic+1,x
			lda	BACK_SCR_BASE+7680+40,y
			ora	#%00000001
			sta	spr3pic+2,x

			lda	BACK_SCR_BASE+7728+ 0,y
			ora	#%10000000
			sta	spr2pic+21,x
			lda	BACK_SCR_BASE+7728+ 8,y
			sta	spr2pic+22,x
			lda	BACK_SCR_BASE+7728+16,y
			sta	spr2pic+23,x
			lda	BACK_SCR_BASE+7728+24,y
			sta	spr3pic+21,x
			lda	BACK_SCR_BASE+7728+32,y
			sta	spr3pic+22,x
			lda	BACK_SCR_BASE+7728+40,y
			ora	#%00000001
			sta	spr3pic+23,x
			inx
			inx
			inx
			iny
			cpy	#$07
			bne	:102

			PopB	r15L
			PopW	r14

			LoadB	r3L,2			;Position für Bubble berechnen.
			jsr	SetHelpPos1
			LoadB	r3L,3
			jsr	SetHelpPos2
			LoadB	r3L,4
			jsr	SetHelpPos1
			LoadB	r3L,5
			jsr	SetHelpPos2
			jmp	DefBubbleData

;*** Statuszeilen-Funktion aufrufen.
:OtherPrinter		jsr	InitForExit1
			jmp	Get_PrnDrv

:OtherInput		jsr	InitForExit1
			jmp	Get_InpDrv

:OtherDateTime		jsr	InitForExit1
			jmp	vSetCMDtime

;*** Einsprung für Applikation öffnen, Dokumente drucken usw...
:Get_gW			ldx	#$00
			b $2c
:Get_gW_Doks		ldx	#$01
			b $2c
:Prn_GW_Doks		ldx	#$02
			b $2c
:Get_Apps		ldx	#$03
			b $2c
:Get_AllDoks		ldx	#$04
			b $2c
:Prn_AllDoks		ldx	#$05
			b $2c
:Get_DAs		ldx	#$06
			b $2c
:Get_PrnDrv		ldx	#$07
			b $2c
:Get_InpDrv		ldx	#$08
			jmp	vAppl_Doks

;*** Info-Block für Parameter-Textdatei.
:HdrB000		w V104a0
			b $03,$15
			j
<MISSING_IMAGE_DATA>
			b $83
			b DATA
			b SEQUENTIAL
			w MenuIcon_1
			w IconEnde_1
			w MenuIcon_1
			b "GD_Toolbox  V"		;Klasse.
			b "1.1"				;Version.
			s $04				;Reserviert.
			b "GeoDOS 64"			;Autor.
:HdrEnd			s (HdrB000+161)-HdrEnd

;*** Name der Hilfedateien.
:HelpFileName		w HelpLink000
			w HelpLink001
			w HelpLink002
			w HelpLink003
			w HelpLink004
			w HelpLink005
			w HelpLink006

:HelpLink000		b "06,GDH_GeoDOS 64",NULL
:HelpLink001		b "06,GDH_GeoDOS 64",NULL
:HelpLink002		b "02,GDH_Spezial",NULL
:HelpLink003		b "02,GDH_CBM/Disk",NULL
:HelpLink004		b "02,GDH_DOS/Disk",NULL
:HelpLink005		b "02,GDH_Copy/File",NULL
:HelpLink006		b "02,GDH_System",NULL

;*** Variablen.
:PrnDrvXPos		b $15,$1a,$1f,$24

;*** Variablen.
:SelectedIcon		b $00
:MoveFromMenu		b $00
:MoveIconCol		b $00
:ToolBoxInMem		b $00
:ToolBoxModify		b $00

;*** Variablen.
:curHelp		b $ff
:curHelpMenu		b $00
:curIconMode		b $00
:curIconData		s $08

;*** Variablen.
:V104a0			b "TOOLBOX.INI",NULL
:V104a1			b "GD_Toolbox  V1.1",NULL
:V104a2			s 17

if Sprache = Deutsch
;*** Frage: "Toolbox löschen ?"
:V104b0			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Den Inhalt der Toolbox-",NULL
::102			b        "Menüleiste löschen ?",NULL

;*** Info: "Datei 'TOOLBOX.INI' wird gespeichert"
:V104b1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Systemdatei 'TOOLBOX.INI'"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "wird gespeichert..."
			b NULL
endif

if Sprache = Englisch
;*** Frage: "Toolbox löschen ?"
:V104b0			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Erease all entrys from",NULL
::102			b        "the toolbox ?",NULL

;*** Info: "Datei 'TOOLBOX.INI' wird gespeichert"
:V104b1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Systemfile 'TOOLBOX.INI'"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "will be updated..."
			b NULL
endif

;*** Bereichsgrenzen.
:V104c0			w mouseTop
			b $06
			b $10,$8f
			w $0058,$00df
			w NULL

:V104c1			w mouseTop
			b $06
			b $00,$c7
			w $0000,$013f
			w NULL

;*** Untermenüs.
:MenuWinData		s $0e				;Keine Daten für Haup tmenü.

			b $11,$10			;Toolbox.
			w $0000
			w MenuIcon_1 ,IconText_1
			w $0000      ,$0000
			w $0000

			b $11,$10			;Spezial-Menü.
			w Menu_T4
			w MenuIcon_2 ,IconText_2
			w IconColor_2, WinText_2
			w Mouse_Menu

			b $16,$0b			;CBM-Menü.
			w Menu_T0
			w MenuIcon_3 ,IconText_3
			w IconColor_3, WinText_3
			w CBM_Menu

			b $14,$0b			;DOS-Menü.
			w Menu_T1
			w MenuIcon_4 ,IconText_4
			w IconColor_4, WinText_4
			w DOS_Menu

			b $16,$10			;COPY-Menü.
			w Menu_T2
			w MenuIcon_5 ,IconText_5
			w IconColor_5, WinText_5
			w COPY_Menu

			b $11,$0b			;CONFIG-Menü.
			w Menu_T3
			w MenuIcon_6 ,IconText_6
			w IconColor_6, WinText_6
			w SETUP_Menu

;*** Zeiger auf Menüdaten.
:WinDataOffset		b 00,14,28,42,56,70,84

;*** Maus-Bereichsgrenzen.
:MouseClkArea		b $00,$af
			w $0000,$0007
			w ClrToolBox

			b $b8,$bf
			w $0000,$006f
			w OtherPrinter

			b $c0,$c7
			w $0000,$006f
			w OtherInput

			b $b8,$c7
			w $0070,$009f
			w OtherDateTime

			b $b8,$c7
			w $00a0,$013f
			w SetNewTarget

			b $ff

;*** Einsprungadressen für interne Routinen.
:InternalRout		w SwapSlctPart
			w SwapBubbles
			w SwapMKey2Mode
			w SwapSlctDrv
			w SwapDnD

;*** Icons & Menüs.
:Icon_Tab1		b $05
			w $0000
			b $00

			w Icon_10
			b $01,$00,$02,$10
			w CallExitMenu

:Icon_Tab1a		s $04 * $08

:Icon_Tab1b		w Icon_01
			b $04,$00,$05,$20
			w SetCBM_Menu

			w Icon_02
			b $04,$30,$05,$20
			w SetDOS_Menu

			w Icon_03
			b $04,$60,$05,$20
			w SetCOPY_Menu

			w Icon_04
			b $04,$90,$05,$20
			w SetSYS_Menu

if Sprache = Deutsch
;*** Titelzeilen.
:Menu_T0		b "System C=64/128",NULL
:Menu_T1		b "System PC-DOS",NULL
:Menu_T2		b "Dateien Kopieren",NULL
:Menu_T3		b "Konfigurieren",NULL
:Menu_T4		b "Sonderfunktionen",NULL
endif

if Sprache = Englisch
;*** Titelzeilen.
:Menu_T0		b "System C=64/128",NULL
:Menu_T1		b "System PC-DOS",NULL
:Menu_T2		b "Copy files",NULL
:Menu_T3		b "Configure",NULL
:Menu_T4		b "Special functions",NULL
endif

;*** "Toolbox".
:MenuIcon_1		b $0a
			w $0000
			b $00

			w $0000
			b $01,$10,$02,$10
			w $0000

			w $0000
			b $01,$20,$02,$10
			w $0000

			w $0000
			b $01,$30,$02,$10
			w $0000

			w $0000
			b $01,$40,$02,$10
			w $0000

			w $0000
			b $01,$50,$02,$10
			w $0000

			w $0000
			b $01,$60,$02,$10
			w $0000

			w $0000
			b $01,$70,$02,$10
			w $0000

			w $0000
			b $01,$80,$02,$10
			w $0000

			w $0000
			b $01,$90,$02,$10
			w $0000

			w $0000
			b $01,$a0,$02,$10
			w $0000

;*** Bubble-Help-Texte.
:IconText_1		s 10 * 2			;"Toolbox".

;*** Farben für Toolbox-Icons.
:IconFarbe_1		s 10
:IconEnde_1		b $00

;*** "Mouse-Menü".
:MenuIcon_2		b $0d
			w $0000
			b $00

			w Icon_Close
			b $0b,$10,$01,$08
			w $0000

			w Icon_10
			b $0c,$28,$02,$10
			w vExitGD
			w Icon_88
			b $0f,$28,$02,$10
			w vExitBASIC
			w Icon_70
			b $16,$28,$02,$10
			w vGetHelp
			w Icon_79
			b $19,$28,$02,$10
			w vInfo

			w Icon_71
			b $0c,$50,$02,$10
			w Get_gW
			w Icon_72
			b $0e,$50,$02,$10
			w Get_gW_Doks
			w Icon_73
			b $10,$50,$02,$10
			w Prn_GW_Doks

			w Icon_74
			b $0c,$78,$02,$10
			w Get_Apps
			w Icon_75
			b $0e,$78,$02,$10
			w Get_AllDoks
			w Icon_76
			b $10,$78,$02,$10
			w Prn_AllDoks
			w Icon_77
			b $12,$78,$02,$10
			w Get_DAs
			w Icon_78
			b $14,$78,$02,$10
			w vRunBASIC

;*** Bubble-Help-Texte.
:IconText_2		w Text_M0			;CLOSE-Icon.
			w Text_M50			;GeoDOS verlasen.
			w Text_M79			;BASIC aufrufen.
			w Text_M51			;Hilfe.
			w Text_M52			;Info.
			w Text_M56			;GeoWrite
			w Text_M57			;GeoWrite-Dokumente öffnen.
			w Text_M58			;GeoWrite-Dokumente drucken.
			w Text_M60			;Applikation öffnen.
			w Text_M61			;Dokument öffnen.
			w Text_M62			;Dokument drucken.
			w Text_M63			;Hilfsmittel öffnen.
			w Text_M64			;BASIC-Programm starten.

;*** Farbe für Icons.
:IconColor_2		w C_MenuClose			;CLOSE-Icon.
			w C_MenuMIcon			;GeoDOS verlasen.
			w C_MenuMIcon			;BASIC aufrufen.
			w C_MenuMIcon			;Hilfe.
			w C_MenuMIcon			;Info.
			w C_MenuMIcon			;GeoWrite
			w C_MenuMIcon			;GeoWrite-Dokumente öffnen.
			w C_MenuMIcon			;GeoWrite-Dokumente drucken.
			w C_MenuMIcon			;Applikation öffnen.
			w C_MenuMIcon			;Dokument öffnen.
			w C_MenuMIcon			;Dokument drucken.
			w C_MenuMIcon			;Hilfsmittel öffnen.
			w C_MenuMIcon			;BASIC-Programm starten.

;*** Grafik für Menüfenster.
:WinText_2		b MOVEPENTO
			w $005c
			b $24
			b FRAME_RECTO
			w $00db
			b $3b

			b MOVEPENTO
			w $005c
			b $4c
			b FRAME_RECTO
			w $00db
			b $63

			b MOVEPENTO
			w $005c
			b $74
			b FRAME_RECTO
			w $00db
			b $8b

if Sprache = Deutsch
			b ESC_PUTSTRING
			w $0064
			b $24
			b "Spezialmenü"
endif

if Sprache = Englisch
			b ESC_PUTSTRING
			w $0064
			b $24
			b "Special"
endif

			b GOTOXY
			w $0064
			b $4c
			b "GeoWrite"

			b GOTOXY
			w $0064
			b $74
			b "Quickstart"
			b NULL

;*** "Mein Computer".
:MenuIcon_3		b $11
			w $0000
			b $00

			w Icon_Close
			b $0b,$10,$01,$08
			w $0000

			w Icon_20
			b $0c,$28,$02,$10
			w vC_Format
			w Icon_29
			b $0e,$28,$02,$10
			w vC_Validate
			w Icon_21
			b $10,$28,$02,$10
			w vC_Rename
			w Icon_22
			b $12,$28,$02,$10
			w vC_Dir
			w Icon_28
			b $14,$28,$02,$10
			w vC_DirPrint
			w Icon_23
			b $16,$28,$02,$10
			w vC_PartCMD
			w Icon_24
			b $18,$28,$02,$10
			w vC_MD
			w Icon_25
			b $1a,$28,$02,$10
			w vC_RD
			w Icon_26
			b $1c,$28,$02,$10
			w vC_CD
			w Icon_27
			b $1e,$28,$02,$10
			w vC_DiskCopy

			w Icon_30
			b $0c,$50,$02,$10
			w vC_DelFile
			w Icon_35
			b $0e,$50,$02,$10
			w vC_UndelFile
			w Icon_31
			b $10,$50,$02,$10
			w vC_RenFile
			w Icon_32
			b $12,$50,$02,$10
			w vC_PrnFile
			w Icon_33
			b $14,$50,$02,$10
			w vC_FileInfo
			w Icon_34
			b $16,$50,$02,$10
			w vC_SortDir

;*** Bubble-Help-Texte.
:IconText_3		w Text_M0			;CLOSE-Icon.
			w Text_M1			;DISK  : FORMAT
			w Text_M15			;DISK  : RENAME
			w Text_M2			;DISK  : VALIDATE
			w Text_M3			;DISK  : DIRECTORY
			w Text_M4			;DISK  : PRINT DIRECTORY
			w Text_M5			;DISK  : PARTITION
			w Text_M6			;SUBDIR: CREATE
			w Text_M7			;SUBDIR: DELETE
			w Text_M8			;SUBDIR: CHANGE
			w Text_M9			;DISK  : BACKUP
			w Text_M10			;FILE  : DELETE
			w Text_M16			;FILE  : RENAME
			w Text_M11			;FILE  : UNDELETE
			w Text_M12			;FILE  : PRINT
			w Text_M13			;FILE  : INFO
			w Text_M14			;FILE  : SORT

;*** Farbe für Icons.
:IconColor_3		w C_MenuClose			;CLOSE-Icon.
			w C_MenuMIcon			;DISK  : FORMAT
			w C_MenuMIcon			;DISK  : RENAME
			w C_MenuMIcon			;DISK  : VALIDATE
			w C_MenuMIcon			;DISK  : DIRECTORY
			w C_MenuMIcon			;DISK  : PRINT DIRECTORY
			w C_MenuMIcon			;DISK  : PARTITION
			w C_MenuMIcon			;SUBDIR: CREATE
			w C_MenuMIcon			;SUBDIR: DELETE
			w C_MenuMIcon			;SUBDIR: CHANGE
			w C_MenuMIcon			;DISK  : BACKUP
			w C_MenuMIcon			;FILE  : DELETE
			w C_MenuMIcon			;FILE  : RENAME
			w C_MenuMIcon			;FILE  : UNDELETE
			w C_MenuMIcon			;FILE  : PRINT
			w C_MenuMIcon			;FILE  : INFO
			w C_MenuMIcon			;FILE  : SORT

;*** Grafik für Menüfenster.
:WinText_3		b MOVEPENTO
			w $005c
			b $24
			b FRAME_RECTO
			w $0103
			b $3b

			b MOVEPENTO
			w $005c
			b $4c
			b FRAME_RECTO
			w $0103
			b $63

if Sprache = Deutsch
			b ESC_PUTSTRING
			w $0064
			b $24
			b "Menü - Diskette"

			b GOTOXY
			w $0064
			b $4c
			b "Menü - Datei"
			b NULL
endif

if Sprache = Englisch
			b ESC_PUTSTRING
			w $0064
			b $24
			b "Menu - disk"

			b GOTOXY
			w $0064
			b $4c
			b "Menu - file"
			b NULL
endif

;*** "MSDOS Computer".
:MenuIcon_4		b $0b
			w $0000
			b $00

			w Icon_Close
			b $0b,$10,$01,$08
			w $0000

			w Icon_20
			b $0c,$28,$02,$10
			w vD_Format
			w Icon_21
			b $0e,$28,$02,$10
			w vD_Rename
			w Icon_22
			b $10,$28,$02,$10
			w vD_Dir
			w Icon_28
			b $12,$28,$02,$10
			w vD_DirPrint
			w Icon_24
			b $14,$28,$02,$10
			w vD_MD
			w Icon_25
			b $16,$28,$02,$10
			w vD_RD

			w Icon_30
			b $0c,$50,$02,$10
			w vD_DelFile
			w Icon_31
			b $0e,$50,$02,$10
			w vD_RenFile
			w Icon_32
			b $10,$50,$02,$10
			w vD_PrnFile
			w Icon_33
			b $12,$50,$02,$10
			w vD_FileInfo

;*** Bubble-Help-Texte.
:IconText_4		w Text_M0			;CLOSE-Icon.
			w Text_M1			;DISK  : FORMAT
			w Text_M2			;DISK  : RENAME
			w Text_M3			;DISK  : DIRECTORY
			w Text_M4			;DISK  : PRINT DIRECTORY
			w Text_M6			;SUBDIR: CREATE
			w Text_M7			;SUBDIR: DELETE
			w Text_M10			;FILE  : DELETE
			w Text_M11			;FILE  : RENAME
			w Text_M12			;FILE  : PRINT
			w Text_M13			;FILE  : INFO

;*** Farbe für Icons.
:IconColor_4		w C_MenuClose			;CLOSE-Icon.
			w C_MenuMIcon			;DISK  : FORMAT
			w C_MenuMIcon			;DISK  : RENAME
			w C_MenuMIcon			;DISK  : DIRECTORY
			w C_MenuMIcon			;DISK  : PRINT DIRECTORY
			w C_MenuMIcon			;SUBDIR: CREATE
			w C_MenuMIcon			;SUBDIR: DELETE
			w C_MenuMIcon			;FILE  : DELETE
			w C_MenuMIcon			;FILE  : RENAME
			w C_MenuMIcon			;FILE  : PRINT
			w C_MenuMIcon			;FILE  : INFO

;*** Grafik für Menüfenster.
:WinText_4		b MOVEPENTO
			w $005c
			b $24
			b FRAME_RECTO
			w $00f3
			b $3b

			b MOVEPENTO
			w $005c
			b $4c
			b FRAME_RECTO
			w $00f3
			b $63

if Sprache = Deutsch
			b ESC_PUTSTRING
			w $0064
			b $24
			b "Menü - Diskette"

			b GOTOXY
			w $0064
			b $4c
			b "Menü - Datei"
			b NULL
endif

if Sprache = Englisch
			b ESC_PUTSTRING
			w $0064
			b $24
			b "Menü - disk"

			b GOTOXY
			w $0064
			b $4c
			b "Menü - file"
			b NULL
endif

;*** "Kopieren".
:MenuIcon_5		b $0f
			w $0000
			b $00

			w Icon_Close
			b $0b,$10,$01,$08
			w $0000

			w Icon_40
			b $0c,$28,$02,$10
			w vSetOptions
:MI_5a			w Icon_41
			b $0f,$28,$02,$10
			w $0001

			w Icon_60
			b $0c,$50,$02,$10
			w vDOStoCBM
			w Icon_51
			b $0e,$50,$02,$10
			w vDOStoCBM_F
			w Icon_52
			b $10,$50,$02,$10
			w vDOStoGW

			w Icon_60
			b $17,$50,$02,$10
			w vCBMtoDOS
			w Icon_51
			b $19,$50,$02,$10
			w vCBMtoDOS_F
			w Icon_52
			b $1b,$50,$02,$10
			w vGWtoDOS

			w Icon_60
			b $0c,$78,$02,$10
			w vCBMtoCBM
			w Icon_61
			b $0e,$78,$02,$10
			w vCBMtoGW
			w Icon_62
			b $10,$78,$02,$10
			w vGWtoCBM
			w Icon_52
			b $12,$78,$02,$10
			w vGWtoGW
			w Icon_51
			b $14,$78,$02,$10
			w vCBMtoCBM_F
			w Icon_63
			b $16,$78,$02,$10
			w vDuplicate

;*** Bubble-Help-Texte.
:IconText_5		w Text_M0			;CLOSE-Icon.
			w Text_M20			;Optionen ändern.
			w Text_M21			;Partitions-Auswahl.
			w Text_M30			;DOS => CBM
			w Text_M31			;DOS => CBM 1:1
			w Text_M32			;DOS => GW
			w Text_M33			;CBM => DOS
			w Text_M34			;CBM => DOS 1:1
			w Text_M35			;GW  => DOS
			w Text_M36			;CBM => CBM
			w Text_M37			;CBM => GW
			w Text_M38			;GW  => CBM
			w Text_M39			;GW  => GW
			w Text_M40			;CBM => CBM 1:1
			w Text_M41			;Duplicate

;*** Farbe für Icons.
:IconColor_5		w C_MenuClose			;CLOSE-Icon.
			w C_MenuMIcon			;Optionen ändern.
			w C_MenuMIcon			;Partitions-Auswahl.
			w C_MenuMIcon			;DOS => CBM
			w C_MenuMIcon			;DOS => CBM 1:1
			w C_MenuMIcon			;DOS => GW
			w C_MenuMIcon			;CBM => DOS
			w C_MenuMIcon			;CBM => DOS 1:1
			w C_MenuMIcon			;GW  => DOS
			w C_MenuMIcon			;CBM => CBM
			w C_MenuMIcon			;CBM => GW
			w C_MenuMIcon			;GW  => CBM
			w C_MenuMIcon			;GW  => GW
			w C_MenuMIcon			;CBM => CBM 1:1
			w C_MenuMIcon			;Duplicate

;*** Grafik für Menüfenster.
:WinText_5		b MOVEPENTO
			w $005c
			b $24
			b FRAME_RECTO
			w $0103
			b $3b

			b MOVEPENTO
			w $005c
			b $4c
			b FRAME_RECTO
			w $00ab
			b $63

			b MOVEPENTO
			w $00b4
			b $4c
			b FRAME_RECTO
			w $0103
			b $63

			b MOVEPENTO
			w $005c
			b $74
			b FRAME_RECTO
			w $0103
			b $8b

if Sprache = Deutsch
			b ESC_PUTSTRING
			w $0064
			b $24
			b "Optionen"
endif

if Sprache = Englisch
			b ESC_PUTSTRING
			w $0064
			b $24
			b "Options"
endif

			b GOTOXY
			w $0064
			b $4c
			b "DOS > CBM"

			b GOTOXY
			w $00bc
			b $4c
			b "CBM > DOS"

			b GOTOXY
			w $0064
			b $74
			b "CBM > CBM"
			b NULL

;*** "Setup".
:MenuIcon_6		b $0d
			w $0000
			b $00

			w Icon_Close
			b $0b,$10,$01,$08
			w $0000

			w Icon_80
			b $0c,$28,$02,$10
			w vSwapDrives
			w Icon_81
			b $0f,$28,$02,$10
			w Get_PrnDrv
			w Icon_82
			b $11,$28,$02,$10
			w Get_InpDrv
			w Icon_83
			b $17,$28,$02,$10
			w vParkHD
			w Icon_84
			b $19,$28,$02,$10
			w vUnParkHD

			w Icon_85
			b $0c,$50,$02,$10
			w vSetCMDtime
			w Icon_86
			b $0e,$50,$02,$10
			w vColorSetup
:MI_6a			w Icon_12
			b $11,$50,$02,$10
			w $0002
:MI_6c			w Icon_98
			b $13,$50,$02,$10
			w $0003
;--- Ergänzung: 22.12.18/M.Kanet
;Unterstützung für Option D'n'D On/Off ergänzt.
;Kann im Menü TOOLS ein-/ausgeschaltet werden.
:MI_6d			w Icon_91
			b $15,$50,$02,$10
			w $0005
:MI_6b			w Icon_89
			b $17,$50,$02,$10
			w $0004
			w Icon_87
			b $19,$50,$02,$10
			w SaveToolBox

;*** Bubble-Help-Texte.
:IconText_6		w Text_M0
			w Text_M70			;Laufwerke tauschen.
			w Text_M71			;Drucker wählen.
			w Text_M72			;Eingabetreiber wählen.
			w Text_M73			;Festplatte parken.
			w Text_M74			;Festplatte starten.
			w Text_M75			;Uhrzeit ändern.
			w Text_M78			;Farben ändern.
			w Text_M76			;Bubbles anzeigen.
			w Text_M81			;Mittlere Maustaste.
			w Text_M82			;Drag'n'Drop.
			w Text_M80			;Laufwerk abfragen.
			w Text_M77			;Toolbox speichern.

;*** Farbe für Icons.
:IconColor_6		w C_MenuClose
			w C_MenuMIcon			;Laufwerke tauschen.
			w C_MenuMIcon			;Drucker wählen.
			w C_MenuMIcon			;Eingabetreiber wählen.
			w $0016				;Festplatte parken.
			w $002e				;Festplatte starten.
			w C_MenuMIcon			;Uhrzeit ändern.
			w C_MenuMIcon			;Farben ändern.
			w $0007				;Bubbles anzeigen.
			w C_MenuMIcon			;Mittlere Maustaste.
			w C_MenuMIcon			;Drag'n'Drop.
			w C_MenuMIcon			;Laufwerk abfragen.
			w C_MenuMIcon			;Toolbox speichern.

;*** Grafik für Menüfenster.
:WinText_6		b MOVEPENTO
			w $005c
			b $24
			b FRAME_RECTO
			w $00db
			b $3b

			b MOVEPENTO
			w $005c
			b $4c
			b FRAME_RECTO
			w $00db
			b $63

if Sprache = Deutsch
			b ESC_PUTSTRING
			w $0064
			b $24
			b "Menü - Hardware"

			b GOTOXY
			w $0064
			b $4c
			b "Menü - System"
			b NULL
endif

if Sprache = Englisch
			b ESC_PUTSTRING
			w $0064
			b $24
			b "Menu - hardware"

			b GOTOXY
			w $0064
			b $4c
			b "Menu - system"
			b NULL
endif

if Sprache = Deutsch
;*** Bubble-Help-Texte.
:Text_M0		b "MENÜ",GOTOX,$33,$00
			b "VERLASSEN",NULL
:Text_M1		b "FORMAT",GOTOX,$33,$00
			b "DISKETTE",NULL
:Text_M2		b "NEUER",GOTOX,$33,$00
			b "DISKNAME",NULL
:Text_M3		b "DIRECTORY",GOTOX,$33,$00
			b "ANZEIGEN",NULL
:Text_M4		b "DIRECTORY",GOTOX,$33,$00
			b "DRUCKEN",NULL
:Text_M5		b "PARTITION",GOTOX,$33,$00
			b "WECHSELN",NULL
:Text_M6		b "DIRECTORY",GOTOX,$33,$00
			b "ERSTELLEN",NULL
:Text_M7		b "DIRECTORY",GOTOX,$33,$00
			b "LÖSCHEN",NULL
:Text_M8		b "DIRECTORY",GOTOX,$33,$00
			b "WECHSELN",NULL
:Text_M9		b "DISKETTE",GOTOX,$33,$00
			b "KOPIEREN",NULL
:Text_M10		b "DATEIEN",GOTOX,$33,$00
			b "LÖSCHEN",NULL
:Text_M11		b "NEUER",GOTOX,$33,$00
			b "DATEINAME",NULL
:Text_M12		b "DATEIEN",GOTOX,$33,$00
			b "DRUCKEN",NULL
:Text_M13		b "DATEIINFOS",GOTOX,$33,$00
			b "ANZEIGEN",NULL
:Text_M14		b "DIRECTORY",GOTOX,$33,$00
			b "SORTIEREN",NULL
:Text_M15		b "DISKETTE",GOTOX,$33,$00
			b "AUFRÄUMEN",NULL
:Text_M16		b "DATEIEN",GOTOX,$33,$00
			b "RETTEN",NULL
:Text_M20		b "OPTIONEN",GOTOX,$33,$00
			b "ÄNDERN",NULL
:Text_M21		b "PARTITION",GOTOX,$33,$00
			b "ABFRAGEN",NULL
:Text_M30		b "DOS - CBM",GOTOX,$33,$00
			b "TEXTE",NULL
:Text_M31		b "DOS - CBM",GOTOX,$33,$00
			b "DATEIEN",NULL
:Text_M32		b "DOS - GW",GOTOX,$33,$00
			b "TEXTE",NULL
:Text_M33		b "CBM - DOS",GOTOX,$33,$00
			b "TEXTE",NULL
:Text_M34		b "CBM - DOS",GOTOX,$33,$00
			b "DATEIEN",NULL
:Text_M35		b "GW - DOS",GOTOX,$33,$00
			b "TEXTE",NULL
:Text_M36		b "CBM - CBM",GOTOX,$33,$00
			b "TEXTE",NULL
:Text_M37		b "CBM - GW",GOTOX,$33,$00
			b "TEXTE",NULL
:Text_M38		b "GW - CBM",GOTOX,$33,$00
			b "TEXTE",NULL
:Text_M39		b "GW - GW",GOTOX,$33,$00
			b "TEXTE",NULL
:Text_M40		b "CBM - CBM",GOTOX,$33,$00
			b "DATEIEN",NULL
:Text_M41		b "BACKUP",GOTOX,$33,$00
			b "ERSTELLEN",NULL

;*** Bubble-Help-Texte.
:Text_M50		b "GEODOS",GOTOX,$33,$00
			b "BEENDEN",NULL
:Text_M51		b "ONLINE-",GOTOX,$33,$00
			b "HILFE",NULL
:Text_M52		b "GEODOS",GOTOX,$33,$00
			b "INFO",NULL
:Text_M56		b "GEOWRITE",GOTOX,$33,$00
			b "STARTEN",NULL
:Text_M57		b "GW-TEXT",GOTOX,$33,$00
			b "ÖFFNEN",NULL
:Text_M58		b "GW-TEXT",GOTOX,$33,$00
			b "DRUCKEN",NULL
:Text_M70		b "LAUFWERK",GOTOX,$33,$00
			b "TAUSCHEN",NULL
:Text_M71		b "DRUCKER-",GOTOX,$33,$00
			b "TREIBER",NULL
:Text_M72		b "EINGABE-",GOTOX,$33,$00
			b "TREIBER",NULL
:Text_M73		b "CMD HD",GOTOX,$33,$00
			b "PARKEN",NULL
:Text_M74		b "CMD HD",GOTOX,$33,$00
			b "STARTEN",NULL
:Text_M75		b "GEOS-",GOTOX,$33,$00
			b "UHRZEIT",NULL
:Text_M76		b "BUBBLES ",GOTOX,$33,$00
			b "ANZEIGEN",NULL
:Text_M77		b "TOOLBOX",GOTOX,$33,$00
			b "SPEICHERN",NULL
:Text_M78		b "FARBEN",GOTOX,$33,$00
			b "ÄNDERN",NULL
:Text_M79		b "BASIC",GOTOX,$33,$00
			b "AUFRUFEN",NULL
:Text_M80		b "LAUFWERKS",GOTOX,$33,$00
			b "AUSWAHL",NULL
:Text_M60		b "PROGRAMM",GOTOX,$33,$00
			b "STARTEN",NULL
:Text_M61		b "DOKUMENT",GOTOX,$33,$00
			b "ÖFFNEN",NULL
:Text_M62		b "DOKUMENT",GOTOX,$33,$00
			b "DRUCKEN",NULL
:Text_M63		b "HILFS-",GOTOX,$33,$00
			b "MITTEL",NULL
:Text_M64		b "BASIC-",GOTOX,$33,$00
			b "PROGRAMM",NULL
:Text_M81		b "MITTLERE",GOTOX,$33,$00
			b "MAUSTASTE",NULL
:Text_M82		b "D'n'D",GOTOX,$33,$00
			b "MODUS",NULL
endif

if Sprache = Englisch
;*** Bubble-Help-Texte.
:Text_M0		b "EXIT",GOTOX,$33,$00
			b "MENU",NULL
:Text_M1		b "FORMAT",GOTOX,$33,$00
			b "DISK",NULL
:Text_M2		b "NEW"	,GOTOX,$33,$00
			b "DISKNAME",NULL
:Text_M3		b "VIEW",GOTOX,$33,$00
			b "DIRECTORY",NULL
:Text_M4		b "PRINT",GOTOX,$33,$00
			b "DIRECTORY",NULL
:Text_M5		b "SWAP",GOTOX,$33,$00
			b "PARTITION",NULL
:Text_M6		b "CREATE",GOTOX,$33,$00
			b "DIRECTORY",NULL
:Text_M7		b "DELETE",GOTOX,$33,$00
			b "DIRECTORY",NULL
:Text_M8		b "CHANGE",GOTOX,$33,$00
			b "DIRECTORY",NULL
:Text_M9		b "CREATE",GOTOX,$33,$00
			b "DISKCOPY",NULL
:Text_M10		b "DELETE",GOTOX,$33,$00
			b "FILES",NULL
:Text_M11		b "RENAME",GOTOX,$33,$00
			b "FILES",NULL
:Text_M12		b "PRINT",GOTOX,$33,$00
			b "FILES",NULL
:Text_M13		b "EDIT",GOTOX,$33,$00
			b "FILEINFO",NULL
:Text_M14		b "SORT",GOTOX,$33,$00
			b "FILES",NULL
:Text_M15		b "VALIDATE",GOTOX,$33,$00
			b "DISK",NULL
:Text_M16		b "UNDELETE",GOTOX,$33,$00
			b "FILES",NULL
:Text_M20		b "CHANGE",GOTOX,$33,$00
			b "OPTIONS",NULL
:Text_M21		b "PARTITION",GOTOX,$33,$00
			b "MODE",NULL
:Text_M30		b "DOS - CBM",GOTOX,$33,$00
			b "TEXTFILES",NULL
:Text_M31		b "DOS - CBM",GOTOX,$33,$00
			b "FILES",NULL
:Text_M32		b "DOS - GW",GOTOX,$33,$00
			b "TEXTFILES",NULL
:Text_M33		b "CBM - DOS",GOTOX,$33,$00
			b "TEXTFILES",NULL
:Text_M34		b "CBM - DOS",GOTOX,$33,$00
			b "FILES",NULL
:Text_M35		b "GW - DOS",GOTOX,$33,$00
			b "TEXTFILES",NULL
:Text_M36		b "CBM - CBM",GOTOX,$33,$00
			b "TEXTFILES",NULL
:Text_M37		b "CBM - GW",GOTOX,$33,$00
			b "TEXTFILES",NULL
:Text_M38		b "GW - CBM",GOTOX,$33,$00
			b "TEXTFILES",NULL
:Text_M39		b "GW - GW",GOTOX,$33,$00
			b "TEXTE",NULL
:Text_M40		b "CBM - CBM",GOTOX,$33,$00
			b "FILE",NULL
:Text_M41		b "CREATE",GOTOX,$33,$00
			b "BACKUP",NULL

;*** Bubble-Help-Texte.
:Text_M50		b "EXIT",GOTOX,$33,$00
			b "GEODOS",NULL
:Text_M51		b "ONLINE-",GOTOX,$33,$00
			b "HELP",NULL
:Text_M52		b "GEODOS",GOTOX,$33,$00
			b "INFO",NULL
:Text_M56		b "OPEN",GOTOX,$33,$00
			b "GEOWRITE",NULL
:Text_M57		b "OPEN",GOTOX,$33,$00
			b "GW-TEXT",NULL
:Text_M58		b "PRINT",GOTOX,$33,$00
			b "GW-TEXT",NULL
:Text_M70		b "SWAP",GOTOX,$33,$00
			b "DRIVES",NULL
:Text_M71		b "PRINTER-",GOTOX,$33,$00
			b "DRIVER",NULL
:Text_M72		b "INPUT-",GOTOX,$33,$00
			b "DRIVER",NULL
:Text_M73		b "PARK",GOTOX,$33,$00
			b "CMD HD",NULL
:Text_M74		b "UNPARK",GOTOX,$33,$00
			b "CMD HD",NULL
:Text_M75		b "SET GEOS",GOTOX,$33,$00
			b "RTC-TIME",NULL
:Text_M76		b "VIEW ",GOTOX,$33,$00
			b "BUBBLES",NULL
:Text_M77		b "UPDATE",GOTOX,$33,$00
			b "TOOLBOX",NULL
:Text_M78		b "CHANGE",GOTOX,$33,$00
			b "COLORS",NULL
:Text_M79		b "CALL",GOTOX,$33,$00
			b "BASIC",NULL
:Text_M80		b "DRIVE",GOTOX,$33,$00
			b "SELECTION",NULL
:Text_M60		b "OPEN",GOTOX,$33,$00
			b "PROGRAMM",NULL
:Text_M61		b "OPEN",GOTOX,$33,$00
			b "DOKUMENT",NULL
:Text_M62		b "PRINT",GOTOX,$33,$00
			b "DOKUMENT",NULL
:Text_M63		b "DESC-",GOTOX,$33,$00
			b "ACCESSORY",NULL
:Text_M64		b "BASIC-",GOTOX,$33,$00
			b "PROGRAMM",NULL
:Text_M81		b "THIRD",GOTOX,$33,$00
			b "MOUSEKEY",NULL
:Text_M82		b "D'n'D",GOTOX,$33,$00
			b "MODE",NULL
endif

;*** Sprites
:Spr01			b %01111111,%11111111,%11111111
			b %10000000,%00000000,%00000000
			b %10000000,%00000000,%00000000
			b %10000000,%00000000,%00000000
			b %10000000,%00000000,%00000000
			b %10000000,%00000000,%00000000
			b %10000000,%00000000,%00000000
			b %10000000,%00000000,%00000000
			b %10000000,%00000000,%00000000
			b %10000000,%00000000,%00000000
			b %10000000,%00000000,%00000000
			b %10000000,%00000000,%00000000
			b %10000000,%00000000,%00000000
			b %10000000,%00000000,%00000000
			b %10000000,%00000000,%00000000
			b %10000000,%00000000,%00000000
			b %10000000,%00000000,%00000000
			b %01100000,%11111111,%11111111
			b %00100111,%00000000,%00000000
			b %01111000,%00000000,%00000000
			b %11100000,%00000000,%00000000
			b NULL

:Spr02			b %11111111,%11111111,%11111110
			b %00000000,%00000000,%00000001
			b %00000000,%00000000,%00000001
			b %00000000,%00000000,%00000001
			b %00000000,%00000000,%00000001
			b %00000000,%00000000,%00000001
			b %00000000,%00000000,%00000001
			b %00000000,%00000000,%00000001
			b %00000000,%00000000,%00000001
			b %00000000,%00000000,%00000001
			b %00000000,%00000000,%00000001
			b %00000000,%00000000,%00000001
			b %00000000,%00000000,%00000001
			b %00000000,%00000000,%00000001
			b %00000000,%00000000,%00000001
			b %00000000,%00000000,%00000001
			b %00000000,%00000000,%00000001
			b %11111111,%11111111,%11111110
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b NULL

:Spr03			b %01111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %01111111,%11111111,%11111111
			b %00111111,%00000000,%00000000
			b %01111000,%00000000,%00000000
			b %11100000,%00000000,%00000000
			b NULL

:Spr04			b %11111111,%11111111,%11111110
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111111
			b %11111111,%11111111,%11111110
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b NULL

:Spr05			s 64
:Spr06			b $ff,$ff,$00,$ff,$ff,$00,$ff,$ff,$00,$ff,$ff,$00
			b $ff,$ff,$00,$ff,$ff,$00,$ff,$ff,$00,$ff,$ff,$00
			b $ff,$ff,$00,$ff,$ff,$00,$ff,$ff,$00,$ff,$ff,$00
			b $ff,$ff,$00,$ff,$ff,$00,$ff,$ff,$00,$ff,$ff,$00
			b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
			b $00,$00,$00,$00
