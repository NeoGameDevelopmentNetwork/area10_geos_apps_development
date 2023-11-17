; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;
; SuperMouse128
;
;******************************************************************************
;Linke Maustaste   : Mausklick    20 Mhz
;Mittlere Maustaste: Mausklick     1 Mhz
;Rechte Maustaste  : Doppelklick  20 Mhz
;CTRL-Taste        : DoubleSpeed
;******************************************************************************
;
; Maustreiber für C=1351, SmartMouse & SuperCPU
; (c) 1997-99 M. Kanet
; (c) 1999 W. Grimm MegaCom Software
;
;******************************************************************************

if .p
			t "SymbTab_1"
			t "SymbTab_2"
			t "SymbTab_3"
			t "SymbTab128"
			t "MacTab"
:Flag64_128		= TRUE_C128
endif

			n "SuperMouse128",NULL
			f INPUT_128
			a "M.Kanet/W.Grimm"

			o $fd00
			p $fd00

			z $40

			c "InputDevice V4.0"
			i
<MISSING_IMAGE_DATA>

			h "L:20Mhz, M:1Mhz, R:2-click"
			h "CTRL-key for DoubleSpeed"
			h "For C=1351,SmartMouse,SCPU"

if .p
:FastSpeed		= $02
:FastSpeed80		= $03				;80 Zeichen fastspeed C128
:LowSpeed80		= $01				;80 Zeichen normalspeed C128
:NumClicks		= $02 -1
:ClkDelay		= $0a
endif

;******************************************************************************
			t "-G3_SuperMouse"
;******************************************************************************
