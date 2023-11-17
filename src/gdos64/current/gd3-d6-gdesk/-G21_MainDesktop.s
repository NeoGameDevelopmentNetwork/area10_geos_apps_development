; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
;Routine:   MainBoot
;Funktion:  Einsprung aus BOOT-Routine:
;           -GeoDesk initialisieren.
;           -AppLinks einlesen.
;           -DeskTop zeichnen.
;           -TaskBar/Uhr zeichnen.
;           -Fenstermanager starten.
;           -Variablen speichern.
;
:MainBoot		jsr	MOD_WM			;FensterManager initialisieren:
							; - WindowManager nachladen.
							; - Zeichensatz aktivieren.
							; - Vordergrundgrafik aktivieren.

			jsr	SUB_FIND_STDICON	;Standard-Icons suchen/laden.

			jsr	SUB_LOADCOL		;Farbprofil aus DACC laden.

			jsr	SUB_LNK_LD_DATA		;AppLink-Daten einlesen.

			jsr	SET_TEST_CACHE		; => BAM testen/Cache oder Disk.

			LoadW	r0,WIN_DESKTOP
			jsr	WM_COPY_WIN_DATA	;DeskTop-Daten setzen.

			jsr	MainDTopRedraw		;DeskTop neu zeichnen.
			jsr	WM_SAVE_WIN_DATA	;Fensterdaten speichern.

			jsr	testDWinMode		;Auf DualFenster-Modus testen.

			jsr	resetHelpSys		;Hilfesystem zurücksetzen.

			jmp	UPDATE_GD_CORE		;GeoDesk-Systemvariablen speichern.
							;Damit stehen die Systemvariablen
							;auch nach einem RBOOT im Speicher.

;
;Routine:   MainReBoot
;Funktion:  Einsprung über EnterDeskTop:
;           -GeoDesk initialisieren.
;           -Laufwerke testen.
;           -DeskTop zeichnen.
;           -TaskBar/Uhr zeichnen.
;           -Fenstermanager starten.
;           -Fenster neu zeichnen.
;
:MainReBoot		jsr	MOD_WM			;FensterManager initialisieren:
							; - WindowManager nachladen.
							; - Zeichensatz aktivieren.
							; - Vordergrundgrafik aktivieren.

			jsr	getGDINI_RAM		;GeoDesk-Optionen aus DACC laden.

			jsr	SUB_LOADCOL		;Farbprofil aus DACC laden.

;--- Geöffnete Fenster neu zeichnen.
			jsr	MainDTopRedraw		;DeskTop neu zeichnen.

			lda	#FALSE
			sta	:flagDelWin

			lda	#MAX_WINDOWS -1		;Zeiger auf letztes Fenster.
::loop			pha
			tax
			lda	WM_STACK,x		;Fenster aktiv?
			beq	:next			; => MyComp... Weiter...
			bmi	:next			; => Nein, Weiter...

			sta	WM_WCODE
			jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

;			ldx	WM_WCODE
			ldy	WIN_DRIVE,x		;Laufwerk definiert?
			beq	:win_redraw		; => Nein, weiter...

			lda	WIN_REALTYPE,x
			cmp	RealDrvType -8,y	;Laufwerkstyp verändert?
			bne	:win_close		; => Nein, weiter...

;--- Fensterlaufwerk öffnen.
::win_ok		jsr	WM_OPEN_DRIVE		;Fensterlaufwerk öffnen.
			txa				;Fehler?
			beq	:disk			; => Nein, weiter...

;--- Fenster fehlerhaft, schließen.
::win_close		lda	WM_WCODE		;Fenster schließen.
			jsr	WM_DELETE_WINDOW

			lda	#TRUE
			sta	:flagDelWin
			bne	:next

;--- Hinweis:
;Diskette öffnen, da bei einem GEOS-
;ReBoot sonst die Disknamen nicht im
;Speicher stehen und Fenster dann ohne
;Disknamen neu aufgebaut werden.
::disk			jsr	OpenDisk		;Diskette öffnen.

