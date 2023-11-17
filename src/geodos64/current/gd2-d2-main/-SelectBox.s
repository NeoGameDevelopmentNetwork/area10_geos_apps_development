; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Auswahltabelle
; Datum			: 06.07.97
; Aufruf		: JSR  SelectBox
; Übergabe		: AKKU,xRegWord Zeiger auf Dialogboxtabelle
;			  b     $00 = Keine Laufwerksanzeige.
;			        $01 = Nur Laufwerk A:
;			        $02 = Nur Laufwerk A:, B:
;			        $03 = Nur Laufwerk A:, B:, C:
;			        $04 = Nur Laufwerk A:, B:, C:, D:
;			        $2x = Nur SD2IEC-Laufwerke.
;			        $4x = Nur CMD-Laufwerke.
;			        $80 = MSDOS-Laufwerk.
;			        $FF = Nur Laufwerk anzeigen.
;			  b     $00 = Kein Partitionswechsel.
;			        $FF = Partitionswechsel anbieten.
;			  b     $00 Einzel-Datei Auswahl.
;			        $ff Multi -Datei Auswahl.
;			  b     Länge der Datei-Namen.
;			  b     Anzahl "ActionFiles" in Tabelle.
;			  w     Zeiger auf Überschrift.
;			  w     Zeiger auf Dateitabelle.
;
; Rückgabe		: r13L= $00 Einzel-Datei Auswahl.
; Einzelauswahl		      = $01 Klick auf OK, ohne Auswahl einer Datei.
;			      = $02 Abbruch.
;			      = $8x Laufwerkseintrag.
;			      = $90 Partitions-Wechsel.
;			      = $ff Multi -Datei Auswahl.
;			  r13H= Nummer des Eintrages in Datei-Tabelle
;			  r14 = Zeiger auf Datei-Tabelle.
;			  r15 = Zeiger auf Datei-Eintrag
;
; Rückgabe		: r13L= s.o.
; Mehrfachauswahl	  r13H= Anzahl Dateien.
;			  r15 = Tabelle mit ausgewählten Files
;******************************************************************************

:BOX_Left		= 48
:BOX_Top		= 40
:TabXPos		= BOX_Left +16
:TabYPos		= BOX_Top +16
:TabRelPos		= SCREEN_BASE    + TabYPos * 40 + TabXPos - 8
:ColBoxTop		= (BOX_Top/8)*40 + BOX_Left/8

;*** Dialogbox aufrufen.
.SelectBox		sta	r15L			;Zeiger auf Definitionstabelle merken.
			stx	r15H
			LoadW	r0,DlgBoxData		;Zeiger auf Dialogboxdaten.
			DB_RecBox:101			;Dialogbox ausführen.
			lda	r13L
			ldx	r13H
::101			rts

;*** Dialogbox initialisieren.
:InitDlgBox		ldy	#$00			;Parameter merken:
::101			lda	(r15L),y
			sta	Mod_SlctDrv,y
			iny
			cpy	#$05
			bne	:101

			lda	(r15L),y		;Zeiger auf Titel merken.
			pha
			iny
			lda	(r15L),y
			pha
			iny
			lda	(r15L),y		;Zeiger auf Anfang Tabelle merken.
			sta	Vec_FileTab +0
			iny
			lda	(r15L),y
			sta	Vec_FileTab +1

			jsr	i_FillRam		;Speicher für Auswahlflags löschen.
			w	32,Flag_FileSlct
			b	$00

;*** Dialogbox zeichnen.
			jsr	i_C_FBoxClose
			b	$06,$05,$01,$01
			jsr	i_C_FBoxTitel
			b	$07,$05,$1b,$01
			jsr	i_C_FBoxBack
			b	$06,$06,$1c,$0c
			jsr	i_C_MenuTBox
			b	$07,$07,$13,$08

			Display	ST_WR_FORE
			jsr	i_GraphicsString
			b	NEWPATTERN,$00
			b	MOVEPENTO		;Titelzeile.
			w	$0038
			b	$28
			b	RECTANGLETO
			w	$010f
			b	$2f

			b	MOVEPENTO		;Dateifenster.
			w	$0037
			b	$37
			b	FRAME_RECTO
			w	$00d0
			b	$78
			b	NULL

			jsr	UseGDFont
			LoadW	r11,BOX_Left+16
			LoadB	r1H,BOX_Top +6
			pla
			tax
			pla
			jsr	PutText

;*** Laufwerksbox ?
			lda	Mod_SlctDrv		;Laufwerk anzeigen ?
			bne	:102			;Ja, weiter...
			sta	MaxDrvSlct
			jmp	InitSlctBar		;Nein, Laufwerk/Partition übergehen.

::102			jsr	CurDrvView		;Aktuelles Laufwerk/Diskette einlesen.

			jsr	i_C_MenuTBox		;Farbe für Laufwerksanzeige setzen.
			b	$07,$10,$13,$01
			jsr	CurDrvFrame		;Aktuelles Laufwerk anzeigen.

			lda	Mod_SlctDrv		;Laufwerkstausch möglich ?
			cmp	#$ff
			beq	:103			;Nein, weiter...

			jsr	i_BitmapUp
			w	Icon_DOWN
			b	$19,$80,$01,$08
			jsr	i_C_FBoxBack
			b	$19,$10,$01,$01

