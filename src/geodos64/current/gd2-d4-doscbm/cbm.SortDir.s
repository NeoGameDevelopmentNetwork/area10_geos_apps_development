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

:MaxReadSek		= 26

endif

			n	"mod.#407.obj"
			o	ModStart
			q	EndProgrammCode
			r	EndAreaCBM - (MaxReadSek *256 *2)

			jmp	CBM_SortDir

			t	"-FontType2"

;*** L407: Verzeichnis sortieren.
:CBM_SortDir		Display	ST_WR_FORE		;Vordergrundbildschirm aktivieren.
			jsr	ClrScreen		;Bildschirm löschen.

			ldx	#$00			;Diskette einlegen.
			beq	GetDisk_b

:GetDisk_a		jsr	ClrScreen		;Bildschirm löschen.
			ldx	#$ff			;Neue Diskette einlegen.

:GetDisk_b		lda	curDrive
			jsr	InsertDisk
			cmp	#$01
			beq	:101
			jmp	L407ExitGD

::101			jsr	Read240Dir		;Verzeichnis von Diskette einlesen.

			lda	MaxFileS
			cmp	#$02
			bcs	:102
			DB_OK	V407d4
			jmp	L407ExitGD

::102			jsr	Bildschirm_a		;Menüs auf Bildschirm ausgeben.
			jsr	Bildschirm_c

			LoadW	r0,HelpFileName
			lda	#<CBM_SortDir
			ldx	#>CBM_SortDir
			jsr	InstallHelp

			LoadW	otherPressVec,SelectFile

			LoadW	r0,Icon_Tab1		;Icon-Tabelle auf Bildschirm.
			jmp	DoIcons			;Menüs aktivieren.

;*** Neues Laufwerk wählen.
:OtherDrive		jsr	ClrWin
			jmp	vC_SortDir

;*** Neue Partition wählen.
:OtherPart		jsr	ClrWin
			jsr	CMD_OtherPart
			jmp	CBM_SortDir

;*** Neues Verzeichnis wählen.
:OtherNDir		jsr	ClrWin
			jsr	CMD_OtherNDir
			jmp	CBM_SortDir

;*** Zurück zu GeoDOS.
:L407ExitGD		jsr	ClrWin
			jmp	InitScreen

;*** Bildschirm löschen.
:ClrWin			ClrW	otherPressVec
			jmp	ClrScreen

;*** Bildschirm aufbauen.
:Bildschirm_a		jsr	ClrScreen

			jsr	i_C_MenuTitel
			b	$00,$00,$28,$01
			jsr	i_C_MenuBack
			b	$00,$01,$28,$18

			jsr	UseGDFont		;Titelzeilen definieren.
			Print	$0008,$06
if Sprache = Deutsch
			b	PLAINTEXT,"CBM  -  Verzeichnis sortieren",NULL
endif
if Sprache = Englisch
			b	PLAINTEXT,"CBM  -  Sort directory",NULL
endif

			LoadW	r0,V407e0
			jsr	GraphicsString

			jsr	i_C_Register
			b	$01,$05,$0f,$01
			jsr	i_C_Register
			b	$15,$05,$0f,$01
			jsr	i_C_MenuTBox
			b	$01,$07,$11,$0d
			jsr	i_C_MenuTBox
			b	$15,$07,$11,$0d
			jsr	i_C_MenuMIcon
			b	$01,$15,$04,$02
			jsr	i_C_MenuMIcon
			b	$06,$15,$02,$02
			jsr	i_C_MenuMIcon
			b	$08,$15,$02,$02
			jsr	i_C_MenuMIcon
			b	$15,$15,$04,$02
			jsr	i_C_MenuMIcon
			b	$1a,$15,$02,$02
			jsr	i_C_MenuMIcon
			b	$1c,$15,$02,$02
			jsr	i_C_MenuMIcon
			b	$1f,$15,$02,$02

;*** Daten neu anzeigen.
:Bildschirm_b		jsr	PrintFiles		;Anzahl Dateien ausgeben.
			jsr	S_ResetBit		;Quell-Auswahl löschen.
			jsr	T_ResetBit		;Ziel -Auswahl löschen.
			jsr	S_Top			;Zum Anfang Quell-Verzeichnis.
			jmp	T_Top			;Zum Anfang Ziel -Verzeichnis.

;*** Directory-Icons installieren.
:Bildschirm_c		lda	C_MenuBack		;Iconfenster löschen.
			pha
			and	#%00001111
			sta	r0L
			pla
			asl
			asl
			asl
			asl
			ora	r0L
			sta	:101 +4

			jsr	i_ColorBox
::101			b	$00,$01,$28,$03,$ff

			FillPRec$00,$08,$1f,$0000,$013f

			jsr	i_C_MenuBack
			b	$00,$01,$28,$03

;*** Icon-Tabelle definieren.
			LoadB	Icon_Tab1,9		;Bei RAM-Laufwerk und CMD HD keinen
			LoadB	r14H,$0a
			LoadW	r15,Icon_Tab1a

			CmpBI	CBM_Count,2
			bcc	:102
			ldx	#$00			;Icon: "Laufwerk wechseln"
			jsr	Copy1Icon

