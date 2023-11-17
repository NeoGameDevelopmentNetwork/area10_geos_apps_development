; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "GEOS_QuellCo.ext"
endif

			n "GEOS_BBG/2.OBJ"
			f $06
			c "KERNAL_C000 V1.0"
			a "M. Kanet"
			o ReBootGEOS
			p EnterDeskTop
			i
<MISSING_IMAGE_DATA>

;*** ReBoot-Routine für GEOS aus REU laden.
:RL_ReBootGEOS		lda	#%00111111		;Seite #254 in REU aktivieren.
			sta	$dffe			;Bank #0, $FE00.
			lda	#%00000011
			sta	$dfff
			jsr	$de00			;BBG-ReBoot ausführen.
			jmp	$6000			;ReBoot-GEOS starten.
