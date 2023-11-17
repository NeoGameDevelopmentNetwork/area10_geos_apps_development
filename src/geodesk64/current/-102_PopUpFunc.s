; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** GEOS/Einstellungen - Setup starten.
:MENU_SETUP_EDIT	jsr	UPDATE_GD_CORE		;GeoDesk-Systemvariablen speichern.
			jmp	MOD_OPEN_EDITOR		;GEOS-Editor aufrufen.

;*** GEOS/Einstellungen - Drucker wechseln.
:MENU_SETUP_PRNT	lda	#$08			;Suche nach Druckertreiber
			jsr	SetDevice		;auf Laufwerk 8/A: starten.
			jsr	SUB_SLCT_PRNT		;Druckertreiber wählen.
			txa				;Abbruch?
			bne	:1			; => Ja, Ende...
			jmp	UpdateMyComputer	;"MyComputer" aktualisieren.
::1			rts

;*** GEOS/Einstellungen - Eingabegerät wechseln.
:MENU_SETUP_INPT	lda	#$08			;Suche nach Druckertreiber
			jsr	SetDevice		;auf Laufwerk 8/A: starten.
			jsr	SUB_SLCT_INPT		;Eingabetreiber wählen.
			txa				;Abbruch?
			bne	:1			; => Ja, Ende...
			jmp	UpdateMyComputer	;"MyComputer" aktualisieren.
::1			rts

;*** PopUp/Arbeitsplatz - Laufwerk öffnen.
:PF_OPEN_DRV_A		ldx	#8
			b $2c
:PF_OPEN_DRV_B		ldx	#9
			b $2c
:PF_OPEN_DRV_C		ldx	#10
			b $2c
:PF_OPEN_DRV_D		ldx	#11
			lda	driveType -8,x		;Laufwerk verfügbar?
			bne	:0			; => Ja, weiter...
			jmp	MENU_SETUP_EDIT		;GEOS.Editor starten.

::0			txa
			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Laufwerksfehler?
			bne	:exit			; => Ja, Abbruch...

			ldx	curDrive
			lda	RealDrvMode -8,x	;Laufwerkstyp einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode?
			beq	:1			; => Nein, weiter...

;--- NativeMode: ROOT öffnen.
			jsr	OpenRootDir		;Hauptverzeichnis öffnen.
			txa				;Fehler?
			bne	:no_disk		; => Ja, Abbruch...
			beq	:2			; => Nein, Fenster öffnen.

;--- 1541/71/81: Disk öffnen.
::1			jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler?
			bne	:no_disk		; => Ja, Abbruch...
;			beq	:2			; => Nein, Fenster öffnen.

;--- Neues Fenster öffnen.
;Standardmäßig ist WIN_DATAMODE hier
;gleich $00 = Dateimodus.
;Bei einem Diskfehler beim öffnen des
;Mediums wird durch die Fehlerroutine
;(:no_disk) "WIN_DATAMODE" auf $40 =
;"ImageBrowser-Modus" gesetzt.
::2			lda	curDrive		;Eintrags-Nr. in Arbeitsplatz für
			sec				;Laufwerk berechnen.
			sbc	#$08
			tax
if MAXENTRY16BIT = TRUE
			ldy	#$00
endif
			jmp	MYCOMP_DRVNEWWIN	;Neues Laufwerksfenster öffnen.

;--- Fehler, auf SD2IEC testen.
;Bei SD2IEC das nächste freie Fenster
;suchen und WIN_DATAMODE setzen, damit
;der ImageBrowser gestartet wird.
::no_disk		stx	:4 +1			;Fehler-Nummer merken.

			ldx	curDrive
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
;			and	#SET_MODE_SD2IEC	;Typ SD2IEC?
;--- Ergänzung: 11.05.20/M.Kanet
;In seltenen Fällen kann auch bei einer
;CMD-HD eine ungültige Partition aktiv
;sein, daher den Partitionsmodus für
;das Laufwerk aktivieren.
			and	#SET_MODE_PARTITION!SET_MODE_SD2IEC
			beq	:4			; => Nein, weiter...

			jsr	WM_IS_WIN_FREE		;Freie Fenster-Nummer suchen.
			cpx	#NO_ERROR		;Freies Fenster verfügbar?
			bne	:4			; => Nein, Abbruch...

			tay				;Fenster-Nr.
			ldx	curDrive
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			bpl	:4a			; => SD2IEC.
			lda	#%1000 0000		;Partitionsmodus CMD.
			b $2c
