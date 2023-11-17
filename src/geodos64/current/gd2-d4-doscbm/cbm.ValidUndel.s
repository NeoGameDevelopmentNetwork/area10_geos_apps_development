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

:dir3Head		=	$9c80
:DRIVE_MASK		=	%00001111
:INV_TRACK		=	$02

endif

			n	"mod.#411.obj"
			o	ModStart

			jmp	CBM_Validate
			jmp	CBM_Undelete

			t	"-CBM_GetDskNam"
			t	"-CBM_ChkNmSd2"

;*** Diskette validieren.
:CBM_Validate		lda	Target_Drv
			jsr	LoadNewDisk

;*** Commodore-Datei drucken.
:SetValOpt		jsr	IsDskInDrv

			ClrB	curSubMenu		;Zeiger auf Hauptmenü.

;*** Bildschirm aufbauen.
:SetPrnOpt1		jsr	Bildschirm_a

;*** Auswahlmenü darstellen.
:SetPrnOpt2		jsr	InitMenuPage		;Menüseite initialisieren.

;*** Menü aktivieren.
			jsr	SetHelp

			LoadW	otherPressVec,ChkOptSlct
			LoadW	r0,Icon_Tab3
			jsr	DoIcons			;Icon-Menü aktivieren.

:SetPrnOpt3		StartMouse
			NoMseKey
			rts

;*** Zeiger auf Hilfedatei bereitstellen.
:SetHelp		LoadW	r0,HelpFileName
			lda	#<SetPrnOpt1
			ldx	#>SetPrnOpt1
			jmp	InstallHelp

;*** Zurück zu GeoDOS.
:L411ExitGD		jsr	ClrWin
			jmp	InitScreen

;*** Bildschirm löschen,
;    Vektor ":otherPressVec" löschen.
:ClrWin			ClrW	otherPressVec
			jmp	ClrScreen

;*** Dateinamen ausgeben.
:PrnFileName		ldy	#$00			;Dateiname ausgeben.
::101			sty	:102 +1

			lda	(r15L),y
			beq	:103
			jsr	SmallPutChar

::102			ldy	#$ff
			iny
			cpy	#16
			bne	:101
::103			rts

;*** Fenster aufbauen.
:Bildschirm_a		jsr	ClrScreen		;Bildschirm löschen.

			jsr	i_C_MenuTitel
			b	$00,$00,$28,$01
			jsr	i_C_MenuBack
			b	$00,$01,$28,$18

			FillPRec$00,$00,$07,$0008,$013f

			jsr	UseGDFont		;Titel ausgeben.
			PrintStrgV411a0

			LoadW	r0,V411h0		;Menügrafik zeichnen.
			jsr	GraphicsString
			jsr	i_C_Register
			b	$01,$05,$0b,$01
			jsr	i_C_Register
			b	$0d,$05,$09,$01

			jsr	i_C_MenuMIcon
			b	$00,$01,$0a,$03
			rts

;*** Menüseite initialisieren.
:InitMenuPage		jsr	i_C_MenuBack		;Menüfenster löschen.
			b	$01,$06,$26,$13
			FillPRec$00,$31,$b7,$0001,$013e

			lda	curSubMenu		;Menütext ausgeben.
			asl
			tax
			lda	MenuText+0,x
			sta	r0L
			lda	MenuText+1,x
			sta	r0H
			jsr	PutString

;*** Bildschirm aufbauen.
:SetClkPos		jsr	SetDataVec		;Zeiger auf Menütabelle.

			FillPRec$00,$b9,$c6,$0001,$013e

			jsr	UseGDFont		;GeoDOS-Font aktivieren.
			ClrB	currentMode

			lda	curSubMenu		;Text für Fußzeile ausgeben.
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

::101			ldy	#$00			;Menüoptionen ausgeben.
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
			lda	V411i0+0,x
			sta	a7L
			lda	V411i0+1,x
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
			jsr	DefColOpt		;Farbe für Optionsfeld definieren.
			jsr	SetColOpt		;Farbe für Optionsfeld darstellen.
			ldy	#$ff
			rts

;*** Prüfen ob Option angeklickt.
:ChkOptSlct		lda	#$00
			jsr	:110			;Klick auf "Verzeichnis" ?
			bne	:102			;Ja, weiter...

			lda	#$06
			jsr	:110			;Klick auf "Optionen" ?
			bne	:103			;Ja, weiter...

::101			jmp	:120			;Wurde Option angeklickt ?

::102			lda	#$00
			b $2c
::103			lda	#$01
			cmp	curSubMenu
			beq	:105
			sta	curSubMenu
			jmp	SetPrnOpt2		;Nein, weitertesten.
::105			jmp	SetPrnOpt3

;*** Mausbereich prüfen.
::110			clc
			adc	#<V411b0
			sta	a7L
			lda	#$00
			adc	#>V411b0
			sta	a7H

			jsr	CopyRecData		;Werte aus Menütabelle nach ":r2".
			jmp	IsMseInRegion		;Ist Maus innerhalb eines Options-

;*** Optionsbereich prüfen.
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

;*** Aktuelles Laufwerk wechseln.
:SetOpt1a		ldx	Target_Drv		;Zeiger auf nächstes Laufwerk.
::101			inx
			cpx	#12			;Letztes Laufwerk erreicht ?
			bcc	:102			;Nein, weiter...
			ldx	#8			;Laufwerk #8 aktivieren.
::102			lda	DriveTypes-8,x		;Laufwerk verfügbar ?
			beq	:101			;Nein, nächstes Laufwerk.
			txa
			jmp	LoadNewDisk

;*** Aktuelles Laufwerk anzeigen.
:DefOpt1a		lda	#$00			;Ausgabe-Fenster löschen.
			jsr	ShowClkOpt

			lda	Target_Drv		;Laufwerksbuchstaben berechnen.
			add	$39
			sta	:101 +10

			Print	$0024,$4e
if Sprache = Deutsch
::101			b	PLAINTEXT,"Laufwerk x: ",NULL
endif
if Sprache = Englisch
::101			b	PLAINTEXT,"Drive    x: ",NULL
endif

			lda	Target_Drv		;Laufwerksbezeichnung ausgeben.
			sub	8
			asl
			asl
			asl
			clc
			adc	#<Drive_ASCII
			sta	r15L
			lda	#$00
			adc	#>Drive_ASCII
			sta	r15H
			jsr	PrnFileName
			ldy	#$ff
			rts

;*** Partition wechseln.
:SetOpt1b		bit	DiskInDrv
			bpl	:101
			bit	curDrvMode		;CMD-Laufwerk ?
			bmi	:102			;Ja, weiter...
::101			rts

::102			pla
			pla
			jsr	ClrWin			;Bildschirm löschen.
			jsr	CMD_OtherPart		;Partition wechseln.
			txa
			bmi	:103
			bne	:104
			jmp	SetValOpt		;Optionen anzeigen.
::103			jmp	L411ExitGD
::104			jmp	DiskError

;*** Diskette wechseln.
:SetOpt1c		lda	curDrvMode
			and	#%00001000
			beq	:101
			lda	Target_Drv
			jmp	LoadNewDisk

::101			pla
			pla
			jsr	InsertNewDsk		;Neue Diskette einlegen.
			jmp	SetPrnOpt1		;Optionen anzeigen.

;*** Aktuelle Partition anzeigen.
:DefOpt1b		lda	#$00			;Ausgabe-Fenster löschen.
			jsr	ShowClkOpt
			bit	DiskInDrv		;Diskette im Laufwerk ?
			bpl	:101			;Nein, weiter...
			bit	curDrvMode		;CMD-Laufwerk ?
			bpl	:102			;Nein, weiter...

			LoadW	r11,$0024		;Partitionsname ausgeben.
			LoadB	r1H,$76
			LoadW	r15,Part_Info+5
			jsr	PrnFileName
			ldy	#$ff
			rts

::101			Print	$0024,$76
if Sprache = Deutsch
			b	PLAINTEXT,"(Keine Diskette)",NULL
endif
if Sprache = Englisch
			b	PLAINTEXT,"(No disk)",NULL
endif
			ldy	#$ff
			rts

::102			PrintXY	$0024,$76,cbmDiskName
			ldy	#$ff
			rts

;*** Icons ausgeben.
:ChangeIcon1		lda	#$48
			b $2c
:ChangeIcon2		lda	#$70
			sta	:101 +6
::101			jsr	i_BitmapUp
			w	Icon_02
			b	$23,$68,$01,$08
			ldy	#$ff
			rts

;*** Weitere Partitionen.
:SetOpt2a		bit	curDrvMode		;CMD-Laufwerk?
			bpl	:101			; => Nein, Option deaktivieren.
			lda	MoreValidate
			eor	#%11111111
			b $2c
