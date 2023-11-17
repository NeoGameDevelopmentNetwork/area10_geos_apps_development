; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; geoWiC64ntp
;
;GEOS-Anwendung für das WiC64.
; * Systemzeit über NTP-Server setzen
;
; (w) 2022 / M.Kanet
;
; v0.10: Initial release.
;

;*** Symboltabellen.
if .p
			t "TopSym"
			t "TopMac"

;--- Zusätzliche Labels MP3/Kernal:
			t "TopSym.MP3"
			t "TopSym.IO"

;--- Sprache festlegen.
:LANG_DE		= $0110
:LANG_EN		= $0220
:LANG			= LANG_DE

;--- lib.WiC64-Build-Optionen.
;Werden die folgenden Optionen auf
;`TRUE` gesetzt, dann werden die dazu
;erforderlichen Routinen während des
;Assemblierungsvorgangs mit in den
;Code eingebunden.
;
;TRUE = Aktuelle Timezone abfragen:
;ENABLE_GETTZN  = FALSE
:ENABLE_GETTZN  = TRUE
;
;TRUE = Timezone setzen:
;ENABLE_SETTZN  = FALSE
:ENABLE_SETTZN  = TRUE
;
;TRUE = Datum/Zeit via NTP abfragen:
;Erfordert ENABLE_SETTZN=TRUE, da bei
;fehlerhaften Datum/Zeit-Angaben die
;Timezone auf "00" gesetzt wird.
;ENABLE_GETNTP  = FALSE
:ENABLE_GETNTP  = TRUE
;
;TRUE = Netzwerkname abfragen:
:ENABLE_GETSSID = FALSE
;ENABLE_GETSSID = TRUE
;
;TRUE = Signalstärke abfragen:
:ENABLE_GETRSSI = FALSE
;ENABLE_GETRSSI = TRUE
;

endif

			f AUTO_EXEC
			a "Markus Kanet"

			o APP_RAM
			p MAIN

if LANG = LANG_DE
			n "geoWiC64ntp",NULL
			c "GWIC64NTP   V0.1"
endif
if LANG = LANG_EN
			n "geoWiC64ntpE",NULL
			c "GWIC64NTPE  V0.1"
endif

			z $80 ;Nur GEOS64.
			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "TZNxx ;xx = Zeitzone 00-31"
			h "GEOS-Uhrzeit setzen mit WiC64 und NTP-Server"
endif
if LANG = LANG_EN
			h "TZNxx ;xx = Timezone 00-31"
			h "Set GEOS time using NTP server and WiC64"
endif

;*** Externer Code: WiC64-Tools.
			t "lib.WiC64"

;*** RTC des TurboChameleon auslesen.
:MAIN			jsr	_WiC64_HW_TC64		;TurboChameleon64 erkennen.
			jsr	_WiC64_HW_SCPU		;CMD SuperCPU erkennen.

			jsr	_WiC64_CHECK		;WiC64-Hardware erkennen.
			txa				;Gefunden?
			beq	:ok			; => Ja, weiter...

			lda	firstBoot		;GEOS-BootUp?
			bpl	:end			; => Ja, Ende...

			lda	#<Dlg_NoWIC64
			ldx	#>Dlg_NoWIC64
			bne	:exitDlg		;Fehler ausgeben.

::ok			jsr	setDatenAndTime		;Datum und Uhrzeit setzen.
			txa
			beq	:done

			lda	firstBoot		;GEOS-BootUp?
			bpl	:end			; => Ja, Ende...

			lda	#<Dlg_NTPerr
			ldx	#>Dlg_NTPerr
			bne	:exitDlg		;Fehler ausgeben.

::done			lda	firstBoot		;GEOS-BootUp?
			bpl	:end			; => Ja, Ende...

			lda	#<Dlg_RTCset
			ldx	#>Dlg_RTCset

::exitDlg		sta	r0L
			stx	r0H
			jsr	DoDlgBox		;Meldung ausgeben.
::end			jmp	EnterDeskTop		;Zurück zum DeskTop.

