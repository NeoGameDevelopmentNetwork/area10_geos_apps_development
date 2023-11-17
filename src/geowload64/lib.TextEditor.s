; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; lib.TextEditor
;
;GEOS-Bibliothek für Texteingabe.
; * Word-Wrapping
; * Mehrzeiliger Text
; * Cursor-Unterstützung
; * Befehl senden/Daten empfangen
;
; (w) 2022 / M.Kanet
;
; v0.10: Initial release.
;

;
; Text-Eingaberoutine.
;
;BoxLeft		= 80   ;Grenzen für Infoblock-Fenster.
;BoxRight		= 240
;BoxTop			= 100
;BoxBottom		= 144
;INPUT_MAX_LEN		= 96
;
;			LoadW	r0 ,iText      ;Textspeicher.
;			LoadB	r2L,BoxTop     ;Oben.
;			LoadB	r2H,BoxBottom  ;Unten.
;			LoadW	r3 ,BoxLeft    ;Links.
;			LoadW	r4 ,BoxRight   ;Rechts.
;			LoadB	r5L,%10000000  ;Bit%7=1: CR erlaubt.
;			jsr	InputText
;			rts
;
;Nach der Eingabe folgende Vektoren zurücksetzen:
;
; :keyVector		= $0000
; :alphaFlag		= %0xxxxxxx
;
;Cursor abschalten mit:
;
;			jsr	PromptOff   ;Cursor abschalten.
;
;Oder Systemroutine verwenden:
;
;			jsr	InputExit   ;Text-Eingabe beenden.
;

;*** Variablen für Text-Eingabe.
:INPUT_MAX_LEN		= 254
:INPUT_MAX_LINE		= 3

;*** Übergabeparameter.
:INPUT_SIZE		s $06
:INPUT_VEC_BUF		w $0000
:INPUT_ENABLE_CR	b $00
:INPUT_ENABLE_SP	b $00

;*** Daten für Texteingabe.
:tabKeyWidth		s 256
:flagPosEOL		b $00
:charMaxCount		b $00
:charCurPos		b $00

;*** INPUT-Routine aktivieren.
:InputText		lda	r0L			;Zeiger auf Textdaten sichern.
			sta	INPUT_VEC_BUF +0
			lda	r0H
			sta	INPUT_VEC_BUF +1

			ldx	r2L			;Obere Grenze Eingabefeld.
			inx
			stx	INPUT_SIZE+0

			ldx	r2H			;Untere Grenze Eingabefeld.
			dex
			stx	INPUT_SIZE+1

			lda	r3L			;Linke Grenze Eingabefeld.
			clc
			adc	#< $0003
			sta	INPUT_SIZE+2
			lda	r3H
			adc	#> $0003
			sta	INPUT_SIZE+3

			lda	r4L			;Rechte Grenze Eingabefeld.
			sec
			sbc	#< $0003
			sta	INPUT_SIZE+4
			lda	r4H
			sbc	#> $0003
			sta	INPUT_SIZE+5

			lda	#$00
			sta	INPUT_ENABLE_CR
			sta	INPUT_ENABLE_SP

			lda	r5L			;Flags für RETURN und SPACE
			asl				;einlesen und zwischenspeichern.
			ror	INPUT_ENABLE_CR
			asl
			ror	INPUT_ENABLE_SP

;--- Vorgabetext definieren.
			jsr	UseSystemFont
			LoadB	currentMode,SET_PLAINTEXT

			jsr	SetTextAdr		;Zeiger auf Textspeicher setzen.

			ldy	#$00			;Zeiger auf erstes Zeichen.
::nxChar		sty	r1L			;Zeiger auf Text zwischenspeichern.

			lda	(r0L),y			;Zeichen einlesen. Ende erreicht?
			beq	:done			; => Ja, Ende...

			ldy	#$00			;Vorgabewert Breite = 0.
			cmp	#$20			;Zeichen < $20?
			bcc	:1			; => Ja, übrgehen.

			ldx	currentMode
			jsr	GetRealSize		;Breite aktuelles Zeichen holen.

