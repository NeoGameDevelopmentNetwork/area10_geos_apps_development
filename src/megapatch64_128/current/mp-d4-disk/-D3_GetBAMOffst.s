; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = C_81!FD_81!HD_81!HD_81_PP
if :tmp0 = TRUE
;******************************************************************************
;*** Offest auf BAM berechnen.
;    Übergabe:		r6L  = Track
;    Rückgabe:		xReg = Offset auf Byte.
;			AKKU = $00, dir2Head
;			       $FF, dir3Head
:GetBAM_Offset		lda	#$00
			sta	:53 +1

			lda	r6L
			cmp	#41
			bcc	:51
			sbc	#40
			dec	:53 +1
::51			sec
			sbc	#$01
			asl
			sta	:52 +1
			asl
			clc
::52			adc	#$ff
			tax
::53			lda	#$ff
			rts
endif
