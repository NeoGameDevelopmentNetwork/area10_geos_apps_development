; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; Symboldateien einbinden.
;
if .p
			t "TopSym"
			t "TopMac"
endif

;
; GEOS-Header definieren.
;
			n "DiskAnalyzerDEMO"
			c "ANALYZER    V1.0",NULL
			a "Markus Kanet",NULL

			f APPLICATION
			z $80 ;Nur GEOS64.

			o APP_RAM

			h "Original-Programm GEOSTOOLS von W.Knupe (w)1989, UI-Nachbau von M.Kanet (w)2022"

			i
<MISSING_IMAGE_DATA>

;
; Hauptmenü anzeigen
;
:MAININIT		lda	#0			; Bildschirm löschen.
			jsr	SetPattern

			jsr	i_Rectangle
			b	0,199
			w	0,319

			LoadW	r0,geosmenu		; GEOS-Menü anzeigen.
			jsr	DoMenu

			lda	#ST_FLASH
			sta	iconSelFlag		; Icons beim anklicken invertieren.

			LoadW	r0,iconmenu		; ICON-Menü anzeigen.
			jsr	DoIcons

			jsr	UseSystemFont		; Systemzeichensatz aktivieren.

			LoadW	r0,menutext		; Menü-Text ausgeben.
			jsr	PutString

			jsr	Zeige_Adresse		; Aktuellen Track/Sektor anzeigen.

			jsr	Lade_Sektor		; Sektor-Inhalt einlesen.

			jsr	Zeige_Inhalt		; Sektor-Inhalt anzeigen.

			rts				; Zurück zur GEOS-Mainloop.

;
; Nach BASIC wechseln.
;
:Starte_BASIC		LoadW	r0,:Befehl		; Zeiger auf BASIC-Befehl.

			lda	#$00			; Keine Datei laden.
			sta	r5L
			sta	r5H

			sta	$0800			; Kein Programm starten.
			sta	$0801
			sta	$0802
			sta	$0803

			LoadW	r7,$0803		; Endadresse setzen.

			jmp	ToBasic			; Nach BASIC wechseln.

; Dummy-Befehlstring für BASIC V2.
::Befehl		b "PRINT"
			b 34,"HELLO WORLD!",34
			b NULL

;
; Sektor einlesen.
;
:Lade_Sektor		lda	Adr_TR			; Aktueller Track/Sektor
			sta	r1L			; nach r1L/r1H.
			lda	Adr_SE
			sta	r1H

			LoadW	r4,diskBlkBuf		; Sektor nach diskBlkBuf.

			jsr	GetBlock		; Sektor einlesen.
			txa				; Diskfehler?
			beq	:ok			; => Nein, weiter...

			jmp	Panic			; Diskfehler!

::ok			rts				; Ende...

;
; Track/Sektor anzeigen.
;
:Zeige_Adresse		jsr	i_GraphicsString

			b NEWPATTERN			;Füllmuster setzen.
			b $00

			b MOVEPENTO			;Zeiger auf xl/yo setzen.
			w $0110
			b $b0

			b RECTANGLETO			;Rechteck nach xr/yu.
			w $013f
			b $c7

			b NULL				;Ende.

			LoadW	r0,textcursek		; Info-Text ausgeben.
			jsr	PutString

			LoadW	r11,$012f		; Cursor setzen.
			LoadB	r1H,$b6

			lda	Adr_TR			; Track nach r0L.
			sta	r0L
			lda	#$00			; Highbyte immer $00.
			sta	r0H

			; Max. 12 Pixel breit, rechtsbündig, keine führende 0.
			lda	#12!SET_RIGHTJUST!SET_SUPRESS
			jsr	PutDecimal		; Track-Adresse ausgeben.

			LoadW	r11,$012f		; Cursor setzen.
			LoadB	r1H,$c0

			lda	Adr_SE			; Sektor nach r0L.
			sta	r0L
			lda	#$00			; Highbyte immer $00.
			sta	r0H

			; Max. 12 Pixel breit, rechtsbündig, keine führende 0.
			lda	#12!SET_RIGHTJUST!SET_SUPRESS
			lda	#12!SET_RIGHTJUST!SET_SUPRESS
			jmp	PutDecimal		; Sektor-Adresse ausgeben.

;
; Track +1 lesen
;
:SetTAdrP1		inc	Adr_TR
			jsr	Zeige_Adresse
			rts

;
; Track -1 lesen
;
:SetTAdrM1		dec	Adr_TR
			jsr	Zeige_Adresse
			rts

;
; Sektor +1 lesen
;
:SetSAdrP1		inc	Adr_SE
			jsr	Zeige_Adresse
			rts

