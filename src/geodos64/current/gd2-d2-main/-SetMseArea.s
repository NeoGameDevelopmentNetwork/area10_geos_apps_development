; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Fenstergrenzen setzen.
.SetWindow_a		ldy	#$00
			b $2c
.SetWindow_b		ldy	#$06
			b $2c
.SetWindow_c		ldy	#$0c
			ldx	#$00
::101			lda	MseMoveAreas,y
			sta	mouseTop,x
			iny
			inx
			cpx	#$06
			bne	:101
			rts

;*** Fenstergrenzen.
:MseMoveAreas		b $00,$c7			;Vollbild.
			w $0000,$013f
			b $28,$8f			;Dialogbox.
			w $0030,$010f
			b $80,$a7			;Laufwerksauswahlbox.
			w $0038,$00c7
