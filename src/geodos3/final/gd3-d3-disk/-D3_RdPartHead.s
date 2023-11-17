; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = FD_NM!HD_NM
if :tmp0 = TRUE
;******************************************************************************
;*** Diskette aktivieren.
:xReadPartHeader	ldx	#$01
			stx	r1L
			inx
			stx	r1H
			LoadW	r4 ,dir3Head
			jmp	xReadBlock
endif

;******************************************************************************
::tmp1 = RL_NM
if :tmp1 = TRUE
;******************************************************************************
;*** Diskette aktivieren.
:xReadPartHeader	ldx	#$01
			stx	r1L
			inx
			stx	r1H
			LoadW	r4 ,dir3Head		;Sonst Probleme beim erkennen der
			lda	RL_PartNr		;Partitionsgröße!
			sta	r3H
			jmp	xDsk_SekRead
endif

;******************************************************************************
::tmp2 = RD_NM
if :tmp2 = TRUE
;******************************************************************************
;*** Diskette aktivieren.
:xReadPartHeader	ldx	#$01
			stx	r1L
			inx
			stx	r1H
			LoadW	r4 ,dir3Head		;Sonst Probleme beim erkennen der
			jmp	xDsk_SekRead		;Partitionsgröße!
endif
