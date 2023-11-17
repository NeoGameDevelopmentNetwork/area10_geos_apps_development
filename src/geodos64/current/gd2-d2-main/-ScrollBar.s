; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Auswahltabelle
; Datum			: 02.07.97
; Aufruf		: JSR  DoFileBox
; Übergabe		: r0 = Zeiger auf Datentabelle.
;			  b    Zeiger auf xPos									(in CARDS!)
;			  b    Zeiger auf yPos									(in PIXEL!)
;			  b    max. Länge des Balken								(in PIXEL!)
;			  b    max. Anzahl Einträge in Tabelle.
;			  b    max. Einträge auf einer Seite.
;			  b    Tabellenzeiger = Nr. der ersten Datei auf der Seite!
;
;'InitBalken'		Muß als erstes aufgerufen werden um die Daten (r0-r2) für
;			den Anzeigebalken zu definieren und den Balken auf dem
;			Bildschirm auszugeben.
;'SetPosBalken'		Setzt den Füllbalken auf neue Position. Dazu muß im AKKU die
;			neue Position des Tabellenzeigers übergeben werden.
;'PrintBalken'		Zeichnet den Anzeige- und Füllbalken erneut. Dazu muß aber
;			vorher mindestens 1x 'InitBalken' aufgerufen worden sein!
;'ReadSB_Data'		Übergibt folgende Werte an die aufrufende Routine:
;			r0L = SB_XPosByte X-Position Balken in CARDS.
;			r0H = SB_YPosByte Y-Position in Pixel.
;			r1L = SB_MaxYlen									Byte Länge des Balkens.
;			r1H = SB_MaxEntry									Byte Anzahl Einträge in Tabelle.
;			r2L = SB_MaxEScr									Byte Anzahl Einträge auf Seite.
;			r2H = SB_PosEntry									Byte Aktuelle Position in Tabelle.
;			r3  = SB_PosTopWord Startadresse im Grafikspeicher.
;			r4L = SB_TopByte Oberkante Füllbalken.
;			r4H = SB_EndByte Unterkante Füllbalken.
;			r5L = SB_LengthByte Länge Füllbalken.
;'IsMseOnPos'		Mausklick auf Anzeigebalken auswerten. Ergebnis im AKKU:
;			$01 = Mausklick Oberhalb Füllbalken.
;			$02 = Mausklick auf Füllbalken.
;			$03 = Mausklick Unterhalb Füllbalken.
;'StopMouseMove'	Schränkt Mausbewegung ein.
;'SetRelMouse'		Setzt neue Mausposition. Wird beim Verschieben des
;			Füllbalkens benötigt. Vorher muß ein 'JSR SetPosBalken'
;			erfolgen!
;******************************************************************************

;*** Variablen.
:SB_XPos		b $00				;r0L
:SB_YPos		b $00				;r0H
:SB_MaxYlen		b $00				;r1L
:SB_MaxEntry		b $00				;r1H
:SB_MaxEScr		b $00				;r2L
:SB_PosEntry		b $00				;r2H

:SB_PosTop		w $0000				;r3
:SB_Top			b $00				;r4L
:SB_End			b $00				;r4H
:SB_Length		b $00				;r5L

;*** Balken initialiseren.
.InitBalken		ldy	#$05			;Paraeter speichern.
::101			lda	(r0L),y
			sta	SB_XPos,y
			dey
			bpl	:101

			jsr	Anzeige_Ypos		;Position des Anzeigebalkens berechnen.
			jsr	Balken_Ymax		;Länge des Füllbalkens anzeigen.

			lda	SB_XPos
			sta	:102 +0
			sta	:103 +0
			sta	:104 +0

			lda	SB_YPos			;Position für "UP"-Icon berechnen.
			sub	8
			sta	:102 +1
			lsr
			lsr
			lsr
			sta	:104 +1

			lda	SB_YPos			;Position für "DOWN"-Icon berechnen.
			adda	SB_MaxYlen
			sta	:103 +1

			lda	SB_MaxYlen
			lsr
			lsr
			lsr
			add	2
			sta	:104 +3

			jsr	i_BitmapUp		;"UP"-Icon ausgeben.
			w	Icon_UP
::102			b	$19,$ff,$01,$08

			jsr	i_BitmapUp		;"DOWN"-Icon ausgeben.
			w	Icon_DOWN
::103			b	$19,$ff,$01,$08

			jsr	i_C_Balken
::104			b	$00,$00,$01,$00

			jmp	PrintBalken		;Balken ausgeben.

;*** Neue Balkenposition defnieren und anzeigen.
.SetPosBalken		sta	SB_PosEntry		;Neue Position Füllbalken setzen.

