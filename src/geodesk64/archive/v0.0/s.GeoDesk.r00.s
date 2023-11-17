; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "WindowManager"
			t "G3_SymMacExt"

			f APPLICATION
			o $1000

:PREF_LINK_HEADER	= 1 +2 +2
:SIZE_LINK_ENTRY	= PREF_LINK_HEADER +64

:MAX_WINDOWS		= 16
:NO_MORE_WINDOWS	= $80
:NO_WIN_SELECT		= $81
:NO_LNK_SELECT		= $82
:WINDOW_CLOSED		= $83
:WINDOW_NOT_FOUND	= $84
:JOB_NOT_FOUND		= $85

:SCREEN_WIDTH		= $0140
:SCREEN_HIGHT		= $c8
:TASKBAR_HIGHT		= $10

:MAX_AREA_WIN_X		= SCREEN_WIDTH
:MAX_AREA_WIN_Y		= SCREEN_HIGHT - TASKBAR_HIGHT
:MIN_SIZE_WIN_X		= $0030
:MIN_SIZE_WIN_Y		= $0020

:MIN_AREA_BAR_Y		= SCREEN_HIGHT - TASKBAR_HIGHT
:MAX_AREA_BAR_Y		= SCREEN_HIGHT - 1
:MIN_AREA_BAR_X		= $0000
:MAX_AREA_BAR_X		= SCREEN_WIDTH - 1

:WIN_STD_POS_X		= $0020
:WIN_STD_POS_Y		= $10
:WIN_STD_SIZE_X		= $00e0
:WIN_STD_SIZE_Y		= $80

:BACK_COL_BASE		= BACK_SCR_BASE - 40*25

:MainInit		LoadB	dispBufferOn,ST_WR_FORE
			jsr	GetBackScreen

			jsr	InitTaskBar

			jsr	InitForWM
			jsr	DrawLinkTab
			rts

:InitTaskBar		lda	#$02
			jsr	SetPattern
			jsr	i_Rectangle
			b	MIN_AREA_BAR_Y,MAX_AREA_BAR_Y
			w	MIN_AREA_BAR_X,MAX_AREA_BAR_X
			lda	C_WinBack
			jsr	DirectColor

			LoadW	r0,IconTab1
			jmp	DoIcons

;*** Link-Datei ausgeben.
:DrawLinkTab		jsr	InitLinkTab
::51			jsr	DefLinkIconArea

			lda	#$01
			jsr	SetPattern
			jsr	Rectangle
			lda	#$07
			jsr	DirectColor

			lda	r15L
			clc
			adc	#< PREF_LINK_HEADER
			sta	r0L
			lda	r15H
			adc	#> PREF_LINK_HEADER
			sta	r0H

			jsr	WM_GET_ICONXY

			LoadB	r2L,3
			LoadB	r2H,21
			jsr	BitmapUp

			AddVBW	SIZE_LINK_ENTRY,r15

			dec	r14H
			bne	:51
			rts

;*** Mausklick auf Link-Eintrag ?
:TestSlctLink		php
			sei

			jsr	InitLinkTab
::51			jsr	DefLinkIconArea

			jsr	IsMseInRegion
			tax
			bne	:53

::52			AddVBW	SIZE_LINK_ENTRY,r15

			dec	r14H
			bne	:51

			plp

			lda	mouseOldVec +0
			ldx	mouseOldVec +1
			jmp	CallRoutine

::53			ldy	#$00
			lda	(r15L),y
			cmp	#$01
			bne	:52

			plp

			ldy	#$04
			lda	(r15L),y
			tax
			dey
			lda	(r15L),y
			jmp	CallRoutine

:InitLinkTab		LoadW	r15,LinkTab

			ldy	#$00
			lda	(r15L),y
			sta	r14H

			AddVBW	1,r15
			rts

:DefLinkIconArea	ldy	#$02
			lda	(r15L),y
			sta	r2L
			clc
			adc	#$17
			sta	r2H

			dey
			lda	(r15L),y
			asl
			asl
			asl
			sta	r3L
			lda	#$00
			rol
			sta	r3H

			lda	r3L
			clc
			adc	#$17
			sta	r4L
			lda	r3H
			adc	#$00
			sta	r4H
			rts

;*** Arbeitsplatz öffnen.
:OpenWorkPlace		jsr	WM_OPEN_WINDOW
			cpx	#NO_ERROR
			bne	:51
::51			rts

;*** Icon-Tabelle.
:IconTab1		b $01
			w $0000
			b $00

			w Icon_GEOS
			b MIN_AREA_BAR_X / 8
			b MIN_AREA_BAR_Y
			b Icon_GEOSx,Icon_GEOSy
			w EnterDeskTop

;*** Icons.
:Icon_GEOS
<MISSING_IMAGE_DATA>
:Icon_GEOSx		= .x
:Icon_GEOSy		= .y

;*** Verknüpfungen auf DeskTop.
;    b $01		= Direktaufruf in GeoDesk.
;    b x,y		= Position für Verknüpfung
;    w Adresse		= Einsprungsadresse.
;    j Icon		= $BF + 63 Byte für Icon-Daten.