::1			tya				;Zeichenbreite retten.

			ldy	r1L
			sta	tabKeyWidth,y		;Zeichenbreite speichern.

			iny
			cpy	#INPUT_MAX_LEN		;Max. Anzahl Zeichen erreicht?
			bcc	:nxChar			; => Nein, weiter...

::done			sty	charMaxCount		;Anzahl Zeichen speichern.

			jsr	ClrTextBuf		;Rest des Textspeichers löschen.

;--- Eingabe initialisieren.
			lda	#8			;Höhe des Textcursors.
			jsr	InitTextPrompt

			lda	#<iCheckInput		;Tastaturabfrage installieren.
			sta	keyVector  +0
			lda	#>iCheckInput
			sta	keyVector  +1

			lda	alphaFlag		;Cursor einschalten.
			ora	#%10000000
			sta	alphaFlag
			jsr	PromptOn
			cli

			jsr	InitForIO		;I/O-Bereich aktivieren.
			lda	C_Mouse			;Cursor-Farbe setzen.
			sta	mob1clr
			jsr	DoneWithIO		;I/O-Bereich abschalten.

			jsr	PrintText		;Gesamten Text ausgeben.

;			jsr	Home			;Zum Textanfang springen.

			jsr	FindLastChar		;Zum Textende springen.
			sty	charCurPos		;Cursorposition speichern und
			jmp	SetCursor		;Cursor hinter Zeichen setzen.

;*** Texteingabe beenden.
:InputExit		jsr	InitForIO		;I/O-Bereich aktivieren.
			lda	#$00			;Farbe für Cursor zurücksetzen.
			sta	mob1clr
			jsr	DoneWithIO		;I/O-Bereich abschalten.

			jsr	PromptOff		;Cursor abschalten.

			lda	#$00			;Tastenabfrage löschen.
			sta	keyVector +0
			sta	keyVector +1

			lda	alphaFlag		;Cursor ausblenden.
			and	#%01111111
			sta	alphaFlag

			rts

;*** Ganzen Text ausgeben.
:PrintText		jsr	UseSystemFont		;Systemfont aktivieren.

			lda	#SET_PLAINTEXT		;Textstil auf Standard setzen.
			sta	currentMode

;--- Eingabefeld löschen.
			ldx	INPUT_SIZE+0		;Grenzen für Eingabefeld setzen.
			stx	r2L
			ldx	INPUT_SIZE+1
			stx	r2H

			lda	INPUT_SIZE+2
			sec
			sbc	#< $0003
			sta	r3L
			lda	INPUT_SIZE+3
			sbc	#> $0003
			sta	r3H

			lda	INPUT_SIZE+4
			clc
			adc	#< $0003
			sta	r4L
			lda	INPUT_SIZE+5
			adc	#> $0003
			sta	r4H

			lda	#$00
			jsr	SetPattern		;Füllmuster setzen.
			jsr	Rectangle		;Eingabefeld löschen.

;--- Text ausgeben.
			jsr	SetTextAdr		;Zeiger auf Textspeicher setzen.

			ldx	#$00
::newLine		inx
			stx	r15L			;Zeilenposition speichern.

			stx	r4H
			jsr	FindLineLength		;Zeilenlänge ermitteln.

			lda	r3L			;Zähler erstes Zeichen in Zeile.
			sta	r14L
			clc
			adc	r2L			;Anzahl Zeichen.
			sta	r14H			;Zähler letztes Zeichen in Zeile.

			jsr	SetLowXPos		;X-Position für Textausgabe.

			ldy	r14L			;Zeiger auf Textspeicher.
::nxChar		lda	(r0L),y			;Zeichen einlesen. Ende erreicht?
			beq	:done			; => Ja, Ende...

			cmp	#CR			;Zeilenumbruch?
			bne	:1			; => Nein, weiter...

			bit	INPUT_ENABLE_CR		;Zeilenumbruch erlaubt?
			bmi	:nxLine			; => Ja, weiter...
			bpl	:done			; => Nein, Ende...

