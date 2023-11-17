; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
;Routine  : WM_CHK_MOUSE
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Mausklick auswerten.
;Hinweis  : Routine wird innerhalb der MainLoop ausgeführt!
;
:WM_CHK_MOUSE		lda	mouseData		;Mausbutton gedrückt ?
			bmi	exit_MseKbd		; => Nein, Ende...

			bit	GD_HIDEWIN_MODE		;Fenster ausgeblendet?
			bpl	:1			; => Nein, weiter...

			ldy	WM_WCOUNT_OPEN		;Fenster-Nr. für DeskTop
			dey				;berechnen.
			lda	#$00			;Kein Klick auf Fenster-Titel.
			jmp	:do_click		; => Mausklick ausführen.

::1			jsr	WM_FIND_WINDOW		;Fenster suchen.
			txa				;Wurde Fenster gefunden ?
			bne	:callOldMseVec		; => Nein, Ende...

;--- Mausklick auf Fenster.
;ACHTUNG! YReg enthält Fenster-Nr.!
::do_click		sta	WM_TITEL_STATUS		;Rechtsklick/Titel löschen.

			jsr	getMseState		;Tastenstatus abfragen.
			jmp	WM_CHK_MSE_KBD		;Weiter zur Fensterabfrage.

;--- Weiter mit Original-Maus-Routine.
::callOldMseVec		lda	mouseOldVec +0		;Mausabfrage extern fortsetzen.
			ldx	mouseOldVec +1
			jmp	CallRoutine

;--- Maus/Tastatur-Abfrage beenden.
:exit_MseKbd		rts

;
;Routine  : WM_CHK_KBD
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : sim. Mausklick auswerten.
;Hinweis  : Routine wird über die Tastaturabfrage aufgerufen!
;
.WM_CHK_KBD		jsr	WM_FIND_WINDOW		;Fenster suchen.
			txa				;Wurde Fenster gefunden ?
			bne	exit_MseKbd		; => Nein, Ende...

			sta	WM_TITEL_STATUS		;Rechtsklick/Titel löschen.

			lda	#254			;Rechtsklick simulieren.
			sta	mseClkState

;--- Mausklick/Tastenklick auf Fenster.
;ACHTUNG! YReg enthält Fenster-Nr.!
:WM_CHK_MSE_KBD		lda	WM_WCODE		;Nr. des aktiven Fensters einlesen
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
			lda	r3L			;Titelzeile, Statuszeile und
			clc				;Rahmen links/rechts von der
			adc	#2			;Fenstergröße abziehen.
			sta	r3L
			bcc	:add1
			inc	r3H

::add1			lda	r4L
			sec
			sbc	#8
			sta	r4L
			bcs	:sub1
			dec	r4H

::sub1			lda	r2L
			clc
			adc	#8
			sta	r2L

			lda	r2H
			sec
			sbc	#8
			sta	r2H

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

			jsr	waitNoMseKey		;Warten auf Maustaste...

			dec	WM_TITEL_STATUS		;Rechtsklick/Titel löschen.

::win_select		jsr	:updateDirData		;Verzeichnisdaten einlesen.
::skip_update		jmp	doSelectWin		; => Ja, Fenster angeklickt.

;--- System-Icons Teil#1 testen.
::test_winfunc1		lda	#< :tab1		;Tabelle mit Fenster-Funktionen.
			sta	r14L
			lda	#> :tab1
			sta	r14H
			lda	#10			;Anzahl Fenster-Funktionen.
			sta	r15H
			jsr	WM_FIND_JOBS		;Fenster-Funktion auswerten.
			txa				;Wurde Fenster-Funktion gewählt ?
			beq	:updateDirData		; => Ja, Ende...

;--- System-Icons Teil#2 testen.
::test_winfunc2		lda	#< :tab2		;Tabelle mit ScrollBar-Icons.
			sta	r14L
			lda	#> :tab2
			sta	r14H
			lda	#3			;Anzahl Scrollbar-Icons.
			sta	r15H
			jsr	WM_FIND_JOBS		;ScrollBar-Icons auswerten.

;--- Verzeichnisdaten aktualisieren.
::updateDirData		lda	WM_WCODE		;Nr. des obersten Fensters einlesen.
			beq	:exit			; => Desktop, Ende...

			cmp	mouseCurTopWin		;Fenster bereits aktiv?
			beq	:getfiles		; => Ja, weiter...

			jsr	WM_OPEN_DRIVE		;Laufwerk öffnen.

::getfiles		jsr	WM_CALL_GETFILES	;Verzeichnisdaten einlesen.
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

;
;Routine  : doSelectWin
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Mausklick auswerten.
;Hinweis  : Fenster angeklickt.
;           Linke Maustaste, Rechte Maustaste oder
;           Linke Maustaste+CBM testen.
; -> Aufruf nur durch ":WM_CHK_KBD".
;
:doSelectWin		bit	shiftKeys		;Linke SHIFT-Taste+Maus gedrückt?
			bmi	:select_multi		; => Ja, Mehrfach-Dateiauswahl.

			lda	mseClkState		;Tasten-Status abfragen.