:LinkTab		b $01				;Anzahl

			b $01				;Typ : $01 = Direktaufruf über JMP $xxxx
			b $01,$08			;Position.
			w OpenWorkPlace			;Routine für Direkteinsprung.

:Icon_01		j
<MISSING_IMAGE_DATA>

;******************************************************************************
;Ab hier folgt Code für Fenstermanager
;******************************************************************************

;*** FensterManager initialisieren.
;    Der FM klinkt sich hierbei direkt in die Mausabfrage ein und
;    kehrt danach erst zur eigentlichen Mausroutine zurück.
:InitForWM		MoveW	mouseVector,mouseOldVec
			LoadW	mouseVector,WM_ChkMouse
			rts

;*** FensterManager abschalten.
:DoneWithWM		MoveW	mouseOldVec,mouseVector
			rts

;*** Mausklick auswerten.
:WM_ChkMouse		lda	mouseData		;Mausbutton gedrückt ?
			bmi	:51			; => Nein, Ende...

			jsr	WM_FIND_WINDOW		;Fenster suchen.
			txa				;Wurde Fenster gefunden ?
			beq	:52			; => Ja, weiter...
::51			rts

::52			lda	WindowStack		;Nr. des obersten Fensters einlesen
			sta	WindowLastWin		;und zwisichenspeichern.

;--- DeskTop-Icons abfragen.
			lda	WindowStack,y		;Neues Fenster einlesen und
			sta	WM_WCODE		;nach oben kopieren.
			bne	:53
			jmp	WM_CALL_EXEC		;DeskTop aktivieren.

;--- Fenster-Icons abfragen.
::53			jsr	WM_WIN2TOP		;Fenster umsortieren.

			LoadW	r14,WM_TAB_WINFUNC
			LoadB	r15H,9
			jsr	WM_FIND_JOBS		;Icons auswerten.
			txa				;Wurde Fenster-Icon gewählt ?
			beq	:51			; => Ja, Ende...

;--- Wechsel zu anderem Fenster.
			lda	WindowLastWin
			cmp	WindowStack		;Wurde Fenster gewechselt ?
			beq	:51			; => Nein, Ende...

			jsr	WM_DRAW_NO_TOP		;Fenster unter aktuellem Fenster
			jsr	WM_SAVE_SCRN		;neu zeichnen und speichern.
			jmp	WM_DRAW_TOP_WIN		;Oberstes Fenster neu zeichnen.

;*** Aktuelles Fenster suchen.
:WM_FIND_WINDOW		php				;IRQ sperren.
			sei

			PushB	r15H			;Register ":r15" sichern.

			lda	#$00			;Fenster-Nr. löschen.
			sta	r15H

::51			ldx	#WINDOW_NOT_FOUND	;Fehlermeldung vorbereiten.

			ldy	r15H
			cpy	#MAX_WINDOWS		;Alle Fenster durchsucht ?
			beq	:53			; => Ja, Ende...
			lda	WindowStack,y		;Fenster-Nr. einlesen.
			bmi	:53			; => Ende erreicht...

			jsr	WM_GET_WIN_SIZE		;Fenstergröße einlesen.
			jsr	IsMseInRegion		;Mausposition abfragen.
			tax				;Ist Maus in Bereich ?
			bne	:52			; => Ja, Fenster gefunden.

			inc	r15H			;Zeiger auf nächstes Fenster und
			jmp	:51			;weitersuchen.

::52			ldx	#NO_ERROR		;Flag für "Kein Fehler" setzen und
			ldy	r15H			;Fenster-Nr. einlesen.

::53			PopB	r15H			;Register ":r15" zurücksetzen.
			plp
			rts

;*** Funktion: Gewähltes Fenster schließen.
:WM_FUNC_CLOSE		lda	WM_WCODE
			jsr	WM_CLOSE_WINDOW
			ldx	#NO_ERROR
			rts

;*** Funktion: Fenster maximieren.
:WM_FUNC_MAX		jsr	WM_SET_MAX_WIN
			jsr	WM_SET_WIN_SIZE
			jsr	WM_WIN_UPDATE
			ldx	#NO_ERROR
			rts

;*** Funktion: Standardgröße für Fenster setzen.
:WM_FUNC_STD		jsr	WM_SET_STD_WIN
			jsr	WM_SET_WIN_SIZE
			jsr	WM_WIN_UPDATE
			ldx	#NO_ERROR
			rts

;*** Funktion: Fenster nach unten verschieben.
:WM_FUNC_DOWN		lda	WindowOpenCount
			cmp	#$03
			bcc	:54

			ldx	#$00
			ldy	#$00
::51			lda	WindowStack ,x
			beq	:53
			cmp	WM_WCODE
			beq	:52
			sta	WindowStack ,y
			iny
::52			inx
			cpx	#MAX_WINDOWS
			bne	:51

::53			lda	WM_WCODE
			sta	WindowStack ,y
			jsr	WM_DRAW_ALL_WIN