;*** Partitionswechsel anbieten ?
;--- Ergänzung: 21.11.18/M.Kanet
;Beim CMD-Laufwerken Partitions- und Verzeichniswechsel anbieten.
;Bei sonstigen NativeMode-Laufwerken nur Verzeichniswechsel.
::103			bit	Mod_SlctPart		;Partitionswechsel anbieten?
			bpl	InitSlctBar		; => Nein, weiter...
			lda	curDrvMode		;CMD-Laufwerk ?
			bmi	:103a			; => Ja, Auswahlbox anzeigen.
			and	#%00100000		;NativeMode-Laufwerk?
			beq	InitSlctBar		; => Nein, keine Auswahlbox.
			ldy	#$ff
			bne	:104			;Nur Verzeichniswechsel anbieten.

;--- Aktive Partition einlesen.
::103a			ldx	curDrive
			lda	DrivePart -8,x
			jsr	GetPartInfo		;Partition einlesen.
			txa				;Fehler?
			beq	:104			; => Ja, weiter...
			ldy	#$00			;Partitionswechsel anbieten.
::104			tya
			pha

;--- Rahmen für Partitions-/Verzeichniswechsel zeichnen.
			jsr	i_C_MenuTBox
			b	$1b,$10,$05,$01
			jsr	i_GraphicsString
			b	MOVEPENTO
			w	$00d7
			b	$7f
			b	FRAME_RECTO
			w	$0108
			b	$88
			b	ESC_PUTSTRING
			w	$00de
			b	$86
			b	PLAINTEXT
			b	NULL

			pla
			cmp	#$ff			;Partitions- oder Verzeichniswechsel?
			bne	:104a			; => Partitionswechsel, weiter...
			lda	#"D"			;"DIR" für Verzeichniswechsel auf
			jsr	PutChar			;NativeMode-Laufwerken anzeigen.
			lda	#"I"
			jsr	PutChar
			lda	#"R"
			jsr	PutChar
			jmp	:104b

::104a			pha				;"Pxxx" für Partitionswechsel und
			lda	#"P"			;ggf. Verzeichniswechsel anzeigen.
			jsr	PutChar
			pla
			sta	r0L
			lda	#$00
			sta	r0H
			sta	r1L
			ldy	#$03
			jsr	Do0Z24Bit		;Zahl nach ASCII wandeln.

;--- DropDown-Pfeil anzeigen.
::104b			jsr	i_BitmapUp
			w	Icon_DOWN
			b	$20,$80,$01,$08

;*** Tabelle/Scroll-Balken initialisieren.
:InitSlctBar		ClrB	Page_1stFile		;Tabelle auf Anfang.
			jsr	TestFileTab		;Tabelle testen.
			lda	MaxFileInTab
			sta	MoveBarData+3

			LoadW	r0,MoveBarData
			jsr	InitBalken

			jsr	PrintTab		;Tabelle zeigen.

;*** Select-Icons zeichnen.
			ldx	Mod_FileSlct		;Mehr-Dateiauswahl ?
			beq	:1			;Nein, weiter.
			stx	Flag_SlctMode
			jsr	i_BitmapUp
			w	Icon_Slct
			b	$1b,$50,$02,$10
			jsr	i_C_MenuMIcon
			b	$1b,$0a,$02,$02

;*** Warten bis keine Maustaste gedrückt.
::1			jsr	i_C_FBoxDIcon
			b	$1b,$07,$06,$02
			jsr	i_C_FBoxDIcon
			b	$1b,$0d,$06,$02

			jsr	WaitNoMKey
			LoadW	appMain,:2
			rts

::2			ClrW	appMain
			jmp	SetWindow_b

;*** Datei-Liste überprüfen.
:TestFileTab		MoveW	Vec_FileTab,r0		;Anfang Daten-Tabelle nach ":r0".

			ldx	#$00
			ldy	#$00
::101			lda	(r0L),y			;Auf Tabellen-Ende prüfen.
			beq	:103			;Ja, Ende erreicht.
			inx				;Anzahl Dateien erhöhen.
			cpx	#255			;Mehr als 255 Files ?
			beq	:103			;Ja, Abbruch.
::102			AddVBW	16,r0
			jmp	:101

::103			stx	MaxFileInTab
			rts

;*** Zurück zum DeskTop
:L162Exit_a		lda	#$01			;"OK".
			b $2c
:L162Exit_b		lda	#$02			;"CLOSE" / "ABBRUCH".
			b $2c
:L162Exit_c		lda	#$90			;"PARTITION"
			b $2c
:L162Exit		lda	r0L
			sta	Flag_ExitMode

;*** Bildschirm wiederherstellen.
			jsr	i_C_ColorClr
			b	$06,$05,$1c,$0e

			FillPRec$00,$28,$91,$0030,$010f

;*** Einzeldateiauswahl.
			lda	Mod_FileSlct
			bne	:102
			lda	Flag_ExitMode		;Rücksprung.
			bne	:101

			lda	CurSlctFile		;Zeiger auf Eintrag bereitstellen.
			jsr	PosToFile
			stx	r15L
			sty	r15H
			MoveW	Vec_FileTab,r14

			lda	Flag_ExitMode		;Rücksprung.
::101			ldx	CurSlctFile		;Nr. des Eintrags.

;*** Rückgabewerte in Register und
;    zurück zur Applikation.
::ExitToAppl		sta	r13L
			stx	r13H
			jsr	SetWindow_a
			jmp	RstrFrmDialogue

;*** Klick auf OK, Abbruch oder Laufwerk.
::102			lda	Flag_ExitMode
			beq	:103
			cmp	#$01
			beq	:104
			cmp	#$ff
			beq	:104
