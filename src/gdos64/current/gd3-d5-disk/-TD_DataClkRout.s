; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = C_41!C_71!C_81!PC_DOS!IEC_NM!S2I_NM
::tmp0b = FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM
::tmp0  = :tmp0a!:tmp0b
if :tmp0!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS aktivieren.
:waitDataIn_HIGH	lda	d2L
			sta	$dd00
::51			bit	$dd00
			bpl	:51
			rts

;*** TurboDOS beenden.
:waitDataIn_LOW		jsr	setClkOut_HIGH
::51			bit	$dd00
			bmi	:51
			rts

;*** CLOCK_OUT-Leitung auf LOW setzen.
:setClkOut_HIGH		ldx	DD00_RegBuf
			stx	$dd00
			rts
endif

;******************************************************************************
::tmp1 = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
if :tmp1!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS aktivieren.
:waitDataIn_HIGH	lda	d2L
			sta	$dd00
::51			bit	$dd00
			bpl	:51
			rts

;*** TurboDOS beenden.
:waitDataIn_LOW		ldx	d2H
			stx	$dd00
::51			bit	$dd00
			bmi	:51
			rts
endif