::4a			lda	#%0100 0000		;DiskImage-Modus SD2IEC.
			sta	WIN_DATAMODE,y		;SD2IEC-Browser-Modus setzen.
			jmp	:2			;DiskImage-Browser öffnen.

::4			ldx	#$ff			;Fehler-Nr. zurücksetzen und
			jmp	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

::exit			rts

;*** PopUp/DeskTop - AppLink-Titel anzeigen.
:PF_VIEW_ALTITLE	lda	GD_LNK_TITLE
			eor	#$ff
			sta	GD_LNK_TITLE
			jsr	MainDrawDesktop
			jmp	WM_DRAW_ALL_WIN		;Fenster aus ScreenBuffer laden.

;*** PopUp/DeskTop - Hintergrund anzeigen.
:PF_BACK_SCREEN		bit	GD_BACKSCRN		;Hintergrundbild aktiv?
			bmi	:1			; => Ja, abschalten.

			LoadW	r0,backScrCode		;Auf Hintergrundbild im
			LoadW	r1,backScrCodeRAM	;GEOS-Speicher testen.
			LoadW	r2,backScrCodeLen
			lda	GD_SYSDATA_BUF
			sta	r3L
			jsr	VerifyRAM		;Prüfcode testen.
			and	#%0010 0000		;Hintergrundbild im Speicher?
			beq	:2			; => Ja, weiter...
			jmp	MOD_OPEN_BACKSCR	;Hintergrundbild auswählen.

::1			lda	#$00			;Kein Hintergrubdild verwenden.
			b $2c
::2			lda	#$ff			;Hintergrundbild verwenden.
			sta	GD_BACKSCRN		;Flag für Hintergrundbild setzen.

			lda	sysRAMFlg
			and	#%11110111
			bit	GD_BACKSCRN		;GeoDesk-Hintergrundbild verwenden?
			bpl	:3			; => Nein, weiter...
			ora	#%00001000		; => Ja, System-Wert ändern.
::3			sta	sysRAMFlg
			sta	sysFlgCopy

			jsr	MainDrawDesktop		;Desktop neu zeichnen.
			jmp	WM_DRAW_ALL_WIN		;Fenster aus ScreenBuffer laden.

;*** PopUp/DeskTop - AppLinks sperren.
:PF_LOCK_APPLINK	lda	GD_LNK_LOCK
			eor	#$ff
			sta	GD_LNK_LOCK
			rts

;*** PopUp/AppLink - Verzeichnis öffnen.
:PF_OPEN_SDIR		MoveW	AL_VEC_FILE,r14		;Zeiger auf Eintrag kopieren.
			jmp	AL_OPEN_SDIR		;Verzeichnis öffnen.

;*** PopUp/Titelzeile - Partition wechseln.
:PF_SWAP_DSKIMG		ldy	WM_WCODE		;Fenster-Nr. einlesen.
			beq	:exitDesktop		; => Desktop, kein Fenster.

			php
			sei				;Interrupt sperren.
			jsr	MouseOff		;Mauszeiger abschalten.

			ldx	WIN_DRIVE,y		;Laufwerksadresse einlesen.
			beq	:error			; => Kein Laufwerk.
;			ldx	curDrive
			lda	RealDrvType -8,x	;RAM-Laufwerk?
			bmi	:error			; => Part./DiskImage nicht möglich.

			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_PARTITION!SET_MODE_SD2IEC
			beq	:error			; => Kein CMD/SD2IEC-Laufwerk...

			and	#SET_MODE_SD2IEC	;Typ SD2IEC?
			beq	:1			; => Nein, weiter...

			jsr	closeDrvWin		;Andere Fenster für das aktuelle
							;SD2IEC schließen, damit keine
							;zwei Fenster mit unterschiedlichen
							;DiskImages geöffnet sind.

::1			jsr	SUB_GETPART		;Partitionsdaten einlesen.
			txa				;Fenster neu laden?
			beq	:ok			; => Ja, weiter...

			ldx	WM_WCODE
			lda	WIN_DATAMODE,x		;Partitionsauswahl-Modus testen.
			and	#%0100 0000		;SD2IEC-DiskImages?
			beq	:exit			; => Nein, weiter...

			lda	#<WM_CALL_DRAW		;Verzeichnis neu laden.
			ldx	#>WM_CALL_DRAW
			bne	:updWinData

