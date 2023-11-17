; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = C_41!C_71
if :tmp0!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** Bytes über ser. Bus / TurboDOS einlesen.
;    Übergabe:		AKKU/xReg , Zeiger auf Bytespeicher.
:verDataBytes		sta	d0L
			stx	d0H

			lda	#$00
			sta	d1L

			jsr	initDataTALK
			bne	:err

;--- Nur 1581/Native:Diskname korrigieren.
;			jsr	SwapDskNamData		;Diskname zurück nach 1581/Native.

::1			jsr	ACPTR

			ldy	#$00
			cmp	(d0L),y
			bne	:verify_error

			inc	d0L
			bne	:2
			inc	d0H

::2			dec	d1L
			bne	:1

			lda	#NO_ERROR
			b $2c
::verify_error		lda	#WR_VER_ERR
			pha

			jsr	UNTALK

;--- Nur 1581/Native:Diskname korrigieren.
;			jsr	SwapDskNamData		;Diskname nach GEOS.

			pla

::err			tax
			rts
endif
