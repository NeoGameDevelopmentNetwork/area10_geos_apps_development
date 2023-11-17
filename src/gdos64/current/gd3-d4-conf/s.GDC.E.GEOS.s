; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_CROM"
			t "SymbTab_CXIO"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_MMAP"
			t "SymbTab_CHAR"
			t "SymbTab_SCPU"
			t "MacTab"

;--- Externe Labels.
			t "s.GD3_KERNAL.ext"
			t "s.GDC.Config.ext"
			t "o.DiskCore.ext"

;--- I/O-Register CMD-SmartMouse.
:mport			= cia1base + 1
:mpddr			= cia1base + 3

;--- I/O-Register TurboChameleon64.
:cfgreg   = $d0fe ; config enable reg
:cfgspi   = $d0f1 ; SPI config reg

:mmcena   = $2a    ; bring MMC to life
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

;--- I/O-Register Ultimate 64/II(+).
;
; Note:
; Firmware 1.34 is known to be broken
; because of the Turbo-Mode.
; This firmware, or any newer version,
; is currently not supported.
;
; Ultimate users must enable:
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

;*** GEOS-Header.
			n "obj.CFG.GEOS"
			f DATA

			o BASE_GCFG_BOOT

;******************************************************************************
;*** Sprungtabelle.
;******************************************************************************
:MainInit		jmp	BOOT_GDC_GEOS
;******************************************************************************

;*** AutoBoot: GD.CONF.GEOS.
:BOOT_GDC_GEOS		lda	BootMenuStatus		;Menü-Modus setzen.
			sta	Flag_MenuStatus

			lda	BootMLineMode		;Menü-Trennlinien setzen.
			sta	Flag_SetMLine

			lda	BootColsMode		;Farbmodus setzen.
			sta	Flag_SetColor

			lda	BootCRSR_Repeat		;Cursor-Frequenz setzen.
			sta	Flag_CrsrRepeat

			lda	sysRAMFlg		;CREU/MoveData setzen.
			and	#%01111111
			sta	sysRAMFlg
			lda	BootRAM_Flag
			and	#%10000000
			ora	sysRAMFlg
			sta	sysRAMFlg
			sta	sysFlgCopy

			jsr	e_GetSCPUdata		;SCPU erkennen / SpeedFlag auslesen.

			bit	SCPU_Enabled		;Ist SuperCPU aktiviert ?
			bpl	:1			; => Nein, weiter...

			lda	BootOptimize		;Optimierung für SuperCPU
			sta	Flag_Optimize		;festlegen.
			jsr	SCPU_SetOpt

			lda	BootSpeed		;SpeedMode für SuperCPU
			jsr	e_SetSFlagSCPU		;festlegen.

::1			jsr	e_SetNameDT		;Name DeskTop festlegen.

if LANG = LANG_DE
			jsr	e_InitQWERTZ		;QWERTZ/QWERTY-Tastatur aktivieren.
endif

;------------------------------------------------------------------------------
; DRIVECORE
;
;Vor dem Aufruf der Suchroutine für
;RTCs darf auf dem aktiven Laufwerk
;das TurboDOS nicht mehr aktiv sein!
;
			jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	_DDC_DETECTALL		;Geräte am ser.Bus erkennen.
;------------------------------------------------------------------------------

			jmp	e_SetClockGEOS		;Uhrzeit setzen.

;*** SuperCPU-Daten abfragen.
.e_GetSCPUdata		lda	#$00			;Takt für SCPU auf 1Mhz setzen.
			sta	SCPU_SpeedMode		;(Falls keine SCPU vorhanden)
			sta	SCPU_Enabled		;Flag: "Keine SCPU" setzen.

			php
			sei
			ldx	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA
			lda	SCPU_HW_CHECK
			and	#%10000000		;Bit 7=1, SCPU nicht aktiv.
			bne	:1
			dec	SCPU_Enabled		;Flag setzen: "SCPU verfügbar".

			lda	SCPU_HW_SPEED
			and	#%01000000		;Bit 6=0, SCPU mit 20 Mhz.
			sta	SCPU_SpeedMode		;Aktuellen SCPU-Takt speichern.

::1			stx	CPU_DATA
			plp
			rts

