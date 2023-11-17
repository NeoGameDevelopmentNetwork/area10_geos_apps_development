; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Mausklick auf Arbeitsplatz.
:MseClkMyComputer	jsr	WM_TEST_ENTRY		;Icon ausgewählt?
			bcc	:exit			; => Nein, weiter.

;--- Hinweis:
;Speichern nur für DiskCopy notwendig.
;			stx	sysSource +0		;Nr. des Eintrages speichern.
;			sty	sysSource +1

if MAXENTRY16BIT = TRUE
			cpy	#$00			;Aktuell max. 255 Einträge.
			bne	:exit			; => Größer 256, Abbruch...
endif

			cpx	#$04			;Laufwerk/Drucker ausgewählt?
			bcc	:1			; => Laufwerk.
			beq	:4			; => Drucker.
			cpx	#$05			;Eingabe ausgewäht?
			bne	:exit			; => Nein, Abbruch...
			jmp	AL_OPEN_INPUT		;Eingabetreiber wechseln.
::exit			rts

::editor		jmp	MENU_SETUP_EDIT

;--- Laufwerk verschieben.
::1			lda	driveType,x		;Laufwerk vorhanden?
			beq	:editor			; => Nein, Editor starten...

			jsr	WM_TEST_MOVE		;Drag`n`Drop?
			bcs	:2			; => Ja, weiter...
			jmp	MYCOMP_DRVCURWIN	;Laufwerksfenster öffnen.

::2			stx	winSource		;Nr. Source-Fenster speichern.

			txa
			clc
			adc	#$08
			jsr	Sys_SetDvSource		;Laufwerksdaten einlesen.

			LoadW	r4,Icon_Drive +1
			jsr	DRAG_N_DROP_ICON	;Drag`n`Drop ausführen.
			cpx	#NO_ERROR		;Icon abgelegt?
			bne	:exit			; => Nein, Abbruch.
			tay				;Auf DeskTop abgelegt?
			bne	:3			; => Nein, Abbruch.

			jmp	AL_DnD_Drive		;AppLink für Laufwerk erstellen.
::3			jmp	MseTestDiskCopy		;Auf DiskCopy testen.

;--- Drucker verschieben.
::4			jsr	WM_TEST_MOVE		;Drag`n`Drop?
			bcs	:5			; => Ja, weiter...

			jsr	SUB_SLCT_PRNT		;Drucker auswählen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abruch...
			jmp	UpdateMyComputer	;Arbeitsplatz aktualisieren.

::5			LoadW	r4,Icon_Printer +1
			jsr	DRAG_N_DROP_ICON	;Drag`n`Drop ausführen.
			cpx	#NO_ERROR		;Icon abgelegt?
			bne	:exit			; => Nein, Abbruch.
			tay				;Auf DeskTop abgelegt?
			bne	:exit			; => Nein, Abbruch.

;--- Hinweis:
;Es wird hier ein neuer Drucker
;ausgewählt der dann als AppLink auf
;dem DeskTop abgelegt wird.
;Notwendig da der Pfad zum Treiber im
;AppLink gespeichert wird.
			jsr	SUB_SLCT_PRNT		;Drucker auswählen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abruch...

			jmp	AL_DnD_Printer		;AppLink für Drucker erstellen.

;*** Laufwerk kopieren?
;    Übergabe: YREG = Ziel-Fenster.
:MseTestDiskCopy	cpy	WM_MYCOMP		;DnD auf Arbeitsplatzfenster?
			bne	:1			; => Nein, weiter...

			ClrB	winTarget		;Kein Target-Fenster speichern.

			jsr	WM_TEST_ENTRY		;Icon ausgewählt?
			bcc	:3			; => Nein, weiter.

if MAXENTRY16BIT = TRUE
			cpy	#$00			;Aktuell max. 255 Einträge.
			bne	:3			; => Größer 256, Abbruch...
