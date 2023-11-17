; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** "Preferences" und "Pad Color Pref" anwenden.
:applyPrefData		lda	bufTrSePrefs +0
			beq	:padcol			; => Keine Prefs...
			sta	r1L
			lda	bufTrSePrefs +1
			sta	r1H

;--- Block mit Preferences einlesen.
			jsr	getDiskBlock
			jsr	exitOnDiskErr

;--- Vorgaben übernehmen.
			lda	diskBlkBuf +2
			sta	maxMouseSpeed
			lda	diskBlkBuf +3
			sta	minMouseSpeed
			lda	diskBlkBuf +4
			sta	mouseAccel

;--- Neue Hintergrundfarbe?
			lda	diskBlkBuf +5
			ora	diskBlkBuf +6
			cmp	screencolors
			beq	:2			; => Nein, weiter...

			sta	screencolors
			sta	:1			;Bildschirmfarbe
			jsr	i_FillRam		;setzen.
			w 1000
			w COLOR_MATRIX
::1			b $00

;--- Hinweis:
;Hier sollte zur Sicherheit der IRQ
;gesperrt werden.
::2			ldy	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA

;--- Mauszeiger/Cursor-Farbe übernehmen.
			lda	diskBlkBuf +7
			sta	mob0clr
			sta	mob1clr
			lda	diskBlkBuf +71
			sta	extclr

			sty	CPU_DATA

;--- Mauszeiger-Icon übernehmen.
			ldy	#63 -1
::3			lda	diskBlkBuf +8,y
			sta	mousePicData,y
			dey
			bpl	:3

;--- "Pad Color Pref"?
::padcol		lda	bufTrSePadCol +0
			beq	:endpref		; => Keine Farben...
			sta	r1L
			lda	bufTrSePadCol +1
			sta	r1H

;--- Block mit Farbdaten einlesen.
			jsr	getDiskBlock
			jsr	exitOnDiskErr

;--- Farbdaten übernehmen.
			ldx	#$08			;Icon-Farben setzen.
::4			lda	diskBlkBuf +2,x
			sta	PADCOLDATA,x
			dex
			bpl	:4

;--- DeskPad neu zeichnen.
			jsr	drawDeskPadCol

::endpref		rts
