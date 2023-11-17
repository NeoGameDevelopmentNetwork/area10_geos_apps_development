; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; WIC64-GEOS64DEMO
;
;GEOS-Anwendung für das WiC64.
; * WLAN-Status anzeigen.
; * Portal über HTTP/GET starten.
;
; (w) 2022-2023 / M.Kanet
;

;*** Symboltabellen.
if .p
			t "TopSym"
			t "TopMac"

;--- Zusätzliche Labels MP3/Kernal:
			t "TopSym.MP3"
			t "TopSym.IO"

;--- WiC64-Demo assemblieren.
;TRUE = Ja, FALSE = Nein.
:DEMO_MODE		= FALSE

;--- Lage X/Y für WiC64-Logo.
:LOGO_X			= 19
:LOGO_Y			= 40
:LINE_1			= COLOR_MATRIX + (LOGO_Y/8 +0)*40 + LOGO_X
:LINE_2			= COLOR_MATRIX + (LOGO_Y/8 +1)*40 + LOGO_X
:LINE_3			= COLOR_MATRIX + (LOGO_Y/8 +2)*40 + LOGO_X

;--- Lage X/Y für Turbo-Modus-Option.
:TURBO_OPT_X		= $00b0
:TURBO_OPT_Y		= $5b

;--- C64-Adressen.
:TBUFFR			= $033c ;Adresse Kassettenpuffer / Portal-Loader.
:VICSCN			= $0400 ;Startadresse Bildschirmspeicher.

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
;ENABLE_GETSSID = FALSE
:ENABLE_GETSSID = TRUE
;
;TRUE = Signalstärke abfragen:
;ENABLE_GETRSSI = FALSE
:ENABLE_GETRSSI = TRUE
;
endif

if DEMO_MODE = FALSE
			n "WIC64-GEOS64DEMO"
endif
if DEMO_MODE = TRUE
			n "WIC64-DEMO"
endif

			c "WIC64DEMO   V0.40"
			a "Markus Kanet"

			f APPLICATION
			z $80 ;Nur GEOS64!
			i
<MISSING_IMAGE_DATA>

			o $7800
			p MAIN

if DEMO_MODE = FALSE
			h "GEOS-Anwendung für WiC64."
endif
if DEMO_MODE = TRUE
			h "Demo-Anwendung für WiC64."
endif
			h "Info zeigen/Portal starten."
			h "Nur GEOS64/MP64/GDOS64!"

;*** Externer Code: WiC64-Tools.
			t "lib.WiC64"

;*** Hauptprpogramm.
:MAIN			lda	#ST_WR_FORE		;Nur in den Vordergrund schreiben.
			sta	dispBufferOn

;--- Auf GDOS64 testen.
;			lda	bootName +1		;GDOS-Kernal aktiv ?
;			cmp	#"D"			;"GDOS64-V3"
;			bne	:GEOS			; => Nein, weiter...
;			lda	bootName +7
;			cmp	#"V"
;			beq	:GDOS64			; => Ja, GDOS64.

;--- Auf GDOS64/MP3 testen.
			lda	MP3_CODE +0		;Kennung für GDOS64/MP3.
			cmp	#"M"			;MegaPatch installiert ?
			bne	:GEOS			; => Nein, weiter...
			lda	MP3_CODE +1
			cmp	#"P"
			beq	:GDOS64			; => Ja, GDOS64/MP3.

;--- Hintergrund für GEOS V2:
::GEOS			lda	#$02			;GEOS:
			jsr	SetPattern		;Hintergrund löschen.

			jsr	i_Rectangle
			b	$00,$c7
			w	$0000,$013f

			lda	#$00
			beq	:setColorMode

;--- Hintergrund für GDOS64/MP3:
::GDOS64		jsr	GetBackScreen		;GDOS64: Hintergrundbild.

			lda	#$ff
::setColorMode		sta	flagColorOn

;--- Hardware-Erkennung.
;Auf WiC64/SuperCPU/TC64 testen und
;WiC64-Informationen einlesen.
if DEMO_MODE = FALSE
:checkHardware		jsr	_WiC64_CHECK		;WiC64-Hardware erkennen.
endif

