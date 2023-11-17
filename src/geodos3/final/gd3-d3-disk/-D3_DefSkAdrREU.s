; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = RL_81
if :tmp0 = TRUE
;******************************************************************************
;*** Sektor-Adresse in REU berechnen.
;    Hinweis: YReg darf nicht verändert werden,
;    siehe Routine "-D3_DoSekOp".
:DefSekAdrREU		ldx	r1L
			dex
			lda	SekAdrRAM_L   ,x
			clc
			adc	r1H
			sta	r0L
			lda	SekAdrRAM_H   ,x
			adc	#$00
			sta	r0H

			ldx	RL_PartNr
			lda	#$00
			sta	r1L
			lda	r0L
			clc
			adc	RL_PartADDR_L ,x
			sta	r1H
			lda	r0H
			adc	RL_PartADDR_H ,x
			sta	r3L
			rts

;*** Max. Anzahl Sektoren/Track.
:SekAdrRAM_L		b $00,$28,$50,$78,$a0,$c8,$f0,$18
			b $40,$68,$90,$b8,$e0,$08,$30,$58
			b $80,$a8,$d0,$f8,$20,$48,$70,$98
			b $c0,$e8,$10,$38,$60,$88,$b0,$d8
			b $00,$28,$50,$78,$a0,$c8,$f0,$18
			b $40,$68,$90,$b8,$e0,$08,$30,$58
			b $80,$a8,$d0,$f8,$20,$48,$70,$98
			b $c0,$e8,$10,$38,$60,$88,$b0,$d8
			b $00,$28,$50,$78,$a0,$c8,$f0,$18
			b $40,$68,$90,$b8,$e0,$08,$30,$58
:SekAdrRAM_H		b $00,$00,$00,$00,$00,$00,$00,$01
			b $01,$01,$01,$01,$01,$02,$02,$02
			b $02,$02,$02,$02,$03,$03,$03,$03
			b $03,$03,$04,$04,$04,$04,$04,$04
			b $05,$05,$05,$05,$05,$05,$05,$06
			b $06,$06,$06,$06,$06,$07,$07,$07
			b $07,$07,$07,$07,$08,$08,$08,$08
			b $08,$08,$09,$09,$09,$09,$09,$09
			b $0a,$0a,$0a,$0a,$0a,$0a,$0a,$0b
			b $0b,$0b,$0b,$0b,$0b,$0c,$0c,$0c
endif

;******************************************************************************
::tmp1 = RD_81
if :tmp1 = TRUE
;******************************************************************************
;*** Sektor-Adresse in REU berechnen.
;    Hinweis: YReg darf nicht verändert werden,
;    siehe Routine "-D3_DoSekOp".
:DefSekAdrREU		ldx	r1L
			dex
			lda	SekAdrRAM_L,x
			clc
			adc	r1H
			sta	r0L
			lda	SekAdrRAM_H,x
			adc	#$00
			sta	r0H

			lda	#$00
			sta	r1L
			lda	r0L
			clc
			adc	#$00
			sta	r1H
			lda	r0H
			ldx	curDrive
			adc	ramBase     -8,x
			sta	r3L
			rts

;*** Max. Anzahl Sektoren/Track.
:SekAdrRAM_L		b $00,$28,$50,$78,$a0,$c8,$f0,$18
			b $40,$68,$90,$b8,$e0,$08,$30,$58
			b $80,$a8,$d0,$f8,$20,$48,$70,$98
			b $c0,$e8,$10,$38,$60,$88,$b0,$d8
			b $00,$28,$50,$78,$a0,$c8,$f0,$18
			b $40,$68,$90,$b8,$e0,$08,$30,$58
			b $80,$a8,$d0,$f8,$20,$48,$70,$98
			b $c0,$e8,$10,$38,$60,$88,$b0,$d8
			b $00,$28,$50,$78,$a0,$c8,$f0,$18
			b $40,$68,$90,$b8,$e0,$08,$30,$58
