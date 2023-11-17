; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** GEOS-Uhrzeit setzen.
;******************************************************************************
;*** GEOS-Uhrzeit setzen.
.SetClockGEOS		lda	BootRTCdrive		;Uhrzeit setzen ?
			beq	:53			; => Nein, weiter...
			cmp	#$ff			;Automatik aktiv ?
			beq	:52			; => Ja, RTC-Gerät suchen.

::51			jsr	FindRTCdrive		;Laufwerk suchen und Zeit setzen.
			txa				;RTC-Fehler ?
			beq	:53			; => Nein, weiter...

;--- Vorgegebenes Laufwerk nicht gefunden.
;    Andere Laufwerke mit RTC-Uhr suchen.
::52			lda	#DrvRAMLink		;RAMLink mit RTC-Uhr suchen.
			jsr	FindRTCdrive
			txa				;RTC-Fehler ?
			beq	:53			; => Nein, weiter...

			lda	#DrvFD			;CMD_FD mit RTC-Uhr suchen.
			jsr	FindRTCdrive
			txa				;RTC-Fehler ?
			beq	:53			; => Nein, weiter...

			lda	#DrvHD			;CMD_HD mit RTC-Uhr suchen.
			jsr	FindRTCdrive
			txa				;RTC-Fehler ?
			beq	:53			; => Nein, weiter...

			lda	#$fe			;SmartMouse mit RTC-Uhr suchen.
			jsr	FindRTCdrive
;			txa				;RTC-Fehler ?
;			beq	:53			; => Nein, weiter...

;--- Ergänzung: 08.07.18/M.Kanet
;Code-Rekonstruktion: Die Version von 2003 wurde um die Möglichkeit erweitert
;auch 64Net als RTC-Gerät zum setzen der GEOS-Uhrzeit zu verwenden.
;--- Ergänzung: 24.08.18/M.Kanet
;Die automatische Erkennung von 64Net als RTC-Gerät führt bei installiertem
;Parallelkabel zur 1570 zu einem System-Stillstand.
;64Net als RTC nur noch über die manuelle Auswahl erlauben.
;			lda	#$fd			;64Net mit PC-Uhr suchen.
;			jmp	FindRTCdrive
::53			rts

;*** CMD-Laufwerk mit Echtzeituhr suchen.
.FindRTCdrive		sta	RTC_Type		;Laufwerkstyp speichern.
			cmp	#$fe			;SmartMouse ?
			beq	FindRTC_SM		; => Ja, weiter...
;--- Ergänzung: 08.07.18/M.Kanet
;Code-Rekonstruktion: Die Version von 2003 wurde um die Möglichkeit erweitert
;auch 64Net als RTC-Gerät zum setzen der GEOS-Uhrzeit zu verwenden.
			cmp	#$fd			;64Net PC-Uhr ?
			beq	FindRTC_64Net		; => Ja, weiter...

			jsr	PurgeTurbo		;TurboDOS deaktivieren.

			ldx	#$08
::51			stx	RTC_Drive		;Laufwerksadresse einlesen und

			ldy	DriveInfoTab-8,x	;Laufwerk erkennen.
			cpy	RTC_Type		;Laufwerk gefunden ?
			bne	:53			; => Nein, weiter...

			jsr	InitForIO		;I/O-Bereich einblenden.

			ldx	RTC_Drive
			jsr	GetRTCTime		;Uhrzeit einlesen.
			txa				;RTC-Fehler ?
			bne	:52			; => Ja, weiter...

			jsr	SetCPUtime		;Uhrzeit setzen.

			ldx	#NO_ERROR
::52			jsr	DoneWithIO
			txa				;Uhrzeit gesetzt ?
			beq	:54			; => Ja, Ende...

			ldx	RTC_Drive		;Nächstes Laufwerk testen.
::53			inx
			cpx	#29 +1
			bcc	:51
			ldx	#DEV_NOT_FOUND
::54			rts

;******************************************************************************
;*** GEOS-Uhrzeit setzen.
;******************************************************************************
;*** SmartMouse mit RTC suchen.
.FindRTC_SM		jsr	PurgeTurbo		;TurboDOS abschalten und
			jsr	InitForIO		;I/O-Bereich einblenden.
			jsr	GetRTCmodeSM		;SmartMouse-RTC-abfragen.
			txa				;RTC-Fehler ?
			bne	:51			; => Ja, Ende...

			jsr	SetCPUtime		;Uhrzeit setzen.

			ldx	#NO_ERROR
