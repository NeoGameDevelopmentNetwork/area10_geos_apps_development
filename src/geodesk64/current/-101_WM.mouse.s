; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;Routine:   WM_CHK_MOUSE
;Parameter: -
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Mausklick auswerten.
;Hinweis:   Routine wird innerhalb der MainLoop ausgeführt!
;******************************************************************************
:WM_CHK_MOUSE		lda	mouseData		;Mausbutton gedrückt ?
			bmi	exit_MseKbd		; => Nein, Ende...

			jsr	WM_FIND_WINDOW		;Fenster suchen.
			txa				;Wurde Fenster gefunden ?
			bne	:callOldMseVec		; => Nein, Ende...

;--- Mausklick auf Fenster.
;ACHTUNG! YReg enthält Fenster-Nr.!
			sta	WM_TITEL_STATUS		;Rechtsklick/Titel löschen.

			jsr	getMseState		;Tastenstatus abfragen.
			jmp	WM_CHK_MSE_KBD		;Weiter zur Fensterabfrage.

;--- Weiter mit Original-Maus-Routine.
::callOldMseVec		lda	mouseOldVec +0		;Mausabfrage extern fortsetzen.
			ldx	mouseOldVec +1
			jmp	CallRoutine

;--- Maus/Tastatur-Abfrage beenden.
:exit_MseKbd		rts

;******************************************************************************
;Routine:   WM_CHK_KBD
;Parameter: -
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  sim. Mausklick auswerten.
;Hinweis:   Routine wird über die Tastaturabfrage aufgerufen!
;******************************************************************************
.WM_CHK_KBD		jsr	WM_FIND_WINDOW		;Fenster suchen.
			txa				;Wurde Fenster gefunden ?
			bne	exit_MseKbd		; => Nein, Ende...

			sta	WM_TITEL_STATUS		;Rechtsklick/Titel löschen.

			lda	#254			;Rechtsklick simulieren.
			sta	mseClkState

;--- Mausklick/Tastenklick auf Fenster.
;ACHTUNG! YReg enthält Fenster-Nr.!
:WM_CHK_MSE_KBD		lda	WM_STACK		;Nr. des obersten Fensters einlesen
			sta	mouseCurTopWin		;und zwisichenspeichern.

;--- Fenster-Daten einlesen.
			lda	WM_STACK,y		;Neue Fenster-Nr. einlesen und
			sta	WM_WCODE		;Fensterdaten kopieren.
			jsr	WM_LOAD_WIN_DATA

			lda	WM_WCODE		;Desktop ?
			beq	:win_select		; => Ja, keine Fenster-Icons.

			php
			sei				;Interrupt sperren.

			cmp	mouseCurTopWin		;Fenster bereits oben ?
			beq	:defMover

;--- Ergänzung: 09.05.21/M.Kanet
;Dateien im RAM in Cache speichern.
;Damit werden ggf. geänderte Dateien im
;Speicher für das vorherige Fenster
;im Cache aktualisiert.
			PushB	WM_WCODE
			lda	mouseCurTopWin
			sta	WM_WCODE
			jsr	SET_CACHE_DATA		;Zeiger auf Dateien im Cache.
			jsr	StashRAM		;Cache aktualisieren.
			PopB	WM_WCODE

			jsr	WM_WIN_BLOCKED		;Ist Ziel-Fenster durch andere
			txa				;Fenster verdeckt ?
			pha
			lda	WM_WCODE
			jsr	WM_WIN2TOP		;Fenster umsortieren.
			pla				;Ist Fenster verdeckt ?
			beq	:defMover		; => Nein, weiter...

			jsr	WM_LOAD_SCREEN		;Fenster aus ScreenBuffer laden.

;--- Ergänzung: 16.05.21/M.Kanet
;Verzeichnisdaten am Ende neu einlesen.
;Bei Fenster->Down werden sonst Daten
;eingelesen die später überholt sind.
;			jsr	WM_CALL_GETFILES	;Verzeichnisdaten einlesen.

;--- Scrollbalken aktualisieren.
::defMover		jsr	WM_DEF_MOVER_DAT	;Daten für Scrollbalken definieren.
;			jsr	WriteSB_Data
			jsr	WM_SCRBAR_INIT		;Scrollbalken initialisieren.

;--- Klick innerhalb Fenster ?
			jsr	WM_GET_SLCT_SIZE	;Fenstergröße ermitteln.

;--- Hinweis:
;Links nur 2Pixel abziehen, damit der
;Bereich für die Mehrfachauswahl von
;links nach rechts genutzt werden kann.
			AddVBW	2,r3			;Titelzeile, Statuszeile und
			SubVW	8,r4			;Rahmen links/rechts von der
			AddVB	8,r2L			;Fenstergröße abziehen.
			SubVB	8,r2H
			jsr	IsMseInRegion		;Klick auf Fensterinhalt prüfen.

			plp				;IRQ-Status zurücksetzen.

			tax				;Mausklick innerhalb Dateifenster ?
			bne	:win_select		; => Ja, Fenster angeklickt.

;--- Klick auf Fenster-Icons ?
::no_win_slct		lda	mseClkState
			cmp	#254			;Rechter Mausklick ?
			bne	:test_winfunc1		; => Nein, weiter...

			lda	mouseYPos
			cmp	r2L			;Mausklick auf Titelzeile?
			bcs	:test_winfunc1		; => Nein, weiter...

			jsr	WM_WAIT_NOMSEKEY	;Warten auf Maustaste...

			dec	WM_TITEL_STATUS		;Rechtsklick/Titel löschen.

::win_select		lda	WM_WCODE
			beq	:skip_update
			cmp	getFileWin
			beq	:skip_update
			jsr	WM_CALL_GETFILES	;Verzeichnisdaten einlesen.
::skip_update		jmp	doSelectWin		; => Ja, Fenster angeklickt.

;--- System-Icons Teil#1 testen.
::test_winfunc1		LoadW	r14,:tab1		;Tabelle mit Fenster-Funktionen.
			LoadB	r15H,10			;Anzahl Fenster-Funktionen.
			jsr	WM_FIND_JOBS		;Fenster-Funktion auswerten.
			txa				;Wurde Fenster-Funktion gewählt ?
			beq	:updateDirData		; => Ja, Ende...

;--- System-Icons Teil#2 testen.
::test_winfunc2		LoadW	r14,:tab2		;Tabelle mit ScrollBar-Icons.
			LoadB	r15H,3			;Anzahl Scrollbar-Icons.
			jsr	WM_FIND_JOBS		;ScrollBar-Icons auswerten.

;--- Verzeichnisdaten aktualisieren.
::updateDirData		lda	WM_WCODE		;Nr. des obersten Fensters einlesen.
			beq	:exit			; => Desktop, Ende...
			cmp	getFileWin		;Fenster gewechselt ?
			beq	:exit			; => Nein, weiter...
			jsr	WM_CALL_GETFILES	;Verzeichnisdaten einlesen.
::exit			rts

;*** Funktionen für Fenster-Icons.
::tab1			w WM_DEF_AREA_CL		;Fenster schließen.
			w WM_FUNC_CLOSE			;Dateien für TopWin werden geladen!

			w WM_DEF_AREA_DN		;Fenster nach unten.
			w WM_FUNC_DOWN			;Nur Fenster neu zeichnen!

			w WM_DEF_AREA_STD		;Fenster auf Standard-Größe.
			w WM_FUNC_STD			;Dateien für TopWin werden geladen!

			w WM_DEF_AREA_MN		;Fenstergröße zurücksetzen.
			w WM_FUNC_MIN			;Dateien für TopWin werden geladen!

			w WM_DEF_AREA_MX		;Fenster maximieren.
			w WM_FUNC_MAX			;Dateien für TopWin werden geladen!

			w WM_DEF_AREA_UL		;Fenster links/oben vergrößern.
			w WM_FUNC_SIZE_UL		;Dateien für TopWin werden geladen!

			w WM_DEF_AREA_UR		;Fenster rechts/oben vergrößern.
			w WM_FUNC_SIZE_UR		;Dateien für TopWin werden geladen!

			w WM_DEF_AREA_DL		;Fenster links/unten vergrößern.
			w WM_FUNC_SIZE_DL		;Dateien für TopWin werden geladen!

			w WM_DEF_AREA_DR		;Fenster rechts/unten vergrößern.
			w WM_FUNC_SIZE_DR		;Dateien für TopWin werden geladen!

			w WM_DEF_AREA_MV		;Fenster über Titelzeile schieben.
			w WM_FUNC_SIZE_MV		;Nur Fenster neu zeichnen!