;*** Dialogbox für "Kein WiC64".
:Dlg_NoWIC64		b %10000001
			b DBTXTSTR   ,$10,$0b
			w :51
			b DBTXTSTR   ,$10,$24
			w :52
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
if LANG = LANG_DE
			b "Kein 'WiC64' erkannt!",NULL
endif
if LANG = LANG_EN
			b "No 'WiC64' detected!",NULL
endif

;*** Dialogbox für "Uhrzeit nicht gesetzt".
:Dlg_NTPerr		b %10000001
			b DBTXTSTR   ,$10,$0b
			w :51
			b DBTXTSTR   ,$10,$24
			w :52
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
if LANG = LANG_DE
			b "Kann Uhrzeit nicht aktualisieren!",NULL
endif
if LANG = LANG_EN
			b "Unable to set date and time!",NULL
endif

;*** Dialogbox für "Uhrzeit gesetzt".
:Dlg_RTCset		b %10000001
			b DBTXTSTR   ,$10,$0b
			w :51
			b DBTXTSTR   ,$10,$20
			w :52
			b DBTXTSTR   ,$10,$30
			w com_getntp_data
			b DBTXTSTR   ,$10,$3c
			w com_gettzn_text
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

;*** NTP-Server abfragen und Datum/Zeit setzen.
:setDatenAndTime	jsr	getDefaultTZN		;Standard-Timezone einlesen.

			jsr	PurgeTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O-Bereich einschalten.

			bit	flagTurboMode		;CPU-Turbo aktiv?
			bpl	:1			; => Nein, weiter...
			jsr	_WiC64_TURBO_OFF	;CPU-Turbo abschalten.

::1			jsr	_WiC64_Init		;WiC64 zurücksetzen.

			lda	defaultTimezone		;Default-Timezone definiert?
			bpl	:settzn			; => Ja, weiter...

			jsr	_WiC64_GetNTP		;NTP-Datum/Zeit einlesen.
			txa				;Fehler/Timeout?
			beq	:2			; => Nein, weiter...
			cpx	#ERR_BAD_NTP_DATA	;Fehler "Datum/Zeit ungültig"?
			bne	:error			; =>  Nein, Abbruch...

			lda	#00			;Zeitzone auf 00 setzen.
							;(Greenwich Mean Time)
::settzn		jsr	_WiC64_SetTZN		;NTP-Zeitzone setzen.
			jsr	_WiC64_GetNTP		;NTP-Datum/Zeit einlesen.
			txa				;Fehler/Timeout?
			bne	:error			; => Ja, Abbruch...

::2			jsr	_WiC64_GetTZN		;NTP-Timezone einlesen.
			txa				;Fehler/Timeout?
			bne	:error			; => Ja, Abbruch...

			jsr	_WiC64_ReadMode		;WiC64 auf `Empfang` umschalten.
			jsr	_WiC64_Init		;WiC64 zurücksetzen.

			lda	#NO_ERROR		;WiC64: OK.
::error			sta	flagWiC64rdy		;WiC64-Status speichern.
			bne	:skip

			jsr	ConvRTC2BCD		;RTC von ASCII nach BCD.
			jsr	ConvRTC2DEZ		;RTC-Daten BCD nach DEZ.

			jsr	SetGEOStime		;GEOS-Datum/Zeit setzen.
			jsr	SetCPUtime		;System-Zeit setzen.

::skip			bit	flagTurboMode		;War CPU-Turbo aktiv?
			bpl	:3			; => Nein, weiter...
			jsr	_WiC64_TURBO_ON		;CPU-Turbo wieder zurücksetzen.

::3			jsr	DoneWithIO		;I/O-Bereich abschalten.

			ldx	flagWiC64rdy		;Fehler-Status einlesen.
::exit			rts

;*** Default Timezone einlesen.
:getDefaultTZN		LoadB	r7L,AUTO_EXEC
			LoadB	r7H,1
			LoadW	r10,sysAppClass
			LoadW	r6,sysAppFName
			jsr	FindFTypes		;Programmdatei suchen.
			txa				;Diskfehler?
			bne	:skip			; => Ja, Fehler ausgeben.
			lda	r7H			;Programmdatei gefunden?
			bne	:skip			; => Ja, weiter...