::103			ldx	#$00
			jmp	:ExitToAppl

;*** Mehrfachauswahl: Tabelle erzeugen.
::104			lda	Vec_FileTab+0
			sta	r14L
			sta	r15L
			lda	Vec_FileTab+1
			sta	r14H
			sta	r15H

			lda	#$00
			sta	MaxFileInTab
			sta	CurSlctFile

::105			ldy	#$00			;Nicht gewählte
			lda	(r14L),y		;Dateien aus Tabelle löschen.
			bne	:107
			sta	(r15L),y
			MoveW	Vec_FileTab,r15

			lda	#$ff			;Rücksprung.
			ldx	MaxFileInTab		;Anzahl Dateien.
			bne	:106
			lda	#$01
::106			jmp	:ExitToAppl		;Nr. des Eintrags.

::107			lda	CurSlctFile		;Ist Datei ausgewählt ?
			jsr	PosToSlctFile
			and	BitDefTab,y
			beq	:109			;Nein, überspringen.

			ldy	#$0f			;Eintrag umkopieren.
::108			lda	(r14L),y
			sta	(r15L),y
			dey
			bpl	:108
			jsr	Add_16_r15		;Zeiger auf nächsten Eintrag.
			inc	MaxFileInTab

::109			AddVBW	16,r14			;Zeiger auf nächste Datei in Tabelle.
			inc	CurSlctFile
			jmp	:105

;*** Datei/Scroll-Icons auswählen.
:ChkMseClick		lda	mouseData
			bmi	WaitNoMKey

			ClrB	r15L
::101			tay
			jsr	ChkMseArea		;Mausklick in Datei-Area ?
			beq	:102			;Nein, weiter...
			jmp	(r5)			;Datei auswählen.

::102			AddVB	8,r15L
			cmp	#10*8
			bne	:101

;*** Warten bis keine Maustaste gedrückt.
:WaitNoMKey		NoMseKey
			rts

;*** Ist Maus in bestimmten Bereich (Tabelle oder Scroll-Icons) ?
:ChkMseArea		ldx	#$00
::101			lda	MseTestAreas,y
			sta	r2L,x
			iny
			inx
			cpx	#$08
			bne	:101

			php
			sei
			jsr	IsMseInRegion
			plp
			tax
			rts

;*** Datei auswählen.
:SelectFile		lda	mouseYPos		;Klick auf Datei berechnen.
			sub	TabYPos
			lsr
			lsr
			lsr
			sta	:102 +1
			adda	Page_1stFile
			cmp	MaxFileInTab
			bcs	:107			;Keine Datei angeklickt.

::101			sta	CurSlctFile		;Dateinr. merken.
			jsr	PosToFile		;Zeiger auf Dateieintrag berechnen.
			stx	r0L
			sty	r0H

			lda	CurSlctFile		;Modus der Datei invertieren.
			jsr	PosToSlctFile
			eor	BitDefTab,y
			sta	Flag_FileSlct,x
			and	BitDefTab,y		;Aktuellen Zustand der gewählten Datei
			sta	:105 +1			;merken (für Doppelklick!).

::102			lda	#$00			;Dateiname ausgeben.
			jsr	PrintName

			jsr	WaitNoMKey

			lda	Mod_FileSlct		;Mehrdatei-Modus ?
			beq	:106			;Ja, weiter...

::104			lda	Cnt_SysEntry		;ACTION-Files vorhanden ?
			beq	:105			;Nein, weiter...
			cmp	CurSlctFile		;ACTION-File angeklickt ?
			beq	:105			;Nein,...
			bcc	:105			;Nein, weiter...

			lda	#$00			;ACTION-Eintrag auswählen.
			sta	Mod_FileSlct
			beq	:106

::105			ldx	#$ff			;Wurde Datei angewählt ?
			beq	:107			;Nein, weiter...
			jsr	TestDblClick		;Test auf Doppelklick.
			txa				;Doppelklick ?
			beq	:107			;Nein, weiter...

			lda	#$ff			;Ja, Auswahl beenden.
			b $2c
::106			lda	#$00
			sta	r0L
			jmp	L162Exit

::107			rts

;*** Auf Doppelklick testen.
:TestDblClick		jsr	GetMouseYPos
			sta	:102 +1

			ldx	#$05
::101			stx	:103 +1

			jsr	GetMouseYPos
::102			cmp	#$ff
			bne	:104

			lda	inputData
			bpl	:104
			lda	pressFlag
			and	#%00100000
			bne	:105

			jsr	CPU_Pause
::103			ldx	#$ff
			dex
			bne	:101

::104			ldx	#$00
			rts

::105			jsr	WaitNoMKey
			ldx	#$ff
			rts

;*** Y-Pos. testen.
:TestMouseYPos		jsr	GetMouseYPos
			cmp	r0H
			rts

;*** Y-Pos. ermitteln.
:GetMouseYPos		lda	mouseYPos
			lsr
			lsr
			lsr
			rts

;*** Bildschirmdaten kopieren.
:CopyScrnData		ldy	#$00			;Grafikzeilen a 144 Byte (18 * 8)
::101			lda	(r0L),y			;verschieben.
			sta	(r1L),y
			iny
			cpy	#144
			bne	:101
			rts

;*** Anzeigebalken neu Positionieren.
:NewPosBalken		lda	Page_1stFile
			jmp	SetPosBalken

