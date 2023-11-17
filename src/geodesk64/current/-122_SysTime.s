; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Systemzeit kopieren.
:copySystemTime		lda	hour			;Stunde einlesen und
			sta	varHour			;in Zwischenspeicher schreiben.
			jsr	chkTimeHour		;Stunde auf Gültigkeit testen.

			lda	minutes			;Minute einlesen und
			sta	varMinute		;in Zwischenspeicher schreiben.
			jsr	chkTimeMinute		;Minute auf Gültigkeit testen.

			lda	seconds			;Sekunde einlesen und
			sta	varSecond		;in Zwischenspeicher schreiben.
			jsr	chkTimeSecond		;Sekunde auf Gültigkeit testen.

			lda	day			;Tag einlesen und
			sta	varDay			;in Zwischenspeicher schreiben.
			jsr	chkDateDay		;Tag auf Gültigkeit testen.

			lda	month			;Monat einlesen und
			sta	varMonth		;in Zwischenspeicher schreiben.
			jsr	chkDateMonth		;Monat auf Gültigkeit testen.

			lda	millenium		;Jahr von 2-Byte-Wert in
			sta	r0L			;Dezimalzahl umrechnen.
			LoadB	r1L,100
			ldx	#r0L
			ldy	#r1L
			jsr	BBMult
			lda	r0L
			clc
			adc	year			;Jahr einlesen und
			sta	varYear +0		;in Zwischenspeicher schreiben.
			lda	r0H
			adc	#$00
			sta	varYear +1
			jsr	chkDateYear		;Jahr auf Gültigkeit testen.

			rts

;*** Neue Uhrzeit setzen.
:setSystemTime		jsr	InitForIO		;I/O aktivieren.

			MoveW	varYear,r0		;Jahr von Dezimalzahl in
			LoadW	r1,100			;2-Byte-Wert umrechnen.
			ldx	#r0L
			ldy	#r1L
			jsr	Ddiv

			lda	r0L			;Jahr/Millenium übernehmen.
			sta	millenium
			lda	r8L
			sta	year

			lda	varMonth		;Monat übernehmen.
			sta	month

			lda	varDay			;Tag übernehmen.
			sta	day

			lda	varHour			;Stunde nach BCD wandeln.
			sta	hour
			jsr	DEZtoBCD
			sed				;AM/PM-Flag berechnen.
			cmp	#$13
			bcc	:102
			sbc	#$12
			ora	#%10000000
::102			tax
			lda	CIA_TODHR		;Uhrzeit anhalten.
			ldy	CIA_TOD10
			txa
			sta	CIA_TODHR		;Stunde setzen.
			cld

			lda	varMinute
			sta	minutes
			jsr	DEZtoBCD		;Minute nach BCD wandeln.
			sta	CIA_TODMIN		;Minute setzen.

			lda	varSecond
			sta	seconds
			jsr	DEZtoBCD		;Sekunde nach BCD wandeln.
			sta	CIA_TODSEC		;Sekunde setzen.

			ClrB	CIA_TOD10		;Uhrzeit starten.

			jmp	DoneWithIO		;I/O abschalten.

;*** Dezimal nach BCD.
:DEZtoBCD		ldx	#0
::101			cmp	#10
			bcc	:102
			inx
			sbc	#10
			bcs	:101
::102			sta	r0L
			txa
			asl
			asl
			asl
			asl
			ora	r0L
			rts

;*** Datum auf Gültigkeit testen.
:chkDateDay		lda	varDay			;Tag einlesen.
			beq	:1			; => Tag ungültig...

			cmp	#31 +1			;Tag > 31?
			bcc	:2			; => Nein, weiter...

			lda	#31			;max.Wert für Tag setzen.
			b $2c
::1			lda	#1			;min.Wert für Tag setzen.
			sta	varDay			;Korrigierter Wert für Tag.
::2			rts

:chkDateMonth		lda	varMonth		;Monat einlesen.
			beq	:1			; => Monat ungültig...

			cmp	#12 +1			;Monat > 12?
			bcc	:2			; => Nein, weiter...

			lda	#12			;max.Wert für Monat setzen.
			b $2c
::1			lda	#1			;min.Wert für Monat setzen.
			sta	varMonth		;Korrigierter Wert für Monat.
::2			rts

:chkDateYear		lda	varYear +1		;Jahr einlesen.
			cmp	#>1980			;Jahr > 1980 ?
			beq	:1			; => Vielleicht...
			bcs	:3			; => Ja, weiter...
			bcc	:2			; => Nein, Jahr zurücksetzen.

::1			lda	varYear +0
			cmp	#<1980
			bcs	:3

::2			LoadW	varYear,1980		;Default für Jahr setzen.

::3			rts

;*** Uhrzeit auf Gültigkeit testen.
:chkTimeHour		lda	varHour			;Stunde einlesen.
			cmp	#23 +1			;Stunde > 23?
			bcc	:1			; => Nein, weiter...

			lda	#23			;max.Wert für Stunde setzen.
			sta	varHour			;Korrigierter Wert für Stunde.

::1			rts

:chkTimeMinute		lda	varMinute		;Minute einlesen.
			cmp	#59 +1			;Minute > 59?
			bcc	:1

			lda	#59			;max.Wert für Minute setzen.
			sta	varMinute		;Korrigierter Wert für Minute.

::1			rts

:chkTimeSecond		lda	varSecond		;Sekunde einlesen.
			cmp	#59 +1			;Sekunde > 59?
			bcc	:1

			lda	#59			;max.Wert für Sekunde setzen.
			sta	varSecond		;Korrigierter Wert für Sekunde.

::1			rts

;*** Variablen.
:varHour		b $00
:varMinute		b $00
:varSecond		b $00
:varDay			b $00
:varMonth		b $00
:varYear		w $0000
