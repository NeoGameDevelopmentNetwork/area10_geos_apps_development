; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_1"
			t "SymbTab_GDOS"
			t "SymbTab_GTYP"
			t "SymbTab_MMAP"
			t "MacTab"
endif

;*** GEOS-Header.
			n "PuzzleIt!"
			c "ScrSaver64  V1.0"
			t "opt.Author"
			f SYSTEM
			z $80;nur GEOS64

			o LOAD_SCRSAVER

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "Bildschirmschoner für GDOS64..."
endif
if LANG = LANG_EN
			h "Screensaver for GDOS64..."
endif

;*** ScreenSaver aufrufen.
:MainInit		jmp	InitScreenSaver

;*** ScreenSaver installieren.
;Das Laufwerk, von welchem ScreenSaver
;geladen wurde, muss noch aktiv sein!
;Rückgabe eines Installationsfehlers
;im xReg ($00=Kein Fehler).
;ACHTUNG!
;Nur JMP-Befehl oder "LDX #$00:RTS",
;da direkt im Anschluss der Name des
;ScreenSavers erwartet wird!
;(Addresse: LOAD_SCRSAVER +6)
:InstallSaver		ldx	#$00
			rts

;*** Name des ScreenSavers.
;Direkt nach dem JMP-Befehl, da über
;GD.CONFIG der Name an dieser Stelle
;ausgelesen wird.
;Der Name muss mit dem Dateinamen
;übereinstimmen, da der ScreenSaver
;über diesen Namen beim Systemstart
;geladen wird.
:SaverName		b "PuzzleIt!",NULL

;*** ScreenSaver aufrufen.
:InitScreenSaver	php				;IRQ sperren.
			sei				;ScreenSaver läuft in der MainLoop!

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
			ldx	CPU_DATA		;CPU-Register speichern und
			lda	#IO_IN			;I/O-Bereich einblenden.
			sta	CPU_DATA

::53			lda	#$00
			sta	$dc00			;Tastenregister aktivieren.
			lda	$dc01			;Tastenstatus einlesen.
			eor	#$ff			;Taste noch gedrückt ?
			bne	:53			;Ja, Warteschleife...

			stx	CPU_DATA		;CPU-Register zurücksetzen.
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
			w	$0000,$013f
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
			CmpWI	r4,320
			bcc	:51

::80			LoadW	r3  ,$0000
			LoadW	r4  ,$013f
			LoadB	r11L,$00
::52			lda	#%01010101
			jsr	HorizontalLine
			AddVB	47,r11L
			lda	#%11111111
			jsr	HorizontalLine
			AddVB	 1,r11L
			CmpBI	r11L,192
			bcc	:52

			LoadB	LastWay,$ff		;Alle Richtungen freigeben.
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
			ldx	CPU_DATA		;CPU-Register speichern und
			lda	#IO_IN			;I/O-Bereich einblenden.
			sta	CPU_DATA
			lda	#$00
			sta	$dc00			;Tastenregister aktivieren.
			lda	$dc01			;Tastenstatus einlesen.
			stx	CPU_DATA		;CPU-Register zurücksetzen.
			plp				;IRQ-Status zurücksetzen.

			eor	#$ff			;Wurde Taste gedrückt ?
			beq	DoPuzzle		;Nein, Schleife bis Taste gedrückt.

;*** Zurück zum Programm.
:EndPuzzle		php				;IRQ-Status speichern und
			sei				;IRQ abschalten.
			ldx	CPU_DATA		;CPU-Register speichern und
			lda	#IO_IN			;I/O-Bereich einblenden.
			sta	CPU_DATA
			lda	FrameColor
			sta	$d020
			lda	MouseMode
			sta	$d015
			stx	CPU_DATA		;CPU-Register zurücksetzen.
			plp				;IRQ-Status zurücksetzen.

			jsr	LoadScreen		;Bildschirm zurücksetzen.

			pla				;Variablen zurücksetzen.
			jsr	SetPattern
			PopB	dispBufferOn
			rts

