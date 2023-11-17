; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;Routine:   MainBoot
;Funktion:  Einsprung aus BOOT-Routine:
;           -GeoDesk initialisieren.
;           -AppLinks einlesen.
;           -DeskTop zeichnen.
;           -TaskBar/Uhr zeichnen.
;           -Fenstermanager starten.
;           -Variablen speichern.
;******************************************************************************
:MainBoot		jsr	SUB_LNK_LD_DATA		;AppLink-Daten einlesen.

			jsr	ResetFontGD		;GeoDesk-Zeichensatz aktivieren.

			jsr	SET_TEST_CACHE		; => BAM testen/Cache oder Disk.

			LoadW	r0,WIN_DESKTOP
			jsr	WM_COPY_WIN_DATA	;DeskTop-Daten setzen.

			jsr	MainDrawDesktop		;DeskTop neu zeichnen.
			jsr	WM_SAVE_WIN_DATA	;Fensterdaten speichern.

			jsr	testDWinMode		;Auf DualFenster-Modus testen.

			jmp	UPDATE_GD_CORE		;GeoDesk-Systemvariablen speichern.
							;Damit stehen die Systemvariablen
							;auch nach einem RBOOT im Speicher.

;******************************************************************************
;Routine:   MainReBoot
;Funktion:  Einsprung über EnterDeskTop:
;           -GeoDesk initialisieren.
;           -Laufwerke testen.
;           -DeskTop zeichnen.
;           -TaskBar/Uhr zeichnen.
;           -Fenstermanager starten.
;           -Fenster neu zeichnen.
;******************************************************************************
:MainReBoot		jsr	ResetFontGD		;GeoDesk-Zeichensatz aktivieren.

			jsr	CheckWinStatus		;Laufwerke auf Gültigkeit testen.

;--- Geöffnete Fenster neu zeichnen.
			jsr	MainDrawDesktop		;DeskTop neu zeichnen.

			lda	#MAX_WINDOWS -1		;Zeiger auf letztes Fenster.
::1			pha
			tax
			lda	WM_STACK,x		;Fenster aktiv?
			beq	:2			; => MyComp... Weiter...
			bmi	:2			; => Nein, Weiter...

			sta	WM_WCODE
			jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

			jsr	OpenWinDrive		;Fensterlaufwerk öffnen.
			txa				;Fehler?
			bne	:2			; => Ja, Fenster schließen.

;--- HINWEIS:
;Diskette öffnen, da bei einem GEOS-
;ReBoot sonst die Disknamen nicht im
;Speicher stehen und Fenster dann ohne
;Disknamen neu aufgebaut werden.
			jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler?
			beq	:3			; => Nein, weiter...

;--- Fenster fehlerhaft, schließen.
			jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

			lda	WM_WCODE		;Fenster schließen.
			jsr	WM_CLOSE_WINDOW
			jmp	:2

;--- Partition- oder DiskImage gewechselt?
::3			ldx	WM_WCODE		;Fenster-Nr. einlesen.
			ldy	WIN_DRIVE,x		;Laufwerk aktiv?
			beq	:5			; => Nein, weiter...

			lda	RealDrvMode -8,y	;Laufwerksmodus einlesen.
			and	#SET_MODE_SD2IEC	;SD2IEC-Laufwerk?
			beq	:4			; => Nein, weiter...

;--- SD2IEC: Dateien/DiskImages einlesen.
			lda	WIN_DATAMODE,x		;Fenster-Modus einlesen.
			and	#%01000000		;DiskImage-Browser aktiv?
			beq	:4			; => Nein, weiter...

			jsr	GetDirHead		;BAM einlesen.
			txa				;Fehler?
			bne	:6			; => Ja, weiter...

			ldx	WM_WCODE		;Fenster-Nr. einlesen.
			lda	#$00			; => Diskette aktiv.
			sta	WIN_DATAMODE,x		;DiskImage-Browser-Modus löschen.

