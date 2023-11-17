; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** GEOS-Uhrzeit setzen.
:SetClockGEOS		lda	BootRTCdrive		;Uhrzeit setzen ?
			beq	:3			; => Nein, weiter...
			cmp	#$ff			;AutoMatik ?
			beq	:2			; => Ja, RTC-Gerät suchen.

::1			jsr	FindRTCdrive		;Laufwerk suchen und Zeit setzen.
			txa				;RTC-Fehler ?
			beq	:3			; => Nein, weiter...

;--- Vorgegebenes Laufwerk nicht gefunden.
;    Andere Laufwerke mit RTC-Uhr suchen.
::2			lda	#$fc			;TurboChameleon64 suchen.
			jsr	FindRTCdrive
			txa				;RTC-Fehler ?
			beq	:3			; => Nein, weiter...

			lda	#$fd			;Ultimate64/II(+) suchen.
			jsr	FindRTCdrive
			txa				;RTC-Fehler ?
			beq	:3			; => Nein, weiter...

			lda	#$fe			;SmartMouse mit RTC-Uhr suchen.
			jsr	FindRTCdrive
			txa				;RTC-Fehler ?
			beq	:3			; => Nein, weiter...

			lda	#DrvFD			;CMD_FD mit RTC-Uhr suchen.
			jsr	FindRTCdrive
			txa				;RTC-Fehler ?
			beq	:3			; => Nein, weiter...

			lda	#DrvHD			;CMD_HD mit RTC-Uhr suchen.
			jsr	FindRTCdrive
			txa				;RTC-Fehler ?
			beq	:3			; => Nein, weiter...

			lda	#DrvRAMLink		;RAMLink mit RTC-Uhr suchen.
			jmp	FindRTCdrive
::3			rts

;*** Gerät mit Echtzeituhr suchen.
:FindRTCdrive		cmp	#$fc			;TurboChameleon64 ?
			bne	:test_u64		; => Nein, weiter...
			jmp	FindRTC_TC64		; => Ja, Gerät testen.

::test_u64		cmp	#$fd			;Ultimate64/II(+) ?
			bne	:test_cmd		; => Nein, weiter...
			jmp	FindRTC_U64II		; => Ja, Gerät testen.

::test_cmdsm		cmp	#$fe			;SmartMouse ?
			bne	:test_cmd		; => Nein, weiter...
			jmp	FindRTC_SM		; => Ja, Gerät testen.

::test_cmd		jmp	FindRTC_CMD		; => CMD-Laufwerk testen.

;*** *** Laufwerk mit CMD-Uhr anzeigen.
:PutSetClkInfo		jsr	FindTypeRTCdrv		;Zeiger auf RTC-Uhr-Text
			txa				;berechnen und RTC-Gerät anzeigen.
			asl
			tax
			lda	VecRTCtext +0,x
			sta	r0L
			lda	VecRTCtext +1,x
			sta	r0H
			LoadW	r11,$005c
			LoadB	r1H,$66
			jmp	PutString

;*** Neues Gerät mit RTC-Uhr wählen.
:SetNewClkDev		jsr	FindTypeRTCdrv		;Zeiger auf nächstes RTC-Gerät.

			lda	TabRTCtypes,x
			cmp	#$ff
			bne	:1
			ldx	#$ff
::1			inx
			lda	TabRTCtypes,x
			sta	BootRTCdrive		;Keine Uhr setzen ?
			beq	:2			; => Ja, Ende...
			cmp	#$ff			;AutoDetect ?
			beq	:2			; => Ja, Ende...

			jsr	FindRTCdrive		;RTC-Gerät suchen.
			txa				;RTC-Fehler ?
			bne	SetNewClkDev		; => Ja, nächstes RTC-Gerät.

::2			rts

;*** Laufwerkstyp erkennen für RTC-Echtzeituhr.
:FindTypeRTCdrv		ldx	#$00
::1			lda	TabRTCtypes,x		;Modus aus Tabelle mit
			cmp	BootRTCdrive		;Konfiguration vergleichen.
			beq	:2			; => Gefunden, Ende...
			inx
			cmp	#$ff			;Letzten Modus geprüft ?
			bne	:1			; => Nein, weitersuchen.
			ldx	#$00			;RTC-Gerät unbekannt, keine Uhr.
