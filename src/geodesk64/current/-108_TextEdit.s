; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Text-Eingaberoutine.
;******************************************************************************
;BoxLeft		= 80				;Grenzen für Infoblock-Fenster.
;BoxRight		= 240
;BoxTop			= 100
;BoxBottom		= 144
;MaxText		= 96
;
;			LoadW	r0,iText		;Textspeicher.
;			LoadB	r2L,BoxTop		;Oben.
;			LoadB	r2H,BoxBottom		;Unten.
;			LoadW	r3,BoxLeft		;Links.
;			LoadW	r4,BoxRight		;Rechts.
;			jsr	InputText
;			rts
;
;Nach der Eingabe folgende Vektoren zurücksetzen:
;
; :keyVector			= $0000
; :alphaFlag			= %0xxxxxxx
;
;Cursor abschalten mit:
;
;			jsr	PromptOff
;
;******************************************************************************

:spr1clr		= $d028
:MaxText		= 96 -1

;*** INPUT-Routine aktivieren.
:InputText		lda	r0L
			pha
			sta	SetTextAdr+1
			lda	r0H
			pha
			sta	SetTextAdr+5

			ldx	r2L			;Obere Grenze Eingabefeld.
			inx
			stx	BoxRange+0

			ldx	r2H			;Untere Grenze Eingabefeld.
			dex
			stx	BoxRange+1

			lda	r3L			;Linke Grenze Eingabefeld.
			clc
			adc	#3
			sta	BoxRange+2

			lda	r4L			;Rechte Grenze Eingabefeld.
			sec
			sbc	#3
			sta	BoxRange+3

;*** Vorgabetext definieren.
			jsr	UseSystemFont
			LoadB	currentMode,SET_PLAINTEXT

			pla
			sta	r0H
			pla
			sta	r0L

			lda	#$00			;Länge des Vorgabetextes im
::1			sta	:2 +1
			tay
			lda	(r0L),y			;Textspeicher ermitteln.
			beq	:3

			ldy	#$00
			cmp	#$20
			bcc	:2
			ldx	currentMode
			jsr	GetRealSize
			dey

::2			ldx	#$ff
			tya
			sta	KeyWidthTab,x

			inx
			txa
			cmp	#MaxText
			bcc	:1
			tay

::3			sty	maxChars

			lda	#$00			;Rest des Textspeichers löschen.
::4			sta	(r0L),y
			sta	KeyWidthTab,y
			iny
			cpy	#MaxText+1
			bcc	:4

;*** Eingabe fortsetzen.
			lda	#8
			jsr	InitTextPrompt

			lda	#<PruefeTaste		;Tastaturabfrage installieren.
			sta	keyVector  +0
			lda	#>PruefeTaste
			sta	keyVector  +1

			lda	alphaFlag		;Cursor einschalten.
			ora	#%10000000
			sta	alphaFlag
			jsr	PromptOn
			cli

			jsr	InitForIO		;Cursor-Farbe "BLAU".
			ClrB	spr1clr
			jsr	DoneWithIO

			jsr	Home

;*** Ganzen Text ausgeben.
:PrintText		jsr	UseSystemFont
			LoadB	currentMode,SET_PLAINTEXT

			ldx	BoxRange+0
			stx	r2L
			ldx	BoxRange+1
			stx	r2H
			ldx	BoxRange+2
			dex
			dex
			stx	r3L
			ldx	BoxRange+3
			inx
			inx
			stx	r4L

			lda	#0
			sta	r3H
			sta	r4H

			jsr	SetPattern
			jsr	Rectangle

;*** Text ausgeben.
			jsr	SetTextAdr

			ldx	#$01
::1			stx	a3L
			stx	a1L

			jsr	GetLineLength
			jsr	SetLowXPos

			ldy	a0L
::2			lda	(r0L),y
			beq	:5
			cmp	#$0d
			beq	:4
			jsr	SmallPutChar
::3			inc	a0L
			ldy	a0L
			cpy	a0H
			bne	:2

::4			ldx	a3L
			inx

			lda	r1H
			clc
			adc	#10
			cmp	BoxRange+1
			bcc	:1

::5			jsr	FindCursor

			jmp	RegisterSetFont

;*** Textadresse setzen.
:SetTextAdr		lda	#$ff
			sta	r0L
			lda	#$ff
			sta	r0H
			rts

;*** Eine Zeile tiefer.
:Add10YPos		AddVB	10,r1H
			rts

;*** Cursor an den linken Rand.
:SetLowXPos		lda	BoxRange+2
			sta	r11L
			LoadB	r11H,NULL
			rts