::1			jsr	SmallPutChar		;Zeichen ausgeben.

			inc	r14L			;Zeichenzähler aktuelle Zeile +1.

			ldy	r14L			;Zeichenzähler einlesen.
			cpy	charMaxCount		;Alle Zeichen ausgegeben?
			beq	:done			; => Ja, Ende...
			cpy	r14H			;Ende der Zeile erreicht?
			bne	:nxChar			; => Nein, weiter...

::nxLine		ldx	r15L
			cpx	#INPUT_MAX_LINE		;Letzte Zeile ausgegeben?
			bcs	:done			; => Ja, Ende...

			jsr	Add10YPos		;Cursor auf nächste Zeile setzen.

;			lda	r1H
			cmp	INPUT_SIZE+1		;Ende Eingabefeld erreicht?
			bcc	:newLine		; => Nein, weiter...

::done			jmp	RegisterSetFont

;*** Zeiger auf Textspeicher setzen.
:SetTextAdr		lda	INPUT_VEC_BUF +0
			sta	r0L
			lda	INPUT_VEC_BUF +1
			sta	r0H
			rts

;*** Eine Zeile tiefer.
:Add10YPos		lda	r1H
			clc
			adc	#10
			sta	r1H
			rts

;*** Cursor an den linken Rand.
:SetLowXPos		lda	INPUT_SIZE+2
			sta	r11L
			lda	INPUT_SIZE+3
			sta	r11H
			rts

;*** Cursor an den oberen Rand.
:SetLowYPos		lda	INPUT_SIZE+0
			clc
			adc	#8
			sta	r1H
			rts

;*** Rest des Textspeichers löschen.
;Übergabe: YReg = Zeiger auf Textspeicher.
:ClrTextBuf		lda	#NULL
::1			sta	(r0L),y			;Rest des Textspeichers löschen.
			sta	tabKeyWidth,y		;Speicher Zeichenbreite löschen.
			iny
			cpy	#INPUT_MAX_LEN +1
			bcc	:1
			rts

;*** Cursor setzen/einschalten.
:SetCursor		lda	r11L			;Cursor-X-Position speichern.
			sta	stringX +0
			lda	r11H
			sta	stringX +1

			lda	r1H			;Cursor-Y-Position speichern.
			sec
			sbc	baselineOffset
			sta	stringY

			jmp	PromptOn		;Cursor einschalten.

;*** Letztes Zeichen suchen.
;Rückgabe: XReg = $FF:Ende Textspeicher erreicht.
:FindLastChar		lda	#%10000000		;Leztztes Zeichen suchen.
			b $2c

;*** Länge der aktuellen Zeile berechnen.
;Übergabe: r4H = Zeilennummer.
:FindLineLength		lda	#%00000000		;Lände der aktuellen Zeile testen.
			sta	r4L

			jsr	SetTextAdr		;Zeiger auf Textspeicher setzen.

			jsr	SetLowYPos		;Cursor auf erste Zeile setzen.

			ldy	#$00
			sty	r3H			;Anzahl Zeilen = 0.
::loop			sty	r3L			;Zeiger auf aktuelles Zeichen.

			jsr	SetLowXPos		;Cursor auf Anfang der Zeile setzen.

			lda	#$00
			sta	r2L			;Länge der aktuellen Zeile = 0.
			sta	r2H			;Position letztes Leerzeichen.

::nxChar		lda	(r0L),y			;Zeichen aus Speicher einlesen.
			beq	:done			;$00-Byte? Ja, Text-Ende.

			cmp	#" "			;Leerzeichen?
			bne	:3			;Nein, weiter...

			ldx	r2L			;Zeilenlänge ab Leerzeichen
			inx				;ermitteln.
			stx	r2H

