; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Farbrechteck zeichnen.
			bit	graphMode
			bmi	:80
			jmp	ColorRecBox40

::80			PushW	r2
			PushW	r3
			PushW	r4
			PushW	r5
			PushW	r6
			lda	r5H			;Y-Anfang x 8
			asl
			asl
			asl
			sta	r2L
			lda	r6H			;Y-Höhe x 8
			asl
			asl
			asl
			clc
			adc	r2L
			sta	r2H
			dec	r2H

			LoadB	r3H,0
			lda	r5L			;X-Anfang x 8 + verdoppeln
			asl
			rol	r3H
			asl
			rol	r3H
			asl
			rol	r3H
			asl
			rol	r3H
			sta	r3L

			LoadB	r4H,0
			lda	r6L			;X-Breite x 8 + verdoppeln
			asl
			rol	r4H
			asl
			rol	r4H
			asl
			rol	r4H
			asl
			rol	r4H
			clc
			adc	r3L
			sta	r4L
			lda	r4H
			adc	r3H
			sta	r4H
			lda	r4L
			sec
			sbc	#1
			sta	r4L
			bcs	:1
			dec	r4H
::1			lda	r7L
			lsr
			lsr
			lsr
			lsr
			tay
			lda	VDCFarbtab,y
;--- Änderung: 17.07.18/M.Kanet
;Im bisherigen Code wurde die Vordergrundfarbe nicht
;richtig definiert. Dazu muss der Wert aus VDCFarbtab
;wieder um 4Bit nach links geschoben werden, damit
;die Bits 0-3 frei für die Hintergrundfarbe sind.
			asl
			asl
			asl
			asl
;---
			tax
			lda	r7L
			and	#%00001111
			tay
			txa
			ora	VDCFarbtab,y
			jsr	_DirectColor
			PopW	r6
			PopW	r5
			PopW	r4
			PopW	r3
			PopW	r2
			rts
