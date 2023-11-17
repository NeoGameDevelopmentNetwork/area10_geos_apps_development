; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "GEOS_QuellCo.ext"
endif

			n "SuperGEOS.obj"
			c "SuperPatch  v1.5"
			a "Maurice Randall"
			f $0e
			z $80
			o $0400
			p MainInit
			i
<MISSING_IMAGE_DATA>

;*** Haupteinsprung.
:MainInit		bit	firstBoot		;Als Bootprogramm gestartet ?
			bmi	:101			;Nein, Setup starten.
			jmp	DoAutoSetup
::101			jmp	DoSetup

;*** Patches während Boot-Vorgang
;    in Kernal installieren.
:DoAutoSetup		jsr	IsSCPUaktiv
			bcc	:101
			jsr	DoInstall		;Patches installieren.
			jsr	InitForIO		;Neue Routinen testen.
			jsr	DoneWithIO
::101			jmp	EnterDeskTop		;Zum DeskTop zurück.

;*** Patches installieren.
:DoInstall		jsr	InstallNewRout
			jsr	DefPatchAdr
			bcs	:101
			rts

::101			jsr	SetNewBootVec
			jmp	SetNewIOvec

;******************************************************************************
;*** Neue Routinen die im freien RAM ab
;    $D200-$D2FF installiert werden und
;    für den korrekten Ablauf der I/O-
;    Routinen nötig sind!
:ld2a6			lda	$d0b8			;Aktuellen Takt einlesen.
:ld2a9			sta	$d07a			;Software-Speed 1Mhz.
:ld2ac			rts

:ld2ad			bmi	ld2b2			;War 20Mhz-Modus aktiv ?
:ld2af			sta	$d07b			;Ja, zurücksetzen.
:ld2b2			jmp	($9002)			;DoneWithIO ausführen.

:ld2b5			ldy	#$00			;Flag: GEOS-Optimieren.
:ld2b7			b $2c
:ld2b8			ldy	#$03			;Flag: GEOS nicht optimieren.

:ld2ba			php
:ld2bb			sei				;IRQ abschalten.
:ld2bc			sta	$d07e			;Hardware-Register einschalten.
:ld2bf			sta	$d074,y			;Optimierung setzen.
:ld2c2			sta	$d07f			;Hardware-Register ausschalten.
:ld2c5			plp				;IRQ zurücksetzen.
:ld2c6			rts

:ld2c7			lda	$dd0d			;Neue Reset-Routine.
:ld2ca			lda	#$ff			;Original-bereich ab Adresse
:ld2cc			sta	$dd04			;$9F85 bis $9FFF.
:ld2cf			sta	$dd05
:ld2d2			lda	#$81
:ld2d4			sta	$dd0d
:ld2d7			lda	#$01
:ld2d9			sta	$dd0e
:ld2dc			jsr	$d2f7
:ld2df			sta	$d07b			;Software-Speed 20Mhz.
:ld2e2			jmp	($a000)

:ld2e5			jsr	$d2f4			;GEOS-Optimierung ein.
:ld2e8			sta	$d07b			;Software-Speed 20 Mhz.
:ld2eb			jmp	ReBootGEOS		;GEOS neu starten.

:ld2ee			jmp	$d2a6			;Einsprung: InitForIO
:ld2f1			jmp	$d2ad			;Einsprung: DoneWithIO
:ld2f4			jmp	$d2b5			;GEOS-Optimierung ein.
:ld2f7			jmp	$d2b8			;GEOS-Optimierung aus.
:ld2fa			jmp	$d2c7			;Reset-Routine beenden.
:ld2fd			jmp	$d2e5			;GEOS neu starten.

;******************************************************************************
;*** Neue Routinen die im Kernal-RAM ab
;    $9F85-$9FFF installiert werden und
;    für den korrekten Ablauf der I/O-
;    Routinen nötig sind! Die genaue
;    Lage der Routinen wird von Install
;    zuvor berechnet!!!
:l9f97			b $00				;Zwischenspeicher für den
							;aktuellen Takt bevor Routine
							;":InitForIO" aufgerufen wurde.