;--- Hinweis:
;:getMseState setzt mseClkState immer
;auf einen Wert >0.
;			beq	:no_mouse		; => Keine Maustaste, Ende...

			cmp	#207			;CBM + Linker Mausklick ?
			beq	:select_single		; => Ja, Einzel-Datei wählen.
			cmp	#222			;CBM + Rechter Mausklick ?
			beq	:right_button		; => Ja, weiter...
			cmp	#253			;Linker Mausklick ?
			beq	:select_multi		; => Ja, Mehrfach-Dateiauswahl.
			cmp	#254			;Rechter Mausklick Titelzeile ?
			bne	:test_desktop		; => Nein, weiter...

::right_button		jmp	WM_CALL_RIGHTCLK	;Mausklick auswerten.
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
::select_multi		jmp	WM_CALL_MSLCT		; => Mehrfach-Auswahl.

;--- Einzelauswahl.
::select_single		jmp	WM_CALL_SSLCT		; => Einzel-Auswahl.

;--- Kein SSLCT/MSLCT möglich, Ende.
::exit			rts

;
;Routine  : getMseState
;Parameter: -
;Rückgabe : mseClkState = 254 -> Rechte Maustaste.
;           shiftKeys   = 255 -> Linke Shift-Taste.
;Verändert: A
;Funktion : Mausklick auswerten.
;
:getMseState		php
			sei				;IRQ-Status speichern.
			lda	CPU_DATA
			pha
			lda	#$35			;I/O-Bereich aktivieren.
			sta	CPU_DATA

			lda	#$00			;Status linke SHIFT-Taste löschen.
			sta	shiftKeys
;			sta	mseClkState		;Maustasten speichern.

;--- Tastaturabfrage.
;Testen ob linke SHIFT-Taste gedrückt.
;Falls ja, dann führt das unter VICE im
;WARP-Modus dazu, das "duplizieren"
;erkannt wird: Drag`n`Drop mit SHIFT
;innerhalb des gleichen Fensters.
;Wenn linke SHIFT-Taste gedrückt, dann
;Mausklick ignorieren.
			lda	#%11111101		;Linke SHIFT-Taste abfragen.
			sta	cia1base +0
			lda	cia1base +1
			and	#%10000000		;Linke SHIFT-Taste gedrückt?
			bne	:1			; => Nein, weiter...
			dec	shiftKeys

::1			lda	#%01111111		;C= Taste abfragen.
			sta	cia1base +0
			lda	cia1base +1		;Tasten-Status abfragen.
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
			plp				;IRQ-Status zurücksetzen.
			rts

:mseClkState		b $00
:shiftKeys		b $00

;
;Routine  : WM_FIND_JOBS
;Parameter: r14  = Zeiger auf Jobtabelle.
;           r15H = Anzahl Jobs.
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Sucht Job für ausgewähltes System-Icon.
;
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

;
;Routine  : WM_FUNC_CLOSE
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Ausgewähltes Fenster schließen.
;
:WM_FUNC_CLOSE		lda	WM_WCODE
			jsr	WM_CLOSE_WINDOW		;Fenster schließen.

			lda	WM_WCODE		;Aktuelles Fenster = Desktop ?
			beq	:skip_getfiles		; => Ja, weiter...

			jsr	WM_CALL_GETFILES	;Verzeichnisdaten einlesen.

::skip_getfiles		ldx	#NO_ERROR
			rts

;
;Routine  : WM_FUNC_MAX
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Ausgewähltes Fenster maximieren.
;
:WM_FUNC_MAX		ldx	WM_WCODE
			lda	WMODE_MAXIMIZED,x
			bne	:1
			dec	WMODE_MAXIMIZED,x
			jsr	WM_UPDATE		;Obersetes Fenster neu zeichnen.
::1			ldx	#NO_ERROR
			rts

;
;Routine  : WM_FUNC_MIN
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Ausgewähltes Fenster zurücksetzen.
;
:WM_FUNC_MIN		ldx	WM_WCODE
			lda	WMODE_MAXIMIZED,x
			beq	:1
			inc	WMODE_MAXIMIZED,x
			jsr	WM_UPDATE		;Obersetes Fenster neu zeichnen.
::1			ldx	#NO_ERROR
			rts

;
;Routine  : WM_FUNC_STD
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Ausgewähltes Fenster auf Standardgröße zurücksetzen.
;
:WM_FUNC_STD		ldx	WM_WCODE		;"Maximiert"-Flag löschen.
			lda	#$00
			sta	WMODE_MAXIMIZED,x
			jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.
			jsr	WM_DEF_STD_WSIZE	;Standardgröße setzen.
			jsr	WM_SAVE_WIN_DATA	;Fensterdaten speichern.
			jsr	WM_UPDATE		;Obersetes Fenster neu zeichnen.
			ldx	#NO_ERROR
			rts

;
;Routine  : WM_FUNC_DOWN
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Ausgewähltes Fenster nach unten verschieben.
;
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

