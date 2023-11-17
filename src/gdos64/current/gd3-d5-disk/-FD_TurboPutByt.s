; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = C_41!C_71!FD_41!FD_71!HD_41!HD_71
if :tmp0!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** Daten über ser.Bus senden.
;    Übergabe:		AKKU/xReg  , Zeiger auf Bytespeicher.
:putDataBytes		sta	d0L
			stx	d0H

			jsr	initDataLISTEN
			bne	:err

			ldy	#$00
::loop			lda	(d0L),y
;--- Hinweis:
;Debug-Code, ersetzt Daten durch ein
;Test-Byte %10111101.
;::DEBUG		ldx	r1L
;			cpx	#40
;			beq	:skip_DEBUG
;			lda	#%10111101
;::skip_DEBUG
;----
			jsr	CIOUT
			iny
			bne	:loop

			jsr	UNLSN

			lda	#NO_ERROR
::err			tax
			rts
endif

;******************************************************************************
::tmp1 = C_81!FD_81!FD_NM!HD_81!HD_NM!IEC_NM!S2I_NM
if :tmp1!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** Daten über ser.Bus senden.
;    Übergabe:		AKKU/xReg  , Zeiger auf Bytespeicher.
:putDataBytes		sta	d0L
			stx	d0H

			jsr	initDataLISTEN
			bne	:err

			jsr	SwapDskNamData		;Diskname zurück nach 1581/Native.

			ldy	#$00
::loop			lda	(d0L),y
;--- Hinweis:
;Debug-Code, ersetzt Daten durch ein
;Test-Byte %10111101.
;::DEBUG		ldx	r1L
;			cpx	#40
;			beq	:skip_DEBUG
;			lda	#%10111101
;::skip_DEBUG
;----
			jsr	CIOUT
			iny
			bne	:loop

			jsr	UNLSN

			jsr	SwapDskNamData		;Diskname nach GEOS.

			lda	#NO_ERROR
::err			tax
			rts
endif