:l9f98			jsr	$9fa2			;Standard ":InitForIO" starten.
:l9f9b			jsr	$d2ee			;Auf 1Mhz zurückschalten.
:l9f9e			sta	l9f97			;Aktuellen Takt merken.
:l9fa1			rts

:l9fa2			jmp	($9000)			;Zeiger auf ":InitForIO".

:l9fa5			bit	l9f97			;Speed-Flag testen.
:l9fa8			jmp	$d2f1			;":DoneWithIO" beenden.

;*** Neue Routinen im RAM ab Adresse
;    $D200-D2FF installieren.
:InstallNewRout		jsr	InitForIO
			jsr	CopyProgData
			jmp	DoneWithIO

:CopyProgData		php
			sei
			sta	$d07e			;Hardware-Register einschalten,
							;damit schreiben auf Bereich
							;$D200-$D2FF möglich wird!
			ldy	#$00
::101			lda	ld2a6,y			;Neue Routinen instllieren.
			sta	$d2a6,y
			iny
			cpy	#$5a
			bne	:101

			sta	$d07f			;Hardware-Register ausschalten.
			plp
			rts

;*** Neue ":InitForIO"/":DoneWithIO"-Routinen installieren.
:SetNewIOvec		php
			sei
			ldx	#$05
::101			lda	NewInitForIO,x
			sta	InitForIO,x
			dex
			bpl	:101
			plp
			rts

;*** Neue Einsprungadressen für die
;    Routinen ":InitForIO"/":DoneWithIO"
;    werden vom Programm berechnet!!!
:NewInitForIO		jmp	$9f98			;Neuer Einsprung: InitForIO.
:NewDoneWithIO		jmp	$9fa5			;Neuer Einsprung: DoneWithIO.

;*** Einsprungadressen berechnen.
:DefPatchAdr		jsr	FindVec1		;Kernal-Einsprung suchen.
			bcs	:102			;Gefunden ? Ja, weiter...
::101			clc
			rts

::102			jsr	FindVec2		;Kernal-Einsprung suchen.
			bcc	:101			;Nein, Abbruch...

			ldy	#$02			;Zeiger auf neue Reset-Routine
::103			lda	NewVecToReset,y		;im Bereich $D200-$D2FF
			sta	(r0L),y			;installieren.
			dey
			bpl	:103

;------------------------------------------------------------------------------
			clc				;Position für Zwischenspeicher
			lda	#$03			;des aktuellen Takts vor einem
			adc	r0L			;":InitForIO"-Aufruf berechnen
			sta	r0L			;und in die neue Routinen für
			bcc	:104			;IO-Aufrufe eintragen.
			inc	r0H

::104			lda	r0L
			sta	l9f9e +1
			sta	l9fa5 +1
			lda	r0H
			sta	l9f9e +2
			sta	l9fa5 +2
;------------------------------------------------------------------------------
			clc				;Zeiger auf Vektor-Einsprung
			lda	r0L			;"jmp ($9000)" in der neuen
			adc	#$0b			;Routine berechnen.
			sta	l9f98 +1
			lda	r0H
			adc	#$00
			sta	l9f98 +2
;------------------------------------------------------------------------------
			clc				;Zeiger auf neue ":InitForIO"
			lda	r0L			;Routine im Bereich $9F85 bis
			adc	#$01			;$9FFF berechnen.
			sta	NewInitForIO +1
			lda	r0H
			adc	#$00
			sta	NewInitForIO +2
;------------------------------------------------------------------------------
			clc				;Zeiger auf neue ":InitForIO"
			lda	r0L			;Routine im Bereich $9F85 bis
			adc	#$0e			;$9FFF berechnen.
			sta	NewDoneWithIO +1
			lda	r0H
			adc	#$00
			sta	NewDoneWithIO +2
;------------------------------------------------------------------------------

			ldy	#$00			;Neue Routinen in den
::105			lda	l9f97,y			;Bereich $9F85 bis $9FFF
			sta	(r0L),y			;kopieren.
			iny
			cpy	#$14
			bne	:105
			sec
			rts

;*** Zeiger auf neuen Bereich der
;    Reset-Routine.
:NewVecToReset		jmp	$d2fa

