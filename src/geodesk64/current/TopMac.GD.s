﻿; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

; System-Macros GeoDesk
; Version 16.03.2019

:LoadB			m
			lda	#§1
			sta	§0
			/

:LoadW			m
			lda	#<§1
			sta	§0
			lda	#>§1
			sta	§0+1
			/

:MoveB			m
			lda	§0
			sta	§1
			/

:MoveW			m
			lda	§0
			sta	§1
			lda	§0+1
			sta	§1+1
			/

:ClrB			m
			lda	#$00
			sta	§0
			/

:ClrW			m
			lda	#$00
			sta	§0
			sta	§0 +1
			/

:PushB			m
			lda	§0
			pha
			/

:PushW			m
			lda	§0+1
			pha
			lda	§0
			pha
			/

:PopB			m
			pla
			sta	§0
			/

:PopW			m
			pla
			sta	§0
			pla
			sta	§0+1
			/

:AddVB			m
			lda	§1
			clc
			adc	#§0
			sta	§1
			/

:AddVW			m
			lda	#<§0
			clc
			adc	§1
			sta	§1
			lda	#>§0
			adc	§1+1
			sta	§1+1
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

:SubVB			m
			sec
			lda	§1
			sbc	#§0
			sta	§1
			/

:SubVW			m
			lda	§1
			sec
			sbc	#<§0
			sta	§1
			lda	§1+1
			sbc	#>§0
			sta	§1+1
			/

:CmpB			m
			lda	§0
			cmp	§1
			/

:CmpBI			m
			lda	§0
			cmp	#§1
			/

:CmpW			m
			lda	§0+1
			cmp	§1+1
			bne	:ende
			lda	§0
			cmp	§1
::ende
			/

:CmpWI			m
			lda	§0+1
			cmp	#>§1
			bne	:ende1
			lda	§0
			cmp	#<§1
::ende1
			/

:IncW			m
			inc	§0 +0
			bne	:Exit
			inc	§0 +1
::Exit
			/

; Optionale Macros.
:AddB			m
			clc
			lda	§0
			adc	§1
			sta	§1
			/

:AddW			m
			lda	§0
			clc
			adc	§1
			sta	§1
			lda	§0+1
			adc	§1+1
			sta	§1+1
			/

:SubW			m
			lda	§1
			sec
			sbc	§0
			sta	§1
			lda	§1+1
			sbc	§0+1
			sta	§1+1
			/
