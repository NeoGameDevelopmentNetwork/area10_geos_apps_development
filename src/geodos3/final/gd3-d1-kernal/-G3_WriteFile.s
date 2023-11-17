; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Datei auf Diskette speichern.
:xWriteFile		jsr	EnterTurbo		;Turbo-DOS aktivieren.
			txa				;Diskettenfehler ?
			bne	:2			;Ja, Abbruch...
			sta	VerWriteFlag		;Datei schreiben.

			jsr	InitForIO		;I/O aktivieren.

			lda	#>diskBlkBuf
			sta	r4H
			lda	#<diskBlkBuf
			sta	r4L

			lda	r6H
			pha
			lda	r6L
			pha
			lda	r7H
			pha
			lda	r7L
			pha
			jsr	VerWriteFile		;Datei speichern.
			pla
			sta	r7L
			pla
			sta	r7H
			pla
			sta	r6L
			pla
			sta	r6H
			txa
			bne	:1
			dec	VerWriteFlag		;Flag für "Datei vergleichen".
			jsr	VerWriteFile		;Datei vergleichen.
::1			jmp	DoneWithIO		;I/O abschalten.
::2			rts
