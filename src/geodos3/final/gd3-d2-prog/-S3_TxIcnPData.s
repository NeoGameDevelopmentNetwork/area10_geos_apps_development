; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Positionsdaten für Icons und Texte.
;
;*** Escape-Icon.
;    ........ ###
;    ........
;
:IconX1x		= $20
:IconX1y		= $50

;*** Layout #1 1x2, 2x1 oder 2x2 Icons.
;1x2:###  ... 2x1:...  ... 2x2:###  ###
;
;    ###  ...     ###  ###     ###  ###
;
:Icon1x			= $03
:Icon2x			= $15
:Icon1y			= $78
:Icon2y			= $98

:IconT1x		= (Icon1x*8 +44)
:IconT2x		= (Icon2x*8 +44)
:IconT1y		= Icon1y    + 7
:IconT1ay		= IconT1y   + 9
:IconT2y		= Icon2y    + 7
:IconT2ay		= IconT2y   + 9

;*** Layout #2 3x2 Icons.
;3x2:###  ###  ###
;
;    ###  ###  ###
;
:Icon6x1		= $04
:Icon6x2		= $10
:Icon6x3		= $1c
:Icon6y1		= $68
:Icon6y2		= $90
:IconT6x1		= (Icon6x1*8)
:IconT6x2		= (Icon6x2*8)
:IconT6x3		= (Icon6x3*8)
:IconT6y1_1		= Icon6y1   +30
:IconT6y1_2		= IconT6y1_1 +8
:IconT6y2_1		= Icon6y2   +30
:IconT6y2_2		= IconT6y2_1 +8

;*** Layout #3 4x1 Icons.
;4x1:### ### ### ###
;
:Icon4x1		= $03
:Icon4x2		= $0c
:Icon4x3		= $15
:Icon4x4		= $20
:Icon4y			= $90
:IconT4x1		= (Icon4x1*8)
:IconT4x2		= (Icon4x2*8)
:IconT4x3		= (Icon4x3*8)
:IconT4x4		= (Icon4x4*8)
:IconT4y1		= Icon4y  +30
:IconT4y2		= IconT4y1 +8

;*** Layout #4 3x1 Icons.
;3x1:
;
;    ###  ###  ###
;
:Icon3x1		= $03
:Icon3x2		= $10
:Icon3x3		= $20
:Icon3y			= $98
:IconT3x1		= (Icon3x1*8 +44)
:IconT3x2		= (Icon3x2*8 +44)
:IconT3y		= Icon3y    + 7
:IconT3ay		= IconT3y   + 9
