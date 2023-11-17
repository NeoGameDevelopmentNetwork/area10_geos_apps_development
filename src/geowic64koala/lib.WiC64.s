; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; lib.WiC64
;
;GEOS-Bibliothek für das WiC64.
; * Hardware-Check
; * Turbo-Modus setzen/löschen
; * IP/SSID/RSSI abfragen
; * Timezone setzen/abfragen.
; * Datum/Zeit über NTP abfragen.
; * Befehl senden/Daten empfangen
;
; (w) 2022 / M.Kanet
;
; v0.10: Initial release.
;

;
; KONFIGURATION:
;
if .p
;--- Standard-Werte für Timeout.
;Für Abfragen via Internet:
:timeout_default	= 50  ;50 x 1/10s = ca. 5.0s.
;
;Für Abfragen zur Hardware:
:timeout_fast		= 5   ; 5 x 1/10s = ca. 0.5s.
;
endif

;*** Symboltabellen.
if .p
;--- Fehler-Codes.
:ERR_UNKNOWN		= $80
:ERR_NO_WIC64		= $81
:ERR_BAD_CONFIG		= $82
:ERR_ESP_TIMEOUT	= $83
:ERR_BAD_URL		= $84
:ERR_NO_SIZE_DATA	= $85
:ERR_BAD_SEND_LEN	= $86
:ERR_BAD_SEND_ADR	= $87
:ERR_BAD_GET_LEN	= $88
:ERR_NO_DATA		= $89
:ERR_INIT_DLOAD		= $8a
:ERR_BAD_NTP_DATA	= $8b
:ERR_MAX		= 12

;--- TurboChameleon64-Register.
:TC64_HW_EN_DIS		= $d0fe
:TC64_HW_SPEED		= $d0f3

;--- SuperCPU-Register.
:SCPU_HW_EN		= $d07e
:SCPU_HW_DIS		= $d07f
:SCPU_HW_CHECK		= $d0bc
;:SCPU_HW_OPT		= $d0b4
:SCPU_HW_NORMAL		= $d07a
;:SCPU_HW_TURBO		= $d07b
:SCPU_HW_SPEED		= $d0b8
;:SCPU_HW_VIC_OPT	= $d074
;:SCPU_HW_VIC_B2	= $d074
;:SCPU_HW_VIC_B1	= $d075
;:SCPU_HW_VIC_BAS	= $d076
:SCPU_HW_VIC_OFF	= $d077
;:SRAM_FIRST_PAGE	= $d27c
;:SRAM_FIRST_BANK	= $d27d
;:SRAM_LAST_PAGE	= $d27e
;:SRAM_LAST_BANK	= $d27f
;:SRAM_USER_PAGE	= $d300 ;Free RAM $D300-$D3FF.
;:SCPU_ROM_VER		= $e487 ;Überprüfen der SuperCPU-Version.

;*** CIA2 Kontrollregister.
:CIA2_DPR_A		= $dd00
:CIA2_DPR_B		= $dd01
:CIA2_DDR_A		= $dd02
:CIA2_DDR_B		= $dd03
:CIA2_ICR		= $dd0d
endif

;*** Auf WiC64 testen.
:_WiC64_CHECK		jsr	PurgeTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O-Bereich einschalten.

			bit	flagTurboMode		;CPU-Turbo aktiv?
			bpl	:1			; => Nein, weiter...
			jsr	_WiC64_TURBO_OFF	;CPU-Turbo abschalten.

::1			jsr	_WiC64_Init		;WiC64 zurücksetzen.

			jsr	_WiC64_GetIP		;WiC64-IP einlesen.

			lda	r12L			;Datenempfang beendet?
			beq	:err_no_wic64		; => Nein, kein WiC64.
			lda	r12H			;WiC64 vorhanden?
			beq	:err_no_wic64		; => Nein, Ende...
			cmp	#"0"			;`0.0.0.0`?
			beq	:err_config		; => Ja, nicht verbunden.

if ENABLE_GETSSID = TRUE
			jsr	_WiC64_GetSSID		;Netzwerkname einlesen.
			txa				;Fehler/Timeout?
			bne	:error			; => Ja, Abbruch...
endif

if ENABLE_GETRSSI = TRUE
			jsr	_WiC64_GetRSSI		;Signalstärke einlesen.
			txa				;Fehler/Timeout?
			bne	:error			; => Ja, Abbruch...
endif

			jsr	_WiC64_ReadMode		;WiC64 auf `Empfang` umschalten.
			jsr	_WiC64_Init		;WiC64 zurücksetzen.

			lda	#NO_ERROR		;WiC64: OK.
			b $2c
::err_no_wic64		lda	#ERR_NO_WIC64		;WiC64: Nicht vorhanden/verbunden.
			b $2c
::err_config		lda	#ERR_BAD_CONFIG		;WiC64: Nicht vorhanden/verbunden.
::error			sta	flagWiC64rdy		;WiC64-Status speichern.

			bit	flagTurboMode		;War CPU-Turbo aktiv?
			bpl	:3			; => Nein, weiter...
			jsr	_WiC64_TURBO_ON		;CPU-Turbo wieder zurücksetzen.