::6			jsr	SET_LOAD_DISK		;Dateien von Disk neu einlesen.
			jmp	:5

;--- BAM auf Veränderungen testen.
;Wenn verändert,dann Disk neu einlesen.
;Sonst aus Cache einlesen.
::4			jsr	SET_TEST_CACHE		; => BAM testen/Cache oder Disk.
							;Erforderlich damit bei Rückkehr
							;von GEOS/DeskTop beim neu zeichnen
							;der Fensters alle Dateien im
							;Speicher sind.

			jsr	UNSLCT_DIR_DATA		;Dateien im Fenster abwählen.

;--- Fenster zeichnen.
::5			jsr	WM_CALL_REDRAW		;Fenster zeichnen.
			jsr	WM_SAVE_WIN_DATA	;Fensterdaten aktualisieren.

::2			pla
			sec
			sbc	#$01			;Alle Fenster gezeichnet?
			bpl	:1			; => Nein, weiter...

			jsr	testDWinMode		;Auf DualFenster-Modus testen.

			jmp	SET_LOAD_CACHE		;GetFiles-Modus zurücksetzen.

;******************************************************************************
;Routine:   MainUpdate
;Funktion:  Einsprung aus Disk-/Dateifunktionen:
;           -DeskTop aus ScreenCache einlesen.
;           -TaskBar/Uhr zeichnen.
;           -Fenstermanager starten.
;           -Verzeichnis aus Cache einlesen.
;           -Datei-Auswahl aufheben.
;           -Fenster aus ScreenBuffer laden.
;           -Oberstes Fenster neu zeichnen.
;******************************************************************************
:MainUpdate		jsr	WM_LOAD_BACKSCR		;Fenster +ApplInks +DeskTop laden.

			jsr	updateOtherWin		;Andere Fenster ggf. aktualisieren.

			jsr	RESET_DIR_DATA		;Verzeichnis-Daten einlesen.
			jsr	WM_UPDATE		;Oberstes Fenster aktualisieren.

			jsr	testDWinMode		;Auf DualFenster-Modus testen.

			jsr	ReStartTaskBar		;TaskBar starten.

			jsr	InitWinMseKbd		;Fenster-/Maus-/Tastatur starten.
			jmp	SUB_SYSINFO		;Systeminfo anzeigen.

;******************************************************************************
;Routine:   InitWinMseKbd
;Funktion:  Fenster-/Maus-/Tastaturabfrage initialisieren.
;******************************************************************************
:InitWinMseKbd		clc
			jsr	StartMouseMode		;Mausabfrage starten.
			jsr	WM_NO_MOUSE_WIN		;Fenstergrenzen zurücksetzen.
			jsr	InitShortCuts		;Tastenabfrage installieren.
			jmp	InitForWM		;Fenstermanager wieder aktivieren.

;******************************************************************************
;Routine:   MainUpdateST
;Funktion:  Einsprung aus Kopierfunktionen:
;           -DeskTop zeichnen.
;           -TaskBar/Uhr zeichnen.
;           -Fenstermanager starten.
;           -Verzeichnis aus Cache einlesen.
;           -Datei-Auswahl aufheben.
;           -Fenster aus ScreenBuffer laden.
;           -Source/Target Fenster neu laden/zeichnen.
;            Nur wenn GD_RELOAD_DIR gesetzt, ansonsten
;            Dateien aus Disk-Cache einlesen.
;******************************************************************************
:MainUpdateWin		jsr	WM_LOAD_BACKSCR		;Fenster +AppLinks +DeskTop laden.

			lda	#MAX_WINDOWS -1		;Zeiger auf letztes Fenster.
::1			pha
			tax
			lda	WM_STACK,x		;Fenster aktiv?
			beq	:2			; => DeskTop, weiter...
			bpl	:10			; => Fenster, weiter...
::2			jmp	:60			;Weiter mit nächstem Fenster.

