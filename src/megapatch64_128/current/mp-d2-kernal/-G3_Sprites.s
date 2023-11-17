; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Spritedaten in Spritespeicher kopieren.
:xDrawSprite		ldy	r3L
			lda	sprPicAdrL,y
			sta	r5L
			lda	sprPicAdrH,y
			sta	r5H

			ldy	#$3f
::51			lda	(r4L),y
			sta	(r5L),y
			dey
			bpl	:51
			rts

;*** Zeiger auf Sprite-Speicher.
:sprPicAdrL		b < spr0pic,< spr1pic,< spr2pic,< spr3pic
			b < spr4pic,< spr5pic,< spr6pic,< spr7pic
:sprPicAdrH		b > spr0pic,> spr1pic,> spr2pic,> spr3pic
			b > spr4pic,> spr5pic,> spr6pic,> spr7pic

;*** C64: Sprite positionieren.
if Flag64_128 = TRUE_C64
:xPosSprite		lda	CPU_DATA
			pha
			lda	#%00110101
			sta	CPU_DATA

			lda	r3L
			asl
			tay

			lda	r5L
			clc
			adc	#$32
			sta	mob0ypos,y
			lda	r4L
			clc
			adc	#$18
			sta	r6L
			lda	r4H
			adc	#$00
			sta	r6H

			lda	r6L
			sta	mob0xpos,y

			ldx	r3L
			lda	BitData2,x
			eor	#$ff
			and	msbxpos
			tay
			lda	#$01
			and	r6H
			beq	:51
			tya
			ora	BitData2,x
			tay
::51			sty	msbxpos
			jmp	ExitSprPicIO

;*** Sprite einschalten.
:xEnablSprite		ldx	r3L
			lda	BitData2,x
			tax
			lda	CPU_DATA
			pha
			lda	#%00110101
			sta	CPU_DATA
			txa
			ora	mobenble
			jmp	SetMobExitIO

;*** Sprite abschalten.
:xDisablSprite		ldx	r3L
			lda	BitData2,x
			eor	#$ff
			tax
			lda	CPU_DATA
			pha
			lda	#%00110101
			sta	CPU_DATA
			txa
			and	mobenble
:SetMobExitIO		sta	mobenble
:ExitSprPicIO		pla
			sta	CPU_DATA
			rts
endif

;*** C128: Sprite positionieren.
if Flag64_128 = TRUE_C128
:xPosSprite		ldx	#r4L			;r4 = X-Koordinate
			jsr	NormalizeX

			lda	r3L			;Nummer des Sprites
			asl
			tay

			lda	r5L			;r5L = Y-Koordinate
			clc
			adc	#$32
			sta	mob0ypos,y

			lda	graphMode
			bpl	:51			;>40Zeichen

			lda	r4H			;r4 nach VDC X-Koordinate
			sta	VDC_mob0xpos+1,y
			lsr
			sta	r4H
			lda	r4L
			sta	VDC_mob0xpos,y
			ror
			sta	r4L			;r4 = r4/2

::51			lda	r4L
			clc
			adc	#24
			sta	r6L			;r6 = r4 + 24 (rechter Rand)
			lda	r4H
			adc	#0
			sta	r6H

			lda	r6L
			sta	mob0xpos,y		;VIC X-Pos low setzen

			ldx	r3L
			lda	BitData2,x
			eor	#$ff
			and	msbxpos			;VIC X-Pos high stezen
			tay

			lda	#$01
			and	r6H
			beq	:52
			tya
			ora	BitData2,x
			tay
::52			sty	msbxpos
			rts

;*** Sprite einschalten.
:xEnablSprite		ldx	r3L
			lda	BitData2,x
			tax
			txa
			ora	mobenble
			sta	mobenble
			rts

;*** Sprite ausschalten.
:xDisablSprite		ldx	r3L
			lda	BitData2,x
			eor	#$ff
			pha
			pla
			and	mobenble
			sta	mobenble
			rts
endif
