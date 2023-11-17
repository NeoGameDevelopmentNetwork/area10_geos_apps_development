; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** PopUp-Menü öffnen.
:OPEN_MENU_POPUP	jsr	OPEN_MENU_GETDAT	;Zeiger auf PopUp-Menu-Daten.
			jmp	OPEN_MENU

;*** GEOS-Menü öffnen.
:OPEN_MENU_GEOS		LoadW	r0,MENU_DATA_GEOS	;Zeiger auf Menü-Daten setzen.
			jmp	OPEN_MENU

;*** Fenster-Menü öffnen.
:OPEN_MENU_SCRN		LoadW	r0,MENU_DATA_SCRN	;Zeiger auf Menü-Daten setzen.

;*** Farbe setzen und PullDown-Menü öffnen.
;    Übergabe: r0 = Zeiger auf Menüdaten.
:OPEN_MENU		jsr	DoneWithWM		;Fenster-Abfrage abschalten.

			ClrW	keyVector		;Tastaturabfrage löschen.

			jsr	WM_NO_MARGIN		;Textgrenzen löschen.
			jsr	WM_SAVE_BACKSCR		;Aktuellen Bildschirm speichern.

			jsr	OPEN_MENU_SETCOL	;Farbe für Menü setzen.

			jsr	UpdateMenuData		;Menütexte aktualisieren.

			lda	#$01
			jsr	DoMenu			;Menü aktivieren.

;*** Menü-Vektoren setzen.
:OPEN_MENU_INIT		LoadW	appMain,DrawClock
			LoadW	RecoverVector,:1	;Eigene RecoverRectangle-Routine.
			LoadW	mouseFaultVec,:2	;Eigene Mausabfrage setzen.
			rts

;--- Ersatz für RecoverRectangle.
::1			LoadW	r10,GD_BACKSCR_BUF
			LoadW	r11,GD_BACKCOL_BUF
			lda	GD_SYSDATA_BUF
			jmp	WM_LOAD_AREA

;--- Mausabfrage.
::2			lda	faultData		;Hat Mauszeiger aktuelles Menü
			and	#%00001000		;verlassen ?
			bne	:3			;Ja, ein Menü zurück.
			ldx	#%10000000
			ldy	#%11000000
::3			txa				;Hat Mauszeiger obere/linke
			and	faultData		;Grenze verlassen ?
			bne	:4			;Ja, ein Menü zurück.
			tya

::4			lda	menuNumber		;Hauptmenü aktiv ?
			beq	:5			;Ja, übergehen.
			jsr	OPEN_PREV_MENU		;Ein Menü zurück.
			jmp	OPEN_MENU_INIT

::5			jsr	RecoverAllMenus		;Menüs löschen.
			;jmp	CLOSE_MENU		;Vektoren zurücksetzen.

;*** Vektoren zurücksetzen.
:CLOSE_MENU		lda	#$00
			sta	mouseFaultVec +0	;Mausabfrage löschen.
			sta	mouseFaultVec +1
			sta	RecoverVector +0	;RecoverRectangle löschen.
			sta	RecoverVector +1

			lda	mouseOn			;Menü-Flag löschen.
			and	#%10111111
			sta	mouseOn

			jmp	InitWinMseKbd		;Fenster-/Maus-/Tastatur starten.

;*** Zeiger auf Menü-Initialisierung setzen.
;    Übergabe: XAKKU/XREG = Zeiger auf Menüdaten.
:MENU_SETINT		sta	r0L
			stx	r0H
:MENU_SETINT_r0		LoadW	appMain,OPEN_MENU_INIT
			;jmp	OPEN_MENU_SETCOL

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

;*** Informationen für aktuelles Menü einlesen.
;    Übergabe: XREG = Menü-Nr.
:OPEN_MENU_GETDAT	lda	PDWidth,x		;Menü-Breite einlesen.
			sta	r5H

			txa				;Zeiger auf Tabelle mit den
			asl				;Menüdaten einlesen.
			asl
			tax
			lda	PDVec +0,x
			sta	r0L
			lda	PDVec +1,x
			sta	r0H

;--- Größe für Menü berechnen.
;Hinweis: Das Menü wird dabei auf
;ganze CARDs ab-/aufgerundet um die
;Farb-CARDs am C64 nutzen zu können.
			ldy	#$06			;Anzahl Menü-Einträge einlesen.
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

;*** Menüdaten für PopUp-Menü anpassen.
:UpdateMenuData		ldx	WM_WCODE		;Fenster-Nr. einlesen.

			ldy	#" "			;Applink: Titel anzeigen.
			lda	GD_LNK_TITLE
			beq	:1
			ldy	#"*"