;--- Auf Arbeitsplatz testen.
::10			tax

			cpx	WM_MYCOMP		;Arbeitsplatz-Fenster?
			bne	:11			; => Nein, weiter...

;--- Arbeitsplatz aktualisieren.
;Die Routine wird auch nach DiskCopy
;aufgerufen. Da sich hier der DiskName
;ändert -> Arbeitsplatz aktualisieren.
			stx	WM_WCODE		;Fenster-Nr. setzen und
			jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.
			jsr	WM_CALL_REDRAW		;Target-Fenster neu zeichnen.
			jsr	WM_SAVE_WIN_DATA	;Fensterdaten aktualisieren.
			jmp	:60			;Weiter mit nächstem Fenster.

;--- Quell-/Zielfenster überspringen.
::11			cpx	winSource		;Fenster Quell-Laufwerk?
			beq	:12			; => Ja, überspringen.
			cpx	winTarget		;Fenster Ziel-Laufwerk?
			bne	:20			; => Nein, weiter...
::12			jmp	:60			;Weiter mit nächsten Fenster.

;--- Auf Source-Laufwerk testen.
::20			lda	WIN_DRIVE,x		;Laufwerk für Fenster einlesen.
			beq	:50			; => Kein Laufwerk, Screen laden.

			cmp	sysSource		;Source-Laufwerk?
			bne	:40			; => Nein, weiter...
			ldy	WIN_PART,x
			cpy	sysSource +1		;Source-Partition?
			bne	:40			; => Nein, weiter...

			ldy	WIN_SDIR_T,x		;Tr/Se für Verzeichnis vergleichen.
			cpy	sysSource +2		;Bei gleichem Verzeichnis Dateien
			bne	:31			;von Disk neu einlesen.
			ldy	WIN_SDIR_T,x		;Ist das Verzeichnis ein anderes,
			cpy	sysSource +3		;dann Dateien aus Cache laden.
			bne	:31

::30			lda	#GD_LOAD_DISK		;Verzeichnis neu einlesen.
			b $2c
::31			lda	#GD_LOAD_CACHE		;Verzeichnis aus Cache einlesen.
			jsr	updateDrvWin		;Fensterinhalt neu zeichnen.
			jmp	:60			;Weiter mit nächstem Fenster.

;--- Auf Target-Laufwerk testen.
::40			cmp	sysTarget		;Target-Laufwerk?
			bne	:50			; => Nein, weiter...
			ldy	WIN_PART,x
			cpy	sysTarget +1		;Target-Partition?
			bne	:50			; => Nein, weiter...

			ldy	WIN_SDIR_T,x		;Tr/Se für Verzeichnis vergleichen.
			cpy	sysTarget +2		;Bei gleichem Verzeichnis Dateien
			bne	:31			;von Disk neu einlesen.
			ldy	WIN_SDIR_T,x		;Ist das Verzeichnis ein anderes,
			cpy	sysTarget +3		;dann Dateien aus Cache laden.
			bne	:31
			beq	:30			;Dateien von Disk neu laden.

;--- Fenster aus ScreenBuffer laden.
::50			stx	WM_WCODE		;Fenster-Nr. setzen und
			jsr	WM_LOAD_SCREEN		;Fenster aus ScreenBuffer laden.

;--- Nächstes Fenster...
::60			pla
			sec
			sbc	#$01			;Alle Fenster gezeichnet?
			bcc	:61			; => Ja, Ende...
			jmp	:1			;Weiter mit nächstem Fenster.

;--- Quell-/Ziel-Fenster aktualisieren.
::61			bit	GD_OPEN_TARGET		;Ziel-Fenster aktivieren?
			bmi	:81			; => Ja, weiter...

;--- Ziel/Quelle aktiualisieren.
::71			ldx	winTarget		;Quelle und Ziel gleich?
			cpx	winSource		;(z.B. Dateien duplizieren)
			beq	:72			; => Ja, weiter...
			lda	updateTarget		;Update-Modus für Fenster.
			jsr	updateDrvWin		;Ziel-Laufwerk aktualisieren.

