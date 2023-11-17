; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Datum von yy/mm/dd nach yyyy/mm/dd konvertieren.
:ConvertDate		ldy	#$19
			ldx	#$01
::1			lda	(a1L),y			;Dateum beider Verzeichnis-
			sta	dateFile_a1,x		;Einträge in Zwischenspeicher
			lda	(a2L),y			;kopieren.
			sta	dateFile_a2,x
			iny
			inx
			cpx	#$06
			bcc	:1

			jsr	chkDateTime_a1
			jsr	chkDateTime_a2

			lda	dateFile_a1 +1		;Jahrhundert für beide Verzeichnis-
			jsr	:century		;Einträge ermitteln.
			stx	dateFile_a1 +0
			lda	dateFile_a2 +1
			jsr	:century
			stx	dateFile_a2 +0
			rts

;--- Jahrhundert ermitteln.
::century		ldx	#19
			cmp	#80			;Jahr >= 80 => 1980.
			bcs	:99
			ldx	#20			;Jahr <  80 => 2000 - 2079.
::99			rts

;*** Auf gültiges Datum/Uhrzeit testen.
:chkDateTime_a1		ldx	#1
			b $2c
:chkDateTime_a2		ldx	#8
			stx	:exit +1

			lda	dateFile_a1,x		;Jahr.
			beq	:exit
			cmp	#99 +1			;Jahr =< 99?
			bcs	:exit			; => Nein, Fehler...

			inx
			lda	dateFile_a1,x		;Monat.
			beq	:exit
			cmp	#12 +1			;Monat =< 12?
			bcs	:exit			; => Nein, Fehler...

			inx
			lda	dateFile_a1,x		;Tag.
			beq	:exit
			cmp	#31 +1			;Tag =< 31?
			bcs	:exit			; => Nein, Fehler...

			inx
			lda	dateFile_a1,x		;Stunde.
			cmp	#24			;Stunde < 24?
			bcs	:exit			; => Nein, Fehler...

			inx
			lda	dateFile_a1,x		;Minute.
			cmp	#60			;Minute < 60?
			bcs	:exit			; => Nein, Fehler...

			rts				;Datum/Uhrzeit gültig.

;--- Fehlerhaftes Datum ersetzen.
::exit			ldx	#$ff

			lda	#80
			sta	dateFile_a1,x		;Jahr.
			inx
			lda	#1
			sta	dateFile_a1,x		;Monat.
			inx
			sta	dateFile_a1,x		;Tag.

;--- Fehlerhafte Uhrzeit ersetzen.
			lda	#00
			inx
			sta	dateFile_a1,x		;Stunde.
			inx
			sta	dateFile_a1,x		;Minute.
			rts

;*** Zwischenspeicher für Datum.
:dateFile_a1		s 07
:dateFile_a2		s 07