::3			jsr	DoneWithIO		;I/O-Bereich abschalten.

			ldx	flagWiC64rdy		;Fehler-Status einlesen.
::exit			rts

;*** Hardware-Erkennung: TC64.
:_WiC64_HW_TC64		php				;IRQ-Status zwischenspeichern und
			sei				;Interrupt sperren.

			lda	CPU_DATA
			pha
			lda	#IO_IN			;I/O-Bereich einblenden.
			sta	CPU_DATA

			lda	TC64_HW_EN_DIS		;Aktuellen Modus TC64 einlesen.
			ldx	#$2a
			stx	TC64_HW_EN_DIS		;Konfigurationsregister einschalten.
			ldx	TC64_HW_EN_DIS		;TC64-Status einlesen.
			ldy	TC64_HW_SPEED		;TC64-Speed-Flag einlesen.
			sta	TC64_HW_EN_DIS		;TC64-Modus zurücksetzen.

			lda	flagTurboMode
			and	#%11011111
			cpx	#$ff			;TC64 verfügbar ?
			beq	:exit			; => Nein, Ende...
			ora	#%00100000		;TC64-Flag setzen.
			cpy	#%10000000		;Turbo-Modus gesetzt ?
			bcc	:exit			; => Nein, Ende...
			ora	#%10000000		;Turbo-Flag setzen.
::exit			sta	flagTurboMode

			pla
			sta	CPU_DATA		;Konfiguration zurücksetzen.

			plp				;IRQ-Status zurücksetzen.
			rts

;*** Hardware-Erkennung: SuperCPU.
:_WiC64_HW_SCPU		php				;IRQ-Status zwischenspeichern und
			sei				;Interrupt sperren.

			lda	CPU_DATA
			pha
			lda	#IO_IN			;I/O-Bereich einblenden.
			sta	CPU_DATA

			lda	SCPU_HW_SPEED		;SuperCPU-Turbo-Flag einlesen und
			and	#%01000000		;Bit%6 = Turbo-Flag isolieren.
			tay
			lda	SCPU_HW_CHECK		;SuperCPU-Status einlesen.
			and	#%10000000
			tax

			lda	flagTurboMode
			and	#%10111111
			cpx	#$00			;SuperCPU verfügbar ?
			bne	:exit			; => Nein, Ende...
			ora	#%01000000		;SuperCPU-Flag setzen.
			cpy	#%00000000		;Turbo-Modus gesetzt ?
			bne	:exit			; => Nein, Ende...
			ora	#%10000000		;Turbo-Flag setzen.
::exit			sta	flagTurboMode

			pla
			sta	CPU_DATA		;Konfiguration zurücksetzen.

			plp				;IRQ-Status zurücksetzen.
			rts

;*** Turbo-Modus an/aus.
:_WiC64_TURBO_OFF	lda	#%00000000
			b $2c
:_WiC64_TURBO_ON	lda	#%10000000
			sta	r0L

			php				;IRQ-Status zwischenspeichern und
			sei				;Interrupt sperren.

			lda	CPU_DATA
			pha
			lda	#IO_IN			;I/O-Bereich einblenden.
			sta	CPU_DATA

			lda	flagTurboMode
			and	#%01100000		;SuperCPU / TC64 vorhanden ?
			beq	:exit			; => Nein, Abbruch...

			cmp	#%01000000		;SuperCPU ?
			bne	:isTC64			; => Nein, weiter...

::isSCPU		ldx	#$00			;Vorgabe: 1MHz.
			bit	r0L			;Turbo-Modus aktivieren ?
			bpl	:1			; => Nein, weiter...
			inx				;Vorgabe: 20MHz.
::1			sta	SCPU_HW_NORMAL,x	;Turbo-Modus SuperCPU setzen.
			jmp	:exit

::isTC64		ldy	TC64_HW_EN_DIS		;Aktuellen Modus TC64 einlesen.
			ldx	#$2a
			stx	TC64_HW_EN_DIS		;Konfigurationsregister einschalten.
			lda	TC64_HW_SPEED		;Aktuellen Turbo-Modus einlesen.
			and	#%01111111		;Vorgabe: 1MHz.
			bit	r0L			;Turbo-Modus aktivieren ?
			bpl	:2			; => Nein, weiter...
			ora	#%10000000		;Vorgabe: 10MHz.
::2			sta	TC64_HW_SPEED		;Turbo-Modus TC64 setzen.
			sty	TC64_HW_EN_DIS		;TC64-Modus zurücksetzen.

::exit			pla
			sta	CPU_DATA		;Konfiguration zurücksetzen.

			plp				;IRQ-Status zurücksetzen.
			rts

