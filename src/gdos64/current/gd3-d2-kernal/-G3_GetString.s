; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Neue GetString-Routine.
:KeysInBuffer		= InpStrMaxKey
:xGetString		lda	r0L			;Zeiger auf Eingabespeicher
			sta	string +0		;zwischenspeichern.
			lda	r0H
			sta	string +1

			lda	r1L			;Systemfehler-Flag speichern.
			pha

			lda	r2L			;Eingabelänge speichern.
			sta	InpStrgLen

			lda	r11L			;Start für Texteingabe
			sta	InpStartXPosL		;zwischenspeichern.
			lda	r11H
			sta	InpStartXPosH

			lda	r1H			;Y-Koordinate speichern.
			sta	stringY

			pha
			clc
			adc	baselineOffset
			sta	r1H

			lda	r4H			;Vektor auf Routine für
			pha				;Überschreiten des rechten
			lda	r4L			;Randes zwischenspeichern.
			pha
			jsr	PutString		;Vorgabetext ausgeben.
			pla				;Vektor auf Routine für
			sta	r4L			;Überschreiten des rechten
			pla				;Randes wieder zurückschreiben.
			sta	r4H
			pla
			sta	r1H

			lda	r0L			;Länge der Eingabe berechnen.
			sec
			sbc	string +0
			sta	KeysInBuffer		;Max. Zeichen in Puffer.
			sta	CurCrsrPos		;Cursor-Position festlegen.

			lda	r11L
			sta	stringX +0
			lda	r11H
			sta	stringX +1

			lda	keyVector     +0	;Zeiger auf ":keyVector"
			sta	keyVectorMain +0	;zwischenspeichern.
			lda	keyVector     +1
			sta	keyVectorMain +1

			lda	#< GetNextKey		;Zeiger auf neue Eingabe-
			sta	keyVector     +0	;Routine setzen.
			lda	#> GetNextKey
			sta	keyVector     +1

			ldx	#< StrgFaultRout	;Routine für Fehlerbehandlung.
			ldy	#> StrgFaultRout
			pla				;Standard-Fehlerroutine ?
			bpl	:1			;Ja, weiter...
			ldx	r4L			;Anwender-Fehlerroutine.
			ldy	r4H
::1			stx	StringFaultVec +0
			sty	StringFaultVec +1

			lda	curSetHight
			jsr	InitTextPrompt		;Text-Cursor erzeugen.
			jmp	xPromptOn

;*** Cursor-Modus festlegen.
:SetCursorMode		lda	alphaFlag
			bpl	NOFUNC8
			dec	alphaFlag
			lda	alphaFlag
			and	#$3f
			bne	NOFUNC8
			bit	alphaFlag
			bvc	xPromptOn
			jmp	xPromptOff

;*** Cursor einschalten.
:xPromptOn		lda	#%01000000
			ora	alphaFlag
			sta	alphaFlag
			lda	#$01			;Sprite-Nummer für Cursor.
			sta	r3L
			lda	stringX+1		;X-Koordinate für Cursor.
			sta	r4H
			lda	stringX+0
			sta	r4L
			lda	stringY			;Y-Koordinate für Cursor.
			sta	r5L
			jsr	xPosSprite		;Cursor positionieren.
			jsr	xEnablSprite		;Cursor einschalten.
			jmp	SetPromptMode		;Cursor-Modus festlegen.

;*** Cursor abschalten.
:xPromptOff		lda	#%10111111		;Flag: "Cursor unsichtbar".
			and	alphaFlag
			sta	alphaFlag
			lda	#$01			;Cursor-Sprite wählen.
			sta	r3L
			jsr	xDisablSprite		;Sprite abschalten.

;*** Cursor-Status setzen.
:SetPromptMode		lda	alphaFlag
			and	#%11000000
			ora	#%00011100
			sta	alphaFlag
:NOFUNC8		rts