;*** SuperCPU-SpeedFlag setzen.
.e_SetSFlagSCPU		php				;SuperCPU-Taktfrequenz festlegen.
			sei
			ldx	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA
			ldy	#$00
			bit	BootSpeed
			bvs	:1
			iny
::1			sta	SCPU_HW_NORMAL,y	;Takt über Register $D07A/$D07B
			stx	CPU_DATA		;einstellen.
			plp
			rts

;*** QWERTZ/QWERTY-Tastatur aktivieren.
if LANG = LANG_DE
.e_InitQWERTZ		bit	BootQWERTZ
			bmi	:QWERTZ

::QWERTY		ldx	#"Z"
			ldy	#"Y"
			jsr	:setKeys1
			ldx	#"z"
			ldy	#"y"
			bne	:setKeys0

::QWERTZ		ldx	#"Y"
			ldy	#"Z"
			jsr	:setKeys1
			ldx	#"y"
			ldy	#"z"

::setKeys0		stx	key0z
			sty	key0y
			rts
::setKeys1		stx	key1z
			sty	key1y
			rts
endif

;*** Name DeskTop-Datei festlegen.
.e_SetNameDT		ldy	#0
::1			lda	BootNameDT,y
			beq	:2
			sta	DBoxDTopName,y
			iny
			cpy	#DBoxDTopNmLen
			bcc	:1
			bcs	:4
::2			lda	#" "
::3			sta	DBoxDTopName,y
			iny
			cpy	#DBoxDTopNmLen
			bcc	:3

::4			ldy	#0
::5			lda	BootFileDT,y
			beq	:6
			sta	DeskTopName,y
			iny
			cpy	#DTopFileNmLen
			bcc	:5
			lda	#NULL
::6			sta	DeskTopName,y
			iny
			cpy	#DTopFileNmLen +1
			bcc	:6

::exit			rts

;*** Neue Uhrzeit setzen.
.e_SetGEOStime		lda	RTC_DATA +1		;GEOS-Jahreszahl setzen.
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
.e_SetCPUtime		jsr	ConvHour24h
			jsr	e_DEZtoBCD
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
			jsr	e_DEZtoBCD		;Minute nach BCD wandeln.
			sta	cia1tod_m		;Minute setzen.

			lda	RTC_DATA +6
			jsr	e_DEZtoBCD		;Sekunde nach BCD wandeln.
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
.e_DEZtoBCD		ldx	#0
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
.e_BCDtoDEZ		pha
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

;*** GEOS-Uhrzeit setzen.
.e_SetClockGEOS		lda	BootRTCdrive		;Uhrzeit setzen ?
			beq	:3			; => Nein, weiter...
			cmp	#$ff			;Automatik ?
			beq	:2			; => Ja, RTC-Gerät suchen.

::1			jsr	e_FindRTCdev		;Laufwerk suchen und Zeit setzen.
			txa				;RTC-Fehler ?
			beq	:3			; => Nein, weiter...

;--- Vorgegebenes Laufwerk nicht gefunden.
;    Andere Laufwerke mit RTC-Uhr suchen.
::2			lda	#$fc			;TurboChameleon64 suchen.
			jsr	e_FindRTCdev
			txa				;RTC-Fehler ?
			beq	:3			; => Nein, weiter...

			lda	#$fd			;Ultimate64/II(+) suchen.
			jsr	e_FindRTCdev
			txa				;RTC-Fehler ?
			beq	:3			; => Nein, weiter...

			lda	#$fe			;SmartMouse mit RTC-Uhr suchen.
			jsr	e_FindRTCdev
			txa				;RTC-Fehler ?
			beq	:3			; => Nein, weiter...

			lda	#DrvFD			;CMD_FD mit RTC-Uhr suchen.
			jsr	e_FindRTCdev
			txa				;RTC-Fehler ?
			beq	:3			; => Nein, weiter...

			lda	#DrvHD			;CMD_HD mit RTC-Uhr suchen.
			jsr	e_FindRTCdev
			txa				;RTC-Fehler ?
			beq	:3			; => Nein, weiter...

			lda	#DrvRAMLink		;RAMLink mit RTC-Uhr suchen.
			jmp	e_FindRTCdev
::3			rts

;*** Gerät mit Echtzeituhr suchen.
.e_FindRTCdev		cmp	#$fc			;TurboChameleon64 ?
			bne	:test_u64		; => Nein, weiter...
			jmp	e_FindRTC_TC64		; => Ja, Gerät testen.

