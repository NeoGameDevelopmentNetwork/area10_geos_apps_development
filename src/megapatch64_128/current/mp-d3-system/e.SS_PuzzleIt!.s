; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "PuzzleIt!"
			t "G3_SymMacExt"

			a "M. Kanet"
			f SYSTEM
			o LD_ADDR_SCRSAVER

			i
<MISSING_IMAGE_DATA>
if Flag64_128 = TRUE_C64
			c "ScrSaver64  V1.0"
			z $80				;nur GEOS64 bei MP3-64
endif

if Flag64_128 = TRUE_C128
			c "ScrSaver128 V1.0"
			z $40				;40 und 80 Zeichen-Modus bei MP3-128
endif

;*** ScreenSaver aufrufen.
:MainInit		jmp	InitScreenSaver

;*** ScreenSaver installieren.
;    Laufwerk von dem ScreenSaver geladen wurde muß noch aktiv sein!
;    Rückgabe eines Fehlers im xReg ($00=Kein Fehler).
;    ACHTUNG! Nur JMP-Befehl oder "LDX #$00:RTS", da direkt im Anschluß
;    der Name des ScreenSavers erwartet wird! (Addr: G3_ScrSave +6)
:InstallSaver		ldx	#$00
			rts

;*** Name des ScreenSavers.
;    Direkt nach dem JMP-Befehl, da über den GEOS.Editor der Name
;    an dieser Stelle ausgelesen wird.
;    Der Name muss mit dem Dateinamen übereinstimmen, da der
;    Bildschirmschoner über diesen Namen beim Systemstart geladen wird.
:SaverName		b "PuzzleIt!",NULL

;*** ScreenSaver aufrufen.
:InitScreenSaver	php				;IRQ sperren.
			sei				;Screener läuft in der MainLoop!

			ldx	#$1f			;Register ":r0" bis ":r3"
::51			lda	r0L,x			;speichern.
			pha
			dex
			bpl	:51

			jsr	DoSaverJob		;Bildschirmschoner aktivieren.

			lda	#%01000000		;Bildschirmschoner neu starten.
			sta	Flag_ScrSaver

			ldx	#$00			;Register ":r0" bis ":r3"
::52			pla				;zurückschreiben.
			sta	r0L,x
			inx
			cpx	#$20
			bne	:52

			sei				;IRQ abschalten.
if Flag64_128 = TRUE_C64
			ldx	CPU_DATA		;CPU-Register speichern und
			lda	#$35			;I/O-Bereich einblenden.
			sta	CPU_DATA
endif
::53			lda	#$00
			sta	$dc00			;Tastenregister aktivieren.
if Flag64_128 = TRUE_C128
			sta	$d02f			;C128 Zusatztasten
endif
			lda	$dc01			;Tastenstatus einlesen.
			eor	#$ff			;Taste noch gedrückt ?
			bne	:53			;Ja, Warteschleife...

if Flag64_128 = TRUE_C64
			stx	CPU_DATA		;CPU-Register zurücksetzen.
endif
			plp				;IRQ zurücksetzen und
			rts				;Ende...

;*** Bildschirmschoner-Grafik.
:DoSaverJob		PushB	dispBufferOn		;Variablen speichern.
			PushB	curPattern
			LoadB	dispBufferOn,ST_WR_FORE

			jsr	SaveScreen		;Bildschirm zwischenspeichern.
			jsr	InitPuzzle

			lda	#$00			;Unterste Zeile löschen.
			jsr	SetPattern		;Für das Puzzle wird nur ein Feld
			jsr	i_Rectangle		;von 320x192 = 5*64 x 4*48
			b	$c0,$c7			;benötigt. Der Rest ist ungenutzt.
			w	$0000 ! DOUBLE_W,$013f ! DOUBLE_W ! ADD1_W
			lda	#$00
			jsr	DirectColor

			LoadB	r3L,$00			;Gitterraster zeichnen.
			LoadB	r3H,$bf
			LoadW	r4 ,$0000
::51			lda	#%01010101
			jsr	VerticalLine
			AddVBW	63,r4
			lda	#%11111111
			jsr	VerticalLine
			AddVBW	 1,r4
if Flag64_128 = TRUE_C128
			bit	graphMode
			bpl	:40
			CmpWI	r4,640
			bcc	:51
			bcs	:80
::40
endif
			CmpWI	r4,320
			bcc	:51

