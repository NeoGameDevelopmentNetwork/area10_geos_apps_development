; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Info-Box zeigen.
:Win1x0			= 8
:Win1y0			= 8
:Win1x1			= Win1x0+295
:Win1y1			= Win1y0+176

:Info			jsr	MouseOff		;Maus abschalten.

			SetColRam1000,0,$00

			Display	ST_WR_FORE ! ST_WR_BACK
			Pattern	2
			FillRec	0,199,0,319
			Pattern	1
			FillRec	Win1y0+8,Win1y1+8,Win1x0+8,Win1x1+8
			Pattern	0
			FillRec	Win1y0  ,Win1y1  ,Win1x0  ,Win1x1
			lda	#%11111111
			jsr	FrameRectangle
			Pattern	1
			FillRec	Win1y0  ,Win1y0+7,Win1x0+8,Win1x1

			jsr	UseGDFont		;Überschrift.
			PrintXY	Win1x0+16,Win1y0+6,V100d0

			LoadW	r0,V100e1		;Programm-Name.
			LoadB	r1L,Win1x0/8+3
			LoadB	r1H,Win1y0  +12
			LoadB	r2L,V100e1_x
			LoadB	r2H,V100e1_y
			jsr	BitmapUp
			LoadW	r0,V100e0		;Firmen-Logo.
			LoadB	r1L,Win1x0/8+1
			LoadB	r1H,Win1y0  +48
			LoadB	r2L,V100e0_x
			LoadB	r2H,V100e0_y
			jsr	BitmapUp
			LoadW	r0,icon_Close		;Close-Icon.
			LoadB	r1L,1
			LoadB	r1H,8
			LoadB	r2L,icon_Close_x
			LoadB	r2H,icon_Close_y
			jsr	BitmapUp

			jsr	UseSystemFont		;System-Font aktivieren.
			LoadW	r15,V100a0		;Zeiger auf Anfang Text-Tabelle.
			lda	#$00			;Text-Tabelle ausgeben.
::1			pha
			ldy	#$00
			lda	(r15L),y		;X-Koordinate.
			sta	r11L
			iny
			lda	(r15L),y
			sta	r11H
			iny
			lda	(r15L),y		;Y-Koordinate.
			sta	r1H
			iny
			iny
			lda	(r15L),y		;Zeiger auf Text.
			sta	r0L
			iny
			lda	(r15L),y
			sta	r0H
			jsr	PutString

			AddVW	6,r15
			pla
			add	$01
			cmp	#12
			bne	:1

			jsr	UseGDFont
			PrintXY	Win1x0+11,Win1y0+170,V100c0
			PrintStrgVersionCode		;Versions-Nr. ausgeben.

			LoadW	r0,V100e2		;Klammeraffe (at) ausgeben.
			LoadB	r1L,Win1x0/8 +32
			LoadB	r1H,Win1y0   +97
			LoadB	r2L,V100e2_x
			LoadB	r2H,V100e2_y
			jsr	BitmapUp

			SetColRam1000,0,$b1		;Bildschirm einschalten.
			jsr	i_FillRam
			w	(Win1x1 -Win1x0)/8
			w	COLOR_MATRIX + Win1y0/8*40+Win1x0/8+1
			b	$61

;*** Warten auf User.
:Wait			StartMouse			;Maus-Modus aktivieren.
			ClrB	pressFlag		;Warten auf Maus-Klick.
::1			lda	pressFlag
			beq	:1
			NoMseKey			;Warten bis Maus-Taste frei.

			SetColRam1000,0,$00
			Display	ST_WR_FORE ! ST_WR_BACK
			Pattern	2
			FillRec	0,199,0,319

			jmp	InitScreen

;*** Grafiken & Texte.
:V100a0			w Win1x0+188,Win1y0+ 20,V100b0
			w Win1x0+195,Win1y0+ 34,V100b1
			w Win1x0+184,Win1y0+ 45,V100b2
			w Win1x0+190,Win1y0+ 55,V100b3
			w Win1x0+192,Win1y0+ 69,V100b4
			w Win1x0+184,Win1y0+ 79,V100b5
			w Win1x0+190,Win1y0+ 93,V100b6
			w Win1x0+184,Win1y0+103,V100b7
			w Win1x0+223,Win1y0+113,V100b8
			w Win1x0+191,Win1y0+131,V100b9
			w Win1x0+198,Win1y0+141,V100b10
			w Win1x0+188,Win1y0+153,V100b11

:V100b0			b PLAINTEXT,BOLDON
			b "(w) '95-'96 von:",NULL
:V100b1			b "Markus Kanet",NULL
:V100b2			b "",NULL
:V100b3			b "",NULL
:V100b4			b "",NULL
:V100b5			b "",NULL
:V100b6			b "Internet e-Mail",NULL
:V100b7			b "darkvision",NULL
:V100b8			b "gmx.eu",NULL
:V100b9			b "",NULL
:V100b10		b "",NULL
:V100b11		b "",NULL

:V100c0			b PLAINTEXT
			b "Voll-Version: ",NULL

:V100d0			b PLAINTEXT,REV_ON
			b "One Vision Softworks präsentiert:",NULL

:V100e0
<MISSING_IMAGE_DATA>
:V100e0_x		= .x
:V100e0_y		= .y

:V100e1
<MISSING_IMAGE_DATA>
:V100e1_x		= .x
:V100e1_y		= .y

:V100e2
<MISSING_IMAGE_DATA>
:V100e2_x		= .x
:V100e2_y		= .y
