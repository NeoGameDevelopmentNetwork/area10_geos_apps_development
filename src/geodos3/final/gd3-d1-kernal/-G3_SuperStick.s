; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Sprungtabelle.
:xInitMouse		jmp	yInitMouse
:xSlowMouse		jmp	ySlowMouse
:xUpdateMouse		jmp	yUpdateMouse

:MouseXspeed		b $00
:MouseYspeed		b $00
:CurrentAccel		b $00
:DirectionX		b $00
:DirectionY		b $00
:LastButtonMode		b $00
:LastMove		b $00
:CurrentMove		b $00

;------------------------------------------------------------------------------
;Mausabfrage initialisieren.
;------------------------------------------------------------------------------
:yInitMouse		jsr	ySlowMouse
			sta	CurrentAccel
			sta	mouseXPos +0
			sta	mouseXPos +1
			sta	mouseYPos
			lda	#$ff
			sta	inputData
			jmp	GetDirectionMode

;------------------------------------------------------------------------------
;Mauszeiger abbremsen.
;------------------------------------------------------------------------------
:ySlowMouse		lda	#$00
			sta	inputData +1
			rts

;------------------------------------------------------------------------------
;Mausposition aktualisieren.
;------------------------------------------------------------------------------
:yUpdateMouse
;--- Ergänzung: 09.11.2018/M.Kanet
;Nur auf Maus-Bewegung testen wenn Maus sichtbar.
;Vgl. SuperMouse-Treiber.
;			jsr	GetStickMove

			bit	mouseOn			;Mauszeiger sichtbar ?
			bpl	NoUpdate		; => Nein, weiter...

			jsr	GetStickMove

			jsr	GetNewMseData

;------------------------------------------------------------------------------
;X-Position aktualisieren.
;------------------------------------------------------------------------------
:SetNewMseXPos		ldy	#$ff
			lda	DirectionX
			bmi	:51
			iny
::51			sty	r11H
			sty	r12L
			asl
			rol	r11H
			asl
			rol	r11H
			asl
			rol	r11H
			clc
			adc	MouseXspeed
			sta	MouseXspeed
			lda	r11H
			adc	mouseXPos +0
			sta	mouseXPos +0
			lda	r12L
			adc	mouseXPos +1
			sta	mouseXPos +1

;------------------------------------------------------------------------------
;Y-Position aktualisieren.
;------------------------------------------------------------------------------
:SetNewMseYPos		ldy	#$00
			lda	DirectionY
			bpl	:51
			dey
::51			sty	r1H
			asl
			rol	r1H
			asl
			rol	r1H
			asl
			rol	r1H
			clc
			adc	MouseYspeed
			sta	MouseYspeed
			lda	r1H
			adc	mouseYPos
			sta	mouseYPos
:NoUpdate		rts

;------------------------------------------------------------------------------
;Joystick-Aktionen auswerten.
;------------------------------------------------------------------------------
:GetStickMove
;--- Ergänzung: 09.11.2018/M.Kanet
;Vor dem Zugriff auf $DC00/cia1base sicherstellen das der
;I/O-Bereich aktiviert ist. Beim Aufruf von UpdateMouse ist das evtl.
;nicht immer der Fall und dann landet der Schreibzugriff auf $DC00 im
;RAM und beschädigt Kernal-Code.
;Dieser `Fehler` ist bereits in GEOS64 2.x enthalten!
			php
			sei
			ldx	CPU_DATA
			ldy	#IO_IN			;I/O aktivieren.
			sty	CPU_DATA
			lda	#$ff
			sta	$dc00
			lda	PortAdrByte		;Joystick in Port 1/2
			stx	CPU_DATA
			plp

			eor	#$ff
			cmp	CurrentMove
			sta	CurrentMove
			bne	NoStickMove

			and	#$0f
			cmp	LastMove
			beq	CheckButton

			sta	LastMove
			tay
			lda	MoveWay,y
			sta	inputData

			lda	#$40
			ora	pressFlag
			sta	pressFlag

			jsr	GetDirectionMode

;------------------------------------------------------------------------------
;Feuerknopf gedrückt ?
;------------------------------------------------------------------------------
:CheckButton		lda	CurrentMove
			and	#$10
			cmp	LastButtonMode
			beq	NoStickMove
			sta	LastButtonMode
			asl
			asl
			asl
			eor	#$80
			sta	mouseData
			lda	#$20
			ora	pressFlag
			sta	pressFlag
:NoStickMove		rts