;*** Funktionen für Scrollbalken.
::tab2			w WM_DEF_AREA_WUP		;Nach oben scrollen.
			w WM_FUNC_MOVE_UP		;Dateien für TopWin werden geladen!

			w WM_DEF_AREA_WDN		;Nach unten scrollen.
			w WM_FUNC_MOVE_DN		;Dateien für TopWin werden geladen!

			w WM_DEF_AREA_BAR		;Fensterbalken schieben.
			w WM_FUNC_MOVER			;Dateien für TopWin werden geladen!

;*** Variablen.
:mouseCurTopWin		b $00

;******************************************************************************
;Routine:   doSelectWin
;Parameter: -
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Mausklick auswerten.
;Hinweis:   Fenster angeklickt.
;           Linke Maustaste, Rechte Maustaste oder
;           Linke Maustaste+CBM testen.
; -> Aufruf nur durch ":WM_CHK_KBD".
;******************************************************************************
:doSelectWin		bit	shiftKeys		;Linke SHIFT-Taste+Maus gedrückt?
			bmi	:select_multi		; => Ja, Mehrfach-Dateiauswahl.

			lda	mseClkState		;Tasten-Status abfragen.
			beq	:no_mouse		; => Keine Maustaste, Ende...

			cmp	#207			;CBM + Linker Mausklick ?
			beq	:select_single		; => Ja, Einzel-Datei wählen.
			cmp	#253			;Linker Mausklick ?
			beq	:select_multi		; => Ja, Mehrfach-Dateiauswahl.
::skip_select		cmp	#254			;Rechter Mausklick ?
			bne	:test_desktop		; => Nein, weiter...

			jmp	WM_CALL_RIGHTCLK	;Mausklick auswerten.
::no_mouse		rts

;--- Klick auf DeskTop ?
::test_desktop		lda	WM_WCODE		;Klick auf DeskTop?
			beq	:call_window		; => Ja, auswerten...

;--- Wechsel zu anderem Fenster.
::no_desktop		jsr	WM_TEST_ENTRY		;Datei-Icon ausgewählt ?
			bcc	:no_icon_slct		; => Nein, weiter...
::call_window		jmp	WM_CALL_EXEC		;Datei-Klick auswerten.

::no_icon_slct		jsr	WM_TEST_MOVE		;Datei verschieben?
			bcc	:exit			; => Nein, kein Drag'n'Drop...

;--- Mehrfachauswahl.
::select_multi		ldx	WM_WCODE
			ldy	WIN_DATAMODE,x		;Partitionen oder DiskImages?
			bne	:exit			; => Ja, Keine Auswahl möglich.
			jmp	WM_CALL_MSLCT		; => Mehrfach-Auswahl.

;--- Einzelauswahl.
::select_single		ldx	WM_WCODE
			ldy	WIN_DATAMODE,x		;Partitionen oder DiskImages?
			bne	:exit			; => Ja, Keine Auswahl möglich.
			jmp	WM_CALL_SSLCT		; => Einzel-Auswahl.

;--- Kein SSLCT/MSLCT möglich, Ende.
::exit			rts

;******************************************************************************
;Routine:   getMseState
;Parameter: -
;Rückgabe:  mseClkState = 254 -> Rechte Maustaste.
;           shiftKeys   = 255 -> Linke Shift-Taste.
;Verändert: A
;Funktion:  Mausklick auswerten.
;******************************************************************************
:getMseState		php
			sei				;IRQ-Status speichern.
			lda	CPU_DATA
			pha
			lda	#$35			;I/O-Bereich aktivieren.
			sta	CPU_DATA

			lda	#$00			;Status für Maustasten und
			sta	mseClkState		;linke SHIFT-taste löschen.
			sta	shiftKeys

;--- Tastaturabfrage.
;Testen ob linke SHIFT-Taste gedrückt.
;Falls ja, dann führt das unter VICE im
;WARP-Modus dazu, das "duplizieren"
;erkannt wird: Drag`n`Drop mit SHIFT
;innerhalb des gleichen Fensters.
;Wenn linke SHIFT-Taste gedrückt, dann
;Mausklick ignorieren.
			lda	#%11111101		;Linke SHIFT-Taste abfragen.
			sta	CIA_PRA
			lda	CIA_PRB
			and	#%10000000		;Linke SHIFT-Taste gedrückt?
			bne	:1			; => Nein, weiter...
			dec	shiftKeys

::1			lda	#%01111111		;C= Taste abfragen.
			sta	CIA_PRA
			lda	CIA_PRB			;Tasten-Status abfragen.
;--- Hinweis:
;Damit im Textmodus über das Gummiband
;auch Dateien ausgewählt werden können
;wenn man direkt auf einen Dateieintrag
;klickt, muss man jetzt die SHIFT-Taste
;gedrückt halten. Daher Mausklick bei
;SHIFT-Taste nicht mehr ignorieren.
;			bit	shiftKeys		;Linke SHIFT-Taste gedrückt?
;			bmi	:2			; => Ja, Mausklick ignorieren.

			sta	mseClkState		;Maustasten speichern.

::2			pla
			sta	CPU_DATA		;I/O-Bereich ausblenden.
;			lda	mseClkState
			plp				;IRQ-Status zurücksetzen.
			rts

:mseClkState		b $00
:shiftKeys		b $00

;******************************************************************************
;Routine:   WM_WAIT_NOMSEKEY
;Parameter: -
;Rückgabe:  -
;Verändert: A
;Funktion:  Warten bis keine Maustaste gedrückt.
;******************************************************************************
.WM_WAIT_NOMSEKEY	lda	mouseData		;Maustaste gedrückt?
			bpl	WM_WAIT_NOMSEKEY	; => Ja, warten...
			ClrB	pressFlag		;Tastenstatus löschen.
			rts				;Ende.

;******************************************************************************
;Routine:   WM_FIND_JOBS
;Parameter: r14  = Zeiger auf Jobtabelle.
;           r15H = Anzahl Jobs.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Sucht Job für ausgewähltes System-Icon.
;******************************************************************************
:WM_FIND_JOBS		php
			sei

			lda	#$00			;Job-Zähler zurücksetzen.
			sta	r15L

::1			lda	r15L
			cmp	r15H			;Alle Jobs durchsucht?
			beq	:4			; => Ja, Abbruch...

			asl				;Daten für Icon einlesen.
			asl
			tay
			ldx	#$00
::2			lda	(r14L),y
			sta	r0L   ,x
			iny
			inx
			cpx	#$04
			bcc	:2

			lda	r0L			;Routine zum setzen der
			ldx	r0H			;Icon-Position/Größe aufrufen.
			jsr	CallRoutine
			jsr	IsMseInRegion
			tax				;Ist Mauszeiger auf Icon?
			beq	:3			; => Nein, weiter...

			plp				;IRQ-Status zurücksetzen.

			lda	r1L			;Job für Icon aufrufen.
			ldx	r1H
			jmp	CallRoutine

::3			inc	r15L			;Zähler auf nächstes Icon.
			jmp	:1

::4			ldx	#JOB_NOT_FOUND		;Fehler, Job nicht gefunden.

::5			plp				;IRQ-Status zurücksetzen.
			rts

