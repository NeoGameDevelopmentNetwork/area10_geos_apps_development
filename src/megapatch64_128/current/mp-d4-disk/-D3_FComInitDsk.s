; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = FD_41!FD_71!FD_81!FD_NM!RL_41!RL_71!RL_81!RL_NM
::tmp0b = HD_41!HD_71!HD_81!HD_NM!HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp0 = :tmp0a!:tmp0b
if :tmp0 = TRUE
;******************************************************************************
;*** Diskette initialisieren.
:FCom_InitDisk		ldx	#> :com_InitDisk
			lda	#< :com_InitDisk
			ldy	#3
			jsr	SendComVLen		;Init-Befehl senden.
			bne	:1			;Fehler? => Ja, Abbruch...

			jsr	UNLSN			;Laufwerk abschalten.

			ldx	#NO_ERROR
::1			rts

::com_InitDisk		b "I0:"
endif
