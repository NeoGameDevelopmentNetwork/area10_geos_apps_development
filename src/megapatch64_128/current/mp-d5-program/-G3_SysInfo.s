; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Prozessortyp ausgeben.
:PrintBootInfo
if Flag64_128 = TRUE_C64
			jsr	GetPAL_NTSC		;PAL/NTSC-Flag aktualisieren.
endif
			lda	#$15
			sta	$d018
			lda	#$00			;Bildschirm löschen und Titel
			sta	$d020			;ausgeben.
			sta	$d021
			lda	#$0f
			sta	COLOR
			jsr	CLEAR
			jsr	Strg_Titel		;Installationsmeldung ausgeben.
			jsr	Strg_Autor		;Autoren ausgeben.

			lda	#< CompText
			ldy	#> CompText
			jsr	Strg_CurText

			jsr	GetComputer

			lda	ComputerType
			asl
			tax
			lda	CompVecTab +0,x
			ldy	CompVecTab +1,x
			jsr	Strg_CurText

			lda	#< SystemText
			ldy	#> SystemText
			jsr	Strg_CurText

			lda	SystemType
			asl
			tax
			lda	SysVecTab +0,x
			ldy	SysVecTab +1,x
			jsr	Strg_CurText

			lda	#< ProcText
			ldy	#> ProcText
			jsr	Strg_CurText

			jsr	GetProcessor

			lda	ProcessorType
			asl
			tax
			lda	ProcVecTab +0,x
			ldy	ProcVecTab +1,x
			jmp	Strg_CurText

;*** Aktuellen Prozessor erkennen.
:GetProcessor		sed
			lda	#$99
			clc
			adc	#$01
			cld
			bpl	:51
			LoadB	ProcessorType,0		;6510,8502
			rts

::51			lda	#$01
			ldx	#$ff
			b $42
			inx
			cpx	#$00
			beq	:52
			LoadB	ProcessorType,1		;65816
			rts

::52			cmp	#$01
			beq	:53
			LoadB	ProcessorType,2		;65CE02
			rts

::53			LoadB	ProcessorType,3		;65C02
			rts

;*** Aktiven Computer ermitteln.
:GetComputer		php				;Register sichern.
			sei
if Flag64_128 = TRUE_C64
			PushB	CPU_DATA		;Testen auf C128 im C64-Modus.
			LoadB	CPU_DATA,$35
			PushB	$d030			;CLKRATE für C128 1/2MHz.

			ldy	#$00

			LoadB	$d030,$00		;Testwert schreiben.
							;Immer $d030 an Stelle von CLKRATE
							;verwenden da CLKRATE nur in
							;SymbTab128 für C128 definiert.
			lda	$d030			;Mhz-Register einlesen. $00 ?
			and	#%00000001		; => Nein, C64...
			bne	:51
			iny
endif
if Flag64_128 = TRUE_C128
			ldy	#1			;Bei GEOS128 immer C128.
endif
::51			sty	ComputerType		;Computertyp speichern.

if Flag64_128 = TRUE_C64
			lda	PAL_NTSC		;PAL/NTSC-Register einlesen.
endif
if Flag64_128 = TRUE_C128
			ldy	PAL_NTSC		;PAL ($FF) oder NTSC ($00) ?
			bpl	:1
			ldy	#1
::1			tya
endif
			and	#%00000001		;Flag isolieren und speichern.
			sta	SystemType

if Flag64_128 = TRUE_C64
			PopB	$d030			;Register zurücksetzen.
			PopB	CPU_DATA
endif
			plp
			rts

;******************************************************************************
;*** PAL/NTSC-Erkennung
;******************************************************************************
if Flag64_128 = TRUE_C64
			t "-G3_GetPAL_NTSC"
endif
;******************************************************************************

;*** System-Information: Beispiel:
;GEOS-MEGAPATCH 64
;1998-2023 : MARKUS KANET
;BUILD     : ddmmzz.REV2
;
;COMPUTER  : C64
;SYSTEM    : PAL
;AKTIVE CPU: 6510/8502
;
;...BOOT-MELDUNGEN...
;
;
;*** Titelinformation.
if Flag64_128 = TRUE_C64
:BootText00		b "GEOS-MEGAPATCH 64",CR
endif
if Flag64_128 = TRUE_C128
:BootText00		b "GEOS-MEGAPATCH 128",CR
endif

;*** Kernal-Information.
			b "BUILD : "
			d "obj.BuildID"
			b CR,CR,NULL

;*** Titelinformation.
if Flag64_128 = TRUE_C64
:BootText00a		b "1998-2000: MARKUS KANET",CR
			b "2018-2023: MARKUS KANET",CR
			b CR,CR,NULL
endif
if Flag64_128 = TRUE_C128
:BootText00a		b "1998-2003: M.KANET/W.GRIMM",CR
			b "2018-2023: MARKUS KANET",CR
			b CR,CR,NULL
endif

;*** Variablen für Computertyp.
:ComputerType		b $00
:CompVecTab		w C64
			w C128

:CompText		b "COMPUTER  : ",NULL
:EmulatorText		b "EMULATOR  : ",NULL

:C64			b "C64",CR,NULL
:C128			b "C128",CR,NULL

;*** Variablen für Computertyp.
:SystemType		b $00
:SysVecTab		w NTSC
			w PAL

:SystemText		b "SYSTEM    : ",NULL

:NTSC			b "NTSC",CR,NULL
:PAL			b "PAL",CR,NULL

;*** Variablen für Prozessortyp.
:ProcessorType		b $00
:ProcVecTab		w P6510
			w P65816
			w P65CE02
			w P65C02

if Sprache = Deutsch
:ProcText		b "AKTIVE CPU: ",NULL
endif

if Sprache = Englisch
:ProcText		b "ACTIVE CPU: ",NULL
endif

:P6510			b "6510/8502",CR,CR,NULL
:P65816			b "65816",CR,CR,NULL
:P65CE02		b "65CE02",CR,CR,NULL
:P65C02			b "65C02",CR,CR,NULL
