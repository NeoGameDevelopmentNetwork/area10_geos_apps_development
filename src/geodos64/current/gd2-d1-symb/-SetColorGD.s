; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Farbbox zeichnen.
; Datum			: 05.07.97
; Aufruf		: JSR  (Bereichsname)
; Übergabe		: -
; Rückgabe		: -
; Verändert		: AKKU,xReg,yReg
;			  r5  bis r7
; Variablen		: -
; Routinen		: -
;******************************************************************************

;*** Farbbox zeichnen.
.i_C_ColorBack		ldx	#$00
			b $2c
.i_C_ColorClr		ldx	#$01
			b $2c
.i_C_MenuBack		ldx	#$02
			b $2c
.i_C_MenuTBox		ldx	#$03
			b $2c
.i_C_MenuMIcon		ldx	#$04
			b $2c
.i_C_MenuDIcon		ldx	#$05
			b $2c
.i_C_MenuClose		ldx	#$06
			b $2c
.i_C_MenuTitel		ldx	#$07
			b $2c

.i_C_Balken		ldx	#$08
			b $2c
.i_C_Register		ldx	#$09
			b $2c

.i_C_DBoxClose		ldx	#$0c
			b $2c
.i_C_DBoxTitel		ldx	#$0d
			b $2c
.i_C_DBoxBack		ldx	#$0e
			b $2c
.i_C_DBoxDIcon		ldx	#$0f
			b $2c

.i_C_IBoxBack		ldx	#$10
			b $2c

.i_C_FBoxClose		ldx	#$11
			b $2c
.i_C_FBoxTitel		ldx	#$12
			b $2c
.i_C_FBoxBack		ldx	#$13
			b $2c
.i_C_FBoxDIcon		ldx	#$14
			b $2c

.i_C_MainIcon		ldx	#$15
			b $2c

.i_C_GEOS		ldx	#$16
			lda	colSystem,x
			jmp	i_UserColor