;*** Balken verschieben.
:MoveBar		lda	MaxFileInTab
			cmp	#$08
			bcc	:100
			jsr	IsMseOnPos		;Position der Maus ermitteln.
			cmp	#$01			;Oberhalb des Anzeigebalkens ?
			beq	:101			;Ja, eine Seite zurück.
			cmp	#$02			;Auf dem Anzeigebalkens ?
			beq	:102			;Ja, Balken verschieben.
			cmp	#$03			;Unterhalb des Anzeigebalkens ?
			beq	:103			;Ja, eine Seite vorwärts.
::100			rts

::101			jmp	LastPage
::102			jmp	MoveToPos
::103			jmp	NextPage

;*** Balken verschieben.
:MoveToPos		jsr	StopMouseMove		;Mausbewegung einschränken.

::101			jsr	UpdateMouse		;Mausdaten aktualisieren.
			ldx	mouseData		;Maustaste noch gedrückt ?
			bmi	:102			;Nein, neue Position anzeigen.
			lda	inputData		;Mausbewegung einlesen.
			bne	:103			;Mausbewegung auswerten.
			beq	:101			;Keine Bewegung, Schleife...

::102			ClrB	pressFlag		;Maustastenklick löschen.
			jsr	SetWindow_b		;Fenstergrenzen zurücksetzen.
			jmp	PrintTab		;Position anzeigen.

::103			cmp	#$02			;Maus nach oben ?
			beq	:104			;Ja, auswerten.
			cmp	#$06			;Maus nach unten ?
			beq	:105			;Ja, auswerten.
			jmp	:101			;Keine Bewegung, Schleife...

::104			jsr	LastFile_a		;Eine Datei zurück.
			bcs	:101			;Geht nicht, Abbruch.
			dec	Page_1stFile		;Zeiger auf letzte Datei.
			jmp	:106			;Neue Position anzeigen.

::105			jsr	NextFile_a		;Eine Datei vorwärts.
			bcs	:101			;Geht nicht, Abbruch.
			inc	Page_1stFile		;Zeiger auf nächste Datei.
::106			jsr	NewPosBalken		;Tabellenposition einlesen und
							;Anzeigebalken setzen.
			jsr	SetRelMouse		;Mauszeiger verschieben.
			jmp	:101			;Maus weiter auswerten.

;*** Scoll-Icon auswählen.
:SlctAllFiles		ldx	Mod_FileSlct		;Mehr-Dateiauswahl ?
			beq	:103			;Nein, weiter.
			jsr	InvertRectangle

			lda	Flag_SlctMode
			eor	#%11111111
			sta	Flag_SlctMode
			beq	:101

			jsr	ReSelect
			jmp	:102

::101			jsr	AllSelect

::102			lda	#$20
			jmp	EndScrolling

::103			rts

;*** Zeiger auf Zustands-Bit in Datei-Tabelle.
;    Für jeden Eintrag gibt es ein Bit, welches anzeigt ob die Datei angewählt
;    ist oder nicht. Bit = 1, Datei ist angewählt.
:PosToSlctFile		tay				;Zeiger auf Zustands-Bit für
			lsr				;aktuellen Eintrag berechnen.
			lsr
			lsr
			tax
			tya
			and	#%00000111
			tay				;Zeiger auf Bit im yReg.
			lda	Flag_FileSlct,x		;Zeiger innerhalb Tabelle im xReg.
			rts

;*** Zeiger auf Anfang Tabellen-Ausschnitt berechnen.
;    Eingabe:		AKKU = Position ":Page_1stFile"
;    Ausgabe:		xReg = Low -Byte
;			yReg = High-Byte
:PosToFile		sta	r15L			;Zeiger auf den ersten Eintrag in der
			ClrB	r15H			;Tabelle berechnen und die nächsten
			ldx	#r15L			;8 Einträge ausgeben.
			ldy	#$04
			jsr	DShiftLeft
			clc
			lda	r15L
			adc	Vec_FileTab +0
			tax
			lda	r15H
			adc	Vec_FileTab +1
			tay
			rts

;*** Tabelle ausgeben.
:PrintTab		jsr	NewPosBalken		;Tabellenposition einlesen und
							;Anzeigebalken setzen.
			lda	Page_1stFile
			jsr	PosToFile		;Zeiger auf Datei einlesen.
			stx	r15L
			sty	r15H

			lda	#$00			;Dateizähler löschen.
::101			tax
			ldy	#$00
			lda	(r15L),y		;Byte aus Dateinamen einlesen.
			bne	:102			; <> $00, Dateiname ausgeben.
			rts

::102			MoveW	r15,r0			;Zeiger auf Tabelleneintrag setzen.

			txa				;Zeiger auf Eintrag speichern.
			pha				;und aktuellen Eintrag ausgeben.
			jsr	PrintName
			jsr	Add_16_r15		;Zeiger auf nächsten Eintrag.
			pla
			add	$01			;Zähler für Anzahl Dateien +1.
			cmp	#$08			;'8' dateien ausgegeben ?
			bne	:101			;Nein, weiter...

			rts				;Ende...

;*** Neuen Eintrag in Tabelle ausgeben.
:PrintNewEntry		stx	:101 +1			;Nr. relativ zu ":Page_1stFile" merken.
			jsr	PosToFile		;Zeiger auf Datei einlesen.
			stx	r0L
			sty	r0H
::101			lda	#$ff			;Neuen Datei-Namen ausgeben.

;*** Name ausgeben.
:PrintName		pha				;Nr. relativ zu Page_1stFile.
			adda	Page_1stFile
			sta	:101 +1
			sta	:103 +1
			pla				;Nr. des Eintrages (absolut) berechnen.
			asl				;(Also Position von 0-7).
			asl
			asl
			add	TabYPos+6
			sta	DefRectangle +1
			jsr	DefRectangle

			ClrB	currentMode