;*** Cursor an den oberen Rand.
:SetLowYPos		lda	BoxRange+0
			clc
			adc	#8
			sta	r1H
			rts

;*** Länge der aktuellen Zeile berechnen.
:GetLineLength		lda	r0L
			sta	:2 +3
			lda	r0H
			sta	:2 +4

			jsr	SetLowYPos

			ldy	#$00

::1			sty	a0L
			ldx	BoxRange+2
			lda	#$00
			sta	a0H
			sta	a9L			;Länge der aktuellen Zeile = 0.
			sta	a9H			;Länge der aktuellen Zeile = 0.

::2			inc	a9L			;Anzahl Zeichen in Zeile +1.

			lda	$ffff,y			;Zeichen aus Speicher einlesen.
			bne	:2a			;$00-Byte ? Ja, Text-Ende.
			LoadB	a1L,$01			;Zähler für Zeilen auf 0.
			jmp	:3a

::2a			cmp	#$0d			;RETURN ?
			beq	:3a			;Nein, weiter...

			cmp	#$20			;Leerzeichen ?
			bne	:3			;Nein, weiter...

			MoveB	a9L,a9H			;Max. Zeilenlänge bis Leerzeichen
							;begrenzen.

::3			txa				;Zeichenbreite addieren.
			adc	KeyWidthTab,y
			tax
			iny
			cpx	BoxRange+3		;Rechter Rand erreicht ?
			bcc	:2			;Nein, weiter...

			dec	a9L			;Zeilenlänge -1 (Letztes Zeichen ist
							;sonst außerhalb Textfenster!)

			ldx	a9H
			beq	:3a
			cpx	a9L
			bcs	:3a
			stx	a9L 			;Zeile zu lang.
							;Max. Zeilenlänge auf letztes
							;Leerzeichen begrenzen.

::3a			lda	a9L			;Zeilenlänge berechnen.
			clc
			adc	a0L
			sta	a0H

			dec	a1L			;Noch eine Zeile testen ?
			beq	:6			;Nein, Ende...

			jsr	Add10YPos

			ldy	a0H
			jmp	:1

::6			rts

;*** Tastatur-Abfrage.
:PruefeTaste		jsr	UseSystemFont
			LoadB	currentMode,SET_PLAINTEXT
			jsr	TestTaste
			jmp	RegisterSetFont

:TestTaste		lda	keyData
			cmp	#$1e			;Cursor um 1 Zeichen nach rechts.
			beq	iRight
			cmp	#$08			;Cursor um 1 Zeichen nach links.
			beq	iLeft
			cmp	#$11			;Cursor eine Zeile tiefer.
			beq	iDown
			cmp	#$10			;Cursor eine Zeile höher.
			beq	iUp
			cmp	#$1d			;Zeichen links vom Cursor löschen.
			beq	iDeleteKey
			cmp	#$12			;Cursor in "Home"-Position.
			beq	iHome
			cmp	#$13			;Text löschen.
			beq	iClrHome

			ldx	stringY
			cpx	BoxRange+1		;Schlußzeile erreicht ?
			bcs	:1			;Ja, keine weitere Eingabe.

			cmp	#$0d			;Cursor zum Anfang der nächsten Zeile.
			beq	iReturnKey
			cmp	#$1c			;Leerzeichen einfügen.
			beq	iInsSpace

			cmp	#$20
			bcc	:1
			cmp	#$7f
			bcc	iInsertKey
::1			rts

:iRight			jmp	Right
:iLeft			jmp	Left
:iDown			jmp	Down
:iUp			jmp	Up
:iInsertKey		jmp	InsertKey
:iDeleteKey		jmp	DelLastChar
:iReturnKey		jmp	ReturnKey
:iInsSpace		jmp	Insert
:iHome			jmp	Home
:iClrHome		jmp	Clear

;*** Cursor suchen.
:FindCursor		jsr	UseSystemFont
			LoadB	currentMode,SET_PLAINTEXT

			jsr	SetTextAdr

			ldx	#$01
::1			stx	a3L
			stx	a1L
			jsr	GetLineLength
			jsr	SetLowXPos
			jmp	:4

::2			lda	(r0L),y
			beq	:6
			inc	a0L
			cmp	#$0d
			bne	:3
			jsr	SetLowXPos
			jsr	Add10YPos
			jmp	:4

::3			ldx	KeyWidthTab,y
			inx
			txa
			clc
			adc	r11L
			sta	r11L
			bcc	:4
			inc	r11H

::4			ldy	a0L
			cpy	curChar
			beq	:6

			cpy	a0H
			bne	:2

::5			ldx	a3L
			inx
			cpx	#$05
			bne	:1

			jsr	SetLowXPos
			jsr	Add10YPos