;*** WLAN-IP einlesen.
;Übergabe : -
;Rückgabe : r12L = $00 = Kein WiC64.
;                  $01 = WiC64 connected.
;           r12H = $00 = Kein WiC64.
;                  `0` = WiC64 not connected.
;Verändert: A,X,Y,r0L,r10,r11,r12,r13L,r14
:_WiC64_GetIP		jsr	timeoutInitFast		;Timeout initialisieren.

;			lda	#$00 			;Fehlerstatus initialisieren.
			sta	r12H 			;Rückmeldung für "Kein WLAN".

			lda	#<com_getip 		;WLAN-IP abfragen.
			ldy	#>com_getip		;Damit wird auch auf ein WiC64
			jsr	_WiC64_SendCom		;am Userport getestet.
			txa				;Fehler/Timeout?
			bne	timeoutError		; => Ja, Abbruch...
;			lda	errTimeout 		;Timeout erreicht ?
;			beq	timeoutError		; => Ja, Abbruch...

			lda	#<max_getip_data	;Puffergröße definieren.
			sta	r14L
			lda	#>max_getip_data
			sta	r14H

			lda	#<com_getip_data	;Rückmeldung von WiC64 empfangen.
			ldy	#>com_getip_data
			ldx	#TRUE			;Puffer initialisieren.
			jsr	_WiC64_GetData		;Daten vom WiC64 empfangen.
			txa				;Fehler/Timeout?
			bne	timeoutError		; => Ja, Abbruch...

			ldy	#$00			;Zähler initialisieren.
::1			lda	com_getip_data,y	;Rückmeldung einlesen.
			cmp	#"." 			;Trenner "." erreicht ?
			beq	:2			; => Ja, weiter...
			ora	r12H			;Alle IP-Segemente über eine ODER-
			sta	r12H			;Verknüpfung addieren.
::2			iny
			cpy	lenDataSize +0		;Alle Bytes geprüft ?
			bne	:1			; => Nein, weiter...

			lda	r12H			;ORA-Wert der IP-Segmente einlesen.
			cmp	#"0"			;`0` = `0.0.0.0` = Kein WLAN ?
			beq	timeoutReset		; => Ja, Abbruch...

			inc	r12L			;`1` = IP <> 0.0.0.0 = Connected.

;*** Reset timeout.
:timeoutReset		lda	errTimeout		;Timeout ?
			beq	timeoutError		; => Ja, Abbruch...

			lda	#timeout_default	;Timeout auf Standard zurücksetzen.
			sta	errTimeout
:timeoutError		rts

;*** Timeout initialisieren.
:timeoutInitStd		lda	#timeout_default	;Für Internet-Zugriff auf Standard.
			b $2c
:timeoutInitFast	lda	#timeout_fast 		;Timeout auf minimum setzen.
			sta	errTimeout

			lda	#$00 			;Fehlerstatus initialisieren.
			sta	r12L 			;Rückmeldung für "Kein WiC64".
			rts

;*** WLAN-Signalstärke einlesen.
if ENABLE_GETRSSI = TRUE
;Übergabe : -
;Rückgabe : r12L = $00 = Kein WiC64.
;                  $01 = Datenempfang beendet.
;Verändert: A,X,Y,r0L,r10,r11,r12L,r13L,r14
:_WiC64_GetRSSI		jsr	timeoutInitFast		;Timeout initialisieren.

			lda	#<com_getsig 		;WLAN-Signal-Level abfragen.
			ldy	#>com_getsig
			jsr	_WiC64_SendCom		;Befehl an WiC64 senden.
			txa				;Fehler/Timeout?
			bne	:error			; => Ja, Abbruch...
;			lda	errTimeout 		;Timeout erreicht ?
;			beq	:error			; => Ja, Abbruch...

			lda	#<max_getsig_data	;Puffergröße definieren.
			sta	r14L
			lda	#>max_getsig_data
			sta	r14H

			lda	#<com_getsig_data	;Rückmeldung von WiC64 empfangen.
			ldy	#>com_getsig_data
			ldx	#TRUE			;Puffer initialisieren.
			jsr	_WiC64_GetData		;Daten vom WiC64 empfangen.
			txa				;Fehler/Timeout?
			bne	:error			; => Ja, Abbruch...

			inc	r12L			;Datenempfang beendet.
			jmp	timeoutReset		;Timeout-Zähler zurücksetzen.

::error			rts
endif

;*** WLAN-Netzwerkname einlesen.
if ENABLE_GETSSID = TRUE
;Übergabe : -
;Rückgabe : r12L = $00 = Kein WiC64.
;                  $01 = Datenempfang beendet.
;Verändert: A,X,Y,r0L,r10,r11,r12L,r13L,r14
:_WiC64_GetSSID		jsr	timeoutInitFast		;Timeout initialisieren.

			lda	#<com_getnam 		;WLAN-Netzwerkname abfragen.
			ldy	#>com_getnam
			jsr	_WiC64_SendCom		;Befehl an WiC64 senden.
			txa				;Fehler/Timeout?
			bne	:error			; => Ja, Abbruch...
