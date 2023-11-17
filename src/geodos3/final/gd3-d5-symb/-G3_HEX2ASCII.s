; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** HEX-Tahl nach ASCII wandeln.
;Übergabe: AKKU      = Hex-Zahl.
;Rückgabe: xReg/AKKU = High/Low-Nibble.
:HEX2ASCII		pha
			lsr
			lsr
			lsr
			lsr
			jsr	:doASCII
			tax
			pla
::doASCII		and	#%00001111
			clc
			adc	#$30
			cmp	#$3a
			bcc	:done
			clc
			adc	#$07
::done			rts
