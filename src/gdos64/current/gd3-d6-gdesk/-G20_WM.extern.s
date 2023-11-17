; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
;Routine  : InitForWM
;Parameter: -
;Rückgabe : -
;Verändert: A,X
;Funktion : Initialisiert die Mausabfrage für ":mouseVector".
;           Der WM klinkt sich hierbei direkt in die Mausabfrage ein und
;           kehrt danach erst zur eigentlichen Mausroutine zurück.
;
.InitForWM		lda	otherPressVec +0
			ldx	otherPressVec +1

			cmp	#< WM_CHK_MOUSE		;Mausabfrage bereits aktiv?
			bne	:1			; => Nein, weiter...
			cpx	#> WM_CHK_MOUSE
			beq	:2			; => Ja, Ende...

::1			sta	mouseOldVec +0		;Zeiger auf existierende
			stx	mouseOldVec +1		;Mausabfrage zwischenspeichern.

			lda	#< WM_CHK_MOUSE		;Zeiger auf neue Mausabfrage.
			sta	otherPressVec +0
			lda	#> WM_CHK_MOUSE
			sta	otherPressVec +1

::2			rts

;
;Routine  : DoneWithWM
;Parameter: -
;Rückgabe : -
;Verändert: A
;Funktion : Deaktiviert die Mausabfrage über ":otherPressVec".
;
.DoneWithWM		lda	mouseOldVec +0
			sta	otherPressVec +0
			lda	mouseOldVec +1
			sta	otherPressVec +1
			rts

;
;Routine  : WM_IS_WIN_FREE
;Parameter: -
;Rückgabe : AKKU = Fenster-Nr.
;           XREG = $00=Kein Fehler.
;Verändert: A,X,Y
;Funktion : Sucht nach einer freien Fenster-Nr.
;
.WM_IS_WIN_FREE		ldy	WM_WCOUNT_OPEN
			cpy	#MAX_WINDOWS
			bcs	:3

			lda	#$00
::1			ldx	#$00
::2			cmp	WM_STACK,x
			bne	:4
			clc
			adc	#$01
			cmp	#MAX_WINDOWS
			bcc	:1
::3			ldx	#NO_MORE_WINDOWS
			rts

::4			inx
			cpx	#MAX_WINDOWS
			bcc	:2
			ldx	#NO_ERROR
			rts

;
;Routine  : WM_COPY_WIN_DATA
;Parameter: r0 = Zeiger auf Datentabelle.
;Rückgabe : -
;Verändert: A,Y
;Funktion : Fensterdaten in Fensterdaten-Tabelle einlesen.
;
.WM_COPY_WIN_DATA	ldy	#WINDOW_DATA_SIZE -1
::1			lda	(r0L),y
			sta	WM_DATA_BUF,y
			dey
			bpl	:1
			rts

;
;Routine  : WM_LOAD_WIN_DATA
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe : -
;Verändert: A,X,Y
;Funktion : Kopiert Daten aus Fensterdaten-Tabelle in Zwischenspeicher.
;
.WM_LOAD_WIN_DATA	lda	r0H
			pha
			lda	r0L
			pha

			jsr	setWinDataVec
			jsr	WM_COPY_WIN_DATA

			pla
			sta	r0L
			pla
			sta	r0H
			rts

;
;Routine  : WM_SAVE_WIN_DATA
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe : -
;Verändert: A,X,Y
;Funktion : Kopiert Daten aus Zwischenspeicher in Fensterdaten-Tabelle.
;
.WM_SAVE_WIN_DATA	lda	r0H
			pha
			lda	r0L
			pha

			jsr	setWinDataVec

			ldy	#WINDOW_DATA_SIZE -1
::1			lda	WM_DATA_BUF,y
			sta	(r0L),y
			dey
			bpl	:1

			pla
			sta	r0L
			pla
			sta	r0H
			rts

