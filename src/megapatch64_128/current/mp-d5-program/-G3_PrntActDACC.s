; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Speichererweiterung erkannt.
:PrintActiveDACC	tya				;Verwendete Speichererweiterung
			pha				;ausgeben.

if Flag64_128 = TRUE_C128
			bit	graphMode		;40Z-Modus aktiv?
			bpl	:51			; => Ja, weiter...

			LoadW	r3,0
			LoadW	r4,639
			LoadB	r2L,168
			LoadB	r2H,199
			lda	#$f2
			jsr	ColorRectangle		;GEOS 2.0 DirectColor-Routine !
endif

::51			jsr	i_FillRam
			w	40 * 4
			w	COLOR_MATRIX +40 * 21
			b	$16

			LoadW	r0,Strg_DetectRAM
			jsr	GraphicsString

			pla				;RAM-Typ ausgeben.
			tay
			lda	Name_RamVecTab +0,y
			sta	r0L
			lda	Name_RamVecTab +1,y
			sta	r0H
			jsr	PutString

			lda	#","
			jsr	PutChar
			lda	#" "
			jsr	PutChar

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
			jsr	PutChar
			lda	#"b"
			jsr	PutChar

			lda	#","
			jsr	PutChar
			lda	#" "
			jsr	PutChar

			lda	#"$"			;Startadresse des DACC-Speichers
			jsr	PutChar			;in der Speichererweiterung
			lda	ExtRAM_Bank +1		;ausgeben.
			jsr	HEX2ASCII
			lda	#":"
			jsr	PutChar
			lda	ExtRAM_Bank +0
			jsr	HEX2ASCII
			lda	#$00
			jsr	HEX2ASCII

			lda	ExtRAM_Type
			cmp	#RAM_BBG
			bne	:52

			lda	#"/"
			jsr	PutChar
			lda	#"$"
			jsr	PutChar
			lda	GRAM_BANK_SIZE
			jsr	HEX2ASCII

::52			rts

;*** HEX-Zahl nach ASCII wandeln.
:HEX2ASCII		pha
			lsr
			lsr
			lsr
			lsr
			jsr	:51
			tax
			pla
			jsr	:51
			pha
			txa
			jsr	PutChar
			pla
			jmp	PutChar

::51			and	#%00001111
			clc
			adc	#$30
			cmp	#$3a
			bcc	:52
			clc
			adc	#$07
::52			rts

;*** Grafik für Titelbildanzeige.
:ScreenInitData		b NEWPATTERN,$01
			b MOVEPENTO
			w $013f ! DOUBLE_W ! ADD1_W
			b $c7
			b RECTANGLETO
			w $0000 ! DOUBLE_W
			b $00
			b NEWPATTERN,$00
			b RECTANGLETO
			w $013f ! DOUBLE_W ! ADD1_W
			b $0f
			b ESC_PUTSTRING
			w $0010 ! DOUBLE_W
			b $0b
			b PLAINTEXT,BOLDON

if Flag64_128!Sprache = TRUE_C64!Deutsch
			b "MegaPatch64 wird konfiguriert, bitte warten...",NULL
endif

if Flag64_128!Sprache = TRUE_C128!Deutsch
			b "MegaPatch128 wird konfiguriert, bitte warten...",NULL
endif

if Flag64_128!Sprache = TRUE_C64!Englisch
			b "MegaPatch64 will be configured, please wait...",NULL
endif

if Flag64_128!Sprache = TRUE_C128!Englisch
			b "MegaPatch128 will be configured, please wait...",NULL
endif

;*** Bezeichnungen für Speichererweiterungen.
:Name_RAMCard		b "CMD RAMCard",NULL
:Name_RAMLink		b "CMD RAMLink",NULL
:Name_REU		b "Commodore REU",NULL
:Name_BBGRAM		b "GEORAM",NULL

:Name_RamVecTab		w Name_RAMCard
			w Name_RAMLink
			w Name_REU
			w Name_BBGRAM

;*** Grafik für Titelbildanzeige.
:Strg_DetectRAM		b NEWPATTERN,$00
			b MOVEPENTO
			w $0000 ! DOUBLE_W
			b $a8
			b RECTANGLETO
			w $013f ! DOUBLE_W ! ADD1_W
			b $c7
			b ESC_PUTSTRING
			w $0010 ! DOUBLE_W
			b $c0
			b PLAINTEXT,BOLDON

if Sprache = Deutsch
			b "(Aktuell verfügbarer GEOS-DACC-Speicher)"
endif

if Sprache = Englisch
			b "(Currently available GEOS-DACC-memory)"
endif

			b GOTOXY
			w $0010 ! DOUBLE_W
			b $b4
			b PLAINTEXT,BOLDON

if Sprache = Deutsch
			b "DACC-Speicher: ",NULL
endif

if Sprache = Englisch
			b "DACC-Memory: ",NULL
endif