;*** Balken ausgeben.
.PrintBalken		jsr	Balken_Ypos		;Y-Position für Füllbalken berechnen.

			MoveW	SB_PosTop,r0		;Grafikposition berechnen.
			ClrB	r1L			;Zähler für Balkenlänge löschen.

			lda	SB_YPos			;Zeiger innerhalb Grafik-CARD be-
			and	#%00000111		;rechnen (Wert von $00-$07).
			tay

::101			lda	SB_Length		;Balkenlänge = $00 ?
			beq	:104			;Ja, kein Füllbalken anzeigen.

			ldx	r1L
			cpx	SB_Top			;Anfang Füllbalken erreicht ?
			beq	:103			;Ja, Quer-Linie ausgeben.
			bcc	:104			;Kleiner, dann Hintergrund ausgeben.
			cpx	SB_End			;Ende Füllbalken erreicht ?
			beq	:103			;Ja, Quer-Linie ausgeben.
			bcs	:104			;Größer, dann Hintergrund ausgeben.
			inx
			cpx	SB_MaxYlen		;Ende Anzeigebalken erreicht ?
			beq	:104			;Ja, Quer-Linie ausgeben.

::102			lda	#%11100111		;Wert für Füllbalken.
			b $2c
::103			lda	#%11111111
			b $2c
::104			lda	#%10000001
::105			sta	(r0L),y			;Byte in Grafikspeicher schreiben.
			inc	r1L
			CmpB	r1L,SB_MaxYlen		;Gesamte Balkenlänge ausgegeben ?
			beq	:106			;Ja, Abbruch...

			iny
			cpy	#8			;8 Byte in einem CARD gespeichert ?
			bne	:101			;Nein, weiter...

			AddVW	320,r0			;Zeiger auf nächstes CARD berechnen.
			ldy	#$00
			beq	:101			;Schleife...
::106			rts				;Ende.

;*** Position des Anzeigebalken berechnen.
:Anzeige_Ypos		MoveB	SB_XPos,r0L
			LoadB	r0H,NULL
			ldx	#r0L
			ldy	#$03
			jsr	DShiftLeft
			AddVW	SCREEN_BASE,r0
			lda	SB_YPos
			lsr
			lsr
			lsr
			tay
			beq	:102
::101			AddVW	40*8,r0
			dey
			bne	:101
::102			MoveW	r0,SB_PosTop
			rts

;*** Länge des Balken berechnen.
:Balken_Ymax		lda	#$00
			ldx	SB_MaxEScr
			cpx	SB_MaxEntry
			bcs	:101
			MoveB	SB_MaxYlen,r0L
			MoveB	SB_MaxEScr,r1L
			jsr	Mult_r0r1
			MoveB	SB_MaxEntry,r1L
			jsr	Div_r0r1
			CmpBI	r0L,8
			bcs	:101
			lda	#$08
::101			sta	SB_Length
			rts

;*** Position des Balken berechnen.
:Balken_Ypos		ldx	#NULL
			ldy	SB_Length
			CmpB	SB_MaxEScr,SB_MaxEntry
			bcs	:101

			MoveB	SB_PosEntry,r0L
			lda	SB_MaxYlen
			suba	SB_Length
			sta	r1L
			jsr	Mult_r0r1
			lda	SB_MaxEntry
			suba	SB_MaxEScr
			sta	r1L
			jsr	Div_r0r1
			lda	r0L
			tax
			adda	SB_Length
			tay
::101			stx	SB_Top
			dey
			sty	SB_End
			rts

:Mult_r0r1		ldx	#r0L			;Multiplikation durchführen.
			ldy	#r1L
			jmp	BBMult

:Div_r0r1		LoadB	r1H,NULL		;Division durchführen.
			ldx	#r0L
			ldy	#r1L
			jmp	Ddiv

;*** Balken initialiseren.
.ReadSB_Data		ldx	#$0a
::101			lda	SB_XPos,x
			sta	r0L,x
			dex
			bpl	:101
			rts

;*** Mausklick überprüfen.
.IsMseOnPos		lda	mouseYPos
			suba	SB_YPos
			cmp	SB_Top
			bcc	:103
::101			cmp	SB_End
			bcc	:102
			lda	#$03
			b $2c
::102			lda	#$02
			b $2c
::103			lda	#$01
			rts

;*** Mausbewegung kontrollieren.
.StopMouseMove		lda	mouseXPos +0
			sta	mouseLeft +0
			sta	mouseRight+0
			lda	mouseXPos +1
			sta	mouseLeft +1
			sta	mouseRight+1
			lda	mouseYPos
			jmp	SetNewRelMse
.SetRelMouse		lda	#$ff
			adda	SB_Top
:SetNewRelMse		sta	mouseTop
			sta	mouseBottom
			suba	SB_Top
			sta	SetRelMouse+1
			rts

;*** Systemicons.
.Icon_UP		;$01 x $08
<MISSING_IMAGE_DATA>

.Icon_DOWN		;$01 x $08
<MISSING_IMAGE_DATA>
