; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Variablen definieren.
:OptBase		= UsedGWFont

:Opt_Datum		= CopyOptions + 0
:Opt_OverWrite		= CopyOptions + 1

:DOS_CBMType		= OptDOStoCBM + 0
:DOS_LfCode		= OptDOStoCBM + 1
:DOS_FfCode		= OptDOStoGW  + 0
:DOS_GW_Ver		= OptDOStoGW  + 1
:DOS_GW_1Page		= OptDOStoGW  + 2
:DOS_GW_PLen		= OptDOStoGW  + 4
:DOS_GW_Frmt		= OptGW_Format+ 0

:CBM_DOSName		= OptCBMtoDOS + 0
:CBM_LfCode		= OptCBMtoDOS + 1
:CBM_ZielDir		= OptCBMtoDOS + 2
:CBM_ZielDirCl		= OptCBMtoDOS + 3
:CBM_FfCode		= OptGWtoDOS  + 0

:GW_LRand		= OptGW_Rand  + 0
:GW_RRand		= OptGW_Rand  + 2
:GW_TabBase		= OptGW_Tab   + 0
:GW_Absatz		= OptGW_Tab   +16
:GW_Format		= OptGW_Format+ 0
:GW_Font		= OptGW_Font  + 0

;*** Farben für Options-Box setzen.
:SetOptions		stx	OptionMode		;Rückkehr-Option merken.

			MoveW	keyVector,V200a1
			ClrB	V200a0
			jsr	L900a0			;Linken Rand bestimmen.
			jsr	GetPrnDim		;Seiten-Länge berechnen.
			jsr	ChkPageSize

;*** Rücksprung in Font/Druckerwahl.
			ldx	OptionMode		;Rückkehr aus Drucker/Font-Wahl ?
			beq	SetOpt_a		;Nein, Normal starten.
			rts				;Zurück zur Drucker-/Font-Auswahl.

;*** Parameter-Fenster zeichnen.
:SetOpt_a		Display	ST_WR_FORE ! ST_WR_BACK
			Window	40,175,16,191

;*** Parameter-Texte ausgeben.
			lda	V200a0			;Notitzblock beschriften.
			jsr	PutWinText

;*** Parameter eingeben.
:SetOpt_b		Display	ST_WR_FORE
			LoadW	otherPressVec,ChkOptSlct
			LoadW	r0,icon_Tab1
			jmp	DoIcons			;Icons aktivieren.

;*** Standwart-Werte schreiben.
:StandardOpt		ldy	#$43
::1			lda	V200c2,y		;Standard-Werte in
			sta	OptBase,y		;Zwischenspeicher übertragen.
			dey
			bpl	:1

			jsr	L900a0			;Seitenformat bestimmen.

			lda	V200a0			;Seite neu aufbauen.
			jmp	PutWinText

;*** Zurück zu geoDOS
:L200ExitGD		lda	#$00			;GEOS-Vektoren zurücksetzen.
			sta	otherPressVec+0
			sta	otherPressVec+1
			lda	V200a1   +0
			sta	keyVector+0
			lda	V200a1   +1
			sta	keyVector+1
			jmp	InitScreen		;Ende...

;*** Seitenformat bestimmen.
:L900a0			lda	#$60			;Linker Rand für V2.0-Texte.
			ldx	DOS_GW_Ver
			beq	:1
			lda	#$10			;Linker Rand für V2.0-Texte.
::1			sta	V200a4+0		;Werte für linken Rand speichern.
			ClrB	V200a4+1
			rts

;*** Startadresse Daten-Liste nach ":a9".
:L900b0			lda	V200a0			;Aktuelle Menüseite ermitteln.
			asl
			tax
			lda	V200k0+0,x		;Startadresse für Daten-Liste nach
			sta	a9L			;":a9" kopieren.
			lda	V200k0+1,x
			sta	a9H
			rts

;*** Werte aus Daten-Liste nach ":r2" für GEOS-Grafik-Routinen.
:L900c0			ldy	#$05
::1			lda	(a9L),y
			sta	r2,y
			dey
			bpl	:1
			rts

;*** Bildschirm löschen.
:L900d0			SetColRam34,5*40+3,$b1
			Display	ST_WR_FORE ! ST_WR_BACK
			Pattern	2
			FillRec	8,191,0,319
			rts

;*** Routine in ":a9" + yReg aufrufen.
:L900e0			lda	(a9L),y			;Low -Byte der aufzurufenden Routine
			pha				;einlesen.
			iny
			lda	(a9L),y			;High-Byte der aufzurufenden Routine
			tax				;einlesen.
			pla
			jmp	CallRoutine		;Routine aufrufen.

;*** Options-Icon-Fläache füllen.
:L900f0			jsr	SetPattern		;Muster setzen.
			jmp	Rectangle		;Ausgefülltes Rechteck zeichnen.

;*** Zahlenwert ausgeben.
:L900g0			sta	r0L			;Zahlenwert nach ":r0".
			stx	r0H
			tya				;Startadresse Daten-Liste berechnen.
			asl
			tax
			lda	V200o0+0,x
			sta	a8L
			lda	V200o0+1,x
			sta	a8H

			ldy	#$00
			lda	(a8L),y			;X-Koordinate für Zahlenausgabe.
			pha
			iny
			lda	(a8L),y
			pha
			iny
			lda	(a8L),y			;Y-Koordinate für Zahlenausgabe.
			pha
			iny
			lda	(a8L),y			;Einsprungs-Adresse für Zahlenausgabe.
			sta	a7L
			iny
			lda	(a8L),y
			sta	a7H

			pla				;Register belegen.
			tay
			pla
			tax
			pla
			jmp	(a7)			;Zahl ausgeben.

;*** Seite wechseln.
:ChangePage		sec				;Y-Koordinate der Maus einlesen.
			lda	mouseYPos		;Testen ob Maus innerhalb des
			sbc	#160			;"Eselsohrs" angeklickt wurde.
			bcs	:2
::1			rts				;Nein, Rücksprung.

::2			tay
			sec
			lda	mouseXPos+0
			sbc	#176
			tax
			lda	mouseXPos+1
			sbc	#0
			bne	:1
			cpx	#16			;Ist Maus innerhalb des "Eselsohrs" ?
			bcs	:1			;Nein, Rücksprung.
			cpy	#16
			bcs	:1
			sty	r0L
			txa				;Feststellen: Seite vor/zurück ?
			eor	#%00001111
			cmp	r0L
			bcs	GotoNextPage		;Seite vor.
			bcc	GotoLastPage		;Seite zurück.

;*** Weiter auf nächste Seite.
:GotoNextPage		ldx	V200a0
			inx
			cpx	#$08
			bne	:1
			ldx	#$00
::1			jmp	GotoNewPage

;*** Zurück zur letzten Seite.
:GotoLastPage		ldx	V200a0
			dex
			cpx	#$ff
			bne	GotoNewPage
			ldx	#$07
:GotoNewPage		stx	V200a0
			txa
			jmp	PutWinText

;*** Option-Icon gewählt
:OptIconSlct		lda	r0L
			sub	10

;*** Inhalt des Windows ausgeben.
:PutWinText		sta	V200a0			;Neue Parameter-Seite merken.

			Display	ST_WR_FORE ! ST_WR_BACK
			Pattern	0
			FillRec	48,159,17,190
			Pattern	1
			FillRec	40,47,24,191

			jsr	UseGDFont		;geoDOS-Font aktivieren.
			lda	V200a0			;Titel-Überschrift ausgeben.
			asl
			pha
			tax
			lda	V200d0+0,x
			sta	r0L
			lda	V200d0+1,x
			sta	r0H
			LoadB	currentMode,SET_REVERSE
			LoadW	r11,32
			LoadB	r1H,46
			jsr	PutString
			jsr	UseSystemFont		;GEOS-Font aktivieren.
			pla
			tax
			lda	V200i0+0,x		;Fenster-Texte ausgeben.
			sta	r0L
			lda	V200i0+1,x
			sta	r0H
			jsr	PutString

;*** Klick-Positionen anzeigen.
:SetClkPos		jsr	L900b0			;Startadresse Daten-Liste ermitteln.

::1			ldy	#$00
			lda	(a9L),y			;Ende der Daten-Liste erreicht ?
			bne	:2			;Nein, weiter.
			rts				;Ende.

::2			jsr	L900c0			;Werte aus Daten-Liste nach ":r2".
			IncWord	r3			;Grenzen des Rechtecks -1.
			SubVW	1,r4
			inc	r2L
			dec	r2H

			ldy	#$07			;Inhalt des Options-Icons
			lda	(a9L),y			;definieren.
			tax
			dey
			lda	(a9L),y
			ldy	#$00
			jsr	CallRoutine
			tya
			bmi	:3

			jsr	L900f0			;Falls "Klick-Option",
							;Rechteck mit Muster füllen.

::3			jsr	L900c0			;Werte aus Daten-Liste nach ":r2".
			lda	r2H			;Falls Wert für "Y-unten" = NULL, kein
			beq	:4			;Rechteck zeichnen.

			lda	#%11111111		;Rahmen um Options-Icon zeichnen.
			jsr	FrameRectangle

::4			AddVBW	10,a9			;Zeiger auf nächsten Wert in Liste.
			jmp	:1

;*** Prüfen ob Option angeklickt.
:ChkOptSlct		jsr	L900b0			;Startadresse Daten-Liste ermitteln.

::1			ldy	#$00
			lda	(a9L),y			;Ende der Daten-Liste erreicht ?
			bne	:2			;Nein, weiter.
			rts				;Ende.