::3			inc	r2L			;Anzahl Zeichen in Zeile +1.

			cmp	#CR			;RETURN?
			bne	:3d			; => Nein, weiter...

			bit	INPUT_ENABLE_CR		;RETURN erlaubt?
			bmi	:3a			; => Ja, weiter...
			dec	r2L			;Zeilenende.
			jmp	:done			;Auswertung beenden.

::3d			lda	r11L			;Zeichenbreite addieren.
			clc
			adc	tabKeyWidth,y
			sta	r11L
			lda	r11H
			adc	#$00
			sta	r11H

			iny				;Zeiger auf nächstes Zeichen.

			lda	r11H			;Rechte Grenze für Textfeld
			cmp	INPUT_SIZE+5		;überschritten?
			bne	:3b
			lda	r11L
			cmp	INPUT_SIZE+4
::3b			bcc	:nxChar			; => Nein, weiter...

			dec	r2L			;Letztes Zeichen ignorieren.

;--- Zeilenende erreicht.
::eol			ldx	r2H			;Leerzeichen in Zeile vorhanden?
			beq	:3a			; => Nein, weiter...
			cpx	r2L			;Leerzeichen an aktueller Position?
			bcs	:3a			; => Ja, weiter...
			stx	r2L 			;Zeile zu lang.
							;Max. Zeilenlänge auf letztes
							;Leerzeichen begrenzen.

::3a			lda	r3L			;Erstes Zeichen der Zeile und
			clc				;Anzahl Zeichen in Zeile
			adc	r2L			;addieren.
			tay

			ldx	r3H			;Aktuelle Zeile einlesen.
			inx				;Anzahl Zeilen +1.

			bit	r4L			;Länge der Textzeile ermitteln?
			bmi	:3c			; => Nein, weiter...

			cpx	r4H			;Gesuchte Zeile erreicht?
			beq	:exit			; => Ja, Ende...

::3c			cpx	#INPUT_MAX_LINE		;Letzte Zeile erreicht?
			beq	:6			; => Ja, Ende...
			stx	r3H			;Neue Zeilenposition speichern.

			jsr	Add10YPos		;Cursor-Position auf nächste Zeile.

			jmp	:loop			;Weiter mit nächstem Zeichen.

::6			ldx	#$ff			;Ende Textspeicher erreicht.
			b $2c
::done			ldx	#$00			;Weitere Zeicheneingabe möglich.
			sty	charMaxCount		;Anzahl Zeichen in Textspeicher.

			cpy	charCurPos		;Position größer als Anzahl Zeichen?
			bcs	:8			; => Nein, weiter...
			sty	charCurPos		;Cursor hinter letztes Zeichen.

::8			jsr	ClrTextBuf		;Rest des Textspeichers löschen.

			ldy	charMaxCount		;Anzahl Zeichen in Textspeicher.
::exit			rts

;*** Cursor-Position ermiteln.
; -> curPosChar zeigt auf das Zeichen
;    hinter der letzten Eingabe.
; <- Rückgabe X/Y hinter dem Zeichen.
:FindPosChar		lda	#%10000000		;Cursor-Position für Zeichen suchen.
			b $2c
; -> stringX/Y zeigt auf die aktuelle
;    Cusror-Position.
; <- curCharPos und X/Y zeigen auf das
;    Zeichen vor dem Cursor.
:FindPosCursor		lda	#%00000000		;Koordinaten für Cursor suchen.
			sta	r4L

			jsr	SetTextAdr		;Zeiger auf Textspeicher setzen.

			jsr	SetLowYPos		;Cursor auf erste Zeile setzen.

			ldy	#$00

			sty	r4H			;Y-Position Zeichen/Cursor.
			sty	r5L			;X-Position Zeichen/Cursor-L.
			sty	r5H			;X-Position Zeichen/Cursor-H.
			sty	r6L			;":curCharPos" für Zeichen/Cursor.

			sty	r7L			;X-Position letztes Leerzeichen-L.
			sty	r7H			;X-Position letztes Leerzeichen-H.

			sty	r3H			;Anzahl Zeilen = 0.