if DEMO_MODE = TRUE
:checkHardware		lda	flagTurboMode		;Turbo-Hardware gefunden ?
			bne	:no_emul		; => Ja, weiter...
			lda	#%10100000		;Demo: Turbo/TC64.
			sta	flagTurboMode
::no_emul
endif

			lda	flagTurboMode
			and	#%01100000		;Turbo-Hardware verfügbar ?
			bne	:turboActive		; => Ja, weiter...

::noTurbo		lda	#NULL			;Kein TC64/SuperCPU...
			b $2c
::turboActive		lda	#DBOPVEC		;TC64 oder SuperCPU vorhanden.
			sta	dlgBox_noTurbo

if DEMO_MODE = TRUE
			lda	#NULL			;Demo-Modus:
			sta	flagWiC64rdy		; => WiC64 vorhanden.
			lda	#1
			sta	r12L			; => Übertragung beendet.
			lda	#"9"
			sta	r12H			; => IP-Adresse gültig.
endif

			ldx	#<text_OK		;Status.
			ldy	#>text_OK
			bit	flagWiC64rdy		;WiC64 vorhanden?
			bpl	:1			; => Ja, weiter...
if DEMO_MODE = TRUE
			bmi	:1
endif
			lda	#NULL
			sta	dlgBox_noWiC64
			ldx	#<text_noWiC64
			ldy	#>text_noWiC64
::1			stx	r5L
			sty	r5H

			ldx	#<text_noWLAN		;WLAN-IP.
			ldy	#>text_noWLAN
			lda	r12H			;WLAN verfügbar?
			beq	:2			; => Nein, weiter...
			cmp	#"0"			;IP-Adresse = "0.0.0.0"?
			beq	:2			; => Ja, nicht verbunden, weiter...
			ldx	#<com_getip_data
			ldy	#>com_getip_data
::2			stx	r6L
			sty	r6H

			ldx	#<text_noData		;WLAN-SSID.
			ldy	#>text_noData
			lda	r12L			;Übertragung beendet?
			beq	:3			; => Nein, weiter...
			ldx	#<com_getnam_data
			ldy	#>com_getnam_data
::3			stx	r7L
			sty	r7H

			ldx	#<text_noData		;WLAN-RSSI.
			ldy	#>text_noData
			lda	r12L			;Übertragung beendet?
			beq	:4			; => Nein, weiter...
			ldx	#<com_getsig_data
			ldy	#>com_getsig_data
::4			stx	r8L
			sty	r8H

			lda	#<dlgBoxData		;Zeiger auf Infobox.
			sta	r0L
			lda	#>dlgBoxData
			sta	r0H

			jsr	DoDlgBox		;Info-Box öffnen.

			lda	sysDBData		;Rückmeldung auswerten.
			cmp	#OPEN			;Portal öffnen ?
			beq	:portal			; => Ja, weiter...

			jmp	EnterDeskTop		;Zum DeskTop...

;--- WiC64-Portal-Menü laden/starten.
::portal		jsr	i_FillRam		;Löschen des Farb- und Grafik-RAM
			w	40*25			;(Screen-Garbage beim RESET).
			w	$0400			;Bildschirm Bank #0.
			b	$20

			jsr	i_FillRam
			w	40*25
			w	$0c00			;FarbRAM Bank #0.
			b	$00

			jsr	i_FillRam
			w	40*25*8
			w	$2000			;Hires-Grafik Bank #0.
			b	$00

;			jsr	PurgeTurbo		;TurboDOS komplett abschalten.
;			jsr	InitForIO		;GEOS-I/O nicht erforderlich.

			jmp	_WiC64_Portal		;Zum Portal...

;*** WiC64-Logo anzeigen.
:drawWiC64logo		bit	flagColorOn		;Farbe anzeigen ?
			bpl	:skip_color		; => Nein, weiter...

			ldx	#0			;Farben für das Logo direkt
::loop			lda	WIC64_LOGO_COL,x	;in das FarbRAM schreiben.
			sta	LINE_1,x
			sta	LINE_2,x
			sta	LINE_3,x
			inx
			cpx	#WIC64_LOGO_X
			bcc	:loop

::skip_color		jsr	i_BitmapUp		;WiC64-Logo anzeigen.
			w	WIC64_LOGO
			b	LOGO_X
			b	LOGO_Y
			b	WIC64_LOGO_X
			b	WIC64_LOGO_Y

			rts

