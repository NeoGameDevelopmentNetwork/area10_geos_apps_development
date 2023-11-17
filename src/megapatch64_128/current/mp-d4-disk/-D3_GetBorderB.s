; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = C_41!C_71!C_81!FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM
::tmp0b = RL_41!RL_71!RL_81!RL_NM!RD_41!RD_71!RD_81!RD_NM
::tmp0c = RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp0d = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP!IEC_NM!S2I_NM
::tmp0  = :tmp0a!:tmp0b!:tmp0c!:tmp0d
if :tmp0 = TRUE
;******************************************************************************
;*** BorderBlock einlesen.
;    Übergabe:		-
;    Rückgabe:		r1	= Track/Sektor für Borderblock.
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xGetBorderBlock	jsr	xGetDirHead		;Aktuelle BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:52			;Ja, Abbruch...

			jsr	ChkDkGEOS_r5		;Auf GEOS-Diskette testen.
;			cmp	#$00			;":isGEOS" = $00 ?
			beq	:51			; => Ja, Keine GEOS-Diskette.

			lda	curDirHead +171		;Zeiger auf BorderBlock einlesen.
			sta	r1L
			lda	curDirHead +172
			sta	r1H

			ldy	#$00
			b $2c
::51			ldy	#$ff
			ldx	#NO_ERROR
::52			rts
endif
