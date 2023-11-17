; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; ULIB: Auf GeoRAM testen
;
;Übergabe : -
;Rückgabe : X = Fehlerstatus, $00 = GeoRAM vorhanden
;             = $0D, Keine GeoRAM
;Verändert: A,X,Y

:ULIB_TEST_GRAM

			ldy	#$00			;Speicher in $DE00 testen.
::1			lda	$de00,y			;Wenn GeoRAM, dann stehen hier
			tax				;256Byte an RAM innerhalb der
			eor	#$ff			;GeoRAM zur Verfügung.
			sta	$de00,y
			cmp	$de00,y
			php
			txa
			sta	$de00,y
			plp				;Testbyte gespeichert ?
			bne	:no_gram		; => Nein, keine GeoRAM.
			iny
			bne	:1

			ldx	#NO_ERROR
			b $2c
::no_gram		ldx	#DEV_NOT_FOUND

			rts
