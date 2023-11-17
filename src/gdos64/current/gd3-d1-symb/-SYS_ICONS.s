; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if EnableMSelect = TRUE
:Icon_MSelect
			b %10000000 +1 +8		;Ungepackt +Kennbyte +8 Datenbytes.

			b %00000000			;"Pfeil nach unten"
			b %00111000
			b %00111000
			b %11111110
			b %01111100
			b %00111000
			b %00010000
			b %00000000

:Icon_MSelect_x		= 1				;Beite = 1 Card
:Icon_MSelect_y		= 8				;Höhe  = 8 Pixel
endif

if EnableMSlctUp = TRUE
:Icon_MSlctUp
			b %10000000 +1 +8		;Ungepackt +Kennbyte +8 Datenbytes.

			b %00000000			;"Pfeil nach unten"
			b %00010000
			b %00111000
			b %01111100
			b %11111110
			b %00111000
			b %00111000
			b %00000000

:Icon_MSlctUp_x		= 1				;Beite = 1 Card
:Icon_MSlctUp_y		= 8				;Höhe  = 8 Pixel
endif

if EnableMUpDown = TRUE
:Icon_MUpDown
			b %10000000 +1 +8		;Ungepackt +Kennbyte +8 Datenbytes.

			b %00011000			;"Up/Down"
			b %00111100
			b %01111110
			b %00000000
			b %00000000
			b %01111110
			b %00111100
			b %00011000

:Icon_MUpDown_x		= 1				;Beite = 1 Card
:Icon_MUpDown_y		= 8				;Höhe  = 8 Pixel
endif

if EnableMButton = TRUE
:Icon_MButton
			b %10000000 +1 +8		;Ungepackt +Kennbyte +8 Datenbytes.

			b %11111111			;"Button"
			b %11111101
			b %11111101
			b %11111101
			b %11111101
			b %11111101
			b %10000001
			b %11111111

:Icon_MButton_x		= 1				;Beite = 1 Card
:Icon_MButton_y		= 8				;Höhe  = 8 Pixel
endif
