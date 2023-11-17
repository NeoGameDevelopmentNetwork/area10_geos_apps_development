; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; Symboltabellen einbinden.
;
if .p
			t "TopSym"
			t "TopMac"
			t "Sym128.erg"
endif

;
; GEOS-Header definieren.
;
			n "keyData"
			c "keyData     V1.0"
			a "Markus kanet"

			f APPLICATION
			z $40 ;GEOS64/128 40+80Z.

			o APP_RAM

			h "Zeichen, Dezimal- und Hex-Wert einer Taste anzeigen. Mausklick=Ende."

			i
<MISSING_IMAGE_DATA>

;
; Tastaturabfrage starten.
;
:MAININIT		sei				;Interrupt sperren.

			LoadW	r11,$0000
			ldy	#0
			jsr	StartMouseMode		;Mausabfrage starten.

			cli				;Interrupt freigeben.

::wait			bit	mouseData		;Warten bis keine
			bpl	:wait			;Maustaste gedrückt.
			lda	#NULL
			sta	pressFlag

			lda	#0			;Bildschirm löschen.
			jsr	SetPattern

			ldy	#0
			bit	c128Flag
			bpl	:1
			ldy	#8

::1			ldx	#0
::2			lda	scrData,y
			sta	r2,x
			iny
			inx
			cpx	#6
			bcc	:2

			jsr	Rectangle

			LoadW	r11,10
			LoadB	r1H,64
			LoadW	r0,InfoText
			jsr	PutString

;
; Ende über Mausklick.
; => Rückkehr zum DeskTop.
;
			LoadW	otherPressVec,EnterDeskTop

;
; Taste auswerten.
; Kombinationen mit CBM/SHIFT/CTRL
; sind möglich.
			LoadW	keyVector,printKey

			rts				;Zurück zur GEOS-Mainloop.

;
; Infotext
;
:InfoText		b PLAINTEXT
			b "Taste drücken für Angaben zu :keyData",CR
			b GOTOX
			w $000a
			b "Zum beenden Maustaste drücken."
			b NULL

;
; Aufruf aus der Mainloop:
; => Taste wurde gedrückt.
;
:printKey		LoadW	r11,10
			LoadB	r1H,20

			jsr	:cleanup		;Ausgabebereich löschen.

			lda	keyData			;Taste einlesen.
			cmp	#$20			;Sichtbare Taste?
			bcc	:1			; => Nein, weiter...
			cmp	#$7f			;Sichtbare Taste?
			bcs	:1			; => Nein, weiter...

			LoadW	r11,10			;Ausgabeposition setzen.
			LoadB	r1H,20
			lda	keyData
			jsr	SmallPutChar		;Zeichencode ausgeben.

			jsr	:cleanup		;Ausgabebereich löschen.

::1			LoadW	r11,40			;Position für
			LoadB	r1H,20			;Dezimalwert.

			lda	keyData
			sta	r0L
			lda	#$00
			sta	r0H
			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal		;Tastencode/Dezimal.

			jsr	:cleanup		;Ausgabebereich löschen.

			LoadW	r11,70			;Position für
			LoadB	r1H,20			;Hexadezimalwert.

			lda	#"$"			;Hexzahl-Kennung
			jsr	SmallPutChar		;ausgeben.

			lda	keyData			;Tastencode nach
			jsr	HEX2ASCII		;ASCIi wandeln.
			pha
			txa
			jsr	SmallPutChar		;High-Nibble ausgeben.
			pla
			jsr	SmallPutChar		;Low-Nibble ausgeben.

::cleanup		lda	#" "			;Reste von vorheriger
			jsr	SmallPutChar		;Ausgabe löschen.
			lda	#" "
			jsr	SmallPutChar		;Proportionalfont!)

			rts

;
; Größe für Bildschirmbereich.
; Beim C128 inkl. Verdoppelung für
; den 80-Zeichen-Bildschirm.
;
:scrData		b 0				;C64.
			b 199
			w 0
			w 319
			w NULL

			b 0				;C128.
			b 199
			w 0
			w 319!DOUBLE_W!ADD1_W
			w NULL

;
; HEX-Zahl nach ASCII wandeln.
;
; Übergabe:
; AKKU = Hex-Zahl.
;
; Rückgabe:
; AKKU = Low -Nibble Hex-Zahl.
; XREG = High-Nibble Hex-Zahl.
;
:HEX2ASCII		pha				;HEX-Wert speichern.

			lsr				;HIGH-Nibble isolieren.
			lsr
			lsr
			lsr
			jsr	:1			;HIGH-Nibble nach ASCII.
			tax				;Ergebnis zwischenspeichern.

			pla				;HEX-Wert zurücksetzen und
							;nach ASCII wandeln.

::1			and	#%00001111
			cmp	#10			;Zahl größer 10?
			bcc	:2			; => Nein, weiter...

			clc				;Zeichen $A-$F wandeln.
			adc	#$07

::2			clc
			adc	#"0"

			rts