::101			lda	#$00			;Zustands-Bit für Eintrag einlesen.
			jsr	PosToSlctFile
			and	BitDefTab,y
			beq	:102			;-> Datei nicht angewählt.
			lda	#%00100000
			sta	currentMode
			lda	#$01
::102			jsr	SetPattern
			jsr	Rectangle

			lda	DefRectangle +1
			sta	r1H			;Y-Koordinate berechnen.
			LoadW	r11,TabXPos		;X-Koordinate für Eintrag setzen.

			ldx	Cnt_SysEntry		;ACTION-Einträge vorhanden ?
			beq	:105			;Nein, weiter...

::103			lda	#$ff
			cmp	Cnt_SysEntry
			bcs	:104
			lda	#">"			;Action-Files markieren.
			b $2c
::104			lda	#" "			;Standard-Eintrag merkieren.
			jsr	SmallPutChar
			lda	#" "
			jsr	SmallPutChar

::105			ldy	#$00			;Eintrag ausgeben.
::106			sty	:107 +1
			lda	(r0L),y
			jsr	ConvertChar
			jsr	SmallPutChar
::107			ldy	#$ff
			iny
			cpy	Len_FileName
			bne	:106
			rts

;*** Rechteck definieren.
:DefRectangle		lda	#$ff
			tax
			inx
			stx	r2H
			sub	6
			sta	r2L

			ldx	#$03
::101			lda	MseTestAreas +2,x
			sta	r3L      ,x
			dex
			bpl	:101
			rts

;*** Eine Seite vorwärts.
:NextPage		lda	Page_1stFile
			add	15
			cmp	MaxFileInTab
			bcc	:101
			jmp	EndPage

::101			lda	Page_1stFile
			add	8
			sta	Page_1stFile
			jmp	PrintTab

;*** Eine Seite zurück.
:LastPage		lda	Page_1stFile
			cmp	#$08
			bcs	:101
			jmp	TopPage

::101			lda	Page_1stFile
			sub	8
			sta	Page_1stFile
			jmp	PrintTab

;*** Zum Anfang.
:TopPage		lda	#$00
			cmp	Page_1stFile
			beq	:101
			sta	Page_1stFile
			jsr	PrintTab
::101			rts

;*** Zum Ende.
:EndPage		lda	MaxFileInTab
			sub	8
			bcc	TopPage
			cmp	Page_1stFile
			beq	:101
			sta	Page_1stFile
			jsr	PrintTab
::101			rts

;*** Dateien abwählen.
:ReSelect		jsr	InitIconSlct
			lda	Cnt_SysEntry
::101			pha
			jsr	PosToSlctFile
			ora	BitDefTab,y
			eor	BitDefTab,y
			sta	Flag_FileSlct,x
			pla
			add	1
			bne	:101
			jmp	PrintTab

;*** Dateien abwählen.
:AllSelect		jsr	InitIconSlct
			lda	Cnt_SysEntry
::101			pha
			jsr	PosToSlctFile
			ora	BitDefTab,y
			sta	Flag_FileSlct,x
			pla
			add	1
			bne	:101
			jmp	PrintTab

;*** Icon-Klick auf "Select" initialisieren.
:InitIconSlct		lda	Cnt_SysEntry
			jsr	PosToFile
			stx	r0L
			sty	r0H
			rts

;*** Weiterscrollen.
:NextScroll		jsr	CPU_Pause
			lda	mouseData		;Dauerfunktion ?
			rts

;*** Pause für SuperCPU
.CPU_Pause		lda	$01
			pha
			lda	#$35
			sta	$01
			lda	$dc08			;Sekunden/10 - Register.
::101			cmp	$dc08
			beq	:101
			pla
			sta	$01
			rts

;*** Icon Re-Invertieren.
:EndScrolling		pha				;Akku zwischenspeichern.
			jsr	SetWindow_b		;Fenstergrenzen zurücksetzen.
			pla
			tay				;Icon-Daten einlesen.
			jsr	ChkMseArea
			jmp	InvertRectangle		;Icon Reinvertieren.

;*** Eine Datei vorwärts.
:NextFile		jsr	NextFile_a
			bcs	NextFile_b
			jsr	StopMouseMove		;Mausbewegung einschränken.
			jsr	InvertRectangle		;Icon invertieren.

::101			jsr	NextFile_a		;Scrolling möglich ?
			bcs	:102			;Nein, Abbrch.
			jsr	NextFile_c		;Eine Datei vorwärts.
			jsr	NextScroll		;Weiterscrollen ?
			beq	:101			;Ja, weiter...
::102			lda	#$10			;Scrolling abschließen.
			jmp	EndScrolling

;*** Nächste Datei noch vorhanden ?
:NextFile_a		lda	Page_1stFile		;Tabellen-Ende erreicht ?
			add	$08
			cmp	MaxFileInTab
:NextFile_b		rts

;*** Bildschirm scrollen.
:NextFile_c		php				;IRQ sperren.
			sei

			LoadW	r0,TabRelPos

			ldx	#$07
::101			clc				;Zeiger auf Grafik-Daten berechnen.
			lda	r0L
			sta	r1L
			adc	#<320
			sta	r0L
			lda	r0H
			sta	r1H
			adc	#>320
			sta	r0H
			jsr	CopyScrnData
			dex
			bne	:101

			plp

			inc	Page_1stFile		;Tabellenzeiger korrigieren.
			jsr	NewPosBalken

			clc
			lda	Page_1stFile		;Nächsten Dateinamen ausgeben.
			adc	#$07
			ldx	#$07
			jsr	PrintNewEntry
			clc
			rts

