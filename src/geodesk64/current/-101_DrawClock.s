; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Aktuelle Uhrzeit ausgeben.
.DrawClock		jsr	ResetFontGD		;Zeichensatz aktivieren.

;--- Bildschirmausgabe vorbereiten.
			jsr	WM_NO_MARGIN		;Textgrenzen löschen.

;--- Position für Datum setzen.
			LoadW	r11,MAX_AREA_BAR_X-$3f +3
			LoadB	r1H,MIN_AREA_BAR_Y +7

;--- Datum ausgeben.
			lda	day
			jsr	:prntNum
			lda	#"."
			jsr	SmallPutChar
			lda	month
			jsr	:prntNum
			lda	#"."
			jsr	SmallPutChar
			lda	millenium
			jsr	:prntNum
			lda	year
			jsr	:prntNum

			lda	#" "
			jsr	SmallPutChar

;--- Position für Uhrzeit setzen.
			LoadW	r11,MAX_AREA_BAR_X-$3f +3
			LoadB	r1H,MIN_AREA_BAR_Y +14

;--- Uhrzeit ausgeben.
			lda	hour
			jsr	:prntNum
			lda	#":"
			jsr	SmallPutChar
			lda	minutes
			jsr	:prntNum
			lda	#"."
			jsr	SmallPutChar
			lda	seconds
			jsr	:prntNum

			lda	#" "
			jmp	SmallPutChar

;--- Dezimal-Zahl 00-99 ausgeben.
::prntNum		jsr	DEZ2ASCII		;Zahl von DEZ nach ASCII wandeln.
			pha
			txa
			jsr	SmallPutChar		;10er ausgeben.
			pla
			jmp	SmallPutChar		;1er ausgeben.