; Sektor -1 lesen
:SetSAdrM1		dec	Adr_SE
			jsr	Zeige_Adresse
			rts

;
; Track +1 setzen
;
:SetTrP1		inc	Adr_TR
			jsr	Zeige_Adresse
			jsr	Lade_Sektor
			jsr	Zeige_Inhalt
			rts

;
; Track -1 setzen
;
:SetTrM1		dec	Adr_TR
			jsr	Zeige_Adresse
			jsr	Lade_Sektor
			jsr	Zeige_Inhalt
			rts

;
; Sekor lesen und anzeigen
;
:RdPrntSek		jsr	Lade_Sektor
			jsr	Zeige_Inhalt
			rts

;
; Folgesektor lesen
;
:RdNextSek		lda	diskBlkBuf +0		;Folgesektor verfügbar?
			beq	:exit			; => Nein, Ende...
			sta	Adr_TR
			lda	diskBlkBuf +1
			sta	Adr_SE
			jsr	Zeige_Adresse
			jsr	Lade_Sektor
			jsr	Zeige_Inhalt
::exit			rts

;
; HEX-Zahl nach ASCII wandeln.
;
; Übergabe:
; AKKU = Hex-Zahl.
; Rückgabe:
; AKKU = Low-Nibble Hex-Zahl.
; XREG = High-Nibble Hex-Zahl.
:HEX2ASCII		pha				; HEX-Wert speichern.
			lsr				; HIGH-Nibble isolieren.
			lsr
			lsr
			lsr
			jsr	:1			; HIGH-Nibble nach ASCII wandeln.
			tax				; Ergebnis zwischenspeichern.

			pla				; HEX-Wert zurücksetzen und
							; nach ASCII wandeln.
::1			and	#%00001111
			clc
			adc	#"0"
			cmp	#"9" +1			; Zahl größer 10?
			bcc	:2			; => Ja, weiter...
			clc				; HEX-Zeichen nach $a-$f wandeln.
			adc	#$27
::2			rts

;
; Sektorinhalt anzeigen
;
:Zeige_Inhalt		jsr	i_GraphicsString

			b NEWPATTERN			;Füllmuster setzen.
			b $00

			b MOVEPENTO			;Zeiger auf xl/yo setzen.
			w $0000
			b $10

			b RECTANGLETO			;Rechteck nach xr/yu.
			w $013f
			b $af

			b NULL				;Ende.
			LoadB	a0L,0			; Zeiger auf Byte #1.
			LoadW	a1,diskBlkBuf		; Zeiger auf Datenpuffer.

			LoadB	r1H,20			; Startwert für Y-Position Text.

::loop			LoadW	r11,$0000		; Startwert für X-Position Zeile.
			AddVB	9,r1H			; Y-Position auf nächste Zeile.

			lda	a0L			; Position einlesen.
			jsr	HEX2ASCII		; Nach ASCII wandeln.
			pha
			txa
			jsr	SmallPutChar		; High-Nibble ausgeben.
			pla
			jsr	SmallPutChar		; Low-Nibble ausgeben.

			lda	a0L			; Aktuelles Byte zwischenspeichern.
			pha

			LoadW	r11,13			; X-Position für HEX-Werte setzen.
			LoadB	a0H,16			; Anzahl Werte.
			jsr	zeige_hex		; HEX-Werte anzeigen.

			pla				; Position wieder auf aktuelles
			sta	a0L			; Byte zurücksetzen.

			LoadW	r11,190			; X-Position für ASCII-Werte setzen.
			LoadB	a0H,16			; Anzahl Werte.
			jsr	zeige_ascii		; ASCII-Werte anzeigen.

			lda	a0L			; Alle Werte ausgegeben ?
			bne	:loop			; => Nein, weiter...

			rts

;
; HEX-Werte anzeigen.
;
:zeige_hex		MoveW	r11,a2			; X-Position zwischenspeichern.

			ldy	a0L
			lda	(a1L),y			; Aktuelles Zeichen einlesen und
			jsr	HEX2ASCII		; nach ASCII wandeln.
			pha
			txa
			jsr	SmallPutChar		; High-Nibble ausgeben.
			pla
			jsr	SmallPutChar		; Low-Nibble ausgeben.

			inc	a0L			; Alle Bytes ausgegeben ?
			beq	:end			; => Ja, Ende...

			dec	a0H			; Alle Werte in Zeile ausgegeben ?
			beq	:end			; => Ja, Ende...

			lda	a2L			; X-Position für nächsten Wert
			clc				; berechnen.
			adc	#< 11
			sta	r11L
			lda	a2H
			adc	#> 11
			sta	r11H

			jmp	zeige_hex		; Nächsten Wert ausgeben.