;******************************************************************************
;Routine:   WM_FUNC_CLOSE
;Parameter: -
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Ausgewähltes Fenster schließen.
;******************************************************************************
:WM_FUNC_CLOSE		lda	WM_WCODE
			jsr	WM_CLOSE_WINDOW		;Fenster schließen.

;--- Ergänzung: 09.05.21/M.Kanet
;Wenn ein Fenster geschlossen wird,
;dann sind die Daten im RAM ungültig.
;Daher muss hier ":getFileWin" gelöscht
;werden um dann die Verzeichnisdaten
;für das neue Fenster einzulesen.
			lda	WM_WCODE		;Aktuelles Fenster = Desktop ?
			beq	:skip_getfiles		; => Ja, weiter...

			lda	#$00			;Verzeichnisdaten für aktuelles
			sta	getFileWin		;Fenster einlesen.
			jsr	WM_CALL_GETFILES

::skip_getfiles		ldx	#NO_ERROR
			rts

;******************************************************************************
;Routine:   WM_FUNC_MAX
;Parameter: -
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Ausgewähltes Fenster maximieren.
;******************************************************************************
:WM_FUNC_MAX		ldx	WM_WCODE
			lda	WMODE_MAXIMIZED,x
			bne	:1
			dec	WMODE_MAXIMIZED,x
			jsr	WM_UPDATE		;Obersetes Fenster neu zeichnen.
::1			ldx	#NO_ERROR
			rts

;******************************************************************************
;Routine:   WM_FUNC_MIN
;Parameter: -
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Ausgewähltes Fenster zurücksetzen.
;******************************************************************************
:WM_FUNC_MIN		ldx	WM_WCODE
			lda	WMODE_MAXIMIZED,x
			beq	:1
			inc	WMODE_MAXIMIZED,x
			jsr	WM_UPDATE		;Obersetes Fenster neu zeichnen.
::1			ldx	#NO_ERROR
			rts

;******************************************************************************
;Routine:   WM_FUNC_STD
;Parameter: -
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Ausgewähltes Fenster auf Standardgröße zurücksetzen.
;******************************************************************************
:WM_FUNC_STD		ldx	WM_WCODE		;"Maximiert"-Flag löschen.
			lda	#$00
			sta	WMODE_MAXIMIZED,x
			jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.
			jsr	WM_DEF_STD_WSIZE	;Standardgröße setzen.
			jsr	WM_SAVE_WIN_DATA	;Fensterdaten speichern.
			jsr	WM_UPDATE		;Obersetes Fenster neu zeichnen.
			ldx	#NO_ERROR
			rts

;******************************************************************************
;Routine:   WM_FUNC_DOWN
;Parameter: -
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Ausgewähltes Fenster nach unten verschieben.
;******************************************************************************
:WM_FUNC_DOWN		lda	WM_WCOUNT_OPEN
			cmp	#$03			;Nur 1 Fenster + Desktop?
			bcc	:4			; => Ja, Ende...

			ldx	#$00			;Fenster im Stack nach
			ldy	#$00			;unten verschieben.
::1			lda	WM_STACK ,x
			beq	:3
			cmp	WM_WCODE
			beq	:2
			sta	WM_STACK ,y
			iny
::2			inx
			cpx	#MAX_WINDOWS
			bne	:1

::3			lda	WM_WCODE		;Fenster-Nr. an letzte Stelle
			sta	WM_STACK ,y		;im Stack schreiben.

			jsr	WM_DRAW_ALL_WIN		;Alle Fenster aus ScreenBuffer
							;neu darstellen.

::4			ldx	#NO_ERROR
			rts

;******************************************************************************
;Routine:   WM_FUNC_SIZE_...
;Parameter: -
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Größe für ausgewähltes Fenster ändern.
;******************************************************************************
:WM_FUNC_SIZE_UL	lda	#<WM_FJOB_SIZE_UL
			ldx	#>WM_FJOB_SIZE_UL
			bne	WM_FUNC_RESIZE

:WM_FUNC_SIZE_UR	lda	#<WM_FJOB_SIZE_UR
			ldx	#>WM_FJOB_SIZE_UR
			bne	WM_FUNC_RESIZE

:WM_FUNC_SIZE_DL	lda	#<WM_FJOB_SIZE_DL
			ldx	#>WM_FJOB_SIZE_DL
			bne	WM_FUNC_RESIZE

:WM_FUNC_SIZE_DR	lda	#<WM_FJOB_SIZE_DR
			ldx	#>WM_FJOB_SIZE_DR

;*** Fenstergröße ändern.
:WM_FUNC_RESIZE		jsr	WM_EDIT_WIN		;Gummi-Band erzeugen.

			ldx	WM_WCODE		;"Maximiert"-Flag löschen.
			lda	#$00
			sta	WMODE_MAXIMIZED,x

			jsr	WM_SET_WIN_SIZE		;Neue Fenstergröße setzen.

			jmp	WM_UPDATE		;Aktuelles Fenster neu zeichnen.

;******************************************************************************
;Routine:   WM_FJOB_SIZE_...
;Parameter: -
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Gummi-Band vergrößern oder verkleinern.
;******************************************************************************
:WM_FJOB_SIZE_UL	jsr	WM_FJOB_TEST_Y0		;Nach oben...
			jsr	WM_FJOB_TEST_X0		;Nach links...

			MoveW	mouseXPos,r3
			MoveB	mouseYPos,r2L
			rts

:WM_FJOB_SIZE_UR	jsr	WM_FJOB_TEST_Y0		;Nach oben...
			jsr	WM_FJOB_TEST_X1		;Nach rechts...

			MoveW	mouseXPos,r4
			MoveB	mouseYPos,r2L
			rts

:WM_FJOB_SIZE_DL	jsr	WM_FJOB_TEST_Y1		;Nach unten...
			jsr	WM_FJOB_TEST_X0		;Nach links...

			MoveW	mouseXPos,r3
			MoveB	mouseYPos,r2H
			rts

:WM_FJOB_SIZE_DR	jsr	WM_FJOB_TEST_Y1		;Nach unten...
			jsr	WM_FJOB_TEST_X1		;Nach rechts...

			MoveW	mouseXPos,r4
			MoveB	mouseYPos,r2H
			rts

;******************************************************************************
;Routine:   WM_FJOB_TEST_...
;Parameter: -
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Prüfen ob Größenänderung möglich.
;           Falls nein, Maus-Position korrigieren.
;******************************************************************************
:WM_FJOB_TEST_Y0	lda	r2H
			sec
			sbc	mouseYPos
			bcc	:0
			cmp	#MIN_SIZE_WIN_Y 		;Nach oben möglich?
			bcs	:1			; => Ja, weiter...
::0			MoveB	r2L,mouseYPos		;Mausposition zurücksetzen.
::1			rts

:WM_FJOB_TEST_Y1	lda	mouseYPos
			sec
			sbc	r2L
			bcc	:0
			cmp	#MIN_SIZE_WIN_Y 		;Nach unten möglich?
			bcs	:1			; => Ja, weiter...
::0			MoveB	r2H,mouseYPos		;Mausposition zurücksetzen.
::1			rts

:WM_FJOB_TEST_X0	lda	r4L
			sec
			sbc	mouseXPos +0
			tax
			lda	r4H
			sbc	mouseXPos +1
			bcc	:0
			bne	:1
			cpx	#MIN_SIZE_WIN_X 		;Nach links möglich?
			bcs	:1			; => Ja, weiter...
::0			MoveW	r3 ,mouseXPos		;Mausposition zurücksetzen.
::1			rts

:WM_FJOB_TEST_X1	lda	mouseXPos +0
			sec
			sbc	r3L
			tax
			lda	mouseXPos +1
			sbc	r3H
			bcc	:0
			bne	:1
			cpx	#MIN_SIZE_WIN_X 		;Nach rechts möglich?
			bcs	:1			; => Ja, weiter...
