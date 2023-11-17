; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Aktuelle Uhrzeit ausgeben.
.GD_INITCLOCK		lda	#$ff			;Aktuellen Zeitwert löschen.
			sta	clockTimeBuf

:GD_DRAWCLOCK		jsr	ResetFontGD		;Zeichensatz aktivieren.

;--- Bildschirmausgabe vorbereiten.
			jsr	MAIN_RESETAREA		;Textgrenzen löschen.

;--- Datum+Zeit nur alle 60sec. ausgeben.
			lda	minutes			;Aktuelle Minuten-Wert einlesen.
			cmp	clockTimeBuf		;Minute verändert?
			bne	:restart		; => Ja, Datum+Zeit ausgeben.

;--- Nur Sekunden-Wert aktualisieren.
			MoveW	clockXPosBuf,r11
			LoadB	r1H,MIN_AREA_BAR_Y +14
			jmp	:seconds		;Nur Sekundenwert ausgeben.

;--- Position für Datum setzen.
::restart		sta	clockTimeBuf		;Neuen Minuten-Wert speichern.

			LoadW	r11,MAX_AREA_BAR_X-$3f +3
			LoadB	r1H,MIN_AREA_BAR_Y +7

;--- Datum ausgeben.
			lda	day
			jsr	:prntNum
			lda	#"."
			jsr	SmallPutChar
			lda	month
			jsr	:prntNum
			lda	#"."
			jsr	SmallPutChar
			lda	millenium
			jsr	:prntNum
			lda	year
			jsr	:prntNum

			lda	#" "
			jsr	SmallPutChar

;--- Position für Uhrzeit setzen.
			LoadW	r11,MAX_AREA_BAR_X-$3f +3
			LoadB	r1H,MIN_AREA_BAR_Y +14

;--- Uhrzeit ausgeben.
			lda	hour
			jsr	:prntNum
			lda	#":"
			jsr	SmallPutChar
			lda	minutes
			jsr	:prntNum
			lda	#"."
			jsr	SmallPutChar

			MoveW	r11,clockXPosBuf	;Sekunden-Position speichern.

::seconds		lda	seconds
			jsr	:prntNum

			lda	#" "
			jsr	SmallPutChar

;--- HotCorners auswerten.
			lda	#< ChkHotCorners	;HotCorners auswerten.
			ldx	#> ChkHotCorners

			bit	mouseData		;Maustaste gedrückt?
			bmi	:1			; => Ja, HotCorners überspringen.

			lda	#< chkHCexit		;HotCorner-Status zurücksetzen.
			ldx	#> chkHCexit

::1			jsr	CallRoutine		;Aktion ausführen/zurücksetzen.

;--- Bildschirmschoner starten?
::testScrSvr		bit	Flag_RunScrSvr		;Sofortstart Bildschirmschoner?
			bpl	:exit			; => Nein, Ende...

::start_saver		lda	#%00000000		;Zähler löschen und
			sta	Flag_ScrSaver		;Bildschirmschoner starten.
			sta	Flag_RunScrSvr

::exit			rts

;--- Dezimal-Zahl 00-99 ausgeben.
::prntNum		jsr	DEZ2ASCII		;Zahl von DEZ nach ASCII wandeln.
			pha
			txa
			jsr	SmallPutChar		;10er ausgeben.
			pla
			jmp	SmallPutChar		;1er ausgeben.

;*** Zwischenspeicher für Zeitausgabe.
:clockXPosBuf		w $0000				;X-Position für Sekunden-Ausgabe.
:clockTimeBuf		b $ff				;Letzter Wert für Minute.

;*** HotCorner auswerten.
:ChkHotCorners		lda	mouseXPos +1		;X-Position in Cards berechnen.
			lsr
			lda	mouseXPos +0
			ror
			lsr
			lsr
			tax				;X-Position.

			lda	mouseYPos		;Y-Position berechnen.
			lsr
			lsr
			lsr

			beq	:upper			;Y-Pos= 0 => Ecken 1+2 testen.
			cmp	#24			;Y-Pos=24 ?
			bne	exitHC			; => Ja, Ecken 3+4 testen.

::lower			jmp	chkHClower		;Unten links/rechts testen.
::upper			jmp	chkHCupper		;Open links/rechts testen.

;*** Maus nicht in HotCorner-Bereich.
:chkHCexit		ldy	#3
			lda	#$ff			;Maus nicht im HotCorner-Bereich,
::1			sta	curTimerHC,y		;Status zurücksetzen.
			dey
			bpl	:1
:exitHC			rts

;*** HotCorner links/rechts testen.
:chkHClower		ldy	#2			;Unten links/rechts testen.
			b $2c
:chkHCupper		ldy	#0			;Oben links/rechts testen.
			txa				;X-Pos = 0 ?
			beq	:left_right		; => Ja, weiter...
			iny
			cmp	#40 -1			;X-Pos = 39 ?
			bne	chkHCexit		; => Nein, Abbruch...

;--- Mauszeiger im HotCorner-Bereich.
::left_right		lda	GD_HC_CFG1,y		;HotCorner bei Mauszeiger aktiv?
			bpl	exitHC			; => Nein, Abbruch...

			jsr	testHCtimer		;Timer für HotCorner abgelaufen?
			bcc	exitHC			; => Nein, Ende...

			lda	#$ff			;Timer zurücksetzen.
			sta	curTimerHC,y

			pla				;Rücksprung aus ":DrawClock"
			pla				;vom Stack entfernen.

			sty	r10L			;HotCorner speichern.

			lda	#GEXT_START_HC		;Funktion für HotCorner ausführen.
			jmp	LdDTopMod

;*** Timer für HotCorner testen.
:testHCtimer		lda	curTimerHC,y		;Timer bereits aktiv?
			bpl	:l1			; => Ja, weiter...

			lda	seconds			;Timer mit aktuellen Sekunden-Wert
			sta	curTimerHC,y		;initialisieren.
			clc				;C=0 => Timer aktiv.
			rts

::l1			lda	seconds			;Aktuellen Sekunden-Wert einlesen.
			cmp	curTimerHC,y		;Sekunde < Timer ?
			bcs	:l2			; => Nein, weiter...
			clc				;Überlauf Sekunden-Zähler durch
			adc	#60			;Addition von 60sek. korrigieren.
::l2			sec
			sbc	curTimerHC,y		;Timer-Differenz berechnen.
			cmp	GD_HC_TIMER1,y		;Timer abgelaufen?
;			clc				; => Nein, Timer aktiv.
;			sec				; => Ja, Timer abgelaufen.
			rts

;*** Aktueller HotCorner-Status.
:curTimerHC		b $ff,$ff,$ff,$ff		;Timer-Initialisierung.
