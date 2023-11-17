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

			lda	CPU_DATA
			pha
			lda	#IO_IN
			sta	CPU_DATA
			lda	$dc08			;Sekunden/10 - Register.
::51			cmp	$dc08
			beq	:51
			pla
			sta	CPU_DATA

			plp
			rts