;
;Routine  : WM_CLR_WINDRVDAT
;Parameter: XREG = Fenster-Nr.
;Rückgabe : -
;Verändert: A
;Funktion : Laufwerksdaten für Fenster löschen.
;           Notwendig z.B. für "OpenMyComputer"
;           da das Fenster kein Laufwerk ist.
;
.WM_CLR_WINDRVDAT	;ldx	WM_WCODE 		;Fenster-Daten löschen.
			lda	#$00
			sta	WIN_DRIVE   ,x
			sta	WIN_PART    ,x
			sta	WIN_SDIR_T  ,x
			sta	WIN_SDIR_S  ,x
			sta	WIN_REALTYPE,x
			sta	WIN_DATAMODE,x
			rts

;
;Routine  : WM_CLR_WINSYSDAT
;Parameter: XREG = Fenster-Nr.
;Rückgabe : -
;Verändert: A
;Funktion : Optionen für Fenster löschen.
;           Notwendig für jedes neue
;           Fenster das geöffnet wird.
;
.WM_CLR_WINSYSDAT	;ldx	WM_WCODE 		;Fenster-Daten löschen.

			lda	#$00
			sta	WMODE_SLCT,x		;Anzahl ausgewählter Einträge.

;			sta	WMODE_MAXIMIZED,x	;Fenster maximiert. Wird durch
;							;":WM_DEF_STD_WSIZE" gelöscht.

			sta	WMODE_VSIZE,x		;Größe in KByte/Blocks.
			sta	WMODE_FILTER,x		;Filter für Fenster.
			sta	WMODE_SORT,x		;Sortierung für Fenster.
			sta	WMODE_VICON,x		;Icons/Text anzeigen.
			sta	WMODE_VINFO,x		;Text/Details anzeigen.

			rts

;
;Routine  : WM_TEST_MOVE
;Parameter: -
;Rückgabe : -
;Verändert: A
;Funktion : Auf Drag`n`Drop testen.
;
.WM_TEST_MOVE		lda	mouseData
			bmi	:1
			jsr	SCPU_Pause

			lda	mouseData
			bmi	:1
			jsr	SCPU_Pause

			lda	mouseData
			bmi	:1
			sec
			rts

::1			clc
			rts

;
;Routine  : WM_OPEN_WINDOW
;Parameter: r0   = Zeiger auf Datentabelle.
;           r1L  = $00=Fenster-Optionen löschen.
;Rückgabe : AKKU = Fenster-Nr.
;           XREG = $00=Kein Fehler.
;Verändert: A,X,Y,r0-r15
;Funktion : Öffnet und zeichnet ein neues Fenster mit Inhalt.
;Hinweis  : Wenn das Fenster kein Laufwerksfenster ist, dann sollte
;           vorher ":WM_CLR_WINDRVDAT" aufgerufen werden um die
;           Laufwerksdaten für das Fenster zu löschen.
;
.WM_OPEN_WINDOW		jsr	WM_IS_WIN_FREE		;Freie Fenster-Nr. suchen.
			cpx	#NO_ERROR		;Fenster gefunden ?
			beq	:1			; => Ja, weiter...
			rts

::1			ldy	WM_WCOUNT_OPEN		;Fenster in Stackspeicher eintragen.
			sta	WM_STACK,y
			inc	WM_WCOUNT_OPEN

			bit	r1L
			bmi	WM_USER_WINDOW
			pha
			tax				;Fenster-Daten löschen.
			jsr	WM_CLR_WINSYSDAT
			pla

			tax
			lda	#$00			;Flag löschen: "Maximiert".
			sta	WMODE_MAXIMIZED,x
			txa

;
;Routine  : WM_USER_WINDOW
;Parameter: AKKU = Fenster-Nr.
;           r0   = Zeiger auf Datentabelle.
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Öffnet und zeichnet ein bereits reserviertes Fenster mit Inhalt.
;Hinweis  : Wenn das Fenster kein Laufwerksfenster ist, dann sollte
;           vorher ":WM_CLR_WINDRVDAT" aufgerufen werden um die
;           Laufwerksdaten für das Fenster zu löschen.
;
.WM_USER_WINDOW		php
			sei				;Interrupt sperren.

			pha				;Fensterdaten in
			sta	WM_WCODE		;Zwischenspeicher kopieren.
			jsr	WM_COPY_WIN_DATA
			pla
			jsr	WM_WIN2TOP		;Fenster nach oben holen.

			lda	WM_DATA_SIZE		;Feste Fenstergröße ?
			bne	:1			; => Ja, weiter...

			lda	WM_DATA_Y0
			ora	WM_DATA_Y1		;Fenstergröße definiert ?
			bne	:1			; => Ja, weiter...
			jsr	WM_DEF_STD_WSIZE	;Standard-Größe festlegen.