endif

			cpx	#$04			;Laufwerk ausgewählt?
			bcs	:3			; => Nein, Abbruch...

			txa				;DnD auf Laufwerk in Arbeitsplatz.
			clc
			adc	#$08			;Ziel-Laufwerk definieren.
			cmp	sysSource
			bne	:4			; => Weiter...

;--- Hinweis:
;Drag`n`Drop auf gleiches Laufwerk
;ignorieren und Laufwerk öffnen.
;XReg/YReg sind noch unverändert und
;zeigen auf gewähltes Laufwerks-Icon.
;Bei VICE im Warp-Modus wird so ein
;ungewolltes Drag`n`Drop auf das
;gleiche Laufwerk verhindert.
			jmp	MYCOMP_DRVCURWIN	;Laufwerksfenster öffnen.

::1			lda	WIN_DRIVE,y		;DnD auf anderes Fenster.
			beq	:3			; => Kein Laufwerk definiert.

			sty	winTarget		;Nr. Target-Fenster speichern.

			tya				;Ziel-Fenster nach oben.
			jsr	WM_WIN2TOP

::2			jsr	OpenWinDrive		;Laufwerk für Fenster öffnen.
			txa				;Fehler?
			bne	:3			; => Ja, Abbruch...

			lda	curDrive
::4			jsr	Sys_SetDvTarget		;Laufwerksdaten einlesen.

			ldx	sysTarget +0		;Zur Sicherheit Laufwerk prüfen.
			lda	driveType -8,x		;Laufwerk definiert?
			beq	:3			; => Nein, Abbruch...

			jsr	WM_SAVE_BACKSCR		;Aktuellen Bildschirm speichern.
			jmp	MOD_DISKCOPY		;DiskCopy starten.
::3			rts

;*** Mausklick auf Dateifenster.
:MseClkFileWin		jsr	WM_TEST_ENTRY		;Icon ausgewählt?
			bcc	:exit			; => Nein, Abbruch...

;--- Mauslick auf Datei.
			stx	fileEntryPos +0		;Datei-Nr. speichern.
if MAXENTRY16BIT = TRUE
			sty	fileEntryPos +1
endif
			stx	r0L
if MAXENTRY16BIT = TRUE
			sty	r0H
endif

			ldx	#r0L			;Zeiger auf Verzeichnis-Eintrag
			jsr	SET_POS_RAM		;berechnen.

			MoveW	r0,fileEntryVec		;Zeiger zwischenspeichern.
			jsr	FILE_r14_SLCT		;Aktuelle Datei unter Mauszeiger
							;im Speicher und am Bildschirm
							;auswählen (":r0" nicht verändern!)

::1			ldx	WM_WCODE
			lda	WIN_DATAMODE,x		;Fenstermodus einlesen.
			bmi	:5			; => Partitionen wechseln.
			bne	:4			; => SD2IEC/DiskImages wechseln.

			ldy	#$02
			lda	(r0L),y
			cmp	#GD_MORE_FILES		;"Weitere Dateien"?
			beq	:3			; => Ja, weiter...

			jsr	WM_TEST_MOVE		;Drag`n`Drop?
			bcc	:2			; => Nein, weiter...
			jmp	MseDragAndDrop		;Drag`n`Drop auswerten.

;--- Kein Eintrag, Abbruch...
::exit			rts

;--- Datei öffnen.
::2			jsr	FILE_r14_UNSLCT		;Aktuelle Datei unter Mauszeiger
							;im Speicher und am Bildschirm
							;abwählen (":r0" nicht verändern!)
			jmp	OpenFile_r0		;Anwendung/Dokument/DA öffnen.

;--- Weitere Dateien öffnen.
::3			jmp	LoadMoreFiles		;"Weitere Dateien" angeklickt.

