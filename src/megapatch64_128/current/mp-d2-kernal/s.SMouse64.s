; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;
; SuperMouse64
;
;******************************************************************************
;Linke Maustaste   : Mausklick    20 Mhz
;Mittlere Maustaste: Mausklick     1 Mhz
;Rechte Maustaste  : Doppelklick  20 Mhz
;CTRL-Taste        : DoubleSpeed
;******************************************************************************
;
; Maustreiber für C=1351, SmartMouse, SuperCPU & TC64.
; (c) 1997-2019 M. Kanet
;
; 13.06.2019
; V4.01: Anpassung an TurboChameleon64.
;        Umschaltung auf 1MHz um den
;        "Zitter"-Bug zu umgehen.
;        Entspricht Anpassung für SCPU.
;******************************************************************************

if .p
			t "SymbTab_1"
			t "SymbTab_2"
			t "SymbTab_3"
			t "SymbTab64"
			t "MacTab"
:Flag64_128		= TRUE_C64
endif

			n "SuperMouse64",NULL
			f INPUT_DEVICE
			a "Markus Kanet"

			o $fe80
			p $fe80

			z $00

			c "InputDevice V4.0"
			i
<MISSING_IMAGE_DATA>

			h "L:20Mhz, M:1Mhz, R:2-click"
			h "CTRL-key for DoubleSpeed"
			h "C=1351,SmartMouse,SCPU,TC64"

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
