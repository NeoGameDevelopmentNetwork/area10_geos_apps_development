; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Pause von 1/10sec ausführen.
:xSCPU_Pause		php
			sei

;---C64: Warteschleife.
if Flag64_128 = TRUE_C64
			lda	CPU_DATA
			pha
			lda	#%00110101
			sta	CPU_DATA
			lda	$dc08			;Sekunden/10 - Register.
::51			cmp	$dc08
			beq	:51
			pla
			sta	CPU_DATA
endif

;---C128: Warteschleife.
if Flag64_128 = TRUE_C128
			lda	MMU
			pha
			lda	#%01111110
			sta	MMU
			lda	$dc08			;Sekunden/10 - Register.
::51			cmp	$dc08
			beq	:51
			pla
			sta	MMU
endif

			plp
			rts