;--- SD2IEC: DiskImage oder Verzeichnis öffnen.
::4			php
			sei				;Interrupt sperren.
			jsr	MouseOff		;Mauszeiger abschalten.

			MoveW	r0,a0
			jsr	SUB_OPEN_SD_DIMG	;SD2IEC-Eintrag öffnen.
			cpx	#DEV_NOT_FOUND		;SD-Karte im Laufwerk?
			beq	:exitMouse		; => Nein, Ende...
			txa				;Status prüfen:
			bne	:updWinData		; => Verzeichnis gewechselt.

			jsr	closeDrvWin		;Andere Fenster für das aktuelle
							;SD2IEC schließen, damit keine
							;zwei Fenster mit unterschiedlichen
							;DiskImages geöffnet sind.
			jmp	:updDrvData		; => DiskImage geöffnet.

;--- CMD: Partition öffnen.
::5			php
			sei				;Interrupt sperren.
			jsr	MouseOff		;Mauszeiger abschalten.

			ldy	#$03
			lda	(r0L),y			;Partitions-Nr. einlesen und
			sta	r3H			;speichern.
			jsr	OpenPartition		;Partition wechseln.
			txa				;Fehler?
			bne	:exitMouse		; => Ja, Abbruch...

;--- Laufwerksdaten aktualisieren.
::updDrvData		jsr	SaveWinDrive		;Laufwerksdaten aktualisieren.

			ldx	WM_WCODE
			lda	#$00			;Partitionsmodus löschen.
			sta	WIN_DATAMODE,x

			txa				;Partition ausgewählt.
			pha				;Falls "MyComputer" geöffnen:
			jsr	UpdateMyComputer	;"MyComputer" aktualisieren.
			pla
			jsr	WM_WIN2TOP		;Laufwerks-Fenster wieder
			jsr	WM_LOAD_WIN_DATA	;aktivieren.

;--- Fensterdaten aktualisieren.
::updWinData		jsr	InitEntryCnt		;Datei-Zähler löschen.

			jsr	WM_SAVE_WIN_DATA	;Fensterdaten speichern.

			jsr	SET_LOAD_DISK		;Dateien von Disk neu einlesen.
			jsr	WM_CALL_DRAW		;Fenster neu laden.

::exitMouse		jsr	MouseUp			;Mauszeiger wieder einschalten.
			plp				;Interrupt-Status zurücksetzen.
			rts

;*** Datei/Verzeichnis verschieben.
:MseDragAndDrop		jsr	countSlctFiles		;Dateiauswahl zählen.
			cmp	#$02			;Mehr als eine Datei gewählt?
			bcs	:2			; => Ja, weiter...

			ldy	#$02
			lda	(r0L),y			;Dateityp "Gelöscht"?
			and	#FTYPE_MODES		;Dateityp isolieren.
			cmp	#FTYPE_DIR		;NativeMode Verzeichnis?
			bne	:1			; => Nein, weiter...
			jmp	MseDnD_SubDir		;Verzeichnis verschieben.
::1			jmp	MseDnD_File		;Datei verschieben.

;--- Mehrere Dateien verarbeiten.
::2			lda	#< Icon_CBM +1		;ToDo: Passendes Icon für
			ldx	#> Icon_CBM +1		;      MultiDatei-Operation.
			sta	r4L
			stx	r4H
			jsr	DRAG_N_DROP_ICON	;Ziel-Fenster ermitteln.
			cpx	#NO_ERROR		;Fehler?
			bne	:3			; => Ja, Abbruch...
			tay				;Ziel-Fenster = DeskTop?
			beq	:3			; => Ja, Abbruch...

;--- Fensterstatus prüfen:
;Target-Fenster darf nicht MyComp- oder
;Partitionsauswahl-Fenster sein.
			cmp	WM_MYCOMP		;Ziel-Fenster = Arbeitsplatz?
			beq	:3			; => Nein, weiter...

			lda	WIN_DATAMODE,y		;Ziel-Fenster = Partition/DiskImage?
			bne	:3			; => Ja, Abbruch...
			jmp	MseDnD_Windows		; => Nein, FileCopy/FileMove.

;--- Dateiklick abbrechen.
::3			rts

