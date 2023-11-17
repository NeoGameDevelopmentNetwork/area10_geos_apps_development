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
;*** Auf GEOS-Diskette testen.
;    Übergabe:		r5	= Zeiger auf BAM (":curDirHead").
;    Rückgabe:		AKKU	= $00, Keine GEOS-Diskette.
;    Geändert:		AKKU,xReg,yReg
:xChkDkGEOS		ldy	#$0b
::1			lda	curDirHead +$ad,y
			cmp	FormatText     ,y
			bne	:2
			dey
			bpl	:1
			b $2c
;--- Änderung: 01.07.18/M.Kanet
;Die ursprüngliche Routine übergab den Status-Code für :isGEOS im AKKU-Register
;und wurde ggf. über den BIT/b $2c-Befehl übersprungen. Der BIT-Befehl kann
;jedoch das Z-Flag beeinflussen, so das eine GEOS-Diskette in seltenen Fällen
;als eine "Nicht GEOS"-Diskette erkannt werden konnte.
;Siehe auch Routine "GetBorderBlock".
::2			ldy	#$00
			tya
			sta	isGEOS
			rts

;*** Format-Info für GEOS-Diskette.
:FormatText		b "GEOS format V1.0"
endif