::test_u64		cmp	#$fd			;Ultimate64/II(+) ?
			bne	:test_cmdsm		; => Nein, weiter...
			jmp	e_FindRTC_U2P		; => Ja, Gerät testen.

::test_cmdsm		cmp	#$fe			;SmartMouse ?
			bne	:test_cmd		; => Nein, weiter...
			jmp	e_FindRTC_SMse		; => Ja, Gerät testen.

::test_cmd		jmp	e_FindRTC_CMD		; => CMD-Laufwerk testen.

;*** CMD-Laufwerk mit RTC suchen.
.e_FindRTC_CMD		pha
			jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	InitForIO		;I/O-Bereich einblenden.
			pla

			ldy	#$08
::1			cmp	_DDC_DEVTYPE -8,y
			bne	:2
			pha
			jsr	TestRTC_CMD
			pla
			cpx	#NO_ERROR
			bne	:2

			jsr	e_SetCPUtime		;System-Uhrzeit setzen.
			jsr	e_SetGEOStime		;GEOS-Uhrzeit setzen.

			ldx	#NO_ERROR
			jmp	DoneWithIO		;I/O-Bereich ausblenden.

::2			iny
			cpy	#29 +1
			bcc	:1

			ldx	#DEV_NOT_FOUND
			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** Uhrzeit einlesen.
:TestRTC_CMD		PushB	curDevice
			sty	curDevice

			jsr	ReadRTC_CMD
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

:ReadRTC_CMD		ClrB	STATUS			;Befehlskanal zum Gerät öffnen.
			jsr	UNLSN
			lda	curDevice
			jsr	LISTEN
			lda	#$ff
			jsr	SECOND

			bit	STATUS
			bpl	:51
			jsr	UNLSN
			ldx	#DEV_NOT_FOUND
			rts

::51			ldy	#$00			;Befehl zum lesen der Uhrzeit an
::52			lda	:RTC_GetTime,y		;Laufwerk senden.
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

			bit	STATUS
			bpl	:53
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
::RTC_GetTime		b "T-RD"			;Read Date+Time.

;*** SmartMouse mit RTC suchen.
.e_FindRTC_SMse		jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	TestRTC_SMse		;SmartMouse-RTC abfragen.
			txa				;RTC-Fehler ?
			bne	:1			; => Ja, Ende...

			jsr	e_SetCPUtime		;System-Uhrzeit setzen.
			jsr	e_SetGEOStime		;GEOS-Uhrzeit setzen.

			ldx	#NO_ERROR
::1			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** SmartMouse auf RTC prüfen und Uhrzeit einlesen.
:TestRTC_SMse		jsr	ReadRTC_SMse		;Uhrzeit einlesen.

			ldx	RTC_SM_DATA  +0
			cpx	#$ff			;SmartMouse verfügbar ?
			bne	:1			;Nein, übergehen.
			ldx	#DEV_NOT_FOUND
			rts

::1			lda	RTC_SM_DATA  +5		;Wochentag.
			jsr	e_BCDtoDEZ
			sec
			sbc	#$01
			bcs	:2
			lda	#$00
::2			cmp	#$07
			bcc	:3
			lda	#$06
::3			sta	RTC_DATA +0

			lda	RTC_SM_DATA  +6		;Jahr.
			jsr	e_BCDtoDEZ
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
			jsr	e_BCDtoDEZ
			sta	RTC_DATA +2

			lda	RTC_SM_DATA  +3		;Tag.
			jsr	e_BCDtoDEZ
			sta	RTC_DATA +3

			lda	RTC_SM_DATA  +2		;Stunde.
			jsr	SM_ConvHour1
			sta	RTC_DATA +4
			stx	RTC_DATA +7

			lda	RTC_SM_DATA  +1		;Minute.
			jsr	e_BCDtoDEZ
			sta	RTC_DATA +5

			lda	RTC_SM_DATA  +0		;Sekunde.
			jsr	e_BCDtoDEZ
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
			jmp	e_BCDtoDEZ

::1			and	#%00111111
			jsr	e_BCDtoDEZ
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
:ReadRTC_SMse		jsr	SM_Setup
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