::6			jmp	SetCursor

;*** Cursor suchen.
:FindXYpos		jsr	UseSystemFont
			LoadB	currentMode,SET_PLAINTEXT

			jsr	SetTextAdr

			ldx	#$01
::1			stx	a3L
			stx	a1L
			jsr	GetLineLength
			jsr	SetLowXPos
			jmp	:3

::2			lda	(r0L),y
			beq	SetCursor
			inc	a0L
			cmp	#$0d
			beq	:3

			ldx	KeyWidthTab,y
			inx
			txa
			clc
			adc	r11L
			sta	r11L
			bcc	:3
			inc	r11H

::3			ldy	a0L
			cpy	maxChars
			beq	:4

			lda	r1H
			sec
			sbc	baselineOffset
			cmp	stringY
			bne	:5

			lda	r11L
			cmp	stringX
			bcs	:4
			cpy	a0H
			bcc	:2

::4			sty	curChar
			jmp	SetCursor

::5			cpy	a0H
			bne	:2

			ldx	a3L
			inx
			cpx	#$05
			bne	:1

			jsr	SetLowXPos
			jsr	Add10YPos

:SetCursor		MoveW	r11,stringX
			lda	r1H
			sec
			sbc	baselineOffset
			sta	stringY
			jmp	PromptOn

;*** "CURSOR RIGHT"
:Right			ldy	curChar
			cpy	maxChars
			bne	:1
			rts

::1			iny
			jmp	SetNewXPos

;*** "CURSOR LEFT"
:Left			ldy	curChar
			bne	:1
			rts

::1			dey

;*** Cursor auf neue X/Y-Position.
:SetNewXPos		sty	curChar
			jmp	FindCursor

;*** "CURSOR Down"
:Down			lda	stringY
			cmp	BoxRange+1
			bcc	:1
			rts

::1			clc
			adc	#10
			jmp	SetNewYPos

;*** "CURSOR UP"
:Up			lda	stringY
			sec
			sbc	#10
			cmp	BoxRange+0
			bcs	SetNewYPos
			rts

;*** Neue Y-Koordinate setzen.
:SetNewYPos		sta	stringY
			jmp	FindXYpos

;*** "RETURN" auswerten.
:ReturnKey		lda	#$0d

;*** Zeichen einfügen.
:InsertKey		jsr	AddKey
			jmp	Right

;*** Leerzeichen einfügen.
:Insert			lda	#" "

;*** Zeichen anfügen.
:AddKey			ldy	curChar
			cpy	#95
			bne	:1
			rts

::1			jsr	InsertChar
			jmp	PrintText

;*** Letztes Zeichen löschen.
:DelLastChar		ldy	curChar
			bne	:1
			rts

::1			jsr	DeleteChar
			jmp	PrintText

;*** Eingegebenen Text löschen.
:Clear			jsr	SetTextAdr

			lda	#$00
			sta	maxChars
			tay
::1			sta	(r0L),y
			sta	KeyWidthTab,y
			iny
			cpy	#MaxText+1
			bcc	:1

			jsr	PrintText

;*** Cursor in "Home"-Position.
:Home			LoadB	curChar,NULL
			jsr	FindCursor
			jmp	PromptOn

;*** Zeichen in Eingabetext einfügen.
:InsertChar		tax
			ldy	#MaxText
			cpy	curChar
			bne	:1
			rts

::1			jsr	SetTextAdr

::2			dey
			lda	(r0L),y
			pha
			lda	KeyWidthTab,y
			iny
			sta	KeyWidthTab,y
			pla
			sta	(r0L),y
			dey
			cpy	curChar
			bne	:2
			txa
			sta	(r0L),y

			ldx	currentMode
			ldy	#$00
			cmp	#$20
			bcc	:3
			jsr	GetRealSize
			dey
::3			tya
			ldy	curChar
			sta	KeyWidthTab,y

			ldy	#MaxText
			lda	#$00
			sta	(r0L),y
			cpy	maxChars
			beq	:4
			inc	maxChars
::4			rts

;*** Zeichen aus Text löschen.
:DeleteChar		ldy	curChar
			bne	:1
			rts

::1			dey
			sty	curChar

			jsr	SetTextAdr

::2			iny
			lda	(r0L),y
			pha
			lda	KeyWidthTab,y
			dey
			sta	KeyWidthTab,y
			pla
			sta	(r0L),y
			iny
			cpy	maxChars
			bne	:2

			dec	maxChars

			rts

;*** Variablen.
:BoxRange		s $04
:KeyWidthTab		s 96
:maxChars		b $00
:curChar		b $00
