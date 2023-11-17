; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Anwendung starten auf die ":r0" zeigt.
;    Übergabe: r0 = Zeiger auf 32Byte Verzeichnis-Eintrag.
;        Oder:      Zeiger auf dirEntryBuf -2.
;
;    Hinweis:
;:r0 als Quelle und :a0 als Ziel da die
;Register :r0-:r15 durch UPDATE_GD_CORE und
;VLIR-Routinen verändert werden können.
;
:StartFile_r0		MoveW	r0,a0			;Zeiger auf Eintrag nach :a0.
			jsr	UPDATE_GD_CORE		;Variablen sichern.
			jmp	MOD_OPEN_FILE		;VLIR-Modul "StartFile" aufrufen.

;*** Anwendung/Dokument/DA öffnen.
;    Übergabe: r0 = Zeiger auf 32Byte Verzeichnis-Eintrag.
;        Oder:      Zeiger auf dirEntryBuf -2.
:OpenFile_r0		ldy	#$02
			lda	(r0L),y
			and	#FTYPE_MODES		;Dateityp isolieren.
			cmp	#FTYPE_DIR		;Verzeichnis?
			beq	:3			; => Ja, weiter...

			jsr	CheckFType		;Dateityp auswerten.
			cpx	#NO_ERROR		;Starten möglich?
			beq	:1			; => Ja, weiter...
			cmp	#SYSTEM			;System-Datei?
			beq	:2			; => Ja, weiter... (GeoDesk-Farben?)
			rts

;--- Datei öffnen.
::1			cmp	#PRINTER		;Drucker?
			beq	:4			; => Ja, weiter...
::2			jmp	StartFile_r0

;--- Verzeichnis öffnen.
::3			iny				;Track/Sektor für
			lda	(r0L),y			;Verzeichnis-Header einlesen.
			sta	r1L
			ldx	WM_WCODE
			sta	WIN_SDIR_T,x
			iny
			lda	(r0L),y
			sta	r1H
			sta	WIN_SDIR_S,x
			jsr	OpenSubDir		;Verzeichnis öffnen.

			lda	#$00			;Zeiger auf ersten Eintrag.
			sta	WM_DATA_CURENTRY +0
if MAXENTRY16BIT = TRUE
			sta	WM_DATA_CURENTRY +1
endif

			jsr	WM_SAVE_WIN_DATA	;Fensterdaten speichern.

			jsr	SET_LOAD_DISK		;Dateien von Disk neu einlesen.
			jmp	WM_CALL_DRAW		;Fenster neu laden.

;--- Drucker öffnen.
::4			LoadW	r6,dataFileName		;Zeiger auf Druckername.
			ldx	#r0L 			;Dateiname aus Verzeichnis-Eintrag
			ldy	#r6L			;in Puffer kopieren.
			jsr	SysCopyFName
			jsr	SUB_OPEN_PRNT		;Druckertreiber wechseln.

			ldx	WM_MYCOMP		;Fenster "MyComputer" geöffnet?
			beq	:exit			; => Nein, weiter...

			lda	WM_WCODE		;Aktuelles Fenster einlesen und
			pha				;zwischenspeichern.

			stx	WM_WCODE		;Fenster "MyComputer" aktualisieren.
			jsr	WM_CALL_DRAW

			pla				;Fenster-Nr. zurücksetzen und
			sta	WM_WCODE		;Fenster neu darstellen.
::exit			jmp	WM_CALL_DRAW

;*** Auf gültigen GEOS-Dateityp testen.
;    Übergabe: r0 = Zeiger auf 32Byte Verzeichnis-Eintrag.
;        Oder:      Zeiger auf dirEntryBuf -2.
;    Rückgabe: XReg = $00/Datei gültig oder #INCOMPATIBLE.
:CheckFType		ldx	#NO_ERROR

			ldy	#$18			;Dateityp auswerten.
			lda	(r0L),y
			beq	:ok			; => BASIC-Programm.
			cmp	#APPLICATION		;Anwendung?
			beq	:ok			; => Ja, weiter...
			cmp	#AUTO_EXEC		;AutoExec?
			beq	:ok			; => Ja, weiter...
			cmp	#APPL_DATA		;Dokument?
			beq	:ok			; => Ja, weiter...
			cmp	#DESK_ACC		;Hilfsmittel?
			beq	:ok			; => Ja, weiter...
			cmp	#PRINTER		;Drucker?
			beq	:ok			; => Ja, weiter...

			ldx	#INCOMPATIBLE		;Unbekannt, Ende...
::ok			rts