;*** Kernal-Einsprung "jmp ($a000)" im
;    Bereich $9D80-$9FFF suchen.
;    Ist das CARRY-Flag gesetzt, dann
;    zeigt ":r0" auf den Einsprung.
:FindVec1		lda	#>$9d7f
			sta	r0H
			lda	#<$9d7f
			sta	r0L

::101			ldy	#$00
			inc	r0L
			bne	:102
			inc	r0H
			lda	r0H
			cmp	#$a0
			bne	:102
			clc				;Nicht gefunden.
			rts

::102			lda	(r0L),y
			cmp	#$6c
			bne	:101
			iny
			lda	(r0L),y
			cmp	#$00
			bne	:101
			iny
			lda	(r0L),y
			cmp	#$a0
			bne	:101
			sec				;Gefunden.
			rts

;*** Position für neue Reset-Routine
;    im Bereich $9F85 bis $9FFF suchen.
:FindVec2		ldx	#$24
::101			ldy	#$00
			sec
			lda	r0L
			sbc	#$01
			sta	r0L
			bcs	:102
			dec	r0H
::102			dex
			bne	:103
			clc
			rts

::103			lda	(r0L),y
			cmp	#$ad
			bne	:101
			iny
			lda	(r0L),y
			cmp	#$0d
			bne	:101
			iny
			lda	(r0L),y
			cmp	#$dd
			bne	:101
			sec
			rts

;*** Zeiger auf neue ReBoot-Routine richten.
:SetNewBootVec		ldy	#$02
::101			lda	NewBootVec,y
			sta	SystemReBoot,y
			dey
			bpl	:101
			rts

:NewBootVec		jmp	$d2fd

;*** SuperCPU suchen.
:IsSCPUaktiv		jsr	InitForIO		;I/O aktivieren.
			bit	$d0bc			;SCPU vorhanden/aktiv ?
			bmi	:101			;Nein, Ende...

			sta	$d07e			;Hardware-Register einschalten.
			sta	$d074			;GEOS-Optimierung ein.
			sta	$d07f			;Hardware-Register ausschalten.
			sta	$d07b			;Software-Speed 20Mhz.
			jsr	DoneWithIO		;I/O zurücksetzen.
			sec				;SCPU aktiviert.
			rts

::101			jsr	DoneWithIO		;I/O zurücksetzen.
			clc				;Keine SCPU gefunden.
			rts

;*** SuperCPU-Setup.
:DoSetup		jsr	InitForIO		;I/O aktivieren.
			lda	extclr			;Rahmenfarbe merken.
			sta	Sv_BackClr
			lda	#$00			;Rahmenfarbe = schwarz.
			sta	extclr
			jsr	DoneWithIO		;I/O zurücksetzen.

			lda	screencolors		;Bildschirmfarben merken.
			sta	SetScreenCol

			jsr	ClrScreen		;Bildschirm löschen.

			jsr	i_BitmapUp		;SuperCPU-Grafik anzeigen.
			w Icon_SCPU
			b $05,$40,$1d,$38

			jsr	i_BitmapUp		;legende anzeigen.
			w Icon_Info
			b $0e,$88,$0b,$28

			lda	#$00			;Vorbelegung falls keine
			sta	Icon_Def1 +0		;SCPU aktiv ist =>
			sta	Icon_Def1 +1		;Icon-Abfrage wird unter-
			sta	Icon_Def2 +0		;bunden, der Speed/Optimize
			sta	Icon_Def2 +1		;Schalter sind inaktiv.

			lda	#$00			;Kein Icon-blinken.
			sta	iconSelFlag

			lda	#>Icon_Tab		;Icons aktivieren.
			sta	r0H
			lda	#<Icon_Tab
			sta	r0L
			jsr	DoIcons

			jsr	SetScrnGrafx		;Bildschirm aufbauen.

			ldx	#$00			;Zeiger auf Beginn der
			stx	ColTabVec		;Farbtabelle.

