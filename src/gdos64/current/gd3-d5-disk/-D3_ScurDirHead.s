; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = RL_NM!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp0b = FD_NM!HD_NM!HD_NM_PP!IEC_NM!S2I_NM
::tmp0  = :tmp0a!:tmp0b
if :tmp0 = TRUE
;******************************************************************************
;*** Zeiger auf BAM/Verzeichnis-Header setzen.
:Set_DirHead		lda	DirHead_Tr
			sta	r1L
			lda	DirHead_Se
			sta	r1H

;*** Zeiger auf ":curDirHead" setzen.
:curDirHead_r4		lda	#< curDirHead
			sta	r4L
			lda	#> curDirHead
			sta	r4H

			rts
endif

;******************************************************************************
::tmp1a = C_41!C_71!C_81!RD_41!RD_71!RD_81!PC_DOS
::tmp1b = RL_41!RL_71!RL_81!FD_41!FD_71!FD_81
::tmp1c = HD_41!HD_71!HD_81!HD_41_PP!HD_71_PP!HD_81_PP
::tmp1d = RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp1e = FD_NM!HD_NM!HD_NM_PP!RL_NM!IEC_NM!S2I_NM
::tmp1  = :tmp1a!:tmp1b!:tmp1c!:tmp1d!:tmp1e
if :tmp1 = TRUE
;******************************************************************************
;*** Zeiger auf ":curDirHead" setzen.
:curDirHead_r5		lda	#< curDirHead
			sta	r5L
			lda	#> curDirHead
			sta	r5H

			rts
endif