::2			jsr	L900c0			;Werte aus Daten-Liste nach ":r2".
			jsr	IsMseInRegion		;Ist Maus innerhalb eines Options-
			tax				;Icons ?
			beq	:3			;Nein, weitertesten.

			ldy	#$08
			jsr	L900e0			;Routine aus Daten-Liste aufrufen.
			jsr	SetClkPos		;Neuen Wert für Option anzeigen.
			cli
			NoMseKey			;Warten bis keine Maustaste gedrückt.
			rts				;Ende.

::3			AddVBW	10,a9
			jmp	:1

;*** Optionen anzeigen.
:DefOpt1a		LoadB	r1H,69			;Übersetzungstabelle DOS - C64.
			lda	#<CTabDOStoCBM
			ldx	#>CTabDOStoCBM
			ldy	CTabDOStoCBM
			jsr	DefOpt1_a

			LoadB	r1H,98			;Übersetzungstabelle C64 - DOS.
			lda	#<CTabCBMtoDOS
			ldx	#>CTabCBMtoDOS
			ldy	CTabCBMtoDOS
			jsr	DefOpt1_a

			PrintXY	32,127,PrntFileName
			PrintXY	32,156,UsedGWFont

			LoadW	r11,124			;Punktgröße ausgeben.
			LoadB	r1H,146
			lda	UsedPointSize
			sta	r0L
			ClrB	r0H
			lda	#%11000000
			jsr	PutDecimal

			PrintStrgV200g0

			ldy	#$ff			;Keinen Rahmen zeichnen.
			rts

;*** Übersetzungstabelle ausgeben.
:DefOpt1_a		cpy	#$00
			bne	:1
			lda	#<V200g1
			ldx	#>V200g1
::1			sta	r0L
			stx	r0H
			LoadW	r11,32
			jmp	PutString

;*** "Ziel-Datei"
:DefOpt2a		ldx	Opt_Datum		;Datum von Original-Datei.
			bne	:1
			ldy	#$02
::1			rts

:DefOpt2b		ldx	Opt_Datum		;Datum von GEOS.
			beq	:1
			ldy	#$02
::1			rts

:DefOpt2c		ldx	Opt_OverWrite		;Dateien löschen.
			bne	:1
			ldy	#$02
::1			rts

:DefOpt2d		ldx	Opt_OverWrite		;Dateien übergehen.
			cpx	#$7f
			bne	:1
			ldy	#$02
::1			rts

:DefOpt2e		ldx	Opt_OverWrite		;Abfrage.
			bpl	:1
			ldy	#$02
::1			rts

;*** "DOS nach CBM"
:DefOpt3a		ldx	DOS_LfCode		;Linefeed.
			beq	:1
			ldy	#$02
::1			rts

:DefOpt3b		ldx	DOS_CBMType		;Datei-Typ = SEQ.
			cpx	#$81
			bne	:1
			ldy	#$02
::1			rts

:DefOpt3c		ldx	DOS_CBMType		;Datei-Typ = PRG.
			cpx	#$82
			bne	:1
			ldy	#$02
::1			rts

:DefOpt3d		ldx	DOS_CBMType		;Datei-Typ = USR.
			cpx	#$83
			bne	:1
			ldy	#$02
::1			rts

;*** "CBM nach DOS"
:DefOpt4a		ldx	CBM_LfCode		;LF ignorieren.
			beq	:1
			ldy	#$02
::1			rts

:DefOpt4b		ldx	CBM_DOSName		;MSDOS-Namen vorschlagen.
			bne	:1
			ldy	#$02
::1			rts

:DefOpt4c		ldx	CBM_DOSName		;Alle MSDOS-Namen neu eingeben.
			beq	:1
			ldy	#$02
::1			rts

;*** "DOS nach geoWrite"
:DefOpt5a		ldx	DOS_GW_Ver		;geoWrite V2.0.
			bne	:1
			ldy	#$02
::1			rts

:DefOpt5b		ldx	DOS_GW_Ver		;geoWrite V2.1.
			beq	:1
			ldy	#$02
::1			rts

:DefOpt5c		lda	DOS_GW_1Page+0		;Erste Seiten-Nummer.
			ldx	DOS_GW_1Page+1
			ldy	#$00
			jmp	L900g0

:DefOpt5d		lda	DOS_GW_Frmt		;Text neu formatieren.
			and	#%00010000
			bne	:1
			ldy	#$02
::1			rts

:DefOpt5e		ldx	DOS_FfCode		;Seitenvorschub übernehmen.
			beq	:1
			ldy	#$02
::1			rts

:DefOpt5f		ldx	DOS_FfCode		;Anzahl Zeilen pro Seite #1.
			bne	:1
			ldy	#$02
::1			rts

:DefOpt5g		lda	LinesPerPage		;Anzahl Zeilen pro Seite #2.
			ldx	#$00
			ldy	#$01
			jmp	L900g0

;*** "geoWrite nach DOS".
:DefOpt6a		ldx	CBM_FfCode		;Seitenvorschub ignorieren.
			beq	:1
			ldy	#$02
::1			rts

;*** Tabulatoren anzeigen.
:DefOpt7a		lda	GW_LRand+0		;Linker Rand.
			ldx	GW_LRand+1
			ldy	#$02
			jmp	L900g0

:DefOpt7b		jsr	TestTabPos		;Tabulatoren testen.
			lda	GW_RRand+0		;Rechter Rand.
			ldx	GW_RRand+1
			ldy	#$03
			jmp	L900g0

:DefOpt7c		lda	GW_Absatz+0		;Absatz-Tabulator.
			ldx	GW_Absatz+1
			ldy	#$04
			jmp	L900g0

:DefOpt7d		ldx	#$01			;Dezimal-Tabulator #1.
			b $2c
:DefOpt7f		ldx	#$03			;Dezimal-Tabulator #2.
			b $2c
:DefOpt7h		ldx	#$05			;Dezimal-Tabulator #3.
			b $2c
:DefOpt7j		ldx	#$07			;Dezimal-Tabulator #4.
			b $2c
:DefOpt7l		ldx	#$09			;Dezimal-Tabulator #5.
			b $2c
:DefOpt7n		ldx	#$0b			;Dezimal-Tabulator #6.
			b $2c
:DefOpt7p		ldx	#$0d			;Dezimal-Tabulator #7.
			b $2c
:DefOpt7r		ldx	#$0f			;Dezimal-Tabulator #8.

			lda	GW_TabBase,x
			bpl	:1
			ldy	#$02
::1			rts

:DefOpt7e		ldy	#$00			;Tabulator-Position #1.
			b $2c
:DefOpt7g		ldy	#$02			;Tabulator-Position #2.
			b $2c
:DefOpt7i		ldy	#$04			;Tabulator-Position #3.
			b $2c
:DefOpt7k		ldy	#$06			;Tabulator-Position #4.
			b $2c
:DefOpt7m		ldy	#$08			;Tabulator-Position #5.
			b $2c
:DefOpt7o		ldy	#$0a			;Tabulator-Position #6.
			b $2c
:DefOpt7q		ldy	#$0c			;Tabulator-Position #7.
			b $2c
:DefOpt7s		ldy	#$0e			;Tabulator-Position #8.

			lda	GW_TabBase+0,y
			pha
			lda	GW_TabBase+1,y
			tax
			tya
			lsr
			add	5
			tay
			pla
			jmp	L900g0

;*** "Dateien verbinden".
:DefOpt8a		ldx	LinkFiles
			beq	:1
			ldy	#$02
::1			rts

:DefOpt8b		lda	LinkFiles
			and	#%00100000
			beq	:1
			ldy	#$02
::1			rts

:DefOpt8c		lda	LinkFiles
			and	#%01000000
			beq	:1
			ldy	#$02
::1			rts

:DefOpt8d		lda	LinkFiles
			and	#%10000000
			beq	:1
			ldy	#$02
::1			rts

;*** Eingegebene Zahlen-Werte überprüfen.
:ChkInput_a		clc				;Nr. der ersten Seite 0-999.
			rts

:ChkInput_b		lda	r0H			;Max. Anzahl Zeilen/Seite 0-255.
			bne	:1
			clc
			rts
::1			sec
			rts

:ChkInput_c		lda	DOS_GW_Ver		;Absatz-Tabulator / Linker Rand.
			bne	:1
			CmpWI	r0,393
			bcc	:2
			rts
::1			CmpWI	r0,553
			bcc	:2
			rts
::2			CmpW	r0,GW_RRand
			rts

:ChkInput_d		CmpWI	r0,80			;Rechter Rand.
			bcs	:1
			sec
			rts
::1			lda	DOS_GW_Ver
			bne	:2
			CmpWI	r0,480
			beq	:3
			bcc	:4
			rts
::2			CmpWI	r0,640
			beq	:3
			bcc	:4
			rts
::3			SubVW	1,r0
			clc
			rts
::4			CmpW	GW_LRand,r0
			rts

:ChkInput_e		CmpW	r0,GW_LRand		;Tabulator #1 - #8.
			bcs	:1
			sec
			rts
::1			CmpW	r0,GW_RRand
			bcc	:2
			MoveW	GW_RRand,r0
			clc
::2			rts

;*** "Ziel-Datei"
:SetOpt2a		lda	#$00			;Datum aus Ziel-Datei.
			b $2c
:SetOpt2b		lda	#$ff			;Datum von GEOS.
			sta	Opt_Datum
			rts

:SetOpt2c		lda	#$00			;Dateien löschen.
			b $2c
:SetOpt2d		lda	#$7f			;Dateien übergehen.
			b $2c
:SetOpt2e		lda	#$ff			;Abfrage.
			sta	Opt_OverWrite
			rts

