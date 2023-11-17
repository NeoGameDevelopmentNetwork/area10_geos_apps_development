; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Auswahl-Menü
;   r12H= $00 Einzel-Datei Auswahl.
;         $ff Multi -Datei Auswahl.
;   r13L= Länge der Datei-Namen.
;   r13H= Anzahl "ActionFiles" in Tabelle.
;   r14 = Zeiger auf Überschrift.
;   r15 = Zeiger auf Datei-Tabelle.
;Rückgabe: (Einzelauswahl)
;   r13L= $01 Klick auf OK, ohne Auswahl einer Datei.
;       = $00 Einzel-Datei Auswahl.
;         $ff Multi -Datei Auswahl.
;   r13H= Nummer des Eintrages in Datei-Tabelle
;   r14 = Zeiger auf Datei-Tabelle.
;   r15 = Zeiger auf Datei-Eintrag
;Rückgabe: (Multi-Dateiauswahl)
;   r13L= $00 Einzel-Datei Auswahl.
;         $ff Multi -Datei Auswahl.
;   r13H= Anzahl Dateien.
;   r15 = Tabelle mit ausgewählten Files

:BOX_Left		= 48
:BOX_Top		= 40
:ScrIcons_x		= (BOX_Left+8)   /8
:ScrIcons_y		= BOX_Top+11*8 +1
:TabXPos		= BOX_Left+16
:TabYPos		= BOX_Top+16
:TabRelPos		= SCREEN_BASE + TabYPos * 40 + TabXPos
:ColBoxTop		= (BOX_Top/8)*40 + BOX_Left/8

;*** Dialogbox aufrufen.
.DoScrTab		sta	r12H			;Auswahl-Modus.
			stx	r13L			;Datei-Namen-Länge..
			sty	r13H			;Anzahl ActionFiles.
			LoadW	r0,DlgBoxData
			ClrDlgBox:1
			lda	r13L
			ldx	r13H
::1			rts

;*** Dialogbox initialisieren.
:InitDlgBox		MoveB	r12H,V070a0		;Auswahl-Modus.
			MoveB	r13L,V070a1		;Datei-Namen-Länge..
			MoveB	r13H,V070a2		;Anzahl ActionFiles.
			MoveB	r14L, :1 +1		;Zeiger auf Titel.
			MoveB	r14H, :2 +1
			MoveW	r15 ,V070c0		;Zeiger auf Tabelle.

			jsr	i_FillRam
			w	32,SlctFileTab
			b	$00

;*** Dialogbox aufbauen.
			jsr	i_FillRam
			w	26,COLOR_MATRIX + ColBoxTop +1
			b	$61

			Display	ST_WR_FORE
			Pattern	1
			FillRec	BOX_Top,BOX_Top+7,BOX_Left+8,BOX_Left+215

			jsr	UseGDFont
			LoadW	r11,BOX_Left+16
			LoadB	r1H,BOX_Top +6
::1			lda	#$ff
			sta	r0L
::2			lda	#$ff
			sta	r0H
			jsr	PutString

			FrameRecTabYPos-3,TabYPos+66,TabXPos-8,TabXPos+135,%11111111

;*** Datei-Tabelle prüfen.
			jsr	TestFileTab		;Tabelle testen.
			LoadB	TabPos,0		;Zeiger auf ersten Eintrag.
			jsr	PrintTab		;Tabelle zeigen.

;*** Select-Icons aktivieren.
			ClrB	V070a4			;Voreinstellung: Keine Icons.
			ldx	MaxFile
			cpx	#$09			;Mehr als acht Einträge ?
			bcc	:4			;Nein, Keine Scroll-Icons.
			lda	#12			;Voreinstellung: Scroll-Icons.
			ldx	V070a0			;Mehr-Dateiauswahl ?
			beq	:3			;Nein, weiter.
			lda	#16			;Voreinstellung: Auswahl-Icons.
