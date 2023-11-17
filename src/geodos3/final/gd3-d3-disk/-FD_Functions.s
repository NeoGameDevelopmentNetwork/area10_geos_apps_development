; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = C_41!C_71!C_81
::tmp0b = FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM!IEC_NM!S2I_NM
::tmp0 = :tmp0a!:tmp0b
if :tmp0!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** Track/Sektor in Befehl übertragen.
:setTrSeAdr		lda	r1L
			jsr	Byte2DEZ
			sty	FComAdrTr +0
			stx	FComAdrTr +1
			sta	FComAdrTr +2

			lda	r1H
			jsr	Byte2DEZ
			sty	FComAdrSe +0
			stx	FComAdrSe +1
			sta	FComAdrSe +2

			rts

;*** Byte nach Dezimal wandeln.
:Byte2DEZ		ldy	#"0"
			ldx	#"0"
::1			cmp	#100
			bcc	:2
;			sec
			sbc	#100
			iny
			bne	:1
::2			cmp	#10
			bcc	:3
;			sec
			sbc	#10
			inx
			bne	:2
::3			;clc
			adc	#"0"
			rts
endif