;*** "DOS nach CBM"
:SetOpt3a		lda	DOS_LfCode		;Linefeed.
			eor	#$ff
			sta	DOS_LfCode
			rts

:SetOpt3b		lda	#$81			;Datei-Typ = SEQ.
			b $2c
:SetOpt3c		lda	#$82			;Datei-Typ = PRG.
			b $2c
:SetOpt3d		lda	#$83			;Datei-Typ = USR.
			sta	DOS_CBMType
			rts

;*** "CBM nach DOS"
:SetOpt4a		lda	CBM_LfCode		;Linefeed.
			eor	#$ff
			sta	CBM_LfCode
			rts

:SetOpt4b		lda	#$00			;Namen vorschlagen.
			b $2c
:SetOpt4c		lda	#$ff			;Namen neu eingeben.
			sta	CBM_DOSName
			rts

;*** "DOS nach geoWrite"
:SetOpt5a		lda	#<V200c0		;geoWrite V2.0
			ldx	#>V200c0
			ldy	#$00
			jmp	SetOpt5

:SetOpt5b		lda	#<V200c1		;geoWrite V2.1
			ldx	#>V200c1
			ldy	#$01

:SetOpt5		sta	r0L			;geoWrite-Version festlegen.
			stx	r0H
			sty	DOS_GW_Ver
			jsr	L900a0			;Linken Rand bestimmen.

			ldy	#21
::1			lda	(r0L),y
			sta	GW_LRand,y
			dey
			bpl	:1
			rts

:SetOpt5c		lda	#$00			;Erste Seiten-Nummer.
			jmp	SetInpOpt

:SetOpt5d		lda	DOS_GW_Frmt		;Text neu formatieren.
			eor	#%00010000
			sta	DOS_GW_Frmt
			rts

:SetOpt5e		lda	#$ff			;Seitenvorschub übernehmen.
			b $2c
:SetOpt5f		lda	#$00			;Seitenvorschub ignorieren.
			sta	DOS_FfCode
			rts

:SetOpt5g		lda	#$01			;Anzahl Zeilen pro Seite.
			jmp	SetInpOpt

;*** "geoWrite nach DOS"
:SetOpt6a		lda	CBM_FfCode		;Linefeed.
			eor	#$ff
			sta	CBM_FfCode
			rts

;*** Options-Werte definieren.
:SetOpt7a		ldx	#$01			;Dezimal-Tabulator #1.
			b $2c
:SetOpt7b		ldx	#$03			;Dezimal-Tabulator #2.
			b $2c
:SetOpt7c		ldx	#$05			;Dezimal-Tabulator #3.
			b $2c
:SetOpt7d		ldx	#$07			;Dezimal-Tabulator #4.
			b $2c
:SetOpt7e		ldx	#$09			;Dezimal-Tabulator #5.
			b $2c
:SetOpt7f		ldx	#$0b			;Dezimal-Tabulator #6.
			b $2c
:SetOpt7g		ldx	#$0d			;Dezimal-Tabulator #7.
			b $2c
:SetOpt7h		ldx	#$0f			;Dezimal-Tabulator #8.

			lda	GW_TabBase,x
			eor	#%10000000
			sta	GW_TabBase,x
			rts

:SetOpt7i		lda	#$02			;Tabulator-Position #1.
			b $2c
:SetOpt7j		lda	#$03			;Tabulator-Position #2.
			b $2c
:SetOpt7k		lda	#$04			;Tabulator-Position #3.
			b $2c
:SetOpt7l		lda	#$05			;Tabulator-Position #4.
			b $2c
:SetOpt7m		lda	#$06			;Tabulator-Position #5.
			b $2c
:SetOpt7n		lda	#$07			;Tabulator-Position #6.
			b $2c
:SetOpt7o		lda	#$08			;Tabulator-Position #7.
			b $2c
:SetOpt7p		lda	#$09			;Tabulator-Position #8.
			b $2c
:SetOpt7q		lda	#$0a
			b $2c
:SetOpt7r		lda	#$0b
			b $2c
:SetOpt7s		lda	#$0c

:SetInpOpt		asl
			tax
			lda	V200m0+0,x
			sta	a9L
			lda	V200m0+1,x
			sta	a9H
			jmp	InpOptNum

;*** "Dateien verbinden".
:SetOpt8a		lda	LinkFiles
			bne	:1
			ora	#%00100000
			bne	:2
::1			lda	#$00
::2			sta	LinkFiles
			rts

:SetOpt8b		lda	#%00100000
			b $2c
:SetOpt8c		lda	#%01000000
			b $2c
:SetOpt8d		lda	#%10000000
			sta	LinkFiles
			rts

;*** Tabulatoren auf Gültigkeit testen.
:TestTabPos		ldy	#$00

::1			lda	GW_TabBase+1,y		;Testen ob Tabulator links vom
			and	#%01111111		;rechten Rand liegt.
			cmp	GW_RRand  +1
			bcc	:3
			lda	GW_TabBase+0,y
			cmp	GW_RRand  +0
			bcc	:3

::2			lda	GW_RRand  +0		;Wert ungültig. Tabulator auf
			sta	GW_TabBase+0,y		;rechten Rand setzen.
			lda	GW_RRand  +1
			sta	GW_TabBase+1,y
			jmp	:4

::3			lda	GW_TabBase+1,y		;Testen ob Tabulator rechts vom
			and	#%10000000		;linken Rand liegt.
			ora	GW_LRand  +1
			cmp	GW_TabBase+1,y
			bcc	:4
			lda	GW_LRand  +0
			cmp	GW_TabBase+0,y
			bcc	:4
			bcs	:2

::4			iny
			iny
			cpy	#$10
			bne	:1
			rts

;*** Tabulator-Position ausgeben.
:PrnTab1Opt		pha
			lda	r0H			;Dezimal-Tabulator-Flag löschen.
			and	#%01111111
			sta	r0H
			pla

;*** Zahlenwert/8 ausgeben.
:PrnOpt8Num		jsr	ClrOptRec
			AddW	V200a4,r0		;Linken Rand addieren.

			lda	r0L			;Falls Wert für "Rechter Rand"
			and	#%00000111		;Word um eins erhöhen.
			beq	:1
			IncWord	r0

::1			ldx	#r0L			;Word / 8.
			ldy	#$03
			jsr	DShiftRight
			jmp	PrnOptNum

;*** Zahlenwert/1 ausgeben.
:PrnOpt1Num		jsr	ClrOptRec		;Ausgabebereich löschen.

;*** Zahlenwert ausgeben.
:PrnOptNum		lda	#%11000000		;Zahl "linksbündig" ausgeben.
			jsr	PutDecimal
			ldy	#$ff
			rts

;*** Ausgabe-Fenster für Zahlenwert löschen.
:ClrOptRec		pha				;Register zwischenspeichern.
			txa
			pha
			tya
			pha
			lda	#$00			;Ausgabe-Fenster löschen.
			jsr	L900f0
			pla				;Register wieder herstellen.
			sta	r1H
			pla
			sta	r11H
			pla
			sta	r11L
			rts

;*** Keine Druckertreiber
:NoPrinter		lda	#<V200q2		;Text für Fehlermeldung:
			ldx	#>V200q2		;"Keine Druckertreiber..."
			jmp	NoFiles

;*** Keine Zeichensätze.
:NoFonts		lda	#<V200q3		;Text für Fehlermeldung:
			ldx	#>V200q3		;"Keine Schriftarten..."
			jmp	NoFiles

;*** Keine DOS-Tabellen.
:NoDOSTab		lda	#<V200q4		;Text für Fehlermeldung:
			ldx	#>V200q4		;"Keine DOS-Tabellen..."
			jmp	NoFiles

;*** Keine C64-Tabellen.
:NoCBMTab		lda	#<V200q5		;Text für Fehlermeldung:
			ldx	#>V200q5		;"Keine CBM-Tabellen..."

;*** Keine Dateien gefunden.
:NoFiles		sta	V200q1+0		;Text für Fehlermeldung merken.
			stx	V200q1+1

			LoadW	r0,V200q0
			ClrDlgBoxCSet_Grau		;Fehlerbox ausgeben.
			jmp	SetOpt_a		;Zurück zur Options-Auswahl.

;*** Zahl Eingeben.
:InpOptNum		PopW	V200a3			;Rücksprung-Adresse merken.

			lda	mouseOn			;Menüs & Icons aus.
			and	#%10011111
			sta	mouseOn
			MoveW	V200a1,otherPressVec
			MoveW	a9,V200a2		;Zeiger auf Daten-Liste merken.

;*** Neue Zahl eingeben.
:InpNOptNum		jsr	SetInputAdr		;Pos. auf Zahlenspeicher berechnen.

			ldy	#$00			;Zahl aus Speicher nach ":r0".
			lda	(r1L),y
			sta	r0L
			iny
			lda	(r1L),y
			and	#%00000011
			sta	r0H

			ldy	#$0c
			lda	(a9L),y			;Wert für linken Rand addieren ?
			beq	:1			;Nein, weiter.
			AddW	V200a4,r0		;Ja, Wert für linken Rand addieren.

::1			ldy	#$06
			jsr	L900e0			;Routine aus Daten-Liste aufrufen.

			ldy	#$00
			lda	(a9L),y			;X-Koordinate für Eingabe.
			sta	r11L
			iny
			lda	(a9L),y
			sta	r11H
			iny
			lda	(a9L),y			;Y-Koordinate für Eingabe.
			sta	r1H
			iny
			lda	(a9L),y			;Anzahl Zeichen für Eingabe.
			sta	r2L

			LoadW	r0,InputBuf		;Zeiger auf Eingabespeicher.
			LoadB	r1L,$00			;Standard-Fehler-Routine.
			LoadW	keyVector,:2		;Zeiger auf Abschluß-Routine.
			jmp	GetString