:SekAdrRAM_H		b $00,$00,$00,$00,$00,$00,$00,$01
			b $01,$01,$01,$01,$01,$02,$02,$02
			b $02,$02,$02,$02,$03,$03,$03,$03
			b $03,$03,$04,$04,$04,$04,$04,$04
			b $05,$05,$05,$05,$05,$05,$05,$06
			b $06,$06,$06,$06,$06,$07,$07,$07
			b $07,$07,$07,$07,$08,$08,$08,$08
			b $08,$08,$09,$09,$09,$09,$09,$09
			b $0a,$0a,$0a,$0a,$0a,$0a,$0a,$0b
			b $0b,$0b,$0b,$0b,$0b,$0c,$0c,$0c
endif

;******************************************************************************
::tmp2 = RL_71
if :tmp2 = TRUE
;******************************************************************************
;*** Sektor-Adresse in REU berechnen.
;    Hinweis: YReg darf nicht verändert werden,
;    siehe Routine "-D3_DoSekOp".
:DefSekAdrREU		lda	r1L
			cmp	#36
			bcc	:51
			sbc	#35
::51			tax
			dex
			lda	SekAdrRAM_L,x
			clc
			adc	r1H
			sta	r0L
			lda	SekAdrRAM_H,x
			adc	#$00
			sta	r0H
			lda	r1L
			cmp	#36
			bcc	:52
			AddVW	683,r0			;Seite #2 addieren. Achtung! Der
;			AddVW	700,r0			;Wert 683 ist für die RL notwendig!

::52			ldx	RL_PartNr
			lda	#$00
			sta	r1L
			lda	r0L
			clc
			adc	RL_PartADDR_L ,x
			sta	r1H
			lda	r0H
			adc	RL_PartADDR_H ,x
			sta	r3L
			rts

;*** Max. Anzahl Sektoren/Track.
:SekAdrRAM_L		b $00,$15,$2a,$3f,$54,$69,$7e,$93
			b $a8,$bd,$d2,$e7,$fc,$11,$26,$3b
			b $50,$65,$78,$8b,$9e,$b1,$c4,$d7
			b $ea,$fc,$0e,$20,$32,$44,$56,$67
			b $78,$89,$9a,$ab
:SekAdrRAM_H		b $00,$00,$00,$00,$00,$00,$00,$00
			b $00,$00,$00,$00,$00,$01,$01,$01
			b $01,$01,$01,$01,$01,$01,$01,$01
			b $01,$01,$02,$02,$02,$02,$02,$02
			b $02,$02,$02,$02
endif

;******************************************************************************
::tmp3 = RD_71
if :tmp3 = TRUE
;******************************************************************************
;*** Sektor-Adresse in REU berechnen.
;    Hinweis: YReg darf nicht verändert werden,
;    siehe Routine "-D3_DoSekOp".
:DefSekAdrREU		lda	r1L
			cmp	#36
			bcc	:51
			sbc	#35
::51			tax
			dex
			lda	SekAdrRAM_L,x
			clc
			adc	r1H
			sta	r0L
			lda	SekAdrRAM_H,x
			adc	#$00
			sta	r0H
			lda	r1L
			cmp	#36
			bcc	:52
;			AddVW	683,r0			;Seite #2 addieren. Achtung! Der
			AddVW	700,r0			;Wert 683 wäre ideal, Wert 700 aber
							;wegen GEOSV2 beibehalten!

::52			lda	#$00
			sta	r1L
			lda	r0L
			clc
			adc	#$00
			sta	r1H
			lda	r0H
			ldx	curDrive
			adc	ramBase     -8,x
			sta	r3L
			rts

;*** Max. Anzahl Sektoren/Track.
:SekAdrRAM_L		b $00,$15,$2a,$3f,$54,$69,$7e,$93
			b $a8,$bd,$d2,$e7,$fc,$11,$26,$3b
			b $50,$65,$78,$8b,$9e,$b1,$c4,$d7
			b $ea,$fc,$0e,$20,$32,$44,$56,$67
			b $78,$89,$9a,$ab
:SekAdrRAM_H		b $00,$00,$00,$00,$00,$00,$00,$00
			b $00,$00,$00,$00,$00,$01,$01,$01
			b $01,$01,$01,$01,$01,$01,$01,$01
			b $01,$01,$02,$02,$02,$02,$02,$02
			b $02,$02,$02,$02