::51			jmp	DoneWithIO

;--- Ergänzung: 08.07.18/M.Kanet
;Code-Rekonstruktion: Die Version von 2003 wurde um die Möglichkeit erweitert
;auch 64Net als RTC-Gerät zum setzen der GEOS-Uhrzeit zu verwenden.
;Die Routine von W.Grimm wurde ungetestet 1:1 übernommen.
;*** 64Net mit PC-Uhr suchen.
.FindRTC_64Net		jsr	L40d2
			txa
			bne	:1			; => Ja, Ende...

			jsr	L4043
			jsr	L411d

			ldx	#NO_ERROR
::1			rts

;******************************************************************************
;*** GEOS-Uhrzeit setzen.
;******************************************************************************
;--- Ergänzung: 08.07.18/M.Kanet
;Code-Rekonstruktion: GEOS-Uhrzeit mit 64Net setzen.
;Hinweis: Die Routine verwendet auch in der C128-Version von 2003
;das Register CPU_DATA. Frage: Ist dazu nicht das Register MMU zuständig?
;Evtl. wurde die Routine in die 64er-Version eingebaut und beim 128er
;vergessen eine entsprechende if/endif-Abfrage für MMU einzubauen.
:L4043			lda	CPU_DATA
			pha
			lda	#$35
			sta	CPU_DATA

			lda	#$58
			jsr	L420f
			lda	#$44
			jsr	L420f
			lda	#$57
			jsr	L420f
			lda	#$02
			jsr	L420f
			lda	#$54
			jsr	L420f
			lda	#$44
			jsr	L420f
			lda	#$58
			jsr	L420f
			lda	#$44
			jsr	L420f
			lda	#$52
			jsr	L420f
			jsr	L4266
			sta	L40d1
			ldy	#$00
::1			jsr	L4266
			sta	L4294,y
			iny
			dec	L40d1
			bne	:1
			jsr	L4266
			sta	L4294,y
			pla
			sta	CPU_DATA
			lda	L42a8
			sta	L41f8 +06
			lda	L42a9
			sta	L41f8 +07
			lda	L42a0
			sta	L41f8 +03
			lda	L42a1
			sta	L41f8 +04
			lda	L42a3
			sta	L41f8 +00
			lda	L42a4
			sta	L41f8 +01
			lda	L4297
			sta	L41f8 +12
			lda	L4298
			sta	L41f8 +13
			lda	L429a
			sta	L41f8 +15
			lda	L429b
			sta	L41f8 +16
			rts

:L40d1			b $00

;******************************************************************************
;*** GEOS-Uhrzeit setzen.
;******************************************************************************
:L40d2			cli
			ldx	CPU_DATA
			lda	#$b5
			sta	CPU_DATA
			lda	#$07
			sta	$dd03
			lda	#$00
			sta	$dd01
			lda	#$08
			sta	$dd01
			lda	#$32
			sta	dblClickCount
::1			lda	$dd01
			and	#%11110000
			cmp	#%10000000
			beq	:2
			lda	dblClickCount
			bne	:1
			stx	CPU_DATA
			ldx	#$ff
			rts

::2			lda	#$00
			sta	$dd01
::3			lda	$dd01
			and	#%11110000
			cmp	#%00000000
			bne	:4
			lda	dblClickCount
			bne	:3
			stx	CPU_DATA
			ldx	#$ff
			rts
::4			stx	CPU_DATA
			ldx	#$00
			rts

:L411d			jsr	L41c5
			php
			sei
			lda	CPU_DATA
			pha
			lda	#$35
			sta	CPU_DATA
			lda	$dc0f
			and	#%01111111
			sta	$dc0f
			ldx	#$00
::1			lda	L420a,x
			sta	year,x
			inx
			cpx	#$05
			bne	:1

			ldx	#19			;<*> Jahr2000-Byte definieren.
			lda	year
			cmp	#99
			bcs	:2
			inx
::2			stx	millenium

			lda	L41f8 +15
			asl
			asl
			asl
			asl
			sta	L4190
			lda	L41f8 +16
			and	#%00001111
			ora	L4190
			sta	$dc0a

			lda	L41f8 +12
			asl
			asl
			asl
			asl
			sta	L4190
			lda	L41f8 +13
			and	#%00001111
			ora	L4190
			cmp	#19
			bcc	:3
			sed
			sec
			sbc	#$12
			cld
			ora	#%10000000