::0			MoveW	r4 ,mouseXPos		;Mausposition zurücksetzen.
::1			rts

;******************************************************************************
;Routine:   WM_FUNC_SIZE_MV
;Parameter: -
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Fenster verschieben.
;******************************************************************************
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

			lda	#<WM_FJOB_TEST_MOV
			ldx	#>WM_FJOB_TEST_MOV
			jsr	WM_EDIT_WIN

			jsr	WM_SET_CARD_XY

			PushB	r2L
			PushW	r3
			PushW	r13
			PushB	r14L

			lda	r2L
			lsr
			lsr
			lsr
			pha
			lda	r3H
			lsr
			lda	r3L
			ror
			lsr
			lsr
			pha
			jsr	WM_DRAW_NO_TOP
			pla
			sta	DB_DELTA_X
			pla
			sta	DB_DELTA_Y

			jsr	WM_LOAD_SCREEN

			PopB	r14L
			PopW	r13
			PopW	r3
			PopB	r2L

			MoveW	r3  ,r4
			AddW	r13 ,r4
			MoveB	r2L ,r2H
			AddB	r14L,r2H
			jsr	WM_SET_WIN_SIZE		;Neue Fensterposition setzen.

			jsr	WM_DRAW_MOVER		;Scrollbalken aktualisieren.

			jmp	WM_SAVE_SCREEN		;Fenster in ScreenBuffer speichern.

;******************************************************************************
;Routine:   WM_FJOB_TEST_MOV
;Parameter: -
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Testen ob Fenster verschoben werden kann.
;           Wenn ja, dann neue X-/Y-Position für Gummi-Band setzen.
;******************************************************************************
:WM_FJOB_TEST_MOV	jsr	WM_FJOB_TEST_MX		;X-Verschieben testen.
			jsr	WM_FJOB_TEST_MY		;Y-Verschieben testen.

			lda	mouseXPos +0		;Neue Position für Gummi-Band
			sta	r3L			;berechnen.
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

;******************************************************************************
;Routine:   WM_FJOB_TEST_M...
;Parameter: -
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Testen ob Fenster verschoben werden kann.
;           Falls nein, Maus-Position korrigieren.
;******************************************************************************
:WM_FJOB_TEST_MY	lda	mouseYPos		;Mausposition einlesen.
			clc				;Fensterhöhe addieren.
			adc	r14L			;Größer als Bildschirm/Überlauf?
			bcs	:0			; => Ja, Mausposition zurücksetzen.
			cmp	#MAX_AREA_WIN_Y 		;Nach unten möglich?
			bcc	:1			; => Ja, weiter...
::0			MoveB	r2L,mouseYPos		;Mausposition zurücksetzen.
::1			rts

:WM_FJOB_TEST_MX	lda	mouseXPos +0		;Mausposition einlesen.
			clc				;Fensterbreite addieren.
			adc	r13L
			tax
			lda	mouseXPos +1
			adc	r13H			;Größer als Bildschirm/Überlauf?
			bcs	:0			; => Ja, Mausposition zurücksetzen.
			cmp	#> MAX_AREA_WIN_X
			bne	:1
			cpx	#< MAX_AREA_WIN_X 	;Nach rechts möglich?
			bcc	:1			; => Ja, weiter...
::0			MoveW	r3 ,mouseXPos		;Mausposition zurücksetzen.
::1			rts

;******************************************************************************
;Routine:   WM_EDIT_WIN
;Parameter: AKKU/XREG = Zeiger auf Test-Routine.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Gewähltes Fenster mit Gummi-Band vergrößern/verschieben.
;           Wenn ja, dann neue X-/Y-Position für Gummi-Band setzen.
;******************************************************************************
:WM_EDIT_WIN		sta	:3 +1			;Vektor auf Testroutine speichern.
			stx	:3 +2

			php
			cli				;Interrupt freigeben (Mausbewegung).

			lda	WM_STACK		;Fenstergröße einlesen.
			jsr	WM_GET_WIN_SIZE

			lda	#(SCRN_HEIGHT - TASKBAR_HEIGHT) -1
			sta	mouseBottom		;Untere Fenstergrenze setzen.

::1			jsr	WM_DRAW_FRAME		;Gummi-Band zeichnen.

::2			lda	mouseData		;Maustaste noch gedrückt?
			bmi	:4			; => Nein, Ende...
			lda	inputData		;Mauszeiger bewegt?
			bmi	:2			; => Nein, warten...

			jsr	WM_DRAW_FRAME		;Gummi-Band löschen.

::3			jsr	$ffff			;Neue Position möglich?
			jmp	:1			;Weiter mit Mausabfrage.

::4			jsr	WM_DRAW_FRAME		;Gummi-Band löschen.

			LoadB	pressFlag,$00		;Tastenstatus löschen.

			lda	#SCRN_HEIGHT -1
			sta	mouseBottom		;Untere Fenstergrenze setzen.

			plp				;IRQ-Status zurücksetzen.
			rts

;******************************************************************************
;Routine:   WM_FUNC_MOVE...
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Fensterinhalt nach oben/unten verschieben.
;******************************************************************************
.WM_FUNC_PAGE_DN	lda	WM_DATA_CURENTRY +0
			clc
			adc	WM_COUNT_ICON_XY
			sta	r0L
if MAXENTRY16BIT = TRUE
			lda	WM_DATA_CURENTRY +1
			adc	#$00
			sta	r0H
endif
			bcs	WM_FUNC_MOVE_END	;Zum Ende der Liste.
			jmp	MoveSBar2Page		;Seite vorwärts.

.WM_FUNC_PAGE_UP	lda	WM_DATA_CURENTRY +0
			sec
			sbc	WM_COUNT_ICON_XY
			sta	r0L
if MAXENTRY16BIT = TRUE
			lda	WM_DATA_CURENTRY +1
			sbc	#$00
			sta	r0H
endif
			bcc	WM_FUNC_MOVE_TOP	;Zum Anfang der Liste.
			jmp	MoveSBar2Page		;Seite zurück.

:WM_FUNC_MOVER		lda	#$7f			;Scrollbalken verschieben.
			b $2c
.WM_FUNC_MOVE_UP	lda	#$00			;Seite zurück.
			b $2c
.WM_FUNC_MOVE_DN	lda	#$ff			;Seite vorwärts.
			sta	WM_MOVE_MODE

			cmp	#$7f			;Scrollbalken verschieben?
			beq	MoveSBar2Pos		; => Ja, weiter...

			jsr	getMseState		;Tastatur abfragen.
			lda	mseClkState
			and	#%00100000		;CBM-Taste gedrückt?
			bne	MoveSBar2Pos		; => Nein, weiter...

			lda	WM_MOVE_MODE		;Zeiger auf ersten/letzten Eintrag.
			b $2c
.WM_FUNC_MOVE_TOP	lda	#$00			;Zum Anfang springen.
			b $2c
.WM_FUNC_MOVE_END	lda	#$ff			;Zum Ende springen.

			sta	r0L			;Fensterposition setzen.
if MAXENTRY16BIT = TRUE
			sta	r0H
endif
:MoveSBar2Page		jsr	WM_TEST_CUR_POS		;Neue Position überprüfen.

if MAXENTRY16BIT = TRUE
			lda	r0H
			cmp	WM_DATA_CURENTRY +1
			bne	:2
endif
			lda	r0L
			cmp	WM_DATA_CURENTRY +0
::2			beq	:1			;Position unverändert, Ende.

			jsr	WM_SET_NEW_POS		;Neue Position speichern.
			jsr	WM_MOVE_NEW_POS		;Fensterinhalt an Pos. ausgeben.
;			jsr	WM_DRAW_MOVER		;Scrollbalken aktualisieren.
			jsr	WM_SAVE_SCREEN		;Fenster in ScreenBuffer speichern.

::1			ldx	#NO_ERROR
			rts