endif

;******************************************************************************
::tmp4 = RL_41
if :tmp4 = TRUE
;******************************************************************************
;*** Sektor-Adresse in REU berechnen.
;    Hinweis: YReg darf nicht verändert werden,
;    siehe Routine "-D3_DoSekOp".
:DefSekAdrREU		ldx	r1L
			dex
			lda	SekAdrRAM_L,x
			clc
			adc	r1H
			sta	r0L
			lda	SekAdrRAM_H,x
			adc	#$00
			sta	r0H

			ldx	RL_PartNr
			lda	#$00
			sta	r1L
			lda	r0L
			clc
			adc	RL_PartADDR_L ,x
			sta	r1H
			lda	r0H
			adc	RL_PartADDR_H ,x
			sta	r3L
			rts

;*** Max. Anzahl Sektoren/Track.
:SekAdrRAM_L		b $00,$15,$2a,$3f,$54,$69,$7e,$93
			b $a8,$bd,$d2,$e7,$fc,$11,$26,$3b
			b $50,$65,$78,$8b,$9e,$b1,$c4,$d7
			b $ea,$fc,$0e,$20,$32,$44,$56,$67
			b $78,$89,$9a,$ab
:SekAdrRAM_H		b $00,$00,$00,$00,$00,$00,$00,$00
			b $00,$00,$00,$00,$00,$01,$01,$01
			b $01,$01,$01,$01,$01,$01,$01,$01
			b $01,$01,$02,$02,$02,$02,$02,$02
			b $02,$02,$02,$02
endif

;******************************************************************************
::tmp5 = RD_41!C_41
if :tmp5 = TRUE
;******************************************************************************
;*** Sektor-Adresse in REU berechnen.
;    Hinweis: YReg darf nicht verändert werden,
;    siehe Routine "-D3_DoSekOp".
:DefSekAdrREU		ldx	r1L
			dex
			lda	SekAdrRAM_L,x
			clc
			adc	r1H
			sta	r0L
			lda	SekAdrRAM_H,x
			adc	#$00
			sta	r0H

			lda	#$00
			sta	r1L
			lda	r0L
			clc
			adc	#$00
			sta	r1H
			lda	r0H
			ldx	curDrive
			adc	ramBase     -8,x
			sta	r3L
			rts

;*** Max. Anzahl Sektoren/Track.
:SekAdrRAM_L		b $00,$15,$2a,$3f,$54,$69,$7e,$93
			b $a8,$bd,$d2,$e7,$fc,$11,$26,$3b
			b $50,$65,$78,$8b,$9e,$b1,$c4,$d7
			b $ea,$fc,$0e,$20,$32,$44,$56,$67
			b $78,$89,$9a,$ab
:SekAdrRAM_H		b $00,$00,$00,$00,$00,$00,$00,$00
			b $00,$00,$00,$00,$00,$01,$01,$01
			b $01,$01,$01,$01,$01,$01,$01,$01
			b $01,$01,$02,$02,$02,$02,$02,$02
			b $02,$02,$02,$02
endif

;******************************************************************************
::tmp6 = RL_NM
if :tmp6 = TRUE
;******************************************************************************
;*** Sektor-Adresse in REU berechnen.
;    Hinweis: YReg darf nicht verändert werden,
;    siehe Routine "-D3_DoSekOp".
:DefSekAdrREU		dec	r1L
			ldx	RL_PartNr
			lda	r1H
			clc
			adc	RL_PartADDR_L ,x
			sta	r1H
			lda	r1L
			adc	RL_PartADDR_H ,x
			sta	r3L
			lda	#$00
			sta	r1L
			rts
endif

;******************************************************************************
::tmp7 = RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
if :tmp7 = TRUE
;******************************************************************************
;*** Sektor-Adresse in REU berechnen.
;    Hinweis: YReg darf nicht verändert werden,
;    siehe Routine "-D3_DoSekOp".
:DefSekAdrREU		dec	r1L
			ldx	curDrive
			clc
			lda	r1L
			adc	ramBase -8,x
			sta	r3L
			lda	#$00
			sta	r1L
			rts
endif
