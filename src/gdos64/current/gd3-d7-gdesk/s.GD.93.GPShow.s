; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Diashow starten.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GTYP"
			t "SymbTab_APPS"
			t "SymbTab_GRFX"
			t "SymbTab_CHAR"
			t "SymbTab_KEYS"
			t "MacTab"

;--- Labels für GeoDesk64.
;			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
endif

;*** GEOS-Header.
			n "obj.GD93"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	StartSlideShow

;*** GeoPaint-Loader.
			t "-G3_ReadGPFile"

;*** Diashow starten.
:StartSlideShow		lda	curDrive		;Aktuelles Laufwerk
			sta	SystemDevice		;zwischenspeichern.

			LoadW	keyVector,testKeyData
			LoadW	appMain,viewPaintLoop

			lda	#$7f			;Flag setzen: "Dateiliste laden".
			sta	flagKeyMode

			lda	delayCount +4		;Anfangsverzögerung einstellen.
			sta	viewDelay

			jsr	MouseOff		;Mauszeiger ausblenden.

			jmp	GetBackScreen		;Hintergrundbild laden.

;*** Nächstes Laufwerk wählen.
:NextDrive		lda	#$7f			;Flag setzen: "Dateiliste laden".
			sta	flagKeyMode

			ldx	curDrive		;Aktuelles Laufwerk einlesen.
::next			inx				;Nächstes Laufwerk.
			cpx	#12			;Ende erreicht?
			bcc	:1			; => Nein, weiter...
			ldx	#8			;Zurück zu Laufwerk #8.

::1			cpx	SystemDevice		;Startlaufwerk erreicht?
			beq	ExitSlideShow		; => Ja, Ende...

			lda	driveType -8,x		;Laufwerk vorhanden?
			beq	:next			; => Nein, nächstes Laufwerk.
			txa
			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Fehler?
			beq	initPaintFiles		; => Nein, weiter...
			bne	NextDrive		; => Ja, nächstes Laufwerk...

;*** Diashow beenden.
:ExitSlideShow		lda	#$00
			sta	keyVector +0
			sta	keyVector +1
			sta	appMain +0
			sta	appMain +1

;--- HINWEIS:
;GPView überschreibt der Bereich mit
;den aktuellen Verzeichnisdaten für
;das oberste Fenster und verändert die
;Farben der System-/Menüleiste.
;Daher Neustart wie ":EnterDeskTop".
			jmp	MOD_REBOOT		;Desktop neu zeichnen.

;*** MainLoop: Bild anzeigen.
:viewPaintLoop		ldx	flagKeyMode		;Tastaturabfrage: Diashow beenden?
			bmi	ExitSlideShow		; => Ja, Ende...

			cpx	#$3f			;Zurück auf Anfang?
			beq	resetPaintFiles		; => Ja, weiter...

			cpx	#$7f			;Neue Liste einlesen?
			beq	initPaintFiles		; => Ja, weiter...

			cpx	#$00			;Nächste Datei anzeigen?
			beq	getNxPntFile		; => Ja, weiter...

			cpx	#8			;Neues Laufwerk wählen?
			bcc	getNxPntFile
			cpx	#12
			bcs	getNxPntFile		; => Nein, nächstes Bild...

			lda	driveType -8,x		;Laufwerk verfügbar?
			beq	NextDrive		; => Nein, nächstes Laufwerk...
			txa
			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Fehler?
			bne	ExitSlideShow		; => Ja, Abbruch...

;*** Dateiliste initialisieren.
:initPaintFiles		jsr	printInfo

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler?
			bne	ExitSlideShow		; => Ja, nächstes Laufwerk wählen.

			jsr	i_FillRam		;Speicher löschen.
			w	256*17
			w	FNameBuf
			b	$00

			LoadW	r6 ,FNameBuf
			LoadB	r7L,APPL_DATA
			LoadB	r7H,255
			LoadW	r10,AppClassPaint
			jsr	FindFTypes		;GeoPaint-Dateien suchen.
			txa				;Fehler ?
			bne	ExitSlideShow		; => Ja, Abbruch...