::54			ldx	#NO_ERROR
			rts

;*** Fenstergröße setzen.
:WM_SET_MAX_WIN		ldy	#$00 +5
			b $2c
:WM_SET_STD_WIN		ldy	#$06 +5
			ldx	#$00 +5
::51			lda	WM_WIN_SIZE_TAB,y
			sta	r2L            ,x
			dey
			dex
			bpl	:51
			rts

;*** Fenstergröße ändern ?
:WM_FUNC_SIZE_UL	lda	#<WM_FJOB_SIZE_UL
			ldx	#>WM_FJOB_SIZE_UL
			jmp	WM_FUNC_RESIZE

:WM_FUNC_SIZE_UR	lda	#<WM_FJOB_SIZE_UR
			ldx	#>WM_FJOB_SIZE_UR
			jmp	WM_FUNC_RESIZE

:WM_FUNC_SIZE_DL	lda	#<WM_FJOB_SIZE_DL
			ldx	#>WM_FJOB_SIZE_DL
			jmp	WM_FUNC_RESIZE

:WM_FUNC_SIZE_DR	lda	#<WM_FJOB_SIZE_DR
			ldx	#>WM_FJOB_SIZE_DR

;*** Fenstergröße ändern.
:WM_FUNC_RESIZE		jsr	WM_EDIT_WIN
			jsr	WM_SET_WIN_SIZE
			jmp	WM_WIN_UPDATE

;*** Fenster verschieben.
:WM_FUNC_SIZE_MV	jsr	WM_GET_SLCT_SIZE

			MoveB	r2L,mouseYPos
			MoveW	r3 ,mouseXPos

			lda	r4L
			sec
			sbc	r3L
			sta	r13L
			lda	r4H
			sbc	r3H
			sta	r13H

			lda	r2H
			sec
			sbc	r2L
			sta	r14L

			lda	#<WM_FJOB_MOVE
			ldx	#>WM_FJOB_MOVE
			jsr	WM_EDIT_WIN

			jsr	WM_SET_CARD_XY
			MoveW	r3,r4
			AddW	r13,r4
			MoveB	r2L,r2H
			AddB	r14L,r2H
			jsr	WM_SET_WIN_SIZE

;*** Oberstes bzw. alle Fenster neu zeichnen.
:WM_WIN_UPDATE		lda	WindowLastWin
			cmp	WindowStack
			bne	WM_DRAW_ALL_WIN

			jsr	WM_LOAD_SCRN
			jmp	WM_DRAW_TOP_WIN

;*** Alle Fenster neu zeichnen.
:WM_DRAW_ALL_WIN	jsr	WM_DRAW_NO_TOP
			jsr	WM_SAVE_SCRN

;*** Aktuelles Fenster neu zeichnen.
:WM_DRAW_TOP_WIN	lda	WindowStack
			beq	:51
			sta	WM_WCODE
			jsr	WM_CALL_REDRAW
::51			ldx	#NO_ERROR
			rts

;*** Zeichen alle Fenster bis auf oberstes Fenster neu.
:WM_DRAW_NO_TOP		jsr	WindowClrArea
			jsr	DrawLinkTab

			lda	#MAX_WINDOWS -1
::53			pha
			tax
			lda	WindowStack,x
			beq	:54
			bmi	:54
			sta	WM_WCODE
			jsr	WM_CALL_REDRAW
::54			pla
			sec
			sbc	#$01
			bne	:53
			rts

;*** Aktuellen Job ermitteln.
;    Übergabe:		r14  = Zeiger auf Jobtabelle.
;			r15H = Anzahl Jobs.
:WM_FIND_JOBS		lda	#$00
			sta	r15L
::51			lda	r15L
			cmp	r15H
			beq	:54
			asl
			asl
			tay
			ldx	#$00
::52			lda	(r14L),y
			sta	r0L   ,x
			iny
			inx
			cpx	#$04
			bcc	:52

			lda	r0L
			ldx	r0H
			jsr	CallRoutine
			jsr	IsMseInRegion
			tax
			beq	:53

			lda	r1L
			ldx	r1H
			jmp	CallRoutine

::53			inc	r15L
			jmp	:51
::54			ldx	#JOB_NOT_FOUND
			rts

;*** Verschiebung möglich ?
:WM_FJOB_MOVE		jsr	WM_FJOB_TEST_MX
			jsr	WM_FJOB_TEST_MY

			lda	mouseXPos +0
			sta	r3L
			clc
			adc	r13L
			sta	r4L
			lda	mouseXPos +1
			sta	r3H
			adc	r13H
			sta	r4H

			lda	mouseYPos
			sta	r2L
			clc
			adc	r14L
			sta	r2H
			rts

;*** Verschiebung in Y-Richtung möglich ?
:WM_FJOB_TEST_MY	lda	mouseYPos
			clc
			adc	r14L
			cmp	#MAX_AREA_WIN_Y
			bcc	:51
			MoveB	r2L,mouseYPos
::51			rts