;--- Hinweis:
;Keinen Fehler auswerten falls bei
;CMD/SD2IEC-Laufwerken der Partitions-
;oder DiskImage-Browser aktiv ist!
			stx	r0L			;Fehler-Status speichern.

;--- Hinweis:
;SD2IEC: Testen ob über eine andere
;Anwendung evtl. ein DiskImage geladen
;wurde und der DiskImage-Browser-Modus
;beendet werden kann.
;CMD: Falls Partitions-Modus aktiv ist,
;Partitionsliste neu einlesen.
			ldx	WM_WCODE
			ldy	WIN_DRIVE,x
			lda	RealDrvMode -8,y	;CMD- oder SD2IEC-Laufwerk ?
			and	#SET_MODE_PARTITION!SET_MODE_SD2IEC
			beq	:test_cache		; => Nein, weiter...

			lda	WIN_DATAMODE,x
			and	#%11000000		;Partition/DiskImage-Modus ?
			beq	:test_cache		; => Nein, weiter...
			bmi	:reload			;CMD-Laufwerk, weiter...

;--- SD2IEC-Laufwerk: DiskImage testen.
			lda	r0L			;Partition/DiskImage geöffnet ?
			bne	:reload			; => Nein, DiskImage-Browser...

			ldx	WM_WCODE		;Fenster-Nr. einlesen und
			lda	WIN_DATAMODE,x		;DiskImage-Browser-Modus löschen,
			and	#%10111111		;da DiskImage geladen ist.
			sta	WIN_DATAMODE,x

::reload		jsr	SET_LOAD_DISK		;Partitionen/Dateien von Disk
			jmp	:win_redraw		;neu einlesen.

;--- BAM auf Veränderungen testen.
;Wenn verändert => Disk neu einlesen.
;Sonst aus Cache einlesen.
::test_cache		jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler ?
			bne	:win_close		; => Ja, Fenster schließen...

			jsr	SET_TEST_CACHE		; => BAM testen/Cache oder Disk.
							;Erforderlich damit bei Rückkehr
							;von GEOS/DeskTop beim neu zeichnen
							;der Fensters alle Dateien im
							;Speicher sind.

			jsr	extWin_Unselect		;Dateien im Fenster abwählen.

;--- Fenster zeichnen.
::win_redraw		jsr	WM_CALL_REDRAW		;Fenster zeichnen.
			jsr	WM_SAVE_WIN_DATA	;Fensterdaten aktualisieren.

::next			pla
			sec
			sbc	#$01			;Alle Fenster gezeichnet?
			bpl	:loop			; => Nein, weiter...

;--- Oberstes Fenster aktivieren.
;Sollte das bisher oberste Fenster
;geschlossen worden sein (z.B. keine
;Disk im Laufwerk), dann muss hier
;das Laufwerk des aktuell obersten
;Fenster geöffnet werden.
;Sonst greift Laufwerk->Eigenschaften
;auf das falsche Laufwerk zu.
			lda	:flagDelWin
			beq	:done

			lda	WM_STACK		;Fenster aktiv?
			bmi	:done			; => Nein, weiter...

			sta	WM_WCODE
			jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

			jsr	WM_OPEN_DRIVE		;Laufwerk für Fenster aktivieren.
;---

::done			jsr	testDWinMode		;Auf DualFenster-Modus testen.

			jsr	resetHelpSys		;Hilfesystem zurücksetzen.

			jmp	SET_LOAD_CACHE		;GetFiles-Modus zurücksetzen.

;--- Laufwerk für Fenster aktivieren.
::flagDelWin		b $00