;--- Fensterposition verschieben.
:MoveSBar2Pos		jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

::move			PushB	WM_DATA_CURENTRY	;Zähler auf aktuellen Eintrag
							;zwischenspeichern.
if MAXENTRY16BIT = TRUE
			PushB	WM_DATA_CURENTRY +1
endif

			jsr	WM_CALL_MOVE		;Fensterinhalt verschieben.

if MAXENTRY16BIT = TRUE
			PopB	r0H
endif
			PopB	r0L			;Zähler auf aktuellen Eintrag
							;zwischenspeichern.

			txa				;Fensterinhalt verschieben möglich?
			bne	:1a			; => Ja, weiter...

if MAXENTRY16BIT = TRUE
			lda	r0H
			cmp	WM_DATA_CURENTRY +1
			bne	:1
endif
			lda	r0L
			cmp	WM_DATA_CURENTRY +0
::1			beq	:2			;Inhalt nicht verändert, Ende...

			jsr	WM_MOVE_NEW_POS		;Fensterinhalt an Pos. ausgeben.

::1a			jsr	WM_DRAW_MOVER		;Scrollbalken aktualisieren.

			lda	GD_SLOWSCR		;Anzeige bremsen?
			bpl	:1b			; => Nein, weiter...
			jsr	SCPU_Pause
::1b			lda	mouseData		;Dauerfunktion ?
			bpl	:move			; => Ja, weiter...

::2			jsr	WM_SAVE_SCREEN		;Fenster in ScreenBuffer speichern.

			ldx	#NO_ERROR
			rts

;******************************************************************************
;Routine:   WM_MOVE_NEW_POS
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Fensterinhalt an Position ausgeben.
;******************************************************************************
:WM_MOVE_NEW_POS	jsr	WM_WIN_MARGIN		;Grenzen für Textausgabe setzen.

			MoveB	windowTop   ,r2L	;Grenzen als Fläche für
			MoveB	windowBottom,r2H	;Grafikroutine übernehmen.
			MoveW	leftMargin  ,r3
			MoveW	rightMargin ,r4

			jsr	WM_CLEAR_WINAREA	;Fensterbereich löschen.

			jmp	WM_CALL_DRAWROUT	;Fensterinhalt aktualisieren.

;******************************************************************************
;Routine:   WM_CALL_MSLCT
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Mehrfach-Dateiauswahl.
;Hinweis:   $0000 = Keine Auswahl möglich.
;           $FFFF = Standard-Auswahl.
;******************************************************************************
:WM_CALL_MSLCT		jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

			lda	WM_DATA_WINMSLCT +0
			ldx	WM_DATA_WINMSLCT +1
			cmp	#$ff			;Standard-Auswahlfunktion?
			bne	callExtSelect		; => Nein, externe Rotuine aufrufen.
			cpx	#$ff
			bne	callExtSelect
			jmp	WM_SLCT_MULTI		;Mehrere Dateien auswählen.

;******************************************************************************
;Routine:   WM_CALL_SSLCT
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Einzel-Dateiauswahl.
;Hinweis:   $0000 = Keine Auswahl möglich.
;           $FFFF = Standard-Auswahl.
;******************************************************************************
:WM_CALL_SSLCT		jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

			lda	WM_DATA_WINSSLCT +0
			ldx	WM_DATA_WINSSLCT +1
			cmp	#$ff			;Standard-Auswahlfunktion?
			bne	callExtSelect		; => Nein, externe Rotuine aufrufen.
			cpx	#$ff
			bne	callExtSelect
			jmp	WM_SLCT_SINGLE		;Eine Datei auswählen.

:callExtSelect		ldy	WM_WCODE		;Externe Routine Einzel-
			jmp	CallRoutine		;Auswahl aufrufen.

;******************************************************************************
;Routine:   WM_SLCT_SINGLE
;Parameter: WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Einzel-Dateiauswahl.
;******************************************************************************
:WM_SLCT_SINGLE		jsr	WM_TEST_ENTRY		;Eintrag mit der Maus ausgewählt?
			bcs	:1			; => Nein, weiter...
			rts

::1			stx	r14L			;Eintrag-Nr. speichern.
if MAXENTRY16BIT = TRUE
			sty	r14H
endif

			jsr	WM_INVERT_FILE		;Verzeichnis-Eintrag invertieren.
			jmp	UPDATE_WIN_DATA		;Fensterdaten speichern.

;******************************************************************************
;Routine:   WM_SLCT_MULTI
;Parameter: WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Mehrfach-Dateiauswahl.
;******************************************************************************
:WM_SLCT_MULTI		jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

			jsr	WM_GET_SLCT_AREA	;Auswahlrahmen erstellen.

			MoveB	r2L,SlctY0		;Größe Auswahlbereich speichern.
			MoveB	r2H,SlctY1
			MoveW	r3 ,SlctX0
			MoveW	r4 ,SlctX1
			MoveB	r5L,SlctMode		;Auswahl-Modus vollständig/kreuzen.

			;jsr	OpenWinDrive		;Laufwerk bereits aktiv...

			jsr	InitFPosData		;Daten für Ausgabe initialisieren.

if MAXENTRY16BIT = FALSE
			ldx	WM_DATA_MAXENTRY +0
endif
if MAXENTRY16BIT = TRUE
			lda	WM_DATA_MAXENTRY +0
			ora	WM_DATA_MAXENTRY +1
			tax				;Dateien vorhanden?
endif
			beq	:end_output		; => Nein, Ende...

::next_column		lda	CurXPos			;Aktuelle X-Position innerhalb
			cmp	MaxXPos			;des gültigen Bereichs?
			bcc	:3			; => Ja, weiter...

::reset_column		jsr	restColumnData		;Spaltendaten zurücksetzen.
			bcc	:next_row		; => Nächste Zeile, weiter...

::end_output		jmp	UPDATE_WIN_DATA		;Fensterdaten speichern.

::next_row		sta	CurYPos			;Neue Y-Position speichern.
			inc	CountY			;Zähler für Zeilen korrigieren.

			ldx	WM_DATA_ROW		;Anzahl Zeilen begrenzt?
			beq	:2b			; => Nein, weiter...
			cmp	WM_DATA_ROW		;Max. Anzahl Zeilen erreicht?
			bcs	:end_output		; => Ja, Ende...

::2b			lda	CurXPos
::3			jsr	setEntryData		;Daten für aktuellen Eintrag setzen.

			MoveB	CurEntry +0,r0L		;Zeiger auf aktuellen Eintrag.
if MAXENTRY16BIT = TRUE
			MoveB	CurEntry +1,r0H
endif

			lda	SlctMode
			bne	:9a
			jsr	WM_SIZE_ENTRY_S		;Größe Eintrag ermitteln.
			txa				;Eintrag anzeigen?
			beq	:4			; => Nein, weiter...
			bne	:9b

::9a			jsr	WM_SIZE_ENTRY_F		;Größe Eintrag ermitteln.
			txa				;Eintrag anzeigen?
			beq	:4			; => Nein, weiter...

::9b			pha
			jsr	WM_TEST_SELECT		;Eintrag ausgewählt?
			pla
			bcc	:3a			; => Nein, weiter...

			pha
;--- Hinweis:
;Beim Auswahlmodus links->rechts muss
;nur der Dateiname in der Auswahl sein,
;aber beim invertieren muss die ganze
;Zeile invertiert werden.
;Single-Click-Auswahl invertiert auch
;die ganze Zeile.
			lda	CurXPos
			jsr	setEntryData		;Daten für aktuellen Eintrag setzen.
			jsr	WM_SIZE_ENTRY_F		;Größe Eintrag ermitteln.
			jsr	WM_CONVERT_CARDS	;Pixel nach CARDs wandeln.
;----
			MoveB	CurEntry +0,r14L	;Eintrag-Nr. einlesen.
if MAXENTRY16BIT = TRUE
			MoveB	CurEntry +1,r14H