if FALSE
			LoadW	r6,sysAppFName
			jsr	FindFile		;Verzeichniseintrag suchen.
			txa				;Diskfehler?
			bne	:skip			; => Ja, Abbruch...

			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo		;GEOS-Infoblock einlesen.
			txa				;Diskfehler?
			bne	:skip			; => Ja, Abbruch...
endif

			lda	fileHeader +160		;Kennbyte einlesen.
			cmp	#"T"			;`TZN` = Standard-Timezone?
			bne	:skip
			lda	fileHeader +161
			cmp	#"Z"
			bne	:skip
			lda	fileHeader +162
			cmp	#"N"
			bne	:skip			; => Nein, Ende...

			lda	fileHeader +163		;Zeitzone von ASCII nach
			sec				;Dezimal wandeln.
			sbc	#"0"
			bcc	:skip
			cmp	#10
			bcs	:skip
			tax
			lda	fileHeader +164
			sec
			sbc	#"0"
			bcc	:skip
			cmp	#10
			bcs	:skip

			cpx	#0			;1er/10er nach Dezimal wandeln.
			beq	:set
::conv			clc
			adc	#10
			dex
			bne	:conv

::set			cmp	#32			;Timezone gültig?
			bcs	:skip			; => Nein, Ende...

			sta	defaultTimezone		;Standard-Timezone setzen.

::skip			rts

;*** RTC-Daten von ASCII nach BCD wandeln.
:ConvRTC2BCD		lda	com_getntp_dy +0	;Jahrhundert.
			ldx	com_getntp_dy +1
			jsr	ASCIItoBCD
			sta	RTC_BCD +0

			lda	com_getntp_dy +2	;Jahreszahl.
			ldx	com_getntp_dy +3
			jsr	ASCIItoBCD
			sta	RTC_BCD +1

			lda	com_getntp_dm +0	;Monat.
			ldx	com_getntp_dm +1
			jsr	ASCIItoBCD
			sta	RTC_BCD +2

; Wird für GEOS nicht benötigt.
;			lda	#$00			;Wochentag.
;			sta	RTC_BCD +3

			lda	com_getntp_dd +0	;Tag.
			ldx	com_getntp_dd +1
			jsr	ASCIItoBCD
			sta	RTC_BCD +4

			lda	com_getntp_th +0	;Stunde.
			ldx	com_getntp_th +1
			jsr	ASCIItoBCD
			sta	RTC_BCD +5

			lda	com_getntp_tm +0	;Minute.
			ldx	com_getntp_tm +1
			jsr	ASCIItoBCD
			sta	RTC_BCD +6

			lda	com_getntp_ts +0	;Sekunde.
			ldx	com_getntp_ts +1
			jsr	ASCIItoBCD
			sta	RTC_BCD +7
			rts

;*** ASCII nach BCD wandeln.
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

;*** GEOS-Datum/Zeit setzen.
:SetGEOStime		lda	RTC_DEZ +0		;GEOS-Jahrhundert setzen.
			sta	millenium
			lda	RTC_DEZ +1		;GEOS-Jahreszahl setzen.
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
:SetCPUtime		lda	RTC_BCD +5
			sed				;AM/PM-Flag berechnen.
			cmp	#$13
			bcc	:2
			sbc	#$12
			ora	#%10000000
::2			tax
			lda	CIA_TODHR		;TOD-Clock einfrieren und
			ldy	CIA_TOD10		;wieder starten.

			txa
			sta	CIA_TODHR		;System-Stunde setzen.
			cld

			lda	RTC_BCD +6
			sta	CIA_TODMIN		;System-Minute setzen.

			lda	RTC_BCD +7
			sta	CIA_TODSEC		;System-Sekunde setzen.

			lda	#$00			;Uhr starten.
			sta	CIA_TOD10

			rts

;*** Variablen.
:sysAppDrive		b $00
:sysAppPart		b $00
:sysAppFName		s 17

if LANG = LANG_DE
:sysAppClass		b "GWIC64NTP   V0.1"
endif
if LANG = LANG_EN
:sysAppClass		b "GWIC64NTPE  V0.1"
endif
			b NULL

:RTC_BCD		s $08 ; clock output buffer BCD
:RTC_DEZ		s $08 ; clock output buffer DEZ
