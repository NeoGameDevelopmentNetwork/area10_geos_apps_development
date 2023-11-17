; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Datei-Informationen verfügbar?
:testFileInfo		lda	#"0"			;Status auswerten.
			cmp	UCI_STATUS_MSG +0
			bne	:err			; => Fehler...
			cmp	UCI_STATUS_MSG +1
			bne	:err			; => Fehler...
::ok			clc				;C-Flag=0: Kein Fehler.
			rts
::err			sec				;C-Flag=1: Fehler.
			rts

;*** Status ausgeben.
:prntStatus		lda	#< UCI_STATUS_MSG
			sta	r0L
			lda	#> UCI_STATUS_MSG
			sta	r0H

			jmp	PutString

;*** Dateiname ausgeben.
:prntFName		lda	vec2FName +0
			sta	r0L
			lda	vec2FName +1
			sta	r0H

			jmp	PutString

;*** Dateigröße ausgeben.
:prntSize		jsr	testFileInfo		;Datei-Informationen verfügbar?
			bcs	:err			; => Nein, Abbruch...

			jsr	ULIB_FILE_SIZE		;Dateigröße umwandeln.

			lda	r2L			;Einheit zwischenspeichern.
			pha

			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal		;Größe ausgeben.

			pla
			jsr	SmallPutChar		;Einheit ausgeben.

			lda	UCI_DATA_MSG +2		;Weniger als 64K ?
			ora	UCI_DATA_MSG +3
			bne	:err			; => Nein, Ende...

			lda	#" "			;Anzahl Bytes ausgeben.
			jsr	SmallPutChar
			lda	#"("			;Anzahl Bytes ausgeben.
			jsr	SmallPutChar

			lda	UCI_DATA_MSG +0
			sta	r0L
			lda	UCI_DATA_MSG +1
			sta	r0H

			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal		;Größe in Bytes ausgeben.

			lda	#"B"
			jsr	SmallPutChar

			lda	#")"
			jsr	SmallPutChar

::err			rts

;*** Datum ausgeben.
:prntDate		jsr	testFileInfo		;Datei-Informationen verfügbar?
			bcs	:err			; => Nein, Abbruch...

			jsr	ULIB_FILE_DATE		;Datum konvertieren.

			lda	r14L			;Tag.
			ldy	#"."
			sec
			jsr	prntDEZtoASCII

			lda	r14H			;Monat.
			ldy	#"."
			sec
			jsr	prntDEZtoASCII

			lda	r15L			;Jahr.
			ldy	#NULL
			clc
			jsr	prntDEZtoASCII

::err			rts

;*** Uhrzeit ausgeben.
:prntTime		jsr	testFileInfo		;Datei-Informationen verfügbar?
			bcs	:err			; => Nein, Abbruch...

			jsr	ULIB_FILE_TIME		;Datum konvertieren.

			lda	r14L			;Stunde.
			ldy	#":"
			sec
			jsr	prntDEZtoASCII

			lda	r14H			;Minute.
			ldy	#"."
			sec
			jsr	prntDEZtoASCII

			lda	r15L			;Sekunde.
;			ldy	#NULL
			clc
			jsr	prntDEZtoASCII

::err			rts

;*** Dezimalzahl nach ASCII wandeln.
;Übergabe: AKKU   = Dezimal-Zahl 0-99
;          C-Flag = 1 = Trenner in YREG auseben
;          YREG   = Zeichen für Zahlentrenner (":" oder ".")
;Rückgabe: -
:prntDEZtoASCII		sty	r15H

			php

			jsr	ULIB_DEZ_ASCII		;Zahl nach ASCII wandeln.

			pha				;Zahl ausgeben.
			txa
			jsr	SmallPutChar
			pla
			jsr	SmallPutChar

			plp				;Zahlen-Trenner ausgeben?
			bcc	:3			; => Nein, weiter...

			lda	r15H
			jsr	SmallPutChar		;Zahlen-Trenner.

::3			rts

;*** Erweiterung ausgeben.
:prntExt		jsr	testFileInfo		;Datei-Informationen verfügbar?
			bcs	:err			; => Nein, Abbruch...

			lda	UCI_DATA_MSG +8		;Dateierweiterung ausgeben.
			jsr	:prntChar

			lda	UCI_DATA_MSG +9
			jsr	:prntChar

			lda	UCI_DATA_MSG +10

::prntChar		cmp	#NULL
			beq	:none
			cmp	#$20
			bcc	:other
			cmp	#$7f
			bcc	:ok
::other			lda	#"."
			bne	:ok
::none			lda	#"?"
::ok			jsr	SmallPutChar

::err			rts

;*** Dateityp ausgeben.
:prntAttr		jsr	testFileInfo		;Datei-Informationen verfügbar?
			bcs	:err			; => Nein, Abbruch...

			ldx	#< :attrFile
			ldy	#> :attrFile		;Text: "Datei".
			lda	UCI_DATA_MSG +11
			and	#%00010000		;Verzeichnis?
			beq	:1			; => Nein, weiter...
			ldx	#< :attrDir
			ldy	#> :attrDir		;Text: "Verzeichnis".
::1			stx	r0L
			sty	r0H
			jsr	PutString		;Dateityp ausgeben.

::err			rts

::attrFile		b "Datei",NULL
::attrDir		b "Verzeichnis",NULL
