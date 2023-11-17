; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** Speicher ab $c000.
;******************************************************************************
			t "-G3_BoldData"

;Zeichensätze einbinden
if Sprache = Deutsch
;			t "-BSWFonts.d"
.BSW_Font		v 9,"fnt.BSW9.de"
.BSW_FontEnd
.BSW128_Font		v 9,"fnt.BSW128.de"
.BSW128_FontEnd
endif
if Sprache = Englisch
;			t "-BSWFonts.e"
.BSW_Font		v 9,"fnt.BSW9.en"
.BSW_FontEnd
.BSW128_Font		v 9,"fnt.BSW128.en"
.BSW128_FontEnd
endif

			t "-G3_BldGDirEnt"

:VDCSpriteOnFlag	b $00

:SprtDataPoinL		b <spr1pic,<spr2pic,<spr3pic,<spr4pic
			b <spr5pic,<spr6pic,<spr7pic
:SprtDataPoinH		b >spr1pic,>spr2pic,>spr3pic,>spr4pic
			b >spr5pic,>spr6pic,>spr7pic

:VDCobj1PointerL	b <VDC_spr1pic,<VDC_spr2pic,<VDC_spr3pic,<VDC_spr4pic
			b <VDC_spr5pic,<VDC_spr6pic,<VDC_spr7pic
:VDCobj1PointerH	b >VDC_spr1pic,>VDC_spr2pic,>VDC_spr3pic,>VDC_spr4pic
			b >VDC_spr5pic,>VDC_spr6pic,>VDC_spr7pic

:VerdoppelTab		b $00,$03,$0c,$0f,$30,$33,$3c,$3f
			b $c0,$c3,$cc,$cf,$f0,$f3,$fc,$ff

if Sprache = Deutsch
;******************************************************************************
;*** Speicher bis $c856 mit $00-Bytes auffüllen.
;******************************************************************************
:_L20T			e $c856
:_L20
;******************************************************************************
endif
if Sprache = Englisch
;******************************************************************************
;*** Speicher bis $c844 mit $00-Bytes auffüllen.
;******************************************************************************
:_L20T			e $c844
:_L20
;******************************************************************************
endif

;*** New GEOS-MouseData.
.OrgMouseData80		b %00000000,%00001111
			b %01111111,%11101111
			b %01111111,%10011111
			b %01111111,%10011111
			b %01100111,%11100111
			b %00011001,%11111001
			b %11111110,%01100111
			b %11111111,%10011111

			b %00000000,%00000000
			b %01111111,%11100000
			b %01111111,%10000000
			b %01111111,%10000000
			b %01100111,%11100000
			b %00000001,%11111000
			b %00000000,%01100000
			b %00000000,%00000000

;*** Original GEOS-MouseData.
;OrgMouseData80		b %00000000,%00001111
;			b %01111111,%11101111
;			b %01111111,%10011111
;			b %01111111,%10011111
;			b %01100111,%11100111
;			b %00011001,%11111001
;			b %11111110,%01111110
;			b %11111111,%10000000
;
;			b %00000000,%00000000
;			b %01111111,%11100000
;			b %01111111,%10000000
;			b %01111111,%10000000
;			b %01100111,%11100000
;			b %00000001,%11111000
;			b %00000000,%01111110
;			b %00000000,%00000000

:TestSpriteDraw		lda	VDCSpriteOnFlag
			bne	lc896
			ldx	#7
			ldy	#14
:lc87f			stx	r0L
			sty	r0H
			lda	BitData5,x
			and	VDC_mobenble
			beq	lc88e
			jsr	DrawSpritesToVDC
:lc88e			dey
			dey
			dex
			bne	lc87f
			stx	VDC_mobenble
:lc896			jsr	SetComAreaOBEN
			rts

:_HideOnlyMouse		bit	graphMode
			bpl	:4			;>40Zeichen
			ldx	#0			;r0 bis r5 auf Stack sichern
::1			lda	r0L,x
			pha
			inx
			cpx	#$0e
			bne	:1
			jsr	TestMouseRecover
			ldx	#$0d			;r0 bis r5 wiederherstellen
::2			pla
			sta	r0L,x
			dex
			bpl	:2
			jsr	SetComAreaOBEN		;Common Area oben setzen
::4			rts

