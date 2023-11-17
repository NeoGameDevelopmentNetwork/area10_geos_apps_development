; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Textausgabe
; Datum			: 02.07.97
; Aufruf		: JSR  PutXYText									 Text an Y-Position ausgeben
; Übergabe		: yReg	Byte Y-Koordinate
;			  AKKU,xRegWord Zeigfer auf Textstring
; Rückgabe		: Bildschirmausgabe
; Verändert		: AKKU,xReg,yReg
;			  r0 ,r1L
;			  r2  bis r10
;			  r12 und r13
; Variablen		: -
; Routinen		: -PutString String ausgeben
;******************************************************************************

;*** Textausgabe.
.PutXYText		sty	r1H
.PutText		sta	r0L
			stx	r0H
			jmp	PutString