::1			jsr	WM_SAVE_WIN_DATA	;Fensterdaten speichern.

			jsr	WM_CALL_DRAW		;Fenster ausgeben.

			jsr	WM_RESET_AREA		;Textgrenzen löschen.

			plp				;IRQ-Status zurücksetzen.

			lda	WM_WCODE
			ldx	#NO_ERROR
			rts

;
;Routine  : WM_CLOSE_ALL_WIN
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Alle Fenster schließen.
;
.WM_CLOSE_ALL_WIN	lda	WM_STACK		;Fenster-Nr. vom Stack holen.
			beq	:1			; => $00 = DeskTop, Ende.
			bmi	:1			; => $FF = Fenster nicht aktiv.
			sta	WM_WCODE		;Als aktives Fenster setzen.
			jsr	WM_CLOSE_WINDOW		;Fenster schließen.
			jmp	WM_CLOSE_ALL_WIN	;Weiter mit nächstem Fenster.
::1			rts

;
;Routine  : WM_CLOSE_CURWIN
;Parameter: WM_CODE = Fenster-Nr.
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Aktives Fenster schließen.
;
.WM_CLOSE_CURWIN	lda	WM_STACK		;Oberstes Fenster einlesen.

;
;Routine  : WM_CLOSE_WINDOW
;Parameter: AKKU = Fenster-Nr.
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Einzelnes Fenster schließen.
;
.WM_CLOSE_WINDOW	php
			sei				;Interrupt sperren.

			sta	WM_WCODE		;Aktives Fenster setzen.
			jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.
			jsr	WM_DELETE_WINDOW	;Fenster aus Liste löschen.
			jsr	WM_DRAW_ALL_WIN		;Alle Fenster aus ScreenBuffer
							;neu darstellen.
			plp				;IRQ-Status zurücksetzen.
			rts				;Keine Fenster mehr, Ende.

;
;Routine  : WM_DELETE_WIN
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Fenster aus Liste löschen.
;
.WM_DELETE_WINDOW	jsr	WM_CALL_EXIT		;Vorbereiten "Fenster schließen".

			ldx	#$00			;Fenster-Nr. in Stack suchen und
			ldy	#$00			;löschen. Stack komprimieren.
::1			lda	WM_STACK ,x
			cmp	WM_WCODE
			beq	:2
			sta	WM_STACK ,y
			iny
::2			inx
			cpx	#MAX_WINDOWS
			bne	:1
			cpy	#MAX_WINDOWS
			beq	:3

			dec	WM_WCOUNT_OPEN		;Anzahl offene Fenster -1.

			lda	#$ff			;Fenster "geschlossen".
			sta	WM_STACK ,y

::3			rts

;
;Routine  : WM_CALL_DRAW
;Parameter: WM_WCODE = Fenster-Nr.
;           WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Initialisiert das angegebene Fenster und zeichnet Fensterinhalt.
;
.WM_CALL_DRAW		php
			sei				;Interrupt sperren.

			jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

			jsr	WM_DRAW_SLCT_WIN	;Leeres Fenster zeichnen.

			lda	WM_DATA_WININIT +0
			ldx	WM_DATA_WININIT +1
			ldy	WM_WCODE
			jsr	CallRoutine		;Fenster initialisieren.

			jsr	WM_SAVE_WIN_DATA	;Fensterdaten speichern.

			jmp	doRedrawWin		;Fensterinhalt zeichnen.

;
;Routine  : WM_CALL_REDRAW
;Parameter: WM_WCODE = Fenster-Nr.
;           WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Zeichnet das angegebene Fenster neu.
;           Dabei wird kein "WIN_INIT" ausgeführt.
;
.WM_CALL_REDRAW		php
			sei				;Interrupt sperren.
			jsr	WM_DRAW_SLCT_WIN	;Leeres Fenster zeichnen.