::102			lda	curDrvType		;Diskwechsel erlauben.
			cmp	#Drv_CMDHD
			beq	:103
			cmp	#Drv_64Net
			beq	:103
			ldx	curDrive
			lda	DriveModes-8,x
			and	#%00001000
			bne	:103
			ldx	#$08			;Icon: "Diskette wechseln"
			jsr	Copy1Icon

::103			lda	curDrvMode
;			bpl	:107
			bpl	:104
			ldx	#$10			;Icon: "Partition wechseln"
			jsr	Copy1Icon

::104			ldx	curDrive
			lda	DriveModes-8,x
;--- Ergänzung: 01.12.18/M.Kanet
;NativeMode ist auch auf Nicht-CMD-Laufwerken möglich.
;			bpl	:107
			and	#%00100000
			beq	:107
			ldx	#$18
			jsr	Copy1Icon

;*** Farbe für Standard-Icons.
::107			lda	r14H
			sta	:108 +2

			jsr	i_C_MenuMIcon
::108			b	$00,$01,$00,$03
			rts

;*** Icon in Icon-Zeile übernehmen.
:Copy1Icon		ldy	#$00
::101			lda	Icon_Tab1b,x
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

;*** Quell-Datei wählen.
:SlctSource		ldy	#$00			;Quell-Bereich aktivieren.
			jsr	SetWinData
			lda	#<V407a5
			ldx	#>V407a5
			jmp	Slct1File

;*** Ziel-Datei wählen.
:SlctTarget		ldy	#$06			;Ziel -Bereich einlesen.
			jsr	SetWinData
			lda	#<V407a6
			ldx	#>V407a6

:Slct1File		sta	r0L
			stx	r0H
			jsr	InitRam

::101			ldx	a3H			;Mit Maus angelickten Eintrag
			lda	mouseYPos		;berechnen.
			sub	$38
			lsr
			lsr
			lsr
			sta	a7H
			clc
			adc	FirstFileS,x		;Datei innerhalb Liste ?
			cmp	MaxFileS,x
			bcc	:103			;Ja, weiter...

::102			ClrB	pressFlag
			LoadW	r0,V407a4
			jmp	InitRam 			;Nein, Mausklick ungültig.

::103			tay				;Position innerhalb Verzeichnis
			lda	(a0L),y			;berechnen.
			sta	a5L
			tay
			lda	(a1L),y			;Datei bereits ausgewählt ?
			beq	:106			;Nein, weiter...

			ldx	a3H			;Anzahl markierter Einträge
			dec	SlctFileS,x		;korrigieren.
			sta	a5H			;Eintrag merken...

			lda	#$00			;und löschen.
			sta	(a1L),y
			tay

::104			lda	(a1L),y			;korrigieren.
			cmp	a5H
			bcc	:105
			lda	(a1L),y
			sbc	#$01
			sta	(a1L),y

::105			iny
			bne	:104
			jmp	:107			;Eintrag ausgeben.

::106			ldx	a3H
			lda	SlctFileS,x
			cmp	#$ff			;Bereits 255 Dateien angewählt ?
			beq	:102			;Ja, Ende...
			inc	SlctFileS,x		;Datei als "ausgewählt" markieren.
			lda	SlctFileS,x
			sta	(a1L),y

::107			lda	a7H			;Ausgabezeile für Eintrag
			asl				;ausgeben.
			asl
			asl
			add	$3e
			sta	a3L
			jsr	View1Entry

			lda	mouseYPos
			lsr
			lsr
			lsr
			sta	r0L

::108			lda	mouseData
			bpl	:109
			jmp	:102

::109			lda	mouseYPos
			lsr
			lsr
			lsr
			cmp	r0L
			beq	:108
			jmp	:101

;*** Quell-Dateien übernehmen.
:TakeSource		ldx	MaxFileT		;Zielverzeichnis voll ?
			cpx	#$ff
			bne	:102			;Nein, weiter...
::101			rts				;Ja, Abbruch.

::102			lda	SlctFileS		;Dateien im Quell-Verzeichnis gewählt ?
			beq	:101			;Nein, Abbruch.

			LoadB	a5H,$01			;Zeiger auf Nr. des ersten gewählten
							;Eintrages m Quell-Verzeichnis.
::103			ldy	#$00
::104			lda	Memory3,y		;Eintrag aus Tabelle einlesen.
			cmp	a5H			;Mit nächster Nr. vergleichen.
			bne	:105			;Eintrag übernehmen ? Nein, weiter...
			tya
			sta	Memory2,x		;Nr. des Eintrages in Tabelle kopieren.
			cpx	#$ff			;Tabelle voll ?
			beq	:107			;Ja, Ende...
			inx
			inc	MaxFileT		;Dateien im Zielverzeichnis  +1.
			dec	MaxFileS		;Dateien im Quellverzeichnis -1.
			beq	:107			;Keine weiteren Dateien ? Ja, Ende...
			jmp	:106

::105			iny				;Zeiger auf nächsten Eintrag.
			bne	:104			;Ende erreicht ? Nein, weiter...
::106			CmpB	a5H,SlctFileS		;Alle Dateien übernommen ?
			beq	:107			;Ja, Ende...
			inc	a5H			;Zeiger auf nächste Datei.
			jmp	:103			;Weiter...

