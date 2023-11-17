; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; geoWiC64Koala
;
;GEOS-Anwendung für das WiC64.
; * Koala-Viewer/Diashow
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

;--- DEMO-Modus festlegen.
:DEMO_MODE		= FALSE

;--- lib.WiC64-Build-Optionen.
;Werden die folgenden Optionen auf
;`TRUE` gesetzt, dann werden die dazu
;erforderlichen Routinen während des
;Assemblierungsvorgangs mit in den
;Code eingebunden.
;
;TRUE = Aktuelle Timezone abfragen:
:ENABLE_GETTZN  = FALSE
;ENABLE_GETTZN  = TRUE
;
;TRUE = Timezone setzen:
:ENABLE_SETTZN  = FALSE
;ENABLE_SETTZN  = TRUE
;
;TRUE = Datum/Zeit via NTP abfragen:
;Erfordert ENABLE_SETTZN=TRUE, da bei
;fehlerhaften Datum/Zeit-Angaben die
;Timezone auf "00" gesetzt wird.
:ENABLE_GETNTP  = FALSE
;ENABLE_GETNTP  = TRUE
;
;TRUE = Netzwerkname abfragen:
:ENABLE_GETSSID = FALSE
;ENABLE_GETSSID = TRUE
;
;TRUE = Signalstärke abfragen:
:ENABLE_GETRSSI = FALSE
;ENABLE_GETRSSI = TRUE
;

:KOALA_BASE		= $2000
:KOALA_LDADR		= KOALA_BASE -2
:MCOLOR_MATRIX		= $d800

endif

			f APPLICATION
			a "Markus Kanet"

			o APP_RAM
			p MAIN

if LANG = LANG_DE
			n "geoWiC64Koala",NULL
			c "GWIC64KOALA V0.1"
endif
if LANG = LANG_EN
			n "geoWiC64KoalaE",NULL
			c "GWIC64KOALAEV0.1"
endif

			z $80 ;Nur GEOS64.
			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "GEOS-Version des WiC64-Koala-Demo"
			h "Für GEOS/MegaPatch64 oder GDOS64"
endif
if LANG = LANG_EN
			h "GEOS version of the WiC64-Koala demo"
			h "For GEOS/MegaPatch64 or GDOS64"
endif

;*** Externer Code: WiC64-Tools.
			t "lib.WiC64"

;*** RTC des TurboChameleon auslesen.
:MAIN			jsr	_WiC64_HW_TC64		;TurboChameleon64 erkennen.
			jsr	_WiC64_HW_SCPU		;CMD SuperCPU erkennen.

			jsr	_WiC64_CHECK		;WiC64-Hardware erkennen.
			txa				;Gefunden?
			beq	:wic64ok		; => Ja, weiter...
if DEMO_MODE = TRUE
			bne	:wic64ok
endif

			LoadW	r0,Dlg_NoWIC64
			jsr	DoDlgBox
			jmp	EnterDeskTop		;Zurück zum DeskTop.

::wic64ok		LoadW	r0,Dlg_Info
			jsr	DoDlgBox

			lda	#%00000000
			sta	flagWiC64dbg		;Kein Debug-Modus.

			bit	flagTurboMode		;CPU-Turbo aktiv?
			bpl	:1			; => Nein, weiter...
			jsr	_WiC64_TURBO_OFF	;CPU-Turbo abschalten.

::1			LoadW	keyVector,testKeyData
			LoadW	appMain,viewKoalaLoop

			lda	#$7f			;Flag setzen: "Dateiliste laden".
			sta	flagKeyMode

			lda	delayCount +1		;Anfangsverzögerung einstellen.
			sta	viewDelay

			jmp	MouseOff		;Mauszeiger ausblenden.

;*** Diashow beenden.
:ExitSlideShow		bit	flagTurboMode		;War CPU-Turbo aktiv?
			bpl	:1			; => Nein, weiter...
			jsr	_WiC64_TURBO_ON		;CPU-Turbo wieder zurücksetzen.

