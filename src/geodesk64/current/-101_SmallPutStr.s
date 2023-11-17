; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Text ausgebene.
;    Übergabe: r0  = Zeiger auf String.
;              r1H = Y-Position.
;              r11 = X-Position.
;Hinweis:
;Im Gegensatz zu PutString werden hier
;Sonderzeichen ausgefiltert.
.smallPutString		ldy	#$00			;Zeiger auf nächstes Zeichen.
			lda	(r0L),y			;Zeichen einlesen.
			beq	:exit			; => String-Ende...
			cmp	#$a0			;SHIFT+SPACE?
			beq	:3			; => Zeichen überspringen.
							;Umgeht Problem mit $A0 im Namen.
			and	#%01111111		;Unter GEOS nur Zeichen $20-$7E.
			cmp	#$20			;ASCII < $20?
			bcc	:1			; => Ja, Zeichen ersetzen.
			cmp	#$7f			;ASCII < $7F?
			bcc	:2			; => Ja, weiter...

::1			lda	#GD_REPLACE_CHAR	;Zeichen ersetzen.
::2			jsr	SmallPutChar		;Zeichen ausgeben.

::3			inc	r0L			;Zeiger auf nächstes Zeichen.
			bne	smallPutString
			inc	r0H
			jmp	smallPutString		;Nächstes Zeichen ausgeben.

::exit			rts