::3			sta	r2L
			LoadB	r2H,16
			LoadW	r0,icon_Slct
			LoadB	r1L,ScrIcons_x		;X-Koordinate der Scroll-Icons.
			LoadB	r1H,ScrIcons_y		;Y-Koordinate der Scroll-Icons.
			ClrB	r11L
			sec
			lda	#16
			sbc	r2L
			sta	r11H
			ClrW	r12
			lda	r2L
			lsr
			sta	V070a4			;Anzahl Icons merken (0,6 oder 8).
			jsr	BitmapClip		;Icon-Bitmap auf Bildschirm.

::4			lda	#$00
			sta	mouseData
			sta	pressFlag
			rts

;*** Datei-Liste überprüfen.
:TestFileTab		LoadB	MaxFile,0		;Anzahl Dateien auf 0.
			MoveW	V070c0,r0		;Anfang Daten-Tabelle nach ":r0".

			ldy	#$00
::1			lda	(r0L),y			;Auf Tabellen-Ende prüfen.
			beq	:3			;Ja, Ende erreicht.
			inc	MaxFile			;Anzahl Dateien erhöhen.
			CmpBI	MaxFile,255		;Mehr als 255 Files ?
			beq	:3			;Ja, Abbruch.
::2			AddVW	16,r0
			jmp	:1

::3			rts

;*** Zurück zum DeskTop
:L070Exit		lda	r0L
			bne	:1
			lda	#$02
::1			sta	sysDBData

;*** Bildschirm wiederherstellen.
			jsr	i_FillRam
			w	26,COLOR_MATRIX + ColBoxTop +1
			b	$b1

			Pattern	2
			FillRec	BOX_Top,BOX_Top+111+8,BOX_Left,BOX_Left+215+8

;*** Ergebnis auswerten.
			lda	sysDBData
			cmp	#$02
			beq	ExitToAppl
			bcs	GetBackCode

			lda	V070a0
			bne	GetBackCode

			LoadB	sysDBData,2		;Keine Auswahl, aber...
			lda	#$01			;klick auf OK.

;*** Rückgabewerte in Register und
;    zurück zur Applikation.
:ExitToAppl		sta	r13L
			stx	r13H
			jmp	RstrFrmDialogue

;*** Rückgabewerte ermitteln.
:GetBackCode		LoadB	sysDBData,1

			lda	V070a0
			bne	:3

			lda	V070e0			;Zeiger auf Eintrag bereitstellen.
			sta	r15L
			LoadB	r15H,0
			ldx	#r15L
			ldy	#$04
			jsr	DShiftLeft
			AddW	V070c0,r15
			MoveW	V070c0,r14

			lda	V070a0			;Rücksprung.
			ldx	V070e0			;Nr. des Eintrags.
			jmp	ExitToAppl

;*** Mehrfachauswahl: Tabelle erzeugen.
::3			lda	V070c0+0
			sta	r14L
			sta	r15L
			lda	V070c0+1
			sta	r14H
			sta	r15H

			lda	#$00
			sta	MaxFile
			sta	V070e0

::4			ldy	#$00			;Nicht gewählte
			lda	(r14L),y		;Dateien aus Tabelle löschen.
			bne	:5
			sta	(r15L),y
			MoveW	V070c0,r15

			lda	V070a0			;Rücksprung.
			ldx	MaxFile			;Anzahl Dateien.
			jmp	ExitToAppl		;Nr. des Eintrags.

::5			lda	V070e0			;Ist Datei ausgewählt ?
			jsr	PosToSlctFile
			and	BitMaske,y
			beq	:7			;Nein, überspringen.

			ldy	#$0f			;Eintrag umkopieren.
::6			lda	(r14L),y
			sta	(r15L),y
			dey
			bpl	:6
			AddVW	16,r15
			inc	MaxFile

::7			AddVW	16,r14			;Zeiger auf nächste Datei in Tabelle.
			inc	V070e0
			jmp	:4

;*** Datei/Scroll-Icons auswählen.
:ChkMseClick		lda	mouseData
			bpl	:2
::1			LoadB	pressFlag,0
			rts

::2			LoadB	r2L,TabYPos
			LoadB	r2H,TabYPos+ 63
			LoadW	r3 ,TabXPos
			LoadW	r4 ,TabXPos+127
			php
			sei
			jsr	IsMseInRegion
			plp
			tax
			beq	:3
			jmp	SelectFile