:TestMouseRecover	bit	SoftSpriteFlag
			bmi	lc8c4
			lda	#$ff
			sta	SoftSpriteFlag
			jsr	RecoverMouseScr
:lc8c4			jsr	SetComAreaOBuUnt
			ldx	r0L
			ldy	r0H
			rts
:MoveTestFlag		b	0
:VDC_DrawSprFlag	b	0

:_DoSoftSprites		jsr	SetComAreaOBuUnt
			lda	VDCSpriteOnFlag
			beq	lc8e3
			lda	#$00
			ldx	#$1a			;alle Softsprite-Positionen
:lc8da			sta	VDC_mobenble,x		;löschen und alle Sprites aus
			dex
			bpl	lc8da
			sta	VDCSpriteOnFlag		;auf $00 setzen
:lc8e3			lda	dispBufferOn
			pha
			lda	#$80			;nur in Vordergrund
			sta	dispBufferOn
			jsr	TestVDCSprEnabled
			lda	mobenble
			eor	#$ff			;Bits invertieren
			ora	MoveTestFlag		;Bits für bewegte Sprites
			and	VDC_mobenble		;enabled VDC Sprites
			sta	VDC_DrawSprFlag		;noch nicht eingezeichnete Spr.
			beq	lc92c			;>keine neuen Sprites
			jsr	TestMouseRecover
			ldy	#14
			ldx	#7
:lc904			stx	r0L			;neue Sprites einzeichnen
			sty	r0H			;und Positionen stezen
			lda	BitData5,x
			sta	r9H
			and	VDC_DrawSprFlag
			beq	lc927
			jsr	DrawSpritesToVDC
			lda	VDC_mob0xpos,y
			sta	VDClast_mobXPos,y
			lda	VDC_mob0xpos+1,y
			sta	VDClast_mobXPos+1,y
			lda	mob0ypos,y
			sta	VDClast_mobYPos,x
:lc927			dey
			dey
			dex
			bne	lc904
:lc92c			lda	moby2
			sta	VDClast_moby2
			lda	mobx2
			sta	VDClast_mobx2
			lda	mobenble
			sta	VDC_mobenble
			jsr	TestSprMoved
			pla
			sta	dispBufferOn
			jsr	SetComAreaOBEN
			lda	mobenble
			and	#$01
			bne	lc94f
			rts

:lc94f			bit	SoftSpriteFlag
			bmi	lc96f
			sei
			lda	mouseXPos +0
			ldx	mouseXPos +1
			ldy	mouseYPos
			cli
			cmp	LastmouseXPos
			bne	lc96c
			cpx	LastmouseXPos+1
			bne	lc96c
			cpy	LastmouseYPos
			bne	lc96c
			rts

:lc96c			jsr	RecoverMouseScr
:lc96f			lda	#$00
			sta	SoftSpriteFlag
			lda	dispBufferOn
			pha
			lda	#$80
			sta	dispBufferOn
			sei
			lda	mouseYPos
			sta	LastmouseYPos
			sta	r2L
			lda	mouseXPos +1
			sta	LastmouseXPos+1
			sta	r1H
			lda	mouseXPos +0
			cli
			sta	LastmouseXPos
			sta	r1L
			jsr	SetComAreaOBuUnt
			lda	r1L
			and	#$07
			asl
			asl
			asl
			sta	r3H
			asl
			adc	r3H
			sta	r3H
			lsr	r1H
			ror	r1L
			lsr	r1H
			ror	r1L
			lsr	r1H
			ror	r1L
			lda	#$08
			sta	r2H
			lda	#$00
			sta	r3L
:lc9b7			ldx	r2L
			cpx	#$c8
			beq	lc9f4
			jsr	GetScreenAdresse
			jsr	GetVScrByte
			clv
			bvc	lc9c9
:lc9c6			jsr	GetNxtVScrByte
:lc9c9			ldy	r3L
			sta	VDC_BackScrSpr0,y
			inc	r3L
			ldy	r3H
			and	VDCmouseData,y
			ora	VDC_BackScrSpr1,y
			jsr	SaveToVDCScr
			inc	r3H
			inc	r5L
			bne	lc9e3
			inc	r5H
:lc9e3			dec	r4L
			bne	lc9c6
			clc
			lda	r4H
			adc	r3H
			sta	r3H
			inc	r2L
			dec	r2H
			bne	lc9b7
