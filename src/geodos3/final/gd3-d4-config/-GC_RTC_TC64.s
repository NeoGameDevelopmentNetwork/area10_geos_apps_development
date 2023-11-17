; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
;
; TurboChameleon64 v1/v2:
;
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
;century  = $20
;
endif

;*** TurboChameleon64 mit RTC suchen.
:FindRTC_TC64		jsr	PurgeTurbo		;TurboDOS abschalten und
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	GetRTCmodeTC64		;TurboChameleon64-RTC abfragen.
			txa				;RTC-Fehler ?
			bne	:1			; => Ja, Ende...

			jsr	SetCPUtime		;System-Uhrzeit setzen.
			jsr	SetGEOStime		;GEOS-Uhrzeit setzen.

			ldx	#NO_ERROR
::1			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** TurboChameleon64 auf RTC prüfen und Uhrzeit einlesen.
:GetRTCmodeTC64		lda	#mmcena			;TC64-Register aktivieren.
			sta	cfgreg
			ldx	cfgreg			;TC64-Status auslesen.
			lda	#mmcdis			;TC64-Register abschalten.
			sta	cfgreg

			cpx	#255			;#255 = C64 ohne TC64.
			bne	:1			; => TC64 aktiv.

			ldx	#DEV_NOT_FOUND
			rts

::1			jsr	RD_TC64_RTC		;RTC einlesen.
;			txa
;			bne	:err
;
;			ldx	#NO_ERROR
::err			rts

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

; Convert BCD to DEZ
::convert_bcd		lda	RTC_BCD +3		;Wochentag.
			jsr	BCDtoDEZ
			sta	RTC_DATA +0

			lda	RTC_BCD +1		;Jahr.
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

			lda	RTC_BCD +2		;Monat
			jsr	BCDtoDEZ
			sta	RTC_DATA +2

			lda	RTC_BCD +4		;Tag.
			jsr	BCDtoDEZ
			sta	RTC_DATA +3

			lda	RTC_BCD +5
			ldx	#$00
			sed				;AM/PM-Flag berechnen.
			cmp	#$13
			bcc	:hour
			sbc	#$12
			dex
::hour			sta	RTC_DATA +4		;Stunde.
			stx	RTC_DATA +7		;AM/PM.

			lda	RTC_BCD +6		;Minute.
			sta	RTC_DATA +5

			lda	RTC_BCD +7		;Sekunde.
			sta	RTC_DATA +6

;			lda	#CR			;Füllbyte.
;			sta	RTC_DATA +8

			ldx	#NO_ERROR		;Kein Fehler.
			rts

:RTC_BCD		s $08 ; clock output buffer BCD
:RTC_DEZ		s $08 ; clock output buffer DEZ