;			lda	errTimeout 		;Timeout erreicht ?
;			beq	:error			; => Ja, Abbruch...

			lda	#<max_getnam_data	;Puffergröße definieren.
			sta	r14L
			lda	#>max_getnam_data
			sta	r14H

			lda	#<com_getnam_data	;Rückmeldung von WiC64 empfangen.
			ldy	#>com_getnam_data
			ldx	#TRUE			;Puffer initialisieren.
			jsr	_WiC64_GetData		;Daten vom WiC64 empfangen.
			txa				;Fehler/Timeout?
			bne	:error			; => Ja, Abbruch...

			inc	r12L			;Datenempfang beendet.
			jmp	timeoutReset		;Timeout-Zähler zurücksetzen.

::error			rts
endif

;*** NTP-Zeitzone setzen.
if ENABLE_SETTZN = TRUE
;Übergabe : A = TimeZone (00-31)
;           Bsp. : A=02 -> European Central Time
;Rückgabe : r12L = $00 = Kein WiC64.
;                  $01 = Datenempfang beendet.
;Verändert: A,X,Y,r0L,r10,r11,r12L,r13L,r14
:_WiC64_SetTZN		ldx	#0			;Dezimalzahl in 1er/10er
::1			cmp	#10			;aufteilen.
			bcc	:2
;			sec
			sbc	#10
			inx
			bne	:1

::2			sta	com_settzn_data +0
			stx	com_settzn_data +1

			jsr	timeoutInitFast		;Timeout initialisieren.

			lda	#<com_settzn 		;NTP-Timezone setzen.
			ldy	#>com_settzn
			jsr	_WiC64_SendCom		;Befehl an WiC64 senden.
			txa				;Fehler/Timeout?
			bne	:error			; => Ja, Abbruch...
;			lda	errTimeout 		;Timeout erreicht ?
;			beq	:error			; => Ja, Abbruch...

			inc	r12L			;Datenempfang beendet.
			jmp	timeoutReset		;Timeout-Zähler zurücksetzen.

::error			rts
endif

;*** NTP-Zeitzone einlesen.
if ENABLE_GETTZN = TRUE
;Übergabe : -
;Rückgabe : r12L = $00 = Kein WiC64.
;                  $01 = Datenempfang beendet.
;Verändert: A,X,Y,r0L,r10,r11,r12L,r13L,r14,r15
:_WiC64_GetTZN		jsr	timeoutInitStd		;Timeout initialisieren.

			lda	#<com_gettzn 		;NTP-Timezone abfragen.
			ldy	#>com_gettzn
			jsr	_WiC64_SendCom		;Befehl an WiC64 senden.
			txa				;Fehler/Timeout?
			bne	:error			; => Ja, Abbruch...
;			lda	errTimeout 		;Timeout erreicht ?
;			beq	:error			; => Ja, Abbruch...

			lda	#<max_gettzn_data	;Puffergröße definieren.
			sta	r14L
			lda	#>max_gettzn_data
			sta	r14H

			lda	#<com_gettzn_data	;Rückmeldung von WiC64 empfangen.
			ldy	#>com_gettzn_data
			ldx	#TRUE			;Puffer initialisieren.
			jsr	_WiC64_GetData		;Daten vom WiC64 empfangen.
			txa				;Fehler/Timeout?
			bne	:error			; => Ja, Abbruch...

			jsr	convertTZN2GMT		;Timezone nach GMT konvertieren.

			ldx	#NO_ERROR		;Kein Fehler.
			inc	r12L			;Datenempfang beendet.
::err_ntp		jmp	timeoutReset		;Timeout-Zähler zurücksetzen.

::error			rts

;*** Timezone-Daten in GMT umwandeln.
;Übergabe : com_gettzn_data = Antwort NTP-Server.
;Rückgabe : com_gettzn_text = "GMT+xxxx"
;Verändert: A,X,Y,r15
:convertTZN2GMT		LoadW	r15L,timezone_data

			ldx	#0			;Rückmeldung vom WiC64 enthält nur
::1			ldy	#0			;einen Korrekturwert. Wert mit der
::2			lda	(r15L),y		;Tabelle vergleichen und dem Wert
			cmp	com_gettzn_data,y	;für GMT ermitteln.
			bne	:3
			iny
			cpy	#4
			bcc	:2
			bcs	:5

::3			lda	r15L			;Zeiger auf nächsten Korrekturwert.
			clc
			adc	#4
			sta	r15L
			bcc	:4
			inc	r15H
::4			inx
			cpx	#32			;Alle Werte durchsucht?
			bcc	:1			; => Nein, weiter...

			ldx	#0			;Vorgabe "GMT+0000".
::5			txa
			asl
			asl
			tay				;Zeiger auf GMT-Text berechnen.
			clc
			adc	#< timezone_gmt
			sta	r15L
			lda	#$00
			adc	#> timezone_gmt
			sta	r15H

			ldy	#0			;GMT-Text in Zwischenspeicher