;*** DialogBox: Turbo-Modus angeklickt?
:chkMouseTurbo		lda	#TURBO_OPT_Y +0		;Linke/obere Ecke setzen.
			sta	r2L
			lda	#< TURBO_OPT_X +0
			sta	r3L
			lda	#> TURBO_OPT_X +0
			sta	r3H

			lda	#TURBO_OPT_Y +7		;Rechter/untere Ecke setzen.
			sta	r2H
			lda	#< TURBO_OPT_X +7
			sta	r4L
			lda	#> TURBO_OPT_X +7
			sta	r4H

			jsr	IsMseInRegion
			cmp	#TRUE			;Turbo-Modus angeklickt ?
			bne	:exit			; => Nein, Ende...

			jsr	swapTurboMode		;Turbo-Modus wechseln.

::wait			lda	mouseData		;Warten bis keine Maustaste
			bpl	:wait			;mehr gedrückt.
			lda	#$00
			sta	pressFlag
::exit			rts

;*** Turbo-Modus wechseln.
:swapTurboMode		lda	flagTurboMode		;Aktuellen Turbo-Modus einlesen.
			eor	#%10000000		;Turbo-Flag invertieren und
			sta	flagTurboMode		;neuen Turbo-Modus speichern.

:setTurboMode		bit	flagTurboMode		;Ist Turbo-Modus aktiv ?
			bpl	:turboModeOff		; => Nein, weiter...

::turboModeOn		lda	#$01			;Füllmuster für "Aktiv".
			b $2c
::turboModeOff		lda	#$00			;Füllmuster für "Nicht aktiv".
			jsr	SetPattern		;GEOS-Füllmuster setzen.

			jsr	i_FrameRectangle	;Rahmen zeichnen.
			b	TURBO_OPT_Y-1,TURBO_OPT_Y+8
			w	TURBO_OPT_X-1,TURBO_OPT_X+8
			b	%11111111

			jsr	i_Rectangle		;Turbo-Modus anzeigen.
			b	TURBO_OPT_Y+0,TURBO_OPT_Y+7
			w	TURBO_OPT_X+0,TURBO_OPT_X+7

			rts

;*** Turbo-Modus an/aus.
:setSpeedMode		lda	flagTurboMode
			and	#%01100000		;SuperCPU / TC64 vorhanden ?
			beq	:exit			; => Nein, Abbruch...

			bit	flagTurboMode		;Turbo-Modus setzen?
			bmi	:turbo_on		; => Ja, weiter...

::turbo_off		jmp	_WiC64_TURBO_OFF	;Turbo-Modus abschalten.
::turbo_on		jmp	_WiC64_TURBO_ON		;Turbo-Modus einschalten.

::exit			rts

;*** Portal-Menü laden.
:_WiC64_Portal		sei				;Interrupt sperren.

			lda	#KRNL_BAS_IO_IN		;IO, KERNAL-, BASIC-ROM einblenden.
			sta	CPU_DATA

::initExitGEOS		ldx	#$ff			;Stack löschen.
			txs

			jsr	setSpeedMode		;Turbo-Modus SuperCPU/TC64 setzen.

;--- Interrupt-Status zurücksetzen.
;Erforderlich falls die Routine mit
;":InitForIO" aufgerufen wurde!
::1			lda	#%11110001
			sta	$d01a			;Raster-IRQ zulassen.
			lda	#%01111111
			sta	$dd0d			;NMI sperren.
			bit	$dd0d			;NMI-Register zurücksetzen.
							;(Werden durch lesen gelöscht)

			lda	$d016			;VIC Control#2 initialisieren.
			and	#%11100000		;40 Spalten, Kein Pixel-Offset und
			ora	#%00001000		;MultiColor-Grafik aus.
			sta	$d016

			lda	#%00000011		;Datenport PA0+PA1 auf Ausgang.
			sta	$dd02
			lda	$dd00			;VIC-Speicherbank #0 aktivieren.
;			and	#%11111100
			ora	#%00000011
			sta	$dd00

