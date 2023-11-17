; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;
; gMicroMys
;
;******************************************************************************
; Test mouse buttons / mouse wheel
;******************************************************************************
;
; USB / PS2 - MicroMys / mousTer
; (c) 2023 M. Kanet
;
; 03.08.2023
; V1.00: Initial release.
;******************************************************************************

;*** Symboltabellen.
if .p
			t "TopSym"
;			t "TopMac"
endif

			n "gMicroMys"
			c "gMicroMys   V1.0",NULL
			a "Markus Kanet",NULL

			o APP_RAM

			z $00
			f APPLICATION

			i
<MISSING_IMAGE_DATA>

			h "Test mouse buttons and mouse wheel... (Controlport #1)"

;*** Hauptanwendung.
:Main			jsr	DrawUI
			jsr	DrawText
			jsr	DrawKeyboard

			lda	#< appMainLoop
			sta	appMain +0
			lda	#> appMainLoop
			sta	appMain +1

			lda	#< irqGetData
			sta	intBotVector +0
			lda	#> irqGetData
			sta	intBotVector +1

			lda	#< appTestMseB
			sta	otherPressVec +0
			lda	#> appTestMseB
			sta	otherPressVec +1

			lda	#< appTestKeyB
			sta	keyVector +0
			lda	#> appTestKeyB
			sta	keyVector +1

			ldy	#0
			sty	r11L
			sty	r11H
			clc
			jsr	StartMouseMode

			rts

;*** Datenanzeige über MainLoop.
:appMainLoop		lda	paddleX +0		;Paddle X.
			cmp	paddleX +1
			beq	:1
			sta	paddleX +1
			ldy	#83
			jsr	PrintByte

::1			lda	paddleY +0		;Paddle Y.
			cmp	paddleY +1
			beq	:2
			sta	paddleY +1
			ldy	#113
			jsr	PrintByte

::2			lda	buttons +0		;MicroMys-Tasten.
;			eor	#%11111111
			cmp	buttons +1
			beq	:msex
			sta	buttons +1

			ldx	#54
			stx	r11L
			ldx	#$00
			stx	r11H
			ldy	#143
			sty	r1H

			jsr	PrintBits

::msex			lda	mouseXPos +1		;Maus X-Koordinate.
			ldx	mouseXPos +0
			cmp	mouseXP   +1
			bne	:msex1
			cpx	mouseXP   +0
::msex1			beq	:msey

			sta	mouseXP +1
			stx	mouseXP +0
			ldy	#83
			jsr	PrintMPos

::msey			ldx	mouseYPos		;Maus Y-Koordinate.
			cpx	mouseYP
			beq	:idat

			stx	mouseYP
			lda	#$00
			ldy	#113
			jsr	PrintMPos

;--- GEOS-Register inputData auswerten.
::idat			lda	inputData +1		;GEOS-Tastenstatus.
			cmp	bufInputData
			beq	:done
			sta	bufInputData

			ldx	#< 253
			stx	r11L
			ldx	#> 253
			stx	r11H
			ldy	#143
			sty	r1H

			jsr	PrintBits

;--- Mausrad-Bewegung anzeigen.

;--- Hinweis:
;Standard-Abfrage für das Mausrad.
;Dabei wird der Wert in ":inputData" +1
;ausgelesen und ausgewertet. Der Wert
;wird durch den MicroMysX0-Treiber
;gesetzt. Die Treiber MicroMysX1/2/3
;simulieren Cursor-Tasten und setzen
;diesen Wert nicht.
::done			lda	inputData +1		;GEOS-Tastenstatus.
			beq	:irq

			asl				;Bit%7.
			asl				;Bit%6.
			asl				;Bit%5.
			asl				;Bit%4.
			bcc	:11
			jmp	MoveUp

::11			asl				;Bit%3.
			bcc	:exit
			jmp	MoveDown