::107			ldy	#$00			;Markierte Dateien aus Quellverzeichnis
			ldx	#$00			;entfernen.
::108			stx	:109 +1
			ldx	Memory1,y
			lda	Memory3,x
			bne	:109
			ldx	:109 +1
			lda	Memory1,y
			sta	Memory1,x
			inc	:109 +1
::109			ldx	#$ff
			iny
			bne	:108
			jmp	Bildschirm_b		;Dateilisten neu anzeigen.

;*** Ziel-Dateien übernehmen.
:TakeTarget		lda	SlctFileT		;Dateien im Zielverzeichnis ?
			bne	:102			;Ja, weiter...
::101			rts				;Abbruch.

::102			lda	#>Memory3
			jsr	ClearMem

			lda	MaxFileS		;Dateien im Quellverzeichnis ?
			beq	:106			;Nein, weiter...

			ldy	#$00
::104			lda	Memory1,y		;Dateien aus Quell-Verzeichnis in
			bne	:105			;Zwischenspeicher übernehmen.
			cpy	#$00
			bne	:106
::105			tax
			lda	#$ff
			sta	Memory3,x
			iny
			bne	:104

::106			ldy	#$00			;Dateien aus Ziel-Verzeichnis in
::107			lda	Memory4,y		;Zwischenspeicher übernehmen.
			beq	:108
			lda	#$ff
			sta	Memory3,y
			dec	MaxFileT
			inc	MaxFileS
::108			iny
			bne	:107

			lda	#>Memory1
			jsr	ClearMem

			ldy	#$00
			ldx	#$00			;Neue Liste für Quell-Verzeichnis
::109			lda	Memory3,y		;erzeugen.
			beq	:270
			tya
			sta	Memory1,x
			inx
::270			iny
			bne	:109

			ldy	#$00
			ldx	#$00			;Markierte Dateien aus
::271			stx	:272 +1			;Zielverzeichnis entfernen.
			ldx	Memory2,y
			lda	Memory4,x
			bne	:272
			ldx	:272 +1
			lda	Memory2,y
			sta	Memory2,x
			inc	:272 +1
::272			ldx	#$ff
			iny
			bne	:271
			jmp	Bildschirm_b		;Neue Dateiliste anzeigen.

;*** Mausklick überprüfen.
:SelectFile		ClrB	a0L
::101			jsr	ChkMseArea		;Mausbereich einlesen.

			php				;Maus innerhalb Bereich ?
			sei
			jsr	IsMseInRegion
			plp
			tax
			beq	:102			;Nein, weiter...
			jmp	(r5)			;Ja, Routine aufrufen.

::102			inc	a0L			;Alle Bereiche überprüft ?
			lda	a0L
			cmp	#8
			bne	:101			;Nein, weiter...
			rts				;Ja, Abbruch...

;*** Bereichsdaten einlesen.
:ChkMseArea		asl
			asl
			asl
			tay
			ldx	#$00
::101			lda	V407c0,y
			sta	r2L,x
			iny
			inx
			cpx	#$08
			bne	:101
			rts

;*** Verzeichnis zurücksetzen.
:ResetDir		jsr	TakeFiles
			jmp	Bildschirm_b

;*** In der Quell-Tabelle eine Datei vorwärts.
:S_FileDown		jsr	S_Balken
			jsr	:101
			ldy	#$00
			jsr	SetWinData
			jsr	NextFile
::101			lda	#$00
			jmp	EndFileMove

;*** In der Quell-Tabelle eine Datei zurück.
:S_FileUp		jsr	S_Balken
			jsr	:101
			ldy	#$00
			jsr	SetWinData
			jsr	LastFile
::101			lda	#$01
			jmp	EndFileMove

;*** In der Ziel-Tabelle eine Datei vorwärts.
:T_FileDown		jsr	T_Balken
			jsr	:101
			ldy	#$06
			jsr	SetWinData
			jsr	NextFile
::101			lda	#$02
			jmp	EndFileMove

;*** In der Ziel-Tabelle eine Datei zurück.
:T_FileUp		jsr	T_Balken
			jsr	:101
			ldy	#$06
			jsr	SetWinData
			jsr	LastFile
::101			lda	#$03
:EndFileMove		jsr	ChkMseArea
			jmp	InvertRectangle

;*** Zum Anfang der Quell-Tabelle.
:S_Top			ClrB	FirstFileS
:S_SetPos		ldy	#$00
			jsr	SetWinData
			jsr	ShowFileList
			jsr	S_Balken
			NoMseKey
			rts

;*** Zum Anfang der Ziel-Tabelle.
:T_Top			ClrB	FirstFileT
:T_SetPos		ldy	#$06
			jsr	SetWinData
			jsr	ShowFileList
			jsr	T_Balken
			NoMseKey
			rts

;*** In der Quell-Tabelle eine Seite zurück.
:S_End			lda	MaxFileS
			sub	13
			bcs	:101
			rts
::101			sta	FirstFileS
			jmp	S_SetPos

;*** In der Ziel-Tabelle eine Seite zurück.
:T_End			lda	MaxFileT
			sub	13
			bcs	:101
			rts
::101			sta	FirstFileT
			jmp	T_SetPos

