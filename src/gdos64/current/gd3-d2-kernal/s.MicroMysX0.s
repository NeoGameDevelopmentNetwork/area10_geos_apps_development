; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;
; MicroMys Typ X0
;
;******************************************************************************
;Linke Maustaste   : Mausklick
;Mittlere Maustaste: Mausklick
;Rechte Maustaste  : Mausklick
;Mausrad aufwärts  : -
;Mausrad abwärts   : -
;******************************************************************************
;
; Maustreiber für USB oder PS/2-Maus, SuperCPU & TC64.
; (c) 2023 M. Kanet
;
; 03.08.2023
; V5.1: Initial release.
;******************************************************************************

;*** Symboltabellen.
if .p
			t "SymbTab_1"
			t "SymbTab_GDOS"
			t "SymbTab_CXIO"
			t "SymbTab_SCPU"
			t "SymbTab_TC64"
			t "SymbTab_GTYP"
			t "MacTab"
endif

;*** GEOS-Header.
			n "MicroMysX0",NULL
			c "InputDevice V5.1"
			t "opt.Author"
			f INPUT_DEVICE
			z $80 ;nur GEOS64

			o MOUSE_BASE

			i
<MISSING_IMAGE_DATA>

			h "Mouse driver, controlport 1"
			h "GEOS,MicroMys,SCPU,TC64"
			h "L/M/R:Click, U/D: No click"

if .p
;--- MicroMys-Einstellungen:
:WHEEL_DELAY		= 8				;Mausrad-Verzögerung.
:WHEEL_KEYS		= FALSE				;Cursor-Tasten simulieren.
:WHEEL_UP		= NULL				;Cursor up.
:WHEEL_DOWN		= NULL				;Cursor down.
:WHEEL_MKEY		= FALSE				;Multitasten-Option.
:WHEEL_MMULT		= 0				;Anzahl Wiederholungen.
endif

;******************************************************************************
			t "-G3_InpDevMMys"
;******************************************************************************

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g MOUSE_BASE + MOUSE_SIZE
;******************************************************************************
