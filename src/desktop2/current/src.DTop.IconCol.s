; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Farbe für alle Icons zeichnen.
:drawDeskPadICol	lda	diskOpenFlg		;Diskette geöffnet
			and	flagDiskRdy		;und gültig?
			beq	:exit			; => Nein, Ende..
			lda	a7L			;Icon-Modus?
			bne	:exit			; => Nein, Ende...
			lda	#ICON_PAD +7
::1			pha
			jsr	drawIconColor
			pla
			sec
			sbc	#$01
			bpl	:1
::exit			rts

;*** Farbe für ein Icon zeichnen.
:drawIconColor		sta	r0L
			jsr	testIconExist
			beq	exit2
			lda	r0L
			ldx	#r5L
			jsr	setVecIcon2File
			ldy	#$16			;GEOS-Dateityp
			lda	(r5L),y			;einlesen.
			jsr	getFIconColor
			sta	r5L
			lda	DESKPADCOL
			and	#%00001111
			ora	r5L
			ldy	r0L
			clv
			bvc	setIconColor

;*** Farbe für ein Icon löschen.
:drawIconNoColor	tay
			lda	DESKPADCOL

;*** Farbe für Icon setzen.
:setIconColor		jsr	isGEOS_V2		;Älter als GEOS V2?
			bcc	exit2			; => Keine Farben...

			jsr	testCurViewMode
			bcc	exit2			; => Text-Modus...
			sta	r0L

			lda	tabIconPosXH,y
			sta	r5H
			lda	tabIconPosXL,y
			sta	r5L

			ldx	#$03			;3 Cards hoch.
::1			ldy	#$00
			lda	r0L
::2			sta	(r5L),y
			iny
			cpy	#$03			;3 Cards breit.
			bne	:2

			lda	r5L			;Zeiger auf nächste
			clc				;Zeile setzen.
			adc	#$28
			sta	r5L
			bcc	:3
			inc	r5H

::3			dex				;3x3 Cards?
			bne	:1			; => Nein, weiter...

:exit2			rts

;*** Farbe für GEOS-Dateityp-Icon einlesen.
;Ein byte beinhaltet zwei Farben im
;High- und Low-Nibble.
:getFIconColor		lsr
			tay
			lda	PADCOLDATA,y
			bcs	:1
			asl
			asl
			asl
			asl
::1			and	#%11110000
			rts
