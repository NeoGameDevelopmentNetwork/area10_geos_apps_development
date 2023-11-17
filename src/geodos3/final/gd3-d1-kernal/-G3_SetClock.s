; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** GEOS-Uhrzeit aktualisieren.
:SetGeosClock		sei

			lda	CPU_DATA
			pha
			lda	#IO_IN
			sta	CPU_DATA

			lda	$dc0f			;Uhrzeit aktivieren.
			and	#$7f
			sta	$dc0f

			lda	$dc0b			;Stundenregister
			and	#$1f			;Einer-/Zehnerstd. ausblenden
			cmp	#$12			;12 Uhr?
			bne	:1			;>nein
			bit	$dc0b			;am/pm Flag testen
			bmi	:2			;>nachmittags (pm) 12 Uhr
			lda	hour			;Stunden auf 0 Uhr ?
			beq	:2			;>ja dann Datum nicht erhöhen

			jsr	SetADDR_GetNxDay	;Zeiger auf ":G3_GetNextDay".
			jsr	SwapRAM			;Routine in Speicher holen.
			jsr	LD_ADDR_GETNXDAY	;Neuen Tag beginnen.

			lda	#$00			;>auf 0 Uhr stellen
::1			bit	$dc0b			;am/pm Flag testen
			bpl	:2			;>vormittags (am)
			sed				;>nachmittags (pm)
			clc				;12 addieren
			adc	#$12
			cld
::2			ldx	#$00
			ldy	#$02
::3			jsr	BCDtoDEZ		;Datum/Uhrzeit kopieren.
			bpl	:3

			ldx	#19
			lda	year			;Jahrtausendbyte festlegen.
			cmp	#99
			bcs	:56
			inx
::56			stx	millenium

			ldx	$dc0d			;Alarm-Zustand einlesen.
			pla
			sta	CPU_DATA		;I/O abschalten.

			txa
			bit	alarmSetFlag		;Weckzeit aktiviert ?
			bpl	:5			; => Ja, weiter...
			and	#%00000100		;"CIA-Timer"-Weckzeit erreicht?
			beq	:6			; => Nein, Ende...

			lda	#%01001010		;Anzahl Signale initialisieren.
			sta	alarmSetFlag		;Vorgabewert: 10 Alarm-Signale.
			lda	alarmTmtVector +1	;User-Weckroutine definiert ?
			beq	:5			; => Nein, Weckton ausgeben.
			jmp	(alarmTmtVector)	;Weckroutine anspringen.

::5			bit	alarmSetFlag		;Alarm-Routine ausführen ?
			bvc	:6			; => Nein, weiter...
			jsr	SetADDR_DoAlarm		;Zeiger auf DoAlarm-Routine.
			jsr	SwapRAM			;Routine in Speicher einlesen.
			jsr	LD_ADDR_DOALARM		;Weckton aktivieren.
::6			cli
			rts

;*** BCD-Zahl nach DEZ wandeln.
:BCDtoDEZ		sty	:3 +1
			pha
			lsr
			lsr
			lsr
			lsr
			tay
			pla
			and	#%00001111
			clc
::1			dey
			bmi	:2
			adc	#10
			bne	:1
::2			sta	hour,x
			inx
::3			ldy	#$ff
			lda	year    ,y		;Aktuelles Datum in
			sta	dateCopy,y		;Zwischenspeicher kopieren.
			lda	$dc08   ,y
			dey
			rts