::72			lda	winSource		;Quell-Fenster nach oben sortieren.
			beq	:90
			jsr	WM_WIN2TOP

			ldx	winSource		;Fenster-Nr. Quell-Laufwerk.
			lda	updateSource		;Update-Modus für Fenster.
			jsr	updateDrvWin		;Quell-Laufwerk aktualisieren.
			jmp	:90

;--- Quelle/Ziel aktiualisieren.
::81			ldx	winSource		;Quelle und Ziel gleich?
			beq	:83			; => Kein Fenster, weiter...
			cpx	winTarget		;(z.B. Dateien duplizieren)
			beq	:82			; => Ja, weiter...
			lda	updateSource		;Update-Modus für Fenster.
			jsr	updateDrvWin		;Quell-Laufwerk aktualisieren.

::82			lda	winTarget		;Ziel-Fenster nach oben sortieren.
			beq	:90
			jsr	WM_WIN2TOP

::83			ldx	winTarget		;Fenster-Nr. Ziel-Laufwerk.
			beq	:90			; => Kein Fenster, weiter...
			lda	updateTarget		;Update-Modus für Fenster.
			jsr	updateDrvWin		;Ziel-Laufwerk aktualisieren.

;--- Rückkehr zum Fenstermanager.
::90			lda	#$00			;Source/Target-Daten löschen.
			sta	sysSource
			sta	winSource
			sta	sysTarget
			sta	winTarget

;			jmp	MainReStart		;FensterManager starten.

;******************************************************************************
;Routine:   MainReStart
;Funktion:  Rückkehr zum FensterManager:
;           -TaskBar/Uhr aktivieren.
;           -Fenstermanager starten.
;******************************************************************************
:MainReStart		jsr	RESET_DIR_DATA		;Verzeichnis-Daten einlesen.
							;Erforderlich z.B. für Konfiguration
							;speichern, das bei geöffnetem
							;Dateifenster die Dateiliste mit
							;anderen Daten überschreibt.

			jsr	ReStartTaskBar		;TaskBar starten.

			jsr	InitWinMseKbd		;Fenster-/Maus-/Tastatur starten.
			jmp	SUB_SYSINFO		;Systeminfo anzeigen.

;******************************************************************************
;Routine:   MainInitWM
;Funktion:  Rückkehr zum FensterManager:
;           -DeskTop zeichnen.
;           -TaskBar/Uhr zeichnen.
;           -Fenstermanager starten.
;           -Verzeichnis aus Cache einlesen.
;           -Alle Fenster aus ScreenBuffer laden.
;******************************************************************************
:MainInitWM		jsr	MainDrawDesktop		;DeskTop neu zeichnen.
			jmp	WM_DRAW_ALL_WIN		;Fenster aus ScreenBuffer laden.

;******************************************************************************
;Routine:   updateDrvWin
;Funktion:  Setzt Reload-Flag, Fenster-Nr. und zeichnet Fenster neu.
;           -Fenster aktivieren.
;           -Laufwerk aktivieren.
;           -Verzeichnis ins RAM kopieren.
;           -Fenster neu zeichnen.
;           -Fenster in ScreenBuffer speichern.
;           -Fensterdaten speichern.
;******************************************************************************
:updateDrvWin		sta	GD_RELOAD_DIR		;Reload-Flag setzen.

			stx	WM_WCODE		;Fenster-Nr. setzen und
			jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

			jsr	OpenWinDrive		;Fensterlaufwerk öffnen.
;--- HINWEIS:
;Hier sollte kein Fehler auftreten, da
;zuvor ja Dateien auf dieses Laufwerk
;kopiert bzw. eingelesen wurde.
;Sicherheitsabfrage.
			txa				;Fehler?
			beq	:1			; => Nein, weiter...