;			jmp	WM_CALL_DRAW		;Verzeichnis neu laden.

::ok			jsr	SET_LOAD_DISK		;Dateien von Disk neu einlesen.

::exit			lda	#<WM_CALL_REDRAW	;Fensterinhalt neu zeichnen.
			ldx	#>WM_CALL_REDRAW
::updWinData		jsr	CallRoutine
;			jmp	WM_CALL_REDRAW		;Fensterinhalt neu zeichnen.

::error			jsr	MouseUp			;Mauszeiger wieder einschalten.
			plp				;Interrupt-Status zurücksetzen.
::exitDesktop		rts

;*** PopUp/Fenster - Datei/Verzeichnis Öffnen.
:PF_OPEN_FILE		jsr	FILE_r14_SLCT		;Aktuelle Datei unter Mauszeiger
							;im Speicher und am Bildschirm
							;auswählen (":r0" nicht verändern!)

			MoveW	fileEntryVec,r0		;Zeiger auf Verzeichnis-Eintrag.
			jmp	OpenFile_r0		;Anwendung/Dokument/DA öffnen.

;*** PopUp/Fenster - Datei-Eigenschaften.
:PF_FILE_INFO		jsr	countSlctFiles		;Dateiauswahl zählen.
			beq	:exit			; => Nichts ausgewählt, Ende...
			jsr	UPDATE_GD_CORE		;Variablen sichern.
			jmp	MOD_FILE_INFO		;Datei-Informationen anzeigen.
::exit			rts

;*** PopUp/Fenster - Datei/Verzeichnis Löschen.
:PF_DEL_FILE		jsr	countSlctFiles		;Dateiauswahl zählen.
			beq	:exit			; => Nichts ausgewählt, Ende...
			jsr	UPDATE_GD_CORE		;Variablen sichern.
			jmp	MOD_FILE_DELETE		;Dateien löschen.
::exit			rts

;*** PopUp/Fenster - Datei konvertieren.
:PF_CONVERT_FILE	jsr	countSlctFiles		;Dateiauswahl zählen.
			beq	:exit			; => Nichts ausgewählt, Ende...
			jsr	UPDATE_GD_CORE		;Variablen sichern.
			jmp	MOD_CONVERT		;Dateien konvertieren.
::exit			rts

;*** CBM+T - Dateien tauschen.
:PF_SWAP_ENTRIES	jsr	countSlctFiles		;Dateiauswahl zählen.
			cmp	#$02			;Zwei Dateien?
			bne	:exit			; => Nein, Ende...
			jsr	UPDATE_GD_CORE		;Variablen sichern.
			jmp	MOD_SWAPENTRIES		;Dateien tauschen.
::exit			rts

;*** PopUp/Fenster/Native - ROOT öffnen.
:PF_OPEN_ROOT		ldx	WM_WCODE
			lda	WIN_DATAMODE,x		;Partitionsauswahl-Modus testen.
			and	#%0100 0000		;SD2IEC-DiskImages?
			beq	:0			; => Nein, weiter...

;--- SD2IEC: Hauptverzeichnis öffnen.
			jsr	SUB_OPEN_SD_ROOT	;Hauptverzeichnis öffnen.
			cpx	#DEV_NOT_FOUND		;SD-Karte im Laufwerk?
			beq	:1			; => Nein, Ende...
			jsr	SET_LOAD_DISK		;Dateien von Disk neu einlesen.
			jmp	WM_CALL_DRAW		;Verzeichnis neu laden.

;--- Native: Hauptverzeichnis öffnen.
::0			;ldx	WM_WCODE
			ldy	WIN_DRIVE,x		;Laufwerksadresse einlesen.
			lda	RealDrvMode -8,y	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode?
			beq	:1			; => Nein, Ende...

			lda	#$01
			sta	WIN_SDIR_T,x
			sta	WIN_SDIR_S,x
			jsr	OpenRootDir
			jsr	SET_LOAD_DISK		;Dateien von Disk neu einlesen.
			jmp	WM_CALL_DRAW		;Verzeichnis neu laden.
::1			rts

;*** PopUp/Fenster/Native - Verzeichnis zurück.
:PF_OPEN_PARENT		ldx	WM_WCODE
			lda	WIN_DATAMODE,x		;Partitionsauswahl-Modus testen.
			and	#%0100 0000		;SD2IEC-DiskImages?
			beq	:0			; => Nein, weiter...

