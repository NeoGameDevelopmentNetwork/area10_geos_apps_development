; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Prozessortyp ausgeben.
:PrintBootInfo		jsr	GetPAL_NTSC		;PAL/NTSC-Flag aktualisieren.

			lda	#$15
			sta	grmemptr
			lda	#$00			;Bildschirm löschen und Titel
			sta	extclr			;ausgeben.
			sta	bakclr0
			lda	#$0f
			sta	COLOR
			jsr	CLEAR
			jsr	Strg_Titel		;Installationsmeldung ausgeben.
			jsr	Strg_Autor		;Autor ausgeben.

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

			lda	CPU_DATA
			pha
			lda	#IO_IN
			sta	CPU_DATA

			PushB	$d030

			ldy	#$00

			LoadB	$d030,$00		;Auf 1Mhz umschalten.
			lda	$d030			;Mhz-Register einlesen. 1Mhz aktiv ?
			and	#%00000001		; => Nein, C64...
			bne	:51
			iny
::51			sty	ComputerType		;Computertyp speichern.

			lda	PAL_NTSC		;PAL/NTSC-Register einlesen.
			and	#%00000001		;Flag isolieren und speichern.
			sta	SystemType

			PopB	$d030			;Register zurücksetzen.

			pla
			sta	CPU_DATA
			plp
			rts

;******************************************************************************
;*** PAL/NTSC-Erkennung
;******************************************************************************
			t "-G3_GetPAL_NTSC"
;******************************************************************************

;*** System-Information (Beispiel):
;         1         2         3         4
;1234567890123456789012345678901234567890
;GEODOS 64 - SPECIAL EDITION 3.0
;BUILD : V0.00r1-01.01.21:1800DEVU
;
;1995-1999 : MARKUS KANET
;2021      : MARKUS KANET
;
;
;COMPUTER  : C64
;SYSTEM    : PAL
;AKTIVE CPU: 6510/8502
;
;...BOOT-MELDUNGEN...
;
;
;*** Titel-Information.
:BootText00		b "GEODOS 64 - SPECIAL-EDITION 3.0",CR

;*** Kernal-Information.
			b "BUILD : "
			d "obj.BuildID"
			b CR,CR,NULL

;*** Autor-Information.
:BootText00a		b "1995-1999 : MARKUS KANET",CR
			b "2021      : MARKUS KANET",CR
			b CR,CR,NULL

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
