; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; ULIB: FILE_INFO/FILE_STAT
;
;Größe/Datum/Uhrzeit vom FAT-Format
;in das GEOS-Format umwandeln.
;
;Im Verzeichniseintrag wird die Größe
;in Bytes, Datum und Uhrzeit in einem
;kodierten Format gespeichert.
;Umwandeln der Werte in ein für GEOS
;nutzbares Format.
;
;*** Dateigröße umwandeln.
;Übergabe : UCI_DATA_MSG = lb,mlb,mhb,hb
;Rückgabe : r0  = lb/hb
;           r2L = Einheit
;Verändert: A,X,Y,r0,r2L

:ULIB_FILE_SIZE		lda	r1H			;Register ":r1"
			pha				;zwischenspeichern.
			lda	r1L
			pha

			ldx	#4 -1			;Dateigröße nach r0/r1.
::1			lda	UCI_DATA_MSG,x
			sta	r0,x
			dex
			bpl	:1

			ldx	r1H			;hb einlesen.

			lda	#"K"			;Einheit "Kb".

::loop			ldy	#10			;Größe / 1024.
::shift			lsr	r1H
			ror	r1L
			ror	r0H
			ror	r0L
			bcc	:2			; => Kein, Rest, weiter...

			inc	r0L			;Zahl aufrunden...
			bne	:2
			inc	r0H
			bne	:2
			inc	r1L
			bne	:2
			inc	r1H

::2			dey
			bne	:shift

			cpx	#$00			;War hb = 0?
			beq	:done			; => Ja, Ende...

			ldx	#$00
			lda	#"M"			;Einheit "Mb".
			bne	:loop			;Größe / 1024*1024

::done			sta	r2L			;Einheit zwischenspeichern.

			lda	r0L			;Größe = 0?
			ora	r0H
			bne	:exit			; => Nein, weiter...
			inc	r0L			;Größe mind. 1.

::exit			pla				;Register ":r1"
			sta	r1L			;zurücksetzen.
			pla
			sta	r1H

			rts

;*** Dateidatum umwandeln.
;Übergabe : UCI_DATA_MSG +4 = Datum im FAT-Format (WORD).
;Rückgabe : r14L = Tag   (00-31)
;           r14H = Monat (01-12)
;           r15L = Jahr  (00-99)
;Verändert: A,X,Y,r0,r14,r15L

:ULIB_FILE_DATE		lda	UCI_DATA_MSG +4		;WORD für Datum einlesen.
			sta	r0L
			ldx	UCI_DATA_MSG +5
			stx	r0H

;			lda	r0L			;Bit %0-%4 = Tag.
			and	#%00011111
			sta	r14L

			ldx	#r0L
			ldy	#5
			jsr	DShiftRight

			lda	r0L			;Bit %5-%8 = Monat.
			and	#%00001111
			sta	r14H

			ldx	#r0L
			ldy	#4
			jsr	DShiftRight

			lda	r0L			;Bit %9-%15 = Jahr.
			and	#%01111111
			clc
			adc	#80
::1			cmp	#100
			bcc	:2
			sbc	#100
			bne	:1
::2			sta	r15L

			rts

;*** Dateiuhrzeit umwandeln.
;Übergabe : UCI_DATA_MSG +6 = Uhrzeit im FAT-Format (WORD).
;Rückgabe : r14L = Stunde  (00-23)
;           r14H = Minute  (00-59)
;           r15L = Sekunde (00-59)
;Verändert: A,X,Y,r0,r14,r15L

:ULIB_FILE_TIME		lda	UCI_DATA_MSG +6
			sta	r0L
			ldx	UCI_DATA_MSG +7
			stx	r0H

;			lda	r0L			;Bit %0-%4 = Sekunden.
			and	#%00011111		;Sekunde/2 (0-31) einlesen.
			asl				;Sekunde *2.
			cmp	#60
			bcc	:1
			lda	#59
::1			sta	r15L			;Sekunden speichern.

			ldx	#r0L
			ldy	#5
			jsr	DShiftRight

			lda	r0L			;Bit %5-%10 = Minuten.
			and	#%00111111
			cmp	#60
			bcc	:2
			lda	#59
::2			sta	r14H			;Minute speichern.

			ldx	#r0L
			ldy	#6
			jsr	DShiftRight

			lda	r0L			;Bit %11-%15 = Stunden.
			and	#%00011111
			cmp	#24
			bcc	:3
			lda	#23
::3			sta	r14L			;Stunde speichern.

			rts

;*** Dezimalzahl nach ASCII wandeln.
;Übergabe: A = Dezimal-Zahl 0-99.
;Rückgabe: X/A = 10er/1er Dezimalzahl.
;Verändert: A,X

:ULIB_DEZ_ASCII		ldx	#"0"
::1			cmp	#10			;Restwert < 10?
			bcc	:2			; => Ja, weiter...
;			sec
			sbc	#10			;Restwert -10.
			inx				;10er-Zahl +1.
			cpx	#"9" +1			;10er-Zahl > 9?
			bcc	:1			; => Nein, weiter...
			dex				;Wert >99, Zahl auf
			lda	#9			;99 begrenzen.
::2			clc				;1er-Zahl nach ASCII wandeln.
			adc	#"0"
			rts
