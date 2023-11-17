; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "SymbTab_1"
			t "SymbTab_GDOS"
			t "SymbTab_CXIO"
			t "SymbTab_GTYP"
			t "MacTab"

;--- Externe Labels.
			t "s.GD3_KERNAL.ext"
endif

;*** GEOS-Header.
			n "obj.DvRAM_CREU"
			f DATA

			o BASE_RAM_DRV

			r BASE_RAM_DRV +SIZE_RAM_DRV

;*** DoRAMOp-Routine für C=REU.
			t "-R3_DoRAM_CREU"
			t "-R3_DoRAMOpCREU"

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g BASE_RAM_DRV +SIZE_RAM_DRV
;******************************************************************************