::loop			sty	r3L			;Zeiger auf aktuelles Zeichen.

			jsr	SetLowXPos		;Cursor auf Anfang der Zeile setzen.

			lda	#$00
			sta	r2L			;Länge der aktuellen Zeile = 0.
			sta	r2H			;Position letztes Leerzeichen.

;--- FindPosCursor.
::nxChar		bit	r4L			;"FindPosChar"?
			bmi	:1a			; => Ja, weiter...

::testCursor		lda	r1H
			sec
			sbc	baselineOffset
			cmp	stringY			;Y-Position für Cursor gefunden?
			bne	:1a			; => Nein, weiter...

			lda	r11H
			cmp	stringX +1
			bne	:4a
			lda	r11L
			cmp	stringX +0		;X-Position =< Cursor-Position?
::4a			beq	:4c			; => X = Cursor, Position OK.
			bcs	:1a			; => X > Cursor, weiter...

::4c			jsr	:copyPos		;Aktuelle X/Y-Position sichern.

;--- FindPosChar.
::1a			bit	r4L			;"FindPosChar"?
			bpl	:5a			; => Nein, weiter...

			cpy	charCurPos		;Aktuelles Zeichen gefunden?
			bne	:5a			; => Nein, weiter...

			jsr	:copyPos		;Aktuelle X/Y-Position sichern.

;--- Zeichen auswerten.
::5a			lda	(r0L),y			;Zeichen aus Speicher einlesen.
			tax				;$00-Byte = Text-Ende?
			bne	:1b			; => Nein, weiter...
			jmp	:done			;Text-Ende erreicht.

::1b			inc	r2L			;Anzahl Zeichen in Zeile +1.

			cpx	#CR			;RETURN?
			bne	:3d			; => Nein, weiter...

			bit	INPUT_ENABLE_CR		;RETURN erlaubt?
			bmi	:3a			; => Ja, weiter...
			dec	r2L			;Zeichen ignorieren und als
			jmp	:done			;Text-Ende behandeln.

::3d			lda	r11L			;Zeichenbreite addieren.
			clc
			adc	tabKeyWidth,y
			sta	r11L
			lda	r11H
			adc	#$00
			sta	r11H

			cpx	#" "			;Leerzeichen?
			bne	:3f			; => Nein, weiter...

			lda	r2L			;Position letztes Leerzeichen
			sta	r2H			;in Zeile zwischenspeichern.

			lda	r1H
			sec
			sbc	baselineOffset
			cmp	stringY			;Aktuelle Zeile = Cursor-Zeile?
			bne	:3f			; => Nein, weiter...

			lda	r11L			;X-Position Leerzeichen speichern.
			sta	r7L
			lda	r11H
			sta	r7H

::3f			iny				;Zeiger auf nächstes Zeichen.

			lda	r11H
			cmp	INPUT_SIZE+5
			bne	:3b
			lda	r11L
			cmp	INPUT_SIZE+4		;Ende Textfenster überschritten?
::3b			bcs	:3g
			jmp	:nxChar			; => Nein, weiter...

;--- WordWrapping erreicht.
::3g			dec	r2L			;Zeichenzähler korrigieren.

			bit	r4L			;"FindPosCursor"?
			bmi	:eol			; => Nein, weiter...

			lda	r1H
			sec
			sbc	baselineOffset
			cmp	stringY			;Aktuelle Zeile = Cursor?
			bne	:eol			; => Nein, weiter...

;--- Zeilen-Umbruch in Cursor-Zeile.
			ldx	r2H			;Leerzeichen gefunden?
			beq	:eol			; => Nein, weiter..
			cpx	r6L			;Position < Leerzeichen?
			bcs	:eol			; => Ja, nicht korrigieren.
			stx	r2L			;Leerzeichen für curCharPos.

			lda	r7L			;X-Koordinate letztes Leerzeichen.
			ldy	r7H

			cpy	r5H			;Position > Cursor-Position?
			bne	:9a
			cmp	r5L