;*** Eingabe abschließen.
::2			MoveW	V200a2,a9		;Zeiger auf Daten-Liste zurücksetzen.

			ldy	#$08
			jsr	L900e0			;Routine aus Daten-Liste aufrufen.

			ldy	#$0c
			lda	(a9L),y			;Wert für linken Rand abziehen ?
			beq	:3			;Nein, weiter.
			SubW	V200a4,r0		;Ja, Wert für linken Rand abziehen.

::3			ldy	#$0a
			jsr	L900e0			;Routine aus Daten-Liste aufrufen.
			bcc	:4			;Wert in Ordnung ? Ja, weiter.
			jsr	SetClkPos		;Alte Werte ausgeben.
			MoveW	V200a2,a9		;Zahl erneut eingeben.
			jmp	InpNOptNum

::4			jsr	SetInputAdr		;Zeiger auf Zahlenpeicher.
			ldy	#$00
			lda	r0L			;Neuen Wert in Speicher schreiben.
			sta	(r1L),y
			iny
			lda	(r1L),y
			and	#%11111100
			ora	r0H
			sta	(r1L),y

			lda	mouseOn			;Icons aktivieren.
			ora	#%00100000
			sta	mouseOn
			LoadW	otherPressVec,ChkOptSlct

			PushW	V200a3			;Rücksprung-Adresse wieder herstellen.
			rts

;*** Zeiger auf Zahlenspeicher einlesen.
:SetInputAdr		ldy	#$04			;Zeiger auf Vorgabe-Wert für
			lda	(a9L),y			;Input-Routine berechnen.
			sta	r1L
			iny
			lda	(a9L),y
			sta	r1H
			rts

;*** $HEX nach ASCII wandeln.
:HEXtoASCII_2		lda	r0L			;Tabulator am Rechten Rand ?
			and	#%00000111		;Ja, Word um eins erhöhen.
			beq	HEXtoASCII_1
			IncWord	r0

:HEXtoASCII_1		ldx	#r0L			;Zahlenwert / 8.
			ldy	#$03
			jsr	DShiftRight
			jmp	HEXtoASCII		;Word nach ASCII wandeln.

:HEXtoASCII_3		ClrB	r0H			;Byte nach ASCII wandeln.

:HEXtoASCII		jsr	InitForBA		;Word in ASCII-String ab $0100
			lda	r0L			;umwandeln.
			ldx	r0H
			jsr	Word_FAC
			jsr	x_FLPSTR
			jsr	DoneWithBA

			ldy	#$00
::1			lda	$0101,y			;Word ab $0101 in Eingabespeicher
			beq	:2			;übertragen.
			sta	InputBuf,y
			iny
			cpy	#$03
			bne	:1
			lda	#$00			;Ende des Eingabespeichers
::2			sta	InputBuf,y		;markieren.
			rts

;*** ASCII nach $HEX-Word wandeln.
:ASCIItoHEX_1		jsr	ASCIItoHEX		;ASCII nach HEX wandeln.
			ldx	#r0L			;Word + 8.
			ldy	#$03
			jmp	DShiftLeft

:ASCIItoHEX		ClrW	r0			;Word auf $0000 setzen.
			lda	InputBuf		;Eingabe-Speicher leer ?
			bne	:1			;Nein, weiter.
			rts

::1			ldy	#$01			;Länge der Zahl ermitteln.
::2			lda	InputBuf,y
			beq	:3
			iny
			bne	:2
			iny

::3			dey
			sty	r1L			;Länge der Zahl merken.
			ClrB	r1H			;Zeiger auf Dezimal-Stelle für 1er.

::4			ldy	r1L
			lda	InputBuf,y		;Zeichen aus Zahlenstring holen.
			sub	$30			;Reinen Zahlenwert (0-9) isolieren.
			bcc	:7			;Unterlauf, keine Ziffer.
			cmp	#$0a			;Wert >= 10 ?
			bcs	:7			;Ja, keine Ziffer.
			tax
			beq	:7			;Null ? Ja, weiter...
::6			ldy	r1H			;Je nach Dezimal-Stelle, 1er, 10er
			lda	V200b0,y		;oder 100er addieren.
			clc
			adc	r0L
			sta	r0L
			lda	#$00
			adc	r0H
			sta	r0H
			dex				;Schleife bis Zahl = 0.
			bne	:6

::7			inc	r1H			;Weiter bis Zahlenende erreicht.
			dec	r1L
			bpl	:4
			rts

;*** Drucker wählen.
:SlctPrinter		jsr	L900d0			;Bildschirm löschen.
			jsr	SaveDrvData		;Laufwerk und Partition sichern.
::1			jsr	InitFileTab		;Laufwerks-Einträge erzeugen.

			lda	#PRINTER		;Druckertreiber einlesen.
			ldx	#$00
			ldy	#$00
			jsr	GetFileList

			LoadW	r14,V200f0		;Drucker-Auswahlbox.
			LoadW	r15,Memory
			lda	#$00
			ldx	#$10
			ldy	#$02
			jsr	SlctFileList
			bcc	:3			;Datei-Auswahl ? Ja, weiter...
			tax				;Wurde Laufwerk gewechselt ?
			bne	:1			;Ja, Neue Tabelle.
::2			jmp	ExitPFSlct		;Nein, zurück zum Options-Modus.

::3			ldy	#$0f			;Neuen Druckertreiber setzen.
::4			lda	(r15L),y
			sta	PrntFileName,y
			dey
			bpl	:4

			LoadW	r6,PrntFileName
			jsr	FindFile		;Drucker-Treiber suchen.
			txa
			beq	:6
			cpx	#$05
			beq	:2
::5			jmp	DiskError

::6			jsr	GetPrnDim		;Druckertreiber/Seitenlänge einlesen.

;*** Seitenlänge ermitteln.
:GetPageLen		jsr	ChkPageSize		;Seitenlänge mit Schriftart
							;verknüpfen -> Anzahl Zeilen berechnen.

;*** Drucker-Treiber einlesen und Seitenlänge ermitteln.
:ExitPFSlct		jsr	LoadDrvData		;Laufwerk & Partition zurücksetzen.
			jsr	ClrPartName		;Anzeige für Partitionsname löschen.
			jmp	SetInfoPage		;Zurück zum Options-Modus.

;*** Drucker-Treiber einlesen und Seitenlänge ermitteln.
:GetPrnDim		LoadW	r6,PrntFileName
			LoadB	r0L,%00000001
			LoadW	r7,PRINTBASE
			jsr	GetFile			;Drucker-Treiber laden.
			txa
			beq	:1
			cpx	#$05
			beq	:2			;Drucker-Treiber nicht gefunden.
			jmp	DiskError

::1			jsr	GetDimensions
			sty	r0L			;Seitenlänge einlesen.
			ClrB	r0H
			ldx	#r0L
			ldy	#$03
			jsr	DShiftLeft
			MoveW	r0,OptDOStoGW+4
::2			rts

;*** Anzahl Zeilen berechnen.
:ChkPageSize		lda	OptDOStoGW+4		;Seitenlänge des Druckers nach ":r0".
			sta	r0L
			lda	OptDOStoGW+5
			sta	r0H

			lda	OptGW_Font+1		;Punktgröße nach ":r1".
			and	#%00111111
			add	2
			sta	r1L
			ClrB	r1H

			ldx	#r0L			;"Seitenlänge : Punktgröße"
			ldy	#r1L
			jsr	Ddiv

			lda	r0L			;Ergebnis nach ":LinesPerPage".
			sub	2
			sta	LinesPerPage

			rts

;*** Schriftart wählen.
:SlctFont		jsr	L900d0
			jsr	SaveDrvData		;Laufwerk und Partition sichern.
::1			jsr	InitFileTab		;Laufwerks-Einträge erzeugen.

			ldy	#$0f			;Eintrag "BSW-Font" erzeugen.
::2			lda	V200c2,y
			sta	(a9L),y
			dey
			bpl	:2
			AddVW	16,a9

			lda	#FONT			;Zeichensätze einlesen.
			ldx	#$00
			ldy	#$00
			jsr	GetFileList

			LoadW	r14,V200f1		;Font-Auswahlbox.
			LoadW	r15,Memory
			lda	#$00
			ldx	#$10
			ldy	#$03
			jsr	SlctFileList
			bcc	:4			;Datei-Auswahl ? Ja, weiter...
			tax				;Wurde Laufwerk gewechselt ?
			bne	:1			;Ja, Neue Tabelle.
::3			jmp	ExitPFSlct		;Nein, zurück zum Options-Modus.

::4			cpx	#$00			;"BSW-Font" aktivieren ?
			bne	:6			;Nein, weiter.

			ldy	#$0f			;Ja, Name des BSW-Fonts in Speicher.
::5			lda	V200c2,y
			sta	UsedGWFont,y
			dey
			bpl	:5

			lda	#$09			;Punktgröße.
			sta	UsedPointSize
			sta	OptGW_Font+1		;Punktgröße und ID.
			lda	#$00
			sta	OptGW_Font+2
			jmp	ExitPFSlct

::6			ldy	#$10			;Font-Datei auf Disk suchen.
			lda	#$00
			sta	(r15L),y
			MoveW	r15,r6
			jsr	FindFile
			txa
			beq	:8
::7			jmp	DiskError		;Disketten-Fehler.

