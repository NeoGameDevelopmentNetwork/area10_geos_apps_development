; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = C_41!C_71!C_81!IEC_NM!S2I_NM
::tmp0b = FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM
::tmp0 = :tmp0a!:tmp0b
if :tmp0!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** Bytes über ser. Bus / TurboDOS einlesen.
;    Übergabe:		AKKU/xReg , Zeiger auf Bytespeicher.
;			yReg      , Anzahl Bytes.
:getDataBytes		sta	d0L
			stx	d0H

			sty	d1L

			jsr	initDataTALK
			bne	:err

::1			jsr	ACPTR

			ldy	#$00
			sta	(d0L),y

			inc	d0L
			bne	:2
			inc	d0H

::2			dec	d1L
			bne	:1

			jsr	UNTALK

			lda	#NO_ERROR
::err			tax
			rts
endif
