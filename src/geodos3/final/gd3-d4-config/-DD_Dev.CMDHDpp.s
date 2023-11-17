; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Auf CMD-HD-Kabel testen.
:TestHDcable		lda	DrvAdrGEOS
			jsr	SetDevice
			jsr	PurgeTurbo
			jsr	InitForIO

			lda	#<data1
			ldx	#>data1
			ldy	#32
			jsr	SendComVLen

;			LoadW	r0,data1
;			LoadB	r2L,32
;			jsr	SendCommand

			jsr	UNLSN

			lda	#<data2
			ldx	#>data2
			ldy	#23
			jsr	SendComVLen

;			LoadW	r0,data2
;			LoadB	r2L,23
;			jsr	SendCommand

			jsr	UNLSN

			lda	#<data3
			ldx	#>data3
			ldy	#5
			jsr	SendComVLen

;			LoadW	r0,data3
;			LoadB	r2L,5
;			jsr	SendCommand

			jsr	UNLSN

			jsr	EN_SET_REC

			ldx	#$98
			lda	$df41
			pha
			lda	$df42
			stx	$df43
			sta	$df42
			pla
			sta	$df41

			lda	#$00
			sta	r0L
			sta	r0H

			lda	$df40
			clc
			adc	#$10
			sta	:1 +4
			adc	#$10
			sta	:1 +4

::1			lda	$df40
			cmp	#$ff
			beq	:2

			inc	r0L
			bne	:1
			inc	r0H
			bne	:1
			beq	:9

::2			lda	$df40
			cmp	#$ff
			beq	:3

			inc	r0L
			bne	:2
			inc	r0H
			bne	:2
			beq	:9

::9			lda	#$ff
			b $2c
::3			lda	#NO_ERROR
			pha
			jsr	RL_HW_DIS2

			jsr	DoneWithIO
			pla
			tax
			rts

;--- Test-Routine Teil #1
:data1			b "M-W",$00,$03,$1b

			sei
			ldx	#$82
			lda	$8802
			stx	$8803
			sta	$8802
			lda	#$10
			sta	$8000
			ldx	#$00
			ldy	#$00
::1			iny
			bne	:1
			inx
			bne	:1

;--- Test-Routine Teil #2
:data2			b "M-W",$1b,$03,$11
			ldx	#$00
			lda	#$01
::1			sta	$8800
::2			inx
			bne	:2
			clc
			adc	#$01
			bne	:1
			cli
			rts

;--- Test-Routine starten
:data3			b "M-E",$00,$03
