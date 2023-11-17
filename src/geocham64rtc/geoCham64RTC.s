; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "TopSym"
			t "TopMac"

; Unterstützung für Ultimate64/II(+):
; Mögliche Werte:
:U2P_ON			= $1000
:U2P_OFF		= $0000
:ENABLE_U2P = U2P_OFF

; Sprache festlegen.
:LANG_DE		= $0110
:LANG_EN		= $0220
:LANG = LANG_DE

; TC64-Register
:cfgreg   = $d0fe ; config enable reg
:cfgspi   = $d0f1 ; SPI config reg

:mmcena   = 42    ; bring MMC to life
:mmcdis   = $ff   ; kill MMC
:mmcsel1  = $13   ; spictl init code
:mmcsel2  = $92   ; spidat init code
:mmcrtc   = $03   ; cfgspi init code

:spidat   = $df10 ; SPI data transfer reg
:spictl   = $df11 ; SPI control reg
:spistat  = $df12 ; SPI status reg
:spiread  = $00   ; SPI read init code
:spirdy   = $01   ; busy wait status code

; The PFC2123 does not know a century,
; so assume century to be 20:
;
; Ergänzung: 12.02.19/M.Kanet
; Wird für GEOS/MegaPatch64 nicht benötigt.
;century  = $20
;
; Ultimate II(+)
:ctrlreg		= $df1c				;control_register
:statreg		= $df1c				;status_register
:cmddatareg		= $df1d				;command_data_register
:respdatareg		= $df1e				;response_data_register
:statdatareg		= $df1f				;status_data_register
;
; C64/C128 CIA1 adress:
:CIA1_TOD_T		= $dc08
:CIA1_TOD_S		= $dc09
:CIA1_TOD_M		= $dc0a
:CIA1_TOD_H		= $dc0b
endif

			f AUTO_EXEC
			a "Markus Kanet"

			o APP_RAM
			p APP_RAM

			c "CHAM64RTC   V1.4"

if ENABLE_U2P!LANG = U2P_OFF!LANG_DE
			n "geoCham64RTC",NULL
endif
if ENABLE_U2P!LANG = U2P_OFF!LANG_EN
			n "geoCham64RTCen",NULL
endif
if ENABLE_U2P = U2P_OFF
			z $80 ;Nur GEOS64.
			i
<MISSING_IMAGE_DATA>
endif
if ENABLE_U2P!LANG = U2P_OFF!LANG_DE
			h "GEOS-Uhrzeit setzen mit der RTC des Chameleon64"
endif
if ENABLE_U2P!LANG = U2P_OFF!LANG_EN
			h "Set GEOS time using RTC from Chameleon64"
endif

if ENABLE_U2P!LANG = U2P_ON!LANG_DE
			n "geoCham64RTC+",NULL
endif
if ENABLE_U2P!LANG = U2P_ON!LANG_EN
			n "geoCham64RTC+en",NULL
endif
if ENABLE_U2P = U2P_ON
			z $40 ;GEOS64/128 und 40/80Zeichen..
			i
<MISSING_IMAGE_DATA>
endif
if ENABLE_U2P!LANG = U2P_ON!LANG_DE
			h "GEOS-Uhrzeit setzen mit der RTC des Chameleon64 oder Ultimate64/II(+)"
endif
if ENABLE_U2P!LANG = U2P_ON!LANG_EN
			h "Set GEOS time using RTC from Chameleon64 or Ultimate64/II(+)"
endif

;*** RTC des TurboChameleon auslesen.
:MAIN			jsr	InitForIO		;I/O aktivieren.

			lda	#mmcena			;TC64-Register aktivieren.
			sta	cfgreg
			ldx	cfgreg			;TC64-Status auslesen.
			lda	#mmcdis			;TC64-Register abschalten.
			sta	cfgreg

			cpx	#255			;#255 = C64 ohne TC64.
			bne	:TC64			; => TC64 aktiv.

if ENABLE_U2P = U2P_ON
			lda	cmddatareg		;Auf 1541Ultimate testen.
			cmp	#$c9
			beq	:U2P			;1541Ultimate gefunden.
endif

::err			jsr	DoneWithIO		;I/O abschalten.

			lda	firstBoot		;GEOS-BootUp?
			bpl	:end			; => Ja, Ende...
			lda	#<Dlg_NoRTC
			ldx	#>Dlg_NoRTC
			bne	:exitDlg		;Fehler ausgeben.

;*** Uhrzeit der UltimateII(+) einlesen.
if ENABLE_U2P = U2P_ON
::U2P			jsr	RD_U2P_RTC		;RTC einlesen.
			txa
			bne	:err

			jsr	ConvRTC2BCD		;RTC von ASCII nach BCD.

			jmp	:TC64_U2P		;Weiter...
endif

