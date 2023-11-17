; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Partitionsdaten einlesen.
;Übergabe: AKKU = Partitionsnummer.
:cmdGetPartData		sta	:FCom_GP +3

			lda	#< :FCom_GP
			ldx	#> :FCom_GP
			ldy	#:FCom_GP_len
			jsr	xSendComVLen		;Befehl senden.
			jsr	UNLSN			;Laufwerk abschalten.

			lda	#< devDataBuf
			ldx	#> devDataBuf
			ldy	#31
			jmp	getDevBytes

::FCom_GP		b "G-P",$00,CR
::FCom_GP_end
::FCom_GP_len		= (:FCom_GP_end - :FCom_GP)
