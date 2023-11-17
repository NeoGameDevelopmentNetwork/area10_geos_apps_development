; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Auf GeoRAM/BBGRAM testen.
;    Rückgabe:		xReg = $00, Laufwerk kann installiert werden.
:DetectGRAM		php				;IRQ sperren.
			sei

			lda	CPU_DATA		;I/O-Bereich und ROM aktivieren.
			pha
			lda	#IO_IN
			sta	CPU_DATA

			jsr	:sysDetectGRAM		;Erkennungsroutine starten.

			pla
			sta	CPU_DATA		;I/O-Bereich und ROM ausblenden.

			plp
			rts

;*** Auf GeoRAM testen, keine Änderung von CPU_DATA.
;--- Hinweis: 04.02.21/M.Kanet
;Eigenständige ":sysDetect"-Routine war
;nur unter MegaPatch128 notwendig.
::sysDetectGRAM		ldy	#$00
::51			lda	$de00,y
			eor	#$ff
			sta	$de00,y
			cmp	$de00,y
			php
			eor	#$ff
			sta	$de00,y
			plp
			bne	:52
			iny
			bne	:51

			ldx	#NO_ERROR
			b $2c
::52			ldx	#DEV_NOT_FOUND
			rts