:doRedrawWin		jsr	WM_WIN_MARGIN		;Grenzen für Textausgabe setzen.
			jsr	WM_CALL_DRAWROUT	;Fensterinhalt ausgeben.
			jsr	WM_SAVE_WIN_DATA	;Fensterdaten speichern.
			jsr	WM_DRAW_TITLE		;Titelzeile ausgeben.
			jsr	WM_DRAW_INFO		;Infozeile ausgeben.
			jsr	WM_DRAW_MOVER		;Scrollbalken aktualisieren.
			jsr	WM_SAVE_SCREEN		;Fenster in ScreenBuffer speichern.
			plp				;IRQ-Status zurücksetzen.
			rts

;
;Routine  : WM_CALL_GETFILES
;Parameter: reloadFlag = $00 => Dateien aus Cache.
;                        $FF => Dateien von Disk einlesen.
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Routine "Dateien laden" aufrufen.
;
.WM_CALL_GETFILES	php				;IRQ sperren und Mauszeiger
			sei				;abschalten.
			jsr	MouseOff

			lda	WM_DATA_GETFILE+0	;Systemroutine zum einlesen von
			ldx	WM_DATA_GETFILE+1	;Verzeichnisdaten aufrufen.
			jsr	CallRoutine

			jsr	MouseUp			;Mauszeiger aktivieren und
			plp				;IRQ-Status zurücksetzen.
			rts

;
;Routine  : WM_UPDATE
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Aktualisiert und prüft das oberste Fenster.
;
.WM_UPDATE		jsr	WM_DRAW_NO_TOP		;Fenster aus ScreenBuffer laden.

			lda	WM_STACK		;Oberstes Fenster aktivieren.
			sta	WM_WCODE		;Weiteres Fenster aktiv?
			beq	:exit			; => Nein, Ende...

			jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

			jsr	WM_GET_ICON_XY		;Anzahl Icons ermitteln.

			jsr	WM_TEST_WIN_POS		;Testen ob aktuelle Position im
							;Fenster gültig ist, falls nein auf
							;erste Position zurücksetzen.

			jsr	WM_CALL_REDRAW		;Oberstes Fenster neu laden.

::exit			ldx	#NO_ERROR
			rts

;
;Routine  : WM_REDRAW_ALL
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Zeichnet alle Fenster neu (außer Desktop).
;           Dabei wird kein "WIN_INIT" ausgeführt.
;
:WM_REDRAW_ALL		lda	#$00			;Hintergrundbild und Verknüpfungen
			sta	WM_WCODE		;aus Speicher holen und neuzeichnen.
			jsr	WM_LOAD_SCREEN

			lda	#MAX_WINDOWS -1		;Fenster Zähler setzen.
::loop			pha
			tax
			lda	WM_STACK,x
			beq	:skip			;Desktop? => Ja, weiter....
			bmi	:skip			;Fenster aktiv? => Nein, weiter...
			sta	WM_WCODE		;Als aktuelles Fenster setzen.

			jsr	WM_CALL_REDRAW		;Fenster neu zeichnen.

::skip			pla
			sec				;Fenster-Zähler korrigieren.
			sbc	#$01			;Alle Fenster gezeichnet?
			bpl	:loop			; => Nein, weiter...

			ldx	#NO_ERROR
			rts

::reloadFilesBuf	b $00

;
;Routine  : WM_DRAW_ALL_WIN
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Zeichnet alle Fenster neu.
;           Der Inhalt wird dabei aus dem ScreenBuffer eingelesen.
;
.WM_DRAW_ALL_WIN	jsr	WM_DRAW_NO_TOP		;Fenster aus ScreenBuffer laden.