:resetPaintFiles	ldx	#NULL
			stx	flagKeyMode		;Tastenstatus löschen.
			stx	flagViewFile		;Status Bildanzeige löschen.

			inx
			stx	viewDelayCnt		;Verzögerung initialisieren.
			stx	viewDelayPause

			LoadW	curDirEntry,FNameBuf

;*** GeoPaint-Dateien anzeigen.
:getNxPntFile		dec	viewDelayPause		;Wartezeit abgelaufen?
			bne	:skip			; => Nein, Ende...

			lda	#50
			sta	viewDelayPause

			dec	viewDelayCnt		;Verzögerung abgelaufen?
			bne	:skip			; => Nein, Ende...

			bit	flagPauseMode		;Pausen-Modus?
			bpl	:do			; => Nein, Bild anzeigen.

::skip			rts

::do			MoveW	curDirEntry,r0		;Zeiger auf Dateiname.

			ldy	#0
			lda	(r0L),y			;Dateiname verfügbar?
			bne	:1			; => Ja, weiter...

			lda	#$3f			;Flag "Neustart".
			bit	flagViewFile		;Wurde eine Datei angezeigt?
			bmi	:setMode		; => Ja, weiter...
::errExit		lda	#$ff			;Flag "Abbruch".
::setMode		sta	flagKeyMode		;Status setzen.
			rts

::1			LoadW	r1,dataFileName
			ldx	#r0L
			ldy	#r1L
			jsr	CopyString		;Dateiname kopieren.

			LoadB	a0L,%00000000		;Farb-RAM nicht löschen.
			LoadW	a2,GrfxData		;Zeiger auf Zwischenspeicher.
			jsr	ViewPaintFile		;Bild anzeigen.
			txa				;Diskettenfehler?
			bne	:errExit		; => Ja, Abbruch...

			LoadB	flagViewFile,$ff	;Flag "Datei angezeigt".

			lda	curDirEntry +0		;Zeiger auf den nächsten
			clc				;Dateinamen.
			adc	#17
			sta	curDirEntry +0
			bcc	:2
			inc	curDirEntry +1

::2			lda	viewDelay		;Verzögerung zurücksetzen.
			sta	viewDelayCnt

			bit	flagInfoMode		;Info-Modus aktiv?
			bpl	:3			; => Nein, weiter...

			jsr	printFileName		;Dateiname ausgeben.

::3			rts				;Zurück zur MainLoop.

;*** Dateiname ausgeben.
:printFileName		jsr	clearInfo		;Info-Bereich löschen.

			LoadW	r0,dataFileName
			jmp	PutString		;Dateiname ausgeben.

;*** Status-Meldung anzeigen.
:printInfo		jsr	clearInfo		;Info-Bereich löschen.

			LoadW	r0,txLoading
			jmp	PutString		;Statusmeldung ausgeben.

;*** Infobereich löschen.
:info_width		= 20
:clearInfo		lda	#ST_WR_FORE		;Nur in Vordergrund schreiben.
			sta	dispBufferOn
			jsr	UseSystemFont		;Standard-Font setzen.

			jsr	i_GraphicsString	;Info-Bereich löschen.
			b	NEWPATTERN
			b	$00
			b	MOVEPENTO
			w	$0000
			b	$b8
			b	RECTANGLETO
			w	info_width*8 -1
			b	$c7
			b	FRAME_RECTO
			w	$0000
			b	$b8
			b	ESC_PUTSTRING		;Cursor-Position setzen.
			w	$0003
			b	$c3
			b	PLAINTEXT
			b	BOLDON
			b	NULL

			lda	C_WinBack		;Farbe löschen.
			jsr	i_UserColor
			b	$00,$17,info_width,$02

			lda	curDrive		;Laufwerk ausgeben.
			clc
			adc	#"A" -8
			jsr	SmallPutChar
			lda	#":"
			jsr	SmallPutChar

			rts

;*** Tastaturabfrage.
:testKeyData		lda	keyData
			cmp	#KEY_CR			;RETURN?
			bne	:1			; => Nein, weiter...

			lda	#$ff			;Status: "Abbruch".
			sta	flagKeyMode
			rts

