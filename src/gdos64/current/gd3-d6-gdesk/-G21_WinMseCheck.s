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
;			stx	sysSource		;Nr. des Eintrages speichern.

			cpx	#$04			;Laufwerk/Drucker ausgewählt?
			bcc	:slct_drive		; => Laufwerk.
			beq	:printer		; => Drucker.
			cpx	#$05			;Eingabetreiber ausgewählt?
			bne	:exit			; => Nein, Abbruch...
::input			jmp	EXT_INPUTDBOX		;Eingabetreiber wechseln.

;--- Abbruch.
::exit			rts

;--- Laufwerk verschieben.
::slct_drive		lda	driveType,x		;Laufwerk vorhanden?
			beq	:config			; => Nein, Editor starten...

			jsr	WM_TEST_MOVE		;Drag`n`Drop?
			bcs	:11			; => Ja, weiter...
			jmp	MYCOMP_DRVCURWIN	;Laufwerksfenster öffnen.

::11			stx	winSource		;Nr. Source-Fenster speichern.

			txa
			clc
			adc	#$08
			jsr	Sys_SetDvSource		;Laufwerksdaten einlesen.

			LoadW	r4,Icon_Drive +1
			jsr	DRAG_N_DROP_ICON	;Drag`n`Drop ausführen.
			cpx	#NO_ERROR		;Icon abgelegt?
			bne	:exit			; => Nein, Abbruch.
			tay				;Auf DeskTop abgelegt?
			bne	:12			; => Nein, Abbruch.

			jmp	AL_DnD_Drive		;AppLink für Laufwerk erstellen.
::12			jmp	MseTestDiskCopy		;Auf DiskCopy testen.

::config		jmp	OpenGDConfig		;GD.CONFIG starten.

;--- Drucker verschieben oder wählen?.
::printer		jsr	WM_TEST_MOVE		;Drag`n`Drop?
			bcs	:exec_dnd_prnt		; => Ja, weiter...

;--- Drucker wählen.
			jmp	EXT_PRINTDBOX		;Drucker auswählen.

;--- Drucker verschieben.
::exec_dnd_prnt		lda	#< Icon_Printer +1
			sta	r4L
			lda	#> Icon_Printer +1
			sta	r4H

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
			lda	mouseXPos +0
			pha
			lda	mouseXPos +1
			pha
			lda	mouseYPos
			pha

			jsr	EXT_PRINTALNK		;Drucker auswählen.

			pla
			sta	mouseYPos
			pla
			sta	mouseXPos +1
			pla
			sta	mouseXPos +0

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

::2			jsr	WM_OPEN_DRIVE		;Laufwerk für Fenster öffnen.
			txa				;Fehler?
			bne	:3			; => Ja, Abbruch...

			lda	curDrive
::4			jsr	Sys_SetDvTarget		;Laufwerksdaten einlesen.

			ldx	sysTarget +0		;Zur Sicherheit Laufwerk prüfen.
			lda	driveType -8,x		;Laufwerk definiert?
			beq	:3			; => Nein, Abbruch...

			jsr	sys_SvBackScrn		;Aktuellen Bildschirm speichern.
			jsr	UPDATE_GD_CORE		;Variablen sichern.

			jmp	MOD_DISKCOPY		;DiskCopy starten.

::3			rts

;*** Mausklick auf Dateifenster.
.MseClkFileWin		jsr	WM_TEST_ENTRY		;Icon ausgewählt?
			bcs	clickFile		; => Ja, weiter...

;*** Kein Eintrag, Abbruch...
:MseNoFileSlct		rts

;*** Mauslick auf Datei.
:clickFile		stx	fileEntryPos		;Datei-Nr. speichern.

.MseClkOnFile		stx	r0L

			ldx	#r0L			;Zeiger auf Verzeichnis-Eintrag
			jsr	WM_SETVEC_ENTRY		;berechnen.

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

			lda	WM_WCODE
			pha

			jsr	UpdateMyComputer	;"MyComputer" aktualisieren.

			pla
			jsr	WM_WIN2TOP		;Laufwerks-Fenster wieder
			jsr	WM_LOAD_WIN_DATA	;aktivieren.

;			ldx	WM_WCODE
			lda	#%00000000
			sta	WIN_DATAMODE,x		;Partitionsmodus löschen.

;			lda	#$00
			sta	WIN_DIR_START,x		;Verzeichnis von Anfang einlesen.

;--- Fensterdaten aktualisieren.
::updWinData		jsr	extWin_InitCount	;Datei-Zähler löschen.

			jsr	WM_SAVE_WIN_DATA	;Fensterdaten speichern.

			jsr	SET_LOAD_DISK		;Dateien von Disk neu einlesen.
			jsr	WM_CALL_DRAW		;Fenster neu laden.