;
;Routine  : WM_DRAW_TOP_WIN
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Zeichnet oberstes Fenster neu.
;           Der Inhalt wird dabei aus dem ScreenBuffer eingelesen.
;Hinweis  : Einsprungsadresse wird
;           aktuell nicht verwendet.
;
::WM_DRAW_TOP_WIN	lda	WM_STACK		;Oberstes Fenster aktivieren.
			sta	WM_WCODE

			jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

			jsr	WM_LOAD_SCREEN		;Fenster aus ScreenBuffer einlesen.

			jsr	WM_DRAW_MOVER		;Scrollbalken aktualisieren.

			ldx	#NO_ERROR
			rts

;
;Routine  : WM_DRAW_NO_TOP
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Zeichnet bis auf oberstes alle Fenster neu.
;           Der Inhalt wird dabei aus dem ScreenBuffer eingelesen.
;
:WM_DRAW_NO_TOP		lda	WM_WCODE		;Aktuelles Fenster merken.
			pha

			lda	#MAX_WINDOWS -1		;Fenster Zähler setzen.
::loop			pha
			tax
			lda	WM_STACK,x
			bmi	:skip			;Fenster aktiv? => Nein, weiter...
			sta	WM_WCODE		;Als aktuelles Fenster setzen.

			jsr	WM_LOAD_SCREEN		;Fenster aus ScreenBuffer einlesen.

::skip			pla
			sec				;Fenster-Zähler korrigieren.
			sbc	#$01			;Alle Fenster gezeichnet?
			bne	:loop			; => Nein, weiter...

			pla				;Aktives Fenster zurücksetzen.
			sta	WM_WCODE
			jmp	WM_LOAD_WIN_DATA	;Fensterdaten zurücksetzen.

;
;Routine  : WM_DRAW_BACKSCR
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0-r4
;Funktion : Zeichnet den Hintergrund neu.
;           Der Inhalt wird dabei aus dem ScreenBuffer eingelesen.
;
.WM_DRAW_BACKSCR	lda	WM_WCODE		;Aktuelle Fenster-Nr.
			pha				;zwischenspeichern.

			lda	#$00			;"DeskTop-Fenster" aktivieren.
			sta	WM_WCODE
			jsr	WM_LOAD_SCREEN		;Fenster aus ScreenBuffer laden.

			pla				;Aktuelle Fenster-Nr. wieder
			sta	WM_WCODE		;einlesen.

			rts

;
;Routine  : WM_HIDEWIN_OFF
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0-r4
;Funktion : Ausgeblendete Fenster wieder anzeigen.
;           Der Inhalt wird dabei aus dem ScreenBuffer eingelesen.
;
.WM_HIDEWIN_OFF		bit	GD_HIDEWIN_MODE		;Fenster versteckt?
			bpl	:1			; => Nein, Ende...

			jsr	WM_DRAW_ALL_WIN		;Alle Fenster wieder anzeigen.

			lda	#$00			;Flag für "Fenster ausgeblendet"
			sta	GD_HIDEWIN_MODE		;zurücksetzen.

::1			rts

;
;Routine  : WM_FUNC_SORT
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Fenster als Stapel sortieren.
;
.WM_FUNC_SORT		lda	#$01
			sta	r1L			;Fensterzähler initialisieren.

::1			lda	r1L
			sta	WM_WCODE
			tax
			lda	#$00			;"Maximiert"-Flag löschen.
			sta	WMODE_MAXIMIZED,x

			jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.
			jsr	WM_DEF_STD_WSIZE	;Fenstergröße auf Standard setzen.
			jsr	WM_SAVE_WIN_DATA	;Fensterdaten speichern.

			lda	WM_WCODE		;Fenster nach oben sortieren.
			jsr	WM_WIN2TOP

			inc	r1L
			lda	r1L
			cmp	#MAX_WINDOWS		;Alle Fenster neu angeordnet?
			bcc	:1			; => Nein, weiter...

			jmp	WM_REDRAW_ALL		;Alle Fenster neu darstellen.

;
;Routine  : WM_FUNC_POS
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Fenster nebeneinander anordnen.
;
.WM_FUNC_POS		lda	#MIN_AREA_WIN_Y
			sta	r2L
			lda	#MAX_AREA_WIN_Y -1
			sta	r2H			;Fensterhöhe für eine Fensterreihe.

			ldx	WM_WCOUNT_OPEN
			dex
			cpx	#$03 +1			;Weniger als vier Fenster?
			bcc	:2			; => Ja, weiter...
			bne	:1			; => Mehr oder weniger als vier.
			ldx	#$02			;Bei vier Fenster Anordnung 2x2.
			b $2c