::80			LoadW	r3  ,$0000 ! DOUBLE_W
			LoadW	r4  ,$013f ! DOUBLE_W ! ADD1_W
			LoadB	r11L,$00
::52			lda	#%01010101
			jsr	HorizontalLine
			AddVB	47,r11L
			lda	#%11111111
			jsr	HorizontalLine
			AddVB	 1,r11L
			CmpBI	r11L,192
			bcc	:52

			LoadB	LastWay,$ff      ;Alle Richtungen freigeben.
			LoadW	EmptyX,$0080   		;Startwerte für leeres Feld.
			LoadB	EmptyY,$60
			jsr	SetEmpty		;Koordinaten für leeres Feld
			lda	#$01			;bestimmen und Inhalt löschen.
			jsr	SetPattern
			jsr	Rectangle
			lda	#$00
			jsr	DirectColor

;*** Puzzle ausführen.
:DoPuzzle		jsr	WaitLoop1		;Verzögerung zwischen Bildaufbau-
			tax				;Taste gedrückt ?
			bne	EndPuzzle		;Ja, Ende...

			jsr	MovePuzzle		;Puzzle verschieben.

			lda	CurrentWay		;Aktuelle Bewegungsrichtung
			sta	LastWay			;speichern. Damit wird verhindert,
							;das sofort die Gegenrichtung ge-
							;wählt wird. Sonst kommt es zum
							;links-rechts-links-rechts-Effekt!

			php				;IRQ-Status speichern und
			sei				;IRQ abschalten.
if Flag64_128 = TRUE_C64
			ldx	CPU_DATA		;CPU-Register speichern und
			lda	#$35			;I/O-Bereich einblenden.
			sta	CPU_DATA
endif
			lda	#$00
			sta	$dc00			;Tastenregister aktivieren.
if Flag64_128 = TRUE_C128
			sta	$d02f			;C128 Zusatztasten
endif
			lda	$dc01			;Tastenstatus einlesen.
if Flag64_128 = TRUE_C64
			stx	CPU_DATA		;CPU-Register zurücksetzen.
endif
			plp				;IRQ-Status zurücksetzen.

			eor	#$ff			;Wurde Taste gedrückt ?
			beq	DoPuzzle		;Nein, Schleife bis Taste gedrückt.

;*** Zurück zum Programm.
:EndPuzzle		php				;IRQ-Status speichern und
			sei				;IRQ abschalten.
if Flag64_128 = TRUE_C64
			ldx	CPU_DATA		;CPU-Register speichern und
			lda	#$35			;I/O-Bereich einblenden.
			sta	CPU_DATA
endif
			lda	FrameColor
			sta	$d020
			lda	MouseMode
			sta	$d015
if Flag64_128 = TRUE_C64
			stx	CPU_DATA		;CPU-Register zurücksetzen.
endif
			plp				;IRQ-Status zurücksetzen.

			jsr	LoadScreen		;Bildschirm zurücksetzen.

			pla				;Variablen zurücksetzen.
			jsr	SetPattern
			PopB	dispBufferOn
			rts

;*** Register zwischenspeichern.
:InitPuzzle		php				;IRQ-Status speichern und
			sei				;IRQ abschalten.
if Flag64_128 = TRUE_C64
			ldx	CPU_DATA		;CPU-Register speichern und
			lda	#$35			;I/O-Bereich einblenden.
			sta	CPU_DATA
endif
			lda	$d020			;Rahmenfarbe zwischenspeichern.
			sta	FrameColor
			lda	#$00			;Rahmenfarbe auf "schwarz" setzen.
			sta	$d020

			lda	$d015			;Spritemodi zwischenspeichern.
			sta	MouseMode
			lda	#$00			;Alle Sprites abschalten.
			sta	$d015
if Flag64_128 = TRUE_C64
			stx	CPU_DATA		;CPU-Register zurücksetzen.
endif
			plp				;IRQ-Status zurücksetzen.
			rts

;*** Warteschleife vor Puzzle-Aufbau.
:WaitLoop1		php				;IRQ-Status speichern und
			sei				;IRQ abschalten.
if Flag64_128 = TRUE_C64
			ldx	CPU_DATA		;CPU-Register speichern und
			lda	#$35			;I/O-Bereich einblenden.
			sta	CPU_DATA
endif
			ldy	#$04
::51			lda	$dc08			;1/10sec-Register einlesen und
::52			cmp	$dc08			;auf Veränderung warten.
			beq	:52
			lda	#$00
			sta	$dc00			;Tastenregister aktivieren.