;--- SD2IEC: Elternverzeichnis öffnen.
			jsr	SUB_OPEN_SD_DIR		;Elternverzeichnis öffnen.
			cpx	#DEV_NOT_FOUND		;SD-Karte im Laufwerk?
			beq	:1			; => Nein, Ende...

			jsr	set1stFilePos		;Liste auf Anfang setzen.

			jsr	SET_LOAD_DISK		;Dateien von Disk neu einlesen.
			jmp	WM_CALL_DRAW		;Verzeichnis neu laden.

;--- Native: Elternverzeichnis öffnen.
::0			jsr	set1stFilePos		;Liste auf Anfang setzen.

			;ldx	WM_WCODE
			ldy	WIN_DRIVE,x		;Laufwerksadresse einlesen.
			lda	RealDrvMode -8,y	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode?
			beq	:1			; => Nein, Ende...

			lda	curDirHead+34		;Hauptverzeichnis ?
			beq	:1			; => Ja, Ende...
			sta	r1L			;Track/Sektor für
			ldx	WM_WCODE		;Elternverzeichnis kopieren und
			sta	WIN_SDIR_T,x		;in Fensterdaten speichern.
			lda	curDirHead+35
			sta	r1H
			sta	WIN_SDIR_S,x
			jsr	OpenSubDir		;Unterverzeichnis öffnen.
			jsr	SET_LOAD_DISK		;Dateien von Disk neu einlesen.
			jmp	WM_CALL_DRAW		;Verzeichnis neu laden.
::1			rts

;*** Liste auf Anfang setzen.
:set1stFilePos		lda	#$00			;Zeiger auf erste Datei setzen.
			sta	WM_DATA_CURENTRY +0
if MAXENTRY16BIT = TRUE
			sta	WM_DATA_CURENTRY +1
endif
			jmp	WM_SAVE_WIN_DATA	;Fensterdaten speichern.

;*** Neues Verzeichnis erstellen.
:PF_CREATE_DIR		ldx	WM_WCODE
			ldy	WIN_DRIVE,x		;Laufwerksadresse einlesen.
			lda	RealDrvMode -8,y	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode?
			beq	:1			; => Nein, Ende...
			jmp	MOD_CREATE_DIR		;Verzeichnis erstellen.
::1			rts

;*** Neues SD-DiskImage erstellen.
:PF_CREATE_IMG		ldx	WM_WCODE
			ldy	WIN_DRIVE,x		;Laufwerksadresse einlesen.
			lda	RealDrvMode -8,y	;Laufwerksmodus einlesen.
			and	#SET_MODE_SD2IEC	;SD2IEC?
			beq	:1			; => Nein, Ende...
			jmp	MOD_CREATE_IMG		;DiskImage erstellen.
::1			rts

;*** Laufwerk formatieren.
;Aufruf über ShortCut/PopUp-Menü.
;Hinweis:
;Option ist nur für reale Laufwerke
;verfügbar, nicht für RAMDisks.
:PF_FORMAT_DISK		ldx	WM_WCODE		;Fenster-Nr. einlesen.
			ldy	WIN_DRIVE,x		;Laufwerksadresse einlesen.
			lda	RealDrvType -8,y	;Laufwerk = RAM-Laufwerk?
			bmi	:1			; => Ja, Ende...
			jmp	MOD_FRMTDISK		;Diskette formatieren.
::1			rts

;*** PopUp/Fenster - Neue Ansicht.
:PF_NEW_VIEW		jsr	OpenWinDrive		;Laufwerk aktivieren.
			txa				;Fehler?
			bne	:1			; => Ja, Abbruch...

			jsr	WM_IS_WIN_FREE		;Freie Fenster-Nr. suchen.
			cpx	#NO_ERROR		;Fenster verfügbar?
			bne	:1			; => Nein, Ende...

			tay				;Fenster-Einstellungen in neues
			ldx	WM_WCODE		;Fenster kopieren.
			lda	WMODE_VICON,x
			sta	WMODE_VICON,y
			lda	WMODE_VSIZE,x
			sta	WMODE_VSIZE,y
			lda	WMODE_VINFO,x
			sta	WMODE_VINFO,y
			lda	WMODE_FILTER,x
			sta	WMODE_FILTER,y
			lda	WMODE_SORT,x
			sta	WMODE_SORT,y

			lda	WIN_DRIVE,x		;Eintrags-Nr. in Arbeitsplatz für
			sec				;Laufwerk berechnen.
			sbc	#$08
			tax
			ldy	#$00
			jmp	MYCOMP_DRVUSRWIN	;Laufwerk im Arbeitsplatz öffnen.