;*** Uhrzeit des TC64 einlesen.
::TC64			jsr	RD_TC64_RTC		;RTC einlesen.

;*** Uhrzeit aktualisieren.
::TC64_U2P		jsr	DoneWithIO		;I/O abschalten.

			jsr	ConvRTC2DEZ		;RTC-Daten BCD nach DEZ.

			jsr	SetGEOStime		;GEOS-Datum/Zeit setzen.
			jsr	SetCPUtime		;System-Zeit setzen.

;*** Ende...
			lda	firstBoot		;GEOS-BootUp?
			bpl	:end			; => Ja, Ende...

			lda	#<Dlg_RTCset
			ldx	#>Dlg_RTCset
::exitDlg		sta	r0L
			stx	r0H
			jsr	DoDlgBox		;Meldung ausgeben.
::end			jmp	EnterDeskTop		;Zurück zum DeskTop.

;*** Dialogbox für "Kein TC64".
:Dlg_NoRTC		b %10000001
			b DBTXTSTR   ,$10,$0b
			w :51
if ENABLE_U2P = U2P_OFF
			b DBTXTSTR   ,$10,$24
			w :52
endif
if ENABLE_U2P = U2P_ON
			b DBTXTSTR   ,$10,$18
			w :52
			b DBTXTSTR   ,$10,$22
			w :53
			b DBTXTSTR   ,$10,$2e
			w :54
			b DBTXTSTR   ,$10,$38
			w :55
			b DBTXTSTR   ,$10,$42
			w :56
endif
			b OK         ,$02,$48
			b NULL

::51			b PLAINTEXT, BOLDON
if LANG = LANG_DE
			b "FEHLER !!!",NULL
endif
if LANG = LANG_EN
			b "ERROR !!!",NULL
endif

::52			b PLAINTEXT
if ENABLE_U2P!LANG = U2P_OFF!LANG_DE
			b "Kein 'Chameleon64'-Modul erkannt!",NULL
endif
if ENABLE_U2P!LANG = U2P_OFF!LANG_EN
			b "No 'Chameleon64' module detected!",NULL
endif
if ENABLE_U2P!LANG = U2P_ON!LANG_DE
			b "Kein 'Chameleon64` oder",NULL
::53			b "'Ultimate64/II(+)'-Modul erkannt!",NULL
endif
if ENABLE_U2P!LANG = U2P_ON!LANG_EN
			b "No 'Chameleon64' or",NULL
::53			b "'Ultimate64/II(+)' module detected!",NULL
endif
if ENABLE_U2P = U2P_ON
::54			b BOLDON
			b "Ultimate 64/II(+) "
endif
if ENABLE_U2P!LANG = U2P_ON!LANG_DE
			b "Anwender:"
endif
if ENABLE_U2P!LANG = U2P_ON!LANG_EN
			b "users:"
endif
if ENABLE_U2P = U2P_ON
			b PLAINTEXT
			b NULL
::55			b "-> C64 AND CARTRIDGE SETTINGS",NULL
::56			b "-> COMMAND INTERFACE = ENABLED",NULL
endif

;*** Dialogbox für "Uhrzeit gesetzt".
:Dlg_RTCset		b %10000001
			b DBTXTSTR   ,$10,$0b
			w :51
			b DBTXTSTR   ,$10,$20
			w :52
			b OK         ,$02,$48
			b NULL

::51			b PLAINTEXT, BOLDON
			b "INFORMATION"
			b NULL

::52			b PLAINTEXT
if LANG = LANG_DE
			b "Datum und Uhrzeit aktualisiert!",NULL
endif
if LANG = LANG_EN
			b "Date and time have been updated!",NULL
endif

;*** GEOS-Datum/Zeit setzen.
:SetGEOStime		lda	RTC_DEZ +1		;GEOS-Jahreszahl setzen.
			sta	year
			lda	RTC_DEZ +2		;GEOS-Monat setzen.
			sta	month
			lda	RTC_DEZ +4		;GEOS-Tag setzen.
			sta	day
			lda	RTC_DEZ +5		;GEOS-Stunde setzen.
			sta	hour
			lda	RTC_DEZ +6		;GEOS-Minute setzen.
			sta	minutes
			lda	RTC_DEZ +7		;GEOS-Sekunde setzen.
			sta	seconds
			rts

;*** System-Uhrzeit setzen.
:SetCPUtime		jsr	InitForIO		;I/O aktivieren.

			lda	RTC_BCD +5
			sed				;AM/PM-Flag berechnen.
			cmp	#$13
			bcc	:2
			sbc	#$12
			ora	#%10000000
::2			tax
			lda	CIA1_TOD_H		;TOD-Clock einfrieren und
			ldy	CIA1_TOD_T		;wieder starten.

			txa
			sta	CIA1_TOD_H		;System-Stunde setzen.
			cld

			lda	RTC_BCD +6
			sta	CIA1_TOD_M		;System-Minute setzen.

			lda	RTC_BCD +7
			sta	CIA1_TOD_S		;System-Sekunde setzen.

			lda	#$00			;Uhr starten.
			sta	CIA1_TOD_T

			jmp	DoneWithIO		;I/O abschalten.

