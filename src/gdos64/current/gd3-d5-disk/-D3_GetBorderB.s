; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = C_41!C_71!C_81!FD_41!FD_71!FD_81
::tmp0b = RL_41!RL_71!RL_81!RD_41!RD_71!RD_81
::tmp0c = HD_41!HD_71!HD_81!HD_41_PP!HD_71_PP!HD_81_PP
::tmp0  = :tmp0a!:tmp0b!:tmp0c
if :tmp0 = TRUE
;******************************************************************************
;*** BorderBlock einlesen.
;    Übergabe:		-
;    Rückgabe:		r1	= Track/Sektor für Borderblock.
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xGetBorderBlock	jsr	xGetDirHead		;Aktuelle BAM einlesen.
			txa				;Diskettenfehler?
			bne	:err			; => Ja, Abbruch...

			jsr	ChkDkGEOS_r5		;Auf GEOS-Diskette testen.
;			tax				;":isGEOS" = $00 ?
			beq	:EOD			; => Ja, Keine GEOS-Diskette.

			lda	curDirHead +171		;Zeiger auf BorderBlock einlesen.
			sta	r1L
			lda	curDirHead +172
			sta	r1H

			ldy	#$00
			b $2c
::EOD			ldy	#$ff
			ldx	#NO_ERROR
::err			rts
endif

;******************************************************************************
::tmp1a = FD_NM!HD_NM!HD_NM_PP
::tmp1b = RL_NM!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp1c = IEC_NM!S2I_NM
::tmp1  = :tmp1a!:tmp1b!:tmp1c
if :tmp1 = TRUE
;******************************************************************************
;*** BorderBlock einlesen.
;    Übergabe:		-
;    Rückgabe:		r1	= Track/Sektor für Borderblock.
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xGetBorderBlock	jsr	ChkRootGEOS		;Auf GEOS-Diskette testen.

			jsr	xGetDirHead		;Aktuelle BAM einlesen.
			cpx	#NO_ERROR		;Diskettenfehler?
			bne	:err			; => Ja, Abbruch...

			bit	isGEOS			;Borderblock vorhanden?
			bpl	:EOD			; => Nein, keine GEOS-Diskette.

			sta	r1L			;Zeiger auf Borderblock
			sty	r1H			;nach ":r1" übernehmen.

			ldy	#$00			;Weitere Dateien...
			b $2c
::EOD			ldy	#$ff			;Verzeichnisende erreicht.
			ldx	#NO_ERROR
::err			rts
endif
