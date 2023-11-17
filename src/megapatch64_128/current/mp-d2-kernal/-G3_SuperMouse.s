; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Maustreiber initialisieren.
:xInitMouse		rts
:LastXmov		b $00				;Letzte X-Bewegung.
:LastYmov		b $00				;Letzte Y-Bewegung.

;*** Mauszeiger abbremsen.
:xSlowMouse		rts
:CntDblClk		b $00				;Zähler für Anzahl Doppelklicks.
:DelayDblClk		b $00				;Pause zwischen Doppelklick.

if Flag64_128 = TRUE_C128
:xUpdateMouse		jmp	yUpdateMouse
:xSetMouse		jmp	ActivePortA
endif

;*** Mausdaten aktualisieren.
if Flag64_128 = TRUE_C64
:xUpdateMouse
else
:yUpdateMouse
endif
			bit	mouseOn			;Maus aktiviert ?
			bpl	xSlowMouse		;Nein, Abbruch...

;--- Ergänzung: 09.11.18/M.Kanet
;Vor dem ändern von CPU_DATA den Interrupt sperren.
			php
			sei
			lda	CPU_DATA
			pha
			lda	#$35			;I/O aktivieren.
			sta	CPU_DATA

if Flag64_128 = TRUE_C64
			lda	#$2a			;TurboChameleon64:
			sta	$d0fe			;Konfigurationsregister einschalten.
endif

			ldy	#$01			;Aktuellen SCPU-Speed einlesen.
			bit	$d0b8
			bpl	:1
			dey
::1			sty	curSpeedSCPU +1

if Flag64_128 = TRUE_C64
			ldy	$d0f3			;Aktuellen TC64-Speed einlesen.
			sty	curSpeedTC64 +1
endif

			jsr	ClrPortAB		;Maussregister löschen.

			lda	$dc01			;Maustasten-Register einlesen
			eor	#%11111111		;Bits invertieren.
			and	#%00010011		;Maustasten gedrückt ?
			beq	ChkCurMKey		;Nein, weiter...

;*** Linke Maustaste abfragen.
:TestM1Key		cmp	#%00010000		;Taste #1 gedrückt ?
			bcc	TestM2Key		;Nein, weiter...

:SetMseClick		bit	mouseData		;Maustaste bereits gedrückt ?
			bpl	ExitKeyTest		;Ja, Status nicht ändern.
			bmi	SetKeyOn		;Neuen tastenstatus festlegen.

;*** Keine Maustaste gedrückt.
:ChkCurMKey		bit	KeyM2Aktiv		;Maustaste #2 aktiv ?
			bpl	:51			;Nein, weiter...
			inc	KeyM2Aktiv		;M2-Modus löschen und

			jsr	resetSpeedCPU		;CPU-Speed zurücksetzen.

::51			lda	CntDblClk		;Doppelklick aktiv ?
			beq	:52			;Nein, weiter...
			dec	DelayDblClk		;Verzögerung ausführen. Abgelaufen ?
			bne	:52			;Nein, weiter...
			dec	CntDblClk		;Doppelklick-Flag löschen.
			jmp	SetKeyOn		;Doppelklick ausführen.

::52			bit	mouseData		;War Maustaste gedrückt ?
			bmi	ExitKeyTest		;Nein, weiter...

;--- Hinweis:
;Nur Bit %7 setzen! Der Wert $FF ist
;nicht definiert und führt bei einigen
;Programmen zu Problemen, z.B. bei
;P/S-Editor aus dem GEOS-MegaPack2.
:SetKeyOff		lda	#%10000000		;Flag "Keine Maustaste gedrückt".
			b $2c
:SetKeyOn		lda	#%00000000		;Flag "Maustaste gedrückt".
			sta	mouseData		;Modus für Maustaste setzen.

			lda	pressFlag		;Maustasten-Status geändert.
			ora	#%00100000
			sta	pressFlag
:ExitKeyTest		jmp	StartMseMove		;Mausbewegung abfragen.

;*** Mittlere Maustaste abfragen.
:TestM2Key		cmp	#%00000010		;Mittlere Maustaste gedrückt ?
			bcc	TestM3Key		;Nein, weiter...

			bit	KeyM2Aktiv		;Maustaste #2 bereits aktiv ?
			bmi	:51			;Ja, weiter...
			dec	KeyM2Aktiv		;"Maustaste #2 aktiv"-Flag setzen.

			jsr	slowDownCPU		;CPU auf 1MHz schalten.

