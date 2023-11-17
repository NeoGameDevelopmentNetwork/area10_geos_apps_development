; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Dateien tauschen.
;Dabei werden zwei markierte Dateien im
;Verzeichnis gegeneinander getauscht.
:xSWAPENTRIES		LoadW	r15,BASE_DIR_DATA	;Zeiger auf Anfang Verzeichnis.

			lda	#$00			;Dateizähler zurücksetzen.
			sta	r3L
if MAXENTRY16BIT = TRUE
			sta	r3H
endif
			sta	fileName1		;Dateiname #1 und #2 löschen.
			sta	fileName2

			LoadW	r4,fileName1
			jsr	getFileName		;Erste markierte Datei suchen.
			lda	fileName1		;Datei gefunden?
			beq	:exit			; => Nein, Ende...

			LoadW	r4,fileName2
			jsr	getNextFile		;Zweite markierte Datei suchen.
			lda	fileName2		;Datei gefunden?
			beq	:exit			; => Nein, Ende...

			jsr	SwapEntries		;Einträge tauschen.

;--- Ergänzung: 17.08.21/M.Kanet
;Fehlerstatus abfragen und auswerten.
			txa				;Diskettenfehler ?
			beq	:update

			pha				;Fehlercode zwischenspeichern.
			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.
			pla				;Fehlercode wieder einlesen.
			cmp	#WR_PR_ON		;Schreibschutz aktiv ?
			beq	:exit			; => Ja, weiter...
;---

::update		jsr	SET_LOAD_DISK		;Verzeichnis von Disk neu einlesen.
::exit			jmp	MOD_UPDATE		;Zurück zum FensterManager.

;*** Markierte Datei suchen.
:getFileName		ldy	#$00
			lda	(r15L),y		;Datei ausgewählt?
			and	#GD_MODE_MASK
			beq	getNextFile		; => Nein, weiter...

			ldy	#$02
			lda	(r15L),y		;Dateityp einlesen.
			cmp	#GD_MORE_FILES		;Eintrag "Weitere Dateien"?
			beq	getNextFile		; => Ja, ignorieren.

			lda	r15L			;Zeiger auf Dateiname in
			clc				;Verzeichnis-Eintrag berechnen.
			adc	#$05
			sta	r5L
			lda	r15H
			adc	#$00
			sta	r5H

			ldx	#r5L
			ldy	#r4L
			jmp	SysCopyName		;Dateiname kopieren.

:getNextFile		AddVBW	32,r15			;Zeiger auf nächsten Eintrag.

			inc	r3L			;Datei-Zähler +1.
if MAXENTRY16BIT = TRUE
			bne	:1
			inc	r3H
endif
::1
if MAXENTRY16BIT = TRUE
			lda	r3H
			cmp	WM_DATA_MAXENTRY +1
			bne	:2
endif
			lda	r3L
			cmp	WM_DATA_MAXENTRY +0
::2			bcc	getFileName		; => Weiter mit nächster Datei.
			rts

:fileName1		s 17
:fileName2		s 17

;*** Dateieinträge tauschen.
:SwapEntries		LoadW	r6,fileName1
			jsr	FindFile		;Erste Datei suchen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			MoveB	r1L,r11L		;Track/Sektor/Position des
			MoveB	r1H,r11H		;Verzeichnis-Eintrages sichern.
			MoveW	r5,r15

			ldy	#$00			;Verzeichnis-Eintrag
::1			lda	(r5L),y			;zwischenspeichern.
			sta	fileHeader,y
			iny
			cpy	#30
			bcc	:1

			LoadW	r6,fileName2
			jsr	FindFile		;Erste Datei suchen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			ldy	#$00			;Verzeichnis-Eintrag von
::2			lda	(r5L),y			;Datei #2 mit Datei #1 tauschen.
			pha
			lda	fileHeader,y
			sta	(r5L),y
			pla
			sta	fileHeader,y
			iny
			cpy	#30
			bcc	:2

			LoadW	r4,diskBlkBuf
			jsr	PutBlock		;Verzeichnis-Sektor speichern.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			MoveB	r11L,r1L		;Track/Sektor/Position für erste
			MoveB	r11H,r1H		;Datei wieder herstellen.
			MoveW	r15,r5

			jsr	GetBlock		;Verzeichnis-Sektor einlesen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			ldy	#$00			;Verzeichnis-Eintrag Datei #2
::3			lda	fileHeader,y		;an die Stelle von Datei #1
			sta	(r5L),y			;kopieren.
			iny
			cpy	#30
			bcc	:3

			jsr	PutBlock		;Verzeichnis-Sektor speichern.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

;--- NativeMode-Verzeichnisse korrigieren.
			lda	curType			;Laufwerkstyp einlesen.
			and	#DRIVE_MODES
			cmp	#DrvNative		;NativeMode ?
			bne	:exit			; => Nein, weiter...

			jsr	VerifyNMDir		;Verzeichnis-Header korrigieren.
::exit			rts
