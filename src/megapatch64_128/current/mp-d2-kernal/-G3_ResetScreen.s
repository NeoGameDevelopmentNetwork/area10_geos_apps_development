; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Grafikspeicher (Vordergrund!) löschen, Farben zurücksetzen.
.xResetScreen		php
			sei

if Flag64_128 = TRUE_C64
			ldx	CPU_DATA
			lda	#%00110101
			sta	CPU_DATA

			lda	C_GEOS_MOUSE
			sta	mob0clr
			sta	mob1clr

			lda	C_GEOS_FRAME
			sta	extclr

			stx	CPU_DATA
endif

			lda	#ST_WR_FORE
			sta	dispBufferOn

			lda	#$02
			jsr	SetPattern

if Flag64_128 = TRUE_C64
			lda	C_GEOS_BACK
			sta	screencolors

			jsr	i_UserColor
			b	$00,$00,$28,$19

			jsr	i_Rectangle
			b	$00,$c7
			w	$0000,$013f
else
			lda	C_GEOS_BACK
			bit	graphMode
			bpl	:1
			sta	scr80colors
			jsr	xSet_C_FarbTab		;MP3-Farbtabelle wechseln (VIC/VDC)
			lda	C_GEOS_BACK
::1			sta	screencolors

			lda	C_GEOS_MOUSE
			sta	mob0clr
			sta	mob1clr
			lda	C_GEOS_FRAME
			sta	extclr

			jsr	xSet_C_FarbTab		;MP3-Farbtabelle wechseln (VIC/VDC)
			bit	graphMode
			bmi	:2
			lda	C_GEOS_BACK
			sta	scr80colors
			jsr	xSet_C_FarbTab		;MP3-Farbtabelle wechseln (VIC/VDC)

::2			bit	graphMode
			bmi	:3
			jsr	i_Rectangle
			b	$00,$c7
			w	$0000,$013f
			lda	screencolors
			jmp	:4
::3			jsr	i_Rectangle
			b	$00,$c7
			w	0,639
			lda	scr80colors
::4			jsr	DirectColor
endif

			plp
			rts