;
;Routine:   MainUpdate
;Funktion:  Einsprung aus Disk-/Dateifunktionen:
;           -DeskTop aus ScreenCache einlesen.
;           -TaskBar/Uhr zeichnen.
;           -Fenstermanager starten.
;           -Verzeichnis aus Cache einlesen.
;           -Datei-Auswahl aufheben.
;           -Fenster aus ScreenBuffer laden.
;           -Oberstes Fenster neu zeichnen.
;
:MainUpdate		jsr	MOD_WM			;FensterManager initialisieren:
							; - WindowManager nachladen.
							; - Zeichensatz aktivieren.
							; - Vordergrundgrafik aktivieren.

			jsr	updateDrvData		;Fensterdaten aktualsieren.

			jsr	updateOtherWin		;Andere Fenster ggf. aktualisieren.

			jsr	extWin_ResetData	;Verzeichnis-Daten einlesen.
			jsr	WM_UPDATE		;Oberstes Fenster aktualisieren.

			jsr	testDWinMode		;Auf DualFenster-Modus testen.

			jsr	resetHelpSys		;Hilfesystem zurücksetzen.

			jsr	ReStartTaskBar		;TaskBar starten.

			jsr	InitWinMseKbd		;Fenster-/Maus-/Tastatur starten.
			jmp	SUB_SYSINFO		;Systeminfo anzeigen.

;
;Routine:   InitWinMseKbd
;Funktion:  Fenster-/Maus-/Tastaturabfrage initialisieren.
;
.InitWinMseKbd		clc
			jsr	StartMouseMode		;Mausabfrage starten.

			jsr	MAIN_RESETAREA		;Fenstergrenzen zurücksetzen.

;--- Hinweis:
;Es gibt in GeoDesk keine andere
;Tastenabfrage, daher ist keyVector
;immer undefiniert / $0000.
if FALSE
			lda	keyVector +0
			ldx	keyVector +1

			cmp	#< GD_SHORTCUTS		;Tastenabfrage bereits aktiv?
			bne	:1			; => Nein, weiter...
			cpx	#> GD_SHORTCUTS
			beq	:2			; => Ja, Ende...

::1			sta	oldKeyVector +0		;Zeiger auf existierende
			stx	oldKeyVector +1		;Tastenabfrage zwischenspeichern.
endif

			lda	#< GD_SHORTCUTS		;Zeiger auf neue Tastenabfrage.
			sta	keyVector +0
			lda	#> GD_SHORTCUTS
			sta	keyVector +1

			lda	#< GD_DRAWCLOCK		;Uhrzeit aktualisieren.
			sta	appMain +0
			lda	#> GD_DRAWCLOCK
			sta	appMain +1

			lda	#< GD_MICROMYS		;MouseWheel abfragen.
			sta	intBotVector +0
			lda	#> GD_MICROMYS
			sta	intBotVector +1

::2			jmp	InitForWM		;Fenstermanager wieder aktivieren.

;*** Tastenabfrage installieren.
:GD_SHORTCUTS		lda	#GEXT_SHORTCUT		;Tastaturabfrage laden.
			jmp	LdDTopMod

;*** Alte keyVector-Routine.
;
;Hinweis:
;Wird aktuell nicht verwendet.
;
if FALSE
:oldKeyVector		w $0000
endif

;
;Routine:   MainUpdateWin
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
;
:MainUpdateWin		jsr	MOD_WM			;FensterManager initialisieren:
							; - WindowManager nachladen.
							; - Zeichensatz aktivieren.
							; - Vordergrundgrafik aktivieren.

			lda	drvUpdFlag
			and	#%00100000		;Dateiauswahl aufheben ?
			beq	:1			; => Nein, weiter...

			lda	winSource
			sta	WM_WCODE		;Fenster-Nr. setzen und
			jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

			jsr	extWin_Unselect

::1			lda	#MAX_WINDOWS -1		;Zeiger auf letztes Fenster.
::loop			pha
			tax
			lda	WM_STACK,x		;Fenster aktiv?
			beq	:2			; => DeskTop, weiter...
			bpl	:10			; => Fenster, weiter...
::2			jmp	:next			;Weiter mit nächstem Fenster.

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
			jmp	:next			;Weiter mit nächstem Fenster.

;--- Quell-/Zielfenster überspringen.
::11			cpx	winSource		;Fenster Quell-Laufwerk?
			beq	:12			; => Ja, überspringen.
			cpx	winTarget		;Fenster Ziel-Laufwerk?
			bne	:20			; => Nein, weiter...
