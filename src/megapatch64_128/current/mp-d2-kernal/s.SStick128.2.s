; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;
; SuperStick128
;
;******************************************************************************
;
; Joysticktreiber
; (c) 1997-99 M. Kanet
; (c) 1999 W. Grimm MegaCom Software
;
;******************************************************************************

			t "G3_SymMacExt"

			n "SuperStick128.2",NULL
			f INPUT_128
			a "M.Kanet/W.Grimm"

			o $fd00
			p $fd00

			z $40

			c "InputDevice V4.0"
			i
<MISSING_IMAGE_DATA>

;*** Nutzung des Anschlußports:
;1 = Port 1
;2 = Port 2
:PortFlag = 2

if PortFlag = 1
			h "Joystick, GamePad, C=1350 Port 1"
:PortAdrByte		= $dc01
endif

if PortFlag = 2
			h "Joystick, GamePad, C=1350 Port 2"
:PortAdrByte		= $dc00
endif

;******************************************************************************
			t "-G3_SuperStick"
;******************************************************************************