::end			rts

;
; ASCII-Zeichen anzeigen.
;
:zeige_ascii		MoveW	r11,a2

			ldy	a0L
			lda	(a1L),y			; Aktuelles Zeichen einlesen.
			cmp	#$20			; Zeichen < $20 ?
			bcc	:dot			; => Ja, durch "." ersetzen.
			cmp	#$80 +1			; Zeichen gültig ?
			bcc	:print			; => Ja, Zeichen ausgeben.
::dot			lda	#"."			; Ersatzzeichen.
::print			jsr	SmallPutChar		; ASCII-Zeichen ausgeben.

			inc	a0L			; Alle Bytes ausgegeben ?
			beq	:end			; => Ja, Ende...

			dec	a0H			; Alle Werte in Zeile ausgegeben ?
			beq	:end			; => Ja, Ende...

			lda	a2L			; X-Position für nächsten Wert
			clc				; berechnen.
			adc	#< 8
			sta	r11L
			lda	a2H
			adc	#> 8
			sta	r11H

			jmp	zeige_ascii		; Nächsten Wert ausgeben.

::end			rts

;
; Programmdaten.
;
:Adr_TR			b $07
:Adr_SE			b $03

;
; Texte für Hauptmenü.
;
:menutext		b PLAINTEXT

			b GOTOXY
			w $0011
			b $bb
			b "Track"

			b GOTOXY
			w $0051
			b $bb
			b "Sektor"

:textcursek		b PLAINTEXT

			b GOTOXY
			w $0112
			b $b6
			b "Track:"

			b GOTOXY
			w $0112
			b $c0
			b "Sektor:"

			b NULL

;
; Hauptmenü
;
:geosmenu
			b 0
			b 14
			w 0
			w 319
			b 2 ! HORIZONTAL ! UN_CONSTRAINED

			w :01
			b MENU_ACTION
			w EnterDeskTop

			w :02
			b MENU_ACTION
			w Starte_BASIC

::01			b "GEOS", NULL
::02			b "BASIC", NULL

;
; Icon-Menü.
;
:iconmenu		b 10
			w $0000
			b $00

			w icon_plus
			b $00,$b0,icon_plus_x,icon_plus_y
			w SetTAdrP1

			w icon_minus
			b $05,$b0,icon_minus_x,icon_minus_y
			w SetTAdrM1

			w icon_plus
			b $08,$b0,icon_plus_x,icon_plus_y
			w SetSAdrP1

			w icon_minus
			b $0e,$b0,icon_minus_x,icon_minus_y
			w SetSAdrM1

			w icon_r
			b $11,$b0,icon_r_x,icon_r_y
			w RdPrntSek

			w icon_n
			b $14,$b0,icon_n_x,icon_n_y
			w RdNextSek

			w icon_m
			b $17,$b0,icon_m_x,icon_m_y
			w $0000

			w icon_s
			b $1a,$b0,icon_s_x,icon_s_y
			w $0000

			w icon_t_minus
			b $1d,$b0,icon_t_minus_x,icon_t_minus_y
			w SetTrM1

			w icon_t_plus
			b $20,$b0,icon_t_plus_x,icon_t_plus_y
			w SetTrP1

;
; Dummy-Icon
if 0
; Packer-Code $80 + 32 Byte ungepackte Grafikdaten
:icon_dummy		b $80 +32
			b %00000000,%00000000
			b %01111111,%11111110
			b %01000000,%00000011
			b %01000000,%00000011
			b %01000000,%00000011
			b %01000000,%00000011
			b %01000000,%00000011
			b %01000000,%00000011
			b %01000000,%00000011
			b %01000000,%00000011
			b %01000000,%00000011
			b %01000000,%00000011
			b %01000000,%00000011
			b %01000000,%00000011
			b %01111111,%11111111
			b %00111111,%11111111

:icon_dummy_x = 2
:icon_dummy_y = 16
endif

;
; Menü-Icons.
;
; Packer-Code $80 + 32 Byte ungepackte Grafikdaten
:icon_plus		b $80 +32
			b %00000000,%00000000
			b %01111111,%11111110
			b %01000000,%00000011
			b %01000000,%00000011
			b %01000001,%10000011
			b %01000001,%10000011
			b %01000001,%10000011
			b %01001111,%11110011
			b %01001111,%11110011
			b %01000001,%10000011
			b %01000001,%10000011
			b %01000001,%10000011
			b %01000000,%00000011
			b %01000000,%00000011
			b %01111111,%11111111
			b %00111111,%11111111

