; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Fortschrittsanzeige.
;    Übergabe:  statusPos = Aktueller Eintrag.
;               statusMax = Max. Anzahl Einträge.
;    Variablen: STATUS_X      = Status-Box links.
;               STATUS_W      = Breite Status-Box.
;               STATUS_Y      = Status-Box oben.
;               STATUS_H      = Höhe Status-Box.
;               STATUS_CNT_W  = Breite Fortschrittsanzeige.
;               STATUS_CNT_X1 = Fortschrittsanzeige links.
;               STATUS_CNT_X2 = Fortschrittsanzeige rechts.
;               STATUS_CNT_Y1 = Fortschrittsanzeige oben.
;               STATUS_CNT_Y2 = Fortschrittsanzeige unten.
:_ext_PrntStat		ldx	statusPos		;Erster Eintrag?
			bne	:2			; => Nein, weiter...
::1			rts				; => Ja, nur Werte ausgeben.

;--- Speicherübersicht ausgeben.
::2			inx
			cpx	statusMax		;Mehr als ein Eintrag?
			bne	:3			; => Ja, weiter...

			lda	#$00
			sta	r8L			;Rest-Wert für %-Balken löschen
			sta	r8H			;für "Ganzen %-Balken füllen".
			beq	:4			;Fortschrittsanzeige darstellen.

;--- Prozentwert für Fortschrittsanzeige berechnen.
;Hier  : Breite > Max.Wert Dateien.
;Formel: (Breite * Max.Wert)/Anzahl.
;Wenn die Breite < Max.Wert ist, dann:
;Formel: Max.Wert/(Breite * Anzahl).
::3			LoadW	r3,STATUS_CNT_W
			ldx	statusPos
			cpx	statusMax		;Letzte Datei?
			bne	:3a			; => Nein, weiter...
			dex
::3a			stx	r5L
			ldx	#r3L
			ldy	#r5L
			jsr	BMult			;Breite_Balken * Datei-Nr.

			MoveB	statusMax,r5L
			ClrB	r5H
			ldx	#r3L
			ldy	#r5L
			jsr	Ddiv			;(Breite_Balken * Datei-Nr.)/Gesamt.

			lda	r3L			;Prozentwert = 0?
			ora	r3H
			beq	:1			; => Ja, nichts ausgeben.

			lda	r3L			;Füllwert für Fortschrittsanzeige
			clc				;berechnen.
			adc	#< STATUS_CNT_X1
			sta	r4L
			lda	r3H
			adc	#> STATUS_CNT_X1
			sta	r4H

			CmpWI	r4,STATUS_CNT_X2	;Füllwert > Breite_Balken?
			bcc	:5			; => Nein, weiter...

::4			LoadW	r4,STATUS_CNT_X2	;Max. Breite Füllwert setzen.

::5			lda	r8L			;Restwert = 0?
			ora	r8H
			beq	:6			; => Ja, weiter...

			CmpW	r4,STATUS_CNT_X2	;Fortschrittsbalken aktulisieren.
			bne	:6

			SubVW	3,r4			;Füllwert reduzieren. 100% noch
							;nicht erreicht, daher nicht den
							;ganzen Infobalken füllen.

::6			LoadB	r2L,STATUS_CNT_Y1
			LoadB	r2H,STATUS_CNT_Y2
			LoadW	r3,STATUS_CNT_X1

			lda	statusPat		;Füllmuster setzen.
			jsr	SetPattern

			jmp	Rectangle		;Fortschrittsanzeige.

;*** Status-Box anzeigen.
:_ext_InitIBox		lda	#$00			;Füllmuster löschen.
			jsr	SetPattern

			jsr	i_Rectangle		;Status-Box zeichnen.
			b	STATUS_Y
			b	(STATUS_Y + STATUS_H) -1
			w	STATUS_X
			w	(STATUS_X + STATUS_W) -1

			lda	#%11111111		;Rahmen für Status-Box.
			jsr	FrameRectangle

;--- Titelzeile.
			lda	C_RegisterBack		;Farbe für Status-Box.
			jsr	DirectColor

			jsr	i_Rectangle		;Titelzeile löschen.
			b	STATUS_Y
			b	STATUS_Y +15
			w	STATUS_X
			w	(STATUS_X + STATUS_W) -1

			lda	C_DBoxTitel		;Farbe für Titelzeile setzen.
			jmp	DirectColor

;*** Status-Box mit Fortschrittsbalken.
:_ext_InitStat		jsr	i_FrameRectangle	;Rahmen um Fortschrittsanzeige.
			b	STATUS_CNT_Y1 -1
			b	STATUS_CNT_Y2 +1
			w	STATUS_CNT_X1 -1
			w	STATUS_CNT_X2 +1
			b	%11111111

			jsr	i_Rectangle		;Fortschrittsanzeige löschen.
			b	STATUS_CNT_Y1
			b	STATUS_CNT_Y2
			w	STATUS_CNT_X1
			w	STATUS_CNT_X2

			lda	C_InputField		;Farbe für Fortschrittsanzeige.
			jsr	DirectColor

			jsr	ResetFontGD		;GD-Font aktivieren.

			LoadW	r11,STATUS_CNT_X1 -12
			LoadB	r1H,STATUS_CNT_Y1 +6
			LoadW	r0,infoTx0pct
			jsr	PutString

			LoadW	r11,STATUS_CNT_X2 +4
			LoadB	r1H,STATUS_CNT_Y1 +6
			LoadW	r0,infoTx100pct
			jmp	PutString

;*** Variablen.
:statusPos		b $00				;Aktueller Wert.
:statusMax		b $00				;Maximaler Wert.
:statusPat		b $02				;Pattern für Füllmuster.
:infoTx0pct		b "0%",NULL
:infoTx100pct		b "100%",NULL
