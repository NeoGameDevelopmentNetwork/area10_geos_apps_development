; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: 24Bit-Zahl rechtsbündig ausgeben
;			  (mit "0" am Anfang)
; Datum			: 02.07.97
; Aufruf		: JSR  Do0Z24Bit
; Übergabe		: yReg	Byte Länge des Zahlenstrings
;			  r0L,r0H,r1LTByte 24Bit-Zahl (low,middle,high)
;			  r1H	Byte Y-Koordinate für PutString
;			  r11	Word X-Koordinate für PutString
; Rückgabe		: Bildschirmausgabe
; Verändert		: AKKU,xReg,yReg
;			  r0L,r0H,r1L
;			  r2  bis r10
;			  r12 und r13
; Variablen		: -ASCII_ZahlText Umgewandelte Zahl in ASCII
; Routinen		: -ZahlToASCII Zahl nach ASCII wandeln
;			  -SmallPutChar Zeichenausgabe
;******************************************************************************

;******************************************************************************
; Funktion		: 24Bit-Zahl rechtsbündig ausgeben
;			  (mit " " am Anfang)
; Datum			: 02.07.97
; Aufruf		: JSR  DoZahl24Bit
; Übergabe		: yReg	Byte Länge des Zahlenstrings
;			  r0L,r0H,r1LTByte 24Bit-Zahl (low,middle,high)
;			  r1H	Byte Y-Koordinate für PutString
;			  r11	Word X-Koordinate für PutString
; Rückgabe		: Bildschirmausgabe
; Verändert		: AKKU,xReg,yReg
;			  r0L,r0H,r1L
;			  r2  bis r10
;			  r12 und r13
; Variablen		: -ASCII_ZahlText Umgewandelte Zahl in ASCII
; Routinen		: -ZahlToASCII Zahl nach ASCII wandeln
;			  -SmallPutChar Zeichenausgabe
;******************************************************************************

;*** Zahl rechtsbündig ausgeben.
.Do0Z24Bit		lda	#"0"			;Füllzeichen "0".
			b $2c				;Nächste Routine überspringen.

;*** Zahl rechtsbündig ausgeben.
.DoZahl24Bit		lda	#" "			;Füllzeichen " ".
			sta	FillByte		;Füllzeichen merken.
			sty	StrLen			;Stringlänge merken.

			jsr	ZahlToASCII		;Zahl in ASCII umwandeln.

::101			cpx	StrLen			;String auf gewünschte Länge mit
			bcs	:102			;Füllzeichen auffüllen.
			txa
			pha
			lda	FillByte
			jsr	SmallPutChar
			pla
			tax
			inx
			bne	:101

::102			lda	#<ASCII_Zahl		;Ergebnis der Zahlenumwandlung
			ldx	#>ASCII_Zahl
			jmp	PutText			;ausgeben.

.FillByte		b $00
.StrLen			b $00