::1			cmp	#"a"			;Laufwerk A:?
			beq	:drv8			; => Ja, weiter...
			cmp	#"b"			;Laufwerk B:?
			beq	:drv9			; => Ja, weiter...
			cmp	#"c"			;Laufwerk C:?
			beq	:drv10			; => Ja, weiter...
			cmp	#"d"			;Laufwerk D:?
			bne	:3			; => Nein, weiter...

::drv11			ldx	#11
			b $2c
::drv10			ldx	#10
			b $2c
::drv9			ldx	#9
			b $2c
::drv8			ldx	#8
			lda	driveType -8,x		;Laufwerk verfügbar?
			beq	:2			; => Nein, Ende...

			stx	flagKeyMode

			lda	#1			;Verzögerung zurücksetzen.
			sta	viewDelayPause
			sta	viewDelayCnt
::2			rts

::3			cmp	#"0"			;Taste 0-9?
			bcc	:4
			cmp	#"9" +1
			bcs	:4			; => Nein, weiter...

			sec				;Verzögerung berechnen.
			sbc	#$30
			tax
			lda	delayCount ,x
			sta	viewDelay

			lda	#1			;Verzögerung zurücksetzen.
			sta	viewDelayPause
			sta	viewDelayCnt
			rts

::4			cmp	#" "			;Nächstes Bild?
			bne	:5			; => Nein, weiter...

			ldx	#1			;Verzögerung zurücksetzen.
			stx	viewDelayPause
			stx	viewDelayCnt
			dex
			stx	flagPauseMode		;Pausenmodus zurücksetzen.

			rts

::5			cmp	#KEY_F7			;F7 = Pausen-Modus?
			bne	:6			; => Nein, weiter...

			lda	flagPauseMode		;Pausenmodus umschalten.
			eor	#%10000000
			sta	flagPauseMode

			lda	#1			;Verzögerung zurücksetzen.
			sta	viewDelayPause
			sta	viewDelayCnt
			rts

::6			cmp	#KEY_F5			;F5 = Info-Modus?
			bne	:7			; => Nein, weiter...

			lda	flagInfoMode		;Pausenmodus umschalten.
			eor	#%10000000
			sta	flagInfoMode

			lda	#1			;Verzögerung zurücksetzen.
			sta	viewDelayPause
			sta	viewDelayCnt
			rts

::7			rts				;Ungültige Taste, Ende...

;*** Variablen.
:AppClassPaint		b "Paint Image ",NULL

:SystemDevice		b $00
:curDirEntry		w $0000

:flagKeyMode		b $00
:flagViewFile		b $00
:flagPauseMode		b $00
:viewDelay		b $05
:viewDelayCnt		b $00
:viewDelayPause		b $00
:flagInfoMode		b $00

;*** Tabelle für Zeit-Verzögerung.
:delayCount		b 1				; 0
			b 35				; 1
			b 65				; 2
			b 75				; 3
			b 105				; 4
			b 135				; 5
			b 165				; 6
			b 195				; 7
			b 225				; 8
			b 255				; 9

;*** Statusmeldung.
:txLoading
if LANG = LANG_DE
			b	"Lade Dateiliste..."
endif
if LANG = LANG_EN
			b	"Loading file list..."
endif
			b	NULL

;*** Zwischenspeicher.
:DATABUF

;--- Speicher für Dateiauswahl.
:FNameBuf		= DATABUF

;--- Speicher für GeoPaint-Daten.
;Benötigter Speicher für eine Zeile:
; Grafikdaten: 1280 Bytes (80 Cards x 8 Bytes x 2 Zeilen)
; Reserviert :    8 Bytes
; Farbdaten  :  160 Bytes (80 Cards x 2 Zeilen)
;             ------------
;              1448 Bytes
;
:GrfxData		= FNameBuf   +(256 * 17)

:DATABUFEND		= GrfxData   +(640 * 2) +8 +(80 * 2)
:DATABUFSIZE		= (DATABUFEND - DATABUF)

;*** Endadresse testen:
			g OS_BASE - DATABUFSIZE
;***