::1			rts

;*** PopUp Fenster - Neu laden.
:PF_RELOAD_DISK		jsr	OpenWinDrive		;Laufwerk aktivieren.
			txa				;Fehler?
			beq	PF_RELOAD_CURDSK	; => Ja, Abbruch...
:PF_RELOAD_EXIT		rts

:PF_RELOAD_CURDSK	ldx	WM_WCODE
			ldy	WIN_DRIVE,x		;Laufwerksadresse einlesen.
			lda	RealDrvMode -8,y	;Laufwerksmodus einlesen.
			and	#SET_MODE_SD2IEC	;SD2IEC-Laufwerk?
			beq	:open_disk		; => Nein, weiter...

			jsr	SUB_GET_SD_MODE		;SD2IEC-Modus testen.
			cpx	#DEV_NOT_FOUND		;SD-Karte im Laufwerk?
			beq	PF_RELOAD_EXIT		; => Nein, Abbruch...
			txa				;DiskImage aktiv?
			beq	:open_disk		; => Ja, weiter...
			jmp	PF_SWAP_DSKIMG		;Verzeichnisbrowser öffnen.

::open_disk		jsr	OpenDisk		;Diskette öffnen um DiskNamen
			txa				;zu aktualisieren.
			bne	PF_RELOAD_EXIT		; => Ja, Abbruch...

			jsr	InitWinDirData		;Verzeichnisdaten zurücksetzen.

			jsr	set1stFilePos		;Liste auf Anfang setzen.

			jsr	SET_LOAD_DISK		;Dateien von Disk neu einlesen.

			jmp	WM_CALL_DRAW		;Fnetsrinhalt neu laden.

;*** PopUp/Fenster/Anzeige - KByte/Blocks.
:PF_VIEW_SIZE		ldy	WM_WCODE
			lda	WMODE_VSIZE,y
			eor	#$ff
			sta	WMODE_VSIZE,y
			jmp	WM_CALL_REDRAW		;Fensterinhalt neu zeichnen.

;*** PopUp/Fenster/Anzeige - Icons anzeigen.
:PF_VIEW_ICONS		ldx	WM_WCODE
			lda	#$00			;Text-Modus löschen.
			sta	WMODE_VINFO,x
			lda	WMODE_VICON,x		;Icon-Modus wechseln.
			eor	#$ff
			sta	WMODE_VICON,x
			jsr	INIT_WIN_GRID		;Raster für Fenster neu berechnen.
			jmp	WM_CALL_REDRAW		;Fensterinhalt neu zeichnen.

;*** PopUp/Fenster/Anzeige - Textmodus/Details.
:PF_VIEW_DETAILS	ldx	WM_WCODE
			lda	#$ff			;Textmodus aktivieren.
			sta	WMODE_VICON,x
			lda	WMODE_VINFO,x		;Detail-Modus wechseln.
			eor	#$ff
			sta	WMODE_VINFO,x
			jsr	INIT_WIN_GRID		;Raster für Fenster neu berechnen.
			jmp	WM_CALL_REDRAW		;Fensterinhalt neu zeichnen.

;*** PopUp/Fenster/Anzeige - SlowMode.
:PF_VIEW_SLOWMOVE	lda	GD_SLOWSCR
			eor	#$ff
			sta	GD_SLOWSCR
			rts

;*** PopUp/Fenster/Anzeige - SlowMode.
:PF_VIEW_DELFILES	lda	GD_VIEW_DEL		;Status "Gelöschte Dateien"
			pha				;zwischenspeichern.

			lda	#%11000000
			sta	GD_VIEW_DEL		;Nur gelöschte Dateien anzeigen.
			jsr	PF_RELOAD_CURDSK	;Dateien einlesen.

			pla				;Status "Gelöschte Dateien"
			sta	GD_VIEW_DEL		;wieder zurücksetzen.
			rts

;*** PopUp/Fenster - Dateifilter.
:PF_FILTER_ALL		lda	#$00
			b $2c
:PF_FILTER_BASIC	lda	#$80
			b $2c
:PF_FILTER_APPS		lda	#$80 ! APPLICATION
			b $2c
:PF_FILTER_EXEC		lda	#$80 ! AUTO_EXEC
			b $2c
