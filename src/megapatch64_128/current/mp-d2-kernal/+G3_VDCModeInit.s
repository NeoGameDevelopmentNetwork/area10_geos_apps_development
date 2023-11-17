; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;Initialisierung des VDC Farbmodus
;insgesamt stehen 4 Modi zur Verfügung
;Modi-Übergabe im Akku (0 bis 4)
;Jetzt bei MP3:		Modi 0 und 1 nicht mehr vorhanden
;			anstatt dessen wird immer auf Modus 2
;			geschaltet. Modus 3 und 4 sind möglich!
;0 = Stand-Modus:	640 * 200 Pixelkeine Farbe (ATR aus)
;1 = Farb-Modus:	640 * 176 PixelFarbe: 8*8 Pixel ($3880)	1760
;2 = Farb-Modus:	640 * 200 PixelFarbe: 8*8 Pixel ($4000)	2000
;3 = Farb-Modus:	640 * 200 PixelFarbe: 8*4 Pixel ($4000)	4000
;4 = Farb-Modus:	640 * 200 PixelFarbe: 8*2 Pixel ($4000)	8000

:_VDC_ModeInit		cmp	#0
			bcc	:2			;>kleiner als 0 nicht möglich
			cmp	#5
			bcc	:1			;>größer als 4 nicht möglich
::2			rts
::1			cmp	#2
			bcs	:1a			;>Modus 3 bis 5
			lda	#2			;>Modus 0 oder 1 dann auf 2
::1a			ldx	#0			;Flag für gleicher Modus lösch.
			cmp	vdcClrMode		;gleicher Modus?
			bne	:1b			;>nein
			ldx	#1			;Flag für gleicher Modus setzen
::1b			stx	:ModeFlag+1		;Flag setzen
			sta	vdcClrMode		;Modus sichern
			bit	graphMode
			bpl	:2			;>bei 40Zeichen Rücksprung
			tay				;Tabellenpointer nach r0 holen
			dey
			dey
			lda	VDCPointTab_low,y
			sta	r0L
			lda	VDCPointTab_high,y
			sta	r0H
			ldy	#0
::3			lda	(r0L),y
			iny
			cmp	#$ff
			beq	:6			;>fertig
			tax
			cpx	#25			;Register 25 initialisieren?
			bne	:4			;>nein
			lda	VDCBaseD600		;Status holen
			and	#%00000111
			beq	:4
			lda	(r0L),y
			ora	#%00000111
			sta	(r0L),y
::4			jsr	oGetVDC			;Registerinhalt holen
			cmp	(r0L),y			;mit Tabellenwert vergleichen
			beq	:5			;>gleich
			lda	(r0L),y			;>nicht gleich dann Tabellen-
			jsr	oSetVDC			; wert in Register schreiben
::5			iny
			bne	:3			;Schleife

::6			ldx	#28			;Register 28 auslesen
			jsr	oGetVDC
			and	#%11101111		;Bit4 (RAM-Typ) ausblenden
			tay
			lda	vdcClrMode		;welcher Farbmodus
			cmp	#2
			bcc	:7			;>0 oder 1
			tya				;>2 bis 4
			ora	#%00010000		;64K RAM-Bit maskieren
			tay
::7			tya				;RAM-Typ wieder setzen
			jsr	oSetVDC

			ldx	#26			;Farbe setzen
			lda	scr80colors
			lsr
			lsr
			lsr
			lsr
			jsr	oSetVDC

			ldx	#24			;Register 24 setzen
			lda	scr80polar
			jsr	oSetVDC

::ModeFlag		ldx	#0			;Modus-Flag testen
			beq	:non			;>neuer Screen-Modus
			rts				;>gleicher Screen-Modus
::non			lda	#0
			sta	r2L
			sta	r3L
			sta	r3H
			LoadB	r2H,199
			LoadW	r4,639
			lda	scr80colors
			jmp	_DirectColor

:VDCPointTab_high	b >VDC_Tab2,>VDC_Tab3,>VDC_Tab4
:VDCPointTab_low	b <VDC_Tab2,<VDC_Tab3,<VDC_Tab4

;:VDCPointTab_high	b >VDC_Tab0,>VDC_Tab1,>VDC_Tab2,>VDC_Tab3,>VDC_Tab4
;:VDCPointTab_low	b <VDC_Tab0,<VDC_Tab1,<VDC_Tab2,<VDC_Tab3,<VDC_Tab4

;:VDC_Tab0		b $04,$20,$06,$19,$07,$1c,$09,$e7
;			b $14,$38,$15,$80,$19,$87,$24,$f5,$ff

;:VDC_Tab1		b $04,$20,$06,$16,$07,$1c,$09,$e7
;			b $14,$38,$15,$80,$19,$c0,$24,$f5,$ff

;Tabellenaufbau Register/Wert Register/Wert ...
.VDC_Tab2		b $04,$20,$06,$19,$07,$1c,$09,$e7
			b $14,$40,$15,$00,$19,$c0,$24,$f5,$ff

.VDC_Tab3		b $04,$40,$06,$32,$07,$38,$09,$e3
			b $14,$40,$15,$00,$19,$c0,$24,$f4,$ff

.VDC_Tab4		b $04,$80,$06,$64,$07,$70,$09,$e1
			b $14,$40,$15,$00,$19,$c0,$24,$f2,$ff