;HINWEIS:
;Bei einer SuperCPU die Optimierung
;auf "Standard" zurücksetzen.
;Bei einer V2 entspricht das nur der
;Optimierung des Bildschirm-RAM.
;Dabei wird der Bereich $0400-$07FF im
;RAM der SuperCPU gespiegelt.
;Setzt man die Einstellung hier nicht
;zurück, dann schreibt der Kernal in
;das Spiegel-RAM, nach einem Reset
;erfolgt die Ausgabe auf dem C64-RAM.
; => Bildschirm nicht initialisiert.
			sta	SCPU_HW_EN		;SuperCPU/Hardware-Register ein.
			sta	SCPU_HW_VIC_OFF		;BASIC-Optimierung aktivieren.
			sta	SCPU_HW_DIS		;SuperCPU/Hardware-Register aus.

			jsr	$fda3			;":IOINIT" = CIA-Register löschen.

			jsr	$fd50			;":RAMTAS" = RAM-Reset ab $FD5F:
							;          Kasettenpuffer setzen.
							;          Bildschirm auf $0400.
;			jsr	$fd5f			;Löschen der ZeroPage und des
							;Bereichs $0200-$03FF überspringen!

			ldx	#< $a000		;Endeadresse+1 BASIC-RAM.
			lda	#> $a000
			stx	$0283			;":MEMSIZ"
			sta	$0284

;			ldx	#< $0800		;Startadresse BASIC-RAM.
			lda	#> $0800
			stx	$0281			;":MEMSTR"
			sta	$0282

			lda	#> VICSCN
			sta	$0288			;Adresse Page#0 Bildschirmspeicher.

			ldx	#< TBUFFR		;Startadresse
			lda	#> TBUFFR		;Kassettenpuffer.
			stx	$b2			;":TAPE1"
			sta	$b3

;--- Kernal-Vektoren initialisieren:
			jsr	$e453			;":INIVEC" = $0300-$030B

			jsr	$fd15			;":RESTOR" = $0314-$0333

			jsr	$e3bf			;":INITMP" = Init BASIC-Interpreter.
							;Verändert den STack, daher nicht
							;aus Unterprogramm aufrufen!

			jsr	$ff81			;":CINT"   = Bildschirm-Reset.
			jsr	$e422			;":MSGNEW" = Einschaltmeldung.

			lda	#CR			;Leerzeile ausgeben.
			jsr	$ffd2

			lda	$dd0d			;I/O zurücksetzen.
			lda	#$ff			;Verzögerung für Timer A setzen.
			sta	$dd04
			sta	$dd05

			lda	#$7f			;Bit%7 = 0: Alle Interrupts aus.
			sta	$dd0d
			lda	#$81			;Bit%7 = 1: Interrupts ein.
			sta	$dd0d			;Bit%0 = 1: Nur Interrupt Timer A.
			bit	$dd0d			;Register zurücksetzen.

			lda	#$81			;Bit%7 = 1: 50Mhz-Uhr !!!
			sta	$dd0e			;Bit%0 = 1: Start Timer.

			lda	#8			;Laufwerk #8 aktivieren.
			sta	curDevice

;*** Portal-Launcher laden/starten.
:loadPortal		ldx	#r10L			;ZeroPage bereits initialisiert.
::backup		lda	zpage,x			;Verwendete Adressen sichern und
			pha				;nach dem Download zurücksetzen.
			inx
			cpx	#r15H +1
			bcc	:backup

if DEMO_MODE = FALSE
			jsr	_WiC64_Init		;WiC64 initialisieren.
endif

			ldx	#lenMenuLoader
::1			lda	loaderBegin,x		;Lade-Routine für Portal-Launcher
			sta	TBUFFR,x		;installieren.
			dex
			bpl	:1

if DEMO_MODE = FALSE
::load			lda	#<com_geturl
			ldy	#>com_geturl
			jsr	_WiC64_SendCom 		;HTTP/GET an WiC64 senden.
			txa				;Fehler/Timeout?
			bne	:load			; => Ja, nochmal versuchen...

			jsr	_WiC64_InitGet2		;Datenampfang initialisieren.
			txa				;Fehler/Timeout?
			bne	:load			; => Ja, nochmal versuchen...

			lda	lenDataSize +0		;Anzahl Daten-Bytes übernehmen.
			sta	r11H
			sta	r13L

			ldx	lenDataSize +1
			stx	r11L

			jsr	read_byte 		;Ladeadresse ignorieren.
			jsr	read_byte

			lda	r11H			;Programgröße testen. Wenn nur zwei
			bne	:2			;Bytes, dann Fehler.
			lda	r11L
			cmp	#$02
			beq	:load			; => Nochmal versuchen.

			inc	extclr			;Rahmenfarbe wechseln für
			jsr	_WiC64_Wait		;Status-Anzeige.
			dec	extclr