::3			sta	$dc0b
			lda	#$00
			sta	$dc09
			sta	$dc08
			sta	seconds
			pla
			sta	CPU_DATA
			plp
			rts

:L4190			b $00

;******************************************************************************
;*** GEOS-Uhrzeit setzen.
;******************************************************************************
:L4191			LoadW	a1,L41f8
			clc
			lda	a1L
			adc	a0L
			sta	a1L
			lda	a1H
			adc	#$00
			sta	a1H
			ldy	#$00
			lda	(a1L),y
			and	#%00001111
			sta	a2L
			lda	#10
			sta	a2H
			ldx	#a2L
			ldy	#a2H
			jsr	BBMult
			sta	a3L
			ldy	#$01
			lda	(a1L),y
			and	#%00001111
			clc
			adc	a3L
			rts

:L41c5			lda	#$06
			sta	a0L
			jsr	L4191
			sta	L420a
			lda	#$03
			sta	a0L
			jsr	L4191
			sta	L420b
			lda	#$00
			sta	a0L
			jsr	L4191
			sta	L420c
			lda	#$0c
			sta	a0L
			jsr	L4191
			sta	L420d
			lda	#$0f
			sta	a0L
			jsr	L4191
			sta	L420e
			rts

:L41f8			b "00.00.00    00:00",NULL
:L420a			b $00
:L420b			b $00
:L420c			b $00
:L420d			b $00
:L420e			b $00

;******************************************************************************
;*** GEOS-Uhrzeit setzen.
;******************************************************************************
:L420f			sta	L4293
			and	#%00000011
			ora	#%00000100
			sta	$dd01
::1			lda	$dd01
			and	#%01110000
			cmp	#%01010000
			bne	:1

			lda	L4293
			lsr
			lsr
			and	#%00000011
			sta	$dd01
::2			lda	$dd01
			and	#%01110000
			cmp	#%00100000
			bne	:2

			lda	L4293
			lsr
			lsr
			lsr
			lsr
			and	#%00000011
			ora	#%00000100
			sta	$dd01
::3			lda	$dd01
			and	#%01110000
			cmp	#%01100000
			bne	:3

			lda	L4293
			rol
			rol
			rol
			and	#%00000011
			sta	$dd01
::4			lda	$dd01
			and	#%01110000
			cmp	#%00010000
			bne	:4
			lda	#$03
			sta	$dd01
			rts

:L4266			lda	#$04
			sta	$dd01

::1			lda	$dd01
			and	#%00001000
			beq	:1

			lda	$dd01
			lsr
			lsr
			lsr
			lsr
			and	#%00001111
			sta	L4293

			lda	#$00
			sta	$dd01
::2			lda	$dd01
			and	#%00001000
			bne	:2
			lda	$dd01
			and	#%11110000
			ora	L4293
			rts

:L4293			b $00
:L4294			b $00
:L4295			b $00
:L4296			b $00
:L4297			b $00
:L4298			b $00
:L4299			b $00
:L429a			b $00
:L429b			b $00
:L429c			b $00
:L429d			b $00
:L429e			b $00
:L429f			b $00
:L42a0			b $00
:L42a1			b $00
:L42a2			b $00
:L42a3			b $00
:L42a4			b $00
:L42a5			b $00
:L42a6			b $00
:L42a7			b $00
:L42a8			b $00
:L42a9			b $00
:L42aa			b $00
:L42ab			b $00
:L42ac			b $00
:L42ad			b $00
:L42ae			b $00
:L42af			b $00
:L42b0			b $00
:L42b1			b $00
:L42b2			b $00
:L42b3			b $00

;******************************************************************************
;*** GEOS-Uhrzeit setzen.
;******************************************************************************
;*** Uhrzeit einlesen.
:GetRTCTime		PushB	curDevice
			stx	curDevice
			jsr	GetRTCData
			PopB	curDevice
			rts

:GetRTCData		ClrB	STATUS			;Befehlskanal zum Gerät öffnen.
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

;******************************************************************************
;*** GEOS-Uhrzeit setzen.
;******************************************************************************
;*** SmartMouse auf RTC prüfen und Uhrzeit einlesen.
:GetRTCmodeSM		jsr	SM_RdClk		;Uhrzeit einlesen.

			ldx	RTC_SM_DATA  +0
			cpx	#$ff			;SmartMouse verfügbar ?
			bne	:51			;Nein, übergehen.
			ldx	#DEV_NOT_FOUND
			rts

