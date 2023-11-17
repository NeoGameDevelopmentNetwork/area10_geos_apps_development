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
;*** Max. Anzahl Sektoren auf aktuellem track ermitteln.
:GetMaxSekOnTrack	ldx	#$00
::52			cmp	Tab_TrackChange,x
			bcc	:53
			inx
			bne	:52
::53			lda	Tab_MaxSekOnTr ,x
			rts

:Tab_TrackChange	b $12,$19,$1f,$24
:Tab_MaxSekOnTr		b $15,$13,$12,$11
endif

;******************************************************************************
::tmp1 = RL_71!RD_71!C_71!FD_71!HD_71!HD_71_PP
if :tmp1 = TRUE
;******************************************************************************
;*** Max. Anzahl Sektoren auf aktuellem track ermitteln.
:GetMaxSekOnTrack	cmp	#36
			bcc	:51
			sbc	#35
::51			ldx	#$00
::52			cmp	Tab_TrackChange,x
			bcc	:53
			inx
			bne	:52
::53			lda	Tab_MaxSekOnTr ,x
			rts

:Tab_TrackChange	b $12,$19,$1f,$24
:Tab_MaxSekOnTr		b $15,$13,$12,$11
endif
