; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** DeskTop-Modul laden.
:loadDTopMod1		ldy	#$01			;DeskTop-Routinen.
			b $2c
:loadDTopMod2		ldy	#$02			;Datei-Info.
			b $2c
:loadDTopMod3		ldy	#$03			;Drucker/Einagebe und
			b $2c				;Seite neu/löschen.
:loadDTopMod4		ldy	#$04			;DeskTop-Routinen.
			b $2c
:loadDTopMod5		ldy	#$05			;Uhrzeit/ShortCuts.
			cpy	a9L			;Modul geladen?
			bne	:1			; => Nein, weiter...

			jsr	setDrvNotRdy
			jmp	:loaded			;Modul starten.

::1			lda	a9L			;Aktuelles Modul
			pha				;zwischenspeichern.

			sty	a9L			;Neues Modul.

			lda	curDrive		;Aktuelles Laufwerk
			pha				;zwischenspeichern.

;--- DeskTop suchen.
::findDTop		jsr	r10_classDTop
			jsr	findFile_System
			cpx	#CANCEL_ERR		;Abbruch?
			beq	:cancel			; => Ja, Ende...
			txa				;Diskfehler?
			bne	:err			; => Ja, Abbruch...

			jsr	r0_buf_TempName
			jsr	OpenRecordFile
			txa				;Diskfehler?
			bne	:err			; => Ja, Abbruch...

			lda	a9L			;Zeiger auf Modul.
			jsr	PointRecord
			txa				;Diskfehler?
			bne	:err			; => Ja, Abbruch...

			ldy	#>vlirModBase
			sty	r7H
			ldy	#<vlirModBase
			sty	r7L			;Ladeadresse.

			lda	#>vlirModSize
			sta	r2H
			lda	#<vlirModSize
			sta	r2L			;Max. Größe.

			jsr	ReadRecord		;Modul einlesen.
			txa				;Diskfehler?
			beq	:ok			; => Nein, weiter...

::err			jsr	openErrBox1Line
			clv
			bvc	:findDTop		; => Weitersuchen...

::ok			pla				;Lfwk. zurücksetzen.
			jsr	setDevOpenDisk

			pla				;Letztes Modul...

::loaded		ldx	#NO_ERROR		;Kein Fehler.
			beq	:done			; => Weiter...

::cancel		pla				;Lfwk. zurücksetzen.
			jsr	setDevOpenDisk

;--- Hinweis:
;Wird das aktive Modul teilweise
;überschrieben und der Ladevorgang
;abgebrochen, dann kann es hier zu
;einem Absturz kommen, wenn man das
;Modul zurücksetzt.
			pla				;Aktuelles Modul
			sta	a9L			;zurücksetzen.

			jsr	unselectIcons

;--- Zurück zu Routine?
			lda	a9H			;Zurück zur Routine?
			bne	:2			; => Ja, Ende...

			pla				;Rücksprungadresse
			pla				;löschen.

;--- Abbruch/Fehler.
::2			ldx	#$ff

::done			txa
			pha

			lda	flagDrivesRdy
			bne	:3

			jsr	testSrcTgtDkRdy

::3			lda	#$00
			sta	a9H
			sta	flagDrivesRdy

;--- Status im X-Register übergeben.
			pla
			tax				;Z-Flag setzen!
			rts
