; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Auf RAMLink testen.
;Rückgabe: xReg = $00, Laufwerk kann installiert werden.
;               = $0D, Keine RAMLink.
:DetectRLNK		php				;IRQ sperren.
			sei

			lda	CPU_DATA		;I/O-Bereich und ROM aktivieren.
			pha
			lda	#KRNL_IO_IN
			sta	CPU_DATA

			lda	EN_SET_REC		;Byte aus Kernal einlesen.
			cmp	#$78			;RAMLink-OS/"SEI"-Befehl ?
			bne	:no_rlnk		; => Nein, weiter...

			ldx	#NO_ERROR
			b $2c
::no_rlnk		ldx	#DEV_NOT_FOUND

			pla
			sta	CPU_DATA		;I/O-Bereich und ROM ausblenden.

			plp
			rts
