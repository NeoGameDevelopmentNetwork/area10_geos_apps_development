; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExt"

;*** GEOS-Header.
			n "NewMouse64"
			c "NewMouse    V1.0"
			t "G3_Sys.Author"
			f AUTO_EXEC
			z $80				;nur GEOS64

			o APP_RAM

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "* Ein einfacher Mauszeiger..."
endif
if Sprache = Englisch
			h "* A simple mouse pointer..."
endif

;Symbol für Mauszeiger auswählen.
;1 = Moderner, schlanker Mauszeiger
;2 = Standard Mauszeiger
:UseMousePic = 1

:Start			ldy	#$3e
::1			lda	MousePic,y
			sta	mousePicData,y
			dey
			bpl	:1
			jmp	EnterDeskTop

if UseMousePic = 1
;*** Moderner, schlanker Mauszeiger
:MousePic		b %10000000,%00000000,%00000000	;Zeile #1
			b %11000000,%00000000,%00000000	;Zeile #2
			b %11100000,%00000000,%00000000	;Zeile #3
			b %11110000,%00000000,%00000000	;Zeile #4
			b %11111000,%00000000,%00000000	;Zeile #5
			b %11111100,%00000000,%00000000	;Zeile #6
			b %11111000,%00000000,%00000000	;Zeile #7
			b %11110000,%00000000,%00000000	;Zeile #8
			b %11011000,%00000000,%00000000	;Zeile #9
			b %10011000,%00000000,%00000000	;Zeile #10
			b %00001100,%00000000,%00000000	;Zeile #11
			b %00001100,%00000000,%00000000	;Zeile #12
			b %00000000,%00000000,%00000000	;Zeile #13
			b %00000000,%00000000,%00000000	;Zeile #14
			b %00000000,%00000000,%00000000	;Zeile #15
			b %00000000,%00000000,%00000000	;Zeile #16
			b %00000000,%00000000,%00000000	;Zeile #17
			b %00000000,%00000000,%00000000	;Zeile #18
			b %00000000,%00000000,%00000000	;Zeile #19
			b %00000000,%00000000,%00000000	;Zeile #20
			b %00000000,%00000000,%00000000	;Zeile #21
else
;*** Standard Mauszeiger
:MousePic		b %11111110,%00000000,%00000000	;Zeile #1
			b %11111100,%00000000,%00000000	;Zeile #2
			b %11111000,%00000000,%00000000	;Zeile #3
			b %11111000,%00000000,%00000000	;Zeile #4
			b %11111100,%00000000,%00000000	;Zeile #5
			b %11001110,%00000000,%00000000	;Zeile #6
			b %10000111,%00000000,%00000000	;Zeile #7
			b %00000010,%00000000,%00000000	;Zeile #8
			b %00000000,%00000000,%00000000	;Zeile #9
			b %00000000,%00000000,%00000000	;Zeile #10
			b %00000000,%00000000,%00000000	;Zeile #11
			b %00000000,%00000000,%00000000	;Zeile #12
			b %00000000,%00000000,%00000000	;Zeile #13
			b %00000000,%00000000,%00000000	;Zeile #14
			b %00000000,%00000000,%00000000	;Zeile #15
			b %00000000,%00000000,%00000000	;Zeile #16
			b %00000000,%00000000,%00000000	;Zeile #17
			b %00000000,%00000000,%00000000	;Zeile #18
			b %00000000,%00000000,%00000000	;Zeile #19
			b %00000000,%00000000,%00000000	;Zeile #20
			b %00000000,%00000000,%00000000	;Zeile #21
endif