::6			lda	(r15L),y		;kopieren.
			sta	com_gettzn_text +3,y
			iny
			cpy	#4			;Max. 4 Zeichen kopiert?
			bcc	:6			; => Nein, weiter...

			rts
endif

;*** NTP-Datum/Zeit einlesen.
if ENABLE_GETNTP = TRUE
;Übergabe : -
;Rückgabe : r12L = $00 = Kein WiC64.
;                  $01 = Datenempfang beendet.
;Verändert: A,X,Y,r0L,r10,r11,r12L,r13L,r14
:_WiC64_GetNTP		jsr	timeoutInitStd		;Timeout initialisieren.

			lda	#<com_getntp 		;NTP Datum/Zeit abfragen.
			ldy	#>com_getntp
			jsr	_WiC64_SendCom		;Befehl an WiC64 senden.
			txa				;Fehler/Timeout?
			bne	:error			; => Ja, Abbruch...
;			lda	errTimeout 		;Timeout erreicht ?
;			beq	:error			; => Ja, Abbruch...

			lda	#<max_getntp_data	;Puffergröße definieren.
			sta	r14L
			lda	#>max_getntp_data
			sta	r14H

			lda	#<com_getntp_data	;Rückmeldung von WiC64 empfangen.
			ldy	#>com_getntp_data
			ldx	#TRUE			;Puffer initialisieren.
			jsr	_WiC64_GetData		;Daten vom WiC64 empfangen.
			txa				;Fehler/Timeout?
			bne	:error			; => Ja, Abbruch...

			ldx	#ERR_BAD_NTP_DATA
			lda	#":"			;Zeitangabe testen: "hh:mm:ss"
			cmp	com_getntp_data+2
			bne	:err_ntp
			cmp	com_getntp_data+5
			bne	:err_ntp
			lda	#"-"			;Datumsangabe testen: "dd-mm-yyyy"
			cmp	com_getntp_data+11
			bne	:err_ntp
			cmp	com_getntp_data+14
			bne	:err_ntp		; => Ungültig, Abbruch...

			ldx	#NO_ERROR
			inc	r12L			;Datenempfang beendet.
::err_ntp		jmp	timeoutReset		;Timeout-Zähler zurücksetzen.

::error			rts
endif

;*** WiC64 initialisieren.
;Übergabe : -
;Rückgabe : -
;Verändert: A
:_WiC64_Init		lda	CIA2_DDR_A		;WiC64: CIA2.
;			ora	#%00000001		;PA0 auf Ausgang schalten.
			ora	#%00000100		;PA2 auf Ausgang schalten.
			sta	CIA2_DDR_A

			lda	#timeout_default	;Timeout auf Standard setzen.
			sta	errTimeout
			rts

;*** WiC64 auf Empfang umschalten.
;Übergabe : -
;Rückgabe : -
;Verändert: A
:_WiC64_ReadMode	lda	#%11111111 		;WiC64 auf `Empfang` umschalten.
			sta	CIA2_DDR_B 		;CIA#2 Port B auf Ausgang.
			lda	CIA2_DPR_A
			ora	#%00000100 		;PA2 HIGH = WiC64 bereit für den
			sta	CIA2_DPR_A		;Empfang von Daten vom C64.
			rts

;*** WiC64 auf Senden umschalten.
;Übergabe : -
;Rückgabe : -
;Verändert: A
:_WiC64_SendMode	lda	#%00000000 		;WiC64 auf `Senden` umschalten.
			sta	CIA2_DDR_B 		;CIA#2 Port B auf Eingang.
			lda	CIA2_DPR_A
			and	#%11111011 		;PA2 LOW = WiC64 bereit für das
			sta	CIA2_DPR_A		;Senden von Daten an den C64.
			rts

;*** Daten-Empfang initialisieren.
;Übergabe : -
;Rückgabe : X = Fehlercode.
;Verändert: A,X,Y,r0L,r13L
:_WiC64_InitGet2	lda	#%00000000
			b $2c
:_WiC64_InitGet4	lda	#%10000000
			sta	r13L

			lda	#timeout_default	;Timeout auf Standard setzen.
			sta	errTimeout

			jsr	_WiC64_SendMode		;WiC64 auf `Senden` umschalten.

			jsr	read_byte		;Übertragung initialisieren.

;--- Anzahl Bytes einlesen.
;ACHTUNG: Reverse Order High/Low!
			jsr	read_byte 		;Byte lesen -> Anzahl High-Byte.
			cpx	#NO_ERROR		;Fehler?
			bne	:err_nosize		; => Ja, keine Daten, Abbruch...
			sta	lenDataSize +0		;Datenlänge High-Byte.

			jsr	read_byte 		;Byte lesen -> Anzahl Low-Byte.
			sta	lenDataSize +1		;Datenlänge Low-Byte.

			bit	r13L			;Datengröße mit 4-Bytes?
			bpl	:done			; => Nein, weiter...

			jsr	read_byte 		;Byte 3+4 nur bei WiC64-Befehl
			sta	lenDataSize +2		;Typ $25 = Load/HTTP > 64Kb.

			jsr	read_byte
			sta	lenDataSize +3

			ora	lenDataSize +2
