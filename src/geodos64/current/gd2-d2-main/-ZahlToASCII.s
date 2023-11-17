; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Zahl in Textstring umwandeln
; Datum			: 02.07.97
; Aufruf		: JSR  ZahlToASCII
; Übergabe		: r0L,r0H,r1LTByte 24Bit-Zahl (low,middle,high)
;			  r1H	Byte Y-Koordinate für PutString
;			  r11	Word X-Koordinate für PutString
; Rückgabe		: -ASCII_ZahlText Umgewandelte Zahl in ASCII
; Verändert		: AKKU,xReg,yReg
;			  r0L,r0H,r1L
;			  r2  bis r10
;			  r12 und r13
; Variablen		: -
; Routinen		: -
;******************************************************************************

;*** Zahl nach ASCII wandeln.
.ZahlToASCII		ldy	#16
			lda	#"0"			;Textspeicher mit "0"-Bytes
::101			sta	ASCII_Zahl,y		;auffüllen.
			dey
			bpl	:101

			ldy	#18			;Zeiger auf Vergleichstabelle.
			ldx	#$00			;Zeiger auf Textspeicher.

::102			sec				;10er-Werte von 24-BIT-Zahl
			lda	r0L			;subtrahieren.
			sbc	ZWerte+0,y
			pha
			lda	r0H
			sbc	ZWerte+1,y
			pha
			lda	r1L
			sbc	ZWerte+2,y
			bcc	:103			;Unterlauf ? Ja, nächster 10er-Wert.
			sta	r1L			;Zahlenrest merken.
			pla
			sta	r0H
			pla
			sta	r0L

;--- Ergänzung: 21.11.18/M.Kanet
;GeoDOS-Kernal-Speicherplatz einsparen.
;			lda	ASCII_Zahl,x		;Textspeicher korrigieren.
;			add	1
;			sta	ASCII_Zahl,x
			inc	ASCII_Zahl,x		;Textspeicher korrigieren.
			jmp	:102			;Umwandlung fortsetzen.

::103			pla
			pla

			cpy	#0			;Zahl umgewandelt ?
			beq	:105			;Ja, Ende...

			dey				;Zeiger auf Zahlentabelle berechnen.
			dey
			dey

			lda	ASCII_Zahl
			cmp	#"0"			;Aktueller 10er-Wert = 0 ?
			beq	:104			;Ja, weiter...
			inx				;Zeiger auf Textspeicher korrigieren.
::104			jmp	:102			;Umwandlung fortsetzen.

::105			inx
			lda	#$00			;Stringende kennzeichnen.
			sta	ASCII_Zahl,x
			rts

.ASCII_Zahl		s 17				;Textspeicher für ASCII-Zahl.
.ZWerte			b $01,$00,$00			;Wert für #1
			b $0a,$00,$00			;Wert für #10
			b $64,$00,$00			;Wert für #100
			b $e8,$03,$00			;Wert für #1000
			b $10,$27,$00			;Wert für #10000
			b $a0,$86,$01			;Wert für #100000
			b $40,$42,$0f			;Wert für #1000000
