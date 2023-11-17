; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; ULIB: Pfad+Dateiname in Pfad und Dateiname aufteilen
;
;Übergabe : r6 = Zwischenspeicher für Pfad (z.B. UCI_DATA_MSG)
;           r9 = Zeiger auf /Pfad/Dateiname
;Rückgabe : r6 = Zeiger auf /Pfad
;           r9 = Zeiger auf Dateiname
;Verändert: A,X,Y,r9

:ULIB_SPLIT_PATH

			lda	r0H			;Register r0L/r0H
			pha				;zwischenspeichern.
			lda	r0L
			pha

			ldy	#0
			sty	r0L			;Kein "/" gefunden.
			sty	r0H			;Position letztes "/".

::1			lda	(r9L),y			;Zeichen einlesen. Ende?
			beq	:3			; => Ja, weiter...

			cmp	#"/"			;Pfad-Trenner?
			bne	:2			; => Nein, weiter...

			sty	r0H			;Position "/" speichern.

			lda	#$ff			;Flag setzen: "/" gefunden.
			sta	r0L

::2			iny				;Alle Zeichen überprüft?
			bne	:1			; => Nein, weiter...

::3			ldy	r0L			;"/" gefunden?
			beq	:null			; => Nein , weiter...

			ldy	#0			;Verzeichnispfad in
::4			lda	(r9),y			;Zwischenspeicher kopieren.
			sta	(r6),y
			iny
			cpy	r0H			;Verzeichnispfad kopiert?
			bne	:4			; => Nein, weiter...

::null			lda	#NULL			;Ende-Kenung setzen.
			sta	(r6),y
			iny

			cpy	#1			;Pfad vorhanden?
			beq	:nopath			; => Kein Pfad, weiter...

			tya				;Zeiger auf Dateiname berechnen.
			clc
			adc	r9L
			sta	r9L
			lda	#$00
			adc	r9H
			sta	r9H

::path			ldx	#TRUE			; => Pfad+Dateiname...
			b $2c
::nopath		ldx	#FALSE			; => Kein Pfad, nur Dateiname...

::done			pla				;Register r0L/r0H
			sta	r0L			;zurücksetzen.
			pla
			sta	r0H

			rts
