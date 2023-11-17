; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Prüfsumme bilden.
:xCRC			ldy	#$ff			;Startwert für Prüfsumme.
			sty	r2L
			sty	r2H
			iny
::1			lda	#$80			;Bit-Maske auf Startwert.
			sta	r3L

::2			asl	r2L			;Prüfsumme um 1 Bit nach
			rol	r2H			;links verschieben.

			lda	(r0L),y			;Byte aus CRC-Bereich lesen.
			and	r3L			;Mit Bit-Maske verknüpfen.
			bcc	:3			;War Prüfsummen-Bit #15 = 0 ?
							;Ja, weiter...
			eor	r3L			;Bit-Ergebnis invertieren.
::3			beq	:4			;Ergebnis = $00 ? Ja, weiter...

			lda	r2L			;Prüfsumme ergänzen.
			eor	#%00100001
			sta	r2L
			lda	r2H
			eor	#%00010000
			sta	r2H

::4			lsr	r3L			;Alle Bits eines Bytes ?
			bcc	:2			;Nein, weiter...

			iny				;Zeiger auf nächstes Byte
			bne	:5			;berechnen.
			inc	r0H

::5			ldx	#r1L			;Länge des CRC-Bereichs
			jsr	xDdec			;korrigieren.
			lda	r1L
			ora	r1H			;Prüfsumme erstellt ?
			bne	:1			;Nein, weiter...
			rts