;*** Eine Datei zurück.
:LastFile		jsr	LastFile_a
			bcs	LastFile_b
			jsr	StopMouseMove		;Mausbewegung einschränken.
			jsr	InvertRectangle		;Icon invertieren.

::101			jsr	LastFile_a		;Scrolling möglich ?
			bcs	:102			;Nein, Abbrch.
			jsr	LastFile_c		;Eine Datei zurück.
			jsr	NextScroll		;Weiterscrollen ?
			beq	:101			;Ja, weiter...
::102			lda	#$08			;Scrolling abschließen.
			jmp	EndScrolling

;*** Nächste Datei noch vorhanden ?
:LastFile_a		lda	Page_1stFile		;Tabellenanfang erreicht ?
			bne	:101			;Nein, -> Scrolling.
			sec				;Abbruch.
			rts
::101			clc
:LastFile_b		rts

;*** Bildschirm scrollen.
:LastFile_c		php				;IRQ sperren.
			sei

			LoadW	r0,TabRelPos+2240

			ldx	#$07
::101			sec				;Zeiger auf Grafik-Daten berechnen.
			lda	r0L
			sta	r1L
			sbc	#<320
			sta	r0L
			lda	r0H
			sta	r1H
			sbc	#>320
			sta	r0H
			jsr	CopyScrnData
			dex
			bne	:101

			plp

			dec	Page_1stFile		;Tabellen-Zeiger korrigieren.
			jsr	NewPosBalken

			lda	Page_1stFile		;Nächsten Dateinamen ausgeben.
			ldx	#$00
			jsr	PrintNewEntry
			clc				;Weiterscrollen.
			rts

;*** Neues Laufwerk wählen.
:SlctNewDrv		lda	Mod_SlctDrv		;Laufwerk wählen erlaubt ?
			beq	:101			; => Nein, Ende...
			cmp	#$ff			;Nur aktuelles Laufwerk?
			bne	:102			; => Nein, weiter...
::101			rts

::102			cmp	#$80			;MSDOS-Laaufwerk wählen?
			bne	:103			; => Nein, weiter...
			sta	r0L
			jmp	L162Exit

::103			jsr	AllDrvView		;Laufwerkstabelle erzeugen.

			jsr	i_C_MenuTBox
			b	$07,$10,$12,$05

			jsr	i_GraphicsString
			b	NEWPATTERN,$00
			b	MOVEPENTO		;Hintergrund.
			w	$0038
			b	$80
			b	RECTANGLETO
			w	$00c7
			b	$a7
			b	FRAME_RECTO		;Rahmen.
			w	$0038
			b	$80
			b	NULL

			PrintStrgDriveNames		;Laufwerke ausgeben.

			jsr	SetWindow_c		;Fenster einschränken.
			LoadW	otherPressVec,SlctDrive
			jmp	WaitNoMKey

;*** Laufwerk auswählen.
:SlctDrive		jsr	StopMouseMove		;Mausbewegung stoppen.

			lda	mouseYPos		;Gewähltes Laufwerk ermitteln.
			sub	$82
			bcc	:101
			lsr
			lsr
			lsr
			cmp	MaxDrvSlct		;Gültig ?
			bcc	:102			;Ja, weiter...

;*** Laufwerksauswahl beenden.
::101			jsr	ClrDrvWin		;Fenster löschen.
			jsr	SetWindow_b
			LoadW	otherPressVec,ChkMseClick
			jmp	WaitNoMKey		;Auswahl beenden.

;*** Laufwerk auswählen.
::102			pha
			jsr	ClrDrvWin		;Fenster löschen.
			ClrB	Mod_FileSlct		;ACTION-Eintrag auswählen.
			pla
			tax
			lda	CMD_Drives ,x
			sec
			sbc	#$08
			ora	#%10000000		;Laufwerk auswählen.
			sta	r0L
			jmp	L162Exit

;*** Aktuelles Laufwerk & Diskettennamen anzeigen.
:CurDrvView		lda	Mod_SlctDrv
			sta	CopyMSlctDrv
			LoadB	Mod_SlctDrv,$ff
			jsr	AllDrvView
			lda	CopyMSlctDrv
			sta	Mod_SlctDrv
			rts

;*** Laufwerksbezeichnungen einlesen.
:AllDrvView		ldy	#17			;Laufwerkstabelle löschen.
			lda	#" "
::101			sta	DrvANm,y
			sta	DrvBNm,y
			sta	DrvCNm,y
			sta	DrvDNm,y
			dey
			bpl	:101

			lda	curDrive		;Aktuelles Laufwerk merken.
			sta	r10L

			lda	#$08			;Zeiger auf erstes Laufwerk.
			sta	r10H

			ClrB	MaxDrvSlct		;Anzahl Laufwerke löschen.
			LoadW	r11 ,DrvANm		;Zeiger auf Tabelle.

::102			lda	Mod_SlctDrv
			cmp	#$ff			;Nur aktuelles Laufwerk anzeigen ?
			bne	:103			;Nein, weiter...

			lda	r10L
			cmp	r10H			;Aktuelles Laufwerk erreicht ?
			bne	:107			;Nein, nächstes Laufwerk.