::101			lda	ColTop,x		;Daten für Farbbereich
			sta	r2L			;einlesen.
			lda	ColBottom,x
			sta	r2H
			lda	ColLeft,x
			sta	r3L
			lda	ColRight,x
			sta	r4L
			lda	ColData,x
			sta	r4H

			jsr	ColorBox		;Farbe setzen.

			inc	ColTabVec
			ldx	ColTabVec
			cpx	#$08			;Alle Farben gesetzt ?
			bne	:101			;Nein, weiter...

			jsr	ColSpeedLED

			lda	#>TestSwitches
			sta	appMain+1
			lda	#<TestSwitches
			sta	appMain+0
			rts

;*** Zwischenspeicher.
:SetScreenCol		b $00
:Sv_BackClr		b $00

;*** Farbdaten für Bildaufbau.
:ColTabVec		b $00				;Zeiger auf Farbtabelle.

:ColTop			b $00,$08,$0b,$0c		;Obere Grenze für
			b $09,$09,$14,$11		;Farbbereich.

:ColBottom		b $18,$0a,$0b,$0e		;Untere Grenze für
			b $0a,$0a,$15,$15		;Farbbereich.

:ColLeft		b $00,$05,$05,$05		;Linke Grenze für
			b $06,$0d,$1e,$0e		;Farbbereich.

:ColRight		b $27,$21,$21,$21		;Rechte Grenze für
			b $0b,$20,$24,$18		;Farbbereich.

:ColData		b $3f,$31,$c1,$b1		;Farbwert für
			b $21,$e1,$b1,$0f		;Farbbereich.

;*** Switch-Änderungen erkennen.
:TestSwitches		lda	JiffySpeed		;JiffyDOS-Status merken.
			sta	CurJiffySpd
			jsr	GetInfoSCPU		;SuperCPU-Daten einlesen.
			lda	CurJiffySpd
			eor	JiffySpeed		;JiffyDOS-Status verändert ?
			bpl	:101			;Nein, weiter...
			jsr	TestJiffyDOS		;JiffyDOS-Status anzeigen.

::101			lda	CurJiffySpd
			eor	JiffySpeed		;Aktuellen Takt ermitteln.
			and	#%01000000		;Wurde Takt geändert ?
			beq	:103			;Nein, weiter...

			php
			sei

			lda	CPU_DATA		;CPU_Register merken.
			pha
			lda	#$35			;I/O aktivieren.
			sta	CPU_DATA

			ldy	#$00			;Vorgabe 1Mhz-Modus.
			bit	JiffySpeed		;1Mhz-Modus aktiv ?
			bvs	:102			;Ja, weiter...
			iny				;Auf 20Mhz umschalten.
::102			sta	$d07a,y			;Neuen Takt setzen.

			pla
			sta	CPU_DATA		;I/O zurücksetzen.

			plp
			jsr	GetInfoSCPU		;SuperCPU-Daten einlesen.
			jsr	TestCurSpeed		;Aktuellen Takt anzeigen.

::103			rts

:CurJiffySpd		b $00				;Zwischenspeicher.

;*** Bildschirm aufbauen.
:SetScrnGrafx		jsr	GetInfoSCPU		;SuperCPU-Daten einlesen.
			bit	ConnectSCPU		;CPU angeschlossen/aktiv ?
			bpl	:101			;Nein, weiter...

			jsr	i_BitmapUp
			w Icon_Inaktiv
			b $06,$68,$03,$08

			jsr	i_BitmapUp
			w Icon_Aktiv
			b $0a,$68,$03,$08

			jsr	i_BitmapUp
			w Icon_Aktiv
			b $0e,$68,$03,$08

			jsr	i_BitmapUp
			w Icon_Aktiv
			b $1c,$68,$03,$08

			rts

::101			jsr	i_BitmapUp
			w Icon_Aktiv
			b $06,$68,$03,$08

			jsr	TestJiffyDOS		;JiffyDOS anzeigen.
			jsr	TestCurSpeed		;Aktuellen Takt anzeigen.
			jsr	TestOptimize

			lda	#$10
			sta	Icon_Def1 +1
			sta	Icon_Def2 +1
			rts

;*** Auf JiffyDOS testen.
:TestJiffyDOS		ldx	#$00
			bit	JiffySpeed
			bmi	:101
			inx
::101			jmp	PrintSwitch

