; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Zeichen nach GEOS-ASCII wandeln.
; Datum			: 02.07.97
; Aufruf		: JSR  ConvertChar
; Übergabe		: AKKU	Byte Textzeichen
; Rückgabe		: AKKU	Byte GEOS-Textzeichen
; Verändert		: AKKU
; Variablen		: -
; Routinen		: -
;******************************************************************************

;*** Zeichen nach GEOS-ASCII wandeln.
.ConvertChar		cmp	#$00
			beq	:101
			cmp	#$a0
			bne	:102
::101			lda	#" "
::102			cmp	#$20
			bcc	:101
			cmp	#$7f
			bcc	:103
			sbc	#$20
			jmp	:102
::103			rts
