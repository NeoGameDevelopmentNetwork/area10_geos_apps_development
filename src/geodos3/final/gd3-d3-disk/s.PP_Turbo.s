; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
;if .p
;			t "TopSym"
;			t "TopSym/G3"
;			t "TopMac/G3"
;endif

			n "obj.TurboPP"
;			t "G3_Sys.Author"
			f 3 ;DATA

			o $0300

.TD_ReadBlock		lda	#$00
			b $2c
.TD_ReadLink		lda	#$02
			pha
			jsr	TDR_GetSektor
			pla
			tay
			jsr	SEND_Bytes

.TD_GetError		lda	$24
			sta	$0700
			ldy	#$01

:SEND_Bytes		jsr	SetVecDataBuf

			jsr	l03b0
			jsr	CLOCK_IN_HIGH
:SEND_GetNxByte		dey
			lda	#$04
::1			bit	$8000
			beq	:1
			lda	($fc),y
			sta	$8800
			ldx	#$12
			stx	$8000
			lda	#$04
::2			bit	$8000
			bne	:2
			tya
			beq	:3
			dey
			lda	($fc),y
			sta	$8800
			ldx	#$10
			stx	$8000
			tya
			bne	SEND_GetNxByte

::3			ldx	#$10
			stx	$8000
			lda	#$04
::4			bit	$8000
			beq	:4

			ldx	#$12
			stx	$8000

			ldx	#$92
			b $2c
:l03b0			ldx	#$82
			lda	$8802
			stx	$8803
			sta	$8802
			rts

:GET_Bytes		ldy	#$00

:GET_NextByte		jsr	CLOCK_IN_HIGH

::1			lda	#$04
::2			bit	$8000
			beq	:2

			lda	$8800
			ldx	#$12
			stx	$8000
			dey
			sta	($fc),y
			beq	:5

			lda	#$04
::3			bit	$8000
			bne	:3

			lda	$8800
			ldx	#$10
			stx	$8000
			dey
			sta	($fc),y
			bne	:1

			lda	#$04
::4			bit	$8000
			beq	:4
			ldx	#$12
			stx	$8000
::5			rts

:CLOCK_IN_HIGH		lda	#$04
:l0444			bit	$8000
			bne	l0444
:l0449			lda	#$10
			sta	$8000
			rts

.TD_Start		sei
			ldx	#$02
			ldy	#$00
:l045b			dey
			bne	l045b
			dex
			bne	l045b

			lda	#$04
:l0463			bit	$8000
			beq	l0463

			ldx	#$12
			stx	$8000
			bne	l0476

:l046f			lda	#$04
			bit	$8000
			beq	l0481

:l0476			jsr	l04b2

			cli
			lda	#$04
:l047c			bit	$8000
			bne	l047c

:l0481			sei
			jsr	l04b9

			lda	#> USER_JOB
			sta	$fd
			lda	#< USER_JOB
			sta	$fc

			ldy	#$04
			jsr	GET_NextByte
			jsr	EXEC_USER_JOB
			jmp	l046f

.TD_MLoop_Stop		jsr	CLOCK_IN_HIGH
			pla
			pla
			cli
			rts

:EXEC_USER_JOB		b $4c
:USER_JOB		w $78e2
:USER_TRACK		b $00
:USER_SECTOR		b $00

:l04b2			lda	$8f00
			ora	#$41
			bne	l04be
:l04b9			lda	#$be
			and	$8f00
:l04be			sta	$8f00
			rts

.TD_WriteBlock		jsr	SetVecDataBuf
			jsr	GET_Bytes
			jsr	TDR_WrSekData
			jmp	TD_GetError

:TDR_WrSekData		lda	#$00
			sta	$01fa
			bit	$8f00
			bmi	TDR_PutSektor
			lda	#$08
			sta	$01fa
			sta	$24
			rts

:TDR_PutSektor		lda	#$90
			b $2c
:TDR_GetSektor		lda	#$80
			ldx	USER_TRACK
			stx	$2808
			ldx	USER_SECTOR
			stx	$2809
			ldx	#$04
			jmp	$ff4e

:SetVecDataBuf		lda	#> $0700
			sta	$fd
			lda	#< $0700
			sta	$fc
			rts