:lc9f4			pla
			sta	dispBufferOn
			jmp	SetComAreaOBEN

:TestVDCSprEnabled	ldx	#$00			;Testen ob Sprite enabled
			stx	VDC_SprMoveFlag		;wenn ja dann testen ob sich
			stx	MoveTestFlag		;Sprite bewegt hat
			ldy	#14			;es werden alle Sprites
			ldx	#7			;getestet
:lca06			stx	r0L
			sty	r0H
			lda	BitData5,x
			sta	r9H
			and	mobenble
			beq	lca21
			jsr	TestVDCSprMove		;auf Bewegung testen
			bcc	lca21			;nicht bewegt
			lda	r9H			;SpriteBit speichern
			ora	MoveTestFlag
			sta	MoveTestFlag
:lca21			dey				;auf nächstes Sprite stellen
			dey
			dex
			bne	lca06
			rts

:TestVDCSprMove		lda	VDC_SprMoveFlag
			bne	lca6d
			lda	VDC_mob0xpos+1,y
			bpl	lca39
			lda	#$00
			sta	VDC_mob0xpos,y
			sta	VDC_mob0xpos+1,y
:lca39			lda	VDC_mob0xpos,y
			cmp	VDClast_mobXPos,y
			bne	lca6a
			lda	VDC_mob0xpos+1,y
			cmp	VDClast_mobXPos+1,y
			bne	lca6a
			lda	mob0ypos,y
			cmp	VDClast_mobYPos,x
			bne	lca6a
			lda	mobx2
			cmp	VDClast_mobx2
			bne	lca6a
			lda	moby2
			cmp	VDClast_moby2
			bne	lca6a
			lda	r9H
			and	VDC_mobenble
			beq	lca6a
			clc
			rts
:lca6a			inc	VDC_SprMoveFlag
:lca6d			sec
			rts
:Add80TOr5		lda	#$50
			clc
			adc	r5L
			sta	r5L
			lda	r5H
			adc	#$00
			sta	r5H
			rts

:TestSprMoved		lda	MoveTestFlag		;hat sich ein Sprite bewegt?
			beq	lcaa9			;>nein
			lda	#$01
			sta	r0L			;r0L = 1
			asl
			sta	r0H			;r0H = 2
			lsr	MoveTestFlag		;einzelne Spritebits einblenden
:lca8c			lsr	MoveTestFlag
			bcc	lca9d			;>nicht enabled
			ldy	r0H
			ldx	r0L
			lda	BitData5,x		;Spritebit setzen
			sta	r9H
			jsr	MoveVDCSprite
:lca9d			inc	r0H
			inc	r0H
			inc	r0L
			lda	r0L
			cmp	#8
			bne	lca8c
:lcaa9			rts

:MoveVDCSprite		jsr	SetVDCsprData
:lcaad			jsr	SetSprZeile
			jsr	PrntSpriteZeile
			jsr	Add80TOr5
			lda	r10H
			beq	lcac0
			jsr	PrntSpriteZeile
			jsr	Add80TOr5
:lcac0			dec	r11L
			bne	lcaad
			rts

:SetVDCsprData		lda	SprtDataPoinL-1,x
			sta	r4L
			lda	SprtDataPoinH-1,x
			sta	r4H
			lda	VDCobj1PointerL-1,x
			sta	r12L
			lda	VDCobj1PointerH-1,x
			sta	r12H
			lda	mob0ypos,y
			sec
			sbc	#$32
			tax
			stx	r9L
			jsr	xGetScanLine
			ldx	r0L			;Spritenummer
			ldy	#63			;Byte für Höhe des Sprite aus
			lda	(r4L),y			;Spritedaten holen (64. Byte)
			sta	r11H
			and	#$7f			;Bit 7 ausblenden
			sta	r11L
			sta	VDC_sprHight,x		;im Höhenzeiger speichern
			ldy	r0H
			lda	moby2    ;ist Sprite in Y-Richtung vergrößert?
			and	r9H
			sta	r10H
			beq	lcb05			;>nein
			lda	r11L			;>ja dann verdoppelte Höhe
			asl
			sta	VDC_sprHight,x		;in Register setzen