::1			sty	PT108 +1

			ldy	#" "			;AppLink: Gesperrt.
			lda	GD_LNK_LOCK
			beq	:2
			ldy	#"*"
::2			sty	PT055 +1

			ldy	#" "			;Desktop: Hintergrundbild zeigen.
			lda	sysRAMFlg
			and	#%00001000
			beq	:3
			ldy	#"*"
::3			sty	PT054 +1

			ldy	#" "			;Anzeige: Größe in KByte/Blocks.
			lda	WMODE_VSIZE,x
			bpl	:4
			ldy	#"*"
::4			sty	PT114 +1		;Extra Byte "BOLDON" überspringen!

			ldy	#" "			;Anzeige: Icons/Text.
			lda	WMODE_VICON,x
			bpl	:5
			ldy	#"*"
::5			sty	PT115 +1

			ldy	#" "			;Anzeige: Details anzeigen.
			lda	WMODE_VINFO,x
			bpl	:6
			ldy	#"*"
::6			sty	PT116 +1

			ldy	#" "			;Anzeige: Ausgabe bremsen.
			lda	GD_SLOWSCR
			bpl	:7
			ldy	#"*"
::7			sty	PT117 +1

			ldy	#" "			;Anzeige: Dateifilter.
			lda	WMODE_FILTER,x
			beq	:8
			ldy	#"*"
::8			sty	PT120 +1

			rts

;*** Menü "Fenster" verlassen.
:EXIT_MENU_SCRN		pha
			jsr	RecoverAllMenus		;Menüs löschen.
			jsr	CLOSE_MENU		;Vektoren zurücksetzen.
			jsr	UPDATE_GD_CORE		;Variablen sichern.
			pla

;--- Mehr als drei Menüeinträge.
			cmp	#MAX_ENTRY_SCRN		;Menü-Eintrag gültig?
			bcs	:1			; => Nein, Ende...

			asl				;Zeiger auf Routine für
			tay				;Menüeintrag einlesen.
			lda	:vecRoutTab +0,y
			ldx	:vecRoutTab +1,y
			jmp	CallRoutine		;Menüroutine aufrufen.
::1			rts

::vecRoutTab		w OpenMyComputer		;Arbeitsplatz öffnen.
			w PF_OPEN_DRV_A
			w PF_OPEN_DRV_B
			w PF_OPEN_DRV_C
			w PF_OPEN_DRV_D
			w WM_FUNC_SORT			;Fenster überlappend.
			w WM_FUNC_POS			;Fenster nebeneinander.
			w WM_CLOSE_ALL_WIN		;Alle Fenster schließen.

;*** Menü "Programme" aktivieren.
:OPEN_MENU_APPL		lda	#<MENU_DATA_APPL
			ldx	#>MENU_DATA_APPL
			jmp	MENU_SETINT

;*** Menü "Programme" verlassen.
:EXIT_MENU_APPL		pha
			jsr	RecoverAllMenus		;Menüs löschen.
			jsr	CLOSE_MENU		;Vektoren zurücksetzen.
			jsr	UPDATE_GD_CORE		;Variablen sichern.
			pla

;--- Mehr als drei Menüeinträge.
			cmp	#MAX_ENTRY_APPL		;Menü-Eintrag gültig?
			bcs	:1			; => Nein, Ende...

			asl				;Zeiger auf Routine für
			tay				;Menüeintrag einlesen.
			lda	:vecRoutTab +0,y
			ldx	:vecRoutTab +1,y
			jmp	CallRoutine		;Menüroutine aufrufen.
::1			rts

::vecRoutTab		w MOD_OPEN_APPL			;Anwendungen.
			w MOD_OPEN_AUTO			;Autostart-Programme.
			w MOD_OPEN_DA			;Hilfsmittel.

;*** Menü "Dokumente" aktivieren.
:OPEN_MENU_DOCS		lda	#<MENU_DATA_DOCS
			ldx	#>MENU_DATA_DOCS
			jmp	MENU_SETINT

;*** Menü "Dokumente" verlassen.
:EXIT_MENU_DOCS		pha
			jsr	RecoverAllMenus		;Menüs löschen.
			jsr	CLOSE_MENU		;Vektoren zurücksetzen.
			jsr	UPDATE_GD_CORE		;Variablen sichern.
			pla