;*** SuperCPU-Daten einlesen.
:GetInfoSCPU		php
			sei

			lda	CPU_DATA		;CPU_Register merken.
			pha
			lda	#$35			;I/O aktivieren.
			sta	CPU_DATA

			lda	$d0bc
			sta	ConnectSCPU
			lda	$d0b5
			sta	JiffySpeed
			lda	$d0b8
			sta	SpeedSlct
			lda	$d0b4
			sta	OptimizeGEOS

			pla
			sta	CPU_DATA		;I/O zurücksetzen.

			plp
			rts

;*** Auf aktuelle Taktfrequenz testen.
:TestCurSpeed		ldx	#$03
			bit	SpeedSlct
			bmi	:101
			dex
::101			jsr	PrintSwitch

;*** Farbe für LED = Taktfrequenz.
:ColSpeedLED		lda	#$0d
			sta	r2L
			lda	#$0d
			sta	r2H
			lda	#$13
			sta	r3L
			lda	#$13
			sta	r4L
			lda	#$a1			; -> 20 Mhz.
			sta	r4H
			bit	SpeedSlct
			bpl	:101
			lda	#$b1			; ->  1 Mhz.
			sta	r4H
::101			jmp	ColorBox

;*** Optimierungsmodus anzeigen.
:TestOptimize		ldx	#$05
			lda	OptimizeGEOS
			and	#%11000000
			bne	:101
			dex
::101			jmp	PrintSwitch

;*** daten für Switch-Zuständen.
:SwitchModeL		b < Icon_Aktiv, < Icon_Inaktiv
			b < Icon_Aktiv, < Icon_Inaktiv
			b < Icon_Aktiv, < Icon_Inaktiv

:SwitchModeH		b > Icon_Aktiv, > Icon_Inaktiv
			b > Icon_Aktiv, > Icon_Inaktiv
			b > Icon_Aktiv, > Icon_Inaktiv

:SwitchXpos		b $0a,$0a
			b $0e,$0e
			b $1c,$1c

;*** Zwischenspeicher SCPU-Daten.
:ConnectSCPU		b $00
:OptimizeGEOS		b $00
:JiffySpeed		b $00
:SpeedSlct		b $00

;*** Icon für Schalter ausgeben.
;    xReg = $00,$01 SCPU     ein/aus
;           $02,$03 JiffyDOS ein/aus
;           $04,$05 Speed    20 /1Mhz
:PrintSwitch		lda	SwitchModeL,x
			sta	r0L
			lda	SwitchModeH,x
			sta	r0H
			lda	SwitchXpos,x
			sta	r1L
			lda	#$68
			sta	r1H
			lda	#$03
			sta	r2L
			lda	#$08
			sta	r2H
			jmp	BitmapUp

;*** Setup beenden.
:ExitToDeskTop		lda	#$00			;Vektor auf Switch-Abfrage
			sta	appMain+1		;wieder löschen.
			lda	#$00
			sta	appMain+0

			jsr	ClrScreen		;Bildschirm löschen.

			jsr	InitForIO		;I/O aktivieren.
			lda	Sv_BackClr		;Rahmenfarbe zurücksetzen.
			sta	extclr
			jsr	DoneWithIO		;I/O abschalten.

			lda	SetScreenCol		;Bildschirmfarbe
			sta	screencolors		;zurücksetzen.

			lda	#$00			;Farb-RAM löschen.
			sta	r2L
			lda	#$18
			sta	r2H
			lda	#$00
			sta	r3L
			lda	#$27
			sta	r4L
			lda	screencolors
			sta	r4H
			jsr	ColorBox

			jmp	EnterDeskTop		;Zum DeskTop.

;*** Switch: CPU-Speed.
:SetSpeed		bit	mouseData
			bpl	SetSpeed

			php
			sei

			lda	CPU_DATA		;CPU_Register merken.
			pha
			lda	#$35			;I/O aktivieren.
			sta	CPU_DATA

			ldy	#$00			;Vorgabe: 1Mhz-Takt.
			bit	$d0b8			;Aktuellen Takt testen.
			bpl	:101			;20Mhz aktiv ? Ja, weiter...
			iny				;Nein, auf 20Mhz umschalten.
