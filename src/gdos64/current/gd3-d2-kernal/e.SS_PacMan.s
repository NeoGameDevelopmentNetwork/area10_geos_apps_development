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
			t "SymbTab_SCPU"
			t "SymbTab_TC64"
			t "MacTab"
endif

			n "PacMan"
			c "ScrSaver64  V1.0"
			t "opt.Author"
			f SYSTEM
			z $80 ;nur GEOS64

			o LOAD_SCRSAVER

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "Bildschirmschoner für GDOS64..."
endif
if LANG = LANG_EN
			h "Screensaver for GDOS64..."
endif

if .p
:spr1copyA		= SCREEN_BASE + 0*8*40 +0*64
:spr1copyB		= SCREEN_BASE + 0*8*40 +1*64
:spr1copyC		= SCREEN_BASE + 0*8*40 +2*64
:spr2copyA		= SCREEN_BASE +23*8*40 +0*64
:spr2copyB		= SCREEN_BASE +23*8*40 +1*64
:spr2copyC		= SCREEN_BASE +23*8*40 +2*64
:spr3copyA		= SCREEN_BASE +23*8*40 +3*64
:spr3copyB		= SCREEN_BASE +23*8*40 +4*64
:spr3copyC		= SCREEN_BASE +23*8*40 +5*64
:spr4copyA		= SCREEN_BASE +23*8*40 +6*64
:spr4copyB		= SCREEN_BASE +23*8*40 +7*64
:spr4copyC		= SCREEN_BASE +23*8*40 +8*64
endif

;*** ScreenSaver aufrufen.
:MainInit		jmp	InitScreenSaver

;*** ScreenSaver installieren.
;Das Laufwerk, von dem der ScreenSaver
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
:SaverName		b "PacMan",NULL

;*** ScreenSaver aufrufen.
:InitScreenSaver	php				;IRQ sperren.
			sei				;ScreenSaver läuft in der MainLoop!

			ldx	#$1f			;Register ":r0" bis ":r3"
::51			lda	r0L,x			;zwischenspeichern.
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
			ldx	CPU_DATA		;CPU-Register zwischenspeichern und
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

			ldx	CPU_DATA
			lda	#IO_IN			;I/O-Bereich einblenden.
			sta	CPU_DATA

			lda	$d010			;Sprite-X-Koordinate speichern.
			sta	SpriteXHFlag
			lda	$d015			;Sprite-Flag zwischenspeichern.
			sta	SpriteOnFlag
			ldy	#$07
::51			lda	$d000          ,y	;Sprite-X-Koordinate speichern.
			sta	SpritePosBuf +0,y
			lda	$d008          ,y	;Sprite-Y-Koordinate speichern.
			sta	SpritePosBuf +8,y
			lda	$d027          ,y	;Sprite-Farbe speichern.
			sta	SpriteColBuf +0,y
			lda	#$00			;Sprite-Farbe löschen.
			sta	$d027          ,y
			dey
			bpl	:51

			lda	#$07 			;PacMan-Farben setzen.
			sta	$d027
			sta	$d029
			sta	$d02b
			sta	$d02d

			lda	SCPU_HW_SPEED		;SCPU auf 1Mhz runtertakten.
			sta	SpeedFlag
			sta	SCPU_HW_NORMAL

			lda	#$2a			;TurboChameleon64:
			sta	TC64_HW_EN_DIS		;Konfigurationsregister einschalten.
			lda	TC64_HW_SPEED		;Aktuellen TC64-Speed einlesen.
			sta	SpeedFlagTC
			and	#%01111111		;TC64 auf 1MHz umschalten.
			sta	TC64_HW_SPEED
			lda	#$ff
			sta	TC64_HW_EN_DIS		;Konfigurationsregister ausschalten.

			stx	CPU_DATA

			jsr	i_MoveData		;Sprite-Grafiken zwischenspeichern.
			w	spr0pic
			w	SpriteBuffer
			w	8 * 64

			jsr	SaveScreen		;Bildschirm zwischenspeichern.
			jsr	InitPacMan		;PacMan aktivieren.

			lda	CPU_DATA
			pha
			lda	#IO_IN			;I/O-Bereich einblenden.
			sta	CPU_DATA

