; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t	"TopSym"
			t	"Sym128.erg"
			t	"TopMac"
			t	"GD_Mac"
			t	"src.GeoDOS.ext"
endif

			n	"mod.#102.obj"
			o	ModStart
			r	EndAreaCBM

;*** Infotext ausgeben.
:Info			ldy	#$0f
::101			lda	AppClass,y
			sta	V102b1,y
			sta	V102c1,y
			sta	V102d1,y
			sta	V102g1,y
			dey
			bpl	:101

			jsr	MouseOff		;Maus abschalten.

			jsr	InitForIO
			lda	C_ScreenBack
			and	#%00001111
			sta	$d020
			lda	C_Mouse
			sta	$d027
			jsr	DoneWithIO

			jsr	ClrScreen

			jsr	i_BitmapUp
			w	Icon_00
			b	$00,$00,$03,$15
			jsr	i_BitmapUp
			w	Icon_01
			b	$03,$00,$03,$15

			ldy	#$00
			ldx	#$00
::102			lda	SCREEN_BASE +0*40*8 +0*8,y
			sta	spr5pic             +0*8,x
			lda	SCREEN_BASE +1*40*8 +0*8,y
			sta	spr5pic             +3*8,x
			lda	SCREEN_BASE +2*40*8 +0*8,y
			sta	spr5pic             +6*8,x
			lda	SCREEN_BASE +0*40*8 +3*8,y
			sta	spr6pic             +0*8,x
			lda	SCREEN_BASE +1*40*8 +3*8,y
			sta	spr6pic             +3*8,x
			lda	SCREEN_BASE +2*40*8 +3*8,y
			sta	spr6pic             +6*8,x
			inx
			inx
			inx
			cpx	#24
			bcc	:103
			txa
			sbc	#23
			tax
::103			iny
			cpy	#24
			bcc	:102

			jsr	InitForIO
			lda	#$00
			sta	$d017
			sta	$d01c
			sta	$d01d
			LoadB	$d02c,$06
			LoadB	$d02d,$0d
			jsr	DoneWithIO

			LoadB	r3L,$05
			LoadW	r4 ,$0034
			LoadB	r5L,$36
			jsr	PosSprite
			jsr	EnablSprite
			inc	r3L
			jsr	PosSprite
			jsr	EnablSprite

			jsr	ClrScreen

;--- Ergänzung: M.Kanet/18.12.18
;MP128 setzt beim Wechsel von 80Z auf 40Z die Mausgrenzen nicht korrekt.
;Der folgende Code setzt die Mausgrenzen und positioniert den Mauszeiger
;in der Mitte des Bildschirms.
			jsr	SetWindow_a

			php
			sei
			LoadW	r11,160
			ldy	#100
			sec
			jsr	StartMouseMode
			plp
			jsr	UpdateMouse

;*** Info anzeigen.
:StartViewInfo		Window	$20,$a7,$0020,$011f
			jsr	i_BitmapUp
			w	Icon_Close
			b	$04,$20,$01,$08

			lda	#$00
			sta	V102a0
			sta	currentMode

::101			jsr	ClrWinBox
			lda	V102a0
			pha
			add	$31
			sta	V102a2+10
			pla
			asl
			tax
			lda	V102a1+0,x
			sta	:102 +1
			lda	V102a1+1,x
			sta	:102 +2
::102			jsr	$ffff
			PrintStrgV102a2
			jsr	WaitForUser
			jsr	TestMseKlick
			bmi	:111
			bne	:121

			LoadB	r3L,$05
			jsr	DisablSprite
			inc	r3L
			jsr	DisablSprite

			jsr	ClrScreen
			jmp	InitScreen

::111			ldx	V102a0
			inx
			cpx	#$04
			bne	:112
			ldx	#$00
::112			stx	V102a0
			jmp	:101

::121			ldx	V102a0
			dex
			cpx	#$ff
			bne	:122
			ldx	#$03
::122			stx	V102a0
			jmp	:101

;*** Ausgabe Programm-Info.
:Info_a			PrintStrgV102b0			;Ausgabe Autor-Info.
			rts