;--- HINWEIS:
;Fenster darf hier nicht geschlossen
;werden, da die Suchfunktion für die
;geänderten Fenster den Fenster-Stack
;abarbeitet, Der Stack sollte während
;der Suche nicht geändert werden.
;			lda	WM_WCODE		;Fenster schließen.
;			jmp	WM_CLOSE_WINDOW
;Fenster nicht schließen, sondern aus
;ScreenBuffer laden.
			jmp	WM_LOAD_SCREEN		;Fenster aus ScreenBuffer laden.

;--- HINWEIS:
;Verzeichnis aus Cache einlesen und
;Fensterinhalt neu zeichnen.
::1			jsr	getCacheData		;Verzeichnis aus Cache einlesen.

			jsr	WM_CALL_REDRAW		;Fenster neu zeichnen.
			jsr	WM_SAVE_SCREEN		;Fenster im Cache speichern.
			jmp	WM_SAVE_WIN_DATA	;Fensterdaten aktualisieren.

;******************************************************************************
;Routine:   testDWinMode
;Funktion:  Testet auf DualWin-Mode und öffnet Fenster.
;******************************************************************************
:testDWinMode		lda	GD_DUALWIN_MODE		;Zwei-Fenster-Modus aktiv?
			beq	exitDWinMode		; => Nein, Ende...

			lda	WM_WCOUNT_OPEN		;Anzahl offener Fenster einlesen.
			cmp	#3			;Mehr als zwei Fenster geöffnet?
			bcs	exitDWinMode		; => Ja, Ende...
			pha

			ldx	GD_DUALWIN_DRV2		;Wenn nur DeskTop oder max. ein
			ldy	#$01			;Fenster geöffnet:
			jsr	openDualWin		;Zweites Fenster öffnen.

			pla
			cmp	#1			;Nur DeskTop geöffnet?
			bne	:1			; => Nein, weiter...

			ldx	GD_DUALWIN_DRV1
			ldy	#$00
			jsr	openDualWin		;Erstes Fenster öffnen.

::1			jmp	clrStdWinSize

;******************************************************************************
;Routine:   switchDWinMode
;Funktion:  Wechelt zwischen DualWin-Mode ein/aus.
;******************************************************************************
:switchDWinMode		lda	GD_DUALWIN_MODE
			eor	#$ff
			sta	GD_DUALWIN_MODE
:exitDWinMode		rts

;*** Fenster für Laufwerk öffnen.
:openDualWin		lda	driveType,x		;Laufwerk vorhanden?
			beq	exitDWinMode		; => Nein, Abbruch...

			txa				;Laufwerkadresse speichern.
			pha

			tya				;Zeiger auf Fensterdaten
			asl				;berechnen.
			asl
			asl
			tay
			iny
			ldx	#1			;Fenstergröße in Fensterdaten
::1			lda	:drvWinSize,y		;kopieren.
			sta	WIN_FILES,x
			iny
			inx
			cpx	#7
			bcc	:1
			pla
			asl
			tay
			lda	:drvWinData +0,y
			ldx	:drvWinData +1,y
			jmp	CallRoutine		;Fenster öffnen.

::drvWinData		w PF_OPEN_DRV_A
			w PF_OPEN_DRV_B
			w PF_OPEN_DRV_C
			w PF_OPEN_DRV_D

::drvWinSize		b $00
			b MIN_AREA_WIN_Y,MAX_AREA_WIN_Y -1
			w MIN_AREA_WIN_X,MAX_AREA_WIN_X-160 -1
			b NULL
			b $00
			b MIN_AREA_WIN_Y,MAX_AREA_WIN_Y -1
			w MIN_AREA_WIN_X+160,MAX_AREA_WIN_X -1
			b NULL

;*** Fenster/Verzeichnis-Daten aktivieren.
:RESET_DIR_DATA		ldx	WM_STACK		;DeskTop aktiv?
			bne	:1			; => Nein, weiter...
