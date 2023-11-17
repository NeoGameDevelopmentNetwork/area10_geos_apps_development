; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Inline: Zeichenkette ausgeben.
:xi_PutString		pla				;Zeiger auf Inlne-Daten
			sta	r0L			;einlesen.
			pla
			sta	r0H
			jsr	SetNxByte_r0		;Zeiger auf nächstes Byte.

			ldy	#$00
			lda	(r0L),y			;Xlow-Koordinate einlesen.
			sta	r11L
			jsr	SetNxByte_r0		;Zeiger auf nächstes Byte.
			lda	(r0L),y			;Xhigh-Koordinate einlesen.
			sta	r11H
			jsr	SetNxByte_r0		;Zeiger auf nächstes Byte.
			lda	(r0L),y			;Y-Koordinate einlesen.
			sta	r1H
			jsr	SetNxByte_r0		;Zeiger auf erstes Zeichen.
			jsr	xPutString		;Text ausgeben.
			jsr	SetNxByte_r0		;Zeiger auf nächstes Byte.
			jmp	(r0)			;Zurück zum Programm.