::12			jmp	:next			;Weiter mit nächsten Fenster.

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
			jmp	:next			;Weiter mit nächstem Fenster.

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
::next			pla
			sec
			sbc	#$01			;Alle Fenster gezeichnet?
			bcc	:61			; => Ja, Ende...
			jmp	:loop			;Weiter mit nächstem Fenster.

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
			beq	:done
			jsr	WM_WIN2TOP

			ldx	winSource		;Fenster-Nr. Quell-Laufwerk.
			lda	updateSource		;Update-Modus für Fenster.
			jsr	updateDrvWin		;Quell-Laufwerk aktualisieren.
			jmp	:done

;--- Quelle/Ziel aktiualisieren.
::81			ldx	winSource		;Quelle und Ziel gleich?
			beq	:83			; => Kein Fenster, weiter...
			cpx	winTarget		;(z.B. Dateien duplizieren)
			beq	:82			; => Ja, weiter...
			lda	updateSource		;Update-Modus für Fenster.
			jsr	updateDrvWin		;Quell-Laufwerk aktualisieren.

::82			lda	winTarget		;Ziel-Fenster nach oben sortieren.
			beq	:done
			jsr	WM_WIN2TOP

::83			ldx	winTarget		;Fenster-Nr. Ziel-Laufwerk.
			beq	:done			; => Kein Fenster, weiter...
			lda	updateTarget		;Update-Modus für Fenster.
			jsr	updateDrvWin		;Ziel-Laufwerk aktualisieren.

;--- Rückkehr zum Fenstermanager.
::done			lda	#$00			;Source/Target-Daten löschen.
			sta	sysSource
			sta	winSource
			sta	sysTarget
			sta	winTarget

;			jmp	MainReStart		;FensterManager starten.

;
;Routine:   MainReStart
;Funktion:  Rückkehr zum FensterManager:
;           -TaskBar/Uhr aktivieren.
;           -Fenstermanager starten.
;
:MainReStart		jsr	resetHelpSys		;Hilfesystem zurücksetzen.

			lda	WM_STACK		;Dateifenster geöffnet?
			beq	:skip			; => Nein, weiter...

			jsr	WM_OPEN_DRIVE		;Fensterlaufwerk wieder aktivieren.

			jsr	extWin_ResetData	;Verzeichnis-Daten einlesen.
							;Erforderlich z.B. für Konfiguration
							;speichern, das bei geöffnetem
							;Dateifenster die Dateiliste mit
							;anderen Daten überschreibt.

::skip			jsr	ReStartTaskBar		;TaskBar starten.

			jsr	InitWinMseKbd		;Fenster-/Maus-/Tastatur starten.
			jmp	SUB_SYSINFO		;Systeminfo anzeigen.

;
;Routine:   MainInitWM
;Funktion:  Rückkehr zum FensterManager:
;           -DeskTop zeichnen.
;           -TaskBar/Uhr zeichnen.
;           -Fenstermanager starten.
;           -Verzeichnis aus Cache einlesen.
;           -Alle Fenster aus ScreenBuffer laden.
;
:MainInitWM		jsr	MainDTopUpdate		;DeskTop neu zeichnen.
			jmp	WM_DRAW_ALL_WIN		;Fenster aus ScreenBuffer laden.

;
;Routine:   updateDrvData
;Funktion:  Fensterdaten ändern.
;
;Nach der Rückkehr aus einem Modul,
;z.B. Verzeichnis erstellen, hier die
;Daten für das Fenster aktualisieren.
;
:updateDrvData		bit	drvUpdFlag		;Andere Fenster schließen ?
			bvc	:1			; => Nein, weiter...

			jsr	closeDrvWin		;Andere Fenster schließen.
;			jsr	BACKUP_WMCORE		;Haupt-Modul speichern.

			lda	drvUpdFlag		;Status zurücksetzen.
			and	#%10111111
			sta	drvUpdFlag

::1			lda	WM_WCODE		;Aktuelles Fenster =
			cmp	WM_MYCOMP		;Arbeitsplatz?
			beq	:exit			; => Ja, Ende...

			bit	drvUpdFlag
			bpl	:exit

			ldx	WM_WCODE

