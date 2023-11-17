; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** GEOS-Menü öffnen.
.OPEN_MENU_GEOS		lda	#GMNU_GEOS
			b $2c

;*** Fenster-Menü öffnen.
.OPEN_MENU_SCRN		lda	#GMNU_WIN		;Zeiger auf Menü-Daten setzen.

			pha
			jsr	WM_HIDEWIN_OFF		;"Fenster ausblenden" deaktivieren.
			pla

			jmp	LdDTopMod		;Menü nachladen.

;*** Farbe setzen und PullDown-Menü öffnen.
;    Übergabe: r0 = Zeiger auf Menüdaten.
.OPEN_MENU		jsr	DoneWithWM		;Fenster-Abfrage abschalten.

			lda	#$00			;Tastaturabfrage löschen.
			sta	keyVector +0
			sta	keyVector +1

			jsr	MAIN_RESETAREA		;Textgrenzen löschen.
			jsr	sys_SvBackScrn		;Aktuellen Bildschirm speichern.

			jsr	OPEN_MENU_SETCOL	;Farbe für Menü setzen.

			lda	#$01
			jsr	DoMenu			;Menü aktivieren.

;*** Menü-Vektoren setzen.
.OPEN_MENU_INIT		lda	#< GD_DRAWCLOCK		;Uhrzeit aktualisieren.
			sta	appMain +0
			lda	#> GD_DRAWCLOCK
			sta	appMain +1

			lda	#< :1			;Eigene RecoverRectangle-Routine.
			sta	RecoverVector +0
			lda	#> :1
			sta	RecoverVector +1

			lda	#< :2			;Eigene Mausabfrage setzen.
			sta	mouseFaultVec +0
			lda	#> :2
			sta	mouseFaultVec +1

::exit			rts

;--- Ersatz für RecoverRectangle.
::1			lda	#< GD_BACKSCR_BUF
			sta	r10L
			lda	#> GD_BACKSCR_BUF
			sta	r10H

			lda	#< GD_BACKCOL_BUF
			sta	r11L
			lda	#> GD_BACKCOL_BUF
			sta	r11H

			lda	GD_SYSDATA_BUF
			jmp	WM_LOAD_AREA

;--- Mausabfrage.
::2			lda	faultData		;Hat Mauszeiger aktuelles Menü
			and	#%00001000		;verlassen ?
			beq	:exit			; => Nein, Ende...

			lda	menuNumber		;Hauptmenü aktiv ?
			beq	:5			;Ja, übergehen.
			jsr	OPEN_PREV_MENU		;Ein Menü zurück.
			jmp	OPEN_MENU_INIT

::5			jsr	RecoverAllMenus		;Menüs löschen.

			lda	exitMenuVec +0
			ldx	exitMenuVec +1
			jsr	CallRoutine

;*** Vektoren zurücksetzen.
.CLOSE_MENU		lda	#$00
			sta	mouseFaultVec +0	;Mausabfrage löschen.
			sta	mouseFaultVec +1

			sta	RecoverVector +0	;RecoverRectangle löschen.
			sta	RecoverVector +1

			sta	exitMenuVec +0
			sta	exitMenuVec +1

			lda	mouseOn			;Menü-Flag löschen.
			and	#%10111111
			sta	mouseOn

			jmp	InitWinMseKbd		;Fenster-/Maus-/Tastatur starten.

.exitMenuVec		w $0000

;*** Zeiger auf Menü-Initialisierung setzen.
;    Übergabe: AKKU/XREG = Zeiger auf Menüdaten.
.MENU_SETINT_AX		sta	r0L
			stx	r0H

.MENU_SETINT_r0		lda	#< OPEN_MENU_INIT
			sta	appMain +0
			lda	#> OPEN_MENU_INIT
			sta	appMain +1

;			jmp	OPEN_MENU_SETCOL

;*** Hintergrundfarbe für Menü setzen.
:OPEN_MENU_SETCOL	ldy	#$05
::1			lda	(r0L),y			;Fenstergröße einlesen.
			sta	r2,y
			dey
			bpl	:1

			lda	C_PullDMenu		;Farbe für Menü setzen.
			jmp	DirectColor

