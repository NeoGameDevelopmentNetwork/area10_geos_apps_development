; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; ULIB: Datei-/Verzeichnisname senden
;
;Übergabe : r8 = Zeiger auf Textstring
;Rückgabe : -
;Verändert: A,Y

:ULIB_PUSH_NAME8	ldy	#0
::1			lda	(r8),y			;Zeichen einlesen.
			beq	:2			; => Ende-Kennung...
			sta	UCI_COMDATA		;Zeichen an UCI senden.
			iny				;Max. 256 Zeichen gesendet?
			bne	:1			; => Nein, weiter...

::2			rts
