; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Maus im Border-Bereich?
:isMseAreaBorder	jsr	u_IsMseInRegion
			b AREA_BORDER_Y0,AREA_BORDER_Y1
			w AREA_BORDER_X0,AREA_BORDER_X1
			rts

;*** maus im Dateifenster?
:isMseAreaPadPage	jsr	u_IsMseInRegion
			b AREA_PADPAGE_Y0,AREA_PADPAGE_Y1
			w AREA_PADPAGE_X0,AREA_PADPAGE_X1
			rts

;*** Inline-Routine für ":IsMseInRegion".
;Inline:   b yo,yu  = Y-Koordinate oben/unten.
;          w xl,xr  = X-Koordinate links/rechts.
;Rückgabe: siehe ":IsMseInRegion".
.u_IsMseInRegion	pla
			sta	returnAddress +0
			pla
			sta	returnAddress +1

			ldy	#$01
			lda	(returnAddress),y
			sta	r2L
			iny
			lda	(returnAddress),y
			sta	r2H
			iny

			lda	(returnAddress),y
			sta	r3L
			iny
			lda	(returnAddress),y
			sta	r3H
			iny

			lda	(returnAddress),y
			sta	r4L
			iny
			lda	(returnAddress),y
			sta	r4H
			jsr	IsMseInRegion

			php
			lda	#6 +1
			jmp	DoInlineReturn