::0			rts

::1			lda	WIN_DRIVE,x		;Laufwerksfenster?
			beq	:0			; => Nein, Ende...

			stx	WM_WCODE		;Oberstes Fenster aktivieren.
			jsr	WM_LOAD_WIN_DATA

:UNSLCT_DIR_DATA	jsr	getCacheData		;Verzeichnis aus Cache einlesen.

			lda	#GD_MODE_UNSLCT
			jmp	SetFileSlctMode		;Datei-Auswahl aufheben.

;*** Dateien aus Cache einlesen.
;HINIWEIS:
;Bei SET_CACHE_DATA/FetchRAM auch das
;Laufwerk für GetFiles setzen.
;
;Damit wird der Routine signalisiert
;welche Dateien von welchem Laufwerk
;im RAM vorhanden sind.
;Dadurch wird verhindert das die
;GetFiles-Routine den Cache mit den
;falschen Dateien aktualisiert.
;
:getCacheData
;--- Ergänzung: 24.11.19/M.Kanet
;Nicht auf WM_STACK zurückgreifen, da
;sich der Stack ggf. geändert hat.
;Immer das aktuelle Fenster verwenden!
;			ldx	WM_STACK
			ldx	WM_WCODE		;Laufwerksdaten für die Dateien
			stx	getFileWin		;im RAM setzen.

			lda	WIN_DRIVE,x		;Laufwerk setzen.
			sta	getFileDrv

			lda	WIN_PART,x		;Ggf. Partition setzen.
			sta	getFilePart

			lda	WIN_SDIR_T,x		;Ggf. Unterverzeichnis setzen.
			sta	getFileSDir +0
			lda	WIN_SDIR_S,x
			sta	getFileSDir +1

			jsr	SET_CACHE_DATA		;Zeiger auf Dateien im Cache setzen.
			jmp	FetchRAM		;Cache im RAm einlesen.

;*** Gültigkeit der Laufwerksfenster testen.
;Hinweis: Wurden Laufwerke z.B. mit
;         dem GEOS.Editor gewechselt,
;         dann muss hier sichergestellt
;         werden das die Laufwerksdaten
;         noch zu den Fensterdaten
;         passen.
;         Nein => Fenster schließen.
:CheckWinStatus		ldx	#MAX_WINDOWS -1		;Max. Fenster-Nr. einlesen.
::1			txa				;Zähler für Fenster-Nr.
			pha				;speichern.

			lda	WM_STACK,x		;Fenster-Nr. einlesen.
			beq	:2			; => Desktop, weiter...
			bmi	:2			; => Leer, weiter...

			tax
			ldy	WIN_DRIVE,x		;Laufwerk definiert?
			beq	:2			; => Nein, weiter...

			lda	WIN_REALTYPE,x
			cmp	RealDrvType -8,y	;Laufwerkstyp verändert?
			beq	:2			; => Nein, weiter...

			stx	WM_WCODE		;Fenster-Nr. setzen.
			jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

			lda	WM_WCODE		;Fenster schließen.
			jsr	WM_CLOSE_WINDOW

::2			pla				;Zähler für Fenster-Nr.
			tax				;zurücksetzen.

			dex				;Alle Fenster geprüft?
			bpl	:1			; => Nein, weiter...
			rts

;*** Desktop zeichnen.
:MainDrawDesktop	jsr	WM_CLEAR_SCREEN		;Bildschirm löschen.
			jsr	AL_DRAW_FILES		;AppLinks zeichnen.

			jsr	InitTaskBar		;TaskBar darstellen.

			jsr	InitWinMseKbd		;Fenster-/Maus-/Tastatur starten.
			jsr	SUB_SYSINFO		;Systeminfo anzeigen.

			lda	#$00			;DeskTop als aktives Fenster setzen.
			sta	WM_WCODE

			jmp	WM_SAVE_SCREEN		;Bildschirminhalt speichern.