;*** Verschiebung in X-Richtung möglich ?
:WM_FJOB_TEST_MX	lda	mouseXPos +0
			clc
			adc	r13L
			tax
			lda	mouseXPos +1
			adc	r13H
			cmp	#> MAX_AREA_WIN_X
			bne	:51
			cpx	#< MAX_AREA_WIN_X
			bcc	:51
			MoveW	r3,mouseXPos
::51			rts

;*** Fenster nach links/oben vergrößern.
:WM_FJOB_SIZE_UL	jsr	WM_FJOB_TEST_Y0
			jsr	WM_FJOB_TEST_X0

::108			MoveW	mouseXPos,r3
			MoveB	mouseYPos,r2L
			rts

;*** Fenster nach rechts/oben vergrößern.
:WM_FJOB_SIZE_UR	jsr	WM_FJOB_TEST_Y0
			jsr	WM_FJOB_TEST_X1

::108			MoveW	mouseXPos,r4
			MoveB	mouseYPos,r2L
			rts

;*** Fenster nach links/unten vergrößern.
:WM_FJOB_SIZE_DL	jsr	WM_FJOB_TEST_Y1
			jsr	WM_FJOB_TEST_X0

::108			MoveW	mouseXPos,r3
			MoveB	mouseYPos,r2H
			rts

;*** Fenster nach rechts/unten vergrößern.
:WM_FJOB_SIZE_DR	jsr	WM_FJOB_TEST_Y1
			jsr	WM_FJOB_TEST_X1

::108			MoveW	mouseXPos,r4
			MoveB	mouseYPos,r2H
			rts

;*** Verkleinern nach oben möglich ?
:WM_FJOB_TEST_Y0	lda	r2H
			sec
			sbc	mouseYPos
			cmp	#MIN_SIZE_WIN_Y
			bcs	:101
			MoveB	r2L,mouseYPos
::101			rts

;*** Verkleinern nach unten möglich ?
:WM_FJOB_TEST_Y1	lda	mouseYPos
			sec
			sbc	r2L
			cmp	#MIN_SIZE_WIN_Y
			bcs	:101
			MoveB	r2H,mouseYPos
::101			rts

;*** Verkleinern nach rechts möglich ?
:WM_FJOB_TEST_X0	lda	r4L
			sec
			sbc	mouseXPos +0
			tax
			lda	r4H
			sbc	mouseXPos +1
			bne	:101
			cpx	#MIN_SIZE_WIN_X
			bcs	:101
			MoveW	r3 ,mouseXPos
::101			rts

;*** Verkleinern nach links möglich ?
:WM_FJOB_TEST_X1	lda	mouseXPos +0
			sec
			sbc	r3L
			tax
			lda	mouseXPos +1
			sbc	r3H
			bne	:101
			cpx	#MIN_SIZE_WIN_X
			bcs	:101
			MoveW	r4 ,mouseXPos
::101			rts

;*** Gewähltes Fenster vergrößern/verschieben.
;    Übergabe:		AKKU/XREG = Zeiger auf Test-Routine.
:WM_EDIT_WIN		sta	:106 +1
			stx	:106 +2

			php
			cli

			lda	WindowStack
			jsr	WM_GET_WIN_SIZE

			LoadB	mouseBottom,$b7

::104			jsr	WM_DRAW_FRAME

::105			lda	mouseData
			bmi	:110
			lda	inputData
			bmi	:105

			jsr	WM_DRAW_FRAME
::106			jsr	$ffff
			jmp	:104

::110			jsr	WM_DRAW_FRAME

			LoadB	pressFlag,$00
			LoadB	mouseBottom,$c7
			plp
			rts

;*** Neues Fenster öffnen.
;    Rückgabe:		xReg = $00, Kein Fehler.
;			AKKU = Fenster-Nr.
:WM_OPEN_WINDOW		ldy	WindowOpenCount
			cpy	#MAX_WINDOWS
			bcc	:51
			ldx	#NO_MORE_WINDOWS
			rts

::51			lda	#$01
::52			ldx	#$00
::53			cmp	WindowStack,x
			bne	:54
			clc
			adc	#$01
			cmp	#MAX_WINDOWS
			bcc	:52
			ldx	#NO_MORE_WINDOWS
			rts

::54			inx
			cpx	#MAX_WINDOWS
			bcc	:53

;--- Freie Fenster-Nr. gefunden.
			sta	WindowStack,y
			pha

			lda	WindowStack		;Fenster geöffnet ?
			beq	:55			; => Nein, weiter...
			sta	WM_WCODE		;Aktives Fenster als "inaktiv"
			jsr	SetNoMoveIcons		;kennzeichnen.

::55			pla
			sta	WM_WCODE
			jsr	WM_WIN2TOP

			inc	WindowOpenCount

			jsr	WM_SAVE_SCRN
			jsr	WM_DRAW_SLCT_WIN

			lda	WM_WCODE
			ldx	#NO_ERROR
			rts

;*** Fenster schließen.
;    Übergabe:		AKKU = Fenster-Nr.
:WM_CLOSE_WINDOW	sta	r15H

			ldx	#$00
			ldy	#$00