::1			lda	#$00
			sta	keyVector +0
			sta	keyVector +1
			sta	appMain +0
			sta	appMain +1

			lda	C_WinBack
			jsr	i_UserColor
			b	$00,$00,$28,$19

			jsr	InitForIO

			lda	$d016
			and	#%11101111
			sta	$d016

			jsr	DoneWithIO

::end			jmp	EnterDeskTop		;Zurück zum DeskTop.

;*** MainLoop: Bild anzeigen.
:viewKoalaLoop		ldx	flagKeyMode		;Tastaturabfrage: Diashow beenden?
			bpl	:next			; => Nein, weiter...
			jmp	ExitSlideShow		; => Ja, Ende...

::next			cpx	#$00			;Nächste Datei anzeigen?
			beq	getNextImage		; => Ja, weiter...

;			cpx	#$7f			;Neue Liste einlesen?
;			beq	initKoalaLoop		; => Ja, weiter...

;*** Dateiliste initialisieren.
:initKoalaLoop		lda	#"0"
			sta	fname_koala +0
			sta	fname_koala +1
			sta	fname_koala +2

			ldx	#NULL
			stx	flagKeyMode		;Tastenstatus löschen.

			inx
			stx	viewDelayCnt		;Verzögerung initialisieren.
			stx	viewDelayPause

			jsr	InitForIO

			lda	$d016
			ora	#%00010000
			sta	$d016

			jsr	DoneWithIO

;*** KOALA-Dateien anzeigen.
:getNextImage		dec	viewDelayPause		;Wartezeit abgelaufen?
			bne	:skip			; => Nein, Ende...

			lda	#50
			sta	viewDelayPause

			dec	viewDelayCnt		;Verzögerung abgelaufen?
			bne	:skip			; => Nein, Ende...

			bit	flagPauseMode		;Pausen-Modus?
			bpl	:do			; => Nein, Bild anzeigen.

::skip			rts

::do			jsr	getKoalaFile		;KOALA-Bild über WiC64 laden.
			txa				;Fehler?
			bne	:errExit		; => Ja, Abbruch...

			jsr	drawKoalaFile		;KOALA-Bild anzeigen.

			jsr	nextKoalaFile		;Zähler auf nächstes Bild setzen.

			lda	viewDelay		;Verzögerung zurücksetzen.
			sta	viewDelayCnt

			lda	#$00			;Flag "Nächstes Bild".
			b $2c
::errExit		lda	#$ff			;Flag "Abbruch".
::setMode		sta	flagKeyMode		;Status setzen.
			rts

;*** Tastaturabfrage.
:testKeyData		lda	keyData
			cmp	#CR			;RETURN?
			bne	:1			; => Nein, weiter...

			lda	#$ff			;Status: "Abbruch".
			sta	flagKeyMode
			rts

::1			cmp	#"0"			;Taste 0-9?
			bcc	:2
			cmp	#"9" +1
			bcs	:2			; => Nein, weiter...

			sec				;Verzögerung berechnen.
			sbc	#$30
			tax
			lda	delayCount ,x
			sta	viewDelay

			lda	#1			;Verzögerung zurücksetzen.
			sta	viewDelayPause
			sta	viewDelayCnt
			rts

::2			cmp	#$3d			;SHIFT+0?
			beq	:2_000			; => Ja, Sprung zu Bild 000.
			cmp	#$21			;SHIFT+1?
			beq	:2_100			; => Ja, Sprung zu Bild 100.
			cmp	#$22			;SHIFT+2?
			beq	:2_200			; => Ja, Sprung zu Bild 200.
if LANG = LANG_DE
			cmp	#$40			;SHIFT+3? DE=§
endif
if LANG = LANG_EN
			cmp	#$23			;SHIFT+3? EN=#
endif
			beq	:2_300			; => Ja, Sprung zu Bild 300.
			cmp	#$24			;SHIFT+4?
			bne	:3			; => Nein, weiter...

::2_400			lda	#"4"
			b $2c
::2_300			lda	#"3"
			b $2c