::done			ora	lenDataSize +1		;Datengröße testen.
			ora	lenDataSize +0		;Größer > 0 Bytes?
			beq	:err_len		; => Nein, Fehler/keine Daten..

			ldx	#NO_ERROR		;Kein Fehler.
			b $2c
::err_len		ldx	#ERR_BAD_GET_LEN	;Keine Daten zum Download..
			b $2c
::err_nosize		ldx	#ERR_NO_SIZE_DATA	;Keine Angabe zur Datengröße.
::exit			rts

;*** Befehl an WiC64 senden.
;Übergabe : A/Y = Zeiger auf Befehl.
;Rückgabe : X   = Status.
;Verändert: A,X,Y,r0L,r10,r11
:_WiC64_SendCom		sta	r10L			;Zeiger auf WiC64-Befehl
			sty	r10H			;zwischenspeichern.

			php				;IRQ-Status speichern.
			sei	 			;IRQ abschalten.

			jsr	_WiC64_ReadMode		;WiC64 auf `Empfang` umschalten.

			ldy	#$01
			lda	(r10L),y		;Anzahl Bytes in WiC64-Befehl
			sta	r11L			;zwischenspeichern.
			iny
			lda	(r10L),y
			sta	r11H
			ora	r11L			;Befehlslänge = NULL?
			beq	:err_len		; => Ja, Abbruch...

			lda	r11L			;Befehlslänge -1 für späteren
			bne	:1			;Test auf "Alle Daten gesendet".
			dec	r11H
::1			dec	r11L

			ldy	#$00
::loop_send		lda	(r10L),y		;Byte einlesen und an WiC64
			jsr	write_byte 		;mittels Handshake senden.

			lda	r11L			;Anzahl Bytes -1.
			bne	:256b
			lda	r11H			;Alle Bytes gesendet?
			beq	:done			; => Ja, Ende...
::64k			dec	r11H
::256b			dec	r11L

			txa
;			cpx	#NO_ERROR		;Übertragungsfehler?
			bne	:error			; => Ja, Abbruch...

			iny				;Zeiger auf nächstes Zeichen.
			bne	:loop_send
			inc	r10H			;Max. Anzahl Zeichen gesendet?
			bne	:loop_send		; => Nein, weiter...

::err_buf		ldx	#ERR_BAD_SEND_ADR	;Speichergrenze überschritten.
			b $2c
::err_len		ldx	#ERR_BAD_SEND_LEN	;Befehlslänge ungültig.
			b $2c
::done			ldx	#NO_ERROR		;Kein Fehler.

::error			plp	 			;IRQ-Status zurücksetzen.
			rts

;*** Daten von WiC64 empfangen.
;Übergabe : A/Y = Zeiger auf Puffer für Daten.
;           X   = TRUE/Puffer löschen, FALSE/Nicht löschen.
;           r14 = Puffergröße / max. Anzahl Bytes.
;Rückgabe : X = Fehlercode.
;Verändert: A,X,Y,r0L,r10,r11,r14
:_WiC64_GetData		sta	r10L			;Zeiger auf Puffer für Daten
			sty	r10H			;zwischenspeichern.

			lda	#$00			;Flag löschen: "Puffer voll".
			sta	flagBufferFull

			php				;IRQ-Status speichern.
			sei	 			;IRQ abschalten.

			txa				;Puffer initialisieren = FALSE ?
			beq	:no_clr			; => Ja, weiter...

			jsr	_Wic64_ClrBuf		;Empfangspufer löschen.

::no_clr		jsr	_WiC64_InitGet2		;Daten-Empfang initialisieren.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch..

			lda	lenDataSize +1		;Anzahl Datenbytes einlesen.
			sta	r11L			;ACHTUNG: Reverse order!
			lda	lenDataSize +0
			sta	r11H

			lda	r11L			;Datenlänge -1 für späteren
			bne	:1			;Test auf "Alle Daten empfangen".
			dec	r11H
::1			dec	r11L

			ldy	#$00
::loop_read		jsr	read_byte 		;Byte von WiC64 einlesen.
			cpx	#NO_ERROR		;Übertragungsfehler?
			bne	:err_no_data		; => Ja, Abbruch...

			bit	flagBufferFull		;Speicher bereits voll ?
			bmi	:skip			; => Ja, Daten ignorieren...

			ldx	r14L			;Freier Speicher Datenpuffer -1.
			bne	:12
			ldx	r14H			;Datenpuffer voll?
			bne	:11			; => Nein, weiter...
			dec	flagBufferFull		;Flag setzen "Puffer voll" und
			bne	:skip			;restliche Bytes ignorieren.
::11			dec	r14H
::12			dec	r14L

::write			sta	(r10L),y		;Byte im Speicher ablegen.

::skip			ldx	r11L			;Anzahl Datenbytes -1.
			bne	:21
			ldx	r11H			;Alle Bytes empfangen?
			beq	:done			; => Ja, Ende...
			dec	r11H