;*** Datei aus Fenster verschieben.
:MseDnD_File		tax				;Dateityp "Gelöscht"?
			bne	:0			; => Nein, weiter...
			lda	#<Icon_Deleted +1	;Zeiger auf "Gelöscht"-Icon.
			ldx	#>Icon_Deleted +1
			bne	:3

;--- Ausnahmebehandlung für AppLinks:
;Hier nicht auf gültigen GEOS-Typ für
;AppLinks testen, da sonst auch kein
;Drag'n'Drop für FileCopy möglich ist.
::0			ldy	#$18
			lda	(r0L),y			;GEOS-Dateityp auswerten.

;			jsr	CheckFType		;Dateityp auswerten.
;			cpx	#NO_ERROR		;Starten möglich?
;			bne	:7			; => Nein, Ende...

			cmp	#$00			;BASIC oder GEOS-Datei?
			bne	:1			; => GEOS-Datei, weiter...
			lda	#<Icon_CBM +1		;Zeiger auf "CBM"-Icon.
			ldx	#>Icon_CBM +1
			bne	:3

::1			cmp	#PRINTER		;Druckertreiber?
			bne	:2			; => Nein, weiter...
			lda	#<Icon_Printer +1
			ldx	#>Icon_Printer +1
			bne	:3

::2			lda	r0L			;Zeiger auf Verzeichnis-Eintrag
			clc				;berechnen, da GetFHdrInfo einen
			adc	#$02			;30-Byte-Eintrag erwartet.
			sta	r9L
			lda	r0H
			adc	#$00
			sta	r9H

			jsr	OpenWinDrive		;Laufwerk aktivieren.
			jsr	GetFHdrInfo		;Dateiheader einlesen.

			lda	#<fileHeader +5
			ldx	#>fileHeader +5
::3			sta	r4L			;Zeiger auf Icon für DnD
			stx	r4H			;setzen.
			jsr	DRAG_N_DROP_ICON
			cpx	#NO_ERROR
			bne	:7
			tay				;Ziel-Fenster = DeskTop?
			beq	:4			; => Ja, weiter...

;--- Fensterstatus prüfen:
;Target-Fenster darf nicht MyComp- oder
;Partitionsauswahl-Fenster sein.
			cmp	WM_MYCOMP		;Ziel-Fenster = Arbeitsplatz?
			beq	:7			; => Ja, Abbruch...

			lda	WIN_DATAMODE,y		;Ziel-Fenster = Partition/DiskImage?
			bne	:7			; => Ja, Abbruch...

			jmp	MseDnD_Windows		; => Nein, FileCopy/FileMove.

;--- Drag'n'Drop auf DeskTop.
::4			jsr	FILE_r14_UNSLCT		;Aktuelle Datei unter Mauszeiger
							;im Speicher und am Bildschirm
							;abwählen (":r0" nicht verändern!)

::5			MoveW	fileEntryVec,r0		;Zeiger auf Verzeichnis_Eintrag.

			jsr	CheckFType		;Dateityp auswerten.
			cpx	#NO_ERROR		;AppLink möglich?
			bne	:7			; => Nein, Ende...

;			ldy	#$18
;			lda	(r0L),y			;GEOS-Dateityp auswerten.
			cmp	#PRINTER		;Drucker?
			beq	:6			; => Ja, Drucker-AppLink erstellen.

			jmp	AL_DnD_Files		;AppLink für Datei erstellen.

;--- Drucker aus Fenster verschieben.
::6			jmp	AL_DnD_FilePrnt		;AppLink für Drucker erstellen.

;--- Dateiklick abbrechen.
::7			rts

;*** Verzeichnis aus Fenster verschieben.
:MseDnD_SubDir		lda	#< Icon_Map +1		;Zeiger auf "Verzeichnis"-Icon.
			ldx	#> Icon_Map +1
			sta	r4L
			stx	r4H
			jsr	DRAG_N_DROP_ICON
			cpx	#NO_ERROR
			bne	:exit
			tay				;Ziel-Fenster = DeskTop?
			beq	:1			; => Ja, weiter...