;*** RTC-Daten von BCD nach DEZ wandeln.
:ConvRTC2DEZ		ldx	#$07
::1			txa
			pha
			lda	RTC_BCD,x
			jsr	BCDtoDEZ
			tay
			pla
			tax
			tya
			sta	RTC_DEZ,x
			dex
			bne	:1
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

;
; Read Turbo Chameleon 64 RTC
;
; Written by Paul Foerster
; (paul.foerster(at)gmail.com), based on
; Yahoo Chameleon 64 group, article #349
; by Peter Wendrich (pwsoft(at)syntiac.com)
;
; Chameleon 64 clock chip: PCF2123
;
; Output of RTC:
; CC YY MM WD DD HH MM SS (8 bytes)
; value output format is BCD
;

; Enable config mode
:RD_TC64_RTC		lda	#mmcena
			sta	cfgreg

; Save old config
			lda	cfgspi
			pha
			lda	spictl
			pha

; MMC emulation and RTC enable
			lda	#mmcrtc
			sta	cfgspi
			sta	spictl

; MMC active, 250 kHz, RTC selected
			lda	#mmcsel1
			sta	spictl

; Set SPI transfer control for reading
			lda	#mmcsel2
			sta	spidat
::wait1			lda	spistat
			and	#spirdy
			bne	:wait1

; Read 7 date/time bytes sequentially
			ldx	#$07
::getval		lda	#spiread
			sta	spidat
::wait2			lda	spistat
			and	#spirdy
			bne	:wait2
			lda	spidat
			sta	RTC_BCD,x
			dex
			bne	:getval

; Set assumed century here
;
; Ergänzung: 12.02.19/M.Kanet
; Wird für GEOS/MegaPatch64 nicht benötigt.
;			lda	#century
;			sta	RTC_BCD

; Restore old Chameleon 64 config
			pla
			sta	spictl
			pla
			sta	cfgspi

; Disable Chameleon 64 config mode
			lda	#mmcdis
			sta	cfgreg
			rts

:RTC_BCD		s $08 ; clock output buffer BCD
:RTC_DEZ		s $08 ; clock output buffer DEZ

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
if ENABLE_U2P = U2P_ON
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
			bne	:err
::ok			ldx	#$00			;Alles OK.
			b $2c
::err			ldx	#$0d			;Fehler.
			rts

;*** RTC-Daten der U2P nach BCD wandeln.
:ConvRTC2BCD		lda	U2P_RTC+2		;Jahreszahl.
			ldx	U2P_RTC+3
			jsr	ASCIItoBCD
			sta	RTC_BCD +1

; Ergänzung: 14.02.19/M.Kanet
; Wird für GEOS/MegaPatch64 nicht benötigt.
;			lda	U2P_RTC+0		;Jahrhundert.
;			ldx	U2P_RTC+1
;			jsr	ASCIItoBCD
;			sta	RTC_BCD +0

			lda	U2P_RTC+5		;Monat.
			ldx	U2P_RTC+6
			jsr	ASCIItoBCD
			sta	RTC_BCD +2

; Ergänzung: 14.02.19/M.Kanet
; Wird für GEOS/MegaPatch64 nicht benötigt.
;			lda	#$00			;Wochentag.
;			sta	RTC_BCD +3

			lda	U2P_RTC+8		;Tag.
			ldx	U2P_RTC+9
			jsr	ASCIItoBCD
			sta	RTC_BCD +4

			lda	U2P_RTC+11		;Stunde.
			ldx	U2P_RTC+12
			jsr	ASCIItoBCD
			sta	RTC_BCD +5

			lda	U2P_RTC+14		;Minute.
			ldx	U2P_RTC+15
			jsr	ASCIItoBCD
			sta	RTC_BCD +6

			lda	U2P_RTC+17		;Sekunde.
			ldx	U2P_RTC+18
			jsr	ASCIItoBCD
			sta	RTC_BCD +7
			rts

;*** ASCII nach BCD wandeln.
;Die RTC-Daten des TC64 liegen ebenfalls im BCD vor.
;Um die restlichen Routinen zu vereinheitlichen werden
;die ASCII-Daten nach BCD gewandelt. Für die TOD des
;C64 werden die Daten ebenfalls in BCD benötigt.
:ASCIItoBCD		sec
			sbc	#$30
			asl
			asl
			asl
			asl
			sta	r0L
			txa
			sec
			sbc	#$30
			ora	r0L
			rts

:U2P_STAT		s 30 ; clock status buffer ASCII
:U2P_RTC		s 30 ; clock output buffer ASCII
endif