::51			jmp	SetMseClick		;Maustaste ausführen.

;*** Rechte Maustaste abfragen.
:TestM3Key		lsr				;Rechte Maustaste gedrückt ?
			bcc	ChkCurMKey		;Nein, Keine Maustaste gedrückt...

			ldx	#$00			;Doppelklick löschen.
			stx	CntDblClk

			ldx	menuNumber		;Hauptmenü aktiv ?
			bne	:51			;Nein, Doppelklick ignorieren...

			lda	#NumClicks		;Zähler für Anzahl Doppelklicks
			sta	CntDblClk		;auf Startwert setzen.
			lda	#ClkDelay		;Verzögerung zwischen Doppelklick
			sta	DelayDblClk		;auf Startwert setzen.
::51			jmp	SetMseClick		;Maustaste ausführen.

;*** Mauszeiger bewegen.
:StartMseMove		jsr	ClrPortAB		;Maussregister löschen und
			jsr	ActivePortA		;Mausrichtungsabfrage initialisieren.

			jsr	slowDownCPU		;CPU auf 1MHz schalten.

			ldx	#$ff			;Warteschleife um "zittern" bei
::51			dex				;SCPU zu verhindern.
			bne	:51

			jsr	resetSpeedCPU		;CPU zurücksetzen.

;--------------------------------------
;Bewegung des Mauszeigers berechnen.
; -> X-Bewegeung.
;--------------------------------------
			ldx	#$00			;xReg ist bereits $00.
			stx	r1L			;Vorgabe: Keine Mausbewegung.
			jsr	GetMseMove		;Bewegungszustand ermitteln.
			sty	LastXmov		;Neue X-Bewegung merken.
			tay
			beq	:53
			bpl	:52

			lda	#$08			;Bewegung nach links.
			b $2c
::52			lda	#$04			;Bewegung nach rechts.
			sta	r1L			;Bewegungsrichtung merken.

			tya				;Beschleunigung ausführen.

::53			clc				;Neue X-Koordinate berechnen.
			adc	mouseXPos +0
			sta	mouseXPos +0
			txa
			adc	mouseXPos +1
			sta	mouseXPos +1

;--------------------------------------
;Bewegung des Mauszeigers berechnen.
; -> Y-Bewegeung.
;--------------------------------------
			ldx	#$01
			jsr	GetMseMove		;Bewegungszustand ermitteln.
			sty	LastYmov		;Neue Y-Bewegung merken.
			tax				;Mauszeiger in Bewegung ?
			beq	:55			;Nein, weiter...
			bpl	:54

			lda	#$01			;Bewegung nach unten.
			b $2c
::54			lda	#$02			;Bewegung nach oben.
			ora	r1L			;Y-Bewegung mit X-Bewegung
			sta	r1L			;verknüpfen.

			txa				;Beschleunigung ausführen.

::55			sec				;Neue Y-Koordinate berechnen.
			eor	#$ff
			adc	mouseYPos
			sta	mouseYPos

;--------------------------------------
;Bewegungsrichtung für GEOS setzen.
;--------------------------------------
			ldx	r1L
			lda	MoveWay,x
			sta	inputData

;*** Mausabfrage beenden.
:xUpdateExit

if Flag64_128 = TRUE_C64
			lda	#$ff			;TurboChameleon64:
			sta	$d0fe			;Konfigurationsregister ausschalten.
endif

			pla				;ROM-Status einlesen und
			sta	CPU_DATA		;zurückschreiben.
;--- Ergänzung: 09.11.18/M.Kanet
;Nach dem zurücksetzen von CPU_DATA den Interrupt wieder freigeben.
			plp
			rts				;Ende...

;*** Mausabfrage initialisieren.
:ClrPortAB		ldx	#$00			;Datenrichtungsregister löschen.
			stx	$dc02			;(Port A löschen)
			stx	$dc03			;(Port B löschen)
			rts

;*** Richtungsabfrage initialisieren.
:ActivePortA		lda	#$ff			;Daterichtungsregister
			sta	$dc02
			lda	#$40			;Datenregister auf
			sta	$dc00			;Port A schalten.
			rts