:Info_b			PrintStrgV102c0			;Ausgabe Programm-Info.
			rts

:Info_c			PrintStrgV102d0			;Ausgabe Versions-Info.
			PrintStrgVersionCode
			PrintStrgV102d2
			PrintStrgAppClass
			PrintStrgV102d4
			rts

:Info_f			PrintStrgV102g0			;Ausgabe Testphase-Info.
			rts

;*** Warten auf User.
:WaitForUser		NoMseKey
			ClrB	pressFlag		;Warten auf Maus-Klick.
::101			lda	pressFlag
			beq	:101
			NoMseKey			;Warten bis Maus-Taste frei.
			rts

;*** Fensterinhalt löschen.
:ClrWinBox		FillPRec$00,$28,$a6,$0021,$011e
			jsr	i_BitmapUp
			w	Icon_02
			b	$22,$98,Icon_02_x,Icon_02_y
			jsr	i_ColorBox
			b	$22,$13,$02,$02,$01
			rts

;*** Mausklick testen.
:TestMseKlick		LoadB	r2L,$98
			LoadB	r2H,$a7
			LoadW	r3,$0110
			LoadW	r4,$011f
			php
			sei
			jsr	IsMseInRegion
			plp
			tax
			bne	:101
			rts

::101			sec				;Y-Koordinate der Maus einlesen.
			lda	mouseYPos		;Testen ob Maus innerhalb des
			sbc	#$98			;"Eselsohrs" angeklickt wurde.
			sta	r0L

			sec
			lda	mouseXPos+0
			sbc	#<$0110
			eor	#%00001111
			cmp	r0L
			bcs	:102			;Seite vor.
			ldx	#$7f			;Seite zurück.
			rts
::102			ldx	#$ff
			rts

if Sprache = Deutsch
;*** Variablen.
:V102a0			b $00
:V102a1			w Info_a, Info_b
			w Info_c, Info_f
:V102a2			b GOTOXY
			w $00da
			b $26
			b "Seite 1/4"
			b NULL

;*** Autor-Information.
:V102b0			b GOTOXY
			w $0030
			b $26
			b "Der Autor...    "
			b GOTOXY
			w $0058
			b $3e
:V102b1			b "1234567890123456"
			b GOTOXY
			w $0058
			b $48
			b "Benutzeroberfläche"
			b GOTOXY
			w $0030
			b $5b
			b "o Idee & Entwicklung:"
			b GOTOXY
			w $0030
			b $64
			b "  Markus Kanet"
			b GOTOXY
			w $0030
			b $82
			b "o EMail:"
			b GOTOXY
			w $0030
			b $8b
			b "  darkvision(at)gmx.eu"
			b NULL

;*** Programm-Information.
:V102c0			b GOTOXY
			w $0030
			b $26
			b "Das Programm... "
			b GOTOXY
			w $0058
			b $3e
:V102c1			b "1234567890123456"
			b GOTOXY
			w $0058
			b $48
			b "Benutzeroberfläche"
			b GOTOXY
			w $0030
			b $5d
			b "o DeskTop-Funktionen"
			b GOTOXY
			w $0030
			b $66
			b "o Texte konvertieren"
			b GOTOXY
			w $0030
			b $6f
			b "o Texte auf Drucker ausgeben"
			b GOTOXY
			w $0030
			b $78
			b "o Verzeichnisse drucken"
			b GOTOXY
			w $0030
			b $81
			b "o MSDOS-Disketten bearbeiten"
			b GOTOXY
			w $0030
			b $8a
			b "o Programmverwaltung"
			b NULL

;*** Versions-Information.
:V102d0			b GOTOXY
			w $0030
			b $26
			b "Die Version...  "
			b GOTOXY
			w $0058
			b $3e
:V102d1			b "1234567890123456"
			b GOTOXY
			w $0058
			b $48
			b "Benutzeroberfläche"
			b GOTOXY
			w $0030
			b $5c
			b "Version: "
			b NULL