;*** TurboChameleon64 mit RTC suchen.
.e_FindRTC_TC64		jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	TestRTC_TC64		;TurboChameleon64-RTC abfragen.
			txa				;RTC-Fehler ?
			bne	:1			; => Ja, Ende...

			jsr	e_SetCPUtime		;System-Uhrzeit setzen.
			jsr	e_SetGEOStime		;GEOS-Uhrzeit setzen.

			ldx	#NO_ERROR
::1			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** TurboChameleon64 auf RTC prüfen und Uhrzeit einlesen.
:TestRTC_TC64		lda	#mmcena			;TC64-Register aktivieren.
			sta	cfgreg
			ldx	cfgreg			;TC64-Status auslesen.
			lda	#mmcdis			;TC64-Register abschalten.
			sta	cfgreg

			cpx	#255			;#255 = C64 ohne TC64.
			bne	:1			; => TC64 aktiv.

			ldx	#DEV_NOT_FOUND
			rts

::1			jsr	ReadRTC_TC64		;RTC einlesen.
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
:ReadRTC_TC64		lda	#mmcena
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
			sta	:tc64_rtcbcd,x
			dex
			bne	:getval

; Set assumed century here
;			lda	#century
;			sta	:tc64_rtcbcd

; Restore old Chameleon 64 config
			pla
			sta	spictl
			pla
			sta	cfgspi

; Disable Chameleon 64 config mode
			lda	#mmcdis
			sta	cfgreg

; Convert BCD to DEZ
::convert_bcd		lda	:tc64_rtcbcd +3		;Wochentag.
			jsr	e_BCDtoDEZ
			sta	RTC_DATA +0

			lda	:tc64_rtcbcd +1		;Jahr.
			jsr	e_BCDtoDEZ
			sta	RTC_DATA +1

;--- Ergänzung: 18.02.19/M.Kanet
; Jahrtausend nicht unterstützt.
; Annahme für 1980-1999 / 2000-2079.
			ldy	#19			;Jahrtausend festlegen.
			cmp	#80			;80-99?
			bcs	:year2k			; => Ja,   1980-1999
			iny				; => Nein, 2000-2079
::year2k		sty	RTC_MILLENIUM

			lda	:tc64_rtcbcd +2		;Monat
			jsr	e_BCDtoDEZ
			sta	RTC_DATA +2

			lda	:tc64_rtcbcd +4		;Tag.
			jsr	e_BCDtoDEZ
			sta	RTC_DATA +3

			lda	:tc64_rtcbcd +5
			ldx	#0
			sed				;AM/PM-Flag berechnen.
			cmp	#$12
			bcc	:hour
			sbc	#$12
			dex
::hour			cld
			stx	RTC_DATA +7		;AM/PM.

;--- Ergänzung: 27.02.23/M.Kanet
;Uhrzeit von 24H nach AM/PM wandeln.
;00:00 ist 12AM, 12:00 ist 12PM!
			cmp	#0
			bne	:hour1
			lda	#12			;00AM/PM = 12AM/PM.
::hour1			jsr	e_BCDtoDEZ
			sta	RTC_DATA +4		;Stunde.

			lda	:tc64_rtcbcd +6		;Minute.
			jsr	e_BCDtoDEZ
			sta	RTC_DATA +5

			lda	:tc64_rtcbcd +7		;Sekunde.
			jsr	e_BCDtoDEZ
			sta	RTC_DATA +6

;			lda	#CR			;Füllbyte.
;			sta	RTC_DATA +8

			ldx	#NO_ERROR		;Kein Fehler.
			rts

::tc64_rtcbcd		s $08 ; clock output buffer BCD
::tc64_rtcdez		s $08 ; clock output buffer DEZ

;*** Ultimate64/II(+) mit RTC suchen.
.e_FindRTC_U2P		jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	TestRTC_U2P		;Ultimate64/II(+)-RTC abfragen.
			txa				;RTC-Fehler ?
			bne	:1			; => Ja, Ende...

			jsr	e_SetCPUtime		;System-Uhrzeit setzen.
			jsr	e_SetGEOStime		;GEOS-Uhrzeit setzen.

			ldx	#NO_ERROR
::1			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** Ultimate64/II(+) auf RTC prüfen und Uhrzeit einlesen.
:TestRTC_U2P		lda	cmddatareg		;Auf 1541Ultimate testen.
			cmp	#$c9
			beq	:1			;1541Ultimate gefunden.

			ldx	#DEV_NOT_FOUND
			rts