endif
			jsr	WM_INVERT_FILE		;Verzeichnis-Eintrag invertieren.
			pla

::3a			inc	CurEntry +0		;Zähler auf nächsten Eintrag.
if MAXENTRY16BIT = TRUE
			bne	:3b
			inc	CurEntry +1
endif

::3b			tax

::4
if MAXENTRY16BIT = TRUE
			lda	CurEntry +1
			cmp	WM_DATA_MAXENTRY +1
			bne	:4a
endif
			lda	CurEntry +0
			cmp	WM_DATA_MAXENTRY +0
::4a			bcs	:end_output		; => Weitere Einträge ausgeben.

			cpx	#$7f			;War Eintrag im sichtbaren Bereich?
			beq	:5a			; => Nein, Eintrag in nächster
							;    Zeile darstellen.

			jsr	setNextColumn		;X-Position für nächsten Eintrag.

			lda	WM_DATA_COLUMN		;Max. Anzahl Spalten definiert?
			beq	:5			; => Nein, weiter...
			lda	CountX
			cmp	WM_DATA_COLUMN		;Max. Anzahl Spalten erreicht?
			bcc	:5a			; => Nein, weiter...

::5			jmp	:next_column		;Nächste Spalte.
::5a			jmp	:reset_column		;Nächste Zeile.

;******************************************************************************
;Routine:   WM_GET_SLCT_AREA
;Parameter: -
;Rückgabe:  r2L-r4 = Gewählter Rahmenbereich.
;           r5L    = Markierungsmodus:
;                    $00 = Links nach rechts.
;                    $ff = Rechts nach Links.
;Verändert: A,X,Y,r2-r5L
;Funktion:  Größe für Auswahl-Rahmen berechnen.
;******************************************************************************
:WM_GET_SLCT_AREA	jsr	:SET_MOUSE_FRAME	;Rahmenposition setzen.

			lda	mouseXPos +0		;Aktuelle Mausposition speichern.
			sta	:ClickX   +0
			lda	mouseXPos +1
			sta	:ClickX   +1
			lda	mouseYPos
			sta	:ClickY

			AddVBW	8,mouseXPos		;Mindestgröße für Auswahl-Rahmen
			AddVB	8,mouseYPos		;Festlegen.

::1			MoveW	mouseXPos,:MouseX	;Zeiger auf Anfangs-Position
			MoveB	mouseYPos,:MouseY	;für Auswahl-Rahmen setzen.
			jsr	:SET_FRAME		;End-Position setzen.
			jsr	WM_DRAW_FRAME		;Auswahl-Rahmen zeichnen.

::2			lda	mouseData		;Maustaste noch gedrückt?
			bmi	:3			; => Nein, Ende...
			lda	inputData		;Mausbewegung?
			bmi	:2			; => Nein, warten...

			jsr	:SET_FRAME		;End-Position setzen.
			jsr	WM_DRAW_FRAME		;Auswahl-Rahmen löschen.
			jmp	:1

::3			jsr	:SET_FRAME		;End-Position setzen.
			jsr	WM_DRAW_FRAME		;Auswahl-Rahmen löschen.

;--- Auswahlmodus festlegen.
;Auswahl-Rahmen von links nach rechts:
;Einträge müssen vollständig innerhalb
;des Auswahl-Rahmens liegen.
			ldx	#$00			;Auswahlmodus "Vollständig".
			CmpW	:ClickX,:MouseX		;Maus < Anfangs-Position?
			bcc	:4			; => Ja, Ende...
;Auswahl-Rahmen von rechts nach links:
;Einträge müssen teilweise innerhalb
;des Auswahl-Rahmens liegen.
			dex				;Auswahlmodus "Kreuzen".
::4			stx	r5L			;Auswahlmodus speichern.
			jmp	WM_NO_MOUSE_WIN

;--- Rahmenposition setzen.
::SET_FRAME		CmpW	:MouseX,:ClickX
			bcs	:11
			MoveW	:MouseX,r3
			MoveW	:ClickX,r4
			jmp	:12

::11			MoveW	:ClickX,r3
			MoveW	:MouseX,r4

::12			CmpB	:MouseY,:ClickY
			bcs	:13
			MoveB	:MouseY,r2L
			MoveB	:ClickY,r2H
			jmp	:14

::13			MoveB	:ClickY,r2L
			MoveB	:MouseY,r2H
::14			rts

;--- Mausgrenzen setzen.
::SET_MOUSE_FRAME	lda	WM_WCODE		;Fenster-Größe einlesen.
			jsr	WM_GET_WIN_SIZE

			lda	r3L			;Linker Rand.
			clc
			adc	#$08
			sta	mouseLeft +0
			lda	r3H
			adc	#$00
			sta	mouseLeft +1

			lda	r4L			;Rechter Rand.
			sec
			sbc	#$08
			sta	mouseRight +0
			lda	r4H
			sbc	#$00
			sta	mouseRight +1

			lda	r2L			;Oberer Rand.
			clc
			adc	#$08
			sta	mouseTop

			lda	r2H			;Unterer Rand.
			sec
			sbc	#$08
			sta	mouseBottom
			rts

;--- Variablen.
::ClickX		w $0000
::ClickY		b $00
::MouseX		w $0000
::MouseY		b $00

;******************************************************************************
;Routine:   WM_TEST_SELECT
;Parameter: SlctMode = Auswahlmodus.
;                      $00 = Links->Rechts.
;                      $FF = Rechts->Links.
;           r2L = Y-Position/oben für Auswahlfenster.
;           r2H = Y-Position/unten für Auswahlfenster.
;           r3  = X-Position/links für Auswahlfenster.
;           r4  = X-Position/rechts für Auswahlfenster.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Mehrfach-Dateiauswahl: Prüfen ob Eintrag im Fenster.
;           Dabei wird unterschieden zwischen der Auswahl von
;           Links->Rechts und Rechts->Links:
;           Links->Rechts: Eintrag muss komplett im Rahmen sein.
;           Rechts->links: Eintrag muss teilweise im Rahmen sein.
;******************************************************************************
:WM_TEST_SELECT		jsr	WM_CONVERT_CARDS	;Pixel nach CARDs wandeln.

			CmpB	r2L,SlctY1		;Y-Position teilweise in Auswahl?
			bcs	:not_selected		; => Nein, ignorieren.
			CmpB	r2H,SlctY0
			bcc	:not_selected

			bit	SlctMode		;Auswahl-Modus testen.
			bmi	:1			;Auswahl Rechts->Links, weiter...

			CmpB	r2L,SlctY0		;Y-Position komplett in Auswahl?
			bcc	:not_selected		; => Nein, ignorieren.
			CmpB	r2H,SlctY1
			bcs	:not_selected

::1			CmpW	r3 ,SlctX1		;X-Position teilweise in Auswahl?
			bcs	:not_selected		; => Nein, ignorieren.
			CmpW	r4 ,SlctX0
			bcc	:not_selected

			bit	SlctMode		;Auswahl-Modus testen.
			bmi	:selected		;Auswahl Rechts->Links, weiter...

			CmpW	r3 ,SlctX0		;X-Position komplett in Auswahl?
			bcc	:not_selected		; => Nein, ignorieren.
			CmpW	r4 ,SlctX1
			bcs	:not_selected

;--- Datei gewählt.
::selected		sec
			rts

;--- Nicht gewählt.
::not_selected		clc
			rts

;******************************************************************************
;Routine:   WM_INVERT_FILE
;Parameter: WM_WCODE = Fenster-Nr.
;           r2L = Y-Koordinate für Eintrag/oben.
;           r2H = Y-Koordinate für Eintrag/unten.
;           r3  = X-Koordinate für Eintrag/links.
;           r4  = X-Koordinate für Eintrag/rechts.
;           r14 = Eintrag-Nr.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Eintrag invertieren wenn innerhalb Auswahlbereich.
;******************************************************************************
:WM_INVERT_FILE		MoveB	r14L,r15L
if MAXENTRY16BIT = TRUE
			MoveB	r14H,r15H