::2_200			lda	#"2"
			b $2c
::2_100			lda	#"1"
			b $2c
::2_000			lda	#"0"
			sta	fname_koala +0		;Neuen Dateinamen setzen.

			lda	#"0"
			sta	fname_koala +1
			sta	fname_koala +2

			lda	#1			;Verzögerung zurücksetzen.
			sta	viewDelayPause
			sta	viewDelayCnt
			rts

::3			cmp	#" "			;Nächstes Bild?
			bne	:5			; => Nein, weiter...

			ldx	#1			;Verzögerung zurücksetzen.
			stx	viewDelayPause
			stx	viewDelayCnt
			dex
			stx	flagPauseMode		;Pausenmodus zurücksetzen.

			rts

::5			cmp	#KEY_F7			;F7 = Pausen-Modus?
			bne	:6			; => Nein, weiter...

			lda	flagPauseMode		;Pausenmodus umschalten.
			eor	#%10000000
			sta	flagPauseMode

			lda	#1			;Verzögerung zurücksetzen.
			sta	viewDelayPause
			sta	viewDelayCnt
			rts

::6			rts				;Ungültige Taste, Ende...

;*** KOALA-Bild von Laufwerk laden.
if DEMO_MODE = TRUE
:getKoalaFile		lda	C_WinBack
			jsr	i_UserColor
			b	$00,$00,$28,$19

			LoadW	r6,FNAME
			jsr	FindFile

			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r7,KOALA_BASE -2
			LoadW	r2,$4000
			jsr	ReadFile

			rts

:FNAME			b "KOALA.KOA",NULL
endif

;** KOALA-Bild über WiC64 laden.
if DEMO_MODE = FALSE
:getKoalaFile		jsr	PurgeTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O-Bereich einschalten.

			jsr	_WiC64_Init		;WiC64 zurücksetzen.

			jsr	timeoutInitFast		;Timeout initialisieren.

			lda	#<com_getkoala 		;Download-Befehl senden.
			ldy	#>com_getkoala
			jsr	_WiC64_SendCom		;Befehl an WiC64 senden.
			txa				;Fehler/Timeout?
			bne	:error			; => Ja, Abbruch...
;			lda	errTimeout 		;Timeout erreicht ?
;			beq	:error			; => Ja, Abbruch...

			jsr	timeoutInitStd		;Timeout initialisieren.

			lda	#<max_koala_data	;Puffergröße definieren.
			sta	r14L
			lda	#>max_koala_data
			sta	r14H

			lda	#<KOALA_LDADR		;Rückmeldung von WiC64 empfangen.
			ldy	#>KOALA_LDADR
			ldx	#FALSE			;Puffer initialisieren.
			jsr	_WiC64_GetData		;Daten vom WiC64 empfangen.
			txa				;Fehler/Timeout?
			bne	:error			; => Ja, Abbruch...

			ldx	#NO_ERROR
			inc	r12L			;Datenempfang beendet.
::error			jsr	timeoutReset		;Timeout-Zähler zurücksetzen.

			stx	flagWiC64rdy

			jsr	_WiC64_ReadMode		;WiC64 auf `Empfang` umschalten.
			jsr	_WiC64_Init		;WiC64 zurücksetzen.

			jsr	DoneWithIO		;I/O-Bereich abschalten.

			ldx	flagWiC64rdy		;Fehler-Status einlesen.
::exit			rts
endif

;*** Zähler auf nächstes KOALA-Bild.
:nextKoalaFile		inc	fname_koala +2
			lda	fname_koala +2
			cmp	#"9" +1
			bcc	:ok
			lda	#"0"
			sta	fname_koala +2

			inc	fname_koala +1
			lda	fname_koala +1
			cmp	#"9" +1
			bcc	:ok
			lda	#"0"
			sta	fname_koala +1

			inc	fname_koala +0
			lda	fname_koala +0
			cmp	#"5"
			bcc	:ok
			lda	#"0"
			sta	fname_koala +0

::ok			rts