;--- Hinweis:
;Alternative Abfrage über den IRQ.
;Die X1/2/3-Treiber werten das Mausrad
;direkt aus und simulieren Bewegung
;über die Cursor-Tasten.
;Dabei wird dann ":inputData" +1 nicht
;gesetzt um eine doppelte Auswertung
;über die Anwendung zu verhindern.
;Über den IRQ und $DC01 kann man den
;Mausrad-Status dennoch abfragen.
;Für ältere V4-Maustreiber wird damit
;auch ein Mausklick angezeigt.
::irq			lda	buttons +0

			lsr				;Bit%0 = RMB.
			bcs	:21
			jmp	ClickRight

::21			lsr				;Bit%1 = MMB.
			bcs	:22
			jmp	ClickMiddle

::22			lsr				;Bit%2 = Up.
			bcs	:23
			jmp	MoveUp

::23			lsr				;Bit%3 = Down.
			bcs	:24
			jmp	MoveDown

::24			lsr				;Bit%4 = LMB.
			bcs	:exit
			jmp	ClickLeft

;--- Ende MainLoop.
::exit			rts

;*** Bitwerte ausgeben.
:PrintBits		ldy	#8
			sty	r15H

::bits			asl
			pha
			bcs	:b1
::b0			lda	#"o"			;Breite wie "#".
			b $2c
::b1			lda	#"#"			;Breite wie "o".
			jsr	SmallPutChar
			pla
			dec	r15H
			bne	:bits

			rts

;*** Mausposition anzeigen.
:PrintMPos		stx	r0L
			sta	r0H
			lda	#< 264
			sta	r11L
			lda	#> 264
			sta	r11H
			jmp	PrintDec

;*** Paddle/Tastenstatus anzeigen.
:PrintByte		sta	r0L
			lda	#$00
			sta	r0H
			ldx	#54
			stx	r11L
;			lda	#$00
			sta	r11H

:PrintDec		sty	r1H
			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal
			lda	#" "
			jsr	SmallPutChar
			lda	#" "
			jmp	SmallPutChar

;*** Zwischenspeicher.
:paddleX		b $00,$3f			;$d419
:paddleY		b $00,$3f			;$d41a
:buttons		b $00,$3f			;$dc01

:mouseXP		w $ffff				;mouseXPos.
:mouseYP		b $ff				;mouseYPos.

:bufInputData		b $3f				;inputData +1

;*** otherPressVec: Maustastenabfrage.
:appTestMseB		bit	mouseData		;Maustaste gedrückt?
			bmi	:done			; => Nein, Ende...

;--- Hinweis:
;Die Maustreiber V5 von GDOS64 setzen
;in ":inputData" +1 auch die Bits für
;die drei Maustasten. Ist der Wert $00
;dann wurde keine Taste gedrückt.
			lda	inputData +1		;Maustaste gedrückt?
			beq	:done			; => Nein, Ende...

			asl				;Bit%7.
			bcc	:1
			jmp	ClickLeft

::1			asl				;Bit%6.
			bcc	:2
			jmp	ClickRight

::2			asl				;Bit%5.
			bcc	:exit
			jmp	ClickMiddle

;--- Ende otherPressVec: Tastenstatus löschen.
::exit			lda	#%00000000
			sta	inputData +1

::done			rts

;*** Mausklick am Bildschirm anzeigen.
:ClickLeft		ldy	#24
			b $2c
:ClickMiddle		ldy	#30
			b $2c
:ClickRight		ldy	#36
			b $2c
:MoveUp			ldy	#42
			b $2c
:MoveDown		ldy	#48
			tya
			pha
			jsr	setRectData

			lda	#2
			jsr	SetPattern

			jsr	Rectangle

			pla
			cmp	#42
			bcs	:skip

			lda	mouseData
			bpl	:loop

::wait			lda	buttons +0
			eor	#%11111111
			bne	:wait

::loop			bit	mouseData
			bpl	:loop

::skip			lda	pressFlag
			and	#%11011111
			sta	pressFlag

			lda	#%00000000		;Optional!
			sta	inputData +1

			jsr	SCPU_Pause
;			jsr	SCPU_Pause
;			jsr	SCPU_Pause

			lda	#0
			jsr	SetPattern

			jmp	Rectangle

