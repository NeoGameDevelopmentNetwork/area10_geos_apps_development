; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Gelöschte Dateieinträge entfernen.
:xPURGEFILES		lda	WM_DATA_MAXENTRY +0
if MAXENTRY16BIT = TRUE
			ora	WM_DATA_MAXENTRY +1
endif
			bne	:1			; => Dateien vorhanden, weiter...
			jmp	MOD_RESTART		;Keine Dateien, Abbruch...

;--- Zeiger auf ersten Verzeichnis-Sektor.
::1			lda	#$00
			sta	updateDir		;Verzeichnis-Update zurücksetzen.

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			jsr	Get1stDirEntry		;Zeiger erster Verzeichnis-Eintrag.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			cpy	#$ff			;Verzeichnis-Ende erreicht?
			bne	:findfile		; => Ja, weiter...
			jmp	:cancel

::error			jsr	doXRegStatus		;Fehlermeldung ausgeben.
			jmp	:cancel			;Funktion abbrechen.

;--- Zeiger auf Anfang Dateiliste.
::findfile		LoadW	a9,BASE_DIR_DATA	;Zeiger auf Verzeichnisdaten.

			ClrB	a8L			;Dateizähler löschen.
if MAXENTRY16BIT = TRUE
			sta	a8H
endif

;			MoveB	r1L,curDirSek +0	;Zeiger auf Track/Sektor
;			MoveB	r1H,curDirSek +1	;zwischenspeichern.

;--- Verzeichnis-Eintrag auswerten.
::loop			ldy	#$00
			lda	(a9L),y			;Auswahlk-Flag einlesen.
			and	#GD_MODE_MASK		;Datei ausgewählt?
			beq	:skip_file		; => Nein, weiter...
			iny
			iny
			lda	(a9L),y			;Datei gelöscht?
			bne	:skip_file		; => Nein, weiter...

;--- Markierte Datei im Verzeichnis suchen.
			dey
			dey
::2			lda	(r5L),y			;Verzeichnis-Eintrag mit aktuellem
			iny				;Dateieintrag vergleichen.
			iny
			cmp	(a9L),y
			bne	:skip_file
			dey
;			dey
;			iny
			cpy	#30			;Eintrag geprüft?
			bcc	:2			; => Nein, weiter...
			bcs	:purge_file

;--- Weiter mit nächster Datei.
::skip_file		inc	a8L			;Dateizähler +1.
if MAXENTRY16BIT = TRUE
			bne	:3
			inc	a8H
endif
::3
if MAXENTRY16BIT = TRUE
			lda	a8H			;Alle Dateien geprüft?
			cmp	WM_DATA_MAXENTRY +1
			bne	:4
endif
			lda	a8L
			cmp	WM_DATA_MAXENTRY +0
::4			bcs	:next_file		; => Ja, weiter...

			AddVBW	32,a9			;Nächsten Dateieintrag suchen.
			jmp	:loop

;--- Aktuellen Eintrag löschen.
::purge_file		jsr	PurgeEntry		;Verzeichniseintrag löschen.

;--- Weiter mit nächsten Eintrag.
::next_file		lda	r5L
			cmp	#7*32 +2
			bne	:skip_write

			bit	updateDir
			bpl	:skip_write

			jsr	WriteDirSek		;Verzeichnis-Sektor schreiben.
			txa				;Fehler ?
			bne	:error			; => Ja, Abbruch...

::skip_write		jsr	GetNxtDirEntry		;Zeiger auf nächsten Eintrag.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			cpy	#$ff			;Verzeichnis-Ende erreicht?
			bne	:findfile		; => Nein, weiter...

;--- Verzeichnis bearbeitet.
::cancel		jsr	SET_LOAD_DISK		;Verzeichnis neu einlesen.
			jmp	MOD_UPDATE		;Zurück zum DeskTop.

;*** Verzeichniseintrag löschen.
:PurgeEntry		ldy	#$ff
			sty	updateDir

			iny
			tya
::1			sta	(r5L),y			;Verzeichnis-Eintrag mit aktuellem
			iny
			cpy	#30
			bcc	:1

			rts

;*** Verzeichnis-Sektor auf Disk speichern.
:WriteDirSek		jsr	EnterTurbo		;GEOS-Turbo aktivieren.
			jsr	InitForIO		;I/O aktivieren.

;			MoveB	curDirSek +0,r1L	;Zeiger auf Track/Sektor
;			MoveB	curDirSek +1,r1H	;wieder zurücksetzen.
			LoadW	r4,diskBlkBuf		;Zeiger auf Dir_Sektor.
			jsr	WriteBlock		;Sektor schreiben.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...
			jsr	VerWriteBlock		;Sektor-Verify.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

;			lda	#$00
			sta	updateDir

::exit			jsr	DoneWithIO		;I/O abschalten.
;			txa				;Fehler?
;			bne	:error			; => Ja, Abbruch...

;			ldx	#NO_ERROR
::error			rts

;*** Variablen.
;updateDir		b $00				;In "-111_Recover" definiert.