:lcb05			lda	#4			;Breite des Sprites setzen
			sta	VDC_sprLeng,x
			lda	r11H     ;ist Sprite in X-Richtung verdoppelt?
			and	#$80
			beq	lcb15			;>nein
			lda	#2			;>ja
			sta	VDC_sprLeng,x
:lcb15			lda	mobx2    ;ist Sprite in X-Richtung verdoppelt?
			and	r9H
			sta	r10L
			beq	lcb2c			;>nein
			lda	VDC_sprLeng,x		;>ja dann Breite verdoppeln
			asl
			sta	VDC_sprLeng,x
			cmp	#4			;wenn Breite = 4
			beq	lcb2c			;>dann ok
			dec	VDC_sprLeng,x		;sonst auf 7 setzen
:lcb2c			lda	VDC_mob0xpos,y
			sta	r8L
			and	#$07
			sta	r8H
			lda	VDC_mob0xpos+1,y
			ror
			ror	r8L
			ror
			ror	r8L
			lsr	r8L
			lda	r8L
			clc
			adc	r5L
			sta	r5L
			sta	VDC_sprPos,y
			lda	r5H
			adc	#$00
			sta	r5H
			sta	VDC_sprPos+1,y
			lda	#80
			sec
			sbc	r8L
			bcs	lcb5c
			lda	#$00
:lcb5c			cmp	VDC_sprLeng,x
			bcs	lcb64
			sta	VDC_sprLeng,x
:lcb64			lda	#200
			sec
			sbc	r9L
			cmp	VDC_sprHight,x
			bcs	lcb79
			sta	VDC_sprHight,x
			sta	r11L
			lda	r10H
			beq	lcb79
			lsr	r11L
:lcb79			rts

:DrawSpritesToVDC	lda	VDCobj1PointerL-1,x
			sta	r3L
			lda	VDCobj1PointerH-1,x
			sta	r3H
			lda	VDC_sprPos,y
			sta	r5L
			lda	VDC_sprPos+1,y
			sta	r5H
			lda	VDC_sprLeng,x
			sta	r1L
			lda	VDC_sprHight,x
			sta	r1H
:lcb98			ldx	r1L
			ldy	#$00
			lda	(r3L),y
			jsr	SaveToVDCScr		;1 Byte nach r5 in VDC
			iny
			dex
			beq	lcbb3
:lcba5			bit	VDCBaseD600
			bpl	lcba5
			lda	(r3L),y
			sta	VDCDataD601
			iny
			dex
			bne	lcba5
:lcbb3			tya
			clc
			adc	r3L			;r3 = r3 + Y-Reg
			sta	r3L
			lda	r3H
			adc	#$00
			sta	r3H
			jsr	Add80TOr5
			dec	r1H			;Zähler (Höhe des Sprites)
			bne	lcb98
			ldx	r0L
			ldy	r0H
			rts

:SetSprZeile		ldy	#$00
			sty	VDCSprDataBuf1+3
			sty	VDCSprDataBuf1+6
:lcbd3			lda	(r4L),y			;1 Spritezeile holen
			sta	VDCSprDataBuf1,y	;und zwischenspeichern
			iny
			cpy	#3			;3 Bytes
			bne	lcbd3
			tya
			clc
			adc	r4L
			sta	r4L
			lda	r4H
			adc	#$00
			sta	r4H			;r4 = r4 + Y-Reg(3)
			lda	r10L
			beq	lcbf0
			jsr	VerdoppelZeile
:lcbf0			lda	r8H
			beq	lcc20
			tax
			bit	r11H
			bpl	lcc08
			lda	r10L
			bne	lcc08
:lcbfd			lsr	VDCSprDataBuf1
			ror	VDCSprDataBuf1+1
			dex
			bne	lcbfd
			beq	lcc20
:lcc08			lsr	VDCSprDataBuf1
			ror	VDCSprDataBuf1+1
			ror	VDCSprDataBuf1+2
			ror	VDCSprDataBuf1+3
			ror	VDCSprDataBuf1+4
			ror	VDCSprDataBuf1+5
			ror	VDCSprDataBuf1+6
			dex
			bne	lcc08
:lcc20			ldx	r0L
			ldy	r0H
			rts

:VerdoppelZeile		bit	r11H
			bmi	lcc31
			ldx	#$04
			lda	VDCSprDataBuf1+2
			jsr	VerdoppelByte
