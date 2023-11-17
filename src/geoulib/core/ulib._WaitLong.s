; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; ULIB: Warteschleife für Freeze/Mount
;
;Übergabe : -
;Rückgabe : -
;Verändert: X,Y

:ULIB_WAIT_LONG

			ldx	#2
::1			ldy	cia1tod_s
::2			cpy	cia1tod_s
			beq	:2
			dex
			bne	:1

			rts