::103			ldx	r10H			;Zeiger auf aktuelles Laufwerk.
			lda	DriveTypes -8,x		;Laufwerkstyp einlesen.
			beq	:107			; $00, => Nicht verfügbar...

			lda	Mod_SlctDrv
			cmp	#$ff			;Nur aktuelles Laufwerk anzeigen ?
			beq	:106			;Ja, weiter...

;			lda	Mod_SlctDrv
			and	#%01100000		;Nur CMD/SD2IEC-Laufwerke anzeigen ?
			beq	:106			; => Nein, weiter...
			and	#%01000000		;CMD-Laufwerke anzeigen ?
			beq	:104			; => Nein, weiter...
;			ldx	r10H			;Zeiger auf aktuelles Laufwerk.
			lda	DriveModes -8,x		;Laufwerksmodi einlesen.
			bmi	:106			; => CMD-Laufwerk...

::104			lda	Mod_SlctDrv
			and	#%00100000		;Nur SD2IEC-Laufwerke anzeigen ?
			beq	:107			; => Nein, weiter...
;			ldx	r10H			;Zeiger auf aktuelles Laufwerk.
			lda	DriveModes -8,x		;Laufwerksmodi einlesen.
			and	#%00000001
			beq	:107			; => Kein SD2IEC-Laufwerk...

::106			jsr	GetDskName		;Disk-/Partitionsname einlesen.

::107			lda	Mod_SlctDrv
			cmp	#$ff			;Nur aktuelles Laufwerk anzeigen ?
			beq	:108			;Ja, weiter...

			and	#%00000111		;Max. Anzahl anzuzeigender Laufwerke
			clc				;berechnen.
			adc	#$07
			cmp	r10H			;Max. Anzahl Laufwerke erreicht ?
			bcc	:109			;Ja, Ende...

::108			inc	r10H			;Zeiger auf nächstes Laufwerk...
			CmpBI	r10H,12			;Alle Laufwerke getestet ?
			bcc	:102			;Nein, weiter...

::109			lda	r10L
			jmp	NewDrive		;Laufwerk zurücksetzen.

;*** Laufwerksbezeichnug einlesen.
:GetDskName		ldy	#$00			;Laufwerksbezeichnung in Tabelle
			lda	r10H			;eintragen.
			clc
			adc	#$39
			sta	(r11L),y
			iny
			lda	#":"
			sta	(r11L),y

			ldx	MaxDrvSlct
			lda	r10H
			sta	CMD_Drives ,x
			tax
			lda	DriveModes -8,x		;Laufwerksmodi einlesen.
			and	#%00000001		;SD2IEC-Laufwrk?
			beq	:99			; => Nein, CMD-Laufwerk...

;--- SD2IEC-Laufwerk.
			lda	#<DrvSD2IEC-2		;Kein Diskname sondern "SD2IEC" bei
			ldy	#>DrvSD2IEC-2		;Laufwerksauswahlbox anzeigen.
			ldx	#$00
			beq	:102

;--- CMD-Laufwerk.
::99			txa
			jsr	NewDrive		;Laufwerk aktivieren.
			txa				;Fehler ?
			bne	:104			;Ja, Abbruch.

			lda	CopyMSlctDrv
			cmp	#$80			;MSDOS-Laufwerk ?
			bne	:100			;Nein, weiter...
			lda	#<dosDiskName-2
			ldy	#>dosDiskName-2
			ldx	#$00
			beq	:102

::100			ldx	curDrive
			lda	DriveModes-8,x		;Laufwerksmodus einlesen.
			bmi	:101			;CMD-Laufwerk ? Ja, weiter...

			jsr	GetDirHead		;Commodore-Laufwerk, Diskettenname
							;einlesen.

			lda	#<curDirHead +$8e
			ldy	#>curDirHead +$8e
			bne	:102

::101			lda	DrivePart -8,x
			jsr	GetPartInfo		;Partitionsdaten einlesen.

			lda	#<Part_Info  +$03
			ldy	#>Part_Info  +$03

::102			sta	r12L			;Zeiger auf Disk-/Partitionsname merken
			sty	r12H

			txa				;Diskettenfehler ?
			bne	:104			;Ja, Abbruch.

			ldy	#$02			;Disk-/Partitionsname kopieren.
::103			lda	(r12L),y
			beq	:104
			jsr	ConvertChar
			sta	(r11L),y
			iny
			cpy	#$12
			bne	:103

::104			inc	MaxDrvSlct		;Anzahl Laufwerke +1.
			AddVBW	22,r11			;Zeiger auf Tabelle korrigieren.
			rts

;*** Fenster löschen.
:ClrDrvWin		jsr	i_C_ColorClr
			b	$07,$12,$13,$03
			jsr	i_C_FBoxBack
			b	$07,$11,$12,$01

			jsr	i_GraphicsString
			b	NEWPATTERN,$00

			b	MOVEPENTO		;Dialogbox.
			w	$0038
			b	$7f
			b	RECTANGLETO
			w	$00c7
			b	$8e

			b	MOVEPENTO		;Rahmen.
			w	$0038
			b	$8f
			b	LINETO
			w	$00c7
			b	$8f

			b	MOVEPENTO		;Hintergrund.
			w	$0038
			b	$90
			b	RECTANGLETO
			w	$00c7
			b	$a7

			b	NULL

