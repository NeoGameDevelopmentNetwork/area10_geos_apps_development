; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Auf GeoRAM/BBGRAM testen.
;Rückgabe: xReg = $00, Laufwerk kann installiert werden.
;               = $0D, Keine GeoRAM.
:DetectGRAM		php				;IRQ sperren.
			sei

			lda	CPU_DATA		;I/O-Bereich und ROM aktivieren.
			pha
			lda	#IO_IN
			sta	CPU_DATA

			ldy	#$00			;Speicher in $DE00 testen.
::51			lda	$de00,y			;Wenn GeoRAM, dann stehen hier
			eor	#$ff			;256Byte an RAM innerhalb der
			sta	$de00,y			;GeoRAM zur Verfügung.
			cmp	$de00,y
			php
			eor	#$ff
			sta	$de00,y
			plp				;Testbyte gespeichert ?
			bne	:no_gram		; => Nein, keine GeoRAM.
			iny
			bne	:51

			ldx	#NO_ERROR
			b $2c
::no_gram		ldx	#DEV_NOT_FOUND

			pla
			sta	CPU_DATA		;I/O-Bereich und ROM ausblenden.

			plp
			rts
