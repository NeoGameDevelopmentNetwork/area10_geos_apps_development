; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; ULIB: C128 auf 1/2Mhz umschalten
;
;1Mhz-Modus für Ultimate-Menü/Freeze.
;
;Übergabe : -
;Rückgabe : -
;Verändert: A

:ULIB_128_SLOW

			lda	CLKRATE128		;CLKRATE (C128):
			sta	buf_CLKRATE128		;Speed-Flag zwischenspeichern.
			lda	#$00
			sta	CLKRATE128		;Auf 1MHz zurückschalten.
							;Bit0  : 1=Start Timer
			rts

;
; ULIB: C128 auf 1/2Mhz umschalten.
;
;CLKRATE wieder zurücksetzen.
;
;Übergabe : -
;Rückgabe : -
;Verändert: A

:ULIB_128_RESTORE

			lda	buf_CLKRATE128		;CLKRATE (C128):
			sta	CLKRATE128		;Speed-Flag zurücksetzen.

			rts

:buf_CLKRATE128		b $00