::8			ldy	#$0f			;Name der Datei zwischenspeichern.
::9			lda	(r15L),y
			sta	V201z0,y
			dey
			bpl	:9

			lda	dirEntryBuf+1		;VLIR-Header lesen.
			sta	r1L
			lda	dirEntryBuf+2
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa
			bne	:7			;Disketten-Fehler.

			LoadW	r9,dirEntryBuf		;File-Header lesen.
			jsr	GetFHdrInfo
			txa
			bne	:7			;Disketten-Fehler.

			LoadW	a9,Memory		;Zeiger auf Anfang für Punktgrößen-
							;Tabelle setzen.
			lda	#$02
::10			pha
			tax
			lda	diskBlkBuf,x		;Prüfen ob VLIR-Datensatz belegt ist.
			beq	:13			;Nicht belegt, Größe nicht vorhanden.
			txa				;Größe nach ASCII wandeln und in
			sub	2			;Tabelle eintragen.
			lsr
			sta	r0L
			jsr	HEXtoASCII_3
			ldy	#$00
			ldx	#$00
::11			lda	InputBuf,y
			beq	:12
			sta	(a9L),y
			iny
			cpy	#$03
			bne	:11
::12			lda	V200g0,x		;Text " Punkte" in Tabelle.
			sta	(a9L),y
			inx
			iny
			cpy	#$10
			bne	:12
			AddVBW	16,a9
::13			pla				;Nächste Punktgröße testen.
			add	2
			bne	:10
			tay
			sta	(a9L),y

;*** Punktgröße wählen.
:SlctPntSize		CmpWI	a9,Memory		;Punktgrößen in Font-Datei ?
			bne	:1			;Ja, auswählen.
			jmp	ExitPFSlct

::1			LoadW	r14,V200f2		;Punktgrößen-Auswahlbox.
			LoadW	r15,Memory
			lda	#$00
			ldx	#$10
			ldy	#$00
			jsr	DoScrTab

			ldy	sysDBData		;Punktgröße gewählt ?
			cpy	#$01
			beq	:3
			cmp	#$01
			bne	:2			;Ja, weiter.
			jsr	LoadDrvData
			jmp	SlctFont

::2			jmp	ExitPFSlct		;Nein, zurück zum Options-Modus.

::3			ldy	#$00			;Punktgröße nach $HEX wandeln.
::4			lda	(r15L),y
			cmp	#" "
			beq	:5
			sta	InputBuf,y
			iny
			cpy	#$03
			bne	:4

::5			lda	#$00
			sta	InputBuf,y
			jsr	ASCIItoHEX

;*** NEWCARDSET definieren.
:SetNewFont		lda	fileHeader+128		;Font-ID mit Punktgröße
			sta	r1L			;verknüpfen.
			lda	fileHeader+129
			sta	r1H
			ldx	#r1L
			ldy	#$06
			jsr	DShiftLeft
			lda	r0L
			sta	UsedPointSize
			and	#%00111111
			ora	r1L
			sta	OptGW_Font+1
			lda	r1H
			sta	OptGW_Font+2

			ldy	#$0f
::1			lda	V201z0,y		;Name der Font-Datei in Speicher.
			sta	UsedGWFont,y
			dey
			bpl	:1

			jmp	GetPageLen		;Seitenlänge berechnen.

;*** Parameter speichern.
:SetGFLPar		sta	L900h0 +1		;Datei-Typ merken.
			stx	L900h1 +1		;Zeiger auf "Class" merken.
			sty	L900h2 +1
			rts

;*** Datei-Liste einlesen.
:GetSFileList		jsr	SetGFLPar		;Parameter speichern.
			jsr	GetStartDrv		;Start-Laufwerk aktivieren.
			txa
			bne	:1
			jsr	L900h0			;Dateien einlesen.
			jsr	GetWorkDrv		;Arbeits-Laufwerk aktivieren.
			txa
			beq	:1
			jmp	DiskError		;Disketten-Fehler.
::1			rts				;Ende, Rücksprung.

;*** Datei-Liste einlesen.
;    Ablage für Datei-Namen in ":a9".
:GetFileList		jsr	SetGFLPar		;Parameter speichern.

:L900h0			lda	#$ff
			sta	r7L			;Dateien suchen.
			LoadB	r7H,255
:L900h1			lda	#$ff
			sta	r10L
:L900h2			lda	#$ff
			sta	r10H
			MoveW	a9,r6
			jsr	FindFTypes
			txa
			beq	:5
::4			jmp	DiskError		;Disketten-Fehler.

::5			CmpBI	r7H,255			;Dateien gefunden ?
			bne	:7			;Ja, Tabelle generieren.
::6			rts

::7			lda	a9L			;Datei-Namen der gefundenen Einträge
			sta	r0L			;in 16-Byte-Format wandeln.
			sta	r1L
			lda	a9H
			sta	r0H
			sta	r1H

::8			ldy	#$00
::9			lda	(r1L),y			;$00-Bytes im Datei-Namen
			bne	:10			;durch "SHIFT-SPACE" ersetzen.
			lda	#$a0
::10			sta	(r0L),y
			iny
			cpy	#$10			;Ende Datei-Namen erreicht ?
			bne	:9

			AddVBW	16,r0			;Zeiger auf nächsten Datei-Namen.
			AddVBW	17,r1

			inc	r7H
			CmpBI	r7H,255			;Ende der Tabelle erreicht ?
			bne	:8			;Nein, weiter...

			ldy	#$00			;Tabellen-Ende markieren.
			tya
			sta	(r0L),y
			rts

;*** Name der aktiven Partition ausgeben.
:PrnPartName		InitSPort			;Aktive Partition einlesen.
			CxSend	GetCurPart
			CxReceiveCurPartDat
			jsr	DoneWithIO

			Pattern	0
			jsr	SetPtNamBack
			lda	#%11111111
			jsr	FrameRectangle
			FrameRec169,182,10,309,%11111111
			FrameRec170,181,11,308,%11111111

			lda	curDrive		;Laufwerk in Text eintragen.
			add	$39
			sta	V200r6

			jsr	UseGDFont		;geoDOS-Font aktivieren.
			PrintXY	16,178,V200r5		;Laufwerk & Partitionsname ausgeben.

			lda	#$00
::1			pha
			tay
			lda	CurPartDat+5,y
			cmp	#$20
			bcc	:2
			cmp	#$7f
			bcc	:3
::2			lda	#" "
::3			jsr	SmallPutChar
			pla
			add	1
			cmp	#16
			bne	:1
			rts

;*** Anzeige für Partitions-Name löschen.
:ClrPartName		Pattern	2
:SetPtNamBack		Display	ST_WR_FORE
			FillRec	167,184, 8,311
			rts

;*** Laufwerk und Partition speichern.
:SaveDrvData		ldx	curDrive		;Aktuelles Laufwerk merken.
			stx	ModBuf    +0
			lda	ramBase-8,x		;Startadresse RAM-Partition merken.
			sta	ModBuf    +1
			lda	driveData +3
			sta	ModBuf    +2
			InitSPort			;Aktive Partition einlesen.
			CxSend	GetCurPart
			CxReceiveCurPartDat
			jsr	DoneWithIO
			lda	CurPartDat+4		;Aktive Partition merken.
			sta	ModBuf    +3
			rts

;*** Laufwerk und Partition zurücksetzen.
:LoadDrvData		lda	ModBuf    +0		;Aktuelles Laufwerk wieder herstellen.
			jsr	NewDrive
			ldx	curDrive
			lda	ModBuf    +1		;RAM-Partition wieder herstellen.
			sta	ramBase-8,x
			lda	ModBuf    +2
			sta	driveData+3
			lda	ModBuf    +3
			sta	DoUsrPart+4
			C_Send	DoUsrPart		;Partition wieder herstellen.
			jmp	OpenDisk

;*** Laufwerks-Typen in Tabelle.
:InitFileTab		jsr	i_FillRam		;Speicher löschen.
			w	17*256,Memory
			b	$00

			LoadW	a9,Memory		;Zeiger auf Anfang Zwischenspeicher.

			ldx	#$00
			stx	V200r0			;Anzahl Drives löschen.
			stx	V200r1			;Kein Partitionswechsel.
::1			lda	DriveTypes,x		;Laufwerk vorhanden ?
			beq	:3			;Nein, weiter...

			inc	V200r0			;Laufwerk, Zähler korrigieren.
			txa				;Laufwerks-Namen als Eintrag in
			pha				;Tabelle kopieren.
			asl
			asl
			asl
			asl
			tax
			ldy	#$00
::2			lda	V200r2,x
			sta	(a9L),y
			inx
			iny
			cpy	#$10
			bne	:2

			AddVBW	16,a9

			pla
			tax
::3			inx				;Vier Laufwerke überprüfen.
			cpx	#$04
			bne	:1

			ldx	curDrive
			lda	DriveModes-8,x		;Aktives-Laufwerk "RAM-Partition" ?
			bpl	:5			;Nein, weiter...

			ldy	#$0f			;Partitions-Eintrag erzeugen.
::4			lda	V200r3,y
			sta	(a9L),y
			dey
			bpl	:4

			AddVW	16,a9
			inc	V200r0
			inc	V200r1

			jsr	PrnPartName		;Partitionsname anzeigen.

::5			lda	#$00			;Tabellen-Ende markieren.
			tay
			sta	(a9L),y

			rts

;*** Auswahl-Tabelle.
:SlctFileList		sty	V200r4			;Options-Modus speichern.

			pha
			lda	curDrive		;Laufwerk in Titel-Zeile.
			add	$39
			ldy	#27
			sta	(r14L),y
			pla

			ldy	V200r0			;Anzahl "Action-Files".
			jsr	DoScrTab		;Datei-Auswahl.

			ldy	sysDBData		;Auswahl abgebrochen ?
			cpy	#$01			;Nein, weiter.
			beq	:1

			lda	#$00			;Zurück zum Partitions-Menü.
			sec
			rts