if Flag64_128 = TRUE_C128
			sta	$d02f			;C128 Zusatztasten
endif
			lda	$dc01			;Tastenstatus einlesen.
			eor	#$ff			;Wurde Taste gedrückt ?
			bne	:53			;Nein, Schleife bis Taste gedrückt.
			dey
			bne	:51
::53
if Flag64_128 = TRUE_C64
			stx	CPU_DATA		;CPU-Register zurücksetzen.
endif
			plp
			rts

;*** Warteschleife zwischen den Verschiebungsphasen.
:WaitLoop2		txa
			pha
			php				;IRQ-Status speichern und
			sei				;IRQ abschalten.
if Flag64_128 = TRUE_C64
			ldx	CPU_DATA		;CPU-Register speichern und
			lda	#$35			;I/O-bereich einblenden.
			sta	CPU_DATA
endif
			ldy	$d012
::51			lda	$d012
			bne	:51

			ldy	#32
::52			lda	$d012
::53			cmp	$d012
			beq	:53
			dey
			bne	:52
if Flag64_128 = TRUE_C64
			stx	CPU_DATA		;CPU-Register zurücksetzen.
endif
			plp
			pla
			tax				;IRQ-Status zurücksetzen.
			rts

;*** Puzzle verschieben.
:MovePuzzle		jsr	SetEmpty		;Koordinaten für leeres Feld.

:NewMoveData		php				;IRQ-Status speichern und
			sei				;IRQ abschalten.
if Flag64_128 = TRUE_C64
			ldx	CPU_DATA		;CPU-Register speichern und
			lda	#$35			;I/O-bereich einblenden.
			sta	CPU_DATA
endif
			lda	$d012			;Zufallszahl einlesen.
if Flag64_128 = TRUE_C64
			stx	CPU_DATA		;CPU-Register zurücksetzen.
endif
			plp				;IRQ-Register zurücksetzen.
			lsr				;Bewegungsrichtung bestimmen.
			and	#%00000011
			sta	CurrentWay		;Aktuelle Richtung speichern.
			cmp	#$00
			beq	:101			; => Puzzle nach unten.
			cmp	#$01
			beq	:102			; => Puzzle nach oben.
			cmp	#$02
			beq	:103			; => Puzzle nach rechts.
			cmp	#$03
			beq	:104			; => Puzzle nach links.
			jmp	NewMoveData
::101			jmp	MoveDown
::102			jmp	MoveUp
::103			jmp	MoveRight
::104			jmp	MoveLeft

;*** Koordinaten für leeres Feld setzen.
:SetEmpty		lda	EmptyX +0
			sta	r3L
			clc
			adc	#63
			sta	r4L
			lda	EmptyX +1
			sta	r3H
			adc	#0
			sta	r4H
			lda	EmptyY
			sta	r2L
			clc
			adc	#47
			sta	r2H
			rts

;*** Puzzle-Teil nach unten verschieben.
:MoveDown		lda	r2L			;Ist leeres Feld am oberen Rand ?
			bne	:102			;Nein, weiter...
::101			jmp	NewMoveData		;Nicht möglich, andere Richtung.

::102			lda	LastWay			;Letzte Richtung einlesen.
			cmp	#$01			;Nach oben verschoben ?
			beq	:101			;Ja, Gegenrichtung nicht erlaubt.

if Flag64_128 = TRUE_C128
			bit	graphMode
			bpl	:40
			jmp	MoveDown80
::40
endif
			lda	#$06			;Puzzle-Teil verschieben.
::103			pha
			jsr	WaitLoop2
			jsr	DefGrfxMemAdr

			ldx	#$06
::104			PushW	r0
			PushW	r1

			lda	r0L
			sta	r10L
			sec
			sbc	#< 320
			sta	r0L
			lda	r0H
			sta	r10H
			sbc	#> 320
			sta	r0H

			lda	r1L
			sta	r11L
			sec
			sbc	#< 40
			sta	r1L
			lda	r1H
			sta	r11H
			sbc	#> 40
			sta	r1H

			jsr	CopyLineData

			dex
			beq	:105

			PopW	r1
			PopW	r0

			SubVW	320,r0
			SubVW	 40,r1
			jmp	:104

::105			jsr	ClearLineData
			AddVB	8,r2L

			PopW	r1
			PopW	r0

			pla
			sec
			sbc	#$01
			beq	:106
			jmp	:103

::106			SubVB	48,EmptyY		;Koordinate für leeres Feld.
			rts

