; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;
; SmartMouse
;
;******************************************************************************
;Linke Maustaste    : Mausklick
;Mittlere Maustaste : Mausklick
;Rechte Maustaste   : Mausklick
;******************************************************************************
;
; Maustreiber für CMD SmartMouse, USB- oder PS/2-Maus, SuperCPU & TC64.
; (c) 2023 M. Kanet
;
; 04.08.2023
; V5.1: Minor fixes.
;
; 18.07.2023
; V5.0: Initial release.
;******************************************************************************

;*** Symboltabellen.
if .p
			t "SymbTab_1"
;			t "SymbTab_GDOS"
			t "SymbTab_CXIO"
			t "SymbTab_SCPU"
			t "SymbTab_TC64"
			t "SymbTab_GTYP"
			t "MacTab"
endif

;*** GEOS-Header.
			n "SmartMouse",NULL
			c "InputDevice V5.1"
			t "opt.Author"
			f INPUT_DEVICE
			z $80 ;nur GEOS64

			o MOUSE_BASE

			i
<MISSING_IMAGE_DATA>

			h "Mouse driver, controlport 1"
			h "SmartMouse,USB,PS/2,SCPU,TC64"
			h "L/M/R:Click, no mouse wheel"

;*** Maustreiber initialisieren.
:xInitMouse		rts

:LastMove
:LastXmov		b $00				;Letzte X-Bewegung.
:LastYmov		b $00				;Letzte Y-Bewegung.

;*** Mauszeiger abbremsen.
:xSlowMouse		rts

			b $00
			b $00

;*** Mausdaten aktualisieren.
:xUpdateMouse		bit	mouseOn			;Maus aktiviert?
			bpl	xSlowMouse		; => Nein, Abbruch...

			php				;Interrupt sperren.
			sei

			lda	CPU_DATA		;I/O aktivieren.
			pha
			lda	#IO_IN
			sta	CPU_DATA

			lda	#$2a			;TurboChameleon64:
			sta	TC64_HW_EN_DIS		;Konfigurationsregister einschalten.

			jsr	ClrPortAB		;Maussregister löschen.

;			ldx	#%00000000		;inputData +1: Keine Maustaste.

			lda	cia1base +1		;Maustasten-Register einlesen
			eor	#%11111111		;Bits invertieren.
;--- Maustasten:
;Bit%4: Linke Taste.
;Bit%1: Mittlere Taste.
;Bit%0: Rechte Taste.
			and	#%00010011		;Maustasten gedrückt?
			beq	NoMKeyActive		; => Nein, weiter...

;--- Linke Maustaste abfragen.
:TestM1Key		cmp	#%00010000		;Taste #1 gedrückt?
			bcc	TestM2Key		; => Nein, weiter...

			ldx	#%10000000		;inputData +1: Linke Maustaste.
			bne	ExecMseClick

;--- Rechte Maustaste abfragen.
:TestM2Key		lsr				;Rechte Maustaste gedrückt?
			bcc	TestM3Key		; => Nein, weiter...

			ldx	#%01000000		;inputData +1: Rechte Maustaste.
			bne	ExecMseClick

;--- Mittlere Maustaste abfragen.
:TestM3Key		lsr				;Mittlere Maustaste gedrückt?
			bcc	NoMKeyActive		; => Nein, weiter...

			ldx	#%00100000		;inputData +1: Mittlere Maustaste.
;			bne	ExecMseClick

;*** Maustaste ausführen.
:ExecMseClick		bit	mouseData		;Maustaste bereits gedrückt?
			bpl	StartMseMove		; => Ja, Status nicht ändern.
			bmi	SetKeyOn		;Neuen Tastenstatus festlegen.

;*** Keine Maustaste gedrückt.
:NoMKeyActive		bit	mouseData		;War Maustaste gedrückt?
			bmi	StartMseMove		; => Nein, weiter...

;--- Hinweis:
;Nur Bit %7 setzen! Der Wert $FF ist
;nicht definiert und führt bei einigen
;Programmen zu Problemen, z.B. bei
;P/S-Editor aus dem GEOS-MegaPack2.
:SetKeyOff		lda	#%10000000		;Flag "Keine Maustaste gedrückt".
			b $2c