;*** In der Quell-Tabelle eine Seite vorwärts.
:S_NextPage		lda	FirstFileS
			add	26
			bcs	:101
			cmp	MaxFileS
			bcc	:102
::101			jmp	S_End
::102			sub	13
			sta	FirstFileS
			jmp	S_SetPos

;*** Zum Ende der Quell-Tabelle.
:S_LastPage		lda	FirstFileS
			sub	13
			bcs	:101
			jmp	S_Top
::101			sta	FirstFileS
			jmp	S_SetPos

;*** In der Ziel-Tabelle eine Seite vorwärts.
:T_NextPage		lda	FirstFileT
			add	26
			bcs	:101
			cmp	MaxFileT
			bcc	:102
::101			jmp	T_End
::102			sub	13
			sta	FirstFileT
			jmp	T_SetPos

;*** Zum Ende der Ziel-Tabelle.
:T_LastPage		lda	FirstFileT
			sub	13
			bcs	:101
			jmp	T_Top
::101			sta	FirstFileT
			jmp	T_SetPos

;*** Mausklick auf Quell-Anzeigebalken.
:S_MoveBar		jsr	S_Balken
			ldy	#$00
			jsr	SetWinData
			jsr	IsMseOnPos		;Position der Maus ermitteln.
			cmp	#$01			;Oberhalb des Anzeigebalkens ?
			beq	:1			;Ja, eine Seite zurück.
			cmp	#$02			;Auf dem Anzeigebalkens ?
			beq	:2			;Ja, Balken verschieben.
			cmp	#$03			;Unterhalb des Anzeigebalkens ?
			beq	:3			;Ja, eine Seite vorwärts.
			rts

::1			jmp	S_LastPage
::2			jmp	MoveToPos
::3			jmp	S_NextPage

;*** Mausklick auf Quell-Anzeigebalken.
:T_MoveBar		jsr	T_Balken
			ldy	#$06
			jsr	SetWinData
			jsr	IsMseOnPos		;Position der Maus ermitteln.
			cmp	#$01			;Oberhalb des Anzeigebalkens ?
			beq	:1			;Ja, eine Seite zurück.
			cmp	#$02			;Auf dem Anzeigebalkens ?
			beq	:2			;Ja, Balken verschieben.
			cmp	#$03			;Unterhalb des Anzeigebalkens ?
			beq	:3			;Ja, eine Seite vorwärts.
			rts

::1			jmp	T_LastPage
::2			jmp	MoveToPos
::3			jmp	T_NextPage

;*** Balken verschieben.
:MoveToPos		jsr	StopMouseMove		;Mausbewegung einschränken.

::1			jsr	UpdateMouse		;Mausdaten aktualisieren.
			ldx	mouseData		;Maustaste noch gedrückt ?
			bmi	:2			;Nein, neue Position anzeigen.
			lda	inputData		;Mausbewegung einlesen.
			bne	:3			;Mausbewegung auswerten.
			beq	:1			;Keine Bewegung, Schleife...

::2			ClrB	pressFlag		;Maustastenklick löschen.
			LoadW	r0,V407a4
			jsr	InitRam

			lda	a3H
			bne	:2a
			jmp	S_SetPos
::2a			jmp	T_SetPos		;Position anzeigen.

::3			cmp	#$02			;Maus nach oben ?
			beq	:4			;Ja, auswerten.
			cmp	#$06			;Maus nach unten ?
			beq	:5			;Ja, auswerten.
			jmp	:1			;Keine Bewegung, Schleife...

::4			jsr	LastFile_a		;Eine Datei zurück.
			bcs	:1			;Geht nicht, Abbruch.
			ldx	a3H
			dec	FirstFileS,x
			jmp	:6			;Neue Position anzeigen.

::5			jsr	NextFile_a		;Eine Datei vorwärts.
			bcs	:1			;Geht nicht, Abbruch.
			ldx	a3H
			inc	FirstFileS,x
::6			lda	FirstFileS,x		;Tabellenposition einlesen und
			jsr	SetPosBalken		;Anzeigebalken setzen und
			jsr	SetRelMouse		;Maus entsprechend verschieben.
			jmp	:1			;Maus weiter auswerten.

;*** Tabelle ausgeben.
; :a0  = Zeiger auf Tabelle.
; :a1  = Zeiger auf Tabelle.
; :a2  = Zeiger auf x-Koordinate.
; :a3L = reserviert für y-Koordinate.
; :a3H = $00 = Source, $01 = Target.
; :a4L = Zähler für Dateien in Tabelle.
; :a4H = Aktueller Eintrag.
; :a5L = Ausgabe von Eintrag xyz.
; :a5H = Berechnung für Zeiger/Eintrag.
; :a6L = Max. Files.
:ShowFileList		LoadB	a3L,$3e			;Zeiger auf erste Zeile.
			ClrB	a4L			;Zähler für Anzahl Einträge auf 0.

			ldx	a3H
			lda	FirstFileS,x		;Nr. der ersten Datei
			sta	a4H			;in Zwischenspeicher.
			lda	MaxFileS,x		;Max. Anzahl Dateien in Tabelle
			sta	a6L			;in Zwischenspeicher kopieren.

::101			ldy	a4H			;Tabellenende erreicht ?
			cpy	a6L
			bcs	:105			;Ja, Rest des Fensters löschen...

			lda	(a0L),y			;Pos. des Eintrages im Verzeichnis
