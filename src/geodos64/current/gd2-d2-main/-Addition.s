; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Wert 2 zu r15 addieren.
; Datum			: 14.11.18
; Aufruf		: JSR  Add_2_r15
; Übergabe		: r15	Word 16Bit-Zahl
; Rückgabe		: r15	Word 16Bit-Zahl
; Verändert		: AKKU
;			  r15
; Variablen		: -
; Routinen		: -
;******************************************************************************

;******************************************************************************
; Funktion		: Wert 16 zu r15 addieren.
; Datum			: 14.11.18
; Aufruf		: JSR  Add_16_r15
; Übergabe		: r15	Word 16Bit-Zahl
; Rückgabe		: r15	Word 16Bit-Zahl
; Verändert		: AKKU
;			  r15
; Variablen		: -
; Routinen		: -
;******************************************************************************

;*** Wert zu r15 addieren.
.Add_2_r15		lda	#2
			b $2c
.Add_16_r15		lda	#16
			clc
			adc	r15L
			sta	r15L
			bcc	:1
			inc	r15H
::1			rts
