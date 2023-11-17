; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = RL_NM!RD_NM!FD_NM!PC_DOS!HD_NM!HD_NM_PP!IEC_NM!S2I_NM
::tmp0b = RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp0  = :tmp0a!:tmp0b
if :tmp0 = TRUE
;******************************************************************************
;*** Zeiger auf ersten Verzeichnis-Sektor.
:Set_1stDirSek		lda	curDirHead +0
			sta	r1L
			lda	curDirHead +1
			sta	r1H
			rts
endif

;******************************************************************************
::tmp1a = RL_81!RL_71!RL_41!RD_81!RD_71!RD_41
::tmp1b = C_41!C_71!C_81!FD_41!FD_71!FD_81!HD_41!HD_71!HD_81
::tmp1c = HD_41_PP!HD_71_PP!HD_81_PP
::tmp1  = :tmp1a!:tmp1b!:tmp1c
if :tmp1 = TRUE
;******************************************************************************
;*** Zeiger auf ersten Verzeichnis-Sektor.
:Set_1stDirSek		LoadB	r1L,Tr_1stDirSek
			LoadB	r1H,Se_1stDirSek
			rts
endif