:SetKeyOn		lda	#%00000000		;Flag "Maustaste gedrückt".
			sta	mouseData		;Modus für Maustaste setzen.

			lda	pressFlag		;GEOS-Maustasten-Status geändert.
			ora	#%00100000		;(Tasten oder Mausrad)
			sta	pressFlag

:SetKeyData		stx	inputData +1		;Maustasten-Bits setzen.

;			jmp	StartMseMove		;Mauszeiger bewegen.

;*** Mauszeiger bewegen.
:StartMseMove		jsr	ClrPortAB		;Maussregister löschen und
			jsr	ActivePortA		;Richtungsabfrage initialisieren.

			jsr	GetCurSpeed

			jsr	slowDownCPU		;CPU auf 1MHz schalten.

			lda	#255			;Warteschleife um "zittern" bei
::wait			sec	 			;SCPU/TC64 zu verhindern.
			sbc	#1
			bne	:wait

			jsr	setSpeedCPU

;--------------------------------------
;Bewegung des Mauszeigers berechnen:
; -> X-Bewegeung.
;--------------------------------------
			ldx	#$00
			stx	r1L			;Vorgabe: Keine Mausbewegung.
			jsr	GetDirection		;Bewegungszustand ermitteln.
			sty	LastXmov		;Neue X-Bewegung merken.
			tay
			beq	:move_x
			bpl	:right

::left			lda	#$08			;Bewegung nach links.
			b $2c
::right			lda	#$04			;Bewegung nach rechts.
			sta	r1L			;Bewegungsrichtung merken.

			tya				;Beschleunigung ausführen.

::move_x		clc				;Neue X-Koordinate berechnen.
			adc	mouseXPos +0
			sta	mouseXPos +0
			txa
			adc	mouseXPos +1
			sta	mouseXPos +1

;--------------------------------------
;Bewegung des Mauszeigers berechnen:
; -> Y-Bewegeung.
;--------------------------------------
			ldx	#$01
			jsr	GetDirection		;Bewegungszustand ermitteln.
			sty	LastYmov		;Neue Y-Bewegung merken.
			tax				;Mauszeiger in Bewegung?
			beq	:move_y			;Nein, weiter...
			bpl	:up

::down			lda	#$01			;Bewegung nach unten.
			b $2c
::up			lda	#$02			;Bewegung nach oben.
			ora	r1L			;Y-Bewegung mit X-Bewegung
			sta	r1L			;verknüpfen.

			txa				;Beschleunigung ausführen.

::move_y		sec				;Neue Y-Koordinate berechnen.
			eor	#$ff
			adc	mouseYPos
			sta	mouseYPos

;--------------------------------------
;GEOS-Bewegungsrichtung setzen.
;--------------------------------------
			ldx	r1L
			lda	tabMoveGEOS,x		;Bewegungsrichtung für
			sta	inputData		;GEOS setzen.

;--- Mausabfrage beenden.
::exit			lda	#$ff			;TurboChameleon64:
			sta	TC64_HW_EN_DIS		;Konfigurationsregister ausschalten.

			pla
			sta	CPU_DATA		;I/O-Bereich zurücksetzen.

			plp				;Interrupt-Status zurücksetzen.
			rts				;Ende...

;*** Bewegungsdifferenz seit letzter Mausabfrage berechnen (Richtung X/Y).
;Übergabe: xReg = $00, X-Richtung abfragen (paddleX = $d419).
;               = $01, Y-Richtung abfragen (paddleY = $d41a).
;Rückgabe: AKKU = Aktuelle Bewegung.
;                 Bit%7=0: right/up.
;                 Bit%7=1: left/down.
;          yReg = Letzte Bewegung der Maus.
:GetDirection		lda	paddleX ,x		;Aktuelle Bewegung einlesen.
			sta	r0H			;Aktuelle Bewegung speichern.

			ldy	LastMove,x		;Letzte Bewegung einlesen.
			sty	r0L			;Letzte Bewegung speichern.

			ldx	#$00			;Flag für "Keine Y-Bewegung".

			sec				;Differenz zwischen letzter und
			sbc	r0L			;aktueller Bewegung berechnen.
			and	#%01111111
			cmp	#%01000000		;Richtung/Gegenrichtung?
			bcs	MovLeftUp		; => Gegenrichtung.
			lsr
			bne	MovRightDown		; => Richtung.