;--- Mehr als drei Menüeinträge.
			cmp	#MAX_ENTRY_DOCS		;Menü-Eintrag gültig?
			bcs	:1			; => Nein, Ende...

			asl				;Zeiger auf Routine für
			tay				;Menüeintrag einlesen.
			lda	:vecRoutTab +0,y
			ldx	:vecRoutTab +1,y
			jmp	CallRoutine		;Menüroutine aufrufen.
::1			rts

::vecRoutTab		w MOD_OPEN_DOCS			;Alle Dokumente.
			w MOD_OPEN_WRITE		;geoWrite Dokumente.
			w MOD_OPEN_PAINT		;geoPaint Dokumente.

;*** Menü "Beenden" aktivieren.
:OPEN_MENU_EXIT		lda	#<MENU_DATA_EXIT
			ldx	#>MENU_DATA_EXIT
			jmp	MENU_SETINT

;*** Menü "Beenden" verlassen.
:EXIT_MENU_EXIT		pha
			jsr	RecoverAllMenus		;Menüs löschen.
			jsr	CLOSE_MENU		;Vektoren zurücksetzen.
			jsr	UPDATE_GD_CORE		;Variablen sichern.
			pla

;--- Mehr als drei Menüeinträge.
			cmp	#MAX_ENTRY_EXIT		;Menü-Eintrag gültig?
			bcs	:1			; => Nein, Ende...

			asl				;Zeiger auf Routine für
			tay				;Menüeintrag einlesen.
			lda	:vecRoutTab +0,y
			ldx	:vecRoutTab +1,y
			jmp	CallRoutine		;Menüroutine aufrufen.
::1			rts

::vecRoutTab		w MOD_OPEN_EXITG		;Nach GEOS beenden.
			w MOD_OPEN_EXIT64		;Nach BASIC beenden.
			w MOD_OPEN_EXITB		;BASIC-Programm starten.

;*** Menü "Einstellungen" aktivieren.
:OPEN_MENU_SETUP	lda	#<MENU_DATA_SETUP
			ldx	#>MENU_DATA_SETUP
			jmp	MENU_SETINT

;*** Menü "Einstellungen" verlassen.
:EXIT_MENU_SETUP	pha
			jsr	RecoverAllMenus		;Menüs löschen.
			jsr	CLOSE_MENU		;Vektoren zurücksetzen.
			pla

;--- Mehr als drei Menüeinträge.
			cmp	#MAX_ENTRY_SETUP	;Menü-Eintrag gültig?
			bcs	:1			; => Nein, Ende...

			asl				;Zeiger auf Routine für
			tay				;Menüeintrag einlesen.
			lda	:vecRoutTab +0,y
			ldx	:vecRoutTab +1,y
			jmp	CallRoutine		;Menüroutine aufrufen.
::1			rts

::vecRoutTab		w MENU_SETUP_EDIT		;Einstellungen -> GEOS.
			w MOD_OPTIONS			;Einstellungen -> GeoDesk.
			w MOD_SAVE_CONFIG		;Konfiguration speichern.
			w MENU_SETUP_PRNT		;Drucker wechseln.
			w MENU_SETUP_INPT		;Eingabe wechseln.
			w MOD_COLSETUP			;Systemfarben ändern.
			w MOD_OPEN_BACKSCR		;Hintergrundbild wechseln.
			w SUB_LNK_SV_DATA		;AppLinks speichern.
			w MOD_SYSTIME			;Systemzeit setzen.

;*** Info anzeigen.
:OPEN_INFO		jsr	RecoverAllMenus		;Menüs löschen.
			jsr	CLOSE_MENU		;Vektoren zurücksetzen.
			jmp	SUB_SHOWHELP		;Variablen sichern.

;*** Untermenüs aus Kontextmenü öffnen.
:OPEN_MENU_VOPT		ldx	#11
			b $2c
:OPEN_MENU_DISK		ldx	#12
			b $2c
:OPEN_MENU_FILTER	ldx	#14
			b $2c
:OPEN_MENU_SORT		ldx	#15
			b $2c
:OPEN_MENU_SELECT	ldx	#16
			jsr	OPEN_MENU_GETDAT
			jmp	MENU_SETINT_r0

;*** PopUp-Menü beenden.
:PExit_000		ldx	#0
			b $2c
:PExit_001		ldx	#1
			b $2c
:PExit_002		ldx	#2
			b $2c
:PExit_003		ldx	#3
			b $2c
:PExit_004		ldx	#4
			b $2c
:PExit_005		ldx	#5
			b $2c
:PExit_006		ldx	#6
			b $2c
:PExit_007		ldx	#7
			b $2c
:PExit_008		ldx	#8
			b $2c
