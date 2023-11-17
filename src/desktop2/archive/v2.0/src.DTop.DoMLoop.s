; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Erweiterte MainLoop-Routine.
:u_appMain		lda	flag_DnDActive
			beq	exit5			; => Kein DnD...

			lda	#$01			;DnD-Sprite.
			sta	r3L

			lda	mouseYPos		;Position für DnD-
			sec				;Sprite berechnen.
			sbc	#$08
			sta	r5L

			sec
			lda	mouseXPos +0
			sbc	#< $0008
			sta	r4L
			lda	mouseXPos +1
			sbc	#> $0008
			sta	r4H

			jmp	PosSprite		;DnD-Sprite setzen.

:exit5			rts