::1			cpx	V200r0			;Laufwerk/Partition wechseln ?
			bcs	:4			;Nein, weiter...

			lda	V200r1			;Partition wechseln ?
			beq	:3			;Nein, Laufwerk wechseln.

			inx
			cpx	V200r0			;Partition wechseln ?
			bne	:2			;Nein, Laufwerk wechseln.
			ldx	V200r4			;Partitions-Menü.
			jsr	m_SlctPart1
			lda	#$ff			;Zurück zum Parameter-Menü.
			sec
			rts

::2			dex				;Neues Laufwerk wählen.
::3			txa
			asl
			asl
			asl
			asl
			add	9
			tay
			lda	(r14L),y
			sub	$39
			pha
			jsr	LoadDrvData		;Partition auf aktivem Laufwerk
							;zurücksetzen.
			pla
			jsr	NewDrive		;Neues Laufwerk aktivieren.
			jsr	SaveDrvData		;Laufwerk und Partition sichern.
			jsr	ClrPartName
			lda	#$ff			;Auswahlbox nochmal aufbauen.
			sec
			rts

::4			txa				;Datei-Eintrag berechnen.
			suba	V200r0
			tax
			clc
			rts

;*** Tabellen löschen.
:NoCTab			lda	#$00			;Namen der Übersetzungstabelle
			sta	CTabDOStoCBM		;löschen.
			sta	CTabCBMtoDOS

:SetInfoPage		ClrB	V200a0			;Info-Seite neu aufbauen.
			jmp	SetOpt_a

;*** Konvertierungstabelle DOS laden.
:SlctCTabDOS		jsr	L900d0			;Bildschirm löschen.

			ldy	#$0f			;Text für "1:1 Übertragung".
::1			lda	V200g1,y
			sta	V201z0,y
			dey
			bpl	:1

			LoadW	a9,Memory
			lda	#APPL_DATA		;Tabellen einlesen.
			ldx	#<V200h0
			ldy	#>V200h0
			jsr	GetSFileList
			tax
			beq	:2
			jmp	NoDOSTab		;Keine Tabellen gefunden.

::2			LoadW	r14,V200f3		;Tabellen-Auswahlbox.
			LoadW	r15,V201z0
			lda	#$00
			ldx	#$10
			ldy	#$00
			jsr	DoScrTab

			ldy	sysDBData
			cpy	#$01
			beq	:3
			jmp	SetOpt_a		;Ja, zurück zum Options-Modus.

::3			cpx	#$00			;"1:1 Übertragung" gewählt ?
			bne	:4			;Nein, weiter.
			stx	CTabDOStoCBM		;Ja, Tabelle löschen.
			jmp	SetInfoPage		;Zurück zum Options-Modus.

::4			ldy	#$0f			;Name der Tabelle merken.
::5			lda	(r15L),y
			sta	CTabDOStoCBM,y
			dey
			bpl	:5
			jmp	SetInfoPage		;Zurück zum Options-Modus.

;*** Konvertierungstabelle C64 laden.
:SlctCTabCBM		jsr	L900d0			;Bildschirm löschen.

			ldy	#$0f			;Text für "1:1 Übertragung".
::1			lda	V200g1,y
			sta	V201z0,y
			dey
			bpl	:1

			LoadW	a9,Memory
			lda	#APPL_DATA		;Tabellen einlesen.
			ldx	#<V200h1
			ldy	#>V200h1
			jsr	GetSFileList
			tax
			beq	:2
			jmp	NoCBMTab		;Keine Tabellen gefunden.

::2			LoadW	r14,V200f4		;Tabellen-Auswahlbox.
			LoadW	r15,V201z0
			lda	#$00
			ldx	#$10
			ldy	#$00
			jsr	DoScrTab

			ldy	sysDBData
			cpy	#$01
			beq	:3
			jmp	SetOpt_a		;Ja, zurück zum Options-Modus.

::3			cpx	#$00			;"1:1 Übertragung" gewählt ?
			bne	:4			;Nein, weiter.
			stx	CTabCBMtoDOS		;Ja, Tabelle löschen.
			jmp	SetInfoPage		;Zurück zum Options-Modus.

::4			ldy	#$0f			;Name der Tabelle merken.
::5			lda	(r15L),y
			sta	CTabCBMtoDOS,y
			dey
			bpl	:5
			jmp	SetInfoPage		;Zurück zum Options-Modus.

;*** Icon-Tabelle.
:OptYDelta		= 20
:OptYPos		= 40

:icon_Tab1		b 18
			w $0000
			b $00

			w icon_Close
			b  0, 0
			b icon_Close_x,icon_Close_y
			w ExitDT_a

			w icon_Close
			b  2,40
			b icon_Close_x,icon_Close_y
			w L200ExitGD

			w icon_Standard
			b  2,16
			b icon_Standard_x,icon_Standard_y
			w StandardOpt

			w icon_SlctPrn
			b  5,16
			b icon_SlctPrn_x,icon_SlctPrn_y
			w SlctPrinter

			w icon_SlctFont
			b  8,16
			b icon_SlctFont_x,icon_SlctFont_y
			w SlctFont

			w icon_NoCTab
			b 12,16
			b icon_NoCTab_x,icon_NoCTab_y
			w NoCTab

			w icon_DosCTab
			b 15,16
			b icon_DosCTab_x,icon_DosCTab_y
			w SlctCTabDOS

			w icon_CbmCTab
			b 18,16
			b icon_CbmCTab_x,icon_CbmCTab_y
			w SlctCTabCBM

			w icon_Exit
			b 22,16
			b icon_Exit_x,icon_Exit_y
			w L200ExitGD

			w icon_GotoPage
			b 22,160
			b icon_GotoPage_x,icon_GotoPage_y
			w ChangePage

			w icon_Opt0
			b 27,16
			b icon_Opt0_x,icon_Opt0_y
			w OptIconSlct

			w icon_Opt1
			b 27,0 + OptYPos + 0 * OptYDelta
			b icon_Opt1_x,icon_Opt1_y
			w OptIconSlct

			w icon_Opt2
			b 27,2 + OptYPos + 1 * OptYDelta
			b icon_Opt2_x,icon_Opt2_y
			w OptIconSlct

			w icon_Opt3
			b 27,2 + OptYPos + 2 * OptYDelta
			b icon_Opt3_x,icon_Opt3_y
			w OptIconSlct

			w icon_Opt4
			b 27,4 + OptYPos + 3 * OptYDelta
			b icon_Opt4_x,icon_Opt4_y
			w OptIconSlct

			w icon_Opt5
			b 27,4 + OptYPos + 4 * OptYDelta
			b icon_Opt5_x,icon_Opt5_y
			w OptIconSlct

			w icon_Opt6
			b 27,6 + OptYPos + 5 * OptYDelta
			b icon_Opt6_x,icon_Opt6_y
			w OptIconSlct

			w icon_Opt7
			b 27,8 + OptYPos + 6 * OptYDelta
			b icon_Opt7_x,icon_Opt7_y
			w OptIconSlct

;*** Icons.
:icon_Standard
<MISSING_IMAGE_DATA>
:icon_Standard_x	= .x
:icon_Standard_y	= .y

:icon_SlctPrn
<MISSING_IMAGE_DATA>
:icon_SlctPrn_x		= .x
:icon_SlctPrn_y		= .y

:icon_SlctFont
<MISSING_IMAGE_DATA>
:icon_SlctFont_x	= .x
:icon_SlctFont_y	= .y

:icon_ExitShowCTab
<MISSING_IMAGE_DATA>
:icon_ExitShowCTab_x	= .x
:icon_ExitShowCTab_y	= .y

:icon_Exit
<MISSING_IMAGE_DATA>
:icon_Exit_x		= .x
:icon_Exit_y		= .y

:icon_GotoPage
<MISSING_IMAGE_DATA>
:icon_GotoPage_x	= .x
:icon_GotoPage_y	= .y

:icon_NoCTab
<MISSING_IMAGE_DATA>
:icon_NoCTab_x		= .x
:icon_NoCTab_y		= .y

:icon_DosCTab
<MISSING_IMAGE_DATA>
:icon_DosCTab_x		= .x
:icon_DosCTab_y		= .y

:icon_CbmCTab
<MISSING_IMAGE_DATA>
:icon_CbmCTab_x		= .x
:icon_CbmCTab_y		= .y

:icon_Opt0
<MISSING_IMAGE_DATA>
:icon_Opt0_x		= .x
:icon_Opt0_y		= .y

:icon_Opt1                <MISSING_IMAGE_DATA>
:icon_Opt1_x		= .x
:icon_Opt1_y		= .y

:icon_Opt2
<MISSING_IMAGE_DATA>
:icon_Opt2_x		= .x
:icon_Opt2_y		= .y

:icon_Opt3
<MISSING_IMAGE_DATA>
:icon_Opt3_x		= .x
:icon_Opt3_y		= .y

:icon_Opt4
<MISSING_IMAGE_DATA>
:icon_Opt4_x		= .x
:icon_Opt4_y		= .y

:icon_Opt5
<MISSING_IMAGE_DATA>
:icon_Opt5_x		= .x
:icon_Opt5_y		= .y

:icon_Opt6
<MISSING_IMAGE_DATA>
:icon_Opt6_x		= .x
:icon_Opt6_y		= .y

:icon_Opt7
<MISSING_IMAGE_DATA>
:icon_Opt7_x		= .x
:icon_Opt7_y		= .y

