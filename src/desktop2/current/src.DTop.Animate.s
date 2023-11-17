; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Animation für Seitenwechsel.
:animatePageSlct	lda	r1L
			pha

			jsr	disableFileDnD
			jsr	testDiskChanged
			jsr	clearCurPadPage

::next			lda	#> AREA_PADPAGE_X0 +15
			sta	r4H
			lda	#< AREA_PADPAGE_X0 +15
			sta	r4L
			lda	#AREA_PADPAGE_Y1 -14
			sta	r11L
			pla
			pha
			sta	r1L
			tay
			lda	#$00
			sta	r1H
			lda	#$08
			sta	r1L
			tya
			bpl	:init

::back			lda	#> AREA_PADPAGE_X0 +95
			sta	r4H
			lda	#< AREA_PADPAGE_X0 +95
			sta	r4L
			lda	#AREA_PADPAGE_Y0
			sta	r11L
			lda	#$ff
			sta	r1H
			lda	#$f8
			sta	r1L

::init			lda	#%00000000		;Linienmuster.
			sta	r0L
			lda	#10			;Anzahl Animationen.
			sta	r0H

::step			lda	#> AREA_PADPAGE_X0
			sta	r3H
			lda	#< AREA_PADPAGE_X0
			sta	r3L
			lda	r0L
			jsr	HorizontalLine

			lda	r11L
			sta	r3L
			lda	#AREA_PADPAGE_Y1
			sta	r3H
			lda	r0L
			jsr	VerticalLine

			lda	r0L
			eor	#$ff
			sta	r0L
			bpl	:step

			lda	r1L
			clc
			adc	r4L
			sta	r4L
			lda	r1H
			adc	r4H
			sta	r4H

			sec
			lda	r11L
			sbc	r1L
			sta	r11L

			dec	r0H			;Animation beendet?
			bne	:step			; => Nein, weiter...

			lda	#ICON_PGNAV
			jsr	prntIconTab1

			pla
			sta	r1L
			rts