;*** Rahmen für Laufwerksanzeige darstellen.
:CurDrvFrame		jsr	i_GraphicsString
			b	NEWPATTERN,$00
			b	MOVEPENTO		;Laufwerksrahmen.
			w	$0037
			b	$7f
			b	FRAME_RECTO
			w	$00d0
			b	$88

			b	MOVEPENTO		;Hintergrund.
			w	$0038
			b	$80
			b	RECTANGLETO
			w	$00c7
			b	$87

			b	NULL

;*** Aktuelles Laufwerk anzeigen.
:PrnCurDrv		ldx	#0
			ldy	#5
::101			cpx	MaxDrvSlct		;Ende der Tabelle erreicht ?
			beq	:102			;Ja, Ende...
			lda	curDrive		;Aktuelles Laufwerk in Tabelle
			add	$39			;gefunden ?
			cmp	DriveNames,y
			beq	:103			;Ja, anzeigen.
			inx
			tya
			add	22
			tay				;Weitersuchen.
			cpy	#5 + 4*22		;Ende erreicht ?
			bne	:101			;Nein, weiter...

			ldx	#$00
::102			ldy	#5			;Erstes Laufwerk wählen.
::103			txa				;Zeiger auf Eintrag merken.
			pha
			sty	:105 +1

			jsr	i_PutString		;Bildschirmposition setzen.
			w	$0040
			b	$86
			b	PLAINTEXT
			b	NULL

			ldx	#$12			;Max. 18 Zeichen ausgeben.
::104			stx	:106 +1

::105			ldy	#$ff
			lda	DriveNames,y		;Zeichen aus Tabelle einlesen und
			jsr	SmallPutChar		;auf Bildschirm ausgeben.
			inc	:105 +1

::106			ldx	#$ff
			dex				;Alle Zeichen ausgegeben ?
			bne	:104			;Nein, weiter...

::107			pla				;Eintrag zurücksetzen.
			rts

;*** Partitionswechsel.
:GetNewPart		bit	Mod_SlctPart		;Partitionswechsel möglich ?
			bpl	:101			; => Nein, Abbruch...
			lda	curDrvMode		;CMD-Laufwerk ?
			bmi	:100			; => Ja, weiter...
			and	#%00100000		;NativeMode-Laufwerk?
			beq	:101			;Nein, Abbruch...
::100			jmp	L162Exit_c		;Partition/Verzeichnis wählen.
::101			rts

;*** Variablen.
:Mod_SlctDrv		b $00				;Anzahl Laufwerke.
:Mod_SlctPart		b $00				;Partitionswechsel.
:Mod_FileSlct		b $00				;Einzel-/Mehrfachauswahl.
:Len_FileName		b $00				;Länge Dateinamen.
:Cnt_SysEntry		b $00				;Anzahl "ActionFiles" in Tabelle.
:Vec_FileTab		w $0000				;Zeiger auf Tabelle.
:CopyMSlctDrv		b $00				;Kopie von ":Mod_SlctDrv"

:MaxDrvSlct		b $00				;Anzahl Laufwerke in Tabelle.
:CMD_Drives		s $04				;CMD-Laufwerke.
:CurSlctFile		b $00				;Ausgewählte Datei
:Flag_SlctMode		b $00				;Modus für Wahl/Abwahl.
:Flag_ExitMode		b $00				;Abbruch-Funktion.

:Page_1stFile		b $00
:MaxFileInTab		b $00
:Flag_FileSlct		s 32				;32 Byte a 8 Bit = 256 Dateien.
:BitDefTab		b $80,$40,$20,$10,$08,$04,$02,$01

;*** Mausabfrage-Bereiche.
:MseTestAreas		b $38,$77
			w $0038,$00c7,SelectFile
			b $38,$3f
			w $00c8,$00cf,LastFile
			b $70,$77
			w $00c8,$00cf,NextFile
			b $40,$6f
			w $00c8,$00cf,MoveBar
			b $50,$5f
			w $00d8,$00e7,SlctAllFiles
			b $80,$8a
			w $0038,$00cf,SlctNewDrv
			b $80,$8a
			w $00d8,$0107,GetNewPart

;*** Daten für Scrollbalken.
:MoveBarData		b $19,$40,$30,$00,$08,$00

;*** Dialogbox-Daten.
:DlgBoxData		b %00100000
			b $28,$8f
			w $0030,$010f
			b DBUSRICON,  0,  0
			w V162d0
			b DBUSRICON, 21, 16
			w V162d1
			b DBUSRICON, 21, 64
			w V162d2
			b DBOPVEC
			w ChkMseClick
			b DB_USR_ROUT
			w InitDlgBox
			b NULL

;*** Icon-Grafiken.
:V162d0			w Icon_Close
			b $00,$00,$01,$08
			w L162Exit_b
:V162d1			w Icon_OK
			b $00,$00,$06,$10
			w L162Exit_a
:V162d2			w Icon_Abbruch
			b $00,$00,$06,$10
			w L162Exit_b

;*** Laufwerksbezeichnungen.
.DriveNames		b PLAINTEXT
			b GOTOXY
			w $0040
			b $88
:DrvANm			s 18
			b GOTOXY
			w $0040
			b $90
:DrvBNm			s 18
			b GOTOXY
			w $0040
			b $98
:DrvCNm			s 18
			b GOTOXY
			w $0040
			b $a0
:DrvDNm			s 18
			b NULL

:DrvSD2IEC		b "SD2IEC",NULL

;*** Systemicons.
.Icon_OK		;$06 x $10
<MISSING_IMAGE_DATA>

.Icon_Abbruch		;$06 x $10
<MISSING_IMAGE_DATA>

.Icon_Slct		;$02 x $10
<MISSING_IMAGE_DATA>
