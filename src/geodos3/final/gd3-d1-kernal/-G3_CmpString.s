; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** String + NULL-Byte vergleichen.
;    Akku =  $00, Ende durch $00-Byte.
;    Akku <> $00, Anzahl Zeichen.
:xCmpString		lda	#$00
:xCmpFString		stx	:1 +1
			sty	:2 +1
			tax
			ldy	#$00
::1			lda	(r5L),y
::2			cmp	(r1L),y
			bne	:4
			cmp	#$00
			bne	:3
			txa
			beq	:4
::3			iny
			beq	:4
			txa
			beq	:1
			dex
			bne	:1
			txa
::4			rts
