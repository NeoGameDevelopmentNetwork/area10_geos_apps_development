; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;Farbwert in Akku
;Y-Koordinaten r2L, r2H in Pixel
;X-Koordinaten r3, r4 in Pixel
:_DirectColor		pha

			ldy	#11
::1			lda	r2,y
			sta	ZeroBuffer,y
			dey
			bpl	:1

			ldx	#r3L
			jsr	NormalizeX
			ldx	#r4L
			jsr	NormalizeX
			pla
			sta	DoColBox80+1
			jsr	SetScr80Adr
			inc	r4L			;wegen DrawVDCLineFast
:DoColBox80		lda	#$00
			jsr	DrawVDCLineFast
			AddVW	80,r5			;nächste Zeile
			dec	r2H
			bne	DoColBox80

			ldy	#11
::1			lda	ZeroBuffer,y
			sta	r2,y
			dey
			bpl	:1
			rts
:ZeroBuffer		s	12

:SetScr80Adr		PushB	r2L
			jsr	SETr2L_r2H
::1			lda	#$40
			sta	r5H			;Highbyte von ATR-Adresse
::2			dec	r2L			;Y-Anfang
			beq	:3			;aufaddieren bis Anfangszeile
			AddVW	80,r5			;ereicht ist
			jmp	:2
::3			PopB	r2L
			rts

:SETr2L_r2H		sec
			lda	r2H			;Y-unten von Y-oben
			sbc	r2L			;abziehen - ergibt Höhe
			lsr				;geteilt durch 8 (8x8 Pixel)
			lsr
			lsr
			sta	r2H			;in r2H ist Höhe
			lda	r2L			;Y-oben
			lsr				;geteilt durch 8 (8x8 Pixel)
			lsr
			lsr
			sta	r2L			;in r2L ist Y-Anfang
			inc	r2L
			inc	r2H
:SETr5L_r4L		lda	r3L
			sta	r5L
			lda	r3H
			lsr				;r3 geteilt durch 8
			ror	r5L
			lsr
			ror	r5L
			lsr
			ror	r5L			;in r5L ist X-Anfang
			sec
			lda	r4L			;Weite berechnen
			sbc	r3L
			sta	r4L			;Weite in r4L
			lda	r4H
			sbc	r3H			;Weite high im Akku
			lsr				;geteilt druch 8
			ror	r4L
			lsr
			ror	r4L
			lsr
			ror	r4L			;Weite in r4L
			rts

:DrawVDCLineFast	ldx	#18
			stx	$d600
			ldx	r5H
::1			bit	$d600
			bpl	:1
			stx	$d601
			ldx	#19
			stx	$d600
			ldx	r5L
::2			bit	$d600
			bpl	:2
			stx	$d601
			ldx	#31
			stx	$d600
::3			bit	$d600
			bpl	:3
			sta	$d601
			lda	r4L			;Breite der Linie
			sec				;1 abziehen da 1 Byte durch
			sbc	#1			;SetVDCScrByte schon gesetzt ist
			beq	:4			;>alle schon gesetzt dann Ende
			ldx	#30			;WordCount-Register setzen
			stx	$d600
::5			bit	$d600
			bpl	:5
			sta	$d601			;Anzahl setzen
::4			rts