;*** Erweiterung für ":DoPreviousMenu", damit auch Farben des
;    letzten Menüs richtig gesetzt werden.
:OPEN_PREV_MENU		lda	Rectangle +1		;Rectangel-Routine von
			sta	:2 +1			;GEOS auf eigene Routine umbiegen.
			lda	Rectangle +2
			sta	:3 +1

			lda	#< :1
			sta	Rectangle +1
			lda	#> :1
			sta	Rectangle +2

			jmp	DoPreviousMenu		;Vorheriges Menü aufrufen.

::1			lda	C_PullDMenu		;Farbe für Menü setzen.
			jsr	DirectColor

::2			lda	#$ff			;Original-Rectangle-Routine im
			sta	Rectangle +1		;GEOS-Kernal wieder installieren.
::3			ldx	#$ff
			stx	Rectangle +2
			jmp	CallRoutine		;Rectangle aufrufen.

;*** GEOS-Menü beenden.
.EXIT_MENU_GEOS		jsr	RecoverAllMenus		;Menüs löschen.
			jsr	CLOSE_MENU		;Vektoren zurücksetzen.
			jmp	UPDATE_GD_CORE		;Variablen sichern.

;*** Größe für Menü berechnen.
;Übergabe: r0  = Zeiger auf Menü-Tabelle.
;          r5L = Breite.
;
;Hinweis: Das Menü wird dabei auf
;ganze CARDs ab-/aufgerundet um die
;Farb-CARDs am C64 nutzen zu können.
.MENU_SET_SIZE		ldy	#$06			;Anzahl Menü-Einträge einlesen.
			lda	(r0L),y
			and	#%00001111

			tay				;Höhe für Menü berechnen.
			lda	#$02
::1			clc
			adc	#14
			dey
			bne	:1

			ora	#%00000111		;Untere Kante auf volle CARDs
			sta	r5L			;aufrunden.

			lda	#MAX_AREA_WIN_Y -1
			sec
			sbc	r5L
			cmp	mouseYPos		;Y-Position für Menü ermitteln.
			bcc	:4			;Standard = Mausposition. Wenn
			lda	mouseYPos		;Menü ausserhalb Bildschirm, dann
							;Y-Position korrigieren.
::4			and	#%11111000		;Obere Kante auf ganze CARDs
			sta	r2L			;abrunden.
			clc
			adc	r5L
			sta	r2H

			sec				;X-Position für Menü ermitteln.
			lda	#< MAX_AREA_WIN_X -1
			sbc	r5H
			sta	r3L
			lda	#> MAX_AREA_WIN_X -1
			sbc	#$00
			sta	r3H

			CmpW	r3,mouseXPos		;Standard = Mausposition. Wenn
			bcc	:5			;Menü ausserhalb Bildschirm, dann
			MoveW	mouseXPos,r3		;X-Position korrigieren.

::5			clc				;Linke Kante auf volle CARDS
			lda	r3L			;abrunden, rechte Kante auf volle
			and	#%11111000		;CARDs aufrunden.
			sta	r3L
			adc	r5H
			sta	r4L
			lda	r3H
			adc	#$00
			sta	r4H

			ldy	#$05			;Größe für Menü in
::6			lda	r2,y			;Menüdaten kopieren.
			sta	(r0L),y
			dey
			bpl	:6
			rts

;*** PopUp-Menü beenden.
.EXIT_POPUP_MENU	php
			sei
			clc
			jsr	StartMouseMode
			cli

;--- Hinweis:
;Warten bis Maustaste nicht mehr
;gedrückt. Führt sonst zu Problemen
;bei der Tastaturabfrage.
			jsr	waitNoMseKey		;Warten bis keine M-Taste gedrückt.

			plp

			jsr	RecoverAllMenus		;Menüs löschen.
			jsr	CLOSE_MENU		;Vektoren zurücksetzen.
			jmp	UPDATE_GD_CORE		;Variablen sichern.

;*** PopUp-Fenster für DeskTop-Eigenschaften.
:PM_PROPERTIES		jsr	WM_HIDEWIN_OFF		;"Fenster ausblenden" deaktivieren.

			jsr	AL_FIND_ICON		;AppLink-Icons suchen.
			txa				;Wurde AppLink angeklickt?
			bne	:dtop			; => Nein, weiter...

;--- Rechter Mausklick auf AppLink.
::alink			MoveB	r13H,AL_CNT_FILE
			MoveW	r14 ,AL_VEC_FILE
			MoveW	r15 ,AL_VEC_ICON

			lda	#GMNU_ALINK		;Zeiger auf AppLink-Menü setzen.
			b $2c