;
;Routine  : WM_FUNC_SIZE_...
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Größe für ausgewähltes Fenster ändern.
;
:WM_FUNC_SIZE_UL	lda	#< WM_FJOB_SIZE_UL
			ldx	#> WM_FJOB_SIZE_UL
			bne	WM_FUNC_RESIZE

:WM_FUNC_SIZE_UR	lda	#< WM_FJOB_SIZE_UR
			ldx	#> WM_FJOB_SIZE_UR
			bne	WM_FUNC_RESIZE

:WM_FUNC_SIZE_DL	lda	#< WM_FJOB_SIZE_DL
			ldx	#> WM_FJOB_SIZE_DL
			bne	WM_FUNC_RESIZE

:WM_FUNC_SIZE_DR	lda	#< WM_FJOB_SIZE_DR
			ldx	#> WM_FJOB_SIZE_DR

;*** Fenstergröße ändern.
:WM_FUNC_RESIZE		jsr	WM_EDIT_WIN		;Gummi-Band erzeugen.

			ldx	WM_WCODE		;"Maximiert"-Flag löschen.
			lda	#$00
			sta	WMODE_MAXIMIZED,x

			jsr	WM_SET_WIN_SIZE		;Neue Fenstergröße setzen.

			jmp	WM_UPDATE		;Aktuelles Fenster neu zeichnen.

;
;Routine  : WM_FJOB_SIZE_...
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Gummi-Band vergrößern oder verkleinern.
;
:WM_FJOB_SIZE_UL	jsr	WM_FJOB_TEST_Y0		;Nach oben...
			jsr	WM_FJOB_TEST_X0		;Nach links...

			lda	mouseXPos +0
			sta	r3L
			lda	mouseXPos +1
			sta	r3H
			lda	mouseYPos
			sta	r2L
			rts

:WM_FJOB_SIZE_UR	jsr	WM_FJOB_TEST_Y0		;Nach oben...
			jsr	WM_FJOB_TEST_X1		;Nach rechts...

			lda	mouseXPos +0
			sta	r4L
			lda	mouseXPos +1
			sta	r4H
			lda	mouseYPos
			sta	r2L
			rts

:WM_FJOB_SIZE_DL	jsr	WM_FJOB_TEST_Y1		;Nach unten...
			jsr	WM_FJOB_TEST_X0		;Nach links...

			lda	mouseXPos +0
			sta	r3L
			lda	mouseXPos +1
			sta	r3H
			lda	mouseYPos
			sta	r2H
			rts

:WM_FJOB_SIZE_DR	jsr	WM_FJOB_TEST_Y1		;Nach unten...
			jsr	WM_FJOB_TEST_X1		;Nach rechts...

			lda	mouseXPos +0
			sta	r4L
			lda	mouseXPos +1
			sta	r4H
			lda	mouseYPos
			sta	r2H
			rts

;
;Routine  : WM_FJOB_TEST_...
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Prüfen ob Größenänderung möglich.
;           Falls nein, Maus-Position korrigieren.
;
:WM_FJOB_TEST_Y0	lda	r2H
			sec
			sbc	mouseYPos
			bcc	:0
			cmp	#MIN_SIZE_WIN_Y 		;Nach oben möglich?
			bcs	:1			; => Ja, weiter...
::0			lda	r2L			;Mausposition zurücksetzen.
			sta	mouseYPos
::1			rts

:WM_FJOB_TEST_Y1	lda	mouseYPos
			sec
			sbc	r2L
			bcc	:0
			cmp	#MIN_SIZE_WIN_Y 		;Nach unten möglich?
			bcs	:1			; => Ja, weiter...
::0			lda	r2H			;Mausposition zurücksetzen.
			sta	mouseYPos
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
::0			lda	r3L			;Mausposition zurücksetzen.
			sta	mouseXPos +0
			lda	r3H
			sta	mouseXPos +1
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
::0			lda	r4L			;Mausposition zurücksetzen.
			sta	mouseXPos +0
			lda	r4H
			sta	mouseXPos +1
::1			rts

;
;Routine  : WM_FUNC_SIZE_MV
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Fenster verschieben.
;
:WM_FUNC_SIZE_MV	jsr	WM_GET_SLCT_SIZE

			lda	r2L
			sta	mouseYPos
			lda	r3L
			sta	mouseXPos +0
			lda	r3H
			sta	mouseXPos +1

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

			lda	#< WM_FJOB_TEST_MOV
			ldx	#> WM_FJOB_TEST_MOV
			jsr	WM_EDIT_WIN

			jsr	WM_SET_CARD_XY

			lda	r2L
			pha
			lda	r3H
			pha
			lda	r3L
			pha
			lda	r13H
			pha
			lda	r13L
			pha
			lda	r14L
			pha

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

			pla
			sta	r14L
			pla
			sta	r13L
			pla
			sta	r13H
			pla
			sta	r3L
			pla
			sta	r3H
			pla
			sta	r2L

			lda	r3L
			clc
			adc	r13L
			sta	r4L
			lda	r3H
			adc	r13H
			sta	r4H

			lda	r2L
			clc
			adc	r14L
			sta	r2H
			jsr	WM_SET_WIN_SIZE		;Neue Fensterposition setzen.

			jsr	WM_DRAW_MOVER		;Scrollbalken aktualisieren.

			jmp	WM_SAVE_SCREEN		;Fenster in ScreenBuffer speichern.