::3			LoadB	r2L,ScrIcons_y
			LoadB	r2H,ScrIcons_y   + 15
			LoadW	r3 ,ScrIcons_x*8
			LoadW	r4 ,ScrIcons_x*8 +127
			php
			sei
			jsr	IsMseInRegion
			plp
			tax
			beq	:4
			jmp	SelectIcon

::4			rts

;*** Datei auswählen.
:SelectFile		lda	mouseYPos
			sub	TabYPos
			lsr
			lsr
			lsr
			sta	:2 +1
			adda	TabPos
			cmp	MaxFile
			bcc	:1
			rts

::1			sta	V070e0
			sta	r0L
			LoadB	r0H,0
			ldx	#r0L
			ldy	#$04
			jsr	DShiftLeft
			AddW	V070c0,r0

			lda	V070e0
			jsr	PosToSlctFile
			eor	BitMaske,y
			sta	SlctFileTab,x

::2			lda	#$00
			jsr	PrintName

			lda	V070a0
			bne	:4

::3			LoadB	r0L,$ff
			jsr	:5
			jmp	L070Exit

::4			lda	V070a2
			beq	:5
			cmp	V070e0
			beq	:5
			bcc	:5
			LoadB	V070a0,0
			jmp	:3

::5			lda	mouseData
			bpl	:5
			LoadB	pressFlag,0
			rts

;*** Scoll-Icon auswählen.
:SelectIcon		MoveW	mouseXPos,r3
			SubVW	56,r3
			ldx	#r3L
			ldy	#$04
			jsr	DShiftRight
			lda	r3L
			cmp	V070a4
			bcc	:1
			rts

::1			pha
			ldx	#r3L
			ldy	#$04
			jsr	DShiftLeft
			AddVW	56,r3
			MoveW	r3,r4
			AddVW	15,r4

			lda	mouseYPos
			sub	1
			and	#%11110000
			sta	r2L
			inc	r2L
			ora	#%00001111
			sta	r2H
			inc	r2H

			jsr	SvIconPos
			pla
			asl
			tax
			lda	JumpAdr+0,x
			pha
			lda	JumpAdr+1,x
			tax
			pla
			jsr	CallRoutine
			jsr	LdIconPos

			rts

;*** Zeiger auf Zustands-Bit in Datei-Tabelle.
;    Für jeden Eintrag gibt es ein Bit,
;    welches anzeigt ob die Datei angewählt
;    ist oder nicht.
;    Bit = 1, Datei ist angewählt.
:PosToSlctFile		tay				;Zeiger auf Zustands-Bit für
			lsr				;aktuellen Eintrag berechnen.
			lsr
			lsr
			tax
			tya
			and	#%00000111
			tay				;Zeiger auf Bit im yReg.
			lda	SlctFileTab,x		;Zeiger innerhalb Tabelle im xReg.
			rts

;*** Tabelle ausgeben.
:PrintTab		MoveB	TabPos,r15L		;Zeiger auf den ersten Eintrag in der
			LoadB	r15H,0			;Tabelle berechnen und die nächsten
			ldx	#r15L			;8 Einträge ausgeben.
			ldy	#$04
			jsr	DShiftLeft
			AddW	V070c0,r15

			lda	#$00
::1			pha
			tax
			MoveW	r15,r0

			ldy	#$00
			lda	(r0L),y
			bne	:2
			pla
			rts

::2			txa
			jsr	PrintName
			AddVW	16,r15
			pla
			add	$01
			cmp	#$08
			bne	:1

			rts

;*** Name ausgeben.
:PrintName		sta	:1 +1			;Nr. relativ zu TabPos.
			asl				;(Also Position von 0-7).
			asl
			asl
			add	TabYPos+6
			sta	r1H			;Y-Koordinate berechnen.
			LoadW	r11,TabXPos		;X-Koordinate für Eintrag setzen.
			LoadB	currentMode,0		;Modus "NICHT ANGEWÄHLT".