::102			sta	a5L			;in Zwischenspeicher.
			jsr	View1Entry		;Dateieintrag ausgeben.
			AddVB	8,a3L			;Zeiger auf nächste Zeile.
			inc	a4L			;Zähler Anzahl Dateien/Tabelle +1.

::103			inc	a4H			;Tabellenende erreicht ?
			beq	:104			;Ja, Ende...

			CmpBI	a4L,13			;Tabelle voll ?
			bne	:101			;Nein, weiter...
::104			rts

::105			Pattern	0			;Unteren Bereich des Ausgabefensters
							;löschen.
			lda	a3L
			sub	6
			sta	r2L
			LoadB	r2H,159
			jsr	DefXPos

			jmp	Rectangle

;*** Eintrag ausgeben.
:View1Entry		MoveB	a5L,a7L			;Nr. des Eintrags speichern.
			jsr	GetFilePos		;Verzeichniseintrag suchen.

			ldy	#$02
			lda	(a5L),y			;Datei verfügbar ?
			beq	:104			;Nein, weiter...

			jsr	DefRectangle

			ldx	#%00000000
			ldy	a7L
			lda	(a1L),y			;Eintrag angewählt ?
			beq	:101			;Nein, weiter...
			lda	#$01
			ldx	#%00100000		;Ja, reverse Darstellung.
::101			stx	currentMode
			jsr	SetPattern
			jsr	Rectangle

::102			MoveW	a2,r11			;Position für Text festlegen.
			MoveB	a3L,r1H

			lda	#$05			;Dateiname ausgeben.
::103			pha
			tay
			lda	(a5L),y
			jsr	ConvertChar
			jsr	SmallPutChar
			pla
			add	1
			cmp	#$15
			bne	:103
::104			rts				;Ende...

;*** X-Koordinaten berechnen.
:DefRectangle		lda	a3L
			tax
			sub	6
			sta	r2L
			inx
			stx	r2H

:DefXPos		sec
			lda	a2L
			sbc	#$08
			sta	r3L
			lda	a2H
			sbc	#$00
			sta	r3H

			clc
			lda	r3L
			adc	#$87
			sta	r4L
			lda	r3H
			adc	#$00
			sta	r4H
			rts

;*** Eine Datei vorwärts.
:NextFile		jsr	NextFile_a
			bcc	NextFile_b
			rts				;Abbruch...

:NextFile_a		ldx	a3H
			lda	FirstFileS,x
			add	13
			bcs	:101
			cmp	MaxFileS,x		;Tabellen-Ende erreicht ?
::101			rts

:NextFile_b		php
			sei
			ldx	a3H
			lda	GrafxDatS,x
			sta	r0L
			lda	GrafxDatT,x
			sta	r0H

			ldx	#12
::103			clc				;Zeiger auf Grafik-Daten berechnen.
			lda	r0L
			sta	r1L
			adc	#<320
			sta	r0L
			lda	r0H
			sta	r1H
			adc	#>320
			sta	r0H
			ldy	#$00			;13 Grafikzeilen a 112 Byte (16 * 7)
::104			lda	(r0L),y			;verschieben.
			sta	(r1L),y
			iny
			cpy	#136
			bne	:104
			dex
			bne	:103
			plp

			ldx	a3H
			inc	FirstFileS,x		;Tabellenzeiger korrigieren.
			lda	FirstFileS,x		;Nächsten Dateinamen ausgeben.
			pha
			add	12
			tay
			lda	(a0L),y
			sta	a5L
			lda	#158
			sta	a3L
			jsr	View1Entry
			pla
			jsr	SetPosBalken
			jsr	TestMouse
			jmp	NextFile		;Weiterscrollen.

;*** Eine Datei zurück.
:LastFile		jsr	LastFile_a
			bcc	LastFile_b
			rts				;Abbruch.

:LastFile_a		ldx	a3H
			lda	FirstFileS,x		;Tabellenzeiger korrigieren.
			bne	:101
			sec
			rts
::101			clc
			rts

:LastFile_b		php
			sei
			ldx	a3H
			clc
			lda	GrafxDatS,x
			adc	#<3840
			sta	r0L
			lda	GrafxDatT,x
			adc	#>3840
			sta	r0H

			ldx	#12
::102			sec				;Zeiger auf Grafik-Daten berechnen.
			lda	r0L
			sta	r1L
			sbc	#<320
			sta	r0L
			lda	r0H
			sta	r1H
			sbc	#>320
			sta	r0H
			ldy	#$00			;13 Grafikzeilen a 112 Byte (16 * 7)
::103			lda	(r0L),y			;verschieben.
			sta	(r1L),y
			iny
			cpy	#136
			bne	:103
			dex
			bne	:102
			plp

			ldx	a3H
			dec	FirstFileS,x		;Tabellenzeiger korrigieren.
			lda	FirstFileS,x		;Nächsten Dateinamen ausgeben.
			pha
			tay
			lda	(a0L),y
			sta	a5L
			lda	#62
			sta	a3L
			jsr	View1Entry
			pla
			jsr	SetPosBalken
			jsr	TestMouse
			jmp	LastFile		;Weiterscrollen.