::1			jsr	ReadRTC_U2P		;RTC einlesen.
;			txa
;			bne	:err
;
;			ldx	#NO_ERROR
:err			rts

;
; Read Ultimate 64/II(+) RTC
;
; Written by Torsten Kracke
; Updated by Markus Kanet
;
; This code is heavily based on
; the source code "IDE64RTC"
; by Maciej Witkowiak
;
; Output of RTC:
; CCYY/MM/DD HH:MM:SS (18 bytes)
; 0123456789012345678
; 0000000000111111111
;
; value output format is ASCII
;
:ReadRTC_U2P		lda	#$01			;'DOS_CMD_GET_TIME' an
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

::wait			lda	#%00100000
			bit	statreg
			beq	:wait
			bvc	:gettime		;Status einlesen.

			lda	statdatareg
			sta	:u2p_status,y
			iny
			jmp	:wait

::gettime		bpl	:rcvd			;RTC-Zeit einlesen.

			lda	respdatareg
			sta	:u2p_rtcdata,x
			inx
			jmp	:wait

::rcvd			lda	#$02			;Empfang der Daten
			sta	ctrlreg			;bestätigen.
			lda	#$10
::busy2			bit	statreg
			bne	:busy2

::statusok		lda	:u2p_status+0		;Status auswerten.
			cmp	#"0"
			bne	:err
			lda	:u2p_status+1
			cmp	#"0"
			beq	:convert_ascii
::err			ldx	#DEV_NOT_FOUND		;Fehler.
			rts

;--- RTC-Daten der U2P nach DEZ wandeln.
::convert_ascii		lda	:u2p_rtcdata+2		;Jahreszahl.
			ldx	:u2p_rtcdata+3
			jsr	:ascii2dez
			sta	RTC_DATA +1

			lda	:u2p_rtcdata+0		;Jahrtausend.
			ldx	:u2p_rtcdata+1
			jsr	:ascii2dez
			sta	RTC_MILLENIUM

			lda	:u2p_rtcdata+5		;Monat.
			ldx	:u2p_rtcdata+6
			jsr	:ascii2dez
			sta	RTC_DATA +2

			lda	:u2p_rtcdata+8		;Tag.
			ldx	:u2p_rtcdata+9
			jsr	:ascii2dez
			sta	RTC_DATA +3

; Ergänzung: 14.02.19/M.Kanet
; Wird für GEOS nicht benötigt.
; (Existiert für Ultimate64/II(+) auch nicht)
;			lda	#$00			;Wochentag.
;			sta	RTC_DATA +0

			lda	:u2p_rtcdata+11		;Stunde.
			ldx	:u2p_rtcdata+12
			jsr	:ascii2dez

;--- Ergänzung: 22.02.23/M.Kanet
;Uhrzeit von 24H nach AM/PM wandeln.
;00:00 ist 12AM, 12:00 ist 12PM!
			ldx	#$00			;AM/PM-Flag berechnen.
			cmp	#12			;00-11=12-11AM
			bcc	:hour			;12-23=12-11PM
			sbc	#12
			dex
::hour			cmp	#0
			bne	:hour1
			lda	#12			;00AM/PM = 12AM/PM.
::hour1			sta	RTC_DATA +4
			stx	RTC_DATA +7

			lda	:u2p_rtcdata+14		;Minute.
			ldx	:u2p_rtcdata+15
			jsr	:ascii2dez
			sta	RTC_DATA +5

			lda	:u2p_rtcdata+17		;Sekunde.
			ldx	:u2p_rtcdata+18
			jsr	:ascii2dez
			sta	RTC_DATA +6

;			lda	#CR			;Füllbyte.
;			sta	RTC_DATA +8

			ldx	#NO_ERROR
			rts

;*** ASCII nach DEZ wandeln.
::ascii2dez		sec
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

::u2p_status		s 30 ; clock status buffer ASCII
::u2p_rtcdata		s 30 ; clock output buffer ASCII

;*** SuperCPU-optionen.
.SCPU_SpeedMode		b $00
.SCPU_Enabled		b $00

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

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g BASE_DDRV_INFO
;******************************************************************************