:PF_FILTER_DOCS		lda	#$80 ! APPL_DATA
			b $2c
:PF_FILTER_DA		lda	#$80 ! DESK_ACC
			b $2c
:PF_FILTER_FONT		lda	#$80 ! FONT
			b $2c
:PF_FILTER_PRNT		lda	#$80 ! PRINTER
			b $2c
:PF_FILTER_INPT		lda	#$80 ! INPUT_DEVICE
			b $2c
:PF_FILTER_SYS		lda	#$80 ! SYSTEM

			ldx	WM_WCODE
			sta	WMODE_FILTER,x		;Neuen Filter-Modus setzen.

			jsr	InitEntryCnt		;Datei-Zähler löschen.

			jsr	WM_SAVE_WIN_DATA	;Fensterdaten speichern.

			jsr	SET_LOAD_DISK		;Dateien von Disk neu einlesen.
			jmp	WM_CALL_DRAW		;Verzeichnis neu laden.

;*** PopUp/Fenster - Dateien sortieren.
:PF_SORT_NONE		lda	#$00
			b $2c
:PF_SORT_NAME		lda	#$01
			b $2c
:PF_SORT_SIZE		lda	#$02
			b $2c
:PF_SORT_DATE_OLD	lda	#$03
			b $2c
:PF_SORT_DATE_NEW	lda	#$04
			b $2c
:PF_SORT_TYPE		lda	#$05
			b $2c
:PF_SORT_GEOS		lda	#$06
			ldx	WM_WCODE
			sta	WMODE_SORT,x		;Neuen Sortiermodus setzen.

			pha

			jsr	set1stFilePos		;Liste auf Anfang setzen.

			pla				;Sortierung aufheben?
			beq	:1			; => Ja, Disk neu laden.

			jsr	SET_SORT_MODE		;Flag für ":GetFiles" setzen:
							;"Nur Dateien sortieren".

			;jsr	WM_MOVE_WIN_UP		;Fenster nach oben sortieren.
							;Wird jetzt durch Mausabfrage
							;bereits erledigt.

			jmp	WM_CALL_DRAW		;Verzeichnis neu laden.
::1			jmp	PF_RELOAD_DISK		;Sortierung aufheben.

;*** PopUp/Fenster - Alle Dateien auswählen.
:PF_SELECT_ALL		lda	#GD_MODE_SELECT
			b $2c

;*** PopUp/Fenster - Auswahl aufheben.
:PF_SELECT_NONE		lda	#GD_MODE_UNSLCT

			jsr	SetFileSlctMode		;Dateien markieren.
			jmp	WM_CALL_REDRAW		;Fensterinhalt neu zeichnen.

;
;HINWEIS:
;Laufwerksfunktionen über Arbeitsplatz
;aufrufen (Validate, DiskInfo...).
;
;Laufwerk öffnen damit die Routine
;auf ein Laufwerk zugreifen kann.
;Über "MyComputer" ist dem Fenster
;sonst kein Laufwerk zugeordnet!
;
;*** PopUp/Laufwerk - Partition wechseln.
:MYCOMP_PART
if MAXENTRY16BIT = TRUE
			ldy	MyCompEntry +1
			bne	:exit
endif
			ldx	MyCompEntry +0
			cpx	#$04			;Laufwerk güktig?
			bcc	:1			; => Nein, weiter...
::exit			rts

::1			lda	RealDrvMode,x		;CMD-/SD2IEC-Laufwerk?
			and	#SET_MODE_PARTITION!SET_MODE_SD2IEC
			beq	:exit			; => Nein, Ende...

			cmp	#SET_MODE_SD2IEC	;SD2IEC?
			beq	:2			; = Ja, weiter...

			lda	#%1000 0000		;CMD-Partitions-Auswahl.
			b $2c
::2			lda	#%0100 0000		;DiskImage-Auswahl.

			ldx	WM_WCODE
			sta	WIN_DATAMODE,x		;Partitions-Modus setzen.
			jsr	MYCOMP_DRVENTRY		;PopUp/Laufwerk - Öffnen.
			txa				;Fehler?
			beq	:exit			; => Ja, Abbruch...

;*** Arbeitsplatz/Laufwerk öffnen: Fehler.
:MYCOMP_DRVERROR	jmp	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