;*** Variablen.
:OptionMode		b $00

:V200a0			b $00				;Aktuelles Parameter-Menü.
:V200a1			w $0000				;Zwischenspeicher: ":keyVector".
:V200a2			w $0000				;Zwischenspeicher: Zeiger auf Daten-Liste.
:V200a3			w $0000				;Zwischenspeicher: Rücksprung-Adresse.
:V200a4			w $0000				;Zwischenspeicher: Anfangs-Wert "linker Rand".

;*** Umrechnungswerte für ASCII nach HEX.
:V200b0			b 1,10,100

;*** Zwischenspeicher für Zahleneingabe.
:InputBuf		s $04

;*** Vorgabe-Werte.
:V200c0			w $0000,$01df
			w $01df,$01df,$01df,$01df
			w $01df,$01df,$01df,$01df,$0000
:V200c1			w $0000,$027f
			w $027f,$027f,$027f,$027f
			w $027f,$027f,$027f,$027f,$0000

:V200c2			b "BSW- GEOS System",$00	;Name der aktiven Schriftart.
			b $09				;Punktgröße.
			w $0040				;Anzahl Zeilen/Seite (WORD!).
			b $00				;$FF = Dateien verbinden.
			b $00				;Datum der Quell-Datei übernehmen.
			b $ff				;Vor dem löschen von Dateien fragen.
			b $81				;CBM-Datei-Typ "SEQ".
			b $00				;"LF" nich ignorieren.
			b $00				;DOS-Namen vorschlagen.
			b $00				;"LF" nicht einfügen.
			b $00				;Typ Ziel-Verzeichnis ($FF= SubDir).
			w $0000				;Cluster für Ziel-Verzeichnis.
			b $00				;DOS-Seitenvorschub ignorieren.
			b $00				;geoWrite-Text V2.0
			w $0001				;Nr. der ersten Seite.
			w $02f0				;Länge einer Seite-> Druckertreiber.
			b ESC_RULER			;Seiten-Anfang.
			w $0000				;Linker Rand.
			w $01df				;Rechter Rand.
			w $01df				;Tabulator #1.
			w $01df				;Tabulator #2.
			w $01df				;Tabulator #3.
			w $01df				;Tabulator #4.
			w $01df				;Tabulator #5.
			w $01df				;Tabulator #6.
			w $01df				;Tabulator #7.
			w $01df				;Tabulator #8.
			w $0000				;Absatz-Tabulator.
			b %00010000			;Formatierung.
			s $03				;Reserviert.
			b NEWCARDSET
			w $0009				;Font-ID & Punktgröße.
			b $00				;Schriftstil.
			b $00				;GW-Seitenvorschub ignorieren.

;*** Titel-Texte.
:V200d0			w V200e0,V200e1,V200e2,V200e3
			w V200e4,V200e5,V200e6,V200e7

:V200e0			b "Information",NULL
:V200e1			b "Ziel-Datei",NULL
:V200e2			b "DOS - CBM",NULL
:V200e3			b "CBM - DOS",NULL
:V200e4			b "DOS - geoWrite",NULL
:V200e5			b "geoWrite - DOS",NULL
:V200e6			b "Seitenformat",NULL
:V200e7			b "Zusammenfügen",NULL

;*** Dialogbox-Titel.
:V200f0			b PLAINTEXT,REV_ON
			b "Drucker wählen           x:",NULL
:V200f1			b PLAINTEXT,REV_ON
			b "Schriftart wählen        x:",NULL
:V200f2			b PLAINTEXT,REV_ON
			b "Punktgröße wählen",NULL
:V200f3			b PLAINTEXT,REV_ON
			b "Übersetzen DOS nach C64",NULL
:V200f4			b PLAINTEXT,REV_ON
			b "Übersetzen C64 nach DOS",NULL

;*** System-Texte.
:V200g0			b " Punkte",0,0,0,0,0,0,0,0,0,0
:V200g1			b "1:1 Übertragung ",NULL

;*** Klasse für Übersetzungs-Tabellen.
:V200h0			b "gD-Conv DOS ",NULL
:V200h1			b "gD-Conv CBM ",NULL

;*** Parameter-Texte.
:V200i0			w V200j0,V200j1,V200j2,V200j3
			w V200j4,V200j5,V200j6,V200j7

;*** "Information".
:V200j0			b PLAINTEXT,BOLDON
			b GOTOXY
			w 32
			b 59
			b "Übersetzen DOS-C64:"
			b GOTOXY
			w 32
			b 88
			b "Übersetzen C64-DOS:"
			b GOTOXY
			w 32
			b 117
			b "Aktiver Drucker:"
			b GOTOXY
			w 32
			b 146
			b "Schriftart/Größe:"
			b NULL

;*** "Ziel-Datei".
:V200j1			b PLAINTEXT,BOLDON
			b GOTOXY
			w 32
			b 59
			b "Datum für Ziel-Datei:"
			b GOTOXY
			w 44
			b 71
			b "Original-Datei"
			b GOTOXY
			w 44
			b 87
			b "Übernahme von GEOS"
			b GOTOXY
			w 32
			b 107
			b "Ziel-Datei überschreiben:"
			b GOTOXY
			w 44
			b 119
			b "Ja, Ziel-Datei löschen"
			b GOTOXY
			w 44
			b 135
			b "Nein, Datei ignorieren"
			b GOTOXY
			w 44
			b 151
			b "Abfrage"
			b NULL

;*** "DOS - CBM".
:V200j2			b PLAINTEXT,BOLDON
			b GOTOXY
			w 32
			b 59
			b "Zeilenvorschub:"
			b GOTOXY
			w 44
			b 71
			b "Ignorieren"
			b GOTOXY
			w 32
			b 107
			b "Datei-Typ:"
			b GOTOXY
			w 44
			b 119
			b "Commodore SEQ"
			b GOTOXY
			w 44
			b 135
			b "Commodore PRG"
			b GOTOXY
			w 44
			b 151
			b "Commodore USR"
			b NULL

;*** "CBM - DOS".
:V200j3			b PLAINTEXT,BOLDON
			b GOTOXY
			w 32
			b 59
			b "Zeilenvorschub:"
			b GOTOXY
			w 44
			b 71
			b "Einfügen"
			b GOTOXY
			w 32
			b 107
			b "DOS-Datei-Name:"
			b GOTOXY
			w 44
			b 119
			b "Name vorschlagen"
			b GOTOXY
			w 44
			b 135
			b "Neu eingeben"
			b NULL

;*** "DOS - geoWrite".
:V200j4			b PLAINTEXT,BOLDON
			b GOTOXY
			w 44
			b 63
			b "Write Image V2.0"
			b GOTOXY
			w 44
			b 79
			b "Write Image V2.1"
			b GOTOXY
			w 32
			b 98
			b "Erste Seiten-Nr:"
			b GOTOXY
			w 44
			b 119
			b "Text neu formatieren"
			b GOTOXY
			w 44
			b 135
			b "Seitenende übernehmen"
			b GOTOXY
			w 44
			b 151
			b "Zeilen pro Seite:"
			b NULL

;*** "DOS - geoWrite".
:V200j5			b PLAINTEXT,BOLDON
			b GOTOXY
			w 32
			b 59
			b "Zeilenvorschub:"
			b GOTOXY
			w 44
			b 71
			b "Einfügen"
			b GOTOXY
			w 32
			b 91
			b "geoWrite - Seitenende:"
			b GOTOXY
			w 44
			b 103
			b "Ignorieren"
			b GOTOXY
			w 32
			b 123
			b "DOS-Datei-Name:"
			b GOTOXY
			w 44
			b 135
			b "Name vorschlagen"
			b GOTOXY
			w 44
			b 151
			b "Neu eingeben"
			b NULL

;*** "Seitenformat".
:V200j6			b PLAINTEXT,BOLDON
			b GOTOXY
			w 32
			b 63
			b "Rand links/rechts:"
			b GOTOXY
			w 32
			b 79
			b "Absatz-Tabulator:"
			b GOTOXY
			w 44
			b 103
			b "Tab 1:"
			b GOTOXY
			w 44
			b 119
			b "Tab 2:"
			b GOTOXY
			w 44
			b 135
			b "Tab 3:"
			b GOTOXY
			w 44
			b 151
			b "Tab 4:"
			b GOTOXY
			w 124
			b 103
			b "Tab 5:"
			b GOTOXY
			w 124
			b 119
			b "Tab 6:"
			b GOTOXY
			w 124
			b 135
			b "Tab 7:"
			b GOTOXY
			w 124
			b 151
			b "Tab 8:"
			b NULL

;*** "Verbinden".
:V200j7			b PLAINTEXT,BOLDON
			b GOTOXY
			w  32
			b  59
			b "Mehrere Texte zu einer"
			b GOTOXY
			w  32
			b  70
			b "geoWrite-Datei verbinden."
			b GOTOXY
			w  44
			b  87
			b "Dateien zusammenfügen"
			b GOTOXY
			w  44
			b 111
			b "Direkt verbinden"
			b GOTOXY
			w  44
			b 127
			b "Leerzeile einfügen"
			b GOTOXY
			w 44
			b 143
			b "Neue Seite beginnen"
			b NULL

;*** Daten-Listen für "Klick-Positioen".
:V200k0			w V200l0,V200l1,V200l2,V200l3
			w V200l4,V200l5,V200l6,V200l7

:V200l0			b   1,  0			;"Information".
			w   0,  0,DefOpt1a,$0000
			b NULL