;*** Cursor-Sprite erzeugen.
:xInitTextPrompt	tay				;Höhe des Cursors merken.

			lda	CPU_DATA		;I/O-Register sichern.
			pha
			lda	#IO_IN			;I/O-Bereich einschalten.
			sta	CPU_DATA

			lda	mob0clr			;Mauszeigerfarbe als Wert für
			sta	mob1clr			;Cursor-Farbe festsetzen.

			lda	moby2			;Keine Vergrößerung des Sprite
			and	#%11111101		;in Y-Richtung.
			sta	moby2

			tya				;Höhe des Cursors
			pha				;zwischenspeichern.
			lda	#%10000011		;Flag: "Cursor aktiv".
			sta	alphaFlag

			ldx	#$40
			lda	#$00
::1			sta	spr1pic -1,x		;Sprite-Speicher löschen.
			dex
			bne	:1

			pla				;Cursor-Höhe einlesen.
			tay
			cpy	#$15			;Mehr als 21 Pixel ?
			bcc	:2			;Nein, weiter...
			beq	:2			;Nein, weiter...

			tya				;Cursor-Höhe durch 2 teilen.
			lsr
			tay
			lda	moby2			;Sprite-Vergrößerung
			ora	#$02			;in Y-Richtung.
			sta	moby2

::2			lda	#%10000000		;Cursor-Grafik erzeugen.
::3			sta	spr1pic,x
			inx
			inx
			inx
			dey
			bpl	:3
			pla				;I/O-Register zurücksetzen.
			sta	CPU_DATA
			rts

;*** Default-Fehlerroutine beim überschreiten des rechten
;    Randes bei der Texteingabe.
:StrgFaultRout		dec	KeysInBuffer
			lda	KeysInBuffer
			cmp	CurCrsrPos
			bcs	:1
			sta	CurCrsrPos
::1			rts

;*** Nächstes Zeichen über Tastatur einlesen.
:GetNextKey		jsr	xPromptOff		;Cursor abschalten.

			jsr	SetCrsrXPos		;Cursor-Position ermitteln.

			lda	stringY			;Y-Koordinate festlegen.
			sta	r1H

			ldy	KeysInBuffer		;Anzahl Zeichen in Puffer.
			lda	keyData			;Zeichen einlesen.
			bpl	K_ENTER			; > $7F ? Nein weiter...
			rts				;Ende.

;*** Sondertasten auswerten.
;*** <EINGABE BEENDEN>
:K_ENTER		cmp	#$0d			;<RETURN> gedrückt ?
			bne	K_LEFT			;Nein, weiter...

			php				;Cursor abschalten.
			sei
			jsr	xPromptOff
			lda	#$7f
			and	alphaFlag
			sta	alphaFlag
			plp

			lda	#$00			;String-Ende markieren.
			sta	(string),y
			sta	keyVector      +0	;Tastaturabfrage löschen.
			sta	keyVector      +1
			sta	StringFaultVec +0
			sta	StringFaultVec +1
			jmp	(keyVectorMain)		;Zurück zum Hauptprogramm.

;*** <CURSOR LINKS>
:K_LEFT			cmp	#$08			;<CRSR LEFT> gedrückt ?
			bne	K_RIGHT			;Nein, weiter...
:K_LEFT_1		ldy	CurCrsrPos		;Am Textanfang ?
			beq	ExitChkKey3		;Ja, ignorieren.
			dey				;Ein Zeichen zurück.
			jmp	ExitChkKey1		;Cursor neu positionieren.

;*** <CURSOR RECHTS>
:K_RIGHT		cmp	#$1e			;<CRSR RIGHT> gedrückt ?
			bne	K_CLR			;Nein, weiter...
			cpy	CurCrsrPos		;Bereits am Ende der Eingabe ?
			beq	ExitChkKey2		;Ja, ignorieren.
			bcc	ExitChkKey2		;Ja, ignorieren.
			inc	CurCrsrPos		;Ein Zwichen weiter.
			bne	ExitChkKey2		;Cursor neu positionieren.