::1			ldx	#$03			;Mehr als vier Anordnung 3x2.
			lda	#$57
			sta	r2H			;Fensterhöhe für erste Fensterreihe.

::2			stx	r1H			;Anzahl Fenster je Reihe.

			dex				;Breite für Fenster einlesen.
			txa
			asl
			tax
			lda	:WIDTH +0,x
			sta	r5L
			lda	:WIDTH +1,x
			sta	r5H

			lda	#$00			;Zeiger auf Fensterstack
			sta	r1L			;initialisieren.

;--- Hinweis:
;Der ursprüngliche Code hat Icons am
;rechten Rand auch teilweise angezeigt.
;Aktuell werden nur ganze Icons ange-
;zeigt, dazu muss die minimale Breite
;aber vergrößert werden.
::3			lda	#< MIN_AREA_WIN_X	;Linker Rand bei $0000.
			sta	r3L
;			lda	#> MIN_AREA_WIN_X
			sta	r3H
;			lda	#$00			;Spaltenzähler zurücksetzen.
			sta	r6L

::4			ldx	r1L
			lda	WM_STACK,x		;Fenster geöffnet?
			beq	:5			; => Desktop ignorieren.
			bmi	:5			; => Nein, weiter...
			sta	WM_WCODE		;Fenster-Nr. in Stackzeiger.

			tax
			lda	#$00			;"Maximiert"-Flag löschen.
			sta	WMODE_MAXIMIZED,x

			jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

			lda	r2L			;Fenster-Position oben setzen.
			sta	WM_DATA_Y0
			lda	r2H			;Fenster-Position unten setzen.
			sta	WM_DATA_Y1

			lda	r3L			;Fenster-Position links setzen.
			sta	WM_DATA_X0 +0
			lda	r3H
			sta	WM_DATA_X0 +1

			lda	r3L			;Fenster-Position rechts setzen.
			clc
			adc	r5L
			sta	r3L
			sta	WM_DATA_X1 +0
			lda	r3H
			adc	r5H
			sta	r3H
			sta	WM_DATA_X1 +1

			inc	r6L			;Anzahl Spalten +1.
			lda	r6L
			cmp	#$03			;Spalte #3 erreicht?
			bne	:7			; => Nein, weiter...

			lda	WM_DATA_X1 +0		;Letzte Spalte maximieren.
			clc
			adc	#8
			sta	WM_DATA_X1 +0
			bcc	:7
			inc	WM_DATA_X1 +1

::7			jsr	WM_SAVE_WIN_DATA	;Fensterdaten speichern.

			inc	r3L			;r3 = Rechter Rand Fenster, auf
			bne	:5			;linken Rand nächste Spalte setzen.
			inc	r3H

::5			inc	r1L			;Fensterzähler +1.
			lda	r1L
			cmp	#MAX_WINDOWS		;Alle Fenster neu angeordnet?
			bcs	:6			; => Nein, weiter...

			lda	r6L			;Spaltenzähler einlesen.
			cmp	r1H			;Letzte Spalte erreicht?
			bne	:4			; => Nein, weiter...

			lda	#$58			;Y-Position für zweite Reihe.
			sta	r2L
			lda	#MAX_AREA_WIN_Y -1
			sta	r2H
			jmp	:3			; => Weiter mit nächster Reihe.

::6			jmp	WM_REDRAW_ALL		;Alle Fenster neu darstellen.

;*** Tabelle mit Fensterbreite für 1,2 oder 3 Spalten.

;--- Hinweis:
;Fenster vergrößern für neue Anzeige
;von ganzen Icons.
;::WIDTH		w 36*8-1
;			w 18*8-1
;			w 12*8-1

::WIDTH			w 40*8-1			;Nur 1 Fenster.
			w 20*8-1			;2/4 Fenster.
			w 13*8-1			;3/5/6 Fenster.