endif
			ldx	#r15L
			jsr	SET_POS_RAM		;Zeiger auf Eintrag berechnen.

			ldy	#$02
			lda	(r15L),y		;Dateityp-byte einlesen.
			cmp	#GD_MORE_FILES		;"Weitere Dateien"?
			beq	:5			; => Ja, nicht auswählen...

			CmpW	r4,rightMargin		;Rechte Grenze innerhalb Bildschirm?
			bcc	:1			; => Ja, weiter...
			MoveW	rightMargin,r4		;Rechte Grenze setzen.

::1			CmpB	r2H,windowBottom	;Untere Grenze innerhalb Bildschirm?
			bcc	:2			; => Ja, weiter...
			MoveB	windowBottom,r2H	;Untere Grenze setzen.

::2			jsr	InvertRectangle		;Bereich invertieren.

			jsr	WM_SLCTMODE		;Datei aus-/abwählen.

			ldx	WM_WCODE		;Fenster-Nr. einlesen.
			lda	r4L			;Icon ausgewählt?
			bne	:4			; => Ja, weiter...

if MAXENTRY16BIT = TRUE
			lda	WMODE_SLCT_L,x		;Anzahl ausgewählte Dateien -1.
			bne	:3
			dec	WMODE_SLCT_H,x
endif
::3			dec	WMODE_SLCT_L,x
			rts

::4			inc	WMODE_SLCT_L,x		;Anzahl ausgewählte Dateien +1.
if MAXENTRY16BIT = TRUE
			bne	:5
			inc	WMODE_SLCT_H,x
endif
::5			rts

;******************************************************************************
;Routine:   WM_SWITCH_FSLCT
;Parameter: r14 = Eintrag-Nr.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Datei im Speicher aus-/abwählen und am Bildschirm invertieren.
;******************************************************************************
.WM_FMODE_SELECT	ldx	#GD_MODE_SELECT
			b $2c
.WM_FMODE_UNSLCT	ldx	#GD_MODE_UNSLCT

			PushW	r0			;r0 zwischenspeichern.

			txa				;Markierungsmodus zwischenspeichern.
			pha

			jsr	WM_SET_ENTRY		;Eintrag im Fenster suchen.
			bcc	:1			; => Nicht gefunden, weiter...

			pla				;Markierungsmodus wieder einlesen.

			ldy	#$00			;Ist die aktuelle Datei bereits
			cmp	(r0L),y			;entsprechend markiert?
			beq	:1			; => Ja, weiter...

			jsr	WM_INVERT_FILE		;Verzeichnis-Eintrag invertieren.
			jsr	WM_SAVE_SCREEN		;ScreenBuffer aktualisiseren.

::1			PopW	r0			;r0 zurücksetzen.
			rts

;******************************************************************************
;Routine:   WM_SLCTMODE
;Parameter: r14 = Eintrag-Nr.
;           r15 = Zeiger auf Verzeichnis-Eintrag im Speicher.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Ändert Status "Datei ausgewählt" und speichert
;           neuen Status im Speicher/Cache.
;******************************************************************************
:WM_SLCTMODE		ldy	#$00
			lda	(r15L),y		;Status "Datei ausgewählt" umkehren.
			eor	#GD_MODE_MASK
			sta	(r15L),y
			sta	r4L

			jsr	SET_POS_CACHE		;Zeiger auf Eintrag im Cache.
			bcc	:exit			; => Kein Cache, Ende...

			LoadW	r0 ,r4
			MoveW	r14,r1
			LoadW	r2 ,1
			MoveB	r12H,r3L		;Speicherbank wird durch
							;":SET_POS_CACHE" gesetzt.
			jmp	StashRAM

::exit			rts

;******************************************************************************
;Routine:   WM_SIZE_ENTRY_F(ULL)/S(HORT)
;Parameter: WM_WCODE = Fenster-Nr.
;           r1L = X-Position für Ausgabe (CARDs).
;           r1H = Y-Position für Ausgabe (Pixel).
;           r2L = Max. X-Position für Ausgabe (CARDs).
;           r2H = Max. Y-Position für Ausgabe (Pixel).
;           r3L = X-Abstand (CARDs).
;           r3H = Y-Abstand (Pixel).
;Rückgabe:  r2L = Breite für Eintrag (CARDs).
;           r2H = Höhe für Eintrag (Pixel).
;           XREG = $00 => Eintrag nicht anzeigen.
;                  $7F => Eintrag in nächster Zeile anzeigen.
;                  $FF => Eintrag anzeigen.
;Verändert: A,X,Y,r0-r15
;Funktion:  Definiert Größe für Eintrag bei Datei-Auswahl.
;           WM_SIZE_ENTRY_F:
;           Im Infomodus ist die Breite = Ganze Zeile.
;           WM_SIZE_ENTRY_S:
;           Im Infomodus ist die Breite = Dateiname.
;******************************************************************************
:WM_SIZE_ENTRY_F	ldy	#$00			;Breite Info-Modus = Ganze Zeile.
			b $2c

:WM_SIZE_ENTRY_S	ldy	#$ff			;Breite Info-Modus = Dateiname.

			ldx	WM_WCODE
			lda	WMODE_VICON,x		;Icon-Modus?
			bne	:textMode		; => Nein, weiter...

;--- Icon-Modus.
::iconMode		jsr	WM_TEST_ENTRY_X		;Eintrag noch innerhalb der Zeile?
			bcc	:1			; => Ja, weiter...
;			beq	:1			; => Ja, weiter...

			ldx	#$00			;Eintrag nicht anzeigen.
			rts

::1			AddVB	3,r1L

			LoadB	r2L,$03			;Größe für Eintrag setzen.
			LoadB	r2H,$15			;Icon = 3CARDs breit, 21 Pixel hoch.

			ldx	#$ff			;Eintrag anzeigen.
			rts

;--- Text-Modus.
::textMode		ldx	WM_WCODE
			lda	WMODE_VINFO,x		;Details anzeigen?
			bne	:infoMode		; => Ja, weiter...

			jsr	WM_TEST_ENTRY_X		;Eintrag noch innerhalb der Zeile?
			bcc	:2			; => Ja, weiter...
;			beq	:2			; => Ja, weiter...

			ldx	#$00			;Eintrag nicht anzeigen.
			rts

::2			jsr	WM_GET_GRID_X		;Größe für Eintrag setzen.
			sta	r2L
			jsr	WM_GET_GRID_Y
			sta	r2H

			ldx	#$ff			;Eintrag anzeigen.
			rts

;--- Info-Modus.
::infoMode		tya				;Breiten-Modus abfragen.
			bne	:infoModeSmall		; => Nur Dateiname.

			lda	r2L			;Größe für ganze Zeile setzen.
			sec
			sbc	r1L
			jmp	:infoModeSet

::infoModeSmall		jsr	WM_GET_GRID_X		;Größe für Dateiname setzen.

::infoModeSet		sta	r2L			;Breite für Eintrag speichern.
			jsr	WM_GET_GRID_Y		;Höhe Eintrag ermitteln.
			sta	r2H

			ldx	#$7f			;Eintrag in nächster Zeile zeigen.
			rts

;******************************************************************************
;Routine:   WM_TEST_ENTRY_X
;Parameter: r1L = X-Position für Ausgabe.
;           r2L = Max. X-Position für Ausgabe.
;           r3L = X-Abstand.
;Rückgabe:  C-FLAG=0 Eintrag innerhalb Zeile.
;Verändert: A
;Funktion:  Prüft ob ein Eintrag (Icon oder Text) komplett innerhalb der
;           aktuellen zeile noch angezeigt werden kann.
;******************************************************************************
.WM_TEST_ENTRY_X	lda	r1L			;X-Position in CARDs.
			clc
			adc	r3L			;Breite in CARDs addieren.
			cmp	r2L			;Eintrag noch innerhalb der Zeile?
			rts