;*** <EINGABE LÖSCHEN>
:K_CLR			cmp	#$13			;<CLR> gedrückt ?
			bne	K_HOME			;Nein, weiter...
			lda	#$00			;Cursorposition und Anzahl
			sta	CurCrsrPos		;Zeichen im Speicher löschen.
			sta	KeysInBuffer
			jsr	Del1TextChar		;Text neu ausgeben.
			lda	#$00
			sta	KeysInBuffer		;Anzahl Zeichen korrigieren.
			beq	K_HOME_1

;*** <ZUM ANFANG DER EINGABE>
:K_HOME			cmp	#$12			;<HOME> gedrückt ?
			bne	K_DEL			;Nein, weiter...
:K_HOME_1		ldy	#$00
			beq	ExitChkKey1		;Cursor neu positionieren.

;*** <LETZTES ZEICHEN LÖSCHEN>
:K_DEL			cmp	#$1d			;<HOME> gedrückt ?
			bne	K_INSERT		;Nein, weiter...
			lda	CurCrsrPos		;Am Anfang der Eingabe ?
			beq	ExitChkKey3		;Ja, ignorieren.
:K_INSERT_1		jsr	Del1TextChar		;Letztes Zeichen löschen.
:K_INSERT_2		jmp	ExitChkKey2		;Cursor neu positionieren.

;*** <ZEICHEN EINFÜGEN>
:K_INSERT		cmp	#$1c			;<HOME> gedrückt ?
			bne	K_TEXT			;Nein, weiter...
			cpy	CurCrsrPos		;Am Ende der Eingabe ?
			beq	ExitChkKey2		;Ja, ignorieren.
			cpy	InpStrgLen		;Eingabespeicher voll?
			beq	ExitChkKey2		;Ja, ignorieren.
			lda	#" "			;SPACE einfügen.
			jsr	K_TEXT_1
			jmp	K_LEFT_1		;Ein Zeichen zurück.

;*** Tastaturabfrage beenden.
:ExitChkKey1		sty	CurCrsrPos		;Neue Cursor-Position setzen.
:ExitChkKey2		jsr	FindCursorPos		;Cursor-Position berechnen.
:ExitChkKey3		jmp	xPromptOn

;*** Textzeichen ausgeben.
:K_TEXT			cmp	#$20			;Gültiges Zeichen ?
			bcc	ExitChkKey3		;Nein, weiter...

:K_TEXT_1		cpy	InpStrgLen		;Speicher voll ?
			beq	ExitChkKey3		;Ja, nicht ausgeben.

			pha				;Zeichen merken.

			cpy	CurCrsrPos		;Cursor am Ende der Eingabe ?
			beq	:2			;Ja, weiter...

			inc	CurCrsrPos
			jsr	DelLastText
			ldy	KeysInBuffer		;des Eingabepuffers löschen.
			dec	CurCrsrPos

::1			dey				;Ein Zeichen einfügen.
			lda	(string),y
			iny
			sta	(string),y
			dey
			cpy	CurCrsrPos
			bne	:1

::2			pla				;Zeichen in Speicher kopieren.
;			ldy	CurCrsrPos
			sta	(string),y
			inc	KeysInBuffer		;Anzahl Zeichen +1.
			jsr	PrnTextAtCRSR		;Text erneut ausgeben.
			inc	CurCrsrPos		;Cursor neu positionieren.
			jmp	ExitChkKey2

;*** Letztes Pixel der Eingabe berechnen und Text ausgeben.
:FindCursorPos		lda	InpStartXPosL		;Startposition der Eingabe.
			sta	stringX       +0
			lda	InpStartXPosH
			sta	stringX       +1

			ldy	#$00
::1			cpy	CurCrsrPos		;Cursor-Position erreicht ?
			bcs	NOFUNC9			;Ja, Ende...

			tya
			pha
			lda	(string),y
			ldx	currentMode		;Breite für aktuelles Zeichen
			jsr	GetRealSize		;berechnen.
			dey
			tya				;Breite für aktuelles Zeichen
			clc				;zu X-Koordinate addieren.
			adc	stringX +0
			ldx	stringX +1
			bcc	:2
			inx

