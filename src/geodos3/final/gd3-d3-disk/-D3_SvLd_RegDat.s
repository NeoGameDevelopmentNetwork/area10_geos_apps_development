; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = C_81!FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM!IEC_NM!S2I_NM
::tmp0b = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp0c = RL_NM!RL_81!RL_71!RL_41!RD_NM!RD_81!RD_71!RD_41
::tmp0d = RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp0  = :tmp0a!:tmp0b!:tmp0c!:tmp0d
if :tmp0 = TRUE
;******************************************************************************
;*** ZeroPage-Register ":r0" bis ":r5" zwischenspeichern.
:Save_RegData		pha
			txa
			pha

			ldx	#$0b
::51			lda	r0L      ,x
			sta	zPage_Buf,x
			dex
			bpl	:51

			pla
			tax
			pla
			rts

;*** ZeroPage-Register ":r0" bis ":r5" zurücksetzen.
:Load_RegData		pha
			txa
			pha

			ldx	#$0b
::51			lda	zPage_Buf,x
			sta	r0L      ,x
			dex
			bpl	:51

			pla
			tax
			pla
			rts

:zPage_Buf		s 12
endif
