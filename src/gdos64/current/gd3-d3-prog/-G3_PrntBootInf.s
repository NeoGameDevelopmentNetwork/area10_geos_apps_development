; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Prozessortyp ausgeben.
:PrintBootInfo		php				;Register sichern.
			sei

			lda	CPU_DATA
			pha
			lda	#KRNL_BAS_IO_IN
			sta	CPU_DATA

			jsr	GetPAL_NTSC		;PAL/NTSC-Flag aktualisieren.

			lda	#0			;Bildschirm löschen und Titel
			sta	extclr			;ausgeben.
			sta	bakclr0

			lda	#15			;Zeichen-Farbe setzen.
			sta	COLOR

			jsr	CHOME			;Cursorposition setzen.

			lda	#< BootText00		;GDOS-Info.
			ldy	#> BootText00
			jsr	ROM_OUT_STRING

			lda	#< BootText00a		;Entwickler-Info.
			ldy	#> BootText00a
			jsr	ROM_OUT_STRING

			lda	#< CompText		;System-Info.
			ldy	#> CompText
			jsr	ROM_OUT_STRING

			jsr	:getComp

			lda	ComputerType
			asl
			tax
			lda	CompVecTab +0,x
			ldy	CompVecTab +1,x
			jsr	ROM_OUT_STRING

			lda	#< SystemText
			ldy	#> SystemText
			jsr	ROM_OUT_STRING

			lda	SystemType
			asl
			tax
			lda	SysVecTab +0,x
			ldy	SysVecTab +1,x
			jsr	ROM_OUT_STRING

			lda	#< ProcText
			ldy	#> ProcText
			jsr	ROM_OUT_STRING

			jsr	:getProc

			lda	ProcessorType
			asl
			tax
			lda	ProcVecTab +0,x
			ldy	ProcVecTab +1,x
			jsr	ROM_OUT_STRING

			pla
			sta	CPU_DATA
			plp
			rts

;*** Aktuellen Prozessor erkennen.
::getProc		sed
			lda	#$99
			clc
			adc	#$01
			cld
			bmi	:6510_8502		;6510,8502

			lda	#$01
			ldx	#$ff
			b $42
			inx
			cpx	#$00
			bne	:65816			;65816

			cmp	#$01
			bne	:65CE02			;65CE02

::65C02			lda	#3			;65C02
			b $2c
::65CE02		lda	#2			;65CE02
			b $2c
::65816			lda	#1			;65816
			b $2c
::6510_8502		lda	#0			;6510,8502
			sta	ProcessorType
			rts

;*** Aktiven Computer ermitteln.
::getComp		PushB	$d030

			ldy	#$00

			LoadB	$d030,$00		;Auf 1Mhz umschalten.
			lda	$d030			;Mhz-Register einlesen. 1Mhz aktiv ?
			and	#%00000001		; => Nein, C64...
			bne	:11
			iny
::11			sty	ComputerType		;Computertyp speichern.

			lda	PAL_NTSC		;PAL/NTSC-Register einlesen.
			and	#%00000001		;Flag isolieren und speichern.
			sta	SystemType

			PopB	$d030			;Register zurücksetzen.
			rts

;*** Variablen für Computertyp.
:ComputerType		b $00
:CompVecTab		w C64
			w C128

:CompText		b "COMPUTER  : ",NULL

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

if LANG = LANG_DE
:ProcText		b "AKTIVE CPU: ",NULL
endif

if LANG = LANG_EN
:ProcText		b "ACTIVE CPU: ",NULL
endif

:P6510			b "6510/8502",CR,CR,NULL
:P65816			b "65816",CR,CR,NULL
:P65CE02		b "65CE02",CR,CR,NULL
:P65C02			b "65C02",CR,CR,NULL