::2			cpx	rightMargin +1		;Rechter Rand überschritten ?
			bne	:3
			cmp	rightMargin +0
::3			bcc	:4
			beq	:4
			pla				;Ja, Cursor neu positionieren.
			sta	CurCrsrPos
			rts

::4			clc				;Nein, neue X-Koordinate
			adc	#$01			;speichern.
			sta	stringX +0
			bcc	:6
			inx
::6			stx	stringX +1

::5			pla				;Zeiger auf nächte Position in
			tay				;Textspeicher setzen.
			iny
			bne	:1
:NOFUNC9		rts				;Cursor ist positioniert.

;*** Eingabetext ausgeben.
:Del1TextChar		cpy	#$00			;Zeichen im Speicher ?
			beq	NOFUNC9			;Nein, Ende...

::1			jsr	DelLastText

			ldy	CurCrsrPos		;Ein Zeichen im Speicher
::2			cpy	KeysInBuffer		;des Eingabepuffers löschen.
			bcs	:3
			lda	(string),y
			dey
			sta	(string),y
			iny
			iny
			bne	:2

::3			dec	KeysInBuffer		;Anzahl Zeichen -1.
			dec	CurCrsrPos		;Cursor-Position korrigieren.
			ldy	CurCrsrPos

;*** Text ab Cursor-Position ausgeben.
:PrnTextAtCRSR		lda	#$80

;*** Text ab Cursor löschen/ausgeben.
:PrnClrCurText		sta	:2 +1

			lda	dispBufferOn		;Bildschirmflag speichern.
			pha

;--- Ergänzung: 06.11.22/M.Kanet
;Hier wurde seit der ersten Version von
;MP3 ein falscher Vergleich ausgeführt.
;Wenn dispBufferOn so eingestellt ist,
;das sowohl nach SCREEN_BASE und auch
;nach BACK_SCR_BASE geschrieben werden
;soll, dann zeigt GetString keinen Text
;auf dem Bildschirm an!
			and	#%00100000		;Dialogbox aktiv ?
			beq	:1			;Nein, weiter...
			lda	#%10100000		;Bei Dialogbox immer nur in
			sta	dispBufferOn		;Vordergrund schreiben.

::1			lda	r1H			;Register ":r1H" speichern.
			pha
			clc
			adc	baselineOffset		;Y-Koordinate für Textausgabe
			sta	r1H			;berechnen.

::2			lda	#$80			;Text ausgeben / löschen ?
			bpl	ClearText		; => Text löschen.

;*** Text ausgeben.
:PrintText		cpy	KeysInBuffer
			bcs	ExitTextOut
			tya
			pha
			lda	(string),y
			jsr	xPutChar
			pla
			tay
			iny
			bne	PrintText

;*** Text löschen.
:ClearText		cpy	CurCrsrPos
			bcc	ExitTextOut
			dey
			tya
			pha
			lda	(string),y
			jsr	RemoveChar
			pla
			tay
			bne	ClearText

;*** Job beenden.
:ExitTextOut		pla
			sta	r1H			;Register ":r1H" zurücksetzen.
			pla
			sta	dispBufferOn		;Bildschirmflag zurücksetzen.
			rts

;*** X-Koordinate für Textausgabe.
:SetCrsrXPos		lda	stringX +0
			sta	r11L
			lda	stringX +1
			sta	r11H
			rts

;*** Eingabe vom Textende bis Cursor-Position löschen.
:DelLastText		lda	CurCrsrPos		;Cursor-Position merken.
			pha
			sty	CurCrsrPos		;Zeiger auf letztes Zeichen.
			jsr	FindCursorPos		;Max. X-Koordinate berechnen.

			ldy	CurCrsrPos
			pla
			sta	CurCrsrPos

			jsr	SetCrsrXPos		;X-Koordinate für Textausgabe.

			lda	#$00
			jmp	PrnClrCurText		;Eingabe-Text löschen.