::21			dec	r11L

			iny				;Zeiger auf nächstes Zeichen.
			bne	:loop_read
			inc	r10H			;Max. Anzahl Zeichen gesendet?
			bne	:loop_read		; => Nein, weiter...

::err_len		ldx	#ERR_BAD_SEND_LEN	;Speichergrenze überschritten.
			b $2c
::err_no_data		ldx	#ERR_NO_DATA		;Keine Download-Daten.
			b $2c
::done			ldx	#NO_ERROR		;Kein Fehler.

::exit			plp	 			;IRQ-Status zurücksetzen.
			rts

;*** Empfangspuffer löschen.
;Übergabe : r10 = Zeiger auf Puffer für Daten.
;           r14 = Puffergröße / max. Anzahl Bytes.
;Rückgabe : X   = Status.
;Verändert: A,X,Y
:_Wic64_ClrBuf		lda	r14L
			ora	r14H			;Puffergröße = $0000 ?
			beq	:exit			; => Ja, Ende.

			lda	r10H			;High-Byte Puffer-Adresse
			pha				;zwischenspeichern.

			lda	#$00
			tay
			tax
::1			sta	(r10L),y		;Speicher mit $00-Bytes löschen.

			iny				;256 Bytes gelöscht ?
			bne	:2			; => Nein, weiter...
			inc	r10H			;High-Byte Puffer-Adresse +1.
			inx				;Byte-Zähler High-Byte +1.

::2			cpy	r14L
			bne	:1
			cpx	r14H			;Alle Bytes im Puffer gelöscht ?
			bne	:1			; => Nein, weiter...

			pla				;High-Byte der Puffer-Adresse
			sta	r10H			;wieder zurücksetzen.

::exit			rts

;*** Byte von WiC64 einlesen.
;Übergabe : -
;Rückgabe : A = Datenbyte.
;           X = Fehlercode.
;Verändert: A,X,r0L
:read_byte		jsr	_WiC64_Handshake	;Warten bis Byte bereit zum lesen.

			lda	CIA2_DPR_B 		;Byte von WiC64 empfangen.
							;CIA#2 PortB 8Bit/parallel.
			rts

;*** Byte an WiC64 senden.
;Übergabe : A = Datenbyte.
;Rückgabe : X = Fehlercode.
;Verändert: A,X,r0L
:write_byte		sta	CIA2_DPR_B 		;Byte an WiC64 senden.
							;CIA#2 PortB 8Bit/parallel.
;			jmp	_WiC64_Handshake	;Warten bis Byte verarbeitet.

;*** Handshake für senden/empfangen von Daten.
;Übergabe : -
;Rückgabe : errTimeout=0: Timeout.
;Verändert: A,X,r0L
;
:_WiC64_Handshake	ldx	errTimeout 		;Timeout bereits aufgetreten ?
			beq	:error			; => Ja, Abbruch...

;			ldx	#timeout_default 	;Timeout-Zähler initialisieren.
			stx	r0L

			ldx	#$00			;Warteschleife initialisieren.
::loop			lda	CIA2_ICR 		;Interrupt-Status einlesen.
			and	#%00010000		;CIA#2 NMI FLAG ?
			bne	:hs_rts  		; => Ja, Handshake OK, Ende...

			inx				;256 Durchläufe ?
			bne	:loop			; => Nein, weiter warten...

			bit	flagWiC64dbg		;Debug-Modus?
			bpl	:1			; => Nein, weiter...

			inc	extclr			;Rahmenfarbe wechseln für
			nop				;Status-Anzeige.
			nop
			nop
			nop
			dec	extclr

::1			lda	CIA_TOD10		;Bei Turbo-Karten 1/10sec. warten.
::wait			cmp	CIA_TOD10		;(dec/bne läuft hier zu schnell)
			beq	:wait

			dec	r0L			;Timeout abgelaufen ?
			bne	:loop			; => Nein, weiter warten...

;HINWEIS:
;Bei Timeout oder Fehler die Zeit für
;den Handshake auf ein minimum zurück-
;setzen um Wartezeit zu reduzieren.
			lda	#$00 			;Timeout aufgetreten:
			sta	errTimeout 		;Fehlerstatus setzen.

::error			ldx	#ERR_ESP_TIMEOUT	; => Fehler: Timeout.
			rts

::hs_rts		ldx	#NO_ERROR		; => Kein Fehler.
			rts

;*** Variablen.
:flagWiC64rdy		b $00 ;$00=NO_ERROR / $8x=DEV_NOT_FOUND
:flagTurboMode		b $00 ;Bit%7=1: TurboOn, Bit%6=1:TC64, Bit%5=1:SCPU
:flagWiC64dbg		b $00 ;Bit%7=0: Debug-Modus inaktiv.
:flagBufferFull		b $00 ;$FF = Puffer voll.
:lenDataSize		s $04 ;2-4 Bytes für Datengröße.
:errTimeout		b $00 ;$00 = Timeout-Fehler, >$00=OK!
:defaultTimezone	b $ff ;$00 = Greenwich mean time.
			      ;$FF = Nicht ändern...

