﻿; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;
; SuperStick64
;
;******************************************************************************
;
; Joysticktreiber
; (c) 1997-2021 M. Kanet
;
;******************************************************************************

;*** Symboltabellen.
			t "G3_SymMacExt"

;*** GEOS-Header.
			n "SuperStick64.2",NULL
			c "InputDevice V4.0"
			t "G3_Sys.Author"
			f INPUT_DEVICE
			z $80				;nur GEOS64

			o MOUSE_BASE
			p MOUSE_JMP

			i
<MISSING_IMAGE_DATA>

;*** Nutzung des Anschlußports:
;1 = Port 1
;2 = Port 2
if .p
:PortFlag = 2
endif

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

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			e END_MOUSE
;******************************************************************************