::101			lda	#$00
			sta	MoreValidate
			rts

;*** Weitere Partitionen.
:DefOpt2a		bit	curDrvMode		;CMD-Laufwerk?
			bpl	:101			; => Nein, Option deaktivieren.
			bit	MoreValidate
			bpl	:101
			ldy	#$02
::101			rts

;*** Defekte Dateien löschen.
:SetOpt2b		lda	KillErrorFile
			eor	#%11111111
			sta	KillErrorFile
			rts

;*** Defekte Dateien löschen.
:DefOpt2b		bit	KillErrorFile
			bpl	:101
			ldy	#$02
::101			rts

;*** Dateilänge korrigieren.
:SetOpt2c		lda	ChkFileSize
			eor	#%11111111
			sta	ChkFileSize
			rts

;*** Dateilänge korrigieren.
:DefOpt2c		bit	ChkFileSize
			bpl	:101
			ldy	#$02
::101			rts

;*** Dateien schließen.
:SetOpt2d		lda	CloseFiles
			eor	#%11111111
			sta	CloseFiles
			rts

;*** Dateien schließen.
:DefOpt2d		bit	CloseFiles
			bpl	:101
			ldy	#$02
::101			rts

;*** Unterverzeichnis-Header prüfen.
:SetOpt2e		ldx	curDrive
			lda	DriveModes-8,x
			and	#%00100000
			beq	:101
			lda	ChkNMSubD
			eor	#%11111111
			b $2c
::101			lda	#$00
			sta	ChkNMSubD
			rts

;*** Unterverzeichnis-Header prüfen.
:DefOpt2e		ldx	curDrive
			lda	DriveModes-8,x
			and	#%00100000
			beq	:101
			bit	ChkNMSubD
			bpl	:101
			ldy	#$02
::101			rts

;*** Neue Diskette einlegen.
:InsertNewDsk		jsr	ClrWin			;Bildschirm löschen.

			lda	Target_Drv		;Diskette einlegen.
			ldx	#$ff
			jsr	InsertDisk
			cmp	#$01
			beq	:101

			ldx	#$00
			b $2c
::101			ldx	#$ff
			stx	DiskInDrv

			lda	Target_Drv

;*** Neue Diskette öffnen.
:LoadNewDisk		sta	Target_Drv
			jsr	NewDrive

			jsr	IsDskInDrv
			bit	DiskInDrv
			bmi	:101
			rts

::101			bit	curDrvMode
;--- Ergänzung: 08.10.18/M.Kanet
;Der Originalcode überspringt bei nicht-CMD-Laufwerken auch das öffnen
;des Hauptverzeichnisses auf NativeMode-Laufwerken.
;			bpl	:103
			bpl	:102

			ldx	Target_Drv		;Partition aktivieren.
			lda	DrivePart -8,x
			jsr	SetNewPart

::102			lda	curDrvMode
			and	#%00100000
			beq	:103
			jsr	New_CMD_Root
::103			jsr	NewOpenDisk
::104			txa
			beq	:105
			lda	#$ff
::105			eor	#%11111111
			sta	DiskInDrv

			bit	DiskInDrv
			bpl	:106
			jsr	CBM_GetDskNam
::106			rts

;*** Neue Partition aktivieren.
:LoadNewPart		bit	curDrvMode		;CMD-Laufwerk ?
			bpl	:101			;Nein, weiter...

			ldx	Target_Drv		;Partition aktivieren.
			lda	DrivePart -8,x
			jsr	SetNewPart

			lda	#$ff
			rts
::101			lda	#$00
			rts

;*** Diskette im Laufwerk ?
:IsDskInDrv		jsr	NewOpenDisk		;Diskette öffnen.
			txa				;Fehler ?
			beq	:101			;Nein, weiter...
			lda	#$ff			;Keine Diskette!
::101			eor	#%11111111
			sta	DiskInDrv
			rts

;*** Diskette validieren.
:StartValid		lda	#$00
			sta	ErrorFiles		;Anzahl gelöschter Dateien = $00.
			sta	otherPressVec+0		;Vektoren löschen.
			sta	otherPressVec+1
			sta	keyVector    +0
			sta	keyVector    +1

			jsr	ClrScreen

			tsx
			stx	StackPointer

			bit	DiskInDrv		;Diskette im Laufwerk ?
			bmi	StartValid2		;Nein, weiter...
			rts

:StartValid2		jsr	DoInfoBox
			PrintStrgV411c0

			lda	Target_Drv
			jsr	NewDrive

			lda	curDrvMode
;--- Ergänzung: 30.09.18/M.Kanet
;NativeMode ist mit RAMNative und IECBusNative auch auf nicht-CMD-Laufwerken
;möglich. Daher Bit#7 nicht mehr prüfen.
;			bpl	:102
			and	#%00100000
			beq	:102
			jsr	New_CMD_Root
::102			jsr	NewOpenDisk
			txa				;Diskettenfehler ?
			bne	:103			;Ja, Abbruch.

			jsr	ClrBoxText
			PrintStrgV411c1
			jsr	ClearBAM		;Leere BAM im Speicher erzeugen.
			txa				;Diskettenfehler ?
			beq	StartValidDsk		;Nein, weiter...
::103			jmp	DiskError

;*** Verzeichnis validieren.
:StartValidDsk

;--- Ergänzung: 29.11.18/M.Kanet
;Verzeichnis-Header überprüfen. Das sortieren von Verzeichnissen kann
;ungültige Angaben im Verzeichnis-Header zum passenden Verzeichnis-
;Eintrag erzeugen.
			bit	ChkNMSubD		;Verzeichnis-Header prüfen?
			bpl	:99			; => Nein, weiter...
			jsr	ClrScreen		;Bildschirm löschen.
			jsr	VerifyNMDir		;Verzeichnis-Header prüfen.

::99			jsr	ValidScreen
			PrintStrgV411e5

			jsr	EnterTurbo		;GEOS-Turbo aktivieren.
			txa				;Diskettenfehler ?
			beq	:101
::100			jmp	DiskError

::101			jsr	InitForIO		;IO aktivieren.

			lda	curType			;Ersten Directory-Block einlesen.
			jsr	Get1stDirBlk
::102			jsr	ValidateDir		;Verzeichnis-Sektor in BAM belegen.
			txa				;Diskettenfehler ?
			bne	:103			;Ja, Abbruch.

			lda	fileHeader+1		;Zeiger auf nächsten Verzeichnis-
			sta	r1H			;Sektor richten.
			lda	fileHeader+0
			sta	r1L
			bne	:102			;Nächsten Sektor belegen.

			LoadW	r5,curDirHead
			jsr	ChkDkGEOS
			bit	isGEOS			;GEOS-Diskette ?
			bpl	:104			;Nein, weiter...

			lda	curDirHead+172		;Zeiger auf Borderblock richten.
			sta	r1H
			lda	curDirHead+171
			sta	r1L			;Borderblock verfügbar ?
			beq	:104			;Nein, weiter...

			jsr	ValidateDir		;Borderblock belegen.
			txa				;Diskettenfehler ?
			beq	:104			;Nein, weiter...

;*** Diskettenfehler, Abbruch zum DeskTop.
::103			jsr	DoneWithIO		;Abbruch.
			jmp	PrnStatus

;*** Unterverzeichnisse aufräumen.
::104			jsr	DoneWithIO		;IO abschalten.
			jsr	PutDirHead		;BAM auf Diskette schreiben.

			lda	curDrvMode
;--- Ergänzung: 30.09.18/M.Kanet
;NativeMode ist mit RAMNative und IECBusNative auch auf nicht-CMD-Laufwerken
;möglich. Daher Bit#7 nicht mehr prüfen.
;			bpl	:106
			and	#%00100000		;NativeMode ?
			beq	:106			;Nein, weiter...

			jsr	ValidSDir		;Unterverzeichnisse validieren.
			txa				;Diskettenfehler ?
			beq	:106			;Nein, weiter...
::105			jmp	PrnStatus		;Abbruch.

;--- Ergänzung: 01.11.18/M.Kanet
;Wheels hat einen internen Zähler für die Zahl an freien Blöcken. Dieser
;wird direkt bei CalcBlksFree nach :r4 kopiert. Es findet keine tatsächliche
;Prüfung der BAM statt!
;Die Anzahl der freien Blöcke werden nach OpenDisk errechnet. Dabei wird die
;Anzahl der freien Blocks ohne die Sektoren #0 bis #63 ermittelt.
;Hinweis: Die Berechnung der freien Sektoren findet im TurboDOS von Wheels
;         statt. Einsprung bei $0513 im Laufwerks-RAM.
;Danach wird bei jedem AllocateBlock dieser Zähler korrigiert.
;Markiert man beim anlegen einer neuen BAM die Sektoren #0 bis #63 als
;belegt, dann korrigiert Wheels die Anzahl der freien Sektoren nach unten,
;da keine Prüfung auf Track#1/Sektor #0-63 stattfindet.
;Damit stimmt dann beim Anzeigen des Verzeichnisses unter GeoDOS die Anzahl
;der belegten Sektoren nicht mehr.
;Daher muss hier OpenDisk aufgerufen werden da hier die Wheels-TurboDOS-
;Routine aufgerufen wird um die Anzahl freier Sektoren zu ermitteln.
::106			jsr	OpenDisk
			txa
			bne	:105

			jsr	ClrScreen