::exitMouse		jsr	MouseUp			;Mauszeiger wieder einschalten.
			plp				;Interrupt-Status zurücksetzen.
			rts

;*** Datei/Verzeichnis verschieben.
:MseDragAndDrop		jsr	GetNumSlctFiles		;Dateiauswahl zählen.
			cmp	#$02			;Mehr als eine Datei gewählt?
			bcs	:2			; => Ja, weiter...

			ldy	#$02
			lda	(r0L),y			;Dateityp "Gelöscht"?
			and	#ST_FMODES		;Dateityp isolieren.
			cmp	#DIR			;NativeMode Verzeichnis?
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
			bne	:1			; => Nein, weiter...

			lda	#< Icon_DEL +1		;Zeiger auf "Gelöscht"-Icon.
			ldx	#> Icon_DEL +1
			bne	:set_icon

;--- Ausnahmebehandlung für AppLinks:
;Hier nicht auf gültigen GEOS-Typ für
;AppLinks testen, da sonst auch kein
;Drag'n'Drop für FileCopy möglich ist.
::1			ldy	#$18
			lda	(r0L),y			;GEOS-Dateityp auswerten.

;			jsr	CheckFType		;Dateityp auswerten.
;			cpx	#NO_ERROR		;Starten möglich?
;			bne	:exit			; => Nein, Ende...

			cmp	#$00			;BASIC oder GEOS-Datei?
			bne	:2			; => GEOS-Datei, weiter...
			lda	#< Icon_CBM +1		;Zeiger auf "CBM"-Icon.
			ldx	#> Icon_CBM +1
			bne	:set_icon

::2			cmp	#PRINTER		;Druckertreiber?
			bne	:3			; => Nein, weiter...
			lda	#< Icon_Printer +1
			ldx	#> Icon_Printer +1
			bne	:set_icon

::3			lda	r0L			;Zeiger auf Verzeichnis-Eintrag
			clc				;berechnen, da GetFHdrInfo einen
			adc	#$02			;30-Byte-Eintrag erwartet.
			sta	r9L
			lda	r0H
			adc	#$00
			sta	r9H

			jsr	WM_OPEN_DRIVE		;Laufwerk aktivieren.
			jsr	GetFHdrInfo		;Dateiheader einlesen.

			lda	#< fileHeader +5
			ldx	#> fileHeader +5

::set_icon		sta	r4L			;Zeiger auf Icon für DnD
			stx	r4H			;setzen.
			jsr	DRAG_N_DROP_ICON
			cpx	#NO_ERROR
			bne	:exit
			tay				;Ziel-Fenster = DeskTop?
			beq	:dnd_dtop		; => Ja, weiter...

;--- Fensterstatus prüfen:
;Target-Fenster darf nicht MyComp- oder
;Partitionsauswahl-Fenster sein.
			cmp	WM_MYCOMP		;Ziel-Fenster = Arbeitsplatz?
			beq	:exit			; => Ja, Abbruch...

			lda	WIN_DATAMODE,y		;Ziel-Fenster = Partition/DiskImage?
			bne	:exit			; => Ja, Abbruch...

			jmp	MseDnD_Windows		; => Nein, FileCopy/FileMove.

;--- Drag'n'Drop auf DeskTop.
::dnd_dtop		jsr	FILE_r14_UNSLCT		;Aktuelle Datei unter Mauszeiger
							;im Speicher und am Bildschirm
							;abwählen (":r0" nicht verändern!)

			MoveW	fileEntryVec,r0		;Zeiger auf Verzeichnis_Eintrag.

			jsr	CheckFType		;Dateityp auswerten.
			cpx	#NO_ERROR		;AppLink möglich?
			bne	:exit			; => Nein, Ende...

;			ldy	#$18
;			lda	(r0L),y			;GEOS-Dateityp auswerten.
			cmp	#INPUT_DEVICE		;Eingabetreiber?
			beq	:exit			; => Ja, Abbruch...
			cmp	#PRINTER		;Drucker?
			beq	:dnd_prnt		; => Ja, Drucker-AppLink erstellen.

			jmp	AL_DnD_Files		;AppLink für Datei erstellen.

;--- Drucker aus Fenster verschieben.
::dnd_prnt		jmp	AL_DnD_FilePrnt		;AppLink für Drucker erstellen.

;--- Dateiklick abbrechen.
::exit			rts

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
			sty	cia1base +0
			ldy	cia1base +1
			stx	CPU_DATA
			plp

