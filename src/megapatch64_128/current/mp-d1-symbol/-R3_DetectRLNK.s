; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Auf RAMLink testen.
;    Rückgabe:		xReg = $00, Laufwerk kann installiert werden.
:DetectRLNK		php				;IRQ sperren.
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

			jsr	sysDetectRLNK		;Erkennungsroutine starten.

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

;*** Auf RAMLink testen, keine Änderung von MMU, CLKRATE und RAM_Reg_Buf.
:sysDetectRLNK		lda	$e0a9			;Byte aus Kernal einlesen.
			cmp	#$78			;RAMLink-OS/"SEI"-Befehl ?
			bne	:51			; => Nein, weiter...

			ldx	#NO_ERROR
			b $2c
::51			ldx	#DEV_NOT_FOUND
			rts
