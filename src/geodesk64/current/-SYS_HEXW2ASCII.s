; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** HEX-WORD nach ASCII konvertieren.
;    Übergabe: r0 = Hex-Zahl als WORD.
;    Rückgabe: r1 = 4 ASCII-zeichen für Hex-Zahl/WORD.
:HEXW2ASCII		lda	r0L			;LOW-Byte zwischenspeichern.
			pha

			lda	r0H			;HIGH-Byte einlesen und
			jsr	HEX2ASCII		;nach ASCII wandeln.

			ldy	#$01
			sta	(r1L),y			;LOW-Nibble HIGH-Byte.
			dey
			txa
			sta	(r1L),y			;HIGH-Nibble HIGH-Byte.

			pla				;LOW-Byte einlesen und
			jsr	HEX2ASCII		;nach ASCII wandeln.

			ldy	#$03
			sta	(r1L),y			;LOW-Nibble LOW-Byte.
			dey
			txa
			sta	(r1L),y			;HIGH-Nibble LOW-Byte.
			rts