if Flag64_128 = TRUE_C128
:MoveDown80		lda	#$06			;Puzzle-Teil verschieben.
::103			pha
			jsr	WaitLoop2
			jsr	DefGrfxMemAdr
			jsr	SetCopyBit

			ldx	#$06
::104			PushW	r0
			PushW	r1

			lda	r0L
			sta	r10L
			sec
			sbc	#< 640
			sta	r0L
			lda	r0H
			sta	r10H
			sbc	#> 640
			sta	r0H

			MoveW	r1,r11
			lda	#1
			ldy	vdcClrMode
			dey
::doclr			dey
			beq	:endClr
			asl
			jmp	:doclr
::endClr		tay

::22			jsr	:sub80r1
			dey
			bne	:22

			txa
			pha
			jsr	CopyLineData80
			pla
			tax

			dex
			beq	:105

			PopW	r1
			PopW	r0

			SubVW	640,r0
			jsr	:sub80r1
			ldy	vdcClrMode
			dey
			dey
			beq	:104
			jsr	:sub80r1
			dey
			beq	:104
			jsr	:sub80r1
			jsr	:sub80r1
			jmp	:104

::sub80r1		SubVW	80,r1
			rts

::105			jsr	ClearCopyBit
			jsr	ClearLineData80
			AddVB	8,r2L

			PopW	r1
			PopW	r0

			pla
			sec
			sbc	#$01
			beq	:106
			jmp	:103

::106			SubVB	48,EmptyY		;Koordinate für leeres Feld.
			rts
endif

;*** Puzzle-Teil nach oben verschieben.
:MoveUp			CmpBI	r2H,191			;Ist leeres Feld am unteren Rand ?
			bne	:102			;Nein, weiter...
::101			jmp	NewMoveData		;Nicht möglich, andere Richtung.

::102			lda	LastWay			;Letzte Richtung einlesen.
			cmp	#$00			;Nach unten verschoben ?
			beq	:101			;Ja, Gegenrichtung nicht erlaubt.

			lda	r2L
			clc				;Erste Zeile im Grafikfeld
			adc	#48			;berechnen und "Empty"-Koordinaten
			sta	EmptyY			;aktualisieren.
			sta	r2L

if Flag64_128 = TRUE_C128
			bit	graphMode
			bpl	:40
			jmp	MoveUp80
::40
endif
			lda	#$06			;Puzzle-Teil verschieben.
::103			pha
			jsr	WaitLoop2
			jsr	DefGrfxMemAdr

			ldx	#$06
::104			lda	r0L
			sec
			sbc	#< 320
			sta	r10L
			lda	r0H
			sbc	#> 320
			sta	r10H

			lda	r1L
			sec
			sbc	#< 40
			sta	r11L
			lda	r1H
			sbc	#> 40
			sta	r11H

			jsr	CopyLineData

			dex
			beq	:105

			AddVW	320,r0
			AddVW	 40,r1
			jmp	:104

::105			jsr	ClearLineData
			SubVB	8,r2L

			pla
			sec
			sbc	#$01
			beq	:106
			jmp	:103

::106			rts

if Flag64_128 = TRUE_C128
:MoveUp80		lda	#$06			;Puzzle-Teil verschieben.
::103			pha
			jsr	WaitLoop2
			jsr	DefGrfxMemAdr
			jsr	SetCopyBit

			ldx	#$06
::104			lda	r0L
			sec
			sbc	#< 640
			sta	r10L
			lda	r0H
			sbc	#> 640
			sta	r10H

			MoveW	r1,r11
			lda	#1
			ldy	vdcClrMode
			dey
::doclr			dey
			beq	:endClr
			asl
			jmp	:doclr
::endClr		tay

::22			lda	r11L
			sec
			sbc	#< 80
			sta	r11L
			lda	r11H
			sbc	#> 80
			sta	r11H
			dey
			bne	:22

			txa
			pha
			jsr	CopyLineData80
			pla
			tax

			dex
			beq	:105

			AddVW	640,r0
			jsr	:add80r1
			ldy	vdcClrMode
			dey
			dey
			beq	:104
			jsr	:add80r1
			dey
			beq	:104
			jsr	:add80r1
			jsr	:add80r1
			jmp	:104

::add80r1		AddVW	 80,r1
			rts

::105			jsr	ClearCopyBit
			jsr	ClearLineData80
			SubVB	8,r2L

			pla
			sec
			sbc	#$01
			beq	:106
			jmp	:103