;
;Routine  : WM_FJOB_TEST_MOV
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Testen ob Fenster verschoben werden kann.
;           Wenn ja, dann neue X-/Y-Position für Gummi-Band setzen.
;
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

;
;Routine  : WM_FJOB_TEST_M...
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Testen ob Fenster verschoben werden kann.
;           Falls nein, Maus-Position korrigieren.
;
:WM_FJOB_TEST_MY	lda	mouseYPos		;Mausposition einlesen.
			clc				;Fensterhöhe addieren.
			adc	r14L			;Größer als Bildschirm/Überlauf?
			bcs	:0			; => Ja, Mausposition zurücksetzen.
			cmp	#MAX_AREA_WIN_Y 		;Nach unten möglich?
			bcc	:1			; => Ja, weiter...
::0			lda	r2L			;Mausposition zurücksetzen.
			sta	mouseYPos
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
::0			lda	r3L			;Mausposition zurücksetzen.
			sta	mouseXPos +0
			lda	r3H
			sta	mouseXPos +1
::1			rts

;
;Routine  : WM_EDIT_WIN
;Parameter: AKKU/XREG = Zeiger auf Test-Routine.
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Gewähltes Fenster mit Gummi-Band vergrößern/verschieben.
;           Wenn ja, dann neue X-/Y-Position für Gummi-Band setzen.
;
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

			lda	#%00000000		;Tastenstatus löschen.
			sta	pressFlag

			lda	#SCRN_HEIGHT -1
			sta	mouseBottom		;Untere Fenstergrenze setzen.

			plp				;IRQ-Status zurücksetzen.
			rts

;
;Routine  : WM_FUNC_MOVE...
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Fensterinhalt nach oben/unten verschieben.
;
.WM_FUNC_PAGE_DN	lda	WM_DATA_CURENTRY
			clc
			adc	WM_COUNT_ICON_XY
			sta	r0L
			bcs	WM_FUNC_MOVE_END	;Zum Ende der Liste.
			jmp	MoveSBar2Page		;Seite vorwärts.

.WM_FUNC_PAGE_UP	lda	WM_DATA_CURENTRY
			sec
			sbc	WM_COUNT_ICON_XY
			sta	r0L
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

:MoveSBar2Page		jsr	WM_TEST_CUR_POS		;Neue Position überprüfen.

			lda	r0L
			cmp	WM_DATA_CURENTRY
::2			beq	:1			;Position unverändert, Ende.

			jsr	WM_SET_NEW_POS		;Neue Position speichern.
			jsr	WM_MOVE_NEW_POS		;Fensterinhalt an Pos. ausgeben.
;			jsr	WM_DRAW_MOVER		;Scrollbalken aktualisieren.
			jsr	WM_SAVE_SCREEN		;Fenster in ScreenBuffer speichern.

::1			ldx	#NO_ERROR
			rts

;--- Fensterposition verschieben.
:MoveSBar2Pos		jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

::move			lda	WM_DATA_CURENTRY	;Zähler auf aktuellen Eintrag
			pha				;zwischenspeichern.

			jsr	WM_CALL_MOVE		;Fensterinhalt verschieben.

			pla				;Zähler auf aktuellen Eintrag
			sta	r0L			;zwischenspeichern.

			txa				;Fensterinhalt verschieben möglich?
			bne	:1a			; => Ja, weiter...

			lda	r0L
			cmp	WM_DATA_CURENTRY
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

;
;Routine  : WM_MOVE_NEW_POS
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Fensterinhalt an Position ausgeben.
;
:WM_MOVE_NEW_POS	jsr	WM_WIN_MARGIN		;Grenzen für Textausgabe setzen.

			lda	windowTop		;Grenzen als Fläche für
			sta	r2L			;Grafikroutine übernehmen.
			lda	windowBottom
			sta	r2H
			lda	leftMargin +0
			sta	r3L
			lda	leftMargin +1
			sta	r3H
			lda	rightMargin +0
			sta	r4L
			lda	rightMargin +1
			sta	r4H

			jsr	WM_CLEAR_WINAREA	;Fensterbereich löschen.

			jmp	WM_CALL_DRAWROUT	;Fensterinhalt aktualisieren.

;
;Routine  : WM_CALL_MSLCT
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Mehrfach-Dateiauswahl.
;Hinweis  : $0000 = Keine Auswahl möglich.
;           $FFFF = Standard-Auswahl.
;
:WM_CALL_MSLCT		jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

			lda	WM_DATA_WINMSLCT +0
			ldx	WM_DATA_WINMSLCT +1

			cmp	#$ff			;Standard-Auswahlfunktion?
			bne	callExtSelect		; => Nein, externe Rotuine aufrufen.
			cpx	#$ff
			bne	callExtSelect

			lda	#<WM_SLCT_MULTI		;Mehrere Dateien auswählen.
			ldx	#>WM_SLCT_MULTI
			bne	callExtSelect