:lcc31			ldx	#$02
			lda	VDCSprDataBuf1+1
			jsr	VerdoppelByte
			ldx	#$00
			lda	VDCSprDataBuf1
:VerdoppelByte		sta	r2L
			and	#$0f
			tay
			lda	VerdoppelTab,y
			sta	VDCSprDataBuf1+1,x
			lda	r2L
			lsr
			lsr
			lsr
			lsr
			tay
			lda	VerdoppelTab,y
			sta	VDCSprDataBuf1,x
			rts

:PrntSpriteZeile	lda	VDC_sprLeng,x
			beq	lccb3			;>Länge = 0 = nicht darstellen
			tax
			ldy	#$00
			jsr	GetVScrByte
			sta	(r12L),y
			ora	VDCSprDataBuf1,y
			sta	VDCSprDataBuf2,y
			iny
			dex
			beq	lcc82
:lcc6e			lda	VDCBaseD600
			bpl	lcc6e
			lda	VDCDataD601
			sta	(r12L),y
			ora	VDCSprDataBuf1,y
			sta	VDCSprDataBuf2,y
			iny
			dex
			bne	lcc6e
:lcc82			ldx	r0L
			lda	VDC_sprLeng,x
			clc
			adc	r12L
			sta	r12L
			bcc	lcc90
			inc	r12H
:lcc90			lda	VDC_sprLeng,x
			tax
			ldy	#$00
			lda	VDCSprDataBuf2,y
			jsr	SaveToVDCScr
			iny
			dex
			beq	lccaf
:lcca0			bit	VDCBaseD600
			bpl	lcca0
			lda	VDCSprDataBuf2,y
			sta	VDCDataD601
			iny
			dex
			bne	lcca0
:lccaf			ldx	r0L
			ldy	r0H
:lccb3			rts

:_TempHideMouse		bit	graphMode
			bpl	lcce2
			jsr	SetComAreaOBuUnt
			bit	SoftSpriteFlag
			php
			jsr	SetComAreaOBEN
			plp
			bpl	lccca
			lda	VDC_mobenble
			beq	lcce2
:lccca			ldx	#$00
:lcccc			lda	r0L,x
			pha
			inx
			cpx	#$0e
			bne	lcccc
			jsr	TestMouseRecover
			jsr	TestSpriteDraw
			ldx	#$0d
:lccdc			pla
			sta	r0L,x
			dex
			bpl	lccdc
:lcce2			rts

:GetScreenAdresse	jsr	xGetScanLine
			lda	r1L
			clc
			adc	r5L
			sta	r5L
			bcc	lccf1
			inc	r5H
:lccf1			lda	#$00
			sta	r4H
			lda	#$50
			sec
			sbc	r1L
			cmp	#$03
			bcc	lcd03
			lda	#$03
			sta	r4L
			rts
:lcd03			sta	r4L
			eor	#$03
			sta	r4H
			rts

:RecoverMouseScr	lda	dispBufferOn
			pha
			lda	#$80
			sta	dispBufferOn		;nur in Vordergrund
			lda	LastmouseYPos
			sta	r2L			;r2L = MausYPos
			lda	LastmouseXPos
			sta	r1L
			lda	LastmouseXPos+1
			lsr
			ror	r1L
			lsr
			ror	r1L
			lsr
			ror	r1L
			sta	r1H			;r1 = MuasXPos in Cards
			jsr	SetComAreaOBuUnt
			lda	#8
			sta	r2H			;r2H = 8 (Höhe des Sprites)
			lda	#0
			sta	r3L			;r3L = 0 (Spritenummer)
:lcd34			ldx	r2L
			cpx	#200			;unterer Rand erreicht?
			beq	lcd57			;>ja
			jsr	GetScreenAdresse
:lcd3d			ldy	r3L
			lda	VDC_BackScrSpr0,y
			jsr	SaveToVDCScr		;Hintergrund unter Sprite
			inc	r3L			;wiederherstellen
			inc	r5L
			bne	lcd4d
			inc	r5H
:lcd4d			dec	r4L
			bne	lcd3d
			inc	r2L
			dec	r2H
			bne	lcd34
:lcd57			pla
			sta	dispBufferOn

:SetComAreaOBEN		lda	#%00001000		;Common-Area = oberer Bereich
			b	$2c