;*** IP abfragen.
:max_getip_data		= 20 ;Freie Begrenzung auf 20 Zeichen (IPv6).
:com_getip		b "W",$04,$00,$06
:com_getip_data		b "192.168.9.9"
;			b "8888:8888:8888:8888"
			e (com_getip_data +max_getip_data) +1

;*** Netzwerkname abfragen.
if ENABLE_GETSSID = TRUE
:max_getnam_data	= 18 ;Begrenzung wegen Bildschirmausgabe.
:com_getnam		b "W",$04,$00,$10
:com_getnam_data	b "C64.TEST.NETWORK"
;			b "WWWWWWWWWWWWWWWWWW"
			e (com_getnam_data +max_getnam_data) +1
endif

;*** Signalstärke abfragen.
if ENABLE_GETRSSI = TRUE
:max_getsig_data	= 8  ;Freie Begrenzung auf 8 Zeichen.
:com_getsig		b "W",$04,$00,$11
:com_getsig_data	b "-99"
			e (com_getsig_data +max_getsig_data) +1
endif

;*** NTP-Zeitzone abfragen.
if ENABLE_GETTZN = TRUE
:max_gettzn_data	= 6  ;Freie Begrenzung auf 8 Zeichen.
:com_gettzn		b "W",$04,$00,$17
:com_gettzn_data	b "-39600"
			e (com_gettzn_data +max_gettzn_data) +1
:com_gettzn_text	b "GMT+0000"
			b NULL
endif

;*** NTP-Zeitzone setzen.
if ENABLE_SETTZN = TRUE
:max_settzn_data	= 2  ;Freie Begrenzung auf 2 Zeichen.
:com_settzn		b "W",$06,$00,$16
:com_settzn_data	b $00,$00 ;Greenwich Mean Time
;			b $01,$00 ;UTC standard time
;			b $02,$00 ;European central time
;			...
			e (com_settzn_data +max_settzn_data) +1
endif

;*** NTP-Datum/Zeit.
if ENABLE_GETNTP = TRUE
;HINWEIS:
;Wenn ":" und "-" in der Rückmeldung
;nicht an der richtigen Stelle stehen,
;dann gilt Datum/Zeit als ungültig.
:max_getntp_data	= 20 ;Freie Begrenzung auf 20 Zeichen.
:com_getntp		b "W",$04,$00,$15
:com_getntp_data
:com_getntp_th		b "06:"
:com_getntp_tm		b "30:"
:com_getntp_ts		b "45 "
:com_getntp_dd		b "22-"
:com_getntp_dm		b "03-"
:com_getntp_dy		b "2022"
			e (com_getntp_data +max_getntp_data) +1
endif

;*** Timezone-Rückmeldung.
if ENABLE_GETTZN = TRUE
;HINWEIS:
;Das WiC64 liefert einen max. 6 Zeichen
;langen Textstring zurück.
;Über die folgenden Tabellen wird die
;dazu passende Timezone gesucht.
:timezone_data		b "0",0,0,0  ;00
			b "0",0,0,0  ;01
			b "3600"     ;02
			b "7200"     ;03
			b "7200"     ;04
			b "1080"     ;05
			b "1260"     ;06
			b "1440"     ;07
			b "1800"     ;08
			b "1980"     ;09
			b "2160"     ;10
			b "2520"     ;11
			b "2880"     ;12
			b "3240"     ;13
			b "3420"     ;14
			b "3600"     ;15
			b "3960"     ;16
			b "4320"     ;17
			b "-396"     ;18
			b "-360"     ;19
			b "-324"     ;20
			b "-288"     ;21
			b "-252"     ;22
			b "-252"     ;23
			b "-216"     ;24
			b "-180"     ;25
			b "-180"     ;26
			b "-144"     ;27
			b "-126"     ;28
			b "-108"     ;29
			b "-108"     ;30
			b "-360"     ;31

;*** Timezone GMT-Daten.
:timezone_gmt		b "+000"     ;00
			b "+000"     ;01
			b "+010"     ;02
			b "+020"     ;03
			b "+020"     ;04
			b "+030"     ;05
			b "+033"     ;06
			b "+040"     ;07
			b "+050"     ;08
			b "+053"     ;09
			b "+060"     ;10
			b "+070"     ;11
			b "+080"     ;12
			b "+090"     ;13
			b "+093"     ;14
			b "+100"     ;15
			b "+110"     ;16
			b "+120"     ;17
			b "-110"     ;18
			b "-100"     ;19
			b "-090"     ;20
			b "-080"     ;21
			b "-070"     ;22
			b "-070"     ;23
			b "-060"     ;24
			b "-050"     ;25
			b "-050"     ;26
			b "-040"     ;27
			b "-033"     ;28
			b "-030"     ;29
			b "-020"     ;30
			b "-010"     ;31
endif