::2			inc	r13L			;Zähler optimieren für dec/bne.
endif

			lda	#< $0801 		;Zeiger auf Ladeadresse für
			sta	r10L			;Portal-Menü setzen.
			lda	#> $0801 		; => Immer $0801 !
			sta	r10H

			jmp	TBUFFR 			;Programm laden und starten.

;*** LOAD-Routine.
;HINIWEIS:
;Keine absoluten Sprünge über jmp/jsr
;mit Ausnahme von Kernal-Aufrufen!
;Die Routine ist relokatibel!

;*** Portal-Launcher via HTTP/GET laden.
if DEMO_MODE = FALSE
:loaderBegin		lda	#timeout_default 	;Timeout initialisieren.
			sta	r0L

;			lda	CIA_TOD10		;Sicherstellen das Timer läuft.
;			sta	CIA_TOD10		;(Wird für Handshake genutzt)

			ldy	#$00			;Zeiger auf Anfang Speicher.
			ldx	r11L			;Byte-Zähler initialisieren.
::loop			lda	#$00
			sta	r0H
::wait_ready		lda	$dd0d 			;Interrupt-Status einlesen.

;HINWEIS:
;Die NOP-Verzögerung ist erforderlich
;wenn das WiC64 unter VICE emuliert
;wird, da sonst das Byte vom WiC64 zu
;schnell abgerufen wird.
			nop
			nop
			nop
			nop

			and	#%00010000		;CIA#2 NMI FLAG ?
			bne	:byte_ready  		; => Ja, Handshake OK, Ende...

			inc	r0H
			bne	:wait_ready

;			lda	CIA_TOD10		;Bei Turbo-Karten 1/10sec. warten.
;::wait			cmp	CIA_TOD10		;(dec/bne läuft hier zu schnell)
;			beq	:wait

::wait			lda	rasreq			;Warteschleife...
			bmi	:wait
::wait1			lda	rasreq
			bpl	:wait1

			dec	r0L 			;Timeout abgelaufen ?
			bne	:wait_ready		; => Nein, weiter warten...

			jmp	$fce2			;Ladefehler => C64-Reset.

::byte_ready		lda	$dd01 			;Byte von WiC64 empfangen und
			sta	(r10L),y		;speichern.
;			sta	extclr 			;Debug-Modus: Rahmenfarbe ändern.

			iny				;256 Bytes empfangen ?
			bne	:1			; => Nein, weiter...
			inc	r10H			;High-Byte +1.

::1			dex
			bne	:loop
			dec	r13L			;Alle Bytes empfangen ?
			bne	:loop			; => Nein, weiter...
endif

;*** Demo-Anwendung laden.
if DEMO_MODE = TRUE
:loaderBegin		ldy	#$00			;BASIC-Programm kopieren.
::1			lda	progBegin,y
			sta	(r10L),y
			iny
			cpy	#progLen
			bcc	:1
endif

;--- GET beenden, Programmlänge ermitteln.
			tya				;Ende BASIC-Programm
			clc				;definieren.
			adc	$2b
			sta	$2d			;":VARTAB" Start BASIC-Variablen.
			sta	$ae			;":EAL"    Programmende.
			lda	r10H
			adc	#$00
			sta	$2e
			sta	$af

			ldx	#r15H			;Verwendete ZeroPage-Adressen
::restore		pla				;wieder zurücksetzen.
			sta	zpage,x			;":r10L" ist Teil des Stringstack.
			dex				;Fehlerhafte Werte führen zu einem
			cpx	#r10L			;"FORMULA TOO COMPLEX"-Fehler.
			bcs	:restore

;--- Wird bereits durch ":initExitGEOS" ausgeführt.
;			jsr	$ff81			;":CINT"   = Bildschirm-Reset.

;--- CIA initialisieren.
			jsr	$fda3 			;":IOINIT" = Init CIA
							; => Nach ":LOAD" erneut ausführen!

