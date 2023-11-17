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

			lda	CPU_DATA		;I/O-Bereich und ROM aktivieren.
			pha
			lda	#KRNL_IO_IN
			sta	CPU_DATA

			jsr	:sysDetectRLNK		;Erkennungsroutine starten.

			pla
			sta	CPU_DATA		;I/O-Bereich und ROM ausblenden.

			plp
			rts

;*** Auf RAMLink testen, keine Änderung von CPU_DATA.
;--- Hinweis: 04.02.21/M.Kanet
;Eigenständige ":sysDetect"-Routine war
;nur unter MegaPatch128 notwendig.
::sysDetectRLNK		lda	EN_SET_REC		;Byte aus Kernal einlesen.
			cmp	#$78			;RAMLink-OS/"SEI"-Befehl ?
			bne	:51			; => Nein, weiter...

			ldx	#NO_ERROR
			b $2c
::51			ldx	#DEV_NOT_FOUND
			rts
