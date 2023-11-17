; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = C_41!C_71!C_81
::tmp0b = FD_41!FD_71!FD_81!FD_NM!PC_DOS!HD_41!HD_71!HD_81!HD_NM!IEC_NM!S2I_NM
::tmp0c = RL_41!RL_71!RL_81!RL_NM!RD_41!RD_71!RD_81!RD_NM
::tmp0d = RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp0e = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp0  = :tmp0a!:tmp0b!:tmp0c!:tmp0d!:tmp0e
if :tmp0 = TRUE
;******************************************************************************
;*** Zeiger auf ":curDirHead" setzen.
:Set_curDirHead		LoadW	r5,curDirHead
			rts
endif