;*** KOALA-Bild anzeigen.
:drawKoalaFile		bit	flagTurboMode		;War CPU-Turbo aktiv?
			bpl	:1			; => Nein, weiter...
			jsr	_WiC64_TURBO_ON		;CPU-Turbo wieder zurücksetzen.

::1			jsr	i_MoveData
			w	KOALA_BASE
			w	SCREEN_BASE
			w	40*25*8

			jsr	InitForIO

			ldx	#0
::l1			lda	KOALA_BASE +8000 +  0,x
			sta	COLOR_MATRIX     +  0,x
			lda	KOALA_BASE +8000 +256,x
			sta	COLOR_MATRIX     +256,x
			lda	KOALA_BASE +8000 +512,x
			sta	COLOR_MATRIX     +512,x
			lda	KOALA_BASE +8000 +744,x
			sta	COLOR_MATRIX     +744,x

			lda	KOALA_BASE +9000 +  0,x
			sta	MCOLOR_MATRIX    +  0,x
			lda	KOALA_BASE +9000 +256,x
			sta	MCOLOR_MATRIX    +256,x
			lda	KOALA_BASE +9000 +512,x
			sta	MCOLOR_MATRIX    +512,x
			lda	KOALA_BASE +9000 +744,x
			sta	MCOLOR_MATRIX    +744,x

			inx
			bne	:l1

			lda	KOALA_BASE +8000 +1000 +1000
			sta	bakclr0			;Hintergrundfarbe setzen.

			jsr	DoneWithIO

			bit	flagTurboMode		;CPU-Turbo aktiv?
			bpl	:2			; => Nein, weiter...
			jsr	_WiC64_TURBO_OFF	;CPU-Turbo abschalten.

::2			rts

;*** Variablen.
:flagKeyMode		b $00
:flagPauseMode		b $00
:viewDelay		b $05
:viewDelayCnt		b $00
:viewDelayPause		b $00
:backScrCol		b $00

;*** Tabelle für Zeit-Verzögerung.
:delayCount		b 1				; 0
			b 35				; 1
			b 65				; 2
			b 75				; 3
			b 105				; 4
			b 135				; 5
			b 165				; 6
			b 195				; 7
			b 225				; 8
			b 255				; 9

;*** Download-Informationen.
:max_koala_data		= 2 +8000 +1000 +1000 +10 ;10Bytes Reserve.
:com_getkoala		b "W",$22,$00,$01
			b "http://www.wic64.de/ko/"
:fname_koala		b "000.koa"

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

;*** Dialogbox für "Infoseite".
:Dlg_Info		b %10000001
			b DBTXTSTR   ,$10,$0b
			w :51
			b DBTXTSTR   ,$10,$1c
			w :52
			b DBTXTSTR   ,$10,$26
			w :53
			b DBTXTSTR   ,$10,$31
			w :54
			b DBTXTSTR   ,$10,$40
			w :55
			b OK         ,$02,$48
			b NULL

::51			b PLAINTEXT, BOLDON
if LANG = LANG_DE
			b "HINWEIS:",NULL
endif
if LANG = LANG_EN
			b "NOTE:",NULL
endif

::52			b PLAINTEXT
if LANG = LANG_DE
			b "Ende mit 'RETURN'-Taste",NULL
endif
if LANG = LANG_EN
			b "Exit with 'RETURN' key",NULL
endif

::53
if LANG = LANG_DE
			b "Geschwindigkeit: Tasten 0-9",NULL
endif
if LANG = LANG_EN
			b "Display speed: keys 0-9",NULL
endif

::54
if LANG = LANG_DE
			b "Sprung zu Bild: SHIFT 0/1/2/3/4",NULL
endif
if LANG = LANG_EN
			b "Jump to Image: SHIFT 0/1/2/3/4",NULL
endif

::55
if LANG = LANG_DE
			b "Tasten ggf. länger gedrückt halten!",NULL
endif
if LANG = LANG_EN
			b "Hold down keys longer if necessary!",NULL
endif