;*** Dauerfunktion ?
:TestMouse		sei
			jsr	CPU_Pause
			cli
			lda	mouseData
			bne	:101
			rts

::101			pla
			pla
			ClrB	pressFlag
			rts

;*** Speicher löschen.
:ClearMem		sta	r0H
			ClrB	r0L
			tay
::101			sta	(r0L),y
			iny
			bne	:101
			rts

;*** Zeiger auf Tabelle berechnen.
:GetFilePos		ClrB	a5H
			ldx	#a5L
			ldy	#$05
			jsr	DShiftLeft
			AddVW	Memory5,a5
			rts

;*** Fensterparameter setzen.
; yReg = $00, Source
; yReg = $06, Target
:SetWinData		lda	V407a0+0,y
			sta	a0L
			lda	V407a0+1,y
			sta	a0H
			lda	V407a0+2,y
			sta	a1L
			lda	V407a0+3,y
			sta	a1H
			lda	V407a0+4,y
			sta	a2L
			lda	V407a0+5,y
			sta	a2H

			ldx	#$00
			cpy	#$00
			beq	:101
			inx
::101			stx	a3H
			rts

;*** Anzahl Dateien ausgeben.
:PrintFiles		LoadW	r0,V407e1
			jsr	GraphicsString

			ClrB	currentMode
			jsr	UseMiniFont

			LoadW	r11,$0008
			MoveB	MaxFileS,r0L
			jsr	:101

			LoadW	r11,$00a8
			MoveB	MaxFileT,r0L
			jsr	:101

			jmp	UseGDFont

::101			LoadB	r1H,$c5
			ClrB	r0H
			lda	#%11000000
			jsr	PutDecimal
			LoadW	r0,V407d3
			jmp	PutString

;*** Alle Markierungen im Quell-Verzeichnis löschen.
:S_Reset		jsr	S_ResetBit
			jmp	S_SetPos

;*** Alle Markierungen im Ziel -Verzeichnis löschen.
:T_Reset		jsr	T_ResetBit
			jmp	T_SetPos

;*** Alle Dateien im Quell-Verzeichnis markieren.
:S_SetAll		lda	MaxFileS
			bne	:102
::101			rts

::102			ldx	#$00
			stx	r0L
			ldy	SlctFileS
			iny
			sty	r0H

::103			lda	Memory1,x
			tax
			lda	Memory3,x
			bne	:104
			lda	r0H
			sta	Memory3,x
			inc	r0H
::104			inc	r0L
			ldx	r0L
			cpx	MaxFileS
			bne	:103

			lda	MaxFileS
			sta	SlctFileS
			jmp	S_SetPos

;*** Alle Dateien im Ziel-Verzeichnis markieren.
:T_SetAll		lda	MaxFileT
			bne	:102
::101			rts

::102			ldx	#$00
			stx	r0L
			ldy	SlctFileT
			iny
			sty	r0H

::103			lda	Memory2,x
			tax
			lda	Memory4,x
			bne	:104
			lda	r0H
			sta	Memory4,x
			inc	r0H
::104			inc	r0L
			ldx	r0L
			cpx	MaxFileT
			bne	:103

			lda	MaxFileT
			sta	SlctFileT
			jmp	T_SetPos

;*** Quell-Bit löschen.
:S_ResetBit		lda	#>Memory3
			ldx	#$00
			beq	Reset1Bit

;*** Ziel-Bit löschen.
:T_ResetBit		lda	#>Memory4
			ldx	#$01

:Reset1Bit		sta	r4H
			ClrB	r4L

			lda	#$00
			sta	SlctFileS,x
			tay
::101			sta	(r4L),y
			iny
			bne	:101
			rts

;*** Anzeigebalken.
:S_Balken		ldx	#$00
			b $2c
:T_Balken		ldx	#$01

			lda	V407a3,x
			sta	V407a2+0

			lda	MaxFileS,x
			sta	V407a2+3

			lda	FirstFileS,x
			sta	V407a2+5

			LoadW	r0,V407a2
			jmp	InitBalken

;*** Verzeichnis in Speicher einlesen.
:Read240Dir		jsr	DoInfoBox
			PrintStrgV407d0

			jsr	i_FillRam
			w	MaxReadSek * 256
			w	Memory5
			b	$00

			jsr	GetDirHead

			jsr	EnterTurbo
			jsr	InitForIO

			ClrB	SekInMem

			MoveW	curDirHead,r1
			LoadW	r4,Memory5
::101			jsr	ReadBlock
			txa
			beq	:102
			jsr	DoneWithIO
			jmp	DiskError

::102			ldy	#$00
			lda	(r4L),y
			beq	:103
			sta	r1L
			iny
			lda	(r4L),y
			sta	r1H

			inc	r4H
			inc	SekInMem
			CmpBI	SekInMem,MaxReadSek
			bne	:101

			jsr	DoneWithIO
			jsr	ClrBox

			DB_OK	V407d5
			jmp	L407ExitGD

::103			jsr	DoneWithIO
			jsr	ClrBox

;*** Dateien in Tabelle übernehmen.
:TakeFiles		ldy	#$00
			tya
::111			sta	Memory1,y
			sta	Memory2,y
			sta	Memory3,y
			sta	Memory4,y
			iny
			bne	:111

			LoadW	r4,Memory5
			ldx	#$00
			stx	r5L
			stx	r5H