;*** keyVector: Tastaturabfrage.
:appTestKeyB		lda	keyData
			cmp	#" "
			bne	:1
			jmp	EnterDeskTop

::1			cmp	#KEY_UP
			bne	:2
			jmp	DrawKeyUp

::2			cmp	#KEY_DOWN
			bne	:3
			jmp	DrawKeyDown

::3			cmp	#KEY_LEFT
			bne	:4
			jmp	DrawKeyLeft

::4			cmp	#KEY_RIGHT
			bne	:exit
			jmp	DrawKeyRight

::exit			rts

;*** Cursor-Tasten invertieren.
:DrawKeyUp		ldy	#0
			b $2c
:DrawKeyDown		ldy	#6
			b $2c
:DrawKeyLeft		ldy	#12
			b $2c
:DrawKeyRight		ldy	#18

			jsr	setRectData

			jsr	InvertRectangle

			jsr	SCPU_Pause
;			jsr	SCPU_Pause
;			jsr	SCPU_Pause

			jmp	InvertRectangle

;*** intBotVector: Interrupt-Routine zur Datenabfrage.
:irqGetData		php
			sei

			ldx	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA
			lda	$d419
			sta	paddleX +0
			lda	$d41a
			sta	paddleY +0
			lda	$dc01
			sta	buttons +0
			stx	CPU_DATA

			plp
			rts

;*** UI zeichnen.
:DrawUI			jsr	i_GraphicsString

			b NEWPATTERN
			b 0

;--- Maus.
			b MOVEPENTO			;Maus.
			w 160 -40
			b 100 -60
			b RECTANGLETO
			w 161 +40
			b 100 +50
			b FRAME_RECTO
			w 160 -40
			b 100 -60

;--- Buttons.
			b MOVEPENTO			;Left button.
			w 160 -10
			b 100 -50
			b FRAME_RECTO
			w 161 +10
			b 100 -20

			b MOVEPENTO			;Middle button.
			w 160 -15
			b 100 -50
			b FRAME_RECTO
			w 160 -35
			b 100 -20

			b MOVEPENTO			;Right button.
			w 161 +15
			b 100 -50
			b FRAME_RECTO
			w 161 +35
			b 100 -20

			b MOVEPENTO			;Wheel up.
			w 160 -05
			b 100 -15
			b FRAME_RECTO
			w 161 +05
			b 100 -05

			b MOVEPENTO			;Wheel down.
			w 160 -05
			b 100 -02
			b FRAME_RECTO
			w 161 +05
			b 100 +08

;--- Status.
			b MOVEPENTO			;Paddle X.
			w 10
			b 70
			b RECTANGLETO
			w 110
			b 90
			b FRAME_RECTO
			w 10
			b 70

			b MOVEPENTO			;Paddle Y.
			w 10
			b 100
			b RECTANGLETO
			w 110
			b 120
			b FRAME_RECTO
			w 10
			b 100

			b MOVEPENTO			;Buttons.
			w 10
			b 130
			b RECTANGLETO
			w 110
			b 150
			b FRAME_RECTO
			w 10
			b 130

;--- Position.
			b MOVEPENTO			;Maus-X.
			w 210
			b 70
			b RECTANGLETO
			w 309
			b 90
			b FRAME_RECTO
			w 210
			b 70

			b MOVEPENTO			;Maus-Y.
			w 210
			b 100
			b RECTANGLETO
			w 309
			b 120
			b FRAME_RECTO
			w 210
			b 100

;--- Input-Device.
			b MOVEPENTO			;inputDevName.
			w 210
			b 40
			b RECTANGLETO
			w 309
			b 60
			b FRAME_RECTO
			w 210
			b 40

;--- inputData +1.
			b MOVEPENTO			;Maus-Y.
			w 210
			b 130
			b RECTANGLETO
			w 309
			b 150
			b FRAME_RECTO
			w 210
			b 130

			b NULL

			rts

