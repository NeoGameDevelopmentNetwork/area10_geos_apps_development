; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = RL_81!RD_81!C_81!FD_81!HD_81!HD_81_PP!HD_NM_PP
if :tmp0 = TRUE
;******************************************************************************
;*** ":dir3Head" in REU zwischenspeichern.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,yReg,r0,r1,r2,r3L
:Save_dir3Head		ldy	#%10010000
			b $2c
:Load_dir3Head		ldy	#%10010001
			txa
			pha
			tya
			pha
			lda	#< dir3Head
			sta	r0L
			lda	#> dir3Head
			sta	r0H
			ldx	curDrive		;BAM-Sektor #3 in ":dir3Head" in
			lda	DskDrvBaseL -8,x	;REU zwischenspeichern.
			clc
			adc	#< $0c80
			sta	r1L
			lda	DskDrvBaseH -8,x
			adc	#> $0c80
			sta	r1H
			ldy	#$00
			sty	r3L
			sty	r2L
			iny
			sty	r2H
			pla
			tay
			jsr	DoRAMOp
			pla
			tax
			rts
endif