::1			lda	#$00			;Nr. des Eintrages (absolut) berechnen.
			adda	TabPos
			sta	:1b +1

			ldx	V070a2			;Einzel-Datei-Auswahl ?
			beq	:1b			;Ja, weiter...

			cmp	V070a2
			bcs	:1a
			lda	#">"			;Action-Files markieren.
			b $2c
::1a			lda	#" "			;Normal-Files markieren.
			jsr	SmallPutChar
			lda	#" "
			jsr	SmallPutChar

::1b			lda	#$00			;Zustands-Bit für Eintrag einlesen.
			jsr	PosToSlctFile
			and	BitMaske,y
			beq	:1c			;-> Datei nicht angewählt.
			LoadB	currentMode,%00100000

::1c			lda	#$00			;Eintrag ausgeben.
::2			pha
			tay
			lda	(r0L),y
			bne	:3
			lda	#" "
::3			and	#$7f
			jsr	SmallPutChar
			pla
			add	$01
			cmp	V070a1
			bne	:2
::4			cmp	#$10
			beq	:5
			pha
			lda	#" "
			jsr	SmallPutChar
			pla
			add	$01
			jmp	:4

::5			rts

;*** Eine Datei vorwärts.
:NextFile		lda	TabPos
			add	$08
			cmp	MaxFile
			bcc	:1
			jmp	:3

::1			php
			sei
			ldy	#$00			;Tabellen-Daten (GRAFIK!) verschieben.
::2			lda	TabRelPos + 320,y
			sta	TabRelPos      ,y
			lda	TabRelPos + 640,y
			sta	TabRelPos + 320,y
			lda	TabRelPos + 960,y
			sta	TabRelPos + 640,y
			lda	TabRelPos +1280,y
			sta	TabRelPos + 960,y
			lda	TabRelPos +1600,y
			sta	TabRelPos +1280,y
			lda	TabRelPos +1920,y
			sta	TabRelPos +1600,y
			lda	TabRelPos +2240,y
			sta	TabRelPos +1920,y
			iny
			bpl	:2
			plp

			inc	TabPos

			clc
			lda	TabPos
			adc	#$07
			sta	r0L
			LoadB	r0H,0
			ldx	#r0L
			ldy	#$04
			jsr	DShiftLeft
			AddW	V070c0,r0
			lda	#$07			;Neuen Datei-Namen ausgeben.
			jsr	PrintName
			lda	mouseData		;Dauerfunktion ?
			bne	:3			;Nein, Ende...
			jmp	NextFile		;Ja, nochmal verschieben.

::3			ClrB	pressFlag
			rts

;*** Eine Datei zurück.
:LastFile		lda	TabPos
			bne	:1
			jmp	:3

::1			php
			sei
			ldy	#$00			;Tabellen-Daten (GRAFIK!) verschieben.
::2			lda	TabRelPos +1920,y
			sta	TabRelPos +2240,y
			lda	TabRelPos +1600,y
			sta	TabRelPos +1920,y
			lda	TabRelPos +1280,y
			sta	TabRelPos +1600,y
			lda	TabRelPos + 960,y
			sta	TabRelPos +1280,y
			lda	TabRelPos + 640,y
			sta	TabRelPos + 960,y
			lda	TabRelPos + 320,y
			sta	TabRelPos + 640,y
			lda	TabRelPos      ,y
			sta	TabRelPos + 320,y
			iny
			bpl	:2
			plp

			dec	TabPos

			lda	TabPos
			sta	r0L
			LoadB	r0H,0
			ldx	#r0L
			ldy	#$04
			jsr	DShiftLeft
			AddW	V070c0,r0
			lda	#$00			;Neuen Dateinamen ausgeben.
			jsr	PrintName
			lda	mouseData		;Dauerfunktion ?
			bne	:3			;Nein, Ende...
			jmp	LastFile

::3			ClrB	pressFlag
			rts

;*** Eine Seite vorwärts.
:NextPage		lda	TabPos
			clc
			adc	#$0f
			cmp	MaxFile
			bcc	:1
			jmp	EndPage_0

::1			clc
			lda	TabPos
			adc	#$08
			sta	TabPos
			jmp	PrintTab

