; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;
; MicroMys Typ X1
;
;******************************************************************************
;Linke Maustaste   : Mausklick
;Mittlere Maustaste: Mausklick
;Rechte Maustaste  : Mausklick
;Mausrad aufwärts  : Cursor up
;Mausrad abwärts   : Cursor down
;******************************************************************************
;
; Maustreiber für USB oder PS/2-Maus, SuperCPU & TC64.
; (c) 2023 M. Kanet
;
; 04.08.2023
; V5.1: Minor fixes.
;
; 18.07.2023
; V5.0: Initial release.
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
			n "MicroMysX1",NULL
			c "InputDevice V5.1"
			t "opt.Author"
			f INPUT_DEVICE
			z $80 ;nur GEOS64

			o MOUSE_BASE

			i
<MISSING_IMAGE_DATA>

			h "Mouse driver, controlport 1"
			h "GDOS64,MicroMys,SCPU,TC64"
			h "L/M/R:Click, U/D: 1x CRSR U/D"

if .p
;--- MicroMys-Einstellungen:
:WHEEL_DELAY		= 8				;Mausrad-Verzögerung.
:WHEEL_KEYS		= TRUE				;Cursor-Tasten simulieren.
:WHEEL_UP		= $10				;Cursor up.
:WHEEL_DOWN		= $11				;Cursor down.
:WHEEL_MKEY		= FALSE				;Multitasten-Option.
:WHEEL_MMULT		= 1				;Anzahl Wiederholungen.
endif

;******************************************************************************
			t "-G3_InpDevMMys"
;******************************************************************************

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g MOUSE_BASE + MOUSE_SIZE
;******************************************************************************