;			cpy	#%01101111		;Beide Tasten gedrückt halten.
;			bne	:exit			; => Geht nicht ;-)
			cpy	#%01111111		;SHIFT Links gedrückt?
			beq	:1			; => Ja, weiter...
			cpy	#%11101111		;SHIFT Rechts gedrückt?
			beq	:1			; => Ja, weiter...

::exit			rts

::1			ldx	winSource		;Nr. Source-Fenster einlesen.

			lda	WIN_DRIVE,x		;Laufwerksadresse für Fenster
			sta	sysSource +0		;einlesen und speichern.

			lda	WIN_PART,x		;Partition für Fenster
			sta	sysSource +1		;einlesen und speichern.

			lda	WIN_SDIR_T,x		;Unterverzeichnis für Fenster
			sta	sysSource +2		;einlesen und speichern.
			lda	WIN_SDIR_S,x
			sta	sysSource +3

			ldx	winTarget		;Nr. Target-Fenster einlesen.

			lda	WIN_DRIVE,x		;Laufwerksadresse für Fenster
			sta	sysTarget +0		;einlesen und speichern.

			lda	WIN_PART,x		;Partition für Fenster
			sta	sysTarget +1		;einlesen und speichern.

			lda	WIN_SDIR_T,x		;Unterverzeichnis für Fenster
			sta	sysTarget +2		;einlesen und speichern.
			lda	WIN_SDIR_S,x
			sta	sysTarget +3

			jsr	sys_SvBackScrn		;Aktuellen Bildschirm speichern.
			jsr	UPDATE_GD_CORE		;Variablen sichern.

			lda	WM_DATA_MAXENTRY
			sta	fileEntryCount		;Max.Dateianzahl zwischenspeichern.

			lda	#%00100000		;Dateiauswahl aufheben.
			sta	drvUpdFlag

			jmp	MOD_COPYMOVE		;Dateien kopieren.

;*** Datei in r14 markieren/abwählen.
:FILE_r14_SLCT		lda	#$00
			b $2c
:FILE_r14_UNSLCT	lda	#$ff

			ldx	fileEntryPos		;Zeiger auf Datei-Eintrag.
			stx	r14L

			tax
			bne	:1

			jmp	WM_FMODE_SELECT		;Aktuelle Datei markieren.
::1			jmp	WM_FMODE_UNSLCT		;Aktuelle Datei abwählen.

;*** Anzahl ausgewählte Dateien ermitteln.
.GetNumSlctFiles	ldx	#r15L
			jsr	ADDR_RAM_x		;Zeiger auf Anfang Verzeichnis.

			ldx	#$00			;Anzahl ausgewählte Dateien
			stx	:count			;löschen.

;--- Zeiger auf erste Datei.
			stx	r3L			;Zeiger auf erste Datei.

;--- Zähler für Anzahl Dateien.
;Wird für einige Datei-Routinen wie
;z.B. "Dateien tauschen" benötigt, um
;die Dateien im aktuellen Verzeichnis
;auswerten zu können.
			lda	WM_DATA_MAXENTRY
			sta	fileEntryCount

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

::3			lda	r3L
			cmp	fileEntryCount
::4			bcc	:1			; => Weiter mit nächster Datei.

			lda	:count			;Anzahl markierter Dateien.
			rts

;*** Variablen.
::count			b $00

;*** Weitere Dateien einlesen.
:LoadMoreFiles		jsr	waitNoMseKey		;Warten bis keine M-Taste gedrückt.

			lda	#$00			;Verzeichnis auf Anfang.
			sta	WM_DATA_CURENTRY

;--- Hinweis:
;Auf der ersten Seite zeigt
;WIN_DIR_NR auf $0000, daher für
;die erste Seite MaxFiles addieren.
;Ab der zweiten Seite dann MaxFiles-1
;addieren.
			ldx	WM_WCODE		;Auf erste Seite prüfen.
			lda	WIN_DIR_NR,x

			ldx	WM_DATA_MAXENTRY

			cmp	#$00			;Erste Seite?
			beq	:1			; => Ja, weiter...

;--- Ab Seite#2 MaxFiles -1 addieren.
			dex

;--- Positionszähler korrigieren.
::1			txa
			ldx	WM_WCODE		;Position im Verzeichnis
			clc				;berechnen.
			adc	WIN_DIR_NR,x
			sta	WIN_DIR_NR,x

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

::2			jsr	waitNoMseKey		;Warten bis keine M-Taste gedrückt.

			jmp	AL_OPEN_ENTRY		;AppLink öffnen.
