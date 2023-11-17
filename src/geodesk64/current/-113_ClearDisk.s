; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Diskette löschen.
:doClearDisk		jsr	OpenWinDrive		;Ziel-Laufwerk öffnen.
			txa				;Fehler?
			beq	:1			; => Nein, weiter...
::err			rts				;Fehler, Abbruch.

::1			ldx	WM_WCODE
			ldy	WIN_DRIVE,x		;Laufwerksadresse einlesen.
			lda	RealDrvMode -8,y	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			beq	:2			; => Kein NativeMode, weiter...

			jsr	OpenRootDir		;Hauptverzeichnis öffnen.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch.

::2			jsr	getMaxTracks		;Max. Anzahl Tracks einlesen.

			bit	optClearDir		;Verzeichnis löschen?
			bpl	:3			; => Nein, weiter...

			jsr	ClearDirHead		;GEOS-Kennung löschen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			jsr	ClearDirSek		;Verzeichnis löschen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			jsr	ClearBAM		;BAM löschen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

::3			jsr	saveDiskName		;Neuen Disknamen speichern.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler ?
			bne	:err			; => Ja, Abbruch.

			bit	curDiskGEOS		;GEOS-Disk erzeugen?
			bpl	:4			; => Nein, weiter...

			jsr	SetGEOSDisk		;GEOS-Disk erstellen.
			txa				;Fehler ?
			bne	:err			; => Ja, Abbruch.

::4			bit	optClearSek		;Leere Sektoren löschen?
			bpl	:5			; => Nein, weiter...

			jsr	ClearDataSek		;Freie Sektoren mit 0-Bytes füllen.
			txa				;Fehler ?
			bne	:err			; => Ja, Abbruch.

::5			ldx	#NO_ERROR		;Kein Fehler...
			rts				;Ende.

;*** Flag setzen "Disk aktualisieren".
;
;Wird durch das Registermenü gesetzt
;wenn Disk-Name oder Status GEOS-Disk
;geändert wird.
;
:setReloadDir		lda	#$ff
			sta	reloadDir
			rts

;*** Disk-Name aktualisieren.
:saveDiskName		jsr	GetDirHead		;BAM einlesen.
			txa				;Fehler?
			bne	:5			; => Ja, Abbruch...

			ldy	#0			;Disk-Name in BAM kopieren.
::1			lda	textDrvName,y
			beq	:2
			sta	curDirHead +$90,y
			iny
			cpy	#16
			bcc	:1
			bcs	:4

::2			lda	#$a0			;Disk-Name mit $A0 auffüllen.
::3			sta	curDirHead +$90,y
			iny
			cpy	#16
			bcc	:3

::4			jsr	PutDirHead		;BAM auf Disk speichern.

::5			rts

;*** GEOS-Header löschen.
:ClearDirHead		ldx	#$ab			;GEOS-Kennung löschen.
			lda	#$00
::1			sta	curDirHead,x
			inx
			cpx	#$be
			bcc	:1

			jmp	PutDirHead		;BAM speichern.

;*** Verzeichnis-Sektoren löschen.
:ClearDirSek		ClrB	firstDirSek		;Erster Sektor.

			lda	curType			;Zeiger auf ersten Verzeichnis-
			jsr	Get1stDirBlk		;Sektor setzen.
			txa				;Fehler?
			beq	:1			; => Nein, weiter...
::err			rts

::1			LoadW	r4,diskBlkBuf		;Zeiger auf Zwischenspeicher.
::2			jsr	GetBlock		;Verzeichnis-Sektor einlesen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			lda	diskBlkBuf +0		;Zeiger auf nächsten Verzeichnis-
			pha				;Sektor zwischenspeichern.
			lda	diskBlkBuf +1
			pha

;			ldx	#$00			;Verzeichnis-Sektor löschen.
			txa
::3			sta	diskBlkBuf,x
			inx
			bne	:3

			bit	firstDirSek		;Erster Verzeichnis-Sektor?
			bmi	:4			; => Nein, weiter...
			dec	diskBlkBuf +1		;$00/$FF = Verzeichnis-Ende.
			dec	firstDirSek

::4			jsr	PutBlock		;Verzeichnis-Sektor speichern.

			pla				;Zeiger auf nächsten Verzeichnis-
			sta	r1H			;Sektor einlesen.
			pla
			sta	r1L

			cpx	#NO_ERROR		;Fehler?
			bne	:err			; => Ja, Abbruch...

			tax				;Weitere Verzeichnis-Sektor?
			bne	:2			; => Ja, weiter...

;			ldx	#NO_ERROR		;Kein Fehler.
			rts				;Ende.

;*** Datensektoren löschen.
:ClearDataSek		LoadB	statusPos,$00		;Zeiger auf erste Spur.
			lda	maxTrack
			sta	statusMax
			jsr	DrawStatusBox		;Status-Box anzeigen.
			jsr	prntDiskInfo		;Disk-/Verzeichnisname ausgeben.

			ClrB	lastTrack		;Aktuellen Track löschen.

			jsr	EnterTurbo		;TurboDOS starten.
			jsr	InitForIO		;I/O aktivieren.

			ldx	#$00			;Datensektor löschen.
			txa
;			lda	#$fd			;Dummy-Wert für Debugging.
::1			sta	diskBlkBuf,x
			inx
			bne	:1

			ldx	#$01			;Zeiger auf ersten Disksektor.
			stx	r1L
			dex
			stx	r1H

			LoadW	r4,diskBlkBuf		;Zeiger auf Zwischenspeicher.

::loop			lda	r1L
			cmp	lastTrack		;Track anzeigen?
			beq	:2			; => Nein, weiter...

			sta	lastTrack		;Neuen Track speichern.

			jsr	DoneWithIO		;I/O ausschalten.
			jsr	prntStatus		;Status aktualisieren.
			jsr	InitForIO		;I/O einschalten.

			inc	statusPos

::2			MoveB	r1L,r6L
			MoveB	r1H,r6H
			jsr	FindBAMBit		;Ist Sektor frei?
			beq	:3			; => Nein, weiter...

			jsr	WriteBlock		;Sektor löschen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch..

::3			jsr	GetNextSekAdr		;Zeiger auf nächsten Sektor.
			txa				;Weiterer Sektor verfügbar?
			beq	:loop			; => Ja, weiter...

			ldx	#NO_ERROR		;Kein Fehler.

::exit			jmp	DoneWithIO		;I/O abschalten.

;*** Variablen.
:textDrvName		s 17
:optClearDir		b $ff
:optClearSek		b $00
:curDiskGEOS		b $00
:firstDirSek		b $00
:lastTrack		b $00