;*** PopUp/Laufwerk - Öffnen.
:MYCOMP_OPENDRV		jsr	MYCOMP_DRVENTRY		;Neues Fenster öffnen.
			txa				;Fehler?
			bne	MYCOMP_DRVERROR		; => Ja, Abbruch...
			rts

;*** PopUp/Laufwerk - Neues Fenster.
:MYCOMP_NEWVIEW		ldx	MyCompEntry +0
if MAXENTRY16BIT = TRUE
			ldy	MyCompEntry +1
endif
			jsr	MYCOMP_DRVNEWWIN	;Neues Fenster öffnen.
			txa				;Fehler?
			bne	MYCOMP_DRVERROR		; => Ja, Abbruch...
			rts

;*** PopUp/Laufwerk - Validate.
;Aufruf über Arbeitsplatz.
:MYCOMP_VALIDATE	jsr	MYCOMP_DRVENTRY		;Laufwerk öffnen.
			txa				;Fehler?
			bne	MYCOMP_DRVERROR		; => Ja, Abbruch...
			jmp	MOD_VALIDATE		;Validate ausführen.

;*** PopUp/Laufwerk - DiskInfo.
;Aufruf über Arbeitsplatz.
:MYCOMP_DISKINFO	jsr	MYCOMP_DRVENTRY		;Laufwerk öffnen.
			txa				;Fehler?
			bne	MYCOMP_DRVERROR		; => Ja, Abbruch...
			jmp	MOD_DISKINFO		;DiskInfo ausführen.

;*** Laufwerk löschen.
;Aufruf über Arbeitsplatz.
:MYCOMP_CLRDRV		jsr	MYCOMP_DRVENTRY		;Laufwerk öffnen.
			txa				;Fehler?
			bne	MYCOMP_DRVERROR		; => Ja, Abbruch...
			jmp	MOD_CLRDISK		;Diskette löschen.

;*** Laufwerk formatieren.
;Aufruf über Arbeitsplatz.
;Hinweis:
;Option ist nur für reale Laufwerke
;verfügbar, nicht für RAMDisks. Hier
;wird dann "Clear Disk" aufgerufen.
:MYCOMP_FRMTDRV		jsr	myCompSetDevice		;Laufwerk aktivieren.
			txa				;Fehler?
			bne	formatExit		; => Ja, Abbruch.

			ldy	curDrive		;Laufwerksadresse einlesen.
			lda	RealDrvType -8,y	;Laufwerk = RAM-Laufwerk?
			bpl	:1			; => Nein, weiter...

			jsr	MYCOMP_DRVENTRY		;Laufwerk öffnen.
			txa				;Fehler?
			bne	MYCOMP_DRVERROR		; => Ja, Abbruch...
			jmp	MOD_CLRDISK		;RAMDisk => Laufwerk löschen.
::1			jmp	MOD_FRMTDISK		;Diskette formatieren.

;*** Arbeitsplatz-Laufwerk aktivieren.
;    Übergabe: MyCompEntry = Gewählter Eintrag in Arbeitsplatz.
;    Rückgabe: XREG = $00/OK.
:myCompSetDevice
if MAXENTRY16BIT = TRUE
			lda	MyCompEntry +1		;Laufwerk gültig?
			bne	:error			; => Nein, Abbruch...
endif
			lda	MyCompEntry +0
			cmp	#$04			;Laufwerk gültig?
			bcs	:error			; => Nein, AAbbruch...

			clc				;Laufwerksadresse berechnen.
			adc	#$08
			jmp	SetDevice		;Laufwerk aktivieren.

::error			ldx	#CANCEL_ERR
:formatExit		rts

;*** PopUp/Laufwerk - AppLink erstellen.
:PF_CREATE_AL		lda	curDirHead +34		;Ist Hauptverzeichnis aktiv?
			ora	curDirHead +35
			bne	:1			; => Nein, weiter...

			lda	#$01			;AppLink als Laufwerk erstellen.
			ldx	#<Icon_Drive +1
			ldy	#>Icon_Drive +1
			bne	:2

::1			lda	#$03			;AppLink als Verzeichnis erstellen.
			ldx	#<Icon_Map +1
			ldy	#>Icon_Map +1

::2			pha				;AppLink-Typ speichern.

			stx	r4L			;Zeiger auf Icon für
			sty	r4H			;AppLink speichern.

			LoadB	r3L,1			;Sprite für D`n`D erzeugen.
			jsr	DrawSprite

			pla
			jmp	AL_DnD_DrvSubD		;AppLink erstellen.