::106			rts
endif

;*** Puzzle-Teil nach rechts verschieben.
:MoveRight		CmpWI	r3,$0000		;Ist leeres Feld am linken Rand ?
			bne	:102			;Nein, weiter...
::101			jmp	NewMoveData		;Nicht möglich, andere Richtung.

::102			lda	LastWay			;Letzte Richtung einlesen.
			cmp	#$03			;Nach links verschoben ?
			beq	:101			;Ja, Gegenrichtung nicht erlaubt.

			SubVW	64,r3
			jsr	DefGrfxMemAdr

if Flag64_128 = TRUE_C128
			bit	graphMode
			bpl	:40
			jmp	MoveRight80
::40
endif
			lda	#$08			;Puzzle-Teil verschieben.
			pha
::103			jsr	WaitLoop2
			PushW	r0
			PushW	r1

			ldx	#$06
::104			ldy	#$07
::105			lda	(r1L),y
			iny
			sta	(r1L),y
			dey
			dey
			bpl	:105
			iny
			lda	#$00
			sta	(r1L),y

			ldy	#7*8 +7
::106			lda	(r0L),y
			pha
			tya
			clc
			adc	#8
			tay
			pla
			sta	(r0L),y
			tya
			sec
			sbc	#8
			tay
			dey
			bpl	:106
			iny
			tya
::107			sta	(r0L),y
			iny
			cpy	#$08
			bne	:107

			AddVW	320,r0
			AddVW	 40,r1

			dex
			bne	:104

			PopW	r1
			PopW	r0

			pla
			sec
			sbc	#$01
			beq	:108
			pha
			AddVW	8,r0
			AddVW	1,r1
			jmp	:103

::108			SubVW	64,EmptyX		;Koordinate für leeres Feld.
			rts

if Flag64_128 = TRUE_C128
;*** Puzzle-Teil nach rechts verschieben.
:MoveRight80		lda	#$08			;Puzzle-Teil verschieben.
			pha
::103			jsr	WaitLoop2
			PushW	r0
			PushW	r1

			AddVW	7,r0
			AddVW	7,r1

			ldx	#48
::104			txa
			pha

			PushW	r0

			ldx	#8
::block			txa
			pha

			lda	r0H			;von r0
			ldy	r0L
			ldx	#18
			jsr	SetVDCReg
			ldx	#31			;Datenbyte holen
			jsr	GetVDC
			jsr	SetVDC			;in nächste Speicherstelle schreiben

			lda	r0L			;r0 = r0 - 1
			sec
			sbc	#1
			sta	r0L
			bcs	:111
			dec	r0H

::111			pla
			tax
			dex
			bne	:block

			inc	r0L			;r0 = r0 + 1
			bne	:112
			inc	r0H

::112			LoadB	ClearLineByte,$60	;rts in Routine setzen
			lda	r0H
			ldy	r0L
			ldx	#18
			jsr	SetVDCReg
			jsr	ClearLine
			LoadB	ClearLineByte,$ea	;nop in Routine setzen
			PopW	r0
			pla
			tax
			dex
			beq	:105

			AddVW	80,r0
			jmp	:104

::105			ldx	vdcClrMode
			lda	#6
			dex
::2			dex
			beq	:1
			asl
			jmp	:2
::1			tax
::104a			txa
			pha
			PushW	r1
			ldx	#8
::3			txa
			pha
			lda	r1H
			ldy	r1L
			ldx	#18
			jsr	SetVDCReg
			ldx	#31			;Datenbyte holen
			jsr	GetVDC
			jsr	SetVDC			;in nächste Speicherstelle schreiben

			lda	r1L			;r1 = r1 - 1
			sec
			sbc	#1
			sta	r1L
			bcs	:111a
			dec	r1H

::111a			pla
			tax
			dex
			bne	:3

			inc	r1L			;r1 = r1 + 1
			bne	:112a
			inc	r1H

::112a			LoadB	ClearLineByte,$60	;rts in Routine setzen
			lda	r1H
			ldy	r1L
			ldx	#18
			jsr	SetVDCReg
			jsr	ClearLine
			LoadB	ClearLineByte,$ea	;nop in Routine setzen
			PopW	r1
			pla
			tax
			dex
			beq	:105a

			AddVW	80,r1
			jmp	:104a
endif

if Flag64_128 = TRUE_C128
::105a			PopW	r1
			PopW	r0

			pla
			sec
			sbc	#$01
			beq	:108
			pha
			inc	r0L
			bne	:115
			inc	r0H