;*** SCPU/TC64 auf 1MHz schalten.
:slowDownCPU		sta	$d07a			;SCPU auf 1Mhz zurücksetzen.

if Flag64_128 = TRUE_C64
			lda	$d0f3			;TC64 auf 1MHz umschalten.
			and	#%01111111
			sta	$d0f3
endif

			rts

;*** SCPU/TC64 zurücksetzen.
:resetSpeedCPU

:curSpeedSCPU		ldy	#$ff
			sta	$d07a,y			;SCPU-Speed wieder zurücksetzen.

if Flag64_128 = TRUE_C64
:curSpeedTC64		ldy	#$ff			;TurboChameleon64 wieder
			sty	$d0f3			;zurücksetzen.
endif

			rts

;*** Bewegungsdifferenz seit letzter Mausabfrage berechnen (Richtung X/Y).
;    Übergabe:		xReg = $00, X-Richtung abfragen.
;			     = $01, Y-Richtung abfragen.
;    Rückgabe:		AKKU = Aktuelle Bewegung.
;			yReg = Letzte Bewegung der Maus.
:GetMseMove		lda	$d419   ,x		;Aktuelle Bewegung einlesen.
			ldy	LastXmov,x		;Letzte Bewegung einlesen.
			sty	r0L			;Letzte Bewegung merken.
			sta	r0H			;Aktuelle Bewegung merken.

			ldx	#$00			;Flag für "Keine Y-Bewegung".

			sec				;Differenz zwischen letzter und
			sbc	r0L			;aktueller Bewegung berechnen.
			and	#$7f
			cmp	#$40			;Richtung/Gegenrichtung ?
			bcs	MovLeftUp		; -> Gegenrichtung.
			lsr
			bne	TestDblSpeed		; -> Richtung.

:NoMove			txa				;Keine Richtung/Gegenrichtung, Ende...
			rts

;--------------------------------------
;Sonderbehandlung für Bewegung nach
;links (X) bzw. oben (Y).
;--------------------------------------
:MovLeftUp		ora	#$80			;Gegenrichtung markieren.
			cmp	#$ff			;Maus verfügbar ?
			beq	NoMove			;Nein, wenn Register $D419/$D41A = $FF.

			sec				; -> Gegenrichtung.
			ror				;Highbyte für Bewegungsdifferenz = $FF.
			dex				;(Aus Addition der Differenz wird dann
							; eine Subtraktion!)
;*** DoubleSpeed ausführen.
:TestDblSpeed		tay

			lda	#%01111111
			sta	$dc00
			lda	$dc01			;Tasten-Status einlesen.
			and	#%00000100		;Ist CTRL-Taste gedrückt ?
			php				;Ergebnis merken.
			tya

if Flag64_128 = TRUE_C128
			bit	graphMode
			bmi	:80
			plp				;CTRL gedrückt ?
			bne	:52			;Nein, weiter...
			beq	:40			;Ja highspeed
::80			ldy	#LowSpeed80		;80 Zeichen normalspeed
			plp				;CTRL gedrückt ?
			bne	:51			;Nein, weiter...
			ldy	#FastSpeed80		;HighSpeed aktivieren.
			b	$2c
::40			ldy	#FastSpeed		;DoubleSpeed aktivieren.
else
			plp				;CTRL gedrückt ?
			bne	:52			;Nein, weiter...
			ldy	#FastSpeed		;DoubleSpeed aktivieren.
endif

::51			asl
			pha
			txa
			rol
			tax
			pla
			dey
			bne	:51

::52			ldy	r0H			;Aktuelle bewegung einlesen und
			rts				;Routine beenden.

;*** Werte für ":inputData".
;Gibt Bewegungsrichtung des Mauszeigers
;an. Werte von 0-10 möglich.
:MoveWay		b $ff,$06,$02,$ff		;Tabelle für ":inputData".
			b $00,$07,$01,$ff
			b $04,$05,$03
;			b            ,$ff		;Speicherplatz einsparen.
;			b $ff,$ff,$ff,$ff

;*** Variablen für mittlere Maustaste.
:KeyM2Aktiv		b $00				;$FF = M2-Modus bereits aktiv.

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			e END_MOUSE
;******************************************************************************
