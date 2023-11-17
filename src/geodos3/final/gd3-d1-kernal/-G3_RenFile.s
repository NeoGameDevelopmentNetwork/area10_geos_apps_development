; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Datei umbenennen.
:xRenameFile		lda	r0H			;Zeiger auf neuen Dateinamen
			pha				;zwischenspeichern.
			lda	r0L
			pha
			jsr	FindFile		;Datei suchen.
			pla				;Zeiger auf neuen Dateinamen
			sta	r0L			;zurückschreiben.
			pla
			sta	r0H
			txa				;Diskettenfehler ?
			bne	:55			;Ja, Abbruch...

			clc				;Zeiger auf Dateiname innerhalb
			lda	#$03			;Verzeichniseintrag berechnen.
			adc	r5L
			sta	r5L
			bcc	:51
			inc	r5H

::51			ldy	#$00			;Neuen Dateinamen in
::52			lda	(r0L),y			;Verzeichniseintrag kopieren.
			beq	:53
			sta	(r5L),y
			iny
			cpy	#$10
			bcc	:52
			bcs	:54

::53			lda	#$a0			;Dateiname auch 16 Zeichen
			sta	(r5L),y			;mit $A0-Codes auffüllen.
			iny
			cpy	#$10
			bcc	:53
::54			jmp	PutBlock_dskBuf		;Sektor zurückschreiben.
::55			rts