;*** Programmtext ausgeben.
:DrawText		jsr	i_GraphicsString

			b NEWPATTERN
			b 0

			b MOVEPENTO			;Keyboard.
			w 10
			b 8
			b RECTANGLETO
			w 309
			b 31
			b FRAME_RECTO
			w 10
			b 8

			b NULL

			jsr	i_PutString
			w 16
			b 22
			b BOLDON,"gMicroMys",PLAINTEXT

			b GOTOXY
			w 126
			b 22
			b "(Test mouse buttons and mouse wheel)"

			b GOTOXY
			w 128
			b 146
			b "(SPACE) = EXIT"

			b GOTOXY
			w 135
			b 134
			b BOLDON,"MicroMys",PLAINTEXT

			b GOTOXY
			w 16
			b 83
			b BOLDON,"$D419:",PLAINTEXT

			b GOTOXY
			w 16
			b 113
			b BOLDON,"$D41A:",PLAINTEXT

			b GOTOXY
			w 16
			b 143
			b BOLDON,"$DC01:",PLAINTEXT

			b GOTOXY
			w 216
			b 83
			b BOLDON,"MouseX:",PLAINTEXT

			b GOTOXY
			w 216
			b 113
			b BOLDON,"MouseY:",PLAINTEXT

			b GOTOXY
			w 216
			b 143
			b BOLDON,"ID +1:",PLAINTEXT

			b GOTOXY
			w 216
			b 53

			b NULL

;--- Maustreiber anzeigen.
			lda	#< 306
			sta	rightMargin +0
			lda	#> 306
			sta	rightMargin +1

			lda	#< inputDevName
			sta	r0L
			lda	#> inputDevName
			sta	r0H

			jsr	PutString

			lda	#< 319
			sta	rightMargin +0
			lda	#> 319
			sta	rightMargin +1

			rts

;*** Cursor-Tasten anzeigen.
:DrawKeyboard		jsr	i_GraphicsString

			b NEWPATTERN
			b 0

			b MOVEPENTO			;Keyboard.
			w 10
			b 160
			b RECTANGLETO
			w 309
			b 191
			b FRAME_RECTO
			w 10
			b 160

			b NULL

			jsr	i_BitmapUp
			w icon_crsr
			b 16,168,icon_crsr_x,icon_crsr_y

			jsr	i_PutString
			w 16
			b 178
			b BOLDON,"Keyboard emulation:",PLAINTEXT

			b GOTOXY
			w 196
			b 178
			b "Cursor keys/input device"

			b NULL

			rts

:icon_crsr
<MISSING_IMAGE_DATA>

:icon_crsr_x		= .x
:icon_crsr_y		= .y

;*** Pause von 1/10sec ausführen.
:SCPU_Pause		php
			sei

			lda	CPU_DATA
			pha
			lda	#IO_IN
			sta	CPU_DATA
			lda	$dc08			;1/10s - Register.
::wait			cmp	$dc08
			beq	:wait
			pla
			sta	CPU_DATA

			plp
			rts

;*** Grafikkordinaten setzen.
:setRectData		ldx	#0
::1			lda	tabRectData,y
			sta	r2,x
			iny
			inx
			cpx	#6
			bcc	:1
			rts

;*** Tabelle mit Grafikkoordinaten.
:tabRectData

;--- Cursor-Tasten.
			b 168,168 +icon_crsr_y -1
			w 16*8,18*8 -1

			b 168,168 +icon_crsr_y -1
			w 18*8,20*8 -1

			b 168,168 +icon_crsr_y -1
			w 20*8,22*8 -1

			b 168,168 +icon_crsr_y -1
			w 22*8,24*8 -1

;--- Maustasten-Anzeige.
			b 100 -49,100 -21		;Left button.
			w 160 -34,160 -16

			b 100 -49,100 -21		;Middle button.
			w 160 -09,161 +09

			b 100 -49,100 -21		;Right button.
			w 161 +16,161 +34

			b 100 -14,100 -06		;Wheel up.
			w 160 -04,161 +04

			b 100 -01,100 +07		;Wheel down.
			w 160 -04,161 +04
