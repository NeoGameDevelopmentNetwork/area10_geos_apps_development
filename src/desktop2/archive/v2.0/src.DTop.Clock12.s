; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Ausgabefeld Datum/Uhrzeit.
.AREA_CLOCK_Y0		= $00
:AREA_CLOCK_Y1		= $0c
.AREA_CLOCK_X0		= $00dd
:AREA_CLOCK_X1		= $013f

;--- Position Datum/Uhrzeit:
.POS_CLOCK_DATE		= $00e3
.POS_CLOCK_TIME		= $0114

;*** Uhr initialisieren.
:initDTopClock		lda	#$00
			sta	flagUpdClock

			jsr	setPattern0
			jsr	i_Rectangle
			b AREA_CLOCK_Y0,AREA_CLOCK_Y1
			w AREA_CLOCK_X0,AREA_CLOCK_X1

			jsr	i_FrameRectangle
			b AREA_CLOCK_Y0,AREA_CLOCK_Y1
			w AREA_CLOCK_X0,AREA_CLOCK_X1
			b %11111111

			lda	#> tabProcData
			sta	r0H
			lda	#< tabProcData
			sta	r0L

			lda	#$01			;Uhranzeige starten.
			jsr	InitProcesses

;*** Uhrzeit aktualisieren.
.updateProcClock	jsr	restartProcClock
			jmp	updDateTime

;*** Uhrzeit neu starten.
:restartProcClock	ldx	#$00
			jmp	RestartProcess

;*** Prozesstabelle.
:tabProcData		w procRoutClock
			w 60

;*** Uhrzeit anhalten.
.blockProcClock		ldx	#$00
			jmp	BlockProcess

;*** Zeichen in Uhrzeit-Text schreiben.
:writeClockData		cmp	stringCurTime,x
			beq	:exit

			sta	stringCurTime,x

			txa
			pha
			jsr	prntCurTime
			pla
			tax

::exit			rts

;*** Prozessroutine: Uhrzeit aktualisieren.
:procRoutClock		bit	flagUpdClock
			bmi	:exit

			php
			sei
			lda	CPU_DATA
			pha
			lda	#IO_IN
			sta	CPU_DATA

			lda	#"A"			;AM/PM-Flag.
			bit	$dc0b
			bpl	:am_pm
			lda	#"P"
::am_pm			ldx	#6
			jsr	writeClockData

			lda	$dc0b
			and	#$7f
			bne	:conv_hour
			lda	#$12
::conv_hour		jsr	convBCD2ASCII
			pha
			txa
			ldx	#$00
			jsr	writeClockData
			inx
			pla
			jsr	writeClockData

			lda	$dc0a
			jsr	convBCD2ASCII
			pha
			txa
			ldx	#$03
			jsr	writeClockData
			inx
			pla
			jsr	writeClockData
			lda	$dc08			;Uhr starten.

			pla
			sta	CPU_DATA
			plp

			lda	hour
			ora	minutes			;"00:00" Uhr?
			beq	updDateTime		; => Ja, Neues Datum.
::exit			rts

;*** Text für Datum/Uhrzeit definieren.
:updDateTime		lda	#$00
			ldx	#9
			sta	stringCurTime,x
			sta	stringCurDate,x
			lda	#$20
			sta	stringCurTime +5
			sta	stringCurTime +8
			sta	stringCurDate +8

			php
			sei
			lda	CPU_DATA
			pha
			lda	#IO_IN
			sta	CPU_DATA

			lda	#"M"
			sta	stringCurTime +7
			lda	#":"
			sta	stringCurTime +2

			lda	$dc0a			;Minuten.
			jsr	convBCD2ASCII
			sta	stringCurTime +4
			stx	stringCurTime +3

			ldx	#"A"
			lda	$dc0b
			bpl	:am
			ldx	#"P"
::am			and	#$7f
			bne	:am_pm
			lda	#$12
::am_pm			stx	stringCurTime +6
			jsr	convBCD2ASCII
			sta	stringCurTime +1
			stx	stringCurTime +0

			bit	$dc08			;Uhr starten.
			pla
			sta	CPU_DATA
			plp

			lda	year
			jsr	convDez2ASCII
			sta	stringCurDate +7
			stx	stringCurDate +6

			lda	#"/"
			sta	stringCurDate +5
			sta	stringCurDate +2

			lda	day
			jsr	convDez2ASCII
			sta	stringCurDate +4
			stx	stringCurDate +3

			lda	month
			jsr	convDez2ASCII
			sta	stringCurDate +1
			stx	stringCurDate +0

			jsr	prntCurDate

;*** Uhrzeit ausgeben.
.prntCurTime		php
			sei
			lda	CPU_DATA
			pha
			lda	#RAM_64K
			sta	CPU_DATA

			lda	#> stringCurTime
			sta	r0H
			lda	#< stringCurTime
			sta	r0L

			lda	#> POS_CLOCK_TIME
			sta	r11H
			lda	#< POS_CLOCK_TIME
			sta	r11L
			lda	#AREA_CLOCK_Y0 +9
			sta	r1H

			clv
			bvc	prntClockStrg

;*** Datum ausgeben.
.prntCurDate		php
			sei
			lda	CPU_DATA
			pha
			lda	#RAM_64K
			sta	CPU_DATA

			lda	#> stringCurDate
			sta	r0H
			lda	#< stringCurDate
			sta	r0L

			lda	#> POS_CLOCK_DATE
			sta	r11H
			lda	#< POS_CLOCK_DATE
			sta	r11L
			lda	#AREA_CLOCK_Y0 +9
			sta	r1H

:prntClockStrg		jsr	PutString

			pla
			sta	CPU_DATA
			plp
			rts

;*** BCD-Zahl 0-99 nach ASCII wandeln.
;Übergabe: A   = Zahl 0-99.
;Rückgabe: X/A = ASCII 10er/1er.
:convBCD2ASCII		pha
			lsr
			lsr
			lsr
			lsr
			clc
			adc	#"0"
			tax
			pla
			and	#%00001111
			clc
			adc	#"0"
			rts

;*** DEZ-Zahl 0-99 nach ASCII wandeln.
;Übergabe: A   = Zahl 0-99.
;Rückgabe: X/A = ASCII 10er/1er.
.convDez2ASCII		ldx	#"0"
			sec
::1			sbc	#10
			bcc	:2
			inx
			bcs	:1
::2			adc	#"0" +10
			rts