::51			lda	WindowStack ,x
			cmp	r15H
			beq	:52
			sta	WindowStack ,y
			iny
::52			inx
			cpx	#MAX_WINDOWS
			bne	:51
			cpy	#MAX_WINDOWS
			beq	:54
			dec	WindowOpenCount
			lda	#$ff
			sta	WindowStack ,y

::53			jmp	WM_DRAW_ALL_WIN
::54			rts

;*** Window nach oben holen.
;    Übergabe:		AKKU = Fenster-Nr.
:WM_WIN2TOP		sta	r15H

			ldx	#MAX_WINDOWS -1
			ldy	#MAX_WINDOWS -1
::51			lda	WindowStack ,x
			cmp	r15H
			beq	:52
			sta	WindowStack ,y
			dey
::52			dex
			bpl	:51
			lda	r15H
			sta	WindowStack
			rts

;*** Größe für aktuelles Fenster einlesen.
;    Übergabe:		":WM_WCODE" = Fenster-Nr.
:WM_GET_SLCT_SIZE	lda	WM_WCODE

;*** Größe für aktuelles Fenster einlesen.
;    Übergabe:		AKKU = Fenster-Nr.
:WM_GET_WIN_SIZE	asl
			sta	:51 +1
			asl
			clc
::51			adc	#$ff
			tay
			ldx	#$00
::52			lda	WindowData,y
			sta	r2L       ,x
			iny
			inx
			cpx	#$06
			bcc	:52
			rts

;*** Größe für aktuelles Fenster festlegen.
;    Übergabe:		":WM_WCODE" = Fenster-Nr.
:WM_SET_WIN_SIZE	jsr	WM_SET_CARD_XY
			lda	WM_WCODE
			asl
			sta	:51 +1
			asl
			clc
::51			adc	#$ff
			tay
			ldx	#$00
::52			lda	r2L       ,x
			sta	WindowData,y
			iny
			inx
			cpx	#$06
			bcc	:52
			rts

;*** Koordinaten auf CARDs umrechnen.
:WM_SET_CARD_XY		lda	r2L
			and	#%11111000
			sta	r2L

			lda	r2H
			ora	#%00000111
			sta	r2H

			lda	r3L
			and	#%11111000
			sta	r3L

			lda	r4L
			ora	#%00000111
			sta	r4L
			rts

;*** Zeiger auf Routine bei Mausklick auf Fenster setzen.
;    Übergabe:		AKKU = Fenster-Nr.
:WM_SET_ROUTINE		asl
			tax
			lda	r0L
			sta	WindowRoutDraw   +0,x
			lda	r0H
			sta	WindowRoutDraw   +1,x
			lda	r1L
			sta	WindowRoutReDraw +0,x
			lda	r1H
			sta	WindowRoutReDraw +1,x
			lda	r2L
			sta	WindowRoutExec   +0,x
			lda	r2H
			sta	WindowRoutExec   +1,x
			rts

;*** Fenster-Inhalt neu zeichnen.
;    Übergabe:		AKKU = Fenster-Nr.
:WM_CALL_DRAW		asl
			tay
			lda	WindowRoutDraw   +0,y
			ldx	WindowRoutDraw   +1,y
			jmp	CallRoutine

;*** Fenster-Inhalt zeichnen.
;    Übergabe:		AKKU = Fenster-Nr.
:WM_CALL_REDRAW		asl
			tay
			lda	WindowRoutReDraw +0,y
			ldx	WindowRoutReDraw +1,y
			jmp	CallRoutine

;*** Mausklick in Fenster auswerten.
;    Übergabe:		AKKU = Fenster-Nr.
:WM_CALL_EXEC		asl
			tay
			lda	WindowRoutExec   +0,y
			ldx	WindowRoutExec   +1,y
			jmp	CallRoutine

;*** Aktuellen Bildschirm-Inhalt in REU kopieren.
:WM_SAVE_SCRN		LoadW	r0,SCREEN_BASE
			LoadW	r1,BACK_SCR_BASE
			LoadW	r2,40*25*8 -40*2*8
			jsr	MoveData

			LoadW	r0,COLOR_MATRIX
			LoadW	r1,BACK_COL_BASE
			LoadW	r2,40*25   -40*2
			jmp	MoveData

;*** Aktuellen Bildschirm-Inhalt aus REU einlesen.
:WM_LOAD_SCRN		LoadW	r0,BACK_SCR_BASE
			LoadW	r1,SCREEN_BASE
			LoadW	r2,40*25*8 -40*2*8
			jsr	MoveData

			LoadW	r0,BACK_COL_BASE
			LoadW	r1,COLOR_MATRIX
			LoadW	r2,40*25   -40*2
			jmp	MoveData