::52			lda	#$00			;Warten bis keine Taste gedrückt.
			sta	$dc00
			lda	$dc01
			eor	#$ff
			bne	:52

::53			lda	#$00
			jsr	MovePacMan		;PacMan bewegen.
			lda	#$01
			jsr	MovePacMan		;PacMan bewegen.
			lda	#$02
			jsr	MovePacMan		;PacMan bewegen.
			lda	#$03
			jsr	MovePacMan		;PacMan bewegen.

::54			lda	#$00
			sta	$dc00			;Tastenregister aktivieren.
			lda	$dc01			;Tastenstatus einlesen.
			eor	#$ff			;Wurde Taste gedrückt ?
			bne	:55			;Ja, Ende...

			jsr	NextPacMan		;PacMan bewegen.
			jmp	:53			;Schleife...

::55			ldy	#$07			;Sprite-Daten zurücksetzen.
::56			lda	SpritePosBuf +0,y
			sta	$d000          ,y
			lda	SpritePosBuf +8,y
			sta	$d008          ,y
			lda	SpriteColBuf +0,y
			sta	$d027          ,y
			dey
			bpl	:56

			lda	SpriteOnFlag
			sta	$d015
			lda	SpriteXHFlag
			sta	$d010

			lda	#$2a			;TurboChameleon64:
			sta	TC64_HW_EN_DIS		;Konfigurationsregister einschalten.
			lda	SpeedFlagTC		;Speedflag am TC64 wieder
			sta	TC64_HW_SPEED		;zurücksetzen.
			lda	#$ff
			sta	TC64_HW_EN_DIS		;Konfigurationsregister ausschalten.

			ldy	#$00			;SCPU auf Start-Takt
			bit	SpeedFlag		;zurücksetzen.
			bmi	:57
			iny
::57			sta	SCPU_HW_NORMAL,y

			pla
			sta	CPU_DATA		;I/O-Bereich zurücksetzen.

			jsr	i_MoveData
			w	SpriteBuffer
			w	spr0pic
			w	8 * 64

			jsr	LoadScreen		;Bildschirm wieder herstellen.

			pla				;Variablen zurücksetzen.
			jsr	SetPattern
			PopB	dispBufferOn
			rts