:SetComAreaOBuUnt	lda	#%00001100		;Common-Area = oben u. unten
			sta	lcd67+1
			lda	RAM_Conf_Reg
			and	#%11110011		;Common-Area Bits ausblenden
:lcd67			ora	#%00000000
			sta	RAM_Conf_Reg		;Common-Area setzen
			rts

:_SetMsePic		lda	r0H			;r0 = $0000?
			ora	r0L
			bne	NewMsePic		;>nein

if 0
			ldx	#4			;Orginal Mausdaten setzen
::1			asl	r0L			;r0 = r0 * 32
			rol	r0H
			dex
			bpl	:1
			lda	r0L
			clc
			adc	#<OrgMouseData80	;r0 = r0 + OrgMouseData80
			sta	r0L
			lda	r0H
			adc	#>OrgMouseData80
			sta	r0H
endif
			lda	#<OrgMouseData80	;r0 = OrgMouseData80
			sta	r0L
			lda	#>OrgMouseData80
			sta	r0H

:NewMsePic		LoadW	r1,VDCmouseData
			ldx	#0
::8			LoadB	r4L,8			; r4L = 8
::9			ldy	#0
			lda	(r0L),y			;erstes Mausbyte holen
			sta	r2H			;nach r2H
			iny
			lda	(r0L),y			;zweites Mausbyte holen
			sta	r3L			;nach r3L

			ldy	#0
			cpx	#8			;alle Mausbytes durch?
			bcs	:1			;>ja
			dey				;>nein
::1			sty	r3H			;bei ja r3H = 0  bei nein r3H = $ff
			sty	r2L			;bei ja r2L = 0  bei nein r2L = $ff

			clc				;r0 = r0 + 2
			lda	#2
			adc	r0L
			sta	r0L
			bcc	:2
			inc	r0H

::2			txa
			and	#$07
			tay
			beq	:3			;>fertig

::4			lsr	r2L
			ror	r2H
			ror	r3L
			ror	r3H
			dey
			bne	:4

::3			jsr	SetComAreaOBuUnt

			ldy	#2			;3 MausBytes übertragen
::5			lda	$0007,y			;(r2H,y)
			sta	(r1L),y
			dey
			bpl	:5

			jsr	SetComAreaOBEN

			clc				;r1 = r1 + 3
			lda	#$03
			adc	r1L
			sta	r1L
			bcc	:6
			inc	r1H

::6			dec	r4L
			bne	:9

			inx
			cpx	#$08
			beq	:7

			sec				; r0 = r0 - 16
			lda	r0L
			sbc	#16
			sta	r0L
			bcs	:7
			dec	r0H

::7			cpx	#16
			bne	:8
			rts

			t "-G3_ColorBox"

:SetStartScrAdr		lda	r3H
			pha
			lda	r3L
			and	#$07
			pha
			lda	r3L			;r3 = r3/8
			ldx	graphMode		;welcher Modus?
			bpl	:1			;>40 Zeichen
			lsr	r3H
			ror
			lsr	r3H
			ror
			lsr	r3H
			ror
::1			clc
			adc	r5L
			sta	r5L			;r5 = r5 + r3
			sta	r6L
			php
			lda	r5H
			adc	r3H
			sta	r5H
			plp
:lf6e3			lda	r6H			;r6 = r6 + r3
			adc	r3H
			sta	r6H
			pla
			tax
			pla
			sta	r3H
			rts

:_JumpB0_Basic		jsr	SetComAreaOBuUnt	;Common Area oben und unten
			ldy	#$27			;Kommando-String nach $0e00
::1			lda	(r0L),y
			sta	$0e00,y
			dey
			bpl	:1
			jmp	SetComAreaOBEN		;Common Area oben

;Farbtabelle für VDC
:_C_FarbTab_VDC		t "+G3_MP3_COLOR"
:_C_FarbTab_END

:FarbAnzahl		= ( _C_FarbTab_END - _C_FarbTab_VDC )

;******************************************************************************
;*** Speicher bis $D000 mit $00-Bytes auffüllen.
;******************************************************************************
:_B0_D000T		e $d000
:_B0_D000
;******************************************************************************

;Bereich Bank 0 $d000 bis $dfff

;******************************************************************************
;*** Speicher bis $E000 mit $00-Bytes auffüllen.
;******************************************************************************
:_B0_E000T		e $e000
:_B0_E000
;******************************************************************************