;*** Eine Seite zurück.
:LastPage		lda	TabPos
			cmp	#$08
			bcs	:1
			jmp	TopPage_0

::1			sec
			lda	TabPos
			sbc	#$08
			sta	TabPos
			jmp	PrintTab

;*** Zum Anfang.
:TopPage
:TopPage_0		lda	#$00
			cmp	TabPos
			beq	:1
			sta	TabPos
			jsr	PrintTab
::1			rts

;*** Zum Ende.
:EndPage
:EndPage_0		sec
			lda	MaxFile
			sbc	#$08
			bcc	TopPage
			cmp	TabPos
			beq	:1
			sta	TabPos
			jsr	PrintTab
::1			rts

;*** Dateien abwählen.
:ReSelect		jsr	InitIconSlct

			lda	V070a2
::1			pha
			jsr	PosToSlctFile
			ora	BitMaske,y
			eor	BitMaske,y
			sta	SlctFileTab,x
			pla
			add	$01
			bne	:1
			jmp	PrintTab

;*** Dateien abwählen.
:AllSelect		jsr	InitIconSlct

			lda	V070a2
::1			pha
			jsr	PosToSlctFile
			ora	BitMaske,y
			sta	SlctFileTab,x
			pla
			add	$01
			bne	:1
			jmp	PrintTab

;*** Icon-Klic auf "Select" initialisieren.
:InitIconSlct		MoveW	V070a2,r0
			ldx	#r0L
			ldy	#$04
			jsr	DShiftLeft
			AddW	V070c0,r0
			rts

;*** Icon-Daten merken.
:SvIconPos		ldx	#$05
::1			lda	r2L,x
			sta	V070d0,x
			dex
			bpl	:1
			jmp	InvertRectangle

;*** Icon-Daten einlesen.
:LdIconPos		ldx	#$05
::1			lda	V070d0,x
			sta	r2L,x
			dex
			bpl	:1
			jmp	InvertRectangle

;*** Variablen.
:V070a0			b $00
:V070a1			b $00
:V070a2			b $00,$00
:V070a3			b $00
:V070a4			b $00				;max. Select-Icons.

:V070c0			w $0000				;Zeiger auf Tabelle.

:V070d0			s $06				;Icon-Daten für InvertRectangle
:V070e0			b $00				;Ausgewählte Datei

:TabPos			b $00
:MaxFile		b $00

:SlctFileTab		s 32				;32 Byte a 8 Bit = 256 Dateien.

:BitMaske		b $80,$40,$20,$10
			b $08,$04,$02,$01

:JumpAdr		w NextFile,LastFile
			w NextPage,LastPage
			w TopPage ,EndPage
			w ReSelect,AllSelect

;*** Dialogbox-Daten.
:DlgBoxData		b $01
			b 40,151
			w 48,263
			b DBUSRICON,  0,  0
			w iconData_Close
			b DBUSRICON, 20, 13
			w iconData_OK
			b DBUSRICON, 20, 88
			w iconData_Exit
			b DB_USR_ROUT
			w InitDlgBox
			b DBOPVEC
			w ChkMseClick
			b NULL

;*** Icon-Grafiken.
:iconData_Close		w	icon_Close
			b	BOX_Left/8,BOX_Top
			b	icon_Close_x,icon_Close_y
			w	L070Exit

:iconData_OK		w	icon_OK_a
			b	(BOX_Left+160)/8,BOX_Top+13
			b	icon_OK_a_x,icon_OK_a_y
			w	L070Exit

:icon_OK_a
<MISSING_IMAGE_DATA>
:icon_OK_a_x		= .x
:icon_OK_a_y		= .y

:iconData_Exit		w	icon_Abbruch
			b	(BOX_Left+160)/8,BOX_Top+88
			b	icon_Abbruch_x,icon_Abbruch_y
			w	L070Exit

:icon_Abbruch
<MISSING_IMAGE_DATA>
:icon_Abbruch_x		= .x
:icon_Abbruch_y		= .y

:icon_Slct
<MISSING_IMAGE_DATA>
:icon_Slct_x		= .x
:icon_Slct_y		= .y
