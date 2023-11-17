; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Neuen Zeichensatz aktivieren.
; Datum			: 02.07.97
; Aufruf		: JSR  UseMiniFont
; Übergabe		: -
; Rückgabe		: -
; Verändert		: AKKU,xReg,yReg
;			  r0
; Variablen		: -
; Routinen		: -
;******************************************************************************

;*** Neuen Zeichensatz aktivieren.
.UseMiniFont		LoadW	r0,MiniFont
			jmp	LoadCharSet

;*** Spezieller Zeichensatz für GeoDOS (7x8)
:MiniFont		v 7,"fnt.GeoDOS #2"