;
;Routine  : WM_WIN2TOP
;Parameter: AKKU = Fenster-Nr.
;Rückgabe : -
;Verändert: A,X,Y
;Funktion : Setzt Fenster an erste Stelle im Stack.
;
.WM_WIN2TOP		sta	WM_WCODE		;Fenster-Nr. sichern.

			ldx	#MAX_WINDOWS -1
			ldy	#MAX_WINDOWS -1
::1			lda	WM_STACK ,x		;Ziel-Fenster im Stack suchen und
			cmp	WM_WCODE		;aus Stack löschen.
			beq	:2			; => Fenster gefunden, überspringen.
			sta	WM_STACK ,y
			dey
			bmi	:3			;Fenster nicht gefunden, Abbruch.

::2			dex				;Gesamten Stack durchsucht?
			bpl	:1			; => Nein, weiter...

			lda	WM_WCODE		;Ziel-Fenster an erste Stelle
			sta	WM_STACK		;in Stack schreiben.

::3			rts

;
;Routine  : WM_FIND_WINDOW
;Parameter: -
;Rückgabe : XREG = $00 => Kein Fehler.
;           YREG = Fenster-Nr.
;Verändert: A,X,Y,r0,r2-r4
;Funktion : Aktuelles Fenster suchen.
;
.WM_FIND_WINDOW		php				;IRQ sperren.
			sei

			lda	#$00			;Fenster-Nr. auf Anfang.
			sta	:tmpWindow

::1			ldx	#WINDOW_NOT_FOUND	;Fehlermeldung vorbereiten.

			ldy	:tmpWindow
			cpy	#MAX_WINDOWS		;Alle Fenster durchsucht ?
			beq	:3			; => Ja, Ende...
			lda	WM_STACK,y		;Fenster-Nr. einlesen.
			bmi	:3			; => Ende erreicht...

			jsr	WM_GET_WIN_SIZE		;Fenstergröße einlesen.
			jsr	IsMseInRegion		;Mausposition abfragen.
			tax				;Ist Maus in Bereich ?
			bne	:2			; => Ja, Fenster gefunden.

			inc	:tmpWindow		;Zeiger auf nächstes Fenster und
			jmp	:1			;weitersuchen.

::2			ldx	#NO_ERROR		;Flag für "Kein Fehler" setzen und
			ldy	:tmpWindow		;Fenster-Nr. einlesen.
::3			plp
			rts

::tmpWindow		b $00

;
;Routine  : WM_WIN_BLOCKED
;Parameter: -
;Rückgabe : XREG = $00 => Fenster nicht verdeckt.
;Verändert: A,X,Y,r0,r2-r4
;Funktion : Prüft ob aktuelles Fenster verdeckt ist.
;
:WM_WIN_BLOCKED		lda	WM_WCODE		;Aktuelle Fenster-Nr. in
			sta	:tmpWindow		;Zwischenspeicher einlesen.
			jsr	:1			;Ist Fenster verdeckt ?

			txa				;Ergebnis zwischenspeichern.
			pha

			lda	:tmpWindow		;Fensterdaten für aktuelles
			sta	WM_WCODE		;Fenster wieder einlesen.
			jsr	WM_LOAD_WIN_DATA

			pla
			tax
			rts

;--- Ist Fenster verdeckt ?
::1			jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

			ldx	#$05			;Größe des aktuellen
::2			lda	WM_DATA_Y0,x		;Fensters einlesen.
			sta	r2L       ,x
			dex
			bpl	:2

::3			inx
			stx	:tmpStackPointer	;Zeiger auf Fensterstack speichern.

			lda	WM_STACK,x
			bmi	:4			; => Nicht definiert, weiter...
			beq	:4			; => Desktop-Fenster, weiter...
			cmp	:tmpWindow		;Aktuelles Fenster ?
			beq	:5			; => Ja, übergehen...

			sta	WM_WCODE		;Fensterdaten einlesen.
			jsr	WM_LOAD_WIN_DATA

			lda	WM_DATA_Y0		;Fenstergröße testen.
			cmp	r2H
			bcs	:4
			lda	WM_DATA_Y1
			cmp	r2L
			bcc	:4

			lda	WM_DATA_X0 +1
			cmp	r4H
			bne	:c1
			lda	WM_DATA_X0 +0
			cmp	r4L