:V102d2			b GOTOXY
			w $0030
			b $65
			b "Klasse : "
			b NULL

:V102d4			b GOTOXY
			w $0030
			b $73
			b "System : GEOS V2.x"
			b GOTOXY
			w $0030
			b $7c
			b "         C64/C128 (40 Zeichen)"
			b GOTOXY
			w $0030
			b $88
			b "Unterstützt CMD FD, CMD HD,"
			b GOTOXY
			w $0030
			b $91
			b "CMD RAMLink, SD2IEC..."
			b NULL
endif

if Sprache = Englisch
;*** Variablen.
:V102a0			b $00
:V102a1			w Info_a, Info_b
			w Info_c, Info_f
:V102a2			b GOTOXY
			w $00da
			b $26
			b "Page  1/4"
			b NULL

;*** Autor-Information.
:V102b0			b GOTOXY
			w $0030
			b $26
			b "The author...    "
			b GOTOXY
			w $0058
			b $3e
:V102b1			b "1234567890123456"
			b GOTOXY
			w $0058
			b $48
			b "DeskTop-workshell"
			b GOTOXY
			w $0030
			b $5b
			b "o Idea & programming:"
			b GOTOXY
			w $0030
			b $64
			b "  Markus Kanet"
			b GOTOXY
			w $0030
			b $82
			b "o EMail:"
			b GOTOXY
			w $0030
			b $8b
			b "  darkvision(at)gmx.eu"
			b NULL

;*** Programm-Information.
:V102c0			b GOTOXY
			w $0030
			b $26
			b "The programm... "
			b GOTOXY
			w $0058
			b $3e
:V102c1			b "1234567890123456"
			b GOTOXY
			w $0058
			b $48
			b "DeskTop-workshell"
			b GOTOXY
			w $0030
			b $5d
			b "o DeskTop-functions"
			b GOTOXY
			w $0030
			b $66
			b "o convert textfiles"
			b GOTOXY
			w $0030
			b $6f
			b "o print textfiles"
			b GOTOXY
			w $0030
			b $78
			b "o print directories"
			b GOTOXY
			w $0030
			b $81
			b "o use PCDOS-disks"
			b GOTOXY
			w $0030
			b $8a
			b "o file-managment"
			b NULL

;*** Versions-Information.
:V102d0			b GOTOXY
			w $0030
			b $26
			b "The version...  "
			b GOTOXY
			w $0058
			b $3e
:V102d1			b "1234567890123456"
			b GOTOXY
			w $0058
			b $48
			b "DeskTop-workshell"
			b GOTOXY
			w $0030
			b $5c
			b "Version: "
			b NULL

:V102d2			b GOTOXY
			w $0030
			b $65
			b "Class  : "
			b NULL

:V102d3			b GOTOXY
			w $0030
			b $a1
			b "** Full version **"
			b NULL

:V102d4			b GOTOXY
			w $0030
			b $73
			b "System : GEOS V2.x / gateWay"
			b GOTOXY
			w $0030
			b $7c
			b "         C64/C128 (40 Zeichen)"
			b GOTOXY
			w $0030
			b $88
			b "All hardware by CMD is"
			b GOTOXY
			w $0030
			b $91
			b "supported (incl. NativeMode)"
			b NULL
endif

;*** Copyright-Information.
:V102g0			b GOTOXY
			w $0030
			b $26
			b "Copyright...    "
			b GOTOXY
			w $0058
			b $3e
:V102g1			b "1234567890123456"
			b GOTOXY
			w $0030
			b $5b
			b "o Copyright:"
			b GOTOXY
			w $0030
			b $64
			b "  (C) Markus Kanet"
			b NULL

;*** Icon-Grafiken.
:Icon_00
<MISSING_IMAGE_DATA>
:Icon_00_x		= .x
:Icon_00_y		= .y

:Icon_01
<MISSING_IMAGE_DATA>
:Icon_01_x		= .x
:Icon_01_y		= .y

:Icon_02
<MISSING_IMAGE_DATA>
:Icon_02_x		= .x
:Icon_02_y		= .y

:EndInfo