::9a			bcs	:eol			; => Ja, ignorieren...

			sta	r5L			;X-Koordinate hinter letztem
			sty	r5H			;Leerzeichen für Cursor setzen.

			lda	r3L			;Anfang der aktuellen Zeile.
			clc
			adc	r2L			;Anzahl Zeichen in Zeile.
			sta	r6L			;Position für curCharPos.

;--- Zeilenende erreicht.
::eol			ldx	r2H			;Leerzeichen gefunden?
			beq	:3a			; => Nein, weiter...
			cpx	r2L			;Position < aktuelle Position?
			bcs	:3a			; => Nein, weiter...
			stx	r2L 			;Zeile zu lang.

::3a			lda	r3L			;Anfang der aktuellen Zeile.
			clc
			adc	r2L			;Anzahl Zeichen in Zeile.
			tay				;Erstes Zeichen nächste Zeile.

			inc	r3H
			lda	r3H
			cmp	#INPUT_MAX_LINE		;Noch eine Zeile testen?
			beq	:done			; => Nein, Ende...

			jsr	Add10YPos		;Y-Koordinate auf nächste Zeile.
			jmp	:loop			;Nächstes Zeile auswerten.

;--- Aktuelle Position speichern.
::copyPos		sty	r6L			;Position für curCharPos speichern.

			lda	r1H			;Y-Koordinate für Cursor speichern.
			sta	r4H

			lda	r11L			;X-Koordinate für Cursor speichern.
			sta	r5L
			lda	r11H
			sta	r5H
			rts

;--- Text-Ende erreicht.
::done			ldy	r6L			;Aktuelle Position einlesen.
			bit	r4L			;FindPosCursor?
			bmi	:6a			; => Nein, weiter...
			sty	charCurPos		;curCharpos für aktuelle Positon.

::6a			lda	r4H			;Wurde Position gefunden?
			beq	:exit			; => Nein, überspringen.

			sta	r1H			;Y-Position für Cursor/Zeichen.

			lda	r5L			;X-Position für Cursor/Zeichen.
			sta	r11L
			lda	r5H
			sta	r11H

::exit			rts				;Ende.

;*** MainLoop: Tastatur-Abfrage.
:iCheckInput		jsr	UseSystemFont
			LoadB	currentMode,SET_PLAINTEXT

			ldx	#$ff
			lda	charMaxCount
			sec				;Steht Cursor am Ende des
			sbc	charCurPos		;Textfeldes?
			beq	:1			; => Ja, weiter...
			inx				; => Nein, Cursor innerhalb Text.
::1			stx	flagPosEOL		;Flag "Cursor am Textende" setzen.

			jsr	iTestKey		;Tastendruck auswerten.
			jmp	RegisterSetFont		;Registerfont wieder aktivieren.

;*** Tastendruck auswerten.
:iTestKey		lda	keyData			;Tastencode einlesen.

			cmp	#$1e			;Cursor um 1 Zeichen nach rechts.
			beq	:crsr_right
			cmp	#$08			;Cursor um 1 Zeichen nach links.
			beq	:crsr_left
			cmp	#$11			;Cursor eine Zeile tiefer.
			beq	:crsr_down
			cmp	#$10			;Cursor eine Zeile höher.
			beq	:crsr_up

			cmp	#$1d			;Zeichen links vom Cursor löschen.
			beq	:key_delete
			cmp	#$12			;Cursor in "Home"-Position.
			beq	:home
			cmp	#$13			;Text löschen.
			beq	:home_clear

			ldx	stringY
			cpx	INPUT_SIZE+1		;Schlußzeile erreicht?
			bcs	:1			; => Ja, keine weitere Eingabe.

			cmp	#CR			;Zum Anfang der nächsten Zeile.
			beq	:return
			cmp	#$1c			;Leerzeichen einfügen.
			beq	:insert

			cmp	#$20			;Zeichen gültig?
			bcc	:1			; => Nein, Ende...
			bne	:2
			bit	INPUT_ENABLE_SP		;Leerzeichen erlaubt?
			bpl	:1			; => Nein, Ende...
