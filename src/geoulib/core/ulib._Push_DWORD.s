; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; ULIB: DWORD an UCI senden
;
;Übergabe : X = Zeiger auf Zeropage
;Rückgabe : -
;Verändert: A,X,Y

:ULIB_PUSH_DWORD	ldy	#0
;			ldx	#r0
::1			lda	ZPAGE,x			;DWORD (4 Bytes) an UCI senden.
			sta	UCI_COMDATA
			inx
			iny
			cpy	#4
			bcc	:1
			rts
