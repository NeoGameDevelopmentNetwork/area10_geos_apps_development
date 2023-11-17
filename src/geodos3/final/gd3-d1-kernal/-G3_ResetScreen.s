; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Grafikspeicher (Vordergrund!) löschen, Farben zurücksetzen.
:xResetScreen		php
			sei

			ldx	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA

			lda	C_GEOS_MOUSE
			sta	mob0clr
			sta	mob1clr

			lda	C_GEOS_FRAME
			sta	extclr

			stx	CPU_DATA

			lda	#ST_WR_FORE
			sta	dispBufferOn

			lda	#$02
			jsr	SetPattern

			lda	C_GEOS_BACK
			sta	screencolors

			jsr	i_UserColor
			b	$00,$00,$28,$19

			jsr	i_Rectangle
:MaxScrnArea		b	$00,$c7			;Wird auch in DoMenu als
			w	$0000,$013f		;als Datentabelle verwendet!

			plp
			rts