::2			cmp	#$7f
			bcc	:key_insert		; => Ja, Zeichen einfügen.
::1			rts

::crsr_right		jmp	iCrsrRight
::crsr_left		jmp	iCrsrLeft
::crsr_down		jmp	iCrsrDown
::crsr_up		jmp	iCrsrUp
::key_insert		jmp	iKeyInsert
::key_delete		jmp	iKeyDelete
::return		jmp	iReturn
::insert		jmp	iInsert
::home			jmp	iHome
::home_clear		jmp	iClear

;*** "CURSOR RIGHT"
:iCrsrRight		ldy	charCurPos
			cpy	charMaxCount		;Textende erreicht?
			beq	:1			; => Ja, Ende...
			iny				;Cursor auf nächste Zeichen.
			jsr	SetNewXPos		;Cursor-Position setzen.
::1			rts

;*** "CURSOR LEFT"
:iCrsrLeft		ldy	charCurPos		;Cursor am Textanfang?
			beq	:1			; => Ja, Ende...
			dey				;Cursor auf vorheriges Zeichen.
			jsr	SetNewXPos		;Cursor-Position setzen.
::1			rts

;*** "CURSOR Down"
:iCrsrDown		lda	stringY
			clc
			adc	#10
			cmp	INPUT_SIZE+1		;Ende Textfeld erreicht?
			bcs	:1			; => Ja, Ende...
			jsr	SetNewYPos		;Cursor-Position setzen.
::1			rts

;*** "CURSOR UP"
:iCrsrUp		lda	stringY
			sec
			sbc	#10
			cmp	INPUT_SIZE+0		;Anfang Textfeld erreicht?
			bcc	:1			; => Ja, Ende...
			jsr	SetNewYPos		;Cursor-Position setzen.
::1			rts

;*** "RETURN" auswerten.
:iReturn		bit	INPUT_ENABLE_CR		;RETURN erlaubt?
			bmi	:1			; => Ja, weiter...
			jmp	InputExit		;Texteingabe beenden.

::1			lda	#CR			;Zeilenumbruch einfügen.

;*** Zeichen einfügen.
:iKeyInsert		jsr	AddKey			;Zeichen einfügen.
			jmp	iCrsrRight		;Cursor hinter neues Zeichen setzen.

;*** Leerzeichen einfügen.
:iInsert		bit	INPUT_ENABLE_SP		;Leerzeichen erlaubt?
			bmi	:1			; => Ja, weiter...
			lda	#"_"			;Leerzeichen durch "_" ersetzen.
			b $2c
::1			lda	#" "			;Leerzeichen.
			jmp	AddKey			;Zeichen in Text einfügen.

;*** Letztes Zeichen löschen.
:iKeyDelete		ldy	charCurPos		;Cursor am Textanfang?
			bne	:1			; => Nein, weiter...
			rts

::1			jsr	DeleteChar		;Letztes Zeichen löschen.
			jsr	PrintText		;Gesamten Text ausgeben.

			jsr	FindPosChar		;Zeichenposition suchen.
			jmp	SetCursor		;Cursor hinter Zeichen setzen.

;*** Eingegebenen Text löschen.
:iClear			jsr	SetTextAdr		;Zeiger auf Textspeicher setzen.

			ldy	#$00
			sty	charMaxCount		;Anzahl Zeichen löschen.
			jsr	ClrTextBuf		;Textspeicher löschen.

			jsr	PrintText		;Gesamten Text ausgeben.

;*** Cursor in "Home"-Position.
:iHome			LoadB	charCurPos,NULL		;Cursor an Textanfang setzen.

			jsr	FindPosChar		;Zeichenposition suchen.
			jmp	SetCursor		;Cursor hinter Zeichen setzen.

;*** Cursor auf neue X/Y-Position.
;Übergabe: YReg = Zeichenposition.
:SetNewXPos		sty	charCurPos		;Zeichenposition speichern.
			jsr	FindPosChar		;Zeichenposition suchen.
			jmp	SetCursor		;Cursor hinter Zeichen setzen.

