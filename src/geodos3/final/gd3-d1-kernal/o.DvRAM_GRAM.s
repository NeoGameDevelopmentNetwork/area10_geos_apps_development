﻿; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExt"

;*** GEOS-Header.
			n "obj.DvRAM_GRAM"
			t "G3_Data.V.Class"

			o BASE_RAM_DRV

;*** DoRAMOp-Routine für GeoRAM.
			t "-R3_DoRAM_GRAM"

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g GD_JUMPTAB
;******************************************************************************