;*** Alle Fenster löschen.
:WindowClrArea		lda	sysRAMFlg
			and	#%00001000		;Hintergrundbild aktiv ?
			beq	:51			; => Nein, weiter...

			lda	MP3_64K_SYSTEM
			sta	r3L
			LoadW	r0,COLOR_MATRIX
			LoadW	r1,R2_ADDR_BS_COLOR
			LoadW	r2,R2_SIZE_BS_COLOR -2*40
			jsr	FetchRAM
			LoadW	r0,SCREEN_BASE
			LoadW	r1,R2_ADDR_BS_GRAFX
			LoadW	r2,R2_SIZE_BS_GRAFX -2*40*8
			jmp	FetchRAM

::51			lda	BackScrPattern
			jsr	SetPattern
			jsr	WM_SET_MAX_WIN
			lda	C_GEOS_BACK
			jsr	DirectColor
			jmp	Rectangle

;*** Rahmen invertieren.
:WM_DRAW_FRAME		PushB	r2L
			PushB	r2H
			ldx	r2L
			inx
			stx	r2H
			jsr	InvertRectangle
			PopB	r2H
			tax
			dex
			stx	r2L
			jsr	InvertRectangle
			PopB	r2L

			PushW	r3
			PushW	r4
			MoveW	r3,r4
			jsr	InvertRectangle
			PopW	r4
			MoveW	r4,r3
			jsr	InvertRectangle
			PopW	r3
			rts

;*** Leeres Fenster zeichnen.
;    Übergabe:		":WM_WCODE" = Fenster-Nr.
:WM_DRAW_SLCT_WIN	jsr	WM_GET_SLCT_SIZE
			jsr	WM_DRAW_USER_WIN

			LoadW	r14,WM_SYS1ICON_TAB
			LoadB	r15H,4
			MoveB	C_WinIcon,r13H
			jsr	WM_DRAW_ICON_TAB

			lda	WindowStack
			cmp	WM_WCODE
			bne	SetNoMoveIcons

			LoadW	r14,WM_SYS2ICON_TAB
			LoadB	r15H,4
			MoveB	C_WinIcon,r13H
			jmp	WM_DRAW_ICON_TAB

:SetNoMoveIcons		LoadW	r14,WM_SYS3ICON_TAB
			LoadB	r15H,4
			MoveB	C_WinBack,r13H
			jmp	WM_DRAW_ICON_TAB

;*** Freies Fenster zeichnen.
;    Übergabe:		r2-r4 = Größe des Fensters.
:WM_DRAW_USER_WIN	PushB	r2L
			PushW	r3
			jsr	:51
			PopW	r3
			PopB	r2L
			rts

::51			lda	C_WinBack
			jsr	DirectColor
			lda	#$00
			jsr	SetPattern
			jsr	Rectangle

			lda	r2L
			pha
			lda	r2H
			pha

;--- Kopfzeile zeichnen.
			lda	r2L
			clc
			adc	#$07
			sta	r2H
			lda	C_WinTitel
			jsr	DirectColor

;--- Fußzeile zeichnen.
			pla
			sta	r2H
			sec
			sbc	#$07
			sta	r2L
			lda	#%11111111
			jsr	FrameRectangle

			pla
			clc
			adc	#$07
			sta	r2L

			lda	r4H
			pha
			lda	r4L
			pha

			jsr	:52

			pla
			sec
			sbc	#$07
			sta	r3L
			pla
			sbc	#$00
			sta	r3H

;--- Senkrechten Rahmen zeichnen.
::52			lda	r3L
			clc
			adc	#$07
			sta	r4L
			lda	r3H
			adc	#$00
			sta	r4H
			lda	#%11111111
			jmp	FrameRectangle

;*** Fenster-Icons darstellen.
;    Übergabe:		r14  = Zeiger auf Icon-Tabelle.
;			r15H = Anzahl Icons.
;			r13H = Farbe
:WM_DRAW_ICON_TAB	ldy	#$03
			lda	(r14L),y
			tax
			dey
			lda	(r14L),y
			jsr	CallRoutine

			lda	r13H
			jsr	DirectColor
			jsr	WM_GET_ICONXY

			ldy	#$00
			lda	(r14L),y
			sta	r0L
			iny
			lda	(r14L),y
			sta	r0H
			LoadB	r2L,Icon_MoveW
			LoadB	r2H,Icon_MoveH
			jsr	BitmapUp

			AddVBW	4,r14

			dec	r15H
			bne	WM_DRAW_ICON_TAB
			rts

;*** Rechteck-Koordinaten in ":BitmapUp"-Format konvertieren.
:WM_GET_ICONXY		lda	r3H			;X-Koordinate in CARDs
			lsr				;umrechnen.
			lda	r3L
			ror
			lsr
			lsr
			sta	r1L

			lda	r2L			;Y-Koordinate übernehmen.
			sta	r1H
			rts

;*** Bereiche für Fenster-Icons berechnen.
:WM_DEF_AREA_UL		lda	#$00
			b $2c
:WM_DEF_AREA_UR		lda	#$03
			b $2c
:WM_DEF_AREA_DL		lda	#$06
			b $2c
:WM_DEF_AREA_DR		lda	#$09
			b $2c
:WM_DEF_AREA_CL		lda	#$0c
			b $2c