;*** Weitere Partitionen bearbeiten ?
:MoreCMD_Part		lda	ErrorFiles
			beq	:101

			DB_OK	V411g5

::101			bit	curDrvMode
			bpl	:102
			bit	MoreValidate
			bmi	:103
::102			jmp	L411ExitGD

::103			jsr	ClrWin			;Bildschirm löschen.
			jsr	CMD_OtherPart		;Partition wechseln.
			txa
			bmi	:104
			bne	:105
			jmp	SetValOpt		;Optionen anzeigen.
::104			jmp	L411ExitGD
::105			jmp	DiskError

;*** Anzahl gelöschter Dateien ausgeben.
:ErrorMaxFile		jsr	ISet_Info

			CmpBI	ErrorFiles,2
			bcs	:101
			PrintStrgV411g8
			rts

::101			PrintStrgV411g6

			MoveB	ErrorFiles,r0L
			ClrB	r0H
			lda	#%11000000
			jsr	PutDecimal

			PrintStrgV411g7
			rts

;*** BAM löschen.
:ClearBAM		lda	curType
			and	#DRIVE_MASK
			cmp	#3
			beq	Is1581
			cmp	#4
			beq	:101
			jmp	No1581

::101			lda	curDrvType
			cmp	#Drv_GWRD		;RAM-Laufwerk?
			bne	:102			; => Nein, weiter...
			lda	curDirHead +1		;Echtes RAMNative z.B. MegaPatch?
			cmp	#$22			;BAM ist dann in den Sektoren 2-33.
			bne	:103			; => Nein, weiter...
			lda	curDirHead +2
			cmp	#"H"
			bne	:103			; => Nein, weiter...
::102			jmp	IsNative

::103			jmp	IsRAMDisk

;*** BAM für 1581 erzeugen.
:Is1581			ldy	#16
::101			lda	#40
			sta	dir2Head,y
			sta	dir3Head,y
			iny
			ldx	#4
			lda	#$ff
::102			sta	dir2Head,y
			sta	dir3Head,y
			iny
			dex
			bpl	:102
			tya
			bne	:101

;--- Link-Bytes für BAM-Sektor #1/#2 setzen.
			LoadB	dir2Head+  0,$28
			LoadB	dir2Head+  1,$02
			LoadB	dir3Head+  0,$00
			LoadB	dir3Head+  1,$ff

;--- Anzahl freier Sektoren auf Track #40 (Sek.40/0+1+2 sind durch BAM belegt)
			LoadB	dir2Head+250,37

;--- BAM-Sektoren in der Sektor-Tabelle als belegt markieren.
			LoadB	dir2Head+251,%11111000

;--- Verzeichnis in BAM belegen.
			jsr	AllocDir		;Verzeichnis in BAM belegen.
			txa				;Fehler?
			bne	:disk_error		; => Ja, Abbruch...

;--- Ergänzung: 26.04.19/M.Kanet
;Nach dem reservieren der Verzeichnis-
;Sektoren die BAM auf Disk speichern.
			jmp	PutDirHead		;BAM aktualisieren.
::disk_error		rts

;*** BAM für 1541/1571 erzeugen.
:No1581			pha				;Laufwerktyp speichern.

			LoadB	r1L,1

			ldy	#4
::101			sty	r0L
			jsr	GetSectors

			ldy	r0L
			lda	r1H
			sta	curDirHead+0,y

			lda	#$ff
			sta	curDirHead+1,y
			sta	curDirHead+2,y

			lda	r1H
			sec
			sbc	#16
			tax
			lda	BAM_BitTab-1,x
			sta	curDirHead+3,y
			iny
			iny
			iny
			iny
			inc	r1L
			cpy	#144
			bcc	:101

			dec	curDirHead+72
			LoadB	curDirHead+73,%1111 1110

			pla
			cmp	#2			;Laufwerkstyp = 1571?
			bne	:103			; => Nein, weiter...

			lda	curDirHead+3		;Doppelseitig?
			beq	:103			; => Nein, weiter...

			jsr	i_FillRam
			w	256,dir2Head
			b	0

			jsr	i_FillRam
			w	105,dir2Head
			b	$ff

			LoadB	r1L,36
			LoadB	r0H,2

			ldy	#221
::102			sty	r0L
			jsr	GetSectors

			ldy	r0L
			lda	r1H
			sta	curDirHead,y

			lda	r1H
			sec
			sbc	#16
			tax
			lda	BAM_BitTab-1,x
			ldx	r0H
			sta	dir2Head,x

			AddVB	3,r0H
			inc	r1L
			iny
			bne	:102

			LoadB	curDirHead+238,0
			sta	dir2Head+51
			sta	dir2Head+52
			sta	dir2Head+53

;--- Verzeichnis in BAM belegen.
::103			jsr	AllocDir		;Verzeichnis in BAM belegen.
			txa				;Fehler?
			bne	:disk_error		; => Ja, Abbruch...

;--- Ergänzung: 26.04.19/M.Kanet
;Nach dem reservieren der Verzeichnis-
;Sektoren die BAM auf Disk speichern.
			jmp	PutDirHead		;BAM aktualisieren.
::disk_error		rts

;*** Native-BAM erzeugen.
:IsNative		jsr	InitSek1BAM		;BAM-Sektor #1 erzeugen/speichern.
			txa				;Fehler?
			bne	:103			; => Ja, Abbruch...

			jsr	InitForIO		;I/O aktivieren.

			LoadB	r6L,$01			;Bam-Sektoren #1/0 bis #1/33 belegen.
			LoadB	r6H,$00
::102			jsr	AllocAllDrv
			txa
			bne	:102a
			inc	r6H
;--- Ergänzung: 01.11.18/M.Kanet
;Ursprünglich wurde hier auf r6H < 32 geprüft. Die BAM reicht
;aber von Sektor #2 bis einschließlich #33.
;Daher Vergleich auf < 34 geändert.
			CmpBI	r6H,34
			bcc	:102

::102a			jsr	DoneWithIO		;I/O abschalten.
			txa				;BAM-Fehler?
			bne	:103			; => Ja, Abbruch...

			jsr	PutDirHead		;BAM auf Disk speichern.
			txa
			beq	:104
::103			jmp	PrnStatus

::104			jsr	EnterTurbo		;TurboDOS aktivieren.
			txa
			bne	:103

			jsr	InitForIO		;I/O aktivieren.
			jsr	InitSek2BAM		;BAM-Sektor #3 bis #33 initialisieren.

			LoadB	r1L,$01
			LoadB	r1H,$03
			LoadW	r4,diskBlkBuf
::106			jsr	WriteBlock
			txa
			beq	:107
			jsr	DoneWithIO
			jmp	PrnStatus

::107			inc	r1H
			CmpBI	r1H,34
			bcc	:106

			jsr	DoneWithIO

			jsr	GetDirHead		;BAM einlesen.
			txa				;Fehler?
			bne	:103			; => Ja, Abbruch...

;--- Ergänzung: 01.11.18/M.Kanet
;Ursprünglich wurden nur 32 Sektoren belegt. Die BAM reicht aber von
;Sektor #2 bis einschließlich #33. Daher wurden hier im Original-Code
;die letzten beiden Sektoren manuell als belegt markiert.
;Befehl entfällt...
;			lda	#%00111111		;Sektor #32/33 belegt.
;			sta	dir2Head+$24		;BAM-Byte Track #1, Sektor 32-39.

;--- Verzeichnis in BAM belegen.
			jsr	AllocDir		;Verzeichnis in BAM belegen.
			txa				;Fehler?
			bne	:103			; => Ja, Abbruch...

;--- Ergänzung: 26.04.19/M.Kanet
;Nach dem reservieren der Verzeichnis-
;Sektoren die BAM auf Disk speichern.
			jmp	PutDirHead		;BAM aktualisieren.

;*** RAMDisk validieren (gateWay-NativeRAMDisk)
:IsRAMDisk		jsr	InitSek1BAM		;BAM-Sektor #1 erzeugen/speichern.
			txa				;Fehler?
			bne	:103			; => Ja, Abbruch...

			jsr	InitForIO

			LoadB	r6L,$01
			LoadB	r6H,$00