::51			lda	RTC_SM_DATA  +5		;Wochentag.
			jsr	BCDtoDEZ
			sec
			sbc	#$01
			bcs	:52
			lda	#$00
::52			cmp	#$07
			bcc	:53
			lda	#$06
::53			sta	RTC_DATA +0

			lda	RTC_SM_DATA  +6		;Jahr.
			jsr	BCDtoDEZ
			sta	RTC_DATA +1

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

			LoadB	RTC_DATA +8,$0d

			ldx	#NO_ERROR
			rts

;*** SmartMouse-Zeitsystem korrigieren.
:SM_ConvHour1		cmp	#%10000000
			bcc	:101
			pha
			and	#%00100000
			tax
			pla
			and	#%00011111
			jmp	BCDtoDEZ

::101			and	#%00111111
			jsr	BCDtoDEZ
			ldx	#$00
			rts

			ldx	#$00
			cmp	#12
			bcc	:102
			dex
			rts

::102			cmp	#$00
			bne	:103
			lda	#12
::103			rts

;******************************************************************************
;*** GEOS-Uhrzeit setzen.
;******************************************************************************
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

;*** Uhrzeit einlesen.
:SM_RdClk		jsr	SM_Setup
			lda	#$bf			;burst rd clk cmd
			jsr	SM_SendCom		;send it
			ldy	#00
::101			jsr	SM_GetByte
			sta	RTC_SM_DATA,y
			iny
			cpy	#$08
			bcc	:101
			jsr	SM_End1
			jmp	SM_Exit

;*** Befehl an SmartMouse senden.
:SM_SendCom		pha
			jsr	SM_Init1		;SM_Output
			pla
:SM_Com1		jsr	SM_SendByte
			jmp	SM_Input

;******************************************************************************
;*** GEOS-Uhrzeit setzen.
;******************************************************************************
;*** Byte von SmartMouse einlesen.
:SM_GetByte		ldx	#08
::101			jsr	SM_Init3
			lda	mport
			lsr
			lsr
			lsr
			ror	RTC_SM_BUF +2
			jsr	SM_End2
			dex
			bne	:101
			lda	RTC_SM_BUF +2
			rts

;*** Byte an SmartMouse senden.
:SM_SendByte		sta	RTC_SM_BUF +2
			ldx	#08
::101			jsr	SM_Init3
			lda	#00
			ror	RTC_SM_BUF +2
			rol
			asl
			asl
			ora	#%11110001		;set io bit
			sta	mport
			jsr	SM_End2
			dex
			bne	:101
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

;******************************************************************************
;*** GEOS-Uhrzeit setzen.
;******************************************************************************
;*** Neue Uhrzeit setzen.
:SetCPUtime		ldx	#$02
::51			lda	RTC_DATA +1,x		;Datum festlegen.
			sta	year       ,x
			dex
			bpl	:51

			ldx	#19			;<*> Jahr2000-Byte definieren.
			cmp	#99
			bcs	:51a
			inx
::51a			stx	millenium

			lda	RTC_DATA +4		;Stunde nach BCD wandeln.
			ldx	RTC_DATA +7
			bne	:52
			cmp	#12
			bne	:53
			lda	#0
			beq	:53
::52			cmp	#12
			beq	:53
			clc
			adc	#12
::53			sta	RTC_DATA +4
			jsr	DEZtoBCD
			sed				;AM/PM-Flag berechnen.
			cmp	#$13
			bcc	:54
			sbc	#$12
			ora	#%10000000
::54			tax
			and	#%10000000
			sta	r0L
			lda	$dc0b
			ldy	$dc08
			txa
			sta	$dc0b			;Stunde setzen.
			cld

			lda	RTC_DATA +5
			jsr	DEZtoBCD		;Minute nach BCD wandeln.
			sta	$dc0a			;Minute setzen.

			lda	RTC_DATA +6
			jsr	DEZtoBCD		;Sekunde nach BCD wandeln.
			sta	$dc09			;Sekunde setzen.

			ClrB	$dc08
			rts

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
			beq	:102
::101			clc
			adc	#10
			dey
			bne	:101
::102			sta	r0L
			pla
			and	#%00001111
			clc
			adc	r0L
			rts
