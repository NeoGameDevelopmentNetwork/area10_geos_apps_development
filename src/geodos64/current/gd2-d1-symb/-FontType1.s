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
; Aufruf		: JSR  UseGDFont
; Übergabe		: -
; Rückgabe		: -
; Verändert		: AKKU,xReg,yReg
;			  r0
; Variablen		: -
; Routinen		: -
;******************************************************************************

;*** Neuen Zeichensatz aktivieren.
.UseGDFont		LoadW	r0,Font
			jmp	LoadCharSet

;*** Spezieller Zeichensatz für GeoDOS (7x8)
:Font			v 8,"fnt.GeoDOS #1"
