; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** CMD-Laufwerk mit RTC suchen.
:FindRTC_CMD		pha
			jsr	PurgeTurbo
			jsr	InitForIO
			pla

			ldy	#$08
::1			cmp	devInfo -8,y
			bne	:2
			pha
			jsr	GetRTCTime
			pla
			cpx	#NO_ERROR
			bne	:2

			jsr	SetCPUtime		;System-Uhrzeit setzen.
			jsr	SetGEOStime		;GEOS-Uhrzeit setzen.

			ldx	#NO_ERROR
			jmp	DoneWithIO

::2			iny
			cpy	#29 +1
			bcc	:1

			ldx	#DEV_NOT_FOUND
			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** Uhrzeit einlesen.
:GetRTCTime		PushB	curDevice
			sty	curDevice

			jsr	CMD_RdClk
			txa
			bne	:1

;--- Ergänzung: 18.02.19/M.Kanet
; Jahrtausend nicht unterstützt.
; Annahme für 1980-1999 / 2000-2079.
			ldy	#19			;Jahrtausend festlegen.
			lda	RTC_DATA +1
			cmp	#80			;80-99?
			bcs	:year2k			; => Ja,   1980-1999
			iny				; => Nein, 2000-2079
::year2k		sty	RTC_MILLENIUM

;			ldx	#NO_ERROR

::1			ldy	curDevice
			PopB	curDevice
			rts

;
; Read CMD-Drive RTC
;
; Written by Markus Kanet
;
; Output of RTC:
; WD YY MM DD HH MM SS AP $0D (9 bytes)
; value output format is DEZ
;

:CMD_RdClk		ClrB	STATUS			;Befehlskanal zum Gerät öffnen.
			jsr	UNLSN
			lda	curDevice
			jsr	LISTEN
			lda	#$ff
			jsr	SECOND

			lda	STATUS
			beq	:51
			jsr	UNLSN
			ldx	#DEV_NOT_FOUND
			rts

::51			ldy	#$00			;Befehl zum lesen der Uhrzeit an
::52			lda	RTC_GetTime,y		;Laufwerk senden.
			jsr	CIOUT
			iny
			cpy	#$04
			bcc	:52

			jsr	UNLSN

			ClrB	STATUS			;Laufwerk auf "senden" umschalten.
			jsr	UNTALK
			lda	curDevice
			jsr	TALK
			lda	#$ff
			jsr	TKSA

			lda	STATUS
			beq	:53
			jsr	UNTALK
			ldx	#DEV_NOT_FOUND
			rts

::53			ldy	#$00
::54			jsr	ACPTR
			sta	RTC_DATA,y
			iny
			cpy	#$09
			bcc	:54

			pha

::55			lda	STATUS
			bne	:56
			jsr	ACPTR
			jmp	:55

::56			jsr	UNTALK
			pla

			ldx	#DEV_NOT_FOUND
			cmp	#CR
			bne	:57

			ldx	#NO_ERROR
::57			rts

;*** CMD-RTC data.
:RTC_GetTime		b "T-RD"			;Read Date+Time.