;
;Routine  : WM_CALL_SSLCT
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Einzel-Dateiauswahl.
;Hinweis  : $0000 = Keine Auswahl möglich.
;           $FFFF = Standard-Auswahl.
;
:WM_CALL_SSLCT		jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

			lda	WM_DATA_WINSSLCT +0
			ldx	WM_DATA_WINSSLCT +1

			cmp	#$ff			;Standard-Auswahlfunktion?
			bne	callExtSelect		; => Nein, externe Rotuine aufrufen.
			cpx	#$ff
			bne	callExtSelect

			lda	#<WM_SLCT_SINGLE	;Eine Datei auswählen.
			ldx	#>WM_SLCT_SINGLE
;			bne	callExtSelect

:callExtSelect		ldy	WM_WCODE		;Externe Routine Einzel-
			jsr	CallRoutine		;Auswahl aufrufen.

			lda	WM_DATA_WINUPD +0
			ldx	WM_DATA_WINUPD +1
			jmp	CallRoutine		;Fensterinhalt speichern.

;
;Routine  : WM_SLCT_SINGLE
;Parameter: WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Einzel-Dateiauswahl.
;
.WM_SLCT_SINGLE		jsr	WM_TEST_ENTRY		;Eintrag mit der Maus ausgewählt?
			bcs	:1			; => Nein, weiter...
			rts

::1			stx	r14L			;Eintrag-Nr. speichern.

			jmp	WM_INVERT_FILE		;Verzeichnis-Eintrag invertieren.

;
;Routine  : WM_SLCT_MULTI
;Parameter: WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Mehrfach-Dateiauswahl.
;
.WM_SLCT_MULTI		jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

			jsr	WM_GET_SLCT_AREA	;Auswahlrahmen erstellen.

			lda	r2L			;Größe Auswahlbereich speichern.
			sta	SlctY0
			lda	r2H
			sta	SlctY1
			lda	r3L
			sta	SlctX0 +0
			lda	r3H
			sta	SlctX0 +1
			lda	r4L
			sta	SlctX1 +0
			lda	r4H
			sta	SlctX1 +1

			lda	r5L			;Auswahl-Modus vollständig/kreuzen.
			sta	SlctMode

;			jsr	WM_OPEN_DRIVE		;Laufwerk bereits aktiv...

			jsr	InitFPosData		;Daten für Ausgabe initialisieren.

			ldx	WM_DATA_MAXENTRY
			beq	:end_output		; => Nein, Ende...

::next_column		lda	CurXPos			;Aktuelle X-Position innerhalb
			cmp	MaxXPos			;des gültigen Bereichs?
			bcc	:3			; => Ja, weiter...

::reset_column		jsr	restColumnData		;Spaltendaten zurücksetzen.
			bcc	:next_row		; => Nächste Zeile, weiter...

::end_output		rts

::next_row		sta	CurYPos			;Neue Y-Position speichern.
			inc	CountY			;Zähler für Zeilen korrigieren.

			ldx	WM_DATA_ROW		;Anzahl Zeilen begrenzt?
			beq	:2b			; => Nein, weiter...
			cmp	WM_DATA_ROW		;Max. Anzahl Zeilen erreicht?
			bcs	:end_output		; => Ja, Ende...

::2b			lda	CurXPos
::3			jsr	setEntryData		;Daten für aktuellen Eintrag setzen.

			lda	CurEntry		;Zeiger auf aktuellen Eintrag.
			sta	r0L

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
			lda	CurEntry		;Eintrag-Nr. einlesen.
			sta	r14L
			jsr	WM_INVERT_FILE		;Verzeichnis-Eintrag invertieren.
			pla

::3a			inc	CurEntry		;Zähler auf nächsten Eintrag.

::3b			tax

::4			lda	CurEntry
			cmp	WM_DATA_MAXENTRY
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

;
;Routine  : WM_GET_SLCT_AREA
;Parameter: -
;Rückgabe : r2L-r4 = Gewählter Rahmenbereich.
;           r5L    = Markierungsmodus:
;                    $00 = Links nach rechts.
;                    $ff = Rechts nach Links.
;Verändert: A,X,Y,r2-r5L
;Funktion : Größe für Auswahl-Rahmen berechnen.
;
:WM_GET_SLCT_AREA	jsr	:SET_MOUSE_FRAME	;Rahmenposition setzen.

			lda	mouseXPos +0		;Aktuelle Mausposition speichern.
			sta	:ClickX   +0
			lda	mouseXPos +1
			sta	:ClickX   +1
			lda	mouseYPos
			sta	:ClickY

			lda	mouseXPos +0		;Mindestgröße für Auswahl-Rahmen
			clc				;festlegen.
			adc	#8
			sta	mouseXPos +0
			bcc	:add1
			inc	mouseXPos +1

