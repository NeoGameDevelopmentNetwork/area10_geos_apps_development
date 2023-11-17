; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "GEOS_QuellCo.ext"

:EN_SET_REC		= $e0a9
:RL_HW_EN		= $e0b1
:SET_REC_IMG		= $fe03
:EXEC_REC_REU		= $fe06
:EXEC_REC_SEC		= $fe09
:RL_HW_DIS		= $fe0c
:RL_HW_DIS2		= $fe0f
:EXEC_REU_DIS		= $fe1e
:EXEC_SEC_DIS		= $fe21

endif

			n "GEOS_RL/2.OBJ"
			f $06
			c "KERNAL_C000 V1.0"
			a "M. Kanet"
			o ReBootGEOS
			p EnterDeskTop
			i
<MISSING_IMAGE_DATA>

:RL_ReBootGEOS		sei				;IRQ abschalten.

			lda	#%00110110		;I/O aktivieren.
			sta	CPU_DATA

			jsr	EN_SET_REC		;RL-Hardware einschalten.

			ldy	#$09
::101			lda	RamBootData   ,y	;Transfer-Daten
			sta	ramExpBase1 +1,y	;kopieren.
			dey
			bpl	:101

			jsr	EXEC_REC_REU		;Transfer ausführen.
			jsr	RL_HW_DIS		;RL-Hardware abschalten.

			jmp	$6000			;GEOS booten...

:RamBootData		b	$91
			w	$6000
			w	$7e00
			b	$00
			w	$0500
			b	$00
			b	$00