:WM_DEF_AREA_MX		lda	#$0f
			b $2c
:WM_DEF_AREA_MN		lda	#$12
			b $2c
:WM_DEF_AREA_DN		lda	#$15
:WM_DEF_AREA		pha
			jsr	WM_GET_SLCT_SIZE
			pla
			tay

			lda	WM_DEFICON_TAB +0,y
			bmi	:52

			lda	r3L
			clc
			adc	WM_DEFICON_TAB +1,y
			sta	r3L
			bcc	:51
			inc	r3H
::51			jmp	:53

::52			lda	r4L
			sec
			sbc	WM_DEFICON_TAB +1,y
			sta	r3L
			lda	r4H
			sbc	#$00
			sta	r3H

::53			lda	r3L
			clc
			adc	#$07
			sta	r4L
			lda	r3H
			adc	#$00
			sta	r4H

::55			lda	WM_DEFICON_TAB +0,y
			and	#%01000000
			bne	:56

			lda	r2L
			clc
			adc	WM_DEFICON_TAB +2,y
			sta	r2L
			clc
			adc	#$07
			sta	r2H
			rts

::56			lda	r2H
			sec
			sbc	WM_DEFICON_TAB +2,y
			sta	r2L
			clc
			adc	#$07
			sta	r2H
			rts

;*** Bereich für Klick auf Titelzeile berechnen.
:WM_DEF_AREA_MV		jsr	WM_GET_SLCT_SIZE

			lda	r2L
			clc
			adc	#$07
			sta	r2H

			lda	r3L
			clc
			adc	#$10
			sta	r3L
			lda	r3H
			adc	#$00
			sta	r3H

			lda	r4L
			sec
			sbc	#$20
			sta	r4L
			lda	r4H
			sbc	#$00
			sta	r4H
			rts

;*** Variablen.
:mouseOldVec		w $0000

:WM_WIN_SIZE_TAB	b $00  ,MAX_AREA_WIN_Y -1
			w $0000,MAX_AREA_WIN_X -1
			b WIN_STD_POS_Y,WIN_STD_POS_Y + WIN_STD_SIZE_Y -1
			w WIN_STD_POS_X,WIN_STD_POS_X + WIN_STD_SIZE_X -1

:WindowStack		b $00,$ff,$ff,$ff,$ff,$ff,$ff,$ff
			b $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff

:WindowOpenCount	b $01
:WM_WCODE		b $00
:WindowLastWin		b $00

:WindowRoutExec		w TestSlctLink
			w $0000
			w $0000
			w $0000
			w $0000
			w $0000
			w $0000
			w $0000
			w $0000
			w $0000
			w $0000
			w $0000
			w $0000
			w $0000
			w $0000
			w $0000

:WindowRoutDraw		w WM_DRAW_ALL_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN

:WindowRoutReDraw	w WM_DRAW_ALL_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN
			w WM_DRAW_SLCT_WIN

:WindowData		b $00  ,SCREEN_HIGHT -1
			w $0000,SCREEN_WIDTH -1

			b WIN_STD_POS_Y +00*8,00*8+ WIN_STD_POS_Y +WIN_STD_SIZE_Y -1
			w WIN_STD_POS_X +00*8,00*8+ WIN_STD_POS_X +WIN_STD_SIZE_X -1

			b WIN_STD_POS_Y +01*8,01*8+ WIN_STD_POS_Y +WIN_STD_SIZE_Y -1
			w WIN_STD_POS_X +01*8,01*8+ WIN_STD_POS_X +WIN_STD_SIZE_X -1

			b WIN_STD_POS_Y +02*8,02*8+ WIN_STD_POS_Y +WIN_STD_SIZE_Y -1
			w WIN_STD_POS_X +02*8,02*8+ WIN_STD_POS_X +WIN_STD_SIZE_X -1

			b WIN_STD_POS_Y +03*8,03*8+ WIN_STD_POS_Y +WIN_STD_SIZE_Y -1
			w WIN_STD_POS_X +03*8,03*8+ WIN_STD_POS_X +WIN_STD_SIZE_X -1

			b WIN_STD_POS_Y +04*8,04*8+ WIN_STD_POS_Y +WIN_STD_SIZE_Y -1
			w WIN_STD_POS_X +04*8,04*8+ WIN_STD_POS_X +WIN_STD_SIZE_X -1

			b WIN_STD_POS_Y +00*8,00*8+ WIN_STD_POS_Y +WIN_STD_SIZE_Y -1
			w WIN_STD_POS_X +01*8,01*8+ WIN_STD_POS_X +WIN_STD_SIZE_X -1

			b WIN_STD_POS_Y +01*8,01*8+ WIN_STD_POS_Y +WIN_STD_SIZE_Y -1
			w WIN_STD_POS_X +02*8,02*8+ WIN_STD_POS_X +WIN_STD_SIZE_X -1

			b WIN_STD_POS_Y +02*8,02*8+ WIN_STD_POS_Y +WIN_STD_SIZE_Y -1
			w WIN_STD_POS_X +03*8,03*8+ WIN_STD_POS_X +WIN_STD_SIZE_X -1

			b WIN_STD_POS_Y +03*8,03*8+ WIN_STD_POS_Y +WIN_STD_SIZE_Y -1
			w WIN_STD_POS_X +04*8,04*8+ WIN_STD_POS_X +WIN_STD_SIZE_X -1

			b WIN_STD_POS_Y +04*8,04*8+ WIN_STD_POS_Y +WIN_STD_SIZE_Y -1
			w WIN_STD_POS_X +05*8,05*8+ WIN_STD_POS_X +WIN_STD_SIZE_X -1

			b WIN_STD_POS_Y +00*8,00*8+ WIN_STD_POS_Y +WIN_STD_SIZE_Y -1
			w WIN_STD_POS_X +02*8,02*8+ WIN_STD_POS_X +WIN_STD_SIZE_X -1

			b WIN_STD_POS_Y +01*8,01*8+ WIN_STD_POS_Y +WIN_STD_SIZE_Y -1
			w WIN_STD_POS_X +03*8,03*8+ WIN_STD_POS_X +WIN_STD_SIZE_X -1

			b WIN_STD_POS_Y +02*8,02*8+ WIN_STD_POS_Y +WIN_STD_SIZE_Y -1
			w WIN_STD_POS_X +04*8,04*8+ WIN_STD_POS_X +WIN_STD_SIZE_X -1

			b WIN_STD_POS_Y +03*8,03*8+ WIN_STD_POS_Y +WIN_STD_SIZE_Y -1
			w WIN_STD_POS_X +05*8,05*8+ WIN_STD_POS_X +WIN_STD_SIZE_X -1

			b WIN_STD_POS_Y +04*8,04*8+ WIN_STD_POS_Y +WIN_STD_SIZE_Y -1
			w WIN_STD_POS_X +06*8,06*8+ WIN_STD_POS_X +WIN_STD_SIZE_X -1