;--- Rechter Mausklick auf DeskTop.
::dtop			lda	#GMNU_DTOP		;Zeiger auf DeskTop-Menü setzen.
			jmp	LdDTopMod		;Menü nachladen.

;*** PopUp-Fenster für Datei-Eigenschaften.
:PM_FILE		lda	#$00
			sta	drvUpdFlag		;Fenster nicht aktualisieren.
			sta	drvUpdSDir +0		;Kein neues Verzeichnis setzen.
			sta	drvUpdSDir +1
			sta	drvUpdMode		;Laufwerksmodus nicht ändern.

			lda	WM_DATA_MAXENTRY
			sta	fileEntryCount		;Max.Dateianzahl zwischenspeichern.

			lda	WM_TITEL_STATUS		;Rechtsklick/Titel angeklickt?
			beq	:window			; => Nein, weiter...

;--- Rechter Mausklkick auf Titelzeile.
::title			lda	#GMNU_TITLE
			jmp	LdDTopMod

;--- Befehlsmenü aufrufen?
::window		php				;Tastaturabfrage:
			sei				;CBM + Rechter Mausklick?
			ldx	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA
			lda	#%01111111
			sta	cia1base +0
			lda	cia1base +1
			stx	CPU_DATA
			plp

			and	#%00100000		;Rechter Mausklick = CBM-Menü?
			beq	:cbmcom			; => Nein, weiter...

;--- Mausklick auf Fensterinhalt.
			ldx	WM_WCODE		;Fenster-Nummer einlesen.
			lda	WIN_DATAMODE,x		;Partitionsauswahl aktiv?
			bmi	:drive			; => Ja, Keine Dateiauswahl...

			jsr	WM_TEST_ENTRY		;Icon angeklickt?
			bcs	:fileslct		; => Ja, weiter...

;--- Rechter Mausklick auf Fenster.
::drive			lda	#GMNU_DISK		;Laufwerk-Menü anzeigen.
			b $2c

;--- CBM-Menü anzeigen.
::cbmcom		lda	#GMNU_CBMCOM		;CBM-Tools anzeigen.
			jmp	LdDTopMod

;--- Rechter Mausklick auf Datei-Icon.
::fileslct		stx	fileEntryPos		;Eintrag-Nr. zwischenspeichern.

			stx	r0L			;Eintrag-Nr. für Berechnung

			ldx	#r0L			;Zeiger auf Dateieintrag
			jsr	WM_SETVEC_ENTRY		;berechnen.

			ldy	#$02
			lda	(r0L),y			;Dateityp-Byte einlesen.
			cmp	#GD_MORE_FILES		;"Weitere Dateien"?
			beq	:exit			; => Ja, Ende...

;			PushW	r0			;Zeiger auf aktuelle Datei sichern.
			MoveW	r0,fileEntryVec

			jsr	FILE_r14_SLCT		;Aktuelle Datei unter Mauszeiger
							;im Speicher und am Bildschirm
							;auswählen (":r0" nicht verändern!)

			jsr	SET_POS_CACHE		;Zeiger auf Datei im Cache.

			MoveW	r14,r1			;Cache aktualisieren.
			LoadW	r2,32
			lda	r12H
			sta	r3L
			jsr	StashRAM

;			PopW	fileEntryVec		;Zeiger auf Datei zurücksetzen.

			ldx	WM_WCODE		;Fenster-Nummer einlesen.
			lda	WIN_DATAMODE,x		;Partitionsauswahl aktiv?
			beq	:file			; => Nein, weiter...

;--- SD2IEC-Menü anzeigen.
::dimage		lda	#GMNU_SD2IEC		;SD2IEC-Menü anzeigen.
			b $2c

;--- Datei-Menü anzeigen.
::file			lda	#GMNU_FILE		;Datei-Menü anzeigen.
			jmp	LdDTopMod

;--- Mausklick ignorieren.
::exit			plp
			rts

;*** Rechter Mausklick auf Arbeitsplatz.
:PM_MYCOMP		jsr	WM_TEST_ENTRY		;Eintrag angeklickt?
			bcc	:exit			; => Nein, Ende...

			stx	MyCompEntry

			jsr	WM_HIDEWIN_OFF		;"Fenster ausblenden" deaktivieren.

			lda	#GMNU_MYCOMP		;Zeiger auf Menü-Daten setzen.
			jmp	LdDTopMod		;Menü nachladen.

::exit			rts
