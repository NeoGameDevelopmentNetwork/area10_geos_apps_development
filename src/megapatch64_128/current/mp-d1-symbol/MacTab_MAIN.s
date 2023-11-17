; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

:LoadB			m
			lda	#§1
			sta	§0
			/

:LoadW			m
			lda	#>§1
			sta	§0 +1
			lda	#<§1
			sta	§0
			/

:MoveB			m
			lda	§0
			sta	§1
			/

:MoveW			m
			lda	§0
			sta	§1
			lda	§0 +1
			sta	§1 +1
			/

:add			m
			clc
			adc	#§0
			/

:PushB			m
			lda	§0
			pha
			/

:PushW			m
			lda	§0 +1
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
			sta	§0 +1
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
