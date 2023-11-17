; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

; Makrodefinitionen für GEOS/MegaPatch3
; Revision 29.10.2022

:ClrB			m
			lda	#$00
			sta	§0
			/

:ClrW			m
			lda	#$00
			sta	§0
			sta	§0 +1
			/

:AddVBW			m
			lda	#§0
			clc
			adc	§1
			sta	§1
			bcc	:Exit
			inc	§1+1
::Exit
			/
