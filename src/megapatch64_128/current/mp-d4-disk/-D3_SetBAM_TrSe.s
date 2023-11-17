; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = RL_41!RD_41!C_41!FD_41!HD_41!HD_41_PP
if :tmp0 = TRUE
;******************************************************************************
;*** Zeiger auf BAM-Sektoren setzen.
:SetBAM_TrSe		lda	#< curDirHead
			sta	r4L
			lda	#> curDirHead
			sta	r4H
			lda	#$12
			sta	r1L
			lda	#$00
			sta	r1H
			rts
endif

;******************************************************************************
::tmp1 = RL_71!RD_71!C_71!FD_71!HD_71!HD_71_PP
if :tmp1 = TRUE
;******************************************************************************
;*** Zeiger auf BAM-Sektoren setzen.
:SetBAM_TrSe1		ldx	#> curDirHead
			lda	#18
			bne	SetBAM_TrSe

:SetBAM_TrSe2		ldx	#> dir2Head
			lda	#53
:SetBAM_TrSe		ldy	#0
			sty	r4L
			stx	r4H			;Puffer-Adresse definieren.
			sta	r1L			;Track/Sektor definieren.
			sty	r1H
			rts
endif

;******************************************************************************
::tmp2 = RL_81!RD_81!C_81!FD_81!HD_81!HD_81_PP
if :tmp2 = TRUE
;******************************************************************************
;*** Zeiger auf BAM-Sektoren setzen.
:SetBAM_TrSe1		ldx	#> curDirHead
			ldy	#< curDirHead
			lda	#$00
			beq	SetBAM_TrSe

:SetBAM_TrSe2		ldx	#> dir2Head
			ldy	#< dir2Head
			lda	#$01
			bne	SetBAM_TrSe

:SetBAM_TrSe3		ldx	#> dir3Head
			ldy	#< dir3Head
			lda	#$02
:SetBAM_TrSe		stx	r4H			;Puffer-Adresse definieren.
			sty	r4L
			sta	r1H			;Track/Sektor definieren.
			lda	#$28
			sta	r1L
			rts
endif