;------------------------------------------------------------------------------
;Neue Bewegungsrichtung ermitteln.
;------------------------------------------------------------------------------
:GetNewDirection	lda	DirectionData1,x
			sta	r1L
			lda	DirectionData2,x
			sta	r2L
			lda	DirectionModes,x
			pha
			ldx	#r1L
			ldy	#r0L
			jsr	BBMult
			ldx	#r2L
			jsr	BBMult
			pla

			pha				;Bewegung nach links ?
			bpl	:51			; => Nein, weiter...
			ldx	#r1L			;Bewegungsrichtung umdrehen.
			jsr	Dnegate

::51			pla
			and	#$40			;Bewegung nach oben ?
;--- Ergänzung: 09.11.2018/M.Kanet
;Um bei der Registerabfrage CPU_DATA setzen zu können müssen ein
;paar Bytes eingespart werden. Routine angepasst.
;			beq	:52			; => Nein, weiter...
			beq	NoStickMove		; => Nein, weiter...
			ldx	#r2L			;Bewegungsrichtung umdrehen.
			jmp	Dnegate
;::52			rts

;------------------------------------------------------------------------------
;Bewegungsrichtung/Geschwindigkeit ermitteln.
;------------------------------------------------------------------------------
:GetNewMseData		ldx	inputData		;Joystick bewegt ?
			bmi	GetMinMseSpeed		; => Nein, weiter...

			lda	maxMouseSpeed		;Maximale Mauszeigergeschwindigkeit
			cmp	inputData +1		;erreicht ?
			bcc	:51			; => Ja, Maximum setzen.

			lda	mouseAccel		;Zähler für Geschwindigkeit
			clc				;erhöhen. Erreicht dieser Zähler den
			adc	CurrentAccel		;Wert 256, dann wird das Tempo der
			sta	CurrentAccel		;Maus erhöht.
			bcc	GetDirectionMode

			inc	inputData +1		;Mauszeigergeschwindigkeit erhöhen.
			jmp	GetDirectionMode

::51			sta	inputData +1

;--- Mauszeigergeschwindigkeit verringern.
:GetMinMseSpeed		lda	minMouseSpeed		;Minimale Mauszeigergeschwindigkeit
			cmp	inputData +1		;erreicht ?
			bcs	:51			; => Ja, weiter...

			lda	CurrentAccel		;Zähler für Geschwindigkeit
			sec				;verkleinern. Erreicht dieser Zähler
			sbc	mouseAccel		;den Wert 256, dann wird das Tempo
			sta	CurrentAccel		;der Maus verringert.
			bcs	GetDirectionMode

			dec	inputData +1
			jmp	GetDirectionMode

::51			sta	inputData +1

;------------------------------------------------------------------------------
;Bewegungsrichtung ermitteln.
;------------------------------------------------------------------------------
:GetDirectionMode	ldx	inputData		;Joystick bewegt ?
			bmi	SetNoDirection		; => Nein, weiter...

			ldy	inputData +1		;Aktuelles Tempo der Maus
			sty	r0L			;einlesen und neues
			jsr	GetNewDirection		;Bewegungsrichtung ermitteln.

;--- Ergänzung: 09.11.2018/M.Kanet
;Um bei der Registerabfrage CPU_DATA setzen zu können müssen ein
;paar Bytes eingespart werden. Routine angepasst.
			lda	r1H			;Neue Bewegungsrichtung X.
;			sta	DirectionX
			ldx	r2H			;Neue Bewegungsrichtung Y.
;			sta	DirectionY
;			rts
			jmp	SetDirectionXY

;------------------------------------------------------------------------------
;Bewegungsrichtungen löschen.
;------------------------------------------------------------------------------
:SetNoDirection		lda	#$00
			tax
:SetDirectionXY		sta	DirectionX
			stx	DirectionY
			rts

;*** Werte für ":inputData". Gibt Bewegungsrichtung des Mauszeigers an.
:MoveWay		b $ff,$02,$06,$ff
			b $04,$03,$05,$ff
			b $00,$01,$07
;--- Ergänzung: 09.11.2018/M.Kanet
;Um bei der Registerabfrage CPU_DATA setzen zu können müssen ein
;paar Bytes eingespart werden. Diese Bytes werden nicht abgefragt.
;			b             $ff
;			b $ff,$ff,$ff,$ff

;*** Berechnungstabellen für Bewegungsrichtungen.
:DirectionData1		b $ff,$b5
:DirectionData2		b $00,$b5,$ff,$b5
			b $00,$b5,$ff,$b5

;*** Bewegungsrichtungen.
:DirectionModes		b %00000000			;rechts
			b %01000000			;rechts/oben
			b %01000000			;oben
			b %11000000			;links/oben
			b %10000000			;links
			b %10000000			;links/unten
			b %00000000			;unten
			b %00000000			;rechts/unten
