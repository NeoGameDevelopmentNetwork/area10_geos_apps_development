; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
;
; Ultimate 64/II(+)
;
; Note:
; Firmware 1.37 is known to be broken.
; Ultimate-users must enable:
;
; -> C64 and Cartridge settings
; -> Command interface = Enabled
;
:ctrlreg		= $df1c				;control_register
:statreg		= $df1c				;status_register
:cmddatareg		= $df1d				;command_data_register
:respdatareg		= $df1e				;response_data_register
:statdatareg		= $df1f				;status_data_register
endif

;*** Ultimate64/II(+) mit RTC suchen.
:FindRTC_U64II		jsr	PurgeTurbo		;TurboDOS abschalten und
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	GetRTCmodeU64II		;Ultimate64/II(+)-RTC abfragen.
			txa				;RTC-Fehler ?
			bne	:1			; => Ja, Ende...

			jsr	SetCPUtime		;System-Uhrzeit setzen.
			jsr	SetGEOStime		;GEOS-Uhrzeit setzen.

			ldx	#NO_ERROR
::1			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** Ultimate64/II(+) auf RTC prüfen und Uhrzeit einlesen.
:GetRTCmodeU64II	lda	cmddatareg		;Auf 1541Ultimate testen.
			cmp	#$c9
			beq	:1			;1541Ultimate gefunden.

			ldx	#DEV_NOT_FOUND
			rts

::1			jsr	RD_U2P_RTC		;RTC einlesen.
;			txa
;			bne	:err
;
;			ldx	#NO_ERROR
:err			rts

;
; Read Ultimate 64/II(+) RTC
;
; Written by Torsten Kracke.
; Merged with Code from Chameleon64 by Markus Kanet
;
; This code is heavily based on
; the source code "IDE64RTC"
; by Maciej Witkowiak (ytm(at)Elysium.pl)
;
; Output of RTC:
; CCYY/MM/DD HH:MM:SS (18 bytes)
; 0123456789012345678
; 0000000000111111111
;
; value output format is ASCII
;
:RD_U2P_RTC		lda	#$01			;'DOS_CMD_GET_TIME' an
			sta	cmddatareg		;Ultimate64/II(+) senden.
			lda	#$26
			sta	cmddatareg
			lda	#$01
			sta	ctrlreg

			lda	#$10			;Warten bis Gerät
::busy1			bit	statreg			;bereit.
			bne	:busy1

			ldx	#$00
			ldy	#$00
::wait			lda	#$20
			bit	statreg
			beq	:wait

			bvc	:gettime		;Status einlesen.
			lda	statdatareg
			sta	U2P_STAT,y
			iny
			jmp	:wait

::gettime		bpl	:rcvd			;RTC-Zeit einlesen.
			lda	respdatareg
			sta	U2P_RTC,x
			inx
			jmp	:wait

::rcvd			lda	#$02			;Empfang der Daten
			sta	ctrlreg			;bestätigen.
			lda	#$10
::busy2			bit	statreg
			bne	:busy2

::statusok		lda	U2P_STAT+0		;Status auswerten.
			cmp	#"0"
			bne	:err
			lda	U2P_STAT+1
			cmp	#"0"
			beq	:convert_ascii
::err			ldx	#DEV_NOT_FOUND		;Fehler.
			rts

;--- RTC-Daten der U2P nach DEZ wandeln.
::convert_ascii		lda	U2P_RTC+2		;Jahreszahl.
			ldx	U2P_RTC+3
			jsr	ASCIItoDEZ
			sta	RTC_DATA +1

			lda	U2P_RTC+0		;Jahrtausend.
			ldx	U2P_RTC+1
			jsr	ASCIItoDEZ
			sta	RTC_MILLENIUM

			lda	U2P_RTC+5		;Monat.
			ldx	U2P_RTC+6
			jsr	ASCIItoDEZ
			sta	RTC_DATA +2

			lda	U2P_RTC+8		;Tag.
			ldx	U2P_RTC+9
			jsr	ASCIItoDEZ
			sta	RTC_DATA +3

; Ergänzung: 14.02.19/M.Kanet
; Wird für GEOS nicht benötigt.
; (Existiert für Ultimate64/II(+) auch nicht)
;			lda	#$00			;Wochentag.
;			sta	RTC_DATA +0

			lda	U2P_RTC+11		;Stunde.
			ldx	U2P_RTC+12
			jsr	ASCIItoDEZ
			ldx	#$00			;AM/PM-Flag berechnen.
			cmp	#13
			bcc	:hour
			sbc	#12
			dex
::hour			sta	RTC_DATA +4
			stx	RTC_DATA +7

			lda	U2P_RTC+14		;Minute.
			ldx	U2P_RTC+15
			jsr	ASCIItoDEZ
			sta	RTC_DATA +5

			lda	U2P_RTC+17		;Sekunde.
			ldx	U2P_RTC+18
			jsr	ASCIItoDEZ
			sta	RTC_DATA +6

;			lda	#CR			;Füllbyte.
;			sta	RTC_DATA +8

			ldx	#NO_ERROR
			rts

;*** ASCII nach DEZ wandeln.
:ASCIItoDEZ		sec
			sbc	#$30
			cmp	#10
			bcc	:1
			lda	#9
::1			tay

			txa
			sec
			sbc	#$30
			cmp	#10
			bcc	:2
			lda	#9

::2			cpy	#0
			beq	:3
			clc
			adc	#10
			dey
			bne	:2

::3			rts

:U2P_STAT		s 30 ; clock status buffer ASCII
:U2P_RTC		s 30 ; clock output buffer ASCII