::115			inc	r1L
			bne	:116
			inc	r1H
::116			jmp	:103

::108			SubVW	64,EmptyX		;Koordinate für leeres Feld.

			rts
endif

;*** Puzzle-Teil nach links verschieben.
:MoveLeft
if Flag64_128 = TRUE_C128
			bit	graphMode
			bpl	:40a
			CmpWI	r4,$027f		;Ist leeres Feld am rechten Rand ?
			bne	:102			;Nein, weiter...
			beq	:101
::40a
endif
			CmpWI	r4,$013f		;Ist leeres Feld am rechten Rand ?
			bne	:102			;Nein, weiter...
::101			jmp	NewMoveData		;Nicht möglich, andere Richtung.

::102			lda	LastWay			;Letzte Richtung einlesen.
			cmp	#$02			;Nach rechts verschoben ?
			beq	:101			;Ja, Gegenrichtung nicht erlaubt.

			AddVW	64,r3
			jsr	DefGrfxMemAdr

if Flag64_128 = TRUE_C128
			bit	graphMode
			bpl	:40
			jmp	MoveLeft80
::40
endif
			lda	#$08			;Puzzle-Teil verschieben.
::103			pha
			jsr	WaitLoop2
			SubVW	8,r0
			SubVW	1,r1

			PushW	r0
			PushW	r1

			ldx	#$06
::104			ldy	#$01
::105			lda	(r1L),y
			dey
			sta	(r1L),y
			iny
			iny
			cpy	#$08 +1
			bne	:105
			dey
			lda	#$00
			sta	(r1L),y

			ldy	#8
::106			lda	(r0L),y
			pha
			tya
			sec
			sbc	#8
			tay
			pla
			sta	(r0L),y
			tya
			clc
			adc	#8
			tay
			iny
			cpy	#8*8 +8
			bne	:106
			dey
			lda	#$00
::107			sta	(r0L),y
			dey
			cpy	#8*8
			bcs	:107

			AddVW	320,r0
			AddVW	 40,r1

			dex
			bne	:104

			PopW	r1
			PopW	r0

			pla
			sec
			sbc	#$01
			beq	:108
			jmp	:103

::108			AddVW	64,EmptyX		;Koordinate für leeres Feld.
			rts

if Flag64_128 = TRUE_C128
;*** Puzzle-Teil nach links verschieben.
:MoveLeft80		lda	#$08			;Puzzle-Teil verschieben.
			pha
::103			jsr	WaitLoop2

			PushW	r0
			PushW	r1

			ldx	#$06
::104			lda	r0L
			sec
			sbc	#1
			sta	r10L
			lda	r0H
			sbc	#0
			sta	r10H

			lda	r1L
			sec
			sbc	#1
			sta	r11L
			lda	r1H
			sbc	#0
			sta	r11H

::2			txa
			pha
			jsr	SetCopyBit
			jsr	CopyLineData80
			jsr	ClearCopyBit
			LoadB	ClearLineByte,$60	;rts in Routine setzen
			PushW	r0
			PushW	r1
			AddVW	7,r0
			AddVW	7,r1
			jsr	ClearLineData80
			PopW	r1
			PopW	r0
			LoadB	ClearLineByte,$ea	;nop in Routine setzen
			pla
			tax

			dex
			beq	:105

			AddVW	640,r0
			jsr	:add80r1
			ldy	vdcClrMode
			dey
			dey
			beq	:104x
			jsr	:add80r1
			dey
			beq	:104x
			jsr	:add80r1
			jsr	:add80r1
::104x			jmp	:104

::add80r1		AddVW	 80,r1
			rts

::105			PopW	r1
			PopW	r0

			pla
			sec
			sbc	#$01
			beq	:108
			pha
			SubVW	1,r0
			SubVW	1,r1
			jmp	:103

::108			AddVW	64,EmptyX		;Koordinate für leeres Feld.

			rts
endif

if Flag64_128 = TRUE_C64
;*** Grafikspeicheradresse berechnen.
:DefGrfxMemAdr		ldx	r2L
			jsr	GetScanLine
			lda	r3L
			and	#%11111000
			clc
			adc	r5L
			sta	r0L
			lda	r3H
			adc	r5H
			sta	r0H

			lda	r0L
			sec
			sbc	#< SCREEN_BASE
			sta	r1L
			lda	r0H
			sbc	#> SCREEN_BASE
			sta	r1H
			ldx	#r1L
			ldy	#$03
			jsr	DShiftRight
			AddVW	COLOR_MATRIX,r1
			rts