::101			sta	$d07a,y			;Neuen Takt setzen.
			pla
			sta	CPU_DATA		;I/O zurücksetzen.
			plp
			jsr	GetInfoSCPU		;SuperCPU-Daten einlesen.
			jmp	TestCurSpeed		;Aktuellen Takt anzeigen.

;*** Switch: Optimize GEOS.
:SetOptimize		bit	mouseData
			bpl	SetOptimize

			php
			sei

			lda	CPU_DATA		;CPU_Register merken.
			pha
			lda	#$35			;I/O aktivieren.
			sta	CPU_DATA

			sta	$d07e			;Hardware-Register aktivieren.

			lda	OptimizeGEOS
			and	#%11000000		;GEOS-Optimierung aktiv ?
			beq	:101			;Ja, weiter...

			ldy	#$00			;GEOS-Optimierung ein.
			b	$2c
::101			ldy	#$03			;GEOS-Optimierung aus.
			sta	$d074,y			;Neuen Optimize-Modus setzen.

			sta	$d07f			;Hardware-Register abschalten.

			pla
			sta	CPU_DATA		;I/O zurücksetzen.

			plp

			jsr	GetInfoSCPU		;SuperCPU-Daten einlesen.
			jmp	TestOptimize		;Optimierung anzeigen.

;*** Icon-Tabelle
:Icon_Tab		b $03
			w $00a0
			b $64

:Icon_Def1		w Icon_Aktiv
			b $0e,$68,$03,$08
			w SetSpeed

:Icon_Def2		w Icon_Aktiv
			b $1c,$68,$03,$08
			w SetOptimize

			w Icon_EXIT
			b $1e,$a0,$07,$10
			w ExitToDeskTop

;*** Bildschirm löschen.
:ClrScreen		lda	#$00
			sta	r2L
			lda	#$18
			sta	r2H
			lda	#$00
			sta	r3L
			lda	#$27
			sta	r4L
			lda	#$33
			sta	r4H
			jsr	ColorBox

			lda	#$02
			jsr	SetPattern

			jsr	i_Rectangle
			b $00,$c7,$00,$00
			b $3f,$01
			rts

;*** Grafiken für Setup-Routine.
:Icon_EXIT                <MISSING_IMAGE_DATA>

:Icon_SCPU
<MISSING_IMAGE_DATA>

:Icon_Aktiv
<MISSING_IMAGE_DATA>

:Icon_Inaktiv

<MISSING_IMAGE_DATA>

:Icon_Info
<MISSING_IMAGE_DATA>

;*** Farbe zeichnen.
;    r2L = Erste Zeile
;    r2H = Letzte Zeile
;    r3L = Erste Spalte
;    r4L = Letzte Spalte
;    r4H = Farbwert
:ColorBox		php				;IRQ abschalten.
			sei

			lda	r2L			;Nr. der ersten Zeile als
			sta	r6L			;Startwert für Zähler.

			clc				;Zeiger auf Farb-RAM
			lda	r3L			;berechnen.
			adc	#<COLOR_MATRIX
			sta	r5L
			lda	#>COLOR_MATRIX
			adc	#$00
			sta	r5H

			ldx	r2L			;Start in erster Zeile ?
			beq	:103			;Ja, weiter...

::101			clc				;Zeiger auf Zeile in
			lda	#$28			;Farb-RAM berechnen.
			adc	r5L
			sta	r5L
			bcc	:102
			inc	r5H

::102			dex				;Zeile erreicht ?
			bne	:101			;Nein, weiter...

::103			ldy	#$00
			ldx	r3L
			lda	r4H
::104			sta	(r5L),y			;Farbe setzen.
			iny
			inx
			cpx	r4L			;Ende erreicht ?
			beq	:104			;Nein, weiter...
			bcc	:104

			clc				;Zeiger auf nächste Zeile.
			lda	#$28
			adc	r5L
			sta	r5L
			bcc	:105
			inc	r5H

::105			inc	r6L

			lda	r2H
			cmp	r6L			;Ende erreicht ?
			bcs	:103			;Nein, weiter...

			plp				;IRQ zurücksetzen.
			rts
