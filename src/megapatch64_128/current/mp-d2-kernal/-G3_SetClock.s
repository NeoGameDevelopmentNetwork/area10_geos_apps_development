; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** GEOS-Uhrzeit aktualisieren.
:SetGeosClock		sei

;---C64: I/O aktivieen.
if Flag64_128 = TRUE_C64
			lda	CPU_DATA
			pha
			lda	#%00110101
			sta	CPU_DATA
endif

			lda	$dc0f			;Uhrzeit aktivieren.
			and	#$7f
			sta	$dc0f

			lda	$dc0b			;Stundenregister
			and	#$1f			;Einer-/Zehnerstd. ausblenden
			cmp	#$12			;12 Uhr?
			bne	:51			;>nein
			bit	$dc0b			;am/pm Flag testen
			bmi	:52			;>nachmittags (pm) 12 Uhr
			lda	hour			;Stunden auf 0 Uhr ?
			beq	:52			;>ja dann Datum nicht erhöhen

			jsr	SetADDR_GetNxDay	;Zeiger auf ":G3_GetNextDay".
			jsr	SwapRAM			;Routine in Speicher holen.
			jsr	LD_ADDR_GETNXDAY	;Neuen Tag beginnen.

			lda	#$00			;>auf 0 Uhr stellen
::51			bit	$dc0b			;am/pm Flag testen
			bpl	:52			;>vormittags (am)
			sed				;>nachmittags (pm)
			clc				;12 addieren
			adc	#$12
			cld
::52			ldx	#$00
			ldy	#$02
::53			jsr	BCDtoDEZ		;Datum kopieren.
			bpl	:53

			ldx	$dc0d			;Alarm-Zustand einlesen.

;---C64: I/O deaktivieen.
if Flag64_128 = TRUE_C64
			pla
			sta	CPU_DATA		;I/O abschalten.
endif

			txa
			bit	alarmSetFlag		;Weckzeit aktiviert ?
			bpl	:55			; => Ja, weiter...
			and	#%00000100		;"CIA-Timer"-Weckzeit erreicht?
			beq	:56			; => Nein, Ende...

			lda	#%01001010		;Anzahl Signale initialisieren.
			sta	alarmSetFlag		;Vorgabewert: 10 Alarm-Signale.
			lda	alarmTmtVector +1	;User-Weckroutine definiert ?
			beq	:55			; => Nein, Weckton ausgeben.
			jmp	(alarmTmtVector)	;Weckroutine anspringen.

::55			bit	alarmSetFlag		;Alarm-Routine ausführen ?
			bvc	:56			; => Nein, weiter...
			jsr	SetADDR_DoAlarm		;Zeiger auf DoAlarm-Routine.
			jsr	SwapRAM			;Routine in Speicher einlesen.
			jsr	LD_ADDR_DOALARM		;Weckton aktivieren.
::56			cli
			rts

;*** BCD-Zahl nach DEZ wandeln.
:BCDtoDEZ		sty	:53 +1
			pha
			lsr
			lsr
			lsr
			lsr
			tay
			pla
			and	#%00001111
			clc
::51			dey
			bmi	:52
			adc	#10
			bne	:51
::52			sta	hour,x
			inx
::53			ldy	#$ff
			lda	year    ,y		;Aktuelles Datum in
			sta	dateCopy,y		;Zwischenspeicher kopieren.
			lda	$dc08   ,y
			dey
			rts
