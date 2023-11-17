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

if Flag64_128 = TRUE_C64
			lda	CPU_DATA		;I/O-Bereich und ROM aktivieren.
			pha
			lda	#$37
			sta	CPU_DATA
endif
if Flag64_128 = TRUE_C128
			lda	MMU			;I/O-Bereich und ROM aktivieren.
			pha
			lda	#$4e
			sta	MMU
endif

			jsr	sysDetectGRAM		;Erkennungsroutine starten.

if Flag64_128 = TRUE_C64
			pla
			sta	CPU_DATA		;I/O-Bereich und ROM ausblenden.
endif
if Flag64_128 = TRUE_C128
			pla
			sta	MMU			;I/O-Bereich und ROM ausblenden.
endif

			plp
			rts

;*** Auf GeoRAM testen, keine Änderung von MMU, CLKRATE und RAM_Reg_Buf.
:sysDetectGRAM		ldy	#$00
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