;--- Fensterstatus prüfen:
;Target-Fenster darf nicht MyComp- oder
;Partitionsauswahl-Fenster sein.
			cmp	WM_MYCOMP		;Ziel-Fenster = Arbeitsplatz?
			beq	:exit			; => Nein, weiter...

			lda	WIN_DATAMODE,y		;Ziel-Fenster = Partition/DiskImage?
			bne	:exit			; => Ja, Abbruch...

			jmp	MseDnD_Windows		; => Nein, FileCopy/FileMove.

::1			MoveW	fileEntryVec,r0		;Zeiger auf Verzeichnis_Eintrag.

			ldy	#$03
			lda	(r0L),y			;Track/Sektor für Verzeichnis-
			sta	r1L			;Header einlesen.
			iny
			lda	(r0L),y
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Verzeichnis-Header einlesen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			jmp	AL_DnD_SubDir		;AppLink für Verzeichnis erstellen.

;--- Dateiklick abbrechen.
::exit			rts

;*** Datei in anderes Fenster kopieren/verschieben.
;    Übergabe: WM_WCODE = Quell-Fenster.
;              YREG     = Ziel-Fenster
:MseDnD_Windows		lda	WM_WCODE
;			sta	sysSource
;			sty	sysTarget

			sta	winSource		;Nr. Source-Fenster speichern.
			sty	winTarget		;Nr. Target-Fenster speichern.

			tax

;--- Fensterstatus prüfen:
;Weder Source- noch Target-Fenster
;dürfen MyComp- oder Partitionsauswahl-
;Fenster sein.
			cpx	WM_MYCOMP		;Source-Fenster = Arbeitsplatz?
			beq	:exit			; => Ja, Abbruch...
			lda	WIN_DATAMODE,x		;Source-Laufwerk im Partitionsmodus?
			bne	:exit			; => Ja, Abbruch...

			cpy	WM_MYCOMP		;Target-Fenster = Arbeitsplatz?
			beq	:exit			; => Ja, Abbruch...
			lda	WIN_DATAMODE,y		;Target-Laufwerk im Partitionsmodus?
			bne	:exit			; => Ja, Abbruch...

			cpy	winSource		;Source = Target ?
			bne	:1			; => Nein, weiter...

;--- Duplizieren -> SHIFT-Taste testen.
			php				;Tastaturabfrage:
			sei				;Linke/Rechte SHIFT-Taste für
			ldx	CPU_DATA		;Dateien duplizieren.
			lda	#$35
			sta	CPU_DATA
			ldy	#%10111101
			sty	CIA_PRA
			ldy	CIA_PRB
			stx	CPU_DATA
			plp

;			cpy	#%01101111		;Beide Tasten gedrückt halten.
;			bne	:exit			; => Geht nicht ;-)
			cpy	#%01111111		;SHIFT Links gedrückt?
			beq	:1
			cpy	#%11101111		;SHIFT Rechts gedrückt?
			bne	:exit			; => Nein, Abbruch...

::1			jsr	WM_SAVE_BACKSCR		;Aktuellen Bildschirm speichern.
			jmp	MOD_COPYMOVE
::exit			rts

;*** Datei in r14 markieren/abwählen.
:FILE_r14_SLCT		lda	#$00
			b $2c
:FILE_r14_UNSLCT	lda	#$ff
			ldx	fileEntryPos +0		;Zeiger auf Datei-Eintrag.
			stx	r14L
if MAXENTRY16BIT = TRUE
			ldx	fileEntryPos +1
			stx	r14H
endif
			tax
			bne	:1
			jmp	WM_FMODE_SELECT		;Aktuelle Datei markieren.
::1			jmp	WM_FMODE_UNSLCT		;Aktuelle Datei abwählen.

