; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = C_41
if :tmp0 = TRUE
;******************************************************************************
;*** TurboDOS aktivieren und neue Diskette öffnen.
:xNewDisk		bit	curType			;Shaow1541 ?
			bvc	:1			; => Nein, weiter...
			jsr	InitShadowRAM
::1			jmp	xLogNewDisk
endif

;******************************************************************************
::tmp1 = C_71!C_81!FD_41!FD_71!FD_81!FD_NM!PC_DOS!IEC_NM!S2I_NM
if :tmp1 = TRUE
;******************************************************************************
;*** TurboDOS aktivieren und neue Diskette öffnen.
:xNewDisk = xLogNewDisk
endif

;******************************************************************************
::tmp2a = HD_41!HD_71!HD_81!HD_NM!HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp2b = RL_41!RL_71!RL_81!RL_NM!RD_41!RD_71!RD_81!RD_NM
::tmp2c = RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp2  = :tmp2a!:tmp2b!:tmp2c
if :tmp2 = TRUE
;******************************************************************************
;*** TurboDOS aktivieren und neue Diskette öffnen.
:xNewDisk = xEnterTurbo
endif