:PExit_009		ldx	#9
			b $2c
:PExit_010		ldx	#10
			b $2c
:PExit_011		ldx	#11
			b $2c
:PExit_012		ldx	#12
			b $2c
:PExit_013		ldx	#13
			b $2c
:PExit_014		ldx	#14
			b $2c
:PExit_015		ldx	#15
			b $2c
:PExit_016		ldx	#16
			b $2c
:PExit_017		ldx	#17
			b $2c
:PExit_018		ldx	#18
			b $2c
:PExit_019		ldx	#19
			b $2c
:PExit_020		ldx	#20
			b $2c
:PExit_021		ldx	#21
			pha
			txa
			pha

			php
			sei
			clc
			jsr	StartMouseMode
			cli

;--- Hinweis:
;Warten bis Maustaste nicht mehr
;gedrückt. Führt sonst zu Problemen
;bei der Tastaturabfrage.
			jsr	WM_WAIT_NOMSEKEY	;Warten bis keine M-Taste gedrückt.

			plp

			jsr	RecoverAllMenus		;Menüs löschen.
			jsr	CLOSE_MENU		;Vektoren zurücksetzen.

			pla				;Zeiger auf Funktionstabelle
			asl				;einlesen.
			asl
			tax
			lda	PDVec +2,x
			sta	r0L
			lda	PDVec +3,x
			sta	r0H

			pla				;Adresse Menüroutine einlesen.
			asl
			tay
			iny
			lda	(r0L),y
			tax
			dey
			lda	(r0L),y
			jmp	CallRoutine		;Menüroutine aufrufen.

;*** PopUp-Fenster für DeskTop-Eigenschaften.
:PM_PROPERTIES		jsr	AL_FIND_ICON
			txa
			bne	:3

			MoveB	r13H,AL_CNT_FILE
			MoveW	r14 ,AL_VEC_FILE
			MoveW	r15 ,AL_VEC_ICON

			ldy	#LINK_DATA_TYPE
			lda	(r14L),y
			cmp	#AL_TYPE_FILE
			beq	:4
			cmp	#AL_TYPE_MYCOMP
			beq	:5
			cmp	#AL_TYPE_SUBDIR
			beq	:7
			cmp	#AL_TYPE_PRNT
			beq	:6
			cmp	#AL_TYPE_DRIVE
			beq	:1
			rts

;--- Rechter Mausklick auf AppLink/Laufwerk.
::1			ldy	#LINK_DATA_DRIVE	;Laufwerksadresse einlesen.
			lda	(r14L),y
			tax
			lda	RealDrvMode -8,x	;Laufwerk CMD/SD2IEC?
			and	#SET_MODE_PARTITION!SET_MODE_SD2IEC
			beq	:2			; => Nein, keine Partitionsauswahl.

;--- Rechter Mausklick auf AppLink/Laufwerk/CMD/SD.
			ldx	#4
			b $2c

;--- Rechter Mausklick auf AppLink/Laufwerk/Std.
::2			ldx	#18
			b $2c

;--- Rechter Mausklick auf DeskTop.
::3			ldx	#0
			b $2c

;--- Rechter Mausklick auf AppLink/Datei.
::4			ldx	#1
			b $2c

;--- Rechter Mausklick auf AppLink/Arbeitsplatz.
::5			ldx	#2
			b $2c

;--- Rechter Mausklick auf AppLink/Drucker.
::6			ldx	#3
			b $2c

;--- Rechter Mausklick auf AppLink/Verzeichnis.
::7			ldx	#10
			jmp	OPEN_MENU_POPUP

;*** PopUp-Fenster für Datei-Eigenschaften.
:PM_FILE		ldx	WM_WCODE
			lda	WM_TITEL_STATUS		;Rechtsklick/Titel angeklickt?
			beq	:window			; => Nein, weiter...

;--- Rechter Mausklkick auf Titelzeile.
;			ldx	WM_WCODE
			lda	WIN_DATAMODE,x		;CMD-Partitionsauswahl aktiv?
			bmi	:4			; => Ja, Ende...
			bne	:2			; => SD2IEC-DiskImage-Browser.

;--- Dateimodus.
;			ldx	WM_WCODE
			ldy	WIN_DRIVE,x		;Laufwerksadresse einlesen.

			lda	RealDrvMode -8,y	;CMD/SD2IEC/Native ?
			and	#SET_MODE_PARTITION!SET_MODE_SD2IEC!SET_MODE_SUBDIR
			beq	:5			; => Nein, Ende...

			cmp	#SET_MODE_PARTITION
			beq	:4			; => CMD 41/71/81.
			cmp	#SET_MODE_SD2IEC
			beq	:4			; => SD2IEC 41/71/81.

			cmp	#SET_MODE_PARTITION!SET_MODE_SUBDIR
			beq	:3			; => CMD Native.
			cmp	#SET_MODE_SD2IEC!SET_MODE_SUBDIR
			beq	:3			; => SD2IEC Native.