;******************************************************************************
;Routine:   WM_TEST_ENTRY
;Parameter: WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe:  r1L = X-Position für Ausgabe (CARDS).
;           r1H = Y-Position für Ausgabe (Pixel).
;           r2L = Max. X-Position für Ausgabe (CARDS).
;           r2H = Max. Y-Position für Ausgabe (Pixel).
;           r3L = X-Abstand (CARDS).
;           r3H = Y-Abstand (Pixel).
;           C-Flag=0  = Nichts ausgewählt.
;           XREG/YREG = Eintrag-Nr.
;Verändert: A,X,Y,r0-r5
;Funktion:  Prüft ob ein Eintrag mit der Maus angeklickt wurde.
;******************************************************************************
.WM_TEST_ENTRY		lda	#<IsMseInRegion		;Zeiger auf Testroutine.
			ldx	#>IsMseInRegion		;IsMseInRegion testet Mauszeiger.
			jsr	doEntryCheck		;Maus in Bereich?
			bcc	:1			; => Nein, weiter...

			ldx	CurEntry +0		;Eintrag-Nr. einlesen.
if MAXENTRY16BIT = TRUE
			ldy	CurEntry +1
endif
;			sec				;Eintrag ausgewählt.
::1			rts

;******************************************************************************
;Routine:   WM_SET_ENTRY
;Parameter: r14 = Nr. des gesuchten Eintrages.
;Rückgabe:  r1L = X-Position für Ausgabe (CARDS).
;           r1H = Y-Position für Ausgabe (Pixel).
;           r2L = Max. X-Position für Ausgabe (CARDS).
;           r2H = Max. Y-Position für Ausgabe (Pixel).
;           r3L = X-Abstand (CARDS).
;           r3H = Y-Abstand (Pixel).
;           C-Flag=0 = Nicht gefunden bzw. nicht sichtbar.
;Verändert: A,X,Y,r0-r5
;Funktion:  Berechnet Position für Icon in Fenster.
;******************************************************************************
:WM_SET_ENTRY		lda	#<:test_entry		;Zeiger auf Testroutine.
			ldx	#>:test_entry		;Prüft auf Eintrag-Nr.
			jsr	doEntryCheck		;Eintrag gefunden/sichtbar?
;			bcc	:1			; => Nein, weiter...
;			sec				;Eintrag-Nr. gefunden/sichtbar.
::1			rts

::test_entry
if MAXENTRY16BIT = TRUE
			lda	r14H			;Aktueller Eintrag=Sucheintrag?
			cmp	CurEntry +1
			bne	:1a
endif
			lda	r14L
			cmp	CurEntry +0
::1a			bne	:_false			; => Nein, weiter...
			lda	#$ff			;Eintrag gefunden.
			b $2c
::_false		lda	#$00			;Eintrag nicht gefunden.
			rts

;******************************************************************************
;Routine:   doEntryCheck
;Parameter: r5  = Zeiger auf Testroutine.
;                 Routine gibt AKKU=$FF zurück wenn TRUE.
;Rückgabe:  r1L = X-Position für Ausgabe (CARDS).
;           r1H = Y-Position für Ausgabe (Pixel).
;           r2L = Max. X-Position für Ausgabe (CARDS).
;           r2H = Max. Y-Position für Ausgabe (Pixel).
;           r3L = X-Abstand (CARDS).
;           r3H = Y-Abstand (Pixel).
;           C-Flag=0 = Nicht gefunden bzw. nicht sichtbar.
;Verändert: A,X,Y,r2-r5
;Funktion:  Sucht Eintrag im Fenster.
;           Wird von ":WM_TEST_ENTRY" und ":WM_SET_ENTRY" verwendet.
;******************************************************************************
:doEntryCheck		sta	r5L			;Zeiger auf Testroutine speichern.
			stx	r5H

if MAXENTRY16BIT = FALSE
			ldx	WM_DATA_MAXENTRY +0
endif
if MAXENTRY16BIT = TRUE
			lda	WM_DATA_MAXENTRY +0
			ora	WM_DATA_MAXENTRY +1
			tax				;Dateien vorhanden?
endif
			beq	:22			; => Nein, Ende...

			php
			sei				;Interrupt sperren.

			jsr	InitFPosData		;Daten für Ausgabe initialisieren.

;--- Nächsten Eintrag testen.
::10			lda	CurXPos			;Aktuelle X-Position innerhalb
			cmp	MaxXPos			;des gültigen Bereichs?
			bcc	:33			; => Ja, weiter...

;--- Spalte zurücksetzen.
::11			jsr	restColumnData		;Spaltendaten zurücksetzen.
			bcc	:31			; => Nächste Zeile, weiter...
							; => Keine weitere Zeile, Ende.
::21			plp
::22			clc				;Nicht gefunden, Ende.
			rts

;--- Nächste Zeile.
::31			sta	CurYPos			;Neue Y-Position speichern.
			inc	CountY			;Zähler für Zeilen korrigieren.

			ldx	WM_DATA_ROW		;Anzahl Zeilen begrenzt?
			beq	:32			; => Nein, weiter...
			cmp	WM_DATA_ROW		;Max. Anzahl Zeilen erreicht?
			bcs	:21			; => Ja, Ende...

::32			lda	CurXPos			;Aktuelle X-Position setzen.
::33			jsr	setEntryData		;Daten für aktuellen Eintrag setzen.

			jsr	WM_SIZE_ENTRY_F		;Größe Eintrag ermitteln.
			txa				;Eintrag sichtbar?
			beq	:42			; => Nein, weiter...

			pha

			jsr	WM_CONVERT_CARDS	;Position in CARDs umwandeln.

			lda	r5L
			ldx	r5H
			jsr	CallRoutine		;Gesuchter Eintrag gefunden?
			tay				;Ergebnis speichern.

			pla				;Zeilen-Status wieder einlesen.
			tax

			tya				;Eintrag gefunden?
			beq	:41			; => Nein, weiter...

			plp				;IRQ-Status zurücksetzen.
			sec				;Eintrag gefunden.
			rts

::41			inc	CurEntry +0		;Zähler auf nächsten Eintrag.
if MAXENTRY16BIT = TRUE
			bne	:42
			inc	CurEntry +1
endif

::42
if MAXENTRY16BIT = TRUE
			lda	CurEntry +1
			cmp	WM_DATA_MAXENTRY +1
			bne	:42a
endif
			lda	CurEntry +0
			cmp	WM_DATA_MAXENTRY +0
::42a			bcs	:21			; => Weitere Einträge ausgeben.

			cpx	#$7f			;War Eintrag im sichtbaren Bereich?
			beq	:52			; => Nein, weiter mit Eintrag in
							;    nächster Zeile.

			jsr	setNextColumn		;X-Position für nächsten Eintrag.

			lda	WM_DATA_COLUMN		;Max. Anzahl Spalten definiert?
			beq	:51			; => Nein, weiter...
			lda	CountX
			cmp	WM_DATA_COLUMN		;Max. Anzahl Spalten erreicht?
			bcc	:52			; => Nein, weiter...

::51			jmp	:10			;Nächste Spalte.
::52			jmp	:11			;Nächste Zeile.

;*** Variablen für Dateiauswahl/Dateianzeige.
:CurXPos		b $00
:CurYPos		b $00
:MinXPos		b $00
:MaxXPos		b $00
:MinYPos		b $00
:MaxYPos		b $00
if MAXENTRY16BIT = FALSE
:CurEntry		b $00
endif
if MAXENTRY16BIT = TRUE
:CurEntry		w $0000
endif
:CurGridX		b $00
:CurGridY		b $00
:CountX			b $00
:CountY			b $00
:SlctY0			b $00
:SlctY1			b $00
:SlctX0			w $0000
:SlctX1			w $0000
:SlctMode		b $00