;*** Register zwischenspeichern.
:InitPuzzle		php				;IRQ-Status speichern und
			sei				;IRQ abschalten.
			ldx	CPU_DATA		;CPU-Register speichern und
			lda	#IO_IN			;I/O-Bereich einblenden.
			sta	CPU_DATA

			lda	$d020			;Rahmenfarbe zwischenspeichern.
			sta	FrameColor
			lda	#$00			;Rahmenfarbe auf "schwarz" setzen.
			sta	$d020

			lda	$d015			;Spritemodi zwischenspeichern.
			sta	MouseMode
			lda	#$00			;Alle Sprites abschalten.
			sta	$d015

			stx	CPU_DATA		;CPU-Register zurücksetzen.
			plp				;IRQ-Status zurücksetzen.
			rts

;*** Warteschleife vor Puzzle-Aufbau.
:WaitLoop1		php				;IRQ-Status speichern und
			sei				;IRQ abschalten.
			ldx	CPU_DATA		;CPU-Register speichern und
			lda	#IO_IN			;I/O-Bereich einblenden.
			sta	CPU_DATA

			ldy	#$04
::51			lda	$dc08			;1/10sec-Register einlesen und
::52			cmp	$dc08			;auf Veränderung warten.
			beq	:52
			lda	#$00
			sta	$dc00			;Tastenregister aktivieren.
			lda	$dc01			;Tastenstatus einlesen.
			eor	#$ff			;Wurde Taste gedrückt ?
			bne	:53			;Nein, Schleife bis Taste gedrückt.
			dey
			bne	:51

::53			stx	CPU_DATA		;CPU-Register zurücksetzen.
			plp
			rts

;*** Warteschleife zwischen den Verschiebungsphasen.
:WaitLoop2		txa
			pha

			php				;IRQ-Status speichern und
			sei				;IRQ abschalten.
			ldx	CPU_DATA		;CPU-Register speichern und
			lda	#IO_IN			;I/O-Bereich einblenden.
			sta	CPU_DATA

			ldy	$d012
::51			lda	$d012
			bne	:51

			ldy	#32
::52			lda	$d012
::53			cmp	$d012
			beq	:53
			dey
			bne	:52

			stx	CPU_DATA		;CPU-Register zurücksetzen.
			plp

			pla
			tax				;IRQ-Status zurücksetzen.
			rts

;*** Puzzle verschieben.
:MovePuzzle		jsr	SetEmpty		;Koordinaten für leeres Feld.

:NewMoveData		php				;IRQ-Status speichern und
			sei				;IRQ abschalten.
			ldx	CPU_DATA		;CPU-Register speichern und
			lda	#IO_IN			;I/O-Bereich einblenden.
			sta	CPU_DATA
			lda	$d012			;Zufallszahl einlesen.
			stx	CPU_DATA		;CPU-Register zurücksetzen.
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

;*** Puzzle-Teil nach rechts verschieben.
:MoveRight		CmpWI	r3,$0000		;Ist leeres Feld am linken Rand ?
			bne	:102			;Nein, weiter...
::101			jmp	NewMoveData		;Nicht möglich, andere Richtung.

::102			lda	LastWay			;Letzte Richtung einlesen.
			cmp	#$03			;Nach links verschoben ?
			beq	:101			;Ja, Gegenrichtung nicht erlaubt.

			SubVW	64,r3
			jsr	DefGrfxMemAdr

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

;*** Puzzle-Teil nach links verschieben.
:MoveLeft		CmpWI	r4,$013f		;Ist leeres Feld am rechten Rand ?
			bne	:102			;Nein, weiter...
::101			jmp	NewMoveData		;Nicht möglich, andere Richtung.

::102			lda	LastWay			;Letzte Richtung einlesen.
			cmp	#$02			;Nach rechts verschoben ?
			beq	:101			;Ja, Gegenrichtung nicht erlaubt.

			AddVW	64,r3
			jsr	DefGrfxMemAdr

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
			LoadW	r1,R2A_SS_GRAFX
			LoadW	r2,R2S_SS_GRAFX
			lda	MP3_64K_SYSTEM
			sta	r3L
			rts

:SetColorADDR		LoadW	r0,COLOR_MATRIX
			LoadW	r1,R2A_SS_COLOR
			LoadW	r2,R2S_SS_COLOR
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

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LOAD_SCRSAVER + R2S_SCRSAVER -1
;******************************************************************************