:NoMove			txa				;Kein Richtungswechsel, Ende...
			rts

;--------------------------------------
;Sonderbehandlung für Bewegung nach
;links (X) bzw. oben (Y).
;--------------------------------------
:MovLeftUp		ora	#%10000000		;Gegenrichtung markieren.
			cmp	#%11111111		;Maus verfügbar?
			beq	NoMove			; => Nein, wenn Reg. $D419/$D41A = $FF.

			sec				; => Gegenrichtung.
			ror				;High für Bewegungsdifferenz = $FF.
			dex				;(Aus Addition der Differenz wird
							; dann eine Subtraktion!)
;--------------------------------------
;Sonderbehandlung für Bewegung nach
;rechts (X) bzw. unten (Y).
;--------------------------------------
:MovRightDown		ldy	r0H			;Aktuelle bewegung einlesen und
			rts				;Routine beenden.

;*** Mausabfrage initialisieren.
:ClrPortAB		ldx	#$00			;Datenrichtungsregister löschen.
			stx	cia1base +2		;(Port A löschen)
			stx	cia1base +3		;(Port B löschen)
			rts

;*** Richtungsabfrage initialisieren.
:ActivePortA		lda	#$ff			;Daterichtungsregister auf
			sta	cia1base +2		;Ausgang setzen (lesen/schreiben).
			lda	#%01 000000		;Paddle in Port #1 aktivieren.
			sta	cia1base +0		;(%10xxxxxx für Port #2)
			rts

;*** Aktuellen CPU-Takt einlesen.
:GetCurSpeed		ldy	#$01			;Aktuellen SCPU-Speed einlesen.
			bit	SCPU_HW_SPEED
			bpl	:1
			dey

::1			ldx	TC64_HW_SPEED		;Aktuellen TC64-Speed einlesen.
			rts

;*** SCPU/TC64 auf 1MHz schalten.
:slowDownCPU		sta	SCPU_HW_NORMAL		;SCPU auf 1Mhz umschalten.

			lda	TC64_HW_SPEED		;TC64 auf 1MHz umschalten.
			and	#%01111111
			sta	TC64_HW_SPEED

			rts

;*** SCPU/TC64 zurücksetzen.
:resetSpeedCPU

:curSpeedSCPU		ldy	#$ff			;SCPU-Speed wieder zurücksetzen.
:curSpeedTC64		ldx	#$ff			;TC64-Speed wieder zurücksetzen.

:setSpeedCPU		sta	SCPU_HW_NORMAL,y
			stx	TC64_HW_SPEED
			rts

;*** Werte für ":inputData".
;Gibt Bewegungsrichtung des Mauszeigers
;an. Nur Index von 0-10 möglich.
:tabMoveGEOS		b $ff				;%0000: Keine Bewegung.
			b $06				;%0001: Nach unten.
			b $02				;%0010: Nach oben.
			b $ff				;%0011: Keine Bewegung.
			b $00				;%0100: Nach rechts.
			b $07				;%0101: Nach rechts/unten.
			b $01				;%0110: Nach rechts/oben.
			b $ff				;%0111: Keine Bewegung.
			b $04				;%1000: Nach links.
			b $05				;%1001: Nach links/unten.
			b $03				;%1010: Nach links/oben.

;--- Speicherplatz einsparen.
;			b $ff				;%1011: -
;			b $ff				;%1100: -
;			b $ff				;%1101: -
;			b $ff				;%1110: -
;			b $ff				;%1111: -

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g MOUSE_BASE + MOUSE_SIZE
;******************************************************************************
