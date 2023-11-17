; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Hinweis:
;":xSendComVLen" muss am Anfang der
;Quelltext-Datei stehen, da andere
;Dateien vor dem Include-Befehl "t"
;ein externes Label ergänzen!

;*** Floppy-Befehl mit variabler Länge an Laufwerk senden.
;    Übergabe:		AKKU	= Low -Byte, Zeiger auf Floppy-Befehl.
;			xReg	= High-Byte, Zeiger auf Floppy-Befehl.
;			yReg	= Länge (Zeichen) Floppy-Befehl.
;    Rückgabe:    Z-Flag = 1: OK
;                 Z-Flag = 0: Fehler
;                 xReg   = Fehler-Status
:xSendComVLen		sta	:51 +1			;Zeiger auf Floppy-Befehl sichern.
			stx	:51 +2
			sty	:52 +1

;			jsr	UNTALK			;Aufruf durch ":initDevLISTEN".

			jsr	initDevLISTEN		;Laufwerk auf Empfang schalten.
			bne	:53			;Fehler? => Ja, Abbruch...

			ldy	#$00
::51			lda	$ffff,y			;Bytes an Floppy-Laufwerk senden.
			jsr	CIOUT
			iny
::52			cpy	#$ff
			bcc	:51

			ldx	#NO_ERROR
::53			rts