::112			ldy	#$02
			lda	(r4L),y
			beq	:113

			ldx	r5L
			lda	r5H
			sta	Memory1,x
			inc	r5L
			cpx	#$fe
			beq	:114

::113			inc	r5H

			AddVBW	32,r4
			CmpBI	r4H,>Memory6
			bne	:112

::114			MoveB	r5L,MaxFileS

			lda	#$00
			sta	MaxFileT
			sta	FirstFileS
			sta	FirstFileT
			rts

;*** Neues Verzeichnis schreiben.
:WriteNewDir		jsr	S_SetAll
			jsr	TakeSource

::101			jsr	i_FillRam
			w	MaxReadSek * 256
			w	Memory6
			b	$00

			LoadW	r0,Memory5
			LoadW	r1,Memory6
			ldx	#$00
::102			ldy	#$00
			lda	(r0L),y
			sta	(r1L),y
			iny
			lda	(r0L),y
			sta	(r1L),y
			inc	r0H
			inc	r1H
			inx
			cpx	#MaxReadSek
			bne	:102

			LoadW	a6,Memory6
			ClrB	a1L
::103			ldx	a1L
			lda	Memory2,x
			sta	a5L
			jsr	GetFilePos

			ldy	#$02
::104			lda	(a5L),y
			sta	(a6L),y
			iny
			cpy	#$20
			bne	:104

			AddVBW	32,a6

			inc	a1L
			CmpB	a1L,MaxFileT
			beq	:105
			jmp	:103

::105			lda	#$00
			ldx	a6H
			sta	a7L
			stx	a7H

			ldy	#$00
			tya
			sta	(a7L),y
			iny
			lda	#$ff
			sta	(a7L),y

::107			jsr	ClrScreen

			jsr	DoInfoBox
			PrintStrgV407d1

			jsr	GetDirHead

			jsr	EnterTurbo
			jsr	InitForIO

			ClrB	CurDiskSek

			MoveW	curDirHead,r1
			LoadW	r4,Memory6
::108			jsr	WriteBlock
			txa
			beq	:109
			jsr	DoneWithIO
			jmp	DiskError

::109			ldy	#$00
			lda	(r4L),y
			beq	:110
			sta	r1L
			iny
			lda	(r4L),y
			sta	r1H

			inc	r4H
			inc	CurDiskSek
			CmpBI	CurDiskSek,MaxReadSek
			bne	:108

::110			jsr	DoneWithIO
;--- Ergänzung: 27.11.18/M.Kanet
;Nach dem sortieren des Verzeichnises prüfen ob die Header von
;Unterverzeichnissen angepasst werden müssen.
;Betrifft nur NativeMode.
			jsr	VerifyNMDir
::111			jsr	ClrBox
			jmp	L407ExitGD

;--- Ergänzung: 27.11.18/M.Kanet
;Testroutine für NativeMode-Unterverzeichnisse.
			t "-CBM_ChkNmSd1"
;			t "-CBM_ChkNmSd2"

;*** Name der Hilfedatei.
:HelpFileName		b "20,GDH_CBM/Datei",NULL

;*** Variablen.
:SekInMem		b $00
:CurDiskSek		b $00

;*** Daten für Quell-Verzeichnis.
:V407a0			w Memory1
			w Memory3
			w $0010

;*** Daten für Ziel -Verzeichnis.
:V407a1			w Memory2
			w Memory4
			w $00b0

;*** Daten für Anzeige-Balken.
:V407a2			b $12,$40,$58,$ff,$0d,$ff
:V407a3			b $12,$26

;*** Maus-Fenstergrenzen zurücksetzen.
:V407a4			w mouseTop
			b $06
			b $00,$c7
			w $0000,$013f
			w $0000

;*** Maus-Fenstergrenzen zurücksetzen.
:V407a5			w mouseTop
			b $06
			b $38,$9f
			w $0008,$008f
			w $0000

;*** Maus-Fenstergrenzen zurücksetzen.
:V407a6			w mouseTop
			b $06
			b $38,$9f
			w $00a8,$012f
			w $0000

;*** Variablen für Tabellen.
:FirstFileS		b $00
:FirstFileT		b $00
:MaxFileS		b $00
:MaxFileT		b $00
:SlctFileS		b $00
:SlctFileT		b $00
:GrafxDatS		b <SCREEN_BASE+2248
			b <SCREEN_BASE+2408
:GrafxDatT		b >SCREEN_BASE+2248
			b >SCREEN_BASE+2408

;*** Maus-Aktionsgrenzen.
:V407c0			b $98,$9f
			w $0090,$0097, S_FileDown
			b $38,$3f
			w $0090,$0097, S_FileUp
			b $98,$9f
			w $0130,$0137, T_FileDown
			b $38,$3f
			w $0130,$0137, T_FileUp
			b $40,$97
			w $0090,$0097, S_MoveBar
			b $40,$97
			w $0130,$0137, T_MoveBar
			b $38,$9f
			w $0008,$008f, SlctSource
			b $38,$9f
			w $00a8,$012f, SlctTarget

if Sprache = Deutsch
;*** Texte für Infoboxen.
:V407d0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Verzeichnis wird"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "eingelesen..."
			b NULL