::102			jsr	AllocAllDrv
			txa
			bne	:102a
			inc	r6H
			CmpBI	r6H,$05
			bcc	:102

::102a			jsr	DoneWithIO		;I/O abschalten.
			txa				;BAM-Fehler?
			bne	:103			; => Ja, Abbruch...

			jsr	PutDirHead		;BAM auf Disk speichern.
			txa
			beq	:104
::103			jmp	PrnStatus

::104			jsr	EnterTurbo		;TurboDOS aktivieren.
			txa
			bne	:103

			jsr	InitForIO		;I/O aktivieren.
			jsr	InitSek2BAM		;BAM-Sektor #3 bis #5 initialisieren.

			LoadB	r1L,$01			;BAM-Sektoren #3 bis #5 schreiben.
			LoadB	r1H,$03			;Die BAM einer gateWay-RAMDisk
			LoadW	r4,diskBlkBuf		;hat max. 7(Sek#2) +3*8(Sek#3-#5)
::106			jsr	WriteBlock		;=31 Tracks a 256 Sektoren = 2Mb.
			txa
			beq	:107
			jsr	DoneWithIO
			jmp	PrnStatus

::107			inc	r1H
			CmpBI	r1H,6
			bcc	:106

			jsr	DoneWithIO

			jsr	GetDirHead		;BAM einlesen.
			txa				;Fehler?
			bne	:103			; => Ja, Abbruch...

;--- Verzeichnis in BAM belegen.
			jsr	AllocDir		;Verzeichnis in BAM belegen.
			txa				;Fehler?
			bne	:103			; => Ja, Abbruch...

;--- Ergänzung: 26.04.19/M.Kanet
;Nach dem reservieren der Verzeichnis-
;Sektoren die BAM auf Disk speichern.
			jmp	PutDirHead		;BAM aktualisieren.

;*** BAM-Sektor #1 löschen.
:InitSek1BAM		ldy	#$20
			lda	#$ff
::101			sta	dir2Head,y
			iny
			bne	:101

;--- Ergänzung: 01.11.18/M.Kanet
;Bei Wheels wird beim belegen von Sektoren in der BAM ggf. die BAM nachgeladen
;falls diese sich noch nicht im Speicher befindet. Daher neue BAM direkt auf
;Disk speichern.
			LoadB	r1L,1			;Zeiger auf BAM-Sektor #1.
			LoadB	r1H,2			;(Track #1/Sektor #2)
			LoadW	r4,dir2Head		;Zeiger auf BAM-Speicher.
			jsr	PutBlock		;BAM-Sektor schreiben.
			txa				;Fehler?
			bne	:102			; => Ja, Abbruch...

			jsr	GetDirHead		;BAM einlesen.
::102			rts

;*** BAM-Sektor #2 löschen.
:InitSek2BAM		ldy	#$00
			lda	#$ff
::101			sta	diskBlkBuf,y
			iny
			bne	:101
			rts

;*** Verzeichnis in BAM belegen.
;--- Ergänzung: 26.04.19/M.Kanet
;Routine als Unterprogramm ausgelagert.
;Aufruf über 'jsr AllocDir'.
;Rückgabe: XReg > $00, Fehler.
:AllocDir		lda	curType			;Ersten Directory-Block einlesen.
			jsr	Get1stDirBlk

			MoveW	r1,curDirHead
			jsr	EnterTurbo		;GEOS-Turbo aktivieren.
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch.

			jsr	InitForIO		;IO aktivieren.
			jsr	AllocChain		;Verzeichnis belegen.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch.

			LoadW	r5,curDirHead
			jsr	ChkDkGEOS
			bit	isGEOS			;GEOS-Diskette ?
			bpl	:101			;Nein, weiter...

			lda	curDirHead+172		;Zeiger auf Borderblock richten.
			sta	r6H
			lda	curDirHead+171
			sta	r6L
			beq	:101
			jsr	AllocAllDrv		;Borderblock belegen.

::101			jsr	DoneWithIO		;IO abschalten.
::102			rts

;*** Unterverzeichnisse Validieren.
:ValidSDir		lda	curType			;Ersten Directory-Block einlesen.
			jsr	Get1stDirBlk

			LoadW	r4,fileHeader		;Zeiger auf Zwischenspeicher.
::101			jsr	GetBlock		;Verzeichnis-Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:105			;Ja, Abruch.

			ldy	#$02
::102			lda	fileHeader,y		;Dateityp einlesen.
			and	#%00001111		;Dateityp-Flag isolieren.
			cmp	#$06			;Verzeichnis ?
			beq	:107			;Ja, Verzeichnis validieren.

::103			tya				;Zeiger auf nächsten Eintrag.
			add	$20
			tay				;Letzter Eintrag überprüft ?
			bcc	:102			;Nein, weiter...

			lda	fileHeader+1		;Zeiger auf nächsten Sektor.
			sta	r1H
			lda	fileHeader+0
			sta	r1L			;Ende erreicht ?
			bne	:101			;Nein, weiter...

::104			ldx	curDirHead+$22		;Hauptverzeichnis ?
			ldy	curDirHead+$23
			cpx	#$00
			bne	:106			;Nein, zum übergeordneten Verzeichnis.
			cpy	#$00
			bne	:106			;Nein, zum übergeordneten Verzeichnis.

			ldx	#$00			;Ja, Ende...
::105			rts

;*** Übergeordnetes Verzeichnis öffnen.
::106			lda	curDirHead+$24		;Zeiger auf PARENT-Spur merken.
			pha
			lda	curDirHead+$25		;Zeiger auf PARENT-Sektor merken.
			pha
			lda	curDirHead+$26		;Zeiger auf PARENT-Eintrag merken.
			pha
			txa				;Zeiger auf neuen Verzeichniszweig
			pha				;zwischenspeichern.
			tya
			pha
			jsr	PutDirHead		;BAM speichern.
			pla
			sta	r1H
			pla
			sta	r1L
			jsr	New_CMD_SubD		;Unterverzeichnis öffnen.
			pla				;Zeiger auf PARENT-Eintrag
			sta	:106a +1 		;wiederherstellen.
			pla
			sta	r1H
			pla
			sta	r1L

			txa				;Diskettenfehler ?
			bne	:105			;Ja, Abruch.

			LoadW	r4,fileHeader
			jsr	GetBlock		;PARENT-Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:105			;Ja, Abruch.
::106a			ldy	#$ff
			jmp	:103			;Zeiger auf nächsten Eintrag.

;*** Neues Unterverzeichnis öffnen.
::107			tya
			pha
			jsr	PutDirHead
			pla
			tay
			lda	fileHeader+1,y
			sta	r1L
			lda	fileHeader+2,y
			sta	r1H
			jsr	New_CMD_SubD		;Unterverzeichnis öffnen.
			txa				;Diskettenfehler ?
			bne	:108			;Ja, Abruch.

			jsr	ValSDirChain		;Verzeichniszweig validieren.
			txa				;Diskettenfehler ?
			bne	:108			;Nein, weiter...
			jmp	ValidSDir
::108			rts				;Ja, Abbruch.

;*** Verzeichniszweig validieren.
:ValSDirChain		jsr	PrnSDirName

			jsr	EnterTurbo		;GEOS-Turbo aktivieren.
			txa				;Diskettenfehler ?
			bne	:103			;Ja, Abbruch....

			jsr	InitForIO		;IO aktivieren.

			lda	curType			;Ersten Directory-Block einlesen.
			jsr	Get1stDirBlk
::101			jsr	ValidateDir		;Verzeichnis-Sektor in BAM belegen.
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch.

			lda	fileHeader+1		;Zeiger auf nächsten Verzeichnis-
			sta	r1H			;Sektor richten.
			lda	fileHeader+0
			sta	r1L
			bne	:101			;Nächsten Sektor belegen.
::102			jmp	DoneWithIO
::103			rts

;*** Alle Dateien im aktuellen Verzeichnis-Sektor belegen.
:ValidateDir		PushW	r1			;Zeiger auf Track/Sektor merken.

			LoadW	r4,fileHeader		;Dir_Sektor einlesen.
			jsr	ReadBlock
			txa				;Diskettenfehler ?
			beq	:100			;Ja, Abbruch.
			jmp	:107

::100			lda	r4L			;Zeiger auf Dateityp erzeugen.
			clc
			adc	#2
			sta	r5L
			lda	r4H
			adc	#00
			sta	r5H

::101			ldy	#0			;Dateityp einlesen.
			lda	(r5L),y			;Datei korrekt geschlossen ?
			bmi	:103			;Ja, weiter...
			beq	:102			;Gelöschte Datei ? -> Übergehen.

			bit	CloseFiles		;Dateien schließen ?
			bpl	:102			;Nein, -> löschen.
			ora	#%10000000		;"Closed"-Bit setzen.
			sta	(r5L),y
			jmp	:103

::102			lda	#$00			;Eintrag löschen.
			tay
			sta	(r5L),y
			jmp	:105

::103			ldy	#22
			lda	(r5L),y			;GEOS-Filetyp einlesen.
			cmp	#TEMPORARY
			beq	:102

::104			jsr	ValidateFile		;Datei validieren.
			txa				;Diskettenfehler ?
			beq	:105			;Nein, weiter...

			bit	KillErrorFile		;Defekte Dateien automatisch löschen ?
			bpl	:107			;Nein, Fehler anzeigen.

			ldy	#$00			;Dateieintrag löschen.
			tya
			sta	(r5L),y

			PopW	r1
			LoadW	r4,fileHeader		;Dir_Sektor einlesen.
			jsr	WriteBlock
			txa
			bne	:108

			jsr	VerWriteBlock
			txa
			bne	:108

			jsr	DoneWithIO

			inc	ErrorFiles		;Anzahl defekter Dateien +1.
			ldx	StackPointer		;Stapel korrigieren.
			txs
			jsr	ClrScreen
			jmp	StartValid2		;Neustart von "Validate".

::105			lda	r5L			;Zeiger auf nächsten Dir_Eintrag.
			clc
			adc	#32
			sta	r5L
			bcs	:106
			jmp	:101

::106			PopW	r1			;Zeiger auf Track/Sektor einlesen.
			LoadW	r4,fileHeader		;Zeiger auf Dir_Sektor.
			jsr	WriteBlock		;Sektor schreiben.
			txa				;Diskettenfehler ?
			bne	:108			;Ja, Abbruch.
			jmp	VerWriteBlock		;Sektor-Verify.

::107			PopW	r1			;Disk_Error. Stapel korrigieren.
::108			rts				;Abbruch.

;*** Ersten Directory-Sektor ermitteln.
:Get1stDirBlk		and	#DRIVE_MASK		;Laufwerkstyp ermtteln.
			cmp	#$03
			beq	:101
			cmp	#$04
			beq	:102

			lda	#18			;1541/1571-Laufwerk:
			ldy	#01			;Sektor 18/1.
			bne	:103

::101			lda	#40			;1581-Laufwerk:
			ldy	#03			;Sektor 40/3.
			bne	:103

::102			lda	curDirHead+0		;Native-Laufwerk:
			ldy	curDirHead+1		;Sektor aus ":curDirHead" entnehmen.
::103			sta	r1L			;Zeiger auf ersten Sektor
			sty	r1H			;im Verzeichnis merken.
			rts

;*** Einzelne Datei validieren.
; r5 - Zeiger auf den Directory-Eintrag
;      (wird aktualisiert)
:ValidateFile		jsr	PrintName

			lda	#0
			sta	r2L			;Zähler für belegte Blöcke
			sta	r2H			;löschen.

			ldy	#22
			lda	(r5L),y			;GEOS-Filetyp einlesen.
			beq	:104			;$00 = "nicht GEOS" ? Ja, weiter...

			ldy	#19			;Zeiger auf Track/Sektor Info-Block.
			jsr	CopySekAdr		;Sektor-Adresse nach ":r1" kopieren.
			jsr	AllocChain		;Info-Block belegen.
			txa				;Diskettenfehler ?
			bne	:107			;Ja, Abbruch.

			ldy	#21
			lda	(r5L),y			;Dateistruktur einlesen.
			beq	:104			;$00 = Seq ? Ja, weiter...

;*** VLIR-Dateien.
;    VLIR-Header einlesen und alle VLIR-Datensätze
;    in der BAM als belegt kennzeichnen.
			ldy	#1			;Zeiger auf Track/Sektor VLIR-Header.
			jsr	CopySekAdr		;Sektor-Adresse nach ":r1" kopieren.
			LoadW	r4,fileTrScTab
			jsr	ReadBlock		;VLIR-Header einlesen.
			txa				;Diskettenfehler ?
			bne	:107			;Ja, Abbruch.

			ldy	#2			;Zeiger auf ersten VLIR-Datensatz.
::101			lda	fileTrScTab,y		;Startadresse Track/Sektor des VLIR-
			sta	r1L			;Datensatzes nach ":r1" kopieren.
			iny
			ldx	fileTrScTab,y
			stx	r1H

			cpy	#1			;Wurden bereits alle 254 VLIR-
			beq	:104			;Datensätze belegt ? yReg = $01 -> Ja!

			iny
			lda	r1L			;VLIR-Datensatz vorhanden ?
			beq	:103			;Nein, weiter...

::102			tya				;yReg sichern.
			pha
			jsr	AllocChain		;VLIR-Datensatz belegen.
			pla
			tay				;yReg zurücksetzen.
			txa				;Diskettenfehler ?
			bne	:107			;Ja, Abbruch.
			beq	:101			;Nein, nächsten VLIR-Datensatz belegen.

::103			txa				;Sektor = $FF ? Datensatz übergehen.
			bne	:101			;Sektor = $00 ? Vorzeitig beenden.

;*** Datensatz belegen.
;    VLIR = Nur VLIR-Header belegen.
;    SEQ  = Datei belegen.
::104			ldy	#1			;Zeiger auf Track/Sektor Startsektor.
			jsr	CopySekAdr		;Sektor-Adresse nach ":r1" kopieren.
			jsr	AllocChain		;Datei belegen.
			txa				;Diskettenfehler ?
			bne	:107			;Ja, Abbruch.

::105			bit	ChkFileSize		;Dateilänge korrigieren ?
			bpl	:106			;Nein, weiter...

			ldy	#28			;Anzahl der belegten Sektoren in
			lda	r2L			;Dateieintrag kopieren.
			sta	(r5L),y
			iny
			lda	r2H
			sta	(r5L),y

::106			ldx	#0
::107			rts

;*** Track/Sektor aus Dateieintrag einlesen.
:CopySekAdr		lda	(r5L),y
			sta	r1L
			iny
			lda	(r5L),y
			sta	r1H
			rts

;*** Sektor-Kette in der BAM belegen.
:AllocChain		ldx	r1L			;Track = $00 ?
			beq	:104			;Ja, Ende...

			LoadW	r4,diskBlkBuf		;Zeiger auf Zwischenspeicher.

;*** Link-Bytes des ersten Datenblocks einlesen.
::101			ldx	#>ReadLink		;Routine für 1571/1581/Native etc...
			ldy	#<ReadLink
			lda	curType
			and	#DRIVE_MASK
			cmp	#$01
			bne	:102

			ldx	#>ReadBlock		;Routine für 1541...
			ldy	#<ReadBlock
::102			tya
			jsr	CallRoutine		;"ReadLink" (71,81..) "ReadBlock" (41).
			txa				;Diskettenfehler ?
			bne	:104			;Ja, Abbruch.

			MoveW	r1,r6			;Sektor in BAM belegen.
			jsr	AllocAllDrv
			txa				;Diskettenfehler ?
			bne	:104			;Ja, Abbruch.

			inc	r2L			;Zähler für Sektoren +1.
			bne	:103
			inc	r2H

::103			lda	diskBlkBuf+1		;Zeiger auf nächsten Sektor.
			sta	r1H
			lda	diskBlkBuf+0
			sta	r1L
			bne	:101			;Ende erreicht ? Nein, weiter...
::104			rts

;*** Sektor auf allen Laufwerken belegen.
:AllocAllDrv		jsr	DoneWithIO

			lda	curType			;Lafwerk vom Typ 1541 ?
			and	#DRIVE_MASK
			cmp	#$01
			beq	:101			;Ja, weiter...
			jsr	AllocateBlock		;Sektor in BAM belegen.
			jmp	:103

;*** Sonderbehandlung 1541.
::101			jsr	FindBAMBit		;Prüfen, ob Sektor bereits belegt.
			beq	:102			;Ja, Fehler "BAD BAM", Abbruch.

			lda	r8H			;Sektor in BAM belegen.
			eor	#$ff
			and	curDirHead,x
			sta	curDirHead,x
			ldx	r7H			;Anzahl freie Sektoren auf Track -1.
			dec	curDirHead,x

			ldx	#0			;Kein Fehler.
			b $2c
::102			ldx	#6			;Fehler "BAD_BAM".
::103			txa
			pha
			jsr	InitForIO
			pla
			tax
			rts

;*** Sektor-Anzahl für Spur-Nr. bestimmen.
:GetSectors		lda	r1L			;Track = $00 ?
			beq	:101			;Ja, Abbruch.

			lda	curType			;Laufwerkstyp festlegen.
			and	#DRIVE_MASK
			tay
			dey				;1541-Laufwerk ?
			bne	:102			;Nein, weiter...

			CmpBI	r1L,36			;Track von $01 - $33 ?
			bcc	:103			;Ja, weiter...
::101			ldx	#INV_TRACK		;Fehler "Invalid Track".
			rts				;Abbruch.

::102			dey				;1571-Laufwerk ?
			bne	:107			;Nein, weiter...

			CmpBI	r1L,71			;Track von $00 - $46 ?
			bcs	:101			;Nein, Abbruch.

::103			ldy	#7			;Zeiger auf Track-Tabelle.
::104			cmp	Tracks,y		;Track > Tabellenwert ?
			bcs	:105			;Ja, max. Anzahl Sektoren einlesen.
			dey				;Zeiger auf nächsten Tabellenwert.
			bpl	:104			;Weiteruchen.
			bmi	:101			;Ungültige Track-Adresse.

::105			tya				;Bei 1571 auf Track $01-$33 begrenzen.
			and	#%0000 0011
			tay
			lda	Sectors,y		;Anzahl Sektoren einlesen
::106			sta	r1H			;und merken...
			ldx	#0			;"Kein Fehler"...
			rts

::107			ldx	#$0d			;Routine wird nur bei 1541/1571
			rts				;aufgerufen. Bei 1581/Native -> Fehler.

;*** Bildschirm aufbauen.
:ValidScreen		jsr	ClrScreen

			jsr	i_C_MenuTitel
			b	$04,$04,$20,$01
			jsr	i_C_MenuBack
			b	$04,$05,$20,$0d
			FrameRec$28,$8f,$0020,$011f,%11111111

			jsr	UseGDFont
			PrintStrgV411d0

			FrameRec$37,$40,$008f,$0110,%11111111
			jsr	i_ColorBox
			b	$12,$07,$10,$01,$01
			FrameRec$47,$50,$008f,$0110,%11111111
			jsr	i_ColorBox
			b	$12,$09,$10,$01,$01
			FrameRec$57,$60,$008f,$0110,%11111111
			jsr	i_ColorBox
			b	$12,$0b,$10,$01,$01
			FrameRec$67,$70,$008f,$0110,%11111111
			jsr	i_ColorBox
			b	$12,$0d,$10,$01,$01

			PrintStrgV411e0
			jsr	PrnDiskName
			jmp	PrnSDirName

;*** 1541,1571,1581: Disketten-Name ausgeben.
;*** CMD/Native    : Partitions-Name ausgeben.
:PrnDiskName		lda	curDrvMode
;--- Ergänzung: 30.09.18/M.Kanet
;NativeMode ist mit RAMNative und IECBusNative auch auf nicht-CMD-Laufwerken
;möglich. Daher Bit#7 nicht mehr prüfen.
;			bpl	:100
			and	#%00100000		;NativeMode?
			beq	:100			; => Nein, weiter...
			lda	curDrvMode		;CMD-Laufwerk?
			bmi	:101			; => Ja, weiter...

			ldx	#r15L			;RAMNative-Laufwerk.
			jsr	GetPtrCurDkNm		;Diskname und Verzeichnis ausgeben.
			LoadB	DirType,$ff
			jmp	:102

::100			ldx	#r15L			;Nicht-CMD-Laufwerk, nur
			jsr	GetPtrCurDkNm		;Diskname ausgeben.
			ClrB	DirType
			jmp	:102

::101			jsr	GetCurPInfo		;CMD-Laufwerk, Partition und
							;Verzeichnis ausgeben.

			LoadW	r15,Part_Info+5
			LoadB	DirType,$ff

::102			jsr	UseGDFont
			ClrB	currentMode

			LoadW	r11,$0092
			LoadB	r1H,$3e

			lda	#$00
::103			pha
			tay
			lda	(r15L),y
			jsr	ConvertChar
			jsr	SmallPutChar
			pla
			add	1
			cmp	#16
			bcc	:103

			rts

;*** 1541,1571,1581: Keine Ausgabe.
;*** CMD/Native    : Verzeichnis-Name ausgeben.
:PrnSDirName		FillPRec$00,$48,$4f,$0090,$010f

			bit	DirType
			bpl	:102

			ldx	#r15L
			jsr	GetPtrCurDkNm

			jsr	UseGDFont
			ClrB	currentMode

			LoadW	r11,$0092
			LoadB	r1H,$4e

			lda	#$00
::101			pha
			tay
			lda	(r15L),y
			jsr	ConvertChar
			jsr	SmallPutChar
			pla
			add	1
			cmp	#16
			bcc	:101

::102			rts

;*** Dateiname ausgeben.
:PrintName		jsr	DoneWithIO

			lda	r5L
			sta	r15L
			pha
			lda	r5H
			sta	r15H
			pha

			FillPRec$00,$58,$5f,$0090,$010f

			jsr	UseGDFont
			ClrB	currentMode

			LoadW	r11,$0092
			LoadB	r1H,$5e

			lda	#$03
::101			pha
			tay
			lda	(r15L),y
			beq	:102
			jsr	ConvertChar
			jsr	SmallPutChar
			pla
			add	1
			cmp	#$13
			bcc	:101

			pha
::102			pla

			pla
			sta	r5H
			pla
			sta	r5L

			jmp	InitForIO

;*** Status-Meldung ausgeben.
:PrnStatus		stx	ExitDskErr +1

			lda	#<V411e1
			ldy	#>V411e1
			cpx	#$06
			beq	:101
			lda	#<V411e2
			ldy	#>V411e2
::101			sta	r0L
			sty	r0H
			jsr	PutString

			ldx	#$ff			;Zurück zur MainLoop.
			txs
			lda	#>MainLoop -1
			pha
			lda	#<MainLoop -1
			pha

			FillPRec$00,$20,$27,$0020,$011f
			PrintStrgV411e4

			jsr	i_C_MenuDIcon
			b	$1c,$0f,$06,$02
			LoadW	r0,Icon_Tab1
			jmp	DoIcons

:ExitDskErr		ldx	#$ff
			jmp	DiskError

;*** Gelöschte Datei wiederherstellen.
:CBM_Undelete		jsr	GetDelFiles
			txa
			bmi	:104
			bne	:105

			lda	#<V411f0
			ldx	#>V411f0
			jsr	SelectBox

			lda	r13L
			cmp	#$80
			bcc	:104
			cmp	#$90
			beq	:103
			cmp	#$ff
			beq	StartUndel

			and	#%01111111
			add	8			;Neue Laufwerksadr. berechnen und
			sta	Target_Drv		;zwischenspeichern.
			jsr	NewDrive		;Laufwerk aktivieren.
			jmp	CBM_Undelete

::103			jsr	CMD_NewTarget
			jmp	CBM_Undelete
::104			jmp	InitScreen
::105			jmp	DiskError

;*** Dateien wiederherstellen.
:StartUndel		ClrB	AnzahlFiles
			LoadW	a0,FileNTab

:UndelNextFile		jsr	ValidScreen
			PrintStrgV411e6

::101			ldy	#$00
			lda	(a0L),y
			bne	:102
			jmp	UndelInfo

::102			jsr	NewOpenDisk		;BAM einlesen.
			txa
			bne	:107

			jsr	FindDelFile
			txa
			beq	:104
::103			AddVBW	16,a0
			jmp	:101

::104			jsr	CopyDirEntry

			LoadW	a1,dirEntryBuf
			jsr	UndelFile
			txa
			beq	:105
			jmp	FileDestruct

::105			jsr	FindDelFile
			txa
			bne	:103

			ldx	#$00
::106			lda	dirEntryBuf,x
			sta	fileHeader,y
			iny
			inx
			cpx	#30
			bcc	:106

			jsr	PutBlock
			txa
			bne	:107

			jsr	PutDirHead
			txa
			bne	:107
			inc	AnzahlFiles
			jmp	:103

::107			jmp	DiskError

;*** Datei bereits zerstört.
:FileDestruct		AddVBW	16,a0

			PrintStrgV411e3

			FillPRec$00,$20,$27,$0020,$011f
			PrintStrgV411e4

			jsr	i_C_MenuDIcon
			b	$1c,$0f,$06,$02
			LoadW	r0,Icon_Tab2
			jmp	DoIcons

;*** Datei suchen.
:FindDelFile		lda	curType
			jsr	Get1stDirBlk

::101			LoadW	r4,fileHeader
			jsr	GetBlock

			ldy	#$02
::102			lda	fileHeader,y
			beq	:104
::103			tya
			add	32
			tay
			bcc	:102

			lda	fileHeader+1
			sta	r1H
			lda	fileHeader+0
			sta	r1L
			bne	:101
			ldx	#$05
			rts

::104			tya
			pha
			tax
			ldy	#$00
::105			lda	fileHeader+3,x
			cmp	(a0L),y
			beq	:106
			pla
			tay
			jmp	:103

::106			inx
			iny
			cpy	#16
			bcc	:105

			pla
			tay
			ldx	#$00
			rts

;*** Dateieintrag in Zwischenspeicher kopieren.
:CopyDirEntry		ldx	#$00
::101			lda	fileHeader,y
			sta	dirEntryBuf,x
			iny
			inx
			cpx	#30
			bcc	:101
			rts

;*** Datei wiederherstellen.
:UndelFile		jsr	EnterTurbo		;GEOS-Turbo aktivieren.
			txa				;Diskettenfehler ?
			beq	:101			;Nein, weiter...
			rts				;Abbruch.

::101			jsr	InitForIO		;IO aktivieren.

			MoveW	a1,r5
			jsr	ValidateFile		;Validate ausführen.
			txa				;Diskettenfehler ?
			bne	:103			;Ja, Abbruch.

			ldx	#$82			;Dateityp $82 für gelöschte Datei

			ldy	#21
			lda	(a1L),y			;Dateistruktur einlesen.
			beq	:102			;SEQ  = Datei "PRG".
			inx				;VLIR = Datei "USR".
::102			txa

			ldy	#0
			sta	(a1L),y			;Dateityp in Dateieintrag kopieren.

			ldx	#0			;Flag für "Kein Fehler".
::103			jmp	DoneWithIO		;IO abschalten.

;*** Gelöschte Dateien einlesen.
:GetDelFiles		lda	curDrive
			ldx	#$00			;Diskette einlegen.
			jsr	InsertDisk
			cmp	#$01
			beq	:101
			ldx	#$ff			;Keine Dateien gewählt.
			rts				;Abbruch.

;*** Zeiger auf ersten Datei-Eintrag.
::101			jsr	NewOpenDisk		;BAM einlesen.
			txa
			beq	:102
::100			rts

::102			ClrB	AnzahlFiles
			LoadW	a0,FileNTab

			jsr	i_FillRam
			w	256*17
			w	FileNTab
			b	$00

			lda	curType
			jsr	Get1stDirBlk

::103			LoadW	r4,fileHeader
			jsr	GetBlock
			txa
			bne	:100

			ldy	#$02
::104			lda	fileHeader,y
			beq	:106
::105			tya
			add	32
			tay
			bcc	:104

			lda	fileHeader+1
			sta	r1H
			lda	fileHeader+0
			sta	r1L
			bne	:103
			ldx	#$00
			rts

::106			lda	fileHeader+$01,y
			beq	:105
			lda	fileHeader+$16,y
			beq	:107
			cmp	#TEMPORARY
			beq	:105

::107			inc	AnzahlFiles

			tya
			pha
			tax
			ldy	#$00
::108			lda	fileHeader+3,x
			sta	(a0L),y
			inx
			iny
			cpy	#16
			bcc	:108

			AddVBW	16,a0

			pla
			tay

			CmpBI	AnzahlFiles,255
			bcc	:105
			ldx	#$00
			rts

;*** Informationen ausgeben.
:UndelInfo		jsr	ClrScreen

			lda	AnzahlFiles
			beq	:101

			DB_OK	V411g1
			jmp	InitScreen

::101			DB_OK	V411g0
			jmp	InitScreen

;*** Anzahl Dateien ausgeben.
:UndelMaxFile		jsr	ISet_Info

			CmpBI	AnzahlFiles,2
			bcs	:101
			PrintStrgV411g4
			rts

::101			PrintStrgV411g2

			MoveB	AnzahlFiles,r0L
			ClrB	r0H
			lda	#%11000000
			jsr	PutDecimal

			PrintStrgV411g3
			rts

;*** Name der Hilfedatei.
:HelpFileName		b "05,GDH_CBM/Disk",NULL

;*** Variablen.
:curSubMenu		b $00
:StackPointer		b $00
:ChkNMSubD		b $00				;Unterverzeichnis-Header prüfen.
:ChkFileSize		b $ff				;Dateilängen korrigieren.
:KillErrorFile		b $00				;Defekte Dateien löschen.
:MoreValidate		b $00				;$FF = Weitere Partitionen aufräumen.
:CloseFiles		b $ff				;$FF = Dateien schließen.
:DiskInDrv		b $00				;$FF = Diskette im Laufwerk.
:ErrorFiles		b $00				;Anzahl defekter Dateien.
:DirType		b $00				;$FF = Unterverzeichnis.

;*** Tabelle mit Tracks, bei denen ein Wechsel der
;    Sektoranzahl/Track stattfindet.
:Tracks			b $01,$12,$19,$1f,$24,$35,$3c,$42
:Sectors		b $15,$13,$12,$11

;*** Tabelle zum belegen von Sektoren in der BAM.
:BAM_BitTab		b %00000001
			b %00000011
			b %00000111
			b %00001111
			b %00011111

;*** Menüvariablen.
:MenuText		w V411h1, V411h2
:InfoText		w V411a1, V411a2

if Sprache = Deutsch
:V411a0			b PLAINTEXT
			b GOTOXY
			w $0008
			b $06
			b "CBM  -  Verzeichnis aufräumen",NULL

:V411a1			b "Aktuelles Verzeichnis",NULL
:V411a2			b "Optionen",NULL
endif

if Sprache = Englisch
:V411a0			b PLAINTEXT
			b GOTOXY
			w $0008
			b $06
			b "CBM  -  Validate directory",NULL

:V411a1			b "Current directory",NULL
:V411a2			b "Options",NULL
endif

:V411b0			b $28,$2f
			w $0008,$005f
			b $28,$2f
			w $0068,$00af

;*** Texte für Info-Fenster.
if Sprache = Deutsch
:V411c0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Diskette wird"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "initialisiert...",NULL

:V411c1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Neue Disketten-BAM"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "wird erzeugt...",NULL

:V411c2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Laufwerk wird"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "initialisiert...",NULL

;*** Texte für Info-Fenster.
:V411c3			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Datei wird gerettet:"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b NULL

;*** Bildschirmtext.
:V411d0			b PLAINTEXT
			b GOTOXY
			w $0030
			b $3e
			b "Diskette   :"
			b GOTOXY
			w $0030
			b $4e
			b "Verzeichnis:"
			b GOTOXY
			w $0030
			b $5e
			b "Datei      :"
			b GOTOXY
			w $0030
			b $6e
			b "Status     :"
			b NULL
endif

;*** Texte für Info-Fenster.
if Sprache = Englisch
:V411c0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Initializing disk..."
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b NULL

:V411c1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Create new directory"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "on target-disk...",NULL

:V411c2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Initializing"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "disk-drive...",NULL

;*** Texte für Info-Fenster.
:V411c3			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Restore file:"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b NULL

;*** Bildschirmtext.
:V411d0			b PLAINTEXT
			b GOTOXY
			w $0030
			b $3e
			b "Disk       :"
			b GOTOXY
			w $0030
			b $4e
			b "Directory  :"
			b GOTOXY
			w $0030
			b $5e
			b "File       :"
			b GOTOXY
			w $0030
			b $6e
			b "Status     :"
			b NULL
endif

;*** Status-Meldungen.
if Sprache = Deutsch
:V411e0			b PLAINTEXT
			b GOTOXY
			w $0092
			b $6e
			b "OK!",NULL

:V411e1			b PLAINTEXT
			b GOTOXY
			w $0092
			b $6e
			b "BAM defekt!",NULL

:V411e2			b PLAINTEXT
			b GOTOXY
			w $0092
			b $6e
			b "Diskettenfehler!",NULL

:V411e3			b PLAINTEXT
			b GOTOXY
			w $0092
			b $6e
			b "Datei defekt!",NULL

:V411e4			b PLAINTEXT
			b GOTOXY
			w $0028
			b $26
			b "Systemmeldung",NULL

:V411e5			b PLAINTEXT
			b GOTOXY
			w $0028
			b $26
			b "Diskette aufräumen",NULL

:V411e6			b PLAINTEXT
			b GOTOXY
			w $0028
			b $26
			b "Dateien retten",NULL
endif

if Sprache = Englisch
:V411e0			b PLAINTEXT
			b GOTOXY
			w $0092
			b $6e
			b "OK!",NULL

:V411e1			b PLAINTEXT
			b GOTOXY
			w $0092
			b $6e
			b "BAM corrupt!",NULL

:V411e2			b PLAINTEXT
			b GOTOXY
			w $0092
			b $6e
			b "Diskerror!",NULL

:V411e3			b PLAINTEXT
			b GOTOXY
			w $0092
			b $6e
			b "File corrupt!",NULL

:V411e4			b PLAINTEXT
			b GOTOXY
			w $0028
			b $26
			b "Information",NULL

:V411e5			b PLAINTEXT
			b GOTOXY
			w $0028
			b $26
			b "Validate disk",NULL

:V411e6			b PLAINTEXT
			b GOTOXY
			w $0028
			b $26
			b "Restore file",NULL
endif

;*** Dialogboxen.
:V411f0			b $04
			b $c0
			b $ff
			b $10
			b $00
			w V411f1
			w FileNTab
if Sprache = Deutsch
:V411f1			b PLAINTEXT,"Gelöschte Dateien",NULL
endif
if Sprache = Englisch
:V411f1			b PLAINTEXT,"Deleted files",NULL
endif

;*** Fehlermeldungen.
if Sprache = Deutsch
:V411g0			w :101, :102, ISet_Info
::101			b BOLDON,"Es konnte keine gelöschte",NULL
::102			b        "Datei gerettet werden!",NULL

:V411g1			w :101, :101, UndelMaxFile
::101			b BOLDON,NULL

:V411g2			b PLAINTEXT,BOLDON
			b GOTOXY
			w $0063
			b $48
			b "Es konnten ",NULL
:V411g3			b " Dateien"
			b GOTOXY
			w $0063
			b $52
			b "gerettet werden!",NULL

:V411g4			b PLAINTEXT,BOLDON
			b GOTOXY
			w $0063
			b $48
			b "Es konnte 1 Datei"
			b GOTOXY
			w $0063
			b $52
			b "gerettet werden!",NULL

:V411g5			w :101, :101, ErrorMaxFile
::101			b BOLDON,NULL

:V411g6			b PLAINTEXT,BOLDON
			b GOTOXY
			w $0063
			b $48
			b "Es wurden ",NULL
:V411g7			b " defekte"
			b GOTOXY
			w $0063
			b $52
			b "Dateien gelöscht!",NULL

:V411g8			b PLAINTEXT,BOLDON
			b GOTOXY
			w $0063
			b $48
			b "Es wurde 1 defekte"
			b GOTOXY
			w $0063
			b $52
			b "Datei gelöscht!",NULL
endif

;*** Fehlermeldungen.
if Sprache = Englisch
:V411g0			w :101, :102, ISet_Info
::101			b BOLDON,"Unable to restore",NULL
::102			b        "deleted files!",NULL

:V411g1			w :101, :101, UndelMaxFile
::101			b BOLDON,NULL

:V411g2			b PLAINTEXT,BOLDON
			b GOTOXY
			w $0063
			b $48
			b NULL
:V411g3			b " files restored"
			b GOTOXY
			w $0063
			b $52
			b "on target-disk!",NULL

:V411g4			b PLAINTEXT,BOLDON
			b GOTOXY
			w $0063
			b $48
			b "File restored!"
			b GOTOXY
			w $0063
			b $52
			b NULL

:V411g5			w :101, :101, ErrorMaxFile
::101			b BOLDON,NULL

:V411g6			b PLAINTEXT,BOLDON
			b GOTOXY
			w $0063
			b $48
			b NULL
:V411g7			b " corrupted file"
			b GOTOXY
			w $0063
			b $52
			b "deleted!",NULL

:V411g8			b PLAINTEXT,BOLDON
			b GOTOXY
			w $0063
			b $48
			b "One corrupted file"
			b GOTOXY
			w $0063
			b $52
			b "deleted!",NULL
endif

;*** Menügrafik.
if Sprache = Deutsch
:V411h0			b MOVEPENTO
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
			b "Verzeichnis"
			b GOTOX
			w $006c
			b "Optionen"

			b NULL

endif

if Sprache = Englisch
:V411h0			b MOVEPENTO
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
			b "Directory"
			b GOTOX
			w $006c
			b "Options"

			b NULL
endif

;*** Menütexte.
if Sprache = Deutsch
:V411h1			b ESC_GRAPHICS
			b MOVEPENTO
			w $0018
			b $42
			b FRAME_RECTO
			w $0127
			b $54

			b MOVEPENTO
			w $0018
			b $6a
			b FRAME_RECTO
			w $0127
			b $7c

			b MOVEPENTO
			w $0018
			b $9a
			b FRAME_RECTO
			w $0127
			b $ac

			b ESC_PUTSTRING
			w $0020
			b $42
			b PLAINTEXT
			b "Aktuelles Laufwerk"

			b GOTOXY
			w $0020
			b $6a
			b "Diskette/Partition"

			b GOTOXY
			w $0020
			b $9a
			b PLAINTEXT
			b "CMD-Laufwerke"

			b GOTOXY
			w $0034
			b $a6
			b "Weitere Partitionen bearbeiten"
			b NULL

:V411h2			b ESC_GRAPHICS
			b MOVEPENTO
			w $0018
			b $42
			b FRAME_RECTO
			w $0127
			b $5c

			b MOVEPENTO
			w $0018
			b $72
			b FRAME_RECTO
			w $0127
			b $ac

			b ESC_PUTSTRING
			w $0020
			b $42
			b "Verzeichnis-Optionen"

			b GOTOXY
			w $0034
			b $4e
			b "Unterverzeichnis-Header prüfen"

			b GOTOXY
			w $0020
			b $72
			b "Datei-Optionen"

			b GOTOXY
			w $0034
			b $7e
			b "Defekte Dateien löschen"

			b GOTOXY
			w $0034
			b $8e
			b "Dateilänge korrigieren"

			b GOTOXY
			w $0034
			b $9e
			b "Geöffnete Dateien schließen"
			b NULL
endif

;*** Menügrafik.
if Sprache = Englisch
;*** Menütexte.
:V411h1			b ESC_GRAPHICS
			b MOVEPENTO
			w $0018
			b $42
			b FRAME_RECTO
			w $0127
			b $54

			b MOVEPENTO
			w $0018
			b $6a
			b FRAME_RECTO
			w $0127
			b $7c

			b MOVEPENTO
			w $0018
			b $9a
			b FRAME_RECTO
			w $0127
			b $ac

			b ESC_PUTSTRING
			w $0020
			b $42
			b PLAINTEXT
			b "Current drive"

			b GOTOXY
			w $0020
			b $6a
			b "Disk/Partition"

			b GOTOXY
			w $0020
			b $9a
			b PLAINTEXT
			b "CMD devices"

			b GOTOXY
			w $0034
			b $a6
			b "Check additional partitions"
			b NULL

:V411h2			b ESC_GRAPHICS
			b MOVEPENTO
			w $0018
			b $42
			b FRAME_RECTO
			w $0127
			b $5c

			b MOVEPENTO
			w $0018
			b $72
			b FRAME_RECTO
			w $0127
			b $ac

			b ESC_PUTSTRING
			w $0020
			b $42
			b "Directory-options"

			b GOTOXY
			w $0034
			b $4e
			b "Check subdirectory headers"

			b GOTOXY
			w $0020
			b $72
			b "File-options"

			b GOTOXY
			w $0034
			b $7e
			b "Delete corrupt files"

			b GOTOXY
			w $0034
			b $8e
			b "Set correct filesize"

			b GOTOXY
			w $0034
			b $9e
			b "Close opened files"
			b NULL
endif

;*** Datenliste für "Klick-Positionen".
:V411i0			w V411i1, V411i2

:V411i1			b $48,$4f
			w $0020,$0117,DefOpt1a,$0000
			b $70,$77
			w $0020,$0117,DefOpt1b,SetOpt1b
			b $48,$4f
			w $0118,$011f,ChangeIcon1,SetOpt1a
			b $70,$77
			w $0118,$011f,ChangeIcon2,SetOpt1c
			b $a0,$a7
			w $0020,$0027,DefOpt2a,SetOpt2a
			b NULL

:V411i2			b $48,$4f
			w $0020,$0027,DefOpt2e,SetOpt2e
			b $78,$7f
			w $0020,$0027,DefOpt2b,SetOpt2b
			b $88,$8f
			w $0020,$0027,DefOpt2c,SetOpt2c
			b $98,$9f
			w $0020,$0027,DefOpt2d,SetOpt2d
			b NULL

;*** Icon-Menü.
:Icon_Tab1		b $01
			w $0000
			b $00

			w Icon_OK
			b $1c,$78,$06,$10
			w ExitDskErr

:Icon_Tab2		b $01
			w $0000
			b $00

			w Icon_OK
			b $1c,$78,$06,$10
			w UndelNextFile

;*** Hauptmenü-Icons.
:Icon_Tab3		b 2
			w $0000
			b $00

			w Icon_00
			b $00,$08,$05,$18
			w L411ExitGD

			w Icon_01
			b $05,$08,$05,$18
			w StartValid

;*** Icons.
if Sprache = Deutsch
:Icon_00
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_00
<MISSING_IMAGE_DATA>
endif

:Icon_01
<MISSING_IMAGE_DATA>

:Icon_02
<MISSING_IMAGE_DATA>
