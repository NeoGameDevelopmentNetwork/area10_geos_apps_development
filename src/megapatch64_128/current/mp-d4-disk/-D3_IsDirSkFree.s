; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = C_41!C_71!FD_41!FD_71!HD_41!HD_41_PP!HD_71!HD_71_PP
::tmp0b = RL_41!RL_71!RD_41!RD_71
::tmp0  = :tmp0a!:tmp0b
if :tmp0 = TRUE
;******************************************************************************
;*** Ist Verzeichnis-Sektor frei ?
:IsDirSekFree		ldx	#FULL_DIRECTORY		;Vorbereiten: "Verzeichnis voll".
			lda	curDirHead +$48		;Freie Verzeichnis-Sektoren testen.
			beq	:51
			ldx	#NO_ERROR
::51			rts
endif

;******************************************************************************
::tmp1 = C_81!FD_81!HD_81!HD_81_PP!RL_81!RD_81
if :tmp1 = TRUE
;******************************************************************************
;*** Ist Verzeichnis-Sektor frei ?
:IsDirSekFree		ldx	#FULL_DIRECTORY		;Vorbereiten: "Verzeichnis voll".
			lda	dir2Head +$fa		;Freie Verzeichnis-Sektoren testen.
			beq	:51
			ldx	#NO_ERROR
::51			rts
endif