:icon_plus_x = 2
:icon_plus_y = 16

;
; Packer-Code $80 + 32 Byte ungepackte Grafikdaten
:icon_minus		b $80 +32
			b %01111111,%11111110
			b %01000000,%00000011
			b %01000000,%00000011
			b %01000000,%00000011
			b %01000000,%00000011
			b %01000000,%00000011
			b %01001111,%11110011
			b %01001111,%11110011
			b %01000000,%00000011
			b %01000000,%00000011
			b %01000000,%00000011
			b %01000000,%00000011
			b %01000000,%00000011
			b %01111111,%11111111
			b %00111111,%11111111

:icon_minus_x = 2
:icon_minus_y = 16

;
; Packer-Code $80 + 32 Byte ungepackte Grafikdaten
:icon_r			b $80 +32
			b %00000000,%00000000
			b %01111111,%11111110
			b %01000000,%00000011
			b %01011111,%11110011
			b %01011111,%11110011
			b %01011000,%00011011
			b %01011000,%00011011
			b %01011000,%00011011
			b %01011111,%11111011
			b %01011111,%11110011
			b %01011000,%01100011
			b %01011000,%00110011
			b %01011000,%00011011
			b %01000000,%00000011
			b %01111111,%11111111
			b %00111111,%11111111

:icon_r_x = 2
:icon_r_y = 16

;
; Packer-Code $80 + 32 Byte ungepackte Grafikdaten
:icon_n			b $80 +32
			b %00000000,%00000000
			b %01111111,%11111110
			b %01000000,%00000011
			b %01011110,%00011011
			b %01011110,%00011011
			b %01011011,%00011011
			b %01011011,%00011011
			b %01011001,%10011011
			b %01011001,%10011011
			b %01011000,%11011011
			b %01011000,%11011011
			b %01011000,%01111011
			b %01011000,%01111011
			b %01000000,%00000011
			b %01111111,%11111111
			b %00111111,%11111111

:icon_n_x = 2
:icon_n_y = 16

;
; Packer-Code $80 + 32 Byte ungepackte Grafikdaten
:icon_m			b $80 +32
			b %00000000,%00000000
			b %01111111,%11111110
			b %01000000,%00000011
			b %01011110,%01111011
			b %01011110,%01111011
			b %01011011,%11011011
			b %01011011,%11011011
			b %01011001,%10011011
			b %01011001,%10011011
			b %01011000,%00011011
			b %01011000,%00011011
			b %01011000,%00011011
			b %01011000,%00011011
			b %01000000,%00000011
			b %01111111,%11111111
			b %00111111,%11111111

:icon_m_x = 2
:icon_m_y = 16

;
; Packer-Code $80 + 32 Byte ungepackte Grafikdaten
:icon_s			b $80 +32
			b %00000000,%00000000
			b %01111111,%11111110
			b %01000000,%00000011
			b %01001111,%11111011
			b %01011111,%11111011
			b %01011000,%00000011
			b %01011000,%00000011
			b %01011111,%11110011
			b %01001111,%11111011
			b %01000000,%00011011
			b %01000000,%00011011
			b %01011111,%11111011
			b %01011111,%11110011
			b %01000000,%00000011
			b %01111111,%11111111
			b %00111111,%11111111

:icon_s_x = 2
:icon_s_y = 16

;
; Packer-Code $80 + 32 Byte ungepackte Grafikdaten
:icon_t_minus		b $80 +32
			b %00000000,%00000000
			b %01111111,%11111110
			b %01000000,%00000011
			b %01011111,%11111011
			b %01011111,%11111011
			b %01000001,%10000011
			b %01000001,%10000011
			b %01000001,%10000011
			b %01000001,%10000011
			b %01000001,%10000011
			b %01000001,%10111011
			b %01000001,%10000011
			b %01000001,%10000011
			b %01000000,%00000011
			b %01111111,%11111111
			b %00111111,%11111111

:icon_t_minus_x = 2
:icon_t_minus_y = 16

;
; Packer-Code $80 + 32 Byte ungepackte Grafikdaten
:icon_t_plus		b $80 +32
			b %00000000,%00000000
			b %01111111,%11111110
			b %01000000,%00000011
			b %01011111,%11111011
			b %01011111,%11111011
			b %01000001,%10000011
			b %01000001,%10000011
			b %01000001,%10000011
			b %01000001,%10000011
			b %01000001,%10010011
			b %01000001,%10111011
			b %01000001,%10010011
			b %01000001,%10000011
			b %01000000,%00000011
			b %01111111,%11111111
			b %00111111,%11111111

:icon_t_plus_x = 2
:icon_t_plus_y = 16
