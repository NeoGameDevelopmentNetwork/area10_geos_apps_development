; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Hinweis:
;":ClrDBoxTitel" muss am Anfang der
;Quelltext-Datei stehen, da andere
;Dateien vor dem Include-Befehl "t"
;ein externes Label ergänzen!

;*** Titelzeile in Dialogbox löschen.
::ClrDBoxTitel		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$30,$3f
			w	$0040,$00ff
			lda	C_DBoxTitel
			jsr	DirectColor
			jmp	UseSystemFont
