; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** ShadowRAM initialisieren.
::InitShadowRAM		ldy	curDrive		;Zeiger auf erste Bank für
			lda	ramBase -8,y		;Shadow1541-Laufwerk richten.
			beq	:exit			; => Nicht definiert, Ende...
			sta	r3L

			lda	#> :init		;Zeiger auf Initialisierungswert
			sta	r0H			;für Sektortabelle (2x NULL-Byte!)
			lda	#< :init
			sta	r0L

			ldy	#$00			;Offset in 64K-Bank.
			sty	r1L
			sty	r1H
			sty	r2H			;Anzahl Bytes = 2.
			iny
			iny
			sty	r2L

			iny				;Bank-Zähler initialisieren.
			sty	r3H			; => 3x64K für max. 192Kb-Disk.

;--- Cache initialisieren.
;Dabei werden nur die Linkbytes
;aller Sektoren im Cache gelöscht.
;Damit werden beim nächsten ReadBlock
;die Daten wieder von Disk gelesen.
::loop			jsr	StashRAM		;Sektor "Nicht gespeichert" setzen.
			inc	r1H			;Zeiger auf nächsten Sektor in Bank.
			bne	:loop			;Schleife.

			inc	r3L			;Zeiger auf nächste Bank.

			dec	r3H			;Alle Bänke initialisiert ?
			bne	:loop			; => Nein, weiter...

::exit			rts

::init			w $0000