;			cmp	#SET_MODE_SUBDIR
;			beq	:1			; => Nicht-CMD/Native.

;--- NativeMode-Laufwerke.
::1			ldx	#9			;Verzeichnis wechseln.
			b $2c

;--- SD2IEC/Browser.
::2			ldx	#20			;SD2IEC/DiskImage-Browser.
			b $2c

;--- CMD-Native oder SD2IEC-Native.
::3			ldx	#17			;Partition/Verzeichnis wechseln.
			jmp	OPEN_MENU_POPUP

;--- CMD-41/71/81 oder SD2IEC-41/71/81-Laufwerk.
::4			jmp	PF_SWAP_DSKIMG		;Partition wechseln.

;--- Rechter Maisklick auf Titel nicht möglich.
::5			rts

;--- Mausklick auf Fensterinhalt.
::window		lda	WIN_DATAMODE,x		;Partitionsauswahl aktiv?
			bne	:winback		; => Ja, weiter...

			jsr	WM_TEST_ENTRY		;Icon angeklickt?
			bcc	:winback		; => Nein, weiter...

;--- Rechter Mausklick auf Datei-Icon.
::file			stx	fileEntryPos +0		;Eintrag-Nr. zwischenspeichern.
if MAXENTRY16BIT = TRUE
			sty	fileEntryPos +1
endif

			stx	r0L			;Eintrag-Nr. für Berechnung
if MAXENTRY16BIT = TRUE
			sty	r0H			;Adresse zwischenspeichern.
endif

			ldx	#r0L			;Zeiger auf Dateieintrag
			jsr	SET_POS_RAM		;berechnen.

			ldy	#$02
			lda	(r0L),y			;Dateityp-Byte einlesen.
			cmp	#GD_MORE_FILES		;"Weitere Dateien"?
			beq	:5			; => Ja, Ende...

			pha

			jsr	FILE_r14_SLCT		;Aktuelle Datei unter Mauszeiger
							;im Speicher und am Bildschirm
							;auswählen (":r0" nicht verändern!)

			MoveW	r0,fileEntryVec		;Zeiger auf aktuelle Datei sichern.

			pla
			beq	:6

			ldx	#6			;Standard-Dateimenü.
			b $2c
::6			ldx	#21			;Menü für gelöschte Dateien.
			jmp	OPEN_MENU_POPUP		;PopUp-Menü öffnen.

;--- Rechter Mausklick auf Fenster-Hintergrund.
::winback		ldx	WM_WCODE
			lda	WIN_DATAMODE,x		;Partitionsauswahl aktiv?
			bne	:part			; => Ja, weiter...

::drive			ldx	#7			;PopUp-Menü Laufwerk.
			b $2c
::part			ldx	#11			;PopUp-Menü Partitionsauswahl.
			jmp	OPEN_MENU_POPUP

;*** Rechter Mausklick auf Arbeitsplatz.
:PM_MYCOMP		jsr	WM_TEST_ENTRY		;Eintrag angeklickt?
			bcc	:exit			; => Nein, Ende...

			stx	MyCompEntry +0
if MAXENTRY16BIT = TRUE
			sty	MyCompEntry +1
endif

			cpx	#$04			;Rechtsklick auf Drucker?
			beq	:print			; => Ja, weiter...
			cpx	#$05			;Rechtsklick auf Eingabegerät?
			beq	:input			; => Ja, weiter...
			bcs	:exit			; => Rechtsklick ungültig.

			lda	driveType,x		;Existiert Laufwerk?
			beq	:exit			; => Rechtsklick ungültig.
			lda	RealDrvMode,x		;Laufwerksmodus einlesen.
			and	#SET_MODE_PARTITION!SET_MODE_SD2IEC
			bne	:part			; => Nein, weiter...

::drive			ldx	#19			;PopUp-Menü für Laufwerk.
			b $2c
::part			ldx	#8			;PopUp-Menü für Laufwerk.
			b $2c
::print			ldx	#5			;PopUp-Menü für Drucker.
			b $2c
::input			ldx	#13			;PopUp-Menü für Eingabegerät.
			jmp	OPEN_MENU_POPUP

::exit			rts
