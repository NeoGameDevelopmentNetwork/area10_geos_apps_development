; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_1"
			t "SymbTab_GDOS"
			t "SymbTab_GTYP"
			t "SymbTab_MMAP"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"
endif

;*** GEOS-Header.
			n "obj.NewPanicBox"
			f DATA

			o LOAD_PANIC

;*** PANIC!-Routine.
:xPanic			pla				;Abbruch-Adresse einlesen.
			tay
			pla
			tax

			sec				;Programm-Adresse
			tya				;berechnen.
			sbc	#$02
			tay
			bcs	:101
			dex

::101			txa				;HEX nach ASCII wandeln.
			ldx	#$00			;(High-Byte)
			jsr	ConvHexToASCII

			tya				;HEX nach ASCII wandeln.
			jsr	ConvHexToASCII		;(Low-Byte)

			lda	#> PanicBox
			sta	r0H
			lda	#< PanicBox
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
			and	#$0f
			jsr	ConvHexNibble
			inx
			rts

;*** Halb-Byte nach ASCII wandeln.
:ConvHexNibble		cmp	#$0a
			bcs	:101
			clc
			adc	#$30
			bne	:102
::101			clc
			adc	#$37
::102			sta	PanicAddress,x
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

if LANG = LANG_DE
			b "Absturz nahe $"
endif

if LANG = LANG_EN
			b "Break near $"
endif

;*** Speicher für HEX-Zahl bei
;    PANIC!-Routine.
:PanicAddress		b "xxxx",$00

if LANG = LANG_DE
:PanicText2		b "Das GEOS-System ist fehlerhaft",NULL
:PanicText3		b "oder die Anwendung ist defekt!",NULL
endif

if LANG = LANG_EN
:PanicText2		b "This GEOS-system is corrupt",NULL
:PanicText3		b "or the application is defect!",NULL
endif

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LOAD_PANIC + R2S_PANIC -1
;******************************************************************************