::add1			lda	mouseYPos
			clc
			adc	#8
			sta	mouseYPos

::1			lda	mouseXPos +0		;Zeiger auf Anfangs-Position
			sta	:MouseX +0		;für Auswahl-Rahmen setzen.
			lda	mouseXPos +1
			sta	:MouseX +1
			lda	mouseYPos
			sta	:MouseY
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
			lda	:ClickX +1		;Maus < Anfangs-Position?
			cmp	:MouseX +1
			bne	:cmp1
			lda	:ClickX +0
			cmp	:MouseX +0
::cmp1			bcc	:4			; => Ja, Ende...
;Auswahl-Rahmen von rechts nach links:
;Einträge müssen teilweise innerhalb
;des Auswahl-Rahmens liegen.
			dex				;Auswahlmodus "Kreuzen".
::4			stx	r5L			;Auswahlmodus speichern.
			jmp	WM_RESET_AREA

;--- Rahmenposition setzen.
::SET_FRAME		lda	:MouseX +1
			cmp	:ClickX +1
			bne	:cmp2
			lda	:MouseX +0
			cmp	:ClickX +0
::cmp2			bcs	:11

			lda	:MouseX +0
			sta	r3L
			lda	:MouseX +1
			sta	r3H
			lda	:ClickX +0
			sta	r4L
			lda	:ClickX +1
			sta	r4H
			jmp	:12

::11			lda	:ClickX +0
			sta	r3L
			lda	:ClickX +1
			sta	r3H
			lda	:MouseX +0
			sta	r4L
			lda	:MouseX +1
			sta	r4H

::12			lda	:MouseY
			cmp	:ClickY
			bcs	:13

			lda	:MouseY
			sta	r2L
			lda	:ClickY
			sta	r2H
			rts

::13			lda	:ClickY
			sta	r2L
			lda	:MouseY
			sta	r2H
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

;
;Routine  : WM_TEST_SELECT
;Parameter: SlctMode = Auswahlmodus.
;                      $00 = Links->Rechts.
;                      $FF = Rechts->Links.
;           r2L = Y-Position/oben für Auswahlfenster.
;           r2H = Y-Position/unten für Auswahlfenster.
;           r3  = X-Position/links für Auswahlfenster.
;           r4  = X-Position/rechts für Auswahlfenster.
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Mehrfach-Dateiauswahl: Prüfen ob Eintrag im Fenster.
;           Dabei wird unterschieden zwischen der Auswahl von
;           Links->Rechts und Rechts->Links:
;           Links->Rechts: Eintrag muss komplett im Rahmen sein.
;           Rechts->links: Eintrag muss teilweise im Rahmen sein.
;
:WM_TEST_SELECT		jsr	WM_CONVERT_CARDS	;Pixel nach CARDs wandeln.

			lda	r2L			;Y-Position teilweise in Auswahl?
			cmp	SlctY1
			bcs	:not_selected

			lda	r2H
			cmp	SlctY0
			bcc	:not_selected		; => Nein, ignorieren.

			bit	SlctMode		;Auswahl-Modus testen.
			bmi	:1			;Auswahl Rechts->Links, weiter...

			lda	r2L			;Y-Position komplett in Auswahl?
			cmp	SlctY0
			bcc	:not_selected

			lda	r2H
			cmp	SlctY1
			bcs	:not_selected		; => Nein, ignorieren.

::1			lda	r3H			;X-Position teilweise in Auswahl?
			cmp	SlctX1 +1
			bne	:cmp1
			lda	r3L
			cmp	SlctX1 +0
::cmp1			bcs	:not_selected		; => Nein, ignorieren.

			lda	r4H
			cmp	SlctX0 +1
			bne	:cmp2
			lda	r4L
			cmp	SlctX0 +0
::cmp2			bcc	:not_selected

			bit	SlctMode		;Auswahl-Modus testen.
			bmi	:selected		;Auswahl Rechts->Links, weiter...

			lda	r3H			;X-Position komplett in Auswahl?
			cmp	SlctX0 +1
			bne	:cmp3
			lda	r3L
			cmp	SlctX0 +0
::cmp3			bcc	:not_selected		; => Nein, ignorieren.

			lda	r4H
			cmp	SlctX1 +1
			bne	:cmp4
			lda	r4L
			cmp	SlctX1 +0
::cmp4			bcs	:not_selected

;--- Datei gewählt.
::selected		sec
			rts

;--- Nicht gewählt.
::not_selected		clc
			rts