;*** PacMan zeichnen.
:InitPacMan		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$00,$07
			w	$0000,$013f
			lda	#$00
			jsr	DirectColor

			jsr	i_Rectangle
			b	$b8,$c7
			w	$0000,$013f
			lda	#$00
			jsr	DirectColor

			jsr	i_MoveData		;PacMan-Grafiken in
			w	Sprite_02		;Zwischenspeicher kopieren.
			w	spr1copyA
			w	3 * 64
			jsr	i_MoveData
			w	Sprite_02
			w	spr2copyA
			w	3 * 64
			jsr	i_MoveData
			w	Sprite_02
			w	spr3copyA
			w	3 * 64
			jsr	i_MoveData
			w	Sprite_02
			w	spr4copyA
			w	3 * 64

			ldx	#$01			;Sprite-Daten initialisieren.
			jsr	DoMirrorSprite		;(Sprite #1 und #3 spiegeln für
			ldx	#$03			; Gegenrichtung...)
			jsr	DoMirrorSprite

			ldx	#$ff
			stx	SpriteMode
			inx
			stx	SpriteMove
			stx	SpriteDir

			lda	#$00			;Startwerte für X-/Y-Koordinate.
			sta	r4L
			sta	r4H
			sta	SpriteXlow  +0
			sta	SpriteDir   +0
			sta	SpriteDir   +2
			lda	#$80
			sta	SpriteXlow  +1
			sta	SpriteDir   +1
			sta	SpriteDir   +3
			lda	#$40
			sta	SpriteXlow  +2
			lda	#$10
			sta	SpriteXlow  +3
			lda	#$00
			sta	SpriteXhigh +0
			sta	SpriteXhigh +1
			sta	SpriteXhigh +2
			lda	#$01
			sta	SpriteXhigh +3
			lda	#$04
			sta	r5L
			sta	SpriteY     +0
			clc
			adc	#5*8
			sta	SpriteY     +1
			clc
			adc	#6*8
			sta	SpriteY     +2
			clc
			adc	#5*8
			sta	SpriteY     +3

			lda	#$01			;Sprites zeichnen.
			jsr	:51
			lda	#$03
			jsr	:51
			lda	#$05
			jsr	:51
			lda	#$07

::51			sta	r3L			;(PacMan-Untergrund/Gesicht)
			LoadW	r4 ,Sprite_01
			jsr	DrawSprite
			jsr	PosSprite
			jsr	EnablSprite
			dec	r3L
			jsr	PosSprite
			jmp	EnablSprite

;*** Sprite animieren.
:NextPacMan		lda	#$00			;PacMan #1 animieren.
			jsr	:50
			lda	#$01			;PacMan #2 animieren.
			jsr	:50
			lda	#$02			;PacMan #3 animieren.
			jsr	:50
			lda	#$03			;PacMan #4 animieren.

::50			pha
			jsr	LoadPacManData		;PacMan-Koordinaten einlesen.
			bmi	:52			; => Gegenrichtung, weiter...

::51			inc	CurrentMode		;Zeiger auf nächstes Sprite.
			CmpBI	CurrentMode,3		;Ende erreicht ?
			bcc	:53			;Nein, weiter...
			lda	#$80			;Animationsmodus wechseln.
			sta	CurrentMove

::52			dec	CurrentMode		;Zeiger auf vorheriges Sprite.
			bpl	:53			;Ende erreicht ? Nein, weiter...
			lda	#$00			;Animationsmodus wechseln.
			sta	CurrentMove
			beq	:51

::53			pla
			pha
			jsr	SavePacManData		;PacMan-Daten speichern
			txa
			jsr	:54
			pla
			jmp	MovePacMan

::54			sta	:55 +1			;Zeiger auf Sprite-Tabelle
			asl				;berechnen und neue Sprite-Grafik
			clc				;speichern.
::55			adc	#$ff
			clc
			adc	CurrentMode
			asl
			tax
			lda	SpriteTab2 +0,x
			sta	r4L
			lda	SpriteTab2 +1,x
			sta	r4H
			jmp	DrawSprite

;*** PacMan bewegen.
:MovePacMan		pha
			jsr	LoadPacManData		;PacMan-Koordinaten einlesen.

			jsr	ClearScreen		;Grafik unter PacMan löschen.

			bit	CurrentDir		;Bewegungsrichtung einlesen.
			bmi	:53			; => Gegenrichtung, weiter...

;--- Nach rechts bewegen.
::51			inc	r14L			;PacMan nach rechts bewegen.
			bne	:52
			inc	r14H
::52			CmpWI	r14 ,312		;Rechten Rand erreicht ?
			bcc	:55			;Nein, weiter...

;--- Letztes Card in Zeile löschen.
;Hinweis: Aufruf ClearScreen eingefügt,
;da sonst die letzten Pixel der Zeile
;nicht gelöscht werden.
			jsr	ClearScreen		;Grafik unter PacMan löschen.

			pla
			pha
			jsr	MirrorPacMan		;PacMan spiegeln, Y-Pos nach unten.

			lda	#$80			;Richtung umkehren.
			sta	CurrentDir		;(von rechts nach links)

;--- Hinweis:
;Das letzte Card in der nächsten Zeile
;wird erst im nächsten Move-Durchlauf
;gelöscht, da zuerst die x-Position des
;Sprite um 1px reduziert werden muss!

;--- Nach links bewegen.
::53			lda	r14L			;PacMan nach links bewegen.
			bne	:54
			dec	r14H
::54			dec	r14L

			lda	r14L
			ora	r14H			;Linken Rand erreicht ?
			bne	:55			;Nein, weiter...

;--- Card#0 aktuelle Zeile löschen.
			jsr	ClearScreen		;Grafik unter PacMan löschen und

			lda	#$00			;Richtung umkehren.
			sta	CurrentDir		;(von links nach rechts)

;--- Card#0 in nächster Zeile löschen.
			jsr	ClearScreen		;Grafik unter PacMan löschen.

			pla
			pha
			jsr	MirrorPacMan		;PacMan spiegeln, Y-Pos nach unten.
;--- Hinweis:
;Sprite steht an x-Position 0, daher im
;nächsten Move-Durchlauf zuerst Card#0
;der Grafik löschen!
;			jmp	:51			;Fehler, erst löschen, dann bewegen!

;--- Neue Position speichern.
::55			pla
			jsr	SavePacManData		;PacMan-Daten speichern.

			MoveW	r14 ,r4			;PacMan-Sprite #1 und #2 setzen.
			MoveB	r15L,r5L
			jsr	PosSprite
			inc	r3L
			jmp	PosSprite

;*** Sprites spiegeln.
:MirrorPacMan		tax
			lda	r15L
			clc
			adc	#$08
			cmp	#180
			bcc	:51
			lda	#4
::51			sta	r15L

:DoMirrorSprite		txa
			sta	:51 +1
			asl
			clc
::51			adc	#$ff
			asl
			pha
			jsr	StartMirror
			pla
			clc
			adc	#$02
			pha
			jsr	StartMirror
			pla
			clc
			adc	#$02

;*** Sprite-bereich spiegeln.
:StartMirror		tax
			lda	SpriteTab2 +0,x
			sta	r0L
			lda	SpriteTab2 +1,x
			sta	r0H

			ldy	#$00
::51			lda	#$00
			sta	r3L
			sta	r3H
			lda	(r0L),y
			ldx	#$08
::52			asl
			ror	r3H
			dex
			bne	:52
			iny
			lda	(r0L),y
			ldx	#$08
::53			asl
			ror	r3L
			dex
			bne	:53
			dey
			lda	r3L
			sta	(r0L),y
			iny
			lda	r3H
			sta	(r0L),y
			iny
			iny
			cpy	#48
			bcc	:51
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

;*** Sprite-Bereich löschen.
:ClearScreen		lda	#$00
			bit	CurrentDir
			bpl	:51
			lda	#$08
::51			clc
			adc	r14L
			sta	r3L
			lda	#$00
			adc	r14H
			sta	r3H

			lda	r3L
			clc
			adc	#07
			sta	r4L
			lda	r3H
			adc	#$00
			sta	r4H

			CmpWI	r4,319 +1
			bcc	ClearLineData
			LoadW	r4,319

;*** Rechteck-Bereich löschen.
:ClearLineData		lda	r15L
			clc
			adc	#$04
			sta	r2L
			clc
			adc	#07
			sta	r2H

			lda	CPU_DATA
			pha
			lda	#$30
			sta	CPU_DATA

			lda	#$00
			jsr	SetPattern
			jsr	Rectangle

			lda	#$90
			jsr	DirectColor
			pla
			sta	CPU_DATA
			rts

;*** PacMan-Koordinaten einlesen.
:LoadPacManData		tax
			lda	SpriteXlow ,x		;PacMan-Koordinaten einlesen.
			sta	r14L
			lda	SpriteXhigh,x
			sta	r14H
			lda	SpriteY    ,x
			sta	r15L
			lda	SpriteDir  ,x
			sta	CurrentDir
			lda	SpriteMode ,x
			sta	CurrentMode
			lda	SpriteMove ,x
			sta	CurrentMove
			rts

;*** PacMan-Koordinaten speichern.
:SavePacManData		tax				;PacMan-Koordinaten einlesen.
			lda	r14L
			sta	SpriteXlow ,x
			lda	r14H
			sta	SpriteXhigh,x
			lda	r15L
			sta	SpriteY    ,x
			lda	CurrentDir
			sta	SpriteDir  ,x
			lda	CurrentMode
			sta	SpriteMode ,x
			lda	CurrentMove
			sta	SpriteMove ,x
			lda	SpriteNum  ,x		;Sprite-Nummer einlesen und
			sta	r3L			;zwischenspeichern.
			rts

;*** Variablen.
:SpriteXlow		b $00,$00,$00,$00
:SpriteXhigh		b $00,$00,$00,$00
:SpriteY		b $00,$00,$00,$00
:SpriteMode		b $00,$00,$00,$00
:SpriteMove		b $00,$00,$00,$00
:SpriteDir		b $00,$00,$00,$00
:SpriteNum		b $00,$02,$04,$06
:CurrentSprite		b $00
:CurrentMode		b $00
:CurrentMove		b $00
:CurrentDir		b $00
:SpeedFlag		b $00
:SpeedFlagTC		b $00

:SpriteTab2		w spr1copyA
			w spr1copyB
			w spr1copyC
			w spr2copyA
			w spr2copyB
			w spr2copyC
			w spr3copyA
			w spr3copyB
			w spr3copyC
			w spr4copyA
			w spr4copyB
			w spr4copyC
:SpriteBuffer		s 64 * 8
:SpriteOnFlag		b $00
:SpriteXHFlag		b $00
:SpritePosBuf		s 8*2
:SpriteColBuf		s 8

;*** Sprite für PacMans
:Sprite_01		b %00000111,%11100000,%00000000
			b %00011111,%11111000,%00000000
			b %00111111,%11111100,%00000000
			b %01111111,%11111110,%00000000
			b %01111111,%11111110,%00000000
			b %11111111,%11111111,%00000000
			b %11111111,%11111111,%00000000
			b %11111111,%11111111,%00000000
			b %11111111,%11111111,%00000000
			b %11111111,%11111111,%00000000
			b %01111111,%11111110,%00000000
			b %01111111,%11111110,%00000000
			b %00111111,%11111100,%00000000
			b %00011111,%11111000,%00000000
			b %00000111,%11100000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b $00

:Sprite_02		b %00000000,%00000000,%00000000
			b %00000111,%11100000,%00000000
			b %00011111,%11111000,%00000000
			b %00111111,%10011100,%00000000
			b %00111111,%10011100,%00000000
			b %01111111,%11111110,%00000000
			b %01111111,%11111110,%00000000
			b %01111111,%10000000,%00000000
			b %01111111,%11111110,%00000000
			b %01111111,%11111110,%00000000
			b %00111111,%11111100,%00000000
			b %00111111,%11111100,%00000000
			b %00011111,%11111000,%00000000
			b %00000111,%11100000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b $00

:Sprite_03		b %00000000,%00000000,%00000000
			b %00000111,%11100000,%00000000
			b %00011111,%11111000,%00000000
			b %00111111,%10011100,%00000000
			b %00111111,%10011100,%00000000
			b %01111111,%11111110,%00000000
			b %01111111,%11110000,%00000000
			b %01111111,%10000000,%00000000
			b %01111111,%11110000,%00000000
			b %01111111,%11111110,%00000000
			b %00111111,%11111100,%00000000
			b %00111111,%11111100,%00000000
			b %00011111,%11111000,%00000000
			b %00000111,%11100000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b $00

:Sprite_04		b %00000000,%00000000,%00000000
			b %00000111,%11100000,%00000000
			b %00011111,%11111000,%00000000
			b %00111111,%10011100,%00000000
			b %00111111,%10011110,%00000000
			b %01111111,%11111000,%00000000
			b %01111111,%11000000,%00000000
			b %01111111,%00000000,%00000000
			b %01111111,%11000000,%00000000
			b %01111111,%11111000,%00000000
			b %00111111,%11111110,%00000000
			b %00111111,%11111100,%00000000
			b %00011111,%11111000,%00000000
			b %00000111,%11100000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b %00000000,%00000000,%00000000
			b $00

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LOAD_SCRSAVER + R2S_SCRSAVER -1
;******************************************************************************
