; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Speichererweiterung erkannt.
;Übergabe: DACC_Vec = Zeiger auf Texttabelle ":DACC_RamVecTab".
:PrintActiveDACC	LoadW	r0,Strg_DetectDACC
			jsr	PutString

			ldy	DACC_Vec		;DACC-Typ ausgeben.
			lda	DACC_RamVecTab +0,y
			sta	r0L
			lda	DACC_RamVecTab +1,y
			sta	r0H
			jsr	PutString

			lda	#","
			jsr	SmallPutChar
			lda	#" "
			jsr	SmallPutChar

			lda	ExtRAM_Size		;DACC-Größe ausgeben.
			sta	r0L
			lda	#$00
			sta	r0H
			ldx	#r0L
			ldy	#$06
			jsr	DShiftLeft

			lda	#%11000000
			jsr	PutDecimal

			lda	#"K"
			jsr	SmallPutChar
			lda	#"b"
			jsr	SmallPutChar

			lda	#","
			jsr	SmallPutChar
			lda	#" "
			jsr	SmallPutChar

			lda	#"$"			;Startadresse des DACC-Speichers
			jsr	SmallPutChar		;in der Speichererweiterung
			lda	ExtRAM_Bank +1		;ausgeben.
			jsr	HEX2ASCII
			pha
			txa
			jsr	SmallPutChar
			pla
			jsr	SmallPutChar

			lda	#":"			;Bank-Adresse / Speicher trennen.
			jsr	SmallPutChar

			lda	ExtRAM_Bank +0		;High-Byte Speicheradresse.
			jsr	HEX2ASCII
			pha
			txa
			jsr	SmallPutChar
			pla
			jsr	SmallPutChar

;--- Ergänzung: 04.02.21/M.Kanet
;Low-Byte immer $00 -> Textausgabe.
;			lda	#$00			;Low-Byte Speicheradresse.
;			jsr	HEX2ASCII
;			pha
;			txa
			lda	#"0"
			jsr	SmallPutChar
;			pla
			lda	#"0"
			jsr	SmallPutChar

;--- Ergänzung: 07.02.21/M.Kanet
;Bei GeoRAM die Bank-Größe anzeigen.
			lda	ExtRAM_Type		;RAM-Typ einlesen.
			cmp	#RAM_BBG		;Typ GeoRAM?
			bne	:exit			; => Nein, Ende...

			lda	#"/"
			jsr	SmallPutChar
			lda	#"$"
			jsr	SmallPutChar

			lda	GRAM_BANK_SIZE		;Bank-Größe GeoRAM.
			jsr	HEX2ASCII
			pha
			txa
			jsr	SmallPutChar
			pla
			jsr	SmallPutChar

::exit			rts

;*** Bezeichnungen für Speichererweiterungen.
:DACC_RAMCard		b "CMD RAMCard",NULL
:DACC_RAMLink		b "CMD RAMLink",NULL
:DACC_REU		b "Commodore REU",NULL
:DACC_BBGRAM		b "GEORAM/BBGRAM",NULL

:DACC_Vec		b $00
:DACC_RamVecTab		w DACC_RAMCard
			w DACC_RAMLink
			w DACC_REU
			w DACC_BBGRAM

;*** Grafik für Titelbildanzeige.
:Strg_DetectDACC	b GOTOXY
			w $0010
			b $c0
			b PLAINTEXT,BOLDON

if LANG = LANG_DE
			b "(Aktuell verfügbarer GEOS/DACC-Speicher)"
endif

if LANG = LANG_EN
			b "(Currently available GEOS/DACC memory)"
endif
			b GOTOXY
			w $0010
			b $b4
;			b PLAINTEXT,BOLDON

if LANG = LANG_DE
			b "DACC-Speicher: ",NULL
endif

if LANG = LANG_EN
			b "DACC-Memory: ",NULL
endif