;--- Neues UV setzen.
			lda	drvUpdSDir +0
			beq	:2
			sta	WIN_SDIR_T,x
			lda	drvUpdSDir +1
			sta	WIN_SDIR_S,x

			lda	#$00			;PagingMode: Verzeichnis von
			sta	WIN_DIR_START,x		;Anfang neu anzeigen.

;--- Partitionsmodus wechseln.
::2			lda	drvUpdMode
			sta	WIN_DATAMODE,x

;--- Update beenden.
::exit			lda	#$00
			sta	drvUpdFlag

			rts

;
;Routine:   updateDrvWin
;Funktion:  Setzt Reload-Flag, Fenster-Nr. und zeichnet Fenster neu.
;           -Fenster aktivieren.
;           -Laufwerk aktivieren.
;           -Verzeichnis ins RAM kopieren.
;           -Fenster neu zeichnen.
;           -Fenster in ScreenBuffer speichern.
;           -Fensterdaten speichern.
;
:updateDrvWin		sta	GD_RELOAD_DIR		;Reload-Flag setzen.

			stx	WM_WCODE		;Fenster-Nr. setzen und
			jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

			jsr	WM_OPEN_DRIVE		;Fensterlaufwerk öffnen.
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
::err			jmp	WM_LOAD_SCREEN		;Fenster aus ScreenBuffer laden.

;--- HINWEIS:
;Verzeichnis aus Cache einlesen und
;Fensterinhalt neu zeichnen.
::1			jsr	extWin_GetCache		;Verzeichnis aus Cache einlesen.

			jsr	WM_CALL_REDRAW		;Fenster neu zeichnen.
			jsr	WM_SAVE_SCREEN		;Fenster im Cache speichern.
			jmp	WM_SAVE_WIN_DATA	;Fensterdaten aktualisieren.

;
;Routine:   testDWinMode
;Funktion:  Testet auf DualWin-Mode und öffnet Fenster.
;
:testDWinMode		lda	GD_DUALWIN_MODE		;Zwei-Fenster-Modus aktiv?
			beq	:exit			; => Nein, Ende...

			lda	WM_WCOUNT_OPEN		;Anzahl offener Fenster einlesen.
			cmp	#3			;Mehr als zwei Fenster geöffnet?
			bcs	:exit			; => Ja, Ende...
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

::1			jsr	clrStdWinSize

::exit			rts

;*** Fenster für Laufwerk öffnen.
:openDualWin		lda	driveType,x		;Laufwerk vorhanden?
			beq	:exit			; => Nein, Abbruch...

			txa				;Laufwerkadresse speichern.
			pha

			tya				;Zeiger auf Fensterdaten
			asl				;berechnen.
			asl
			asl
			tay
			iny
			ldx	#1			;Fenstergröße in Fensterdaten
::1			lda	:size,y			;kopieren.
			sta	WIN_FILES,x
			iny
			inx
			cpx	#7
			bcc	:1
			pla
			asl
			tay
			lda	:data +0,y
			ldx	:data +1,y
			jmp	CallRoutine		;Fenster öffnen.
::exit			rts

::data			w PF_OPEN_DRV_A
			w PF_OPEN_DRV_B
			w PF_OPEN_DRV_C
			w PF_OPEN_DRV_D

::size			b $00
			b MIN_AREA_WIN_Y,MAX_AREA_WIN_Y -1
			w MIN_AREA_WIN_X,MAX_AREA_WIN_X-160 -1
			b NULL
			b $00
			b MIN_AREA_WIN_Y,MAX_AREA_WIN_Y -1
			w MIN_AREA_WIN_X+160,MAX_AREA_WIN_X -1
			b NULL

;*** Hilesystem zurücksetzen.
:resetHelpSys		lda	#0
			sta	HelpSystemPage		;Erste Seite für Hilfesystem.

			tay
::1			sta	HelpSystemFile,y	;Dateiname für Hilfesystem auf
			iny				;löschen => Standard-Dokument.
			cpy	#16
			bcc	:1

			rts