:V407d1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Verzeichnis wird"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "aktualisiert..."
			b NULL

;*** Texte.
:V407d3			b " Datei(en)",NULL

;*** Fehlermeldungen.
:V407d4			w :101, :102, ISet_Achtung
::101			b BOLDON,"Keine Dateien zum",NULL
::102			b        "sortieren auf Diskette!",NULL

:V407d5			w :101, :102, ISet_Achtung
::101			b BOLDON,"Das Verzeichnis ist zu groß.",NULL
::102			b        "Sortieren nicht möglich!",NULL
endif

if Sprache = Englisch
;*** Texte für Infoboxen.
:V407d0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Load current"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "directory..."
			b NULL

:V407d1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Update current"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "directory..."
			b NULL

;*** Texte.
:V407d3			b " File(s)",NULL

;*** Fehlermeldungen.
:V407d4			w :101, :102, ISet_Achtung
::101			b BOLDON,"No files to",NULL
::102			b        "sort on disk!",NULL

:V407d5			w :101, :102, ISet_Achtung
::101			b BOLDON,"Directory overflow.",NULL
::102			b        "Unable to sort directory!",NULL
endif

;*** Daten für Fenster.
:V407e0			b MOVEPENTO
			w $0000
			b $30
			b FRAME_RECTO
			w $013f
			b $bf
			b FRAME_RECTO
			w $0000
			b $c7

			b MOVEPENTO			;Rahmen Quell-Verzeichnis.
			w $0000
			b $30
			b FRAME_RECTO
			w $009f
			b $c7

			b MOVEPENTO			;Rahmen Ziel-Verzeichnis.
			w $00a0
			b $30
			b FRAME_RECTO
			w $013f
			b $c7

			b MOVEPENTO			;Rahmen Quell-Verzeichnis.
			w $0007
			b $37
			b FRAME_RECTO
			w $0098
			b $a0

			b MOVEPENTO			;Rahmen Ziel-Verzeichnis.
			w $00a7
			b $37
			b FRAME_RECTO
			w $0138
			b $a0

if Sprache = Deutsch
			b ESC_PUTSTRING
			w $000a
			b $2e
			b PLAINTEXT
			b "Dateiauswahl"
			b GOTOX
			w $00aa
			b "Zielverzeichnis"
			b NULL
endif

if Sprache = Englisch
			b ESC_PUTSTRING
			w $000a
			b $2e
			b PLAINTEXT
			b "Files"
			b GOTOX
			w $00aa
			b "Target-directory"
			b NULL
endif

;*** Anzeigefeld für "Anzahl Dateien" löschen.
:V407e1			b NEWPATTERN,$00

			b MOVEPENTO
			w $0001
			b $c0
			b RECTANGLETO
			w $009e
			b $c6

			b MOVEPENTO
			w $00a1
			b $c0
			b RECTANGLETO
			w $013e
			b $c6

			b NULL

;*** Icontabelle.
:Icon_Tab1		b 9
			w $0000
			b $00

			w Icon_07
			b $01,$a8,$04,$10
			w TakeSource

			w Icon_05
			b $06,$a8,$02,$10
			w S_Reset

			w Icon_06
			b $08,$a8,$02,$10
			w S_SetAll

			w Icon_08
			b $15,$a8,$04,$10
			w TakeTarget

			w Icon_05
			b $1a,$a8,$02,$10
			w T_Reset

			w Icon_06
			b $1c,$a8,$02,$10
			w T_SetAll

			w Icon_09
			b $1f,$a8,$02,$10
			w ResetDir

			w Icon_10
			b $00,$08,$05,$18
			w L407ExitGD

			w Icon_11
			b $05,$08,$05,$18
			w WriteNewDir

:Icon_Tab1a		s 4 * 8

:Icon_Tab1b		w Icon_12
			b $14,$08,$05,$18
			w OtherDrive

			w Icon_13
			b $17,$08,$05,$18
			w GetDisk_a

			w Icon_14
			b $1a,$08,$05,$18
			w OtherPart

			w Icon_15
			b $1d,$08,$05,$18
			w OtherNDir

;*** Icons.
:Icon_05
<MISSING_IMAGE_DATA>

:Icon_06
<MISSING_IMAGE_DATA>

:Icon_07
<MISSING_IMAGE_DATA>

:Icon_08
<MISSING_IMAGE_DATA>

:Icon_09
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
:Icon_10
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_10
<MISSING_IMAGE_DATA>
endif

:Icon_11
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
:Icon_12
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_12
<MISSING_IMAGE_DATA>
endif

if Sprache = Deutsch
:Icon_13
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_13
<MISSING_IMAGE_DATA>
endif

:Icon_14
<MISSING_IMAGE_DATA>

:Icon_15
<MISSING_IMAGE_DATA>

:EndProgrammCode

;*** Speicher für Datei-Einträge.
:Memory
:Memory1		= PRINTBASE
:Memory2		= Memory1 + 256
:Memory3		= Memory2 + 256
:Memory4		= Memory3 + 256
:Memory5		= (Memory / 256 +1) * 256
:Memory6		= Memory5 + 256 * MaxReadSek
:Memory7		= Memory6 + 256 * MaxReadSek