;*** Fensterfunktionen.
:WM_TAB_WINFUNC		w WM_DEF_AREA_CL
			w WM_FUNC_CLOSE

			w WM_DEF_AREA_MX
			w WM_FUNC_MAX

			w WM_DEF_AREA_MN
			w WM_FUNC_STD

			w WM_DEF_AREA_DN
			w WM_FUNC_DOWN

			w WM_DEF_AREA_UL
			w WM_FUNC_SIZE_UL

			w WM_DEF_AREA_UR
			w WM_FUNC_SIZE_UR

			w WM_DEF_AREA_DL
			w WM_FUNC_SIZE_DL

			w WM_DEF_AREA_DR
			w WM_FUNC_SIZE_DR

			w WM_DEF_AREA_MV
			w WM_FUNC_SIZE_MV

;*** Tabelle für Icon-Bereiche.
;    b $00!$00 = linke  obere  Ecke
;      $80!$00 = rechte obere  Ecke
;      $00!$40 = linke  untere Ecke
;      $80!$40 = rechte untere Ecke
;    b DeltaX
;    b DeltaY
:WM_DEFICON_TAB		b $00!$00,$00,$00		;Resize UL
			b $80!$00,$07,$00		;Resize UR
			b $00!$40,$00,$07		;Resize DL
			b $80!$40,$07,$07		;Resize DR
			b $00!$00,$08,$00		;Close
			b $80!$00,$0f,$00		;Maximize
			b $80!$00,$17,$00		;Standard
			b $80!$00,$1f,$00		;Move down.

;*** Angaben für Fenster-Icons.
:WM_SYS1ICON_TAB	w Icon_CL
			w WM_DEF_AREA_CL

			w Icon_MX
			w WM_DEF_AREA_MX

			w Icon_MN
			w WM_DEF_AREA_MN

			w Icon_DN
			w WM_DEF_AREA_DN

:WM_SYS2ICON_TAB	w Icon_UL
			w WM_DEF_AREA_UL

			w Icon_UR
			w WM_DEF_AREA_UR

			w Icon_DL
			w WM_DEF_AREA_DL

			w Icon_DR
			w WM_DEF_AREA_DR

:WM_SYS3ICON_TAB	w Icon_NM
			w WM_DEF_AREA_UL

			w Icon_NM
			w WM_DEF_AREA_UR

			w Icon_NM
			w WM_DEF_AREA_DL

			w Icon_NM
			w WM_DEF_AREA_DR

;*** Icons.
:Icon_MoveW		= 1
:Icon_MoveH		= 8

:Icon_UL
<MISSING_IMAGE_DATA>

:Icon_UR
<MISSING_IMAGE_DATA>

:Icon_DL
<MISSING_IMAGE_DATA>

:Icon_DR
<MISSING_IMAGE_DATA>

:Icon_NM
<MISSING_IMAGE_DATA>

:Icon_CL
<MISSING_IMAGE_DATA>

:Icon_MX
<MISSING_IMAGE_DATA>

:Icon_MN
<MISSING_IMAGE_DATA>

:Icon_DN
<MISSING_IMAGE_DATA>