::c1			bcs	:4

			lda	WM_DATA_X1 +1
			cmp	r3H
			bne	:c2
			lda	WM_DATA_X1 +0
			cmp	r3L
::c2			bcc	:4

			ldx	#WINDOW_BLOCKED		;Fenster blockiert, Ende...
			rts

::4			ldx	:tmpStackPointer
			cpx	#MAX_WINDOWS -1		;Alle Fenster überprüft ?
			bcc	:3			; => Nein, weiter...

::5			ldx	#NO_ERROR
			rts

::tmpStackPointer	b $00
::tmpWindow		b $00

;
;Routine  : WM_CONVERT_CARDS
;Parameter: r1L = X-Koordinate (Cards)
;           r1H = Y-Koordinate (Pixel)
;           r2L = Breite (Cards)
;           r2H = Höhe (Pixel)
;Rückgabe : r2L = Y-Koordinate/oben (Pixel)
;           r2H = Y-Koordinate/unten (Pixel)
;           r3  = X-Koordinate/links (Pixel)
;           r4  = X-Koordinate/rechts (Pixel)
;Verändert: A,X,Y,r2-r4
;Funktion : Berechnet Grafikbereich von Icon in Pixel.
;
.WM_CONVERT_CARDS	lda	r1L			;X-Koordinate von CARDs nach
			sta	r3L			;Pixel in ":r3" konvertieren.
			lda	#$00
			sta	r3H
			ldx	#r3L
			ldy	#$03
			jsr	DShiftLeft

			lda	r2L			;Breite von CARDs nach
			sta	r4L			;Pixel in ":r4" konvertieren.
			lda	#$00
			sta	r4H
			ldx	#r4L
			ldy	#$03
			jsr	DShiftLeft

			lda	r3L			;Breite in Pixel in rechte
			clc				;X-Koordinate wandeln.
			adc	r4L
			sta	r4L
			lda	r3H
			adc	r4H
			sta	r4H

			lda	r4L			;Rechte X-Koordinate -1 Pixel für
			bne	:1			;Ende des letzten CARDs setzen.
			dec	r4H
::1			dec	r4L

			lda	r1H			;Obere Y-Koordinate setzen.
			sta	r2L
			clc
			adc	r2H			;Höhe für Icon addieren.
			sta	r2H			;Untere Y-Koordinate.
			dec	r2H			;Auf Ende unterstes CARD setzen.
			rts

;
;Routine  : WM_CONVERT_PIXEL
;Parameter: r3  = X-Koordinate (WORD, Pixel)
;           r2L = Y-Koordinate (BYTE, Pixel)
;Rückgabe : r1L = X-Koordinate (Cards)
;           r1H = Y-Koordinate (Pixel)
;Verändert: A,r1L,r1H
;Funktion : Rechteck-Koordinaten in ":BitmapUp"-Format konvertieren.
;
.WM_CONVERT_PIXEL	lda	r3H			;X-Koordinate in CARDs
			lsr				;umrechnen.
			lda	r3L
			ror
			lsr
			lsr
			sta	r1L

			lda	r2L			;Y-Koordinate übernehmen.
			sta	r1H
			rts

;
;Routine  : WM_GET_GRID_X
;Parameter: WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe : AKKU = Breite für Spalte.
;Verändert: A
;Funktion : Berechnet Breite einer Spalte.
;
.WM_GET_GRID_X		lda	WM_DATA_GRID_X
			bne	:1
			lda	#WM_GRID_ICON_XC
::1			rts

;
;Routine  : WM_GET_GRID_Y
;Parameter: WM_DATA_BUF = Daten für aktuelles Fenster.
;Rückgabe : AKKU = Höhe für Zeile.
;Verändert: A
;Funktion : Berechnet Höhe einer Zeile.
;
.WM_GET_GRID_Y		lda	WM_DATA_GRID_Y
			bne	:1
			lda	#WM_GRID_ICON_Y
::1			rts