;*** Anzahl ausgewählte Dateien ermitteln.
:countSlctFiles		ldx	#r15L
			jsr	ADDR_RAM_x		;Zeiger auf Anfang Verzeichnis.

			ldx	#$00			;Anzahl ausgewählte Dateien
			stx	:count			;löschen.

			stx	r3L			;Zeiger auf erste Datei.
if MAXENTRY16BIT = TRUE
			stx	r3H
endif

::1			ldy	#$00
			lda	(r15L),y		;Datei ausgewählt?
			and	#GD_MODE_MASK
			beq	:2			; => Nein, weiter...

			ldy	#$02
			lda	(r15L),y		;Dateityp einlesen?
			cmp	#GD_MORE_FILES		;Eintrag "Weitere Dateien>"?
			beq	:2			; => Ja, ignorieren.

			inc	:count

::2			AddVBW	32,r15			;Zeiger auf nächsten Eintrag.

			inc	r3L			;Datei-Zähler +1.
if MAXENTRY16BIT = TRUE
			bne	:3
			inc	r3H
endif

::3
if MAXENTRY16BIT = TRUE
			lda	r3H
			cmp	WM_DATA_MAXENTRY +1
			bne	:4
endif
			lda	r3L
			cmp	WM_DATA_MAXENTRY +0
::4			bcc	:1			; => Weiter mit nächster Datei.

			lda	:count			;Anzahl markierter Dateien.
			rts

;*** Variablen.
::count			b $00

;*** Weitere Dateien einlesen.
:LoadMoreFiles		jsr	WM_WAIT_NOMSEKEY	;Warten bis keine M-Taste gedrückt.

			lda	#$00			;Verzeichnis auf Anfang.
			sta	WM_DATA_CURENTRY +0
if MAXENTRY16BIT = TRUE
			sta	WM_DATA_CURENTRY +1
endif

;--- Hinweis:
;Auf der ersten Seite zeigt
;WIN_DIR_NR_L/H auf $0000, daher für
;die erste Seite MaxFiles addieren.
;Ab der zweiten Seite dann MaxFiles-1
;addieren.
			ldx	WM_WCODE		;Auf erste Seite prüfen.
			lda	WIN_DIR_NR_L,x
			ora	WIN_DIR_NR_H,x

			ldx	WM_DATA_MAXENTRY +0
			ldy	WM_DATA_MAXENTRY +1

			cmp	#$00			;Erste Seite?
			beq	:1			; => Ja, weiter...

;--- Ab Seite#2 MaxFiles -1 addieren.
if MAXENTRY16BIT = TRUE
			txa
			bne	:0
			dey
::0
endif
			dex

;--- Positionszähler korrigieren.
::1			txa
			ldx	WM_WCODE		;Position im Verzeichnis
			clc				;berechnen.
			adc	WIN_DIR_NR_L,x
			sta	WIN_DIR_NR_L,x
			tya
			adc	WIN_DIR_NR_H,x
			sta	WIN_DIR_NR_H,x

			lda	#$ff			;Flag setzen:
			sta	WIN_DIR_START,x		;Die nächsten Dateien einlesen.

			jsr	SET_LOAD_DISK		;Dateien von Disk einlesen.
			jsr	WM_CALL_GETFILES	;Verzeichnis einlesen.
			jmp	WM_CALL_REDRAW		;Fenster neu zeichnen.

;*** Mausklick auf Link-Eintrag ?
:MseClkAppLink		jsr	AL_FIND_ICON		;AppLink finden.
			txa				;AppLink gewählt?
			beq	:1			; => Ja, weiter...
			rts

::1			bit	GD_LNK_LOCK		;AppLinks gesperrt?
			bmi	:2			; => Ja, weiter...

			jsr	WM_TEST_MOVE		;Drag`n`Drop?
			bcc	:2			; => Nein, weiter...
			jmp	AL_MOVE_ICON

::2			jsr	WM_WAIT_NOMSEKEY	;Warten bis keine M-Taste gedrückt.

			jmp	AL_OPEN_ENTRY		;AppLink öffnen.