:V200l1			b  64, 71			;"Ziel-Datei".
			w  32, 39,DefOpt2a,SetOpt2a
			b  80, 87
			w  32, 39,DefOpt2b,SetOpt2b
			b 112,119
			w  32, 39,DefOpt2c,SetOpt2c
			b 128,135
			w  32, 39,DefOpt2d,SetOpt2d
			b 144,151
			w  32, 39,DefOpt2e,SetOpt2e
			b NULL

:V200l2			b  64, 71			;"DOS - CBM".
			w  32, 39,DefOpt3a,SetOpt3a
			b 112,119
			w  32, 39,DefOpt3b,SetOpt3b
			b 128,135
			w  32, 39,DefOpt3c,SetOpt3c
			b 144,151
			w  32, 39,DefOpt3d,SetOpt3d
			b NULL

:V200l3			b  64, 71			;"CBM - DOS".
			w  32, 39,DefOpt4a,SetOpt4a
			b 112,119
			w  32, 39,DefOpt4b,SetOpt4b
			b 128,135
			w  32, 39,DefOpt4c,SetOpt4c
			b NULL

:V200l4			b  56, 63			;"DOS - geoWrite".
			w  32, 39,DefOpt5a,SetOpt5a
			b  72, 79
			w  32, 39,DefOpt5b,SetOpt5b
			b  90,102
			w 117,141,DefOpt5c,SetOpt5c
			b 112,119
			w  32, 39,DefOpt5d,SetOpt5d
			b 128,135
			w  32, 39,DefOpt5e,SetOpt5e
			b 144,151
			w  32, 39,DefOpt5f,SetOpt5f
			b 143,155
			w 136,160,DefOpt5g,SetOpt5g
			b NULL

:V200l5			b  64, 71			;"geoWrite - DOS".
			w  32, 39,DefOpt4a,SetOpt4a
			b  96,103
			w  32, 39,DefOpt6a,SetOpt6a
			b 128,135
			w  32, 39,DefOpt4b,SetOpt4b
			b 144,151
			w  32, 39,DefOpt4c,SetOpt4c
			b NULL

;*** Daten-Listen für "Klick-Positioen" (Fortsetzung).
:V200l6			b  55, 67			;"Linker Rand".
			w 131,155,DefOpt7a,SetOpt7i
			b  55, 67			;"Rechter Rand".
			w 159,183,DefOpt7b,SetOpt7j
			b  71, 83			;"Absatztabulator".
			w 131,155,DefOpt7c,SetOpt7k
			b  96,103			;"Dez. Tab#1".
			w  32, 39,DefOpt7d,SetOpt7a
			b  95,107			;"Pos. Tab#1".
			w  78,102,DefOpt7e,SetOpt7l
			b 112,119			;"Dez. Tab#2".
			w  32, 39,DefOpt7f,SetOpt7b
			b 111,123			;"Pos. Tab#2".
			w  78,102,DefOpt7g,SetOpt7m
			b 128,135			;"Dez. Tab#3".
			w  32, 39,DefOpt7h,SetOpt7c
			b 127,139			;"Pos. Tab#3".
			w  78,102,DefOpt7i,SetOpt7n
			b 144,151			;"Dez. Tab#4".
			w  32, 39,DefOpt7j,SetOpt7d
			b 143,155			;"Pos. Tab#4".
			w  78,102,DefOpt7k,SetOpt7o
			b  96,103			;"Dez. Tab#5".
			w 112,119,DefOpt7l,SetOpt7e
			b  95,107			;"Pos. Tab#5".
			w 159,183,DefOpt7m,SetOpt7p
			b 112,119			;"Dez. Tab#6".
			w 112,119,DefOpt7n,SetOpt7f
			b 111,123			;"Pos. Tab#6".
			w 159,183,DefOpt7o,SetOpt7q
			b 128,135			;"Dez. Tab#7".
			w 112,119,DefOpt7p,SetOpt7g
			b 127,139			;"Pos. Tab#7".
			w 159,183,DefOpt7q,SetOpt7r
			b 144,151			;"Dez. Tab#8".
			w 112,119,DefOpt7r,SetOpt7h
			b 143,155			;"Pos. Tab#8".
			w 159,183,DefOpt7s,SetOpt7s
			b NULL

:V200l7			b  80, 87			;"Dateien verbinden".
			w  32, 39,DefOpt8a,SetOpt8a
			b 104,111
			w  32, 39,DefOpt8b,SetOpt8b
			b 120,127
			w  32, 39,DefOpt8c,SetOpt8c
			b 136,143
			w  32, 39,DefOpt8d,SetOpt8d
			b NULL

;*** Parameter für Zahleneingabe.
:V200m0			w V200n0 ,V200n1
			w V200n2 ,V200n3 ,V200n4
			w V200n5 ,V200n6 ,V200n7 ,V200n8
			w V200n9 ,V200n10,V200n11,V200n12

:V200n0			w 120				;Nr. der ersten Seite.
			b  92,3
			w DOS_GW_1Page
			w HEXtoASCII,ASCIItoHEX
			w ChkInput_a
			b $00

:V200n1			w 139				;Max. Seitenlänge.
			b 145,3
			w LinesPerPage
			w HEXtoASCII_3,ASCIItoHEX
			w ChkInput_b
			b $00

:V200n2			w 134				;Linker Rand.
			b 57,2
			w GW_LRand
			w HEXtoASCII_1,ASCIItoHEX_1
			w ChkInput_c
			b $ff

:V200n3			w 162				;Rechter Rand.
			b 57,2
			w GW_RRand
			w HEXtoASCII_2,ASCIItoHEX_1
			w ChkInput_d
			b $ff

:V200n4			w 134				;Absatz.
			b 73,2
			w GW_Absatz
			w HEXtoASCII_1,ASCIItoHEX_1
			w ChkInput_c
			b $ff

:V200n5			w 81				;Tabulator #1.
			b 97,2
			w GW_TabBase+0
			w HEXtoASCII_2,ASCIItoHEX_1
			w ChkInput_e
			b $ff

:V200n6			w 81				;Tabulator #2.
			b 113,2
			w GW_TabBase+2
			w HEXtoASCII_2,ASCIItoHEX_1
			w ChkInput_e
			b $ff

:V200n7			w 81				;Tabulator #3.
			b 129,2
			w GW_TabBase+4
			w HEXtoASCII_2,ASCIItoHEX_1
			w ChkInput_e
			b $ff

:V200n8			w 81				;Tabulator #4.
			b 145,2
			w GW_TabBase+6
			w HEXtoASCII_2,ASCIItoHEX_1
			w ChkInput_e
			b $ff

:V200n9			w 162				;Tabulator #5.
			b 97,2
			w GW_TabBase+8
			w HEXtoASCII_2,ASCIItoHEX_1
			w ChkInput_e
			b $ff

:V200n10		w 162				;Tabulator #6.
			b 113,2
			w GW_TabBase+10
			w HEXtoASCII_2,ASCIItoHEX_1
			w ChkInput_e
			b $ff

:V200n11		w 162				;Tabulator #7.
			b 129,2
			w GW_TabBase+12
			w HEXtoASCII_2,ASCIItoHEX_1
			w ChkInput_e
			b $ff

:V200n12		w 162				;Tabulator #8.
			b 145,2
			w GW_TabBase+14
			w HEXtoASCII_2,ASCIItoHEX_1
			w ChkInput_e
			b $ff

;*** Daten-Listen für Zahlenausgabe.
:V200o0			w V200p0 ,V200p1
			w V200p2 ,V200p3 ,V200p4
			w V200p5 ,V200p6 ,V200p7 ,V200p8
			w V200p9 ,V200p10,V200p11,V200p12

:V200p0			w 120
			b  98
			w PrnOpt1Num

:V200p1			w 139
			b 151
			w PrnOpt1Num

:V200p2			w 134
			b  63
			w PrnOpt8Num

:V200p3			w 162
			b  63
			w PrnOpt8Num

:V200p4			w 134
			b  79
			w PrnOpt8Num

:V200p5			w  81
			b 103
			w PrnTab1Opt

:V200p6			w  81
			b 119
			w PrnTab1Opt

:V200p7			w  81
			b  135
			w PrnTab1Opt

:V200p8			w  81
			b 151
			w PrnTab1Opt

:V200p9			w 162
			b 103
			w PrnTab1Opt

:V200p10		w 162
			b 119
			w PrnTab1Opt

:V200p11		w 162
			b 135
			w PrnTab1Opt

:V200p12		w 162
			b 151
			w PrnTab1Opt

;*** Fehler: "Keine Tabellen auf Start-Diskette!"
:V200q0			b $01
			b 56,127
			w 64,255
			b OK        , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
:V200q1			w $ffff
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V200q6
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V200q2			b PLAINTEXT,BOLDON
			b "Keine Druckertreiber",NULL
:V200q3			b PLAINTEXT,BOLDON
			b "Keine Zeichensätze",NULL
:V200q4			b PLAINTEXT,BOLDON
			b "Keine Tabellen",NULL
:V200q5			b PLAINTEXT,BOLDON
			b "Keine Tabellen",NULL
:V200q6			b "auf Start-Diskette!",NULL

:V200r0			b $00				;Anzahl Laufwerke.
:V200r1			b $00				;$01 = Partitionswechsel erlaubt.
:V200r2			b "Laufwerk A:     "
			b "Laufwerk B:     "
			b "Laufwerk C:     "
			b "Laufwerk D:     "
:V200r3			b "Partitionen     "
:V200r4			b $00
:V200r5			b PLAINTEXT
			b "Aktive Partition ist "
:V200r6			b "x:",NULL

;******************************************************************************
;*** Speicher für ersten Eintrag bei Auswahlbox.
:V201z0			s 16

;******************************************************************************
:Memory
