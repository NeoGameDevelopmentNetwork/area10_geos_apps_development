; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;Routine:   ResetFontGD
;Parameter: -
;Rückgabe:  -
;Verändert: A,X,Y,r0
;Funktion:  Aktiviert GeoDesk-Zeichensatz.
;******************************************************************************
.ResetFontGD		lda	#ST_WR_FORE		;Nur in Vordergrund schreiben.
			sta	dispBufferOn

			ClrB	currentMode		;PLAINTEXT.

			LoadW	r0,FontG3		;Zeichensatz aktivieren.
			jmp	LoadCharSet
