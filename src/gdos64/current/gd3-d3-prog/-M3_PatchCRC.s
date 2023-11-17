; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Prüfsumme erstellen.
;    Übergabe:		AKKU/xReg = Zeiger auf Track/Sektor.
:PatchCRC		sta	r1L			;Zeiger auf ersten Sektor speichern.
			stx	r1H

			ldy	#$00
			sty	a0L			;CRC-Wert löschen.
			sty	a0H

			ldy	#< diskBlkBuf		;Zeiger auf Datenspeicher.
			sty	r4L
			ldy	#> diskBlkBuf
			sty	r4H

			jsr	EnterTurbo		;TurboDOS aktivieren.

;--- Hinweis:
;DoneWithIO/InitForIO verwenden, da bei
;SuperCPU sonst nur 1MHz genutzt wird!
::loop			jsr	InitForIO		;I/O-Bereich einschalten.
			jsr	ReadBlock		;Sektor einlesen.
			jsr	DoneWithIO		;I/O-Bereich abschalten.
			txa				;Diskettenfehler ?
			bne	:exit			; => Ja, Abbruch...

			lda	#< diskBlkBuf+2		;Zeiger auf CRC-Bereich.
			sta	r0L
			lda	#> diskBlkBuf+2
			sta	r0H

			ldy	#$fe			;254 Datenbytes testen.
			lda	diskBlkBuf +0		;Letzter Sektor ?
			bne	:bytes			; => Nein, weiter...
			lda	diskBlkBuf +1		;Anzahl Bytes in letztem Sektor
			sec				;berechnen.
			sbc	#$02
			tay
::bytes			sty	r1L

			jsr	xCRC			;Prüfsumme erstellen.

			lda	a0L			;Prüfsummen addieren.
			clc
			adc	r2L
			sta	a0L
			lda	a0H
			adc	r2H
			sta	a0H

			ldx	diskBlkBuf +0		;Alle Sektoren getestet ?
			beq	:exit			; => Ja, Ende...
			stx	r1L			;Nächsten Sektor setzen.
			ldx	diskBlkBuf +1		;Zeiger auf nächster Sektor.
			stx	r1H

if MODE_CRC_SETUP = TRUE
;--- Hinweis:
;Bei SETUP während der CRC-Prüfung den
;Abbruch über die '!'-Taste erlauben.
			jsr	TestExitKey
endif

			jmp	:loop

::exit			rts

;*** Dateiname der Patch-Datei.
:PATCH_DAT		b "PATCH_64.DAT",NULL

;*** Prüfsummen-Routine.
;    Hier wird eine eigene Routine eingebunden, da nicht auszuschließen
;    ist das andere GEOS-Versionen andere CRC-Ergebnisse liefern.
:xCRC			ldy	#$ff			;Startwert für Prüfsumme.
			sty	r2L
			sty	r2H
			iny
::101			lda	#$80			;Bit-Maske auf Startwert.
			sta	r3L

::102			asl	r2L			;Prüfsumme um 1 Bit nach
			rol	r2H			;links verschieben.

			lda	(r0L),y			;Byte aus CRC-Bereich lesen.
			and	r3L			;Mit Bit-Maske verknüpfen.
			bcc	:103			;War Prüfsummen-Bit #15 = 0 ?
							; => Ja, weiter...
			eor	r3L			;Bit-Ergebnis invertieren.
::103			beq	:104			;Ergebnis = $00 ? Ja, weiter...

			lda	r2L			;Prüfsumme ergänzen.
			eor	#%00100001
			sta	r2L
			lda	r2H
			eor	#%00010000
			sta	r2H

::104			lsr	r3L			;Alle Bits eines Bytes ?
			bcc	:102			; => Nein, weiter...

			iny				;Zeiger auf nächstes Byte setzen.
			dec	r1L			;Alle Bytes getestet ?
			bne	:101			; => Nein, weiter...
			rts