;*** Neue Y-Koordinate setzen.
;Übergabe: YReg = Neue Y-Position für Cursor.
:SetNewYPos		sta	stringY
			jsr	FindPosCursor		;Cursor-Position suchen.
			jmp	SetCursor		;Cursor hinter Zeichen setzen.

;*** Zeichen anfügen.
:AddKey			ldy	charCurPos
			cpy	#INPUT_MAX_LEN
			bne	:1
::exit			rts

::1			jsr	InsertChar		;Zeichen einfügen.
			jsr	FindLastChar		;Letztes Zeichen suchen.

			bit	flagPosEOL		;War Cursor am Textende?
			bpl	:2			; => Nein, weiter...
			txa				;Weiteres Zeichen möglich?
			bne	:exit			; => Nein, Ende...

			sty	charCurPos		;Neue Zeichenposition speichern.
			jsr	FindPosChar		;Zeichenposition suchen.

			lda	r1H
			sec
			sbc	baselineOffset
			cmp	stringY			;Position innerhalb Zeile?
			bne	:2			; => Nein, ganzen Text ausgeben.

			jsr	FindPosCursor		;Cursor-Position suchen.

			ldy	charCurPos
			lda	(r0L),y			;Neues Zeichen einlesen.
			cmp	#CR			;RETURN?
			beq	:2a			; => Ja, weiter...
			jsr	SmallPutChar		;Zeichen ausgeben.

::2a			jsr	FindPosChar		;Zeichenposition suchen.
			jmp	SetCursor		;Cursor hinter Zeichen setzen.

::2			jsr	PrintText		;Gesamten Text ausgeben.

			jsr	FindPosChar		;Zeichenposition suchen.
			jmp	SetCursor		;Cursor hinter Zeichen setzen.

;*** Zeichen in Eingabetext einfügen.
:InsertChar		tax
			ldy	#INPUT_MAX_LEN
			cpy	charCurPos		;Max. Anzahl Zeichen erreicht?
			beq	:exit			; => Nein, weiter...

			jsr	SetTextAdr		;Zeiger auf Textspeicher setzen.

::1			dey				;Byte in Textspeicher und
			lda	(r0L),y			;Tabelle mit Zeichenbreite
			pha				;einfügen um Platz für neues
			lda	tabKeyWidth,y		;Zeichen zu schaffen.
			iny
			sta	tabKeyWidth,y
			pla
			sta	(r0L),y
			dey
			cpy	charCurPos
			bne	:1
			txa
			sta	(r0L),y			;Neues Zeichen speichern.

			ldx	currentMode
			ldy	#$00
			cmp	#$20			;Textzeichen?
			bcc	:2			; => Nein, weiter...
			jsr	GetRealSize		;Zeichenbreite ermitteln.
::2			tya
			ldy	charCurPos
			sta	tabKeyWidth,y		;Zeichenbreite in Tabelle schreiben.

			ldy	#INPUT_MAX_LEN
			lda	#$00
			sta	(r0L),y			;Letztes Zeichen löschen=Textende.
			cpy	charMaxCount		;Textspeicher voll?
			beq	:exit			; => Ja, Ende...
			inc	charMaxCount		;Anzahl Zeichen +1.

::exit			rts

;*** Zeichen aus Text löschen.
:DeleteChar		ldy	charCurPos		;Cursor am Textanfang?
			beq	:exit			; => Nein, weiter...

			dey
			sty	charCurPos		;Neue Zeichenposition speichern.

			jsr	SetTextAdr		;Zeiger auf Textspeicher setzen.

::1			iny				;Byte in Textspeicher und in
			lda	(r0L),y			;Tabelle für Zeichenbreite löschen.
			pha
			lda	tabKeyWidth,y
			dey
			sta	tabKeyWidth,y
			pla
			sta	(r0L),y
			iny
			cpy	charMaxCount
			bne	:1

			dec	charMaxCount		;Anzahl Zeichen -1.

::exit			rts
