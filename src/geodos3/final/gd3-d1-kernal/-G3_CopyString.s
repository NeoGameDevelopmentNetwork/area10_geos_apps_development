; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** String kopieren. (Akku =$00 bis zum $00-Byte, <>$00 = Anzahl Zeichen).
;    Akku =  $00, Ende durch $00-Byte.
;    Akku <> $00, Anzahl Zeichen.
:xCopyString		lda	#$00
:xCopyFString		stx	:1 +1
			sty	:2 +1
			tax
			ldy	#$00
::1			lda	(r4L),y
::2			sta	(r5L),y
			bne	:3
			txa
			beq	:4
::3			iny
			beq	:4
			txa
			beq	:1
			dex
			bne	:1
::4			rts