;--- BASIC-Interpreter intialisieren.
			jsr	$a659			;":NEWCLR" = "NEW" ausführen.
							; => Nach ":LOAD" erneut ausführen!
			jsr	$a533			;":LNKPRG" = Linkzeiger berechnen.

;--- Start!
			cli
			jmp	$a7ae 			;":INTPRT" = "RUN" ausführen.

:loaderEnd		g loaderBegin + (VICSCN - TBUFFR) -1
:lenMenuLoader		= (loaderEnd - loaderBegin)

;*** Variablen.
:flagColorOn		b $00 ;$FF = GDOS64/MP3 mit Farbe.
			      ;$00 = GEOS ohne Farbe.
;*** Fehlertexte.
:text_OK		b BOLDON
			b "OK!"
			b PLAINTEXT,0
:text_noWiC64		b BOLDON
			b "N.V."
			b PLAINTEXT,0
:text_noWLAN		b "Kein Internet!",0
:text_noData		b "-",0

;*** DialogBox.
:dlgBoxData		b $81
			b DBTXTSTR  ,$08,$10		;Status
			w tx01
			b DBTXTSTR  ,$08,$1c		;WiC64...
			w tx02
			b DBVARSTR  ,$26,$1c
			b r5L

			b DBTXTSTR  ,$08,$2b		;WLAN-SSID
			w tx04
			b DBVARSTR  ,$1e,$2b
			b r7L

			b DBTXTSTR  ,$08,$36		;WLAN-RSSI
			w tx05
			b DBVARSTR  ,$1e,$36
			b r8L

			b DBTXTSTR  ,$08,$41		;WLAN-IP
			w tx03
			b DBVARSTR  ,$14,$41
			b r6L

			b DB_USR_ROUT			;WiC64-Logo...
			w drawWiC64logo
			b OK        ,$11,$48

:dlgBox_noWiC64		b OPEN      ,$01,$48		;Portal-Launcher...
			b DBTXTSTR  ,$3a,$54
			w tx06

:dlgBox_noTurbo		b DBOPVEC			;Option für Turbo-Modus...
			w chkMouseTurbo
			b DB_USR_ROUT
			w setTurboMode
			b DBTXTSTR  ,$6e,$36
			w tx07
			b DBTXTSTR  ,$7c,$41
			w tx08
			b NULL

:tx01			b PLAINTEXT,BOLDON
			b "STATUS:"
			b PLAINTEXT,0

:tx02			b "WiC64:",0
:tx03			b "IP:",0
:tx04			b "SSID:",0
:tx05			b "RSSI:",0
:tx06			b BOLDON
			b "(Portal)"
			b PLAINTEXT,0
:tx07			b "SuperCPU / TC64",0
:tx08			b "Turbo-Modus",0

;*** WiC64-Logo
:WIC64_LOGO
<MISSING_IMAGE_DATA>
:WIC64_LOGO_X		= .x
:WIC64_LOGO_Y		= .y

;*** Farben für WiC64-Logo.
:WIC64_LOGO_COL		b $40,$40,$e0,$e0,$e0,$e0,$e0,$e0,$20,$20,$20,$20

;*** Download-Adresse für Portal-Launcher.
;HINWEIS:
;GEOS verwendet ASCII-Codes, daher hier
;die URL in Kleinbuchstaben!
;Der WiC64-Befehl wird als PETSCII-Code
;gesendet, daher Großbuchstaben!
if DEMO_MODE = FALSE
:com_geturl		b "W",$20,$00,$01
:com_geturl_data	b "http://x.wic64.net/menue.prg"
			b NULL
endif

;*** Anwendung für Demo-Modus.
;HINWEIS:
;Im Demo-Modus wird nur ein Test-
;Programm "Hello World!" gestartet.
if DEMO_MODE = TRUE
:progBegin		b $15,$08,$0a,$00,$99,$22,$48,$45
			b $4c,$4c,$4f,$20,$57,$4f,$52,$4c
			b $44,$21,$22,$00,$00,$00
:progEnd
:progLen		= (progEnd - progBegin)
endif

;******************************************************************************
;*** Endadresse testen:                                                     ***
			g $8000
;******************************************************************************