::2			rts

;*** Neue Uhrzeit setzen.
:SetGEOStime		lda	RTC_DATA +1		;GEOS-Jahreszahl setzen.
			sta	year
			lda	RTC_MILLENIUM		;GEOS-Jahrtausend setzen.
			sta	millenium
			lda	RTC_DATA +2		;GEOS-Monat setzen.
			sta	month
			lda	RTC_DATA +3		;GEOS-Tag setzen.
			sta	day
;			lda	RTC_DATA +4		;GEOS-Stunde setzen.
			jsr	ConvHour24h		;(AM/PM umrechnen).
			sta	hour
			lda	RTC_DATA +5		;GEOS-Minute setzen.
			sta	minutes
			lda	RTC_DATA +6		;GEOS-Sekunde setzen.
			sta	seconds
			rts

;*** Neue Uhrzeit setzen.
:SetCPUtime		jsr	ConvHour24h
			jsr	DEZtoBCD
			sed				;AM/PM-Flag berechnen.
			cmp	#$13
			bcc	:1
			sbc	#$12
			ora	#%10000000
::1			tax
			and	#%10000000
			sta	r0L
			lda	cia1tod_h
			ldy	cia1tod_t
			txa
			sta	cia1tod_h		;Stunde setzen.
			cld

			lda	RTC_DATA +5
			jsr	DEZtoBCD		;Minute nach BCD wandeln.
			sta	cia1tod_m		;Minute setzen.

			lda	RTC_DATA +6
			jsr	DEZtoBCD		;Sekunde nach BCD wandeln.
			sta	cia1tod_s		;Sekunde setzen.

			ClrB	cia1tod_t
			rts

;*** Stunde AM/PM nach 24h wandeln.
:ConvHour24h		lda	RTC_DATA +4		;Stunde.
			ldx	RTC_DATA +7		;AM/PM-Flag.
			bne	:1
			cmp	#12
			bne	:2
			lda	#0
			beq	:2
::1			cmp	#12
			beq	:2
			clc
			adc	#12
::2			rts

;*** Dezimal nach BCD.
:DEZtoBCD		ldx	#0
::1			cmp	#10
			bcc	:2
			inx
			sbc	#10
			bcs	:1
::2			sta	r0L
			txa
			asl
			asl
			asl
			asl
			ora	r0L
			rts

;*** BCD nach Dezimal wandeln.
:BCDtoDEZ		pha
			and	#%11110000
			lsr
			lsr
			lsr
			lsr
			tay
			lda	#$00
			cpy	#$00
			beq	:2
::1			clc
			adc	#10
			dey
			bne	:1
::2			sta	r0L
			pla
			and	#%00001111
			clc
			adc	r0L
			rts

;*** RTC-Gerät.
:RTC_Type		b $00

;*** RTC-Daten.
;Format = CMD-Laufwerk FD/HD/RL.
:RTC_DATA		b $00				;Wochentag
			b $00				;Jahr
			b $00				;Monat
			b $00				;Tag
			b $00				;Stunde (1-12)
			b $00				;Minute
			b $00				;Sekunde
			b $00				;AM/PM (0=AM)
			b $00				;CR/CHR$(13)
:RTC_MILLENIUM		b $00

;*** Zeiger auf Texte für RTC-Geräte.
:VecRTCtext		w Text_NORTC
			w Text_TC64
			w Text_U64II
			w Text_CMD_SM
			w Text_CMD_RL
			w Text_CMD_FD
			w Text_CMD_HD
			w Text_AUTO

;*** Tabelle mit RTC-Geräten.
:TabRTCtypes		b $00				;Deaktiviert
			b $fc				;TurboChameleon64
			b $fd				;Ultimate64/II(+)
			b $fe				;CMD-SmartMouse
			b DrvRAMLink			;CMD-RAMlink
			b DrvFD				;CMD-FD
			b DrvHD				;CMD-HD
			b $ff				;Auto-Detect