;*** Grafikzeile löschen.
:ClearLineData		ldy	#8   -1
::101			lda	#$00
			sta	(r1L ),y
			dey
			bpl	:101

			ldy	#8*8 -1
::102			lda	#$00
			sta	(r0L ),y
			dey
			bpl	:102
			rts

;*** Grafikzeile kopieren.
:CopyLineData		ldy	#8*8 -1
::101			lda	(r0L ),y
			sta	(r10L),y
			dey
			bpl	:101

			ldy	#8   -1
::102			lda	(r1L ),y
			sta	(r11L),y
			dey
			bpl	:102
			rts

;*** Bildschirm speichern/laden.
:SetGrafxADDR		LoadW	r0,SCREEN_BASE
			LoadW	r1,R2_ADDR_SS_GRAFX
			LoadW	r2,R2_SIZE_SS_GRAFX
			lda	MP3_64K_SYSTEM
			sta	r3L
			rts

:SetColorADDR		LoadW	r0,COLOR_MATRIX
			LoadW	r1,R2_ADDR_SS_COLOR
			LoadW	r2,R2_SIZE_SS_COLOR
			lda	MP3_64K_SYSTEM
			sta	r3L
			rts

:SaveScreen		jsr	SetGrafxADDR
			jsr	StashRAM
			jsr	SetColorADDR
			jmp	StashRAM

:LoadScreen		jsr	SetGrafxADDR
			jsr	FetchRAM
			jsr	SetColorADDR
			jmp	FetchRAM

;*** Variablen.
:FrameColor		b $00
:MouseMode		b $00
:EmptyX			w $0000
:EmptyY			b $00
:LastWay		b $00
:CurrentWay		b $00

endif

if Flag64_128 = TRUE_C128
;*** Grafikspeicheradresse berechnen.
:DefGrfxMemAdr		ldx	r2L
			jsr	GetScanLine
			bit	graphMode
			bpl	:40

			PushW	r3
			lsr	r3H			;r3 = r3/8(Cards)
			ror	r3L
			lsr	r3H
			ror	r3L
			lsr	r3H
			ror	r3L
			lda	r3L
			jmp	:80

::40			lda	r3L
			and	#%11111000
::80			clc
			adc	r5L
			sta	r0L
			lda	r3H
			adc	r5H
			sta	r0H

			bit	graphMode
			bpl	:40c
			lda	r3L			;r1 = $4000 + r3L
			sta	r1L
			lda	#$40
			sta	r1H
			lda	r2L
			ldx	vdcClrMode
			dex
			dex
			beq	:8
			dex
			beq	:4
			bne	:2
::8			lsr
::4			lsr
::2			lsr
			tax
			beq	:1
::3			AddVW	80,r1			;r1 = r1 + r2L/8 * 80
			dex
			bne	:3
::1			PopW	r3
			rts

::40c			lda	r0L
			sec
			sbc	#< SCREEN_BASE
			sta	r1L
			lda	r0H
			sbc	#> SCREEN_BASE
			sta	r1H
			ldx	#r1L
			ldy	#$03
			jsr	DShiftRight
			AddVW	COLOR_MATRIX,r1
			rts

;*** Grafikzeile löschen.
:ClearLineData		ldy	#8   -1
::101			lda	#$00
			sta	(r1L ),y
			dey
			bpl	:101

			ldy	#8*8 -1
::102			lda	#$00
			sta	(r0L ),y
			dey
			bpl	:102
			rts

:ClearLineData80	ldx	#8
::1			txa
			pha
			lda	r0H
			ldy	r0L
			ldx	#18
			jsr	SetVDCReg
			jsr	ClearLine
			AddVW	80,r0
			pla
			tax
			dex
			bne	:1

;Farbdaten löschen
			ldx	vdcClrMode
			lda	#1
			dex
::3			dex
			beq	:2
			asl
			jmp	:3
::2			tax

::4			txa
			pha
			lda	r1H
			ldy	r1L
			ldx	#18
			jsr	SetVDCReg
			jsr	ClearLine
			AddVW	80,r1
			pla
			tax
			dex
			bne	:4
			rts
endif

if Flag64_128 = TRUE_C128
;*** Grafikzeile kopieren.
:CopyLineData		ldy	#8*8 -1
::101			lda	(r0L ),y
			sta	(r10L),y
			dey
			bpl	:101

			ldy	#8   -1
