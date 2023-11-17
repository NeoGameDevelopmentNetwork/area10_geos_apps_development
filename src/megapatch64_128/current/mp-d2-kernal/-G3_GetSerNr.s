; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** GEOS-Serien-Nummer einlesen.
:xGetSerialNumber	lda	SerialNumber+0
			sta	r0L
			lda	SerialNumber+1
			sta	r0H
			rts
