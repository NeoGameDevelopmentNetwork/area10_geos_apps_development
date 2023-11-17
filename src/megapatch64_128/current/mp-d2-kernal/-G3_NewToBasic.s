; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Neue ToBasic-Routine.
:xToBasic		lda	r0H			;Register ":r0"
			pha				;zwischenspeichern.
			lda	r0L
			pha

			jsr	SetADDR_ToBASIC		;Zeiger auf RAM-Routine setzen.
			jsr	FetchRAM		;ToBASIC-Routine einlesen.

			pla				;Register ":r0"
			sta	r0L			;zurücksetzen.
			pla
			sta	r0H

			jmp	LD_ADDR_TOBASIC		;ToBASIC ausführen.