::102			lda	(r1L ),y
			sta	(r11L),y
			dey
			bpl	:102
			rts

:CopyLineData80		PushW	r0
			ldx	#8
::1			txa
			pha
			lda	r0H			;Copy von r0
			ldy	r0L
			ldx	#32
			jsr	SetVDCReg
			lda	r10H			;nach r10
			ldy	r10L
			ldx	#18
			jsr	SetVDCReg

			lda	#8			;8 Bytes kopieren
			ldx	#30			;WordCount-Register
			jsr	SetVDC

			AddVW	80,r0
			AddVW	80,r10
			pla
			tax
			dex
			bne	:1
			PopW	r0

;Farbdaten kopieren
			ldx	vdcClrMode
			lda	#1
			dex
::4			dex
			beq	:3
			asl
			jmp	:4
::3			tax
			PushW	r1
::2			txa
			pha

			lda	r1H			;Copy von r1
			ldy	r1L
			ldx	#32
			jsr	SetVDCReg
			lda	r11H			;nach r11
			ldy	r11L
			ldx	#18
			jsr	SetVDCReg

			lda	#8			;8 Bytes kopieren
			ldx	#30			;WordCount-Register
			jsr	SetVDC

			AddVW	80,r1
			AddVW	80,r11
			pla
			tax
			dex
			bne	:2
			PopW	r1
			rts

;*** Bildschirm speichern/laden.
:SetGrafxADDR		LoadW	r0,SCREEN_BASE
			LoadW	r1,R2_ADDR_SS_GRAFX
			LoadW	r2,R2_SIZE_SS_GRAFX
			lda	MP3_64K_SYSTEM
			sta	r3L
			rts

:SetColorADDR		LoadW	r0,COLOR_MATRIX
			LoadW	r1,R2_ADDR_SS_COLOR
			LoadW	r2,R2_SIZE_SS_COLOR
			lda	MP3_64K_SYSTEM
			sta	r3L
			rts
endif

if Flag64_128 = TRUE_C128
:SaveScreen		jsr	SetGrafxADDR
			jsr	StashRAM
			jsr	SetColorADDR
			jsr	StashRAM

			ldx	#26			;Register 26 des VDC (Randfarbe)
			jsr	GetVDC			;holen
			sta	OldVDC26+1		;sichern
			lda	#$00			;Randfarbe auf schwarz
			jsr	SetVDC
			lda	graphMode		;Bildschirmmodus?
			bpl	:40			;>40 Zeichen
			ldy	#0			;Kennzeichen für kein Spooler
			tya				;Bildschirm nicht löschen
			clc
			jmp	xSave80Screen		;80 Zeichenbildschirm retten und löschen
::40			rts

:LoadScreen		lda	graphMode		;Bildschirmmodus?
			bpl	LoadScreen40		;>40 Zeichen
			ldy	#0			;Kennzeichen für kein Spooler
			clc
			jsr	xLoad80Screen		;80 Zeichenbildschirm zurücksetzen
			ldx	#26			;Register 26 des VDC (Randfarbe)
:OldVDC26		lda	#0
			jsr	SetVDC			;wiederherstellen
:LoadScreen40		jsr	SetGrafxADDR
			jsr	FetchRAM
			jsr	SetColorADDR
			jmp	FetchRAM

;*** Variablen.
:FrameColor		b $00
:MouseMode		b $00
:EmptyX			w $0000
:EmptyY			b $00
:LastWay		b $00
:CurrentWay		b $00

:SetVDCReg		jsr	SetVDC			;Copyregister setzen
			inx				;in X wird Register
			tya				;in A wird Highbyte
			jmp	SetVDC			;in Y wird Lowbyte übergeben

:SetCopyBit		;Copybit 7 in Reg. 24 setzen
			ldx	#24
			jsr	GetVDC
			ora	#%10000000
			jmp	SetVDC

:ClearCopyBit		ldx	#24
			jsr	GetVDC
			and	#%01111111
			jmp	SetVDC

:ClearLine		lda	#$00
			ldx	#31			;Data-Register
			jsr	SetVDC
:ClearLineByte		nop				;wenn nur 1 Byte gelöscht werden soll dann wir hier rts eingefügt
			dex				;WordCount-Register
			lda	#7
			jmp	SetVDC
endif

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_SCRSAVER + R2_SIZE_SCRSAVER -1
;******************************************************************************