;
;Routine  : WM_INVERT_FILE
;Parameter: WM_WCODE = Fenster-Nr.
;           r2L = Y-Koordinate für Eintrag/oben.
;           r2H = Y-Koordinate für Eintrag/unten.
;           r3  = X-Koordinate für Eintrag/links.
;           r4  = X-Koordinate für Eintrag/rechts.
;           r14 = Eintrag-Nr.
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Eintrag invertieren wenn innerhalb Auswahlbereich.
;
:WM_INVERT_FILE		lda	r14L
			sta	r15L

			ldx	#r15L
			jsr	WM_SETVEC_ENTRY		;Zeiger auf Eintrag berechnen.

			ldy	#$02
			lda	(r15L),y		;Dateityp-byte einlesen.
			cmp	#GD_MORE_FILES		;"Weitere Dateien"?
			beq	:5			; => Ja, nicht auswählen...

			lda	r4H			;Rechte Grenze innerhalb Bildschirm?
			cmp	rightMargin +1
			bne	:cmp1
			lda	r4L
			cmp	rightMargin +0
::cmp1			bcc	:1			; => Ja, weiter...

			lda	rightMargin +0		;Rechte Grenze setzen.
			sta	r4L
			lda	rightMargin +1
			sta	r4H

::1			lda	r2H			;Untere Grenze innerhalb Bildschirm?
			cmp	windowBottom
			bcc	:2			; => Ja, weiter...

			lda	windowBottom		;Untere Grenze setzen.
			sta	r2H

::2			jsr	InvertRectangle		;Bereich invertieren.

			ldx	WM_WCODE		;Fenster-Nr. einlesen.

			ldy	#$00
			lda	(r15L),y		;Status "Datei ausgewählt" umkehren.
			eor	#GD_MODE_MASK
			sta	(r15L),y
			bne	:4			; => Icon ausgewählt.

;--- Dateiauswahl aufgehoben.
::3			dec	WMODE_SLCT,x
			rts

;--- Datei ausgewählt.
::4			inc	WMODE_SLCT,x		;Anzahl ausgewählte Dateien +1.
::5			rts

;
;Routine  : WM_SETVEC_ENTRY
;Parameter: XReg = Zero-Page-Adresse Faktor #1.
;Rückgabe : Zero-Page Faktor#1 erhält Adresse im RAM.
;Verändert: A,X,Y,r6-r8
;Funktion : Zeiger auf Eintrag im Speicher berechnen.
;
.WM_SETVEC_ENTRY	ldy	#5			;Größe Dateieintrag 2^5 = 32 Bytes.

			lda	#$00			;High-Byte Dateizähler löschen.
			sta	zpage +1,x

			jsr	DShiftLeft		;Anzahl Einträge x 32 Bytes.

			lda	zpage +0,x		;Startadresse Verzeichnisdaten.
			clc
			adc	#< BASE_DIRDATA
			sta	zpage +0,x
			lda	zpage +1,x
			adc	#> BASE_DIRDATA
			sta	zpage +1,x
			rts

;
;Routine  : WM_SWITCH_FSLCT
;Parameter: r0  = Zeiger auf Datei-Eintrag im Speicher.
;           r14 = Eintrag-Nr.
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Datei im Speicher aus-/abwählen und am Bildschirm invertieren.
;
.WM_FMODE_SELECT	ldx	#GD_MODE_SELECT
			b $2c
.WM_FMODE_UNSLCT	ldx	#GD_MODE_UNSLCT

			lda	r0H			;":r0" zwischenspeichern.
			pha				;(Zeiger auf Verzeichniseintrag)
			lda	r0L
			pha

			txa				;Markierungsmodus zwischenspeichern.
			pha
			jsr	WM_SET_ENTRY		;Eintrag im Fenster suchen.
			pla				;Markierungsmodus wieder einlesen.
			bcc	:1			; => Nicht gefunden, weiter...

			ldy	#$00			;Ist die aktuelle Datei bereits
			cmp	(r0L),y			;entsprechend markiert?
			beq	:1			; => Ja, weiter...

			jsr	WM_INVERT_FILE		;Verzeichnis-Eintrag invertieren.
			jsr	WM_SAVE_SCREEN		;ScreenBuffer aktualisiseren.

::1			pla				;r0 zurücksetzen.
			sta	r0L
			pla
			sta	r0H

			rts

;
;Routine  : WM_SIZE_ENTRY_F(ULL)/S(HORT)
;Parameter: WM_WCODE = Fenster-Nr.
;           r1L = X-Position für Ausgabe (CARDs).
;           r1H = Y-Position für Ausgabe (Pixel).
;           r2L = Max. X-Position für Ausgabe (CARDs).
;           r2H = Max. Y-Position für Ausgabe (Pixel).
;           r3L = X-Abstand (CARDs).
;           r3H = Y-Abstand (Pixel).
;Rückgabe : r2L = Breite für Eintrag (CARDs).
;           r2H = Höhe für Eintrag (Pixel).
;           XREG = $00 => Eintrag nicht anzeigen.
;                  $7F => Eintrag in nächster Zeile anzeigen.
;                  $FF => Eintrag anzeigen.
;Verändert: A,X,Y,r0-r15
;Funktion : Definiert Größe für Eintrag bei Datei-Auswahl.
;           WM_SIZE_ENTRY_F:
;           Im Infomodus ist die Breite = Ganze Zeile.
;           WM_SIZE_ENTRY_S:
;           Im Infomodus ist die Breite = Dateiname.
;
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

