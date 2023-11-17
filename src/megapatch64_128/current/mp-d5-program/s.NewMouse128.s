; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			t "G3_SymMacExt"

			n "NewMouse128"
			f AUTO_EXEC
			a "W.Grimm/M.Kanet"
			c "NewMouse    V1.0"
			h "* A simple mouse pointer..."
			z $40

:D_OrgMouseData		= $c985
:E_OrgMouseData		= $c991
:D_OrgMouseData80	= $c856
:E_OrgMouseData80	= $c844

:Start			jsr	TestGEOSVersion
			jsr	TestC128
			bmi	:1
			jmp	EnterDeskTop

::1			LoadW	r0,Mouse80Pic
			LoadW	r1,D_OrgMouseData80
			lda	nationality
			bne	:2
			LoadW	r1,E_OrgMouseData80
::2			LoadW	r2,$0020
			lda	#$01
			sta	r3L
			lda	#$00
			sta	r3H
			jsr	MoveBData
			lda	#$00
			sta	r0H
			sta	r0L
			jsr	SetMsePic
			LoadW	r0,Mouse40Pic
			LoadW	r1,D_OrgMouseData
			lda	nationality
			bne	:3
			LoadW	r1,E_OrgMouseData
::3			LoadW	r2,$0018
			jsr	MoveData
			LoadW	r1,$84c1
			jsr	MoveData
;			lda	#$0b
;			sta	C_GEOS_OUSE
;			sta	$d027
;			sta	$d028
			jmp	EnterDeskTop

:Mouse80Pic		b %00111111,%11111111
			b %01011111,%11111111
			b %01101111,%11111111
			b %01110111,%11111111
			b %01111011,%11111111
			b %01111101,%11111111
			b %01011011,%11111111
			b %10100111,%11111111

			b %00000000,%00000000
			b %01000000,%00000000
			b %01100000,%00000000
			b %01110000,%00000000
			b %01111000,%00000000
			b %01111100,%00000000
			b %01011000,%00000000
			b %00000000,%00000000

:Mouse40Pic		b %01000000,%00000000,%00000000
			b %01100000,%00000000,%00000000
			b %01110000,%00000000,%00000000
			b %01111000,%00000000,%00000000
			b %01111100,%00000000,%00000000
			b %01011000,%00000000,%00000000
			b %00001100,%00000000,%00000000
			b %00001000,%00000000,%00000000

if 0 = 1
:Mouse40Pic		b %01111110,%00000000,%00000000
			b %01111100,%00000000,%00000000
			b %01111000,%00000000,%00000000
			b %01111100,%00000000,%00000000
			b %01101110,%00000000,%00000000
			b %01000111,%00000000,%00000000
			b %00000010,%00000000,%00000000
			b %00000000,%00000000,%00000000
endif

:TestGEOSVersion	lda	version
			cmp	#$20
			bne	:1
			rts

::1			jmp	EnterDeskTop

:TestC128		lda	#$12
			cmp	version
			bpl	:1
			lda	c128Flag
::1			rts
