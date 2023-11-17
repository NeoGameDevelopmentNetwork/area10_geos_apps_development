; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Hinweistext ausgeben.
:setSortInfo		lda	WM_DATA_MAXENTRY+0
if MAXENTRY16BIT = TRUE
			ldx	WM_DATA_MAXENTRY+1
			bne	:0
endif
			cmp	#SORTFILES_INFO		;Mehr als eine Datei?
			bcc	:3			; => Ja, weiter...

::0			ldy	#iconSort_x *8 -1	;Grafikdaten speichern.
::1			lda	SCREEN_BASE,y
			sta	iconDataBuf,y
			dey
			bpl	:1

			ldy	#iconSort_x -1		;Farbdaten speichern.
::2			lda	COLOR_MATRIX,y
			sta	iconColorBuf,y
			dey
			bpl	:2

			jsr	i_BitmapUp		;Hinweis ausgeben.
			w	iconSort
			b	$00,$00
			b	iconSort_x,iconSort_y

			lda	#$12
			jsr	i_UserColor
			b	$00,$00,iconSort_x,$01

::3			rts

;*** Hinweistext löschen.
:resetSortInfo		lda	WM_DATA_MAXENTRY+0
if MAXENTRY16BIT = TRUE
			ldx	WM_DATA_MAXENTRY+1
			bne	:0
endif
			cmp	#SORTFILES_INFO		;Meh als eine Datei?
			bcc	:3			; => Ja, weiter...

::0			ldy	#iconSort_x *8 -1	;Grafikdaten zurücksetzen.
::1			lda	iconDataBuf,y
			sta	SCREEN_BASE,y
			dey
			bpl	:1

			ldy	#iconSort_x -1		;Farbdaten zurücksetzen.
::2			lda	iconColorBuf,y
			sta	COLOR_MATRIX,y
			dey
			bpl	:2

::3			rts

;*** Hinweis-Icons.
if LANG = LANG_DE
:iconSort
<MISSING_IMAGE_DATA>

:iconSort_x		= .x
:iconSort_y		= .y
endif
if LANG = LANG_EN
:iconSort
<MISSING_IMAGE_DATA>

:iconSort_x		= .x
:iconSort_y		= .y
endif

:iconDataBuf		s iconSort_x * 8
:iconColorBuf		s iconSort_x