::1			lda	r1L
			clc
			adc	#3
			sta	r1L

			lda	#3			;Größe für Eintrag setzen.
			sta	r2L			;Icon = 3CARDs breit, 21 Pixel hoch.
			lda	#21
			sta	r2H

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

;
;Routine  : WM_TEST_ENTRY_X
;Parameter: r1L = X-Position für Ausgabe.
;           r2L = Max. X-Position für Ausgabe.
;           r3L = X-Abstand.
;Rückgabe : C-FLAG=0 Eintrag innerhalb Zeile.
;Verändert: A
;Funktion : Prüft ob ein Eintrag (Icon oder Text) komplett innerhalb der
;           aktuellen zeile noch angezeigt werden kann.
;
.WM_TEST_ENTRY_X	lda	r1L			;X-Position in CARDs.
			clc
			adc	r3L			;Breite in CARDs addieren.
			cmp	r2L			;Eintrag noch innerhalb der Zeile?
			rts

;
;Routine  : WM_TEST_ENTRY
;Parameter: WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe : r1L = X-Position für Ausgabe (CARDS).
;           r1H = Y-Position für Ausgabe (Pixel).
;           r2L = Max. X-Position für Ausgabe (CARDS).
;           r2H = Max. Y-Position für Ausgabe (Pixel).
;           r3L = X-Abstand (CARDS).
;           r3H = Y-Abstand (Pixel).
;           C-Flag=0  = Nichts ausgewählt.
;           XREG/YREG = Eintrag-Nr.
;Verändert: A,X,Y,r1-r5
;Funktion : Prüft ob ein Eintrag mit der Maus angeklickt wurde.
;
.WM_TEST_ENTRY		lda	#< IsMseInRegion	;Zeiger auf Testroutine.
			ldx	#> IsMseInRegion	;IsMseInRegion testet Mauszeiger.
			jsr	doEntryCheck		;Maus in Bereich?
			bcc	:1			; => Nein, weiter...

			ldx	CurEntry		;Eintrag-Nr. einlesen.
;			sec				;Eintrag ausgewählt.
::1			rts

;
;Routine  : WM_SET_ENTRY
;Parameter: r14L= Nr. des gesuchten Eintrages.
;Rückgabe : r1L = X-Position für Ausgabe (CARDS).
;           r1H = Y-Position für Ausgabe (Pixel).
;           r2L = Max. X-Position für Ausgabe (CARDS).
;           r2H = Max. Y-Position für Ausgabe (Pixel).
;           r3L = X-Abstand (CARDS).
;           r3H = Y-Abstand (Pixel).
;           C-Flag=0 = Nicht gefunden bzw. nicht sichtbar.
;Verändert: A,X,Y,r1-r5
;Funktion : Berechnet Position für Icon in Fenster.
;
:WM_SET_ENTRY		lda	#< :test_entry		;Zeiger auf Testroutine.
			ldx	#> :test_entry		;Prüft auf Eintrag-Nr.
			jsr	doEntryCheck		;Eintrag gefunden/sichtbar?
;			bcc	:1			; => Nein, weiter...
;			sec				;Eintrag-Nr. gefunden/sichtbar.
::1			rts

::test_entry		lda	r14L
			cmp	CurEntry
			bne	:_false			; => Nein, weiter...
			lda	#$ff			;Eintrag gefunden.
			b $2c
::_false		lda	#$00			;Eintrag nicht gefunden.
			rts

;
;Routine  : doEntryCheck
;Parameter: r5  = Zeiger auf Testroutine.
;                 Routine gibt AKKU=$FF zurück wenn TRUE.
;Rückgabe : r1L = X-Position für Ausgabe (CARDS).
;           r1H = Y-Position für Ausgabe (Pixel).
;           r2L = Max. X-Position für Ausgabe (CARDS).
;           r2H = Max. Y-Position für Ausgabe (Pixel).
;           r3L = X-Abstand (CARDS).
;           r3H = Y-Abstand (Pixel).
;           C-Flag=0 = Nicht gefunden bzw. nicht sichtbar.
;Verändert: A,X,Y,r2-r5
;Funktion : Sucht Eintrag im Fenster.
;           Wird von ":WM_TEST_ENTRY" und ":WM_SET_ENTRY" verwendet.
;
:doEntryCheck		sta	r5L			;Zeiger auf Testroutine speichern.
			stx	r5H

			ldx	WM_DATA_MAXENTRY	;Mind. 1 Eintrag vorhanden?
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

::41			inc	CurEntry		;Zähler auf nächsten Eintrag.

::42			lda	CurEntry
			cmp	WM_DATA_MAXENTRY
			bcs	:21			; => Weitere Einträge ausgeben.

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
:CurEntry		b $00
:CurGridX		b $00
:CurGridY		b $00
:CountX			b $00
:CountY			b $00
:SlctY0			b $00
:SlctY1			b $00
:SlctX0			w $0000
:SlctX1			w $0000
:SlctMode		b $00
