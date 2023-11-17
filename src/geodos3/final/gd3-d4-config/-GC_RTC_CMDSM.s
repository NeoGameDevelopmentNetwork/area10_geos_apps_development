; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** SmartMouse mit RTC suchen.
:FindRTC_SM		jsr	PurgeTurbo		;TurboDOS abschalten und
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	GetRTCmodeSM		;SmartMouse-RTC abfragen.
			txa				;RTC-Fehler ?
			bne	:1			; => Ja, Ende...

			jsr	SetCPUtime		;System-Uhrzeit setzen.
			jsr	SetGEOStime		;GEOS-Uhrzeit setzen.

			ldx	#NO_ERROR
::1			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** SmartMouse auf RTC prüfen und Uhrzeit einlesen.
:GetRTCmodeSM		jsr	SM_RdClk		;Uhrzeit einlesen.

			ldx	RTC_SM_DATA  +0
			cpx	#$ff			;SmartMouse verfügbar ?
			bne	:1			;Nein, übergehen.
			ldx	#DEV_NOT_FOUND
			rts

::1			lda	RTC_SM_DATA  +5		;Wochentag.
			jsr	BCDtoDEZ
			sec
			sbc	#$01
			bcs	:2
			lda	#$00
::2			cmp	#$07
			bcc	:3
			lda	#$06
::3			sta	RTC_DATA +0

			lda	RTC_SM_DATA  +6		;Jahr.
			jsr	BCDtoDEZ
			sta	RTC_DATA +1

;--- Ergänzung: 18.02.19/M.Kanet
; Jahrtausend nicht unterstützt.
; Annahme für 1980-1999 / 2000-2079.
			ldy	#19			;Jahrtausend festlegen.
			cmp	#80			;80-99?
			bcs	:year2k			; => Ja,   1980-1999
			iny				; => Nein, 2000-2079
::year2k		sty	RTC_MILLENIUM

			lda	RTC_SM_DATA  +4		;Monat.
			jsr	BCDtoDEZ
			sta	RTC_DATA +2

			lda	RTC_SM_DATA  +3		;Tag.
			jsr	BCDtoDEZ
			sta	RTC_DATA +3

			lda	RTC_SM_DATA  +2		;Stunde.
			jsr	SM_ConvHour1
			sta	RTC_DATA +4
			stx	RTC_DATA +7

			lda	RTC_SM_DATA  +1		;Minute.
			jsr	BCDtoDEZ
			sta	RTC_DATA +5

			lda	RTC_SM_DATA  +0		;Sekunde.
			jsr	BCDtoDEZ
			sta	RTC_DATA +6

;			lda	#CR			;Füllbyte.
;			sta	RTC_DATA +8

			ldx	#NO_ERROR
			rts

;*** SmartMouse-Zeitsystem korrigieren.
:SM_ConvHour1		cmp	#%10000000
			bcc	:1
			pha
			and	#%00100000
			tax
			pla
			and	#%00011111
			jmp	BCDtoDEZ

::1			and	#%00111111
			jsr	BCDtoDEZ
			ldx	#$00
			rts

			ldx	#$00
			cmp	#12
			bcc	:2
			dex
			rts

::2			cmp	#$00
			bne	:3
			lda	#12
::3			rts

;
; Read CMD SmartMouse RTC
;
; Written by Markus Kanet
;
; Output of RTC:
; SS MM HH TT MM WD YY WP (8 bytes)
; value output format is BCD
;

;*** Uhrzeit einlesen.
:SM_RdClk		jsr	SM_Setup
			lda	#$bf			;burst rd clk cmd
			jsr	SM_SendCom		;send it
			ldy	#00
::1			jsr	SM_GetByte
			sta	RTC_SM_DATA,y
			iny
			cpy	#$08
			bcc	:1
			jsr	SM_End1
			jmp	SM_Exit

;*** Abfragemodus starten.
:SM_Setup		php
			sei
			sta	RTC_SM_BUF +2
			pla
			sta	RTC_SM_BUF +3
			lda	mport
			sta	RTC_SM_BUF +0
			lda	mpddr
			sta	RTC_SM_BUF +1
			lda	#%11111111
			sta	mport
			lda	#%00001010
			sta	mpddr
			lda	RTC_SM_BUF +2
			rts

;*** Abfragemodus beenden.
:SM_Exit		sta	RTC_SM_BUF +2
			lda	RTC_SM_BUF +0
			sta	mport
			lda	RTC_SM_BUF +1
			sta	mpddr
			lda	RTC_SM_BUF +3
			pha
			lda	RTC_SM_BUF +2
			plp
			rts

;*** Befehl an SmartMouse senden.
:SM_SendCom		pha
			jsr	SM_Init1		;SM_Output
			pla
:SM_Com1		jsr	SM_SendByte
			jmp	SM_Input

;*** Byte von SmartMouse einlesen.
:SM_GetByte		ldx	#08
::1			jsr	SM_Init3
			lda	mport
			lsr
			lsr
			lsr
			ror	RTC_SM_BUF +2
			jsr	SM_End2
			dex
			bne	:1
			lda	RTC_SM_BUF +2
			rts

;*** Byte an SmartMouse senden.
:SM_SendByte		sta	RTC_SM_BUF +2
			ldx	#08
::1			jsr	SM_Init3
			lda	#00
			ror	RTC_SM_BUF +2
			rol
			asl
			asl
			ora	#%11110001		;set io bit
			sta	mport
			jsr	SM_End2
			dex
			bne	:1
			rts

;*** Warten bis SMartMouse bereit.
:SM_Init1		jsr	SM_Output
			jsr	SM_Init3
:SM_Init2		lda	#%11110111
			b $2c
:SM_Init3		lda	#%11111101
			and	mport
			sta	mport
			rts

;*** SmartMouse deaktivieren.
:SM_End1		lda	#%00001000
			b $2c
:SM_End2		lda	#%00000010
			ora	mport
			sta	mport
			rts

;*** Datenrichtung bestimmen.
:SM_Output		lda	#%00001110
			b $2c
:SM_Input		lda	#%00001010
			sta	mpddr
			rts

;*** SmartMouse-Zwischenspeicher.
:RTC_SM_DATA		s $08
:RTC_SM_BUF		s $04
