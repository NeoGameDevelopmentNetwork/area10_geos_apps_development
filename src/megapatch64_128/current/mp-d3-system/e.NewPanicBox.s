; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "obj.NewPanicBox"
			t "G3_SymMacExt"

if Flag64_128 = TRUE_C64
			t "G3_V.Cl.64.Data"
endif
if Flag64_128 = TRUE_C128
			t "G3_V.Cl.128.Data"
endif

			o LD_ADDR_PANIC

;*** PANIC!-Routine.
:xPanic

;--- Ergänzung: 30.12.22/M.Kanet
;Der C128 schreibt bei einem BRK acht
;zusätzliche Bytes auf den Stack.
;Wird die GEOS-Routine zum debugging
;verwendet (jsr Panic), dann müssen
;vorher acht Bytes zusätzlich auf den
;Stack abgelegt werden, damit die
;angezeigte Adresse stimmt.
;Damit wird das Verhalten wieder an
;GEOS128 angepasst.
if Flag64_128 = TRUE_C128
			pla
			pla
			pla
			pla
			pla
			pla
			pla
			pla
endif

			pla				;Abbruch-Adresse einlesen.
			tay
			pla
			tax

			sec				;Programm-Adresse
			tya				;berechnen.
			sbc	#$02
			tay
			bcs	:1
			dex

::1			txa				;HEX nach ASCII wandeln.
			ldx	#$00			;(High-Byte)
			jsr	ConvHexToASCII

			tya				;HEX nach ASCII wandeln.
			jsr	ConvHexToASCII		;(Low-Byte)

			lda	#>PanicBox
			sta	r0H
			lda	#<PanicBox
			sta	r0L
			jsr	DoDlgBox		;Panic-Box anzeigen.
			jmp	EnterDeskTop

;*** HEX-Zahl nach ASCII-Wandeln und in PANIC!-Text eintragen.
:ConvHexToASCII		pha
			lsr
			lsr
			lsr
			lsr
			jsr	ConvHexNibble
			inx
			pla
			and	#%00001111
			jsr	ConvHexNibble
			inx
			rts

;*** Halb-Byte nach ASCII wandeln.
:ConvHexNibble		cmp	#10
			bcs	:1
;			clc
			adc	#"0"
			bne	:2
::1			clc
			adc	#"A" -10
::2			sta	PanicAddress,x
			rts

;*** Dialogbox für PANIC!-Routine.
:PanicBox		b %11100001
			b DBTXTSTR ,$0c,$10
			w PanicText
			b DBTXTSTR ,$0c,$26
			w PanicText2
			b DBTXTSTR ,$0c,$30
			w PanicText3
			b OK       ,$11,$48
			b NULL

;*** Systemtext für PANIC!-Routine.
:PanicText		b PLAINTEXT,BOLDON

if Sprache = Deutsch
			b "Absturz nahe $"
endif

if Sprache = Englisch
			b "Break near $"
endif

;*** Speicher für HEX-Zahl bei
;    PANIC!-Routine.
:PanicAddress		b "xxxx",NULL

if Sprache = Deutsch
:PanicText2		b "Das GEOS-System ist fehlerhaft",NULL
:PanicText3		b "oder die Anwendung ist defekt!",NULL
endif

if Sprache = Englisch
:PanicText2		b "The GEOS system is corrupt",NULL
:PanicText3		b "or the application is defect!",NULL
endif

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_PANIC + R2_SIZE_PANIC -1
;******************************************************************************
